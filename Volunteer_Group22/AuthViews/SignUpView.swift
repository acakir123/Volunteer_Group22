import SwiftUI

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var role = "Volunteer"
    @State private var showError = false
    @State private var errorMessage = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            // Logo
            Image("Voluntir-Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.top, 30)
                .padding(.bottom, 30)
            
            // Input Fields
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                
                // Role Selection with Circular Buttons
                HStack {
                    Button(action: { role = "Administrator" }) {
                        HStack {
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .fill(role == "Administrator" ? Color.blue : Color.clear)
                                        .frame(width: 10, height: 10)
                                )
                            Text("Administrator")
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { role = "Volunteer" }) {
                        HStack {
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .fill(role == "Volunteer" ? Color.blue : Color.clear)
                                        .frame(width: 10, height: 10)
                                )
                            Text("Volunteer")
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
            
            // Error Message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 8)
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
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.headline)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Sign In Navigation
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(.footnote)
                NavigationLink {
                    SignInView()
                        .navigationBarBackButtonHidden(true)
                } label: {
                    Text("Sign in here")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 16)
            
            Spacer()
        }
        .padding()
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
