import ReverieKit
import SharedModels
import XCTest

final class StartEndDateTests: XCTestCase {
  func testCalculateStartEndDateForDate() throws {
    let date = Date(timeIntervalSince1970: 1_597_673_898)

    let startEndDate = StartEndDate(date: date, timeZone: TimeZone(abbreviation: "UTC")!)
    XCTAssertEqual(startEndDate.startDate.timeIntervalSince1970, 1_597_622_400)
    XCTAssertEqual(startEndDate.endDate.timeIntervalSince1970, 1_597_708_799)
  }
}
