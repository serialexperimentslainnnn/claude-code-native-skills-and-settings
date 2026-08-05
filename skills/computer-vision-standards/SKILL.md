---
name: computer-vision-standards
description: Applied computer vision as a data problem, not a model problem. Use when defining a vision task (classification, object detection, semantic versus instance versus panoptic segmentation, multi-object tracking, OCR, keypoint/pose estimation), building or auditing an image dataset and its label quality, inter-annotator agreement, annotating with CVAT, Label Studio, labelme, Roboflow, FiftyOne or supervision, converting between COCO JSON, YOLO .txt, Pascal VOC XML, YOLO data.yaml and instances_train.json, writing albumentations or kornia augmentation pipelines and spotting augmentation that breaks the label, choosing a detector or segmenter (Ultralytics YOLO/YOLO26, RT-DETR, RF-DETR, D-FINE, DEIM, YOLOX, Detectron2, MMDetection, SAM/SAM 2/SAM 3, Grounding DINO, DINOv2/DINOv3) and reading its weights licence before shipping, computing IoU, mAP@0.5:0.95, per-class confusion or PR curves, exporting to ONNX, TensorRT, OpenVINO, LiteRT or Core ML, matching train and serve preprocessing (resize, letterbox, BGR/RGB, normalisation), budgeting per-frame latency on an edge device, or handling camera, lens and lighting drift. Also covers biometric and CCTV footage constraints.
---

# Estándares de visión por computador (computer vision)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **resolver un problema de visión con imágenes o vídeo**: definir la tarea, construir y
etiquetar el conjunto de datos, elegir un modelo preentrenado y su licencia, evaluar en el dominio
real, exportar y desplegar con presupuesto de latencia, y vigilar la deriva del sensor.

Triggers: `.jpg`/`.png`/`.mp4` como dato de entrada, `instances_train2017.json`, `data.yaml`,
`labels/*.txt` de YOLO, `Annotations/*.xml` de Pascal VOC, `annotations.xml` de CVAT, `mAP`,
`IoU`, `NMS`, `conf`/`iou` de umbral, `letterbox`, `imgsz`, `albumentations`, `A.Compose`,
`kornia`, `cv2.imread`, `torchvision.transforms`, `ultralytics`, `YOLO(...)`, `RT-DETR`,
`RF-DETR`, `detectron2`, `mmdet`, `SamPredictor`, `GroundingDINO`, `DINOv3`, `.onnx`, `.engine`,
`.xml`+`.bin` de OpenVINO, `.tflite`, `.mlpackage`, "detectar piezas defectuosas", "contar
personas", "leer matrículas", "seguir objetos entre fotogramas", "va bien en test y mal en
planta", "en la cámara nueva falla".

**Tesis del dominio**: **casi todo problema de visión se resuelve con un modelo preentrenado y un
conjunto de datos bien etiquetado; el modelo casi nunca es el cuello de botella.** El orden real de
impacto sobre la métrica es **definición de la tarea > calidad y consistencia del etiquetado >
representatividad del conjunto > aumento de datos > arquitectura > hiperparámetros**, y el trabajo
se reparte casi siempre al revés. Corolarios que fijan criterio: **(a)** cambiar de detector rara
vez compensa arreglar 200 etiquetas mal puestas; **(b)** si el modelo falla, el primer sospechoso
es la etiqueta, no la red; **(c)** una métrica pública alta no dice nada de tu planta, tu cámara ni
tu iluminación.

**No aplica**:

- `deep-learning-standards`, `model-finetuning-standards` y `classical-ml-standards` (**escritas**):
  **entrenar una red propia y su bucle son de la primera** (precisión mixta, distribuido,
  reproducibilidad, diagnóstico de la pérdida, compresión); **tocar los pesos de un modelo ajeno es
  de la segunda**; **el dato tabular es de la tercera**, junto con la mecánica común de fuga,
  partición, umbral y calibración, que **no se duplica aquí**: se aplica igual y vive allí. Desde
  este lado solo se afirma qué es específico de la imagen —qué tarea, qué etiqueta, qué
  preprocesado y qué deriva de sensor.
- `llm-app-engineering-standards`, `rag-standards` y `llm-evaluation-standards` (**escritas**):
  **el producto sobre un LLM de terceros es de la primera, la recuperación de la segunda y la
  medición de sistemas no deterministas de la tercera**; aquí las métricas son deterministas
  (IoU, mAP, matriz de confusión) y se calculan aquí. Un VLM que describe una imagen en texto libre
  es producto LLM y se evalúa allí; un detector que devuelve cajas es de aquí.
- `mlops-standards`, `local-inference-standards`, `gpu-computing-standards`, `mlsecops-standards` y
  `ai-governance-standards` (**escritas**): **el ciclo de vida en producción es de la primera**
  —registro, promoción, vigilancia de deriva, reentrenamiento—, **servir pesos propios de la
  segunda**, **la GPU como recurso de la tercera**, **la procedencia de los pesos y los ataques al
  modelo de la cuarta**, y **la clasificación de riesgo, el AI Act y el inventario de la quinta**.
  Aquí se **detecta** la deriva de cámara (§6) y se **exige** la clasificación de riesgo antes de
  desplegar biometría (§5); el gobierno, allí.
- Comunes: `privacy-engineering-standards` (**biometría, rostros y voz de personas**),
  `opensource-licensing-standards` (**la política de licencias, incluidas las de pesos y datasets**),
  `data-engineering-standards` y `data-governance-quality-standards` (ingesta, linaje y calidad del
  dato), `python-standards`, `finops-standards` y `green-it-standards` (coste y huella de la
  inferencia), `grc-compliance-standards`, `webgl-webgpu-standards` (inferencia en el navegador) y
  `embedded-iot-standards` (el dispositivo de borde como sistema).
- `xr-standards` y `robotics-ros-standards`: **el SLAM y la percepción son de aquí**; **el consumo
  del resultado y su temporización son suyos** — el presupuesto de fotograma y la latencia
  movimiento-a-fotón allí, el ciclo de control y la QoS del mensaje que transporta la detección
  allá. Una detección correcta que llega tarde es un fallo suyo, no de la métrica de aquí.
- Skills hermanas de modalidad: `nlp-standards` (texto) y `multimodal-genai-standards` (generación
  de imagen, audio y vídeo). **Son tres modalidades, no tres niveles**: ninguna es prerrequisito de
  otra. **Regla de arbitraje con `multimodal-genai-standards`, recíproca y ya declarada en su §1:
  si la salida son cajas, máscaras, *keypoints* o etiquetas, es de aquí; si es prosa, descripción,
  extracción semántica de un documento o un artefacto generado, es suya.**

## 2. Decisiones por defecto

> Verificar la última versión y la licencia **de los pesos** por web antes de fijarla en un
> proyecto real (§8). La licencia del repositorio **no** es la de los pesos.

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Punto de partida | **Preentrenado + tus datos etiquetados** | Entrenar desde cero: exige justificarlo (`deep-learning-standards` §1) |
| Detección, licencia permisiva | **RT-DETR / RF-DETR / D-FINE / DEIM / YOLOX** (Apache-2.0 verificado) | Ultralytics YOLO **solo** con licencia Enterprise o proyecto AGPL |
| Segmentación de instancia | **Detectron2 / MMDetection** (Apache-2.0) | Ultralytics `-seg` bajo las mismas condiciones |
| Segmentación interactiva / *zero-shot* | **SAM 2** (Apache-2.0 verificado) | SAM 3: licencia propia de Meta, no OSI (§5) |
| *Backbone* de propósito general | **DINOv2** (Apache-2.0 verificado) | DINOv3: licencia propia y acceso restringido (§5) |
| Detección por texto libre | Grounding DINO (Apache-2.0) para **prototipar y preetiquetar**, no para producción |
| Anotación | **CVAT** (MIT verificado) autoalojado; **Label Studio** (Apache-2.0) si mezclas modalidades | Roboflow / SaaS: revisa a quién cede derechos sobre tus imágenes |
| Auditoría del dataset | **FiftyOne** (Apache-2.0 verificado) | Scripts propios: se acaban escribiendo igual, peor |
| Aumento de datos | **albumentations** (MIT) | `kornia` (Apache-2.0) si el aumento va en GPU dentro del grafo |
| Formato canónico en el repo | **COCO JSON** como fuente de verdad; YOLO `.txt` derivado | VOC XML solo por compatibilidad heredada |
| Exportación | **ONNX** + ONNX Runtime (MIT) como *baseline* portable | TensorRT (NVIDIA), OpenVINO (Intel), LiteRT / Core ML según el hardware final |

**Regla de elección**: fija primero **el hardware de despliegue y el presupuesto de fotograma**;
después la familia de modelo. Al revés se acaba con un modelo que no entra en el dispositivo.

## 3. Definir la tarea antes que el modelo

**Elegir mal la tarea es el error más caro del dominio**, porque no se detecta hasta que el
etiquetado está pagado y hay que rehacerlo entero.

| Pregunta de negocio | Tarea | Etiqueta que hay que pagar |
|---|---|---|
| ¿Está presente / de qué tipo es? | Clasificación (mono o multietiqueta) | Una etiqueta por imagen |
| ¿Cuántos hay y dónde? | Detección | Caja + clase por instancia |
| ¿Qué superficie ocupa? | Segmentación **semántica** (píxel → clase, sin instancias) | Máscara por píxel |
| ¿Cuántos objetos y qué píxeles son de cada uno? | Segmentación **de instancia** | Máscara por instancia |
| Ambas a la vez, sin huecos ni solapes | Segmentación **panóptica** | Etiquetado más caro de todos |
| ¿Es el mismo objeto que el fotograma anterior? | Seguimiento (detección + asociación) | Identidad persistente entre fotogramas |
| ¿Qué dice ese texto? | OCR (detección + reconocimiento) | Cajas de texto + transcripción |
| ¿En qué postura está? | Estimación de pose | Puntos clave por instancia |

Criterios duros:

- **Semántica vs. instancia no es un detalle**: si hay que **contar**, semántica no sirve; dos
  objetos pegados son una sola región. Reetiquetar de semántica a instancia cuesta casi lo mismo
  que empezar.
- **Seguimiento es detección + asociación**: la métrica de seguimiento (cambios de identidad) no
  mejora con un detector mejor si el problema es la asociación.
- **Detección con una sola clase y un objeto por imagen = clasificación**: no pagues cajas.
- **Contar no siempre es detectar**: si los objetos se solapan mucho (células, grano, multitud), la
  regresión de densidad supera a la detección con una fracción del etiquetado.
- **OCR de documento estructurado**: comprueba antes si el productor del documento puede darte el
  dato en origen. Reconocer texto que alguien imprimió desde una base de datos es un fracaso de
  integración, no un problema de visión.

## 4. Datos: el factor dominante

**Adquisición**: captura con **el mismo sensor, óptica, montaje e iluminación** que tendrá
producción. Un conjunto tomado con el móvil del jefe de planta no predice nada sobre la cámara
industrial que se instalará. Registra por imagen: cámara, lente, exposición, turno, línea, lote —
son las variables con las que después se parte el conjunto y se diagnostica la deriva.

**Etiquetado — la calidad y la consistencia mandan sobre la cantidad**:

- **Guía de etiquetado escrita antes de la primera etiqueta**, con casos límite resueltos y
  ejemplos de "sí / no / dudoso". Sin guía, cada anotador inventa la suya y el techo de la métrica
  queda fijado por esa inconsistencia.
- **Acuerdo entre anotadores medido, no supuesto**: un subconjunto solapado etiquetado por ≥2
  personas y un estadístico de acuerdo (para cajas, IoU pareado y coincidencia de clase; para
  clasificación, un índice tipo kappa que corrija el azar). **Si dos anotadores no se ponen de
  acuerdo, el modelo no puede aprenderlo y la evaluación no significa nada.** El acuerdo es el
  techo práctico de la métrica.
- **Ciclo de revisión**: etiqueta → revisión por segunda persona → corrección de la guía. Las
  discrepancias son el mejor detector de tarea mal definida.
- **Auditoría de etiquetas ya existentes** antes de culpar al modelo: ordena por pérdida y revisa
  los peores; los errores de etiqueta se concentran ahí. Los conjuntos públicos también los tienen.
- **Trazabilidad**: quién etiquetó qué y cuándo, versión de la guía y versión del conjunto
  (`data-governance-quality-standards`). Un dataset sin versión no es evaluable.

**Formatos**: COCO JSON (un fichero, cajas `[x, y, w, h]` absolutas, máscaras RLE o polígono),
YOLO (un `.txt` por imagen, `[clase, xc, yc, w, h]` **normalizado**), Pascal VOC (un XML por
imagen, `[xmin, ymin, xmax, ymax]`). **La conversión entre ellos es la fuente clásica de cajas
desplazadas**: origen de coordenadas, absoluto vs. normalizado, esquina vs. centro y orden de
clases. Verifica siempre **superponiendo las cajas convertidas sobre la imagen**, no leyendo el
JSON.

**Aumento de datos con criterio**: el aumento simula la variabilidad **que existirá en producción**,
no la que se te ocurra. Si la cámara está fija y cenital, rotar 90° enseña una variación que nunca
verá y gasta capacidad.

**Aumento que rompe la etiqueta** — lista de veto:

- ❌ **Volteo horizontal** cuando la clase depende de la lateralidad: texto, dígitos, matrículas,
  izquierda/derecha anatómica, tornillos por sentido de rosca, señales asimétricas.
- ❌ **Recorte o traslación sin recalcular caja/máscara/puntos clave**, o dejando cajas de objetos
  que ya no están en la imagen. Usa transformaciones que transporten la anotación (`bbox_params`,
  `keypoint_params`) y **descarta** cajas por debajo de un área visible mínima.
- ❌ **Cambios de color agresivos** cuando el color **es** la clase: madurez de fruta, código de
  cable, semáforo, óxido, tinción médica.
- ❌ **Desenfoque, ruido o compresión fuertes** cuando el defecto a detectar es sutil: borras la
  clase positiva.
- ❌ **Mezcla de imágenes (mosaico, mixup, copy-paste)** en un conjunto de **validación**. Solo
  entrenamiento, nunca evaluación.
- ❌ Aumento **después** de normalizar, o con un pipeline distinto del de inferencia (§6).

**Desequilibrio y casos raros**: en visión industrial **el caso raro es el objetivo** — el defecto
que aparece una vez cada diez mil piezas es justamente el que hay que detectar. Consecuencias:
sobremuestrea o pondera la clase rara en entrenamiento, pero **nunca en el conjunto de evaluación**,
que debe conservar la prevalencia real; reserva un conjunto específico de casos raros y repórtalo
aparte; y si los positivos son poquísimos, plantea **detección de anomalías** (entrenar solo con
normales) en vez de clasificación supervisada.

## 5. Licencias, biometría y videovigilancia

**La licencia de los pesos no es la del repositorio, y esto es el error de licencia más común del
dominio.** Verificado leyendo el fichero en crudo (ago-2026):

| Familia | Licencia verificada | Consecuencia |
|---|---|---|
| **Ultralytics** (YOLOv5, YOLOv8, YOLO11, YOLO26, y su RT-DETR/YOLO-World empaquetados) | **AGPL-3.0** en `LICENSE`, con Enterprise de pago | Su página de licencia lo dice sin ambigüedad: *"An Enterprise License is required if you want to use Ultralytics YOLO without open-sourcing your entire project"*, y lista expresamente *"Internal business tools or private company applications"*, *"Embedded deployments in hardware, edge devices, robotics, cameras, or appliances"* y *"Using custom-trained or fine-tuned YOLO models in a proprietary or commercial setting"*. **Tu modelo entrenado con tus datos sigue afectado** según el licenciante |
| YOLOv7, YOLOv9, YOLOv6 (Meituan), YOLO-World | **GPL-3.0** | Copyleft fuerte igualmente |
| YOLOv10 (THU-MIG) | **AGPL-3.0** | Igual que Ultralytics |
| **YOLOX** (Megvii), **RT-DETR**, **D-FINE**, **DEIM**, **RF-DETR** (Roboflow) | **Apache-2.0** | Vía permisiva real para detección |
| Detectron2, MMDetection, Grounding DINO, **SAM 2**, **DINOv2** | **Apache-2.0** | Permisivo |
| **SAM 3** (Meta, "SAM License", 19-nov-2025) y **DINOv3** (Meta, 19-ago-2025) | **Licencia propia, no OSI** | Vírica en la forma: *"If you distribute or make the … Materials, or any derivative works thereof, available to a third party, you may only do so under the terms of this Agreement"*; prohíbe *"reverse engineer, decompile or discover the underlying components"*; excluye usos militares, nucleares y de armas por *Trade Controls*; **tú indemnizas a Meta**; y **Meta puede modificar el acuerdo unilateralmente** (*"All such changes will be effective immediately"*). DINOv3 exige además aceptación con datos personales; sus variantes *EUPE* van bajo la **FAIR Noncommercial Research License** |

**Reglas duras**: (1) un modelo AGPL entrenado con tus datos **no se despliega en un SaaS ni en un
producto cerrado** sin licencia comercial — hay proveedores que revenden esa licencia comercial,
verifica el alcance exacto; (2) `pip install` no es aceptación informada: la licencia se lee
**antes**; (3) el cumplimiento se automatiza en CI (`opensource-licensing-standards`), no se
recuerda.

**Datasets**: los conjuntos públicos son mayoritariamente **solo investigación**. Verificado:
**ImageNet** — *"Researcher shall use the Database only for non-commercial research and educational
purposes"*, y **vincula al empleador** si trabajas en una empresa con ánimo de lucro; **Cityscapes**
— no comercial, con permiso para distribuir "representaciones abstractas" (modelos entrenados) pero
no el dato; **KITTI** — CC BY-NC-SA. En **COCO** la licencia de **las anotaciones y la de las
imágenes no son la misma** (imágenes de terceros con sus propios términos): verifica ambas.
Consecuencia práctica que casi nadie comprueba: **unos pesos preentrenados sobre un dataset "solo
investigación" arrastran la duda al producto**. Decídelo con legal, no con una intuición.

**Biometría y videovigilancia** — el marco de riesgo vive en `ai-governance-standards` (AI Act,
clasificación, inventario, calendario) y el tratamiento del dato personal en
`privacy-engineering-standards` (base jurídica, DPIA, minimización, retención, derechos). Lo que
esta skill fija es la **parada técnica**: un rostro, una matrícula, una marcha o una huella son
**dato biométrico** en cuanto sirven para identificar, y ese proyecto **no arranca sin evaluación
previa**. El **AI Act (Reglamento (UE) 2024/1689) art. 5** prohíbe expresamente, verbatim:

- *"the placing on the market, the putting into service for this specific purpose, or the use of AI
  systems that create or expand facial recognition databases through the untargeted scraping of
  facial images from the internet or CCTV footage"* (art. 5.1.e);
- *"…the use of AI systems to infer emotions of a natural person in the areas of workplace and
  education institutions, except where the use of the AI system is intended to be put in place or
  into the market for medical or safety reasons"* (art. 5.1.f);
- *"…the use of biometric categorisation systems that categorise individually natural persons based
  on their biometric data to deduce or infer their race, political opinions, trade union
  membership, religious or philosophical beliefs, sex life or sexual orientation"* (art. 5.1.g);
- *"the use of 'real-time' remote biometric identification systems in publicly accessible spaces for
  the purposes of law enforcement"*, salvo las excepciones tasadas del art. 5.1.h con autorización
  judicial previa (art. 5.2-5.3).

Estas prohibiciones **aplican desde el 2-feb-2025**. La identificación biométrica **no prohibida**
cae en el **alto riesgo** del Anexo III con su régimen completo. Además, el art. 50.3 obliga al
desplegador de un sistema de **reconocimiento de emociones o categorización biométrica** a
*"inform the natural persons exposed thereto of the operation of the system"*. **Calendario y
matices: `ai-governance-standards` §3.3, que ya los tiene verificados contra el DOUE incluido el
Digital Omnibus.** Regla de ingeniería derivada: **cuando la identidad no es el objetivo, no la
captures** — detectar presencia, contar o medir ocupación se hace sin reconocer a nadie, y elegir la
variante que no identifica elimina el problema entero en vez de gestionarlo.

## 6. Evaluación, despliegue y deriva

**Evaluación**:

- **IoU** define qué cuenta como acierto; el umbral es una decisión de producto, no un valor por
  defecto. **mAP** promedia precisión media sobre clases y sobre umbrales de IoU.
- **mAP oculta la clase que te importa.** Un mAP global excelente convive con un 0,2 de AP en la
  clase de defecto crítico si esa clase es minoritaria. **Reporta siempre AP por clase**, y fija el
  criterio de aceptación sobre la clase que decide el negocio, no sobre el promedio.
- **Matriz de confusión por clase** con los fondos incluidos: separa "no lo vio" de "lo vio y lo
  llamó otra cosa". Son fallos con arreglos distintos (más datos vs. mejor guía de etiquetado).
- **Curva precisión-recall completa** y elección explícita del punto de operación según el coste
  asimétrico: en inspección, un falso negativo que llega al cliente no vale lo mismo que un falso
  positivo que solo cuesta una revisión.
- **Evaluar en el dominio de despliegue, no en el conjunto público.** El conjunto de prueba se
  captura en la línea, la tienda o la calle donde va a correr, se congela y **no se toca**. Una
  cifra de *benchmark* público es una señal de capacidad de la arquitectura, jamás una predicción
  de tu rendimiento.
- **Partición por grupo, no aleatoria**: fotogramas del mismo vídeo, imágenes del mismo lote, de la
  misma pieza o de la misma persona van **enteros** al mismo lado. Partir al azar fotogramas
  consecutivos es fuga y produce métricas de fantasía (`classical-ml-standards`).

**Despliegue**:

- **Presupuesto de fotograma explícito** antes de elegir modelo: FPS objetivo, resolución de
  entrada, número de cámaras por dispositivo y latencia extremo a extremo (captura → preproceso →
  inferencia → posproceso → acción). **El NMS y el preproceso pueden costar más que la red**;
  mídelos por separado.
- **Cuantización y exportación**: exporta a ONNX como base portable y compila al motor del hardware
  final (TensorRT en NVIDIA, OpenVINO en Intel, LiteRT/NNAPI en Android, Core ML en Apple).
  **Reevalúa la métrica completa después de cuantizar** —no solo un par de imágenes—: INT8 sin
  calibración representativa hunde selectivamente las clases raras, que son las que importan (§4).
- **El preprocesado debe coincidir exactamente entre entrenamiento y producción. Es la fuente
  número uno de degradación silenciosa** y no da error: da menos precisión. Puntos de fallo
  reales: orden de canales (BGR de OpenCV vs. RGB de PIL/torchvision), algoritmo de redimensionado
  e interpolación, *letterbox* con o sin relleno y su color, media y desviación de normalización,
  rango 0-255 vs. 0-1, EXIF de orientación aplicado o no, y el espacio de color del decodificador
  de vídeo. **Regla**: el preprocesado se implementa **una vez**, se versiona junto al modelo y se
  verifica con un test de igualdad numérica entre el pipeline de entrenamiento y el de servicio
  sobre las mismas imágenes (§7).

**Deriva** (detección aquí, gobierno en `mlops-standards`): en visión la deriva casi nunca es
"cambió el mundo", es **cambió el sensor**. Disparadores conocidos: sustitución de cámara o de
lente, actualización de firmware que altera el balance de blancos o la compresión, cambio de
iluminaria, suciedad o condensación en el óptica, reposicionamiento del montaje, cambio de estación
o de turno, y cambio de formato del envase o de la pieza. Vigila **estadísticos de la imagen**
(brillo, contraste, nitidez, histograma por canal) y **la distribución de las salidas** (confianza
media, número de detecciones por fotograma) — se degradan antes de que nadie reporte un fallo.
**Cualquier cambio físico en la instalación dispara reevaluación**, y eso se pacta con el
responsable de mantenimiento, no se descubre después.

## 7. Sostenibilidad y prohibiciones

Mantenimiento: fija el **motor de inferencia** (ONNX Runtime, TensorRT, OpenVINO) como dependencia
versionada y prueba la migración con el conjunto congelado antes de subir versión. Comprueba la
**actividad real** del proyecto antes de casarte con él: a ago-2026, MMDetection no publica versión
etiquetada desde ene-2024 y Detectron2 desde 2021 — usables, pero sin soporte que esperar.

- ❌ **PROHIBIDO** usar un modelo AGPL (Ultralytics y derivados, YOLOv10) en producto cerrado, SaaS
  o herramienta interna sin licencia comercial escrita.
- ❌ **PROHIBIDO** desplegar pesos sin haber leído su fichero de licencia **en crudo** y comprobado
  que no es una licencia propia del proveedor con restricciones de uso.
- ❌ **PROHIBIDO** entrenar o desplegar con un dataset "solo investigación" en un producto comercial.
- ❌ **PROHIBIDO** empezar a etiquetar sin guía escrita y sin medir el acuerdo entre anotadores.
- ❌ **PROHIBIDO** reportar solo mAP global: sin AP por clase y matriz de confusión, la evaluación
  no está hecha.
- ❌ **PROHIBIDO** evaluar en un conjunto público y desplegar en otro dominio como si midiera lo
  mismo.
- ❌ **PROHIBIDO** partir aleatoriamente fotogramas de un mismo vídeo o imágenes de una misma pieza
  entre entrenamiento y prueba.
- ❌ **PROHIBIDO** aplicar aumento de datos que invalida la etiqueta (volteo en texto/lateralidad,
  color cuando el color es la clase) o aumento de mezcla en validación.
- ❌ **PROHIBIDO** dos implementaciones distintas del preprocesado, una para entrenar y otra para
  servir. Una sola, versionada con el modelo y con test de igualdad numérica.
- ❌ **PROHIBIDO** dar por buena una exportación o una cuantización sin reevaluar la métrica
  completa sobre el conjunto congelado.
- ❌ **PROHIBIDO** ajustar el umbral de confianza mirando el conjunto de prueba.
- ❌ **PROHIBIDO** capturar o inferir identidad biométrica cuando la tarea no la necesita.
- ❌ **PROHIBIDO** arrancar un proyecto de reconocimiento facial, categorización biométrica o
  inferencia de emociones sin clasificación de riesgo previa y base jurídica documentada (§5).
- ❌ **PROHIBIDO** almacenar imágenes de personas sin política de retención y borrado.
- ❌ **PROHIBIDO** cambiar cámara, lente, iluminación o montaje sin reevaluar el modelo.

## 8. Verificación web obligatoria

1. **Licencia de los pesos, versión por versión y proveedor por proveedor** —el mismo nombre de
   modelo cambia de licencia entre encarnaciones—, leyendo `LICENSE`/`LICENSE.md`/`COPYING` **en
   crudo** en la rama correcta y la ficha del modelo aparte: **son documentos distintos**.
2. Estado y términos de las **licencias comerciales de reventa** para modelos AGPL: qué modelos
   cubren, con qué alcance y hasta cuándo.
3. **Licencia y términos de uso de cada dataset** —imágenes y anotaciones por separado— y de los
   pesos preentrenados sobre él.
4. **Mantenimiento real** de marcos y herramientas de anotación (última versión etiquetada, ritmo
   de *commits*, CVEs abiertas) antes de fijarlos.
5. Versión y soporte de hardware de **ONNX / ONNX Runtime / TensorRT / OpenVINO / LiteRT / Core ML**
   y su matriz de compatibilidad con el modelo que exportas.
6. **AI Act**: texto vigente del art. 5 y del art. 50, calendario y modificaciones del *Digital
   Omnibus* — contrástalo con `ai-governance-standards` §3.3 y con el DOUE.
7. **Hueco declarado**: este documento **no fija ninguna cifra de exactitud, mAP, FPS ni latencia**.
   No se han verificado cifras de *benchmark* con sus condiciones de medida (resolución, hardware,
   precisión, tamaño de lote, si incluye NMS y preproceso), y **sin esas condiciones una cifra no
   significa nada**. Si necesitas comparar, mide tú en tu hardware con tu conjunto congelado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
