import SwiftUI

struct LiveSearchBar: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var viewModel: LiveSearchViewModel
  var isFocused: FocusState<Bool>.Binding
  let onSubmit: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
        TextField("Videos, channels, playlists", text: $viewModel.query)
          .focused(isFocused)
          .submitLabel(.search)
          .onSubmit(onSubmit)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.never)
          .accessibilityLabel(Text("Search"))
          .accessibilityIdentifier("live.search.field")
        if !viewModel.query.isEmpty {
          Button {
            viewModel.query = ""
            viewModel.queryDidChange()
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .accessibilityLabel(Text("Clear search"))
        }
      }
      .padding(.horizontal, 12)
      .frame(height: 44)
      .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

      if viewModel.services.count > 1 {
        serviceMenu
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }

  private var serviceMenu: some View {
    Menu {
      Picker("Service", selection: Binding(
        get: { viewModel.selectedServiceID },
        set: { id in Task { await viewModel.selectService(id) } }
      )) {
        ForEach(viewModel.services) { service in
          Label { Text(verbatim: service.name) } icon: { service.logo }
            .tag(service.id)
        }
      }
      .pickerStyle(.inline)
    } label: {
      HStack(spacing: 4) {
        if let selectedService {
          LiveServiceLogo(service: selectedService)
        }
        Image(systemName: "chevron.down")
          .font(.caption2.weight(.bold))
          .foregroundStyle(.secondary)
      }
      .foregroundStyle(palette.accent)
      .padding(.horizontal, 12)
      .frame(height: 44)
      .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .accessibilityLabel(Text("Service"))
    .accessibilityValue(Text(verbatim: selectedService?.name ?? ""))
    .accessibilityIdentifier("live.search.service")
  }

  private var selectedService: VideoService? {
    viewModel.services.first { $0.id == viewModel.selectedServiceID } ?? viewModel.services.first
  }
}
