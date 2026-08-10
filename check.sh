#!/usr/bin/env bash
#
# Gates mecánicos del catálogo. Salida 0 = todo verde.
# Estos tres gates han cazado deuda real: 13 skills sin cierre de §8 y varias con el frontmatter
# desalineado del nombre del directorio.

set -uo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO/skills" || { echo "No encuentro $REPO/skills" >&2; exit 1; }

fail=0
report() { printf '%-46s %s\n' "$1" "$2"; }

# 1. El campo `name` del frontmatter debe coincidir con el nombre del directorio, o la skill
#    no se registra.
mismatch=""
for d in */; do
  d="${d%/}"
  [ -f "$d/SKILL.md" ] || { mismatch+="  $d (sin SKILL.md)"$'\n'; continue; }
  n="$(grep -m1 '^name:' "$d/SKILL.md" | sed 's/^name: *//')"
  [ "$n" = "$d" ] || mismatch+="  $d -> '$n'"$'\n'
done
if [ -n "$mismatch" ]; then report "name == directorio" "FALLA"; printf '%s' "$mismatch"; fail=1
else report "name == directorio" "ok"; fi

# 2. Frontera declarada: sin la línea `**Not applicable**` la skill colisiona con sus vecinas.
#    Durante la migración a inglés (2026-08) se acepta la forma española `No aplica`; cuando no
#    quede ninguna, retirar la alternativa del patrón.
sinfrontera="$(grep -LE 'Not applicable|No aplica' */SKILL.md 2>/dev/null)"
if [ -n "$sinfrontera" ]; then report "frontera declarada en §1" "FALLA"; sed 's/^/  /' <<<"$sinfrontera"; fail=1
else report "frontera declarada en §1" "ok"; fi

# 3. Cierre canónico de §8. Sin él, una skill con un dato caducado gana la discusión contra la web.
#    Misma nota de migración que el gate 2.
sincierre="$(grep -LE 'the web wins|manda la web' */SKILL.md 2>/dev/null)"
if [ -n "$sincierre" ]; then report "cierre de arbitraje en §8" "FALLA"; sed 's/^/  /' <<<"$sincierre"; fail=1
else report "cierre de arbitraje en §8" "ok"; fi

echo
echo "skills: $(ls -d */ | wc -l)   líneas: $(cat */SKILL.md | wc -l)"
echo "coste de índice: $(grep -h '^description:' */SKILL.md | wc -w) palabras inyectadas en cada turno"
echo
echo "El test de colisión de disparadores vive en claude-code-skills-standards/SKILL.md §4.3."
exit $fail
