---
name: nosql-standards
description: Use when a non-relational store is proposed, modelled or operated — justifying it against PostgreSQL JSONB and GIN first, MongoDB (mongod, mongosh, replica set, sharded cluster, SSPL, Atlas-only rapid releases), DynamoDB single-table design (partition key and sort key, GSI, LSI, hot partition, on-demand versus provisioned capacity, TransactWriteItems, DynamoDB Streams, adaptive capacity), Cassandra or ScyllaDB (CQL, cqlsh, keyspace RF, NetworkTopologyStrategy, LOCAL_QUORUM, tombstones, compaction strategy, nodetool repair), Couchbase, FerretDB or the Linux Foundation DocumentDB Postgres extension, modelling by access pattern instead of by entity, deliberate denormalization and duplicated writes, eventual versus strong reads, CAP and PACELC trade-offs, LSM write amplification and compaction cost, rebalancing and major-version upgrades, source-available licence review (SSPL, BUSL, free-tier node or vCPU caps) before a commercial or managed deployment, or migrating back to a relational store.
---

# Estándares de almacenes NoSQL

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **decidir, modelar y operar** un almacén no relacional: documental (MongoDB y
compatibles, Couchbase), clave-valor y de columna ancha (DynamoDB, Cassandra, ScyllaDB).
Cubre la justificación previa frente a PostgreSQL, el modelado por patrón de acceso, el
diseño de clave, la consistencia como decisión de producto, la operación (particiones,
compactación, rebalanceo, respaldo, upgrades), el coste y **la revisión de licencia** —que
en este dominio es un criterio de arquitectura, no un trámite legal— y la salida de vuelta
a relacional cuando la decisión fue errónea.

Triggers: "MongoDB", "mongosh", "replica set", "sharding", "DynamoDB", "single-table
design", "partition key", "GSI", "hot partition", "Cassandra", "ScyllaDB", "CQL",
"keyspace", "quorum", "tombstone", "compaction", "Couchbase", "FerretDB", "DocumentDB",
"consistencia eventual", "desnormalizar", "esquema flexible", "NoSQL".

**No aplica**: ver `data-platform-standards` (**skill madre**: PostgreSQL como default —
modelado, JSONB, índices, particionado, réplicas, PITR—, Valkey/Redis, Kafka, backups,
clasificación del dato; y el principio "un almacén por necesidad" que esta skill hereda),
`graph-db-standards` (bases de datos de grafo: **el grafo es un modelo de datos distinto,
no una familia más de NoSQL** aunque el marketing las agrupe — recorridos de profundidad
variable, Cypher/GQL, supernodos; aquí no se decide nada de grafo),
`microservices-architecture-standards` (propiedad del dato por servicio, outbox, sagas y
consistencia eventual **entre servicios**; aquí la del motor),
`privacy-engineering-standards` (qué dato personal puede existir, DPIA, borrado real y
crypto-shredding extremo a extremo; aquí solo su ejecución en un motor sin JOIN ni FK),
`object-storage-standards` (S3 y compatibles como almacén de blobs: un documento grande
casi nunca va en la base de datos), `backup-recovery-standards` (mecánica y repositorio de
la copia), `bcdr-standards` (RTO/RPO derivados del negocio), `observability-standards`,
`sre-practice-standards`, `kubernetes-standards` (operadores y StatefulSets),
`linux-storage-standards` y `zfs-standards` (el disco por debajo), `iac-standards`,
`cicd-standards`, `secrets-management-standards`,
`identity-access-management-standards`, `cryptography-pki-standards`,
`grc-compliance-standards`, `vulnerability-management-standards`,
`aws-standards`/`azure-standards`/`gcp-standards` (DynamoDB, Cosmos DB, Firestore y
DocumentDB gestionado como servicios del proveedor: cuotas, IAM y factura son suyas; **el
criterio de modelado y de consistencia es de aquí**), las skills de lenguaje (drivers,
ODM/ORM y su ciclo de vida), `data-engineering-standards` (pipelines que cargan o extraen
de estos almacenes), `rag-standards` (recuperación para IA), `vector-db-standards`
(**búsqueda vectorial y operación del índice ANN: suyas**, aunque estos motores hayan
añadido tipos vector), `data-warehouse-modeling-standards` (modelado analítico).
**Ola 4, planificadas**: `search-engines-standards` (**Elasticsearch/OpenSearch y la
búsqueda de texto son suyas — frontera muy próxima**: si el requisito es *relevancia*
—ranking, analizadores, facetas, sugerencias— no es un almacén documental, es un buscador;
aquí solo el almacén de verdad que lo alimenta y del que se reindexa),
`vector-db-standards` (**búsqueda vectorial y ANN: suya**, aunque estos motores hayan
añadido tipos vector), `timeseries-db-standards` (**series temporales: suyas**),
`caching-cdn-standards` (**Redis/Valkey como caché: suya** — una caché no es un almacén y
no se decide aquí), `data-warehouse-modeling-standards` y `lakehouse-standards` (analítica
y modelado dimensional), `streaming-cdc-standards` (CDC desde estos motores),
`message-brokers-standards`, `data-governance-quality-standards`, `oracle-dba-standards`,
`sqlserver-dba-standards`, `mysql-mariadb-dba-standards`.

### Principio rector: la pregunta previa es **¿por qué no PostgreSQL?**

Un almacén NoSQL entra en la arquitectura **solo** cuando una necesidad **medida** lo exige
y el ADR documenta cuál es. La lista de necesidades que lo justifican es corta:

1. **Escala de escritura horizontal real** que un PostgreSQL bien dimensionado (con
   particionado y réplicas) no absorbe, demostrada con cifras y proyección, no con miedo.
2. **Patrón de acceso conocido, fijo y de alta cardinalidad**, con presupuesto de latencia
   p99 estricto a escala (milisegundos de un solo dígito bajo carga sostenida).
3. **Distribución geográfica multi-región activo-activo** con escritura local y resolución
   de conflictos asumida.
4. **Volumen de serie o de log** que un motor LSM absorbe barato y el relacional no.

Lo que **no** justifica un NoSQL: la *forma* del dato. "Es jerárquico", "es anidado", "los
campos varían por cliente" y "el esquema evoluciona rápido" los resuelve PostgreSQL con
`jsonb` + índices **GIN** (`jsonb_path_ops`), columnas generadas para lo que se consulta a
menudo, `CHECK` con `jsonb_matches_schema`/validación en el borde, particionado declarativo
y réplicas de lectura. Y las resuelve **conservando** transacciones multi-documento,
integridad referencial, JOIN ad-hoc y un ecosistema de operación maduro.

Señal de la propia industria: **DocumentDB** —el motor documental compatible con MongoDB
donado a la Linux Foundation (MIT, agosto 2025)— es literalmente un par de extensiones de
PostgreSQL (`pg_documentdb_core`, `pg_documentdb`) más una pasarela de protocolo
(`pg_documentdb_gw`). Cuando la industria quiso un documental abierto, lo construyó
**encima de PostgreSQL**. Ojo con el nombre: **no** es Amazon DocumentDB, que es un
servicio gestionado distinto de AWS.

**Coste de la decisión**: adoptar un NoSQL añade un motor a operar, una licencia que
revisar, un modelo de consistencia que explicar al negocio y un modelado que **se congela
con el patrón de acceso** (§3). Es una puerta *one-way* en la práctica: se entra rápido y
se sale con una migración (§7).

## 2. Decisiones por defecto

> Verificar por web la versión, el EOL, los CVE y **sobre todo la licencia vigente** antes
> de fijar nada en un proyecto real (§8). Los datos de esta tabla son de agosto 2026 y
> caducan; las licencias de este dominio han cambiado varias veces en dos años.

| Necesidad | Por defecto | Alternativa justificable |
|---|---|---|
| Cualquier caso sin necesidad medida de §1 | **PostgreSQL** (`jsonb` + GIN) | — (la carga de la prueba es de quien propone el NoSQL) |
| Documental gestionado en AWS/Azure/GCP | El servicio del proveedor, con el modelado de §3 | Autogestionado solo con capacidad operativa real |
| Clave-valor a escala en AWS | **DynamoDB** | Cassandra/ScyllaDB si hay multi-nube o portabilidad exigida |
| Columna ancha autogestionada | **Apache Cassandra 5.0.x** (Apache-2.0) | ScyllaDB si el perfil de latencia/densidad lo justifica **y** se acepta su licencia (§2.1) |
| Documental "compatible con Mongo" sin SSPL | **DocumentDB** (Linux Foundation, MIT) o **FerretDB** sobre él | MongoDB con licencia comercial |
| Caché | **No es esta skill** — ver `caching-cdn-standards` | — |
| Búsqueda por relevancia | **No es esta skill** — ver `search-engines-standards` | — |

Versiones verificadas (agosto 2026):

| Motor | Estado verificado | Nota que cambia decisiones |
|---|---|---|
| MongoDB | Rama 8.3.x (8.3.7, jul 2026); 9.0 en alpha. 8.0 y 7.0 con EOL 31-oct-2029 (política extendida a 4-5 años) | **Las *rapid releases* (8.1, 8.2, 8.3) solo están soportadas en Atlas, no on-prem**: autogestionado ⇒ **8.0 LTS**. 8.2 fin de soporte 31-jul-2026 |
| Apache Cassandra | 5.0.8 (abr 2026) estable; 6.0-alpha1 en desarrollo (protocolo Accord) | 5.0 trajo SAI (CEP-7) y tipo vector con ANN (CEP-30) y Unified Compaction Strategy. No llevar 6.0 a producción |
| ScyllaDB | 2026.2.x estable; 2026.3.0 en rc. Versionado por año | **Ya no hay edición open source** (§2.1) |
| DocumentDB (LF) | Proyecto de la Linux Foundation, MIT, extensiones sobre PostgreSQL (soporta hasta PG 18) | Opción real para huir de SSPL manteniendo drivers de Mongo |
| FerretDB | Última etiqueta pública verificada: v2.7.0 (nov 2025) | Cadencia a vigilar antes de apoyarse en él en producción |

### 2.1 Licencias — el dato que decide

**Regla**: ningún motor entra en un despliegue comercial, y menos en uno **ofrecido como
servicio a terceros**, sin leer su licencia vigente y registrarla en el ADR. Estado
verificado en agosto 2026:

| Motor | Licencia del código | Qué implica |
|---|---|---|
| **MongoDB Community Server** | **SSPL v1** desde octubre 2018 (retirada de la OSI en 2019; la OSI declaró en 2021 que **no** cumple la Open Source Definition). Los *drivers* sí son Apache-2.0 | Ofrecerlo **como servicio** obliga a publicar bajo SSPL todo el software de ese servicio: en la práctica, servicio gestionado propio ⇒ licencia comercial (Enterprise Advanced). **MongoDB no ha vuelto a una licencia OSI**, a diferencia de Elastic y Redis. Uso interno de la aplicación: sin obligación de publicar. Debian, RHEL y Fedora lo retiraron por esto |
| **ScyllaDB** | **Source-available** (ScyllaDB Software License Agreement) desde diciembre 2024. **6.2 fue la última release AGPL**; las anteriores siguen AGPL a perpetuidad pero sin correcciones | Free tier con **límite duro**, verbatim del FAQ oficial: *"The full-featured ScyllaDB Enterprise will be available for free with a 10TB limitation (total hard drive space of all ScyllaDB servers per organization). The maximum total amount of virtual CPUs (vCPUs, hyperthreads) of all servers across all clusters is 50."* Cualquier despliegue serio ⇒ contrato comercial. Presupuestarlo **antes** de elegirlo |
| **Apache Cassandra** | **Apache-2.0** | Sin restricción de despliegue ni de servicio. Es el default cuando la licencia es un criterio |
| **Couchbase Server** | Código bajo **BSL 1.1** (revierte a Apache-2.0 a los 4 años). Los binarios de Community Edition van bajo su propio *Community Edition License Agreement* | CE limitada a **5 nodos por clúster**, **4 cores por nodo** y **sin XDCR** (CE 7.0+): escala departamental. Derivados del código BSL heredan BSL |
| **ArangoDB** | **BUSL-1.1** desde 3.12 (antes Apache-2.0). Binarios CE bajo *ArangoDB Community License* con tope de **100 GiB** en producción y solo uso interno | Prohibido usarlo para un DBaaS/SaaS o redistribuirlo con tu producto sin acuerdo comercial |
| **DocumentDB (Linux Foundation)** | **MIT** | Sin restricciones; gobernanza vendor-neutral con TSC |
| **DynamoDB / Cosmos DB / Firestore** | Servicio gestionado propietario | La "licencia" es el contrato del proveedor y el *lock-in*: registrarlo como coste de salida (§7) |
| Valkey / Redis | *Fuera de alcance* (ver `caching-cdn-standards`): Valkey BSD-3; Redis 8+ tri-licencia AGPLv3/RSALv2/SSPL | Se cita solo para no confundir el criterio de licencia entre familias |

**PROHIBIDO** afirmar la licencia de cualquiera de estos motores de memoria: se lee la
página oficial vigente (§8). El error de licencia es el más caro de este dominio.

## 3. Modelado: es lo contrario del relacional

### 3.1 Se modela por patrón de acceso, no por entidad

- El punto de partida **no** es el diagrama entidad-relación: es la **lista de consultas**
  de la aplicación, cada una con su cardinalidad, su frecuencia y su presupuesto de
  latencia. Sin esa lista escrita, no hay diseño posible — hay adivinación.
- **Desnormalización deliberada y duplicación controlada**: el dato se copia donde se lee.
  Cada duplicado es una invariante que la aplicación —no el motor— debe mantener: se
  documenta qué copia es la fuente de verdad, quién la propaga y qué pasa si la propagación
  falla a medias (no hay FK ni JOIN que te salven).
- **Agregado = límite de transacción y de lectura**: si dos cosas se leen y escriben juntas
  y su tamaño está acotado, van en el mismo documento/partición; si crecen sin cota
  (comentarios, eventos, histórico), **no** se anidan: el documento ilimitado es el
  anti-patrón clásico (en DynamoDB, además, es imposible: máximo **400 KB por ítem**).
- **Cambiar el patrón de acceso después suele significar remodelar y migrar todos los
  datos**, no añadir un índice. Es la diferencia estructural con el relacional y la razón
  por la que un dominio en exploración —donde nadie sabe aún cómo se va a consultar— es
  el peor candidato posible para un NoSQL.
- "Esquema flexible" **no** significa "sin contrato": el esquema existe, y si no está en el
  motor está —implícito y sin validar— en el código. Contrato explícito y versionado
  siempre: JSON Schema validado en el borde, `$jsonSchema` en la colección, tipos
  declarados en CQL. Campo nuevo ⇒ aditivo y con default; migración de forma ⇒ misma
  disciplina expand/contract que en SQL, con doble lectura durante la transición.

### 3.2 Diseño de clave (lo que decide el rendimiento y la factura)

- **Clave de partición**: determina la distribución. Se elige por **cardinalidad alta y
  tráfico uniforme**, no por "es el id de la entidad principal". Claves de baja
  cardinalidad (estado, país, tenant grande, `true/false`, fecha del día) producen
  ***hot partitions***: el clúster está al 10% y el usuario ve throttling.
- **Clave de ordenación** (sort key / clustering key): define el rango consultable barato.
  Se diseña como una **jerarquía de prefijos** (`ORG#123#PROJ#7#TASK#9`) para que un solo
  `begins_with` sirva a varias consultas.
- Límites que condicionan el diseño en DynamoDB (verificados; re-verificar en §8): ítem
  **400 KB**; **3.000 RCU / 1.000 WCU por partición** (con *adaptive capacity* automática,
  que mitiga pero no elimina el problema de una clave caliente); **5 LSI** y **20 GSI** por
  tabla por defecto; 40.000 RU/WU por tabla por defecto; 2.500 tablas por región (ampliable
  a 10.000).
- Mitigación de claves calientes: *write sharding* con sufijo acotado (`#1..#N`) y
  dispersión en lectura, o cambio de clave — nunca "confiar en que el motor lo reparta".
- **Cassandra/ScyllaDB**: la *partition key* acota el trabajo de una consulta; particiones
  gigantes (cientos de MB, millones de celdas) matan latencias y compactación. Consultar
  siempre por clave de partición; `ALLOW FILTERING` está **prohibido** en producción. Los
  índices secundarios nativos son una trampa a escala: modelar tabla por consulta, o SAI
  (Cassandra 5.0) con medición.
- **Diseño de tabla única (single-table) en DynamoDB**: es la técnica correcta para
  resolver varias entidades y accesos con menos peticiones y transacciones baratas, y es
  **caro en cognición**: nombres de atributos genéricos (`PK`/`SK`/`GSI1PK`), ilegible
  fuera del código que lo interpreta, difícil de explorar ad-hoc y muy rígido ante un
  patrón de acceso nuevo. Adóptalo cuando el patrón de acceso sea estable y esté escrito;
  con dos o tres entidades y accesos simples, varias tablas son más honestas. En ambos
  casos, el mapa de acceso→clave se documenta junto al código: sin él, la tabla es
  ilegible en 6 meses.

### 3.3 Consistencia: es una decisión de producto

- **CAP sin misticismo**: ante una partición de red, el sistema elige responder con datos
  posiblemente obsoletos (AP) o rechazar la petición (CP). **PACELC** añade lo que de
  verdad se paga a diario: *else*, sin partición, se elige entre **latencia** y
  **consistencia**. La mayoría de estos motores son configurables por operación: la
  decisión no es del motor, es **tuya y por consulta**.
- **"Eventual" en la práctica** significa: puedes leer tu propia escritura y no verla;
  dos lectores pueden ver estados distintos; un contador puede retroceder; y una
  reconciliación tardía puede borrar lo que el usuario acababa de escribir. Todo eso hay
  que **decidirlo con el dueño del producto**, no esconderlo en un YAML. Lo que no tolera
  obsolescencia (saldo, stock, permisos, límites de crédito, unicidad) no se resuelve con
  lectura eventual — y a menudo tampoco con este tipo de almacén.
- Palancas concretas: DynamoDB con lectura fuertemente consistente (`ConsistentRead=true`,
  el doble de coste, solo en la región de la tabla, no en GSI) frente a la eventual por
  defecto; global tables con **MREC** (eventual) o **MRSC** (fuerte multi-región, con sus
  cuotas); Cassandra/ScyllaDB con `LOCAL_QUORUM` en RF=3 por DC como base sana (R+W>RF), y
  `ONE` solo donde la obsolescencia sea aceptable y explícita; MongoDB con `writeConcern`
  `majority` + `readConcern` `majority` y lecturas en primario por defecto (`readPreference
  secondary` solo con lag asumido).
- **Transacciones donde existen y sus límites**: MongoDB tiene transacciones multi-documento
  y distribuidas (con coste, ventana temporal acotada y contención propia); DynamoDB tiene
  transacciones acotadas por petición y de coste doble; Cassandra tiene LWT (Paxos, caro) y
  Accord en desarrollo para 6.0. **Ninguna** sustituye a un relacional para lógica
  transaccional densa: si el dominio necesita transacciones a menudo, el motor está mal
  elegido.
- Sin FK ni JOIN, la integridad la sostiene la aplicación: unicidad con ítem/documento
  centinela e inserción condicional (`attribute_not_exists`, índice único), idempotencia
  por clave natural en toda escritura reintentable, y un **reconciliador** que detecta
  divergencias entre copias duplicadas. Ese reconciliador es parte del entregable, no un
  extra.

## 4. Calidad y gates

Gates de CI, en orden de coste creciente. Rompen el build:

1. **Contrato de esquema versionado en el repo** (JSON Schema / `$jsonSchema` / DDL CQL) y
   validación de compatibilidad hacia atrás en cada PR. Sin contrato, no se mergea.
2. **Mapa de patrones de acceso** actualizado como fichero del repo: cada consulta de la
   aplicación mapeada a clave/índice. Una consulta nueva sin entrada en el mapa es un fallo
   de revisión, no un detalle.
3. **Tests de integración contra el motor real** (Testcontainers, DynamoDB Local): jamás
   contra un mock del driver ni un stub en memoria — los dialectos y los límites mienten.
   Cubrir camino feliz **y bordes**: ítem al límite de tamaño, clave inexistente, escritura
   condicional que falla, reintento duplicado, paginación con `LastEvaluatedKey`/cursor.
4. **Test de consistencia explícito**: al menos un test que documente el comportamiento
   bajo lectura eventual (leer justo después de escribir) para que la decisión de §3.3 sea
   verificable y no folclore.
5. **Detección de escaneos**: prohibido `Scan` sin filtro de clave, `ALLOW FILTERING` y
   `find()` sin índice en el camino caliente. Linter o revisión mecánica sobre las
   consultas; en MongoDB, `notablescan` en entornos de prueba para que falle en CI.
6. **Prueba de carga con datos representativos y distribución realista** (incluidas las
   claves calientes): un plan con 1.000 documentos no predice nada a 100 M. Medir p99, no
   media.
7. **Restore probado** del respaldo (§6) con cadencia programada: es un gate de entrega,
   no una tarea de operaciones.

## 5. Seguridad

- **Autenticación y autorización siempre activas**: estos motores han protagonizado fugas
  masivas precisamente por instancias sin autenticación expuestas a Internet. `bindIp`
  restringido, nunca `0.0.0.0` accesible desde fuera; red privada + firewall de egreso e
  ingreso; **jamás** un puerto de base de datos publicado en Internet, ni siquiera "un
  momento para probar".
- **TLS en tránsito** entre clientes y nodos **y entre nodos** (Cassandra/Scylla:
  `internode_encryption`); **cifrado en reposo** con claves en KMS y rotación (ver
  `cryptography-pki-standards`).
- **Mínimo privilegio con roles por aplicación**, distintos de los de administración y de
  los de analítica. Ojo con los bypass de RBAC a nivel de consulta: CVE-2026-13059 en
  MongoDB (CVSS 8.6) permitía a un usuario de bajo privilegio saltarse controles de
  `find`/`update`/`delete`/`aggregate` — el RBAC del motor se parchea, no se supone.
- **Inyección**: sí existe fuera de SQL. Nunca construir filtros a partir de entrada del
  usuario sin tipar (operadores `$where`, `$ne`, `$gt` inyectados desde JSON del cliente);
  `$where` y la ejecución de JavaScript en servidor, **desactivados**. En CQL, siempre
  sentencias preparadas con parámetros.
- **CVE y parcheo** (verificados en agosto 2026, re-verificar en §8): MongoDB acumuló en
  2026 vulnerabilidades de severidad alta —CVE-2026-13072 (CVSS 9.2, corrupción de memoria
  con *compute mode* activo), CVE-2026-9740 (8.7, alcanzable sin autenticar), CVE-2026-8053
  (colecciones time-series)— con corrección en **7.0.39 / 8.0.28 / 8.2.12 / 8.3.7**; y
  **MongoBleed (CVE-2025-14847)**, fuga de memoria sin autenticar vía mensajes comprimidos,
  **entró en el catálogo KEV de CISA** (explotación activa confirmada). Cassandra: revisar
  CVE-2025-23015 (escalada a superusuario con `MODIFY ON ALL KEYSPACES`), cuyo parche se
  aplicó mal en 4.0.16 — corregido en 4.0.17. Suscribirse a los avisos del motor es
  obligatorio, no opcional.
- **Cadena de suministro de los drivers**: no hay incidente conocido específico de estos
  motores, pero npm y PyPI viven bajo campañas de gusano recurrentes (Shai-Hulud/TeamPCP,
  TrapDoor en 2026, incluidos paquetes maliciosos **con procedencia SLSA válida**).
  Fijar drivers por versión y hash en el lockfile, SCA en CI y revisión de cualquier salto
  de versión mayor.
- **Datos personales**: sin JOIN ni FK, el borrado es una **búsqueda por todas las copias**
  (§3.1) — el derecho de supresión se diseña con el modelo, no después. Documentos y
  particiones duplicadas, índices secundarios, streams, backups y réplicas cross-region
  cuentan. Donde el borrado físico no sea viable en ventana, crypto-shredding por sujeto
  (ver `privacy-engineering-standards`).

## 6. Operación, rendimiento y coste

- **Réplicas y particiones**: RF=3 como base con conciencia de zona/rack
  (`NetworkTopologyStrategy`, rack awareness); MongoDB con replica set de 3 miembros y
  árbitros **evitados**. Añadir o quitar nodos es **rebalanceo**: costoso en red y en E/S,
  planificado en ventana y medido, nunca improvisado en incidente.
- **Compactación y amplificación de escritura (LSM)**: en Cassandra/ScyllaDB (y en el
  motor de almacenamiento de muchos documentales) cada escritura se reescribe varias veces
  al compactar. Consecuencias que hay que presupuestar: espacio libre suficiente para
  compactar (regla práctica: no llenar el disco por encima del 50-70% según estrategia),
  E/S y CPU reservadas, y elección consciente de estrategia (UCS en Cassandra 5.0,
  size-tiered vs leveled según lectura/escritura). **Tombstones**: los borrados son
  escrituras; una carga de borrado masivo genera lecturas lentas y timeouts hasta
  `gc_grace_seconds` — el borrado se diseña (TTL, particionado por tiempo y drop), no se
  improvisa.
- **Reparación/anti-entropía** como tarea programada y monitorizada (`nodetool repair`
  incremental o herramienta del ecosistema; Cassandra 5.0.x incorpora reparación
  automatizada retroportada de 6.0). Una réplica no reparada es datos divergentes en
  silencio.
- **Respaldo y restauración**: snapshot + copia fuera del clúster, cifrada, con una copia
  inmutable u offline (3-2-1). **El gate es el restore**, y en estos motores el restore
  suele implicar reconstruir topología y token ranges: ensáyalo completo, cronometrado, y
  registra el tiempo real como SLI. En DynamoDB, PITR es una casilla que **hay que
  activar** y tiene ventana propia; la copia a otra cuenta/región es decisión aparte.
- **Actualizaciones de versión mayor**: leer las release notes completas, ensayar en
  staging con datos representativos, rolling upgrade nodo a nodo con compatibilidad de
  protocolo verificada, y **rollback definido y probado** (que en muchos motores no es
  reversible tras migrar el formato de sstables/ficheros: si no hay vuelta atrás, la
  estrategia es clúster paralelo y doble escritura). Nunca una `.0` en producción. Y ojo al
  soporte real: en MongoDB autogestionado, las *rapid releases* no están soportadas (§2).
- **Observabilidad mínima**: latencia p99 por operación, tasa de throttling/timeout, lag de
  réplica, distribución de tráfico por partición (para ver las claves calientes **antes**
  del incidente), tamaño de partición máximo, pendientes de compactación, tombstones por
  lectura, y consumo frente a capacidad. Alertas por síntoma con runbook.
- **Coste — el patrón de acceso es la factura**:
  - Modelo **por petición (on-demand)** frente a **por capacidad aprovisionada**: en
    DynamoDB, tras la bajada de precios de noviembre de 2024 (−50% on-demand, hasta −67% en
    global tables), **on-demand es el default razonable** para la mayoría de cargas; el
    aprovisionado gana con tráfico muy predecible y estable. Existen *Database Savings
    Plans* (desde diciembre 2025, ~12-18%) y capacidad reservada, cada uno con su alcance.
    Re-verificar precios y descuentos antes de modelar (§8).
  - Un modelado malo **multiplica** la factura sin cambiar una línea de negocio: `Scan` en
    vez de `Query`, GSI proyectando `ALL` cuando bastaba `KEYS_ONLY`, ítems grandes leídos
    enteros para usar un campo, escrituras replicadas en regiones que nadie lee, o un
    documento que crece hasta consumir varias unidades por lectura.
  - Presupuesto de coste **por consulta** en los caminos calientes, medido en producción y
    revisado trimestralmente junto al de latencia. En NoSQL, coste y modelo son lo mismo.
- **Capacidad**: proyecta crecimiento de datos y de tráfico con datos reales; el momento de
  añadir nodos es antes de que la compactación no llegue, no cuando el disco esté al 85%.

## 7. Sostenibilidad, salida y prohibiciones

- **ADR obligatorio** para: elección del motor (con el "por qué no PostgreSQL" respondido),
  clave de partición y ordenación, tabla única vs múltiple, nivel de consistencia por
  operación, política de retención y **licencia vigente en el momento de decidir**.
- **Re-evaluar la licencia en cada upgrade mayor**: este dominio ha cambiado de licencia
  tres veces en dos años (ScyllaDB 2024, ArangoDB 3.12, Redis 2024-2025). Un upgrade puede
  cambiar tus obligaciones legales sin cambiar una línea de tu código.
- **Salida y migración de vuelta a relacional** cuando la decisión fue errónea (síntomas:
  cada funcionalidad nueva exige remodelar; la aplicación reimplementa JOINs en memoria;
  proliferan reconciliadores; la factura crece más rápido que el tráfico; nadie sabe
  responder una consulta ad-hoc del negocio). Procedimiento:
  1. Fija el patrón de acceso real observado en producción (no el imaginado) y modela el
     esquema relacional destino, **normalizando** lo que se duplicó.
  2. Carga inicial en bloque + **CDC/stream** del motor origen (Change Streams, DynamoDB
     Streams, CDC de Cassandra) hacia el destino, hasta alcanzar lag estable.
  3. Doble escritura o *shadow reads* con comparación automática de resultados durante un
     periodo con tráfico real; el corte se hace cuando la divergencia es cero y medida.
  4. Conmutación por *feature flag*, con vuelta atrás disponible, y retirada del motor
     viejo **como parte del proyecto** (si no, quedan dos almacenes para siempre).
  - Migración parcial válida y a menudo la mejor: dejar en el NoSQL solo la carga que
    justificaba §1 y llevar el resto a PostgreSQL.

**PROHIBIDO**
- ❌ Elegir NoSQL **por la forma del dato** (jerárquico, anidado, "campos variables"): eso
  es `jsonb` + GIN en PostgreSQL.
- ❌ Adoptarlo sin ADR con la necesidad **medida** de §1 y sin el "por qué no PostgreSQL".
- ❌ Modelar **por entidad** (copiar el modelo relacional al documental) o empezar a modelar
  sin la lista escrita de patrones de acceso.
- ❌ "Esquema flexible" como excusa para no tener contrato ni validación.
- ❌ Documentos, arrays o particiones que crecen **sin cota**.
- ❌ Claves de partición de baja cardinalidad o con tráfico sesgado, sin mitigación.
- ❌ `Scan` sin filtro de clave, `ALLOW FILTERING`, o consultas sin índice en camino caliente.
- ❌ Índices secundarios nativos de Cassandra a escala sin medición; GSI con proyección
  `ALL` "por si acaso".
- ❌ Prometer consistencia fuerte que el motor no da, o esconder la eventual al negocio.
- ❌ Usar el NoSQL como almacén transaccional del dinero/stock sin idempotencia ni unicidad
  garantizada en el motor.
- ❌ Instancia sin autenticación, con `0.0.0.0` alcanzable o sin TLS entre nodos.
- ❌ `$where`/JavaScript en servidor, o filtros construidos con entrada del usuario sin tipar.
- ❌ Autogestionar MongoDB en una *rapid release* (no soportada fuera de Atlas).
- ❌ Borrado masivo sin plan de tombstones/compactación, o desactivar la reparación.
- ❌ Backup sin restore ensayado y cronometrado; PITR sin activar creyendo que viene puesto.
- ❌ Upgrade mayor sin ensayo, sin release notes y sin ruta de rollback definida.
- ❌ Desplegar un motor **source-available** (SSPL, BUSL, licencia de ScyllaDB) en producto
  comercial o como servicio sin revisión legal y sin registrar la obligación en el ADR.
- ❌ Afirmar versiones, EOL o **licencias** de memoria, sin la verificación de §8.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un entregable:

1. **Licencia vigente de cada motor** en su página oficial (`mongodb.com/legal/licensing`,
   FAQ de licencia de ScyllaDB, licencia de Couchbase CE, licencia de ArangoDB): es el dato
   que más cambia y el que más caro sale equivocar. Verificar también los límites numéricos
   del free tier (10 TB / 50 vCPU en ScyllaDB, 5 nodos / 4 cores en Couchbase CE, 100 GiB
   en ArangoDB CE) **verbatim**, no de resumen.
2. **Versión estable, política de releases y EOL**: MongoDB (¿sigue 8.0 la LTS on-prem?
   ¿ha salido 9.0 GA?), Cassandra (¿6.0 GA?), ScyllaDB (¿2026.3 estable?), DocumentDB y
   FerretDB (cadencia real de releases).
3. **CVE abiertos y versiones de parche** de los motores a recomendar, y presencia en el
   **catálogo KEV de CISA** (MongoBleed lo estaba en agosto 2026).
4. **Precios y modelos de facturación** de DynamoDB/Cosmos DB/Firestore y sus descuentos
   por compromiso: cambian y determinan el diseño.
5. **Cuotas y límites duros** del servicio gestionado (tamaño de ítem, throughput por
   partición, número de índices): un límite es una restricción de diseño, no un detalle.
6. **Incidentes de cadena de suministro** en los drivers y ODM que se vayan a usar.

**Huecos declarados** (no verificados en la sesión de agosto 2026; **no rellenar de
memoria**, verificar antes de usar):
- **Versión estable actual de Couchbase Server** y estado de su Community Edition en 2026
  (solo se verificó el modelo de licencia y sus límites, no la versión ni cambios recientes).
- **Estado de MongoDB 9.0** más allá de la existencia de etiquetas alpha.
- **Compatibilidad real de ScyllaDB con la versión actual de CQL/Cassandra 5.0** (SAI,
  tipo vector): no verificada.
- **Estado de actividad de FerretDB** tras v2.7.0 (nov 2025): no verificado si la cadencia
  se ha reanudado o el proyecto ha cambiado de modelo.
- **Cosmos DB y Firestore**: no se verificó ningún dato específico (cuotas, modelos de
  consistencia, precios) — tratar todo lo relativo a ellos como no verificado aquí.
- **CVE de Couchbase, DynamoDB y DocumentDB**: no revisados.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
