#!/usr/bin/env bash
# Validates plugin structure. Exit 1 on any FAIL line.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
err() { echo "FAIL: $*"; fail=1; }

# 1. JSON manifests parse
for j in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json; do
  [ -f "$ROOT/$j" ] || { err "$j missing"; continue; }
  python3 -m json.tool "$ROOT/$j" >/dev/null 2>&1 || err "$j is not valid JSON"
done

# 2. Skills
count=0
for dir in "$ROOT"/skills/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  f="$dir/SKILL.md"
  [ -f "$f" ] || { err "$name: missing SKILL.md"; continue; }
  count=$((count + 1))
  head -1 "$f" | grep -q '^---$' || err "$name: no frontmatter"
  fm_name="$(sed -n '2,12p' "$f" | grep -m1 '^name:' | sed 's/^name:[[:space:]]*//')"
  [ "$fm_name" = "$name" ] || err "$name: frontmatter name is '$fm_name'"
  desc="$(sed -n '2,12p' "$f" | grep -m1 '^description:' | sed 's/^description:[[:space:]]*//')"
  [ -n "$desc" ] || err "$name: empty description"
  for rel in $(grep -oE '(references|scripts)/[A-Za-z0-9_./-]+' "$f" | sort -u); do
    [ -e "$dir$rel" ] || err "$name: link to missing $rel"
  done
done
echo "checked $count skills"

# 3. No Ruby leftovers (skills/systematic-debugging and skills/brainstorming use
# illustrative Ruby deliberately and are allowlisted)
if [ -d "$ROOT/skills" ]; then
  leftovers="$(grep -rnE 'superpowers-ruby|bin/rails|Minitest|Gemfile|Rails\.|config/initializers|db/schema\.rb|\bRSpec\b|```ruby' "$ROOT/skills" "$ROOT/hooks" "$ROOT/agents" 2>/dev/null \
    | grep -vE "^$ROOT/skills/(systematic-debugging|brainstorming)/" || true)"
  [ -z "$leftovers" ] || err "Ruby leftovers:
$leftovers"
fi

# 4. session-start emits valid JSON mentioning Flutter
if [ -f "$ROOT/hooks/session-start" ]; then
  out="$(CLAUDE_PLUGIN_ROOT="$ROOT" bash "$ROOT/hooks/session-start" 2>&1)"
  printf '%s' "$out" | python3 -m json.tool >/dev/null 2>&1 || err "session-start output is not valid JSON"
  printf '%s' "$out" | grep -q 'superpowers for Flutter' || err "session-start does not mention Flutter"
fi

[ "$fail" -eq 0 ] && echo OK
exit "$fail"
