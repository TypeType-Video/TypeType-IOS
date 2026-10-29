import SwiftUI

extension LivePlaylistDetailView {
  @ToolbarContentBuilder
  var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .topBarTrailing) {
      Menu {
        Picker("Sort", selection: $viewModel.sort) {
          ForEach(LivePlaylistDetailViewModel.Sort.allCases) {
            Text($0.title).tag($0)
          }
        }
        Divider()
        Button("Rename", systemImage: "pencil") {
          renamesPlaylist = true
        }
        Button(
          "Delete playlist",
          systemImage: "trash",
          role: .destructive
        ) {
          confirmsDeletion = true
        }
      } label: {
        Label("Playlist options", systemImage: "ellipsis.circle")
      }
      .liveConfirmPopover(
        isPresented: $confirmsDeletion,
        title: "Delete playlist?",
        message: "This action cannot be undone.",
        confirmTitle: "Delete"
      ) {
        Task {
          if await viewModel.delete() {
            onChanged()
            dismiss()
          }
        }
      }
      if viewModel.sort == .manual,
        viewModel.playlist?.videos.isEmpty == false {
        EditButton()
      }
    }
  }
}
