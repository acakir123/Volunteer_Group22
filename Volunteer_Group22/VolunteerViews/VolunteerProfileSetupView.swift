import SwiftUI
import FirebaseFirestore

struct VolunteerProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // State variables for form fields
    @State private var fullName: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var selectedSkills: Set<String> = []
    @State private var preferences: String = ""
    @State private var availability: [Date] = []
    
    // State for validation errors or success messages
    @State private var showMessage = false
    @State private var messageText = ""
    @State private var isError = false
    
    // List of states (2-character codes)
    private let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE",
                          "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS",
                          "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS",
                          "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
                          "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                          "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV",
                          "WI", "WY"]
    
    // List of skills (multi-select)
    private let skills = [
        "Teaching", "Cooking", "First Aid", "Event Planning", "Fundraising",
        "Public Speaking", "Graphic Design", "Social Media Management"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Full Name
                Section(header: Text("Full Name")) {
                    TextField("Enter full name", text: $fullName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                // Address
                Section(header: Text("Address")) {
                    TextField("Address Line 1", text: $address1)
                    TextField("Address Line 2 (Optional)", text: $address2)
                }
                
                // City, State, Zip Code
                Section(header: Text("City, State, Zip Code")) {
                    TextField("City", text: $city)
                    Picker("State", selection: $state) {
                        Text("Select State").tag("")
                        ForEach(states, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("Zip Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                // Skills (Multi-select)
                Section(header: Text("Skills")) {
                    List(skills, id: \.self) { skill in
                        Button(action: {
                            if selectedSkills.contains(skill) {
                                selectedSkills.remove(skill)
                            } else {
                                selectedSkills.insert(skill)
                            }
                        }) {
                            HStack {
                                Text(skill)
                                Spacer()
                                if selectedSkills.contains(skill) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                // Preferences
                Section(header: Text("Preferences")) {
                    TextEditor(text: $preferences)
                        .frame(height: 100)
                }
                
                // Availability (Example: add today’s date)
                Section(header: Text("Availability")) {
                    Button("Add Today") {
                        availability.append(Date())
                    }
                    ForEach(availability, id: \.self) { date in
                        Text("\(date, formatter: dateFormatter)")
                    }
                }
                
                // Save Button
                Section {
                    Button(action: saveProfile) {
                        Text("Save Profile")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                // Message display
                if showMessage {
                    Text(messageText)
                        .foregroundColor(isError ? .red : .green)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Volunteer Profile Setup")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Date formatter for displaying dates in the availability section
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    // Save profile function that pushes data to Firestore
    private func saveProfile() {
        // Validate required fields
        if fullName.isEmpty {
            showValidationError("Full Name is required.")
            return
        }
        if address1.isEmpty {
            showValidationError("Address Line 1 is required.")
            return
        }
        if city.isEmpty {
            showValidationError("City is required.")
            return
        }
        if state.isEmpty {
            showValidationError("State is required.")
            return
        }
        if zipCode.count < 5 {
            showValidationError("Zip Code must be at least 5 characters.")
            return
        }
        if selectedSkills.isEmpty {
            showValidationError("At least one skill is required.")
            return
        }
        
        // Construct profile data to update
        let profileData: [String: Any] = [
            "fullName": fullName,
            "address1": address1,
            "address2": address2,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "skills": Array(selectedSkills),
            "preferences": preferences,
            // Save availability as an array of Timestamps
            "availability": availability.map { Timestamp(date: $0) }
        ]
        
        // Get the current user’s UID from the AuthViewModel
        guard let uid = authViewModel.userSession?.uid else {
            showValidationError("User not found.")
            return
        }
        
        // Push the updated data to Firestore
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(profileData) { error in
            if let error = error {
                self.messageText = "Error saving profile: \(error.localizedDescription)"
                self.isError = true
            } else {
                self.messageText = "Profile saved successfully!"
                self.isError = false
                
                Task {
                    await authViewModel.fetchUser()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            self.showMessage = true
        }
    }
    
    private func showValidationError(_ text: String) {
        messageText = text
        isError = true
        showMessage = true
    }
}
