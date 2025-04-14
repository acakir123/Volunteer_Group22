import SwiftUI
import FirebaseFirestore
import UIKit

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
                    .font(.system(size: 28, weight: .bold))
                
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
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                                .frame(height: 10)
                            
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

class ShareCoordinator: NSObject {
    private var temporaryURLs: [URL] = []
    
    func share(data: Data, fileName: String, from viewController: UIViewController?) {
        let tempFileName = fileName
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)
        
        do {
            try data.write(to: tempURL)
            
            self.temporaryURLs.append(tempURL)
            
            let activityVC = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController?.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX,
                                           y: UIScreen.main.bounds.midY,
                                           width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            // Present directly from UIKit
            DispatchQueue.main.async {
                viewController?.present(activityVC, animated: true) {
                    activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
                        if let index = self?.temporaryURLs.firstIndex(of: tempURL) {
                            self?.temporaryURLs.remove(at: index)
                        }
                        try? FileManager.default.removeItem(at: tempURL)
                    }
                }
            }
        } catch {
            print("Error writing data to temp file: \(error.localizedDescription)")
        }
    }
}

extension UIApplication {
    static var rootViewController: UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first?.rootViewController
    }
}

struct AdminReportingView: View {
    private let db = Firestore.firestore()
    
    @State private var totalVolunteers: Int = 0
    @State private var activeEvents: Int = 0
    @State private var totalHours: Int = 0
    @State private var successRate: Int = 0
    @State private var eventStatus = [("Completed", 0.0), ("In Progress", 0.0), ("Upcoming", 0.0)]
    @State private var skillDistribution: [(String, Double)] = []
    
    @State private var volunteerHistories: [VolunteerHistoryRecord] = []
    @State private var events: [Event] = []
    @State private var isSharing: Bool = false
    @State private var shareURL: URL?
    
    @State private var volunteerNameMap: [String: String] = [:]
    
    @State private var selectedOption: String = "Export"
    
    private let shareCoordinator = ShareCoordinator()
    
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
                    
                    Menu {
                        Button("Export as PDF", action: {
                            Task {
                                await fetchReportData()
                                let pdfData = generatePDFReport(volunteerHistories: volunteerHistories, events: events)
                                DispatchQueue.main.async {
                                    shareCoordinator.share(data: pdfData, fileName: "Report.pdf", from: UIApplication.rootViewController)
                                }
                            }
                        })
                        Button("Export as CSV", action: {
                            Task {
                                await fetchReportData()
                                let csvData = generateCSVReport(volunteerHistories: volunteerHistories, events: events)
                                DispatchQueue.main.async {
                                    shareCoordinator.share(data: csvData, fileName: "Report.csv", from: UIApplication.rootViewController)
                                }
                            }
                        })
                    } label: {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .padding(12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Statistics Cards
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
                
                // Charts
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
        .sheet(isPresented: $isSharing, onDismiss: {
            if let shareURL = shareURL {
                try? FileManager.default.removeItem(at: shareURL)
                self.shareURL = nil
            }
        }) {
            if let shareURL = shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
        .onAppear {
            Task {
                fetchStatistics()
                fetchEventStatus()
                await fetchVolunteerNameMap()
                do {
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
    
    private func fetchStatistics() {
        Task {
            totalVolunteers = await fetchTotalVolunteers()
            activeEvents = await fetchActiveEventsCount()
            totalHours = await fetchTotalHoursDonated()
            successRate = await fetchSuccessRate()
        }
    }
    
    private func fetchTotalVolunteers() async -> Int {
        do {
            let snapshot = try await db.collection("users")
                .whereField("role", isEqualTo: "Volunteer")
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching total volunteers: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func fetchActiveEventsCount() async -> Int {
        do {
            let snapshot = try await db.collection("events")
                .whereField("status", isEqualTo: "Upcoming")
                .getDocuments()
            return snapshot.documents.count
        } catch {
            print("Error fetching active events: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func fetchTotalHoursDonated() async -> Int {
        do {
            let snapshot = try await db.collection("events").getDocuments()
            return snapshot.documents.reduce(0) {
                $0 + ((($1.data()["assignedVolunteers"] as? [String])?.count ?? 0) * 5)
            }
        } catch {
            print("Error fetching total hours donated: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func fetchSuccessRate() async -> Int {
        do {
            let completedSnapshot = try await db.collection("events")
                .whereField("status", isEqualTo: "Completed")
                .getDocuments()
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
                    await MainActor.run {
                        self.eventStatus = [("Completed", 0), ("In Progress", 0), ("Upcoming", 0)]
                    }
                    return
                }
                
                let completed = snapshot.documents.filter {
                    $0.data()["status"] as? String == "Completed"
                }.count
                let inProgress = snapshot.documents.filter {
                    $0.data()["status"] as? String == "In Progress"
                }.count
                let upcoming = snapshot.documents.filter {
                    $0.data()["status"] as? String == "Upcoming"
                }.count
                
                let completedPercent = Double(completed) / Double(totalCount) * 100.0
                let inProgressPercent = Double(inProgress) / Double(totalCount) * 100.0
                let upcomingPercent = Double(upcoming) / Double(totalCount) * 100.0
                
                await MainActor.run {
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
        let snapshot = try await db.collection("users")
            .whereField("role", isEqualTo: "Volunteer")
            .getDocuments()
        
        for document in snapshot.documents {
            if let skills = document.data()["skills"] as? [String] {
                for skill in skills {
                    skillsCount[skill, default: 0] += 1
                }
            }
        }
        return skillsCount
    }
    
    private func fetchReportData() async {
        do {
            let historySnapshot = try await db.collection("volunteerHistory").getDocuments()
            volunteerHistories = historySnapshot.documents.map { VolunteerHistoryRecord(document: $0) }
        } catch {
            print("Error fetching volunteer histories: \(error.localizedDescription)")
        }
        
        do {
            let eventSnapshot = try await db.collection("events").getDocuments()
            events = eventSnapshot.documents.map { Event(documentId: $0.documentID, data: $0.data()) }
        } catch {
            print("Error fetching events for report: \(error.localizedDescription)")
        }
    }
    
    private func fetchVolunteerNameMap() async {
        do {
            let snapshot = try await db.collection("users")
                .whereField("role", isEqualTo: "Volunteer")
                .getDocuments()
            var map: [String: String] = [:]
            for document in snapshot.documents {
                let fullName = document.data()["fullName"] as? String ?? "Unknown Volunteer"
                map[document.documentID] = fullName
            }
            await MainActor.run {
                self.volunteerNameMap = map
            }
        } catch {
            print("Error fetching volunteer name map: \(error.localizedDescription)")
        }
    }
    
    // Share generated data using a temporary file
    private func share(data: Data, fileName: String) {
        if shareURL != nil {
            try? FileManager.default.removeItem(at: shareURL!)
            shareURL = nil
        }
        
        let tempFileName = fileName
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(tempFileName)
        
        do {
            try data.write(to: tempURL)
            self.shareURL = tempURL
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isSharing = true
            }
        } catch {
            print("Error writing data to temporary file: \(error.localizedDescription)")
        }
    }
    
    private func generatePDFReport(volunteerHistories: [VolunteerHistoryRecord],
                                   events: [Event]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Voluntiir",
            kCGPDFContextAuthor: "Voluntiir Team",
            kCGPDFContextTitle: "Volunteer & Event Report"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let margin: CGFloat = 20
        
        var eventNameMap: [String: String] = [:]
        for event in events {
            if let id = event.documentId {
                eventNameMap[id] = event.name
            }
        }
        
        // Generate PDF using UIGraphicsPDFRenderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        var pageNumber = 1
        
        let data = renderer.pdfData { context in
            // Cover Page
            context.beginPage()
            drawCoverPage(context: context,
                          pageRect: pageRect,
                          title: "Volunteer & Event Report",
                          subtitle: "Generated on \(Date())")
            drawFooter(context: context, pageNumber: pageNumber, pageRect: pageRect)
            
            // Main Page
            context.beginPage()
            pageNumber += 1
            var yPosition = margin
            
            yPosition = drawSectionHeader("Volunteer Participation History",
                                          context: context,
                                          at: yPosition,
                                          margin: margin,
                                          pageWidth: pageWidth)
            
            let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
            for volunteer in volunteerHistories {
                if yPosition > (pageHeight - margin - 100) {
                    context.beginPage()
                    pageNumber += 1
                    yPosition = margin
                }
                
                let blockHeight: CGFloat = 70
                let blockRect = CGRect(x: margin, y: yPosition,
                                       width: pageWidth - 2 * margin,
                                       height: blockHeight)
                context.cgContext.setFillColor(UIColor.systemGray6.cgColor)
                context.cgContext.fill(blockRect)
                
                let dateString = volunteer.dateCompleted != nil
                    ? DateFormatter.localizedString(from: volunteer.dateCompleted!, dateStyle: .short, timeStyle: .short)
                    : "N/A"
                
                let eventName = eventNameMap[volunteer.eventId] ?? volunteer.eventId
                let volunteerText = """
                \(volunteer.fullName ?? "Unknown") participated in Event: \(eventName)
                on \(dateString)
                Feedback: \(volunteer.feedback)
                """
                volunteerText.draw(in: CGRect(
                    x: margin + 8,
                    y: yPosition + 8,
                    width: blockRect.width - 16,
                    height: blockRect.height - 16
                ), withAttributes: bodyAttributes)
                
                yPosition += blockHeight + 10
            }
            
            if yPosition > (pageHeight - margin - 60) {
                context.beginPage()
                pageNumber += 1
                yPosition = margin
            }
            yPosition = drawSectionHeader("Event Details", context: context,
                                          at: yPosition, margin: margin,
                                          pageWidth: pageWidth)
            
            for event in events {
                if yPosition > (pageHeight - margin - 100) {
                    context.beginPage()
                    pageNumber += 1
                    yPosition = margin
                }
                
                let blockHeight: CGFloat = 80
                let blockRect = CGRect(x: margin, y: yPosition,
                                       width: pageWidth - 2 * margin,
                                       height: blockHeight)
                context.cgContext.setFillColor(UIColor.systemGray5.cgColor)
                context.cgContext.fill(blockRect)
                
                let dateStr = DateFormatter.localizedString(from: event.date, dateStyle: .short, timeStyle: .short)

                let volunteerList = event.assignedVolunteers.map { volunteerNameMap[$0] ?? $0 }.joined(separator: ", ")
                let eventText = """
                Event: \(event.name)
                Location: \(event.location)
                Date: \(dateStr)
                Volunteers Assigned: \(volunteerList)
                """
                eventText.draw(in: CGRect(
                    x: margin + 8,
                    y: yPosition + 8,
                    width: blockRect.width - 16,
                    height: blockRect.height - 16
                ), withAttributes: bodyAttributes)
                
                yPosition += blockHeight + 10
            }
            
            drawFooter(context: context, pageNumber: pageNumber, pageRect: pageRect)
        }
        
        return data
    }
    
    // Generate a CSV report as Data
    private func generateCSVReport(volunteerHistories: [VolunteerHistoryRecord], events: [Event]) -> Data {
        var csvString = "Volunteer Participation History\n"
        csvString += "Full Name,Event Name,Date Completed,Feedback\n"
        
        var eventNameMap: [String: String] = [:]
        for event in events {
            if let id = event.documentId {
                eventNameMap[id] = event.name
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        for volunteer in volunteerHistories {
            let dateString: String = {
                if let date = volunteer.dateCompleted {
                    return formatter.string(from: date)
                }
                return "N/A"
            }()
            let eventName = eventNameMap[volunteer.eventId] ?? volunteer.eventId
            let line = "\"\(volunteer.fullName ?? "Unknown")\",\"\(eventName)\",\"\(dateString)\",\"\(volunteer.feedback)\"\n"
            csvString.append(line)
        }
        
        csvString.append("\nEvent Details\n")
        csvString.append("Event Name,Location,Date,Assigned Volunteers\n")
    
        for event in events {
            let dateString = formatter.string(from: event.date)
            let volunteerList = event.assignedVolunteers.map { volunteerNameMap[$0] ?? $0 }.joined(separator: "; ")
            let line = "\"\(event.name)\",\"\(event.location)\",\"\(dateString)\",\"\(volunteerList)\"\n"
            csvString.append(line)
        }
        
        return Data(csvString.utf8)
    }
    
    func drawCoverPage(context: UIGraphicsPDFRendererContext,
                       pageRect: CGRect,
                       title: String,
                       subtitle: String?) {
        let margin: CGFloat = 20
        var yPosition = margin + 50
        
        let titleAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 32, weight: .bold)]
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(at: CGPoint(x: (pageRect.width - titleSize.width) / 2, y: yPosition),
                   withAttributes: titleAttributes)
        
        yPosition += titleSize.height + 20
        
        if let subtitle = subtitle {
            let subAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .medium),
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ]
            let subSize = subtitle.size(withAttributes: subAttributes)
            subtitle.draw(at: CGPoint(x: (pageRect.width - subSize.width) / 2, y: yPosition),
                          withAttributes: subAttributes)
        }
    }
    
    func drawFooter(context: UIGraphicsPDFRendererContext,
                    pageNumber: Int,
                    pageRect: CGRect) {
        let footerFont = UIFont.systemFont(ofSize: 12)
        let footerText = "Page \(pageNumber)"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont
        ]
        let textSize = footerText.size(withAttributes: footerAttributes)
        let x = (pageRect.width - textSize.width) / 2
        let y = pageRect.height - textSize.height - 20
        footerText.draw(at: CGPoint(x: x, y: y), withAttributes: footerAttributes)
    }
    
    func drawSectionHeader(_ title: String,
                           context: UIGraphicsPDFRendererContext,
                           at y: CGFloat,
                           margin: CGFloat,
                           pageWidth: CGFloat) -> CGFloat {
        let headerAttributes = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18, weight: .medium)
        ]
        title.draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttributes)
        
        let lineY = y + 25
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: margin, y: lineY))
        context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: lineY))
        context.cgContext.strokePath()
        
        return lineY + 10
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue)
            .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> some UIViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}

#Preview {
    AdminReportingView()
}
