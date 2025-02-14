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


// Search and filter bar
struct SearchBar: View {
    @Binding var searchText: String
    @Binding var selectedFilter: Event.EventStatus?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search events...", text: $searchText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(Event.EventStatus.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: selectedFilter == status,
                            action: { selectedFilter = status }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Filter chip component
struct FilterChipHistory: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(uiColor: .systemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                    Text("Past Events")
                        .font(.system(size: 24, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .center) // Center the text
                    Spacer()
                }

                List{
                    Text("Item 1")
                    Text("Item 2")
                    Text("Item 3")
                    
                    
                }   //End of list
                
                
                
            }
        }
        
        
        
    }   //End of body
}   //End of VolunteerHistoryView


#Preview {
    VolunteerHistoryView()
        
}
