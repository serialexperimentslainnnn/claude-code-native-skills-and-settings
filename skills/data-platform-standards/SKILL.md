---
name: data-platform-standards
description: Standards for data platform design and operations. Use when working with PostgreSQL (data modeling, indexes, migrations, tuning, replication, HA, PITR), Redis or Valkey caching (TTL, cache patterns), Kafka streaming (partitioning, retention, schema registry), database backups, encryption at rest, data classification, retention policies, or GDPR compliance for stored data.
---

# Estándares de plataforma de datos

## 1. Alcance y triggers

Aplica al diseñar, revisar u operar: bases de datos relacionales, cachés, streaming de datos, backups, cifrado y ciclo de vida del dato. Triggers: "PostgreSQL", "migración de esquema", "índice", "réplica", "PITR", "Redis", "Valkey", "caché", "TTL", "Kafka", "partición", "schema registry", "backup", "retención", "GDPR", "cifrado en reposo".

**No aplica**: ver `microservices-architecture-standards` (propiedad del dato por servicio, outbox, sagas y coreografía de eventos; aquí el motor que los soporta), `api-design-standards` (contrato hacia el exterior; una tabla no es una API), `onprem-standards` y `homelab-standards` (el host, el almacenamiento y el hipervisor por debajo del motor), `aws-standards`/`azure-standards`/`gcp-standards` (RDS/Aurora, Azure Database, Cloud SQL/AlloyDB/BigQuery como servicios gestionados: aquí el criterio de modelado y operación que aplica igual), `cryptography-pki-standards` (elección de algoritmos y ciclo de vida de las claves que cifran el dato en reposo; aquí solo la exigencia de cifrarlo y clasificarlo), `grc-compliance-standards` (el marco normativo, el registro de tratamiento y la evidencia de auditoría del GDPR), `privacy-engineering-standards` (la **ingeniería** de la privacidad: qué dato se puede recoger y cuánto tiempo, DPIA, seudonimización frente a anonimización, crypto-shredding, derechos del interesado de extremo a extremo — aquí solo su ejecución en el motor: particionado por retención, borrado, cifrado en reposo, réplicas), `bcdr-standards` (RTO/RPO derivados del negocio y orden de recuperación; aquí el PITR y la mecánica del respaldo del motor), `identity-access-management-standards` (identidad y autorización de quien accede al dato), `vulnerability-management-standards` (CVE y EOL de los motores), `observability-standards` (métricas y alertas del motor), `iac-standards` (el código que aprovisiona la instancia), `lua-standards` (**el script `EVAL`/`EVALSHA` o `FUNCTION` que se ejecuta dentro de Redis/Valkey**: atomicidad, determinismo y prohibición de depender del reloj o del azar son suyos; la memoria, la persistencia, la política de expulsión y el clustering del motor son de aquí), `sql-standards` (**el lenguaje SQL**: cómo se escribe la consulta y el DDL —joins, CTEs y funciones de ventana, `NULL` y lógica trivaluada, predicados SARGables, quoting de identificadores dinámicos, la mecánica de escritura del expand/contract—; **regla de arbitraje espejada desde su §1**: *si la pregunta cambia cómo se escribe la consulta o el DDL, es de `sql-standards`; si cambia qué motor se elige, cómo se dimensiona, respalda, replica o restaura, es de aquí; si cambia la forma del modelo, es de la skill de modelado*. Corolario: *"¿por qué esta consulta no usa el índice?"* es suya —se reescribe el predicado—; *"¿qué índice creo y cuánto cuesta mantenerlo?"* es de aquí), las skills de lenguaje (ORM, driver y migraciones desde el código), `gis-geoespacial-standards` (**el dato espacial y su criterio**: PostGIS y sus tipos e índices GiST/SP-GiST, sistemas de referencia y proyecciones, tolerancia y validez geométrica — **aquí el motor PostgreSQL que lo hospeda**: dimensionado, respaldo, réplica y el coste de esos índices). Motores fuera de PostgreSQL/Redis/Valkey/Kafka —Oracle, SQL Server, MySQL, NoSQL, grafos, vectorial, time-series, buscadores y lakehouse— tienen **skill propia y manda la suya**: `oracle-dba-standards`, `sqlserver-dba-standards`, `mysql-mariadb-dba-standards`, `nosql-standards`, `graph-db-standards`, `vector-db-standards`, `timeseries-db-standards`, `search-engines-standards`, `lakehouse-standards`. Lo que se conserva aquí es transversal (3-2-1, restore probado, migraciones versionadas, un almacén por necesidad).

Principio rector: **un almacén por necesidad, no por moda** — PostgreSQL cubre por defecto lo relacional, JSONB, full-text básico y colas simples (`SKIP LOCKED`); añade una pieza nueva (caché, broker, motor de búsqueda) solo cuando una necesidad medida lo exija y con su coste operativo asumido en ADR.

## 2. Decisiones por defecto

> **Verificación web obligatoria antes de fijar versiones**: valores verificados en agosto 2026; re-verifica con WebSearch en cada uso real (ver §8).

| Ámbito | Default | Nota |
|---|---|---|
| Relacional | **PostgreSQL 18.x** (18.4 estable; 19 en beta, GA prevista otoño 2026 — no en prod hasta 19.1+) | Default salvo requisito que lo descarte, con ADR |
| IDs | `uuidv7()` nativo (PG 18) o `bigint identity` | UUIDv4 como PK fragmenta índices B-tree |
| Caché in-memory | **Valkey** (BSD-3, Linux Foundation, 9.x) | Redis 8+ es tri-licencia (AGPLv3/RSALv2/SSPL): úsalo solo si la política de licencias de la organización acepta AGPL o si necesitas sus módulos integrados (JSON, query engine, vector) |
| Streaming | **Kafka 4.x** (4.2.1 actual; KRaft, sin ZooKeeper desde 4.0) | Gestionado (MSK/Confluent Cloud/Aiven) salvo capacidad operativa real para operarlo |
| Schema registry | **Karapace o Apicurio** (Apache 2.0) | Confluent Schema Registry es Confluent Community License, no OSS: decisión consciente |
| Formato de eventos | **Avro o protobuf** con registry | JSON Schema solo con validación en CI |
| Migraciones | Herramienta versionada del ecosistema (Flyway/Liquibase/Alembic/dbmate...) en repo y CI | Nunca DDL manual en prod |
| Backups | **3-2-1** + PITR con WAL archiving (pgBackRest/barman) | Un backup sin restore probado no existe |

## 3. Diseño y límites

### PostgreSQL — modelado
- Normaliza por defecto (3FN); desnormaliza solo con medición que lo justifique y documentando la invariante que se rompe. JSONB para datos genuinamente semiestructurados, no como excusa para no modelar.
- Tipos correctos: `timestamptz` (nunca `timestamp` sin zona), `numeric` para dinero, `text` + `CHECK`/dominios en vez de `varchar(n)` arbitrarios. Constraints en la BD (`NOT NULL`, FK, `UNIQUE`, `CHECK`): la aplicación valida, la base de datos garantiza.
- Particionado declarativo (por rango de fecha, típicamente) cuando haya retención por tiempo o tablas > decenas de GB con patrón de acceso reciente; decidirlo al diseñar, no al llegar el dolor.
- Convenciones de esquema: `snake_case`, nombres en un solo idioma consistente, columnas de auditoría (`created_at`/`updated_at` en `timestamptz`) por defecto; *soft delete* solo si el negocio necesita el histórico — y entonces con índice parcial y política de purga que respete la retención (§5), no un `deleted_at` eterno.
- Multi-tenancy decidido por ADR: esquema/BD por tenant (aislamiento fuerte, más operación) vs columna `tenant_id` + **Row-Level Security activada** como red obligatoria (nunca solo filtros en la app).

### PostgreSQL — índices
- Todo FK con índice. Índices compuestos ordenados por selectividad y patrón de consulta; parciales para subconjuntos calientes (`WHERE deleted_at IS NULL`); *covering* (`INCLUDE`) para index-only scans medidos.
- Cada índice se justifica con un plan (`EXPLAIN (ANALYZE, BUFFERS)`): los índices no usados cuestan escrituras y espacio — revisa `pg_stat_user_indexes` periódicamente y elimina los muertos.
- Creación en prod siempre `CREATE INDEX CONCURRENTLY` (fuera de transacción, con reintento si queda `INVALID`).

### PostgreSQL — migraciones (expand/contract)
- Versionadas, inmutables una vez mergeadas, con orden total y aplicadas solo por CI/CD. Cada cambio compatible hacia atrás con el código en ejecución (N y N-1 conviven durante el despliegue):
  1. **Expand**: añade columna/tabla nueva (nullable o con default), doble escritura si procede.
  2. **Migrate**: backfill en lotes pequeños (evita bloqueos largos y bloat masivo).
  3. **Contract**: retira lo viejo en una migración posterior, cuando la telemetría confirme que nada lo usa.
- Conoce los locks antes de cada DDL en caliente (chuleta; verifica en la doc de tu versión):

| Operación | Coste en caliente | Alternativa segura |
|---|---|---|
| `ADD COLUMN` (nullable o default constante) | Barato (PG 11+) | — |
| `SET NOT NULL` directo | Escaneo con lock | `CHECK ... NOT VALID` + `VALIDATE CONSTRAINT` (PG 12+ lo aprovecha) |
| `ALTER TYPE` de columna | Reescritura de tabla | Columna nueva + backfill + swap (expand/contract) |
| `ADD FOREIGN KEY` directo | Lock + validación | `NOT VALID` + `VALIDATE` después |
| `CREATE INDEX` | Lock de escrituras | `CONCURRENTLY` |

- Fija `lock_timeout` y `statement_timeout` en la sesión de migración para no colgar producción; reintenta con backoff si no consigue el lock.

### PostgreSQL — transacciones y concurrencia
- Transacciones cortas: nada de transacciones abiertas durante llamadas externas o espera de usuario (bloquean vacuum, retienen snapshots, agravan bloat). Alerta sobre `idle in transaction`.
- Nivel de aislamiento consciente: `READ COMMITTED` por defecto; `REPEATABLE READ`/`SERIALIZABLE` con manejo de errores de serialización (retry). Bloqueos explícitos (`SELECT ... FOR UPDATE SKIP LOCKED` para colas de trabajo) antes que locks de tabla.
- Escrituras concurrentes idempotentes: `INSERT ... ON CONFLICT` para upserts; claves naturales con `UNIQUE` como red de seguridad frente a duplicados de reintentos.

### Valkey/Redis — patrones de caché
- **Cache-aside** por defecto: lee caché → miss → lee BD → escribe caché con TTL. La BD es la fuente de verdad; la caché es siempre descartable y reconstruible.
- **TTL obligatorio en toda clave** (§7). TTL con jitter para evitar estampidas por expiración sincronizada; para claves muy calientes, protección anti-estampida (lock ligero o *soft-TTL* con refresco en background).
- Invalidación explícita al escribir (delete, no update de caché — menos carreras). Claves con namespace y versión (`app:v2:user:{id}`) para invalidar por despliegue.
- `maxmemory` + política explícita (`allkeys-lru`/`volatile-ttl` según uso); nunca sin límite. Si es solo caché, persistencia desactivada; si algún dato exige durabilidad, no pertenece a la caché.
- Diseña para el fallo de la caché: la aplicación debe funcionar (degradada) con la caché caída; protege la BD del *thundering herd* post-caída (rate limit/carga progresiva). Otros usos legítimos (rate limiting, locks distribuidos con expiración, colas ligeras) se declaran como tales, con su propia durabilidad y HA evaluadas — no "aprovechando" la instancia de caché.
- Prohibido usar la caché como única copia de un dato de negocio, y prohibido `KEYS` en prod (usa `SCAN`).

### Kafka — streaming
- **Clave de partición = entidad cuya secuencia importa** (el orden solo se garantiza por partición). Dimensiona particiones por throughput objetivo y paralelismo de consumidores con margen (crecer particiones rompe la afinidad de claves: decisión de diseño, no parche).
- **Retención explícita por topic** según clasificación del dato y GDPR (§5): `delete` con tiempo acotado por defecto; `compact` solo para changelogs/estado por clave. Nada de retención infinita "por si acaso".
- **Registry obligatorio** con compatibilidad `BACKWARD` mínima verificada en CI; evolución de esquemas solo aditiva y con defaults. Productores idempotentes (`enable.idempotence=true`, default moderno) y `acks=all` con `min.insync.replicas=2` (RF=3) para datos que importan.
- Consumidores idempotentes (la entrega es at-least-once), lag monitorizado, DLQ con runbook. Commit de offsets tras procesar (at-least-once), nunca antes (at-most-once silencioso); *exactly-once* solo dentro de Kafka Streams/transacciones Kafka, no lo prometas extremo a extremo.
- Kafka no es base de datos ni almacén eterno: el estado consultable vive en un almacén de verdad (PostgreSQL, objeto), alimentado desde el stream. Para historia larga, tiered storage o exportación a almacenamiento barato, con decisión explícita.

## 4. Calidad y testing

- **Tests de migraciones en CI**: cada PR aplica `up` sobre una BD real (contenedor de la misma versión mayor que prod, p. ej. Testcontainers), y valida compatibilidad N-1: el código actual funciona sobre el esquema nuevo y el código nuevo sobre el esquema previo durante el rollout.
- Migraciones destructivas (drops de la fase contract) con doble control: revisión explícita + confirmación de telemetría de no-uso; el pipeline las marca y exige aprobación separada.
- Datos de prueba: fixtures sintéticas o anonimizadas — **prohibido** copiar datos de producción con PII a entornos de prueba sin anonimización/enmascaramiento verificado.
- Tests de integración de repositorios/queries contra PostgreSQL real, no contra H2/SQLite ni mocks del driver: los dialectos mienten.
- **Contract testing de esquemas de eventos**: el check de compatibilidad del registry es gate de CI; un productor no mergea un esquema incompatible.
- Rendimiento con datos realistas: valida planes de las queries críticas con volúmenes representativos (un plan sobre 100 filas no predice 100M); presupuestos de latencia por query en los flujos calientes.
- Gates: lint SQL (sqlfluff o equivalente) + migraciones aplicadas + tests de integración en CI. Prohibido mergear DDL que no haya pasado por el pipeline.

## 5. Seguridad y datos personales

- **Cifrado en reposo obligatorio** (volumen/filesystem o TDE del proveedor gestionado) con claves en KMS y rotación; cifrado de columna/aplicación para datos especialmente sensibles. **TLS en tránsito** en PostgreSQL, Valkey/Redis y Kafka, también intra-red (zero-trust): `scram-sha-256` en PG (nunca `md5`/`trust`), AUTH+TLS en Valkey, SASL+ACLs por principal en Kafka.
- Mínimo privilegio: roles de aplicación sin `SUPERUSER`/ownership, usuarios distintos para app/migraciones/lectura, credenciales desde gestor de secretos con rotación; `pgaudit` o equivalente donde haya requisitos de auditoría.
- **Clasificación de datos**: etiqueta cada tabla/topic/clave de caché (público / interno / confidencial / datos personales). La clasificación determina cifrado, retención, acceso y si puede estar en caché o en un topic.
- **GDPR por diseño**:
  - *Minimización*: no almacenes ni publiques en eventos campos "por si acaso"; PII fuera de logs, métricas y claves de caché.
  - *Retención*: definida por clasificación y automatizada (particiones por fecha + drop, `retention.ms` por topic, TTL); no "para siempre".
  - *Derecho al olvido*: borrado con alcance completo — BD (delete real, no solo soft-delete eterno), réplicas, caché, topics (compactación con tombstones o **crypto-shredding**: cifrado por sujeto y destrucción de clave, única vía práctica en logs inmutables y backups dentro de su ventana de retención documentada).
- Los backups también son datos personales: cifrados, acceso restringido y ventana de retención que la política de olvido documente.
- Registro de tratamientos al día: para cada almacén con PII, documenta finalidad, base legal, retención y quién accede (RGPD art. 30); los entornos no productivos cuentan (§4: sin PII real en test).
- Pseudonimización donde el caso de uso lo permita (analítica, métricas): claves sustitutas sin PII en los datasets derivados; la tabla de mapeo, bajo el control de acceso más estricto.
- Accesos a datos sensibles auditados y revisados periódicamente; exportaciones masivas (dumps, ETL hacia fuera) requieren aprobación y quedan trazadas (control de exfiltración).

## 6. Operabilidad

- **HA PostgreSQL**: replicación en streaming con al menos una réplica en otra AZ; failover automatizado y **probado** (Patroni o equivalente en autogestionado; multi-AZ en gestionado). Réplicas síncronas solo si el RPO≈0 justifica la latencia. `pg_stat_replication` y lag de réplica con alerta.
- Lecturas en réplica solo para cargas que toleran el lag (reporting, búsquedas); nunca leer tu propia escritura desde la réplica sin control de sesión. La réplica de HA no es la de reporting: cargas analíticas pesadas en réplica dedicada.
- Failover ensayado en calendario (game day): el ejercicio incluye a la aplicación (reconexión, poolers, DNS/VIP), no solo al motor.
- **PITR**: base backups + archivado continuo de WAL (pgBackRest/barman o mecanismo del proveedor). RTO/RPO definidos por escrito y **restore ensayado con cadencia programada** — el gate es "restauramos y validamos", no "el backup terminó".
- **Backups 3-2-1**: 3 copias, 2 medios/sistemas, 1 fuera del sitio/cuenta; al menos una copia inmutable u offline (ransomware). Verificación de integridad automática.
- **Tuning básico razonado** (punto de partida, medir después): `shared_buffers` ~25% RAM; `effective_cache_size` ~50-75%; `work_mem` calculado por conexiones×operaciones concurrentes (no valores heroicos globales); `random_page_cost` ≈1.1 en SSD/NVMe; `max_wal_size` y `checkpoint_completion_target` para checkpoints suaves (vigila `checkpoints_req` vs `checkpoints_timed`); `wal_compression`; autovacuum **más** agresivo en tablas calientes (bajar `autovacuum_vacuum_scale_factor`), jamás desactivado. **PgBouncer/pooler** ante muchas conexiones (transaction pooling; ojo: rompe features de sesión — prepared statements de sesión, advisory locks). Todo cambio de parámetro con motivo y medición antes/después; la configuración de la BD es código versionado, sin cambios manuales (drift).
- **HA caché**: Valkey/Redis con réplica + failover (Sentinel o modo cluster) solo si el impacto de perder la caché lo justifica (medido: ¿aguanta la BD el miss masivo?); si no, instancia simple y diseño tolerante (§3). Cluster para datasets que no caben en un nodo, no por moda.
- **Kafka ops**: RF=3 y `min.insync.replicas=2` en topics de datos importantes; monitoriza particiones under-replicated, ISR shrink, uso de disco por topic y skew de particiones (claves calientes). Rolling upgrades ensayados; brokers repartidos entre AZs con `rack awareness`.
- **Observabilidad** (`pg_stat_statements` siempre activo; alerta por síntoma con runbook). SLI mínimos por pieza:
  - PostgreSQL: latencia de query p95/p99, tasa de error, conexiones usadas/pool, replication lag, bloat, disco, edad de transacción (`wraparound`); logs de queries lentas (`log_min_duration_statement`) y de locks (`log_lock_waits`).
  - Valkey/Redis: hit ratio, evicciones, memoria usada vs `maxmemory`, latencia p99, clientes bloqueados.
  - Kafka: consumer lag por grupo, under-replicated partitions, throughput por topic, profundidad de DLQ.
  - Backups: éxito/duración del backup **y** del restore de prueba, edad del último restore validado (SLI de primera clase).
- **Capacity**: proyecta crecimiento con datos (tamaño de tablas/topics, IOPS, conexiones); revisa trimestralmente; el coste (FinOps) es atributo de diseño — tiering/retención antes que "más disco".

## 7. Sostenibilidad y evolución

- Esquemas de BD y de eventos evolucionan **solo** por expand/contract (§3): lo nuevo convive con lo viejo, la telemetría confirma el abandono, y el contract se ejecuta — retirar es parte de la tarea, no deuda tácita.
- Cambios de versión mayor (PG, Kafka, Valkey) planificados: leer release notes, ensayar en staging con datos representativos, `pg_upgrade`/rolling upgrade con rollback definido. Nunca saltar a una .0 en producción.
- ADR para decisiones one-way: elección de motor, estrategia de particionado (PG y Kafka), claves de partición, modelo de multi-tenancy, política de retención.
- Evita el acoplamiento al proveedor sin decidirlo: features propietarias del gestionado (extensiones exclusivas, APIs no estándar) solo con ADR que registre el coste de salida.
- Higiene continua: revisa trimestralmente índices no usados, tablas huérfanas, topics sin consumidores y claves de caché sin tráfico — el esquema también acumula deuda.

### Lista de prohibiciones
- ❌ Base de datos compartida entre servicios (cada servicio posee su esquema; integración por API/eventos).
- ❌ DDL manual en producción o migraciones fuera del pipeline versionado.
- ❌ Migración con breaking change sin fase expand/contract (drop/rename directo de columna en uso).
- ❌ Claves de caché sin TTL, o caché como única copia de datos de negocio.
- ❌ `KEYS`, `FLUSHALL` o instancia sin `maxmemory` en producción.
- ❌ Topics sin esquema en registry, sin política de compatibilidad o con retención indefinida sin justificar.
- ❌ Backup sin restore probado; backups sin cifrar; sin copia offsite/inmutable.
- ❌ PII en logs, métricas, claves de caché o eventos sin necesidad y sin clasificar.
- ❌ `trust`/`md5` en `pg_hba.conf`, superusuario para la aplicación, o secretos de BD en código/repositorio.
- ❌ Desactivar autovacuum, o fsync/synchronous_commit=off para "ganar rendimiento" en datos que importan.
- ❌ Índices sin justificar con plan de ejecución; `CREATE INDEX` bloqueante en caliente.
- ❌ UUIDv4 como PK en tablas grandes de inserción intensiva (usa uuidv7/bigint).
- ❌ Transacciones largas o `idle in transaction` sin timeout (`idle_in_transaction_session_timeout`).
- ❌ Copiar datos de producción con PII a entornos no productivos sin anonimizar.
- ❌ Kafka como almacén de verdad consultable o con retención infinita implícita.
- ❌ SQL construido por concatenación de entrada (siempre consultas parametrizadas).
- ❌ Fijar versiones, licencias o parámetros "de memoria" sin la verificación de §8.

## 8. Verificación web obligatoria

Antes de fijar en un entregable cualquier versión, licencia o parámetro recomendado aquí, **verifica con WebSearch** (los datos de §2 son de agosto 2026 y caducan):

1. Versión estable y EOL de PostgreSQL (¿sigue 18.x? ¿ya salió 19 GA?) — postgresql.org / endoflife.date.
2. Versión estable de Kafka (¿sigue 4.2.x?) y del cliente/registry elegidos.
3. Estado de licencias Redis vs Valkey (Redis 8+: tri-licencia con AGPLv3 desde mayo 2025; Valkey BSD-3 — ¿algún cambio posterior?).
4. CVEs relevantes de las versiones a recomendar y estado de las extensiones/herramientas (pgBackRest, Patroni, PgBouncer, Karapace/Apicurio).
5. Cambios normativos aplicables (GDPR/guidance del EDPB) si el diseño toca datos personales.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
