---
name: deep-learning-standards
description: Training your own deep neural network as an engineering decision, not a default. Use when justifying a custom network against a classical model, a frozen pretrained backbone or a third-party API, writing PyTorch training code with nn.Module, DataLoader, torch.compile, torch.amp autocast and GradScaler, gradient accumulation and gradient clipping, checkpointing and resuming with torch.save/load_state_dict, seeding with torch.manual_seed and torch.use_deterministic_algorithms, scaling with DistributedDataParallel, FSDP, torchrun or accelerate versus model/tensor/pipeline parallelism, diagnosing a loss that will not go down or a train/val curve gap, dataloader bottlenecks and storage formats (webdataset, Parquet, tfrecord, memory-mapped tensors), label quality and annotation error, holding out an untouched test set, or shrinking a model for deployment with quantization, pruning, distillation, ONNX or TorchScript export. Also covers PyTorch versus JAX versus Keras/TensorFlow selection.
---

# Estándares de deep learning — entrenar una red propia

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **entrenar una red neuronal profunda que tú posees**: justificación, elección de marco,
reproducibilidad, bucle de entrenamiento en producción, datos y etiquetas, regularización y
diagnóstico, evaluación honesta y compresión del modelo para desplegarlo.

Triggers: `nn.Module`, `DataLoader`, `optimizer.step()`, `loss.backward()`, `torch.compile`,
`torch.amp` / `autocast` / `GradScaler`, `torch.manual_seed`,
`torch.use_deterministic_algorithms`, `DistributedDataParallel`, `FSDP`, `torchrun`,
`accelerate launch`, `deepspeed`, `state_dict`, `checkpoint.pt`, `jax`/`flax`/`optax`,
`keras`/`KERAS_BACKEND`, `tf.data`, `webdataset`, `.onnx`, `torch.jit`, "la pérdida no baja",
"se sobreajusta", "NaN en el loss", "el entrenamiento tarda tres días", "la GPU está al 20 %",
"cuántas épocas", "cuantizar el modelo", "destilar", "podar".

**Tesis del dominio**: **entrenar una red profunda propia es una decisión que hay que justificar
frente a tres alternativas más baratas** —(a) un modelo clásico, (b) un modelo preentrenado
congelado con una cabeza entrenada encima, (c) una API de terceros—. Ninguna de las tres exige
mantener un ciclo de entrenamiento, ni GPUs, ni la deuda de reproducibilidad que trae. La red
propia se justifica cuando concurre al menos una de estas condiciones **y se puede argumentar**:

- **Datos propios abundantes y etiquetados** en un dominio que ningún preentrenado cubre.
- **Requisito de latencia o de despliegue local** (borde, aislamiento de red, soberanía del dato)
  que ninguna API satisface.
- **Coste unitario de inferencia** que a tu volumen hace inviable la API — con la cuenta hecha,
  no intuida (`finops-standards`).
- **La tarea no existe como servicio**: modalidad, formato o estructura de salida propios.

Corolario: **`classical-ml` no es "deep learning pequeño"** y esta skill no es su versión
grande. Si el dato es tabular, la carga de la prueba está en la red (ver
`classical-ml-standards` §2.1), no en el *gradient boosting*.

**No aplica**:

- `mlops-standards` (**escrita — frontera crítica**): **el ciclo de vida del modelo en producción
  es suyo** — versionado de datos y experimentos, registro de modelos, *feature store*,
  despliegue, *train/serve skew*, **deriva**, reentrenamiento y retirada. **Aquí, cómo se entrena
  y se evalúa el modelo antes de llegar ahí.** El caso frontera se resuelve así: **una métrica
  offline que mejora y una producción que empeora se diagnostica aquí como problema de
  distribución y se vigila allí como deriva.**
- `classical-ml-standards` (**esta misma ola**): partición, fuga, validación, métricas,
  calibración, umbral y modelos tabulares. **Las secciones de fuga, línea base, métricas y umbral
  no se duplican aquí: se aplican igual y viven allí.**
- `model-finetuning-standards` (**esta misma ola**): **el ajuste fino no es entrenar.** Partir de
  pesos ajenos y moverlos poco (LoRA/QLoRA, SFT, preferencias) es suyo; entrenar desde cero o
  todos los pesos de un modelo propio es de aquí. Congelar un *backbone* y entrenar solo la
  cabeza es de esta skill; mover los pesos de un *backbone* generativo es suyo.
- `llm-app-engineering-standards` y `rag-standards` (**escritas**): **construir producto sobre un
  LLM de terceros es suyo**, igual que la recuperación. El orden **prompt → recuperación →
  ajuste fino → entrenamiento propio** es la escalera de coste del catálogo; desde este lado solo
  se afirma el último peldaño: **entrenar es el más caro y el que más se elige por defecto sin
  justificarlo.**
- `llm-evaluation-standards` (**escrita**): **la medición de sistemas no deterministas es suya** —
  conjuntos de evaluación, jueces LLM, significancia, gates en CI. Aquí se exige el conjunto de
  prueba intocado y la línea base; el método de medir cuando la salida es texto libre, allí.
- `local-inference-standards` (**escrita**): **servir pesos propios es suyo** — vLLM, llama.cpp,
  batching, caché KV, cuantización *en servicio*. Aquí, la cuantización/poda/destilación como
  **decisión de diseño del modelo**; el motor que lo sirve, allí.
- `gpu-computing-standards`: **la GPU como recurso que se aprovisiona, comparte y paga** —
  drivers, CUDA, MIG, colas, DCGM, refrigeración. Aquí, solo el trabajo que la usa.
- `mlsecops-standards` (**escrita**): **envenenamiento de datos, procedencia de los pesos,
  formatos seguros (`safetensors` frente a `pickle`), `trust_remote_code`, firma y AIBOM y los
  ataques al modelo son suyos.** Aquí se enuncian como higiene (§5) y se delega el análisis.
- `data-engineering-standards`, `data-governance-quality-standards`: la tubería y la calidad del
  dato. **La calidad de las *etiquetas* se trata aquí** (§4.1): es propiedad del problema de
  aprendizaje, no del pipeline.
- `ai-governance-standards` (riesgo, AI Act, inventario); `privacy-engineering-standards` (dato
  personal y memorización); `finops-standards`, `green-it-standards` (coste y huella);
  `python-standards`, `r-standards`, `julia-standards`; `kubernetes-standards`,
  `object-storage-standards`, `observability-standards`; `computer-vision-standards`,
  `nlp-standards`, `multimodal-genai-standards` (**Ola 7**: aplicaciones por modalidad).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.1 Marco

| Pieza | Elección | Estado verificado (ago-2026) |
|---|---|---|
| Marco por defecto del catálogo | **PyTorch** | `torch` 2.13.0, publicado 8-jul-2026 (PyPI); metadatos de licencia: `Apache-2.0 AND Apache-2.0 WITH LLVM-exception AND BSD-2-Clause AND BSD-3-Clause AND BSL-1.0 AND MIT` |
| Alternativa legítima (TPU, transformación de funciones, paralelismo declarativo) | **JAX** | `jax` 0.11.0, 16-jul-2026 (PyPI); cadencia de *releases* mensual (v0.9.2 mar-2026, v0.10.0 abr, v0.10.1 may, v0.10.2 jun, v0.11.0 jul) |
| Capa alta portable | **Keras 3** | `keras` 3.15.1, 29-jul-2026. Verbatim del README: *"Keras 3 is a multi-backend deep learning framework, with support for JAX, TensorFlow, PyTorch, and OpenVINO (for inference-only)"* |
| TensorFlow | **Solo mantenimiento de lo que ya existe** | `tensorflow` 2.21.0, 6-mar-2026; el *release* anterior, 2.20.0, es de 13-ago-2025 (feed Atom de GitHub): ~7 meses entre versiones menores |

**Honestidad sobre el estado del ecosistema, con lo que sí es verificable**: PyTorch y JAX
publican con cadencia alta y sostenida; **TensorFlow tiene una cadencia de *releases* mucho más
espaciada** y Keras 3 ya no es su capa exclusiva, sino una fachada multi-backend cuyo propio
README lista JAX en primer lugar y TensorFlow como uno más. **Criterio**: proyecto nuevo →
PyTorch, salvo razón concreta (TPU, código JAX existente, requisito de despliegue móvil sobre el
tooling de TF). Proyecto existente en TensorFlow → **no se migra por moda**; se migra si el
tooling que necesitas ya no llega, y se declara como proyecto con su coste. **No se afirma aquí
ninguna cuota de mercado ni de publicaciones: las fuentes disponibles son blogs sin metodología y
se contradicen entre sí (§8).**

### 2.2 Antes de entrenar, en este orden

1. **Línea base clásica** (`classical-ml-standards`) o heurística. Sin ella no hay contexto.
2. **Preentrenado congelado + cabeza lineal**. Barato, rápido y sorprendentemente competitivo;
   es la línea base real de cualquier red propia.
3. **Preentrenado con ajuste fino** (`model-finetuning-standards` si es generativo).
4. **Entrenamiento desde cero**: solo con las condiciones de §1 argumentadas por escrito.

**PROHIBIDO entrenar desde cero lo que existe preentrenado** salvo justificación explícita de
dominio, licencia o restricción de despliegue (§7).

## 3. Reproducibilidad

- **Semillas**: Python, NumPy y el marco; y la semilla del *sampler*/*shuffle* del `DataLoader` y
  de cada *worker*. Se registran junto al resto de la configuración del experimento
  (`mlops-standards`).
- **La reproducibilidad exacta cuesta rendimiento**, y el propio PyTorch lo dice. Verbatim de la
  nota de reproducibilidad de la documentación (2.13): *"Completely reproducible results are not
  guaranteed across PyTorch releases, individual commits, or different platforms."* / *"Furthermore,
  results may not be reproducible between CPU and GPU executions, even when using identical
  seeds."* / *"torch.use_deterministic_algorithms() lets you configure PyTorch to use deterministic
  algorithms instead of nondeterministic ones where available."* / *"Deterministic operations are
  often slower than nondeterministic operations, so single-run performance may decrease for your
  model."*
- **Criterio operativo**: el determinismo completo se activa **para depurar** y en tests de
  regresión pequeños; en entrenamiento largo se acepta el no determinismo de la GPU (reducciones
  atómicas, selección de kernels, TF32) y se compensa **reportando varianza entre semillas**.
- **Lo que sí debe ser reproducible siempre**: versión del código y de los datos,
  hiperparámetros, entorno (imagen, CUDA/driver) y el *checkpoint*. La aleatoriedad numérica es
  negociable; la trazabilidad, no.

## 4. Datos, bucle de entrenamiento y diagnóstico

### 4.1 Datos y etiquetas

- **La calidad de las etiquetas es el factor con más impacto y menos atención.** Antes de cambiar
  de arquitectura, muestrea 100-200 ejemplos y anótalos tú: si el desacuerdo con la etiqueta
  existente es alto, **estás midiendo ruido y ningún modelo lo arreglará**. Mide acuerdo entre
  anotadores, define la guía y revisa los errores del modelo buscando etiquetas mal puestas.
- **El cargador de datos es el cuello de botella real** en casi todo entrenamiento que "no
  aprovecha la GPU": si la utilización oscila, es E/S o preprocesado en CPU. Palancas: *workers*,
  *prefetch*, `pin_memory`, preprocesado offline, decodificación en GPU.
- **Formato de almacenamiento**: millones de ficheros pequeños en objetos o NFS es el antipatrón
  clásico; agrupar en *shards* secuenciales (webdataset/tar, Parquet, tensores mapeados en
  memoria) cambia el orden de magnitud. Coste de almacenamiento y egreso:
  `object-storage-standards` y `finops-standards`.
- **Partición y fuga**: mismas reglas que en `classical-ml-standards` §4.1-4.2. Con imágenes,
  audio o texto la fuga típica es el **duplicado casi idéntico** repartido entre train y test:
  deduplicar por similitud antes de partir, no después.

### 4.2 Bucle de entrenamiento en producción

| Requisito | Decisión |
|---|---|
| Interrupción y reanudación | *Checkpoint* periódico con **estado completo**: pesos, optimizador, *scheduler*, época/paso, estado del RNG y del *sampler*. Un checkpoint que solo guarda pesos no reanuda, reinicia. |
| Memoria y velocidad | **Precisión mixta** (bf16 preferido a fp16 por rango dinámico; fp16 exige escalado de pérdida) |
| Lote efectivo mayor que la VRAM | **Acumulación de gradientes**, ajustando el escalado del gradiente y la frecuencia del `step` |
| Estabilidad | Recorte de norma del gradiente, *warmup* + *schedule* de tasa de aprendizaje |
| Compilación | `torch.compile` cuando el grafo es estable; medir, no asumir: recompilaciones por formas variables pueden costar más de lo que ahorran |
| Coste | Presupuesto de horas-GPU **declarado antes** de lanzar, con corte automático |

### 4.3 Entrenamiento distribuido

- **Paralelismo de datos** (DDP y equivalentes): respuesta por defecto — el modelo cabe en una
  GPU y sobran datos. Escala casi lineal hasta que la comunicación domina.
- **Fragmentación de estado** (FSDP/ZeRO) cuando lo que no cabe es **el estado del optimizador y
  los gradientes**, no el modelo. Primera opción ante un "no cabe": menos invasiva que partirlo.
- **Paralelismo de modelo** (tensorial o por etapas) solo cuando **una capa o el modelo entero no
  caben** en un dispositivo: complica el código, mete burbujas de *pipeline* y ata la topología.
- **No distribuyas hasta haber medido que una GPU está saturada de verdad.** Un cargador mal
  configurado repartido entre ocho GPUs sigue estando mal, ocho veces más caro.

### 4.4 Regularización y diagnóstico

- **Curvas de entrenamiento y validación en el mismo gráfico, siempre.** Entrenamiento baja y
  validación sube = sobreajuste (más datos, más aumento, regularización, parada temprana, modelo
  menor). Ambas altas y planas = subajuste o problema de optimización.
- **Cuando la pérdida no baja**, en este orden: (1) sobreajusta a propósito un lote de 8 ejemplos
  —si no lo consigue hay un bug, no un problema de aprendizaje—; (2) comprueba alineación
  etiqueta-entrada y misma normalización en train e inferencia; (3) barre la tasa de aprendizaje
  dos órdenes de magnitud arriba y abajo; (4) revisa pérdida y última capa (activación duplicada,
  *logits* vs. probabilidades); (5) NaN → mixta sin escalado, división por cero o tasa alta.
- **Parada temprana con paciencia sobre validación**; el *checkpoint* guardado es el mejor de
  validación, no el último.

### 4.5 Evaluación

- **Conjunto de prueba intocado**: se mira **una vez**, al final, y con la línea base al lado.
  Cada mirada adicional lo convierte en conjunto de validación y su estimación deja de ser
  válida.
- **Ninguna métrica se publica sin condiciones de medida**: dataset y versión, partición,
  preprocesado, hardware, semilla(s), varianza entre ejecuciones y línea base.
- **Un modelo que mejora en la métrica y empeora en producción suele tener un problema de
  distribución**, no de modelo: el conjunto de evaluación no representa el tráfico real, o el
  tráfico cambió. Diagnóstico aquí (comparar distribuciones de entrada, segmentar el error por
  cohortes); **la vigilancia continua de la deriva es de `mlops-standards`**.
- **Evalúa por segmentos, no solo en agregado**: una métrica global estable puede esconder un
  colapso en un subgrupo. El *fairness* como propiedad medible se calcula aquí; su aceptabilidad
  se decide en `ai-governance-standards`.

## 5. Seguridad y procedencia

- **Pesos de terceros**: descarga por revisión/digest fijado, `safetensors` frente a formatos con
  `pickle`, `trust_remote_code` desactivado salvo revisión explícita, verificación de firma. El
  criterio completo es de `mlsecops-standards`; aquí es requisito de entrada.
- **Envenenamiento de datos**: cualquier corpus scrapeado o contribuido por usuarios es superficie
  de ataque sobre el modelo entrenado. Procedencia declarada por fuente y capacidad de excluir un
  origen y reentrenar.
- **Memorización y PII**: una red entrenada sobre datos personales puede reproducirlos. La base
  de licitud, la minimización y el borrado son de `privacy-engineering-standards`, y hay que
  resolverlos **antes** de entrenar: no hay `DELETE` en un `.safetensors`.
- Secretos, credenciales de almacenamiento y tokens de *hub* nunca en el código de entrenamiento
  ni en la imagen (`secrets-management-standards`).

## 6. Eficiencia y coste

- **Cuantización, poda y destilación son decisiones de despliegue con pérdida medible**, no
  optimizaciones gratuitas. Se decide con la métrica de la tarea antes y después, sobre el mismo
  conjunto, y con la latencia/memoria objetivo declarada. Orden habitual de rentabilidad:
  cuantización post-entrenamiento → destilación a un modelo menor → poda estructurada.
  Cuantización *en el motor de servicio*: `local-inference-standards`.
- **Exportación** (ONNX, TorchScript, compiladores de inferencia): valida numéricamente la
  equivalencia sobre un conjunto de casos antes de sustituir; una diferencia de preprocesado
  entre entrenamiento y export es *train/serve skew* (`mlops-standards`).
- **El coste es una restricción de diseño, no una factura sorpresa**: horas-GPU con presupuesto y
  corte, y coste por predicción en inferencia (que a volumen alto domina al de entrenamiento).
  Política: `finops-standards`; huella: `green-it-standards`; GPU compartida:
  `gpu-computing-standards`.
- Observabilidad del entrenamiento: utilización de GPU y memoria, tiempo por paso, muestras/s, y
  alerta si un trabajo lleva N horas con la GPU al 20 %.

## 7. Sostenibilidad y prohibiciones

- Versión de marco, CUDA y driver fijadas en la imagen y actualizadas deliberadamente: un cambio
  mayor puede mover las métricas y se trata como experimento, no como mantenimiento. Un modelo
  entrenado sin código, datos y configuración recuperables **es un artefacto muerto**: no se
  depura ni se reproduce, y retirarlo es la única opción honesta.

**PROHIBIDO**:

- ❌ **Entrenar sin línea base** (clásica, preentrenado congelado o heurística).
- ❌ **Mirar el conjunto de prueba más de una vez**, o usarlo para elegir arquitectura,
  hiperparámetros, *checkpoint* o umbral.
- ❌ **Publicar una métrica sin condiciones de medida** (dataset, partición, hardware, semillas,
  varianza, línea base).
- ❌ **Entrenar desde cero lo que existe preentrenado**, sin justificar dominio, licencia o
  restricción de despliegue.
- ❌ Escalar a multi-GPU sin haber demostrado que una GPU está saturada.
- ❌ *Checkpoints* que solo guardan pesos en un entrenamiento que dura más que la ventana de
  interrupción de la infraestructura.
- ❌ Cargar pesos de terceros con `pickle` o `trust_remote_code` sin revisión.
- ❌ Presentar una mejora del 0,3 % con una sola semilla como resultado.
- ❌ Cambiar arquitectura antes de haber inspeccionado manualmente una muestra de etiquetas.
- ❌ Cuantizar o podar sin medir la pérdida de calidad en la métrica de la tarea.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

- Última estable de **PyTorch, JAX, Keras y TensorFlow**, y la matriz de compatibilidad
  PyTorch ↔ CUDA ↔ driver ↔ Python: es la fuente número uno de entornos rotos.
- Estado del ecosistema: cadencia de *releases* en los feeds Atom de GitHub y notas oficiales.
  **Hueco declarado**: no se fija aquí ninguna cuota de uso, publicaciones ni empleo entre marcos
  — las fuentes localizadas son artículos sin metodología publicada y **se contradicen entre sí**
  (cifras de "cuota de investigación" del 55 % al 85 % según la página). Si necesitas el dato,
  exige encuesta con muestra y método.
- **Hueco declarado**: ninguna cifra de aceleración de `torch.compile`, precisión mixta ni
  escalado distribuido; dependen de modelo, lote y hardware y rara vez traen condiciones.
- Estado de las APIs de entrenamiento distribuido (DDP/FSDP y sus versiones) antes de escribir
  código: han cambiado de nombre y de recomendación entre versiones mayores. Y qué operaciones
  siguen sin implementación determinista en la versión que uses.
- CVEs del marco, del runtime de GPU y de las bibliotecas de carga de modelos
  (`vulnerability-management-standards`), y licencias reales de cualquier peso preentrenado que
  incorpores: **la licencia de unos pesos no es una licencia de software** y rara vez es OSI
  (ver `model-finetuning-standards` §5 y `opensource-licensing-standards`).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
