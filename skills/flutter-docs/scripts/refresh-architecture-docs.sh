#!/usr/bin/env bash
# Re-vendors the Flutter app-architecture pages from flutter/website (CC BY 4.0).
set -euo pipefail
DIR="$(cd "$(dirname "$0")/../references" && pwd)"
BASE="https://raw.githubusercontent.com/flutter/website/main/sites/docs/src/content/app-architecture"
for page in guide recommendations concepts; do
  {
    echo "<!-- Vendored from $BASE/$page.md on $(date +%F). Source: https://docs.flutter.dev/app-architecture/$page (CC BY 4.0) -->"
    curl -fsSL "$BASE/$page.md"
  } > "$DIR/flutter-architecture-$page.md"
  echo "wrote flutter-architecture-$page.md"
done
