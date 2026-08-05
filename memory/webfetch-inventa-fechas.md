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
- **Invirtió el sentido del art. 31 de la European Accessibility Act**, devolviendo lo contrario de
  lo que dice el texto normativo.
- **Fabrica articulado normativo entero, y es el caso más grave (2026-08-05).** Al pedir el
  **art. 9 del RGPD** a EUR-Lex devolvió un texto inventado: **omitía "biometric data"**, insertaba
  *"criminal convictions and offences"* —que es el **art. 10**, no el 9— y atribuía a la letra (i)
  el contenido de la (g). El texto correcto solo apareció al **forzar reproducción carácter a
  carácter** contra una página corta. No es un desliz de fecha: es una norma **reconstruida de
  forma plausible y falsa**, indistinguible de la buena para quien revise por encima.

**Why:** un dato mal leído no se queda en una respuesta; se propaga. En este proyecto una fecha sin
verificar entró en un informe de agente, la repetí yo en el prompt de la ola siguiente como si
fuera dato firme, y acabó escrita en una skill. El error viaja a través de mis propios prompts.

**How to apply:** versiones y fechas, de `api.github.com` o de **feeds Atom** (funcionan cuando la
API REST está limitada por tasa); licencias, del fichero `LICENSE` en crudo desde
`raw.githubusercontent.com`; cualquier cita normativa que decida algo, pedida **verbatim**, no
resumida. Y cuando la fuente primaria se contradice consigo misma, **se declara la discrepancia en
vez de elegir una**.

**Para articulado normativo, verbatim no basta como instrucción: hay que forzar el modo literal.**
Pedir "cítamelo verbatim" sobre una página larga sigue pasando por el resumidor. Lo que funcionó:
página **corta** (el artículo suelto, no el reglamento consolidado — EUR-Lex además trunca los
documentos grandes) y exigir **reproducción carácter a carácter**. Si aun así no sale limpio, se
declara el hueco: en este catálogo un artículo mal citado es peor que un artículo ausente.

**El bloqueo por 403 es la norma, no la excepción, y no se combate insistiendo.** Confirmados en
este proyecto: `iso.org`, `etsi.org`, `cisa.gov`, `media.defense.gov`, `sap.com`, `bailii.org`,
`health.ec.europa.eu`, `unrealengine.com` (y 429 en su copia archivada), `salesforce.com/pricing`.
Ante un bloqueo: cambiar de vía (PDF en crudo, boletín oficial, mirror que reproduzca literal) o
**declarar el hueco** — nunca gastar turnos reintentando ni rellenar con lo que circula.
Ver [[skills-catalog-roadmap]].
