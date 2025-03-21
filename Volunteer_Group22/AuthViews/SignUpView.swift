import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var role = "Volunteer"
    @State private var showError = false
    @State private var errorMessage = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Centered Logo
                HStack {
                    Spacer()
                    Image("Voluntir-Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                    Spacer()
                }
                
            
                VStack(alignment: .leading) {
                    
                    // Page Title and Subtitle
                    Text("Sign Up")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Create your account to get started")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 30)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            TextField("Enter an email address", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            SecureField("Create a password", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Role Selection
                    HStack {
                        Spacer()
                        HStack(spacing: 20) {
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
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    
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
                                try await authViewModel.signUp(withEmail: email, password: password, role: role)
                                
                                if let user = Auth.auth().currentUser {
                                    user.sendEmailVerification { error in
                                        if let error = error {
                                            print("Error sending email verification: \(error.localizedDescription)")
                                        }
                                    }
                                }
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
                    .padding(.top, 20)
                    
                    // Sign In Navigation
                    HStack {
                        Spacer()
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
                        Spacer()
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
