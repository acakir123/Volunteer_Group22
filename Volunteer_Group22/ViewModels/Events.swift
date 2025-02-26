import SwiftUI
import FirebaseFirestore

// Model for events
struct Event: Identifiable {
    let id = UUID()
    var documentId: String?
    var name: String
    var description: String
    var location: String
    var requiredSkills: [String]
    var urgency: UrgencyLevel
    var date: Date
    var status: EventStatus
    var volunteerRequirements: Int
    var assignedVolunteers: [String] = []
    var createdAt: Date?
    
    enum UrgencyLevel: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    enum EventStatus: String, CaseIterable {
        case upcoming = "Upcoming"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
    
    // Initialize from Firestore document
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        
        // Location data
        let locationData = data["location"] as? [String: String] ?? [:]
        let address = locationData["address"] ?? ""
        let city = locationData["city"] ?? ""
        let state = locationData["state"] ?? ""
        let country = locationData["country"] ?? ""
        let zipCode = locationData["zipCode"] ?? ""
        
        // Formatted location string for display
        var locationComponents = [String]()
        if !address.isEmpty { locationComponents.append(address) }
        if !city.isEmpty { locationComponents.append(city) }
        if !state.isEmpty { locationComponents.append(state) }
        if !country.isEmpty { locationComponents.append(country) }
        if !zipCode.isEmpty { locationComponents.append(zipCode) }
        
        self.location = locationComponents.joined(separator: ", ")
        
        self.requiredSkills = data["requiredSkills"] as? [String] ?? []
        
        let urgencyString = data["urgency"] as? String ?? "Medium"
        self.urgency = UrgencyLevel(rawValue: urgencyString) ?? .medium
        
        self.date = (data["dateTime"] as? Timestamp)?.dateValue() ?? Date()
        
        let statusString = data["status"] as? String ?? "Upcoming"
        self.status = EventStatus(rawValue: statusString) ?? .upcoming
        
        self.volunteerRequirements = data["volunteerRequirements"] as? Int ?? 1
        self.assignedVolunteers = data["assignedVolunteers"] as? [String] ?? []
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }
    
    init(
        name: String,
        description: String,
        location: String,
        requiredSkills: [String],
        urgency: UrgencyLevel,
        date: Date,
        status: EventStatus,
        volunteerRequirements: Int,
        assignedVolunteers: [String] = []
    ) {
        self.documentId = nil
        self.name = name
        self.description = description
        self.location = location
        self.requiredSkills = requiredSkills
        self.urgency = urgency
        self.date = date
        self.status = status
        self.volunteerRequirements = volunteerRequirements
        self.assignedVolunteers = assignedVolunteers
        self.createdAt = nil
    }
}


// Event list item component
struct EventListItem: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.name)
                    .font(.headline)
                Spacer()
                StatusBadge(urgency: event.urgency)
            }
            
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.gray)
                Text(event.location)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text(event.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(event.requiredSkills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// Status badge component
struct StatusBadge: View {
    let urgency: Event.UrgencyLevel
    
    var body: some View {
        Text(urgency.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(urgency.color.opacity(0.1))
            .foregroundColor(urgency.color)
            .cornerRadius(8)
    }
}

// Form data model
struct EventFormData {
    var name: String
    var description: String
    
    var address: String
    var city: String
    var state: String
    var country: String
    var zipCode: String
    
    var requiredSkills: Set<String>
    var urgency: Event.UrgencyLevel
    var date: Date
    var status: Event.EventStatus
    var volunteerRequirements: Int
    
    // Initialize from Event model
    init(from event: Event) {
        self.name = event.name
        self.description = event.description
        
        let locationComponents = event.location.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        self.address = locationComponents.count > 0 ? String(locationComponents[0]) : ""
        self.city = locationComponents.count > 1 ? String(locationComponents[1]) : ""
        self.state = locationComponents.count > 2 ? String(locationComponents[2]) : ""
        self.country = locationComponents.count > 3 ? String(locationComponents[3]) : ""
        self.zipCode = locationComponents.count > 4 ? String(locationComponents[4]) : ""
        
        self.requiredSkills = Set(event.requiredSkills)
        self.urgency = event.urgency
        self.date = event.date
        self.status = event.status
        self.volunteerRequirements = event.volunteerRequirements
    }
    
    // Helper to get formatted location string 
    var formattedLocation: String {
        var components = [String]()
        
        if !address.isEmpty { components.append(address) }
        if !city.isEmpty { components.append(city) }
        if !state.isEmpty { components.append(state) }
        if !country.isEmpty { components.append(country) }
        if !zipCode.isEmpty { components.append(zipCode) }
        
        return components.joined(separator: ", ")
    }
}

// Form field validation
struct EventFormValidation {
    var nameError: String?
    var descriptionError: String?
    var addressError: String?
    var cityError: String?
    var stateError: String?
    var skillsError: String?
    var dateError: String?
    var volunteerRequirementsError: String?
    
    private let maxNameLength = 100
    private let minDescriptionLength = 20
    private let maxDescriptionLength = 1000
    private let maxAddressLength = 100
    private let maxCityLength = 50
    private let maxStateLength = 50
    private let maxSkillsCount = 5
    private let minVolunteers = 1
    private let maxVolunteers = 100
    
    var hasErrors: Bool {
        return nameError != nil ||
        descriptionError != nil ||
        addressError != nil ||
        cityError != nil ||
        stateError != nil ||
        skillsError != nil ||
        dateError != nil ||
        volunteerRequirementsError != nil
    }
    
    mutating func validate(event: EventFormData) {
        // Name validation
        if event.name.isEmpty {
            nameError = "Event name is required"
        } else if event.name.count > maxNameLength {
            nameError = "Event name must be less than \(maxNameLength) characters"
        } else {
            nameError = nil
        }
        
        // Description validation
        if event.description.isEmpty {
            descriptionError = "Event description is required"
        } else if event.description.count < minDescriptionLength {
            descriptionError = "Description must be at least \(minDescriptionLength) characters"
        } else if event.description.count > maxDescriptionLength {
            descriptionError = "Description must be less than \(maxDescriptionLength) characters"
        } else {
            descriptionError = nil
        }
        
        // Address validation
        if event.address.isEmpty {
            addressError = "Street address is required"
        } else if event.address.count > maxAddressLength {
            addressError = "Address must be less than \(maxAddressLength) characters"
        } else {
            addressError = nil
        }
        
        // City validation
        if event.city.isEmpty {
            cityError = "City is required"
        } else if event.city.count > maxCityLength {
            cityError = "City must be less than \(maxCityLength) characters"
        } else {
            cityError = nil
        }
        
        // State validation
        if event.state.isEmpty {
            stateError = "State/Province is required"
        } else if event.state.count > maxStateLength {
            stateError = "State must be less than \(maxStateLength) characters"
        } else {
            stateError = nil
        }
        
        // Skills validation
        if event.requiredSkills.isEmpty {
            skillsError = "At least one skill is required"
        } else if event.requiredSkills.count > maxSkillsCount {
            skillsError = "Maximum of \(maxSkillsCount) skills allowed"
        } else {
            skillsError = nil
        }
        
        // Date validation
        let calendar = Calendar.current
        if event.date < calendar.startOfDay(for: Date()) {
            dateError = "Event date must be in the future"
        } else {
            dateError = nil
        }
        
        // Volunteer requirements validation
        if event.volunteerRequirements < minVolunteers {
            volunteerRequirementsError = "At least \(minVolunteers) volunteer is required"
        } else if event.volunteerRequirements > maxVolunteers {
            volunteerRequirementsError = "Maximum of \(maxVolunteers) volunteers allowed"
        } else {
            volunteerRequirementsError = nil
        }
    }
}
