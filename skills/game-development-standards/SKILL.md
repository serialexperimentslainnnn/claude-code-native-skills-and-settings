---
name: game-development-standards
description: Game development as engineering, governed by the frame budget. Use when working with Unity (.unity scenes, .prefab, .meta files, Assets/ and ProjectSettings/, Packages/manifest.json, MonoBehaviour, FixedUpdate, Burst/Jobs, DOTS/Entities, Addressables, IL2CPP, Unity 6 LTS and Unity Personal/Pro/Enterprise revenue thresholds), Unreal Engine (.uproject, .uasset, .umap, Build.cs and Target.cs, UPROPERTY/UFUNCTION, Blueprints, Nanite, Lumen, Chaos, World Partition, UE royalty and per-seat licensing), Godot (project.godot, .tscn, .tres, GDScript .gd, _process versus _physics_process), a game loop with fixed timestep and interpolation, frame-time percentiles, stutter and hitching, GC spikes and object pooling, asset streaming and level loading, ECS and data-oriented design, deterministic simulation and floating-point desync, netcode with server authority, client-side prediction, rollback and lag compensation, cheating and anti-cheat, matchmaking and lobbies, large binary assets under Git LFS or Perforce P4/Helix Core, console certification and platform TRC/TCR submission, in-game accessibility (remapping, subtitles, motion options), or loot boxes, in-game purchases and PEGI descriptors.
---

# Estándares de desarrollo de videojuegos

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio de ingeniería sobre **construir un juego**: qué motor y bajo qué licencia, cómo se
organiza el bucle de simulación, cómo se gestiona memoria y carga, cómo se diseña el multijugador
cuando el cliente es hostil por defecto, cómo se versionan gigabytes de binarios, qué exige una
consola para dejarte publicar, y qué obligaciones legales trae monetizar con azar y con menores.

**Eje del dominio: el presupuesto de fotograma lo domina todo.** No es una métrica de rendimiento
entre otras — es la restricción de la que se deriva la arquitectura entera. A 60 fps hay **16,6 ms**
por fotograma para simular, animar, resolver físicas, culling, preparar y emitir *draw calls*, audio,
red y entrada; a 30 fps, 33,3 ms; a 120 fps, 8,3 ms; a 90 Hz de XR, 11,1 ms (ver `xr-standards`). De
ese número salen todas las decisiones que en otro dominio serían opinables: por qué se agrupa memoria
en lugar de reservarla, por qué se evita la asignación en el bucle caliente, por qué los datos se
disponen por columnas, por qué el nivel se carga por partes. **Un diseño que no cabe en el
presupuesto no es un diseño lento: es un diseño incorrecto.**

**Corolario que decide el trabajo diario: manda el percentil, no la media.** 240 fps de media con un
fotograma de 80 ms cada dos segundos se percibe **peor** que 60 fps estables. La métrica de producto
es el **tiempo de fotograma** (ms) en **p99 / p99.9** y el número de fotogramas que se salen del
presupuesto (*hitches*), no los fps medios. Los fps son un promedio recíproco: ocultan exactamente el
fallo que el jugador nota. **Ningún objetivo de rendimiento se escribe en fps medios.**

Triggers: `.unity`, `.prefab`, `.meta`, `Assets/`, `ProjectSettings/`, `Packages/manifest.json`,
`MonoBehaviour`, `Update`/`FixedUpdate`/`LateUpdate`, `[BurstCompile]`, `Entities`, `Addressables`,
IL2CPP; `.uproject`, `.uasset`, `.umap`, `*.Build.cs`, `UPROPERTY`, `UCLASS`, Blueprint, Nanite,
Lumen, Chaos, World Partition; `project.godot`, `.tscn`, `.tres`, `.gd`, `_physics_process`;
`.gitattributes` con `filter=lfs`, `p4 sync`, `p4 edit`, `typemap`; "va a tirones", "se congela al
entrar en la zona", "los jugadores se teletransportan", "no pasa la cert", "desincroniza en la
partida en red".

**No aplica**: ver `webgl-webgpu-standards` (**el navegador y la API gráfica son suyos, sin
excepción**: `getContext('webgl2'|'webgpu')`, WGSL/GLSL, three.js/Babylon, pérdida de contexto,
KTX2/Basis, y **el presupuesto de fotograma dentro de un canvas web**. Frontera operativa: **si el
destino es el navegador, la capa gráfica es suya y aquí solo queda el diseño del bucle, la
simulación y la producción de assets**; si el destino es un ejecutable nativo o de consola, la
gráfica cae bajo el motor y su documentación, no bajo esta skill —esta skill **no** fija criterio de
API gráfica nativa: no reclama Vulkan, D3D12 ni Metal), `xr-standards` (**lote 22, hermana directa**:
**confort, cinetosis, latencia movimiento-fotón, OpenXR, interacción con manos y mandos y la
privacidad biométrica son suyos**; **aquí el motor, el bucle y la producción del contenido**. Un
juego de VR se construye bajo esta skill y **se valida bajo la suya**: si el presupuesto se justifica
por el mareo y no por la fluidez, es de allí), `cpp-standards` y `c-standards` (el lenguaje: RAII,
UB, sanitizers, flags de compilación — aquí solo el uso que le da el motor),
`dotnet-standards` (**C# como lenguaje**; ojo: **Unity no usa el runtime de .NET moderno ni sus
convenciones**, y su §1 lo excluye explícitamente — el C# de scripting de Unity es de aquí, el C# de
servidor es suyo), `rust-standards` (lenguaje; motores en Rust son ecosistema inmaduro: exige ADR),
`performance-engineering-standards` (**la metodología de perfilado y optimización es suya**:
método USE, *flame graphs*, medir antes de optimizar, ley de Amdahl. **Aquí solo la restricción
específica —el presupuesto por fotograma— y las herramientas del motor**), `gaming-infrastructure`
(**Ola 7, planificada**: **servidores dedicados, orquestación de sesiones, escalado y coste de flota,
transporte, matchmaking como servicio**. Aquí el **protocolo y el modelo de autoridad** del juego, no
la infraestructura que lo aloja), `mobile-standards` (tienda, empaquetado, permisos, ciclo de vida de
app y política de App Store/Play; aquí solo el juego que corre dentro), `accessibility-standards`
(**el criterio de conformidad WCAG y su alcance legal es suyo**; **un juego no es una página web y
WCAG no le aplica directamente** — aquí las opciones de accesibilidad de juego), `i18n-standards`
(localización, formatos, pseudolocalización y proveedor de traducción; aquí el coste que impone al
motor: texto en atlas, longitud variable, doblaje), `privacy-engineering-standards` (RGPD aplicado,
DPIA, telemetría y datos de menores como diseño; aquí solo el disparador del dominio),
`git-workflow-standards` (rama, commits, LFS como herramienta y política de repo),
`testing-qa-standards` (estrategia de test y QA como función), `cicd-standards` (pipeline y gates),
`deep-learning-standards` / `local-inference-standards` (IA como modelo entrenado; la "IA" de
comportamiento de NPC —máquinas de estado, *behavior trees*, GOAP, *pathfinding*— **es de aquí**),
`opensource-licensing-standards` (licencia de dependencias y de assets), `webassembly-standards`
(el objetivo Wasm y su runtime).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión y **las condiciones comerciales vigentes** por web antes de fijarlas en
> un proyecto real (§8). **Los términos de Unity y Unreal han cambiado dos veces en tres años; casi
> todo lo que circula por foros está caducado.**

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| Motor 3D de equipo pequeño/medio | **Unity 6 LTS** | Unreal | Ecosistema, plataformas, contratación |
| Fidelidad gráfica alta / AAA | **Unreal Engine 5** | Unity con HDRP | Nanite, Lumen, herramientas de cine |
| 2D, indie, sin ataduras de licencia | **Godot 4** | Unity | MIT, sin umbrales ni royalties |
| Riesgo de licencia inaceptable | **Godot** | Motor propio | Único de los tres sin contraparte comercial |
| Motor propio | **No**, salvo requisito imposible | — | Coste permanente de herramientas y port |
| Lenguaje de gameplay | El del motor (C#, C++/Blueprint, GDScript) | — | Salirse rompe el *tooling* |
| Control de versiones de arte | **Perforce (P4/Helix Core)** en producción con artistas | Git + LFS en equipo pequeño | Bloqueo exclusivo de binarios |
| Objetivo de rendimiento | **ms de p99 por plataforma**, no fps medios | — | El *stutter* es el fallo real |
| Multijugador competitivo | **Autoridad del servidor** | — | El cliente es hostil por definición |
| Multijugador cooperativo pequeño | Anfitrión-cliente con autoridad del anfitrión | P2P determinista (*lockstep*) | Coste frente a superficie de trampa |
| Red de acción rápida | Predicción + reconciliación + compensación de retardo | *Rollback* (juegos de lucha) | Latencia percibida |

**Estado verificado de las licencias (agosto de 2026)** — es el dato que decide un proyecto:

- **Unity**: la *Runtime Fee* **se canceló**. Verbatim del anuncio (Matt Bromberg, CEO, 12-sep-2024):
  *«we've made the decision to cancel the Runtime Fee for our games customers, effective immediately.
  Non-gaming Industry customers are not impacted by this modification»* y *«we're reverting to our
  existing seat-based subscription model for all gaming customers»*. Modelo vigente según
  `unity.com/pricing` (consultado ago-2026): **Personal gratis** por debajo de **200 000 USD** de
  ingresos o financiación en los últimos 12 meses; **Pro obligatorio por encima de 200 000 USD**
  (**210 USD/mes por puesto**, desde **2 310 USD/año**); **Enterprise obligatorio por encima de
  25 M USD**; **Unity Industry** para aplicaciones **fuera de juego/entretenimiento** con más de
  1 M USD. **Verificar los umbrales y el precio antes de presupuestar**: subieron el 1-ene-2025 y han
  vuelto a moverse.
- **Unity, versiones**: `unity.com/releases` (ago-2026) — **Unity 6.3 LTS soportada hasta diciembre
  de 2027**; **Unity 6.0 LTS hasta octubre de 2026** (es decir, **caduca este mes: migrar ya**). LTS
  anual con **dos años** de soporte; las *Update releases* solo se soportan **hasta que sale la
  siguiente**. Producción en vivo → LTS; producción a medio ciclo → Update.
- **Unreal Engine**: modelo de **royalty del 5 % sobre los ingresos brutos de por vida que superen
  1 000 000 USD por producto**, con exclusión de las ventas en la Epic Games Store, y un **modelo de
  puestos** (*Unreal Subscription*, introducido con UE 5.4, del orden de **1 850 USD/puesto/año**)
  para uso **no-juego** en empresas por encima de 1 M USD. **⚠ Este bloque NO está verificado
  verbatim**: `unrealengine.com/eula/unreal` y `/license` devuelven **403** a cualquier acceso
  automatizado (ver §8). **Antes de firmar nada, leer el EULA en el navegador y confirmar
  porcentaje, umbral, base de cálculo (bruto antes de la comisión de tienda) y exclusiones.**
- **Unreal, versiones**: **UE 5.8 (junio de 2026)** es la última entrega mayor planificada de la
  línea UE5; **UE6 apunta a Early Access a finales de 2027** (fuente: cobertura de State of Unreal
  2026 vía búsqueda web; **no verbatim** — confirmar antes de planificar una migración).
- **Godot**: **MIT**, verbatim de `LICENSE.txt` en `master`: *«Permission is hereby granted, free of
  charge, to any person obtaining a copy of this software … to deal in the Software without
  restriction»*. **Sin royalties, sin umbrales de ingresos, sin puestos.** Última estable verificada
  por el feed Atom de releases: **4.7.1-stable**. El precio se paga en madurez de herramientas, 3D
  de gama alta y soporte de consola (que llega por terceros, no por el proyecto).
- **Regla de gobierno**: la licencia del motor es una **decisión de puerta de un solo sentido** a
  mitad de producción. Se documenta en un ADR con **la versión exacta de los términos aceptados** y
  la cláusula de continuidad (Unity se comprometió a que quien siga en una versión conserva los
  términos de esa versión: **verificar que sigue vigente**). Guardar copia fechada del EULA.

## 3. Estructura y convenciones

**Bucle de juego — el reparto no negociable.** Simulación a **paso fijo**, render a paso variable,
interpolación entre estados para dibujar:

```
acumulador += dt_real (acotado: nunca más de N pasos por fotograma → "espiral de la muerte")
mientras acumulador >= dt_fijo:  simular(dt_fijo); acumulador -= dt_fijo
render(alpha = acumulador / dt_fijo)   // interpolar estado previo→actual
```

- **Física y lógica de gameplay determinista van en el paso fijo** (`FixedUpdate`,
  `_physics_process`, `Tick` de física). Entrada, cámara, animación y UI van en el variable.
- **PROHIBIDO** multiplicar por `deltaTime` dentro del paso fijo o meter lógica de física en el paso
  variable: es la causa de "en un PC rápido el personaje salta más alto".
- El `dt_real` **se acota siempre** (p. ej. 0,25 s): sin tope, un pico de carga genera más pasos de
  simulación, que generan más carga, que generan más pasos.

**Memoria.** El recolector de basura y el asignador son la primera fuente de picos de p99.

- **Cero asignaciones en el bucle caliente.** En C#: nada de LINQ, `string` concatenado, *boxing*,
  *lambdas* que capturan, `foreach` sobre colecciones que asignan enumerador, ni `GetComponent` por
  fotograma. En C++: nada de `new`/`shared_ptr` por fotograma; arenas y *pools*.
- ***Pooling*** para todo lo que nace y muere en cadena: proyectiles, partículas, enemigos, entradas
  de UI, efectos de sonido. El *pool* se dimensiona al **peor caso medido**, no al típico, y se
  precalienta en la carga, no en el primer disparo.
- Presupuesto de memoria **por plataforma** y fallo de build si se supera. La consola no tiene
  *swap*: pasarse no degrada, mata el proceso.

**Datos y ECS.** ECS (Unity Entities/DOTS, `flecs`, `bevy_ecs`) aporta de verdad cuando hay **muchas
entidades homogéneas actualizándose cada fotograma** —miles de unidades, proyectiles, partículas,
*boids*— y el cuello es el recorrido de memoria y los fallos de caché. **No aporta** en un juego de
pocas entidades heterogéneas con lógica de guion: ahí paga complejidad, *tooling* peor, depuración
peor y contratación peor a cambio de nada. **Regla**: se adopta ECS **sobre el subsistema medido que
lo necesita**, no sobre el proyecto entero, y se justifica con el perfilado que lo motivó.

**Carga y *streaming*.** El objetivo es que **nunca se cargue nada síncrono en un fotograma de
juego**. Todo asset se carga por referencia indirecta y asíncrona (Addressables, *asset registry* y
*soft references* en Unreal, `ResourceLoader.load_threaded_request` en Godot), con
*streaming* por celdas/niveles y presupuesto de E/S por fotograma. Cargar por ruta y en caliente es
el origen clásico del *hitch* al entrar en una zona.

**Organización del repo.** Carpetas por *feature*, no por tipo de asset, cuando el equipo crece;
convención de nombres estable y automatizada (el importador y el *build* dependen de ella); **nada
generado se commitea** (`Library/`, `Temp/`, `Intermediate/`, `Saved/`, `DerivedDataCache/`,
`.godot/`). En Unity, **los `.meta` sí se commitean siempre** y `ProjectSettings/` va bajo control
de versiones y bajo revisión: cambiar ahí es cambiar el build.

**Binarios grandes.** Un `.psd`, un `.fbx` o un `.uasset` **no se fusionan**. Dos opciones:

- **Git + LFS**: viable si el arte es moderado y el equipo es técnico. Exige `.gitattributes`
  disciplinado desde el commit 1, política de *pruning* y saber que **el historial de LFS crece sin
  límite**. El bloqueo de fichero de LFS existe pero es frágil frente a un equipo de artistas.
- **Perforce (P4/Helix Core)**: sigue vivo en la industria por dos razones concretas que Git no
  cubre bien: **bloqueo exclusivo (*checkout*) de binarios** y **sincronización parcial de un
  depósito enorme sin clonar el historial**. Verificado en `perforce.com` (ago-2026): *«Perforce P4
  is free for up to 5 users and 20 workspaces»* — el nivel gratuito cubre a un equipo pequeño; a
  partir de ahí es coste y administración. Cuidar el `typemap` (binarios como `binary+l`) desde el
  día 1.
- **Regla**: la decisión la manda **quién toca los ficheros**, no la preferencia del equipo de
  programación. Si hay artistas a jornada completa, se elige por ellos.

## 4. Calidad y testing

- **Determinismo primero**: la lógica de simulación se separa de la presentación para poder
  **probarla sin motor**. Si no se puede ejecutar un paso de simulación en un test unitario, el
  diseño está acoplado a `MonoBehaviour`/`AActor` y hay que extraerlo.
- **Tests de reproducción de partida** (*replay*): grabar entradas + semilla, reproducir y comparar
  el estado final. Es el test de regresión más rentable del dominio: detecta desincronización,
  dependencia del *frame rate* y aleatoriedad no controlada.
- **Aleatoriedad**: PRNG propio con semilla explícita y estado por sistema. **PROHIBIDO** usar el
  aleatorio global del runtime en lógica que deba reproducirse o sincronizarse.
- **Tests de rendimiento como gate**: escena de referencia + recorrido fijo (*flythrough*) ejecutado
  en CI sobre hardware representativo, con **umbral en p99 de ms**, no en media. Rompe el build.
- **Presupuestos automáticos**: número de *draw calls*, triángulos, memoria de texturas, tamaño del
  paquete y tiempo de carga por nivel, verificados en el pipeline de assets.
- **Perfilado con la herramienta del motor** (Unity Profiler/Profile Analyzer, Unreal Insights,
  Godot Profiler) **en build de release sobre el dispositivo objetivo**. Perfilar en el editor, en
  el PC del programador, mide otra cosa. RenderDoc/PIX para el lado GPU.
- Orden de coste creciente en CI: análisis estático y reglas de proyecto → tests unitarios de
  simulación → *replays* deterministas → build por plataforma → escena de rendimiento → *smoke test*
  automatizado en dispositivo → sesión de QA manual y *playtest*.
- **QA es una función, no una fase**: bordes obligatorios en el plan de prueba — pérdida de foco,
  desconexión en mitad de la carga, disco lleno al guardar, mando desconectado, alt-tab, suspensión
  de consola, cambio de resolución, dos jugadores con el mismo nombre, reloj del sistema alterado.

## 5. Seguridad del stack

**Regla dura del multijugador: nunca confiar en el cliente.** El cliente está en manos del atacante:
su memoria es editable, su tráfico es interceptable y su binario es desensamblable. De ahí:

- El **servidor es la única autoridad** sobre estado, daño, inventario, moneda, colisión y
  resultado. El cliente **propone entrada**, no resultados. Cualquier mensaje del tipo "he matado a
  X" o "tengo Y oro" es un fallo de diseño, no un fallo de validación.
- **Validar en servidor** todo: rango de movimiento por tick (*speed hack*), línea de visión y
  distancia al disparar, cadencia, propiedad del objeto que se usa, precio de la transacción.
- **No enviar lo que el cliente no debe saber**: la posición del enemigo tras la pared es un
  *wallhack* servido por el propio servidor. *Culling* de interés (AoI) **por seguridad**, no solo
  por ancho de banda.
- **Predicción y reconciliación**: el cliente predice para ocultar la latencia, el servidor corrige
  y el cliente re-simula desde el último estado confirmado. La compensación de retardo (*lag
  compensation*) rebobina el estado del servidor al instante del disparo del atacante: es correcto
  competitivamente y **hay que documentarlo**, porque genera el "me han matado detrás de la
  esquina".
- **Determinismo en punto flotante**: dos máquinas con distinto compilador, distinta CPU, distintas
  optimizaciones (`-ffast-math`, FMA, SIMD) o distinto orden de iteración **pueden divergir bit a
  bit**. Por eso el multijugador determinista (*lockstep*) es difícil: exige aritmética de punto fijo
  o una biblioteca determinista, orden de iteración estable, misma versión de motor en todos los
  extremos y prohibición de usar el estado de la presentación en la simulación. Si no se puede
  garantizar, **no se elige *lockstep***: se elige autoridad de servidor con estado replicado.
- **Anticheat**: la detección en cliente es una carrera de armamento perdida a plazo largo. Orden
  correcto: (1) diseño con autoridad de servidor, (2) detección **estadística en servidor** sobre
  telemetría (precisión imposible, tiempos de reacción, trayectorias), (3) solo después, cliente.
  El anticheat **en modo núcleo** (kernel) compra detección a un precio alto y explícito: es un
  driver privilegiado en la máquina del jugador —superficie de ataque, riesgo de pantallazo azul,
  rechazo de la comunidad, incompatibilidad con Linux/Steam Deck y con máquinas virtuales— y una
  **cuestión de privacidad que hay que declarar** (`privacy-engineering-standards`). Se decide en un
  ADR con el coste de soporte contabilizado, nunca por defecto.
- **Superficie clásica**: deserialización de partidas guardadas y de *mods* (código ejecutable desde
  fichero de usuario → sandbox o firma), *replays* y niveles de la comunidad como entrada no
  confiable, servidores de partida expuestos sin límite de tasa (amplificación UDP), y claves de API
  de servicios (analítica, tiendas, backend) **embebidas en el binario del cliente**: cualquier clave
  que viaje en el cliente **está publicada**.
- **Cuentas y tiendas**: la compra la valida el servidor contra la tienda (recibo verificado en
  servidor); nunca el cliente. Los *webhooks* de tienda se verifican por firma.
- **Menores**: si el juego es accesible a menores, la telemetría, la publicidad, el chat y los datos
  personales entran en un régimen distinto (COPPA en EE. UU., RGPD y protección reforzada del menor
  en la UE, verificación de edad). **No se recoge lo que no se necesita**; el chat abierto exige
  moderación y denuncia. Diseño y base legal → `privacy-engineering-standards`.

## 6. Rendimiento y operabilidad

- **Métrica de producto**: histograma de tiempo de fotograma con **p50/p95/p99/p99.9** y conteo de
  fotogramas por encima del presupuesto, **por plataforma y por escena**. Los fps medios solo valen
  para el marketing.
- **Telemetría de rendimiento en producción**, con consentimiento y anonimizada: modelo de
  dispositivo, GPU, distribución de tiempo de fotograma, tiempos de carga, cierres inesperados. Sin
  esto no se sabe qué está roto en el hardware que no tienes.
- **Presupuesto por subsistema** publicado (p. ej. a 16,6 ms: X ms de simulación, Y de animación, Z
  de preparación de render) y vigilado en CI: sin reparto, cada equipo consume el margen del otro.
- **Causas típicas de *hitch*** en orden de frecuencia real: recolección de basura, carga síncrona de
  assets, **compilación de shaders en caliente** (precompilar/*warm-up* de PSO obligatorio), primer
  uso de un sistema no precalentado, E/S de guardado en el hilo principal, y *spike* de instanciación.
- **Escalabilidad de calidad**: niveles de detalle y opciones de calidad que se puedan degradar por
  dispositivo, con detección conservadora. Ningún juego rinde igual en todo el catálogo de PC.
- **Build y plataformas**: *build once* por plataforma en CI, artefacto versionado y firmado, y
  matriz de plataformas objetivo declarada desde el principio (cambiar de objetivo a mitad es un
  coste de proyecto, no de sprint). Compilación de assets determinista y caché compartida.
- **Certificación de consola**: cada fabricante impone requisitos técnicos propios (TRC/TCR/lotcheck
  y equivalentes) sobre suspensión y reanudación, gestión de usuarios y cierres de sesión, guardado y
  espacio insuficiente, mandos desconectados, nomenclatura de la UI, tiempos de arranque y trofeos.
  **Se leen al inicio del proyecto y se prueban durante el desarrollo, no en la semana de la
  entrega**: fallar cert reinicia un ciclo de días o semanas. Su contenido está bajo NDA del
  fabricante y **no se reproduce aquí**: se consulta en el portal de desarrollador correspondiente.
- **Post-lanzamiento**: parches y contenido descargable con compatibilidad de partidas guardadas
  (versionar el formato de guardado desde la v1 y migrar hacia adelante), *feature flags* de servidor
  para desactivar contenido roto sin publicar parche, y ventana de mantenimiento comunicada.

**Accesibilidad de juego** — es requisito de producto, no cortesía. Mínimos exigibles:

- **Remapeo completo** de controles (teclado, ratón y mando), incluidos los *quick-time events*;
  alternativa a mantener pulsado (*toggle* frente a *hold*) y a pulsar repetidamente (*mashing*).
- **Subtítulos** legibles por defecto: tamaño ajustable, fondo opaco opcional, nombre del hablante y
  **subtitulado de efectos relevantes** para jugabilidad; separación entre volumen de voz, efectos y
  música.
- **Movimiento y visión**: opciones de reducción de sacudida de cámara y de destellos, ajuste de
  campo de visión, desactivación del *motion blur*; evitar patrones de riesgo fotosensible.
- **Color y contraste**: nunca información **solo** por color; paletas alternativas y contraste
  ajustable en la UI; escala de la interfaz.
- **Dificultad y asistencia** como opciones separadas (puntería asistida, invulnerabilidad, saltar
  puzles) sin castigo social ni bloqueo de contenido.
- Etiquetas y *badges* de accesibilidad de tienda: se declaran con lo que realmente existe.

**i18n**: texto fuera del código y de la textura desde el día 1, longitud variable prevista en la UI
(el alemán y el ruso crecen; el japonés no rompe línea igual), fuentes con cobertura de glifos y
atlas dimensionado, soporte RTL si aplica, doblaje y sincronía labial como coste de producción, y
pseudolocalización en QA. Criterio y proveedor → `i18n-standards`.

**Monetización y regulación** — verificar el estado antes de diseñar la economía:

- **Cajas de botín**: **Bélgica** las considera juego de azar desde 2018 y las prohíbe de facto
  (**verificar el estado y el alcance actual**). En **España** existe desde 2022 un **anteproyecto de
  ley de regulación de los mecanismos aleatorios de recompensa** (Ministerio de Consumo/DGOJ) con
  verificación de identidad para menores y restricciones de publicidad: **a agosto de 2026 no consta
  que haya llegado a ley** — comprobarlo, no asumirlo (§8). En la **UE**, la **Digital Fairness Act**
  es la pieza que puede prohibir o restringir cajas de botín, monedas virtuales y diseño adictivo
  para menores: a agosto de 2026 es **propuesta esperada, no derecho vigente**.
- **PEGI** ya publica descriptores específicos verificables en `pegi.info`: **«Paid random items»**,
  **«In-game purchases»**, **«Pressure to play»**, **«Time-limited offers»** y **«Cryptocurrency»**.
  Diseñar con ellos en mente: el descriptor afecta a la clasificación y a la tienda.
- Criterios de ingeniería que sobreviven a cualquier regulación: **publicar las probabilidades**,
  **mostrar el precio en dinero real** junto a la moneda virtual, **no encadenar monedas** para
  ocultar el coste, **no dirigir ofertas temporales a cuentas de menores**, y guardar registro
  auditable de cada transacción y de cada tirada (semilla, resultado, saldo) para poder responder a
  una reclamación o a un regulador.

## 7. Sostenibilidad a largo plazo

- **Cadencia de motor**: se sube de versión **mayor** entre proyectos, no a mitad de producción;
  dentro de un proyecto solo se aplican parches de la misma LTS, con la versión **fijada** en el
  repo y en CI. Toda subida se prueba con los *replays* deterministas y con la escena de rendimiento.
- **Fin de soporte**: seguir en una versión sin soporte es aceptable solo si el juego está cerrado y
  no recibe contenido; si sigue vivo, la subida se planifica con antelación (ver el caso de Unity 6.0
  LTS caducando en octubre de 2026).
- **Dependencias**: cada paquete del *Asset Store*/Marketplace/AssetLib es una dependencia con
  licencia, mantenimiento y superficie de seguridad. Se auditan igual que cualquier librería
  (`opensource-licensing-standards`); **PROHIBIDO** integrar assets de terceros sin registrar
  licencia y versión.
- **Documentar el "por qué" con ADR**: motor y versión de sus términos, modelo de red, ECS sí/no,
  anticheat, VCS, plataformas objetivo.

**Prohibiciones explícitas:**

- ❌ **Fijar objetivos o celebrar mejoras en fps medios.** El presupuesto se expresa en **ms** y se
  mide en **percentiles**.
- ❌ **Confiar en cualquier dato que venga del cliente** en un juego con competición, economía o
  progresión compartida. Sin excepciones "porque es cooperativo".
- ❌ Lógica dependiente del *frame rate*: nada de física en `Update`, ni de `deltaTime` dentro del
  paso fijo, ni de bucles de simulación sin acotar el acumulador.
- ❌ Asignar memoria, cargar assets, compilar shaders o tocar el disco **en el bucle caliente**.
- ❌ `GameObject.Find`, `GetComponent`, búsqueda por etiqueta/nombre o `Blueprint tick` con lógica
  pesada por fotograma. Se resuelve en la carga y se cachea.
- ❌ `Debug.Log`/`UE_LOG` verboso en el bucle de release: no es gratis.
- ❌ Aleatoriedad global no sembrada en lógica de juego, y `System.Random`/`rand()` compartido entre
  hilos.
- ❌ **Anticheat en modo núcleo por defecto**, sin ADR, sin evaluar el coste en privacidad, soporte y
  compatibilidad con Linux/Steam Deck.
- ❌ Claves de API, secretos de backend o credenciales de tienda **en el binario del cliente**.
- ❌ Commitear artefactos generados (`Library/`, `Intermediate/`, `Saved/`, `.godot/`) o binarios
  grandes sin LFS/Perforce configurado antes del primer commit. Arreglarlo después implica reescribir
  historia.
- ❌ Repositorio sin `.meta` de Unity versionados: rompe referencias para todo el equipo.
- ❌ Dejar la accesibilidad, la localización y la certificación de consola **para el final**. Las
  tres son restricciones de arquitectura, no de pulido.
- ❌ Guardado sin versión de formato y sin ruta de migración.
- ❌ Diseñar economía con azar de pago **sin publicar probabilidades** ni precio en dinero real, o
  dirigirla a cuentas de menores.
- ❌ Motor propio "porque tendremos más control" sin un requisito que ningún motor comercial cubra,
  contabilizando el coste de editor, pipeline de assets, port a consola y contratación.
- ❌ Adoptar ECS/DOTS en todo el proyecto por moda, sin perfilado que lo motive.
- ❌ Copiar de un foro las condiciones de licencia de Unity o Unreal. **Se leen en la fuente y se
  archivan fechadas.**

## 8. Verificación web obligatoria

Antes de decidir, comprobar en la fuente primaria (y **no** en foros ni en resúmenes de terceros):

1. **Unity**: `unity.com/pricing` y los *Unity Terms of Service* — umbrales de Personal/Pro/
   Enterprise/Industry, precio por puesto, y si la cláusula de continuidad por versión sigue vigente.
   Versiones y soporte en `unity.com/releases` (Unity 6.0 LTS caduca en **octubre de 2026**).
2. **Unreal**: `unrealengine.com/eula/unreal` y `unrealengine.com/license` **leídos en navegador**.
   **Hueco declarado**: ambos devuelven **HTTP 403** a acceso automatizado, y el intento de recuperar
   una copia archivada devolvió **429**; el porcentaje (5 %), el umbral (1 M USD de ingresos brutos
   de por vida por producto), la exclusión de la Epic Games Store, el 3,5 % de *Launch Everywhere
   with Epic* y el precio por puesto de *Unreal Subscription* proceden de **búsqueda web, no de
   texto verbatim del EULA**. Verificarlos antes de firmar o presupuestar.
3. **Unreal, hoja de ruta**: que UE 5.8 (jun-2026) sea la última mayor de UE5 y que UE6 apunte a
   Early Access a finales de 2027 procede de cobertura de prensa vía búsqueda; confirmar en el sitio
   de Epic antes de planificar migración.
4. **Godot**: `LICENSE.txt` en el repositorio (MIT) y la última estable en el feed de releases
   (4.7.1-stable a ago-2026); estado del soporte de consola por terceros.
5. **Perforce/P4**: límites del nivel gratuito (verificado: *«free for up to 5 users and 20
   workspaces»*) y precio del siguiente escalón.
6. **Regulación de cajas de botín**: estado del **anteproyecto español** (¿sigue siendo anteproyecto,
   se aprobó, se retiró?), estado de la **Digital Fairness Act** en la UE (propuesta, trílogos,
   entrada en vigor) y el alcance real de la prohibición **belga**. **Los tres eran datos en
   movimiento en la fecha de verificación.** Contrastar con BOE/EUR-Lex, no con prensa.
7. **PEGI**: lista vigente de descriptores y su efecto en la clasificación (`pegi.info`).
8. **Plataformas**: requisitos de certificación y SDK vigentes en el portal de cada fabricante (bajo
   NDA), y política de tienda de móvil (`mobile-standards`).
9. **CVEs y avisos** del motor y de los paquetes de terceros integrados; cadencia de parches.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
