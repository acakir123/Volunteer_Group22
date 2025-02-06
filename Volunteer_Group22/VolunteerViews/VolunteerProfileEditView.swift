import SwiftUI

struct VolunteerProfileEditView: View {
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Image("Voluntir-Logo") // Replace with actual image asset
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
                            SettingsRow(icon: "person.crop.circle", title: "Personal Information")
                        }
                        NavigationLink(destination: Text("Sign-In & Security")) {
                            SettingsRow(icon: "lock.fill", title: "Sign-In & Security")
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
                        NavigationLink(destination: Text("Subscriptions")) {
                            SettingsRow(icon: "clock.fill", title: "Subscriptions")
                        }
                    }
                    
                    Section {
                        NavigationLink(destination: Text("iCloud")) {
                            HStack {
                                SettingsRow(icon: "icloud.fill", title: "iCloud")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                        NavigationLink(destination: Text("Family")) {
                            HStack {
                                SettingsRow(icon: "person.3.fill", title: "Family")
                                Spacer()
                                Text("")
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                            }
                        }
                        NavigationLink(destination: Text("Find My")) {
                            SettingsRow(icon: "location.fill", title: "Find My")
                        }
                        NavigationLink(destination: Text("Media & Purchases")) {
                            SettingsRow(icon: "applelogo", title: "Media & Purchases")
                        }
                        NavigationLink(destination: Text("Sign in with Apple")) {
                            SettingsRow(icon: "applelogo", title: "Sign in with Apple")
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
