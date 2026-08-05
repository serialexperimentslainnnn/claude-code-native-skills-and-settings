---
name: project-map
description: Build and maintain PROJECTMAP.md, the orientation map of the repository you are working in, so you stop paying for the same grep/find/ls twice. Use at the start of work in an unfamiliar repo, when PROJECTMAP.md is missing or stale, when you catch yourself searching for where something lives, after adding or moving a directory, after changing the build/test/lint commands, or when a session hands off work to the next one. Covers what goes in the map, what must never go in it, how to generate it cheaply, how to keep it honest, and where to put it so it does not pollute a repository that is not yours.
---

# Mapa del proyecto — `PROJECTMAP.md`

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

> **El problema que resuelve.** Sin mapa, cada sesión redescubre el mismo repositorio: los mismos
> `find`, los mismos `grep`, las mismas lecturas de ficheros que resultan no ser el que era. Se
> paga entero cada vez, y el contexto se llena de ruido de exploración en vez de trabajo.
>
> **El riesgo que introduce.** Un mapa desactualizado es **peor que no tener mapa**: no se
> comprueba, se cree. Todo lo que sigue existe para que el mapa no mienta.

## 1. Alcance y triggers

Se activa cuando:

- Empiezas a trabajar en un repositorio y **no existe `PROJECTMAP.md`** → créalo antes de la
  primera tarea sustancial.
- Existe pero **está desfasado** (§5 dice cómo detectarlo en un comando).
- **Te sorprendes buscando dónde vive algo** que ya buscaste antes en esta sesión o en otra. Esa
  sorpresa es la señal: lo que acabas de descubrir va al mapa.
- **Cambia la estructura**: directorio nuevo, módulo movido, comando de build/test distinto,
  convención nueva. Se actualiza **en el mismo turno**, no "luego".
- Vas a **ceder el trabajo** a otra sesión o a un subagente: el mapa es el traspaso más barato.

**No aplica**: ver `knowledge-management-standards` (documentación para personas: ADRs, runbooks,
wiki, quién mantiene qué — el mapa **no** es documentación de producto ni sustituye un README),
`claude-code-skills-standards` (autoría de skills y `CLAUDE.md`: **el mapa describe el repo, el
`CLAUDE.md` fija cómo se trabaja en él** — si dudas, la regla va al `CLAUDE.md`, el hecho al mapa),
`software-architecture-patterns-standards` (decidir la arquitectura; aquí solo se **describe** la
que hay, sin juzgarla), `code-review-standards` (revisar el cambio), `git-workflow-standards`
(historia y ramas).

## 2. Decisiones por defecto

| Decisión | Por defecto | Motivo |
|---|---|---|
| Nombre y ubicación | `PROJECTMAP.md` en la raíz del repo | Predecible; lo encuentra cualquier sesión sin buscarlo |
| Tamaño máximo | **~150 líneas** | Por encima, estás duplicando el repositorio en vez de indexarlo |
| Versionado en repo propio | Commitear, si el equipo lo quiere | Se amortiza entre personas y sesiones |
| Versionado en **repo ajeno** | **NO** commitear: `.git/info/exclude` | Exclusión **local**; `.gitignore` está versionado y tocarlo ensucia el repo de otro |
| Monorepo | Un mapa raíz + uno por paquete grande | Un solo mapa de 800 líneas no lo lee nadie, ni tú |
| Estado de generación | Cabecera con fecha y **SHA corto del HEAD** | Sin eso no se puede saber si está caducado |
| Idioma | El del repositorio (código, docs, issues) | Coherencia con el resto del proyecto |

## 3. Qué contiene (y en qué orden)

El orden importa: lo que más se consulta va arriba.

```markdown
# Mapa de <proyecto>

> Generado el <YYYY-MM-DD> sobre `<sha-corto>`. Si algo aquí no cuadra con el repo, **manda el
> repo**: corrige esta línea y sigue. Mantenido según la skill `project-map`.

## Quiero tocar… → está en…
| Para… | Ve a | Nota |
|---|---|---|
| Añadir un endpoint | `src/api/routes/` | El registro central está en `src/api/router.ts:40` |
| Cambiar el esquema de BD | `migrations/` | Nunca a mano en `models/`: se genera |

## Estructura
- `src/` — código de producción. `src/core/` no depende de nada de `src/adapters/`.
- `tests/` — unitarios junto al código; los de integración aquí.
- `scripts/` — utilidades de desarrollo, no se despliegan.

## Puntos de entrada
- CLI: `src/cli/main.py` → `cmd_*` por subcomando.
- HTTP: `src/api/app.ts`, arranca en `:8080`.
- Cron/colas: `workers/`, registrados en `workers/registry.yaml`.

## Comandos
| Qué | Comando | Verificado |
|---|---|---|
| Build | `make build` | 2026-08-05 |
| Tests | `pytest -q` | 2026-08-05 |
| Lint + tipos | `ruff check . && mypy src` | 2026-08-05 |

## Convenciones e invariantes
- Los tests van junto al módulo, con sufijo `_test`.
- Nada de acceso a BD fuera de `repositories/`.

## Zonas minadas
- `src/legacy/billing.py`: sin tests, lo toca facturación real. Leer `docs/adr/0007` antes.
- `vendor/`: código de terceros parcheado a mano; los cambios se pierden al actualizar.

## Fuera del mapa
`node_modules/`, `dist/`, `.venv/`, ficheros generados (`*_pb2.py`).
```

**La tabla "quiero tocar… → está en…" es el corazón del fichero.** Es la que ahorra los `grep`.
Si solo tienes tiempo para una sección, es esa. Un árbol de directorios sin ella es decorativo.

## 4. Cómo generarlo barato

No leas el repositorio entero: **indexa, no copies**.

1. **Inventario, no volcado.** `git ls-files` filtrado por directorio da la forma real del proyecto
   sin listar 10.000 rutas: agrupa por primer y segundo nivel y cuenta. Lo que no está en git
   (generado, ignorado) no va al mapa salvo que sea una zona minada.
2. **Lee los ficheros que ya son un mapa**: `README`, `CONTRIBUTING`, `CLAUDE.md`/`AGENTS.md`,
   `Makefile`/`justfile`, `package.json` (scripts), `pyproject.toml`, `docker-compose.yml`, CI
   (`.github/workflows/`). Los comandos salen de ahí, no de tu memoria.
3. **Puntos de entrada por convención del ecosistema**: `main`, `index`, `app`, `cmd/`, `bin/`,
   `[project.scripts]`, `entrypoint` del Dockerfile, `services:` del compose.
4. **Zonas minadas por historia**: los ficheros con más cambios (`git log --format= --name-only |
   sort | uniq -c | sort -rn | head`) señalan dónde duele. Cruzarlo con la ausencia de tests da la
   lista de zonas minadas casi hecha.
5. **Delegable**: en un repo grande, un subagente de exploración devuelve el borrador y tú lo
   contrastas. Ese es exactamente el gasto que el mapa evita repetir después.

**Un comando que no has ejecutado no se escribe como verificado.** O lo corres, o lo marcas
`sin verificar`.

## 5. Cómo se mantiene honesto

- **Regla de la sorpresa**: cada vez que el mapa te falle —una ruta que ya no existe, un comando
  que no funciona— **corriges esa línea en el momento**. Es el único mantenimiento que se sostiene.
- **Regla del mismo turno**: si tu cambio mueve, crea o renombra algo que el mapa nombra,
  actualizas el mapa **en ese turno**. Un mapa que se actualiza "al final" no se actualiza.
- **Chequeo mecánico de rutas** (barato, ejecútalo al retomar): extrae las rutas citadas en el mapa
  y comprueba que existen. Una ruta muerta invalida la línea entera, no solo su final:

  ```bash
  grep -oE '`[a-zA-Z0-9_./-]+/[a-zA-Z0-9_./-]*`' PROJECTMAP.md | tr -d '`' |
    while read -r p; do [ -e "$p" ] || echo "RUTA MUERTA: $p"; done
  ```
- **Desfase respecto al código**: compara el SHA de la cabecera con `git rev-parse --short HEAD`.
  Muchos commits de diferencia no invalidan el mapa —la estructura cambia despacio—, pero sí
  obligan a mirar `git diff --stat <sha-del-mapa>..HEAD -- '*/'` en busca de directorios nuevos.
- **Si el mapa contradice al repositorio, manda el repositorio.** Siempre. El mapa es un índice,
  no una fuente de verdad.

## 6. Prohibiciones

- ❌ **Copiar contenido del código al mapa** (firmas, cuerpos de función, esquemas completos).
  Duplicar es garantizar que divergen. Se cita `fichero:línea`, no se transcribe.
- ❌ **Listar todos los ficheros.** Un `tree` volcado no es un mapa: es el mismo problema con más
  tokens. Se nombran directorios y los ficheros que de verdad son puntos de entrada.
- ❌ **Escribir lo que no has verificado.** Nada de "probablemente los tests se lancen con…".
  O lo compruebas, o lo marcas `sin verificar`.
- ❌ **Dejarlo caducar en silencio.** Si detectas que está desfasado y no puedes arreglarlo entero,
  **marca la sección afectada como no fiable** en vez de dejarla como si valiera.
- ❌ **Meter en el mapa lo que es doctrina** (cómo se trabaja, qué está prohibido): eso va al
  `CLAUDE.md`. El mapa dice **dónde está** cada cosa, no **cómo** debe hacerse.
- ❌ **Secretos, rutas internas identificables, IPs, nombres de host de producción.** El mapa suele
  acabar versionado; trátalo como código público.
- ❌ **Crear `PROJECTMAP.md` y no volver a mirarlo.** Un mapa que no se lee al empezar no ahorra
  nada: el hábito es leerlo **antes** de explorar, no después.
- ❌ **Commitearlo en un repositorio ajeno sin permiso.** Va a `.git/info/exclude`, que es local.

## 7. Sostenibilidad

- El mapa es **desechable y regenerable**: si un refactor grande lo invalida, se regenera desde
  cero (§4). No hay que preservar su historia.
- Si el mapa crece por encima de ~150 líneas de forma natural, **no lo amplíes: divídelo** (uno por
  paquete) o recorta lo que no se consulta nunca. El árbol completo es lo primero que sobra.
- En repos con `AGENTS.md`/`CLAUDE.md` ya ricos, **no dupliques**: el mapa enlaza a ellos.

## 8. Verificación

1. **Contra el repositorio, siempre**: las rutas existen (§5), los comandos se ejecutan, los puntos
   de entrada arrancan. **Si el mapa contradice al repo, manda el repo.**
2. **Contra la web**, solo para lo externo que el mapa cite: nombres y versiones de herramientas de
   build, comandos de un gestor de paquetes, ubicación canónica de un fichero de configuración de
   un framework. Eso caduca y no se fija de memoria.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
