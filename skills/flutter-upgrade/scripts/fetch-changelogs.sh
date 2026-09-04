#!/usr/bin/env bash
# Prints the CHANGELOG of each pub.dev package given as argument.
# Usage: fetch-changelogs.sh go_router flutter_bloc
set -uo pipefail
[ $# -gt 0 ] || { echo "usage: $0 <package>..." >&2; exit 2; }
failed=0
for pkg in "$@"; do
  echo "===== $pkg ====="
  url="https://pub.dev/api/packages/$pkg"
  meta="$(curl -fsSL "$url" 2>/dev/null)"
  if [ -z "$meta" ]; then
    echo "error: could not fetch metadata for $pkg (bad package name or network error)" >&2
    failed=1
    echo
    continue
  fi
  parsed="$(python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)["latest"]
    print(d["version"])
    print(d["archive_url"])
except Exception:
    sys.exit(1)' <<<"$meta")"
  if [ -z "$parsed" ]; then
    echo "error: could not parse pub.dev metadata for $pkg" >&2
    failed=1
    echo
    continue
  fi
  latest="$(sed -n '1p' <<<"$parsed")"
  archive="$(sed -n '2p' <<<"$parsed")"
  if [ -z "${latest:-}" ] || [ -z "${archive:-}" ]; then
    echo "error: could not parse pub.dev metadata for $pkg" >&2
    failed=1
    echo
    continue
  fi
  echo "latest: $latest"
  # pub.dev serves the raw changelog of the package archive under /documentation; the API exposes the archive URL.
  tmp="$(mktemp -d)"
  curl -fsSL "$archive" 2>/dev/null | tar -xz -C "$tmp" 2>/dev/null || true
  if [ -f "$tmp/CHANGELOG.md" ]; then
    sed -n '1,120p' "$tmp/CHANGELOG.md"
  else
    echo "(no CHANGELOG.md in archive; see https://pub.dev/packages/$pkg/changelog)"
  fi
  rm -rf "$tmp"
  echo
done
exit $failed
