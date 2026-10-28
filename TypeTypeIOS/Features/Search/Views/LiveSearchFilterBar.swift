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
      VStack(alignment: .leading, spacing: 2) {
        ForEach(viewModel.services) { service in
          Button {
            presentsService = false
            Task { await viewModel.selectService(service.id) }
          } label: {
            menuLabel(
              Text(verbatim: service.name),
              selected: service.id == viewModel.selectedServiceID
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(12)
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
      VStack(alignment: .leading, spacing: 2) {
        Button {
          presentsContent = false
          Task { await viewModel.selectContentFilter(nil) }
        } label: {
          menuLabel(
            Text("All content"),
            selected: viewModel.selectedContentFilter == nil
          )
        }
        .buttonStyle(.plain)
        ForEach(viewModel.visibleContentFilters) { filter in
          Button {
            presentsContent = false
            Task {
              await viewModel.selectContentFilter(filter.value)
            }
          } label: {
            menuLabel(
              Text(verbatim: filter.displayName),
              selected:
                filter.value == viewModel.selectedContentFilter
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(12)
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
      VStack(alignment: .leading, spacing: 2) {
        Button {
          presentsSort = false
          Task { await viewModel.selectSortFilter(nil) }
        } label: {
          menuLabel(
            Text("Default order"),
            selected: viewModel.selectedSortFilter == nil
          )
        }
        .buttonStyle(.plain)
        ForEach(viewModel.filters.sortFilters) { filter in
          Button {
            presentsSort = false
            Task {
              await viewModel.selectSortFilter(filter.value)
            }
          } label: {
            menuLabel(
              Text(verbatim: filter.displayName),
              selected:
                filter.value == viewModel.selectedSortFilter
            )
          }
          .buttonStyle(.plain)
        }
      }
      .padding(12)
    }
    .accessibilityIdentifier("live.search.sort-filter")
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

  private func menuLabel(
    _ title: Text,
    selected: Bool
  ) -> some View {
    selected
      ? Label {
          title
        } icon: {
          Image(systemName: "checkmark")
        }
      : Label {
          title
        } icon: {
          Image(systemName: "circle")
        }
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
