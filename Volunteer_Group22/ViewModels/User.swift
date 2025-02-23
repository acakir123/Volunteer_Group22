import SwiftUI

struct User: Codable {
    struct Availability: Codable {
        var startTime: String
        var endTime: String
    }
    
    struct Location: Codable {
        var address: String
        var city: String
        var country: String
        var state: String
        var zipCode: String
    }
    
    var uid: String
    var username: String
    var fullName: String
    var email: String
    var createdAt: Date
    var role: String
    var preferences: [String]
    var skills: [String]
    var location: Location
    var availability: [String: Availability]
}
