import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var isEmailVerified: Bool = false
    @Published var user: User?
    @Published var currentVolunteer: Volunteer? = nil
    
    public let db = Firestore.firestore()
    private var userRole: String = ""
    
    private let isTestMode: Bool
    
    private var usersCollection: CollectionReference {
        if isTestMode { return db.collection("testUsers") }
        return db.collection("users")
    }
    private var eventsCollection: CollectionReference {
        if isTestMode { return db.collection("testEvents") }
        return db.collection("events")
    }
    private var volunteerHistoryCollection: CollectionReference {
        if isTestMode { return db.collection("testVolunteerHistory") }
        return db.collection("volunteerHistory")
    }
    
    init(isTestMode: Bool = false) {
        self.isTestMode = isTestMode
        
        self.userSession = Auth.auth().currentUser
        if let user = self.userSession {
            Task {
                do {
                    try await user.reload()
                    self.isEmailVerified = user.isEmailVerified
                    await fetchUser()
                } catch {
                    print("Error reloading user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await result.user.reload()
            self.userSession = result.user
            self.isEmailVerified = result.user.isEmailVerified
            await fetchUser()
        } catch {
            print("failed to sign in: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signUp(withEmail email: String, password: String, role: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let userId = result.user.uid
            self.userRole = role
            try await createUserDocument(userId: userId, email: email, role: role)
        } catch {
            print("Failed to create user: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func createUserDocument(userId: String, email: String, role: String) async throws {
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "role": role
        ]
        try await usersCollection.document(userId).setData(userData)
    }
    
    var isProfileComplete: Bool {
        guard let fullName = user?.fullName, !fullName.isEmpty else { return false }
        return true
    }
    
    func resetPassword(withEmail email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            print("Error sending password reset email: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
        } catch {
            print("failed to sign out: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async throws {
        do {
            guard let currentUser = Auth.auth().currentUser else { return }
            try await currentUser.delete()
            self.userSession = nil
        } catch {
            print("Error deleting account: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        do {
            let snapshot = try await usersCollection.document(uid).getDocument()
            if let data = snapshot.data() {
                let username  = data["username"] as? String ?? ""
                let fullName  = data["fullName"] as? String ?? ""
                let email     = data["email"] as? String ?? ""
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                let role      = data["role"] as? String ?? ""
                let preferences = data["preferences"] as? [String] ?? []
                let skills    = data["skills"] as? [String] ?? []
                
                let locationData = data["location"] as? [String: Any] ?? [:]
                let address  = locationData["address"]  as? String ?? ""
                let address2 = locationData["address2"] as? String ?? ""
                let city     = locationData["city"]     as? String ?? ""
                let country  = locationData["country"]  as? String ?? ""
                let state    = locationData["state"]    as? String ?? ""
                let zipCode  = locationData["zipCode"]  as? String ?? ""
                
                let availabilityData = data["availability"] as? [String: [String: Timestamp]] ?? [:]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "h:mm a"
                
                var availability: [String: User.Availability] = [:]
                for (day, dict) in availabilityData {
                    if let startTS = dict["startTime"],
                       let endTS   = dict["endTime"] {
                        
                        let startDate = startTS.dateValue()
                        let endDate   = endTS.dateValue()
                        
                        let startString = dateFormatter.string(from: startDate)
                        let endString   = dateFormatter.string(from: endDate)
                        
                        availability[day] = User.Availability(
                            startTime: startString,
                            endTime:   endString
                        )
                    }
                }
                
                let userLocation = User.Location(
                    address: address,
                    city: city,
                    country: country,
                    state: state,
                    zipCode: zipCode
                )
                
                self.user = User(
                    uid: uid,
                    username: username,
                    fullName: fullName,
                    email: email,
                    createdAt: createdAt,
                    role: role,
                    preferences: preferences,
                    skills: skills,
                    location: userLocation,
                    availability: availability
                )
            } else {
                print("DEBUG: Document for \(uid) returned no data.")
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }


    
    func signUp(for event: Event) async throws {
        guard let userId = user?.uid else { return }
        guard let documentId = event.documentId else { return }
        
        try await eventsCollection.document(documentId).updateData([
            "assignedVolunteers": FieldValue.arrayUnion([userId])
        ])
    }
    
    public func createEvent(
        name: String,
        description: String,
        date: Date,
        address: String,
        city: String,
        state: String,
        country: String,
        zipCode: String,
        requiredSkills: [String],
        urgency: Event.UrgencyLevel,
        volunteerRequirements: Int
    ) async throws {
        let urgencyString = urgency.rawValue
        
        let locationData: [String: String] = [
            "address": address,
            "city": city,
            "state": state,
            "country": country,
            "zipCode": zipCode
        ]
        
        let eventData: [String: Any] = [
            "name": name,
            "description": description,
            "dateTime": Timestamp(date: date),
            "location": locationData,
            "requiredSkills": requiredSkills,
            "urgency": urgencyString,
            "volunteerRequirements": volunteerRequirements,
            "assignedVolunteers": [],
            "status": Event.EventStatus.upcoming.rawValue,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await eventsCollection.addDocument(data: eventData)
    }
    
    public func updateEvent(
        eventId: String,
        name: String,
        description: String,
        date: Date,
        address: String,
        city: String,
        state: String,
        country: String,
        zipCode: String,
        requiredSkills: [String],
        urgency: Event.UrgencyLevel,
        volunteerRequirements: Int,
        status: Event.EventStatus
    ) async throws {
        let urgencyString = urgency.rawValue
        let statusString = status.rawValue
        
        let locationData: [String: String] = [
            "address": address,
            "city": city,
            "state": state,
            "country": country,
            "zipCode": zipCode
        ]
        
        let eventData: [String: Any] = [
            "name": name,
            "description": description,
            "dateTime": Timestamp(date: date),
            "location": locationData,
            "requiredSkills": requiredSkills,
            "urgency": urgencyString,
            "volunteerRequirements": volunteerRequirements,
            "status": statusString,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await eventsCollection.document(eventId).updateData(eventData)
    }
    
    public func deleteEvent(eventId: String) async throws {
        try await eventsCollection.document(eventId).delete()
    }
    
    public func fetchEvents(db: Firestore) async throws -> [Event] {
        let snapshot = try await eventsCollection.getDocuments()
        return snapshot.documents.map { doc in
            Event(documentId: doc.documentID, data: doc.data())
        }
    }
    
    public func fetchEvent(db: Firestore, documentId: String) async throws -> Event? {
        let doc = try await eventsCollection.document(documentId).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        return Event(documentId: doc.documentID, data: data)
    }
    
    public func fetchFilteredEvents(
        db: Firestore,
        status: Event.EventStatus? = nil,
        searchText: String? = nil
    ) async throws -> [Event] {
        var query: Query = eventsCollection
        
        if let status = status {
            query = query.whereField("status", isEqualTo: status.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        var events = snapshot.documents.map { doc in
            Event(documentId: doc.documentID, data: doc.data())
        }
        
        if let searchText = searchText, !searchText.isEmpty {
            let lower = searchText.lowercased()
            events = events.filter { e in
                e.name.lowercased().contains(lower)
                || e.description.lowercased().contains(lower)
                || e.location.lowercased().contains(lower)
            }
        }
        
        return events
    }
    
    func generateVolunteerHistoryRecords() async throws {
        let now = Date()
        
        // Query all events with dateTime < now
        let snapshot = try await eventsCollection
            .whereField("dateTime", isLessThan: Timestamp(date: now))
            .getDocuments()
        
        for doc in snapshot.documents {
            let eventId = doc.documentID
            let data = doc.data()
            
            let assignedVolunteers = data["assignedVolunteers"] as? [String] ?? []
            
            for volunteerId in assignedVolunteers {
                // fetch user doc for name
                let userDoc = try await usersCollection.document(volunteerId).getDocument()
                let userData = userDoc.data() ?? [:]
                let volunteerName = userData["fullName"] as? String ?? ""
                
                // Check if a volunteerHistory doc exists
                let existing = try await volunteerHistoryCollection
                    .whereField("eventId", isEqualTo: eventId)
                    .whereField("volunteerId", isEqualTo: volunteerId)
                    .getDocuments()
                
                if existing.documents.isEmpty {
                    let historyData: [String: Any] = [
                        "eventId": eventId,
                        "volunteerId": volunteerId,
                        "dateCompleted": Timestamp(date: now),
                        "performance": [:],
                        "feedback": "",
                        "createdAt": Timestamp(date: now),
                        "fullName": volunteerName
                    ]
                    _ = try await volunteerHistoryCollection.addDocument(data: historyData)
                }
            }
            
            // Mark event as completed if not already
            if let currentStatus = data["status"] as? String,
               currentStatus != Event.EventStatus.completed.rawValue {
                try await eventsCollection.document(eventId)
                    .updateData(["status": Event.EventStatus.completed.rawValue])
            }
        }
    }
}
