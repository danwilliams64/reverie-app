import ComposableArchitecture
import ReverieKit
import SwiftUI

struct RecentUsernamesState: Equatable {
  var usernames: [String] = []
}

public enum RecentUsernamesAction: Equatable {
  case add(String)
  case onAppear
  case remove(String)
  case selected(String)
}

struct RecentUsernamesEnvironment {
  var userDefaultsClient: UserDefaultsClient
}

let recentUsernamesReducer = Reducer<RecentUsernamesState, RecentUsernamesAction, RecentUsernamesEnvironment> {
  state, action, environment in
  switch action {
  case let .add(username):
    guard !state.usernames.contains(username) else { return .none }
    state.usernames.insert(username, at: 0)
    return environment.userDefaultsClient.setRecentUsernames(state.usernames)
      .fireAndForget()

  case .onAppear:
    state.usernames = environment.userDefaultsClient.recentUsernames
    return .none

  case let .remove(username):
    state.usernames.removeAll(where: { $0 == username })
    return environment.userDefaultsClient.setRecentUsernames(state.usernames)
      .fireAndForget()

  case .selected:
    return .none
  }
}

struct RecentUsernamesView: View {
  let store: Store<RecentUsernamesState, RecentUsernamesAction>

  var body: some View {
    WithViewStore(store) { viewStore in
      if !viewStore.usernames.isEmpty {
        Text(LocalizedStringKey("ONBOARDING_RECENT_USERS"))
          .foregroundColor(.secondary)
        ForEach(viewStore.usernames, id: \.self) { username in
          HStack {
            Button(action: {
              viewStore.send(.selected(username))
            }) {
              Text(username)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.accentColor)
            }

            Button(action: { viewStore.send(.remove(username)) }) {
              Image(sfSymbol: .trash)
            }
            .foregroundColor(.secondary)
            .accessibilityLabel(LocalizedStringKey("DELETE"))
          }
          .buttonStyle(PlainButtonStyle())
        }
      } else {
        Color.clear
          .onAppear {
            viewStore.send(.onAppear)
          }
      }
    }
  }
}
