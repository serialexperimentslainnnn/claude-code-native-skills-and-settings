---
name: mlops-standards
description: Use when the lifecycle of a model you train and own runs as production engineering — versioning datasets and training runs with DVC or lakeFS, tracking experiments in MLflow or Weights & Biases, promoting artifacts through a model registry with model cards, stages and approval, orchestrating training pipelines with Airflow, Kubeflow, Metaflow, Prefect or Dagster, a feature store (Feast) and train/serve skew, batch versus online versus streaming serving with shadow and canary rollout and model rollback to the previous weights and preprocessing, detecting data drift versus concept drift with Evidently when the label arrives late or never, proxy metrics and feedback loops where the model shapes its own future data, retraining triggered by schedule, threshold or event, training versus inference cost, model retirement, or fairness and bias measured as a system property.
---

# Estándares de MLOps — el ciclo de vida del modelo como ingeniería de producción

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando **entrenas, registras, despliegas, vigilas, reentrenas y retiras un modelo propio**:
ML clásico (tabular, series, visión, texto), *fine-tuning* de un modelo abierto, o cualquier
artefacto entrenado cuyo comportamiento dependa de datos que tú controlas. Cubre el dato como
artefacto versionado, la experimentación, el registro de modelos como frontera hacia producción,
el pipeline de entrenamiento, las *features* y el *skew*, el despliegue y el *rollback*, la
monitorización en producción (deriva, métricas *proxy*, bucles de retroalimentación), el
reentrenamiento, el coste y la retirada.

Triggers: "el modelo ha empeorado", "reentrenar", "deriva", "drift", "data drift", "concept
drift", "train/serve skew", "feature store", "registro de modelos", "model registry", "promover a
producción", "model card", "versionar el dataset", `dvc.yaml`, `.dvc`, `dvc repro`, `lakectl`,
`mlflow.log_metric`, `mlflow.register_model`, `MLmodel`, `MLproject`, `wandb.init`, `dag.py` de
entrenamiento, `KFP`/`@dsl.pipeline`, `@step` de Metaflow, `@flow`/`@task`, `@asset`,
`feature_store.yaml`, `get_historical_features` vs. `get_online_features`, `Evidently`,
`predict_proba` en batch nocturno, *shadow deployment*, "volver al modelo anterior", "la etiqueta
tarda semanas", "el notebook con el que entrenamos el bueno", coste de inferencia por predicción,
sesgo y *fairness* medidos.

**Tesis del dominio — se aplica en todo el documento**: **un sistema de ML no falla como falla el
software; se degrada en silencio con el código intacto.** Tres consecuencias que ordenan el resto:

1. **El código es la parte pequeña.** La mayor parte del sistema es dato, configuración,
   extracción de *features*, verificación y monitorización — la "deuda técnica oculta" del ML.
   Un repo impecable con un pipeline de datos sin contratos es un sistema frágil.
2. **La entrada cambia sola.** Nadie despliega y sin embargo la precisión cae: cambió el mundo,
   el proveedor del dato o el comportamiento del usuario. Sin monitorización del **dato**, la
   primera señal es una queja de negocio meses tarde.
3. **Reproducibilidad es un requisito funcional, no higiene.** Si no puedes reconstruir el modelo
   que está sirviendo hoy —datos, código, hiperparámetros, entorno, semilla—, no puedes
   depurarlo, auditarlo ni revertirlo. Y tarde o temprano tendrás que hacer las tres cosas.

**No aplica**:

- `timeseries-db-standards`: **el motor de la serie temporal y su política de retención son
  suyos**, y esa política es una **restricción de esta skill, no un detalle de almacenamiento**:
  el *rollup* que baja la resolución del histórico destruye el conjunto de entrenamiento y con él
  la reproducibilidad que aquí se exige. Regla: **antes de aceptar un downsampling, declara qué
  señales alimentan un modelo y consérvalas crudas**; si no se puede, el modelo deja de ser
  reconstruible y eso se registra como deuda, no se descubre al reentrenar.
- `data-engineering-standards`: **el pipeline de datos que alimenta al modelo
  es suyo** — ingesta, ELT, idempotencia, *backfill*, Parquet, coste de escaneo, frescura y
  observabilidad del dato. Comparten orquestador (Airflow, Dagster, Prefect) y eso es solape
  inherente, no de propiedad. **Regla de arbitraje: si el artefacto producido es una tabla que
  consume gente o BI, es suya; si es un modelo entrenado o las *features* que lo alimentan, es de
  esta skill.** El *feature store* y el *train/serve skew* son de aquí.
- `classical-ml-standards`, `deep-learning-standards` y `model-finetuning-standards`
  (**frontera de "antes y después"**): **cómo se entrena y se evalúa un modelo es suyo**
  —partición y fuga de datos, validación, métricas y calibración, umbral de decisión, bucle de
  entrenamiento, y el orden prompt → recuperación → **ajuste fino**—; **el ciclo de vida en
  producción es de aquí**: registro, versionado, *feature store*, despliegue, deriva, reentrenamiento
  y *train/serve skew*. Corrección de esta skill: donde decía que *"un fine-tuning propio cruza a
  esta skill"*, **el criterio de ajuste fino es ahora de `model-finetuning-standards`**; lo que
  sigue siendo de aquí es el registro, la promoción y la operación del artefacto resultante.
- `r-standards` y `julia-standards`: **el ciclo de vida del modelo es de esta
  skill** —registro, versionado, *feature store*, despliegue, monitorización de deriva,
  reentrenamiento, *train/serve skew*—, **con independencia del lenguaje en que se entrene**;
  **cómo se escribe ese R o ese Julia** —`renv` y reproducibilidad de la librería, estabilidad de
  tipos, tests, estilo, empaquetado— es de esas skills. El caso peligroso que ambas partes deben
  reconocer: **un análisis exploratorio que se convierte en servicio sin reescribirse** es deuda
  que aquí se cobra en producción.
- `data-warehouse-modeling-standards`: grano, hechos y dimensiones, SCD,
  dimensiones conformadas y la definición canónica de una métrica de negocio. **Una tabla de
  *features* no es un mart** y no se rige por su modelado; pero si tus *features* se derivan de
  marts, su grano y su historización son de allí.
- `llm-app-engineering-standards` (*la confusión más común de este dominio,
  y se declara explícitamente*): **construir producto sobre un LLM de terceros no es MLOps.** No
  entrenas nada, no tienes pesos, no hay deriva de *tu* modelo sino cambios de versión del
  proveedor, y el "registro de modelos" es una cadena en un fichero de configuración. Allí viven
  prompts versionados, salida estructurada, ventana de contexto, caché, reintentos y límites de
  gasto. **Regla de arbitraje: si el artefacto que promueves son pesos que tú produjiste, es de
  esta skill; si es un prompt y un identificador de modelo ajeno, es suya.** Un *fine-tuning*
  propio cruza a esta skill; llamar a un modelo afinado por el proveedor, no.
- `llm-evaluation-standards`: **la medición de calidad es suya** — conjuntos
  de evaluación, LLM-as-judge y su calibración, assertions deterministas, significancia, gates de
  regresión en CI, anotación de trazas. Aquí se **exige la evaluación como gate** (§4) y se define
  **qué se registra para que sea reproducible y comparable entre versiones de modelo**; la
  metodología de medir vive allí. Frontera fina: **el número lo produce ella, la decisión de
  promover o revertir con ese número es de aquí.**
- `mlsecops-standards`: lo **adversario y la cadena de suministro del
  modelo** — procedencia e integridad de pesos de terceros, `safetensors` frente a formatos con
  `pickle`, `trust_remote_code`, `picklescan`/`modelscan`, firma de artefactos y pin por digest,
  AIBOM/ML-BOM, envenenamiento de datos y de pesos, *backdoors*, extracción, inversión e
  inferencia de pertenencia, *red teaming* con `garak`/`PyRIT`, y el mapeo a MITRE ATLAS y OWASP
  GenAI. Aquí, la **operación del ciclo de vida**. Fronteras compartidas, resueltas así: **el
  formato de artefacto y el pin por digest los exige esta skill como requisito de reproducibilidad
  y los razona ella como amenaza**; la deserialización insegura (§5) y el incidente de cadena de
  suministro se **enuncian aquí como prohibición operativa** y se **analizan allí**. Si la
  pregunta es "¿me pueden atacar por aquí?", es suya; si es "¿cómo lo despliego y lo vigilo?", es
  de esta skill.
- `ai-governance-standards`: **decide y responde; aquí se
  opera.** El **registro de modelos** (artefactos que tú entrenas y sirves, con sus métricas y su
  linaje) es de esta skill; el **inventario de sistemas de IA** —que incluye herramientas de
  terceros que tú no operas, SaaS con IA embebida y la IA en la sombra— es suyo. La clasificación
  de riesgo del AI Act, la supervisión humana como obligación, la evaluación de impacto y la
  rendición de cuentas son suyas; **el *fairness* como propiedad medible del sistema es de aquí**
  (§6.5) — tú produces el número, ella decide qué umbral es aceptable y quién firma.
- `data-platform-standards`: el **almacén** — PostgreSQL, Kafka, particionado, réplicas, PITR,
  retención del motor. Aquí, el dataset **como artefacto versionado y reproducible**, no la base
  de datos que lo aloja.
- `object-storage-standards`: **dónde viven datasets y artefactos** (S3/MinIO/Ceph), versionado
  de objetos, clases de almacenamiento, ciclo de vida y coste de egreso. Un *checkpoint* de
  decenas de GB por experimento tiene factura: el criterio de retención del bucket es suyo.
- `sre-practice-standards`: SLO, error budget, guardia y *capacity planning* del **servicio** que
  sirve el modelo. Aquí, las métricas **del modelo**, que un SLO de latencia no ve: un servicio
  con 99,99 % de disponibilidad puede estar sirviendo predicciones basura.
- `cicd-standards`: el **pipeline genérico** — runners, OIDC, SBOM, firma, gates. Aquí, qué gate
  específico de ML añade (§4) y por qué "los tests pasan" no significa "el modelo sirve".
- `kubernetes-standards` (manifiestos, Helm, GitOps del despliegue), `gpu-computing-standards`
  (**la GPU como recurso**: driver, MIG, DCGM, coste y refrigeración — aquí solo el trabajo que
  la usa), `local-inference-standards` (**servir modelos abiertos**: vLLM, cuantización, caché KV
  — si sirves pesos abiertos sin entrenarlos, manda esa skill), `observability-standards` (OTel,
  Prometheus, alertas — aquí solo **qué** métrica de modelo importa), `iac-standards`,
  `python-standards` (código de entrenamiento como código de producción),
  `incident-management-standards` (un modelo degradado que causa impacto **es un incidente** y se
  gestiona allí), `bcdr-standards`, `identity-access-management-standards`,
  `secrets-management-standards`, `vulnerability-management-standards` (triaje y SLA de los CVE
  de §5), `privacy-engineering-standards` (**dato personal en entrenamiento, minimización,
  memorización, DPIA** — si el dataset tiene PII, la base de licitud y la retención se deciden
  allí, no aquí), `grc-compliance-standards` (marco de gestión y evidencia de auditoría),
  `rag-standards` y `ai-agents-standards` (capa de aplicación), `mcp-standards`.
- **`claude-api`** (sin sufijo `-standards`, **skill instalada, referencia canónica del lado
  Anthropic**): IDs de modelo, precios, parámetros, caché, batches. **Ningún dato de modelos
  Claude se afirma de memoria**; si comparas el coste de entrenar y servir propio contra una API
  gestionada, el lado de Anthropic sale de ahí.

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión, la licencia y el estado del proyecto por web antes de fijarlo en
> un proyecto real (§8). **Este ecosistema cambia de dueño y de licencia con frecuencia**: en los
> últimos meses lakeFS (Treeverse) absorbió DVC y Prefect compró Dagster (§7).

| Decisión | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Versionado de dataset (proyecto pequeño/mediano, ficheros) | **DVC 3.67.x** (Apache-2.0). **Cambio de titularidad**: lakeFS/Treeverse adquirió el proyecto a Iterative.ai (anunciado nov-2025); el repo vive ya en `treeverse/dvc`. Licencia sin cambios | Un `git-lfs` sin linaje ni pipeline: versiona el fichero, no el experimento |
| Versionado de dataset (data lake, escala, muchos consumidores) | **lakeFS 1.85.x** (Apache-2.0): ramas y *commits* sobre el propio object storage | Formatos de tabla con *time travel* (Iceberg/Delta) si el dato ya vive ahí — **es la opción más barata y a menudo la correcta**: no metas una pieza nueva si tu almacén ya versiona |
| Seguimiento de experimentos | **MLflow 3.15.x** (Apache-2.0) — de facto el estándar, autoalojable, con registro integrado | **Aviso de gobernanza**: MLflow está en la Linux Foundation desde 2020, pero el desarrollo y la dirección siguen dominados por Databricks. No se localizó ningún cambio de gobernanza en 2026 (**hueco declarado, §8**): trátalo como proyecto *single-vendor* de facto y valora ese riesgo antes de casarte con él |
| Alternativa gestionada de seguimiento | **Weights & Biases**: SDK cliente MIT, **servidor propietario/SaaS**. Excelente producto, *lock-in* real | No confundir "SDK open source" con "plataforma open source". Si el requisito es autoalojar sin licencia comercial, no es candidato |
| Registro de modelos | El de **MLflow** salvo requisito que lo descarte | Registro casero en una tabla: acaba sin *linaje*, sin aprobación y sin quien lo mantenga |
| Orquestación (el equipo ya tiene Airflow) | **Apache Airflow 3.3.x** (Apache-2.0) | **No introduzcas un orquestador nuevo solo por ML.** El coste operativo de una segunda plataforma casi nunca lo paga el beneficio |
| Orquestación (equipo de ciencia de datos, Python primero) | **Metaflow 2.19.x** (Apache-2.0, Netflix): el que menos ceremonia impone por unidad de valor | Prefect 3.8.x / Dagster 1.13.x (ambos Apache-2.0): **Prefect anunció la adquisición de Dagster Labs el 13-jul-2026** (marca combinada Prefect desde ago-2026; Dagster y Dagster+ conservan nombre, precio y hoja de ruta) — dos productos, un dueño; exige plan de convergencia antes de adoptar cualquiera de los dos a largo plazo |
| Orquestación (ya vives en Kubernetes y lo operas bien) | **Kubeflow Pipelines** (Apache-2.0, v1.10.x) | **Kubeflow completo es la pieza que más veces pesa más de lo que aporta**: si no tienes un equipo de plataforma dedicado, es una plataforma que te opera a ti |
| Feature store | **Ninguno por defecto.** Se añade cuando hay *skew* medido o *reuso real* de features entre equipos | **Feast 0.65.x** (Apache-2.0) si se justifica. Un feature store para un equipo y tres modelos es complejidad gratuita: el mismo resultado se consigue con **una sola función compartida de transformación** importada por entrenamiento e inferencia |
| Monitorización de modelo | **Evidently** (Apache-2.0) para deriva y calidad de dato, exportando a Prometheus/OTel | **Verificar actividad**: última release del feed observada en mar-2026 — comprobar mantenimiento antes de adoptarlo (§8). WhyLabs: verificar estado y modelo de licencia antes de recomendarlo |
| Serving en línea | **KServe 0.19.x/0.20.x** (Apache-2.0) si ya hay Kubernetes; **BentoML 1.4.x** (Apache-2.0) si no | **Seldon Core v2 está bajo Business Source License 1.1 desde ene-2024 — NO es open source**: uso en producción comercial requiere licencia de pago. `Change License` a Apache-2.0 a los cuatro años de cada release. **Descartado por defecto**; si aparece en una arquitectura heredada, es deuda con factura |
| Formato de artefacto | **ONNX** o **safetensors** cuando el framework lo permita | **`pickle`/`joblib` es ejecución de código arbitraria al cargar** (§5). Si es inevitable, el artefacto va firmado y su origen es un registro con control de acceso |
| Documentación del modelo | **Model card** obligatoria como condición de registro (§3.3) | Formato: el YAML estructurado del *hub* + narrativa. **No hay estándar normativo con tracción**: la capa de metadatos (YAML, Croissant para datasets) sí está estandarizada y automatizada; la narrativa (limitaciones, sesgo, procedencia) es la peor cubierta del ecosistema — precisamente la que te van a pedir en una auditoría |

**Regla de adopción**: cada pieza de este cuadro cuesta operación, actualizaciones y CVEs. La
arquitectura por defecto de un equipo pequeño es **git + un almacén de objetos versionado + MLflow
+ el orquestador que ya usas + un job de monitorización**. Todo lo demás se gana un sitio con un
problema medido, no con un diagrama de referencia.

## 3. Estructura y convenciones

### 3.1 Reproducibilidad — el requisito, no la aspiración

Un modelo en producción no existe si no puedes reconstruirlo. **Cinco ejes, todos obligatorios**:

| Eje | Cómo se fija | Fallo típico |
|---|---|---|
| **Datos** | Snapshot inmutable identificado por hash/commit/versión de tabla, no por ruta ni por `WHERE fecha > ...` ejecutado hoy | "El dataset" es una consulta que devuelve algo distinto cada día |
| **Código** | Commit de git, con el árbol limpio. CI se niega a entrenar desde un árbol sucio | Se entrenó con cambios locales sin commitear |
| **Hiperparámetros y config** | Fichero versionado en el repo, no argumentos de línea de comandos escritos a mano | El valor bueno vive en el historial de la shell de alguien |
| **Entorno** | Lockfile (`uv.lock`, `poetry.lock`) **y** imagen de contenedor por digest; versión de CUDA/driver anotada | "Funcionaba con la versión anterior de la librería" |
| **Semillas y no determinismo** | Semilla fijada y registrada; **y documentado qué sigue siendo no determinista** (GPU, paralelismo, orden de datos) | Prometer bit-a-bit lo que el hardware no da: se registra la **tolerancia**, no una igualdad falsa |

**El antipatrón central: "el notebook que entrenó el modelo bueno".** Un notebook tiene estado
oculto, orden de ejecución no reproducible, dependencias implícitas y no pasa por revisión.
Sirve para explorar; **no es el artefacto de entrenamiento**. La regla dura: *el modelo que sirve
producción se produjo con un pipeline ejecutado por CI/orquestador desde un commit*, y el notebook
—si existe— es un anexo desechable. Un notebook en la ruta crítica es un *bus factor* de uno.

### 3.2 Layout de referencia

```
proyecto/
  pipelines/          # definición del pipeline (dvc.yaml / flow.py / dag.py)
  src/
    features/         # transformaciones — IMPORTADAS por entrenamiento e inferencia (§3.5)
    training/
    inference/
  conf/               # hiperparámetros y config versionados
  tests/
    test_data_contract.py   # esquema, rangos, nulos, cardinalidad
    test_features.py        # invariantes de transformación
    test_model_contract.py  # forma de E/S, latencia, casos conocidos
  notebooks/          # exploración desechable, fuera de la ruta crítica
  model_card.md
```

### 3.3 Registro de modelos — la frontera hacia producción

El registro es **el único camino a producción**. Un artefacto no registrado no se despliega.
Metadatos mínimos, sin los cuales el registro rechaza la versión:

- **Linaje**: commit de código, versión/hash del dataset, config de hiperparámetros, imagen del
  entorno por digest, y el ID de la ejecución que lo produjo.
- **Métricas** de evaluación sobre un conjunto de prueba **congelado y versionado**, y sobre los
  **segmentos** relevantes (no solo el agregado: la media esconde el subgrupo donde falla).
- **Dueño** identificable (persona o equipo), no un buzón genérico.
- **Propósito y ámbito de uso**: para qué se entrenó y **para qué no debe usarse**.
- **Limitaciones conocidas**: poblaciones infrarrepresentadas, rango de validez de las entradas,
  supuestos que si dejan de cumplirse invalidan el modelo.
- **Model card** enlazada (§2). Sin ella, no se promueve.

**Promoción por etapas** (`dev` → `staging` → `production` → `archived`) con **aprobación humana
explícita y registrada** en el salto a producción. La aprobación la firma alguien que puede
explicar qué mide la métrica; no es un botón. Toda promoción y toda reversión quedan en un
registro inmutable: eso es la evidencia que pedirá auditoría y la que necesitarás a las 3 de la
mañana.

### 3.4 Pipeline de entrenamiento

Etapas explícitas y cacheables: `ingesta → validación → features → entrenamiento → evaluación →
registro`. Criterio, no catálogo:

- **La validación de datos es una etapa que falla el pipeline**, no un aviso. Contrato de esquema,
  rangos, nulos, cardinalidad y distribución esperada. *Garbage in* no se detecta después.
- **La evaluación decide el registro**: si el modelo nuevo no supera al de producción en el
  conjunto congelado **y en cada segmento vigilado**, no se registra. La comparación es contra el
  modelo en producción, no contra la ejecución anterior.
- **Idempotencia y reanudación**: una etapa que se re-ejecuta con las mismas entradas produce lo
  mismo o reutiliza caché. Un pipeline que hay que ejecutar entero por un fallo en la última
  etapa es un pipeline que nadie ejecuta.
- **Un pipeline no es un DAG bonito**: si el orquestador te obliga a escribir más código de
  pegamento del que tiene tu lógica, has elegido mal. Es señal de adoptar lo que ya operas.

### 3.5 Features y el *train/serve skew*

El fallo más caro y más silencioso del ML en producción: **la misma feature se calcula distinto en
entrenamiento y en inferencia**. Casos típicos: la media se calcula sobre todo el histórico en
entrenamiento y sobre la ventana móvil en producción; un `NULL` se imputa distinto; el
entrenamiento usa un valor que en el momento de la predicción todavía no existe (**fuga temporal**
— el modelo evalúa maravillosamente y en producción no sirve para nada).

**Orden de soluciones, de más barata a más cara**:

1. **Una sola implementación de la transformación**, importada por ambos caminos. Resuelve la
   mayoría de los casos y cuesta cero infraestructura.
2. **Registro de la feature calculada en el momento de la predicción** y comparación offline
   contra la recalculada en entrenamiento: detecta el *skew* aunque no lo evites.
3. **Feature store** (Feast): tiene sentido cuando hay **reuso real entre equipos**, o cuando
   necesitas *point-in-time correctness* sobre histórico (`get_historical_features`) porque
   evitar la fuga temporal a mano es inviable. Fuera de ese caso es dos almacenes más que operar
   y sincronizar. **La sincronía offline/online es ella misma una fuente de *skew***: no
   compraste una garantía, compraste un problema distinto.

### 3.6 Despliegue

| Modo | Cuándo | Trampa |
|---|---|---|
| **Batch** | La predicción se consume con horas o días de retraso (scoring nocturno, segmentación) | Es el modo por defecto y el más barato de operar. **Empieza aquí**: mucha gente monta *serving* en línea para un caso que se resolvía con un job nocturno |
| **En línea** | La predicción es parte de una petición de usuario | Añade SLO de latencia, autoescalado, y el coste de tener el modelo caliente 24×7 |
| **Streaming** | La decisión debe tomarse sobre el evento en vuelo | La complejidad de estado y de reproceso rara vez se paga fuera de fraude/tiempo real duro |

**Rollout**: *shadow* (el modelo nuevo recibe tráfico real y **no** responde al usuario; se
comparan predicciones) es la técnica de mayor rendimiento por unidad de riesgo — úsala antes de
cualquier canary. Después, canary por porcentaje con criterio de aborto **basado en métricas de
negocio o proxy**, no solo en errores HTTP.

**Rollback de un modelo — más difícil de lo que la gente cree.** Volver atrás exige tener
simultáneamente disponibles y compatibles: los **pesos anteriores**, el **preprocesado anterior**
(el que va con esos pesos, no el actual), el **contrato de features** que esperaba, y la
**configuración** con la que se sirvió. Reglas:

- El artefacto desplegable **empaqueta modelo + preprocesado + contrato** juntos, versionados como
  una unidad. Un modelo sin su preprocesado no es reversible.
- La versión N-1 se mantiene **desplegable y probada**, no solo almacenada. Un `rollback` que
  nadie ha ejercitado no existe (mismo criterio que un backup).
- Si el reentrenamiento cambió el esquema de features, el rollback **también revierte el pipeline
  de features**. Si eso no es posible, no era un rollback: era un despliegue nuevo hacia atrás.

## 4. Calidad y gates

Gates que **rompen el build o bloquean la promoción**, en orden de coste creciente:

1. **Formatter + linter + type checker** sobre el código de entrenamiento e inferencia. El código
   de ML es código de producción; ver `python-standards`.
2. **Tests unitarios de transformaciones de features**: invariantes, bordes (vacío, un solo
   registro, todo nulo, categoría no vista) y errores. Sin lógica en el test.
3. **Test de contrato de datos**: esquema, tipos, rangos, nulos, cardinalidad. Falla el pipeline.
4. **Test de determinismo**: mismo commit + mismo dataset + misma semilla → métricas dentro de la
   tolerancia declarada. Si esto falla, todo lo demás es ruido.
5. **Detección de fuga temporal**: comprobación explícita de que ninguna feature usa información
   posterior al instante de la predicción. Es la causa nº 1 de "funcionaba en el notebook".
6. **Gate de evaluación**: métricas agregadas **y por segmento** contra el modelo en producción,
   sobre conjunto congelado. Metodología en `llm-evaluation-standards` cuando aplique.
7. **Gate de *fairness***: métricas de disparidad por grupo dentro del umbral acordado (§6.5). El
   umbral lo fija gobierno (`ai-governance-standards`); el gate lo ejecuta el pipeline.
8. **Gate de completitud del registro**: metadatos de §3.3 presentes, model card enlazada, dueño
   asignado. Sin ellos el registro rechaza la versión — es el punto de control más barato que
   existe y el más olvidado.
9. **Prueba de *rollback*** en preproducción, con periodicidad: desplegar N-1 y verificar que
   sirve. Trimestral como mínimo.
10. **Test de carga / coste por predicción** antes de habilitar tráfico real (§6.4).

**Prohibido tratar "los tests pasan" como "el modelo sirve"**: la suite verde con un modelo que
predice la clase mayoritaria es el escenario normal, no el excepcional. La métrica de negocio es
la que decide.

## 5. Seguridad del stack

- **Deserialización insegura es la vulnerabilidad estructural del dominio.** `pickle`, `joblib`,
  `torch.load(weights_only=False)` y `cloudpickle` **ejecutan código al cargar**. La familia
  CVE-2024-37054/37055/37059 de MLflow (RCE por artefacto PyFunc/PyTorch/pmdarima malicioso,
  CWE-502) tiene PoC público reciente y sigue explotándose: **actualizar MLflow muy por encima de
  2.14.1** y **restringir el API de artefactos**. Un artefacto de modelo es **código**, no dato.
- **Servidor de tracking/registro nunca expuesto a internet ni sin autenticación.** Un MLflow
  abierto es RCE mediante artefacto y, además, fuga completa de datos de entrenamiento y métricas.
  Autenticación delegada al IdP (`identity-access-management-standards`), red segmentada.
- **Cadena de suministro de paquetes de ML — objetivo activo en 2026.** Precedentes verificados:
  compromiso de **LiteLLM en PyPI (mar-2026, versiones 1.82.7/1.82.8)** originado en un **Trivy
  comprometido usado en CI**, con ejecución vía ficheros `.pth` en `site-packages` **sin necesidad
  de importar el paquete**; **telnyx** (mar-2026); **`mistralai==2.4.6`** (may-2026); campaña
  **Hades** sobre `ensmallen` y paquetes de bioinformática en PyPI (jun-2026). Consecuencias
  operativas no negociables: **lockfile con hashes**, **pin exacto de toda herramienta invocada en
  CI** (incluidos los escáneres de seguridad), builds en entorno efímero y sin credenciales
  persistentes, y verificación de que un `pip install` no ejecuta nada por sí solo.
- **Datasets y pesos con control de acceso y linaje.** Quién puede leer el dataset de
  entrenamiento es una decisión de seguridad, no de comodidad; si contiene dato personal, manda
  `privacy-engineering-standards`.
- **Credenciales del pipeline**: identidad efímera (OIDC) hacia el almacén y el registro; nunca
  claves estáticas en el código del experimento ni en el notebook. Ver
  `secrets-management-standards`.
- **Registro de auditoría inmutable** de quién promovió qué modelo, cuándo y con qué métricas.
- El **modelo entrenado puede filtrar sus datos de entrenamiento** (memorización, inferencia de
  pertenencia): la evaluación de ese riesgo es de `privacy-engineering-standards`; el ataque
  adversario, de `mlsecops-standards`.

## 6. Rendimiento y operabilidad

### 6.1 Monitorización — la parte que casi nadie hace bien

Tres capas, y la mayoría de equipos solo tiene la primera:

1. **Servicio**: latencia, errores, saturación. Es lo que ya sabes hacer y **no dice nada del
   modelo**. `sre-practice-standards`.
2. **Dato de entrada**: distribución de cada feature, tasa de nulos, categorías no vistas,
   volumen. **Es la señal más temprana disponible y no necesita etiquetas.** Si no vigilas nada
   más, vigila esto.
3. **Calidad de la predicción**: distribución de la salida, y —cuando llegue— métrica real contra
   la etiqueta.

### 6.2 Deriva de datos frente a deriva de concepto

- **Deriva de datos (covariate shift)**: cambia la distribución de la entrada. Detectable **hoy y
  sin etiquetas** (tests de distribución, distancia entre poblaciones). **Detectarla no implica
  que el modelo haya empeorado**: la alarma por deriva estadística sin impacto medido es la
  primera fuente de fatiga de alertas del dominio — vigila las features que el modelo realmente
  usa, con umbrales calibrados sobre histórico, no `p < 0.05` sobre cien columnas.
- **Deriva de concepto**: cambia la **relación** entre entrada y salida. La entrada puede parecer
  idéntica y el modelo estar equivocándose. **Solo se detecta con etiquetas o con un proxy**, y es
  la que de verdad te hace daño.

### 6.3 El problema de la etiqueta que tarda (o no llega)

En muchos sistemas la verdad tarda semanas (impago, renovación, recaída) o **no llega nunca**
porque el modelo la impidió (no concediste el crédito: no sabes si habría pagado).

- Define **métricas proxy** explícitas y **documenta su sesgo**: tasa de aceptación, distribución
  de scores, tasa de intervención humana, tasa de anulación por el operador.
- **Reserva un porcentaje de tráfico sin modelo** (o con decisión aleatorizada) cuando sea ética y
  legalmente admisible: es la única forma de obtener etiquetas no censuradas y de medir de verdad
  si el modelo aporta. Es un coste deliberado, con dueño y presupuesto.
- **Bucles de retroalimentación**: si el modelo influye en los datos con los que se reentrenará,
  se realimenta a sí mismo y su sesgo se amplifica en cada ciclo (recomendadores, priorización de
  colas, detección de fraude). **Es un riesgo de diseño, no un detalle**: identifícalo por escrito
  en la model card, y mide contra una muestra no afectada por el modelo. Sin esa muestra, no
  tienes forma de distinguir "el modelo funciona" de "el modelo se está dando la razón".

### 6.4 Reentrenamiento y coste

**Disparadores** — elige uno explícito y escríbelo; un reentrenamiento sin criterio es una
lotería periódica:

| Disparador | Cuándo | Riesgo |
|---|---|---|
| **Por calendario** | El dato se renueva a ritmo conocido y estable | Reentrena cuando no hace falta (coste, riesgo de regresión) y no reentrena cuando sí |
| **Por umbral** | Hay métrica real o proxy fiable en producción | Requiere la señal que §6.3 dice que a menudo no tienes; umbral mal calibrado = oscilación |
| **Por evento** | Cambio conocido del negocio, del proveedor de datos o de la regulación | Depende de que alguien avise: exige acoplarlo a gestión del cambio |

**Reglas duras del reentrenamiento**: pasa por **los mismos gates** que el primer entrenamiento
(§4) — un modelo reentrenado no es una actualización menor, es un modelo nuevo; se despliega con
*shadow*/canary como cualquier otro; y **reentrenar no arregla la deriva de concepto si la causa
es que el problema cambió**: puede estar aprendiendo el mundo roto. Antes de reentrenar
automáticamente, pregunta si el fallo es de dato o de formulación.

**Coste**: el entrenamiento es un pico visible y presupuestado; **la inferencia es un goteo
continuo que a medio plazo domina la factura** y casi nadie la atribuye por modelo. Instrumenta
**coste por predicción** y **coste por punto de métrica ganado**: un modelo un 0,3 % mejor que
triplica el coste de inferencia es una mala decisión de ingeniería disfrazada de mejora. Batch
antes que en línea; modelo pequeño antes que grande; caché de predicciones repetidas antes que
más réplicas. Ver `gpu-computing-standards` para la utilización como métrica FinOps.

### 6.5 Fairness y sesgo como propiedad medible

**Aquí se mide; en `ai-governance-standards` se decide qué es aceptable y quién responde.**

- Las métricas de equidad son **mutuamente incompatibles**: paridad demográfica, igualdad de
  oportunidades y calibración por grupo no pueden satisfacerse a la vez salvo en casos
  degenerados. **Elegir cuál aplica es una decisión de producto y de gobierno, documentada**, no
  una opción por defecto de una librería.
- Se mide **por segmento y en el gate de evaluación** (§4.7), sobre datos representativos, y se
  vuelve a medir **en producción**: un modelo justo en el conjunto de prueba puede no serlo con
  la población real.
- El sesgo casi nunca está "en el modelo": está en el dato histórico, en la etiqueta (que suele
  registrar la decisión pasada, no la verdad) y en el bucle de §6.3. Auditar solo la salida es
  llegar tarde.
- **Los atributos protegidos que se necesitan para medir equidad suelen ser categoría especial de
  dato personal**: cómo obtenerlos y tratarlos legalmente es de `privacy-engineering-standards`.
  No los recojas por tu cuenta para "hacer un análisis".

### 6.6 Retirada del modelo

La fase que no está en ningún diagrama y que todo el mundo omite. Un modelo se retira cuando:
ya no supera al baseline, su dominio cambió, su dueño desapareció, o el coste supera el valor.
Procedimiento mínimo:

1. **Identificar consumidores reales** por telemetría, no por documentación. Casi siempre hay uno
   que nadie recordaba.
2. **Anunciar y fijar fecha**; ofrecer sustituto o degradación explícita (regla de negocio,
   baseline, decisión humana).
3. **Apagar sirviendo error explícito**, nunca devolviendo un valor por defecto silencioso: una
   predicción constante disfrazada de predicción es peor que un fallo.
4. **Conservar artefacto, model card, dataset y métricas** según la política de retención — puede
   hacer falta para auditar una decisión pasada mucho después de apagarlo.
5. Marcar `archived` en el registro y **retirarlo del inventario de sistemas de IA** con
   `ai-governance-standards`.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: revisar el toolchain cada **3 meses** — este ecosistema cambia de dueño y de
  licencia más rápido que casi ningún otro del catálogo. Evidencia reciente: **lakeFS adquirió
  DVC** (nov-2025), **Prefect adquirió Dagster** (anunciado 13-jul-2026), **Seldon Core v2 pasó a BSL 1.1**
  (ene-2024). Antes de adoptar cualquier herramienta: leer el `LICENSE` **del repo**, no la página
  de marketing, y comprobar la fecha de la última release.
- **Criterio de adopción**: una herramienta entra si resuelve un problema **medido**, tiene dueño
  claro y su coste operativo cabe en el equipo. Sale si lleva 6 meses sin releases, si cambia a
  licencia restrictiva o si nadie sabe operarla.
- **Deuda consciente**: si entrenas sin versionar el dataset o sin gate de fairness porque hoy no
  puedes, queda escrito con motivo y fecha en la model card. Deuda declarada es deuda gestionable.

**PROHIBIDO**
- ❌ Desplegar un modelo entrenado desde un notebook o desde un árbol de git sucio.
- ❌ Un modelo en producción que no se puede reconstruir (datos, código, config, entorno, semilla).
- ❌ Promover a producción sin pasar por el registro, sin dueño, sin model card y sin aprobación
  humana registrada.
- ❌ Desplegar sin plan de *rollback* **probado**, o sin la versión N-1 desplegable con **su**
  preprocesado.
- ❌ Servir un modelo sin monitorización de la distribución de entrada. Sin eso, operas a ciegas.
- ❌ Confundir alerta de deriva estadística con degradación del modelo, y despertar a alguien por
  un `p-valor`.
- ❌ Reentrenamiento automático que se despliega sin gates de evaluación ni canary.
- ❌ Calcular una feature dos veces, en dos sitios, con dos implementaciones distintas.
- ❌ Evaluar solo con la métrica agregada: la media esconde el segmento donde el modelo falla.
- ❌ Cargar artefactos `pickle`/`joblib` de origen no controlado; exponer MLflow sin autenticación.
- ❌ Usar herramientas de CI (incluidos escáneres) sin pin exacto de versión — precedente LiteLLM.
- ❌ Introducir feature store, Kubeflow completo u orquestador nuevo sin un problema medido que lo
  exija: en este dominio, la mayoría de la complejidad instalada no se ha ganado su sitio.
- ❌ Adoptar una herramienta sin leer su `LICENSE` y su última fecha de release.
- ❌ Presentar una mejora de métrica sin su coste de inferencia asociado.
- ❌ Recoger atributos protegidos "para medir sesgo" sin base legal (ver `privacy-engineering`).
- ❌ Apagar un modelo devolviendo un valor por defecto silencioso.
- ❌ Dar por bueno un modelo cuya única evidencia es una demo.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, licencia o recomendación de herramienta:

1. **Licencia real del repo** (`LICENSE` en `HEAD`), no la web de marketing. Comprobado ago-2026:
   Apache-2.0 en MLflow, DVC, lakeFS, Metaflow, Prefect, Dagster, Airflow, Feast, Evidently,
   BentoML, KServe; **Seldon Core v2 en BSL 1.1** (no open source); **W&B con SDK MIT y servidor
   propietario**. Re-verificar: los cambios de licencia en este sector son frecuentes.
2. **Última release y actividad** vía el feed Atom del repo (`/releases.atom`) o PyPI — la API
   REST de GitHub está limitada por tasa y su HTML induce a error de fecha. Observado ago-2026:
   MLflow 3.15.1, DVC 3.67.1 (mar-2026), lakeFS 1.85.0, Airflow 3.3.0, Metaflow 2.19.35, Prefect
   3.8.x, Dagster 1.13.16, Feast 0.65.0, Evidently 0.7.21 (mar-2026), KServe 0.19/0.20-rc,
   BentoML 1.4.39, Kubeflow 1.10.0, Seldon Core 1.19.0.
3. **Cambios de titularidad y consolidación**: lakeFS↔DVC, Prefect↔Dagster. Comprobar si hay
   nuevos movimientos y si alguno derivó en cambio de licencia o de mantenimiento.
4. **CVEs del stack**: MLflow (familia CWE-502), Kubeflow, KServe, BentoML, y el runtime de
   serialización que uses. Triaje y SLA en `vulnerability-management-standards`.
5. **Incidentes de cadena de suministro en PyPI/npm** que afecten a paquetes de ML o a
   herramientas invocadas en CI. Precedentes 2026: Trivy (mar), LiteLLM (mar), telnyx (mar),
   mistralai (may), campaña Hades/`ensmallen` (jun).
6. **Estándares de documentación de modelo/dataset**: si ha aparecido un formato con tracción real
   o una obligación normativa que fije el contenido de la documentación técnica.

**Huecos declarados (no rellenados de memoria):**
- **Gobernanza de MLflow**: no se localizó ningún cambio de gobernanza en 2026 más allá de su
  pertenencia a la Linux Foundation desde 2020; el proyecto sigue siendo *single-vendor* de facto
  (Databricks). **Si existe un cambio reciente, este documento no lo recoge — verifícalo en el
  fichero de gobernanza del repo y en el blog de LF AI & Data antes de decidir la adopción.**
- **Estado de mantenimiento de Evidently**: última release observada en el feed en mar-2026;
  no se ha confirmado si el ritmo es deliberado o señal de abandono.
- **WhyLabs**: estado del producto y modelo de licencia **no verificados**. No recomendado hasta
  comprobarlo.
- **Prefect↔Dagster**: no se ha localizado un plan público de convergencia de producto. Tratar la
  continuidad a largo plazo de cualquiera de los dos como incierta.
- **Feast**: gobernanza y patrocinio actuales no verificados en detalle.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
