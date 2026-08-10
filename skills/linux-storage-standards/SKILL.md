---
name: linux-storage-standards
description: Linux block storage and traditional filesystems, everything except ZFS. Use when working with LVM (pvcreate, vgcreate, lvcreate, lvextend, lvresize, pvmove, lvmthin thin pools, thin_pool_autoextend_threshold, lvm.conf, dmeventd), mdadm software RAID (--consistency-policy ppl/journal, write-intent bitmap, /proc/mdstat, mdadm.conf), ext4/XFS/btrfs (mkfs.ext4, mkfs.xfs, xfs_growfs, xfs_repair, xfs_info, resize2fs, tune2fs, e2fsck, dumpe2fs, btrfs subvolume/scrub/balance), mount options (noatime, discard, nofail, x-systemd.device-timeout), fstrim.timer, blkid, lsblk, partitioning with parted/sgdisk, NVMe and SSD wear (nvme-cli, smartctl, over-provisioning, /sys/block/*/queue/scheduler none vs mq-deadline vs bfq, nr_requests), device-mapper multipath (multipath -ll, multipath.conf, /dev/mapper aliases), iSCSI initiator (iscsiadm, open-iscsi, node.session.timeo), NFS client mounts (hard vs soft, timeo, retrans, nconnect), LUKS/dm-crypt (cryptsetup, crypttab, luksFormat, argon2id), disk quotas, inode exhaustion, df versus du discrepancies, and I/O diagnosis or benchmarking with iostat, iotop, blktrace, biolatency or fio.
---

# Estándares de almacenamiento en Linux (capa de bloques y filesystems)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: el almacenamiento en Linux es **una pila de capas**, y casi todo diagnóstico
> equivocado nace de tratarla como una sola. "El disco va lento" rara vez es el disco. Antes de
> tocar nada, **sitúa el problema en su capa**.

## 1. Alcance y triggers

Aplica a todo el almacenamiento local y de bloques de un host Linux **que no sea ZFS**: la pila de
dispositivo a aplicación, LVM, RAID por software, filesystems tradicionales (ext4, XFS, btrfs),
NVMe/SSD, multipath, iSCSI y NFS **desde el cliente**, cifrado en reposo con LUKS, cuotas,
capacidad, y el diagnóstico y la medición de I/O.

Disparadores: `lsblk`, `blkid`, `pvs`/`vgs`/`lvs`, `lvm.conf`, `mdadm`, `/proc/mdstat`, `mkfs.*`,
`xfs_*`, `resize2fs`, `tune2fs`, `btrfs`, `/etc/fstab` (la línea de un filesystem),
`fstrim.timer`, `nvme`, `smartctl`, `multipath.conf`, `iscsiadm`, `cryptsetup`, `/etc/crypttab`,
`iostat`, `fio`, `blktrace`, "no queda espacio", "inodos agotados", "df y du no coinciden".

**Regla de arbitraje interna**: si la pregunta se responde con `lvs`, `mdadm`, `mkfs` o `mount`, es
de esta skill. Si se responde con `zpool` o `zfs`, es de `zfs-standards`.

**No aplica**: ver `zfs-standards` (**la frontera hermana**: pools, vdevs, `ashift`, `recordsize`,
`volblocksize`, snapshots, `zfs send`, ARC, scrub, cifrado nativo. **Un sistema con ZFS no lleva
LVM ni mdadm debajo**: ZFS es a la vez gestor de volúmenes y filesystem y exige los discos crudos
tras un HBA en modo IT — apilarlo sobre `md` o sobre un LV le quita la información con la que
repara. Si en un diagrama aparecen `zpool` y `vgcreate` sobre los mismos discos, el diseño está
mal. La única convivencia legítima es tener ambos mundos en **discos distintos** del mismo host,
p. ej. raíz en LVM+ext4 y datos en ZFS), `linux-administration-standards` (**la más próxima; la
frontera es qué se pregunta, no qué fichero se toca**: el **modelo de systemd** —`fstab` frente a
unidades `.mount`, generadores, `x-systemd.*`, orden de arranque, `autofs`, `emergency.target` y la
recuperación de un host que no arranca, `systemd-cgtop`, `IOWeight=`, retención de journald— es
**suyo**; **el contenido de la línea**: qué filesystem, con qué parámetros de creación, sobre qué
capa de bloques, con qué opciones por rendimiento y cómo se dimensiona y se hace crecer, es
**de aquí**. En una línea: **"¿por qué no monta en el arranque?" es suyo; "¿por qué va lento y
cómo lo agrando?" es de aquí.** Y `iostat` aparece en ambas: allí como parte del triaje general de
un host lento, aquí como herramienta de atribución dentro de la pila de bloques),
`onprem-standards` (paraguas de plataforma; su §2 fija el criterio de filesystem y su §1.3 los
invariantes), `homelab-standards` (btrfs con snapshots y su tooling en **laboratorio personal**,
donde el criterio es coste, ruido y consumo; aquí btrfs se juzga por estabilidad de feature en
producción, §3.4), `bcdr-standards` (RTO/RPO, orden de recuperación, ejercicios de DR),
`backup-recovery-standards` (herramienta de copia, repositorio, retención,
inmutabilidad y procedimiento de restore; **un snapshot de LVM o de btrfs no es un backup**, §3.2 y
§3.4: aquí se dan como mecanismo de punto de consistencia, nunca como estrategia de respaldo),
`data-platform-standards` (**el motor de datos encima**: el filesystem, su alineación y el layout
de LV donde vive PostgreSQL son **de aquí**; `shared_buffers`, `wal_*`, índices, PITR y réplica son
**suyos**), `linux-hardening-standards` (**`noexec`/`nosuid`/`nodev` y la separación de particiones
como control CIS son suyas**; aquí las mismas opciones de montaje **por criterio de rendimiento y
layout** — si la pregunta es "¿qué exige el benchmark?", es allí; si es "¿me penaliza `noatime`?",
es aquí), `cryptography-pki-standards` (elección de algoritmo, KDF y **custodia de las claves** de
LUKS; aquí solo el uso operativo del volumen cifrado), `secrets-management-standards` (dónde vive
la clave de desbloqueo desatendido), `kubernetes-standards` (CSI, PV/PVC, StorageClass y modos de
acceso — la frontera es el nodo: el disco y el filesystem del nodo son de aquí, el volumen que el
CSI presenta al pod es suyo), `observability-standards` (diseño de métricas y alertas; aquí **qué**
hay que vigilar), `incident-response-forensics-standards` (adquisición de imagen forense y cadena
de custodia: si el objetivo es preservar evidencia, manda allí — aquí el diagnóstico y la
reparación, que **destruyen evidencia**), `proxmox-ve-standards` y `libvirt-kvm-standards`
(almacenamiento de VMs — el LV o el fichero de imagen y su alineación son
de aquí, el modelo de caché del disco virtual y su definición son suyos), `ha-clustering-standards`
(almacenamiento **compartido** — cluster LVM, GFS2/OCFS2, fencing y quórum;
aquí el almacenamiento **de un host**), `object-storage-standards` (S3 y su
modelo de consistencia y durabilidad, radicalmente distinto al de bloques — no se diseña un sistema
de objetos con criterio de filesystem), `file-servers-standards` (**el protocolo de compartición de
ficheros y su exposición**: `smb.conf` y `/etc/exports`, dialecto, mapeo de identidad, ACL del
recurso publicado y su auditoría — **si la respuesta se escribe en `/etc/exports`, es suya**; aquí
el **lado cliente** del montaje NFS y todo el bloque, incluido el `target` iSCSI de `targetcli`,
que no es compartición de ficheros sino un disco crudo con un solo dueño),
`networking-standards` (la red que sostiene iSCSI/NFS:
VLAN, MTU/jumbo frames, rutas; aquí el lado cliente y sus timeouts).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de cada feature por web antes de fijarla (§8).

| Ámbito | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Filesystem general | **XFS** (default de la familia RHEL desde RHEL 7 y hasta RHEL 10) | **ext4** si necesitas **reducir** el filesystem, o en cargas de muchos ficheros pequeños. ❌ Elegir "porque siempre uso ext4" sin mirar §3.4 |
| Filesystem si hay que encoger | **ext4** — **XFS no se puede reducir, punto** (`xfs_growfs` solo crece; no hay shrink online ni en el roadmap upstream a kernel 7.0) | ❌ Planificar un XFS "ya lo encogeremos": el único camino es dump + `mkfs` + restore |
| btrfs | Solo con **perfiles single/DUP/RAID1/RAID1C3/RAID1C4**; útil si quieres snapshots y checksums sin ZFS | ❌ **btrfs RAID5/RAID6**: la documentación del proyecto lo marca **unstable** y el formato en disco sigue sin finalizar (estado a kernel 7.1). Ver §3.4 |
| Gestor de volúmenes | **LVM** cuando haya que crecer, mover en caliente o repartir un pool de discos; **sin LVM** si es un disco y un filesystem que nunca cambian | ❌ LVM "por costumbre" en una VM de un disco: capa extra, más piezas, cero beneficio (§3.2) |
| LVM thin | Solo con `thin_pool_autoextend_threshold` **< 100** (típico 80) y `lvm2-monitor`/`dmeventd` activo y **monitorizado** | ❌ Sobreaprovisionar sin alerta de ocupación del pool: **llenar un thin pool corrompe y puede ser irreparable** (§3.2) |
| RAID por software | **mdadm RAID10** para datos que importan; **RAID1** para raíz/arranque | **RAID6** si manda la capacidad. ❌ **RAID5 con discos grandes** (coherente con `onprem-standards` §7). ❌ RAID0 en producción |
| Write hole de RAID5/6 | `--consistency-policy=ppl` (RAID5) o journal en SSD espejadas (RAID4/5/6) | ❌ Creer que el **write-intent bitmap cierra el write hole**: solo acelera el resync. Ver §3.3 |
| Planificador de I/O | **`none`** en NVMe (y es el default del kernel para NVMe) | **`mq-deadline`** en SATA SSD/HDD con carga mixta, y en NVMe **solo** si mides que la latencia de cola (p99/p999) mejora. `bfq` en escritorio/interactivo. ❌ Cambiarlo sin medir antes y después |
| TRIM | **`fstrim.timer`** semanal (`systemctl enable --now fstrim.timer`) | ❌ Opción de montaje **`discard`** en XFS (el propio `xfs(5)` lo desaconseja: impacto "quite severe") y en ext4. En **btrfs**, `discard=async` sí es alternativa válida. ❌ TRIM continuo sobre LUN thin de SAN |
| `atime` | **`noatime`** (o `relatime`, que ya es el default del kernel) | ❌ `atime` por defecto en filesystems con muchos ficheros o sobre almacenamiento remoto |
| Montaje de volúmenes no críticos | `nofail` + `x-systemd.device-timeout=` | ❌ Entrada de `fstab` sin `nofail` para un disco de datos opcional: **un disco ausente deja el host en `emergency.target`** (el arranque y su recuperación son de `linux-administration-standards`) |
| Identificación de dispositivos | **`UUID=`** en `fstab`/`crypttab`, o `/dev/disk/by-id`; alias del mapper en multipath | ❌ `/dev/sdX` en cualquier fichero persistente: se reordena entre arranques |
| NFS cliente | **`hard`** siempre, con `timeo=600,retrans=2` | ❌ **`soft`** en cargas de escritura: causa **corrupción silenciosa** documentada. `softerr`/`softreval` solo con la aplicación consciente de EIO. `nconnect=4–8` **tras medir** y nunca con `sec=krb5*` |
| Cifrado en reposo | **LUKS2 con `argon2id`** (default upstream de cryptsetup) | `pbkdf2` **solo** en la partición que deba desbloquear GRUB. La política de KDF y la custodia de claves son de `cryptography-pki-standards` |
| Multipath | Activo siempre que el LUN llegue por más de una ruta; **acceso solo por `/dev/mapper/<alias>`** | ❌ Montar `/dev/sdX` cuando existe un mapa multipath: el fallo clásico, §3.6 |

## 3. La pila y sus capas

### 3.1 El stack de bloques

```
aplicación
  └─ filesystem            (ext4 / XFS / btrfs)   ← inodos, journal, fragmentación, lleno
      └─ LUKS / dm-crypt   (opcional)             ← CPU, TRIM, desbloqueo
          └─ LVM  (PV/VG/LV, thin)                ← espacio del VG, thin pool lleno
              └─ mdadm  (RAID por software)       ← degradado, resync, write hole
                  └─ multipath (SAN)              ← rutas caídas, failover
                      └─ dispositivo (SATA/SAS/NVMe/LUN)  ← SMART, desgaste, cola
```

- **El orden importa y no es negociable**: `multipath` va debajo de LVM, **LUKS va encima de
  LVM o debajo, pero se decide una vez** (LUKS-sobre-LV permite cifrar solo algunos volúmenes;
  LVM-sobre-LUKS cifra todo con una sola clave y suele ser lo correcto para un portátil o un host
  entero). Reordenar la pila después implica migrar datos.
- **Diagnóstico: identifica la capa antes de actuar.** `lsblk -o NAME,KNAME,TYPE,SIZE,FSTYPE,MOUNTPOINT`
  muestra la pila real. Una latencia alta en `iostat` sobre `dm-3` con los discos físicos ociosos
  apunta a la capa dm (cifrado, thin, RAID), no al disco.
- **Cada capa añade un modo de fallo y un punto de mentira**: la que menos capas tenga cumpliendo
  el requisito es la correcta (KISS). Toda capa presente debe justificar su existencia.

### 3.2 LVM

- **Cuándo aporta**: hay que crecer en caliente, mover datos entre discos sin parar (`pvmove`),
  agregar varios dispositivos, o separar volúmenes con ciclos de vida distintos.
- **Cuándo es complejidad gratuita**: una VM con un disco virtual y un filesystem, donde el
  hipervisor ya sabe crecer el disco. Ahí LVM solo añade un paso a cada operación.
- **Crecer**: `lvextend -r -L +100G /dev/vg/lv` — el `-r` (`--resizefs`) hace crecer el filesystem
  en el mismo paso, y es **la forma correcta**: hacerlo en dos pasos es donde la gente olvida el
  segundo y luego "el disco no creció". Crecer XFS y ext4 es **online**.
- **Encoger**: **solo ext4 y solo con el filesystem desmontado** (`e2fsck -f`, `resize2fs` al
  tamaño destino, **luego** `lvreduce` a un tamaño **igual o mayor**). Invertir el orden destruye
  datos. **XFS no se encoge nunca** (§2, §3.4). Antes de encoger: backup verificado, no snapshot.
- **Thin provisioning — el riesgo real**: la suma de los LV finos puede exceder el pool; mientras
  hay espacio libre no pasa nada, y el día que se llena **el thin pool puede quedar dañado y ser
  difícil o imposible de reparar**. Requisitos no negociables:
  - `thin_pool_autoextend_threshold` **< 100** (100 lo desactiva; el mínimo aceptado es 50; 80 es
    el valor práctico) y `thin_pool_autoextend_percent` (p. ej. 20) en `lvm.conf`; **con extents
    libres reales en el VG**, porque sin ellos `lvextend --use-policies` no puede hacer nada.
  - `lvm2-monitor` activo y **monitorización habilitada en el pool** (`lvchange --monitor y`): sin
    dmeventd la política no se aplica.
  - **Alerta sobre `Data%` y `Meta%` del pool** (`lvs -o +data_percent,metadata_percent`) — los
    **metadatos se agotan por separado** y su agotamiento devuelve errores de I/O igual que los
    datos. Es el olvido clásico.
  - Comportamiento ante pool lleno configurado a conciencia: `--errorwhenfull y|n` (el default `n`
    encola escrituras ~60 s esperando extensión, y luego devuelve error).
  - Salida de emergencia documentada: `fstrim`/`discard` en los invitados, destruir snapshots,
    borrar datos, o extender el VG. Las lecturas siguen funcionando aunque el pool esté sin espacio.
- **Snapshots de LVM ≠ snapshots de ZFS/btrfs**: los clásicos son **copy-on-write con un volumen de
  exception fijo** que, si se llena, **invalida el snapshot**; penalizan cada escritura del origen;
  no son baratos ni infinitos. Los thin snapshots son mucho mejores pero comparten el destino del
  thin pool. En ambos casos: **punto de consistencia para hacer la copia, nunca la copia**
  (`backup-recovery-standards`).
- **LVM sobre RAID**: `md` debajo y LVM encima es la combinación clásica y predecible. `lvcreate
  --type raid1/raid5` (dm-raid) existe y usa el mismo motor del kernel, pero deja el diagnóstico
  repartido entre `lvs` y `/proc/mdstat`: elige uno y sé coherente. ❌ Apilar LVM sobre LVM.
- **Alineación**: en LUN de SAN y en SSD, `pvcreate --dataalignment` coherente con el stripe del
  array; desalinear multiplica las escrituras read-modify-write. Verifica con `pvs -o +pe_start`.
- **Copia de la metadata del VG**: `/etc/lvm/backup` y `/etc/lvm/archive` se respaldan con el host.
  `vgcfgrestore` ha salvado más sistemas que cualquier herramienta de recuperación.

### 3.3 RAID por software (mdadm)

- **Niveles y criterio**: RAID1 (raíz, arranque), **RAID10 (datos con IOPS)**, RAID6 (capacidad con
  discos grandes). **RAID5 con discos grandes está prohibido** por la misma razón que RAIDZ1: la
  ventana de reconstrucción es tan larga que el segundo fallo o un URE deja de ser improbable.
  RAID0 no es RAID.
- **Write hole**: tras un apagado sucio la paridad de un stripe puede quedar inconsistente con los
  datos, y si además el array está degradado no hay forma de recalcularla → **corrupción
  silenciosa** al reconstruir. Por eso `md` no arranca por defecto un array degradado y sucio.
  - **`--consistency-policy=ppl`** (Partial Parity Log, **solo RAID5**, metadata 1.x o IMSM):
    cierra el write hole **sin disco dedicado**, a costa de hasta 30–40 % de rendimiento de
    escritura. **Es más débil que un journal**: no protege el dato en vuelo, solo la corrupción
    silenciosa; si se pierde un disco sucio del stripe, no hay recuperación PPL para ese stripe.
  - **`--write-journal`** (RAID4/5/6): garantía fuerte, exige **SSD dedicada y espejada** — si no,
    acabas de crear un SPOF que se lleva el array.
  - **El write-intent bitmap NO cierra el write hole**: solo limita la región a re-sincronizar.
    Úsalo igualmente (`--bitmap=internal`) porque convierte un resync completo en uno de minutos.
  - **RAID6 no tiene PPL**: journal o asumir el riesgo.
  - **Si el filesystem de arriba ya lo resuelve** (ZFS raidz), la protección a nivel `md` sobra —
    pero entonces no deberías tener `md` debajo de ZFS en absoluto (§1).
- **Operación**: `mdadm --detail --scan >> /etc/mdadm/mdadm.conf` tras crear (si no, el array puede
  ensamblarse con otro nombre); `mdadm --monitor` con destino real de correo/alerta; `checkarray`
  (scrub) periódico y **vigilado** — un array que nunca se verifica no sabe que tiene un disco malo
  hasta el resync.
- **Reconstrucción**: `/proc/mdstat` da progreso y velocidad; `/sys/block/mdX/md/sync_speed_max`
  la acota. **Cronometra un resync real en preproducción**: si tarda más que tu ventana de riesgo
  aceptable, el nivel de RAID está mal elegido.
- **mdadm+LVM+XFS frente a ZFS/btrfs — el criterio, no el bando**: `md`+LVM+XFS es predecible,
  universal, soportado por todas las distros, con herramientas de rescate en cualquier live-CD, y
  **no detecta corrupción silenciosa** (sin checksums de datos: la paridad detecta un disco que
  falla, no un bit que miente). ZFS/btrfs dan checksums extremo a extremo, snapshots baratos y
  reparación desde la copia redundante, a cambio de RAM, de un modelo mental propio y —en ZFS— de
  un módulo fuera del árbol. **Decide por el requisito**: si necesitas integridad demostrable y
  snapshots, ZFS (`zfs-standards`); si necesitas simplicidad, portabilidad y encoger volúmenes,
  `md`+LVM+ext4/XFS. **Lo prohibido es mezclarlos en la misma pila.**

### 3.4 Filesystems

- **XFS** — default de RHEL desde la 7 (y en RHEL 10). Escala mejor a partir de varios TB y en
  paralelismo: los allocation groups tienen metadatos independientes y permiten asignar desde
  varios hilos sin contención. **Solo crece** (`xfs_growfs`, online). En error de metadatos
  **apaga el filesystem** y devuelve `EFSCORRUPTED` (frente a ext4, que por defecto continúa) —
  fail-fast, que para un servidor suele ser lo correcto.
- **ext4** — la elección cuando hace falta **encoger** (`resize2fs` offline), en cargas de muchos
  ficheros pequeños, y donde la familiaridad de las herramientas de rescate importa.
- **Parámetros de creación que NO se cambian después** — se deciden en el `mkfs` o se convive con
  ellos de por vida:
  - **Tamaño de bloque** (`-b` en ext4, `-b size=` en XFS): fijo para siempre.
  - **Número de inodos / ratio bytes-por-inodo en ext4** (`-i`, `-N`): **agotar inodos con espacio
    libre de sobra** es un fallo clásico en filesystems de correo, caché o build (§3.8). XFS asigna
    inodos dinámicamente y no sufre esto.
  - **Tamaño del sector/`sunit`/`swidth` en XFS** para alinear con el stripe del RAID.
  - `-m` (porcentaje reservado a root en ext4): **bajarlo a 0–1 % en volúmenes de datos** grandes;
    el 5 % por defecto son decenas de GB tirados. **No lo bajes en `/` ni en `/var`**: esa reserva
    es lo que permite arreglar un sistema lleno.
  - Features de ext4 (`metadata_csum`, `64bit`) — verifica el default de tu `mke2fs.conf`.
- **btrfs — estado a kernel 7.1** (documentación oficial del proyecto, ago-2026):
  - **OK**: subvolúmenes y snapshots, compresión, `send`, `receive`, `scrub`, free space tree,
    fsverity, perfiles **RAID1, RAID1C3, RAID1C4**.
  - **"mostly OK"**: cuotas/qgroups (rendimiento se degrada mucho con muchos snapshots),
    `device replace`, zoned mode.
  - **`RAID56`: unstable.** El grupo de bloques RAID5/6 sigue sin implementarse por completo y **el
    formato en disco no está finalizado**. **Prohibido en producción**, sin matices ni "pero a mí me
    funciona".
  - Criterio: btrfs es correcto para raíz con snapshots y rollback, y para datos con RAID1/1C3.
    Para paridad, o es `md`+RAID6, o es ZFS RAIDZ2.
  - Sus qgroups en un sistema con snapshots automáticos frecuentes son una fuente conocida de
    latencia: mídelo antes de activarlos.
- **Opciones de montaje que importan (por rendimiento y operabilidad)**: `noatime`; `nofail` +
  `x-systemd.device-timeout=` en volúmenes no críticos; `nodiscard` implícito (usar `fstrim.timer`,
  §3.5); `defaults` sin pensar es una decisión, y suele ser la equivocada. **`noexec`, `nosuid` y
  `nodev` son control de seguridad y su criterio lo fija `linux-hardening-standards`.**
- **`fstab` frente a unidades `.mount`**: **el modelo, la precedencia y el generador son de
  `linux-administration-standards`**; aquí solo la regla de contenido: **identifica siempre por
  `UUID=`**, nunca por `/dev/sdX`, y en un volumen que puede no estar presente, `nofail`.
- **`fsck` y reparación**: `xfs_repair` exige el filesystem **desmontado** y `xfs_repair -L`
  (descartar el log) es **destructivo, último recurso**. En ext4, `e2fsck -f` fuera de la ventana de
  producción. Antes de reparar un filesystem con datos que importan y ante sospecha de compromiso:
  **imagen primero** (`incident-response-forensics-standards`) — reparar destruye evidencia.

### 3.5 NVMe, SSD y desgaste

- **Sobreaprovisionamiento (over-provisioning)**: dejar sin particionar un 7–20 % de un SSD (o
  usar `nvme format`/HPA según el fabricante) alarga la vida y estabiliza la latencia de escritura
  sostenida. En SSD de datacenter suele venir de fábrica; en modelos de consumo usados como cache o
  SLOG, hacerlo a mano es la diferencia entre rendimiento estable y colapso.
- **TRIM**: **`fstrim.timer` semanal**, no `discard` en el montaje. El `xfs(5)` desaconseja
  explícitamente `discard` por impacto "quite severe" (hay casos documentados de borrados de ~31 s
  pasando a ~2 min). En **btrfs**, `discard=async` (kernel 5.6+) sí es una alternativa razonable.
  En LUKS hay que **permitirlo explícitamente** (`discard` en `crypttab`), con la contrapartida
  conocida de **fuga de información** sobre qué bloques están usados: es una decisión de modelo de
  amenaza, no de rendimiento. Sobre LUN thin de SAN o disco virtual thin, **fstrim periódico**, no
  continuo.
- **Monitorización del desgaste, no de la muerte**: `smartctl -a` / `nvme smart-log` →
  `percentage_used`, `available_spare` frente a `available_spare_threshold`, `media_errors`,
  `unsafe_shutdowns`, `data_units_written`. **Métrica exportada y con alerta por tendencia**: un
  SSD se sustituye cuando la proyección dice que llegará al límite dentro de la ventana de
  aprovisionamiento, no cuando falla. Vigila los **lotes**: discos idénticos comprados juntos se
  desgastan juntos.
- **Planificadores de I/O**: los clásicos (`cfq`, `deadline` de cola única) ya no existen; el
  kernel es blk-mq. Para **NVMe el default y la recomendación es `none`**: la profundidad de cola y
  el paralelismo del dispositivo hacen que planificar sea puro overhead de CPU. **`mq-deadline`**
  se justifica en SATA SSD/HDD con carga mixta y, en NVMe, **solo** si la métrica que te importa es
  la **latencia de cola** (p99/p999) y lo has medido: `mq-deadline` impone deadlines (500 ms
  lectura / 5 s escritura) y evita que una petición se quede atrás. `bfq` para interactividad de
  escritorio. En muchos NVMe **solo `none` está disponible** salvo que cargues los módulos.
  Se cambia por sysfs sin reinicio (persistente vía regla udev), pero **nunca sin medir antes y
  después**.
- **Colas**: `nr_requests`, `queue_depth` y el número de colas hardware determinan más el
  rendimiento percibido que el planificador. "El disco va lento" con `%util` al 100 % y `aqu-sz`
  alto es **saturación de cola**, no un disco malo.

### 3.6 Multipath, iSCSI y NFS (lado cliente)

- **Multipath cuando el LUN llega por más de una ruta** (dos HBA, dos controladoras, dos switches
  FC/iSCSI). Sin él, la pérdida de una ruta es la pérdida del LUN.
- **El fallo clásico: montar `/dev/sdX` en vez del mapper.** Cuando hay multipath, cada ruta
  aparece como un `sdX` distinto y **funciona** — hasta que esa ruta cae, o hasta que dos rutas se
  montan a la vez y corrompen. **Regla dura: si `multipath -ll` lista el WWID, el único acceso
  legítimo es `/dev/mapper/<alias>`.** Añade los `sdX` subyacentes al `blacklist`/filtro de LVM
  (`global_filter` en `lvm.conf`) para que LVM no vea el mismo PV cuatro veces.
- **Alias persistentes** en `multipath.conf` (por WWID, con nombre que diga qué es), `find_multipaths`
  y política de path acorde al array (`path_grouping_policy`, ALUA). Los parámetros del array se
  toman **de la guía del fabricante**, no del default genérico.
- **iSCSI**: `iscsiadm` con `node.startup=automatic` para LUN necesarios en arranque y **la unidad
  de red arriba antes** (`_netdev` en `fstab`); CHAP mutuo; **VLAN de almacenamiento dedicada**, MTU
  coherente extremo a extremo (`networking-standards`). Timeouts (`node.session.timeo.replacement_timeout`)
  ajustados al tiempo de failover del array: demasiado corto convierte un failover normal en errores
  de I/O; demasiado largo cuelga la aplicación.
- **NFS cliente — `hard` frente a `soft`**: **`hard` siempre**. `soft` devuelve EIO tras `retrans`
  reintentos y **puede causar corrupción silenciosa de datos**: la aplicación no sabe qué escrituras
  se confirmaron. El patrón real documentado es exactamente ese (artefactos corruptos, checksums
  que no cuadran, herramientas que ignoran el EIO de `write()`). Valores conservadores:
  **`hard,timeo=600,retrans=2`** (más `_netdev`/`nofail` y ordenación de systemd).
  - `softerr`/`softreval` son matices para casos concretos (poder desmontar un servidor muerto),
    no la solución al bloqueo.
  - `nconnect=4–8` mejora el throughput con varias conexiones TCP (kernel 5.3+), **tras medir** y
    con el valor de la guía del proveedor; el **primer montaje a una IP fija el `nconnect` para esa
    IP** en ese cliente. **No combinar con `sec=krb5*`.**
  - **El impacto de un almacenamiento remoto caído**: con `hard`, los procesos que tocan el montaje
    quedan en `D` (uninterruptible) y no se pueden matar; el host parece colgado. Eso es
    **correcto**: la alternativa es corromper. Mitigación real: monitorizar el servidor NFS,
    montajes con `autofs` o `.mount` para lo no crítico
    (`linux-administration-standards`), y no colgar servicios críticos de un NFS sin HA.

### 3.7 Cifrado en reposo (LUKS)

- **LUKS2 con `argon2id`** (default upstream de cryptsetup; memoria mínima del benchmark 64 MiB).
  **`pbkdf2` solo** en la partición que GRUB deba desbloquear, porque su soporte de LUKS2 es
  limitado. Un keyslot antiguo se migra con `cryptsetup luksConvertKey --pbkdf argon2id`.
  **No fijes parámetros de KDF de memoria: los defaults cambian entre versiones** — la elección de
  algoritmo y sus parámetros son de `cryptography-pki-standards`.
- **Backup de la cabecera LUKS obligatorio** (`cryptsetup luksHeaderBackup`), guardado **fuera del
  disco cifrado** y con control de acceso: una cabecera corrupta es pérdida total aunque los datos
  estén intactos. Es la primera pregunta de cualquier revisión.
- **Desbloqueo desatendido**: TPM2 (`systemd-cryptenroll --tpm2-device=auto` con PCRs pensados y
  **política de recuperación**), Clevis/Tang para desbloqueo en red, o `LoadCredential`/agente. **La
  política, la custodia de la clave de recuperación y su rotación son de
  `cryptography-pki-standards` y `secrets-management-standards`**; aquí queda fijado que
  (a) **siempre** hay una passphrase de recuperación custodiada fuera del host, y (b) un cambio de
  firmware o de kernel puede invalidar el sellado TPM: **prueba el arranque tras cada actualización
  que toque PCRs, con consola OOB disponible**.
- **Coste y TRIM**: el impacto de CPU con AES-NI es marginal; el TRIM a través de LUKS hay que
  habilitarlo explícitamente y filtra metadatos (§3.5). El baseline de cifrado obligatorio por
  clasificación de dato es de `linux-hardening-standards`.

### 3.8 Los fallos que parecen otra cosa

- **`df` dice lleno y `du` no lo encuentra** → casi siempre un **fichero borrado que sigue abierto**
  por un proceso: `lsof +L1` o `lsof | grep deleted`; el espacio vuelve al reiniciar el proceso, no
  al borrar de nuevo. Otras causas: un montaje **encima** de un directorio con datos debajo
  (comprobar con un bind mount del raíz), o el porcentaje reservado a root (`tune2fs -m`).
- **"No queda espacio" con `df` mostrando espacio libre** → **inodos agotados** (`df -i`). Ocurre en
  filesystems de caché, correo o build con millones de ficheros pequeños. **No se arregla en
  caliente en ext4**: hay que recrear el filesystem con más inodos (o migrar a XFS, que los asigna
  dinámicamente). Es un fallo **de diseño en el `mkfs`**, y por eso `df -i` va en la monitorización.
- **Filesystem lleno al 100 % que impide arrancar o reparar**: sin espacio no se escriben logs,
  no arranca journald, algunos servicios fallan de forma inexplicable, y en ext4 sin reserva de
  root ni siquiera un administrador puede maniobrar. **Alerta al 80 %, no al 95 %**, y con
  predicción de tiempo hasta el llenado.
- **Cuotas**: `quota`/`xfs_quota` (XFS incluye cuotas por proyecto, muy útiles para acotar un
  directorio sin darle un LV propio) cuando varios consumidores comparten un filesystem. Sin
  cuotas, el primero que se descontrola tumba a todos.
- **Un `dm` degradado que nadie ve**: `dmsetup status`, `lvs -o +lv_health_status`, `/proc/mdstat`.
  Un array degradado que no genera alerta es una pérdida de datos programada.

### 3.9 Rendimiento y medición

- **Latencia frente a throughput**: son objetivos distintos y casi siempre opuestos. Define cuál
  te importa **antes** de medir. Un número de MB/s sin percentiles de latencia no dice nada de una
  base de datos.
- **`iostat -xz 1`**: `r_await`/`w_await` (latencia real por operación), `aqu-sz` (profundidad de
  cola), `%util` (**engañoso en NVMe**: llega al 100 % sin saturación porque el dispositivo procesa
  en paralelo). `iotop`/`pidstat -d` para atribuir a proceso; `blktrace`/`biolatency` (bcc/bpftrace)
  cuando hay que ver la distribución real y dónde se pierde el tiempo dentro de la pila.
- **Medir con `fio` sin engañarse** — los tres errores que invalidan cualquier benchmark:
  1. **Medir la caché**: dataset mayor que la RAM, o `direct=1` (O_DIRECT) para saltar la page
     cache. Un `dd` que da 3 GB/s en una máquina con 64 GB de RAM está midiendo memoria.
  2. **Medir el patrón equivocado**: usa el `bs`, la mezcla lectura/escritura, `iodepth` y `numjobs`
     de tu carga real, no `bs=1M` secuencial para una BD que hace 8K aleatorio.
  3. **No dejar que el SSD entre en estado estacionario**: los primeros minutos de un SSD vacío
     mienten. `ramp_time` y ejecuciones largas.
  Además: `fsync`/`end_fsync` si te importa la durabilidad, y **nunca ejecutar `fio` con escritura
  sobre un dispositivo con datos** (`filename=/dev/sdX` destruye el contenido).
- **"El disco va lento" — orden de sospecha real**: (1) filesystem por encima del 80–90 % lleno o
  fragmentado; (2) profundidad de cola / saturación por concurrencia; (3) una capa dm intermedia
  (thin pool casi lleno, cifrado sin AES-NI, RAID en resync); (4) escrituras síncronas que la
  aplicación pide y nadie había contado; (5) el disco. **El disco es la última hipótesis, no la
  primera.**
- **Crecer en caliente**: disco virtual ampliado → `echo 1 > /sys/class/block/sdX/device/rescan`
  (o `iscsiadm --rescan`, o `multipathd resize map`) → `growpart`/`parted` → `pvresize` →
  `lvextend -r`. Cada paso se verifica antes del siguiente; saltarse uno produce el clásico
  "he ampliado el disco y no se ve".

## 4. Gates: lo que hay que demostrar

Un sistema de almacenamiento no está en producción hasta que estos puntos están demostrados con
evidencia y fecha:

1. **Alerta de capacidad con predicción, en espacio Y en inodos.** `df` y `df -i` exportados, aviso
   al 80 % con estimación de tiempo hasta el llenado. Un aviso al 95 % llega tarde por definición.
   En LVM thin, alerta adicional sobre `Data%` **y** `Meta%` del pool.
2. **Alerta de degradación probada.** `mdadm --monitor` (o el equivalente del dm) y SMART/NVMe con
   destino que llega a un humano de guardia; **se verifica provocándola** (desconectar un disco en
   preproducción), no leyendo la configuración.
3. **Scrub/`checkarray` programado y vigilado** en cualquier array con redundancia; **la alerta es
   sobre el resultado**, no sobre que el timer se ejecutara.
4. **Reconstrucción cronometrada.** Un resync real medido en preproducción con la carga puesta. Si
   supera la ventana de riesgo aceptable, **el nivel de RAID está mal elegido** y se revisa (§3.3).
5. **Crecimiento en caliente ensayado.** El procedimiento completo (§3.9) ejecutado al menos una
   vez por alguien distinto del autor del runbook, con la aplicación en marcha.
6. **Backup de cabecera LUKS y de metadata LVM verificados**, guardados fuera del sistema, y con la
   restauración probada (`cryptsetup luksHeaderRestore` / `vgcfgrestore`) en un entorno de prueba.
7. **Ninguna referencia a `/dev/sdX`** en `fstab`, `crypttab`, scripts, unidades ni documentación.
   Gate mecánico: `grep -rn '/dev/sd' /etc/fstab /etc/crypttab /etc/systemd/system/` vacío.
8. **Multipath: comprobar que el punto de montaje es el mapper** y que el failover de ruta se ha
   probado (bajar una ruta y ver que la I/O continúa).

## 5. Seguridad

- **Cifrado en reposo según la clasificación del dato** (§3.7). El baseline de qué debe ir cifrado
  y la separación de particiones como control CIS son de `linux-hardening-standards`; **las
  opciones `noexec`/`nosuid`/`nodev` son suyas**, no de aquí.
- **Retirada de discos**: un disco que sale del datacenter sin borrado criptográfico o destrucción
  física es una fuga de datos. `nvme format --ses=1`/`blkdiscard`/`cryptsetup luksErase` según el
  medio — y en SSD, **borrar ficheros no borra nada** por el remapeo interno: el cifrado desde el
  día uno es lo que hace la retirada trivial (destruye la clave y el disco es ruido).
- **Filtro de LVM (`global_filter`)**: en un host con multipath, iSCSI o VMs, LVM puede activar
  volúmenes que no le corresponden — incluidos LV **dentro** de discos de invitados. Es superficie
  de escape y de corrupción: filtra explícitamente lo que LVM debe mirar.
- **Montajes de red y confianza**: NFSv3 con `sec=sys` confía en el UID que dice el cliente. En
  redes no confiables, NFSv4 con Kerberos o nada; el diseño de segmentación es de
  `networking-standards`.
- **TRIM sobre cifrado filtra metadatos** (qué bloques están usados): decisión consciente (§3.5).
- **CVEs de la pila de almacenamiento**: los de kernel (`md`, `dm`, drivers NVMe/SCSI, filesystems)
  se triagan como cualquier otro (`vulnerability-management-standards`); su remediación **implica
  reinicio**, y esa política es de `linux-administration-standards`. **Hueco declarado (§8)**: no
  se ha verificado en esta sesión ningún CVE concreto de LVM/mdadm/XFS/ext4/btrfs de 2025-2026.

## 6. Observabilidad y operabilidad

- **Métricas mínimas por host**: espacio e inodos por filesystem (`node_filesystem_*`), latencia y
  cola por dispositivo (`node_disk_*`: `io_time`, `read/write_time`, `io_now`), estado de arrays
  (`node_md_*`), SMART/NVMe (`smartctl_exporter`: `percentage_used`, `available_spare`,
  `media_errors`, reasignados y pendientes), ocupación de datos **y metadatos** de thin pools,
  estado de rutas multipath, estado de montajes de red. El diseño de las alertas y sus umbrales es
  de `observability-standards`; **qué** exponer es de aquí.
- **Alertas accionables**: filesystem > 80 % (con predicción), inodos > 80 %, array degradado o en
  resync, thin pool > 80 % en datos o metadatos, ruta multipath caída, SMART con reasignados o
  pendientes creciendo, `percentage_used` de NVMe por encima del umbral de aprovisionamiento,
  latencia p99 por encima del objetivo, montaje NFS/iSCSI no disponible. Sin runbook enlazado, la
  alerta sobra.
- **Capacidad como planificación, no como alarma**: revisión trimestral de tendencia por volumen,
  antigüedad y desgaste por lote de discos, y espacio libre real del VG (los thin pools mienten
  sobre el espacio disponible por diseño).
- **Runbooks probados**: sustituir un disco de un array, extender un volumen en caliente, thin pool
  al 95 %, filesystem al 100 %, ruta de SAN caída, servidor NFS caído. Probados, versionados, con
  dueño.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Revisión trimestral: firmware de discos, HBA y controladoras (los bugs de firmware de SSD que
  causan pérdida de datos a las N horas de encendido son un género propio); desgaste por lote;
  tendencia de capacidad; vigencia de la topología frente a la carga actual.
- Antes de cualquier upgrade de kernel: comprobar cambios en el subsistema de bloques o en el
  filesystem que uses si el salto es de versión mayor (`linux-administration-standards` gobierna
  la política de reinicio).
- **Documentar en el runbook las decisiones irreversibles del `mkfs`** (tamaño de bloque, inodos,
  alineación) junto al host: dentro de tres años nadie recordará por qué ese filesystem tiene esos
  parámetros, y son los que impiden el crecimiento.

**PROHIBIDO**
- ❌ **LVM o mdadm por debajo de ZFS.** Si el sistema es ZFS, los discos van crudos tras un HBA en
  modo IT (`zfs-standards`).
- ❌ **btrfs RAID5/RAID6** en producción: **unstable** y con formato en disco sin finalizar.
- ❌ **mdadm RAID5 con discos grandes**; ❌ RAID0 con datos que importen; ❌ array sin `--bitmap`.
- ❌ Creer que el write-intent bitmap cierra el write hole (no lo hace: solo acelera el resync).
- ❌ **Thin pool sobreaprovisionado sin `thin_pool_autoextend_threshold < 100`, sin dmeventd activo
  y sin alerta sobre datos Y metadatos.** Llenar el pool puede ser irreparable.
- ❌ Snapshots de LVM o de btrfs presentados como backup.
- ❌ Planificar encoger un XFS: **no se puede**. Elegir XFS donde el requisito es reducir.
- ❌ `lvreduce` antes de `resize2fs`, o `lvreduce` sin backup verificado.
- ❌ `/dev/sdX` en `fstab`, `crypttab`, scripts, unidades o documentación.
- ❌ Montar el `sdX` subyacente cuando existe un mapa multipath.
- ❌ **NFS con `soft` en cargas de escritura**: corrupción silenciosa documentada.
- ❌ `nconnect` combinado con `sec=krb5*`; `nconnect` copiado de un blog sin medir.
- ❌ Opción de montaje **`discard`** en ext4/XFS por defecto (usar `fstrim.timer`); TRIM continuo
  sobre LUN thin de SAN.
- ❌ Entrada de `fstab` de un volumen opcional **sin `nofail`**: un disco ausente tira el arranque.
- ❌ Cambiar el planificador de I/O, `nr_requests` o cualquier tunable **sin medición antes y
  después**.
- ❌ Benchmarks con `dd`, sin `direct=1`, con dataset menor que la RAM, o sin `ramp_time` en SSD.
- ❌ Ejecutar `fio` en modo escritura contra un dispositivo con datos.
- ❌ LUKS sin **backup de cabecera** custodiado fuera del disco cifrado, o desbloqueo por TPM sin
  passphrase de recuperación custodiada.
- ❌ `xfs_repair -L` o cualquier reparación destructiva como primer intento, o antes de tener
  imagen si hay sospecha de compromiso.
- ❌ Filesystem de producción sin alerta de espacio **y de inodos**.
- ❌ Array degradado, thin pool al límite o ruta multipath caída sin alerta que llegue a un humano.
- ❌ Bajar la reserva de root (`tune2fs -m 0`) en `/` o `/var`.
- ❌ Retirar un disco sin borrado criptográfico o destrucción física.

## 8. Verificación web obligatoria

Verificado a **agosto 2026** (y qué hay que re-verificar antes de fijar nada):
1. **XFS no admite reducción**, ni online ni offline, y no está en el roadmap upstream a kernel 7.0;
   solo hay trabajo en revisión para encoger **AG vacíos**. `xfs_growfs` solo crece. **XFS sigue
   siendo el default de la familia RHEL en RHEL 10**, con ext4 plenamente soportado. Re-verificar
   en la documentación de Red Hat y en `xfs.org` — es el error de memoria más frecuente del dominio.
   (Nota: XFS ganó auto-reparación de metadatos en kernel 7.0; **hueco**: no verificado su alcance.)
2. **btrfs — matriz de estabilidad oficial** (`btrfs.readthedocs.io/en/latest/Status.html`, estado a
   kernel 7.1): `RAID56` = **unstable** con formato en disco no finalizado; `qgroups` y
   `device replace` = "mostly OK"; snapshots, compresión, send/receive, scrub, free space tree y
   RAID1/1C3/1C4 = OK. **Re-verificar en esa página, nunca de oídas**: es la fuente canónica y
   cambia por versión de kernel.
3. **Planificadores de I/O**: `none` es el default y la recomendación para NVMe; `mq-deadline`
   justificado por latencia de cola medida o en SATA. Los planificadores de cola única (`cfq`,
   `deadline`) ya no existen. Confirmar qué ofrece `/sys/block/<dev>/queue/scheduler` en el kernel
   concreto.
4. **LVM thin**: `thin_pool_autoextend_threshold` mínimo 50, 100 lo desactiva; dmeventd/`lvm2-monitor`
   requerido; el agotamiento de **metadatos** es un modo de fallo independiente; llenar el pool
   puede dañarlo de forma difícil o imposible de reparar. Fuente: `lvmthin(7)`. Re-verificar los
   defaults de tu distro en `lvm.conf`.
5. **`fstrim.timer` frente a `discard`**: `xfs(5)` sigue desaconsejando `discard` por impacto
   severo; ext4 tampoco lo recomienda por defecto; `discard=async` es de **btrfs** (kernel 5.6+) y
   no existe en ext4/XFS. Re-verificar en el `man` de la versión instalada.
6. **NFS `hard` frente a `soft`**: `nfs(5)` documenta que un timeout de `soft` **puede causar
   corrupción silenciosa de datos**. `hard,timeo=600,retrans=2` como base. `nconnect` requiere
   kernel 5.3+, el valor óptimo depende del proveedor (4 en unos, 8-16 en otros) y **no se combina
   con Kerberos**. Verificar la guía del proveedor de almacenamiento concreto.
7. **mdadm write hole**: `--consistency-policy` admite `resync|bitmap|journal|ppl`; **PPL solo
   RAID5**, máx. 64 discos, coste de escritura hasta 30–40 %, y **no protege el dato en vuelo**;
   `journal` sirve para RAID4/5/6 y exige SSD dedicada (espejada, o es un SPOF). El **bitmap no
   cierra el write hole**. Fuente: `mdadm(8)` y `docs.kernel.org/driver-api/md/raid5-ppl.html`.
8. **cryptsetup/LUKS2**: el default upstream es **argon2id** (era argon2i), con memoria mínima de
   benchmark de 64 MiB; los parámetros se autoajustan al hardware y **cambian entre versiones** —
   la propia ArchWiki advierte de no confiar en los defaults. GRUB necesita `pbkdf2`.
   **Hueco declarado**: no se ha verificado la versión exacta de cryptsetup vigente en ago-2026 ni
   sus parámetros por defecto actuales. Consultar el GitLab upstream antes de fijarlos.
9. **CVEs**: **hueco declarado** — no se ha verificado en esta sesión ningún CVE concreto de
   LVM2, mdadm, cryptsetup, open-iscsi, multipath-tools ni de los filesystems (ext4/XFS/btrfs) en
   2025-2026. Consultar los avisos de la distro (DSA/USN/RHSA) y NVD antes de afirmar nada sobre
   la seguridad de estos componentes.
10. **Hueco declarado — no verificado en esta sesión**: (a) el estado actual de `f2fs` y otros
    filesystems de nicho (bcachefs incluido: su situación upstream ha sido cambiante y **no se
    recomienda aquí por defecto** precisamente por no estar verificada); (b) los valores actuales
    de `nr_requests` y defaults de blk-mq por tipo de dispositivo; (c) límites vigentes de tamaño
    de volumen y de fichero soportados **por la distro** (no por el filesystem) para ext4 y XFS —
    Red Hat y SUSE publican límites *soportados* más bajos que los teóricos, y ese es el número que
    cuenta en un contrato de soporte.
11. Antes de cualquier `mkfs` en producción: los parámetros irreversibles (§3.4) contra la
    documentación de la versión de `e2fsprogs`/`xfsprogs` instalada, no contra la memoria.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
