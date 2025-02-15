import SwiftUI

// Model for past activities
struct PastActivity: Identifiable {
    let id = UUID()
    let eventTitle: String
    let eventDescription: String
    let eventDate: String
    let eventLocation: String
    let participationStatus: ParticipationStatus
    
    enum ParticipationStatus: String {
        case attended = "Attended"
        case canceled = "Canceled"
        case noShow = "No Show"
        
        var color: Color {
            switch self {
            case .attended:
                return .green
            case .canceled:
                return .orange
            case .noShow:
                return .red
            }
        }
    }
}

struct VolunteerHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Sample data for past activities
    @State private var activities: [PastActivity] = [
        PastActivity(
            eventTitle: "Community Cleanup",
            eventDescription: "Helped clean up local parks and streets.",
            eventDate: "Oct 15, 2023",
            eventLocation: "Central Park, NY",
            participationStatus: .attended
        ),
        PastActivity(
            eventTitle: "Food Drive",
            eventDescription: "Collected and distributed food to local shelters.",
            eventDate: "Sep 30, 2023",
            eventLocation: "Brooklyn Food Bank, NY",
            participationStatus: .canceled
        ),
        PastActivity(
            eventTitle: "Charity Run",
            eventDescription: "Participated in a 5K run to raise funds for charity.",
            eventDate: "Aug 20, 2023",
            eventLocation: "Prospect Park, NY",
            participationStatus: .noShow
        )
    ]
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Past Activities")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 16)
                Spacer()
            }
            .padding(.horizontal)
            
            // List of past activities
            List(activities) { activity in
                VStack(alignment: .leading, spacing: 8) {
                    // Event Title
                    Text(activity.eventTitle)
                        .font(.headline)
                    
                    // Event Description
                    Text(activity.eventDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Event Date and Location
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(activity.eventDate)
                            .font(.caption)
                        
                        Spacer()
                        
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.blue)
                        Text(activity.eventLocation)
                            .font(.caption)
                    }
                    
                    // Participation Status
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(activity.participationStatus.rawValue)
                            .font(.caption)
                            .foregroundColor(activity.participationStatus.color)
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct VolunteerHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerHistoryView()
            .environmentObject(AuthViewModel()) 
    }
}

