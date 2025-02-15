import SwiftUI

// Quick stats for users dashboard - shows key metrics in a clean, modern card layout
struct UserStats: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct IDCardView: View {
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: .blue,
                                                    radius: CGFloat(0),
                                                    x: CGFloat(5), y: CGFloat(5))
                    .frame(width: 350, height: 200)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Voluntiir")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.blue)
                        Text("Volunteer ID Card")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("First Name:").font(.caption).bold()
                            Text("John")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.black)

                            Text("Last Name:").font(.caption).bold()
                            Text("Doe")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.black)

                            Text("DOB:").font(.caption).bold()
                            Text("06/03/1981")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Image(.a) // Replace with actual profile image
                            .resizable()
                            .frame(width: 90, height: 90)
                            .clipShape(Rectangle())
                            .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
                            .padding(.trailing, 10)
                    }
                }
                .padding(15)
            }
            .frame(width: 350, height: 200)
            
            Spacer()
        }
    }
}



// Volunteer Dashboard View
struct VolunteerDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView{
            VStack(spacing : 24){
                //Header section for the dashboard
                VStack(spacing: 4) {
                    HStack {
                        Text("Hello, John!")
                            .font(.system(size: 32, weight: .bold))
                        
                        Spacer()
                        
                        NavigationLink(destination: VolunteerProfileEditView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                    
//                    HStack {
//                        Text("Here's what's happening today")
//                            .font(.system(size: 17))
//                            .foregroundColor(.secondary)
//                        Spacer()
//                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                IDCardView()
                
                // Overview section with key statistics
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overview")
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        UserStats(
                            title: "Active Events",
                            value: "12",
                            icon: "calendar",
                            color: .blue
                        )
                        UserStats(
                            title: "Hours Donated",
                            value: "14",
                            icon: "clock",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }   //End of Overview section

            }
            
        }
        
    }//end of body

}



struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("Home Screen")
                .font(.largeTitle)
                .navigationTitle("Home")
        }
    }
}

struct SearchView: View {
    var body: some View {
        NavigationStack {
            Text("Search Screen")
                .font(.largeTitle)
                .navigationTitle("Search")
        }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Text("History Screen")
                .font(.largeTitle)
                .navigationTitle("History")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("Profile Screen")
                .font(.largeTitle)
                .navigationTitle("Profile")
        }
    }
}


#Preview {
    VolunteerDashboardView()
        .environmentObject(AuthViewModel())
}
