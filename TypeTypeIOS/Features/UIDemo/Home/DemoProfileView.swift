import PhotosUI
import SwiftUI

struct DemoProfileView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  @State private var username = ""
  @State private var displayName = ""
  @State private var email = ""
  @State private var bio = ""
  @State private var savedMessage: String?
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var presentsPassword = false
  @State private var presentsEmoji = false
  @State private var currentPassword = ""

  var body: some View {
    NavigationStack {
      Form {
        Section {
          HStack(spacing: 14) {
            DemoProfileAvatarView(size: 74)
            VStack(alignment: .leading, spacing: 7) {
              PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose photo", systemImage: "photo")
              }
              emojiMenu
            }
          }
        }

        Section("Public profile") {
          TextField("Public username", text: $username)
            .textInputAutocapitalization(.never)
          if !username.isEmpty && !validUsername {
            Text("Use 3–32 letters, numbers, dots, underscores, or dashes.")
              .font(.caption)
              .foregroundStyle(.red)
          }
          TextField("Bio", text: $bio, axis: .vertical)
            .lineLimit(3...6)
          Text("\(bio.count)/280")
            .font(.caption)
            .foregroundStyle(bio.count > 280 ? .red : .secondary)
        }

        Section("Account identity") {
          TextField("Display name", text: $displayName)
          TextField("Email address", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
          if identityChanged {
            SecureField("Current password", text: $currentPassword)
          }
          Button("Change password") {
            presentsPassword = true
          }
        }

        if let savedMessage {
          Section {
            Label(savedMessage, systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
          }
        }
      }
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save", action: save)
            .disabled(!canSave)
            .accessibilityIdentifier("demo.profile.save")
        }
      }
      .sheet(isPresented: $presentsPassword) {
        DemoChangePasswordView()
      }
      .sheet(isPresented: $presentsEmoji) {
        DemoEmojiPickerView()
      }
      .onAppear(perform: loadDraft)
      .onChange(of: selectedPhoto) {
        loadSelectedPhoto()
      }
    }
    .preferredColorScheme(session.preferences.colorScheme)
    .accessibilityIdentifier("demo.profile.screen")
  }

  private var emojiMenu: some View {
    Menu {
      Button("TypeType logo") {
        session.useProfileEmoji(nil)
      }
      Button("Browse emoji…") {
        presentsEmoji = true
      }
    } label: {
      Label("Choose emoji", systemImage: "face.smiling")
    }
  }

  private var canSave: Bool {
    validUsername
      && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && email.contains("@")
      && bio.count <= 280
      && (!identityChanged || !currentPassword.isEmpty)
  }

  private var validUsername: Bool {
    let value = username.trimmingCharacters(in: .whitespacesAndNewlines)
    guard (3...32).contains(value.count) else { return false }
    let allowed = CharacterSet.alphanumerics.union(
      CharacterSet(charactersIn: "._-")
    )
    return value.unicodeScalars.allSatisfy(allowed.contains)
  }

  private var identityChanged: Bool {
    displayName.trimmingCharacters(in: .whitespacesAndNewlines)
      != session.profileDisplayName
      || email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        != session.profileEmail.lowercased()
  }

  private func loadDraft() {
    username = session.profileUsername
    displayName = session.profileDisplayName
    email = session.profileEmail
    bio = session.profileBio
  }

  private func save() {
    session.updateProfile(
      username: username,
      displayName: displayName,
      email: email,
      bio: bio
    )
    withAnimation(.snappy) {
      savedMessage = "Profile saved for this session."
    }
    currentPassword = ""
  }

  private func loadSelectedPhoto() {
    guard let selectedPhoto else { return }
    Task {
      if let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
        await MainActor.run {
          session.useProfilePhoto(data)
        }
      }
    }
  }
}
