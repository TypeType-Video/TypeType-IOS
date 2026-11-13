import CoreImage.CIFilterBuiltins
import SwiftUI

struct LiveLinkedAccountsView: View {
  @StateObject private var viewModel: LiveLinkedAccountsViewModel
  @Environment(\.openURL) private var openURL

  init(youtube: LiveYouTubeSessionServiceProtocol, service: LiveLinkedAccountsServiceProtocol) {
    _viewModel = StateObject(wrappedValue: LiveLinkedAccountsViewModel(youtube: youtube, service: service))
  }

  var body: some View {
    List {
      youtubeSection
      biliBiliSection
    }
    .liveGroupedList()
    .navigationTitle("Linked accounts")
    .navigationBarTitleDisplayMode(.inline)
    .task { await viewModel.refresh() }
    .onDisappear { viewModel.stop() }
  }

  private var youtubeSection: some View {
    LiveSection {
      statusRow(connected: viewModel.youtubeConnected)
      if let login = viewModel.youtubeLogin {
        VStack(alignment: .leading, spacing: 8) {
          Text("Enter this code on YouTube:")
          Text(verbatim: login.userCode)
            .font(.title.monospaced().weight(.bold))
            .textSelection(.enabled)
            .accessibilityIdentifier("live.linked.youtube-code")
          ProgressView().controlSize(.small)
        }
        if let url = URL(string: login.verificationURL) {
          Button("Open the YouTube page") { openURL(url) }
        }
        Button("Cancel", role: .cancel) { viewModel.cancelYouTube() }
      } else if viewModel.youtubeConnected == true {
        Button("Disconnect", role: .destructive) { Task { await viewModel.disconnectYouTube() } }
          .disabled(viewModel.isBusy)
      } else {
        Button("Connect with a code") { viewModel.startYouTube() }
          .accessibilityIdentifier("live.linked.youtube-connect")
      }
    } header: {
      Text("YouTube").liveSectionHeader()
    } footer: {
      footer(error: viewModel.youtubeError, hint: "For videos that need a signed-in YouTube session. A secondary account is recommended.")
    }
  }

  private var biliBiliSection: some View {
    LiveSection {
      statusRow(connected: viewModel.biliBiliState.map { $0 == .connected })
      if viewModel.biliBiliState == .needsReconnect {
        Text("The BiliBili session expired. Connect again.")
          .foregroundStyle(.orange)
      }
      if let qr = viewModel.biliBiliQR {
        VStack(spacing: 10) {
          if let image = Self.qrImage(qr.qrURL) {
            Image(uiImage: image)
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 200, height: 200)
              .padding(10)
              .background(.white, in: RoundedRectangle(cornerRadius: 12))
              .accessibilityLabel("BiliBili sign-in QR code")
          }
          Text(viewModel.biliBiliScanned ? "Scanned. Confirm in the BiliBili app." : "Scan this code with the BiliBili app.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        if let url = URL(string: qr.qrURL) {
          Button("Open in BiliBili") { openURL(url) }
        }
        Button("Cancel", role: .cancel) { viewModel.cancelBiliBili() }
      } else if viewModel.biliBiliState == .connected {
        Button("Disconnect", role: .destructive) { Task { await viewModel.disconnectBiliBili() } }
          .disabled(viewModel.isBusy)
      } else {
        Button("Connect with a QR code") { viewModel.startBiliBili() }
          .accessibilityIdentifier("live.linked.bilibili-connect")
      }
    } header: {
      Text("BiliBili").liveSectionHeader()
    } footer: {
      footer(error: viewModel.biliBiliError, hint: "For BiliBili videos in higher quality or that need an account.")
    }
  }

  @ViewBuilder
  private func statusRow(connected: Bool?) -> some View {
    switch connected {
    case nil:
      ProgressView()
    case let .some(isConnected):
      Label(
        isConnected ? "Connected" : "Not connected",
        systemImage: isConnected ? "checkmark.seal.fill" : "person.crop.circle.badge.questionmark"
      )
      .foregroundStyle(isConnected ? Color.green : Color.secondary)
    }
  }

  private func footer(error: String?, hint: LocalizedStringKey) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      if let error {
        Text(error).foregroundStyle(.red)
      }
      Text(hint)
    }
    .font(.footnote)
    .foregroundStyle(.secondary)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  static func qrImage(_ text: String) -> UIImage? {
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(text.utf8)
    filter.correctionLevel = "M"
    guard let output = filter.outputImage,
      let image = CIContext().createCGImage(output, from: output.extent)
    else { return nil }
    return UIImage(cgImage: image)
  }
}
