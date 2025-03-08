import XCTest
@testable import Volunteer_Group22
import UserNotifications

@MainActor
final class NotificationManagerTests: XCTestCase {

    var sut: NotificationManager!

    override func setUp() {
        super.setUp()
        sut = NotificationManager.shared
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testRequestAuthorizationWait() {
        let exp = expectation(description: "Authorization callback")
        
        sut.requestAuthorization()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error, "Wait timed out")
        }
    }

    func testGetNotificationSettingsWait() {
        let exp = expectation(description: "Settings callback")
        
        sut.getNotificationSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }
    
    func testIncrementNotificationCount() {
        let initial = sut.notificationCount
        sut.notificationCount += 1
        XCTAssertEqual(sut.notificationCount, initial + 1, "Should increment count by 1")
    }
    
    func testInitialValuesWithNewInstance() {
        let manager = NotificationManager()
        XCTAssertEqual(manager.notificationCount, 0, "Should start at 0 unless incremented")
    }
}
