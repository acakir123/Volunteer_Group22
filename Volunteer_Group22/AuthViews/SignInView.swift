import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
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
                    Text("Sign In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Welcome back to the app")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 30)
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email Address")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            TextField("Enter your Email", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            SecureField("********", text: $password)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .frame(height: 50)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        NavigationLink {
                            ForgotPasswordView()
                                .navigationBarBackButtonHidden(true)
                        } label: {
                            Text("Forgot Password?")
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Error Message
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    
                    // Sign In Button
                    Button {
                        Task {
                            do {
                                try await authViewModel.signIn(withEmail: email, password: password)
                            } catch {
                                showError = true
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                    }
                    .padding(.top, 20)
                    
                    // Sign Up Navigation
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.footnote)
                            NavigationLink {
                                SignUpView()
                                    .navigationBarBackButtonHidden(true)
                            } label: {
                                Text("Sign up here")
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

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthViewModel())
    }
}
