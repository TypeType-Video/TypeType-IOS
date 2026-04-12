import SwiftUI

struct ImportAssetBanner: View {
  let title: String
  let imageName: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
      if let image = UIImage(contentsOfFile: assetPath(imageName)) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .frame(height: 140)
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  }

  private func assetPath(_ imageName: String) -> String {
    let root = Bundle.main.resourcePath ?? ""
    return "\(root)/Public/\(imageName)"
  }
}
