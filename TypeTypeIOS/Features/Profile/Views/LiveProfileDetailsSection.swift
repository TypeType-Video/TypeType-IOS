import SwiftUI

struct LiveProfileDetailsSection: View {
  @ObservedObject var viewModel: LiveProfileViewModel

  var body: some View {
    Section("Public profile") {
      TextField("Public username", text: $viewModel.publicUsername)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .accessibilityIdentifier("live.profile.username")
      TextField(
        "Bio",
        text: $viewModel.bio,
        axis: .vertical
      )
      .lineLimit(3...7)
      .accessibilityIdentifier("live.profile.bio")
      HStack {
        Text("Visible to people who open your public profile.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(viewModel.bio.count)/500")
          .font(.caption.monospacedDigit())
          .foregroundStyle(
            viewModel.bio.count > 500 ? .red : .secondary
          )
      }
      Button {
        Task { await viewModel.saveProfile() }
      } label: {
        if viewModel.isSaving {
          ProgressView()
            .frame(maxWidth: .infinity)
        } else {
          Text("Save public profile")
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(
        viewModel.isSaving
          || viewModel.publicUsername.count > 64
          || viewModel.bio.count > 500
      )
      .accessibilityIdentifier("live.profile.save")
    }
  }
}
