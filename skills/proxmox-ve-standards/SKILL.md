---
name: proxmox-ve-standards
description: Proxmox VE and Proxmox Backup Server as a production virtualization platform. Use when running pvecm, ha-manager, pvesh, pveum, pvesm, pvesr, pveceph, pveperf, qm, pct or vzdump, editing /etc/pve files (corosync.conf, storage.cfg, datacenter.cfg, qemu-server/*.conf, lxc/*.conf, user.cfg, sdn/), sizing cluster quorum and QDevice (corosync-qdevice), HA groups, affinity rules and watchdog fencing, PVE SDN zones/vnets/fabrics or EVPN controllers, Linux bridge versus OVS on a PVE node, choosing among LVM-thin, ZFS, Ceph, NFS or iSCSI PVE storage types and their snapshot support, replication jobs between nodes, privileged versus unprivileged LXC containers, cloud-init VM templates, PVE roles and API tokens instead of root@pam, enterprise versus no-subscription repositories, the ESXi import wizard and VMware exit, or Proxmox Backup Server datastores, namespaces, verify/prune/garbage-collect and sync jobs, proxmox-backup-client and S3-backed datastores.
---

# Estándares de Proxmox VE y Proxmox Backup Server

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: en Proxmox VE las decisiones irreversibles no están en la VM, están en el
> **cluster**. La red de Corosync, el número de nodos, el tipo de storage y el modelo de CPU se
> eligen una vez y condicionan todo lo demás; una VM se reconfigura en un minuto. Dedica el esfuerzo
> de diseño a lo que no se cambia sin vaciar el cluster.

## 1. Alcance y triggers

Aplica a Proxmox VE y Proxmox Backup Server **como plataforma de producción**: diseño y quórum del
cluster, HA y fencing, elección y operación del storage de PVE, red del hipervisor y SDN, ciclo de
vida de VMs y contenedores LXC, PBS como producto de respaldo, RBAC y automatización por API,
cadencia de actualización del cluster, y migración desde VMware.

Disparadores: `pvecm`, `ha-manager`, `pvesh`, `pveum`, `pvesm`, `pvesr`, `pveceph`, `pveperf`,
`pveversion`, `qm`, `pct`, `vzdump`, `proxmox-backup-client`, `proxmox-backup-manager`,
`/etc/pve/` (`corosync.conf`, `storage.cfg`, `datacenter.cfg`, `qemu-server/<vmid>.conf`,
`lxc/<ctid>.conf`, `user.cfg`, `sdn/`), `/etc/apt/sources.list.d/pve-enterprise.*`,
`corosync-qdevice`, `pve-esxi-import-tools`, "nodo sin quórum", "el cluster se ha partido",
"la VM no migra", "datastore de PBS", "verify job", "garbage collect".

**Regla de arbitraje interna**: si la respuesta se escribe con un comando `pve*`/`qm`/`pct` o
tocando un fichero bajo `/etc/pve/`, es de esta skill. Si se escribe con `virsh` o editando XML de
dominio, es de `libvirt-kvm-standards`.

### 1.1 Frontera con `libvirt-kvm-standards` (la más fina del par)

PVE usa KVM/QEMU, pero **no usa libvirt**: gestiona QEMU directamente desde `qemu-server`. En
consecuencia:

| Se decide aquí | Se decide en `libvirt-kvm-standards` |
|---|---|
| Si hay cluster, quórum, HA y fencing | Si el host es único y no hay plataforma |
| Storage como **tipo de PVE** (`storage.cfg`) y qué soporta snapshot | Pool/volumen de libvirt, `qemu-img`, formato del disco a bajo nivel |
| El **perfil de VM** que fija PVE (virtio, agente, tipo de CPU del cluster) | El **XML del dominio** completo: `machine type`, `iothreads`, `numatune`, `<cpu>` |
| Backup integrado (PBS/vzdump) y su retención | Que **no hay** backup integrado: es motivo para no usar libvirt puro en producción |
| RBAC, tokens de API, pools de recursos | `libvirtd`/daemons modulares, sVirt, socket y permisos locales |
| Migración en vivo como **operación de cluster** | Los **requisitos** de compatibilidad que la hacen posible |

**El XML del dominio no se documenta aquí.** Si estás editando XML en un host PVE, casi siempre
estás haciendo algo mal (`args:` en el `.conf` está fuera del modelo soportado y rompe migración,
snapshot y soporte).

**No aplica**: ver `libvirt-kvm-standards` (**la frontera hermana**, §1.1 arriba: el sustrato
KVM/QEMU sin plataforma; hosts sueltos, laboratorio, CI), `onprem-standards` (**paraguas**: su §2
fija la elección de hipervisor y de backup de VM y esta skill la desarrolla sin contradecirla; su
§1.3 fija los invariantes, en particular *HA sin fencing probado es corrupción diferida* y *un
backup sin restore probado no existe*), `ha-clustering-standards` (**Ola 2, planificada** —
**frontera quirúrgica**: allí Pacemaker/Corosync **genérico** para dar HA a **servicios** Linux
(recursos, constraints, agentes OCF, STONITH de dispositivo); aquí el cluster de PVE, que trae su
propio stack —`pve-cluster`/`pmxcfs`, `pve-ha-manager`, watchdog— y **no se opera con `pcs` ni
`crm`**. Regla: **si el recurso que conmuta es una VM o un contenedor de PVE, es de aquí; si es un
servicio dentro de un SO, es de allí.** Corosync es común a ambas: los principios de quórum,
latencia y redundancia de enlace valen igual), `zfs-standards` (**el pool por debajo**: topología de
vdev, `ashift`, `recordsize`/`volblocksize` del zvol, ARC, scrub, `zfs send` como mecanismo — **el
diseño del pool es suyo, su uso como storage de PVE es de aquí**), `bcdr-standards` (RTO/RPO
derivados del negocio, orden de recuperación, ejercicios de DR, declaración del desastre — **PBS es
la herramienta, no la estrategia**), `backup-recovery-standards` (**mecánica genérica del respaldo**:
restic/Kopia/Borg/Bareos, cadenas full/incremental, topología 3-2-1-1-0, repositorios append-only,
GFS, restores de prueba automatizados — **PBS como producto y sus jobs son de aquí**; el criterio
transversal de retención, inmutabilidad y verificación es suyo y este documento no lo contradice),
`linux-storage-standards` (LVM y LVM-thin, multipath, iniciador iSCSI, NVMe, filesystems y LUKS
**por debajo** del storage de PVE: `storage.cfg` es de aquí, `lvs`/`multipath -ll`/`iscsiadm` son
suyos), `object-storage-standards` (**Ola 2, planificada**: el bucket S3 que respalda un
datastore de PBS), `linux-administration-standards` (el SO Debian del nodo: systemd, journald,
diagnóstico), `linux-hardening-standards` (baseline CIS del nodo, `sshd_config`, auditd),
`selinux-standards` (MAC; PVE usa **AppArmor** para LXC — los perfiles son de allí),
`networking-standards` (**diseño** de red: VLAN, routing, BGP; aquí solo la configuración del nodo y
la SDN de PVE), `firewall-policy-standards` (**la política de filtrado como artefacto gobernado**:
matriz de flujos, propiedad y caducidad de reglas, nftables; aquí solo que el firewall de PVE se
activa con *default-deny* y se expresa por VM/grupo de seguridad), `dns-standards`, `iac-standards`
(Terraform/OpenTofu y Ansible que **definen** las VMs; aquí qué debe contener la definición),
`observability-standards` (diseño de métricas y alertas; aquí **qué** hay que vigilar de PVE/PBS),
`kubernetes-standards` (workload en contenedor sobre un cluster K8s, aunque sus nodos sean VMs de
PVE), `container-runtime-security-standards` (seguridad del contenedor OCI en ejecución; el LXC de
PVE **no es un contenedor OCI** y su criterio está en §3.5),
`vulnerability-management-standards` (triaje de un CVE concreto), `identity-access-management-standards`
(el IdP al que se federa PVE), `secrets-management-standards` (custodia de tokens y claves de
cifrado de backup), `windows-server-ad-standards` (VMs Windows: drivers virtio-win, AD),
`incident-response-forensics-standards` (adquisición de memoria de una VM comprometida),
`homelab-standards` (**la frontera es el rigor exigido, no el tamaño**: allí un nodo PVE de
laboratorio donde el criterio es coste, ruido y consumo; aquí producción con RTO/RPO comprometido),
`vmware-standards` (**Ola 7 — frontera de origen, no de destino**: **la decisión de quedarse o
salir de VMware, su modelo de licencia y lo que se rompe al migrar son suyos**; **aquí la
plataforma de llegada** y su operación. El asistente de importación de PVE es de aquí; el inventario
de lo que hay que sacar y su coste, de allí), `xen-standards` y `hyper-v-standards` (**Ola 7**: los
otros dos hipervisores del catálogo, cada uno con su skill — la comparación se escribe desde la
skill del hipervisor en cuestión, no aquí).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un sistema real (§8).

| Ámbito | Por defecto | Alternativa justificable / Prohibido |
|---|---|---|
| Versión de PVE | **PVE 9.2** (21-may-2026): Debian 13.5, kernel 7.0, QEMU 11.0, LXC 7.0, ZFS 2.4 | ❌ **PVE 8.x en producción a partir de sep-2026: EOL el 31-ago-2026** (el SO entero deja de recibir parches, no solo PVE). Salto 8.4 → 9.x por el procedimiento oficial, nunca por dist-upgrade a mano |
| Versión de PBS | **PBS 4.2** (29-abr-2026): Debian 13.4, kernel 7.0, ZFS 2.4 | PBS y PVE se actualizan **coordinados**; comprueba compatibilidad antes de desacoplarlos |
| Tamaño de cluster | **3 nodos mínimo** para HA (quórum real) | 2 nodos **solo** con QDevice (`corosync-qdevice`) en un tercer sitio; ❌ 2 nodos "con HA" sin QDevice; ❌ nodo suelto haciendo de árbitro con red compartida |
| Red de Corosync | **NIC física dedicada**, latencia **< 5 ms** entre todos los nodos, y **al menos 2 links** (`link0`/`link1` en redes distintas) | ❌ Corosync compartiendo red con almacenamiento o replicación (salvo como link de **fallback de baja prioridad**); ❌ un solo link sobre un bond como toda la redundancia; >10 ms es inestable con más de 3 nodos |
| Fencing | **Watchdog** (hardware si el BMC lo ofrece, `softdog` si no) configurado y **ejercitado** antes de activar HA | ❌ Activar `ha-manager` sin haber apagado un nodo y cronometrado el failover |
| Storage por defecto | **ZFS local + replicación `pvesr`** para clusters pequeños (2-5 nodos, RPO en minutos) | **Ceph** desde **3 nodos idénticos** y con red propia; **NFS/iSCSI** si ya hay una cabina y se acepta el SPOF que introduce |
| Ceph | Mínimo **3 servidores preferiblemente idénticos**; `size=3`, `min_size=2`; red **exclusiva ≥ 10 Gbps** | ❌ `min_size=1` (permite E/S con una sola réplica: pérdida de datos); ❌ Ceph con 3 nodos "porque el mínimo es 3" si no hay red dedicada ni presupuesto de mantenimiento; realista a partir de **5 nodos** |
| Ceph release | **Tentacle 20.2.1** para despliegues nuevos en PVE 9.2; **Squid 19.2.3** sigue empaquetado | El upgrade de Ceph y el de PVE se hacen **en pasos separados** y en el orden documentado, nunca a la vez |
| Red de VMs | **Linux bridge** con `VLAN aware`, sobre **bond LACP (802.3ad)** a switches MLAG/apilados | **OVS** solo si necesitas algo que el bridge Linux no da (y sabrás cuál es); ❌ OVS "porque suena mejor" |
| Perfil de VM | **virtio-scsi single** + `qemu-guest-agent` + `discard` + `iothread`; UEFI/OVMF salvo motivo | ❌ IDE/SATA emulado o `e1000` fuera de un arranque de rescate; ❌ VM en producción sin agente (rompe snapshot consistente, shutdown ordenado e IPs en la GUI) |
| Tipo de CPU | **Un modelo nombrado común a todo el cluster** (el mayor que soporten todos los nodos), definido como custom CPU model en el datacenter | ❌ `host` en un cluster heterogéneo: **rompe la migración en vivo** y, en kernels vulnerables, expone rutas de virtualización anidada (§5) |
| Contenedores | **LXC no privilegiado** (por defecto desde PVE 4.4) para servicios internos que no necesitan kernel propio | **VM** siempre que haya multi-tenencia, código no confiable, kernel distinto o requisito de aislamiento; ❌ LXC privilegiado tratado como frontera de seguridad (§3.5) |
| Backup | **PBS** con cifrado **del lado cliente**, `verify` + `prune` + `garbage-collect` programados y **sync a un segundo repositorio** | `vzdump` a NFS solo como copia secundaria puntual; ❌ vzdump suelto sin verificación ni retención como única copia; ❌ "backup" = snapshot del hipervisor |
| Automatización | **Token de API con rol de mínimo privilegio** y `privsep`, por servicio | ❌ `root@pam` (ni su token) en Terraform, Ansible, CI o un exporter |
| Repos | **`pve-enterprise` con suscripción** en producción | `pve-no-subscription` es válido técnicamente pero **no es la cola de paquetes probada**; ❌ `pvetest` en producción; ❌ mezclar repos de Debian de terceros en el nodo |

## 3. Diseño y convenciones

### 3.1 Cluster y quórum

- El cluster PVE es **pmxcfs sobre Corosync**: `/etc/pve` es un filesystem replicado que **se vuelve
  de solo lectura al perder quórum**. Un nodo sin quórum no arranca VMs ni acepta cambios: eso es el
  diseño funcionando, no una avería.
- **Número impar de nodos** o QDevice. Con número par y sin árbitro, una partición 50/50 deja el
  cluster entero en solo lectura.
- **Corosync tolera poca latencia y ningún jitter, pero casi nada de ancho de banda.** Por eso la
  regla es red **dedicada**, no red rápida: un enlace de 1 Gbps limpio es mejor que compartir un
  25 Gbps con Ceph. Corosync admite hasta 8 links; usa **al menos 2, en caminos físicos distintos**.
- Un bond **no sustituye a un segundo link**: protege del fallo de un cable, no del de un switch mal
  configurado, un bucle o una tormenta de broadcast que afecta a todo el bond.
- Nodo nuevo: se une **vacío**; unir un nodo con VMs definidas destruye su `/etc/pve`. Retirar un
  nodo es `pvecm delnode` y **no se reutiliza el hostname/VMID sin reinstalar**.
- Los enlaces de Corosync se cambian con el cluster **sano** y siguiendo el procedimiento
  (`corosync.conf` con `config_version` incrementado, distribuido por pmxcfs); editar a mano en un
  nodo sin quórum parte el cluster.

### 3.2 HA y fencing

- `ha-manager` solo actúa sobre recursos declarados; una VM crítica que nadie añadió a HA **no
  conmuta**. Inventaría qué recursos son HA y cuáles no, explícitamente.
- **Fencing en PVE es por watchdog + pérdida de quórum**: el nodo que se queda sin quórum se
  auto-reinicia. Esto implica que **la red de cluster es el mecanismo de fencing**: si es frágil,
  el fencing dispara solo. Otra razón para la red dedicada y redundante.
- **HA groups / reglas de afinidad** (PVE 9: reglas de afinidad y anti-afinidad): úsalas para separar
  los nodos de un cluster de aplicación (etcd, base de datos replicada) y para juntar VMs que se
  hablan mucho. Sin anti-afinidad, HA puede reunir las tres réplicas en un nodo.
- **El failover se ensaya apagando un nodo** (`poweroff` físico o corte de PSU, no `shutdown`
  ordenado), en ventana acordada, cronometrando el tiempo hasta que el servicio responde. Sin ese
  ensayo, HA es una casilla marcada, no una capacidad. Invariante de `onprem-standards` §1.3.
- El balanceador dinámico de carga de PVE 9.2 reubica carga; **no sustituye a la anti-afinidad ni al
  dimensionamiento**: un cluster que solo aguanta con N nodos vivos no tolera perder uno.

### 3.3 Almacenamiento

Criterio, en orden de preferencia por **simplicidad que cumpla el RPO**:

1. **ZFS local + replicación programada (`pvesr`)** — 2 a 5 nodos. RPO = intervalo de réplica
   (minutos), no cero. Sin red de almacenamiento, sin cabina, sin quórum de datos. Es la opción por
   defecto para la mayoría de clusters pequeños. El diseño del pool es de `zfs-standards`.
2. **Ceph** — a partir de **3 nodos idénticos** por documentación, pero **realista desde 5**: con 3
   nodos, perder uno durante un mantenimiento te deja sin margen de reconstrucción. Exige red propia
   ≥10 Gbps (25+ para el tráfico interno en despliegues serios) y **un dueño que lo mantenga**. Ceph
   mal dimensionado es peor que NFS.
3. **NFS / iSCSI / FC contra cabina** — válido si ya existe la cabina y su HA es real. Introduce un
   SPOF externo al cluster y su latencia. Con LVM sobre iSCSI/FC, PVE 9 aporta snapshots sobre LVM
   *thick* compartido mediante cadenas de volúmenes; verifica el soporte exacto para tu tipo de
   storage antes de prometer snapshots.

Reglas transversales:

- **Los snapshots dependen del tipo de storage.** No prometas snapshot ni backup consistente sin
  comprobar qué soporta ese storage en la versión instalada — es la causa habitual de "no puedo
  hacer snapshot antes de actualizar".
- **Thin provisioning se vigila o corrompe**: en LVM-thin y ZFS, sobrecomprometer sin alerta de
  ocupación real acaba en pool lleno y VMs en solo lectura o corruptas. Alerta con umbral y margen
  (ZFS: no pasar del 80%).
- **Un snapshot no es un backup** (vive en el mismo pool y muere con él) y **un snapshot con memoria
  tampoco**: es un punto de restauración local.
- El disco de la VM sobre ZFS es un **zvol**: su `volblocksize` es decisión de `zfs-standards` y se
  fija **en la creación**; cambiarlo exige recrear el volumen.

### 3.4 Red y SDN

- **Separación de planos, obligatoria**: gestión/PVE-UI, Corosync, almacenamiento/replicación,
  tráfico de VMs y backup. Mínimo: Corosync aparte de todo lo demás; almacenamiento aparte del
  tráfico de VMs.
- Interfaz de gestión de PVE **nunca expuesta a red de usuario ni a Internet**: bastión o VPN. El
  puerto 8006 en Internet es un incidente esperando fecha.
- **Bridge Linux VLAN-aware** sobre bond LACP es el caso por defecto y el mejor soportado. OVS añade
  superficie y modos de fallo; se justifica por una función concreta, no por preferencia.
- **SDN de PVE**: integrada en el producto y desarrollada activamente. Zonas simples/VLAN/QinQ/VXLAN
  y **EVPN** para L3 entre nodos; **Fabrics** (PVE 9.0: OpenFabric y OSPF; 9.1: redistribución de
  rutas OSPF y múltiples controladores EVPN; 9.2: protocolo **WireGuard**, route-maps y prefix-lists
  BGP, underlay IPv6 para EVPN) construyen topologías spine-leaf desde la interfaz en lugar de editar
  FRR a mano. **Verifica en las release notes qué parte está marcada como experimental en tu versión
  exacta antes de meterla en producción**: la SDN ha ido madurando por partes, no en bloque.
- Cortafuegos de PVE: activarlo a nivel de datacenter con política **default-deny** de entrada y
  reglas por VM/grupo de seguridad. Un cortafuegos de host activado sin regla de gestión te deja
  fuera: cambio con consola OOB abierta.

### 3.5 VMs y contenedores

- **La decisión LXC vs VM es de aislamiento, no de rendimiento.** LXC comparte kernel con el host.
  Un **LXC privilegiado no es una frontera de seguridad**: root dentro es root en el host (sin
  remapeo de UID), y el propio proyecto LXC declara insegura esa configuración y **no trata los
  escapes desde contenedor privilegiado como CVE**. Lo que queda son namespaces, capabilities y
  AppArmor: defensa en profundidad, no límite de confianza.
- LXC **no privilegiado** (default) remapea UID 0 a un UID sin privilegio del host, y es el único
  modo que se puede razonar como frontera. Casos que aún empujan a privilegiado (cliente NFS/CIFS
  del kernel, algunos passthrough de GPU): si aparecen, **la respuesta correcta suele ser una VM**.
- Nada de multi-tenencia ni de código no confiable en LXC: **eso es una VM**.
- **Plantillas + cloud-init** para todo lo que se cree más de una vez; VMID y naming por convención;
  la definición vive en el repo de IaC (`iac-standards`), no en clics.
- **CPU coherente en el cluster**: un modelo nombrado común (o un custom CPU model del datacenter,
  editable desde la GUI en 9.2). `host` maximiza rendimiento y **minimiza portabilidad**.
- Ballooning: útil para sobrecomprometer memoria en entornos con picos desacoplados; **desactívalo**
  en VMs con memoria fijada por la aplicación (bases de datos, JVM dimensionada, hugepages). NUMA
  activado en VMs grandes y `cores`/`sockets` coherentes con el hardware.
- `args:` en el `.conf` de la VM (paso directo de argumentos a QEMU) es **último recurso**: no está
  soportado, puede romper migración y snapshots, y desaparece del modelo en cada upgrade.

### 3.6 PBS

- **Modelo**: datastore con deduplicación por chunks + **cifrado del lado cliente** (la clave la
  tiene el cliente; PBS almacena cifrado y **no puede restaurar sin ella**). Corolario duro:
  **la clave se custodia fuera del sistema respaldado** o el backup es papel picado
  (`secrets-management-standards`, `bcdr-standards`).
- **Los tres trabajos son obligatorios y distintos**: `verify` (relee y comprueba integridad de los
  chunks — un backup nunca verificado no está probado), `prune` (aplica la política de retención
  marcando snapshots) y `garbage-collect` (libera de verdad el espacio de los chunks sin referencia).
  Prune sin GC no libera nada; GC sin prune no borra nada. Programa los tres y **alerta si fallan**.
- **Namespaces** para separar orígenes/tenants dentro de un datastore, y **sync jobs** (pull o push)
  hacia un segundo PBS, idealmente en otro sitio y **fuera del dominio de confianza de producción**
  (el ransomware ataca primero el backup accesible). PBS 4.2 añade cifrado en servidor para push sync
  y `worker-threads` para paralelizar grupos en enlaces con latencia.
- **Backend S3**: introducido como *technology preview* en PBS 4.0 y **oficialmente soportado desde
  PBS 4.2** (29-abr-2026), con contador de peticiones y tráfico por datastore. Límites que cambian el
  diseño: cada datastore S3 lo gestiona **una única instancia de PBS**, hay caché local de metadatos
  y chunks, y **PBS no soporta Object Lock ni versionado** — activar Object Lock en el bucket puede
  dañar la estructura del datastore. Conclusión: **S3 es una copia adicional / offsite barata, no
  sustituye al PBS local ni aporta por sí solo la inmutabilidad** que exige el escenario ransomware.
  Verifica este punto en la documentación oficial antes de diseñar sobre él (§8).
- **La regla dura**: *un job en verde no es un backup*. Lo que cuenta es un **restore real y
  cronometrado**: fichero suelto, VM completa y —al menos una vez— **el propio PBS** desde cero. Se
  programa, se mide contra el RTO y el resultado entra en monitorización.
- La **estrategia** (qué se protege, con qué RTO/RPO, en qué orden se recupera, quién declara el
  desastre) es de `bcdr-standards`. Aquí solo la mecánica del producto.

### 3.7 Operación

- **RBAC real**: roles por función sobre paths (`/vms/<id>`, `/storage/<id>`, `/pool/<pool>`), pools
  de recursos para agrupar por servicio/cliente, y **tokens de API con `privsep`** y permisos
  mínimos por integración. `root@pam` es para emergencias, con contraseña en gestor de secretos y
  MFA (TOTP/WebAuthn) obligatorio en toda cuenta humana. Autenticación contra el IdP corporativo
  (LDAP/AD/OIDC) para las personas; tokens locales para las máquinas.
- **Actualización rodando por el cluster**, un nodo cada vez: `migrate` fuera → `apt full-upgrade` →
  `reboot` → comprobar quórum, HA y estado de Ceph/ZFS → **rebalancear** → siguiente nodo. Nunca dos
  nodos a la vez; nunca con el cluster degradado o Ceph en `HEALTH_WARN` por reconstrucción.
- **Kernel y microcódigo**: reinicio requerido; planifícalo en la misma ventana. Verifica el kernel
  realmente arrancado (`uname -r`) contra el instalado, no el paquete.
- **Ciclo de vida**: una major de PVE se soporta mientras su Debian base es *oldstable*, ~3 años
  desde su salida. Ten fechado el salto **antes** del EOL, con un nodo o cluster de staging que haga
  el camino primero.

### 3.8 Migración desde VMware

- Contexto (verifícalo, cambia por trimestre): el licenciamiento post-Broadcom —fin de licencias
  perpetuas, retirada del ESXi gratuito, mínimos de 16 cores por CPU y de 72 cores por pedido en
  VCF/VVF, subidas de coste de varios múltiplos— ha empujado una salida masiva; Proxmox VE es el
  principal receptor y XCP-ng/Vates una alternativa menor pero viva. **La decisión de plataforma es
  de `onprem-standards` §2**; aquí, cómo se ejecuta la migración.
- **Asistente de importación integrado** (storage de tipo ESXi, `pve-esxi-import-tools`): importa la
  VM entera mapeando la mayor parte de la configuración, con opción de importación en vivo para
  reducir la parada. Límites verificados: probado con **ESXi 6.5 a 8.0**; **discos sobre vSAN no
  funcionan**; ESXi sobrecargado **limita peticiones y bloquea importaciones en curso** (el servicio
  `esxi-folder-fuse` limita a 4 conexiones paralelas); el ESXi **gratuito no expone la API** que el
  asistente necesita. En campo, conectar **directo al host ESXi** suele funcionar donde vCenter falla,
  y la importación en vivo exige red muy estable. Estos límites proceden de documentación y reportes
  de 2024-2025: **re-verifica el estado actual en el wiki y el Bugzilla antes de planificar** (§8).
- **Antes de mover nada**: instala **virtio y qemu-guest-agent en el invitado mientras sigue en
  ESXi** (en Windows, los drivers virtio-win). Migrar primero y luego pelearse con un Windows que no
  arranca por cambio de controlador de disco es el error clásico.
- Qué se rompe con frecuencia: arranque BIOS/UEFI y orden de arranque, controlador de disco, nombres
  de interfaz de red (y con ellos IPs estáticas y reglas de firewall), VMware Tools residual, licencias
  atadas a UUID/MAC, discos independientes o RDM, y todo lo que dependa de funciones de vSphere sin
  equivalente (DRS afinidades, políticas de storage). **Migra por lotes, con ventana y plan de vuelta
  atrás**; la VM original se conserva apagada hasta validar.

## 4. Gates de calidad

Antes de dar por buena una plataforma PVE/PBS:

1. **Quórum verificado**: `pvecm status` con todos los votos esperados, y `corosync-cfgtool -s` con
   **todos los links up**. Un link caído desde hace semanas y nadie enterado es el estado previo a
   todo cluster partido.
2. **Latencia de Corosync medida** (< 5 ms, sin picos) y **red de cluster demostrablemente separada**
   de storage y de tráfico de VMs.
3. **Fencing probado**: apagado brusco de un nodo con HA activo; se registra el tiempo hasta que el
   servicio vuelve y se compara con el RTO comprometido. Mínimo semestral.
4. **Restore probado y cronometrado**: fichero + VM completa desde PBS, con resultado en
   monitorización. Un `verify` en verde **no** cuenta como restore.
5. **`verify`, `prune` y `garbage-collect` programados** y con alerta de fallo en los tres.
6. **Sin `root@pam` en automatización**: auditar `/etc/pve/user.cfg` y los tokens; cada integración
   con su token y su rol mínimo.
7. **Perfil de VM auditado**: todas las VMs de producción con virtio, `qemu-guest-agent` activo y
   modelo de CPU del cluster. Lista de excepciones justificada por escrito.
8. **Sin LXC privilegiado** salvo excepción documentada, con dueño y con fecha de revisión.
9. **Ocupación de storage bajo umbral** (ZFS < 80%, thin pools con margen) y alerta por predicción,
   no por "lleno".
10. **Versiones al día y coherentes**: `pveversion -v` en todos los nodos igual; ninguna rama EOL en
    producción; PVE y PBS compatibles entre sí.

## 5. Seguridad

- **CVE-2026-53359 ("Januscape", divulgado 06-jul-2026)**: escape **invitado → host** en el shadow
  MMU x86 de KVM (Intel VMX/EPT y AMD SVM/NPT), que afecta a VMs con **virtualización anidada**
  habilitada. **Parchear 53359 no basta**: la remediación completa exige también **`CVE-2026-46113`**
  (corregido en may-2026; cubre el caso *leaf shadow page*, 53359 el *non-leaf*).
  Proxmox publicó kernels corregidos (**`proxmox-kernel-6.8.12-33-pve`
  y `proxmox-kernel-7.0.14-4-pve`** o posteriores; Debian, DSA-6381-1). Acción: **parchear y
  reiniciar**, auditar qué VMs tienen nested virt o CPU `host`, y **desactivar nested salvo necesidad
  demostrada**. Nested no está expuesto por defecto: requiere el flag explícito o el modelo de CPU
  `host` — otro motivo para no usar `host` de forma indiscriminada. **Verifica la versión mínima
  fijada hoy antes de citarla** (§8).
- **Superficie de la interfaz**: PVE-UI/API (8006), SPICE/VNC proxy, SSH entre nodos y PBS (8007) van
  en el plano de gestión, **sin ruta desde redes de usuario**. TLS con certificado de la PKI interna
  (ACME/step-ca), no el autofirmado por defecto.
- **Multi-tenencia**: la frontera entre inquilinos es **la VM**, nunca el LXC. Añade separación de
  red (VLAN/SDN + firewall por VM) y pools + RBAC; sin las tres, "multi-tenant" es una etiqueta.
- **Aislamiento del backup**: el PBS de destino **no** se autentica con credenciales del dominio de
  producción, y el sync remoto es preferentemente **pull desde el destino**. Un PBS que produccción
  puede borrar no protege de ransomware.
- **AppArmor** confina los LXC; desactivarlo "para que funcione" convierte cualquier contenedor en
  privilegiado de facto. El diagnóstico correcto va por `selinux-standards` (perfiles MAC).
- Cifrado en reposo: cifrado del lado cliente en PBS **siempre**; disco del nodo con LUKS o cifrado
  nativo de ZFS donde el dato lo exija; claves fuera del host.
- Suscripción y repos: `pve-enterprise` es también una decisión de seguridad (cola de paquetes
  probada y soporte). Ningún repo de terceros en el nodo hipervisor: el nodo no es un servidor de
  aplicaciones.

## 6. Rendimiento y observabilidad

- **Qué vigilar como mínimo** (el diseño del stack es de `observability-standards`): estado y votos
  del cluster, links de Corosync, estado de HA por recurso, salud de Ceph/ZFS (scrub, resilver,
  degradación), ocupación real de cada storage con predicción, presión de memoria y ballooning,
  `steal time` en invitados, estado y antigüedad del último backup **y del último restore probado**,
  fallos de `verify`, GC de PBS, caducidad de certificados, deriva de NTP y temperatura/SMART.
- Toda alerta enlaza runbook. Alerta que nadie puede accionar se elimina (`onprem-standards` §6).
- **Sobrecompromiso**: vCPU se sobrecomprometen con cabeza (vigila `steal`); **la memoria no se
  sobrecompromete en producción** salvo con ballooning entendido y medido — el OOM del host se lleva
  VMs por delante.
- Migración en vivo: coste real en memoria y red. Con VMs grandes y red de migración lenta, la
  ventana de mantenimiento se calcula, no se improvisa; red de migración dedicada si el cluster es
  grande.
- Capacidad con **N-1 como requisito**: el cluster debe absorber la pérdida de un nodo (dos, si el
  mantenimiento coincide con un fallo) sin sobrecompromiso. Si no, no hay HA, hay esperanza.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Minor de PVE/PBS: mensual, rodando por el cluster. Kernel/microcódigo: mensual o ante CVE explotable.
- Major: tras leer las release notes completas y probar en staging, **con fecha anterior al EOL de la
  rama actual** (PVE 8 → 9 antes del 31-ago-2026).
- Ceph: su upgrade es un proyecto propio, en pasos y con el orden documentado (comprobar versiones
  mínimas de `pve-manager` y de los paquetes de Ceph antes de empezar). Nunca a la vez que el de PVE.
- Firmware de BMC/NIC/HBA/discos: revisión trimestral.

**PROHIBIDO**
- ❌ Activar HA sin fencing/watchdog **probado apagando un nodo**. Invariante de plataforma.
- ❌ Cluster de 2 nodos con HA y sin QDevice; número par sin árbitro.
- ❌ Corosync compartiendo red con almacenamiento, replicación o backup; un único link.
- ❌ Editar `corosync.conf` a mano en un nodo sin quórum, o unir al cluster un nodo con VMs.
- ❌ Ejecutar PVE 8.x en producción tras su EOL (31-ago-2026) sin plan de salida fechado.
- ❌ `root@pam` (o su token) en Terraform, Ansible, CI, exporters o cualquier automatización.
- ❌ Exponer 8006/8007 o el BMC a red de usuario o a Internet.
- ❌ LXC privilegiado como aislamiento de código no confiable o de otro inquilino.
- ❌ VM de producción sin `qemu-guest-agent`, o con IDE/SATA/`e1000` emulados.
- ❌ CPU `host` en cluster heterogéneo (rompe migración en vivo) y nested virt sin necesidad.
- ❌ `args:` en el `.conf` de la VM como configuración permanente.
- ❌ Tratar un snapshot (con o sin memoria) como backup; una única copia; PBS en el mismo chasis o
  pool que produce; clave de cifrado del backup guardada solo dentro del sistema respaldado.
- ❌ `prune` sin `garbage-collect`, o cualquiera de los tres jobs sin alerta de fallo.
- ❌ Dar por bueno un backup por el job en verde, sin restore cronometrado.
- ❌ `min_size=1` en Ceph; Ceph sin red dedicada; Ceph sin dueño que lo mantenga.
- ❌ Thin provisioning sin alerta de ocupación real; pools ZFS > 80% sin plan.
- ❌ Actualizar dos nodos a la vez, o actualizar con el cluster/Ceph degradado.
- ❌ Instalar repos de terceros o servicios de aplicación en el nodo hipervisor.
- ❌ Migrar desde ESXi sin instalar virtio/guest-agent antes, y sin conservar la VM origen apagada
  hasta validar.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, fecha o nombre de feature, **búscalo — no lo recuerdes**. La
verificación de este documento (ago-2026) y lo que queda abierto:

1. **Versiones y EOL**: `pve.proxmox.com/wiki/Roadmap`, `pbs.proxmox.com/wiki/Roadmap` y la tabla de
   ciclo de vida oficial. Verificado: **PVE 9.2 (21-may-2026)** sobre Debian 13.5, kernel 7.0,
   QEMU 11.0, LXC 7.0, ZFS 2.4, Ceph Squid 19.2.3 y **Tentacle 20.2.1** (default en despliegues
   nuevos); **PBS 4.2 (29-abr-2026)** sobre Debian 13.4, kernel 7.0, ZFS 2.4; **PVE 8 EOL
   31-ago-2026**. Caduca rápido: re-verifica.
2. **Backend S3 de PBS**: verificado que pasó de *technology preview* (4.0) a **soportado
   oficialmente en 4.2**. **Hueco declarado**: la ausencia de soporte de **Object Lock/versionado** y
   el riesgo de corromper el datastore al activarlo en el bucket procede de un análisis de terceros,
   **no confirmado contra documentación oficial** — confírmalo antes de diseñar inmutabilidad sobre
   S3.
3. **Madurez de la SDN de PVE**: verificadas las features por versión (Fabrics con OpenFabric/OSPF en
   9.0; OSPF route redistribution y múltiples controladores EVPN en 9.1; fabric WireGuard, route-maps
   y prefix-lists BGP e underlay IPv6 en 9.2). **Hueco declarado**: **no se ha confirmado qué
   subcomponentes siguen marcados como experimentales** en la documentación de 9.2 — compruébalo en
   las release notes y en la doc de SDN antes de llevarlos a producción.
4. **Asistente de importación desde VMware**: verificados los límites (ESXi 6.5-8.0, vSAN no
   soportado, rate limiting del ESXi, 4 conexiones paralelas, API no expuesta en ESXi gratuito).
   **Hueco declarado**: la fuente principal es documentación y reportes de **2024-2025**; no se ha
   confirmado el estado a 2026 ni qué bugs se han cerrado. Consulta el wiki *Migrate to Proxmox VE* y
   el Bugzilla antes de planificar una migración grande.
5. **CVEs**: verificado **CVE-2026-53359 "Januscape"** (escape invitado→host vía nested KVM) y los
   kernels corregidos citados en §5. Re-verifica la **versión mínima vigente** y busca CVEs
   posteriores en QEMU, kernel KVM y los paquetes `pve-*` antes de fijar un mínimo.
6. **Ceph**: verificado mínimo documentado de **3 servidores preferiblemente idénticos**, `size=3`/
   `min_size=2`, red exclusiva **≥10 Gbps** y recomendación de tres redes (25+/10+/1 Gbps). Verifica
   los requisitos de la versión de Ceph que vayas a desplegar y el ciclo de vida de esa release.
7. **Corosync**: verificado **<5 ms** de latencia requerida, inestabilidad por encima de ~10 ms con
   más de 3 nodos, NIC dedicada recomendada, **hasta 8 links**, y la prohibición explícita de
   compartir red entre corosync y almacenamiento.
8. **LXC**: verificado que **no privilegiado es el default desde PVE 4.4** y que upstream declara
   inseguro el modo privilegiado y no trata sus escapes como CVE.
9. **Contexto de mercado** (cambia por trimestre): licenciamiento Broadcom/VMware, mínimos de cores,
   y madurez de alternativas (XCP-ng/Vates, Nutanix). Verificado a ago-2026 el sentido general de la
   migración; los porcentajes citados en §3.8 proceden de análisis de terceros y **no de fuente
   primaria**.
10. **Procedimiento de upgrade oficial** (`Upgrade_from_8_to_9`, `pve8to9`, `Ceph_Squid_to_Tentacle`)
    y sus versiones mínimas de paquete: se leen enteros antes de empezar, nunca de memoria.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
