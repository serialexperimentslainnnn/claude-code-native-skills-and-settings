---
name: lakehouse-standards
description: Use when analytical data lives as an open table format on object storage — deciding whether a lakehouse is warranted at all versus PostgreSQL or a managed columnar warehouse, choosing between Apache Iceberg, Delta Lake, Apache Hudi and Apache Paimon, Iceberg spec v2 versus v3 (deletion vectors, row lineage, VARIANT type), reading the metadata tree of metadata.json, manifest lists, manifest files and snapshots, picking the catalog as the real architecture decision (Iceberg REST Catalog API, Apache Polaris, Unity Catalog, AWS Glue Data Catalog, Project Nessie, Apache Gravitino, Lakekeeper, legacy Hive Metastore/Thrift) and its credential vending, hidden partitioning and partition-spec evolution, expire_snapshots, remove_orphan_files, rewrite_data_files and rewrite_manifests as scheduled maintenance, copy-on-write versus merge-on-read and the real cost of MERGE and DELETE, optimistic concurrency and commit conflicts between two writers, reading one table from Spark, Trino, DuckDB, ClickHouse or Flink, pyiceberg or delta-rs, time travel and snapshot retention, table registration and catalog migration, or table/row/column access control and legally mandated deletion inside an immutable format.
---

# Estándares de lakehouse (formato de tabla abierto)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: un lakehouse **no es un directorio de Parquet con nombre de marketing**. Es un
> **formato de tabla** —un árbol de metadatos versionado sobre un bucket— que compra ACID, evolución
> de esquema, *time travel* y lectura/escritura concurrente, y **se paga en catálogo, compactación y
> mantenimiento permanente**. Si no vas a operar ese mantenimiento, no tienes un lakehouse: tienes
> un pantano con snapshots.

## 1. Alcance y triggers

Aplica al **formato de tabla** y a todo lo que se decide desde él: elección de formato, catálogo,
anatomía de metadatos, particionado y su evolución, mantenimiento de tabla, concurrencia de
escritura, motores de consulta sobre el mismo dato, estrategia de actualización y borrado, y
gobierno/seguridad a nivel de tabla.

Disparadores: `metadata.json`, `snap-*.avro`, `manifest-list`, `.metadata/`, `_delta_log/`,
`.hoodie/`, `format-version`, `iceberg.catalog.type`, `catalog-impl`, `warehouse=`,
`spark.sql.catalog.*`, `USING iceberg` / `USING delta`, `CALL ... system.rewrite_data_files`,
`expire_snapshots`, `remove_orphan_files`, `rewrite_manifests`, `VACUUM`, `OPTIMIZE`, `ZORDER`,
`MERGE INTO`, `FOR SYSTEM_TIME AS OF` / `VERSION AS OF`, `pyiceberg`, `delta-rs`/`deltalake`,
`iceberg-rest`, `polaris`, `nessie`, `gravitino`, `lakekeeper`, `unitycatalog`, `glue_catalog`,
`hive metastore`, `thrift://`, `s3tables`, y las frases que delatan el dominio: "la consulta lee
50.000 ficheros", "el bucket no para de crecer", "dos jobs se pisan al escribir la tabla",
"necesito ver la tabla como estaba el martes", "cambiamos el particionado y hay que reescribirlo
todo", "el borrado de un usuario no se aplica en el histórico".

**No aplica**: ver
- `data-engineering-standards` (**hermana; regla de corte ya escrita allí y espejada aquí sin
  cambios**): el **formato de fichero** —Parquet, tamaño de fichero, compresión, tipado del
  fichero— es **suyo**; el **formato de tabla** —Iceberg/Delta/Hudi, catálogo, snapshots,
  compactación, particionado oculto— es **de aquí**. **Si la decisión la toma el formato de tabla,
  es de aquí; si la toma el proceso que escribe, es suya.** Corolario: la ingesta, la orquestación,
  la idempotencia del job, el *backfill* y el problema de los ficheros pequeños **en origen** son
  suyos; la **compactación como operación de la tabla** es de aquí.
- `data-warehouse-modeling-standards` (**frontera fina, declarada en ambos lados**): el *time
  travel* de un formato de tabla te devuelve **la tabla como estaba**; una **SCD tipo 2** te dice
  **cómo estaba la entidad de negocio**. Son cosas distintas: el primero es una capacidad de
  infraestructura para recuperación y auditoría técnica, con retención de días o semanas; la
  segunda es una decisión de modelado que el negocio consulta indefinidamente. **Sustituir una SCD2
  por *time travel* está prohibido allí y lo está aquí** (§7). Grano, hechos, dimensiones y
  métricas son suyos; esta skill no modela nada.
- `data-platform-standards` (**madre**): **PostgreSQL, Redis/Valkey, Kafka como motor** (particiones
  del topic, retención, *schema registry*), backups y PITR del motor, cifrado en reposo. Su
  principio rector —**un almacén por necesidad, no por moda**— se hereda aquí sin excepción y es
  precisamente el filtro de §2.1: **esta skill no autoriza un lakehouse, decide cómo se hace bien
  uno ya justificado.**
- `object-storage-standards`: **el sustrato es suyo** — buckets, política de bucket, clases de
  almacenamiento y su latencia de rescate, Object Lock y *legal hold*, versionado de objetos, ciclo
  de vida, multipart, `AbortIncompleteMultipartUpload`, checksums, **coste por petición y por
  salida**, y el antipatrón de montar S3 como disco. Aquí, qué **estructura de claves y qué patrón
  de peticiones** produce un formato de tabla encima, y qué exige del bucket. Regla de arbitraje:
  si la pregunta es sobre el **bucket**, es suya; si es sobre la **tabla**, es de aquí. Aviso
  cruzado: **Object Lock en modo *compliance* y una tabla con `expire_snapshots` son incompatibles
  en la práctica** — el mantenimiento no podrá borrar nada (§5).
- `streaming-cdc-standards` (**hermana; frontera declarada en ambos lados**): **cómo se capturan los
  cambios y cómo se procesan en movimiento** es suyo —log de transacciones, Debezium, *snapshot*
  inicial, slots de replicación, semántica de entrega, orden por partición, ventanas y marcas de
  agua—. Aquí, **qué le pasa a la tabla cuando esos cambios aterrizan**: *copy-on-write* frente a
  *merge-on-read*, coste de `MERGE`/`DELETE`, ficheros de borrado y vectores de borrado,
  compactación inducida por el flujo. **El CDC es una fuente típica del lakehouse, no la única**: el
  lakehouse se alimenta igual por lotes; y el CDC alimenta igual a otros destinos (una réplica, una
  caché, un índice de búsqueda). Ninguna de las dos skills presupone a la otra.
- `microservices-architecture-standards`: **outbox, sagas, eventos de dominio y propiedad del dato
  por servicio son suyos**. Un evento de dominio no es una fila de una tabla analítica.
- `privacy-engineering-standards`: **retención, minimización, seudonimización, *crypto-shredding* y
  los derechos del interesado son suyos**. Aquí solo la **restricción técnica** que impone un
  formato inmutable con historia y cómo se ejecuta el borrado dentro de él (§5.3).
- `data-governance-quality-standards` (**ya en disco**): catálogo **de negocio y de metadatos**
  (DataHub, OpenMetadata, Collibra, Atlan…), propiedad y *stewardship*, glosario, contratos de datos,
  linaje como programa y calidad como disciplina. **Frontera obligatoria por el homónimo "catálogo"**:
  el catálogo de este documento (Polaris, Glue, Unity, Nessie, Gravitino) es un **componente de
  tiempo de ejecución** que resuelve el puntero de la tabla, secuencia los *commits* y entrega
  credenciales; el suyo es un **inventario documental y de gobierno**. Regla de corte: **si el
  componente está en la ruta de una consulta, es de aquí; si está en la ruta de una persona que
  busca o gobierna un dataset, es suyo.** Unity Catalog aparece en ambas listas justamente porque
  intenta ser las dos cosas — su faceta de catálogo Iceberg es de aquí.
- `analytics-bi-standards`: la herramienta de BI y el consumo.
- `message-brokers-standards`: el broker como pieza.
- `nosql-standards`, `graph-db-standards`, `vector-db-standards`, `search-engines-standards`,
  `timeseries-db-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`,
  `mysql-mariadb-dba-standards`: otros almacenes, con su propio criterio.
- `aws-standards`/`azure-standards`/`gcp-standards`: **Glue, S3 Tables, Databricks, BigQuery,
  Fabric/OneLake como servicios gestionados** —aprovisionamiento, IAM, red, facturación—; aquí el
  criterio de formato y catálogo que aplica igual en los tres.
- `backup-recovery-standards` y `bcdr-standards`: **el *time travel* no es una copia de seguridad**
  (§7). Qué se copia, con qué cadena y cómo se prueba el restore es suyo.
- `identity-access-management-standards` (la identidad que el catálogo autentica),
  `secrets-management-standards` (las credenciales que el catálogo *vende*),
  `observability-standards`, `sre-practice-standards`, `iac-standards`, `cicd-standards`,
  `kubernetes-standards`, `grc-compliance-standards`, `mlops-standards`, `rag-standards`,
  `python-standards` (`pyiceberg`, `delta-rs`), `jvm-spring-standards` (la JVM y su tuning bajo los
  motores), `scala-standards` (**el Scala que se escribe dentro de un job de Spark o de Flink**:
  aquí el formato de tabla, el catálogo y la mantenimiento; allí el código).
- `sql-standards` (**el lenguaje SQL**). Frontera nombrada porque **`MERGE` aparece en las dos**:
  aquí es una **operación sobre la tabla** —coste copy-on-write frente a merge-on-read, ficheros
  de borrado, compactación, snapshots que deja atrás—; allí es una **cláusula que se escribe**
  —condiciones de coincidencia, no determinismo cuando la fuente duplica filas, alternativas por
  dialecto cuando el motor no la tiene—. Ninguna de las dos duplica a la otra.

## 2. Decisiones por defecto

> Verificar por web versión, licencia, gobernanza y estado real de adopción antes de fijar nada en
> un proyecto real (§8). Este subsector se movió mucho en 2025-2026 y una foto vieja aquí cuesta una
> migración.

### 2.1 La decisión de partida: ¿de verdad hace falta un lakehouse?

**"Lakehouse" es una de las dos etiquetas más vendidas del sector** (la otra la trata
`streaming-cdc-standards`). Antes de adoptarlo, agota esta escalera. Cada escalón evitado es
infraestructura que no operas:

| Situación real | Solución más simple | Cuándo deja de servir |
|---|---|---|
| El dato analítico cabe holgadamente en el motor operacional | **PostgreSQL** con particionado por rango y una réplica de lectura (ver `data-platform-standards`) | Cuando el escaneo analítico compite con la carga transaccional y la réplica ya no absorbe |
| Volumen medio, un equipo pequeño, consultas ad hoc | **Ficheros Parquet + DuckDB** o un motor columnar embebido, sin catálogo ni transacciones | Cuando hay varios escritores, borrados/actualizaciones frecuentes o necesidad de esquema evolutivo |
| Analítica seria sin equipo de plataforma | **Almacén columnar gestionado** (BigQuery, Snowflake, ClickHouse Cloud, Redshift) | Cuando el coste, el *lock-in* o la necesidad de que varios motores lean el mismo dato lo hacen inviable |
| Varios motores deben leer y escribir **el mismo** dato, con ACID, borrados y esquema que evoluciona | **Lakehouse** con formato de tabla y catálogo | — |

**Lo que un directorio de Parquet realmente no te da** —y es la única lista que justifica el salto—:

1. **Atomicidad y aislamiento**: un lector nunca ve una escritura a medias; un `INSERT OVERWRITE`
   fallido no deja la tabla en un estado intermedio.
2. **Borrados y actualizaciones por fila** sin reescribir la partición entera a mano.
3. **Evolución de esquema segura** (añadir, renombrar, reordenar, cambiar tipo dentro de reglas) por
   **ID de columna**, no por posición ni por nombre de fichero.
4. **Time travel y *rollback*** a un snapshot anterior tras una escritura mala.
5. **Escritura concurrente** con control optimista, en lugar de "el último que escribió gana".
6. **Planificación sin listar el bucket**: los metadatos saben qué ficheros hay y qué rangos
   contienen; el listado de S3 deja de ser la operación crítica.
7. **Particionado desacoplado de la ruta**: se puede cambiar sin reescribir el histórico.

**Lo que cuesta, y hay que firmarlo antes**: un **catálogo** que hay que desplegar, autenticar,
respaldar y hacer HA; un **trabajo de mantenimiento periódico** (compactación, expiración,
huérfanos) con su cómputo y su factura; un **modo de fallo nuevo** (la tabla se corrompe si borras
ficheros por debajo del catálogo); y **una pieza más que actualizar y explicar a quien te sustituya**.

Regla: **si nadie del equipo puede nombrar quién ejecuta la compactación y con qué cadencia, todavía
no estás listo para un lakehouse.**

### 2.2 Los tres (cuatro) formatos — estado verificado a agosto 2026

| Formato | Versión verificada | Estado real | Veredicto |
|---|---|---|---|
| **Apache Iceberg** | **1.11.0** (implementación Java, may-2026); **spec v3** en producción | **Es la *lingua franca***: los tres grandes proveedores de nube lo ofrecen gestionado, Snowflake y Databricks lo leen y escriben nativamente, DuckDB tiene escritura, Trino/Flink/Spark/ClickHouse lo soportan. La spec v3 está GA en Snowflake (7-may-2026) y en Databricks Runtime 18.0+ | **Default para cualquier lakehouse nuevo que deba ser multi-motor** |
| **Delta Lake** | **4.3.1** (jul-2026) | Vivo y con el mayor ecosistema de un solo proveedor. Sigue siendo el formato nativo y más optimizado **dentro de Databricks**. UniForm permite exponer una tabla Delta como Iceberg | **Default solo si el centro de gravedad es Databricks**; fuera de ahí, Iceberg |
| **Apache Hudi** | **1.2.0** (jun-2026); rama 0.14.x aún con releases | Maduro, con su diseño centrado en *upserts*, borrados e incremental *pull*. **Su diferenciación histórica se ha erosionado**: Iceberg v3 y Delta incorporaron vectores de borrado y linaje de fila | **No lo elijas para un proyecto nuevo salvo requisito concreto** de su modelo de índices/upserts que hayas probado |
| **Apache Paimon** | 1.x | Nicho **streaming-nativo** (LSM, *upsert* de alto caudal, origen en el ecosistema Flink de Alibaba). Legítimo si tu carga es CDC continuo de altísimo caudal | Excepción justificada, no default |
| **DuckLake** | — | Metadatos en una base de datos relacional en vez de ficheros. **Experimental**: interesante, sin adopción de producción demostrada | **Piloto, nunca producción** |

**Lo que hay que entender de la convergencia (es el dato que decide la elección, y donde más fácil
es quedarse con una foto de 2024)**: **la guerra de formatos terminó en tablas, no por exterminio**.
Iceberg ganó como estándar de interoperabilidad; Delta sobrevive como formato nativo optimizado de
Databricks; y la **spec v3 de Iceberg** absorbió justamente las capacidades que diferenciaban a
Delta —**vectores de borrado, linaje de fila (`_row_id`, `_last_updated_sequence_number`), tipo
`VARIANT`, valores por defecto de columna, tipos geoespaciales, timestamps de nanosegundos y
transformaciones de partición multi-argumento**—, con lo que la disyuntiva "rendimiento o
compatibilidad" dejó de existir. Databricks ha propuesto además converger el **árbol de metadatos**
de Iceberg v4 y Delta 5.0 en una única estructura: **es una propuesta, no un hecho** — vigílala, no
la des por cerrada (§8).

Consecuencia práctica: **la elección de formato es hoy una decisión reversible (*two-way door*) y
barata en comparación con la del catálogo.** Lo que se pierde al cambiar de formato es la historia:
la migración mueve metadatos y a veces reescribe ficheros, pero **los snapshots antiguos y el *time
travel* previo no viajan**. Planifica la migración con un periodo de convivencia y no prometas
histórico consultable a través del corte.

**Sobre `format-version` de Iceberg**: v3 no es retrocompatible hacia atrás — **un lector v2 no
puede leer una tabla v3**, aunque un lector v3 lee tablas v2. Subir `format-version` es un cambio
que **rompe consumidores viejos**: inventaría los motores que leen la tabla **antes** de subirla, no
después. En v3 los ficheros de borrado posicionales dejan de escribirse a favor de **vectores de
borrado** (uno como máximo por fichero de datos y snapshot).

### 2.3 El catálogo: **esta sí es la decisión de arquitectura**

El formato dice cómo se guardan los metadatos; **el catálogo dice cuál es el puntero actual de la
tabla, quién puede leerla y con qué credencial**. Es el punto de serialización de los *commits*, el
límite de la API entre todos los motores y tu dato, y **el sitio donde se produce realmente el
bloqueo de proveedor**. Un formato abierto con un catálogo cerrado no es un lakehouse abierto: es un
producto con un formato de fichero público.

| Catálogo | Estado verificado (ago 2026) | Apertura real | Cuándo |
|---|---|---|---|
| **Apache Polaris** | **1.7.0** (ago-2026); **TLP de la ASF desde el 18-feb-2026**. Servidor REST sin estado sobre PostgreSQL/otros | **Abierto de verdad**: Apache 2.0, gobernanza de fundación, *credential vending* con modelo zero-trust. **Solo Iceberg** | **Default cuando quieres neutralidad de proveedor** y el equipo puede operar un servicio con su base de datos |
| **Catálogo REST gestionado del proveedor** (AWS Glue / S3 Tables, BigLake REST, etc.) | Vivos y con soporte de v3 en AWS desde nov-2025 | Hablan la **API REST de Iceberg**, que es lo que importa; la implementación es del proveedor | **Default pragmático si ya vives en esa nube** y aceptas la dependencia |
| **Unity Catalog** | **OSS 0.5.1** (jul-2026), Apache 2.0, bajo LF AI & Data; expone API REST de Iceberg y de Hive Metastore | **Apertura parcial y esa es la letra pequeña**: la versión OSS va muy por detrás de la gestionada — **linaje, federación y control de acceso fino (RLS, enmascaramiento de columnas, ABAC) son de la versión de Databricks**, no del OSS. Databricks ha declarado intención de cerrar la brecha; **la paridad no está fechada** | Si tu plataforma **es** Databricks, es la elección natural y casi obligada. **No lo adoptes "porque es open source" esperando la funcionalidad del producto** |
| **Project Nessie** | **0.108.4** (jul-2026), activo | Abierto. Su valor propio son **ramas y etiquetas tipo Git** sobre el catálogo (entornos de desarrollo aislados, publicación atómica multi-tabla) | Cuando necesitas ramificación de datos. **Vigila**: se comenta una convergencia con Polaris — verifícalo antes de apostar a cinco años (§8) |
| **Apache Gravitino** | **1.3.0** (jun-2026); TLP de la ASF desde jun-2025 | Abierto. Se posiciona como **"catálogo de catálogos"**: federación de metadatos heterogéneos en su sitio | Cuando el problema es **federar** varios catálogos existentes, no sustituirlos |
| **Lakekeeper** | Implementación REST en Rust, binario único | Abierto | Alternativa ligera a Polaris. **Verifica versión, licencia y madurez antes de producción** |
| **Hive Metastore (Thrift)** | Sin deprecación formal por el proyecto Iceberg, pero **empujado fuera comercial y arquitectónicamente** (p. ej. Starburst retira su imagen empaquetada de HMS en su LTS de ago-2026) | Abierto pero obsoleto en diseño: **sin *credential vending*, sin ramas, SPOF salvo HA cuidadosa, protocolo Thrift** | **Solo para convivir con lo que ya existe. PROHIBIDO en despliegues nuevos** (§7) |

**Reglas del catálogo, en orden de importancia**:

1. **Elige una implementación que hable la API REST de Iceberg.** Es lo que te permite cambiar de
   backend sin tocar la configuración de cada motor. Empezar con Thrift/HMS es firmar una migración
   futura.
2. **Migrar de catálogo es una operación de metadatos**: los ficheros de datos no se mueven, se
   re-registra la tabla. Eso hace la decisión menos irreversible de lo que parece — **pero el riesgo
   real es el *split-brain***: dos catálogos apuntando a la misma tabla durante la transición, con
   dos punteros de snapshot divergentes. Corta escrituras en el origen antes de registrar en el
   destino, sin excepción.
3. **El catálogo es infraestructura crítica de estado**: su base de datos necesita HA, backup y
   restore probado (ver `backup-recovery-standards`). **Si pierdes el catálogo, los ficheros del
   bucket siguen ahí pero no hay tabla.** Ten escrito el procedimiento de reconstrucción desde el
   `metadata.json` más reciente.
4. **Coexistencia planificada, no perpetua**: es legítimo tener Glue para lo heredado y Polaris para
   lo multi-motor. Ponle fecha de fin a la coexistencia o se vuelve permanente.
5. **ADR obligatorio** con el plan de salida escrito: qué motores dependen de él, cómo se re-registran
   las tablas y cuánto se tarda.

### 2.4 Motores de consulta sobre el mismo dato

| Motor | Versión verificada (ago 2026) | Uso |
|---|---|---|
| **Trino** | 483 (jul-2026) | Consulta interactiva federada sobre el lakehouse. Buen default de consulta |
| **DuckDB** | 1.5.5 (jul-2026) | Consulta local y trabajos que caben en una máquina grande. **Considera esto antes que Spark** |
| **Apache Spark** | 4.2.0 (jul-2026); 4.0.4 y 3.5.9 con mantenimiento | Escritura pesada, mantenimiento de tablas, procesos que no caben en una máquina |
| **Apache Flink** | **2.3.0** (jun-2026); 1.20.x aún con parches | Escritura continua desde flujo (ver `streaming-cdc-standards`) |
| **ClickHouse** | — (**no verificado en esta revisión**) | Lectura de Iceberg/Delta; su fuerte es su propio almacenamiento, no el lakehouse |
| Gestionados (Snowflake, Databricks, BigQuery, Athena, EMR, Dremio, StarRocks) | — | Correctos; el criterio es qué **catálogo** exigen |

**Qué significa "abierto" de verdad**: el dato en Parquet + un formato de tabla abierto es condición
**necesaria y no suficiente**. Comprueba las tres, y si falla una no digas que es abierto:
(a) ¿puede **otro** motor **leer** la tabla sin exportarla?; (b) ¿puede otro motor **escribir** en
ella?; (c) ¿el **catálogo** habla un protocolo que implementa alguien más? El escenario más común de
falsa apertura en 2026 no es el formato: es un catálogo propietario que vende credenciales solo a
su propio motor, o una tabla gestionada donde solo el proveedor puede escribir.

## 3. Anatomía, particionado y mantenimiento

### 3.1 El árbol de metadatos — **entenderlo explica el 90 % de los problemas de rendimiento y coste**

Un formato de tabla es una **pila de punteros inmutables**. En Iceberg, de arriba abajo:

```
catálogo  →  metadata.json            (esquema, particionado, propiedades, lista de snapshots)
             └─ snapshot              (un estado completo de la tabla en un instante)
                └─ manifest list      (los manifiestos de ese snapshot, con rangos de partición)
                   └─ manifest file   (los ficheros de datos, con métricas por columna: min/max/nulos)
                      └─ data files   (.parquet) + delete files / deletion vectors
```

Delta usa un **log de transacciones** (`_delta_log/` con JSON incrementales y *checkpoints*
periódicos) y Hudi una **línea de tiempo** (`.hoodie/`), pero las tres consecuencias son las mismas:

- **Una escritura no modifica nada: añade.** Un `commit` es publicar un puntero nuevo. Por eso hay
  ACID, y por eso **el bucket crece por diseño** hasta que alguien limpia.
- **La planificación de la consulta se hace leyendo metadatos, no listando el bucket.** El *pruning*
  ocurre en dos niveles: por rango de partición (en la lista de manifiestos) y por **estadísticas
  min/max por columna** (en el manifiesto). Un motor lento suele estar leyendo demasiados
  manifiestos, no demasiados datos.
- **Los síntomas de "va lento" y "cuesta mucho" son casi siempre metadatos**, no cómputo:
  demasiados snapshots vivos, demasiados manifiestos, demasiados ficheros pequeños, o ficheros de
  borrado sin fusionar. Diagnostica **contando ficheros y manifiestos por partición** antes de tocar
  el clúster.
- **Métricas por columna cuestan espacio de metadatos**: en tablas muy anchas, escribir estadísticas
  de las 500 columnas infla el manifiesto y ralentiza la planificación. Limita las columnas con
  estadísticas a las que se filtran.

### 3.2 Particionado

- **Particionado oculto (Iceberg)**: la partición se declara como una **transformación sobre una
  columna** (`days(event_ts)`, `bucket(16, user_id)`) y el motor la aplica al filtrar por la columna
  original. Frente al particionado por directorios (estilo Hive), elimina la clase de error más
  frecuente del dominio: **la consulta que filtra por `event_ts` pero no por la columna sintética
  `dt`, y escanea la tabla entera sin que nadie lo note hasta la factura**. Con particionado oculto
  esa consulta poda bien; sin él, no.
- **Evolución de particionado**: se puede cambiar la especificación **sin reescribir el histórico**;
  los datos viejos conservan su spec y los nuevos usan la nueva. Es una de las mejores razones para
  adoptar el formato. Dos avisos: (a) el motor tiene que planificar sobre **dos specs a la vez**,
  con su coste; (b) **no es una excusa para no pensar el particionado inicial**, es una salida de
  emergencia.
- **Error clásico y vetado: particionar por columna de alta cardinalidad** (`user_id`, `order_id`,
  `uuid`). Genera millones de particiones minúsculas, hunde la planificación y multiplica las
  peticiones al bucket. Si necesitas agrupar por esa columna, usa **`bucket(N, col)`** (número
  acotado de particiones) o **ordenación/clustering dentro de la partición**, no partición directa.
- **Regla de dimensionado**: apunta a particiones de **cientos de MB a unos pocos GB**. Una
  partición por día que produce 3 MB significa que la partición correcta era el mes.
- **Particiona por la columna por la que filtras** —casi siempre fecha **del evento**, no de
  ingesta— y verifica la poda leyendo el plan, no suponiéndola.

### 3.3 Mantenimiento — **la sección que nadie planifica y la que decide si el proyecto sobrevive**

Los formatos **traen las primitivas; ninguna se ejecuta sola**. Programarlas, dimensionarlas y
vigilarlas es trabajo de plataforma con coste de cómputo real, y va en el presupuesto desde el día
uno.

| Operación | Qué arregla | Si no se hace |
|---|---|---|
| **Compactación** (`rewrite_data_files` / `OPTIMIZE`) | Fusiona ficheros pequeños; opcionalmente ordena o agrupa (Z-order) | Miles de ficheros por partición: planificación lenta, peticiones caras, consultas que degradan cada semana |
| **Expiración de snapshots** (`expire_snapshots` / `VACUUM`) | Elimina snapshots viejos **y los ficheros que solo ellos referenciaban** | **El bucket crece para siempre**, el `metadata.json` acumula snapshots, el listado y la planificación se degradan y la factura sube sin que nadie relacione la causa. **Este es el fallo económico más común del dominio** |
| **Limpieza de huérfanos** (`remove_orphan_files`) | Borra ficheros que están en el bucket pero **ningún** snapshot referencia (restos de jobs que murieron a medias) | La expiración **no** los toca: se acumulan indefinidamente y pagas almacenamiento por basura invisible |
| **Reescritura de manifiestos** (`rewrite_manifests`) | Consolida manifiestos fragmentados | Planificación lenta pese a tener pocos ficheros de datos |
| **Fusión de borrados** (compactación de *delete files* / vectores) | Reduce el trabajo de aplicar borrados en lectura | Tablas *merge-on-read* que se vuelven cada vez más lentas de leer |

Reglas duras:

- **Orden**: compacta primero, **luego** expira snapshots (así la expiración puede liberar los
  ficheros que la compactación dejó obsoletos), después limpia huérfanos y consolida manifiestos.
  Saltarse un paso debilita a los demás.
- **`remove_orphan_files` con ventana de seguridad amplia** (por defecto 3 días; **nunca menor que
  la duración máxima de una escritura en curso**). Una ventana corta borra ficheros de un job en
  vuelo y **corrompe la tabla**. Este es el comando más peligroso del dominio: trátalo como tal.
- **La expiración de snapshots fija tu ventana real de *time travel* y de *rollback***. Decídela
  explícitamente (típico: 7 días), publícala y no la descubras el día que hace falta revertir.
- **Cadencia**: tablas alimentadas por flujo, cada 1-3 horas; tablas por lotes, diaria; huérfanos y
  manifiestos, semanal. Ajusta con la métrica, no con la costumbre.
- **La compactación cuesta cómputo y peticiones**: reescribe datos. En tablas grandes es una partida
  presupuestaria propia y compite con las consultas. Prográmala fuera de la ventana crítica y
  **limita su concurrencia**, o se convierte en el proceso que tumba la plataforma.
- **A escala, el mantenimiento se dispara por señal, no por cron ciego**: número de ficheros, tamaño
  medio, ratio de ficheros de borrado, número de manifiestos y profundidad de snapshots por tabla,
  con el cron como red de seguridad.
- **Nunca borres ficheros del bucket "para limpiar"** ni pongas una regla de ciclo de vida de S3 que
  expire objetos dentro de la ruta de una tabla viva. **Es la forma más rápida y más definitiva de
  destruir una tabla**: el catálogo seguirá apuntando a ficheros que ya no existen. La limpieza se
  hace **siempre** con las primitivas del formato (§7). Ver `object-storage-standards` para la
  regla de ciclo de vida, que aquí queda **vetada sobre rutas de tablas activas**.

### 3.4 Escrituras concurrentes y control optimista

- El modelo es **concurrencia optimista**: cada escritor lee el snapshot actual, prepara sus
  ficheros y **intenta publicar** el puntero nuevo. Si otro publicó mientras tanto, el *commit*
  falla y el escritor **reintenta re-basando su cambio** sobre el snapshot nuevo, si el conflicto lo
  permite.
- **Qué pasa realmente cuando dos jobs escriben la misma tabla**: dos `INSERT` a particiones
  distintas casi siempre conviven (se reintenta y pasa). **Dos operaciones que reescriben los mismos
  ficheros —dos `MERGE`, o un `MERGE` y una compactación sobre la misma partición— entran en
  conflicto de verdad**, y uno de los dos pierde su trabajo entero tras haber gastado el cómputo.
  A caudal alto, el reintento se convierte en *livelock*: nunca consigue publicar.
- Reglas: **un escritor lógico por tabla y partición**; el mantenimiento **no** se solapa con las
  escrituras pesadas sobre las mismas particiones; configura reintentos con *backoff* y **un tope**;
  y si el conflicto es crónico, el problema es el diseño de particionado o la concurrencia del
  pipeline, no el número de reintentos.
- **El aislamiento es a nivel de tabla.** Un cambio que debe ser atómico **entre varias tablas** no
  lo es, salvo que el catálogo lo ofrezca explícitamente (es el argumento propio de las ramas de
  Nessie). No asumas atomicidad multi-tabla.
- **Ramas y etiquetas** (Iceberg branches/tags, Nessie): publicación atómica, entornos de desarrollo
  aislados y auditoría por etiqueta. Útil y correcto; **cada rama viva retiene snapshots y por tanto
  ficheros**: entra en el presupuesto de mantenimiento.

### 3.5 Actualizaciones y borrados: *copy-on-write* frente a *merge-on-read*

El mecanismo de captura de cambios es de `streaming-cdc-standards`; **qué le hace a la tabla es de
aquí**. Es una decisión por tabla, escrita, no un default heredado del ejemplo que copiaste.

| Estrategia | Cómo funciona | Coste de escritura | Coste de lectura | Cuándo |
|---|---|---|---|---|
| **Copy-on-write (CoW)** | Reescribe los ficheros de datos afectados en el *commit* | **Alto**: cambiar una fila reescribe su fichero entero | **Mínimo**: los lectores leen datos limpios | Tablas con actualizaciones poco frecuentes y muchas lecturas. **Default para la capa de consumo** |
| **Merge-on-read (MoR)** | Escribe ficheros de borrado / vectores de borrado y fusiona en la lectura | **Bajo**: el *commit* es rápido | **Creciente**: cada lectura aplica los borrados pendientes | Ingesta continua o CDC de alto caudal. **Obliga a compactación agresiva** |

- **MoR sin compactación programada es una bomba de relojería**: la tabla es rápida de escribir y
  cada día más lenta de leer, con una degradación que nadie atribuye a la decisión que la causó.
- **El coste real de `DELETE` y `UPDATE`**: en CoW, borrar 10 filas repartidas por 10 ficheros
  reescribe los 10 ficheros completos. **Un borrado por cumplimiento normativo que afecte a una fila
  por partición puede reescribir la tabla entera.** Agrupa los borrados en **lotes periódicos** en
  lugar de aplicarlos fila a fila.
- **Iceberg v3 sustituye los ficheros de borrado posicionales por vectores de borrado** (mapa de
  bits, uno como máximo por fichero de datos y snapshot): menos ficheros, lectura más eficiente y
  comparación de borrados entre commits más simple. Es una razón sólida para subir a v3 en tablas
  MoR, **una vez inventariados los lectores** (§2.2).
- **La ingesta continua produce ficheros pequeños por construcción.** No lo trates como un defecto
  del flujo: es el precio de la latencia, y se paga con compactación. Si nadie quiere pagarlo, la
  latencia que querías no era necesaria.

## 4. Calidad y testing — gates

En orden de coste creciente. **Los marcados como gate rompen el build o bloquean la publicación.**

1. **Definición de tabla y propiedades como código**, versionadas y revisadas: esquema,
   `format-version`, especificación de partición, estrategia CoW/MoR, propiedades de compactación y
   de expiración. Una tabla creada a mano desde una consola es una tabla sin dueño. *Gate de CI.*
2. **Toda tabla se registra en el catálogo y se accede por el catálogo.** Prohibido el acceso por
   ruta (`s3://.../table/`) saltándose el catálogo: es la vía directa a la corrupción y a saltarse
   el control de acceso. *Gate de revisión.*
3. **Test de evolución de esquema**: el cambio propuesto se aplica sobre una copia y **se lee con la
   versión de cada motor que consume la tabla**. Renombrar, reordenar y cambiar tipo son legales por
   spec; **eliminar o cambiar de tipo de forma incompatible rompe consumidores**. Un cambio de
   `format-version` es un cambio incompatible mientras exista un lector viejo. *Gate de CI.*
4. **Contrato de la tabla publicada**: eliminar o renombrar una columna consumida, cambiar el grano
   o cambiar la spec de partición **rompe el build** salvo aprobación registrada. La tabla publicada
   es una API (coherente con `data-warehouse-modeling-standards` §4). *Gate.*
5. **Aserciones sobre el dato** (unicidad de clave, no nulos, referencial, rangos): son de
   `data-engineering-standards` §4 y de `data-warehouse-modeling-standards` §4. Aquí solo se exige
   que **bloqueen la publicación del snapshot**, aprovechando que el formato permite escribir en una
   rama y fusionar solo si pasan.
6. **Test de idempotencia de la escritura**: ejecutar la misma carga dos veces produce el mismo
   estado de tabla (mismo recuento, misma suma de control). *Gate de CI en pipelines que escriben.*
7. **Prueba de concurrencia**: dos escritores simultáneos sobre la misma tabla en el entorno de
   pruebas; se verifica que uno reintenta y **ninguno pierde datos en silencio**. Esta prueba no se
   hace nunca y es donde aparecen los fallos de producción.
8. **Salud de tabla como test programado, con umbrales** (no solo panel): número de ficheros por
   partición, tamaño medio de fichero, número de snapshots, número de manifiestos, ratio de ficheros
   de borrado. Superar el umbral **abre un aviso accionable**, no una entrada en un dashboard que
   nadie mira.
9. **Ensayo de *rollback*** documentado y ejecutado en calendario: revertir una tabla a un snapshot
   anterior, medir cuánto se tarda y comprobar que los consumidores lo toleran. Un *rollback* que
   nunca se ha probado no existe.
10. **Ensayo de pérdida de catálogo**: reconstruir el registro de una tabla desde su `metadata.json`
    en un entorno de pruebas. Es el escenario de desastre específico de este dominio.
11. **Dependencias fijadas por hash/digest** en todo proceso con credenciales del *warehouse*
    (`pyiceberg`, `delta-rs`, conectores, imágenes de Spark/Trino). *Gate de CI* (§5).

## 5. Seguridad del stack

### 5.1 Control de acceso: quién lo aplica de verdad

El reparto, verificado y con su punto ciego:

| Control | Quién lo aplica |
|---|---|
| Permisos de espacio de nombres, tabla y columna; alcance de la credencial | **El catálogo** (RBAC del catálogo REST) |
| Restricción de rutas de almacenamiento | **El catálogo**, mediante *credential vending* de credenciales temporales y acotadas |
| **Filtrado de filas y enmascaramiento de columnas** | **El motor**, salvo que tu catálogo implemente control fino — Polaris, por ejemplo, **no** lo hace nativamente |
| Auditoría independiente del motor | **El catálogo** |

**Regla de diseño que se deriva, y es la trampa del dominio**: **nunca dependas de un control fino
aplicado solo en el motor si varios motores pueden obtener credenciales de almacenamiento**. Una
política de filas de Trino no la conoce Spark; y una credencial acotada que da acceso de lectura a
los ficheros entregará las filas sin enmascarar a cualquier cliente que no pase por el motor con
política. Si necesitas RLS/enmascaramiento de verdad: o lo aplica el catálogo, o **restringes el
conjunto de motores que pueden obtener credenciales**, o publicas una tabla derivada ya filtrada.

- ***Credential vending* obligatorio**: los usuarios y los motores **no** deben tener credenciales
  directas del bucket. El catálogo autentica y entrega credenciales temporales de mínimo privilegio.
  Un usuario con claves de S3 del *warehouse* invalida el control de acceso del catálogo entero.
- El catálogo es un **objetivo de alto valor**: autenticación fuerte, TLS, sin credenciales
  estáticas de larga vida, identidades federadas (ver `identity-access-management-standards` y
  `secrets-management-standards`), y auditoría retenida.
- **Separación de escritura y mantenimiento**: la identidad del pipeline escribe; la identidad del
  mantenimiento borra. Que un solo rol pueda borrar ficheros de datos es la superficie con la que se
  destruye una tabla, por error o por ataque.

### 5.2 Sustrato y cadena de suministro

- **Cifrado en reposo** del bucket y **TLS obligatorio** en el acceso; el detalle es de
  `object-storage-standards` y `cryptography-pki-standards`.
- **Object Lock en modo *compliance* sobre rutas de tablas vivas es incompatible con el
  mantenimiento**: `expire_snapshots` y `remove_orphan_files` no podrán borrar nada y el
  almacenamiento crecerá sin límite. Si hay obligación de inmutabilidad normativa, se resuelve con
  **una copia derivada** en un bucket bloqueado, no bloqueando la tabla operativa.
- **Cadena de suministro — no es hipótesis**: el ecosistema de datos lleva desde 2025 bajo una
  campaña sostenida. Precedentes verificados: **Trivy** (mar-2026), **LiteLLM** en PyPI (1.82.7 y
  1.82.8, 24-mar-2026), **Telnyx** (mar-2026), **`durabletask` de Microsoft** (1.4.1-1.4.3,
  may-2026) y **`elementary-data` 0.23.3** (abr-2026, patrón `.pth` que se ejecuta al arrancar el
  intérprete). La generación actual, **"Mini Shai-Hulud" (CVE-2026-45321)**, activa desde finales de
  abr-2026, es un gusano que se propaga entre npm y PyPI, **extrae tokens OIDC de la memoria del
  runner de GitHub Actions** y ha llegado a **falsificar atestaciones de procedencia SLSA nivel 3**.
  Derivas obligatorias aquí:
  - **Fija por hash/digest** todo lo que se instala en un proceso que tiene credenciales del
    *warehouse* o del catálogo; nada de rangos abiertos.
  - **Ventana de cuarentena** de días antes de adoptar una versión recién publicada en entornos con
    credenciales de producción.
  - **La atestación de procedencia ya no es prueba suficiente** por sí sola: combínala con
    cuarentena y con mínimo privilegio del *runner*.
  - Un *runner* de mantenimiento de tablas **no debe tener credenciales de más de un entorno**.
- **A ago-2026 no consta compromiso de `pyiceberg` ni de `deltalake`/`delta-rs`** — verifícalo de
  nuevo antes de fijarlo (§8).

### 5.3 Dato personal y borrado en un formato inmutable

**La restricción técnica, que es lo único que decide esta skill** (la política es de
`privacy-engineering-standards`):

- Un `DELETE` sobre la tabla **no borra el dato**: crea un snapshot nuevo en el que la fila no
  aparece. **El dato sigue en los ficheros anteriores y sigue siendo recuperable por *time travel*
  hasta que expiran los snapshots y se limpian los huérfanos.**
- Por tanto, un borrado por obligación legal solo está **completo** cuando: (1) se ejecuta el
  `DELETE`; (2) **se compactan o reescriben** los ficheros afectados; (3) **expiran** todos los
  snapshots que los referenciaban; (4) **se limpian los huérfanos**; y (5) se comprueba que ninguna
  **rama, etiqueta, réplica, copia de seguridad o tabla derivada** conserva la fila.
- **Consecuencia de diseño obligatoria**: la **ventana de expiración de snapshots pasa a ser un
  parámetro de cumplimiento**, no solo de operación. Si el compromiso de borrado es de 30 días, la
  retención de snapshots **debe** ser menor, y hay que decirlo por escrito.
- Cuando lo anterior no sea viable (histórico enorme, borrados frecuentes, obligación de
  inmutabilidad simultánea), la salida es **crypto-shredding** o seudonimización desde el diseño:
  la decisión es de `privacy-engineering-standards`; **la estructura que la hace posible se decide
  aquí y ahora, porque después es una reescritura completa de la tabla**.
- **Minimización**: la columna de PII que no aterriza en la tabla es la que no hay que borrar
  después de un histórico entero.

## 6. Rendimiento y operabilidad

- **Diagnostica por metadatos, no por clúster.** Ante "va lento", mide en este orden: número de
  ficheros de datos leídos, tamaño medio, número de manifiestos, snapshots vivos, ratio de ficheros
  de borrado, y solo entonces CPU y memoria. Añadir *workers* a una tabla fragmentada es pagar más
  por el mismo problema.
- **Métricas mínimas por tabla**, con umbral y alerta: ficheros por partición, tamaño medio de
  fichero, número de snapshots, número de manifiestos, antigüedad de la última compactación,
  antigüedad de la última expiración, bytes totales de la tabla frente a bytes vivos, y **coste de
  peticiones al bucket** (ver `object-storage-standards`).
- **Coste**: en este modelo se paga por **almacenamiento + peticiones + cómputo de consulta +
  cómputo de mantenimiento**. Las dos partidas que la gente olvida son las dos últimas. Presupuesta
  el mantenimiento explícitamente; si no cabe, la tabla está mal dimensionada o el lakehouse era
  innecesario (§2.1).
- **Divergencia entre bytes almacenados y bytes vivos**: es el indicador temprano y directo de que
  la expiración o la limpieza de huérfanos no se está ejecutando. Vigílalo desde el primer día.
- **Ordenación y clustering** dentro de la partición (orden por columna de filtro, Z-order para
  filtros multidimensionales) valen más que añadir particiones. Se aplican en la compactación.
- **Estadísticas de columna acotadas** en tablas anchas: escribirlas todas infla los manifiestos.
- **Propietario por tabla**, publicado, con su SLA de frescura (de
  `data-engineering-standards` §6.2) **y su plan de mantenimiento**. Una tabla sin propietario no
  tiene quien ejecute la compactación, que es como acaban degradadas todas.
- **Runbooks escritos y ensayados**: revertir una tabla a un snapshot; recuperar de una expiración
  demasiado agresiva; reconstruir el registro tras perder el catálogo; parar y drenar escritores
  antes de una migración de catálogo.
- **Un *rollback* es visible para los consumidores**: cambia lo que ya leyeron. Comunícalo; el
  silencio destruye la confianza más rápido que el error.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisa trimestralmente versión de formato, catálogo y motores; y **la convergencia
  Iceberg v4 / Delta 5.0**, que es la propuesta con más capacidad de mover el suelo de este dominio
  a medio plazo. Los saltos de `format-version` se planifican con inventario de lectores.
- **Retirada activa**: tabla sin consumo medido durante un trimestre se marca y se retira, con sus
  ficheros. Un lakehouse acumula por diseño; podar es parte del trabajo.
- **ADR obligatorio** para: adoptar lakehouse (frente a las alternativas de §2.1), elegir formato,
  **elegir catálogo con plan de salida escrito**, estrategia CoW/MoR por tabla, política de
  particionado, ventana de retención de snapshots (**que es también un parámetro de cumplimiento**)
  y plan de mantenimiento con su presupuesto.
- **Cuenta con la convivencia**: durante años vas a tener tablas en dos formatos o dos catálogos.
  Ponle fecha, propietario y criterio de finalización, o se vuelve el estado permanente.

**PROHIBIDO**
- ❌ Adoptar un lakehouse sin descartar antes PostgreSQL, Parquet+DuckDB o un almacén columnar
  gestionado (§2.1).
- ❌ Poner un lakehouse en producción **sin trabajo de mantenimiento programado y con presupuesto**:
  compactación, expiración de snapshots y limpieza de huérfanos.
- ❌ **Borrar ficheros del bucket a mano**, o aplicar una regla de ciclo de vida de S3 que expire
  objetos dentro de la ruta de una tabla viva. Destruye la tabla.
- ❌ `remove_orphan_files` con ventana menor que la duración máxima de una escritura en vuelo.
- ❌ Acceder a la tabla por ruta saltándose el catálogo, o registrar la misma tabla en dos catálogos
  con escritura activa en ambos (*split-brain*).
- ❌ **Hive Metastore/Thrift en un despliegue nuevo.**
- ❌ Adoptar un catálogo sin ADR con **plan de salida** — es donde vive el bloqueo de proveedor, no
  en el formato.
- ❌ Llamar "abierto" a un stack cuyo catálogo solo habla con el motor de su propio proveedor, o
  cuya tabla gestionada solo puede escribir el proveedor.
- ❌ Adoptar Unity Catalog OSS esperando la funcionalidad de la versión gestionada de Databricks
  (linaje, federación, RLS y enmascaramiento **no** están en el OSS).
- ❌ Particionar por columna de alta cardinalidad (usa `bucket(N, col)` o clustering).
- ❌ Confiar en la evolución de particionado para no pensar el particionado inicial.
- ❌ Subir `format-version` (p. ej. a Iceberg v3) sin inventariar los motores lectores: **v2 no lee
  v3**.
- ❌ *Merge-on-read* sin compactación agresiva programada.
- ❌ Aplicar borrados por cumplimiento fila a fila en tablas *copy-on-write*.
- ❌ **Sustituir una SCD tipo 2 por *time travel*** (prohibición espejo de
  `data-warehouse-modeling-standards`).
- ❌ **Usar el *time travel* como copia de seguridad.** Tiene retención de días, vive en el mismo
  bucket, comparte el mismo radio de destrucción y desaparece con la expiración. Ver
  `backup-recovery-standards`.
- ❌ Dar por borrado un dato personal tras un `DELETE`, sin expiración de snapshots ni limpieza de
  huérfanos (§5.3).
- ❌ Object Lock en modo *compliance* sobre la ruta de una tabla activa.
- ❌ Credenciales directas del bucket para usuarios o motores, en vez de *credential vending*.
- ❌ Depender de RLS/enmascaramiento aplicado solo en un motor cuando varios motores pueden obtener
  credenciales.
- ❌ Un solo rol con permiso de escritura y de borrado de ficheros para todo.
- ❌ Varios escritores concurrentes sobre la misma tabla y partición sin diseño de conflicto, o
  mantenimiento solapado con la escritura pesada.
- ❌ Asumir atomicidad entre varias tablas.
- ❌ Dependencias sin fijar por hash/digest en procesos con credenciales del *warehouse* (§5.2).
- ❌ Catálogo sin HA, sin backup y sin ensayo de restauración.
- ❌ DuckLake u otros formatos experimentales en producción.
- ❌ Fijar versiones, licencias, gobernanza o estado de adopción de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2, §3 y §5 son de **agosto de 2026**. Antes de fijar nada en un entregable, verifica:

1. **Iceberg**: versión de implementación (**1.11.0**, may-2026 — confirmado por el feed de
   releases) y estado de la **spec v3** (en producción; GA en Snowflake el 7-may-2026 y en
   Databricks Runtime 18.0+; AWS con vectores de borrado y linaje de fila desde nov-2025). Verifica
   qué motores de **tu** stack leen v3 antes de subir `format-version`.
2. **Delta Lake** (4.3.1, jul-2026) y **Hudi** (1.2.0, jun-2026): versión y actividad reales.
3. **La convergencia**: estado de la propuesta de **árbol de metadatos común entre Iceberg v4 y
   Delta 5.0**. A ago-2026 es una **propuesta de Databricks, no una decisión de la comunidad
   Iceberg**. No la cites como hecho.
4. **Catálogos**: Polaris (1.7.0 ago-2026, TLP de la ASF desde 18-feb-2026), Nessie (0.108.4) **y en
   particular si la comentada convergencia Nessie→Polaris se ha materializado**; Gravitino (1.3.0,
   TLP desde jun-2025); **Unity Catalog OSS** (0.5.1, jul-2026) y **qué funcionalidad concreta sigue
   siendo exclusiva de Databricks** — es el dato que decide si "abierto" significa algo; Glue y S3
   Tables; y el grado real de retirada del **Hive Metastore** en tu distribución.
5. **Motores**: Trino (483), DuckDB (1.5.5), Spark (4.2.0), Flink (2.3.0) y su soporte concreto de
   la versión de spec que uses.
6. **Licencias**: de todo motor y catálogo que recomiendes, y de la capa comercial sobre la que te
   apoyes (Databricks, Snowflake, Dremio, Starburst, Confluent). En este sector cambian sin cambiar
   el nombre del producto.
7. **Cadena de suministro**: advisories recientes de `pyiceberg`, `deltalake`/`delta-rs`, imágenes
   de Spark/Trino y del catálogo, y evolución de **Mini Shai-Hulud (CVE-2026-45321)**.
8. **Object Lock, clases de almacenamiento y coste por petición**: contrástalo con
   `object-storage-standards` §5 y con la tarifa vigente del proveedor.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **ClickHouse**: no verificados versión, licencia ni estado de su soporte de Iceberg/Delta.
- **Lakekeeper**: no verificados versión, licencia ni madurez de producción. No lo recomiendes sin
  comprobarlo.
- **Apache Paimon**: no verificada la versión exacta ni su cadencia de releases; solo su
  posicionamiento streaming-nativo.
- **Hudi**: no verificada la relación entre la rama 1.2.x y la 0.14.x (ambas con releases en
  jun-2026), ni cuál es la recomendada por el proyecto.
- **Convergencia Nessie/Polaris**: recogida como comentario del ecosistema, **no verificada** en
  fuente del proyecto.
- **Cifras de coste de mantenimiento**: no hay dato verificado; mide en tu plataforma antes de
  presupuestar.
- **Iceberg v4**: no verificado ningún calendario ni acuerdo de comunidad.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
