#!/usr/bin/env bash
# Smoke test for bin/generate. Copies the repository to a temporary
# directory, records a fake release from a fixture dist/, and checks
# every derived file.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  [ "$1" = "$2" ] || fail "$3: expected '$2', got '$1'"
}

cp -R "$root/bin" "$work/bin"
mkdir -p "$work/releases" "$work/dist"

# Two existing lines plus the release under test, so resolve/ has to
# pick the newest patch in one line and ignore the other.
for version in 0.1.0 0.1.1 0.2.0; do
  jq -n --arg v "$version" \
    '{ version: $v, date: "2026-01-01", files: {} }' \
    >"$work/releases/$version.json"
done

for platform in darwin-arm64 linux-x86_64; do
  tarball="$work/dist/koja-v0.2.1-$platform.tar.gz"
  printf 'fake %s\n' "$platform" >"$tarball"
  (cd "$work/dist" && shasum -a 256 "$(basename "$tarball")" >"$tarball.sha256")
done

"$work/bin/generate" 0.2.1 "$work/dist" >/dev/null

assert_eq "$(cat "$work/latest")" "0.2.1" "latest"
assert_eq "$(jq -r '.version' "$work/latest.json")" "0.2.1" "latest.json"
assert_eq "$(jq -r '.[0].version' "$work/index.json")" "0.2.1" "index.json newest first"
assert_eq "$(jq -r 'length' "$work/index.json")" "4" "index.json length"
assert_eq "$(tr '\n' ' ' <"$work/versions")" "0.1.0 0.1.1 0.2.0 0.2.1 " "versions oldest first"
assert_eq "$(cat "$work/resolve/0")" "0.2.1" "resolve major"
assert_eq "$(cat "$work/resolve/0.1")" "0.1.1" "resolve older line"
assert_eq "$(cat "$work/resolve/0.2")" "0.2.1" "resolve current line"
assert_eq "$(cat "$work/resolve/0.2.0")" "0.2.0" "resolve exact"

record="$work/releases/0.2.1.json"
assert_eq "$(jq -r '.files | keys | join(" ")' "$record")" "darwin-arm64 linux-x86_64" "record platforms"
assert_eq "$(jq -r '.files["darwin-arm64"].url' "$record")" \
  "https://github.com/koja-lang/koja/releases/download/v0.2.1/koja-v0.2.1-darwin-arm64.tar.gz" \
  "record url"
assert_eq "$(jq -r '.files["darwin-arm64"].sha256' "$record")" \
  "$(awk '{ print $1 }' "$work/dist/koja-v0.2.1-darwin-arm64.tar.gz.sha256")" \
  "record sha256"
assert_eq "$(jq -r '.files["darwin-arm64"].size' "$record")" \
  "$(wc -c <"$work/dist/koja-v0.2.1-darwin-arm64.tar.gz" | tr -d ' ')" \
  "record size"

# A second run over the same input must not change anything.
before="$(cd "$work" && find . -type f -not -path './dist/*' -exec shasum {} + | sort)"
"$work/bin/generate" >/dev/null
after="$(cd "$work" && find . -type f -not -path './dist/*' -exec shasum {} + | sort)"
[ "$before" = "$after" ] || fail "rebuild is not idempotent"

echo "ok"
