---
name: data-engineering-standards
description: Use when moving or transforming data on a schedule — deciding whether a pipeline is needed at all versus a read replica, a federated query or a nightly COPY, ELT versus ETL, batch/incremental/streaming ingestion, managed connectors versus custom code (Airbyte, Fivetran, Meltano, dlt, Singer taps), SQL transformation with dbt (dbt_project.yml, models/, dbt build, dbt test, dbt Fusion) or SQLMesh (audits, virtual data environments), data-pipeline orchestration with Airflow (DAGs, @task, assets), Dagster, Prefect, Kestra or Mage, watermarks, partitions, idempotent backfill and reprocessing, Parquet layout, compression and the small-file problem, partition pruning as a cost decision, freshness SLA versus availability SLA, pipeline retries, silent pipeline failure, data lineage or the data on-call rotation.
---

# Estándares de ingeniería de datos

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando el dato **se mueve o se transforma de forma repetida**: la decisión de si hace falta
un pipeline, la ingesta, la transformación, la orquestación, el reprocesado, los formatos de
fichero, el coste de escaneo, la observabilidad del dato y la operación de todo ello.

Disparadores: `dbt_project.yml`, `profiles.yml`, `models/`, `dbt run|build|test|source freshness`,
`dbt deps`, `sqlmesh plan`, `audits/`, `dag.py`, `@dag`/`@task`, `airflow dags`, `@asset`,
`dg`/`dagster dev`, `prefect deploy`, `flows/*.yml` de Kestra, `meltano.yml`, `tap-`/`target-`,
`dlt.pipeline(...)`, `airbyte`, `fivetran`, `COPY`/`UNLOAD`, `MERGE`, `INSERT OVERWRITE`,
`.parquet`, `_SUCCESS`, `part-00000-*`, `watermark`, `backfill`, `reprocesar`, "el pipeline
falló", "faltan datos de ayer", "los datos están viejos", "el informe se ejecutó antes que el
ETL", "duplicados tras el reintento", "la query cuesta 40 € cada vez".

**No aplica**: ver
- `data-warehouse-modeling-standards` (**hermana; frontera declarada en ambos lados**): ella
  decide **la forma del destino** —grano, hechos y dimensiones, SCD, capas, métricas—; esta
  decide **cómo el dato llega hasta ahí y se recalcula sin romperse**. Un pipeline sin modelo
  produce un pantano; un modelo sin pipeline es un diagrama. Si la pregunta es "¿qué columnas y
  a qué grano?", es de ella; si es "¿cómo se recarga marzo sin duplicar?", es de aquí.
- `data-platform-standards` (**madre**): PostgreSQL como motor operacional, Redis/Valkey, Kafka
  como motor (particiones, retención, registry), backups y PITR, cifrado en reposo. Su principio
  rector —**un almacén por necesidad, no por moda**— se hereda aquí sin excepción: esta skill no
  autoriza almacenes nuevos, solo el movimiento entre los que ya se justificaron.
- `lakehouse-standards` (**Ola 4, planificada**): el **formato de tabla** —Iceberg, Delta Lake,
  Hudi—, catálogo REST, snapshots, *time travel*, compactación y mantenimiento de tabla,
  particionado oculto y evolución de partición. Aquí solo el **formato de fichero** (Parquet), el
  tamaño de fichero y la escritura idempotente. Regla de corte: **si la decisión la toma el
  formato de tabla, es de `lakehouse-standards`; si la toma el proceso que escribe, es de aquí**.
- `streaming-cdc-standards` (**Ola 4, planificada**): Debezium, conectores de log, *snapshot*
  inicial, tratamiento de `DELETE` y *tombstones*, orden y *exactly-once* en streaming. Aquí solo
  el **criterio de cuándo la captura de cambios es la respuesta** y qué obliga aguas abajo.
- `data-governance-quality-standards` (**Ola 4, planificada**): contratos de datos como programa,
  catálogo, propiedad, *stewardship*, política de calidad. Aquí su **ejecución en el pipeline**:
  las aserciones que rompen la ejecución y el gate de frescura.
- `analytics-bi-standards` (**Ola 4, planificada**): la herramienta de BI y el consumo. La
  **definición de métrica** cae en `data-warehouse-modeling-standards`, no aquí.
- `microservices-architecture-standards`: **outbox, eventos de dominio y propiedad del dato por
  servicio son suyos**; aquí solo el consumo analítico de esos eventos.
- `privacy-engineering-standards`: **retención, borrado, minimización y dato personal son suyos**;
  aquí se **ejecutan** (columnas que no se copian, particiones que se dropean, entornos sin PII).
- `object-storage-standards`: **S3 como sustrato** —buckets, claves, clases de almacenamiento,
  Object Lock, ciclo de vida, multipart—; aquí qué ficheros se escriben dentro.
- `observability-standards`: telemetría **del sistema** (OTel, Prometheus, cardinalidad). La
  **observabilidad del dato** —frescura, volumen, esquema, distribución, linaje— es de aquí; la
  línea es: si la señal describe el proceso (CPU, latencia, errores HTTP), es suya; si describe el
  dato (llegó tarde, llegaron 0 filas, cambió el esquema), es de aquí.
- `sre-practice-standards` (SLO, error budget, on-call como práctica), `incident-management-standards`
  (el proceso del incidente), `cicd-standards` (el pipeline de CI que despliega el pipeline de
  datos), `iac-standards`, `kubernetes-standards`, `python-standards` (calidad del código Python
  del job), `secrets-management-standards` (las credenciales del almacén),
  `identity-access-management-standards`, `backup-recovery-standards`, `bcdr-standards`,
  `grc-compliance-standards`, `aws-standards`/`azure-standards`/`gcp-standards` (Glue, Data
  Factory, Dataflow, MWAA, BigQuery/Redshift/Synapse **como servicios gestionados**),
  `mlops-standards` (**feature store, train/serve skew y pipeline de entrenamiento son suyos**),
  `rag-standards` y `llm-app-engineering-standards`, `ai-governance-standards`.
- Motores concretos: `nosql-standards`, `timeseries-db-standards`, `search-engines-standards`,
  `message-brokers-standards`, `graph-db-standards`, `vector-db-standards`, `oracle-dba-standards`,
  `sqlserver-dba-standards`, `mysql-mariadb-dba-standards` (todas **Ola 4, planificadas**).
- `r-standards` y `julia-standards` (**Ola 5, escritas**): la **plataforma** —ingesta, orquestación,
  idempotencia, *backfill*, Parquet, frescura— es de aquí; el **código de análisis** que corre en un
  paso del pipeline es suyo. Si un script de R o de Julia se ha convertido de facto en el
  orquestador, el problema es de esta skill.
- `scala-standards` y `python-standards` (**Spark es la confusión más probable**: la plataforma
  —dimensionado del clúster, particiones, *shuffle*, formato de salida, orquestación del job y su
  idempotencia— **es de aquí**; el **Scala o el Python que se escribe dentro del job** —estilo,
  efectos, tests, build con sbt o con `uv`— es de la skill del lenguaje).
- `sql-standards` (**el lenguaje SQL**). **dbt/SQLMesh como herramienta y la estructura del
  proyecto son de aquí** —materializaciones, orquestación, tests de datos, *backfill*,
  idempotencia—; el **SQL que ese modelo contiene** está sujeto a `sql-standards`: joins, CTEs y
  funciones de ventana, `NULL`, predicados SARGables, estilo y linting con `sqlfluff`. Generar el
  SQL con una plantilla **no lo exime** de ese criterio.

**Principio rector**: **todo pipeline se ejecutará dos veces.** Por reintento, por *backfill*, por
un despliegue duplicado o por un humano nervioso a las 3 a.m. Un proceso que no puede repetirse
sin cambiar el resultado no es un pipeline: es un script con suerte. La idempotencia no es una
optimización, es la condición de entrada.

**Corolario de escepticismo**: este sector vende herramienta a un ritmo que ninguna organización
puede operar. Cada pieza nueva del *stack* es un componente más que actualizar, monitorizar,
asegurar y explicar a quien te sustituya. Antes de añadirla, exige la necesidad medida.

## 2. Decisiones por defecto

> Verificar la última versión, licencia y **propietario** por web antes de fijarlo en un proyecto
> real (§8). Este sector consolidó fuerte en 2025-2026: varias herramientas cambiaron de dueño o
> de licencia sin cambiar de nombre.

### 2.1 La decisión de partida: ¿hace falta un pipeline?

Antes de elegir herramienta, agota por este orden. Cada escalón que evites es infraestructura que
no operas:

| Necesidad real | Solución más simple | Cuándo deja de servir |
|---|---|---|
| Consultar datos operacionales sin castigar la BD | **Réplica de lectura** del motor (ver `data-platform-standards`) | Consultas analíticas que barren tablas enteras y compiten con la replicación |
| Cruzar dos fuentes ocasionalmente | **Consulta federada** (FDW de PostgreSQL, `read_parquet`/`ATTACH` de DuckDB, external tables) | Volumen que hace la federación lenta o cara; necesidad de histórico |
| Un informe diario sobre datos de ayer | **`COPY`/`UNLOAD`/export nocturno** a ficheros + consulta sobre ellos | Más de un puñado de fuentes, o transformaciones con dependencias entre sí |
| Un dashboard de una tabla | **Vista materializada** en el propio motor | Cruce entre sistemas distintos |
| Todo lo anterior insuficiente | **Pipeline** con orquestador | — |

Una consulta federada, una réplica de lectura o un `COPY` nocturno resuelven **más casos de los
que la industria admite**. El coste de un pipeline no es escribirlo: es mantenerlo vivo durante
cinco años mientras las fuentes cambian sin avisar.

### 2.2 ELT frente a ETL

**ELT por defecto**: extrae, carga en crudo, transforma **dentro** del almacén con SQL. El almacén
moderno invirtió el orden por tres razones concretas, no por moda:

1. El cómputo del almacén es elástico y escala mejor que un servidor de ETL propio.
2. La **capa cruda inmutable** permite reprocesar sin volver a la fuente — y la fuente casi nunca
   te deja volver (APIs con retención corta, sistemas que sobrescriben).
3. La transformación en SQL es revisable, testeable y comprensible por más gente que un grafo de
   una herramienta gráfica.

**ETL sigue siendo correcto** cuando: la ley prohíbe que el dato crudo aterrice (PII que debe
seudonimizarse **antes** de la carga — coordinar con `privacy-engineering-standards`), el volumen
crudo es absurdo frente al útil, la fuente exige transformación en el mismo proceso de lectura, o
el destino no tiene cómputo (un fichero, un SFTP). Decisión por ADR, no por defecto invertido.

### 2.3 Toolchain

| Ámbito | Default | Estado verificado (ago 2026) | Alternativa justificable |
|---|---|---|---|
| Transformación SQL | **dbt Core** | dbt Labs **completó la fusión con Fivetran el 1-jun-2026**. dbt Core sigue **Apache 2.0**; dbt Core v2.0 (basado en el motor Fusion) publicado en el repo `dbt-core` bajo Apache 2.0, en alpha. El binario **dbt Fusion es propietario**, bajo *dbt Product Licensing Agreement* | **SQLMesh**: donado por Fivetran a la **Linux Foundation (mar-2026)**, gobernanza abierta. Es hoy la alternativa con mejor posición de gobernanza, no un experimento |
| Orquestación (pesada, estándar de mercado) | **Airflow 3.3.x** | 3.3.0 (jul-2026). **Airflow 2 llegó a EOL el 22-abr-2026**: cualquier 2.x en producción es software sin parches | Astronomer/MWAA/Composer si no quieres operarlo |
| Orquestación (declarativa, orientada a activos) | **Dagster 1.13.x** | **Prefect anunció la adquisición de Dagster Labs el 13-jul-2026**; la compañía combinada opera bajo el nombre Prefect desde ago-2026. Dagster y Dagster+ siguen mantenidos y el OSS continúa bajo su licencia actual | Prefect 3.x si ya lo usas |
| Orquestación ligera / declarativa en YAML | **Kestra 1.x** | Releases activas (rama 1.3.x y LTS 1.0.x) | — |
| Ingesta con código, en tu proceso | **dlt** (1.29.x) | Librería Python, sin servidor que operar. **Default cuando el conector no existe** | Singer taps si ya hay uno bueno |
| Ingesta con conectores gestionados | **Fivetran** (SaaS) si el presupuesto lo cubre | Airbyte: plataforma y conectores estratégicos bajo **Elastic License 2.0** — *source-available*, **no OSI open source**; restringe ofrecerlo como servicio gestionado | **Meltano** (4.x) para orquestar taps Singer con configuración versionada |
| Formato de fichero columnar | **Parquet** | Sigue siendo el default indiscutido del ecosistema. Formatos nuevos (Vortex —incubación en LF AI & Data—, Lance, Nimble) resuelven cargas de IA/acceso aleatorio: **piloto, no producción** para analítica general | ORC solo si el ecosistema existente lo impone; **nunca CSV/JSON como formato de destino** |
| Motor de consulta local / pipelines pequeños | **DuckDB 1.5.x** | Reemplaza legítimamente a Spark en el rango de "cabe en una máquina grande", que es la mayoría | — |
| Compresión | **zstd** por defecto; snappy si el motor lo prefiere y la CPU es el cuello | — | gzip solo por compatibilidad heredada |
| Motor distribuido | **Ninguno por defecto** | Spark/Flink solo cuando el volumen no cabe en una máquina grande, **medido** | — |

**Sobre los orquestadores, con honestidad**: la mayoría de las organizaciones que instalan Airflow
no lo necesitaban. Un `systemd` timer, un cron con bloqueo (`flock`) y un log decente cubren un
pipeline lineal de tres pasos. El orquestador se gana su coste cuando hay **dependencias reales
entre tareas, reintentos por tarea, backfill parametrizado y visibilidad compartida** — no cuando
hay tres jobs que se ejecutan en orden. Instalar Airflow para eso es pagar un clúster para
sustituir a `&&`.

**Sobre el riesgo de continuidad tras la consolidación**: dbt, SQLMesh, Census y Fivetran están
hoy bajo el mismo techo; Dagster y Prefect también. Eso no invalida ninguna herramienta, pero sí
obliga a: (a) preferir el proyecto con gobernanza de fundación cuando el resto empata —SQLMesh
está en Linux Foundation, dbt Core no—, (b) registrar en el ADR **cuál es el plan de salida** de
la pieza propietaria, y (c) no construir sobre funcionalidad exclusiva de la capa comercial sin
decidirlo.

## 3. Estructura y convenciones

### 3.1 Capas de un pipeline

Tres zonas, con reglas distintas. (**La forma de la capa de consumo la decide
`data-warehouse-modeling-standards`; aquí solo el contrato de movimiento entre zonas.**)

1. **Cruda / aterrizaje**: copia fiel de la fuente, **inmutable**, particionada por fecha de
   ingesta, con metadatos de procedencia (`_ingested_at`, `_source`, `_batch_id`, `_source_file`).
   No se limpia, no se renombra, no se corrige. Su valor entero está en que puedes reconstruir
   todo lo demás desde ella.
2. **Intermedia / preparada**: tipado, deduplicación, normalización de nombres, aplicación de
   reglas de calidad. Es la capa donde vive la lógica fea.
3. **Consumo**: la que ven las personas y las herramientas de BI. **Debe ser aburrida**: nombres
   estables, tipos estables, sin lógica sorprendente.

### 3.2 Ingesta: elige el modo más barato que cumpla

| Modo | Cuándo | Trampa |
|---|---|---|
| **Completo (*full refresh*)** | Tablas pequeñas, dimensiones, fuentes sin marca de cambio | Escala pésimamente y borra el histórico si la fuente sobrescribe |
| **Incremental por marca de agua** | Tabla con `updated_at` fiable e índice | **`updated_at` casi nunca es fiable**: relojes desalineados, actualizaciones en masa que no lo tocan, borrados que no dejan rastro |
| **Captura de cambios (CDC)** | Necesitas borrados, orden y baja latencia sobre una BD | Acoplamiento al log del motor; carga operativa real (ver `streaming-cdc-standards`) |
| **Streaming** | La latencia de negocio se mide en segundos **y alguien actúa en esos segundos** | Casi nadie necesita segundos; casi todos los piden |

Reglas duras de ingesta:
- **Solapa la ventana**: lee desde `max(watermark) - Δ`, con Δ ≥ el desfase de reloj y la latencia
  de escritura de la fuente. Después deduplica por clave. Una ventana sin solape pierde filas en
  silencio, que es el peor fallo posible.
- **Los borrados no se propagan solos.** Si la fuente borra físicamente y tú ingieres por marca de
  agua, tu copia acumula fantasmas para siempre. Decide explícitamente: CDC, *full refresh*
  periódico de reconciliación, o borrado lógico acordado con la fuente.
- **Escribe la marca de agua después de confirmar la escritura**, nunca antes. Al revés se pierden
  datos; así solo se reprocesan.
- Guarda el fichero/lote crudo antes de parsearlo. Cuando el parseo falle a los seis meses, será
  lo único que te salve.

### 3.3 Idempotencia y reprocesado — la sección que separa un pipeline de un script

- **Unidad de trabajo = partición**, no "la ejecución de hoy". Una tarea recibe un intervalo
  explícito y produce **exactamente** la partición de ese intervalo.
- **Escritura por reemplazo de partición**, no por acumulación: `INSERT OVERWRITE` / `DELETE`
  del rango + `INSERT` en la misma transacción / `MERGE` por clave. Nunca `INSERT` a secas en una
  tarea que puede reintentarse.
- **Nada de `now()`, `CURRENT_DATE` ni "el último fichero" dentro de la lógica.** El tiempo entra
  como **parámetro** de la ejecución. Un pipeline que consulta el reloj no puede reprocesar el
  pasado, y por tanto no puede corregirse.
- **Backfill = la misma tarea, otro parámetro.** Si hace falta un script distinto para recargar
  marzo, el diseño está mal. El backfill se ejecuta acotado (rango a rango, con límite de
  concurrencia) para no tumbar la fuente ni el almacén.
- **Clave de negocio y deduplicación explícitas**: toda tabla tiene una clave declarada y un
  criterio de "cuál gana" ante duplicados (típicamente el más reciente por `_ingested_at`).
- **Efectos laterales no idempotentes** (enviar un correo, llamar a una API que cobra, publicar un
  evento) fuera del pipeline de datos, o protegidos por clave de idempotencia y registro de
  ejecución. Un reintento no debe facturar dos veces.
- **Ficheros: escribe a temporal y renombra/publica al final** (o usa el commit atómico del formato
  de tabla, ver `lakehouse-standards`). Un consumidor no debe ver nunca una partición a medias.

### 3.4 Formatos y ficheros

- **Parquet como default columnar** para todo dato analítico persistido. CSV solo como formato de
  intercambio con terceros; JSON solo como aterrizaje crudo de una API.
- **Tamaño de fichero objetivo: ~128 MB - 1 GB** por fichero (ajustar al motor). El **problema de
  los ficheros pequeños** es real y caro: miles de ficheros de 2 MB multiplican las peticiones a
  S3, hinchan los metadatos y hunden el planificador. Compacta como tarea programada.
- Particiona por la columna por la que **filtras**, normalmente fecha del evento (no de ingesta) —
  y con **cardinalidad baja**. Particionar por `user_id` genera un millón de directorios y es un
  incidente, no un diseño.
- Tipos correctos en el fichero: fechas como fecha, decimales como decimal (**dinero jamás en
  float**), *timestamps* con zona. Un Parquet con todo en `string` desperdicia el formato entero.
- Escribe el esquema, no lo infieras en cada lectura. La inferencia de esquema es la causa número
  uno de que "el pipeline funcionaba ayer".

### 3.5 Coste: el particionado es una decisión de dinero

En BigQuery, Athena, Snowflake, Redshift Spectrum y cualquier motor sobre object storage **se paga
por dato escaneado**. Por tanto:

- **Poda de particiones verificada, no supuesta**: revisa el plan (`EXPLAIN`, bytes estimados) de
  las consultas caras. Una función sobre la columna de partición en el `WHERE` anula la poda
  entera y multiplica la factura sin avisar.
- `SELECT *` en una tabla ancha columnar es un error de coste, no de estilo.
- **Materializa lo que se consulta muchas veces**; deja como vista lo que se consulta poco. La
  tabla intermedia que nadie consulta se paga en cada ejecución y no la lee nadie.
- Presupuesto por consulta y por proyecto, con alerta. El coste es un SLI (§6), no una sorpresa de
  fin de mes.
- El *full refresh* nocturno de una tabla de miles de millones de filas es correcto exactamente
  hasta que ves lo que cuesta al año. Entonces se vuelve incremental, con reconciliación completa
  periódica.

## 4. Calidad y testing — gates

En orden de coste creciente. **Los marcados como gate rompen el build o la ejecución.**

1. **Lint y formato de SQL y de Python** (`sqlfluff`/formateador del ecosistema, `ruff` — ver
   `python-standards`). *Gate de CI.*
2. **El proyecto compila sin ejecutar nada**: `dbt parse`/`dbt compile`, `sqlmesh plan` en entorno
   virtual, `airflow dags list`/import de todos los DAGs sin error. Un DAG que no importa rompe el
   *scheduler* entero. *Gate de CI.*
3. **Nada de credenciales ni de referencias a producción en el repo**: los perfiles y las
   conexiones vienen de gestor de secretos (ver `secrets-management-standards`). *Gate de CI.*
4. **Tests unitarios de la lógica de transformación** con datos fijos de entrada y salida esperada
   (`dbt` unit tests, `sqlmesh` unit tests, o SQL sobre fixtures). Cubre el caso feliz **y los
   bordes**: nulos, duplicados, fila que llega dos veces, cadena vacía frente a nulo, valor fuera
   de catálogo, fecha en el futuro. *Gate de CI.*
5. **Aserciones de datos en la ejecución** (no en CI): unicidad de la clave, no nulos en las
   columnas críticas, integridad referencial contra la dimensión, rango/valores aceptados, y
   **volumen dentro de banda esperada**. La detalle del programa de calidad es de
   `data-governance-quality-standards`; aquí la regla es de ejecución:
   - Una aserción **bloqueante** detiene la publicación de la capa de consumo. Publicar datos
     malos es peor que no publicar.
   - Una aserción **de aviso** no detiene nada pero se contabiliza y se revisa; si nadie la mira,
     bórrala — el ruido de calidad entrena al equipo a ignorar las alertas de calidad.
6. **Frescura de fuentes** (`dbt source freshness` o equivalente) **antes** de transformar: si la
   fuente no ha llegado, no se transforma sobre datos viejos en silencio.
7. **Idempotencia probada explícitamente**: un test que ejecuta la misma partición **dos veces** y
   comprueba que el resultado es idéntico (mismo recuento, misma suma de control). Sin este test,
   la idempotencia es una intención. *Gate de CI en pipelines que escriben.*
8. **Entorno de desarrollo aislado** por rama/usuario (esquema propio, entorno virtual de SQLMesh,
   `target` de dbt): nadie desarrolla contra las tablas de producción.
9. **Ejecución diferencial en PR**: construir solo lo modificado y lo aguas abajo, sobre una
   muestra acotada, y comparar contra producción cuando el motor lo permita. Un PR que no se ha
   ejecutado nunca no está revisado.
10. **Sin PII real en entornos no productivos** (ver `privacy-engineering-standards`). *Gate.*

## 5. Seguridad del stack

- **Cadena de suministro — precedente vivo, no hipótesis**: el paquete **`elementary-data` 0.23.3`**
  (herramienta de calidad del ecosistema dbt, >1M descargas/mes) fue publicado con **infostealer**
  el 24-abr-2026, vía inyección de script en un workflow de GitHub Actions disparado por comentario
  de PR; el *payload* iba en un fichero `.pth` que Python ejecuta **al arrancar el intérprete**, y
  robaba perfiles de dbt, credenciales de Snowflake/BigQuery/Redshift, claves de AWS/GCP/Azure,
  secretos de Kubernetes, tokens de API, claves SSH y ficheros `.env`. Corregido en 0.23.4. En el
  mismo periodo: **LiteLLM** (mar-2026) y **Microsoft `durabletask`** (may-2026) en PyPI. Deriva
  obligatoria:
  - **Fija dependencias por hash** (`uv.lock`/`requirements.txt` con hashes, imágenes por
    *digest*). Rango abierto de versiones en una herramienta de datos = credenciales del almacén
    expuestas a la próxima publicación maliciosa.
  - **Retrasa la adopción** de versiones recién publicadas en los entornos que tienen credenciales
    de producción (ventana de cuarentena de días, no de minutos).
  - El *runner* que ejecuta el pipeline **no debe tener credenciales de más de un entorno**.
  - Publica con OIDC y tokens efímeros; nunca tokens estáticos de larga vida (ver `cicd-standards`).
- **Credenciales del almacén**: una identidad por pipeline, con permisos por esquema/dataset, no
  una cuenta de servicio omnipotente compartida. Escritura solo donde escribe; lectura solo donde
  lee. Rotación gestionada (ver `secrets-management-standards`).
- **Mínimo privilegio en la fuente**: el usuario de extracción es de **solo lectura**, sobre las
  tablas o vistas concretas acordadas, con `statement_timeout` para no tumbar el sistema
  operacional. Extraer de una réplica, no del primario, salvo motivo.
- **Minimización en la extracción**: no copies columnas que no vas a usar. Cada columna de PII que
  no ingieres es un problema de retención, de borrado y de brecha que no tendrás
  (ver `privacy-engineering-standards`).
- **Retención en la capa cruda también**: "guardamos el crudo para siempre" es una decisión de
  privacidad y de coste que alguien tiene que firmar. Particiona por fecha para poder `DROP`.
- **Cifrado en tránsito y en reposo** en todos los saltos, incluidos los buckets intermedios y las
  zonas de aterrizaje (SFTP, `/tmp`, el disco del *worker*).
- **PII fuera de logs y de mensajes de error**: un log de pipeline que imprime la fila que falló es
  una fuga. Registra la clave o el desplazamiento, no el contenido.
- **Nunca SQL por concatenación** de parámetros de ejecución (fechas, nombres de tabla) en jobs
  que reciben entrada externa: parametriza o valida contra una lista blanca.

## 6. Rendimiento y operabilidad

### 6.1 Observabilidad del dato (distinta de la del sistema)

El proceso puede terminar en verde y el dato estar mal. **El fallo silencioso es peor que la
caída**: una caída se ve; una tabla que lleva tres semanas con datos de hace tres semanas se
descubre en un consejo de dirección. Instrumenta cuatro señales por dataset:

| Señal | Qué mide | Alerta típica |
|---|---|---|
| **Frescura** | Antigüedad del dato más reciente | Supera el SLA de frescura acordado |
| **Volumen** | Filas/bytes de la última partición | Fuera de banda respecto al histórico (incluye **0 filas**, el fallo más común y menos alertado) |
| **Esquema** | Columnas, tipos, nulabilidad | Cambio no anunciado en la fuente |
| **Distribución** | Nulos, cardinalidad, rangos de columnas críticas | Deriva brusca |

Además: **linaje** de columna a columna cuando el motor lo permita, o al menos de tabla a tabla.
El linaje no es documentación: es lo que contesta las dos únicas preguntas de una incidencia de
datos —**"¿qué se rompió?"** y **"¿qué depende de ello?"**— y lo que permite avisar a los
afectados antes de que decidan sobre datos falsos.

### 6.2 SLA de frescura frente a SLA de disponibilidad

Son **distintos** y se confunden constantemente. La tabla puede estar disponible al 100 % y
contener datos de anteayer. Publica, por dataset de consumo:

- **Frescura comprometida** ("los pedidos están al día a las 07:00 en día laborable").
- **Ventana de corrección** ("las correcciones de los últimos 3 días se reprocesan; más atrás,
  bajo petición").
- **Propietario** y canal de contacto.

Sin ese compromiso publicado, cada consumidor inventa el suyo y todos se equivocan.

### 6.3 Operación

- **Reintentos con backoff y jitter**, con tope. Un reintento infinito contra una fuente caída es
  un ataque de denegación de servicio contra tu propio proveedor.
- **Timeouts en todo**: consulta, tarea y DAG completo. Una tarea sin timeout puede bloquear el
  *slot* y hacer que nada más se ejecute mientras la frescura se degrada en silencio.
- **Concurrencia acotada** por fuente (*pools*): el pipeline no debe poder tumbar el sistema
  operacional del que extrae. Esto es especialmente cierto en *backfills*.
- **Alertas accionables**: alerta por **síntoma con impacto** (dataset X incumple su SLA de
  frescura), no por "tarea Y falló" cuando el reintento la va a resolver. Cada alerta lleva
  runbook: qué se rompió, qué depende, cómo se reprocesa.
- **Turno de guardia de datos**: si hay compromisos de frescura, hay alguien que responde. Si nadie
  responde fuera de horario, **no prometas frescura fuera de horario** — un SLA que no tiene
  guardia detrás es una mentira documentada. Coordina con `sre-practice-standards`.
- **Runbook de reprocesado** escrito y **ensayado**: cómo recargar un día, cómo recargar un mes,
  cuánto tarda, cuánto cuesta y a quién hay que avisar. Se ensaya en calendario; el día del
  incidente no se improvisa un `MERGE`.
- **Comunicación al consumidor**: cuando un dato publicado era incorrecto, no basta con corregirlo.
  Hay que decirlo. La confianza en la plataforma de datos se pierde por silencio, no por errores.
- Capacidad y coste revisados con cadencia: crecimiento de volumen, duración de las ejecuciones
  críticas (¿la ventana nocturna sigue cabiendo en la noche?), coste por dataset.

## 7. Sostenibilidad y prohibiciones

- **Cadencia de actualización**: mayores del orquestador y del motor de transformación con
  ensayo en un entorno espejo; los EOL se planifican con antelación (precedente: Airflow 2 murió
  el 22-abr-2026 y arrastró a quien no lo miró). Revisa **trimestralmente** licencias y propiedad
  de las piezas: en este sector cambian sin que cambie el nombre del producto.
- **Retirada activa**: todo dataset y todo DAG sin consumo medido durante un trimestre se marca
  para retirada y se retira. Un almacén de datos crece por acumulación por defecto; podar es parte
  del trabajo, no una limpieza opcional.
- **ADR obligatorio** para: adoptar un orquestador, cambiar de motor de transformación, elegir
  estrategia de particionado, introducir streaming, y contratar una pieza SaaS con datos dentro.
- Evita construir sobre funcionalidad exclusiva de la capa comercial de una herramienta sin
  registrar el coste de salida.

**PROHIBIDO**
- ❌ Un pipeline sin haber descartado antes réplica de lectura, consulta federada o export nocturno.
- ❌ Un proceso que no puede ejecutarse dos veces con el mismo resultado.
- ❌ `now()`/`CURRENT_DATE`/"el último fichero" dentro de la lógica de transformación: el tiempo es
  un parámetro.
- ❌ Un script de *backfill* distinto del pipeline normal.
- ❌ Escribir la marca de agua antes de confirmar la escritura del dato.
- ❌ Ventana incremental sin solape, o incremental sin plan explícito para los borrados de la fuente.
- ❌ Transformar la capa cruda: es inmutable. Corregir el crudo destruye la capacidad de reprocesar.
- ❌ Escribir a una ruta que los consumidores leen mientras se escribe (sin publicación atómica).
- ❌ Publicar la capa de consumo con las aserciones bloqueantes en rojo.
- ❌ Alerta de datos sin runbook, o alerta que nadie atiende.
- ❌ Prometer SLA de frescura sin guardia que lo sostenga.
- ❌ Fallo silencioso tolerado: "0 filas" no es éxito.
- ❌ CSV o JSON como formato de destino analítico; Parquet con todo tipado como `string`.
- ❌ Miles de ficheros pequeños sin tarea de compactación.
- ❌ Particionar por columna de alta cardinalidad.
- ❌ `SELECT *` en tablas anchas columnares en producción.
- ❌ Escribir un conector para una fuente que ya tiene uno mantenido y aceptable — y su recíproco:
  adoptar una plataforma de ingesta entera para dos fuentes que `dlt` resuelve en 40 líneas.
- ❌ Streaming porque suena mejor, sin nadie que actúe en la latencia que se compra.
- ❌ Spark porque el dato "es grande", sin haber medido que no cabe en una máquina.
- ❌ Dependencias sin fijar por hash/digest en cualquier proceso con credenciales del almacén (§5).
- ❌ Una cuenta de servicio compartida con permisos totales para todos los pipelines.
- ❌ Copiar columnas de PII "por si acaso"; PII en logs de pipeline.
- ❌ Capa cruda sin política de retención declarada.
- ❌ Fijar versiones, licencias o propiedad de una herramienta de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2 y §5 son de **agosto de 2026** y este sector consolida constantemente. Antes de
fijar nada en un entregable, verifica:

1. **dbt**: licencia vigente de dbt Core (Apache 2.0 a fecha de hoy), estado de dbt Core v2.0
   (estaba en **alpha**) y del binario Fusion (propietario, *dbt Product Licensing Agreement*), y
   qué ha cambiado en la gobernanza tras la fusión con Fivetran (completada 1-jun-2026).
2. **SQLMesh**: estado en la Linux Foundation tras la donación de mar-2026 y actividad real del
   proyecto.
3. **Orquestadores**: versión vigente de Airflow (3.3.0 en jul-2026) y su calendario de soporte;
   **evolución de Dagster tras la adquisición por Prefect (anunciada 13-jul-2026)** — la
   integración de producto y la licencia del OSS son el riesgo a vigilar, no la versión;
   estado de Kestra y de Mage (verificar si Mage sigue mantenido antes de recomendarlo:
   **no verificado en esta revisión**).
4. **Ingesta**: licencia actual de Airbyte (ELv2, *source-available*), modelo de Fivetran tras la
   fusión, y actividad de Meltano y dlt.
5. **Formatos**: si Parquet sigue siendo el default de facto y si algún sucesor (Vortex, Lance,
   Nimble, F3) ha pasado de piloto a producción; estado de la *File Format API* de Iceberg
   (frontera con `lakehouse-standards`).
6. **Cadena de suministro**: CVEs y compromisos recientes de **cualquier** paquete que vayas a
   añadir al entorno con credenciales del almacén (precedentes: `elementary-data` abr-2026,
   `durabletask` may-2026, LiteLLM mar-2026).
7. Versiones y EOL del motor de almacén (BigQuery/Snowflake/Redshift/Databricks/DuckDB) y de los
   *runtimes* Python del pipeline.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Mage**: no verificado su estado de mantenimiento. No recomendarlo sin comprobarlo.
- **Prefect/Dagster**: no verificado si existe compromiso público de licencia OSS a largo plazo más
  allá de "the open source project continues under its existing license"; la nota de prensa no lo
  detalla. Verificar antes de apostar la orquestación a Dagster a cinco años.
- **Parquet v3**: existe discusión en la lista de correo de Apache, sin estado verificado. No
  afirmar nada sobre una v3.
- **Fivetran**: precios y condiciones tras la fusión no verificados.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
