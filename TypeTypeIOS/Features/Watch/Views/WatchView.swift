import SwiftUI

struct WatchView: View {
  let videoURL: String
  @StateObject private var viewModel: WatchViewModel
  @StateObject private var actionsViewModel: WatchActionsViewModel

  init(
    videoURL: String,
    watchService: WatchServiceProtocol,
    watchActionsService: WatchActionsServiceProtocol
  ) {
    self.videoURL = videoURL
    _viewModel = StateObject(wrappedValue: WatchViewModel(videoURL: videoURL, watchService: watchService))
    _actionsViewModel = StateObject(
      wrappedValue: WatchActionsViewModel(videoURL: videoURL, service: watchActionsService)
    )
  }

  private func formatDuration(_ total: Int64) -> String {
    let minutes = total / 60
    let seconds = total % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  private func formatViews(_ views: Int64) -> String {
    if views >= 1_000_000 { return String(format: "%.1fM", Double(views) / 1_000_000.0) }
    if views >= 1_000 { return String(format: "%.1fK", Double(views) / 1_000.0) }
    return "\(views)"
  }
  @ViewBuilder
  private var actionBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack {
        Button {
          Task { await actionsViewModel.toggleFavorite() }
        } label: {
          Label(
            actionsViewModel.isFavorite ? "Favorited" : "Favorite",
            systemImage: actionsViewModel.isFavorite ? "heart.fill" : "heart"
          )
        }
        .buttonStyle(.bordered)

        Button {
          Task { await actionsViewModel.toggleWatchLater() }
        } label: {
          Label(
            actionsViewModel.isWatchLater ? "Saved" : "Watch Later",
            systemImage: actionsViewModel.isWatchLater ? "clock.fill" : "clock"
          )
        }
        .buttonStyle(.bordered)

        Button {
          Task { await actionsViewModel.toggleSubscription() }
        } label: {
          Label(
            actionsViewModel.isSubscribed ? "Subscribed" : "Subscribe",
            systemImage: actionsViewModel.isSubscribed ? "bell.fill" : "bell"
          )
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .disabled(actionsViewModel.isMutating || actionsViewModel.isLoading)
  }
  @ViewBuilder
  private var content: some View {
    if viewModel.isLoading && viewModel.stream == nil {
      ProgressView("Loading video...")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    } else if let errorMessage = viewModel.errorMessage {
      ContentUnavailableView(
        "Unable to open video",
        systemImage: "exclamationmark.triangle",
        description: Text(errorMessage)
      )
      .frame(maxHeight: .infinity)
    } else if let stream = viewModel.stream {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          AsyncImage(url: URL(string: stream.thumbnailUrl)) { image in
            image
              .resizable()
              .scaledToFill()
          } placeholder: {
            Color.secondary.opacity(0.18)
          }
          .frame(maxWidth: .infinity)
          .aspectRatio(16 / 9, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 12))

          Text(stream.title)
            .font(.title3.weight(.semibold))
          Text(stream.uploaderName)
            .font(.subheadline)
            .foregroundStyle(.secondary)

          HStack(spacing: 10) {
            Text("\(formatViews(stream.viewCount)) views")
            Text("•")
            Text(stream.uploadDate)
            Text("•")
            Text(formatDuration(stream.duration))
          }
          .font(.caption)
          .foregroundStyle(.secondary)

          HStack(spacing: 8) {
            Text(stream.streamType.uppercased())
            if stream.isShortFormContent {
              Text("SHORT")
            }
          }
          .font(.caption2.weight(.semibold))
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(TypeTypeColor.card)
          .clipShape(Capsule())

          actionBar

          if let message = actionsViewModel.message {
            Text(message)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          if stream.requiresMembership {
            Label("Member-only content", systemImage: "person.2.badge.key")
              .font(.caption)
              .foregroundStyle(.orange)
          }

          if !stream.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(stream.description)
              .font(.body)
              .foregroundStyle(.secondary)
          }

          HStack {
            if let source = URL(string: videoURL) {
              Link("Open Source", destination: source)
                .buttonStyle(.borderedProminent)
            }
            if let uploader = URL(string: stream.uploaderUrl), !stream.uploaderUrl.isEmpty {
              Link("Channel", destination: uploader)
                .buttonStyle(.bordered)
            }
          }
        }
        .padding()
      }
      .task(id: stream.title) {
        actionsViewModel.prepare(stream: stream)
        await actionsViewModel.refresh()
      }
    }
  }

  var body: some View {
    content
      .navigationTitle("Watch")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await viewModel.load()
      }
  }
}
