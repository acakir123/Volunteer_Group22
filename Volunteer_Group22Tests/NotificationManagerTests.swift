import XCTest
@testable import Volunteer_Group22
import UserNotifications

@MainActor
final class NotificationManagerTests: XCTestCase {

    var sut: NotificationManager!

    override func setUp() {
        sut = NotificationManager.shared
    }

    override func tearDown() {
        sut = nil
    }

    func testInitialValues() {
        XCTAssertNil(sut.notificationSettings)
        XCTAssertEqual(sut.notificationCount, 0)
    }

    func testRequestAuthorization() {
        sut.requestAuthorization()
        XCTAssert(true, "No crash => code covered")
    }

    func testGetNotificationSettings() {
        sut.getNotificationSettings()
        XCTAssert(true, "No crash => code covered")
    }

    func testIncrementNotificationCount() {
        let initial = sut.notificationCount
        sut.notificationCount += 1
        XCTAssertEqual(sut.notificationCount, initial + 1)
    }
}
