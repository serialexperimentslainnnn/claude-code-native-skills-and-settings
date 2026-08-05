---
name: web-performance-standards
description: Use when browser performance must be measured and defended as a budget — Core Web Vitals LCP, INP and CLS thresholds, the web-vitals JavaScript library, Chrome UX Report (CrUX) and the CrUX API, PageSpeed Insights, real user monitoring at the 75th percentile, Lighthouse CI with lighthouserc.js and budget.json performance budgets, a performance budget that fails the build, WebPageTest and its filmstrip and waterfall, DevTools Performance panel traces, Long Animation Frames API, long tasks and main-thread blocking, Total Blocking Time, Speed Index, Time to First Byte, JavaScript bundle cost and hydration cost, layout shift attribution and sources, content-visibility, requestIdleCallback and scheduler.yield, third-party script cost, or justifying performance work with conversion and bounce-rate data.
---

# Estándares de rendimiento web

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la experiencia medida en el navegador de un usuario real**: qué métrica se recoge,
con qué umbral, en qué percentil, quién decide con ella y qué gate rompe el build cuando se
supera el presupuesto. Cubre presupuestos de rendimiento, Core Web Vitals, medición de campo
y de laboratorio, coste de JavaScript, estabilidad visual, trabajo en el hilo principal y la
justificación de negocio del trabajo de rendimiento.

Triggers: Core Web Vitals, LCP, INP, CLS, FID (retirada), TTFB, FCP, TBT, Speed Index,
`web-vitals`, `onLCP`/`onINP`/`onCLS`, CrUX y la CrUX API, PageSpeed Insights, Search Console
(informe de Métricas web principales), Lighthouse, Lighthouse CI, `lighthouserc.js`,
`budget.json`, `assertions`, WebPageTest, panel *Performance* de DevTools, *Long Animation
Frames* (LoAF), `PerformanceObserver`, `longtask`, `layout-shift`, `element` timing,
`scheduler.yield()`, `requestIdleCallback`, `content-visibility`, `contain-intrinsic-size`,
presupuesto de peso de JS, número de peticiones, coste de hidratación, coste de *script* de
terceros, percentil 75, p75/p95, RUM.

**Tesis de la skill**: **el rendimiento es un presupuesto que se acuerda y se defiende en CI,
no una optimización posterior.** Sin un número acordado por escrito, cualquier regresión es
negociable y todas se aprueban una a una hasta que el sitio es lento. Con presupuesto, la
conversación deja de ser estética ("va un poco lento") y pasa a ser binaria: **se pasa o
rompe el build**. Corolario: **el laboratorio no decide** (§2.3). Decide el campo, en el
percentil 75, sobre dispositivos reales. Segundo corolario: **una puntuación no es una
experiencia** — perseguir el 100 de Lighthouse es sustituir el objetivo por su indicador.

**No aplica**: ver `frontend-web-platform-standards` (**el mecanismo de plataforma es suyo**:
`preload`/`preconnect`/`fetchpriority`, `defer`/`async`, `font-display` y *subsetting*,
`srcset`/`<picture>`/AVIF/`loading="lazy"`, `content-visibility` como característica CSS, la
elección de *bundler* y su configuración, y los límites de tamaño de *bundle* que impone el
build. **Aquí el presupuesto que esos mecanismos deben cumplir y la medición que demuestra
que lo cumplen** — qué `preload` poner es suyo, **si ha mejorado el LCP en p75 de campo es de
aquí**), `frontend-frameworks-standards` (el framework, el modelo de renderizado — CSR/SSR/
islas/RSC — y el enrutado son suyos; **aquí sus consecuencias medibles**: la hidratación como
coste en el hilo principal y su efecto en INP, el coste de una navegación de cliente),
`accessibility-standards` (**skill hermana**: se cruzan en `prefers-reduced-motion` — allí
criterio de conformidad, aquí ahorro de renderizado — y en la percepción de velocidad; los
criterios WCAG y la conformidad legal son suyos), `caching-cdn-standards` (**la caché HTTP,
el CDN y la purga son suyos**: `Cache-Control`, `s-maxage`, `stale-while-revalidate`, claves
de caché, *origin shield*, `Cache-Status`. **Aquí solo el efecto medido en el cliente**: un
`Cache-Status: hit` que no mueve el TTFB en p75 de campo no ha mejorado nada),
`observability-standards` (la plataforma de telemetría: recolectores, almacenamiento,
retención, muestreo, tableros y alertas. **Aquí qué métrica de usuario real se recoge y con
qué percentil se decide**), `sre-practice-standards` (**frontera importante**: SLO,
*error budget*, fiabilidad y disponibilidad del **servicio en producción** son suyos —
latencia de servidor incluida. **Aquí la experiencia percibida en el navegador**: el servidor
puede cumplir su SLO de p99 y el usuario seguir viendo una página en blanco a los 4 s por
culpa del JavaScript. Dos números, dos dueños, sin colisión),
`performance-engineering-standards` (**metodología general de perfilado y optimización de
*backend* y sistemas**: USE/RED, *flame graphs*, perfilado de CPU y memoria, análisis de
cuellos de botella en servidor, base de datos y sistema operativo. **Aquí solo el navegador y
el usuario real**. La frontera exacta: **el TTFB es el punto de contacto** — cómo se reduce
el tiempo de respuesta del servidor es suyo; **que ese TTFB entra en el LCP y cuánto pesa en
el p75 de campo es de aquí**), `testing-qa-standards` (los guiones de carga y estrés — k6,
Gatling, Locust, JMeter — y la estrategia de test son suyos; aquí la medición en navegador),
`api-design-standards` (el contrato y la paginación; aquí el coste medido de una respuesta
sobredimensionada) y `cicd-standards` (la *pipeline*; **aquí qué gate ponerle**, §4),
`design-systems-standards` (**el contrato del componente y el gobierno del sistema son suyos**;
aquí **el peso que ese sistema añade al bundle y el coste de sus dependencias** — un sistema de
diseño es una de las mayores fuentes de JavaScript no usado, y el presupuesto se defiende aquí),
`cms-jamstack-standards` (el CMS y su modelado son suyos; aquí **el coste medido de sus imágenes y
de sus scripts de terceros**, que suele dominar el LCP de un sitio de contenido),
`webgl-webgpu-standards` (**Ola 6** — **son dos presupuestos distintos y no se mezclan**: aquí las
Core Web Vitals y el presupuesto de carga; allí **el presupuesto de fotograma y el coste de GPU**.
Un canvas puede ir a 60 fps y arruinar el INP de la página, o al revés: ninguna de las dos métricas
predice a la otra), `pwa-standards` (**Ola 6**: la caché del *service worker* cambia radicalmente
las métricas de visita repetida — **medir solo la primera visita oculta lo que hace una PWA**, y
una caché mal configurada sirve rápido una versión vieja, que no es una mejora).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.1 Core Web Vitals vigentes y sus umbrales (verbatim)

**Son tres, y las tres están en estado *Stable***. web.dev, verbatim: *"The Core Web Vitals
are at the following lifecycle stages: LCP : Stable CLS : Stable INP : Stable"*.

| Métrica | Mide | Bueno | Malo |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | Carga | ≤2500 ms | >4000 ms |
| **INP** (Interaction to Next Paint) | Interactividad | ≤200 ms | >500 ms |
| **CLS** (Cumulative Layout Shift) | Estabilidad visual | ≤0,1 | >0,25 |

Verbatim de web.dev, sin reformular:

> *"Largest Contentful Paint (LCP): measures loading performance. To provide a good user
> experience, LCP should occur within 2.5 seconds of when the page first starts loading.
> Interaction to Next Paint (INP): measures interactivity. To provide a good user experience,
> pages should have a INP of 200 milliseconds or less. Cumulative Layout Shift (CLS):
> measures visual stability. To provide a good user experience, pages should maintain a CLS
> of 0.1. or less."*

> *"To ensure you're hitting the recommended target for these metrics for most of your users,
> a good threshold to measure is the 75th percentile of page loads, segmented across mobile
> and desktop devices. Tools that assess Core Web Vitals compliance should consider a page
> passing if it meets the recommended targets at the 75th percentile for all three of the
> Core Web Vitals metrics."*

Umbrales "poor" verbatim: INP — *"An INP above 500 milliseconds means a page has poor
responsiveness."* CLS — *"Good CLS values are 0.1 or less. Poor values are greater than
0.25."* LCP — la tabla de *Defining the Core Web Vitals metrics thresholds* da **≤2500 ms**
(bueno) y **>4000 ms** (malo).

**FID está retirada.** web.dev, verbatim: *"A stable metric can be retired and replaced by
another metric that addresses the problem area more effectively. This is exactly what
happened to FID as INP became a stable Core Web Vital metric in 2024."* **Cualquier guía,
tablero o alerta que siga midiendo FID está caducada** — y hay muchas. INP no es "FID mejor":
FID solo medía el retraso de entrada de la **primera** interacción; INP mide **todo el ciclo
hasta el siguiente pintado** en **todas** las interacciones de la vida de la página, y es la
métrica que más se incumple.

**Estabilidad del conjunto**: verbatim de web.dev, *"Stable Core Web Vitals metrics won't
change more than once per year. Any change to a Core Web Vital will be clearly communicated
in the metric's official documentation, as well as in the metric's changelog."* **A ago-2026
no consta ninguna métrica nueva anunciada ni cambio de umbral** — pero es exactamente el dato
que caduca (§8): comprobar el ciclo de vida (*experimental* / *pending* / *stable*) antes de
fijar nada.

**Métricas de apoyo, que NO son Core Web Vitals** y no se usan como objetivo: TTFB y FCP
(diagnostican LCP: respuesta lenta del servidor y recursos que bloquean el renderizado,
respectivamente) y **TBT**, que web.dev describe como métrica **de laboratorio** útil para
detectar problemas de interactividad que afectan a INP. Se usan **para diagnosticar**, nunca
para declarar éxito.

### 2.2 Herramientas

| Uso | Por defecto | Versión / licencia verificada | Nota |
|---|---|---|---|
| RUM en producción | **`web-vitals`** | 6.0.1 — Apache-2.0 | `onLCP`/`onINP`/`onCLS` + *attribution build* para saber **qué elemento** |
| Campo agregado público | **CrUX / CrUX API** y PageSpeed Insights | Servicio de Google | Ventana móvil de 28 días, p75 |
| Laboratorio reproducible | **Lighthouse** | 13.4.1 — Apache-2.0 | Solo diagnóstico y comparación relativa |
| Gate en CI | **Lighthouse CI** (`@lhci/cli`) | 0.15.1 — Apache-2.0 | Repo activo; último *push* verificado 27-mar-2026 |
| Análisis profundo de carga | **WebPageTest** | ⚠ **PolyForm Shield License 1.0.0** | **No es software libre** (§2.4) |
| Perfilado de hilo principal | DevTools *Performance* + LoAF | Navegador | Lo que explica un INP malo |

### 2.3 Campo vs. laboratorio: **el laboratorio no decide**

| | Campo (RUM, CrUX) | Laboratorio (Lighthouse, WebPageTest) |
|---|---|---|
| Qué es | Lo que le pasó a usuarios reales | Una simulación en condiciones fijas |
| Para qué sirve | **Decidir**: cumplir o no cumplir | **Diagnosticar**: por qué y qué arreglar |
| INP | Se mide (necesita interacción real) | **No se mide** — no hay usuario que interactúe |
| Variabilidad | Dispositivo, red, ubicación, caché, ruta | Controlada, reproducible |

**Reglas duras**:
- **Una métrica de laboratorio nunca cierra un debate sobre si el sitio es rápido.** Cierra el
  debate sobre qué recurso bloquea el renderizado.
- **INP no existe en laboratorio.** Lighthouse da **TBT** como aproximación; TBT y INP
  correlacionan mal. Quien afirme "hemos mejorado INP" enseñando un Lighthouse, no lo ha
  medido.
- **El laboratorio simula un dispositivo; el campo tiene el dispositivo.** Si el laboratorio
  no emula CPU lenta y red móvil, mide un mundo que no existe (§6.1).
- La divergencia entre CrUX y el RUM propio es **normal y esperada** (poblaciones, muestreo y
  ventanas distintas). **No se "arregla": se explica.** Se decide con **una** de las dos,
  declarada de antemano.

### 2.4 Estado y licencias — dos avisos verificados

- **WebPageTest no es open source.** Su `LICENSE.md` en crudo dice: *"Licensed under the
  PolyForm Shield License 1.0.0"* (Catchpoint Systems Inc.). PolyForm Shield es
  **source-available con cláusula anti-competencia**, no una licencia libre. Además, el repo
  `catchpoint/WebPageTest` tenía su último *push* el **19-sep-2025** — casi un año sin
  actividad a ago-2026. **Criterio**: usarlo como servicio de diagnóstico, sí; **no** fijarlo
  como dependencia auto-hospedada de una *pipeline* sin pasar por revisión legal, y **no**
  asumir que es BSD/Apache como se repite por ahí.
- `lighthouse`, `@lhci/cli` y `web-vitals` son **Apache-2.0**, verificado en sus `LICENSE` en
  crudo y en el campo `license` de npm. `lighthouse-ci` **no está archivado** y sigue
  recibiendo cambios, pero **acumula 230 issues abiertas**: no está muerto, tampoco atendido
  con holgura. Verificar antes de apostar la *pipeline* entera a él (§8).

## 3. El presupuesto de rendimiento

**Sin presupuesto no hay skill que valga.** El presupuesto es un fichero versionado, revisado
en PR, con **dueño**. Tres capas, y las tres se declaran:

### 3.1 Capa 1 — objetivos de campo (los que deciden)

Se expresan **siempre** como *métrica + percentil + segmento + ventana*:

```
LCP p75 móvil (28 d, CrUX)   ≤ 2500 ms
INP p75 móvil (28 d, CrUX)   ≤ 200 ms
CLS p75 móvil (28 d, CrUX)   ≤ 0.1
```

**Móvil es el segmento que manda**, salvo que el producto sea de escritorio por definición
(herramienta interna, panel de operaciones). Escritorio se mide igual pero no es el objetivo
que se defiende.

**El percentil 75 no es negociable y la media está prohibida** (§7). Razón: la distribución de
tiempos de carga tiene **cola larga**. La media la aplasta el grueso de sesiones rápidas
—dispositivos buenos, red buena, caché caliente— y **oculta exactamente a los usuarios que se
van**. Con p75 se afirma algo comprobable: *"3 de cada 4 sesiones están por debajo de este
número"*. La mediana (p50) miente por lo mismo con más disimulo. Si además el producto es
crítico, seguir p95 como métrica secundaria de cola.

### 3.2 Capa 2 — presupuesto de recursos (el que rompe el build)

Los objetivos de campo tardan 28 días en moverse; **no sirven como gate de PR**. El gate es
un presupuesto de recursos en laboratorio, que sí es determinista. Se declara en
`budget.json` (formato de Lighthouse) o en las aserciones de `lighthouserc.js`:

```json
[{
  "path": "/*",
  "resourceSizes": [
    { "resourceType": "script",     "budget": 170 },
    { "resourceType": "stylesheet", "budget": 60  },
    { "resourceType": "font",       "budget": 100 },
    { "resourceType": "image",      "budget": 300 },
    { "resourceType": "total",      "budget": 700 }
  ],
  "resourceCounts": [
    { "resourceType": "third-party", "budget": 10 },
    { "resourceType": "total",       "budget": 50 }
  ],
  "timings": [
    { "metric": "largest-contentful-paint", "budget": 2500 },
    { "metric": "total-blocking-time",      "budget": 200  },
    { "metric": "cumulative-layout-shift",  "budget": 0.1  }
  ]
}]
```

**Los números anteriores son una plantilla, no una verdad.** Cómo se fijan de verdad, en
orden:
1. **Medir el estado actual** en campo, p75 móvil. Sin línea base no hay presupuesto.
2. **Medir a los competidores** con los que compite el usuario, en laboratorio comparable.
3. Fijar el presupuesto **por debajo del estado actual** (o por debajo del mejor competidor
   si ya se cumple), y **nunca subirlo sin decisión explícita y firmada**.
4. Presupuesto **por ruta**, no global: la portada, la ficha de producto y el proceso de pago
   tienen presupuestos distintos porque tienen valor distinto.

**El presupuesto de JS es el que importa.** Referencia de la realidad, no de la aspiración:
el **Web Almanac 2025** (capítulo *Page Weight*, HTTP Archive) da una portada mediana móvil de
**2.362 KB**, de los cuales **632 KB de JavaScript**, 911 KB de imágenes, 122 KB de fuentes,
77 KB de CSS y 22 KB de HTML. **Discrepancia declarada**: algunas reseñas de la misma edición
citan **697 KB** de JavaScript — probablemente escritorio, o de un capítulo distinto; el
capítulo *JavaScript* de 2025 devolvía 404 en la verificación. **Usar la cifra propia medida,
no la del almanaque**: el almanaque sirve para saber que el sector está mal, no para copiarle
el presupuesto.

### 3.3 Capa 3 — regla de no regresión

Además del umbral absoluto, **prohibir el empeoramiento**: cualquier PR que aumente el peso
de JS de una ruta por encima de un delta acordado (p. ej. +5 KB comprimido) requiere
aprobación explícita, con motivo escrito. Es lo que evita la muerte por mil recortes: **nadie
añade 400 KB de golpe; se añaden en cuarenta PR de 10 KB que todos parecían razonables.**

## 4. Gates de CI

En orden de coste creciente. **El presupuesto que no rompe el build es una sugerencia.**

1. **Tamaño de *bundle* en el build** (`size-limit`, `bundlesize` o el límite del propio
   *bundler*): sobre el artefacto, en segundos. La herramienta concreta es de
   `frontend-web-platform-standards`; **el número que debe cumplir es de aquí**.
2. **Lighthouse CI con `assertions`** contra `budget.json`, sobre las 3-5 rutas de mayor
   valor. Ejecutar **N≥3 pasadas y tomar la mediana**: una sola pasada de Lighthouse tiene
   ruido suficiente para hacer el gate inestable, y **un gate inestable se desactiva a la
   semana**.
3. **Aserción de no regresión** contra la rama principal (§3.3).
4. **Comprobación de campo en el despliegue**: tras publicar, vigilar LCP/INP/CLS de RUM
   propio en ventana corta (horas, no 28 días) para detectar una regresión grave antes de que
   entre en CrUX.

**Requisitos del gate para que sobreviva**:
- **Determinista**: entorno fijo, versión de Chrome fija, red y CPU emuladas con los mismos
  factores en cada pasada.
- **Con dueño**: si nadie es responsable de arreglarlo, se saltará con `--no-verify`.
- **Con vía de excepción registrada**: la excepción se documenta en el PR con motivo y fecha
  de caducidad. **Excepciones silenciosas, no.**

## 5. Seguridad y coste de terceros

- **Cada *script* de terceros es una dependencia de rendimiento y de seguridad a la vez.**
  Ninguno entra sin: propietario nombrado, medición de su coste (bytes + tiempo de hilo
  principal), fecha de revisión y **plan de retirada**. Un gestor de etiquetas es una puerta
  abierta por la que entra código sin PR: **el contenido del gestor de etiquetas también
  entra en el presupuesto** y se audita con la misma cadencia.
- **`async`/`defer` reduce el bloqueo de análisis, no el coste de CPU.** El *script* de
  terceros sigue compitiendo por el hilo principal cuando se ejecuta, y ahí es donde estropea
  el INP.
- **RUM y privacidad**: los datos de `web-vitals` que se envían a un *endpoint* propio pueden
  llevar URL con parámetros identificativos y selectores del DOM (en la *attribution build*).
  Sanear antes de enviar; ver `privacy-engineering-standards`. Muestrear no exime de
  minimizar.
- Endurecimiento de terceros (SRI, CSP, `Permissions-Policy`) es de
  `frontend-web-platform-standards`; **aquí solo su coste medido**.

## 6. Dónde está el tiempo, de verdad

### 6.1 El coste de JavaScript domina, y manda la CPU del dispositivo

**La red se puede comprar; la CPU del usuario, no.** Un byte de imagen se descarga y se
pinta. Un byte de JavaScript se descarga, **se analiza, se compila, se ejecuta**, reserva
memoria y provoca recolección de basura — y todo eso ocurre **en el hilo principal**, en un
teléfono de gama media que puede ser 4-6 veces más lento que el portátil de quien lo escribió.
Consecuencias operativas:

- **Medir siempre con emulación de CPU lenta** (*throttling* ≥4×) y red móvil. Medir en el
  portátil del equipo con fibra es medir un usuario que no existe.
- **Tener un dispositivo de gama media real** para probar. Es la herramienta de rendimiento
  más barata y la que más cambia decisiones.
- **INP se arregla en el hilo principal, no en la red.** Tareas largas (>50 ms) troceadas,
  ceder al hilo con `scheduler.yield()` donde esté disponible (o `setTimeout(0)` /
  `requestIdleCallback` como alternativa), trabajo pesado a *Web Worker*, y **pintar la
  respuesta antes de hacer el trabajo caro** (el usuario mide hasta el siguiente pintado, no
  hasta que el cálculo acaba).
- **Diagnóstico de INP**: *Long Animation Frames* (LoAF) vía `PerformanceObserver`, y la
  *attribution build* de `web-vitals`, que dice **qué elemento y qué script**. Sin
  atribución, optimizar INP es adivinar.
- **La hidratación es coste de CPU pura** y suele ser el pico que estropea INP en el primer
  segundo. El modelo de renderizado que la genera es de `frontend-frameworks-standards`;
  **aquí el número que produce**: cuánto tiempo de hilo principal cuesta y cuánto sube el TBT.

### 6.2 Estabilidad visual (CLS) — las causas, no los síntomas

Cinco causas cubren casi todo:
1. **Imágenes y vídeos sin dimensiones** (`width`/`height` o `aspect-ratio`) → el hueco no se
   reserva.
2. **Fuentes web** que cambian de métricas al cargar (FOUT/FOIT) → reservar con métricas de
   sustitución.
3. **Contenido inyectado sobre lo ya pintado**: banners, avisos de cookies, anuncios,
   *toasts*. Si debe aparecer, **reservar el espacio desde el primer pintado**.
4. **Contenido cargado tarde que empuja** (recomendaciones, *widgets*): reservar altura
   mínima con `contain-intrinsic-size`.
5. **Animaciones sobre propiedades que provocan *layout*** (`top`, `left`, `width`, `height`)
   en vez de `transform`/`opacity`.

**Regla**: un desplazamiento provocado por una acción del usuario en los 500 ms siguientes no
cuenta para CLS. **Todo lo demás sí.** Y CLS se acumula durante **toda la vida de la página**:
un desplazamiento en el pie a los 30 s de *scroll* cuenta igual que uno al cargar.

### 6.3 Renderizado y hilo principal

- **Tarea larga = >50 ms.** Se miden con `PerformanceObserver` (`longtask`) y con LoAF.
- **`content-visibility: auto` + `contain-intrinsic-size`** para secciones largas fuera de
  pantalla: evita el coste de *layout* y pintado de lo que no se ve. Ojo: mal dimensionado
  **provoca CLS** — se paga con la otra métrica. La característica CSS es de
  `frontend-web-platform-standards`; **la decisión de usarla y la medición del intercambio
  son de aquí**.
- **Listas largas**: virtualizar por encima de unos cientos de filas. El umbral se mide, no se
  supone.
- **No animar propiedades que provocan *layout*.** `transform` y `opacity` van en el
  compositor.

### 6.4 Imágenes, fuentes y pistas de carga — solo el criterio

Los mecanismos (`srcset`, `<picture>`, AVIF/WebP, `loading="lazy"`, `font-display`,
*subsetting*, `preload`, `preconnect`, `fetchpriority`) son de
`frontend-web-platform-standards`. **Aquí lo que decide un presupuesto**:

- **La imagen LCP nunca es `loading="lazy"`.** Es el error de una línea que más LCP arruina.
  Se marca con `fetchpriority="high"` y, si se descubre tarde, se le hace `preload`.
- **`preload` es un recurso escaso**: cada `preload` compite con los demás. Más de 2-3
  recursos precargados suele empeorar en vez de mejorar. **Se mide antes y después, siempre.**
- **`preconnect` solo a orígenes críticos** (2-4 como mucho): cada uno cuesta una conexión que
  puede no usarse.
- **Fuentes**: presupuesto explícito de peso y de número de familias/variantes. Cada variante
  es una petición y un riesgo de CLS. `font-display: swap` intercambia FOIT por CLS —
  intercambio que se decide con datos, no por costumbre.
- **Imágenes**: formato moderno, dimensiones correctas para el hueco real y `srcset` por
  densidad y anchura. Una imagen servida a 3× de su tamaño de presentación es peso puro.

### 6.5 Caché y servidor, vistos desde el cliente

- El **TTFB** es el suelo del LCP: no hay LCP de 2,5 s con un TTFB de 2 s. La optimización del
  servidor es de `performance-engineering-standards`; **el criterio de aquí es que el TTFB
  entra en el presupuesto de LCP y se mide en campo, no en el log del servidor**.
- **La caché no se mide por *hit ratio* sino por su efecto en el usuario**: la métrica de aquí
  es el LCP p75 de las visitas repetidas frente a las primeras visitas. La política de caché,
  la purga y el CDN son de `caching-cdn-standards`.
- **Segmentar el campo por primera visita vs. repetida.** Un p75 global bonito puede esconder
  una primera visita desastrosa; y la primera visita es la que convierte.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisar por web el conjunto de Core Web Vitals y sus umbrales **cada
  trimestre** (§8). Revisar el presupuesto **cada vez que cambie el estado del arte o el
  competidor**, y como mínimo una vez al año — un presupuesto que nunca se revisa acaba
  siendo o inalcanzable o irrelevante.
- **El presupuesto se sube solo con decisión explícita**, escrita, con motivo y con quién la
  aprueba. Subirlo "para desbloquear el release" sin registro es cómo mueren todos los
  presupuestos.
- **Relación con el negocio**: el trabajo de rendimiento se justifica con **datos propios**,
  no con estadísticas de terceros. Método: correlacionar el LCP/INP p75 por segmento con tasa
  de conversión, tasa de rebote y valor medio de pedido **del propio sitio**, y —cuando se
  pueda— **medirlo con un experimento A/B** en el que la única variable sea el rendimiento.
  El estudio clásico (Deloitte, *Milliseconds Make Millions*, ~30 M de sesiones en 37 marcas)
  reporta que una mejora de 0,1 s se asocia a **+8,4 % de conversiones en retail** y **+10,1 %
  en viajes**, con **+9,2 % de valor medio de pedido en retail**. **Caveat que casi nadie
  cita**: esa "mejora de 0,1 s" era un compuesto de **First Meaningful Paint, Estimated Input
  Latency y Observed Load**, métricas hoy **retiradas**; y es un estudio observacional, no un
  experimento. Sirve para abrir la conversación; **no** sirve como promesa de retorno.

Prohibiciones explícitas:

- ❌ **Optimizar sin medir antes.** Sin línea base no hay mejora, hay opinión. Toda tarea de
  rendimiento empieza con la métrica actual y el objetivo, escritos.
- ❌ **Decidir con datos de laboratorio solamente.** El laboratorio diagnostica; **el campo
  decide** (§2.3). En particular: **no existe INP de laboratorio**.
- ❌ **Perseguir la puntuación de Lighthouse** en vez de la experiencia real. Un 100 con LCP
  p75 de 4 s en campo es un 100 inútil. La puntuación es un indicador; convertirla en objetivo
  es la ley de Goodhart aplicada al frontend.
- ❌ **Decidir con la media (o con la mediana) en vez del percentil 75.** La media oculta a
  quien se va (§3.1).
- ❌ **Cargar una librería completa para usar una función.** Antes: ¿lo hace la plataforma?
  ¿existe una alternativa de un orden de magnitud menos? ¿se puede importar solo esa parte con
  *tree-shaking* real (y comprobarlo en el artefacto, no en la teoría)?
- ❌ **`loading="lazy"` en la imagen del LCP** o en cualquier imagen sobre la línea de flotación.
- ❌ **Añadir un *script* de terceros sin dueño, sin medición y sin plan de retirada** (§5).
- ❌ **Presupuesto que no rompe el build.** Un aviso en la consola de CI no es un presupuesto.
- ❌ **Gate de rendimiento con una sola pasada de Lighthouse**: el ruido lo vuelve inestable y
  un gate inestable acaba desactivado.
- ❌ **Medir el rendimiento solo en el equipo de desarrollo** (portátil potente, fibra, caché
  caliente). Emulación de CPU y red, o dispositivo real (§6.1).
- ❌ **Seguir midiendo FID** o mantener tableros y alertas basados en ella (§2.1).
- ❌ **Tratar el rendimiento como una fase final** ("lo optimizamos antes de salir"). Para
  entonces la decisión que lo estropeó —el framework, el modelo de renderizado, los seis
  *scripts* de marketing— ya no se puede revertir sin rehacer.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un proyecto real:

1. **Core Web Vitals**: `web.dev/articles/vitals` — **cuáles son las métricas hoy, en qué
   estado del ciclo de vida (*experimental* / *pending* / *stable*) y con qué umbrales**.
   Copiar los umbrales **verbatim** desde `web.dev/articles/lcp`, `/inp`, `/cls` y
   `/defining-core-web-vitals-thresholds`: un resumidor automático que redondee un número
   cambia si algo cumple o no. Verificar además si hay alguna métrica nueva anunciada — la
   propia página advierte que una métrica estable puede retirarse y ser sustituida.
2. **Percentil y ventana**: confirmar que sigue siendo **p75** y la ventana de CrUX (28 días
   móviles) antes de escribir un objetivo.
3. **`web-vitals`**: versión y API vigente (verificado 6.0.1, Apache-2.0). Comprobar si la
   *attribution build* ha cambiado de forma de importarse.
4. **Lighthouse / Lighthouse CI**: versiones (verificado `lighthouse` 13.4.1, `@lhci/cli`
   0.15.1, ambos Apache-2.0), formato vigente de `lighthouserc.js` y `budget.json`, y **estado
   real del repositorio** — `lighthouse-ci` no está archivado (último *push* verificado:
   27-mar-2026) pero acumula 230 issues abiertas. Recordar que **el feed de releases de GitHub
   no es la fuente de verdad de un proyecto**: contrastar con su web oficial antes de dar por
   muerto o por vivo cualquiera de ellos.
5. **WebPageTest — comprobación de licencia obligatoria**: leer `LICENSE.md` **en crudo**.
   Verificado a ago-2026: **PolyForm Shield License 1.0.0**, source-available con cláusula
   anti-competencia, **no** software libre; y el repo llevaba sin *push* desde el
   **19-sep-2025**. Si se va a auto-hospedar o integrar en un producto, pasa por revisión
   legal.
6. **Datos del sector**: Web Almanac / HTTP Archive publican edición nueva cada año.
   **Discrepancia declarada y sin resolver**: el capítulo *Page Weight* de 2025 da **632 KB**
   de JavaScript en la portada mediana móvil, mientras reseñas de la misma edición citan
   **697 KB**; el capítulo *JavaScript* de 2025 devolvía **404** en la verificación. Comprobar
   la edición vigente y el capítulo exacto antes de citar cualquier cifra.
7. **Hueco declarado**: no se ha verificado en fuente primaria ninguna cifra de porcentaje de
   sitios que aprueban los tres CWV (circulan 43 % de fallo de INP y 48 % de aprobado en
   móvil, todas de fuentes secundarias). **No usar sin comprobar en CrUX / el informe público
   de Chrome.**
8. **Hueco declarado**: el estudio de Deloitte citado en §7 no se ha leído en su PDF original
   en esta verificación; las cifras (+8,4 % / +10,1 % / +9,2 %) y el caveat de las métricas
   compuestas proceden de resúmenes. **Contrastar con el informe antes de usarlo ante
   negocio.**
9. **APIs de diagnóstico**: estado y disponibilidad de *Long Animation Frames*,
   `scheduler.yield()` y `content-visibility` en los navegadores objetivo — el soporte se
   consulta en `frontend-web-platform-standards`, no se supone aquí.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
