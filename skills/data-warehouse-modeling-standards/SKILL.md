---
name: data-warehouse-modeling-standards
description: Use when deciding the shape of an analytical schema — star schema versus 3NF versus Data Vault (hubs, links, satellites, PIT and bridge tables), bronze/silver/gold or staging/intermediate/marts layering, declaring the grain of a fact table, additive versus semi-additive versus non-additive measures, factless facts, periodic and accumulating snapshots, surrogate versus natural keys, slowly changing dimensions (SCD type 0-7), conformed dimensions across marts, degenerate and junk dimensions, a date/calendar dimension with fiscal periods and business timezone versus UTC, One Big Table denormalization for a serving layer, the single definition of a metric and the semantic layer (MetricFlow, Cube, Apache Ossie/OSI semantic models), proving uniqueness and referential integrity on a model, or migrating a schema whose grain must change.
---

# Estándares de modelado de almacén de datos

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **decidir la forma del destino analítico**: qué tablas existen, a qué grano, con qué
claves, cómo se guarda la historia, cómo se organizan en capas y dónde vive la definición de una
métrica.

Disparadores: `fct_`/`dim_`/`stg_`/`int_`, `schema.yml`/`semantic_models`/`metrics:`, `hub_`/
`lnk_`/`sat_`, `_sk`/`_key`/`surrogate`, `valid_from`/`valid_to`/`is_current`/`dbt_valid_to`,
`dim_date`/`dim_calendar`, `unique_key`, "star schema", "grano", "grain", "SCD2", "historizar",
"dimensión conformada", "OBT", "tabla ancha", "marts", "capa oro", "medallion", "métrica",
"capa semántica", y las preguntas que delatan un modelo mal declarado: **"¿por qué el ingreso no
cuadra entre estos dos informes?"**, "¿cuántas filas debería tener esta tabla?", "¿qué representa
una fila aquí?", "¿por qué al sumar sale el doble?", "queremos ver cómo estaba el cliente en
marzo".

**No aplica**: ver
- `data-engineering-standards` (**hermana; frontera declarada en ambos lados**): ella **mueve y
  transforma** —ingesta, ELT/ETL, orquestación, idempotencia, *backfill*, Parquet, coste de
  escaneo, frescura y observabilidad del dato—; esta **decide la forma del destino**. Regla de
  corte: si la pregunta es "¿cómo se recarga marzo sin duplicar?", es de ella; si es "¿qué
  representa una fila y qué pasa cuando el cliente cambia de segmento?", es de aquí. Un pipeline
  sin modelo produce un pantano; un modelo sin pipeline es un diagrama.
- `data-platform-standards` (**madre**): **PostgreSQL como motor operacional** es suyo, con su
  modelado normalizado, sus índices, sus migraciones y su particionado. Aquí se modela el **destino
  analítico**, que es otra cosa y obedece a otras reglas. Su principio rector —**un almacén por
  necesidad, no por moda**— se hereda: esta skill no autoriza un almacén analítico nuevo; asume que
  ya se justificó. **Un `dim_` no se crea dentro de la base de datos transaccional.**
- `lakehouse-standards`: el **formato de tabla** —Iceberg, Delta, Hudi—,
  evolución de esquema a nivel de fichero, particionado oculto, *time travel* y snapshots del
  motor. Frontera fina y deliberada: el *time travel* del formato de tabla te devuelve **la tabla
  como estaba**; una SCD tipo 2 te dice **cómo estaba la entidad del negocio**. No son sustitutos:
  el primero es una capacidad de infraestructura para recuperación y auditoría técnica, la segunda
  es una decisión de modelado que el negocio consulta. **Nunca sustituyas una SCD2 por *time
  travel*.**
- `analytics-bi-standards`: la herramienta de BI, los dashboards, la
  gobernanza del consumo y el rendimiento de la capa de presentación. **Decisión de frontera
  explícita: la definición canónica de una métrica es de aquí** (§3.7) —vive en el repositorio,
  versionada, junto al modelo—; la BI **la consume**, no la define. Una métrica definida dentro de
  un informe es un defecto de modelado, no una elección de herramienta.
- `data-governance-quality-standards`: catálogo, propiedad, glosario de
  negocio, contratos y calidad como programa. Aquí las **pruebas estructurales del modelo** (§4).
- `streaming-cdc-standards`: captura de cambios como mecanismo. Aquí solo
  el uso que se le da: alimentar la historización dimensional.
- `microservices-architecture-standards`: **eventos de dominio, outbox y propiedad del dato por
  servicio son suyos**. Un evento de dominio no es un hecho analítico: modelar el hecho es de aquí.
- `privacy-engineering-standards`: **retención, borrado, minimización, seudonimización y
  clasificación del dato personal son suyos**; aquí se **ejecutan en el modelo** —qué columnas no
  entran en una dimensión, cómo se borra a un sujeto de una SCD2 sin destruir los hechos, dónde
  vive la tabla de correspondencia—.
- `object-storage-standards` (S3 como sustrato), `observability-standards`, `mlops-standards`
  (**feature store y train/serve skew son suyos**; una tabla de *features* no es un mart),
  `rag-standards`, `ai-governance-standards`, `grc-compliance-standards`, `bcdr-standards`,
  `backup-recovery-standards`, `cicd-standards`, `iac-standards`,
  `identity-access-management-standards`, `secrets-management-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (**Redshift, BigQuery, Synapse/Fabric como
  servicios gestionados: coste, red, IAM y aprovisionamiento son suyos; el criterio de modelado
  encima es de aquí**), `api-design-standards`.
- Motores no analíticos: `nosql-standards`, `graph-db-standards`, `timeseries-db-standards`,
  `search-engines-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`,
  `mysql-mariadb-dba-standards`.
- `sql-standards` (**el lenguaje SQL**, incluido el que contiene un modelo dbt/SQLMesh).
  Frontera espejada desde su §1: *"¿qué representa una fila?"* —grano, hechos, dimensiones, SCD,
  capas, definición canónica de métrica— **es de aquí**; *"¿cómo expreso esa SCD2 en SQL sin una
  subconsulta correlacionada?"* es suya. **Que el SQL viva dentro de un modelo no lo exime del
  criterio de lenguaje.**

**Tesis del dominio — el modelado sigue importando**. El argumento de que el almacenamiento barato
y el cómputo elástico jubilaron el modelado confunde el coste que desapareció con los que quedaron.
El disco dejó de importar; **el cómputo, la comprensión y la confianza no**:

- **Cómputo**: en los motores modernos se paga por escaneo. Una tabla sin grano declarado se
  consulta mal y se paga cada vez.
- **Comprensión**: si nadie sabe qué representa una fila, cada analista inventa su interpretación y
  todas son plausibles.
- **Confianza**: es el recurso escaso. **Dos informes que discrepan destruyen la confianza en la
  plataforma más rápido que un error que se detecta y se corrige** — un error se arregla; la
  discrepancia enseña a la organización que los datos son opinables.

Lo que sí ha cambiado es la **implementación**: menos estrellas físicas construidas a mano, más
modelos gestionados por herramienta y capas semánticas encima. Las obligaciones que sobreviven son
las mismas: **declarar el grano, separar hecho de dimensión, conformar dimensiones e historizar lo
que cambia**.

## 2. Decisiones por defecto

> Verificar por web el estado de las referencias, especificaciones y herramientas antes de fijarlas
> en un proyecto real (§8).

### 2.1 Elección de paradigma

| Paradigma | Cuándo es la respuesta correcta | Coste real | Veredicto |
|---|---|---|---|
| **Kimball / dimensional (estrella)** | **Default.** El destino se consulta para responder preguntas de negocio | Requiere declarar grano y conformar dimensiones — trabajo intelectual, no técnico | **Adopta esto salvo motivo escrito** |
| **Inmon / 3FN corporativa** | Integración de muchos sistemas con reglas de negocio complejas y un equipo central que la sostiene, alimentando marts dimensionales aguas abajo | Lento de entregar; incomprensible para el consumidor final: **nunca es la capa de consumo** | Capa intermedia en organizaciones grandes |
| **Data Vault 2.0** (hubs, links, satélites) | Muchas fuentes cambiantes **y** requisito de auditabilidad total: quién dijo qué, cuándo y desde qué sistema (banca, seguros, sector regulado) | **Explosión de tablas** (del orden de 3× frente al modelo relacional equivalente) y *joins* inmanejables; obliga a tablas *PIT* y *bridge* solo para poder consultar; y a construir marts dimensionales encima **de todos modos** | **Resuelve un problema de auditoría e integración que la mayoría no tiene.** Los datos de adopción lo confirman: los propios adoptantes citan como principales inconvenientes las necesidades de formación (~48 %), la complejidad de implementación (~35 %) y el rendimiento de consulta (~32 %), y solo ~31 % dice que su implementación cumple del todo el estándar. Exige automatización y personal formado |
| **One Big Table (OBT)** | **Capa de servicio**, derivada de un modelo, para un dashboard o un caso concreto (§3.6) | Se reconstruye entera; se especializa y se multiplica | Correcto como destino, **nunca como origen de la verdad** |

Regla: **Data Vault sin requisito de auditoría explícito es sobre-ingeniería**, y en concreto la
peor clase de sobre-ingeniería: la que impone una tasa de explicación permanente a todo el que
entre al equipo.

### 2.2 Toolchain de modelado

| Ámbito | Default | Nota (ago 2026) |
|---|---|---|
| Referencia canónica dimensional | **Kimball & Ross, *The Data Warehouse Toolkit*, 3.ª ed. (2013)** | **No hay 4.ª edición**; el Kimball Group cesó su actividad de consultoría/formación en 2016. Sigue siendo la referencia, con la salvedad de que sus capítulos de ETL describen una era anterior al ELT |
| Definición de métricas | **En el repositorio, en YAML versionado, junto al modelo** | **MetricFlow** relicenciado a **Apache 2.0** (oct-2025). **Cube** como alternativa *headless* (define **y sirve**: no son intercambiables) |
| Especificación de intercambio semántico | **Apache Ossie (incubating)**, antes *Open Semantic Interchange* (OSI) | Apache-2.0, especificación JSON/YAML. Es una **especificación**, no un producto: no almacena ni sirve nada. Vigila la adopción real de importadores antes de apostar la portabilidad |
| Pruebas del modelo | Aserciones declarativas versionadas (unicidad, no nulos, relaciones, valores aceptados) | Gate de ejecución (§4) |
| Documentación del grano | En el propio modelo, no en un wiki | Un grano documentado fuera del código deja de ser cierto en un trimestre |

## 3. Estructura y convenciones

### 3.1 Capas

Tres, con responsabilidades separadas. Los nombres varían (bronce/plata/oro,
*staging*/intermedio/marts); las reglas no:

| Capa | Contenido | Regla dura |
|---|---|---|
| **Cruda / bronce** | Copia fiel de la fuente, inmutable | No se modela. Es de `data-engineering-standards` |
| **Intermedia / plata** | Tipado, deduplicación, conformación de entidades, reglas de negocio | Aquí vive la lógica fea, y **solo aquí** |
| **Consumo / oro / marts** | Hechos y dimensiones, o el OBT derivado de ellos | **Debe ser aburrida**: nombres estables, tipos estables, cero sorpresas |

Que la capa de consumo sea aburrida es un requisito, no un estilo. Es la capa que la gente lee sin
preguntarte, la que rompe informes cuando cambia y la que fija el contrato con el negocio. Toda
sorpresa (una columna que a veces es nula, un `status` con valores nuevos sin avisar, una métrica
que cambió de definición en silencio) se paga en confianza, y la confianza no se recupera con un
*hotfix*.

**Prohibido saltarse la capa intermedia** poniendo lógica de negocio en la capa de consumo: el
resultado son marts que se contradicen porque cada uno reimplementó la misma regla ligeramente
distinta.

### 3.2 Hechos: el grano es la decisión

**El grano es la decisión más importante y la más equivocada.** Se declara **primero**, en una
frase en lenguaje natural, antes de escribir una columna:

> "Una fila = **una línea de un pedido** en el momento en que se confirmó."

Reglas:
- **El grano se escribe en el modelo** (descripción de la tabla), no en la cabeza de nadie.
- **Grano atómico por defecto**: el más fino que la fuente permita. Agregar después es trivial;
  desagregar es imposible. Los pre-agregados son optimizaciones derivadas, no el hecho.
- **Un grano por tabla.** Mezclar líneas de pedido y cabeceras de pedido en la misma tabla es la
  causa raíz de la mitad de las cifras infladas de la industria: cualquier suma multiplica por el
  número de líneas.
- **El grano se prueba, no se cree** (§4): si la clave declarada no es única, tu grano no es el que
  crees, y todo lo construido encima está mal.

**Tipos de medida** — la clasificación decide qué agregaciones son legales, y hay que declararla:

| Tipo | Suma sobre cualquier dimensión | Ejemplo | Trampa |
|---|---|---|---|
| **Aditiva** | Sí | Importe de venta | — |
| **Semiaditiva** | Sí, salvo sobre el tiempo | Saldo de cuenta, nivel de inventario | Sumar saldos de 12 meses da una cifra sin significado. Sobre el tiempo: último valor o media |
| **No aditiva** | No | Ratios, porcentajes, márgenes unitarios | **Nunca almacenes el ratio**: almacena numerador y denominador y divide al agregar. Sumar ratios es siempre incorrecto |

**Tipos de tabla de hechos**:
- **Transaccional**: una fila por evento, grano atómico. El default.
- **Snapshot periódico**: una fila por entidad y periodo (saldo diario, inventario semanal). Para
  medidas semiaditivas y para preguntas de "cuánto había". Crece de forma predecible.
- **Snapshot acumulativo**: una fila por proceso con múltiples hitos, **que se actualiza** conforme
  avanza (pedido → pagado → enviado → entregado). Para medir latencias entre fases. Es la única
  tabla de hechos que se actualiza, y hay que decirlo explícitamente porque rompe la expectativa
  de inmutabilidad.
- **Sin hechos (*factless*)**: registra que algo ocurrió o que una relación existe, sin medida.
  Asistencias, coberturas, elegibilidad. Legítima y muy infrautilizada: la alternativa habitual es
  inventarse una columna `count = 1`, que es lo mismo con peor nombre.

Además: **dimensiones degeneradas** (número de pedido/ticket) viven en el hecho, sin tabla propia;
**dimensiones basura** (*junk*) agrupan banderas de baja cardinalidad que no merecen una dimensión
cada una.

### 3.3 Dimensiones

- **Claves subrogadas** en las dimensiones historizadas (SCD2) — son **obligatorias** ahí, porque
  la clave natural deja de ser única al haber varias versiones. En dimensiones no historizadas, la
  clave natural es aceptable y más simple; decisión consciente, no automatismo.
- **La clave natural nunca desaparece del modelo**: se conserva como columna, porque es lo único
  que permite reconciliar con el sistema origen cuando alguien pregunte.
- **Nunca uses la clave subrogada como clave de integración entre sistemas** ni la expongas al
  exterior: es un detalle interno del almacén.
- **Toda dimensión tiene una fila "desconocido"/"no aplica"** con clave fija (típicamente `-1`).
  Sin ella, los hechos con dimensión ausente se pierden en el `INNER JOIN` y las cifras bajan sin
  que nadie sepa por qué. Esto es un `LEFT JOIN` que silenciosamente descuadra el total.
- **Jerarquías**: dentro de la propia dimensión (país → región → ciudad) mientras sean fijas.
  Jerarquías irregulares o de profundidad variable exigen tabla puente (*bridge*) — y son la
  excusa más frecuente para complicar un modelo que no lo necesitaba.

**Dimensiones que cambian lentamente (SCD)** — Kimball define los tipos 0 a 7; en la práctica
solo se usan tres, y hay que elegir por pregunta de negocio, no por costumbre:

| Tipo | Comportamiento | Cuándo |
|---|---|---|
| **0** | El atributo no cambia nunca | Fecha de alta original, país de nacimiento |
| **1** | Sobrescribe | **El default.** El negocio no necesita el valor anterior (corrección de una errata, teléfono actual) |
| **2** | Fila nueva con `valid_from`/`valid_to`/`is_current` | **Cuando el negocio necesita analizar el pasado con los valores de entonces**: cambio de segmento de cliente, de territorio de venta, de tarifa |
| **3** | Columna "valor anterior" | Nicho real: una reorganización puntual en la que hay que informar por la estructura vieja **y** la nueva a la vez. No es una alternativa general a la 2 |

Criterio de decisión, en una pregunta: **"cuando este atributo cambie, ¿los informes históricos
deben reflejar el valor de entonces o el de ahora?"** Si es "de entonces", tipo 2. Si es "de
ahora", tipo 1. Si nadie sabe contestar, es tipo 1 — y se documenta que se preguntó.

**La SCD tipo 2 no es gratis** y por eso está en las prohibiciones sin necesidad: multiplica filas,
obliga a que **todo** *join* desde el hecho use la clave subrogada vigente en la fecha del evento
(no la actual), rompe los conteos ingenuos de la dimensión (`COUNT(*)` deja de ser "número de
clientes") y complica el borrado por derecho al olvido. Aplícala a los atributos que lo requieren,
**no a la dimensión entera**.

**Dimensiones conformadas** — el mecanismo que hace que dos marts sean comparables. Una dimensión
conformada es la misma dimensión (mismas claves, mismos atributos, mismo significado) usada por
varios hechos. Sin ellas, "ventas por región" y "devoluciones por región" no se pueden cruzar
porque "región" no significa lo mismo, y nadie lo descubre hasta que las cifras no cuadran en una
reunión. Regla: **una entidad de negocio = una dimensión = un propietario.** Si un mart necesita
una variante, se justifica por escrito o se conforma la dimensión.

### 3.4 La dimensión de fecha

Tabla física, poblada por adelantado, con una fila por día (y otra por hora/minuto si hace falta,
**separada**). No es opcional y no se sustituye por funciones de fecha del motor: existe para
alojar lo que el motor no sabe —festivos, calendario fiscal, semanas laborables, temporadas— y para
que las consultas filtren por atributo en vez de por expresión.

- Clave en formato `YYYYMMDD` (entero) o fecha: legible en el hecho, ordenable, sin *join* para
  depurar.
- **Calendario fiscal** como columnas propias (`fiscal_year`, `fiscal_quarter`, `fiscal_period`):
  el año fiscal casi nunca coincide con el natural, y reimplementarlo en cada consulta garantiza
  que unas cuadren y otras no.

### 3.5 El problema de la fecha — hora local frente a UTC

Origen recurrente de discrepancias entre informes que nadie sabe explicar. Regla en tres partes,
todas obligatorias:

1. **Almacena siempre el instante en UTC** con tipo con zona (`timestamptz`/`TIMESTAMP` con zona).
   Nunca un tipo sin zona: "las 14:00" sin zona es un dato incompleto disfrazado de dato completo.
2. **Almacena además la clave de fecha del negocio** (`date_key`) ya resuelta en la **zona horaria
   del negocio**, decidida y documentada. Es la columna por la que se filtra y se agrupa. Sin ella,
   cada consulta convierte a su manera y "ventas de ayer" da tres cifras distintas según quién
   pregunte.
3. **Documenta cuál es la zona del negocio y qué pasa con las operaciones multi-país**: o una zona
   canónica única, o una `date_key` local **por país** además de la canónica — elegido
   explícitamente y escrito en el modelo.

Añadidos: guarda el desplazamiento (*offset*) si el cambio de horario importa (los días de 23 y 25
horas existen y rompen los cuadres anuales); y decide qué fecha manda —fecha de evento, de
contabilización, de ingesta— por hecho. **Las tres son diferentes y las tres son necesarias**; la
que se usa para particionar no es necesariamente la que se usa para informar.

### 3.6 Desnormalización deliberada: OBT

Aplanar todo en una tabla ancha es **correcto** cuando: (a) sirve un caso de consumo concreto,
(b) **se deriva** de un modelo dimensional que sigue existiendo, (c) su reconstrucción es
automática, y (d) está documentado que es una vista de servicio.

La ganancia es real y medible —los motores columnares MPP favorecen la tabla ancha frente al *join*
en tiempo de consulta—, pero es una ganancia **de la última milla**.

Es **pereza** cuando: sustituye al modelo en vez de derivarse de él, cada equipo tiene el suyo con
reglas distintas, nadie sabe a qué grano está, o la métrica se define dentro de la propia tabla y
se duplica en la siguiente. Síntoma inequívoco: **existen tres tablas anchas de "ventas" y ninguna
cuadra con las otras**.

### 3.7 Métricas y capa semántica

**La definición de "ingreso" o de "cliente activo" es un artefacto del repositorio, versionado,
revisado por *pull request* y con propietario.** No vive en un informe, ni en una hoja de cálculo,
ni en la cabeza de la persona que lleva más tiempo.

- **Una definición, un nombre.** Si el negocio tiene dos nociones de ingreso (bruto y neto de
  devoluciones), son **dos métricas con dos nombres**, no una métrica ambigua.
- **La métrica se define sobre el modelo dimensional**, declarando la medida, la agregación y las
  dimensiones por las que es legal desglosarla. Una métrica sin dimensiones declaradas se
  desglosará por algo que no tiene sentido.
- **La capa semántica no arregla un modelo malo**: si el grano está mal, la métrica calculada
  encima está mal con más pasos y mejor presentación.
- **Portabilidad, con escepticismo medido**: Apache Ossie (incubating) es la especificación de
  intercambio, y MetricFlow (Apache 2.0) su formato declarativo de referencia. La especificación
  no transporta la arquitectura de servicio —caché, pre-agregados, multi-tenancy, APIs—: eso no es
  portable aunque la definición sí lo sea. Adopta la especificación por higiene; no la asumas como
  garantía de salida.
- **Métrica sin propietario = métrica muerta.** Cuando dos informes discrepen, tiene que haber
  alguien que decida cuál es correcto y en cuánto tiempo.

## 4. Calidad y testing — gates

Las pruebas de un modelo no son opinables: son las que demuestran que el modelo es lo que dices
que es. En orden de coste creciente; **todas son gate de la publicación de la capa de consumo**
salvo indicación contraria.

1. **Unicidad de la clave del grano.** La prueba que demuestra que el grano declarado es real. Si
   la clave es compuesta, se prueba la combinación. **Sin este test no hay modelo, hay una tabla.**
2. **No nulos** en las claves, las claves foráneas de dimensión y las columnas de las que depende
   una métrica.
3. **Integridad referencial**: toda clave de dimensión del hecho existe en la dimensión. Los
   almacenes analíticos no imponen FK; por tanto se prueba, o no existe.
4. **Valores aceptados** en columnas de catálogo (`status`, `type`, `channel`): detecta el valor
   nuevo que la fuente introdujo sin avisar **antes** de que aparezca como "otros" en un informe.
5. **Rangos y signos**: importes que no pueden ser negativos, fechas que no pueden estar en el
   futuro, cantidades acotadas.
6. **Integridad de la SCD2** — se olvida sistemáticamente y es donde más silenciosamente se rompe:
   - Exactamente **una** fila vigente (`is_current`) por clave natural.
   - Los intervalos `[valid_from, valid_to)` de una misma clave natural **no se solapan y no dejan
     huecos**.
   - La primera versión empieza en el origen del tiempo y la vigente no tiene fin (o tiene una
     fecha centinela documentada, siempre la misma).
7. **Reconciliación con el origen**: recuento y suma de una medida clave frente al sistema fuente,
   con tolerancia declarada. Es la única prueba que detecta la pérdida de filas aguas arriba.
8. **Cuadre entre capas y entre marts**: la métrica canónica calculada desde el hecho atómico y
   desde el agregado/OBT deben coincidir. **Si dos marts publican la misma métrica, un test compara
   sus resultados** — este es el test que evita el fallo más caro del dominio.
9. **Prueba de no-multiplicación (*fan-out*)**: tras los *joins* del modelo, el recuento de filas
   del hecho no cambia. Detecta el *join* con una dimensión que no era única, que es la causa
   mecánica de las cifras infladas.
10. **Tests unitarios de la lógica de negocio** con filas de entrada fijas y salida esperada,
    cubriendo bordes: nulos, cambio de versión SCD2 justo en el instante del evento, fila que llega
    fuera de orden, entidad sin dimensión, importe cero, devolución total.
11. **Contrato de la capa de consumo**: eliminar o renombrar una columna publicada, o cambiar el
    tipo, **rompe el build** salvo aprobación explícita registrada. La capa de consumo es una API.
12. **Documentación como gate**: modelo sin descripción de grano y sin columnas documentadas no
    mergea.

## 5. Seguridad y dato personal en el modelo

- **Clasifica al modelar, no después.** Cada columna de una dimensión sabe si es pública, interna,
  confidencial o personal. La clasificación decide quién la ve y cuánto vive
  (ver `privacy-engineering-standards`).
- **Minimización en el modelo**: una dimensión no es un vertedero de todos los campos de la fuente.
  Cada atributo copiado es un atributo que hay que retener, borrar y explicar en una brecha. Copiar
  la tabla `customer` entera "por si acaso" es una decisión de privacidad tomada por omisión.
- **El derecho al olvido y la SCD2 chocan de frente**: borrar a un sujeto de una dimensión
  historizada destruye la trazabilidad de los hechos si se hace ingenuamente. Diseña desde el
  principio: **atributos identificativos separados** de los analíticos (segmento, región, cohorte),
  de forma que se pueda anonimizar la parte identificativa conservando la estructura del hecho.
  Alternativa: seudonimización con tabla de correspondencia bajo control estricto, o
  *crypto-shredding*. Decisión de `privacy-engineering-standards`; **la estructura que la hace
  posible se decide aquí, y si no se decide aquí, después es una migración**.
- **Los hechos no llevan PII.** Llevan claves. Si un hecho necesita el nombre o el correo, el
  modelo está mal.
- **Granularidad como control**: publicar el mart agregado en vez del hecho atómico es a menudo la
  mitigación más simple y más efectiva. Un mart al que no se puede llegar a la persona no necesita
  la mitad de los controles del que sí.
- **Seguridad a nivel de fila/columna** aplicada en la capa de consumo y **modelada**: la dimensión
  que determina la visibilidad (organización, territorio) tiene que existir en el hecho para poder
  filtrar. Si se añade después, es una migración de todo el histórico.
- Sin PII real en entornos de desarrollo del modelo (ver `data-engineering-standards` §4).

## 6. Rendimiento y operabilidad del modelo

- **Materializa por consumo, no por costumbre**: hecho atómico materializado; capas intermedias
  como vista si se consultan poco; agregados y OBT materializados solo con demanda medida. Cada
  tabla materializada que nadie consulta se paga en cada ejecución.
- **Los agregados son derivados y deben poder reconstruirse** desde el hecho atómico. Un agregado
  que no se puede recalcular es una fuente de verdad accidental.
- **Ordenación/clustering por la columna de filtro habitual** (fecha del evento, y a veces la
  dimensión de mayor cardinalidad de filtrado). El particionado físico y su coste son de
  `data-engineering-standards`; **qué columna merece ser la de filtro lo dice el modelo**.
- **Dimensiones pequeñas y anchas, hechos altos y estrechos**: es el reparto que los motores
  columnares premian. Una dimensión con 40 atributos y 50.000 filas es sana; un hecho con 40
  columnas descriptivas es un error de modelado.
- **Vigila el crecimiento de las SCD2**: una dimensión historizada sobre un atributo volátil crece
  sin límite y degrada todos los *joins*. Si crece más rápido que el hecho, el atributo no era
  dimensional: era una medida.
- **Métricas de salud del modelo**, revisadas con cadencia: número de marts que publican la misma
  métrica (objetivo: uno), modelos sin grano documentado (objetivo: cero), tests por modelo,
  modelos sin consumo en el último trimestre.
- **Propietario por dimensión conformada y por métrica**, publicado. Sin propietario, la
  discrepancia entre informes no la resuelve nadie y se convierte en folclore.

## 7. Sostenibilidad y prohibiciones

- **Evolución del esquema**: **añadir es fácil, cambiar el grano es una migración.** Añadir una
  columna o una dimensión es aditivo y compatible. Cambiar el grano de un hecho, cambiar una
  dimensión de tipo 1 a tipo 2, o redefinir una métrica **no lo son**: exigen reconstrucción del
  histórico, comunicación a los consumidores y un periodo de convivencia de la versión vieja y la
  nueva. Trátalos como una migración con expand/contract, no como un cambio de código.
- **Redefinir una métrica es un evento de comunicación, no un commit.** Las cifras publicadas
  cambiarán retroactivamente; si nadie lo anuncia, el negocio concluye que los datos son
  poco fiables. Versiona la métrica y mantén ambas mientras dure la transición.
- **Retirada activa**: mart, dimensión o métrica sin consumo medido durante un trimestre se marca y
  se retira. El almacén crece por acumulación por defecto.
- **ADR obligatorio** para: paradigma de modelado, grano de cada hecho central, política de
  historización por dimensión, zona horaria canónica y calendario fiscal, y la decisión de publicar
  un OBT.
- **Cadencia de revisión**: semestral para el estado de las especificaciones de capa semántica
  (Apache Ossie, MetricFlow, Cube), que están en movimiento activo.

**PROHIBIDO**
- ❌ **Modelar sin declarar el grano** por escrito y en el propio modelo. Es el defecto raíz del
  dominio.
- ❌ Más de un grano en la misma tabla de hechos.
- ❌ Publicar una tabla sin test de unicidad de su clave: el grano no está probado.
- ❌ **SCD tipo 2 sin necesidad demostrada**, o aplicada a la dimensión entera en lugar de a los
  atributos que la requieren.
- ❌ Sustituir una SCD tipo 2 por el *time travel* del formato de tabla.
- ❌ **Marts que redefinen métricas** ya definidas en otro sitio; o la misma métrica con el mismo
  nombre y dos definiciones.
- ❌ Definir una métrica dentro de un informe o de una herramienta de BI.
- ❌ Almacenar ratios, porcentajes o medias como medida agregable.
- ❌ Sumar una medida semiaditiva sobre el tiempo.
- ❌ Dimensión sin fila "desconocido", o `INNER JOIN` a dimensión que descarta hechos en silencio.
- ❌ Clave subrogada expuesta fuera del almacén o usada como clave de integración.
- ❌ Perder la clave natural del origen al modelar.
- ❌ Guardar instantes sin zona horaria, o carecer de una `date_key` de negocio explícita.
- ❌ Reimplementar el calendario fiscal en cada consulta en vez de tenerlo en la dimensión de fecha.
- ❌ OBT como origen de la verdad, o varios OBT del mismo dominio con reglas distintas.
- ❌ Lógica de negocio en la capa de consumo, o capa de consumo que salta la intermedia.
- ❌ Data Vault sin requisito de auditoría escrito.
- ❌ Normalización 3FN como capa de consumo para usuarios de negocio.
- ❌ PII en tablas de hechos; dimensiones que copian la fuente entera "por si acaso".
- ❌ Cambiar el grano, el tipo o el nombre de una columna publicada sin migración y sin avisar.
- ❌ Confiar en la integridad referencial "porque los datos vienen bien": en un almacén analítico
  no hay FK, hay tests.
- ❌ Documentar el grano en un wiki en vez de en el modelo.
- ❌ Fijar versiones, licencias o estado de especificaciones de memoria (§8).

## 8. Verificación web obligatoria

Los datos de §2 son de **agosto de 2026**. Antes de fijar nada en un entregable, verifica:

1. **Referencia de Kimball**: si ha aparecido una 4.ª edición de *The Data Warehouse Toolkit*
   (a ago-2026 la vigente es la **3.ª, de 2013**, sin sucesora anunciada).
2. **Data Vault 2.0**: estado del estándar y de su ecosistema de automatización; datos de adopción
   actualizados antes de citar porcentajes (los de §2.1 proceden de un estudio de BARC de
   patrocinio comercial: **trátalos como orden de magnitud, no como cifra exacta**).
3. **Capa semántica**: estado de **Apache Ossie** (incubadora de la ASF, antes OSI; especificación
   v1.0 publicada a principios de 2026) y **adopción real de importadores/exportadores por parte de
   los proveedores** — es lo único que convierte la especificación en portabilidad. Licencia y
   actividad de **MetricFlow** (Apache 2.0 desde oct-2025) y de **Cube**.
4. **dbt tras la fusión con Fivetran** (completada 1-jun-2026): qué parte de la capa semántica es
   OSS y qué parte exige plataforma de pago; la API de servicio de métricas ha estado ligada al
   producto comercial (ver `data-engineering-standards` §2 y §8).
5. **Formato de tabla**: capacidades de evolución de esquema y de *time travel* de Iceberg/Delta,
   por si desplazan la frontera con `lakehouse-standards` (Iceberg 1.11.0 en may-2026).
6. Funciones y límites del motor concreto (BigQuery, Snowflake, Redshift, Databricks, Fabric) en lo
   que el modelo dé por hecho: *clustering*, vistas materializadas, seguridad a nivel de fila.

**Huecos declarados de esta revisión** (no rellenar de memoria):
- **Apache Ossie**: no verificado el número de proveedores con importador/exportador **realmente
  publicado**; las fuentes secundarias sugieren que la adopción va muy por detrás del anuncio.
  No prometas portabilidad de métricas sin comprobarlo producto a producto.
- **Data Vault 2.0**: no verificada la posición actual de Dan Linstedt ni ninguna revisión del
  estándar posterior a 2025.
- **Cube**: no verificados versión, licencia vigente ni modelo de negocio actual en esta revisión.
- **Cifras de rendimiento OBT frente a estrella**: los porcentajes que circulan proceden de un
  *benchmark* de proveedor. Mide en tu motor y con tus datos antes de usarlos para decidir.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
