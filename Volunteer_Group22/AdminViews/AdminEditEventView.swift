import SwiftUI

// Custom form field components
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

// Main view
struct AdminEditEventView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var formData: EventFormData
    @State private var validation = EventFormValidation()
    @State private var showingDeleteConfirmation = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    // Available skills
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
    
    init(event: Event) {
        self.event = event
        _formData = State(initialValue: EventFormData(from: event))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Form fields
                VStack(spacing: 20) {
                    // Event Name
                    FormField(
                        title: "Event Name",
                        error: validation.nameError
                    ) {
                        TextField("Enter event name", text: $formData.name)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                    }
                    
                    // Description
                    FormField(
                        title: "Description",
                        error: validation.descriptionError
                    ) {
                        TextEditor(text: $formData.description)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                            .disabled(isLoading)
                    }
                    
                    // Location Section
                    GroupBox(
                        label: Text("Location")
                            .font(.headline)
                    ) {
                        VStack(spacing: 16) {
                            // Street Address
                            FormField(
                                title: "Street Address",
                                error: validation.addressError
                            ) {
                                TextField("Enter street address", text: $formData.address)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(isLoading)
                            }
                            
                            // City
                            FormField(
                                title: "City",
                                error: validation.cityError
                            ) {
                                TextField("Enter city", text: $formData.city)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(isLoading)
                            }
                            
                            // State and Zip in the same row
                            HStack(spacing: 16) {
                                // State/Province
                                FormField(
                                    title: "State/Province",
                                    error: validation.stateError
                                ) {
                                    TextField("Enter state", text: $formData.state)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isLoading)
                                }
                                
                                // ZIP/Postal Code
                                FormField(
                                    title: "ZIP/Postal Code",
                                    error: nil
                                ) {
                                    TextField("Enter ZIP code", text: $formData.zipCode)
                                        .textFieldStyle(.roundedBorder)
                                        .disabled(isLoading)
                                        .keyboardType(.numberPad)
                                }
                            }
                            
                            // Country
                            FormField(
                                title: "Country",
                                error: nil
                            ) {
                                TextField("Enter country", text: $formData.country)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(isLoading)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Required Skills
                    FormField(
                        title: "Required Skills",
                        error: validation.skillsError
                    ) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(availableSkills, id: \.self) { skill in
                                    SkillToggleButton(
                                        skill: skill,
                                        isSelected: formData.requiredSkills.contains(skill),
                                        action: {
                                            if !isLoading {
                                                if formData.requiredSkills.contains(skill) {
                                                    formData.requiredSkills.remove(skill)
                                                } else {
                                                    formData.requiredSkills.insert(skill)
                                                }
                                            }
                                        }
                                    )
                                    .opacity(isLoading ? 0.5 : 1)
                                }
                            }
                        }
                    }
                    
                    // Urgency
                    FormField(
                        title: "Urgency Level",
                        error: nil
                    ) {
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
                    FormField(
                        title: "Number of Volunteers Needed",
                        error: validation.volunteerRequirementsError
                    ) {
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
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Event Date
                    FormField(
                        title: "Event Date",
                        error: validation.dateError
                    ) {
                        DatePicker(
                            "Select date",
                            selection: $formData.date,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .disabled(isLoading)
                    }
                    
                    // Status
                    FormField(
                        title: "Event Status",
                        error: nil
                    ) {
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
                
                // Action buttons
                HStack(spacing: 16) {
                    // Delete button
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
                    
                    // Save button
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
        .disabled(isLoading)
    }
    
    private func saveEvent() {
        // First validate the form
        validation.validate(event: formData)
        
        guard !validation.hasErrors else {
            return
        }
        
        // Ensure we have a document ID
        guard let documentId = event.documentId else {
            errorMessage = "Cannot update event: missing document ID"
            showingErrorAlert = true
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Call the AuthViewModel updateEvent method
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
                
                // Show success alert on the main thread
                await MainActor.run {
                    isLoading = false
                    showingSuccessAlert = true
                }
            } catch {
                // Show error alert on the main thread
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func deleteEvent() {
        // Ensure we have a document ID
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
}

// Skill toggle button component
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

struct AdminEditEventView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminEditEventView(event: Event(
                name: "Beach Cleanup",
                description: "Community beach cleanup event",
                location: "Santa Monica Beach",
                requiredSkills: ["Physical Labor", "Environmental"],
                urgency: .medium,
                date: Date().addingTimeInterval(86400 * 7),
                status: .upcoming,
                volunteerRequirements: 1
            ))
        }
    }
}
