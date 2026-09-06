#!/usr/bin/env bash
# Shows what obra/superpowers changed, between two tags, in the skills and hooks
# this plugin carries. Diffs upstream against upstream, so our Flutter
# adaptations never show up as noise.
#
#   scripts/upstream-diff.sh                # UPSTREAM_VERSION -> latest tag
#   scripts/upstream-diff.sh v6.3.0 v6.4.0  # explicit range
#
# Exit 0 when nothing we carry changed, 1 when something did (full diff written
# to $OUT, default upstream-<old>..<new>.diff in the current directory).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="https://github.com/obra/superpowers.git"
OLD="${1:-$(cat "$ROOT/UPSTREAM_VERSION")}"
NEW="${2:-$(git ls-remote --tags --refs "$REPO" 'v*' | awk -F/ '{print $NF}' | sort -V | tail -1)}"
OUT="${OUT:-upstream-$OLD..$NEW.diff}"
SHARED=(brainstorming dispatching-parallel-agents executing-plans finishing-a-development-branch
  receiving-code-review requesting-code-review subagent-driven-development systematic-debugging
  test-driven-development using-git-worktrees using-superpowers verification-before-completion
  writing-plans writing-skills)

if [ "$OLD" = "$NEW" ]; then echo "upstream is at $NEW, same as UPSTREAM_VERSION"; exit 0; fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for tag in "$OLD" "$NEW"; do
  git clone -q --depth 1 --branch "$tag" "$REPO" "$tmp/$tag" 2>/dev/null || { echo "cannot fetch tag $tag" >&2; exit 2; }
done

echo "obra/superpowers $OLD -> $NEW"
: > "$OUT"; changed=0
for s in "${SHARED[@]}"; do
  if d="$(diff -ru "$tmp/$OLD/skills/$s" "$tmp/$NEW/skills/$s" 2>&1)"; then
    printf '  %-34s unchanged\n' "$s"
  else
    add=$(grep -c '^+[^+]' <<<"$d" || true); del=$(grep -c '^-[^-]' <<<"$d" || true)
    printf '  %-34s CHANGED  +%s/-%s\n' "$s" "$add" "$del"; printf '%s\n' "$d" >> "$OUT"; changed=1
  fi
done
if d="$(diff -ru "$tmp/$OLD/hooks" "$tmp/$NEW/hooks" 2>&1)"; then printf '  %-34s unchanged\n' hooks
else printf '  %-34s CHANGED\n' hooks; printf '%s\n' "$d" >> "$OUT"; changed=1; fi
extra="$(comm -13 <(ls "$tmp/$OLD/skills") <(ls "$tmp/$NEW/skills") | tr '\n' ' ')"
[ -z "$extra" ] || echo "  new upstream skills not in this plugin: $extra"

if [ "$changed" -eq 1 ]; then echo "full diff: $OUT"; exit 1; fi
rm -f "$OUT"; echo "nothing we carry changed"
