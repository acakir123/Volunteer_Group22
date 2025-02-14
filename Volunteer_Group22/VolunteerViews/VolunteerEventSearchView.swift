import SwiftUI

// Model for events
struct VolunteerEvent: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var location: String
    var requiredSkills: [String]
    var urgency: UrgencyLevel
    var date: Date
    var status: EventStatus
    
    enum UrgencyLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    enum EventStatus: String {
        case upcoming = "Upcoming"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
}

// Event list item component
struct VolunteerEventListItem: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.name)
                    .font(.headline)
                Spacer()
                StatusBadge(urgency: event.urgency)
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.gray)
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text(event.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(event.requiredSkills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Status badge component
struct VolunteerStatusBadge: View {
    let urgency: Event.UrgencyLevel
    
    var body: some View {
        Text(urgency.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(urgency.color.opacity(0.1))
            .foregroundColor(urgency.color)
            .cornerRadius(8)
    }
}

// Search and filter bar
struct VolunteerEventSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: Event.EventStatus?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search events...", text: $searchText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(Event.EventStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: selectedFilter == status,
                            action: { selectedFilter = status }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Filter chip component
struct VolunteerFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// Main view
struct VolunteerEventSearchView: View {
    @State private var searchText = ""
    @State private var selectedFilter: Event.EventStatus?
    @State private var showingCreateEvent = false
    @State private var events: [Event] = [] // Sample data here
    
    var filteredEvents: [Event] {
        events.filter { event in
            let matchesSearch = searchText.isEmpty ||
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter = selectedFilter == nil || event.status == selectedFilter
            
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Search for an event")
                            .font(.system(size: 32, weight: .bold))
                        Text("View all events below")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
//                    Button(action: { showingCreateEvent = true }) {
//                        Image(systemName: "plus.circle.fill")
//                            .font(.system(size: 32))
//                            .foregroundColor(.blue)
//                    }
                }
                .padding(.horizontal)
                
                // Search and filters
                EventSearchBar(
                    searchText: $searchText,
                    selectedFilter: $selectedFilter
                )
                .padding(.horizontal)
                
                // Events list
                LazyVStack(spacing: 16) {
                    ForEach(filteredEvents) { event in
                        NavigationLink(destination: AdminEditEventView(event: event)) {
                            EventListItem(event: event)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: $showingCreateEvent) {
            NavigationView {
                AdminCreateEventView()
            }
        }
        .onAppear {
            // Load sample data
            loadSampleEvents()
        }
    }
    
    private func loadSampleEvents() {
        events = [
            Event(
                name: "Beach Cleanup",
                description: "Community beach cleanup event",
                location: "Santa Monica Beach",
                requiredSkills: ["Physical Labor", "Environmental"],
                urgency: .medium,
                date: Date().addingTimeInterval(86400 * 7),
                status: .upcoming
            ),
            Event(
                name: "Food Bank Distribution",
                description: "Weekly food distribution",
                location: "Downtown Food Bank",
                requiredSkills: ["Organization", "Customer Service"],
                urgency: .high,
                date: Date().addingTimeInterval(86400 * 2),
                status: .upcoming
            ),
            // Add more sample events
        ]
    }
}

extension VolunteerEvent.EventStatus: CaseIterable {
    static var allCases: [Event.EventStatus] = [.upcoming, .inProgress, .completed, .cancelled]
}

#Preview {
    VolunteerEventSearchView()
        
}
