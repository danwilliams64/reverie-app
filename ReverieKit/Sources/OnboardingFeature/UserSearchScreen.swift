import ApiClient
import ComposableArchitecture
import ReverieKit
import SharedModels
import SwiftUI

public struct UserSearchState: Equatable {
  public var searchQuery = ""
  public var searchResults: [User] = []
  public var searchRequestInFlight: String?

  var recentUsernamesState = RecentUsernamesState()
}

public enum UserSearchAction: Equatable {
  case recentUsernames(RecentUsernamesAction)
  case searchQueryChanged(String)
  case searchQueryDebounced(String)
  case searchResultsUpdated(Result<[User], ApiError>)
  case userSelected(User)
}

struct UserSearchTearDownToken: Hashable {}

public struct UserSearchEnvironment {
  public var apiClient: ApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  public var userDefaultsClient: UserDefaultsClient
}

public let userSearchReducer = Reducer<UserSearchState, UserSearchAction, UserSearchEnvironment>.combine(
  recentUsernamesReducer
    .pullback(
      state: \.recentUsernamesState,
      action: /UserSearchAction.recentUsernames,
      environment: { env in .init(userDefaultsClient: env.userDefaultsClient) }
    ),
  .init { state, action, environment in
    switch action {
    case let .recentUsernames(.selected(username)):
      return Effect<UserSearchAction, Never>(value: .searchQueryChanged(username))

    case let .searchQueryChanged(query):
      struct SearchQueryId: Hashable {}
      state.searchQuery = query
      state.searchResults = []

      guard !query.isEmpty else {
        state.searchResults = []
        return .cancel(id: SearchQueryId())
      }

      return Effect(value: query)
        .debounce(id: SearchQueryId(), for: 1, scheduler: environment.mainQueue)
        .map(UserSearchAction.searchQueryDebounced)

    case let .searchQueryDebounced(query):
      state.searchRequestInFlight = query

      return environment.apiClient
        .loadUserInfo(username: query)
        .receive(on: environment.mainQueue.animation())
        .map { [$0] }
        .catchToEffect(UserSearchAction.searchResultsUpdated)

    case let .searchResultsUpdated(.success(results)):
      state.searchResults = results
      state.searchRequestInFlight = nil
      return .none

    case .searchResultsUpdated(.failure):
      // TODO: Handle failure
      state.searchRequestInFlight = nil
      return .none

    case .recentUsernames:
      return .none

    case .userSelected:
      return .none
    }
  }
)

public struct UserSearchScreen: View {
  let store: Store<UserSearchState, UserSearchAction>

  public init(store: Store<UserSearchState, UserSearchAction>) {
    self.store = store
  }

  private enum Field: Int, Hashable {
    case username
  }

  @FocusState private var focusedField: Field?

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        if viewStore.searchRequestInFlight != nil {
          ProgressView().padding(.vertical)
        }
        List {
          Section {
            ForEach(viewStore.searchResults) { user in
              Button(
                action: { viewStore.send(.userSelected(user)) },
                label: {
                  SearchResult(
                    username: user.username,
                    imageUrl: user.imageUrl
                  )
                }
              )
            }
          }
        }
        .listStyle(.insetGrouped)
      }
      .searchable(
        text: viewStore.binding(
          get: \.searchQuery,
          send: UserSearchAction.searchQueryChanged
        ),
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: LocalizedStringKey("ONBOARDING_USERNAME_SEARCH_PLACEHOLDER")
      ) {
        if viewStore.searchQuery.isEmpty {
          RecentUsernamesView(
            store: store.scope(
              state: \.recentUsernamesState,
              action: UserSearchAction.recentUsernames
            )
          )
        }
      }.autocapitalization(.none)
      // Focusing too early causes the field to not become focused.
      .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(900)) {
        focusedField = .username
      }}
      .navigationTitle(LocalizedStringKey("USERNAME_PLACEHOLDER"))
    }
  }
}

struct SearchResult: View {
  let username: String
  let imageUrl: URL?

  var body: some View {
    HStack {
      AsyncImage(url: imageUrl) { image in
        image.resizable()
      } placeholder: {
        Circle()
          .background(Color(uiColor: .secondarySystemFill))
      }
      .frame(width: 64, height: 64)
      .clipShape(Circle())

      Text(username)
        .fontWeight(.medium)
    }
  }
}

struct UserSearchScreen_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      UserSearchScreen(
        store: .init(
          initialState: .init(),
          reducer: userSearchReducer,
          environment: .init(
            apiClient: .noop,
            mainQueue: .main,
            userDefaultsClient: .live()
          )
        )
      )
    }
  }
}
