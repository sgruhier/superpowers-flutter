#!/usr/bin/env bash
# Re-vendors Effective Dart from dart-lang/site-www (CC BY 4.0).
set -euo pipefail
DIR="$(cd "$(dirname "$0")/../references" && pwd)"
BASE="https://raw.githubusercontent.com/dart-lang/site-www/main/src/content/effective-dart"
for page in style documentation usage design; do
  {
    echo "<!-- Vendored from $BASE/$page.md on $(date +%F). Source: https://dart.dev/effective-dart/$page (CC BY 4.0) -->"
    curl -fsSL "$BASE/$page.md"
  } > "$DIR/effective-dart-$page.md"
  echo "wrote effective-dart-$page.md"
done
