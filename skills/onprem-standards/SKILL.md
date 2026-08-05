---
name: onprem-standards
description: On-premise platform umbrella - the whole datacenter or server room as one system, and the router to the deep infra skill that owns each layer. Use when designing or reviewing a bare-metal fleet end to end, sizing hardware and rack capacity, redundant power feeds, UPS and cooling, the out-of-band management plane (BMC, IPMI, iDRAC, iLO, serial console, KVM over IP), hardware lifecycle and warranty, inventory-as-code with host naming and IPAM conventions, rebuild-from-code guarantees for every server, fleet-wide patch and end-of-life cadence, choosing a virtualization platform, or deciding which infrastructure skill a task belongs to.
---

# Estándares on-premise — skill paraguas de plataforma

Criterios verificados contra el estado del ecosistema en **agosto de 2026**. Ante cualquier
versión, flag o parámetro concreto, **verifica en la web antes de fijarlo** (sección 8).

> **Esta skill es un paraguas.** Fija los **invariantes** de una plataforma on-premise y **enruta**
> a la skill profunda de cada capa (§1.2). Si la tarea vive en una sola capa, manda la skill
> profunda; este documento manda cuando la decisión es **de plataforma** (cómo encajan las capas,
> qué se exige a todas, qué no puede quedar sin dueño).

## 1. Alcance y triggers

### 1.1 Qué decide esta skill

- **Diseño de plataforma completa**: qué capas existen, quién es dueño de cada una, cómo encajan
  cómputo, almacenamiento, red, respaldo y observabilidad en un CPD o sala propia.
- **Hardware y físico**: dimensionado y capacidad, rack, alimentación redundante, UPS,
  refrigeración, ciclo de vida y garantía del hardware.
- **Plano de gestión out-of-band**: BMC/IPMI/iDRAC/iLO, consola serie, KVM sobre IP.
- **Elección de plataforma de virtualización** y salida de VMware; topología de cluster y quórum.
- **Convenciones de flota**: inventario como código, naming, IPAM, reconstruibilidad desde cero.
- **Cadencia de parcheo y de fin de vida** de toda la flota.
- **Enrutado**: ante una tarea de infra, decidir qué skill profunda aplica (§1.2).

### 1.2 Enrutado a skills profundas

| Si la tarea es de… | Manda | Estado |
|---|---|---|
| Instrumentación, métricas, trazas, logs, alertas, dashboards | `observability-standards` | existe |
| SLO, error budget, on-call, postmortems, capacidad como práctica | `sre-practice-standards` | existe |
| Routing, VLAN, BGP, DNS, firewall, VPN, captura de tráfico | `networking-standards` | existe |
| Scripts de shell, automatización de sistema | `bash-linux-scripting-standards` | existe |
| Ansible, Terraform/OpenTofu, drift, políticas de infra | `iac-standards` | existe |
| Triaje de CVE, SLA de remediación, EOL, VEX | `vulnerability-management-standards` | existe |
| PKI interna, ACME, mTLS, cifrado en reposo, custodia de claves | `cryptography-pki-standards` | existe |
| IdP, SSO, MFA, bastión con PAM/JIT, federación | `identity-access-management-standards` | existe |
| ISO 27001/NIST CSF/ENS, SoA, evidencia de auditoría | `grc-compliance-standards` | existe |
| Laboratorio personal, self-hosting, un solo nodo, coste doméstico | `homelab-standards` | existe |
| Hardening CIS del SO, auditd, OpenSCAP/Lynis, baseline | `linux-hardening-standards` | existe |
| SELinux/AppArmor: políticas, `audit2allow`, contextos | `selinux-standards` | existe |
| Ejercicio ofensivo autorizado: RoE, pentest, red team, informe | `offensive-security-standards` | existe |
| Windows Server y Active Directory: dominio, GPO, Tier 0, Kerberos | `windows-server-ad-standards` | existe |
| Seguridad del contenedor en ejecución: seccomp, escape, Falco | `container-runtime-security-standards` | existe |
| Dato personal: minimización, retención, borrado, DPIA | `privacy-engineering-standards` | existe |
| Laboratorio de seguridad aislado, CTF, entrenamiento | `ctf-lab-standards` | existe |
| RTO/RPO, plan de continuidad, ejercicios de DR, sitio alterno | `bcdr-standards` | existe |
| Declaración del incidente, IC, comunicación, postmortem | `incident-management-standards` | existe |
| Reglas de detección, SIEM, cobertura ATT&CK, Sigma/YARA | `detection-engineering-standards` | existe |
| Compromiso de seguridad: contención, evidencia, forense | `incident-response-forensics-standards` | existe |
| systemd, usuarios, logs, paquetes, día a día del SO | `linux-administration-standards` | existe |
| Familia RHEL/Fedora: `dnf5`, `rpm-ostree`, `bootc` | `rhel-fedora-standards` | existe |
| ZFS: topología de pool, ARC, `zfs send`, scrub | `zfs-standards` | existe |
| Estrategia de copia, retención, inmutabilidad, restore | `backup-recovery-standards` | existe |
| Proxmox VE/PBS: cluster, SDN, PBS, RBAC | `proxmox-ve-standards` | existe |
| KVM/libvirt puro, `virsh`, dominios XML | `libvirt-kvm-standards` | existe |
| vSphere/ESX, vCenter, vSAN, licencias Broadcom, salida de VMware | `vmware-standards` | existe |
| Hyper-V, WSFC, S2D, Azure Local, licencias por core de Windows | `hyper-v-standards` | existe |
| Xen, XCP-ng, Xen Orchestra, XenServer heredado | `xen-standards` | existe |
| Podman, Quadlet, contenedores bajo systemd | `podman-systemd-containers-standards` | existe |
| LVM, multipath, NVMe, filesystems, tuning de I/O | `linux-storage-standards` | existe |
| Pacemaker/Corosync, fencing, quórum, recursos | `ha-clustering-standards` | existe |
| Servidor DNS, zona, DNSSEC, registros de correo | `dns-standards` | existe |
| Ruleset nftables/firewalld, política de filtrado y su gobierno | `firewall-policy-standards` | existe |
| Túneles y acceso remoto: WireGuard, IPsec, mallas | `vpn-standards` | existe |
| "No conecta / va lento": diagnóstico reactivo de red | `network-troubleshooting-standards` | existe |
| S3 y almacenamiento de objetos, Object Lock, ciclo de vida | `object-storage-standards` | existe |

**Todas las capas tienen ya dueño.** Este documento no contiene criterio provisional de ninguna:
si la tarea cae en una fila de la tabla, manda esa skill. Lo que queda aquí es lo que **no** cabe
en ninguna capa — la plataforma como conjunto — y los invariantes de §1.3.

### 1.3 Invariantes (no negociables, valen para todas las capas)

1. **Sin telemetría no hay producción.** Un host o servicio sin métricas y sin alerta accionable
   no está desplegado: está abandonado.
2. **Un backup sin restore probado no existe.** La prueba es el restore cronometrado, no el job en
   verde.
3. **HA sin fencing probado es corrupción diferida.** Antes de activar HA, se apaga un nodo.
4. **Ningún snowflake.** Todo cambio en prod nace del código y del inventario; el drift es hallazgo.
5. **Ningún dato de host de memoria.** Se consulta el inventario: IP, rol, VLAN, dueño, criticidad.
6. **Nada sin dueño ni fecha de fin de vida.** Servicio, servidor o certificado sin responsable y
   sin EOL fechado es deuda que vencerá sola.

**No aplica**: además de las capas enrutadas en §1.2 — que mandan sobre este documento en su
dominio —, ver `kubernetes-standards` (contenedores, manifiestos y cluster K8s aunque corran sobre
este hierro), `aws-standards`/`azure-standards`/`gcp-standards` (la nube; aquí el lado on-prem de un
híbrido y la conectividad hacia ellas), `data-platform-standards` (el motor de datos que corre
encima: modelado, tuning, réplicas), `cicd-standards` (la pipeline que ejecuta los cambios),
`appsec-standards` (código de aplicación), `homelab-standards` (la frontera es el **rigor exigido**,
no el tamaño: aquí producción con RTO/RPO comprometido y ventanas acordadas; allí laboratorio
personal donde el criterio es coste, ruido y consumo). `green-it-standards` (**Ola 6**: **el centro
de datos físico —energía redundante, refrigeración, densidad, ciclo de vida del hardware— es de
aquí**; **su contabilidad de huella y las obligaciones de reporte son suyas**, incluido el criterio
sobre el PUE, que **la propia norma que lo define desaconseja usar como nota global**. Consecuencia
que ambas comparten: **alargar la vida útil del equipo suele pesar más que optimizar su consumo**,
porque la huella incorporada ya está gastada).

## 2. Decisiones por defecto de plataforma

> Nota: versiones verificadas ago-2026; re-verificar en la web antes de instalar (sección 8).
> Esta tabla fija **la elección de plataforma**, no su operación fina: el detalle de cada pieza
> pertenece a la skill de §1.2 que la cubre. Las versiones se citan solo como referencia de la
> decisión; la versión vigente y su EOL los fija la skill dueña de esa capa.

| Ámbito | Por defecto | Prohibido |
|---|---|---|
| SO base servidores | **Debian 13 "trixie"** (estable desde ago-2025, soporte a 2028+LTS 2030) o **Ubuntu Server 26.04 LTS** (soporte a 2031) | Distros EOL o sin canal de security updates; instalar "testing" en prod |
| Hipervisor | **Proxmox VE** sobre KVM como plataforma gestionada; libvirt puro solo en hosts sueltos. La operación, en `proxmox-ve-standards` y `libvirt-kvm-standards` | VMware nuevo sin justificar el coste tras Broadcom; hipervisores sin soporte. Alternativas válidas con dueño propio: `vmware-standards` (estancia o salida), `hyper-v-standards` (si las licencias de Windows ya están pagadas) y `xen-standards` (XCP-ng si el equipo lo domina) |
| Respaldo | Copia **verificada con restore cronometrado**; la mecánica la fija `backup-recovery-standards` y el plan `bcdr-standards` | Backup = snapshot del hipervisor; job en verde sin restore probado |
| Filesystem datos | **ZFS** para datos que importan; el diseño del pool lo fija `zfs-standards`, el stack de bloques `linux-storage-standards` | RAID5/RAIDZ1 con discos grandes; hardware RAID debajo de ZFS; RAID0 en prod |
| Monitorización | node_exporter en **todo** host y una alerta accionable por síntoma; el stack y su diseño los fija `observability-standards` | Hosts sin telemetría ("sin telemetría no hay producción"); alertas por email sin on-call definido |
| Acceso remoto | SSH con **claves ed25519 o FIDO2 (ed25519-sk)**, bastión, MFA | Contraseñas SSH, root login, telnet, SNMP v1/v2c |
| Config management | Ansible (o equivalente) idempotente, repo versionado, ejecutado desde CI o AWX | Cambios manuales no capturados (snowflakes); scripts sueltos sin idempotencia |
| Time/DNS | NTP interno (chrony) y DNS interno redundante; ambos monitorizados | Hosts con reloj libre (rompe TLS, Kerberos, logs); un único DNS |

## 3. Estructura y convenciones

**Systemd**: el diseño de unidades, timers, journald y el día a día del SO son de
`linux-administration-standards`; su sandboxing como **control de seguridad** medido, de
`linux-hardening-standards`. Lo que esta skill exige a la flota entera: **ningún servicio propio
corre sin unidad versionada**, y la unidad se despliega desde el repo, no se escribe en el host.

**Convenciones de flota**
- Inventario como código (fuente de verdad única: hostname, IP, rol, VLAN, dueño, criticidad).
  Ningún dato de host "de memoria": se consulta el inventario.
- Naming estable por rol+ubicación+índice; IPAM sin solapamientos (RFC1918), documentado en el repo.
- Todo servidor reconstruible desde código (PXE/preseed/autoinstall/cloud-init + Ansible); la
  prueba es reinstalar uno y que quede idéntico.
- VMs con virtio + qemu-guest-agent; ballooning y CPU type coherentes por cluster (migración en vivo).

## 4. Gates de calidad obligatorios

- **Lint de IaC**: `ansible-lint`/`yamllint` (o equivalente) en CI; cambios de infra por PR/MR,
  nunca ejecución directa en prod desde el portátil.
- **Baseline de hardening auditada**: CIS Benchmark del SO aplicado vía código y verificado con
  escáner (OpenSCAP/Lynis/Wazuh SCA) con score mínimo acordado; el drift es hallazgo, no anécdota.
- **Validación pre-cambio**: `visudo -c`, `sshd -t`, `nginx -t`, `named-checkconf`… — todo
  servicio con verificador propio se valida antes de recargar. Cambios SSH/firewall con sesión
  de rescate abierta (o consola OOB) hasta confirmar acceso.
- **Smoke test post-cambio**: el playbook/handler comprueba que el servicio responde (puerto,
  health endpoint), no solo que systemd está `active`.
- **Backup verificado como gate**: job periódico de **restore real** (fichero + VM completa) con
  resultado en monitorización; un backup sin restore probado cuenta como inexistente.
- **HA probada**: failover ejercitado (apagar un nodo del cluster) en ventana acordada, mínimo
  semestral; el resultado alimenta el runbook.

## 5. Seguridad

> El **hardening del SO** (CIS, auditd, OpenSCAP/Lynis) pertenece a `linux-hardening-standards`, el
> control de acceso obligatorio a `selinux-standards` y la política de filtrado a
> `firewall-policy-standards` (§1.2). Lo de abajo **no es criterio de hardening**: es el mínimo
> exigible a **toda** la plataforma, incluido lo que ninguna de ellas cubre — el plano de gestión
> físico (BMC/IPMI) y la disciplina de flota.

**Hardening (CIS como baseline)**
- Mínimo instalado: sin servicios/puertos innecesarios; firewall de host **default-deny entrada**
  (nftables) además del de perímetro; egress filtrado en zonas sensibles.
- SSH: `PermitRootLogin no`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
  claves ed25519/FIDO2, `AllowGroups`, banner legal; acceso a prod solo vía **bastión** con
  grabación/auditoría de sesión. Actualizaciones de seguridad automáticas del propio sshd/SO.
- Cuentas: sudo nominal con logging (nada de root compartido), contraseñas locales solo de
  emergencia en gestor de secretos, credenciales de servicio con rotación.
- Kernel/plataforma: microcode al día, mitigaciones activas, SELinux/AppArmor enforcing,
  auditd con reglas mínimas útiles reenviadas al SIEM.
- Secure Boot + TPM donde el hardware lo permita; cifrado en reposo (LUKS/ZFS encryption) en
  discos con datos y en backups; claves en gestor (no en el propio host).

**Red** — el diseño de red (routing, VLAN, BGP, DNS, política de firewall) lo fija
`networking-standards`; aquí solo lo que la plataforma de servidores debe garantizar:
- Segmentación por VLANs mínimo: gestión / servicios / almacenamiento-replicación / usuarios /
  DMZ; **default-deny entre zonas**, cada flujo permitido documentado en el repo de red.
- **Plano de gestión separado y out-of-band**: IPMI/iDRAC/iLO, interfaces de gestión del
  hipervisor y switches en VLAN dedicada sin ruta desde redes de usuario; acceso solo vía
  bastión/VPN (WireGuard). BMC con firmware parcheado y credenciales únicas por host.
- Corosync/cluster y tráfico de replicación en red dedicada (latencia y aislamiento).
- 802.1X/port-security en acceso donde aplique; SNMPv3 únicamente; TLS 1.2+/mTLS en tráfico
  este-oeste de servicios internos; PKI interna con ACME (step-ca) mejor que certificados manuales.

**Mínimo privilegio operativo**
- RBAC en Proxmox/libvirt (roles por función, API tokens con scope, no `root@pam` para automatización).
- Ansible con cuentas dedicadas y sudo restringido a lo necesario; secretos en Vault/sops, jamás
  en claro en el repo.

## 6. Operabilidad

**Observabilidad**
- node_exporter + exporters específicos (zfs, smartctl, libvirt/PVE, blackbox) en todo host;
  scrape federado o Prometheus por sitio con retención larga (Thanos/Mimir solo si el volumen lo pide — KISS).
- Alertas **accionables sobre síntomas** (golden signals + disco lleno con predicción, SMART,
  degradación RAID/ZFS, backup fallido o **restore-test fallido**, certificado por caducar,
  nodo de cluster caído, NTP drift). Cada alerta enlaza runbook; alerta sin acción posible se elimina.
- Dashboards por capa (hardware / hipervisor / VM / servicio) y **SLOs con error budget** para
  los servicios que importan; postmortems sin culpa con acciones.

**HA sin SPOF** — Pacemaker/Corosync, fencing y recursos en detalle van a `ha-clustering-standards`
(§1.2); aquí la topología y la redundancia física, que son decisión de plataforma:
- Clusters de 3+ nodos (quórum real; 2 nodos solo con qdevice); **fencing/watchdog configurado y
  probado** antes de activar HA — HA sin fencing es corrupción diferida.
- Redundancia física: dual PSU en feeds distintos, bonding LACP a switches apilados/MLAG, UPS
  monitorizada con apagado ordenado probado, refrigeración vigilada.
- Storage compartido con replicación (Ceph a partir de 3-5 nodos homogéneos; ZFS replication
  para pares) — elige el más simple que cumpla el RPO, no el más potente.

**Backups y DR** — el plan de continuidad, los RTO/RPO derivados del negocio, el orden de
recuperación y los ejercicios de DR **ya son de `bcdr-standards`**; la mecánica de la copia irá a
`backup-recovery-standards` (§1.2). Aquí, el mínimo exigible a la plataforma:
- Regla **3-2-1** con al menos una copia **inmutable u offline** (PBS remoto con sync cifrado,
  S3 object-lock, o tape) — el ransomware ataca primero los backups accesibles.
- Retención por criticidad (p. ej. 7d/4w/12m), cifrado en reposo y en tránsito, **claves de
  cifrado custodiadas fuera** del sistema respaldado (backup cifrado sin clave = pérdida total).
- **RTO/RPO por servicio, por escrito**, y **ejercicios de DR programados** (mínimo anual, ideal
  semestral): restaurar el servicio crítico en hardware/sitio alterno, cronometrado, con informe.
  También config de switches/firewall y la propia infraestructura de backup.
- Runbooks de operación: arranque/parada ordenada del CPD, pérdida de nodo, pérdida de site,
  restore selectivo. Probados, versionados, con dueño.

## 7. Sostenibilidad y prohibiciones

**Cadencia de parches/upgrades** — el triaje de un CVE concreto (CVSS+EPSS+KEV, SLA, VEX) lo fija
`vulnerability-management-standards`; aquí la cadencia de la flota:
- Seguridad SO: automático (`unattended-upgrades` solo security) en tiers bajos; semanal
  orquestado con reinicio en ventana para prod. Kernel/microcode: mensual o ante CVE explotable (triaje CVSS+EPSS+KEV).
- Hipervisor/PBS: minor updates mensuales rodando por el cluster (migrate→patch→reboot→rebalance);
  majors tras leer release notes y probar en nodo/cluster de staging. No dejar morir soportes
  (PVE 8 EOL ago-2026: planifica el salto a 9.x antes, no después).
- Firmware (BIOS/BMC/NIC/discos) y switches: revisión trimestral; BMC ante cualquier CVE.
- Prometheus/Grafana: seguir línea LTS/última minor; leer breaking changes antes de major.

**PROHIBIDO**
- Cambios manuales en prod no reflejados en el código/inventario (snowflakes); drift sin corregir.
- Backups sin restore probado; una sola copia; backup en el mismo chasis/pool que el origen;
  claves de cifrado de backup guardadas solo dentro del sistema respaldado.
- SSH por contraseña, root login remoto, telnet, SNMP v1/v2c, interfaces de gestión (BMC/PVE/
  switches) expuestas a redes de usuario o a Internet.
- HA sin fencing probado; clusters de 2 nodos sin qdevice; "HA" con un único switch/PSU/UPS.
- RAID5/RAIDZ1 con discos grandes; hardware RAID bajo ZFS; pools ZFS >80% llenos sin plan.
- Desactivar SELinux/AppArmor o el firewall "para que funcione" sin diagnóstico ni revert.
- Ejecutar en prod versiones EOL (SO, hipervisor, servicios) sin plan de salida fechado.
- Alertas ruidosas mantenidas "por si acaso"; silencios permanentes sin caducidad.
- Editar unidades systemd del paquete en vez de overrides; servicios como root sin sandboxing.
- Compartir credenciales de BMC/rootIPMI entre hosts; credenciales por defecto de fábrica.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato concreto, **búscalo — no lo recuerdes**:
- Versión estable y EOL actual de: Proxmox VE/PBS (roadmap + endoflife.date), Debian/Ubuntu,
  Prometheus (línea LTS), Grafana, OpenZFS. Verificado ago-2026: PVE 9.2, PBS 4.2, Debian 13.6,
  Ubuntu 26.04 LTS, Prometheus 3.13 LTS, Grafana 13.x — pero caduca rápido.
- CIS Benchmark vigente para la versión exacta del SO antes de aplicar/auditar hardening.
- CVEs activos (con KEV/EPSS) del stack afectado antes de decidir cadencia de un parche urgente.
- Compatibilidades antes de upgrades cruzados (PVE↔PBS, kernel↔ZFS, Ceph↔PVE) en las release
  notes oficiales, y el procedimiento de upgrade oficial (pve-upgrade-checklist) — no de memoria.
- Estado del mercado si la decisión es de plataforma (licenciamiento Broadcom/VMware, madurez
  XCP-ng/alternativas) — cambia por trimestre.

Si no puedes verificar, dilo explícitamente en vez de suponer.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
