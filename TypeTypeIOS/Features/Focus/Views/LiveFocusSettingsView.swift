import SwiftUI

struct LiveFocusSettingsView: View {
  @StateObject private var model: LiveFocusViewModel

  init(service: LiveFocusServiceProtocol, subscriptions: LiveSubscriptionsServiceProtocol) {
    _model = StateObject(wrappedValue: LiveFocusViewModel(service: service, subscriptions: subscriptions))
  }

  var body: some View {
    List {
      if let settings = model.settings {
        form(settings)
      } else if let error = model.error {
        Text(verbatim: error).foregroundStyle(.secondary)
      } else {
        ProgressView().frame(maxWidth: .infinity)
      }
    }
    .liveGroupedList()
    .navigationTitle("Focus")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.load() }
    .accessibilityIdentifier("live.settings.focus")
  }

  @ViewBuilder
  private func form(_ settings: LiveFocusSettings) -> some View {
    LiveSection {
      picker("Channels to fade", selection: settings.entertainmentGroupID ?? "", options: groupOptions(none: "Choose a group")) {
        await model.setEntertainment($0)
      }
      .disabled(model.groups.isEmpty)
      picker("Channels to keep first", selection: settings.studyGroupID ?? "",
             options: groupOptions(none: "None", excluding: settings.entertainmentGroupID)) {
        await model.setStudy($0)
      }
      .disabled(model.groups.isEmpty)
      picker("Fade over", selection: settings.transitionDays,
             options: LiveFocusSettings.choices(LiveFocusSettings.transitionChoices, current: settings.transitionDays)
               .map { ($0, String(localized: "\($0) days")) }) {
        await model.setTransition($0)
      }
      picker("Their channel pages show", selection: settings.archiveDays,
             options: LiveFocusSettings.choices(LiveFocusSettings.archiveChoices, current: settings.archiveDays)
               .map { ($0, String(localized: "The last \($0) days")) }) {
        await model.setArchive($0)
      }
      picker("When", selection: settings.schedule,
             options: [(.always, String(localized: "Every day")), (.weekdays, String(localized: "Weekdays, free on weekends"))]) {
        await model.setSchedule($0)
      }
    } header: {
      Text("Focus").liveSectionHeader()
    } footer: {
      VStack(alignment: .leading, spacing: 6) {
        Text("Pick the group of channels that distracts you. Its videos slowly fade from your home and your subscription feed, and its channel pages only show recent videos. Search stays as it is.")
        if model.groups.isEmpty { Text("Create a subscription group first.") }
      }
      .font(.footnote)
      .foregroundStyle(.secondary)
    }
    .disabled(model.isLocked || model.isSaving)

    LiveSection {
      VStack(alignment: .leading, spacing: 4) {
        Text(verbatim: statusText(settings)).font(.body.weight(.semibold))
        Text(model.isLocked ? "The settings can change once focus is off." : "Turning it off takes effect one day later, and you can change your mind until then.")
          .font(.footnote).foregroundStyle(.secondary)
      }
      .accessibilityElement(children: .combine)
      action(settings)
    } footer: {
      if let error = model.error { Text(verbatim: error).liveSettingsFooter() }
    }
  }

  @ViewBuilder
  private func action(_ settings: LiveFocusSettings) -> some View {
    if !settings.enabled {
      Button("Turn on") { Task { await model.turnOn() } }
        .disabled(model.isSaving || settings.entertainmentGroupID == nil)
        .accessibilityHint(Text("Starts fading the chosen channels."))
    } else if settings.disableAt != nil {
      Button("Keep focus on") { Task { await model.turnOn() } }
        .disabled(model.isSaving)
    } else {
      Button("Turn off", role: .destructive) { Task { await model.turnOff() } }
        .disabled(model.isSaving)
        .accessibilityHint(Text("Focus turns off one day later."))
    }
  }

  private func statusText(_ settings: LiveFocusSettings) -> String {
    switch settings.status(now: Date()) {
    case .off: String(localized: "Off")
    case let .leaving(hours): String(localized: "Turns off in \(hours) h")
    case let .on(day, total, percent): String(localized: "Day \(day) of \(total): \(percent)% of these videos still show")
    }
  }

  private func groupOptions(none: String.LocalizationValue, excluding: String? = nil) -> [(String, String)] {
    [("", String(localized: none))] + model.groups.filter { $0.id != excluding }.map { ($0.id, $0.name) }
  }

  private func picker<Value: Hashable>(
    _ title: LocalizedStringKey, selection: Value, options: [(Value, String)], onChange: @escaping (Value) async -> Void
  ) -> some View {
    Picker(title, selection: Binding(get: { selection }, set: { value in Task { await onChange(value) } })) {
      ForEach(options, id: \.0) { option in Text(verbatim: option.1).tag(option.0) }
    }
  }
}
