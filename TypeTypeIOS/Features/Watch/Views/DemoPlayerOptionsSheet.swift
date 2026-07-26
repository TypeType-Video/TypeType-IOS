import SwiftUI

struct DemoPlayerOptionsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var session: DemoSessionStore
  @ObservedObject var controller: DemoPlayerController
  @Binding var audioOnly: Bool

  var body: some View {
    NavigationStack {
      Form {
        Section("Playback") {
          Picker("Quality", selection: binding(\.defaultQuality)) {
            Text("Best available").tag("Best available")
            Text("2160p").tag("2160p")
            Text("1080p").tag("1080p")
            Text("720p").tag("720p")
          }
          Picker("Speed", selection: binding(\.playbackSpeed)) {
            ForEach(
              ["0.25×", "0.5×", "0.75×", "1×", "1.25×", "1.5×", "2×", "3×", "4×"],
              id: \.self
            ) {
              Text($0).tag($0)
            }
          }
          .onChange(of: session.preferences.playbackSpeed) {
            controller.setPlaybackRate(selectedRate)
          }
          Stepper(
            "Audio boost · \(session.preferences.audioGainPercent)%",
            value: binding(\.audioGainPercent),
            in: 100...300,
            step: 25
          )
          .onChange(of: session.preferences.audioGainPercent) {
            controller.setAudioGain(
              percent: session.preferences.audioGainPercent
            )
          }
          .accessibilityIdentifier("demo.player.audio-boost")
          Text("Boost is separate from the iPhone volume and can reach 300%.")
            .font(.caption)
            .foregroundStyle(.secondary)
          Toggle(
            "Audio only",
            systemImage: "headphones",
            isOn: audioOnlyBinding
          )
          Toggle("Autoplay next video", isOn: binding(\.autoplay))
          Toggle("Loop video", isOn: binding(\.loopPlayback))
            .onChange(of: session.preferences.loopPlayback) {
              controller.setLooping(session.preferences.loopPlayback)
            }
        }

        Section("Tracks") {
          Picker("Audio", selection: binding(\.audioLanguage)) {
            Text("Original · English").tag("Original")
            Text("French").tag("French")
            Text("Audio description").tag("Description")
          }
          .disabled(session.preferences.prefersOriginalLanguage)
          if session.preferences.prefersOriginalLanguage {
            Text("Original audio is preferred by your language setting.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Toggle("Subtitles", isOn: binding(\.subtitlesEnabled))
          if session.preferences.subtitlesEnabled {
            Picker("Subtitle language", selection: binding(\.subtitleLanguage)) {
              Text("English").tag("English")
              Text("Français").tag("French")
              Text("Deutsch").tag("German")
              Text("Auto-translated").tag("Auto")
            }
          }
          NavigationLink("Caption appearance") {
            DemoCaptionSettingsView()
          }
        }

        Section("Player presentation") {
          Toggle("Cinema mode", isOn: binding(\.cinemaMode))
          Toggle("Bullet comments", isOn: binding(\.bulletComments))
          if session.preferences.bulletComments {
            LabeledContent("Danmaku speed") {
              Slider(value: binding(\.bulletCommentSpeed), in: 0.5...2)
                .frame(width: 145)
            }
            LabeledContent("Danmaku size") {
              Slider(value: binding(\.bulletCommentSize), in: 0.7...1.6)
                .frame(width: 145)
            }
          }
          Picker("Demo state", selection: binding(\.playerDemoState)) {
            ForEach(
              [
                "Normal",
                "Live",
                "Premiere scheduled",
                "Paid video",
                "Members only",
                "Outside family list",
                "YouTube reconnect",
                "Region blocked",
                "Unavailable",
              ],
              id: \.self
            ) {
              Text($0).tag($0)
            }
          }
        }

        Section("Community enhancements") {
          Toggle("SponsorBlock", isOn: binding(\.sponsorBlock))
            .accessibilityIdentifier("demo.player.options.sponsorblock")
          Toggle("DeArrow", isOn: binding(\.deArrow))
            .accessibilityIdentifier("demo.player.options.dearrow")
          LabeledContent(
            "SponsorBlock behavior",
            value: session.preferences.sponsorBlockMode
          )
          LabeledContent(
            "Title and thumbnail",
            value: session.preferences.deArrow ? "Community" : "Original"
          )
        }

        Section("Stream information") {
          LabeledContent("Delivery", value: "SABR")
          LabeledContent(
            "Video",
            value: "\(session.preferences.defaultQuality) · H.264"
          )
          LabeledContent(
            "Audio",
            value: "\(effectiveAudioLanguage) · AAC · 48 kHz"
          )
          LabeledContent("Buffer", value: "Healthy")
        }
      }
      .navigationTitle("Player options")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .presentationDetents([.large])
    .preferredColorScheme(session.preferences.colorScheme)
    .accessibilityIdentifier("demo.player.options")
  }

  private var audioOnlyBinding: Binding<Bool> {
    Binding(
      get: { audioOnly },
      set: { enabled in
        let wasPlaying = controller.state == .playing
        audioOnly = enabled
        controller.resumeAfterPresentationChange(if: wasPlaying)
      }
    )
  }

}
