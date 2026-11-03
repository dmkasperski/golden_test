#!/usr/bin/env bash
# Turns the fragments in changelog.d/ into the next release: computes the
# version from the bumps they ask for, writes the CHANGELOG section, sets
# `version` in pubspec.yaml, refreshes example/pubspec.lock and deletes the
# fragments it consumed.
#
# Run it from the package root, on master, with everything for the release
# merged. It changes files and commits nothing; review the diff, commit, then
# push the `v<version>` tag.
#
#   --dry-run   print what it would do and change nothing.
set -euo pipefail

cd "$(dirname "$0")/../.."

dry_run=false
[[ ${1:-} == --dry-run ]] && dry_run=true

fail() {
  echo "error: $1" >&2
  exit 1
}

# Every section a fragment may ask for, in the order they are written out.
sections=('Breaking changes' 'New features' 'Improvements' 'Fixes')

entries=()
for fragment in changelog.d/*.md; do
  [[ -e $fragment ]] || continue
  [[ $(basename "$fragment") == README.md ]] && continue
  entries+=("$fragment")
done
[[ ${#entries[@]} -gt 0 ]] ||
  fail "no fragments in changelog.d/, so there is nothing to release."

# `rank` orders the bumps so the largest one a fragment asks for wins.
rank_of() {
  case $1 in
  patch) echo 1 ;;
  minor) echo 2 ;;
  major) echo 3 ;;
  *) fail "fragment $2 has bump '$1'; expected major, minor or patch." ;;
  esac
}

# The value of a `key: value` line in the fragment's `---` header.
field() {
  awk -v key="$1" '
    NR == 1 && $0 == "---" { header = 1; next }
    header && $0 == "---" { exit }
    header && substr($0, 1, length(key) + 1) == key ":" {
      sub("^" key ": *", "")
      print
      exit
    }
  ' "$2"
}

# Everything after the header, without blank lines at either end.
body() {
  awk 'seen == 2 { print } $0 == "---" { seen++ }' "$1" |
    awk '
      NF || started { started = 1; lines[n++] = $0 }
      END {
        last = n
        while (last > 0 && lines[last - 1] == "") last--
        for (i = 0; i < last; i++) print lines[i]
      }
    '
}

highest=0
declare -a section_bodies
for i in "${!sections[@]}"; do section_bodies[i]=""; done

for fragment in "${entries[@]}"; do
  bump=$(field bump "$fragment")
  section=$(field section "$fragment")
  [[ -n $bump ]] || fail "fragment $fragment has no 'bump:' line."
  [[ -n $section ]] || fail "fragment $fragment has no 'section:' line."

  rank=$(rank_of "$bump" "$fragment")
  ((rank > highest)) && highest=$rank

  index=""
  for i in "${!sections[@]}"; do
    [[ ${sections[i]} == "$section" ]] && index=$i
  done
  [[ -n $index ]] ||
    fail "fragment $fragment has section '$section'; expected one of: ${sections[*]}."

  text=$(body "$fragment")
  [[ -n $text ]] || fail "fragment $fragment has no body."
  section_bodies[index]="${section_bodies[index]}${text}"$'\n'
done

current=$(sed -n 's/^version: *//p' pubspec.yaml)
[[ $current =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] ||
  fail "version '$current' in pubspec.yaml is not MAJOR.MINOR.PATCH."
major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}

case $highest in
3) version="$((major + 1)).0.0" ;;
2) version="$major.$((minor + 1)).0" ;;
1) version="$major.$minor.$((patch + 1))" ;;
esac

section_text=""
for i in "${!sections[@]}"; do
  [[ -n ${section_bodies[i]} ]] || continue
  section_text="${section_text}
### ${sections[i]}
${section_bodies[i]}"
done

entry="## $version
${section_text}"

echo "$current -> $version, from ${#entries[@]} fragment(s)."
if $dry_run; then
  echo
  echo "$entry"
  exit 0
fi

printf '%s\n%s' "$entry" "$(cat CHANGELOG.md)" >CHANGELOG.md.new
mv CHANGELOG.md.new CHANGELOG.md

# Only the package's own version, which is the first `version:` in the file.
sed -i '' "1,/^version:/s/^version: .*/version: $version/" pubspec.yaml 2>/dev/null ||
  sed -i "1,/^version:/s/^version: .*/version: $version/" pubspec.yaml

rm -- "${entries[@]}"

(cd example && flutter pub get >/dev/null) ||
  echo "warning: 'flutter pub get' in example/ failed; update pubspec.lock by hand." >&2

echo "Review the diff, commit it, then push the tag:"
echo "  git tag v$version && git push origin v$version"
