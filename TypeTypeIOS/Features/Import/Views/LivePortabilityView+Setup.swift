import SwiftUI

extension LivePortabilityView {
  @ViewBuilder
  var setupSection: some View {
    LiveSection {
      if viewModel.state == .loadingFormats {
        HStack {
          Text("Loading formats")
          Spacer()
          ProgressView()
        }
      } else if let format = viewModel.selectedFormat {
        Picker("Destination format", selection: formatBinding) {
          ForEach(viewModel.formats) { format in
            Text(portabilityFormatTitle(format.format)).tag(format)
          }
        }
        LabeledContent("Adapter", value: "v\(format.adapterVersion)")
      }
    } header: { Text("Format").liveSectionHeader() }

    if !viewModel.activeCategories.isEmpty {
      LiveSection {
        Button("Select all") {
          viewModel.selectedCategories = Set(
            viewModel.activeCategories.map(\.rawValue)
          )
        }
        ForEach(viewModel.activeCategories) { category in
          Toggle(category.title, isOn: categoryBinding(category))
        }
      } header: { Text("Categories").liveSectionHeader() }
    }

    actionSection
  }

  @ViewBuilder
  var actionSection: some View {
    if viewModel.mode == .import {
      LiveSection {
        Button("Choose or drop a backup file") {
          showsFilePicker = true
        }
        if let name = viewModel.selectedFileName {
          LabeledContent("Selected", value: name)
        }
      } header: { Text("Backup file").liveSectionHeader() }
    }

    LiveSection {
      if viewModel.mode == .export {
        Button {
          Task { await viewModel.start() }
        } label: {
          if viewModel.isStartingJob {
            ProgressView()
          } else {
            Text("Generate export")
          }
        }
        .disabled(!viewModel.canStart)
      } else if let format = viewModel.selectedFormat {
        Button("Choose another backup") {
          showsFilePicker = true
        }
        Button {
          Task { await viewModel.start() }
        } label: {
          if viewModel.isStartingJob {
            ProgressView()
          } else {
            Text("Analyze \(portabilityFormatTitle(format.format))")
          }
        }
        .disabled(!viewModel.canStart)
      }
    } footer: {
      if viewModel.selectedCategories.isEmpty {
        Text("Select at least one category.")
      }
    }
  }

  var modeBinding: Binding<LivePortabilityViewModel.Mode> {
    Binding(
      get: { viewModel.mode },
      set: { mode in Task { await viewModel.selectMode(mode) } }
    )
  }

  var formatBinding: Binding<LivePortabilityFormat> {
    Binding(
      get: { viewModel.selectedFormat ?? viewModel.formats.first! },
      set: viewModel.selectFormat
    )
  }

  var policyBinding: Binding<Bool> {
    Binding(
      get: { viewModel.duplicatePolicy == .skip },
      set: {
        viewModel.duplicatePolicy = $0 ? .skip : .replace
      }
    )
  }

  func categoryBinding(
    _ category: LiveTypeTypeBackupCategory
  ) -> Binding<Bool> {
    Binding(
      get: { viewModel.selectedCategories.contains(category.rawValue) },
      set: { _ in viewModel.toggle(category) }
    )
  }
}
