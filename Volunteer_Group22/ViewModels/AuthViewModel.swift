import SwiftUI
import FirebaseAuth
import FirebaseFirestore


@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var isEmailVerified: Bool = false
    @Published var user: User?
    
    private let db = Firestore.firestore()
    private var userRole: String = ""
    
    init() {
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
    
    // Check if profile is complete
    var isProfileComplete: Bool {
        guard let fullName = user?.fullName, !fullName.isEmpty else { return false }
        return true
    }
    
    // Sign In Existing User
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
    
    // Create New User and Add to Firestore
    func signUp(withEmail email: String, password: String, role: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            let userId = result.user.uid
            self.userRole = role
            
            // Create initial user document in Firestore
            try await createUserDocument(userId: userId, email: email, role: role)
        } catch {
            print("Failed to create user: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Function to Create Firestore User Document
    private func createUserDocument(userId: String, email: String, role: String) async throws {
        let userData: [String: Any] = [
            "email": email,
            "createdAt": Timestamp(date: Date()),
            "role": role
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    
    // Send password reset email
    func resetPassword(withEmail email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            print("Error sending password reset email: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Sign Out Current User
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
        } catch {
            print("failed to sign out: \(error.localizedDescription)")
        }
    }
    
    // Delete Current Users Account
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
    
    
    // Fetch user profile data from Firestore
    func fetchUser() async {
        guard let uid = userSession?.uid else { return }
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                let username = data["username"] as? String ?? ""
                let fullName = data["fullName"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                let role = data["role"] as? String ?? ""
                let preferences = data["preferences"] as? [String] ?? []
                let skills = data["skills"] as? [String] ?? []
                
                let locationData = data["location"] as? [String: Any] ?? [:]
                let address = locationData["address"] as? String ?? ""
                let city = locationData["city"] as? String ?? ""
                let country = locationData["country"] as? String ?? ""
                let state = locationData["state"] as? String ?? ""
                let zipCode = locationData["zipCode"] as? String ?? ""
                let location = User.Location(address: address, city: city, country: country, state: state, zipCode: zipCode)
                
                let availabilityData = data["availability"] as? [String: [String: String]] ?? [:]
                var availability: [String: User.Availability] = [:]
                
                for (day, dict) in availabilityData {
                    let startTime = dict["startTime"] ?? ""
                    let endTime   = dict["endTime"] ?? ""
                    availability[day] = User.Availability(
                        startTime: startTime,
                        endTime:   endTime
                    )
                }
                
                self.user = User(
                    uid: uid,
                    username: username,
                    fullName: fullName,
                    email: email,
                    createdAt: createdAt,
                    role: role,
                    preferences: preferences,
                    skills: skills,
                    location: location,
                    availability: availability
                )
            } else {
                print("DEBUG: Document for \(uid) returned no data.")
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
        }
    }
}
