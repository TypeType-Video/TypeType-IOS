import SwiftUI

struct ShortsView: View {
  @ObservedObject var coordinator: RootCoordinator
  @StateObject private var viewModel: ShortsViewModel
  @State private var serviceID: Int = DefaultServiceStore.get()
  @State private var lastVisibleVideoURL: String?

  init(coordinator: RootCoordinator) {
    self.coordinator = coordinator
    _viewModel = StateObject(
      wrappedValue: ShortsViewModel(
        service: coordinator.dependencies.shortsService,
        blockedService: coordinator.dependencies.blockedService
      )
    )
  }

  private func loadDefaultServiceID() async {
    do {
      let settings = try await coordinator.dependencies.userSettingsService.get()
      serviceID = settings.defaultService
      DefaultServiceStore.set(settings.defaultService)
    } catch {
      serviceID = DefaultServiceStore.get()
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if viewModel.isLoading && viewModel.items.isEmpty {
          ProgressView("Loading shorts...")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if viewModel.items.isEmpty {
          ContentUnavailableView("No shorts yet", systemImage: "play.tv", description: Text("Try again in a moment."))
        } else {
          TabView(selection: $viewModel.activeIndex) {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { pair in
              let index = pair.offset
              let item = pair.element
              VStack(spacing: 8) {
                HomeVideoRowView(video: item)
                NavigationLink {
                  WatchView(
                    videoURL: item.url,
                    coordinator: coordinator,
                    watchService: coordinator.dependencies.watchService,
                    watchProgressService: coordinator.dependencies.watchProgressService,
                    watchActionsService: coordinator.dependencies.watchActionsService,
                    recommendationFeedbackService: coordinator.dependencies.recommendationFeedbackService
                  )
                } label: {
                  Label("Open short", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)

                if viewModel.canLoadMore,
                  index >= max(0, viewModel.items.count - 3),
                  !viewModel.isLoadingMore {
                  Button("Load more") {
                    Task { await viewModel.loadMore(serviceID: serviceID) }
                  }
                  .buttonStyle(.bordered)
                }

                Button("Not interested") {
                  Task {
                    await coordinator.dependencies.recommendationFeedbackService.sendFeedback(
                      type: .notInterested,
                      videoURL: item.url,
                      uploaderURL: item.uploaderUrl
                    )
                    lastVisibleVideoURL = nil
                    viewModel.hideCurrent(index: index)
                  }
                }
                .buttonStyle(.bordered)

                if !item.uploaderUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                  Button("Less from channel") {
                    Task {
                      await coordinator.dependencies.recommendationFeedbackService.sendFeedback(
                        type: .lessFromChannel,
                        videoURL: item.url,
                        uploaderURL: item.uploaderUrl
                      )
                      lastVisibleVideoURL = nil
                      viewModel.hideCurrent(index: index)
                    }
                  }
                  .buttonStyle(.bordered)
                }
              }
              .padding()
              .tag(index)
              .task {
                await coordinator.dependencies.recommendationFeedbackService.sendEvent(
                  type: .impression,
                  videoURL: item.url,
                  uploaderURL: item.uploaderUrl,
                  title: item.title,
                  watchRatio: nil,
                  watchDurationMs: nil
                )
                lastVisibleVideoURL = item.url
              }
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .always))
          .onChange(of: viewModel.activeIndex) { _, newIndex in
            if let previous = lastVisibleVideoURL,
              let previousItem = viewModel.items.first(where: { $0.url == previous }) {
              Task {
                await coordinator.dependencies.recommendationFeedbackService.sendEvent(
                  type: .shortSkip,
                  videoURL: previousItem.url,
                  uploaderURL: previousItem.uploaderUrl,
                  title: previousItem.title,
                  watchRatio: nil,
                  watchDurationMs: nil
                )
              }
            }
            if viewModel.items.indices.contains(newIndex) {
              lastVisibleVideoURL = viewModel.items[newIndex].url
            }
            viewModel.prefetchIfNeeded(activeIndex: newIndex, serviceID: serviceID)
          }
        }
      }
      .navigationTitle("Shorts")
      .onDisappear {
        lastVisibleVideoURL = nil
      }
    }
    .task {
      RecommendationContextStore.set(intent: "shorts")
      await coordinator.dependencies.recommendationFeedbackService.resetEventDeduper()
      await loadDefaultServiceID()
      await viewModel.loadInitial(serviceID: serviceID)
    }
    .task(id: coordinator.selectedServer?.id) {
      RecommendationContextStore.set(intent: "shorts")
      await coordinator.dependencies.recommendationFeedbackService.resetEventDeduper()
      await loadDefaultServiceID()
      await viewModel.loadInitial(serviceID: serviceID)
    }
  }
}
