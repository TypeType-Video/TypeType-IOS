import SwiftUI

extension LiveLibraryView {
  // Regular width: the sections become a sidebar and the chosen one fills the detail. The section models live on
  // LiveLibraryView, so a rotation between the two layouts keeps what is already loaded.
  var splitLayout: some View {
    NavigationSplitView {
      List {
        LiveSection {
          ForEach(LiveLibrarySection.allCases) { item in
            sidebarRow(item)
          }
        }
      }
      .liveGroupedList()
      .navigationTitle("Library")
    } detail: {
      NavigationStack {
        sectionContent(section)
          .navigationTitle(section.title)
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .primaryAction) { sectionAction }
          }
      }
      .id(section)
    }
  }

  private func sidebarRow(_ item: LiveLibrarySection) -> some View {
    Button {
      section = item
    } label: {
      Label {
        Text(item.title)
          .foregroundStyle(Color.primary)
      } icon: {
        Image(systemName: item.systemImage)
          .foregroundStyle(palette.accent)
      }
    }
    .listRowBackground(section == item ? palette.accent.opacity(0.16) : palette.rowBackground)
    .accessibilityAddTraits(section == item ? .isSelected : [])
    .accessibilityIdentifier("live.library.sidebar.\(item.rawValue)")
  }
}
