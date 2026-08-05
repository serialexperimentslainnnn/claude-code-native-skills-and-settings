---
name: github-releases-no-es-la-fuente
description: El feed de releases de GitHub no dice la versión real de un proyecto; contrastar siempre con su web oficial
metadata: 
  node_type: memory
  type: feedback
  originSessionId: eee8c4df-ddc8-4b90-a384-7e95178ea6bc
  modified: 2026-08-03T18:58:21.922Z
---

**El feed de releases de GitHub no es la fuente de verdad de un proyecto.** Seis casos confirmados
en una sola tanda de investigación (ago-2026, Ola 5 del catálogo de skills):

- **Zig** se mudó a **Codeberg** en nov-2025; su Atom de GitHub sigue congelado en 0.15.2 cuando la
  estable real es 0.16.0.
- **Leiningen** también está en Codeberg, y su GitHub se autodescribe como *"temporary convenience
  mirror"*: la versión vigente **solo aparece allí**.
- **Solidity** se mantiene ahora en **`argotorg/solidity`**, no en `ethereum/solidity`.
- **`styler`** (R) publica en **CRAN**; su último release de GitHub es dos años anterior.
- Los **módulos de Perl** se consultan en **MetaCPAN** (Perl::Critic: v1.154 en GitHub, 1.156 en CPAN).
- **Dart**: su Atom está dominado por builds `-dev`; la estable sale de `releases_linux.json` de Flutter.
- **CMocka** publica en `cmocka.org` con el espejo de GitHub parado desde 2019.

**Why:** el error tiene dos direcciones y las dos son caras: fijas una versión vieja como si fuera
la última, o **declaras abandonado un proyecto vivo** y descartas una herramienta buena. Medir salud
por cadencia de *releases* de GitHub produce falsos abandonos sistemáticos.

**How to apply:** contrastar **siempre** con la web oficial del proyecto antes de fijar una versión
o de afirmar que algo está sin mantenimiento. Y dos notas operativas del mismo barrido:
`api.github.com` **devuelve 403 sin autenticar** (usar los feeds `/releases.atom`), y **la licencia
se lee del `LICENSE` en crudo aunque "todo el mundo sepa" que es MIT** — en esa misma tanda cayeron
Brakeman (propietaria de pago), `data.table` (MPL-2.0), StyLua y selene (MPL-2.0), perltidy
(GPL-2.0), Extism (BSD-3), Wasmtime (Apache-2.0 *WITH LLVM-exception*) y Slither/Echidna/Medusa
(AGPL-3.0). Ver [[webfetch-inventa-fechas]] y [[skills-catalog-roadmap]].
