import SwiftUI
import FirebaseFirestore

// Model for volunteer history records
struct VolunteerHistoryRecord: Identifiable {
    let id = UUID()
    var documentId: String?
    var eventId: String
    var volunteerId: String
    var dateCompleted: Date
    var performance: [String: Any]
    var feedback: String
    var createdAt: Date?
    
    // Event details (populated after fetching event data)
    var eventTitle: String = ""
    var eventDescription: String = ""
    var eventLocation: String = ""
    var eventDate: Date = Date()
    
    // Participation status
    var participationStatus: ParticipationStatus = .attended
    
    enum ParticipationStatus: String, CaseIterable {
        case attended = "Attended"
        case canceled = "Canceled"
        case noShow = "No Show"
        
        var color: Color {
            switch self {
            case .attended:
                return .green
            case .canceled:
                return .orange
            case .noShow:
                return .red
            }
        }
    }
    
    // Initialize from Firestore document
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.eventId = data["eventId"] as? String ?? ""
        self.volunteerId = data["volunteerId"] as? String ?? ""
        self.dateCompleted = (data["dateCompleted"] as? Timestamp)?.dateValue() ?? Date()
        self.performance = data["performance"] as? [String: Any] ?? [:]
        self.feedback = data["feedback"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        
        // Determine participation status based on event data (default to attended)
        if let performanceData = self.performance as? [String: String],
           let status = performanceData["status"] {
            if status == "canceled" {
                self.participationStatus = .canceled
            } else if status == "noShow" {
                self.participationStatus = .noShow
            } else {
                self.participationStatus = .attended
            }
        }
    }
}

// ViewModel for handling Volunteer History
class VolunteerHistoryViewModel: ObservableObject {
    @Published var historyRecords: [VolunteerHistoryRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    // Fetch volunteer history for a specific user
    func fetchVolunteerHistory(for userId: String, db: Firestore) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let historySnapshot = try await db.collection("volunteerHistory")
                .whereField("volunteerId", isEqualTo: userId)
                .getDocuments() // No index required

            var records: [VolunteerHistoryRecord] = []
            
            for document in historySnapshot.documents {
                var record = VolunteerHistoryRecord(documentId: document.documentID, data: document.data())

                // Fetch the associated event data
                if !record.eventId.isEmpty {
                    if let eventData = try? await fetchEventDetails(eventId: record.eventId, db: db) {
                        record.eventTitle = eventData["name"] as? String ?? "Unknown Event"
                        record.eventDescription = eventData["description"] as? String ?? ""

                        if let locationData = eventData["location"] as? [String: String] {
                            let address = locationData["address"] ?? ""
                            let city = locationData["city"] ?? ""
                            let state = locationData["state"] ?? ""

                            var locationComponents = [String]()
                            if !address.isEmpty { locationComponents.append(address) }
                            if !city.isEmpty { locationComponents.append(city) }
                            if !state.isEmpty { locationComponents.append(state) }

                            record.eventLocation = locationComponents.joined(separator: ", ")
                        }

                        record.eventDate = (eventData["dateTime"] as? Timestamp)?.dateValue() ?? Date()
                    }
                }
                
                records.append(record)
            }
            
            // Manually sort by dateCompleted in descending order
            records.sort { $0.dateCompleted > $1.dateCompleted }
            
            DispatchQueue.main.async {
                self.historyRecords = records
                self.isLoading = false
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load volunteer history: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    
    // Helper function to fetch event details
    private func fetchEventDetails(eventId: String, db: Firestore) async throws -> [String: Any]? {
        let eventDoc = try await db.collection("events").document(eventId).getDocument()
        if eventDoc.exists {
            return eventDoc.data()
        }
        return nil
    }
}

// Updated VolunteerHistoryView to use the ViewModel
struct VolunteerHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VolunteerHistoryViewModel()
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Past Activities")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 16)
                Spacer()
            }
            .padding(.horizontal)
            
            // Content based on state
            ZStack {
                // Loading state
                if viewModel.isLoading {
                    ProgressView("Loading history...")
                }
                // Error state
                else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Button("Try Again") {
                            Task {
                                if let userId = authViewModel.userSession?.uid {
                                    await viewModel.fetchVolunteerHistory(for: userId, db: authViewModel.db)
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .padding()
                }
                // Empty state
                else if viewModel.historyRecords.isEmpty {
                    VStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                            .padding()
                        
                        Text("No past activities yet")
                            .font(.headline)
                        
                        Text("Your completed volunteer activities will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                }
                // List of past activities
                else {
                    List {
                        ForEach(viewModel.historyRecords) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                // Event Title
                                Text(record.eventTitle)
                                    .font(.headline)
                                
                                // Event Description
                                Text(record.eventDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                // Event Date and Location
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text(formatDate(record.eventDate))
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.blue)
                                    Text(record.eventLocation)
                                        .font(.caption)
                                        .lineLimit(1)
                                }
                                
                                // Participation Status
                                HStack {
                                    Text("Status:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(record.participationStatus.rawValue)
                                        .font(.caption)
                                        .foregroundColor(record.participationStatus.color)
                                        .fontWeight(.medium)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        if let userId = authViewModel.userSession?.uid {
                            await viewModel.fetchVolunteerHistory(for: userId, db: authViewModel.db)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Load data when view appears
            Task {
                if let userId = authViewModel.userSession?.uid {
                    await viewModel.fetchVolunteerHistory(for: userId, db: authViewModel.db)
                }
            }
        }
    }
    
    // Helper method to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct VolunteerHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerHistoryView()
            .environmentObject(AuthViewModel())
    }
}
