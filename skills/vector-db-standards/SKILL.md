---
name: vector-db-standards
description: Operating a vector search engine as a piece of infrastructure. Use when sizing RAM and disk for an ANN index, choosing binary, scalar, product or rotational/RaBitQ-style vector compression, diagnosing a selective pre-filter or post-filter that collapses recall or latency, collection snapshots and restoring an index, index build and rebuild time, cold start after restart, replication factor, shards and horizontal partitioning of collections, tombstones and graph degradation after deletes, per-collection versus per-filter tenant isolation, securing engines that ship open (Qdrant service.api_key, AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED, Milvus authorizationEnabled and the default root password, ports 6333/6334, 19530, 8080, 8000), embedding inversion as a privacy risk, or non-RAG similarity workloads such as recommendation, deduplication and record linkage, image or audio search, anomaly detection and clustering.
---

# Estándares de bases de datos vectoriales (el motor como infraestructura)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando hay que **desplegar, operar, dimensionar, respaldar, escalar, asegurar o pagar** un
motor de búsqueda vectorial: la decisión de si hace falta un motor dedicado, el compromiso
recall/latencia/memoria como decisión explícita, el coste en RAM y en tiempo de construcción de cada
familia de índice, el filtrado previo/posterior, la persistencia y el respaldo del índice, la
reconstrucción, el borrado y la degradación del grafo, réplicas y particionado, multi-tenancy, y los
usos de la similitud vectorial **que no son RAG**.

Triggers: "¿me hace falta una base vectorial?", "no cabe en memoria", "cuánta RAM necesita el
índice", "cuantización binaria/escalar/producto", "comprimir vectores", "snapshot de la colección",
"restaurar un índice", "cuánto tarda en reconstruirse", "arranque en frío", "el motor tarda en
levantar", "factor de replicación", "sharding de colecciones", "borrado y compactación",
"tombstones", "el recall cayó al añadir un filtro", "el filtro me devuelve menos resultados de los
que pido", "aislamiento por colección o por filtro", "un tenant por colección", "endpoint sin
autenticación", `service.api_key`, `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED`,
`authorizationEnabled`, puertos `6333`/`6334`, `19530`, `8080`, `8000`, "inversión de embeddings",
"deduplicación", "record linkage", "búsqueda por imagen", "detección de anomalías", "clustering",
"recomendación por similitud".

**Tesis del dominio**: *un motor vectorial es una base de datos que vive en RAM y responde con
aproximaciones.* Las dos mitades de esa frase son las que deciden todo lo demás: **la memoria es el
recurso dominante y el coste real**, y **el recall no es un hecho, es un parámetro que has elegido —
consciente o inconscientemente**.

**Regla de arbitraje con `rag-standards` (léela antes de escribir nada en este dominio)**: si la
pregunta cambia **qué se recupera**, es de `rag-standards`; si cambia **quién opera, paga, respalda o
restaura el motor**, es de aquí. Corolario operativo: subir `ef_search` para mejorar el recall de un
RAG es de `rag-standards`; el nodo que se queda sin RAM construyendo ese índice, o el restore que
tarda seis horas, es de aquí.

**No aplica**:

- **`rag-standards`** — **la frontera crítica**. Es **el patrón de recuperación para alimentar a un
  LLM**: chunking, elección y ciclo de vida del modelo de embedding y su coste de reindexado,
  elección entre pgvector y motor dedicado **desde la perspectiva de la calidad de recuperación**,
  **parámetros de tuning de HNSW e IVFFlat** (`m`, `ef_construction`, `ef_search`, `lists`,
  `probes`), recuperación híbrida densa + BM25 con **fusión RRF**, reranking con cross-encoder,
  filtrado por metadatos como técnica de recuperación, métricas `recall@k`/`MRR`/`nDCG`, y control
  de acceso por documento en la recuperación. **Nada de eso se repite aquí**: cuando esta skill
  necesita esos conceptos, los enlaza. Aquí el motor como pieza de infraestructura y los usos que no
  son RAG.
- `data-platform-standards` — **skill madre**: el motor PostgreSQL (modelado, migraciones, réplicas,
  PITR, tuning, RLS, JSONB, full-text) y el principio rector **"un almacén por necesidad, no por
  moda"**, que esta skill hereda entero. **Arbitraje de `pgvector` a tres bandas**: la extensión y
  sus parámetros de índice son de `rag-standards`; **el PostgreSQL que la aloja, su respaldo, su HA y
  su parcheo son de `data-platform-standards`**; el criterio de **cuándo pgvector deja de servir y
  qué cuesta operar la pieza dedicada que lo sustituye** es de aquí (§2.2).
- `search-engines-standards` — motores de texto (Elasticsearch/OpenSearch, Meilisearch, Typesense,
  Vespa, Solr), modelado del índice invertido, relevancia BM25, ciclo de vida del índice y operación
  del cluster. **Varios de ellos también hacen búsqueda vectorial**: si el motor ya está desplegado
  por su capacidad léxica, el criterio de operarlo es suyo; si se despliega **por** los vectores, es
  de aquí. **La búsqueda híbrida cruza las tres skills: el criterio de fusión vive en
  `rag-standards` (RRF) para el caso RAG y en `search-engines-standards` para la implementación
  dentro del motor de texto. Aquí no se decide fusión.**
- `nosql-standards`, `graph-db-standards`, `timeseries-db-standards`, `data-warehouse-modeling-standards`,
  `lakehouse-standards`, `streaming-cdc-standards`, `data-governance-quality-standards`,
  `analytics-bi-standards`, `caching-cdn-standards`, `message-brokers-standards`,
  `oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`
  (**Ola 4, planificadas**): sus motores.
- `data-engineering-standards`: el pipeline que alimenta el índice (orquestación, backfill
  idempotente, watermarks). Aquí solo el destino y su coste de escritura.
- `privacy-engineering-standards`: dato personal, minimización, DPIA, derecho de supresión.
  **Un embedding de un dato personal es un dato personal** (§5.3): aquí el riesgo técnico de la
  inversión y la mecánica del borrado en el motor, allí el derecho y su alcance.
- `llm-app-engineering-standards`, `mlops-standards`, `local-inference-standards`: el modelo que
  produce los vectores, su servicio y su ciclo de vida. Aquí solo lo que su salida cuesta almacenar.
- `object-storage-standards`: S3/MinIO/Ceph como destino de snapshots y como capa de datos de los
  motores que separan cómputo de almacenamiento.
- `backup-recovery-standards` (mecánica del respaldo, restore probado, repositorios inmutables) y
  `bcdr-standards` (RTO/RPO derivados del negocio). Aquí solo **qué tiene de particular respaldar un
  índice ANN**.
- `kubernetes-standards` (StatefulSets, PVC, operadores), `linux-storage-standards` (el bloque bajo
  el motor), `iac-standards`, `cicd-standards`, `sre-practice-standards` (SLO, capacity planning).
- `identity-access-management-standards` (el modelo de autorización), `secrets-management-standards`
  (la API key del motor), `cryptography-pki-standards` (TLS), `firewall-policy-standards` (exponer o
  no el puerto — §5.1), `networking-standards`, `vulnerability-management-standards` (CVE y EOL),
  `grc-compliance-standards`.
- `aws-standards` / `azure-standards` / `gcp-standards`: equivalentes gestionados. El criterio de
  dimensionado y de filtrado aplica igual; la factura y el modelo de servicio son suyos.
- Skills de lenguaje (`python-standards`, `typescript-standards`, `go-standards`, …): los clientes.

## 2. Decisiones por defecto

> Verificar versión, licencia y estado por web antes de fijar nada (§8). Sector con **cambios de
> licencia y adquisiciones frecuentes**; lo verificado aquí es de agosto de 2026.

### 2.1 ¿Para qué es realmente esto? Los usos que no son RAG

RAG se ha comido la conversación, pero la búsqueda por similitud es anterior y más amplia. Cada uso
tiene un perfil operativo distinto, y **el perfil decide el motor mucho más que la moda**:

| Uso | Perfil de carga | Lo que decide el diseño |
|---|---|---|
| **Recomendación** ("parecidos a esto", *related items*) | Lecturas muy altas, índice relativamente estable, latencia dura (está en el camino de renderizado) | Réplicas de lectura y caché. El recall importa menos que el p99 |
| **Deduplicación y *record linkage*** | Cargas por lotes, umbral de similitud, muchísimas consultas contra el propio corpus | **No es un problema de top-k, es de umbral.** El resultado se revisa: la salida vectorial es *candidatos*, no decisión. Bloqueo por similitud + verificación determinista después |
| **Búsqueda por imagen / audio / vídeo** | Vectores de dimensionalidad alta, corpus enorme, escritura por lotes | La memoria es el problema desde el primer día. Cuantización obligatoria, casi siempre |
| **Detección de anomalías** | Consulta la distancia al vecino más cercano, no la lista | El *drift* del corpus mueve el umbral: reevaluación periódica o alertas que se apagan solas |
| **Agrupamiento / exploración de corpus** | Lotes offline, sin SLA de latencia | Casi nunca necesita un motor en línea: una biblioteca ANN en un proceso batch basta |
| **RAG** | Ver `rag-standards` | — |

**Criterio**: si el uso es **offline y por lotes**, una biblioteca ANN en proceso (FAISS, `usearch`,
`hnswlib`) o un fichero columnar tipo Lance resuelve sin operar un servicio. **Un servicio se
justifica por concurrencia, actualización en línea y multi-cliente, no por tener vectores.**

### 2.2 ¿Motor dedicado o pgvector? — la pregunta honesta

Heredado de `data-platform-standards`: **un almacén por necesidad, no por moda.**

| Situación | Decisión |
|---|---|
| Ya operas PostgreSQL, volumen moderado, filtrado por metadatos relacional | **`pgvector`.** Backup, PITR, HA, autenticación, RLS, transaccionalidad y monitorización **ya están resueltos y pagados**. Añadir un motor dedicado es añadir una pieza de operación entera |
| El índice no cabe en la RAM del PostgreSQL sin ahogar al OLTP | Motor dedicado, **o** instancia PostgreSQL separada solo para vectores (opción intermedia que casi nadie considera) |
| Necesitas cuantización avanzada, filtrado con payload complejo, o escala horizontal del índice | Motor dedicado |
| Corpus de cientos de millones o miles de millones de vectores | Motor dedicado con particionado |
| "Es lo que se usa para IA" | **No es un criterio.** Exige ADR |

**El umbral exacto no se cita, se mide.** Depende de dimensionalidad, cuantización, selectividad de
los filtros, RAM disponible y latencia objetivo — cualquier cifra concreta que leas es el
experimento de otro. **Método**: carga una muestra representativa (≥10 % del corpus objetivo),
construye el índice, mide RAM residente, latencia p95 con filtros reales y tiempo de construcción, y
**extrapola linealmente en número de vectores** (la memoria del índice escala así; la latencia, mejor
que linealmente). Si la extrapolación no cabe en el presupuesto, tienes tu respuesta y tienes el ADR.

### 2.3 Motores — estado verificado (agosto 2026)

| Motor | Versión | Licencia | Criterio operativo |
|---|---|---|---|
| **pgvector** | **0.8.6** (jul-2026) | **PostgreSQL** (verbatim: *"Permission to use, copy, modify, and distribute this software…"*) | Default. Operas PostgreSQL, no un motor nuevo |
| **Qdrant** | **1.18.3** (jul-2026) | **Apache-2.0** | Default de motor dedicado: filtrado con payload bueno, operación simple, licencia limpia, cuantización rica (§2.5) |
| **Weaviate** | **1.38.8**; **1.39.0-rc.1** (ago-2026) | **BSD-3-Clause** (core, verificado en el `LICENSE` del repo) | Módulos integrados. ⚠️ **Acceso anónimo activado por defecto** (§5.1) |
| **Milvus** | **3.0.0** (jul-2026) y serie **2.6.22** | **Apache-2.0** | Escala masiva a cambio de complejidad operativa alta (varios componentes + etcd + object storage). **Major reciente: no adoptar 3.x sin leer la guía de migración** |
| **Chroma** | tag `Latest` (jul-2026); última numerada **1.5.9** (may-2026) | **Apache-2.0** | Prototipado. **No producción seria** (criterio heredado de `rag-standards`) |
| **LanceDB** | **0.36/0.37.x** (jul-2026) | **Apache-2.0** | Formato columnar sobre object storage. Encaje analítico y por lotes; **almacenamiento barato en lugar de RAM cara** es su propuesta real |

**Vetado sin ADR**: adoptar un motor dedicado teniendo PostgreSQL y volumen moderado; desplegar un
motor cuya licencia no hayas leído este trimestre.

### 2.4 Familias de índice — lo que decide un despliegue

Los parámetros de tuning y su efecto sobre el recall son de `rag-standards` §2.3. **Aquí solo lo que
paga infraestructura: memoria y tiempo de construcción.**

| Familia | Memoria | Construcción | Actualización / borrado | Cuándo |
|---|---|---|---|---|
| **Exacta (fuerza bruta)** | Solo los vectores | Ninguna | Trivial | Corpus pequeño, o **como referencia para medir el recall del índice aproximado**. Recall = 1 por definición |
| **Grafo (HNSW y variantes)** | **Alta**: vectores **+ el grafo de enlaces**, y el grafo no es despreciable | Lenta, y crece más que linealmente | Inserción barata; **el borrado degrada el grafo** (§6.3) | Default cuando la latencia manda y la RAM alcanza |
| **IVF (particionado por centroides)** | Menor que grafo | **Requiere entrenamiento sobre datos representativos ya cargados** | Reentrenar cuando la distribución cambia | Cuando la memoria es la restricción y aceptas peor recall |
| **Con cuantización** (§2.5) | **La palanca principal**: divide la memoria por un factor grande | Añade una fase de entrenamiento en PQ; escalar y binaria son baratas | Igual que la familia base | Cuando el índice no cabe, que es casi siempre a partir de cierto tamaño |
| **En disco / híbrido** | Baja RAM, alta E/S | Media | Media | Corpus enorme con latencia tolerante. **Exige NVMe: sobre almacenamiento de red se derrumba** |

**Reglas de dimensionado que se olvidan siempre**:

1. **Presupuesta RAM para dos índices, no para uno**: reconstruir sin caída exige que el nuevo
   coexista con el viejo. Si el nodo solo aguanta uno, no tienes camino de reconstrucción en caliente.
2. **El tiempo de construcción es una ventana de indisponibilidad o de coste doble.** Mídelo antes de
   comprometer un SLA de frescura.
3. **La dimensionalidad se paga linealmente en todo**: almacenamiento, memoria de índice, ancho de
   banda y latencia de comparación. Reducirla (Matryoshka, PQ) suele ser la optimización de coste más
   rentable — la elección del modelo y su dimensión es de `rag-standards` §2.4.

### 2.5 Cuantización — la palanca de coste

Verificado a ago-2026, **por motor** (§8):

| Motor | Métodos | Nota |
|---|---|---|
| **Qdrant** | **TurboQuant** (hasta 32×), **escalar** (4×), **binaria** (hasta 32×), **producto** (hasta 64×) | La doc oficial recomienda TurboQuant de 4 bits sobre escalar salvo con distancia Manhattan (L1) |
| **Weaviate** | **RQ (rotacional, recomendada por la doc)**, **PQ**, **BQ**, **SQ**, o ninguna | La doc menciona compresión por defecto a partir de cierta versión: **verifica cuál aplica a la tuya** |
| **Milvus** | SQ, PQ, binaria y variantes | Verificar por versión: 3.x cambió cosas |
| **pgvector** | `halfvec` (media precisión) y cuantización binaria por índice de expresión | Menos rica que la de los dedicados; suele bastar |

**Reglas duras**:

- **La cuantización es aproximación sobre aproximación.** Un índice ANN ya cuesta recall; comprimir
  cuesta más. **Mide el recall antes y después contra fuerza bruta** (método en `rag-standards` §2.3)
  — jamás la actives "por eficiencia" sin la medida.
- **El *rescoring* con vectores completos es lo que hace usable la cuantización agresiva**: buscar
  comprimido, reordenar los candidatos con precisión completa. Si tu motor lo soporta, actívalo; si
  no lo soporta, la binaria agresiva suele ser inaceptable.
- **Los factores de compresión son de la documentación del motor; el impacto en recall es de tu
  corpus.** Los números de recall que publican los proveedores se miden sobre datasets académicos con
  distribuciones benignas. No son tu corpus.

## 3. El problema del filtrado — la sección que evita el incidente

**Es el fallo de producción más común de este dominio** y casi nunca se ve venir, porque **no da
error**: en desarrollo, con 10.000 vectores y sin filtros, todo va bien; en producción, con filtros
selectivos, el sistema devuelve resultados peores o tarda un orden de magnitud más.

El índice ANN está construido sobre **todo** el espacio de vectores. Un filtro por metadatos
(tenant, fecha, idioma, permisos, categoría) rompe esa premisa. Hay tres estrategias y las tres
fallan de forma distinta:

| Estrategia | Qué hace | Cómo falla |
|---|---|---|
| **Post-filtrado** | Busca en el índice, filtra después | **Devuelve menos de `k`, o nada.** Pides 10, el índice devuelve 10 candidatos globales, el filtro descarta 9 → te quedas con 1. Con filtros muy selectivos, cero resultados y silencio |
| **Pre-filtrado ingenuo** | Selecciona por el filtro, luego busca exacto sobre el subconjunto | Correcto pero **puede degradar a escaneo completo** si el subconjunto es grande. La latencia se dispara |
| **Filtrado durante el recorrido** (*filterable HNSW*, *iterative scan*, índices por payload) | El recorrido del grafo aplica el filtro mientras navega | Lo correcto, pero **el grafo puede desconectarse**: si los nodos que pasan el filtro no son alcanzables entre sí, el recall cae en silencio |

**Criterio**:

1. **Conoce cuál de las tres implementa tu motor y bajo qué condiciones cambia de una a otra.**
   Muchos motores tienen heurísticas por selectividad estimada: por debajo de un umbral hacen una
   cosa, por encima otra. Ese umbral es configurable y casi nadie lo toca.
2. **Mide el recall *con el filtro aplicado*, no sin él.** Un recall del 98 % sin filtro y del 40 %
   con `tenant_id = X` es un sistema roto que pasa todas las pruebas.
3. **Indexa los campos de filtro.** Un filtro sin índice de payload obliga al motor a evaluar
   condición por condición durante el recorrido.
4. **Filtros ultraselectivos (un tenant pequeño, un usuario concreto) casi siempre se resuelven mejor
   con búsqueda exacta sobre el subconjunto** que con ANN. Si el motor no lo decide solo, decídelo tú.
5. **Un filtro cuya selectividad varía mucho entre tenants es una bomba de latencia**: el p99 lo
   marcará el tenant peor. Mide por tenant, no en agregado.

**El filtrado por metadatos *como técnica de recuperación en RAG* es de `rag-standards`.** Aquí su
consecuencia sobre el índice, la latencia y el recall.

## 4. Calidad y gates

| # | Gate | Rompe si |
|---|---|---|
| 1 | **Recall del índice medido contra fuerza bruta** sobre una muestra, con umbral de no-regresión | Cae bajo umbral |
| 2 | **Recall medido *con los filtros de producción aplicados*** (§3), no solo sin filtro | Cae bajo umbral |
| 3 | **Cambio de cuantización, de familia de índice o de dimensionalidad ⇒ medición de recall obligatoria** en el diff | Falta la medición |
| 4 | **Restore probado**: snapshot restaurado en entorno limpio y consultado, con tiempo registrado | No se restaura, o no se mide el tiempo |
| 5 | **Presupuesto de memoria declarado** (RAM del índice extrapolada al volumen objetivo) y alerta antes de agotarlo | No existe |
| 6 | **Autenticación y TLS activados en todo entorno alcanzable por red**, verificado por prueba automática que hace una petición **sin credenciales** y espera `401`/`403` | Responde `200` |
| 7 | **Aislamiento entre tenants**: prueba que un tenant no recupera vectores de otro (§5.2) | Fuga. **Innegociable** |
| 8 | **Borrado propagado**: eliminado un registro, no vuelve a aparecer en resultados tras la compactación | Sobrevive |
| 9 | Reconstrucción del índice ensayada y **cronometrada** al menos una vez por trimestre | No ensayada |
| 10 | SCA y CVEs del motor y sus clientes (§5.4) | Crítica sin mitigar |

**El gate 6 es el que más veces salva.** Un motor vectorial con un `curl` anónimo que devuelve `200`
es una fuga de datos, no una incidencia de configuración.

## 5. Seguridad

### 5.1 Estos motores vienen abiertos — verificado por motor

**El dato de seguridad más valioso de esta skill.** Verificado en la documentación oficial a ago-2026:

| Motor | Estado por defecto | Cita / evidencia |
|---|---|---|
| **Qdrant** (OSS autoalojado) | **Sin autenticación** | Doc oficial, verbatim: *"By default, all self-deployed Qdrant instances are not secure."* y *"By default, an open source Qdrant deployment accepts requests from anyone who can reach it."* Se cierra con `service.api_key` (y claves de solo lectura / granulares). En Qdrant Cloud sí está activada por defecto |
| **Weaviate** | **Acceso anónimo activado** | Referencia de variables de entorno, verbatim: `AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED` … *"Defaults to true"*. Hay que ponerlo a `false` y habilitar API key u OIDC explícitamente |
| **Milvus** | **Autenticación desactivada**, y con **contraseña por defecto conocida** | Doc oficial, verbatim: *"By default, the `root` user is created with the password `Milvus` when Milvus is initiated."* Se activa con `common.security.authorizationEnabled` |
| **Chroma** | Sin autenticación en el arranque estándar | Puerto `8000`. Configuración de auth explícita y opcional |
| **pgvector** | **Hereda la autenticación de PostgreSQL** | **Es su mayor ventaja de seguridad y casi nadie la cuenta**: `pg_hba.conf`, roles, TLS, RLS y auditoría ya existen y ya se revisan |
| **LanceDB** (embebido) | No hay servicio que autenticar | El control es el del almacenamiento (IAM de S3/objeto). **Si el bucket está abierto, el índice está abierto** |

**Reglas**:

- **Ningún motor vectorial se expone a Internet. Nunca.** No hay caso de uso legítimo para un puerto
  `6333`, `19530`, `8080` o `8000` de un motor vectorial accesible desde fuera. Red privada, y regla
  de firewall por defecto-denegar (`firewall-policy-standards`).
- **Investigación pública (Orca Security, may-2026)** documenta instancias expuestas enumerables sin
  autenticación en esos puertos por defecto, con corpus enteros —tickets, bases de conocimiento,
  conversaciones— accesibles. **La cifra exacta de instancias no se fija aquí** (§8): lo que decide
  es que el patrón está confirmado y automatizado.
- **La API key es un secreto**: `secrets-management-standards`. No en `docker-compose.yml`, no en el
  chart, no en la imagen.
- **TLS obligatorio** también dentro del perímetro (`cryptography-pki-standards`): los vectores y los
  payloads viajan en claro si no.
- **El endpoint de métricas y el panel web también se exponen.** Cuéntalos al abrir puertos.

### 5.2 Multi-tenancy: aislamiento por colección frente a aislamiento por filtro

| Modelo | Aislamiento | Coste | Efecto en recall |
|---|---|---|---|
| **Colección (o índice) por tenant** | **Fuerte**: un límite, no una condición. Borrar un tenant es borrar una colección | Alto con muchos tenants: cada colección tiene sobrecarga fija de índice y memoria. Miles de tenants pequeños no escalan así | **Mejor**: el índice contiene solo lo del tenant, sin filtro que degrade el recorrido |
| **Filtro `tenant_id` en colección compartida** | **Débil**: depende de que **cada** consulta lleve el filtro. Un camino que lo olvida es una fuga | Bajo y uniforme | **Peor y variable**: es exactamente el problema de §3, y el p99 lo marca el tenant grande |
| **Híbrido** (colección por tenant grande, compartida para la cola larga) | Fuerte donde importa | Medio | Aceptable, a costa de dos rutas de código |

**Criterio**: **si el aislamiento es un requisito regulatorio o contractual, colección separada.** Un
filtro es una condición que un `if` puede saltarse; una colección es un límite. Si eliges filtro,
el filtro se inyecta **en una capa que la aplicación no puede rodear**, y el gate 7 de §4 lo prueba
en CI. El control de acceso **por documento** dentro de un RAG es de `rag-standards` §5.1.

### 5.3 Inversión de embeddings — el riesgo de privacidad específico

**Un embedding no es un hash ni una anonimización.** Existen ataques de inversión que reconstruyen
total o parcialmente el texto original a partir del vector, y ataques de inferencia de pertenencia
que revelan si un documento estaba en el corpus.

Consecuencias operativas, no teóricas:

- **Un vector derivado de un dato personal es un dato personal**: entra en el registro de
  tratamiento, en la clasificación, en la retención y en el derecho de supresión
  (`privacy-engineering-standards`).
- **No exportes vectores a terceros ni a entornos de menor confianza "porque son solo números".** Un
  volcado de embeddings es un volcado de contenido.
- **El borrado del origen sin borrado del vector no es borrado** (§6.3).
- Minimiza antes de vectorizar: lo que no entra al corpus no puede reconstruirse.

### 5.4 Superficie de ataque y cadena de suministro

- **El motor entra en el ciclo de parcheo como cualquier otra base de datos.** Precedentes
  verificados: **Milvus CVE-2025-64513**, *bypass* completo de autenticación en el componente Proxy
  explotable **sin autenticar**, con acceso administrativo total; corregido en 2.4.24 / 2.5.21 /
  2.6.5. **pgvector 0.8.2 (feb-2026) corrigió CVE-2026-3172** (construcción paralela de índices
  HNSW).
- Riesgo indirecto por integraciones: **CVE-2026-24477** filtraba la API key de Qdrant en claro a
  usuarios no autenticados a través de un endpoint de AnythingLLM. **La clave de tu motor la puede
  filtrar cualquier pieza que la use.**
- Fija imagen por **digest**, no por tag; SBOM y firma (`cicd-standards`,
  `vulnerability-management-standards`).

## 6. Operación

### 6.1 Persistencia y durabilidad — verifícalo, no lo asumas

Varios de estos motores nacieron **solo en memoria** o con persistencia opcional y añadieron
durabilidad después. **Antes de poner datos que no puedas regenerar, responde por escrito**:

1. ¿Qué se persiste: los vectores, el índice, o ambos? Muchos motores persisten los vectores y
   **reconstruyen el índice al arrancar** — eso es el arranque en frío (§6.5).
2. ¿Hay *write-ahead log*? ¿Qué se pierde en un `SIGKILL`?
3. ¿La escritura es *fsync* síncrono o diferido? ¿Configurable?
4. ¿Qué garantía de consistencia hay entre réplicas, y qué ves durante un fallo de nodo?

**Regla de oro que ahorra la mitad de estas preguntas: el índice vectorial es una proyección
derivada, no la fuente de verdad.** El texto original, los metadatos y —si puedes pagarlo— los
vectores viven en un almacén durable (PostgreSQL, object storage). Así, **el peor caso del motor
vectorial es reindexar, no perder datos.** Diseña para eso desde el día uno y la mitad de este
apartado deja de ser crítica.

### 6.2 Respaldo y restauración

- **Un snapshot de un índice ANN no es un `pg_dump`.** Suele ser una copia consistente de segmentos
  binarios acoplada a la **versión del motor**: restaurarlo en una versión distinta puede fallar o
  degradar en silencio. **Anota la versión con el snapshot.**
- **Un snapshot de disco tomado en caliente sin coordinar con el motor puede ser inconsistente.**
  Usa el mecanismo de snapshot del propio motor, o congela la escritura (`fsfreeze` y hooks:
  `backup-recovery-standards`).
- **El coste real del respaldo es el restore, y el restore de un índice grande incluye cargarlo a
  memoria.** Cronométralo (§4, gate 4) y compáralo con el RTO comprometido (`bcdr-standards`). Es
  frecuente que **reindexar desde la fuente de verdad sea más rápido que restaurar** — si es tu caso,
  ese es tu procedimiento de recuperación y hay que escribirlo.
- Destino: object storage con versionado e inmutabilidad (`object-storage-standards`), cifrado en
  cliente.

### 6.3 Actualizaciones, borrados y compactación

- **Los índices de grafo se degradan con el borrado.** El patrón habitual es marcar (*tombstone*) y
  compactar después: entre ambas cosas, el índice ocupa memoria por vectores que ya no existen y el
  recorrido pasa por nodos muertos. **Recall y latencia empeoran con el tiempo en un corpus con
  rotación alta.**
- **La compactación es E/S y CPU intensiva**: prográmala, obsérvala y ten en cuenta su pico. Un
  corpus muy volátil puede necesitar **reconstrucción periódica**, no solo compactación.
- **Actualizar un vector = borrar + insertar** en casi todos los motores. Reindexar el mismo
  documento repetidamente infla el índice aunque el número lógico de registros no cambie. Vigila
  **vectores lógicos frente a vectores físicos**: si divergen mucho, toca compactar o reconstruir.
- **En IVF, la distribución cambia y los centroides envejecen**: el recall cae aunque nada falle.
  Reentrenar es una operación planificada.
- **Borrado y derecho de supresión**: el borrado debe llegar al vector, al índice, a las réplicas, a
  los snapshots vigentes y a cualquier caché. Un `deleted=true` que un filtro puede olvidar **no es
  un borrado** (`privacy-engineering-standards`; mecánica en RAG: `rag-standards` §6.2).

### 6.4 Escala

- **Réplicas de lectura** son la palanca fácil: la carga de estos sistemas suele ser abrumadoramente
  de lectura. Cuestan **memoria completa por réplica** — el índice no se comparte.
- **Particionado (sharding)**: reparte el corpus. Cada consulta va a **todos** los shards y se
  fusiona, así que **el p99 lo marca el shard más lento** y añadir shards no reduce la latencia, solo
  la memoria por nodo. **Particiona por memoria, no por latencia.**
- **Particionar por una clave de negocio (tenant, idioma, fecha)** es mejor que particionar al azar
  **si las consultas llevan esa clave**: entonces la consulta toca un shard y sí mejora la latencia.
  Es la decisión de diseño con más retorno de esta sección.
- **Cuando el índice deja de caber en memoria** hay exactamente cuatro salidas, en orden de coste
  creciente: **(1)** cuantizar (§2.5), **(2)** reducir dimensionalidad, **(3)** índice en disco sobre
  NVMe, **(4)** particionar horizontalmente. Comprar RAM es la quinta y no siempre la peor.
- **Rebalanceo**: mover un shard es mover gigabytes y reconstruir índice. Pregunta **antes** de
  desplegar cuánto tarda y si se puede hacer sin caída.

### 6.5 Arranque en frío

**El tiempo de arranque de un motor vectorial no es el de un proceso, es el de cargar decenas o
cientos de GB a memoria** (o reconstruir el índice, según §6.1). Consecuencias que rompen despliegues:

- Sondas de *liveness*/*readiness* con umbrales de servicio web **matan el pod en bucle**
  (`kubernetes-standards`): ajusta `startupProbe`.
- Un reinicio rodante de N réplicas cuesta N × tiempo de arranque, con capacidad reducida mientras.
- **Autoescalado reactivo no funciona** con este perfil: cuando la réplica nueva está lista, el pico
  pasó. Sobreaprovisiona o escala por señal anticipada.
- Mídelo y ponlo en el runbook. Es el número que nadie tiene cuando hace falta.

### 6.6 Coste y observabilidad

**La memoria es el coste dominante**, y sube por tres vías que se multiplican: número de vectores ×
dimensionalidad × réplicas. Las palancas, por rentabilidad: **cuantización → dimensionalidad →
número de réplicas → índice en disco**.

Instrumenta (`observability-standards` lleva el transporte y el backend):

- **RAM residente del proceso frente a RAM del nodo** — la métrica que predice la caída.
- Latencia p50/p95/p99 **por colección y por tenant**, no en agregado.
- **Vectores lógicos frente a físicos** (deuda de compactación).
- Tasa de escritura, retraso de indexación, duración de la compactación.
- **Recall medido periódicamente contra fuerza bruta sobre una muestra**: es la única alarma que
  detecta la degradación silenciosa. **Sin ella, un índice que empeora no genera ninguna señal.**
- Tiempo de arranque en frío y de construcción del índice, como series históricas.

### 6.7 Runbook mínimo

Índice que no cabe en memoria (OOM del nodo); latencia disparada tras añadir un filtro; recall que
cae sin cambios de código (compactación pendiente, centroides envejecidos, deriva del corpus);
snapshot que no restaura en la versión actual; nodo que no termina de arrancar; tenant que ve datos
de otro (**incidente de seguridad**, no bug: `incident-management-standards`,
`incident-response-forensics-standards`); motor descubierto expuesto sin autenticación (asume
compromiso y trata el corpus como filtrado).

## 7. Sostenibilidad y prohibiciones

**Cadencia de revisión: 3 meses.** Versiones, licencias, métodos de cuantización y CVEs se mueven
trimestralmente en este sector.

- Revisar: versión y CVEs del motor, **licencia** (patrón frecuente de cambio), soporte de
  cuantización nuevo (aparecen métodos con mejor compromiso cada pocos meses), y si el presupuesto de
  memoria sigue casando con el crecimiento real del corpus.
- **Actualizar el motor puede exigir reconstruir el índice o invalidar snapshots.** Léelo en las
  notas de versión antes, no durante.
- Deuda consciente registrada: recall sin medir, restore sin probar, compactación pendiente,
  autenticación pospuesta ("solo está en la red interna").

**PROHIBIDO**

- ❌ Desplegar un motor vectorial dedicado teniendo PostgreSQL y volumen moderado, sin ADR.
- ❌ Desplegar un servicio para un uso **offline por lotes** que resolvería una biblioteca ANN en proceso.
- ❌ **Exponer el puerto del motor a Internet.** Bajo ninguna circunstancia.
- ❌ **Arrancar en cualquier entorno alcanzable por red sin autenticación ni TLS** (§5.1). "Está en la
  red interna" no es un control.
- ❌ Dejar la contraseña por defecto de Milvus (`root`/`Milvus`) o cualquier credencial de demo.
- ❌ Poner la API key del motor en el `docker-compose.yml`, el chart o la imagen.
- ❌ **Fijar parámetros de índice o activar cuantización sin medir el recall contra fuerza bruta.**
- ❌ **Medir el recall sin los filtros de producción aplicados** y dar el sistema por bueno.
- ❌ Confiar en el post-filtrado con filtros selectivos y no notar que devuelves menos de `k`.
- ❌ Filtrar por un campo sin índice de payload.
- ❌ Dimensionar la RAM para un solo índice y quedarse sin camino de reconstrucción en caliente.
- ❌ Tratar el índice vectorial como fuente de verdad, sin origen durable del que reindexar.
- ❌ Snapshot sin restore probado y **sin cronometrar**; snapshot sin anotar la versión del motor.
- ❌ Copiar el disco en caliente sin usar el mecanismo de snapshot del motor ni congelar la escritura.
- ❌ Ignorar la degradación del grafo por borrado en corpus con rotación alta.
- ❌ Borrado lógico como respuesta a un derecho de supresión.
- ❌ **Tratar un embedding como anonimización**, o exportarlo a un entorno de menor confianza.
- ❌ Multi-tenancy por filtro cuando el aislamiento es requisito regulatorio, o sin prueba de
  aislamiento en CI.
- ❌ Sondas de arranque con umbrales de servicio web sobre un motor que carga GB a memoria.
- ❌ Autoescalado reactivo como plan de capacidad de un motor con arranque en frío largo.
- ❌ Chroma en producción seria; adoptar Milvus 3.x sin leer la guía de migración.
- ❌ Duplicar aquí criterio de `rag-standards` (chunking, embeddings, tuning ANN, híbrido, RRF,
  reranking, `recall@k`) en vez de enlazarlo.
- ❌ Fijar de memoria una versión, una licencia, un factor de compresión o una cifra de recall (§8).

## 8. Verificación web obligatoria

1. **Versión y licencia de cada motor**: pgvector, Qdrant, Weaviate, Milvus, Chroma, LanceDB.
   Verificado a ago-2026 vía feeds Atom de releases y ficheros `LICENSE` del repositorio (no vía
   resúmenes de páginas HTML, que **inventan fechas**): pgvector 0.8.6 / licencia PostgreSQL;
   Qdrant 1.18.3 / Apache-2.0; Weaviate 1.38.8 y 1.39.0-rc.1 / **BSD-3-Clause confirmado en el
   `LICENSE` del core**; Milvus **3.0.0** y 2.6.22 / Apache-2.0; Chroma / Apache-2.0; LanceDB
   0.36-0.37.x / Apache-2.0. **Reverifica: el cambio de licencia es el patrón del sector.**
2. **CVEs**: Milvus **CVE-2025-64513** (bypass de auth sin autenticar, corregido en 2.4.24/2.5.21/
   2.6.5), pgvector **CVE-2026-3172** (corregido en 0.8.2), **CVE-2026-24477** (fuga de la API key de
   Qdrant vía AnythingLLM). Comprueba avisos nuevos antes de fijar versión.
3. **Autenticación por defecto por motor** (§5.1). Verificado verbatim en documentación oficial para
   Qdrant, Weaviate y Milvus. **Reverifícalo en cada versión mayor: es el dato que más cambia y el
   que más cuesta si está mal.**
4. **Soporte de cuantización por motor y versión** (§2.5), y si hay *rescoring* con vectores completos.
5. **Modelo de persistencia** del motor concreto (§6.1): qué se persiste, WAL, fsync, y si el índice
   se reconstruye al arrancar.
6. **Compatibilidad de snapshots entre versiones** antes de cualquier actualización.
7. **Servicios gestionados equivalentes** y su modelo de precio (`aws-standards`, `azure-standards`,
   `gcp-standards`) — cambian a menudo.
8. **Incidentes de cadena de suministro** en el ecosistema (precedentes en el catálogo: LiteLLM en
   PyPI, marzo 2026).

**Huecos declarados — NO rellenar de memoria**:

- **Umbral de volumen exacto en el que pgvector deja de servir**: deliberadamente no fijado. Depende
  de dimensionalidad, cuantización, selectividad de filtros, RAM y latencia objetivo. **Se mide con
  el método de §2.2.**
- **Fórmulas de consumo de memoria por familia de índice**: no fijadas. Las que circulan omiten la
  sobrecarga real del grafo y del payload. Mídelo sobre una muestra.
- **Impacto en recall de cada método de cuantización**: **no fijado.** Los factores de compresión son
  de la documentación del proveedor (verificados); el recall depende de tu corpus y de tu modelo.
- **Cuantización en Milvus 3.x**: no verificada en detalle en esta revisión (el major es de jul-2026).
  Consulta su documentación antes de fijar nada.
- **Estado de auth por defecto de Chroma y LanceDB**: verificado solo de forma indirecta (Chroma sin
  auth en el arranque estándar, puerto 8000; LanceDB embebido no expone servicio). **Confírmalo en su
  documentación antes de desplegar.**
- **Cifras de instancias expuestas en Internet**: el patrón está confirmado por investigación pública
  (Orca Security, may-2026); **los conteos concretos que circulan en blogs no se citan como hechos.**
- **Latencias, throughput y benchmarks comparativos entre motores**: no fijados. Los públicos son casi
  siempre de proveedor, sin condiciones reproducibles y sobre datasets académicos.
- **Precios de los servicios gestionados**: no fijados.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
