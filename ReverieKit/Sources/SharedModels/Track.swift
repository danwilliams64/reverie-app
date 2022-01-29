import Foundation

public struct Track: Decodable, Identifiable, Equatable {
  public var id: String {
    // Last.fm sometimes returns a 'mbid', but since this isn't always available, use the timestamp and hope it's
    // unique enough along with the name.
    "\(date.timeIntervalSince1970)" + name
  }

  public let name: String
  public let imageUrl: URL?
  public let artistName: String
  public let albumName: String
  public let date: Date

  internal init(
    name: String,
    imageUrl: URL?,
    artistName: String,
    albumName: String,
    date: Date
  ) {
    self.name = name
    self.imageUrl = imageUrl
    self.artistName = artistName
    self.albumName = albumName
    self.date = date
  }
}

extension Track {
  private enum CodingKeys: String, CodingKey {
    case artist, album, image, date, name, mbid
  }

  private enum NestedTextCodingKeys: String, CodingKey {
    case text = "#text"
  }

  private enum DateCodingKeys: String, CodingKey {
    case uts
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    name = try container.decode(String.self, forKey: .name)

    let artistContainer = try container.nestedContainer(
      keyedBy: NestedTextCodingKeys.self,
      forKey: .artist
    )
    artistName = try artistContainer.decodeIfPresent(String.self, forKey: .text) ?? "Unknown Artist"

    let albumContiner = try container.nestedContainer(
      keyedBy: NestedTextCodingKeys.self,
      forKey: .album
    )
    albumName = try albumContiner.decodeIfPresent(String.self, forKey: .text) ?? "Unknown Album"

    let images = try container.decodeIfPresent([Image].self, forKey: .image)
    // Last.fm returns an array of various image sizes. Use the last one for the largest possible size.
    imageUrl = images?.last?.url

    // Last.fm stores the timestamp as a String... unless the user is currently playing a track.
    // If we don't find a date, we're probably dealing with a 'nowplaying' track which is helpfully attached to all
    // API responses.
    let dateContainer = try container.nestedContainer(keyedBy: DateCodingKeys.self, forKey: .date)
    let timestampString = try dateContainer.decode(String.self, forKey: .uts)

    let timestamp = Double(timestampString) ?? 0
    date = Date(timeIntervalSince1970: timestamp)
  }
}

// MARK: - Mock

public extension Track {
  static func mock(date: Date) -> Track {
    Track(
      name: "Are You In?",
      imageUrl: URL(
        string: "https://lastfm.freetls.fastly.net/i/u/300x300/71c45e62e5624d32cdbc3063dad0d2ed.png"
      )!,
      artistName: "Incubus",
      albumName: "Morning View",
      date: date
    )
  }

  static var mock: Track {
    Track(
      name: "Are You In?",
      imageUrl: URL(
        string: "https://lastfm.freetls.fastly.net/i/u/300x300/71c45e62e5624d32cdbc3063dad0d2ed.png"
      )!,
      artistName: "Incubus",
      albumName: "Morning View",
      date: Date(timeIntervalSince1970: 1_534_515_319)
    )
  }
}
