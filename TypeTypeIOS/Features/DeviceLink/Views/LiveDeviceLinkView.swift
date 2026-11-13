import SwiftUI

struct LiveDeviceLinkView: View {
  @StateObject private var viewModel: LiveDeviceLinkViewModel
  @FocusState private var codeFocused: Bool

  init(service: LiveDeviceLinkServiceProtocol) {
    _viewModel = StateObject(wrappedValue: LiveDeviceLinkViewModel(service: service))
  }

  var body: some View {
    List {
      if let request = viewModel.request {
        decisionSection(request)
      } else if let outcome = viewModel.outcome {
        outcomeSection(outcome)
      } else {
        codeSection
      }
    }
    .liveGroupedList()
    .navigationTitle("Sign in another device")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear { codeFocused = viewModel.request == nil && viewModel.outcome == nil }
  }

  private var codeSection: some View {
    LiveSection {
      TextField("Device code", text: $viewModel.code)
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .font(.title3.monospaced())
        .submitLabel(.continue)
        .focused($codeFocused)
        .onSubmit { Task { await viewModel.lookUp() } }
        .accessibilityIdentifier("live.device-link.code")
      Button {
        Task { await viewModel.lookUp() }
      } label: {
        HStack {
          Text("Continue")
          Spacer()
          if viewModel.isBusy { ProgressView() }
        }
      }
      .disabled(!viewModel.canLookUp)
      .accessibilityIdentifier("live.device-link.continue")
    } footer: {
      footer("Enter the code shown on your TV or other device.")
    }
  }

  private func decisionSection(_ request: LiveDeviceLinkRequest) -> some View {
    LiveSection {
      Label {
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: request.deviceName.isEmpty ? request.userCode : request.deviceName)
          Text("Sign in this device with your account?")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      } icon: {
        Image(systemName: "tv")
          .foregroundStyle(.tint)
      }
      Button("Sign it in") { Task { await viewModel.approve() } }
        .disabled(viewModel.isBusy)
        .accessibilityIdentifier("live.device-link.approve")
      Button("Refuse", role: .destructive) { Task { await viewModel.deny() } }
        .disabled(viewModel.isBusy)
    } footer: {
      footer("Only sign in a device you are using yourself.")
    }
  }

  private func outcomeSection(_ outcome: LiveDeviceLinkViewModel.Outcome) -> some View {
    LiveSection {
      Label(
        outcome == .approved ? "The device is signed in." : "The sign-in was refused.",
        systemImage: outcome == .approved ? "checkmark.circle.fill" : "xmark.circle"
      )
      .foregroundStyle(outcome == .approved ? Color.green : Color.secondary)
      Button("Sign in another device") {
        viewModel.reset()
        codeFocused = true
      }
    }
  }

  private func footer(_ hint: LocalizedStringKey) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      if let failure = viewModel.failure {
        Text(failure)
          .foregroundStyle(.red)
      }
      Text(hint)
    }
    .font(.footnote)
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
