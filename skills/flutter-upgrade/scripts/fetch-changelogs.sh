#!/usr/bin/env bash
# Prints the CHANGELOG of each pub.dev package given as argument.
# Usage: fetch-changelogs.sh go_router flutter_bloc
set -euo pipefail
[ $# -gt 0 ] || { echo "usage: $0 <package>..." >&2; exit 2; }
for pkg in "$@"; do
  echo "===== $pkg ====="
  url="https://pub.dev/api/packages/$pkg"
  latest="$(curl -fsSL "$url" | python3 -c 'import json,sys; print(json.load(sys.stdin)["latest"]["version"])')"
  echo "latest: $latest"
  # pub.dev serves the raw changelog of the package archive under /documentation; the API exposes the archive URL.
  archive="$(curl -fsSL "$url" | python3 -c 'import json,sys; print(json.load(sys.stdin)["latest"]["archive_url"])')"
  tmp="$(mktemp -d)"
  curl -fsSL "$archive" | tar -xz -C "$tmp" 2>/dev/null || true
  if [ -f "$tmp/CHANGELOG.md" ]; then
    sed -n '1,120p' "$tmp/CHANGELOG.md"
  else
    echo "(no CHANGELOG.md in archive; see https://pub.dev/packages/$pkg/changelog)"
  fi
  rm -rf "$tmp"
  echo
done
