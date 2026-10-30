import SwiftUI

struct LiveWatchSectionPlaceholder: View {
  enum Kind {
    case related
    case comments
  }

  let kind: Kind

  var body: some View {
    switch kind {
    case .related:
      VStack(alignment: .leading, spacing: 12) {
        TypeTypeSkeleton(cornerRadius: 6)
          .frame(width: 140, height: 14)
        ForEach(0..<2, id: \.self) { _ in
          row(leading: TypeTypeSkeleton(cornerRadius: 8).frame(width: 160, height: 90), lineHeight: 12, width: 180)
        }
      }
      .accessibilityLabel("Loading related videos")
    case .comments:
      VStack(alignment: .leading, spacing: 14) {
        ForEach(0..<3, id: \.self) { _ in
          row(leading: TypeTypeSkeleton(cornerRadius: 18).frame(width: 36, height: 36), lineHeight: 10, width: 120)
        }
      }
      .accessibilityLabel("Loading comments")
    }
  }

  private func row(leading: some View, lineHeight: CGFloat, width: CGFloat) -> some View {
    HStack(alignment: .top, spacing: 10) {
      leading
      VStack(alignment: .leading, spacing: 6) {
        if kind == .related {
          TypeTypeSkeleton(cornerRadius: 4).frame(height: lineHeight)
          TypeTypeSkeleton(cornerRadius: 4).frame(width: width, height: 10)
        } else {
          TypeTypeSkeleton(cornerRadius: 4).frame(width: width, height: 10)
          TypeTypeSkeleton(cornerRadius: 4).frame(height: lineHeight)
        }
      }
    }
  }
}
