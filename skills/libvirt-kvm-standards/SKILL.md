---
name: libvirt-kvm-standards
description: Bare KVM/QEMU with libvirt on standalone hosts, with no management platform above it. Use when running virsh, virt-install, virt-xml, virt-clone, virt-manager, virt-viewer, virt-sysprep, virt-customize, virt-df, guestfish or libguestfs tools, qemu-img and qemu-system-x86_64, editing domain XML under /etc/libvirt/qemu, libvirtd.conf, qemu.conf or the modular daemons (virtqemud, virtnetworkd, virtstoraged, virtnodedevd, virtproxyd), defining libvirt storage pools and volumes or virtual networks (default NAT, bridge, macvtap, open vswitch portgroup), pinning a versioned machine type (pc-q35-x.y) instead of an alias, choosing host-passthrough versus a named CPU model, OVMF/UEFI nvram and swtpm virtual TPM, hugepages, numatune and vcpupin, iothreads, qcow2 versus raw versus LVM/zvol backing with cache modes none/writeback/directsync and io=native/io_uring, discard=unmap, VFIO and IOMMU groups for PCI or GPU passthrough, internal versus external snapshots (snapshot-create-as, blockcommit, blockpull), live migration with virsh migrate and what breaks it, or sVirt confinement of the qemu process.
---

# Estándares de KVM/QEMU con libvirt (sin plataforma de gestión)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: libvirt puro **no tiene cluster, ni HA, ni backup, ni RBAC útil, ni interfaz de
> operación**. Eso no es un defecto: es el alcance. Si el proyecto necesita cualquiera de esas
> cuatro cosas, la respuesta correcta no es construirlas a mano sobre `virsh`, es una plataforma
> (`proxmox-ve-standards`). Usar libvirt puro donde hacía falta plataforma es el error caro de este
> dominio, y se paga a los dos años, en producción y de golpe.

## 1. Alcance y triggers

Aplica al **sustrato de virtualización**: KVM como acelerador del kernel, QEMU como proceso de
usuario y libvirt como API y modelo de objetos por encima, en **hosts individuales sin plataforma**.
Cubre el modelo de objetos, el XML del dominio y qué partes de él importan, almacenamiento y red de
la VM a bajo nivel, passthrough de dispositivos, migración en vivo, snapshots, herramientas de
imagen del ecosistema, y la seguridad del proceso QEMU.

Disparadores: `virsh` (`define`, `edit`, `dumpxml`, `start`, `migrate`, `snapshot-create-as`,
`blockcommit`, `blockpull`, `attach-device`, `nodedev-*`, `pool-*`, `vol-*`, `net-*`, `domcapabilities`,
`capabilities`), `virt-install`, `virt-xml`, `virt-clone`, `virt-manager`, `virt-viewer`,
`virt-sysprep`, `virt-customize`, `virt-df`, `guestfish`, `libguestfs`, `qemu-img`,
`qemu-system-x86_64`, `/etc/libvirt/qemu/*.xml`, `/etc/libvirt/qemu.conf`, `/etc/libvirt/libvirtd.conf`,
`virtqemud`/`virtnetworkd`/`virtstoraged`/`virtnodedevd`/`virtproxyd`, `/var/lib/libvirt/images`,
`vfio-pci`, `/sys/kernel/iommu_groups`, `swtpm`, `OVMF_CODE.fd`/`OVMF_VARS.fd`, `machine type`,
`host-passthrough`, `macvtap`, `virtio-blk`/`virtio-scsi`/`virtio-net`.

### 1.1 Cuándo libvirt puro y cuándo plataforma

**libvirt puro es la respuesta correcta cuando:**
- Es **un host** (o unos pocos independientes) y la pérdida de ese host es un evento aceptado y con
  procedimiento, no un desastre.
- Es laboratorio, entorno de desarrollo, banco de pruebas o **runner de CI** que crea y destruye VMs.
- La infraestructura de VMs se **define por código** (Terraform/Ansible) y el host es ganado, no
  mascota: se reconstruye desde cero.
- Necesitas control fino de QEMU que una plataforma esconde: passthrough exótico, topología NUMA
  concreta, dispositivos a medida, virtualización confidencial.

**No lo es —y la respuesta es plataforma— cuando aparece cualquiera de estas:**
- Hace falta **conmutación automática** ante caída de un host: eso es HA, y HA exige quórum y
  fencing. `virsh migrate` es una operación manual, no un failover.
- Hace falta **backup con retención, deduplicación, verificación y restore probado**: libvirt no lo
  trae. Guardar `qcow2` a un NFS con `rsync` no es un plan de respaldo.
- Hay **varios operadores** que necesitan permisos distintos: el control de acceso real de libvirt es
  la pertenencia al grupo del socket, es decir, todo o nada sobre el host.
- Hay **decenas de VMs** que alguien debe operar sin leer XML.

**Ola 2 planificada / vecina**: si el requisito es HA de **servicios Linux** (no de VMs), es
`ha-clustering-standards`. Levantar VMs con Pacemaker + `VirtualDomain` sobre almacenamiento
compartido es técnicamente posible y **casi nunca la elección correcta frente a una plataforma**:
sumas fencing, filesystem de cluster y un stack más que mantener para reimplementar peor lo que PVE
ya trae. Si aun así se hace, el criterio de quórum, fencing y STONITH es de aquella skill y **es
obligatorio**, no opcional.

**No aplica**: ver `proxmox-ve-standards` (**la frontera hermana**: PVE usa KVM/QEMU pero **no usa
libvirt** —gestiona QEMU con `qemu-server`— así que en un nodo PVE no se edita XML de dominio ni se
usa `virsh`; allí viven cluster, quórum, HA, fencing, PBS, RBAC, SDN, LXC y el asistente de
importación desde VMware. Regla: **si la respuesta se escribe con `virsh` o con XML, es de aquí; si
se escribe con `qm`/`pct`/`pve*` o tocando `/etc/pve`, es de allí**), `onprem-standards` (**paraguas**:
su §2 fija la elección de hipervisor y su §1.3 los invariantes de plataforma), `ha-clustering-standards`
(**Ola 2, planificada**: Pacemaker/Corosync, fencing, recursos — §1.1),
`zfs-standards` (**el pool y el zvol por debajo**: topología de vdev, `ashift`, y sobre todo el
`volblocksize` del zvol que respalda un disco — **el diseño del pool y las propiedades del zvol son
suyos; el `<disk>` del dominio, su `cache`, su `io` y su `discard` son de aquí**),
`linux-storage-standards` (LVM y LVM-thin, multipath, iSCSI, NVMe, filesystems y LUKS que respaldan
las imágenes; `qemu-img` y el formato de la imagen son de aquí, `lvcreate`/`multipath -ll` son suyos),
`linux-administration-standards` (el SO del host: systemd, journald, cgroups, diagnóstico — **las
unidades de los daemons modulares y su activación por socket son suyas; qué daemon instalar y por qué
es de aquí**), `linux-hardening-standards` (baseline CIS del host, sandboxing de unidades como
control), `selinux-standards` (**sVirt**: el confinamiento MAC del proceso QEMU por dominio,
denegaciones AVC, `virt_use_nfs` y compañía, perfiles AppArmor de libvirt — **aquí solo que sVirt no
se desactiva y qué rompe al hacerlo**), `networking-standards` (**diseño** de red: VLAN, routing,
direccionamiento; aquí solo el modelo de red que se le da a la VM),
`firewall-policy-standards` (política de filtrado como artefacto; `nwfilter` de libvirt se decide
con ese criterio), `iac-standards` (**Terraform/OpenTofu y Ansible que definen las VMs**: allí el
módulo, el estado, la CI y la detección de drift; **aquí qué debe contener la definición para que la
VM sea correcta y migrable**), `kubernetes-standards` (workload en contenedor; y si la pregunta es
"¿VM o contenedor?", ver §3.1), `container-runtime-security-standards` (aislamiento de contenedores;
**una VM sí es una frontera de seguridad, un contenedor es más débil** — Kata Containers vive allí),
`observability-standards` (diseño de métricas y alertas; aquí **qué** vigilar de un host KVM),
`vulnerability-management-standards` (triaje de un CVE concreto de QEMU/kernel),
`incident-response-forensics-standards` (**adquisición de memoria de una VM**: `virsh dump` es un
mecanismo de aquí, el orden de volatilidad y la cadena de custodia son suyos),
`cryptography-pki-standards` (certificados del transporte TLS de libvirt),
`secrets-management-standards` (`virsh secret-*` y las claves de disco cifrado),
`windows-server-ad-standards` (invitados Windows: drivers **virtio-win**, licenciamiento, AD),
`homelab-standards` (host KVM de laboratorio donde el criterio es coste, ruido y consumo),
`ctf-lab-standards` (VMs desechables y aisladas para detonar binarios: allí el aislamiento es el
propósito), `vmware-standards`, `hyper-v-standards` y `xen-standards` (**Ola 7**: los otros
hipervisores, cada uno con su skill. **La importación de un disco `.vmdk` o `.vhdx` y la conversión
del formato son de aquí**; **el inventario de lo que hay que migrar, su licencia y lo que se pierde
al salir son de la skill del hipervisor de origen**. Aviso que las cuatro comparten: **un CVE de
hipervisor no se traslada de uno a otro** — la respuesta de parcheo es de la skill del producto
afectado).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un sistema real (§8).

| Ámbito | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| QEMU | La rama que empaquete la distro con soporte de seguridad; upstream estable a ago-2026: **QEMU 11.0** (11.0.3, 24-jul-2026) — 11.1 aún en RC | ❌ Compilar QEMU a mano en un host de producción y quedarse fuera del canal de parches |
| libvirt | El de la distro; upstream a ago-2026: **12.6.0** (03-ago-2026). Desde **12.4.0** el mínimo de QEMU soportado es **7.2.0** | ❌ Mezclar libvirt de terceros con QEMU de la distro sin verificar la matriz de soporte |
| Daemons | **Daemons modulares** (`virtqemud`, `virtnetworkd`, `virtstoraged`, `virtnodedevd`, `virtsecretd`, `virtnwfilterd`), activados por socket | `libvirtd` monolítico **solo** en hosts heredados: upstream lo eliminará y ya es el camino sin salida. `virtproxyd` únicamente si necesitas acceso remoto/compatibilidad legacy |
| Acceso remoto | **`qemu+ssh://`** (autenticación y cifrado por SSH, sin abrir nada nuevo) | TLS con PKI interna y `virtproxyd` si hay muchos clientes; ❌ **TCP en claro sin autenticación** (`listen_tls=0` + `auth_tcp="none"`): es un host root remoto abierto |
| Fuente de verdad | **XML versionado en repo** aplicado con `virsh define` (o generado por Ansible/Terraform) | `virsh edit` para diagnóstico y cambio puntual, **con el cambio devuelto al repo**; ❌ el host como única copia de la definición |
| `machine type` | **Versionado y fijado explícitamente** (`pc-q35-<x.y>`, el más reciente **no deprecado**) | ❌ Dejar el alias (`q35`, `pc`): al actualizar QEMU la máquina cambia de hardware virtual bajo los pies del invitado y rompe migración y, en Windows, activación y arranque |
| Firmware | **UEFI/OVMF** con NVRAM por dominio; Secure Boot activado en invitados que lo soporten | SeaBIOS solo para invitados legacy que no arrancan por UEFI |
| CPU | **Modelo nombrado** común al parque (el mayor soportado por todos los hosts) | `host-passthrough` solo en host único o parque homogéneo y sin migración; ❌ `host-passthrough` + migración entre CPUs distintas |
| Disco | **virtio-scsi** con `discard='unmap'`, `io='native'` (o `io_uring`) y **`cache='none'`** | `virtio-blk` para latencia mínima con pocos discos; ❌ `cache='writeback'` en datos que importan (§3.4); ❌ IDE/SATA emulados |
| Formato | **raw** sobre zvol/LV para rendimiento; **qcow2** sobre fichero cuando quieras snapshots y thin | ❌ qcow2 **sobre** un zvol o LV (dos capas de copy-on-write, doble amplificación); ❌ snapshots internos qcow2 en producción (§3.6) |
| Red | **Bridge** a la red física para VMs que dan servicio | NAT (`default`) solo para laboratorio y CI; **macvtap** cuando quieras simplicidad y aceptes que **el host no habla con la VM** (§3.5); SR-IOV cuando el rendimiento lo exija y aceptes perder migración en vivo |
| TPM | **swtpm** con TPM 2.0 emulado en todo invitado Windows 11+ y en cualquiera que use cifrado de disco atado a TPM | ❌ TPM emulado sin persistencia de su estado: rompe BitLocker en el siguiente arranque |
| Snapshots | **Externos** (`--disk-only` + `blockcommit`) | ❌ Snapshots **internos** de qcow2 como práctica habitual; ❌ cualquier snapshot como sustituto del backup |
| Backup | **Fuera de libvirt**: agente en el invitado o `zfs send` del zvol tras `fsfreeze` vía guest agent | ❌ Copiar un `qcow2` en caliente sin *freeze* ni snapshot: la imagen resultante es basura con formato válido |
| Automatización | **cloud-init** (o ignition en Fedora CoreOS/RHCOS) sobre plantilla limpia con `virt-sysprep` | ❌ Clonar una VM sin `virt-sysprep`: arrastra machine-id, claves SSH de host, MAC y hostname |

## 3. El modelo y el XML que importa

### 3.1 Modelo de objetos

- Objetos: **dominios** (VMs), **storage pools** y sus **volúmenes**, **redes**, **secretos**,
  **nwfilters** y **dispositivos de nodo**. Cada uno con su XML, sus comandos `virsh` y su ciclo
  `define` → `start` → `autostart`.
- **`virsh` es la interfaz real y la API es la fuente de verdad**; `virt-manager` es un cliente
  cómodo para inspección y para el 5% de operaciones interactivas, **no la forma de gestionar un
  parque**. Nada que se haga más de dos veces se hace por GUI.
- `define` es persistente, `create` es transitorio (desaparece al parar). Un dominio creado con
  `create` que "se ha perdido al reiniciar" no se ha perdido: nunca existió en disco.
- **libvirt normaliza y completa el XML al definirlo**: lo que escribes no es lo que queda. `virsh
  dumpxml` sobre un dominio **activo** muestra la configuración en ejecución, que puede diferir de la
  persistente (`--inactive`). Diagnostica siempre sabiendo cuál estás mirando.
- Los storage pools de libvirt son una comodidad, no una capa de gestión: sobre ZFS o LVM el trabajo
  real lo hacen `zfs`/`lvm` y el pool es un envoltorio. Úsalos si simplifican; no dependas de ellos.
- **VM o contenedor**: la VM aporta **kernel propio y una frontera de seguridad de verdad**; el
  contenedor aporta densidad y arranque rápido. Multi-tenencia, código no confiable, kernel distinto
  o requisito regulatorio de aislamiento → **VM**. Todo lo demás, contenedor
  (`kubernetes-standards`, `podman-systemd-containers-standards` — Ola 2).

### 3.2 `machine type`: fíjalo o te romperá

- Los tipos versionados **congelan el hardware virtual** que ve el invitado. Es lo que hace posible
  migrar y lo que evita que un `apt upgrade` de QEMU cambie la placa base de una VM en marcha.
- **Política de QEMU verificada**: los tipos versionados se soportan **6 años ≈ 18 releases**; se
  marcan **deprecados a los 3 años (9 releases)** y **se eliminan 3 años después**. A la fecha, **todos
  los de versión `8.1.0` o anterior están deprecados**. Literal de la documentación: *"Newly deployed
  VMs should exclusively use a non-deprecated machine type, with use of the most recent version highly
  recommended."*
- **QEMU se niega a arrancar una VM con un tipo eliminado.** QEMU 11.0 eliminó `pc-i440fx-2.6`,
  `pc-q35-2.6`, `pc-i440fx-2.7` y `pc-q35-2.7`. Un host actualizado con VMs viejas **no arranca**, y
  te enteras después del reinicio.
- Procedimiento: auditar `machine` de todos los dominios contra la lista de deprecados **antes** de
  cada actualización de QEMU, y subirlos en ventana de servicio (apagar → editar → arrancar; no en
  caliente). Un tipo deprecado solo se conserva para **recibir migraciones y restaurar estado
  guardado** de VMs preexistentes.
- **Nunca uses el alias** (`q35`, `pc`) en la definición: resuelve a "lo más nuevo que haya hoy" y
  convierte cada actualización en una lotería. En Windows, un cambio de máquina puede invalidar la
  activación.

### 3.3 CPU, NUMA y memoria

- `host-passthrough` da todas las extensiones del host y **fija la VM a esa CPU**: sin migración a
  hardware distinto, sin arranque tras cambiar de host. Vale para host único; es una trampa en un
  parque.
- **Modelo nombrado** (con `check='full'`) es lo que permite un parque migrable: se elige el mayor
  modelo soportado por **todos** los hosts, y se documenta como decisión del parque. Los flags
  concretos se comprueban con `virsh domcapabilities` y `virsh cpu-baseline`/`hypervisor-cpu-baseline`,
  **no de memoria**.
- **Virtualización anidada: desactivada salvo necesidad demostrada** (ver §5, Januscape). Si el
  invitado no va a ejecutar otro hipervisor, no se la des.
- **Hugepages** (2 MiB, o 1 GiB en VMs muy grandes) reducen presión de TLB en cargas con mucha
  memoria; exigen reserva en el host y **desactivar el ballooning** de esa VM.
- **NUMA**: en hosts multi-socket, una VM que cruza nodos NUMA sin pinning pierde rendimiento de
  forma silenciosa e irregular. Con VMs grandes: `numatune` + `vcpupin` + `memnode` coherentes con
  la topología real (`virsh capabilities`, `lscpu`, `numactl -H`), y topología virtual expuesta al
  invitado. En VMs pequeñas, el pinning es sobreingeniería que estorba al planificador.
- **`iothreads`**: hilos de E/S dedicados asignados a discos virtio; separan la E/S del vCPU y evitan
  que un disco lento bloquee la VM. Uno por disco con carga real; no uno por disco "porque sí".
- `<memballoon>` es útil en laboratorio y **estorba en producción** con memoria dimensionada: fija la
  memoria y desactívalo en bases de datos, JVM y cargas con hugepages.

### 3.4 Almacenamiento y caché

- **Elección de backing**, por criterio real: `raw` sobre **zvol o LV** = máximo rendimiento y
  snapshots delegados a la capa de abajo (que los hace mejor); **qcow2 sobre fichero** = snapshots,
  thin provisioning, backing chains y portabilidad, a costa de una capa de indirección.
- **Nunca apiles copy-on-write**: qcow2 sobre zvol o sobre LVM-thin duplica la amplificación de
  escritura y el consumo. Si el backend ya hace CoW, el formato es `raw`.
- **Modos de caché y qué significan ante corte de luz** — el criterio es la integridad, no el
  benchmark:
  - **`cache='none'`** — E/S directa al backend, evita la caché de página del host, **respeta los
    flush del invitado**. Es el defecto correcto y el único que permite migración en vivo con
    almacenamiento compartido sin trucos.
  - **`cache='directsync'`** — como `none` pero además cada escritura es síncrona. Máxima seguridad,
    peor rendimiento; para lo que no puede perder una escritura y no tiene protección propia.
  - **`cache='writeback'`** — usa la caché del host y **confía en que el invitado emita flush**. Un
    invitado que no los emite (o un fallo de host) pierde datos ya confirmados. Aceptable en
    laboratorio y en cargas reconstruibles; **prohibido en datos que importan**.
  - `cache='unsafe'` **ignora los flush**: solo para instalaciones desechables y builds de CI.
- El backend también manda: un zvol o LV **sin caché de escritura protegida por batería/flush
  honesto** no se salva con el modo de caché de QEMU. La integridad es una propiedad de la pila
  entera.
- **`discard='unmap'` + `detect_zeroes`** para que el borrado dentro del invitado libere espacio en
  el thin pool; con `fstrim.timer` activo en el invitado. Sin esto, un thin pool solo crece.
- Rendimiento: `io='native'` (AIO) o `io_uring` según lo que soporte tu QEMU/kernel; medir con `fio`
  **dentro del invitado** contra el mismo perfil de carga, no con `dd`.

### 3.5 Red

- **Bridge** al segmento físico: la VM es un equipo más de la red. Es el caso por defecto para
  servicio.
- **NAT (`default`)**: cómodo, aislado y **suficiente para laboratorio y CI**. En producción crea
  dependencia de `dnsmasq` en el host y complica cualquier flujo entrante.
- **macvtap**: menos capas y buen rendimiento, con una **limitación conocida y sorprendente**: el
  host **no puede hablar con sus propias VMs** por esa interfaz (el tráfico no vuelve por la NIC).
  Rompe cualquier agente, backup o monitorización que corra en el host y consulte a la VM. Además,
  muchos switches no aceptan múltiples MAC por puerto sin configuración previa.
- **SR-IOV / passthrough de VF**: rendimiento casi nativo a cambio de **perder migración en vivo** y
  atarte al modelo de NIC. Decisión consciente y documentada, no optimización oportunista.
- MTU coherente en toda la ruta (bridge, bond, switch, VM): un MTU desalineado se manifiesta como
  "va bien hasta que transfiero un fichero grande".
- `nwfilter` de libvirt sirve para anti-spoofing básico por VM (MAC/IP); **no es la política de
  firewall del entorno**, que se decide en `firewall-policy-standards`.

### 3.6 Snapshots

- **Externos** (`virsh snapshot-create-as --disk-only [--quiesce]`): crean un overlay y dejan la
  imagen base intacta. Se consolidan con **`blockcommit`** (overlay → base) o se descartan. Es el
  modelo soportado y el que permite copiar la base en frío.
- **Internos** (dentro del qcow2): cómodos y frágiles — corrompen más fácilmente, degradan el
  rendimiento acumulando capas y su soporte es peor. **No en producción.**
- **`--quiesce` exige el `qemu-guest-agent` en el invitado**: es lo que congela los filesystems y
  hace el snapshot *consistente con crash* en lugar de "lo que hubiera en el disco en ese instante".
  Sin agente, un snapshot de una base de datos es una apuesta.
- **Un snapshot con memoria no es un backup.** Restaura el estado de RAM y devuelve una VM viva en
  el instante capturado — con las conexiones caducadas, los tickets Kerberos vencidos, el reloj
  atrasado y, si el snapshot es posterior al compromiso, con el atacante dentro. Vive en el mismo
  almacenamiento que el original y muere con él.
- **Las cadenas de snapshots se consolidan.** Una VM con seis overlays acumulados desde hace meses es
  una avería en curso: rendimiento degradado y una cadena que, si se rompe por el medio, se lleva la
  VM entera. Inventaría y purga.

### 3.7 Migración en vivo

Requisitos, todos simultáneos:
1. **CPU compatible** en destino: mismo modelo nombrado o superconjunto. `host-passthrough` entre
   CPUs distintas la rompe.
2. **Mismo `machine type`** disponible en el QEMU de destino (y no eliminado, §3.2).
3. **Almacenamiento**: compartido y visible con la **misma ruta** en ambos hosts, o migración de
   bloques (`--copy-storage-all`/`--copy-storage-inc`), que es mucho más lenta y carga la red.
4. **QEMU/libvirt de destino igual o más nuevo**: hacia atrás no está soportado.
5. **Red**: conectividad entre hosts para el flujo de migración, y que la VM conserve su L2 al llegar
   (mismo bridge/VLAN).

Lo que la rompe además: dispositivos **passthrough (VFIO/SR-IOV)**, `<hostdev>` sin `failover`,
discos con `cache='writeback'` en almacenamiento compartido, y ficheros locales que la VM tiene
abiertos y el destino no tiene. **Migración ≠ HA**: es una operación manual para mantenimiento; si
el host origen muere, no hay migración que hacer.

### 3.8 Passthrough de dispositivos

- Precondiciones: **IOMMU activado** en firmware y kernel (`intel_iommu=on` / `amd_iommu=on`), y el
  dispositivo enlazado a **`vfio-pci`** antes de que lo tome su driver nativo.
- **El grupo de IOMMU es la unidad de aislamiento, no el dispositivo.** Si en el grupo hay más
  dispositivos, **van todos** o no va ninguno. Comprobar `/sys/kernel/iommu_groups` **antes** de
  prometer nada.
- **`pcie_acs_override` y parches similares rompen la garantía de aislamiento** entre dispositivos
  del grupo: aceptable en un laboratorio propio, **prohibido en producción y en multi-tenencia**.
- **GPU passthrough**: trampas conocidas — la GPU primaria del host necesita `vfio-pci` desde el
  arranque o un stub, hay que pasar el **grupo de funciones completo** (vídeo + audio HDMI), el
  firmware de la tarjeta (vBIOS) puede necesitar volcado, y el estado de reinicio de la GPU puede
  impedir arrancar la VM dos veces sin reiniciar el host. Presupuesta tiempo de integración; no es
  una casilla.
- **Passthrough sacrifica migración en vivo, suspensión y, a menudo, snapshots.** Es un intercambio,
  y hay que declararlo antes de comprometer disponibilidad.
- Superficie de seguridad: un dispositivo pasado es DMA hacia el host mediado por el IOMMU. Con el
  IOMMU mal configurado o con overrides de ACS, **el invitado puede escribir memoria del host**.

### 3.9 Herramientas del ecosistema

- **`qemu-img`**: `create`, `convert` (cambio de formato y de backend), `info`, `check`, `resize`,
  `snapshot`. `qemu-img check` sobre una qcow2 sospechosa **antes** de arrancarla.
- **libguestfs**: `guestfish` (shell sobre el filesystem del invitado), `virt-df`, `virt-cat`,
  `virt-ls`, `virt-inspector`. **Nunca sobre una imagen de una VM encendida** salvo en modo lectura
  y sabiendo que la vista es inconsistente; escribir en la imagen de una VM viva la corrompe.
- **`virt-sysprep`**: obligatorio antes de convertir una VM en plantilla — borra machine-id, claves
  de host SSH, logs, historiales, reglas de red persistentes y credenciales. Sin él, todas las VMs
  clonadas comparten identidad (y el DHCP y el logging enloquecen).
- **`virt-customize`**: personalización offline de imágenes (paquetes, ficheros, contraseñas) para
  construir plantillas reproducibles desde código.
- **`virt-install` / `virt-xml`**: creación y modificación de dominios desde script, preferibles a
  editar XML a mano en automatización. `virt-clone` para clonar (y **después** `virt-sysprep`).
- **`virt-viewer`** (SPICE/VNC) para consola; la consola serie (`virsh console`) es la que salva
  cuando la red del invitado no levanta — configúrala **antes** de necesitarla.

## 4. Gates de calidad

Antes de dar por bueno un host o una definición de VM:

1. **Auditoría de `machine type`**: ningún dominio con tipo deprecado o eliminado en el QEMU
   instalado. Se comprueba **antes** de cada upgrade de QEMU, no después del reinicio.
2. **XML en repo**: `virsh dumpxml --inactive` de cada dominio coincide con la definición versionada.
   Diferencia = drift, y es hallazgo.
3. **Coherencia de CPU del parque**: todos los dominios con el modelo nombrado acordado; excepciones
   con `host-passthrough` listadas y justificadas (y marcadas como no migrables).
4. **Arranque en frío probado**: la VM arranca tras reinicio completo del host, con `autostart` donde
   corresponda y sin intervención manual.
5. **Consola serie funcional** en toda VM Linux de producción (`virsh console`), verificada.
6. **`qemu-guest-agent` activo** en todo invitado: sin él no hay `--quiesce`, ni apagado ordenado, ni
   IPs reportadas.
7. **Restore probado**: reconstruir una VM desde su definición + su copia de datos, cronometrado. Si
   no existe copia con restore probado, **el host no está en producción** (`onprem-standards` §1.3).
8. **Cadenas de snapshots limpias**: ningún dominio con overlays acumulados sin fecha ni dueño.
9. **sVirt activo**: SELinux/AppArmor en enforcing y confinando cada dominio; verificado en las
   etiquetas del proceso, no asumido.
10. **Sin transporte de libvirt en claro**: `qemu+tcp` sin auth ni TLS es un fallo bloqueante.
11. **Versiones parcheadas**: kernel/KVM y QEMU al día frente a los CVE de escape vigentes (§5),
    verificando el **kernel arrancado**, no el paquete instalado.

## 5. Seguridad

- **La VM es una frontera de seguridad de verdad, pero no es infinita.** QEMU es un proceso de
  usuario enorme con dispositivos emulados; los escapes invitado→host existen, se publican y **se
  explotan**. Corolarios operativos: reducir dispositivos emulados a los necesarios, parchear rápido
  y no tratar "está en una VM" como fin del análisis.
- **CVEs de referencia verificados a ago-2026** (re-verifica el estado y busca posteriores, §8):
  - **Januscape — `CVE-2026-53359`** (divulgado 06-jul-2026): escape **invitado → host** en el shadow
    MMU x86 de KVM, afectando tanto Intel VMX/EPT como AMD SVM/NPT. **Parchear 53359 no basta**: la
    remediación completa exige también **`CVE-2026-46113`** (corregido en may-2026, caso de *leaf
    shadow page*; 53359 cubre el *non-leaf*). Mitigación mientras tanto: **desactivar la
    virtualización anidada** donde no sea imprescindible.
  - **Escape vía `virtio-snd` en QEMU** (mar-2026): desbordamiento de heap convertido en escape
    fiable, **con exploit público**. Regla derivada: **no expongas dispositivos emulados que la carga
    no necesita** — audio, USB, webcam, puertos serie de más. Cada dispositivo es superficie.
  - **`CVE-2026-0665`**: off-by-one en el soporte de Xen sobre KVM de QEMU (hypercall `physdev`),
    accesos fuera de límites desde un invitado malicioso.
- **Virtualización anidada apagada por defecto.** Es la mitigación que aparece una y otra vez, y casi
  ninguna VM la necesita.
- **sVirt es obligatorio**: SELinux (`svirt_t`/`svirt_image_t`) o AppArmor etiquetan cada dominio para
  que un QEMU comprometido no alcance las imágenes de los demás. **Desactivar SELinux/AppArmor "para
  que arranque la VM" elimina el único control que contiene un escape parcial**; el diagnóstico
  correcto es de `selinux-standards` (booleanos como los de NFS, `virt-*`, contextos de imagen). No se
  desactiva: se etiqueta bien.
- **QEMU corre como usuario sin privilegios** (`qemu:qemu`, configurable en `/etc/libvirt/qemu.conf`).
  Nunca como root "para simplificar permisos": si un fichero no es accesible, se corrigen permisos y
  etiquetas.
- **El socket de libvirt es root efectivo sobre el host.** Pertenecer a `libvirt`/`libvirt-qemu`
  equivale a poder arrancar una VM que monte el disco del host: **trátalo como sudo sin contraseña** y
  no lo repartas. libvirt **no tiene RBAC útil** (`polkit` da un control grueso); si necesitas
  permisos por VM y por persona, necesitas plataforma (§1.1).
- **Transporte**: `qemu+ssh://` por defecto; TLS con PKI interna si hace falta. **`auth_tcp="none"`
  es entrega de root remoto**; no existe justificación en producción.
- **Cifrado en reposo**: LUKS por debajo (host) o cifrado nativo del backend; el cifrado interno de
  qcow2 solo con criterio y con la clave gestionada por `virsh secret-*` y custodiada fuera.
- Invitados no confiables: VM dedicada, red aislada, cero passthrough, cero carpetas compartidas, y
  el host tratado como potencialmente alcanzable. Si el propósito es detonar malware, el criterio de
  aislamiento es de `ctf-lab-standards`.
- **Adquisición forense**: `virsh dump` (o el snapshot con memoria) captura la RAM de una VM viva sin
  tocar el invitado — mecanismo excelente. El orden de volatilidad, el hash y la cadena de custodia
  son de `incident-response-forensics-standards`.

## 6. Rendimiento y operabilidad

- **Qué vigilar** (el diseño del stack es de `observability-standards`): estado de cada dominio,
  `steal time` en los invitados, presión de memoria del host y actividad de swap (**el host de
  virtualización no debería paginar nunca**), latencia y saturación de la E/S de backend, errores de
  `virtio`, temperatura/SMART, y el estado de la última copia y del último restore probado.
- El exporter de libvirt/`libvirt_exporter` da métricas por dominio; sin él, "la VM va lenta" es
  irresoluble.
- **Sobrecompromiso**: vCPU se sobrecomprometen con medida (`steal` como señal); **la memoria no**,
  salvo con ballooning entendido. Un host que swapea arrastra a todas sus VMs a la vez.
- **Apagado ordenado del host**: `libvirt-guests` (o equivalente) configurado para **suspender o
  apagar limpiamente** los dominios al parar el host, y probado. Un corte que mata 20 VMs a la vez
  produce 20 filesystems por revisar.
- **Arranque**: `autostart` en los dominios que deben volver solos, y **orden/retardo** entre ellos si
  hay dependencias (base de datos antes que aplicación). Comprobado con un reinicio real.
- **Los daemons modulares se activan por socket** y salen por inactividad (típicamente
  `--timeout=120`), reiniciándose al llegar un cliente. **Reiniciar `virtqemud` no interrumpe los
  invitados en marcha** — pero evítalo con VMs vivas si puedes.
- Capacidad: reserva memoria y CPU para el **host** (E/S, ZFS ARC, monitorización). Dimensionar al
  100% de la RAM en VMs es cómo se llega a que el host swapee.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- QEMU y kernel/KVM: parches de seguridad con la cadencia de la distro, y **fuera de ciclo ante un
  CVE de escape** con exploit público. Requiere apagar/reiniciar la VM (o el host, para el kernel):
  planifica la ventana, no la improvises.
- libvirt: seguir la rama de la distro; leer el `NEWS` antes de un salto de major (p. ej. **12.4.0
  subió el QEMU mínimo a 7.2.0**).
- **Auditoría anual de `machine type`** de todo el parque contra la lista de deprecados, con plan de
  subida. Es la deuda que se cobra sola en el peor momento.
- Migración de `libvirtd` monolítico a **daemons modulares** con fecha: upstream lo eliminará y las
  distros ya lo dan por defecto en instalaciones nuevas.
- `virtio-win` en invitados Windows: actualizar con las herramientas del invitado, no dejarlo en la
  versión de la instalación.

**PROHIBIDO**
- ❌ Usar libvirt puro donde el requisito real era HA, backup integrado o RBAC multi-operador (§1.1);
  reimplementar una plataforma a base de scripts sobre `virsh`.
- ❌ Alias de `machine type` (`q35`, `pc`) en una definición; dejar tipos deprecados sin plan.
- ❌ Actualizar QEMU sin auditar antes los `machine type` del parque.
- ❌ `host-passthrough` en un parque que debe migrar entre hosts distintos.
- ❌ Virtualización anidada activada "por si acaso" (§5).
- ❌ `cache='writeback'` (y no digamos `unsafe`) en datos que importan.
- ❌ qcow2 sobre zvol o sobre LVM-thin; snapshots internos de qcow2 en producción.
- ❌ Copiar una imagen en caliente sin `--quiesce`/snapshot y llamarlo backup.
- ❌ Tratar un snapshot —con o sin memoria— como copia de seguridad.
- ❌ Dejar cadenas de overlays sin consolidar ni dueño.
- ❌ `qemu+tcp` sin TLS ni autenticación; `auth_tcp="none"`.
- ❌ Repartir pertenencia al grupo `libvirt` como si fuera un permiso de lectura: es root en el host.
- ❌ Ejecutar QEMU como root; desactivar SELinux/AppArmor para que arranque una VM.
- ❌ `pcie_acs_override` o equivalentes en producción o en multi-tenencia.
- ❌ Clonar una VM sin `virt-sysprep`.
- ❌ Editar la imagen de una VM encendida con libguestfs.
- ❌ VM de producción sin `qemu-guest-agent` ni consola serie.
- ❌ El host como única copia de la definición del dominio (XML solo en `/etc/libvirt`).
- ❌ Sobrecomprometer memoria hasta que el host swapee.
- ❌ Ejecutar QEMU compilado a mano en producción, fuera del canal de parches de seguridad.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, política o nombre de feature, **búscalo — no lo recuerdes**. Lo
verificado a ago-2026 y lo que queda abierto:

1. **QEMU**: verificado **11.0.0 (22-abr-2026)** como última estable de la serie (punto **11.0.3**,
   24-jul-2026); **11.1 aún en RC** (11.1.0-rc2, 29-jul-2026) — comprueba si ya salió. Verificado
   que 11.0 **elimina** `pc-i440fx-2.6`, `pc-q35-2.6`, `pc-i440fx-2.7` y `pc-q35-2.7` y **retira el
   soporte de hosts de 32 bits**.
2. **Política de machine types**: verificada literalmente en `qemu.org/docs/master/about/deprecated.html`
   — 6 años/18 releases, deprecación a los 3 años/9 releases, borrado 3 años después, y **todos los
   `8.1.0` o anteriores deprecados hoy**. **Re-lee esa página antes de cada upgrade**: la lista se
   mueve en cada release.
3. **libvirt**: verificado **12.6.0 (03-ago-2026)** como última publicada (12.5.0 el 01-07-2026,
   12.4.0 el 01-06-2026, que **subió el QEMU mínimo a 7.2.0**). Lee el `NEWS` de las versiones que
   saltes.
4. **Daemons modulares**: verificado el reparto de responsabilidades (`virtqemud` y compañía,
   `virtproxyd` para remoto/legacy, socket con `--timeout=120`, reinicio sin cortar invitados) y que
   upstream **eliminará `libvirtd`**. **Hueco declarado**: no se ha confirmado una **fecha concreta**
   de eliminación de `libvirtd` ni el estado exacto por distribución más allá de RHEL 9 (instalaciones
   nuevas modulares, upgrades desde RHEL 8 monolíticas) y SUSE. Confírmalo para tu distro.
5. **CVEs**: verificados **CVE-2026-53359 ("Januscape", 06-jul-2026)**, la dependencia de
   **CVE-2026-46113** para la remediación completa, el **escape vía `virtio-snd`** de mar-2026 con
   exploit público, y **CVE-2026-0665** (Xen sobre KVM en QEMU). **Busca CVEs posteriores** en QEMU,
   kernel/KVM y libvirt antes de fijar una versión mínima, y consulta el aviso de **tu** distribución:
   los números de versión upstream no se mapean mecánicamente a los paquetes.
6. **Huecos declarados adicionales** (no verificados por web en esta redacción; el criterio se apoya
   en el comportamiento documentado del stack, **confírmalos antes de citarlos como dato**):
   - La **matriz exacta de modos de caché** (`none`/`writeback`/`directsync`/`unsafe`) frente a
     `cache.direct`/`cache.writeback`/`cache.no-flush` y su interacción con la migración en vivo en
     la versión de QEMU instalada: se lee en la documentación de libvirt de `<driver cache=…>`.
   - El **estado de `io_uring`** como backend de E/S soportado y recomendado en tu QEMU/kernel.
   - La **limitación de macvtap host↔VM** (§3.5): comportamiento conocido y estable del stack, pero
     no reverificado contra fuente primaria en esta redacción.
   - El estado y las opciones de **virtualización confidencial** (AMD SEV-SNP, Intel TDX) en libvirt
     y QEMU 11.x, que QEMU 11.0 amplió con soporte de reinicio: **no cubierto en este documento**.
   - La política de soporte de **`virtio-win`** y su versión recomendada para cada Windows.
7. **Antes de cualquier upgrade cruzado** (libvirt ↔ QEMU ↔ kernel ↔ backend de almacenamiento): la
   matriz de compatibilidad de la distribución, no la intuición.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
