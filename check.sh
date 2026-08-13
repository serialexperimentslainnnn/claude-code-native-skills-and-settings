#!/usr/bin/env bash
#
# Mechanical gates for the catalogue. Exit 0 = all green.
# These three gates have caught real debt: 13 skills with no §8 arbitration close, and several
# whose frontmatter name did not match the directory.

set -uo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO/skills" || { echo "Cannot find $REPO/skills" >&2; exit 1; }

fail=0
report() { printf '%-46s %s\n' "$1" "$2"; }

# 1. The frontmatter `name` field must equal the directory name, or the skill is not registered.
mismatch=""
for d in */; do
  d="${d%/}"
  [ -f "$d/SKILL.md" ] || { mismatch+="  $d (no SKILL.md)"$'\n'; continue; }
  n="$(grep -m1 '^name:' "$d/SKILL.md" | sed 's/^name: *//')"
  [ "$n" = "$d" ] || mismatch+="  $d -> '$n'"$'\n'
done
if [ -n "$mismatch" ]; then report "name == directory" "FAIL"; printf '%s' "$mismatch"; fail=1
else report "name == directory" "ok"; fi

# 2. Declared boundary: without the `**Not applicable**` line the skill collides with its
#    neighbours. The Spanish alternative `No aplica` was accepted during the 2026-08 migration and
#    was retired on 2026-08-13, once the last Spanish body was translated: a bilingual gate cannot
#    tell a finished migration from a regression.
noboundary="$(grep -L 'Not applicable' */SKILL.md 2>/dev/null)"
if [ -n "$noboundary" ]; then report "declared boundary in §1" "FAIL"; sed 's/^/  /' <<<"$noboundary"; fail=1
else report "declared boundary in §1" "ok"; fi

# 3. Canonical §8 close. Without it, a skill holding an expired fact wins the argument against
#    the web. Spanish alternative retired on 2026-08-13, same as gate 2.
noclose="$(grep -L 'the web wins' */SKILL.md 2>/dev/null)"
if [ -n "$noclose" ]; then report "arbitration close in §8" "FAIL"; sed 's/^/  /' <<<"$noclose"; fail=1
else report "arbitration close in §8" "ok"; fi

# Index cost counts only what is actually injected. Per the official documentation, a skill with
# `disable-model-invocation: true` keeps its description OUT of context, so counting it overstates
# the per-turn cost and punishes the right choice for side-effecting skills.
indexed="$(grep -L '^disable-model-invocation: true' */SKILL.md)"
manual_only=$(( $(ls -d */ | wc -l) - $(wc -w <<<"$indexed") ))

echo
echo "skills: $(ls -d */ | wc -l)   lines: $(cat */SKILL.md | wc -l)"
echo "index cost: $(grep -h '^description:' $indexed | wc -w) words injected on every turn   (manual-only, not indexed: $manual_only)"
echo
echo "The trigger-collision test lives in claude-code-skills-standards/SKILL.md §4.3."
exit $fail
