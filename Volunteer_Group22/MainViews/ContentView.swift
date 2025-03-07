import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            NavigationStack {
                // if no user signed in, show signinview
                if authViewModel.userSession == nil {
                    SignInView()
                } else {
                    // if user signed in, check email verification
                    if !authViewModel.isEmailVerified {
                        emailVerificationView()
                    } else if !authViewModel.isProfileComplete {
                        // route to appropriate profile setup view
                        if authViewModel.user?.role == "Administrator" {
                            AdminProfileSetupView()
                        } else {
                            VolunteerProfileSetupView()
                        }
                    } else {
                        // route to appropriate main view
                        if authViewModel.user?.role == "Administrator" {
                            AdminMainTabView()
                        } else {
                            VolunteerMainTabView()
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                if authViewModel.userSession != nil {
                    await authViewModel.fetchUser()
                }
            }
        }
    }
}

struct emailVerificationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Sign up successful! Please check your email and verify your account before logging in.")
                .padding()
            
            Button(action: {
                // sign user out so contentview routing works
                authViewModel.signOut()
            }) {
                Text("Back to Sign In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Email Verification")
        .navigationBarTitleDisplayMode(.inline)
    }
}



