import AppleMusicClient
import ComposableArchitecture
import ReverieKit
import SharedModels
import SwiftUI

public struct TrackDetailState: Equatable, Identifiable {
  public var id: Track.ID {
    track.id
  }

  var errorMessage: String?
  var isSearching = false
  var searchResults: IdentifiedArrayOf<SearchResult>
  public var track: Track

  public init(track: Track) {
    self.track = track
    searchResults = .init()
  }
}

public enum TrackDetailAction: Equatable {
  case playButtonTapped
  case searchResultsFetched(Result<[SearchResult], SearchResult.Error>)
  case dismissErrorMessage
}

public struct TrackDetailEnvironment {
  public var appleMusicClient: AppleMusicClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>

  public init(
    appleMusicClient: AppleMusicClient,
    mainQueue: AnySchedulerOf<DispatchQueue> = .main
  ) {
    self.appleMusicClient = appleMusicClient
    self.mainQueue = mainQueue
  }
}

public let trackDetailReducer = Reducer<TrackDetailState, TrackDetailAction, TrackDetailEnvironment> {
  state, action, environment in

  struct DismissCancellable: Hashable {}

  switch action {
  case .playButtonTapped:
    state.isSearching = true

    return environment.appleMusicClient.searchRequest("\(state.track.name) \(state.track.artistName)")
      .receive(on: environment.mainQueue)
      .map { $0.map(SearchResult.appleMusic) }
      .mapError { _ in SearchResult.Error() }
      .catchToEffect()
      .map(TrackDetailAction.searchResultsFetched)
      .cancellable(id: DismissCancellable())

// Just play the first result for now...
//      .compactMap(\.first)
//      .flatMap(environment.appleMusicClient.playSong)
//      .receive(on: environment.mainQueue)
//      .fireAndForget()

  case let .searchResultsFetched(.success(searchResults)):
    state.searchResults = IdentifiedArray(uniqueElements: searchResults)
    state.isSearching = false
    return .none

  case let .searchResultsFetched(.failure(error)):
    state.errorMessage = "Error searching Apple Music catalog. Please try again later."
    state.isSearching = false

    return Effect(value: TrackDetailAction.dismissErrorMessage)
      .delay(for: .seconds(5), scheduler: environment.mainQueue.eraseToAnyScheduler())
      .eraseToEffect()
      .cancellable(id: DismissCancellable())

  case .dismissErrorMessage:
    state.errorMessage = nil
    return .cancel(id: DismissCancellable())
  }
}

public struct TrackDetailScreen: View {
  let store: Store<TrackDetailState, TrackDetailAction>

  public init(store: Store<TrackDetailState, TrackDetailAction>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store) { viewStore in
      ScrollView {
        VStack {
          CoverArt(url: viewStore.track.imageUrl)
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)

          Text(viewStore.track.name)
            .font(.title3)
            .fontWeight(.semibold)

          Text("\(viewStore.track.artistName) – \(viewStore.track.albumName)")
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          Button(action: { viewStore.send(.playButtonTapped) }, label: {
            Group {
              switch viewStore.isSearching {
              case true:
                HStack {
                  ProgressView()
                  Text(" Searching...")
                }
              case false:
                HStack(spacing: 0) {
                  Text("Play on ")
                    .fontWeight(.semibold)
                  Text(Image(sfSymbol: .applelogo))
                    .fontWeight(.semibold)
                  Text(" Music")
                    .fontWeight(.semibold)
                }
              }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
          })
          .buttonStyle(.borderedProminent)
          .disabled(viewStore.isSearching)
        }
      }
      .padding(.horizontal)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .navigationTitle(viewStore.track.name)

      // Overlay/toast to display Apple Music errors
      .overlay(
        Group {
          switch viewStore.errorMessage {
          case let .some(errorMessage):
            Button(errorMessage) {
              viewStore.send(.dismissErrorMessage, animation: .default)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.red)
            .foregroundColor(.white)
          default:
            EmptyView()
          }
        },
        alignment: .bottom
      )
    }
  }
}

struct TrackDetailScreen_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TrackDetailScreen(
        store: .init(
          initialState: .init(track: Track.mock),
          reducer: trackDetailReducer,
          environment: .init(appleMusicClient: .denied)
        )
      )
    }
  }
}
