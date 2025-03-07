"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyNewlyAssignedVolunteers =
  functions.firestore
    .document("events/{eventId}")
    .onWrite(async (change, context) => {
      if (!change.after.exists) {
        return null;
      }

      const oldData = change.before.exists
        ? change.before.data()
        : null;
      const newData = change.after.data();

      const oldVols = (oldData && oldData.assignedVolunteers)
        || [];
      const newVols = (newData && newData.assignedVolunteers)
        || [];

      // Find newly assigned volunteers
      const newlyAssigned = newVols.filter(
        (uid) => !oldVols.includes(uid),
      );
      if (newlyAssigned.length === 0) {
        return null;
      }

      for (const volunteerId of newlyAssigned) {
        try {
          const userDoc = await admin.firestore()
            .collection("users")
            .doc(volunteerId)
            .get();

          if (!userDoc.exists) {
            console.log(
              "User " + volunteerId + " not found, skipping push",
            );
            continue;
          }

          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;
          if (!fcmToken) {
            console.log(
              "No fcmToken for user " + volunteerId
                + ", skipping push",
            );
            continue;
          }

          const name = newData.name || "an event";
          
          console.log("fcmToken from user doc:", fcmToken);
          
          const message = {
            token: fcmToken,
            notification: {
              title: "Assigned to New Event",
              body: "You have been assigned to " + name + "!"
            },
            data: {
              eventId: context.params.eventId,
              type: "event" 
            },
            android: {
              priority: "high"
            },
            apns: {
              payload: {
                aps: {
                  contentAvailable: true,
                  badge: 1,
                  sound: "default"
                }
              },
              headers: {
                "apns-priority": "10"
              }
            }
          };
          
          await admin.messaging().send(message);
          
          console.log(
            "Notification sent to volunteer " + volunteerId,
          );
        } catch (err) {
          console.error("Error sending notification:", err);
        }
      }
      return null;
    });

// Notify volunteer when an event has been updated
exports.notifyEventUpdates = functions.firestore
  .document("events/{eventId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    
    const hasChanged = hasEventChanged(beforeData, afterData);
    
    if (!hasChanged) {
      console.log("No important changes detected, skipping notifications");
      return null;
    }
    
    const assignedVolunteers = afterData.assignedVolunteers || [];
    
    if (assignedVolunteers.length === 0) {
      console.log("No volunteers assigned to this event, skipping notifications");
      return null;
    }
  
    const eventName = afterData.name || "an event";
    
    for (const volunteerId of assignedVolunteers) {
      try {
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(volunteerId)
          .get();
          
        if (!userDoc.exists) {
          console.log("User " + volunteerId + " not found, skipping update notification");
          continue;
        }
        
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        if (!fcmToken) {
          console.log("No fcmToken for user " + volunteerId + ", skipping update notification");
          continue;
        }
        
        // Create and send notification
        const message = {
          token: fcmToken,
          notification: {
            title: "Event Updated",
            body: `"${eventName}" has been updated. Please check for changes.`
          },
          data: {
            eventId: context.params.eventId,
            type: "event"
          },
          android: {
            priority: "high"
          },
          apns: {
            payload: {
              aps: {
                contentAvailable: true,
                badge: 1,
                sound: "default"
              }
            },
            headers: {
              "apns-priority": "10"
            }
          }
        };
        
        await admin.messaging().send(message);
        console.log("Update notification sent to volunteer " + volunteerId);
      } catch (err) {
        console.error("Error sending update notification:", err);
      }
    }
    
    return null;
  });

  // Send daily reminders to volunteers about upcoming events. Runs once a day via Google Cloud Scheduler
  exports.sendDailyEventReminders = functions.pubsub
  .schedule('0 7 * * *')  // Runs at 7:00 AM every day
  .timeZone('America/Chicago')  
  .onRun(async (context) => {
    const db = admin.firestore();
    
    // Calculate time window for upcoming events (events in the next 5 days)
    const now = new Date();
    const fiveDaysLater = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);
    
    console.log(`Checking for events between ${now.toISOString()} and ${fiveDaysLater.toISOString()}`);
    
    try {
      const eventsSnapshot = await db.collection('events')
        .where('status', '==', 'Upcoming')
        .get();
        
      console.log(`Found ${eventsSnapshot.size} upcoming events to check`);
      
      if (eventsSnapshot.empty) {
        return null;
      }
      
      const now = new Date();
      const fiveDaysLater = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);
      const eventsInRange = [];
      
      eventsSnapshot.forEach(doc => {
        const eventData = doc.data();
        if (!eventData.dateTime) return; 
        
        const eventDate = eventData.dateTime.toDate();
        
        if (eventDate >= now && eventDate <= fiveDaysLater) {
          eventsInRange.push({
            id: doc.id,
            data: eventData
          });
        }
      });
      
      console.log(`Found ${eventsInRange.length} events in the next 5 days`);
      
      let notificationCount = 0;
      
      for (const event of eventsInRange) {
        const eventData = event.data;
        const eventId = event.id;
        const eventName = eventData.name || "Unnamed event";
        
        const assignedVolunteers = eventData.assignedVolunteers || [];
        if (assignedVolunteers.length === 0) {
          console.log(`Event ${eventId} has no assigned volunteers, skipping`);
          continue;
        }
        
        const eventDate = eventData.dateTime.toDate();
        const formattedDate = eventDate.toLocaleDateString('en-US', {
          weekday: 'long',
          month: 'short', 
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
        });
        
        const today = new Date();
        const msPerDay = 24 * 60 * 60 * 1000;
        const daysUntil = Math.ceil((eventDate - today) / msPerDay);
        const dayText = daysUntil === 1 ? "tomorrow" : `in ${daysUntil} days`;
        
        console.log(`Sending reminders for event "${eventName}" on ${formattedDate} (${dayText})`);
        
        // Send notification to each volunteer
        for (const volunteerId of assignedVolunteers) {
          try {
            const userDoc = await db.collection('users').doc(volunteerId).get();
            
            if (!userDoc.exists) {
              console.log(`User ${volunteerId} not found, skipping`);
              continue;
            }
            
            const userData = userDoc.data();
            const fcmToken = userData.fcmToken;
            
            if (!fcmToken) {
              console.log(`No FCM token for user ${volunteerId}, skipping`);
              continue;
            }
            
            // Create and send the notification
            const message = {
              token: fcmToken,
              notification: {
                title: "Upcoming Event Reminder",
                body: `"${eventName}" is ${dayText} on ${formattedDate}!`
              },
              data: {
                eventId: eventId,
                type: "event"
              },
              android: {
                priority: "high"
              },
              apns: {
                payload: {
                  aps: {
                    contentAvailable: true,
                    badge: 1,
                    sound: "default"
                  }
                },
                headers: {
                  "apns-priority": "10"
                }
              }
            };
            
            await admin.messaging().send(message);
            notificationCount++;
            console.log(`Reminder sent to volunteer ${volunteerId} for event ${eventId}`);
            
          } catch (err) {
            console.error(`Error sending reminder to volunteer ${volunteerId}:`, err);
          }
        }
      }
      
      console.log(`Successfully sent ${notificationCount} event reminders`);
      return null;
      
    } catch (error) {
      console.error("Error in sendDailyEventReminders function:", error);
      return null;
    }
  });

  function hasEventChanged(before, after) {
    // Fields to compare
    const fieldsToCheck = [
      'name',
      'description',
      'dateTime',
      'location',
      'status',
      'urgency',
      'requiredSkills',
      'volunteerRequirements'
    ];
    
    // Check if any field has changed
    for (const field of fieldsToCheck) {
      if (before[field] === undefined && after[field] === undefined) {
        continue;
      }
      
      if (typeof before[field] === 'object' && before[field] !== null) {
        if (JSON.stringify(before[field]) !== JSON.stringify(after[field])) {
          console.log(`Event field '${field}' changed`);
          return true;
        }
      } 
      else if (before[field] !== after[field]) {
        console.log(`Event field '${field}' changed from "${before[field]}" to "${after[field]}"`);
        return true;
      }
    }
    
    return false;
  }