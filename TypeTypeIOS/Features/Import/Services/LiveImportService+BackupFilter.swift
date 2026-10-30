import Foundation

extension LiveImportService {
  static func filterTypeTypeBackup(
    data: Data,
    categories: Set<LiveTypeTypeBackupCategory>
  ) throws -> Data {
    let object = try JSONSerialization.jsonObject(with: data)
    guard var backup = object as? [String: Any] else {
      throw NetworkError.decoding
    }

    let fieldNames: [LiveTypeTypeBackupCategory: String] = [
      .subscriptions: "subscriptions",
      .history: "history",
      .playlists: "playlists",
      .watchLater: "watchLater",
      .favorites: "favorites",
      .progress: "progress",
      .searchHistory: "searchHistory",
      .savedPlaylists: "savedPlaylists",
      .settings: "settings",
      .contentFilters: "contentFilters",
      .subscriptionGroups: "subscriptionGroups",
    ]

    let declaredCategories = Set(
      (backup["categories"] as? [String] ?? []).compactMap {
        LiveTypeTypeBackupCategory(rawValue: $0)
      }
    )
    let sourceCategories: Set<LiveTypeTypeBackupCategory>
    if declaredCategories.isEmpty {
      sourceCategories = Set(
        LiveTypeTypeBackupCategory.allCases.filter { category in
          backup[fieldNames[category] ?? category.rawValue] != nil
        }
      )
    } else {
      sourceCategories = declaredCategories
    }

    let selectedCategories = categories.intersection(sourceCategories)
    backup["categories"] = selectedCategories
      .map(\.rawValue)
      .sorted()
    for category in LiveTypeTypeBackupCategory.allCases
    where !selectedCategories.contains(category) {
      backup.removeValue(forKey: fieldNames[category] ?? category.rawValue)
    }

    return try JSONSerialization.data(
      withJSONObject: backup,
      options: [.sortedKeys]
    )
  }
}
