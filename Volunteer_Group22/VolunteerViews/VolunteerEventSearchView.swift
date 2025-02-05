import SwiftUI



struct VolunteerEventSearchView: View {
    @State private var searchText : String = ""
    
    
    var body: some View {
        NavigationStack {   //Nagivation stack for search bar
            VStack(spacing: 20) {
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                    
                    TextField("Search", text: $searchText)
                        .padding(.vertical, 10) // Adjust text position
                        .padding(.horizontal, 5)
                        .background(Color.clear)
                        .autocapitalization(.none)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
            
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 10)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.horizontal, 16) // Extra horizontal padding for alignment
                
                HStack(spacing: 10) {    //Single stack for search results
                    Text("Search Results")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                }
            
                
                List {  //Events need to be created from the database that the admin will create, uodate, and delete
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
