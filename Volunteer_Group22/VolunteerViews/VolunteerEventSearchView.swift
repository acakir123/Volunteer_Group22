import SwiftUI

// MARK: - Models
struct VolunteerEvent: Identifiable {
    let id = UUID()
    var name: String
    var description: String
    var location: String
    var requiredSkills: [String]
    var urgency: UrgencyLevel
    var date: Date
    var status: EventStatus
    var maxParticipants: Int
    var currentParticipants: Int
    
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
    
    enum EventStatus: String, CaseIterable {
        case upcoming = "Upcoming"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
        
        var color: Color {
            switch self {
            case .upcoming: return .blue
            case .inProgress: return .green
            case .completed: return .gray
            case .cancelled: return .red
            }
        }
    }
}

// MARK: - Components

struct VolunteerStatusBadge: View {
    let urgency: VolunteerEvent.UrgencyLevel
    
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

struct VolunteerEventSearchBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: VolunteerEvent.EventStatus?
    
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
                    
                    ForEach(VolunteerEvent.EventStatus.allCases, id: \.self) { status in
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

struct VolunteerEventListItem: View {
    let event: VolunteerEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.name)
                    .font(.headline)
                Spacer()
                VolunteerStatusBadge(urgency: event.urgency)
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
            
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.gray)
                Text("\(event.currentParticipants)/\(event.maxParticipants) participants")
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

// MARK: - Views
struct VolunteerEventSearchView: View {
    @State private var searchText = ""
    @State private var selectedFilter: VolunteerEvent.EventStatus?
    @State private var events: [VolunteerEvent] = []
    
    var filteredEvents: [VolunteerEvent] {
        events.filter { event in
            let matchesSearch = searchText.isEmpty ||
                event.name.localizedCaseInsensitiveContains(searchText) ||
                event.location.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter = selectedFilter == nil || event.status == selectedFilter
            
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        NavigationStack {
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
                    }
                    .padding(.horizontal)
                    
                    // Search and filters
                    VolunteerEventSearchBar(
                        searchText: $searchText,
                        selectedFilter: $selectedFilter
                    )
                    .padding(.horizontal)
                    
                    // Events list
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEvents) { event in
                            NavigationLink {
                                VolunteerEventDetailView(event: event)
                            } label: {
                                VolunteerEventListItem(event: event)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .onAppear {
                loadSampleEvents()
            }
        }
    }
    
    private func loadSampleEvents() {
        events = SampleEventGenerator.generateSampleEvents()
    }
}

struct VolunteerEventDetailView: View {
    let event: VolunteerEvent
    @State private var showingSignUpAlert = false
    @State private var showingSignUpConfirmation = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Event header section
                Group {
                    HStack {
                        Text(event.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        VolunteerStatusBadge(urgency: event.urgency)
                    }
                }
                
                // Event details section
                Group {
                    // Status
                    HStack {
                        Text(event.status.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(event.status.color.opacity(0.1))
                            .foregroundColor(event.status.color)
                            .cornerRadius(8)
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                        Text(event.location)
                    }
                    
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                        Text(event.date, style: .date)
                    }
                    
                    // Capacity
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.gray)
                        Text("\(event.currentParticipants) of \(event.maxParticipants) spots filled")
                        if event.currentParticipants >= event.maxParticipants {
                            Text("(Full)")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // About section
                Group {
                    Text("About")
                        .font(.headline)
                    Text(event.description)
                        .foregroundColor(.secondary)
                }
                
                // Required Skills section
                Group {
                    Text("Required Skills")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(event.requiredSkills, id: \.self) { skill in
                            Text(skill)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer(minLength: 20)
                
                // Sign up button
                if event.status == .upcoming {
                    Button(action: {
                        showingSignUpAlert = true
                    }) {
                        Text(event.currentParticipants >= event.maxParticipants ? "Join Waitlist" : "Sign Up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(event.status == .cancelled)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Up Confirmation", isPresented: $showingSignUpAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Up") {
                // Placeholder for backend signup logic
                showingSignUpConfirmation = true
            }
        } message: {
            Text("Would you like to sign up for this event?")
        }
        .alert("Success!", isPresented: $showingSignUpConfirmation) {
            Button("OK") {
                // Return to events list after successful signup
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("You have successfully signed up for this event. You will receive a confirmation email shortly.")
        }
    }
}

// MARK: - Sample Data Generator
struct SampleEventGenerator {
    static func generateSampleEvents() -> [VolunteerEvent] {
        return [
            VolunteerEvent(
                name: "Beach Cleanup",
                description: "Join us for our monthly beach cleanup event! Help keep our beaches clean and protect marine life. All cleaning supplies will be provided. Please wear comfortable clothes and bring water.",
                location: "Santa Monica Beach",
                requiredSkills: ["Physical Labor", "Environmental"],
                urgency: .medium,
                date: Date().addingTimeInterval(86400 * 7),
                status: .upcoming,
                maxParticipants: 50,
                currentParticipants: 32
            ),
            VolunteerEvent(
                name: "Food Bank Distribution",
                description: "Help distribute food to families in need at our weekly food bank event. Tasks include sorting donations, packing boxes, and assisting with distribution.",
                location: "Downtown Food Bank",
                requiredSkills: ["Organization", "Customer Service"],
                urgency: .high,
                date: Date().addingTimeInterval(86400 * 2),
                status: .upcoming,
                maxParticipants: 30,
                currentParticipants: 25
            ),
            VolunteerEvent(
                name: "Senior Center Tech Help",
                description: "Assist seniors with basic technology skills, including smartphone usage, email setup, and video calling with family.",
                location: "Sunshine Senior Center",
                requiredSkills: ["Technology", "Patience", "Teaching"],
                urgency: .low,
                date: Date().addingTimeInterval(86400 * 14),
                status: .upcoming,
                maxParticipants: 15,
                currentParticipants: 8
            ),
            VolunteerEvent(
                name: "Park Maintenance",
                description: "Help maintain our local park. Activities include planting, weeding, and general cleanup.",
                location: "Central Park",
                requiredSkills: ["Gardening", "Physical Labor"],
                urgency: .medium,
                date: Date().addingTimeInterval(86400 * 5),
                status: .inProgress,
                maxParticipants: 25,
                currentParticipants: 20
            ),
            VolunteerEvent(
                name: "Animal Shelter Care",
                description: "Completed event helping at the local animal shelter with feeding, cleaning, and socializing with animals.",
                location: "Happy Paws Shelter",
                requiredSkills: ["Animal Care", "Cleaning"],
                urgency: .low,
                date: Date().addingTimeInterval(-86400 * 2),
                status: .completed,
                maxParticipants: 20,
                currentParticipants: 18
            )
        ]
    }
}

// MARK: - Preview Providers
struct VolunteerEventSearchView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerEventSearchView()
    }
}

struct VolunteerEventDetailView_Previews: PreviewProvider {
    static var sampleEvent = VolunteerEvent(
        name: "Beach Cleanup",
        description: "Join us for our monthly beach cleanup event! Help keep our beaches clean and protect marine life. All cleaning supplies will be provided. Please wear comfortable clothes and bring water.",
        location: "Santa Monica Beach",
        requiredSkills: ["Physical Labor", "Environmental"],
        urgency: .medium,
        date: Date().addingTimeInterval(86400 * 7),
        status: .upcoming,
        maxParticipants: 50,
        currentParticipants: 32
    )
    
    static var previews: some View {
        NavigationStack {
            VolunteerEventDetailView(event: sampleEvent)
        }
    }
}

struct VolunteerEventListItem_Previews: PreviewProvider {
    static var sampleEvent = VolunteerEvent(
        name: "Food Bank Distribution",
        description: "Help distribute food to families in need at our weekly food bank event.",
        location: "Downtown Food Bank",
        requiredSkills: ["Organization", "Customer Service"],
        urgency: .high,
        date: Date().addingTimeInterval(86400 * 2),
        status: .upcoming,
        maxParticipants: 30,
        currentParticipants: 25
    )
    
    static var previews: some View {
        VolunteerEventListItem(event: sampleEvent)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct VolunteerStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            VolunteerStatusBadge(urgency: .low)
            VolunteerStatusBadge(urgency: .medium)
            VolunteerStatusBadge(urgency: .high)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct FilterChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 12) {
            FilterChip(title: "All", isSelected: true, action: {})
            FilterChip(title: "Upcoming", isSelected: false, action: {})
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Extensions
extension Date {
    func formattedEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func relativeDateString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension VolunteerEvent {
    var isFullyBooked: Bool {
        currentParticipants >= maxParticipants
    }
    
    var availableSpots: Int {
        max(0, maxParticipants - currentParticipants)
    }
    
    var capacityPercentage: Double {
        Double(currentParticipants) / Double(maxParticipants) * 100
    }
}


