import SwiftUI

struct LiveAuthView: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel = LiveAuthViewModel()
  @State private var isLight = false
  @State private var showsResetPassword = false

  var body: some View {
    ZStack {
      AuthBackdrop(isLight: isLight)

      GeometryReader { proxy in
        ScrollView {
          VStack {
            Spacer(minLength: 78)
            LiveAuthCard(
              coordinator: coordinator,
              viewModel: viewModel,
              isLight: isLight,
              showsResetPassword: $showsResetPassword
            )
            .padding(.horizontal, proxy.size.width < 500 ? 28 : 44)
            Spacer(minLength: 48)
          }
          .frame(minHeight: proxy.size.height)
          .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
      }
    }
    .overlay(alignment: .topLeading) {
      Button {
        coordinator.showServerSetup()
      } label: {
        Label("Instances", systemImage: "server.rack")
          .labelStyle(.iconOnly)
          .frame(width: 42, height: 42)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
      }
      .accessibilityLabel("Choose another TypeType instance")
      .padding(.top, 14)
      .padding(.leading, 16)
    }
    .overlay(alignment: .topTrailing) {
      Button {
        withAnimation(.easeInOut(duration: 0.25)) {
          isLight.toggle()
        }
      } label: {
        Image(systemName: isLight ? "moon.fill" : "sun.max.fill")
          .frame(width: 42, height: 42)
          .background(.ultraThinMaterial)
          .clipShape(Circle())
      }
      .accessibilityLabel(
        isLight ? "Use dark appearance" : "Use light appearance"
      )
      .padding(.top, 14)
      .padding(.trailing, 16)
    }
    .sheet(isPresented: $showsResetPassword) {
      LiveResetPasswordView(
        service: coordinator.dependencies.resetPasswordService
      )
    }
    .task {
      await viewModel.load(using: coordinator)
    }
    .tint(isLight ? palette.accent : .white)
    .preferredColorScheme(isLight ? .light : .dark)
  }
}
