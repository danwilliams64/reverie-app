import Combine
import ComposableArchitecture
import SharedModels
import SwiftDate

public struct ApiClient {
  public var apiRequest: (Route) -> Effect<(data: Data, response: URLResponse), URLError>
  public var baseUrl: () -> URL
//  public var recentTracks: (String, Date) -> Effect<[Track], URLError>
//  public var timeline: (String, Date) -> Effect<[TimelineYear], Never>
//  public var userInfo: (String) -> Effect<User, URLError>

  public init(
    apiRequest: @escaping (Route) -> Effect<(data: Data, response: URLResponse), URLError>,
    baseUrl: @escaping () -> URL
//    recentTracks: @escaping (String, Date) -> Effect<[Track], URLError>,
//    timeline: @escaping (String, Date) -> Effect<[TimelineYear], Never>,
//    userInfo: @escaping (String) -> Effect<User, URLError>
  ) {
    self.apiRequest = apiRequest
    self.baseUrl = baseUrl
//    self.recentTracks = recentTracks
//    self.timeline = timeline
//    self.userInfo = userInfo
  }
}

public extension ApiClient {
  static let failing = Self(
    apiRequest: { _ in
      .failing("\(Self.self).apiRequest is unimplemented")
    },
    baseUrl: {
      print("\(Self.self).baseUrl is unimplemented")
      return URL(string: "/")!
    }
//    recentTracks: { _, _ in .failing("\(Self.self).recentTracks is unimplemented") },
//    timeline: { _, _ in .failing("\(Self.self).timeline is unimplemented") },
//    userInfo: { _ in .failing("\(Self.self).userInfo is unimplmented")}
  )
}

public extension ApiClient {
  static let noop = Self(
    apiRequest: { _ in .none },
    baseUrl: { URL(string: "/")! }
//    recentTracks: { _, _ in .none },
//    timeline: { _, _ in .none },
//    userInfo: { _ in .none }
  )
}

let jsonDecoder = JSONDecoder()

/// User

extension ApiClient {
  private struct UserInfoEnvelope: Decodable {
    let user: User
  }

  public func loadUserInfo(username: String) -> Effect<User, ApiError> {
    apiRequest(Route.userGetInfo(username: username))
      .map { data, _ in data }
      .apiDecode(as: UserInfoEnvelope.self)
      .map(\.user)
      .eraseToEffect()
  }
}

public extension ApiClient {
  private struct ResponseWrapper: Decodable {
    struct RecentTracksWrapper: Decodable {
      let track: [Result<Track, DecodingError>]
    }

    let recenttracks: RecentTracksWrapper
  }

  func recentTracks(date: Date, username: String) -> Effect<[Track], ApiError> {
    let dates = StartEndDate(date: date)
    return apiRequest(.recentTracks(dates: dates, username: username))
      .map { data, _ in data }
      .apiDecode(as: ResponseWrapper.self)
      .map(\.recenttracks)
      .map(\.track)
      .map { $0.compactMap { try? $0.get() } }
      .eraseToEffect()
  }

  func timelineYears(
    date: Date,
    startYear: Int = 2002,
    username: String
  ) -> Effect<[TimelineYear], ApiError> {
    let years = date.year - startYear
    let dates = (1 ... years).map { date - $0.years }

    let publishers = dates.map {
      recentTracks(date: $0, username: username)
        .eraseToAnyPublisher()
    }

    let merged = Publishers.MergeMany(publishers)
      .collect()
      .map { results in
        Array(
          results.compactMap { tracks -> TimelineYear? in
            guard !tracks.isEmpty else { return nil }
            return TimelineYear(
              date: tracks.first!.date,
              items: tracks.sorted(by: { $0.date < $1.date })
            )
          }
          .sorted()
          .reversed()
        )
      }
      .eraseToAnyPublisher()

    return merged.eraseToEffect()
  }
}
