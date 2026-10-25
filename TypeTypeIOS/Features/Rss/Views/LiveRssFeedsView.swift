import SwiftUI

struct LiveRssFeedsView: View {
  @StateObject private var viewModel: LiveRssFeedsViewModel
  @State private var presentsEditor = false

  init(
    feedService: LiveRssFeedServiceProtocol,
    subscriptionsService: LiveSubscriptionsServiceProtocol
  ) {
    _viewModel = StateObject(
      wrappedValue: LiveRssFeedsViewModel(
        feedService: feedService,
        subscriptionsService: subscriptionsService
      )
    )
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        ProgressView("Loading RSS feeds")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case let .failed(message):
        ContentUnavailableView {
          Label("RSS unavailable", systemImage: "dot.radiowaves.left.and.right")
        } description: {
          Text(message)
        } actions: {
          Button("Try again") { Task { await viewModel.reload() } }
        }
      case .loaded:
        feedList
      }
    }
    .navigationTitle("RSS feeds")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Add") {
          viewModel.startCreate()
          presentsEditor = true
        }
        .accessibilityIdentifier("live.rss.add")
      }
    }
    .task { await viewModel.prepare() }
    .refreshable { await viewModel.reload() }
    .sheet(isPresented: $presentsEditor) { editor }
    .alert("RSS feeds", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .accessibilityIdentifier("live.rss.screen")
  }

  @ViewBuilder private var feedList: some View {
    if viewModel.feeds.isEmpty {
      ContentUnavailableView(
        "No RSS feeds",
        systemImage: "dot.radiowaves.left.and.right",
        description: Text("Create a private feed for your subscriptions.")
      )
    } else {
      List {
        ForEach(viewModel.feeds) { feed in
          row(feed)
        }
      }
        .id(DemoTheme.renderToken)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DemoTheme.background)
      .listStyle(.insetGrouped)
    }
  }

  private func row(_ feed: LiveRssFeed) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Toggle(feed.name, isOn: enabledBinding(feed))
        .disabled(viewModel.busyFeedIDs.contains(feed.id))
      Text(feed.scope == "channels" ? "Selected channels" : "All subscriptions")
        .font(.caption)
        .foregroundStyle(.secondary)
      HStack {
        Button("Copy URL") {
          UIPasteboard.general.string = viewModel.shareURL?.absoluteString
        }
        .disabled(viewModel.shareURL == nil)
        Button("Regenerate") {
          Task { await viewModel.regenerate(feed) }
        }
        Spacer()
        Button("Edit") {
          viewModel.startEdit(feed)
          presentsEditor = true
        }
        Button("Delete", role: .destructive) {
          Task { await viewModel.delete(feed) }
        }
      }
      .font(.caption)
      .buttonStyle(.borderless)
    }
    .padding(.vertical, 2)
    .opacity(feed.enabled ? 1 : 0.6)
  }

  @ViewBuilder private var editor: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Feed name", text: $viewModel.draftName)
          Toggle("Only selected channels", isOn: $viewModel.draftIncludesChannels)
        } header: { Text("Feed").liveSectionHeader() }
        if viewModel.draftIncludesChannels {
          Section {
            ForEach(viewModel.subscriptions) { subscription in
              Button {
                viewModel.toggleDraftChannel(subscription)
              } label: {
                HStack {
                  Text(subscription.name)
                  Spacer()
                  if viewModel.draftSelectedChannels.contains(subscription.channelURL) {
                    Image(systemName: "checkmark")
                  }
                }
              }
            }
          } header: { Text("Channels").liveSectionHeader() }
        }
        Section {
          Toggle("Shorts", isOn: $viewModel.draftIncludeShorts)
          Toggle("Live", isOn: $viewModel.draftIncludeLive)
          Toggle("Upcoming", isOn: $viewModel.draftIncludeUpcoming)
        } header: { Text("Content").liveSectionHeader() }
      }
        .id(DemoTheme.renderToken)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DemoTheme.background)
      .navigationTitle("RSS feed")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { presentsEditor = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            Task {
              await viewModel.save()
              if viewModel.errorMessage == nil {
                presentsEditor = false
              }
            }
          }
        }
      }
    }
  }

  private func enabledBinding(_ feed: LiveRssFeed) -> Binding<Bool> {
    Binding(
      get: { feed.enabled },
      set: { enabled in
        Task { await viewModel.setEnabled(enabled, for: feed) }
      }
    )
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
