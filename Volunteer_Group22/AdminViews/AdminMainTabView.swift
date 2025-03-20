import SwiftUI

struct AdminMainTabView: View {
    @State private var selectedTab = 0
    @State private var adminProfileFinished = true
    
    
    var body: some View {
        Group {
            TabView(selection: $selectedTab) {
                // Dashboard
                NavigationView {
                    AdminDashboardView()
                        .navigationBarHidden(true)
                }
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Dashboard")
                }
                .tag(0)
                
                // Events
                NavigationView {
                    AdminEventManagementView()
                }
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(1)
                
                // Matching
                NavigationView {
                    AdminVolunteerMatchView()
                }
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Match")
                }
                .tag(2)
                
                // Reports
                NavigationView {
                    AdminReportingView()
                }
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Reports")
                }
                .tag(3)
            }
            .tint(.blue)
        }
        
    }
}

