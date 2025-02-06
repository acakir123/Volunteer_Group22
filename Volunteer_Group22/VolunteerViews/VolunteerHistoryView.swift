import SwiftUI


struct PastActivity {
    let title: String
    let timestamp: String
    let type: ActivityType
    
    enum ActivityType {
        case event
        var icon : String {
            switch self {
            
            case .event:
                return "calendar"
            }
        }
        
        var color: Color {
            switch self {
            case .event:
                return .blue
            }
        }
    }
}




struct VolunteerHistoryView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Sample activities - will be replaced with real data from backend
    @State private var activities: [PastActivity] = [
    PastActivity(title: "Past Events You Participated", timestamp: "2 days ago", type: .event)
    ]
        
    var body: some View {
        
        NavigationView {
            VStack {
                HStack {    //HStack for the title
                    Text("Past Activities")
                        .font(.system(size: 24, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center) // Center the text
                    Spacer()
                }

                List{
                    Text("Item 1")
                    Text("Item 2")
                    Text("Item 3")
                    
                    
                }   //End of list
                .navigationBarTitle("History", displayMode: .inline)
            }
        }
        
        
        
    }   //End of body
}   //End of VolunteerHistoryView


#Preview {
    VolunteerHistoryView()
}
