---
name: accessibility-standards
description: Use when digital accessibility is a conformance requirement — WCAG 2.1/2.2 Level A/AA success criteria, EN 301 549, the European Accessibility Act (Directive 2019/882), Spain's Ley 11/2023 and Real Decreto 1112/2018, ADA Title II web rule and Section 508, axe-core, @axe-core/playwright, jest-axe, Pa11y and pa11y-ci with .pa11yci, Lighthouse accessibility category as a CI gate, WAVE, VPAT and Accessibility Conformance Report, an accessibility statement page, keyboard-only and screen-reader testing with NVDA/JAWS/VoiceOver/TalkBack, accessible name computation, aria-hidden, tabindex, role and aria-* attributes, focus management in dialogs and SPA route changes, focus-visible and outline, prefers-reduced-motion and prefers-contrast, alt text, form labels and error messaging, data table headers, captions transcripts and audio description, PDF/UA tagged documents, or accessibility overlay widgets.
---

# Estándares de accesibilidad digital

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando hay que **decidir si algo cumple** y **demostrarlo**: qué norma y qué nivel se
exige, qué criterio de conformidad concreto se incumple, cómo se prueba, quién firma la
declaración y qué obligación legal hay detrás. Cubre contenido web, aplicaciones web,
documentos y correo. El **criterio de conformidad** es lo propio de esta skill.

Triggers: WCAG 2.1 / 2.2, niveles A / AA / AAA, un número de criterio de éxito (1.4.3,
2.4.7, 2.5.8, 4.1.2…), EN 301 549, Directiva (UE) 2019/882 (*European Accessibility Act*),
Directiva (UE) 2016/2102, Ley 11/2023, Real Decreto 1112/2018, ADA Título II, Section 508,
VPAT / ACR, declaración de accesibilidad, `axe-core`, `@axe-core/playwright`,
`@axe-core/react`, `jest-axe`, `pa11y` / `pa11y-ci` / `.pa11yci`, categoría *accessibility*
de Lighthouse, WAVE, ARC Toolkit, NVDA, JAWS, VoiceOver, TalkBack, Orca, nombre accesible,
`aria-*`, `role`, `aria-hidden`, `aria-live`, `tabindex`, `:focus-visible`, `outline`,
`prefers-reduced-motion`, `prefers-contrast`, `alt`, `<label>`/`aria-labelledby`,
`<caption>`/`<th scope>`, subtítulos, transcripción, audiodescripción, PDF/UA, *overlay* de
accesibilidad.

**Tesis de la skill**: **la accesibilidad es un requisito, no una mejora.** No se prioriza
contra funcionalidades: es funcionalidad. Y en la UE, además, es **obligación legal con
fecha ya vencida** — Directiva (UE) 2019/882, art. 31.2, verbatim: *"They shall apply those
measures from 28 June 2025."* Corolario operativo: **un fallo de accesibilidad en producción
es un defecto, con su bug y su regresión**, no una tarea de *backlog* con etiqueta `a11y`.
Segundo corolario, incómodo: **la automatización no puede cerrarlo** (§4.1) — quien firma la
conformidad es una persona que ha probado con teclado y con lector de pantalla.

**No aplica**: ver `frontend-web-platform-standards` (**el HTML semántico, el CSS, las APIs
del navegador, el modelo de carga y las herramientas de build son suyos** — qué elemento
nativo existe, cómo se estila, qué *Baseline* soporta `:focus-visible` o `prefers-contrast`.
**Aquí solo el criterio de conformidad**: qué exige WCAG, qué nivel, cómo se prueba y quién
lo declara. Elegir `<button>` en vez de `<div role="button">` es decisión suya; **exigirlo**
como conformidad es de aquí), `frontend-frameworks-standards` (el framework y su modelo de
renderizado y enrutado son suyos; **aquí las consecuencias medibles**: el foco al cambiar de
ruta en una SPA §3.5, el componente de diálogo que atrapa el foco, el anuncio de estado tras
una mutación), `design-systems-standards` (**el sitio correcto para resolver la accesibilidad
una sola vez es un componente del sistema de diseño**: el botón, el campo, el diálogo y el
menú accesibles se construyen ahí y se auditan ahí — no en cada pantalla. Su gobierno,
versionado y documentación son suyos; aquí el criterio que ese componente debe cumplir),
`web-performance-standards` (**skill hermana**: se cruzan en `prefers-reduced-motion` — aquí
como criterio de conformidad, allí como coste de renderizado — y en la percepción de
velocidad; el presupuesto y las Core Web Vitals son suyos), `grc-compliance-standards` (el
marco normativo, la evidencia de auditoría, el registro de riesgo legal y la relación con el
regulador; **aquí el criterio técnico de conformidad y su prueba**), `mobile-standards`
(accesibilidad de app nativa: `UIAccessibility`, `AccessibilityNodeInfo`, TalkBack/VoiceOver
como API de plataforma y las pautas de cada tienda son suyas; aquí la web y el WebView),
`privacy-engineering-standards` (tratamiento de datos personales; aquí solo la advertencia de
que un *overlay* de terceros es un tercero con acceso al DOM, §5.2), `api-design-standards`
(contratos de servicio; los mensajes de error legibles por humanos que devuelve la API son
suyos, su presentación accesible es de aquí) y `cicd-standards` (la *pipeline*; **aquí qué
gate ponerle**, §4.2), `technical-hiring-standards` (el diseño del proceso de selección es suyo; **la
conformidad de sus herramientas y los ajustes razonables —formato alternativo, tiempo adicional,
prueba accesible con lector de pantalla— se rigen por el criterio de aquí**. Aviso compartido: **un
proceso de selección inaccesible descarta candidaturas antes de evaluarlas**, y eso no es un fallo
de experiencia de usuario sino de validez del instrumento de medida),
`webgl-webgpu-standards` (**un `<canvas>` es opaco para la tecnología asistiva** — no
tiene estructura, ni texto, ni foco. El criterio de conformidad y la exigencia de alternativa
equivalente son de aquí; **cómo se implementa el contenido del canvas y su rendimiento, suyo**),
`i18n-standards` (frontera con solape real y concreto: el
atributo `lang` correcto y la dirección del texto son **criterio de conformidad de aquí** —sin
`lang` el lector de pantalla pronuncia mal—, mientras que **la elección de idiomas, el catálogo de
mensajes, la pluralización, el formato regional y el flujo de traducción son suyos**. Aviso
compartido: **una interfaz traducida a un idioma RTL no es la misma interfaz reflejada**, y el
texto de otros idiomas se expande —un componente que solo cabe en inglés falla en ambas skills).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.1 Norma objetivo

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Norma técnica | **WCAG 2.2 nivel AA** | WCAG 2.1 AA si el contrato/regulador la cita literalmente (ADA Título II, EN 301 549 V3.2.1) |
| Nivel | **AA como objetivo operativo** | AAA solo en criterios concretos que aporten (p. ej. 1.4.6 contraste alto en contenido crítico) |
| Norma UE | **EN 301 549**, versión citada en el DOUE | — |
| Documento de conformidad | Declaración de accesibilidad (UE) / **VPAT-ACR** (mercado EE. UU.) | — |

**Por qué AA y no AAA**: la propia WCAG lo dice — no es política de proyecto sino de la
norma. WCAG 2.2, §5.2.1 Conformance Level, Nota 2, verbatim: *"It is not recommended that
Level AAA conformance be required as a general policy for entire sites because it is not
possible to satisfy all Level AAA success criteria for some content."* AA es el nivel que **todas** las normas
legales citadas abajo referencian. AAA se aplica **por criterio elegido**, nunca como meta
global.

**WCAG 2.2 es la Recomendación vigente**: publicada el **5 de octubre de 2023**, con
actualización del **12 de diciembre de 2024**. No deroga las anteriores — W3C, verbatim:
*"WCAG 2.2 does not deprecate or supersede WCAG 2.1, and WCAG 2.1 does not deprecate or
supersede WCAG 2.0."* Único cambio de fondo respecto a 2.1: **4.1.1 Parsing** figura en el
índice de WCAG 2.2 como *"4.1.1 Parsing (Obsolete and removed)"*.

**WCAG 3.0 NO está vigente y no se planifica contra ella.** El borrador es *W3C Working
Draft* de **03 March 2026**, y su propio "Status of This Document" dice verbatim: *"This is
a draft document and may be updated, replaced, or obsoleted by other documents at any time.
It is inappropriate to cite this document as other than a work in progress."* En WCAG 3.0
las siglas cambian de significado (*W3C Accessibility Guidelines*) y el modelo de
conformidad es distinto (niveles tipo bronce/plata/oro en vez de A/AA/AAA). **Un proveedor
que venda "certificación WCAG 3.0" en 2026 está vendiendo humo** — no hay modelo de
conformidad estable contra el que certificar. Fechas de Candidate Recommendation y
Recommendation: **hueco, no verificadas por fuente primaria** (§8).

### 2.2 Obligación legal — qué decide

**No se elige el nivel: lo fija la norma que aplique al producto.** Antes de nada, determinar
jurisdicción y sector.

| Marco | Ámbito | Norma técnica | Fecha |
|---|---|---|---|
| Directiva (UE) 2019/882 (EAA) | Productos y servicios **al consumidor** (sector privado incluido) | EN 301 549 | **Aplicable desde 28-jun-2025** |
| Directiva (UE) 2016/2102 | Webs y apps del **sector público** de la UE | EN 301 549 | En vigor |
| España — Ley 11/2023 | Transposición de la EAA | EN 301 549 | Título I aplicable desde 28-jun-2025 |
| España — RD 1112/2018 | Sector público español | EN 301 549 | En vigor |
| EE. UU. — Section 508 | ICT federal | **WCAG 2.0 A y AA** | Vigente desde 18-ene-2018 |
| EE. UU. — ADA Título II | Administración estatal y local | **WCAG 2.1 nivel AA** | **26-abr-2027 / 26-abr-2028** |

**EAA (Directiva (UE) 2019/882)** — citas verbatim de EUR-Lex:
- Art. 31.1: *"Member States shall adopt and publish, by 28 June 2022, the laws, regulations
  and administrative provisions necessary to comply with this Directive."*
- Art. 31.2: *"They shall apply those measures from 28 June 2025."*
- Art. 31.3: *"By way of derogation from paragraph 2 of this Article, Member States may
  decide to apply the measures regarding the obligations set out in Article 4(8) at the
  latest from 28 June 2027."* (comunicaciones de emergencia).
- Art. 4.5, **la exención que más se invoca mal**: *"Microenterprises providing services
  shall be exempt from complying with the accessibility requirements referred to in paragraph
  3 of this Article and any obligations relating to the compliance with those requirements."*
  → **la exención es para microempresas que prestan SERVICIOS, no para microempresas que
  fabrican productos.** No se aplica de oído: se comprueba contra el texto.
- Art. 32.1 (transitoria): *"Member States shall provide for a transitional period ending on
  28 June 2030 during which service providers may continue to provide their services"* con
  productos usados legalmente antes de la fecha. **No es una prórroga general hasta 2030.**

**España**: la transposición es la **Ley 11/2023, de 8 de mayo, de trasposición de Directivas
de la Unión Europea en materia de accesibilidad de determinados productos y servicios,
migración de personas altamente cualificadas, tributaria y digitalización de actuaciones
notariales y registrales** (BOE-A-2023-11022); su Título I transpone la EAA. Desarrollo
posterior verificado: **Real Decreto 143/2026, de 25 de febrero, por el que se crea y regula
la Unidad técnica de apoyo y coordinación de las autoridades de vigilancia en materia de
requisitos de accesibilidad** (BOE-A-2026-4520), que desarrolla el art. 28 de la Ley 11/2023
— es decir, **la maquinaria de vigilancia ya existe**, no es una obligación sin autoridad
detrás. El **RD 1112/2018, de 7 de septiembre, sobre accesibilidad de los sitios web y
aplicaciones para dispositivos móviles del sector público** sigue siendo el que rige el
sector público, con su **declaración de accesibilidad** obligatoria (§6.1). Las cuantías del
régimen sancionador de la Ley 11/2023 y los plazos exactos de sus disposiciones transitorias:
**hueco, verificar en el texto consolidado del BOE** (§8).

**EN 301 549**: la versión con presunción de conformidad es la **citada en el DOUE**, no la
última que ETSI haya publicado. Verificado: **V3.2.1 (2021-03)** es la referenciada; existe
un borrador **V4.1.0 (2025-11)** publicado por ETSI que alinea las cláusulas 9, 10 y 11 con
WCAG 2.2 y añade Anexo ZA (Directiva 2016/2102) y una cláusula A.2 para la Directiva
2019/882. La Comisión Europea lo dice verbatim: *"New versions of the WCAG or of EN 301 549
do not automatically change the legal obligations."* **La fecha de publicación de una V4.1.1
en el DOUE es un hueco: circula "octubre de 2026" en fuentes secundarias, sin confirmación
primaria** (§8). Consecuencia práctica: **construir contra WCAG 2.2 AA aunque la norma citada
siga en 2.1 AA** — 2.2 es superconjunto salvo 4.1.1, y evita re-auditar cuando cambie la
cita.

**EE. UU. — corrección importante**: la regla de la ADA Título II se publicó el **24 de abril
de 2024** con estándar técnico, verbatim de ada.gov: *"The Web Content Accessibility
Guidelines (WCAG) Version 2.1, Level AA is the technical standard for state and local
governments' web content and mobile apps."* **Las fechas de cumplimiento se ampliaron**:
ada.gov, verbatim: *"On April 20, 2026, the Federal Register published the Department's
Interim Final Rule (IFR) extending the compliance date for State and local government
entities with a total population of 50,000 or more to April 26, 2027. The compliance date for
public entities with a total population of less than 50,000, or any special district
government, is extended to April 26, 2028."* **Discrepancia declarada**: buena parte de las
fuentes secundarias (blogs de proveedores, guías "2026") siguen citando el **24/26 de abril
de 2026** como fecha viva. Está desfasado. **Manda ada.gov.** Lo que **no** cambió: el
estándar técnico ni el alcance del contenido cubierto.

**Section 508** no se ha actualizado a WCAG 2.1/2.2: sigue incorporando **WCAG 2.0 niveles A
y AA**, con la regla final en vigor desde el **18 de enero de 2018**. Consecuencia: cumplir
2.2 AA cubre 508; lo contrario no.

### 2.3 Herramientas

| Uso | Por defecto | Versión / licencia verificada | Nota |
|---|---|---|---|
| Motor de reglas | **`axe-core`** | 4.12.1 — **MPL-2.0** | Estándar de facto; base de casi todo lo demás |
| Test unitario/componente | `jest-axe` / `@axe-core/playwright` | Ver §8 | Auditar el componente del sistema de diseño, no la página entera |
| Rastreo de sitio en CI | **`pa11y-ci`** (`.pa11yci`) | `pa11y` 9.1.1 — **LGPL-3.0-only** | **Licencia LGPL, no MIT**: relevante si se empaqueta o se enlaza |
| Auditoría de página | **Lighthouse** | 13.4.1 — Apache-2.0 | Su categoría *accessibility* es axe-core con subconjunto de reglas |
| Gate en CI | **Lighthouse CI** (`@lhci/cli`) | 0.15.1 — Apache-2.0 | Mismo binario que el presupuesto de rendimiento |
| Exploratorio manual | WAVE, ARC Toolkit, *Accessibility Tree* de DevTools | — | No automatizable en CI |
| Lectores de pantalla | **NVDA + Firefox/Chrome (Windows)**, **VoiceOver + Safari (macOS/iOS)**, **TalkBack + Chrome (Android)** | — | JAWS si el público objetivo es corporativo/AAPP (§4.3) |

**`pa11y` es LGPL-3.0-only** — no MIT, como suele asumirse. Comprobado en su `LICENSE` en
crudo y en el campo `license` de npm. Uso como herramienta de CI: sin problema. Enlazarlo
dentro de un producto distribuido: revisar con quien lleve licencias.

## 3. Criterios que más se incumplen (y qué exigen literalmente)

**Base empírica, no intuición.** WebAIM Million, muestra de **febrero de 2026** sobre el
millón de portadas más populares: **95,9 % de las portadas tenían fallos de WCAG 2
detectados**, subiendo desde el 94,8 % de 2025 — *"reversing a trend of small improvements
each of the previous 6 years"*. Y como solo se cuenta lo detectable automáticamente, el
propio informe concluye verbatim: *"this suggests that the rate of full WCAG 2 A/AA
conformance was certainly lower than 4.1%."*

Los seis fallos que concentran el **96 % de todos los errores detectados** (portadas
afectadas, feb-2026):

| Fallo | % portadas | Criterio |
|---|---|---|
| Texto de bajo contraste | **83,9 %** | 1.4.3 |
| Falta texto alternativo en imágenes | 53,1 % | 1.1.1 |
| Falta etiqueta en campo de formulario | 51,0 % | 1.3.1 / 3.3.2 / 4.1.2 |
| Enlaces vacíos | 46,3 % | 2.4.4 / 4.1.2 |
| Botones vacíos | 30,6 % | 4.1.2 |
| Falta idioma del documento | 13,5 % | 3.1.1 |

**Criterio operativo**: si un proyecto no puede arreglarlo todo de golpe, **estos seis
primero** — son baratos, automatizables y cubren la mayoría del volumen real.

### 3.1 Contraste y color (verbatim de WCAG 2.2)

- **1.4.3 Contrast (Minimum) (Level AA)**: *"The visual presentation of text and images of
  text has a contrast ratio of at least 4.5:1"*, con excepciones: *"Large-scale text and
  images of large-scale text have a contrast ratio of at least 3:1"*; texto incidental,
  inactivo o decorativo, y logotipos, sin requisito.
- **1.4.11 Non-text Contrast (Level AA)**: *"The visual presentation of the following have a
  contrast ratio of at least 3:1 against adjacent color(s): User Interface Components […]
  Graphical Objects"*. → **el borde del campo, el estado *checked* y el indicador de foco
  también tienen umbral**, no solo el texto.
- **1.4.1 Use of Color (Level A)**: *"Color is not used as the only visual means of conveying
  information, indicating an action, prompting a response, or distinguishing a visual
  element."* → un campo en rojo sin texto de error **incumple**; una serie de gráfica
  distinguida solo por color **incumple** (ver también la skill `dataviz` si está disponible).

### 3.2 Foco

- **2.4.7 Focus Visible (Level AA)**: *"Any keyboard operable user interface has a mode of
  operation where the keyboard focus indicator is visible."*
- **2.4.11 Focus Not Obscured (Minimum) (Level AA)**, nuevo en 2.2: *"When a user interface
  component receives keyboard focus, the component is not entirely hidden due to
  author-created content."* → **una barra fija (*sticky header*/*cookie banner*) que tapa el
  elemento enfocado incumple.** Es el fallo típico que ninguna herramienta automática ve.
- **2.4.3 Focus Order (Level A)**: *"If a web page can be navigated sequentially and the
  navigation sequences affect meaning or operation, focusable components receive focus in an
  order that preserves meaning and operability."*
- **2.4.13 Focus Appearance** es **AAA**, no AA: *"an area of the focus indicator […] is at
  least as large as the area of a 2 CSS pixel thick perimeter of the unfocused component […]
  and has a contrast ratio of at least 3:1 between the same pixels in the focused and
  unfocused states."* Buen objetivo de diseño; **no exigible como AA**.

### 3.3 Objetivo de puntero (nuevo en 2.2)

- **2.5.8 Target Size (Minimum) (Level AA)**: *"The size of the target for pointer inputs is
  at least 24 by 24 CSS pixels"*, salvo espaciado equivalente (círculo de 24 px que no
  interseca otro objetivo), control equivalente en la misma página, objetivo *inline* en una
  frase, control del agente de usuario o presentación esencial.
- **2.5.7 Dragging Movements (Level AA)**: *"All functionality that uses a dragging movement
  for operation can be achieved by a single pointer without dragging, unless dragging is
  essential"*. → **todo *drag & drop* necesita una alternativa sin arrastrar.** Es el criterio
  que más rompe los reordenadores de listas y los *kanban*.

### 3.4 ARIA y nombre accesible

**Primera regla de ARIA, verbatim de *Using ARIA* (W3C)**: *"If you can use a native HTML
element or attribute with the semantics and behavior you require already built in, instead of
re-purposing an element and adding an ARIA role, state or property to make it accessible,
then do so."* Las excepciones que el propio documento admite: que la característica exista en
HTML pero no esté implementada o sin soporte de accesibilidad; que las restricciones de
diseño visual impidan usar el elemento nativo porque no se puede estilar como se requiere; o
que la característica no exista hoy en HTML.

Reglas derivadas, exigibles:
- **ARIA mal puesto es peor que nada.** `role="button"` sobre un `<div>` obliga a implementar
  a mano foco, `Enter`, `Space` y estado deshabilitado. Si no están los cuatro, es un defecto.
- **Todo control interactivo tiene nombre accesible** (4.1.2 Name, Role, Value, nivel A). El
  nombre visible debe estar contenido en el nombre accesible (2.5.3 Label in Name, nivel A) —
  si no, el usuario de control por voz no puede activarlo diciendo lo que ve.
- **Un icono-botón sin texto necesita nombre**: `aria-label` o texto oculto visualmente. Un
  `title` **no basta**.
- **`aria-live` para lo que cambia sin recargar**: 4.1.3 Status Messages (AA), verbatim:
  *"status messages can be programmatically determined through role or properties such that
  they can be presented to the user by assistive technologies without receiving focus."* La
  región viva debe existir **en el DOM antes** de recibir el mensaje, o no se anuncia.

### 3.5 Regiones, encabezados y foco en SPA

- **Landmarks**: `<header>`/`<nav>`/`<main>`/`<footer>` — un solo `<main>` por vista, y un
  enlace "saltar al contenido" como primer elemento enfocable (2.4.1 Bypass Blocks, nivel A).
- **Encabezados jerárquicos y sin saltos**; `<h1>` único y descriptivo de la vista. Un
  encabezado no es un tamaño de letra.
- **Cambio de ruta en una SPA — el fallo clásico**: navegar sin recarga **no** mueve el foco
  ni anuncia nada. El usuario de lector de pantalla se queda donde estaba, con el foco en un
  enlace que ya no existe. **Criterio obligatorio en toda SPA**: al completar un cambio de
  ruta, (a) actualizar `document.title`, (b) **mover el foco** al `<h1>` de la vista nueva o a
  su contenedor (`tabindex="-1"` + `.focus()`), y (c) anunciar el cambio por región viva si el
  destino tarda en pintar. **Sin los tres, la navegación es inaccesible aunque cada pantalla
  suelta pase axe.** El *router* es de `frontend-frameworks-standards`; **el requisito es de
  aquí, y se prueba con teclado y lector, no con un test automático.**
- **Diálogo modal**: foco al abrir dentro del diálogo, foco **atrapado** mientras esté
  abierto, `Escape` cierra, y **el foco vuelve al elemento que lo abrió**. Usar `<dialog>` con
  `showModal()` o un componente del sistema de diseño ya auditado; no reimplementarlo por
  pantalla.

### 3.6 Formularios y errores

- **Todo campo tiene `<label>` asociado** (`for`/`id`) o `aria-labelledby`. Un `placeholder`
  **no es una etiqueta**: desaparece al escribir y suele fallar el contraste.
- **3.3.1 Error Identification (Level A)**, verbatim: *"If an input error is automatically
  detected, the item that is in error is identified and the error is described to the user in
  text."* → **en texto**, no solo con un borde rojo o un icono.
- **3.3.3 Error Suggestion (Level AA)**: *"If an input error is automatically detected and
  suggestions for correction are known, then the suggestions are provided to the user, unless
  it would jeopardize the security or purpose of the content."*
- **3.3.2 Labels or Instructions (Level A)**: *"Labels or instructions are provided when
  content requires user input."* Formato esperado, obligatoriedad y restricciones **antes** de
  enviar, no después.
- El mensaje de error se asocia al campo (`aria-describedby`), se marca `aria-invalid`, y el
  foco va al primer campo erróneo o a un resumen de errores enfocable.
- **3.3.8 Accessible Authentication (Minimum) (AA)**, nuevo en 2.2: no exigir una prueba
  cognitiva (recordar, transcribir, resolver un puzle) sin alternativa. **Afecta directamente
  a los CAPTCHA y a los códigos de un solo uso que bloquean el pegado** — si el campo impide
  `paste`, incumple.

### 3.7 Tablas de datos

`<table>` solo para datos, nunca para maquetar. `<caption>` con el título, `<th>` con
`scope="col"`/`scope="row"`, `<thead>`/`<tbody>`. Tablas complejas: `headers`/`id`. Una
"tabla" hecha de `<div>` requiere `role="table"`/`row`/`cell` completos — **es más trabajo que
usar la etiqueta nativa** (§3.4).

### 3.8 Movimiento y preferencias del usuario

- **2.3.1 Three Flashes or Below Threshold (Level A)**: nada que destelle más de tres veces
  por segundo. Es un criterio de **seguridad física** (epilepsia fotosensible), no estético.
- **2.2.2 Pause, Stop, Hide (Level A)**: todo movimiento automático de más de 5 s se puede
  pausar, parar u ocultar. Aplica a carruseles y a *marquees* de logos.
- **`prefers-reduced-motion: reduce`**: respetar la preferencia del sistema **por defecto** —
  animaciones de transformación/desplazamiento desactivadas o reducidas a un cambio de
  opacidad. Cruce con `web-performance-standards`: allí la misma consulta se usa para no
  gastar hilo principal; aquí es requisito de conformidad.
- **`prefers-contrast: more`** y modo de contraste forzado del SO: la interfaz debe seguir
  siendo usable; no anular los colores del sistema con `!important`.

### 3.9 Multimedia, documentos y correo

| Contenido | Requisito mínimo (AA) |
|---|---|
| Vídeo con audio, pregrabado | **Subtítulos** (1.2.2, A) + **audiodescripción** (1.2.5, AA) |
| Solo audio, pregrabado | Transcripción textual (1.2.1, A) |
| Directo | Subtítulos en directo (1.2.4, AA) |
| Reproductor | Controles operables por teclado, con nombre accesible; sin autoplay con sonido |

- **Los subtítulos automáticos sin revisar no cumplen**: 1.2.2 exige subtítulos, y unos
  subtítulos con errores de transcripción no transmiten el contenido. Revisión humana.
- **Transcripción ≠ subtítulos**: la transcripción no cubre 1.2.2 para vídeo.
- **La entrega técnica de la pista es de `streaming-multimedia-standards`** (WebVTT/TTML/IMSC,
  CEA-608/708, declaración en el manifiesto HLS/DASH, *rendition* de audiodescripción). Aquí el
  criterio de conformidad y quién firma; allí, que llegue al reproductor. **Una pista producida
  pero no declarada en el manifiesto incumple igual**: el gate es que se vea en el cliente.
- **PDF**: si se publica un PDF, va **etiquetado** (estructura, orden de lectura, texto
  alternativo, idioma, título del documento) — referencia **PDF/UA**. Criterio preferente:
  **publicar HTML y ofrecer el PDF como descarga secundaria**, no al revés. Un PDF escaneado
  sin capa de texto es contenido inaccesible, sin matices.
- **Correo (HTML)**: texto alternativo en imágenes, contraste suficiente, jerarquía de
  encabezados, y **versión de texto plano** en el `multipart/alternative`. El correo que solo
  es una imagen enlazada es inaccesible.

## 4. Método de prueba y gates de CI

### 4.1 Qué automatiza la automatización — el dato, no la intuición

**Ninguna herramienta automática cierra la conformidad.** Cifras verificadas, con su fuente y
su sesgo declarado:

- **Deque (fabricante de `axe-core`)**, sobre >2.000 auditorías, >13.000 páginas y ~300.000
  incidencias: *"57.38% of total issues were identified using its automated tests"*. La
  documentación de `axe-core` lo repite: *"With axe-core, you can find on average 57% of WCAG
  issues automatically"*. **Es un estudio del fabricante sobre su propio producto**, y mide
  **volumen de incidencias**, no porcentaje de criterios de éxito cubiertos.
- **UK Government Digital Service**: la mejor herramienta que probó encontró **el 40 %** de
  las barreras conocidas.
- Deque sitúa sus *Intelligent Guided Tests* (semiautomáticas, con intervención humana) en
  torno al **80 %**; el salto 57 %→80 % **no es automatización, es una persona guiada**.

**Criterio fijado**: tratar el **~40 %** como cifra de trabajo conservadora y el **57 %** como
cota superior optimista de fabricante. **Entre el 43 % y el 60 % de los problemas reales no
los ve ninguna herramienta.** Consecuencia directa: **una puntuación de 100 en la categoría
*accessibility* de Lighthouse no significa que el sitio sea accesible**, significa que pasaron
las reglas que se pueden comprobar sin entender el contenido. Nada que sea juicio semántico
—si el `alt` describe la imagen, si el orden del foco tiene sentido, si el error se entiende,
si el diálogo devuelve el foco— es automatizable.

### 4.2 Gates de CI (orden de coste creciente)

1. **Lint estático** (`eslint-plugin-jsx-a11y` o equivalente del framework): sobre el
   *diff*, en el *pre-commit*. Coste ~0.
2. **`axe-core` a nivel de componente** (`jest-axe`) en los componentes del sistema de
   diseño: **cero violaciones, rompe el build**. Es el gate más rentable porque un componente
   arreglado arregla todas sus instancias.
3. **`@axe-core/playwright` en los recorridos E2E críticos** (alta, login, compra, búsqueda),
   **en cada estado relevante**: formulario vacío, formulario con errores, diálogo abierto,
   menú desplegado. **Un análisis del estado inicial de la página no vale de nada**: los
   fallos viven en los estados.
4. **`pa11y-ci` con `.pa11yci`** rastreando el conjunto de URLs representativas en *nightly*,
   no en cada PR.
5. **Lighthouse CI** con aserción sobre la categoría *accessibility*: **umbral absoluto y
   además prohibición de regresión** respecto a la rama principal. Mismo binario y misma
   configuración que el presupuesto de `web-performance-standards`.

**Política de fallo**: `axe-core` **serious** y **critical** rompen el build sin excepción.
`moderate`/`minor` avisan y entran en el registro. **Las exclusiones (`disableRules`,
selectores excluidos) se declaran en el fichero de configuración con motivo e issue asociado,
nunca en línea y nunca en silencio.**

### 4.3 Lo que no se puede automatizar (y es obligatorio)

**Requisito no sustituible**: antes de declarar conformidad, cada recorrido crítico se prueba

- **Solo con teclado**, sin ratón: `Tab`/`Shift+Tab` recorren todo lo interactivo en orden
  lógico, el foco es visible siempre (§3.2), no hay trampas de foco, `Escape` cierra lo que
  se abre y **el foco vuelve donde debía**.
- **Con al menos dos lectores de pantalla reales**, en su pareja natural de navegador:
  **NVDA + Firefox o Chrome (Windows)** y **VoiceOver + Safari (macOS/iOS)**; **TalkBack +
  Chrome** si hay web móvil; **JAWS** si el público objetivo es corporativo o administración
  pública. Los lectores **no se comportan igual entre sí**: un patrón que funciona en
  VoiceOver puede callar en NVDA. **Emular con el árbol de accesibilidad de DevTools no
  sustituye la prueba**; el árbol dice qué hay, no qué se oye.
- **Con zoom al 200 % y al 400 %** (1.4.4 Resize Text, 1.4.10 Reflow) y con espaciado de
  texto forzado (1.4.12).
- **Con usuarios con discapacidad** cuando el producto sea crítico o de uso masivo. Es la
  única prueba que detecta problemas de usabilidad que técnicamente "cumplen".

## 5. Seguridad y riesgos del stack

### 5.1 Los overlays de accesibilidad: PROHIBIDOS como estrategia de conformidad

**Posición formal de la comunidad**, verbatim del *Overlay Fact Sheet* (**1.031 firmantes** en
la consulta de ago-2026):

> *"1. We will never advocate, recommend, or integrate an overlay which deceptively markets
> itself as providing automated compliance with laws or standards
> 2. We will always advocate for the remediation of accessibility issues at the source of the
> original error
> 3. We will refuse to stay silent when overlay vendors use deception to market their products
> 4. More specifically, we hereby advocate for the removal of web accessibility overlay and
> encourage the site owners who've implemented these products to use more robust, independent,
> and permanent strategies to making their sites more accessible"*

**Y hay resolución de un regulador, no solo opinión**: la **FTC** ordenó a **accessiBe** pagar
**1.000.000 USD** por afirmaciones engañosas sobre su widget `accessWidget` (anuncio del
3-ene-2025; orden final aprobada el 24-abr-2025). La orden le prohíbe representar que sus
productos automáticos pueden hacer cualquier web conforme a WCAG o mantener esa conformidad
sin pruebas que lo sustenten, y también hacer pasar reseñas propias por opiniones
independientes. La FTC documentó en webs con el *overlay* instalado: `alt` ausente o
incorrecto, indicador de foco ausente, trampas de teclado y niveles de encabezado erróneos —
**es decir, el overlay ni siquiera arregla lo que dice arreglar**. Nota de rigor: fue un
acuerdo **sin admisión** de las prácticas.

**Criterio**: un overlay **no** se instala como solución de conformidad. Si ya está instalado,
**retirarlo** forma parte del plan de remediación. Un widget propio de preferencias
(contraste, tamaño de texto) construido y auditado por el equipo **no es un overlay** y es
legítimo — la diferencia es que no promete conformidad ni se inyecta sobre el DOM ajeno.

### 5.2 Riesgo de terceros

Un overlay o un widget de accesibilidad de terceros es **JavaScript de terceros con acceso
total al DOM**, que a menudo intercepta el foco y la entrada de teclado. Implicaciones que
suelen pasarse por alto: superficie de XSS y de cadena de suministro, incompatibilidad con
una CSP estricta (obliga a `unsafe-inline` o a `unsafe-eval` con frecuencia), y **tratamiento
de datos de usuarios con discapacidad** — categoría especialmente sensible bajo el RGPD (ver
`privacy-engineering-standards`). Si aun así entra, entra con SRI, con revisión de CSP y con
DPA firmado.

### 5.3 Accesibilidad y controles de seguridad

- **CAPTCHA**: si es la única forma de pasar, incumple 3.3.8 (§3.6). Alternativas: detección
  sin interacción, tokens de atestación, límite de tasa. Si hay CAPTCHA, **alternativa no
  visual y no cognitiva obligatoria**.
- **MFA**: los códigos de un solo uso deben poder **pegarse** y ser leídos por el gestor de
  contraseñas (`autocomplete="one-time-code"`). Bloquear el pegado por "seguridad" es un
  incumplimiento con coste de seguridad negativo.
- **Timeouts de sesión**: 2.2.1 Timing Adjustable (nivel A) exige avisar y permitir extender.
  Un cierre de sesión silencioso a los 15 minutos rompe a quien necesita más tiempo.
- **Contenido oculto por seguridad**: `aria-hidden="true"` **nunca** sobre algo enfocable
  (§7). Si debe ocultarse a todos, `hidden`/`display:none`/`inert`.

## 6. Operabilidad: declarar, medir y no regresar

### 6.1 Declaración de accesibilidad

Cuando la ley la exige (sector público UE: Directiva 2016/2102; España: **RD 1112/2018**), la
declaración **es un entregable con contenido tasado**, no una página de buenas intenciones.
Debe incluir, como mínimo: estado de cumplimiento (conforme / parcialmente conforme / no
conforme), **qué partes del contenido no son accesibles y por qué**, alternativas ofrecidas,
mecanismo de comunicación y solicitud de información accesible, **procedimiento de queja y
reclamación**, fecha de la declaración y **fecha de la última revisión**. El RD 1112/2018
obliga además a **revisiones periódicas** y a mantenerla actualizada. **Una declaración que
afirma conformidad total sin auditoría manual detrás es una falsedad documentada con nombre
del responsable encima.** Redactar como parcialmente conforme con lista de excepciones
sinceras es la opción correcta y la defendible.

Para el mercado estadounidense el documento equivalente es el **VPAT / ACR**, que lo pide el
comprador en el pliego, no el regulador.

### 6.2 Auditoría e informe

Alcance por **recorridos de usuario**, no por número de páginas. Cada hallazgo lleva:
criterio de éxito incumplido (número y nivel), severidad por impacto en el usuario (no por
facilidad de arreglo), pasos de reproducción, tecnología asistiva y navegador usados, y
propuesta de remediación. **Los hallazgos entran en el mismo backlog que los demás bugs, con
el mismo SLA de severidad.** Un tablero de accesibilidad aparte es un tablero que nadie mira.

### 6.3 No regresión

- Métrica que se sigue: **violaciones `serious`+`critical` por recorrido crítico**, tendencia
  mensual. Objetivo: cero, y **sin regresión** entre releases.
- **Cobertura de auditoría manual**: % de recorridos críticos probados con teclado y lector
  de pantalla en los últimos N meses. Es la métrica honesta; el resto es el 40-57 %.
- Los componentes del sistema de diseño se auditan al publicarse una versión mayor y su
  informe se versiona con el componente.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisar por web el estado de WCAG, EN 301 549 y las fechas legales **cada
  trimestre**; las herramientas, con la cadencia normal de dependencias. `axe-core` cambia de
  reglas entre versiones menores: **fijar versión y revisar el *changelog*** antes de subir,
  porque una versión nueva puede romper el build con hallazgos legítimos nuevos (eso es
  bueno: se arreglan, no se silencian).
- **No planificar contra WCAG 3.0** (§2.1). Planificar contra 2.2 AA.
- **La accesibilidad se estima dentro de la historia**, no como historia aparte. Una historia
  sin criterios de aceptación de accesibilidad no cumple la *Definition of Ready*.

Prohibiciones explícitas:

- ❌ **Overlays de accesibilidad como solución de conformidad** (accessiBe, UserWay, AudioEye
  y similares en modo *widget*). Ver §5.1: hay posición formal de 1.031 firmantes y una orden
  de la FTC de 1 M USD.
- ❌ **`outline: none` (o `outline: 0`) sin indicador de foco sustituto** que cumpla 1.4.11
  y 2.4.7. Es el incumplimiento de una línea más repetido del sector.
- ❌ **`aria-hidden="true"` sobre contenido interactivo o que lo contenga**. Crea un elemento
  enfocable e invisible para la tecnología asistiva: el peor de los dos mundos. Usar `inert`.
- ❌ **`tabindex` positivo** (`tabindex="1"` y superiores). Rompe el orden del documento en
  toda la página, no solo donde se pone. Solo `0` y `-1`.
- ❌ **Texto dentro de imágenes** para contenido (1.4.5 Images of Text, AA). No escala, no se
  traduce, no se selecciona y suele fallar contraste. Excepciones: logotipos y casos donde la
  presentación es esencial.
- ❌ **`placeholder` como única etiqueta** de un campo.
- ❌ **`<div>`/`<span>` con `onclick`** sin `role`, sin `tabindex="0"` y sin manejo de teclado.
  Antes de eso, `<button>` (§3.4).
- ❌ **Anunciar "conforme WCAG AA" sin auditoría manual** con teclado y lector de pantalla.
  Con declaración legal firmada, además de falso es responsabilidad.
- ❌ **Silenciar reglas de `axe-core` en línea** o excluir selectores sin motivo escrito e
  issue asociado.
- ❌ **`user-scalable=no` / `maximum-scale=1`** en el `viewport`: bloquea el zoom (1.4.4).
- ❌ **Cambio de ruta en SPA sin gestión de foco ni anuncio** (§3.5).
- ❌ **Subtítulos automáticos sin revisión humana** presentados como cumplimiento de 1.2.2.
- ❌ **PDF sin etiquetar** como único formato de un contenido esencial.
- ❌ **Tratar la accesibilidad como fase final** ("lo pasamos por axe antes de salir"). El 43-60
  % que la automatización no ve se descubre entonces, cuando el rediseño ya no cabe.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un proyecto real, verificar en la fuente
primaria:

1. **WCAG**: `w3.org/WAI/standards-guidelines/wcag/` — versión que es Recomendación hoy y
   fecha de la última actualización. Texto normativo de cada criterio en `w3.org/TR/WCAG22/`,
   **copiado verbatim**: un matiz mal transcrito cambia si algo cumple o no.
2. **WCAG 3.0**: `w3.org/TR/wcag-3.0/` — comprobar que sigue siendo *Working Draft*.
   **Hueco declarado**: fechas previstas de Candidate Recommendation y de Recommendation, sin
   fuente primaria; las cifras que circulan (Q4-2027, ≥2028, 2029) son de terceros.
3. **EAA**: EUR-Lex CELEX `32019L0882` — arts. 4, 31 y 32 en su texto consolidado. **No fiarse
   de resúmenes**: el art. 31.1 (28-jun-2022, transposición) se confunde sistemáticamente con
   el 31.2 (28-jun-2025, aplicación), y un resumidor automático los invirtió durante esta misma
   verificación.
4. **España**: BOE-A-2023-11022 (Ley 11/2023) — **huecos declarados**: no se han verificado en
   fuente primaria las cuantías del régimen sancionador ni el plazo exacto de la disposición
   transitoria sobre terminales de autoservicio (una fuente secundaria dice 10 años, la EAA
   habla de vida útil económica con tope; **discrepancia sin resolver**). BOE-A-2018-12699
   (RD 1112/2018) y BOE-A-2026-4520 (RD 143/2026).
5. **EN 301 549**: página de ETSI y **la cita en el DOUE**, que es lo que da presunción de
   conformidad. **Hueco declarado**: la publicación de V4.1.1 en el DOUE (se cita "octubre de
   2026" en fuentes secundarias) no está confirmada por fuente primaria. Recordar el verbatim
   de la Comisión: *"New versions of the WCAG or of EN 301 549 do not automatically change the
   legal obligations."*
6. **EE. UU.**: `ada.gov` para el Título II — **las fechas vigentes son 26-abr-2027 y
   26-abr-2028**, no las de 2026 que siguen repitiendo las guías de proveedores
   (**discrepancia declarada**, §2.2). `section508.gov` para confirmar si sigue en WCAG 2.0 AA.
7. **Cifras de automatización**: el 57 % es de Deque sobre sus propias herramientas y el 40 %
   es de GDS. Buscar si hay estudio independiente más reciente antes de citar cualquiera.
8. **WebAIM Million**: se publica anualmente (última verificada: **febrero de 2026**).
   Comprobar la edición vigente antes de citar porcentajes.
9. **Overlays**: `overlayfactsheet.com` (número de firmantes, verificado: **1.031**) y
   `ftc.gov` para el estado de la orden contra accessiBe y cualquier acción posterior contra
   otros proveedores.
10. **Herramientas — versión y licencia, leyendo el `LICENSE` en crudo**: `axe-core`
    (verificado 4.12.1, **MPL-2.0**), `pa11y` (9.1.1, **LGPL-3.0-only** — no MIT),
    `lighthouse` (13.4.1, Apache-2.0), `@lhci/cli` (0.15.1, Apache-2.0). Comprobar además si
    alguna ha pasado a modo mantenimiento o ha cambiado de repositorio: **el feed de releases
    de GitHub no es la fuente de verdad de un proyecto**; contrastar con su web oficial.
11. **Hueco declarado**: la adopción de WCAG 2.2 como **ISO/IEC 40500** (se cita una edición
    de 2025) no se ha verificado contra ISO ni contra W3C. No afirmarlo sin comprobarlo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
