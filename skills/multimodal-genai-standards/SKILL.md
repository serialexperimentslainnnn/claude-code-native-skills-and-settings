---
name: multimodal-genai-standards
description: Generative and understanding systems over non-text modalities — image, audio, video and document — as an engineering problem, provider-agnostic. Use when sending an image, a PDF page, a screenshot, a chart, an audio file or a video frame into a vision-language model, choosing between a classical OCR pipeline (Tesseract, PaddleOCR, docTR, Surya/Marker) and a VLM-based document reader (dots.ocr, olmOCR, DeepSeek-OCR, PaddleOCR-VL, Docling) and benchmarking with OmniDocBench or olmOCR-Bench, generating images with diffusion models (Stable Diffusion, FLUX.1 dev/schnell/pro, ComfyUI, ControlNet, LoRA adapters, seed/CFG/steps, negative prompts) and budgeting cost per image, running speech-to-text (Whisper large-v3 and turbo, faster-whisper, whisper.cpp, Parakeet TDT, Canary-Qwen, Voxtral, WER measurement, diarization, timestamps) or text-to-speech and voice cloning consent, processing video (frame sampling rate, keyframes, temporal cost), estimating latency and cost per modality and per token of image or audio, evaluating multimodal output (why CLIPScore, FID and BLEU decide nothing), defending against prompt injection embedded in images, screenshots and documents, applying C2PA Content Credentials, durable soft bindings and watermarking, or resolving rights over training data, over generated output and over the model weights license.
---

# Estándares de IA generativa multimodal

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **construir producto sobre modelos que entienden o generan modalidades que no son texto**:
imagen, audio, vídeo y documento. Cubre la decisión de modalidad, la elección entre canalización
clásica y modelo generativo, el coste y la latencia por modalidad, la evaluación de una salida que
no tiene respuesta correcta única, la **seguridad de una entrada que el modelo trata como
instrucción**, y los derechos sobre entrada, pesos y salida.

**Principio rector: en multimodal, el dato de entrada es también un canal de instrucciones.** Un
píxel, un fotograma o una capa oculta de un PDF entran por la misma vía que tu *system prompt* y el
modelo no distingue una cosa de la otra. Todo §5 sale de ahí. Corolarios:

1. **Casi nunca necesitas generación; casi siempre necesitas comprensión.** Y la comprensión de un
   documento suele resolverla mejor una canalización con anclaje espacial que un VLM libre (§2).
2. **La métrica automática multimodal decide poco.** FID, CLIPScore o WER agregado no dicen si tu
   producto funciona (§4).
3. **El coste no está en el prompt: está en la resolución, el número de páginas y la tasa de
   fotogramas** (§6). Es la variable que se descubre en la factura.

Disparadores: los del frontmatter.

**No aplica**:
- **`claude-api`** (skill instalada, **referencia canónica del lado Anthropic**): **todo dato de
  modelo, identificador, precio, ventana de contexto, límite de tamaño o formato de imagen/PDF de
  Anthropic sale de allí, NUNCA de memoria ni de este documento.** Si la respuesta contiene un ID de
  modelo, una tarifa o un nombre de parámetro de Anthropic, es suya. Aquí, criterio agnóstico.
- `llm-app-engineering-standards`: **la aplicación de LLM de texto** — prompt como artefacto, salida
  estructurada, ventana de contexto, caché de prefijo, streaming, reintentos, límites de gasto,
  inyección de prompt **en el canal de texto**. Aquí solo lo que **añade la modalidad**: el vector
  de inyección visual y documental, el coste por imagen/segundo, y la evaluación de salida no
  textual. **No se duplica su criterio de fiabilidad ni de prompting.**
- `computer-vision-standards`: **percepción clásica** — detección, segmentación, seguimiento,
  etiquetado, mAP/IoU, despliegue en borde, deriva de sensor. **Regla de arbitraje ya declarada en
  su §1 y respetada aquí: si la salida son cajas, máscaras o clases, es de allí; si es prosa,
  descripción, extracción semántica o un artefacto generado, es de aquí.**
- `nlp-standards`: texto puro y su decisión de tres vías (regla / modelo pequeño / LLM). **Se aplica
  igual antes de meter un VLM**: si el documento es texto digital limpio, extraer y usar PLN es más
  barato, exacto y auditable que mirarlo con un modelo.
- `deep-learning-standards` y `model-finetuning-standards`: **entrenar y tocar pesos**. Un LoRA de
  difusión o un ajuste de VLM es suyo, incluida **la licencia de los pesos de partida**; aquí solo
  el uso del modelo resultante y el coste de su inferencia.
- `rag-standards`: **la recuperación** — ingesta, chunking, índice, híbrido, reranking, citación.
  **Frontera fina y frecuente**: convertir un PDF en texto y trozos utilizables es **parseo de
  documento y es de aquí**; qué se indexa, cómo se trocea y cómo se recupera es **suyo**.
- `llm-evaluation-standards`: **la maquinaria de evaluación** — conjuntos dorados, jueces LLM y su
  calibración, significancia, regresión en CI. Aquí, **qué se mide en multimodal y por qué las
  métricas automáticas no bastan** (§4); el aparato, allí.
- `ai-agents-standards` (el bucle autónomo, y el agente que mira una pantalla),
  `mlops-standards` (ciclo de vida en producción), `local-inference-standards` (servir pesos
  propios), `gpu-computing-standards` (la GPU como recurso), `mlsecops-standards` (procedencia de
  pesos y ataques al modelo), `ai-governance-standards` (**AI Act, clasificación de riesgo,
  inventario y las obligaciones de transparencia y marcado del artículo 50 — son suyas**; aquí solo
  el mecanismo técnico, §5), `privacy-engineering-standards` (biometría, imagen de personas, voz
  como dato personal), `opensource-licensing-standards` (licencias de pesos y de datasets),
  `accessibility-standards` (**el texto alternativo generado y los subtítulos automáticos son
  ayuda, no conformidad**: el criterio WCAG es suyo), `finops-standards` (unidad económica).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| ¿Multimodal o no? | **Si el dato existe en forma estructurada o textual, úsalo.** Mirar una captura de un dashboard cuando existe la API es pagar por adivinar | Se decide antes que el modelo |
| Documento **digital** (PDF con capa de texto) | **Extracción directa**, no VLM | Es exacta, barata, determinista y auditable. Un VLM aquí solo añade coste y riesgo de alucinación |
| Documento **escaneado, con tablas, gráficos o manuscrito** | **VLM de documento con anclaje espacial** (*bounding boxes*) | El anclaje es el control anti-alucinación: obliga a que el texto extraído apunte a una región. Un extractor sin coordenadas no es verificable |
| OCR clásico frente a VLM | **Depende de la tarea; no hay ganador** | Clásico gana en entrada limpia, formato estable, latencia y coste. VLM gana en maquetación compleja, tablas, gráficos y extracción semántica. **Los VLM son del orden de 5-10× más lentos y pueden alucinar texto plausible pero falso** — el fallo peligroso, porque parece correcto |
| Canalización en cascada | **Cuidado con el error compuesto** | Una tasa de error por carácter del 2 % por etapa se propaga y arruina la extracción aguas abajo. Es el argumento real a favor del modelo de una pasada, no el hype |
| Evaluación de extracción documental | **Contra tus documentos, siempre** | `OmniDocBench` y `olmOCR-Bench` son las referencias públicas; sirven para descartar, **no para decidir**. Buena parte de los comparativos de 2026 son blogs de proveedores con interés comercial |
| Transcripción (STT) | **Whisper large-v3 / turbo** por defecto multilingüe; alternativas si el caso es inglés o tiempo real | A ago-2026 **no consta sucesor de Whisper**: `large-v3` y su destilado *turbo* siguen siendo el checkpoint abierto de referencia (>99 idiomas). Alternativas medidas: **Parakeet TDT 0.6B v3** (mejor WER medio y mucho más rápido, pero **solo inglés y lenguas europeas**), **Canary-Qwen 2.5B** (mejor en inglés, **solo inglés**) |
| Licencia del modelo de STT | **Decide tanto como el WER** | Verificado: **Whisper es MIT**; **Parakeet TDT 0.6B v3 y Canary-Qwen son CC-BY-4.0** → uso comercial permitido **con atribución obligatoria**, que en un producto embebido o de marca blanca es una obligación real. **Es motivo legítimo para desplegar el modelo que no es el más preciso** |
| Generación de imagen | **Diffusion con control explícito**; sin control, es una máquina de sorpresas | Semilla, pasos, CFG y ControlNet fijados y **registrados con cada salida**. Sin semilla registrada no hay reproducción ni depuración |
| Licencia de pesos de generación | **Se lee en crudo, siempre** | Verificado literal: **FLUX.1 [dev] Non-Commercial License v1.1.1** — *"You may only access, use, Distribute, or create Derivatives of the FLUX.1 [dev] Model or Derivatives for Non-Commercial Purposes"*. **Y sin embargo, sobre la salida**: *"We claim no ownership rights in and to the Outputs… You may use Output for any purpose (including for commercial purposes)"*, salvo entrenar un modelo competidor. **Los pesos y la salida tienen licencias distintas: confundirlas es el error caro de este dominio** |
| Vídeo | **Muestreo de fotogramas antes que "pasar el vídeo"** | Coste y latencia crecen linealmente con los fotogramas. Empieza por keyframes y sube solo si la métrica lo pide |
| Voz sintética / clonación | **Consentimiento explícito, escrito y revocable del titular de la voz** | Precondición dura, no *nice to have*. La voz es dato biométrico (`privacy-engineering-standards`) |
| Marcado de contenido generado | **C2PA + marca de agua, sabiendo que es forense y no preventivo** (§5) | Línea de especificación publicada: **2.4**. C2PA se creó en 2021; **>6.000 miembros y afiliados a ene-2026** |

## 3. Estructura y convenciones

- **Un artefacto multimodal se registra con su procedencia completa**: modelo y versión, semilla,
  parámetros, hash de la entrada, coste y fecha. Sin eso no se puede reproducir un fallo, ni
  responder a una reclamación, ni auditar.
- **Normaliza la entrada en el borde, no en el modelo**: resolución máxima, DPI, deskew,
  orientación, formato y **tamaño máximo**. Un usuario que sube un TIFF de 200 MB no debe llegar al
  modelo; debe llegar al validador.
- **La resolución es el parámetro de coste, no un detalle de calidad.** Fija la mínima que sostiene
  la métrica y mídelo; subir resolución "por si acaso" multiplica el gasto sin mover el resultado.
- **Salida estructurada obligatoria** para extracción: esquema declarado y validado, con
  coordenadas de origen por campo. **Un campo sin ancla es un campo no verificable.**
- **Ruta de fallback y de revisión humana declarada por adelantado**: qué pasa cuando la confianza
  baja de umbral, quién revisa y con qué SLA. Un extractor documental sin cola de revisión asume
  implícitamente un 100 % de acierto que no existe.
- **Idempotencia y caché por hash de entrada**: la misma imagen no se procesa dos veces. Es la
  optimización de coste con mejor relación esfuerzo/beneficio en este dominio.
- **Audio: la unidad es el segmento, no el fichero.** Segmentación, marcas de tiempo y, si aplica,
  diarización; los ficheros largos se trocean para acotar el fallo y el reintento.
- **El texto alternativo y los subtítulos generados se marcan como generados** y pasan revisión si
  son la vía de acceso de alguien. La conformidad la fija `accessibility-standards`.

## 4. Evaluación: por qué la métrica automática no basta

- **El problema estructural**: en generación multimodal **no hay una respuesta correcta**, y las
  métricas automáticas miden parecido con una referencia arbitraria o alineación en un espacio
  aprendido — no utilidad. **FID** compara distribuciones y es sensible al conjunto y al tamaño de
  muestra; **CLIPScore** hereda los sesgos y los puntos ciegos del propio CLIP y premia lo que CLIP
  reconoce; **BLEU/ROUGE** sobre descripciones de imagen penalizan una descripción mejor redactada.
  **Ninguna es un gate de producto.** Sirven para detectar regresiones groseras, y para nada más.
- **WER es la excepción parcial**: es objetiva, pero **el WER agregado esconde exactamente lo que
  importa** — nombres propios, cifras, jerga del dominio, hablantes con acento, audio con ruido.
  **Mide WER por segmento y por clase de hablante**, y añade una métrica de negocio (¿se extrajo
  bien el número de póliza?).
- **Extracción documental**: la métrica es **exactitud por campo sobre tus documentos**, y por tipo
  de campo (los numéricos y las tablas fallan distinto que la prosa). Añade **tasa de corrección
  humana**, que es el coste real.
- **Conjunto dorado propio, obligatorio**: 100–300 muestras representativas —incluyendo **los casos
  feos**: fotocopia torcida, sello encima del texto, tabla partida entre páginas, audio con dos
  personas hablando a la vez—. La maquinaria (jueces, significancia, CI) es de
  `llm-evaluation-standards`; **el contenido del conjunto es responsabilidad de este dominio**.
- **Evaluación humana con rúbrica** para generación: criterios escritos, más de un evaluador,
  acuerdo medido. "Me gusta más" no es una evaluación.
- **Gate de CI**: el conjunto dorado corre en cada cambio de modelo, de prompt o de preprocesado.
  **Cambiar de versión de modelo sin re-evaluar es desplegar a ciegas**, y en multimodal las
  regresiones son silenciosas: la salida sigue siendo plausible.

## 5. Seguridad del stack

**5.1 Inyección de prompt por imagen y por documento — el riesgo que define el dominio.**

- **Es arquitectónico, no un bug**: los VLM actuales **no distinguen el contenido visual que quieres
  mostrar de las instrucciones incrustadas en él**; una vez pasado el codificador de visión, todo
  entra por la misma vía de seguimiento de instrucciones. Está catalogado en **OWASP LLM01**.
- **Clases de ataque verificadas**: texto tipográfico incrustado en la imagen y hecho poco visible
  para el humano pero legible para el modelo; **perturbaciones adversarias sin texto legible**, que
  funcionan **aunque el modelo no tenga OCR** (línea de trabajo de Bagdasaryan et al. y sucesores);
  instrucciones en metadatos, capas ocultas o texto blanco de un documento; y en 2026, **inyección
  desde el mundo físico** (carteles, embalaje, pantallas dentro del campo de visión de un agente con
  cámara).
- **Estado de las defensas, sin adornos: van por detrás.** Los guardarraíles comerciales más citados
  siguen siendo **solo texto** en sus APIs públicas; no existe una defensa de producción fiable para
  imagen, audio y documento. **Diseña asumiendo que la inyección multimodal funciona.**
- **Controles que sí valen, porque no dependen de detectar el ataque**:
  1. **Toda entrada no controlada es dato, nunca instrucción.** Separación explícita en el prompt y,
     sobre todo, en los permisos.
  2. **La salida del modelo no ejecuta nada con privilegio.** Ni herramienta con efecto lateral, ni
     llamada de red, ni escritura, sin validación independiente o aprobación humana
     (`ai-agents-standards` para el bucle).
  3. **Mínimo privilegio del proceso que mira contenido ajeno**, y egreso restringido: la
     exfiltración por URL en la respuesta es el vector de cobro habitual.
  4. **Filtrado de salida** de cualquier cosa que exfiltre (URLs con datos, markdown de imagen
     remota).
  5. **Ojo con el OCR como defensa**: los ataques por perturbación lo ignoran, y los modelos de
     fusión temprana tratan símbolos visuales (emoji, rebus) como instrucción — un filtro de
     palabras clave no los ve.
- **Superficie propia de capturas de pantalla**: un agente que mira la pantalla ve todo lo que hay
  en ella, incluida una ventana de correo con instrucciones hostiles. Trátalo como entrada de
  Internet.

**5.2 Marcado, procedencia y su límite honesto.**

- **C2PA es forense, no preventivo.** Prueba que una clave firmó un manifiesto y que el fichero no
  cambió desde entonces; **no prueba que la imagen sea verdadera, ni justa, ni tuya**, y la
  especificación no aborda la identidad humana u organizativa. Limitaciones verificadas: el
  manifiesto embebido **se pierde cuando cualquier herramienta no compatible reescribe el fichero**
  (WhatsApp, iMessage y Facebook recodifican al subir), y **una captura de pantalla o una foto de
  la pantalla rompe el vínculo**. Un fichero sin credencial **no dice nada**: puede que nunca la
  tuviera, o que se la quitaran.
- **Durable Content Credentials** combinan *hard binding* (hash SHA-256 sobre los bytes) con *soft
  binding* (marca de agua o huella perceptual) para reencontrar el manifiesto en un repositorio.
  Regla de la propia especificación: **un *soft binding* no se usa como *hard binding***.
- **Ninguna marca de agua resiste a un adversario dedicado con acceso al modelo.** Úsala para
  trazabilidad y cumplimiento, jamás como control de seguridad.
- **La obligación regulatoria de marcar y divulgar contenido sintético es de
  `ai-governance-standards`** (AI Act, artículo 50 y códigos de práctica asociados). Aquí solo el
  mecanismo y sus límites. **Verifica las fechas allí y por web; no las cites de memoria.**

**5.3 Derechos.**

- **Tres licencias distintas y separadas, y la gente las mezcla**: (a) los **datos de entrenamiento**
  del modelo, (b) los **pesos**, (c) la **salida**. El caso FLUX.1 [dev] lo ilustra literalmente
  (§2): pesos **no comerciales**, salida **usable comercialmente**.
- **La licencia se lee en crudo**, del fichero de licencia del repositorio de pesos, nunca de la
  web del proyecto ni de un resumen. Y se relee al cambiar de versión: **las licencias de modelos
  cambian entre releases**.
- **La procedencia del dato de entrenamiento es un riesgo abierto** (litigios en curso en varias
  jurisdicciones a ago-2026). Postura por defecto: **no generes material que imite deliberadamente
  el estilo identificable de un autor o la marca de un tercero**, y no lo publiques sin revisión.
- **Imagen y voz de personas**: dato personal, y a menudo biométrico. Base jurídica, minimización y
  consentimiento explícito para clonar voz o rostro (`privacy-engineering-standards`).
- **Datos del usuario hacia el proveedor**: qué se retiene, cuánto y si se entrena con ello, se
  verifica en el contrato del proveedor concreto — **para Anthropic, en `claude-api`**.

## 6. Coste, latencia y operabilidad

- **Instrumenta el coste por modalidad y por unidad de negocio desde el día uno** (por página, por
  minuto de audio, por imagen generada, por fotograma). En texto el coste sorprende; en multimodal
  **descarrila**, porque una sola variable —resolución, páginas, fps— lo multiplica.
- **Órdenes de magnitud reales**: la extracción documental va de **céntimos por millar de páginas**
  con un modelo abierto autoalojado a **varios órdenes más** con un modelo comercial grande por
  página. **La diferencia decide la arquitectura, no el margen.** Las cifras concretas se verifican
  por web y, en Anthropic, en `claude-api`.
- **Latencia**: la percepción y la generación de imagen/audio son de segundos. Diseña asíncrono con
  estado y notificación; un endpoint síncrono esperando a un modelo de difusión es un timeout con
  fecha. **Presupuesto por petición y por usuario con corte duro** — el bucle que reprocesa un PDF
  de 900 páginas es el incidente de coste clásico.
- **Degradación explícita**: si el modelo falla o supera presupuesto, la ruta alternativa es
  canalización clásica + revisión humana, no un error 500.
- **Vigila**: coste y latencia p95 por modalidad, tasa de rechazo del validador de entrada, tasa de
  corrección humana, y **deriva de la calidad tras un cambio de versión del proveedor** — que
  ocurre sin avisar y no da error.

## 7. Sostenibilidad y prohibiciones

- **Todo modelo se re-evalúa contra el conjunto dorado cuando cambia de versión**, incluido un
  modelo gestionado que "no has tocado".
- **Los pesos y sus licencias se reauditan por release** (§5.3).

- ❌ **PROHIBIDO** tratar una entrada visual o documental de origen no controlado como si no
  contuviera instrucciones (§5.1).
- ❌ Dar a la salida de un VLM capacidad de ejecutar herramientas con efecto lateral sin validación
  independiente o aprobación humana.
- ❌ Usar un VLM para leer un documento que ya tiene capa de texto extraíble.
- ❌ Extraer campos sin anclaje espacial y presentarlos como verificados, o desplegar extracción
  documental sin cola de revisión humana ni umbral de confianza.
- ❌ Usar FID, CLIPScore, BLEU o WER agregado como criterio de aceptación de producto (§4).
- ❌ Cambiar de modelo o de versión sin re-ejecutar el conjunto dorado.
- ❌ Confundir la licencia de los pesos con la de la salida (§5.3, caso FLUX.1 [dev]), o asumir una
  licencia por la web del proyecto: **se lee el fichero en crudo**.
- ❌ Clonar una voz o un rostro sin consentimiento explícito, escrito y revocable.
- ❌ Presentar C2PA o una marca de agua como prueba de autenticidad o control preventivo, **o tratar
  la ausencia de credencial como prueba de manipulación** (§5.2).
- ❌ Confiar en un guardarraíl de texto para contener inyección por imagen o audio.
- ❌ Enviar vídeo entero a un modelo sin política de muestreo de fotogramas; subir resolución, DPI o
  fps sin medir si mueve la métrica; o desplegar sin presupuesto por petición y corte duro.
- ❌ **Citar de memoria un identificador, precio o límite de modelo de Anthropic: sale de
  `claude-api`.**
- ❌ Tratar subtítulos o texto alternativo generados automáticamente como conformidad de
  accesibilidad.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Todo dato de modelo de Anthropic** (IDs, precios, límites de tamaño y formato de imagen y PDF,
   parámetros): **de la skill `claude-api`**, no de aquí ni de memoria.
2. **Precios y límites por modalidad del proveedor que uses**: cambian con frecuencia y el coste por
   imagen o por minuto de audio es la variable que decide la arquitectura (§6).
3. **Estado de Whisper y de sus alternativas**: a ago-2026 **no consta sucesor anunciado de
   Whisper**; `large-v3`/turbo siguen siendo el checkpoint abierto de referencia. Reconfirma antes
   de comprometer una arquitectura de STT, y **verifica la licencia de cada checkpoint**
   (Whisper = MIT; Parakeet TDT 0.6B v3 y Canary-Qwen = CC-BY-4.0, con atribución obligatoria).
4. **Licencias de pesos de generación de imagen leídas en crudo** — el caso verificado aquí es
   **FLUX.1 [dev] Non-Commercial License v1.1.1** (pesos no comerciales, salida comercial permitida
   salvo entrenar un competidor). Comprueba también Stable Diffusion y cualquier LoRA de terceros,
   que arrastran su propia licencia.
   - **Hueco declarado**: no verifiqué la licencia vigente de Stable Diffusion 3.x ni las condiciones
     de FLUX.1 [pro]/[schnell]; se leen en crudo antes de usarlas.
5. **Especificación C2PA vigente** en `spec.c2pa.org` (línea publicada verificada: **2.4**),
   estado del programa de conformidad y de la *Trust List*, y **qué plataformas conservan o eliminan
   el manifiesto al subir** — es lo que decide si el marcado sirve en tu canal de distribución.
6. **Obligaciones regulatorias de marcado y divulgación**: **son de `ai-governance-standards`**;
   verifica allí y por web las fechas de aplicación del AI Act (artículo 50) y el estado del código
   de práctica de marcado. **No cites fechas regulatorias de memoria.**
7. **Estado de las defensas contra inyección multimodal**: es el área que más se mueve. **Hueco
   declarado**: a ago-2026 no encontré una defensa de producción con eficacia demostrada
   independientemente para imagen/audio/documento; las cifras de detección que circulan vienen de
   los propios autores de cada marco. Diseña con los controles de §5.1, que no dependen de detectar.
8. **Benchmarks de extracción documental** (`OmniDocBench`, `olmOCR-Bench`) y el modelo abierto
   vigente: el liderazgo cambia cada pocos meses y **buena parte de los comparativos publicados son
   de proveedores con interés comercial**. Reproduce sobre tus documentos antes de decidir.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
