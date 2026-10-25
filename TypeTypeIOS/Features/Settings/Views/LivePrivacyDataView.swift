import SwiftUI

struct LivePrivacyDataView: View {
  @StateObject private var viewModel: LivePrivacyDataViewModel
  @State private var confirmation: Action?

  init(
    history: LiveHistoryServiceProtocol,
    searchHistory: LiveSearchHistoryServiceProtocol,
    subscriptions: LiveSubscriptionsServiceProtocol
  ) {
    _viewModel = StateObject(
      wrappedValue: LivePrivacyDataViewModel(
        history: history,
        searchHistory: searchHistory,
        subscriptions: subscriptions
      )
    )
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        ProgressView("Loading stored data")
      case let .failed(message):
        ContentUnavailableView {
          Label("Stored data unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
          Text(message)
        } actions: {
          Button("Try again") { Task { await viewModel.reload() } }
        }
      case .loaded:
        list
      }
    }
    .navigationTitle("Stored data")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.prepare() }
    .confirmationDialog(
      confirmation?.title ?? "",
      isPresented: Binding(
        get: { confirmation != nil },
        set: { if !$0 { confirmation = nil } }
      ),
      titleVisibility: .visible
    ) {
      if let confirmation {
        Button(confirmation.button, role: .destructive) {
          perform(confirmation)
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone.")
    }
  }

  private var list: some View {
    List {
      Section {
        dataRow(
          "Watch history",
          count: viewModel.historyCount,
          action: .history
        )
        dataRow(
          "Search history",
          count: viewModel.searchHistoryCount,
          action: .search
        )
        dataRow(
          "Subscriptions",
          count: viewModel.subscriptions.count,
          action: .subscriptions
        )
      } footer: {
        Text("These actions update the selected TypeType instance.").liveSectionSlotChrome()
      }
      if let message = viewModel.message {
        Section {
          Label(message, systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green)
        }
      }
    }
      .liveThemedList()
      .id(DemoTheme.renderToken)
    .refreshable { await viewModel.reload() }
  }

  private func dataRow(
    _ title: String,
    count: Int,
    action: Action
  ) -> some View {
    HStack {
      VStack(alignment: .leading) {
        Text(title)
        Text("\(count) \(count == 1 ? "item" : "items")")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button(action.button, role: .destructive) {
        confirmation = action
      }
      .disabled(count == 0 || viewModel.isBusy)
    }
  }

  private func perform(_ action: Action) {
    confirmation = nil
    Task {
      switch action {
      case .history: await viewModel.clearHistory()
      case .search: await viewModel.clearSearchHistory()
      case .subscriptions: await viewModel.unsubscribeAll()
      }
    }
  }

  private enum Action: String {
    case history, search, subscriptions

    var title: String {
      switch self {
      case .history: return "Clear watch history?"
      case .search: return "Clear search history?"
      case .subscriptions: return "Unsubscribe from every channel?"
      }
    }

    var button: String {
      self == .subscriptions ? "Unsubscribe all" : "Clear"
    }
  }
}
