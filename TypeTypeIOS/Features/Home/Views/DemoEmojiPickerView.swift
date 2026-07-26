import SwiftUI

struct DemoEmojiPickerView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var session: DemoSessionStore
  @State private var query = ""

  private let emojis = [
    ("Rabbit", "\u{1F430}"),
    ("Movie camera", "\u{1F3A5}"),
    ("Clapper board", "\u{1F3AC}"),
    ("Parrot", "\u{1F99C}"),
    ("Cat", "\u{1F431}"),
    ("Dog", "\u{1F436}"),
    ("Fox", "\u{1F98A}"),
    ("Panda", "\u{1F43C}"),
    ("Frog", "\u{1F438}"),
    ("Penguin", "\u{1F427}"),
    ("Owl", "\u{1F989}"),
    ("Whale", "\u{1F433}"),
    ("Rocket", "\u{1F680}"),
    ("Satellite", "\u{1F6F0}\u{FE0F}"),
    ("Television", "\u{1F4FA}"),
    ("Headphones", "\u{1F3A7}"),
    ("Music", "\u{1F3B5}"),
    ("Sparkles", "\u{2728}"),
    ("Rainbow", "\u{1F308}"),
    ("Open heart", "\u{1F49C}"),
  ]

  private let columns = [
    GridItem(.adaptive(minimum: 62), spacing: 12),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(filtered, id: \.0) { item in
            Button {
              session.useProfileEmoji(item.1)
              dismiss()
            } label: {
              Text(item.1)
                .font(.system(size: 34))
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel(item.0)
          }
        }
        .padding()
      }
      .searchable(text: $query, prompt: "Search emoji")
      .navigationTitle("Emoji avatar")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  private var filtered: [(String, String)] {
    guard !query.isEmpty else { return emojis }
    return emojis.filter {
      $0.0.localizedCaseInsensitiveContains(query)
        || $0.1.contains(query)
    }
  }
}
