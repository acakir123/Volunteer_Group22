import SwiftUI


// MARK: - Components

struct VolunteerStatusBadge: View {
    @EnvironmentObject var authViewModel: AuthViewModel
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

struct VolunteerEventListItem: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let event: Event
    
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
                Text("\(event.assignedVolunteers.count) participants")
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
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @State private var selectedFilter: Event.EventStatus?
    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
            .refreshable {
                await refreshEvents()
            }
            .onAppear {
                fetchEvents()
            }
        }
    }
    
    private func fetchEvents() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Access the Firestore db from the AuthViewModel
                let fetchedEvents = try await authViewModel.fetchEvents(db: authViewModel.db)
                
                // Check if any events have ended
                try await authViewModel.generateVolunteerHistoryRecords()
                
                await MainActor.run {
                    events = fetchedEvents
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
                print("Error fetching events: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Access the Firestore db from the AuthViewModel
            let fetchedEvents = try await authViewModel.fetchEvents(db: authViewModel.db)
            
            await MainActor.run {
                events = fetchedEvents
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            print("Error refreshing events: \(error.localizedDescription)")
        }
    }
}


enum VolunteerEventAlert: Identifiable {
    case signUpConfirmation, signUpSuccess
    
    var id: Int {
        hashValue
    }
}

struct VolunteerEventDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let event: Event
    @State private var activeAlert: VolunteerEventAlert?
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var selectedEvent: Event?
    @State private var selectedVolunteer: Volunteer?
    @State private var errorMessage: String?

    
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
                if event.status == .upcoming {//only shows if event is upcoming
                    Button(action: {
                        activeAlert = .signUpConfirmation
                    }) {
                        Text(event.assignedVolunteers.count >= event.volunteerRequirements ? "Join Waitlist" : "Sign Up")
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
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .signUpConfirmation:
                return Alert(
                    title: Text("Sign Up Confirmation"),
                    message: Text("Would you like to sign up for this event?"),
                    primaryButton: .default(Text("Sign Up"), action: {
                        Task {
                                do {
                                    if event.assignedVolunteers.count >= event.volunteerRequirements {
                                        print("Event is full")
                                    } else{
                                        try await authViewModel.signUp(for: event)
                                        // Handle success (e.g., show a confirmation alert or update the UI
                                        activeAlert = .signUpSuccess
                                    }
                                } catch {
                                    // Handle error (e.g., show an error message)
                                    print("Error signing up: \(error.localizedDescription)")
                                }
                            }
                    }),
                    secondaryButton: .cancel()
                )
            case .signUpSuccess:
                return Alert(
                    title: Text("Success!"),
                    message: Text("You have successfully signed up for this event. You will receive a confirmation email shortly."),
                    dismissButton: .default(Text("OK"), action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            }
        }

    }
    
    
    //Function to create a volunteer match -- adding the volunteer to the 'assignedVolunteers' list in the event document in Firestore
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
                    print("Volunteer (volunteer.user.uid) is already assigned to event (eventId)")
                }

                await MainActor.run {
                    // Reset selection
                    selectedVolunteer = nil
                    selectedEvent = nil
                    isLoading = false

                    // Refresh data to update the UI
                    //fetchData()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to assign volunteer: (error.localizedDescription)"
                    isLoading = false
                }
                print("ERROR assigning volunteer: (error)")
            }
        }
    }
    
    
}


// MARK: - Preview Providers
struct VolunteerEventSearchView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerEventSearchView()
    }
}

//struct VolunteerEventDetailView_Previews: PreviewProvider {
//    static var sampleEvent = VolunteerEvent(
//        name: "Beach Cleanup",
//        description: "Join us for our monthly beach cleanup event! Help keep our beaches clean and protect marine life. All cleaning supplies will be provided. Please wear comfortable clothes and bring water.",
//        location: "Santa Monica Beach",
//        requiredSkills: ["Physical Labor", "Environmental"],
//        urgency: .medium,
//        date: Date().addingTimeInterval(86400 * 7),
//        status: .upcoming,
//        maxParticipants: 50,
//        currentParticipants: 32
//    )
//    
//    static var previews: some View {
//        NavigationStack {
//            VolunteerEventDetailView(event: sampleEvent)
//        }
//    }
//}
//
//struct VolunteerEventListItem_Previews: PreviewProvider {
//    static var sampleEvent = VolunteerEvent(
//        name: "Food Bank Distribution",
//        description: "Help distribute food to families in need at our weekly food bank event.",
//        location: "Downtown Food Bank",
//        requiredSkills: ["Organization", "Customer Service"],
//        urgency: .high,
//        date: Date().addingTimeInterval(86400 * 2),
//        status: .upcoming,
//        maxParticipants: 30,
//        currentParticipants: 25
//    )
//    
//    static var previews: some View {
//        VolunteerEventListItem(event: sampleEvent)
//            .padding()
//            .previewLayout(.sizeThatFits)
//    }
//}
//
//struct VolunteerStatusBadge_Previews: PreviewProvider {
//    static var previews: some View {
//        VStack(spacing: 20) {
//            VolunteerStatusBadge(urgency: .low)
//            VolunteerStatusBadge(urgency: .medium)
//            VolunteerStatusBadge(urgency: .high)
//        }
//        .padding()
//        .previewLayout(.sizeThatFits)
//    }
//}

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



