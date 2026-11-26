---
bump: minor
section: New features
---
- **The status bar's glyphs follow the app's `SystemUiOverlayStyle`**: the frame used to draw the clock and the status icons in the golden's brightness, black in a light theme, whatever the app drew under them. A device takes their colour from the style the app sets under the bar, as an `AppBar` or an `AnnotatedRegion` does, so a dark app bar or a red banner in a light theme gets white glyphs. The harness now finds that style as the framework does before sending it to the system, and the frame draws what the device would: Android reads `statusBarIconBrightness`, iOS draws the opposite of `statusBarBrightness`. Without a style the glyphs follow the golden's brightness as before. **Goldens whose app sets a status bar style that differs from the theme's brightness will move and need regenerating.**
