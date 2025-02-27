import SwiftUI
import FirebaseFirestore

// Match result structure
struct VolunteerMatch: Identifiable {
    let id = UUID()
    let volunteer: Volunteer
    let event: Event
    let matchScore: Double
    let matchReasons: [String]
}


struct Volunteer: Identifiable {
    let id = UUID()
    let user: User
    var matchScore: Double = 0.0
    
    var name: String { user.fullName.isEmpty ? "Unnamed Volunteer" : user.fullName }
    var skills: Set<String> { Set(user.skills) }
    var availability: [Date] {
        return user.availability.compactMap { (_, value) in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.date(from: value.startTime)
        }
    }
    var address: String { user.location.address }
    var city: String { user.location.city }
    var state: String { user.location.state }
    var zipCode: String { user.location.zipCode }
    var preferences: String? { user.preferences.joined(separator: ", ") }
    
    var isProfileComplete: Bool {
        return !user.location.address.isEmpty && !user.fullName.isEmpty && !user.skills.isEmpty
    }
}

struct AdminVolunteerMatchView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var selectedEvent: Event?
    @State private var selectedVolunteer: Volunteer?
    @State private var searchText = ""
    @State private var showingMatchConfirmation = false
    @State private var autoMatches: [VolunteerMatch] = []
    @State private var volunteers: [Volunteer] = []
    @State private var events: [Event] = []
    @State private var selectedSection: MatchSection = .volunteers
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var assignedVolunteersMap: [String: [String]] = [:]
    
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
        if searchText.isEmpty {
            return events.filter { event in
                event.status == .upcoming
            }
        }
        return events.filter { event in
            event.status == .upcoming &&
            (event.name.localizedCaseInsensitiveContains(searchText) ||
             event.description.localizedCaseInsensitiveContains(searchText))
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
                
                // Loading or error states
                if isLoading && volunteers.isEmpty && events.isEmpty {
                    ProgressView("Loading data...")
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 8) {
                        Text("Error loading data")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            fetchData()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    // Main content
                    if selectedSection == .volunteers {
                        if filteredVolunteers.isEmpty {
                            Text("No volunteers found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredVolunteers) { volunteer in
                                    let isAssigned = selectedEvent != nil ?
                                        isVolunteerAssignedToEvent(volunteer: volunteer, event: selectedEvent!) :
                                        false
                                    
                                    VolunteerCard(
                                        volunteer: volunteer,
                                        isSelected: selectedVolunteer?.id == volunteer.id,
                                        isAssigned: isAssigned,
                                        event: selectedEvent,
                                        action: {
                                            if isAssigned {
                                                // Do nothing if already assigned
                                                return
                                            }
                                            
                                            if selectedVolunteer?.id == volunteer.id {
                                                selectedVolunteer = nil
                                            } else {
                                                selectedVolunteer = volunteer
                                                // Update auto matches when volunteer is selected
                                                if let event = selectedEvent {
                                                    generateMatchScore(volunteer: volunteer, event: event)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        if filteredEvents.isEmpty {
                            Text("No upcoming events found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding()
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
                                                // Update auto matches when event is selected
                                                if let volunteer = selectedVolunteer {
                                                    generateMatchScore(volunteer: volunteer, event: event)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Match details
                if let volunteer = selectedVolunteer, let event = selectedEvent {
                    let isAlreadyAssigned = isVolunteerAssignedToEvent(volunteer: volunteer, event: event)
                    
                    MatchDetailCard(
                        volunteer: volunteer,
                        event: event,
                        isAlreadyAssigned: isAlreadyAssigned,
                        onMatch: {
                            if !isAlreadyAssigned {
                                showingMatchConfirmation = true
                            }
                        }
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
                                    let isAssigned = isVolunteerAssignedToEvent(
                                        volunteer: match.volunteer,
                                        event: match.event
                                    )
                                    
                                    SuggestedMatchCard(
                                        match: match,
                                        isAlreadyAssigned: isAssigned,
                                        onAccept: {
                                            if !isAssigned {
                                                acceptMatch(match)
                                            }
                                        }
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
            fetchData()
        }
        .overlay(
            Group {
                if isLoading && !(volunteers.isEmpty && events.isEmpty) {
                    ProgressView()
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
        )
    }

    // Fetch real data from Firestore
    private func fetchData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedEvents = try await authViewModel.fetchEvents(db: authViewModel.db)
                
                let users = try await fetchVolunteers()
                
                // Map users to volunteers and filter out incomplete profiles
                let allVolunteers = users.map { user in
                    Volunteer(user: user)
                }
                
                // Filter out incomplete profiles
                let completedVolunteers = allVolunteers.filter { volunteer in
                    return !volunteer.user.location.address.isEmpty &&
                           !volunteer.user.fullName.isEmpty &&
                           !volunteer.user.skills.isEmpty
                }
                
                await MainActor.run {
                    events = fetchedEvents
                    volunteers = completedVolunteers
                    
                    assignedVolunteersMap = getAssignedVolunteersMap()
                    
                    isLoading = false
                    
                    if !volunteers.isEmpty && !events.isEmpty {
                        generateAutoMatches()
                    } else {
                        print("Not generating matches because either volunteers (\(volunteers.count)) or events (\(events.count)) is empty")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error: \(error.localizedDescription)"
                    isLoading = false
                }
                print("ERROR fetching data: \(error)")
            }
        }
    }
    
    // Fetch users with "volunteer" role
    private func fetchVolunteers() async throws -> [User] {
        let db = authViewModel.db
        
        let allUsersSnapshot = try await db.collection("users").getDocuments()
        print("DEBUG: Total users in database: \(allUsersSnapshot.documents.count)")
        
        for doc in allUsersSnapshot.documents {
            let data = doc.data()
            print("DEBUG: User ID: \(doc.documentID), email: \(data["email"] as? String ?? "no email"), role: \(data["role"] as? String ?? "no role")")
        }
        
        let snapshot = try await db.collection("users").getDocuments()
        
        var users: [User] = []
        
        for document in snapshot.documents {
            let data = document.data()
            let uid = document.documentID
            
            let role = data["role"] as? String ?? ""
            
            if role.isEmpty || (!role.lowercased().contains("volunteer") && role != "user") {
                print("DEBUG: Skipping user \(uid) with role '\(role)'")
                continue
            }
            
            let username = data["username"] as? String ?? ""
            let fullName = data["fullName"] as? String ?? data["name"] as? String ?? "Unnamed Volunteer"
            let email = data["email"] as? String ?? ""
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            let preferences = data["preferences"] as? [String] ?? []
            let skills = data["skills"] as? [String] ?? []
            
            var location: User.Location
            if let locationData = data["location"] as? [String: Any] {
                location = User.Location(
                    address: locationData["address"] as? String ?? "",
                    city: locationData["city"] as? String ?? "",
                    country: locationData["country"] as? String ?? "",
                    state: locationData["state"] as? String ?? "",
                    zipCode: locationData["zipCode"] as? String ?? ""
                )
            } else {
                location = User.Location(
                    address: data["address1"] as? String ?? data["address"] as? String ?? "",
                    city: data["city"] as? String ?? "",
                    country: data["country"] as? String ?? "",
                    state: data["state"] as? String ?? "",
                    zipCode: data["zipCode"] as? String ?? ""
                )
            }
            
            var availability: [String: User.Availability] = [:]
            if let availabilityData = data["availability"] as? [String: [String: String]] {
                for (day, dict) in availabilityData {
                    let startTime = dict["startTime"] ?? ""
                    let endTime = dict["endTime"] ?? ""
                    availability[day] = User.Availability(
                        startTime: startTime,
                        endTime: endTime
                    )
                }
            } else {
                let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
                for day in weekdays {
                    availability[day] = User.Availability(startTime: "09:00", endTime: "17:00")
                }
            }
            
            do {
                let user = User(
                    uid: uid,
                    username: username,
                    fullName: fullName,
                    email: email,
                    createdAt: createdAt,
                    role: role,
                    preferences: preferences,
                    skills: skills,
                    location: location,
                    availability: availability
                )
                
                users.append(user)
                print("Successfully added user \(uid) to volunteers list")
            } catch {
                print("Error creating User object: \(error.localizedDescription)")
            }
        }
        return users
    }
    
    // Generate auto-matches based on volunteers and events
    private func generateAutoMatches() {
        autoMatches = []
        
        let upcomingEvents = events.filter { $0.status == .upcoming }
        
        let eligibleVolunteers = volunteers.filter { $0.isProfileComplete }
        
        for volunteer in eligibleVolunteers {
            for event in upcomingEvents {
                if isVolunteerAssignedToEvent(volunteer: volunteer, event: event) {
                    continue
                }
                
                let (score, reasons) = calculateMatchScore(volunteer: volunteer, event: event)
                
                // Only suggest matches with decent scores (above 50%)
                if score > 50 {
                    let match = VolunteerMatch(
                        volunteer: volunteer,
                        event: event,
                        matchScore: score,
                        matchReasons: reasons
                    )
                    autoMatches.append(match)
                }
            }
        }
        
        autoMatches.sort { $0.matchScore > $1.matchScore }
        
        if autoMatches.count > 10 {
            autoMatches = Array(autoMatches.prefix(10))
        }
    }
    
    // Calculate match score and reasons for a volunteer and event
    private func calculateMatchScore(volunteer: Volunteer, event: Event) -> (Double, [String]) {
        var score = 0.0
        var reasons: [String] = []
        
        let requiredSkillsSet = Set(event.requiredSkills)
        let volunteerSkillsSet = volunteer.skills
        
        let matchingSkillsCount = volunteerSkillsSet.intersection(requiredSkillsSet).count
        let skillsMatchPercentage = requiredSkillsSet.isEmpty ? 100.0 :
            (Double(matchingSkillsCount) / Double(requiredSkillsSet.count)) * 100.0
        
        score += skillsMatchPercentage * 0.7
        
        if matchingSkillsCount > 0 {
            reasons.append("\(Int(skillsMatchPercentage))% skills match (\(matchingSkillsCount)/\(requiredSkillsSet.count))")
        }
        
        let eventDay = Calendar.current.component(.weekday, from: event.date)
        let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        
        if eventDay >= 1 && eventDay <= 7 {
            let eventDayString = weekdays[eventDay - 1]
            if let availability = volunteer.user.availability[eventDayString] {
                if !availability.startTime.isEmpty && !availability.endTime.isEmpty {
                    score += 20.0
                    reasons.append("Available on event day")
                }
            }
        }
        
        if volunteer.city.lowercased() == event.location.lowercased() {
            score += 10.0
            reasons.append("Same location")
        } else if volunteer.state.lowercased() == event.location.lowercased() {
            score += 5.0
            reasons.append("Same state/region")
        }
        
        if let preferences = volunteer.preferences {
            if preferences.lowercased().contains(event.name.lowercased()) ||
               preferences.lowercased().contains(event.description.lowercased()) {
                score += 10.0
                reasons.append("Matches volunteer preferences")
            }
        }
        
        // Cap the score at 100
        score = min(score, 100.0)
        
        return (score, reasons)
    }
    
    // Update match score for a selected volunteer and event
    private func generateMatchScore(volunteer: Volunteer, event: Event) {
        let (score, reasons) = calculateMatchScore(volunteer: volunteer, event: event)
        
        let match = VolunteerMatch(
            volunteer: volunteer,
            event: event,
            matchScore: score,
            matchReasons: reasons
        )
        
        autoMatches = [match]
    }
    
    // Accept a suggested match
    private func acceptMatch(_ match: VolunteerMatch) {
        selectedVolunteer = match.volunteer
        selectedEvent = match.event
        showingMatchConfirmation = true
    }
    
    // Assign volunteer to event by adding to assignedVolunteers array
    private func createMatch() {
        guard let volunteer = selectedVolunteer, let event = selectedEvent else { return }
        
        isLoading = true
        
        Task {
            do {
                guard let eventId = event.documentId else {
                    throw NSError(domain: "VolunteerMatch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Event has no document ID"])
                }
                
                var updatedAssignedVolunteers = event.assignedVolunteers
                
                if !updatedAssignedVolunteers.contains(volunteer.user.uid) {
                    updatedAssignedVolunteers.append(volunteer.user.uid)
                    
                    // Update the event document in Firestore
                    try await authViewModel.db.collection("events").document(eventId).updateData([
                        "assignedVolunteers": updatedAssignedVolunteers
                    ])
                } else {
                    print("Volunteer \(volunteer.user.uid) is already assigned to event \(eventId)")
                }
                
                await MainActor.run {
                    // Reset selection
                    selectedVolunteer = nil
                    selectedEvent = nil
                    isLoading = false
                    
                    // Refresh data to update the UI
                    fetchData()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to assign volunteer: \(error.localizedDescription)"
                    isLoading = false
                }
                print("ERROR assigning volunteer: \(error)")
            }
        }
    }
    
    // Helper method to check if a volunteer is already assigned to an event
    func isVolunteerAssignedToEvent(volunteer: Volunteer, event: Event) -> Bool {
        return event.assignedVolunteers.contains(volunteer.user.uid)
    }
    
    // Helper method to get all volunteers assigned to any event
    func getAssignedVolunteersMap() -> [String: [String]] {
        var assignedMap: [String: [String]] = [:]
        
        for event in events {
            for volunteerId in event.assignedVolunteers {
                if volunteerId.isEmpty { continue }
                
                if assignedMap[volunteerId] == nil {
                    assignedMap[volunteerId] = [event.documentId ?? ""]
                } else {
                    assignedMap[volunteerId]?.append(event.documentId ?? "")
                }
            }
        }
        
        return assignedMap
    }
}

// MARK: - Supporting Views
struct VolunteerCard: View {
    let volunteer: Volunteer
    let isSelected: Bool
    let isAssigned: Bool
    let event: Event?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(volunteer.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isAssigned {
                        Text("Already Assigned")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .cornerRadius(8)
                    }
                    else if !volunteer.isProfileComplete {
                        Text("Incomplete")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                }
                
                if !volunteer.city.isEmpty || !volunteer.state.isEmpty {
                    Text("\(volunteer.city)\(volunteer.city.isEmpty || volunteer.state.isEmpty ? "" : ", ")\(volunteer.state)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if !volunteer.isProfileComplete {
                    Text("No location information")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                if !volunteer.skills.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
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
                } else if !volunteer.isProfileComplete {
                    Text("No skills listed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.blue.opacity(0.1) :
                isAssigned ? Color.gray.opacity(0.1) :
                Color(uiColor: .systemBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue :
                        isAssigned ? Color.gray :
                        Color.clear,
                        lineWidth: 2
                    )
            )
            .opacity(isAssigned ? 0.7 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAssigned)
    }
}

struct EventCard: View {
    let event: Event
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
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
                    HStack(spacing: 8) {
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
            .padding(16)
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
    let isAlreadyAssigned: Bool
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
                .disabled(!volunteer.isProfileComplete || isAlreadyAssigned)
                .opacity((!volunteer.isProfileComplete || isAlreadyAssigned) ? 0.5 : 1.0)
            }
            
            // Warning for already assigned volunteer
            if isAlreadyAssigned {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.gray)
                    
                    Text("This volunteer is already assigned to this event.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            else if !volunteer.isProfileComplete {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("This volunteer has an incomplete profile. They may need to add more information before being matched to events.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
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
                    
                    if !volunteer.city.isEmpty || !volunteer.state.isEmpty {
                        Text("\(volunteer.city)\(volunteer.city.isEmpty || volunteer.state.isEmpty ? "" : ", ")\(volunteer.state)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No location information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
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
                if matchingSkills.isEmpty {
                    Text("No matching skills")
                        .foregroundColor(.orange)
                } else {
                    ForEach(Array(matchingSkills), id: \.self) { skill in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(skill)
                        }
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
    let isAlreadyAssigned: Bool
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
                    .foregroundColor(isAlreadyAssigned ? .gray : .blue)
            }
            
            // Show "Already assigned" indicator if applicable
            if isAlreadyAssigned {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gray)
                    Text("Already assigned to event")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                ForEach(match.matchReasons, id: \.self) { reason in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: onAccept) {
                Text(isAlreadyAssigned ? "Already Assigned" : "Accept Match")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isAlreadyAssigned ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isAlreadyAssigned)
        }
        .padding()
        .frame(width: 300)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(isAlreadyAssigned ? 0.7 : 1)
    }
}
