import SwiftUI

struct DemoImportView: View {
  @Environment(\.themePalette) private var palette
  @State private var selectedSource: DemoImportSource?

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Migration assistant")
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
          Text("Import your data in minutes")
            .font(.title2.weight(.bold))
          Text("Pick a source and follow a completely local mock import.")
            .foregroundStyle(.secondary)
        }

        ForEach(DemoImportSource.allCases) { source in
          Button {
            selectedSource = source
          } label: {
            sourceCard(source)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("demo.import.source.\(source.rawValue)")
        }
      }
      .padding(16)
    }
    .background(palette.groupedBackground)
    .navigationTitle("Import")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $selectedSource) { source in
      DemoImportFlowView(source: source)
    }
    .accessibilityIdentifier("demo.import.screen")
  }

  private func sourceCard(_ source: DemoImportSource) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Image(systemName: source.systemImage)
        .font(.title2.weight(.semibold))
        .frame(width: 48, height: 48)
        .background(.black.opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 13))
      Text(source.title)
        .font(.headline)
      Text(source.summary)
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.72))
      Label("Start \(source.shortName) import", systemImage: "arrow.right")
        .font(.subheadline.weight(.semibold))
    }
    .foregroundStyle(.white)
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(20)
    .background(source.gradient)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}
