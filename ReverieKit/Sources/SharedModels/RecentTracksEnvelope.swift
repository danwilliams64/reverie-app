import Foundation

public struct ResponseEnvelope: Decodable {
  public struct RecentTracksEnvelope: Decodable {
    public let track: Track
  }

  public let recenttracks: RecentTracksEnvelope
}
