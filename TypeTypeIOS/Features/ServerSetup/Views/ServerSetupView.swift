import SwiftUI
import UIKit

struct ServerSetupView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel = ServerSetupViewModel()
  @State var pendingRemoval: ServerProfile?
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    ZStack {
      DemoAuthBackdrop(isLight: colorScheme == .light)

      ScrollView {
        VStack(spacing: 22) {
          header
          connectCard
          if !coordinator.servers.isEmpty {
            savedServers
          }
        }
        .frame(maxWidth: 520)
        .padding(.horizontal, 24)
        .padding(.vertical, 54)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
    }
    .tint(DemoTheme.accent)
    .onChange(of: viewModel.url) {
      viewModel.clearError()
      coordinator.connectionError = nil
    }
    .alert(item: $pendingRemoval) { server in
      Alert(
        title: Text("Remove \(server.name)?"),
        message: Text(
          "This removes the instance and its saved session from this device."
        ),
        primaryButton: .destructive(Text("Remove")) {
          coordinator.deleteServer(server)
        },
        secondaryButton: .cancel()
      )
    }
  }

  private var header: some View {
    VStack(spacing: 12) {
      Image("TypeTypeLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 82, height: 82)
        .accessibilityHidden(true)
      Text("Connect to TypeType")
        .font(.largeTitle.bold())
        .multilineTextAlignment(.center)
      Text("Choose the instance that keeps your account and private data.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }

  private var connectCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("TypeType instance")
        .font(.headline)
      serverField(
        "Name (optional)",
        text: $viewModel.name,
        contentType: .organizationName,
        identifier: "live.server.name"
      )
      serverField(
        "Server address",
        text: $viewModel.url,
        contentType: .URL,
        identifier: "live.server.url"
      )
      Text("You can enter a domain or a complete address. TypeType verifies the instance before saving it.")
        .font(.caption)
        .foregroundStyle(.secondary)

      if let message =
        viewModel.errorMessage ?? coordinator.connectionError {
        Label(message, systemImage: "exclamationmark.triangle.fill")
          .font(.footnote)
          .foregroundStyle(.red)
      }

      Button {
        Task {
          await viewModel.connect(using: coordinator)
        }
      } label: {
        HStack {
          if viewModel.isConnecting {
            ProgressView()
              .controlSize(.small)
          }
          Text(viewModel.isConnecting ? "Checking instance…" : "Connect")
            .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 46)
      }
      .buttonStyle(.borderedProminent)
      .disabled(!viewModel.canConnect)
      .accessibilityIdentifier("live.server.connect")
    }
    .liveCard()
  }

  private func serverField(
    _ title: String,
    text: Binding<String>,
    contentType: UITextContentType,
    identifier: String
  ) -> some View {
    TextField(title, text: text)
      .textContentType(contentType)
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .keyboardType(contentType == .URL ? .URL : .default)
      .padding(.horizontal, 13)
      .frame(minHeight: 48)
      .background(.primary.opacity(0.055))
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .accessibilityIdentifier(identifier)
  }
}
