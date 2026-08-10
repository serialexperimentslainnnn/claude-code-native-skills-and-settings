---
name: xr-standards
description: Virtual, augmented and mixed reality engineering where comfort, latency and biometric privacy are hard requirements. Use when building with OpenXR (xrCreateInstance, XrSession, XrSpace, xrWaitFrame/xrBeginFrame/xrEndFrame, XR_KHR_composition_layer_depth, XR_EXT_hand_tracking, XR_EXT_eye_gaze_interaction, XR_EXT_plane_detection, XR_EXT_spatial_anchor, vendor XR_FB_/XR_META_/XR_ANDROID_ extensions), Unity XR Interaction Toolkit and OpenXR plugin, Unreal VR templates and OpenXR runtime, Godot XR, or WebXR (navigator.xr, requestSession("immersive-vr"/"immersive-ar"), XRReferenceSpace, hit-test and anchors), motion-to-photon latency, reprojection, timewarp, Application SpaceWarp and stale frames, headset refresh rates and per-frame budget on standalone hardware, locomotion, teleport, snap turn, vignette and simulator sickness, room-scale guardian and boundary, seated versus standing play, hand tracking versus controllers, raycast interaction, gaze and pinch, passthrough and scene understanding, spatial anchors and a persisted 3D mesh of the user's home, eye or face tracking data and emotion inference under the EU AI Act, Quest store VRC submission checks, or spatial audio and spatial subtitles.
---

# Estándares de XR (realidad virtual, aumentada y mixta)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio de ingeniería sobre **construir una aplicación que se lleva puesta en la cabeza**:
presupuesto de fotograma y latencia, confort y cinetosis como requisito funcional, API estándar
frente a extensión de fabricante, interacción con manos y mandos, accesibilidad en un medio que
asume un cuerpo concreto, y **la privacidad de los datos que solo existen en XR** —mirada, cara,
cuerpo y un mapa tridimensional del domicilio del usuario—.

**Eje del dominio: el confort y la seguridad no son pulido, son requisito funcional.** En una
pantalla, un fotograma perdido es una molestia; en la cabeza, **es un síntoma físico**. Un juego con
malas físicas se juega mal; una aplicación de XR que provoca mareo **no se usa**, se quita uno el
casco y no vuelve. Por eso el orden de prioridades es rígido y no se negocia con el diseño:

1. **Tasa de fotogramas estable dentro del presupuesto del dispositivo** — no "alta de media".
2. **Latencia movimiento-fotón mínima**: la imagen debe responder a la cabeza antes que el oído
   interno note el desfase.
3. **Ninguna aceleración impuesta al usuario**: ni de cámara, ni de horizonte, ni de escala.
4. Y solo después: fidelidad visual, contenido y funcionalidad.

**Regla de oro, la que más se incumple: no muevas la cámara del usuario sin que el usuario lo haya
hecho.** Nada de cinemáticas que giran la cabeza, ni de sacudidas de cámara, ni de retroceso de
arma que rota la vista, ni de "smooth" impuesto al colisionar, ni de fundido que arrastra el
horizonte. El vector de la cinetosis es el **conflicto entre lo que el ojo ve y lo que el oído
interno siente**; cualquier movimiento que el cuerpo no ha ordenado es una dosis de ese conflicto.

**La reproyección es una red de seguridad, no un plan.** *Timewarp*/*reprojection* y sus variantes
(*Application SpaceWarp* y equivalentes) salvan un fotograma perdido ocasional generando uno
sintético a partir del anterior; usados como presupuesto de diseño producen artefactos visibles
(estelas, bordes desgarrados, fantasmas en objetos rápidos) y no arreglan la latencia de la
simulación. **Se diseña para cumplir el presupuesto sin ellos.**

Triggers: `xrCreateInstance`, `XrSession`, `XrSpace`, `xrWaitFrame`, `xrEndFrame`,
`XR_EXT_hand_tracking`, `XR_EXT_eye_gaze_interaction`, `XR_EXT_plane_detection`,
`XR_EXT_spatial_anchor`, `XR_FB_*`/`XR_META_*`/`XR_ANDROID_*`, `com.oculus.permission.USE_SCENE`,
`XRInteractionManager`, `XROrigin`, `navigator.xr`, `requestSession('immersive-vr')`,
`XRReferenceSpace`, `local-floor`, `hit-test`, OVR Metrics Tool, *stale frames*, VRC de tienda, y
los síntomas: "marea", "se ve a tirones al girar la cabeza", "las manos van con retraso", "no
detecta el suelo", "el rechazo del casco a los 10 minutos".

**No aplica**: ver `game-development-standards` (**lote 22, hermana directa y frontera principal**:
**el motor, el bucle de juego, el paso fijo, ECS, el *pooling*, el *streaming* de assets, el
multijugador con autoridad de servidor, el control de versiones de binarios, la certificación y la
monetización son suyos**. **Aquí lo que cambia por llevarlo puesto**: presupuesto y estabilidad por
dispositivo, confort, locomoción, interacción espacial, accesibilidad de XR y privacidad
biométrica. Regla de arbitraje: *si la respuesta sería la misma en una pantalla plana, es de
`game-development`; si cambia porque el usuario tiene el aparato en la cabeza, es de aquí*),
`webgl-webgpu-standards` (**el navegador y la API gráfica son suyos sin excepción**: WebGL2/WebGPU,
WGSL/GLSL, three.js/Babylon, pérdida de contexto, texturas comprimidas. **WebXR se apoya en ellos:
aquí el modelo de sesión, los espacios de referencia, la entrada y el confort; allí lo que se
dibuja y cuánto cuesta**), `computer-vision-standards` (**SLAM, seguimiento *inside-out*,
reconstrucción, detección de planos y de marcadores, y cualquier modelo de percepción son suyos**;
aquí solo **consumir** el resultado que expone el runtime —anclas, mallas, planos— y las
obligaciones que trae ese dato), `mobile-standards` (empaquetado Android, permisos, ciclo de vida
de app y política de tienda; un casco autónomo es un Android con reglas propias), `cpp-standards` /
`c-standards` (el lenguaje del *loader* y de las extensiones), `dotnet-standards` (C# fuera de
Unity), `accessibility-standards` (**el criterio de conformidad WCAG, EN 301 549 y su alcance legal
es suyo**; **aquí lo que WCAG no cubre**: altura, alcance, mano dominante, sentado/de pie, subtítulo
espacial), `i18n-standards` (traducción, formatos y proveedor; aquí solo el coste espacial del
texto), `privacy-engineering-standards` (**la disciplina de privacidad —base legal, DPIA,
minimización, derechos del interesado, retención— es suya, íntegra**. **Aquí solo el hecho
diferencial de XR**: qué sensores existen, qué se deriva de ellos y qué se prohíbe capturar. Un
tratamiento de datos de mirada se **diseña** con esta skill y se **gobierna** con la suya),
`ai-governance-standards` (**el AI Act como marco de cumplimiento —inventario, roles de proveedor y
responsable del despliegue, evaluaciones, gobernanza— es suyo**; aquí solo el disparador concreto:
inferencia de emociones a partir de biometría), `deep-learning-standards` y
`local-inference-standards` (entrenar y servir modelos), `performance-engineering-standards`
(metodología de perfilado), `gaming-infrastructure-standards` (servidores y sesiones
multiusuario), `frontend-web-platform-standards` (la página que aloja la experiencia WebXR),
`embedded-iot-standards` (el dispositivo como objeto físico; aquí se asume hardware ajeno).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión, el catálogo de dispositivos vigente y sus tasas de refresco por web
> antes de fijarlas en un proyecto real (§8). **El catálogo de hardware de XR rota rápido y las
> cifras de ventas que circulan no son verificables: no se citan.**

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| API de dispositivo | **OpenXR** | SDK propietario | Estándar Khronos; evita reescribir por fabricante |
| Extensiones de fabricante | Solo tras degradación probada | — | Cada `XR_FB_`/`XR_META_` es acoplamiento |
| Motor | Unity + XR Interaction Toolkit / Unreal / Godot XR | Nativo con OpenXR + Vulkan | Herramientas e interacción resueltas |
| Objetivo de rendimiento | **ms de p99 dentro del presupuesto del dispositivo** | — | El fotograma perdido se nota en el cuerpo |
| Locomoción por defecto | **Teleporte + giro por pasos (*snap turn*)** | Continua **como opción** con viñeteado | Menor conflicto vestibular |
| Marco de referencia | `local-floor`/*stage* con calibración de altura | `local` sentado | Escala y suelo correctos |
| Entrada | **Mandos** como camino primario | Manos como alternativa | Fiabilidad, precisión y fatiga |
| Interacción a distancia | *Raycast* con retroalimentación clara | Interacción directa (cerca) | Ergonomía del alcance |
| Mirada como entrada | **Solo con confirmación explícita** | — | La mirada no es una intención |
| Datos de mirada/cara | **No salen del dispositivo** | Nunca por defecto | Biometría §5 |
| Web | **WebXR** cuando basta y el alcance manda | Nativo cuando manda el rendimiento | Distribución sin tienda |
| Reproyección | Red de seguridad | — | No es presupuesto de diseño |

**Estado verificado del estándar (agosto de 2026):**

- **OpenXR** publica su especificación en la línea **1.1** (`registry.khronos.org/OpenXR/`: *«OpenXR
  1.1 API Specifications (also applies to 1.0 development)»*; la 1.0.34 aparece marcada como
  *Obsolete*). Última entrega del SDK verificada por el feed Atom de releases: **OpenXR SDK
  1.1.62**.
- **Qué queda fuera del estándar, con cifra y método**: contando las extensiones declaradas en el
  registro oficial `specification/registry/xr.xml` (rama `main` de `OpenXR-SDK`, excluidos los
  huecos reservados del tipo `XR_META_extension_NNN`), hay **261 extensiones con nombre real**, de
  las cuales solo **35 son `XR_KHR_`** y **38 `XR_EXT_`** (multi-fabricante). Las **188 restantes son
  de fabricante**: `XR_FB_` 41, `XR_META_` 34, `XR_ANDROID_` 27, `XR_BD_` 16, `XR_MSFT_` 15,
  `XR_ML_` 13, `XR_HTC_` 9, `XR_VARJO_` 7, `XR_QCOM_` 6… **Lectura**: OpenXR estandariza bien el
  núcleo —sesión, espacios, capas, entrada, ciclo de fotograma— y **casi todo lo diferencial
  (passthrough, malla de escena, seguimiento de cara y cuerpo, anclas compartidas, *depth*) sigue
  llegando por extensión de fabricante**. Portabilidad real = núcleo estándar + capa de abstracción
  propia sobre lo que se use por extensión + **degradación probada** cuando la extensión no está.
- **WebXR Device API**: **W3C Candidate Recommendation Draft de 9 de junio de 2026**
  (`w3.org/TR/webxr/`). Es decir: estándar en curso, no Recomendación; el soporte por navegador y
  plataforma **se comprueba antes de prometerlo**, y los módulos (AR, *hit test*, anclas, capas,
  manos) van por especificaciones separadas con madurez distinta.
- **Presupuesto de fotograma por dispositivo — dato normativo verificado.** Requisito de tienda de
  Meta `VRC.Quest.Performance.1` (actualizado 22-oct-2025), verbatim: *«The app must run at an
  allowed refresh rate and maintain a rendering rate (fps) of at least 60 fps»*, *«Interactive
  applications must use a refresh rate of 72 Hz, 80 Hz, 90 Hz, 96 Hz, 100 Hz or 120 Hz (96 Hz, 100
  Hz, and 120 Hz not available on all devices)»* y *«Media applications may use a refresh of 60 Hz
  on devices that support 60 Hz»*. La guía de rendimiento para Unity del mismo fabricante afirma
  además: *«Interactive applications must achieve a minimum of 72 FPS»*. **Traducción a
  presupuesto**: 72 Hz → **13,9 ms**; 80 Hz → 12,5 ms; 90 Hz → **11,1 ms**; 120 Hz → 8,3 ms **por
  fotograma, para todo** (simulación, física, animación, culling, dos ojos de render, composición,
  audio, red). Y **por ojo**: el coste de render se paga dos veces salvo que se use render de una
  sola pasada (*single-pass instanced*/*multiview*), que es el ajuste por defecto correcto.
- **Excepción documentada**: el mismo VRC permite *«a rendering rate (fps) of half the refresh rate
  (such as … 36 fps for 72 Hz), for portions of their experience utilizing Application SpaceWarp»*
  y exige generar vectores de movimiento que minimicen los artefactos. **Es una excepción con
  condiciones, no una licencia para diseñar a medio presupuesto.**
- **Otros fabricantes**: cada tienda tiene su propio pliego equivalente. **No se asume que el de uno
  valga para el otro**: se lee el del destino antes de fijar el objetivo (§8).

## 3. Estructura y convenciones

**Bucle y sincronización.** El ciclo de OpenXR (`xrWaitFrame` → `xrBeginFrame` → render →
`xrEndFrame`) lo gobierna **el runtime**, no la aplicación: `xrWaitFrame` es quien decide cuándo
empezar y entrega el `predictedDisplayTime`. Reglas:

- **Toda pose se consulta para el tiempo de visualización predicho**, no para "ahora". Usar la pose
  del fotograma anterior o el reloj del sistema introduce latencia y *judder*.
- **Nunca bloquear el hilo de render**: carga de assets, red, decodificación y física pesada van
  fuera. Un bloqueo de 30 ms es un fotograma perdido, y un fotograma perdido es un tirón en la
  cabeza.
- **Entregar siempre las capas de composición con profundidad correcta** (`XR_KHR_composition_layer_depth`
  cuando esté disponible): la reproyección funciona mucho mejor con profundidad.
- **La UI no se pega a la cara.** Interfaz anclada al mundo o al cuerpo, a distancia cómoda de
  lectura, con texto de tamaño angular suficiente. La UI fija a la cabeza (*head-locked*) provoca
  mareo y es la marca del port perezoso desde pantalla plana.

**Espacios de referencia y escala.** Declarar explícitamente qué se usa (`local`, `local-floor`,
`stage`/*bounded*) y **respetar la escala 1:1**: un metro virtual es un metro real. Cambiar la
escala del mundo o la separación interpupilar sin motivo rompe la percepción de profundidad y marea.
El límite de juego (*guardian*/boundary) es una funcionalidad de **seguridad física**: nunca
ocultarlo, nunca incitar a salirse de él, prever el caso de espacio pequeño.

**Locomoción — catálogo con criterio:**

- **Teleporte** con indicación de destino: el más cómodo, casi sin conflicto vestibular. Por defecto.
- **Giro por pasos** (30°/45°) frente a giro continuo: por defecto los pasos; el continuo, opción.
- **Locomoción continua**: solo como **opción activable**, con **viñeteado dinámico** (reducir el
  campo de visión periférico mientras hay movimiento), velocidad constante y **sin aceleración**
  (la aceleración es lo que marea, no la velocidad), sin *strafe* combinado con giro.
- **Marco estático de referencia** (cabina, nariz virtual, rejilla o marco fijo respecto al cuerpo)
  cuando hay movimiento inevitable: reduce el conflicto al dar al ojo una referencia que no se
  mueve. Es el motivo de que los simuladores de conducción/vuelo sean cómodos.
- **Prohibido siempre**: escaleras/rampas que balancean la cámara, *head bobbing*, movimiento
  vertical no ordenado, caída libre larga, y quitar el control de la vista al usuario.
- **Todo lo anterior se ofrece como ajuste**, con valores por defecto conservadores y accesibles en
  cualquier momento **sin salir de la aplicación**.

**Interacción.**

- **Mandos** para lo que exige precisión, retroalimentación háptica y baja fatiga. **Manos** para
  interacción social, breve o sin accesorio: el seguimiento falla con oclusión, con poca luz y fuera
  del campo de las cámaras, así que **toda interacción con manos necesita camino alternativo** y
  tolerancia a la pérdida de seguimiento.
- ***Gorilla arm* es un requisito de diseño**: nada de mantener el brazo en alto ni de gestos
  repetidos; interacciones cortas, a la altura del pecho, con descanso.
- **Retroalimentación multimodal**: todo objetivo apuntado se resalta, toda acción confirma con
  sonido y/o háptica. En XR, sin retroalimentación el usuario no sabe si el sistema lo ha oído.
- **La mirada no es un clic.** Con seguimiento ocular, la mirada puede seleccionar pero **confirma
  otro gesto** (pinza, botón). El *dwell* (mantener la mirada) solo como accesibilidad explícita.
- **Zona de confort**: contenido interactivo dentro del alcance sin desplazarse; nada crítico por
  encima de la cabeza, por debajo de la cintura ni detrás del usuario. Si algo importante está
  fuera del campo de visión, hay que **indicarlo** (audio espacial, flecha, halo).

**Audio espacial** como parte de la simulación, no como adorno: es el canal que sitúa lo que está
fuera de la vista y reduce el trabajo del cuello. Con oclusión y reverberación coherentes con la
escena.

## 4. Calidad y testing

- **Perfilar en el dispositivo, en build de release, siempre.** El editor con vista previa en el
  casco no mide lo que mide el aparato: térmica, GPU móvil, resolución real y composición. En
  hardware autónomo, además, **el rendimiento decae con el calor**: la prueba válida dura **más de
  15–20 minutos**, no dos.
- **Métrica**: tiempo de fotograma en p99, **fotogramas perdidos y *stale frames*** (fotogramas
  repetidos por el compositor), y nivel de *throttling* térmico de CPU/GPU. Los fps medios no valen.
- **Pruebas de confort con personas**, incluidas personas sin experiencia previa en XR y personas
  propensas al mareo: **la tolerancia del equipo de desarrollo es la peor referencia posible**
  (habituación). Sesiones cronometradas, con posibilidad de parar en cualquier momento, y registro
  de síntomas. **Ninguna cifra del tipo "el X % se marea" se cita sin estudio y metodología: es
  folclore del sector.**
- **Matriz de pruebas físicas obligatoria**: de pie y sentado; espacio grande y espacio de 1×1 m;
  usuario alto y usuario bajo (o sentado en silla de ruedas); zurdo y diestro; con gafas; con poca
  luz y con luz directa (afecta al seguimiento *inside-out*); quitarse y ponerse el casco a media
  sesión; perder el seguimiento de una mano; mando sin batería.
- **Degradación de extensiones**: test que arranca con las extensiones de fabricante deshabilitadas
  y verifica que la aplicación funciona o degrada limpiamente.
- **Gates de CI en orden de coste**: análisis estático → tests de lógica sin casco → build por
  plataforma → escena de referencia medida en dispositivo con umbral en ms → comprobación
  automatizada de requisitos de tienda (VRC/equivalente) → sesión de confort con personas.
- **Antes de enviar a tienda**: pasar la lista de requisitos del fabricante entera. Los fallos más
  frecuentes no son técnicos de render, son de política —privacidad, edad, contenido, metadatos—.

## 5. Seguridad del stack

**Aquí es donde XR se separa de todo lo demás del catálogo: los sensores que necesita para funcionar
son sensores de vigilancia corporal y doméstica.** El casco mide dónde miras, cuánto se dilatan tus
pupilas, cómo se mueve tu cara, cómo se mueve tu cuerpo y **cómo es por dentro la habitación en la
que vives**. Nada de eso es "telemetría".

- **Mirada (*eye tracking*)**: revela atención, interés, carga cognitiva y —según la literatura—
  permite identificar a la persona por su patrón de movimiento ocular. **Criterio duro: los datos de
  mirada se procesan en el dispositivo y no salen de él.** Si el caso de uso es *foveated rendering*
  o apuntado, la aplicación necesita el vector actual, **no el histórico**: no se almacena, no se
  registra, no se envía, no se usa para publicidad ni para analítica de atención.
- **Cara y cuerpo**: la expresión facial y la postura son datos de comportamiento derivados de
  sensores biométricos. Mismo criterio: locales, efímeros, con propósito declarado (avatar) y sin
  persistencia.
- **Mapa 3D del domicilio**: la malla de escena, los planos y los anclas espaciales son **un plano de
  la casa del usuario**, con muebles, tamaño y a veces contenido. En la plataforma de Meta el acceso
  está tras un permiso de ejecución explícito —`com.oculus.permission.USE_SCENE`, declarado en el
  `AndroidManifest.xml`, con diálogo de consentimiento— y la documentación exige **prever el camino
  alternativo si el usuario lo deniega**. Criterio: **pedirlo solo cuando se usa, explicarlo en el
  momento, funcionar sin él y no exportarlo jamás del dispositivo**. Subir una malla de escena a un
  servidor propio es un tratamiento que requiere base legal, DPIA y minimización
  (`privacy-engineering-standards`).
- **Cámaras de *passthrough*** y acceso a fotograma de cámara: es una cámara doméstica con todo lo
  que ello implica —terceros no consentidos en la escena incluidos—. Se trata como cámara, con
  indicación visible de captura y sin grabación silenciosa.
- **Marco legal, verbatim de la fuente:**
  - **RGPD, art. 4(14)**: *«‘biometric data’ means personal data resulting from specific technical
    processing relating to the physical, physiological or behavioural characteristics of a natural
    person, which allow or confirm the unique identification of that natural person…»*. **Art. 9(1)**:
    el tratamiento de *«biometric data for the purpose of uniquely identifying a natural person»*
    **está prohibido** salvo excepción del 9(2) —consentimiento explícito entre ellas—. Es decir: el
    dato de mirada o de cara **no es automáticamente art. 9**; lo es **cuando se usa para
    identificar de forma única**. La consecuencia práctica no cambia: es dato personal sensible por
    contexto, y el diseño correcto es que no se persista.
  - **Reglamento de IA (UE) 2024/1689 — inferencia de emociones**. Definición (art. 3): *«‘emotion
    recognition system’ means an AI system for the purpose of identifying or inferring emotions or
    intentions of natural persons on the basis of their biometric data»*. **Prohibición (art. 5)**,
    verbatim: *«the placing on the market, the putting into service for this specific purpose, or
    the use of AI systems to infer emotions of a natural person in the areas of workplace and
    education institutions, except where the use of the AI system is intended to be put in place or
    into the market for medical or safety reasons»*. Fuera de trabajo y educación **no está
    prohibido, pero es alto riesgo**: el Anexo III lista *«AI systems intended to be used for
    emotion recognition»*. Y el art. 50(3) obliga: *«Deployers of an emotion recognition system or a
    biometric categorisation system shall inform the natural persons exposed thereto of the
    operation of the system»*. El propio Reglamento avisa en sus considerandos de que hay *«serious
    concerns about the scientific basis of AI systems aiming to identify or infer emotions»*.
    **Traducción de ingeniería**: una función de "detectar cómo se siente el usuario" a partir de
    cara, mirada o voz es, en formación laboral o educativa en la UE, **ilegal**; en el resto de
    casos arrastra el régimen de alto riesgo y deber de información. **No se implementa sin pasar
    por `ai-governance-standards`.**
- **Menores**: los cascos tienen mínimos de edad y modos de cuenta infantil. Contenido, chat de voz,
  captura de datos y publicidad cambian de régimen. Verificar la política de la plataforma y el
  marco de protección del menor antes de diseñar la funcionalidad social.
- **Requisito de tienda verificado** (`VRC.Quest.Privacy.4`, actualizado 8-abr-2026): la política de
  privacidad debe explicar cómo **cualquier** usuario solicita el borrado de sus datos, y *«Requiring
  users to pay a fee for deletion of user data is prohibited»*. Es además, según el propio
  fabricante, **uno de los requisitos que más se suspenden**.
- **Superficie clásica que no desaparece por ser XR**: multijugador con autoridad de servidor y
  cliente hostil (`game-development-standards` §5), claves embebidas en el binario, contenido
  descargado por el usuario, y **acoso en espacios sociales** —que en XR es corporal (invasión de
  espacio personal): burbuja personal, silenciado, bloqueo y denuncia son funcionalidades de
  seguridad, no de comunidad—.

## 6. Rendimiento y operabilidad

- **Coste doble por ojo**: activar render de una sola pasada instanciada (*single-pass
  instanced*/multiview) por defecto; medir si se está pagando dos veces por error.
- **Palancas reales en hardware autónomo**, en orden de rentabilidad: reducir *draw calls* y cambios
  de material (agrupamiento estático/dinámico, atlas), resolución dinámica y *foveation* (fija o
  guiada por mirada), *shaders* móviles simples y sin sobredibujo (**el sobredibujo con transparencias
  es el asesino número uno**), *lightmaps* frente a iluminación dinámica, LOD agresivo, y evitar
  post-procesado a pantalla completa. La geometría rara vez es el cuello; el relleno y las llamadas,
  casi siempre.
- **Térmica**: el dispositivo autónomo se limita solo. Medir con la sesión larga y dejar margen
  (~10–20 %) sobre el presupuesto nominal; ningún diseño que dependa de ir al 99 % del presupuesto
  sobrevive al minuto 20.
- **Telemetría de sesión** (con consentimiento): tiempo de fotograma, fotogramas perdidos,
  *throttling*, duración de sesión y **abandono temprano**. Un pico de abandonos en los primeros
  minutos es la firma del mareo, no de la trama.
- **Arranque y reanudación**: el usuario se quita y se pone el casco constantemente; guardar y
  restaurar estado, pausar sin castigo, no perder progreso al perder el foco.
- **Batería y peso**: la sesión típica no dura horas. Diseñar experiencias con puntos de salida
  naturales cada pocos minutos.
- **Accesibilidad en XR** — mínimos exigibles, y ninguno es opcional:
  - **Altura y alcance ajustables**: recalibración de altura sin salir de la app; todo lo interactivo
    alcanzable **sentado**; modo sentado real (no "de pie con menos altura").
  - **Mano dominante configurable** y toda acción disponible con **una sola mano**.
  - **Alternativa a girarse físicamente**: giro por mando siempre disponible (no todo el mundo puede
    girar 360°, ni tiene sitio).
  - **Locomoción configurable** (teleporte/continua, viñeteado, giro por pasos/continuo, velocidad).
  - **Subtítulos espaciales**: legibles, con indicación de la dirección del hablante fuera de vista;
    tamaño y contraste ajustables; nada de subtítulo *head-locked* pegado a la cara.
  - **Sin requisito de audición estéreo ni de visión binocular**: no cifrar información **solo** en
    audio espacial ni **solo** en profundidad estereoscópica.
  - **Sin exigir gestos finos, fuerza ni rapidez**; tiempos de espera ajustables; *dwell* como
    alternativa a la pulsación.
  - **Fotosensibilidad**: sin destellos ni patrones de alto contraste rápido; opción de reducir
    efectos.

## 7. Sostenibilidad a largo plazo

- **Portabilidad como decisión de arquitectura**: núcleo sobre OpenXR, y **una capa propia fina**
  sobre toda extensión de fabricante que se use, con implementación nula (*no-op*) documentada. El
  dispositivo estrella de hoy se descataloga; el SDK propietario que ahorró dos semanas cuesta el
  port entero.
- **Cadencia**: el runtime del fabricante se actualiza solo en el dispositivo del usuario. Probar
  contra la versión de runtime nueva **antes** de que llegue al público (canales de prueba) y fijar
  la versión de SDK/plugin en el repo y en CI.
- **Deprecación**: las extensiones `XR_FB_*` se han ido reemplazando por `XR_META_*` y algunas
  funciones por `XR_EXT_*` ya estandarizadas. Revisar en cada subida qué se ha promovido al núcleo y
  migrar hacia el estándar, no al revés.
- **Documentar en ADR**: dispositivos objetivo y su presupuesto, extensiones no estándar usadas y por
  qué, decisiones de locomoción y confort, y **qué datos de sensor se tocan y con qué base legal**.

**Prohibiciones explícitas:**

- ❌ **Mover, rotar, inclinar o sacudir la cámara del usuario** por decisión de la aplicación.
  Incluye *head bobbing*, retroceso de arma, cinemáticas que giran la vista y "empujones" físicos.
- ❌ Diseñar contando con la reproyección/*SpaceWarp* para llegar al presupuesto.
- ❌ Fijar el objetivo en **fps medios** o medir solo en el editor y en el PC de desarrollo.
- ❌ Aceleración en la locomoción continua, o locomoción continua **sin** alternativa por teleporte
  y **sin** viñeteado configurable.
- ❌ UI pegada a la cabeza (*head-locked*), texto pequeño a distancia de lectura incorrecta, o menús
  que obligan a girar el cuello.
- ❌ Ocultar, desactivar o incitar a ignorar el límite de juego (*guardian*/boundary).
- ❌ **Almacenar, registrar o transmitir datos de mirada, expresión facial, cuerpo o malla de
  escena.** Ni "anonimizados", ni "para mejorar el producto".
- ❌ **Inferir emociones o estado psicológico** a partir de biometría en contexto laboral o educativo
  en la UE (prohibición del art. 5 del Reglamento de IA), y hacerlo en cualquier otro contexto sin
  gobierno de alto riesgo y sin informar a la persona (arts. Anexo III y 50(3)).
- ❌ Pedir el permiso de datos espaciales al arrancar "por si acaso", sin explicación y sin camino
  alternativo si se deniega.
- ❌ Grabar *passthrough* o cámara sin indicación visible.
- ❌ Asumir un cuerpo estándar: usuario de pie, dos manos funcionales, 1,75 m, sin gafas, con 2×2 m
  libres. Es la exclusión por defecto del medio.
- ❌ Bloquear el hilo de render con carga de assets, red o física pesada.
- ❌ Depender de una extensión de fabricante sin ruta de degradación probada.
- ❌ Citar cifras de mareo, de cuota de mercado o de ventas de dispositivos sin estudio y metodología.
- ❌ Portar una aplicación de pantalla plana a XR conservando cámara, UI y ritmo. Es el origen del
  95 % de las malas experiencias… cifra que, por cierto, **tampoco tiene fuente: no la repitas**.

## 8. Verificación web obligatoria

Antes de decidir, comprobar en la fuente primaria:

1. **OpenXR**: versión vigente de la especificación en `registry.khronos.org/OpenXR/` (verificada:
   línea **1.1**) y última entrega del SDK (verificada: **1.1.62**). Revisar en
   `specification/registry/xr.xml` qué extensiones se han promovido a `XR_EXT_`/`XR_KHR_` desde la
   última vez: **es la única forma fiable de saber qué ha dejado de ser propietario**.
2. **Presupuesto por dispositivo**: pliego de requisitos técnicos de **cada tienda de destino**
   (verificado solo el de Meta: `VRC.Quest.Performance.1`, tasas permitidas y mínimo de 60 fps con
   excepción de AppSW). **Hueco declarado**: no se ha podido verificar en fuente primaria la tasa de
   refresco objetivo ni el pliego equivalente de **visionOS/Apple Vision Pro** ni de otros
   fabricantes (páginas renderizadas por JavaScript, sin texto recuperable); **verificar antes de
   fijar objetivo en esas plataformas**.
3. **WebXR**: estado del documento en `w3.org/TR/webxr/` (verificado: **Candidate Recommendation
   Draft, 9-jun-2026**) y soporte real por navegador/plataforma de los módulos que se vayan a usar
   (AR, *hit test*, anclas, capas, manos) — el soporte de Safari/visionOS y de los cascos Android es
   el que más cambia.
4. **Catálogo de dispositivos**: modelos vigentes, tasas soportadas, resolución, sensores (mirada,
   cara, cuerpo) y mínimos de edad. **No casarse con un fabricante ni citar ventas.**
5. **Reglamento de IA (UE) 2024/1689**: texto consolidado en EUR-Lex y **fechas de aplicación
   vigentes** —han sido modificadas por el paquete ómnibus digital; el calendario correcto lo fija
   `ai-governance-standards`, no este documento—.
6. **RGPD**: guías de la AEPD y del EDPB sobre biometría y datos derivados de sensores; la
   interpretación de "identificación única" es la que decide si aplica el art. 9.
7. **Requisitos de privacidad y publicación de tienda** (verificado: `VRC.Quest.Privacy.4`,
   8-abr-2026) y política de menores de cada plataforma.
8. **CVEs y avisos** del runtime, del *loader* de OpenXR, del motor y de los SDK de fabricante.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
