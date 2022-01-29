import ComposableArchitecture
import ReverieKit
import XCTest

@testable import OnboardingFeature

class RecentUsernamesFeatureTests: XCTestCase {
  var userDefaults: UserDefaults!

  override func setUp() {
    let suiteName = "RecentUsernamesFeatureTests"
    UserDefaults().removePersistentDomain(forName: suiteName)
    userDefaults = UserDefaults(suiteName: suiteName)
  }

  func testRecentUsernamesFlow() {
    let store = TestStore(
      initialState: RecentUsernamesState(),
      reducer: recentUsernamesReducer,
      environment: RecentUsernamesEnvironment(
        userDefaultsClient: UserDefaultsClient.live(userDefaults: userDefaults)
      )
    )

    store.send(.onAppear) {
      $0.usernames = []
    }

    store.send(.add("testUser1")) {
      $0.usernames = [
        "testUser1",
      ]
    }

    store.send(.add("testUser1")) {
      $0.usernames = [
        "testUser1",
      ]
    }

    store.send(.add("testUser2")) {
      $0.usernames = [
        "testUser2",
        "testUser1",
      ]
    }

    store.send(.remove("nonExistentUser")) {
      $0.usernames = [
        "testUser2",
        "testUser1",
      ]
    }

    store.send(.remove("testUser2")) {
      $0.usernames = [
        "testUser1",
      ]
    }
  }
}
