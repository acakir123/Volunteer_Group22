import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                VolunteerMainTabView()
                
                
                /* if user.role == admin {
                    AdminMainTabView()
                 } else if user.role == volunteer {
                    VolunteerMainTabView()
                 }
                 */ 
            } else {
                SignInView()
            }
        }
    }
}

#Preview {
    ContentView()
}
