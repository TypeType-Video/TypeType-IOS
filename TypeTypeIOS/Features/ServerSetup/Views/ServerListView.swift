import SwiftUI

struct ServerListView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel = ServerListViewModel()

  var body: some View {
    NavigationStack {
      List {
        if coordinator.servers.isEmpty {
          Text("No server configured yet.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(coordinator.servers) { server in
            Button {
              coordinator.setSelectedServer(server)
            } label: {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(server.name)
                    .font(.headline)
                  Text(server.baseURLString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if coordinator.selectedServer?.id == server.id {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                }
              }
            }
            .swipeActions {
              Button(role: .destructive) {
                coordinator.deleteServer(server)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
            .contextMenu {
              Button {
                viewModel.openEditServer(server)
              } label: {
                Label("Edit", systemImage: "pencil")
              }
            }
          }
        }
      }
      .navigationTitle("Servers")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            viewModel.openAddServerSheet()
          } label: {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .sheet(isPresented: $viewModel.isPresentingConnectServer) {
        ConnectServerView(coordinator: coordinator)
      }
      .sheet(item: $viewModel.editingServer) { server in
        EditServerView(server: server, coordinator: coordinator)
      }
    }
    .transition(.move(edge: .leading).combined(with: .opacity))
  }
}
