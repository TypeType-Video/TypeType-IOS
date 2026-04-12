import Foundation

extension WatchViewModel {
  func replies(for parentID: String) -> [WatchComment] {
    repliesByParentID[parentID] ?? []
  }

  func isLoadingReplies(for parentID: String) -> Bool {
    repliesLoadingParentIDs.contains(parentID)
  }

  func canLoadMoreReplies(for parentID: String, initialRepliesPage: String?) -> Bool {
    if repliesByParentID[parentID] == nil {
      return initialRepliesPage != nil
    }
    return repliesNextPageByParentID[parentID] != nil
  }

  func loadReplies(for parent: WatchComment) async {
    guard let initialRepliesPage = parent.repliesPage else { return }
    if repliesLoadingParentIDs.contains(parent.id) { return }

    let nextToken = repliesByParentID[parent.id] == nil
      ? initialRepliesPage
      : repliesNextPageByParentID[parent.id]
    guard let nextToken else { return }

    repliesLoadingParentIDs.insert(parent.id)
    defer { repliesLoadingParentIDs.remove(parent.id) }

    do {
      let page = try await watchService.commentReplies(for: videoURL, repliesPage: nextToken)
      let existing = repliesByParentID[parent.id] ?? []
      repliesByParentID[parent.id] = existing + page.comments
      repliesNextPageByParentID[parent.id] = page.nextPage
    } catch {
      // Ignore transient reply load errors.
    }
  }
}
