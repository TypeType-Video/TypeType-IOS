import Foundation
import MetricKit

final class LiveCrashReporter: NSObject, MXMetricManagerSubscriber {
  private let archive: LiveCrashReportArchive

  init(archive: LiveCrashReportArchive) {
    self.archive = archive
  }

  func start() {
    MXMetricManager.shared.add(self)
  }

  func didReceive(_ payloads: [MXDiagnosticPayload]) {
    let reports = payloads.flatMap(Self.reports(from:))
    Task { [archive] in await archive.append(reports) }
  }

  private static func reports(from payload: MXDiagnosticPayload) -> [LiveCrashReport] {
    let crashes = (payload.crashDiagnostics ?? []).map { diagnostic in
      LiveCrashReport(
        kind: .crash,
        date: payload.timeStampEnd,
        appVersion: diagnostic.applicationVersion,
        system: diagnostic.metaData.osVersion,
        device: diagnostic.metaData.deviceType,
        exceptionType: diagnostic.exceptionType?.intValue,
        signal: diagnostic.signal?.intValue,
        terminationReason: diagnostic.terminationReason,
        hangSeconds: nil,
        frames: LiveCrashReport.frames(fromCallStackTree: diagnostic.callStackTree.jsonRepresentation())
      )
    }
    let hangs = (payload.hangDiagnostics ?? []).map { diagnostic in
      LiveCrashReport(
        kind: .hang,
        date: payload.timeStampEnd,
        appVersion: diagnostic.applicationVersion,
        system: diagnostic.metaData.osVersion,
        device: diagnostic.metaData.deviceType,
        exceptionType: nil,
        signal: nil,
        terminationReason: nil,
        hangSeconds: diagnostic.hangDuration.converted(to: .seconds).value,
        frames: LiveCrashReport.frames(fromCallStackTree: diagnostic.callStackTree.jsonRepresentation())
      )
    }
    return crashes + hangs
  }
}
