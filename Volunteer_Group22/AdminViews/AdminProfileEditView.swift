import SwiftUI
import FirebaseFirestore

struct AdminProfileEditView: View {
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
    @State private var availabilityDate: Date = Date()  
    
    // State for validation errors or success messages
    @State private var showMessage = false
    @State private var messageText = ""
    @State private var isError = false

    private let db = Firestore.firestore()

    // List of states
    private let states = [
        "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN",
        "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV",
        "NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN",
        "TX","UT","VT","VA","WA","WV","WI","WY"
    ]
    
    // List of skills
    private let skills = [
        "Teaching","Cooking","First Aid","Event Planning","Fundraising","Public Speaking",
        "Graphic Design","Social Media Management"
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
                
                // Availability (Same UI as AdminProfileSetupView)
                Section(header: Text("Availability")) {
                    DatePicker("Select Date", selection: $availabilityDate, displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())

                    Button("Add Date") {
                        if !availability.contains(availabilityDate) {
                            availability.append(availabilityDate)
                        }
                    }
                    
                    if availability.isEmpty {
                        Text("No availability added yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availability, id: \.self) { date in
                            HStack {
                                Text("\(date, formatter: dateFormatter)")
                                Spacer()
                                Button(action: {
                                    availability.removeAll { $0 == date }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
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
                        Task {
                            authViewModel.signOut()
                        }
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
                
                // Message display
                if showMessage {
                    Text(messageText)
                        .foregroundColor(isError ? .red : .green)
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
            showValidationError("Please fill in all required fields.")
            return
        }
        
        guard let uid = authViewModel.userSession?.uid else {
            showValidationError("User not found.")
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
                messageText = "Error saving profile: \(error.localizedDescription)"
                isError = true
            } else {
                messageText = "Profile updated successfully!"
                isError = false
                
                Task {
                    await authViewModel.fetchUser()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            showMessage = true
        }
    }
    
    private func showValidationError(_ text: String) {
        messageText = text
        isError = true
        showMessage = true
    }
}


/*
#Preview {
    AdminProfileEditView()
        .environmentObject(AuthViewModel())
}*/

