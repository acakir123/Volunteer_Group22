import SwiftUI

struct VolunteerProfileEditView: View {
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "person.circle")
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
                        SettingsRow(icon: "creditcard.fill", title: "Payment & Shipping")
                    }
                    
                    NavigationLink(destination: Text("Preferences & Availability")) {
                        SettingsRow(icon: "calendar", title: "Preferences & Availability")
                    }
                }
                
                Section {
                    NavigationLink(destination: Text("Manage Skills")) {
                        SettingsRow(icon: "books.vertical.fill", title: "Manage Skills")
                    }
                    
                    NavigationLink(destination: Text("Location Services")) {
                        SettingsRow(icon: "location.fill", title: "Location Services")
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Voluntiir Account")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
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
        NavigationStack {
            VolunteerProfileEditView()
        }
    }
}
