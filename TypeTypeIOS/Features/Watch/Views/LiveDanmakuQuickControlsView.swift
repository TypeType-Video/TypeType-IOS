import SwiftUI

struct LiveDanmakuQuickControlsView: View {
  @ObservedObject var controller: LivePlayerController
  @ObservedObject private var bulletCommentStore: LiveBulletCommentStore
  @State private var presentsControls = false

  init(controller: LivePlayerController) {
    self.controller = controller
    bulletCommentStore = controller.bulletCommentStore
  }

  var body: some View {
    Button {
      presentsControls = true
    } label: {
      VStack(spacing: 5) {
        Image(
          systemName: controller.bulletCommentsEnabled
            ? "captions.bubble.fill"
            : "captions.bubble"
        )
        .font(.title3.weight(.medium))
        Text("Danmaku")
          .font(.caption.weight(.semibold))
          .lineLimit(1)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 48)
    }
    .buttonStyle(.bordered)
    .accessibilityLabel("Danmaku controls")
    .accessibilityValue(
      controller.bulletCommentsEnabled ? "On" : "Off"
    )
    .accessibilityIdentifier("live.danmaku.quick-action")
    .popover(isPresented: $presentsControls) {
      controls
        .presentationCompactAdaptation(.popover)
    }
  }

  private var controls: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack {
        Label("Danmaku", systemImage: "captions.bubble")
          .font(.headline)
        Spacer()
        Toggle(
          "Danmaku",
          isOn: Binding(
            get: { controller.bulletCommentsEnabled },
            set: controller.setBulletCommentsEnabled
          )
        ).liveRowFill()
        .labelsHidden()
      }

      control(
        title: "Speed",
        value: controller.bulletCommentSpeed,
        range: 0.5...2,
        setter: controller.setBulletCommentSpeed
      )

      control(
        title: "Size",
        value: controller.bulletCommentSize,
        range: 0.5...2,
        setter: controller.setBulletCommentSize
      )

      if bulletCommentStore.state.isLoading {
        HStack(spacing: 8) {
          ProgressView()
          Text("Loading danmaku")
            .foregroundStyle(.secondary)
        }
        .font(.caption)
      } else {
        Text("\(bulletCommentStore.state.comments.count) danmaku")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(20)
    .frame(width: 300)
  }

  private func control(
    title: String,
    value: Double,
    range: ClosedRange<Double>,
    setter: @escaping (Double) -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
        Spacer()
        Text(value.formatted(.number.precision(.fractionLength(1))) + "×")
          .monospacedDigit()
          .foregroundStyle(.secondary)
      }
      Slider(
        value: Binding(get: { value }, set: setter),
        in: range,
        step: 0.1
      )
      .disabled(!controller.bulletCommentsEnabled)
      .accessibilityLabel("Danmaku \(title.lowercased())")
      .accessibilityIdentifier(
        "live.danmaku.\(title.lowercased())"
      )
    }
    .font(.subheadline)
  }
}
