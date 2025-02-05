import SwiftUI


struct AdminMainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView {
            AdminVolunteerMatchView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Volunteer Match")
                }
                .tag(0)
            
            AdminDashboardView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Dashboard")
                }
                .tag(1)
            
            AdminReportingView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Reports")
                }
                .tag(2)
            
            }
        }
        // if admin profile not setup -> AdminProfileSetupView()
        
        /* TabView
         AdminDashboardView -- AdminProfileEditView
         AdminEventManagementView -> AdminCreateEventView, AdminEditEventView
         AdminVolunteerMatchView
         AdminReportingView
         */
    }

