import SwiftUI

struct LiveSavedAccountsSection: View {
  @ObservedObject var coordinator: RootCoordinator
  @State private var switchingID: String?
  @State private var failure: String?
  @State private var pendingForget: LiveSavedAccount?

  var body: some View {
    LiveSection {
      ForEach(coordinator.savedAccounts) { account in
        Button {
          Task { await select(account) }
        } label: {
          HStack(spacing: 12) {
            LiveSettingText(
              title: LocalizedStringKey(account.publicUsername ?? account.accountIdentifier ?? account.userID),
              detail: LocalizedStringKey(AuthRole(rawValue: account.role).title)
            )
            Spacer()
            if switchingID == account.userID {
              ProgressView()
            } else if account.userID == coordinator.currentUser?.id {
              Image(systemName: "checkmark")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            }
          }
          .foregroundStyle(.primary)
        }
        .tint(Color.primary)
        .disabled(switchingID != nil)
        .accessibilityAddTraits(account.userID == coordinator.currentUser?.id ? .isSelected : [])
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
          Button("Forget", role: .destructive) { pendingForget = account }
        }
      }
      Button("Sign in with another account") {
        coordinator.addAccount()
      }
    } header: {
      Text("Accounts on this instance").liveSettingsHeader()
    } footer: {
      Text("Tap an account to switch to it. Swipe left to forget it on this device.")
        .liveSettingsFooter()
    }
    .alert("Couldn’t switch account", isPresented: failureBinding) {
      Button("OK") { failure = nil }
    } message: {
      Text(failure ?? "")
    }
    .alert("Forget this account?", isPresented: forgetBinding) {
      Button("Forget", role: .destructive) {
        if let account = pendingForget {
          Task { await coordinator.forgetAccount(account) }
        }
        pendingForget = nil
      }
      Button("Cancel", role: .cancel) { pendingForget = nil }
    } message: {
      Text("It is removed from this device. You can sign in again later.")
    }
  }

  private func select(_ account: LiveSavedAccount) async {
    guard account.userID != coordinator.currentUser?.id else { return }
    switchingID = account.userID
    defer { switchingID = nil }
    do {
      try await coordinator.switchAccount(to: account)
    } catch {
      failure = error.localizedDescription
    }
  }

  private var failureBinding: Binding<Bool> {
    Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })
  }

  private var forgetBinding: Binding<Bool> {
    Binding(get: { pendingForget != nil }, set: { if !$0 { pendingForget = nil } })
  }
}
