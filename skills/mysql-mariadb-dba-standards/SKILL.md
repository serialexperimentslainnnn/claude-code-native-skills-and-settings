---
name: mysql-mariadb-dba-standards
description: Use when operating MySQL, MariaDB or Percona Server — my.cnf/mariadb.cnf and mysqld/mariadbd flags, innodb_buffer_pool_size, innodb_flush_log_at_trx_commit, innodb_redo_log_capacity, utf8mb4 charsets and collations, EXPLAIN/EXPLAIN ANALYZE plans, performance_schema and the sys schema, slow query log, mysqldump, mydumper, xtrabackup, mariabackup, binlog and GTID replication, semisync, InnoDB Cluster, Group Replication, Galera wsrep, ALGORITHM=INSTANT online DDL, gh-ost and pt-online-schema-change, Percona Toolkit, mysql_upgrade/mariadb-upgrade, or choosing between Oracle MySQL and MariaDB.
---

# Estándares de MySQL / MariaDB / Percona (DBA)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al elegir, diseñar, operar, ajustar o migrar servidores de la familia MySQL:
**Oracle MySQL**, **MariaDB Server**, **Percona Server for MySQL** y **Percona XtraDB
Cluster**. Cubre motor InnoDB y su dimensionado, diseño de esquema e índices, lectura de
planes, DDL en línea, replicación y clústeres, respaldo lógico/físico, diagnóstico de
rendimiento, actualizaciones mayores y superficie de seguridad del servidor.

Triggers: `my.cnf`, `mariadb.cnf`, `/etc/mysql/conf.d/*`, `mysqld`, `mariadbd`, `mysql`,
`mariadb`, `mysqladmin`, `mysqlbinlog`, `mysqldump`, `mydumper`/`myloader`, `xtrabackup`,
`mariabackup`, `pt-online-schema-change`, `pt-query-digest`, `pt-archiver`, `gh-ost`,
`mysql_upgrade`/`mariadb-upgrade`, `mysqlsh`/MySQL Shell, `innodb_buffer_pool_size`,
`innodb_flush_log_at_trx_commit`, `innodb_redo_log_capacity`, `sql_mode`, `utf8mb4`,
`performance_schema`, `sys.*`, `SHOW ENGINE INNODB STATUS`, `EXPLAIN`/`EXPLAIN ANALYZE`,
`binlog`, `GTID`, `gtid_mode`, `rpl_semi_sync`, `wsrep_*`, Galera, InnoDB Cluster,
Group Replication, `ALGORITHM=INSTANT`, `ROW_FORMAT`, `ibd`, `ib_logfile`.

**Tesis de la skill**: *MySQL y MariaDB llevan más de una década divergiendo y ya no son
intercambiables*. "Es lo mismo, MariaDB es un drop-in" es una creencia falsa que sigue
causando incidentes de migración, de replicación y de backup. **Elegir uno es una decisión
de arquitectura con ADR**, no un detalle de empaquetado (§2, §3.1).

**No aplica**: ver `data-platform-standards` (**skill madre**: PostgreSQL es el default
relacional del catálogo y el principio rector es *un almacén por necesidad, no por moda* —
esta skill se activa cuando MySQL/MariaDB **ya está ahí** o cuando un requisito duro lo
impone, no para proponerlo por defecto; también fija Valkey/Redis y Kafka),
`caching-cdn-standards` (la caché delante de la base de datos; **frontera explícita**: si
el problema es una consulta sin índice o un N+1, la solución es arreglar la consulta, **no**
añadir una caché — ver §6), `oracle-dba-standards` (Oracle Database: RMAN, Data Guard,
RAC, AWR/ASH, licenciamiento y salida hacia PostgreSQL) y `sqlserver-dba-standards`
(T-SQL, DBCC CHECKDB, Always On, Query Store, licenciamiento por core), `nosql-standards`/`search-engines-standards`/`vector-db-standards`/
`timeseries-db-standards` (otros modelos de dato; la última cubre además la decisión de
particionar por rango en PostgreSQL antes de adoptar un motor temporal),
`message-brokers-standards` (colas, brokers y logs distribuidos),
`streaming-cdc-standards` (**la captura desde el binlog es suya**: Debezium, conectores,
esquema de eventos; **el impacto en el motor es de esta skill**: `binlog_format=ROW`,
`binlog_row_image`, retención de binlogs, coste de I/O y de purga, réplica dedicada para el
conector), `backup-recovery-standards` (mecánica genérica del repositorio, retención GFS,
inmutabilidad, cifrado de la copia; aquí solo la herramienta específica del motor y la
consistencia del punto de recuperación), `bcdr-standards` (**el plan**: BIA, RTO/RPO
derivados del negocio, orden de recuperación, declaración de desastre),
`ha-clustering-standards` (Pacemaker/Corosync, STONITH, VIP y clustering genérico de SO;
aquí los clústeres nativos del motor), `linux-storage-standards` y `onprem-standards`
(filesystem, I/O scheduler, NVMe, RAID y el hardware bajo el datadir),
`observability-standards` (plataforma de métricas, trazas y alertas; aquí qué SLI exportar),
`sre-practice-standards` e `incident-management-standards` (SLO y proceso de incidente),
`vulnerability-management-standards` (triaje y cadencia de parcheo; aquí qué CVE del motor
mirar), `linux-hardening-standards` y `firewall-policy-standards` (hardening del host y
exposición de red), `identity-access-management-standards` (identidad corporativa; aquí
cuentas y privilegios *dentro* del servidor), `cryptography-pki-standards` (algoritmos y
ciclo de vida de los certificados que usa el TLS del motor), `secrets-management-standards`
(dónde vive la contraseña de la aplicación), `privacy-engineering-standards` (qué dato
personal puede almacenarse y su borrado; aquí cómo se ejecuta en el motor),
`aws-standards`/`azure-standards`/`gcp-standards` (RDS/Aurora MySQL, Azure Database for
MySQL/MariaDB, Cloud SQL for MySQL como **servicios gestionados**: el criterio de esquema,
índices y replicación de aquí sigue aplicando; la operación del plano de control, no),
`kubernetes-standards` (operadores y statefulsets), `iac-standards` (aprovisionamiento),
`php-standards`/`python-standards`/`typescript-standards`/`jvm-spring-standards` (**MySQL es
el motor clásico de LAMP y de muchos frameworks**: ORM, driver, pool y migraciones desde el
código son suyos; el esquema resultante y su coste, de aquí),
`data-engineering-standards`/`analytics-bi-standards`/`lakehouse-standards` (analítica sobre
el dato una vez extraído; **MySQL no es un almacén analítico**),
`sql-standards` (**el lenguaje SQL**; regla de arbitraje espejada desde su §1: *si la pregunta
cambia cómo se escribe la consulta o el DDL, es de `sql-standards`; si cambia qué motor se
elige, cómo se dimensiona, respalda, replica o restaura, es de aquí*. Las peculiaridades de
dialecto de MySQL/MariaDB que **cambian el código** —`ONLY_FULL_GROUP_BY` y el resto de
`sql_mode`, `INSERT ... ON DUPLICATE KEY UPDATE` en ausencia de `MERGE`, colaciones y
comparación de cadenas— son suyas; **el parámetro del servidor que las activa y su impacto
operativo, de aquí**).

## 2. Decisiones por defecto

> Verificar la última versión y las fechas de EOL por web antes de fijarlas en un proyecto
> real (§8). Los datos siguientes son de **agosto 2026** y caducan rápido.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Motor relacional del catálogo | **PostgreSQL** (ver `data-platform-standards`) | MySQL/MariaDB solo por sistema existente, requisito de producto (WordPress, Zabbix, Moodle…), competencia del equipo o servicio gestionado impuesto — **con ADR** |
| Si es MySQL | **MySQL 9.7.x LTS** (GA 2026-04-21, EOL 2034-04-21; 9.7.2 de 2026-07-28) | **8.4 LTS** solo si hay bloqueo de compatibilidad (premier hasta 2029-04-30, extendido hasta 2032-04-30). **8.0 murió el 2026-04-30**: cualquier 8.0 en producción hoy es riesgo abierto |
| Releases *Innovation* de MySQL | **PROHIBIDAS en producción** | Desde 9.7, Oracle pasa a **CalVer `YY.M`** (26.7 es la de julio-2026, siguiente 26.10). Una Innovation solo se soporta **hasta que sale la siguiente**: es un canal de vista previa, no una rama de producción |
| Si es MariaDB | **MariaDB 12.3 LTS** (GA 2026-05-28) o **11.8 LTS** (EOL 2028-06-04, extendido 2033-10-22) | 11.4 LTS (EOL 2029-05-29) y 10.11 LTS (EOL 2028-02-16) siguen vivas para sistemas heredados. **10.6 murió el 2026-07-06**. Rolling releases trimestrales (12.0/12.1/12.2…): **no en producción** |
| Percona | **Percona Server for MySQL 8.4.x** (8.4.10-10, 2026-06-30) | **No existe Percona Server 9.7**: si necesitas MySQL 9.7 LTS, es Oracle MySQL. Percona Server 8.0 EOL jun-2026 |
| Motor de tablas | **InnoDB, sin excepciones** | MyISAM/Aria como motor de datos de negocio está **vetado** (§7) |
| Juego de caracteres | **`utf8mb4`** + colación explícita y única en todo el esquema | `utf8`/`utf8mb3` es el desastre histórico de 3 bytes: no es UTF-8, rompe emoji y buena parte del BMP extendido |
| Clave primaria | `BIGINT UNSIGNED AUTO_INCREMENT` o **UUIDv7 binario** (`BINARY(16)`) | **UUIDv4 como PK está vetado** en tablas de inserción intensiva (§3.2) |
| Durabilidad | `innodb_flush_log_at_trx_commit=1` + `sync_binlog=1` | Cualquier otro valor es **pérdida de datos aceptada conscientemente**, con ADR (§3.1) |
| Cambio de esquema | **`ALGORITHM=INSTANT` explícito** cuando la operación lo soporta; si no, `INPLACE`; si tampoco, **gh-ost** (o `pt-online-schema-change` si hay FK que no puedes tocar) | Nunca dejar que el servidor elija el algoritmo en silencio |
| Respaldo físico | **XtraBackup 8.4** en MySQL/Percona; **`mariabackup`** en MariaDB | **XtraBackup no sirve para MariaDB** y puede producir copias corruptas en silencio: es una divergencia real de internals de InnoDB (§3.6) |
| Respaldo lógico | **mydumper/myloader** para volumen; `mysqldump`/`mariadb-dump` solo para esquemas o tablas pequeñas | `mysqldump` es monohilo y su restauración no escala |
| Herramientas | **Percona Toolkit 3.7.1-3** (2026-04-17) | `pt-query-digest`, `pt-archiver`, `pt-online-schema-change`, `pt-upgrade` siguen mantenidos |
| Alta disponibilidad | **Replicación asíncrona con GTID + failover orquestado y ensayado** | Los clústeres síncronos (InnoDB Cluster/Group Replication, Galera/PXC) solo con necesidad medida y coste operativo asumido (§3.5) |
| Migraciones DDL | Herramienta versionada (Flyway/Liquibase/Alembic/dbmate/Skeema) en repo y CI | Ver `data-platform-standards` §3; DDL manual en producción está vetado |

### 2.1 El mapa real de la familia (agosto 2026)

| Producto | Qué es hoy | Criterio |
|---|---|---|
| **Oracle MySQL** | Upstream propietario de Oracle, Community (GPLv2) + Enterprise. Modelo Innovation/LTS, ahora CalVer | Default si ya estás en MySQL. Vigila: la actividad de desarrollo y el tamaño de la base de contribuidores es objeto de crítica pública en 2026 — factor de riesgo a monitorizar, no motivo automático de huida |
| **MariaDB Server** | Fork de 2009 (Monty Widenius). **MariaDB plc es propiedad de K1 Investment Management desde sep-2024** (adquisición de ~37 M$ tras un paso desastroso por bolsa vía SPAC); la **MariaDB Foundation** gobierna el proyecto abierto y es independiente (AWS entró como patrocinador *diamond*) | Adoptable: el código es GPLv2 y la Foundation es la salvaguarda de gobernanza. **Pero el respaldo comercial está en manos de capital riesgo**: registra en el ADR el riesgo de cambio de modelo y verifica el estado societario antes de comprometerte a soporte de pago |
| **Percona Server for MySQL** | Drop-in *real* de Oracle MySQL con instrumentación extra (mejor `performance_schema`, thread pool, auditoría, cifrado). GPLv2 | Elección sensata cuando quieres MySQL con herramientas de diagnóstico serias. Coste: **va por detrás de Oracle** (mainline 8.4, sin 9.7) |
| **Percona XtraDB Cluster (PXC)** | Percona Server + Galera | Ver §3.5 antes de adoptarlo |
| **Otros forks** (Aurora MySQL, TiDB, Vitess, Dolt, MyRocks…) | Compatibles por *protocolo de cable*, no por motor | Compatibilidad de wire protocol ≠ compatibilidad semántica. Cada uno es una decisión propia con su propio ADR |

## 3. Criterio técnico

### 3.1 La divergencia MySQL ↔ MariaDB (verificado, agosto 2026)

Hasta MariaDB 5.5 fue drop-in; desde el salto a 10.0 (2014) dejó de serlo, y **MariaDB ya
no garantiza compatibilidad drop-in**. Lo que sigue siendo cierto: la **compatibilidad de
protocolo de cable** — casi todos los drivers y clientes MySQL hablan con MariaDB. Lo que
no lo es, y rompe migraciones:

- **JSON**: MySQL usa un tipo `JSON` **binario nativo**, con índices multivaluados sobre
  arrays, columnas generadas indexables y operadores `->`/`->>`. En MariaDB, `JSON` es un
  **alias de `LONGTEXT`** con `CHECK (json_valid(...))`: cada operación reparsea el texto y
  no hay operadores de flecha. Migrar en cualquier dirección exige tocar esquema y consultas.
- **Replicación**: los **formatos de GTID son incompatibles**. No puedes poner una MariaDB
  como réplica de un primario MySQL (ni viceversa) con GTID. Es la trampa que más veces
  convierte una "migración transparente" en una parada.
- **Alta disponibilidad**: **Group Replication / InnoDB Cluster** (MySQL) y **Galera** (MariaDB,
  PXC) resuelven lo mismo con implementaciones distintas e **inmezclables**.
- **Vectores**: **MariaDB 11.8 LTS** trae `VECTOR(N)` y **`VECTOR INDEX` nativo (HNSW
  modificado)**, con `VEC_DISTANCE_EUCLIDEAN`/`VEC_DISTANCE_COSINE` y tuning
  (`mhnsw_ef_search`, `mhnsw_default_m`). **MySQL 9.7 tiene el tipo `VECTOR` pero no índice
  ANN en la edición comunitaria**: el índice y `DISTANCE()` viven en HeatWave (nube de
  Oracle). Si necesitas búsqueda vectorial *en el motor MySQL-family*, hoy es MariaDB — o,
  mejor, un almacén dedicado (ver `vector-db-standards`).
- **Solo en MariaDB**: `SEQUENCE`, tablas versionadas por sistema (`SYSTEM VERSIONING`), modo
  de compatibilidad Oracle, **thread pool en la edición comunitaria** (en MySQL es Enterprise),
  ColumnStore.
- **Solo en MySQL**: JSON binario, índices invisibles, diccionario de datos transaccional,
  MySQL Shell y su AdminAPI, Group Replication, derivadas laterales, CIDR en cuentas de usuario.
- **Autenticación**: `caching_sha2_password` (MySQL) y el SHA-256 de MySQL **no son
  trasladables** a MariaDB; `mysql_native_password` está desactivado por defecto desde 8.4.
  Los usuarios se recrean, no se migran.

**Criterio**: una migración MySQL↔MariaDB es un **proyecto de migración completo** —
conversión de esquema, reescritura de consultas, recreación de cuentas, sincronización por
volcado lógico (nunca por GTID), y ventana de corte con rollback. Presupuéstala como tal o
no la hagas.

### 3.2 InnoDB: lo que de verdad mueve la aguja

- **`innodb_buffer_pool_size` es el ajuste de mayor impacto, con diferencia.** Punto de
  partida en servidor dedicado: **50-75 % de la RAM**, dejando margen real para conexiones,
  `sort_buffer`/`join_buffer` por sesión, el SO y el page cache. En servidor compartido o
  contenedor con `memory.limit`, dimensiona por debajo del límite y **verifica que no muere
  por OOM**. Métrica de decisión: tasa de lecturas físicas
  (`Innodb_buffer_pool_reads` / `Innodb_buffer_pool_read_requests`) — si el *working set*
  cabe, esa tasa tiende a cero y añadir RAM deja de rendir.
- **Redo log**: dimensionado insuficiente → checkpoints agresivos y bloqueo de escrituras.
  MySQL 8.0.30+/8.4/9.7 usan `innodb_redo_log_capacity` (sustituye a
  `innodb_log_file_size`×`innodb_log_files_in_group`); MariaDB mantiene `innodb_log_file_size`.
  **Verifica el nombre del parámetro contra la versión exacta antes de escribirlo** (§8).
- **Durabilidad — el compromiso real**: `innodb_flush_log_at_trx_commit`
  - `1` (default, **obligatorio para datos que importan**): fsync del redo en cada commit.
    Durable ante caída del SO/host.
  - `2`: escribe al page cache del SO en cada commit, fsync cada segundo. Sobrevive a la
    caída del *proceso*, **no a la del host**. Ventana de pérdida ≈1 s.
  - `0`: ventana de pérdida ≈1 s incluso ante caída del proceso.
  El "truco de rendimiento" de bajarlo a 2 es **aceptar pérdida de datos**: solo con ADR, solo
  en réplicas de lectura, entornos de test o cargas reconstruibles. Con `sync_binlog=1` y
  `=1` obtienes durabilidad *y* consistencia binlog↔InnoDB; cualquier relajación rompe el
  punto de recuperación de §3.6. Si el fsync duele, la respuesta correcta suele ser
  **agrupar escrituras y usar almacenamiento con caché protegida por batería**, no relajar
  la durabilidad.
- **`innodb_flush_method`/`innodb_flush_neighbors`**: en NVMe/SSD, `O_DIRECT` y
  `innodb_flush_neighbors=0`; el default heredado está pensado para discos rotativos.
- **`innodb_io_capacity`/`_max`** acordes al almacenamiento real, medido — no copiados de un blog.
- **MyISAM está muerto**: sin transacciones, sin recuperación ante caída, bloqueo a nivel de
  tabla y corrupción silenciosa. Solo puede quedar en tablas internas del sistema donde el
  motor lo imponga. Cualquier tabla de negocio en MyISAM/Aria es deuda a convertir, y su
  presencia invalida cualquier estrategia de backup consistente.

### 3.3 Esquema: el índice agrupado manda

- **InnoDB organiza la tabla físicamente por la clave primaria** (índice agrupado). De ahí
  todo lo demás:
  - Una PK **monótona creciente** (`AUTO_INCREMENT`, UUIDv7, ULID, Snowflake) inserta siempre
    al final: páginas llenas, poco split, índice compacto.
  - Una **PK aleatoria (UUIDv4)** inserta en posiciones dispersas: *page splits* constantes,
    fragmentación, páginas medio vacías, buffer pool desperdiciado y escritura amplificada.
    Es el antipatrón más caro y más frecuente de la familia. **Veto** en tablas grandes.
  - Si necesitas identificadores opacos hacia fuera: **UUIDv7/ULID en `BINARY(16)`** (nunca
    `CHAR(36)`), o PK interna `BIGINT` + columna pública única.
- **Toda tabla lleva PK explícita**. Sin ella InnoDB inventa una interna oculta que no puedes
  usar, y la replicación por filas se degrada a escaneos completos en la réplica.
- **PK estrecha**: cada índice secundario almacena la PK como puntero. Una PK ancha infla
  *todos* los índices.
- **Tipos**: `DATETIME`/`TIMESTAMP` con criterio explícito de zona horaria (documenta cuál y
  por qué; `TIMESTAMP` convierte por `time_zone`, `DATETIME` no) — y verifica el estado del
  **problema del año 2038** en tu versión (MariaDB 11.8 amplió el rango de `TIMESTAMP`).
  `DECIMAL` para dinero, **nunca `FLOAT`/`DOUBLE`**. `ENUM` solo para conjuntos verdaderamente
  fijos (añadir un valor es un DDL). `TEXT`/`BLOB` fuera de la fila caliente si no se leen
  siempre. `NOT NULL` por defecto.
- **Trampas clásicas**: `sql_mode` sin `STRICT_TRANS_TABLES` acepta truncados silenciosos —
  **fija `sql_mode` explícitamente y versiónalo**; comparar `VARCHAR` con número provoca
  conversión implícita y anula el índice; `utf8mb4` cambia el tamaño máximo de clave de índice
  (767→3072 bytes con `DYNAMIC`), así que prefijos e índices largos hay que revisarlos.
- **Colación**: elige **una** para todo el esquema y para las conexiones. Mezclar colaciones
  en un `JOIN` fuerza conversión y mata el índice. Ten en cuenta que el default de colación
  `utf8mb4` **cambió entre versiones mayores** (`general_ci` → `0900_ai_ci` en MySQL 8+,
  `uca1400` en MariaDB reciente): declara la colación, no la heredes.

### 3.4 Cambios de esquema en línea

Estado verificado (agosto 2026):

- **`ALGORITHM=INSTANT`** es el default en MySQL 8.4+ cuando la operación lo permite, y cubre:
  añadir/quitar columna (en cualquier posición), añadir/quitar columna virtual o `DEFAULT`,
  ampliar `ENUM`/`SET`, cambiar tipo de índice, renombrar tabla. **No cubre construir índices,
  cambiar la PK ni la mayoría de cambios de tipo.**
- Límites duros de INSTANT que muerden en producción: **máximo 64 versiones de fila** (255
  desde MySQL 9.1) antes de exigir una reconstrucción; **no** en `ROW_FORMAT=COMPRESSED`, ni
  con índice `FULLTEXT`, ni en tablas temporales; tope de 1022 columnas internas; solo
  `LOCK=DEFAULT`. `OPTIMIZE TABLE` (reconstrucción) resetea el contador.
- **Regla**: **especifica siempre `ALGORITHM=` y `LOCK=` explícitamente**, incluso el default.
  Que el servidor elija en silencio un `COPY` sobre una tabla de 400 GB es un incidente.
- Cuando INSTANT/INPLACE no llegan: **gh-ost** por defecto (sin triggers, lee el binlog,
  corte controlado por ti — mejor bajo carga de escritura alta) o **`pt-online-schema-change`**
  si hay claves foráneas que no puedes soltar o versiones antiguas. Ambos siguen mantenidos.
  Ambos exigen espacio para una copia completa de la tabla y una ventana de corte.
- Toda migración con la disciplina **expand/contract** de `data-platform-standards` §3, con
  `lock_wait_timeout` acotado y reintento: un DDL que espera un *metadata lock* **encola todas
  las consultas posteriores sobre esa tabla**, incluidos los `SELECT`. Es el mecanismo por el
  que "un ALTER pequeño" tumba un servicio entero.

### 3.5 Índices, consultas y replicación

**Índices y planes**
- `EXPLAIN` primero, `EXPLAIN ANALYZE` (MySQL 8.0.18+ / MariaAB con `ANALYZE FORMAT=JSON`)
  para contrastar estimación con realidad. Lo que se mira: `type` (`ALL` = escaneo completo,
  `index` = escaneo del índice completo — tampoco es bueno), `rows` estimadas vs reales,
  `key` usada, `Extra` (`Using filesort`, `Using temporary`, `Using index` = cobertura).
- **Índice compuesto: el orden importa** — prefijo por igualdad, luego rango, luego orden.
  Un índice `(a,b,c)` sirve para `a`, `(a,b)`, `(a,b,c)`; **no** para `b` ni `(b,c)`. Una
  condición de rango consume el resto del índice para ordenación.
- **Cobertura**: si el índice contiene todas las columnas de la consulta, no toca la tabla
  (`Using index`). Es la optimización de mayor retorno en lecturas calientes.
- **Antipatrones que anulan el índice**: función o aritmética sobre la columna indexada
  (`WHERE DATE(created_at) = …`), `LIKE '%algo'`, `OR` sobre columnas distintas sin índices
  adecuados, conversión implícita de tipo o de colación, `SELECT *` cuando existía cobertura,
  paginación con `OFFSET` grande (usa paginación por clave/*keyset*).
- Índices duplicados o redundantes (`(a)` cuando existe `(a,b)`) cuestan escrituras y espacio:
  revisión periódica con `pt-duplicate-key-checker` y `sys.schema_unused_indexes`.

**Replicación**
- **GTID activado siempre** (`gtid_mode=ON`+`enforce_gtid_consistency` en MySQL;
  `gtid_strict_mode` en MariaDB): sin GTID, el failover y el reenganche de réplicas son
  manuales y propensos a error.
- `binlog_format=ROW` (default moderno) y `binlog_row_image` decidido conscientemente:
  `FULL` es lo que necesita CDC (ver `streaming-cdc-standards`), `MINIMAL` reduce volumen
  pero rompe consumidores que esperan la fila completa.
- **Asíncrona** (default): rápida, con ventana de pérdida en failover igual al lag.
  **Semisíncrona** (plugin en MySQL, `rpl_semi_sync_master_wait_point=AFTER_SYNC`): el
  primario espera acuse de al menos una réplica → RPO≈0 a costa de latencia de commit y de un
  modo degradado (con timeout, **cae a asíncrona silenciosamente**: alerta sobre ese estado o
  no sabrás que perdiste la garantía).
- **Lag de réplica — causas reales**, en orden de frecuencia: aplicador monohilo por falta de
  paralelismo (`replica_parallel_workers` + `binlog_transaction_dependency_tracking=WRITESET`),
  transacciones grandes o DDL largo, falta de PK en tablas (escaneos completos por fila),
  I/O saturado, y consultas de lectura pesadas compitiendo en la réplica. Métrica útil:
  `Seconds_Behind_Source` **miente** en varios escenarios — complementa con
  heartbeat (`pt-heartbeat`) o marca de tiempo propia.
- **Nunca escribas en una réplica** salvo `super_read_only=ON` desactivado deliberadamente
  durante un failover controlado. `read_only` no basta para usuarios con `SUPER`.
- **Clústeres — criterio honesto**:
  - **InnoDB Cluster / Group Replication** (MySQL) y **Galera / PXC** (MariaDB/Percona) dan
    consistencia y failover automático, pero su coste real es alto: sensibilidad extrema a la
    latencia de red, **penalización en escrituras de una sola fila caliente** (conflictos de
    certificación en Galera son errores que la aplicación **debe** reintentar), DDL que
    bloquea el clúster (TOI) o requiere procedimiento rodante (RSU), escrituras multi-primario
    que casi nunca compensan, y SST (transferencia de estado) que puede tardar horas en un
    dataset grande.
  - **Default**: primario + réplicas asíncronas con GTID y **failover orquestado y ensayado**
    (Orchestrator, MySQL Shell/MySQL Router, MaxScale, ProxySQL según el caso). Adopta un
    clúster síncrono solo con requisito medido de RPO≈0 y equipo capaz de operarlo —
    documentado en ADR. Un clúster mal operado tiene *menos* disponibilidad que un primario
    con réplica.
  - Recuerda: `wsrep_notify_cmd` y la superficie SST son **la clase de vulnerabilidad más
    grave de 2026 en esta familia** (§5).

### 3.6 Respaldo y punto de recuperación

- **Lógico** (`mysqldump`, `mariadb-dump`, **mydumper/myloader**): portable entre versiones
  y motores, permite restaurar una tabla, **pero** su restauración es lenta y el tiempo crece
  con el dataset. Consistencia solo con `--single-transaction` (**y solo si todo es InnoDB**:
  una tabla MyISAM rompe la consistencia del volcado en silencio).
- **Físico** (**XtraBackup 8.4** para MySQL/Percona; **`mariabackup`** para MariaDB): copia en
  caliente a nivel de fichero, restauración rápida, es lo que hace viable el RTO. Reglas:
  - **La versión mayor de la herramienta debe coincidir con la del servidor.** XtraBackup 8.4
    no respalda datos creados por versiones anteriores a 8.4. XtraBackup 8.0 llegó a EOL en
    junio de 2026.
  - **XtraBackup no vale para MariaDB** (los internals de InnoDB divergieron): usar
    `mariabackup`. Esta confusión produce copias que restauran y luego corrompen.
  - Registra el **LSN/posición de binlog** de cada copia: es el ancla del PITR.
- **PITR**: copia base + **binlogs archivados fuera del host**, con retención definida y
  `binlog_expire_logs_seconds` coherente con esa retención. Sin binlogs archivados, tu RPO es
  la antigüedad del último backup, digan lo que digan las diapositivas.
- **Gate no negociable**: *un backup sin restauración probada no existe*. El SLI es la **edad
  de la última restauración validada** en un host limpio, con verificación de integridad
  (`mysqlcheck`/`CHECKSUM TABLE` o comparación con `pt-table-checksum`) — no "el job terminó
  en verde".
- El plan (RTO/RPO, orden de recuperación, quién declara el desastre, escenario ransomware)
  vive en `bcdr-standards`; el repositorio, la inmutabilidad y el cifrado, en
  `backup-recovery-standards`. Aquí solo la mecánica del motor.

## 4. Calidad y gates de CI

En orden de coste creciente. Los marcados **rompen el build**:

1. **Lint de SQL y de esquema** (sqlfluff, o `skeema lint`): estilo, `sql_mode` estricto,
   `utf8mb4` obligatorio, `ENGINE=InnoDB` obligatorio. **Gate**.
2. **PK obligatoria en toda tabla nueva** y **veto de `FLOAT`/`DOUBLE` para importes** y de
   `utf8`/`utf8mb3`, comprobados sobre el DDL del PR. **Gate**.
3. **Migraciones aplicadas sobre un motor real** de la **misma versión mayor y misma
   distribución que producción** (contenedor/Testcontainers): MySQL 9.7 se prueba contra MySQL
   9.7, no contra MariaDB ni contra SQLite. Los dialectos mienten (§3.1). **Gate**.
4. **Compatibilidad N-1** (expand/contract): el código actual funciona con el esquema nuevo y
   el nuevo con el esquema previo. **Gate**.
5. **Presupuesto de DDL**: el pipeline calcula si el `ALTER` es INSTANT/INPLACE/COPY y, si es
   COPY o toca una tabla por encima de un umbral de filas, **exige aprobación explícita** y
   ruta por gh-ost/pt-osc. **Gate**.
6. **Revisión de planes en consultas críticas** con volumen representativo: un plan sobre
   1.000 filas no predice nada sobre 100 M. Presupuesto de latencia p95 por consulta caliente.
7. **`pt-upgrade`** antes de cada actualización mayor: compara resultados y planes de un
   corpus real de consultas entre la versión actual y la destino.
8. **Consistencia primario-réplica** con `pt-table-checksum` en calendario (la deriva
   silenciosa existe, sobre todo tras incidentes de replicación).
9. **Restauración de prueba automatizada** con cadencia y su resultado como métrica publicada.
10. Datos de prueba sintéticos o anonimizados: **prohibido** clonar producción con datos
    personales a entornos no productivos sin enmascarar.

## 5. Seguridad

- **Superficie de red**: el puerto 3306 **no se expone a Internet jamás**, ni "temporalmente".
  Bind a interfaz interna, filtrado por defecto-denegar (`firewall-policy-standards`), acceso
  administrativo por bastión. Un MySQL con `root@%` accesible es un incidente esperando fecha.
- **Cuentas**: la identidad en esta familia es **`usuario@host`** — el `host` es parte de la
  credencial y es un control de acceso real. **Prohibido `%`** salvo justificación con red
  compensatoria; usuarios distintos para aplicación, migraciones, lectura, backup y
  monitorización, cada uno con el mínimo privilegio (`SELECT,INSERT,UPDATE,DELETE` en **su**
  esquema; nunca `ALL PRIVILEGES ON *.*`, nunca `SUPER`/`GRANT OPTION` para la aplicación).
  Retirar cuentas anónimas y bases de datos de ejemplo en el aprovisionamiento.
- **TLS obligatorio** también intra-red (`require_secure_transport=ON`, `REQUIRE SSL` o mTLS
  por cuenta). Certificados y su ciclo de vida: `cryptography-pki-standards`.
- **Autenticación**: `caching_sha2_password` en MySQL 8.4+/9.7 (`mysql_native_password`
  desactivado por defecto — no lo reactives "para que funcione el driver viejo": actualiza el
  driver). Contraseñas desde el gestor de secretos, nunca en `my.cnf` legible ni en variables
  de entorno del contenedor en claro. `local_infile=OFF` salvo necesidad (vector de lectura de
  ficheros del cliente). `secure_file_priv` acotado o vacío para desactivar `INTO OUTFILE`.
- **CVEs a vigilar (verificados a agosto 2026 — re-verificar, §8)**:
  - **Galera/wsrep**: `CVE-2026-49261` (**CVSS 10.0**, ejecución de comandos vía
    `wsrep_notify_cmd` con el nombre de un nodo *joiner*), `CVE-2026-48165`, `CVE-2026-48163`
    y `CVE-2026-44168` (comandos arbitrarios en el donante durante SST por rsync y mariabackup).
    **Si tienes Galera/PXC, esto es prioridad uno**; mitigación temporal: desactivar
    `wsrep_notify_cmd`. Es además el argumento operativo contra adoptar un clúster síncrono
    sin equipo que lo parchee a ritmo.
  - **MariaDB Connector/C `CVE-2026-44172`**: `mysql_real_escape_string()` **no escapa
    correctamente con el charset `big5`** en protocolo de texto (fix en 3.3.19 / 3.4.9). Es la
    demostración de por qué el escapado manual está vetado: **usa consultas preparadas del
    lado del servidor**, siempre.
  - MySQL entra en el **Oracle Critical Patch Update** trimestral (enero/abril/julio/octubre);
    `CVE-2026-46850` (MySQL Shell, 9.9) y `CVE-2026-46860` (MySQL Router, 9.8) muestran que
    **las herramientas del ecosistema son superficie de ataque igual que el servidor**.
- **Cadena de suministro**: los repositorios de paquetes (Oracle, MariaDB, Percona), las
  imágenes de contenedor y los operadores de Kubernetes son código privilegiado sobre tu dato.
  Fija por *digest*, verifica firma y suma de comprobación del repositorio. **Precedente
  obligatorio de 2026**: *Mini Shai-Hulud* / **CVE-2026-45321** demostró que se pueden
  **falsificar atestaciones SLSA de nivel 3** — la procedencia ya **no** es prueba suficiente
  por sí sola; combínala con pinning por digest, revisión de cambios y detección en ejecución
  (ver `vulnerability-management-standards` y `cicd-standards`).
- **Auditoría**: plugin de auditoría (Percona/MariaDB/Enterprise) donde haya requisito;
  registro de accesos administrativos y de exportaciones masivas (control de exfiltración).
  El **log general está prohibido en producción** (registra credenciales y mata el rendimiento).
- **Datos personales**: clasificación, minimización y borrado real según
  `privacy-engineering-standards`. Recuerda que los **binlogs y los backups también contienen
  el dato borrado** durante su ventana de retención: documéntala.

## 6. Rendimiento y operabilidad

- **El mito de "hay que optimizar la base"**: en la inmensa mayoría de los casos el motor está
  bien y el problema es **la aplicación**: un **N+1** del ORM que emite 3.000 consultas por
  petición, ausencia de índice, `SELECT *` sobre tablas anchas, paginación por `OFFSET`, o una
  transacción abierta durante una llamada HTTP. **Diagnostica antes de tocar `my.cnf`.** Subir
  el buffer pool no arregla un N+1; solo lo hace más rápido de ejecutar 3.000 veces.
  → **Frontera con `caching-cdn-standards`**: poner una caché delante de una consulta sin
  índice es esconder el problema y duplicar estado. Primero el índice o la consulta; la caché,
  después y con criterio.
- **Instrumentación**: `performance_schema` **activado** (con consumers acotados si la memoria
  aprieta) y **el esquema `sys` como interfaz de lectura**: `sys.statement_analysis`,
  `sys.schema_unused_indexes`, `sys.schema_tables_with_full_table_scans`,
  `sys.io_global_by_file_by_bytes`, `sys.innodb_lock_waits`.
- **Consultas lentas**: `slow_query_log` con `long_query_time` bajo (0.1-0.5 s) y
  `log_queries_not_using_indexes` **de forma temporal** (inunda el disco), digerido con
  `pt-query-digest`. La unidad de trabajo es el **agregado por huella de consulta**, no la
  consulta lenta aislada: mil consultas de 20 ms pesan más que una de 2 s.
- **SLI mínimos** a exportar (ver `observability-standards` para la plataforma):
  conexiones usadas vs `max_connections` (y rechazos), QPS por tipo, latencia p95/p99,
  tasa de lecturas físicas del buffer pool, **lag de réplica** (con heartbeat, no solo
  `Seconds_Behind_Source`), espera de bloqueos y deadlocks, tamaño de la lista de historial
  (`History list length` — su crecimiento delata transacciones abiertas), uso de disco del
  datadir y de los binlogs, **edad de la última restauración validada**.
- **Conexiones**: MySQL usa un hilo por conexión; `max_connections` alto es una trampa de
  memoria y de cambio de contexto. **Pool en la aplicación** dimensionado (no 200 conexiones
  por pod), o **ProxySQL/MaxScale** como multiplexor cuando el número de clientes lo exige.
  Thread pool: comunitario en MariaDB y Percona, Enterprise en Oracle MySQL.
- **Transacciones cortas**, `innodb_lock_wait_timeout` y `wait_timeout` acotados,
  `MAX_EXECUTION_TIME` en consultas de lectura de la aplicación. Nada de transacciones abiertas
  esperando a un servicio externo.
- **Deadlocks**: son normales en carga concurrente; la aplicación **debe reintentar** con
  backoff. Si son frecuentes, la causa es orden de bloqueo inconsistente entre transacciones,
  no el motor. `SHOW ENGINE INNODB STATUS` para el último; `innodb_print_all_deadlocks` para
  investigar un patrón.
- **Capacidad**: proyecta tamaño de tablas e índices, IOPS y conexiones con datos; revisa
  trimestralmente. El coste (FinOps) es atributo de diseño: archivado con `pt-archiver` y
  particionado por rango de fecha antes que "más disco".
- **Configuración como código**: `my.cnf` versionado y desplegado por IaC. Cero cambios
  manuales en producción; cada parámetro con motivo escrito y medición antes/después.

## 7. Sostenibilidad y prohibiciones

**Actualizaciones**
- **No se salta versión mayor**: la ruta desde MySQL 8.0 es **8.0 → 8.4 → 9.7**, secuencial;
  el diccionario de datos se actualiza en cada salto. Presupuéstalo como dos proyectos.
- Antes de cada salto: leer las notas de incompatibilidades, correr **`pt-upgrade`** con
  consultas reales, y revisar **palabras reservadas nuevas** (8.4 añadió `MANUAL`, `PARALLEL`,
  `QUALIFY`, `TABLESAMPLE`, entre otras — un nombre de columna sin comillas rompe en el
  arranque de la aplicación, no en la migración).
- Ensayo en preproducción con datos representativos y **ruta de rollback definida** (réplica
  de la versión antigua mantenida hasta validar; una vez actualizado el diccionario, no hay
  vuelta atrás en el mismo datadir).
- Cadencia mínima: parches trimestrales alineados con el CPU de Oracle / las releases de
  MariaDB y Percona; **salto de LTS planificado con 12 meses de antelación** al EOL, no al
  llegar la fecha.
- Revisa cada semestre el estado de la serie que usas contra §8: en esta familia, las fechas
  de EOL se cumplen y dejan sistemas sin parches de seguridad (8.0 y 10.6 murieron en 2026).

**Lista de prohibiciones**
- ❌ Afirmar o asumir que **MariaDB es un drop-in de MySQL** (o viceversa). No lo es desde 2014.
- ❌ Replicación cruzada MySQL↔MariaDB con GTID, o mezclar Group Replication con Galera.
- ❌ **XtraBackup contra MariaDB** (usa `mariabackup`), o herramienta de versión mayor distinta
  a la del servidor.
- ❌ Correr una serie **fuera de soporte** (MySQL 8.0 tras 2026-04-30, MariaDB 10.6 tras
  2026-07-06, Percona Server 8.0 tras jun-2026) sin plan de salida con fecha.
- ❌ **Releases *Innovation* de MySQL o rolling de MariaDB en producción.**
- ❌ MyISAM/Aria para datos de negocio; tablas sin clave primaria explícita.
- ❌ **UUIDv4 como PK** en tablas grandes de inserción intensiva; UUID en `CHAR(36)`.
- ❌ `utf8`/`utf8mb3`; colaciones mezcladas dentro de un esquema o entre `JOIN`.
- ❌ `FLOAT`/`DOUBLE` para importes monetarios.
- ❌ `sql_mode` no fijado explícitamente, o sin modo estricto.
- ❌ `ALTER TABLE` sin `ALGORITHM=`/`LOCK=` explícitos sobre tablas grandes en caliente.
- ❌ `innodb_flush_log_at_trx_commit != 1` o `sync_binlog != 1` en datos que importan, sin ADR
  que documente la ventana de pérdida aceptada.
- ❌ **Concatenar entrada en SQL** o confiar en escapado manual del cliente (ver
  `CVE-2026-44172`): consultas preparadas del lado del servidor, siempre.
- ❌ `root@%`, `ALL PRIVILEGES ON *.*` para la aplicación, cuentas sin restricción de `host`,
  o 3306 accesible desde fuera de la red de servicio.
- ❌ Log general activado en producción; contraseñas en `my.cnf` sin permisos restringidos.
- ❌ Escribir en una réplica; `read_only` sin `super_read_only`.
- ❌ Adoptar Galera/PXC/InnoDB Cluster sin requisito de RPO≈0 medido, sin ensayo de failover
  **y** de SST, y sin capacidad de parcheo rápido (§5).
- ❌ Backup sin restauración probada; PITR sin binlogs archivados fuera del host.
- ❌ Copiar producción con datos personales a entornos no productivos sin anonimizar.
- ❌ Tocar `my.cnf` antes de haber diagnosticado la consulta (§6), o **añadir una caché para
  tapar una consulta sin índice**.
- ❌ Fijar versiones, EOL o comportamiento de un parámetro **de memoria**, sin §8.

## 8. Verificación web obligatoria

Nada de lo anterior en materia de versiones, fechas o licencias se da por bueno sin
comprobarlo. Antes de fijarlo en un entregable:

1. **MySQL**: serie LTS vigente y fechas — `endoflife.date/api/mysql.json` (datos crudos, no
   la página HTML) y el ciclo de vida de Oracle. Confirmar el **modelo CalVer `YY.M`** para
   Innovation/LTS posterior a 9.7 y cuál es la LTS recomendada hoy.
2. **MariaDB**: series LTS y EOL — `endoflife.date/api/mariadb.json` y
   `mariadb.org/about/maintenance-policy/`. **Hueco declarado**: no se ha verificado la fecha
   exacta de EOL de **MariaDB 12.3 LTS** (la política publicada y el feed no coincidían al
   redactar: *binarios comunitarios 3 años + 2 de parches en fuente* frente a EOL a 5 años en
   otras series). **Verifícalo antes de comprometer una ventana de soporte.**
3. **Percona**: versión actual de Percona Server, XtraBackup, Percona Toolkit y PXC en
   `docs.percona.com`; y si ya existe una línea alineada con MySQL 9.7 (a agosto 2026 **no
   existía**).
4. **Divergencia MySQL↔MariaDB**: matriz de compatibilidad oficial de MariaDB
   (`mariadb.com/docs/.../mysql-to-mariadb-compatibility-matrix` e "Incompatibilities and
   Feature Differences") antes de planificar cualquier migración. Cambia con cada release.
5. **Nombres exactos de parámetros** en la versión concreta: `innodb_redo_log_capacity` vs
   `innodb_log_file_size`, defaults de colación `utf8mb4`, defaults de
   `binlog_transaction_dependency_tracking`, y estado del plugin semisíncrono. **Contra el
   manual de la versión, no de memoria.**
6. **CVEs**: Oracle CPU del trimestre (`oracle.com/security-alerts/`), listas de CVE de
   MariaDB Community/Enterprise, avisos de Percona, y el estado de los CVE de Galera/wsrep de
   2026 (`CVE-2026-49261` y familia) y de Connector/C (`CVE-2026-44172`). Priorizar con
   CVSS + EPSS + KEV (`vulnerability-management-standards`).
7. **Cadena de suministro**: incidentes vigentes en repositorios de paquetes e imágenes;
   revisar el estado de **CVE-2026-45321 / Mini Shai-Hulud** y qué garantías de procedencia
   siguen siendo válidas.
8. **Huecos declarados** (no verificados por web en esta redacción — **no rellenar de memoria**):
   - EOL exacto de **MariaDB 12.3 LTS** (punto 2).
   - Estado de soporte de **MariaDB 12.3 en las distribuciones** (Debian/RHEL/Fedora) y qué
     serie empaqueta cada una hoy.
   - Estado de **mantenimiento activo de gh-ost** (última release y cadencia): se verificó que
     sigue siendo la herramienta de referencia recomendada, **no** la actividad del repositorio.
   - Cifras de rendimiento comparadas MariaDB Vector vs pgvector: aparecen en material de
     marketing del proveedor; **no reproducidas ni verificadas de forma independiente**.
   - Fecha exacta de EOL de **Percona Server 8.4** y de XtraBackup 8.4.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
