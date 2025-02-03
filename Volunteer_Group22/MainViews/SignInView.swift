import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            Text("Sign In View")
            
            
            
            // Sign In Button
            Button {
                Task {
                    try await authViewModel.signIn(withEmail: email, password: password)
                }
            } label: {
                Text("Sign In Button")
            }
            
            
            // Navigate to sign up view if user does not already have an account
            NavigationLink {
                SignUpView()
                // Back bar hidden, user should only be able to navigate between signin/up thru these buttons
                    .navigationBarBackButtonHidden(true)
            } label: {
                VStack {
                    Text("Don't have an account?")
                    Text("Sign up here")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
            
        }
    }
}


#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
