---
bump: major
section: Breaking changes
---
- **The theme carries `Device.platform`**: `flutter test` reports Android whatever device a golden runs on, so a golden of `Device.iphone15Pro()` said iPhone and drew Android. `Theme.of(context).platform` now follows the device, which is what adaptive widgets, the back icon, the scroll physics and the text selection controls read. **Goldens of a device whose `platform` is not Android will change and need regenerating**; a device with no `platform` of its own is unaffected. The default device is `Device.iphone15Pro()`, so a project that has not changed it will see every golden move. `defaultTargetPlatform` itself is deliberately left alone: every `ThemeData` resolves its typography from it when it is built, and a test environment has fonts for Android only, so overriding it renders every glyph as a blank box — including inside a widget that builds an app or a theme of its own.
