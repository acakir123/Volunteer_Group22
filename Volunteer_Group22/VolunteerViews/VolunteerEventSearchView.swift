import SwiftUI



struct VolunteerEventSearchView: View {
    @State private var searchText : String = ""
    
    
    var body: some View {
        NavigationStack {   //Nagivation stack for search bar
            VStack(spacing: 20) {
                
                TextField("Search", text: $searchText)
                            .padding(12) // Increased padding for better touch area
                            .background(Color(.systemGray6)) // iOS-style background
                            .cornerRadius(12) // Rounded corners like native iOS search bars
                            .shadow(radius: 1) // Subtle shadow to match iOS depth effect
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    if !searchText.isEmpty {
                                        Button(action: {
                                            searchText = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                            )
                            .padding(.horizontal, 16) // Additional horizontal padding
                            .autocapitalization(.none)
                            .keyboardType(.default)
                            .disableAutocorrection(true)
                    
                
                HStack {
                    Text("Search Results")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                }
                List {
                    // Event 1
                    //NavigationLink(destination: VolunteerEventDetailView()) {
                    HStack {
                        Image("event1")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading) {
                            Text("Event 1")
                                .font(.headline)
                            
                            Text("Description of Event 1")
                                .font(.subheadline)
                        }
                    }
                    
                    
                    // Event 2
                    //NavigationLink(destination: VolunteerEventDetailView()) {
                    HStack {
                        Image("event2")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading) {
                            Text("Event 2")
                                .font(.headline)
                            
                            Text("Description of Event 2")
                                .font(.subheadline)
                        }
                    }
                    
                    
                    // Event 3
                    //NavigationLink(destination: VolunteerEventDetailView()) {
                    HStack {
                        Image("event3")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                        
                        VStack(alignment: .leading) {
                            Text("Event 3")
                                .font(.headline)
                            
                            Text("Description of Event 3")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        
        
        
    }   //End of body
}   //End of VolunteerEventSearchView
                
                

#Preview{
    VolunteerEventSearchView()
    
}
