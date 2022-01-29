import AppleMusicClient
import Combine
import ComposableArchitecture
import Foundation
import MusicKit
import ReverieKit
import SharedModels
import SwiftUI

struct TrackSearchResultsState: Equatable {
  var searchResults: [SearchResult] = []
  var term: String
}

enum TrackSearchResultsAction: Equatable {
  case onAppear
}

struct TrackSearchResultsEnvironment {
  var appleMusicClient: AppleMusicClient
}

let trackSearchResultsReducer = Reducer<
  TrackSearchResultsState,
  TrackSearchResultsAction,
  TrackSearchResultsEnvironment
> { _, action, _ in
  switch action {
  case .onAppear:
    return .none
  }
}

struct TrackSearchResultsScreen: View {
  let store: Store<TrackSearchResultsState, TrackSearchResultsAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      List {
        ForEach(viewStore.searchResults) { searchResult in
          HStack {
            HStack {
              // Image
              CoverArt(url: searchResult.coverImageUrl)
                .frame(width: 120)

              // Text
              VStack(alignment: .leading) {
                Text(searchResult.title)
                  .lineLimit(2)
                  .foregroundColor(Color(.label))
                  .font(.headline)

                Text("\(searchResult.artistName) – \(searchResult.albumName)")
                  .lineLimit(2)
                  .foregroundColor(Color(.secondaryLabel))
                  .font(.subheadline)
              }
              .padding(8)
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
      }
      .navigationTitle(LocalizedStringKey("SEARCH_TITLE"))
    }
  }
}

struct TrackSearchResultsScreen_Previews: PreviewProvider {
  static var previews: some View {
    TrackSearchResultsScreen(
      store: Store<TrackSearchResultsState, TrackSearchResultsAction>.init(
        initialState: .init(
          searchResults: [
            .mock(
              .init(
                artistName: "Public Service Broadcasting",
                coverImageUrl: URL(
                  string: "https://guitar.com/wp-content/uploads/2021/09/Public-Service-Broadcasting-Bright-Magic@1400x1400.jpg"
                ),
                title: "Der Rhythmus der Maschinen"
              )
            ),
            .mock(
              .init(
                artistName: "Public Service Broadcasting",
                coverImageUrl: URL(
                  string: "https://guitar.com/wp-content/uploads/2021/09/Public-Service-Broadcasting-Bright-Magic@1400x1400.jpg"
                ),
                title: "People, Let's Dance"
              )
            ),
          ],
          term: "public service"
        ),
        reducer: trackSearchResultsReducer,
        environment: .init(appleMusicClient: .noop)
      )
    )
  }
}
