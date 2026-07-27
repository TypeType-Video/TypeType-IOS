import SwiftUI

struct LivePlayerView: View {
  @ObservedObject var controller: LivePlayerController
  let posterURL: URL?
  @State private var showsOptions = false

  var body: some View {
    ZStack {
      Color.black

      DemoPlayerLayerView(player: controller.player)
        .accessibilityIdentifier("live.player.surface")

      if controller.audioOnly {
        ZStack {
          LiveRemoteImage(url: posterURL)
            .scaledToFill()
            .blur(radius: 28)
            .opacity(0.48)
            .clipped()
          Image(systemName: "waveform")
            .font(.system(size: 44, weight: .medium))
            .foregroundStyle(.white)
            .symbolEffect(.variableColor.iterative)
        }
        .allowsHitTesting(false)
      }

      statusOverlay

      Button {
        showsOptions = true
      } label: {
        Image(systemName: "slider.horizontal.3")
          .font(.body.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 38, height: 38)
          .background(.black.opacity(0.58), in: Circle())
          .overlay {
            Circle().stroke(.white.opacity(0.22), lineWidth: 0.5)
          }
      }
      .buttonStyle(.plain)
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topTrailing
      )
      .padding(10)
      .accessibilityLabel("Player options")
      .accessibilityIdentifier("live.player.options")
    }
    .aspectRatio(16 / 9, contentMode: .fit)
    .clipShape(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
    .accessibilityIdentifier("live.player.container")
    .accessibilityValue(controller.accessibilityStatus)
    .sheet(isPresented: $showsOptions) {
      LivePlayerOptionsSheet(controller: controller)
    }
  }

  @ViewBuilder
  private var statusOverlay: some View {
    switch controller.state {
    case .idle, .loading:
      ProgressView()
        .controlSize(.large)
        .tint(.white)
        .accessibilityLabel("Preparing video")
    case let .failed(message):
      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
          .font(.title2)
        Text(message)
          .font(.footnote)
          .multilineTextAlignment(.center)
        Button("Try again", action: controller.retry)
          .buttonStyle(.borderedProminent)
      }
      .foregroundStyle(.white)
      .padding(24)
      .background(.black.opacity(0.82))
      .clipShape(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .padding(18)
    case .ready, .playing, .paused:
      EmptyView()
    }
  }
}

private struct LivePlayerOptionsSheet: View {
  @ObservedObject var controller: LivePlayerController
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section("Playback") {
          Toggle(
            "Audio only",
            isOn: Binding(
              get: { controller.audioOnly },
              set: controller.setAudioOnly
            )
          )

          Picker(
            "Speed",
            selection: Binding(
              get: { controller.playbackRate },
              set: controller.setPlaybackRate
            )
          ) {
            Text("0.5×").tag(Float(0.5))
            Text("0.75×").tag(Float(0.75))
            Text("Normal").tag(Float(1))
            Text("1.25×").tag(Float(1.25))
            Text("1.5×").tag(Float(1.5))
            Text("2×").tag(Float(2))
          }
        }

        if !controller.availableVideoSources.isEmpty {
          Section("Quality") {
            Picker(
              "Video",
              selection: Binding(
                get: { controller.selectedVideoItag },
                set: controller.selectVideoItag
              )
            ) {
              Text("Automatic").tag(Int?.none)
              ForEach(controller.availableVideoSources) { source in
                Text(source.displayName).tag(Optional(source.itag))
              }
            }
          }
        }

        if controller.availableAudioSources.count > 1 {
          Section("Audio") {
            Picker(
              "Track",
              selection: Binding(
                get: { controller.selectedAudioTrackID },
                set: controller.selectAudioTrack
              )
            ) {
              Text("Default").tag(String?.none)
              ForEach(controller.availableAudioSources) { source in
                Text(source.displayName)
                  .tag(source.audioTrackID)
              }
            }
          }
        }

        Section {
          LabeledContent("Transport", value: controller.transportLabel)
          if controller.preparation?.subtitles.isEmpty == false {
            Text(
              "Subtitles are available from the native player menu."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle("Player")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}
