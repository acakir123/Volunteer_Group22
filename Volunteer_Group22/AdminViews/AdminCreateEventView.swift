import SwiftUI

struct AdminCreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
            status: .upcoming,
            volunteerRequirements: 1
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
                        .frame(maxWidth: .infinity)
                        .background(Color(uiColor: .systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Event Date
                    FormField(
                        title: "Event Date",
                        error: validation.dateError
                    ) {
                        DatePicker(
                            "Select date and time",
                            selection: $formData.date,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
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
        
        // Call the AuthViewModel createEvent method with separate location fields
        Task {
            do {
                try await authViewModel.createEvent(
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
                    volunteerRequirements: formData.volunteerRequirements
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
}
