import AVKit
import SwiftUI

extension LivePlayerOptionsSheet {
  var presentationSection: some View {
    Section {
      Picker("Image mode", selection: binding(
        \.imageMode,
        setter: controller.setImageMode
      )) {
        ForEach(LivePlayerImageMode.allCases) { mode in
          Text(mode.title).tag(mode)
        }
      }
      Toggle("Cinema mode", isOn: $cinemaMode).liveRowFill()
      LabeledContent(
        "Picture in Picture",
        value: AVPictureInPictureController
          .isPictureInPictureSupported()
          ? "Available"
          : "Unavailable"
      )

      if controller.supportsBulletComments {
        Toggle(
          "Danmaku",
          isOn: binding(
            \.bulletCommentsEnabled,
            setter: controller.setBulletCommentsEnabled
          )
        ).liveRowFill()
        if controller.bulletCommentsEnabled {
          LabeledContent("Danmaku speed") {
            Slider(
              value: binding(
                \.bulletCommentSpeed,
                setter: controller.setBulletCommentSpeed
              ),
              in: 0.5...2,
              step: 0.1
            )
            .frame(width: 145)
          }
          LabeledContent("Danmaku size") {
            Slider(
              value: binding(
                \.bulletCommentSize,
                setter: controller.setBulletCommentSize
              ),
              in: 0.5...2,
              step: 0.1
            )
            .frame(width: 145)
          }
          if bulletCommentStore.state.isLoading {
            HStack {
              Text("Loading danmaku")
              Spacer()
              ProgressView()
            }
          } else if bulletCommentStore.state.comments.isEmpty {
            Text("No danmaku is available for this video.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    } header: { Text("Player presentation").liveSectionHeader() }
  }
}
