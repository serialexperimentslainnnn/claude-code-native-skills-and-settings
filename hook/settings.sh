# shellcheck shell=bash
#
# Lo carga install.sh con `.`: aquí vive TODO lo que toca ~/.claude/settings.json, que es del
# usuario (env, permisos, modelo). Este repo gestiona una sola entrada: el hook UserPromptSubmit que
# vuelca how-to-work.md en cada turno. La sesión carga CLAUDE.md una vez y el bloque de método se
# hunde según crece la conversación; el hook lo trae de vuelta antes de cada respuesta.
#
# La entrada se identifica por su marcador en el comando y se deduplica por el comando exacto:
# instalar dos veces deja una sola. Los marcadores de la era anterior (core-directives.md) se
# quitan de paso, porque un hook huérfano que apunta a un fichero que ya no existe falla en cada
# turno.
#
# Contrato con el que lo carga: SETTINGS, CLAUDE_HOME, DRY_RUN, y las funciones log y backup.
: "${SETTINGS:?}" "${CLAUDE_HOME:?}" "${DRY_RUN:?}"

HOOK_FILE="how-to-work.md"
HOOK_MARKERS='["how-to-work.md","core-directives.md"]'
JQ_STALE='def stale: (.command // "") as $c | any($ms[]; . as $m | $c | contains($m));'

settings_valid() {
  [ -f "$SETTINGS" ] || return 0
  jq -e . "$SETTINGS" >/dev/null 2>&1 && return 0
  echo "settings.json no es JSON válido; no lo toco. Arréglalo y reinstala." >&2
  return 1
}

# Aplica un filtro jq sobre settings.json de forma atómica: nunca queda un fichero a medias.
settings_apply() {
  local tmp
  tmp="$(mktemp)"
  jq "$@" "$SETTINGS" > "$tmp" || { rm -f -- "$tmp"; return 1; }
  mv -- "$tmp" "$SETTINGS"
}

hook_present() {
  [ -f "$SETTINGS" ] || return 1
  jq -e --arg cmd "$1" '[.hooks.UserPromptSubmit // [] | .[] | .hooks[]? | select(.command == $cmd)]
    | length > 0' "$SETTINGS" >/dev/null 2>&1
}

hook_stale_present() {
  [ -f "$SETTINGS" ] || return 1
  jq -e --argjson ms "$HOOK_MARKERS" "$JQ_STALE"'[.hooks.UserPromptSubmit // [] | .[] | .hooks[]?
    | select(stale)] | length > 0' "$SETTINGS" >/dev/null 2>&1
}

hook_install() {
  local cmd="cat -- '$CLAUDE_HOME/$HOOK_FILE'"
  settings_valid || return 1
  if hook_present "$cmd"; then log "hook: ya está en $SETTINGS"; return 0; fi
  backup "$SETTINGS"
  log "hook: UserPromptSubmit -> $cmd   (en $SETTINGS)"
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  [ -f "$SETTINGS" ] || printf '{}\n' > "$SETTINGS"
  settings_apply --arg cmd "$cmd" --argjson ms "$HOOK_MARKERS" "$JQ_STALE"'
    .hooks.UserPromptSubmit = (
      [ (.hooks.UserPromptSubmit // [])[]
        | .hooks = ((.hooks // []) | map(select(stale | not)))
        | select((.hooks | length) > 0) ]
      + [ {hooks: [{type: "command", command: $cmd, timeout: 5}]} ])'
}

hook_remove() {
  settings_valid || return 1
  if ! hook_stale_present; then log "hook: no está (correcto)"; return 0; fi
  backup "$SETTINGS"
  log "hook: quitando la reinyección de $SETTINGS"
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  settings_apply --argjson ms "$HOOK_MARKERS" "$JQ_STALE"'
    .hooks.UserPromptSubmit |= (
      map(.hooks = ((.hooks // []) | map(select(stale | not))))
      | map(select((.hooks | length) > 0)))
    | if (.hooks.UserPromptSubmit // []) == [] then del(.hooks.UserPromptSubmit) else . end
    | if (.hooks // {}) == {} then del(.hooks) else . end'
}
