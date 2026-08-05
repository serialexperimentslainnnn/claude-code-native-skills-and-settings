---
name: ha-clustering-standards
description: High availability for services running inside an OS, with Pacemaker/Corosync as reference. Use when running pcs, crm/crmsh, crm_mon, crm_resource, crm_simulate, cibadmin, pcs stonith, pcs constraint or the ha_cluster system role, editing cib.xml, votequorum settings (two_node, wait_for_all, last_man_standing, auto_tie_breaker), corosync-qnetd/qdevice arbitration, STONITH agents (fence_ipmilan, fence_idrac, fence_ilo, fence_apc, fence_sbd, fence_vmware, fence_aws/fence_gce), sbd.conf and hardware watchdog fencing, stonith-enabled and no-quorum-policy, OCF resource agents, IPaddr2 virtual IPs, colocation and ordering constraints, resource-stickiness, clone and promotable resources, cluster maintenance-mode and standby, DRBD with drbdadm and drbd.conf, dlm with GFS2 or OCFS2 shared filesystems, Patroni patroni.yml versus a Pacemaker-managed PostgreSQL, keepalived.conf VRRP as a lighter alternative, split-brain and fence racing incidents, or answering whether a service needs a cluster at all.
---

# Estándares de alta disponibilidad de servicios (Pacemaker/Corosync)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

> **Tesis del documento**: **HA sin fencing probado no es HA, es corrupción de datos diferida.**
> Un cluster que no puede matar a un nodo sospechoso con certeza no está protegiendo el
> servicio: está esperando el día en que dos nodos escriban el mismo dato a la vez.
>
> **Corolario que se olvida más**: **un cluster mal operado tiene peor disponibilidad que un
> servicio simple bien monitorizado.** Cada nodo, cada agente, cada restricción y cada
> dispositivo de fencing es una pieza nueva que puede fallar — y falla. La complejidad es el
> enemigo del *uptime*. Aplica KISS antes de aplicar Pacemaker.

## 1. Alcance y triggers

Aplica a dar alta disponibilidad a **servicios que corren dentro de un sistema operativo**:
la decisión de si hace falta un cluster, quórum y arbitraje, fencing/STONITH, gestión de
recursos con Pacemaker, almacenamiento compartido o replicado, patrones por tipo de servicio,
operación del cluster y ejercicios de conmutación.

Disparadores: `pacemaker`, `pacemakerd`, `corosync`, `corosync-qnetd`, `corosync-qdevice`,
`votequorum`, `two_node`, `wait_for_all`, `last_man_standing`, `auto_tie_breaker`, `pcs`,
`pcsd`, `crm`, `crmsh`, `crm_mon`, `crm_resource`, `crm_simulate`, `crm_verify`, `cibadmin`,
`cib.xml`, `stonith-enabled`, `no-quorum-policy`, `resource-stickiness`, `migration-threshold`,
`failure-timeout`, `ocf:heartbeat:*`, `IPaddr2`, `Filesystem`, `systemd:` como clase de recurso,
`pcs constraint colocation|order`, `clone`, `promotable`/`master`, `fence_ipmilan`,
`fence_idrac`, `fence_ilo4`, `fence_apc_snmp`, `fence_sbd`, `fence_vmware_rest`,
`fence_aws`/`fence_gce`, `sbd`, `/etc/sysconfig/sbd`, `SBD_WATCHDOG_DEV`, `softdog`,
`drbdadm`, `drbd.conf`, `drbdsetup`, `dlm_controld`, `gfs2`, `mkfs.gfs2`, `ocfs2`,
`patroni.yml`, `patronictl`, `keepalived.conf`, `vrrp_instance`, `ha_cluster` (rol de sistema),
`cockpit-ha-cluster`, "split-brain", "el cluster ha hecho failover solo", "los dos nodos creen
que son primarios", "no arranca el recurso y no sé por qué".

**Regla de arbitraje interna**: si la respuesta se escribe con `pcs`/`crm`/`cibadmin` sobre un
CIB de Pacemaker, o en `sbd.conf`/`drbd.conf`, es de esta skill.

### 1.1 Frontera con `proxmox-ve-standards` (espejo de la regla ya escrita allí)

`proxmox-ve-standards` ya fijó la regla de arbitraje de este par, y **este documento la espeja
literalmente**:

> **Si el recurso que conmuta es una VM o un contenedor de PVE, es de `proxmox-ve-standards`;
> si es un servicio dentro de un SO, es de aquí.**

Con dos precisiones que hay que tener claras:

- **PVE trae su propio stack de HA** —`pve-cluster`/`pmxcfs`, `pve-ha-manager`, sus grupos HA y
  su watchdog— y **no se opera con `pcs` ni con `crm`**. Ejecutar `pcs` en un nodo PVE es un
  error de categoría: no hay CIB que tocar.
- **Corosync es común a ambas.** Los principios de quórum, latencia del anillo, redundancia de
  enlace y la aritmética de nodos valen igual en los dos lados; lo que cambia es el gestor de
  recursos que hay encima.

### 1.2 HA no es DR (la confusión más común del dominio)

| | HA (esta skill) | DR (`bcdr-standards`) |
|---|---|---|
| Responde a | Fallo de **un componente** dentro de un dominio de fallo | Pérdida del **dominio de fallo entero**: sala, CPD, región, proveedor |
| Horizonte | Segundos a minutos, **automático** | Minutos a días, **con decisión humana** de declarar el desastre |
| Mecanismo | Redundancia activa y conmutación | Recuperación desde copia o sitio alterno |
| Contra qué **no** protege | Borrado lógico, corrupción, ransomware, error humano — **los replica al instante** | (es justo para lo que existe) |
| Métrica | Disponibilidad, MTTR | **RTO/RPO** derivados del impacto de negocio |

**Un cluster de HA no es un backup y no sustituye a un plan de continuidad.** Replicación
síncrona es un `DELETE` propagado en milisegundos. Y a la inversa: un plan de DR impecable no
evita el minuto de caída del martes. **Hacen falta los dos, y son proyectos distintos.**
`bcdr-standards` fija RTO/RPO y el orden de recuperación; esta skill fija el mecanismo que
sostiene el objetivo de disponibilidad que fija `sre-practice-standards`.

**No aplica**: ver `proxmox-ve-standards` (**frontera hermana, §1.1**: HA de VMs y contenedores
de PVE con `ha-manager`, grupos HA, reglas de afinidad y su watchdog),
`kubernetes-standards` (**el orquestador es la respuesta correcta a "que este servicio sobreviva
a la caída de su host"**: reprogramación, réplicas, probes y PDB. Pacemaker no compite con eso),
`podman-systemd-containers-standards` (**mención cruzada, sin solape**: contenedores como
servicios de systemd en un host. Si la pregunta es cómo sobreviven a la caída del host, la
respuesta honesta es **casi nunca con Pacemaker**: un orquestador, un balanceador delante de dos
instancias con el estado fuera, o el downtime aceptado por escrito. Pacemaker gestionando
contenedores de un host es complejidad de cluster sin ninguna de sus garantías),
`bcdr-standards` (**§1.2**: RTO/RPO, BIA, ejercicios de DR, sitio alterno, declaración del
desastre), `backup-recovery-standards` (la copia y su restore probado — **replicación no es
copia**), `sre-practice-standards` (**la disponibilidad como objetivo es suya**: SLI/SLO, error
budget, on-call, capacidad; **el mecanismo para alcanzarla es de aquí**. Si el SLO se cumple sin
cluster, no se monta cluster), `incident-management-standards` (declaración, roles y comunicación
del incidente; aquí el diagnóstico técnico del cluster), `data-platform-standards` (**el motor de
datos y su replicación son suyos**: PostgreSQL, su streaming replication, tuning, PITR, Redis,
Kafka; **aquí el mecanismo de cluster que promueve o conmuta** — ver §5.2, donde el criterio es
que para PostgreSQL la respuesta por defecto **no** es Pacemaker), `linux-storage-standards`
(LVM, multipath, iSCSI, filesystems locales y LUKS **por debajo** del recurso de cluster),
`zfs-standards` (el pool; ZFS **no es** un filesystem de cluster y no se monta en dos nodos),
`linux-administration-standards` (**systemd**: un recurso gestionado por el cluster **no se
toca con `systemctl`** — ya está prohibido allí y aquí se confirma), `networking-standards`
(diseño de la red, VLAN, VRRP a nivel de red, MTU; aquí el uso de la red por el cluster y sus
requisitos de latencia), `firewall-policy-standards` (la política de filtrado que debe permitir
el tráfico de Corosync y de los dispositivos de fencing),
`observability-standards` (diseño del stack de métricas y alertas; aquí **qué** vigilar del
cluster y **desde dónde**), `identity-access-management-standards` (credenciales del BMC y su
custodia; aquí que el fencing necesita esas credenciales y que son de alto privilegio),
`secrets-management-standards` (dónde viven esas credenciales), `onprem-standards` (**paraguas**:
su §1.3 fija el invariante *HA sin fencing probado es corrupción diferida*, que es la tesis de
este documento, y su §6 cedía a esta skill el detalle del bloque de HA),
`microservices-architecture-standards` (**resiliencia distribuida en la aplicación** —circuit
breakers, reintentos con backoff, bulkheads, sagas— frente a HA de infraestructura: **una
aplicación bien diseñada necesita menos cluster**, y ese es el orden correcto de inversión),
`windows-server-ad-standards` (WSFC y clustering de Windows).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). En clusters,
> **la versión que manda es la que empaqueta y soporta tu distribución**, no la de upstream:
> aquí no se compila a mano.

| Pieza | Estado (ago-2026) | Criterio |
|---|---|---|
| Pacemaker | **3.0.3** (2026-07-28) y **2.1.11** (2026-06-29): **ambas líneas vivas** | 3.0 (GA 2025-01-08) existe para **eliminar sintaxis legacy deprecada**. Greenfield → 3.0.x si la distro lo trae; si no, 2.1.x sin drama |
| Corosync | **3.1.10** (2025-11-15) | Cadencia anual (releases en noviembre). Estable y aburrido, que es lo que se quiere en la capa de membresía |
| `pcs` | **0.12.3** (2026-07-10) / **0.11.12.1** (2026-07-14) — dos líneas mantenidas | **Herramienta en RHEL/Fedora/Ubuntu.** En RHEL 10, la **UI web autónoma de `pcsd` ya no existe**: pasa a `cockpit-ha-cluster` |
| `crmsh` | **5.0.0** (2025-08-15); **5.1.0-rc2** (2026-06-29) | **Herramienta en SUSE/SLES.** SLE HA 16 se construye alrededor de `crm cluster init`. **Ni `pcs` ni `crmsh` están obsoletos**: se elige por el soporte del proveedor, no por gusto |
| `resource-agents` | **4.18.0** (2026-04-08) | Activo |
| `fence-agents` | **4.17.0** (2026-01-05) | Activo |
| `sbd` | **1.5.2** (2023-01-09) — último *release*; repositorio con actividad (commits en ene-2026) | **Cadencia lenta**: úsalo con la versión que empaqueta tu distro y no asumas correcciones upstream recientes. Sigue siendo el mecanismo de referencia sin PDU/BMC |
| DRBD (módulo) | **9.3.3** (2026-07-01) out-of-tree de LINBIT; **10.0.0 en alfa** — no tocar | **El DRBD del kernel mainline es 8.4.11, de hace ~8 años.** LINBIT está subiendo 9.3 a upstream (podría llegar en Linux 7.2, sep/oct-2026). Hoy: **módulo out-of-tree por DKMS**, con lo que implica en parcheo de kernel |
| `drbd-utils` | **9.34.0** | **No mezclar `drbd-utils` 9.x con el módulo in-tree 8.4**: la sintaxis de config no cuadra y produce fallos confusos |
| Patroni | **4.1.4** (2026-07-07); líneas 4.0.10 y 3.3.11 parcheadas el mismo día | **Respuesta por defecto para HA de PostgreSQL** (§5.2) |
| keepalived | **2.4.3** | VRRP: alternativa **ligera** para IP virtual sin cluster completo (§5.5) |
| Automatización | Rol de sistema **`ha_cluster`** (RHEL) o `crm cluster init` (SUSE) | Cluster declarativo y versionado > sesión interactiva de `pcs` irreproducible |

**Estado de los filesystems de cluster — cambio importante, verificado**:

- **GFS2 sale de Red Hat.** El *Resilient Storage Add-On* **queda descontinuado a partir de RHEL
  10**: los paquetes `gfs2-utils`, `dlm` y `ctdb` se discontinúan y **los módulos `gfs2` y `dlm`
  se han eliminado del kernel de RHEL 10**. Sigue soportado en RHEL 7/8/9 hasta el fin de su
  ciclo de mantenimiento — ese es tu plazo de migración, no una prórroga indefinida.
- **OCFS2 sale de SUSE.** Deprecado en SLE HA 15 SP7 y **no estará en SLE HA 16**; SUSE
  documenta la migración **a GFS2** (aviso: GFS2 **no soporta reflink**, a diferencia de OCFS2).
- **Las dos distribuciones han intercambiado su filesystem de cluster preferido.** Cualquier
  diseño multi-proveedor tiene que asumirlo.
- **Consecuencia de criterio**: en RHEL 10+ **no hay filesystem de bloque compartido soportado
  en el kernel**. El diseño activo/activo sobre disco compartido deja de ser una opción por
  defecto; lo que queda es activo/pasivo con XFS sobre almacenamiento compartido, un
  almacenamiento distribuido (CephFS y similares) o exportar por NFS/SMB desde un par en
  activo/pasivo. **Elegir GFS2 hoy para algo nuevo exige justificar el ciclo de vida.**

## 3. La pregunta previa: ¿de verdad necesitas HA?

**Es la sección más importante del documento.** Antes de instalar nada, se responde por escrito:

1. **¿Qué SPOF elimina el cluster, y cuáles deja?** Un cluster de dos nodos en el mismo rack,
   con la misma PDU, el mismo switch y la misma cabina no elimina casi nada: mueve el punto
   único de fallo del servidor al switch. **Dibuja los dominios de fallo antes de comprar
   licencias.**
2. **¿Cuál es el objetivo de disponibilidad, y de dónde sale?** Si viene de un SLO con impacto
   de negocio detrás (`sre-practice-standards`), adelante. Si viene de "queremos que no se
   caiga", no hay requisito, hay ansiedad.
3. **¿Cuánto downtime cuesta de verdad un minuto?** Compáralo con el coste de operar un cluster:
   segundo nodo, dispositivos de fencing, red dedicada, formación, ventanas de parcheo dobles y
   un modo de fallo nuevo que nadie del equipo ha visto antes.
4. **¿Quién opera esto a las 3 de la mañana?** Un cluster que solo entiende una persona **reduce**
   la disponibilidad real. Si el equipo de guardia no sabe leer un `crm_mon` ni cuándo poner el
   cluster en mantenimiento, el cluster es un riesgo, no un control.
5. **¿El estado del servicio es compatible con la conmutación?** Un servicio que tarda 8 minutos
   en recuperar su base de datos tras un corte sucio no gana nada con un failover de 20 segundos.

### 3.1 Alternativas más simples que casi siempre bastan

Se descartan **por escrito** antes de montar Pacemaker:

| Alternativa | Cuándo basta |
|---|---|
| **Servicio con `Restart=on-failure` y monitorización** | Cuando el fallo típico es que el proceso se muere, no que el hardware arde. Cubre la mayoría de incidentes reales |
| **Balanceador delante de N backends sin estado** | El patrón más robusto que existe: sin quórum, sin fencing, sin split-brain. **Si puedes sacar el estado del servicio, hazlo y ahórrate el cluster entero** |
| **Réplica con promoción manual documentada** | RTO de minutos aceptable. Un runbook probado + una réplica al día vale más que un cluster que nadie ha ejercitado |
| **VRRP (`keepalived`) para la IP** | Solo hace falta que una IP se mueva entre dos nodos. Sin CIB, sin fencing, sin agentes |
| **Orquestador** | El servicio ya está en contenedores y lo que quieres es reprogramación automática |
| **Servicio gestionado / cluster del proveedor** | En nube: el HA lo opera otro y sale más barato que el tuyo |

**Regla de decisión**: monta Pacemaker cuando necesites **conmutación automática de un recurso
con estado, con exclusión mutua garantizada** — y estés dispuesto a mantener fencing probado.
En cualquier otro caso, hay una respuesta más simple, y la respuesta más simple es la correcta.

## 4. Quórum, split-brain y fencing

### 4.1 Quórum

- **Tres nodos como número mínimo sano.** El quórum es aritmética, no opinión: con 3 nodos
  sobrevives a la pérdida de 1 con mayoría real.
- **Dos nodos sin árbitro es una máquina de corromper datos.** Ante una partición, ambos nodos
  ven "el otro no está" y ambos concluyen lo mismo. Lo único que evita que los dos monten el
  dato es el fencing — y si el fencing también depende de la red partida, no evita nada.
- Parámetros de `votequorum` (texto verbatim del manual, para que no se citen de memoria):
  - **`two_node`**: *"Enables two node cluster operations (default: 0)"*; fija artificialmente el
    quórum a 1 en clusters de dos nodos. Nota del manual: *"enabling `two_node: 1` automatically
    enables `wait_for_all`"*.
  - **`wait_for_all`**: *"Enables Wait For All (WFA) feature (default: 0)"* — el cluster
    *"will be quorate for the first time only after all nodes have been visible at least once at
    the same time"*. Traducción operativa: **evita que un solo nodo arranque solo tras un corte
    general y se declare dueño de todo**. Es una protección real y barata.
  - **`last_man_standing`**: recalcula dinámicamente `expected_votes` y el quórum bajo ciertas
    condiciones, con una ventana configurable (por defecto 10 s). **Peligroso sin fencing
    impecable**: reduce el listón del quórum justo cuando el cluster está degradado.
  - **`auto_tie_breaker`**: permite sobrevivir a la caída simultánea del 50 % de los nodos de
    forma determinista; por defecto gana el `nodeid` más bajo, ajustable con
    `auto_tie_breaker_node`.
- **`corosync-qnetd` + `corosync-qdevice` es la respuesta correcta para dos nodos.** Un tercer
  árbitro que **no tiene por qué ser un nodo del cluster** (un host pequeño en otro dominio de
  fallo). Coste ridículo comparado con lo que evita. **Un cluster de dos nodos sin qdevice y sin
  fencing fiable no se pone en producción.**
- **El árbitro tiene que estar en otro dominio de fallo.** Un qnetd en el mismo rack, el mismo
  switch o la misma VM que un nodo no arbitra nada.
- **Red de Corosync**: dedicada o al menos aislada, con **redundancia de enlace** (varios
  `ring`), latencia baja y estable. Corosync es sensible a la latencia y al jitter: **una red
  compartida con backups o replicación produce fencings espurios a las 3 de la mañana**. El
  diseño de esa red es de `networking-standards`; el requisito es de aquí.
- **`no-quorum-policy`**: el default sensato es `stop` (parar recursos al perder quórum).
  `ignore` es la vía rápida al split-brain y solo tiene sentido en configuraciones muy concretas
  con fencing perfecto. **`no-quorum-policy=ignore` copiado de un blog es una causa habitual de
  pérdida de datos.**

### 4.2 Fencing / STONITH: la tesis

**Sin fencing probado no hay HA.** El cluster no puede distinguir "el nodo está muerto" de "el
nodo no me contesta pero sigue escribiendo en el disco". La única forma de convertir la
incertidumbre en certeza es **matar el nodo** y confirmar que ha muerto.

- **`stonith-enabled=false` es el pecado capital de este dominio.** Es la línea que aparece en
  todos los tutoriales de "monta tu primer cluster" y en todos los postmortems de corrupción.
  Está **prohibida** fuera de un laboratorio desechable, y en un laboratorio se documenta que lo
  es. Un cluster con STONITH deshabilitado no es un cluster degradado: es dos servidores con un
  sistema que les da permiso para pisarse.
- **Agentes por plataforma** (elige por lo que hay debajo, no por lo que es fácil):

| Sustrato | Agente | Aviso |
|---|---|---|
| Servidor físico con BMC | `fence_ipmilan`, `fence_idrac`, `fence_ilo4`/`fence_ilo5` | **El BMC tiene que estar en una red que sobreviva a la partición**, y sus credenciales son de altísimo privilegio (`identity-access-management-standards`). Un BMC alimentado por la misma PSU que el nodo no siempre sirve |
| PDU gestionada | `fence_apc_snmp` y equivalentes | Fiable y brutal. Cuidado con servidores de doble alimentación: **hay que cortar ambas tomas** o no se apaga nada |
| Sin BMC ni PDU | **SBD** (`fence_sbd`) | Modo con disco (1–3 dispositivos; 2–3 recomendados para cargas críticas) o **diskless** solo con watchdog |
| Hipervisor | `fence_vmware_rest`, agentes de libvirt | El hipervisor pasa a ser SPOF del fencing: tenlo en cuenta |
| Nube | `fence_aws`, `fence_gce`, `fence_azure_arm` | Dependen de la API del proveedor y de credenciales: una caída de la API del proveedor es una caída del fencing |

- **SBD**, precisiones verificadas y no negociables:
  - **Watchdog por hardware, siempre.** ClusterLabs es explícito: un watchdog **software**
    depende de que el SO funcione correctamente, y por tanto **no es fiable para fencing**.
    `softdog` vale para un laboratorio y **para nada más**.
  - El demonio `sbd` **debe estar arrancado antes que los servicios del cluster**, y **el cluster
    no puede gestionarlo como recurso**. Es infraestructura, no recurso.
  - Modo con disco: el dispositivo compartido es un SPOF; con 2–3 dispositivos en cabinas
    distintas deja de serlo.
- **`fencing loop`**: el nodo A mata a B, B arranca, no se pone de acuerdo, mata a A, y así hasta
  que alguien lo para. Se mitiga con retardo de arranque de los servicios del cluster tras el
  boot y con `wait_for_all`.
- **`fence racing`**: los dos nodos de un par se disparan simultáneamente y el cluster queda sin
  nadie. Se mitiga con **retardo asimétrico** en los dispositivos de fencing (`pcmk_delay_base` /
  `pcmk_delay_max`, distinto por nodo) para que uno gane siempre.
- **Topología de fencing**: cuando hay varios mecanismos (BMC + PDU), se define el **orden y el
  respaldo** (`pcs stonith level`), no se dejan dos agentes sueltos compitiendo.

### 4.3 LA PRUEBA OBLIGATORIA

**Antes de que un cluster reciba tráfico de producción, se apaga un nodo en sucio.** No
`pcs cluster stop`, no `reboot`: **corte de alimentación, `echo c > /proc/sysrq-trigger`, o
desconectar la red del nodo activo.** Y se comprueba:

1. El nodo superviviente **fencea** al otro y lo confirma (no "cree" que lo ha apagado).
2. Los recursos arrancan en el superviviente dentro del tiempo esperado, y se **cronometra**.
3. El dato está **íntegro**: filesystem consistente, base de datos sin corrupción, sin escrituras
   dobles.
4. El nodo fenceado, al volver, **no se lleva por delante** al que está sirviendo.
5. Y se repite **provocando la partición de red** en vez del apagado: es un fallo distinto y
   revela si el fencing depende de la red que acaba de partirse.

**Un cluster que no ha pasado esta prueba no está en producción, está en pruebas** — se
comporte como se comporte el resto del tiempo.

## 5. Pacemaker en la práctica y patrones por servicio

### 5.1 Recursos, agentes y restricciones

- **Clase de agente**: `ocf:` cuando existe agente OCF (tiene `monitor` de verdad y semántica de
  estado), `systemd:` cuando lo que gestionas es una unidad ya existente y bien hecha. **`lsb:`
  solo en legacy**: los scripts init mienten sobre el estado.
- **Todo recurso lleva operación `monitor` con `interval` explícito.** Un recurso sin monitor es
  un recurso que el cluster cree vivo para siempre. Y con `timeout` **realista**: un timeout
  corto en un servicio lento produce conmutaciones fantasma; uno largo alarga el corte real.
- **`resource-stickiness` > 0 por defecto.** Sin *stickiness*, el recurso vuelve al nodo
  "preferido" en cuanto reaparece, provocando **un segundo corte gratis** justo después del
  primero. El failback es una decisión, no un reflejo.
- **`migration-threshold` + `failure-timeout`**: limita cuántos fallos aguanta un recurso en un
  nodo antes de moverse, y cuándo se olvida el fallo. Sin ellos, un recurso rebota entre nodos.
- **Las restricciones mal puestas son la causa nº1 de conmutaciones sorpresa.** Criterio:
  - **Colocación** (`colocation`) y **orden** (`order`) son cosas distintas y se confunden a
    diario: "juntos" no implica "en este orden". Se declaran **las dos** cuando aplica.
  - Los `score` intermedios (ni `INFINITY` ni 0) producen comportamientos que nadie predice.
    **Usa `INFINITY` o no pongas la restricción.**
  - Un **grupo** (`group`) es azúcar sintáctico de colocación + orden implícitos. Cómodo y
    legible; pero implica que **el fallo de un miembro arrastra a los siguientes**. Si eso no es
    lo que quieres, no uses grupo.
  - **`clone`** para servicios activo/activo sin estado; **`promotable`** para el patrón
    primario/réplica.
  - **`crm_simulate` antes de aplicar** cualquier cambio de restricciones en producción: te dice
    qué va a mover el cluster **antes** de que lo mueva. Es la herramienta más infrautilizada del
    stack.
- **El CIB es configuración, y va versionado.** Se exporta (`pcs cluster cib` / `cibadmin -Q`) al
  repositorio, y se despliega con el rol `ha_cluster` o equivalente (`iac-standards`). **Editar
  `cib.xml` a mano en disco está prohibido** — se usa `pcs`/`crm`/`cibadmin`.

### 5.2 PostgreSQL: **Patroni, no Pacemaker** (criterio claro)

**Para PostgreSQL, la respuesta por defecto hoy es Patroni + un DCS distribuido (etcd o Consul)
+ HAProxy delante. Pacemaker es la excepción.**

Motivos, no gustos:
- Patroni **entiende PostgreSQL**: roles de replicación, promoción, *rewind*, lag. Pacemaker es
  un gestor de recursos genérico y todo lo que sabe de Postgres se lo cuenta un agente.
- Patroni cubre explícitamente el caso feo: **degrada el primario cuando queda aislado de la
  mayoría**, y `maximum_lag_on_failover` impide promover una réplica demasiado atrasada — que es
  exactamente la decisión que arruina un failover mal hecho.

**Pacemaker sigue siendo la respuesta cuando**:
- el HA de la base de datos es **por almacenamiento compartido**, no por replicación;
- PostgreSQL es **un recurso más** dentro de un cluster que ya gestiona otros servicios y
  dependencias del SO;
- hay un stack soportado por el proveedor construido alrededor de Pacemaker (típico en SAP), y
  salirse de él te deja sin soporte.

**Trampas de Patroni que hay que anotar en el diseño**:
- **El DCS es el nuevo quórum.** Un etcd de un solo nodo, o —clásico— corriendo en las mismas
  máquinas que la base de datos, convierte una caída del primario en una caída total. **etcd
  distribuido, quorado y en dominios de fallo distintos**, o no hay HA.
- Con **solo dos nodos de PostgreSQL** el quórum vuelve a ser incómodo; considérese un tercer
  nodo (aunque sea testigo) antes de aceptar el diseño.
- El enrutado de clientes (HAProxy contra la API REST de Patroni) es **parte del diseño**, no un
  detalle: sin él, el failover ocurre y nadie se entera.

**El motor, su replicación, su tuning y su PITR son de `data-platform-standards`.** Aquí solo se
fija **qué mecanismo de cluster se usa y por qué**.

### 5.3 IP virtual

- `ocf:heartbeat:IPaddr2` es el recurso más común y el más fácil de romper: **la IP virtual va
  colocada y ordenada con el servicio que la usa** (grupo o colocation+order), o acabarás con la
  IP en un nodo y el servicio en otro.
- Se comprueba que el ARP gratuito llega y que los switches actualizan su tabla: un failover
  técnicamente correcto con la red sin enterarse es un corte igual.
- Si lo **único** que necesitas es mover una IP, **no montes Pacemaker**: `keepalived` (§5.5).

### 5.4 NFS / Samba en activo-pasivo

- Patrón: almacenamiento compartido + `Filesystem` + IP virtual + el servicio, todo en un
  **grupo**, con orden estricto. Solo un nodo monta.
- **Lo que rompe a la gente**: el **estado de bloqueos**. Un failover de NFS sin migrar el estado
  de locks deja clientes colgados o, peor, escribiendo sobre bloqueos que ya no valen. El
  directorio de estado va en el almacenamiento compartido, y **se prueba con clientes reales
  escribiendo durante la conmutación**, no con un `showmount`.
- Con Samba y CTDB en juego: comprobar el ciclo de vida del paquete en tu distro antes de
  diseñar (en RHEL 10, `ctdb` va en el lote discontinuado del Resilient Storage Add-On).

### 5.5 VRRP con `keepalived` (la opción ligera, y muchas veces la correcta)

- Para **HAProxy/nginx u otro frontal sin estado** con una IP flotante, `keepalived` (2.4.x) hace
  el trabajo sin CIB, sin agentes y sin fencing.
- **Sus límites, dichos claramente**: VRRP **no tiene quórum ni fencing**. Ante una partición,
  ambos nodos pueden reclamar la IP (dos MAC anunciando la misma dirección). Es aceptable
  precisamente porque **delante de servicios sin estado un split-brain no corrompe nada**:
  duplica tráfico, no datos.
- **Regla dura**: `keepalived` **nunca** delante de un recurso con estado que no tolere doble
  escritura. Ahí hace falta quórum y fencing, es decir, Pacemaker (o el mecanismo propio del
  motor, §5.2).

## 6. Almacenamiento compartido y replicado

**La regla que gobierna toda esta sección**: **un filesystem que no es de cluster, montado en dos
nodos a la vez, destruye el dato.** No "puede dar problemas": lo destruye, y a menudo en
silencio, porque cada nodo tiene su propia caché y su propio journal. XFS, ext4, btrfs y ZFS
**no son filesystems de cluster**. El único mecanismo que impide ese doble montaje en el mundo
real es el fencing (§4.2), y de ahí que la tesis de este documento sea la que es.

- **Activo/pasivo con XFS sobre almacenamiento compartido** es el patrón por defecto y el que
  hay que preferir: un solo montaje, recurso `Filesystem` gestionado por el cluster, fencing
  probado. Simple y suficiente en la mayoría de casos.
- **Activo/activo con GFS2 u OCFS2** exige un gestor de bloqueos distribuido (`dlm`) y **fencing
  impecable**: sin él, el `dlm` no puede recuperar y el cluster se bloquea o corrompe. Además,
  **su futuro está comprometido en las dos grandes familias** (§2): GFS2 fuera de RHEL 10,
  OCFS2 fuera de SLE HA 16. **Diseño nuevo sobre filesystem de cluster: justificar el ciclo de
  vida por escrito, y contemplar la salida.**
- **DRBD** cuando no hay cabina compartida y se quiere replicación de bloque entre nodos:
  - Modos de replicación: **A** (asíncrono, RPO > 0), **B** (semi-síncrono) y **C** (síncrono,
    RPO 0 y el que se usa en HA de verdad). **Elegir C salvo que la latencia del enlace lo
    impida** — y si lo impide, admite que tu RPO no es cero y anótalo en `bcdr-standards`.
  - **Dual-primary es la trampa clásica.** Solo tiene sentido para el caso corto y controlado
    (migración en vivo de VMs) y **exige un filesystem de cluster encima**. Guía histórica de
    LINBIT: en DRBD 9 hay "two-primary", no "multi-primary"; parecer que funciona no es
    funcionar. **Dual-primary permanente para un filesystem normal = corrupción garantizada.**
  - **Deuda operativa real**: el módulo es **out-of-tree** (DKMS) y va detrás del kernel. Cada
    actualización de kernel es un riesgo de arranque sin `/dev/drbdX`. Planifica el parcheo
    contando con eso. El esfuerzo de subir DRBD 9.3 a mainline está en curso pero **aún no ha
    aterrizado**; hasta entonces, DKMS.
  - **No mezclar `drbd-utils` 9.x con el módulo 8.4 del kernel mainline**: la sintaxis de
    configuración no cuadra.
- **DRBD no es un backup.** Replica el borrado y la corrupción a la velocidad del enlace.

## 7. Operación, gates y prohibiciones

### 7.1 Operación

- **Modo mantenimiento ANTES de tocar nada.** `pcs property set maintenance-mode=true` (o
  `pcs node standby` / `crm node standby` para un nodo) antes de parchear, reiniciar un servicio,
  probar algo o mirar con demasiada curiosidad. **La causa más común de un incidente de cluster
  es un administrador operando el servicio a mano mientras el cluster mira.**
- **Un recurso gestionado por el cluster no se toca con `systemctl`.** Ya está prohibido en
  `linux-administration-standards`; aquí se confirma: `systemctl restart` sobre un recurso
  gestionado provoca que el cluster lo vea como fallo y, según la configuración, un fencing.
- **Salir del mantenimiento es parte del procedimiento**, y se verifica que el cluster ve el
  estado real (`crm_mon -1`, sin fallos pendientes, `pcs status` limpio). Un cluster que lleva
  semanas en `maintenance-mode` **no está dando HA** y nadie se ha dado cuenta.
- **Actualizaciones rodando** (`rolling upgrade`), nodo a nodo, con el cluster en marcha:
  - Pacemaker soporta rolling upgrade **desde 2.0.0 en adelante**; desde versiones anteriores a
    2.0.0 **no está soportado** — hay que pasar primero por una release 2.x.
  - Un nodo con Pacemaker 3.0+ **no conecta con nodos Pacemaker Remote de 1.1.14 o anteriores**,
    y Pacemaker 1 no habla con Remote/bundles de 3.0+. Inventaria antes de empezar.
  - Pacemaker 3.0 **valida el CIB de forma estricta**: `validate-with` es obligatorio, sensible a
    mayúsculas, y no admite esquemas antiguos (`pacemaker-1.1`, `pacemaker-next`, etc.). **Un CIB
    que venía funcionando puede no cargar tras la actualización.** Se prueba con `crm_verify`
    contra el esquema nuevo antes de tocar el primer nodo.
- **Monitorización del cluster DESDE FUERA del cluster.** Un cluster que se vigila a sí mismo
  informa perfectamente hasta el momento en que deja de poder informar. La alerta de "cluster sin
  quórum" o "nodo fenceado" tiene que salir de un sistema que no está en el cluster
  (`observability-standards`). Qué vigilar como mínimo:
  - quórum presente y número de nodos esperados;
  - **`stonith-enabled` es `true`** (alerta si alguien lo desactiva — pasa);
  - recursos parados, fallidos o en un nodo inesperado;
  - **fallos de fencing** (un fencing que falla es un incidente de severidad alta, aunque el
    servicio siga arriba);
  - `maintenance-mode` activo más de X horas;
  - retransmisiones y pérdida de tokens de Corosync (síntoma temprano de la red que causará el
    próximo fencing espurio);
  - estado de los dispositivos de fencing: **el BMC/PDU se prueba periódicamente, no cuando hace
    falta**;
  - salud de SBD y del watchdog.
- **Los logs que importan**: `pacemaker.log` / journal de `pacemaker` y `corosync`, y sobre todo
  **`crm_mon --show-detail` y el historial de fallos del recurso**. En un incidente, la pregunta
  no es "qué pasó" sino **"por qué el cluster decidió esto"**, y esa respuesta está en la
  transición del PE (`crm_simulate` sobre el fichero de la transición). Retención de esos logs
  suficiente para un postmortem (`incident-management-standards`).
- **Credenciales de fencing**: son credenciales de "apaga este servidor". Van en el gestor de
  secretos (`secrets-management-standards`), con rotación, y su red de gestión segmentada.

### 7.2 Ejercicios (gates recurrentes)

1. **Antes de producción**: la prueba de §4.3 — apagado sucio **y** partición de red — con
   informe: qué se apagó, cuánto tardó la conmutación, integridad del dato, qué falló.
2. **Failover programado como mínimo semestral**, en ventana acordada, sobre el cluster de
   producción. Un failover que solo se probó el día de la instalación no está probado: han
   cambiado el kernel, los agentes, el firmware del BMC y las reglas de red desde entonces.
3. **Failback probado.** La vuelta es una conmutación más y suele estar menos ensayada que la
   ida. Se ejercita explícitamente, y se decide si es automática (con `stickiness` bajo) o
   manual (recomendado por defecto).
4. **Informe por ejercicio**: fecha, escenario, tiempo de conmutación medido, desviación frente
   al objetivo, hallazgos y acciones con dueño. Sin informe, el ejercicio no cuenta.
5. **Prueba de los dispositivos de fencing por separado** (`pcs stonith fence <nodo>` en ventana):
   confirma que el BMC responde, que las credenciales siguen siendo válidas y que la red de
   gestión llega. Es el componente que más se degrada en silencio.
6. **`crm_simulate` en CI** sobre el CIB versionado ante cualquier cambio de restricciones.

### 7.3 PROHIBIDO

- ❌ **`stonith-enabled=false`** en cualquier cosa que no sea un laboratorio desechable
  documentado como tal. Es la prohibición número uno de este documento.
- ❌ Cluster en producción **sin la prueba de apagado sucio** de §4.3.
- ❌ **Cluster de dos nodos sin qdevice/qnetd** (o sin un fencing que demostradamente resuelva la
  partición).
- ❌ Árbitro (qnetd) en el mismo dominio de fallo que un nodo del cluster.
- ❌ **`no-quorum-policy=ignore`** copiado sin entender qué habilita.
- ❌ **Watchdog software (`softdog`) como fencing en producción**: no es fiable por diseño.
- ❌ Montar un filesystem **no de cluster** (XFS, ext4, btrfs, ZFS) en dos nodos a la vez.
- ❌ **DRBD dual-primary permanente** bajo un filesystem que no sea de cluster.
- ❌ Confundir **replicación con backup**, o **HA con DR** (§1.2).
- ❌ Operar un recurso gestionado con `systemctl`, o tocar el servicio sin `maintenance-mode`.
- ❌ Editar `cib.xml` a mano en disco; configurar el cluster solo por sesión interactiva sin
  dejar el CIB versionado en el repositorio.
- ❌ Restricciones con `score` intermedios "a ver qué pasa"; restricciones sin `crm_simulate`.
- ❌ Recurso sin operación `monitor`, o con `timeout` copiado del ejemplo.
- ❌ `resource-stickiness=0` (failback automático inmediato = segundo corte gratis).
- ❌ **Exponer el demonio `pcsd` / su interfaz web a una red no confiable.** El grueso de los CVE
  recientes de `pcs` viene de sus **dependencias empaquetadas en `pcsd`** (tornado, rack, lodash:
  RHSA-2026:2452 / 2462 / 2469 / 2818 / 2819, feb-2026), no de la lógica del cluster. Red de
  gestión, y parcheo al ritmo de las erratas de la distro.
- ❌ Corosync sobre una red compartida con backup o replicación masiva.
- ❌ **Pacemaker gestionando contenedores de un host** para "darles HA": ver
  `podman-systemd-containers-standards`. La respuesta es un orquestador, un balanceador con el
  estado fuera, o downtime aceptado por escrito.
- ❌ `keepalived`/VRRP delante de un recurso con estado que no tolere doble escritura.
- ❌ Montar un cluster porque "queremos que no se caiga", sin SLO, sin dominios de fallo
  dibujados y sin nadie de guardia que sepa operarlo.
- ❌ Compilar Pacemaker/Corosync a mano en un sistema con soporte del proveedor.
- ❌ Diseño nuevo sobre GFS2/OCFS2 sin justificar por escrito su ciclo de vida (§2).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real:

1. **Versiones empaquetadas por tu distribución** de `pacemaker`, `corosync`, `pcs`/`crmsh`,
   `resource-agents`, `fence-agents` y `sbd` — **no las de upstream**. En clusters manda el
   soporte del proveedor.
2. **Ciclo de vida del filesystem de cluster** en tu distro: GFS2 **descontinuado a partir de
   RHEL 10** (Resilient Storage Add-On; módulos `gfs2` y `dlm` fuera del kernel), OCFS2
   deprecado en SLE HA 15 SP7 y **fuera de SLE HA 16**. Confirmar fechas exactas de fin de
   soporte de RHEL 9 antes de comprometer una migración.
3. **Notas de migración de Pacemaker 3.0**: validación estricta del CIB, `validate-with`,
   esquemas retirados, compatibilidad de Pacemaker Remote. Leer la página de cambios de 3.0 de
   ClusterLabs **antes** de la primera actualización rodante.
4. **Estado del agente de fencing concreto de tu hardware/hipervisor/nube** y sus parámetros
   (`pcmk_delay_base`, `pcmk_host_map`, `pcmk_reboot_action`): cambian entre versiones de
   `fence-agents`.
5. **Erratas de seguridad de `pcs`/`pcsd`** en tu stream (las recientes vienen de dependencias
   empaquetadas) y CVE de `corosync`, `pacemaker` y `sbd`.
6. **Patroni**: última versión y su matriz de compatibilidad con la versión de PostgreSQL y con
   el DCS elegido; y si sigue siendo la recomendación por defecto frente a Pacemaker.
7. **DRBD**: si el módulo 9.3 ya ha aterrizado en el kernel mainline (estimación de LINBIT:
   posiblemente Linux 7.2, sep/oct-2026) — cambia por completo la ecuación de mantenimiento
   frente a DKMS.
8. **Requisitos de latencia y tuning de Corosync** (`token`, `consensus`) para tu topología, en
   particular si hay enlaces entre salas.

**Huecos declarados — NO rellenar de memoria, verificar antes de usar:**
- **Fecha y contenido del último release de `sbd`**: el último tag verificado es **1.5.2
  (2023-01-09)** con actividad de repositorio en enero de 2026, pero **no se ha confirmado si
  existe una release posterior ni qué versión empaquetan RHEL 10 y SLE HA 16**. Comprobarlo antes
  de depender de una corrección concreta.
- **Fecha exacta del release de `keepalived` 2.4.3** (tag verificado, fecha no obtenida por
  límite de tasa de la API) y su estado de mantenimiento.
- **Fecha de `drbd-utils` 9.34.0** (tag verificado, fecha no obtenida). Y **la relación exacta
  entre DRBD 9.3.3 y la rama 10.0.0 alfa**: no se ha verificado el plan de soporte de LINBIT.
- **Motivo del lote de parches de Patroni del 2026-07-07** (4.1.4, 4.0.10 y 3.3.11 el mismo día,
  patrón típico de corrección de seguridad): **no verificado**. Consultar el advisory antes de
  fijar versión mínima.
- **Estado y soporte de `pg_auto_failover`** como alternativa a Patroni en escenarios de dos
  nodos: mencionado en las fuentes pero **no verificado en cuanto a mantenimiento actual**.
- **Alternativas soportadas a GFS2 en RHEL 10** para activo/activo sobre bloque compartido:
  **no verificado** más allá de la constatación de que el add-on desaparece. Confirmar con Red
  Hat antes de diseñar.
- **Parámetros de tuning de Corosync recomendados hoy** (`token`, `token_retransmits_before_loss_const`,
  `consensus`): **no verificados en esta revisión**. No copiar valores de blogs.
- **Compatibilidad exacta de `crmsh` 5.1 con Pacemaker 3.0.x** (5.1.0 estaba en rc2 a jun-2026):
  no verificada.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
