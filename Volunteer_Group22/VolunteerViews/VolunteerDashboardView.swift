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


// Volunteer Dashboard View
struct VolunteerDashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    
    var body: some View {
        ScrollView{
            VStack(spacing : 24){
                //Header section for the dashboard
                VStack(spacing: 4) {
                    HStack {
                        Text("Ready, Player One!")
                            .font(.system(size: 32, weight: .bold))
                        
                        Spacer()
                        
                        NavigationLink(destination: AdminProfileEditView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        Text("Here's what's happening today")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
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
    }
}


#Preview {
    VolunteerDashboardView()
}
