---
name: zfs-standards
description: OpenZFS pool design and operation on Linux and FreeBSD. Use when running zpool or zfs subcommands (zpool create/status/scrub/replace/attach/detach/import/trim, zfs send/recv, zfs rewrite, zfs allow, zdb), choosing vdev topology (mirror, raidz1/raidz2/raidz3, draid, special vdev, SLOG/log, L2ARC/cache, spares), setting ashift, recordsize, volblocksize, compression=lz4/zstd, atime, xattr=sa, sync, logbias, primarycache, dedup or fast dedup (dedup_table_quota, feature@fast_dedup), zvols, ZFS native encryption and raw send (zfs send -w, keylocation, keyformat), ARC tuning (zfs_arc_max, zarcstat, zarcsummary, arcstats), snapshot replication with sanoid/syncoid, zrepl or zfs-autobackup, zfs-dkms versus kmod module builds, RAIDZ expansion, resilver and scrub scheduling, or ZFS-on-root.
---

# Estándares de ZFS (OpenZFS)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: en ZFS **el diseño del pool es una decisión de puerta de un solo sentido**.
> `ashift`, el tipo de vdev, su anchura y la presencia de un `special` vdev no se cambian: se
> destruye el pool y se restaura. Todo lo demás (propiedades, snapshots, caché) es reversible.
> Dedica el esfuerzo de diseño a lo irreversible y deja de discutir lo que se cambia con un
> `zfs set`.

## 1. Alcance y triggers

Aplica a cualquier tarea sobre un pool ZFS: topología y creación, propiedades de dataset y zvol,
integridad (scrub, resilver, sustitución de disco), snapshots y replicación como **mecanismo**,
cifrado nativo, ARC y memoria, empaquetado del módulo en Linux, y planificación de capacidad.

Disparadores: `zpool`, `zfs`, `zdb`, `zed`/ZED, `arcstats`, `/etc/zfs/`, `zfs.conf` en
`modprobe.d`, `zpool.cache`, `feature@…`, `sanoid.conf`, `zrepl.yml`.

**Regla de arbitraje interna**: si la pregunta se responde con `zpool` o `zfs`, es de esta skill.
Si se responde con `lvs`, `mdadm`, `mkfs` o `mount`, es de `linux-storage-standards`.

**No aplica**: ver `linux-storage-standards` (**la frontera hermana**: LVM, mdadm, ext4/XFS/btrfs,
multipath, NVMe, LUKS, `fio`, `iostat` — todo el stack de bloques tradicional; **un sistema con ZFS
no lleva LVM ni mdadm debajo**, ZFS es a la vez gestor de volúmenes y filesystem y necesita los
discos crudos), `onprem-standards` (paraguas de plataforma: su §2 fija el criterio de filesystem
—ZFS con mirrors o RAIDZ2— y esta skill lo desarrolla sin contradecirlo; su §1.3 fija los
invariantes), `bcdr-standards` (RTO/RPO, orden de recuperación, ejercicios de DR: **un snapshot no
es un backup**, ver §3.5), `backup-recovery-standards` (**Ola 2, planificada** — la **estrategia y
mecánica del respaldo**: herramienta, repositorio, retención GFS, inmutabilidad, catálogo,
procedimiento de restore; aquí solo el snapshot y `zfs send` como **mecanismo de bajo nivel**, no
como plan de copia), `linux-administration-standards` (día a día del SO:
`fstab`, unidades `.mount`, systemd, paquetes, diagnóstico general del host; la **frontera**: el
montaje de un dataset ZFS lo gobierna la propiedad `mountpoint` y el generador de systemd de ZFS,
no `fstab` — si aparece una línea de `fstab` para un dataset, el error es de esta skill; si el
problema es de orden de arranque, `systemd-remount-fs` o un `.mount` de un filesystem no-ZFS, es de
aquella), `data-platform-standards` (**el motor de datos encima**: el `recordsize`/`volblocksize`
del dataset donde vive PostgreSQL es **de esta skill**; el `shared_buffers`, el `full_page_writes`,
los índices y el PITR son **suyos** — ver §3.2), `homelab-standards` (btrfs y snapshots en
laboratorio, criterio de coste, ruido y consumo: allí ZFS compite con btrfs por RAM y por
simplicidad, y la decisión es económica), `proxmox-ve-standards` y `libvirt-kvm-standards`
(**Ola 2, planificadas**: almacenamiento de VMs — el zvol y su `volblocksize` son de aquí, la
definición del disco de la VM y el modelo de caché del hipervisor son suyos),
`ha-clustering-standards` (**Ola 2, planificada**: almacenamiento compartido y fencing — **ZFS no
es un filesystem de cluster**, ver §7), `object-storage-standards` (**Ola 2, planificada**: S3),
`file-servers-standards` (**el snapshot se crea aquí y se publica allí**: las *Previous Versions*
que ve un cliente Windows salen de un snapshot ZFS expuesto por SMB con `shadow_copy2`, cuya
configuración es suya), `kubernetes-standards` (CSI, PV/PVC), `observability-standards` (diseño de métricas y alertas; aquí
solo **qué** hay que vigilar de ZFS), `cryptography-pki-standards` (elección de algoritmo y custodia
de la clave de `keylocation`; aquí solo el uso operativo del cifrado nativo),
`linux-hardening-standards` (`noexec`/`nosuid`/`nodev` como control de seguridad, aunque se
expresen como propiedades ZFS; el criterio de rendimiento y layout es de aquí).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un sistema real (§8).

| Ámbito | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Versión de OpenZFS | **2.4.x** (2.4.3, 12-jun-2026; kernels Linux 4.18–7.0, FreeBSD 13.3+/14.0+) | **2.3.x** (2.3.8) sigue mantenida y es la elección conservadora si tu distro la empaqueta. **2.2 está EOL desde el 18-dic-2025** — aunque se publicara un 2.2.10 el 12-jun-2026, no es una rama viva: planifica la salida. ❌ Ramas EOL en prod sin fecha de migración |
| Topología para datos que importan | **Mirrors** (vdevs de 2 vías, 3 en datos irreemplazables) | **RAIDZ2** cuando el espacio útil manda sobre los IOPS (archivo, backup, media). ❌ RAIDZ1 con discos ≥2 TB. ❌ RAID0 / vdev único sin redundancia en prod |
| Anchura de vdev RAIDZ | RAIDZ2 de **6–10 discos**; por encima, varios vdevs en el mismo pool | ❌ RAIDZ de 16+ discos "para no perder espacio": el resilver se eterniza y la ventana de segundo fallo se dispara |
| `ashift` | **12** (sectores de 4 KiB) salvo prueba en contrario; **13** en NVMe/SSD con página de 8 KiB | ❌ Dejar que ZFS autodetecte con discos que mienten (512e): quedas clavado en `ashift=9` **de por vida**. Verifica con `zdb -C \| grep ashift` tras crear |
| Compresión | **`lz4`** en todo el pool (`compression=lz4`), coste despreciable y evita escribir ceros | **`zstd`** (nivel 3–7) en datos fríos o con CPU sobrante y ratio demostrado. ❌ `compression=off` "para no gastar CPU": pierdes espacio, ancho de banda y el early-abort de lz4 ya es gratis |
| `atime` | **`atime=off`** por defecto; `relatime=on` si algo depende del tiempo de acceso | ❌ `atime=on` en datasets con muchos ficheros: escritura por cada lectura |
| `xattr` | **`xattr=sa`** (y `acltype=posixacl` donde se usen ACLs) | ❌ `xattr=dir` (por defecto histórico): un inodo extra por atributo, penaliza SELinux y Samba |
| `recordsize` (dataset) | **128K** general; **16K** para PostgreSQL/MySQL (datos); **1M** para ficheros grandes secuenciales (media, backups, imágenes) | Ver §3.2. ❌ Bajar `recordsize` "por si acaso": multiplica metadatos y mata la compresión |
| `volblocksize` (zvol) | **16K** (default desde OpenZFS 2.2) sobre mirrors; sobre RAIDZ, calcular el padding antes (§3.2) | ❌ Fijarlo tras crear el zvol: **solo se aplica en la creación**, hay que recrear y migrar |
| `sync` | **`sync=standard`** siempre | ❌ **`sync=disabled`**: bala en el pie. El pool no se corrompe, pero la aplicación pierde escrituras que creyó confirmadas — inaceptable en BD, NFS o hipervisor |
| Deduplicación | **`dedup=off`**. La *fast dedup* de 2.3+ mejora el mecanismo, **no cambia la recomendación** | Solo con ratio medido **>2:1** (`zdb -S`), `dedup_table_quota` fijado y DDT en `dedup` vdev dedicado. `feature@fast_dedup` es **upgrade de pool irreversible** (no importable por 2.2.x). ❌ Dedup legacy (sin migración a fast dedup) |
| SLOG | **No, por defecto.** Solo si hay escrituras **síncronas** medidas (NFS con `sync`, zvols de VM, BD) | SSD/NVMe con **PLP (power-loss protection)**, en mirror. ❌ SSD de consumo sin PLP como SLOG: pierde exactamente lo que venía a proteger. ❌ SLOG para acelerar escrituras asíncronas: no hace nada |
| L2ARC | **No, por defecto.** Casi nunca es la respuesta: **más RAM primero** | Solo con working set >> RAM, `arcstat` mostrando *miss* alto sostenido y ≥64 GB de RAM. Sus cabeceras **consumen ARC**: en máquinas pequeñas empeora el rendimiento |
| `special` vdev | Solo con **la misma redundancia que el pool de datos** (mirror de 2–3) | **Su pérdida se lleva el pool entero.** Útil para metadatos y `special_small_blocks` en pools RAIDZ de HDD. ❌ `special` vdev de un solo dispositivo. ❌ Añadirlo sin plan de sustitución |
| Módulo en Linux | **kmod empaquetado por la distro** (Proxmox VE, Ubuntu `zfs-linux`, RHEL `kmod-zfs`) | `zfs-dkms` solo si no hay kmod, **con el kernel pineado** (§3.6). ❌ `zfs-dkms` en un host Proxmox (el kernel ya trae ZFS) |
| Cifrado en reposo | **LUKS debajo** cuando lo único que se necesita es cifrado de disco completo | **Cifrado nativo** cuando se necesita cifrado por dataset o `raw send` a un destino no confiable — con las salvedades de §5 |
| Ocupación máxima | **80 %** como umbral de alerta, 85 % como techo operativo | ❌ Pools por encima del 90 %: el asignador cambia de estrategia, la fragmentación se dispara y el rendimiento cae en escalón |

## 3. Diseño y operación

### 3.1 Topología: lo que no se cambia

- **El vdev es la unidad de redundancia y de fallo.** Un pool muere si muere *cualquiera* de sus
  vdevs. Corolario: añadir un vdev sin redundancia a un pool redundante degrada **todo** el pool.
- **Mirrors vs RAIDZ — el criterio real es IOPS y tiempo de resilver, no espacio útil**:
  - Un vdev RAIDZ da los **IOPS de un solo disco**, independientemente de su anchura. Un pool de
    N mirrors da N veces los IOPS de un disco. Para VMs, bases de datos o cualquier carga aleatoria,
    **mirrors**.
  - El resilver de un mirror copia disco a disco. El de un RAIDZ **lee todos los discos
    supervivientes** y reconstruye: con discos de 18–24 TB son días, y durante esos días la
    redundancia está consumida y los discos hermanos (misma edad, mismo lote) están al máximo.
  - **RAIDZ1 con discos grandes es una apuesta perdida**: la ventana de reconstrucción es tan larga
    y el estrés tan alto que el segundo fallo (o un URE) deja de ser improbable. Prohibido en prod
    con discos ≥2 TB (coherente con `onprem-standards` §2 y §7).
- **Anchura**: RAIDZ2 de 6–10. Más ancho no da IOPS, solo alarga el resilver. Varios vdevs
  estrechos > un vdev ancho.
- **`ashift` se fija al crear el vdev y no se cambia jamás.** Fíjalo explícitamente
  (`zpool create -o ashift=12`) y verifícalo con `zdb -C`. Un pool con `ashift=9` sobre discos 4Kn
  o SSD tiene amplificación de escritura permanente.
- **Homogeneidad**: todos los vdevs de un pool con la misma topología y tamaño. Un pool con un
  mirror y un RAIDZ2 mezclados hereda lo peor de ambos y desequilibra la asignación.
- **dRAID**: solo tiene sentido a partir de decenas de discos (spare distribuido → resilver
  secuencial en horas en vez de días). Por debajo de ~20 discos, complejidad sin retorno.

### 3.2 `recordsize`, `volblocksize` y padding en RAIDZ

- `recordsize` es un **máximo**, no un tamaño fijo: los ficheros pequeños usan bloques menores.
  Es cambiable en caliente pero **solo afecta a los bloques nuevos**; para reescribir lo existente,
  `zfs rewrite` (§3.3) — verificando el resultado, porque hay reportes de que no siempre aplica el
  nuevo `recordsize` (§8).
- **Bases de datos**: `recordsize` alineado al tamaño de página del motor, típicamente **16K** para
  PostgreSQL (páginas de 8K; 16K comprime mejor que dos de 8K y evita la amplificación de lectura
  del default de 128K). Dataset separado para el WAL con **`recordsize=128K`** y
  `logbias=throughput`, porque es escritura secuencial. **El `shared_buffers`, el
  `full_page_writes` y el plan de PITR son de `data-platform-standards`**; aquí solo el layout de
  datasets y el tamaño de bloque.
- **Ficheros grandes secuenciales** (media, imágenes de backup, objetos): `recordsize=1M`. Menos
  metadatos, mejor compresión, menos IOPS.
- **`volblocksize` en zvol**: default **16K** desde OpenZFS 2.2, se aplica **solo en la creación**.
  Cambiarlo exige crear un zvol nuevo y migrar el contenido.
- **El desperdicio de RAIDZ con bloques pequeños es real y se calcula antes, no después.** ZFS
  redondea la asignación a múltiplos de (paridad+1) sectores; con `volblocksize` pequeño sobre
  RAIDZ el *padding* puede costar tanto como la paridad. Ejemplo documentado: RAIDZ1 de 4 discos,
  `ashift=12`, `volblocksize=8K` → 25 % a paridad **y otro 25 % a padding**; lo que ZFS reporta como
  1,5 TB útiles almacena 1 TB de datos del invitado. **Zvols de VM y bases de datos van sobre
  mirrors**; si tienen que ir sobre RAIDZ, calcula el overhead con la tabla de anchura de stripe de
  RAIDZ (Delphix/Ahrens) **antes** de crear el pool.
- `primarycache=metadata` solo en datasets cuya caché ya la hace la aplicación (p. ej. el buffer
  pool de la BD) y con medición previa. Por defecto, `all`.

### 3.3 Integridad y operación

- **Scrub programado y vigilado**: mensual en HDD, trimestral en SSD/NVMe. `zpool scrub -a` (2.4+)
  cubre todos los pools importados. Un scrub que no se vigila no sirve: la alerta es sobre
  `zpool status`, no sobre que el cron se ejecutara.
- **`zpool status` se lee con criterio**, no buscando la palabra `ONLINE`:
  - `DEGRADED` → actúa hoy, no mañana. `FAULTED`/`UNAVAIL` → redundancia consumida.
  - Columnas `READ`/`WRITE`/`CKSUM` **distintas de cero son un hallazgo aunque el pool esté
    `ONLINE`**: errores de checksum recurrentes en un disco anticipan su muerte o apuntan a cable,
    backplane, HBA o RAM sin ECC.
  - `zpool status -v` lista los ficheros afectados por corrupción no reparable.
  - Tras un resilver o expansión, `scan:`/`expand:` informan del progreso y de si terminó.
- **ZED (`zfs-zed`) activo y con notificación real** (`/etc/zfs/zed.d/zed.rc`): sin ZED nadie se
  entera de un `DEGRADED` hasta que falla el segundo disco.
- **SMART como señal previa**: `smartd` con self-test corto semanal y largo mensual; el disco se
  sustituye por tendencia (sectores reasignados, pendientes, errores CRC), no por muerte.
- **Sustitución de disco**: `zpool replace pool <viejo> <nuevo>`. Con hueco físico disponible,
  conectar el nuevo **antes** de retirar el viejo (resilver sin degradar). Identifica los discos por
  `/dev/disk/by-id/` — **nunca por `/dev/sdX`**, que se reordena en el arranque.
- **Hot spares**: útiles solo si hay `autoreplace=on` y ZED los activa. Un spare que exige
  intervención manual no aporta nada sobre un disco en el estante. En pools de mirrors pequeños,
  un tercer disco en mirror suele ser mejor uso del mismo hardware.
- **Hardware RAID debajo de ZFS rompe el modelo de integridad**, sin matices: ZFS deja de ver los
  discos individuales, no puede reparar desde la copia redundante (solo detecta), la caché de la
  controladora miente sobre las barreras de escritura y el resilver deja de ser inteligente.
  **HBA en modo IT/JBOD o nada.**
- **RAM ECC**: ZFS detecta corrupción en disco, no en memoria. Sin ECC, un bit volteado se escribe
  con checksum correcto. No es negociable en un sistema de almacenamiento de producción.
- **`zpool import` tras desastre**: `zpool import` sin argumentos enumera lo importable;
  `-d /dev/disk/by-id` cuando los nombres cambiaron; `-f` tras un fallo de host; `-R /mnt` para
  importar en un raíz alternativo sin pisar montajes; `-o readonly=on` **como primer intento
  siempre** ante un pool sospechoso. `-F`/`-X` (rewind) son destructivos: descartan transacciones.
  Antes de usarlos, imagen forense o copia — y consulta antes de improvisar.
- **Expansión: qué se puede y qué no**:
  - ✅ Añadir un vdev nuevo al pool (crece, **no rebalancea**: los datos viejos siguen donde
    estaban y el vdev nuevo se lleva las escrituras).
  - ✅ Sustituir todos los discos de un vdev por otros mayores (con `autoexpand=on`, crece al
    terminar el último resilver).
  - ✅ **RAIDZ expansion** (`zpool attach` sobre un vdev RAIDZ, desde OpenZFS **2.3.0**): añade un
    disco a un vdev RAIDZ existente, online, reanudable e incluso resistente a un fallo de disco
    durante el reflow. **Límites reales**: no cambia el nivel de RAIDZ (un RAIDZ1 no se convierte en
    RAIDZ2), y **no reescribe los datos existentes** — los bloques antiguos conservan su ratio
    datos/paridad original, solo repartidos sobre más discos. La eficiencia prometida solo se
    obtiene en lo que se escriba después, y `zfs list`/`df` reportan menos espacio del esperado para
    los bloques nuevos (comportamiento documentado, no un bug). Para recuperar el ratio hay que
    reescribir: **`zfs rewrite`** (llegó en **2.3.4**) o send/recv a un dataset nuevo.
  - ❌ Quitar un disco de un vdev RAIDZ, estrecharlo o cambiar su nivel.
  - ❌ Quitar un vdev de datos de un pool con RAIDZ (`zpool remove` solo soporta top-level de
    mirror/single en pools sin RAIDZ).
  - ❌ Cambiar `ashift`.
- **`zfs rewrite`** (2.3.4+): reescribe ficheros in-situ para aplicar la configuración actual del
  pool (rebalanceo tras añadir vdev o expandir RAIDZ, defragmentación, cambio de compresión).
  Aviso operativo: **los snapshots existentes fijan los bloques viejos**, así que la reescritura
  duplica el espacio hasta que se liberen; pausa la política de snapshots automáticos durante la
  operación y ten holgura de capacidad.

### 3.4 ARC y memoria

- **El "1 GB de RAM por TB de pool" es folclore**, no criterio. El tamaño correcto del ARC lo
  determina el **working set** y el ratio de acierto medido, no la capacidad del pool. Un archivo
  frío de 200 TB funciona con 32 GB; una BD de 2 TB con acceso aleatorio puede querer más.
  **La única excepción donde la regla sigue viva —y se queda corta— es la deduplicación**: la DDT
  debe residir en memoria y pide bastante más de 1 GB/TB. Es una razón más para `dedup=off`.
- **Desde OpenZFS 2.3 el ARC por defecto crece casi hasta toda la RAM** (`max(RAM − 1 GB,
  5/8 × RAM)`), frente al 50 % de versiones anteriores. En un host que **solo** sirve
  almacenamiento eso está bien; en un hipervisor o en un host con aplicaciones, **hay que capar**
  `zfs_arc_max` explícitamente o el ARC compite con las VMs y la presión de memoria acaba en el
  OOM killer.
- Se fija **en bytes** en `/etc/modprobe.d/zfs.conf` (`options zfs zfs_arc_max=…`) y se regenera
  el initramfs; en caliente vía `/sys/module/zfs/parameters/zfs_arc_max`. Verifica que quedó
  aplicado: es el error clásico.
- **Con swap configurado siempre**, incluso con RAM de sobra: el ARC no encoge instantáneamente
  bajo presión y sin swap el OOM killer mata la aplicación. **`zvol` como dispositivo de swap está
  prohibido** (deadlock conocido bajo presión de memoria): swap en partición o fichero fuera de ZFS.
- Medir, no adivinar: `zarcstat`/`zarcsummary` (renombrados desde `arcstat`/`arc_summary` en 2.4) y
  `/proc/spl/kstat/zfs/arcstats`. Objetivo de hit ratio >85–90 %; por debajo, el problema es RAM o
  patrón de acceso, no falta de L2ARC.
- **ZFS en máquinas con poca RAM** (<8 GB): funciona, pero con `zfs_arc_max` capado a 1–2 GB, sin
  dedup, sin L2ARC y asumiendo rendimiento modesto. Por debajo de 2 GB de ARC el sistema se
  arrastra: ahí ZFS es la elección equivocada.

### 3.5 Snapshots y replicación (mecanismo, no estrategia)

- **Un snapshot NO es un backup.** Vive en el mismo pool: un fallo de vdev, un `zpool destroy`, un
  ransomware con root o un incendio se lo llevan con el original. El snapshot es *undo* barato y
  punto de consistencia para la copia. **La estrategia de respaldo —qué se copia, adónde, con qué
  retención, inmutabilidad y verificación de restore— es de `backup-recovery-standards` (Ola 2), y
  el RTO/RPO y el orden de recuperación de `bcdr-standards`.** Esta skill solo fija el mecanismo.
- Snapshots recursivos y atómicos por dataset (`zfs snapshot -r`); nomenclatura con timestamp
  ordenable (`autosnap_2026-08-02_00:00:00_daily`).
- **Retención automatizada, nunca manual.** Herramientas con mantenimiento verificado (ago-2026):
  - **sanoid/syncoid** (jimsalterjrs/sanoid): repo activo (jun-2026), última release v2.3.0
    (jun-2025). Política declarativa en `sanoid.conf`, `syncoid` para el envío. **Por defecto.**
  - **zrepl** (Go, daemon con jobs push/pull, snapshots y poda en un solo binario): activo, v0.7.0
    (feb-2026) tras un parón largo — válido si quieres un daemon en vez de cron+scripts.
  - **zfs-autobackup** (psy0rz): activo (jun-2026), pero su línea actual es **v4.0-beta**: usa la
    estable o asume que estás en beta.
  - ❌ Scripts caseros de retención sin bloqueo ni idempotencia: borran el snapshot equivocado el
    día que importa.
- **Réplica incremental** con `zfs send -i`/`-I` sobre un snapshot base común; `-R` para replicar
  el árbol con propiedades. En el destino, **`zfs recv -F` solo si entiendes que descarta cambios
  locales**. Bookmarks (`#`) cuando quieras poder purgar el snapshot origen conservando el punto de
  partida incremental.
- **Destino en modo lectura**: `readonly=on` en el dataset replicado y, si el destino no es de
  confianza, **`zfs allow` delegando solo lo mínimo** en vez de dar root.
- **Réplica cifrada**: `zfs send -w` (**raw send**) envía los bloques tal cual están cifrados; el
  destino nunca ve la clave ni el texto en claro. Es el modo correcto para replicar a un tercero.
  Ver §5 para el estado de madurez.
- **Verificar la réplica, no suponerla**: la alerta es sobre "edad del último snapshot recibido en
  destino" comparada con el RPO, y periódicamente se **monta y comprueba** el destino. Una réplica
  que nadie ha leído nunca es una hipótesis.

### 3.6 ZFS en Linux: el módulo y la raíz

- **Licencia**: ZFS es CDDL y el kernel es GPLv2; el módulo no puede distribuirse dentro del
  kernel. Consecuencia práctica: **el módulo va siempre fuera del árbol**, se compila contra tu
  kernel y **puede no compilar tras una actualización**. Esto no es un fallo puntual: es la
  condición estructural.
- **kmod (precompilado por la distro) > DKMS**, siempre que exista: el paquete está versionado
  contra el kernel que envía la distro y el gestor de paquetes no los deja divergir. Proxmox VE,
  Ubuntu (`zfs-linux`) y RHEL/EL (`kmod-zfs` de OpenZFS) lo ofrecen. **En Proxmox VE no se instala
  `zfs-dkms`**: el kernel ya trae ZFS y añadirlo rompe.
- **Si es obligatorio DKMS**, el procedimiento es no negociable:
  1. `apt-mark hold` (o equivalente) sobre el metapaquete de kernel/headers hasta comprobar que la
     versión de OpenZFS instalada soporta ese kernel — **el rango soportado se consulta en las
     release notes, no de memoria** (2.4.3: 4.18–7.0).
  2. Tras el upgrade y **antes de reiniciar**: `dkms status zfs` debe decir `installed` para el
     kernel **nuevo**, no `added`.
  3. Conservar el kernel anterior arrancable en GRUB; nunca `autoremove` el último bueno.
  4. En ZFS-on-root, regenerar el initramfs y no reiniciar sin acceso a consola OOB o KVM.
- **ZFS on root**: viable y usado en producción (Proxmox, Ubuntu), pero eleva el fallo de módulo de
  "el pool de datos no monta" a "el sistema no arranca". Exige: consola out-of-band, kernel de
  rescate, `bpool` separado si el bootloader no soporta todas las features, y **no activar features
  de pool nuevas en el pool de arranque sin comprobar que el bootloader las entiende**.
- **`zpool upgrade` es irreversible**: activa features que impiden importar el pool con versiones
  anteriores de ZFS (y con otro SO). No se ejecuta "porque `zpool status` lo sugiere": se ejecuta
  cuando necesitas una feature concreta y has verificado que **todos** los sistemas que deben
  importar ese pool (incluido el live-USB de rescate y el destino de réplica) la soportan.

### 3.7 Capacidad

- **Por encima del ~80 % el pool se degrada.** ZFS es copy-on-write: sin espacio libre contiguo no
  hay dónde escribir bloques nuevos y el asignador pasa de *first-fit* a *best-fit*, lo que dispara
  la latencia. Por encima del 90 % la caída es un escalón, no una pendiente.
- **La fragmentación no se defragmenta con una herramienta**: `zpool list` muestra `FRAG` (del
  espacio libre, no de los datos). Se corrige liberando espacio, reescribiendo (`zfs rewrite`) o
  con send/recv a un pool nuevo. Prevenirla es más barato que arreglarla.
- **Alerta de capacidad con predicción**, no con umbral fijo: avisar al 75–80 % con tiempo estimado
  hasta el llenado. Un pool ZFS lleno al 100 % puede impedir incluso **borrar** ficheros (borrar
  requiere escribir metadatos); la salida de emergencia es destruir un snapshot o una reserva.
- **`refreservation` en zvols de VM y `quota`/`reservation` por dataset**: sin ellas, un dataset se
  come el pool y tumba a todos los demás. Un dataset con `quota` no es un dataset aislado: reserva
  también (`reservation`) lo que no puede permitirse perder.
- `zfs list -o space` para entender a dónde se ha ido el espacio (`USEDSNAP`, `USEDREFRESERV`);
  `df` **miente** sobre ZFS.

## 4. Gates: lo que hay que demostrar

Un pool ZFS no está "en producción" hasta que estos cuatro puntos están demostrados, con evidencia
y fecha, no declarados:

1. **Scrub programado Y vigilado.** Timer/cron con `OnCalendar` y `RandomizedDelaySec`, y una
   alerta que dispara si (a) el scrub falla, (b) el último scrub tiene más de N días, o (c) el
   scrub encuentra errores. El gate lo pasa la alerta, no el timer.
2. **Alerta de degradación probada.** ZED activo con notificación que llega a un humano de guardia.
   **Se verifica provocándola** (offline de un disco en un pool de pruebas o `zinject`), no leyendo
   la config.
3. **Sustitución de disco ensayada.** El runbook de `zpool replace` se ha ejecutado al menos una vez
   por un operador distinto del que lo escribió, cronometrando el resilver completo. Si el resilver
   estimado supera la ventana de riesgo aceptable, **la topología está mal elegida** y hay que
   revisarla (§3.1).
4. **Restauración de la réplica verificada.** Se importa el pool destino, se monta el dataset
   replicado y se comprueba el contenido con la aplicación real. Una réplica que solo se ha
   escrito, nunca leído, no cuenta. (La política y la cadencia de esta prueba son de
   `backup-recovery-standards` / `bcdr-standards`; el gate técnico es de aquí.)

Adicionales, exigibles en cualquier revisión:
- `zdb -C | grep ashift` coincide con el hardware; `zpool status -v` limpio y `CKSUM=0`.
- Exporter de ZFS (node_exporter con colector zfs, o `zfs_exporter`) publicando estado de pool,
  capacidad, `FRAG`, ARC hit ratio, edad del último scrub y edad del último snapshot replicado.
- Discos referenciados por `by-id` en cualquier script o documentación; ninguno por `/dev/sdX`.
- Prueba de arranque tras actualizar kernel en un host ZFS-on-root, hecha en preproducción antes
  que en producción.

## 5. Seguridad

- **Cifrado nativo — estado real (ago-2026)**: el histórico de corrupción con `send`/`recv` sobre
  datasets cifrados (issues #12014 y #11688, abiertos desde 2021) se cerró con **PR #17340**,
  incluido a partir de **2.2.8 / 2.3.3**; FreeBSD lo distribuyó como errata (FreeBSD-EN-25:10.zfs).
  Criterio: **usable a partir de 2.3.3/2.4.x**, con dos matices que no se omiten —
  (a) los fallos estaban en el **send no-raw** desde datasets cifrados: **prefiere siempre
  `zfs send -w`**; (b) la documentación de Proxmox VE seguía marcando el cifrado nativo como
  *experimental* con limitaciones conocidas en replicación de datasets cifrados. Antes de
  recomendarlo en un sistema concreto, **verifica el estado en la versión exacta y en la distro
  exacta** (§8). Con LUKS por debajo tienes una alternativa madura si no necesitas cifrado por
  dataset ni raw send.
- **Lo que el cifrado nativo NO cifra**: nombres de dataset, tamaños, propiedades y la propia
  topología del pool. Si el modelo de amenaza incluye metadatos, es LUKS.
- **Custodia de la clave**: `keylocation` nunca apuntando a un fichero dentro del propio pool
  cifrado (dependencia circular: sin clave no montas, y la clave está dentro). Clave en gestor de
  secretos o TPM, **y una copia custodiada fuera del sistema respaldado** — un backup cifrado sin
  clave es pérdida total. La elección de algoritmo y la política de custodia son de
  `cryptography-pki-standards` y `secrets-management-standards`.
- **Delegación con `zfs allow`** en lugar de root: el agente que replica solo necesita
  `send,snapshot,hold` en origen y `receive,create,mount` en destino. Root para un job de
  replicación es privilegio innecesario y superficie de ransomware.
- **Snapshots como mitigación de ransomware — con límites**: son de solo lectura y ayudan, pero un
  atacante con root en el host **puede destruirlos**. La protección real es la copia **fuera del
  host** e inmutable (dominio de `backup-recovery-standards`/`bcdr-standards`). `zfs hold` sobre
  snapshots críticos añade fricción, no una frontera de seguridad.
- **Propiedades de montaje como control de seguridad** (`exec=off`, `setuid=off`, `devices=off` en
  datasets de datos, `/home`, `/var/tmp`): el criterio y el baseline son de
  `linux-hardening-standards`; aquí se registra que en ZFS se expresan como **propiedades del
  dataset**, no como opciones de `fstab`, y que ese es el punto donde se aplican.
- **CVEs**: no consta ninguna vulnerabilidad relevante específica de OpenZFS en 2025-2026 en las
  fuentes consultadas, pero el canal correcto son los avisos de la distro (`zfs-linux`,
  `kmod-zfs`), no la ausencia de noticias. Ver §8.

## 6. Rendimiento y observabilidad

- **Métricas mínimas por pool**: estado (`ONLINE`/`DEGRADED`/`FAULTED`), capacidad usada, `FRAG`,
  errores READ/WRITE/CKSUM por vdev, progreso y antigüedad del último scrub, antigüedad del último
  snapshot y del último snapshot **recibido** en destino, ARC size y hit ratio, latencia por vdev.
  El diseño de las alertas y sus umbrales es de `observability-standards`; **qué** hay que exponer
  es de aquí.
- **Alertas accionables**: pool no `ONLINE`; cualquier contador CKSUM creciente; scrub con
  antigüedad > cadencia + margen; capacidad > 80 %; réplica retrasada respecto al RPO; SMART con
  sectores reasignados/pendientes creciendo. Sin runbook enlazado, la alerta sobra.
- **Diagnóstico**: `zpool iostat -vl 1` (latencia desglosada por vdev y por cola: disk_wait,
  syncq_wait, asyncq_wait) es la primera herramienta, no `iostat` del host — te dice si el problema
  es el disco, la cola de sync o el trim. `zpool iostat -r` para la distribución de tamaños de
  petición.
- **Antes de tocar un tunable**, mide. Los `module parameters` de ZFS (`zfs_txg_timeout`,
  `zfs_vdev_*_max_active`, `zfs_dirty_data_max`) resuelven problemas concretos y **crean otros** si
  se copian de un blog. Cambio con hipótesis, medición antes y después, y registro de por qué.
- **`autotrim=on`** en pools de SSD/NVMe, o `zpool trim` periódico. Sin TRIM el rendimiento de
  escritura de un pool flash se degrada con el uso.
- **Réplica sobre red**: `syncoid` con compresión y `mbuffer` en enlaces WAN; en LAN de 10G+ la
  compresión suele ser el cuello de botella, no el enlace. Mide antes de asumir.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Seguir la rama estable soportada; **planificar la salida de una rama antes de su EOL**, no
  después (2.2 EOL 18-dic-2025). Antes de cada upgrade de OpenZFS: leer release notes y confirmar
  el rango de kernel soportado.
- Antes de cada upgrade de kernel en host con DKMS: comprobar compatibilidad (§3.6). En host con
  kmod, comprobar que el paquete del módulo acompaña al kernel en el mismo repositorio.
- `zpool upgrade` solo cuando se necesita una feature y **todos** los consumidores del pool
  (rescate, destino de réplica, otro SO) la soportan.
- Revisión trimestral de: capacidad y tendencia, antigüedad de discos por lote, `FRAG`, y si la
  topología sigue siendo la adecuada para la carga actual.

**PROHIBIDO**
- ❌ **RAIDZ1 con discos ≥2 TB** en producción. ❌ vdev sin redundancia en un pool con datos.
- ❌ **Hardware RAID (o cualquier controladora con caché no pasante) por debajo de ZFS.** HBA en
  IT/JBOD o nada.
- ❌ Sistema con ZFS montado **sobre LVM o mdadm**: ZFS necesita los discos crudos; apilarlo sobre
  otro gestor de volúmenes le quita la información que usa para reparar y añade una capa de fallo.
- ❌ Crear un pool sin fijar `ashift` explícitamente y sin verificarlo después.
- ❌ **`sync=disabled`** en cualquier dataset con datos que importen.
- ❌ **`dedup=on`** sin ratio medido >2:1, sin `dedup_table_quota` y sin RAM sobrada. La *fast
  dedup* no cambia esto.
- ❌ SLOG sin PLP, SLOG no espejado en cargas críticas, o SLOG "para acelerar" escrituras
  asíncronas (no hace nada).
- ❌ `special` vdev sin redundancia: su pérdida destruye el pool completo.
- ❌ L2ARC antes de haber agotado la ampliación de RAM.
- ❌ Referenciar discos por `/dev/sdX` en pools, scripts o documentación.
- ❌ Snapshots presentados como backup. ❌ Réplica cuyo restore nunca se ha probado.
- ❌ Ejecutar `zpool import -F`/`-X` como primer intento ante un pool sospechoso, o sin copia previa.
- ❌ `zfs-dkms` sin kernel pineado, o reiniciar tras upgrade de kernel sin verificar `dkms status`.
- ❌ `zfs-dkms` instalado en Proxmox VE.
- ❌ Pools por encima del 80 % sin plan de crecimiento fechado; pools al 90 % operando "normal".
- ❌ ZFS en producción **sin RAM ECC**.
- ❌ **zvol como dispositivo de swap** (deadlock conocido bajo presión de memoria).
- ❌ Usar ZFS como filesystem compartido de cluster (dos nodos importando el mismo pool):
  **ZFS no es cluster-aware**; el import simultáneo destruye el pool. Ver `ha-clustering-standards`.
- ❌ Copiar tunables de módulo de un blog sin medición previa y posterior.
- ❌ Ejecutar `zpool upgrade` "porque lo sugiere `zpool status`".

## 8. Verificación web obligatoria

Verificado a **agosto 2026** (y qué hay que re-verificar):
1. **Versión y ramas de OpenZFS**: 2.4.3 y 2.3.8 (ambas 12-jun-2026); 2.2 EOL 18-dic-2025.
   **Rango de kernel soportado en 2.4.3: Linux 4.18–7.0, FreeBSD 13.3+/14.0+** — este es el dato
   que rompe sistemas y caduca cada release. Fuente: `api.github.com/repos/openzfs/zfs/releases`
   o los feeds Atom. **Nunca del render HTML de GitHub Releases**: el resumidor inventa el año.
2. **RAIDZ expansion**: llegó en 2.3.0; no rebalancea ni cambia el nivel de RAIDZ. Confirmar si
   alguna versión posterior ha añadido rebalanceo automático.
3. **Fast dedup**: en 2.3.0 (DDT log, prefetch, pruning, `dedup_table_quota`). La recomendación
   sigue siendo **no usar dedup**, sostenida por los propios autores de la feature. Re-verificar si
   eso cambia.
4. **`zfs rewrite`**: llegó en **2.3.4** (no en 2.4, como suele recordarse mal). **Hueco declarado**:
   no está verificado de forma concluyente si `zfs rewrite` aplica un `recordsize` nuevo a ficheros
   existentes — hay reportes de que no. **Probar en un dataset de test antes de planificar sobre
   ello.**
5. **Cifrado nativo**: #12014/#11688 cerrados por PR #17340, incluido en 2.2.8/2.3.3. **Hueco
   declarado**: no verificado el estado *actual* de la documentación de Proxmox VE (que lo marcaba
   como experimental) ni si hay incidencias abiertas posteriores a 2.3.3. Verificar en el issue
   tracker de openzfs/zfs y en la doc de la distro antes de recomendarlo sin matices.
6. **Herramientas de replicación** (mantenimiento real, no popularidad): sanoid/syncoid activo
   (repo jun-2026, release v2.3.0 de jun-2025), zrepl v0.7.0 (feb-2026), zfs-autobackup en
   v4.0-beta (jun-2026). Re-verificar por `api.github.com/repos/<org>/<repo>` (campos `pushed_at`,
   `archived`) antes de adoptar.
7. **ARC por defecto**: desde 2.3 es `max(RAM − 1 GB, 5/8 × RAM)`. Confirmar en la versión exacta
   antes de dimensionar un hipervisor.
8. **CVEs**: consultar avisos de la distro (`zfs-linux`, `kmod-zfs`) y GitHub Security Advisories
   de `openzfs/zfs`. **Hueco declarado**: la búsqueda de ago-2026 no encontró CVE relevante de
   OpenZFS en 2025-2026, pero la ausencia de resultados **no es una verificación negativa**:
   comprobar en NVD y en el tracker de la distro antes de afirmarlo.
9. **Compatibilidad cruzada** antes de cualquier upgrade: kernel ↔ OpenZFS, versión de OpenZFS ↔
   features del pool ↔ bootloader (ZFS-on-root) ↔ versión del destino de réplica.
10. **`volblocksize`/`recordsize` óptimos**: la tabla de overhead de RAIDZ (anchura de stripe,
    Ahrens/Delphix) y el default vigente de `volblocksize` (16K desde 2.2) antes de crear zvols
    sobre RAIDZ.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
