/*import SwiftUI
import FirebaseFirestore

// MARK: - Supporting Components

struct StatisticCard: View {
    let title: String
    let value: String
    let trend: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(trend), specifier: "%.1f")%")
                            .font(.caption)
                    }
                    .foregroundColor(trend >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((trend >= 0 ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct SimpleBarChart: View {
    let data: [(String, Double)]
    let maxValue: Double
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(data, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.caption)
                        .frame(width: 100, alignment: .trailing)
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(item.1 / maxValue))
                    }
                    
                    Text("\(Int(item.1))")
                        .font(.caption)
                        .frame(width: 40, alignment: .leading)
                }
                .frame(height: 20)
            }
        }
    }
}

struct CircleProgressView: View {
    let percentage: Double
    let color: Color
    let label: String
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 20, weight: .bold))
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .frame(height: 200)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - AdminReportingView with Firebase Integration

struct AdminReportingView: View {
    @State private var selectedDateRange: DateRange = .lastMonth
    @State private var showingExportOptions = false
    @State private var selectedExportFormat: ExportFormat = .pdf
    
    @State private var totalVolunteers: Int = 0
    @State private var activeEvents: Int = 0
    @State private var hoursDonated: Int = 0
    @State private var successRate: Double = 0
    @State private var skillDistribution: [(String, Double)] = []
    @State private var eventStatus: [(String, Double)] = []
    
    private let db = Firestore.firestore()
    
    enum DateRange: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case lastYear = "Last Year"
        case custom = "Custom Range"
    }
    
    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF"
        case csv = "CSV"
        case excel = "Excel"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatisticCard(title: "Total Volunteers", value: "\(totalVolunteers)", trend: nil)
                    StatisticCard(title: "Active Events", value: "\(activeEvents)", trend: nil)
                    StatisticCard(title: "Hours Donated", value: "\(hoursDonated)", trend: nil)
                    StatisticCard(title: "Success Rate", value: "\(Int(successRate))%", trend: nil)
                }
                .padding(.horizontal)
                
                ChartCard(title: "Event Status Distribution", subtitle: "Current event status breakdown") {
                    HStack {
                        ForEach(eventStatus, id: \.0) { status in
                            CircleProgressView(percentage: status.1, color: .blue, label: status.0)
                        }
                    }
                }
                
                ChartCard(title: "Volunteer Skills", subtitle: "Distribution of volunteer skills") {
                    SimpleBarChart(data: skillDistribution, maxValue: skillDistribution.map { $0.1 }.max() ?? 100)
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            Task {
                await fetchReportData()
            }
        }
    }
    
    private func fetchReportData() async {
        do {
            let volunteersSnapshot = try await db.collection("users").whereField("role", isEqualTo: "Volunteer").getDocuments()
            totalVolunteers = volunteersSnapshot.documents.count

            let eventsSnapshot = try await db.collection("events").whereField("status", isEqualTo: "Upcoming").getDocuments()
            activeEvents = eventsSnapshot.documents.count

            let allEvents = try await db.collection("events").getDocuments()
            hoursDonated = allEvents.documents.reduce(0) { sum, document in
                let assignedVolunteers = document.data()["assignedVolunteers"] as? [String] ?? []
                return sum + (assignedVolunteers.count * 5)
            }

            let completedEvents = allEvents.documents.filter { ($0.data()["status"] as? String) == "Completed" }.count
            let totalEvents = allEvents.documents.count
            successRate = totalEvents > 0 ? (Double(completedEvents) / Double(totalEvents)) * 100 : 0

        } catch {
            print("Error fetching report data: \(error.localizedDescription)")
        }
    }
}
*/

import SwiftUI
import FirebaseFirestore

// MARK: - Structs (Keeping Original Structure)

struct StatisticCard: View {
    let title: String
    let value: String
    let trend: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))

                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(abs(trend), specifier: "%.1f")%")
                            .font(.caption)
                    }
                    .foregroundColor(trend >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((trend >= 0 ? Color.green : Color.red)
                        .opacity(0.1)
                        .cornerRadius(8)
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct SimpleBarChart: View {
    let data: [(String, Double)]
    let maxValue: Double

    var body: some View {
        VStack(spacing: 16) {
            ForEach(data, id: \.0) { item in
                HStack {
                    Text(item.0)
                        .font(.caption)
                        .frame(width: 100, alignment: .trailing)

                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * CGFloat(item.1 / maxValue))
                    }

                    Text("\(Int(item.1))")
                        .font(.caption)
                        .frame(width: 40, alignment: .leading)
                }
                .frame(height: 20)
            }
        }
    }
}

struct CircleProgressView: View {
    let percentage: Double
    let color: Color
    let label: String

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(percentage / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 20, weight: .bold))
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 100, height: 100)
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            content
                .frame(height: 200)
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Main View
struct AdminReportingView: View {
    private let db = Firestore.firestore()

    @State private var totalVolunteers: Int = 0
    @State private var activeEvents: Int = 0
    @State private var totalHours: Int = 0
    @State private var successRate: Int = 0

    @State private var eventStatus = [("Completed", 0.0), ("In Progress", 0.0), ("Upcoming", 0.0)]
    @State private var skillDistribution: [(String, Double)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reports & Analytics")
                            .font(.system(size: 32, weight: .bold))
                        Text("Overview of volunteer performance")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.horizontal)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatisticCard(title: "Total Volunteers", value: "\(totalVolunteers)", trend: 12.5)
                    StatisticCard(title: "Active Events", value: "\(activeEvents)", trend: -5.0)
                    StatisticCard(title: "Hours Donated", value: "\(totalHours)", trend: 8.3)
                    StatisticCard(title: "Success Rate", value: "\(successRate)%", trend: 2.1)
                }
                .padding(.horizontal)

                VStack(spacing: 24) {
                    ChartCard(
                        title: "Event Status Distribution",
                        subtitle: "Current event status breakdown"
                    ) {
                        HStack(spacing: 20) {
                            ForEach(eventStatus, id: \.0) { status in
                                CircleProgressView(
                                    percentage: status.1,
                                    color: status.0 == "Completed" ? .green :
                                          status.0 == "In Progress" ? .blue : .orange,
                                    label: status.0
                                )
                            }
                        }
                    }

                    ChartCard(
                        title: "Volunteer Skills",
                        subtitle: "Distribution of volunteer skills"
                    ) {
                        SimpleBarChart(
                            data: skillDistribution,
                            maxValue: skillDistribution.map { $0.1 }.max() ?? 100
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            Task {
                do {
                    await fetchStatistics()
                    await fetchEventStatus()
                    try await fetchVolunteerSkills() // This function can throw, so we use `try`
                } catch {
                    print("Error fetching volunteer skills: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Fetch Data from Firestore
    private func fetchStatistics() {
        Task {
            totalVolunteers = await fetchTotalVolunteers()
            activeEvents = await fetchActiveEventsCount()
            totalHours = await fetchTotalHoursDonated()
            successRate = await fetchSuccessRate()
        }
    }

    // Fetch total volunteers from Firestore
    private func fetchTotalVolunteers() async -> Int {
        do {
            let snapshot = try await db.collection("users").whereField("role", isEqualTo: "Volunteer").getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching total volunteers: \(error.localizedDescription)")
            return 0
        }
    }

    // Fetch active events count from Firestore
    private func fetchActiveEventsCount() async -> Int {
        do {
            let snapshot = try await db.collection("events").whereField("status", isEqualTo: "Upcoming").getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching active events: \(error.localizedDescription)")
            return 0
        }
    }

    // Fetch total hours donated (Assuming each assigned volunteer contributes 5 hours)
    private func fetchTotalHoursDonated() async -> Int {
        do {
            let snapshot = try await db.collection("events").getDocuments()
            return snapshot.documents.reduce(0) { $0 + (($1.data()["assignedVolunteers"] as? [String])?.count ?? 0) * 5 }
        } catch {
            print("Error fetching total hours donated: \(error.localizedDescription)")
            return 0
        }
    }

    // Fetch success rate (Ratio of completed events to all events)
    private func fetchSuccessRate() async -> Int {
        do {
            let completedSnapshot = try await db.collection("events").whereField("status", isEqualTo: "Completed").getDocuments()
            let totalSnapshot = try await db.collection("events").getDocuments()
            
            let completedCount = completedSnapshot.documents.count
            let totalCount = totalSnapshot.documents.count
            
            return totalCount > 0 ? Int((Double(completedCount) / Double(totalCount)) * 100) : 0
        } catch {
            print("Error fetching success rate: \(error.localizedDescription)")
            return 0
        }
    }

    private func fetchEventStatus() {
        Task {
            do {
                let snapshot = try await db.collection("events").getDocuments()
                let completed = snapshot.documents.filter { $0.data()["status"] as? String == "Completed" }.count
                let inProgress = snapshot.documents.filter { $0.data()["status"] as? String == "In Progress" }.count
                let upcoming = snapshot.documents.filter { $0.data()["status"] as? String == "Upcoming" }.count
                DispatchQueue.main.async {
                    self.eventStatus = [("Completed", Double(completed)), ("In Progress", Double(inProgress)), ("Upcoming", Double(upcoming))]
                }
            } catch {
                print("Error fetching event statuses: \(error.localizedDescription)")
            }
        }
    }

    private func fetchVolunteerSkills() async throws -> [String: Int] {
        var skillsCount: [String: Int] = [:]

        let snapshot = try await db.collection("users").whereField("role", isEqualTo: "Volunteer").getDocuments()

        for document in snapshot.documents {
            if let skills = document.data()["skills"] as? [String] {
                for skill in skills {
                    skillsCount[skill, default: 0] += 1
                }
            }
        }
        
        return skillsCount
    }
    
    private func fetchSkillDistribution() {
        Task {
            do {
                let skillsCount = try await fetchVolunteerSkills() // Fetch skills asynchronously

                // Convert dictionary into a sorted list of tuples (skill, count)
                let sortedSkills = skillsCount.sorted { $0.value > $1.value }

                // Ensure UI updates happen on the main thread
                DispatchQueue.main.async {
                    self.skillDistribution = sortedSkills.map { ($0.key, Double($0.value)) }
                }
                
            } catch {
                print("Error fetching skill distribution: \(error.localizedDescription)")
            }
        }
    }
}


