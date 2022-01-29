import CasePaths
import Foundation
import MusicKit

public enum SearchResult: Equatable {
  public struct Error: Swift.Error, Equatable {
    public init() {}
  }

  case appleMusic(MusicKit.Song)
  case mock(MockSearchResult)

  public var appleMusicSong: MusicKit.Song? {
    (/SearchResult.appleMusic).extract(from: self)
  }

  public var albumName: String {
    switch self {
    case let .appleMusic(song):
      return song.albumTitle ?? ""
    case .mock:
      return "Mock Album"
    }
  }

  public var artistName: String {
    switch self {
    case let .appleMusic(song):
      return song.artistName
    case let .mock(searchResult):
      return searchResult.artistName
    }
  }

  public var coverImageUrl: URL? {
    switch self {
    case let .appleMusic(song):
      return song.artwork?.url(width: 512, height: 512)
    case let .mock(searchResult):
      return searchResult.coverImageUrl
    }
  }

  public var title: String {
    switch self {
    case let .appleMusic(song):
      return song.title
    case let .mock(searchResult):
      return searchResult.title
    }
  }
}

extension SearchResult: Identifiable {
  public var id: String {
    switch self {
    case let .appleMusic(song):
      return "\(song.id)"
    case let .mock(searchResult):
      return "\(searchResult.id)"
    }
  }
}

public struct MockSearchResult: Equatable {
  public var artistName: String
  public var coverImageUrl: URL?
  public var id: String
  public var title: String

  public init(
    artistName: String,
    coverImageUrl: URL? = nil,
    id: UUID = .init(),
    title: String
  ) {
    self.artistName = artistName
    self.coverImageUrl = coverImageUrl
    self.id = id.uuidString
    self.title = title
  }
}
