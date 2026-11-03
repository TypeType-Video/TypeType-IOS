import SwiftUI

struct LiveDownloadRow: View {
  @Environment(\.themePalette) private var palette
  let record: LiveManagedDownload
  let artifactURL: URL?
  var progress: Double?
  let onPlay: () -> Void
  let onCancel: () -> Void
  let onRetry: () -> Void
  let onRemove: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      HStack(alignment: .top, spacing: 12) {
        thumbnail
        VStack(alignment: .leading, spacing: 4) {
          Text(record.title)
            .font(.subheadline.weight(.semibold))
            .lineLimit(2)
          if let channel = record.metadata?.uploaderName, !channel.isEmpty {
            Text(channel)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          status
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .contentShape(Rectangle())
      .onTapGesture { if canPlay { onPlay() } }
      .accessibilityElement(children: .combine)
      .accessibilityAddTraits(canPlay ? .isButton : [])
      .accessibilityHint(canPlay ? Text(isAudio ? "Plays the audio offline" : "Plays the video offline") : Text(""))
      .accessibilityAction(.default) { if canPlay { onPlay() } }

      actionsMenu
    }
    .padding(.vertical, 4)
    .swipeActions(edge: .trailing) {
      if record.state.canCancel {
        Button("Cancel", systemImage: "xmark", role: .destructive, action: onCancel)
      } else {
        Button("Delete", systemImage: "trash", role: .destructive, action: onRemove)
      }
    }
    .accessibilityIdentifier("live.download.\(record.id)")
  }

  private var thumbnail: some View {
    LiveRemoteImage(url: record.metadata.flatMap { URL(string: $0.thumbnailURL) })
      .frame(width: 112, height: 63)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .overlay(alignment: .bottomTrailing) {
        if let duration = LiveDownloadTexts.duration(record.metadata?.duration) {
          Text(duration)
            .font(.caption2.weight(.semibold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 5))
            .padding(4)
        }
      }
      .overlay {
        if canPlay {
          Image(systemName: isAudio ? "headphones" : "play.fill")
            .font(.title3)
            .foregroundStyle(.white)
            .shadow(radius: 3)
        }
      }
      .accessibilityHidden(true)
  }

  @ViewBuilder private var status: some View {
    switch record.state {
    case .ready:
      Text(LiveDownloadTexts.summary(record))
        .font(.caption)
        .foregroundStyle(.secondary)
    case .failed, .cancelled:
      Label(record.failureMessage ?? record.state.title, systemImage: record.state.systemImage)
        .font(.caption)
        .foregroundStyle(record.state == .failed ? Color.red : .secondary)
        .lineLimit(2)
    default:
      VStack(alignment: .leading, spacing: 4) {
        if let progress {
          ProgressView(value: progress).tint(palette.accent)
        } else {
          ProgressView().controlSize(.small)
        }
        Text(LiveDownloadTexts.transfer(record, saved: progress))
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
        if let waiting = record.failureMessage, !waiting.isEmpty {
          Label(waiting, systemImage: "wifi.exclamationmark")
            .font(.caption)
            .foregroundStyle(.orange)
            .lineLimit(2)
        }
      }
      .padding(.top, 2)
    }
  }

  private var actionsMenu: some View {
    Menu {
      if canPlay {
        Button(isAudio ? "Listen" : "Watch", systemImage: isAudio ? "headphones" : "play", action: onPlay)
      }
      if let artifactURL {
        ShareLink(item: artifactURL) { Label("Share", systemImage: "square.and.arrow.up") }
      }
      if record.state.canRetry {
        Button("Retry", systemImage: "arrow.clockwise", action: onRetry)
      }
      if record.state.canCancel {
        Button("Cancel download", systemImage: "xmark", role: .destructive, action: onCancel)
      } else {
        Button("Delete", systemImage: "trash", role: .destructive, action: onRemove)
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.body.weight(.semibold))
        .foregroundStyle(.secondary)
        .frame(width: 32, height: 44)
        .contentShape(Rectangle())
    }
    .accessibilityLabel(Text("More actions for \(record.title)"))
  }

  private var canPlay: Bool {
    record.state == .ready && artifactURL != nil && record.options.mode != LiveDownloadMode.thumbnail.rawValue
  }

  private var isAudio: Bool {
    record.options.mode == LiveDownloadMode.audio.rawValue
  }
}
