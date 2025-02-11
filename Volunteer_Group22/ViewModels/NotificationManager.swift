import SwiftUI
import UserNotifications

class NotificationManager: NSObject, ObservableObject {
    @Published var notificationSettings: UNNotificationSettings?
    @Published var notificationCount: Int = 0
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions) { [weak self] granted, error in
                if granted {
                    self?.getNotificationSettings()
                }
                if let error = error {
                    print("Error requesting authorization: \(error.localizedDescription)")
                }
            }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationSettings = settings
            }
        }
    }
}

// MARK: - Notification View Model
class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    
    struct NotificationItem: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let date: Date
        let type: NotificationType
        var isRead: Bool
        
        enum NotificationType {
            case event
            case match
            case system
        }
    }
    
    func markAsRead(_ notification: NotificationItem) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }
    
    func clearAll() {
        notifications.removeAll()
    }
}

// MARK: - Notification View
struct NotificationView: View {
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                NotificationRow(notification: notification)
                    .onTapGesture {
                        viewModel.markAsRead(notification)
                    }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarItems(
            trailing: Button("Clear All") {
                viewModel.clearAll()
            }
        )
    }
}

struct NotificationRow: View {
    let notification: NotificationViewModel.NotificationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notification.title)
                    .font(.headline)
                Spacer()
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(notification.date, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
