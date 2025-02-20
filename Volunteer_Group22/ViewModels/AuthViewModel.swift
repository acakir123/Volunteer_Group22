import SwiftUI
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    
    init() {
        self.userSession = Auth.auth().currentUser
    }
    
    // Sign In Existing User
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
        } catch {
            print("failed to sign in: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Create New User
    func signUp(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
        } catch {
            print("failed to create user: \(error.localizedDescription)")
            throw error
        }
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

    
    // Fetch current user from Firestore, this is where we get actual user info like name, location, etc. Feeds into User struct and is available anywhere in the app
    func fetchUser() async {
        
    }
    
}
