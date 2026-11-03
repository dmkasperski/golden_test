# Changelog fragments

An unreleased change does not go into `CHANGELOG.md`. It goes into a file of
its own here, and `prepare_release.sh` collects them into a section when the
release is cut.

Two reasons:

- **No conflicts.** Two branches adding an entry each write their own file,
  so they never touch the same lines.
- **The version is decided at the end.** A branch does not know which release
  it lands in, or what else lands with it. The version is computed from the
  fragments actually on `master` when the release is prepared, so a change
  that slips to the next release takes its bump with it.

## Writing one

One file per entry, named after the change (`duo-support.md`,
`fix-snackbar-scaffold.md`); the name is never shown. Markdown, with a short
header:

```markdown
---
bump: minor
section: New features
---
- **Keyboard**: `goldenTest` takes a `keyboard`, which shows the software
  keyboard over the bottom of the screen for the whole test.
```

- **`bump`** is `major`, `minor` or `patch`, for what this change alone would
  require: `major` for a breaking change, `minor` for new public API,
  `patch` otherwise. The release takes the largest bump among its fragments.
- **`section`** is the heading it goes under: `Breaking changes`,
  `New features`, `Improvements` or `Fixes`. Fragments sharing a section are
  listed under one heading, in filename order.
- **The body** is the entry itself, as bullets, written for someone upgrading
  the package: what changed, what they have to do about it, and a link to the
  README section when there is one.

A change with both a feature and a fix gets a fragment for each.

Repo infrastructure — CI, this process, the example app — changes nothing for
package users, so it gets no fragment.

## Cutting a release

From the package root, on `master`, with everything merged:

```sh
.github/scripts/prepare_release.sh
```

It computes the version, writes the section into `CHANGELOG.md`, sets
`version` in `pubspec.yaml`, updates `example/pubspec.lock` and deletes the
fragments it consumed. Review the result, commit it, then push the `v<version>`
tag; `check_release.sh` verifies the rest before anything reaches pub.dev.
