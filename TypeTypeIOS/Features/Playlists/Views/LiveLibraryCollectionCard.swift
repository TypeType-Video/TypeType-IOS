import SwiftUI

struct LiveLibraryCollectionCard: View {
  let kind: LiveLibraryCollectionKind
  let videos: [LiveLibraryVideo]
  let onOpen: () -> Void

  var body: some View {
    Button(action: onOpen) {
      VStack(alignment: .leading, spacing: 9) {
        ZStack(alignment: .bottomTrailing) {
          Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
              LiveRemoteImage(
                url: URL(string: videos.first?.thumbnail ?? "")
              )
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .clipped()
            }
            .clipShape(
              RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
          Text(String(videos.count))
            .font(.caption.weight(.semibold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .frame(minWidth: 36, minHeight: 24)
            .background(.black.opacity(0.78), in: Capsule())
            .foregroundStyle(.white)
            .padding(8)
        }
        Text(kind.title)
          .font(.headline)
          .foregroundStyle(.primary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("live.library.collection-card")
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(kind.title), \(videos.count) videos")
  }
}
