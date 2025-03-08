import SwiftUI
import FirebaseFirestore

struct EventDetails {
    let name: String
    let eventDate: Date
}

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
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
}

struct VolunteerDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VolunteerHistoryViewModel()
    @State private var eventDetails: [String: EventDetails] = [:]
    private let db = Firestore.firestore()
    @State private var eventsJoinedCount: Int = 0
    @State private var totalHours: Int = 0
    @State private var hoursThisMonth: Int = 0
    @State private var eventsCompleted: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Impact")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Hours This Month", value: "\(hoursThisMonth)", icon: "clock", color: .blue)
                        StatCard(title: "Total Hours", value: "\(totalHours)", icon: "clock", color: .green)
                        StatCard(title: "Events Joined", value: "\(eventsJoinedCount)", icon: "calendar", color: .orange)
                        StatCard(title: "Events Completed", value: "\(eventsCompleted)", icon: "checkmark.seal", color: .purple)
                    }
                    .padding(.horizontal)
                }
                
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
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(viewModel.historyRecords.prefix(3)) { record in
                                    let eventDetail = eventDetails[record.eventId] ??
                                        EventDetails(name: "Unknown Event", eventDate: Date())
                                    
                                    VolunteerActivityRow(activity: VolunteerActivity(
                                        title: eventDetail.name,
                                        timestamp: formatDate(eventDetail.eventDate),
                                        type: .event
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
                if let user = authViewModel.user {
                    do {
                        let userDocSnapshot = try await db.collection("users").document(user.uid).getDocument()
                        
                        let firebaseDocID = userDocSnapshot.documentID
                        
                        await viewModel.fetchVolunteerHistory(for: user.uid, db: authViewModel.db)
                        
                        await fetchEventDetails()
                       
                        await MainActor.run {
                            self.hoursThisMonth = self.fetchHoursThisMonth(firebaseDocID: firebaseDocID)
                        }
                        
                        await fetchEventsJoined(firebaseDocID: firebaseDocID)
                        
                        let hours = await fetchTotalHoursDonated(firebaseDocID: firebaseDocID)
                        await MainActor.run {
                            self.totalHours = hours
                        }
                        
                        let completed = await fetchEventsCompleted(firebaseDocID: firebaseDocID)
                        await MainActor.run {
                            self.eventsCompleted = completed
                        }
                    } catch {
                        print("Error loading dashboard data: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func fetchEventDetails() async {
        let eventIds = viewModel.historyRecords.map { $0.eventId }
        
        var newEventDetails: [String: EventDetails] = [:]
        
        for eventId in eventIds {
            do {
                let eventDoc = try await db.collection("events").document(eventId).getDocument()
                
                if let eventData = eventDoc.data() {
                    let eventName = eventData["name"] as? String ?? "Unknown Event"
                    var eventDate = Date()
                    if let timestamp = eventData["dateTime"] as? Timestamp {
                        eventDate = timestamp.dateValue()
                    } else if let timestamp = eventData["date"] as? Timestamp {
                        eventDate = timestamp.dateValue()
                    } else {
                        print("No date field found for event")
                    }
                    
                    newEventDetails[eventId] = EventDetails(name: eventName, eventDate: eventDate)
                } else {
                    print("No data found for event: \(eventId)")
                    newEventDetails[eventId] = EventDetails(name: "Unknown Event", eventDate: Date())
                }
            } catch {
                print("Error fetching event details for \(eventId): \(error.localizedDescription)")
                newEventDetails[eventId] = EventDetails(name: "Unknown Event", eventDate: Date())
            }
        }
        await MainActor.run {
            self.eventDetails = newEventDetails
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func fetchEventsJoined(firebaseDocID: String) async {
        do {
            let snapshot = try await db.collection("events")
                .whereField("assignedVolunteers", arrayContains: firebaseDocID)
                .getDocuments()
            DispatchQueue.main.async {
                self.eventsJoinedCount = snapshot.documents.count
            }
        } catch {
            print("Error fetching events joined: \(error.localizedDescription)")
        }
    }
    
    private func fetchTotalHoursDonated(firebaseDocID: String) async -> Int {
        do {
            let snapshot = try await db.collection("events")
                .whereField("assignedVolunteers", arrayContains: firebaseDocID)
                .getDocuments()
            return snapshot.documents.count * 3
        } catch {
            print("Error fetching total hours donated: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func fetchHoursThisMonth(firebaseDocID: String) -> Int {
        let calendar = Calendar.current
        let now = Date()
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            return 0
        }
        
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: startOfMonth) else {
            return 0
        }
        
        let thisMonthEvents = viewModel.historyRecords.filter { record in
            if let eventDetail = eventDetails[record.eventId] {
                return eventDetail.eventDate >= startOfMonth && eventDetail.eventDate <= endOfMonth
            }
            return false
        }
        
        return thisMonthEvents.count * 3
    }
    
    private func fetchEventsCompleted(firebaseDocID: String) async -> Int {
        do {
            let snapshot = try await db.collection("events")
                .whereField("assignedVolunteers", arrayContains: firebaseDocID)
                .whereField("status", isEqualTo: "Completed")
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching events completed: \(error.localizedDescription)")
            return 0
        }
    }
}
struct VolunteerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerDashboardView()
            .environmentObject(AuthViewModel())
    }
}

