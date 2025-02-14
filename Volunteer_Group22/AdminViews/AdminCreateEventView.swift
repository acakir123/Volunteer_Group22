import SwiftUI

struct AdminCreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: EventFormData
    @State private var validation = EventFormValidation()
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
    
    init() {
        // Create an empty event with default values
        let emptyEvent = Event(
            name: "",
            description: "",
            location: "",
            requiredSkills: [],
            urgency: .medium,
            date: Date().addingTimeInterval(86400), // Tomorrow
            status: .upcoming
        )
        // Initialize the form data with the empty event
        _formData = State(initialValue: EventFormData(from: emptyEvent))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create New Event")
                        .font(.system(size: 24, weight: .bold))
                    Text("Fill in the event details below")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
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
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Select all that apply")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
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
                            }
                        )
                    )
                    
                    // Urgency
                    FormField(
                        title: "Urgency Level",
                        error: nil,
                        content: AnyView(
                            VStack(alignment: .leading, spacing: 8) {
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
                            }
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
                                in: Date()...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                        )
                    )
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16)
                
                // Action buttons
                HStack(spacing: 16) {
                    // Cancel button
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Create button
                    Button(action: createEvent) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Create Event")
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
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Event has been created successfully.")
        }
        .navigationTitle("Create Event")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func createEvent() {
        validation.validate(event: formData)
        
        guard !validation.hasErrors else {
            return
        }
        
        // Here we will save to the backend
        
        showingSuccessAlert = true
    }
}

#Preview {
    AdminCreateEventView()
}
