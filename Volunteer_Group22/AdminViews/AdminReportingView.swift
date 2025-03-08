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
        VStack(alignment: .leading, spacing: 12) {
            ForEach(data, id: \.0) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(item.1))")
                            .font(.caption.bold())
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                                .frame(height: 10)
                            
                            // Value bar
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: max(CGFloat(item.1 / maxValue) * geometry.size.width, 10), height: 10)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(.vertical, 6)
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
    let fixedHeight: Bool
    
    init(
        title: String,
        subtitle: String? = nil,
        fixedHeight: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.fixedHeight = fixedHeight
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
            
            if fixedHeight {
                content
                    .frame(height: 200)
            } else {
                content
            }
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
                        subtitle: "Distribution of volunteer skills",
                        fixedHeight: false
                    ) {
                        VStack(alignment: .leading, spacing: 0) {
                            SimpleBarChart(
                                data: skillDistribution,
                                maxValue: skillDistribution.map { $0.1 }.max() ?? 100
                            )
                            .padding(.top, 8)
                            .padding(.bottom, 16)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .onAppear {
            Task {
                do {
                    fetchStatistics()
                    fetchEventStatus()
                    
                    let skillsCount = try await fetchVolunteerSkills()
                    let sortedSkills = skillsCount.sorted { $0.value > $1.value }
                    
                    DispatchQueue.main.async {
                        self.skillDistribution = sortedSkills.map { ($0.key, Double($0.value)) }
                    }
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
                let totalCount = snapshot.documents.count
                
                guard totalCount > 0 else {
                    DispatchQueue.main.async {
                        self.eventStatus = [("Completed", 0), ("In Progress", 0), ("Upcoming", 0)]
                    }
                    return
                }
                
                let completed = snapshot.documents.filter { $0.data()["status"] as? String == "Completed" }.count
                let inProgress = snapshot.documents.filter { $0.data()["status"] as? String == "In Progress" }.count
                let upcoming = snapshot.documents.filter { $0.data()["status"] as? String == "Upcoming" }.count
                
                let completedPercent = Double(completed) / Double(totalCount) * 100.0
                let inProgressPercent = Double(inProgress) / Double(totalCount) * 100.0
                let upcomingPercent = Double(upcoming) / Double(totalCount) * 100.0
                
                print("Debug - Events: Total: \(totalCount), Completed: \(completed), InProgress: \(inProgress), Upcoming: \(upcoming)")
                print("Debug - Percentages: Completed: \(completedPercent)%, InProgress: \(inProgressPercent)%, Upcoming: \(upcomingPercent)%")
                
                DispatchQueue.main.async {
                    self.eventStatus = [
                        ("Completed", completedPercent),
                        ("In Progress", inProgressPercent),
                        ("Upcoming", upcomingPercent)
                    ]
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


