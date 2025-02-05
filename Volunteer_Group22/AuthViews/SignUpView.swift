import SwiftUI

struct SignUpView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @EnvironmentObject var authViewModel : AuthViewModel
    
    
    var body: some View {
        NavigationStack {
            Text("Sign Up View")
            
            // Sign Up Button
            Button {
                Task {
                    try await authViewModel.signIn(withEmail: email, password: password)
                }
            } label: {
                Text("Sign In Button")
            }
            
            
            // Navigate to sign in view if user already has an account
            NavigationLink {
                SignInView()
                // Back bar hidden, user should only be able to navigate between signin/up thru these buttons
                    .navigationBarBackButtonHidden(true)
            } label: {
                VStack {
                    Text("Already have an account?")
                    Text("Sign in here")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
            
            
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
