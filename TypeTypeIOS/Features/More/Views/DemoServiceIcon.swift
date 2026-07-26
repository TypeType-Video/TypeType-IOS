import SwiftUI

struct DemoServiceIcon: View {
  let service: String
  var size: CGFloat = 34

  var body: some View {
    Image(assetName)
      .resizable()
      .renderingMode(.template)
      .scaledToFit()
      .foregroundStyle(.white)
      .padding(size * 0.21)
      .frame(width: size, height: size)
      .background(brandColor.gradient)
      .clipShape(RoundedRectangle(cornerRadius: size * 0.24))
      .accessibilityHidden(true)
  }

  private var assetName: String {
    switch service {
    case "NicoNico": "ServiceNicoNico"
    case "BiliBili": "ServiceBiliBili"
    default: "ServiceYouTube"
    }
  }

  private var brandColor: Color {
    switch service {
    case "NicoNico": Color(red: 0.18, green: 0.18, blue: 0.2)
    case "BiliBili": Color(red: 0.0, green: 0.65, blue: 0.83)
    default: Color(red: 1, green: 0, blue: 0)
    }
  }
}
