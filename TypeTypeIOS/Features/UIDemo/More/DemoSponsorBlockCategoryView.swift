import SwiftUI

struct DemoSponsorBlockCategoryView: View {
  @EnvironmentObject private var session: DemoSessionStore
  let category: DemoSponsorBlockCategory

  var body: some View {
    Form {
      Section {
        HStack(alignment: .top, spacing: 13) {
          Circle()
            .fill(category.color)
            .frame(width: 16, height: 16)
            .padding(.top, 3)
          Text(category.detail)
            .foregroundStyle(.secondary)
        }
      }

      Section("Action") {
        Picker("Action", selection: action) {
          Text("Skip").tag("Skip")
          Text("Mark").tag("Mark")
          Text("Hide").tag("Hide")
        }
        .pickerStyle(.inline)
      }
    }
    .navigationTitle(category.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var action: Binding<String> {
    Binding(
      get: {
        session.preferences.sponsorBlockCategoryActions[category.id]
          ?? category.defaultAction
      },
      set: { value in
        var actions = session.preferences.sponsorBlockCategoryActions
        actions[category.id] = value
        session.setPreference(\.sponsorBlockCategoryActions, to: actions)
      }
    )
  }
}
