import SwiftUI

struct LiveBlockedKeywordsView: View {
  let service: LiveContentControlsServiceProtocol
  @StateObject private var viewModel: LiveBlockedKeywordsViewModel

  init(service: LiveContentControlsServiceProtocol) {
    self.service = service
    _viewModel = StateObject(
      wrappedValue: LiveBlockedKeywordsViewModel(service: service)
    )
  }

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle, .loading:
        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
      case let .failed(message):
        ContentUnavailableView {
          Label("Blocked keywords unavailable", systemImage: "text.badge.xmark")
        } description: {
          Text(message)
        } actions: {
          Button("Try again") {
            Task { await viewModel.reload() }
          }
        }
      case .loaded:
        list
      }
    }
    .task { await viewModel.prepare() }
    .refreshable { await viewModel.reload() }
    .alert("Blocked keywords", isPresented: errorBinding) {
      Button("OK") { viewModel.dismissError() }
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
  }

  private var list: some View {
    List {
      Section {
        HStack {
          TextField("Add keyword", text: $viewModel.keyword)
            .textInputAutocapitalization(.never)
            .submitLabel(.done)
            .onSubmit {
              Task { await viewModel.add() }
            }
          Button {
            Task { await viewModel.add() }
          } label: {
            if viewModel.isBusy {
              ProgressView()
            } else {
              Image(systemName: "plus.circle.fill")
            }
          }
          .disabled(!viewModel.canAdd)
        }
      } footer: {
        Text("Videos whose title contains a blocked keyword are hidden.")
      }

      if viewModel.keywords.isEmpty {
        Section {
          Text("No blocked keywords")
            .foregroundStyle(.secondary)
        }
      } else {
        Section {
          ForEach(viewModel.keywords) { item in
            HStack {
              VStack(alignment: .leading, spacing: 2) {
                Text(item.keyword)
                if item.global == true {
                  Text("Global")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DemoTheme.accent)
                }
              }
              Spacer()
              Button("Remove", role: .destructive) {
                Task { await viewModel.remove(item) }
              }
              .disabled(viewModel.isBusy)
            }
          }
        } header: { Text("Keywords").liveSectionHeader() }
      }
    }
    .listStyle(.plain)
  }

  private var errorBinding: Binding<Bool> {
    Binding(
      get: { viewModel.errorMessage != nil },
      set: { if !$0 { viewModel.dismissError() } }
    )
  }
}
