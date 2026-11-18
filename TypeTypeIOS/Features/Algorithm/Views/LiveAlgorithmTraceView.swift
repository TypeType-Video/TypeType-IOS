import SwiftUI

struct LiveAlgorithmTraceView: View {
  @ObservedObject var model: LiveAlgorithmViewModel

  var body: some View {
    List {
      if let trace = model.trace {
        LiveSection {
          row("\(trace.candidatesReceived) videos found", detail: LiveAlgorithmLabels.sources(trace))
          row("\(trace.dropped.values.reduce(0, +)) videos set aside",
              detail: trace.dropped.sorted { $0.key < $1.key }.map { LiveAlgorithmLabels.dropped($0.key, count: $0.value) }.joined(separator: " · "))
          row("\(trace.shown) videos shown", detail: String(localized: "In \(trace.rows.count) rows."))
        } header: {
          Text("How the last home page was built").liveSectionHeader()
        } footer: {
          Text(verbatim: [
            Date(timeIntervalSince1970: TimeInterval(trace.builtAt) / 1000).formatted(.relative(presentation: .named)),
            String(localized: "By \(model.name(of: trace.algorithm))."),
          ].joined(separator: " · ")).liveSettingsFooter()
        }
        LiveSection {
          ForEach(trace.rows) { row in
            VStack(alignment: .leading, spacing: 2) {
              Text(verbatim: row.title)
              Text(verbatim: [row.why, String(localized: "\(row.videos) videos")].filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.footnote).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
          }
        } header: {
          Text("\(trace.rows.count) rows").liveSectionHeader()
        } footer: {
          Text("Why each row is on the home page.").liveSettingsFooter()
        }
      } else if model.traceLoaded {
        Text("No home page built by an algorithm yet. Open the home page first.").foregroundStyle(.secondary)
      } else {
        ProgressView().frame(maxWidth: .infinity)
      }
    }
    .liveGroupedList()
    .navigationTitle("Last home page")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.loadTrace() }
  }

  private func row(_ title: LocalizedStringKey, detail: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(title)
      if !detail.isEmpty { Text(verbatim: detail).font(.footnote).foregroundStyle(.secondary) }
    }
    .accessibilityElement(children: .combine)
  }
}

struct LiveAlgorithmOpinionsView: View {
  @ObservedObject var model: LiveAlgorithmViewModel

  var body: some View {
    List {
      LiveSection {
        if model.opinions.isEmpty { Text("Nothing here yet").foregroundStyle(.secondary) }
        ForEach(model.opinions) { opinion in
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(verbatim: LiveAlgorithmLabels.opinion(opinion))
              Text(verbatim: detail(opinion)).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Take back") { Task { await model.remove(opinion) } }
              .buttonStyle(.borderless)
          }
          .accessibilityElement(children: .combine)
          .accessibilityAction(named: Text("Take back")) { Task { await model.remove(opinion) } }
        }
      } header: {
        Text("Opinions given").liveSectionHeader()
      } footer: {
        Text("Only what you choose to send is kept, with the algorithm and settings you had at that moment. It leaves with your export and you can take each opinion back.")
          .liveSettingsFooter()
      }
    }
    .liveGroupedList()
    .navigationTitle("My opinions")
    .navigationBarTitleDisplayMode(.inline)
    .task { await model.loadOpinions() }
  }

  private func detail(_ opinion: LiveRecommenderOpinion) -> String {
    let subject = opinion.kind == "video"
      ? [opinion.title ?? opinion.videoURL, opinion.channelName].compactMap { $0 }.joined(separator: " · ")
      : opinion.comment
    return [
      subject, LiveAlgorithmLabels.reason(opinion.reason), model.name(of: opinion.algorithmID),
      Date(timeIntervalSince1970: TimeInterval(opinion.createdAt) / 1000).formatted(date: .abbreviated, time: .omitted),
    ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
  }
}
