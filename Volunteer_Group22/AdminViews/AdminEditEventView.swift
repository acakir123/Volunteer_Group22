import SwiftUI

// Form field validation
struct EventFormValidation {
    var nameError: String?
    var descriptionError: String?
    var locationError: String?
    var skillsError: String?
    var dateError: String?
    
    var hasErrors: Bool {
        return nameError != nil ||
            descriptionError != nil ||
            locationError != nil ||
            skillsError != nil ||
            dateError != nil
    }
    
    mutating func validate(event: EventFormData) {
        // Name validation
        if event.name.isEmpty {
            nameError = "Event name is required"
        } else if event.name.count > 100 {
            nameError = "Event name must be less than 100 characters"
        } else {
            nameError = nil
        }
        
        // Description validation
        if event.description.isEmpty {
            descriptionError = "Event description is required"
        } else {
            descriptionError = nil
        }
        
        // Location validation
        if event.location.isEmpty {
            locationError = "Location is required"
        } else {
            locationError = nil
        }
        
        // Skills validation
        if event.requiredSkills.isEmpty {
            skillsError = "At least one skill is required"
        } else {
            skillsError = nil
        }
        
        // Date validation
        if event.date < Date() {
            dateError = "Event date must be in the future"
        } else {
            dateError = nil
        }
    }
}

// Form data model
struct EventFormData {
    var name: String
    var description: String
    var location: String
    var requiredSkills: Set<String>
    var urgency: Event.UrgencyLevel
    var date: Date
    var status: Event.EventStatus
    
    // Initialize from Event model
    init(from event: Event) {
        self.name = event.name
        self.description = event.description
        self.location = event.location
        self.requiredSkills = Set(event.requiredSkills)
        self.urgency = event.urgency
        self.date = event.date
        self.status = event.status
    }
}

// Custom form field components
struct FormField: View {
    let title: String
    let error: String?
    let content: AnyView
    
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

struct AdminEditEventView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var formData: EventFormData
    @State private var validation = EventFormValidation()
    @State private var showingDeleteConfirmation = false
    @State private var showingSuccessAlert = false
    
    // Available skills (will come from backend)
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
                        error: validation.nameError,
                        content: AnyView(
                            TextField("Enter event name", text: $formData.name)
                                .textFieldStyle(.roundedBorder)
                        )
                    )
                    
                    // Description
                    FormField(
                        title: "Description",
                        error: validation.descriptionError,
                        content: AnyView(
                            TextEditor(text: $formData.description)
                                .frame(height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.2))
                                )
                        )
                    )
                    
                    // Location
                    FormField(
                        title: "Location",
                        error: validation.locationError,
                        content: AnyView(
                            TextField("Enter location", text: $formData.location)
                                .textFieldStyle(.roundedBorder)
                        )
                    )
                    
                    // Required Skills
                    FormField(
                        title: "Required Skills",
                        error: validation.skillsError,
                        content: AnyView(
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(availableSkills, id: \.self) { skill in
                                        SkillToggleButton(
                                            skill: skill,
                                            isSelected: formData.requiredSkills.contains(skill),
                                            action: {
                                                if formData.requiredSkills.contains(skill) {
                                                    formData.requiredSkills.remove(skill)
                                                } else {
                                                    formData.requiredSkills.insert(skill)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        )
                    )
                    
                    // Urgency
                    FormField(
                        title: "Urgency Level",
                        error: nil,
                        content: AnyView(
                            Picker("Urgency", selection: $formData.urgency) {
                                ForEach(Event.UrgencyLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.segmented)
                        )
                    )
                    
                    // Event Date
                    FormField(
                        title: "Event Date",
                        error: validation.dateError,
                        content: AnyView(
                            DatePicker(
                                "Select date",
                                selection: $formData.date,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                        )
                    )
                    
                    // Status
                    FormField(
                        title: "Event Status",
                        error: nil,
                        content: AnyView(
                            Picker("Status", selection: $formData.status) {
                                ForEach(Event.EventStatus.allCases, id: \.self) { status in
                                    Text(status.rawValue).tag(status)
                                }
                            }
                            .pickerStyle(.menu)
                        )
                    )
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
                    
                    // Save button
                    Button(action: saveEvent) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Save Changes")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
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
    }
    
    private func saveEvent() {
        validation.validate(event: formData)
        
        guard !validation.hasErrors else {
            return
        }
        
        // Here we will save to the backend
        showingSuccessAlert = true
    }
    
    private func deleteEvent() {
        // Here we will delete from the backend
        dismiss()
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
