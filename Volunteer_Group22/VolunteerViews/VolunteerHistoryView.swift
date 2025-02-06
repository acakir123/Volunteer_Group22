import SwiftUI

struct VolunteerHistoryView: View {
    var body: some View {
        Text("Volunteer History View.")
        
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
        VolunteerHistoryView()
}
