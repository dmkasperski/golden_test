---
bump: patch
section: Fixes
---
- **Snackbars now show in the widget's own `Scaffold`** — a snackbar goes to the outermost `Scaffold`s of its `ScaffoldMessenger`, and the widget under test sat inside the harness's own `Scaffold`, so snackbars showed there instead: across the whole screen, over the widget's own `bottomNavigationBar`, and once for a screen with two `Scaffold`s side by side, where an app shows one in each. The harness now puts a `ScaffoldMessenger` between its `Scaffold` and the widget under test. Goldens that show a snackbar will change and need regenerating.
