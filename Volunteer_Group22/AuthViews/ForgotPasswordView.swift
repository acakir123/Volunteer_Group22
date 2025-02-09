import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Back Button
            Button(action: {
                // Add back navigation logic here
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
            }
            
            // Title
            Text("Forgot password")
                .font(.title)
                .fontWeight(.bold)
                
            Text("Please enter your email to reset the password")
                .font(.subheadline)
                .foregroundColor(.gray)
                
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Email")
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
            }
            
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
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .environmentObject(AuthViewModel())
    }
}
