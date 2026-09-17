import SwiftUI

struct LiveSearchFilterBar: View {
  @ObservedObject var viewModel: LiveSearchViewModel

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

  private var serviceMenu: some View {
    Menu {
      ForEach(viewModel.services) { service in
        Button {
          Task { await viewModel.selectService(service.id) }
        } label: {
          menuLabel(
            Text(verbatim: service.name),
            selected: service.id == viewModel.selectedServiceID
          )
        }
      }
    } label: {
      filterLabel(
        Text(verbatim: selectedService.name),
        systemImage: selectedService.systemImage
      )
    }
    .accessibilityIdentifier("live.search.service")
  }

  private var contentMenu: some View {
    Menu {
      Button {
        Task { await viewModel.selectContentFilter(nil) }
      } label: {
          menuLabel(
            Text("All content"),
            selected: viewModel.selectedContentFilter == nil
        )
      }
      ForEach(viewModel.visibleContentFilters) { filter in
        Button {
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
      }
    } label: {
      filterLabel(contentTitle, systemImage: "line.3.horizontal.decrease")
    }
  }

  private var sortMenu: some View {
    Menu {
      Button {
        Task { await viewModel.selectSortFilter(nil) }
      } label: {
        menuLabel(
          Text("Default order"),
          selected: viewModel.selectedSortFilter == nil
        )
      }
      ForEach(viewModel.filters.sortFilters) { filter in
        Button {
          Task { await viewModel.selectSortFilter(filter.value) }
        } label: {
          menuLabel(
            Text(verbatim: filter.displayName),
            selected: filter.value == viewModel.selectedSortFilter
          )
        }
      }
    } label: {
      filterLabel(sortTitle, systemImage: "arrow.up.arrow.down")
    }
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
