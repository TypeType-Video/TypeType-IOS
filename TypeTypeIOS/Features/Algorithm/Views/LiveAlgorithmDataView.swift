import SwiftUI

struct LiveAlgorithmDataView: View {
  @ObservedObject var model: LiveAlgorithmViewModel

  var body: some View {
    List {
      LiveSection {
        if model.categories.isEmpty { ProgressView().frame(maxWidth: .infinity) }
        ForEach(model.categories) { category in
          NavigationLink { LiveAlgorithmCategoryView(model: model, category: category) } label: {
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: LiveAlgorithmLabels.data(category.id))
                Text(category.count == 1 ? "\(category.count) item" : "\(category.count) items")
                  .font(.footnote).foregroundStyle(.secondary)
              }
              Spacer()
              Text(model.uses(category) ? "On" : "Off").font(.footnote).foregroundStyle(.secondary)
            }
          }
        }
      } footer: {
        Text("Review collected data and choose what the algorithm may use.").liveSettingsFooter()
      }
    }
    .liveGroupedList()
    .navigationTitle("Data used")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.loadData() }
  }
}

struct LiveAlgorithmCategoryView: View {
  @ObservedObject var model: LiveAlgorithmViewModel
  let category: LiveRecommenderDataCategory

  private var excludable: Bool { LiveRecommenderDataCategory.excludable.contains(category.id) }

  var body: some View {
    List {
      LiveSection {
        Toggle(isOn: Binding(get: { model.uses(category) }, set: { _ in model.toggleUse(category.id) })) {
          LiveSettingText(title: "Use for the home page", detail: "Let the algorithm read these items.")
        }
        if excludable {
          Picker(selection: Binding(get: { model.retention(category) }, set: { model.setRetention($0, for: category.id) })) {
            ForEach(LiveRecommenderDataCategory.retentionChoices, id: \.self) { days in
              Text(verbatim: LiveAlgorithmLabels.retention(days)).tag(days)
            }
          } label: {
            LiveSettingText(title: "Read back", detail: "The algorithm does not read older items. Nothing is deleted.")
          }
        }
      }
      LiveSection {
        if category.items.isEmpty { Text("No items.").foregroundStyle(.secondary) }
        ForEach(category.items) { item in
          if excludable {
            Toggle(isOn: Binding(get: { !model.excludes(item) }, set: { _ in model.toggleExcluded(item.id) })) { itemLabel(item) }
          } else {
            itemLabel(item)
          }
        }
      } header: {
        Text("Latest \(category.items.count) of \(category.count)").liveSectionHeader()
      }
    }
    .liveGroupedList()
    .navigationTitle(Text(verbatim: LiveAlgorithmLabels.data(category.id)))
    .navigationBarTitleDisplayMode(.inline)
  }

  private func itemLabel(_ item: LiveRecommenderDataItem) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: item.title).lineLimit(2)
      let detail = [item.channel, item.at > 0 ? Date(timeIntervalSince1970: TimeInterval(item.at) / 1000).formatted(.relative(presentation: .named)) : nil]
        .compactMap { $0 }.joined(separator: " · ")
      if !detail.isEmpty { Text(verbatim: detail).font(.footnote).foregroundStyle(.secondary) }
    }
  }
}
