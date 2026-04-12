import SwiftUI

struct RecommendationOnboardingView: View {
  @StateObject private var viewModel: RecommendationOnboardingViewModel

  init(coordinator: RootCoordinator, mode: RecommendationOnboardingViewModel.Mode = .settings) {
    _viewModel = StateObject(
      wrappedValue: RecommendationOnboardingViewModel(
        service: coordinator.dependencies.recommendationOnboardingService,
        subscriptionsService: coordinator.dependencies.subscriptionsService,
        mode: mode
      )
    )
  }

  var body: some View {
    List {
      headerSection
      topicsSection
      channelsSection
      if let error = viewModel.errorMessage {
        Section {
          Text(error)
            .font(.footnote)
            .foregroundStyle(.red)
        }
      }
      if let info = viewModel.infoMessage {
        Section {
          Text(info)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
      actionsSection
    }
    .navigationTitle("Recommendations")
    .task { await viewModel.load() }
    .refreshable { await viewModel.load() }
  }

  @ViewBuilder
  private var headerSection: some View {
    Section {
      Text(viewModel.mode == .onboarding ? "Tune your recommendations" : "Recommendation profile")
        .font(.headline)
      Text(
        viewModel.mode == .onboarding
          ? "Quick setup in two steps. You can skip now and fine tune later from settings."
          : "Adjust your interests and channels. Changes apply to recommendation seeding."
      )
      .font(.footnote)
      .foregroundStyle(.secondary)
      HStack {
        Label("Step \(viewModel.step + 1) of 2", systemImage: "list.number")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        if viewModel.requiresOnboarding {
          Text("Onboarding pending")
            .font(.caption)
            .foregroundStyle(.orange)
        } else {
          Text("Configured")
            .font(.caption)
            .foregroundStyle(.green)
        }
      }

      Picker("Stage", selection: Binding(
        get: { viewModel.step },
        set: { viewModel.selectStep($0) }
      )) {
        Text("Interests").tag(0)
        Text("Channels").tag(1)
      }
      .pickerStyle(.segmented)
    }
  }

  @ViewBuilder
  private var topicsSection: some View {
    if viewModel.step == 0 {
      Section("Step 1 - Interests") {
        Text("Pick at least \(viewModel.minTopics) topics.")
          .font(.footnote)
          .foregroundStyle(.secondary)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(viewModel.topicGroups) { group in
              Button(group.label) {
                viewModel.activeGroupID = group.id
              }
              .buttonStyle(.bordered)
              .tint(viewModel.activeGroupID == group.id ? TypeTypeColor.accent : .gray)
            }
          }
          .padding(.vertical, 2)
        }

        let active = viewModel.topicGroups.first(where: { $0.id == viewModel.activeGroupID }) ?? viewModel.topicGroups.first
        if let active {
          ForEach(active.topics, id: \.self) { topic in
            Button {
              viewModel.toggleTopic(topic)
            } label: {
              HStack {
                Text(topic)
                Spacer()
                if viewModel.selectedTopics.contains(where: { $0.caseInsensitiveCompare(topic) == .orderedSame }) {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(TypeTypeColor.accent)
                }
              }
            }
            .buttonStyle(.plain)
          }
        }

        HStack {
          Text("Selected")
            .foregroundStyle(.secondary)
          Spacer()
          Text("\(viewModel.selectedTopics.count)/\(viewModel.minTopics) minimum")
        }
        .font(.footnote)
      }
    }
  }

  @ViewBuilder
  private var channelsSection: some View {
    if viewModel.step == 1 {
      Section("Step 2 - Favorite channels") {
        Text("Add channel URLs you trust.")
          .font(.footnote)
          .foregroundStyle(.secondary)

        HStack {
          TextField("https://...", text: $viewModel.channelInput)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .textContentType(.URL)
            .keyboardType(.URL)
          Button("Add") {
            viewModel.addChannelFromInput()
          }
          .disabled(viewModel.channelInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }

        if viewModel.selectedChannels.isEmpty {
          Text("No channels selected yet.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        } else {
          ForEach(viewModel.selectedChannels, id: \.self) { channel in
            HStack {
              Text(channel)
                .lineLimit(1)
                .font(.footnote)
              Spacer()
              Button(role: .destructive) {
                viewModel.removeChannel(channel)
              } label: {
                Image(systemName: "xmark.circle.fill")
              }
              .buttonStyle(.borderless)
            }
          }
        }

        if !viewModel.suggestedChannels.isEmpty {
          Text("Suggested from subscriptions")
            .font(.footnote)
            .foregroundStyle(.secondary)
          ForEach(viewModel.suggestedChannels.prefix(12)) { channel in
            Button {
              viewModel.channelInput = channel.channelUrl
              viewModel.addChannelFromInput()
            } label: {
              HStack {
                Text(channel.name)
                Spacer()
                if viewModel.selectedChannels.contains(where: {
                  $0.caseInsensitiveCompare(channel.channelUrl) == .orderedSame
                }) {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(TypeTypeColor.accent)
                } else {
                  Text("Add")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  @ViewBuilder
  private var actionsSection: some View {
    Section {
      if viewModel.step == 0 {
        Button("Next") {
          viewModel.goToNextStep()
        }
        .disabled(!viewModel.canContinueFromTopics)
      }

      if viewModel.step == 1 {
        Button("Back") {
          viewModel.goToPreviousStep()
        }
      }

      Button(viewModel.isSaving ? "Saving..." : "Save preferences") {
        Task { await viewModel.save() }
      }
      .disabled(viewModel.isSaving || viewModel.isLoading)

      if viewModel.step == 1 {
        Button("Finish") {
          Task { await viewModel.finish() }
        }
        .disabled(viewModel.isSaving || viewModel.isLoading || !viewModel.canContinueFromTopics)
      }

      if viewModel.mode == .onboarding {
        Button("Skip for now") {
          Task { await viewModel.skip() }
        }
        .disabled(viewModel.isSaving || viewModel.isLoading)
      }
    }
  }
}
