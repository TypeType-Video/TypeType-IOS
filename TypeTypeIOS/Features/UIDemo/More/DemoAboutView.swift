import SwiftUI

struct DemoAboutView: View {
  @State private var pendingURL: URL?

  var body: some View {
    List {
      Section {
        VStack(spacing: 14) {
          Image("TypeTypeLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 88, height: 88)
          Text("TypeType")
            .font(.title.weight(.bold))
          Text("An open-source video client shaped for iPhone and iPad.")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
      }

      Section("Build") {
        LabeledContent("Version", value: "0.1.0 mock")
        LabeledContent("Data source", value: "Local fixtures")
        LabeledContent("Network", value: "Disabled")
      }

      Section("Open source") {
        externalButton(
          "TypeType on GitHub",
          symbol: "chevron.left.forwardslash.chevron.right",
          url: "https://github.com/TypeType-Video"
        )
        externalButton(
          "PipePipe",
          symbol: "play.rectangle",
          url: "https://github.com/InfinityLoop1308/PipePipe"
        )
        Label("Blender Open Movies", systemImage: "film")
        externalButton(
          "Support TypeType",
          symbol: "heart.fill",
          url: "https://github.com/sponsors/Priveetee"
        )
      }
    }
    .navigationTitle("About TypeType")
    .navigationBarTitleDisplayMode(.inline)
    .demoExternalLinkAlert(pendingURL: $pendingURL)
    .accessibilityIdentifier("demo.about.screen")
  }

  private func externalButton(
    _ title: String,
    symbol: String,
    url: String
  ) -> some View {
    Button {
      pendingURL = URL(string: url)
    } label: {
      Label(title, systemImage: symbol)
    }
  }
}
