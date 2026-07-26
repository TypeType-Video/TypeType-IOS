import SwiftUI

struct DemoGuestAccessPreviewView: View {
  @State private var authMode = DemoAuthMode.signIn
  @State private var presentsAuth = false

  var body: some View {
    VStack(spacing: 24) {
      Image("DemoPixelBird")
        .resizable()
        .interpolation(.none)
        .scaledToFit()
        .frame(maxWidth: 260)
        .padding(26)
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 22))

      VStack(spacing: 8) {
        Text("Guest mode disabled")
          .font(.title2.bold())
        Text("The admin has disabled guest access. Create an account or sign in to continue.")
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }

      VStack(spacing: 10) {
        Button("Create account") {
          authMode = .register
          presentsAuth = true
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        Button("Sign in") {
          authMode = .signIn
          presentsAuth = true
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
      }
    }
    .padding(24)
    .navigationTitle("Guest access preview")
    .navigationBarTitleDisplayMode(.inline)
    .fullScreenCover(isPresented: $presentsAuth) {
      DemoAuthView(initialMode: authMode) {
        presentsAuth = false
      }
    }
  }
}
