<!-- What changes and why. -->

## Checklist

- [ ] `CHANGELOG.md` has an entry for every change that package users act on. Repo infrastructure stays out.
- [ ] `version` in `pubspec.yaml` is either unchanged, or the next release on its major line that fits the change: breaking → major, new public API → minor, otherwise patch.
- [ ] If `version` changed, `CHANGELOG.md` starts with `## <version>` and `example/pubspec.lock` points at it (`flutter pub get` in `example/`).
- [ ] Goldens whose UI changed are regenerated, even if they pass under the tolerance.
