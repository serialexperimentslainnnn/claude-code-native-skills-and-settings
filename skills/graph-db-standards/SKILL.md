---
name: graph-db-standards
description: Use when a graph engine or a graph query is on the table — proving the traversal is variable-depth before adding an engine (friend-of-a-friend, shortest path, cycle detection, propagation) instead of a two-hop JOIN or a recursive CTE, Neo4j (cypher-shell, neo4j.conf, Bolt, 5.26 LTS versus CalVer releases, Community versus Enterprise, GDS algorithms), Memgraph, MemGQL, FalkorDB, ArangoDB, JanusGraph, TigerGraph GSQL, Amazon Neptune or Neptune Analytics, Apache AGE and SQL/PGQ GRAPH_TABLE on Postgres, DuckPGQ, writing Cypher or openCypher MATCH patterns and reading their PROFILE/EXPLAIN plan, GQL as ISO/IEC 39075 and how little of it is really implemented, Gremlin and TinkerPop traversals, RDF triplestores with SPARQL, OWL ontologies, Fuseki, GraphDB or Virtuoso, deciding what is a node versus a relationship, supernodes and dense relationships, anchoring a traversal on a starting index, graph partitioning and single-machine limits, or knowledge graphs built to feed an LLM.
---

# Estándares de bases de datos de grafo

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **decidir, modelar, consultar y operar** un almacén de grafo: grafo de
propiedades (Neo4j, Memgraph, FalkorDB, ArangoDB, JanusGraph, TigerGraph, Neptune) y
RDF/triplestore (Jena/Fuseki, GraphDB, Virtuoso, Neptune en modo SPARQL). Cubre la
justificación previa frente a SQL, los lenguajes de consulta y su portabilidad real, el
modelado (nodo vs relación, supernodos, temporalidad), el rendimiento (anclaje de la
consulta, plan de ejecución), los límites de escala, la operación, las licencias y las
alternativas sobre PostgreSQL antes de adoptar nada.

Triggers: "grafo", "graph database", "Cypher", "openCypher", "GQL", "Gremlin", "SPARQL",
"Neo4j", "Memgraph", "Neptune", "JanusGraph", "TigerGraph", "ArangoDB", "Apache AGE",
"SQL/PGQ", "camino más corto", "amigos de amigos", "recorrido", "traversal", "supernodo",
"ontología", "RDF", "triple", "grafo de conocimiento".

**No aplica**: ver `data-platform-standards` (**skill madre**: PostgreSQL como default,
modelado relacional, índices, réplicas, PITR, backups, clasificación del dato; y el
principio "un almacén por necesidad, no por moda", que aquí se aplica con especial dureza),
`nosql-standards` (documental, clave-valor y columna ancha: MongoDB, DynamoDB,
Cassandra/ScyllaDB; **el grafo es un modelo de datos distinto, no una familia más de
NoSQL** — la agrupación es histórica y comercial, no técnica: allí se modela por patrón de
acceso y se renuncia al JOIN, aquí el recorrido *es* el patrón de acceso),
`rag-standards` (**GraphRAG y la recuperación para IA son suyas**: chunking, embeddings,
recuperación híbrida, reranking, evaluación de recall; aquí solo el motor y el modelado del
grafo que eventualmente alimente esa recuperación), `llm-app-engineering-standards` y
`mlops-standards`, `microservices-architecture-standards` (propiedad del dato por servicio:
un grafo que cruza dominios de varios servicios es una señal de límites mal cortados),
`privacy-engineering-standards` (un grafo de relaciones entre personas es un tratamiento de
alto riesgo: DPIA, minimización y derechos del interesado son suyos),
`identity-access-management-standards` (ReBAC con OpenFGA/SpiceDB/Zanzibar: **son motores
de autorización, no bases de datos de grafo** — no se resuelve aquí),
`observability-standards`, `sre-practice-standards`, `backup-recovery-standards`,
`bcdr-standards`, `kubernetes-standards`, `linux-storage-standards`, `iac-standards`,
`cicd-standards`, `secrets-management-standards`, `cryptography-pki-standards`,
`grc-compliance-standards`, `vulnerability-management-standards`,
`aws-standards`/`azure-standards`/`gcp-standards` (Neptune, Cosmos DB Gremlin API, Spanner
Graph como servicios gestionados: cuotas, IAM y factura son suyas; **el criterio de
modelado y de consulta es de aquí**), las skills de lenguaje (drivers Bolt/Gremlin y OGM),
`vector-db-standards` (**búsqueda vectorial y operación de un índice ANN: suyas**, aunque
los motores de grafo hayan añadido índices vectoriales), `data-engineering-standards` (los
pipelines que cargan el grafo), `data-warehouse-modeling-standards` (modelado analítico).
**Ola 4, planificadas**: `search-engines-standards` (búsqueda
por relevancia), `timeseries-db-standards`, `lakehouse-standards`
(analítica), `streaming-cdc-standards`, `data-governance-quality-standards`,
`analytics-bi-standards`, `caching-cdn-standards`, `message-brokers-standards`,
`oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`.

### Principio rector: el grafo se justifica por la **forma de la consulta**, nunca por la del dato

"Mis datos están conectados" no es un argumento: **todos** los datos relacionales lo están;
para eso existe la clave ajena. El grafo gana cuando la **consulta** tiene esta forma:

- **Profundidad variable o desconocida**: "todo lo que alcanza X en 1..n saltos", "¿existe
  camino entre A y B?", detección de ciclos (fraude, dependencias circulares), cierre
  transitivo (jerarquías de propiedad, listas de materiales, permisos heredados).
- **Caminos como resultado**: ruta más corta, k caminos, camino con restricciones sobre
  los tipos de relación atravesados — no solo los extremos, sino **el camino en sí**.
- **Propagación e influencia** sobre la topología: centralidad, comunidades, PageRank,
  similitud estructural.
- **Topología muy irregular** donde el número de saltos depende del dato, no del esquema,
  y el plan relacional se convierte en una escalera de auto-JOINs recursivos cuyo coste
  explota.

**Y cuándo NO — este es el error dominante del dominio y hay que decirlo sin rodeos**: si
tus consultas son de **uno o dos saltos fijos** ("los pedidos de un cliente", "los
seguidores de un usuario", "las etiquetas de un artículo"), un `JOIN` es más simple, más
rápido, más barato y **no añade un motor a la operación**. Un `JOIN` sobre índices en
PostgreSQL bate a cualquier grafo en ese terreno, y encima conserva transacciones,
agregaciones, informes ad-hoc y un ecosistema de herramientas que el grafo no tiene.
Adoptar un motor de grafo cuesta: una licencia que revisar (§2.1), un lenguaje que casi
nadie del equipo sabe, un modelo que no encaja con el ORM, una copia del dato que hay que
sincronizar desde el sistema de registro, y un componente más en la guardia.

Antes de adoptar, **agota las alternativas de §2.2** (CTE recursiva, `Apache AGE`, SQL/PGQ)
y escribe en un ADR: la consulta concreta que no se puede resolver así, su volumen real, su
presupuesto de latencia y la medición que demuestra que la vía relacional no llega. Sin ese
párrafo, la respuesta es no.

## 2. Decisiones por defecto

> Verificar versión, EOL, CVE y **licencia vigente** por web antes de fijar nada (§8). Los
> datos son de agosto 2026 y este ecosistema cambia de licencia con frecuencia.

| Necesidad | Por defecto | Alternativa justificable |
|---|---|---|
| Recorridos de 1-2 saltos, jerarquías pequeñas | **PostgreSQL** con `JOIN` o `WITH RECURSIVE` | — |
| Grafo de propiedades como funcionalidad secundaria de un sistema ya en PostgreSQL | **Apache AGE** (extensión, Apache-2.0) | Motor dedicado si la medición lo exige |
| Grafo de propiedades como caso de uso central, autogestionado | **Neo4j** (el ecosistema, la documentación y el mercado laboral más maduros) — asumiendo los límites de su Community Edition (§2.1) | Memgraph si el perfil es *streaming*/en memoria; FalkorDB si prima la latencia en cargas tipo GraphRAG |
| Grafo gestionado en AWS | **Amazon Neptune** (openCypher + Gremlin + SPARQL sobre el mismo dato) | — |
| Semántica, vocabularios compartidos, federación e inferencia | **RDF/triplestore**: Apache Jena/Fuseki (Apache-2.0) | GraphDB/Virtuoso/Stardog comerciales; Neptune en modo SPARQL |
| Analítica de grafo puntual sobre datos que ya viven en el almacén analítico | Exportar y usar una librería (NetworkX, igraph, GraphFrames) o **DuckPGQ** | Motor dedicado solo si la analítica es continua |

Estado verificado (agosto 2026):

| Pieza | Estado | Nota que cambia decisiones |
|---|---|---|
| Neo4j | CalVer mensual desde 2025 (etiqueta verificada más reciente: **2026.06.0**) y rama **5.26 LTS** viva (5.26.28) | La serie CalVer exige **Java 21**; 5.26 LTS acepta 17 o 21. 5.26 es *checkpoint* obligatorio para venir de 4.4/5.x |
| Memgraph | **3.12.0** (jul 2026) | Publica **MemGQL**, motor federado de consultas **GQL** que traduce a backends (Memgraph, Neo4j, y relacionales: PostgreSQL, DuckDB, Iceberg) vía Bolt |
| ArangoDB | 3.12.9.x | **BUSL-1.1** desde 3.12 (§2.1) |
| JanusGraph | **1.1.0** (nov 2024) como última release oficial; desarrollo vivo con *per-commit releases* hacia 1.2.0, sin fecha | Cadencia lenta: evaluarlo con los ojos abiertos. Solo backend CQL (Cassandra/ScyllaDB) |
| Apache TinkerPop / Gremlin | **3.8.1** estable; **4.0.0-beta.3** (jul 2026) | Gremlin 4 aún en beta: no fijarlo en producción |
| Apache AGE | Releases por rama de PostgreSQL (1.7.x para PG17/PG18; 1.8.0-rc para PG18/**PG19**); release de ene-2026 añadió RLS e índice sobre columnas id | **Proyecto ASF top-level activo**, Apache-2.0, presente en Azure Database for PostgreSQL. La versión va atada a la mayor de PG: verificar antes de planificar un upgrade de PG |
| Apache Jena / Fuseki | Línea **6.x** (artefacto 6.1.0 en Maven Central) | Jena 6 requiere **Java 21+** |
| Blazegraph | Sin releases desde 2.1.5 (2019) | **Congelado**: no adoptar. Neptune es su sucesor comercial |

### 2.1 Licencias — verificar antes de elegir

| Motor | Licencia verificada | Qué implica |
|---|---|---|
| **Neo4j** | Community Edition libre (históricamente GPLv3 — confirmar en la página de licencias vigente); Enterprise bajo licencia comercial de Neo4j | **La CE no tiene clustering, ni RBAC/control de acceso fino, ni backups en caliente, y está limitada a una única base de datos de usuario.** Es decir: sin HA y sin autorización por rol. Cualquier producción con requisitos de disponibilidad o multi-tenancy ⇒ Enterprise o Aura. Presupuestarlo **antes** de elegir Neo4j |
| **Neo4j GDS** (algoritmos) | Edición Community por defecto; Enterprise con fichero de licencia. La parte abierta se ensambla como **OpenGDS** bajo GPLv3 | GDS Community incluye todos los algoritmos pero limita la **concurrencia a 4 núcleos** y el catálogo de modelos a 3, y no soporta escrituras GDS en clúster. Un cálculo de grafo grande con 4 hilos no es una opción de producción |
| **Memgraph** | Community Edition bajo **BSL 1.1** (convierte a Apache-2.0 a los 4 años); Enterprise bajo licencia propietaria (MEL) | HA, autenticación avanzada y multi-tenancy son Enterprise; la licencia se aplica **por volumen de datos**: al alcanzar el límite se **bloquean las escrituras** (solo lectura y borrado). Dimensionarlo antes |
| **ArangoDB** | Código bajo **BUSL-1.1** desde 3.12 (antes Apache-2.0); binarios CE bajo *ArangoDB Community License* | Tope de **100 GiB** en producción y solo uso interno; prohibido ofrecerlo como servicio o redistribuirlo con tu producto sin acuerdo comercial |
| **FalkorDB** | **SSPLv1** | Uso interno sin obligación; ofrecerlo como servicio a terceros obliga a publicar el servicio completo bajo SSPL o comprar licencia |
| **JanusGraph** | Apache-2.0 | Sin restricciones; el coste está en operar además Cassandra/Scylla + índice externo |
| **Apache AGE**, **Apache Jena/Fuseki**, **openCypher (spec)** | Apache-2.0 | Sin restricciones |
| **TigerGraph / GSQL** | Producto y lenguaje **propietarios** (librerías del ecosistema, como `gsql-graph-algorithms`, sí Apache-2.0) | Lock-in de lenguaje: GSQL no existe fuera de TigerGraph |
| **Neptune / Cosmos DB / Spanner Graph** | Servicio gestionado propietario | La "licencia" es el contrato y el coste de salida |

**PROHIBIDO** afirmar cualquiera de estas licencias de memoria: se lee la página oficial
vigente (§8). ArangoDB, Memgraph y FalkorDB no son open source, aunque su marketing lo
sugiera.

### 2.2 Alternativas sobre PostgreSQL antes de adoptar un motor

- **`WITH RECURSIVE`**: resuelve jerarquías, cierre transitivo y caminos de profundidad
  moderada. Reglas para que no se vuelva inmanejable: índice sobre la columna de enlace,
  **corte de profundidad explícito** (`WHERE depth < n`), y **detección de ciclos**
  (`CYCLE ... SET ... USING ...` en PostgreSQL, o array de visitados). Rinde bien hasta que
  el abanico por nivel explota; ahí se mide y se decide, no antes.
- **Apache AGE**: extensión ASF que da Cypher (subconjunto) dentro de PostgreSQL, con las
  transacciones y el respaldo del motor que ya operas. Es la primera opción cuando el grafo
  es una **parte** del sistema y no el sistema. Coste: rendimiento inferior al de un motor
  nativo en recorridos profundos, cobertura parcial de Cypher, y su versión va atada a la
  mayor de PostgreSQL.
- **SQL/PGQ** (parte 16 de SQL:2023, `GRAPH_TABLE`, vistas de grafo sobre tablas
  existentes): estado real verificado — **Oracle Database 23ai** es la implementación
  comercial madura; **PostgreSQL lo tiene en desarrollo apuntando a PG 19** (no dar por
  hecha su llegada); **DuckDB** vía la extensión comunitaria **DuckPGQ**, útil pero con
  riesgo de proyecto de investigación. Vigilarlo: si llega a PostgreSQL, cambia la
  ecuación de adopción de muchos casos.
- **Precalcular**: si el recorrido siempre parte de los mismos nodos y cambia poco, una
  tabla materializada de alcanzabilidad (recalculada por lote o por evento) resuelve el
  problema sin motor nuevo. Es la opción que casi nadie evalúa y que suele ganar.

## 3. Lenguajes de consulta y portabilidad

- **Cypher / openCypher**: el dialecto de facto del grafo de propiedades. openCypher sigue
  vivo pero **ha redefinido su misión como rampa hacia GQL**: la especificación evoluciona
  incorporando características de GQL. El repositorio openCypher es Apache-2.0 y se declara
  mantenido por empleados/contribuidores de Neo4j a título personal, sin garantías ni
  soporte — no es un estándar con gobernanza neutral.
- **GQL — ISO/IEC 39075**, publicado en **abril de 2024** por ISO/IEC JTC1/SC32/WG3 (el
  mismo grupo que SQL): primer lenguaje de consulta estandarizado nuevo en más de 35 años.
  Lo interesante **no es la norma, es su adopción**, y ahí toca ser honesto:
  - **No existe un régimen de certificación de conformidad independiente** (nada análogo a
    la validación NIST del SQL de los 90). Toda afirmación de conformidad es
    **autodeclarada por el fabricante**.
  - Neo4j publica un apéndice de conformidad GQL en su manual de Cypher, versionado por
    release, e incluye una lista de **características obligatorias de GQL aún no
    soportadas**. Es la contabilidad pública más detallada que existe — y admite huecos.
  - Memgraph lo aborda por otra vía: **MemGQL**, un motor federado de GQL que traduce a
    los lenguajes nativos de los backends.
  - Conclusión operativa: **GQL es una dirección, no una garantía de portabilidad hoy**.
    No planifiques una migración entre motores apoyándote en "los dos hablan GQL".
- **Gremlin (Apache TinkerPop)**: imperativo, portable entre implementaciones de TinkerPop
  (Neptune, JanusGraph, Cosmos DB). 3.8.1 estable, **4.0 aún en beta**. Es la opción cuando
  la portabilidad entre motores TinkerPop pesa más que la legibilidad.
- **SPARQL / RDF**: otro paradigma. Estado normativo verificado: las especificaciones de
  **SPARQL 1.2 siguen en Working Draft**; **RDF 1.2 Concepts y RDF 1.2 Semantics están en
  Candidate Recommendation** (abril 2026), pendientes de dos implementaciones
  independientes que pasen el test suite. En producción hoy se trabaja con **SPARQL 1.1**.
- **Realidad transversal: la portabilidad entre motores sigue siendo pobre.** Aunque dos
  motores acepten "Cypher", divergen en funciones, procedimientos (`CALL`), índices,
  tipos, semántica de caminos y extensiones. Consecuencia de diseño: **aísla el acceso al
  grafo detrás de un repositorio propio** en el código, y trata las consultas como
  artefactos versionados y testeados; cambiar de motor será una reescritura de consultas
  con o sin norma.

## 4. Modelado y calidad — gates

### 4.1 Modelado (donde más se equivoca la gente)

- **Qué es nodo y qué es relación** es *la* decisión del dominio. Regla de trabajo: es
  **nodo** lo que puede ser el **origen o destino de un recorrido** o lo que necesita
  atributos propios, identidad y sus propias relaciones; es **relación** la conexión
  dirigida y tipada entre dos nodos. Si una conexión necesita relacionarse a su vez con
  otra cosa (un pedido que conecta cliente y producto pero también tiene líneas, pagos y
  envíos), **es un nodo**, no una relación con propiedades: reificarla después implica
  reescribir consultas y migrar datos.
- **Propiedad frente a nodo**: un valor descriptivo es propiedad; un valor por el que se
  **filtra o se navega desde muchos nodos** (categoría, etiqueta, país, estado) se
  convierte en nodo... y ahí nace el **supernodo**. Decidir con la consulta en la mano.
- **Supernodos y relaciones densas** son *el* problema de rendimiento del grafo: un nodo
  con millones de aristas convierte cualquier recorrido que lo atraviese en un escaneo.
  Mitigaciones: no modelar como nodo lo que es un atributo de baja cardinalidad; tipar las
  relaciones de forma fina para poder filtrar por tipo antes de expandir; particionar el
  supernodo (por tiempo, por región, por *bucket*); dirección explícita en el recorrido; y
  como última opción, desnormalizar en el nodo lo que se necesita para evitar la expansión.
  **Detectarlos es tarea de diseño y de operación**: consulta periódica de grado máximo.
- **Modelado temporal**: si la relación tiene vigencia (empleos, participaciones,
  titularidades), decidir explícitamente entre (a) propiedades `desde`/`hasta` en la
  relación —simple, obliga a filtrar en cada consulta—, (b) relación reificada en nodo
  "estado/versión" —modelo más limpio, más nodos y más saltos— o (c) instantáneas por
  periodo. Es una decisión ADR: cambiarla después es una migración completa.
- **Dirección y tipos**: las relaciones se crean **una sola vez y con dirección**; la
  consulta puede recorrerlas en ambos sentidos. Duplicar la arista en ambos sentidos
  duplica escrituras y crea inconsistencias.
- **El grafo casi nunca es el sistema de registro**: suele ser una proyección del dato que
  vive en el relacional. Si es así, la reconstrucción completa del grafo desde la fuente
  debe ser un procedimiento probado y cronometrado — y entonces el respaldo del grafo pesa
  menos que el del sistema de registro.

### 4.2 Gates de CI

1. **Esquema declarado y versionado**: restricciones de unicidad y existencia, y los
   índices, como migraciones en el repositorio (nunca creados a mano en producción). En
   Neo4j, `CREATE CONSTRAINT`/`CREATE INDEX` versionados; en RDF, SHACL para validar
   forma. Un grafo sin restricciones acumula nodos duplicados en semanas.
2. **Consultas como artefactos**: cada consulta de la aplicación vive en el repositorio,
   con su test de integración **contra el motor real** (Testcontainers), sobre un grafo
   sintético con la topología que importa — incluidos **ciclos, nodos aislados y al menos
   un supernodo**. Nada de mocks del driver.
3. **Presupuesto de recorrido**: toda consulta de profundidad variable declara su cota
   (`*1..n` acotado, `LIMIT`, timeout de transacción). Una consulta sin cota es un fallo de
   revisión: en un grafo, la diferencia entre 3 y 4 saltos puede ser tres órdenes de
   magnitud.
4. **Plan de ejecución revisado**: `PROFILE`/`EXPLAIN` de las consultas críticas adjunto en
   el PR, con los `db hits` y el operador de arranque visibles. **Gate duro**: ninguna
   consulta caliente puede empezar por un escaneo de etiqueta (`AllNodesScan`/`NodeByLabel
   Scan`) donde debía usar índice.
5. **Regresión de rendimiento** con un grafo de tamaño y **forma** representativos: el
   coste de un recorrido depende del abanico real, no del número de nodos. Medir p99.
6. **Restore probado** del respaldo, cronometrado, con la reconstrucción desde la fuente
   como plan alternativo verificado.

## 5. Rendimiento: anclaje y plan

- **Todo recorrido empieza en un punto.** Sin un **índice de arranque** que localice el
  nodo o el pequeño conjunto inicial, no hay grafo rápido: el motor escanea la etiqueta
  entera y el recorrido posterior da igual. Regla: **cada consulta identifica su nodo
  ancla y ese ancla tiene índice** (o restricción de unicidad, que lo implica).
- **El plan de ejecución importa más que en SQL**, y por una razón concreta: en SQL un mal
  plan suele degradar linealmente con el tamaño de la tabla; en un grafo, expandir por el
  extremo equivocado hace que el coste crezca con el **producto de los abanicos** de cada
  salto. La misma consulta, anclada en el otro extremo, puede ser instantánea o eterna.
  De ahí que `PROFILE` sea obligatorio (§4.2) y que convenga fijar la dirección de
  expansión cuando se conoce la cardinalidad de cada lado.
- Otras palancas: filtrar por **tipo de relación** antes de expandir; acotar la profundidad;
  usar la variante de camino más corto del motor en vez de expandir a mano; evitar
  `OPTIONAL MATCH` encadenados que multiplican filas; y proyectar solo lo necesario.
- **Escrituras**: por lotes y con transacciones cortas; las cargas iniciales masivas usan
  la herramienta de importación en bloque del motor, no un bucle de `MERGE` (que además
  necesita índice para no escanear en cada iteración).
- **Algoritmos de grafo** (PageRank, comunidades, centralidad) no son consultas: son cargas
  analíticas que se ejecutan sobre una proyección, con su ventana, sus recursos y su
  cadencia; nunca en el camino de una petición de usuario. Y ojo con el límite de
  concurrencia de la edición Community (§2.1).

## 6. Escala y operación

- **La mayoría de los grafos caben en una máquina** — y esa es la buena noticia: escalar
  verticalmente (RAM suficiente para que el grafo caliente resida en memoria, NVMe, CPU) es
  la estrategia correcta durante mucho más tiempo del que la gente supone. Diseña para eso
  antes que para repartir.
- **El particionado de un grafo es un problema difícil de verdad**, no una casilla de
  configuración: cualquier corte deja aristas cruzando particiones, y cada arista cruzada
  convierte un salto local en una llamada de red dentro de un recorrido que puede dar
  muchos saltos. Por eso los motores nativos escalan lecturas con **réplicas** y no
  particionan el grafo por defecto, y los que sí lo hacen (JanusGraph sobre Cassandra,
  TigerGraph) trasladan el coste a la latencia del recorrido distribuido. Si crees que
  necesitas particionar, primero verifica que no te cabe en una máquina grande y que el
  problema no es un supernodo (§4.1).
- **Alta disponibilidad**: réplicas y failover son **de pago** en varios motores (§2.1). Si
  la arquitectura exige HA y el presupuesto no cubre la edición Enterprise, la decisión
  correcta no es montar HA artesanal: es no usar ese motor, o mantener el grafo como
  proyección reconstruible desde el sistema de registro y aceptar un RTO de reconstrucción.
- **Copias de seguridad**: en Community suele haber solo copia **en frío** (con el servicio
  parado o inconsistente en caliente): planifica ventana o reconstrucción. Copia cifrada,
  fuera del host, con una copia inmutable, y **restore ensayado y cronometrado** (§4.2).
- **Actualizaciones**: leer las release notes completas y ensayar en staging. En Neo4j hay
  dos trenes —LTS (5.26) y CalVer mensual— con requisitos de Java distintos (21 en CalVer)
  y **5.26 como *checkpoint* obligatorio** para llegar desde versiones anteriores; el
  formato de almacenamiento puede impedir el rollback, así que la vuelta atrás se planifica
  como restauración o clúster paralelo.
- **Seguridad**: nunca exponer Bolt/HTTP/Gremlin/SPARQL a Internet; cambiar credenciales
  por defecto; TLS en tránsito y cifrado en reposo; y asumir que **sin RBAC (Community) el
  control de acceso lo hace enteramente la aplicación**, lo que descarta multi-tenancy en
  el mismo grafo. CVE recientes verificados en Neo4j: **CVE-2026-1497** (autorización
  incorrecta en bases compuestas de Enterprise; corregido en 2026.02 / 5.26.22) y
  **CVE-2026-1622** (la opción `obfuscate_literals` del log de consultas no redacta la
  información de error; corregido en 5.26.21 / 2026.01.3). Suscribirse a los avisos del
  fabricante.
- **Inyección de consultas**: existe igual que en SQL. **Siempre parámetros** (`$param`),
  nunca concatenación de entrada de usuario en Cypher/Gremlin/SPARQL — que además destroza
  la caché de planes. En SPARQL, cuidado adicional con `SERVICE` (federación) como vector
  de SSRF.
- **Observabilidad**: latencia p99 por consulta con nombre, `db hits`/páginas leídas,
  consultas lentas registradas, memoria del grafo residente frente a total, grado máximo de
  nodo (supernodos emergentes), tamaño del *store*, y lag de la proyección respecto al
  sistema de registro. Esta última es la métrica que más incidentes explica.

## 7. Sostenibilidad y prohibiciones

- **ADR obligatorio** con: la consulta concreta que justifica el grafo, la medición de la
  alternativa relacional, el modelo (qué es nodo y qué relación, y por qué), la estrategia
  temporal, el motor y **su licencia y edición en el momento de decidir**.
- **Revisar la licencia en cada upgrade mayor**: ArangoDB (BUSL desde 3.12) y Memgraph (BSL
  con límite por volumen) son ejemplos de cambios que alteran obligaciones sin tocar tu
  código.
- **Ruta de salida**: mantener documentada la reconstrucción del grafo desde el sistema de
  registro y evitar que el grafo acumule dato que no exista en ningún otro sitio. Un grafo
  que se ha convertido en fuente de verdad sin querer es la trampa clásica.
- **Grafos de conocimiento para IA (GraphRAG)** — el caso de uso de moda, y por tanto el
  que más despliegues injustificados produce. La recuperación, la evaluación y la decisión
  de arquitectura son de **`rag-standards`**; desde aquí, tres avisos honestos verificados:
  (a) el coste de **construcción** del grafo es la partida dominante y es de LLM, no de
  base de datos —extracción de entidades y relaciones sobre todo el corpus, más resumen de
  comunidades—, con cifras públicas que fueron de decenas de miles de dólares para corpus
  medianos en 2024 y que las variantes perezosas (LazyGraphRAG, HippoRAG) han reducido
  drásticamente; (b) hay un **coste de consulta** en tokens y latencia notablemente mayor
  que el de la recuperación vectorial, y una reindexación cara cuando el corpus cambia a
  menudo; (c) buena parte de los *benchmarks* favorables los publican fabricantes de bases
  de datos de grafo. Criterio: **agotar primero la recuperación híbrida (BM25 + denso con
  fusión RRF) y el reranking**; el grafo entra cuando el problema es genuinamente
  multi-salto o de agregación global sobre el corpus, y el pipeline de extracción se trata
  como lo que es —un generador de datos con alucinaciones— con validación y corrección.

**PROHIBIDO**
- ❌ Adoptar un motor de grafo porque "los datos están conectados" o porque el dominio se
  dibuja bonito como grafo.
- ❌ Sustituir por un grafo consultas de **uno o dos saltos fijos**: eso es un `JOIN`.
- ❌ Adoptarlo sin haber evaluado y medido `WITH RECURSIVE`, Apache AGE o la
  precomputación.
- ❌ Recorridos de profundidad **ilimitada** o sin `LIMIT`/timeout en producción.
- ❌ Consultas calientes sin **índice de arranque**, o mergeadas sin `PROFILE` revisado.
- ❌ Modelar como relación algo que necesita sus propias relaciones (reificación tardía).
- ❌ Convertir en nodo un atributo de baja cardinalidad y fabricarse un supernodo.
- ❌ Duplicar aristas en ambos sentidos "para que las consultas sean más fáciles".
- ❌ Construir consultas por concatenación de entrada de usuario (Cypher, Gremlin o SPARQL).
- ❌ Exponer Bolt/Gremlin/SPARQL a Internet, o dejar credenciales por defecto.
- ❌ Confiar en la Community Edition para producción con requisitos de HA, RBAC,
  multi-tenancy o backup en caliente (§2.1) — o descubrir ese límite después de firmar.
- ❌ Dar por hecha la portabilidad entre motores por "hablar Cypher" o "ser GQL".
- ❌ Llevar a producción TinkerPop/Gremlin 4 mientras siga en beta.
- ❌ Adoptar Blazegraph u otro motor sin releases recientes.
- ❌ Ejecutar algoritmos de grafo pesados en el camino de una petición de usuario.
- ❌ Dejar que el grafo se convierta en sistema de registro sin decidirlo.
- ❌ Montar GraphRAG sin haber agotado la recuperación híbrida y sin presupuestar el coste
  de construcción y reindexación.
- ❌ Afirmar versiones, estado de normas o **licencias** de memoria, sin la verificación de §8.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un entregable:

1. **Licencia y edición vigentes**: página de licencias de Neo4j (y qué incluye exactamente
   la Community Edition hoy), licencia de GDS, BSL de Memgraph y su límite por volumen,
   BUSL de ArangoDB y el tope de la Community License, SSPL de FalkorDB. Es el dato que más
   cambia y el que más caro sale equivocar.
2. **Versiones y soporte**: release CalVer actual de Neo4j y fecha de EOL de **5.26 LTS**;
   Memgraph; estado de **TinkerPop 4.0** (¿sigue en beta?); release oficial de JanusGraph
   (¿ha salido 1.2.0?); rama de Apache AGE para tu mayor de PostgreSQL; línea de Jena.
3. **Estado real de GQL (ISO/IEC 39075)**: si ha aparecido una segunda edición o enmienda,
   y **qué motores la implementan de verdad** — apéndice de conformidad de Neo4j (lista de
   características obligatorias aún no soportadas) y estado de MemGQL. Desconfiar de toda
   afirmación de conformidad: no hay certificación independiente.
4. **Estado de SQL/PGQ en PostgreSQL** (¿ha entrado en PG 19?): si llega, muchas
   adopciones de motor dedicado dejan de justificarse.
5. **Estado normativo de RDF 1.2 / SPARQL 1.2** en la página del W3C (en agosto 2026: RDF
   1.2 en Candidate Recommendation, SPARQL 1.2 en Working Draft).
6. **CVE** de los motores a recomendar y su versión de parche; presencia en el catálogo KEV
   de CISA.
7. **Incidentes de cadena de suministro** en drivers y librerías (Bolt, Gremlin, OGM): npm
   y PyPI siguen bajo campañas de gusano recurrentes en 2026; fijar versiones y hashes.

**Huecos declarados** (no verificados en la sesión de agosto 2026; **no rellenar de
memoria**):
- **Licencia exacta de Neo4j Community Edition hoy** (históricamente GPLv3): no se pudo
  leer la página oficial —`neo4j.com/docs` devolvió 403— y las fuentes secundarias no la
  citaban textualmente. **Verificar antes de afirmarla.**
- **Fecha de EOL de Neo4j 5.26 LTS**: una fuente secundaria indicaba junio de 2028; sin
  confirmar en fuente oficial.
- **Texto verbatim del apéndice de conformidad GQL de Neo4j** y la lista concreta de
  características obligatorias no soportadas: no accesible (403). Lo afirmado aquí procede
  de fuentes secundarias.
- **TigerGraph**: versión actual, límites del *free tier* (la cifra de 50 GB circula desde
  2020) y estado de su soporte de openCypher: no verificados.
- **Amazon Neptune**: versión de motor actual, Neptune Analytics y sus cuotas: no
  verificados en esta sesión.
- **CVE de Memgraph, ArangoDB, JanusGraph, FalkorDB y Jena/Fuseki**: no revisados.
- **Estado de Wikidata/Wikibase respecto a Blazegraph** (migración en curso o no): no
  verificado.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
