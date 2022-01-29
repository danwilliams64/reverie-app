import Combine
import ComposableArchitecture
import MusicKit
import UIKit

public extension MusicAuthorization.Status {
  var userFacingString: String {
    switch self {
    case .denied:
      return "Denied"
    case .notDetermined:
      return "Not Determined"
    case .restricted:
      return "Restricted"
    case .authorized:
      return "Authorized"
    @unknown default:
      return ""
    }
  }
}

public struct AppleMusicClient {
  public var musicAuthorizationStatus: MusicAuthorization.Status
  public var playSong: (MusicKit.Song) -> Effect<Void, Never>
  public var requestMusicAuthorization: () -> Effect<MusicAuthorization.Status, Never>
  public var searchRequest: (String) -> Effect<MusicItemCollection<Song>, Error>

  public init(
    musicAuthorizationStatus: MusicAuthorization.Status,
    playSong: @escaping (MusicKit.Song) -> Effect<Void, Never>,
    requestMusicAuthorization: @escaping () -> Effect<MusicAuthorization.Status, Never>,
    searchRequest: @escaping (String) -> Effect<MusicItemCollection<Song>, Error>
  ) {
    self.musicAuthorizationStatus = musicAuthorizationStatus
    self.playSong = playSong
    self.requestMusicAuthorization = requestMusicAuthorization
    self.searchRequest = searchRequest
  }
}

public extension AppleMusicClient {
  static let denied = Self(
    musicAuthorizationStatus: .denied,
    playSong: { _ in .none },
    requestMusicAuthorization: { .none },
    searchRequest: { _ in .none }
  )

  static let noop = Self(
    musicAuthorizationStatus: .authorized,
    playSong: { _ in .none },
    requestMusicAuthorization: { .none },
    searchRequest: { _ in .none }
  )
}

public extension AppleMusicClient {
  static let live = Self(
    musicAuthorizationStatus: MusicKit.MusicAuthorization.currentStatus,
    playSong: { song in
      .task {
        let player = SystemMusicPlayer.shared
        player.queue = SystemMusicPlayer.Queue(for: [song], startingAt: song)
        do {
          try await player.play()
        } catch {
          print("Failed to prepare to play with error: ", error)
        }
      }
    },
    requestMusicAuthorization: {
      Effect<MusicAuthorization.Status, Never>.task {
        switch MusicAuthorization.currentStatus {
        case .notDetermined:
          return await MusicAuthorization.request()
        case .denied:
          if let settingsUrl = await URL(string: UIApplication.openSettingsURLString) {
            fatalError("Unimplemented")
          }
          // TODO: Tell user to go to settings and turn it back on.
          fatalError("Unimplemented")
        default:
          fatalError(
            "Shouldn't be able to request authorization for current status: \(MusicAuthorization.currentStatus)"
          )
        }
      }
    },
    searchRequest: { term in
      Effect<MusicItemCollection<Song>, Error>.task {
        let request = MusicCatalogSearchRequest(term: term, types: [Song.self])
        let response = try await request.response()
        return response.songs
      }
    }
  )
}
