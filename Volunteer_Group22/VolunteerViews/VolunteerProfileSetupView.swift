import SwiftUI

struct VolunteerProfileSetupView: View {
    var body: some View {
        Text("Volunteer Profile Setup View.")
        
        NavigationLink {
            VolunteerEventSearchView()
                .navigationBarBackButtonHidden(true)
        } label: {
            Image(systemName: "arrowshape.turn.up.backward.badge.clock")
            Text("Back")
        }
    }
    
}



#Preview {
    VolunteerProfileSetupView()
}
