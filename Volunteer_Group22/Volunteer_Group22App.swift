import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notifications delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Handle token refresh
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Handle registration error
    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenter Delegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Update notification count
        NotificationManager.shared.notificationCount += 1
        
        // Show banner, play sound, and update badge
        completionHandler([[.banner, .sound, .badge]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Handle notification tap here
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    // MARK: - Messaging Delegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "FCMToken")
            print("FCM token: \(token)")
            
            // Send token to server
            sendFCMTokenToServer(token)
            // Token is regenrated sporadically, upon log out, cache clearance, etc
        }
    }
    
    // MARK: - Helper Functions
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "event":
            if let eventId = userInfo["eventId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowEventDetail"),
                    object: nil,
                    userInfo: ["eventId": eventId]
                )
            }
        case "match":
            if let matchId = userInfo["matchId"] as? String {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowMatchDetail"),
                    object: nil,
                    userInfo: ["matchId": matchId]
                )
            }
        default:
            break
        }
    }
    
    private func sendFCMTokenToServer(_ token: String) {
        // Send token to server
    }
}

@main
struct Volunteer_Group22App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var notificationManager = NotificationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(notificationManager)
        }
    }
}

