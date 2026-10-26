#!/usr/bin/env bash
# Validates a release before Publish uploads it. Runs from the package root
# for a pushed `v<version>` tag, with the full git history fetched.
#
# Writes `version`, `previous` (the release it follows) and `maintenance`
# (whether it is for an older major line) to $GITHUB_OUTPUT, and a summary
# to $GITHUB_STEP_SUMMARY.
set -euo pipefail

package=golden_test
tag=${GITHUB_REF_NAME:?}
sha=${GITHUB_SHA:?}

fail() {
  echo "::error::$1"
  exit 1
}

version=$(sed -n 's/^version: *//p' pubspec.yaml)
[[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] ||
  fail "version '$version' in pubspec.yaml is not MAJOR.MINOR.PATCH."
major=${BASH_REMATCH[1]}

[[ $tag == "v$version" ]] ||
  fail "Tag $tag does not match version $version in pubspec.yaml."

published=$(
  curl -sSf "https://pub.dev/api/packages/$package" |
    jq -r '.versions[].version' |
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' |
    sort -V
)
if grep -qx "$version" <<<"$published"; then
  fail "$version is already published on pub.dev."
fi

latest=$(tail -n 1 <<<"$published")
latest_major=${latest%%.*}
line_latest=$(grep -E "^$major\." <<<"$published" | tail -n 1 || true)

if [[ -n $line_latest ]]; then
  IFS=. read -r _ minor patch <<<"$line_latest"
  next_patch="$major.$minor.$((patch + 1))"
  next_minor="$major.$((minor + 1)).0"
  case $version in
    "$next_patch") kind=patch ;;
    "$next_minor") kind=minor ;;
    *) fail "$version does not follow $line_latest, the latest $major.x release: expected $next_patch or $next_minor." ;;
  esac
  previous=$line_latest
else
  next_major="$((latest_major + 1)).0.0"
  [[ $version == "$next_major" ]] ||
    fail "$version starts a new major line, so it must be $next_major (latest release is $latest)."
  kind=major
  previous=$latest
fi

if ((major < latest_major)); then
  maintenance=true
  branch="$major.x"
else
  maintenance=false
  branch=master
fi

git rev-parse --verify --quiet "origin/$branch" >/dev/null ||
  fail "Branch $branch does not exist, so $version has no line to be released from."
git merge-base --is-ancestor "$sha" "origin/$branch" ||
  fail "Tag $tag is not on $branch. Releases of $major.x are tagged on $branch."

heading=$(grep -m 1 '^## ' CHANGELOG.md || true)
[[ $heading == "## $version" ]] ||
  fail "CHANGELOG.md must start with a '## $version' section, found '${heading:-nothing}'."

{
  echo "version=$version"
  echo "previous=$previous"
  echo "maintenance=$maintenance"
} >>"$GITHUB_OUTPUT"

{
  echo "### Releasing $package $version"
  echo
  echo "- **$kind** release after $previous, tagged on \`$branch\`."
  if [[ $maintenance == true ]]; then
    echo "- **Maintenance release** for the $major.x line, while the latest release is $latest. It needs a second approval in the \`pub.dev-maintenance\` environment."
  fi
} >>"$GITHUB_STEP_SUMMARY"
