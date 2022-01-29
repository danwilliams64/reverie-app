import ApiClient
import ApiClientLive
import AppFeature
import ComposableArchitecture
import HomeFeature
import OnboardingFeature
import ReverieKit
import SharedModels
import SwiftUI

@main
struct ReverieApp: App {
  let initialAppState: AppState = {
    var state = AppState()
    let user = AppEnvironment.live.userDefaultsClient.user
    if let user = user {
      state = .timeline(HomeState(user: user))
    } else {
      state = .onboarding(.init())
    }
    return state
  }()

  var body: some Scene {
    WindowGroup {
      AppView(
        store: Store(
          initialState: initialAppState,
          reducer: appReducer,
          environment: .live
        )
      )
    }
  }
}
