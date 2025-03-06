import SwiftUI
import FirebaseFirestore

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

            var records: [VolunteerHistoryRecord] = historySnapshot.documents.map { VolunteerHistoryRecord(document: $0) }

            // Manually sort by dateCompleted in descending order
            records.sort { ($0.dateCompleted ?? Date.distantPast) > ($1.dateCompleted ?? Date.distantPast) }
            
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
                if viewModel.isLoading {
                    ProgressView("Loading history...")
                } else if let error = viewModel.errorMessage {
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
                } else if viewModel.historyRecords.isEmpty {
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
                } else {
                    List {
                        ForEach(viewModel.historyRecords) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(record.fullName ?? "Unknown Volunteer")
                                    .font(.headline)

                                Text(record.feedback)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)

                                // Display Performance Data (Without "Performance" label)
                                if !record.performance.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(record.performance.keys.sorted(), id: \.self) { key in
                                            HStack {
                                                Text("\(key.capitalized):")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Text("\(String(describing: record.performance[key] ?? "N/A"))")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                        }
                                    }
                                }

                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    Text(formatDate(record.dateCompleted ?? Date()))
                                        .font(.caption)
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
