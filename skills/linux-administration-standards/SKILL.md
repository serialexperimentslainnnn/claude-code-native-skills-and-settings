---
name: linux-administration-standards
description: Day-to-day Linux system administration, distribution-agnostic. Use when writing or debugging systemd units and .timer/.mount/.socket/.target files, systemctl edit overrides, Type=/Restart=/After=/Requires= semantics, systemd-analyze blame or critical-chain boot latency, systemd-run transient units, user units and loginctl enable-linger, journald retention (journalctl, journald.conf, SystemMaxUse, Storage=persistent), nsswitch.conf, /etc/fstab versus .mount units, autofs, cgroups v2 resource control (systemd-cgtop, MemoryMax=, CPUQuota=, IOWeight=, systemd-oomd, oomd.conf), NetworkManager/nmcli/nmstate versus systemd-networkd versus netplan renderer choice, resolvectl and /etc/resolv.conf, chrony or systemd-timesyncd clock drift, reboot-required policy after patching, rescue and emergency targets, chroot recovery, or diagnosing a slow or unbootable host with dmesg, iostat and pidstat.
---

# Estándares de administración de sistemas Linux

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **día a día del sistema operativo Linux, con independencia de la distribución**:
el modelo mental de systemd y sus unidades, el arranque y su latencia, logging con journald,
usuarios/grupos/sesiones, procesos y control de recursos con cgroups v2, montajes cotidianos,
configuración de red **desde el host**, paquetes y política de reinicio, hora del sistema, y el
**diagnóstico sistemático de un host** que va lento, no arranca o se quedó sin memoria.

Triggers: `systemctl`, `systemctl edit`, ficheros `.service`/`.timer`/`.mount`/`.socket`/`.path`/
`.target`/`.slice`, `Type=`, `Restart=`, `After=`, `Requires=`, `BindsTo=`, `WantedBy=`,
`systemd-analyze blame`/`critical-chain`/`verify`, `systemd-run`, `loginctl`, `enable-linger`,
`journalctl`, `journald.conf`, `SystemMaxUse=`, `Storage=persistent`, `systemd-cgtop`,
`systemd-cgls`, `MemoryMax=`, `MemoryHigh=`, `CPUQuota=`, `IOWeight=`, `systemd-oomd`,
`oomd.conf`, `/etc/nsswitch.conf`, `/etc/fstab`, `systemd-mount`, `autofs`, `nmcli`, `nmstate`,
`systemd-networkd`, `netplan`, `resolvectl`, `/etc/resolv.conf`, `chronyc`, `timedatectl`,
`needrestart`, `dnf needs-restarting`, `rescue.target`, `emergency.target`, `chroot` de
recuperación, `dmesg`, `iostat`, `pidstat`, "el servidor va lento", "no arranca", "se quedó sin
memoria", "el disco se llenó de logs".

**Principio rector**: **casi nada de lo que se diagnostica como "el sistema" es el sistema.** Un
host que "se queda sin memoria" es casi siempre **una unidad sin límite**; un arranque lento es
**una unidad concreta en la cadena crítica**; un `/var` lleno es **retención de journal sin fijar**.
El trabajo consiste en **atribuir el síntoma a una unidad, un cgroup o un fichero de configuración
concreto** antes de tocar nada — y en no tocar producción a ciegas.

**Frontera con la distribución**: esta skill es **agnóstica**. Todo lo que valga igual en Debian,
Ubuntu, SUSE y RHEL vive aquí. Lo que sea **particularidad de la familia Red Hat** (`dnf5`, RPM y
repos, `rpm-ostree`/`bootc`, `leapp`, `subscription-manager`, `grubby`, `tuned`, `firewalld`,
ciclos de vida de RHEL/Fedora/Alma/Rocky) es de `rhel-fedora-standards`, que **desarrolla** lo de
aquí para esa familia y no lo contradice.

**No aplica**: ver `onprem-standards` (**paraguas de plataforma**: hardware, plano OOB/BMC,
hipervisor, topología e inventario de flota, cadencia de parcheo de la flota — sus invariantes de
§1.3 son inviolables; **esta skill recoge el testigo del bloque de systemd que su §3 marcaba como
criterio provisional**), `rhel-fedora-standards` (particularidades de la familia Red Hat),
`linux-hardening-standards` (**todo lo que sea control de seguridad medible**: baselines CIS/STIG/
ANSSI/CCN-STIC, OpenSCAP/Lynis, `sysctl.d`, `sshd_config`, `auditd`, `sudoers`, `pam_faillock`,
`login.defs`, opciones de montaje `noexec`/`nosuid`/`nodev`, auditoría de SUID, **el sandboxing de
la unidad como control** (`ProtectSystem=`, `PrivateTmp=`, `systemd-analyze security`), AIDE,
Secure Boot/TPM/LUKS, actualizaciones de seguridad desatendidas y livepatching — **aquí el
`Type=`, el `Restart=`, las dependencias y el diagnóstico; allí el confinamiento y su medida**),
`selinux-standards` (MAC: denegaciones AVC, `semanage`, `restorecon`, booleanos, política propia;
si un servicio no arranca **por una denegación**, el diagnóstico es allí — aquí el diagnóstico de
por qué la unidad falla por dependencias, orden, recursos o configuración),
`bash-linux-scripting-standards` (higiene del script que automatiza cualquier cosa de aquí:
`set -Eeuo pipefail`, ShellCheck, `flock`, `mktemp`, bats), `iac-standards` (**la frontera es la
repetibilidad**: lo que se aplica a más de un host o más de una vez **se automatiza allí** con
Ansible idempotente y su CI; **aquí se decide qué se configura, con qué criterio y cómo se
diagnostica cuando falla** — un playbook que no sabe qué `Type=` poner no se arregla con más
`ansible-lint`), `networking-standards` (**diseño** de red: direccionamiento, VLAN, routing, BGP,
política de firewall entre zonas, DNS como servicio, VPN, proxies — **aquí solo la configuración de
red del propio host**: qué gestor se usa, cómo se declara una interfaz y cómo se lee `resolvectl`),
`observability-standards` (dónde se envían, retienen y correlacionan métricas y logs; **aquí el
lado local**: journald, su retención y su reenvío), `vulnerability-management-standards` (triaje de
CVE con CVSS/EPSS/KEV y SLA de remediación — **aquí la política de reinicio tras el parche**),
`identity-access-management-standards` (IdP, SSO, MFA, bastión y elevación JIT — aquí `nsswitch`,
`loginctl` y la sesión local), `windows-server-ad-standards` (**decisión explícita**: el bosque, el
dominio, GPO, Kerberos y el diseño de la identidad corporativa son suyos; **la integración del host
Linux con AD — `realmd`, `sssd.conf`, `adcli`, `nsswitch`, `pam_sss`, mapeo de UID/GID, `id` de un
usuario de dominio, caducidad del keytab — cae de este lado**, porque es configuración del sistema
Linux; el ticket Kerberos que no valida por deriva de reloj también es de aquí, §6),
`kubernetes-standards` (el host como nodo de un cluster: kubelet, cgroups del pod, drenaje),
`container-runtime-security-standards` (seccomp, escape de contenedor, detección en runtime),
`homelab-standards` (laboratorio personal: la frontera es el **rigor exigido**, no el tamaño),
`incident-management-standards` (la declaración del incidente, el IC y la comunicación mientras tú
diagnosticas), `incident-response-forensics-standards` (**si el host puede estar comprometido, para
y cede**: el orden de volatilidad manda sobre el diagnóstico de rendimiento; reiniciar "a ver si se
arregla" destruye evidencia), `bcdr-standards`, `grc-compliance-standards`, `perl-standards` (**Ola 5**: el Perl del sistema es
parte de la distribución y **no se toca**; el Perl de aplicación y su gestión de dependencias son
suyos), `lua-standards` (**Ola 5**: la configuración de nginx es de red y plataforma; el Lua
embebido en él, suyo).

Planificadas — hasta que existan, esta skill es criterio provisional en su solapa:
`linux-storage-standards` (**Ola 2**: LVM, multipath, NVMe, diseño y tuning de filesystems,
`fstrim`, RAID software — **aquí solo el montaje del día a día**: `fstab` vs. unidades `.mount`,
`systemd-mount`, autofs, y "el disco está lleno"; **allí** cómo se dimensiona y se afina),
`backup-recovery-standards` (**Ola 2**: mecánica de copia y restore),
`podman-systemd-containers-standards` (**Ola 2**: Podman y Quadlet — **frontera precisa**: las
unidades `.container`/`.pod`/`.volume`/`.image` de Quadlet y su generador son suyas; el
comportamiento de systemd que las ejecuta —`Type=notify`, orden, `Restart=`, cgroup, journal— es de
aquí), `zfs-standards`, `ha-clustering-standards` (**Ola 2**: Pacemaker/Corosync — un recurso
gestionado por el cluster **no se toca con `systemctl`**, §7), `dns-standards`,
`firewall-policy-standards`, `vpn-standards`, `libvirt-kvm-standards`, `proxmox-ve-standards`,
`network-troubleshooting-standards` (**Ola 2 — frontera delicada y explícita**: el diagnóstico
**del host** es de esta skill —¿la interfaz está `UP`?, ¿el gestor de red correcto la gestiona?,
¿hay ruta por defecto?, ¿`resolvectl status` resuelve?, ¿el socket está en `LISTEN` con `ss -ltnp`?,
¿el servicio falla por límite de recursos o por dependencia?—; el diagnóstico **de la red** es suyo
—captura con `tcpdump`/Wireshark, MTU/MSS y fragmentación, camino y latencia entre hosts, pérdida,
asimetría de rutas, qué firewall intermedio descarta—. **La regla de corte**: si el problema se
reproduce con un `ss`, un `ip`, un `journalctl` y un `curl` a `localhost`, es tuyo; si necesitas
mirar en dos extremos a la vez o poner un sniffer, es suyo).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Gestor de servicios | **systemd**, rama estable **v261** (v261.2, 23-jul-2026); ramas de mantenimiento vivas: 258.x, 259.x, 260.x | Verificado ago-2026 vía `api.github.com`. **No asumas la versión upstream en tu distro**: comprueba con `systemctl --version` — la distro va por detrás y las directivas nuevas no existirán |
| Compatibilidad SysV | **Ninguna. Unidad nativa siempre** | Verificado en el `NEWS` de v260: **se eliminó el soporte de scripts System V** (`systemd-sysv-generator`, `systemd-rc-local-generator`/`rc-local.service`, `systemd-sysv-install`). v260 también sube el **baseline de kernel a 5.10** (recomendado 5.14; 6.6 para funcionalidad completa). Un `/etc/init.d/` o un `/etc/rc.local` que hoy "funciona" **desaparece** al llegar v260 a tu distro: audita ahora y migra |
| Jerarquía de cgroups | **v2 (unified), única** | Verificado en el `NEWS` de v258: **soporte de cgroup v1 (`legacy` e `hybrid`) eliminado**; v2 se monta siempre en arranque y en `systemd-nspawn`. Kernel mínimo subido a 5.4 en v258. Si en `/proc/cmdline` hay `systemd.unified_cgroup_hierarchy=0`, es deuda: quítalo antes de actualizar |
| Tareas programadas | **Timers de systemd** para todo lo nuevo | Logs en el journal, `Persistent=true` recupera ejecuciones perdidas, `RandomizedDelaySec=` evita el efecto manada, dependencias reales y estado consultable (`systemctl list-timers`). `cron` solo para lo heredado que no se vaya a tocar; **no se mezclan** los dos para la misma tarea |
| Overrides de unidad | **`systemctl edit <unit>`** → `/etc/systemd/system/<unit>.d/override.conf` | **Nunca** se edita la unidad que instala el paquete: la sobrescribe la siguiente actualización, silenciosamente. `systemctl edit --full` solo si hay que reescribirla entera, y entonces se documenta por qué |
| Unidad transitoria | **`systemd-run`** (con `--unit=`, `--property=`, `--on-calendar=`, `--scope`) | Una tarea puntual que debe sobrevivir a la sesión SSH, o que necesita límites de recursos, va en una unidad transitoria — **no en `nohup`, `screen` ni `&`**: sin cgroup, sin logs, sin límites y sin trazabilidad |
| Logging | **journald con almacenamiento persistente** (`Storage=persistent`) y límites explícitos (`SystemMaxUse=`, `SystemMaxFileSize=`, `MaxRetentionSec=`) | El defecto volátil pierde el log del arranque anterior — justo el que hace falta tras un crash. Sin límite explícito, `/var/log/journal` crece hasta el 10% del FS |
| Agregación de logs | **Reenvío a un agregador central** desde journald (`systemd-journal-upload`, o agente vector/promtail/rsyslog) | El diseño del stack lo fija `observability-standards`. Aquí el invariante: **el log que solo existe en el host que falló no existe** |
| syslog local | Solo si un consumidor lo exige (`ForwardToSyslog=yes`) | Mantener rsyslog **y** journald escribiendo lo mismo duplica el disco y el trabajo. Elige uno como fuente y el otro como transporte |
| Gestión de red del host | **La nativa de la distro, una sola**: NetworkManager (`nmcli`/`nmstate`) en RHEL/Fedora y en escritorios; **netplan** en Ubuntu (renderer `networkd` en servidor, `NetworkManager` en escritorio); `systemd-networkd` en servidores Debian/minimalistas y contenedores | Verificado ago-2026. **La regla dura es no mezclar**: dos gestores sobre la misma interfaz produce IP duplicadas, DNS sobrescrito y arranques que cuelgan 2 minutos. NetworkManager es *greedy* (gestiona lo que no se le prohíba); `networkd` solo gestiona lo que se le declara |
| Resolución DNS del host | **`systemd-resolved`** con `/etc/resolv.conf` → symlink a `/run/systemd/resolve/stub-resolv.conf`, y **`resolvectl status` como fuente de verdad** | `cat /etc/resolv.conf` **no dice qué está resolviendo** cuando hay stub, split-DNS por interfaz o DNS por VPN. Editar `/etc/resolv.conf` a mano en un sistema con `resolved` es un cambio que se pierde en el próximo evento de red |
| Hora | **chrony** en servidores; `systemd-timesyncd` (SNTP) solo en clientes/VM sin requisito | chrony converge más rápido, aguanta redes malas, soporta NTS y sirve como servidor. `timesyncd` **no es un servidor NTP** ni disciplina bien tras suspensión |
| Control de memoria | **Límites en la unidad** (`MemoryMax=`, `MemoryHigh=`, `MemoryMin=`) por servicio, más `systemd-oomd` donde la distro lo trae | Verificado: `systemd-oomd` viene **activado por defecto en Fedora** (desde F34, sustituyó a earlyoom) y **empaquetado pero desactivado en RHEL** (`systemctl enable --now systemd-oomd`, `/etc/systemd/oomd.conf`). Actúa por **PSI** antes que el OOM killer del kernel, y mata el **cgroup**, no un proceso suelto |
| Política de reinicio tras parche | **Explícita y automatizada**: `needrestart` (Debian/Ubuntu) o `dnf needs-restarting -r` (familia RPM), con ventana definida | Un parche de `glibc`/`openssl` aplicado sin reiniciar el proceso **no está aplicado**. Ver §5 para el CVE de `needrestart` |
| Unidades de usuario | `systemctl --user` para procesos del usuario; **`loginctl enable-linger <user>`** solo si deben sobrevivir al logout | Sin *lingering*, la unidad de usuario muere al cerrar la última sesión — causa habitual de "el contenedor rootless se para solo de noche" |

## 3. Estructura y convenciones

### 3.1 Anatomía de una unidad correcta

Toda unidad de servicio propia cumple, sin excepción:

- **`Type=` correcto**, y esto no es cosmético: `notify` si el software habla `sd_notify` (lo
  mejor: systemd sabe cuándo está *realmente* listo); `exec` si es un proceso normal en primer
  plano; `oneshot` + `RemainAfterExit=` para tareas de inicialización; `forking` **solo** si el
  software se demoniza y no se le puede pedir lo contrario (y entonces con `PIDFile=`).
  `Type=simple` se considera "listo" en cuanto hace `fork/exec`: **miente** sobre la disponibilidad
  y rompe cualquier `After=` que dependa de ella.
- **`Restart=on-failure`** con `RestartSec=` y **`StartLimitIntervalSec=`/`StartLimitBurst=`**
  ajustados. `Restart=always` oculta fallos permanentes en un bucle; sin límite de arranque, un
  servicio roto castiga la CPU y llena el journal.
- **Dependencias reales, no decorativas.** Este es el error más común y más caro:
  - `After=` es **solo orden**, no requisito. `Requires=` es **requisito**, no orden. Se necesitan
    **los dos** para "empieza después de X y no arranques si X falló".
  - `Wants=` es dependencia **débil** (arranca X, pero sigue si falla): es el valor por defecto
    correcto para la mayoría.
  - `BindsTo=` para "si X se para, yo me paro" (dispositivos, montajes, sockets).
  - **`After=network.target` casi nunca es lo que quieres**: significa "después de que se haya
    *configurado* la red", no "con IP y ruta". Si el servicio hace `bind()` a una IP concreta o
    necesita salir a la red al arrancar, es `Wants=network-online.target` **y**
    `After=network-online.target`, **y** el servicio de espera correspondiente activado
    (`NetworkManager-wait-online` o `systemd-networkd-wait-online`). Y aun así: **es mejor un
    servicio que reintenta que un `network-online.target` que retrasa el arranque un minuto.**
  - Dependencia de un montaje: `RequiresMountsFor=/ruta` — no `After=` sobre la unidad `.mount`
    adivinada a mano.
- **Sandboxing**: es un **control de seguridad y su criterio lo fija `linux-hardening-standards`**
  (`ProtectSystem=strict`, `PrivateTmp=`, `NoNewPrivileges=`, `CapabilityBoundingSet=`,
  `systemd-analyze security`). Aquí solo el invariante operativo: **una unidad propia sin
  usuario dedicado (`User=` o `DynamicUser=`) es un hallazgo**, y `systemd-analyze security` se
  ejecuta antes de dar la unidad por buena.
- **Límites de recursos explícitos** en cualquier servicio que pueda crecer: `MemoryMax=`,
  `MemoryHigh=`, `CPUQuota=`, `TasksMax=`, `IOWeight=`. Ver §6.
- **Sin lógica en la unidad**: `ExecStart=` apunta a un binario o a un script versionado del repo,
  no a una cadena de `sh -c` con tuberías y `&&`. Si hace falta lógica, es un script
  (`bash-linux-scripting-standards`).

### 3.2 Convenciones de fichero

- Unidades propias en `/etc/systemd/system/`; **nunca** en `/usr/lib/systemd/system/` (territorio
  del paquete). Overrides en `<unit>.d/override.conf`.
- `systemctl daemon-reload` después de cualquier cambio de fichero de unidad; `systemctl
  reenable` si cambian los `WantedBy=`. Un `systemctl restart` sin `daemon-reload` aplica la unidad
  vieja: causa clásica de "he cambiado el fichero y no hace efecto".
- Configuración por *drop-in* en todo lo que lo admita (`/etc/systemd/*.conf.d/`,
  `/etc/sysctl.d/`, `/etc/systemd/journald.conf.d/`, `/etc/NetworkManager/conf.d/`), no editando
  el fichero principal del paquete. Prefijo numérico para el orden (`50-`).
- Credenciales de un servicio con **`LoadCredential=`/`systemd-creds`**, no en `Environment=` ni en
  un `EnvironmentFile` legible por todos (el detalle es de `secrets-management-standards`).
- Montajes: `/etc/fstab` sigue siendo válido y es el default sensato (systemd lo traduce a unidades
  `.mount` automáticamente). Se pasa a unidad `.mount` explícita cuando hace falta
  **orden o dependencia** que `fstab` no expresa. Montajes de red y todo lo que pueda no estar
  disponible: `noauto,x-systemd.automount` o autofs — **nunca** un montaje de red bloqueante sin
  `_netdev` y sin timeout, porque convierte un NFS caído en un host que no arranca.

### 3.3 Convenciones de flota (heredadas del paraguas)

- Todo host **reconstruible desde código**; el cambio manual en prod es *drift* y es hallazgo.
  Lo repetible se automatiza en `iac-standards`; **lo que se escribe a mano es la excepción
  documentada, no la costumbre**.
- **Ningún dato de host de memoria**: IP, rol, VLAN, dueño y criticidad salen del inventario.
- Ningún servicio, host o certificado sin dueño y sin fecha de fin de vida.

## 4. Calidad: validar antes de recargar, verificar después

Orden de coste creciente. **Ninguno es opcional en producción.**

1. **Validadores sintácticos antes de aplicar**, siempre que existan:
   - `systemd-analyze verify /etc/systemd/system/<unit>` — detecta directivas inválidas,
     dependencias inexistentes y rutas mal puestas **sin arrancar nada**.
   - `sshd -t` (o `sshd -T` para volcar la config efectiva), `visudo -c` / `visudo -f`,
     `nginx -t`, `named-checkconf`, `chronyd -Q`, `nft -c -f`, `netplan generate` (no `apply`),
     `nmcli con show` tras `nmcli con modify`.
   - `systemd-analyze security <unit>` para el sandboxing (criterio en `linux-hardening-standards`).
2. **Smoke test post-cambio, siempre**: `systemctl is-active` **no es una prueba**. Un servicio
   `active (running)` que no escucha en su puerto sigue caído para el usuario. El gate es:
   puerto en `LISTEN` (`ss -ltnp`), respuesta del health endpoint, y **journal sin errores nuevos**
   (`journalctl -u <unit> --since "-2 min" -p warning`).
3. **Sesión de rescate abierta al tocar el acceso remoto.** Antes de recargar `sshd`, firewall de
   host, red o PAM: una segunda sesión SSH ya autenticada (o la consola OOB/serie) abierta y
   **verificada**, y el cambio confirmado desde una **tercera** conexión nueva antes de cerrar
   nada. Complemento barato: un `systemd-run --on-active=5m systemctl restart NetworkManager`
   (o revertir la config) como red de seguridad, cancelado en cuanto se confirma el acceso.
4. **Cambio reversible por diseño**: se conoce el comando de revert **antes** de aplicar. Si el
   revert no cabe en una línea, no es un cambio, es un proyecto — y va por ventana.
5. **Prueba de arranque real** tras cualquier cambio en `fstab`, unidades de montaje, initramfs,
   red o gestor de arranque: **reiniciar en ventana**. Un host que lleva 400 días arriba con
   cambios sin reiniciar es un host cuyo arranque nadie ha probado.
6. **Ensayo fuera de producción** para todo lo que toque arranque, kernel o almacenamiento. El
   host de staging existe para esto.

## 5. Seguridad del día a día

> El baseline (CIS/STIG), `sysctl`, auditd, `sudoers`, PAM y el sandboxing como control son de
> `linux-hardening-standards`; el MAC es de `selinux-standards`. Aquí solo lo inherente a la
> operación diaria.

- **Política de reinicio = parte del parche.** `needrestart` / `dnf needs-restarting -r` decide;
  el resultado se registra y hay ventana. Un `libssl` actualizado con 40 procesos usando el
  binario viejo en memoria es un CVE abierto con el ticket cerrado.
  - **CVE relevante en la herramienta misma**: `needrestart` **< 3.8** arrastró cinco escaladas
    locales a root descubiertas por Qualys (nov-2024), entre ellas **CVE-2024-48990** (vía
    `PYTHONPATH` de un proceso de un usuario sin privilegios). Si operas Debian/Ubuntu, verifica
    la versión instalada y que el parche está aplicado — es el ejemplo perfecto de por qué la
    herramienta de operación también es superficie de ataque.
  - **CVE-2025-32463** (`sudo`, opción `-R`/`chroot`): escalada local a root. `sudo` es la
    herramienta que más se ejecuta en un host administrado: su parcheo no espera a la ventana
    mensual. El triaje y el SLA los fija `vulnerability-management-standards`.
- **Journal como evidencia**: `Storage=persistent`, `Seal=yes` (FSS) donde el journal deba ser
  verificable, y reenvío inmediato a un agregador **fuera del host** — un atacante con root borra
  el journal local en un segundo. La retención y la correlación son de `observability-standards`;
  la cadena de custodia, de `incident-response-forensics-standards`.
- **Sesiones y `nsswitch`**: el orden de `/etc/nsswitch.conf` decide de dónde salen usuarios y
  grupos. Un `sss` antes de `files` con el directorio caído deja el host sin poder resolver ni
  `root` para algunas operaciones; un `files` primero con una cuenta local homónima de una de
  dominio es una puerta trasera silenciosa. **Se revisa explícitamente, no se hereda del
  instalador.**
- **`systemd-run` y unidades transitorias no son un atajo de permisos**: heredan el contexto de
  quien las lanza. Una tarea "temporal" lanzada como root que sigue viva tres meses después es un
  servicio no declarado — se declara o se mata.
- **Antes de diagnosticar rendimiento, descarta compromiso.** Consumo de CPU inexplicable, procesos
  sin unidad padre, conexiones salientes raras: eso no es un problema de capacidad. Se para, se
  preserva y manda `incident-response-forensics-standards`. **Reiniciar destruye evidencia.**

## 6. Rendimiento, recursos y operabilidad

### 6.1 cgroups v2 es el modelo real

- **"El servidor se quedó sin memoria" casi siempre significa "una unidad sin `MemoryMax=`".** Sin
  límites, el OOM killer del kernel elige la víctima por heurística — y suele elegir mal (mata la
  base de datos, no el proceso que se desbocó). Con límites por unidad, el fallo queda **contenido
  en el servicio culpable** y es atribuible.
- Herramientas de atribución, en este orden: `systemd-cgtop` (consumo **por unidad/slice**, que es
  la vista útil), `systemd-cgls` (jerarquía), `systemctl status <unit>` (memoria y tareas
  actuales), `systemctl show <unit> -p MemoryCurrent,MemoryMax,CPUQuotaPerSecUSec,TasksCurrent`.
- Directivas: `MemoryHigh=` (**presión y reclaim**, el freno preferido: degrada en vez de matar),
  `MemoryMax=` (**muro duro**, provoca OOM del cgroup), `MemoryMin=`/`MemoryLow=` (protección de lo
  crítico frente al reclaim), `CPUQuota=`/`CPUWeight=`, `IOWeight=`/`IOReadBandwidthMax=`,
  `TasksMax=` (contención de *fork bombs* y fugas de hilos).
- **Se aplican en caliente**: las propiedades de cgroup surten efecto sin reiniciar el servicio
  (`systemctl set-property <unit> MemoryHigh=2G` para probar; el cambio permanente va en el
  override, §3). Probar en caliente y **luego** persistir es el flujo correcto.
- **Agrupa por *slice*** cuando hay clases de carga: `system.slice`, `user.slice`, y slices propias
  (`app.slice`) con reparto explícito. Proteger `system.slice` del `user.slice` evita que una
  sesión interactiva tire el host.
- `systemd-oomd` actúa por **PSI** antes del OOM killer y mata el cgroup completo. Útil, pero **no
  sustituye a los límites**: es la red de seguridad, no la política. Revisa
  `DefaultMemoryPressureLimit=` y `DefaultMemoryPressureDurationSec=` antes de activarlo en un
  servidor — los defectos están pensados para escritorio.

### 6.2 Arranque

- `systemd-analyze` (tiempo total, firmware/loader/kernel/userspace) → `systemd-analyze blame`
  (unidades por tiempo, **engaña**: una unidad lenta en paralelo no retrasa nada) →
  `systemd-analyze critical-chain [unit]` (**la vista que importa**: la cadena que realmente
  determina el tiempo) → `systemd-analyze plot > boot.svg` para el detalle visual.
- Sospechosos habituales de un arranque de minutos: `*-wait-online` esperando una interfaz que
  nunca llega (DHCP en una VLAN sin servidor, bonding a medio configurar), montajes de red sin
  `_netdev`/timeout, un `Requires=` sobre algo que no existe, resolución DNS bloqueante.
- Un arranque lento **se mide antes y después**. "Ahora parece más rápido" no es un dato.

### 6.3 Journald

- **Lo que NO se resuelve rotando ficheros a mano**: journald **no usa logrotate** y su retención
  se fija en `journald.conf` (`SystemMaxUse=`, `SystemKeepFree=`, `SystemMaxFileSize=`,
  `MaxRetentionSec=`, `MaxFileSec=`). Borrar ficheros de `/var/log/journal` a mano deja el índice
  inconsistente; lo correcto es `journalctl --vacuum-size=`/`--vacuum-time=` y **arreglar la
  política**, no el síntoma.
- **`/var` lleno de logs es un problema de política, no de disco.** Añadir espacio sin fijar
  retención garantiza repetir la incidencia con un disco más caro. Y si el volumen viene de un
  servicio en bucle de reinicio, el arreglo es el servicio (§3.1: `StartLimitBurst=`), no la
  retención.
- `journalctl` con criterio: `-u <unit>` (unidad), `-b -1` (**arranque anterior**: el que interesa
  tras un crash — requiere journal persistente), `-p err..alert` (severidad), `--since/--until`,
  `-f` (seguimiento), `-k` (kernel), `-o json`/`-o verbose` (campos estructurados, incluido
  `_SYSTEMD_UNIT` y `_PID` reales), `--disk-usage`, `--verify`.
- Ratio de rotación y espacio como **métrica monitorizada**, no como sorpresa.

### 6.4 Hora — la causa raíz que nunca se sospecha

**La deriva de reloj se presenta disfrazada**: "TLS roto sin causa" (certificado *not yet valid* /
*expired* según el host), Kerberos que rechaza tickets (tolerancia típica de 5 minutos), logs
imposibles de correlacionar entre hosts, tokens JWT inválidos, réplicas de base de datos que
divergen, backups que se solapan.

- `timedatectl` y `chronyc tracking` / `chronyc sources -v` en **todo** diagnóstico de "falla la
  autenticación" o "el certificado no vale". Es la comprobación de 5 segundos que ahorra la tarde.
- **Métrica de deriva monitorizada con alerta** en toda la flota (el umbral y el stack los fija
  `observability-standards`). Un host sin NTP funcional es un host que aún no ha fallado.
- Zona horaria: **UTC en servidores**, siempre. El *localtime* es cosa de la presentación.

### 6.5 Método de diagnóstico por capas

Ante "va lento" / "no responde", en este orden y **anotando lo que se descarta**:

1. **¿Qué cambió?** Último despliegue, último parche, último cambio de config. `journalctl --since`
   sobre la ventana del cambio, `rpm -qa --last` / `zgrep` del log del gestor de paquetes,
   historial del repo de IaC. La mayoría de las incidencias son un cambio reciente.
2. **Arranque y kernel**: `systemctl --failed`, `systemctl list-jobs` (unidades atascadas),
   `dmesg -T --level=err,warn` (OOM, reset de disco, errores de NIC, MCE, `blocked for more than
   120 seconds`).
3. **Recursos, atribuidos por cgroup**: `systemd-cgtop`, `uptime`/*load average* leído junto a
   `vmstat 1` (distinguir CPU de espera de I/O de `D-state`), `free -m` con `available` (no
   `free`), presión con **PSI** (`/proc/pressure/{cpu,memory,io}` — la señal más directa de "esto
   está saturado" y la que usa `systemd-oomd`).
4. **I/O**: `iostat -xz 1` (`%util`, `await`, `aqu-sz`), `pidstat -d 1` (**qué proceso**),
   `iotop`/`biolatency` si están. Un `await` alto con `%util` bajo apunta al almacenamiento remoto,
   no al disco.
5. **Red desde el host**: `ip -br a` / `ip r` (interfaz, ruta), `resolvectl status` (DNS efectivo,
   **no `/etc/resolv.conf`**), `ss -ltnp` / `ss -s` (sockets, retransmisiones), contadores de
   error/drop en `ip -s link`. **Si el problema no se cierra aquí, cruza la frontera** hacia
   `network-troubleshooting-standards` (§1).
6. **Espacio y inodos**: `df -h` **y `df -i`** (el segundo se olvida y es la causa del 20% de los
   "no puedo escribir" con disco aparentemente libre), `du -x --max-depth=1`,
   `journalctl --disk-usage`, y **ficheros borrados con el descriptor abierto** (`lsof +L1`) — el
   clásico "he borrado el log y no baja el disco".
7. **El servicio**: `systemctl status`, `journalctl -u`, config efectiva (`sshd -T`, `nginx -T`),
   dependencias (`systemctl list-dependencies --before/--after`).

**Recuperación cuando no arranca**, en orden de invasividad:

- Consola (OOB/serie/hipervisor) **primero**: sin consola no hay diagnóstico de arranque, solo
  reinicios a ciegas. Esto es exigencia de plataforma (`onprem-standards`).
- `systemd.unit=rescue.target` (multiusuario mínimo, con FS montados) → `emergency.target`
  (solo shell, raíz en *read-only*) → `rd.break` (parada en el initramfs) desde la línea de
  comandos del kernel, editada **para ese arranque**, no persistida.
- `systemd.log_level=debug` / `systemd.log_target=console` cuando el arranque falla sin decir por
  qué; `journalctl -b -1 -p err` en cuanto se recupere el acceso.
- **Chroot de recuperación** (medio de instalación en modo *rescue*): montar la raíz, `mount
  --bind` de `/dev`, `/proc`, `/sys`, `/run`, entrar, arreglar, **regenerar initramfs y
  actualizar el gestor de arranque si se tocó algo de arranque**, salir limpiamente. Precaución
  específica de la familia Red Hat: si SELinux está activo, un cambio hecho en chroot puede dejar
  ficheros mal etiquetados — se planifica el reetiquetado (`selinux-standards`).
- **Nunca se toca producción a ciegas.** Si no hay hipótesis, no hay cambio: hay recogida de datos.
  Y todo cambio en caliente durante un incidente se anota en el canal del incidente
  (`incident-management-standards`) con hora y autor — el postmortem se escribe con eso.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Actualización de seguridad del SO: automática en tiers bajos, semanal orquestada en producción,
  **con política de reinicio** (§5). La cadencia de flota la fija `onprem-standards`; el triaje del
  CVE concreto, `vulnerability-management-standards`.
- Salto de versión mayor de la distro: **se ensaya en un host gemelo**, con revert probado y
  ventana. Nunca en el host que importa primero.
- Cada versión de systemd que entra con la distro: **leer el `NEWS` de las versiones saltadas**
  antes de actualizar, buscando "Feature Removals and Incompatible Changes". Ahí es donde
  desaparecen las cosas que llevabas años usando (SysV en v260, cgroup v1 en v258).
- Auditoría semestral de deuda: `/etc/init.d/` con contenido, `/etc/rc.local`, `cron` con tareas
  que deberían ser timers, unidades del paquete editadas a mano, montajes en `fstab` sin dueño,
  `systemd-analyze verify` sobre todas las unidades propias.

**PROHIBIDO**
- ❌ Editar la unidad que instala el paquete en vez de un drop-in con `systemctl edit`.
- ❌ `Type=simple` (o el default) en un servicio del que otros dependen: miente sobre estar listo.
- ❌ `After=` sin `Requires=`/`Wants=` cuando lo que se quiere es un requisito — o al revés.
- ❌ `After=network.target` esperando conectividad real. Y `network-online.target` puesto "por si
  acaso" en todo, que retrasa el arranque del host entero.
- ❌ `Restart=always` sobre un fallo permanente, o sin `StartLimitBurst=`: bucle infinito que
  quema CPU y llena el journal.
- ❌ Servicios propios sin `User=`/`DynamicUser=` y sin límites de recursos.
- ❌ Procesos de larga vida lanzados con `nohup`, `&`, `screen` o `tmux` en producción: sin cgroup,
  sin límites, sin logs, sin dueño. Van en unidad (o `systemd-run` si son puntuales).
- ❌ Añadir tareas nuevas a `cron` habiendo timers; o duplicar la misma tarea en cron **y** timer.
- ❌ Journal volátil en un servidor, o sin límite de tamaño; borrar ficheros de
  `/var/log/journal` a mano en vez de `--vacuum-*` y arreglar la retención.
- ❌ Resolver un `/var` lleno ampliando el disco sin fijar la política de retención.
- ❌ Editar `/etc/resolv.conf` a mano en un sistema con `systemd-resolved`, o diagnosticar DNS
  leyendo ese fichero en vez de `resolvectl status`.
- ❌ Dos gestores de red activos sobre la misma interfaz (NetworkManager + `systemd-networkd`,
  netplan + NM sin renderer coherente, `ifupdown` conviviendo con cualquiera de ellos).
- ❌ Tocar `sshd`, PAM, red o firewall **sin sesión de rescate abierta ni consola OOB**.
- ❌ Recargar un servicio sin pasar su validador (`sshd -t`, `visudo -c`, `nginx -t`,
  `systemd-analyze verify`) existiendo uno.
- ❌ Dar por bueno un cambio porque `systemctl is-active` dice `active`.
- ❌ Montajes de red bloqueantes en `fstab` sin `_netdev`, `nofail` o `x-systemd.automount`: un NFS
  caído se convierte en un host que no arranca.
- ❌ Host de producción sin NTP funcional o con zona horaria local.
- ❌ `systemctl start/stop/restart` sobre un recurso gestionado por un cluster (Pacemaker): se
  gestiona con las herramientas del cluster o se provoca un fencing.
- ❌ Reiniciar "a ver si se arregla" antes de recoger datos — y **siempre** si hay sospecha de
  compromiso (destruye evidencia volátil).
- ❌ Cambios manuales en producción que no vuelven al código/inventario (*snowflakes*).
- ❌ Desactivar SELinux/AppArmor, el firewall de host o `systemd-oomd` "para que funcione", sin
  diagnóstico ni fecha de revert.
- ❌ Mantener scripts SysV o `/etc/rc.local` como estrategia: desaparecen con systemd v260.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, directiva, comportamiento o fecha, **búscalo — no lo recuerdes**:

1. **Versión de systemd en tu distro** (`systemctl --version`) **y** la línea upstream vigente. Una
   directiva que existe upstream puede no existir en tu host. Verificado ago-2026 vía
   `api.github.com`: rama estable **v261** (v261.2, 23-jul-2026); mantenimiento en 258.x, 259.x,
   260.x. **No leas versiones ni fechas del render HTML de GitHub Releases: usa `api.github.com` o
   los feeds Atom.**
2. **`NEWS` upstream de cada versión que saltes**, sección "Announcements of Future Feature Removals
   and Incompatible Changes" — leído directamente desde
   `raw.githubusercontent.com/systemd/systemd/vNNN/NEWS`, no de blogs.
3. **Directivas de unidad**: `systemd.exec(5)`, `systemd.resource-control(5)`, `systemd.unit(5)`
   de **tu** versión. Los defaults cambian entre versiones.
4. **Gestor de red por defecto** de la distro y versión exactas antes de escribir configuración de
   red; y qué servicio `*-wait-online` corresponde.
5. **CVE activos** de las herramientas de operación que usas a diario (`sudo`, `needrestart`,
   `openssh`, `systemd`, `chrony`, `polkit`) — son superficie de ataque con acceso local
   privilegiado. Prioriza con KEV/EPSS (`vulnerability-management-standards`).
6. **EOL de la distro** en `endoflife.date` y en la fuente del vendor antes de planificar cualquier
   ciclo de parcheo o migración.

**Huecos declarados — NO verificados en la redacción de este documento; verifícalos antes de
apoyarte en ellos:**

- **Retirada de cgroups v1 en las distros concretas** (no en systemd, que ya está: eliminado en
  v258). En qué versión de Debian/Ubuntu/SUSE deja de arrancarse con
  `systemd.unified_cgroup_hierarchy=0` — **no verificado**. Existe además una afirmación circulando
  en blogs de que "v260 deshabilita cgroup v1 por defecto" que **contradice** el `NEWS` de v258
  (donde ya está eliminado): trata la fuente blog como no fiable y confirma en el `NEWS`.
- **Debian 13/14 y Ubuntu 26.04: gestor de red por defecto exacto por perfil de instalación** —
  descrito aquí a partir de fuentes secundarias (`ifupdown` en servidor Debian, netplan+networkd en
  Ubuntu Server, netplan+NM en Ubuntu Desktop). **No confirmado contra documentación oficial.**
- **Versión de systemd empaquetada por cada distro viva** (Debian estable, Ubuntu LTS, RHEL 9/10,
  Fedora 43/44) — **no verificada una por una**. Comprueba en el host antes de usar cualquier
  directiva reciente.
- **Estado y defaults de `systemd-oomd` en RHEL 10 y Ubuntu 26.04** — solo verificado que en
  Fedora viene activado por defecto desde F34 y que en RHEL se empaqueta desactivado; los umbrales
  por defecto en cada versión **no verificados**.
- **Fechas y detalles de los CVE citados** (`CVE-2024-48990` en `needrestart` < 3.8,
  `CVE-2025-32463` en `sudo`): identificados por búsqueda, **CVSS, versiones exactas afectadas y
  estado en KEV no verificados**. Consúltalos en la fuente antes de fijar un SLA.
- **`systemd-analyze verify` y su cobertura real** (qué clases de error detecta y cuáles no) — no
  contrastado contra la documentación de la versión vigente.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
