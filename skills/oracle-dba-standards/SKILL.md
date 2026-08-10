---
name: oracle-dba-standards
description: Use when operating Oracle Database — sqlplus, RMAN, dgmgrl and Data Guard, srvctl/crsctl/asmcmd and ASM disk groups, lsnrctl with listener.ora/tnsnames.ora/sqlnet.ora, CDB/PDB multitenant and MAX_PDBS, Real Application Clusters, AWR/ASH/ADDM and awrrpt.sql, v$session/v$active_session_history wait events, SQL plan baselines and DBMS_SPM, DBMS_STATS, Flashback Database, unified auditing, TDE wallets and Advanced Security, DBA_FEATURE_USAGE_STATISTICS and CONTROL_MANAGEMENT_PACK_ACCESS as audit exposure, processor core factor and Named User Plus metrics, Standard Edition 2 socket and thread caps, Oracle AI Database 26ai / 23ai / 19c upgrades and Release Updates, quarterly Critical Patch Updates, or ora2pg / orafce / oracle_fdw migration off Oracle to PostgreSQL.
---

# Estándares de administración de Oracle Database

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Tesis del documento**: en Oracle, **la licencia es la primera decisión de arquitectura, no una
> nota al pie**. Casi ninguna otra plataforma tiene la propiedad de que *ejecutar una consulta*
> —un `SELECT` sobre una vista de rendimiento— cree una deuda económica retroactiva. Aquí sí.
> Todo lo que sigue se ordena por esa asimetría: primero qué te puedes permitir usar, después
> cómo usarlo bien.
>
> **Segunda tesis, incómoda**: la mayoría de los Oracle que se encuentran en producción están
> **sobredimensionados y sobrelicenciados** — Enterprise Edition con opciones caras compradas y
> sin usar, o peor, usadas sin comprar. El trabajo honesto empieza por medir qué se usa de verdad.

## 1. Alcance y triggers

Aplica a diseñar, licenciar, operar, diagnosticar y **salir de** Oracle Database: modelo de
licenciamiento y su impacto en el diseño, arquitectura multitenant e instancia/almacenamiento,
RAC, Data Guard, respaldo con RMAN y Flashback, diagnóstico de rendimiento por modelo de espera,
PL/SQL con criterio, actualizaciones y parcheo trimestral, seguridad del motor y del *listener*,
y la conversación de migración a PostgreSQL.

Disparadores: `sqlplus`, `rman`, `dgmgrl`, `srvctl`, `crsctl`, `asmcmd`, `lsnrctl`, `adrci`,
`expdp`/`impdp`, `sqlldr`, `orapwd`, `dbca`, `AutoUpgrade`/`autoupgrade.jar`, `opatch`/`opatchauto`,
`listener.ora`, `tnsnames.ora`, `sqlnet.ora`, `init.ora`/`spfile`, `ORACLE_HOME`, `ORACLE_SID`,
`CDB`/`PDB`, `PDB$SEED`, `MAX_PDBS`, `ALTER PLUGGABLE DATABASE`, `ASM`, `+DATA`/`+FRA`,
`TABLESPACE`, `AWR`, `ASH`, `ADDM`, `awrrpt.sql`, `v$session`, `v$session_wait`,
`v$active_session_history`, `v$sql`, `DBMS_XPLAN`, `DBMS_SPM`, `DBMS_STATS`,
`CONTROL_MANAGEMENT_PACK_ACCESS`, `DBA_FEATURE_USAGE_STATISTICS`, `FLASHBACK DATABASE`,
`ORA-01555`, `ORA-00060`, `ORA-04031`, "core factor", "Named User Plus", "Standard Edition 2",
"Critical Patch Update", "Release Update", `ora2pg`, `orafce`, `oracle_fdw`.

**No aplica**: ver
- `data-platform-standards` (**skill madre**: PostgreSQL como default, modelado relacional,
  migraciones expand/contract, clasificación y retención del dato, principios de respaldo. Su
  principio rector —*un almacén por necesidad, no por moda*— sigue mandando: **esta skill no
  justifica elegir Oracle**, cubre operarlo bien cuando ya está ahí por decisión histórica,
  por requisito de un producto de terceros o por un contrato vivo).
- `sqlserver-dba-standards` (el otro motor propietario del catálogo; motores y proveedores
  distintos, mismo patrón: **el licenciamiento decide la arquitectura**. No compiten).
- `backup-recovery-standards` y `bcdr-standards` — **frontera crítica, regla de arbitraje
  espejada palabra por palabra desde `backup-recovery-standards` §1**:
  > **"¿cómo se hace la copia?" es de `backup-recovery`** (herramienta, repositorio, 3-2-1, GFS,
  > dedup, cifrado del repo, integridad, catálogo, procedimiento de restore); **"¿cuánto podemos
  > perder, en qué orden lo levantamos y quién lo decide?" es de `bcdr`**.
- `plsql-oracle-forms-standards`: **PL/SQL como lenguaje de programa** —paquetes,
  `BULK COLLECT`/`FORALL`, manejo de excepciones, SQL dinámico y sus *binds*, `AUTHID`, utPLSQL— y
  **Oracle Forms/Reports como capa de aplicación** son suyos; **aquí el motor**: parámetros,
  optimizador y estadísticas, RMAN y Data Guard, licenciamiento y el camino de salida hacia
  PostgreSQL. Dos avisos que ambas sostienen: **Oracle Forms NO está desoportado** —lo que aprieta
  es el calendario de la rama 12.2.x—, y **Reports sí está deprecado** aunque se siga empaquetando.
- `sql-standards` (**el lenguaje SQL**; regla de arbitraje espejada desde su §1: *si la pregunta
  cambia cómo se escribe la consulta o el DDL, es de `sql-standards`; si cambia qué motor se
  elige, cómo se dimensiona, respalda, replica o restaura, es de aquí*). Suyas son las
  peculiaridades de dialecto que **cambian el código** —`MERGE`, `CONNECT BY` frente a `WITH
  RECURSIVE`, el `DUAL` histórico, la equivalencia entre cadena vacía y `NULL`, el `ROWNUM`
  frente a `FETCH FIRST`— y el criterio de PL/SQL como **lenguaje**. De aquí, todo lo que decide
  la ejecución: optimizador, estadísticas, *hints*, planes fijados, AWR/ASH, particionado y
  licenciamiento de las opciones que una construcción SQL pueda activar sin querer
  (**comprobar siempre si la cláusula que se escribe factura**).

  Extensión propia de este documento: **lo específico del motor es de aquí** — RMAN (estrategia
  incremental, `VALIDATE`, catálogo de recuperación, FRA), Flashback, el PITR con `SCN`/`RESETLOGS`
  y Data Guard como mecanismo. **El repositorio donde aterrizan esas piezas, su inmutabilidad y
  la cadencia del restore de prueba son de `backup-recovery`**; **el RPO/RTO que justifica el modo
  de protección de Data Guard y el ejercicio de conmutación como parte del plan son de `bcdr`**.
- `ha-clustering-standards` (**Pacemaker/Corosync, quórum y fencing genérico son suyos**; aquí
  Oracle Clusterware/Grid Infrastructure y RAC, que traen su propio quórum y su propio fencing
  —*node eviction* por voting disk y network heartbeat— y **no se mezclan con Pacemaker**).
- `linux-storage-standards` y `zfs-standards` (multipath, LUNs, alineación, filesystem por debajo
  de ASM), `onprem-standards` (el hierro, energía, capacidad), `linux-hardening-standards`
  (bastionado del SO que hospeda `ORACLE_HOME`), `selinux-standards`.
- `proxmox-ve-standards` y `libvirt-kvm-standards` (**relevantes aquí por el licenciamiento**: la
  política de particionado de Oracle convierte una decisión de hipervisor en una decisión de
  coste — §2.4).
- `vulnerability-management-standards` (**el ciclo de CVE, triaje y ventana de parcheo es suyo**;
  aquí solo el calendario y la mecánica de Oracle: RU/CPU/CSPU, `opatch`).
- `cryptography-pki-standards` (algoritmos, TLS y ciclo de vida de las claves en que se apoya TDE
  y el *wallet*), `secrets-management-standards` (dónde vive la contraseña del wallet y de los
  usuarios de servicio), `identity-access-management-standards` (identidad corporativa),
  `grc-compliance-standards` y `privacy-engineering-standards` (marco normativo y datos personales).
- `aws-standards`/`azure-standards`/`gcp-standards` (RDS for Oracle, OCI, *Authorized Cloud
  Environments*: los servicios gestionados y su facturación; **el criterio de licencia BYOL es de
  aquí**).
- `streaming-cdc-standards` (**la captura es suya**: LogMiner, GoldenGate, Debezium; **el impacto
  en el motor es de aquí**: `supplemental logging`, retención de redo, coste en el LGWR).
- `jvm-spring-standards`/`python-standards`/`dotnet-standards` (driver, pool y ORM desde el código),
  `observability-standards` (la plataforma de métricas y alertas donde aterrizan estos SLI).
- `mysql-mariadb-dba-standards` (el tercer motor relacional del catálogo; open source, sin la
  variable de licencia que domina aquí), `timeseries-db-standards`, `message-brokers-standards`,
  `nosql-standards`, `search-engines-standards`, `caching-cdn-standards` (otros almacenes
  especializados).

## 2. Licenciamiento: la decisión dominante

> **Aviso de alcance, no negociable**: este documento fija **criterio técnico**, no asesoramiento
> contractual. Cualquier decisión con impacto económico se valida contra el **Licensing Information
> User Manual de la versión concreta**, el *ordering document* firmado y el **gestor de licencias
> de la organización** (o un asesor independiente). Los datos de abajo están verificados en
> agosto 2026 y **caducan sin aviso**: Oracle republica sus tablas sin notificación (§8).

### 2.1 Ediciones vigentes

| Edición | Estado agosto 2026 | Límite duro |
|---|---|---|
| **Enterprise Edition (EE)** | Única edición con GA on-prem de **Oracle AI Database 26ai** (Linux x86-64, anunciada 27-ene-2026) | Sin límite de sockets; todas las opciones **de pago aparte** |
| **Standard Edition 2 (SE2)** | Vigente en 19c; para 26ai **solo disponible sobre Oracle Database Appliance** en el momento de esta verificación (§8, hueco) | **Máx. 2 sockets ocupados** por servidor y **cap interno de 16 hilos de CPU**; sin opciones EE |
| **Free** (sucesora de Express Edition/XE) | Vigente (`Oracle AI Database 26ai Free`) | **2 CPUs, 2 GB de RAM, 12 GB de datos de usuario**; **sin soporte y sin parches, tampoco de seguridad** |
| **21c** | *Innovation Release*: no es LTS y **no es elegible para Extended Support** | No usar como destino de una migración |

Consecuencias de diseño, no de compras:
- **SE2 no es "Oracle barato": es otro producto.** Sin particionado, sin compresión avanzada, sin
  TDE, sin Active Data Guard, sin packs de diagnóstico. Un diseño que asuma cualquiera de esas
  piezas y aterrice en SE2 no funciona; uno que las use en EE sin licenciarlas es deuda de auditoría.
- **El cap de 16 hilos de SE2 es del motor, no del contrato**: añadir hardware no da capacidad a
  una única base SE2. Dimensionar en consecuencia, no descubrirlo en producción.
- **Free no va a producción.** Cero parches de seguridad es incompatible con
  `vulnerability-management-standards`. Sirve para desarrollo, CI y pruebas de migración.

### 2.2 Métricas de licencia

- **Processor**: `cores físicos × core factor`, redondeando **hacia arriba**. El *core factor* de
  x86 (Intel/AMD) es **0.5** (verificar en la *Processor Core Factor Table* vigente: Oracle la
  republica sin aviso, y **la que aplica es la del día de la firma del ordering document** —
  archivar el PDF fechado junto al contrato). El *hyperthreading* no cuenta: se cuentan **cores
  físicos**.
- **Named User Plus (NUP)**: cuenta **personas y dispositivos**, con mínimos por procesador —
  **25 NUP por procesador en EE**, **10 por servidor en SE2**. El core factor **no reduce NUP**:
  solo fija el número de procesadores sobre el que se calcula el mínimo. NUP solo sale a cuenta
  con población de usuarios pequeña, cerrada y **demostrable**; una aplicación web pública es
  Processor por definición.
- **En *Authorized Cloud Environments* la tabla de core factor no aplica**: se cuenta por vCPU
  bajo la política de nube de Oracle. **No trasladar el 0.5 a un caso de negocio en nube.**
- La licencia de una **opción** debe usar la **misma métrica y el mismo conteo** que la base de
  datos que la ejecuta. No existe "licenciar el pack solo en la instancia que lo usa un martes".

### 2.3 Qué se licencia aparte (y la trampa de auditoría)

Verificado contra el *Licensing Information User Manual* de **Oracle AI Database 26ai**
(docs.oracle.com, tablas de disponibilidad por edición). En EE, la columna de notas dice
literalmente **"Extra cost option"** para:

| Componente | Nota del manual (26ai) | Riesgo real |
|---|---|---|
| **Partitioning** | EE: *extra cost option* | Se activa creando **una** tabla particionada. Un desarrollador puede facturarlo sin saberlo |
| **Advanced Compression** | EE: *extra cost option* | `COMPRESS FOR OLTP`, compresión de RMAN avanzada, Data Pump comprimido |
| **Advanced Security** (TDE de columnas y de tablespaces) | EE: *requires the Oracle Advanced Security option* | Cifrar en reposo con TDE en EE **es una compra**. Planificarlo antes de prometerlo en un diseño |
| **Diagnostics Pack** (AWR, ASH, ADDM) | EE: *extra cost option* | **La trampa clásica** — ver abajo |
| **Tuning Pack** (SQL Tuning Advisor, SQL Access Advisor, Real-Time SQL Monitoring) | EE: *extra cost option, also requires Oracle Diagnostics Pack* | Nunca se compra solo: arrastra Diagnostics |
| **Real Application Clusters** | EE: *extra cost option* | Ver §4 |
| **Active Data Guard** | EE: *extra cost option; license included with Oracle GoldenGate* | Data Guard **básico** sí está en EE; abrir la standby en lectura, no |
| **Database In-Memory** | EE: *extra cost option* | `INMEMORY` en una tabla es la activación |
| **Multitenant** | 3 PDB de usuario sin licencia; hasta **252 PDB** en EE con la opción | Ver §3.1 |

**La trampa clásica, explícita**: en Enterprise Edition el parámetro
`CONTROL_MANAGEMENT_PACK_ACCESS` viene **por defecto en `DIAGNOSTIC+TUNING`**. Consultar una vista
`DBA_HIST_*`, lanzar `awrrpt.sql`, mirar `v$active_session_history` o abrir la pestaña de
rendimiento de Enterprise Manager **usa el Diagnostics Pack** y genera exposición de auditoría
retroactiva, aunque nadie firmara nada. Regla de operación:

- Si **no** hay licencia de packs: `CONTROL_MANAGEMENT_PACK_ACCESS=NONE` **fijado en el spfile y
  verificado en CI/inventario**, y diagnóstico con Statspack o con las vistas `V$` que no
  pertenecen al pack. Prohibido "solo esta vez para depurar".
- Si **sí** la hay: documentado, con la misma métrica y conteo que la base.
- **Revisión periódica obligatoria** de `DBA_FEATURE_USAGE_STATISTICS` (y del histórico
  `DBA_FEATURE_USAGE_STATISTICS` por instancia) como control preventivo, **no** como reacción a
  una carta de auditoría. Es el mismo inventario que usará Oracle.

**Escepticismo obligatorio**: la revisión de uso corta en los dos sentidos. Si el inventario
demuestra que se paga Partitioning, In-Memory o Active Data Guard y **nadie los usa**, eso es un
hallazgo de FinOps que se reporta igual que un incumplimiento — con la advertencia de que
*desinstalar* una opción no siempre reduce la factura hasta la renovación del soporte.

### 2.4 Virtualización y particionado blando

Oracle clasifica las tecnologías en *hard partitioning*, *soft partitioning* y *Oracle Trusted
Partitions*. La frase que decide el coste, tal como aparece reproducida de forma consistente en la
literatura de licenciamiento a partir del documento **"Oracle Partitioning Policy"**
(`oracle.com/us/corporate/pricing/partitioning-070609.pdf`):

> "Unless explicitly stated elsewhere in this document, soft partitioning (including features/
> functionality of any technologies listed as examples above) is not permitted as a means to
> determine or limit the number of software licenses required for any given server"

**Hueco declarado (§8)**: oracle.com devolvió **HTTP 403** a la descarga automatizada de ese PDF en
esta verificación. La cita anterior procede de fuentes secundarias coincidentes y **debe
confirmarse abriendo el PDF a mano** antes de usarla para decidir nada. Además, el propio documento
se publica con etiqueta de carácter informativo y **no forma parte del contrato de licencia**: lo
que obliga es el *ordering document* firmado, no la política. Esa distinción es exactamente la que
discuten los asesores de licencias — **no la resuelve un DBA, y este documento no la resuelve**.

Criterio técnico que sí se fija aquí:
- **VMware, Hyper-V, KVM/Proxmox y contenedores se tratan por defecto como particionado blando**:
  presupuestar que hay que licenciar **todos los cores del host físico** —y, en clústeres con
  migración en vivo, de todos los hosts a los que la VM pueda moverse— hasta que el gestor de
  licencias diga lo contrario **por escrito**.
- Si Oracle debe convivir con un clúster virtualizado general, **aislar el hierro**: clúster
  dedicado, sin DRS ni migración hacia hosts no licenciados, y **evidencia conservada** (logs,
  configuración, capturas fechadas) de dónde ha corrido la instancia. Esa evidencia es la defensa
  de auditoría; se recoge de forma continua, no cuando llega la carta.
- Preferir **hierro dedicado y pequeño** a un clúster grande compartido: en Oracle, la
  consolidación que ahorra en el resto del catálogo **multiplica** la factura.
- La cláusula de "core factor no aplica en nube" (§2.2) convierte *lift-and-shift* a IaaS en un
  ejercicio de recálculo, no de traslado.

### 2.5 Nube

- **BYOL a IaaS de terceros (AWS/Azure/GCP)**: sigue siendo Oracle autogestionado. Las **opciones y
  packs se licencian igual**; lo único que cambia es el conteo (vCPU, política de *Authorized Cloud
  Environments*).
- **Servicios gestionados de Oracle (OCI Base Database, Exadata Database Service, Autonomous)**:
  incluyen opciones según el nivel contratado — el manual de licencias lo tabula por columnas
  (`BaseDB EE-HP`, `BaseDB EE-EP`, `ExaDB`). Ahí sí desaparece parte del riesgo de auditoría, a
  cambio de acoplamiento al proveedor: **decisión de ADR**.
- Ningún número de precio se fija en este documento. **Prohibido citar precios de memoria**: solo
  vale la lista de precios vigente de Oracle en el momento de la decisión.

## 3. Arquitectura

### 3.1 Multitenant (CDB/PDB) es el modelo, no una opción de diseño

- **La arquitectura no-CDB está desoportada**: 19c fue la última versión que la admitió; 21c en
  adelante —y por tanto 23ai y 26ai— **solo existen como CDB**. Un plan de actualización desde 19c
  no-CDB **incluye la conversión a PDB**, y la conversión **es irreversible** (ni Flashback Database
  la deshace): el rollback es "restaurar la copia previa", y hay que dimensionar la ventana en
  consecuencia.
- **3 PDB de usuario por CDB sin licencia de Multitenant** (`PDB$SEED` no cuenta). La cuarta es una
  compra. Nada impide técnicamente crearla en EE, así que **`MAX_PDBS` se fija como salvaguarda**
  en todo CDB sin la opción: es un control de licencia implementado como parámetro.
- Criterio de agrupación: un CDB por **entorno y ciclo de parcheo compartido**, no por conveniencia
  de nombres. Todo lo que comparte CDB comparte ventana de mantenimiento, versión y fallo de
  instancia — el aislamiento que da un PDB es lógico, no de disponibilidad.
- Local *undo*, `PDB$SEED` limpio y clonado por *refreshable clone* para provisionar entornos:
  es la mejor pieza del modelo y la más infrautilizada.

### 3.2 Instancia frente a base de datos

Distinción operativa, no académica: la **instancia** es memoria (SGA/PGA) y procesos; la **base de
datos** son los ficheros. RAC es *N* instancias sobre **una** base de datos; Data Guard es *N* bases
de datos distintas. Casi todo malentendido de HA en Oracle nace de confundir ambas:
**RAC protege de la caída de un nodo; no protege del borrado de un fichero ni de la pérdida del
sitio.** Eso es Data Guard y RMAN.

### 3.3 Tablespaces y organización

- Separar por **ciclo de vida y política**, no por capricho: datos, índices grandes, temporal, undo,
  y un tablespace por conjunto con retención o cifrado propios. `SYSTEM`/`SYSAUX` **nunca** alojan
  objetos de aplicación.
- **Bigfile tablespaces** por defecto sobre ASM para datos de aplicación (menos ficheros que
  gestionar); *smallfile* cuando haga falta granularidad de restauración.
- Gestión local de extents y **ASSM**; nada de gestión manual de segmentos en diseños nuevos.
- **Autoextend con `MAXSIZE` explícito**: un datafile sin techo convierte un bug de aplicación en un
  llenado de cabina.
- El particionado de tablas es **decisión de diseño con factura** (§2.3): si no hay licencia, se
  diseña sin él —vistas, tablas por rango gestionadas por la aplicación, purga por lotes— y se
  documenta la limitación. **Prohibido** particionar "porque es lo correcto" sin verificar licencia.

### 3.4 ASM frente a filesystem

- **ASM por defecto** en instalaciones on-prem con almacenamiento en bloque compartido o múltiple:
  *striping*, rebalanceo en caliente, `ASMLib`/`AFD` o `udev` para persistencia de nombres, y es el
  único camino razonable para RAC.
- **Redundancia**: `EXTERNAL` cuando la cabina ya replica y su fiabilidad está demostrada;
  `NORMAL`/`HIGH` cuando ASM es quien protege. Decidir con `linux-storage-standards`, no por
  costumbre.
- Grupos de discos mínimos y con propósito (`+DATA`, `+RECO`, `+GRID`); discos del mismo tamaño y
  rendimiento dentro de un grupo — el desequilibrio se paga en latencia.
- **Filesystem (xfs/ext4 sobre LVM) es aceptable** en instancias únicas, sin RAC, sobre
  almacenamiento fiable: menos piezas, menos operación (KISS). No se adopta ASM "por ser Oracle".
- ZFS o almacenamiento con *copy-on-write* bajo datafiles: ver `zfs-standards`; cuidar
  `recordsize`/alineación con el `db_block_size` o el rendimiento se desploma.

## 4. RAC: qué resuelve de verdad

- **RAC resuelve disponibilidad frente a la caída de una instancia o un nodo, y escala lecturas
  con esfuerzo. No da rendimiento lineal**: la caché global (*Cache Fusion*) tiene coste, y una
  carga con bloques calientes compartidos puede ir **más lenta** en RAC que en un nodo. Cualquier
  promesa de "el doble de nodos, el doble de TPS" es falsa por defecto.
- **Coste**: opción de pago (§2.3) **sobre todos los nodos**, Grid Infrastructure, almacenamiento
  compartido, interconexión dedicada y redundante, y un salto grande de complejidad operativa —
  precisamente lo que `ha-clustering-standards` advierte: *un clúster mal operado tiene peor
  disponibilidad que un servicio simple bien monitorizado*.
- **Alternativas más simples, en este orden**, antes de proponer RAC:
  1. Instancia única bien dimensionada + **Data Guard con failover rápido** (cubre nodo, sitio y
     corrupción; RTO de minutos).
  2. Instancia única sobre virtualización con reinicio automático en otro host (RTO de minutos,
     coste cercano a cero).
  3. **Oracle Restart** (Grid Infrastructure en un nodo) para reiniciar instancia y listener.
  4. RAC **solo** cuando el RTO exigido —derivado por `bcdr-standards`, no inventado— sea de
     segundos y esté presupuestado.
- Si hay RAC: servicios (`srvctl add service`) como unidad de conexión de la aplicación, con
  preferencias y *TAF*/*Application Continuity* configurados; conexión por **SCAN**, jamás por VIP
  de nodo en cadenas de conexión. Nodos idénticos en hardware y parcheo.
- **El quórum y el fencing de RAC son de Oracle Clusterware** (voting disks, network heartbeat,
  *node eviction*): **no se combina con Pacemaker/Corosync**. `ha-clustering-standards` describe la
  disciplina general de fencing; su implementación aquí es la de Oracle y solo la de Oracle.
- **Prohibido justificar RAC como sustituto de backup o de DR.** Un `DROP TABLE` se replica
  instantáneamente a todos los nodos.

## 5. Data Guard y continuidad

- **Física (redo apply) por defecto**: copia bloque a bloque, simple, cubre todo el contenido.
  **Lógica (SQL apply)** solo para casos concretos (versiones distintas, subconjunto de esquemas,
  actualización rodada) y asumiendo sus limitaciones de tipos de datos.
- **Modos de protección** — elegir desde el RPO derivado por `bcdr-standards`:

| Modo | RPO | Coste |
|---|---|---|
| `MAX PERFORMANCE` (asíncrono) | > 0, variable con el lag | Ninguno sobre la primaria |
| `MAX AVAILABILITY` (síncrono con degradación) | 0 mientras la standby responde | Latencia de commit; degrada a asíncrono ante fallo |
| `MAX PROTECTION` | 0 estricto | **Para la primaria** si no puede confirmar. Solo con ≥2 standby y con esa consecuencia aceptada por escrito |

- **Switchover ≠ failover**: *switchover* es planificado, reversible y sin pérdida — es la operación
  que se ensaya. *Failover* es la reacción a la pérdida de la primaria, potencialmente con pérdida
  de datos, y **deja la antigua primaria fuera del rol** hasta reinstanciarla (`FLASHBACK DATABASE`
  la recupera sin copia completa si estaba habilitado: razón principal para tenerlo activo).
- **Broker (`dgmgrl`) obligatorio** frente a la gestión manual de parámetros: menos superficie de
  error humano, `VALIDATE DATABASE` como comprobación previa, y observabilidad del *apply lag* y
  *transport lag* — ambos son **SLI de primera clase** con alerta.
- **El ensayo es obligatorio y calendarizado**: un *switchover* completo con la aplicación
  reconectando (no solo el motor) al menos con la cadencia que fije `bcdr-standards`. Un Data Guard
  que nunca ha conmutado es un supuesto, no un control.
- **Active Data Guard es opción de pago** (§2.3). Sin ella, la standby **no se abre en lectura**.
  Un diseño que planifique "descargar los informes a la réplica" está comprando, aunque no lo sepa.
  Snapshot Standby (abrir la standby en lectura-escritura para pruebas y luego revertirla) sí está
  en EE, y es la forma barata de probar sobre datos reales — con la clasificación del dato
  respetada (`privacy-engineering-standards`).

## 6. Respaldo: RMAN y Flashback

> **Invariante compartido con `backup-recovery-standards` y `bcdr-standards`, sin matices:**
> **un backup sin restore probado no existe.** Un `RMAN> backup` que terminó en verde no es prueba
> de nada.

- **RMAN es el mecanismo**, no una opción: respaldos consistentes en bloque, reconocimiento de
  corrupción, y `RESTORE`/`RECOVER` guiados por el catálogo. Los volcados `expdp` **no son un
  backup**: son movimiento lógico de datos, sin PITR ni recuperación de instancia.
- **Estrategia por defecto**: nivel 0 semanal + incrementales nivel 1 diarios con **block change
  tracking** activado (reduce drásticamente el escaneo), archivado de redo continuo, y `FRA`
  dimensionada con política de retención explícita (`CONFIGURE RETENTION POLICY`). Incrementales
  *merge* (imagen actualizada) cuando el RTO exige restaurar rápido y hay espacio.
- **Catálogo de recuperación** en base de datos separada cuando hay más de un puñado de instancias:
  el `controlfile` solo retiene metadatos limitados y **se pierde con el sitio**. El catálogo se
  respalda también.
- **Verificación como control de ingeniería**, no como confianza:
  - `RESTORE ... VALIDATE` y `BACKUP VALIDATE CHECK LOGICAL` con cadencia programada.
  - **Restore real periódico a un host distinto**, cronometrado, con `RECOVER` hasta un SCN y
    validación de datos por la aplicación. La cadencia y el registro del ejercicio los fija
    `backup-recovery-standards`; **el procedimiento Oracle es de aquí**.
  - `V$DATABASE_BLOCK_CORRUPTION` vigilada; `DB_BLOCK_CHECKSUM`/`DB_BLOCK_CHECKING` activos salvo
    coste medido que lo desaconseje.
- **Flashback es una red de seguridad distinta, no un backup**: `FLASHBACK QUERY`/`FLASHBACK TABLE`
  (dependen del *undo* y su retención) y `FLASHBACK DATABASE` (depende de los *flashback logs*) sólo
  cubren errores lógicos recientes dentro de su ventana y **desaparecen con el almacenamiento
  primario**. Se habilitan porque acortan el RTO del error humano y porque son requisito práctico
  para reinstanciar tras un failover — nunca como sustituto de la copia.
- **Recycle bin**: activo por defecto, no es un control de recuperación (un `PURGE` o presión de
  espacio lo vacía). No incluirlo en un runbook como red de seguridad.
- El destino de las copias, su cifrado, inmutabilidad y regla 3-2-1 son de `backup-recovery-standards`.
  Nota específica: **el cifrado de backups de RMAN por clave/wallet depende de Advanced Security**
  en algunos modos — verificar la licencia antes de prometer "backups cifrados por el motor";
  cifrar en el repositorio es la alternativa sin factura.

## 7. Rendimiento: el modelo de espera

- **Método, no adivinanza**: en Oracle se diagnostica por **eventos de espera** — dónde se va el
  tiempo de la sesión, no qué contador parece alto. La secuencia es siempre: *sesión → tiempo →
  evento de espera dominante → SQL responsable → plan → causa*. Cualquier propuesta de cambio de
  parámetro que no venga de esa cadena está prohibida.
- **Herramientas y su factura** (§2.3): AWR, ASH y ADDM **son Diagnostics Pack**. Sin licencia:
  `V$SESSION` (con `event`, `blocking_session`, `sql_id`), `V$SESSION_WAIT`, `V$SYSTEM_EVENT`,
  `V$SQL`, `DBMS_XPLAN`, SQL trace (`10046`) + `tkprof`, y **Statspack** como alternativa histórica
  soportada. Con licencia: ASH es la herramienta más rentable del producto — muestreo por segundo
  que responde "qué estaba pasando a las 03:14" sin reproducir el problema.
- **Clases de espera y su lectura** (guía de triaje, no receta): esperas de **E/S de usuario**
  (`db file sequential read`) suelen ser plan o índice, no disco lento; **concurrencia**
  (`buffer busy waits`, `enq: TX - row lock contention`) es diseño de datos o transacciones largas;
  **configuración** (`log file sync`) apunta a commits por operación o a latencia del redo;
  **CPU** alta con `library cache: mutex X` o cifras enormes de *hard parse* apunta al antipatrón
  de literales; en RAC, esperas `gc *` son el coste de Cache Fusion.
- **Planes y su estabilidad**:
  - Leer el plan **real** (`DBMS_XPLAN.DISPLAY_CURSOR` con `ALLSTATS LAST`), no el estimado.
  - **SQL Plan Baselines (`DBMS_SPM`)** como mecanismo de estabilidad por defecto para el SQL
    crítico: se acepta un plan bueno conocido y la evolución de planes nuevos pasa por
    verificación. Los *SQL Profiles* son producto del Tuning Pack (**factura**); las baselines, no.
  - **Hints en el código de aplicación: último recurso**, con comentario que explique por qué y
    fecha de revisión. Un hint es deuda que sobrevive al cambio de versión y de datos.
- **Estadísticas del optimizador**:
  - `DBMS_STATS` con la tarea automática **activa**; se interviene a mano cuando hay carga masiva,
    tabla volátil o histograma que engaña, no por rutina.
  - **Recoger justo después de cargas grandes** y antes de que la aplicación consulte; para tablas
    intermedias muy volátiles, considerar estadísticas fijadas o *dynamic sampling* deliberado.
  - **Prohibido borrar estadísticas o desactivar la recogida** como "solución" a un plan malo: eso
    no arregla el plan, elimina la información.
- **Antipatrones clásicos, vetados**:
  - **SQL sin variables ligadas** (literales concatenados): *hard parse* masivo, contención de
    library cache y, de paso, inyección SQL. Es el fallo nº1 de rendimiento en Oracle y el nº1 de
    seguridad a la vez. `CURSOR_SHARING=FORCE` es una **tirita** de emergencia, no una solución.
  - **Índices que nadie usa**: cuestan en cada DML. Revisión periódica con monitorización de uso y
    retirada (invisibles primero, `DROP` después) — la misma higiene que exige la skill madre.
  - Funciones sobre la columna en el `WHERE` (invalidan el índice salvo índice basado en función),
    tipos implícitamente convertidos (`VARCHAR2` vs `NUMBER`), y `SELECT *` en interfaces.
  - Bucles fila a fila desde la aplicación (*row-by-row*, "slow-by-slow") donde cabía una operación
    de conjunto.
  - Transacciones largas y `undo` insuficiente → `ORA-01555`. Se arregla acortando transacciones,
    no subiendo `UNDO_RETENTION` a ciegas.
- **Parámetros**: cambios uno a uno, con medición antes/después, en `spfile` versionado y con
  justificación escrita. Los parámetros ocultos (`_`) **solo** con Service Request de Oracle que los
  respalde. `MEMORY_TARGET`/`SGA_TARGET` gestionados, `hugepages` configuradas en Linux para SGA
  grandes (y `MEMORY_TARGET` es incompatible con hugepages: elegir conscientemente).

## 8. PL/SQL con criterio

- **Sí**: lógica que debe estar junto al dato por rendimiento (procesamiento masivo con `BULK
  COLLECT`/`FORALL`), integridad que no puede confiarse a un cliente, APIs de paquete que
  encapsulan acceso a tablas, y trabajos programados del propio motor.
- **No**: reglas de negocio completas enterradas en paquetes — **es lógica de negocio sin tests,
  sin revisión de código y sin portabilidad**, y es el principal ancla que convierte "migrar de
  Oracle" en un proyecto de años (§11). Si se escribe, se escribe **como código**: en el
  repositorio, versionado, con migraciones versionadas (mismo criterio que
  `data-platform-standards`), con `utPLSQL` u equivalente en CI, y compilado con
  `PLSQL_WARNINGS` tratados como errores en el build.
- **Prohibido**: DDL dinámico y `EXECUTE IMMEDIATE` con entrada concatenada (usar
  `DBMS_ASSERT` y bind variables); `AUTHID DEFINER` sin pensarlo en paquetes que reciben entrada
  externa; triggers que hacen efectos laterales no evidentes (los triggers en cascada son la
  causa de incidentes más difícil de diagnosticar del motor); `COMMIT` dentro de triggers
  (`PRAGMA AUTONOMOUS_TRANSACTION` solo para auditoría, con la pérdida de atomicidad asumida).

## 9. Versiones, parcheo y actualizaciones

Estado verificado a agosto de 2026 (**re-verificar en MOS Doc ID 742060.1**, que es la fuente
autoritativa y **requiere cuenta de soporte** — este documento no ha podido leerla, §12):

| Versión | Estado | Fechas (verificar) |
|---|---|---|
| **Oracle AI Database 26ai** | Release vigente. GA on-prem Linux x86-64 anunciada el **27-ene-2026** (EE). Numeración de RU: **23.26.1** (ene-2026), **23.26.2** (abr-2026), **23.26.3** (jul-2026) — confirmado en docs.oracle.com | Premier Support hasta **31-dic-2031** (fuente secundaria); Extended **TBD** |
| **23ai** | Misma línea de código; para quien ya estaba en 23ai en OCI o *engineered systems*, pasar a 26ai es un RU | Ver 26ai |
| **19c** | LTS de referencia del parque instalado | Premier hasta **31-dic-2029**; Extended hasta **31-dic-2032** |
| **21c** | *Innovation Release*, **sin Extended Support** | Premier hasta **31-jul-2027** (verificar) |

**La letra pequeña de 19c que cambia decisiones**: a partir del **1-mayo-2027** el soporte de 19c
**excluye** —según la política de soporte y su *statement of changes*— librerías BSAFE, Java y
productos relacionados, **TLS**, **Native Network Encryption**, **Transparent Data Encryption**,
`DBMS_CRYPTO`, utilidades C y Java, y cumplimiento **FIPS**. Consecuencia operativa directa:
**si el sistema depende de TDE, TCPS/TLS, cifrado nativo de red o validación FIPS, el horizonte real
de 19c es mayo de 2027, no 2029 ni 2032.** Verificar el alcance exacto en la fuente primaria antes
de construir un plan sobre ello (§12).

**Parcheo** — el calendario cambió en 2026 y es el dato que más se afirma de memoria mal:
- **Critical Patch Update (CPU)**: trimestral, **tercer martes de enero, abril, julio y octubre**.
  Último publicado: **21-jul-2026**. Próximos anunciados: **20-oct-2026**, **19-ene-2027**,
  **20-abr-2027**.
- **Critical Security Patch Update (CSPU)**: **novedad de 2026** — vía **mensual** intercalada, el
  tercer martes de **febrero, marzo, mayo, junio, agosto, septiembre, noviembre y diciembre**
  (el primero se publicó el **28-mayo-2026**). **No sustituye al CPU: lo complementa.**
- **Release Update (RU)** trimestral para funcionalidad y correcciones acumuladas: **ir siempre por
  RU, no por parches sueltos**; un *one-off* solo con SR abierto y con plan de reabsorción en el
  siguiente RU.
- El triaje, la ventana y el SLA de aplicación los fija `vulnerability-management-standards`. Aquí
  la regla mínima: **el retraso de parcheo se mide y se justifica por escrito**, no se acumula en
  silencio. Aplicar con `opatchauto` sobre `ORACLE_HOME` clonado y **rollback probado**.

**Ruta de actualización**:
1. Inventario previo obligatorio: edición, opciones **realmente en uso**
   (`DBA_FEATURE_USAGE_STATISTICS`), tamaño, no-CDB vs CDB, dependencias de aplicación y drivers.
2. **AutoUpgrade** (`autoupgrade.jar`) es la herramienta soportada; `analyze` y `fixups` antes de
   `deploy`. Nada de recetas manuales heredadas.
3. Desde 19c no-CDB: **conversión a PDB obligatoria** e irreversible (§3.1) — ensayo completo sobre
   copia con datos representativos y ventana de rollback = restaurar.
4. Estadísticas y planes: capturar baselines **antes** de actualizar; una regresión de plan tras el
   upgrade es el fallo más común y el más recuperable si hay baselines.
5. Nunca en producción sin haber ensayado el mismo camino en preproducción con volumen real.

## 10. Seguridad

- **Usuarios y roles**: cuentas de aplicación **sin** `DBA`, sin `SELECT ANY TABLE`, sin
  `CREATE ANY *`. Privilegios de sistema especialmente peligrosos, prohibidos fuera de
  administración justificada y auditada: `SYSDBA`/`SYSOPER`, `ALTER SYSTEM`, `CREATE ANY
  PROCEDURE`/`EXECUTE ANY PROCEDURE`, `GRANT ANY *`, `BECOME USER`, `CREATE DATABASE LINK`
  (un *database link* es un puente de confianza permanente entre sistemas: inventariado y revisado).
- **Cuentas por defecto**: bloqueadas y con contraseña expirada salvo las estrictamente necesarias.
  Contraseñas desde `secrets-management-standards`, nunca en `tnsnames.ora`, scripts ni jobs.
  `SEC_CASE_SENSITIVE_LOGON` y perfiles de contraseña activos.
- **Auditoría unificada** (`unified auditing`) por defecto en versiones actuales: políticas
  orientadas a lo que importa (uso de privilegios administrativos, cambios de estructura, accesos a
  tablas clasificadas), **no** "auditar todo" — eso llena SYSAUX y nadie lo lee. Los registros salen
  del host hacia el SIEM (ver `detection-engineering-standards` para su explotación). El
  `AUDIT_TRAIL` tradicional se considera legado.
- **Cifrado**: TLS/TCPS en el listener con certificados gestionados (`cryptography-pki-standards`).
  **TDE requiere Advanced Security en EE** (§2.3): si no está licenciado, el cifrado en reposo se
  resuelve **por debajo** (cifrado de volumen/cabina) y se documenta la diferencia de modelo de
  amenaza. El *wallet*/keystore **jamás** en el mismo backup que los datos, y su contraseña bajo el
  gestor de secretos — el mismo criterio de custodia de claves que exige `bcdr-standards`.
- **Superficie del listener**: en una interfaz interna, **nunca** expuesto a Internet ni a la red de
  usuarios; `ADMIN_RESTRICTIONS_<listener>=ON`; sin `EXTPROC` si no se usa; *valid node checking*
  (`TCP.VALIDNODE_CHECKING` en `sqlnet.ora`) o, mejor, filtrado en `firewall-policy-standards`; y
  **nunca** el puerto 1521 abierto "temporalmente" para una prueba. El listener sin contraseña no es
  un defecto de configuración: es el diseño moderno — la protección es de red y de SO.
- **Superficie del SO**: `ORACLE_HOME` y ficheros propiedad del usuario `oracle`, permisos
  restrictivos, `orapwd` protegido, `linux-hardening-standards` y `selinux-standards` para el resto.
- **Datos personales**: clasificación, retención y enmascaramiento en entornos no productivos son de
  `privacy-engineering-standards` y `data-platform-standards`. Nota de licencia: **Data Masking and
  Subsetting** y **Database Vault** son productos aparte — copiar producción a preproducción "y
  luego anonimizamos" no es aceptable con o sin ellos.

## 11. Salir de Oracle: la conversación real

No es una recomendación por defecto ni una migración gratuita. Es una decisión de ADR con coste
grande y beneficio grande, que se plantea **cuando el coste de licencia y la exposición de auditoría
superan el coste de reescribir** — no por preferencia tecnológica.

**Qué se rompe de verdad** (por orden de dolor real, no de volumen de código):
1. **PL/SQL de negocio**: paquetes grandes, transacciones autónomas, `COMMIT` dentro de rutinas
   (PostgreSQL no puede confirmar dentro de una función, y una `PROCEDURE` no controla transacción
   si la llaman dentro de un bloque). Es el 80 % del esfuerzo.
2. **Semántica que cambia en silencio**: Oracle trata la **cadena vacía como `NULL`**; PostgreSQL
   no. Es la fuente nº1 de bugs post-migración y **no la detecta ningún conversor**: exige auditar
   toda comparación con `NULL` y toda concatenación.
3. **`DATE` de Oracle incluye hora** → mapear a `timestamp`, nunca a `date`.
4. `ROWID` (`ctid` **no** es un sustituto: cambia con `VACUUM` — se añade clave primaria real),
   `ROWNUM`, `CONNECT BY`, jerárquicas, `MERGE`, secuencias con `NEXTVAL` fuera de estado replicado.
5. Tipos y funciones propietarias, *hints*, `DBMS_*`, jobs del *scheduler*, database links.

**Herramientas vigentes** (verificar versión y mantenimiento antes de adoptarlas, §12):
- **ora2pg** (GPLv3, rama 25.x): conversión de esquema, datos y PL/SQL, y —lo más valioso— su
  **informe de complejidad de migración**, que se ejecuta **primero**, antes de comprometer nada.
  Su salida **no va a producción sin revisión**: deja marcas `TODO`/`FIXME` por diseño.
- **orafce**: extensión que reimplementa funciones y paquetes de Oracle en PostgreSQL. Reduce
  trabajo; **no da compatibilidad completa** y sus propios autores lo dicen.
- **oracle_fdw**: puente para cutover incremental — mantener ambos motores mientras se trasladan
  servicios, en vez de un *big bang*.
- **IvorySQL** (modo de compatibilidad Oracle sobre PostgreSQL) como alternativa; **no mezclar modo
  Oracle y modo PostgreSQL en la misma base**.
- **AWS DMS Schema Conversion** (AWS recomienda ya la vía gestionada frente al cliente descargable
  **AWS SCT**), **pgloader**, **credativ-pg-migrator**.
- **Corrección explícita**: **Babelfish NO sirve para Oracle** — es la capa de compatibilidad con
  **SQL Server**. Confundirlo es un error que aparece con frecuencia en material de migración.

Criterio: migrar **por dominios**, empezando por lo periférico (reporting, aplicaciones internas de
bajo riesgo), con `data-platform-standards` fijando el destino y la disciplina de migraciones, y
`streaming-cdc-standards` si hace falta convivencia con captura de cambios. La migración de datos
sin la migración de la lógica es una trampa: se entrega un PostgreSQL con la mitad de las reglas.

## 12. Calidad y gates

Gates que **rompen el build o bloquean la puesta en producción**, en orden de coste creciente:

1. **Gate de licencia (el primero, siempre)**: ningún diseño, script de despliegue ni migración se
   aprueba sin declarar qué opciones y packs usa. Comprobación automatizable:
   `CONTROL_MANAGEMENT_PACK_ACCESS` conforme a lo contratado, `MAX_PDBS` fijado si no hay
   Multitenant, y **revisión programada de `DBA_FEATURE_USAGE_STATISTICS`** cuyo resultado se
   archiva con fecha. Un uso de opción no contratada es un **fallo de build**, no una observación.
2. **Lint y revisión de SQL/PL/SQL**: sin literales concatenados (bind variables obligatorias),
   sin `SELECT *` en interfaces, `PLSQL_WARNINGS` como error de compilación.
3. **Migraciones versionadas** en repositorio y aplicadas solo por pipeline (mismo criterio que
   `data-platform-standards`); DDL manual en producción **prohibido**.
4. **Tests de PL/SQL** (`utPLSQL` o equivalente) sobre camino feliz, bordes y errores, contra una
   base Oracle real de la misma versión mayor — nunca contra un motor "compatible".
5. **Pruebas de plan con volumen representativo**: un plan sobre 1 000 filas no predice 100 M.
   Capturar baselines del SQL crítico antes de cualquier upgrade o cambio de estadísticas.
6. **Restore de prueba superado** (§6) como gate periódico de la plataforma: si el último restore
   validado es más antiguo que la cadencia acordada, la plataforma está en incumplimiento.
7. **Switchover de Data Guard ensayado** con la cadencia de `bcdr-standards`, con la aplicación
   dentro del ejercicio.
8. **Parcheo**: RU/CPU/CSPU aplicados dentro de la ventana de `vulnerability-management-standards`;
   el retraso se registra con motivo y fecha objetivo.

## 13. Operabilidad y SLI

- **SLI mínimos con alerta accionable y runbook** (la plataforma donde viven es de
  `observability-standards`):
  - Disponibilidad de instancia y de **servicio** (no solo "el proceso vive"): conexión real y
    consulta de prueba.
  - Espacio: tablespaces y **FRA** (una FRA llena **para la base de datos** — es la caída
    autoinfligida más frecuente de Oracle), ASM por grupo de discos, `ORACLE_BASE`/diag.
  - Redo: frecuencia de cambio de log, `log file sync`, archivado **con retraso vigilado** (fallo de
    archivado = parada inminente).
  - Data Guard: *transport lag* y *apply lag*, estado del broker.
  - Sesiones: bloqueos (`blocking_session`), `ORA-00060` (deadlocks), sesiones inactivas con
    transacción abierta.
  - Errores: `ORA-01555`, `ORA-04031`, corrupción de bloque, alertas del `alert.log` y de `adrci`
    filtradas por severidad (no volcar el log entero al SIEM).
  - Backups: éxito y duración del backup **y del restore de prueba**, y **edad del último restore
    validado** como SLI de primera clase.
  - Licencia: fecha de la última revisión de `DBA_FEATURE_USAGE_STATISTICS`.
- **Capacidad**: proyectar crecimiento de datafiles, redo por segundo, IOPS y CPU con datos, y
  revisarlo trimestralmente. En Oracle la capacidad es **también** una proyección de coste de
  licencia: añadir cores es una compra.
- **Todo cambio de configuración es código**: `spfile` exportado y versionado, `listener.ora`,
  `sqlnet.ora`, `tnsnames.ora` y jobs bajo control de versiones con detección de *drift*
  (`iac-standards`). Cero cambios manuales en producción.

## 14. Sostenibilidad y prohibiciones

- Revisión **semestral** de: edición y opciones usadas vs. contratadas, versión y fechas de soporte,
  parcheo aplicado, índices y objetos muertos, database links vivos, y coste total por instancia.
- **ADR obligatorio** para: edición y métrica de licencia, plataforma de virtualización que hospeda
  Oracle, adopción de cualquier opción de pago, adopción de RAC, modo de protección de Data Guard,
  destino de una migración de salida.
- Retirar es parte del trabajo: instancias que nadie usa siguen facturando soporte.

### Lista de prohibiciones

- ❌ **Usar AWR/ASH/ADDM, SQL Tuning Advisor, Real-Time SQL Monitoring o cualquier vista
  `DBA_HIST_*` sin la licencia del pack correspondiente** — ni "solo para depurar", ni una vez.
  Sin licencia: `CONTROL_MANAGEMENT_PACK_ACCESS=NONE` y fin de la discusión.
- ❌ Crear tablas particionadas, marcar tablas `INMEMORY`, activar compresión avanzada, abrir una
  standby en lectura o crear la cuarta PDB **sin verificar la licencia primero**.
- ❌ Fijar **precios, métricas o límites de edición de memoria**. Si no está verificado contra la
  documentación del fabricante o el contrato: se declara el hueco y se remite al gestor de
  licencias (§2, §15).
- ❌ Desplegar Oracle en un clúster de virtualización compartido asumiendo que "solo se licencian
  los hosts donde corre" (§2.4).
- ❌ Producción sobre **Free** (sin parches de seguridad) o sobre una versión fuera de soporte sin
  compensación documentada y aceptada por riesgo.
- ❌ Arquitectura **no-CDB** en un diseño nuevo (desoportada) y conversión a PDB sin ensayo previo.
- ❌ Justificar **RAC** por rendimiento, o como sustituto de backup o de DR.
- ❌ `MAX PROTECTION` sin ≥2 standby y sin aceptación escrita de que la primaria se detiene.
- ❌ Considerar `expdp` un backup, o el *recycle bin* un control de recuperación.
- ❌ Dar por bueno un backup por el `RMAN>` en verde: **sin restore probado no existe**.
- ❌ SQL con literales concatenados (rendimiento **e** inyección) y `EXECUTE IMMEDIATE` sobre
  entrada no validada.
- ❌ Cambiar parámetros ocultos (`_*`) sin Service Request que los respalde; tocar más de un
  parámetro a la vez sin medición.
- ❌ Borrar o congelar estadísticas como remedio a un plan malo.
- ❌ Hints regados por el código como estrategia de estabilidad (usar *baselines*).
- ❌ Listener expuesto fuera de la red de servicio, `EXTPROC` activo sin uso, o contraseñas en
  `tnsnames.ora`/scripts.
- ❌ Cuenta de aplicación con `DBA`, `SELECT ANY TABLE` o `GRANT ANY *`.
- ❌ Wallet de TDE respaldado junto a los datos que cifra.
- ❌ Copiar producción con datos personales a entornos no productivos sin enmascarar.
- ❌ Mezclar Pacemaker/Corosync con Oracle Clusterware para el mismo recurso.
- ❌ Presentar la migración a PostgreSQL como conversión automática: el PL/SQL de negocio y la
  semántica de `NULL`/cadena vacía no los resuelve ninguna herramienta.
- ❌ Proponer Babelfish para migrar Oracle (es de SQL Server).

## 15. Verificación web obligatoria

Todo dato de esta skill con impacto económico o de soporte **caduca**. Antes de fijar nada:

1. **Versión y soporte**: MOS **Doc ID 742060.1** ("Release Schedule of Current Database Releases")
   y el *Oracle Lifetime Support Policy: Technology Products* (PDF) — Premier/Extended de 19c, 21c,
   23ai y **26ai**, y **el alcance exacto de las exclusiones de 19c a partir del 1-mayo-2027**
   (BSAFE, Java, TLS, Native Network Encryption, TDE, `DBMS_CRYPTO`, FIPS).
2. **Licenciamiento por edición**: *Licensing Information User Manual* de la versión exacta
   desplegada (tablas "Consolidation", "High Availability", "Manageability", "Performance",
   "Scalability", "Security", "VLDB") — qué es *extra cost option* **hoy** y si algo cambió de
   edición.
3. **Disponibilidad de Standard Edition 2 para 26ai** fuera de Oracle Database Appliance: era un
   **hueco abierto** en esta verificación.
4. *Processor Core Factor Table* vigente y política de *Authorized Cloud Environments*.
5. **Oracle Partitioning Policy** (PDF): confirmar la cita verbatim de §2.4 abriendo el documento
   —oracle.com bloqueó la descarga automatizada— y su estado contractual.
6. Límites de **Oracle AI Database Free** y política de parches.
7. Calendario de **CPU y CSPU** vigente y CVEs del último trimestre que afecten a la versión
   desplegada; triaje según `vulnerability-management-standards`.
8. Estado y mantenimiento de **ora2pg**, **orafce**, **oracle_fdw**, **IvorySQL**,
   **credativ-pg-migrator** y de la vía de conversión de AWS antes de recomendarlos.

### Huecos declarados en esta verificación (agosto 2026)

- **MOS Doc ID 742060.1**: requiere cuenta de My Oracle Support. **No leído**. Las fechas de
  soporte de §9 provienen de fuentes secundarias coincidentes (comunicados de Oracle recogidos por
  terceros) salvo la tabla de Release Updates, que sí se leyó en docs.oracle.com. **Confirmar en MOS
  antes de planificar un upgrade.**
- **Oracle Partitioning Policy (PDF)**: oracle.com devolvió **HTTP 403** a la descarga automatizada.
  La cita de §2.4 no está verificada contra la fuente primaria.
- **Processor Core Factor Table (PDF)**: mismo bloqueo. El valor 0.5 para x86 procede de fuentes
  secundarias; **verificar el PDF vigente y archivar copia fechada**.
- **Precios**: **ninguno** en este documento, deliberadamente. No hay cifra de lista verificada y
  **no se aproxima ninguna**.
- **Standard Edition 2 sobre 26ai fuera de ODA**: no encontrada confirmación de disponibilidad
  general. Tratar como "no disponible" hasta confirmarlo con Oracle.
- **RAC bajo SE2**: las fuentes secundarias **se contradicen** (unas lo dan por eliminado desde 19c,
  otras por incluido dentro del cap de 2 sockets). **No se fija criterio aquí**: verificar en el
  Licensing Information User Manual de la versión concreta antes de diseñar sobre ello.
- **Fechas de Premier Support de 21c y 26ai**: fuente secundaria únicamente.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
