import SwiftUI
import FirebaseAuth


@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    init() {
        
    }
    
    // Sign In Existing User
    func signIn(withEmail email: String, password: String) async throws {
        print("Sign In")
    }
    
    // Create New User -- More Properties Can Be Added
    func createUser(withEmail email: String, password: String) async throws {
        print("Sign Up")
    }
    func resetPassword(withEmail email: String) async throws {
        print("Reset Password")
    }
    // Sign Out Current User
    func signOut() {
        print("Sign Out")
    }
    
    // Delete Current Users Account
    func deleteAccount() {
        print("Delete Account")
    }
    
    // Fetch Current User
    func fetchUser() async {
        
    }
    
}
