//
//  AuthViewModelIntegrationTests.swift
//  Volunteer_Group22AppTests
//
//  Created by YourName on 3/7/25.
//

import XCTest
@testable import Volunteer_Group22   // Replace with your actual module name
import Firebase

@MainActor // <-- Ensures all test methods run on the main actor
final class AuthViewModelIntegrationTests: XCTestCase {
    
    var sut: AuthViewModel!
    let testEmail = "testUser\(Int.random(in: 1000...9999))@example.com"
    let testPassword = "TestPassword123"
    var createdUserID: String?
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Ensure Firebase is configured if needed
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        sut = AuthViewModel()
    }
    
    override func tearDown() async throws {
        // Cleanup: If we created a user, delete it from Firebase
        if let userID = createdUserID {
            do {
                // Sign in as that user so we can delete
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
    
    func testSignUp() async throws {
        do {
            try await sut.signUp(withEmail: testEmail, password: testPassword, role: "testRole")
            let session = sut.userSession  // Capture in local var
            XCTAssertNotNil(session, "User session should be set after sign up")
            createdUserID = session?.uid
            print("Created test user with ID: \(createdUserID ?? "nil")")
        } catch {
            XCTFail("Sign up failed: \(error)")
        }
    }
    
    func testSignIn() async throws {
        // Must run after testSignUp, but we'll just attempt it
        do {
            try await sut.signIn(withEmail: testEmail, password: testPassword)
            let session = sut.userSession
            XCTAssertNotNil(session, "User session should not be nil after sign in")
        } catch {
            XCTFail("Sign in failed: \(error)")
        }
    }
    
    func testResetPassword() async throws {
        // Attempt to send a reset to the test user
        do {
            try await sut.resetPassword(withEmail: testEmail)
            // We can't easily verify the email was sent, but no error => success
            XCTAssertTrue(true, "No error => reset password triggered")
        } catch {
            XCTFail("Reset password threw error: \(error)")
        }
    }
    
    func testCreateEvent() async throws {
        do {
            try await sut.createEvent(
                name: "Test Event \(Int.random(in: 1000...9999))",
                description: "Integration test event",
                date: Date().addingTimeInterval(3600),  // 1 hour in the future
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
        // We'll create an event in the past, assign ourselves, then call generateVolunteerHistoryRecords
        
        // 1) signUp so we have a user
        do {
            try await sut.signUp(withEmail: testEmail, password: testPassword, role: "testRole")
        } catch {
            // ignore if it fails because user might already exist
        }
        
        // 2) create a past event
        let eventName = "Past Event \(Int.random(in: 1000...9999))"
        let docRef = sut.db.collection("events").document()
        let eventData: [String: Any] = [
            "name": eventName,
            "description": "A past event for testing",
            "dateTime": Timestamp(date: Date().addingTimeInterval(-3600)), // 1 hour in the past
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
            // If success, check volunteerHistory doc
            let volunteerHistorySnapshot = try await sut.db.collection("volunteerHistory")
                .whereField("eventId", isEqualTo: docRef.documentID)
                .whereField("volunteerId", isEqualTo: sut.userSession?.uid ?? "")
                .getDocuments()
            
            XCTAssertFalse(volunteerHistorySnapshot.isEmpty, "We expect a volunteerHistory doc to be created for a past event.")
        } catch {
            XCTFail("generateVolunteerHistoryRecords threw: \(error)")
        }
        
        // Cleanup: remove the event doc
        do {
            try await docRef.delete()
        } catch {
            print("Failed to delete test event doc: \(error)")
        }
    }
    
    func testSignOut() {
        // Just calls signOut
        sut.signOut()
        let session = sut.userSession
        XCTAssertNil(session, "After signOut, userSession should be nil")
    }
}
