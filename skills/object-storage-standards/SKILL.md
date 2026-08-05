---
name: object-storage-standards
description: Object storage as a model distinct from block and file — the S3 API, its self-hosted implementations and its failure modes. Use when working with aws s3 / aws s3api, mc, or rclone remotes and rclone mount, s3fs, goofys or mountpoint-s3, designing bucket names and key prefixes for listing and throughput, bucket policies versus IAM versus ACLs, BucketOwnerEnforced object ownership, Block Public Access, presigned URLs and their TTL, SSE-S3 / SSE-KMS / SSE-C and TLS enforcement via aws:SecureTransport, Object Lock in governance or compliance mode, legal hold, bucket versioning with noncurrent-version expiration, lifecycle transitions to Glacier Instant Retrieval, Flexible Retrieval or Deep Archive and their restore latency, egress and per-request cost, multipart uploads and AbortIncompleteMultipartUpload, ETag pitfalls and CRC32C or CRC64-NVME checksums, cross-region or cross-provider replication, Storage Lens and request-level metrics, or running MinIO, Ceph RGW, Garage or SeaweedFS on-premise with erasure coding and failure domains.
---

# Estándares de almacenamiento de objetos

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: el almacenamiento de objetos **no es un disco lento ni un NAS barato**. Es un
> modelo distinto —objeto inmutable, sin jerarquía real, con coste por petición y por salida— y casi
> todos los problemas graves del dominio nacen de tratarlo como si fuera un filesystem.

## 1. Alcance y triggers

Aplica al diseño y operación de almacenamiento de objetos: el modelo y sus consecuencias, la API S3
como estándar de facto y su compatibilidad real, diseño de buckets y claves, seguridad y exposición
pública, inmutabilidad y versionado, ciclo de vida y clases de almacenamiento con su coste y su
**tiempo** de recuperación, integridad y multipart, replicación, observabilidad de peticiones y coste,
y el criterio para montar object storage propio.

Disparadores: `aws s3`, `aws s3api`, `mc` (MinIO Client), `s3cmd`, `rclone` y sus *remotes*,
`s3fs`, `goofys`, `mount-s3`/`mountpoint-s3`, `boto3`/`aws-sdk` contra S3, `radosgw-admin`,
`garage`, `weed`, `bucket policy`, `BucketOwnerEnforced`, `BlockPublicAcls`, `PutObjectLockConfiguration`,
`ObjectLockLegalHold`, `NoncurrentVersionExpiration`, `AbortIncompleteMultipartUpload`,
`CreateMultipartUpload`, `x-amz-checksum-*`, `presigned URL`, `STANDARD_IA`, `GLACIER`,
`DEEP_ARCHIVE`, `Cool`/`Archive` de Azure Blob, `Nearline`/`Coldline`/`Archive` de GCS.

**No aplica**: ver
- `backup-recovery-standards` (**skill hermana; cruce declarado en ambos lados**): el object storage
  es hoy el **destino** más común del respaldo y el que aporta la inmutabilidad, pero es un dominio
  propio con vida más allá del respaldo (datalake, artefactos, medios, estáticos, logs). **Aquí se
  explica Object Lock, versionado, ciclo de vida, clases y coste; allí se exigen** como requisito del
  repositorio de copias, junto con la retención GFS, el `check`, el restore probado y el catálogo.
  Regla de arbitraje: si la pregunta es sobre el **bucket** (política, lock, clase, coste, replicación,
  clave de objeto), es de aquí; si es sobre la **copia** (qué se copia, con qué cadena, cuánto se
  guarda y cómo se demuestra el restore), es de allí.
- `bcdr-standards`: RTO/RPO, orden de recuperación y ejercicios. **Cruce que importa**: el tiempo de
  rescate de una clase de archivo (§5.2) es un dato de ingeniería de esta skill que **condiciona** un
  RTO fijado allí; se le devuelve el número, no se ajusta el compromiso aquí.
- `aws-standards` / `azure-standards` / `gcp-standards`: S3, Azure Blob Storage y Cloud Storage como
  **servicios gestionados del proveedor** — integración con el resto del catálogo, cuentas y
  organizaciones, controles de la plataforma (SCP, Azure Policy, VPC Service Controls), facturación y
  FinOps del proveedor. Aquí, el **modelo de object storage** transversal y el criterio que aplica
  igual en los tres y en las implementaciones auto-alojadas.
- `identity-access-management-standards`: diseño de identidades, roles, federación OIDC y el
  principio de mínimo privilegio como práctica. Aquí, su aplicación concreta: política de bucket
  frente a IAM frente a ACL, y credencial de escritura sin borrado.
- `cryptography-pki-standards`: elección de algoritmo, gestión y rotación de claves en KMS/HSM. Aquí,
  solo la decisión operativa: clave gestionada por el proveedor frente a clave propia, y qué protege
  cada una.
- `secrets-management-standards`: dónde viven y cómo rotan las claves de acceso; sustituir credencial
  estática por identidad federada de corta vida.
- `privacy-engineering-standards`: dato personal en objetos — clasificación, minimización, supresión.
  **Cruce**: la supresión frente a un objeto bloqueado por Object Lock en modo *compliance* es
  imposible por diseño; la resolución (*crypto-shredding*, ventana acotada) se decide en aquella skill
  y en `backup-recovery-standards` §3.6. Aquí solo se declara la restricción técnica.
- `grc-compliance-standards`: retención por obligación normativa y evidencia de auditoría; aquí, el
  mecanismo (Object Lock, *legal hold*) que la implementa.
- `data-platform-standards`: formatos de tabla y datalake (Parquet, Iceberg, Delta), particionado
  **lógico** del dato y motores de consulta. Aquí, el **layout de claves** que ese particionado
  produce y su efecto sobre listados y peticiones.
- `kubernetes-standards`: CSI, `PersistentVolume` y el object storage consumido desde un *pod*
  (incluido el CSI de S3, que arrastra los mismos problemas de §2.2).
- `linux-storage-standards` (**existe ya en disco**): bloques y filesystems POSIX de verdad — LVM,
  ext4/XFS/btrfs, NFS, iSCSI. **La frontera es exactamente el antipatrón de §2.2**: si necesitas
  semántica POSIX (renombrado atómico, escritura aleatoria en sitio, `flock`, *hardlinks*), el
  problema es de aquella skill, no de esta — no montes S3.
- `zfs-standards`: pools, datasets y `zfs send`. Un backend de objetos no sustituye a un pool local ni
  al revés.
- `ceph-standards`: **la topología del clúster RADOS, `ceph osd`, el mapa CRUSH, los pools y el
  esquema de protección (réplica frente a *erasure coding*) son suyos**; aquí S3 como interfaz —
  política de bucket, versionado, Object Lock, clases y ciclo de vida— por delante de RGW.
- `proxmox-ve-standards` (**existe ya en disco**): *datastores* de Proxmox Backup Server sobre S3 —
  el producto y su configuración son suyos; las propiedades exigibles al bucket (Object Lock,
  versionado, credencial, clase, coste), de aquí.
- `networking-standards` y `firewall-policy-standards`: endpoints privados, egreso y resolución;
  `dns-standards`: nombres de bucket, *virtual-hosted style* y CNAME hacia el endpoint, y el riesgo de
  **subdominio colgante** cuando un bucket se borra y su registro sobrevive.
- `observability-standards`: diseño de métricas, alertas y paneles. Aquí, **qué** hay que medir.
- `iac-standards`: buckets y políticas como código. `cicd-standards`: artefactos y caché en objetos.
- `homelab-standards`: object storage en laboratorio, donde el criterio es coste y simplicidad y se
  admite lo que aquí se veta.

## 2. El modelo, y el antipatrón que domina el dominio

### 2.1 Objeto frente a fichero

| | Fichero (POSIX) | Objeto (S3) |
|---|---|---|
| Unidad | Fichero mutable, escritura aleatoria en sitio | **Objeto inmutable**: se reemplaza entero, no se modifica |
| Jerarquía | Directorios reales | **Clave plana**; el `/` es una convención de prefijo, **no una carpeta** |
| Renombrar | Operación de metadatos, atómica | **No existe**: es copiar + borrar, con coste, tiempo y una ventana no atómica |
| Metadatos | `stat`, permisos, dueño, xattrs | Cabeceras y *tags*; sin uid/gid ni modo salvo que los emules |
| Listar | Barato, ordenado por directorio | **Petición paginada y facturada**; un prefijo con millones de claves es un problema operativo |
| Bloqueo | `flock`, `fcntl` | **No existe** el bloqueo entre clientes; la última escritura gana |
| Coste | Espacio | **Espacio + peticiones + salida**, y las tres importan |
| Consistencia | Del filesystem | Lectura-tras-escritura **fuerte** en S3 desde 2020; **el versionado y el listado tienen sus propios matices** — verifica el modelo de tu implementación (§8) |

Consecuencias de diseño que se derivan directamente de la tabla: no diseñes flujos que dependan de
renombrar, no uses el listado como índice (usa una base de datos), no esperes escritura concurrente
coordinada, y **empaqueta los ficheros muy pequeños** en objetos mayores: un millón de objetos de 4 KB
es un problema de peticiones y de coste, no de espacio.

### 2.2 "Montar S3 como si fuera un disco": antipatrón

`s3fs`, `goofys`, `rclone mount` y `mountpoint-s3` **traducen** llamadas POSIX a una API que no tiene
semántica POSIX. Lo que se rompe, y por qué no es un problema de calidad de la herramienta sino de
impedancia:

- **Renombrado no atómico** (copia + borrado): cualquier patrón "escribe a `.tmp` y renombra" —el
  patrón de escritura segura más común que existe— deja de ser seguro.
- **Escritura aleatoria en sitio**: o no existe, o se emula reescribiendo el objeto entero (amplificación
  brutal de I/O y de coste).
- **Sin bloqueo entre clientes**: dos escritores concurrentes corrompen sin avisar.
- **Metadatos caros**: cada `stat` es una petición. Un `ls -l`, un `find` o un `rsync` sobre un
  montaje son una factura y una latencia, no una operación local.
- **Fallos que POSIX no contempla**: cortes de red, 429/503 y reintentos aparecen como errores de I/O
  o como montajes que desaparecen sin registro.
- **Espacio de nombres desalineado**: las claves S3 admiten cosas que POSIX no; hay claves que
  simplemente **no son visibles** desde el montaje (por ejemplo, las que contienen bytes nulos), y la
  traducción parte por `/`.

**Criterio**:
- **VETADO** para: bases de datos de cualquier tipo, backend de una aplicación con estado, home de
  usuario, destino de compilación, workloads con muchos ficheros pequeños o con escritura concurrente.
- **Admisible, acotado y documentado**: lectura secuencial de objetos grandes por procesos que no
  pueden hablar S3 (ingesta de medios, entrenamiento, ETL de solo lectura), o exposición temporal de
  solo lectura. Para ese caso, **`mountpoint-s3`** (1.23.0, 21-jul-2026) es la opción con el contrato
  más honesto: **AWS declara explícitamente que no es un filesystem de propósito general**, optimizado
  para lectura de alto rendimiento y escritura secuencial de objetos nuevos desde **un solo cliente**,
  y remite a EFS/FSx si necesitas semántica de verdad.
- **`s3fs-fuse`** (v1.97, 8-dic-2025; repositorio activo) es la única de las tres que da un subconjunto
  POSIX amplio y la que funciona contra endpoints no-AWS, a costa de ser la más lenta en metadatos y
  con historial de problemas de caché y de montajes que se caen. Úsala solo dentro del caso acotado.
- **`goofys` está muerto**: último release **v0.24.0 (abril de 2020)** y último *push* al repositorio
  en julio de 2024. **VETADO** en despliegues nuevos.
- **`rclone mount`** (rclone 1.75.0, 31-jul-2026, proyecto muy activo) es aceptable para sincronización
  y acceso puntual; **no** como almacenamiento de una aplicación.
- La alternativa correcta casi siempre es **hablar S3 directamente desde la aplicación**, o usar un
  filesystem de red real (`linux-storage-standards`).

## 3. Decisiones por defecto

> Verificar versión, licencia, estado de mantenimiento y **compatibilidad S3 real** por web antes de
> fijarlas (§8). Datos de **agosto de 2026**, con versiones y fechas tomadas de `api.github.com` y de
> las notas oficiales, **nunca del render HTML de GitHub Releases**.

| Decisión | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| API | **S3 como estándar de facto**. Todo lo que escribas, contra el SDK de S3 | APIs propietarias solo si aportan algo que S3 no da; la portabilidad vale más de lo que parece el día que cambias de proveedor |
| Servicio gestionado frente a propio | **Gestionado por defecto** (S3, Blob, GCS). Se paga por durabilidad, disponibilidad y por no operar discos | Auto-alojado solo con los criterios de §7 |
| Auto-alojado, escala grande y multi-servicio | **Ceph RGW** — Tentacle **v20.2.3** (05-ago-2026); v20.2.0 nov-2025, v20.2.1 abr-2026, v20.2.2 jun-2026. **Squid 19.2.x tiene EOL estimado el 31-10-2026**: no arranques nada nuevo ahí. Topología, `ceph osd`, pools y EC en `ceph-standards`. Object Lock en *governance* y *compliance*; en Tentacle, `PutObjectLockConfiguration` **ya permite habilitar Object Lock en un bucket versionado existente** (antes solo en la creación) | Coste real: operar Ceph es un trabajo, no una tarea |
| Auto-alojado, pequeño y geo-distribuido | **Garage** v2.3.0 (16-abr-2026), AGPL-3.0, ligero y honesto sobre sus límites | **NO SIRVE como ancla de inmutabilidad**: no implementa versionado de bucket (`GetBucketVersioning` es un *stub* que responde "no habilitado") y por tanto **no hay Object Lock**; tampoco implementa ACL ni políticas S3 (usa su propio modelo de claves por bucket) ni *erasure coding* |
| Auto-alojado con licencia permisiva | **SeaweedFS** 4.40 (20-jul-2026), núcleo **Apache-2.0** | **Open-core**: reparación automática de *erasure coding*, PITR y admin OIDC están en la Enterprise de pago por TB. Y hay **incidencia abierta de que el modo *compliance* de Object Lock no impide el borrado** (issue #8350, v4.12): **valida el WORM en tu versión antes de confiar en él** |
| **MinIO** | **No es la opción por defecto para un despliegue nuevo.** AGPLv3; la UI de administración se retiró de la Community Edition (commit de feb-2025, polémica en jun-2025) y quedó en la comercial **AIStor**; el proyecto de GitHub pasó a **modo mantenimiento** y **su última release era RELEASE.2025-10-15**, es decir ~9,5 meses sin publicar a ago-2026 | Justificable solo si ya está desplegado y operado, o si se compra AIStor con los ojos abiertos (tarifa de partida citada públicamente en el orden de **96.000 $/año hasta 400 TB útiles** — verifícala). Existe un *fork* del navegador (OpenMaxIO), que **no resuelve** el mantenimiento del servidor. **Este es el dato que más se cita de memoria y peor envejecido está: verifícalo (§8)** |
| CLI | **`aws s3`/`aws s3api`** contra AWS; **`rclone`** para sincronización, migración y multi-proveedor; **`mc`** solo en ecosistema MinIO | `s3cmd`: legado, sin motivo para elegirlo hoy |
| Acceso público | **Bloqueado por defecto y a nivel de cuenta**, no solo de bucket | Excepción: distribución pública deliberada, servida por CDN, con el bucket **privado** detrás (OAC/OAI o firma), no abierto |
| Modelo de permisos | **Política de bucket + IAM**. **ACLs deshabilitadas** (`BucketOwnerEnforced`) | Las ACL están en retirada de facto: desde **abril de 2023** los buckets nuevos de S3 se crean con BPA activado y ACLs deshabilitadas **por cualquier vía** (consola, CLI, SDK, CloudFormation). No las reactives |
| Cifrado en reposo | **Gestionado por el proveedor por defecto**; **clave propia (KMS/CMEK) cuando el control de acceso a la clave sea un control real** (separación de funciones, revocación, auditoría) | **SSE-C** solo con un motivo fuerte: la gestión de la clave por petición es tuya, y perderla es perder el dato |
| Cifrado en tránsito | **Obligatorio y forzado por política** (`aws:SecureTransport = false` → `Deny`) | Confiar en que el cliente use HTTPS |
| Inmutabilidad | **Object Lock con versionado** (§5.1); *compliance* para la copia ancla, *governance* para lo operativo | Sin Object Lock no hay defensa real frente a un compromiso con credenciales válidas |
| Versionado | **Activado en buckets con dato no reproducible**, **siempre con `NoncurrentVersionExpiration`** | **PROHIBIDO** versionado sin política de expiración: es una factura creciente que nadie mira |
| Multipart | **Regla de ciclo de vida `AbortIncompleteMultipartUpload` en todos los buckets** | Sin ella, las partes huérfanas se facturan indefinidamente y **no se ven** en `aws s3 ls` ni en la pestaña de objetos |
| Credencial | **Identidad federada de corta vida** (rol, OIDC); estática solo si no hay alternativa, con rotación | Clave de acceso permanente en la aplicación |
| Credencial del repositorio de backups | **Escritura sin borrado** (`PutObject` sí, `DeleteObject`/`DeleteObjectVersion` no; sin `s3:BypassGovernanceRetention`) | Ver `backup-recovery-standards` §3.4 |

## 4. Buckets y claves

- **Un bucket no es una carpeta**: es una **frontera de política, de cifrado, de ciclo de vida, de
  versionado, de replicación, de registro y a menudo de facturación**. Se crea un bucket cuando alguna
  de esas propiedades difiere, no para "organizar".
- **Nomenclatura**: el nombre es **global** en S3 y aparece en el DNS. Convención estable y
  predecible (`<org>-<entorno>-<dominio>-<propósito>-<región>`), en minúsculas y sin puntos —**los
  puntos rompen el TLS con el acceso *virtual-hosted style***. Nada de nombres adivinables que
  inviten a un *bucket squatting*, y nada de nombres que revelen estructura interna sensible.
- **Dominio de fallo administrativo**: el aislamiento fuerte es la **cuenta**, no el bucket. La copia
  ancla de un respaldo vive en otra cuenta (`backup-recovery-standards` §3.4).
- **Claves y prefijos**:
  - El prefijo es lo único que el servicio entiende de jerarquía. **Diseña el prefijo para el patrón
    de lectura**, no para que quede bonito en la consola.
  - **Prefijo temporal al principio** (`año/mes/día/`) cuando la consulta y el ciclo de vida son por
    fecha: hace baratos el filtrado de lifecycle y el borrado por rango.
  - **Alta cardinalidad al principio** (hash corto, id de tenant) cuando el patrón es de escritura
    masiva y hay que repartir. En S3 el escalado por prefijo hoy es automático, pero el reparto sigue
    ayudando y en implementaciones auto-alojadas puede ser determinante. **Verifica los límites
    vigentes de tu proveedor (§8) en vez de arrastrar consejos de 2015.**
  - **El listado es el enemigo**: `ListObjectsV2` es paginado, facturado y lento sobre prefijos
    enormes. Si tu aplicación lista para encontrar algo, **te falta un índice** en una base de datos.
    El listado es para inventario y reconciliación, no para servir peticiones.
  - **Sin secretos ni dato personal en la clave**: la clave aparece en logs de acceso, en métricas, en
    URLs y en referrers.
  - **Delimitadores consistentes**; evita claves que empiecen por `/`, que contengan `//`, caracteres
    de control o secuencias que rompan la traducción a fichero en un restore.
- **Etiquetado de objetos y de bucket**: *tags* de bucket para coste y propiedad (dueño, entorno,
  clasificación); *tags* de objeto solo si los vas a usar en políticas o en reglas de ciclo de vida —
  se facturan y se olvidan.

## 5. Seguridad, inmutabilidad y ciclo de vida

### 5.1 Exposición: donde ocurren las filtraciones

- **Bloqueo de acceso público activado a nivel de cuenta**, además de por bucket, y aplicado por
  política de organización para que no se pueda desactivar sin pasar por gobierno. Comprobación
  vigente a ago-2026: los buckets nuevos de S3 se crean con **BPA activado y ACLs deshabilitadas**
  desde abril de 2023, por cualquier vía; los *directory buckets* tienen BPA fijo y **no modificable**.
  **Esto no te salva de los buckets antiguos**: el cambio no tocó los existentes. Auditar los viejos
  es trabajo aparte, y es donde están las filtraciones.
- **Jerarquía de controles**, y por qué las ACL sobran: la ACL es un modelo por objeto, invisible en
  auditoría, que sobrevive a la política del bucket y que produce exactamente el fallo clásico
  ("bucket privado, objeto público"). Con `BucketOwnerEnforced` **desaparece el problema**: el dueño
  del bucket posee todos los objetos y el acceso se gobierna solo con políticas. Es la
  configuración por defecto y **no se revierte**.
- **Política de bucket frente a IAM**: IAM dice qué puede hacer una identidad; la política de bucket
  dice quién puede tocar el recurso y es el sitio correcto para los controles **negativos** que deben
  valer para todos: denegar sin TLS, denegar sin cifrado, denegar fuera de la organización o del
  endpoint privado, denegar `s3:BypassGovernanceRetention` salvo a un rol nominal. **Un `Deny`
  explícito gana siempre**: úsalo para los invariantes.
- **URLs prefirmadas**: **TTL corto** (minutos, no días), el mínimo verbo posible, sin reutilizar y
  sin registrarlas en logs — la URL **es** la credencial. Ojo con el límite duro: una URL firmada con
  credenciales temporales **no sobrevive a la caducidad de esas credenciales** aunque su propio TTL
  sea mayor. Para descarga pública sostenida, CDN con firma, no prefirmado a mano.
- **Registro de acceso activado** (logs de acceso o eventos de datos), con destino en **otro bucket y
  preferiblemente otra cuenta**. Sin registro, una exfiltración por objeto es invisible.
- **Egreso controlado**: en cargas sensibles, endpoint privado y política que restrinja el origen —
  un bucket alcanzable desde cualquier sitio con una clave filtrada es exfiltración en un `aws s3 sync`.
- **Subdominio colgante**: un CNAME hacia un bucket que se borra permite que otro lo reclame. Al
  retirar un bucket, retira el registro DNS **primero** (`dns-standards`).

### 5.2 Inmutabilidad y retención

**Object Lock** (WORM), con el detalle verificado a ago-2026:

- **Requiere versionado**, y el bloqueo se aplica a **versiones de objeto**, no a claves. Habilitar
  Object Lock en un bucket **no se puede deshacer**.
- **Modo *governance***: nadie borra ni altera el bloqueo **salvo** quien tenga
  `s3:BypassGovernanceRetention` y envíe la cabecera `x-amz-bypass-governance-retention`. Es el modo
  correcto para lo operativo y para **probar** una política antes de comprometerla.
- **Modo *compliance***: **nadie** —incluida la cuenta raíz— puede borrar, sobrescribir, acortar la
  retención ni cambiar el modo hasta que expire. Es la protección real frente a un atacante con
  credenciales de administrador, y **es también un riesgo operativo y de coste**: una retención mal
  fijada (6 años en vez de 6 días) es irreversible y se paga entera. **Práctica obligatoria: probar en
  *governance*, promover a *compliance*.**
- **Retención mínima 1 día, sin máximo.** Fija la retención por defecto del bucket y no la dejes al
  cliente.
- ***Legal hold***: independiente de la retención, sin fecha, se retira explícitamente, y **el ciclo
  de vida no lo vence**. Retención y *hold* coexisten: si cualquiera está activo, no se borra. Es el
  mecanismo para una investigación o un litigio (`grc-compliance-standards`,
  `incident-response-forensics-standards`).
- **Sobre existentes**: se aplica o extiende con **S3 Batch Operations**. En **Ceph RGW ≥ Tentacle**,
  `PutObjectLockConfiguration` ya permite habilitar Object Lock en un bucket versionado que no se creó
  con él — antes obligaba a crear bucket nuevo y migrar.
- **Object Lock ha sido evaluado por terceros frente a SEC 17a-4(f), FINRA 4511 y CFTC 1.31**: si esa
  evaluación es tu justificación de cumplimiento, verifica su vigencia y su alcance
  (`grc-compliance-standards`), no la cites de memoria.
- **La compatibilidad no se presupone**: hay implementaciones S3 que exponen la API de Object Lock y
  **no la aplican** (caso documentado y abierto en SeaweedFS, §3). Si tu inmutabilidad depende de esto,
  **pruébalo**: escribe, bloquea, intenta borrar con credencial de administrador y comprueba que
  falla. Ese es el gate §6.4.
- **Restricción que hay que declarar, no esquivar**: el borrado por derecho de supresión **no es
  posible** dentro de un objeto en modo *compliance*. Ver `privacy-engineering-standards` y
  `backup-recovery-standards` §3.6: se resuelve con *crypto-shredding* y ventana acotada, no editando
  la copia.

**Versionado**: es la defensa contra el borrado y la sobrescritura accidentales, y **el mecanismo que
convierte un `DELETE` en un marcador reversible**. Dos verdades incómodas:
1. **El versionado sin política de expiración es una factura creciente** — todas las versiones no
   actuales siguen ocupando y facturando, indefinidamente, y no aparecen en un listado normal. Regla:
   versionado y `NoncurrentVersionExpiration` **se configuran en el mismo cambio**, siempre.
2. **El versionado no es inmutabilidad**: quien puede borrar versiones (`DeleteObjectVersion`) o
   suspender el versionado se lleva todo. La inmutabilidad la da el Object Lock.

### 5.3 Ciclo de vida y clases de almacenamiento

- **El error clásico del dominio**: diseñar con la clase de archivo porque es barata de almacenar y
  descubrir el **plazo de rescate** durante un incidente. Datos vigentes de AWS a ago-2026:
  **Deep Archive** restaura típicamente en **~12 h** con *Standard* (9-12 h vía S3 Batch Operations,
  con rendimiento del orden de 1-2 PB/día) y en **~48 h** con *Bulk*. Precios de recuperación citados
  públicamente: ~**0,02 $/GB** *Standard* y ~**0,0025 $/GB** *Bulk* (verifícalos, §8).
  **Regla dura: si el RTO es inferior al plazo de rescate de la clase, esa clase no es tu nivel de
  recuperación.** Ese número se devuelve a `bcdr-standards`.
- **Costes ocultos del rescate**, todos reales y todos olvidados: el objeto restaurado se **copia
  temporalmente a una clase caliente** y esa copia se factura mientras dure; el original sigue en
  archivo; el **mínimo de permanencia** (180 días en Deep Archive) se paga entero aunque borres al
  día 30; y hay **coste por petición** por objeto restaurado, que domina si son millones de objetos
  pequeños.
- **Diseño de transición**: transición por edad basada en un patrón de acceso **medido**, no supuesto
  (Storage Lens / analítica de clase). Objetos pequeños no compensan la transición (hay un tamaño
  mínimo efectivo y un coste por transición por objeto): **empaquétalos**.
- **Coste de salida (egress) y de petición como restricción de diseño**: la salida entre proveedores
  o hacia Internet es el eje que decide arquitecturas enteras (y el que hace caro salir). Un
  repositorio de respaldo se diseña asumiendo que **algún día se lee entero**, y ese día se factura.
- **Equivalentes**: Azure Blob (*Cool*, *Cold*, *Archive*, con rehidratación de horas y su propio
  mínimo de permanencia) y GCS (*Nearline*, *Coldline*, *Archive*, sin espera de rehidratación pero
  con coste de recuperación y mínimos de permanencia) **no son intercambiables** con S3 ni entre sí.
  **Verifica plazos, mínimos y coste de cada uno antes de diseñar (§8): están explícitamente marcados
  como hueco en esta revisión salvo lo indicado de AWS.**
- **Las reglas de ciclo de vida se despliegan como código y se revisan**: `put-bucket-lifecycle-
  configuration` **reemplaza la configuración entera, no la fusiona** — un despliegue descuidado borra
  reglas existentes (incluida la de abortar multipart). Es un fallo silencioso clásico.

## 6. Gates

Rompen la entrega:

1. **Bucket y política como código**, con `Deny` explícito de tráfico sin TLS y de escritura sin
   cifrado. Creado a mano en la consola = hallazgo.
2. **Escaneo de exposición pública** en CI y en continuo: BPA a nivel de cuenta, ACLs deshabilitadas,
   ausencia de `Principal: "*"` sin condición. Alerta en tiempo real ante un cambio de política que
   abra un bucket.
3. **`AbortIncompleteMultipartUpload` presente en todos los buckets**, con `DaysAfterInitiation` mayor
   que la sesión legítima más larga (7 días es un valor razonable por defecto). Verificado por
   inventario, no por confianza.
4. **Prueba de inmutabilidad ejecutada**, no supuesta: escribir un objeto bajo Object Lock, intentar
   borrarlo con la credencial más privilegiada disponible y **comprobar que falla**. Obligatorio en
   cualquier implementación no-AWS.
5. **Versionado y `NoncurrentVersionExpiration` juntos**, siempre. Versionado sin expiración es un
   fallo de gate.
6. **Reconciliación de inventario**: contraste periódico entre lo que se cree que hay y lo que hay
   (inventario del proveedor o listado), con detección de partes incompletas y de versiones
   huérfanas.
7. **Alerta de coste por eje**, no solo por total: espacio, **peticiones**, salida y recuperación de
   archivo por separado. Un pico de peticiones es una anomalía de aplicación o una exfiltración.
8. **Registro de acceso activo**, en otro bucket y a ser posible en otra cuenta, con retención
   definida.
9. **Prueba de recuperación desde la clase fría**, cronometrada, al menos una vez: el plazo real es el
   dato, y suele desmentir la hoja de cálculo.
10. **Integridad verificada extremo a extremo** (§7.2): checksum comprobado en subida y en descarga,
    no confiado al ETag.

## 7. Operación

### 7.1 Replicación, migración y herramientas

- **Replicación entre regiones**: protege del fallo regional; **no protege del borrado**, que se
  replica igual salvo que se configure lo contrario, ni de un compromiso de la cuenta. Para respaldo,
  lo que cuenta es **otro dominio de fallo administrativo** (otra cuenta u otro proveedor) más Object
  Lock en el destino.
- **Replicación entre proveedores**: defendible como seguro contra el riesgo de proveedor entero
  (`bcdr-standards`), y cara en salida. Decisión con ADR y coste cuantificado, no reflejo.
- **La replicación no es retroactiva** por defecto: los objetos anteriores a la regla no se copian sin
  una operación explícita de *batch*. Fallo silencioso muy frecuente.
- **`rclone`** (1.75.0, 31-jul-2026) es la herramienta correcta para sincronizar y migrar entre
  proveedores. Reglas: `--checksum` mejor que `--size-only`; **`--dry-run` antes de cualquier
  `sync`** (que borra en destino); `copy` por defecto y `sync` solo cuando el borrado sea la
  intención; paralelismo y tamaño de *chunk* ajustados, sabiendo que el paralelismo se paga en
  peticiones.
- **`aws s3 sync`** para lo cotidiano en AWS; **`aws s3api`** cuando necesites control fino (lock,
  versiones, checksums). **`mc`** solo en ecosistema MinIO.
- **Migraciones grandes**: cuenta las **peticiones**, no solo los TB; considera transferencia física
  del proveedor si el volumen lo justifica; y valida por **inventario y checksum**, no por "el comando
  terminó".

### 7.2 Multipart e integridad

- **Multipart es obligatorio por encima del umbral del SDK** y deseable para objetos grandes: permite
  paralelismo y reintento por parte. Su residuo es el problema.
- **Partes incompletas: basura que se factura y que no se ve.** Se almacenan y se cobran a la tarifa
  de la clase indicada al subirlas, indefinidamente, y **no aparecen en `aws s3 ls` ni en la lista de
  objetos de la consola**. En archivo se facturan como *staging* a tarifa caliente. El control es la
  regla de ciclo de vida (§6.3) y la métrica de Storage Lens
  (`IncompleteMultipartUploadStorageBytes`, actualización diaria).
- **ETag: trampa clásica.** El ETag **no es necesariamente el MD5 del objeto**; en multipart es un
  compuesto (hash de hashes con sufijo `-N`) que depende del **tamaño de parte usado**, así que dos
  copias idénticas subidas con tamaños de parte distintos tienen ETag distinto. **VETADO usar el ETag
  como prueba de integridad o como criterio de comparación entre orígenes.**
- **Checksums, que es lo que sí sirve**: usa checksums adicionales (`x-amz-checksum-*`). Estado
  verificado a ago-2026: si no se especifica ninguno, S3 aplica por defecto **CRC-64/NVME** y calcula
  el checksum de objeto completo al terminar la subida. En multipart se declara **`COMPOSITE` o
  `FULL_OBJECT`** en `CreateMultipartUpload` (`FULL_OBJECT` solo con algoritmos CRC, y en ese caso no
  se envía algoritmo por parte); un desajuste devuelve **`BadDigest`**. Con checksum adicional por
  parte, los números de parte deben **empezar en 1 y ser consecutivos** o se obtiene
  **`InvalidPartOrder`**.
- **Verificación extremo a extremo**: el productor calcula y guarda el checksum del contenido; el
  consumidor lo comprueba tras descargar. La comprobación del proveedor cubre el transporte y el
  almacenamiento, no cubre que subieras el fichero equivocado.

### 7.3 Observabilidad y coste

- **Mide peticiones, no solo espacio.** Es la lección de operación más cara del dominio: la factura de
  un bucket con muchos objetos pequeños la domina el `GET`/`PUT`/`LIST`, no el GB.
- Series mínimas: bytes por clase, número de objetos, **peticiones por tipo**, tasa de error 4xx/5xx,
  **429/503 y reintentos** (indican mal reparto o límite de tasa), latencia p50/p99, **bytes de salida**,
  bytes en partes incompletas, bytes en versiones no actuales, y **coste de recuperación de archivo**.
- **Alertas útiles**: pico de `GET` o de salida fuera de patrón (exfiltración o bucle de cliente),
  crecimiento de versiones no actuales (falta la expiración), crecimiento de partes incompletas (falta
  la regla de aborto), aparición de `Principal: "*"`, y fallo de replicación con retraso creciente.
- **Coste por bucket y por dueño**, vía etiquetado, o la conversación de FinOps es imposible.
- **Reconciliación con el inventario del proveedor** (informe de inventario diario) en lugar de
  listados masivos: listar millones de objetos para saber qué hay es caro y lento.

### 7.4 On-premise: cuándo montar el tuyo

Montar object storage propio es un **compromiso operativo permanente**, no un despliegue. Solo se
justifica con al menos uno de estos motivos, escrito en un ADR:

- **Soberanía o requisito legal** que impide el proveedor.
- **Volumen y patrón** donde el coste de salida y de peticiones domina y hay personal para operarlo.
- **Latencia o adyacencia** al cómputo local.
- **Hardware ya amortizado** y capacidad de operación ya existente.

Y lo que implica de verdad:

- **Erasure coding frente a réplica**: EC da eficiencia de espacio (típicamente 1,3-1,5x frente a 3x
  de la triple réplica) a cambio de CPU, latencia y **reconstrucciones caras**. La réplica es simple y
  rápida de reconstruir. La decisión depende del tamaño de objeto y del perfil de acceso, y es de las
  difíciles de cambiar después.
- **Dominios de fallo explícitos**: el esquema de distribución debe repartir por nodo, rack y
  alimentación, no solo por disco. Un EC que sobrevive a dos discos pero no a un rack **no protege de
  lo que realmente falla**.
- **La durabilidad es un trabajo continuo**: *scrub*, detección de corrupción silenciosa, sustitución
  de discos y control del tiempo de reconstrucción, que crece con la capacidad del disco y es cuando
  el cluster es vulnerable.
- **Actualizaciones y compatibilidad**: la API S3 auto-alojada **nunca es 100 % compatible**. Prueba
  con **tu** cliente y **tus** funciones —Object Lock, versionado, políticas, lifecycle, multipart,
  checksums— antes de comprometerte. Es exactamente donde Garage no llega y donde SeaweedFS tiene una
  incidencia abierta (§3).
- **Comparación honesta**: el coste del hardware es la parte fácil. Súmale energía, espacio,
  reemplazo, **personal con guardia**, actualizaciones, y el hecho de que la durabilidad y la
  disponibilidad que consigues no serán las del proveedor. Si el resultado sale parecido, **paga el
  servicio**: el argumento de "es más barato" casi nunca sobrevive a contar el personal.
- **Y aun con object storage propio, la copia ancla sigue necesitando otro dominio de fallo
  administrativo** (`backup-recovery-standards` §3.4). Tu MinIO/Ceph en el mismo CPD no es la copia
  externa.

## 8. Sostenibilidad y prohibiciones

**Cadencia**: revisión semestral de versiones, licencias y estado de mantenimiento de la
implementación auto-alojada (§9); revisión trimestral de políticas de bucket y de exposición pública;
revisión anual de reglas de ciclo de vida contra el patrón de acceso real y contra la factura;
comprobación de la prueba de inmutabilidad tras cada actualización mayor del backend.

**PROHIBIDO**
- ❌ Montar S3 como filesystem para una base de datos, un backend con estado, un home o una compilación.
- ❌ Usar `goofys` en nada nuevo (muerto desde 2020/2024).
- ❌ Depender de renombrado atómico, escritura aleatoria en sitio o bloqueo entre clientes sobre objetos.
- ❌ Usar el listado como índice de la aplicación.
- ❌ Desactivar el bloqueo de acceso público, o reactivar las ACL, sin decisión documentada y revisada.
- ❌ `Principal: "*"` sin condición restrictiva en una política de bucket.
- ❌ Bucket sin `Deny` de tráfico sin TLS.
- ❌ Versionado sin `NoncurrentVersionExpiration`.
- ❌ Bucket sin regla `AbortIncompleteMultipartUpload`.
- ❌ Usar el **ETag** como prueba de integridad o para comparar objetos entre orígenes.
- ❌ Confiar en la inmutabilidad de una implementación S3 **sin haber probado** que el borrado falla.
- ❌ Anclar la inmutabilidad de un respaldo en **Garage** (no tiene versionado, luego no tiene Object
  Lock) o en **SeaweedFS** sin validar el modo *compliance* en tu versión.
- ❌ Desplegar **MinIO** en un sistema nuevo sin haber verificado su estado de mantenimiento y su
  modelo comercial actual (§9).
- ❌ Aplicar Object Lock en modo *compliance* sin haber probado antes la política en *governance*.
- ❌ Diseñar con clase de archivo sin conocer y medir su **plazo de rescate**, su mínimo de permanencia
  y su coste de recuperación.
- ❌ Presuponer que la replicación protege del borrado, o que es retroactiva.
- ❌ URLs prefirmadas con TTL largo, reutilizadas o registradas en logs.
- ❌ Secretos o dato personal en el nombre del bucket o en la clave del objeto.
- ❌ Borrar un bucket sin retirar antes su registro DNS (subdominio colgante).
- ❌ Desplegar `put-bucket-lifecycle-configuration` sin saber que **reemplaza** la configuración entera.
- ❌ Vigilar solo el espacio y no las **peticiones** ni la salida.
- ❌ Montar object storage propio sin ADR, sin personal de guardia y sin prueba de compatibilidad S3
  con tu cliente real.
- ❌ Fijar versiones, licencias, precios, plazos de rescate o comportamiento de servicio **de memoria**
  (§9).

## 9. Verificación web obligatoria

Antes de fijar cualquier versión, licencia, precio, plazo o comportamiento, **búscalo — no lo
recuerdes**. **Aviso metodológico**: toda fecha o versión de GitHub debe salir de **`api.github.com` o
de los feeds Atom**, nunca del render HTML de la página de Releases.

1. **MinIO** — el dato más volátil y peor recordado del dominio. Verificado a ago-2026: AGPLv3; UI de
   administración retirada de la Community Edition (commit de feb-2025, polémica pública en jun-2025)
   y disponible solo en **AIStor** comercial (tarifa citada públicamente en el orden de 96.000 $/año
   hasta 400 TB útiles); proyecto de GitHub declarado en **modo mantenimiento**; **última release
   `RELEASE.2025-10-15T17-29-55Z`**, confirmada vía `api.github.com` — ~9,5 meses sin publicar.
   Existe el *fork* del navegador OpenMaxIO. **Comprueba si ha habido releases nuevas, si el modo
   mantenimiento sigue, y qué funciones adicionales se han movido a AIStor** antes de recomendarlo o
   descartarlo.
2. **Ceph RGW**: versión estable vigente (a ago-2026, **Tentacle v20.2.3**, 05-ago-2026, con EOL
   estimado 01-06-2027; Squid 19.2.x muere el 31-10-2026), y el estado de
   Object Lock —incluida la novedad de Tentacle de poder habilitarlo sobre un bucket versionado
   existente— y de la corrección del `RetainUntilDate` posterior a 2106 (**no repara bloqueos ya
   escritos**).
3. **Garage** (v2.3.0, 16-abr-2026, AGPL-3.0): confirma en su **tabla oficial de compatibilidad S3**
   si sigue sin versionado de bucket, sin Object Lock, sin ACL/políticas S3 y sin *erasure coding*.
   Estos límites cambian entre versiones y son los que deciden si sirve para tu caso.
4. **SeaweedFS** (4.40, 20-jul-2026, núcleo Apache-2.0): estado de la incidencia sobre el modo
   *compliance* de Object Lock (issue #8350 sobre v4.12, borrado que sigue teniendo éxito) y qué sigue
   siendo exclusivo de la Enterprise de pago por TB (reparación automática de EC, PITR, admin OIDC).
5. **S3 Object Lock**: modos vigentes, límites reales, `s3:BypassGovernanceRetention`, mínimos y
   máximos de retención, aplicación sobre objetos existentes vía Batch Operations, y el alcance y la
   vigencia de la evaluación frente a SEC 17a-4(f) / FINRA 4511 / CFTC 1.31.
6. **Comportamiento por defecto de los proveedores**: verificado a ago-2026 que S3 sigue creando los
   buckets nuevos con **Block Public Access activado y ACLs deshabilitadas** (`BucketOwnerEnforced`)
   desde abril de 2023, por cualquier vía, y que los *directory buckets* lo tienen fijo. **Comprueba si
   ha cambiado, y comprueba los equivalentes de Azure y GCP — no verificados en esta revisión.**
7. **Clases frías y de archivo**: verificado a ago-2026 para AWS **Deep Archive**: *Standard* ~12 h
   (9-12 h con S3 Batch Operations, del orden de 1-2 PB/día), *Bulk* ~48 h, mínimo de permanencia 180
   días, coste de recuperación citado en fuentes secundarias en ~0,02 $/GB (*Standard*) y ~0,0025 $/GB
   (*Bulk*). **Contrasta los precios contra la página oficial de precios de S3 antes de usarlos**.
   **Hueco declarado**: no verificados en esta revisión los plazos, mínimos y costes de **Azure Blob
   Archive** (rehidratación) ni de **GCS Coldline/Archive**, ni el coste de salida vigente de ningún
   proveedor.
8. **Montaje**: estado y contrato de **`mountpoint-s3`** (1.23.0, 21-jul-2026; AWS declara que no es
   un filesystem de propósito general), **`s3fs-fuse`** (v1.97, dic-2025, repo activo) y **`rclone`**
   (1.75.0, 31-jul-2026). Confirmado a ago-2026 que **`goofys` está abandonado** (último release
   v0.24.0 de abril de 2020, último *push* en julio de 2024).
9. **Límites de rendimiento y de tasa por prefijo** de tu proveedor: el consejo de aleatorizar el
   prefijo procede de un modelo antiguo. Consulta los límites vigentes en la documentación oficial en
   vez de arrastrar recetas.
10. **Integridad**: comportamiento vigente de los checksums por defecto (a ago-2026, **CRC-64/NVME**
    cuando no se especifica), la distinción `COMPOSITE`/`FULL_OBJECT` en multipart y los errores
    `BadDigest` e `InvalidPartOrder`.
11. **Incidentes de cadena de suministro** de cualquier herramienta o imagen que recomiendes (`rclone`,
    `mc`, clientes S3, imágenes de MinIO/Ceph/Garage/SeaweedFS), en sus canales de aviso. Precedentes
    del catálogo que justifican comprobarlo: el compromiso de **Trivy** (marzo de 2026), la oleada
    contra repositorios y GitHub Actions de 2026 (Nx / CVE-2026-48027 en el KEV de CISA, campaña
    "Megalodon", *Miasma*). **Hueco declarado**: no se ha revisado el historial de CVE de Ceph RGW,
    Garage ni SeaweedFS en esta pasada.
12. **Modelo de consistencia** de tu implementación concreta (listado, versionado, replicación): S3 da
    lectura-tras-escritura fuerte desde 2020, pero **las implementaciones auto-alojadas y los matices
    de listado varían**. No lo des por hecho.

Si no puedes verificar, **dilo explícitamente en vez de suponer**.
Si la web contradice este documento, **manda la web** y señala la discrepancia.
