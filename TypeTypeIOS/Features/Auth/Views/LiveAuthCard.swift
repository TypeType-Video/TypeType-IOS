import SwiftUI

struct LiveAuthCard: View {
  @ObservedObject var coordinator: RootCoordinator
  @ObservedObject var viewModel: LiveAuthViewModel
  let isLight: Bool
  @Binding var showsResetPassword: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      heading
      if viewModel.localLoginEnabled {
        fields
        primaryButton
      } else {
        Label(
          "Local sign-in is disabled on this instance.",
          systemImage: "lock.shield"
        )
        .font(.subheadline)
        .foregroundStyle(palette.secondaryText)
      }
      if viewModel.oidcEnabled {
        oidcButton
      }
      if coordinator.instance?.guestAllowed == true {
        guestButton
      }
      if let errorMessage = viewModel.errorMessage {
        Label(
          errorMessage,
          systemImage: "exclamationmark.triangle.fill"
        )
        .font(.footnote)
        .foregroundStyle(.red)
      }
      footer
    }
    .padding(24)
    .frame(maxWidth: 448)
    .background(palette.cardSurface)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(palette.border)
    }
    .shadow(color: .black.opacity(0.35), radius: 28, y: 14)
    .animation(.snappy(duration: 0.25), value: viewModel.mode)
    .onChange(of: viewModel.identifier) {
      viewModel.clearError()
    }
  }

  private var heading: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(viewModel.mode == .signIn ? "Sign in" : "Create account")
        .font(.title3.weight(.semibold))
        .foregroundStyle(palette.primaryText)
      Text(coordinator.instance?.name ?? coordinator.selectedServer?.name ?? "TypeType")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(palette.primaryText)
      Text(subtitle)
        .font(.footnote)
        .foregroundStyle(palette.secondaryText)
    }
  }

  private var fields: some View {
    VStack(spacing: 12) {
      if viewModel.mode == .register {
        DemoAuthField(
          placeholder: "Name",
          kind: .name,
          palette: palette,
          text: $viewModel.name
        )
      }
      DemoAuthField(
        placeholder: viewModel.mode == .signIn
          ? "Email or username"
          : "Email",
        kind: .email,
        palette: palette,
        text: $viewModel.identifier
      )
      DemoAuthField(
        placeholder: "Password",
        kind: .password,
        palette: palette,
        text: $viewModel.password
      )
    }
  }

  private var primaryButton: some View {
    Button {
      Task {
        await viewModel.submit(using: coordinator)
      }
    } label: {
      loadingLabel(
        viewModel.mode == .signIn ? "Sign in" : "Register"
      )
      .foregroundStyle(palette.buttonText)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 48)
      .background(
        palette.buttonSurface.opacity(viewModel.canSubmit ? 1 : 0.45)
      )
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
    .disabled(!viewModel.canSubmit)
    .accessibilityIdentifier("live.auth.submit")
  }

  private var oidcButton: some View {
    Button {
      Task {
        await viewModel.continueWithOIDC(using: coordinator)
      }
    } label: {
      Label(
        "Continue with \(viewModel.oidcProviderName)",
        systemImage: "person.badge.key.fill"
      )
      .frame(maxWidth: .infinity)
      .frame(minHeight: 46)
    }
    .buttonStyle(.bordered)
    .disabled(viewModel.isLoading)
    .accessibilityIdentifier("live.auth.oidc")
  }

  private var guestButton: some View {
    Button {
      Task {
        await viewModel.continueAsGuest(using: coordinator)
      }
    } label: {
      Label("Continue as guest", systemImage: "person.crop.circle")
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
    }
    .buttonStyle(.plain)
    .foregroundStyle(palette.primaryText)
    .disabled(viewModel.isLoading)
    .accessibilityIdentifier("live.auth.guest")
  }

  var palette: DemoAuthPalette {
    DemoAuthPalette(isLight: isLight)
  }
}
