import Foundation

public struct StartEndDate {
  public var startDate: Date {
    DateComponents(
      calendar: calendar,
      timeZone: timeZone,
      year: originalDateComponents.year,
      month: originalDateComponents.month,
      day: originalDateComponents.day,
      hour: 0,
      minute: 0,
      second: 0
    ).date!
  }

  public var endDate: Date {
    DateComponents(
      calendar: calendar,
      timeZone: timeZone,
      year: originalDateComponents.year,
      month: originalDateComponents.month,
      day: originalDateComponents.day,
      hour: 23,
      minute: 59,
      second: 59
    ).date!
  }

  let calendar: Calendar
  let originalDateComponents: DateComponents
  let timeZone: TimeZone

  public init(date: Date, calendar: Calendar = .current, timeZone: TimeZone = .current) {
    self.calendar = calendar
    self.timeZone = timeZone
    originalDateComponents = calendar.dateComponents([.year, .month, .day], from: date)
  }

  /// Start date timeinterval, formatted as a String to 0 decimal places.
  public var formattedStartDateString: String {
    String(format: "%.0f", startDate.timeIntervalSince1970)
  }

  /// End date timeinterval, formatted as a String to 0 decimal places.
  public var formattedEndDateString: String {
    String(format: "%.0f", endDate.timeIntervalSince1970)
  }
}
