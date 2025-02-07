import SwiftUI

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
// Each button navigates to its respective view when tapped
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
        .frame(height: 90) // Fixed height for consistency
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
            // Activity icon with background
            Circle()
                .fill(activity.type.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: activity.type.icon)
                        .foregroundColor(activity.type.color)
                )
            
            // Activity details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.timestamp)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Navigation chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

// Recent events, volunteer matches, reports, etc. To be fed by backend
struct Activity {
    let title: String
    let timestamp: String
    let type: ActivityType
    
    enum ActivityType {
        case event, volunteer, report
        
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

struct AdminDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Sample activities - will be replaced with real data from backend
    @State private var activities: [Activity] = [
        Activity(title: "New Event Created: Beach Cleanup", timestamp: "2 hours ago", type: .event),
        Activity(title: "Volunteer Match: John D.", timestamp: "5 hours ago", type: .volunteer),
        Activity(title: "Monthly Report Generated", timestamp: "1 day ago", type: .report)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header section with welcome message and profile button
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
                
                // Overview section with key statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overview")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Active Events",
                            value: "12",
                            icon: "calendar",
                            color: .blue
                        )
                        StatCard(
                            title: "Total Volunteers",
                            value: "248",
                            icon: "person.2",
                            color: .green
                        )
                        StatCard(
                            title: "Hours Donated",
                            value: "1.2K",
                            icon: "clock",
                            color: .orange
                        )
                        StatCard(
                            title: "Success Rate",
                            value: "94%",
                            icon: "chart.bar",
                            color: .purple
                        )
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
                
                // Recent Activities section with scrollable list
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Recent Activities")
                            .font(.system(size: 24, weight: .bold))
                        
                        Spacer()
                        
                        Button("See All") {
                            // Navigate to full activity list
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    
                    // Activity list
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
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

