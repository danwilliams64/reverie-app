import AppleMusicClient
import ComposableArchitecture
import MusicKit
import ReverieKit
import SharedModels
import SwiftUI

public struct SettingsState: Equatable {
  public var appleMusicAuthorizationStatus: MusicAuthorization.Status?
  public var user: User

  public init(user: User) {
    self.user = user
  }
}

public enum SettingsAction {
  case appleMusicAuthorizationStatusChanged(MusicAuthorization.Status)
  case appleMusicAuthorizeTapped
  case onAppear
  case removeUserTapped
}

public struct SettingsEnvironment {
  public var appleMusicClient: AppleMusicClient
  public var openUrl: (URL) -> Effect<Never, Never>
  public var userDefaultsClient: UserDefaultsClient

  public init(
    appleMusicClient: AppleMusicClient = .live,
    openUrl: @escaping (URL) -> Effect<Never, Never>,
    userDefaultsClient: UserDefaultsClient
  ) {
    self.appleMusicClient = appleMusicClient
    self.openUrl = openUrl
    self.userDefaultsClient = userDefaultsClient
  }
}

public let settingsReducer = Reducer<SettingsState, SettingsAction, SettingsEnvironment> {
  state, action, environment in
  switch action {
  case let .appleMusicAuthorizationStatusChanged(status):
    state.appleMusicAuthorizationStatus = status
    return .none

  case .appleMusicAuthorizeTapped:
    switch state.appleMusicAuthorizationStatus {
    case .some(.denied):
      // Prompt to change in Settings
      if let url = URL(string: UIApplication.openSettingsURLString) {
        return environment.openUrl(url)
          .fireAndForget()
      }
      return .none

    case .some(.notDetermined):
      return environment.appleMusicClient.requestMusicAuthorization()
        .map(SettingsAction.appleMusicAuthorizationStatusChanged)

    default:
      return .none
    }
  case .onAppear:
    state.appleMusicAuthorizationStatus = environment.appleMusicClient.musicAuthorizationStatus
    return .none

  case .removeUserTapped:
    return .none
  }
}

struct SettingsTearDown: Hashable {}

public struct SettingsScreen: View {
  let store: Store<SettingsState, SettingsAction>

  public init(store: Store<SettingsState, SettingsAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      Form {
        Section(LocalizedStringKey("USERNAME_PLACEHOLDER")) {
          HStack {
            Text(LocalizedStringKey("SETTINGS_USERNAME_TITLE"))
            Spacer()
            Text(viewStore.user.username)
          }

          Button(action: {
            viewStore.send(.removeUserTapped)
          }, label: {
            Text(LocalizedStringKey("SETTINGS_CHANGE_USER"))
          })
        }

        Section("Music Services") {
          Button(
            action: {
              viewStore.send(.appleMusicAuthorizeTapped)
            },
            label: {
              HStack {
                Text(Image(sfSymbol: .applelogo)) + Text(" Music")
                Spacer()
                if let status = viewStore.appleMusicAuthorizationStatus {
                  if status == .authorized {
                    Text(Image(sfSymbol: .checkmarkCircleFill)) + Text(" Authorized")
                  } else {
                    Text(status.userFacingString)
                  }
                }
              }
            }
          )
        }
        .onAppear { viewStore.send(.onAppear) }
        .navigationTitle(LocalizedStringKey("SETTINGS"))
      }
    }
  }
}

struct SettigsScreen_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SettingsScreen(
        store: .init(
          initialState: .init(user: .mock),
          reducer: settingsReducer,
          environment: .init(
            appleMusicClient: .denied,
            openUrl: { url in
              Effect.fireAndForget {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
              }
            },
            userDefaultsClient: .live()
          )
        )
      )
    }
  }
}
