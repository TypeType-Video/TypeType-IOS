import SwiftUI

struct LiveAdminBugReportRow: View {
  let report: LiveAdminBugReport

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(report.category.replacingOccurrences(of: "_", with: " ").capitalized)
          .font(.caption.weight(.semibold))
        Spacer()
        Text(report.status.replacingOccurrences(of: "_", with: " ").capitalized)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(statusColor)
      }
      Text(report.description)
        .font(.subheadline)
        .lineLimit(3)
      Text(report.userEmail)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 5)
    .contentShape(Rectangle())
    .accessibilityIdentifier("live.admin.bug-report")
  }

  private var statusColor: Color {
    switch report.status {
    case "fixed", "closed": return .green
    case "in_progress": return .orange
    default: return DemoTheme.accent
    }
  }
}
