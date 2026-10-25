import SwiftUI

struct DemoHomeFeedView: View {
  let onSignOut: () -> Void
  @EnvironmentObject var session: DemoSessionStore
  @State var selectedVideo: DemoVideo?
  @State var presentsSearch: Bool
  @State var presentsNotifications = false
  @State var presentsProfile = false
  @State var recommendationLimit = 3
  @State var isLoadingMore = false

  init(
    onSignOut: @escaping () -> Void,
    initialVideo: DemoVideo? = nil,
    initiallyPresentsSearch: Bool = false
  ) {
    self.onSignOut = onSignOut
    _selectedVideo = State(initialValue: initialVideo)
    _presentsSearch = State(initialValue: initiallyPresentsSearch)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 30) {
          if showsContinueWatchingSection {
            continueWatching
          }
          if session.preferences.showsRecommendations {
            recommendations
          } else if showsContinueWatchingSection {
            Label("Recommendations are hidden", systemImage: "eye.slash")
              .font(.caption)
              .foregroundStyle(.secondary)
              .accessibilityIdentifier("demo.home.recommendations.hidden")
          }
          if !showsContinueWatchingSection
            && !session.preferences.showsRecommendations {
            ContentUnavailableView(
              "Home is quiet",
              systemImage: "moon.stars",
              description: Text("Enable a discovery surface in More → Discovery & services.")
            ).liveThemedEmptyState()
            .frame(maxWidth: .infinity)
            .padding(.top, 90)
          }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 28)
      }
      .background(Color(uiColor: .systemBackground))
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarBackground(
        Color(uiColor: .systemBackground).opacity(0.96),
        for: .navigationBar
      )
      .toolbar {
        leadingToolbar
        trailingToolbar
      }
      .navigationDestination(item: $selectedVideo) { video in
        DemoWatchView(video: video)
      }
      .fullScreenCover(isPresented: $presentsSearch) {
        DemoSearchView()
      }
      .sheet(isPresented: $presentsNotifications) {
        DemoNotificationsView()
      }
      .sheet(isPresented: $presentsProfile) {
        DemoProfileView()
      }
    }
  }

  func select(_ video: DemoVideo) {
    selectedVideo = video
  }

  private var showsContinueWatchingSection: Bool {
    session.preferences.showsContinueWatching
      && !visibleContinueWatching.isEmpty
  }
}
