import SwiftUI

struct AdminDashboardView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .edgesIgnoringSafeArea(.all)
            
            
            VStack {
                HStack {
                    Text("Welcome, Admin")
                        .font(.system(size: 32))
                    
                    Spacer()
                    
                    Image(systemName: "person.circle")
                        .font(.system(size: 32))
                        .padding(.trailing, 10)
                }
                .padding(.leading, 25)
                .padding(.top, 20)
                .padding(.bottom, 35)
                
                
                HStack {
                    Text("Overview")
                        .font(.system(size: 24))
                    
                }
                
                Spacer()
                
                
                VStack {
                    Text("Quick Actions")
                        .font(.system(size: 24))
                    
                    HStack {
                        VStack {
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 18))
                            
                            Text("Create Event")
                                .font(.system(size: 18))
                        }
                        Spacer()
                        
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 18))
                        
                        Spacer()
                        
                        Image(systemName: "pencil.circle")
                            .font(.system(size: 18))
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 25)
                }
                .background(Color.black.opacity(0.2))
                
                
                Spacer()
                
                HStack {
                    Text("Recent Activities")
                        .font(.system(size: 24))
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthViewModel())
}
