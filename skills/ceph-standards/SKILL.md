---
name: ceph-standards
description: Ceph as distributed storage — the RADOS cluster, its daemons and the decisions that decide whether it survives. Use when running ceph -s / ceph health detail / ceph df / ceph osd tree / ceph osd dump / ceph pg / ceph balancer / ceph orch / ceph telemetry, bootstrapping or operating a cluster with cephadm (cephadm bootstrap, ceph orch apply, ceph orch upgrade start, service specs) or with Rook (CephCluster, CephBlockPool, CephFilesystem, CephObjectStore CRDs), sizing MON quorum and MGR/MDS standbys, editing a CRUSH map or crush rule and choosing the failure domain (osd/host/rack), deciding replicated size=3 min_size=2 versus an erasure-coded profile (k+m, allow_ec_overwrites, allow_ec_optimizations), pool creation and pg_num with the PG autoscaler (pg_autoscale_mode, mon_target_pg_per_osd, noautoscale, bulk), BlueStore OSDs and block.db/block.wal offload sizing with ceph-volume or ceph-bluestore-tool, RBD images and rbd create --data-pool, CephFS with max_mds and standby-replay, RGW daemon placement, mon_osd_nearfull_ratio / backfillfull / full_ratio and a cluster that stopped accepting writes, scrub and deep-scrub tuning, msgr2 crc versus secure mode and cephx keyrings, per-OSD latency and slow ops, stretch clusters and tiebreaker monitors, upgrading between named releases (Squid, Tentacle), or deciding whether Ceph is the right answer at all instead of ZFS or NFS.
---

# Estándares de Ceph — almacenamiento distribuido RADOS

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: Ceph no es "un NAS que escala". Es un **sistema distribuido con consenso**
> (Paxos en los monitores) sobre el que se apoya todo lo demás. Dos consecuencias que gobiernan el
> resto del documento: **si el quórum de monitores cae, el cluster entero deja de servir aunque
> todos los datos estén intactos**, y **un cluster lleno no se puede vaciar**, porque recuperar y
> rebalancear requiere escribir. La mayoría de los desastres de Ceph no son pérdidas de disco: son
> quórum y capacidad.

## 1. Alcance y triggers

Aplica al **cluster RADOS y a su operación**: arquitectura de daemons y su dimensionado, quórum de
monitores, mapa CRUSH y dominios de fallo, esquema de protección (réplica frente a *erasure
coding*), pools y *placement groups*, BlueStore y el offload de metadatos, las tres interfaces
(RBD, CephFS, RGW) y cuándo encaja cada una, red, método de despliegue, actualización entre
releases con nombre, *scrubbing*, gestión de capacidad, observabilidad de latencia, y el criterio
de **cuándo no desplegar Ceph**.

Disparadores: `ceph -s`, `ceph health detail`, `ceph df`, `ceph osd tree`/`dump`/`df`,
`ceph osd crush`, `ceph osd pool create`/`set`, `ceph pg`, `ceph balancer`, `ceph orch`,
`cephadm bootstrap`, `ceph-volume`, `ceph-bluestore-tool`, `rbd`, `ceph fs`, `radosgw-admin`
(como daemon, no como API S3), `ceph.conf`, `keyring`, `mon_osd_full_ratio`, `pg_autoscale_mode`,
`allow_ec_overwrites`, `min_size`, `HEALTH_WARN`/`HEALTH_ERR`, `nearfull`, `slow ops`,
`CephCluster`/`CephBlockPool`/`CephFilesystem` (CRD de Rook), `pveceph`.

**No aplica**: ver `object-storage-standards` (**frontera hermana y la más fina**: el **objeto S3
como interfaz** —política de bucket, versionado, Object Lock, ciclo de vida, clases, presigned
URL, multipart, checksums, coste por petición— es **suyo**, incluido el RGW visto desde el
cliente. **Aquí, el RGW como daemon**: cuántos, dónde se colocan, sobre qué pools —índice
replicado en flash, datos en EC—, su consumo de `block.db` por *omap*, y su sitio en el orden de
upgrade. Regla de arbitraje: **si la pregunta se responde con una llamada S3, es suya; si se
responde con `ceph osd pool` o `ceph orch`, es de aquí**), `linux-storage-standards` (el disco
local y su pila de bloques: LVM, multipath, NVMe, ext4/XFS, LUKS, `fio`, `iostat`. **La frontera
es el OSD**: el dispositivo crudo y su latencia son suyos; lo que BlueStore hace encima es de
aquí — y **Ceph quiere el disco crudo tras un HBA en modo IT**, no un LV sobre una RAID
hardware), `zfs-standards` (**la alternativa honesta**: para un único host, o dos con replicación
asíncrona, ZFS es más simple, más rápido y más barato de operar. §2.1 fija cuándo Ceph pierde esa
comparación), `proxmox-ve-standards` (**Ceph empaquetado por Proxmox**: `pveceph`, su integración
con `storage.cfg`, el orden de upgrade PVE↔Ceph y el mínimo de 3 nodos que documenta. Aquí el
criterio de Ceph *como Ceph*, que no cambia por venir empaquetado; §3.7 declara qué se pierde por
esa vía), `ha-clustering-standards` (**Pacemaker/Corosync, fencing y el quórum de un servicio**.
Frontera: **el quórum de monitores de Ceph no es el quórum de Corosync y no se resuelven con las
mismas herramientas** — Ceph no usa STONITH; su equivalente es marcar un OSD `down`/`out` y el
`nearfull`. Si la pregunta es "¿cómo evito que dos nodos escriban a la vez sobre el mismo LUN?",
es suya), `kubernetes-standards` (el cluster de K8s, su admisión y sus workloads; **Rook es el
operador que corre Ceph dentro de K8s** y su despliegue es de aquí, pero el StorageClass, el
PVC y el CSI vistos por el pod son suyos), `backup-recovery-standards` (**réplica no es copia**:
`size=3` no protege de un `rados rm`, de un ransomware con la keyring de admin ni de un
`ceph osd pool delete`. La copia y su restore probado son suyos), `bcdr-standards` (RTO/RPO,
orden de recuperación, ejercicios; el *stretch cluster* de §3.6 es un mecanismo, no un plan),
`onprem-standards` (paraguas de plataforma y enrutado), `server-hardware-standards` (BOM, HBA en
modo IT, endurance de los SSD, BMC), `networking-standards` (VLAN, MTU, bonding, switches; aquí
solo el **requisito** de red que Ceph impone), `observability-standards` (Prometheus, reglas y
dashboards; aquí **qué** vigilar), `cryptography-pki-standards` (algoritmos y custodia de claves;
aquí solo el uso de cephx y del modo `secure` de msgr2), `secrets-management-standards` (dónde
vive la keyring de `client.admin`), `linux-hardening-standards` (baseline CIS del host que aloja
los daemons), `vulnerability-management-standards` (triaje y SLA de los CVE de Ceph),
`finops-standards` (coste por TB útil frente a alternativas), `air-gapped-standards` (**Ola 7**:
el registro de contenedores interno del que `cephadm` tira las imágenes en un entorno sin salida
a Internet, y la firma que se verifica en el lado aislado).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.1 La decisión previa: ¿Ceph o no?

| Situación | Respuesta | Motivo |
|---|---|---|
| Un solo host, o dos con RPO de minutos | **ZFS + replicación** | Ceph con menos de 3 nodos no tiene tolerancia a fallo real y sí toda su complejidad |
| Necesitas POSIX compartido entre pocos clientes | **NFS sobre ZFS** | CephFS resuelve el mismo problema con un MDS, un pool de metadatos y una curva de operación entera |
| 3-4 nodos, sin dueño asignado a tiempo parcial | **No Ceph** | El coste dominante no es el hardware, es **quién lo mantiene**. Sin dueño, el cluster llega a `nearfull` sin que nadie mire |
| Necesitas las **tres** interfaces (bloque, fichero y objeto) sobre el mismo hardware | **Ceph** | Es su ventaja estructural real, y no la tiene ninguna alternativa libre |
| Crecimiento incremental por nodos, sin cabina y sin ventana de migración | **Ceph** | Añadir capacidad sin parar y sin re-plataformar es su otra ventaja real |
| Kubernetes que necesita RWX y bloque dinámico on-premise | **Ceph vía Rook** | La respuesta estándar; alternativas más simples solo si el requisito RWX no existe |

**Criterio honesto**: Ceph es sobreingeniería por debajo de ~5 nodos y ~100 TB útiles, salvo que
la razón sea *aprender* o que ya exista experiencia operativa en la casa. Por encima de ~1 PB o
con crecimiento continuo, la alternativa deja de existir.

### 2.2 Versiones y ciclo

| Elemento | Estado verificado (ago-2026) | Criterio |
|---|---|---|
| **Tentacle (v20.2.z)** | Release inicial **2025-11-18**; último punto **20.2.3** (2026-08-05); **EOL estimado 2027-06-01** | **Default para despliegues nuevos.** Trae `allow_ec_optimizations` (§3.3) |
| **Squid (v19.2.z)** | Inicial **2024-09-26**; último **19.2.5** (2026-07-14); **EOL estimado 2026-10-31** | En soporte, pero **a menos de tres meses del EOL**: si estás aquí, el upgrade a Tentacle ya está en el plan, no en el backlog |
| Reef (18.2.z), Quincy (17.2.z) y anteriores | **Archivadas**: Reef EOL 2025-03-20, Quincy EOL 2025-01-13 | Sin backports ni parches de seguridad. Correr Reef en producción hoy es deuda de seguridad, no de funcionalidad |
| Licencia | **LGPL-2.1 o LGPL-3** (verificado en el fichero `COPYING` de `ceph/ceph`, rama `main`) | Sin cláusula de fuente-disponible ni relicencia; el riesgo de licencia aquí es nulo |
| Rook | **Apache-2.0** (fichero `LICENSE`, rama `master`) | |

**Sobre "el ciclo anual"**: la documentación dice ciclo estable **anual apuntando a marzo**, con
soporte de ~24 meses (dos ciclos) y **upgrade rolling soportado desde las dos últimas releases
estables**. La realidad de las fechas no cumple ese objetivo: Squid salió en septiembre de 2024 y
Tentacle en noviembre de 2025. **Planifica contra la fecha de EOL publicada en el índice de
releases, no contra "marzo"**, y no te saltes más de dos releases: hacerlo obliga a un upgrade
por etapas y a reinstalar.

### 2.3 Protección de datos

| Uso | Por defecto | Alternativa justificable |
|---|---|---|
| RBD (VMs, contenedores) | **Réplica `size=3`, `min_size=2`** | EC solo si se ha medido; ver §3.3 |
| CephFS metadatos | **Réplica 3, en flash** | Nunca EC. Nunca HDD |
| CephFS / RGW datos fríos y grandes | **EC 4+2** (o 6+3 con suficientes dominios de fallo) | Réplica 3 si la latencia manda |
| RGW índice y pools `.log`/`.meta` | **Réplica 3, en flash** | Nunca EC |

`min_size=1` **está prohibido** (§7): permite servir escrituras con una sola copia viva y convierte
el siguiente fallo en pérdida de datos. En pools EC, la recomendación documentada es
**`min_size` ≥ k+1**.

## 3. Estructura y convenciones

### 3.1 Daemons y quórum — el punto que decide la supervivencia

- **MON** (`ceph-mon`): la fuente de verdad de los mapas, con consenso tipo Paxos. **El cluster
  vive si y solo si una mayoría estricta de monitores está activa y se ve entre sí.** 3 monitores
  toleran 1 caída; **4 también toleran solo 1** (por eso el número par no compra nada y sí añade
  superficie); 5 toleran 2. Documentado: al menos 3 en producción, **número impar siempre**.
- **Consecuencia de diseño, no negociable**: los monitores se reparten entre dominios de fallo
  distintos (rack, chasis, SAI, switch). Tres monitores en el mismo rack son un cluster de un solo
  rack, por muchos OSD que haya repartidos. Requisitos verificados: ≥2 cores, **≥5 GiB RAM por
  daemon**, **100 GB por daemon en SSD** (la base rocksdb del MON crece durante el rebalanceo, y
  un MON que se queda sin disco tumba el quórum).
- **MGR** (`ceph-mgr`): módulos, dashboard, métricas y orquestador. **Siempre ≥2** (activo +
  standby); el upgrade se bloquea (`UPGRADE_NO_STANDBY_MGR`) si no hay standby.
- **OSD** (`ceph-osd`): uno por dispositivo. Verificado: **≥4 GB RAM por daemon** (más es mejor;
  menos de 2 GB no recomendado), 1 hilo mínimo / 3 recomendados por OSD de HDD, 4 / 6 por NVMe.
  Dispositivos por debajo de **1 TiB** están desaconsejados; NVMe PCIe Gen4+ **por encima de 30 TB**
  pueden partirse en dos o más OSD.
- **MDS** (`ceph-mds`): solo si hay CephFS. ≥2 cores (frecuencia por encima de número), **≥8 GiB
  RAM**. `max_mds` es el número de *ranks* activos; **el máximo práctico en un sistema HA es uno
  menos que el número de daemons MDS**, porque hace falta al menos un standby por cada rank que
  quieras poder perder.
- **RGW** (`radosgw`): stateless, se escala por número de instancias detrás de un balanceador.

**Colocación**: MON, MGR y MDS pueden convivir con OSD en clusters modestos, pero **el MON
compitiendo por IOPS con un OSD en el mismo disco es una causa raíz clásica de elecciones
espurias**. Disco separado para el MON, siempre.

### 3.2 CRUSH y el dominio de fallo que no es el que crees

- CRUSH determina la colocación sin tabla central: eso es lo que permite crecer. El parámetro que
  decide la resistencia real es el **dominio de fallo de la regla**: `host` distribuye cada réplica
  en un host distinto; `rack`, en un rack distinto.
- **El fallo de diseño más común**: dejar el dominio en `host` en un cluster que ya está repartido
  en varios racks o varios chasis. Con `size=3` y dominio `host`, **las tres réplicas pueden acabar
  en el mismo rack**: pierdes el rack y pierdes el pool. Y al revés: fijar dominio `rack` con menos
  de 3 racks deja PGs permanentemente `undersized`, porque CRUSH no puede satisfacer la regla.
- Regla operativa: **el dominio de fallo debe ser el nivel del que puedes perder una unidad
  entera**, y el número de *buckets* de ese nivel debe ser ≥ `size` (o ≥ `k+m` en EC;
  **k+m+1 es la planificación correcta**, para poder rebalancear con un dominio caído).
- La jerarquía CRUSH se declara explícitamente (`ceph osd crush move`, o `location` en el spec de
  cephadm). **Un CRUSH map que no refleja el cableado real es una mentira con formato de árbol**:
  revísalo contra el inventario físico, no contra el diagrama.
- Clases de dispositivo (`hdd`, `ssd`, `nvme`) para dirigir pools a medios distintos; el balanceador
  (`ceph balancer`) en modo `upmap` para repartir PGs. Un cluster desbalanceado llega a `nearfull`
  por el OSD más lleno, no por la media — **la capacidad útil la marca el OSD más lleno**.

### 3.3 Réplica frente a erasure coding

- **EC no es "RAID barato"**: cada escritura toca `k+m` OSD y cada lectura degradada exige
  reconstruir. Por debajo del tamaño de banda, **una escritura pequeña se convierte en
  lectura-modificación-escritura distribuida**: ahí es donde EC arruina el rendimiento.
- **Por defecto, EC no admite escrituras parciales.** Para RBD, CephFS y librados hay que activar
  `allow_ec_overwrites true` en el pool, **solo posible sobre OSD BlueStore** (el checksum de
  BlueStore es lo que detecta el bitrot en el *deep scrub*).
- **RBD y CephFS no están plenamente soportados sobre EC**: los metadatos van en un pool
  replicado y solo los datos en el EC (`rbd create --data-pool ec_pool replicated_pool/img`;
  en CephFS, pool de datos por defecto o *file layouts*).
- **Desde Tentacle**: `allow_ec_optimizations true` mejora las E/S pequeñas y elimina el *padding*,
  reduciendo amplificación de espacio. Requiere **todos los MON y OSD ya en Tentacle**, se puede
  activar sobre pools existentes y **no se puede desactivar** una vez activo. Solo con los plugins
  Jerasure e ISA-L.
- Perfiles: documentación recomienda **no pasar de `k>4` o `m>2`** sin entender el impacto;
  **`m=1` está fuertemente desaconsejado en producción** (indisponibilidad durante mantenimiento y
  pérdida de datos ante fallos solapados). Si no sabes cuál elegir: **4+2 o 6+3**. `k>8`
  desaconsejado en la mayoría de casos.
- Desde Octopus un pool EC recupera con **k** shards disponibles (por debajo de k ya hay pérdida),
  pero se recomienda `min_size = k+1` para no perder escrituras.

**Criterio**: EC para RGW y para CephFS de objetos grandes y secuenciales. **Para RBD, réplica 3
salvo que hayas medido tu propio patrón de E/S** — el ahorro de espacio se paga en latencia de
escritura y, sobre todo, en tiempo de recuperación.

### 3.4 Pools y PGs

- **Autoescalado activado** (`pg_autoscale_mode on`) es el default sensato; `warn` si prefieres
  decidir tú los saltos. `off` solo con criterio y con el cálculo hecho.
- Objetivo por OSD: `mon_target_pg_per_osd`, **default 100**; la propia documentación recomienda
  **200 para todo salvo los despliegues más pequeños**, y avisa de que **por encima de 500 hay
  tráfico de peering y consumo de RAM excesivos**. Con más de 50 OSD, 100-250 réplicas de PG por
  OSD.
- Marca `bulk` en los pools que van a ser grandes: sin ella el autoescalador arranca con pocos PGs
  y el pool sufre mientras crece.
- **Durante un upgrade, el autoescalador se pausa** (cephadm lo hace solo salvo que actives
  `mgr/cephadm/pg_autoscale_during_upgrade`). Un *split* de PGs a mitad de upgrade puede añadir
  días en un cluster grande.
- Un pool por propósito, con nombre que diga a qué sirve. **Nunca** `rados bench` contra un pool de
  producción sin borrar después los objetos `bench*`: son una causa documentada de `OSD_FULL`.

### 3.5 BlueStore y el dimensionado de metadatos

- BlueStore habla directamente con el bloque; **Filestore está obsoleto** y cualquier OSD que quede
  en Filestore se migra.
- Con OSD híbridos HDD+SSD, `block.db` (que absorbe el `wal`) va en el dispositivo rápido.
  **Dimensionado verificado (documentación actual)**: **≥2,5 %** del tamaño del `block` lento —la
  cifra bajó porque desde Squid RocksDB comprime—, **≥4 % para RGW** (por el volumen de claves
  *omap*), y **1-2 % basta para RBD**. La regla folclórica del "4 % siempre" sobredimensiona el
  NVMe en cargas RBD y lo infradimensiona en ninguna.
- Ratio de OSD por dispositivo de offload: **4-5 OSD de HDD por SSD SATA**, **≤15 por NVMe**. Ese
  dispositivo es un **dominio de fallo**: si muere, mueren todos los OSD que dependen de él. Cuéntalo
  en el diseño CRUSH.
- Sin mezcla de medios rápidos y lentos **no se crean LV separados**: BlueStore colocaliza solo.

### 3.6 Red

- **Contra el folclore**: la documentación actual **no recomienda por defecto separar red pública y
  de cluster**. Dice que Ceph funciona bien con una sola red pública, especialmente a **25 GE o
  más**, y que la segunda red "complica configuración, coste y gestión y a menudo no tiene impacto
  significativo en el rendimiento". La recomendación firme es otra: **bonding activo/activo contra
  switches redundantes** (o multipath L3 con FRR), con la *hash policy* correcta (habitualmente
  L2+3 o L3+4 — una mal elegida deja una fracción del ancho de banda sin usar).
- Mínimo: **10 Gb/s** entre hosts y hacia clientes; **25 Gb/s** con carga sustancial; 100 Gb/s en
  nodos densos. Referencia de por qué: replicar 10 TiB tarda **30 horas a 1 Gb/s y 3 horas a
  10 Gb/s**; ese tiempo es la ventana en la que un segundo fallo te cuesta los datos.
- Red de cluster dedicada **solo** si el enlace es lento por estándares modernos (1 GE, o 10 GE en
  nodos densos/SSD) y no puedes ampliar el bonding. Si la pones: cada nodo necesita interfaz o VLAN
  adicional y **duplicas la superficie de fallo de red** — una red de cluster caída con la pública
  viva produce un cluster que se ve a sí mismo pero no puede replicar.
- Los daemons se enlazan por defecto en el rango **6800:7568**; el filtrado debe permitirlo entre
  todos los nodos (`firewall-policy-standards` para la política).

### 3.7 Despliegue: cephadm, Rook o el Ceph de Proxmox

| Vía | Cuándo | Qué se pierde |
|---|---|---|
| **cephadm** | **Default en bare metal.** Único método con integración completa de la API de orquestación, CLI y dashboard; soporta Octopus y posteriores | Exige contenedores (Podman o Docker) y **SSH a todos los nodos con clave privilegiada** — ese es su modelo de confianza, trátalo como Tier 0 |
| **Rook** | **Único método recomendado para Ceph dentro de Kubernetes**, y también para conectar K8s a un cluster Ceph externo | El ciclo de vida del almacenamiento queda acoplado al del cluster de K8s. Un cluster de K8s que se reconstruye "porque es efímero" no puede ser el que aloja el almacenamiento persistente |
| **Ceph de Proxmox (`pveceph`)** | Cuando ya hay un cluster PVE y el almacenamiento es para sus VMs | Es Ceph de verdad, pero **el calendario lo marca Proxmox**: la versión empaquetada, no la que quieras. El upgrade de PVE y el de Ceph **son dos proyectos separados y en orden documentado**. Fuera del ecosistema PVE no sirve |
| Ansible, Salt, Juju, Puppet, manual | Legado o requisitos muy concretos | Sin orquestador integrado: `ceph orch` no funciona, el dashboard pierde capacidades y cada operación vuelve a ser manual |

### 3.8 Stretch y multi-sitio

- Un cluster estirado entre dos CPD **necesita un monitor árbitro (*tiebreaker*) en un tercer
  sitio**: con monitores solo en dos sitios, la partición de red deja a ambos sin mayoría. El
  tercer sitio puede ser mucho más pequeño, pero **tiene que existir y ser independiente**.
- La latencia entre sitios entra en el camino de escritura síncrona. Estirar un cluster no es DR:
  es un único dominio de fallo lógico más grande. Para DR real, ver `bcdr-standards`; para
  replicación asíncrona de objetos, el *multisite* de RGW se decide en `object-storage-standards`.

## 4. Verificación antes de producción

En orden de coste creciente; ninguno es opcional para un cluster que va a llevar datos reales.

1. `ceph -s` en `HEALTH_OK` **sin warnings silenciados**, y `ceph health detail` leído entero.
2. `ceph osd tree` contrastado con el **inventario físico**: cada host en su rack real.
3. **Prueba de dominio de fallo**: apaga un host entero (y luego un rack, si el diseño lo declara)
   y comprueba que el cluster sigue sirviendo E/S y que recupera a `active+clean` solo.
4. **Prueba de quórum**: para un monitor, comprueba servicio; para dos de tres, comprueba que el
   cluster **se detiene** — y que sabes recuperarlo. Un operador que no ha visto un cluster sin
   quórum lo verá por primera vez en producción.
5. **Prueba de capacidad**: llena un pool de pruebas hasta `nearfull` en un entorno desechable y
   ejecuta el procedimiento de §6.2. Cronometra.
6. Benchmark con **tu** patrón (`fio` desde el cliente, no `rados bench` desde el nodo). Las cifras
   de IOPS de fabricante y las de los *whitepapers* de Ceph **no son un compromiso**: dependen del
   medio, del perfil EC, del tamaño de bloque y del número de clientes. **Si no lo has medido tú, no
   es un número, es una expectativa.**
7. `ceph telemetry` es opt-in: decide conscientemente si lo activas (ayuda al proyecto, envía datos
   fuera). En entorno aislado, no puede activarse.

## 5. Seguridad

- **cephx está activo por defecto** y da autenticación mutua. La keyring de `client.admin` es
  **equivalente a root sobre todos los datos del cluster**: fuera de los nodos de cliente, en un
  gestor de secretos, y con keyrings acotadas por capacidad (`mon 'profile rbd'`,
  `osd 'profile rbd pool=...'`) para cada consumidor.
- **El tráfico de datos no va cifrado por defecto.** msgr2 tiene dos modos: `crc` (autenticación
  fuerte + integridad, **sin secreto**) y `secure` (cifrado completo con AES-GCM). Los defaults
  verificados son `ms_cluster_mode = crc secure`, `ms_service_mode = crc secure`,
  `ms_client_mode = crc secure` — y como **se prefiere el primero de la lista**, en la práctica el
  tráfico entre daemons y con clientes va en **crc, es decir, en claro**. Solo los monitores
  invierten el orden (`ms_mon_cluster_mode = secure crc`). Si la red de Ceph no es de confianza,
  **fija `secure` explícitamente** y mide el coste; si lo dejas en `crc`, que sea una decisión
  escrita, no un descuido.
- **Dashboard y API del MGR nunca expuestos** fuera de la red de gestión; TLS obligatorio; sin
  credenciales por defecto. El RGW sí se expone, y su superficie (S3, políticas, presigned URLs)
  se endurece con `object-storage-standards`.
- `cephadm` guarda una clave SSH con acceso privilegiado a todos los nodos: es material Tier 0.
  Rota y audita su uso.
- CVEs: Ceph publica avisos propios; suscríbete a `ceph-announce` y trátalos en el flujo de
  `vulnerability-management-standards`. **Correr una release archivada significa no recibir el
  parche** (§2.2).

## 6. Operabilidad

### 6.1 Scrub y deep scrub

Valores por defecto verificados: `osd_max_scrubs` **3**, `osd_scrub_min_interval` **1 día**,
`osd_scrub_max_interval` **7 días**, `osd_deep_scrub_interval` **7 días**,
`osd_scrub_load_threshold` **10.0**, `osd_scrub_during_recovery` **false**.

- El *scrub* ligero compara tamaño y atributos; el **deep scrub lee todos los datos y verifica
  checksums**: es lo que detecta el bitrot, y es la razón por la que EC con *overwrites* exige
  BlueStore.
- Acota la ventana con `osd_scrub_begin_hour`/`end_hour` si el scrub interfiere con la carga. **Lo
  que está prohibido es desactivarlo** (`nodeep-scrub` permanente): un cluster sin deep scrub no
  sabe si sus datos están bien, y lo descubre cuando falla la recuperación.
- Un `PG_NOT_DEEP_SCRUBBED` sostenido significa que **no te da tiempo**: o hay demasiado dato para
  el hardware, o la ventana es demasiado estrecha. Es una señal de capacidad, no un ruido a
  silenciar.

### 6.2 Capacidad — el fallo operacional clásico

Umbrales por defecto verificados: `mon_osd_nearfull_ratio` **0,85**, `mon_osd_backfillfull_ratio`
**0,90**, `mon_osd_full_ratio` **0,95**.

- **Trampa documentada**: esos tres parámetros **solo se aplican en la creación del cluster** y
  después viven en el OSDMap. Cambiarlos en `ceph.conf` o en la config central **no hace nada**;
  hay que usar `ceph osd set-nearfull-ratio` / `set-backfillfull-ratio` / `set-full-ratio`.
- La secuencia del desastre: un OSD cruza `full` → **el cluster deja de aceptar escrituras** →
  para recuperar hace falta escribir → estás bloqueado. Y antes, en `backfillfull`, **el rebalanceo
  ya no puede completarse**, que es el aviso de que la recuperación no cabe.
- **Regla de dimensionado, no de monitorización**: la capacidad utilizable de diseño es la que deja
  espacio para que **la caída del host más grande se recupere sin cruzar `nearfull`**. En un cluster
  de 10 nodos, un nodo es el 10 % y cabe; **en uno de 3 nodos con dominio `host`, la pérdida de un
  nodo no se puede recuperar en ningún sitio** — solo se puede esperar a que vuelva. Esa es la
  diferencia real entre 3 y 10 nodos, y no la escribe ninguna hoja de cálculo de capacidad.
- Salida de emergencia (y solo eso): subir `full_ratio` **un poco** con
  `ceph osd set-full-ratio` para recuperar la escritura, borrar datos o **añadir OSD**, y
  devolverlo. Buscar objetos `bench*` olvidados con `rados ls` antes de nada.
- Alerta accionable: `nearfull` proyectado, no alcanzado. Si tu primer aviso es `OSD_NEARFULL`, ya
  vas tarde.

### 6.3 Qué vigilar

- **Estado**: `HEALTH_*` y cada check por separado — `OSD_NEARFULL`, `OSD_BACKFILLFULL`,
  `OSD_FULL`, `PG_DEGRADED`, `PG_AVAILABILITY`, `OSDMAP_FLAGS`, `MON_DOWN`,
  `UPGRADE_NO_STANDBY_MGR`, `POOL_FULL`, `TOO_MANY_PGS`, `OBJECT_UNFOUND`.
- **Latencia por OSD** (`ceph osd perf`, `commit_latency`/`apply_latency`, y las métricas del
  exporter): la métrica que importa no es la media, es **el OSD peor**. En un sistema distribuido,
  un solo disco enfermo arrastra la latencia de todos los PGs que lo tocan, y el síntoma que ve el
  usuario son `slow ops` en clientes que no están en ese host. Alerta por **outlier**, no por media.
- `slow ops` / `SLOW_OPS` con su OSD y su tipo de operación: es el atajo más corto al disco malo.
- Ocupación por OSD (desviación entre el más lleno y el más vacío) y estado del balanceador.
- PGs en estados no `active+clean` y **cuánto llevan así**.
- Estado del quórum y **deriva de reloj entre monitores**: `MON_CLOCK_SKEW` degrada Paxos. NTP
  fiable en los monitores no es opcional.

### 6.4 Upgrade

- Orden automatizado por cephadm: **managers → monitors → resto de daemons**, reiniciando cada uno
  solo cuando Ceph confirma que el cluster sigue disponible. `HEALTH_WARNING` durante el proceso es
  esperado.
- Requisitos: **un MGR en standby** (si no, el upgrade se bloquea), cluster **sin degradación
  previa**, autoescalador pausado (cephadm lo hace), y **no cambiar la topología durante la fase de
  OSD**.
- Upgrade escalonado (`--daemon-types`, `--limit`, ámbito por *bucket* CRUSH) para clusters
  grandes; en CephFS grande, la doc describe el uso de `mgr/orchestrator/fail_fs` para no tener que
  bajar `max_mds`.
- **Nunca** actualizar Ceph y la plataforma de debajo (PVE, K8s, kernel) en la misma ventana.

## 7. Sostenibilidad y prohibiciones

- Cadencia: seguir la release estable vigente y planificar el salto **antes** del EOL publicado, no
  después. Máximo dos releases de salto por upgrade rolling.
- Cada cluster tiene **un dueño nombrado** y un runbook con: perder un disco, perder un host,
  perder el quórum, llegar a `nearfull`, y hacer el upgrade. Sin eso, el cluster es un pasivo.

Prohibiciones explícitas:

- ❌ **`min_size = 1`** en cualquier pool. Ni "temporalmente para recuperar", sin una decisión
  escrita y una vuelta atrás inmediata.
- ❌ **Número par de monitores**, o los tres monitores en el mismo dominio de fallo.
- ❌ Un cluster de **2 nodos**. No hay tolerancia a fallo; hay dos copias de la complejidad.
- ❌ Dominio de fallo `host` en un cluster multi-rack sin haberlo decidido explícitamente.
- ❌ **EC para RBD** sin haber medido tu patrón de escritura; EC con `m=1` en producción.
- ❌ Poner metadatos de CephFS o el índice de RGW en EC o en HDD.
- ❌ Controladora RAID hardware por delante de los OSD. **HBA en modo IT**, disco crudo.
- ❌ Desactivar el *deep scrub* de forma permanente, o silenciar `PG_NOT_DEEP_SCRUBBED`.
- ❌ Tratar `nearfull` como un aviso informativo. Es un plazo.
- ❌ Cambiar los ratios de capacidad en `ceph.conf` creyendo que surten efecto (§6.2).
- ❌ Correr una release archivada (Reef o anterior) en producción.
- ❌ Exponer el dashboard del MGR o la API de orquestación fuera de la red de gestión.
- ❌ Repartir la keyring de `client.admin` a clientes o a scripts. Capacidades acotadas por consumidor.
- ❌ Usar la réplica como si fuera copia de seguridad.
- ❌ `rados bench` contra un pool de producción sin limpiar los objetos después.
- ❌ Actualizar Ceph con el cluster degradado, o a la vez que la plataforma de debajo.
- ❌ Desplegar Ceph "porque escala" en 3 nodos sin dueño, sin red de 10 Gb/s y sin runbook.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un diseño real:

1. **Release vigente y EOL** en `docs.ceph.com/en/latest/releases/` (tabla *Active Releases*): a
   ago-2026, **Tentacle 20.2.3** (2026-08-05, EOL estimado 2027-06-01) y **Squid 19.2.5**
   (2026-07-14, **EOL estimado 2026-10-31**). Esa fecha de Squid es inminente: re-verifícala.
2. **Ciclo de release** en `docs.ceph.com/en/latest/releases/general/`: el objetivo documentado
   (marzo, anual, 24 meses de soporte) **no coincide con las fechas reales** de Squid y Tentacle.
   Comprueba ambas cosas antes de planificar una migración.
3. **Valores por defecto** citados aquí (`mon_osd_*_ratio`, `osd_scrub_*`, `osd_deep_scrub_interval`,
   `mon_target_pg_per_osd`, `ms_*_mode`, dimensionado de `block.db`): la documentación de
   configuración es la fuente y **cambia entre releases**. Comprueba contra la doc de **tu** versión,
   no contra `latest`.
4. **Estado de `allow_ec_optimizations`**: introducida en Tentacle, restringida a Jerasure e ISA-L
   y **irreversible una vez activada**. Verifica su estado y sus limitaciones en la doc de tu
   release antes de tocar un pool.
5. **CVEs de Ceph, cephadm y Rook**: avisos oficiales del proyecto y `ceph-announce`.
   **Hueco declarado**: no se ha revisado el historial de CVE de Ceph para este documento.
6. **Rendimiento**: cualquier cifra de IOPS o throughput de fabricante o de un *whitepaper* se
   trata como no verificada hasta reproducirla en tu hardware con tu perfil de datos.
   **Hueco declarado**: este documento **no contiene ninguna cifra de rendimiento absoluto** por
   ese motivo; solo la referencia de tiempo de replicación por ancho de banda, que sí está en la
   documentación oficial.
7. **Versión empaquetada por Proxmox VE** y su orden de upgrade documentado, si la vía es
   `pveceph`: la marca Proxmox, no tú (`proxmox-ve-standards` §2 la mantiene actualizada).
8. **Licencias**: Ceph **LGPL-2.1 o LGPL-3** (`COPYING` en `ceph/ceph@main`), Rook **Apache-2.0**
   (`LICENSE` en `rook/rook@master`), ambas leídas en crudo. Re-verifica si el proyecto cambia de
   fundación o de gobernanza.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
