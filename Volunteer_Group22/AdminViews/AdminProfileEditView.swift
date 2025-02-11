import SwiftUI

struct AdminProfileEditView: View {
    // State variables for form fields
    @State private var fullName: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var selectedSkills: Set<String> = []
    @State private var preferences: String = ""
    @State private var availability: Set<Date> = []
    
    // State for validation errors
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Environment object for authentication
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // List of states (2-character codes)
    private let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    
    // List of skills (multi-select)
    private let skills = ["Teaching", "Cooking", "First Aid", "Event Planning", "Fundraising", "Public Speaking", "Graphic Design", "Social Media Management"]
    
    // Mock existing profile data (replace with actual data from backend later)
    private let existingProfile: [String: Any] = [
        "fullName": "John Doe",
        "address1": "123 Main St",
        "address2": "Apt 4B",
        "city": "New York",
        "state": "NY",
        "zipCode": "10001",
        "skills": ["Teaching", "Event Planning"],
        "preferences": "Prefers outdoor events.",
        "availability": [Date(), Calendar.current.date(byAdding: .day, value: 7, to: Date())!]
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
                        Text("Select State").tag("") // Default empty option
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
                
                // Availability (Date Picker)
                Section(header: Text("Availability")) {
                    DatePicker("Select Available Dates", selection: .constant(Date()), displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                
                // Save Button
                Section {
                    Button(action: saveProfile) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                
                // Sign Out Button
                Section {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                
                // Error Message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Pre-fill form fields with existing profile data
                loadExistingProfile()
            }
        }
    }
    
    // Load existing profile data into form fields
    private func loadExistingProfile() {
        fullName = existingProfile["fullName"] as? String ?? ""
        address1 = existingProfile["address1"] as? String ?? ""
        address2 = existingProfile["address2"] as? String ?? ""
        city = existingProfile["city"] as? String ?? ""
        state = existingProfile["state"] as? String ?? ""
        zipCode = existingProfile["zipCode"] as? String ?? ""
        selectedSkills = Set(existingProfile["skills"] as? [String] ?? [])
        preferences = existingProfile["preferences"] as? String ?? ""
        availability = Set(existingProfile["availability"] as? [Date] ?? [])
    }
    
    // Save profile function (mock for front-end)
    private func saveProfile() {
        // Validate required fields
        if fullName.isEmpty {
            errorMessage = "Full Name is required."
            showError = true
        } else if address1.isEmpty {
            errorMessage = "Address Line 1 is required."
            showError = true
        } else if city.isEmpty {
            errorMessage = "City is required."
            showError = true
        } else if state.isEmpty {
            errorMessage = "State is required."
            showError = true
        } else if zipCode.count < 5 {
            errorMessage = "Zip Code must be at least 5 characters."
            showError = true
        } else if selectedSkills.isEmpty {
            errorMessage = "At least one skill is required."
            showError = true
        } else {
            // Mock save action
            let updatedProfileData: [String: Any] = [
                "fullName": fullName,
                "address1": address1,
                "address2": address2,
                "city": city,
                "state": state,
                "zipCode": zipCode,
                "skills": Array(selectedSkills),
                "preferences": preferences,
                "availability": Array(availability)
            ]
            
            print("Updated Profile Data Saved: \(updatedProfileData)")
            errorMessage = "Profile updated successfully!"
            showError = true
        }
    }
}

struct AdminProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        AdminProfileEditView()
            .environmentObject(AuthViewModel()) // Provide a mock AuthViewModel for preview
    }
}
