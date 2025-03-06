import SwiftUI
import FirebaseFirestore

// Quick stats for admin dashboard - shows key metrics in a clean, modern card layout
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

// Quick actions for admin - Create Event, Match Volunteers, and Generate Report
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

// Recent activities row - displays individual activity items with icons and timestamps
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

// Recent activities model
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

// MARK: - Main View
struct AdminDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    private let db = Firestore.firestore()

    // Dynamic state variables
    @State private var activeEventsCount: Int = 0
    @State private var totalVolunteers: Int = 0
    @State private var totalHours: Int = 0
    @State private var successRate: Int = 0
    @State private var activities: [Activity] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack {
                        Text("Welcome, Admin")
                            .font(.system(size: 32, weight: .bold))
                        
                        Spacer()
                        
                        NavigationLink(destination: AdminProfileEditView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Here's what's happening today")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overview")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Active Events", value: "\(activeEventsCount)", icon: "calendar", color: .blue)
                        StatCard(title: "Total Volunteers", value: "\(totalVolunteers)", icon: "person.2", color: .green)
                        StatCard(title: "Hours Donated", value: "\(totalHours)", icon: "clock", color: .orange)
                        StatCard(title: "Success Rate", value: "\(successRate)%", icon: "chart.bar", color: .purple)
                    }
                    .padding(.horizontal)
                }
                
                // Quick Actions section with navigation buttons
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Create Event button
                        NavigationLink(destination: AdminCreateEventView()) {
                            QuickActionButton(
                                title: "Create Event",
                                icon: "plus.circle.fill",
                                action: {}
                            )
                        }
                        
                        // Match Volunteers button
                        NavigationLink(destination: AdminVolunteerMatchView()) {
                            QuickActionButton(
                                title: "Match Volunteers",
                                icon: "person.2.fill",
                                action: {}
                            )
                        }
                        
                        // Generate Report button
                        NavigationLink(destination: AdminReportingView()) {
                            QuickActionButton(
                                title: "Generate Report",
                                icon: "doc.text.fill",
                                action: {}
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activities")
                        .font(.system(size: 24, weight: .bold))
                    
                    VStack(spacing: 12) {
                        ForEach(activities, id: \.title) { activity in
                            RecentActivityRow(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            fetchDashboardStats()
            fetchRecentActivities()
        }
    }
    
    // MARK: - Fetch Data from Firestore
    private func fetchDashboardStats() {
        Task {
            activeEventsCount = await fetchActiveEventsCount()
            totalVolunteers = await fetchTotalVolunteers()
            totalHours = await fetchTotalHoursDonated()
            successRate = await fetchSuccessRate()
        }
    }
    
    private func fetchActiveEventsCount() async -> Int {
        do {
            let snapshot = try await db.collection("events").whereField("status", isEqualTo: "Upcoming").getDocuments()
            return snapshot.documents.count
        } catch {
            return 0
        }
    }

    private func fetchTotalVolunteers() async -> Int {
        do {
            let snapshot = try await db.collection("users").whereField("role", isEqualTo: "Volunteer").getDocuments()
            return snapshot.documents.count
        } catch {
            return 0
        }
    }

    private func fetchTotalHoursDonated() async -> Int {
        do {
            let snapshot = try await db.collection("events").getDocuments()
            return snapshot.documents.reduce(0) { $0 + (($1.data()["assignedVolunteers"] as? [String])?.count ?? 0) * 5 }
        } catch {
            return 0
        }
    }

    private func fetchSuccessRate() async -> Int {
        do {
            let snapshot = try await db.collection("events").whereField("status", isEqualTo: "Completed").getDocuments()
            return snapshot.documents.count
        } catch {
            return 0
        }
    }

    private func fetchRecentActivities() {
        Task {
            do {
                let snapshot = try await db.collection("events")
                    .whereField("status", isEqualTo: "Upcoming") // Fetch only active events
                    .order(by: "createdAt", descending: true) // Sort by newest first
                    .limit(to: 5) // Limit to 5 events
                    .getDocuments()

                let fetchedActivities = snapshot.documents.compactMap { document -> Activity? in
                    let data = document.data()
                    
                    guard let title = data["name"] as? String,
                          let timestamp = (data["createdAt"] as? Timestamp)?.dateValue() else {
                        return nil
                    }

                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d, yyyy h:mm a"
                    let formattedTimestamp = formatter.string(from: timestamp)

                    return Activity(title: title, timestamp: formattedTimestamp, type: .event)
                }

                // Update UI state
                DispatchQueue.main.async {
                    self.activities = fetchedActivities
                }

            } catch {
                print("Error fetching active events: \(error.localizedDescription)")
            }
        }
    }
}



