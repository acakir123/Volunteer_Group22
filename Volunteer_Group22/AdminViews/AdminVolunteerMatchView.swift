import SwiftUI

// Models
struct Volunteer: Identifiable {
    let id = UUID()
    let name: String
    let skills: Set<String>
    let availability: [Date]
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let preferences: String?
    
    var matchScore: Double = 0.0
}

struct VolunteerMatch: Identifiable {
    let id = UUID()
    let volunteer: Volunteer
    let event: Event
    let matchScore: Double
    let matchReasons: [String]
}

struct AdminVolunteerMatchView: View {
    @State private var selectedEvent: Event?
    @State private var selectedVolunteer: Volunteer?
    @State private var searchText = ""
    @State private var showingMatchConfirmation = false
    @State private var autoMatches: [VolunteerMatch] = []
    @State private var volunteers: [Volunteer] = []
    @State private var events: [Event] = []
    @State private var selectedSection: MatchSection = .volunteers
    
    enum MatchSection {
        case volunteers
        case events
    }
    
    // Filtered lists
    var filteredVolunteers: [Volunteer] {
        if searchText.isEmpty {
            return volunteers
        }
        return volunteers.filter { volunteer in
            volunteer.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredEvents: [Event] {
        events.filter { event in
            event.status == .upcoming
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volunteer Matching")
                        .font(.system(size: 32, weight: .bold))
                    Text("Match volunteers with upcoming events")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search \(selectedSection == .volunteers ? "volunteers" : "events")...", text: $searchText)
                    
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
                .padding(.horizontal)
                
                // Segment Control
                Picker("View", selection: $selectedSection) {
                    Text("Volunteers").tag(MatchSection.volunteers)
                    Text("Events").tag(MatchSection.events)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Selected items summary
                if selectedVolunteer != nil || selectedEvent != nil {
                    VStack(spacing: 12) {
                        if let volunteer = selectedVolunteer {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Selected Volunteer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(volunteer.name)
                                        .font(.headline)
                                }
                                Spacer()
                                Button(action: { selectedVolunteer = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        if let event = selectedEvent {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Selected Event")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(event.name)
                                        .font(.headline)
                                }
                                Spacer()
                                Button(action: { selectedEvent = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Main content
                if selectedSection == .volunteers {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredVolunteers) { volunteer in
                            VolunteerCard(
                                volunteer: volunteer,
                                isSelected: selectedVolunteer?.id == volunteer.id,
                                action: {
                                    if selectedVolunteer?.id == volunteer.id {
                                        selectedVolunteer = nil
                                    } else {
                                        selectedVolunteer = volunteer
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredEvents) { event in
                            EventCard(
                                event: event,
                                isSelected: selectedEvent?.id == event.id,
                                action: {
                                    if selectedEvent?.id == event.id {
                                        selectedEvent = nil
                                    } else {
                                        selectedEvent = event
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Match details
                if let volunteer = selectedVolunteer, let event = selectedEvent {
                    MatchDetailCard(
                        volunteer: volunteer,
                        event: event,
                        onMatch: { showingMatchConfirmation = true }
                    )
                    .padding(.horizontal)
                }
                
                // Auto-match suggestions
                if !autoMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suggested Matches")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(autoMatches) { match in
                                    SuggestedMatchCard(
                                        match: match,
                                        onAccept: { acceptMatch(match) }
                                    )
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
        .alert("Confirm Match", isPresented: $showingMatchConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm Match") {
                createMatch()
            }
        } message: {
            Text("Are you sure you want to match this volunteer with the selected event?")
        }
        .onAppear {
            loadSampleData()
            generateAutoMatches()
        }
    }

    
    private func loadSampleData() {
        // Sample volunteers
        volunteers = [
            Volunteer(
                name: "John Smith",
                skills: ["Physical Labor", "Environmental"],
                availability: [Date()],
                address: "123 Main St",
                city: "Springfield",
                state: "IL",
                zipCode: "62701",
                preferences: "Outdoor activities"
            ),
            Volunteer(
                name: "Jane Doe",
                skills: ["Physical Labor", "Environmental"],
                availability: [Date()],
                address: "123 Main St",
                city: "Los Angeles",
                state: "CA",
                zipCode: "90210",
                preferences: "Indoor activities"
            ),
            // Add more sample volunteers
        ]
        
        // Sample events (using existing Event model)
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
                name: "Homeless Shelter",
                description: "Volunteering at homeless shelter",
                location: "Santa Monica Shelter",
                requiredSkills: ["Cooking", "Environmental"],
                urgency: .medium,
                date: Date().addingTimeInterval(86400 * 7),
                status: .upcoming
            ),
            // Add more sample events
        ]
    }
    
    private func generateAutoMatches() {
        autoMatches = []
        
        for volunteer in volunteers {
            for event in events where event.status == .upcoming {
                // Calculate match score based on skills and availability
                let skillMatch = Double(volunteer.skills.intersection(Set(event.requiredSkills)).count) / Double(event.requiredSkills.count)
                
                if skillMatch > 0.5 {
                    let match = VolunteerMatch(
                        volunteer: volunteer,
                        event: event,
                        matchScore: skillMatch * 100,
                        matchReasons: [
                            "\(Int(skillMatch * 100))% skill match",
                            "Available on event date"
                        ]
                    )
                    autoMatches.append(match)
                }
            }
        }
        
        // Sort by match score
        autoMatches.sort { $0.matchScore > $1.matchScore }
    }
    
    private func createMatch() {
        // Here we will save the match to the backend
        selectedVolunteer = nil
        selectedEvent = nil
    }
    
    private func acceptMatch(_ match: VolunteerMatch) {
        selectedVolunteer = match.volunteer
        selectedEvent = match.event
        showingMatchConfirmation = true
    }
}

// MARK: - Supporting Views

struct VolunteerCard: View {
    let volunteer: Volunteer
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(volunteer.name)
                    .font(.headline)
                
                Text("\(volunteer.city), \(volunteer.state)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(volunteer.skills), id: \.self) { skill in
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventCard: View {
    let event: Event
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(event.name)
                        .font(.headline)
                    Spacer()
                    StatusBadge(urgency: event.urgency)
                }
                
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(event.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MatchDetailCard: View {
    let volunteer: Volunteer
    let event: Event
    let onMatch: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Match header
            HStack {
                Text("Match Details")
                    .font(.headline)
                Spacer()
                Button(action: onMatch) {
                    HStack {
                        Image(systemName: "link")
                        Text("Create Match")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            // Match details
            HStack(alignment: .top, spacing: 24) {
                // Volunteer details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Volunteer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(volunteer.name)
                        .font(.headline)
                    
                    Text("\(volunteer.city), \(volunteer.state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Event details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(event.name)
                        .font(.headline)
                    
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Skill match
            VStack(alignment: .leading, spacing: 8) {
                Text("Skill Match")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                let matchingSkills = volunteer.skills.intersection(Set(event.requiredSkills))
                ForEach(Array(matchingSkills), id: \.self) { skill in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(skill)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
    }
}

struct SuggestedMatchCard: View {
    let match: VolunteerMatch
    let onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(match.volunteer.name)
                        .font(.headline)
                    Text(match.event.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(match.matchScore))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ForEach(match.matchReasons, id: \.self) { reason in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: onAccept) {
                Text("Accept Match")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}


struct AdminVolunteerMatchView_Previews: PreviewProvider {
    static var previews: some View {
        AdminVolunteerMatchView()
    }
}
