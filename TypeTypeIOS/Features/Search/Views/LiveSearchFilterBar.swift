import SwiftUI

struct LiveSearchFilterBar: View {
  @ObservedObject var viewModel: LiveSearchViewModel
  @State private var presentsService = false
  @State private var presentsContent = false
  @State private var presentsSort = false

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 10) {
        serviceMenu
        if !viewModel.visibleContentFilters.isEmpty {
          contentMenu
        }
        if !viewModel.filters.sortFilters.isEmpty {
          sortMenu
        }
      }
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.search.filters")
  }

  // Popovers, not system menus: the iOS 26/27 glass menu popup crashes
  // on item taps with `setEffect:` in this app.
  private var serviceMenu: some View {
    Button {
      presentsService = true
    } label: {
      filterLabel(
        Text(verbatim: selectedService.name),
        systemImage: selectedService.systemImage
      )
    }
    .buttonStyle(.plain)
    .popover(isPresented: $presentsService) {
      optionList(
        viewModel.services.map {
          (label: $0.name, selected: $0.id == viewModel.selectedServiceID)
        }
      ) { index in
        presentsService = false
        let service = viewModel.services[index]
        Task { await viewModel.selectService(service.id) }
      }
    }
    .accessibilityIdentifier("live.search.service")
  }

  private var contentMenu: some View {
    Button {
      presentsContent = true
    } label: {
      filterLabel(contentTitle, systemImage: "line.3.horizontal.decrease")
    }
    .buttonStyle(.plain)
    .popover(isPresented: $presentsContent) {
      optionList(
        [(label: "All content", selected: viewModel.selectedContentFilter == nil)]
          + viewModel.visibleContentFilters.map {
            (
              label: $0.displayName,
              selected: $0.value == viewModel.selectedContentFilter
            )
          }
      ) { index in
        presentsContent = false
        let value = index == 0
          ? nil
          : viewModel.visibleContentFilters[index - 1].value
        Task { await viewModel.selectContentFilter(value) }
      }
    }
    .accessibilityIdentifier("live.search.content-filter")
  }

  private var sortMenu: some View {
    Button {
      presentsSort = true
    } label: {
      filterLabel(sortTitle, systemImage: "arrow.up.arrow.down")
    }
    .buttonStyle(.plain)
    .popover(isPresented: $presentsSort) {
      optionList(
        [(label: "Default order", selected: viewModel.selectedSortFilter == nil)]
          + viewModel.filters.sortFilters.map {
            (
              label: $0.displayName,
              selected: $0.value == viewModel.selectedSortFilter
            )
          }
      ) { index in
        presentsSort = false
        let value = index == 0
          ? nil
          : viewModel.filters.sortFilters[index - 1].value
        Task { await viewModel.selectSortFilter(value) }
      }
    }
    .accessibilityIdentifier("live.search.sort-filter")
  }

  /// Glass popover with checkmark rows and hairline dividers — the
  /// LiveOptionMenu recipe. `presentationCompactAdaptation(.popover)` is
  /// what keeps it a bubble on iPhone instead of a full-height sheet.
  private func optionList(
    _ options: [(label: String, selected: Bool)],
    onSelect: @escaping (Int) -> Void
  ) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(options.enumerated()), id: \.offset) { index, option in
        Button {
          onSelect(index)
        } label: {
          HStack(spacing: 12) {
            Text(verbatim: option.label)
              .foregroundStyle(.primary)
            Spacer(minLength: 12)
            if option.selected {
              Image(systemName: "checkmark")
                .foregroundStyle(DemoTheme.accent)
            }
          }
          .padding(.horizontal, 16)
          .frame(minHeight: 44)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        if index < options.count - 1 {
          Rectangle()
            .fill(DemoTheme.separator)
            .frame(height: 1)
            .padding(.horizontal, 16)
        }
      }
    }
    .frame(width: 280)
    .presentationCompactAdaptation(.popover)
  }

  private func filterLabel(
    _ title: Text,
    systemImage: String
  ) -> some View {
    Label {
      title
    } icon: {
      Image(systemName: systemImage)
    }
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 11)
      .padding(.vertical, 8)
      .background(DemoTheme.surface, in: Capsule())
  }

  private var selectedService: VideoService {
    viewModel.services.first {
      $0.id == viewModel.selectedServiceID
    } ?? viewModel.services[0]
  }

  private var contentTitle: Text {
    if let selected = viewModel.visibleContentFilters.first(where: {
      $0.value == viewModel.selectedContentFilter
    }) {
      return Text(verbatim: selected.displayName)
    }
    return Text("All content")
  }

  private var sortTitle: Text {
    if let selected = viewModel.filters.sortFilters.first(where: {
      $0.value == viewModel.selectedSortFilter
    }) {
      return Text(verbatim: selected.displayName)
    }
    return Text("Default order")
  }
}
