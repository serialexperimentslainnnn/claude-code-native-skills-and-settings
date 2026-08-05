---
name: webfetch-inventa-fechas
description: El resumidor de WebFetch inventa años y llega a invertir el sentido de frases normativas; usar API/feeds y pedir citas verbatim
metadata: 
  node_type: memory
  type: feedback
  originSessionId: eee8c4df-ddc8-4b90-a384-7e95178ea6bc
  modified: 2026-08-03T17:37:01.628Z
---

**El resumidor de WebFetch no es fiable para datos que deciden algo.** Observado repetidamente
(2026-08, escribiendo el catálogo de skills), por agentes independientes:

- **Inventa el año** al leer HTML de GitHub Releases. Cazado devolviendo *"March 25, 2025"* para un
  comunicado cuyo identificador era `20260325…`.
- **Invierte el sentido de una frase**: devolvió *"non-versioned machine type"* donde la
  documentación de QEMU decía *"non-deprecated"* — la recomendación contraria.

**Why:** un dato mal leído no se queda en una respuesta; se propaga. En este proyecto una fecha sin
verificar entró en un informe de agente, la repetí yo en el prompt de la ola siguiente como si
fuera dato firme, y acabó escrita en una skill. El error viaja a través de mis propios prompts.

**How to apply:** versiones y fechas, de `api.github.com` o de **feeds Atom** (funcionan cuando la
API REST está limitada por tasa); licencias, del fichero `LICENSE` en crudo desde
`raw.githubusercontent.com`; cualquier cita normativa que decida algo, pedida **verbatim**, no
resumida. Y cuando la fuente primaria se contradice consigo misma, **se declara la discrepancia en
vez de elegir una**. Ver [[skills-catalog-roadmap]].
