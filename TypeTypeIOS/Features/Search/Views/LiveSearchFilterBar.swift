import SwiftUI

struct LiveSearchFilterBar: View {
  @Environment(\.themePalette) private var palette
  @ObservedObject var viewModel: LiveSearchViewModel
  let showsResultFilters: Bool

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        if viewModel.services.count > 1 {
          serviceMenu
        }
        if showsResultFilters, !viewModel.visibleContentFilters.isEmpty {
          contentMenu
        }
        if showsResultFilters, !viewModel.filters.sortFilters.isEmpty {
          sortMenu
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 4)
      .padding(.bottom, 8)
    }
    .scrollIndicators(.hidden)
    .accessibilityIdentifier("live.search.filters")
  }

  private var serviceMenu: some View {
    Menu {
      Picker("Service", selection: Binding(
        get: { viewModel.selectedServiceID },
        set: { id in Task { await viewModel.selectService(id) } }
      )) {
        ForEach(viewModel.services) { service in
          Label { Text(verbatim: service.name) } icon: { Image(systemName: service.systemImage) }
            .tag(service.id)
        }
      }
      .pickerStyle(.inline)
    } label: {
      chip(Text(verbatim: selectedService?.name ?? ""), systemImage: selectedService?.systemImage ?? "globe")
    }
    .accessibilityLabel(Text("Service"))
    .accessibilityValue(Text(verbatim: selectedService?.name ?? ""))
    .accessibilityIdentifier("live.search.service")
  }

  private var contentMenu: some View {
    Menu {
      Picker("Content", selection: Binding(
        get: { viewModel.selectedContentFilter },
        set: { value in Task { await viewModel.selectContentFilter(value) } }
      )) {
        Text("All content").tag(String?.none)
        ForEach(viewModel.visibleContentFilters, id: \.value) { filter in
          Text(verbatim: filter.displayName).tag(Optional(filter.value))
        }
      }
      .pickerStyle(.inline)
    } label: {
      chip(contentTitle, systemImage: "line.3.horizontal.decrease", isActive: viewModel.selectedContentFilter != nil)
    }
    .accessibilityLabel(Text("Content"))
    .accessibilityIdentifier("live.search.content-filter")
  }

  private var sortMenu: some View {
    Menu {
      Picker("Order", selection: Binding(
        get: { viewModel.selectedSortFilter },
        set: { value in Task { await viewModel.selectSortFilter(value) } }
      )) {
        Text("Default order").tag(String?.none)
        ForEach(sortGroups, id: \.name) { group in
          Section(group.name) {
            ForEach(group.options, id: \.value) { filter in
              Text(verbatim: filter.displayName).tag(Optional(filter.value))
            }
          }
        }
      }
      .pickerStyle(.inline)
    } label: {
      chip(sortTitle, systemImage: "arrow.up.arrow.down", isActive: viewModel.selectedSortFilter != nil)
    }
    .accessibilityLabel(Text("Order"))
    .accessibilityIdentifier("live.search.sort-filter")
  }

  private func chip(_ title: Text, systemImage: String, isActive: Bool = false) -> some View {
    HStack(spacing: 5) {
      Image(systemName: systemImage)
      title
      Image(systemName: "chevron.down")
        .font(.caption2.weight(.bold))
    }
    .font(.subheadline.weight(.medium))
    .foregroundStyle(isActive ? palette.accent : .primary)
    .padding(.horizontal, 12)
    .frame(height: 34)
    .background(
      isActive ? palette.accent.opacity(0.15) : palette.surface,
      in: RoundedRectangle(cornerRadius: 10, style: .continuous)
    )
  }

  private var sortGroups: [(name: String, options: [LiveSearchFilterOption])] {
    var groups: [(name: String, options: [LiveSearchFilterOption])] = []
    for filter in viewModel.filters.sortFilters where filter.displayName.lowercased() != "all" {
      let name = filter.groupName ?? ""
      if let index = groups.firstIndex(where: { $0.name == name }) {
        groups[index].options.append(filter)
      } else {
        groups.append((name, [filter]))
      }
    }
    return groups
  }

  private var selectedService: VideoService? {
    viewModel.services.first { $0.id == viewModel.selectedServiceID } ?? viewModel.services.first
  }

  private var contentTitle: Text {
    if let selected = viewModel.visibleContentFilters.first(where: { $0.value == viewModel.selectedContentFilter }) {
      return Text(verbatim: selected.displayName)
    }
    return Text("All content")
  }

  private var sortTitle: Text {
    if let selected = viewModel.filters.sortFilters.first(where: { $0.value == viewModel.selectedSortFilter }) {
      return Text(verbatim: selected.displayName)
    }
    return Text("Default order")
  }
}
