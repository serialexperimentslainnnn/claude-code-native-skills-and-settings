---
name: timeseries-db-standards
description: Use when business, industrial or scientific measurements are stored and queried over time — deciding whether PostgreSQL with range partitioning, BRIN indexes and materialized rollups already suffices before adopting a dedicated engine, TimescaleDB and TigerData (create_hypertable, hypertable, chunk_time_interval, time_bucket, continuous aggregate, add_retention_policy, add_compression_policy, hypercore/columnstore, the tsl/ directory and the Tiger Data License), InfluxDB 3 Core versus Enterprise and the 1.x/2.x/3.x incompatibility mess, InfluxQL and Flux migration, line protocol and InfluxDB Line Protocol/ILP ingestion, QuestDB, VictoriaMetrics as a business data store, TDengine and its AGPL licence, ClickHouse MergeTree/AggregatingMergeTree with TTL as a columnar time-series store, tag versus field modelling and unbounded series explosion from a per-device or per-order identifier, wide versus narrow schema, downsampling and rollup tiers, retention as a business decision, columnar compression ratios and their effect on query speed, batched writes, out-of-order and late-arriving sensor readings from intermittent IoT links, backfills, updates and deletes as the expensive operation, SQL versus proprietary query languages, time-bucket aggregation, gap filling and interpolation, or historians, OT/SCADA archives and sensor telemetry retention.
---

# Estándares de bases de datos de series temporales

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: casi todo el que instala una TSDB lo hace por volúmenes que **PostgreSQL ni
> nota**. Una tabla particionada por rango con índice BRIN y unas vistas materializadas absorbe
> miles de millones de filas en hardware corriente. La TSDB no es un *upgrade* gratis: es **un motor
> más que operar, respaldar, parchear y saber consultar**. Empieza demostrando que el default no
> vale.

## 1. Alcance y triggers

Aplica a **almacenar y consultar medidas fechadas de negocio, industriales y científicas**: sensores
y telemetría OT/IoT, contadores de energía, series financieras, lecturas de laboratorio, eventos de
uso agregados por tiempo. Cubre la decisión de motor, el modelado de la serie, la retención y la
resolución, la compresión, la ingesta, el patrón de consulta y la operación.

Disparadores: `create_hypertable`, `chunk_time_interval`, `time_bucket`, `time_bucket_gapfill`,
`add_continuous_aggregate_policy`, `add_retention_policy`, `add_compression_policy`, `hypercore`,
`columnstore`, `_timescaledb_internal`, `USING BRIN`, `PARTITION BY RANGE (ts)`, `influxd`,
`influxdb3`, `line protocol`, `ILP`, `InfluxQL`, `Flux`, `questdb`, `SAMPLE BY`, `LATEST ON`,
`vmagent`/`vminsert`/`vmselect` como almacén de negocio, `taosd`, `MergeTree ORDER BY (id, ts)`,
`AggregatingMergeTree`, `TTL ... DELETE`/`TTL ... GROUP BY`, y las frases del dominio: "guardamos
lecturas de sensores", "el histórico ocupa terabytes", "la consulta del último año tarda minutos",
"queremos ver la media por hora", "el dato llega con horas de retraso porque el equipo estuvo sin
cobertura", "hay que rellenar los huecos", "¿cuánto tiempo guardamos el detalle?".

**No aplica**: ver
- `observability-standards` (**frontera crítica de esta skill, y se declara aquí sin ambigüedad**):
  **todo el stack de monitorización es suyo** — Prometheus, PromQL, Mimir, Thanos, exporters,
  *scrape*, *recording rules*, Alertmanager, exemplars, muestreo, el Collector de OpenTelemetry, y
  **el control de cardinalidad de las métricas del sistema**. Regla de corte: **si la serie mide el
  comportamiento de tu software o tu infraestructura y existe para diagnosticar un incidente, es
  suya; si la serie es dato del negocio o del proceso físico —lo que produjo la planta, lo que
  midió el sensor, lo que cotizó el activo— y alguien la va a consultar, facturar o auditar meses
  después, es de aquí.** Consecuencias prácticas de la línea: la retención de una métrica de CPU se
  decide por presupuesto de observabilidad (allí); la retención de una lectura de contador se decide
  por obligación contractual o regulatoria (aquí). Un mismo motor puede servir a los dos usos —
  **VictoriaMetrics es el caso obvio**— y eso **no** mueve la frontera: la decide el propósito del
  dato, no el binario. **Y si es el mismo clúster para ambos, es un error de aislamiento** (§6).
- `data-platform-standards` (**madre**): **PostgreSQL como motor es suyo** — modelado, índices,
  migraciones, *tuning*, réplicas, HA, PITR, cifrado en reposo, clasificación y retención GDPR.
  Aquí, **el patrón temporal sobre ese motor** (particionado por rango con fin de retención, BRIN,
  agregados materializados) y **cuándo deja de bastar**. Su principio —**un almacén por necesidad, no
  por moda**— es la premisa de §2.1.
- `message-brokers-standards` (**hermana de Ola 4; la línea se declara en ambos lados**): **un
  broker transporta las medidas, una TSDB las almacena para consultarlas.** El broker —MQTT, Kafka,
  NATS—, su topología, retención, seguridad y operación son suyos. **La escritura en el almacén y
  todo lo que pase después es de aquí.** Se cruzan exactamente en la ingesta IoT: el broker recibe
  del dispositivo, un consumidor escribe por lotes en la TSDB. **El broker no es el almacén** (§7).
- `streaming-cdc-standards` (**regla de corte espejada palabra por palabra**): *si la decisión la
  toma el broker, es suya; si la toma el productor, el consumidor o el procesador, es de aquí* —
  aplicada a este par, **lo que el consumidor hace al llegar el dato (semántica de entrega,
  idempotencia, orden, ventanas, marcas de agua, retraso del consumidor, reprocesado, cola de
  fallidos) es suyo**; **cómo queda ese dato escrito, comprimido, agregado y caducado en el almacén
  es de aquí**. Su "dato tardío" es una decisión de ventana; el mío es una escritura fuera de orden
  contra un *chunk* ya comprimido.
- `data-warehouse-modeling-standards`: el modelo analítico (estrella, grano, SCD, dimensión de
  calendario). Una serie temporal **no es una tabla de hechos periódica** por defecto; si el dato
  acaba en un mart, el modelado es suyo.
- `lakehouse-standards`: el histórico frío en formato de tabla abierta sobre almacenamiento de
  objetos. **El escalón siguiente cuando la TSDB deja de ser el sitio correcto para 5 años de
  detalle** (§3.5).
- `data-engineering-standards` (ingesta por lotes, orquestación, *backfill*),
  `data-governance-quality-standards` (propiedad, catálogo, contratos y calidad del dato),
  `analytics-bi-standards` (el cuadro de mando que lo pinta), `nosql-standards` (Cassandra/Mongo
  como motor genérico; aquí solo si se usa **como** serie temporal), `search-engines-standards`,
  `vector-db-standards`, `graph-db-standards`, `object-storage-standards` (el almacenamiento
  subyacente y su coste por capa), `backup-recovery-standards` (mecánica del respaldo y restauración
  probada), `bcdr-standards` (RTO/RPO), `sre-practice-standards`, `privacy-engineering-standards`
  (**una serie por dispositivo o por persona puede ser dato personal**: minimización, retención y
  derecho de supresión son suyos), `grc-compliance-standards` (obligación legal de conservación),
  `kubernetes-standards`, `linux-storage-standards`/`zfs-standards` (el disco de abajo),
  `aws-standards`/`azure-standards`/`gcp-standards` (Timestream, Managed Prometheus, Monarch y demás
  gestionados), `python-standards`, `mlops-standards` (previsión y detección de anomalías sobre la
  serie: el modelo es suyo, el almacén es de aquí),
  `oracle-dba-standards` y `mysql-mariadb-dba-standards` (**ya en disco**: el *tuning* y la
  operación de esos motores son suyos), `sqlserver-dba-standards` y `caching-cdn-standards`
  (**Ola 4, planificadas**).

**Principio rector**: **la resolución y la retención son decisiones de negocio, no de
infraestructura.** Todo lo demás —motor, compresión, particionado— se deriva de responder *cuánto
detalle hace falta y durante cuánto tiempo*. Un equipo que no ha respondido eso no está listo para
elegir motor.

## 2. Decisiones por defecto

> Verificar versión, licencia y **propiedad** por web antes de fijarlo en un proyecto real (§8).
> **Este dominio ha cambiado de licencia y de dueño repetidamente**: Timescale se renombró a
> **TigerData** (17-jun-2025) e InfluxDB ha roto la compatibilidad **dos veces**.

### 2.1 La pregunta previa: ¿por qué no PostgreSQL?

**PostgreSQL, bien usado, es una base de datos de series temporales perfectamente decente.** Antes
de introducir un motor nuevo, agota esta escalera y **escribe en el ADR en qué escalón te quedas**:

| Escalón | Qué haces | Hasta dónde llega de verdad |
|---|---|---|
| **1. Tabla normal** | `timestamptz` + clave de serie, índice compuesto `(serie, ts DESC)` | Millones de filas. La mayoría de los proyectos que "necesitan TSDB" viven aquí y no lo saben |
| **2. Particionado declarativo por rango de tiempo** | Partición por día/semana/mes; **la retención se convierte en `DROP TABLE`, que es instantáneo**, en vez de un `DELETE` masivo que genera *bloat* | Cientos de millones a miles de millones de filas. **Este escalón es el que casi nadie prueba** |
| **3. Índice BRIN** sobre la columna de tiempo | Índice diminuto que aprovecha la correlación física entre orden de inserción y tiempo | Ideal en tablas *append-only* ordenadas por tiempo: cuesta una fracción de un B-tree en espacio y escritura |
| **4. Agregados materializados** (vistas materializadas refrescadas, o tablas de *rollup* mantenidas por *job*) | Precalculas medias/máximos/sumas por hora y por día | La consulta del cuadro de mando deja de tocar el detalle. **Es el 80 % del beneficio de una TSDB, con el motor que ya tienes** |
| **5. TimescaleDB** (extensión) | Automatiza 2, 3 y 4 y añade **compresión columnar** y agregados continuos incrementales | **Sigue siendo PostgreSQL**: mismo SQL, mismos *drivers*, mismo respaldo, mismo equipo. **Es el primer paso legítimo fuera del default** |
| **6. Motor dedicado** | InfluxDB, QuestDB, ClickHouse, VictoriaMetrics, TDengine | Solo con una medición que demuestre que 1-5 no llegan |

Las tres preguntas que zanjan la discusión:

1. **¿Cuántos puntos por segundo se ingieren de verdad, medidos, en el pico?** Si la respuesta es
   "no lo sabemos" o "unos cuantos miles", el escalón 2-4 sobra.
2. **¿Cuál es la consulta que duele?** Si es "media por hora del último mes de 50 sensores", un
   agregado materializado la resuelve en milisegundos. Si es "escaneo ad-hoc de 3 años de detalle
   crudo con agrupaciones arbitrarias", ahí sí hay caso para un columnar.
3. **¿Quién opera el motor nuevo a las 3 de la madrugada?** Si la respuesta es "el mismo que ya
   opera PostgreSQL y no tiene tiempo", la respuesta correcta es el escalón 5, no el 6.

**Corolario incómodo**: el argumento "es que es dato de series temporales" **no es una
justificación**. Serie temporal es la forma del dato, no un requisito de motor.

### 2.2 Qué hace especial a una serie temporal (y por qué eso permite trucos)

Estas cuatro propiedades son las que un motor especializado explota; **si tu carga no las cumple,
el motor especializado no te dará su ventaja** y estarás pagando la operación sin el beneficio:

| Propiedad | Consecuencia técnica que habilita |
|---|---|
| **Escritura casi siempre por adición y en orden de tiempo** | Estructuras de escritura secuencial; sin actualización en sitio; índice de tiempo casi gratis (BRIN) |
| **Consulta casi siempre acotada por rango de tiempo** | Particionado/*chunking* por tiempo → **poda de particiones**: la consulta ni mira el 99 % de los datos |
| **El dato envejece y pierde valor** | Retención por caducidad y ***downsampling***: el detalle de hace tres años casi nunca hace falta al segundo |
| **Valores contiguos de una misma serie se parecen mucho** | **Compresión columnar con codificación delta y delta-de-delta**: ratios de un orden de magnitud, imposibles en un motor de filas genérico |

**La consecuencia práctica más importante**: en un motor especializado, **comprimir suele acelerar
las consultas analíticas** (menos E/S, mejor uso de caché) a costa de encarecer las modificaciones
puntuales sobre datos ya comprimidos. En un motor genérico, comprimir es solo ahorrar disco.

### 2.3 Toolchain

| Ámbito | Default | Estado verificado (ago 2026) | Alternativa justificable |
|---|---|---|---|
| **Punto de partida** | **PostgreSQL particionado + BRIN + agregados materializados** | Motor y versión los fija `data-platform-standards` | Ninguna: es el escalón 0 |
| **Primer paso especializado** | **TimescaleDB 2.29.0** (28-jul-2026) sobre PostgreSQL | **Licencia dual, verbatim del fichero `LICENSE`**: fuera del directorio `tsl/`, **Apache 2.0**; dentro de `tsl/`, **Timescale License (TSL)**. Se compilan objetos separados y **los binarios con `-tsl` en el nombre son TSL**. La empresa se renombró **Timescale → TigerData (17-jun-2025)** y la TSL aparece hoy como *Tiger Data License* | Ninguna si ya usas PostgreSQL: es la opción de menor coste organizativo |
| **Columnar generalista** (gana más casos de los que se admite) | **ClickHouse 26.7.x** (26.7.2.59-stable, 3-ago-2026) | **Apache 2.0** (verbatim del `LICENSE`, © 2016-2026 ClickHouse, Inc.) | Es la respuesta correcta cuando además hay analítica ad-hoc pesada sobre el histórico |
| **Motor dedicado con SQL y baja latencia de ingesta** | **QuestDB 9.4.3** (15-jun-2026) | **Apache 2.0** (verbatim del `LICENSE.txt`). Hay edición Enterprise comercial: **verifica sus términos antes de contar con HA o seguridad avanzada** (§8) | Nicho: alta frecuencia (finanzas, tick data) con SQL |
| **Motor dedicado de métricas usado como almacén** | **VictoriaMetrics v1.148.0** (20-jul-2026); líneas LTS **v1.136.x** y **v1.122.x** | Repositorio **Apache 2.0**. **Modelo *open core*: hay compilaciones Enterprise con sufijo `enterprise` que exigen `-license`/`-licenseFile`**, con funciones propias (retención por *tenant*, recuperación ante desastres, detección de anomalías). La comprobación de licencia ocurre **solo al arrancar** | Válido, pero **cuidado con la frontera**: si tu caso es monitorización, la skill es `observability-standards` |
| **Motor dedicado orientado a IoT/OT** | **TDengine 3.4.1.6** (`ver-3.4.1.6`, 30-abr-2026) | **AGPL v3** (verbatim del `LICENSE`). **La AGPL es una decisión de política de licencias de la organización, no un detalle**: consúltalo antes de adoptarlo, y más si el producto se ofrece a terceros | Solo con caso industrial claro y AGPL aceptada |
| **InfluxDB** | **No es el default. Adóptalo con los ojos abiertos** (§2.4) | **3.10.0** (17-jun-2026). El repositorio actual (motor v3, en Rust) lleva **`LICENSE-APACHE` + `LICENSE-MIT`** (doble licencia permisiva) y corresponde a **InfluxDB 3 Core**. **Enterprise es comercial** | Solo si ya tienes ecosistema Influx, o si el proveedor gestionado es la vía |
| **Histórico frío de años** | **Formato de tabla abierta sobre almacenamiento de objetos** | Ver `lakehouse-standards` | Tiered storage del propio motor si lo ofrece y lo has probado |
| **Gestionados** | Válidos y muchas veces correctos | Los servicios concretos son de las skills de nube | ADR con coste de salida y formato de exportación **probado** |

### 2.4 InfluxDB: el aviso que hay que dar por escrito

**InfluxDB ha roto la compatibilidad dos veces y eso es un dato de arquitectura, no una anécdota.**
Lo verificado a agosto de 2026:

- **1.x** (InfluxQL, TSM) y **2.x** (Flux, organizaciones/*buckets*) son **líneas distintas con
  lenguaje de consulta distinto**. **3.x** es un **motor nuevo reescrito en Rust** (Arrow/Parquet)
  con SQL e InfluxQL — y **Flux no está soportado en la línea 3**: quien construyó su plataforma
  sobre Flux tiene por delante una **reescritura de consultas**, no una actualización.
- **1.x y 2.x están en mantenimiento**: sin funciones nuevas. No hay fecha de EOL forzosa publicada,
  pero **construir algo nuevo ahí es deuda comprada a sabiendas**.
- **La línea 3 se parte en dos productos**: **Core** (libre, permisivo, **de un solo nodo**) y
  **Enterprise** (comercial: alta disponibilidad, multinodo, compactación para consultas de rango
  largo, certificaciones y soporte). Traducción sin adornos: **la edición libre de InfluxDB 3 no
  cubre alta disponibilidad**, y el rendimiento en consultas históricas largas está asociado a
  funcionalidad de la edición comercial.
- **Aviso operativo verificado**: la etiqueta `latest` de las imágenes Docker de InfluxDB pasa a
  apuntar a **InfluxDB 3 Core el 15-sep-2026**. **Fija la etiqueta por versión**; si no, un
  `docker pull` te cambia de motor mayor sin avisar.

**Criterio**: para un despliegue nuevo, InfluxDB solo es la elección correcta si aceptas
explícitamente la edición comercial o el gestionado, **o** si tu caso es de un solo nodo y sin
compromiso de disponibilidad. En cualquier otro escenario, TimescaleDB o ClickHouse te dan más
certidumbre por menos riesgo de producto.

## 3. Modelado, retención e ingesta

### 3.1 Etiquetas frente a campos, y **la explosión de cardinalidad**

En los motores con modelo de etiquetas (Influx, VictoriaMetrics, TDengine, Prometheus), cada
combinación distinta de valores de etiqueta **crea una serie**, y las series son la unidad de coste
en memoria, en índice y en tiempo de consulta.

- **Etiqueta** = por lo que se agrupa o filtra. **Debe tener un conjunto de valores acotado y
  conocido de antemano**: `planta`, `linea`, `tipo_sensor`, `unidad`.
- **Campo** = el valor medido. No se indexa como dimensión: `temperatura`, `presion`, `kwh`.

**La explosión de cardinalidad es EL fallo estructural de este dominio, y aquí se dice para dato de
negocio, no para métricas de sistema** (eso es de `observability-standards`): **meter un
identificador único como etiqueta —`id_pedido`, `id_transaccion`, `numero_serie` de un parque de
millones de equipos, `uuid` de sesión— mata cualquier motor de series temporales.** No lo degrada:
lo mata. El síntoma llega tarde y siempre igual: la ingesta va bien durante semanas, luego el
consumo de memoria crece sin techo, las consultas se vuelven impredecibles y el motor acaba
reiniciándose. **Y no se arregla borrando la etiqueta: las series ya creadas persisten en el
índice.**

Reglas duras:
- **Ningún identificador de alta cardinalidad como etiqueta.** Si hay que conservarlo, va como
  **campo** (no indexado) o en una **tabla de dimensión** aparte, unida en la consulta.
- **Presupuesto de series declarado por adelantado**: multiplica los cardinales de tus etiquetas
  antes de escribir la primera línea. Si el producto supera lo que tu motor aguanta, el diseño está
  mal, no el motor.
- **Alerta sobre el número de series activas**, no solo sobre disco y CPU. Es el indicador
  adelantado que evita el incidente.
- **Si tu dato es intrínsecamente de alta cardinalidad** —una medida por pedido, por transacción,
  por usuario— **el modelo de etiquetas es el modelo equivocado**. Usa un motor **columnar sin
  índice de series** (ClickHouse, TimescaleDB con columna normal): ahí la cardinalidad es una
  columna más, no una explosión combinatoria. **Este es el criterio de elección de familia más
  útil de toda la sección.**

### 3.2 Esquema ancho frente a estrecho

| Modelo | Forma | Cuándo |
|---|---|---|
| **Estrecho** (`ts, serie, metrica, valor`) | Una fila por medida | Métricas heterogéneas y cambiantes; añadir una magnitud no toca el esquema. **Coste: más filas, y comparar dos magnitudes exige auto-unión o pivote** |
| **Ancho** (`ts, serie, temperatura, presion, caudal, …`) | Una fila por instante de muestreo, una columna por magnitud | **Default cuando el conjunto de magnitudes es estable** y se muestrean juntas. Menos filas, mejor compresión columnar, consultas triviales |

Regla: **si el equipo emite las mismas N magnitudes en el mismo instante, el esquema es ancho.** El
estrecho se elige cuando el catálogo de magnitudes es abierto o cambia sin control tuyo. Decídelo
por escrito: **cambiarlo después es reescribir el histórico.**

Además:
- **`timestamptz` siempre, y almacenamiento en UTC, sin excepción.** La zona horaria es una
  decisión de presentación. Los cambios de hora destruyen series almacenadas en hora local, y el
  bug aparece dos veces al año durante años.
- **Resolución del tiempo declarada** (segundo, milisegundo, microsegundo) y coherente con lo que el
  equipo puede medir de verdad. Guardar nanosegundos de un sensor que muestrea cada 5 s es coste sin
  información.
- **La calidad de la medida es parte del dato**: en OT, el `quality`/estado del punto y la unidad de
  ingeniería se guardan; una lectura sin marca de calidad no se puede auditar después.

### 3.3 Retención, resolución y *downsampling*

**Esto es una decisión de negocio y hay que arrancársela al negocio por escrito.** Patrón por
niveles, que es el que funciona:

| Nivel | Resolución | Retención típica | Para qué |
|---|---|---|---|
| **Crudo** | La de muestreo | Semanas o pocos meses | Diagnóstico fino, investigación de incidentes, prueba |
| **Agregado fino** | 1 min / 5 min | Meses o 1-2 años | Cuadros de mando operativos |
| **Agregado grueso** | 1 h / 1 día | Años | Tendencia, informes, obligación legal |

Reglas:
- **El agregado se calcula de forma incremental y continua** (agregados continuos de TimescaleDB,
  `AggregatingMergeTree` + TTL con `GROUP BY` en ClickHouse, reglas de *rollup* del motor), **no con
  un job artesanal que recalcula el mes entero cada noche**.
- **Decide qué función agrega cada magnitud**: media para temperaturas, **suma para contadores**,
  **último valor para acumulados**, mín/máx cuando el pico es el dato que importa. **Agregar por
  media un contador es un error de negocio silencioso** que nadie detecta hasta la auditoría.
- **Guarda `count` y `sum`, no solo la media**: con la media no puedes re-agregar a una ventana
  mayor sin sesgo. Con `sum` y `count`, sí. Y **los percentiles no se pueden promediar**: si te los
  van a pedir, guarda un esbozo (*sketch*) o el crudo.
- **La retención se aplica sola y se verifica**: política del motor o `DROP` de partición
  programado, con alerta si no se ejecutó. Una política de retención que nadie comprueba es una
  intención.
- **Antes de borrar el crudo, pregunta si hay obligación de conservarlo** (regulación sectorial,
  contrato, garantía del equipo, litigio). Ver `grc-compliance-standards` y
  `privacy-engineering-standards`.
- **Alternativa al borrado: mover a frío.** El detalle antiguo en Parquet sobre almacenamiento de
  objetos cuesta una fracción y sigue siendo consultable (`lakehouse-standards`). **La decisión
  correcta muchas veces no es "borrar o guardar", es "guardar dónde".**

### 3.4 Ingesta

- **Por lotes, siempre.** La escritura punto a punto es el error de rendimiento número uno del
  dominio: colapsa el motor por sobrecoste por petición mucho antes que por volumen de datos.
  Agrupa por tamaño **y** por tiempo máximo de espera, para no sacrificar frescura.
- **Protocolo**: prefiere **SQL** o el protocolo nativo del motor cuando el productor es tuyo;
  **protocolo de línea (InfluxDB Line Protocol / ILP)** cuando el productor es un agente o un equipo
  de campo que ya lo habla; *remote write* de Prometheus **solo** si el origen es un exporter (y
  entonces revisa si el caso es realmente de `observability-standards`). **Elegir el protocolo por
  el productor, no por gusto.**
- **Datos fuera de orden y tardíos**: en IoT con conectividad intermitente **es lo normal, no la
  excepción** — un equipo sin cobertura vuelca 8 horas de golpe. Antes de elegir motor,
  **comprueba explícitamente qué hace el suyo con una escritura muy anterior a la última**: unos la
  aceptan con coste, otros la descartan en silencio, y en motores con compresión por bloques la
  escritura en un bloque ya comprimido **obliga a descomprimir y reescribir**, que es carísimo.
  **Descarte silencioso = pérdida de dato industrial. Es un criterio de descarte de motor.**
- **Marca de tiempo del dispositivo frente a marca de la recepción**: guarda **la del evento** como
  tiempo de la serie, y considera guardar también la de ingesta. Los relojes de campo se desvían:
  **valida en el borde** un rango razonable y desvía lo imposible (fechas en 1970 o en 2049) a
  cuarentena, en lugar de meterlo en la serie.
- **Idempotencia**: los reenvíos existen. Clave natural `(serie, ts)` con escritura de tipo
  *upsert*/último-gana, y **decidido a propósito** — muchos motores de series **no deduplican** y
  te quedas con el punto duplicado, que descuadra las sumas.
- **Actualizaciones y borrados son LA operación cara.** Estos motores están diseñados para no
  hacerlos. Consecuencias que hay que aceptar de antemano: corregir un histórico mal ingerido es un
  proyecto, no un `UPDATE`; **borrar los datos de un solo dispositivo o de una sola persona puede
  ser desproporcionadamente costoso**, así que si hay derecho de supresión, **particiona por algo
  que permita borrar por bloques** o cifra por sujeto (ver `privacy-engineering-standards`).
- **Backfill masivo**: se hace con la compresión y los agregados **desactivados o pausados** cuando
  el motor lo permite, y se reactivan al terminar. Y se mide en un entorno espejo antes.

### 3.5 Consulta

- **SQL es el default, y la razón es de plantilla, no de elegancia**: cualquiera que sepa SQL
  consulta tu almacén, y **todas las herramientas de BI hablan SQL**. Un lenguaje propio
  —Flux es el ejemplo caro— te ata a un ecosistema, no tiene mercado laboral y **puede
  desaparecer con un cambio de versión mayor del producto** (§2.4). **Adoptar un motor con lenguaje
  propio exige ADR con coste de salida.**
- **Toda consulta lleva filtro de rango de tiempo acotado**, y el filtro debe permitir la poda de
  particiones/*chunks*: nada de envolver la columna de tiempo en una función que impida usar el
  particionado. Una consulta sin límite temporal sobre una TSDB es un escaneo total disfrazado.
- **Agregación por *bucket* de tiempo** (`time_bucket`, `SAMPLE BY`, `toStartOfInterval`,
  `GROUP BY` sobre tiempo truncado) es la primitiva del dominio; **fija la zona horaria del *bucket*
  explícitamente** cuando el informe es de negocio: "por día" significa día local para el usuario y
  día UTC para el motor, y ahí es donde no cuadran los informes.
- **Huecos e interpolación son decisiones de negocio, y hay que declararlas**: ¿un sensor que no
  reportó es un cero, un nulo, o el último valor conocido? **Cero y último-valor-conocido dan
  resultados radicalmente distintos** en un cálculo de consumo. Usa la primitiva del motor
  (relleno de huecos, `LOCF`, interpolación lineal) **y documenta cuál se aplicó en el informe**.
- **Consulta el agregado, no el crudo**, en todo lo que sea cuadro de mando. Si el usuario necesita
  bajar al crudo, que sea un camino explícito y acotado en el tiempo.
- **Funciones de ventana** para deltas, tasas, medias móviles y último valor por serie: son parte
  del contrato del motor. **Un motor de series sin funciones de ventana decentes obliga a sacar los
  datos y calcular fuera**, que es exactamente lo que se quería evitar.

## 4. Calidad y testing — gates

En orden de coste creciente. **Los marcados como gate rompen el build o el despliegue.**

1. **ADR del escalón de §2.1**: por qué no basta PostgreSQL, con el número medido de puntos por
   segundo y la consulta que duele. **Sin este documento no se aprueba la introducción de un motor
   nuevo.** *Gate de diseño.*
2. **Esquema, políticas de retención, de compresión y definiciones de agregado como código**,
   versionadas y aplicadas por el pipeline. Nada creado a mano en producción. *Gate de CI.*
3. **Presupuesto de cardinalidad calculado y verificado en CI**: producto de cardinales de etiquetas
   frente al límite declarado. Un cambio que mete un identificador único como etiqueta **rompe el
   build**. *Gate.*
4. **Prueba de escritura fuera de orden y tardía** con un punto de hace días contra datos ya
   comprimidos: se comprueba que **entra**, y se mide lo que cuesta. *Gate.*
5. **Prueba de duplicado**: reenviar el mismo lote no altera sumas ni recuentos. *Gate.*
6. **Test de corrección de los agregados**: el *rollup* de una ventana conocida coincide con el
   cálculo sobre el crudo, incluida la función correcta por magnitud (suma frente a media). *Gate.*
7. **Test de la política de retención**: que caduque lo que debe **y solo eso**, verificado sobre
   datos sintéticos con fechas al borde.
8. **Prueba de rendimiento con volumen realista**: las consultas críticas contra un conjunto del
   tamaño previsto **a un año vista**, no contra una semana de pruebas. Un plan sobre 10 M de filas
   no predice 10.000 M.
9. **Prueba de restauración completa** del almacén con el motor ingiriendo (§6). Se hace antes de
   producción.
10. **Ensayo de actualización de versión mayor** en espejo con datos representativos, verificando
    formato de almacenamiento y compatibilidad de consultas.
11. **Dependencias e imágenes fijadas por digest**, con SBOM (§5). *Gate de CI.*

## 5. Seguridad del stack

- **TLS en tránsito obligatorio** para ingesta y consulta, también dentro de la red. La telemetría
  industrial que viaja en claro por una red plana es el hallazgo clásico de una auditoría OT.
- **Autenticación y autorización separadas por rol**: un rol de **escritura sin lectura** para los
  agentes de campo (un dispositivo comprometido no debe poder leer el histórico de la planta), uno
  de lectura para BI, uno de administración para nadie salvo operación. **El token de un
  dispositivo es un secreto de campo: rotable, de alcance mínimo y revocable individualmente.**
- **Cifrado en reposo** (volumen o mecanismo del motor) y clasificación del dato: una serie por
  contador doméstico, por vehículo o por dispositivo vestible **es dato personal**; una serie de
  producción de planta es secreto industrial. Ver `privacy-engineering-standards` y
  `data-platform-standards`.
- **Nada de motores de series expuestos a Internet sin autenticación.** Es un patrón real y
  recurrente en instalaciones IoT: interfaz de ingesta abierta "porque los equipos están fuera". La
  ingesta desde campo entra por un punto autenticado, o por el broker (ver
  `message-brokers-standards`), no por el puerto del motor.
- **La interfaz de exploración/consulta también es superficie**: paneles y consolas embebidas sin
  autenticación exponen todo el histórico. Detrás de identidad, siempre.
- **Consultas parametrizadas** en todo lo que construya SQL con entrada de usuario: que sea un motor
  de series no lo hace inmune a la inyección (hay CVE de inyección de 2026 en integraciones que
  concatenan SQL contra ClickHouse).
- **Cadena de suministro**: fija imágenes y clientes **por digest**; genera y conserva SBOM;
  cuarentena de días antes de adoptar versiones recién publicadas. **Precedentes verificados en el
  catálogo**: Trivy (mar-2026), LiteLLM (mar-2026), `elementary-data` (abr-2026) y **Mini
  Shai-Hulud / CVE-2026-45321**, que **falsifica atestaciones SLSA nivel 3**: **la procedencia ya
  no es prueba suficiente por sí sola**.
- **Vigila los CVE del motor concreto y de sus imágenes** (ver `vulnerability-management-standards`).
  ClickHouse publica changelog de seguridad propio e imágenes *distroless* desde abr-2026, que
  reducen mucho el ruido del escáner a cambio de no tener shell dentro del contenedor.

## 6. Rendimiento y operabilidad

- **Compresión: mídela, no la supongas.** Los ratios que publican los proveedores se obtienen con
  series regulares y de baja entropía. El efecto real depende de tu dato. Lo que sí es general:
  **ordenar por `(serie, tiempo)` antes de comprimir es lo que hace que la compresión funcione** —
  un orden de almacenamiento que mezcle series destruye el ratio. Mide **espacio y tiempo de
  consulta antes y después**, en tu dato.
- **SLI del almacén**: puntos ingeridos por segundo y su rechazo, **retraso entre la marca de tiempo
  del dato y su disponibilidad para consulta** (la frescura, que es la métrica que le importa al
  negocio), **número de series activas** (§3.1), latencia p95/p99 de las consultas de cuadro de
  mando, retraso de los agregados continuos, ratio de compresión y **crecimiento de disco
  proyectado**. Instrumentación y backend: `observability-standards`.
- **Aísla los usos.** Si el mismo motor sirve monitorización de plataforma **y** dato de negocio,
  sepáralos en instancias o clústeres distintos: un pico de cardinalidad del lado de las métricas
  no puede tumbar el histórico de producción de la planta, ni al revés. **Y sus retenciones
  responden a dueños distintos.**
- **Réplicas**: replica para tolerar el fallo de un nodo **y** para separar la ingesta continua de
  las consultas analíticas pesadas. **Comprueba antes qué modelo de replicación ofrece la edición
  libre de tu motor**: en varias de las opciones de §2.3, la alta disponibilidad está en la edición
  comercial (InfluxDB 3, y funciones de VictoriaMetrics Enterprise). **Descubrirlo después de
  elegir es el error caro.**
- **Respaldo de un motor que ingiere sin parar**: un copiado de ficheros en caliente **no es un
  respaldo consistente**. Usa el mecanismo de instantánea/respaldo del motor (o instantánea del
  volumen con el motor en un estado consistente), verifica la copia y **ensaya la restauración
  completa con cadencia programada**: el gate es "restauramos y validamos", no "el trabajo terminó"
  (`backup-recovery-standards`). **Presupuesta el tiempo de restauración**: restaurar terabytes
  comprimidos es lento, y ese número es tu RTO real, no el que pusiste en el documento.
- **Cuidado con el argumento "la retención ya es mi respaldo"**: la retención borra, no protege.
  Un borrado accidental o una corrupción se propagan a las réplicas. **La retención no es una copia
  de seguridad** (§7).
- **Actualizaciones**: cambios de versión mayor con lectura de notas de versión, ensayo en espejo y
  **plan de vuelta atrás definido**, sabiendo si el formato de almacenamiento cambia (si cambia, la
  vuelta atrás exige restaurar, no solo desplegar la versión anterior). Nunca una `.0` en
  producción.
- **Capacidad**: proyecta con datos —puntos/s × bytes/punto tras compresión × retención por
  nivel— y revisa trimestralmente. **Disco, retención y resolución son la misma decisión**: si el
  disco no llega, la respuesta correcta suele ser bajar resolución del histórico, no comprar disco.

### 6.1 Casos industriales (OT/IoT) y su frontera

- **La TSDB moderna no sustituye por sí sola a un historiador industrial.** Un historiador aporta
  además contexto de activos, calidad del punto, gestión de eventos y alarmas, e integración con el
  sistema de control. Si el requisito es ese, **la TSDB es una pieza, no la solución**.
- **La frontera con el mundo OT se declara y se respeta**: el sistema de control, los protocolos de
  planta (OPC UA, Modbus y demás), la segmentación de red industrial y el modelo de niveles de la
  arquitectura de planta **no son de esta skill** — la red y su segmentación son de
  `networking-standards` y `firewall-policy-standards`, y la política de seguridad de
  `grc-compliance-standards`. **Aquí empieza el trabajo en el punto donde la medida sale de la
  planta hacia el almacén, y nunca al revés: el flujo es de OT hacia IT, unidireccional.**
- **Diseña para la desconexión**: almacenamiento y reenvío en el borde, ingesta que tolere el
  volcado masivo posterior (§3.4) y control de que ese volcado no tumbe la ingesta normal
  (limitación de tasa en el consumidor).
- **La marca de tiempo la pone el equipo, y su reloj miente.** Sincronización horaria en el borde
  como requisito de diseño, y validación en la ingesta.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisa **cada trimestre** versión, licencia **y propiedad** del motor. Este dominio
  ha visto un renombre de empresa (Timescale→TigerData), un cambio de motor con pérdida de lenguaje
  de consulta (InfluxDB) y varios modelos *open core* que mueven funciones a la edición de pago.
- **Retirada activa**: serie, tabla o política sin consulta medida durante dos trimestres se marca y
  se retira. **Un almacén de series crece por acumulación silenciosa**: nadie borra nada porque
  nadie sabe quién lo usa.
- **ADR obligatorio** para: introducir un motor fuera de PostgreSQL, elegir esquema ancho o
  estrecho, fijar los niveles de resolución y retención, adoptar un motor con lenguaje de consulta
  propio, y depender de una función de edición comercial.

**PROHIBIDO**
- ❌ Adoptar una TSDB sin haber medido la carga real ni descartado por escrito PostgreSQL
  particionado con BRIN y agregados materializados.
- ❌ Usar "es dato de series temporales" como justificación de motor.
- ❌ **Un identificador de alta cardinalidad como etiqueta.** Es el fallo estructural del dominio.
- ❌ Desplegar sin presupuesto de series calculado ni alerta sobre series activas.
- ❌ Escritura punto a punto en la ruta caliente de ingesta.
- ❌ Elegir motor sin comprobar qué hace con las escrituras fuera de orden y tardías; aceptar un
  motor que **las descarte en silencio** para un caso IoT.
- ❌ Guardar la marca de tiempo en hora local, o sin zona.
- ❌ Guardar solo la media en un agregado (impide re-agregar sin sesgo); promediar percentiles;
  **agregar un contador por media**.
- ❌ Almacén sin política de retención aplicada automáticamente y **verificada**.
- ❌ Borrar el detalle crudo sin haber comprobado si hay obligación de conservación.
- ❌ Consulta de cuadro de mando contra el crudo cuando existe el agregado; consulta sin rango de
  tiempo acotado.
- ❌ Rellenar huecos con un criterio implícito y no documentado en el informe.
- ❌ Confiar la corrección de un histórico a `UPDATE`/`DELETE` masivos como si fuera una tabla
  normal.
- ❌ Ingesta o consola de exploración expuestas sin autenticación; TLS opcional "porque es red
  interna".
- ❌ Un mismo clúster para monitorización de plataforma y dato de negocio.
- ❌ Copiar los ficheros del motor en caliente y llamarlo respaldo; **usar la retención como copia
  de seguridad**; no ensayar la restauración completa ni medir cuánto tarda.
- ❌ Adoptar un motor cuya alta disponibilidad esté en la edición comercial **sin haberlo decidido a
  propósito**.
- ❌ Usar el broker como almacén de series (ver `message-brokers-standards`).
- ❌ Empezar algo nuevo sobre InfluxDB 1.x/2.x o sobre Flux; depender de la etiqueta `latest` de una
  imagen de InfluxDB.
- ❌ Adoptar un motor AGPL sin aprobación explícita de la política de licencias de la organización.
- ❌ Fijar versiones, licencias o propiedad de un motor de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2 son de **agosto de 2026**, tomados de `api.github.com` (versiones y fechas) y de los
ficheros `LICENSE` en crudo (licencias). Antes de fijar nada en un entregable, verifica:

1. **TimescaleDB / TigerData**: versión (**2.29.0**, 28-jul-2026) y, sobre todo, **la licencia
   vigente y su alcance**. Verificado *verbatim* en `LICENSE`: **Apache 2.0 fuera de `tsl/`,
   Timescale License dentro de `tsl/`, con binarios `-tsl` separados**. La empresa se renombró a
   **TigerData el 17-jun-2025** y la TSL aparece como *Tiger Data License*. **Comprueba en la
   documentación oficial qué funciones concretas caen en cada lado antes de contar con alguna**
   (compresión, agregados continuos y políticas históricamente han vivido en la parte TSL: no lo
   afirmes sin comprobarlo en tu versión).
2. **InfluxDB**: línea vigente (**3.10.0**, 17-jun-2026), licencia del repositorio del motor v3
   (**Apache-2.0 + MIT**, corresponde a **Core**), estado de mantenimiento de 1.x y 2.x, ausencia de
   Flux en la línea 3, y **qué funciones exactas exige Enterprise** (alta disponibilidad, multinodo,
   compactación para rango largo). Verifica también el cambio de la etiqueta `latest` de Docker
   previsto para el **15-sep-2026**.
3. **ClickHouse** (26.7.2.59-stable, 3-ago-2026, Apache 2.0), **QuestDB** (9.4.3, 15-jun-2026,
   Apache 2.0), **VictoriaMetrics** (v1.148.0, 20-jul-2026; LTS v1.136.x y v1.122.x; Apache 2.0 con
   *open core* Enterprise bajo `-license`) y **TDengine** (`ver-3.4.1.6`, 30-abr-2026, **AGPL v3**).
   Re-verifica versión **y** licencia: las tres últimas tienen edición comercial y el reparto de
   funciones cambia entre versiones.
4. **CVE y avisos de seguridad** del motor concreto y de sus imágenes; y la evolución de **Mini
   Shai-Hulud (CVE-2026-45321)** en la cadena de suministro.
5. **Servicios gestionados**: disponibilidad, límites y modelo de precios del gestionado de tu nube,
   y **el formato y el coste de exportar los datos hacia fuera** antes de entrar.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Reparto exacto de funciones de TimescaleDB entre Apache y TSL**: verificado el mecanismo de la
  licencia dual *verbatim*; **no verificada** la lista de funciones por edición en la 2.29. No
  afirmes que una función concreta es Apache sin comprobarlo.
- **Límite de rango de consulta de InfluxDB 3 Core**: circula la afirmación de que Core está acotado
  a consultas de rango corto. La documentación oficial consultada **solo** dice que Enterprise añade
  *"long-range historical queries with compaction"* y multinodo; **no se ha verificado ningún límite
  numérico de horas**. No cites una cifra.
- **QuestDB Enterprise y TDengine Enterprise**: términos, precio y reparto de funciones **no
  verificados**.
- **ClickHouse como serie temporal**: no verificado el estado del motor de tabla específico de
  series temporales ni su madurez. Usa `MergeTree` con orden y TTL, que es lo comprobado.
- **Ratios de compresión reales**: **no hay ninguna cifra verificada de forma independiente** en
  esta revisión. Todas las publicadas provienen de proveedores. Mídelo en tu dato.
- **Comparativas de rendimiento entre motores**: las disponibles las publican los propios
  fabricantes (incluidas las que comparan Influx con TDengine). Trátalas como marketing.
- **Servicios gestionados** (Amazon Timestream y equivalentes): estado, límites y precios **no
  verificados** en esta revisión.
- **CVE recientes de TimescaleDB, InfluxDB, QuestDB, VictoriaMetrics y TDengine**: **no revisados
  uno a uno**. Solo se confirmó que ClickHouse mantiene changelog de seguridad propio y publica
  imágenes *distroless* desde abr-2026.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
