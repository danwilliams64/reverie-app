import ApiClient
import ComposableArchitecture
import ReverieKit
import SwiftDate
import SwiftUI

public struct OnboardingState: Equatable {
  public var userSearch: UserSearchState?

  public init(userSearch: UserSearchState? = nil) {
    self.userSearch = userSearch
  }
}

public enum OnboardingAction: Equatable {
  case getStartedButtonTapped
  case userSearch(UserSearchAction)
  case userSearchDismissed
}

public struct OnboardingEnvironment {
  public var apiClient: ApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  public var userDefaultsClient: UserDefaultsClient

  public init(apiClient: ApiClient, mainQueue: AnySchedulerOf<DispatchQueue>, userDefaultsClient: UserDefaultsClient) {
    self.apiClient = apiClient
    self.mainQueue = mainQueue
    self.userDefaultsClient = userDefaultsClient
  }
}

public let onboardingReducer = Reducer<OnboardingState, OnboardingAction, OnboardingEnvironment>.combine(
  userSearchReducer
    .optional()
    .pullback(
      state: \OnboardingState.userSearch,
      action: /OnboardingAction.userSearch,
      environment: { env in
        .init(
          apiClient: env.apiClient,
          mainQueue: env.mainQueue,
          userDefaultsClient: env.userDefaultsClient
        )
      }
    ),
  .init { state, action, _ in
    switch action {
    case .getStartedButtonTapped:
      state.userSearch = .init()
      return .none

    case .userSearch:
      return .none

    case .userSearchDismissed:
      state.userSearch = nil
      return .cancel(id: UserSearchTearDownToken())
    }
  }
)

public struct OnboardingScreen: View {
  private enum Constants {
    static let labelMaxWidth = CGFloat(256)
  }

  let store: Store<OnboardingState, OnboardingAction>

  public init(store: Store<OnboardingState, OnboardingAction>) {
    self.store = store
  }

  struct ViewState: Equatable {
    var isNavigationActive: Bool

    init(state: OnboardingState) {
      isNavigationActive = state.userSearch != nil
    }
  }

  enum ViewAction {
    case getStartedButtonTapped
    case userSearchDismissed
  }

  public var body: some View {
    WithViewStore(self.store.scope(state: ViewState.init, action: OnboardingAction.init)) { viewStore in
      ScrollView {
        VStack(spacing: 40) {
          VStack {
            Text(LocalizedStringKey("APP_NAME"))
              .foregroundColor(.accentColor)
              .font(.largeTitle)
              .fontWeight(.bold)

            Text(LocalizedStringKey("ONBOARDING_SUBTITLE"))
              .font(.title3)
              .fontWeight(.semibold)
              .multilineTextAlignment(.center)
              .frame(maxWidth: Constants.labelMaxWidth)
          }

          IntroAnimation()

          Text(LocalizedStringKey("ONBOARDING_DESCRIPTION"))
            .font(.body)
            .fontWeight(.medium)
            .multilineTextAlignment(.center)
            .frame(maxWidth: Constants.labelMaxWidth)

          NavigationLink(
            destination: IfLetStore(
              self.store.scope(state: \.userSearch, action: OnboardingAction.userSearch),
              then: UserSearchScreen.init(store:)
            ),
            isActive: viewStore.binding(
              get: \.isNavigationActive,
              send: { $0 ? .getStartedButtonTapped : .userSearchDismissed }
            )
          ) {
            Text("Get Started")
              .fontWeight(.semibold)
              .padding(.vertical)
              .frame(maxWidth: .infinity)
              .controlSize(.large)
              .keyboardShortcut(.defaultAction)
          }
          .buttonStyle(.borderedProminent)
        }
        .padding([.leading, .trailing])
      }
    }
  }
}

extension OnboardingAction {
  init(action: OnboardingScreen.ViewAction) {
    switch action {
    case .getStartedButtonTapped:
      self = .getStartedButtonTapped
    case .userSearchDismissed:
      self = .userSearchDismissed
    }
  }
}

struct IntroAnimation: View {
  struct Row: View {
    static let placeholderStrings = [
      "A slightly larger one",
      "Slightly shorter",
      "Short one",
    ]

    var body: some View {
      HStack {
        // Artwork representation
        Rectangle()
          .frame(width: 32, height: 32)
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .foregroundColor(Color(uiColor: .secondarySystemFill))

        // Title/Subtitle stack
        VStack(alignment: .leading) {
          Text(Row.placeholderStrings[Int.random(in: 0 ..< Row.placeholderStrings.count)])
            .redacted(reason: RedactionReasons.placeholder)

          Text(Row.placeholderStrings[Int.random(in: 0 ..< Row.placeholderStrings.count)])
            .redacted(reason: RedactionReasons.placeholder)
            .foregroundColor(Color(uiColor: .tertiaryLabel))
        }

        Spacer()
      }
    }
  }

  @State var show = false
  private let year = Date().year

  private static let yearCount = 3
  private static let maxTrackCount = 1

  var body: some View {
    VStack(alignment: .leading) {
      ForEach(1 ... IntroAnimation.yearCount, id: \.self) { yearIndex in

        Group {
          Text(verbatim: "\(year - yearIndex)")
            .foregroundColor(Color(uiColor: .secondaryLabel))
            .fontWeight(.bold)

          ForEach(0 ..< Int.random(in: 1 ... IntroAnimation.maxTrackCount), id: \.self) { _ in
            Row()
          }
        }
        .opacity(show ? 1 : 0)
        .offset(y: show ? 0 : -20)
        .animation(.easeOut(duration: 0.6).delay(Double(yearIndex) * 0.2), value: show)
        .onAppear(perform: {
          show = true
        })
      }
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 25)
    .background(Color(uiColor: .secondarySystemFill))
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}

struct OnboardingScreen_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      OnboardingScreen(
        store: .init(
          initialState: .init(),
          reducer: onboardingReducer,
          environment: .init(
            apiClient: .noop,
            mainQueue: .main,
            userDefaultsClient: .live()
          )
        )
      )
    }
    .preferredColorScheme(.dark)
  }
}
