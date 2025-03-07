import SwiftUI
import FirebaseFirestore

struct VolunteerHistoryRecord: Identifiable {
    let id: String
    let eventId: String
    let volunteerId: String
    var performance: [String: Any]
    var feedback: String
    let dateCompleted: Date?
    let fullName: String?
    
    
    init(document: QueryDocumentSnapshot) {
        self.id = document.documentID
        let data = document.data()
        
        self.eventId = data["eventId"] as? String ?? ""
        self.volunteerId = data["volunteerId"] as? String ?? ""
        self.performance = data["performance"] as? [String: Any] ?? [:]
        self.feedback = data["feedback"] as? String ?? ""
        self.fullName = data["fullName"] as? String ?? ""
        
        if let ts = data["dateCompleted"] as? Timestamp {
            self.dateCompleted = ts.dateValue()
        } else {
            self.dateCompleted = nil
        }
    }
}
