import SwiftUI
import FirebaseAuth
import FirebaseFirestore


@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var isEmailVerified: Bool = false
    @Published var user: User?
    
    public let db = Firestore.firestore()
    private var userRole: String = ""
    
    init() {
        self.userSession = Auth.auth().currentUser
        
        if let user = self.userSession {
            Task {
                do {
                    try await user.reload()
                    self.isEmailVerified = user.isEmailVerified
                    
                    await fetchUser()
                } catch {
                    print("Error reloading user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    
    // MARK: Account management
    // Sign In Existing User
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await result.user.reload()
            self.userSession = result.user
            self.isEmailVerified = result.user.isEmailVerified
            
            await fetchUser()
        } catch {
            print("failed to sign in: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Create New User and Add to Firestore
    func signUp(withEmail email: String, password: String, role: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let userId = result.user.uid
            self.userRole = role
            
            // Create initial user document in Firestore
            try await createUserDocument(userId: userId, email: email, role: role)
        } catch {
            print("Failed to create user: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Function to Create Firestore User Document
    private func createUserDocument(userId: String, email: String, role: String) async throws {
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "role": role
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    // Check if profile is complete
    var isProfileComplete: Bool {
        guard let fullName = user?.fullName, !fullName.isEmpty else { return false }
        return true
    }
    
    // Send password reset email
    func resetPassword(withEmail email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            print("Error sending password reset email: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Sign Out Current User
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
        } catch {
            print("failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // Delete Current Users Account
    func deleteAccount() async throws {
        do {
            guard let currentUser = Auth.auth().currentUser else { return }
            try await currentUser.delete()
            self.userSession = nil
        } catch {
            print("Error deleting account: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Fetch user profile data from Firestore
    func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                let username = data["username"] as? String ?? ""
                let fullName = data["fullName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                let role = data["role"] as? String ?? ""
                let preferences = data["preferences"] as? [String] ?? []
                let skills = data["skills"] as? [String] ?? []
                
                let locationData = data["location"] as? [String: Any] ?? [:]
                let address = locationData["address"] as? String ?? ""
                let city = locationData["city"] as? String ?? ""
                let country = locationData["country"] as? String ?? ""
                let state = locationData["state"] as? String ?? ""
                let zipCode = locationData["zipCode"] as? String ?? ""
                let location = User.Location(address: address, city: city, country: country, state: state, zipCode: zipCode)
                
                let availabilityData = data["availability"] as? [String: [String: String]] ?? [:]
                var availability: [String: User.Availability] = [:]
                
                for (day, dict) in availabilityData {
                    let startTime = dict["startTime"] ?? ""
                    let endTime   = dict["endTime"] ?? ""
                    availability[day] = User.Availability(
                        startTime: startTime,
                        endTime:   endTime
                    )
                }
                
                self.user = User(
                    uid: uid,
                    username: username,
                    fullName: fullName,
                    email: email,
                    createdAt: createdAt,
                    role: role,
                    preferences: preferences,
                    skills: skills,
                    location: location,
                    availability: availability
                )
            } else {
                print("DEBUG: Document for \(uid) returned no data.")
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: Event management
    // Create an event
    public func createEvent(
        name: String,
        description: String,
        date: Date,
        address: String,
        city: String,
        state: String,
        country: String,
        zipCode: String,
        requiredSkills: [String],
        urgency: Event.UrgencyLevel,
        volunteerRequirements: Int
    ) async throws {
        
        // Convert urgency enum to string value
        let urgencyString = urgency.rawValue
        
        // Create location data map directly from the separate fields
        let locationData: [String: String] = [
            "address": address,
            "city": city,
            "state": state,
            "country": country,
            "zipCode": zipCode
        ]
        
        // Create event data for Firebase
        let eventData: [String: Any] = [
            "name": name,
            "description": description,
            "dateTime": Timestamp(date: date),
            "location": locationData,
            "requiredSkills": requiredSkills,
            "urgency": urgencyString,
            "volunteerRequirements": volunteerRequirements,
            "assignedVolunteers": [],
            "status": Event.EventStatus.upcoming.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await db.collection("events").addDocument(data: eventData)
    }
    
    // Update an event
    public func updateEvent(
        eventId: String,
        name: String,
        description: String,
        date: Date,
        address: String,
        city: String,
        state: String,
        country: String,
        zipCode: String,
        requiredSkills: [String],
        urgency: Event.UrgencyLevel,
        volunteerRequirements: Int,
        status: Event.EventStatus
    ) async throws {
        
        // Convert urgency enum to string value
        let urgencyString = urgency.rawValue
        let statusString = status.rawValue
        
        // Create location data map directly from the separate fields
        let locationData: [String: String] = [
            "address": address,
            "city": city,
            "state": state,
            "country": country,
            "zipCode": zipCode
        ]
        
        // Create event data for Firebase
        let eventData: [String: Any] = [
            "name": name,
            "description": description,
            "dateTime": Timestamp(date: date),
            "location": locationData,
            "requiredSkills": requiredSkills,
            "urgency": urgencyString,
            "volunteerRequirements": volunteerRequirements,
            "status": statusString,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Update the document in Firestore
        try await db.collection("events").document(eventId).updateData(eventData)
    }
    
    // Delete an event
    public func deleteEvent(eventId: String) async throws {
        try await db.collection("events").document(eventId).delete()
    }
    
    // Fetch events 
    public func fetchEvents(db: Firestore) async throws -> [Event] {
        let snapshot = try await db.collection("events").getDocuments()
        
        return snapshot.documents.map { document in
            return Event(documentId: document.documentID, data: document.data())
        }
    }
    
    // Fetch single event
    public func fetchEvent(db: Firestore, documentId: String) async throws -> Event? {
        let document = try await db.collection("events").document(documentId).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        return Event(documentId: document.documentID, data: data)
    }
    
    
    // Fetch filtered events
    public func fetchFilteredEvents(
        db: Firestore,
        status: Event.EventStatus? = nil,
        searchText: String? = nil
    ) async throws -> [Event] {
        var query: Query = db.collection("events")
        
        // Apply status filter if provided
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        
        var events = snapshot.documents.map { document in
            return Event(documentId: document.documentID, data: document.data())
        }
        
        // Apply text search filter if provided
        if let searchText = searchText, !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            events = events.filter { event in
                event.name.lowercased().contains(lowercasedSearch) ||
                event.description.lowercased().contains(lowercasedSearch) ||
                event.location.lowercased().contains(lowercasedSearch)
            }
        }
        
        return events
    }
    
    // Creates volunteerHistory documents for all events that have ended
    func generateVolunteerHistoryRecords() async throws {
        let now = Date()
        
        // Query all events with dateTime < now
        let eventSnapshot = try await db.collection("events")
            .whereField("dateTime", isLessThan: Timestamp(date: now))
            .getDocuments()
        
        for eventDoc in eventSnapshot.documents {
            let eventId = eventDoc.documentID
            let eventData = eventDoc.data()
            
            // Get assigned volunteers
            let assignedVolunteers = eventData["assignedVolunteers"] as? [String] ?? []
            
            for volunteerId in assignedVolunteers {
                // Check if exists already
                let historySnapshot = try await db.collection("volunteerHistory")
                    .whereField("eventId", isEqualTo: eventId)
                    .whereField("volunteerId", isEqualTo: volunteerId)
                    .getDocuments()
                
                // Create if does not exist
                if historySnapshot.documents.isEmpty {
                    let historyData: [String: Any] = [
                        "eventId": eventId,
                        "volunteerId": volunteerId,
                        "dateCompleted": Timestamp(date: now),
                        "performance": [:],
                        "feedback": "",
                        "createdAt": Timestamp(date: now)
                    ]
                    
                    // Create the document in Firestore
                    _ = db.collection("volunteerHistory").addDocument(data: historyData)
                }
            }
            
            // Change event status to Completed
            if let currentStatus = eventData["status"] as? String,currentStatus != Event.EventStatus.completed.rawValue {
                try await db.collection("events").document(eventId)
                    .updateData(["status": Event.EventStatus.completed.rawValue])
            }
        }
    }
}
