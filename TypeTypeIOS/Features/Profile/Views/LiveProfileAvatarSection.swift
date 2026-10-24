import PhotosUI
import SwiftUI

struct LiveProfileAvatarSection: View {
  let user: AuthUser?
  @Binding var selectedPhoto: PhotosPickerItem?
  let isBusy: Bool
  let onEmoji: (String) -> Void
  let onClear: () -> Void

  private let emojis = [
    ("😀", "1F600"),
    ("🦊", "1F98A"),
    ("🐱", "1F431"),
    ("🐶", "1F436"),
    ("🚀", "1F680"),
    ("🎬", "1F3AC"),
    ("💻", "1F4BB"),
    ("🌍", "1F30D"),
  ]

  var body: some View {
    Section {
      HStack(spacing: 16) {
        LiveRemoteImage(url: user?.avatarURL)
          .frame(width: 72, height: 72)
          .clipShape(Circle())
          .overlay {
            Circle().stroke(.separator, lineWidth: 1)
          }
        VStack(alignment: .leading, spacing: 8) {
          Text(user?.publicUsername ?? "TypeType user")
            .font(.headline)
          PhotosPicker(
            selection: $selectedPhoto,
            matching: .images
          ) {
            Label("Choose image", systemImage: "photo")
          }
          .disabled(isBusy)
        }
      }
      .padding(.vertical, 4)

      ScrollView(.horizontal) {
        HStack(spacing: 10) {
          ForEach(emojis, id: \.1) { emoji, code in
            Button {
              onEmoji(code)
            } label: {
              Text(emoji)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
            .accessibilityLabel("Use \(emoji) avatar")
          }
        }
        .padding(.vertical, 2)
      }
      .scrollIndicators(.hidden)

      Button("Clear avatar", role: .destructive, action: onClear)
        .disabled(isBusy)
    } header: { Text("Avatar").liveSectionHeader() }
  }
}
