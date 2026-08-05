---
name: sqlserver-dba-standards
description: Use when operating Microsoft SQL Server — sqlcmd, SSMS, T-SQL, DBCC CHECKDB, tempdb file configuration, recovery models and transaction log growth, BACKUP DATABASE/DIFFERENTIAL/LOG and a broken log chain, RESTORE WITH NORECOVERY or WITH STANDBY, backup to URL, Always On availability groups, basic availability groups, failover cluster instances on WSFC, CLUSTER_TYPE EXTERNAL with Pacemaker on Linux, Query Store, sys.dm_os_wait_stats and wait statistics, plan regression and forced plans, clustered versus nonclustered and covering indexes, index fragmentation, RCSI and snapshot isolation, deadlock graphs and blocking, SQL Server Agent jobs, Ola Hallengren MaintenanceSolution, First Responder Kit sp_Blitz, dbatools, TDE, mssql-conf and mssql-server containers, edition core and memory limits, core versus Server+CAL licensing and Software Assurance failover rights, or SQL Server 2016/2017/2019/2022/2025 support dates and cumulative updates.
---

# Estándares de administración de Microsoft SQL Server

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Tesis del documento**: en SQL Server **la edición es una decisión de arquitectura**, no una
> línea de pedido. Cambiar de Standard a Enterprise para conseguir grupos de disponibilidad
> completos o reconstrucción de índices en línea es una compra de seis cifras en instalaciones
> medianas; diseñar una solución que solo funciona en Enterprise y aterrizarla en Standard es un
> proyecto fallido. **La edición se fija antes del diseño, y el diseño la respeta.**
>
> **Segunda tesis**: la mayoría de las instancias que se encuentran en producción están
> **sobredimensionadas** (Enterprise para una carga que cabe holgada en Standard) y a la vez
> **mal configuradas** en lo que sí es gratis: `tempdb`, `MAXDOP`, modelo de recuperación, RCSI y
> mantenimiento. Casi siempre hay más rendimiento en corregir eso que en subir de edición.

## 1. Alcance y triggers

Aplica a diseñar, licenciar, operar, respaldar, dar alta disponibilidad, diagnosticar y mantener
SQL Server on-prem, en Linux y en contenedores: ediciones y límites, arquitectura de instancia y
bases del sistema, `tempdb`, modelos de recuperación y cadena de log, respaldo y restauración
nativos, Always On (AG y FCI), rendimiento por estadísticas de espera y Query Store, índices,
bloqueo y aislamiento, T-SQL con criterio, trabajos de mantenimiento, seguridad del motor y
versiones/soporte.

Disparadores: `sqlcmd`, `SSMS`, `bcp`, `mssql-conf`, `mssql-cli`, `dbatools`, `T-SQL`,
`DBCC CHECKDB`, `DBCC SHOW_STATISTICS`, `tempdb`, `master`/`model`/`msdb`,
`RECOVERY FULL|SIMPLE|BULK_LOGGED`, `log_reuse_wait_desc`, `BACKUP DATABASE`, `BACKUP LOG`,
`RESTORE ... WITH NORECOVERY|STANDBY`, `RESTORE VERIFYONLY`, `BACKUP TO URL`, `msdb.dbo.backupset`,
`Always On`, `availability group`, `AG listener`, `WSFC`, `CLUSTER_TYPE = EXTERNAL|NONE`,
`FAILOVER_MODE`, `FCI`, `Query Store`, `sys.query_store_*`, `sys.dm_os_wait_stats`,
`sys.dm_exec_requests`, `sys.dm_db_index_usage_stats`, `sys.dm_db_index_physical_stats`,
`sp_WhoIsActive`, `sp_Blitz`, `sp_BlitzIndex`, `sp_QuickieStore`, `MaintenanceSolution.sql`,
`READ_COMMITTED_SNAPSHOT`, `ALLOW_SNAPSHOT_ISOLATION`, `deadlock graph`, `MAXDOP`,
`cost threshold for parallelism`, `max server memory`, `SQL Server Agent`, `TDE`, `sysadmin`,
`mssql/server` (contenedor), "cumulative update", "edición Standard", "Software Assurance".

**No aplica**: ver
- `data-platform-standards` (**skill madre**: PostgreSQL como default, modelado relacional,
  migraciones expand/contract, clasificación y retención del dato. Su principio —*un almacén por
  necesidad, no por moda*— sigue mandando: **esta skill no justifica elegir SQL Server**, cubre
  operarlo bien cuando ya está por decisión histórica, por un producto de terceros que lo exige o
  por un ecosistema .NET/Windows consolidado).
- `windows-server-ad-standards` (**frontera crítica, delegación total**: bosque/dominio/OU, GPO,
  **Kerberos y NTLM**, SPN, delegación, **gMSA/dMSA**, modelo Tier 0, PAW, recuperación del bosque
  y endurecimiento de Windows Server son **suyos**. La autenticación integrada de SQL Server
  *se apoya* en todo eso: **aquí solo se dice qué exige el motor** —cuenta de servicio, SPN
  correcto para Kerberos, roles del servidor— y **se delega el cómo**. **Prohibido duplicar aquí
  criterio de AD.**).
- `ha-clustering-standards` (**Pacemaker/Corosync, quórum, fencing/STONITH y su disciplina son
  suyos**). Frontera declarada explícitamente: **WSFC es el clúster de Windows y es de esta
  skill** (es inseparable de FCI y de los AG en Windows); **cuando SQL Server corre en Linux, el
  gestor de clúster es Pacemaker y manda `ha-clustering-standards`** —incluido el fencing, que sin
  él no hay HA— y aquí solo vive lo que es del motor: `CLUSTER_TYPE = EXTERNAL`,
  `FAILOVER_MODE = EXTERNAL`, el recurso de AG y el paquete `mssql-server-ha`.
- `backup-recovery-standards` y `bcdr-standards` — **regla de arbitraje espejada palabra por
  palabra desde `backup-recovery-standards` §1**:
  > **"¿cómo se hace la copia?" es de `backup-recovery`** (herramienta, repositorio, 3-2-1, GFS,
  > dedup, cifrado del repo, integridad, catálogo, procedimiento de restore); **"¿cuánto podemos
  > perder, en qué orden lo levantamos y quién lo decide?" es de `bcdr`**.
- `sql-standards` (**el lenguaje SQL**; regla de arbitraje espejada desde su §1: *si la pregunta
  cambia cómo se escribe la consulta o el DDL, es de `sql-standards`; si cambia qué motor se
  elige, cómo se dimensiona, respalda, replica o restaura, es de aquí*). Suyas son las
  peculiaridades de T-SQL que **cambian el código** —`MERGE` y sus condiciones de uso seguro,
  `OUTPUT`, `TOP`, `APPLY`, `OFFSET/FETCH`, el efecto de la colación en la comparación de
  cadenas—; de aquí, todo lo que decide la ejecución: Query Store, planes forzados, niveles de
  compatibilidad, `READ_COMMITTED_SNAPSHOT`, estadísticas, DBCC y el licenciamiento por core de
  las características que una construcción pueda requerir.

  Extensión propia: **lo específico del motor es de aquí** — modelos de recuperación, cadena de
  log y cómo se rompe, backup completo/diferencial/de log, `RESTORE ... WITH STANDBY`,
  `RESTORE VERIFYONLY`/`CHECKSUM`, backup a URL y el papel de los AG en el RPO. **El repositorio,
  su inmutabilidad y la cadencia del restore de prueba son de `backup-recovery`**; **el RPO/RTO
  que justifica el modo síncrono y el ejercicio de conmutación son de `bcdr`**.
- `oracle-dba-standards` (el otro motor propietario del catálogo; distinto proveedor, mismo
  patrón: **el licenciamiento decide la arquitectura**. No compiten).
- `dotnet-standards` (**el código C#/EF Core que consume esta base de datos es suyo**: driver,
  pool, `Microsoft.Data.SqlClient`, migraciones desde la aplicación).
- `streaming-cdc-standards` (**la captura es suya**: CDC, change tracking, change event streaming,
  Debezium; **el coste en el motor es de aquí**: retención del log, trabajos de captura, impacto
  en el modelo de recuperación).
- `azure-standards` (Azure SQL Database, Managed Instance, Arc, Azure Hybrid Benefit),
  `aws-standards`/`gcp-standards` (RDS for SQL Server, Cloud SQL for SQL Server).
- `vulnerability-management-standards` (**el ciclo de CVE y la ventana de parcheo es suyo**; aquí
  solo la mecánica de CU y su cadencia), `identity-access-management-standards`,
  `cryptography-pki-standards` (TLS y las claves en que se apoya TDE), `secrets-management-standards`,
  `linux-hardening-standards` y `podman-systemd-containers-standards`/`kubernetes-standards`
  (el SO y el runtime cuando SQL Server corre fuera de Windows),
  `observability-standards`, `grc-compliance-standards`, `privacy-engineering-standards`,
  `iac-standards`, `firewall-policy-standards` (exposición del puerto 1433).
- `mysql-mariadb-dba-standards` (el tercer motor relacional del catálogo; open source, sin la
  variable de edición que domina aquí), `timeseries-db-standards`, `message-brokers-standards`,
  `nosql-standards`, `search-engines-standards`, `caching-cdn-standards` (otros almacenes
  especializados).

## 2. Ediciones y licenciamiento: la decisión dominante

> **Aviso de alcance, no negociable**: aquí se fija **criterio técnico**, no asesoramiento
> contractual. Toda decisión con impacto económico se valida contra la **guía de licenciamiento de
> SQL Server**, los **Product Terms** vigentes y el **gestor de licencias de la organización**.
> Ningún precio aparece en este documento (§8).

### 2.1 Límites reales de Standard — verificados en SQL Server 2025 (17.x)

Fuente primaria: *Editions and supported features of SQL Server 2025*, learn.microsoft.com
(comprobado también contra el markdown del repositorio `MicrosoftDocs/sql-docs`).

| Límite | Enterprise | **Standard** | Express |
|---|---|---|---|
| Cómputo máximo por instancia (motor) | Máximo del SO | **Menor de 4 sockets o 32 núcleos** | Menor de 1 socket o 4 núcleos |
| Memoria máxima de *buffer pool* por instancia | Máximo del SO | **256 GB** | 1 410 MB |
| Caché de segmento columnstore | Ilimitada | 32 GB | 352 MB |
| Datos *memory-optimized* por base | Ilimitada | 32 GB | 352 MB |

**Cambio que sí mueve un diseño** — nota al pie 2 del propio documento: *"In SQL Server 2022 (16.x)
and earlier versions, the limit is the lesser of 4 sockets or 24 cores."* Es decir: **Standard pasó
de 24 a 32 núcleos y su buffer pool subió a 256 GB en la versión 2025**. Un dimensionamiento hecho
sobre "Standard son 24 cores y 128 GB" está desfasado y puede estar justificando un Enterprise
innecesario. **Verificar siempre contra la página de la versión concreta**: los límites son por
versión.

### 2.2 Qué separa Enterprise de Standard (lo que decide la arquitectura)

Solo Enterprise (verificado en la tabla de 2025):
- **Always On availability groups** completos, **contained AG**, **distributed AG**, reencaminado
  automático de conexión lectura/escritura. **Standard solo tiene *basic availability groups***:
  *"A basic availability group supports two replicas, with one database."* — dos réplicas, **una
  sola base de datos**, sin réplica legible.
- **FCI**: Enterprise hasta **16 nodos**; Standard **2 nodos**.
- **Reconstrucción y creación de índices en línea** (y su versión *resumable*), **cambio de esquema
  en línea**, **restauración de página y fichero en línea**, *fast recovery*, backups reflejados.
- Casi todo *Intelligent Query Processing* avanzado (batch mode on rowstore, adaptive joins,
  memory grant feedback, cardinality feedback, DOP feedback, *automatic tuning*), **Query Store en
  réplicas secundarias**, mantenimiento paralelo de índices, `CHECKDB` paralelo, vistas
  particionadas distribuidas.

**En Standard, y esto es lo que suele sorprender** (y desmonta muchos "necesitamos Enterprise"):
**TDE**, **cifrado de backups**, **compresión de backups**, **particionado de tablas e índices**,
**compresión de datos**, **columnstore**, **In-Memory OLTP**, **Query Store**, **Always Encrypted**
(también con *secure enclaves*), **row-level security**, **dynamic data masking**, **auditoría**,
**Change Data Capture**, **Accelerated Database Recovery**, **optimized locking**, **backup y
restore a almacenamiento objeto compatible con S3**, **AG sin clúster** (*clusterless*) y
—**novedad de 2025**— **Resource Governor**, que era exclusivo de Enterprise.

Regla de decisión: **se justifica Enterprise por HA real (AG multi-base o multi-réplica),
mantenimiento en línea 24×7 o techo de cómputo**; no por funcionalidades que ya están en Standard.
Cualquier propuesta de Enterprise se acompaña de cuál de esas tres razones aplica.

Otros hechos de edición verificados en 2025: **Express** llega hasta 1 socket/4 núcleos y ahora
incluye lo que antes era *Express with Advanced Services*; existen **Enterprise Developer** y
**Standard Developer** como ediciones separadas (Developer = funcionalidad completa de su edición,
**licenciada solo para desarrollo y pruebas — nunca en producción**); la edición **Web** se retira
a partir de 2025 (2022 es la última que la incluye); *Reporting Services* on-prem se consolida bajo
**Power BI Report Server**.

### 2.3 Modelo de licencia

- **Por núcleo**: se cuentan **núcleos físicos** (el *hyperthreading* no cuenta), con mínimo por
  procesador y venta en paquetes de 2. Es el único modelo disponible para Enterprise en acuerdos
  nuevos.
- **Servidor + CAL**: solo Standard. Deja de compensar a partir de cierto número de usuarios; el
  umbral depende del acuerdo — **calcularlo, no estimarlo**.
- **Enterprise con Server+CAL** (heredado, no disponible para acuerdos nuevos) está **limitado a
  20 núcleos por instancia** (nota al pie 1 del documento de ediciones): un contrato antiguo puede
  estar poniendo un techo de rendimiento que nadie recuerda.
- **Virtualización**: con **Software Assurance**, Enterprise ofrece virtualización ilimitada sobre
  un host completamente licenciado; sin SA, se licencia por VM. Contar VMs sobre un host
  compartido sin SA es la vía rápida a un hallazgo de auditoría.

### 2.4 Software Assurance y su papel en alta disponibilidad — **la trampa cara**

**Los derechos de conmutación por error son un beneficio de Software Assurance (o de licencia por
suscripción). Sin SA, una réplica pasiva se licencia por completo, aunque nunca sirva una
consulta.** Con SA, por cada OSE licenciada se pueden ejecutar réplicas pasivas en anticipación de
un failover (típicamente una para HA, una para DR y una en Azure), **siempre que no sirvan datos ni
ejecuten trabajo activo** y que no excedan la licencia de la primaria.

Consecuencias directas de diseño, no de compras:
- Un **secundario legible** en un AG **deja de ser pasivo**: se licencia. "Descargar los informes a
  la réplica" es una compra. Lo mismo vale para ejecutar backups o `CHECKDB` sobre el secundario
  según los términos vigentes: **verificarlo antes de diseñarlo**.
- El coste de HA en SQL Server no es el clúster: **es la licencia del segundo nodo si no hay SA**.
- **Verificar los Product Terms vigentes**: los derechos de failover se han redefinido más de una
  vez. Aquí no se fija su redacción; se fija la obligación de comprobarla.

## 3. Arquitectura de instancia

- **Una instancia por host como default.** Instancias con nombre múltiples reparten memoria y CPU
  entre motores que compiten y complican el parcheo; separar por contenedor o por VM es más limpio
  y más fácil de licenciar. Consolidar en **bases de datos dentro de una instancia**, no en
  instancias dentro de un host.
- **Bases del sistema**: `master` (configuración e inicios de sesión) y `msdb` (Agent, historial de
  backups, planes) **entran en la estrategia de respaldo** — perderlas cuesta la reconstrucción del
  entorno; `model` es la plantilla de toda base nueva (fijar allí el modelo de recuperación y los
  tamaños de fichero por defecto evita sorpresas); `tempdb` se recrea al arrancar y **no se
  respalda**.
- **Memoria**: `max server memory` **siempre fijado** dejando margen al SO (y a otros consumidores
  del host); nunca por defecto. `min server memory` solo si hay competencia real. En Linux, límites
  vía `mssql-conf` y **cgroup v2** (respetado a partir de SQL Server 2025 y de 2022 CU 20 —
  antes, un contenedor con límite de memoria podía morir por OOM porque el motor lo ignoraba).
- **Paralelismo**: `MAXDOP` y `cost threshold for parallelism` **explícitos** desde el día uno. El
  valor por defecto de `cost threshold` (5) es de los años noventa y paraleliza consultas triviales:
  subirlo es uno de los cambios con mejor relación beneficio/riesgo del producto. `MAXDOP` según
  número de núcleos y NUMA, con la excepción documentada por carga.
- **Almacenamiento**: datos, log y `tempdb` en volúmenes con perfiles de E/S distintos; el log de
  transacciones es **escritura secuencial y sensible a latencia** — es el primer sitio donde poner
  el almacenamiento rápido. Formato NTFS con unidad de asignación de 64 KB en Windows salvo criterio
  del fabricante de la cabina (`linux-storage-standards`/`onprem-standards` para el resto).
- **Autocrecimiento**: en incrementos **fijos y grandes**, nunca en porcentaje, y con
  *Instant File Initialization* habilitada (privilegio *Perform Volume Maintenance Tasks*) para que
  el crecimiento de datos no congele la instancia. El autocrecimiento es una **red de seguridad**,
  no una estrategia de capacidad: los ficheros se predimensionan.

### 3.1 `tempdb` — el ajuste con más impacto real

- **Múltiples ficheros de datos, todos del mismo tamaño y con el mismo autocrecimiento**: la
  contención de páginas de asignación en `tempdb` es el cuello de botella clásico de instancias
  ocupadas, y solo desaparece si los ficheros son simétricos (el asignador es *round-robin*
  proporcional al espacio libre: un fichero desigual se lleva todo el trabajo). El instalador
  moderno propone un número razonable según núcleos; **revisarlo, no aceptarlo a ciegas**, y
  **nunca** dejar un solo fichero en un servidor con varios núcleos.
- **Predimensionar** para que no crezca en caliente; volumen dedicado y rápido; *memory-optimized
  tempdb metadata* solo en Enterprise y con la carga que lo justifique.
- `tempdb` es **compartida por toda la instancia**: una consulta con un `sort` monstruoso o un
  `snapshot isolation` mal usado afecta a todas las bases. Vigilarla como recurso global.
- En Linux se admite `tempdb` sobre **tmpfs**: opción real de rendimiento, con la consecuencia de
  consumo de RAM asumida.

### 3.2 Modelos de recuperación y su consecuencia directa

| Modelo | Qué implica | Punto de recuperación |
|---|---|---|
| **SIMPLE** | El log se trunca automáticamente en cada *checkpoint*. **No hay backup de log** | Solo el último completo/diferencial. **RPO = horas**, se quiera o no |
| **FULL** | El log se retiene **hasta que se respalda**. Obligatorio para AG y *log shipping* | PITR al minuto/segundo, si y solo si hay backups de log periódicos |
| **BULK_LOGGED** | Registro mínimo de ciertas operaciones masivas | **Rompe el PITR dentro del intervalo** que contiene la operación masiva: se recupera al final del backup de log, no a un instante |

**La consecuencia que se olvida**: poner una base en **FULL sin programar backups de log** no da
mejor recuperación — hace que **el log crezca hasta llenar el disco** y tumbe la instancia. Es el
incidente autoinfligido más frecuente del producto. Regla operativa:

- El modelo lo determina el **RPO derivado por `bcdr-standards`**, y **FULL implica backups de log
  programados el mismo día que se activa**. No hay medias tintas.
- Diagnóstico obligatorio ante log que crece: `sys.databases.log_reuse_wait_desc` dice **por qué**
  no se puede reutilizar (`LOG_BACKUP`, `ACTIVE_TRANSACTION`, `AVAILABILITY_REPLICA`,
  `REPLICATION`…). Se lee **antes** de tocar nada.
- **Prohibido** `DBCC SHRINKFILE` sobre el log como rutina, y prohibido cualquier receta de
  Internet que pase por poner la base en SIMPLE para "limpiar el log": **rompe la cadena de log**
  (§4) y con ella el punto de recuperación.
- **VLF**: crecer el log en incrementos grandes y pocos; miles de VLF ralentizan el arranque y la
  recuperación.

## 4. Respaldo nativo y restauración

- **Tres piezas**: **completo** (base de la cadena), **diferencial** (todo lo cambiado desde el
  último completo — no desde el diferencial anterior) y **de log** (los cambios desde el backup de
  log anterior, y **solo** en FULL/BULK_LOGGED).
- **La cadena de log** es el activo: una secuencia ininterrumpida de backups de log desde un
  completo. **Se rompe con**: pasar la base a SIMPLE (aunque se vuelva a FULL, hace falta un nuevo
  completo), un backup de log con `TRUNCATE_ONLY` de versiones antiguas, o un **backup fuera de
  banda** hecho por otra herramienta que no use `COPY_ONLY`. De ahí la regla:
  **todo backup ad-hoc se hace con `COPY_ONLY`** — un completo normal desde una herramienta ajena
  reinicia la base del diferencial y deja los diferenciales programados sin sentido.
- **Verificación**: `WITH CHECKSUM` en el backup y `RESTORE VERIFYONLY WITH CHECKSUM` como mínimo
  automático. Eso **no** es un restore: solo dice que el fichero es legible.
- **`RESTORE ... WITH NORECOVERY`** para encadenar diferencial y logs; **`WITH STANDBY`** deja la
  base **legible entre aplicaciones de log** (fichero de deshacer) — es la herramienta adecuada
  para *log shipping* con secundario consultable, y la forma barata de tener una copia legible
  con retardo sin licenciar réplicas legibles.
- **Restauración a un instante**: `RESTORE ... WITH STOPAT` (o `STOPATMARK`) sobre la cadena de log.
  Ensayarlo antes de necesitarlo: el error humano se recupera con esto, no con un AG.
- **Backup a URL** (almacenamiento de objetos): soportado a *block blobs* con SAS; en 2025 también
  **a almacenamiento compatible con S3 vía REST**, en Enterprise **y Standard**. Es un destino, no
  una política — **el repositorio, la inmutabilidad y la regla 3-2-1 son de
  `backup-recovery-standards`**. En Linux, *backup to URL* con *page blob* no está soportado.
- **Cifrado**: `BACKUP ... WITH ENCRYPTION` disponible en Standard y Enterprise; el **certificado o
  clave asimétrica se respalda y se custodia fuera del sistema respaldado** (custodia de claves,
  `bcdr-standards`). Un backup cifrado cuyo certificado se perdió con el servidor es una copia
  inservible: **es la forma más común de descubrir que no había DR**.
- **Catálogo**: `msdb.dbo.backupset`/`backupmediafamily` es el registro de qué existe. Se consulta
  para detectar **huecos de cobertura** y se respalda con `msdb`.

> **Invariante compartido, sin matices**: **un backup sin restore probado no existe.** El gate no es
> "el job terminó en verde", es "restauramos, cronometramos y validamos". La cadencia y el registro
> del ejercicio los fija `backup-recovery-standards`; el procedimiento del motor es de aquí.

## 5. Alta disponibilidad

- **Availability Groups (AG)**: replicación a nivel de **base de datos** por envío de log.
  - **Síncrono** = RPO 0 y failover automático posible, **a costa de latencia en cada commit**
    (la primaria espera el endurecido en la secundaria). **Asíncrono** = sin impacto en latencia,
    con pérdida potencial y **solo failover manual forzado, con pérdida de datos**. La elección la
    dicta el RPO de `bcdr-standards`, no la comodidad.
  - **Listener**: la aplicación se conecta al *listener*, nunca al nombre de un nodo, y la cadena de
    conexión declara `MultiSubnetFailover=True` cuando hay subredes distintas. Sin eso, el failover
    "funciona" y la aplicación no vuelve.
  - **Réplica legible**: no es gratis en dos sentidos. **Licencia** (§2.4: deja de ser pasiva) y
    **rendimiento** — las consultas de solo lectura toman *snapshot isolation* de forma implícita,
    lo que genera **versionado de filas en la primaria** (14 bytes por fila modificada) y aumenta el
    uso de `tempdb` en la secundaria; además, el `REDO` puede bloquearse contra consultas largas y
    disparar el *redo lag*, que es RPO real perdido. Se monitoriza.
  - En Enterprise, según la documentación de 2025: hasta **8 réplicas secundarias**. **Standard solo
    tiene *basic AG***: 2 réplicas, **1 base de datos**, sin secundario legible (§2.2).
- **FCI (instancia de clúster de conmutación)**: comparte **almacenamiento**; protege del fallo del
  nodo, **no del fallo del dato** (una LUN corrupta lo está para todos). Requiere clúster
  (WSFC/Pacemaker) y almacenamiento compartido. Enterprise 16 nodos, Standard 2.
- **AG vs FCI, en una línea**: FCI protege el servidor con una sola copia del dato; AG protege el
  dato con varias copias y permite separación geográfica. **Se combinan** (FCI como réplica de un
  AG) solo con una razón escrita: la complejidad se multiplica.
- **Frontera de clúster, declarada**:
  - **Windows** → **WSFC** es el sustrato de FCI y de los AG (salvo *clusterless*). Su quórum
    (testigo de disco, de fichero, en la nube), su modelo de votos y su operación son **de esta
    skill**. El dominio, las cuentas y el DNS sobre los que se apoya son de
    `windows-server-ad-standards`.
  - **Linux** → el gestor es **Pacemaker/Corosync** y manda **`ha-clustering-standards`**,
    incluido su invariante: **sin fencing probado no hay HA, hay corrupción diferida**. Del motor
    es: `CLUSTER_TYPE = EXTERNAL` con `FAILOVER_MODE = EXTERNAL` (única combinación con failover
    automático), el paquete **`mssql-server-ha`** —con agente HA v2 a partir de **SQL Server 2025
    CU 3**— y los recursos de AG y de IP.
  - **`CLUSTER_TYPE = NONE`** (AG sin clúster): **solo failover manual**, pensado para *read-scale*
    y actualizaciones rodadas. **No es alta disponibilidad**: no venderlo como tal.
  - **Un AG o FCI no puede abarcar WSFC y Pacemaker.** Para escenarios mixtos, solo hay dos vías,
    ambas basadas en AG: `CLUSTER_TYPE = NONE` o un **AG distribuido**.
- **Ensayo obligatorio**: el failover se prueba con la aplicación dentro del ejercicio (reconexión,
  pool, DNS, `MultiSubnetFailover`), con la cadencia de `bcdr-standards`. Un AG que nunca ha
  conmutado es un supuesto.
- **Prohibido**: *database mirroring* en diseños nuevos (**deprecado**), y presentar un AG como
  sustituto del respaldo — un `DELETE` se replica en milisegundos.

## 6. SQL Server en Linux y en contenedores

Es un despliegue de primera clase, **con recortes conocidos**. No soportado en Linux (verificado en
la documentación de 2025): **merge replication**, **FILESTREAM y FileTable**, **procedimientos
extendidos del sistema (`xp_cmdshell`)**, **servidores vinculados a orígenes que no sean SQL
Server** (usar PolyBase), **ensamblados CLR `EXTERNAL_ACCESS`/`UNSAFE`**, **Buffer Pool Extension**,
**database mirroring**, **Always Encrypted con enclaves seguros**, **EKM** (salvo con Azure Key
Vault desde 2022 CU 12), **autenticación integrada de Windows para servidores vinculados y para
endpoints de AG** (los endpoints usan autenticación por certificado), **Analysis Services**,
**Reporting Services**, varios subsistemas del Agent (CmdExec, PowerShell, SSIS, SSAS, SSRS),
**alertas del Agent** y *Managed Backup*. Además: **una sola instancia por host** (no hay SQL
Browser ni instancias con nombre) y **los despliegues en Linux no son FIPS compliant**. A partir de
SQL Server 2025, **SLES deja de estar soportado**.

Contenedores: imagen oficial `mssql/server`. Criterios:
- Fijar la imagen **por digest**, `MSSQL_PID` explícito, contraseña `sa` desde el gestor de
  secretos (jamás en el `Dockerfile`, el `compose` ni la línea de comandos), y **volúmenes
  persistentes** para datos, log y backups — un contenedor de base de datos sin volumen es una
  pérdida de datos programada.
- **cgroup v2** honrado desde 2025 (y 2022 CU 20). Con límite de CPU por cgroup v2, el motor sigue
  informando de las CPU del host: alinear con `ALTER SERVER CONFIGURATION SET PROCESS AFFINITY` y
  el *trace flag* 8002 para que las decisiones de paralelismo no se tomen sobre un recuento falso.
- Las funcionalidades que dependen del agente de **Azure Arc** (Entra ID, Purview, pago por uso,
  Defender) **no están soportadas en contenedores**.
- En Kubernetes, `kubernetes-standards` manda para el resto; la HA del contenedor por *statefulset*
  y reinicio **no es un AG**: es un reinicio, con su RTO.

## 7. Rendimiento

### 7.1 Método: estadísticas de espera y Query Store

- **Se diagnostica por esperas**, no por corazonadas: `sys.dm_os_wait_stats` (acumulado desde el
  arranque — **medir por delta entre dos instantes**, nunca el acumulado en bruto),
  `sys.dm_exec_requests`/`sys.dm_exec_session_wait_stats` para lo que ocurre ahora, y
  `sp_WhoIsActive` como herramienta de primera línea. Ignorar las esperas benignas de fondo antes
  de sacar conclusiones.
- **Query Store es la herramienta que cambió el diagnóstico** y está en **todas las ediciones**
  (activado por defecto en bases nuevas desde 2022): guarda consultas, planes y estadísticas de
  ejecución **con historia**, de modo que "ayer iba bien y hoy no" pasa de anécdota a evidencia.
  Criterio: **activado en toda base de producción**, con modo de captura y retención dimensionados
  (`AUTO` en general), y **vigilando que no se llene** —si el almacén pasa a `READ_ONLY` deja de
  capturar en silencio—. `sp_QuickieStore` para consultarlo sin escribir SQL a mano.
- **Regresión de plan**: identificar con Query Store la consulta con varios planes y forzar el bueno
  (`sys.sp_query_store_force_plan`) como **medida de contención temporal**, con fecha de revisión y
  causa investigada después. Un plan forzado que nadie revisa es deuda: el motor puede dejar de
  poder aplicarlo y nadie se entera. En Enterprise existe *automatic tuning* para corregir
  regresiones automáticamente — **con supervisión**, no como piloto automático.
- **Estadísticas**: `AUTO_CREATE_STATISTICS` y `AUTO_UPDATE_STATISTICS` activadas; actualización
  manual tras cargas masivas y en tablas grandes donde el umbral automático llega tarde.
  `AUTO_UPDATE_STATISTICS_ASYNC` con criterio. La causa nº1 de un plan malo es una estadística
  vieja, no el optimizador.
- **Sniffing de parámetros**: síntoma clásico (mismo procedimiento, rendimiento errático). Se ataca
  en este orden: estadísticas → reescritura de la consulta → `OPTIMIZE FOR`/`RECOMPILE` puntual →
  *Query Store hints* (preferibles a tocar el código) → separación de rutas de código.
  `WITH RECOMPILE` global es una tirita cara.

### 7.2 Índices

- **Un índice agrupado (*clustered*) por tabla, casi siempre**: la tabla *es* el índice agrupado.
  Clave **estrecha, creciente, única e inmutable** (un `int/bigint identity` o un `sequence`);
  **un GUID aleatorio como clave agrupada** fragmenta y ensancha todos los índices no agrupados
  (que la incluyen como puntero) — vetado salvo justificación medida. Un *heap* (tabla sin índice
  agrupado) es la excepción, no el default.
- **No agrupados**: por patrón de consulta real, con `INCLUDE` para lograr **cobertura** medida, y
  **filtrados** para subconjuntos calientes. Cada índice se justifica con un plan; cada índice
  cuesta en cada `INSERT`/`UPDATE`/`DELETE` y en cada backup.
- **Retirada**: `sys.dm_db_index_usage_stats` para detectar índices sin lecturas y con escrituras.
  Antes de borrar, **deshabilitar** y observar. Cuidado: las estadísticas de uso se reinician con la
  instancia — no decidir sobre una ventana corta.
- **Índices que faltan**: los DMV de *missing indexes* son una **pista**, no una orden. Aplicar sus
  sugerencias en bloque es una de las peores prácticas frecuentes: solapan, duplican y engordan la
  tabla. Consolidar a mano (`sp_BlitzIndex` ayuda).
- **Fragmentación y el mito del mantenimiento por rutina**: reorganizar o reconstruir índices cada
  noche **por costumbre** es, en almacenamiento moderno (SSD/NVMe/cabina con caché), casi siempre
  trabajo inútil que genera **toneladas de log** (y por tanto backups de log enormes, tráfico de AG
  y presión de E/S) para una mejora marginal. Criterio:
  - Lo que casi siempre importa es **la actualización de estadísticas**, no la desfragmentación.
  - Reconstruir con umbrales altos y solo en índices grandes y realmente fragmentados;
    **`ONLINE = ON` es Enterprise** — en Standard, una reconstrucción **bloquea**: planificarla en
    ventana o no hacerla.
  - Vigilar el `FILLFACTOR` global: bajarlo "para reducir fragmentación" desperdicia memoria y E/S
    en todas las lecturas.

### 7.3 Bloqueo, aislamiento y **por qué RCSI suele ser la respuesta**

- El default de SQL Server es `READ COMMITTED` **con bloqueos**: los lectores bloquean a escritores
  y viceversa. De ahí nace la mayor parte del bloqueo que se atribuye a "la base va lenta", y de ahí
  nace el antipatrón `WITH (NOLOCK)`, que **no es una optimización: es leer datos sucios**, con
  lecturas duplicadas o ausentes y, en casos reales, errores 601. **Prohibido como práctica general.**
- **`READ_COMMITTED_SNAPSHOT ON` (RCSI)** cambia el nivel por defecto de la base a versionado de
  filas: **los lectores dejan de bloquear a los escritores** sin cambiar una línea de código de
  aplicación. Es, en la práctica, la respuesta correcta para la inmensa mayoría de cargas OLTP —
  el comportamiento al que ya está acostumbrado quien viene de PostgreSQL u Oracle. **Su coste,
  declarado**: versionado de filas en `tempdb` (dimensionarla), 14 bytes extra por fila versionada,
  y un cambio semántico real —desaparecen ciertos bloqueos que hoy serializan de forma accidental,
  así que hay lógica de aplicación que confiaba en ellos sin saberlo. Por eso: **se activa con
  pruebas**, no en caliente un viernes, y requiere acceso exclusivo momentáneo a la base.
- `ALLOW_SNAPSHOT_ISOLATION` (aislamiento *snapshot* explícito) es distinto: transacción con vista
  consistente completa y **conflictos de actualización** que la aplicación debe reintentar. Se usa
  donde se necesita, no por defecto.
- **Interbloqueos (*deadlocks*)**: se **capturan**, no se adivinan — la sesión de eventos extendidos
  `system_health` los registra por defecto; leer el **grafo de interbloqueo** para saber qué
  recursos y en qué orden. Solución por orden de preferencia: **orden de acceso consistente** →
  índices que reduzcan el alcance del bloqueo → transacciones más cortas → nivel de aislamiento →
  **reintento con backoff en la aplicación** (siempre, como red: un interbloqueo es un error
  recuperable, no un fallo de la petición del usuario).
- **Transacciones cortas y sin interacción externa dentro**: nada de llamadas HTTP ni de esperas de
  usuario con una transacción abierta. Fijar `LOCK_TIMEOUT` y timeouts de comando en la aplicación.
- **`Optimized locking`** (2022+, y en Standard en 2025) reduce la escalada y el número de bloqueos:
  evaluarlo, con la misma disciplina de medición antes/después.

### 7.4 T-SQL: antipatrones que matan planes

- **Predicados no *SARGable***: función sobre la columna (`WHERE YEAR(fecha)=2026`,
  `WHERE UPPER(col)=…`), cálculo sobre la columna, `LIKE '%algo'`. Reescribir a rangos.
- **Conversión implícita de tipos** (`nvarchar` contra `varchar`, texto contra número): invalida el
  índice de forma silenciosa. Es el bug de rendimiento más caro y más fácil de arreglar.
- **Funciones escalares definidas por el usuario** en `SELECT`/`WHERE`: históricamente ejecución fila
  a fila. Existe *scalar UDF inlining* (todas las ediciones), pero no cubre todos los casos:
  preferir funciones en línea con tabla (`iTVF`) o expresiones.
- **Cursores y bucles `WHILE`** donde cabía una operación de conjunto.
- **`SELECT *`** en interfaces y vistas; **vistas anidadas sobre vistas** (el optimizador acaba
  con planes imposibles de razonar).
- **`sp_executesql` con literales concatenados**: recompilación masiva **e inyección SQL**.
  Parámetros siempre. Es un veto de seguridad además de rendimiento.
- `MERGE`: usar con cautela (histórico largo de errores y de bloqueo). `INSERT`/`UPDATE`
  explícitos con `ON CONFLICT` lógico suelen ser más predecibles.
- **Triggers** con efectos laterales no evidentes y sin manejo de conjuntos (`inserted`/`deleted`
  tienen **varias filas**): fuente crónica de corrupción lógica.
- Tratar `NULL`, `ANSI_NULLS` y `SET` options con conciencia: cambian los planes y afectan a índices
  filtrados e indexados.

## 8. Mantenimiento: lo que toda instancia necesita

Cuatro trabajos, ni uno menos, todos con **alerta cuando fallan** (un job de mantenimiento que
falla en silencio es peor que no tenerlo):

1. **Integridad**: `DBCC CHECKDB` con `DATA_PURITY`, con cadencia semanal como mínimo en bases que
   importan. **Es el único control que detecta corrupción**; sin él, la corrupción se descubre el
   día que se restaura. En Enterprise hay comprobación paralela; en bases grandes, repartir por
   tablas/filegroups o ejecutarlo sobre una copia restaurada —lo cual, de paso, **prueba el
   restore**: dos controles por el precio de uno.
2. **Estadísticas** (prioritario) e **índices** (con umbrales altos, §7.2).
3. **Backups** completos/diferenciales/log según el modelo de recuperación (§4).
4. **Purga de historial**: `msdb` (historial de backups y de jobs), Query Store, sesiones de eventos
   extendidos, ficheros de backup antiguos. Un `msdb` sin purgar degrada el propio Agent.

**Soluciones comunitarias de referencia — estado verificado en agosto de 2026**:
- **Ola Hallengren, *SQL Server Maintenance Solution*** (`MaintenanceSolution.sql`,
  `DatabaseBackup`, `DatabaseIntegrityCheck`, `IndexOptimize`): **viva y actualizada**, con soporte
  declarado para SQL Server 2017, 2019, 2022 y **2025** más Azure SQL MI. **Es el default**: no se
  escriben scripts propios de backup y mantenimiento salvo razón documentada. Se distribuye por
  versiones fechadas, no por semver: descargar la última de `ola.hallengren.com`.
- **dbatools** (PowerShell, >500 comandos): **viva** — 2.8.2 publicada en la PowerShell Gallery en
  mayo de 2026, con actividad continua en `dataplat/dbatools`. Es la vía correcta para automatizar
  (`Install-DbaMaintenanceSolution`, migraciones, inventario) frente a GUI y scripts a mano.
- **First Responder Kit** (`sp_Blitz`, `sp_BlitzIndex`, `sp_BlitzCache`, `sp_BlitzFirst`): **viva**,
  con release *"The First Responder Kit 2026"* (2026-07-08) y modelo de versiones anuales. Avisos
  reales del propio autor: desde abril de 2026 **solo soporta SQL Server 2016 SP2 y posteriores**,
  `sp_Blitz` **exige `sp_ineachdb`**, varios scripts quedaron deprecados (`sp_BlitzQueryStore` →
  `sp_QuickieStore`), y hubo una release marcada por el autor como poco fiable por contener mucho
  código editado con IA. **Probar antes de desplegar**, especialmente con collation sensible a
  mayúsculas.
- **`sp_WhoIsActive`** (Adam Machanic) para diagnóstico en vivo.
- Regla transversal: **cualquier script de terceros que se instale en una instancia de producción se
  revisa línea a línea** — se ejecuta con privilegios altos dentro del motor.

## 9. Seguridad

- **Autenticación**: modo **integrado (Windows/Kerberos) por defecto**; autenticación SQL solo
  cuando no hay alternativa (Linux, contenedores, terceros), con contraseñas desde el gestor de
  secretos. **Todo lo relativo a Kerberos, SPN, delegación, cuentas de servicio gestionadas
  (gMSA/dMSA), GPO y Tier 0 se delega íntegramente en `windows-server-ad-standards`** — aquí solo
  se declara qué exige el motor: cuenta de servicio dedicada y sin privilegios de dominio, **SPN
  correcto** (sin él la conexión cae a NTLM en silencio y se pierden Kerberos y la delegación),
  y ninguna cuenta administrativa de dominio ejecutando el servicio.
- **`sa`**: deshabilitada y renombrada; **nunca** como cuenta de aplicación. Ningún inicio de sesión
  de aplicación en `sysadmin` ni en `db_owner`: permisos mínimos por esquema, idealmente vía
  procedimientos o roles de base de datos definidos.
- **Roles**: usar roles de servidor y de base de datos (incluidos roles de servidor definidos por el
  usuario) en vez de conceder a principales individuales. Revisar periódicamente `sysadmin`,
  `securityadmin`, `CONTROL SERVER` y la pertenencia a `db_owner` — es la revisión de accesos que
  nadie hace hasta la auditoría.
- **Superficie**: `xp_cmdshell` **deshabilitado** (y ausente en Linux); *CLR* deshabilitado salvo
  necesidad y nunca `UNSAFE`; *Ad Hoc Distributed Queries* deshabilitado; **SQL Browser** apagado
  donde no haga falta; **el puerto 1433 nunca expuesto a Internet ni a la red de usuarios**
  (`firewall-policy-standards`), y **cifrado en tránsito obligatorio** (`Encrypt=True` con
  validación de certificado en la cadena de conexión — un `TrustServerCertificate=True` en
  producción anula la protección).
- **Servidores vinculados**: puentes de confianza permanentes. Inventariados, con la cuenta de menor
  privilegio y revisados; jamás mapeando a una cuenta administrativa.
- **Cifrado en reposo**: **TDE está disponible en Standard y Enterprise** (no en Express) — el mito
  de "TDE es solo Enterprise" está desfasado y ha justificado compras innecesarias. TDE protege
  ficheros y backups **en reposo**, no de un usuario con permisos. **El certificado/DEK se respalda
  y se custodia fuera del servidor**: perderlo es perder los datos (§4). Para dato sensible a nivel
  de columna, **Always Encrypted** (también en Standard, incluso con enclaves seguros en Windows),
  con la clave fuera del motor — es la única protección frente al propio DBA. Las claves y su ciclo
  de vida, en `cryptography-pki-standards`/`secrets-management-standards`.
- **Auditoría**: *SQL Server Audit* (auditoría de servidor y de base de datos, disponible en todas
  las ediciones en 2025) sobre lo que importa —cambios de permisos, accesos a datos clasificados,
  uso de cuentas privilegiadas—, con salida hacia el SIEM. No auditarlo todo: nadie lo lee y cuesta.
- **Parcheo**: SQL Server se sirve por **Cumulative Update** (desde 2017 no hay Service Packs).
  Aplicar CU con cadencia, en ventana, con rollback previsto; los boletines de seguridad llegan
  por Patch Tuesday. En 2026 se han publicado vulnerabilidades relevantes del motor —entre ellas
  RCE críticas por deserialización que alcanzan desde SQL Server 2016 SP3 hasta 2025, y elevación
  de privilegios a `sysadmin`— lo que refuerza dos cosas: **parchear** y **no dar privilegios que
  conviertan una elevación en un desastre**. El triaje y la ventana los fija
  `vulnerability-management-standards`.

## 10. Versiones y soporte — verificado en fuente primaria

Datos tomados de las páginas de ciclo de vida de learn.microsoft.com (agosto 2026). **Es el dato
que más envejece: re-verificar siempre.**

| Versión | Inicio | Fin de soporte estándar (*mainstream*) | Fin de soporte extendido |
|---|---|---|---|
| SQL Server 2016 | 2016-06-01 | 2021-07-13 | **2026-07-14 — ya vencido** |
| SQL Server 2017 | 2017-09-29 | 2022-10-11 | **2027-10-12** |
| SQL Server 2019 | 2019-11-04 | 2025-02-28 | **2030-01-08** |
| SQL Server 2022 | 2022-11-16 | **2028-01-11** | 2033-01-11 |
| **SQL Server 2025** (17.x) | **2025-11-18** | **2031-01-06** | **2036-01-06** |

Lecturas obligadas de esa tabla:
- **SQL Server 2016 está fuera de soporte desde el 14 de julio de 2026.** Existen **Extended
  Security Updates** de pago: Año 1 (2026-07-15 → 2027-07-13), Año 2 (2027-07-14 → 2028-07-18),
  Año 3 (2028-07-19 → 2029-07-17). Un 2016 sin ESU en producción es un riesgo aceptado
  explícitamente o un incumplimiento — no hay tercera opción. Coincidencia que ilustra el punto:
  el mismo mes de su fin de soporte se publicó una RCE crítica que le afectaba.
- **2017 tiene poco más de un año de vida** (octubre de 2027): cualquier plan a 2027 debe incluirlo.
- **2019 está fuera de soporte estándar desde febrero de 2025**: recibe seguridad hasta 2030, pero
  **no correcciones funcionales**. No es el destino de una migración nueva.
- Destino recomendado hoy: **2022 o 2025**, según madurez de CU y compatibilidad de la aplicación.

**Actualizar**: `compatibility level` es una palanca **independiente** de la versión — se sube
**después** del upgrade, con Query Store activo para capturar la línea base y poder revertir un plan
regresivo. Es la red de seguridad que convierte un upgrade arriesgado en uno reversible.

## 11. Calidad y gates

Gates que bloquean la puesta en producción, en orden de coste creciente:

1. **Gate de edición y licencia (el primero)**: todo diseño declara la edición objetivo y qué
   funcionalidad exclusiva usa. Un diseño que use AG completos, indexado en línea o *automatic
   tuning* sobre Standard **no pasa**. Toda réplica no pasiva y toda VM adicional se declaran ante
   el gestor de licencias (§2.4).
2. **Configuración base verificada** como código: `max server memory`, `MAXDOP`,
   `cost threshold for parallelism`, ficheros de `tempdb` simétricos, autocrecimiento fijo, modelo
   de recuperación coherente con los backups programados, RCSI decidido conscientemente,
   Query Store activo. Comprobable con `dbatools` en CI/inventario.
3. **Migraciones de esquema versionadas** en repositorio y aplicadas solo por pipeline (criterio de
   `data-platform-standards`); DDL manual en producción **prohibido**.
4. **Revisión de T-SQL** contra los antipatrones de §7.4; consultas parametrizadas obligatorias.
5. **Pruebas con volumen representativo** y comparación de planes antes/después; validar
   compatibilidad N-1 durante despliegues rodados.
6. **`DBCC CHECKDB` en verde** como condición de salud de la instancia; su fallo es un incidente.
7. **Restore de prueba superado** dentro de la cadencia acordada (§4).
8. **Failover ensayado** (AG o FCI) con la aplicación dentro (§5).
9. **CU aplicada** dentro de la ventana de `vulnerability-management-standards`.

## 12. Operabilidad y SLI

- **SLI mínimos con alerta accionable y runbook** (la plataforma es de `observability-standards`):
  - Disponibilidad de instancia **y de base** (una base `SUSPECT` o `RECOVERY_PENDING` con el
    servicio arriba no la detecta un check de puerto).
  - Espacio: datos, **log de transacciones** con `log_reuse_wait_desc`, `tempdb`, y disco de
    backups.
  - Backups: éxito y duración del completo/diferencial/log, **antigüedad del último backup de log**
    (es el RPO real), y **edad del último restore validado** como SLI de primera clase.
  - AG: estado de sincronización, **send/redo queue** y *redo lag* por réplica, estado del listener,
    salud del WSFC (o del recurso de Pacemaker en Linux).
  - Rendimiento: esperas dominantes por delta, bloqueo (sesiones bloqueadas y duración), deadlocks
    por hora, expectativa de vida de página, uso de CPU y de `tempdb`.
  - Mantenimiento: última ejecución correcta de `CHECKDB`, de estadísticas y de la purga.
  - Errores: log de errores del motor filtrado por severidad (≥16, y **823/824/825** de E/S — el
    825 es la advertencia temprana de un disco que empieza a fallar y casi nadie la vigila).
- **Capacidad**: crecimiento de datos y log, IOPS y latencia de escritura del log, conexiones,
  proyectados con datos y revisados trimestralmente. Añadir núcleos es **una compra** (§2.3): el
  dimensionamiento es también FinOps.
- **Configuración como código**: parámetros de instancia, jobs del Agent, alertas, sesiones de
  eventos extendidos e inicios de sesión, versionados y con detección de *drift* (`iac-standards`,
  `dbatools`). Cero cambios manuales en producción.

## 13. Sostenibilidad y prohibiciones

- Revisión **semestral**: versión y fechas de soporte, CU aplicadas, edición vs funcionalidad
  realmente usada, réplicas y VMs frente a licencias, índices muertos, jobs que fallan en silencio,
  bases sin dueño.
- **ADR obligatorio** para: edición y modelo de licencia, topología de HA (AG vs FCI vs ninguna),
  modelo de recuperación por base, activación de RCSI, contratación de Software Assurance como
  requisito de la arquitectura de HA, y adopción de servicios gestionados en nube.
- Retirar es parte del trabajo: instancias y bases que nadie usa siguen costando licencia, backup y
  superficie de ataque.

### Lista de prohibiciones

- ❌ **Diseñar sobre funcionalidad de Enterprise sin confirmar la edición** (AG completos, réplica
  legible, indexado en línea, restauración de página, IQP avanzado).
- ❌ **Asumir que la réplica pasiva es gratis**: sin Software Assurance, se licencia (§2.4). Y un
  secundario legible **no es pasivo**.
- ❌ Fijar **precios, límites de edición o derechos de licencia de memoria**. Si no está verificado
  contra la documentación de Microsoft o el contrato: hueco declarado y consulta al gestor de
  licencias.
- ❌ **Edición Developer o Evaluation en producción.**
- ❌ Producción sobre **SQL Server 2016 sin ESU** (fuera de soporte desde 2026-07-14) o sobre
  cualquier versión vencida sin riesgo aceptado por escrito.
- ❌ Base en **FULL sin backups de log programados**; `DBCC SHRINKFILE` del log como rutina; pasar a
  SIMPLE para "limpiar" el log.
- ❌ Backup ad-hoc **sin `COPY_ONLY`** (rompe la cadena de diferenciales) o con otra herramienta que
  interfiera con la cadena de log.
- ❌ Dar por bueno un backup por `RESTORE VERIFYONLY`: **sin restore probado no existe**.
- ❌ Certificado de TDE o de cifrado de backup custodiado en el mismo servidor o en el mismo
  repositorio que respalda.
- ❌ **`WITH (NOLOCK)` como práctica general** (lecturas sucias, duplicadas o ausentes). Si el
  problema es bloqueo, la respuesta es **RCSI**, índices y transacciones cortas.
- ❌ **Un solo fichero de `tempdb`** en un servidor multinúcleo, o ficheros de tamaños desiguales.
- ❌ `max server memory` por defecto, `MAXDOP` sin fijar, `cost threshold for parallelism` en 5.
- ❌ Autocrecimiento en porcentaje, o ficheros que crecen en caliente como estrategia de capacidad.
- ❌ Aplicar en bloque las sugerencias de índices faltantes de los DMV.
- ❌ Reconstruir todos los índices cada noche por rutina (log, E/S y tráfico de AG a cambio de nada),
  y reconstruir sin `ONLINE` en Standard fuera de ventana.
- ❌ Instancia sin `DBCC CHECKDB` periódico.
- ❌ SQL dinámico concatenado (`EXEC`/`sp_executesql` con literales): rendimiento **e** inyección.
- ❌ `xp_cmdshell` habilitado, CLR `UNSAFE`, `sa` activa o cuenta de aplicación en `sysadmin`.
- ❌ Puerto 1433 accesible desde Internet o desde la red de usuarios; `TrustServerCertificate=True`
  en producción.
- ❌ *Database mirroring* en un diseño nuevo (deprecado).
- ❌ Presentar `CLUSTER_TYPE = NONE` como alta disponibilidad (solo failover manual).
- ❌ Intentar un AG o FCI que abarque WSFC y Pacemaker.
- ❌ Duplicar aquí criterio de Active Directory: **eso es de `windows-server-ad-standards`**.
- ❌ Instalar scripts de terceros en producción sin revisarlos línea a línea.
- ❌ Contenedor de SQL Server sin volumen persistente, o con la contraseña `sa` en el manifiesto.

## 14. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un entregable:

1. **Fechas de soporte**: `learn.microsoft.com/lifecycle/products/sql-server-<año>` para cada
   versión viva, y el estado de los **ESU de SQL Server 2016**.
2. **Límites y funcionalidades por edición**: *Editions and supported features* **de la versión
   exacta** (los límites cambiaron en 2025: 32 núcleos y 256 GB en Standard). Comprobar si algo más
   se ha movido de Enterprise a Standard desde entonces.
3. **Licenciamiento**: guía de licenciamiento de SQL Server y **Product Terms** vigentes —
   modelo por núcleo vs Servidor+CAL, virtualización y **derechos de conmutación por error con
   Software Assurance**. Cualquier decisión con coste, al gestor de licencias.
4. **Versión y CU actual** (`Latest updates and version history for SQL Server`) y **CVE del último
   trimestre**; triaje según `vulnerability-management-standards`.
5. **SQL Server en Linux y contenedores**: lista de funcionalidades no soportadas y distribuciones
   admitidas (**SLES dejó de estarlo en 2025**); estado del agente HA de Pacemaker
   (`mssql-server-ha`).
6. **Herramientas comunitarias**: última versión y actividad de **Ola Hallengren
   `MaintenanceSolution.sql`**, **dbatools** y **First Responder Kit** —incluida su versión mínima
   de SQL Server soportada— antes de instalarlas.

### Huecos y discrepancias declarados (agosto 2026)

- **Precios**: **ninguno** en este documento, deliberadamente. No hay cifra verificada y **no se
  aproxima ninguna**.
- **Redacción exacta de los derechos de failover con Software Assurance**: descrita aquí en términos
  generales a partir de fuentes de licenciamiento; **no verificada contra los Product Terms
  originales**. Antes de decidir sobre réplicas pasivas, leerlos.
- **Umbral de rentabilidad Servidor+CAL vs por núcleo**: depende del acuerdo. **No se fija número.**
- **Discrepancia en la propia documentación de Microsoft**, detectada en esta verificación y **no
  resuelta**:
  - *Máximo tamaño de base relacional en Express*: la página de ediciones de **Windows** dice
    **50 GB**; la de **Linux** de la misma versión dice **10 GB**. Verificar contra la página de la
    plataforma concreta antes de dimensionar cualquier cosa sobre Express.
  - *Réplicas secundarias síncronas en Enterprise*: la página de **Windows** indica hasta 8
    secundarias **incluyendo 5 síncronas**; la de **Linux**, hasta 8 **incluyendo 2 síncronas**.
    Confirmar para la plataforma de destino.
- **Cadencia y contenido de las CU de SQL Server 2025** posteriores a CU 3: no verificados en
  detalle.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
