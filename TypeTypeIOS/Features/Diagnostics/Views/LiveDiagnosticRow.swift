import SwiftUI
import UIKit

struct LiveDiagnosticRow: View {
  @Environment(\.themePalette) private var palette
  let entry: LiveDiagnosticEntry
  @Binding var copiedRequestID: String?

  private var status: String {
    entry.statusCode.map(String.init) ?? "Network"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .firstTextBaseline) {
        Text("\(entry.method) \(entry.route)")
          .font(.subheadline.weight(.semibold).monospaced())
          .lineLimit(2)
        Spacer(minLength: 8)
        Text(status)
          .font(.caption.weight(.bold).monospacedDigit())
          .foregroundStyle(entry.isFailure ? .red : .green)
      }
      Text(
        "\(entry.durationMilliseconds) ms · \(entry.timestamp.formatted(date: .abbreviated, time: .standard))"
      )
      .font(.caption)
      .foregroundStyle(.secondary)
      requestIDButton
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder private var requestIDButton: some View {
    if let requestID = entry.requestID {
      Button {
        UIPasteboard.general.string = requestID
        withAnimation { copiedRequestID = requestID }
        Task {
          try? await Task.sleep(for: .seconds(2))
          guard copiedRequestID == requestID else { return }
          withAnimation { copiedRequestID = nil }
        }
      } label: {
        Label(requestID, systemImage: "doc.on.doc")
          .font(.caption.monospaced())
          .lineLimit(1)
      }
      .buttonStyle(.plain)
      .foregroundStyle(palette.accent)
      .accessibilityLabel("Copy request ID \(requestID)")
    }
  }
}
