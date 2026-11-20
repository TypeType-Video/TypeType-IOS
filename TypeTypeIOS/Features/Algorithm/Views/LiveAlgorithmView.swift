import SwiftUI

struct LiveAlgorithmView: View {
  @StateObject private var model: LiveAlgorithmViewModel

  init(service: LiveRecommenderServiceProtocol, feedback: LiveRecommenderFeedbackServiceProtocol?) {
    _model = StateObject(wrappedValue: LiveAlgorithmViewModel(service: service, feedback: feedback))
  }

  var body: some View {
    List {
      if model.loaded {
        content
      } else if let error = model.error {
        Text(verbatim: error).foregroundStyle(.secondary)
        Button("Try again") { Task { await model.load() } }
      } else {
        ProgressView().frame(maxWidth: .infinity)
      }
    }
    .liveGroupedList()
    .navigationTitle("Algorithm")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.load() }
    .accessibilityIdentifier("live.algorithm")
  }

  @ViewBuilder
  private var content: some View {
    LiveSection {
      Toggle("Build my home page with an algorithm I choose", isOn: Binding(get: { model.settings.enabled }, set: model.setEnabled))
        .accessibilityIdentifier("live.algorithm.enabled")
    } header: {
      HStack {
        Text("Home page by algorithm").liveSectionHeader()
        Text("Experimental").font(.caption2.weight(.semibold)).foregroundStyle(.tint)
      }
    } footer: {
      (model.settings.enabled ? Text("On. Turn it off to get the standard home page back.") : Text("Off. You keep the standard home page until you turn it on."))
        .liveSettingsFooter()
    }
    if model.settings.enabled {
      LiveSection {
        ForEach(model.algorithms) { algorithm in
          Button { model.select(algorithm.id) } label: {
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: algorithm.name).font(.body.weight(.semibold))
                Text(verbatim: algorithm.description).font(.footnote).foregroundStyle(.secondary)
              }
              Spacer()
              if algorithm.id == model.current?.id { Image(systemName: "checkmark").foregroundStyle(.tint) }
            }
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(algorithm.id == model.current?.id ? .isSelected : [])
        }
      } header: {
        Text("Home page algorithm").liveSectionHeader()
      } footer: {
        Text("The algorithm decides which videos appear on your home page and in what order. Nothing else changes: search, subscriptions and history stay the same.")
          .liveSettingsFooter()
      }
      if let current = model.current {
        if let guide = current.guide {
          LiveSection {
            Text(verbatim: guide.forYouIf)
            Text(verbatim: guide.youWillSee)
            Text(verbatim: guide.goodToKnow).foregroundStyle(.secondary)
          }
          .font(.subheadline)
        }
        if !current.parameters.isEmpty {
          LiveSection {
            NavigationLink { LiveAlgorithmParametersView(model: model, algorithm: current) } label: {
              Text("\(current.name) settings")
            }
          }
        }
      }
    }
    LiveSection {
      NavigationLink { LiveAlgorithmDataView(model: model) } label: {
        LiveSettingText(title: "Data used", detail: "Review collected data and choose what the algorithm may use.")
      }
      NavigationLink { LiveAlgorithmTraceView(model: model) } label: {
        LiveSettingText(title: "How the last home page was built", detail: "Why each row is on the home page.")
      }
      NavigationLink { LiveAlgorithmOpinionsView(model: model) } label: {
        LiveSettingText(title: "My opinions", detail: "The opinions you gave on the home page. Nothing else is recorded.")
      }
    } footer: {
      if let error = model.error { Text(verbatim: error).liveSettingsFooter() }
    }
  }
}
