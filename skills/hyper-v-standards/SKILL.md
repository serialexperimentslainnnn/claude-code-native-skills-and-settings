---
name: hyper-v-standards
description: Hyper-V on Windows Server and Azure Local as a production virtualization platform. Use when running Hyper-V PowerShell cmdlets (New-VM, Set-VMProcessor, Get-VMSwitch, New-VMSwitch, Add-VMNetworkAdapter, Checkpoint-VM, Move-VM, Enable-VMResourceMetering) or Failover Clustering cmdlets (New-Cluster, Test-Cluster, Get-ClusterQuorum, Set-ClusterQuorum, Add-ClusterSharedVolume, Update-ClusterFunctionalLevel, Invoke-CauRun), sizing a Windows Server Failover Cluster (WSFC) with node majority, file share or cloud witness, Cluster Shared Volumes under C:\ClusterStorage, SMB3 file shares with Multichannel and RDMA, Storage Spaces Direct (S2D), Switch Embedded Teaming (SET) versus LBFO, SR-IOV, VMQ, generation 1 versus generation 2 VMs, .vhdx and .avhdx files, Secure Boot and vTPM in a VM, guarded fabric and shielded VMs with Host Guardian Service, Hyper-V checkpoints, live migration and CredSSP versus Kerberos constrained delegation, Cluster-Aware Updating and cluster OS rolling upgrade, Windows Admin Center, or costing Windows Server Standard versus Datacenter core licensing and guest virtualization rights.
---

# Estándares de Hyper-V (Windows Server / Azure Local)

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

> **Premisa dura**: **Hyper-V es el hipervisor que ya has pagado si tienes Windows Server.** Su
> ventaja es económica y de integración con el dominio, no técnica: no gana a KVM ni a vSphere en
> nada concreto, pero si vas a licenciar Windows en los invitados de todas formas, la comparación de
> coste la gana con frecuencia. Elegirlo por otra razón que esa suele ser una decisión mal hecha.

## 1. Alcance y triggers

Aplica a **Hyper-V como plataforma de virtualización de producción**: rol en Windows Server frente a
Azure Local, licenciamiento por núcleos y derechos de virtualización de invitados, clúster WSFC con
su quórum y testigo, almacenamiento (CSV, SMB3, S2D), red virtual (conmutador virtual, SET, SR-IOV),
generación y seguridad de la VM, y operación por PowerShell.

Disparadores: `New-VM`, `Set-VMProcessor`, `Get-VMSwitch`/`New-VMSwitch`, `Checkpoint-VM`, `Move-VM`,
`New-Cluster`, `Test-Cluster`, `Set-ClusterQuorum`, `Add-ClusterSharedVolume`, `Invoke-CauRun`,
`Update-ClusterFunctionalLevel`, `C:\ClusterStorage\`, `.vhdx`/`.avhdx`, "SET", "LBFO", "VMQ",
"SR-IOV", "gen 1 vs gen 2", "vTPM", "shielded VM", "Host Guardian Service", "punto de control",
"migración en vivo", "Windows Admin Center", "Standard o Datacenter".

**No aplica**:
- `windows-server-ad-standards` (**ya escrita**) — **el SO Windows, el dominio, GPO, Kerberos y el
  modelo Tier 0 son suyos**. Aquí solo el rol Hyper-V y el clúster que lo sostiene. Frontera: si la
  respuesta se escribe con `Get-ADUser`/GPO, es de allí; con `Get-VM`/`Get-Cluster`, de aquí.
- `powershell-standards` (**ya escrita**) — **calidad del script**: módulos, manejo de errores,
  `-WhatIf`, pruebas. Aquí qué se automatiza, no cómo se escribe el `.ps1`.
- `vmware-standards` y `xen-standards` — cada skill cubre su hipervisor; la comparación económica
  frente a VMware se hace desde `vmware-standards` (§7, criterio de salida).
- `proxmox-ve-standards` y `libvirt-kvm-standards` — **las plataformas KVM del catálogo**, y el
  destino de migración alternativo cuando la tienda no es Microsoft.
- `onprem-standards` — **paraguas de plataforma on-premise con la tabla de enrutado (§1.2)**.
- `ha-clustering-standards` — Pacemaker/Corosync, quórum y fencing **genéricos** en Linux. **WSFC es
  del hipervisor y se decide aquí**; el principio de quórum es común, la implementación no.
- `linux-storage-standards`, `zfs-standards`, `object-storage-standards` — almacenamiento fuera de
  CSV/S2D/SMB3.
- `networking-standards` — red física, VLAN, MTU, jumbo frames y switch de ToR; aquí el conmutador
  virtual y SET.
- `backup-recovery-standards` — **mecánica del respaldo, retención, inmutabilidad y restore probado**;
  aquí solo el proveedor VSS y la consistencia de aplicación. `bcdr-standards` — RTO/RPO y plan.
- `iac-standards` — Terraform/Ansible/DSC como práctica; `kubernetes-standards` — contenedores por
  encima; `gpu-computing-standards` — DDA/GPU-P: driver y reparto son suyos.
- `azure-standards` — todo lo que vive en Azure; aquí Azure Local solo como producto on-premise.
- `vulnerability-management-standards` y `observability-standards` — triaje de CVE y telemetría.
- `finops-standards` (**ya escrita**) — **el coste por VM y el método de comparación son suyos**;
  aquí el modelo de licencia. `enterprise-architecture-standards` y `migration-projects-standards`
  — decisión de portfolio y ejecución de la migración.

## 2. Versión, calendario y licencia (el cálculo que decide la densidad)

> Verificar la última versión y **todo mínimo o derecho de licencia** por web antes de fijarlo (§8).

| Dato | Estado verificado ago-2026 | Fuente |
|---|---|---|
| LTSC vigente | **Windows Server 2025** (disponible desde 1-nov-2024). No hay "Windows Server 2026" anunciado: la siguiente LTSC está en preview sin nombre | Microsoft Learn / release health |
| Ciclo LTSC | *"5 years of mainstream support and 5 years of extended support for a total lifecycle of 10 years"* | Learn, **verbatim** |
| WS 2025 | Fin de soporte general **13-nov-2029**; extendido **14-nov-2034** | Ciclo de vida MS |
| WS 2022 | **Fin de soporte general 13-oct-2026** — inminente: planificar ya | Ciclo de vida MS |
| WS 2016 | Fin de soporte **12-ene-2027** | Ciclo de vida MS |
| Unidad de licencia | Por **núcleo físico**: *"a minimum of 8 core licenses per physical processor and a minimum of 16 core licenses per server"* | Guía de licenciamiento WS2025, **verbatim** |
| Por VM | *"Licensing by virtual machine requires subscription licenses or licenses with active Software Assurance."* | idem, **verbatim** |
| Standard | *"Windows Server Standard provides rights to use two operating system environments (physical or virtual OSEs)"* | idem, **verbatim** |
| Apilado | *"for each additional set of two OSEs or two Hyper-V containers the customer wishes to use, the server must be relicensed for the same number of core licenses."* | idem, **verbatim** |
| Datacenter | *"Windows Server Datacenter provides rights to use any number of operating system environments (physical or virtual OSEs)"* | idem, **verbatim** |
| Azure Local | *"priced per physical core on your on-premises machines, plus any consumption-based charges … All charges roll up to your existing Azure subscription."* | Learn Azure Local, **verbatim** |

**El cálculo de densidad, que es la decisión:**
- **Standard se apila**: 2 OSE por juego completo de licencias del servidor. Con *N* VMs Windows en
  un host hay que licenciar el host `ceil(N/2)` veces. **El punto de cruce con Datacenter está en
  torno a 12-14 VMs Windows por host** según precio negociado — **calcúlalo con los precios de tu
  contrato, no con esta cifra** (§8).
- **Las VMs Linux no consumen OSE de Windows**, pero **el host sí se licencia entero igual**: un host
  con Hyper-V y solo invitados Linux necesita licencia de Windows Server para el host. Ahí Hyper-V
  pierde su ventaja económica y la comparación con KVM cambia de signo.
- **Standard permite usar el OSE físico solo para hospedar y gestionar los virtuales.** Meter roles
  en el host (fichero, IIS, controlador de dominio) consume uno de los dos OSE y además es mala
  práctica de seguridad.
- **CALs aparte**, por usuario o dispositivo, y **son específicas de versión**: presupuestarlas junto
  con la actualización de host, no después.
- **Datacenter es la edición obligatoria para Storage Spaces Direct**: si el diseño es
  hiperconvergente, la edición ya está decidida y el cálculo de densidad sobra.

**Hyper-V rol vs. Azure Local:**
- **Rol Hyper-V en Windows Server**: propiedad tuya, licencia perpetua + SA, sin dependencia de nube.
  Es la opción por defecto para virtualización on-premise clásica.
- **Azure Local** (antes **Azure Stack HCI**; renombrado por Microsoft) es **suscripción por núcleo
  facturada en Azure**, sobre **hardware certificado**, con Azure Arc como plano de control y
  **cadencia de release mensual con soporte corto por versión** — no es "Windows Server con otro
  nombre": es un producto con dependencia de nube y un ciclo de parcheo mucho más agresivo.
- **Criterio**: Azure Local solo si hay requisito real de gestión desde Azure, de servicios de Azure
  en local o de sucursales gestionadas centralmente. Si el requisito es "virtualizar en mi CPD",
  **rol Hyper-V sobre Windows Server**. Adoptar Azure Local sin ese requisito es sustituir un coste
  de capital por una suscripción y una dependencia de conectividad.

## 3. Arquitectura y operación

**Clúster (WSFC)**
- Nodos **homogéneos** en CPU, firmware y versión de SO. `Test-Cluster` completo antes de crear el
  clúster y tras cada cambio de hardware: **sin informe limpio, el clúster no es soportable**.
- **Quórum siempre con testigo** (obligatorio con número par de nodos, recomendable con impar):
  testigo **en la nube** o **de recurso compartido de ficheros en un tercer sitio**; nunca en un nodo
  del propio clúster ni en su misma cabina.
- Redes separadas y redundantes para gestión, CSV/almacenamiento y migración en vivo. Una sola red
  plana convierte un microcorte en un failover en cascada.

**Almacenamiento**
- **CSV** (`C:\ClusterStorage\`) para acceso simultáneo desde todos los nodos: requisito real de la
  migración en vivo sin copiar disco. **SMB3** (Multichannel + RDMA) es alternativa válida a SAN,
  contra un clúster de ficheros de escalabilidad horizontal, no contra un servidor suelto.
- **Storage Spaces Direct** — requisitos que no se negocian: **edición Datacenter**, **2 a 16
  servidores** certificados en el catálogo de Windows Server, discos directamente conectados por
  **HBA en paso a través, no controladora RAID**, mismo número y tipo de discos en todos los nodos,
  SSD con protección ante pérdida de energía, red **mínimo 10 GbE con RDMA recomendado** (iWARP o
  RoCEv2, y RoCEv2 exige configurar el switch de ToR). **S2D sobre hardware no validado es la causa
  principal de S2D que va mal**: compra solución validada o no lo hagas.
- **VHDX siempre** (no VHD). Disco fijo o dinámico según carga; **passthrough solo con motivo
  escrito** (rompe checkpoints, respaldo y migración).

**Red**
- **Conmutador virtual externo sobre SET**. **LBFO está deprecado bajo Hyper-V**: *"The Hyper-V
  Virtual Switch no longer has the capability to be bound to an LBFO team. Instead, it must be bound
  via Switch Embedded Teaming (SET)"* (Learn, verbatim). Diseño nuevo sobre LBFO: prohibido.
- **SR-IOV** solo con requisito de latencia demostrado: salta el conmutador virtual y con él la
  seguridad de puerto, el QoS y —según configuración— la migración en vivo. Excepción, no ajuste.
- VLAN en el port group de la VM, no en el invitado; MTU coherente (`networking-standards`).

**VM**
- **Generación 2 por defecto** (UEFI, Secure Boot, arranque SCSI, vTPM); generación 1 solo para
  invitados sin UEFI. **La generación no se cambia después**: es la decisión irreversible de la VM.
  Secure Boot activo, con la plantilla correcta para Linux (`MicrosoftUEFICertificateAuthority`).
- **VM blindadas / guarded fabric con HGS**: funcionan, pero están en *"no longer in development"*
  desde Windows Server 2022 —Microsoft redirige a Azure confidential computing y retiró el RSAT de
  VM blindadas del cliente—. **No se diseña nada nuevo sobre HGS**: si el requisito es proteger la VM
  del administrador del host, resuélvelo con controles organizativos y cifrado en el invitado, y
  déjalo escrito como riesgo aceptado.
- **Servicios de integración** al día (Windows Update en invitados Windows, `hv_*` en el kernel de
  Linux): sin ellos no hay apagado ordenado, ni latido, ni respaldo consistente.

**Operación**
- **Un punto de control NO es un respaldo.** Es un delta (`.avhdx`) en el mismo almacenamiento que la
  VM: no sobrevive a la pérdida del volumen, degrada el rendimiento y crece sin límite. Puntos de
  control **de producción** (VSS) solo como vuelta atrás de una ventana de cambio, **con borrado
  obligatorio al cerrarla**. El respaldo real es de `backup-recovery-standards`.
- **Migración en vivo con delegación restringida de Kerberos, no con CredSSP** (obliga a iniciar
  sesión en el nodo origen y expone credenciales). Red dedicada y cifrado si sale de la VLAN.
- **Cluster-Aware Updating** para parchear sin caída y **actualización gradual del SO del clúster**
  para saltar de versión sin vaciarlo: **el nivel funcional se eleva al final y no tiene vuelta
  atrás** (`Update-ClusterFunctionalLevel`); antes, todos los nodos actualizados y estables días.
- **PowerShell es el camino por defecto**, no la alternativa avanzada: es lo único reproducible,
  auditable y versionable. Windows Admin Center para diagnóstico, no para configurar
  (`powershell-standards`).

## 4. Calidad y testing

**Omitida por artificial**: no hay build ni suite de tests. Equivalente operativo: `Test-Cluster` con
informe limpio antes de producción y tras cada cambio de hardware, un failover provocado anual, y la
validación de restore de `backup-recovery-standards`.

## 5. Seguridad del stack

- **El host es Tier 0**: quien administra el host administra todas las VMs, sus discos y su memoria.
  Los hosts Hyper-V y el clúster se tratan con el modelo de niveles de `windows-server-ad-standards`:
  cuentas administrativas separadas, estaciones administrativas dedicadas, **sin sesión interactiva
  del administrador de dominio en el host**.
- **Delegación por rol** (Windows Admin Center / **JEA** de PowerShell), **nunca metiendo operadores
  en el grupo de administradores locales del host**: JEA es el mecanismo para "reiniciar sus VMs y
  nada más".
- **Plano de gestión aislado**: VLAN propia para gestión de host, BMC/iDRAC/iLO y migración en vivo,
  **sin ruta desde la red de usuarios**; WinRM sobre HTTPS y restringido por origen.
- **Server Core** por defecto en los hosts (menos superficie y menos reinicios); Desktop Experience
  solo con justificación. El **host no es servidor de nada más**: ni ficheros, ni DC, ni respaldo.
- **NTLMv2 está deprecado** en Windows Server 2025 (*"NTLMv2 will continue to work but will be removed
  from Windows Server in a future release"*, Learn, verbatim): la autenticación entre hosts y hacia
  el clúster va por Kerberos. Hardening por Microsoft Security Baselines / CIS; el detalle del SO es
  de `windows-server-ad-standards` y `vulnerability-management-standards`.

## 6. Rendimiento y operabilidad

- Contadores que deciden: `Hyper-V Hypervisor Logical Processor \ % Total Run Time` (no el `% CPU`
  del host, que miente), presión de memoria, latencia por VHDX y colas de CSV
  (`observability-standards`).
- **Memoria dinámica solo donde el invitado la soporta**, nunca con memoria fijada (SQL Server, NUMA
  sensible), y con mínimo y máximo configurados. VMs que no caben en un nodo NUMA pagan penalización.
- Reserva de capacidad del clúster para el fallo tolerado (N+1): un clúster al 90 % no puede conmutar
  y su HA es decorativa.

## 7. Sostenibilidad y prohibiciones

**Hyper-V es la respuesta correcta cuando:**
- La organización ya es **tienda Microsoft**: dominio de AD, invitados mayoritariamente Windows,
  equipo que opera con PowerShell, y licencias de Windows Server que se pagan de todas formas.
- **Datacenter ya está comprado** (o el número de VMs Windows lo justifica): el hipervisor sale
  efectivamente sin coste incremental de licencia.
- Se necesita integración natural con AD, WSFC, SMB3 y el ecosistema de respaldo Windows.

**No lo es cuando:**
- El parque es **mayoritariamente Linux**: pagas Windows Server en el host por nada. Ahí manda
  `proxmox-ve-standards` o `libvirt-kvm-standards`.
- Se busca **API y automatización de plataforma de primera clase** para infraestructura como código
  multiplataforma: el ecosistema es más pobre que el de KVM o vSphere.
- El requisito es **hiperconvergencia** y no se quiere ni Datacenter ni hardware validado de S2D.
- La operación es Linux y nadie sabe PowerShell: la curva no es el hipervisor, es la tienda entera.

**Prohibiciones:**
- ❌ **PROHIBIDO** usar puntos de control como respaldo, y ❌ dejarlos vivos más allá de la ventana
  de cambio.
- ❌ **PROHIBIDO** diseñar un conmutador virtual nuevo sobre **LBFO**: SET, siempre.
- ❌ **PROHIBIDO** S2D fuera de Datacenter, sobre controladora RAID, con nodos heterogéneos o sobre
  hardware no certificado.
- ❌ **PROHIBIDO** un clúster de número par de nodos **sin testigo**, o con el testigo alojado en el
  propio clúster o en su misma cabina.
- ❌ **PROHIBIDO** migración en vivo con **CredSSP** en producción: delegación restringida de Kerberos.
- ❌ **PROHIBIDO** ejecutar roles de aplicación, controlador de dominio o consola de respaldo en el
  host Hyper-V.
- ❌ **PROHIBIDO** meter operadores en el grupo de administradores locales del host en lugar de
  delegar por rol/JEA.
- ❌ **PROHIBIDO** elevar el nivel funcional del clúster antes de tener todos los nodos actualizados
  y estables: **no tiene vuelta atrás**.
- ❌ **PROHIBIDO** diseñar sobre **VM blindadas / HGS** en desarrollos nuevos (sin desarrollo activo).
- ❌ **PROHIBIDO** presupuestar Standard vs Datacenter con una cifra genérica: se calcula con los
  precios del contrato y el recuento real de VMs Windows por host.
- ❌ **PROHIBIDO** discos de paso a través o VHD (no VHDX) sin justificación escrita.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar en fuente primaria (Microsoft Learn, ciclo de vida de Microsoft, guía
de licenciamiento vigente) y con fecha:
1. **Versión LTSC vigente** y si ya existe sucesor de Windows Server 2025 con nombre y fechas.
2. **Fechas de ciclo de vida** exactas de la versión desplegada (2016/2019/2022/2025) — la de 2022
   vence en soporte general en **oct-2026**.
3. **Guía de licenciamiento vigente**: mínimos por procesador y por servidor, derechos de OSE por
   edición, condiciones del licenciamiento por VM y CALs. **Cambia entre versiones.**
4. **Hueco declarado — precios**: no se escribe ninguna cifra de €/core ni punto de cruce
   Standard/Datacenter sin los precios del contrato o una oferta. El punto de cruce citado en §2
   (12-14 VMs) es orientativo y **debe recalcularse**.
5. **Estado de Azure Local**: nombre vigente, versión, duración de soporte por release y modelo de
   precio por núcleo (cambió de nombre desde Azure Stack HCI y su cadencia es mensual).
6. **Estado de VM blindadas / HGS** y de NTLMv2: si han pasado de deprecado a retirado.
7. **Requisitos de S2D** para la versión concreta y el catálogo de hardware certificado.
8. CVE recientes de Hyper-V (escape de VM) y del stack de clúster; SLA de parcheo en
   `vulnerability-management-standards`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
