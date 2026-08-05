---
name: xen-standards
description: The Xen hypervisor, XCP-ng and the XenServer legacy - dom0/domU, PV/HVM/PVH and when Xen is still the right answer. Use when running xl (xl create, xl list, xl info, xl dmesg, xl sched-credit2, xl vcpu-pin), editing /etc/xen/*.cfg domain config files or xl.conf, sizing dom0_mem, dom0_max_vcpus and dom0 pinning on the Xen command line, choosing between PV, PVH and HVM guests or using pv-shim, running xenstore-ls, xentop, xl debug-keys or the credit2/null schedulers, operating XCP-ng and XenServer hosts with xe CLI, xsconsole, xapi, toolstack, SR and VDI storage repositories (LVM, ext, thin provisioning, XOSTOR/LINSTOR), PIF/VIF/network objects and bonds, pool masters and HA, managing them with Xen Orchestra, XO Lite, XOA or xo-server, migrating from VMware into XCP-ng, tracking Xen Security Advisories (XSA) and the pre-disclosure list, or deciding between Xen and KVM for a new deployment.
---

# Estándares de Xen, XCP-ng y el legado XenServer

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: Xen es el hipervisor de tipo 1 sobre el que corre buena parte de la nube pública
> y, a la vez, **el que menos se despliega ya en empresa**. Esta skill existe para tres cosas: operar
> bien lo que ya está desplegado, decidir con honestidad si Xen aporta algo en un despliegue nuevo
> (§7: casi nunca), y separar tres cosas que se confunden a diario — **el proyecto Xen**, **XCP-ng**
> (Vates) y **XenServer** (Cloud Software Group, antes Citrix Hypervisor).

## 1. Alcance y triggers

Aplica a: arquitectura Xen (dom0/domU, modos de virtualización), operación de **XCP-ng** como
plataforma y su ecosistema (xapi, `xe`, Xen Orchestra, XOSTOR), el estado del producto comercial
**XenServer**, el proceso de seguridad del proyecto (XSA), y **el criterio de elección** frente a KVM.

Disparadores: `xl` (`create`, `list`, `info`, `dmesg`, `sched-credit2`, `vcpu-pin`), `/etc/xen/*.cfg`,
`xl.conf`, `dom0_mem`, `dom0_max_vcpus`, `xenstore-ls`, `xentop`, `pv-shim`, `xe` (`vm-list`,
`sr-list`, `pool-*`, `host-*`), `xsconsole`, `xapi`, "SR"/"VDI", "PIF"/"VIF", "pool master",
"XOSTOR", "Xen Orchestra", "XOA", "XO Lite", "XSA-", "dom0", "domU", "PVH", "XenServer",
"Citrix Hypervisor".

**No aplica**:
- `proxmox-ve-standards` y `libvirt-kvm-standards` (**ya escritas**) — **las plataformas KVM del
  catálogo y la elección por defecto para despliegue nuevo** (§7). Frontera: si la respuesta se
  escribe con `qm`/`pvesm` es de PVE; con `virsh`/XML de dominio, de libvirt; con `xl`/`xe`, de aquí.
- `vmware-standards` y `hyper-v-standards` — cada skill cubre su hipervisor. El **criterio de salida
  de VMware** (qué se mide antes de decidir) está en `vmware-standards` §7; aquí solo XCP-ng como
  destino posible.
- `onprem-standards` — **paraguas de plataforma on-premise con la tabla de enrutado (§1.2)**.
- `ha-clustering-standards` — Pacemaker/Corosync, quórum y fencing genéricos; aquí el pool y la HA
  **nativos de XCP-ng/XenServer**.
- `linux-storage-standards`, `zfs-standards`, `object-storage-standards` — el almacenamiento fuera
  del modelo de SR/VDI.
- `networking-standards` — red física, VLAN, MTU; aquí solo PIF/VIF, bonds y redes del pool.
- `backup-recovery-standards` — **retención, inmutabilidad y restore probado**; aquí solo qué API de
  respaldo existe y sus límites. `bcdr-standards` — RTO/RPO y plan.
- `linux-administration-standards` y `linux-hardening-standards` — el SO del dom0 como Linux; aquí
  el dom0 **como componente del hipervisor** y su superficie.
- `vulnerability-management-standards` — triaje y SLA de CVE; aquí el proceso XSA y su calendario.
- `iac-standards` (Terraform/Ansible), `kubernetes-standards` (contenedores por encima),
  `gpu-computing-standards` (paso a través de GPU), `observability-standards` (telemetría).
- `opensource-licensing-standards` — criterio general de licencias; aquí las licencias concretas
  verificadas en crudo (§2). `finops-standards` — coste por VM como unidad económica.
- `enterprise-architecture-standards` y `migration-projects-standards`.

## 2. Versiones, licencias y modelo comercial

> Verificar la última versión y **cualquier precio** por web antes de fijarlo (§8).

| Componente | Estado verificado ago-2026 | Licencia (leída **en crudo**) |
|---|---|---|
| **Xen Project** (hipervisor) | Última verificada: **4.21**, anunciada nov-2025. Ramas estables mantenidas en paralelo | **GPL-2.0 *only*** — `COPYING`: *"the only valid version of the GPL … is _this_ particular version (i.e., *only* v2, not v2.2 or v3.x …)"* |
| **XCP-ng** (Vates) | **8.3 LTS** es la versión recomendada; publicada **2024-10-07**, soporte hasta **2028-11-30**. 8.2 LTS terminó soporte en 2025. **9.0 aún no es GA**: *"XCP-ng 9.0 might follow the same path"* | **GPL-2.0** (`xcp-ng/xcp/LICENSE`) |
| **xapi** (toolstack de XCP-ng/XenServer) | Componente central del pool y del `xe` | **LGPL-2.1 con excepción de enlazado** (`xapi-project/xen-api/LICENSE`) |
| **Xen Orchestra** | `xo-server` 5.207.x, `xo-web` 5.201.x (versiones leídas en `package.json`) | **AGPL-3.0-or-later** — implicación real: **modificarlo y ofrecerlo como servicio obliga a publicar el código** |
| **XenServer** (Cloud Software Group) | **XenServer 9** anunciado ≈jul-2026; 8.4 la generación previa. **Citrix Hypervisor 8.2 CU1 llegó a fin de vida el 25-jun-2025** | Propietaria |

**Modelo comercial — lo que hay que saber antes de elegir:**

- **XCP-ng es open source completo, sin funciones de pago en el hipervisor.** El README del proyecto
  lo declara: *"Fully Open Source: no paywalls or complicated licenses, all the features are free"*.
  Lo que se paga es **soporte**, no funcionalidad.
- **Xen Orchestra sí tiene una parte de pago, y es la trampa habitual**: **XO desde fuentes es libre
  (AGPL) y se instala a mano**; **XOA** es el appliance preconstruido y **la única vía a soporte
  profesional**, con precio **por host y año, por niveles**. **Cifras: no se escriben aquí** — se
  cotizan con Vates (§8). Criterio: en producción, o se compra XOA con soporte, o se asume
  explícitamente que la gestión y el respaldo los mantiene el equipo desde fuentes.
- **Backup**: en XCP-ng el respaldo real lo da Xen Orchestra (jobs, delta, replicación, XO Proxy).
  **Sin XO no hay plataforma de respaldo**: esto convierte a XO en dependencia crítica, no en una
  interfaz opcional. Mecánica y restore probado: `backup-recovery-standards`.
- **XenServer ya no tiene edición gratuita**: se sustituyó por una **Trial Edition de 90 días
  limitada a un pool pequeño**, y las licencias de escritorio virtual de Citrix ya no habilitan el
  hipervisor. Consecuencia: **XenServer solo se justifica dentro de una tienda Citrix**; fuera de
  ella, XCP-ng cubre lo mismo sin ese contrato. (Fuente: docs de XenServer + prensa, jul-2026 — §8.)

## 3. Arquitectura y operación

**dom0 / domU**
- **dom0 es un dominio privilegiado, no "el host"**: ejecuta el toolstack y los drivers de backend.
  El hipervisor es pequeño; **la superficie real de ataque es el tamaño del dom0**. De ahí las reglas:
  **dom0 mínimo** (nada instalado que no sea necesario), **memoria fijada** con `dom0_mem=Xg,max:Xg`
  —nunca ballooning en dom0— y **vCPU acotadas y ancladas** (`dom0_max_vcpus`, `dom0_vcpus_pin`) para
  que una domU no le robe CPU. En XCP-ng el dom0 es una appliance: **no se instalan paquetes
  arbitrarios en él**; se rompe el soporte y el ciclo de actualización.
- El aislamiento de drivers en **dominios de servicio** (driver domains) es la baza arquitectónica
  histórica de Xen. Es real y sigue siendo su mejor argumento técnico, pero **fuera de Qubes OS y de
  nichos de alta seguridad casi nadie lo despliega**: no lo propongas como si fuera gratis.

**Modos de virtualización — estado verificado en `SUPPORT.md` de Xen (verbatim):**
- **x86/PV**: *"Status, x86_64: Supported"*, pero **`x86_32` sin shim: *"Supported, not security
  supported"*** — es decir, hay un modo retirado de facto. **PV es paravirtualización clásica,
  sin extensiones de hardware, y es el modo con más superficie en el hipervisor.**
- **x86/HVM**: *"Status, domU: Supported"*. Virtualización completa con QEMU como modelo de
  dispositivo: es QEMU quien aporta la mayor parte del código expuesto.
- **x86/PVH**: **el modo moderno y la elección por defecto**. domU *"Supported"*; **dom0
  *"Supported, with caveats"*** — la propia documentación advierte: *"PVH dom0 hasn't received the
  same test coverage as PV dom0"*, y le faltan al menos **SR-IOV de PCI** y el reenvío nativo de NMI.
  **Criterio: PVH para domU siempre que el invitado lo soporte; PVH dom0 solo con pruebas propias.**
- **Corrección importante**: PV **no está deprecado aguas arriba** (sigue "Supported" y sigue
  recibiendo XSA). La retirada es **aguas abajo**: **XCP-ng dejó de soportar PV** y solo permite
  arrancar invitados PV mediante **`pv-shim`** (PV dentro de un contenedor PVH), que **no es la vía
  recomendada**. No confundas una cosa con la otra al leer documentación.

**XCP-ng: almacenamiento y red**
- El modelo es **SR (Storage Repository) → VDI (disco virtual) → VBD**, no ficheros sueltos.
  Elección de SR: **LVM sobre bloque (iSCSI/FC)** para rendimiento previsible sin thin provisioning;
  **ext/file sobre local o NFS** cuando se quiere thin y snapshots baratos; **XOSTOR (LINSTOR/DRBD)**
  para replicación hiperconvergente. **El soporte de thin provisioning y de snapshot depende del tipo
  de SR y esa elección no se cambia sin vaciar el SR**: decídela una vez, con el dato delante.
- **La cadena de snapshots/VDI encadenados es el fallo operativo clásico de esta plataforma**:
  snapshots olvidados que no coalescen llenan el SR y bloquean el pool. **Vigilar el espacio libre
  del SR y la cola de coalesce es alerta obligatoria**, no un dashboard bonito.
- Red: objetos **PIF/VIF**, bonds a nivel de pool, VLAN en la red del pool y no en el invitado. La
  red física, MTU y LACP son de `networking-standards`.
- **Pool**: un **pool master** con la base de datos de xapi. La HA nativa exige **heartbeat SR** y se
  configura a nivel de pool. **Un pool sin master accesible es un pool sin plano de control**:
  replicación de la BD y procedimiento de promoción documentado y **probado**.

**Herramientas de invitado**: los **guest tools** de XCP-ng (drivers PV y agente) son dependencia de
primera clase — sin ellos no hay apagado ordenado, ni IP en inventario, ni quiesce. Se parchean.

## 4. Calidad y testing

**Omitida por artificial**: no hay build ni suite de tests propia del despliegue. El equivalente
operativo: actualización del pool en rolling con `xe` y evacuación previa, un failover de HA probado
al menos una vez al año, y validación de restore desde XO en `backup-recovery-standards`.

## 5. Seguridad

- **El proceso es XSA (Xen Security Advisory)** y hay que conocerlo porque marca el calendario de
  parcheo: hay **lista de predivulgación** para operadores y distribuidores significativos, con
  embargo — *"One working week between notification arriving at security@xenproject and the issue of
  our own advisory to our predisclosure list … Two working weeks between issue of our advisory to our
  predisclosure list and publication"* — y en la fecha de embargo *"we will publish the advisory, and
  push bugfix changesets to public revision control trees"*. **Para organizaciones el listón de
  entrada es alto**: *"a rule of thumb is that 'large scale' means an installed base of 300,000 or
  more Xen guests"*. Traducción: **tú no vas a estar en la lista**; te enteras el día de publicación,
  así que el procedimiento de parcheo de emergencia debe estar escrito **antes**.
- **Historial**: Xen acumula un volumen alto de avisos de hipervisor (índice XSA muy por encima de
  400 a mediados de 2026, incluidos escapes y filtraciones entre dominios). Eso **no es señal de
  producto malo**: es señal de un proyecto con divulgación disciplinada y de que **el hipervisor es
  una frontera de seguridad que falla de verdad**. La consecuencia operativa es la misma en Xen que
  en cualquier otro: **un XSA de escape de dominio es cambio de emergencia**, no ciclo mensual.
- **El tamaño del dom0 es la superficie de ataque**: cada paquete, servicio y driver en dom0 amplía
  lo que un escape puede alcanzar. Regla: dom0 mínimo, sin servicios de red que no sean el toolstack,
  y gestión (`xe`, XO, SSH) en **VLAN de gestión aislada, sin ruta desde la red de usuarios**.
- **HVM implica QEMU en el modelo de amenaza**: gran parte de los XSA con impacto de escape están en
  el modelo de dispositivo. Preferir **PVH** cuando el invitado lo permite reduce el problema por
  construcción — es el argumento técnico real a favor de PVH, no el rendimiento.
- Autenticación del pool y de XO integrada con el IdP corporativo (`identity-access-management-standards`);
  **nunca `root` compartido del pool como cuenta de trabajo**.

## 6. Rendimiento y operabilidad

- **Planificador**: `credit2` como general; `null` solo para asignación estática 1:1 en latencia
  determinista (telco, tiempo real). Es decisión de plataforma, no ajuste por VM.
- **CPU pinning y NUMA** pesan más en Xen por el efecto del dom0: dom0 anclado y separado de las CPU
  de las domU en hosts cargados. **Nada de ballooning agresivo** en dom0 ni en memoria sensible.
- Métricas que deciden: CPU por dominio (`xentop`), presión de memoria, **espacio libre del SR y cola
  de coalesce**, latencia de VDI y estado del pool master (`observability-standards`).

## 7. Sostenibilidad, criterio de elección y prohibiciones

**Dicho sin adornos: para un despliegue nuevo en empresa, la elección por defecto del catálogo es
KVM — vía `proxmox-ve-standards` (plataforma) o `libvirt-kvm-standards` (host suelto).** Motivos:
base instalada, ecosistema de herramientas y respaldo, cantera de gente que lo sabe operar, e
integración con todo lo demás. **Xen no es peor tecnología; es una apuesta con menos gente detrás en
el segmento empresarial**, y eso se paga en contratación, en soporte de terceros y en tiempo de
diagnóstico.

**Xen (vía XCP-ng) sí se justifica cuando:**
- **Ya hay XenServer/Citrix Hypervisor desplegado** y se quiere salir del contrato sin rehacer el
  modelo operativo: XCP-ng es la ruta de menor fricción (mismo `xe`, mismo modelo de pool/SR/VDI).
- Hay **requisito de aislamiento** que se apoya en la arquitectura de Xen: dominios de servicio,
  hipervisor pequeño, casos de alta seguridad o de certificación (perfil tipo Qubes, automoción,
  sistemas críticos).
- Hay **compatibilidad heredada** concreta con imágenes, herramientas o integraciones XenServer.
- El equipo **ya domina XCP-ng** y opera bien con Xen Orchestra: cambiar de plataforma solo por moda
  es peor decisión que quedarse.

**Xen como destino de salida de VMware** es una opción viva y es el caso comercial actual de Vates
(importación desde VMware en XO), pero **no es la ruta por defecto del catálogo**: el criterio de qué
se mide antes de salir está en `vmware-standards` §7 y el destino por defecto en
`proxmox-ve-standards`. Elegir XCP-ng sobre PVE debe justificarse por uno de los cuatro motivos de
arriba, no por comparativa de funciones.

**Prohibiciones:**
- ❌ **PROHIBIDO** desplegar invitados **PV** en producción nueva. PVH si el invitado lo soporta;
  HVM si no. ❌ `pv-shim` como solución permanente.
- ❌ **PROHIBIDO** `x86_32` PV sin shim: la propia documentación lo marca **sin soporte de seguridad**.
- ❌ **PROHIBIDO** instalar paquetes arbitrarios, servicios o agentes en el **dom0** de XCP-ng.
- ❌ **PROHIBIDO** dom0 con memoria dinámica o sin `dom0_mem` fijado.
- ❌ **PROHIBIDO** exponer `xe`, xapi, XO o el dom0 a la red de usuarios o a Internet.
- ❌ **PROHIBIDO** operar en producción **sin monitorizar espacio libre del SR y la cola de coalesce**:
  es el modo de fallo que para el pool.
- ❌ **PROHIBIDO** tratar un snapshot de VDI como respaldo, y ❌ dejar snapshots vivos sin caducidad.
- ❌ **PROHIBIDO** producción sobre **pre-releases** de XCP-ng: *"Vates does not offer commercial
  support for pre-releases"* y *"may not receive urgent security updates as promptly"*.
- ❌ **PROHIBIDO** montar el respaldo sobre Xen Orchestra sin decidir explícitamente XOA con soporte
  o XO desde fuentes con dueño interno asignado.
- ❌ **PROHIBIDO** modificar Xen Orchestra y ofrecerlo como servicio sin cumplir la **AGPL-3.0**.
- ❌ **PROHIBIDO** posponer un XSA con impacto de escape de dominio al ciclo ordinario de parcheo.
- ❌ **PROHIBIDO** elegir Xen para un despliegue nuevo sin escribir cuál de los cuatro motivos de §7
  aplica.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar en fuente primaria (xenproject.org, `SUPPORT.md` del árbol de Xen,
docs.xcp-ng.org, docs.xen-orchestra.com, docs.xenserver.com) y con fecha:
1. **Versión vigente del hipervisor Xen** — verificada 4.21 (nov-2025); **comprobar si ya hay 4.22**
   y qué ramas estables siguen mantenidas.
2. **XCP-ng**: versión recomendada, estado de **9.0** (a ago-2026 **no GA**) y fechas de fin de
   soporte. 8.3 LTS: soporte hasta **2028-11-30**.
3. **`SUPPORT.md` de la versión concreta**: el estado de PV/PVH/HVM y de PVH dom0 cambia entre
   versiones. No dar por buena esta tabla sin releerlo.
4. **Hueco declarado — precios**: no se escribe ninguna cifra de XOA ni de soporte de Vates sin
   oferta. El modelo verificado es **por host y año, por niveles**; los importes se cotizan.
5. **Hueco declarado — XenServer**: el estado de XenServer 9, sus ediciones y el alcance exacto de la
   Trial Edition proceden de documentación de producto y prensa (jul-2026); **contrastar con
   docs.xenserver.com y con el contrato** antes de basar una decisión en ellos.
6. **XSA recientes** y si alguno afecta a los modos o dispositivos en uso; comprobar también los
   avisos de QEMU si hay invitados HVM.
7. Licencias **en crudo** si cambia algo: `COPYING` de Xen, `LICENSE` de `xcp-ng/xcp` y de
   `xapi-project/xen-api`, y el campo `license` de los `package.json` de Xen Orchestra. Verificado a
   ago-2026: **GPL-2.0 only**, **GPL-2.0**, **LGPL-2.1 con excepción** y **AGPL-3.0-or-later**.
8. Estado del ecosistema de respaldo de terceros para XCP-ng (cobertura real, no anuncios).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
