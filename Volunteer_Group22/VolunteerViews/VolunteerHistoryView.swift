import SwiftUI
import FirebaseFirestore

struct StarRatingView: View {
    let rating: Int
    let maxRating: Int = 5
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                    .font(.system(size: 14))
            }
        }
    }
}

struct HistoryLoadingView: View {
    var body: some View {
        ProgressView("Loading history...")
    }
}

struct HistoryErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
                .padding()
            
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No past activities yet")
                .font(.headline)
            
            Text("Your completed volunteer activities will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryItemView: View {
    let record: VolunteerHistoryRecord
    let eventName: String?  // Added eventName property to display the event name
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Event Name
            Text(eventName ?? "Unknown Event")  // Display the event name here
                .font(.headline)
            
            // Volunteer name
            Text(record.fullName ?? "Unknown Volunteer")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Feedback text
            if !record.feedback.isEmpty {
                Text(record.feedback)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Performance Data
            PerformanceDataView(performance: record.performance)
            
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(formatDate(record.dateCompleted ?? Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct PerformanceDataView: View {
    let performance: [String: Any]
    
    var body: some View {
        if !performance.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(performance.keys.sorted(), id: \.self) { key in
                    if key.lowercased() == "rating", let ratingValue = performance[key] {
                        let rating = getRatingValue(from: ratingValue)
                        HStack(alignment: .center, spacing: 8) {
                            Text("Rating:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            StarRatingView(rating: rating)
                        }
                    } else {
                        HStack {
                            Text("\(key.capitalized):")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("\(getStringValue(from: performance[key]))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private func getRatingValue(from value: Any?) -> Int {
        if let intValue = value as? Int {
            return intValue
        } else if let doubleValue = value as? Double {
            return Int(doubleValue)
        } else if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        }
        return 0
    }
    
    private func getStringValue(from value: Any?) -> String {
        if let stringValue = value as? String {
            return stringValue
        } else if let intValue = value as? Int {
            return String(intValue)
        } else if let doubleValue = value as? Double {
            return String(doubleValue)
        } else if let boolValue = value as? Bool {
            return boolValue ? "Yes" : "No"
        }
        return "N/A"
    }
}

struct HistoryContentView: View {
    let records: [VolunteerHistoryRecord]
    let eventDetails: [String: String]  // Add eventDetails as a parameter
    let refreshAction: () async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(records) { record in
                    // Fetch the event name from eventDetails
                    let eventName = eventDetails[record.eventId] ?? "Unknown Event"
                    HistoryItemView(record: record, eventName: eventName)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .refreshable {
            await refreshAction()
        }
    }
}

struct VolunteerHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = VolunteerHistoryViewModel()
    @State private var eventDetails: [String: String] = [:]  // Dictionary to hold event names
    private let db = Firestore.firestore()  // Add Firestore reference here

    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            mainContentView
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            Task {
                await fetchHistory()
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Past Activities")
                .font(.system(size: 32, weight: .bold))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var mainContentView: some View {
        ZStack {
            if viewModel.isLoading {
                HistoryLoadingView()
            } else if let error = viewModel.errorMessage {
                HistoryErrorView(errorMessage: error) {
                    Task {
                        await fetchHistory()
                    }
                }
            } else if viewModel.historyRecords.isEmpty {
                HistoryEmptyView()
            } else {
                // Pass eventDetails to HistoryContentView
                HistoryContentView(records: viewModel.historyRecords, eventDetails: eventDetails) {
                    await fetchHistory()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func fetchHistory() async {
        if let userId = authViewModel.userSession?.uid {
            await viewModel.fetchVolunteerHistory(for: userId, db: authViewModel.db)
            await fetchEventNames(for: userId)  // Fetch event names using eventId
        }
    }

    // Fetch event names using eventId from "events" collection
    private func fetchEventNames(for userId: String) async {
        let eventIds = viewModel.historyRecords.map { $0.eventId }
        
        var newEventDetails: [String: String] = [:]

        for eventId in eventIds {
            do {
                let eventDoc = try await db.collection("events").document(eventId).getDocument()

                if let eventData = eventDoc.data() {
                    let eventName = eventData["name"] as? String ?? "Unknown Event"
                    newEventDetails[eventId] = eventName
                } else {
                    newEventDetails[eventId] = "Unknown Event"
                }
            } catch {
                newEventDetails[eventId] = "Unknown Event"
            }
        }

        await MainActor.run {
            self.eventDetails = newEventDetails
        }
    }
}

class VolunteerHistoryViewModel: ObservableObject {
    @Published var historyRecords: [VolunteerHistoryRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let db = Firestore.firestore()
    
    func fetchVolunteerHistory(for userId: String, db: Firestore) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let historySnapshot = try await db.collection("volunteerHistory")
                .whereField("volunteerId", isEqualTo: userId)
                .getDocuments()
            
            let records: [VolunteerHistoryRecord] = historySnapshot.documents.map { VolunteerHistoryRecord(document: $0) }
            
            let sortedRecords = records.sorted { ($0.dateCompleted ?? Date.distantPast) > ($1.dateCompleted ?? Date.distantPast) }
            
            DispatchQueue.main.async {
                self.historyRecords = sortedRecords
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load volunteer history: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

struct VolunteerHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        VolunteerHistoryView()
    }
}
