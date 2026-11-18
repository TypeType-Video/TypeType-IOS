import SwiftUI

struct LiveDanmakuJumpPrompt: View {
  static let undoTime: Duration = .seconds(5)

  @ObservedObject var controller: LivePlayerController
  @State private var used: Set<String> = []
  @State private var undo: (from: TimeInterval, to: TimeInterval)?
  @State private var undoTask: Task<Void, Never>?

  var body: some View {
    Group {
      if let undo {
        pill {
          Text("Jumped to \(LiveDanmakuJumpPrompt.clock(undo.to))")
          Button {
            controller.seek(to: undo.from)
            self.undo = nil
          } label: {
            Label("Undo", systemImage: "arrow.uturn.backward")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.mini)
        }
      } else if let offer {
        Button { jump(offer) } label: {
          pill { Label("Jump to \(LiveDanmakuJumpPrompt.clock(offer.seconds))", systemImage: "arrow.down.to.line.compact") }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("A viewer pointed to this moment in the comments."))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    .padding(.leading, 12)
    .padding(.bottom, 64)
    .animation(.easeOut(duration: 0.2), value: offer?.key)
    .onChange(of: controller.video.id) { used = [] }
  }

  private var offer: LiveDanmakuJump? {
    guard controller.supportsBulletComments, controller.bulletCommentsEnabled,
      let found = LiveDanmakuJump.current(in: controller.bulletComments, position: controller.position, duration: controller.duration),
      !used.contains(found.key)
    else { return nil }
    return found
  }

  private func jump(_ offer: LiveDanmakuJump) {
    used.insert(offer.key)
    undo = (controller.position, offer.seconds)
    controller.seek(to: offer.seconds)
    undoTask?.cancel()
    undoTask = Task {
      guard (try? await Task.sleep(for: Self.undoTime)) != nil else { return }
      undo = nil
    }
  }

  private func pill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    HStack(spacing: 8) { content() }
      .font(.caption.weight(.medium))
      .foregroundStyle(.white)
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
      .background(.black.opacity(0.75), in: Capsule())
      .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
  }

  static func clock(_ seconds: TimeInterval) -> String {
    Duration.seconds(seconds).formatted(.time(pattern: seconds >= 3600 ? .hourMinuteSecond : .minuteSecond))
  }
}
