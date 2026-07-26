import SwiftUI

struct LiveYouTubeRemoteBrowserView: View {
  @ObservedObject var browser: LiveYouTubeRemoteBrowser
  @State private var text = ""

  var body: some View {
    VStack(spacing: 12) {
      GeometryReader { geometry in
        ZStack {
          Color.black
          if let frame = browser.frame {
            Image(uiImage: frame)
              .resizable()
              .scaledToFit()
          } else {
            VStack(spacing: 8) {
              ProgressView()
                .tint(.white)
              Text(browser.phase.title)
                .foregroundStyle(.white)
              if let error = browser.errorMessage {
                Text(error)
                  .font(.caption)
                  .foregroundStyle(.red)
              }
            }
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onAppear {
          browser.sendResize(
            width: Int(geometry.size.width),
            height: Int(geometry.size.height)
          )
        }
        .gesture(pointerGesture(size: geometry.size))
      }
      .aspectRatio(16 / 10, contentMode: .fit)

      HStack {
        TextField("Type into YouTube", text: $text)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .onSubmit(sendText)
        Button("Send", action: sendText)
          .disabled(text.isEmpty)
      }

      HStack {
        Button {
          browser.sendKey("Tab", code: "Tab")
        } label: {
          Label("Tab", systemImage: "arrow.right.to.line")
        }
        Spacer()
        Button {
          browser.sendWheel(deltaY: -480)
        } label: {
          Image(systemName: "arrow.up")
        }
        Button {
          browser.sendWheel(deltaY: 480)
        } label: {
          Image(systemName: "arrow.down")
        }
        Spacer()
        Button {
          browser.sendKey("Enter", code: "Enter")
        } label: {
          Label("Enter", systemImage: "return")
        }
      }
      .buttonStyle(.bordered)
    }
  }

  private func pointerGesture(size: CGSize) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        browser.sendPointer(
          event: "move",
          x: Int(value.location.x),
          y: Int(value.location.y)
        )
      }
      .onEnded { value in
        let x = min(max(Int(value.location.x), 0), Int(size.width))
        let y = min(max(Int(value.location.y), 0), Int(size.height))
        browser.sendPointer(event: "down", x: x, y: y)
        browser.sendPointer(event: "up", x: x, y: y)
      }
  }

  private func sendText() {
    browser.sendText(text)
    text = ""
  }
}
