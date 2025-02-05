import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo
                Image("Voluntir-Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 100)
                    .padding(.vertical, 32)
                
                // Email Field
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                
                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Error Message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Sign Up Button
                Button {
                    Task {
                        do {
                            try await authViewModel.signUp(withEmail: email, password: password)
                        } catch {
                            showError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                } label: {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Navigate to Sign In View
                NavigationLink {
                    SignInView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    VStack {
                        Text("Already have an account?")
                        Text("Sign in here")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .font(.system(size: 14))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
