---
name: nlp-standards
description: Natural language processing as a discipline, deciding between a regex, a small specialised model and an LLM. Use when building text classification, named entity recognition, sentiment analysis, summarisation, semantic similarity, clustering or translation, working with spaCy (en_core_web_sm, es_core_news_sm, nlp.pipe, Doc, Span, EntityRuler), NLTK, Stanza, Flair, gensim, scikit-learn TfidfVectorizer, setfit or a fine-tuned encoder, choosing an embedding model (sentence-transformers, BAAI/bge, intfloat/e5, nomic-embed, Alibaba gte, Qwen3-Embedding, jina-embeddings) and reading its weights licence, planning a re-index after changing embedding model, evaluating with MTEB, tokenising with tiktoken, sentencepiece or huggingface tokenizers and explaining why token count is not word count, normalising Unicode with NFC/NFKC, detecting language with fastText lid, lingua or langdetect, handling accents, casing, emoji and zero-width characters, measuring macro-F1 and per-class recall on an imbalanced label set, auditing an annotated text corpus and inter-annotator agreement, or checking that a model that works in English also works in Spanish.
---

# Estándares de procesamiento de lenguaje natural (PLN)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **PLN como disciplina**: decidir con qué se resuelve una tarea de texto, preparar el
texto, elegir y evaluar modelos pequeños y modelos de incrustación, construir corpus etiquetados y
medir honestamente — incluida la **medición por idioma**.

Triggers: `spacy`, `nlp(...)`, `nlp.pipe`, `en_core_web_sm`, `es_core_news_sm`, `EntityRuler`,
`nltk`, `stanza`, `flair`, `gensim`, `TfidfVectorizer`, `CountVectorizer`, `setfit`,
`sentence-transformers`, `SentenceTransformer(...)`, `model.encode(...)`, `bge-`/`e5-`/`gte-`/
`nomic-embed`/`jina-embeddings`, `mteb`, `tiktoken`, `sentencepiece`, `AutoTokenizer`,
`unicodedata.normalize`, `NFC`/`NFKC`, `casefold()`, `langdetect`, `lingua`, `lid.176`,
`macro-F1`, `classification_report`, "clasificar tickets", "extraer entidades", "detectar
sentimiento", "resumir documentos", "buscar textos parecidos", "agrupar comentarios", "traducir",
"en inglés funciona y en español no", "cuántos tokens ocupa esto".

**Tesis del dominio**: **muchas tareas que antes exigían un modelo de PLN entrenado hoy las resuelve
un LLM con un prompt, y otras muchas no deberían usar un LLM en absoluto.** El criterio es de tres
vías y se decide **en este orden**:

1. **Regla o expresión regular** — cuando el patrón es formal y cerrado: NIF, IBAN, matrícula,
   código de producto, fecha, URL, número de factura. **Es exacta, auditable, gratis, instantánea y
   determinista.** Ninguna de esas cuatro propiedades la tiene un modelo.
2. **Modelo pequeño especializado** — cuando hay volumen alto, etiquetas propias estables, o
   restricciones de coste, latencia, determinismo o soberanía del dato. Clasificador sobre
   incrustaciones, encoder ajustado, `setfit` con pocos ejemplos, o un pipeline de spaCy.
3. **LLM** — cuando la tarea es abierta, la salida es texto libre, las clases cambian a menudo, no
   hay datos etiquetados y el volumen es bajo o el valor por documento es alto.

**El error caro va en las dos direcciones**: meter un LLM donde bastaba un `re.match` añade coste,
latencia y no determinismo permanentes; y montar un proyecto de etiquetado de seis meses para una
tarea que un prompt resolvía en una tarde es tirar el presupuesto. **Prototipa con un LLM para
descubrir si la tarea es viable y para generar el conjunto etiquetado inicial; decide después si se
queda o se destila a un modelo pequeño** (§3.2).

**No aplica**:

- `llm-app-engineering-standards`, `rag-standards` y `llm-evaluation-standards` (**escritas —
  frontera crítica**): **el producto sobre un LLM de terceros es de la primera** (prompt como
  artefacto, salida estructurada, ventana de contexto, reintentos, inyección de prompt), **la
  recuperación es de la segunda** (ingesta, *chunking*, índice, híbrido, *reranking*, citación) y
  **medir lo generativo y no determinista es de la tercera** (jueces LLM, casos dorados,
  significancia). Aquí queda el PLN como disciplina: **la decisión de tres vías**, el texto real, los
  modelos pequeños, las incrustaciones **como artefacto** y las métricas deterministas. Regla de
  arbitraje: si la salida es una etiqueta, un vector o un tramo del texto, es de aquí; si es prosa
  generada, es de ellas.
- `deep-learning-standards`, `model-finetuning-standards` y `classical-ml-standards` (**escritas**):
  **entrenar una red propia y su bucle son de la primera**, **mover los pesos de un modelo ajeno de
  la segunda** y **el dato tabular de la tercera**, que además es dueña de la mecánica común —fuga,
  partición, calibración, umbral de decisión, línea base— que **no se duplica aquí**. Un texto
  vectorizado que entra en un `LogisticRegression` es un problema tabular con un preprocesado
  peculiar, y su validación se hace con las reglas de allí.
- `mlops-standards`, `local-inference-standards`, `gpu-computing-standards`, `mlsecops-standards` y
  `ai-governance-standards` (**escritas**): **el ciclo de vida en producción es de la primera**
  —registro, promoción, deriva, reentrenamiento—, **servir pesos propios de la segunda**, **la GPU
  como recurso de la tercera**, **la procedencia de los pesos y los ataques al modelo de la
  cuarta**, y **la clasificación de riesgo, el AI Act y el inventario de la quinta**.
- Comunes: `vector-db-standards` (**el almacén del vector, sus índices y su operación**),
  `i18n-standards` (**cotejo, formatos locales, plurales, dirección del texto y el detalle
  Unicode**; aquí solo lo que rompe un modelo), `search-engines-standards` (búsqueda léxica),
  `privacy-engineering-standards` (**el texto libre es el peor sitio para los datos personales**),
  `opensource-licensing-standards` (política de licencias, incluidas las de modelo y corpus),
  `data-engineering-standards` y `data-governance-quality-standards`, `python-standards`,
  `finops-standards` y `green-it-standards` (coste y huella de la inferencia),
  `grc-compliance-standards`.
- Skills hermanas de modalidad: `computer-vision-standards` (imagen y vídeo) y
  `multimodal-genai-standards` (generación de imagen, audio y vídeo). **Son tres modalidades, no
  tres niveles**: ninguna es prerrequisito de otra.

## 2. Decisiones por defecto

> Verificar la última versión y **la licencia de los pesos, modelo a modelo y idioma a idioma**,
> por web antes de fijarla en un proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Patrón formal y cerrado | **Expresión regular con test de casos** | Nada. Es la respuesta |
| Línea base de clasificación | **TF-IDF + regresión logística** (`scikit-learn`) | Sirve para saber si el problema es fácil; si gana, ya has terminado |
| Clasificación con pocos ejemplos | **Incrustaciones + clasificador lineal**, o `setfit` | LLM con prompt si las clases cambian cada semana |
| Extracción de entidades genéricas | **spaCy** (MIT), con el modelo del idioma correcto | Stanza (Apache-2.0) si prima la exactitud sobre la velocidad |
| Extracción de entidades propias | Reglas (`EntityRuler`) primero, modelo después | LLM con esquema si el dominio es abierto y el volumen bajo |
| Similitud y agrupación | **Incrustaciones** de un modelo permisivo | TF-IDF si el vocabulario es cerrado y técnico |
| Resumen y traducción | **LLM** (`llm-app-engineering-standards`) | Modelo dedicado solo si hay volumen masivo o el dato no puede salir |
| Incrustaciones autoalojadas | **`bge-m3` (MIT), `multilingual-e5-large` (MIT), `gte-multilingual-base` (Apache-2.0), `Qwen3-Embedding` (Apache-2.0), `nomic-embed-text-v2-moe` (Apache-2.0)** — licencias verificadas | API gestionada si no hay restricción de salida del dato |
| Detección de idioma | **`lingua`** (Apache-2.0 verificado) | `fastText` LID **solo tras verificar su licencia**: la ficha del modelo en Hugging Face declara **CC-BY-NC-4.0** (§5) |
| Normalización | **NFC** para almacenar; NFKC solo para comparar | Nunca NFKD "por defecto" sin saber qué colapsa |
| Vectores y su almacén | Ver `vector-db-standards` | — |

## 3. Tareas clásicas y respuesta correcta hoy

### 3.1 Qué usar para cada tarea

| Tarea | Respuesta por defecto hoy | Cuándo NO es esa |
|---|---|---|
| **Clasificación de texto** | Etiquetas estables + volumen → **modelo pequeño**; etiquetas cambiantes o sin datos → LLM | Si las clases son dos y separables por palabras clave, es una regla |
| **Extracción de entidades** | Entidades genéricas (persona, lugar, fecha, dinero) → **spaCy/Stanza**; entidades propias de dominio → reglas + modelo ajustado | Formato fijo (facturas, códigos) → **expresión regular**, no modelo |
| **Análisis de sentimiento** | **LLM** para texto abierto; modelo pequeño si es alto volumen | Lo que casi siempre se quiere de verdad es **clasificar el motivo de la queja**, no la polaridad. Pregunta qué decisión cambia el resultado antes de construir nada |
| **Resumen** | **LLM**, sin discusión | Si se necesita extractivo y verificable, seleccionar frases del original es más defendible |
| **Similitud semántica** | **Incrustaciones** + coseno | Duplicados exactos o casi: *hashing* y distancia de edición, sin modelo |
| **Agrupación (clustering)** | Incrustaciones + clustering, y **un humano nombrando los grupos** | Sin nombres, un clustering no es un resultado: es una figura |
| **Traducción** | **LLM** o servicio dedicado | Dominio muy técnico con glosario propio: exige glosario forzado y revisión humana |

### 3.2 Cuándo un modelo pequeño gana al LLM

Cinco razones, y basta una para justificarlo:

- **Coste por millón de documentos.** Un LLM de API cobra por token de entrada y de salida en
  **cada** documento; un encoder o un clasificador lineal se paga una vez en cómputo propio. **Haz
  la cuenta con tu volumen, tu longitud media de documento y el precio vigente** —no con una
  intuición ni con una cifra recordada— y compárala con el coste de entrenar y mantener el pequeño.
  A partir de cierto volumen la diferencia es de órdenes de magnitud, y ese punto de cruce se
  calcula, no se estima.
- **Latencia.** Un clasificador sobre incrustaciones responde en milisegundos y **por lotes**; un
  LLM no. Si va en la ruta síncrona de una petición de usuario, esto suele decidir solo.
- **Ejecución local.** CPU, borde o red aislada: el modelo pequeño cabe donde el LLM no.
- **Determinismo.** Misma entrada, misma salida, siempre. Auditable, testeable con igualdad exacta
  y explicable ante quien pregunte. Un LLM no ofrece nada de eso.
- **Datos que no pueden salir.** Historia clínica, expediente judicial, dato de menores, secreto
  industrial. Si la respuesta a "¿podemos enviar esto a un tercero?" es no, el debate ha terminado.

**Patrón recomendado**: usa el LLM para **etiquetar** un corpus inicial (con revisión humana de una
muestra, §4.3), entrena el modelo pequeño con él y **compara los dos en el mismo conjunto de
prueba**. Si el pequeño se acerca lo suficiente, se queda el pequeño. **La destilación es una
decisión de coste, no de calidad**: documenta la pérdida que aceptas.

## 4. Texto real, corpus y etiquetado

### 4.1 Normalización

- **Normalización Unicode explícita en la ingesta**: dos textos visualmente idénticos con distinta
  forma de composición (`é` precompuesta vs. `e` + acento combinante) son cadenas distintas, no
  coinciden en un índice y producen duplicados fantasma. **NFC para almacenar; NFKC solo cuando la
  comparación deba ignorar variantes de compatibilidad**, sabiendo que NFKC colapsa ligaduras,
  superíndices, anchos y símbolos y **puede cambiar el significado**.
- **Limpieza mínima obligatoria**: caracteres de ancho cero y controles bidireccionales (vector real
  de suplantación y de inyección, ver `mlsecops-standards`), espacios no separables, comillas
  tipográficas, guiones diversos y saltos de línea heterogéneos.
- **`lower()` no es `casefold()`** y ninguno es seguro por defecto: en turco la `I` no se comporta
  como en español, y bajar a minúsculas destruye señal en siglas y nombres propios. Decide si
  minusculizar **por tarea**, no por costumbre.
- **Emoji y puntuación son señal**, no ruido, en texto de usuario. Borrarlos "para limpiar" es
  perder información.
- **Detección de idioma antes de procesar**: cada texto lleva su idioma detectado como metadato.
  Los detectores fallan en textos cortos y en mezclas; para cadenas de pocas palabras, **la
  confianza importa más que la etiqueta** y hay que tener una rama de "desconocido".

### 4.2 Tokenización y recuento

**El recuento de tokens no es el de palabras ni el de caracteres**, y depende del tokenizador
concreto del modelo concreto. Consecuencias prácticas:

- **Para estimar coste o contexto, cuenta con el tokenizador del modelo que vas a usar**, no con
  `len(texto.split())` ni con una regla de tres. Cambiar de modelo cambia el recuento.
- **El texto no inglés consume más tokens** que el mismo contenido en inglés con la mayoría de
  tokenizadores, y las lenguas con escritura no latina, más aún. Eso es **más coste y menos
  contenido efectivo por ventana** para el mismo documento — mídelo en tus idiomas antes de
  presupuestar.
- **El truncado por tokens parte palabras y caracteres multibyte**: trunca por unidades del
  tokenizador, no por caracteres, y nunca por bytes.
- El detalle de cotejo, mayúsculas por locale, plurales y dirección del texto vive en
  `i18n-standards`; aquí solo lo que rompe un modelo.

### 4.3 Corpus etiquetado — el mismo rigor que en visión

- **Guía de etiquetado escrita antes de la primera etiqueta**, con casos límite y ejemplos.
- **Acuerdo entre anotadores medido** sobre un subconjunto solapado, con un estadístico que corrija
  el azar. **Si dos personas no coinciden, el modelo no puede aprenderlo y la evaluación no
  significa nada**: el acuerdo es el techo de la métrica.
- **Taxonomía cerrada y disjunta**, o multietiqueta declarada. La mitad de los proyectos de
  clasificación fracasan porque las clases se solapan y nadie lo dijo.
- **Etiquetas generadas por un LLM se auditan con muestra humana** y se marcan como sintéticas en el
  linaje. Un conjunto de prueba **nunca** se etiqueta solo con LLM: se convierte en medir el
  parecido con ese LLM.
- **Partición por grupo**: mensajes del mismo hilo, del mismo cliente o del mismo autor van enteros
  al mismo lado. Y si el dato tiene tiempo, **partición temporal**.
- **Versiona el corpus y la guía** (`data-governance-quality-standards`). Un corpus sin versión no
  es evaluable ni reproducible.

## 5. Licencias, datos personales y sesgo

**La licencia del código no es la del modelo, y en PLN cambia incluso entre idiomas del mismo
paquete.** Verificado leyendo los metadatos en crudo (ago-2026):

- **spaCy** es MIT, pero **sus modelos no comparten licencia**: `en_core_web_sm` y `en_core_web_trf`
  son **MIT**, `de_core_news_sm` y `xx_ent_wiki_sm` **MIT**, pero **`es_core_news_sm/md`,
  `es_dep_news_trf` y `ca_core_news_sm` son GNU GPL 3.0**, `fr_core_news_sm` es **LGPL-LR**,
  `pt_core_news_sm` y `nl_core_news_sm` son **CC BY-SA 4.0** e `it_core_news_sm` es
  **CC BY-NC-SA 3.0 — no comercial**. La causa es el corpus de entrenamiento, que arrastra su
  licencia al modelo. **Ejecutar `python -m spacy download es_core_news_sm` en un producto cerrado
  es un problema de licencia que nadie mira.**
- **Modelos de incrustación**: `jina-embeddings-v3` declara **CC-BY-NC-4.0** en su ficha, es decir
  **no comercial sin licencia aparte**; y **`facebook/fasttext-language-identification`, el
  detector de idioma más copiado del mundo, declara CC-BY-NC-4.0 en Hugging Face.** Frente a ellos,
  verificados como permisivos: `bge-m3` (MIT), `multilingual-e5-large` (MIT),
  `gte-multilingual-base` (Apache-2.0), `Qwen3-Embedding` (Apache-2.0), `nomic-embed-text-v2-moe`
  (Apache-2.0), `mxbai-embed-large-v1` (Apache-2.0), `all-MiniLM-L6-v2` (Apache-2.0).
  **Discrepancia declarada**: sobre `jina-embeddings-v4` las fuentes se contradicen —se publicó
  etiquetado como CC-BY-NC-4.0 y después se corrigió hacia la licencia de investigación del modelo
  base del que deriva—; **no lo uses sin verificar la ficha vigente tú mismo**.
- **Copyleft en bibliotecas**: `gensim` es **LGPL-2.1**, no permisiva. `NLTK`, `Stanza`,
  `sentence-transformers`, `tokenizers`, `sentencepiece` y `MTEB` son **Apache-2.0**; `spaCy`,
  `Flair`, `fastText` (código) y `tiktoken` son **MIT**. Verificado en crudo.
- **Corpus**: muchos son solo investigación o llevan cláusula *ShareAlike*, que **contamina el
  modelo entrenado con ellos**. La licencia del corpus es un requisito del proyecto, no un detalle
  de la bibliografía.

**Datos personales**: **el texto libre es el peor sitio del sistema para el dato personal** — no
está en una columna, no se puede tipar y aparece donde nadie lo espera (comentarios, adjuntos,
transcripciones, campos de "observaciones"). Criterio: detecta y **seudonimiza en la ingesta**, no
antes de mostrar; guarda el mapa de reversión aparte y con control de acceso propio; y recuerda que
**un modelo entrenado sobre texto con datos personales es difícil de "desetiquetar" y muy difícil de
someter a un borrado**. Base jurídica, DPIA, retención y derechos: `privacy-engineering-standards`.

**Sesgo y equidad como propiedad del sistema, no del modelo**: mídelo sobre **tu** salida y **tus**
subgrupos —idioma, variedad regional, registro formal/informal, longitud del texto, canal—
comparando tasas de error **por subgrupo**, no exactitud global. Un moderador de contenido que
marca más el español coloquial que el formal, o un clasificador de currículos que rinde peor con
nombres de una procedencia, es un fallo de sistema aunque el modelo base sea el mismo para todos.
Lo que no se mide por subgrupo se descubre por reclamación.

## 6. Incrustaciones, evaluación y producción

**Incrustaciones**: un modelo de incrustación convierte texto en un vector cuya **geometría es
propia de ese modelo**. De ahí la regla que más caro sale ignorar:

- **Cambiar de modelo de incrustación obliga a reindexar todo el corpus.** Los vectores del modelo
  nuevo y los del viejo no son comparables aunque tengan la misma dimensión; mezclarlos degrada la
  búsqueda de forma silenciosa, sin error ni alarma. **Trátalo como una migración de datos**: nueva
  colección, reindexado completo, comparación de calidad contra la anterior y conmutación atómica,
  con vuelta atrás posible. Nunca reindexado parcial "según vaya".
- **El nombre y la versión exacta del modelo, su dimensión, si normaliza el vector, la métrica de
  distancia y el prefijo de instrucción que exige** (varios modelos requieren prefijar consulta y
  documento de forma distinta, y omitirlo degrada mucho sin avisar) se **versionan junto al índice**
  como metadato obligatorio.
- **Elección**: multilingüe si tu corpus lo es —un modelo solo-inglés sobre texto español es un
  fallo silencioso—, tamaño y dimensión acordes al coste de almacenamiento y consulta, longitud
  máxima de entrada compatible con tus documentos, y **licencia verificada** (§5).
- **Evaluación de incrustaciones**: los rankings públicos (MTEB) sirven para **descartar**, no para
  elegir. La elección se hace con **tu** conjunto de consultas y documentos reales y una métrica de
  recuperación acordada. El almacén, sus índices y su operación: `vector-db-standards`.

**Evaluación**:

- **La exactitud global engaña en cuanto hay desequilibrio.** Con un 95 % de una clase, "siempre la
  mayoritaria" saca 95 % y no sirve para nada. **Reporta macro-F1 y precisión/recall/F1 por clase**,
  y fija el criterio de aceptación sobre la clase que decide el negocio.
- **Matriz de confusión completa**, siempre: distingue "no lo detectó" de "lo confundió con otra
  cosa"; tienen arreglos distintos.
- **Umbral de decisión como decisión de producto**, con el coste asimétrico explícito, y **elegido
  en validación, jamás mirando el conjunto de prueba** (`classical-ml-standards`).
- **Línea base obligatoria** (regla, TF-IDF, clase mayoritaria) en el mismo conjunto. Un modelo que
  no la bate no se despliega.
- **Las tareas generativas —resumen, traducción, reescritura— no se evalúan con estas métricas**:
  método, jueces y significancia en `llm-evaluation-standards`. Aquí solo la exigencia de que
  **exista** evaluación antes de desplegar.
- **El idioma es una dimensión de evaluación de primera clase.** Un modelo que va bien en inglés
  puede ir mal en español, y peor en catalán, gallego o euskera. **Reporta la métrica desglosada por
  idioma y por variedad**, con conjunto de prueba propio de cada uno; un promedio global dominado
  por el inglés esconde exactamente el fallo que te va a doler. Lo mismo aplica al texto mezclado
  (dos idiomas en una frase), que es la norma en soporte y redes, no la excepción.

**Producción**:

- **La canalización de preprocesado se versiona con el modelo y es una sola.** Normalización,
  limpieza, tokenización y truncado deben ser **idénticos** en entrenamiento y en servicio; una
  diferencia no da error, da menos precisión. Test de igualdad sobre textos de referencia, en CI.
- **Registra el idioma detectado, la longitud en tokens y la confianza de la predicción** por
  petición: son las tres señales que anticipan la degradación antes de que nadie se queje.
- **Deriva de lenguaje**: vocabulario nuevo, jerga, cambio de canal (de correo a chat), campañas y
  nombres de producto nuevos. Vigila la tasa de "desconocido"/baja confianza y la proporción de
  tokens fuera de vocabulario. Gobierno de la deriva: `mlops-standards`.

## 7. Sostenibilidad y prohibiciones

Mantenimiento: fija versión del modelo, del tokenizador y del pipeline de preprocesado como un solo
artefacto. Al subir versión de una biblioteca de PLN, **reejecuta la evaluación completa antes de
promocionar**: un cambio de tokenizador o de modelo por defecto mueve las métricas sin avisar.

- ❌ **PROHIBIDO** usar un LLM para lo que resuelve una expresión regular o una tabla de búsqueda.
- ❌ **PROHIBIDO** montar un proyecto de etiquetado sin haber comprobado antes con un prototipo que
  la tarea es viable y que la etiqueta es consistente.
- ❌ **PROHIBIDO** comparar modelos en un conjunto público y desplegar en otro dominio como si
  midiera lo mismo.
- ❌ **PROHIBIDO** cambiar de modelo de incrustación sin reindexar el corpus completo.
- ❌ **PROHIBIDO** mezclar en un mismo índice vectores de dos modelos o de dos versiones.
- ❌ **PROHIBIDO** reportar exactitud global en un problema desbalanceado sin métricas por clase.
- ❌ **PROHIBIDO** evaluar solo en inglés un sistema que se usará en otros idiomas.
- ❌ **PROHIBIDO** desplegar pesos de modelo sin haber leído su licencia (y la del corpus con el que
  se entrenó): en spaCy cambia por idioma, y hay modelos de uso general que son **no comerciales**.
- ❌ **PROHIBIDO** usar `gensim` u otra dependencia copyleft sin pasarla por la política de licencias.
- ❌ **PROHIBIDO** etiquetar el conjunto de prueba con un LLM sin revisión humana.
- ❌ **PROHIBIDO** dos implementaciones del preprocesado, una para entrenar y otra para servir.
- ❌ **PROHIBIDO** ajustar el umbral mirando el conjunto de prueba.
- ❌ **PROHIBIDO** enviar texto con datos personales a un tercero sin base jurídica y sin haber
  seudonimizado lo que se pueda.
- ❌ **PROHIBIDO** tratar el análisis de sentimiento como un resultado de negocio: sin la decisión
  que cambia, es una métrica decorativa.
- ❌ **PROHIBIDO** entregar un clustering sin que un humano haya nombrado y validado los grupos.

## 8. Verificación web obligatoria

1. **Licencia de los pesos, modelo a modelo y —en spaCy— idioma a idioma**, leyendo el metadato o la
   ficha en crudo. La licencia del paquete de código **no** es la del modelo.
2. **Licencia del corpus** con el que se entrenó el modelo que vas a usar, y si arrastra *NonCommercial*
   o *ShareAlike* al resultado.
3. **Estado y licencia vigentes de `jina-embeddings-v4`**: las fuentes se contradicen (§5).
4. Última versión y estado de mantenimiento de spaCy, Stanza, sentence-transformers y del modelo de
   incrustación elegido; y si el tokenizador cambió entre versiones.
5. **Precio vigente por token** del proveedor con el que compares coste, y el tamaño de contexto
   real — la cuenta del punto de cruce (§3.2) caduca con cada cambio de tarifa.
6. Estado de MTEB y de cualquier ranking que uses para descartar candidatos: cambia de conjuntos y
   de metodología.
7. **Hueco declarado**: este documento **no fija ninguna cifra de exactitud, F1, latencia, coste por
   millón de documentos ni posición en ranking**. No se han verificado cifras con sus condiciones de
   medida (conjunto, idioma, longitud, hardware, versión del modelo), y **sin esas condiciones una
   cifra no significa nada**. Mide tú, con tu corpus y tu hardware.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
