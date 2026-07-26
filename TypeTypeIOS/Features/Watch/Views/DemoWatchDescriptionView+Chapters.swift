extension DemoWatchDescriptionView {
  var visibleChapters: [DemoWatchChapter] {
    guard session.preferences.sponsorBlock,
      session.preferences.sponsorBlockShowsChapters,
      session.preferences.sponsorBlockCategoryActions["sponsor"] != "Hide"
    else {
      return DemoWatchCatalog.chapters
    }
    let sponsor = DemoWatchChapter(
      id: "sponsorblock-sponsor",
      title: "Sponsor · community segment",
      timestamp: "0:04",
      seconds: 4
    )
    return [DemoWatchCatalog.chapters[0], sponsor]
      + DemoWatchCatalog.chapters.dropFirst()
  }
}
