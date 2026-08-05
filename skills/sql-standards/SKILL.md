---
name: sql-standards
description: Use when writing or reviewing the SQL language itself — .sql files, SELECT/JOIN/CTE/window function queries, GROUP BY and aggregation, NULL and three-valued logic, MERGE and UPSERT, DDL and CREATE TABLE, ALTER TABLE migrations and expand/contract, transactions, BEGIN/COMMIT, isolation levels, SELECT FOR UPDATE and deadlocks, parameterized queries and SQL injection in query construction, dynamic identifier quoting, SARGable predicates, EXPLAIN and query plans, ANSI SQL versus PostgreSQL/MySQL/MariaDB/SQL Server T-SQL/Oracle PL-SQL/SQLite dialect differences, .sqlfluff and sqlfluff, shandy-sqlfmt, or hand-written SQL versus ORM- and dbt-generated SQL.
---

# Estándares del lenguaje SQL

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **lenguaje SQL escrito**: consultas, DDL, migraciones, transacciones, estilo, linting y test
del SQL, y a la lectura de planes **para decidir cómo se escribe la consulta**.
Triggers: ficheros `.sql`, `.sqlfluff`, `SELECT`/`JOIN`/`WITH`/`OVER()`, `GROUP BY`, `MERGE`,
`CREATE TABLE`, `ALTER TABLE`, `BEGIN`/`COMMIT`, `SET TRANSACTION ISOLATION LEVEL`, `FOR UPDATE`,
`EXPLAIN`/`EXPLAIN ANALYZE`/`SHOW PLAN`, `sqlfluff`, `sqlfmt`.
Fija **criterio**, no tutoriales.

**Regla de arbitraje** (la línea de esta skill, y se escribe aquí sin ambigüedad):
> **Si la pregunta cambia cómo se escribe la consulta o el DDL, es de `sql-standards`.
> Si cambia qué motor se elige, cómo se dimensiona, respalda, replica o restaura, es de la skill del motor.
> Si cambia la forma del modelo de datos, es de la skill de modelado.**

Corolario práctico: *"¿por qué esta consulta no usa el índice?"* es de aquí (se reescribe el predicado);
*"¿qué índice creo y cuánto cuesta mantenerlo?"* y *"¿por qué el motor eligió ese plan con estas
estadísticas?"* son de la skill del motor. **Esta skill cede modelado, operación y tuning de motor; se
queda el lenguaje.**

**No aplica**: ver
- `data-platform-standards` (**skill madre**: PostgreSQL como default relacional, modelado, **índices
  como objeto** —cuáles crear, coste de escritura, particionado—, réplicas, PITR, cifrado en reposo,
  retención y clasificación del dato. Aquí sólo **cómo se escribe la consulta para que un índice
  existente sea usable**).
- `mysql-mariadb-dba-standards`, `oracle-dba-standards`, `sqlserver-dba-standards` (**operación de cada
  motor**: parámetros, licenciamiento, HA/réplicas, RMAN/Data Guard, DBCC/Always On/Query Store,
  binlog, AWR/ASH, *tuning* de instancia). Aquí **las diferencias de dialecto que cambian el código**
  que escribes contra ellos, y nada más. **Prohibido duplicar aquí criterio de operación.**
- `data-warehouse-modeling-standards` (**la forma del modelo analítico es suya**: grano, hechos,
  dimensiones, SCD, capas, definición canónica de métrica). Si la pregunta es *"¿qué representa una
  fila?"*, es suya; si es *"¿cómo expreso esa SCD2 en SQL sin subconsulta correlacionada?"*, es de aquí.
- `data-engineering-standards` (ingesta, orquestación, idempotencia del job, *backfill*, Parquet,
  frescura; **dbt como herramienta de transformación y su proyecto son suyos** — aquí sólo el criterio
  sobre el **SQL** que ese modelo contiene, ver §7),
  `lakehouse-standards` (formato de tabla Iceberg/Delta/Hudi, catálogo, snapshots, compactación,
  `MERGE` como operación de la tabla y su coste copy-on-write / merge-on-read),
  `analytics-bi-standards` (el cuadro de mando y quién decide con él),
  `data-governance-quality-standards` (propiedad del dato, contratos, aserciones de calidad).
- `nosql-standards`, `graph-db-standards` (**incluido SQL/PGQ y `GRAPH_TABLE`: el recorrido de
  profundidad variable es suyo**), `timeseries-db-standards`, `vector-db-standards`,
  `search-engines-standards` (otros modelos de dato y sus lenguajes; aquí sólo SQL relacional),
  `streaming-cdc-standards` (SQL de streaming —Flink SQL, ksqlDB— y semántica de eventos).
- `appsec-standards` (**el proceso AppSec es suyo**: modelado de amenazas, triaje del hallazgo de SQLi,
  elección de SAST/DAST, ASVS. **Aquí sólo el criterio de código**: cómo se construye una consulta para
  que la inyección sea imposible — §5).
- `api-design-standards` (el contrato hacia el exterior: **una tabla no es una API**), las skills de
  lenguaje —`python-standards`, `typescript-standards`, `go-standards`, `jvm-spring-standards`,
  `dotnet-standards`, `php-standards`, `ruby-standards` (Active Record y `strong_migrations`),
  `elixir-erlang-standards` (Ecto, `changesets` y `Ecto.Multi`), `scala-standards` (Doobie, Slick,
  Quill), `clojure-standards` (`next.jdbc`, HoneySQL), `r-standards` (`dbplyr`), `julia-standards` (`DBInterface`, `LibPQ`)— (el driver, el
  ORM/generador y la herramienta de migración concreta; **aquí el SQL que producen o que escribes a
  mano**. Que el SQL lo genere una librería **no lo exime** de este criterio: si el generador emite
  una subconsulta correlacionada donde tocaba una función de ventana, el problema es de SQL).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable / nota |
|---|---|---|
| Base de referencia | **SQL estándar (ISO/IEC 9075)** como línea de partida; el dialecto se usa **conscientemente** | El estándar vigente es **SQL:2023**, adoptado en **junio de 2023** (novena edición). Ningún motor lo implementa entero: escribir "SQL estándar" y creer que es portable es un error |
| Portabilidad | **No la persigas por defecto**: elige un motor y usa su dialecto bien | La portabilidad se paga en cada consulta y casi nunca se cobra. Se justifica sólo si el producto se vende sobre varios motores, y entonces se declara y se prueba en CI contra todos |
| Linter | **SQLFluff 4.2.x** (MIT, mantenimiento activo: cadencia ~2-3 semanas en 2026) con `.sqlfluff` versionado y `dialect` explícito | Único linter serio multi-dialecto y consciente de plantillas Jinja/dbt (`sqlfluff-templater-dbt`, versionado en paralelo). 4.0 introdujo parser/lexer en Rust **opt-in** (`sqlfluff[rs]`); los mantenedores prevén hacerlo default en 5.0 |
| Formatter | **sqlfmt** — paquete PyPI **`shandy-sqlfmt`** (Apache-2.0), estilo único no configurable | `sqlfmt` a secas en PyPI es **otro paquete, ajeno al autor**: instalar el nombre equivocado es un error de suministro. sqlfmt **no es un linter** (no construye AST); coexiste con SQLFluff, que además formatea (`sqlfluff fix`). Elegir **uno** de los dos como autoridad de formato y desactivar las reglas de layout del otro |
| Sabor de `MERGE` | Sólo donde existe (ver §3) | `MERGE` está en el estándar desde SQL:2003 y **no existe en MySQL, MariaDB ni SQLite** a 2026-08 |
| Migraciones | Herramienta con **versionado y migraciones inmutables** (Flyway, Liquibase, Alembic, EF Core, golang-migrate) | La elección concreta es de la skill del lenguaje; **el criterio expand/contract de §6 es de aquí y no es negociable** |
| Generación | **ORM para CRUD, SQL a mano para lo analítico y lo caliente** | Ver §7 |

**Diferencias de dialecto que sí cambian el código** (verificar por versión antes de usar, §8):

| Punto | PostgreSQL | MySQL / MariaDB | SQL Server | Oracle | SQLite |
|---|---|---|---|---|---|
| `MERGE` | Desde **15**; `RETURNING` desde **17** | **No existe** → `INSERT ... ON DUPLICATE KEY UPDATE` / `REPLACE` | Sí (larga data) | Sí (con restricciones propias: no actualizar columnas del `ON`, sintaxis `then update … delete` no estándar) | **No existe** → `INSERT ... ON CONFLICT` (UPSERT, desde 3.24, sintaxis tomada de PostgreSQL) |
| `JSON_TABLE` / SQL/JSON | Constructores y `JSON_TABLE` desde **17** | Sí en MySQL 8.0+ | Tipo `JSON` nativo, índices JSON y `JSON_CONTAINS` en **SQL Server 2025** (`JSON_TABLE`: **no verificado**, §8) | Sí | No (`json_each`/`json_tree`) |
| `GROUP BY ALL` | **No en 18**; *committed* para **19** | No | No | No | No |
| Comillas de identificador | `"x"` (plegado a minúsculas si no se citan) | `` `x` `` (o `"x"` con `ANSI_QUOTES`) | `[x]` o `"x"` | `"x"` (plegado a **mayúsculas**) | `"x"`, `` `x` ``, `[x]` |
| Cadenas y concatenación | `\|\|` | `\|\|` es **OR lógico** salvo `PIPES_AS_CONCAT`; usa `CONCAT()` | `+` | `\|\|` | `\|\|` |
| `''` vs `NULL` | Distintos | Distintos | Distintos | **Oracle trata `''` como `NULL`** — trampa clásica al portar | Distintos |
| Límite de filas | `LIMIT`/`OFFSET` y `FETCH FIRST` | `LIMIT` | `OFFSET … FETCH` / `TOP` | `FETCH FIRST` (12c+) | `LIMIT` |
| Aislamiento por defecto | Read Committed | **Repeatable Read** (InnoDB) | Read Committed con **bloqueos** (o RCSI si está activado) | Read Committed sobre *snapshot* | Serializable de facto |
| Sensibilidad de mayúsculas en datos | Sensible (usa `citext`/`ILIKE`/collation) | Depende de la **collation** (`_ci` por defecto históricamente) | Depende de la collation | Sensible | `NOCASE` por columna |
| Tipos booleanos | `boolean` nativo | `TINYINT(1)` disfrazado | `BIT` | Hasta 23c no había `BOOLEAN` en tabla | Enteros 0/1 |

Nada de esto es exhaustivo: **antes de usar una cláusula reciente, comprobar la versión mínima del motor
del proyecto**, no la última del producto (§8).

## 3. Estilo y convenciones

- **Palabras clave en MAYÚSCULAS**, identificadores en `snake_case` minúsculas. Es la única convención que
  sobrevive al plegado de mayúsculas de Postgres y Oracle sin obligar a citar identificadores.
- **Nunca cites identificadores** salvo obligación: un `"MiTabla"` obliga a citarla para siempre y en todas
  partes. Nombres sin espacios, sin acentos y sin palabras reservadas.
- **Nombres**: tablas en **plural o singular — elige uno y fíjalo en `.sqlfluff`**, nunca ambos; columnas
  sin prefijo redundante (`users.id`, no `users.user_id` salvo en FK: `orders.user_id` sí); claves
  primarias `id`, foráneas `<tabla_singular>_id`; booleanos `is_`/`has_`; marcas de tiempo en `_at`
  (`created_at`) y **siempre con zona horaria** (`timestamptz`), en UTC. Sin abreviaturas crípticas.
- **Formato**: una cláusula por línea (`SELECT`, `FROM`, `JOIN`, `WHERE`, `GROUP BY`, `ORDER BY`);
  una columna por línea en listas largas; coma **al principio** o al final, elegida y fijada por el
  formatter, no por persona. La decisión de estilo la toma la herramienta (§2), no la revisión.
- **`SELECT *` PROHIBIDO** fuera de exploración interactiva: rompe al añadir columnas, transfiere datos que
  nadie usa, impide *index-only scans* y hace ilegible el diff. En vistas y en `CREATE TABLE AS`, es un bug
  latente.
- **Alias**: alias de tabla cortos pero significativos (`orders o`, no `a`, `b`, `c`); `AS` explícito en
  alias de columna. Toda columna de una consulta con más de una tabla va **cualificada** (`o.id`).
- **`JOIN` explícito y obligatorio**. **PROHIBIDO el join implícito por coma** (`FROM a, b WHERE a.id = b.a_id`):
  mezcla condición de unión con filtro, y un `WHERE` olvidado produce un producto cartesiano silencioso.
  `CROSS JOIN` se escribe explícito cuando de verdad se quiere. `NATURAL JOIN` y `USING` con muchas
  columnas: vetados por frágiles ante cambios de esquema (`NATURAL JOIN` se rompe solo al añadir una
  columna con nombre coincidente).
- **CTEs (`WITH`) para dar nombre a los pasos**, en lugar de subconsultas anidadas ilegibles. Cuidado:
  en versiones antiguas de PostgreSQL el CTE era **barrera de optimización** (materializado siempre);
  desde PG12 se puede *inlinear* y existen `MATERIALIZED`/`NOT MATERIALIZED` — **verificar el
  comportamiento en el motor y versión concretos antes de asumirlo**. Un CTE no es gratis por definición.
- **Comentarios que explican el porqué**, no el qué: un `-- se excluye el tenant 0 porque es la plantilla
  interna` vale por diez líneas de descripción de sintaxis.
- **DDL declarativo y explícito**: `NOT NULL` por defecto (la nulabilidad se justifica, no al revés),
  `DEFAULT` explícito, **restricciones con nombre** (`CONSTRAINT ck_orders_total_positive CHECK (...)`) —
  un nombre autogenerado hace imposible escribir la migración inversa. Claves foráneas **declaradas** con
  su `ON DELETE` pensado; la integridad referencial vive en la base de datos, no "en la aplicación".
- Tipos: el **más restrictivo que sirva**. `text`/`varchar` con límite pensado, `numeric`/`decimal` para
  dinero (**nunca `float`**), `timestamptz` para instantes, `date` para fechas de calendario, enum o tabla
  de catálogo en vez de strings libres, UUID sólo si aporta (ver criterio de PK en `data-platform-standards`).

## 4. Calidad y testing del SQL

- **Gates de CI, en orden de coste creciente** (todos rompen el build):
  1. `sqlfluff lint` con `dialect` y reglas del repo (y `sqlfluff fix`/`sqlfmt` en pre-commit).
  2. Validación de que **toda migración aplica en limpio y en orden** sobre una base vacía.
  3. **Migración aplicada sobre una copia con datos representativos**, midiendo tiempo y bloqueos.
  4. Tests de comportamiento de las consultas contra el **mismo motor y versión que producción**
     (contenedor efímero, `testcontainers` o servicio de CI). **PROHIBIDO probar contra SQLite si
     producción es PostgreSQL**: los dialectos difieren justo en lo que rompe.
  5. Comprobación de plan en las consultas críticas (ver §6).
- **Qué se testea**: no la sintaxis (eso lo hace el motor) sino el **comportamiento**:
  - Camino feliz **y bordes**: conjunto vacío, un único elemento, duplicados, `NULL` en cada columna
    nullable, valores límite, colación y acentos, huso horario en el borde del día.
  - **Invariantes del modelo como aserciones ejecutables**: unicidad, integridad referencial, grano
    (una fila por X), rangos válidos. Formulación y propiedad en `data-governance-quality-standards`;
    aquí, que existan y corran.
  - **Errores esperados**: violación de restricción, conflicto de concurrencia, deadlock, timeout.
  - Toda consulta corregida por un bug deja **test de regresión con los datos que lo reproducían**.
- Datos de prueba **construidos en el test**, no un dump de producción (dato personal + no determinismo).
  Cero dependencia del orden de filas: sin `ORDER BY`, el orden **no existe** — asertarlo es un test flaky.
- Revisión: un `ALTER TABLE` y un `DELETE`/`UPDATE` sin `WHERE` acotado se revisan como código de
  producción, con el plan y el número de filas afectadas en la PR.

## 5. Seguridad: la inyección SQL es el eje

**Consultas parametrizadas, siempre, sin excepción.** Un *placeholder* (`$1`, `?`, `:nombre`) no es una
plantilla de texto: el valor viaja **fuera** de la sentencia y el motor nunca lo interpreta como código.
Todo lo demás es una variante de concatenación.

- **PROHIBIDO** construir SQL con concatenación, interpolación (`f"..."`, `${}`, `+`), `printf`/`format`
  del lenguaje o del motor con datos de entrada. `format()` de PostgreSQL y `sp_executesql` mal usados son
  **la vía real de inyección en 2026**, no el `' OR 1=1 --` de los tutoriales: el equipo cree que "usa el
  ORM" y esconde un `raw()`/`.query()` con una parte concatenada.
- **Escapar manualmente no es una defensa**: depende de la codificación, de la collation, del modo del
  motor (`NO_BACKSLASH_ESCAPES`) y de que nadie olvide una ruta. La única defensa es que el dato no forme
  parte de la sentencia.
- **Los identificadores no se pueden parametrizar**, y ahí está el agujero real. Cuando de verdad necesitas
  un nombre de tabla, columna u orden dinámicos:
  1. **Primero, evítalo**: una **lista blanca** que mapea la entrada del usuario a un identificador
     literal escrito en el código (`{"fecha": "created_at", "importe": "total"}`) resuelve el 95 % de los
     casos. Si el valor no está en el mapa, es un error, no un identificador.
  2. Si no hay más remedio, **quoting de identificador por la vía del driver o del motor**, nunca a mano:
     `quote_ident()`/`format('%I')` en PostgreSQL, `QUOTENAME()` en SQL Server,
     `DBMS_ASSERT.ENQUOTE_NAME` en Oracle, o el helper de identificadores del driver
     (`psycopg.sql.Identifier`, `sqlalchemy.sql.quoted_name`, `Sequelize.escapeIdentifier`…).
  3. `ORDER BY` dinámico: **sólo por lista blanca**; la dirección (`ASC`/`DESC`) también, nunca desde el
     parámetro tal cual. `ORDER BY <número>` con entrada de usuario es inyección con otro nombre.
- **SQL dinámico dentro del motor** (`EXECUTE`, `sp_executesql`, `EXECUTE IMMEDIATE`): mismo criterio —
  parámetros vinculados (`USING`, `@params` de `sp_executesql`), nunca cadena montada. Vetado
  `EXEC(@sql)` con `@sql` construido por concatenación.
- **Mínimo privilegio como segunda capa**: la aplicación se conecta con un rol **sin DDL, sin `SUPERUSER`,
  sin acceso a esquemas ajenos**, y con permisos por tabla/columna. Rol de sólo lectura para las consultas
  de lectura. **RLS** (PostgreSQL, SQL Server) cuando el aislamiento por inquilino es un requisito de
  seguridad y no una convención de `WHERE tenant_id = ...` que alguien acabará olvidando. Un usuario de
  aplicación que puede `DROP TABLE` convierte una SQLi en una catástrofe en vez de en una fuga.
- **Ceguera evitable**: errores del motor **nunca** al cliente (revelan esquema y habilitan inyección
  basada en error); `LIMIT` obligatorio en toda consulta expuesta; `statement_timeout`/timeout de comando
  siempre configurado (la SQLi ciega basada en tiempo necesita consultas largas).
- **Dato sensible en la consulta**: nada de secretos ni de datos personales en literales que acaben en el
  log de sentencias lentas, en `pg_stat_statements` o en un plan guardado. Los parámetros ayudan también aquí.
- **Auditoría y trazabilidad**: `application_name`/comentario de contexto en la sesión para atribuir una
  consulta a un servicio; el proceso de gestión del hallazgo, en `appsec-standards`.

## 6. Corrección y rendimiento del SQL

**`NULL` y lógica trivaluada — origen de bugs silenciosos**:
- `NULL = NULL` es `UNKNOWN`, no `TRUE`. Comparaciones con `IS NULL` / `IS NOT NULL`, o
  `IS [NOT] DISTINCT FROM` para comparar tratando `NULL` como valor.
- **`NOT IN (subconsulta)` con un solo `NULL` devuelve cero filas**. Usar `NOT EXISTS`, que además suele
  optimizar mejor. Es el bug de SQL más caro que existe.
- Los agregados **ignoran `NULL`** (`COUNT(col)` ≠ `COUNT(*)`; `AVG` divide entre los no nulos).
- `WHERE` filtra por `TRUE`, no por "no falso": una fila con `UNKNOWN` desaparece; en un `CHECK`, en cambio,
  `UNKNOWN` **pasa**. La asimetría es real y hay que tenerla presente al escribir restricciones.
- `LEFT JOIN` + condición sobre la tabla derecha en el `WHERE` **lo convierte en `INNER JOIN`**: la
  condición va en el `ON`.
- Diseño: **`NOT NULL` por defecto**; un `NULL` debe significar algo declarado, no "no lo sabíamos".

**Conjuntos, no bucles**:
- **Piensa en conjuntos**: una consulta que resuelve el problema entero le gana casi siempre a N consultas
  desde el cliente. **El N+1 está vetado** en cualquiera de sus formas (bucle del ORM, `for` que consulta
  por fila, cursor que hace un `UPDATE` por iteración).
- **CTEs y funciones de ventana en lugar de subconsultas correlacionadas y de lógica en el cliente**:
  `ROW_NUMBER()`/`RANK()` con `PARTITION BY` para el "top N por grupo"; `LAG`/`LEAD` para comparar con la
  fila anterior; `SUM() OVER (ORDER BY ... ROWS BETWEEN ...)` para acumulados; `FILTER (WHERE ...)` o
  `CASE` dentro del agregado para pivotar. Traerse los datos al cliente para ordenar, agrupar o comparar
  es el antipatrón por defecto y suele ser dos órdenes de magnitud más caro.
- **CTE recursiva** (`WITH RECURSIVE`) para jerarquías y explosión de listas de materiales, **con corte de
  profundidad explícito**. Si el recorrido es de profundidad variable y sin cota razonable, la pregunta ya
  no es de SQL: ver `graph-db-standards`.
- `GROUP BY`: agrupar por las columnas **reales**, no por posición ordinal (`GROUP BY 1, 2` es cómodo en
  exploración y frágil en producción). MySQL con `ONLY_FULL_GROUP_BY` desactivado permite seleccionar
  columnas no agregadas y devuelve un valor **arbitrario**: activar el modo estricto y tratar cualquier
  consulta que dependa de ese comportamiento como un bug. `HAVING` filtra sobre agregados; filtrar filas
  individuales en `HAVING` en vez de `WHERE` procesa de más.
- `UNION` deduplica (y ordena para hacerlo): usa **`UNION ALL`** salvo que la deduplicación sea el objetivo.
- `DISTINCT` como parche de un `JOIN` que multiplica filas es una señal de consulta mal construida:
  arregla el `JOIN` o usa `EXISTS`.

**SARGability — cómo se escribe la consulta para que el índice sea usable**:
- **Una función sobre la columna indexada mata el índice**: `WHERE UPPER(email) = $1`,
  `WHERE date(created_at) = $1`, `WHERE col + 0 = $1`. Reescribir el predicado sobre la columna desnuda
  (`created_at >= $1 AND created_at < $2`) o crear un índice de expresión — cuál índice, en la skill del motor.
- `LIKE '%algo'` (comodín inicial) no usa un índice B-tree. Es un problema de búsqueda, no de SQL: ver
  `search-engines-standards`.
- **Discordancia de tipos** (comparar `varchar` con número, `int` con `bigint` en algunos motores) provoca
  conversión implícita y descarta el índice. Tipar bien el parámetro en el driver.
- `OR` entre columnas distintas suele impedir un buen plan: `UNION ALL` de dos ramas indexadas gana.
- Predicados **selectivos primero** conceptualmente (aunque el optimizador reordene): filtra en el motor,
  no traigas y descartes.
- **Paginación por *keyset*** (`WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT n`),
  no `OFFSET` grande: `OFFSET 100000` lee y descarta 100 000 filas.

**Transacciones y concurrencia**:
- **Transacciones cortas y con alcance explícito**: `BEGIN` … `COMMIT` alrededor de la unidad atómica, y
  **cero I/O externo dentro** (llamadas HTTP, envío de correo, esperas). Una transacción abierta mientras
  se espera a un tercero es un bloqueo esperando a ocurrir.
- **Niveles de aislamiento y qué anomalía permite cada uno** (ANSI, con la salvedad de que cada motor los
  implementa a su manera — verificar por motor y versión, §8):

  | Nivel | Dirty read | Non-repeatable read | Phantom | Write skew |
  |---|---|---|---|---|
  | Read Uncommitted | posible | posible | posible | posible |
  | Read Committed | no | posible | posible | posible |
  | Repeatable Read | no | no | posible según el motor (**InnoDB y el snapshot de PostgreSQL los evitan**) | **posible** |
  | Serializable | no | no | no | no |

  Consecuencias que sí decides tú: el default no es el mismo en todos los motores (tabla de §2); en
  PostgreSQL, `REPEATABLE READ` y `SERIALIZABLE` **abortan la transacción con error de serialización** y
  **la aplicación debe reintentar** — código que no maneja ese reintento está roto por diseño. `SERIALIZABLE`
  no es "más lento" de forma abstracta: es correcto y con coste de reintentos; súbelo cuando la invariante
  cruza filas (write skew) y bajarlo requiere justificar por qué.
- **`SELECT ... FOR UPDATE`** para bloquear filas que vas a modificar (y `FOR NO KEY UPDATE`/`FOR SHARE`
  según el caso); `SKIP LOCKED` para colas y trabajo repartido, `NOWAIT` cuando prefieres fallar rápido a
  esperar. **No sustituye a un nivel de aislamiento adecuado**: bloquea lo que lees, no lo que no existe aún.
- **Deadlocks**: se previenen accediendo a los recursos **siempre en el mismo orden** y manteniendo las
  transacciones cortas; se **gestionan** con reintento con backoff en el cliente, porque el motor mata a
  una de las dos víctimas y eso es normal, no excepcional. Un deadlock recurrente entre las mismas dos
  sentencias es un bug de orden de acceso, no un problema de capacidad.
- Idempotencia: usa restricciones de unicidad + `ON CONFLICT`/`MERGE` en vez de "comprobar y luego
  insertar" — el hueco entre el `SELECT` y el `INSERT` es una condición de carrera, siempre.

**DDL y migraciones compatibles hacia atrás (expand/contract)** — obligatorio:
1. **Expand**: añadir lo nuevo de forma compatible (columna nullable o con default, nueva tabla, nuevo
   índice). La versión N-1 del código sigue funcionando.
2. **Migrar**: rellenar datos **por lotes acotados y transacciones cortas**, no en un `UPDATE` masivo que
   bloquea la tabla y hincha el WAL/undo.
3. **Desplegar** el código que usa lo nuevo y escribe en ambos sitios si hace falta.
4. **Contract**: en un **release posterior**, eliminar lo viejo.

- **Nunca una migración que rompa la versión N-1** durante un despliegue rolling: renombrar una columna,
  cambiar su tipo o borrarla en el mismo release que el código es una caída garantizada.
- **Lo que bloquea, bloquea**: `ALTER TABLE` que reescribe la tabla, añadir una FK o un `CHECK` que valida
  todo, crear un índice sin la variante concurrente. Usa las variantes online del motor
  (`CREATE INDEX CONCURRENTLY`, `NOT VALID` + `VALIDATE CONSTRAINT`, `ALGORITHM=INPLACE`/`LOCK=NONE`,
  `ONLINE=ON`, herramientas de cambio online) y **fija un `lock_timeout` corto**: una migración que espera
  un lock encola a todo lo que viene detrás y tumba el servicio antes de tocar un solo byte.
- Migraciones **inmutables una vez aplicadas** (nueva migración para corregir, nunca editar la aplicada) y
  **con marcha atrás pensada** —o declarada explícitamente como irreversible—. Toda migración destructiva
  se revisa con nombre y apellidos.

**Planes de ejecución**:
- Lee el plan **real**, no el estimado: `EXPLAIN (ANALYZE, BUFFERS)` en PostgreSQL, `EXPLAIN ANALYZE` en
  MySQL 8+, plan real en SSMS o `SET STATISTICS IO/TIME` en SQL Server, `DBMS_XPLAN.DISPLAY_CURSOR` en Oracle.
- Qué mirar, en este orden: **divergencia entre filas estimadas y reales** (síntoma de estadísticas o de
  predicado no estimable), el nodo que domina el tiempo, escaneos secuenciales sobre tablas grandes,
  *nested loop* con muchas iteraciones, ordenaciones y hashes que se derraman a disco.
- **Mide con datos representativos**: un plan sobre 100 filas no dice nada del plan sobre 100 millones.
- Cuando el plan es malo pese a una consulta bien escrita, **el problema deja de ser de esta skill**:
  estadísticas, parámetros de memoria, *plan cache*, *parameter sniffing* y sugerencias de índice son de la
  skill del motor. **Los *hints* del optimizador son último recurso y con caducidad**: congelan una
  decisión que el motor revisaría solo.

## 7. Sostenibilidad a largo plazo

- **SQL escrito a mano vs. generado**:
  - **ORM**: correcto y preferible para CRUD por clave primaria, unidad de trabajo y mapeo de agregados.
    Deja de serlo en cuanto la consulta tiene más de dos `JOIN`, agregación o ventanas: ahí se escribe SQL
    a mano (o con un constructor tipado tipo sqlc/jOOQ/`sqlalchemy.select` explícito). **El SQL generado
    se revisa y se mide igual que el escrito**: "lo genera el ORM" no es una justificación de plan.
  - **dbt/SQLMesh**: el modelo es SQL y **está sujeto a esta skill** (estilo, `NULL`, joins, ventanas,
    SARGability). La orquestación, materialización, incrementalidad y tests del framework son de
    `data-engineering-standards`. Jinja que construye SQL con interpolación de valores es **la misma
    inyección de §5** cuando la entrada no es un literal del repo.
  - Procedimientos almacenados: lógica de negocio en el motor **sólo con motivo declarado** (integridad
    transaccional imposible fuera, coste de red prohibitivo). Coste asumido: versionado, testing y
    despliegue peores, y acoplamiento al motor.
- **Vistas**: útiles para encapsular una consulta canónica; peligrosas apiladas (vista sobre vista sobre
  vista produce planes imposibles de razonar). Máximo un nivel salvo justificación. Vistas materializadas
  con su política de refresco **declarada**, no improvisada.
- El SQL vive en el repo, en ficheros `.sql` o en el modelo, versionado y revisado. SQL guardado sólo en el
  motor, en una herramienta de BI o en el historial de alguien **no existe**.
- Cadencia: al subir de versión mayor de motor, releer los *breaking changes* del dialecto y volver a medir
  las consultas críticas — el optimizador cambia y algún plan empeora, siempre.

**Lista de prohibiciones (veto):**
- ❌ Cualquier SQL construido por concatenación o interpolación con datos de entrada. Sin excepciones.
- ❌ Identificador dinámico sin lista blanca ni quoting del driver/motor.
- ❌ `SELECT *` en código de producción, en vistas o en `CREATE TABLE AS`.
- ❌ **Join implícito por coma** (`FROM a, b WHERE ...`) y `NATURAL JOIN`.
- ❌ `NOT IN (subconsulta)` sobre una columna nullable (usa `NOT EXISTS`).
- ❌ `UPDATE`/`DELETE` sin `WHERE` acotado, o ejecutado sin haber visto antes el `SELECT` equivalente.
- ❌ `DISTINCT` para tapar filas duplicadas por un `JOIN` mal hecho.
- ❌ `float`/`double` para dinero. Fechas como texto. Zonas horarias implícitas.
- ❌ Bucle en el cliente que ejecuta una consulta por fila (N+1) o cursor con `UPDATE` por iteración.
- ❌ `OFFSET` grande como paginación.
- ❌ Migración que rompe la versión N-1 del código, o `ALTER TABLE` bloqueante sin `lock_timeout` y sin
  variante online. Editar una migración ya aplicada.
- ❌ Restricciones y claves foráneas "gestionadas por la aplicación" en vez de declaradas.
- ❌ Depender del orden de filas sin `ORDER BY`, o de columnas no agregadas con `ONLY_FULL_GROUP_BY`
  desactivado.
- ❌ Transacción abierta alrededor de una llamada de red. Transacción larga "porque es más simple".
- ❌ Conectar la aplicación con un rol con privilegios de DDL o de superusuario.
- ❌ *Hints* del optimizador como solución permanente y sin fecha de revisión.
- ❌ Probar contra un motor distinto al de producción (SQLite en CI, PostgreSQL en prod).

## 8. Verificación web obligatoria

Antes de fijar cláusulas, versiones o herramientas, **verifica online** (WebSearch/WebFetch), con las
**notas de release del motor** como fuente primaria y las tablas de compatibilidad de terceros sólo como
pista — sus columnas suelen indicar *última versión probada*, no *versión desde la que existe*, y leerlas
al revés produce afirmaciones falsas (le pasó a este documento durante su redacción con `MERGE`):
1. **Estándar**: SQL:2023 (ISO/IEC 9075) es la edición vigente; la Parte 16 (SQL/PGQ) figura ya en estado
   *"to be revised"*, así que hay una revisión en curso. **No hay edición "SQL:2026" confirmada a 2026-08**:
   comprobar la actividad de ISO/IEC JTC 1/SC 32 WG3 antes de citar una.
2. **Versión mínima del motor del proyecto** (no la última del producto) para cada cláusula que uses:
   `MERGE` (PostgreSQL 15+, `RETURNING` desde 17; **inexistente en MySQL, MariaDB y SQLite** a 2026-08),
   `JSON_TABLE` y constructores SQL/JSON (PostgreSQL 17+), `GROUP BY ALL` (**no en PostgreSQL 18**,
   *committed* para 19; disponible en DuckDB, Snowflake, Databricks y BigQuery), `FILTER`, `MATCH_RECOGNIZE`,
   `GRAPH_TABLE`/SQL/PGQ, ventanas con `GROUPS`/`EXCLUDE`.
3. **Huecos declarados, no verificados a ago-2026**: si `JSON_TABLE` existe en **SQL Server 2025** (sí están
   verificados el tipo `JSON` nativo, los índices JSON, `JSON_CONTAINS` y las funciones `REGEXP_*`);
   el estado y las limitaciones conocidas de `MERGE` en SQL Server; el soporte de `MERGE` en MariaDB
   independiente de MySQL; los defaults de nivel de aislamiento en la **versión concreta** de cada motor
   (la tabla de §2 refleja el comportamiento clásico y debe confirmarse por versión).
4. **Herramientas**: SQLFluff (4.2.2 a 2026-06, **MIT**, mantenimiento activo) — comprobar si 5.0 ya hizo
   default el motor Rust y qué reglas cambian de severidad; **sqlfmt**, instalado como **`shandy-sqlfmt`**
   (Apache-2.0, 0.31.0 a 2026-08) — confirmar el nombre del paquete antes de instalarlo. Verificar además
   que ninguna de las dos ha cambiado de licencia ni entrado en modo mantenimiento: el catálogo ya tiene
   precedentes (Trivy cambió de licencia; gitleaks se declaró *feature complete* y su acción exige licencia
   comercial para organizaciones desde la v2).
5. **CVEs y avisos** del motor y del driver antes de fijar una versión (osv.dev / GitHub Advisories).
6. Antes de un upgrade mayor de motor, los **breaking changes del dialecto** en las notas oficiales — no de
   memoria ni de un blog de terceros sin contrastar.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
