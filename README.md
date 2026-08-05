# claudeonstereoids

Configuración de Claude Code y **catálogo de skills de ingeniería IT**: 164 documentos de criterio
técnico, ~61.000 líneas, escritos y verificados uno a uno contra fuente primaria.

Una skill de este catálogo **no enseña** — el modelo ya sabe programar. Fija **qué se decide, qué
está prohibido y qué hay que verificar antes de afirmarlo**.

## Instalación

```bash
git clone git@github.com:serialexperimentslainnnn/claudeonstereoids.git
cd claudeonstereoids
./install.sh --dry-run   # enseña lo que hará, sin tocar nada
./install.sh
```

El repo es la única fuente de verdad: **aquí se trabaja, y luego se instala**. El instalador
**plancha** el `CLAUDE.md` global y el catálogo de skills sobre `~/.claude` (copia, dirección única
repo → home, eliminando en destino lo que ya no exista en el repo). Se copia en vez de enlazar a
propósito: así una skill a medio escribir no queda activa en la sesión hasta que decides instalarla.
Todo lo que hubiera antes se respalda con marca de tiempo; nunca se borra nada sin copia.
`./install.sh --uninstall` deshace la instalación e indica cómo restaurar.

Única excepción: la **memoria del proyecto se enlaza**, no se copia — Claude Code la escribe en
`~/.claude/projects/<slug>/memory` durante la sesión y así queda dentro del repo y versionada.

Después, trabaja siempre desde la raíz del repositorio:

```bash
cd claudeonstereoids && claude
```

## Qué hay aquí

| Ruta | Qué es |
|---|---|
| `skills/<nombre>-standards/SKILL.md` | El catálogo. Una skill por directorio. |
| `CLAUDE.md` | Doctrina de ingeniería del usuario (se instala como `~/.claude/CLAUDE.md`). |
| `SKILLS-ROADMAP.md` | **Fichero de continuidad**: estado, olas, método, lecciones y hallazgos. |
| `SKILL-TEMPLATE.md` | Plantilla canónica. Fuera de `skills/` a propósito: cualquier directorio con un `SKILL.md` se registra como skill activable. |
| `plans/` | Plan original con la taxonomía completa por familias. |
| `memory/` | Memoria persistente del proyecto. |
| `install.sh` · `check.sh` | Instalador y gates mecánicos. |

## Estado

154 → **164 skills de ~267 objetivo**. Olas 0-6 completas; la 7 (legacy y verticales) en curso.
El detalle exacto y las tareas pendientes en orden están en el bloque `PUNTO DE CONTINUACIÓN` de
`SKILLS-ROADMAP.md`, que es **lo primero que hay que leer** al retomar.

## Cómo se escribe una skill aquí

Ocho secciones fijas, cuerpo en español, `description` en inglés de una línea con disparadores por
**artefacto concreto** (extensiones, ficheros de configuración, binarios, comandos) — porque esa
línea es lo único que se inyecta en cada turno y de su precisión depende que la skill se active.

Tres reglas que cuestan trabajo aprender y aquí ya están pagadas:

1. **Ningún dato concreto de memoria.** Versiones, fechas de fin de soporte, licencias, números de
   RFC y cifras se verifican por web. Sin poder verificar → **hueco declarado**, nunca relleno.
2. **Cifra con fuente y metodología, o no se escribe.** Este catálogo ha descartado por folclóricas
   el CHAOS Report del Standish, el "10x developer", el coste 10×/100× de un bug tardío, los
   "23 minutos" de recuperación tras una interrupción y las cifras de líneas de COBOL.
3. **La licencia se lee en el fichero, en crudo.** Catorce casos mal supuestos en el catálogo, con
   el fichero llamándose `COPYING`, `LICENSE.txt`, `LICENSE.md` o `license.txt`, y viviendo en
   `master`, `7.0` o `development` en vez de `main`. La clasificación automática de GitHub también
   se equivoca.

## Gates

```bash
./check.sh
```

Comprueba que el `name` del frontmatter coincide con el directorio, que cada skill declara su
frontera `**No aplica**` y que cierra §8 con la fórmula de arbitraje (*si la web contradice este
documento, manda la web*). El **test de colisión de disparadores** vive dentro de la meta-skill
`skills/claude-code-skills-standards/SKILL.md` §4.3.

## Licencia

GPL-3.0. Ver [LICENSE](LICENSE).
