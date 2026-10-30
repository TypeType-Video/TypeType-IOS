import SwiftUI

struct LiveSettingsServicePicker: View {
  @Binding var selection: Int
  let services: [VideoService]

  var body: some View {
    NavigationLink {
      List {
        LiveSection {
          ForEach(services) { service in
            Button {
              selection = service.id
            } label: {
              HStack(spacing: 12) {
                LiveServiceLogo(service: service)
                Text(service.name)
                  .foregroundStyle(.primary)
                Spacer()
                if service.id == selection {
                  Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                }
              }
            }
            .accessibilityAddTraits(service.id == selection ? .isSelected : [])
          }
        }
      }
      .liveGroupedList()
      .navigationTitle("Default service")
      .navigationBarTitleDisplayMode(.inline)
    } label: {
      HStack(spacing: 12) {
        LiveSettingText(title: "Default service", detail: "Where Home, Search and links open first.")
        Spacer(minLength: 8)
        if let current {
          LiveServiceLogo(service: current)
          Text(current.name)
            .foregroundStyle(.secondary)
        }
      }
    }
    .liveRowFill()
  }

  private var current: VideoService? {
    services.first { $0.id == selection }
  }
}

struct LiveServiceLogo: View {
  let service: VideoService

  var body: some View {
    Group {
      if let asset = service.assetName {
        Image(asset)
          .resizable()
          .scaledToFit()
      } else {
        Image(systemName: service.systemImage)
          .foregroundStyle(.secondary)
      }
    }
    .frame(width: 24, height: 24)
    .accessibilityHidden(true)
  }
}
