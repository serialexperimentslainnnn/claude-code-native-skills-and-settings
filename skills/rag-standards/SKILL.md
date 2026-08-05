---
name: rag-standards
description: Retrieval-augmented generation treated as a retrieval problem. Use when deciding RAG versus long context versus fine-tuning, parsing and chunking documents for indexing (PDF tables, multi-column, scans, overlap, structure-aware splits), picking an embedding model and dimensionality and paying the reindex cost of changing it, running pgvector versus Qdrant/Weaviate/Milvus/Chroma/LanceDB, tuning HNSW or IVFFlat parameters (m, ef_construction, ef_search, lists, probes), hybrid dense-plus-BM25 retrieval with RRF fusion, cross-encoder reranking, metadata filters, multi-query or HyDE expansion, grounding answers with citations and refusing when the context does not support them, measuring recall@k / MRR / nDCG separately from faithfulness, per-document access control on retrieved chunks, incremental index updates and deleting embeddings on erasure requests, or judging whether GraphRAG and agentic RAG earn their cost.
---

# Estándares de RAG (recuperación aumentada con generación)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, construir, operar o auditar un sistema de **recuperación aumentada**: la decisión
de si RAG es la arquitectura correcta, la ingesta y el parseo por tipo de documento, el chunking, los
embeddings y su ciclo de vida, el almacén vectorial y sus índices, la recuperación híbrida y el
reranking, el prompt de generación anclado en el contexto, la evaluación separada de recuperación y
generación, y la operación del índice (actualización incremental, borrado, control de acceso, coste
y latencia de la cadena completa).

Triggers: "chunking", "chunk", "solape", "overlap", "splitter", "embedding", "reindexar",
"dimensionalidad", "normalizar vectores", "búsqueda por similitud", "coseno", `pgvector`,
`vector(1536)`, `halfvec`, `HNSW`, `IVFFlat`, `m`, `ef_construction`, `ef_search`, `lists`,
`probes`, Qdrant, Weaviate, Milvus, Chroma, LanceDB, "búsqueda híbrida", `BM25`, `tsvector`, `RRF`,
"reranker", "cross-encoder", "filtrado por metadatos", "multi-query", "HyDE", "citar fuentes",
"alucina con el contexto delante", `recall@k`, `MRR`, `nDCG`, "fidelidad al contexto", "GraphRAG",
"RAG agéntico", "borrar del índice", "un usuario ve un chunk que no debería".

**Tesis del dominio — se aplica en todo el documento**: **RAG es un problema de recuperación, no de
generación.** La inmensa mayoría de los fallos ("el modelo alucina", "responde mal") son fallos de
recuperación: el fragmento correcto nunca llegó al contexto. **Corolario operativo: mide la
recuperación por separado antes de tocar el prompt, el modelo o la temperatura.** Un equipo que
depura un fallo de RAG cambiando el prompt de generación, sin haber medido `recall@k`, está
adivinando.

**No aplica**:

- `llm-app-engineering-standards`: la **aplicación completa** sobre LLM — elección de modelo,
  prompting como código, salida estructurada, presupuesto de ventana de contexto, caché de prefijo,
  streaming, fiabilidad, límites de gasto, inyección de prompt, testing de lo no determinista. **La
  app puede no usar RAG; RAG se usa desde la app.** Aquí solo el prompt **de generación anclada**
  (§3.7) — citación y negativa —, no el prompting en general.
- **`claude-api`** (sin sufijo `-standards`, **skill instalada, referencia canónica del lado
  Anthropic**): todo lo **específico de Anthropic** es suyo — IDs de modelo, precios, ventanas de
  contexto, parámetros, caché de prompt, tool use, MCP, Managed Agents, migración. Si necesitas un
  dato de la API de Claude para el generador o para contexto largo, **sale de ahí**, no de aquí ni
  de memoria. Esta skill es agnóstica de proveedor.
- `llm-evaluation-standards` (**Ola 3, planificada**): **la evaluación es suya** — construcción de
  eval sets, LLM-as-judge y su calibración, significancia estadística, regresión en CI. Aquí se
  define **qué se mide en RAG y por qué separado** (§4), y se exige como gate; la maquinaria de
  evaluación vive allí.
- `ai-agents-standards`: el bucle agéntico autónomo. **RAG agéntico** (§3.10) se
  cubre aquí solo como **patrón de recuperación y su coste**; el bucle autónomo, sus herramientas y
  su memoria son suyos.
- `data-platform-standards`: **el motor PostgreSQL** — modelado, migraciones, tuning general,
  réplicas, PITR, backups, particionado. **Frontera explícita con `pgvector`: el índice vectorial y
  su parametrización (`HNSW`/`IVFFlat`, `m`, `ef_*`, `lists`, `probes`, `halfvec`) son de esta
  skill; el motor que lo aloja, su operación y su respaldo son suyos.** Redis/Valkey y Kafka en la
  ingesta, también suyos.
- `object-storage-standards`: el almacenamiento de los documentos originales (S3/MinIO/Ceph),
  ciclo de vida, versionado y coste de egreso.
- `privacy-engineering-standards`: dato personal, minimización, DPIA, consentimiento. **El derecho
  de supresión aplica también al índice y a los embeddings** (§6): aquí la mecánica del borrado en
  el almacén vectorial, allí el derecho y su alcance.
- `appsec-standards`: clases de vulnerabilidad clásicas y triaje. El control de acceso a nivel de
  documento en la recuperación (§5) es **de esta skill**, pero su modelo de autorización subyacente
  es de `identity-access-management-standards`.
- `mcp-standards`: exponer recuperación como servidor MCP y su seguridad.
- `mlsecops-standards`, `local-inference-standards`, `gpu-computing-standards`, `mlops-standards`,
  `ai-governance-standards` (**Ola 3, planificadas**): seguridad del ciclo de vida del modelo,
  servir embeddings/rerankers propios (vLLM, TEI, llama.cpp), hardware, y gobierno del AI Act.
- `observability-standards`: OTel, backends y cardinalidad. Las **métricas de la cadena RAG**
  (recall, latencia por etapa, coste por consulta) son de esta skill; el transporte y el backend,
  suyos.
- `api-design-standards`: el contrato de tu API de búsqueda hacia fuera.
- `python-standards` / `typescript-standards`: implementación; `cicd-standards`: los gates de §4;
  `kubernetes-standards`, `iac-standards`, `secrets-management-standards`,
  `backup-recovery-standards`, `sre-practice-standards`, `grc-compliance-standards`: sus dominios.

## 2. Decisiones por defecto

> Verificar la última versión, licencia y estado por web antes de fijar nada (§8). Este sector tiene
> **cambios de licencia frecuentes** y adquisiciones; lo verificado aquí es de agosto 2026.

### 2.1 ¿RAG, contexto largo o fine-tuning?

La pregunta se contesta **antes** de montar nada. En 2026 las ventanas de 1M tokens son habituales,
así que "el corpus no cabe" ya no es automático.

| Situación | Arquitectura | Motivo |
|---|---|---|
| El corpus cabe holgadamente en la ventana y el volumen de consultas es bajo | **Contexto largo directo** | RAG aquí es **complejidad gratuita**: pipeline de ingesta, índice, y un modo de fallo nuevo, para nada |
| Corpus órdenes de magnitud mayor que cualquier ventana | **RAG** | Es la única arquitectura que funciona |
| Volumen alto de consultas sobre el mismo corpus grande | **RAG** | El coste de entrada escala linealmente: pagar por leer todo el archivo en cada petición es insostenible |
| Se exige trazabilidad de qué documento fundamentó la respuesta | **RAG** | La citación es un requisito de auditoría, no una funcionalidad |
| El corpus cambia constantemente | **RAG** | El índice se actualiza; reentrenar no |
| Latencia crítica sobre corpus grande | **RAG** | Enviar 1M tokens es más lento que recuperar 5 fragmentos |
| Razonamiento holístico sobre un conjunto acotado (comparar dos contratos, revisar un repositorio, sintetizar N artículos) | **Contexto largo** | La evidencia está distribuida; trocear la destruye |
| Necesitas **forma**: tono, formato, taxonomía propia, comportamiento | **Fine-tuning** (o prompting) | El fine-tuning enseña **forma, no hechos**. Usarlo para inyectar conocimiento es caro, se desactualiza y alucina |
| Existe una API con la respuesta (precio, stock, saldo, estado) | **Llamada a la API** | Vectorizar datos estructurados con respuesta exacta es un error de diseño |
| Mixto (lo habitual en producción) | **Híbrido**: recuperar y razonar en contexto largo sobre lo recuperado | Enruta por forma de la consulta |

**Dos hechos que sostienen el criterio y hay que reverificar (§8)**: la calidad degrada con la
longitud de entrada mucho antes del límite anunciado (*context rot*), y la información en mitad del
contexto se aprovecha peor que la de los extremos (*lost in the middle*). Una ventana grande es
capacidad, no garantía.

**Regla de decisión honesta**: si dudas, empieza **sin** RAG. Añádelo cuando midas que hace falta.

### 2.2 Toolchain

| Ámbito | Default | Motivo / alternativa |
|---|---|---|
| Almacén vectorial | **`pgvector` sobre el PostgreSQL que ya tienes** (0.8.x; 0.8.6 jul-2026, licencia PostgreSQL) | **Criterio real: si ya operas PostgreSQL y el volumen es moderado (hasta ~decenas de millones de vectores), pgvector evita una pieza de operación entera** — backup, HA, monitorización, autenticación y transaccionalidad ya resueltos, y el filtrado por metadatos es simplemente SQL |
| Motor dedicado | **Qdrant** (Rust, Apache-2.0, 1.18.x jul-2026) como default cuando pgvector no llega | Filtrado con payload muy bueno, operación sencilla, licencia limpia |
| Alternativas | **Milvus** (Apache-2.0; **3.0.0 en jul-2026**, además de la serie 2.6.x) escala masiva a cambio de complejidad operativa alta; **Weaviate** (core BSD-3, 1.38.x/1.39-rc) módulos integrados; **Chroma** (Apache-2.0) prototipado, **no** producción seria; **LanceDB** (Apache-2.0) formato columnar sobre object storage, buen encaje analítico | Cambio de major reciente en Milvus: no adoptar 3.x sin leer la migración |
| Búsqueda léxica | **La que ya tenga tu almacén**: `tsvector`/`ParadeDB` en PostgreSQL, sparse vectors en Qdrant, BM25 nativo donde exista | Añadir OpenSearch/Elasticsearch **solo** por BM25 es una pieza cara |
| Índice ANN | **HNSW** por defecto | Mejor compromiso velocidad/recall; se puede crear sobre tabla vacía (sin fase de entrenamiento) |
| IVFFlat | Solo si la memoria es la restricción dominante y aceptas peor recall | Requiere datos representativos ya cargados antes de indexar |
| Métrica de distancia | **La que el modelo de embedding declare** (casi siempre coseno / producto interno sobre vectores normalizados) | Usar una métrica distinta a la del entrenamiento degrada silenciosamente |
| Reranker | **Cross-encoder**, `BGE reranker v2-m3` o `mxbai-rerank` (**ambos Apache-2.0**) autoalojado; API gestionada (Cohere, Voyage) si no quieres servir modelo | ⚠️ **Los pesos de Jina Reranker son CC-BY-NC**: no desplegables en producto comercial; su uso comercial pasa por la API. **Verifica la licencia de cada reranker antes de desplegarlo** |
| Modelo de embedding | **Decisión por evaluación propia** (§2.4). Familias vigentes a ago-2026: Qwen3-Embedding y BGE-M3 (abiertos), y las de OpenAI/Google/Voyage/Cohere (API) | ⚠️ **Nombres y versiones exactas NO fijados aquí** — cambian mensualmente y las fuentes públicas se contradicen. Verificar (§8) |
| Evaluación de RAG | **RAGAS** (Apache-2.0) como punto de partida, con conjunto propio | ⚠️ Cadencia lenta: última release **0.4.3 (ene-2026)**, ~7 meses sin publicar a ago-2026. **Verifica su estado antes de depender de él**; detalle en `llm-evaluation-standards` |
| Framework de ingesta | **LlamaIndex** (0.14.x) si quieres los conectores hechos; código propio si el corpus es de pocos tipos | Un pipeline de ingesta propio de 300 líneas suele ser más mantenible que un framework para 3 formatos |

### 2.3 Parámetros de índice (compromiso exactitud / memoria / velocidad)

Los índices ANN son **aproximados**: cambian recall por velocidad. Fijar sus parámetros a ciegas es
la causa más común de "el sistema recupera mal" sin que nadie lo note.

| Parámetro | Efecto | Criterio |
|---|---|---|
| `m` (HNSW) | Conexiones por nodo. ↑ = mejor recall, más memoria, construcción más lenta | Empieza en el default; súbelo solo si el recall medido no llega |
| `ef_construction` (HNSW) | Esfuerzo al construir. ↑ = mejor grafo, construcción mucho más lenta | Se paga una vez; ser generoso aquí suele salir rentable |
| `ef_search` (HNSW) | Candidatos en consulta. ↑ = mejor recall, más latencia | **Único parámetro ajustable en caliente. Es tu dial recall↔latencia en producción** |
| `lists` (IVFFlat) | Número de particiones | Depende del tamaño del corpus; reindexar es obligatorio si el corpus crece mucho |
| `probes` (IVFFlat) | Particiones visitadas en consulta | Dial recall↔latencia equivalente a `ef_search` |
| Cuantización (`halfvec`, escalar, binaria) | Reduce memoria drásticamente, cuesta recall | **Mide el recall antes y después.** Nunca la actives "por eficiencia" sin medir |

**Regla dura**: **el recall del índice se mide contra búsqueda exacta (fuerza bruta) sobre una
muestra**, no se asume. Un índice mal parametrizado no da error: da respuestas peores, en silencio.

**Interacción con el filtrado**: un filtro restrictivo combinado con un índice ANN puede devolver
menos resultados de los pedidos, o degradar a escaneo. Verifica el comportamiento de tu motor
(pgvector 0.8+ tiene *iterative scans* precisamente para esto) y **mide el recall con filtro
aplicado**, no solo sin él.

### 2.4 Embeddings: la decisión de ida única

| Decisión | Criterio |
|---|---|
| Elección de modelo | **Por evaluación sobre tu corpus**, con tus consultas reales |
| MTEB | **Señal, no verdad.** Está contaminado: muchos modelos entrenan sobre datos que solapan con sus datasets, así que el ranking no predice calidad en un corpus privado. Además MTEB v2 no es comparable con v1. **Úsalo para preseleccionar 3-4 candidatos, no para decidir** |
| Multilingüe | **Obligatorio si el corpus o las consultas lo son.** Un modelo entrenado en inglés sobre corpus en español recupera mal, y no da ningún error |
| Dominio especializado (legal, médico, código) | Los modelos genéricos degradan. Evalúa modelos de dominio o fine-tuning del embedder — es de los pocos fine-tunings con retorno claro |
| Dimensionalidad | **Más dimensiones no es mejor por defecto.** Cuestan memoria de índice, latencia y almacenamiento, linealmente. Si el modelo soporta reducción tipo Matryoshka, evalúa la versión reducida: a menudo el coste cae mucho y el recall casi nada |
| Normalización | Normaliza si la métrica lo requiere, **y hazlo igual en indexación y en consulta**. Un desajuste aquí destroza la búsqueda sin error visible |
| Simetría | Muchos modelos exigen **prefijo/instrucción distinta para consulta y para documento**. Olvidarlo es un bug silencioso muy común |

**El coste de reindexar es la decisión de ida única del dominio.** Cambiar de modelo de embedding
implica **recalcular todos los vectores del corpus**: coste de inferencia proporcional al corpus
entero, ventana de reindexación, y almacenamiento doble si quieres hacerlo sin caída. En la práctica
esto significa:

1. **Elige bien la primera vez**, con evaluación real.
2. **Guarda el texto original de cada chunk** junto al vector. Sin el texto no puedes reindexar sin
   reprocesar los documentos fuente.
3. **Versiona el índice** (`chunks_v3`) e incluye modelo y versión en los metadatos de cada vector.
   Mezclar vectores de dos modelos en un mismo índice produce resultados sin sentido y sin error.
4. **Diseña el camino de migración desde el día uno**: doble escritura a índice nuevo, comparación
   de recall, corte con bandera de funcionalidad, y rollback.

## 3. Estructura y convenciones de la cadena

### 3.1 Ingesta y parseo

**Basura entrando es basura saliendo.** Ningún chunking, embedding ni reranker recupera de un texto
que se extrajo mal. El parseo es la etapa con **mayor retorno por esfuerzo** de toda la cadena y la
que más se subestima.

- **PDF es el problema difícil**, y su dificultad es escalonada: PDF con capa de texto limpia →
  trivial; **multi-columna** → el orden de lectura se rompe y el texto sale intercalado;
  **tablas** → se aplanan y pierden la relación fila/columna, que suele ser justo el dato;
  **escaneado** → requiere OCR y su tasa de error se propaga a todo lo demás.
- **Verifica el texto extraído sobre una muestra representativa antes de indexar nada.** Es el paso
  que más equipos se saltan. Un corpus de 100k documentos con orden de lectura roto es dinero
  quemado en embeddings.
- Las **tablas se tratan aparte**: extraerlas a una representación estructurada (Markdown, CSV,
  descripción textual) preserva la semántica que el texto plano destruye.
- **Limpieza**: cabeceras/pies repetidos, numeración de página, marcas de agua, navegación y
  *boilerplate* son ruido que compite en la similitud. Quítalos.
- **Metadatos desde el origen**: fuente, título, sección, fecha, versión, idioma, autor, y **todo lo
  necesario para el control de acceso (§5)**. Los metadatos que no captures en la ingesta no
  existirán jamás en el índice.
- **Deduplicación** antes de indexar: el mismo documento en tres versiones llena el top-k de
  duplicados y desplaza evidencia útil.
- Pipeline **idempotente y reejecutable**, con identificador estable por documento y por chunk.

### 3.2 Chunking

El chunk es la **unidad de recuperación *y* la unidad de contexto** a la vez. El tamaño óptimo
depende de las dos cosas: si es demasiado grande, la similitud se diluye y recuperas ruido; si es
demasiado pequeño, recuperas un fragmento que por sí solo no responde nada.

| Estrategia | Cuándo |
|---|---|
| **Por estructura del documento** (sección, encabezado, artículo, celda, función) | **Default cuando el documento tiene estructura.** Respeta límites semánticos reales y produce citación natural |
| Por tamaño fijo con solape | Cuando no hay estructura aprovechable. Simple, predecible, barato |
| Semántico (corte donde cambia el tema) | Cuando el texto es continuo y sin marcas. Más caro; **mide si aporta antes de adoptarlo** |
| Por elemento para tablas/código | Nunca partas una tabla o una función por la mitad por llegar al límite de caracteres |

Reglas:

- **El solape existe para no partir una respuesta en dos.** Un solape moderado es sano; un solape
  grande infla el índice y llena el top-k con near-duplicates.
- **Mide el tamaño en tokens del modelo de embedding**, no en caracteres, y respeta su longitud
  máxima: lo que exceda se trunca **silenciosamente** y pierdes el final de cada chunk.
- **Enriquece el chunk con su contexto**: título del documento y ruta de secciones antepuestos al
  texto. Es barato, mejora recuperación y es lo que permite citar bien.
- **Guarda punteros al documento y a la posición** (página, offset, sección) en los metadatos: es lo
  que hace posible la citación verificable (§3.7) y ampliar el contexto en la generación.
- **No hay tamaño universal.** Es un hiperparámetro: barre 2-3 configuraciones contra tu conjunto de
  evaluación y elige por `recall@k` medido, no por lo que diga un tutorial.

### 3.3 Recuperación híbrida: el default serio

**Denso solo no es suficiente.** La búsqueda vectorial falla justo donde el usuario es más
específico: identificadores, referencias de norma, códigos de producto, nombres propios raros,
siglas, errores literales. La búsqueda léxica falla en sinónimos y paráfrasis. Las dos juntas se
cubren mutuamente.

- **Default: denso + léxico (BM25 / `tsvector`), fusionados con RRF** (*Reciprocal Rank Fusion*).
- **RRF es el default de fusión** porque combina rankings sin necesidad de calibrar puntuaciones
  entre sistemas cuyas escalas no son comparables. Una suma ponderada de puntuaciones crudas exige
  normalización y se descalibra sola.
- **Recupera generosamente antes de refinar**: un top-k amplio (decenas) en cada recuperador es
  barato; lo que cuesta es meterlo todo en el contexto. Para eso está el reranker.
- **Filtrado por metadatos** en la propia consulta (fecha, tipo, idioma, tenant, permisos): reduce
  el espacio de búsqueda y es donde pgvector brilla, porque es un `WHERE` normal.

### 3.4 Reranking: la mejora de mayor retorno por esfuerzo

Un **cross-encoder** puntúa consulta y documento **juntos**, no por separado, y por eso ordena mucho
mejor que un bi-encoder. El patrón:

```
consulta → [denso top-50 ∥ BM25 top-50] → RRF → reranker cross-encoder → top-5 → contexto
```

- **Es la primera mejora que se prueba** cuando la recuperación falla, antes de cambiar embeddings,
  chunking o arquitectura. Suele mover más el `nDCG` que cualquiera de ellas y cuesta un componente.
- **Coste**: latencia proporcional al número de candidatos rerankeados. Con reranker autoalojado
  evitas el viaje de red, a cambio de servir un modelo (`local-inference-standards`, Ola 3).
- **Verifica la licencia de los pesos** (§2.2): hay rerankers de calidad con licencia no comercial.
- **Diagnóstico útil**: si tu top-50 contiene el pasaje correcto pero tu top-5 no, tu problema es de
  ordenación → reranker. Si no está en el top-50, es de recuperación → híbrido, chunking o
  embeddings. **Esta distinción se hace midiendo `recall@50` frente a `recall@5`.**

### 3.5 Expansión de consulta: cuándo aporta

- **Multi-consulta** (reformular la pregunta en N variantes y fusionar): aporta en consultas
  ambiguas o multi-parte. Cuesta N recuperaciones + una llamada al modelo.
- **HyDE** (generar una respuesta hipotética y buscar con su embedding): puede ayudar cuando la
  consulta y el documento están redactados de forma muy distinta. Añade una llamada al modelo en el
  camino crítico **y puede alucinar la hipótesis y desviar la búsqueda**.
- **Criterio**: son optimizaciones, no cimientos. **Híbrido + reranker primero; expansión solo si la
  evaluación demuestra que el problema persiste y que esto lo arregla.** Ambas añaden latencia y
  coste en cada consulta, incluidas las que ya funcionaban.

### 3.6 Enrutado por complejidad

No todas las consultas merecen la misma cadena. Una búsqueda factual simple no necesita
multi-consulta, ni grafo, ni bucle agéntico. **Enruta: cadena barata por defecto, cadena cara solo
cuando la consulta lo justifique.** Aplicar el arsenal completo a todo es la forma más rápida de que
el coste por consulta se descontrole sin mejora medible.

### 3.7 El prompt de generación anclada

Es la única parte de prompting que vive en esta skill (el resto: `llm-app-engineering-standards`).

- **Citar fuentes es obligatorio** cuando la respuesta afirma hechos. La cita debe apuntar a un
  fragmento recuperado concreto e identificable, no a "los documentos".
- **Verifica las citas por código**, no por confianza: que el identificador citado esté entre los
  recuperados. Una cita inventada es peor que ninguna cita.
- **Decir "no lo sé" cuando el contexto no lo soporta es un requisito funcional, no una cortesía.**
  Instrucción explícita, y en la evaluación: **casos cuya respuesta correcta es la negativa.**
- **La alucinación con el contexto delante es el fallo que destruye la confianza** — el usuario ve
  las fuentes citadas y la respuesta que no se sigue de ellas, y a partir de ahí no vuelve a creer
  al sistema. Se mide como **fidelidad al contexto** (§4) y es la métrica de generación que más
  importa.
- **Separa contexto recuperado de instrucciones.** El contenido recuperado es entrada **no
  confiable**: un documento del corpus puede llevar instrucciones inyectadas
  (`llm-app-engineering-standards` §5). Un corpus donde cualquiera puede escribir es un vector de
  inyección indirecta.
- Ordena el contexto: lo más relevante en los extremos, no enterrado en el medio (§2.1).

### 3.8 Convenciones de esquema

```
documento(id, uri, titulo, tipo, version, hash, fecha, idioma, acl_ref, creado_en)
chunk(id, documento_id, orden, texto, tokens, pagina, seccion, hash)
embedding(chunk_id, modelo, modelo_version, dim, vector, creado_en)
```

- **Texto del chunk siempre persistido** (§2.4): sin él no hay reindexación barata ni depuración.
- `modelo` + `modelo_version` en cada vector: sin esto no puedes migrar ni detectar mezcla.
- `hash` de documento y de chunk: es lo que hace la ingesta incremental e idempotente (§6).
- `acl_ref`: la referencia de autorización viaja **con el chunk** (§5).
- Índice versionado por nombre (`chunks_v3`), no mutado en sitio.

### 3.9 Métricas de la cadena

Instrumenta **por etapa**, no solo de extremo a extremo: latencia y coste de embedding de consulta,
de recuperación densa, de léxica, de fusión, de reranking y de generación. Sin el desglose no sabes
qué optimizar, y la respuesta suele sorprender.

### 3.10 Más allá del RAG básico — con honestidad sobre su coste

| Arquitectura | Qué es | Cuándo **sí** | El coste que se omite en los blogs |
|---|---|---|---|
| **GraphRAG** | Extrae entidades y relaciones a un grafo; recupera recorriéndolo | Preguntas de "conectar puntos" entre documentos, cadenas de dependencia (precedente legal, cumplimiento, cadena de suministro), y **resolución de entidades** cuando la misma entidad aparece con nombres, siglas y códigos distintos | **Coste de indexación muy alto** (extracción por LLM sobre todo el corpus) y un pipeline nuevo que mantener y reconstruir. Las variantes de indexación diferida reducen mucho ese coste — **verifica cifras y madurez (§8), no las asumas** |
| **RAG agéntico** | El modelo descompone la consulta, recupera, evalúa suficiencia y decide si sigue | Consultas complejas y multi-salto donde una sola pasada no basta | **Multiplica latencia y tokens**, y en consultas factuales simples es despilfarro puro. Exige enrutado por complejidad (§3.6) y tope de iteraciones. El bucle en sí es de `ai-agents-standards` |
| **Late interaction** (ColBERT y similares) | Embeddings por token con puntuación tardía | Casos donde el vector único no basta: cláusula enterrada, dato dentro de una tabla, consultas multi-parte | Índice mucho mayor. El pipeline bi-encoder + cross-encoder es más simple y a menudo equivalente |

**Criterio transversal**: **híbrido + reranker primero.** Arregla la mayoría de los fallos de
recuperación. Todo lo demás se añade cuando **tus métricas** demuestren que lo simple no llega — no
por lectura de un blog. La mayoría de las cifras espectaculares que circulan sobre estas
arquitecturas vienen de blogs de proveedor sin condiciones reproducibles.

## 4. Calidad y evaluación — gates

**La regla de oro del dominio: mide recuperación y generación por separado.** Una métrica de extremo
a extremo te dice que el sistema falla; no te dice **dónde**, y en RAG casi siempre es en la
recuperación. Sin la separación, el equipo optimiza el prompt durante semanas mientras el problema
está en el chunking.

### 4.1 Métricas de recuperación (sin LLM, deterministas, baratas)

| Métrica | Qué responde |
|---|---|
| `recall@k` | ¿Llegó el fragmento correcto al contexto? **La métrica más importante del sistema**: si es baja, ninguna mejora de generación puede salvarte |
| `precision@k` | ¿Cuánto ruido acompaña a la señal? Ruido alto desplaza evidencia y encarece |
| `MRR` | ¿Cómo de arriba aparece el primer resultado relevante? |
| `nDCG@k` | Calidad del **orden** con relevancia graduada. **La que mueve el reranking** |
| `recall@50` frente a `recall@5` | Diagnóstico: separa fallo de recuperación de fallo de ordenación (§3.4) |

### 4.2 Métricas de generación

| Métrica | Qué responde |
|---|---|
| **Fidelidad al contexto** | ¿Cada afirmación se sigue del contexto recuperado? Es la métrica anti-alucinación |
| **Relevancia de la respuesta** | ¿Responde a lo que se preguntó? |
| **Precisión de citación** | ¿Las citas existen entre lo recuperado y sostienen la afirmación? Verificable **por código** |
| **Tasa de negativa correcta** | ¿Dice "no lo sé" cuando debe, y solo cuando debe? Requiere casos negativos en el conjunto |

Cómo se calculan, con qué juez y con qué calibración: `llm-evaluation-standards` (Ola 3).

### 4.3 Conjunto de evaluación propio del dominio

**No se puede mejorar lo que no se mide, y ningún benchmark público mide tu corpus.** El conjunto
mínimo viable:

- **50-200 pares consulta → chunks relevantes**, etiquetados sobre **tu** corpus.
- Consultas **reales de usuarios** en cuanto las tengas. Las inventadas por el equipo son
  sistemáticamente más fáciles y limpias que las reales.
- Cobertura obligatoria de **bordes**: consultas cuya respuesta es que **no está en el corpus**;
  consultas ambiguas; multi-salto (la respuesta exige dos documentos); específicas con identificador
  o código; con errores tipográficos; en cada idioma del corpus; y **de un usuario que no debe ver
  ciertos documentos** (§5).
- Se versiona con el código. Crece cuando aparece un fallo real: **todo fallo de recuperación en
  producción deja un caso de regresión.**

### 4.4 Gates que rompen el build

| # | Gate | Rompe si |
|---|---|---|
| 1 | Lint + tipos (skill del lenguaje) | Falla |
| 2 | Ingesta idempotente: reprocesar el mismo documento no duplica chunks | Duplica |
| 3 | Todo vector lleva `modelo` + `modelo_version`; **ningún índice mezcla modelos** | Mezcla detectada |
| 4 | Todo chunk conserva su texto y sus punteros (documento, posición) | Falta |
| 5 | **Test de aislamiento por permisos**: un usuario sin acceso a un documento **nunca** recibe sus chunks (§5) | **Fuga. Este gate es innegociable** |
| 6 | **`recall@k` sobre el conjunto de evaluación con umbral de no-regresión** | Regresión |
| 7 | **`recall` del índice ANN frente a búsqueda exacta** sobre una muestra | Bajo umbral |
| 8 | Precisión de citación verificada por código (toda cita apunta a un chunk recuperado) | Cita inventada |
| 9 | Casos de negativa: el sistema no responde lo que el contexto no soporta | Responde |
| 10 | **Evaluación obligatoria si el diff toca chunking, modelo de embedding, parámetros de índice, recuperación o reranker** | Regresión sobre umbral |
| 11 | Test de borrado: eliminado un documento, sus chunks y vectores desaparecen del índice (§6) | Sobrevive alguno |
| 12 | SCA sobre el stack (§5) | Crítica o dependencia sin fijar |

## 5. Seguridad

### 5.1 Control de acceso a nivel de documento — el fallo clásico

**El fallo de seguridad característico de RAG: un usuario recupera un chunk que no debería ver.** La
aplicación tiene autorización impecable en su API y, por debajo, el índice vectorial devuelve
cualquier cosa a cualquiera. El modelo entonces resume alegremente el documento confidencial.

Criterio, en orden de fiabilidad:

1. **Filtra en la consulta al almacén, no después.** Filtrar los resultados en la aplicación tras
   recuperarlos es frágil (un camino que olvida el filtro es una fuga) y además rompe el top-k: si
   descartas 8 de 10, te quedan 2.
2. **La referencia de autorización viaja con el chunk** (`acl_ref` en metadatos, §3.8) y se
   materializa como filtro en cada consulta. En pgvector esto es un `WHERE` y, mejor aún, **Row-Level
   Security** — la red que no depende de que la aplicación se acuerde (`data-platform-standards`).
3. **Índices separados por frontera de confianza** cuando el aislamiento debe ser fuerte
   (multi-tenant con datos regulados). Un filtro es una condición; un índice separado es un límite.
4. **Sincronización de permisos**: si los permisos del origen cambian, el índice debe reflejarlo. Un
   índice con permisos de hace un mes es una fuga con retardo. Define la frecuencia y **aliméntala
   por eventos** cuando sea posible.
5. **Test obligatorio en CI** (§4, gate 5), con usuarios de distintos niveles. Es el único control
   que no se degrada solo.
6. **Ojo con las citas y los metadatos**: el título de un documento, su ruta o su existencia pueden
   ser información sensible aunque el contenido no se muestre. La fuga por metadatos es real.

### 5.2 Envenenamiento del corpus e inyección indirecta

- **El contenido recuperado es entrada no confiable.** Si el corpus admite contenido de usuarios,
  scraping, correo o tickets, un atacante puede plantar instrucciones que el modelo leerá como
  tales. Esto es inyección de prompt indirecta: la contención se hace fuera del modelo
  (`llm-app-engineering-standards` §5).
- **Corresponde a `LLM08` *Vector and Embedding Weaknesses* del OWASP Top 10 for LLM Applications
  2025** (edición vigente; verificar §8).
- **Procedencia y confianza por documento**: distingue en los metadatos el corpus curado del corpus
  abierto, y trata el segundo con menos privilegio (no citable como autoridad, no accionable).
- **Los embeddings pueden filtrar información del texto original** por ataques de inversión: no los
  trates como una forma de anonimización. Un vector de un dato personal **es** un dato personal.

### 5.3 Cadena de suministro y dependencias

Este ecosistema ya tiene incidentes reales: el compromiso de **LiteLLM en PyPI (marzo 2026,
versiones `1.82.7`/`1.82.8`)** llegó por un pipeline que ejecutaba una herramienta sin versión
fijada, y afectó a usuarios de varios frameworks de agentes y RAG. **Fija dependencias por hash**,
verifica que el artefacto publicado se corresponde con un tag del repositorio, y trata como
comprometido cualquier host que instalara una versión afectada. Detalle en
`llm-app-engineering-standards` §5.4, `cicd-standards` y `vulnerability-management-standards`.

Además: **pgvector 0.8.2 (feb-2026) corrigió CVE-2026-3172**, un desbordamiento en la construcción
paralela de índices HNSW capaz de filtrar datos de otras relaciones o tumbar el servidor. El motor
vectorial es superficie de ataque como cualquier otra: entra en el ciclo de parcheo.

### 5.4 Datos personales en el índice

- Minimiza antes de indexar: lo que no entra al corpus no puede recuperarse ni filtrarse.
- El índice vectorial es **una copia más** del dato a efectos de inventario, retención y borrado
  (§6). Si tu registro de tratamiento no lo incluye, está incompleto.
- Cifrado en reposo y control de acceso del almacén, como cualquier base de datos
  (`data-platform-standards`, `cryptography-pki-standards`).
- Marco: `privacy-engineering-standards`.

## 6. Operación

### 6.1 Actualización incremental

- **Nunca reindexes todo por un documento que cambió.** Ingesta por eventos o por barrido con
  detección de cambios: `hash` de documento → si cambió, re-chunk y re-embed solo ese documento;
  `hash` de chunk → si el chunk no cambió, reutiliza su vector (ahorro grande en documentos con
  ediciones pequeñas).
- Operación **atómica por documento**: borrar chunks viejos e insertar nuevos en una transacción, o
  el índice queda inconsistente y sirve resultados de dos versiones a la vez.
- **Frescura como métrica**: retraso entre el cambio en el origen y su disponibilidad en el índice.
  Con SLO, si el producto depende de ello.
- **Reindexación completa**: es una operación planificada, no un accidente. Índice nuevo en
  paralelo, comparación de recall contra el actual, corte con bandera, rollback disponible (§2.4).

### 6.2 Borrado

**El derecho de supresión aplica al índice y a los embeddings**, no solo a la base de datos de
origen. Un documento borrado del origen que sigue en el índice se recupera, se cita y se resume.

- El borrado se propaga a: chunks, vectores, índice léxico, cachés de consulta, cachés de resultados
  y cualquier grafo derivado (GraphRAG).
- **Borrado real, no lógico**, cuando la base legal es el derecho de supresión. Un `deleted_at` que
  el filtro de recuperación puede olvidar no es un borrado.
- **Los backups del índice también contienen el dato**: su tratamiento (crypto-shredding, retención
  acotada, reindexación tras restore) se decide con `privacy-engineering-standards` y
  `backup-recovery-standards`.
- **Test de borrado en CI** (§4, gate 11).

### 6.3 Coste y latencia de la cadena completa

Presupuesto explícito por consulta, con desglose por etapa (§3.9):

| Etapa | Coste dominante |
|---|---|
| Ingesta (una vez + incremental) | Parseo/OCR + inferencia de embeddings sobre todo el corpus |
| Almacenamiento | Vectores (dimensiones × corpus) + índice en memoria + texto original |
| Consulta | Embedding de consulta + búsqueda ANN + léxica + **reranking** + **generación** |

- **La generación domina casi siempre el coste por consulta**; el reranking domina la latencia
  añadida. Optimizar la búsqueda ANN cuando el 90 % del gasto está en la generación es optimizar lo
  que no importa: **mide antes**.
- El **caché de consultas frecuentes** (por consulta normalizada + permisos) es la optimización de
  coste más rentable en corpus estables. **Cachea siempre dentro de la frontera de permisos**: un
  caché compartido entre usuarios con distinto acceso es una fuga.
- Alerta sobre: recall que cae (deriva del corpus o del índice), latencia p95 por etapa, tasa de
  negativas que sube (puede indicar recuperación rota), coste por consulta.

### 6.4 Runbook mínimo

Recuperación degradada tras reindexar; índice corrupto o incompleto; modelo de embedding
indisponible; documento que debía borrarse y sigue apareciendo; usuario que ve lo que no debe
(**incidente de seguridad**, no bug de calidad → `incident-management-standards`).

## 7. Sostenibilidad y prohibiciones

**Cadencia de revisión: 3 meses.** Modelos de embedding, rerankers, licencias de almacenes
vectoriales y arquitecturas cambian trimestralmente.

- Revisar: versión y CVEs del almacén vectorial, **licencia** (cambio de licencia es el patrón
  frecuente del sector), estado del modelo de embedding y del reranker, y si el conjunto de
  evaluación sigue representando el tráfico real.
- **El conjunto de evaluación es el activo con más valor a largo plazo del sistema.** Sobrevive a
  cambios de modelo, de almacén y de framework. Trátalo como código de producción.
- Deuda consciente registrada: evaluación pendiente, borrado no propagado, parámetros de índice sin
  medir.

**PROHIBIDO**

- ❌ Montar RAG sin haber comprobado que el corpus no cabe en contexto o que el volumen/latencia/
  auditoría lo exigen.
- ❌ Usar fine-tuning para inyectar hechos. Enseña forma, no conocimiento.
- ❌ Vectorizar datos estructurados que una consulta o una API responden de forma exacta.
- ❌ **Depurar un fallo de RAG tocando el prompt sin haber medido `recall@k` primero.**
- ❌ Indexar sin verificar el texto extraído sobre una muestra (especialmente PDF).
- ❌ Partir tablas, funciones o unidades semánticas por llegar a un límite de caracteres.
- ❌ Medir el tamaño de chunk en caracteres en vez de en tokens del modelo de embedding.
- ❌ Usar prefijo/instrucción distinta —o ninguna— entre indexación y consulta.
- ❌ Elegir el modelo de embedding por posición en MTEB. Está contaminado y v2 no compara con v1.
- ❌ Mezclar vectores de dos modelos o versiones en el mismo índice.
- ❌ Indexar sin guardar el texto original del chunk ni los punteros al documento.
- ❌ Cambiar de modelo de embedding sin plan de reindexación, comparación de recall y rollback.
- ❌ Fijar parámetros de índice ANN sin medir el recall contra búsqueda exacta.
- ❌ Activar cuantización "por eficiencia" sin medir la pérdida de recall.
- ❌ **Recuperación solo densa** como arquitectura final: el híbrido con léxico es el default serio.
- ❌ Saltar el reranker y pasar a GraphRAG o RAG agéntico. Es la mejora barata que hay que probar antes.
- ❌ Aplicar la cadena cara a todas las consultas sin enrutar por complejidad.
- ❌ Generar sin citar cuando se afirman hechos; o citar sin verificar la cita por código.
- ❌ No permitir al sistema decir "no lo sé". La alucinación con contexto destruye la confianza.
- ❌ Tratar el contenido recuperado como confiable.
- ❌ **Filtrar permisos después de recuperar en vez de en la consulta al almacén.**
- ❌ Caché de resultados compartido entre usuarios con distintos permisos.
- ❌ Índice sin sincronización de permisos con el origen.
- ❌ Borrado lógico como respuesta al derecho de supresión; borrado que no se propaga a vectores,
  índice léxico, cachés y grafos derivados.
- ❌ Tratar el embedding como una forma de anonimización.
- ❌ Evaluar sin conjunto propio del dominio, o sin casos negativos y de borde.
- ❌ Chroma en producción seria; adoptar un major nuevo (Milvus 3.x, Haystack 3.x) sin leer la migración.
- ❌ Desplegar un reranker sin verificar la licencia de sus pesos (varios son no comerciales).
- ❌ Añadir un motor vectorial dedicado teniendo PostgreSQL y volumen moderado, sin ADR que
  justifique la pieza de operación extra.
- ❌ Fijar de memoria un nombre de modelo de embedding, un precio o una cifra de benchmark (§8).

## 8. Verificación web obligatoria

1. **Almacenes vectoriales**: versión, **licencia** y estado de pgvector, Qdrant, Weaviate, Milvus,
   Chroma, LanceDB. Verificado a ago-2026: pgvector 0.8.6 (licencia PostgreSQL), Qdrant 1.18.x
   (Apache-2.0), Milvus **3.0.0** además de 2.6.x (Apache-2.0), Weaviate 1.38.x/1.39-rc (core
   BSD-3), Chroma y LanceDB (Apache-2.0). **El cambio de licencia es un patrón frecuente en este
   sector: reverifica antes de comprometerte, y comprueba si alguno ha sido abandonado o adquirido.**
   Preferir feeds Atom de releases al resumen de una página HTML.
2. **CVEs del almacén**: pgvector 0.8.2 corrigió CVE-2026-3172 (HNSW paralelo). Comprueba avisos
   antes de fijar versión.
3. **Modelos de embedding vigentes** y su longitud máxima, dimensionalidad, soporte multilingüe,
   requisitos de prefijo y precio. **No fijados en este documento (§ huecos).**
4. **Estado de MTEB**: si sigue siendo la referencia, si hay sucesor consolidado, y el alcance de la
   contaminación/saturación. A ago-2026 sigue siendo la referencia de facto **con contaminación
   documentada**, y MTEB v2 no es comparable con v1.
5. **Rerankers disponibles y su licencia**: familias BGE y mixedbread (Apache-2.0), Jina
   (pesos CC-BY-NC → uso comercial vía API), Cohere y Voyage (API cerrada). **Verifica la licencia y
   la versión vigente antes de desplegar — las versiones exactas no se fijan aquí.**
6. **RAGAS y frameworks de evaluación de RAG**: RAGAS 0.4.3 es de enero de 2026 y no había publicado
   nada nuevo a agosto de 2026. **Comprueba si sigue mantenido** antes de depender de él (detalle en
   `llm-evaluation-standards`).
7. **Frameworks de ingesta**: LlamaIndex (0.14.x), Haystack (**3.0.0**, jul-2026 — major con
   ruptura), LangChain/LangGraph 1.x. Descarta lo abandonado.
8. **OWASP Top 10 for LLM Applications**: confirmar si sigue vigente la edición **2025** (`LLM08`
   *Vector and Embedding Weaknesses*) o si salió revisión.
9. **Incidentes de cadena de suministro** en lo que recomiendes: precedentes en el catálogo — Trivy
   (marzo 2026), LiteLLM `1.82.7`/`1.82.8` en PyPI (marzo 2026), `gitleaks` (*feature complete*).
10. **Contexto largo frente a RAG**: los umbrales de degradación por longitud (*context rot*, *lost
    in the middle*) y las cifras de coste relativo cambian con cada generación de modelos.

**Huecos declarados — NO rellenar de memoria**:

- **Nombres y versiones exactas de modelos de embedding**: no fijados. Las fuentes públicas
  consultadas se contradicen entre sí en nombres y numeración de versión, y el ciclo es mensual.
  Se verifican con la documentación del proveedor en cada uso.
- **Versiones exactas de rerankers comerciales**: no fijadas por el mismo motivo. Las **licencias**
  sí están verificadas por familia y son el dato que decide.
- **Precios de embeddings, rerankers y generación**: no fijados en este documento.
- **Valores numéricos concretos de `m`, `ef_construction`, `ef_search`, `lists`, `probes`, tamaño de
  chunk y solape**: **deliberadamente no fijados.** Dependen del corpus, del modelo y del hardware;
  cualquier cifra concreta sería un valor por defecto de tutorial disfrazado de criterio. Se
  determinan midiendo (§2.3, §3.2).
- **Multiplicadores de coste/latencia de GraphRAG y RAG agéntico**: las cifras públicas proceden en
  su mayoría de blogs de proveedor sin condiciones reproducibles. **No se citan como hechos.**
- **Umbral de volumen exacto** en el que pgvector deja de ser suficiente: la horquilla de "decenas
  de millones de vectores" es orientativa y depende de dimensionalidad, filtrado y hardware.
  Mídelo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
