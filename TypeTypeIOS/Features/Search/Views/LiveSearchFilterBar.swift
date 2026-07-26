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
            service.name,
            selected: service.id == viewModel.selectedServiceID
          )
        }
      }
    } label: {
      filterLabel(
        selectedService.name,
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
          "All content",
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
            filter.displayName,
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
          "Default order",
          selected: viewModel.selectedSortFilter == nil
        )
      }
      ForEach(viewModel.filters.sortFilters) { filter in
        Button {
          Task { await viewModel.selectSortFilter(filter.value) }
        } label: {
          menuLabel(
            filter.displayName,
            selected: filter.value == viewModel.selectedSortFilter
          )
        }
      }
    } label: {
      filterLabel(sortTitle, systemImage: "arrow.up.arrow.down")
    }
  }

  private func filterLabel(
    _ title: String,
    systemImage: String
  ) -> some View {
    Label(title, systemImage: systemImage)
      .font(.caption.weight(.semibold))
      .padding(.horizontal, 11)
      .padding(.vertical, 8)
      .background(DemoTheme.surface, in: Capsule())
  }

  private func menuLabel(
    _ title: String,
    selected: Bool
  ) -> some View {
    selected
      ? Label(title, systemImage: "checkmark")
      : Label(title, systemImage: "circle")
  }

  private var selectedService: VideoService {
    viewModel.services.first {
      $0.id == viewModel.selectedServiceID
    } ?? viewModel.services[0]
  }

  private var contentTitle: String {
    viewModel.visibleContentFilters.first {
      $0.value == viewModel.selectedContentFilter
    }?.displayName ?? "All content"
  }

  private var sortTitle: String {
    viewModel.filters.sortFilters.first {
      $0.value == viewModel.selectedSortFilter
    }?.displayName ?? "Default order"
  }
}
