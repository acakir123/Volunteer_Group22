import SwiftUI
import FirebaseFirestore

struct VolunteerProfileEditView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var user: User?
    @State private var fullName: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var selectedSkills: Set<String> = []
    @State private var preferences: String = ""
    
    // State for validation errors or success messages
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    private let db = Firestore.firestore()
    
    // List of states (2-character codes)
    private let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    
    // List of skills (multi-select)
    private let skills = ["Teaching", "Cooking", "First Aid", "Event Planning", "Fundraising", "Public Speaking", "Graphic Design", "Social Media Management"]
    
    // Days of the week
    private let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    // Time constraints (7 AM - 10 PM)
    private let minTime = Date.createTime(hour: 7)
    private let maxTime = Date.createTime(hour: 22)
    
    // Each day has a DayTimeRange
    @State private var weeklyAvailability: [String: DayTimeRange] = {
        var dict = [String: DayTimeRange]()
        // 7 AM to 10 PM
        let defaultStart = Date.createTime(hour: 7)
        let defaultEnd   = Date.createTime(hour: 22)
        
        for day in ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"] {
            dict[day] = DayTimeRange(start: defaultStart, end: defaultEnd, isActive: false)
        }
        return dict
    }()
    
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
                
                // Availability
                Section("Availability") {
                    Text("Which days are you available? (7AM - 10PM)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(daysOfWeek, id: \.self) { day in
                        if let _ = weeklyAvailability[day] {
                            DayAvailabilityRow(
                                day: day,
                                minTime: minTime,
                                maxTime: maxTime,
                                timeRange: Binding(
                                    get: { weeklyAvailability[day]! },
                                    set: { weeklyAvailability[day]! = $0 }
                                )
                            )
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
                
                // Messages
                if showSuccess {
                    Text("Profile updated successfully!")
                        .foregroundColor(.green)
                        .font(.body)
                        .padding()
                }
                
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
        
        .listStyle(InsetGroupedListStyle())
    }
    
    // Save updated profile to Firestore
    private func saveProfile() {
        showError = false
        showSuccess = false
        
        if fullName.isEmpty || address1.isEmpty || city.isEmpty || state.isEmpty || zipCode.count < 5 || selectedSkills.isEmpty {
            errorMessage = "Please fill in all required fields."
            showError = true
            return
        }
        
        guard weeklyAvailability.values.contains(where: { $0.isActive }) else {
            errorMessage = "Please select at least one day you're available."
            showError = true
            return
        }
        
        guard let uid = authViewModel.userSession?.uid else {
            errorMessage = "User not found."
            showError = true
            return
        }
        
        var availabilityDict = [String: [String: Timestamp]]()
        for (day, range) in weeklyAvailability {
            if range.isActive {
                availabilityDict[day] = [
                    "startTime": Timestamp(date: range.start),
                    "endTime":   Timestamp(date: range.end)
                ]
            }
        }
        
        let updatedProfile: [String: Any] = [
            "fullName": fullName,
            "location": [
                "address": address1,
                "address2": address2,
                "city": city,
                "country": "",
                "state": state,
                "zipCode": zipCode
            ],
            "skills": Array(selectedSkills),
            "preferences": [preferences],
            "availability": availabilityDict
        ]
        
        db.collection("users").document(uid).setData(updatedProfile, merge: true) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error saving profile: \(error.localizedDescription)"
                    self.showError = true
                }
            } else {
                DispatchQueue.main.async {
                    self.showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccess = false
                    }
                    if var currentUser = self.authViewModel.user {
                        currentUser.fullName = self.fullName
                        self.authViewModel.user = currentUser
                    }
                }
            }
        }
    }


    
    // Load existing profile from Firestore
    private func loadExistingProfile() async {
        guard let uid = authViewModel.userSession?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                DispatchQueue.main.async {
                    self.fullName = data["fullName"] as? String ?? ""
                    if let location = data["location"] as? [String: Any] {
                        self.address1 = location["address"] as? String ?? ""
                        self.address2 = location["address2"] as? String ?? ""
                        self.city = location["city"] as? String ?? ""
                        self.state = location["state"] as? String ?? ""
                        self.zipCode = location["zipCode"] as? String ?? ""
                    }
                    self.selectedSkills = Set(data["skills"] as? [String] ?? [])
                    self.preferences = data["preferences"] as? String ?? ""
                    
                    // Load availability
                    if let availabilityData = data["availability"] as? [String: [String: Timestamp]] {
                        for (day, timeData) in availabilityData {
                            if let startTime = timeData["startTime"]?.dateValue(),
                               let endTime = timeData["endTime"]?.dateValue() {
                                self.weeklyAvailability[day] = DayTimeRange(
                                    start: startTime,
                                    end: endTime,
                                    isActive: true
                                )
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error loading profile: \(error.localizedDescription)")
        }
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.body)
        }
    }
}

struct VolunteerProfileEditView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerProfileEditView()
    }
}
