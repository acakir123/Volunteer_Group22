import SwiftUI

struct VolunteerProfileEditView: View {
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Image(.a) // Replace with actual image asset
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .padding(.bottom, 5)
                    
                    Text("John Doe")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("johndoe123@gmail.com")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                
                List {
                    Section {
                        NavigationLink(destination: Text("Personal Information")) {
                            HStack {
                                SettingsRow(icon: "person.crop.circle", title: "Personal Information")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            
                        }
                        NavigationLink(destination: Text("Sign-In & Security")) {
                            HStack {
                                SettingsRow(icon: "lock.fill", title: "Sign-In & Security")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                            
                        }
                        NavigationLink(destination: Text("Payment & Shipping")) {
                            HStack {
                                SettingsRow(icon: "creditcard.fill", title: "Payment & Shipping")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                        NavigationLink(destination: Text("Preferences & Availability")) {
                            HStack {
                                SettingsRow(icon: "calendar", title: "Preferences & Availability")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    Section {
                        NavigationLink(destination: Text("Manage Skills")) {
                            HStack {
                                SettingsRow(icon: "books.vertical.fill", title: "Manage Skills")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                        
                        NavigationLink(destination: Text("Location Services")) {
                            HStack {
                                SettingsRow(icon: "location.fill", title: "Location Services")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Voluntiir Account", displayMode: .inline)
        }
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.body)
        }
    }
}

struct VolunteerProfileEdit_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerProfileEditView()
    }
}

//No need for regular #Preview {}
