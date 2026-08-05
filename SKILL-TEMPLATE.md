---
name: _template
description: PLANTILLA CANÓNICA — no es una skill activable. Referencia de estructura para autoría de skills del catálogo. Copiar este fichero al crear una skill nueva.
---

# PLANTILLA CANÓNICA DE SKILL

> Este fichero **no es una skill**: es la referencia de estructura del catálogo
> `~/.claude/skills/`. Al crear una skill nueva, copiar y sustituir.

## Reglas de frontmatter (obligatorias)

- `name`: slug kebab-case, sufijo `-standards`, idéntico al nombre del directorio.
- `description`: **en inglés, una sola línea**. Es lo único que se inyecta en cada turno;
  de su precisión depende que la skill se active o no. **Sin límite duro de palabras**: la
  regla es *cero relleno y cero solape con skills hermanas*. Una descripción larga se
  justifica si cada término es un disparador distinto (p. ej. nombres de servicio de un
  proveedor cloud); una corta pero conceptual ("best practices and quality") es peor.
  - Disparadores por **artefacto concreto**, no por concepto: extensiones de fichero,
    nombres de fichero de config, binarios, frameworks, comandos.
  - Ejemplo correcto: `Use when writing .py files, pyproject.toml, uv, ruff, FastAPI, Django...`
  - Ejemplo incorrecto: `Use for Python best practices and quality` (no dispara nada).
  - Evitar términos que ya reclame otra skill de la misma familia (test de colisión).

## Estructura del cuerpo

Cuerpo en **español**. **La longitud la dicta el contenido, no una cuota**: el cuerpo no se
carga hasta que la skill se activa, así que extenderse no cuesta índice. El criterio es
**densidad**: cada línea fija una decisión, una prohibición o algo a verificar. Un dominio
denso (criptografía, redes, GRC) puede pedir 400+ líneas; uno de nicho legacy se queda en
80 y omite las secciones 4 y 6 si resultan artificiales. Lo contraproducente no es el
tamaño, es el relleno: tutorial y prosa entierran la decisión que se venía a buscar.

Primera línea del cuerpo, siempre:
`Criterios verificados a **<mes-año>**. Re-verificar por web antes de fijar nada (§8).`

### 1. Alcance y triggers
Qué cubre, con los disparadores concretos. **Obligatorio** cerrar con la línea de frontera:
`**No aplica**: ver <skill-x> (para …), <skill-y> (para …).`
Sin esta línea la skill colisiona con sus vecinas y el enrutado degrada.

### 2. Decisiones por defecto / Toolchain
Tabla de elecciones concretas con versión mínima y motivo. Encabezado obligatorio:
`> Verificar la última versión por web antes de fijarla en un proyecto real (§8).`
En dominios de criterio sin toolchain (arquitectura, proceso), sustituir por
"Decisiones por defecto" con la tabla de opción recomendada vs. alternativa justificable.

### 3. Estructura y convenciones
Layout, naming, organización. Un bloque de código de referencia si aporta.

### 4. Calidad y testing
Formatter, linter, análisis estático, estrategia de test (camino feliz **y bordes y
errores**), y los **gates de CI que rompen el build**, en orden de coste creciente.

### 5. Seguridad del stack
OWASP aplicado al dominio, secretos, SCA/dependencias, hardening específico.

### 6. Rendimiento y operabilidad
Observabilidad, timeouts, límites, graceful shutdown, capacidad.

### 7. Sostenibilidad a largo plazo
Cadencia de upgrades, política de deprecación, y **lista de prohibiciones explícita**
(anti-patrones vetados, atajos de corto plazo). Formato de viñetas con ❌ o `PROHIBIDO`.

### 8. Verificación web obligatoria
Qué comprobar online antes de decidir: última estable, EOL, CVEs, breaking changes,
nombres exactos de features. Cerrar siempre con:
`Si la web contradice este documento, **manda la web** y señala la discrepancia.`

## Reglas transversales

- **Fija criterio, no enseña**: el modelo ya sabe programar. La skill decide qué usar,
  qué está vetado y qué verificar. Cero tutorial, cero relleno.
- **Extiende el `CLAUDE.md`, no lo repite**: la doctrina transversal ya está ahí.
- **Ningún dato concreto de memoria**: versiones, EOL, flags y nombres se verifican por web.
- **Skills de seguridad ofensiva**: §1 fija como precondición dura el alcance y la
  autorización por escrito (o entorno de laboratorio propio / CTF). §7 prohíbe
  explícitamente incluir payloads listos, bypasses concretos de producto o credenciales
  por defecto de terceros: metodología y gobernanza, no recetario.
