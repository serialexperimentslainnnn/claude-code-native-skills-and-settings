---
name: linux-hardening-standards
description: Linux OS hardening baselines and their measurement. Use when applying or auditing CIS Benchmarks, DISA STIG, ANSSI-BP-028 or CCN-STIC/ENS on Linux hosts, running oscap/OpenSCAP with SCAP Security Guide profiles, Lynis, Wazuh SCA, ansible-lockdown or devsec.hardening roles, or editing sshd_config, sysctl.d, audit.rules/auditd.conf, pam_faillock, faillock.conf, login.defs, sudoers, modprobe.d blacklists, fstab mount options (noexec/nosuid/nodev), SUID audits, systemd unit sandboxing (systemd-analyze security), AIDE, Secure Boot/TPM/LUKS unattended unlock, unattended-upgrades/dnf-automatic or kernel livepatching.
---

# Estándares de hardening de Linux

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **endurecer el sistema operativo Linux y demostrarlo con una medida**: elección y
aplicación de un baseline (CIS, STIG, ANSSI-BP-028, CCN-STIC/ENS), su automatización como código,
su auditoría con escáner, el score acordado y el tratamiento del drift. Cubre superficie mínima,
parámetros de kernel, cuentas/sudo/PAM, SSH, auditd, integridad y arranque medido, contención de
servicios con systemd, opciones de montaje y SUID, actualizaciones de seguridad y livepatching, e
imagen dorada endurecida.

Triggers: `oscap`, `ssg`/`scap-security-guide`, `lynis`, `cis`, `stig`, `anssi_bp28`, `ccn-stic`,
`sshd_config`, `/etc/sysctl.d/*.conf`, `/etc/audit/rules.d/*.rules`, `auditd.conf`, `faillock.conf`,
`pwquality.conf`, `login.defs`, `/etc/sudoers.d/`, `/etc/modprobe.d/*.conf`, `fstab`, `aide.conf`,
`systemd-analyze security`, `unattended-upgrades`, `dnf-automatic`, `kpatch`, "baseline",
"benchmark", "score de cumplimiento", "el hardening ha roto el servicio".

**Principio rector**: **un baseline sin medida es una opinión, y un baseline aplicado a ciegas es
una interrupción de servicio programada.** El hardening real son tres cosas simultáneas —
*aplicarlo como código*, *medirlo con un escáner* y *documentar cada excepción con dueño y motivo*.
Cualquiera de las tres que falte convierte el trabajo en teatro de cumplimiento.

**No aplica**: ver `selinux-standards` (control de acceso obligatorio en profundidad: política,
contextos, booleanos, diagnóstico de AVC, AppArmor — aquí solo se **exige** MAC en `enforcing` como
control del baseline y se mide, no se explica cómo se opera ni se escribe política),
`onprem-standards` (**paraguas de plataforma**: hardware, plano de gestión OOB/BMC, hipervisor,
topología de flota, cadencia de parcheo de la flota, invariantes de plataforma — sus invariantes de
§1.3 son inviolables y esta skill los desarrolla en la capa SO),
`bash-linux-scripting-standards` (los scripts que ejecutan cualquier cosa de aquí: `set -Eeuo
pipefail`, ShellCheck, bats), `iac-standards` (Ansible/Terraform como herramienta: estructura de
roles, Molecule, lint y CI del repo de IaC — aquí solo qué rol de hardening se elige y con qué
criterio se aplica), `vulnerability-management-standards` (triaje de CVE con CVSS/EPSS/KEV, SLA de
remediación, VEX, seguimiento de EOL — **ellos priorizan el parche, tú endureces para que el parche
importe menos**), `grc-compliance-standards` (ENS/ISO 27001/NIST CSF como marco, SoA, aceptación de
riesgo y evidencia de auditoría — aquí el **control técnico y su prueba**, que es lo que ellos
consumen como evidencia), `networking-standards` (diseño de red: VLAN, routing, política de firewall
entre zonas, DNS, VPN; **el firewall *de host* es de esta skill** — `nftables`/`firewalld` en el
propio servidor como control del baseline: default-deny de entrada, egress filtrado, ruleset
versionado —, mientras que qué flujo se permite entre zonas y por qué lo decide la topología de
red), `cryptography-pki-standards` (elección de algoritmos y su justificación criptográfica, gestión
de claves LUKS, emisión de certificados SSH y PKI interna — aquí solo la **configuración** que los
consume), `identity-access-management-standards` (IdP, SSO, MFA, elevación JIT/PAM y el bastión como
servicio — aquí la configuración local: `sudoers`, `pam_faillock`, `AllowGroups`),
`kubernetes-standards` (hardening declarativo del Pod, `securityContext`, admisión),
`observability-standards` (dónde y cómo se recogen, retienen y correlacionan los logs de auditd),
`appsec-standards` (vulnerabilidades del código de aplicación), `homelab-standards` (laboratorio
personal: la frontera es el rigor exigido, no el tamaño), `offensive-security-standards`
(verificación ofensiva del endurecimiento, con alcance y autorización), `ctf-lab-standards`
(laboratorio de entrenamiento desechable), `developer-workstation-standards` (**Ola 6** — frontera
que colisiona de verdad: **aquí el endurecimiento del servidor y de la flota** —baseline CIS/STIG,
`sysctl`, auditd, sudoers, SELinux/AppArmor, aplicado por configuración centralizada—; **allí el
puesto de trabajo**, cuyo modelo de amenaza es distinto: cifrado de disco, claves en hardware,
extensiones del editor y `curl | sh` como cadena de suministro, y credenciales de desarrollo. **Un
baseline de servidor aplicado a una estación de desarrollo no la endurece, la inutiliza**).

Planificadas — hasta que existan, esta skill es criterio provisional en su solapa:
`container-runtime-security-standards` (**Ola 1**: seccomp, eBPF/Falco, detección de escape de
contenedor y seguridad del runtime), `detection-engineering-standards` (**Ola 1**: qué se hace con
la telemetría de auditd — reglas Sigma, casos de uso, SIEM), `bcdr-standards` (**Ola 1**: RTO/RPO y
continuidad), `linux-administration-standards` (**Ola 2**: día a día del SO, systemd, paquetes,
usuarios sin ángulo de seguridad), `rhel-fedora-standards` (**Ola 2**: particularidades de la
familia RHEL — `dnf5`, `rpm-ostree`, `bootc`, image builder).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Los datos son de
> **agosto 2026** y el contenido de baseline (CIS, SSG) se revisa cada pocas semanas.

| Ámbito | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Baseline de referencia | **CIS Benchmark de la versión exacta de la distro**, Level 1 Server como suelo, Level 2 en hosts que traten datos sensibles | Es el único con contenido automatizado, mapeo a controles y actualización continua. **El número de versión va por versión de distro**: "el CIS de Linux" no existe. Verificado ago-2026 en cisecurity.org: **RHEL 10 v1.0.1**, **RHEL 9 v2.0.0**, **RHEL 8 v4.0.0**, **Ubuntu 24.04 LTS v2.0.0**, **Ubuntu 22.04 LTS v3.0.0**, **Debian 13 v1.0.0**, **Debian 12 v2.0.0**; variantes STIG-flavored: RHEL 9 STIG v1.0.0, RHEL 8 STIG v2.0.0, Ubuntu 24.04 STIG v1.0.0 |
| **Hueco de cobertura a vigilar** | **No existe CIS Benchmark para Ubuntu 26.04 LTS** (verificado ago-2026) | Si estandarizas en 26.04, tu baseline **no puede ser CIS todavía**: usa ANSSI-BP-028 o `devsec.hardening` y planifica la migración cuando CIS publique. Extrapolar el benchmark de 24.04 a 26.04 sin revisarlo regla a regla está prohibido (§7) |
| Perfil (L1/L2, Server/Workstation) | **Server** en servidores, **Workstation** solo en puestos; L1 = "no debería romper nada", L2 = **extiende** L1 asumiendo impacto funcional | Cuatro perfiles por benchmark (L1/L2 × Server/Workstation) y **L2 no es autónomo: incluye L1**. Aplicar el perfil Workstation a un servidor, o L2 sin plan de excepciones, es la causa número uno de "el hardening rompió el servicio" |
| Baseline en sector público español | **CCN-STIC 610-25 "Perfilado de seguridad para distribuciones Linux (servidor o cliente)"** sobre el ENS (**RD 311/2022**), categoría BÁSICA/MEDIA/ALTA | Verificado ago-2026: la guía unificada 610-25 (elaborada sobre Rocky Linux 10) define el **PCTE** de Linux con **14 medidas** aplicables técnicamente y perfiles **ENS / DIFUSIÓN LIMITADA / INFORMACIÓN CLASIFICADA**, con anexos por distro (**A** Rocky, **B** Arch, **E** Debian; también anunciados Ubuntu y Fedora). Sustituye en la práctica a la serie por producto `610Axx`. La serie 600 es **incremental**: guía del SO + guía de cada servicio. SSG trae un perfil `ens` |
| Baseline en defensa/gobierno aliado | **DISA STIG** cuando el cliente lo exija por contrato | Verificado ago-2026 (fuentes de terceros, ver §8): **RHEL 9 V2R8**, **RHEL 10 V1R1**, **Ubuntu 24.04 LTS V1R5** (13-may-2026). DISA publica trimestralmente: confirma siempre en `public.cyber.mil` |
| Baseline con criterio técnico propio | **ANSSI-BP-028 v2.0** (oct-2022), niveles `minimal` → `intermediary` → `enhanced` → `high` | Los cuatro niveles son **acumulativos** y están implementados como perfiles SCAP desde SSG **0.1.73**. Es el baseline mejor razonado para elegir *cuánto* endurecer, no solo *qué*. Ojo: `R1`, `R2`… son **identificadores de regla** dentro del documento, no niveles |
| Contenido de auditoría | **SCAP Security Guide / ComplianceAsCode v0.1.81** (1-jun-2026) | Fuente única de perfiles `cis_server_l1/l2`, `cis_workstation_l1/l2`, `stig`, `anssi_bp28_{minimal,intermediary,enhanced,high}`, `pci-dss`, `ospp`, `ens`, `e8`, `hipaa`, `cui`. Cubre RHEL 8/9/10, Ubuntu, **Debian 13**, SLE. Red Hat entrega las versiones CIS vigentes en SSG ≥ 0.1.80. Cambio relevante: las reglas de PAM usan **authselect** — no se aplican si el stack PAM se editó por otros medios |
| Escáner de cumplimiento | **OpenSCAP ≥ 1.4.4** (NEWS 04-mar-2026, publicado 09-abr-2026) — `oscap xccdf eval` | Es la medida formal y auditable (XCCDF/OVAL, ARF). Línea 1.4.x: `oscap xccdf generate fix --fix-type kickstart` (instalación desatendida ya endurecida), `oscap-im` para imágenes **bootc/Image Mode**, `autotailor` con tailorings JSON multi-perfil, `oscap info` lista reglas y variables del perfil, `--skip-valid` **eliminado** → `--skip-validation`. **Aviso**: las distros van muy por detrás (Ubuntu 24.04 empaqueta **1.3.9**) — usa el binario del vendor de tu SO y no asumas features de 1.4.x |
| Escáner complementario | **Lynis 3.1.7** (25-jun-2026; CISOfy, mantenida con cadencia lenta ~8 meses) | Sin agente y sin SCAP: señal rápida y útil en hosts fuera del alcance de SSG. **Las distros empaquetan versiones antiguas**: usa el repo de CISOfy o el tarball, y `lynis --check-update`. Su "hardening index" **no es un score de cumplimiento**: no lo mezcles con el de OpenSCAP |
| Escáner continuo de flota | **Wazuh 4.14.x** (4.14.7, 29-jul-2026) con su módulo **SCA** (políticas YAML alineadas a CIS, extensibles) | OpenSCAP mide bien y puntualmente; el drift se detecta en continuo. Los dos, para cosas distintas. Wazuh 5.0 en desarrollo cambia el ciclo de sincronización de SCA/FIM: no planifiques sobre él hasta su GA |
| Aplicación del baseline | **Rol Ansible mantenido**, no scripts propios | Verificado ago-2026, ambos **activos**: **ansible-lockdown** (RHEL9-CIS **v2.2.0**, 27-feb-2026, firmada GPG; UBUNTU24-CIS **v1.6.0**, 5-may-2026; ~93 repos con commits en jul-ago 2026; patrón `-CIS`/`-STIG` = remediación y `-Audit` = verificación con GOSS; MIT) y **devsec.hardening 10.6.0** (26-may-2026; roles `os_hardening`, `ssh_hardening`, `nginx_hardening`, `mysql_hardening`; Apache-2.0; ya soporta **Ubuntu 26.04** y Fedora 42-44) |
| Elección entre ambos | **ansible-lockdown** si el requisito es *cumplir un benchmark numerado y demostrarlo*; **devsec.hardening** si es *un baseline sensato multi-distro sin numeración* (y hoy, si tu SO es **Ubuntu 26.04**, que aún no tiene CIS) | No los mezcles sobre el mismo host: se pisan en `sysctl.d`, `sshd_config` y `login.defs`. Uno, y encima tus excepciones. Nota operativa: **los roles de ansible-lockdown no soportan check mode** — son remediación, no auditoría |
| Escribirlo a mano | **Solo** para lo que el rol no cubre o para las excepciones | Un baseline propio desde cero envejece: nadie lo reevalúa cuando sale la nueva versión del benchmark. Adoptas contenido mantenido y añades tu delta |
| MAC | **SELinux o AppArmor en `enforcing`, siempre** — control del baseline, no opción | Cómo se opera, diagnostica y escribe política: `selinux-standards`. Verificado ago-2026: **SLES 16.0 (GA 4-nov-2025) elimina AppArmor y arranca con SELinux enforcing** (+400 módulos); openSUSE Tumbleweed desde el snapshot 20250211 y Leap 16 igual |
| Firewall de host | **nftables** (directo o vía `firewalld`), **default-deny de entrada**, ruleset versionado y aplicado por código | systemd v259 ya elimina iptables/libiptc de `networkd`/`nspawn`: iptables-legacy es deuda. El egress filtrado es obligatorio en zonas sensibles |
| Actualizaciones de seguridad | **Automáticas y acotadas a seguridad**: `unattended-upgrades` con orígenes `-security`, o `dnf-automatic` con `upgrade_type = security` + `apply_updates = yes`; orquestadas en ventana para prod | El punto de decisión real **no es instalar, es reiniciar**: kernel, glibc y OpenSSL no surten efecto hasta el reinicio. Verificación obligatoria antes de confiar: `unattended-upgrades --dry-run --debug` / `dnf-automatic /etc/dnf/automatic.conf`, más `journalctl -u` y `/var/run/reboot-required` |
| Livepatching | **Solo si el RTO no admite el reinicio**, y **nunca como sustituto del reinicio** | Verificado ago-2026: **kpatch** (RHEL 9 desde 9.0, **RHEL 10 desde 10.2**; kernels elegibles designados **trimestralmente**, parcheados hasta 1 año; con EUS 2 años y con Update Services for SAP 4; obliga a actualizar kernel y reiniciar **≥2 veces al año**; **no se soporta revertir un live patch sin reiniciar**; solo RPMs de repos Red Hat). **Canonical Livepatch** (hasta 10 años con Ubuntu Pro, +5 con Legacy; parches por kernel solo durante **9-13 meses** desde su release; **incompatible con kernels FIPS y real-time**; **ARM64 llega con 26.04**). **KernelCare/TuxCare** (RHEL, Oracle, Rocky, Alma, CentOS, Ubuntu, Debian — **SLES no figura**; incompatible con Canonical Livepatch en el mismo host). Trata las cifras de cobertura de los comparativos de vendor como marketing |
| auditd | **audit-userspace 4.x** con reglas mínimas útiles en `/etc/audit/rules.d/` | Verificado ago-2026: desde **audit-4.0 las reglas se cargan por `audit-rules.service`**; 4.1.0 añadió `libauplugin`; 4.1.2 aceleró mucho `ausearch`/`aureport` y movió `audit.pid`/estado a `--runstatedir` (`/run`) — **si tienes política MAC propia sobre esas rutas, actualízala**. `report_interval` (≥4.0.5) vuelca métricas a `/run/audit/auditd.state` |
| Integridad de ficheros | **AIDE ≥ 0.19.2** (14-ago-2025) con base de datos **fuera del host**; FIM del agente (Wazuh) donde ya haya agente | **0.19.2 es la versión mínima segura** (CVE-2025-54409: null-pointer deref → DoS local en 0.13–0.19.1). Sin releases en 2026: proyecto de cadencia lenta. Una base de AIDE que vive en el host que audita no vale nada tras un compromiso |
| Arranque | **Secure Boot + TPM 2.0** donde el hardware lo permita, kernel y módulos firmados, `lockdown` en `integrity` como mínimo | systemd v259 **eliminó TPM 1.2** de `systemd-boot`/`systemd-stub`. El LSM `lockdown` **estuvo sin mantenedor desde 5.4 hasta Linux 6.17**, cuando volvió a tener mantenimiento activo: antes de 6.17 trátalo como control estable pero no evolutivo |
| Cifrado en reposo | **LUKS2**; desbloqueo desatendido con **Clevis/Tang** en datacenter y **`systemd-cryptenroll` con TPM2** en equipos con Secure Boot | Verificado ago-2026: TPM2 en `systemd-cryptsetup` requiere systemd ≥ 251 y kernel ≥ 5.17 para políticas de PCR; **sellar a PCR 0/1/2/4 se rompe con cada actualización de kernel/initramfs/GRUB** y **PCR 7 en solitario es atacable** (initrd sustituible sin cambiar PCRs) → usa **políticas de PCR firmadas (PCR 11 + `--tpm2-signature`)** o PIN. El rol upstream `linux-system-roles/nbde_client` es **Clevis-céntrico y no soporta TPM2**. Elección de algoritmos y custodia de claves: `cryptography-pki-standards` |

## 3. Estructura y convenciones

### 3.1 El baseline se aplica con excepciones documentadas, nunca a ciegas

Hay controles de CIS que **rompen servicios reales** — `noexec` en `/var` o `/tmp` frente a
instaladores y runtimes que ejecutan desde ahí, `nodev` en rutas que un contenedor necesita,
`umask 027` frente a servicios que comparten grupo, restringir user namespaces sin privilegios
frente a Podman rootless o navegadores, restricciones de `cron`/`at`, algoritmos SSH que dejan fuera
a clientes antiguos, `pam_pwquality` frente a cuentas de servicio. El baseline **no se aplica al
100 %**: se aplica al 100 % *menos un conjunto de excepciones explícitas*.

Formato obligatorio de excepción, en el repo, junto al código que la implementa:

| Campo | Contenido |
|---|---|
| Regla | ID exacto del benchmark (`xccdf_org.ssgproject.content_rule_…` o número CIS) |
| Alcance | Qué hosts/grupo, no "producción" |
| Motivo | El fallo concreto observado, con evidencia (log, traza, incidencia) |
| Compensación | Qué control alternativo cubre el riesgo |
| Dueño y caducidad | Persona y fecha de reevaluación. **Sin fecha, no es excepción: es abandono** |

La excepción se implementa como **tailoring del perfil** (`autotailor`, ficheros de tailoring
XCCDF/JSON) para que el escáner **no la cuente como fallo**. Una excepción que sigue apareciendo
como hallazgo en cada informe entrena al equipo a ignorar los informes.

### 3.2 Orden de trabajo (no negociable)

1. **Medir antes de tocar**: `oscap xccdf eval` con el perfil objetivo sobre el host tal cual está.
   Ese informe es la línea base y el argumento de la conversación.
2. **Aplicar en no-producción** el rol completo, sin excepciones, y **romper cosas ahí**.
3. **Catalogar lo roto** → excepciones (§3.1) + tailoring.
4. **Aplicar en producción por olas**, con smoke test funcional después de cada ola (§4).
5. **Re-medir y fijar el score acordado** como umbral de CI.
6. **Vigilar el drift** en continuo; cada desviación es un hallazgo con dueño.

Nunca: aplicar el rol completo directamente a producción "porque es un baseline estándar".

### 3.3 Superficie mínima

- **Paquetes**: instalación mínima como punto de partida (`Minimal Install`, `debootstrap`,
  `--no-install-recommends`). Todo lo que se instala después está justificado. Sin compiladores,
  sin clientes de red innecesarios (`telnet`, `ftp`, `rsh`, `tftp`), sin servidores X en servidores.
- **Servicios y puertos**: `systemctl list-units --type=service --state=running` y `ss -lntup`
  contra la lista esperada del rol. Un puerto a la escucha no declarado es un hallazgo.
- **Módulos de kernel innecesarios**, con blacklist real (`install <mod> /bin/true` en
  `/etc/modprobe.d/`, no solo `blacklist`, que no impide la carga bajo demanda): filesystems
  exóticos (`cramfs`, `freevxfs`, `jffs2`, `hfs`, `hfsplus`, `udf`, `squashfs` si no se usa),
  protocolos de red inusuales (`dccp`, `sctp`, `rds`, `tipc`), `usb-storage` en servidores,
  `firewire-core`, `bluetooth`. Verificar que el blacklisting sobrevive al `initramfs`.
- **Cuentas**: sin cuentas de sistema con shell válido; sin cuentas huérfanas; `nologin`
  explícito. Sin cuentas locales compartidas — todo acceso es nominal.

### 3.4 Kernel y parámetros

Nada de "una lista de `sysctl` copiada de un blog". Cada parámetro fijado se justifica y se agrupa
en `/etc/sysctl.d/` por propósito, con el fichero versionado (ojo: en **Debian 13**
`/etc/sysctl.conf` ya no se honra — hay que escribir en `sysctl.d`, cosa que `devsec.hardening`
corrigió en su línea 10.4).

Ejes, con el criterio de por qué:

- **Red**: anti-spoofing (`rp_filter`), ignorar redirects ICMP y source routing, no reenviar
  paquetes salvo que el host sea router, `tcp_syncookies`, y `accept_ra`/`disable_ipv6` **solo si
  IPv6 realmente no se usa** — desactivar IPv6 "por si acaso" rompe servicios modernos y no
  endurece nada. La política de filtrado en sí es del firewall, no de `sysctl`.
- **Exposición de información del kernel**: `kernel.kptr_restrict=2`, `kernel.dmesg_restrict=1`,
  `kernel.perf_event_paranoid` alto en hosts sin perfilado, `fs.protected_hardlinks`/`_symlinks`/
  `_fifos`/`_regular`. Coste operativo real: dificultan el diagnóstico — decídelo, no lo heredes.
- **Restricción de trazado y de vuelcos**: `kernel.yama.ptrace_scope` ≥ 1 (2 o 3 en hosts que no
  depuran nada; `devsec.hardening` 10.6.0 lo endureció explícitamente en may-2026),
  `fs.suid_dumpable=0`, core dumps deshabilitados o dirigidos a ruta controlada (un core dump puede
  contener claves en memoria).
- **Cadena de arranque y de código**: **module signing** obligatorio, `kernel.modules_disabled=1`
  al final del arranque en hosts de función fija, `kexec_load_disabled=1`, y **`lockdown`** —
  `integrity` como suelo (bloquea la modificación del kernel en ejecución y la carga de módulos sin
  firmar), `confidentiality` en hosts que traten secretos, **midiendo antes** qué se rompe
  (perfilado, depuración, hibernación, algunos drivers propietarios). Las transiciones de
  `lockdown` son **unidireccionales**: solo se puede endurecer, nunca relajar en caliente. En
  EFI x86/arm64 muchas distros lo activan solas con Secure Boot. Limitación declarada por su autor:
  protege la **integridad del kernel, no del sistema completo** — complétalo con dm-verity y MAC.
- **Espacios de nombres sin privilegios**: en Ubuntu 24.04+/26.04 la restricción va por AppArmor
  (`kernel.apparmor_restrict_unprivileged_userns=1` por defecto). Antes de desactivarlo por una app
  que "no arranca", entiende qué la usa: es superficie de escalada histórica, y Qualys publicó en
  mar-2025 **tres bypasses** de esa restricción (vía `aa-exec` a perfiles permisivos y vía el perfil
  por defecto de busybox). En **RHEL 10** la configuración por defecto concede user namespaces a
  usuarios no privilegiados, lo que amplió el impacto de fallos de kernel recientes: revísalo.
- **Mitigaciones de CPU**: **activas por defecto, siempre**. Si el coste es inaceptable, se mide con
  el workload real, se documenta la pérdida, se acota a hosts concretos y se aprueba con el dueño
  del riesgo. `mitigations=off` en un host multiinquilino o que ejecute código ajeno está prohibido
  (§7). Referencia verificada del coste real: **VMSCAPE (CVE-2025-40300**, sept-2025; fuga
  guest→hipervisor en todas las generaciones AMD Zen 1-5 y Coffee Lake) se mitiga con IBPB condicional
  tras VMexit (`vmscape=`, `vmscape=force` con guests no confiables) a un coste de **~10 % con
  dispositivo emulado y ~1 % en Zen 4** — ese es el orden de magnitud de la conversación, no "las
  mitigaciones cuestan la mitad del rendimiento". Patrón recurrente: **el parche de kernel solo no
  basta, hace falta microcódigo/UEFI en paralelo**. Estado real: `lscpu` y
  `/sys/devices/system/cpu/vulnerabilities/*`.

### 3.5 Cuentas, sudo y PAM

- **sudo nominal y acotado**: reglas por grupo, con comandos explícitos y rutas absolutas, en
  ficheros de `/etc/sudoers.d/` versionados y validados con `visudo -c`. `Defaults logfile` o
  `log_output` para los comandos elevados. **Prohibido `NOPASSWD: ALL`** (§7); `NOPASSWD` acotado a
  un comando concreto para automatización es aceptable **si** el comando no permite escapar a shell
  (cuidado con `vi`, `less`, `find -exec`, `tar --to-command`, gestores de paquetes).
- **`sudo` es superficie de ataque de primer nivel, no infraestructura inerte**: CVE-2025-32462 y
  **CVE-2025-32463** (escalada a root vía `--chroot`, CVSS 9.3, **en el catálogo CISA KEV desde el
  29-sep-2025**, y **explotable sin estar en sudoers**) se corrigieron en **sudo 1.9.17p1**. Upstream
  ha anunciado que la opción chroot será eliminada. Verifica la versión instalada, y prohíbe el uso
  de `--chroot`/`-R` en tus reglas.
- **`pam_faillock`** configurado en `/etc/security/faillock.conf` (bloqueo tras N fallos, ventana,
  `unlock_time` distinto de cero salvo requisito explícito, y **excluir root del bloqueo permanente**
  para no autoexcluirse). Verifica el desbloqueo con `faillock --user X --reset` antes de darlo por
  bueno. En la familia RHEL, **el stack PAM se gestiona con `authselect`**: editar los ficheros a
  mano hace que las reglas de SSG no apliquen y que el siguiente `authselect apply-changes` revierta
  tu cambio.
- **`pam_namespace` desactivado salvo uso real**: CVE-2025-6020 y su fix completo CVE-2025-8941
  (CVSS 7.8, con exploit público) permiten escalada a root vía symlinks sobre rutas controladas por
  el usuario. Corregido en linux-pam 1.7.1. Si lo necesitas, monta con `nosymfollow` y no lo apuntes
  a rutas escribibles por el usuario.
- **Política de contraseñas contrastada, no barroca**: la evidencia moderna (NIST SP 800-63B) manda
  **longitud mínima alta + comprobación contra listas de contraseñas comprometidas**, y desaconseja
  la caducidad periódica obligatoria y las reglas de composición. El baseline CIS todavía pide
  caducidad y complejidad: si tu marco te obliga, cúmplelo; si tienes margen, documenta la
  desviación *hacia la práctica mejor* con el mismo rigor que cualquier otra excepción. Comprobación
  contra listas: `pam_pwquality` con diccionario o fuente de credenciales filtradas. Hashing local:
  yescrypt o SHA-512 con rondas altas según distro.
- **Límites**: `/etc/security/limits.d/` con `nproc`/`nofile`/`core` acotados para contener
  fork-bombs y agotamiento de descriptores; complementa, no sustituye, los límites de systemd.
- **`umask 027`** (o `077` en hosts sensibles) en `/etc/login.defs` y en el perfil de shell, con
  cuidado en servicios que comparten grupo. `UMask=` en la unidad systemd para el servicio.
- **Sesiones**: `TMOUT`/`ClientAliveInterval` para sesiones inactivas, banner legal
  (`/etc/issue.net`) — el banner es control de cumplimiento, no de seguridad: trátalo como tal.

### 3.6 SSH endurecido

- **Base**: `PermitRootLogin no`, `PasswordAuthentication no`, `KbdInteractiveAuthentication no`,
  `PermitEmptyPasswords no`, `AllowGroups <grupo>` (allowlist explícita, no denylist),
  `X11Forwarding no`, `MaxAuthTries` bajo, `LogLevel VERBOSE` (registra la huella de la clave usada,
  que es lo que necesitarás en la investigación).
- **Post-cuántico — verificado ago-2026** (OpenSSH **10.4**, 06-jul-2026): **9.9** añadió
  `mlkem768x25519-sha256`; **10.0** (abr-2025) lo hizo **KEX por defecto**; **10.1** (oct-2025)
  hace que **el cliente `ssh(1)` avise** cuando el servidor no ofrece KEX post-cuántico (*"WARNING:
  connection is not using a post-quantum key exchange algorithm"*) y añade **`WarnWeakCrypto`** en
  `ssh_config` para silenciarlo. El híbrido anterior `sntrup761x25519-sha512@openssh.com` (por
  defecto desde 9.0) sigue soportado y sirve para interoperar con servidores 9.0-9.8. **Criterio**:
  el servidor debe negociar `mlkem768x25519-sha256`; **silenciar el aviso en el cliente en vez de
  actualizar el servidor está prohibido** (§7). OpenSSH **no** tiene aún firmas post-cuánticas para
  claves de identidad: el aviso es solo de KEX.
- **Algoritmos**: no copies listas de `KexAlgorithms`/`Ciphers`/`MACs` de hace tres años — una lista
  fijada a mano envejece hacia *más débil* que el default del binario actual (desde 10.0 el orden por
  defecto de cifrados es ChaCha20-Poly1305 → AES-GCM → AES-CTR: **una lista antigua deshace esa
  mejora**). Parte del default de la versión instalada y **quita**, no reconstruyas. Verifica lo que
  negocia de verdad (`ssh -Q kex`, `sshd -T`). **DSA fue eliminado por completo en OpenSSH 10.0**;
  RSA solo con SHA-2 y ≥ 3072 bits si no hay más remedio; por defecto **ed25519** o **ed25519-sk**
  (FIDO2). Nota de migración: 10.x cambió `Match` a *quoting* estilo shell — **puede romper configs
  existentes**, y hay una corrección de seguridad en `DisableForwarding`, que no deshabilitaba X11 ni
  agent forwarding como documentaba.
- **Certificados SSH de vida corta > `authorized_keys`**: una CA SSH interna con certificados de
  horas elimina el problema de revocación y de claves huérfanas repartidas por la flota
  (`TrustedUserCAKeys`, `principals`, `HostCertificate` para autenticar también al servidor y matar
  el TOFU). La emisión, la CA y su custodia: `cryptography-pki-standards`; la elevación JIT y el
  bastión como servicio: `identity-access-management-standards`. Aquí: **el host solo confía en la
  CA y en `AllowGroups`**.
- **Acceso solo vía bastión**, con `Match Address` restringiendo el origen y sin acceso directo
  desde redes de usuario. Cualquier cambio en `sshd_config` se valida con `sshd -t` **y se recarga
  con una segunda sesión abierta** (§4).

### 3.7 auditd

- **Reglas mínimas útiles**. Una lista de 400 reglas copiada de un repo genérico produce gigabytes
  al día, satura el disco, degrada el host y **no la lee nadie**: es pérdida de señal disfrazada de
  cumplimiento. La inteligencia de detección (TTP, firmas de herramienta) vive en el SIEM como
  reglas Sigma, no en el ruleset de auditd — ver `detection-engineering-standards` (Ola 1).
- Núcleo defendible: cambios en `/etc/passwd`, `/etc/shadow`, `/etc/group`, `sudoers` y
  `sudoers.d`; ejecución de binarios SUID/SGID relevantes; `execve` de shells por cuentas de
  servicio; carga/descarga de módulos; cambios de hora; montajes; modificación de la configuración
  del propio auditd y de SSH; accesos denegados (`EACCES`/`EPERM`) en rutas críticas. Cada regla con
  `-k <clave>` para poder buscarla y correlacionarla.
- **Sintaxis y despliegue**: las reglas de syscall requieren `-a always,exit` (un `-S execve` suelto
  no genera nada); las reglas de usuario humano usan `-F auid>=<UID_MIN> -F auid!=unset`
  sustituyendo `UID_MIN` de `/etc/login.defs` **en tiempo de despliegue** (auditd no tiene
  variables); `-e 2` al final para inmutabilizar el ruleset **solo cuando el conjunto esté estable**
  (exige reinicio para cambiarlo). Verificación: `augenrules --check`, `augenrules --load`,
  `auditctl -l`, `auditctl -s`.
- **Operación**: en la familia RHEL, `systemctl reload auditd` **no funciona** (`service auditd
  restart` o `augenrules --load`); desde audit-4.0 las reglas se cargan vía `audit-rules.service`.
- **Integridad y retención**: `/var/log/audit` en **partición propia** (que auditd llene el disco
  raíz es una caída, y `space_left_action`/`admin_space_left_action` con `SUSPEND` **dejan de
  auditar en silencio** — decide entre disponibilidad y auditoría, y documéntalo). Reenvío al SIEM
  con `audisp-syslog`/`audisp-remote` desde `/etc/audit/plugins.d/` (en Debian/Ubuntu requiere
  `audispd-plugins`). **El log local es prueba débil**: un atacante con root lo edita; la copia
  remota, con reloj sincronizado, es la que vale. Dónde va y cuánto se retiene, en
  `observability-standards`.

### 3.8 Integridad y arranque

- **Secure Boot habilitado** y kernel + módulos firmados (con MOK propia si compilas módulos fuera
  de árbol). Sin Secure Boot, `lockdown` no es una frontera real.
- **TPM 2.0 con medición**: los PCRs miden la cadena de arranque; útil solo si algo *comprueba* la
  medida — sellado de claves LUKS a PCRs o atestación remota. Un TPM que nadie consulta es un chip
  caro. Cuidado con la fragilidad de PCRs y con el ataque a PCR 7 en solitario (§2).
- **LUKS2** en discos con datos, **y en los backups**. Desatendido: **Clevis/Tang** (dos o más
  servidores Tang para no crear SPOF; `sss` con umbral — **Tang no almacena secretos**) o TPM2 con
  política firmada. Regla dura: **si el host no arranca sin un humano, no está en producción**.
- **AIDE** (o FIM del agente) con la base de datos firmada y almacenada fuera del host,
  inicializada **después** de aplicar el baseline y **reinicializada tras cada cambio aprobado** —
  si no, todo el mundo aprende a ignorar sus informes.

### 3.9 Contención de servicios con systemd (control de hardening de primera línea)

El sandboxing de systemd es un control de contención real y **complementario al MAC**: MAC define
qué puede tocar un dominio según su etiqueta; systemd recorta lo que el proceso *puede pedir* al
kernel (namespaces, capabilities, syscalls, vistas de FS). Se aplican **los dos**;
`systemd-analyze security` **ignora explícitamente SELinux y AppArmor**, así que un score bueno no
sustituye a `enforcing` ni al revés.

Toda unidad propia (y toda unidad de terceros que exponga red) lleva, como suelo:
`User=` dedicado o `DynamicUser=yes`, `NoNewPrivileges=yes`, `ProtectSystem=strict`,
`ProtectHome=yes`, `PrivateTmp=yes`, `PrivateDevices=yes`, `ProtectKernelTunables=yes`,
`ProtectKernelModules=yes`, `ProtectKernelLogs=yes`, `ProtectControlGroups=yes`,
`ProtectClock=yes`, `ProtectHostname=yes`, `ProtectProc=invisible`, `RestrictSUIDSGID=yes`,
`RestrictRealtime=yes`, `RestrictNamespaces=yes`, `LockPersonality=yes`,
`CapabilityBoundingSet=` (vacío, y solo lo imprescindible añadido),
`SystemCallFilter=@system-service` + `SystemCallArchitectures=native`,
`RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX`, `ReadWritePaths=` explícitos,
`IPAddressDeny=any` + `IPAddressAllow=` cuando el servicio hable con destinos conocidos.

- **Umbral**: `systemd-analyze security <unidad>` da un *exposure level* de 0.0 a 10.0, con
  predicados (`UNSAFE` / `EXPOSED` / `MEDIUM` / `OK`). Objetivo **< 4.0** en servicios propios;
  **medir y registrar** el valor antes/después. Desde systemd v250 se puede pasar una **política
  JSON** con los requisitos propios y comparar unidades contra ella: eso es lo que se mete en CI, no
  un número recordado. Caveat oficial: no analiza el hardening interno del programa, y hay servicios
  (`sshd`, `crond`, `atd`) que puntúan mal **por diseño** — no los "arregles" a ciegas.
- **Overrides en `/etc/systemd/system/<unidad>.d/override.conf`**, jamás editando la unidad del
  paquete (§7). Notas de versión relevantes: **v259** (17-dic-2025) pasa `libselinux`, `pam`,
  `audit`, `libseccomp` a `dlopen` y deja de enlazar `libcap` — verifica que tu imagen mínima las
  incluye antes de asumir que el sandbox está activo; **v260** (17-mar-2026) **elimina el soporte de
  scripts SysV** (`systemd-sysv-generator`, `rc-local.service`); **v261** es la línea actual.
- `MemoryDenyWriteExecute=yes` solo donde el runtime lo tolere (rompe JIT: JVM, .NET, V8). Es un
  buen ejemplo de control que **se prueba, no se presupone**.

### 3.10 Filesystem, montajes y SUID

- **Particionado**: `/var`, `/var/log`, `/var/log/audit`, `/tmp` y `/home` separados — el objetivo
  real es que **ningún consumidor de disco pueda tumbar el host** ni impedir el logging.
- **Opciones de montaje**: `nodev` en todo lo que no sea `/` o `/dev`; `nosuid` en `/tmp`,
  `/var/tmp`, `/home`, `/dev/shm` y montajes de red; `noexec` en `/tmp`, `/var/tmp` y `/dev/shm`
  **midiendo antes** (instaladores, `pip`, gestores de paquetes y algunos runtimes ejecutan desde
  `/tmp`; la excepción, si la hay, es `TMPDIR` propio, no quitar `noexec`).
- **Binarios SUID/SGID**: inventario explícito, comparado en cada auditoría
  (`find / -xdev -type f \( -perm -4000 -o -perm -2000 \)`). Un SUID nuevo no declarado es hallazgo
  de seguridad, no ruido. Retira `setuid` de los que no se usen. Preferir **capabilities acotadas** o
  systemd (`AmbientCapabilities=`) sobre SUID nuevo.
- **`/boot`** montado con `nodev,nosuid,noexec` y contraseña de GRUB para la edición de la línea de
  arranque en hosts con acceso físico no controlado (útil justamente porque `selinux=0` o
  `init=/bin/bash` se escriben ahí).

### 3.11 Imagen dorada

- El hardening se aplica **en la imagen**, no host por host: `oscap xccdf generate fix --fix-type
  kickstart` u `oscap-im` para imágenes **bootc/Image Mode** (OpenSCAP 1.4.x), o el remediation
  Ansible del perfil, integrados en el build (image builder, Packer).
- La imagen se **verifica con el mismo escáner y el mismo perfil** que la flota, en el pipeline, y
  se publica **firmada y versionada**. *Build once, promote the same artifact*: la imagen que se
  audita es exactamente la que se despliega.
- La imagen incorpora *cero secretos*: sin claves SSH de host preembebidas (regenerar en primer
  arranque), sin credenciales, sin `authorized_keys` del constructor.

## 4. Gates de calidad (rompen el build o el despliegue)

En orden de coste creciente:

1. **Lint y validación sintáctica** antes de cualquier aplicación: `visudo -c`, `sshd -t`,
   `augenrules --check`, `nft -c -f`, `ansible-lint`. Barato y evita la mayoría de los bloqueos de
   acceso.
2. **Aplicación en modo comprobación** en no-producción (`--check --diff`) y revisión del diff.
   Aviso: los roles de ansible-lockdown **no soportan check mode** — no lo uses como única red.
3. **Escaneo de cumplimiento en CI** sobre la imagen dorada, con el perfil y el tailoring del
   proyecto: `oscap xccdf eval --profile <perfil> --tailoring-file <t.xml> --results-arf arf.xml
   --report report.html`. **El build rompe si el score baja del umbral acordado** o si aparece un
   fallo *nuevo* no cubierto por una excepción vigente. El umbral se sube con el tiempo; nunca se
   baja para que pase el build (§7).
4. **Smoke test funcional post-hardening**: el gate decisivo. Después de endurecer se comprueba que
   **el servicio responde de verdad** (puerto, health endpoint, transacción sintética, autenticación
   real), no que systemd diga `active`. Endurecer sin este test es apostar.
5. **Prueba de acceso con red de rescate**: cambios en SSH, PAM, firewall o `sudoers` se aplican
   **con una segunda sesión abierta o consola OOB disponible**, y se valida un login nuevo antes de
   cerrar la primera. No negociable.
6. **Escaneo continuo de la flota** (Wazuh SCA o equivalente) con **el drift como hallazgo**: ticket
   con dueño y fecha, igual que una vulnerabilidad. Un host que se aparta del baseline entre
   auditorías es exactamente el que te van a comprometer.
7. **Verificación del baseline tras cada cambio** que toque el SO (actualización mayor, nuevo rol,
   nuevo servicio): re-escaneo automático y comparación contra el informe anterior. Las
   actualizaciones de distro **reintroducen** configuración por defecto con frecuencia.
8. **Reinicio probado**: un host endurecido que no arranca tras el reinicio es peor que uno sin
   endurecer. Reinicio obligatorio en el pipeline de validación — montajes, `lockdown`, module
   signing, TPM/LUKS, `modules_disabled` e `initramfs` solo se comprueban de verdad al arrancar.

## 5. Seguridad del propio proceso de hardening

- **La cadena de suministro del baseline es cadena de suministro**: los roles de hardening se fijan
  (*pin*) por versión/tag —nunca `main`—, se revisa el diff al actualizar y se ejecutan desde un
  repo propio o un mirror interno. Un rol que corre como root en toda la flota es el objetivo más
  rentable que tienes. Verifica la firma cuando el proveedor la publique (las releases de
  ansible-lockdown están firmadas con GPG).
- **Rol abandonado = riesgo, no ahorro**: antes de adoptar cualquier contenido de hardening,
  verifica último release y actividad (§8). Un rol sin mantenimiento aplica un benchmark caducado y
  da sensación de cumplimiento.
- **El escáner no es inocuo**: `oscap` con `--remediate` modifica el sistema. Prohibido remediar
  automáticamente en producción desde el escaneo; el escaneo mide, el código aplica.
- **Secretos**: contraseñas de GRUB, hashes de arranque, claves de LUKS, `become_pass` y
  credenciales de agente van en Vault/sops, nunca en el repo ni en variables de rol en claro. El
  hash de contraseña de GRUB en un repo público es una credencial expuesta.
- **Los informes de cumplimiento son datos sensibles**: un ARF/HTML de OpenSCAP es un mapa de las
  debilidades exactas del host. Acceso restringido, no en un bucket abierto ni en el artefacto
  público del pipeline.
- **Registro de quién endurece**: los cambios de baseline se ejecutan desde CI con identidad propia
  y quedan auditados. Nadie aplica un rol de hardening desde su portátil con su cuenta personal.
- **El hardening no sustituye al parcheo**: 2026 ha dejado ejemplos explícitos de fallos de kernel
  que **anulan las garantías del baseline** (escaladas locales a root y bypass de MAC operando por
  debajo de la capa de política). Cuando el hallazgo es de kernel, la única mitigación fiable es
  parchear y reiniciar — coordínalo con `vulnerability-management-standards`.

## 6. Operabilidad y coste

- **Todo control tiene coste; el que no se mide se paga en producción**. Medir con el workload real
  antes de fijar: mitigaciones de CPU (orden de magnitud verificado: ~1-10 % según caso, §3.4),
  `auditd` (I/O y CPU proporcionales al número de reglas), AIDE (I/O del scan: fuera de pico),
  `MemoryDenyWriteExecute` (incompatible con JIT), `noexec` (rompe instaladores),
  `lockdown=confidentiality` (rompe perfilado y depuración).
- **Telemetría del cumplimiento**: exportar el score por host como métrica y alertar sobre
  *tendencia a la baja* y sobre *hosts sin escanear en N días*. Un host que ha dejado de reportar es
  un fallo de control, no un hueco en el dashboard.
- **Diagnóstico bajo un sistema endurecido**: documenta en el runbook cómo se depura con
  `dmesg_restrict`, `ptrace_scope` y `ProtectProc=invisible` activos — si no, la primera incidencia
  seria acabará con alguien desactivándolo todo "temporalmente".
- **Rollback**: cada cambio de hardening tiene revert conocido y probado (el rol debe poder
  desaplicar el control concreto). Sin revert probado no se toca producción.
- **Reinicios**: livepatching no elimina el reinicio, lo pospone — y los propios vendors lo exigen
  (kpatch obliga a actualizar kernel y reiniciar ≥2 veces al año; Canonical solo genera parches para
  un kernel durante 9-13 meses). Ventana de reinicio programada y **contador de uptime como señal de
  riesgo**, no de orgullo.
- **Compatibilidad**: hardening y automatización se estorban (`noexec` en `/tmp` frente a Ansible,
  `nosuid` frente a `become`, `RestrictNamespaces` frente a contenedores). Resuélvelo con
  configuración (`remote_tmp` propio, `pipelining=true`), no quitando el control.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Revisar la **versión del benchmark** trimestralmente (CIS publica actualizaciones continuas; DISA,
  trimestrales) y al salir cada versión mayor de distro. Cambiar de benchmark es un proyecto.
- Actualizar **SSG/ComplianceAsCode y OpenSCAP** con la distro; no mezclar contenido SSG de una
  versión menor con otra (Red Hat lo desaconseja explícitamente: el contenido y los componentes de
  hardening pueden no ser compatibles hacia atrás).
- Revisar **excepciones caducadas** en cada ciclo: la excepción sin fecha no existe.
- Reevaluar la lista de `sysctl`, módulos en blacklist y algoritmos SSH al cambiar de versión mayor
  de kernel u OpenSSH: **lo que era endurecer hace tres años hoy puede ser degradar**.
- No dejar en producción una distro EOL sin plan de salida fechado. Verificado ago-2026: **RHEL 10.2
  y RHEL 9.8** (ambas 20-may-2026; RHEL 10 Full Support hasta may-2030, RHEL 9 hasta may-2027);
  **Fedora 44** (28-abr-2026); **Debian 13.6 "trixie"** (11-jul-2026; soporte completo a ago-2028,
  LTS a jun-2030) con **Debian 12 saliendo de soporte regular el 11-jul-2026**; **Ubuntu 26.04 LTS**
  (23-abr-2026 → abr-2031, ESM a 2036) y **24.04 LTS** (→ abr-2029). **Trampa de RHEL**: durante
  Maintenance Support **solo el último minor recibe parches** — quedarse en 9.7 con 9.8 publicada es
  estar sin soporte de facto.

**PROHIBIDO**
- ❌ **Desactivar un control "para que funcione"** sin diagnóstico, sin excepción documentada y sin
  revert planificado. Incluye `setenforce 0`, parar el firewall, `chmod 777` y quitar `noexec`.
- ❌ **Aplicar CIS/STIG a ciegas en producción** sin ensayo previo y sin catálogo de excepciones.
- ❌ **Extrapolar un benchmark de otra versión de distro** (p. ej. aplicar el CIS de Ubuntu 24.04 a
  26.04, que aún no tiene benchmark) sin revisión regla a regla y sin declararlo como baseline propio.
- ❌ Baseline **sin excepciones documentadas** (aunque estén todas aplicadas: la lista vacía se
  declara), o excepciones **sin dueño y sin fecha de caducidad**.
- ❌ **Bajar el umbral de score** para que pase el build, o marcar reglas como "no aplicable" sin
  motivo escrito.
- ❌ `NOPASSWD: ALL` en sudo; reglas con comodines sobre rutas; binarios que permiten escape a
  shell; permitir `sudo --chroot`/`-R`; `sudo` a un grupo genérico "todos los técnicos".
- ❌ Editar el stack PAM a mano en distros gestionadas por `authselect`.
- ❌ Cuentas compartidas, login de root remoto, autenticación SSH por contraseña, claves SSH sin
  caducidad repartidas por la flota.
- ❌ **Silenciar el aviso post-cuántico de OpenSSH** (`WarnWeakCrypto`) en vez de actualizar el
  servidor; fijar listas de `Ciphers`/`KexAlgorithms`/`MACs` copiadas de una guía antigua sin
  comprobar qué negocia el binario actual.
- ❌ `mitigations=off` (o desactivar mitigaciones individuales) sin medición, sin aprobación del
  dueño del riesgo, y **jamás** en hosts multiinquilino o que ejecuten código de terceros.
- ❌ Desactivar MAC (`selinux=0`, AppArmor parado) como solución — ver `selinux-standards`.
- ❌ Rulesets gigantes de auditd copiados sin revisar; `/var/log/audit` sin partición propia; auditd
  que solo escribe en local sin reenvío al SIEM.
- ❌ Base de datos de AIDE almacenada únicamente en el host que audita; informes de integridad que
  nadie revisa; AIDE < 0.19.2.
- ❌ Editar unidades systemd del paquete en vez de usar `override.conf`; servicios de red corriendo
  como root sin sandboxing.
- ❌ Remediación automática (`oscap --remediate`) directamente contra producción.
- ❌ Aplicar simultáneamente dos roles de hardening (ansible-lockdown + devsec.hardening) sobre el
  mismo host.
- ❌ Usar el livepatching como excusa para no reiniciar nunca, o como sustituto del ciclo de parcheo.
- ❌ Sellar claves LUKS a PCRs frágiles sin política firmada, sin PIN y sin passphrase de
  recuperación custodiada fuera del host.
- ❌ Fijar versiones de benchmark, distro, EOL o algoritmos **de memoria** sin la verificación de §8.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato concreto, **búscalo — no lo recuerdes**:

1. **Versión vigente del CIS Benchmark de la distro exacta** en `cisecurity.org` o CIS WorkBench.
   Verificado ago-2026 (§2), incluido el hallazgo de que **Ubuntu 26.04 LTS aún no tiene benchmark**.
2. **Release de SCAP Security Guide / ComplianceAsCode** y perfiles disponibles para tu producto
   (verificado ago-2026: **v0.1.81**, 1-jun-2026). **Hueco declarado**: no se pudo obtener el
   **listado exhaustivo de perfiles por producto** (`complianceascode.github.io/content-pages/
   product-guides.html` → 404 y `static.open-scap.org/ssg-guides/` → 403); comprueba con
   `oscap info` sobre el datastream instalado, no de memoria.
3. **Release de DISA STIG** para tu SO. **Hueco declarado**: RHEL 9 V2R8, RHEL 10 V1R1 y Ubuntu 24.04
   V1R5 se verificaron **vía terceros** (Tenable, BigFix, Red Hat), **no** en `public.cyber.mil` —
   confirma en la fuente oficial antes de comprometerte contractualmente.
4. **Versión vigente de ANSSI-BP-028** en `cyber.gouv.fr` (verificado: **v2.0**, oct-2022, en SSG
   desde 0.1.73). **Hueco declarado**: no se pudo descartar la existencia de una versión posterior.
5. **Guías CCN-STIC aplicables** en `ccn-cert.cni.es` y el portal del ENS (verificado:
   **CCN-STIC 610-25** con anexos A/Rocky, B/Arch, E/Debian). **Huecos declarados**: la **letra de
   los anexos de Ubuntu y Fedora**, y si la 610-25 **deroga formalmente** la serie por producto
   `610Axx` (que sigue publicada). El texto del **RD 311/2022** tampoco se verificó contra el BOE.
6. **OpenSCAP, Lynis y Wazuh**: versión y mantenimiento (verificado ago-2026: OpenSCAP **1.4.4**,
   Lynis **3.1.7**, Wazuh **4.14.7**; los tres activos). Comprueba también **qué versión empaqueta tu
   distro**, que suele ir muy por detrás.
7. **Roles Ansible de hardening**: último release y actividad antes de adoptarlos (verificado
   ago-2026: ansible-lockdown RHEL9-CIS **v2.2.0** y UBUNTU24-CIS **v1.6.0**; devsec.hardening
   **10.6.0**). No adoptes un rol sin release en el último año. **Hueco declarado**: la versión
   mínima exacta de `ansible-core` que exige devsec.hardening 10.6.0 (la documentación dice ≥ 2.16 y
   la release declara 2.21) — compruébalo en el `galaxy.yml` de la versión que instales.
8. **OpenSSH**: versión instalada y algoritmos por defecto reales (`ssh -Q kex`, `sshd -T`) y estado
   del KEX post-cuántico en `openssh.com/pq.html` (verificado ago-2026: **10.4**, 06-jul-2026).
   **Hueco declarado**: la **lista exacta de MACs por defecto en 10.x** no se verificó (con AEAD la
   lista de MACs no se usa, así que su relevancia práctica es baja), ni si DSA se deshabilitó en
   compilación en 9.8 o en 9.9 — su **eliminación total en 10.0 sí está verificada**.
9. **systemd**: versión instalada y directivas de sandboxing en el man de esa versión (verificado
   ago-2026: **v261** es la línea actual; v260 17-mar-2026; v259 17-dic-2025). **Huecos declarados**:
   la **fecha exacta de v261** y los **cortes numéricos del exposure score** (los predicados existen;
   los umbrales 9.0/7.5/5.0 circulan en foros pero **no están en el manual**) — no cites números de
   corte, cita el predicado que devuelve la herramienta.
10. **audit-userspace**: versión y cambios operativos (verificado ago-2026: línea 4.1.x/4.2; carga de
    reglas por `audit-rules.service` desde 4.0; estado en `/run` desde 4.1.2).
11. **Versiones y EOL de las distros** en `endoflife.date` o el ciclo oficial del vendor (verificado
    ago-2026 en §7). **Hueco declarado**: discrepancia en el **fin de ELS de RHEL 9** entre
    2035-05-31 y 2036-05-31 — confirma en Red Hat antes de usarlo en un plan.
12. **CVEs vigentes** en la cadena que toques, con KEV/EPSS. Verificados y citables: **sudo
    CVE-2025-32462 / CVE-2025-32463** (fix en 1.9.17p1; 32463 en KEV desde 29-sep-2025);
    **linux-pam CVE-2025-6020 y CVE-2025-8941** (`pam_namespace`, fix en 1.7.1); **AIDE
    CVE-2025-54409** (fix en 0.19.2); **VMSCAPE CVE-2025-40300**. **Huecos declarados**: los CVEs de
    2026 en `polkit`/PackageKit/glibc solo se pudieron corroborar con **fuentes de fiabilidad media**
    (blogs de seguridad y PoCs, no NVD/upstream) — **no se citan aquí**; consúltalos en el aviso de tu
    vendor. Y nunca cites un identificador de memoria.
13. **Estado del livepatching** de tu vendor: cobertura, arquitecturas, ventanas y límites
    (verificado ago-2026 en §2). **Hueco declarado**: **SUSE Linux Enterprise Live Patching**
    (histórico kGraft) no se verificó contra fuente de SUSE.
14. **Mitigaciones de CPU**: vulnerabilidades de microarquitectura publicadas desde la última
    revisión y su coste. **Hueco declarado**: no se encontró **ninguna divulgación nueva confirmada
    en 2026** (la más reciente verificable es VMSCAPE, sept-2025) y **no hay dato actualizado del
    coste de `mitigations=off`** — mídelo con tu workload y comprueba
    `/sys/devices/system/cpu/vulnerabilities/`.
15. **Sysctls de endurecimiento del kernel** (`kptr_restrict`, `dmesg_restrict`, `yama.ptrace_scope`,
    module signing). **Hueco declarado**: no se verificaron contra fuente primaria; no se detectaron
    cambios respecto a la recomendación clásica, pero confírmalo en la documentación del kernel de tu
    versión antes de fijarlos.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
