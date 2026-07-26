import SwiftUI

struct DemoHideEverythingSceneView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var phase = 0

  var body: some View {
    ZStack {
      if phase < 3 {
        Color.black.ignoresSafeArea()
        intro
      } else {
        scene
      }

      VStack {
        HStack {
          Button {
            dismiss()
          } label: {
            Label("Back", systemImage: "xmark")
              .labelStyle(.iconOnly)
              .padding(12)
              .background(.black.opacity(0.5), in: Circle())
          }
          .accessibilityLabel("Leave zen scene")
          Spacer()
        }
        Spacer()
      }
      .foregroundStyle(.white)
      .padding()
    }
    .task {
      for next in 1...3 {
        try? await Task.sleep(for: .milliseconds(950))
        withAnimation(.easeInOut(duration: 0.35)) {
          phase = next
        }
      }
    }
    .accessibilityIdentifier("demo.hide-everything.scene")
  }

  private var intro: some View {
    Group {
      if phase == 0 {
        VStack(spacing: 16) {
          Text("FINE!")
            .font(.system(size: 66, weight: .black))
          Text("YOU WANT TO HIDE EVERYTHING?")
            .font(.title3.bold())
        }
      } else if phase == 1 {
        Text("DO YOU KNOW HOW MUCH TIME I SPENT BUILDING ALL OF THIS?!")
          .font(.system(size: 30, weight: .black))
      } else {
        Text("GO AND RELAX")
          .font(.system(size: 46, weight: .black))
      }
    }
    .multilineTextAlignment(.center)
    .foregroundStyle(.white)
    .padding(28)
    .transition(.opacity)
  }

  private var scene: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.2, green: 0.72, blue: 0.86),
          Color(red: 0.06, green: 0.19, blue: 0.2),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      Circle()
        .fill(.white.opacity(0.28))
        .frame(width: 310)
        .blur(radius: 20)
        .offset(x: 110, y: -290)
      pixel("DemoPixelBird", width: 56).offset(x: 112, y: -230)
      pixel("DemoPixelTV", width: 145).offset(x: 70, y: 175)
      pixel("DemoPixelDog", width: 88).offset(x: -118, y: 265)
      pixel("DemoPixelCat", width: 74).offset(x: 120, y: 290)
      Text("A quiet corner of TypeType")
        .font(.caption.monospaced())
        .foregroundStyle(.white.opacity(0.8))
        .offset(y: 330)
    }
  }

  private func pixel(_ name: String, width: CGFloat) -> some View {
    Image(name)
      .resizable()
      .interpolation(.none)
      .scaledToFit()
      .frame(width: width)
  }
}
