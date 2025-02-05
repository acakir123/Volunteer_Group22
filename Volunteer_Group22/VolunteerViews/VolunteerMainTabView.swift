import SwiftUI


struct VolunteerMainTabView: View {
    @State private var selectedTab = 1
    
    var body: some View {
        TabView {
            AdminVolunteerMatchView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("History")
                }
                .tag(0)
            
            VolunteerDashboardView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Dashboard")
                }
                .tag(1)
            
            AdminReportingView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Events")
                }
                .tag(2)
            
            }
        
        // if user profile not setup -> VolunteerProfileSetupView()
        
        /* TabView
         VolunteerDashboardView -- VolunteerProfileEditView
         VolunteerHistoryView
         VolunteerEventSearchView
         */
    }
}
