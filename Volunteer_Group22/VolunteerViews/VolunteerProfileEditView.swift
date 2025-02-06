import SwiftUI

struct VolunteerProfileEditView: View {
    var body: some View {
        Text("Volunteer Profile Edit View.")
        
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
    VolunteerProfileEditView()
}
