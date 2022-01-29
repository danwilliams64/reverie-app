import ApiClient
import Combine
import ComposableArchitecture
import OSLog
import SwiftDate

extension ApiClient {
  private static var startYear = 2002

  public static func live(
    apiKey: String = ProcessInfo.processInfo.environment["LASTFM_API_KEY"]!,
    baseUrl: URL = URL(string: "https://ws.audioscrobbler.com/2.0")!
  ) -> Self {
    Self(
      apiRequest: { route in
        ApiClientLive.apiRequest(apiKey: apiKey, baseUrl: baseUrl, route: route)
      },
      baseUrl: {
        baseUrl
      }
    )
  }
}

private func apiRequest(
  apiKey: String,
  baseUrl: URL,
  route: Route
) -> Effect<(data: Data, response: URLResponse), URLError> {
  Deferred { () -> Effect<(data: Data, response: URLResponse), URLError> in
    guard let request = try? route.urlRequest(apiKey: apiKey, baseUrl: baseUrl) else {
      return Effect(error: URLError(.badURL))
    }

    return URLSession.shared.dataTaskPublisher(for: request)
      .eraseToEffect()
  }
  .eraseToEffect()
}

public extension Logger {
  static let lastFmAPI = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "LastFmAPI")
}
