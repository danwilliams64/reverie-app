import ApiClient
import ApiClientLive
import ComposableArchitecture
import HomeFeature
import OnboardingFeature
import ReverieKit
import SwiftUI

public enum AppState: Equatable {
  case onboarding(OnboardingState)
  case timeline(HomeState)

  public init() {
    self = .onboarding(.init())
  }
}

public enum AppAction {
  case onboarding(OnboardingAction)
  case timeline(HomeAction)
}

public struct AppEnvironment {
  public var apiClient: ApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  public var userDefaultsClient: UserDefaultsClient
}

public let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  onboardingReducer.pullback(
    state: /AppState.onboarding,
    action: /AppAction.onboarding,
    environment: { env in
      OnboardingEnvironment(
        apiClient: env.apiClient,
        mainQueue: env.mainQueue,
        userDefaultsClient: env.userDefaultsClient
      )
    }
  ),
  homeReducer.pullback(
    state: /AppState.timeline,
    action: /AppAction.timeline,
    environment: { env in
      .init(
        apiClient: env.apiClient,
        mainQueue: env.mainQueue,
        userDefaultsClient: env.userDefaultsClient
      )
    }
  ),
  Reducer { state, action, environment in
    switch action {
    case let .onboarding(.userSearch(.userSelected(user))):
      state = .timeline(.init(user: user))
      return environment.userDefaultsClient.setUser(user)
        .fireAndForget()

    case .timeline(.settings(.removeUserTapped)):
      state = .onboarding(.init())
      return environment.userDefaultsClient.remove(userKey)
        .fireAndForget()

    default:
      return .none
    }
  }
)
.debug()

public struct AppView: View {
  let store: Store<AppState, AppAction>

  public init(store: Store<AppState, AppAction>) {
    self.store = store
  }

  public var body: some View {
    SwitchStore(self.store) {
      CaseLet(state: /AppState.onboarding, action: AppAction.onboarding) { onboardingStore in
        NavigationView {
          OnboardingScreen(store: onboardingStore)
        }
        .navigationViewStyle(.stack)
      }

      CaseLet(state: /AppState.timeline, action: AppAction.timeline) { timelineStore in
        NavigationView {
          HomeView(store: timelineStore)
        }
        .navigationViewStyle(.stack)
      }
    }
  }
}

public extension AppEnvironment {
  static var live: Self {
    Self(
      apiClient: .live(),
      mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
      userDefaultsClient: .live()
    )
  }
}
