import SwiftUI

extension LiveHomeView {
  @ToolbarContentBuilder
  var brandToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      Image("TypeTypeLogo")
        .resizable()
        .scaledToFit()
        .frame(width: 25, height: 25)
      .accessibilityLabel("TypeType home")
    }
  }

  @ToolbarContentBuilder
  var serviceToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      if viewModel.services.count > 1 {
        Menu {
          ForEach(viewModel.services) { service in
            Button {
              Task {
                await viewModel.selectService(service.id)
              }
            } label: {
              if service.id == viewModel.selectedServiceID {
                Label(service.name, systemImage: "checkmark")
              } else {
                Text(service.name)
              }
            }
          }
        } label: {
          serviceLabel
        }
        .accessibilityLabel("Video service")
        .accessibilityIdentifier("live.home.service")
      } else {
        serviceLabel
          .accessibilityLabel(
            viewModel.services[0].name
          )
      }
    }
  }

  @ToolbarContentBuilder
  var searchToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Button {
        presentsSearch = true
      } label: {
        Image(systemName: "magnifyingglass")
      }
      .accessibilityLabel("Search")
      .accessibilityIdentifier("live.home.search")
    }
  }

  private var selectedService: VideoService {
    viewModel.services.first {
      $0.id == viewModel.selectedServiceID
    } ?? viewModel.services[0]
  }

  @ViewBuilder
  private var serviceLabel: some View {
    if let assetName = selectedService.assetName {
      Image(assetName)
        .resizable()
        .scaledToFit()
        .frame(width: 25, height: 25)
    } else {
      Image(systemName: selectedService.systemImage)
        .frame(width: 25, height: 25)
    }
  }
}
