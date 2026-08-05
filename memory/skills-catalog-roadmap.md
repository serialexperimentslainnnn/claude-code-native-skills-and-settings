---
name: skills-catalog-roadmap
description: El catálogo de skills IT tiene su fichero de continuidad en ~/.claude/SKILLS-ROADMAP.md; leerlo antes de tocar nada
metadata: 
  node_type: memory
  type: project
  originSessionId: eee8c4df-ddc8-4b90-a384-7e95178ea6bc
  modified: 2026-08-05T14:53:53.791Z
---

Proyecto en curso: catálogo exhaustivo de skills IT en `~/.claude/skills/`, objetivo ~267 skills
en 8 olas. **Todo el estado vive en `~/.claude/SKILLS-ROADMAP.md`**: skills hechas por ola, método
validado, hallazgos verificados por web, decisiones cerradas y plan de lanzamiento de la ola
siguiente. El plan original está en `~/.claude/plans/validated-swimming-treehouse.md` y la
plantilla canónica —deliberadamente fuera de `skills/`, porque cualquier directorio con `SKILL.md`
se registra como skill activable— en `~/.claude/SKILL-TEMPLATE.md`.

**Antes de continuar el proyecto o de escribir una skill nueva, leer el roadmap**: contiene
lecciones de método que ya costaron trabajo perdido (agentes que terminan sin escribir, cortes de
sesión a mitad, datos propagados sin verificar) y las reglas de frontera ya pactadas entre skills.

A 2026-08-04: **132/267, olas 0-6 COMPLETAS**; solo queda la Ola 7 (~120, legacy y verticales,
formato corto), que **no tiene plan de lanzamiento derivado todavía**. El roadmap abre con un
bloque **"PUNTO DE CONTINUACIÓN"** con el estado y las tareas exactas: leerlo antes que nada. La meta-skill que gobierna la calidad del resto es
`claude-code-skills-standards`, que además **contiene el gate mecánico de colisión de triggers**
(script Python sobre las `description`); su lista `STOP` hay que ampliarla cada ola o el gate se
llena de ruido y deja de servir. Ver también [[webfetch-inventa-fechas]] y
[[usuario-maxima-paralelizacion]].

**División del trabajo que funciona**: los subagentes escriben **solo sus propias skills** y
**reportan** las fronteras recíprocas que faltan en las vecinas; esas las escribo yo. Así no se
pisan dos agentes el mismo fichero y el criterio de frontera queda en una sola cabeza.
