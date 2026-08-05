---
name: streaming-cdc-standards
description: Use when changes must be captured from a database or processed in motion — deciding whether streaming is warranted at all versus an incremental batch every 15 minutes, capturing from the transaction log (PostgreSQL pgoutput/wal2json logical decoding and replication slots, MySQL/MariaDB binlog and GTID, Oracle LogMiner, SQL Server CDC, MongoDB change streams) versus triggers or timestamp polling, running Debezium (Debezium Server, Debezium Engine, Kafka Connect connectors, signals, tombstone records, snapshot.mode and incremental snapshots) or Flink CDC, initial snapshot cost and resume after a crash, an inactive slot retaining WAL until pg_wal fills the disk (max_slot_wal_keep_size, idle_replication_slot_timeout, safe_wal_size, wal_status), why table-change events are not domain events and must not become a public contract, at-least-once versus at-most-once versus exactly-once and consumer idempotency, ordering guaranteed only per partition and choosing the partition key, schema evolution when the source adds or drops a column, event time versus processing time, windows, watermarks, late data and keyed state in Apache Flink, Kafka Streams or Spark Structured Streaming, consumer lag as the primary SLI, replay from the beginning of the log, dead-letter queues, or how long the log is retained.
---

# Estándares de streaming y captura de cambios (CDC)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: "tiempo real" es, junto con "lakehouse", la etiqueta más vendida y peor
> justificada del sector. **Un lote incremental cada 15 minutos resuelve la inmensa mayoría de los
> "requisitos de tiempo real"**, y el streaming no es un modo de ejecución: es una **operación
> permanente** que alguien tiene que vigilar todas las noches del año. Empieza por demostrar que
> hace falta.

## 1. Alcance y triggers

Aplica a **capturar cambios de un sistema de origen** y a **procesarlos en movimiento**: la decisión
de si hace falta streaming, el mecanismo de captura, la operación del capturador y su impacto en el
origen, la semántica de entrega, el orden, la evolución de esquema del flujo, el procesamiento con
estado y tiempo, y la operación y el coste de todo ello.

Disparadores: `debezium`, `debezium-server`, `DebeziumEngine`, `io.debezium.connector.*`,
`snapshot.mode`, `signal.data.collection`, `tombstone`, `transforms=unwrap`,
`ExtractNewRecordState`, `pgoutput`, `wal2json`, `CREATE PUBLICATION`,
`pg_create_logical_replication_slot`, `pg_replication_slots`, `slot_name`, `restart_lsn`,
`wal_status`, `safe_wal_size`, `max_slot_wal_keep_size`, `idle_replication_slot_timeout`,
`REPLICA IDENTITY FULL`, `binlog`, `gtid`, `server-id`, `LogMiner`, `change streams`,
`kafka-connect`, `connect-distributed.properties`, `consumer lag`, `auto.offset.reset`,
`enable.idempotence`, `isolation.level=read_committed`, `transactional.id`, `StreamsBuilder`,
`KTable`/`KStream`, `readStream`/`writeStream`, `withWatermark`, `checkpointLocation`,
`StreamExecutionEnvironment`, `KeyedProcessFunction`, `WatermarkStrategy`, `savepoint`,
`checkpoint`, `DLQ`/`dead letter`, y las frases del dominio: "lo queremos en tiempo real", "el disco
del primario se ha llenado", "el conector lleva parado desde el viernes", "faltan los borrados",
"llegan eventos duplicados", "los eventos llegan desordenados", "hay que reprocesar todo el
histórico", "el origen añadió una columna y se rompió el consumidor".

**No aplica**: ver
- `data-platform-standards` (**madre**): **Kafka como motor es suyo** —particiones del topic,
  retención, réplicas, `min.insync.replicas`, KRaft— y también el **registro de esquemas** (Karapace,
  Apicurio, Confluent Schema Registry) y **PostgreSQL como motor** con su replicación, HA y PITR.
  Aquí, **qué se publica en esos topics, con qué garantías y qué se hace con el flujo**. Su
  principio —**un almacén por necesidad, no por moda**— se hereda como **"un flujo por necesidad,
  no por moda"** (§2.1).
- `message-brokers-standards` (**Ola 4, planificada**) — **es la colisión más probable de este par y
  la línea se escribe aquí con precisión**: **el broker como pieza es suyo** (Kafka, Pulsar,
  RabbitMQ, NATS: elección, topología, dimensionado, replicación, retención, operación del clúster,
  colas frente a logs). **El procesamiento del flujo y la captura de lo que entra en él son de
  aquí.** Regla de corte mecánica: **si la decisión la toma el broker, es suya; si la toma el
  productor, el consumidor o el procesador, es de aquí.** "¿Cuántas particiones aguanta el clúster?"
  es suya; "¿qué clave de partición elijo y qué orden me garantiza?" es de aquí.
- `microservices-architecture-standards` (**frontera crítica; ver §3.3, es el error de diseño más
  caro del dominio**): **el patrón outbox, las sagas, los eventos de dominio y la propiedad del dato
  por servicio son suyos**. Un **evento de dominio** lo diseña y publica la aplicación dueña del
  dato; un **cambio de fila capturado por CDC no es un evento de dominio**. Aquí, el mecanismo de
  captura y transporte —incluido el CDC **sobre la tabla outbox**, que es su uso correcto.
- `lakehouse-standards` (**hermana; frontera declarada en ambos lados**): **qué le pasa a la tabla
  cuando los cambios aterrizan** es suyo —*copy-on-write* frente a *merge-on-read*, coste de
  `MERGE`/`DELETE`, ficheros y vectores de borrado, compactación, snapshots, catálogo—. Aquí, **cómo
  se capturan los cambios y cómo se procesan hasta llegar allí**. **El CDC es una fuente típica del
  lakehouse, no la única** (el lakehouse se alimenta igual por lotes) y **el lakehouse no es el
  único destino del CDC** (una réplica, una caché, un índice de búsqueda, otro servicio). Ninguna
  presupone a la otra.
- `data-engineering-standards` (**hermana**): la ingesta por lotes, la orquestación, la marca de
  agua de un incremental, la idempotencia del job, el *backfill* y el formato de fichero. Ella fija
  **cuándo la captura de cambios es la respuesta**; aquí **cómo se hace bien**. Su regla espejada:
  el **formato de fichero** es suyo, el **formato de tabla** es de `lakehouse-standards`.
- `data-governance-quality-standards` (**ya en disco**): **contratos de datos, propiedad, catálogo,
  linaje y calidad como programa son suyos**. Aquí, su ejecución en el flujo: qué esquema se publica,
  quién es el productor responsable y qué aserciones desvían un evento a la cola de fallidos. Regla
  de corte: si la pregunta es "¿quién es el dueño y qué promete el contrato?", es suya; si es "¿qué
  hace el consumidor cuando llega un evento que lo incumple?", es de aquí.
- `data-warehouse-modeling-standards`: el modelo destino. **Un flujo de cambios no es una SCD2**: la
  historización dimensional es una decisión de modelado suya; aquí solo se entrega el cambio.
- `privacy-engineering-standards`: **dato personal, minimización, retención y borrado son suyos**.
  Aquí su restricción técnica: un cambio publicado en un log con retención larga **es una copia más
  del dato personal**, y un `DELETE` en el origen **no borra los eventos anteriores del log** (§5).
- `observability-standards`: instrumentación, OTel, cardinalidad y el backend de métricas. Aquí,
  **qué medir** en un flujo (§6).
- `sre-practice-standards` (SLO, error budget, guardia), `incident-management-standards`,
  `backup-recovery-standards` (**el log de eventos no es una copia de seguridad**),
  `bcdr-standards`, `kubernetes-standards`, `iac-standards`, `cicd-standards`,
  `secrets-management-standards`, `identity-access-management-standards`,
  `grc-compliance-standards`, `mlops-standards`, `nosql-standards`, `search-engines-standards`,
  `vector-db-standards`, `graph-db-standards`, `timeseries-db-standards`,
  `oracle-dba-standards`/`sqlserver-dba-standards`/`mysql-mariadb-dba-standards` (el **tuning y la
  operación del motor de origen** son suyos; aquí solo lo que el CDC le exige. Regla de arbitraje
  espejada con `mysql-mariadb-dba-standards`: **la captura es de aquí, el impacto en el motor es
  suyo** — el formato de GTID, el `binlog` como mecanismo del motor y su purga son suyos; leerlo
  como flujo de cambios, es de aquí), `aws-standards`/`azure-standards`/`gcp-standards` (MSK, DMS, Kinesis, Event Hubs,
  Pub/Sub, Datastream como servicios gestionados), `python-standards`, `jvm-spring-standards`
  (**calidad del código Java/Kotlin**: Flink y Kafka Streams son JVM y su *build*, tests y
  empaquetado son suyos; el diseño del flujo es de aquí), `scala-standards` (misma frontera para
  la API Scala de Flink y de Kafka Streams), `sql-standards` (**Ola 5**: Flink SQL y ksqlDB tienen
  semántica de streaming propia —ventanas, marcas de agua, tablas dinámicas— **que es de aquí**; el
  SQL relacional que se escriba contra un sumidero es suyo).

**Principio rector**: **el streaming no se paga en cómputo, se paga en operación continua.** Un lote
que falla se reintenta mañana; un flujo que falla acumula retraso, retiene recursos en el origen y
degrada mientras nadie mira. Antes de adoptarlo, la pregunta no es "¿puedo?", es **"¿quién lo
vigila a las 3 de la madrugada de un domingo de agosto?"**.

## 2. Decisiones por defecto

> Verificar versión, licencia y propiedad por web antes de fijarlo en un proyecto real (§8). En
> 2026 este subsector cambió de manos: **IBM completó la adquisición de Confluent el 17-mar-2026**.

### 2.1 La decisión de partida: ¿de verdad necesitas streaming?

Agota esta escalera **antes** de introducir un flujo. Cada escalón evitado es una operación
permanente que no asumes:

| Necesidad expresada | Solución más simple | Cuándo deja de servir de verdad |
|---|---|---|
| "Lo queremos en tiempo real" (para un informe que se mira por la mañana) | **Lote incremental por marca de agua** (ver `data-engineering-standards`) | Nunca deja de servir. Este caso **no es streaming** |
| Latencia de minutos, volumen moderado | **Lote incremental cada 5-15 minutos** | Cuando la fuente no tiene marca de agua fiable, o hay que capturar borrados |
| Consultar el dato operacional con retraso mínimo | **Réplica de lectura** del propio motor (ver `data-platform-standards`) | Cuando el destino es otro motor, u otro modelo de datos |
| Necesitas **borrados**, orden y el histórico completo de cambios | **CDC** desde el log de transacciones | — |
| Alguien o algo **actúa en segundos** sobre el evento (fraude, existencias, alertas, precios) | **Streaming** con procesamiento con estado | — |

Dos preguntas que resuelven la mayoría de las discusiones:

1. **¿Qué decisión cambia si el dato llega en 5 segundos en vez de en 15 minutos, y quién la toma?**
   Si la respuesta es "ninguna" o "nadie", el requisito de tiempo real no existe.
2. **¿Cuál es el coste de que el flujo se pare 4 horas un domingo?** Si es "ninguno", tampoco
   necesitas streaming. Si es "grave", necesitas **guardia**, no solo tecnología.

**Regla honesta**: el CDC es **la respuesta correcta a un problema distinto del tiempo real**. Su
valor real suele ser **capturar borrados y cambios rápidos con fidelidad**, no la latencia. Muchos
proyectos que "necesitan streaming" en realidad necesitaban CDC volcando a un destino por
micro-lotes.

### 2.2 Cómo se captura: el mecanismo importa más que la herramienta

| Mecanismo | Cómo funciona | Veredicto |
|---|---|---|
| **Lectura del log de transacciones** (WAL de PostgreSQL, binlog de MySQL/MariaDB, LogMiner de Oracle, CDC de SQL Server, *change streams* de MongoDB) | Lee el registro de escritura del motor: ve **todas** las operaciones, en orden de *commit*, con antes y después | **La forma correcta.** Sin impacto en el esquema, captura borrados, respeta el orden transaccional. **Default absoluto** |
| **Triggers** que escriben en una tabla de auditoría | El motor ejecuta código en cada escritura | **Vetado salvo imposibilidad del log.** Penaliza **cada** transacción del sistema operacional, se salta operaciones masivas mal escritas, ensucia el esquema y se olvida al crear una tabla nueva |
| **Consulta por marca de tiempo** (`WHERE updated_at > :x`) | Sondeo periódico | **No es CDC.** **Pierde los borrados físicos** (para siempre y en silencio) y **pierde los cambios múltiples entre sondeos** (solo ves el último estado). Además, `updated_at` casi nunca es fiable: relojes desalineados, actualizaciones masivas que no lo tocan, escrituras que confirman fuera de orden. Legítimo solo como **incremental por lotes**, sabiendo qué se está perdiendo |
| **Doble escritura** desde la aplicación (BD y luego broker) | La app escribe en los dos sitios | **PROHIBIDO** (§7): no es atómico. Ver outbox en `microservices-architecture-standards` |

**Aviso sobre las marcas de agua y el orden de confirmación**: incluso con `updated_at` perfecto, una
transacción larga puede confirmar **después** de que tu ventana ya haya pasado por su marca de
tiempo. Sin solape de ventana, esa fila no se ingiere nunca. Es la pérdida silenciosa clásica y es
uno de los argumentos más sólidos a favor del log.

### 2.3 Toolchain

| Ámbito | Default | Estado verificado (ago 2026) | Alternativa justificable |
|---|---|---|---|
| Capturador CDC | **Debezium 3.6.x** | 3.6.0.Final (1-jul-2026); 3.7.0.Alpha1 en curso. **Apache 2.0** (verificado en el repositorio). Estándar de facto, respaldo de Red Hat | **Flink CDC** (Apache 2.0) si el procesamiento ya es Flink y quieres un solo sistema |
| Ejecución del capturador | **Debezium Server** (autónomo) si no necesitas Kafka Connect | Existe y está mantenido; en la serie 3.6 se está **migrando del motor embebido antiguo a la extensión Quarkus** (`debezium-quarkus-engine`), con control de ciclo de vida para *hot standby* con bloqueo externo. **Ojo: es una migración arquitectónica en curso, no un modo consolidado** | **Kafka Connect distribuido** cuando ya operas Connect: sigue siendo la vía más probada y la que más ojos ha visto |
| Broker | **Kafka** (la pieza y su operación son de `data-platform-standards` / `message-brokers-standards`) | Kafka 4.3.1 (jun-2026), Apache 2.0, ASF. **La adquisición de Confluent por IBM no cambia la licencia de Kafka**: el proyecto es de la ASF y su PMC es independiente | — |
| Procesamiento con estado, exigente | **Apache Flink 2.3.0** | 2.3.0 estable según la página oficial de descargas (jun-2026); 2.2.1, 2.1.3 y 1.20.5 también publicadas. **No pierde la corona técnica, pero sí equipos nuevos** por su complejidad operativa: exige gente dedicada | **Servicio gestionado de Flink** si no tienes plataforma |
| Procesamiento embebido en un servicio JVM | **Kafka Streams** | Vivo. Sin clúster propio; **acotado por el número de particiones** y con gestión de tiempo/datos tardíos menos sofisticada que Flink | — |
| Procesamiento donde ya hay Spark | **Spark Structured Streaming** | Vivo (Spark 4.2.0, jul-2026). Micro-lotes: latencia de segundos, no de milisegundos. Gana por inercia si el equipo ya es Spark | — |
| Motores SQL-first gestionados (RisingWave, Materialize, Decodable, ksqlDB…) | — | Reducen mucho la carga operativa a cambio de flexibilidad y de dependencia | Válidos con ADR y plan de salida |
| Formato de evento | **Avro o Protobuf con registro de esquemas** | El registro es de `data-platform-standards` | JSON solo con validación en CI |

**Criterio de elección del procesador, en una línea cada uno**:
- **Flink** si hay **estado grande, semántica de tiempo de evento seria y datos tardíos que
  importan**, y tienes quien lo opere.
- **Kafka Streams** si es una **aplicación JVM que ya vive dentro de Kafka** y no quieres otro
  clúster.
- **Spark Structured Streaming** si **ya operas Spark** y la latencia de segundos basta.
- **Ninguno** si lo que necesitabas era un lote incremental (§2.1). Es la respuesta correcta más
  veces de las que se admite.

**Motores retirados o en decadencia — no los elijas para algo nuevo**: Spark Streaming clásico
(DStreams) está obsoleto frente a Structured Streaming; Apache Apex está sin desarrollo desde 2019;
Samza no publica desde 2023; Storm se mantiene pero rara vez es la elección correcta hoy.

**Riesgo de propiedad y licencia**: **IBM completó la compra de Confluent el 17-mar-2026** (unos
11.000 M$; WarpStream incluida). Kafka como proyecto no se ve afectado, pero **la Confluent Community
License** —que cubre Schema Registry, REST Proxy, ksqlDB y varios conectores— **no es OSI open
source** y prohíbe ofrecerlos como servicio competidor. Con el nuevo dueño, el modelo de precios y
soporte es un riesgo a vigilar, no un hecho consumado (§8). Consecuencia práctica: **prefiere
Karapace o Apicurio** para el registro (criterio ya fijado en `data-platform-standards`) y registra
en el ADR de qué componentes con licencia no-OSI dependes.

## 3. Estructura y convenciones

### 3.1 CDC en la práctica: la instantánea inicial y la reanudación

- **La instantánea inicial es el momento más caro y más peligroso de todo el proyecto**: leer la
  tabla entera de un sistema en producción. Reglas:
  - **Lee de una réplica** siempre que el mecanismo lo permita; si no, planifícala en ventana de
    baja carga, con lectura acotada y `statement_timeout`.
  - **Prefiere la instantánea incremental** (por trozos, reanudable, en paralelo con el flujo) a la
    bloqueante. Una instantánea que no se puede reanudar se convierte en cinco reintentos de doce
    horas.
  - **Mide y presupuesta cuánto tarda antes de ejecutarla en producción.** Es el dato que decide si
    el proyecto es viable.
  - **La reinstantánea tiene que ser una operación planificada y ensayada** (señales / *ad hoc
    snapshot*), no un accidente: la vas a necesitar cuando se invalide un slot o se pierda una
    posición.
- **Reanudación tras caída**: el capturador guarda su **desplazamiento** (LSN, GTID, *resume token*)
  de forma durable y externa a su proceso. Reglas: el almacén de desplazamientos entra en la copia
  de seguridad; **si se pierde, el precio es una nueva instantánea completa**; y **el
  desplazamiento se confirma después de entregar, nunca antes** — al revés se pierden cambios en
  silencio, así solo se duplican (y para eso está la idempotencia, §3.4).
- **Latidos (*heartbeats*)**: en bases con muchas tablas donde solo capturas unas pocas, y en bases
  con poca actividad, el capturador puede no avanzar su desplazamiento durante horas mientras el
  WAL se acumula. **Activa los latidos**; es la mitigación específica y casi nadie la conoce.
- **Filtrado en origen, no en destino**: incluye solo las tablas y columnas necesarias
  (publicaciones acotadas, listas de inclusión). Menos carga, menos superficie de dato personal
  (§5), menos ruido de esquema.

### 3.2 El impacto en el origen: **el fallo de producción por excelencia**

**Un slot de replicación lógica retiene WAL mientras su consumidor no confirme. Si el consumidor se
para y nadie lo nota, `pg_wal` crece hasta llenar el disco y el primario cae.** No es un caso raro:
es *el* incidente de este dominio. Verificado sobre PostgreSQL 18:

- **`max_slot_wal_keep_size`** (desde PG 13; recargable por SIGHUP, en MB si no se indica unidad)
  limita el WAL que los slots pueden retener. Con el valor por defecto **`-1` la retención es
  ilimitada**, que es exactamente la configuración con la que se llena el disco. **Fíjalo siempre a
  un valor acorde al espacio libre real.**
- **La contrapartida hay que aceptarla explícitamente**: cuando se supera el límite, PostgreSQL
  **invalida el slot** y recicla el WAL. El consumidor ya no puede continuar y **hará falta un slot
  nuevo y, típicamente, una instantánea inicial completa**. Es una decisión consciente:
  **sacrificas el CDC para salvar la base de datos**. Es la elección correcta, y hay que tenerla
  escrita en el runbook antes de que ocurra.
- **`idle_replication_slot_timeout`** (**nuevo en PostgreSQL 18**; valor sin unidad en segundos, `0`
  desactiva) invalida automáticamente los slots inactivos. **La invalidación ocurre en el
  *checkpoint***, así que hay retardo entre superar el umbral y la invalidación real. No aplica a
  slots que no reservan WAL ni a slots sincronizados desde el primario (`synced = true`). Valores
  razonables del orden de 48-72 h.
- **Vigilancia obligatoria sobre `pg_replication_slots`**: `active`, `wal_status`, `safe_wal_size`
  (con `max_slot_wal_keep_size` positivo indica cuánto WAL queda antes de invalidar; **negativo
  significa que ya se pasó**) e `invalidation_reason`. **Alerta con umbral por retención de WAL del
  slot y por slot inactivo, sin excepción.** Y **borra los slots huérfanos**: un slot de una prueba
  que nadie retiró es una bomba con temporizador.
- **Transacciones largas en el origen** agravan todo: retienen WAL y pueden llegar a llenar el
  almacenamiento por sí solas. Complementa con `wal_sender_timeout` (60 s por defecto) para detectar
  consumidores muertos.
- **`REPLICA IDENTITY`**: por defecto PostgreSQL solo publica la clave primaria en el "antes" de un
  `UPDATE`/`DELETE`. `REPLICA IDENTITY FULL` da la fila completa **a costa de más WAL y más carga**:
  actívalo por tabla y solo si el consumidor lo necesita, nunca de forma global.
- **Otros motores, mismo principio**: en MySQL/MariaDB, la retención del binlog (`binlog_expire_logs_seconds`)
  fija tu ventana de reanudación — si el consumidor se para más tiempo que esa retención, **la
  posición se pierde y toca reinstantánea**. En Oracle, el minado del log tiene coste en el propio
  motor. **Coordina el parámetro con el DBA del motor, es una decisión compartida.**
- **Regla transversal**: el CDC **acopla la salud de tu plataforma analítica a la salud de la base
  de datos operacional**. Es el coste oculto de la técnica y hay que decírselo por escrito al equipo
  dueño del origen antes de encender nada.

### 3.3 CDC frente a outbox — **la frontera y el error de diseño más caro del dominio**

**Dilo con claridad y sin matices tibios: los cambios de tabla capturados por CDC NO son eventos de
dominio.** Un `UPDATE` sobre `orders` te dice que unas columnas cambiaron de valor; **no** te dice
que el pedido se canceló, ni por qué, ni por quién. Publicar CDC crudo como contrato entre servicios
significa:

- **Acoplas a todos los consumidores al esquema físico interno** del servicio origen. A partir de
  ese momento, ese servicio ya no puede refactorizar su base de datos: cualquier `ALTER TABLE` es un
  cambio incompatible en una API pública que nadie declaró como tal. Es exactamente el mismo error
  que dejar que otro servicio consulte tu base de datos, con un salto intermedio que lo disfraza.
- **Pierdes la intención.** El diff de filas no contiene el "por qué". Cada consumidor reconstruye
  la semántica a su manera, y todas las reconstrucciones son distintas y plausibles.
- **Expones todo lo que hay en la tabla**, incluidas columnas que nunca debieron salir del servicio
  (§5).
- **Sin contrato ni versionado**: un refactor rompe consumidores en producción sin aviso previo.

**El reparto correcto, y la frontera con `microservices-architecture-standards`**:

| Caso | Patrón correcto | Dueño de la decisión |
|---|---|---|
| Publicar que **algo de negocio ocurrió** para que otros servicios reaccionen | **Outbox**: la aplicación escribe el evento de dominio, con su esquema y su versión, en la misma transacción que el cambio de estado | `microservices-architecture-standards` |
| **Transportar** de forma fiable ese evento desde la tabla outbox al broker | **CDC sobre la tabla outbox** — este es el uso correcto y virtuoso del CDC en arquitectura de servicios | Aquí |
| Alimentar un **almacén analítico, un lakehouse, una caché o un índice de búsqueda** desde tablas existentes | **CDC directo sobre las tablas**, con el destino tratado como consumidor **interno** | Aquí |
| Integrar un **sistema heredado** que no se puede modificar | **CDC directo**, con **capa anticorrupción obligatoria** que traduzca a un contrato propio antes de exponerlo a nadie más | Aquí |

**Reglas duras que se derivan**:
- **Un topic de CDC crudo nunca es un contrato público.** Si alguien fuera del equipo dueño lo
  consume, o se convierte en evento de dominio con outbox, o se interpone una capa anticorrupción
  con su propio esquema versionado. Sin excepciones.
- El coste del outbox es real y hay que decirlo: **toca todas las rutas de escritura, la tabla crece
  y hay que purgarla, y mantienes dos esquemas** (el de la tabla y el del evento). Se paga porque
  el contrato lo vale.
- **Tombstones**: en un topic compactado, un borrado se representa con un mensaje de valor nulo. Si
  tu consumidor no los trata, **los borrados no se propagan** y tu copia acumula fantasmas. Es un
  fallo silencioso, que es la peor clase.

### 3.4 Semántica de entrega: qué significa de verdad

| Semántica | Qué garantiza | Cómo se consigue | Veredicto |
|---|---|---|---|
| **Como mucho una vez** (*at-most-once*) | Nunca duplica; **puede perder** | Confirmar el desplazamiento **antes** de procesar | **Casi siempre es un accidente, no un diseño.** Y ocurre por descuido |
| **Al menos una vez** (*at-least-once*) | Nunca pierde; **puede duplicar** | Confirmar el desplazamiento **después** de procesar | **El default correcto.** Todo lo demás se construye encima |
| **Exactamente una vez** (*exactly-once*) | Cada efecto se aplica una vez | Transacciones y estado coordinados **dentro del sistema** | **Real, pero mucho más estrecho de lo que se vende** (ver abajo) |

**Qué significa de verdad "exactamente una vez"**: es **exactamente-una-vez *de efecto***, no de
entrega, y **solo dentro de la frontera del sistema que lo implementa** — lectura de Kafka,
actualización de estado y escritura a Kafka en una transacción (Kafka Streams / productor
transaccional con `read_committed`), o el mecanismo de *checkpoint* de Flink con sumideros
transaccionales de dos fases. **En cuanto un efecto sale de esa frontera** —llamar a una API,
enviar un correo, escribir en una base que no participa en la transacción— **la garantía se acaba**.
Cuesta además latencia y complejidad operativa.

**Por tanto: la idempotencia del consumidor es la única defensa real, y es obligatoria.** No es una
alternativa al *exactly-once*, es su prerrequisito y su sustituto en el 90 % de los casos. Se
implementa con:
- **Clave de negocio + upsert** (`INSERT ... ON CONFLICT`, `MERGE`) en vez de `INSERT` a secas.
- **Deduplicación por identificador de evento** con ventana acotada, cuando el upsert no aplica.
- **Comparación de versión / número de secuencia**: descartar el evento cuyo `lsn`/`sequence` sea
  menor o igual al ya aplicado. Esto además protege del reordenamiento.
- **Efectos externos no idempotentes** (cobrar, enviar, notificar) **protegidos con clave de
  idempotencia y registro de ejecución**. Un reproceso no debe facturar dos veces.

### 3.5 Orden y particionado

- **El orden solo se garantiza dentro de una partición.** No existe orden global en un log
  particionado, y quien lo asume construye un sistema que falla de forma intermitente y aleatoria.
- **Elegir la clave de partición es elegir qué se ordena.** Regla: **la clave es la entidad cuya
  secuencia de cambios importa** — típicamente la clave primaria de la fila de origen. Así todos los
  cambios de un mismo pedido van a la misma partición y llegan en orden.
- **Consecuencias que hay que aceptar**:
  - **Sesgo de partición**: una entidad muy activa satura su partición y limita el paralelismo. Se
    detecta midiendo el retraso **por partición**, no el agregado.
  - **Cambiar el número de particiones rompe la afinidad de claves** y por tanto el orden histórico.
    Es una decisión de diseño con consecuencias, no un ajuste de capacidad (la operación del topic
    es de `data-platform-standards`).
  - **El paralelismo del consumidor está acotado por el número de particiones.**
- **Si el orden entre entidades distintas importa** (una transferencia entre dos cuentas), el
  particionado por entidad **no** te lo da. O metes ambas en la misma partición mediante una clave
  compuesta de negocio, o lo resuelves con estado y tiempo de evento en el procesador, o rediseñas
  la operación como un solo evento. Elige explícitamente: no lo dejes al azar.
- **Reordenamiento entre topics**: dos flujos distintos no tienen orden relativo. Si un consumidor
  necesita "primero el cliente, luego el pedido", eso es una **dependencia** que hay que resolver en
  el consumidor (esperar, buscar, reintentar), no una garantía del transporte.

### 3.6 Esquema y evolución

El registro de esquemas y su configuración de compatibilidad son de `data-platform-standards`. Lo
específico del flujo:

- **Compatibilidad hacia atrás** (un consumidor nuevo lee datos viejos) como mínimo obligatorio;
  **hacia adelante** (un consumidor viejo lee datos nuevos) cuando no controlas a los consumidores,
  que es el caso habitual. Verificado en CI, no en la cabeza de nadie.
- **Qué hacer cuando el origen añade una columna**: es **aditivo y compatible** si el campo lleva
  valor por defecto. Decide explícitamente si se propaga (**no todo lo que aparece en el origen debe
  salir del origen**, §5). Si tu conector tiene lista de inclusión de columnas, la columna nueva no
  entra sola: es la opción segura.
- **Qué hacer cuando el origen borra o renombra una columna**: es **incompatible** y rompe
  consumidores. Se trata como una migración *expand/contract*, coordinada con el equipo dueño del
  origen: publicar ambos campos, migrar consumidores, retirar el viejo. **Que el capturador tolere
  el cambio no significa que tus consumidores lo hagan.**
- **Cambio de tipo**: casi siempre incompatible. Campo nuevo + convivencia + retirada.
- **Los eventos ya publicados no se pueden reescribir.** Un consumidor que reprocese desde el
  principio del log verá **todos** los esquemas históricos: tu código de consumo debe poder leerlos
  todos mientras el log los retenga. Esto no es teórico, es lo que ocurre el día que reprocesas.
- **El propietario del esquema del evento es el productor**, con contrato publicado y versionado.
  Un cambio de esquema sin aviso es un incidente, no un despliegue.

### 3.7 Procesamiento en movimiento: tiempo, ventanas y estado

- **Tiempo de evento frente a tiempo de proceso**: el **tiempo de evento** (cuándo ocurrió) es el
  correcto para cualquier cosa que el negocio vaya a leer; el **tiempo de proceso** (cuándo lo vio
  el motor) produce resultados **no reproducibles**: reprocesar da un resultado distinto al
  original. Regla: **agrega siempre por tiempo de evento**; usa tiempo de proceso solo para
  telemetría del propio sistema.
- **Marcas de agua (*watermarks*)**: la afirmación del motor de que "ya no espero eventos anteriores
  a T". Es **una heurística, no un hecho**, y encierra el compromiso central del dominio: **marca de
  agua agresiva = resultados rápidos y más datos descartados; marca de agua permisiva = resultados
  tardíos y más estado retenido**. Se elige con datos de retraso reales del flujo, se documenta y se
  revisa.
- **Datos que llegan tarde**: decide y escribe qué pasa con ellos. Tres opciones legítimas —
  descartarlos (contabilizándolos, siempre), aceptarlos con retraso permitido y **reemitir** el
  resultado corregido, o desviarlos a un flujo lateral para tratamiento aparte. **La opción ilegal
  es no decidir**, porque el default silencioso es descartarlos sin contarlos, y entonces las cifras
  no cuadran y nadie sabe por qué.
- **Ventanas**: fijas (*tumbling*) por defecto; deslizantes (*sliding*) multiplican el estado y el
  cómputo por el solape; de sesión cuando el negocio habla de sesiones. **Cada ventana abierta es
  estado retenido**: una ventana de 30 días sobre una clave de alta cardinalidad es un problema de
  memoria, no un requisito.
- **Estado**: es el activo más caro y más frágil de un flujo. Reglas:
  - **TTL en todo estado con clave**, sin excepción. Un estado con clave sin caducidad crece hasta
    tumbar el job, y lo hace meses después de que nadie recuerde el diseño.
  - **Checkpoints/savepoints con almacenamiento durable**, respaldados y **con restauración
    probada**. Un job cuyo estado no se puede restaurar no es recuperable: solo reprocesable.
  - **La compatibilidad del estado limita el despliegue**: cambiar la lógica o el esquema del estado
    puede impedir restaurar desde el *savepoint* anterior. Ten decidido de antemano si un despliegue
    conserva estado o parte de cero — y si parte de cero, cuánto tarda en recuperar la posición.
  - **Uniones con estado (*joins*) sobre flujos** requieren retener ambos lados: define la ventana o
    el estado explota.

## 4. Calidad y testing — gates

En orden de coste creciente. **Los marcados como gate rompen el build o el despliegue.**

1. **Configuración del capturador y del job como código**, versionada y revisada: conectores, listas
   de inclusión de tablas y columnas, modo de instantánea, claves de partición, retención,
   parámetros de ventana. Nada creado a mano contra una API de producción. *Gate de CI.*
2. **Sin secretos en la configuración del conector**: las credenciales vienen del gestor de secretos
   (ver `secrets-management-standards`). Un fichero de conector con contraseña de la base de datos
   de producción es un hallazgo, no un descuido. *Gate de CI.*
3. **Compatibilidad de esquema verificada en CI** contra el registro, con la política declarada
   (mínimo `BACKWARD`). Un cambio incompatible **rompe el build**. *Gate.*
4. **Tests unitarios de la lógica de procesamiento** con eventos fijos y resultado esperado,
   cubriendo el camino feliz **y los bordes obligatorios**: **evento duplicado**, **evento fuera de
   orden**, **borrado / tombstone**, **campo nulo**, **evento tardío más allá de la marca de agua**,
   **ventana vacía**, **clave nueva jamás vista**, **reinicio a mitad de ventana**. *Gate de CI.*
5. **Test de idempotencia extremo a extremo**: entregar el mismo lote de eventos dos veces produce
   el mismo estado en el destino (mismo recuento, misma suma de control). **Sin este test, la
   idempotencia es una intención.** *Gate de CI.*
6. **Test de propagación de borrados**: borrar en el origen y comprobar que el destino refleja el
   borrado. Es el fallo silencioso más caro y el que menos se prueba. *Gate.*
7. **Test de reanudación**: matar el capturador o el job, arrancarlo y comprobar que **no pierde ni
   duplica de forma no idempotente**. Con contenedores del motor real (no con dobles), porque el
   comportamiento del log es lo que se está probando.
8. **Prueba de restauración de estado** desde *checkpoint*/*savepoint*, y de **cambio de versión de
   la aplicación** conservando estado. Se hace antes del primer despliegue a producción, no después
   del primer incidente.
9. **Reconciliación periódica contra el origen** (recuento y suma de una medida clave, con
   tolerancia declarada), programada. **Un flujo CDC diverge del origen con el tiempo; sin
   reconciliación no te enteras.** Este es el gate operativo más importante de todos.
10. **Ensayo de reproceso**: reprocesar desde el principio del log en un entorno espejo, midiendo
    cuánto tarda y qué cuesta. Si no cabe en el tiempo disponible, tu plan de recuperación no
    existe.
11. **Dependencias fijadas por hash/digest** en conectores, imágenes y librerías del job (§5).
    *Gate de CI.*

## 5. Seguridad del stack

- **El CDC copia todo lo que hay en la tabla, incluidas las columnas que nunca debieron salir.**
  Filtra **en el capturador** (lista de columnas, publicación acotada, enmascaramiento en el
  conector), no aguas abajo: cada columna de PII que no capturas es un problema de retención, de
  borrado y de brecha que no tendrás. Coordinar con `privacy-engineering-standards`.
- **Un log de eventos con retención larga es una copia más del dato personal**, con su propia
  clasificación, su retención declarada y su control de acceso. **Retención infinita "por si acaso"
  está prohibida** (§7).
- **El derecho de supresión choca con el log**: un `DELETE` en el origen genera un evento nuevo,
  **no borra los eventos anteriores**. Un topic compactado con *tombstone* elimina las versiones
  anteriores de esa clave **con el tiempo, no de inmediato**, y solo si está compactado. Si hay
  compromiso de borrado, la **retención del topic pasa a ser un parámetro de cumplimiento**, o se
  diseña con seudonimización / *crypto-shredding* desde el principio. La política es de
  `privacy-engineering-standards`; **la restricción técnica y el parámetro se fijan aquí**.
- **Mínimo privilegio en el origen**: el usuario del capturador tiene **solo** los permisos de
  replicación/lectura que necesita, sobre las tablas acordadas. **No es un superusuario**, aunque el
  tutorial del conector lo ponga así.
- **El capturador se autentica con credenciales rotables y de corta vida**; nada de contraseñas
  estáticas eternas en un fichero de conector. TLS obligatorio contra el origen y contra el broker;
  autorización por topic y por grupo de consumo.
- **PII fuera de logs y de mensajes de error**: un conector que registra la fila que no pudo
  serializar es una fuga. Registra clave y desplazamiento, no contenido. Lo mismo aplica a la **cola
  de mensajes fallidos**: es un almacén de datos con contenido real, y necesita su propio control de
  acceso y su propia retención.
- **Cadena de suministro — precedentes verificados, no hipótesis**: **Trivy** (mar-2026), **LiteLLM**
  en PyPI (1.82.7/1.82.8, 24-mar-2026), **Telnyx** (mar-2026), **`durabletask` de Microsoft**
  (1.4.1-1.4.3, may-2026) y **`elementary-data` 0.23.3** (abr-2026, con el patrón `.pth` que se
  ejecuta al arrancar el intérprete). La generación actual, **"Mini Shai-Hulud"
  (CVE-2026-45321)**, activa desde finales de abr-2026, se propaga entre npm y PyPI, **extrae tokens
  OIDC de la memoria del runner de GitHub Actions** y ha llegado a **falsificar atestaciones de
  procedencia SLSA nivel 3**. Deriva obligatoria: fija por hash/digest todo lo que corre en un
  proceso con credenciales de la base de datos de origen o del broker; ventana de cuarentena de días
  antes de adoptar versiones recién publicadas; **la atestación de procedencia ya no es prueba
  suficiente por sí sola**; y un *runner* no tiene credenciales de más de un entorno.

## 6. Rendimiento y operabilidad

### 6.1 El retraso del consumidor (*lag*) es la métrica principal

- **Mide el retraso en tiempo, no solo en número de mensajes.** "12.000 mensajes de retraso" no
  dice nada; "18 minutos por detrás" sí. Y **mídelo por partición**: el agregado esconde el sesgo,
  que es la causa más frecuente.
- **Alerta por tendencia, no por umbral aislado**: un retraso que crece de forma sostenida es un
  incidente aunque su valor absoluto sea aún pequeño. El umbral fijo avisa cuando ya no hay margen.
- Señales complementarias obligatorias: **retraso del capturador respecto al origen** (que es
  distinto del retraso del consumidor), **retención de WAL / tamaño del slot** (§3.2), tasa de
  reinicios del job, **estado retenido**, duración y fallo de *checkpoints*, tasa de mensajes al DLQ,
  y **antigüedad del dato en el destino** (la frescura, que es la señal que le importa al negocio;
  ver `data-engineering-standards` §6).
- **Alerta accionable con runbook**, siempre: qué se rompió, qué depende, cómo se recupera, cuánto
  tarda. Una alerta de retraso sin runbook a las 4 de la mañana no sirve para nada.
- **Si hay compromiso de latencia, hay guardia.** Un SLO de segundos sin nadie que responda fuera de
  horario es una mentira documentada (criterio heredado de `data-engineering-standards` §6.3 y
  `sre-practice-standards`).

### 6.2 Reproceso, DLQ y la pregunta que decide la arquitectura

- **La cola de mensajes fallidos (DLQ) es obligatoria y con dueño.** Reglas: cada mensaje desviado
  lleva **la causa y el desplazamiento original**; hay un procedimiento escrito de reinyección; y
  **la DLQ se vigila con alerta**. Una DLQ que nadie mira es un vertedero de datos perdidos con
  aspecto de solución. Un mensaje envenenado **nunca** debe reintentarse infinitamente: bloquea la
  partición entera y para el flujo.
- **Reprocesado desde el principio**: es la capacidad que convierte un flujo en algo operable —
  corregir un error de lógica, poblar un destino nuevo, recuperar de una corrupción. Requisitos:
  **consumidores idempotentes** (§3.4), destino que tolere la reescritura, capacidad para absorber
  la ráfaga sin tumbar nada aguas abajo, y **medición previa de cuánto tarda**. Ensáyalo (§4).
- **La pregunta que decide la arquitectura: ¿cuánto tiempo guardas el log?** No es un parámetro de
  operación, es una decisión estructural:

| Retención | Qué te compra | Qué te cuesta |
|---|---|---|
| **Corta** (horas/días) | Almacenamiento barato, superficie de dato personal pequeña | **Solo puedes reprocesar lo reciente.** Un destino nuevo hay que sembrarlo desde el origen con una instantánea |
| **Media** (semanas) | Reproceso realista de incidentes | Coste y clasificación del dato |
| **Larga o infinita** (log como fuente de verdad) | Reconstruir cualquier destino en cualquier momento | Coste creciente, **conflicto directo con retención y borrado de datos personales**, y **todos los esquemas históricos vivos para siempre** en tu código de consumo |

  **Decídelo por escrito en el ADR, con el equipo de privacidad presente**, y ten claro que **el log
  no es una copia de seguridad**: no tiene el modelo de recuperación, ni la verificación, ni el
  aislamiento de una (ver `backup-recovery-standards`).

### 6.3 Coste

- **El streaming se paga en operación continua, no en cómputo puntual.** Un lote consume recursos
  cuando corre; un flujo consume **24×7**: brokers, *workers* del capturador, *task managers* del
  procesador, almacenamiento de estado y de log, y **atención humana**.
- **La partida más cara suele ser la última**, y es la que nunca aparece en la comparativa que
  justificó el proyecto.
- **Compara honestamente**: coste anual del flujo (infraestructura + guardia + mantenimiento)
  frente a coste anual del lote incremental equivalente. Si la diferencia no la justifica una
  decisión de negocio que ocurre en esos segundos (§2.1), la respuesta es el lote.
- **Los ficheros pequeños son un coste inducido del streaming** cuando el destino es un lakehouse:
  la compactación entra en el presupuesto del flujo, no en el de otro equipo (ver
  `lakehouse-standards` §3.3 y §3.5).

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisa trimestralmente versión y licencia del capturador, del procesador y del
  broker, y **la propiedad de las piezas** — en 2026 este subsector cambió de manos (IBM/Confluent).
  Las versiones mayores de Flink y de los conectores se ensayan en espejo con **prueba de
  restauración de estado** antes de tocar producción.
- **Retirada activa**: flujo, topic o conector sin consumo medido durante un trimestre se marca y se
  retira — **incluidos sus slots de replicación**, que es lo que se olvida y lo que llena el disco
  meses después.
- **ADR obligatorio** para: introducir streaming (frente al lote de §2.1), elegir mecanismo de
  captura, elegir procesador, **fijar la retención del log** (§6.2), definir la clave de partición
  de cada flujo, y publicar cualquier topic como contrato hacia fuera del equipo.
- **Documento de impacto en el origen firmado por su equipo dueño** antes de habilitar CDC contra
  una base de datos de producción. No es burocracia: es que su disco es el que se llena.

**PROHIBIDO**
- ❌ Adoptar streaming sin haber descartado por escrito el lote incremental y la réplica de lectura.
- ❌ Prometer latencia de segundos sin guardia que la sostenga.
- ❌ **Doble escritura** desde la aplicación (base de datos y luego broker) sin outbox ni CDC.
- ❌ **Publicar CDC crudo como contrato hacia fuera del equipo dueño del dato**, sin outbox ni capa
  anticorrupción. Es el error de diseño más caro del dominio.
- ❌ Llamar "evento de dominio" a un cambio de fila.
- ❌ CDC por triggers cuando el log de transacciones está disponible.
- ❌ Llamar CDC a un sondeo por `updated_at`: pierde borrados y cambios intermedios.
- ❌ **Slot de replicación con `max_slot_wal_keep_size = -1` (el valor por defecto) sin alerta de
  retención de WAL y de slot inactivo.**
- ❌ Dejar slots huérfanos de pruebas o de conectores retirados.
- ❌ `REPLICA IDENTITY FULL` global sin necesidad demostrada por tabla.
- ❌ Confirmar el desplazamiento antes de procesar (*at-most-once* accidental).
- ❌ Consumidor no idempotente. **La entrega es "al menos una vez" salvo prueba en contrario.**
- ❌ Prometer *exactly-once* extremo a extremo cuando hay un efecto fuera de la frontera
  transaccional.
- ❌ Asumir orden global en un log particionado, o cambiar el número de particiones sin asumir la
  rotura de afinidad de claves.
- ❌ Consumidor que ignora *tombstones*: los borrados no se propagan y nadie se entera.
- ❌ Agregar por tiempo de proceso lo que el negocio va a leer.
- ❌ No decidir qué se hace con los datos tardíos (el default silencioso es descartarlos sin
  contarlos).
- ❌ Estado con clave sin TTL; ventana deslizante amplia sobre clave de alta cardinalidad.
- ❌ Job con estado sin *checkpoint* durable y **sin restauración probada**.
- ❌ Poner un CDC en producción sin haber medido la instantánea inicial ni ensayado la reinstantánea.
- ❌ Instantánea inicial contra el primario en hora punta sin acuerdo con el equipo del origen.
- ❌ Flujo sin DLQ, o DLQ sin dueño, sin alerta y sin procedimiento de reinyección.
- ❌ Reintento infinito de un mensaje envenenado, que bloquea la partición.
- ❌ Flujo sin reconciliación periódica contra el origen.
- ❌ Retención de topic infinita "por si acaso", o log con dato personal sin retención declarada.
- ❌ Usar el log de eventos como copia de seguridad.
- ❌ Usuario superusuario para el capturador; credenciales estáticas eternas en la configuración del
  conector.
- ❌ Capturar columnas de PII "porque venían en la tabla"; PII en logs del conector o en la DLQ sin
  control.
- ❌ Dependencias sin fijar por hash/digest en procesos con credenciales del origen o del broker.
- ❌ Fijar versiones, licencias o propiedad de una herramienta de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2, §3.2 y §5 son de **agosto de 2026**. Antes de fijar nada en un entregable, verifica:

1. **Debezium**: versión vigente (3.6.0.Final el 1-jul-2026; 3.7.0.Alpha1 en curso), licencia
   (**Apache 2.0**, verificada en el repositorio) y **el estado real de Debezium Server**: en la
   serie 3.6 está migrando del motor embebido antiguo a la extensión Quarkus. **Comprueba si esa
   migración se ha consolidado antes de apostar por el modo autónomo sin Kafka Connect.** Verifica
   también el estado del conector concreto de tu motor (los de PostgreSQL, MySQL y SQL Server son
   los más rodados; los demás, no lo asumas).
2. **PostgreSQL**: parámetros y comportamiento de la replicación lógica en **tu** versión —
   `max_slot_wal_keep_size` (por defecto `-1`, ilimitado), **`idle_replication_slot_timeout` (nuevo
   en PG 18, invalida en el *checkpoint*, no aplica a slots `synced`)**, `wal_sender_timeout`, y las
   columnas `wal_status`, `safe_wal_size` e `invalidation_reason` de `pg_replication_slots`. **Estos
   nombres cambian entre versiones: no los cites de memoria.**
3. **Procesadores**: Flink (**2.3.0 estable según la página oficial de descargas, jun-2026**; ojo,
   varias fuentes secundarias siguen citando 2.2.1 — **la fuente del proyecto manda**), Kafka
   Streams (con Kafka 4.3.1, jun-2026) y Spark Structured Streaming (Spark 4.2.0, jul-2026). Y el
   calendario de soporte de la rama que uses.
4. **Licencias y propiedad**: **IBM completó la adquisición de Confluent el 17-mar-2026**; Kafka
   sigue en la ASF bajo Apache 2.0 y no le afecta. Verifica el estado actual de la **Confluent
   Community License** (no OSI: Schema Registry, REST Proxy, ksqlDB y varios conectores) y si el
   modelo de precios o soporte ha cambiado bajo IBM. Verifica también la licencia de cualquier
   plataforma CDC comercial antes de recomendarla.
5. **Cadena de suministro**: advisories de los conectores, imágenes y librerías que instales, y
   evolución de **Mini Shai-Hulud (CVE-2026-45321)**.
6. **Motor de origen**: retención de binlog y su parámetro vigente en MySQL/MariaDB, estado de
   LogMiner en la versión de Oracle en uso, y los límites de CDC del servicio gestionado si el
   origen está en la nube.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Debezium Server en modo autónomo**: verificado que **existe** y que en 3.6 está en migración
  arquitectónica hacia la extensión Quarkus; **no verificado** si el modo autónomo se considera ya
  consolidado y recomendado por el proyecto frente a Kafka Connect. No lo afirmes.
- **Flink CDC**: no verificados versión ni cadencia de releases del subproyecto (solo que es Apache
  2.0 bajo el paraguas de Flink).
- **Licencias de plataformas CDC comerciales** (Estuary, Artie, Sequin, Streamkap, Airbyte para
  CDC): **no verificadas** en esta revisión. La búsqueda no devolvió fuentes primarias. No cites
  ninguna licencia concreta sin comprobarla en el repositorio o en la web del producto.
- **Kafka Streams y Spark Structured Streaming**: no verificado ningún dato de adopción
  independiente. Las comparativas disponibles proceden de proveedores con intereses en la respuesta
  (Confluent, Decodable, RisingWave, Tinybird, Onehouse): trátalas como orientación, no como dato.
- **PeerDB/ClickPipes y otros CDC específicos de destino**: no verificado su estado actual.
- **Coste**: no hay cifras verificadas de coste comparado streaming/lote. Mídelo en tu plataforma.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
