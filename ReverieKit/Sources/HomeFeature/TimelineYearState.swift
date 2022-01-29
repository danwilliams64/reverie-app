import AppleMusicClient
import ComposableArchitecture
import Foundation
import ReverieKit
import SharedModels
import SwiftUI

public struct TimelineYearState: Equatable, Identifiable {
  public var timelineYear: TimelineYear
  public var trackDetails: IdentifiedArrayOf<TrackDetailState>
  public var isExpanded = false
  public var selection: Identified<TrackDetailState.ID, TrackDetailState?>?

  public var id: Double {
    timelineYear.id
  }

  public init(timelineYear: TimelineYear) {
    self.timelineYear = timelineYear
    trackDetails = IdentifiedArray(
      uniqueElements: timelineYear.items.map(TrackDetailState.init(track:))
    )
  }
}

public enum TimelineYearAction {
  case setExpanded(isExpanded: Bool)
  case setSelection(selection: TrackDetailState.ID?)
  case trackDetailAction(id: TrackDetailState.ID, action: TrackDetailAction)
}

public struct TimelineYearEnvironment {}

public let timelineYearReducer = Reducer<TimelineYearState, TimelineYearAction, TimelineYearEnvironment>.combine(
  trackDetailReducer.forEach(
    state: \.trackDetails,
    action: /TimelineYearAction.trackDetailAction(id:action:),
    environment: { _ in .init(appleMusicClient: AppleMusicClient.live) }
  ),
  .init { state, action, _ in
    switch action {
    case let .setExpanded(isExpanded):
      state.isExpanded = isExpanded
      return .none

    case let .setSelection(selection: .some(id)):
      let value = state.trackDetails[id: id]
      state.selection = Identified(value, id: id)

      return .none

    case .setSelection(selection: .none):
      state.selection = nil
      return .none

    case .trackDetailAction:
      return .none
    }
  }
)

public struct TimelineYearView: View {
  let store: Store<TimelineYearState, TimelineYearAction>
  let proxy: GeometryProxy

  let horizontalGridRows: [GridItem]

  public init(store: Store<TimelineYearState, TimelineYearAction>, proxy: GeometryProxy) {
    self.store = store
    self.proxy = proxy

    let viewStore = ViewStore(store)

    let itemCount = viewStore.timelineYear.items.count
    switch itemCount {
    case 1:
      horizontalGridRows = .init(
        repeating: .init(.flexible(minimum: 120, maximum: 180)),
        count: 1
      )
    case 2:
      horizontalGridRows = .init(
        repeating: .init(.flexible(minimum: 120, maximum: 180)),
        count: 2
      )
    default:
      horizontalGridRows = .init(
        repeating: .init(.flexible(minimum: 120, maximum: 180)),
        count: 3
      )
    }
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      Section(header: headerView) {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHGrid(rows: horizontalGridRows, alignment: .top, spacing: 5) {
            ForEachStore(
              self.store.scope(
                state: \.trackDetails,
                action: TimelineYearAction.trackDetailAction(id:action:)
              ),
              content: { detailStore in
                WithViewStore(detailStore) { detailViewStore in
                  NavigationLink(
                    tag: detailViewStore.track.id,
                    selection: viewStore.binding(
                      get: \.selection?.id,
                      send: TimelineYearAction.setSelection(selection:)
                    ), destination: { TrackDetailScreen(store: detailStore) }
                  ) {
                    TrackRow(track: detailViewStore.track)
                      .padding(.horizontal, 16)
                      .frame(
                        width: min(proxy.size.width * 0.8, 400),
                        alignment: .leading
                      )
                  }
                }
              }
            )
          }
        }
      }
    }
  }

  var headerView: some View {
    WithViewStore(store) { viewStore in
      HStack {
        VStack(alignment: .leading) {
          Text(viewStore.timelineYear.title)
            .font(.title).fontWeight(.bold)
            .foregroundColor(.primary)
          Text(viewStore.timelineYear.subtitle)
            .font(.headline)
            .foregroundColor(.secondary)
        }

        Spacer()
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(Color(uiColor: .systemFill))
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .padding(.horizontal, 12)
    }
  }
}

struct TrackRow: View {
  let track: Track

  var body: some View {
    GeometryReader { proxy in
      HStack(alignment: .center, spacing: 5) {
        // Image
        CoverArt(url: track.imageUrl)
          .frame(width: proxy.size.width * 0.3)
          .clipShape(RoundedRectangle(cornerRadius: proxy.size.width * 0.01, style: .continuous))

        // Text
        VStack(alignment: .leading) {
          Spacer()

          Text(track.name)
            .lineLimit(2)
            .foregroundColor(Color(.label))
            .font(.headline)
            .multilineTextAlignment(.leading)

          Text("\(track.artistName) – \(track.albumName)")
            .lineLimit(2)
            .foregroundColor(Color(.secondaryLabel))
            .font(.subheadline)
            .multilineTextAlignment(.leading)

          Text(track.date.formatted(date: .omitted, time: .shortened))
            .foregroundColor(Color(.secondaryLabel))
            .font(.subheadline).fontWeight(.semibold)

          Spacer()
        }
      }
    }
  }
}
