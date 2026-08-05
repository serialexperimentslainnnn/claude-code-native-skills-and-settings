---
name: webgl-webgpu-standards
description: Use when the browser drives the GPU - <canvas> with getContext("webgl2") or getContext("webgpu"), navigator.gpu and requestAdapter/requestDevice, GPUDevice, GPUBuffer, GPURenderPipeline, GPUComputePipeline, GPUBindGroup, .wgsl shaders and WGSL compilation errors, GLSL ES 300 vertex/fragment shaders, three.js and three/webgpu WebGPURenderer with TSL node materials, Babylon.js WebGPUEngine, PixiJS, regl or raw WebGL2, glTF/GLB assets and KHR_texture_basisu, .ktx2 and Basis Universal transcoders, draw calls and instancing with drawElementsInstanced or drawIndexed, frame budget and requestAnimationFrame jank on a canvas, texture memory and GPU out-of-memory, webglcontextlost/webglcontextrestored and GPUDevice.lost, timestamp-query GPU profiling, compute shaders in the browser, OffscreenCanvas in a worker, WebGL2 fallback and navigator.gpu feature detection, or making a canvas accessible.
---

# Estándares de gráficos y cómputo GPU en el navegador (WebGL2 / WebGPU)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio sobre **el uso de la GPU desde el navegador**: cuándo se justifica un canvas acelerado,
qué API se elige, cómo se degrada, qué presupuesto tiene un fotograma, qué se mide y con qué, y qué
riesgos añade.

**Eje: la decisión más importante es si hace falta.** WebGL/WebGPU trae un coste permanente —
degradación obligatoria, pérdida de contexto, memoria de GPU, batería, accesibilidad rota por defecto,
perfilado que casi nadie del equipo sabe leer. Ese coste se paga solo cuando el problema es realmente
de GPU: escenas 3D, mapas con muchísimas entidades, decenas o cientos de miles de puntos por fotograma,
procesamiento de imagen o vídeo en tiempo real, simulación, o inferencia en cliente.

**Cuándo NO**: un gráfico de datos **no necesita WebGL**. Barras, líneas, áreas, tartas, dispersión con
unos miles de puntos: **SVG** (accesible, inspeccionable, imprimible, seleccionable) o **Canvas 2D**
(cuando el número de elementos rompe el DOM). Un canvas WebGL para un dashboard es complejidad
accidental: pierdes accesibilidad, SEO y depuración a cambio de fotogramas que nadie necesita. El umbral
razonable para saltar a GPU es "Canvas 2D ya no llega, **medido**", no "va a quedar más moderno".

Triggers: `getContext('webgl2'|'webgpu')`, `navigator.gpu`, `requestAdapter`/`requestDevice`, ficheros
`.wgsl`, shaders GLSL ES 300, `three`/`three/webgpu`, `@babylonjs/core`, `.ktx2`, glTF con
`KHR_texture_basisu`, `webglcontextlost`, `device.lost`, `timestamp-query`, `OffscreenCanvas`, y el
síntoma clásico: "en móvil se ve bien un rato y luego se queda en negro".

**No aplica**:
- `frontend-web-platform-standards` (**ya escrita**) — **HTML, CSS, las APIs generales del navegador, el
  modelo de carga, la CSP y la herramienta de build son suyos**. Aquí solo el canvas y la GPU: qué se
  dibuja dentro y cuánto cuesta.
- `frontend-frameworks-standards` (**ya escrita**) — **el framework y su modelo de renderizado** son
  suyos; aquí el bucle de render del canvas, que **no** es el ciclo de render del framework y **no** debe
  estar acoplado a él (un canvas que se re-monta en cada render de componente pierde el contexto GPU).
- `web-performance-standards` (**ya escrita**) — **Core Web Vitals, los presupuestos de la página y su
  medición son suyos** (LCP, INP, CLS, peso del bundle). **Aquí el presupuesto de *fotograma* y el coste
  de GPU, que son otra métrica y otro cuello de botella**: una app puede tener CWV perfectos y 12 fps
  dentro del canvas, y puede tener 120 fps y un LCP desastroso. No compiten: se miden aparte. El peso de
  los *assets* 3D (modelos, texturas) sí entra en el presupuesto de bytes de la página → allí.
- `accessibility-standards` (**ya escrita**) — **el criterio de conformidad WCAG es suyo**. Aquí su
  consecuencia técnica: **un canvas es opaco para la tecnología asistiva** (es un mapa de píxeles, no
  contiene semántica), luego exige alternativa equivalente; y `prefers-reduced-motion` como interruptor
  real de la animación.
- `gpu-computing-standards` — **la GPU del servidor, su driver, su reparto (MIG, time-slicing), su
  planificación y su coste son suyos**. **Aquí la GPU del cliente vista desde el navegador**: no eliges
  el hardware, no ves el driver y el usuario puede tener cualquier cosa.
- `local-inference-standards` — si el caso es **ejecutar un modelo**, la elección de modelo,
  cuantización, formato y evaluación es suya. **Aquí solo el sustrato de cómputo** (WebGPU compute,
  límites del dispositivo, memoria).
- `webassembly-standards` (**ya escrita**) — **el módulo Wasm y su runtime son suyos**; es frecuente en
  este dominio (transcodificadores KTX2/Basis, físicas, motores portados). Aquí solo su interacción con
  la GPU y con el presupuesto de fotograma.
- `pwa-standards` — service worker, instalación y offline. Una PWA puede contener un canvas WebGPU: son
  capas distintas. La caché de assets 3D pesados es de allí; su formato y su coste en GPU, de aquí.
- `caching-cdn-standards` (entrega de modelos y texturas, rangos y compresión en tránsito),
  `object-storage-standards` (dónde viven los assets), `appsec-standards` (metodología; aquí los
  controles concretos), `privacy-engineering-standards` (**fingerprinting por GPU**: el criterio legal y
  de consentimiento es suyo), `observability-standards` (plataforma de telemetría; aquí qué métricas de
  GPU emitir), `mobile-standards` (app nativa con motor propio), `i18n-standards`.

## 2. Decisiones por defecto

> Verificar la última versión y el estado de soporte por web antes de fijarlos en un proyecto real (§8).

### Elección de API

Estado verificado a ago-2026 (`webstatus.dev` + MDN/BCD; **cítalo verbatim, no de memoria**):

| API | Estado | Detalle |
|---|---|---|
| **WebGL2** | **Baseline widely available** — `newly` 2021-09-20, `widely` 2024-03-20 | Chrome 56, Chrome Android 58, Edge 79, Firefox 51, Safari 15 / iOS 15 |
| **WebGPU** | **Baseline limited.** MDN, verbatim: *"This feature is not Baseline because it does not work in some of the most widely-used browsers."* | Ver desglose abajo |

Desglose de WebGPU según **MDN browser-compat-data** (verbatim de las notas):
- **Chrome 144**: *"Supported on ChromeOS, macOS, Windows, and Linux (Intel Gen12+ GPUs only)"*. Antes,
  113–143 marcado como implementación parcial en ChromeOS, macOS y Windows. **Linux sigue siendo el
  agujero**: solo Intel Gen12+.
- **Chrome Android 121**: soportado (el soporte real depende del dispositivo y del driver).
- **Firefox 141**: implementación **parcial** — *"Supports all contexts except service workers"*;
  *"Supports Windows since Firefox 141"*; *"Supports macOS Tahoe on Apple silicon since Firefox 145"*.
- **Firefox Android**: `version_added: false`. **No hay soporte.**
- **Safari 26 / iOS 26** (y derivados en iOS, que son WebKit).

**Criterio de elección:**

| Situación | Decisión |
|---|---|
| Producto público, audiencia general, móvil incluido | **WebGL2 como base**, WebGPU como camino acelerado opcional. La degradación **no es opcional hoy** |
| Cómputo real en GPU (compute shaders), inferencia, simulación | **WebGPU**, y una respuesta escrita a qué pasa sin él (CPU/Wasm, servidor, o función desactivada) |
| Audiencia controlada (intranet, kiosco, parque de equipos conocido) | **WebGPU directo**, con el parque verificado — incluida la versión de driver |
| Escena sencilla, pocos objetos, sin cómputo | **WebGL2** y punto. WebGPU no acelera lo que no era lento |
| Linux o Firefox Android en la audiencia | **WebGL2 obligatorio**: es donde WebGPU no está |

**Degradación**: se implementa **una sola vez**, en el motor. Escribir dos renderers a mano (uno WebGPU,
otro WebGL2) es duplicar la superficie de bug; por eso el default es un motor que ya lo hace.

### WGSL y estado de la especificación

- **WebGPU**: *"W3C Candidate Recommendation Draft, 14 July 2026"*.
- **WGSL** (WebGPU Shading Language): *"W3C Candidate Recommendation Draft"*, **16 de julio de 2026**.

Consecuencia: **es una especificación viva, no un estándar cerrado**. Fijar la versión del motor y leer
sus notas de migración en cada actualización; no depender de extensiones marcadas como experimentales
(p. ej. las de nombre `chromium-experimental-*`), que existen bajo *flag* y desaparecen sin aviso.

### Motores y librerías

| Pieza | Estado a ago-2026 | Criterio |
|---|---|---|
| **three.js** (`three`) | **0.185.1** (2026-07-01), **MIT** (leído del `LICENSE`) | Ecosistema y ejemplos imbatibles. `WebGPURenderer` (import desde `three/webgpu`) es **universal**: intenta WebGPU y **cae a WebGL2 automáticamente**; los *node materials* / TSL solo viven ahí. **Cuidado: sigue en `0.x` y rompe entre revisiones (`rXXX`)** — se fija la versión exacta y se lee la *Migration Guide* en cada salto |
| **Babylon.js** (`@babylonjs/core`) | **9.19.0** (2026-07-30), **Apache-2.0 — NO es MIT** (leído del `license.md`) | Motor con baterías incluidas (editor, inspector, física, XR, sistema de materiales por nodos). Doble backend WebGPU/WebGL2 de serie. Mejor opción cuando el proyecto es "una aplicación 3D", no "una web con 3D". La licencia Apache-2.0 importa si hay política de licencias |
| Bajo nivel (WebGL2/WebGPU a pelo, `regl`, envoltorios finos) | — | **Solo** con motivo escrito: control total del pipeline, un caso muy acotado o un presupuesto de bytes que no admite un motor. El coste es que reimplementas pérdida de contexto, gestión de recursos, degradación y perfilado |
| Motor 2D acelerado (PixiJS y similares) | Verificar versión y licencia antes de fijar (§8) | Para 2D masivo (partículas, sprites, mapas), donde un motor 3D es exceso |

**Regla**: se elige **un** motor por proyecto y no se mezclan dos que gestionen el contexto GPU. Antes
de fijar cualquiera: **versión exacta, licencia leída del `LICENSE` en crudo y última publicación**.

### Assets

| Pieza | Elección | Notas |
|---|---|---|
| Formato de escena | **glTF 2.0 / GLB** | Estándar Khronos, soportado por todos los motores |
| Texturas | **KTX2 con Basis Universal** (`KHR_texture_basisu`) | ETC1S para color, UASTC para datos no-color (normales, roughness-metallic), según la propia extensión de Khronos |
| Herramientas | **KTX-Software** (Khronos) y **basis_universal** (Binomial) — ambos **Apache-2.0**, leído del `LICENSE` | El navegador **no decodifica KTX2 de forma nativa**: el motor transcodifica en cliente (Wasm) al formato que soporte la GPU |

## 3. Estructura y convenciones

### Rendimiento: el presupuesto de fotograma es el eje del dominio

- **60 Hz → 16,7 ms por fotograma** (1000/60 = 16,67). Ese es el **total**, no tu presupuesto: dentro
  caben el trabajo de JS, el estilo/layout del resto de la página, la composición y el propio trabajo de
  GPU. Presupuesto de trabajo razonable: **~10-12 ms**, dejando margen al navegador.
- **No todo el mundo va a 60 Hz.** 120 Hz → **8,3 ms**; 144 Hz → **6,9 ms**. `requestAnimationFrame`
  se ajusta a la pantalla: en un móvil de 120 Hz tu escena de "60 fps holgados" empieza a tirar
  fotogramas. **No se asume 60**: se mide el delta real y la animación se hace **en función del tiempo
  transcurrido, nunca por fotograma** (`delta`), o la escena corre al doble de velocidad en un panel de
  120 Hz. Si el coste no cabe, **se limita el fotograma a propósito** (render a 30/60 fps estables) en
  vez de entregar una cadencia irregular: el *jank* se percibe peor que un fps menor y constante.
- **Draw calls**: el coste dominante en la mayoría de escenas web no es el número de triángulos, es el
  número de llamadas de dibujo y los cambios de estado. Agrupar por material, fusionar geometrías
  estáticas, **instanciar** lo repetido (`drawElementsInstanced` / `drawIndexed` con instancias): un
  bosque de 5.000 árboles es **una** llamada, no 5.000.
- **Transferencia CPU↔GPU**: subir buffers o texturas cada fotograma es el segundo cuello clásico. Los
  datos estáticos se suben una vez; lo dinámico va en buffers persistentes actualizados por rangos.
  **Leer de vuelta de la GPU (`readPixels`, `mapAsync`) sincroniza y destroza el pipeline**: si hace
  falta, se hace de forma asíncrona y con varios fotogramas de latencia asumidos.
- **Texturas comprimidas, siempre, en producción**: una PNG/JPEG se descomprime a RGBA sin comprimir en
  memoria de GPU (2048×2048 RGBA ≈ 16 MB, más mipmaps). KTX2/Basis transcodifica al formato nativo del
  dispositivo. Estado de las extensiones (webstatus.dev): **ASTC widely available** (`newly` 2020-01-15,
  `widely` 2022-07-15); **BPTC/BC7 (`EXT_texture_compression_bptc`) y RGTC: Baseline limited**. Por eso
  se envía **KTX2 y se transcodifica en cliente**, en vez de servir un formato fijo por plataforma.
  Mipmaps siempre en lo que se ve en perspectiva.
- **LOD y culling**: niveles de detalle por distancia, *frustum culling* (lo hace el motor, hay que no
  romperlo con jerarquías raras), y *occlusion culling* solo si el perfilado lo justifica. Menos
  geometría subida que descartada.
- **Resolución**: renderizar a `devicePixelRatio` completo en un móvil de gama media es la causa número
  uno de calentamiento. Se limita (`min(dpr, 2)` o menos) y se hace **escalado dinámico de resolución**
  cuando el fotograma se pasa del presupuesto.
- **OffscreenCanvas en un worker** (webstatus.dev: **Baseline widely available**, `widely` 2025-09-27)
  para sacar el bucle de render del hilo principal: la escena deja de bloquear la interacción y la
  interacción deja de tirar fotogramas. Es la decisión estructural que más rinde en apps mixtas.
- **Postprocesado**: cada pasada de pantalla completa es coste fijo por píxel. Se cuentan las pasadas y
  se justifican una a una.

### Medición: el perfilado de CPU no ve el cuello de botella de GPU

Esto es lo que se hace mal casi siempre. El *flame chart* de JavaScript muestra el hilo principal; la
GPU trabaja **de forma asíncrona**. Si la GPU va saturada, en el perfil de CPU verás JS ocioso y
fotogramas largos sin causa aparente — o, peor, verás tiempo dentro de una llamada de la API que en
realidad está **esperando** a la cola de la GPU.

- Regla de diagnóstico: **si bajar la resolución del canvas mejora los fps, el cuello está en la GPU
  (fragmentos/relleno); si no cambia nada, está en CPU o en draw calls.** Es la prueba de dos minutos
  que evita días de optimización mal dirigida.
- **Chrome DevTools → Performance con la pista de GPU activada**, y `chrome://gpu` como fuente de verdad
  de memoria de vídeo. El Firefox Profiler para el equivalente en Gecko.
- **`timestamp-query` de WebGPU** para medir pasadas en GPU. **Está cuantizado a 100 µs por defecto** (es
  una mitigación contra ataques de temporización); la cuantización solo se desactiva con el *flag*
  `chrome://flags/#enable-webgpu-developer-features`, que **no es un entorno de producción**. Además, los
  contadores de la GPU pueden reiniciarse y producir deltas negativos: se descartan.
- **`timestamp-query` no basta**: una pasada rápida en el reloj puede ser lenta en throughput. La prueba
  final es la carga real (subir número de objetos/resolución hasta que caen los fps).
- Herramientas de captura de fotograma (inspector de estado de WebGL/WebGPU, capturas del motor) para ver
  draw calls, cambios de estado y texturas subidas. El inspector de Babylon.js y las herramientas de
  desarrollo de three.js dan el recuento de llamadas y triángulos: **ese contador va en el HUD de
  desarrollo desde el primer día**.
- Se mide **en el hardware objetivo**, y el hardware objetivo incluye **un móvil de gama media de hace
  tres años**. Un portátil de desarrollo no mide nada relevante para el usuario.

### Memoria de GPU y pérdida de contexto

- **La memoria de GPU no la administra el recolector de basura de JS.** Texturas, buffers, geometrías,
  render targets y pipelines se **liberan explícitamente** (`dispose()` del motor, `destroy()` en
  WebGPU). Cambiar de escena sin liberar es la fuga de memoria más común del dominio y termina en
  contexto perdido o pestaña muerta.
- **Manejar la pérdida de contexto NO es opcional: en móvil ocurre.** El navegador puede tirar el
  contexto GPU por presión de memoria, cambio de app, suspensión, actualización de driver o simplemente
  porque el sistema necesita la GPU. Sin manejo, el canvas se queda **en negro para siempre**.
  - WebGL: escuchar **`webglcontextlost`** (y llamar a `event.preventDefault()`, o no habrá restauración)
    y **`webglcontextrestored`** para reconstruir **todos** los recursos GPU. `WEBGL_lose_context` es
    Baseline **widely available** y sirve para **provocar la pérdida en un test** — se prueba, no se
    espera a que pase en producción.
  - WebGPU: `device.lost` es una promesa; al resolverse hay que **pedir un dispositivo nuevo** y
    recrear todo. Un `GPUDevice` perdido no se recupera.
  - Los eventos genéricos `contextlost`/`contextrestored` de `<canvas>` son **Baseline limited**
    (webstatus.dev: Chrome 99, Firefox 125, **sin Safari**): no se depende de ellos.
- Presupuesto de memoria de texturas **declarado** (p. ej. "≤ X MB de texturas en escena") y verificado
  en el HUD de desarrollo. En móvil el techo es mucho más bajo de lo que sugiere la RAM del dispositivo.

### Cómputo en GPU en el navegador

Los *compute shaders* de WebGPU son la primera vía real de cómputo general en GPU desde la web (WebGL2
no los tiene: emularlos con *transform feedback* o render-to-texture es un apaño). Casos reales:
simulación de partículas y física, procesamiento de imagen y vídeo, *culling* y ordenación en GPU,
generación procedural, y **inferencia de modelos en el cliente**.

- **Inferencia en cliente**: WebGPU es hoy el sustrato de las librerías de inferencia en navegador. La
  decisión de **qué modelo, qué cuantización y qué evaluación** es de `local-inference-standards`; aquí
  solo el sustrato: comprobar `navigator.gpu`, comprobar **límites del adaptador**
  (`maxBufferSize`, `maxStorageBufferBindingSize`, `maxComputeWorkgroup*`) antes de decidir que el modelo
  cabe, y tener una respuesta escrita para el dispositivo sin WebGPU (Wasm en CPU, servidor, o función
  no disponible — pero **explicada**, no rota).
- Un cómputo largo en GPU **bloquea la GPU que también dibuja la interfaz**. Se trocea en unidades que
  quepan en el presupuesto de fotograma, o se acepta explícitamente que la UI se congela y se avisa.
  En móvil, además, es un consumo de batería que el usuario nota.
- El resultado se lee de vuelta de forma asíncrona (`mapAsync`), nunca en el camino del fotograma.

### Accesibilidad

- **Un canvas es opaco para la tecnología asistiva**: no tiene estructura ni texto; para un lector de
  pantalla es una imagen sin contenido. **Toda información transmitida solo por el canvas debe existir en
  otra forma**: contenido de respaldo dentro del elemento `<canvas>`, tabla o lista equivalente,
  descripción textual, o una vista alternativa. Un visor 3D decorativo se marca como decorativo; un
  gráfico con datos **necesita los datos**. El criterio de conformidad (qué nivel WCAG exige qué) es de
  `accessibility-standards`; la obligación técnica es de aquí.
- Interacción: si se puede hacer con ratón dentro del canvas, **debe poder hacerse con teclado**, y el
  foco debe ser visible. Controles reales de HTML fuera del canvas siempre que sea posible; recrear un
  botón dibujándolo en píxeles es empezar de cero con la accesibilidad.
- **`prefers-reduced-motion`** (webstatus.dev: **Baseline widely available**, `widely` 2022-07-15) es un
  interruptor **real**: cámaras automáticas, parallax, rotaciones continuas, partículas y transiciones se
  reducen o se detienen. No es "bajar un poco la velocidad": la animación no esencial se apaga.
- Sin epilepsia inducida: nada de destellos por encima de los umbrales, ni de estroboscopios decorativos.

### Compatibilidad y degradación

- **Detección de capacidades, nunca detección de navegador.** `if (navigator.gpu)`, luego
  `await navigator.gpu.requestAdapter()` — **que puede devolver `null` aunque `navigator.gpu` exista**
  (sin GPU compatible, driver bloqueado, adaptador de software). Comprobar además `adapter.features` y
  `adapter.limits` antes de asumir nada: **un adaptador no es un contrato de capacidades**.
- `requestDevice()` también puede fallar y el dispositivo puede perderse **inmediatamente**. Toda la
  ruta de inicialización es asíncrona y falible.
- Cadena de degradación escrita: **WebGPU → WebGL2 → (opcional) Canvas 2D / imagen estática / vista
  alternativa**. Cada escalón debe ser una experiencia utilizable, no un mensaje de error.
- **Sin GPU** (renderizado por software, GPU en lista negra del navegador, dispositivo muy limitado): se
  detecta y se ofrece la vista alternativa. Renderizar por software una escena pesada convierte el
  portátil del usuario en un radiador y no dibuja nada útil.
- Las **extensiones de WebGL** se comprueban una a una (`getExtension`) — su soporte varía mucho más que
  el de WebGL2 (ver BPTC/RGTC arriba, ambas *limited*).

## 4. Calidad y gates de CI

En orden de coste creciente:

1. **Compilación de shaders en CI**: validar WGSL/GLSL en el build (un error de compilación de shader es
   un fallo en tiempo de ejecución y en la cara del usuario). Los shaders viven en ficheros
   versionados y linteados, no en literales de plantilla dispersos.
2. **Presupuesto de assets**: tamaño de modelos y texturas por escena, número de texturas, y **fallar el
   build** si se supera lo declarado. Un `.glb` de 80 MB entra por la puerta de atrás sin este gate.
3. **Verificación de formato**: texturas en KTX2 (no PNG/JPEG sueltas en producción), geometría con
   compresión donde aplique, y ausencia de texturas de 4096² para elementos de 100 px.
4. **Test de degradación**: arrancar con WebGPU deshabilitado y comprobar que la ruta WebGL2 funciona; y
   con ambas deshabilitadas, que aparece la alternativa. **Sin este test, la degradación no existe: es
   una intención.**
5. **Test de pérdida de contexto**: forzarla con `WEBGL_lose_context` (o el equivalente WebGPU) y
   verificar que la escena se reconstruye. Automatizable y casi nadie lo hace.
6. **Test de accesibilidad de la alternativa**: que el contenido equivalente existe y es alcanzable por
   teclado y por lector de pantalla (herramienta y criterio → `accessibility-standards`).
7. **Regresión visual** de fotogramas de referencia: útil pero **inestable entre GPUs y drivers**; se
   fija el entorno (mismo runner, mismo backend, tolerancia de diferencia) o produce ruido perpetuo.
8. **Regresión de rendimiento**: tiempo de fotograma y draw calls en una escena canónica, en hardware
   fijo. Aviso, no fallo, salvo desviación grande: la varianza es real.

## 5. Seguridad

**La GPU es superficie de ataque, y de las más rentables.** El modelo del navegador es: el contenido web
habla con el proceso de GPU por IPC; ese proceso tiene acceso al driver, **está menos aislado que el
proceso de renderizado y se comparte entre orígenes**. Un fallo ahí es escalada de privilegios.

Mitigaciones que aplica el navegador (no las tuyas, pero condicionan lo que puedes hacer):
- **Validación estricta y traducción de shaders**: WGSL se valida y se traduce (Tint en Chromium/Dawn,
  wgpu en Firefox, la pila de Apple en WebKit) al lenguaje del backend nativo (D3D12/Metal/Vulkan). Un
  shader no llega crudo al driver, y la creación de módulo o de pipeline **falla antes de ejecutar** si
  no valida.
- **Aislamiento de proceso** y sanitización de los mensajes IPC entre el renderizador y el proceso de GPU.
- **Cuantización de `timestamp-query` a 100 µs** y no exposición en contextos no aislados, precisamente
  para dificultar ataques de temporización y canales laterales de caché de GPU.
- **Listas de bloqueo de GPU/driver**: el navegador desactiva la aceleración en configuraciones
  conocidas como problemáticas. Por eso `requestAdapter()` puede devolver `null` en una máquina con GPU.

Y su historial real, verificado en NVD (ago-2026):
- **CVE-2026-5281**, verbatim: *"Use after free in Dawn in Google Chrome prior to 146.0.7680.178 allowed a
  remote attacker who had compromised the renderer process to execute arbitrary code via a crafted HTML
  page. (Chromium security severity: High)"*
- **CVE-2026-6310**, verbatim: *"Use after free in Dawn in Google Chrome prior to 147.0.7727.101 allowed a
  remote attacker who had compromised the renderer process to potentially perform a sandbox escape via a
  crafted HTML page. (Chromium security severity: High)"*

Lo que esto significa para tu diseño:
- **Ejecutar *shaders* de terceros es ejecutar código no confiable contra la superficie más frágil del
  navegador.** Un shader subido por un usuario, o traído de una URL ajena, no es "un texto": es entrada
  hostil hacia el compilador de shaders. Si el producto lo permite (editor de efectos, galería de
  shaders de la comunidad), es una **decisión de riesgo escrita**: origen aislado, CSP estricta, sin
  sesión ni datos en ese origen, y con la asunción de que un bug del navegador te afecta directamente.
  Lo mismo con modelos glTF de terceros: son entrada para *parsers* complejos.
- Actualizar el navegador **es** el control principal, y no lo controlas tú. En parque gestionado
  (kioscos, terminales), la política de actualización del navegador es parte del sistema.
- **Fingerprinting**: la GPU es una de las señales de identificación más estables del navegador —
  adaptador, límites, características soportadas y tiempos de compilación. Instanciar un contexto WebGL
  solo para "detectar capacidades" **es una técnica de fingerprinting**, exista o no la intención. Base
  legal, consentimiento y minimización → `privacy-engineering-standards`.
- **En el cliente no hay secretos**, y un shader es texto descargable: nada de lógica de licencia,
  marcas de agua "invisibles" o claves dentro del shader o del asset.
- Assets y transcodificadores son **Wasm de terceros en tu página**: se fijan por versión, se sirven
  desde tu origen y siguen la política de suministro de `frontend-web-platform-standards`.

### Batería y térmica: coste real en móvil

- La GPU es, con la pantalla, el mayor consumidor del dispositivo. Una escena que mantiene la GPU al
  100% **calienta el teléfono, lo hace bajar de frecuencia (*thermal throttling*) y vacía la batería**.
  El síntoma característico es "va bien 30 segundos y luego a la mitad de fps": eso no se arregla
  optimizando micro-detalles, se arregla **bajando el trabajo por fotograma**.
- Obligatorio: **parar el bucle de render cuando el canvas no es visible**
  (`IntersectionObserver` + `visibilitychange`). Un `requestAnimationFrame` que sigue corriendo en una
  pestaña de fondo o fuera de pantalla es consumo puro. Es la optimización más barata y la más olvidada.
- Renderizar **bajo demanda** (solo cuando algo cambia) en escenas estáticas o casi estáticas, en vez de
  a 60 fps perpetuos.
- Escalado dinámico de resolución y límite de fps como política, no como reacción.

## 6. Rendimiento y operabilidad

- Telemetría desde el cliente (qué instrumentar; la plataforma → `observability-standards`):
  backend elegido (WebGPU/WebGL2/alternativa), fabricante y modelo de adaptador **agregados** (ojo con la
  privacidad), tiempo de fotograma p50/p95, **eventos de pérdida de contexto**, fallos de
  `requestAdapter`/`requestDevice`, errores de compilación de shader y tiempo de carga de la escena.
- **La pérdida de contexto es una métrica operativa**, no una curiosidad: un pico en un modelo de móvil
  concreto es un bug de memoria en tu escena, y así se descubre.
- Carga progresiva: la escena aparece por niveles (geometría básica → texturas → detalle), nunca una
  pantalla en blanco de 20 segundos. Indicador de progreso real.
- Presupuestos declarados en el repo: ms por fotograma, draw calls, MB de texturas, MB de assets por
  escena. Sin números escritos no hay regresión detectable.

## 7. Sostenibilidad y prohibiciones

- **Re-evaluar el soporte de WebGPU cada 6 meses** (`webstatus.dev`/MDN): el día que sea Baseline widely
  available, la ruta WebGL2 pasa a ser deuda que se retira — con fecha, no "algún día". Hoy **no lo es**.
- three.js está en `0.x`: se fija la revisión exacta, se lee la *Migration Guide* en cada salto y se
  actualiza con cadencia, no de golpe tras dos años. Babylon.js sigue semver, pero su ciclo de majors es
  real.
- Los shaders son código: se revisan, se comentan y se prueban. Un shader copiado de una galería y no
  entendido es deuda opaca con coste de GPU desconocido.
- Cada extensión, característica o límite tras feature detection lleva escrita su condición de retirada.

**PROHIBIDO:**
- ❌ Usar WebGL/WebGPU para un gráfico de datos que Canvas 2D o SVG resuelven — se pierde accesibilidad y
  depuración a cambio de nada.
- ❌ Enviar solo WebGPU sin degradación a WebGL2: **no es Baseline** (Linux salvo Intel Gen12+, Firefox
  Android, Firefox Linux, navegadores antiguos).
- ❌ Asumir que `navigator.gpu` implica adaptador: `requestAdapter()` puede devolver `null`.
- ❌ Detección por *user agent* en lugar de detección de capacidades.
- ❌ No manejar `webglcontextlost` / `device.lost` — en móvil ocurre y deja el canvas en negro. No llamar
  a `preventDefault()` en `webglcontextlost` (sin eso no hay restauración).
- ❌ No liberar recursos de GPU al cambiar de escena (`dispose()`/`destroy()`): la GPU no tiene GC.
- ❌ `requestAnimationFrame` corriendo con el canvas fuera de pantalla o la pestaña oculta.
- ❌ Animar por fotograma en vez de por tiempo transcurrido: en un panel de 120 Hz la escena va al doble.
- ❌ Renderizar a `devicePixelRatio` sin límite en móvil.
- ❌ Servir texturas PNG/JPEG sin comprimir para GPU en producción, o texturas de 4096² para elementos
  pequeños; olvidar mipmaps.
- ❌ Lecturas síncronas de GPU (`readPixels` y equivalentes) dentro del bucle de fotograma.
- ❌ Un canvas sin alternativa accesible cuando transmite información; ignorar `prefers-reduced-motion`.
- ❌ Optimizar guiándose solo por el perfil de CPU: **no ve el cuello de GPU**. Antes, la prueba de bajar
  la resolución.
- ❌ Depender de `chrome://flags/#enable-webgpu-developer-features` o de extensiones
  `chromium-experimental-*` para algo que llega a producción.
- ❌ Compilar shaders de terceros (o de usuarios) sin decisión de riesgo escrita y aislamiento de origen.
- ❌ Crear un contexto WebGL solo para perfilar el dispositivo: eso es fingerprinting.
- ❌ Dos motores gestionando el contexto GPU en la misma página.
- ❌ Copiar de memoria (o de un blog) el estado de soporte de WebGPU. Se comprueba (§8).

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar online (WebSearch/WebFetch; **MDN/BCD y `webstatus.dev` para soporte**,
W3C para el estado de la especificación, NVD para CVEs, feeds Atom de GitHub para versiones —
**`api.github.com` da 403 sin autenticar**; licencias leídas del `LICENSE` en crudo):

1. **Soporte de WebGPU por navegador *y por plataforma*** en `webstatus.dev`/MDN-BCD, no en un blog: hoy
   **Baseline limited**, con Linux limitado a Intel Gen12+ en Chrome, Firefox parcial (Windows y macOS
   Tahoe en Apple silicon) y **sin Firefox Android**. Comprobar si ya cambió: es lo que decide la
   arquitectura del proyecto.
2. **Estado de la especificación**: WebGPU (CR Draft 14-jul-2026) y WGSL (CR Draft 16-jul-2026). ¿Hay
   Recommendation? ¿Nuevas features estandarizadas (subgrupos, etc.)?
3. **Versiones y licencias** de lo que fijes: three.js (`0.185.1`, **MIT**, y sigue en `0.x`),
   Babylon.js (`@babylonjs/core` `9.19.0`, **Apache-2.0, no MIT**), KTX-Software y basis_universal
   (**Apache-2.0**), y la librería 2D que elijas. Comprobar también **modo mantenimiento o cambio de
   propiedad**.
4. **Extensiones de textura comprimida** (ASTC widely; BPTC/RGTC **limited**) y el estado del pipeline
   KTX2/Basis, incluidos formatos nuevos del transcodificador que **puede que aún no estén
   estandarizados en KTX/glTF**.
5. **Advisories del navegador**: Chrome Releases y NVD para CVEs de Dawn/GPU/ANGLE. En 2026 hay varios
   UAF en Dawn (§5). Es contexto para la decisión de exponer WebGPU en un parque gestionado.
6. **Herramientas de perfilado**: estado de la pista de GPU en DevTools, de `timestamp-query` y su
   cuantización, y de los inspectores de los motores.
7. **Baseline de las APIs de apoyo**: `OffscreenCanvas` (widely), `prefers-reduced-motion` (widely),
   `canvas-context-lost` (**limited, sin Safari**), WebGL2 (widely).

**Huecos no verificados a ago-2026** (no rellenar de memoria; comprobar antes de usar):
- **Soporte de WebGPU en WebView de Android y en navegadores derivados de Chromium** (Samsung Internet,
  Opera; BCD los marca como `mirror`, lo que no garantiza paridad real por dispositivo): **no verificado**.
- **Estado de WebGPU en Firefox para Linux y Android** más allá de "en desarrollo": **no verificado**;
  las fechas objetivo que circulan proceden de fuentes secundarias.
- **Versión y licencia de la librería 2D acelerada** (PixiJS u otra) de §2: **no verificado**, se deja
  deliberadamente sin fijar.
- **Cuota o techo de memoria de GPU por pestaña** en cada navegador: **no verificado** y probablemente no
  documentado. Los presupuestos de §6 son acuerdos de proyecto, **no datos medidos**.
- **Estado de WebGPU en *service workers*** más allá de la nota de Firefox (*"Supports all contexts
  except service workers"*): **no verificado** para el resto de motores.
- **Mitigaciones concretas de canales laterales de GPU** (cachés de compilación, WebGPU-SPY y trabajos
  similares) y qué navegador aplica cuáles: **no verificado**; la cuantización de `timestamp-query` es
  la única confirmada por documentación de Chromium.
- **Cifras de fotograma de §3** (10-12 ms de trabajo útil): regla de diseño, **no una medición**; el
  presupuesto real se establece midiendo en el hardware objetivo.

**Discrepancia declarada**: múltiples fuentes secundarias (incluidas notas de "WebGPU 2026") afirman que
**WebGPU alcanzó Baseline en enero de 2026 en todos los navegadores principales**. **Es falso según las
fuentes primarias**: `webstatus.dev` clasifica `webgpu` como **Baseline limited** (sin entrada de
Firefox) y MDN lo rotula, verbatim, *"This feature is not Baseline because it does not work in some of
the most widely-used browsers."* Manda MDN/`webstatus.dev`. Segunda discrepancia: varios artículos
describen CVE-2026-5281 como explotable *"zero-click"* con solo visitar una página; **el texto de NVD
dice que requiere un atacante *"who had compromised the renderer process"*** (§5) — la diferencia entre
"visitar una web te compromete" y "hace falta encadenar otra vulnerabilidad" es toda la evaluación de
riesgo. Manda NVD / el aviso de Chromium.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
