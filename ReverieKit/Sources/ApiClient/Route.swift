import Foundation
import SharedModels

public enum Route {
  case recentTracks(dates: StartEndDate, username: String)
  case userGetInfo(username: String)

  /// The Last.fm API method name
  private var method: String {
    switch self {
    case .recentTracks:
      return "user.getRecentTracks"
    case .userGetInfo:
      return "user.getInfo"
    }
  }

  private var additionalQueryItems: [URLQueryItem] {
    switch self {
    case let .recentTracks(dates, username):
      return [
        URLQueryItem(name: "from", value: dates.formattedStartDateString),
        URLQueryItem(name: "to", value: dates.formattedEndDateString),
        URLQueryItem(name: "user", value: username),
      ]

    case let .userGetInfo(username):
      return [
        URLQueryItem(name: "user", value: username),
      ]
    }
  }

  public func urlRequest(
    apiKey: String,
    baseUrl: URL
  ) throws -> URLRequest {
    let commonQueryItems: [URLQueryItem] = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "format", value: "json"),
      URLQueryItem(name: "method", value: method),
    ]

    let queryItems = [commonQueryItems, additionalQueryItems].flatMap { $0 }

    guard
      let components = URLComponents(baseUrl: baseUrl, queryItems: queryItems),
      let url = components.url
    else {
      throw URLError(.badURL)
    }

    return URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
  }
}

private extension URLComponents {
  init?(baseUrl: URL, queryItems: [URLQueryItem]) {
    self.init(url: baseUrl, resolvingAgainstBaseURL: true)
    self.queryItems = queryItems
  }
}
