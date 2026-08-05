---
name: design-systems-standards
description: Use when a UI component library is shipped as a versioned product for other teams - design tokens as tokens.json with DTCG $type/$value, style-dictionary config, Tokens Studio, semantic vs literal token naming, theming with CSS custom properties, color-scheme and light-dark(), choosing between headless primitives (radix-ui, @base-ui/react, react-aria-components, @ark-ui/react, @headlessui/react) and full libraries (@mui/material, antd, @chakra-ui/react, @mantine/core, @carbon/react), shadcn/ui components.json and copied-in component code, component public API design (props vs composition, slots, asChild, render props, boolean prop explosion), .storybook/main.ts and *.stories.tsx, Storybook 10 and the Vitest addon, Chromatic or Percy or Lost Pixel visual regression snapshots, per-component axe checks, changesets and semver for a component package, breaking-change policy and codemods, design system adoption metrics, contribution and exception process, or deciding whether to build a design system at all.
---

# Estándares de sistemas de diseño

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Eje**: un sistema de diseño es un **producto con dueño, versión y consumidores**, no una carpeta de
componentes. Si no tiene mantenedor con nombre, versión publicada y política escrita de cambios
rompientes, no es un sistema de diseño: es **deuda técnica con logotipo** y con una presentación bonita.

Esta skill decide **el contrato del componente y el gobierno del sistema**: cuándo hacer uno y cuándo no,
sobre qué base construirlo, cómo se modelan los tokens, cómo se diseña la API pública de un componente,
cómo se versiona, cómo se prueba y cómo se mide su adopción.

Triggers: `tokens.json` / `*.tokens.json` con `$type`/`$value`, `config.json`/`sd.config.js` de Style
Dictionary, `components.json` de shadcn/ui, `.storybook/main.ts`, `*.stories.tsx`/`*.stories.ts`,
`chromatic.config.json`, `.changeset/`, `packages/ui/` en un monorepo, `theme.ts`/`preset.ts` de una
librería de UI, imports de `radix-ui`, `@base-ui/react`, `react-aria-components`, `@ark-ui/react`,
`@headlessui/react`, `@mui/material`, `antd`, `@chakra-ui/react`, `@mantine/core`, `@carbon/react`,
custom properties de tema, `color-scheme`, `light-dark()`, codemods de migración de componentes.

**No aplica**:
- `frontend-web-platform-standards` — **la plataforma del navegador es suya**: qué CSS y qué APIs se
  pueden usar (política Baseline), el modelo de carga, CSP/Trusted Types, el presupuesto global de bytes
  y la cadena de suministro npm. Aquí el sistema **consume** esa política; no la re-decide. `light-dark()`
  o `@layer` se usan si allí están permitidos.
- `frontend-frameworks-standards` — **elige el framework, el modelo de renderizado y la arquitectura de
  la aplicación**. Aquí el componente como **unidad publicada y su contrato**, incluido el coste de que
  ese componente traiga `"use client"` o requiera hidratación. Qué framework lo renderiza es de allí.
- `accessibility-standards` — **el criterio de conformidad WCAG 2.2, el ARIA correcto, la auditoría y la
  declaración de accesibilidad son suyos**. Aquí la consecuencia arquitectónica: **el componente del
  sistema es donde ese criterio se implementa una sola vez** y desde donde se propaga. Un hallazgo de
  auditoría se traduce a un cambio de componente; la auditoría en sí se cede.
- `web-performance-standards` — Core Web Vitals, presupuestos y medición. Aquí solo el **peso del propio
  sistema de componentes** (JS por componente importado, CSS de tema) como criterio de diseño de API.
- `typescript-standards` — **el lenguaje, `tsconfig.json`, el tipado de las props, el empaquetado del
  paquete npm (`exports`, ESM/CJS, `sideEffects`) y su publicación son suyos**. Aquí qué debe expresar
  la API, no cómo se tipa ni cómo se publica.
- `testing-qa-standards` — estrategia de prueba agnóstica y política de *flaky*. Aquí qué se prueba en
  un componente publicado (§4).
- `git-workflow-standards` — SemVer, Conventional Commits, changesets y CHANGELOG como mecánica. Aquí
  **qué cuenta como cambio rompiente en una UI**, que es la parte que ninguna herramienta decide.
- `cicd-standards` (la pipeline que publica el paquete y ejecuta los gates), `cms-jamstack-standards`
  (**recíproca**: el sistema de diseño aporta la capa de presentación; el CMS aporta el contenido que
  esa capa muestra — ninguno decide por el otro), `privacy-engineering-standards` (consentimiento en los
  componentes de formulario), `mobile-standards` (componentes nativos y multiplataforma),
  `observability-standards` (telemetría de uso; aquí solo qué métrica de adopción importa).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).
> Versiones y licencias leídas del registro npm y del `LICENSE` en crudo a **ago-2026**.

### Decisión 0: ¿hace falta un sistema de diseño?

| Situación | Respuesta |
|---|---|
| **Un producto, un equipo** | **No.** Adopta una librería existente y personalízala con tokens. Un sistema propio para un solo consumidor es coste sin beneficio: la ganancia del sistema es la **consistencia entre consumidores**, y con uno solo no hay nada que consistir |
| Dos productos, mismo equipo | Todavía no. Un paquete `ui` compartido en el monorepo, sin gobierno, sin sitio de documentación y sin release independiente |
| Tres o más productos, o dos equipos que no se coordinan a diario | **Sí**, y con dueño asignado y presupuesto de mantenimiento explícito |
| Marca propia fuerte, requisito de accesibilidad transversal, o auditorías recurrentes | **Sí**: el sistema es el único sitio donde esos requisitos se pagan una vez |
| "Lo queremos para que todo se vea igual" sin nadie que lo mantenga | **No.** Sin mantenedor nombrado, el sistema es abandonware a los seis meses y peor que no tenerlo, porque la gente lo copia y lo bifurca |

Un sistema de diseño es un **compromiso plurianual**: mantenimiento, soporte a consumidores, migraciones,
documentación y respuesta a peticiones. Si nadie tiene ese trabajo en su rol, no se empieza.

### Decisión 1: base sobre la que construir

Tres estrategias, con criterio, no con preferencia:

| Estrategia | Cuándo | Coste real |
|---|---|---|
| **Adoptar una librería completa** (Material, Ant, Chakra, Mantine, Carbon) y tematizarla | Producto interno, herramienta de back-office, plazo corto, marca poco diferenciada | Te casas con su modelo de tema y sus majors. Salir de ella es un refactor total. El diseño acaba pareciéndose a la librería, no a tu marca |
| **Construir sobre primitivas accesibles** (headless) | **Default para un sistema propio con marca**. Te dan comportamiento, foco, teclado y ARIA; tú pones todo el CSS | Mantienes tu capa de estilos y el pegamento. Dependes del ritmo de la primitiva |
| **Partir de cero** | Solo si tienes requisitos que ninguna primitiva cubre **y** gente capaz de mantener accesibilidad de diálogos, menús, combobox y tablas | Reimplementar foco, `aria-activedescendant`, portales, colisiones de posición y navegación por teclado es **años-persona** de trabajo que se subestima siempre. Es la decisión más cara y la que más se toma por error |

**Regla dura**: no reimplementes un `Dialog`, `Menu`, `Combobox`, `Select`, `Tooltip`, `Popover` ni
`Tabs` desde cero. Son los componentes donde la accesibilidad y el manejo de foco fallan en silencio y
donde la auditoría siempre pega.

### Primitivas headless (estado a ago-2026)

| Librería | Versión | Licencia | Criterio |
|---|---|---|---|
| **Base UI** (`@base-ui/react`) | **1.6.0** | **MIT** | **Default para React nuevo.** Equipo dedicado (autores de Radix, Floating UI y MUI), API estable desde 1.0, composición por *render prop* en vez de `asChild`, y cubre combobox y multi-select que a Radix le faltan. **Ojo al paquete**: el antiguo `@base-ui-components/react` está congelado en `1.0.0-rc.0` — el nombre publicado es `@base-ui/react` |
| **Radix Primitives** (`radix-ui`) | **1.6.7** | **MIT** (copyright **WorkOS**) | Sigue siendo la base más extendida y no está abandonada, pero su cadencia bajó tras la adquisición por WorkOS. **Base sólida para lo que ya existe; no la elección obvia para greenfield.** No migres por moda: no hay urgencia |
| **React Aria Components** (`react-aria-components`) | **1.20.0** | **Apache-2.0**, no MIT | La implementación de accesibilidad e internacionalización más rigurosa (Adobe): teclado, táctil, RTL, `Intl`. Elígela cuando la accesibilidad y el i18n sean requisito contractual. Más verbosa y con más conceptos propios |
| **Ark UI** (`@ark-ui/react`) | **5.38.0** | **MIT** | La única con paridad real **multi-framework** (React, Vue, Solid, Svelte) sobre máquinas de estado. Elígela si el sistema debe servir a productos con frameworks distintos — que es la situación que suele forzar un sistema de diseño en una empresa grande |
| **Headless UI** (`@headlessui/react`) | **2.2.10** | **MIT** | Alcance pequeño y cerrado, pensado para acompañar a Tailwind. Suficiente para un puñado de componentes; **insuficiente como base de un sistema completo** |

### shadcn/ui no es una dependencia

`shadcn` (CLI **4.16.1**, MIT) **copia código a tu repo**. No aparece en `package.json` como librería de
componentes: aparece como ficheros tuyos. Consecuencias que hay que aceptar por escrito antes de usarlo:

- **Tú eres el mantenedor** desde el minuto uno. No hay `npm update` que traiga arreglos de accesibilidad
  ni parches de comportamiento: hay que ir a leer el upstream y aplicarlos a mano, componente a componente.
- **Las actualizaciones son diffs manuales.** Si has modificado el componente (que es el motivo por el que
  lo copiaste), el upstream y tu versión divergen y la reconciliación es trabajo humano cada vez.
- A cambio: cero capa de abstracción, control total del markup y de los estilos, y **ninguna dependencia
  que pueda cambiar de licencia o de rumbo**. Para un sistema propio con marca es un punto de partida
  legítimo — **como andamio, no como sistema**.
- Si se usa: se **versiona el resultado como paquete propio** con su changelog, y se registra de qué
  revisión de upstream vino cada componente. Copiar sin dejar rastro de la procedencia es lo que convierte
  esto en deuda.
- Cambio verificado (jul-2026): **shadcn/ui adopta Base UI como default para proyectos nuevos**, con
  Radix aún soportado y recomendación explícita de **no migrar** lo existente por sistema.

### Librerías completas (si la Decisión 1 fue "adoptar")

| Librería | Versión | Licencia | Nota de coste / bloqueo |
|---|---|---|---|
| **Material UI** (`@mui/material`) | **9.2.0** | MIT | El core es MIT, pero **MUI X (data grid avanzado, pickers de rango, charts, tree view) es comercial y de pago por desarrollador**. Verificado: **desde el 2026-04-08 MUI X cambia a licencia por aplicación** (mono-aplicación vs. multi-aplicación) y sube precio; el plan Enterprise es siempre multi-aplicación con **mínimo 15 asientos**. Si tu roadmap incluye una tabla de datos seria, **eso es una línea de presupuesto**, no un detalle |
| **Ant Design** (`antd`) | **6.5.3** | MIT | Estética muy marcada y difícil de despersonalizar; documentación y ecosistema con fuerte sesgo al mercado chino |
| **Chakra UI** (`@chakra-ui/react`) | **3.36.1** | MIT | v3 reescrita sobre Ark UI. Buen equilibrio, pero el salto v2→v3 fue una migración real: **cuenta el churn histórico al comprometerte** |
| **Mantine** (`@mantine/core`) | **9.5.1** | MIT | Cobertura amplísima lista para usar. Dependencia efectiva de un mantenedor principal: es el riesgo a nombrar |
| **Carbon** (`@carbon/react`) | **1.113.0** | **Apache-2.0**, no MIT | Sistema de IBM, muy completo y accesible, pero **su lenguaje visual es la marca de IBM**: adoptarlo es adoptar su estética |

**Nada de mezclar dos librerías completas** en el mismo producto: duplicas tokens, temas, portales,
gestión de foco y peso, y ningún equipo consigue mantener las dos coherentes.

### Tokens y documentación

| Pieza | Elección | Estado a ago-2026 |
|---|---|---|
| Formato de tokens | **DTCG** (`$value`, `$type`, `$description`) | Primera versión **estable: 2025.10**. **Atención**: es un *Community Group Report* del W3C, **no es un W3C Standard ni está en la vía de estándares**. Los borradores posteriores en `designtokens.org/tr/drafts` se declaran a sí mismos como no implementables |
| Transformación a plataformas | **Style Dictionary** | **5.5.0**, licencia **Apache-2.0** (no MIT) |
| Autoría desde diseño | **Tokens Studio** para Figma | **Producto comercial con plan gratuito** (Starter, incluye sync a Git); las funciones de automatización, multi-fichero y la plataforma Studio son de pago. **Verifica precio y límites en su web antes de comprometerte** |
| Documentación viva | **Storybook** | **10.5.6**, MIT. Sigue siendo el default por ecosistema. Alternativas: **Ladle** (React + Vite, mucho más rápido, sin ecosistema de addons) e **Histoire** (Vue/Svelte; su formato `.story.vue` **no es CSF**, así que salir de él es reescribir las historias) |
| Regresión visual | Ver §4 — es la partida de coste real del sistema |

## 3. Estructura y convenciones

### Tokens: semántica frente a valor literal

La distinción que decide si el sistema sobrevive a un rediseño:

| Capa | Ejemplo | Quién la consume |
|---|---|---|
| **Primitivos** (valor literal) | `color.blue.600`, `space.4`, `font.size.14` | **Solo la capa semántica.** Un componente que use esto directamente es un bug |
| **Semánticos** (intención) | `color.action.background`, `color.text.muted`, `space.stack.md`, `color.feedback.danger.border` | Los componentes y las aplicaciones |
| **De componente** (opcional) | `button.primary.background` → alias de un semántico | Solo el componente. Útil en sistemas grandes; **innecesario en pequeños** |

- `color-primary-600` es un **valor**: dice qué es. `color-action-background` es **semántica**: dice para
  qué sirve. En un rediseño, el primero hay que buscarlo y reemplazarlo en cada consumidor; el segundo
  cambia una vez en la definición. **La segunda capa es todo el retorno del sistema de tokens.**
- **Una aplicación consumidora nunca referencia un primitivo.** Si lo necesita, es que falta un token
  semántico: la petición se atiende añadiéndolo, no abriendo la escala primitiva al público.
- Escalas cerradas y pequeñas: espaciado en progresión definida (no valores arbitrarios), tipografía con
  un número contado de tamaños, radios y sombras enumerados. **Una escala con 40 valores no es una
  escala: es una paleta libre con más pasos de burocracia.**
- Los tokens son **el contrato con diseño** y viven en un fichero versionado, no en Figma "y además" en
  el código. Una sola fuente de verdad, exportada al resto. Si Figma y el código pueden divergir, ya
  divergieron.
- El pipeline de tokens es un **build reproducible** (Style Dictionary → CSS custom properties, JS/TS,
  iOS/Android si aplica) y corre en CI. Tokens copiados a mano entre plataformas es la vía garantizada
  a la incoherencia.

### Temas y modo oscuro

- Los temas se implementan con **custom properties de CSS** redefinidas por ámbito. Nada de dos hojas
  completas ni de recargar CSS al cambiar de tema.
- `color-scheme` declarado (`light dark`) para que los controles nativos, las barras de scroll y los
  formularios sigan el tema. Se olvida siempre y es lo que delata un modo oscuro a medias.
- `light-dark()` reduce a la mitad las declaraciones de color **si tu política de Baseline lo permite**
  (esa política es de `frontend-web-platform-standards`; **verifícala, no la asumas**).
- **Respeta `prefers-color-scheme` por defecto** y permite override explícito del usuario, persistido.
  Forzar un tema ignorando la preferencia del sistema es una decisión de producto que hay que justificar.
- Un tema **no puede cambiar la semántica**: `color.feedback.danger` sigue significando peligro en todos
  los temas. Si un tema reasigna significados, no es un tema: es otro sistema.
- Contraste verificado **por combinación semántica en cada tema**, no una vez en el claro. El criterio
  de conformidad es de `accessibility-standards`; la obligación de comprobarlo en ambos temas es de aquí.

### La API de un componente es un contrato público

Una vez publicada, cambiarla cuesta a todos los consumidores. Se diseña como se diseña una API HTTP.

- **Composición antes que configuración.** `<Card><Card.Header/><Card.Body/></Card>` escala; una `Card`
  con `title`, `subtitle`, `icon`, `action`, `footer`, `variant`, `dense`, `bordered` no escala: crece
  con cada petición hasta ser inmantenible.
- **Veinte props booleanos son un fallo de diseño, no una API flexible.** Cada booleano multiplica los
  estados posibles (2^n) y ninguno está probado. Señales de que hay que romper el componente en partes o
  sustituir booleanos por una prop de variante enumerada: booleanos mutuamente excluyentes (`primary`,
  `secondary`, `danger` → `variant`), booleanos que solo aplican si otro es cierto, y props que existen
  para un único consumidor.
- **Slots** para el contenido que el consumidor debe controlar; props para lo que el sistema debe decidir.
  Si el consumidor necesita meter markup arbitrario donde no hay slot, la salida será un hack de CSS
  contra tus clases internas — y ese hack se romperá en tu siguiente patch.
- Polimorfismo del elemento raíz (`render` prop en Base UI, `asChild` en Radix, `as`) para no forzar un
  `<div>` donde toca un `<a>` o un `<li>`. Sin esto, la semántica correcta se vuelve imposible.
- **Pasa el resto de props al elemento subyacente** (`...rest`) y **acepta `ref`**: un componente que no
  deja poner `id`, `aria-*`, `data-*` ni obtener el nodo obliga a bifurcarlo.
- **Las clases y los nodos internos no son API pública.** Documenta explícitamente qué es público (props,
  slots, tokens, atributos `data-*` de estado) y qué no. Sin esa frontera escrita, cualquier refactor
  interno es un cambio rompiente de facto porque alguien estilaba `.ds-button__inner`.
- Prohibido `style`/`className` como vía de escape universal sin diseño: o hay una prop de variante, o hay
  un slot, o hay un token. Si aun así hace falta, ver "ruta de escape" en §7.
- Estados obligatorios en todo componente interactivo: reposo, hover, **focus-visible**, activo,
  deshabilitado, cargando, error. Un componente sin estado de foco visible no está terminado.
- **Nada de lógica de negocio ni de fetch dentro de un componente del sistema.** Un `UserAvatar` que
  llama a tu API deja de ser reutilizable y arrastra el cliente HTTP a todos los consumidores.
- La API se escribe **antes** de implementar y se revisa con al menos un consumidor real. Diseñar en
  abstracto produce componentes que nadie usa como se esperaba.

### Organización

- **Un paquete publicado**, no un directorio compartido por ruta relativa: `@org/ui`, con versión, y
  `@org/tokens` aparte si hay consumidores no-web. Los tokens se publican por separado porque su ciclo
  de vida es más lento y su audiencia más amplia.
- **Exportaciones granulares** y `sideEffects` correcto: importar un botón no puede arrastrar el paquete
  entero. Un sistema que solo se puede importar en bloque impone su peso completo a cada consumidor.
- Marca explícitamente los componentes que requieren cliente (`"use client"`) y **mantén el máximo
  posible sin él**: en un sistema consumido por apps con RSC, un `"use client"` en el índice contamina
  todo el árbol.
- CSS del sistema en su propia capa (`@layer`) para que el consumidor pueda ganar especificidad sin
  `!important`.

## 4. Calidad y testing de un sistema de diseño

Un componente publicado se prueba **más** que uno de aplicación: su fallo se multiplica por el número de
consumidores. Gates en orden de coste creciente, cada uno rompe el build:

1. **Typecheck y lint** del paquete (reglas del lenguaje: `typescript-standards`).
2. **API pública congelada**: un informe de la superficie pública (props exportadas, tipos) versionado en
   el repo, cuyo cambio no revisado falla. Es el único gate que detecta un rompiente accidental **antes**
   de publicarlo.
3. **Tests de componente** (Vitest + Testing Library, o el addon de Vitest de Storybook desde v9/10, que
   **sustituye al antiguo `@storybook/test-runner`**): interacción por teclado, estados de carga, error,
   vacío y deshabilitado. Las historias son los casos de prueba: **una historia por estado**, no una
   historia "playground" con controles.
4. **Accesibilidad por componente**, automatizada (axe en cada historia). Cubre ~30-40% de los criterios:
   **el resto es revisión manual y es responsabilidad de `accessibility-standards`**. Un gate de axe verde
   no es una declaración de conformidad y afirmarlo es un riesgo legal, no solo técnico.
5. **Contract tests con los consumidores**: construir al menos una aplicación consumidora real contra la
   versión candidata antes de publicar. Es lo que convierte "creo que no rompe" en un hecho.
6. **Regresión visual** — ver abajo.

### Regresión visual: elige con el coste delante

Es imprescindible (el CSS no tiene tipos: nada más detecta que un cambio de token movió un padding en
30 componentes) y es **la partida de coste recurrente del sistema**. Se factura por *snapshot* =
historia × viewport × navegador × tema, así que **el coste crece de forma multiplicativa** y la factura
sorprende siempre.

| Opción | Modelo | Verificado a ago-2026 |
|---|---|---|
| **Playwright screenshots** / BackstopJS | Gratis, autoalojado | Coste = mantener las imágenes de referencia y el ruido entre entornos. **Exige runner con SO fijado** (contenedor), o el antialiasing produce falsos positivos eternos |
| **Lost Pixel** | Open source + nube opcional | Plan gratuito citado en **7.000 snapshots/mes** — el más generoso de los comparados. **Confirmar en su web** |
| **Chromatic** | SaaS, acoplado a Storybook | **5.000 snapshots/mes gratis**; al agotarlos, *"testing and review will pause until the next month"* — **no hay overage: se para**. De pago desde ~$149-179/mes según fuente (**las fuentes discrepan**). Solo Chrome estable; Firefox/Safari en beta. TurboSnap reduce el volumen |
| **Percy** (BrowserStack) | SaaS | ~5.000 screenshots/mes gratis; factura **por screenshot** (página × navegador × ancho): 2 páginas × 2 navegadores × 3 anchos = **12**. Haz la multiplicación antes de firmar |
| **Applitools** | Enterprise, sin precios públicos | Comparación visual con IA, la más madura en reducción de ruido. Sin tarifa pública = negociación y bloqueo |

Criterio: empieza con el runner gratuito en contenedor fijado y **solo** paga cuando el ruido te esté
costando más horas que la factura. Y en cuanto pagues, **limita el número de historias con snapshot**:
no todas las historias necesitan captura en cuatro navegadores.

## 5. Seguridad del sistema

- El sistema es **una dependencia de todos tus productos a la vez**: un compromiso de su paquete es un
  compromiso de todo el portfolio. La higiene de la cadena de suministro npm es de
  `frontend-web-platform-standards`; aquí la consecuencia: publicación con **trusted publishing/OIDC**,
  sin tokens de larga vida, mínimo de mantenedores con permiso de publish y 2FA obligatorio.
- **Ninguna prop de un componente publicado renderiza HTML crudo.** Si un `RichText` es inevitable, la
  sanitización va **dentro** del componente y no es opcional ni desactivable por prop, porque el
  consumidor la desactivará. Los sinks y la sanitización, en `frontend-web-platform-standards`.
- Un componente del sistema no compone URLs de destino sin validar el esquema: un `<Link href>` que
  acepta `javascript:` es un XSS distribuido a todos los consumidores.
- Cero telemetría oculta en los componentes: un sistema de diseño que llama a casa desde la app de un
  cliente es un incidente de privacidad, no una métrica de adopción (§7 explica cómo medir sin eso).
- Iconos e ilustraciones SVG del sistema: **sanitizados en el build** (SVG puede llevar `<script>` y
  handlers). Nunca se inyectan SVG de terceros en tiempo de ejecución.
- Dependencias del propio sistema al mínimo: cada una la heredan todos los consumidores y ninguno la
  eligió. Añadir una dependencia al sistema exige justificación escrita.

## 6. Rendimiento y operabilidad

- **Peso por componente medido y publicado**, no solo peso total del paquete: el consumidor necesita saber
  qué le cuesta importar el date picker. Sin tree-shaking real verificada, el sistema impone su peor caso
  a todos.
- Presupuesto del propio sistema: un componente que arrastra una dependencia pesada (editor, gráficas,
  máscara de fecha) se publica en **subpath aparte** y se documenta su coste. Los umbrales globales son de
  `web-performance-standards`.
- CSS de tema: una hoja de custom properties, no una por componente cargada a destiempo. Un cambio de
  tema no debe provocar *flash* de contenido sin estilo ni recalculo global.
- **El sitio de documentación es producción**: si Storybook está caído o desactualizado, el sistema no
  existe para sus consumidores. Se despliega por CI en cada merge, con la versión visible en la propia
  documentación.
- Instrumentación útil: qué versión del sistema usa cada aplicación (lockfiles del monorepo o consulta
  a los repos), no telemetría en runtime.

## 7. Sostenibilidad, gobernanza y prohibiciones

### El sistema es un producto: dueño, versión, consumidores

- **Dueño con nombre y tiempo asignado.** Sin eso, no se arranca (§2, Decisión 0).
- **SemVer estricto en el paquete.** En una UI, cuenta como **rompiente**: quitar o renombrar una prop,
  cambiar el default de una prop, cambiar el elemento HTML raíz, quitar un token, y **todo cambio visual
  que un consumidor pueda haber compensado** (un padding, una altura de línea). Lo último es lo que casi
  nadie versiona bien: si el cambio visual obliga a alguien a tocar su CSS, es un major.
- **Política escrita de cambios rompientes**: el rompiente se agrupa en majors planificados, con período
  de deprecación **mínimo de un major** en el que la API vieja sigue funcionando y avisa (`console.warn`
  en desarrollo, marca `@deprecated` en los tipos).
- **Codemod obligatorio** para toda migración mecánica de un major (renombrado de props, cambio de import,
  sustitución de tokens). Publicar un major sin codemod es trasladar tu trabajo a N equipos y garantizar
  que la mitad se queda en la versión vieja. La regla: **si el cambio se puede automatizar, se automatiza;
  si no se puede, se documenta con un ejemplo antes/después por caso.**
- Ventana de soporte declarada: qué majors reciben parches de seguridad y accesibilidad y hasta cuándo.
- Changelog por componente, no solo por paquete: al consumidor le importa si cambió el `Select`, no leer
  200 líneas.

### Adopción y gobernanza

- **Se mide la adopción**, o no hay forma de saber si el sistema sirve: (a) porcentaje de componentes de
  cada aplicación que vienen del sistema frente a locales, (b) número de aplicaciones en la versión
  vigente y en las anteriores, (c) número de *overrides* de CSS contra clases internas —**esta es la
  métrica más honesta**: cada override es un sitio donde el sistema no cubría el caso.
- **Proceso de contribución escrito**: quién propone, quién revisa, cuánto tarda y qué pasa si nadie
  responde. Un proceso de contribución cuyo tiempo de respuesta es "cuando podamos" produce forks, y el
  fork es la muerte del sistema.
- **Las excepciones se registran, no se prohíben.** Un caso no cubierto se resuelve localmente, se
  etiqueta como excepción y **se revisa cada trimestre**: si tres equipos hicieron lo mismo, eso es un
  componente que falta, no tres desviaciones.
- **Un sistema sin ruta de escape se evita en lugar de usarse.** Si el consumidor no puede resolver su
  caso —vía slot, token, variante o composición con las primitivas—, no abandona el caso: abandona el
  sistema, copia el componente y lo bifurca. Así que **la vía de escape se diseña a propósito**: primitivas
  expuestas para componer, `@layer` para que su CSS gane sin `!important`, y un canal para pedir la
  variante que falta. Cerrar la puerta no produce cumplimiento: produce copias fuera de tu control.
- Estados de madurez por componente, visibles en la documentación: **experimental** (puede romper en
  minor, marcado como tal), **estable** (bajo SemVer), **deprecado** (con sustituto y fecha). Publicar
  todo como estable desde el día uno impide iterar.
- **La accesibilidad se resuelve una vez, aquí.** Es el argumento económico más fuerte del sistema: el
  foco, el teclado, el ARIA y el contraste se pagan en el componente y se cobran en cada consumidor.
  Corolario: un componente del sistema con un fallo de accesibilidad es **incidente de prioridad alta**,
  porque está desplegado en todos los productos a la vez. El criterio de conformidad es de
  `accessibility-standards`; el sitio donde se implementa es este.

**PROHIBIDO:**
- ❌ Crear un sistema de diseño para **un solo producto y un solo equipo**. Usa una librería y tematízala.
- ❌ Arrancar un sistema sin **mantenedor nombrado**, sin versión publicada y sin política de cambios
  rompientes. Eso no es un sistema: es deuda con logotipo.
- ❌ Reimplementar desde cero diálogos, menús, combobox, selects, tooltips o tabs habiendo primitivas
  accesibles mantenidas.
- ❌ Que una aplicación consumidora referencie un **token primitivo** (`color.blue.600`) en vez de uno
  semántico. Y ❌ tener solo capa primitiva: entonces no tienes sistema de tokens, tienes constantes.
- ❌ Un componente con veinte props booleanos, o con booleanos mutuamente excluyentes en vez de una
  variante enumerada.
- ❌ Componentes que no aceptan `ref`, no reenvían `...rest`, no permiten `aria-*`/`data-*` o fuerzan el
  elemento raíz. Obligan a bifurcar.
- ❌ Lógica de negocio, `fetch`, estado global de aplicación o cadenas de texto de producto dentro de un
  componente del sistema.
- ❌ Cambiar el aspecto de un componente en un **patch** o un **minor** porque "es solo un píxel".
- ❌ Publicar un major sin codemod para lo automatizable ni guía de migración para lo demás.
- ❌ Tratar clases y nodos internos como si fueran API pública — y ❌ no documentar cuáles no lo son.
- ❌ Mezclar dos librerías de componentes completas en el mismo producto.
- ❌ Usar shadcn/ui sin aceptar por escrito que **el mantenimiento y la reconciliación con upstream son
  tuyos**, y sin registrar de qué revisión vino cada componente.
- ❌ Prop que renderiza HTML sin sanitizar, o sanitización desactivable desde fuera del componente.
- ❌ Declarar conformidad de accesibilidad porque axe está verde en CI.
- ❌ Un sistema sin ruta de escape documentada; responder a un caso no cubierto con "no está soportado".
- ❌ Afirmar de memoria la versión, la licencia o el modelo de precio de una librería de UI. Verificado a
  ago-2026: **React Aria y Carbon son Apache-2.0**, **Style Dictionary es Apache-2.0**, **MUI X es de
  pago y cambió de modelo de licencia en abr-2026**, y el paquete estable de Base UI es `@base-ui/react`,
  no `@base-ui-components/react`.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar online (registro npm y feeds Atom `https://github.com/OWNER/REPO/releases.atom`
— **`api.github.com` da 403 sin autenticar**; web oficial del proyecto para contrastar, porque **el feed de
GitHub no es la fuente de verdad**; `LICENSE` en crudo para licencias; página de precios del proveedor para
el coste):

1. **Estado del DTCG**: ¿sigue **2025.10** siendo la última estable? ¿algún módulo nuevo estabilizado?
   **No afirmes que existe un "estándar W3C de tokens": es un Community Group Report fuera de la vía de
   estándares.** Comprobar en `designtokens.org` y en el blog del CG.
2. **Style Dictionary** (¿sigue 5.x? ¿soporte DTCG completo?) y **Tokens Studio**: precio vigente, qué
   incluye el plan gratuito y qué se pierde al superarlo.
3. **Primitivas**: versión y licencia de `@base-ui/react`, `radix-ui`, `react-aria-components`,
   `@ark-ui/react`, `@headlessui/react`. **Confirmar el nombre del paquete publicado** antes de instalar.
4. **Cadencia de Radix**: ¿ha vuelto a acelerar bajo WorkOS, o sigue en mantenimiento de baja velocidad?
   Es la variable que decide si es base válida para greenfield.
5. **Librerías completas**: versión y licencia de MUI, Ant, Chakra, Mantine, Carbon, y sobre todo el
   **modelo comercial de MUI X tras el cambio del 2026-04-08** (precio real por aplicación y por asiento).
6. **Storybook**: versión mayor vigente, estado del addon de Vitest, y si `@storybook/test-runner` ya está
   retirado del todo. Estado de mantenimiento de **Ladle** e **Histoire**.
7. **Regresión visual**: precios y límites del plan gratuito de Chromatic, Percy, Lost Pixel y Argos —
   **cambian y las fuentes secundarias se contradicen**. Fuente primaria, siempre.
8. **Advisories** de las librerías que entren en el sistema (`github.com/advisories`, osv.dev): una CVE en
   tu base de componentes es una CVE en todos tus productos.

**Huecos no verificados a ago-2026** (no rellenar de memoria):
- **Precio exacto de MUI X Pro y Premium tras el 2026-04-08**: **no verificado**. El anuncio oficial
  confirma la fecha, la licencia por aplicación y el mínimo de 15 asientos en Enterprise, pero **remite a
  la página de precios para las cifras**. Los ~$15/dev/mes y ~$50/dev/mes que citan agregadores son
  **anteriores al cambio**: no los uses.
- **Precio de Tokens Studio** (Starter Plus, Essential, Organisation) y límites exactos del plan gratuito:
  **no verificados** en fuente primaria (una fuente secundaria cita ~€39/mes para Starter Plus).
- **Plan gratuito de Lost Pixel (7.000 snapshots/mes)**: tomado de fuente secundaria, **no verificado** en
  su web.
- Estado de mantenimiento actual de **Histoire** y de **Ladle**: **no verificado** más allá de cifras de
  descargas de terceros.
- Cuota de uso real de cada primitiva y librería: **no verificada** — las cifras de descargas que circulan
  vienen de comparativas de terceros, no del registro.
- Si `light-dark()` está dentro de tu política de Baseline: **es dato de
  `frontend-web-platform-standards`, que lo marca como no verificado**. Compruébalo antes de usarlo.

**Discrepancias declaradas**:
- **Base UI**: el paquete `@base-ui-components/react` sigue publicado y su `latest` es `1.0.0-rc.0`
  (modificado jul-2026), lo que induce a creer que Base UI no ha llegado a estable. **La web oficial y el
  registro coinciden en que el paquete vigente es `@base-ui/react`, versión 1.6.0 (jun-2026), MIT.** Es un
  caso literal de "el nombre antiguo miente": verifica el paquete, no solo la versión.
- **Precio de entrada de Chromatic**: una fuente lo sitúa en $149/mes y otra en $179/mes (Starter, jun-2026)
  con 35.000 snapshots. **No resuelto**; manda su página de precios.
- **Comparativas de Storybook**: varias páginas de 2026 comparan "Storybook 8" contra Ladle e Histoire
  cuando el registro npm sirve **10.5.6**. Esas comparativas están desactualizadas y sus cifras de
  descargas y arranque no son fiables.
- **Radix**: el ecosistema lo describe como "ralentizado tras la adquisición"; los analizadores automáticos
  lo marcan como "healthy" por publicar releases en los últimos tres meses. Ambas cosas son ciertas y miden
  cosas distintas — mira el historial de commits y de issues cerradas, no el badge.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
