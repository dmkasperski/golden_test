<!-- What changes and why. -->

## Checklist

- [ ] A fragment in `changelog.d/` for every change package users act on, written for someone upgrading ([how](../blob/master/changelog.d/README.md)). Repo infrastructure needs none — label the PR `skip changelog` instead.
- [ ] `version` in `pubspec.yaml` is **unchanged**. The release sets it: `prepare_release.sh` computes it from the fragments on `master` when the release is cut.
- [ ] Goldens whose UI changed are regenerated, even if they pass under the tolerance.
