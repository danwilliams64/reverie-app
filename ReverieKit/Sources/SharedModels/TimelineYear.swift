import Foundation
import SwiftDate

public struct TimelineYear: Equatable, Identifiable {
  public var id: Double {
    date.timeIntervalSince1970
  }

  public var date: Date
  public var items: [Track]

  public var title: String

  public var subtitle: String {
    date.toFormat("EEEE")
  }

  public init(date: Date, items: [Track]) {
    self.date = date
    title = date.toFormat("yyyy")
    self.items = items
  }
}

extension TimelineYear: Comparable {
  public static func < (lhs: TimelineYear, rhs: TimelineYear) -> Bool {
    lhs.date < rhs.date
  }

  public static func == (lhs: TimelineYear, rhs: TimelineYear) -> Bool {
    lhs.date == rhs.date
  }
}

public extension TimelineYear {
  static let mock = TimelineYear(
    date: Date(timeIntervalSince1970: 1_534_515_319),
    items: [
      .mock(date: Date(timeIntervalSince1970: 1_534_515_319)),
      .mock(date: Date(timeIntervalSince1970: 1_534_515_019)),
      .mock(date: Date(timeIntervalSince1970: 1_534_514_019)),
    ]
  )
}
