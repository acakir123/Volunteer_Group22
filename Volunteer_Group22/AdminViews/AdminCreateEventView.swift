import SwiftUI

struct AdminCreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formData: EventFormData
    @State private var validation = EventFormValidation()
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
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
                    
                    // Location
                    FormField(
                        title: "Location",
                        error: validation.locationError
                    ) {
                        TextField("Enter location", text: $formData.location)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                    }
                    
                    // Required Skills
                    FormField(
                        title: "Required Skills",
                        error: validation.skillsError
                    ) {
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
                    
                    // Event Date
                    FormField(
                        title: "Event Date",
                        error: validation.dateError
                    ) {
                        DatePicker(
                            "Select date",
                            selection: $formData.date,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .disabled(isLoading)
                    }
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(16)
                
                // Action buttons
                HStack(spacing: 16) {
                    // Cancel button
                    Button(action: {
                        if !isLoading {
                            dismiss()
                        }
                    }) {
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
                    .disabled(isLoading)
                    
                    // Create button
                    Button(action: createEvent) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus")
                                Text("Create Event")
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
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Event has been created successfully.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .navigationTitle("Create Event")
        .navigationBarTitleDisplayMode(.inline)
        .disabled(isLoading)
    }
    
    private func createEvent() {
        // First validate the form
        validation.validate(event: formData)
        
        guard !validation.hasErrors else {
            return
        }
        
        // Set loading state
        isLoading = true
        
        // Simulate API call with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                // Here would be the actual call to Firebase
                // For now, just simulate success/failure
                let shouldSucceed = true // Simulate API response
                
                if shouldSucceed {
                    showingSuccessAlert = true
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
                }
            } catch {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
            }
            
            // Reset loading state
            isLoading = false
        }
    }
}

struct AdminCreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AdminCreateEventView()
        }
    }
}

#Preview {
    AdminCreateEventView()
}
