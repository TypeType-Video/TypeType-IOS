import Foundation

enum PictureInPictureRestore {
  static func restore(
    canRestore: Bool,
    prepare: () -> Void,
    isPrepared: () -> Bool,
    completion: (Bool) -> Void
  ) {
    guard canRestore else {
      completion(false)
      return
    }

    prepare()
    completion(isPrepared())
  }
}
