import SwiftUI
import FirebaseFirestore

struct AdminEditEventView: View {
    // Passed-in event
    let event: Event
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Form states
    @State private var formData: EventFormData
    @State private var validation = EventFormValidation()
    
    // Loading/error states
    @State private var showingDeleteConfirmation = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Volunteers assigned to the event
    @State private var assignedVolunteers: [User] = []
    @State private var isLoadingVolunteers = false
    
    // Confirmation dialog
    @State private var showingConfirmation = false
    @State private var confirmationDialog: ConfirmationDialog?
    
    // For completed events: volunteer history records
    @State private var volunteerHistories: [VolunteerHistoryRecord] = []
    
    // Available skills for toggling
    let availableSkills = [
        "Physical Labor",
        "Customer Service",
        "Teaching",
        "Technical",
        "Medical",
        "Administrative",
        "Environmental",
        "Social Work",
        "Mental Health",
        "Emergency Response"
    ]
    
    // Initialize form data from the event
    init(event: Event) {
        self.event = event
        _formData = State(initialValue: EventFormData(from: event))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if event.status == .completed {
                    // Completed event → Show volunteer feedback
                    feedbackSection
                } else {
                    // Ongoing event → Show normal editing UI
                    assignedVolunteersSection
                    eventEditForm
                    actionButtons
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Event has been updated successfully.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(confirmationDialog?.title ?? "", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(confirmationDialog?.primaryButtonText ?? "Confirm", role: .destructive) {
                confirmationDialog?.primaryAction()
            }
        } message: {
            Text(confirmationDialog?.message ?? "")
        }
        .disabled(isLoading)
        .onAppear {
            // If the event is completed, load volunteerHistory for feedback
            if event.status == .completed {
                fetchVolunteerHistories()
            } else {
                // Otherwise, load assigned volunteers for editing
                if !event.assignedVolunteers.isEmpty {
                    fetchAssignedVolunteers()
                }
            }
        }
    }
    
    
    /// Section to show feedback/performance fields for each volunteerHistory record
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Event Feedback")
                .font(.title2)
                .bold()
            
            if volunteerHistories.isEmpty {
                Text("No volunteer history found for this event.")
                    .foregroundColor(.secondary)
            } else {
                ForEach($volunteerHistories) { $record in
                    feedbackCard(for: $record)
                }
            }
        }
        .padding()
    }
    
    /// A single card for rating/feedback of one volunteer
    private func feedbackCard(for record: Binding<VolunteerHistoryRecord>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let name = record.wrappedValue.fullName {
                Text(name).font(.headline)
            } else {
                Text("Volunteer \(record.wrappedValue.volunteerId)")
                    .font(.headline)
            }
            
            Text("Performance")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            let rating = record.wrappedValue.performance["rating"] as? Int ?? 0
            Stepper("Rating: \(rating)", value: Binding(
                get: { rating },
                set: { newValue in
                    record.wrappedValue.performance["rating"] = newValue
                }
            ), in: 0...5)
            
            Text("Feedback")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: record.feedback)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
            
            Button(action: {
                saveVolunteerFeedback(record: record.wrappedValue)
            }) {
                Text("Save Feedback")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// Section to display and manage assigned volunteers (for non-completed events)
    var assignedVolunteersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Assigned Volunteers (\(event.assignedVolunteers.count))")
                    .font(.headline)
                
                Spacer()
                
                if isLoadingVolunteers {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button(action: fetchAssignedVolunteers) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // No volunteers
            if event.assignedVolunteers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                        Text("No volunteers assigned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Use the Volunteer Matching screen to assign volunteers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                }
            }
            // Loading
            else if isLoadingVolunteers && assignedVolunteers.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView().padding()
                        Text("Loading volunteers...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            // Volunteers loaded
            else {
                if assignedVolunteers.isEmpty {
                    // Prompt to load assigned volunteers
                    Button(action: fetchAssignedVolunteers) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Load \(event.assignedVolunteers.count) assigned volunteers")
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Show the list of assigned volunteers
                    VStack(spacing: 12) {
                        ForEach(assignedVolunteers, id: \.uid) { volunteer in
                            AssignedVolunteerView(volunteer: volunteer) {
                                // Confirmation to remove
                                confirmationDialog = ConfirmationDialog(
                                    title: "Remove Volunteer",
                                    message: "Are you sure you want to remove \(volunteer.fullName) from this event?",
                                    primaryButtonText: "Remove",
                                    primaryAction: {
                                        removeVolunteer(with: volunteer.uid)
                                    }
                                )
                                showingConfirmation = true
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
    
    /// The main form for editing event details (name, description, location, etc.)
    private var eventEditForm: some View {
        VStack(spacing: 20) {
            // Event Name
            FormField(title: "Event Name", error: validation.nameError) {
                TextField("Enter event name", text: $formData.name)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isLoading)
            }
            
            // Description
            FormField(title: "Description", error: validation.descriptionError) {
                TextEditor(text: $formData.description)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2))
                    )
                    .disabled(isLoading)
            }
            
            // Location
            GroupBox(label: Text("Location").font(.headline)) {
                VStack(spacing: 16) {
                    FormField(title: "Street Address", error: validation.addressError) {
                        TextField("Enter street address", text: $formData.address)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                    }
                    
                    FormField(title: "City", error: validation.cityError) {
                        TextField("Enter city", text: $formData.city)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                    }
                    
                    HStack(spacing: 16) {
                        FormField(title: "State/Province", error: validation.stateError) {
                            TextField("Enter state", text: $formData.state)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isLoading)
                        }
                        
                        FormField(title: "ZIP/Postal Code", error: nil) {
                            TextField("Enter ZIP code", text: $formData.zipCode)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isLoading)
                                .keyboardType(.numberPad)
                        }
                    }
                    
                    FormField(title: "Country", error: nil) {
                        TextField("Enter country", text: $formData.country)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Required Skills
            FormField(title: "Required Skills", error: validation.skillsError) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(availableSkills, id: \.self) { skill in
                            SkillToggleButton(
                                skill: skill,
                                isSelected: formData.requiredSkills.contains(skill),
                                action: {
                                    guard !isLoading else { return }
                                    if formData.requiredSkills.contains(skill) {
                                        formData.requiredSkills.remove(skill)
                                    } else {
                                        formData.requiredSkills.insert(skill)
                                    }
                                }
                            )
                            .opacity(isLoading ? 0.5 : 1)
                        }
                    }
                }
            }
            
            // Urgency
            FormField(title: "Urgency Level", error: nil) {
                Picker("Urgency", selection: $formData.urgency) {
                    ForEach(Event.UrgencyLevel.allCases, id: \.self) { level in
                        HStack {
                            Circle()
                                .fill(level.color)
                                .frame(width: 12, height: 12)
                            Text(level.rawValue)
                        }
                        .tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isLoading)
            }
            
            // Volunteer Requirements
            FormField(title: "Number of Volunteers Needed", error: validation.volunteerRequirementsError) {
                HStack {
                    Button(action: {
                        if !isLoading && formData.volunteerRequirements > 1 {
                            formData.volunteerRequirements -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .disabled(formData.volunteerRequirements <= 1 || isLoading)
                    
                    Text("\(formData.volunteerRequirements)")
                        .font(.title3)
                        .frame(width: 50)
                        .padding(.horizontal)
                    
                    Button(action: {
                        if !isLoading && formData.volunteerRequirements < 100 {
                            formData.volunteerRequirements += 1
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    .disabled(formData.volunteerRequirements >= 100 || isLoading)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemGray6))
                .cornerRadius(8)
            }
            
            // Event Date
            FormField(title: "Event Date", error: validation.dateError) {
                DatePicker("Select date", selection: $formData.date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .disabled(isLoading)
            }
            
            // Status
            FormField(title: "Event Status", error: nil) {
                Picker("Status", selection: $formData.status) {
                    ForEach(Event.EventStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
                .disabled(isLoading)
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
    }
    
    /// The bottom row of action buttons (Delete, Save)
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Delete
            Button(action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Event")
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(12)
            }
            .disabled(isLoading)
            
            // Save
            Button(action: saveEvent) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                        Text("Save Changes")
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    /// Validate and save the event to Firestore
    private func saveEvent() {
        validation.validate(event: formData)
        guard !validation.hasErrors else { return }
        
        guard let documentId = event.documentId else {
            errorMessage = "Cannot update event: missing document ID"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        Task {
            do {
                try await authViewModel.updateEvent(
                    eventId: documentId,
                    name: formData.name,
                    description: formData.description,
                    date: formData.date,
                    address: formData.address,
                    city: formData.city,
                    state: formData.state,
                    country: formData.country,
                    zipCode: formData.zipCode,
                    requiredSkills: Array(formData.requiredSkills),
                    urgency: formData.urgency,
                    volunteerRequirements: formData.volunteerRequirements,
                    status: formData.status
                )
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    /// Delete the event from Firestore
    private func deleteEvent() {
        guard let documentId = event.documentId else {
            errorMessage = "Cannot delete event: missing document ID"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        Task {
            do {
                try await authViewModel.deleteEvent(eventId: documentId)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    /// Fetch volunteer histories for a completed event
    func fetchVolunteerHistories() {
        guard let eventId = event.documentId else { return }
        
        Task {
            do {
                let snapshot = try await authViewModel.db.collection("volunteerHistory")
                    .whereField("eventId", isEqualTo: eventId)
                    .getDocuments()
                
                let records = snapshot.documents.map { VolunteerHistoryRecord(document: $0) }
                await MainActor.run {
                    self.volunteerHistories = records
                }
            } catch {
                print("Error fetching volunteerHistory: \(error.localizedDescription)")
            }
        }
    }
    
    /// Save feedback/performance to Firestore for one volunteerHistory record
    func saveVolunteerFeedback(record: VolunteerHistoryRecord) {
        Task {
            do {
                let updatedData: [String: Any] = [
                    "feedback": record.feedback,
                    "performance": record.performance
                ]
                try await authViewModel.db.collection("volunteerHistory")
                    .document(record.id)
                    .updateData(updatedData)
                print("Feedback saved for \(record.id)")
            } catch {
                print("Failed to save feedback: \(error.localizedDescription)")
            }
        }
    }
    
    /// Load assigned volunteers for an event that is not completed
    func fetchAssignedVolunteers() {
        guard let documentId = event.documentId else { return }
        guard !event.assignedVolunteers.isEmpty else {
            assignedVolunteers = []
            return
        }
        
        isLoadingVolunteers = true
        Task {
            do {
                var loadedVolunteers: [User] = []
                for volunteerId in event.assignedVolunteers {
                    guard !volunteerId.isEmpty else { continue }
                    
                    do {
                        let userDoc = try await authViewModel.db.collection("users").document(volunteerId).getDocument()
                        if userDoc.exists, let userData = userDoc.data() {
                            let user = parseUserData(userId: userDoc.documentID, data: userData)
                            loadedVolunteers.append(user)
                        }
                    } catch {
                        print("Error fetching volunteer \(volunteerId): \(error.localizedDescription)")
                    }
                }
                await MainActor.run {
                    assignedVolunteers = loadedVolunteers
                    isLoadingVolunteers = false
                }
            }
        }
    }
    
    /// Remove a volunteer from the assignedVolunteers array
    func removeVolunteer(with uid: String) {
        guard let documentId = event.documentId else { return }
        
        isLoadingVolunteers = true
        Task {
            do {
                let updatedVolunteers = event.assignedVolunteers.filter { $0 != uid }
                try await authViewModel.db.collection("events")
                    .document(documentId)
                    .updateData(["assignedVolunteers": updatedVolunteers])
                
                await MainActor.run {
                    // Locally update the assignedVolunteers array
                    assignedVolunteers = assignedVolunteers.filter { $0.uid != uid }
                    isLoadingVolunteers = false
                }
            } catch {
                print("Error removing volunteer: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingVolunteers = false
                    errorMessage = "Error removing volunteer: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    func parseUserData(userId: String, data: [String: Any]) -> User {
        let username = data["username"] as? String ?? ""
        let fullName = data["fullName"] as? String ?? data["name"] as? String ?? "Unnamed Volunteer"
        let email = data["email"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let role = data["role"] as? String ?? ""
        let preferences = data["preferences"] as? [String] ?? []
        let skills = data["skills"] as? [String] ?? []
        
        var location = User.Location(address: "", city: "", country: "", state: "", zipCode: "")
        if let locationData = data["location"] as? [String: Any] {
            location = User.Location(
                address: locationData["address"] as? String ?? "",
                city: locationData["city"] as? String ?? "",
                country: locationData["country"] as? String ?? "",
                state: locationData["state"] as? String ?? "",
                zipCode: locationData["zipCode"] as? String ?? ""
            )
        }
        
        // Or default availability
        var availability: [String: User.Availability] = [:]
        if let availabilityData = data["availability"] as? [String: [String: String]] {
            for (day, dict) in availabilityData {
                let startTime = dict["startTime"] ?? ""
                let endTime = dict["endTime"] ?? ""
                availability[day] = User.Availability(startTime: startTime, endTime: endTime)
            }
        }
        
        return User(
            uid: userId,
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
    }
}

/// A row for displaying a volunteer’s info with a remove button
extension AdminEditEventView {
    struct AssignedVolunteerView: View {
        let volunteer: User
        let onRemove: () -> Void
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(volunteer.fullName.isEmpty ? "Unnamed Volunteer" : volunteer.fullName)
                        .font(.headline)
                    
                    Text(volunteer.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !volunteer.skills.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(volunteer.skills, id: \.self) { skill in
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
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
}


/// A reusable view for labeling a form field and optionally showing an error
struct FormField<Content: View>: View {
    let title: String
    let error: String?
    let content: Content
    
    init(
        title: String,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.error = error
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            content
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

/// A button for toggling a skill on/off in the requiredSkills set
struct SkillToggleButton: View {
    let skill: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(skill)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(uiColor: .systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3))
                )
        }
    }
}

/// Simple struct for building a SwiftUI confirmation dialog
struct ConfirmationDialog {
    let title: String
    let message: String
    let primaryButtonText: String
    let primaryAction: () -> Void
}

struct AdminEditEventView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminEditEventView(
                event: Event(
                    name: "Beach Cleanup",
                    description: "Community beach cleanup event",
                    location: "Santa Monica Beach",
                    requiredSkills: ["Physical Labor", "Environmental"],
                    urgency: .medium,
                    date: Date().addingTimeInterval(86400 * 7),
                    status: .upcoming,
                    volunteerRequirements: 10
                )
            )
            .environmentObject(AuthViewModel())
        }
    }
}
