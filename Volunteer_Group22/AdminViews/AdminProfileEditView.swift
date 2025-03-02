import SwiftUI
import FirebaseFirestore

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
    @State private var availability: [Date] = []
    
    // State for validation errors or success messages
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Environment object for authentication
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Firestore reference
    private let db = Firestore.firestore()
    
    // List of states (2-character codes)
    private let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    
    // List of skills (multi-select)
    private let skills = ["Teaching", "Cooking", "First Aid", "Event Planning", "Fundraising", "Public Speaking", "Graphic Design", "Social Media Management"]
    
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
                
                // Availability (Date Picker)
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
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
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
                            .frame(maxWidth: .infinity)
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
                Task {
                    await loadExistingProfile()
                }
            }
        }
    }
    
    // Date formatter for displaying dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    // Load existing profile from Firestore
    private func loadExistingProfile() async {
        guard let uid = authViewModel.userSession?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                DispatchQueue.main.async {
                    self.fullName = data["fullName"] as? String ?? ""
                    self.address1 = data["address1"] as? String ?? ""
                    self.address2 = data["address2"] as? String ?? ""
                    self.city = data["city"] as? String ?? ""
                    self.state = data["state"] as? String ?? ""
                    self.zipCode = data["zipCode"] as? String ?? ""
                    self.selectedSkills = Set(data["skills"] as? [String] ?? [])
                    self.preferences = data["preferences"] as? String ?? ""
                    
                    if let availabilityData = data["availability"] as? [Timestamp] {
                        self.availability = availabilityData.map { $0.dateValue() }
                    }
                }
            }
        } catch {
            print("Error loading profile: \(error.localizedDescription)")
        }
    }
    
    // Save updated profile to Firestore
    private func saveProfile() {
        // Validate fields
        if fullName.isEmpty || address1.isEmpty || city.isEmpty || state.isEmpty || zipCode.count < 5 || selectedSkills.isEmpty {
            errorMessage = "Please fill in all required fields."
            showError = true
            return
        }
        
        guard let uid = authViewModel.userSession?.uid else {
            errorMessage = "User not found."
            showError = true
            return
        }
        
        let updatedProfile: [String: Any] = [
            "fullName": fullName,
            "address1": address1,
            "address2": address2,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "skills": Array(selectedSkills),
            "preferences": preferences,
            "availability": availability.map { Timestamp(date: $0) }
        ]
        
        db.collection("users").document(uid).updateData(updatedProfile) { error in
            if let error = error {
                errorMessage = "Error saving profile: \(error.localizedDescription)"
                showError = true
            } else {
                errorMessage = "Profile updated successfully!"
                showError = false
                Task {
                    await authViewModel.fetchUser()
                }
            }
        }
    }
}


