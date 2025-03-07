import SwiftUI
import FirebaseFirestore

// Quick actions for volunteers - View Events, Track Hours
struct VolunteerActionButton: View {
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

// Modified activity type for volunteer perspective
struct VolunteerActivity {
    let title: String
    let timestamp: String
    let type: ActivityType
    
    enum ActivityType {
        case event, hours, achievement
        
        var icon: String {
            switch self {
            case .event: return "calendar"
            case .hours: return "clock"
            case .achievement: return "star"
            }
        }
        
        var color: Color {
            switch self {
            case .event: return .blue
            case .hours: return .green
            case .achievement: return .orange
            }
        }
    }
}

struct VolunteerActivityRow: View {
    let activity: VolunteerActivity
    
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

struct VolunteerDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VolunteerHistoryViewModel()
    @State private var eventNames: [String: String] = [:] // Map eventId -> eventName
    private let db = Firestore.firestore()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header section with welcome message and profile button
                VStack(spacing: 4) {
                    HStack {
                        Text("Welcome, \(authViewModel.user?.fullName ?? "Volunteer")")
                            .font(.system(size: 32, weight: .bold))

                        Spacer()

                        NavigationLink(destination: VolunteerProfileEditView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }

                    HStack {
                        Text("Track your impact")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Overview section with volunteer statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Impact")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Hours This Month", value: "12", icon: "clock", color: .blue)
                        StatCard(title: "Total Hours", value: "56", icon: "sum", color: .green)
                        StatCard(title: "Events Joined", value: "8", icon: "calendar", color: .orange)
                        StatCard(title: "Achievements", value: "5", icon: "star", color: .purple)
                    }
                    .padding(.horizontal)
                }

                // Quick Actions section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        NavigationLink(destination: VolunteerEventSearchView()) {
                            VolunteerActionButton(title: "Browse Events", icon: "calendar", action: {})
                        }

                        NavigationLink(destination: VolunteerHistoryView()) {
                            VolunteerActionButton(title: "Track Hours", icon: "clock", action: {})
                        }
                    }
                    .padding(.horizontal)
                }

                // Recent Activities section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Activities")
                            .font(.system(size: 24, weight: .bold))

                        Spacer()

                        NavigationLink("See All", destination: VolunteerHistoryView())
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)

                    ZStack {
                        if viewModel.isLoading {
                            ProgressView("Loading activities...")
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        } else if viewModel.historyRecords.isEmpty {
                            VStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                    .padding()
                                
                                Text("No recent activities")
                                    .font(.headline)
                                
                                Text("Your completed volunteer activities will appear here")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                            .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.historyRecords.prefix(3)) { record in
                                    let eventName = eventNames[record.eventId] ?? "Unknown Event"

                                    VolunteerActivityRow(activity: VolunteerActivity(
                                        title: eventName,
                                        timestamp: formatDate(record.dateCompleted ?? Date()),
                                        type: .event // Modify if different types exist
                                    ))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            Task {
                if let userId = authViewModel.user?.uid {
                    await viewModel.fetchVolunteerHistory(for: userId, db: authViewModel.db)
                    await fetchEventNames() // Fetch event names after history records are loaded
                }
            }
        }
    }
    
    // Fetch event names from Firestore based on eventIds in history
    private func fetchEventNames() async {
        let eventIds = viewModel.historyRecords.map { $0.eventId }
        var newEventNames: [String: String] = [:]

        for eventId in eventIds {
            do {
                let eventDoc = try await db.collection("events").document(eventId).getDocument()
                if let eventData = eventDoc.data(), let eventName = eventData["name"] as? String {
                    newEventNames[eventId] = eventName
                } else {
                    newEventNames[eventId] = "Unknown Event"
                }
            } catch {
                print("Error fetching event name for \(eventId): \(error.localizedDescription)")
                newEventNames[eventId] = "Unknown Event"
            }
        }

        DispatchQueue.main.async {
            self.eventNames = newEventNames
        }
    }

    // Helper method to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct VolunteerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerDashboardView()
            .environmentObject(AuthViewModel())
    }
}
