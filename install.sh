#!/usr/bin/env bash
#
# Instala esta configuración de Claude Code: plancha el CLAUDE.md global y el catálogo de skills
# sobre ~/.claude.
#
# El repositorio es la ÚNICA fuente de verdad. Aquí se trabaja; instalar es un acto explícito que
# COPIA el estado actual del repo sobre ~/.claude. Se copia en vez de enlazar a propósito: así una
# skill a medio escribir no queda activa en la sesión hasta que se decide instalarla.
#
# Dirección única: repo -> ~/.claude. Lo que hubiera en el destino y no esté en el repo se elimina,
# previo respaldo con marca de tiempo. Nunca se borra nada sin copia.
#
# Excepción deliberada: la memoria del proyecto se ENLAZA, no se copia. Claude Code la escribe en
# ~/.claude/projects/<slug>/memory durante la sesión y queremos que eso caiga dentro del repo y se
# versione; una copia repo -> home tiraría lo escrito en la sesión.
#
#   ./install.sh              instala
#   ./install.sh --dry-run    enseña lo que haría, sin tocar nada
#   ./install.sh --uninstall  quita lo instalado y explica cómo restaurar el último respaldo

set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
BACKUP="$CLAUDE_HOME/backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)   sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

log() { printf '  %s\n' "$*"; }
run() { if [ "$DRY_RUN" = 1 ]; then log "[dry-run] $*"; else "$@"; fi; }

# Lo que se plancha: <ruta en el repo>:<ruta bajo ~/.claude>. Nada más. El resto del repo
# (roadmap, plantilla, planes) es material de trabajo y no pinta nada en la instalación.
#
# workflows/: guiones de orquestación que Claude Code registra como comandos /<nombre>. Se planchan
# igual que las skills y por el mismo motivo: el repo es la fuente y el destino queda idéntico. Ojo
# al orden de precedencia, que NO es el de las skills: si un proyecto tiene .claude/workflows/ con un
# nombre repetido, gana el del proyecto, no éste.
FILES=( "CLAUDE.md:CLAUDE.md" )
DIRS=( "skills:skills" "workflows:workflows" )

# El circuito de subagentes está DESMONTADO. No hay tipos de agente que instalar y no hay hook que
# reinyecte nada: el reglamento entero es `CLAUDE.md`, que la sesión principal carga por sí sola.
# Los restos de las dos eras anteriores (la entrada del hook en settings.json, el fichero que la
# alimentaba y el directorio de tipos de agente) se desmontan del destino en cada instalación,
# porque un destino que no se reinstala desde entonces los sigue usando en silencio.
SETTINGS="$CLAUDE_HOME/settings.json"
HOOK_MARKER="core-directives.md"

# La memoria de Claude Code vive bajo un directorio por proyecto cuyo nombre deriva de la ruta de
# trabajo: cada '/' y cada '.' se sustituyen por '-'.
project_slug() { printf '%s' "$1" | sed 's|[/.]|-|g'; }
MEMORY_TARGET="$CLAUDE_HOME/projects/$(project_slug "$REPO")/memory"

sanity_check() {
  local missing=0 pair
  for pair in "${FILES[@]}" "${DIRS[@]}"; do
    [ -e "$REPO/${pair%%:*}" ] || { echo "FALTA en el repo: ${pair%%:*}" >&2; missing=1; }
  done
  [ "$missing" = 0 ] || { echo "Repositorio incompleto; abortando." >&2; exit 1; }
  command -v rsync >/dev/null || { echo "Falta rsync; abortando." >&2; exit 1; }
  command -v jq >/dev/null || { echo "Falta jq (lo necesita el desmontaje del hook); abortando." >&2; exit 1; }
}

# Respalda el destino solo si existe.
backup() {
  local dest="$1"
  [ -e "$dest" ] || [ -L "$dest" ] || return 0
  run mkdir -p "$BACKUP"
  log "respaldo: $dest -> $BACKUP/"
  run cp -a -- "$dest" "$BACKUP/"
}

# Quita el hook de reinyección de settings.json SIN tocar el resto: ese fichero es del usuario (env,
# permisos, modelo) y aquí solo se elimina una entrada, identificada por su marcador. Idempotente: si
# no está, no toca nada. Se ejecuta en cada instalación porque una instalación anterior pudo dejarlo
# puesto, y un hook huérfano apuntando a un fichero que ya no se instala falla en cada turno.
remove_hook() {
  local tmp
  [ -f "$SETTINGS" ] || return 0

  if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
    echo "settings.json no es JSON válido; no lo toco. Arréglalo y reinstala." >&2
    return 1
  fi

  if ! jq -e --arg m "$HOOK_MARKER" '[.hooks.UserPromptSubmit // [] | .[] | .hooks[]? |
        select((.command // "") | contains($m))] | length > 0' "$SETTINGS" >/dev/null 2>&1; then
    log "hook de directrices: no está (correcto)"
    return 0
  fi

  backup "$SETTINGS"
  log "hook: quitando la reinyección de core-directives.md de $SETTINGS"
  if [ "$DRY_RUN" = 1 ]; then
    log "[dry-run] jq: eliminar el hook de $SETTINGS"
    return 0
  fi
  tmp="$(mktemp)"
  jq --arg m "$HOOK_MARKER" '
    if .hooks.UserPromptSubmit then
      .hooks.UserPromptSubmit |= map(
        .hooks |= map(select((.command // "") | contains($m) | not))
      ) | .hooks.UserPromptSubmit |= map(select((.hooks | length) > 0))
    else . end
    | if (.hooks.UserPromptSubmit // []) == [] then del(.hooks.UserPromptSubmit) else . end
    | if (.hooks // {}) == {} then del(.hooks) else . end
  ' "$SETTINGS" > "$tmp" && mv -- "$tmp" "$SETTINGS"
}

# Restos jubilados en el destino: el fichero que alimentaba el hook y el directorio de tipos de
# agente. Ninguno de los dos está ya en FILES/DIRS, así que `rsync --delete` no los alcanza y se
# quedarían para siempre. Dejarlos es peor que borrarlos: un tipo de agente en ~/.claude/agents/
# RECARGA EN CALIENTE, así que el circuito seguiría vivo en la sesión aunque el repo ya no lo tenga.
remove_retired() {
  local stale
  for stale in "$CLAUDE_HOME/core-directives.md" "$CLAUDE_HOME/agents"; do
    [ -e "$stale" ] || continue
    backup "$stale"
    log "quitando jubilado: $stale"
    run rm -rf -- "$stale"
  done
}

install_all() {
  sanity_check
  echo "Instalando desde $REPO en $CLAUDE_HOME"
  run mkdir -p "$CLAUDE_HOME"

  local pair src dest
  for pair in "${FILES[@]}"; do
    src="$REPO/${pair%%:*}"; dest="$CLAUDE_HOME/${pair##*:}"
    if cmp -s "$src" "$dest"; then log "sin cambios: $dest"; continue; fi
    backup "$dest"
    log "copia: $dest <- $src"
    run cp -f -- "$src" "$dest"
  done

  for pair in "${DIRS[@]}"; do
    src="$REPO/${pair%%:*}/"; dest="$CLAUDE_HOME/${pair##*:}/"
    backup "${dest%/}"
    log "espejo: $dest <- $src   (se elimina lo que sobre en el destino)"
    # --delete: el destino queda idéntico al repo. Es lo que significa planchar.
    # --exclude PROJECTMAP.md: los mapas locales son navegación DEL REPO, no producto instalable.
    if [ "$DRY_RUN" = 1 ]; then
      rsync -a --delete --exclude=PROJECTMAP.md --itemize-changes --dry-run -- "$src" "$dest" | sed 's/^/    /'
    else
      run mkdir -p "$dest"
      run rsync -a --delete --exclude=PROJECTMAP.md -- "$src" "$dest"
    fi
  done

  # Memoria: enlace, no copia (ver cabecera).
  run mkdir -p "$(dirname "$MEMORY_TARGET")"
  if [ -L "$MEMORY_TARGET" ] && [ "$(readlink -f "$MEMORY_TARGET")" = "$(readlink -f "$REPO/memory")" ]; then
    log "memoria ya enlazada: $MEMORY_TARGET"
  else
    # Un directorio real con contenido no se tira: se respalda y su contenido se rescata al repo.
    if [ -d "$MEMORY_TARGET" ] && [ ! -L "$MEMORY_TARGET" ]; then
      if [ -n "$(ls -A "$MEMORY_TARGET" 2>/dev/null)" ]; then
        backup "$MEMORY_TARGET"
        log "memoria con contenido propio: rescatando a $REPO/memory/ antes de enlazar"
        run rsync -a --ignore-existing -- "$MEMORY_TARGET/" "$REPO/memory/"
      fi
      run rm -rf -- "$MEMORY_TARGET"
    elif [ -e "$MEMORY_TARGET" ] || [ -L "$MEMORY_TARGET" ]; then
      backup "$MEMORY_TARGET"
      run rm -f -- "$MEMORY_TARGET"
    fi
    log "enlace: $MEMORY_TARGET -> $REPO/memory"
    run ln -s "$REPO/memory" "$MEMORY_TARGET"
  fi

  remove_hook
  remove_retired

  echo
  echo "Hecho. Abre una sesión con:  cd $REPO && claude"
  [ -d "$BACKUP" ] && echo "Lo anterior quedó en: $BACKUP"
  echo "Comprueba los gates con:     ./check.sh"
  echo "Confirma que no hay hook:    jq .hooks $SETTINGS"
}

uninstall_all() {
  echo "Desinstalando de $CLAUDE_HOME"
  local pair dest
  for pair in "${FILES[@]}" "${DIRS[@]}"; do
    dest="$CLAUDE_HOME/${pair##*:}"
    if [ -e "$dest" ]; then
      backup "$dest"
      log "quitando: $dest"
      run rm -rf -- "$dest"
    fi
  done
  if [ -L "$MEMORY_TARGET" ]; then
    log "quitando enlace: $MEMORY_TARGET"
    run rm -f -- "$MEMORY_TARGET"
  fi

  remove_hook
  remove_retired

  local last
  last="$(find "$CLAUDE_HOME" -maxdepth 1 -type d -name 'backup-*' | sort | tail -1)"
  if [ -n "$last" ]; then
    echo
    echo "Hay un respaldo en $last. Para restaurarlo:"
    echo "  cp -a $last/* $CLAUDE_HOME/"
  fi
}

if [ "$UNINSTALL" = 1 ]; then uninstall_all; else install_all; fi
