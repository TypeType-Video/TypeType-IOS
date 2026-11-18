import SwiftUI

struct LiveAlgorithmParametersView: View {
  @ObservedObject var model: LiveAlgorithmViewModel
  let algorithm: LiveRecommenderAlgorithm
  @State private var confirmsReset = false

  var body: some View {
    List {
      ForEach(groups, id: \.self) { group in
        let text = LiveAlgorithmLabels.group(group)
        LiveSection {
          ForEach(algorithm.parameters.filter { $0.group == group }) { parameter in
            row(parameter)
          }
        } header: {
          Text(verbatim: text.title).liveSectionHeader()
        } footer: {
          if !text.help.isEmpty { Text(verbatim: text.help).liveSettingsFooter() }
        }
      }
      LiveSection {
        Button("Restore \(algorithm.name) defaults", role: .destructive) { confirmsReset = true }
      } footer: {
        Text("Every setting goes back to its default value.").liveSettingsFooter()
      }
    }
    .liveGroupedList()
    .navigationTitle(Text("\(algorithm.name) settings"))
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog(Text("Restore \(algorithm.name) defaults?"), isPresented: $confirmsReset, titleVisibility: .visible) {
      Button("Restore \(algorithm.name) defaults", role: .destructive) { model.resetValues() }
    }
  }

  private var groups: [String] {
    algorithm.parameters.reduce(into: [String]()) { list, parameter in
      if !list.contains(parameter.group) { list.append(parameter.group) }
    }
  }

  @ViewBuilder
  private func row(_ parameter: LiveRecommenderParameter) -> some View {
    switch model.value(parameter) {
    case let .flag(on):
      Toggle(isOn: Binding(get: { on }, set: { model.setValue(.flag($0), for: parameter.id) })) {
        label(parameter)
      }
    case let .number(value):
      Stepper(
        value: Binding(get: { value }, set: { model.setValue(.number($0), for: parameter.id) }),
        in: (parameter.min ?? 0)...(parameter.max ?? max(value, 1)),
        step: parameter.step ?? 1
      ) {
        VStack(alignment: .leading, spacing: 2) {
          label(parameter)
          Text(verbatim: Self.format(value, unit: parameter.unit)).font(.footnote.monospacedDigit()).foregroundStyle(.tint)
        }
      }
      .accessibilityValue(Text(verbatim: Self.format(value, unit: parameter.unit)))
    }
  }

  private func label(_ parameter: LiveRecommenderParameter) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: parameter.label)
      if let help = parameter.help, !help.isEmpty {
        Text(verbatim: help).font(.caption).foregroundStyle(.secondary)
      }
    }
  }

  static func format(_ value: Double, unit: String?) -> String {
    if unit == "%" { return value.formatted(.percent.precision(.fractionLength(0))) }
    let number = value.formatted(.number.precision(.fractionLength(0...2)))
    guard let unit, !unit.isEmpty else { return number }
    return "\(number) \(unit)"
  }
}
