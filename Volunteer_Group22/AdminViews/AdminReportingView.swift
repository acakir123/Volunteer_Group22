import SwiftUI

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
                    .background(
                        (trend >= 0 ? Color.green : Color.red)
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

struct AdminReportingView: View {
    @State private var selectedDateRange: DateRange = .lastMonth
    @State private var showingExportOptions = false
    @State private var selectedExportFormat: ExportFormat = .pdf
    
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
    
    // Sample data
    let skillDistribution = [
        ("Physical Labor", 80.0),
        ("Technical", 60.0),
        ("Customer Service", 90.0),
        ("Medical", 40.0),
        ("Teaching", 70.0)
    ]
    
    let eventStatus = [
        ("Completed", 45.0),
        ("In Progress", 30.0),
        ("Upcoming", 25.0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with export button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reports & Analytics")
                            .font(.system(size: 32, weight: .bold))
                        Text("Overview of volunteer performance")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingExportOptions = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Date range picker
                HStack {
                    Picker("Date Range", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Spacer()
                    
                    if selectedDateRange == .custom {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Select Dates")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Key statistics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatisticCard(
                        title: "Total Volunteers",
                        value: "248",
                        trend: 12.5
                    )
                    StatisticCard(
                        title: "Active Events",
                        value: "12",
                        trend: -5.0
                    )
                    StatisticCard(
                        title: "Hours Donated",
                        value: "1.2K",
                        trend: 8.3
                    )
                    StatisticCard(
                        title: "Success Rate",
                        value: "94%",
                        trend: 2.1
                    )
                }
                .padding(.horizontal)
                
                // Charts
                VStack(spacing: 24) {
                    // Event Status Distribution
                    ChartCard(
                        title: "Event Status Distribution",
                        subtitle: "Current event status breakdown"
                    ) {
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            ForEach(eventStatus, id: \.0) { status in
                                CircleProgressView(
                                    percentage: status.1,
                                    color: status.0 == "Completed" ? .green :
                                          status.0 == "In Progress" ? .blue : .orange,
                                    label: status.0
                                )
                                if status.0 != eventStatus.last?.0 {
                                    Spacer(minLength: 0)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    
                    // Skill Distribution
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
        .sheet(isPresented: $showingExportOptions) {
            NavigationView {
                List {
                    Section(header: Text("Export Format")) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button(action: { exportReport(format: format) }) {
                                HStack {
                                    Text(format.rawValue)
                                    Spacer()
                                    if format == selectedExportFormat {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Export Report")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        showingExportOptions = false
                    }
                )
            }
        }
    }
    
    private func exportReport(format: ExportFormat) {
        selectedExportFormat = format
        // Implement the actual export logic
        showingExportOptions = false
    }
}

struct AdminReportingView_Previews: PreviewProvider {
    static var previews: some View {
        
            AdminReportingView()
        
    }
}
