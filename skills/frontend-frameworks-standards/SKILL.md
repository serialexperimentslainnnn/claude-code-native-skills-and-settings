---
name: frontend-frameworks-standards
description: Use when choosing or structuring a frontend framework application - deciding whether a framework is needed at all, picking a rendering model (CSR, SSR, SSG, ISR, streaming, islands, React Server Components), comparing React, Vue, Svelte, Angular, Solid, Qwik and Astro, choosing a meta-framework (next.config.ts, nuxt.config.ts, svelte.config.js, astro.config.mjs, angular.json, app.config.ts, TanStack Start, React Router framework mode, Remix), routing and data loading, loaders and server functions, server-vs-client state and TanStack Query cache invalidation, form handling and shared client/server validation, hydration cost and partial hydration, error boundaries and loading/suspense states, component testing with Vitest and Testing Library, Playwright end-to-end flows, or judging framework longevity, governance and migration risk before committing.
---

# Estándares de frameworks frontend

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio de **elección y uso** de framework: si hace falta uno, cuál, con qué modelo de
renderizado, cómo se estructura la aplicación (rutas, carga de datos, estado, formularios, errores) y
cómo se prueba. **No enseña ningún framework**: decide entre ellos y pone límites al uso.

Triggers: `next.config.ts`, `nuxt.config.ts`, `svelte.config.js`, `astro.config.mjs`, `angular.json`,
`app.config.ts`, `vite.config.ts` con plugin de framework, ficheros de ruta (`app/`, `routes/`,
`pages/`), `loader`/`action`/server functions, `"use client"`/`"use server"`, `createQuery`/
`useQuery`, error boundaries, `*.test.tsx`, `*.spec.ts` de Playwright.

**Regla de arbitraje con `frontend-web-platform-standards`**: si la respuesta **cambiaría al cambiar de
framework**, es de aquí; si **seguiría siendo cierta en cualquiera** (o sin ninguno), es de allí. "Dónde
se hace el fetch y quién revalida la caché" es de aquí; "el `fetch` lleva `AbortSignal.timeout` y la
imagen LCP lleva `fetchpriority=high`" es de allí.

**No aplica**:
- `frontend-web-platform-standards` — **decide lo que es del navegador y del estándar**: HTML semántico,
  CSS moderno y política de soporte (Baseline), APIs de plataforma, modelo de carga y red, CSP/Trusted
  Types y seguridad del cliente, presupuesto de bundle, herramienta de build (Vite/Rolldown/esbuild) y
  cadena de suministro npm. Aquí no se re-decide nada de eso: se **hereda**. Si un framework impone su
  propio bundler (Turbopack en Next), esa imposición se documenta aquí y sus consecuencias de carga se
  evalúan con el criterio de allí.
- `typescript-standards` — **el lenguaje, `tsconfig.json`, el tipado, el lint (Biome/ESLint), Zod y el
  empaquetado npm son suyos**, igual que su tabla de toolchain Next/React. Aquí la decisión *arquitectónica*
  (qué framework, qué modelo de render, dónde vive el estado), no la config del compilador ni las reglas
  de lint. Donde ambas hablan de Next.js, **manda su tabla para versiones de lenguaje y tooling** y esta
  para el criterio de elección.
- `accessibility-standards` (**Ola 6, ya escrita**) — WCAG 2.2, ARIA, teclado, tecnología asistiva y la
  auditoría. Aquí solo que las *queries por rol* de Testing Library ya auditan de facto y que los
  estados de carga y error deben ser anunciables; **el foco al cambiar de ruta y el anuncio tras una
  mutación son criterio suyo**, aunque el mecanismo lo provea el enrutador de aquí.
- `testing-qa-standards` — **la estrategia de prueba agnóstica de lenguaje es suya**: proporción de la
  pirámide, umbrales de cobertura, mutación, contratos, datos de prueba y política de *flaky*. Aquí solo
  qué probar en una UI de framework y con qué herramienta (§4).
- `web-performance-standards` (**Ola 6, en curso**) — Core Web Vitals, presupuestos y medición. Aquí la
  hidratación como coste arquitectónico, no su métrica.
- `design-systems-standards` (**ya escrita** — **el contrato público del componente**: composición
  frente a configuración, tokens, versionado del paquete y política de cambios rompientes. Aquí
  cómo el framework lo consume y lo renderiza, no cómo se diseña su API),
  `cms-jamstack-standards` (**ya escrita** — el CMS headless y el contenido son suyos; aquí cómo lo
  renderiza el framework), `pwa-standards`, `webgl-webgpu-standards` (**Ola 6, en curso**).
- `api-design-standards` (el contrato que se consume), `caching-cdn-standards` (`Cache-Control`, CDN y
  purga; aquí solo *cuándo* la app pide revalidar), `appsec-standards` (metodología y triaje),
  `secrets-management-standards` (**un secreto no vive en el cliente**: las variables expuestas al bundle
  son públicas por definición), `identity-access-management-standards` (flujos OIDC),
  `observability-standards`, `cicd-standards`, `mobile-standards` (React Native y app nativa),
  `dart-standards` (Flutter web), `webassembly-standards` (**ya escrita**).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).
> Versiones tomadas de npm/feeds oficiales a **ago-2026**; licencias leídas del `LICENSE` o del registro.

### Decisión 0: ¿hace falta framework?

| Caso | Respuesta |
|---|---|
| Sitio de contenido, blog, documentación, landing, marketing | **No**. HTML generado + CSS + JS puntual. Si hay muchas páginas y componentes, **Astro** (islas) antes que una SPA |
| Formulario sencillo (contacto, alta, búsqueda) | **No**. `<form>` con POST y validación de servidor; JS para mejorar, no para funcionar |
| Panel interactivo, editor, app con estado de cliente rico y sesión larga | **Sí**, framework con enrutado y datos |
| "Es que luego crecerá" | **No es un argumento.** Migrar contenido estático a un framework es barato; salir de una SPA que no hacía falta, no |

Un framework es una **decisión de coste permanente**: build, actualizaciones, contratación,
hidratación y superficie de CVE. Se paga cuando resuelve un problema real, no por defecto.

### Modelos de renderizado (el eje real de la decisión)

| Modelo | Resuelve | Coste real |
|---|---|---|
| **CSR** (SPA) | Interacción rica tras la carga; sin servidor de render | HTML vacío al inicio: peor primera carga, SEO frágil, todo el JS por delante |
| **SSG** | Contenido que cambia poco: HTML precomputado, cacheable en CDN | El build crece con el número de páginas; contenido fresco exige rebuild |
| **SSR** | Contenido por petición o personalizado, y HTML útil desde el primer byte | Servidor a mantener, escalar y proteger; latencia del origen en cada navegación |
| **ISR / revalidación** | Volumen de páginas SSG con frescura acotada | Complejidad de invalidación: es una caché, y las cachés tienen bugs de coherencia |
| **Streaming + Suspense** | Enviar lo listo sin esperar lo lento | Requiere diseñar límites de carga; complica el manejo de errores tardíos |
| **Islas** | Página mayormente estática con partes interactivas: se envía **solo** el JS de esas partes | Comunicación entre islas es incómoda a propósito; mal encaje si "todo" es interactivo |
| **RSC** | Componentes que se ejecutan en servidor y no viajan al cliente | Modelo mental doble (servidor/cliente), ecosistema aún acomodándose, acoplamiento fuerte al framework |

**Se elige por página o por ruta, no por proyecto.** Un mismo producto puede tener landing SSG,
listado SSR y panel CSR. Elegir un solo modelo para todo es el error frecuente.

### Frameworks: estado, cuándo sí y cuándo no

| Framework | Versión (ago-2026) | Elígelo cuando | No lo elijas cuando |
|---|---|---|---|
| **React** | **19.2.8** (MIT). Gobernanza: **React Foundation** bajo Linux Foundation desde **2026-02-24**; React, React Native y JSX ya no son de Meta. **No existe React 20** (hay mucho contenido SEO que lo afirma) | Necesitas contratar rápido, ecosistema enorme, o ya tienes React. La apuesta más segura a 3 años por gobernanza y masa crítica | El proyecto es contenido y no interacción; el equipo es pequeño y el peso de runtime importa |
| **Vue** | **3.5.40** estable; **3.6 en RC** con *Vapor Mode* (sin virtual DOM) feature-complete y reactividad reescrita sobre alien-signals (MIT) | Quieres un modelo progresivo, SFC y una curva suave; equipo mediano sin apetito por el churn de React | Necesitas la profundidad de ecosistema de React para un nicho concreto |
| **Svelte** | **5.56.8** (MIT), runes. Rich Harris trabaja en Vercel | Peso de runtime y ergonomía importan más que el tamaño del ecosistema | Contratación difícil en tu mercado; dependes de librerías que solo existen para React |
| **Angular** | **22.1.0** (MIT). v22 **signal-first**: `OnPush` por defecto (`Default` renombrado a `Eager`), Signal Forms y `resource()`/`httpResource()` estables; zoneless por defecto para apps nuevas desde v21 | Empresa grande, equipos rotativos, se valora que el framework imponga estructura, DI y herramientas; ciclo de versiones predecible | Equipo pequeño; quieres arrancar en un día. **Migrar una app existente a zoneless es trabajo real: los formularios reactivos son la parte más arriesgada** |
| **Solid** | **1.9.14** estable; **2.0 en beta** (MIT) | Rendimiento de reactividad fina con modelo mental cercano a JSX, en equipo que acepta un ecosistema pequeño | Necesitas librerías de terceros abundantes o contratación fácil. **No adoptes 2.0 en producción mientras siga en beta** |
| **Qwik** | `@builder.io/qwik` **1.20.0** estable; **Qwik 2 (`@qwik.dev/core`) sigue en beta** (2.0.0-beta.38) (MIT) | Investigación o caso donde la resumabilidad (cero hidratación) es el requisito dominante | Producción con plazos. Un v2 en beta prolongada es una señal a mirar (§7) |
| **Astro** | **7.1.6** (MIT). Compilador reescrito en Rust, sobre **Vite 8/Rolldown**; requiere Node 22.12+. **Gobernanza: Cloudflare adquirió The Astro Technology Company el 2026-01-16**; sigue open source y multi-plataforma según el anuncio | Sitio de contenido con islas: docs, blog, marketing, e-commerce de catálogo. Puede embeber componentes React/Vue/Svelte en islas | La aplicación es mayormente interactiva y con estado compartido entre zonas |

### Meta-frameworks

| Meta-framework | Versión (ago-2026) | Criterio |
|---|---|---|
| **Next.js** | **16.2.12** estable (16.3 en preview/canary), MIT | Default de React con SSR/RSC. Trae Turbopack como bundler por defecto (dev y build). Acopla a su modelo de caché y a un despliegue que rinde mejor en Vercel: es un trade-off, no un defecto oculto |
| **React Router (framework mode)** | **8.3.0**, MIT. v8 GA 2026-06-17, **gobernanza abierta y cadencia anual**; middleware por defecto, **paquetes solo ESM (sin CJS)**, exige Node 22.22+, React 19.2.7+ y Vite 7+ | La opción React con menos magia y menos acoplamiento de plataforma. La cadencia anual anclada a EOL de Node es una señal de madurez |
| **TanStack Start** | **v1** (React y Solid), sobre TanStack Router + Vite | Tipado de rutas y datos extremo. **Nota de riesgo verificada**: los paquetes `@tanstack/*` fueron víctima de la campaña Mini Shai-Hulud en may-2026 (CVE-2026-45321) — no es culpa del código, pero obliga a la higiene de §5 |
| **Nuxt** | **4.5.1** (rama 3.x aún con releases), MIT. NuxtLabs y el creador de Nitro están en **Vercel**; **advisory de seguridad de jul-2026 con RCE en servidor** — parchear es obligatorio | Default de Vue |
| **SvelteKit** | **2.70.2** estable; **3.0 en `next`**, MIT | Default de Svelte. Adaptadores por plataforma |
| **Angular** (con su CLI y SSR) | v22 | Angular no necesita meta-framework externo: ya lo es |
| **Astro** | 7.1.6 | Meta-framework de contenido; ver arriba |
| **Remix 3** | **beta** (3.0.0-beta.x), sin React, componentes propios | **No usar en producción**. Remix 2 continúa como React Router v7/v8 |

### Estado, datos y tests

| Pieza | Elección | Versión (ago-2026) |
|---|---|---|
| Caché de servidor en cliente | **TanStack Query** (o el equivalente del framework: loaders, `resource()` de Angular, `useAsyncData` de Nuxt) | `@tanstack/react-query` **5.101.4** (v6 en beta), MIT |
| Estado global de cliente | El mínimo: contexto o un store pequeño (Zustand/jotai/signals nativas del framework) | — |
| Tests de unidad y componente | **Vitest** + **Testing Library** | Vitest **4.1.10** (v5 en beta), MIT; `@testing-library/react` **16.3.2**, MIT |
| E2E | **Playwright** | **1.62.1**, licencia **Apache-2.0** (no MIT) |

## 3. Estructura y convenciones

### Estado: la mayor parte del "estado global" es caché de servidor

- Separa **estado de servidor** (datos que son propiedad del backend: entidades, listas, permisos) de
  **estado de cliente** (pestaña activa, modal abierto, borrador de formulario). Confundirlos es el
  origen del 80% del boilerplate de estado que se ve en las revisiones.
- El estado de servidor va a una **caché con claves, invalidación, reintentos y estados de carga/error**
  (TanStack Query o los loaders del framework). No se copia a un store global "para tenerlo a mano":
  eso crea dos fuentes de verdad que divergen en cuanto hay una segunda pestaña.
- El estado de cliente que queda tras hacer esto es pequeño. Si sigue siendo grande, casi siempre es
  estado derivado que debería calcularse, o estado de URL que debería vivir en la URL.
- **La URL es estado**: filtros, paginación, pestaña, orden y búsqueda van en la query string. Es
  compartible, marcable, restaurable con el botón atrás y gratis.
- Elegir un store global antes de tener el problema es sobre-ingeniería. Redux **por inercia**: vetado.

### Enrutado y carga de datos

- **Los datos se cargan a nivel de ruta**, no en `useEffect` dentro de un componente hoja: el patrón
  "renderiza → efecto → fetch" produce cascadas en serie y es la causa habitual de una app lenta.
- Rutas paralelas → peticiones paralelas. Una petición que depende de otra es una cascada consciente,
  no un descuido.
- Código dividido por ruta; precarga en `hover`/`focus` del enlace cuando el destino es probable.
- Enrutado tipado si el framework lo ofrece: un enlace roto debe ser un error de compilación.
- Mutación → invalidación explícita de las claves afectadas. Actualización optimista **solo** con
  reversión implementada y probada; si no hay rollback, no hay optimismo, hay mentira.

### Formularios y validación compartida

- Un esquema **único** (Zod o equivalente; la elección de librería es de `typescript-standards`) que se
  usa en cliente **y** en servidor. Dos validaciones escritas a mano divergen a la tercera semana.
- **La validación de cliente es UX; la que cuenta es la del servidor.** Sin excepción.
- El formulario debe funcionar con `<form>` y POST cuando el framework lo permita (progressive
  enhancement): si el JS falla o tarda, el usuario todavía puede enviar.
- Estados obligatorios: enviando, error de campo, error global, éxito. Doble submit bloqueado.
  Errores del servidor mapeados al campo correspondiente, no a un `alert` genérico.
- Ficheros y uploads: límite de tamaño y tipo validados en servidor, siempre.

### Renderizado en servidor e hidratación como coste

- **Hidratar no es gratis**: el HTML llega rápido y luego el navegador vuelve a ejecutar el árbol para
  hacerlo interactivo. Ese hueco entre "se ve" y "responde" es real y es donde se pierde la sensación
  de velocidad. SSR sin control de hidratación puede ser **peor** que CSR para el usuario.
- Estrategias, en orden de preferencia según cuánta interactividad haya: **cero JS** → **islas** →
  **hidratación parcial/selectiva** → **RSC** (el componente de servidor no viaja) → hidratación
  completa. Elegir "hidratación completa de toda la página" es la opción de último recurso, no la
  primera.
- SSR obliga a código isomorfo: nada de `window`/`document` en el camino de render. Y obliga a un
  servidor con timeouts, límites y despliegue — es infraestructura, no una casilla de config.
- **La desincronía de hidratación es un bug**, no un warning que se silencia: significa que servidor y
  cliente renderizaron cosas distintas (fecha, aleatorio, `localStorage`, `Date.now()`).
- Nada sensible en el payload serializado al cliente: lo que va en el HTML de SSR es público.

### Límites de error y estados de carga: requisito, no extra

- **Toda ruta tiene un límite de error** y toda carga asíncrona tiene su estado de pendiente y de fallo.
  Una pantalla en blanco ante un error de red es un defecto de producto.
- El límite de error muestra un mensaje neutro y una acción de recuperación (reintentar, volver);
  **nunca** el stack trace ni el mensaje del backend.
- Estados vacíos diseñados (lista sin resultados ≠ error ≠ cargando). Skeletons que reservan el espacio
  real, para no provocar desplazamiento al llegar los datos.
- El error se reporta al sistema de observabilidad; el usuario ve algo accionable.
- Ofensa clásica: `catch` que hace `console.error` y sigue. Un error que no se muestra ni se reporta
  no existe hasta que lo abre un cliente en un ticket.

## 4. Calidad y testing

- **Se prueba comportamiento observable, no implementación.** Testing Library con queries **por rol y
  por etiqueta accesible**; `data-testid` es último recurso. Si un test se rompe al renombrar una
  variable interna, el test estaba mal.
- Reparto por coste:
  - **Unidad (Vitest)**: lógica pura, transformaciones, esquemas de validación con casos válidos **e
    inválidos**. Rápidos y sin red.
  - **Componente (Vitest + Testing Library)**: interacción real (teclado incluido), estados de carga,
    de error y vacío. Mockea la **frontera de red**, no tus propios hooks.
  - **E2E (Playwright)**: los flujos que si se rompen cuestan dinero — auth, pago, alta, CRUD principal.
    Entre 20 y 30, no doscientos. Trazas al fallar.
- **Casos obligatorios** (no opcionales, no "cuando haya tiempo"): API que devuelve 500, red caída,
  respuesta lenta, sesión expirada a mitad de flujo, doble submit, navegación con el botón atrás durante
  una carga, lista vacía.
- Sin `sleep`/`waitForTimeout`: `findBy*`, `waitFor`, aserciones web-first. Test flaky = se arregla o se
  borra el mismo día; un flaky tolerado envenena la señal de toda la suite.
- Snapshots gigantes como única aserción: no son un test, son una foto.
- Gates de CI (los de plataforma y lenguaje los fijan las skills vecinas): typecheck → unidad y
  componente → build → E2E contra preview. Main siempre verde.

## 5. Seguridad específica de framework

- **Cada endpoint del framework es un endpoint público**: server action, server function, route handler
  o loader. Autenticación y **autorización dentro de cada uno**, verificando que el recurso pertenece al
  usuario (IDOR). El middleware no es frontera de seguridad: es enrutado.
- **Todo lo que llega al bundle es público**: variables con prefijo de exposición (`NEXT_PUBLIC_`,
  `PUBLIC_`, `VITE_`, `NUXT_PUBLIC_`) son visibles para cualquiera. Un secreto ahí es una filtración,
  no un descuido — ver `secrets-management-standards`.
- El escape por defecto del framework se respeta: `dangerouslySetInnerHTML`, `v-html`, `{@html}` y
  equivalentes solo con contenido sanitizado y revisión explícita (los sinks y la sanitización, en
  `frontend-web-platform-standards`).
- SSR con datos de usuario: no serialices al HTML nada que el usuario no deba ver (tokens, campos
  internos, objetos de sesión completos). Filtra en el servidor lo que se manda al cliente.
- Enlaces y redirecciones con destino tomado de la URL: allowlist. Un `?next=` sin validar es open
  redirect.
- **Parchear el meta-framework es operación crítica**, no mantenimiento: precedentes verificados —
  advisory de Nuxt de jul-2026 con **RCE en servidor**, y protecciones SSRF añadidas a
  `platform-server` de Angular en v22. Suscribirse a los advisories del framework elegido.
- La cadena de suministro npm y su higiene son de `frontend-web-platform-standards`; aquí la
  consecuencia: un framework arrastra cientos de transitivas y **eso forma parte del coste de elegirlo**.

## 6. Rendimiento y operabilidad

- El presupuesto de bundle y las métricas de campo son de las skills vecinas. Aquí lo que decide el
  framework: **cuánto JS se envía por ruta** y **cuánto de eso se hidrata**.
- Errores de carga de chunk tras un despliegue: los assets de la versión anterior deben seguir
  sirviéndose durante la ventana de transición, o los usuarios con la pestaña abierta rompen.
- Renderizado en servidor = servicio en producción: timeouts, límites de concurrencia, apagado
  ordenado, health checks y observabilidad. Un fallo del backend no puede tumbar el render de toda la
  página: degradación por sección (streaming + límites de error).
- Revalidación y caché del framework: **explícitas y documentadas**. Confiar en defaults implícitos que
  cambian entre majors es cómo aparecen los bugs de "por qué veo datos viejos".
- Instrumenta: errores no capturados de cliente con source maps subidos (no servidos), navegación de
  rutas, fallos de carga de datos por ruta.

## 7. Sostenibilidad, rotación del ecosistema y prohibiciones

### Elegir para que la decisión sobreviva tres años

El frontend rota más rápido que la vida útil de la aplicación. Criterios, en este orden:

1. **Gobernanza y propiedad.** ¿Quién puede cambiar la licencia o el rumbo de un día para otro?
   Fundación o gobernanza abierta > empresa única. Datos verificados a ago-2026: React pasó a la **React
   Foundation** (Linux Foundation, feb-2026); React Router adoptó **gobernanza abierta** con cadencia
   anual; **Astro fue adquirida por Cloudflare** (ene-2026); Nuxt y Svelte tienen a sus figuras
   principales **en nómina de Vercel**. Ninguno de esos hechos es descalificante por sí solo: son el
   riesgo que hay que nombrar antes de firmar, no después.
2. **Ruta de salida.** ¿Cuánto cuesta salir? Cuanto más estándar sea lo que escribes (HTML, formularios
   nativos, `fetch`, URL como estado), más barata es la salida. El acoplamiento caro no está en el
   framework: está en su modelo de datos y en su plataforma de despliegue.
3. **Contratación.** Un framework que nadie de tu mercado conoce es coste permanente de onboarding.
   Es un criterio técnico legítimo, no una excusa perezosa.
4. **Cadencia predecible.** Releases con calendario y guías de migración > releases sorpresa. Una
   cadencia anclada a algo externo y verificable (p. ej. el EOL de Node) es mejor señal que "cuando esté
   listo".
5. **Estabilidad del modelo mental.** Si el framework ha cambiado su paradigma central dos veces en tres
   años, tu código lo hará también.

**Señales de declive** (ninguna decide sola; **tres juntas sí**):
- Un major clave que lleva **más de un año en beta** sin fecha (aplica hoy a Qwik 2, en beta a ago-2026).
- El equipo principal migra su energía a un proyecto nuevo y el actual pasa a mantenimiento.
- Issues abiertos que crecen mientras los merges caen; PRs de comunidad sin respuesta durante meses.
- La documentación describe una versión que ya no es la recomendada.
- El ecosistema de librerías deja de portar: los plugins se quedan en el major anterior.
- Los blogs pasan de "cómo hacer X" a "cómo migrar fuera".
- El patrocinador único cambia de estrategia o es adquirido **y** deja de contratar en el proyecto.

### Cadencia

- Parches de seguridad del framework: **inmediatos**, con el advisory leído.
- Minors: en lote, quincenal o mensual, agrupados por Renovate.
- Majors: PR propio, changelog leído, codemod oficial si existe, y **una sola major a la vez** (React
  Router v8 exigiendo Vite 7 es el ejemplo de por qué encadenar dos migraciones sale mal).
- No adoptar un major el día de su salida. Tampoco quedarse dos majors atrás: la migración se vuelve
  irreversible y el soporte de seguridad se acaba.
- Beta o RC en producción **solo** con decisión escrita, dueño y fecha de revisión (afecta hoy a Vue 3.6,
  Solid 2, Qwik 2, SvelteKit 3, Vitest 5, TanStack Query 6 y Remix 3).

**PROHIBIDO:**
- ❌ Meter un framework (o una SPA) en un sitio de contenido o en un formulario que el HTML ya resolvía.
- ❌ Elegir framework por moda, por benchmark aislado o por lo que se llevaba en la última conferencia.
  La decisión se escribe con motivo, alternativa descartada y coste de salida.
- ❌ Un solo modelo de renderizado impuesto a todas las rutas "por coherencia".
- ❌ Fetch de datos en `useEffect` (o equivalente) cuando el framework ofrece carga a nivel de ruta;
  cascadas de peticiones en serie sin justificación.
- ❌ Duplicar el estado de servidor en un store global de cliente; Redux (o cualquier store) "por defecto".
- ❌ Estado de filtros/paginación/pestaña fuera de la URL.
- ❌ Server action / route handler / server function sin authn y **authz propias**; middleware como única
  capa de autorización.
- ❌ Secretos o datos sensibles en variables de entorno expuestas al cliente, o serializados en el HTML de SSR.
- ❌ Silenciar warnings de desincronía de hidratación en vez de arreglar su causa.
- ❌ Ruta sin límite de error; carga asíncrona sin estado de pendiente y de fallo; mostrar el error crudo
  del backend al usuario.
- ❌ Actualización optimista sin reversión implementada y probada.
- ❌ Tests acoplados a la implementación (estado interno, nombres de clase CSS, `data-testid` por comodidad),
  con `sleep`, o dependientes del orden.
- ❌ Beta/RC de framework en producción sin decisión escrita con dueño y fecha. **Remix 3 no va a producción.**
- ❌ Mezclar dos frameworks de UI en la misma aplicación por conveniencia (las islas de Astro son la
  excepción diseñada para eso; el resto es deuda con dos runtimes).
- ❌ Afirmar versiones, estado de release, licencia o gobernanza de memoria. Verificado a ago-2026: **no
  existe React 20** pese al volumen de contenido que lo anuncia.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar online (feeds Atom `https://github.com/OWNER/REPO/releases.atom` y el
registro npm — **`api.github.com` da 403 sin autenticar**; sitio oficial de cada proyecto para contrastar,
porque el feed de GitHub **no es la fuente de verdad**; `LICENSE` en crudo para licencias):

1. **Versión mayor y estado de cada framework**: React (¿sigue 19.2.x? ¿React 20 real, no de blogs SEO?),
   Vue (¿3.6 ya estable con Vapor Mode?), Svelte, Angular (v23 llega por calendario), Solid (¿2.0 salió
   de beta?), Qwik (¿Qwik 2 estable, o sigue en beta?), Astro.
2. **Meta-frameworks**: Next.js (¿16.3 estable? ¿17?), Nuxt (rama 4.x y estado de la 3.x), SvelteKit
   (¿3.0 estable?), React Router (v8.x vigente; v9 anunciada para ~may-2027), TanStack Start, Remix 3.
3. **Cambios de licencia o gobernanza** — dato caro, se verifica siempre: React Foundation, adquisición
   de Astro por Cloudflare, gobernanza abierta de React Router, quién emplea a los mantenedores clave.
   **Confirmar que ninguno ha cambiado desde ago-2026.**
4. **Advisories del framework elegido** (`github.com/advisories`, osv.dev, blog de seguridad del
   proyecto): precedentes verificados en 2026 — RCE de Nuxt (jul-2026), CVEs de RSC en React,
   compromiso de los paquetes `@tanstack/*` (CVE-2026-45321, may-2026).
5. **Herramientas de test**: Vitest (¿v5 estable?), Playwright (**Apache-2.0**, no MIT), Testing Library,
   TanStack Query (¿v6 estable?).
6. **Requisitos de plataforma** de cada major: versión mínima de Node, de Vite y ESM-only (React Router 8
   dejó de publicar CJS; Astro 7 exige Node 22.12+).

**Huecos no verificados a ago-2026** (no rellenar de memoria):
- Versión exacta y estado GA de **TanStack Start** (se documenta "v1" pero **el número de versión estable
  concreto no está verificado**; el feed del repo está dominado por betas `2.0.0-beta.x` de los paquetes
  de router).
- Fecha de salida de **Vue 3.6 estable** y de **SvelteKit 3**: **no verificada**.
- Estado de **Solid 2.0** más allá de "beta": **no verificado**.
- Cuota real de mercado y datos de contratación por framework: **no verificados** — la tabla de §2 fija
  criterio cualitativo, no cifras. Usa State of JS / encuestas del año en curso si necesitas números.
- Política de soporte y EOL por major de Next.js, Nuxt y Angular: **no verificada**. Angular publica
  ventanas LTS; comprobar la vigente antes de comprometer una versión.

**Discrepancias declaradas**:
- **React 20**: múltiples artículos de 2026 anuncian su lanzamiento con benchmarks concretos; las fuentes
  fiables lo desmienten y react.dev no lo publica. Contenido generado para SEO. **Manda react.dev.**
- **Vue 3.6 / Vapor Mode**: al menos una fuente lo da por estable en "principios de 2026"; las notas
  oficiales y los tags del repo lo sitúan en **RC** a ago-2026. **Mandan las notas oficiales.**
- **React Router v8**: la web indica 8.2.0 (jul-2026) como vigente y el registro npm devuelve **8.3.0**;
  el registro es más fresco. Comprobar antes de fijar.
- **Astro / Cloudflare**: la adquisición está confirmada por la nota de prensa de Cloudflare
  (2026-01-16); el compromiso de que Astro siga siendo open source y multi-plataforma es una
  **declaración del adquirente**, no un hecho verificable a futuro. Trátalo como riesgo a revisar.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
