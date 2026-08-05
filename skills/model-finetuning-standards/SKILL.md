---
name: model-finetuning-standards
description: Fine-tuning an existing model's weights as the last resort, after prompting and retrieval. Use when deciding between prompt engineering, RAG and training, running full fine-tuning versus PEFT with peft LoraConfig (r, lora_alpha, target_modules="all-linear", lora_dropout), QLoRA with bitsandbytes 4-bit, or DoRA and other LoRA variants, training with trl SFTTrainer, DPOTrainer, GRPOTrainer, KTOTrainer, RLOOTrainer or RewardTrainer, Unsloth or Axolotl configs, building a chat-formatted instruction dataset with chat templates and JSONL conversations, checking eval-set contamination and synthetic-data provenance, measuring catastrophic forgetting of general capability before and after, reading the weights licence of Llama, Gemma, Qwen, Mistral or DeepSeek checkpoints and whether it is OSI-approved, merging adapters with merge_and_unload versus serving adapters at runtime, or maintaining a family of fine-tuned variants.
---

# Estándares de ajuste fino (fine-tuning) de modelos

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **modificar los pesos de un modelo preentrenado ajeno**: la decisión de si hacerlo, el
método (completo frente a PEFT), los datos, la alineación de preferencias, la evaluación
obligatoria antes y después, la licencia de los pesos de partida y el despliegue de la variante
resultante.

Triggers: `peft`, `LoraConfig`, `get_peft_model`, `r=`/`lora_alpha`/`target_modules`,
`QLoRA`, `bitsandbytes` 4-bit, `trl`, `SFTTrainer`, `DPOTrainer`, `GRPOTrainer`, `KTOTrainer`,
`RLOOTrainer`, `RewardTrainer`, `unsloth`, `axolotl`, `adapter_model.safetensors`,
`adapter_config.json`, `merge_and_unload`, plantilla de chat / `chat_template`, `.jsonl` de
conversaciones, "afinar el modelo con nuestros documentos", "que aprenda nuestro producto",
"que responda en nuestro tono", "el modelo no sabe X", "entrenar con nuestros tickets".

**Tesis del dominio**: **el ajuste fino es la última opción, no la primera.** El orden de coste
creciente y de reversibilidad decreciente es:

1. **Prompt** (instrucciones, ejemplos, salida estructurada). Coste marginal, cambio en
   segundos, reversible. Resuelve formato, tono, criterio y tareas acotadas.
2. **Recuperación (RAG)**. Resuelve **conocimiento**: hechos propios, actualizables, citables y
   borrables. Es lo que la gente cree que resuelve el ajuste fino.
3. **Ajuste fino**. Resuelve **comportamiento**: formato rígido, estilo consistente, tarea
   estrecha repetitiva, reducción de longitud de prompt y de latencia/coste por petición.
4. **Entrenamiento propio** (`deep-learning-standards`). Otro orden de magnitud de coste.

**Qué arregla y qué no arregla el ajuste fino**:

| Sí arregla | No arregla |
|---|---|
| Formato de salida estable sin instrucciones largas | **Desconocimiento de hechos** — el error más común y más caro |
| Estilo, tono y registro consistentes | Conocimiento que cambia (precios, catálogo, políticas) |
| Tarea estrecha y repetitiva (clasificar, extraer, reescribir) | Trazabilidad y citación de la fuente |
| Consistencia entre ejecuciones y menos deriva de instrucción | Borrar un dato a petición del titular |
| Prompt más corto → menos tokens, menos latencia | Razonamiento general que el modelo base no tiene |
| Cumplir un esquema o una taxonomía propia | Que el modelo "no alucine" |

**Regla dura**: si la respuesta a "¿qué esperas que aprenda?" es un conjunto de hechos, la
solución es recuperación, no ajuste fino. Meter hechos en los pesos es caro, no verificable,
no actualizable y no borrable.

Corolario: **el ajuste fino no es entrenar.** Se parte de pesos ajenos, se mueven poco y el
resultado hereda las capacidades **y las restricciones legales** del modelo base (§5).

**No aplica**:

- `llm-app-engineering-standards` y `rag-standards` (**escritas — frontera crítica**):
  **construir producto sobre un LLM de terceros es suyo**, igual que **la recuperación** —
  ingesta, *chunking*, embeddings, índice, híbrido, *reranking*, citación. **Aquí, modificar los
  pesos.** El orden prompt → recuperación → ajuste fino cruza las tres skills: desde este lado
  se afirma solo el tercer peldaño y **la carga de la prueba de haber agotado los dos anteriores
  recae aquí**. Si el prompt o el índice resuelven el caso, esta skill declara que no hay
  proyecto.
- `mlops-standards` (**escrita — frontera crítica**): **el ciclo de vida del modelo en
  producción es suyo** — registro y versionado del artefacto, promoción, despliegue, *rollback*
  a los pesos anteriores, deriva, reentrenamiento y retirada. **Aquí, cómo se ajusta y se evalúa
  el modelo antes de llegar ahí.** Un adaptador entrenado por ti **es un artefacto de modelo
  propio** y entra en su registro con su tarjeta y su linaje.
- `llm-evaluation-standards` (**escrita**): **la medición de sistemas no deterministas es suya** —
  conjunto de evaluación, jueces LLM, significancia, gates en CI, contaminación de *benchmarks*.
  Aquí se **exige** la evaluación antes y después (§6) y se define **qué** medir (tarea objetivo
  **y** capacidades generales); el **cómo**, allí.
- `local-inference-standards` (**escrita**): **servir pesos propios es suyo** — vLLM, llama.cpp,
  batching, caché KV, adaptadores en caliente, cuantización de servicio. Aquí, la decisión
  **fusionar o servir adaptadores** y su coste de mantenimiento; el motor, allí.
- `deep-learning-standards` (**esta misma ola**): entrenar una red propia. **El ajuste fino no es
  entrenar**, pero hereda su mecánica: precisión mixta, acumulación de gradientes, *checkpoints*
  y semillas se rigen por allí.
- `classical-ml-standards` (**esta misma ola**): con miles de ejemplos etiquetados, **un
  clasificador clásico sobre embeddings suele ganar en coste, latencia y depurabilidad** a
  ajustar un modelo generativo. Es la línea base olvidada.
- `gpu-computing-standards` (**la GPU como recurso que se aprovisiona, comparte y paga**);
  `mlsecops-standards` (**procedencia de pesos, formatos seguros y ataques al modelo**, incluido
  el envenenamiento del corpus y las puertas traseras); `ai-governance-standards` (**riesgo, AI
  Act e inventario** — ojo: **ajustar y publicar puede convertirte en proveedor** a efectos
  regulatorios); `opensource-licensing-standards` (**la política de licencias**; aquí solo la
  restricción concreta de unos pesos); `privacy-engineering-standards` (dato personal y
  memorización); `data-engineering-standards`, `data-governance-quality-standards`;
  `finops-standards`, `green-it-standards`; `python-standards`; `computer-vision-standards`,
  `nlp-standards`, `multimodal-genai-standards` (**Ola 7**).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Versión verificada (ago-2026, PyPI) | Licencia |
|---|---|---|---|
| PEFT / adaptadores | `peft` | 0.20.0 (28-jul-2026) | Apache-2.0 (cabecera del repo) |
| Entrenadores SFT y preferencias | `trl` | 1.9.2 (28-jul-2026) | Apache-2.0 (metadatos PyPI) |
| Modelos y tokenizadores | `transformers` | 5.14.1 (16-jul-2026) | Apache-2.0 |
| Distribución / lanzamiento | `accelerate` | 1.14.0 (11-jun-2026) | Apache-2.0 |
| Cuantización de entrenamiento (QLoRA) | `bitsandbytes` | 0.50.0 (24-jul-2026) | MIT (metadatos PyPI) |
| Datos | `datasets` | 5.0.1 (28-jul-2026) | Apache-2.0 |
| Formato de pesos | `safetensors` | 0.8.0 (9-jun-2026) | verificar (§8) |

**Método**: **LoRA/QLoRA por defecto**; ajuste completo solo si LoRA con rango suficiente ya se
ha quedado corto **y está medido**. QLoRA (base cuantizada a 4 bits + adaptador) cuando la VRAM
manda; asume una penalización de calidad que hay que medir, no suponer.

**Variantes**: `peft` documenta hoy LoRA con variantes propias (**DoRA, BD-LoRA, KaSA,
MonteCLoRA, VeLoRA** en su índice de documentación) además de familias distintas (AdaLoRA, LoHa,
LoKr, OFT/BOFT, IA3, prompt/prefix tuning y otras). **Criterio: LoRA plano es el punto de
partida; una variante entra solo con una medición propia que la justifique**, no por ser nueva.

## 3. Hiperparámetros que de verdad importan

Cuatro decisiones concentran el resultado: **capas objetivo, rango, tasa de aprendizaje y tamaño
de lote efectivo**. Referencia citable: la guía *"LoRA Without Regret"* de la documentación de
TRL, que reproduce hallazgos de un artículo de Thinking Machines Lab (Schulman et al., 2025).
Verbatim de esa guía:

- *"The authors recommend applying LoRA to all weight matrices rather than limiting it to
  attention layers, as increasing the rank does not compensate for this restriction."* →
  `target_modules="all-linear"` como punto de partida, no solo `q_proj`/`v_proj`.
- *"For datasets that exceed LoRA capacity, LoRA underperforms FullFT"* → el rango debe cubrir
  la capacidad que pide el conjunto. La tabla de la guía recomienda rango **256** para SFT a
  "post-training scale" y **1-32** para RL.
- *"Counterintuitively, the blog post recommends using a higher learning rate than for full
  fine-tuning"*; en su tabla, 1.0e-5 para LoRA frente a 1.0e-6 para ajuste completo, y *"The
  1/r scaling in LoRA makes the optimal learning rate approximately rank-independent"*.
- *"In some scenarios, LoRA is less tolerant of large batch sizes than full fine-tuning."* → la
  guía recomienda lote efectivo < 32.

**Metodología y límite declarados**: resultados de un artículo de blog de laboratorio
reproducidos por HuggingFace sobre modelos y datasets concretos (SmolLM3-3B, Llama-3.2-1B/3.1-8B,
tulu-3-sft-mixture, OpenThoughts-114k, OpenR1-Math-220k); **no es literatura revisada por pares y
no se generaliza a tu modelo sin medirlo**. Su afirmación de cómputo ("~67% of the compute")
**no se adopta aquí como cifra**: no trae hardware ni condiciones (§8). `lora_alpha` es escala
relativa al rango: se fija con él y no se toca a ciegas.

## 4. Alineación de preferencias

Orden correcto: **SFT primero** (formato y tarea), **preferencias después** (elegir entre
respuestas válidas). Saltarse el SFT para ir directo a preferencias es el error de secuencia
habitual.

**Estado real verificado en la documentación de `trl` (índice de docs, ago-2026)**: los
entrenadores **estables** son **DPO, GRPO, KTO, Reward, RLOO y SFT**. En la sección
**experimental** conviven, entre otros, **PPO, ORPO, CPO, BCO, Online DPO, Nash-MD, GSPO-token,
SDPO, A2PO, GMPO, GOLD, GKD, PRM y destilación**.

Lectura de criterio: **DPO no está superado ni retirado — sigue siendo un entrenador de primera
clase**, y junto a él se han consolidado métodos de refuerzo con recompensa verificable (GRPO,
RLOO), la novedad real del último ciclo; la proliferación de siglas vive en experimental por
algo. **Criterio: DPO para preferencias por pares; GRPO/RLOO cuando hay recompensa verificable
(código que compila, test que pasa, resultado numérico correcto); lo demás, solo con medición
propia.**

**Cuándo compensa**: ya tienes SFT decente, existe una preferencia consistente que no sabes
escribir como instrucción y tienes cientos o miles de comparaciones fiables. Con menos, estás
metiendo ruido y arriesgando degradación.

## 5. Datos y licencias — la parte que decide el resultado

### 5.1 El conjunto de entrenamiento es el 90 % del resultado

- **Calidad sobre cantidad.** Cientos o pocos miles de ejemplos **excelentes y consistentes**
  baten a decenas de miles mediocres; un criterio contradictorio repetido enseña la contradicción.
- **Consistencia de formato**: los datos son la especificación y cualquier desviación se aprende.
- **Formato de conversación**: usa la **plantilla de chat del modelo base** (tokens especiales,
  roles, marcas de fin). El desajuste entre la plantilla de entrenamiento y la de inferencia es
  la causa número uno de "el modelo ajustado responde raro", y es *train/serve skew*.
- **Bordes y negativos**: incluye ejemplos donde lo correcto es rechazar, pedir aclaración o
  decir que no se sabe. Si no los pones, el modelo aprende a inventar.
- **Contaminación con el eval**: deduplica el corpus contra el conjunto de evaluación **antes**
  de entrenar, por coincidencia exacta y por similitud. Un eval contaminado no mide nada y no se
  descontamina a posteriori: hay que reentrenar.
- **Datos sintéticos**: útiles para volumen y bordes; heredan sesgo y errores del generador,
  colapsan la diversidad, y **generar con un modelo de terceros para entrenar el tuyo puede
  violar sus condiciones de uso** (revisa los términos del proveedor, no solo la licencia de los
  pesos). Etiqueta el origen sintético y revisa una muestra a mano.
- **PII**: licitud, minimización y retención antes de construir el corpus
  (`privacy-engineering-standards`). El modelo memoriza: **no hay `DELETE` en unos pesos**.

### 5.2 Licencias de pesos: no son licencias de software

**Trampa central del dominio**: la licencia de unos pesos **no** es una licencia de software y
"open source" aplicado a un modelo casi nunca significa lo que parece. Casos leídos en su texto:

| Pesos | Licencia | Restricción real (verbatim del texto) |
|---|---|---|
| Llama 3.3 (texto leído en crudo; **Llama 4 tiene acuerdo propio**, §8) | *Llama Community License Agreement* (no OSI) | Atribución obligatoria: *"prominently display "Built with Llama""*; renombrado forzoso: *"you shall also include "Llama" at the beginning of any such AI model name"* si entrenas otro modelo con sus materiales o salidas; **límite de usuarios**: *"is greater than 700 million monthly active users in the preceding calendar month, you must request a license from Meta"*; política de uso aceptable incorporada por referencia |
| Gemma | *Gemma Terms of Use* (no OSI) | *"You must not use any of the Gemma Services: for the restricted uses set forth in the Gemma Prohibited Use Policy"*; propagación obligatoria: *"You must provide all third party recipients of Gemma or Model Derivatives a copy of this Agreement"* e *"include the use restrictions referenced in Section 3.2 as an enforceable provision"*; *"Google reserves the right to restrict (remotely or otherwise) usage of any of the Gemma Services that Google reasonably believes are in violation of this Agreement."* |
| DeepSeek-V3 | *DeepSeek License Agreement v1.0* (no OSI) | Restricciones de uso en su Anexo A, entre ellas *"For military use in any way"* y *"For fully automated decision making that adversely impacts an individual's legal rights"*; propagación obligatoria a derivados; jurisdicción y ley de la RPC |
| DeepSeek-R1 | **MIT** (`LICENSE` del repo) | Permisiva de verdad — **misma familia de proveedor, licencia distinta**: se verifica por modelo, nunca por marca |
| Qwen3 (p. ej. Qwen3-8B) | **Apache-2.0** (`LICENSE` del repo) | Permisiva; conserva aviso y NOTICE |
| Mistral | **Varía por modelo** (p. ej. `license: apache-2.0` en la ficha de Mistral-Small-3.2-24B-Instruct-2506) | Otros modelos del mismo proveedor se publican bajo licencia de investigación: **verifica el modelo concreto** |

Reglas que se derivan:

- **Ninguna de las licencias de la columna "no OSI" es software libre ni código abierto**: las
  restricciones de campo de uso son incompatibles con la definición de código abierto por
  construcción. Llamarlas "open source" en documentación interna o comercial es un riesgo legal
  propio.
- **La licencia del repositorio de código no es la licencia de los pesos.** Ejemplo verificado:
  el repositorio `google-deepmind/gemma` publica su `LICENSE` bajo Apache-2.0, mientras la ficha
  del modelo declara `license: gemma` y remite a los *Gemma Terms of Use*. **Se lee el
  documento que acompaña a los pesos, no el del código.**
- **Las restricciones se heredan y se propagan**: tu variante ajustada queda sujeta a los
  términos del base y, en varios de estos casos, estás obligado a imponérselos a quien la reciba.
- **La licencia del corpus también restringe**: un dataset con cláusula no comercial o de solo
  investigación contamina el uso del modelo resultante. Se registra licencia de datos y de pesos
  en la tarjeta del modelo.
- La política general de licencias, el gate de CI y el SBOM/AIBOM son de
  `opensource-licensing-standards`.

## 6. Evaluación obligatoria, antes y después

- **Línea base de prompt obligatoria.** Sin la métrica del modelo base con el mejor prompt
  razonable —y, si aplica, con recuperación— no se sabe si el ajuste aportó algo. **Es la puerta
  de entrada al proyecto, no un informe posterior.**
- **Dos ejes de medición, siempre**: (1) **tarea objetivo**, con el eval propio no contaminado;
  (2) **capacidades generales — olvido catastrófico**: el ajuste estrecha el modelo, así que mide
  antes y después capacidades que **no** son la tarea (seguimiento de instrucciones,
  razonamiento, idioma, rechazos). Una mejora en la tarea que rompe el idioma o la seguridad no
  es una mejora.
- **Comportamiento de seguridad**: el ajuste puede degradar los rechazos del base aunque los
  datos no sean maliciosos; se mide antes de publicar (`mlsecops-standards` para *red teaming*).
- **Metodología**: `llm-evaluation-standards`. Aquí solo se fija **qué** se mide y **cuándo**
  bloquea: si la tarea no mejora significativamente sobre la línea base de prompt, o si las
  capacidades generales caen por encima de la tolerancia declarada, **el artefacto no se
  promueve**.
- Registro del experimento (datos, hiperparámetros, semilla, base exacta por revisión/digest) y
  promoción del artefacto: `mlops-standards`.

## 7. Despliegue, sostenibilidad y prohibiciones

- **Fusionar o servir adaptadores**: fusionar (`merge_and_unload`) da un artefacto único, simple
  de servir y cuantizar, perdiendo modularidad y multiplicando el almacenamiento por variante;
  servir adaptadores sobre una base compartida permite muchas variantes con una sola copia de los
  pesos, a cambio de complejidad y ataduras de compatibilidad en el motor. Regla: **una variante
  → fusiona; varias sobre la misma base → adaptadores.** El motor: `local-inference-standards`.
- **El coste real de una familia de variantes es el mantenimiento, no el entrenamiento**: cada
  una necesita eval, tarjeta, reentrenamiento cuando cambie la base y retirada. Antes de la
  segunda, pregunta si basta con enrutar por prompt.
- **Cuando sale una versión mejor del modelo base, el trabajo puede quedar obsoleto**: el ajuste
  fino es perecedero y atado a una base concreta. Planifica con esa caducidad y guarda **el
  dataset**, que es el activo que sobrevive.

**PROHIBIDO**:

- ❌ **Ajustar para añadir conocimiento factual**. Eso es recuperación (`rag-standards`).
- ❌ **Ajustar sin línea base de prompt** (y, cuando aplique, sin línea base de recuperación).
- ❌ **Entrenar sobre datos contaminados con el conjunto de evaluación**.
- ❌ **Publicar un modelo ajustado sin declarar la licencia del modelo base**, sus restricciones
  heredadas y la licencia del corpus.
- ❌ Llamar "open source" a unos pesos con restricciones de uso.
- ❌ Deducir la licencia de unos pesos de la del repositorio de código, de la marca del
  proveedor o de un resumen de terceros: se lee el texto que acompaña al modelo.
- ❌ Publicar sin medir **olvido catastrófico** de capacidades generales y comportamiento de
  seguridad.
- ❌ Entrenar con una plantilla de chat distinta de la que usarás en inferencia.
- ❌ Generar datos sintéticos con un proveedor cuyas condiciones prohíben entrenar modelos
  competidores, sin haber leído esas condiciones.
- ❌ Saltarse SFT y aplicar métodos de preferencia directamente sobre el modelo base.
- ❌ Mantener una familia de variantes sin eval automatizada por variante.
- ❌ Adoptar una variante de LoRA o un método de preferencia "nuevo" sin medición propia.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

- Últimas estables y *breaking changes* de `transformers`, `peft`, `trl`, `accelerate`,
  `datasets` y `bitsandbytes`: **`trl` mueve entrenadores entre estable y experimental entre
  versiones**, y `transformers` 5.x ya introdujo rupturas de API. Lee el índice de documentación
  del repo, no un tutorial.
- **Estado de DPO frente a métodos más recientes**: verifica en la documentación oficial de
  `trl` qué entrenadores están en `Trainers` (estables) y cuáles en `Experimental`. Lo escrito
  aquí procede del `_toctree.yml` del repositorio en ago-2026 y **caduca rápido**.
- **La licencia de CADA modelo de pesos que uses, leída en su texto completo**, incluidas las
  políticas de uso aceptable incorporadas por referencia y las condiciones del proveedor si usas
  su API para generar datos. **Huecos declarados**: (a) el texto de la *Llama Community License*
  citado aquí corresponde a **Llama 3.3** (fecha de versión 6-dic-2024) leído en crudo desde el
  repositorio `meta-llama/llama-models`; **Llama 4 tiene su propio acuerdo** (fecha efectiva
  5-abr-2025) que **no se ha leído íntegro en esta redacción** — no asumas que las cláusulas
  coinciden; (b) las cláusulas de los *Gemma Terms of Use* se obtuvieron por extracción de la
  página oficial, **no desde un fichero en crudo**: reléelas en `ai.google.dev/gemma/terms`
  antes de apoyar una decisión legal en ellas; (c) la licencia de `safetensors` no se verificó.
- **Aprobación OSI**: ninguna de las licencias de pesos con restricciones de uso citadas figura
  como aprobada por la OSI, y por construcción no puede serlo (las restricciones de campo de uso
  son incompatibles con la definición). Verifica la lista vigente y el estado de la *Open Source
  AI Definition* (OSAID) antes de usar la etiqueta "open source" en documentación.
- **Huecos declarados**: (a) ninguna cifra de calidad, ahorro de cómputo o memoria de LoRA/QLoRA
  frente a ajuste completo — las disponibles vienen de blogs de laboratorio o reproducciones
  sobre modelos concretos, sin condiciones homogéneas; (b) ningún tamaño mínimo de dataset — los
  rangos que circulan ("mil ejemplos bastan") no traen tarea, modelo ni métrica: el número sale
  de tu curva de evaluación al variar el tamaño.
- CVEs y estado de mantenimiento de `bitsandbytes` y de los *kernels* de cuantización, y
  procedencia/firma de los pesos base (`mlsecops-standards`).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
