import SwiftUI

struct VolunteerMainTabView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                VolunteerEventSearchView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Events")
            }
            .tag(0)

            NavigationView {
                VolunteerDashboardView()
            }
            .tabItem {
                Image(systemName: "person.3")
                Text("Dashboard")
            }
            .tag(1)

            NavigationView {
                VolunteerHistoryView()
            }
            .tabItem {
                Image(systemName: "clock")
                Text("History")
            }
            .tag(2)
        }
    }
    // if user profile not setup -> VolunteerProfileSetupView()

    /* TabView
     VolunteerDashboardView -- VolunteerProfileEditView
     VolunteerHistoryView
     VolunteerEventSearchView
     */
}

