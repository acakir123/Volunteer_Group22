import SwiftUI

// Search and filter bar
struct EventSearchBar: View {
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
struct FilterChip: View {
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
struct AdminEventManagementView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var searchText = ""
    @State private var selectedFilter: Event.EventStatus?
    @State private var showingCreateEvent = false
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
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Event Management")
                                .font(.system(size: 32, weight: .bold))
                            Text("Manage and track all events")
                                .font(.system(size: 17))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingCreateEvent = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Search and filters
                    EventSearchBar(
                        searchText: $searchText,
                        selectedFilter: $selectedFilter
                    )
                    .padding(.horizontal)
                    
                    // Events list
                    if errorMessage != nil {
                        // Error view
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            Text("Error loading events")
                                .font(.headline)
                            if let error = errorMessage {
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            Button(action: fetchEvents) {
                                Text("Try Again")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 50)
                        .padding()
                    } else if isLoading && events.isEmpty {
                        // Loading view (only show if no events are loaded)
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding(.bottom)
                            Text("Loading events...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else if filteredEvents.isEmpty {
                        // No events view
                        VStack(spacing: 16) {
                            if events.isEmpty {
                                // No events at all
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No events found")
                                    .font(.headline)
                                Text("Click the + button to create your first event.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            } else {
                                // No events matching filters
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No matching events")
                                    .font(.headline)
                                Text("Try adjusting your search or filters.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 50)
                        .padding()
                    } else {
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
                        
                        // Only show refresh button if events are loaded
                        if !events.isEmpty {
                            Button(action: fetchEvents) {
                                Label("Refresh Events", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.5 : 1)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .sheet(isPresented: $showingCreateEvent) {
                NavigationView {
                    AdminCreateEventView()
                        .environmentObject(authViewModel)
                        .onDisappear {
                            // Refresh the events when returning from creating a new event
                            fetchEvents()
                        }
                }
            }
            .refreshable {
                await refreshEvents()
            }
            .onAppear {
                fetchEvents()
            }
            
            // Overlay loading indicator
            if isLoading && !events.isEmpty {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
                    .background(Color(uiColor: .systemBackground).opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 5)
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

struct AdminEventManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminEventManagementView()
                .environmentObject(AuthViewModel())
        }
    }
}

