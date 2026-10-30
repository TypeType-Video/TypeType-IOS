import SwiftUI
import UIKit

struct LiveCrashReportsSection: View {
  let archive: LiveCrashReportArchive
  @State private var reports: [LiveCrashReport] = []

  var body: some View {
    LiveSection {
      if reports.isEmpty {
        Text("No crash or freeze recorded.")
          .foregroundStyle(.secondary)
      } else {
        ForEach(reports) { report in
          NavigationLink {
            LiveCrashReportView(report: report)
          } label: {
            LiveSettingText(
              title: report.kind == .crash ? "TypeType stopped unexpectedly" : "TypeType stopped responding",
              detail: LocalizedStringKey(report.date.formatted(date: .abbreviated, time: .shortened))
            )
          }
        }
        Button("Clear crash reports", role: .destructive) {
          Task {
            await archive.clear()
            reports = []
          }
        }
      }
    } header: {
      Text("Crashes and freezes").liveSettingsHeader()
    } footer: {
      Text("Kept only on this device. Nothing is sent automatically: read a report, then copy it if you want to share it. Reports never contain messages, links, video IDs, account data or tokens.")
        .liveSettingsFooter()
    }
    .task { reports = await archive.reports() }
  }
}

struct LiveCrashReportView: View {
  let report: LiveCrashReport
  @State private var copied = false

  var body: some View {
    List {
      LiveSection {
        Text(report.text)
          .font(.caption.monospaced())
          .textSelection(.enabled)
      }
      LiveSection {
        Button {
          UIPasteboard.general.string = report.text
          copied = true
        } label: {
          Label(copied ? "Report copied" : "Copy report", systemImage: copied ? "checkmark" : "doc.on.doc")
        }
      }
    }
    .liveGroupedList()
    .navigationTitle(report.kind == .crash ? "Crash report" : "Freeze report")
    .navigationBarTitleDisplayMode(.inline)
  }
}
