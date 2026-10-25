import SwiftUI

struct LiveContentControlsView: View {
  let canCreateGlobal: Bool
  @StateObject private var viewModel: LiveContentControlsViewModel
  @State private var addsItem = false

  init(
    service: LiveContentControlsServiceProtocol,
    canCreateGlobal: Bool
  ) {
    self.canCreateGlobal = canCreateGlobal
    _viewModel = StateObject(
      wrappedValue: LiveContentControlsViewModel(service: service)
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      Picker("Content controls", selection: kindBinding) {
        ForEach(LiveContentControlKind.allCases) {
          Text($0.title).tag($0)
        }
      }
      .pickerStyle(.segmented)
      .padding()
      content
    }
    .navigationTitle("Content controls")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        if viewModel.kind != .blockedKeywords {
          Button("Add", systemImage: "plus") { addsItem = true }
        }
      }
    }
    .task { await viewModel.prepare() }
    .sheet(isPresented: $addsItem) {
      LiveContentControlEditor(
        kind: viewModel.kind,
        canCreateGlobal: canCreateGlobal,
        onSave: viewModel.add
      )
    }
    .alert("Content controls", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
    case let .failed(message):
      ContentUnavailableView(
        "Content controls unavailable",
        systemImage: "hand.raised.slash",
        description: Text(message)
      )
    case .loaded:
      if viewModel.kind == .blockedKeywords {
        LiveBlockedKeywordsView(service: viewModel.service)
      } else {
      if viewModel.items.isEmpty {
        ContentUnavailableView(
          "No \(viewModel.kind.title.lowercased())",
          systemImage: "checkmark.shield"
        )
      } else {
        List(viewModel.items) { item in
          VStack(alignment: .leading, spacing: 3) {
            Text(item.name ?? item.url)
              .font(.headline)
            Text(item.url)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(2)
            if item.global == true {
              Text("Global")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(DemoTheme.accent)
            }
          }
          .swipeActions {
            Button("Remove", role: .destructive) {
              Task { await viewModel.remove(item) }
            }
          }
        }
        .listStyle(.plain)
        .liveThemedList()
        .refreshable { await viewModel.reload() }
      }
    }
    }
  }

  private var kindBinding: Binding<LiveContentControlKind> {
    Binding(
      get: { viewModel.kind },
      set: { kind in Task { await viewModel.select(kind) } }
    )
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
