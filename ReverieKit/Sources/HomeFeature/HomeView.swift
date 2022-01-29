import ApiClient
import BottomSheet
import ComposableArchitecture
import ReverieKit
import SettingsFeature
import SharedModels
import SwiftDate
import SwiftUI

public struct HomeState: Equatable {
  public var date = Date()
  public var user: User
  public var timelineYears: IdentifiedArrayOf<TimelineYearState> = []
  public var isDatePickerPresented = false
  public var isLoading = false
  public var lastTimelineRefreshTime: Date?

  public var settings: SettingsState?

  public var isSettingsOpen: Bool {
    settings != nil
  }

  public var shouldRequestRecentData: Bool {
    guard let lastTimelineRefreshTime = lastTimelineRefreshTime else {
      return true
    }

    return !lastTimelineRefreshTime.isToday
  }

  public init(
    date: Date = Date(),
    user: User,
    timelineYears: IdentifiedArrayOf<TimelineYearState> = [],
    isDatePickerPresented: Bool = false,
    isLoading: Bool = false,
    lastTimelineRefreshTime: Date? = nil,
    settings: SettingsState? = nil
  ) {
    self.date = date
    self.user = user
    self.timelineYears = timelineYears
    self.isDatePickerPresented = isDatePickerPresented
    self.isLoading = isLoading
    self.lastTimelineRefreshTime = lastTimelineRefreshTime
    self.settings = settings
  }
}

public enum HomeAction {
  case clearSettings
  case dateChanged(Date)
  case fetchTimeline
  case onAppear
  case onDisappear
  case setDatePickerOpen(isOpen: Bool)
  case setSettingsOpen(isOpen: Bool)
  case settings(SettingsAction)
  case timelineLoaded(Result<[TimelineYear], ApiError>)
  case timelineYear(id: TimelineYearState.ID, action: TimelineYearAction)
}

struct HomeTearDownToken: Hashable {}

public struct HomeEnvironment {
  public var apiClient: ApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  public var userDefaultsClient: UserDefaultsClient

  public init(
    apiClient: ApiClient,
    mainQueue: AnySchedulerOf<DispatchQueue>,
    userDefaultsClient: UserDefaultsClient
  ) {
    self.apiClient = apiClient
    self.mainQueue = mainQueue
    self.userDefaultsClient = userDefaultsClient
  }
}

public let homeReducer = Reducer<HomeState, HomeAction, HomeEnvironment>.combine(
  settingsReducer
    .optional()
    .pullback(
      state: \.settings,
      action: /HomeAction.settings,
      environment: { env in
        .init(
          openUrl: { url in
            Effect.fireAndForget {
              UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
          },
          userDefaultsClient: env.userDefaultsClient
        )
      }
    ),
  timelineYearReducer.forEach(
    state: \.timelineYears,
    action: /HomeAction.timelineYear(id:action:),
    environment: { _ in TimelineYearEnvironment() }
  ),
  .init { state, action, environment in
    switch action {
    case .clearSettings:
      state.settings = nil
      return .none

    case let .dateChanged(date):
      state.date = date
      state.isDatePickerPresented = false
      return Effect(value: HomeAction.fetchTimeline)

    case .fetchTimeline:
      state.isLoading = true
      return environment.apiClient
        .timelineYears(date: state.date, username: state.user.username)
        .receive(on: environment.mainQueue.animation())
        .catchToEffect(HomeAction.timelineLoaded)

    case .onAppear:
      guard state.shouldRequestRecentData else {
        return .none
          .cancellable(id: HomeTearDownToken())
      }

      return Effect(value: HomeAction.fetchTimeline)
        .cancellable(id: HomeTearDownToken())

    case .onDisappear:
      return .cancel(id: HomeTearDownToken())

    case let .setDatePickerOpen(isOpen):
      state.isDatePickerPresented = isOpen
      return .none

    case let .setSettingsOpen(isOpen):
      state.settings = isOpen ? .init(user: state.user) : nil
      return .none

    case .settings(.removeUserTapped):
      return Effect.cancel(id: HomeTearDownToken())

    case .settings:
      return .none

    case let .timelineLoaded(.success(timeline)):
      state.isLoading = false
      state.timelineYears = IdentifiedArray(
        uniqueElements: timeline.map { TimelineYearState(timelineYear: $0) }
      )

      state.lastTimelineRefreshTime = Date()
      return .none

    case let .timelineLoaded(.failure(error)):
      state.isLoading = false
      // TODO: UI to initiate a retry of the failed load.
      return .none

    case let .timelineYear(id, action):
      return .none
    }
  }
)

public struct HomeView: View {
  let store: Store<HomeState, HomeAction>

  public init(store: Store<HomeState, HomeAction>) {
    self.store = store
    let viewStore = ViewStore(store)
    viewStore.send(.onAppear)
  }

  var dateView: some View {
    WithViewStore(store) { viewStore in
      Button(action: { viewStore.send(.setDatePickerOpen(isOpen: true)) }) {
        HStack {
          Image(sfSymbol: .calendar)
            .font(.body)
          Text("\(viewStore.date.formatted(date: .long, time: .omitted))")
            .font(.subheadline)
            .fontWeight(.medium)
          Image(sfSymbol: .chevronRight)
            .font(.caption)
        }
        .padding(8)
        .padding(.horizontal, 12)
        .background(Color.accentColor)
        .foregroundColor(.white)
        .clipShape(Capsule())
        .padding(.vertical, 12)
      }
    }
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      Group {
        switch viewStore.state.isLoading {
        case true:
          ProgressView()
        case false:
          GeometryReader { proxy in
            ScrollView {
              dateView

              ForEachStore(
                store.scope(
                  state: \.timelineYears,
                  action: HomeAction.timelineYear(id:action:)
                ),
                content: { timelineYearStore in
                  TimelineYearView(store: timelineYearStore, proxy: proxy)
                }
              )
            }
          }
        }
      }
      .navigationTitle(LocalizedStringKey("APP_NAME"))
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          NavigationLink(
            destination: IfLetStore(
              self.store.scope(state: \.settings, action: HomeAction.settings),
              then: SettingsScreen.init(store:)
            ),
            isActive: viewStore.binding(
              get: \.isSettingsOpen,
              send: HomeAction.setSettingsOpen(isOpen:)
            )
          ) {
            Image(sfSymbol: .gearshape)
              .accessibilityLabel(LocalizedStringKey("SETTINGS"))
          }
        }
      }
      .bottomSheet(
        isPresented: viewStore.binding(
          get: \.isDatePickerPresented,
          send: HomeAction.setDatePickerOpen(isOpen:)
        ),
        detents: [.medium()]
      ) {
        DateChanger(date: viewStore.binding(get: \.date, send: HomeAction.dateChanged))
      }
    }
  }
}
