import SwiftUI

struct DemoHideEverythingControl: View {
  @EnvironmentObject private var session: DemoSessionStore
  @State private var confirmationStep = 0
  @State private var confirms = false
  @State private var presentsScene = false

  private let prompts = [
    ("Hide everything?", "All recommendations and comments will disappear.", "Yeah, hide it"),
    ("Are you sure?", "You will have nothing left to scroll.", "I am sure"),
    ("Are you SURE sure?!", "We spent months on this.", "Yes, gone"),
    ("LAST CHANCE.", "Do not say we did not warn you.", "Fine, hide it"),
  ]

  var body: some View {
    Button {
      confirmationStep = 0
      confirms = true
    } label: {
      LabeledContent {
        Image(systemName: "chevron.right")
          .foregroundStyle(.secondary)
      } label: {
        Label("Hide everything", systemImage: "eye.slash.fill")
      }
    }
    .foregroundStyle(.primary)
    .alert(
      prompts[confirmationStep].0,
      isPresented: $confirms
    ) {
      Button("Cancel", role: .cancel) {}
      Button(prompts[confirmationStep].2, role: .destructive) {
        continueConfirmation()
      }
    } message: {
      Text(prompts[confirmationStep].1)
    }
    .fullScreenCover(isPresented: $presentsScene) {
      DemoHideEverythingSceneView()
    }
    .accessibilityIdentifier("demo.hide-everything.start")
  }

  private func continueConfirmation() {
    if confirmationStep < prompts.count - 1 {
      confirmationStep += 1
      Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(180))
        confirms = true
      }
      return
    }
    session.setPreference(\.showsContinueWatching, to: false)
    session.setPreference(\.showsRecommendations, to: false)
    session.setPreference(\.showsRelated, to: false)
    session.setPreference(\.loadsComments, to: false)
    presentsScene = true
  }
}
