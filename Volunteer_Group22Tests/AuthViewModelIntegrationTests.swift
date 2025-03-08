import XCTest
@testable import Volunteer_Group22
import Firebase

@MainActor
final class AuthViewModelIntegrationTests: XCTestCase {
    
    var sut: AuthViewModel!
    let testEmail = "testUser\(Int.random(in: 1000...9999))@example.com"
    let testPassword = "TestPassword123"
    var createdUserID: String?
    
    let useTestCollections = true
    
    override func setUp() async throws {
        try await super.setUp()
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        sut = AuthViewModel(isTestMode: useTestCollections)
    }
    
    override func tearDown() async throws {
        if let userID = createdUserID {
            do {
                let result = try await Auth.auth().signIn(withEmail: testEmail, password: testPassword)
                try await result.user.delete()
                print("Deleted test user: \(userID)")
            } catch {
                print("Failed to delete test user: \(error)")
            }
        }
        
        sut = nil
        try await super.tearDown()
    }
    
    // Helper to create an event doc
    private func createTestEvent(name: String) async throws -> String {
        let eventsCollection = useTestCollections
            ? sut.db.collection("testEvents")
            : sut.db.collection("events")
        
        let docRef = eventsCollection.document()
        let eventData: [String: Any] = [
            "name": name,
            "description": "Integration test event",
            "dateTime": Timestamp(date: Date()),
            "location": ["address": "Test Address"],
            "requiredSkills": [],
            "urgency": "Medium",
            "volunteerRequirements": 1,
            "assignedVolunteers": [],
            "status": "Upcoming",
            "createdAt": Timestamp(date: Date())
        ]
        try await docRef.setData(eventData)
        return docRef.documentID
    }
    
    
    func testSignUpThenSignIn() async throws {
        try await sut.signUp(withEmail: testEmail, password: testPassword, role: "testRole")
        XCTAssertNotNil(sut.userSession, "User session should be set after sign up")
        createdUserID = sut.userSession?.uid
        
        // Sign out
        sut.signOut()
        XCTAssertNil(sut.userSession)
        
        // Sign in
        try await sut.signIn(withEmail: testEmail, password: testPassword)
        XCTAssertNotNil(sut.userSession, "User session should not be nil after sign in")
    }
    
    func testResetPassword() async throws {
        do {
            try await sut.resetPassword(withEmail: testEmail)
            XCTAssertTrue(true, "No error => reset password triggered")
        } catch {
            XCTFail("resetPassword threw: \(error)")
        }
    }
    
    func testCreateEvent() async throws {
        do {
            try await sut.createEvent(
                name: "Test Event \(Int.random(in: 1000...9999))",
                description: "Integration test event",
                date: Date().addingTimeInterval(3600),
                address: "123 Test Street",
                city: "TestCity",
                state: "TS",
                country: "TestLand",
                zipCode: "99999",
                requiredSkills: ["Testing"],
                urgency: .medium,
                volunteerRequirements: 5
            )
            XCTAssertTrue(true, "Created event without error")
        } catch {
            XCTFail("createEvent failed: \(error)")
        }
    }
    
    func testGenerateVolunteerHistoryRecords() async throws {
        // 1) sign up
        do {
            try await sut.signUp(withEmail: testEmail, password: testPassword, role: "testRole")
            createdUserID = sut.userSession?.uid
        } catch {
            // if it fails, maybe user already exists
        }
        
        // 2) create a past event
        let eventsColl = useTestCollections ? sut.db.collection("testEvents") : sut.db.collection("events")
        let docRef = eventsColl.document()
        
        let eventData: [String: Any] = [
            "name": "Past Event \(Int.random(in: 1000...9999))",
            "description": "A past event for testing",
            "dateTime": Timestamp(date: Date().addingTimeInterval(-3600)),
            "location": ["address": "Test Past Address"],
            "requiredSkills": [],
            "urgency": "Medium",
            "volunteerRequirements": 1,
            "assignedVolunteers": [sut.userSession?.uid ?? ""],
            "status": "Upcoming",
            "createdAt": Timestamp(date: Date())
        ]
        try await docRef.setData(eventData)
        
        // 3) call generateVolunteerHistoryRecords
        do {
            try await sut.generateVolunteerHistoryRecords()
            
            let volunteerHistColl = useTestCollections
                ? sut.db.collection("testVolunteerHistory")
                : sut.db.collection("volunteerHistory")
            
            let snap = try await volunteerHistColl
                .whereField("eventId", isEqualTo: docRef.documentID)
                .whereField("volunteerId", isEqualTo: sut.userSession?.uid ?? "")
                .getDocuments()
            
            XCTAssertFalse(snap.isEmpty, "Expected volunteerHistory doc to be created for a past event.")
        } catch {
            XCTFail("generateVolunteerHistoryRecords threw: \(error)")
        }
        
        // cleanup
        try? await docRef.delete()
    }
    
    func testSignOut() {
        sut.signOut()
        XCTAssertNil(sut.userSession, "After signOut, userSession should be nil")
    }
    
    // Additional tests for coverage
    
    func testUpdateAndDeleteEvent() async throws {
        let eventId = try await createTestEvent(name: "UpdateDeleteTest")
        
        do {
            try await sut.updateEvent(
                eventId: eventId,
                name: "Updated Name",
                description: "Updated Desc",
                date: Date().addingTimeInterval(7200),
                address: "New Address",
                city: "NewCity",
                state: "NC",
                country: "TestLand",
                zipCode: "88888",
                requiredSkills: ["Swift"],
                urgency: .high,
                volunteerRequirements: 10,
                status: .inProgress
            )
            XCTAssertTrue(true, "updateEvent succeeded")
        } catch {
            XCTFail("updateEvent failed: \(error)")
        }
        
        do {
            try await sut.deleteEvent(eventId: eventId)
            let eventsColl = useTestCollections ? sut.db.collection("testEvents") : sut.db.collection("events")
            let doc = try await eventsColl.document(eventId).getDocument()
            XCTAssertFalse(doc.exists, "Event doc should not exist after deletion")
        } catch {
            XCTFail("deleteEvent failed: \(error)")
        }
    }
    
    func testFetchEventsAndFilteredEvents() async throws {
        let eventId1 = try await createTestEvent(name: "FilterTest1")
        let eventId2 = try await createTestEvent(name: "FilterTest2")
        
        do {
            let allEvents = try await sut.fetchEvents(db: sut.db)
            XCTAssertGreaterThanOrEqual(allEvents.count, 2, "Should have at least 2 events now")
        } catch {
            XCTFail("fetchEvents failed: \(error)")
        }
        
        do {
            let filtered = try await sut.fetchFilteredEvents(db: sut.db, status: nil, searchText: "FilterTest1")
            XCTAssertTrue(filtered.contains { $0.name.contains("FilterTest1") }, "Should find event with 'FilterTest1' in the name")
        } catch {
            XCTFail("fetchFilteredEvents threw: \(error)")
        }
        
        let eventsColl = useTestCollections ? sut.db.collection("testEvents") : sut.db.collection("events")
        try? await eventsColl.document(eventId1).delete()
        try? await eventsColl.document(eventId2).delete()
    }
    
    func testSignUpForEvent() async throws {
        // 1) sign up user
        do {
            try await sut.signUp(withEmail: testEmail, password: testPassword, role: "testRole")
            createdUserID = sut.userSession?.uid
        } catch {
            // ignore if user already exists
        }
        
        // fetchUser so that `user` is set
        await sut.fetchUser()
        
        // 2) create an event
        let eventId = try await createTestEvent(name: "SignUpEventTest")
        let event = Event(documentId: eventId, data: [
            "name": "SignUpEventTest",
            "dateTime": Timestamp(date: Date()),
            "location": ["address": "Test Address"],
            "requiredSkills": [],
            "urgency": "Medium",
            "volunteerRequirements": 1,
            "assignedVolunteers": [],
            "status": "Upcoming",
            "createdAt": Timestamp(date: Date())
        ])
        
        // 3) call signUp(for:)
        do {
            try await sut.signUp(for: event)
            
            // 4) verify assignedVolunteers
            let eventsColl = useTestCollections ? sut.db.collection("testEvents") : sut.db.collection("events")
            let doc = try await eventsColl.document(eventId).getDocument()
            if let assigned = doc.data()?["assignedVolunteers"] as? [String] {
                XCTAssertTrue(assigned.contains(sut.userSession?.uid ?? ""), "User should be in assignedVolunteers")
            } else {
                XCTFail("No assignedVolunteers array found")
            }
        } catch {
            XCTFail("signUp(for:) threw: \(error)")
        }
        
        // Cleanup
        let eventsColl = useTestCollections ? sut.db.collection("testEvents") : sut.db.collection("events")
        try? await eventsColl.document(eventId).delete()
    }
}
