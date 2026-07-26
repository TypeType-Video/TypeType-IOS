enum DemoSearchResultState: String, CaseIterable, Identifiable {
  case normal = "Normal"
  case loading = "Loading"
  case error = "Error"

  var id: String { rawValue }
}
