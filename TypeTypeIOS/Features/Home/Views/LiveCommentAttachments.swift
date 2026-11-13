import SwiftUI

struct LiveCommentAttachments: View {
  let comment: LiveCommentItem
  @ObservedObject var voice: LiveCommentVoicePlayer
  let animatesGIFs: Bool

  var body: some View {
    if let image = comment.image {
      imageView(image)
    }
    if let reply = comment.voiceReply {
      voiceView(reply)
    }
  }

  @ViewBuilder
  private func imageView(_ image: LiveCommentImage) -> some View {
    if let url = LiveImageURLResolver.resolve(image.url) {
      Group {
        if image.animated, animatesGIFs {
          LiveCommentAnimatedImage(url: url)
        } else {
          LiveRemoteImage(url: url, contentMode: .fit)
        }
      }
      .frame(maxWidth: 240, maxHeight: 240, alignment: .leading)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .accessibilityLabel(image.animated ? "GIF attached to the comment" : "Image attached to the comment")
    } else if let text = image.unavailableText, !text.isEmpty {
      unavailable(text)
    }
  }

  @ViewBuilder
  private func voiceView(_ reply: LiveCommentVoiceReply) -> some View {
    if reply.canPlay {
      let phase = voice.phase(for: comment)
      VStack(alignment: .leading, spacing: 6) {
        Button {
          voice.toggle(comment)
        } label: {
          HStack(spacing: 8) {
            if phase == .loading {
              ProgressView().controlSize(.small)
            } else {
              Image(systemName: phase == .playing ? "pause.circle.fill" : "play.circle.fill")
                .font(.title2)
            }
            Text("Voice reply")
              .font(.subheadline.weight(.semibold))
            if reply.duration > 0 {
              Text(Duration.seconds(reply.duration).formatted(.time(pattern: .minuteSecond)))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            }
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phase == .playing ? "Pause voice reply" : "Play voice reply")
        if phase == .failed {
          Text("The voice reply could not be played.")
            .font(.caption)
            .foregroundStyle(.red)
        }
        if !reply.transcript.isEmpty {
          Text(reply.transcript)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      }
    } else if let text = reply.unavailableText, !text.isEmpty {
      unavailable(text)
    }
  }

  private func unavailable(_ text: String) -> some View {
    Text(verbatim: text)
      .font(.caption)
      .foregroundStyle(.secondary)
  }
}

private struct LiveCommentAnimatedImage: View {
  let url: URL
  @State private var image: UIImage?

  var body: some View {
    Group {
      if let image {
        LiveAnimatedImage(image: image)
          .aspectRatio(image.size, contentMode: .fit)
      } else {
        LiveRemoteImage(url: url, contentMode: .fit)
      }
    }
    .task(id: url) { image = await LiveAnimatedImageLoader.comments.image(for: url) }
  }
}
