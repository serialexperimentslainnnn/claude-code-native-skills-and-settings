---
name: bash-linux-scripting-standards
description: Shell scripting and Linux automation standards. Use when writing or reviewing .sh/.bash/.zsh files, "#!/usr/bin/env bash" scripts, set -euo pipefail, shellcheck, shfmt, .shellcheckrc, .editorconfig shell rules, bats tests, getopts parsing, traps, mktemp, flock or POSIX sh portability.
---

# Estándares de shell scripting y automatización Linux

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al escribir, revisar o refactorizar shell: ficheros `.sh`, `.bash`, `.zsh`, ejecutables con shebang de
shell, funciones de `~/.bashrc`/`~/.zshrc` convertidas en herramientas, wrappers de despliegue, scripts de
arranque y mantenimiento, y cualquier automatización pegada con `bash` que ya tenga usuarios. Triggers:
`set -euo pipefail`, `shellcheck`, `shfmt`, `.shellcheckrc`, `bats`, `getopts`, `trap`, `mktemp`, `flock`,
`IFS`, "portabilidad POSIX", "dry-run", "el script se ha hecho enorme".

Principio rector: **bash es un lenguaje de pegamento excelente y un lenguaje de aplicación pésimo**. Su
trabajo es orquestar procesos y ficheros; en cuanto aparecen estructuras de datos, concurrencia, parseo real
o lógica de negocio, mantenerlo cuesta más que reescribirlo (§7, **umbral de reescritura**). Escribe shell
asumiendo que el script vivirá cinco años y lo ejecutará alguien a las 3 de la mañana.

**No aplica**: ver `onprem-standards` (paraguas de plataforma: diseño de unidades systemd,
inventario, cadencia de parcheo de la flota — aquí solo el script y su envoltura mínima),
`linux-hardening-standards` (baseline CIS/STIG, `sysctl`, auditd, sudoers, sandboxing de la unidad
como control de seguridad — aquí solo la higiene del script: `eval`, quoting, temporales, `flock`),
`selinux-standards` (si el script falla por una denegación AVC, el diagnóstico es allí), `cicd-standards` (scripts embebidos en
pipelines, runners, secretos de CI y gates del build), `python-standards` y `go-standards` (el destino
natural cuando se supera el umbral de §7: Python para automatización con datos, Go para binarios
distribuibles sin dependencias), `ruby-standards` y `perl-standards` (destino alternativo
del script que crece **solo si el equipo ya los mantiene** — para código nuevo, el destino por
defecto sigue siendo Python o Go), `powershell-standards` (**frontera recíproca de elección de
shell**: en un entorno Windows o mixto con AD, PowerShell manda —objetos en vez de texto, sin el
problema de quoting y *word splitting* de POSIX—; en Linux y en cualquier script que deba correr
en un sistema mínimo sin dependencias añadidas, manda esta skill. **Multiplataforma no es
argumento suficiente para elegir PowerShell** si el destino real es solo Linux; sí lo es si hay
que administrar Windows).

## 2. Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Herramienta | Por defecto | Motivo / nota |
|---|---|---|
| Intérprete | **bash 5.x**, shebang `#!/usr/bin/env bash` | 5.3 es la rama estable (jul-2025; patches en curso). Verificado ago-2026: Fedora 44 trae 5.3.x; **Debian estable sigue en 5.2.x** → no asumas 5.3 en destinos ajenos |
| Modo estricto | `set -Eeuo pipefail` + `IFS=$'\n\t'` + `shopt -s inherit_errexit` | Con sus límites conocidos (§3); `-E` es imprescindible para que el trap ERR funcione en funciones |
| Linter | **ShellCheck 0.11.x** (0.11.0, ago-2025) con `.shellcheckrc` en el repo | Gate de CI, no sugerencia. Recomendado por la propia Google Shell Style Guide "para todos los scripts, grandes o pequeños" |
| Formateador | **shfmt 3.13.x** (3.13.1, abr-2026) | Config por `.editorconfig`; soporta POSIX sh, bash, mksh y **zsh desde 3.13.0** |
| Tests | **bats-core 1.14.x** (jul-2026) | Con `bats-support`/`bats-assert`; alternativa: `shunit2` en entornos que ya lo usen |
| Guía de estilo | **Google Shell Style Guide** (`google.github.io/styleguide/shellguide.html`) | El `shell.xml` antiguo está deprecado. Es la referencia con más tracción; sus reglas duras están recogidas aquí |
| Dialecto | **bash exclusivamente**, salvo requisito explícito de portabilidad | Google: restringirse a bash "significa que en general no hay necesidad de buscar compatibilidad POSIX ni evitar bashismos" |
| POSIX sh | `#!/bin/sh` + `shellcheck -s sh` **solo** si el destino lo exige (initramfs, BusyBox, Alpine, `dash`, imágenes distroless, instaladores multi-SO) | Estándar vigente: **POSIX.1-2024 / Issue 8** (texto libre en `pubs.opengroup.org`) |
| Ejecución de tareas programadas | Unidad + timer de systemd (§6) | `cron` solo en contenedores sin systemd, BSD/macOS o legacy |

## 3. Estructura y convenciones

### Esqueleto obligatorio

```bash
#!/usr/bin/env bash
# Qué hace, qué asume y quién lo mantiene. Una línea, no una novela.
set -Eeuo pipefail
shopt -s inherit_errexit   # errexit también dentro de $( ); bash >= 4.4
IFS=$'\n\t'
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_NAME SCRIPT_DIR   # separado de la asignación: SC2155
: "${LOG_LEVEL:=info}"            # configurable por entorno, con default
DRY_RUN=false
WORKDIR=''
log() { printf '%s [%s] %s: %s\n' "$(date -u +%FT%TZ)" "$1" "$SCRIPT_NAME" "${*:2}" >&2; }
die() { log error "$*"; exit 1; }
cleanup() { local rc=$?; [[ -d "$WORKDIR" ]] && rm -rf -- "$WORKDIR"; exit "$rc"; }
trap cleanup EXIT
trap 'log error "fallo en ${BASH_SOURCE[0]}:${LINENO} -> ${BASH_COMMAND}"' ERR

main() {
  WORKDIR="$(mktemp -d)"          # limpieza garantizada por el trap EXIT
  ...
}
main "$@"
```

- **`main "$@"` al final**: hace el fichero *sourceable* para tests y evita la ejecución parcial si la
  descarga o la edición se trunca a mitad.
- Ejecutables en `PATH` **sin extensión**; **librerías con `.sh` y sin permiso de ejecución** (Google Shell
  Style Guide). `snake_case` para funciones y locales, `MAYÚSCULAS` solo para constantes y entorno.
- `local` para toda variable dentro de funciones, sin excepción; `readonly` para constantes.

### Quoting, word splitting y globbing

- **Comilla doble toda expansión** (`"$var"`, `"${arr[@]}"`, `"$(cmd)"`), con la excepción justificada en un
  comentario; `"${arr[@]}"` nunca `${arr[*]}` para listas. `IFS=$'\n\t'` reduce el split, **no sustituye al
  comillado**.
- `--` antes de los posicionales (`rm -rf -- "$dir"`) y `./` delante de globs (`rm -- ./*.log`): un fichero
  llamado `-rf` es un exploit trivial. Para recorrer ficheros, `find -print0` +
  `while IFS= read -r -d ''`, o globs con `shopt -s nullglob`; nombres con espacios, saltos de línea y UTF-8
  son la norma, no un caso raro.
- `[[ … ]]` preferido sobre `[`/`test` (sin word splitting ni globbing, con `=~`); aritmética con `(( … ))`.
  En POSIX sh no existen: ahí `[ … ]` con todo comillado.

### Argumentos, ayuda y códigos de salida

- Parseo con **`getopts`** (built-in y portable). Si hacen falta opciones largas, banderas repetibles y
  subcomandos, esa complejidad **ya es señal de umbral** (§7); si aun así se queda en bash, bucle
  `while [[ $# -gt 0 ]]` con `case`, sin `getopt(1)` (comportamiento divergente entre sistemas).
- `usage()` obligatoria: sinopsis, opciones, variables de entorno que lee, códigos de salida y **un ejemplo
  real**. A `stdout` con `exit 0` si se pide con `-h`; a `stderr` con `exit 2` ante error de uso.
- Códigos de salida: `0` éxito; `1` fallo genérico; **`2` error de uso**; `3+` para condiciones de negocio
  documentadas. Respeta `126`/`127` y `128+N`: un script que siempre sale `0` es indetectable desde CI.
- **`stdout` para la salida útil, `stderr` para todo lo demás**: esa separación es lo que hace el script
  componible. Configuración: flag > entorno > default; sin rutas ni hostnames a mitad del código.

### Idempotencia, `--dry-run`, temporales y concurrencia

- **Todo script que modifica algo debe poder ejecutarse dos veces sin daño**: comprueba estado antes de
  actuar (`[[ -L $link ]]`, `id -u "$user" &>/dev/null`), usa operaciones convergentes (`mkdir -p`,
  `ln -sfn`, `install -D -m 0644`) y trata "ya está como debe" como éxito, no como error.
- **`--dry-run` en todo script destructivo**, con un único punto de paso — dos caminos de ejecución
  distintos (real y "simulado") divergen siempre:

  ```bash
  run() { [[ "$DRY_RUN" == true ]] && { log info "DRY-RUN: $*"; return 0; }; "$@"; }
  ```
- Ficheros de configuración: escribe a temporal, **valida** con el verificador del servicio (`sshd -t`,
  `nginx -t`, `visudo -c`, `systemd-analyze verify`) y solo entonces `mv` atómico sobre el destino (mismo
  sistema de ficheros). Guarda copia previa con marca de tiempo.
- **`mktemp` siempre** (`mktemp -d` para directorios). Prohibido `/tmp/$$`, `/tmp/nombre-fijo` o `$RANDOM`:
  condición de carrera y escalada por symlink. La limpieza va **en el trap EXIT**, nunca al final del
  cuerpo — el script puede morir antes de llegar ahí. Un solo `trap … EXIT` por script (el segundo sustituye
  al primero): centraliza en `cleanup()`.
- **`flock` para exclusión mutua** en todo script que pueda solaparse consigo mismo (timer, cron, webhook):

  ```bash
  exec 9>"/run/lock/${SCRIPT_NAME}.lock" || die "no se puede abrir el lock"
  flock -n 9 || { log info "otra instancia en curso; saliendo"; exit 0; }
  ```
  Con `-n` (fallar rápido) o `-w <segundos>`, **nunca** esperar indefinidamente; descriptor ≥ 9 y fichero en
  `/run/lock` o `/run`, no en `/tmp` compartido. Bajo systemd basta con que la unidad no permita solape. Los
  locks por PID escritos a mano (`echo $$ > /var/run/x.pid`) están **prohibidos**: no son atómicos y dejan
  huérfanos tras un `kill -9`.

### Logging, here-docs y tuberías

- Formato estructurado y estable desde la primera versión: `<timestamp ISO-8601 UTC> [nivel] script: mensaje`
  a `stderr`; JSON de una línea si el consumidor es un agregador. Niveles `error|warn|info|debug` filtrados
  por `LOG_LEVEL`; `-v` sube el nivel, `-q` lo baja.
- `set -x` **no es logging**: es depuración interactiva y **filtra secretos**. Bajo flag explícita
  (`--debug`) y con `PS4='+ ${BASH_SOURCE[0]}:${LINENO}: '` para que la traza sea legible.
- Bajo systemd, escribir a `stderr` ya es escribir al journal: no reinventes rotación ni ficheros propios.
- Here-doc **entre comillas** (`<<'EOF'`) por defecto: sin expansión, sin sorpresas; sin comillas solo cuando
  se quiere interpolar. **Nunca** construyas por here-doc contenido que vaya a interpretarse (SQL, otro
  script) concatenando variables sin escapar: es inyección por otro nombre — pasa los datos por argumentos,
  ficheros o `stdin`.
- Process substitution (`< <(cmd)`, `diff <(a) <(b)`) para no perder variables en un subshell: el clásico
  `cmd | while read` que "olvida" lo asignado se resuelve con `while read … < <(cmd)`. Es bashismo puro.
- Estado de salida en tuberías: con `pipefail` basta casi siempre; si necesitas el código de cada tramo,
  `PIPESTATUS` copiado a un array **de inmediato** (se sobrescribe con el siguiente comando).

### Privilegios

- **El script no corre como root "porque es más fácil"**: comprueba lo que necesita y falla claro
  (`[[ $EUID -eq 0 ]] || die "requiere root"`) o, mejor, ejecuta sin privilegios y eleva solo los comandos
  concretos con `sudo` (`sudo -n` en no interactivo, para que falle en vez de colgarse pidiendo contraseña)
  y una regla de `sudoers` acotada a comandos exactos. Prohibido `NOPASSWD: ALL` para un script.
- Bajada de privilegios para el trabajo real: `runuser -u <user> -- cmd` o `setpriv`; bajo systemd,
  `User=`/`Group=` en la unidad — que el gestor de servicios haga el trabajo (ver `onprem-standards`).
- **SUID/SGID prohibidos en scripts de shell** (regla explícita de la Google Shell Style Guide): el shell no
  puede asegurarse lo suficiente. Si hace falta privilegio: `sudo` acotado o un binario compilado.
- `umask 077` antes de crear cualquier fichero con contenido sensible.

## 4. Calidad y gates de CI

En orden de coste creciente; los tres primeros rompen el build:

1. **`shfmt -d -i 2 -ci -sr`** — falla si algún fichero no está formateado; config compartida en
   `.editorconfig` para que editor y CI coincidan (`shfmt -l` ya devuelve estado no cero al listar).
2. **`shellcheck` sobre todos los scripts**, con `--severity=style` y `.shellcheckrc` en el repo; `-x` para
   que siga los `source`, `-s bash`/`-s sh` según el shebang real. Supresiones **por línea y justificadas**
   (`# shellcheck disable=SC2016  # patrón literal para sed`); los falsos positivos reales (SC2016 en
   `sed`/`printf`/`find -exec sh -c`) se suprimen puntualmente, nunca bajando la severidad del proyecto.
3. **Sintaxis y arranque**: `bash -n` sobre cada fichero y ejecución de `--help` (debe salir `0`) en CI.
4. **Tests con `bats`**: camino feliz, **fallo de cada dependencia externa** (comando ausente, salida no cero
   o vacía), argumentos inválidos (¿sale `2` con mensaje?) y **doble ejecución** (idempotencia). Aísla con
   `PATH` a *stubs*; nada de tocar el sistema real. Todo bug corregido deja test de regresión.
5. **Prueba en el intérprete de destino**: si va a Debian estable o a una imagen Alpine, se ejecuta ahí en
   CI. `${var,,}` y los arrays asociativos no existen en `dash`, y bash 5.3 no está en todas partes.

Definición de *done* para un script: pasa shfmt + shellcheck sin supresiones injustificadas, tiene `usage()`,
códigos de salida documentados, limpieza por trap, tests de bordes y se ha ejecutado de verdad en el destino.

## 5. Seguridad

- **`eval` prohibido**, sin excepciones prácticas: casi todo se resuelve con arrays
  (`cmd=(rsync -a "$src" "$dst"); "${cmd[@]}"`), con `declare -n` o con una función. Misma regla para sus
  primos (`bash -c "$var"`, `source "$var"`, `ssh host "$cmd_construido"`, `find -exec sh -c "…$var…"`):
  construir comandos concatenando strings **es inyección de comandos**; usa arrays y `--` para separar datos
  de opciones. Si de verdad no hay alternativa, se justifica en el PR y el input va contra lista blanca.
- **Prohibido parsear la salida de `ls`** (y de `df`, `ps`, `stat` con formato humano): su formato no es
  contrato y rompe con nombres raros y locales distintos. Usa globs, `find -print0` o `stat --format`.
- **`curl | bash` prohibido**, en el script y en las instrucciones que des al usuario: descarga a fichero,
  verifica firma o checksum, revisa, ejecuta. Descargas con `--fail --proto '=https' --tlsv1.2`; nunca `-k`.
- **Secretos**: jamás en el código, en argumentos de comando (visibles en `ps` para toda la máquina) ni en el
  log. Por variable de entorno inyectada por el gestor de secretos, por fichero `0600` o por `stdin`; en
  systemd, `LoadCredential=`. Si el script vuelca su configuración, redáctalos.
- `PATH` explícito al inicio de scripts privilegiados o de arranque; no confíes en el heredado. Comprueba
  dependencias al arrancar (`command -v jq >/dev/null || die "falta jq"`) en vez de fallar a medias.
- Valida toda entrada externa (argumentos, entorno, ficheros, respuestas HTTP) contra el patrón esperado
  antes de usarla en una ruta, comando o comparación; en rutas, rechaza `..` y absolutas donde esperes
  relativas.
- `rm -rf` con variable: comprueba antes que **no está vacía** y que apunta donde crees
  (`[[ -n "$dir" && "$dir" == /srv/app/* ]]`). `rm -rf "$PREFIX/"` con `PREFIX` vacío ha borrado
  producciones enteras.
- Ficheros de trabajo con permisos mínimos (`umask 077`, `install -m 0600`); nunca `chmod 777` "para probar".

## 6. Operabilidad

### Ejecución programada: unidades systemd frente a cron

- **Default con systemd**: unidad `Type=oneshot` + `.timer`. Ventajas frente a cron: journal con metadatos,
  `OnFailure=` para alertar, límites de recursos y sandboxing, dependencias reales, `Persistent=true` para
  recuperar ejecuciones perdidas y **`RandomizedDelaySec=`** para dispersar la flota (si 50 máquinas renuevan
  certificados a la vez, el problema es tuyo y del proveedor). Valida antes de desplegar con
  `systemd-analyze calendar '<expr>'` y `systemd-analyze verify`.
- **`cron` solo** en contenedores sin systemd, BSD/macOS o legacy; entonces: `PATH` explícito, salida a un
  log real (no al correo local), `flock` obligatorio y jitter manual.
- Verificado ago-2026: **systemd 259** en Fedora 44, con el soporte de scripts init SysV **deprecado y
  retirada anunciada para v260** — migra ya cualquier `/etc/init.d/` propio. El diseño de la unidad
  (sandboxing, `ProtectSystem=`, `DynamicUser=`) es materia de `onprem-standards`.

### Señales y apagado ordenado

- Script de larga duración: `trap 'on_term' TERM INT` para cerrar ordenadamente (terminar el trabajo en
  curso, liberar el lock, borrar temporales) y salir con `128+N`.
- Los hijos deben morir con el padre: guarda los PID y mátalos en `cleanup`, o ejecuta bajo systemd, que mata
  el cgroup completo — es la razón operativa de preferir la unidad. Si cerrar lleva tiempo, súbelo en
  `TimeoutStopSec`; si no, llegará `SIGKILL` y dejará el estado a medias.
- **`timeout` en toda operación de red** (`timeout 30 curl …`, `curl --max-time`); reintentos con backoff
  solo en operaciones idempotentes y con tope. Un bucle `until` sin límite es un incidente con fecha abierta.

### Rendimiento

- El coste dominante es **forkear**: nada de tuberías de cinco procesos por línea de fichero. Expansión de
  parámetros (`${var%%…}`, `${var/…/…}`) en vez de `sed`/`cut` para lo trivial, y `awk` de una pasada donde
  ibas a poner un bucle. Nunca `for line in $(cat f)`: `while IFS= read -r line; do … done < f`.
- bash 5.3 añade sustitución de comandos **sin fork** (`${ cmd; }` y `${| cmd; }`, resultado en `REPLY`):
  útiles, pero **rompen en 5.2 y anteriores** — solo con destino 5.3+ comprobado.
- Si el rendimiento importa de verdad, la respuesta está en §7: no es un problema de optimizar bash, es un
  problema de lenguaje.

## 7. Sostenibilidad, umbral de reescritura y prohibiciones

### UMBRAL DE REESCRITURA

Regla dura de la Google Shell Style Guide: shell solo para *"small utilities or simple wrapper scripts"*, y
un script de más de **100 líneas o con control de flujo no trivial se reescribe en un lenguaje más
estructurado *ahora*** — no "cuando haya tiempo". Este documento la adopta y añade los disparadores que en la
práctica llegan antes que el contador de líneas. **Con uno solo basta**:

- **Estructuras de datos** más allá de arrays planos y asociativos: registros, anidado, JSON que se manipula
  en vez de solo extraer un campo con `jq`.
- **Manejo de errores real** (distinguir tipos de fallo, reintentar por clase, deshacer parcialmente) o
  **concurrencia** controlada: `wait -n` y `xargs -P` cubren el caso trivial y nada más.
- **Parsear** (no extraer): formatos con escapes, CSV con comillas, HTML, salidas pensadas para humanos.
- **Tests unitarios de lógica interna**, no del comportamiento observable de un comando.
- Más de **una decena de opciones**, subcomandos o configuración por fichero; o va a ser **dependencia de
  otros equipos** / distribuirse fuera de la máquina donde nació.
- Lleva **tres incidentes** atribuidos a comportamiento de shell (quoting, globbing, código de salida).

Destino: **Python** (`python-standards`) para automatización con datos, APIs y lógica; **Go**
(`go-standards`) para un binario único sin dependencias en el destino. Migración por partes: el script se
queda como envoltura fina mientras la lógica se mueve, y se retira cuando ya no aporta.

### Cadencia y mantenimiento

- Fija en el repo la versión mínima de bash y **compruébala en el script** si usas características modernas
  (`(( BASH_VERSINFO[0] >= 5 )) || die "requiere bash 5+"`): más barato que un fallo silencioso en el
  servidor viejo.
- Actualiza ShellCheck y shfmt con el resto del tooling (mínimo semestral) y **fija la versión en CI**: cada
  release añade comprobaciones que encuentran bugs reales.
- Los scripts caducan: revisa anualmente cuáles no se ejecutan y bórralos. Un script muerto en `PATH` es
  una trampa.

**PROHIBIDO**
- ❌ Script sin `set -euo pipefail` (o sin justificación escrita), y expansiones sin comillas (`$var`,
  `${arr[*]}`, `$(cmd)` desnudos).
- ❌ `eval`, `bash -c "$var"`, `source "$var"` no controlado, o comandos construidos concatenando strings.
- ❌ Parsear la salida de `ls` o de cualquier salida pensada para humanos para obtener nombres de fichero.
- ❌ `curl … | bash`, descargas sin verificar checksum/firma, o `curl -k`/`--insecure`.
- ❌ Temporales predecibles (`/tmp/foo`, `/tmp/$$`) en vez de `mktemp`; limpieza fuera del trap EXIT.
- ❌ Script que puede solaparse consigo mismo sin `flock` o equivalente; ficheros PID escritos a mano.
- ❌ SUID/SGID sobre un script de shell; `sudo` con `NOPASSWD: ALL` para automatización.
- ❌ Secretos en el código, en argumentos de comando o en logs; `set -x` sin flag explícita.
- ❌ `rm -rf` sobre una variable sin comprobar que no está vacía y que apunta al prefijo esperado.
- ❌ Salir siempre con `0`; reutilizar `126`, `127` o `128+N`; mezclar salida útil y logs en `stdout`.
- ❌ Script destructivo sin `--dry-run`, o con caminos de ejecución distintos para real y simulado.
- ❌ Operación de red sin timeout, o reintentos sin límite ni backoff.
- ❌ Bashismos con shebang `#!/bin/sh` (y viceversa), u opciones en el shebang (`#!/bin/bash -e`): se
  ignoran al invocar `bash script`, van en `set`.
- ❌ Nuevos scripts init de SysV en `/etc/init.d/` (deprecado, retirada prevista en systemd 260).
- ❌ Suprimir códigos de ShellCheck globalmente sin comentario que lo justifique.
- ❌ Engordar un script que ya cruzó el umbral de reescritura "porque reescribirlo lleva tiempo".

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, flag o comportamiento, **búscalo — no lo recuerdes**:

1. **Versión de bash en el destino real** (no en tu portátil) y su patch level: `ftp.gnu.org/gnu/bash/` y el
   paquete de la distro. Verificado ago-2026: rama estable **5.3** (jul-2025) con parches en curso; Fedora 44
   trae 5.3.x, **Debian estable sigue en 5.2.x**. Las funsubs `${ cmd; }` son 5.3+.
2. **ShellCheck** y **shfmt** (`github.com/mvdan/sh/releases`), con sus códigos y flags nuevos. Verificado
   ago-2026: ShellCheck **0.11.0** (ago-2025), shfmt **v3.13.1** (abr-2026, zsh desde 3.13.0), bats-core
   **1.14.0** (jul-2026). Los paquetes de distro van por detrás: fija la versión en CI.
3. **Google Shell Style Guide** en `google.github.io/styleguide/shellguide.html`: se actualiza por commits,
   sin ediciones fechadas; el antiguo `shell.xml` está deprecado.
4. **POSIX** si escribes `sh` portable: edición vigente **POSIX.1-2024 (Issue 8)**, texto libre en
   `pubs.opengroup.org` (Shell Command Language), con un primer corrigendum técnico en curso. Verifica ahí
   qué es estándar y qué es bashismo, no de memoria.
5. **systemd**: versión en el destino y cambios que te afecten (verificado ago-2026: **259** en Fedora 44;
   SysV deprecado con retirada anunciada para **260**, que sube dependencias mínimas). Consulta el `NEWS`
   del repo antes de usar una directiva reciente.
6. **CVEs** de las utilidades que invoques con privilegios (`sudo`, `util-linux`/`flock`, `tar`, `curl`).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
