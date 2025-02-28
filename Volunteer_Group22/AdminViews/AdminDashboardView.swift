import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Models & Supporting Structs

struct Activity {
    let title: String
    let timestamp: String
    let type: ActivityType
    
    enum ActivityType: String {
        case event = "event"
        case volunteer = "volunteer"
        case report = "report"
        
        var icon: String {
            switch self {
            case .event: return "calendar"
            case .volunteer: return "person.2"
            case .report: return "doc.text"
            }
        }
        
        var color: Color {
            switch self {
            case .event: return .blue
            case .volunteer: return .green
            case .report: return .orange
            }
        }
    }
}

// MARK: - UI Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.system(size: 15))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .padding(.horizontal, 8)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct RecentActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(activity.type.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: activity.type.icon)
                        .foregroundColor(activity.type.color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.timestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - ViewModel

@MainActor
class AdminDashboardViewModel: ObservableObject {
    @Published var activeEventsCount: Int = 0
    @Published var totalVolunteers: Int = 0
    @Published var totalHours: Int = 0
    @Published var successRate: Int = 0
    @Published var recentActivities: [Activity] = []
    
    private let db = Firestore.firestore()
    
    init() {
        Task {
            await fetchDashboardStats()
        }
    }
    
    func fetchDashboardStats() async {
        do {
            let activeEventsCount = await fetchActiveEventsCount()
            let totalVolunteers = await fetchTotalVolunteers()
            let totalHoursDonated = await fetchTotalHoursDonated()
            let successRate = await fetchSuccessRate()
            await fetchRecentActivities()

            DispatchQueue.main.async {
                self.activeEventsCount = activeEventsCount
                self.totalVolunteers = totalVolunteers
                self.totalHours = totalHoursDonated
                self.successRate = successRate
            }
        } catch {
            print("Error fetching dashboard statistics: \(error.localizedDescription)")
        }
    }
    
    func fetchActiveEventsCount() async -> Int {
        do {
            let snapshot = try await db.collection("events")
                .whereField("status", isEqualTo: "Upcoming")
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching active events: \(error.localizedDescription)")
            return 0
        }
    }

    func fetchTotalVolunteers() async -> Int {
        do {
            let snapshot = try await db.collection("users")
                .whereField("role", isEqualTo: "Volunteer")
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching volunteers: \(error.localizedDescription)")
            return 0
        }
    }

    func fetchTotalHoursDonated() async -> Int {
        do {
            let snapshot = try await db.collection("events").getDocuments()
            
            let totalHours = snapshot.documents.reduce(0) { (sum, document) -> Int in
                let data = document.data()
                let volunteerCount = (data["assignedVolunteers"] as? [String])?.count ?? 0
                let estimatedHoursPerVolunteer = 5
                return sum + (volunteerCount * estimatedHoursPerVolunteer)
            }
            
            return totalHours
        } catch {
            print("Error fetching total hours donated: \(error.localizedDescription)")
            return 0
        }
    }

    func fetchSuccessRate() async -> Int {
        do {
            let snapshot = try await db.collection("events").getDocuments()

            let completedEvents = snapshot.documents.filter { document in
                let status = document.data()["status"] as? String ?? ""
                return status == "Completed"
            }.count

            let totalEvents = snapshot.documents.count
            let successRate = totalEvents > 0 ? (completedEvents * 100) / totalEvents : 0

            return successRate
        } catch {
            print("Error fetching success rate: \(error.localizedDescription)")
            return 0
        }
    }
    
    func fetchRecentActivities() async {
        do {
            let snapshot = try await db.collection("activities")
                .order(by: "timestamp", descending: true)
                .limit(to: 5)
                .getDocuments()

            let activities = snapshot.documents.compactMap { document -> Activity? in
                let data = document.data()
                
                guard let title = data["title"] as? String,
                      let timestamp = data["timestamp"] as? Timestamp,
                      let typeString = data["type"] as? String,
                      let type = Activity.ActivityType(rawValue: typeString) else {
                    return nil
                }

                return Activity(
                    title: title,
                    timestamp: timestamp.dateValue().formatted(),
                    type: type
                )
            }

            DispatchQueue.main.async {
                self.recentActivities = activities
            }
        } catch {
            print("Error fetching recent activities: \(error.localizedDescription)")
        }
    }
}

// MARK: - Main View

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overview").font(.system(size: 24, weight: .bold)).padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Active Events", value: "\(viewModel.activeEventsCount)", icon: "calendar", color: .blue)
                        StatCard(title: "Total Volunteers", value: "\(viewModel.totalVolunteers)", icon: "person.2", color: .green)
                    }
                }.padding(.horizontal)
            }.padding(.vertical)
        }.onAppear {
            Task {
                await viewModel.fetchDashboardStats()
            }
        }
    }
}



