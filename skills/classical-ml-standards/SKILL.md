---
name: classical-ml-standards
description: Classical (non-deep) machine learning on tabular data as an engineering discipline. Use when deciding whether a model is needed at all instead of a SQL query, a business rule or a heuristic, splitting data with train_test_split, StratifiedKFold, GroupKFold, TimeSeriesSplit or nested cross-validation, hunting data leakage from a scaler fit on the full dataset, a target-encoded column, an ID column or a future timestamp, building a scikit-learn Pipeline and ColumnTransformer so preprocessing is fit inside the fold, training gradient boosting with xgboost, lightgbm, catboost, HistGradientBoostingClassifier or a linear/logistic baseline with statsmodels, choosing metrics with accuracy_score, roc_auc_score, average_precision_score, precision_recall_curve, f1_score, confusion_matrix, calibrating probabilities with CalibratedClassifierCV, brier_score_loss or a reliability diagram, picking a decision threshold as a product decision, resampling with imbalanced-learn SMOTE and its calibration cost, interpreting with feature_importances_, permutation_importance, shap or partial dependence, or backtesting a time series with walk-forward validation.
---

# Estándares de machine learning clásico (tabular)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **construir y evaluar un modelo predictivo no profundo sobre datos estructurados**: si
hace falta un modelo, partición, fuga, validación, métricas y umbral, calibración, familia de
modelo, características, desbalanceo, interpretabilidad y series temporales.

Triggers: `sklearn`, `Pipeline`, `ColumnTransformer`, `train_test_split`, `StratifiedKFold`,
`GroupKFold`, `TimeSeriesSplit`, `cross_val_score`, `xgboost`, `lightgbm`, `catboost`,
`HistGradientBoostingClassifier`, `LogisticRegression`, `statsmodels`, `roc_auc_score`,
`average_precision_score`, `brier_score_loss`, `CalibratedClassifierCV`, `feature_importances_`,
`permutation_importance`, `shap`, `imblearn`/`SMOTE`, `joblib.dump`, "0,99 de accuracy", "clases
desbalanceadas", "¿qué umbral pongo?", "las probabilidades no cuadran", "leakage", "backtest",
"predecir la baja / el impago / el fraude / la demanda".

**Tesis del dominio — ordena el resto del documento**:

1. **La primera pregunta no es qué modelo, sino si hace falta un modelo.** Regla de negocio,
   heurística o consulta SQL resuelven buena parte de lo que llega etiquetado como "caso de ML",
   con coste operativo casi nulo y comportamiento auditable (§2.0).
2. **En tabular, el ML clásico sigue siendo el *default*** — por evidencia comparativa (§2.1) y
   por coste de inferencia, tiempo de entrenamiento y depurabilidad.
3. **La fuga de datos (*leakage*) es la causa número uno de modelos falsos**: métricas
   excelentes en validación y nulas en producción casi siempre significan que el modelo vio algo
   que no existirá en el instante de predecir.
4. **Un número sin línea base no significa nada.** AUC 0,84 puede ser excelente o peor que
   predecir siempre la clase mayoritaria; sin línea base no se sabe cuál.

**`classical-ml` no es "deep learning pequeño"**: es otra familia de modelos, con otros
supuestos, otros modos de fallo y otra economía.

**No aplica**:

- `mlops-standards` (**escrita — frontera crítica**): **el ciclo de vida del modelo en
  producción es suyo** — versionado de datos y experimentos, registro, *feature store*,
  despliegue, *train/serve skew*, deriva, reentrenamiento y retirada. **Aquí, cómo se entrena y
  se evalúa el modelo antes de llegar ahí.** Arbitraje: "¿es bueno y por qué debo creérmelo?" es
  de aquí; "¿cómo lo promuevo, lo vigilo y lo revierto?" es suya. El *fairness* y el umbral se
  calculan aquí; su monitorización en el tiempo es de allí.
- `deep-learning-standards` y `model-finetuning-standards` (**esta misma ola**): redes profundas
  propias y modificación de pesos preentrenados. La frontera es la familia de modelo, no el
  dominio del dato: **si vas a entrenar una red sobre tabular, la justificación frente a
  *gradient boosting* se exige aquí (§2.1) y la mecánica de entrenamiento vive allí.**
- `llm-app-engineering-standards`, `rag-standards`, `llm-evaluation-standards`,
  `ai-agents-standards` (**escritas**): todo lo que ocurre sobre un LLM de terceros. Frontera
  práctica: **una clasificación tabular con etiquetas históricas no es trabajo para un LLM**;
  un texto libre sin etiquetas no es trabajo para esta skill.
- `data-engineering-standards`, `data-governance-quality-standards`,
  `data-warehouse-modeling-standards`, `sql-standards` (**escritas**): la tubería, el contrato,
  la calidad, el grano y la consulta. Aquí se **exige** que el dato de entrenamiento tenga
  definición estable y marca temporal fiable; producirlo es suyo. **Si la solución era un
  `GROUP BY`, §2.0 manda y la implementación es suya.**
- `privacy-engineering-standards` (**dato personal en el conjunto de entrenamiento**: licitud,
  minimización, retención, DPIA y supresión sobre un modelo ya entrenado — aquí solo se exige
  hacerse la pregunta antes de entrenar) y `ai-governance-standards` (**clasificación de riesgo,
  AI Act e inventario**: un umbral que deniega crédito o filtra candidatos es decisión regulada —
  el número se calcula aquí, la aceptabilidad se decide allí).
- `analytics-bi-standards` (cuadro de mando, no predicción automatizada); `python-standards`,
  `r-standards`, `julia-standards` (lenguaje y entorno); `finops-standards`, `green-it-standards`
  (coste y huella); `mlsecops-standards` (envenenamiento, procedencia, ataques);
  `gpu-computing-standards` (la GPU como recurso); `computer-vision-standards`, `nlp-standards`,
  `multimodal-genai-standards` (**Ola 7**: aplicaciones por modalidad).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.0 ¿Hace falta un modelo? (puerta obligatoria)

| Situación | Solución correcta |
|---|---|
| La regla la sabe escribir un experto y cabe en 10 condiciones | **Regla de negocio**, versionada en código |
| El criterio es un agregado o un ranking sobre datos existentes | **Consulta SQL / vista** |
| Hay señal débil pero el volumen de decisiones es bajo y el coste del error alto | **Heurística + revisión humana** |
| No hay etiquetas, o son <1000 y ruidosas | **No hay modelo**: primero instrumentar y etiquetar |
| Relación multivariante, etiquetas abundantes, decisión repetitiva y tolerante a error | **Modelo** |

**Regla dura**: un modelo introduce reentrenamiento, monitorización, deriva y una superficie de
explicación ante el cliente; si una regla obtiene la mayor parte del beneficio, el modelo debe
justificar el resto contra ese coste permanente.

### 2.1 Tabular: clásico como default — la evidencia

- Grinsztajn, Oyallon y Varoquaux, *"Why do tree-based models still outperform deep learning on
  tabular data?"* (arXiv:2207.08815, v1 18-jul-2022). Metodología, verbatim: *"We define a
  standard set of 45 datasets from varied domains with clear characteristics of tabular data and
  a benchmarking methodology accounting for both fitting models and finding good
  hyperparameters"*; conclusión verbatim: *"tree-based models remain state-of-the-art on
  medium-sized data (~10K samples) even without accounting for their superior speed"*. **Límite
  declarado por los autores: tamaño medio (~10K).**
- Erickson et al., *TabArena: A Living Benchmark for Machine Learning on Tabular Data*
  (arXiv:2506.16791, v1 20-jun-2025, v4 3-nov-2025). Verbatim: *"While gradient-boosted trees are
  still strong contenders on practical tabular datasets, we observe that deep learning methods
  have caught up under larger time budgets with ensembling. At the same time, foundation models
  excel on smaller datasets."*; y su propia advertencia: *"some deep learning models are
  overrepresented in cross-model ensembles due to validation set overfitting"*.

**Lectura de criterio, no de titular**: el *gradient boosting* es el punto de partida correcto en
tabular, y quien pierde la comparación es la red **con el presupuesto de cómputo y ensamblado de
un proyecto real**, no el de un artículo. Los modelos fundacionales tabulares (línea TabPFN) son
un frente en movimiento y **sus cifras más fuertes proceden de informes de sus propios autores:
no se citan aquí como establecidas** — mide en tu conjunto contra un GBDT tuneado (§8).

### 2.2 Toolchain

| Pieza | Elección | Versión verificada (ago-2026) | Licencia (leída en el repo) |
|---|---|---|---|
| Base | scikit-learn | 1.9.0 (2-jun-2026, PyPI) | BSD-3-Clause |
| GBDT general | XGBoost | 3.4.0 (4-ago-2026, PyPI; requiere Python ≥3.12) | Apache-2.0 |
| GBDT rápido / gran volumen | LightGBM | 4.7.0 (18-jul-2026, PyPI) | MIT |
| GBDT con categóricas nativas | CatBoost | 1.2.10 (18-feb-2026, PyPI) | Apache-2.0 (© 2017-2026 YANDEX LLC) |
| Explicabilidad | SHAP | 0.52.0 (28-may-2026, PyPI) | MIT |
| Inferencia estadística / IC | statsmodels | verificar | verificar |

- **Las tres de boosting son permisivas y aptas para uso comercial.** LightGBM es MIT, sin la
  concesión de patentes que dan Apache-2.0 (XGBoost, CatBoost): si tu política exige *patent
  grant*, eso decide (`opensource-licensing-standards`).
- **Cambio de origen verificado**: LightGBM ya no se publica desde `microsoft/LightGBM`; PyPI
  4.7.0 apunta a `github.com/lightgbm-org/LightGBM`, cuyo `LICENSE` en crudo mantiene MIT con
  copyright de Microsoft **y** "The LightGBM developers". Actualiza URLs, SBOM y *pins*.
- **Sin GPU y con dataset mediano, `HistGradientBoostingClassifier` evita una dependencia
  entera.** Añadir XGBoost/LightGBM/CatBoost se justifica por rendimiento medido, categóricas
  nativas o entrenamiento distribuido, no por costumbre.

## 3. Flujo mínimo defendible

1. **Unidad de decisión e instante de predicción**: qué se predice, para quién, cuándo y con qué
   información **disponible en ese momento**. Sin esto no hay dataset correcto.
2. **Partir los datos ANTES de mirar nada**: exploración, estadísticos, selección de variables e
   imputación se deciden sobre entrenamiento; la prueba se separa primero y no se toca (§7).
3. **Línea base tonta** (clase mayoritaria, media, "lo mismo que ayer", la regla en producción) y
   **línea base honesta** (regresión regularizada o árbol único, dentro del `Pipeline`).
4. **Modelo candidato**: *gradient boosting*, con validación adecuada al dato (§4.2).
5. **Calibración y umbral** (§4.3, §4.4) y **evaluación única en prueba**, con la base al lado.

Todo el preprocesado vive **dentro** del `Pipeline`/`ColumnTransformer` que se ajusta en cada
pliegue: un `fit_transform` sobre el dataset completo antes de partir es fuga, aunque "solo" sea
un `StandardScaler`.

## 4. Validación, métricas y umbral

### 4.1 Fuga de datos — los tres casos que producen casi todos los modelos falsos

- **Fuga temporal**: característica que en producción aún no existirá, o calculada con
  información posterior al instante de predicción (agregados sobre "todo el histórico", columnas
  actualizadas *in place*, tablas sin versionado). Síntoma: métricas irreales y una variable
  dominante que "tiene sentido" a posteriori.
- **Fuga por preprocesado ajustado sobre todo el conjunto**: escalar, imputar con la media
  global, seleccionar variables o codificar el *target* usando también validación. **El *target
  encoding* es el caso más traicionero: exige codificación fuera de pliegue.**
- **Fuga por identificador**: un `id`, hash, código de expediente o correlativo que codifica el
  orden o la clase; se delata como variable sin sentido causal arriba en importancia.
- **Detección**: si el modelo bate la línea base por un margen que sorprende, la hipótesis por
  defecto es fuga, no talento. Reprodúcelo con un corte temporal real antes de celebrarlo.

### 4.2 Validación

| Estructura del dato | Partición correcta | Prohibido |
|---|---|---|
| i.i.d., clases equilibradas | K-fold | — |
| i.i.d., clases desbalanceadas | K-fold estratificado | — |
| Varias filas por entidad (cliente, paciente, dispositivo) | `GroupKFold` / `StratifiedGroupKFold` por entidad | Partición aleatoria: la misma entidad en train y test |
| Temporal | Validación hacia delante (*walk-forward*), corte por fecha, `TimeSeriesSplit` | Partición aleatoria: entrenar con el futuro |
| Selección de hiperparámetros + estimación de error | Validación cruzada anidada | Reportar el mejor CV como estimación insesgada |

**La partición aleatoria es incorrecta en datos temporales o agrupados**, y produce
exactamente el mismo síntoma que la fuga: un número que no se reproduce en producción.

### 4.3 Métricas con criterio

- **La exactitud (*accuracy*) es inútil con clases desbalanceadas**: al 1 % de positivos,
  predecir siempre "negativo" da 99 %. No se reporta sola nunca.
- **Precisión / recall / F1**: se eligen por el coste asimétrico del error. F1 no tiene
  significado de negocio propio: sirve para comparar, no para justificar.
- **ROC frente a precisión-recall**: con positivos escasos la ROC es optimista (la tasa de falsos
  positivos se diluye en un denominador enorme). **Con desbalance fuerte manda la curva de
  precisión-recall y su *average precision***, con la prevalencia escrita al lado como base.
- **Calibración: lo que casi nadie mide y lo que el negocio necesita.** Si el modelo dice 0,7,
  ¿ocurre el 70 % de las veces? Se mide con *Brier score* y diagrama de fiabilidad y se corrige
  con calibración (Platt/isotónica) ajustada en un conjunto separado. Buena discriminación con
  mala calibración es inservible para toda decisión que multiplique probabilidad por importe.
- **Regresión**: MAE/RMSE según si penalizas el error grande; MAPE se rompe con ceros y valores
  pequeños. Reportar en unidades de negocio junto a la línea base.

### 4.4 El umbral es una decisión de producto

El modelo produce una probabilidad; **el umbral la convierte en acción y pertenece a quien asume
el coste del error**, no a quien entrena. Se fija con la matriz de coste (falso positivo ×
volumen frente a falso negativo × volumen) o con una restricción operativa (casos revisables al
día), se elige sobre validación, se declara y se versiona junto al modelo. **Elegirlo mirando el
conjunto de prueba invalida la estimación de error** (§7).

### 4.5 Gates de CI, en orden de coste

1. Test que falla si hay `fit`/`fit_transform` fuera del `Pipeline` o previo a la partición.
2. Esquema del dataset: columnas, tipos, rangos, nulos esperados.
3. No-fuga: columnas prohibidas excluidas; alerta si una variable supera un umbral absurdo de
   importancia.
4. Métrica en validación **frente a la línea base**, con umbral que rompe el build.
5. Semilla fijada y misma métrica en dos ejecuciones.

## 5. Datos, características y desbalanceo

- **Ingeniería de características y fuga son el mismo problema visto dos veces.** Cada
  característica exige responder: ¿existe este valor en el instante de predicción, con esa
  latencia y calculado solo con el pasado? Foco en los agregados temporales: ventana cerrada
  anterior al corte.
- **Categóricas de alta cardinalidad**: nativas de CatBoost/LightGBM o *target encoding* fuera de
  pliegue. `OneHotEncoder` sobre miles de niveles es un error de coste.
- **Desbalanceo**: pregunta primero si es un problema real o solo prevalencia baja. Con GBDT,
  `scale_pos_weight`/pesos de clase y una métrica adecuada (§4.3) suelen bastar.
- **El remuestreo sintético empeora la calibración.** van den Goorbergh, van Smeden, Timmerman y
  Van Calster, JAMIA 29(9):1525-1534 (2022), doi:10.1093/jamia/ocac093. Metodología: regresión
  logística estándar y *ridge* bajo cuatro tratamientos (sin corrección, *undersampling*,
  *oversampling* y SMOTE), evaluados en discriminación, calibración y clasificación, con
  simulación Monte Carlo variando tamaño, número de predictores y fracción de eventos.
  Resultado: las correcciones **dañan la calibración sobreestimando la clase minoritaria, sin
  beneficio en discriminación**. **Discrepancia declarada**: el seguimiento a algoritmos de ML
  (Carriero et al., *Statistics in Medicine*, 2025) **no lo generaliza a todo algoritmo** (§8).
  Criterio: **SMOTE no es el paso por defecto; si lo usas, mide calibración antes y después.**
- **PII en el conjunto de entrenamiento**: licitud, minimización y retención se deciden en
  `privacy-engineering-standards` **antes** de construir el dataset.

## 6. Interpretabilidad y series temporales

- **Explicar el modelo ≠ explicar la decisión.** La importancia global describe el modelo; la
  persona a la que deniegas algo pregunta por *su* caso. Dos entregables distintos, y el segundo
  suele ser el legalmente obligatorio.
- **Trampas de la importancia**: la de *split*/ganancia favorece la alta cardinalidad y se
  reparte arbitrariamente entre variables correlacionadas; la de permutación es preferible, se
  degrada con correlación fuerte y **debe calcularse sobre datos no vistos**.
- **SHAP y sus límites**: atribución local aditiva, con supuestos de independencia en sus
  aproximaciones habituales y coste de cómputo real. **No es medida causal** ni dice qué pasaría
  si cambias la variable: sirve para depurar y explicar un caso, no para argumentar intervención.
- **Cuando la interpretabilidad manda, un modelo lineal es preferible**: coeficientes con
  intervalos y comportamiento estable. En dominios regulados, la diferencia de AUC frente a un
  GBDT rara vez compensa perder la defendibilidad.
- **Series temporales**: validación hacia delante con reentrenamiento en cada corte; retardos y
  ventanas móviles calculados solo con el pasado; estacionalidad y calendario como variables
  explícitas; horizonte declarado. Línea base obligatoria: *naïve* y estacional *naïve*.

## 7. Sostenibilidad y prohibiciones

- Revisar versiones mayores de scikit-learn y del boosting cada trimestre. Un modelo serializado
  con `pickle`/`joblib` **no es portable entre versiones**: fija la versión junto al artefacto y
  prueba la carga en CI. Reentrenamiento, deriva y retirada: `mlops-standards`.

**PROHIBIDO**:

- ❌ **Evaluar sobre los datos de entrenamiento** y presentar esa métrica como resultado.
- ❌ **Elegir el umbral mirando el conjunto de prueba** (o cualquier hiperparámetro).
- ❌ **Presentar métricas sin línea base** ni sin la prevalencia de la clase positiva.
- ❌ **Usar la importancia de características como causalidad** ("la variable X causa la baja").
- ❌ Ajustar cualquier transformación sobre el conjunto completo antes de partir.
- ❌ Partición aleatoria con datos temporales o con varias filas por entidad.
- ❌ Reportar *accuracy* como métrica principal con desbalanceo, o AUC-ROC como única métrica con
  prevalencia baja.
- ❌ Entregar probabilidades sin medir calibración cuando alimentan una decisión económica.
- ❌ Tocar el conjunto de prueba más de una vez, o "probar otra idea" sobre él.
- ❌ Entrenar un modelo cuando una regla, una consulta o una heurística resolvían el caso.
- ❌ Cifras de *benchmark* sin condiciones de medida: dataset, partición, presupuesto de tuneado
  y línea base.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

- Última estable y soporte de Python de **scikit-learn, XGBoost, LightGBM, CatBoost, SHAP y
  statsmodels**; XGBoost 3.4.0 ya exige Python ≥3.12. Cambios de API que rompen antes de subir
  versión mayor.
- **Origen y licencia de cada biblioteca leídos en el `LICENSE` en crudo del repo**, no en un
  resumen. LightGBM cambió de organización (`microsoft/` → `lightgbm-org/`).
- **Estado de la literatura tabular clásico-vs-profundo**: marcador de `tabarena.ai` y
  publicaciones posteriores a nov-2025. Los modelos fundacionales tabulares se mueven rápido y
  **sus cifras más favorables proceden de sus propios autores**: exige metodología, presupuesto
  de cómputo y evaluación independiente antes de citarlas.
- **Huecos declarados**: (a) ninguna cifra de rendimiento comparado (AUC, Elo, posiciones de
  *leaderboard*) se fija aquí — las disponibles carecen de condiciones de medida homogéneas y de
  evaluación independiente; (b) versión y licencia de `statsmodels` e `imbalanced-learn` no
  verificadas en esta redacción.
- **Discrepancia declarada**: van den Goorbergh et al. (2022) concluye contra las correcciones de
  desbalanceo en regresión logística; el seguimiento de Carriero et al. (2025) no lo generaliza a
  todo algoritmo de ML. Comprueba el estado actual y mide calibración en tu caso.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
