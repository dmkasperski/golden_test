#!/usr/bin/env bash
# Fails a pull request that changes the package's public behaviour without
# adding a fragment to changelog.d/.
#
# Reads BASE (the sha the PR is merging into) and LABELS (its labels, comma
# separated). A PR labelled `skip changelog` is let through: use it for a
# change package users cannot observe.
set -euo pipefail

cd "$(dirname "$0")/../.."

base=${BASE:?}
labels=${LABELS:-}

if [[ ,$labels, == *,skip\ changelog,* ]]; then
  echo "Labelled 'skip changelog'."
  exit 0
fi

changed=$(git diff --name-only --diff-filter=d "$base"...HEAD)

# Only lib/ reaches package users. The example, the tests, the skills, CI and
# this process itself change nothing they can observe.
if ! grep -q '^lib/' <<<"$changed"; then
  echo "No change under lib/, so no fragment is needed."
  exit 0
fi

if grep '^changelog\.d/.*\.md$' <<<"$changed" | grep -qvx 'changelog.d/README.md'; then
  echo "Fragment found."
  exit 0
fi

cat >&2 <<'MESSAGE'
::error::This pull request changes lib/ but adds no changelog fragment.

Add one file under changelog.d/ describing the change for package users;
changelog.d/README.md says how. If users cannot observe this change, label
the pull request `skip changelog` instead.
MESSAGE
exit 1
