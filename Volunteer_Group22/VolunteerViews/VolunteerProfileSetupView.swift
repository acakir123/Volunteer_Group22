import SwiftUI
import FirebaseFirestore

struct DayTimeRange {
    var start: Date
    var end: Date
    var isActive: Bool = false
}

extension Date {
    static func createTime(hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }
}


struct DayAvailabilityRow: View {
    let day: String
    let minTime: Date
    let maxTime: Date
    
    @Binding var timeRange: DayTimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(day, isOn: $timeRange.isActive)
            
            if timeRange.isActive {
                HStack {
                    DatePicker(
                        "From",
                        selection: Binding(
                            get: { timeRange.start },
                            set: { timeRange.start = $0 }
                        ),
                        in: minTime...maxTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    
                    Text("to")
                        .foregroundColor(.secondary)
                    
                    DatePicker(
                        "To",
                        selection: Binding(
                            get: { timeRange.end },
                            set: { timeRange.end = $0 }
                        ),
                        in: timeRange.start...maxTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }
        }
    }
}

struct VolunteerProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Basic fields
    @State private var fullName: String = ""
    @State private var address1: String = ""
    @State private var address2: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var selectedSkills: Set<String> = []
    @State private var preferences: String = ""
    
    // For messages
    @State private var showMessage = false
    @State private var messageText = ""
    @State private var isError = false
    
    // Skills & States
    private let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE",
                          "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS",
                          "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS",
                          "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
                          "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
                          "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV",
                          "WI", "WY"]
    
    private let skills = [
        "Teaching", "Cooking", "First Aid", "Event Planning", "Fundraising",
        "Public Speaking", "Graphic Design", "Social Media Management"
    ]
    
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
                Section("Full Name") {
                    TextField("Enter full name", text: $fullName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                // Address
                Section("Address") {
                    TextField("Address Line 1", text: $address1)
                    TextField("Address Line 2 (Optional)", text: $address2)
                }
                
                // City, State, Zip
                Section("City, State, Zip Code") {
                    TextField("City", text: $city)
                    Picker("State", selection: $state) {
                        Text("Select State").tag("")
                        ForEach(states, id: \.self) { st in
                            Text(st).tag(st)
                        }
                    }
                    .pickerStyle(.menu)
                    TextField("Zip Code", text: $zipCode)
                        .keyboardType(.numberPad)
                }
                
                // Skills
                Section("Skills") {
                    List(skills, id: \.self) { skill in
                        Button {
                            if selectedSkills.contains(skill) {
                                selectedSkills.remove(skill)
                            } else {
                                selectedSkills.insert(skill)
                            }
                        } label: {
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
                Section("Preferences") {
                    TextEditor(text: $preferences)
                        .frame(height: 80)
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
                
                // Save
                Section {
                    Button("Save Profile") {
                        saveProfile()
                    }
                }
                
                if showMessage {
                    Text(messageText)
                        .foregroundColor(isError ? .red : .green)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("Profile Setup")
        }
    }
    
    // Save to Firestore
    private func saveProfile() {
        // Basic validations
        guard !fullName.isEmpty else {
            showError("Full Name is required.")
            return
        }
        guard !address1.isEmpty else {
            showError("Address Line 1 is required.")
            return
        }
        guard !city.isEmpty else {
            showError("City is required.")
            return
        }
        guard !state.isEmpty else {
            showError("State is required.")
            return
        }
        guard zipCode.count >= 5 else {
            showError("Zip Code must be at least 5 characters.")
            return
        }
        guard !selectedSkills.isEmpty else {
            showError("At least one skill is required.")
            return
        }
        
        // Check that at least one day is active
        guard weeklyAvailability.values.contains(where: { $0.isActive }) else {
            showError("Please select at least one day you’re available.")
            return
        }
        
        // Build Firestore availability dictionary
        var availabilityDict = [String: [String: Timestamp]]()
        for (day, range) in weeklyAvailability {
            if range.isActive {
                availabilityDict[day] = [
                    "startTime": Timestamp(date: range.start),
                    "endTime":   Timestamp(date: range.end)
                ]
            }
        }
        
        // Build final doc data
        let profileData: [String: Any] = [
            "fullName": fullName,
            "address1": address1,
            "address2": address2,
            "city": city,
            "state": state,
            "zipCode": zipCode,
            "skills": Array(selectedSkills),
            "preferences": preferences,
            "availability": availabilityDict
        ]
        
        guard let uid = authViewModel.userSession?.uid else {
            showError("User not found.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(profileData) { error in
            if let error = error {
                showError("Error saving profile: \(error.localizedDescription)")
            } else {
                messageText = "Profile saved successfully!"
                isError = false
                showMessage = true
                
                Task {
                    await authViewModel.fetchUser()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func showError(_ text: String) {
        messageText = text
        isError = true
        showMessage = true
    }
}


