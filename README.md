<!-- markdownlint-disable MD033 MD041 -->

<div align="center">
  <img src="https://raw.githubusercontent.com/TypeType-Video/TypeType/main/assets/banner.svg" alt="TypeType" width="100%">
  <h1>TypeType iOS</h1>
  <p>The native iPhone and iPad client for a self-hosted <a href="https://github.com/TypeType-Video/TypeType">TypeType</a> instance.</p>
</div>

| Subscriptions | Search | Watch | Library |
| --- | --- | --- | --- |
| ![Subscriptions](assets/screenshots/iphone-subscriptions.png) | ![Search](assets/screenshots/iphone-search.png) | ![Watch](assets/screenshots/iphone-player.png) | ![Library](assets/screenshots/iphone-playlists.png) |

YouTube, BiliBili and NicoNico in SwiftUI, with an in-house native player,
Android-style gestures, Picture in Picture, downloads and offline playback. The
app only talks to [TypeType-Server](https://github.com/TypeType-Video/TypeType-Server).

## Build

Needs Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
xcodebuild -project TypeTypeIOS.xcodeproj -scheme TypeTypeIOSUnit \
  -destination "platform=iOS Simulator,name=iPhone 17" test
```

Work goes to `dev`, `main` is stable. Issues go to the
[central tracker](https://github.com/TypeType-Video/TypeType/issues).
TypeType's position on AI:
[AI_TRANSPARENCY.md](https://github.com/TypeType-Video/TypeType/blob/dev/AI_TRANSPARENCY.md).

## License

[MPL 2.0](LICENSE). Copyright © 2026 Priveetee and TypeType contributors.
Screenshots show public YouTube videos from a test account.
