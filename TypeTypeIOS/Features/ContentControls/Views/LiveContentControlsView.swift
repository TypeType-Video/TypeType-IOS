import SwiftUI

struct LiveContentControlsView: View {
  let service: LiveContentControlsServiceProtocol
  let canCreateGlobal: Bool

  var body: some View {
    List {
      LiveSection {
        ForEach(LiveContentControlKind.allCases) { kind in
          NavigationLink {
            if kind == .blockedKeywords {
              LiveBlockedKeywordsView(service: service)
                .navigationTitle("Blocked keywords")
                .navigationBarTitleDisplayMode(.inline)
            } else {
              LiveContentControlListView(kind: kind, service: service, canCreateGlobal: canCreateGlobal)
            }
          } label: {
            LiveSettingsRowLabel(title: kind.title, subtitle: kind.summary, icon: kind.icon)
          }
        }
      }
    }
    .liveGroupedList()
    .navigationTitle("Blocked")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct LiveContentControlListView: View {
  let kind: LiveContentControlKind
  let canCreateGlobal: Bool
  @StateObject private var viewModel: LiveContentControlsViewModel
  @State private var addsItem = false
  @Environment(\.themePalette) private var palette

  init(kind: LiveContentControlKind, service: LiveContentControlsServiceProtocol, canCreateGlobal: Bool) {
    self.kind = kind
    self.canCreateGlobal = canCreateGlobal
    _viewModel = StateObject(wrappedValue: LiveContentControlsViewModel(service: service, kind: kind))
  }

  var body: some View {
    content
      .navigationTitle(LocalizedStringKey(kind.title))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Add", systemImage: "plus") { addsItem = true }
        }
      }
      .task { await viewModel.prepare() }
      .sheet(isPresented: $addsItem) {
        LiveContentControlEditor(kind: kind, canCreateGlobal: canCreateGlobal, onSave: viewModel.add)
      }
      .alert("Blocked", isPresented: errorBinding) {
        Button("OK") { viewModel.dismissError() }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state {
    case .idle, .loading:
      TypeTypeSkeletonList(layout: .rows, count: 6)
    case let .failed(message):
      ContentUnavailableView {
        Label("Content controls unavailable", systemImage: "hand.raised.slash")
      } description: {
        Text(message)
      } actions: {
        Button("Try again") { Task { await viewModel.reload() } }
      }
      .liveThemedEmptyState()
    case .loaded where viewModel.items.isEmpty:
      ContentUnavailableView {
        Label(kind.emptyTitle, systemImage: kind.icon)
      } description: {
        Text(LocalizedStringKey(kind.summary))
      } actions: {
        Button(kind.addTitle) { addsItem = true }
      }
      .liveThemedEmptyState()
    case .loaded:
      List {
        LiveSection {
          ForEach(viewModel.items) { item in
            row(item)
              .swipeActions {
                Button("Remove", role: .destructive) {
                  Task { await viewModel.remove(item) }
                }
              }
          }
        }
      }
      .liveGroupedList()
      .refreshable { await viewModel.reload() }
    }
  }

  private func row(_ item: LiveContentControlItem) -> some View {
    HStack(spacing: 12) {
      LiveRemoteImage(url: item.thumbnailURL.flatMap(URL.init(string:)))
        .frame(width: kind == .blockedVideos ? 72 : 44, height: 44)
        .clipShape(kind == .blockedVideos
          ? AnyShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          : AnyShape(Circle()))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        Text(item.name ?? item.serviceName)
          .font(.headline)
          .lineLimit(2)
        HStack(spacing: 6) {
          Text(item.serviceName)
          if item.global == true {
            Text("Global")
              .fontWeight(.semibold)
              .foregroundStyle(palette.accent)
          }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
    .accessibilityElement(children: .combine)
  }

  private var errorBinding: Binding<Bool> {
    Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.dismissError() } })
  }
}
