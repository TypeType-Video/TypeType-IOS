import SwiftUI

struct LiveAudioOnlyPoster: View {
  let posterURL: URL?
  let title: String
  let isPlaying: Bool
  var showsDetails = true
  var showsArtwork = true

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        backdrop
        if showsDetails {
          details(height: proxy.size.height)
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .animation(.easeOut(duration: 0.2), value: showsDetails)
    }
    .clipped()
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private func details(height: CGFloat) -> some View {
    if !showsArtwork || height < 120 {
      waveform(size: 26)
    } else if height < 280 {
      compact
    } else {
      expanded
    }
  }

  private var backdrop: some View {
    ZStack {
      Color.black
      // Opaque blur: a plain blur fades the edges to transparent and the black shows through as a dark frame.
      LiveRemoteImage(url: posterURL)
        .blur(radius: 36, opaque: true)
        .opacity(0.6)
      LinearGradient(
        colors: [.black.opacity(0.15), .black.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
      )
    }
  }

  private var compact: some View {
    HStack(spacing: 16) {
      artwork(width: 128)
      VStack(alignment: .leading, spacing: 10) {
        titleText(alignment: .leading)
          .font(.subheadline.weight(.semibold))
        waveform(size: 24)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 24)
    .transition(.opacity)
  }

  private var expanded: some View {
    VStack(spacing: 16) {
      artwork(width: 220)
      titleText(alignment: .center)
        .font(.headline)
      waveform(size: 30)
    }
    .padding(.horizontal, 32)
    .transition(.opacity)
  }

  private func artwork(width: CGFloat) -> some View {
    LiveRemoteImage(url: posterURL)
      .frame(width: width, height: width * 9 / 16)
      .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
  }

  private func titleText(alignment: TextAlignment) -> some View {
    Text(verbatim: title)
      .foregroundStyle(.white)
      .multilineTextAlignment(alignment)
      .lineLimit(2)
  }

  private func waveform(size: CGFloat) -> some View {
    Image(systemName: "waveform")
      .font(.system(size: size, weight: .medium))
      .foregroundStyle(.white)
      .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: isPlaying)
      .transition(.opacity)
  }
}
