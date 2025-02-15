import SwiftUI


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
    
    // Sample activities for volunteer perspective
    @State private var activities: [VolunteerActivity] = [
        VolunteerActivity(title: "Signed up: Beach Cleanup", timestamp: "2 hours ago", type: .event),
        VolunteerActivity(title: "Logged 4 Hours: Park Maintenance", timestamp: "1 day ago", type: .hours),
        VolunteerActivity(title: "Achievement: 50 Hours Milestone", timestamp: "1 week ago", type: .achievement)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header section with welcome message and profile button
                VStack(spacing: 4) {
                    HStack {
                        Text("Welcome, Volunteer")
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
                        StatCard(
                            title: "Hours This Month",
                            value: "12",
                            icon: "clock",
                            color: .blue
                        )
                        StatCard(
                            title: "Total Hours",
                            value: "56",
                            icon: "sum",
                            color: .green
                        )
                        StatCard(
                            title: "Events Joined",
                            value: "8",
                            icon: "calendar",
                            color: .orange
                        )
                        StatCard(
                            title: "Achievements",
                            value: "5",
                            icon: "star",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                }
                
                // Quick Actions section with view-only actions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        NavigationLink(destination: VolunteerEventSearchView()) {
                            VolunteerActionButton(
                                title: "Browse Events",
                                icon: "calendar",
                                action: {}
                            )
                        }
                        
                        NavigationLink(destination: VolunteerHistoryView()) {
                            VolunteerActionButton(
                                title: "Track Hours",
                                icon: "clock",
                                action: {}
                            )
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
                        
                        Button("See All") {
                            // Navigate to full activity history
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(activities, id: \.title) { activity in
                            VolunteerActivityRow(activity: activity)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct VolunteerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerDashboardView()
    }
}
