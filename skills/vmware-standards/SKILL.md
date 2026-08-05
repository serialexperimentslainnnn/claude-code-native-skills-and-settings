---
name: vmware-standards
description: VMware vSphere / VCF as a production platform under Broadcom, and the stay-or-exit decision. Use when running esxcli, vim-cmd, vsish, govc, PowerCLI cmdlets (Connect-VIServer, Get-VMHost, Get-VM, New-VM, Set-VMHostAdvancedConfiguration), the vSphere REST/vSphere Automation API or the terraform-provider-vsphere, operating vCenter Server Appliance (VCSA), vpxd, hostd, /var/log/vmkernel.log, .vmx, .vmdk, .nvram, .vswp or VMFS datastores, sizing a cluster with vSphere HA admission control, DRS, EVC baselines, vMotion and Storage vMotion, vSAN ESA/OSA disk groups and storage policies (SPBM), vSphere Distributed Switch, port groups, NSX segments or Tanzu/vSphere Supervisor, patching with vSphere Lifecycle Manager cluster images and baselines, VMware Tools and VM hardware version compatibility, VADP-based backup, VMSA advisories and ESXi/ESX CVE response, or costing VCF/VVF per-core subscriptions, the 16-core-per-CPU minimum, vSAN TiB entitlements, free ESXi, and whether to migrate off VMware.
---

# Estándares de VMware vSphere / VMware Cloud Foundation

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: en 2026 la decisión sobre VMware que hay encima de la mesa en casi toda
> organización no es técnica, es **económica**: quedarse o salir. La plataforma sigue siendo
> técnicamente competente; lo que cambió es el contrato. Cualquier respuesta que ignore el modelo
> de licencia vigente (§2) es una respuesta incompleta, por buena que sea la arquitectura.

## 1. Alcance y triggers

Aplica a **vSphere/VCF como plataforma de producción** y a la **decisión económica** sobre ella:
versión y calendario de soporte, modelo de licenciamiento y sus mínimos, diseño de clúster (HA,
DRS, vMotion, EVC), almacenamiento (VMFS, NFS, vSAN, SPBM), red del hipervisor (vSS/vDS, y NSX solo
para acotarlo), parcheo con vLCM, automatización (PowerCLI, API, Terraform), hardening del plano de
gestión, y **el criterio de salida** hacia otra plataforma.

Disparadores: `esxcli`, `vim-cmd`, `vsish`, `govc`, `Connect-VIServer` y demás cmdlets de PowerCLI,
`terraform-provider-vsphere`, VCSA, `vpxd`, `hostd`, `/var/log/vmkernel.log`, `.vmx`, `.vmdk`,
`.nvram`, VMFS, `vmware-tools`/`open-vm-tools`, "admission control", "EVC baseline", "storage
policy", "vSphere Lifecycle Manager", "cluster image", "VADP", "VMSA-", "VCF", "VVF", "core
minimum", "renovación de VMware".

**Nomenclatura**: con VCF 9.0 el hipervisor pasa a llamarse **ESX** (antes ESXi); los avisos de
seguridad de 2026 ya usan "VMware ESX" (VMSA-2026-0006). Aquí se usan indistintamente.

**No aplica**:
- `proxmox-ve-standards` — **destino de migración nº1** y skill hermana: **todo lo que se decide
  con `pvecm`/`qm`/`pvesm` o en `/etc/pve/` es suyo**, incluido su asistente de importación desde
  ESXi. Aquí se decide **si** se sale y **qué se mide antes**; allí, cómo se aterriza.
- `libvirt-kvm-standards` — el sustrato KVM/QEMU sin plataforma (`virsh`, XML de dominio). Destino
  válido solo para hosts sueltos: **salir de vCenter a libvirt puro es perder plataforma**, no
  cambiarla.
- `onprem-standards` — **paraguas de plataforma on-premise, con la tabla de enrutado (§1.2)**: su
  §2 ya fija la elección por defecto de hipervisor; esta skill desarrolla el caso VMware sin
  contradecirla.
- `ha-clustering-standards` — Pacemaker/Corosync, quórum y fencing **genéricos** de servicios
  Linux. Aquí el clúster **nativo** del hipervisor: vSphere HA, admission control y aislamiento.
- `linux-storage-standards` y `zfs-standards` — LUN, multipath, filesystem y ZFS del lado del SO;
  aquí VMFS/NFS/vSAN como objetos de vSphere. `object-storage-standards` — S3 y repositorios.
- `networking-standards` — red física, VLAN, MTU y fabric; aquí solo vSwitch/vDS y port groups.
- `backup-recovery-standards` — **mecánica del respaldo, retención, inmutabilidad y restore
  probado son suyas**; aquí solo la API de respaldo (VADP) y la consistencia de aplicación.
- `bcdr-standards` — RTO/RPO, plan y ejercicios de DR; aquí no se fijan objetivos de negocio.
- `iac-standards` — Terraform/Ansible como práctica; `powershell-standards` — calidad del script
  PowerCLI. Aquí solo qué se automatiza y qué queda acoplado a vCenter.
- `kubernetes-standards` — contenedores por encima (incluido lo que corre sobre Supervisor);
  `gpu-computing-standards` — passthrough y reparto de GPU (driver y particionado son suyos).
- `linux-hardening-standards` y `vulnerability-management-standards` — baseline del SO invitado y
  triaje/SLA de CVE; `observability-standards` — telemetría como práctica.
- `finops-standards` — **el coste por VM como unidad económica y el método de comparación son
  suyos**; aquí el **modelo de licencia** del producto que alimenta ese cálculo.
- `enterprise-architecture-standards` — portfolio y ADR; `migration-projects-standards` — ejecución de la migración; `windows-server-ad-standards` — el invitado Windows;
  `hyper-v-standards` y `xen-standards` — hipervisores alternativos, cada uno el suyo.

## 2. Versión, calendario y modelo de licencia (la sección cara)

> Verificar la última versión y **todo precio o mínimo** por web antes de fijarlo (§8).

| Dato | Estado verificado ago-2026 | Fuente |
|---|---|---|
| Generación vigente | **VCF/VVF 9.1**; VCF 9.0 GA **17-jun-2025** | TechDocs/blog VCF |
| Cadencia | Mayor ≈3 años; menor ≈9 meses; mantenimiento ≈3 meses en la primera fase de soporte | KB 410435, verbatim |
| EoGS vSphere 7.0 | **2-oct-2025** (ya pasado) | KB 415405, verbatim |
| EoGS vSphere 8 | Ampliamente citado **11-oct-2027** — **no confirmado en fuente primaria**: ver §8 | — |
| Unidad de licencia | **Por núcleo físico**, suscripción a plazo. **No hay perpetuas nuevas** | KB 313548 / TechDocs |
| Mínimo por CPU | *"You must license a minimum of 16 physical cores for each CPU (physical processor) in your ESXi hosts, even if a CPU has fewer than 16 cores."* | KB 313548, **verbatim** |
| vSAN incluido | VCF: *"1 TiB of vSAN entitlement for each VCF core purchased"*. VVF: *"0.25 TiB … (rounded up to the next TiB)"* | KB 313548, **verbatim** |
| Mecanismo 9.x | *"Subscription-based license files replace the use of the 25-character license keys."* Se licencia desde VCF Operations + consola **vcf.broadcom.com** | TechDocs Licensing Overview, **verbatim** |
| Telemetría obligatoria | *"License usage reports are required at least once every 180 days to maintain your licenses"* | idem, **verbatim** |
| ESXi/ESX gratis | **Vuelve** con 8.0U3e: *"fully production-ready release"*, pero *"No official Broadcom support"*, *"Cannot be managed by vCenter Server"*, 2 CPU físicas/host, 8 vCPU/VM, sin vMotion/DRS/HA/VADP, *"Usage of APIs to manage hosts is not supported"* | KB 399823, **verbatim** |

**Reglas que se derivan y no se negocian:**

- **Se licencia todo el core físico de todo host que ejecute el producto**: no hay licencia por VM ni
  por capacidad, ni exención de test/dev, y apagar cores en BIOS no reduce el conteo. Como el mínimo
  de 16/CPU castiga los hosts pequeños, **la única palanca real de coste es consolidar en menos hosts
  más densos**, no comprar menos.
- **VVF vs VCF**: VVF es la base (vSphere + vSAN limitado + operación); VCF añade NSX y automatización.
  Comprar VCF "porque venía en el paquete" y no usar NSX es el sobrecoste más común.
- **Renovar tarde se penaliza**: prensa de canal (memo de Arrow vía CRN, *The Register* 28-mar-2025)
  reporta *"penalties for end customers who have not renewed their subscription licenses … on the
  anniversary date"*, del 20 % sobre el primer año. **No publicado por Broadcom**: riesgo de
  calendario, no cifra cerrada.
- **Discrepancia declarada — mínimo de 72 cores**: la misma fuente reporta *"the minimum number of
  cores required for VMware licenses will increase substantially, from 16 to 72 cores per command
  line"*, *"as of April 10th"* (2025). Fuentes posteriores lo dan por **aclarado a 72 por
  producto/pedido** o **retirado**, mientras el mínimo primario de **16 por CPU** sigue publicado sin
  cambios. **No hay fuente primaria de Broadcom para el 72.** Planifica con 16/CPU y **exige por
  escrito al partner el mínimo aplicable a tu pedido**.
- **Canal**: el programa VMware Advantage terminó el **31-oct-2025** y pasó a **invitación
  (Pinnacle)**; el modelo **White Label desapareció** y los VCSP no invitados dejaron de renovarse
  (avisos escalonados hasta ene-mar 2026). Fuente: prensa de canal, **no primaria**. Consecuencia:
  **verifica que tu proveedor sigue autorizado antes de contar con él para la renovación.**
- **Precio**: Broadcom **no publica precios de lista**; todo pasa por partner. **Ninguna cifra de
  €/core se escribe sin oferta firmada** (§8).

## 3. Arquitectura y operación

**Clúster y cómputo**
- Clúster homogéneo en CPU y firmware. **Baseline EVC fijada desde el día 1**: activarla después
  obliga a apagar VMs. EVC por VM solo para movilidad puntual.
- **vSphere HA con admission control explícito** y reserva dimensionada al fallo tolerado (N+1
  mínimo). HA sin reserva es HA que no arranca las VMs cuando hace falta.
- **DRS en `fullyAutomated`** salvo motivo escrito, con reglas de afinidad/antiafinidad para lo que
  debe quedar separado. **DRS predictivo** solo con la suite de operaciones alimentándolo y con
  histórico suficiente; sin eso es ruido.
- vMotion y Storage vMotion en **red dedicada** (VLAN propia, MTU coherente) y con vmknics
  redundantes. Storage vMotion se planifica: consume cabina.

**Almacenamiento**
- **VMFS** para bloque, **NFS** cuando la cabina lo hace mejor, **vSAN** cuando se acepta que el
  almacenamiento pasa a ser parte del clúster. **vSAN se licencia aparte por TiB** más allá del
  derecho incluido: es la fuga de coste que aparece a los dos años.
- **SPBM siempre**: política por clase de servicio, nunca por datastore a mano. **vSAN ESA** para
  hardware nuevo; OSA solo por hardware heredado. **vVols están deprecados en VCF/VVF 9.0**
  (KB 401070): no se diseña nada nuevo sobre ellos.

**Red**
- **vDS por defecto** en producción: la config vive en vCenter, consistente y auditable. vSwitch
  estándar solo para arranque del host y rescate.
- **NSX solo si hay requisito de microsegmentación o de red superpuesta que la física no cubre.** Es
  un producto entero con su plano de control y su curva: adoptarlo **encarece la salida** más que
  ninguna otra decisión de esta lista.

**Operación, respaldo y automatización**
- **vLCM con imagen de clúster** (base + vendor addon + firmware), no baselines: es lo único que hace
  todos los hosts idénticos y reproducibles. Parcheo rolling con DRS evacuando.
- **VMware Tools / open-vm-tools es dependencia de primera clase**: sin él no hay quiesce, apagado
  ordenado, IP en inventario ni consistencia de respaldo. Se parchea y se monitoriza como el
  hipervisor. La **versión de hardware de VM** se sube por olas: vuelta atrás cara.
- Respaldo por **VADP** (snapshot + CBT desde el producto de backup), nunca copiando `.vmdk` en
  caliente; quiesce con VSS/scripts. Retención, inmutabilidad y restore: `backup-recovery-standards`.
- **PowerCLI** para operación, **API REST/Automation** para integración, **proveedor de Terraform**
  para lo reproducible (`powershell-standards`, `iac-standards`). **Todo automatismo acoplado a
  vCenter es deuda de salida**: inventaríalo (§7).

## 4. Calidad y testing

**Omitida por artificial**: no hay build ni suite de tests. Equivalente exigible: cada cambio de
clúster se valida en preproducción con la misma imagen, y el failover de HA se prueba anualmente.

## 5. Seguridad del stack

- **vCenter comprometido es el centro de datos comprometido.** Da control sobre todas las VMs, sus
  discos y sus consolas: es **Tier 0**, no "una aplicación de gestión más". Estación administrativa
  dedicada, MFA, cuentas nominales, sin SSO compartido con el parque ofimático y
  `administrator@vsphere.local` reservado y auditado.
- **Plano de gestión aislado**: vCenter, gestión de ESX, iDRAC/iLO y vMotion en VLAN propias, **sin
  ruta desde la red de usuarios**. Modo bloqueo en los hosts; ESXi Shell y SSH apagados salvo
  ventana, con excepciones registradas.
- **Baseline de hardening**: guía oficial en el repositorio de Broadcom
  `github.com/vmware/vcf-security-and-compliance-guidelines` (por versión, ya con 9.0). **CIS**: a
  ago-2026 lo más reciente es **ESXi 8.0 v1.3.0** y **no hay benchmark de 9.0/ESX** — Broadcom como
  baseline técnico, CIS cuando la auditoría exige marco atestable, y el hueco declarado.
- **Parcheo**: los avisos son **VMSA** y llegan sin preaviso. Referencia: **VMSA-2026-0006
  (29-jul-2026)** — bypass de autenticación en vCenter (CVE-2026-59309, 9.8), traversal en su syslog
  (CVE-2026-59310) y **escape de VM** vía VMXNET3 (CVE-2026-47876, 9.3) **sin workaround**. Regla:
  **escape de VM o bypass de autenticación en vCenter es cambio de emergencia**; el SLA general es de
  `vulnerability-management-standards`.
- Cifrado de VM y vTPM solo con custodia de claves resuelta (KMS externo **y su respaldo**): perder
  el proveedor de claves es perder las VMs (`cryptography-pki-standards`).

## 6. Rendimiento y operabilidad

- Métricas que deciden: `%RDY` y `co-stop` (sobresuscripción de vCPU), *ballooning* y *swap* del
  host, latencia de datastore y saturación de vMotion. Exportar a `observability-standards`.
- VMs anchas (muchas vCPU) penalizan la planificación: dimensionar por consumo real, no por lo que
  pidió el proveedor de la aplicación. Sin reservas ni límites por defecto; un límite de CPU
  olvidado es la causa raíz recurrente de "la VM va lenta y no se sabe por qué".
- Capacidad medida contra **cores licenciados**, no contra cores instalados: en este modelo, la
  capacidad ociosa se paga.

## 7. Sostenibilidad y criterio de salida

**Antes de decidir quedarse o salir, se mide esto — y se mide, no se estima:**
1. **Coste real por VM al año** con la renovación ya cotizada (método en `finops-standards`), frente
   al mismo cálculo en la plataforma destino incluyendo hardware, soporte, respaldo y **horas de
   personal**.
2. **Dependencia de vSAN y de NSX**: si el almacenamiento o la microsegmentación viven ahí, la
   salida deja de ser "mover VMs" y pasa a ser rediseñar dos capas.
3. **Formato de disco y arranque**: `.vmdk` a qcow2/raw, BIOS vs UEFI, controladoras (PVSCSI→virtio),
   drivers del invitado, y el renombrado de interfaces de red que se lleva por delante IPs estáticas
   y reglas de firewall.
4. **Respaldo**: el producto actual puede no soportar el destino, o soportarlo peor. Se valida el
   **restore** en el destino antes de migrar nada, no después.
5. **Automatización acoplada**: cada script PowerCLI, pipeline con el proveedor de Terraform de
   vSphere e integración por API es trabajo de reescritura que no aparece en la hoja de cálculo.
6. **Personal**: el equipo sabe vSphere. La curva de la plataforma destino es coste real durante
   12-18 meses, y el riesgo operativo en ese periodo es mayor que el ahorro del primer año.

**Por eso la salida cuesta más de lo que dice la hoja de cálculo**: la hoja compara licencias, y el
proyecto paga rediseño de almacenamiento y red, reescritura de automatización, revalidación de
respaldo y DR, ventanas de parada y una curva de aprendizaje. **Salir puede seguir siendo correcto
—y a menudo lo es—, pero se decide con el coste completo, no con el delta de licencia.**

**Prohibiciones:**
- ❌ **PROHIBIDO** escribir un número de €/core, €/VM o "ahorro estimado" sin oferta firmada.
- ❌ **PROHIBIDO** dimensionar una compra sin el mínimo de cores por CPU **confirmado por escrito**
  por el partner para ese pedido concreto (§2, discrepancia del 72).
- ❌ **PROHIBIDO** el ESXi gratuito en producción: sin soporte, sin vCenter, sin HA/vMotion y **sin
  VADP** — es decir, sin respaldo por API. Laboratorio y nada más.
- ❌ **PROHIBIDO** exponer vCenter o las interfaces de gestión de ESX a la red de usuarios o a
  Internet, y ❌ usar `administrator@vsphere.local` como cuenta de trabajo diaria.
- ❌ **PROHIBIDO** tratar un snapshot de vSphere como respaldo, y ❌ dejar snapshots vivos más allá
  de la ventana de cambio (crecimiento del delta y consolidación imposible).
- ❌ **PROHIBIDO** diseñar sobre **vVols** (deprecados en 9.0) o sobre ediciones que ya no se
  renuevan sin plan de destino.
- ❌ **PROHIBIDO** clústeres heterogéneos sin EVC, y ❌ activar EVC "más adelante".
- ❌ **PROHIBIDO** posponer un VMSA de escape de VM o de bypass de autenticación al ciclo ordinario.
- ❌ **PROHIBIDO** iniciar una migración de salida sin **restore probado en el destino** y sin
  fallback documentado por ola.
- ❌ **PROHIBIDO** dar por hecho que el proveedor actual podrá renovar: se verifica su autorización.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar en fuente primaria (Broadcom TechDocs, KB del portal de soporte,
avisos VMSA) y con fecha:
1. **Versión vigente** de VCF/VVF y de sus componentes, y su **EoGS/EoTG en el Product Lifecycle
   Matrix**. **Hueco declarado**: no se ha confirmado en fuente primaria la fecha de EoGS de
   vSphere 8 (ampliamente citada como 11-oct-2027) ni el EoGS de 9.0/9.1 — verificar en la matriz.
2. **Hueco declarado — precios**: no hay lista pública. **No se escribe ninguna cifra sin oferta**.
3. **Hueco declarado — mínimo de pedido**: el "mínimo de 72 cores" solo consta en prensa de canal y
   se reporta aclarado o retirado. Confirmar por escrito con el partner. Lo primario y vigente es
   **16 cores por CPU** (KB 313548).
4. **Hueco declarado — penalización por renovación tardía** (20 %): prensa de canal, no primaria.
5. Estado del **programa de partners** y de la vía de compra: cambió tres veces entre 2024 y 2026.
6. Estado de las **ediciones** vendibles (VVF/VCF frente a Standard/Enterprise Plus): las fuentes
   secundarias se contradicen sobre cuáles siguen renovándose. **Contrastar con el partner.**
7. Condiciones vigentes del **ESXi/ESX gratuito** (versión ofrecida, límites, si sigue disponible).
8. **VMSA** posteriores a VMSA-2026-0006 y su estado de explotación (KEV/CISA).
9. Estado de **CIS Benchmark** para ESX 9.0 y versión vigente del repositorio de hardening de
   Broadcom.
10. Madurez y estado de las plataformas destino (Proxmox VE, Nutanix, Hyper-V/Azure Local,
    OpenStack, OLVM, XCP-ng) — **el criterio de cada una es de su skill**, no de esta.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
