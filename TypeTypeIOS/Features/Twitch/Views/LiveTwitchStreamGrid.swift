import SwiftUI

struct LiveTwitchStreamGrid: View {
  @ObservedObject var list: LiveTwitchPagedList<LiveTwitchStream>
  let empty: LocalizedStringKey
  let identifier: String
  @Environment(\.liveTwitchPlay) private var play

  var body: some View {
    LiveTwitchPagedContent(list: list, empty: empty, identifier: identifier) { items in
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16, alignment: .top)], spacing: 22) {
        ForEach(items) { stream in
          Button { play(LiveTwitchPlayback.item(live: stream)) } label: {
            LiveTwitchStreamCard(stream: stream)
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

struct LiveTwitchPagedContent<Item: Identifiable & Decodable, Content: View>: View where Item.ID: Hashable {
  @ObservedObject var list: LiveTwitchPagedList<Item>
  let empty: LocalizedStringKey
  let identifier: String
  @ViewBuilder let content: ([Item]) -> Content

  var body: some View {
    switch list.state {
    case .idle, .loading:
      ProgressView()
        .frame(maxWidth: .infinity, minHeight: 120)
    case let .failed(message):
      LiveTwitchMessage(text: Text(message), systemImage: "exclamationmark.triangle") {
        Task { await list.reload() }
      }
    case .loaded:
      if list.items.isEmpty {
        LiveTwitchMessage(text: Text(empty), systemImage: "dot.radiowaves.left.and.right", retry: nil)
      } else {
        VStack(spacing: 12) {
          content(list.items)
          LiveIncrementalLoadingTrigger(
            canLoadMore: list.canLoadMore && !list.moreFailed,
            isLoading: list.isLoadingMore,
            label: "Loading more",
            identifier: identifier
          ) {
            Task { await list.loadMore() }
          }
          if list.moreFailed {
            Button("Try again") { Task { await list.loadMore() } }
              .font(.subheadline)
          }
        }
      }
    }
  }
}

struct LiveTwitchMessage: View {
  let text: Text
  let systemImage: String
  let retry: (() -> Void)?

  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.title2)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      text
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      if let retry {
        Button("Try again", action: retry)
          .font(.subheadline.weight(.semibold))
      }
    }
    .frame(maxWidth: .infinity, minHeight: 120)
    .padding(.horizontal)
  }
}
