import SwiftUI

extension LivePlayerOptionsSheet {
  var presentationSection: some View {
    Section {
      Picker(selection: binding(\.imageMode, setter: controller.setImageMode)) {
        ForEach(LivePlayerImageMode.allCases) { mode in
          Text(LocalizedStringKey(mode.title)).tag(mode)
        }
      } label: {
        LivePlayerOptionLabel("Image mode", icon: "aspectratio")
      }
      Toggle(isOn: $cinemaMode) {
        LivePlayerOptionLabel("Cinema mode", icon: "theatermasks", detail: "Dims the page around the video.")
      }
    } header: { Text("Display").liveSectionHeader() }
  }

  @ViewBuilder var danmakuSection: some View {
    if controller.supportsBulletComments {
      Section {
        Toggle(isOn: binding(\.bulletCommentsEnabled, setter: controller.setBulletCommentsEnabled)) {
          LivePlayerOptionLabel("Danmaku", icon: "text.bubble")
        }
        if controller.bulletCommentsEnabled {
          slider("Speed", icon: "hare", value: binding(\.bulletCommentSpeed, setter: controller.setBulletCommentSpeed))
          slider("Size", icon: "textformat.size", value: binding(\.bulletCommentSize, setter: controller.setBulletCommentSize))
          if bulletCommentStore.state.isLoading {
            HStack {
              Text("Loading danmaku")
              Spacer()
              ProgressView()
            }
            .foregroundStyle(.secondary)
          } else if bulletCommentStore.state.comments.isEmpty {
            Text("No danmaku is available for this video.")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      } header: { Text("Danmaku").liveSectionHeader() }
    }
  }

  private func slider(_ title: LocalizedStringKey, icon: String, value: Binding<Double>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        LivePlayerOptionLabel(title, icon: icon)
        Spacer()
        Text(value.wrappedValue, format: .number.precision(.fractionLength(1)))
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }
      Slider(value: value, in: 0.5...2, step: 0.1)
        .accessibilityLabel(Text(title))
    }
  }
}
