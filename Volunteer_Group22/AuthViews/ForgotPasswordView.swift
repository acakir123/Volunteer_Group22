import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Forgot Password")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)
            
            // Email Field
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .disableAutocorrection(true)
            
            // Error Message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Success Message
            if showSuccess {
                Text("Password reset email sent. Check your inbox.")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            
            // Reset Password Button
            Button {
                Task {
                    do {
                        try await authViewModel.resetPassword(withEmail: email)
                        showSuccess = true
                        showError = false
                    } catch {
                        showError = true
                        errorMessage = error.localizedDescription
                        showSuccess = false
                    }
                }
            } label: {
                Text("Reset Password")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Forgot Password")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
