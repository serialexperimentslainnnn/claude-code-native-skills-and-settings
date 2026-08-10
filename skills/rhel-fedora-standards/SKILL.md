---
name: rhel-fedora-standards
description: Red Hat family specifics - RHEL, CentOS Stream, Fedora, AlmaLinux, Rocky. Use when running dnf5 or dnf5daemon, dnf versionlock, dnf needs-restarting, dnf-automatic or dnf system-upgrade, editing .repo files in /etc/yum.repos.d, enabling EPEL, COPR or RPM Fusion, writing an RPM .spec with rpmbuild or mock, rpm-ostree, bootc upgrade/switch/rollback and image mode for RHEL, bootc-image-builder, Fedora Atomic or Silverblue, subscription-manager, Red Hat Insights or Satellite/Foreman, leapp preupgrade for a major in-place upgrade, grubby and kdump, tuned profiles, cockpit, authselect, AppStream and modularity, or choosing between RHEL, CentOS Stream, AlmaLinux and Rocky lifecycles and EUS/ELC/ELS entitlements.
---

# Estándares de la familia Red Hat (RHEL, CentOS Stream, Fedora, AlmaLinux, Rocky)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **lo que es particular de la familia Red Hat** y no vale igual en Debian/Ubuntu: elección
de distribución dentro de la familia y sus ciclos de vida, `dnf5` y el modelo RPM, repositorios y
sus riesgos, construcción de paquetes propios, el paradigma de **imagen** (`rpm-ostree`, `bootc`,
image mode), suscripciones y derechos, actualizaciones de versión mayor (`leapp`,
`dnf system-upgrade`), y las piezas que la familia trae de serie (SELinux, firewalld, `tuned`,
`cockpit`, `podman`, `grubby`, `kdump`, `authselect`).

Triggers: `dnf5`, `dnf5daemon`, `/etc/dnf/dnf.conf`, `/etc/yum.repos.d/*.repo`, `dnf versionlock`,
`dnf needs-restarting`, `dnf-automatic`, `dnf system-upgrade`, `dnf offline`, `dnf module`,
`rpm -q`, `.spec`, `rpmbuild`, `mock`, `rpmlint`, `%post`/`%files`, `epel-release`, `copr`,
`rpmfusion`, `rpm-ostree`, `ostree`, `bootc`, `bootc upgrade`, `bootc switch`, `bootc rollback`,
`bootc-image-builder`, `Containerfile` con `rhel-bootc`, Silverblue/Atomic,
`subscription-manager`, `rhc`, `insights-client`, Satellite/Foreman, `leapp preupgrade`,
`leapp upgrade`, `grubby`, `kdump`/`kexec`, `tuned-adm`, `cockpit`, `authselect`, `AppStream`,
"¿Rocky o Alma?", "¿CentOS Stream vale para producción?", "el sistema quedó irreparable tras añadir
un repo".

**Principio rector**: **en esta familia, la mayoría de los sistemas irreparables se rompieron por
un repositorio, no por un bug.** Mezclar repos de terceros que reemplazan paquetes base es la causa
número uno de un host que ya no puede actualizarse ni reinstalarse limpiamente, y `--nobest` /
`--skip-broken` es el gesto que convierte un conflicto visible en una corrupción silenciosa. El
segundo principio: **el ciclo de vida es una decisión de arquitectura, no un detalle de
instalación** — RHEL, Stream, Alma y Rocky no son intercambiables aunque los paquetes se parezcan.

**Frontera con `linux-administration-standards`**: aquella skill es **agnóstica de distribución** y
manda en todo lo que vale igual en Debian — systemd y sus unidades, journald, cgroups v2,
`nsswitch`, montajes, gestión de red del host, hora, y el **método de diagnóstico por capas**. Esta
skill **no lo repite**: lo desarrolla donde la familia Red Hat difiere (`dnf` en vez de `apt`,
`grubby` en vez de `update-grub`, `firewalld` en vez de `ufw`, SELinux en vez de AppArmor, `tuned`,
`kdump`). Si la pregunta empieza por "¿cómo escribo esta unidad?", es de allí; si empieza por
"¿qué repo?" o "¿qué versión de RHEL?", es de aquí.

**No aplica**: ver `linux-administration-standards` (día a día agnóstico del SO, systemd, journald,
recursos, diagnóstico del host), `onprem-standards` (paraguas de plataforma: hardware, plano
OOB/BMC, hipervisor, inventario y cadencia de flota; sus invariantes de §1.3 mandan),
`selinux-standards` (**todo el MAC**: `enforcing` es aquí un no-negociable de la familia, pero el
diagnóstico de AVC, `semanage`, `restorecon`, booleanos, `container-selinux`, `udica` y la política
propia son suyos), `linux-hardening-standards` (baseline CIS/STIG/ANSSI/**CCN-STIC**, OpenSCAP con
SSG, `sysctl.d`, `sshd_config`, auditd, `sudoers`, `pam_faillock`, sandboxing de unidad, y
`dnf-automatic` **como control de seguridad** — aquí `dnf-automatic` solo como mecanismo de
actualización y su política de reinicio), `networking-standards` (**el diseño** de red y de la
política de firewall entre zonas; **aquí solo el mecanismo `firewalld`**: qué zona, cómo se asigna
una interfaz y por qué no se mezcla con `nftables` a pelo),
`vulnerability-management-standards` (triaje de CVE con CVSS/EPSS/KEV, SLA, VEX y seguimiento de
EOL — **ellos priorizan el parche; aquí de dónde sale, cómo se aplica y qué ciclo de vida lo
entrega**), `iac-standards` (Ansible como herramienta y su CI: lo repetible se automatiza allí),
`bash-linux-scripting-standards` (los scripts que ejecuten cualquier cosa de aquí),
`kubernetes-standards` (OpenShift/OKD y el cluster; **aquí el nodo y su modo imagen**),
`container-runtime-security-standards` (seguridad del runtime de contenedor),
`observability-standards`, `identity-access-management-standards` (IdP y federación; el
`subscription-manager` y los derechos de Red Hat son de aquí),
`windows-server-ad-standards` (el bosque y el dominio; **la integración del host con AD —
`realmd`, `sssd`, `authselect`, `adcli`— es de `linux-administration-standards` como configuración
del sistema**, y esta skill solo aporta que en esta familia el stack PAM se toca **con
`authselect`**, nunca editando `/etc/pam.d` a mano, porque el contenido SSG/CIS lo asume),
`grc-compliance-standards`, `homelab-standards` (laboratorio personal: la frontera es el rigor),
`bcdr-standards`, `incident-response-forensics-standards`, `perl-standards` (el intérprete
de Perl del sistema y sus paquetes RPM son de aquí — **PROHIBIDO tocarlos o instalar módulos sobre
ellos: rompe herramientas del propio SO**—; el Perl **de aplicación**, con su `perlbrew`/`plenv`,
`cpanfile` y su criterio de código, es suyo).

Además:
`podman-systemd-containers-standards` (Podman, Quadlet, rootless, `podman auto-update`
— **frontera precisa**: aquí solo que **Podman es el default de la familia y Docker la excepción a
justificar**, y las *logically bound images* de bootc; el resto es suyo),
`linux-storage-standards` (LVM, Stratis, XFS y su tuning; aquí solo que XFS es el
filesystem por defecto de RHEL y **no se puede reducir**), `backup-recovery-standards`,
`ha-clustering-standards` (RHEL HA Add-on, Pacemaker/Corosync, `pcs`),
`libvirt-kvm-standards`, `proxmox-ve-standards`, `zfs-standards` (y de paso el motivo por
el que ZFS no es una opción de primera en esta familia — DKMS fuera de árbol contra un kernel que
se actualiza solo), `dns-standards`, `firewall-policy-standards`, `vpn-standards`,
`network-troubleshooting-standards`.

## 2. Decisiones por defecto

> Verificar la última versión y **toda** fecha de EOL por web antes de fijarla en un proyecto real
> (§8). Los datos son de **agosto 2026** y las fechas de ciclo de vida cambian por decisión
> comercial, no por calendario técnico.

### 2.1 Qué distribución de la familia

| Caso | Elección | Motivo / matiz |
|---|---|---|
| Producción con soporte contractual, certificaciones de ISV o requisito de auditoría | **RHEL 10** (última minor **10.2**, GA de la 10.0 el 20-may-2025) | Es lo único con SLA, certificación de hardware/ISV, Insights y una ruta de soporte extendido. RHEL 9 (última **9.8**) sigue plenamente vivo y es la elección conservadora si tu stack aún no está certificado en 10 |
| Producción sin contrato, quiero "RHEL gratis" y **compatibilidad de aplicación** | **AlmaLinux 10** (10.2; GA 27-may-2025) | Objetivo **ABI-compatible**, no clon binario: construye desde fuentes de CentOS Stream y **se reserva parchear bugs que Red Hat aún no ha corregido**. Ventaja concreta y decisiva en hardware viejo: **es el único que publica build para `x86-64-v2`** (Nehalem+), mientras RHEL 10 y Rocky 10 exigen **`x86-64-v3`** (Haswell+, ~2013) |
| Producción sin contrato y necesito que se comporte **exactamente** como RHEL | **Rocky Linux 10** (10.2; GA 11-jun-2025) | Objetivo declarado **bug-for-bug**: si es un bug en RHEL, es el mismo bug en Rocky. Es lo que quieres si validas contra comportamiento de RHEL. Contrapartida: `x86-64-v3` obligatorio, y hay software de terceros que ha dejado de soportarlo (cPanel ≥134) |
| Desarrollo, laboratorio, estación de trabajo, upstream | **Fedora 44** (28-abr-2026) | Es el upstream real de la familia: lo que aquí es normal será RHEL dentro de años. **Ciclo de ~13 meses**: Fedora 43 muere el 9-dic-2026 y Fedora 42 ya está EOL (27-may-2026). **No es una distro de servidor de larga vida** y ponerla en producción es aceptar un salto de versión mayor cada seis meses |
| Quiero ver lo que traerá la próxima minor de RHEL / desarrollar contra ella | **CentOS Stream 10** (12-dic-2024, soporte hasta 31-may-2030; Stream 9 hasta 31-may-2027) | **Es upstream de RHEL, no un derivado**: va *por delante* de la minor publicada. Sirve para desarrollo, CI y contribución. **Usarlo "como si fuera RHEL"** significa aceptar cambios continuos sin minors estables, sin certificación de ISV y sin EUS/ELC — decisión legítima solo si es consciente y está escrita |
| Necesito RHEL de verdad, gratis, en pocos hosts | **Red Hat Developer Subscription for Individuals**: hasta **16 sistemas**, renovación **anual** | Verificado ago-2026: Red Hat admite explícitamente uso productivo de pequeña escala en esos 16. Existe además **RHEL for Business Developers** (jul-2025) hasta **25 instancias solo dev/test**. **Riesgo real a documentar**: hay lecturas de *compliance* que lo tratan como conveniencia y no como derecho de producción — si la empresa audita licenciamiento, ponlo por escrito antes |

**Ciclo de vida de RHEL — el modelo vigente** (verificado ago-2026 en `access.redhat.com`):
- **Full Support** (~5 años: errata de seguridad y bugs, habilitación de hardware, minors nuevas) →
  **Maintenance Support** (~5 años: solo errata, sin funcionalidad ni hardware nuevo, **sin minors
  nuevas**) → **Extended Life Phase** (acceso al contenido ya publicado; **sin parches**).
- **ELC (Extended Life Cycle)** **sustituye desde RHEL 9 a EUS, Enhanced EUS y E4S**: 6 años desde
  la GA de determinadas **minors pares** (9.2, 9.4, 9.6, 9.8, 9.10 / 10.2, 10.4, 10.6, 10.8,
  10.10). Los add-ons **Long-Life (LL)** renuevan anualmente por encima de eso. **Consecuencia
  práctica**: si necesitas quedarte en una minor, **quédate en una par**, o no tendrás stream de
  errata.
- **RHEL Extended Life Cycle, Premium** (desde 2-abr-2026): hasta **14 años** de ciclo, con
  cobertura de CVE Critical, Important y Moderate con **CVSS ≥ 7.0**.
- Fechas de referencia (verificadas en `endoflife.date`, **contrástalas con Red Hat**): RHEL 8 fin
  31-may-2029 (ext. 2033), RHEL 9 fin 31-may-2032 (ext. 2036), RHEL 10 fin 31-may-2035 (ext. 2039).

### 2.2 Herramientas y mecanismos

| Ámbito | Por defecto | Motivo / matiz |
|---|---|---|
| Gestor de paquetes | **`dnf5`** (upstream 5.4.2.1, may-2026). Es **el default desde Fedora 41**; `/usr/bin/dnf` es symlink a `dnf5` y DNF4 ya no está en el conjunto base | Escrito en C++ con `libdnf5`: más rápido, sin dependencia obligatoria de Python. **Lo que cambia de verdad** (§3.2): API Python reescrita, plugins distintos, `--downloaddir` → `--destdir`, y **las transacciones de dnf4 y dnf5 no se ven entre sí** |
| Actualización automática | **`dnf-automatic`** con `apply` en tiers bajos y `download-only` + ventana en producción | **No sabe reiniciar**: no hay soporte nativo de reboot. La política de reinicio se construye aparte con `dnf needs-restarting -r` en un `ExecStartPost=` del override, con ventana horaria. El uso de `dnf-automatic` **como control de seguridad medible** es de `linux-hardening-standards` |
| Fijar versiones | **`dnf versionlock`** para lo que no puede moverse (kernel de un driver certificado, agente de un ISV), **con dueño y fecha de caducidad** | Un `versionlock` sin fecha es un CVE con fecha de caducidad indefinida. Se audita cada trimestre |
| Repositorios de terceros | **Ninguno por defecto.** El que entre, entra con **prioridad**, `includepkgs`/`excludepkgs` acotado, **firma GPG obligatoria** (`gpgcheck=1`, `repo_gpgcheck=1` donde exista) y justificación escrita | Ver §5. Un repo de terceros sin acotar que reemplace paquetes base es la vía directa al sistema irreparable |
| Contenedores | **Podman** (rootless por defecto) + **Quadlet** bajo systemd | Es el default de la familia: sin daemon, sin root, integrado con systemd y SELinux. Docker es la **excepción a justificar** (dependencia dura de una herramienta que solo hable con el socket de Docker). El detalle es de `podman-systemd-containers-standards` |
| MAC | **SELinux `enforcing`, siempre. No negociable** | Ver §5 y `selinux-standards`. Desactivarlo es la prohibición número uno de esta familia |
| Firewall de host | **`firewalld`** con zonas, no `nftables` a pelo | Es lo que asume el resto del ecosistema de la familia (`podman`, Cockpit, roles de Ansible certificados). Mezclar reglas `nft` directas con firewalld produce rulesets que se pierden en el próximo `reload`. El **diseño** de la política es de `networking-standards` |
| Rendimiento | **`tuned`** con perfil explícito por rol (`throughput-performance`, `virtual-guest`, `latency-performance`…) elegido y **versionado**, no el que dejó el instalador | `tuned-adm active` en el inventario. Un perfil por defecto en un rol equivocado es la causa silenciosa de latencias raras. Cambiar `sysctl` a mano por debajo de `tuned` produce config que se revierte sola |
| Gestor de arranque | **`grubby`** para parámetros de kernel y entrada por defecto | Es la interfaz correcta en esta familia (`grubby --update-kernel=ALL --args=...`), y funciona igual en BIOS/UEFI y en sistemas ostree. Editar `/etc/default/grub` + regenerar es el camino largo y propenso a error |
| Volcado de kernel | **`kdump` habilitado y probado** en servidores físicos y VM que importen | Un pánico de kernel sin `vmcore` es un incidente sin causa raíz posible. Reservar memoria (`crashkernel=`) y **probar el volcado** (`echo c > /proc/sysrq-trigger` en ventana): un kdump no probado no existe |
| Consola de gestión | **`cockpit`** solo donde aporte y **nunca expuesto a red de usuario o a Internet** | Útil para hosts sueltos, diagnóstico rápido y gente que no vive en la terminal. **No sustituye a la automatización**: lo que se hace por Cockpit es un cambio manual no capturado (*snowflake*) salvo que se replique en el código |
| Stack PAM y NSS | **`authselect`** exclusivamente | Verificado: el contenido SSG/CIS de reglas PAM **asume authselect y no se aplica si el stack se editó por otros medios**. En RHEL 10, además, los comandos kickstart `auth`/`authconfig` fueron **eliminados** |
| Kernel | **El de la distro, y solo el de la distro** | **En esta familia no existe `kernel-lt` ni `kernel-ml` oficiales** (eso es ELRepo, un tercero). Variantes legítimas: `kernel`, `kernel-rt` (tiempo real, con su add-on), `kernel-debug` (**cuidado**: infla la detección de "reboot required" de `tracer`/Satellite), `kernel-64k` (páginas de 64K en aarch64). Un kernel de tercero rompe soporte, SELinux, kABI de drivers certificados y Secure Boot |

## 3. Estructura y convenciones

### 3.1 RPM, AppStream y modularidad

- **AppStream vs. BaseOS**: BaseOS es el SO con el ciclo de vida de la major; AppStream son los
  componentes de usuario, **cada uno con su propio ciclo, que puede ser más corto que el de la
  distro**. Ese es el detalle que se olvida: tener RHEL 10 soportado hasta 2035 no significa tener
  ese lenguaje o esa base de datos soportados hasta 2035. **Se inventaría el EOL por componente**,
  no por SO (invariante de `onprem-standards`: nada sin fecha de fin de vida).
- **Modularidad: se acabó.** Verificado ago-2026: en **RHEL 10 la modularidad está deprecada, no se
  distribuye contenido modular** y `dnf module` emite aviso de deprecación; los Application Streams
  se instalan como RPM normales. El kickstart `module` está deprecado y Anaconda deprecó su soporte
  de modularidad. **Criterio**: no diseñes nada nuevo sobre módulos; lo que quede de RHEL 8/9 con
  `dnf module enable` es deuda a retirar en la migración, y es una de las cosas que más ruido da en
  `leapp`.
- **Nombre completo de paquete siempre en automatización**: `nombre-version-release.arch`. Un
  playbook que instala `nginx` "a secas" instala cosas distintas en 9 y en 10.
- **`dnf history`** es la herramienta de vuelta atrás (`dnf history undo <id>`), y es la razón por
  la que las transacciones importan: se planifican como transacción única, no como diez `install`
  sueltos. Ojo (§3.2): el historial de dnf4 y el de dnf5 **no son el mismo**.

### 3.2 `dnf5`: lo que realmente cambia respecto a dnf4

Verificado ago-2026 (dnf5 5.4.2.1). Esto es lo que rompe scripts existentes:

- **La API de Python se reescribió entera**: hay que portar a `python3-libdnf5`; **no es compatible
  a nivel de fuente** con el módulo `dnf` de DNF4. Cualquier automatización que importe `dnf` en
  Python se rompe.
- **Plugins**: no son compatibles (API distinta, los viejos eran Python). Lo esencial vive en
  `dnf5-plugins`. En una instalación por defecto de Fedora 44 cargan `builddep`, `changelog`,
  `config-manager`, `copr`, `needs_restarting`, `repoclosure`, `repomanage` y `reposync`.
  **Descartados a propósito**: `generate_completion_cache` y `migrate`. Verifica el plugin concreto
  que uses **antes** de migrar, no después.
- **Opciones que cambian**: `--downloaddir` (dnf4) → **`--destdir`** (dnf5); dnf5 **rechaza**
  `--downloaddir`. `dnf offline-upgrade` **ya no existe** como subcomando → `dnf upgrade --offline`
  seguido de `dnf offline reboot`.
- **Los historiales de transacción no se comparten**: paquetes instalados como dependencia por uno
  aparecen como instalados por el usuario para el otro, lo que impide su autoeliminación. Si un
  host arrastra ambos, se limpia el estado, no se convive.
- **Transacciones offline**: `dnf upgrade --offline` / `dnf5 system-upgrade download` dejan la
  transacción almacenada (`/usr/lib/sysimage/libdnf5/offline`) y se aplican con `dnf5 offline
  reboot` en un entorno mínimo. Subcomandos: `status`, `log`, `clean`, `--poweroff`. **Es el modo
  correcto** para actualizaciones grandes: menos interferencia con procesos en marcha.
- **`dnf5daemon`** expone la funcionalidad por D-Bus para clientes gráficos y Cockpit. Verificado:
  **en Fedora 44 el backend de PackageKit pasó a DNF5** — consecuencia operativa concreta: si
  GNOME Software prepara una transacción offline y por CLI dejaste otro estado de repos, la
  transacción falla. **Una fuente de transacciones por host**.

### 3.3 Repositorios: modelo mínimo y seguro

- Cada `.repo` en `/etc/yum.repos.d/` declara: `enabled`, `gpgcheck=1`, `gpgkey` (clave
  **verificada por huella**, no descargada a ciegas), `priority` si hay riesgo de solape, y
  `includepkgs=`/`excludepkgs=` para **acotar qué puede reemplazar**. Todo el conjunto va
  versionado en el repo de IaC (`iac-standards`).
- **EPEL**: el repo comunitario de facto. **Riesgo real y concreto**: contiene paquetes que pueden
  reemplazar o entrar en conflicto con AppStream, y **no tiene compromiso de estabilidad ni de
  ciclo de vida**; un paquete puede desaparecer o saltar de versión mayor. **Se habilita acotado**
  (`--enablerepo=epel` puntual, o `includepkgs`), nunca "abierto y permanente" en un servidor que
  importa.
  - **EPEL 10 cambió de modelo**: hay **repos por minor** de RHEL 10 (`epel10.N`), con `epel10`
    actuando como rama líder (estilo rawhide, alineada con CentOS Stream 10). Los paquetes se
    arrastran de una minor a la siguiente. **No hay traspaso automático desde `epel9`**: los
    conjuntos de paquetes de EPEL 9 y EPEL 10 se solapan pero ninguno es subconjunto del otro —
    **verifica que tus paquetes existen en EPEL 10 antes de planificar la migración**, es un
    bloqueante habitual y sorprendente.
- **COPR**: repos de construcción personal. Es **build de un individuo**, sin revisión ni garantía.
  Vale para probar y para laboratorio; en producción exige dueño, pin de versión, plan de salida y
  aceptación de riesgo por escrito. Nunca para paquetes del sistema base.
- **RPM Fusion**: multimedia y códecs no libres. Es **de escritorio**, no de servidor. Verificado
  ago-2026: soportado en Fedora 44; y **VLC y LAME ya vienen en los repos principales de Fedora
  44**, así que hace falta para menos cosas que antes.
- **La regla que evita el 90% de los desastres**: un repo de tercero **jamás** reemplaza paquetes de
  BaseOS/AppStream. Si lo hace, o se acota con `excludepkgs` en el repo base, o no entra. Y si ya
  entró: `dnf distro-sync` con el repo desactivado, **antes** de que se acumule.

### 3.4 Construir RPM propio

**Cuándo sí**: software interno que debe instalarse en la ruta del sistema, integrarse con systemd,
declarar dependencias reales, tener contexto SELinux correcto y ser desinstalable y auditable
(`rpm -qa`, `rpm -V`). Un `.tar.gz` descomprimido en `/opt` por un script no es ninguna de esas
cosas.

**Cuándo no**: si la aplicación puede vivir en un **contenedor**, va en contenedor. Empaquetar en
RPM una aplicación con su propio ecosistema de dependencias (Node, Python con ruedas, JVM con
*fat jar*) es trabajo recurrente que no se amortiza.

Convenciones mínimas:
- `.spec` versionado en el repo del proyecto, con `Source0` reproducible, `%changelog` real,
  dependencias declaradas (`Requires`, `BuildRequires`) y **nada de lógica pesada en `%post`**.
- **`mock` para toda construcción destinada a producción**: chroot limpio, contra el conjunto de
  repos exacto del destino. Construir en el portátil del desarrollador introduce
  `BuildRequires` implícitos que no existen en el destino.
- `rpmlint` en CI como gate; firma GPG del paquete y del repo interno (la custodia de la clave la
  fija `cryptography-pki-standards`).
- La ejecución de todo esto en pipeline es de `cicd-standards`; el repo interno de artefactos
  también.

### 3.5 Modo imagen: `rpm-ostree` y `bootc`

**El cambio de paradigma**: el sistema operativo deja de ser el resultado acumulado de N
transacciones de paquetes y pasa a ser una **imagen de contenedor versionada, firmada y
reproducible**, que se despliega en A/B con rollback. Se construye con un `Containerfile`, se
publica en un registry y se despliega con `bootc`.

Verificado ago-2026:
- **`bootc` sustituye a `rpm-ostree`**. Es explícito: en sistemas en modo imagen **no está
  soportado usar `rpm-ostree` para instalar contenido o hacer cambios**, y el desarrollo upstream
  de `rpm-ostree` se ha desplazado a bootc/dnf — seguirá recibiendo correcciones importantes
  (sobre todo de seguridad), pero **funcionalidad nueva de cliente es improbable**. Upstream de
  bootc: **v1.16.6** (28-jul-2026, vía `api.github.com`).
- **RHEL image mode** está documentado como característica de producto en RHEL 9 y 10. **Desde RHEL
  10.0 el modo imagen sustituye a RHEL image builder para imágenes de edge** (los contenedores
  arrancables son obligatorios ahí), y la imagen base es `registry.redhat.io/rhel10/rhel-bootc`.
  **Ojo con el estado de GA por pieza**: la creación y despliegue de ISO con `bootc-image-builder`
  es **Technology Preview**, y depende del comando kickstart `%ostreecontainer`, también TP.
  **Verifica el estado exacto para tu versión antes de comprometer un despliegue** (§8).
- **Operación**: `bootc upgrade` (actualiza la imagen que se sigue) y `bootc switch <imagen>`
  (cambia la imagen seguida) tienen **el mismo efecto** salvo por qué imagen se rastrea; ambos
  preservan `/etc` y `/var` (claves SSH del host, home). Los cambios se **preparan** y no se
  aplican hasta reiniciar salvo `--apply`. Extras verificados: `--download-only`,
  `upgrade --from-downloaded`, y `--apply --soft-reboot=required|auto`. **Fijar por digest
  convierte `bootc upgrade` en no-op** — con pin, se actualiza con `switch`.
- **Logically bound images**: enlaces simbólicos en `/usr/lib/bootc/bound-images.d` apuntando a
  ficheros Quadlet `.image`/`.container`; bootc las descarga en `upgrade`/`switch`, conserva las de
  la instalación de rollback y recoge basura. Permite actualizar la app sin rehacer la imagen del
  SO y viceversa. Limitación verificada: usan el pull secret global (`/etc/ostree/auth.json`);
  **`PullSecret` por imagen aún no está soportado**.
- **Trampas de migración verificadas, que muerden**:
  - **`/opt` es un enlace a `/var/opt`** en sistemas ostree/bootc. Software que instala en `/opt`
    necesita instalarse bajo `/usr` y crear el enlace con `/usr/lib/tmpfiles.d`.
  - ***Identity drift*** al convertir un sistema RHEL for Edge existente a modo imagen: los UID/GID
    del contenedor pueden no coincidir con los del sistema original, rompiendo acceso SSH y
    propiedad de ficheros en `/var`. Los sistemas en modo imagen usan `altfiles`, con usuarios en
    `/usr/lib/passwd` y grupos en `/usr/lib/group`.
  - Sistemas RHEL for Edge **9.6 o superior** desplegados con el *simplified installer* se pueden
    convertir a modo imagen **sin reinstalar**.
- **Cuándo vale la pena frente al modo paquete**: flota **homogénea y numerosa**, edge, nodos de
  cluster, cualquier caso donde la reproducibilidad y el rollback atómico valgan más que la
  flexibilidad. **Cuándo no**: hosts únicos y muy personalizados, cargas que exigen cambiar el SO
  en caliente, o un equipo que no tiene ya una pipeline de imágenes con registry, firma y
  promoción. **El modo imagen no reduce trabajo: lo mueve de la noche del incidente a la pipeline
  de build.** Si esa pipeline no existe, primero se construye.
- **Fedora Atomic / Silverblue / Kinoite / CoreOS**: el mismo paradigma en el upstream, y el sitio
  correcto para aprenderlo antes de llevarlo a RHEL. Verificado: **OpenShift transita a bootc a lo
  largo de 2026** (RHCOS usa hoy contenedores nativos de rpm-ostree, la tecnología que inspiró
  bootc).

### 3.6 Actualizaciones de versión mayor

**No se improvisan. Se ensayan, en un clon del host, con revert probado y ventana.** Es la
operación con mayor probabilidad de dejar un sistema en un estado no soportado.

- **RHEL: `leapp`.** Verificado: **solo entre majors consecutivas** (8→9, 9→10). RHEL 8→10 son
  **dos** upgrades encadenados. Las rutas soportadas se publican **por minor concreta** (tabla 1.1
  de la guía oficial), y se actualizan con cada minor: **consúltala, no la deduzcas**. Flujo:
  `leapp preupgrade` (inhibidores y informe) → resolver **todo** → `leapp upgrade` → reiniciar.
  Detalles verificados que importan:
  - **`leapp` deja SELinux en `permissive` durante el proceso; restaurar `enforcing` a mano
    después** (y planificar el reetiquetado — `selinux-standards`).
  - Sin RHSM o con RHUI: `--no-rhsm`. Con derechos extendidos: `--channel eus|aus` — **con la
    llegada de ELC, confirma el nombre del canal vigente antes de usarlo** (§8).
  - PAYG con RHUI: **solo la última ruta disponible** está soportada.
  - Con SAP HANA, guía específica; no se extrapola.
  - **Los repos de terceros son la primera fuente de inhibidores**: EPEL, COPR y drivers de ISV se
    resuelven **antes**, no durante.
- **Fedora: `dnf system-upgrade`**, una versión cada vez.
  `dnf upgrade --refresh` → `dnf5 system-upgrade download --releasever=NN` →
  `dnf5 system-upgrade reboot`, y luego `dnf5 offline status`/`log`. Ya **no hace falta**
  `dnf-plugin-system-upgrade` (era la era DNF4). Verifica antes qué repos de terceros aún no tienen
  build para la release destino: **es la causa habitual de un upgrade que no resuelve**.
- **Modo imagen**: el upgrade mayor deja de ser una operación in-place y pasa a ser
  `bootc switch` a una imagen basada en la nueva major, con rollback trivial. Es el argumento
  operativo más fuerte a favor del modo imagen.
- **Alternativa siempre sobre la mesa: reinstalar.** Si el host es reconstruible desde código
  (invariante de `onprem-standards`), reinstalar limpio suele ser más rápido, más barato y más
  predecible que un in-place. El in-place se justifica cuando hay estado local que no se puede
  reconstruir — y entonces la pregunta real es por qué ese estado no está respaldado.

### 3.7 Suscripciones, derechos y gestión de flota

- **`subscription-manager`** (o `rhc` para conectar el host) es la puerta a los repos. Un host RHEL
  sin registrar **no recibe parches de seguridad**: monitorizar el estado del registro y de los
  derechos es un requisito de operación, no una tarea administrativa.
- **Satellite / Foreman** (alto nivel): repositorios espejados, **content views y lifecycle
  environments** — la promoción de un conjunto exacto de paquetes de dev→prod, que es lo que hace
  reproducible el parcheo de una flota. Es la respuesta correcta a "cómo garantizo que todos los
  hosts recibieron el mismo conjunto de paquetes". Su función **Tracer** decide qué servicios
  reiniciar tras un update (misma idea que `dnf needs-restarting`; misma trampa conocida:
  `kernel-debug` instalado deja el host marcado como "reboot required" para siempre).
- **Insights**: análisis y recomendaciones a partir de telemetría enviada a Red Hat. **Decisión
  consciente**: envía datos del host fuera. Se activa si el valor (detección de CVE, deriva de
  configuración, riesgos conocidos) compensa, con revisión de privacidad y de política de datos
  (`privacy-engineering-standards`/`grc-compliance-standards`), no por defecto.
- **Derechos y ciclo**: si tu plan es "quedarnos en esta minor", tiene que ser una minor **par**
  (ELC) y con el add-on contratado. Un host anclado a una minor sin derecho ELC está sin errata:
  es un hallazgo, no una estrategia.

## 4. Calidad: qué se valida antes de tocar

> Los gates genéricos (validadores antes de recargar, smoke test, sesión de rescate) son de
> `linux-administration-standards` §4 y **también aplican aquí**. Lo siguiente es lo específico
> de la familia.

1. **`dnf check` y `rpm -Va` limpios** como línea base antes de cualquier operación grande. Un
   sistema con dependencias rotas no se actualiza: se arregla primero.
2. **Ensayo de transacción sin aplicar**: `dnf upgrade --assumeno` / `dnf --setopt=tsflags=test` y
   **lectura del plan**. Si el plan degrada, elimina o sustituye paquetes base, se para. **Un plan
   que solo pasa con `--nobest` o `--skip-broken` es un plan que no se ejecuta** (§7).
3. **`leapp preupgrade` con informe resuelto al 100%** antes de `leapp upgrade`. Los avisos de alta
   severidad no se "aceptan": se resuelven o se cancela el upgrade.
4. **Ensayo en clon**: cualquier upgrade mayor, cambio de kernel o cambio de modo (paquete→imagen)
   se prueba primero sobre una copia del host real, no sobre un host "parecido".
5. **`rpmlint` + `mock` en CI** para todo RPM propio; **firma verificada** antes de publicar.
6. **Modo imagen**: la imagen se construye en CI, se **firma** y se verifica antes de desplegar; se
   despliega primero en un canario; el **rollback se prueba** (`bootc rollback` + reinicio) antes
   de considerar el despliegue completo. Escaneo de la imagen (`oscap-im` para bootc, según
   `linux-hardening-standards`) como gate.
7. **Post-parche**: `dnf needs-restarting -r` (y `-s` para servicios) decide el reinicio; el
   resultado se registra. Conocido y verificado: la herramienta tiene falsos positivos y falsos
   negativos documentados — **ante duda tras un cambio de kernel o glibc, se reinicia**.
8. **Post-upgrade de RHEL**: verificar **`getenforce` → `Enforcing`** (leapp lo dejó en
   `permissive`), estado de repos, `dnf check`, servicios críticos y el arranque completo con un
   reinicio adicional.

## 5. Seguridad específica de la familia

- **SELinux `enforcing`. Siempre. En todos los hosts.** Es la ventaja de seguridad diferencial de
  esta familia y desactivarlo la anula por completo. Matiz verificado que hay que conocer:
  `SELINUX=disabled` en `/etc/selinux/config` está **deprecado desde RHEL 8 y el soporte de kernel
  se eliminó en RHEL 9.0** — el sistema arranca con SELinux habilitado **y sin política**, que es
  el peor estado posible (ni protección ni claridad). Para depurar: `permissive` **con fecha de
  fin**. Todo lo demás, en `selinux-standards`.
- **Cadena de suministro del paquete**: `gpgcheck=1` sin excepciones, claves GPG verificadas por
  **huella** contra la fuente oficial, y `repo_gpgcheck=1` donde el repo lo soporte. Un
  `gpgcheck=0` en un `.repo` es una puerta abierta a ejecución de código como root.
- **Repos de terceros como superficie de ataque, no solo de estabilidad**: COPR es un build de una
  persona; EPEL tiene revisión comunitaria pero sin compromiso; un mirror no oficial es un
  atacante con root en tu flota. Se pinan, se acotan y se auditan.
- **Modo imagen y firma**: si adoptas bootc, la imagen del SO es un artefacto de cadena de
  suministro de primer nivel — **firma (cosign/Sigstore), verificación de procedencia y pin por
  digest** son obligatorios, igual que para cualquier imagen de contenedor
  (`kubernetes-standards`/`cicd-standards`). Un `bootc switch` a un tag mutable de un registry sin
  verificación es un compromiso de root remoto por diseño.
- **Insights y telemetría**: dato que sale del perímetro. Decisión documentada, no por defecto.
- **Firewalld y zonas**: la zona por defecto de una interfaz nueva decide su exposición. Se asigna
  explícitamente; `public` "porque venía así" en una interfaz de gestión es un hallazgo. El diseño,
  en `networking-standards`.
- **Cockpit**: es una consola de administración con privilegios sobre HTTPS. Solo accesible desde
  la red de gestión, detrás de bastión/VPN, con autenticación fuerte. Nunca en Internet.
- **CVE de las herramientas de esta familia**: `sudo` **CVE-2025-32463** (escalada local a root vía
  `chroot`) afecta a toda la familia y `sudo` se ejecuta en cada host administrado: parcheo
  prioritario, no ventana mensual. El triaje formal, en `vulnerability-management-standards`.

## 6. Operabilidad

- **`kdump` probado** y `vmcore` con destino con espacio, retención y monitorización. Un pánico sin
  volcado es una causa raíz que no se encontrará nunca.
- **`tuned-adm active` en el inventario** de cada host, junto al rol. Un perfil equivocado se
  manifiesta como latencia inexplicable meses después.
- **Estado de suscripción y de repos monitorizado**: host no registrado, repo deshabilitado o
  `versionlock` caducado son alertas, no descubrimientos de auditoría.
- **`dnf history` y el log de transacciones reenviados** al agregador: "qué cambió en este host y
  cuándo" debe responderse sin entrar en el host (`observability-standards`).
- **Métrica de "reboot pendiente"** por host, con antigüedad. Un parque con parches aplicados y sin
  reiniciar es un parque sin parchear (§4.7).
- **XFS es el filesystem por defecto de RHEL y no se puede reducir**: el dimensionado de un LV con
  XFS es una decisión de ida. El diseño de almacenamiento es de `linux-storage-standards`.
- **RHEL 10 eliminó Xorg** (queda Xwayland; el protocolo X11 sigue funcionando para la mayoría de
  clientes) y **Motif**. Si algo de tu stack depende de un servidor X real, es un bloqueante de
  migración que hay que detectar en el `preupgrade`, no en producción.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Errata de seguridad: continua/automática en tiers bajos, semanal orquestada en producción, con
  política de reinicio.
- Minors de RHEL: se adoptan dentro de la ventana de soporte de la minor anterior; **si te anclas,
  ánclate a una minor par con derecho ELC**.
- Fedora: **cada versión, sin saltar**, y con el salto planificado — el ciclo es de ~13 meses y las
  versiones EOL no reciben nada. Fedora en un servidor es una obligación de upgrade semestral
  aceptada por escrito.
- Repos de terceros, `versionlock` y excepciones: **auditoría trimestral con dueño y fecha**.
- Major: se planifica con **12 meses** de antelación, con ensayo, y contemplando "reinstalar" como
  alternativa legítima al in-place.

**PROHIBIDO**
- ❌ **Desactivar SELinux** (o dejarlo en `permissive` sin fecha de fin) para que algo funcione.
- ❌ **Mezclar repositorios incompatibles**: EPEL/COPR/RPM Fusion/ELRepo/mirrors de terceros
  reemplazando paquetes de BaseOS o AppStream. Repos sin `priority`, sin acotar y habilitados
  permanentemente en un servidor.
- ❌ **`--nobest`, `--skip-broken` o `--allowerasing` como costumbre.** Son herramientas de
  diagnóstico puntual; usarlas para "que la actualización pase" es cómo se fabrica un sistema
  irreparable.
- ❌ `gpgcheck=0`, o importar claves GPG sin verificar la huella contra la fuente oficial.
- ❌ Saltar de versión mayor en RHEL **sin `leapp`**, o ejecutar `leapp upgrade` con inhibidores
  de `preupgrade` sin resolver, o encadenar 8→10 en un solo salto.
- ❌ Dejar SELinux en `permissive` después de un `leapp` (lo deja así: se restaura y se verifica).
- ❌ Actualizar Fedora saltándose versiones, o mantener en producción una Fedora EOL.
- ❌ **Usar CentOS Stream como si fuera RHEL** sin entender que va por delante, no tiene minors
  estables, ni EUS/ELC, ni certificación de ISV — y sin dejarlo escrito como decisión.
- ❌ Instalar kernels de terceros (`kernel-lt`/`kernel-ml` de ELRepo) o módulos fuera de árbol sin
  aceptar por escrito la pérdida de soporte, de kABI certificada y de Secure Boot.
- ❌ Usar `rpm-ostree` para instalar contenido en un sistema en modo imagen (no está soportado), o
  hacer cambios manuales en un host bootc esperando que sobrevivan.
- ❌ Desplegar bootc desde un **tag mutable sin firma ni verificación de digest**.
- ❌ Adoptar modo imagen sin una pipeline de build, firma y promoción ya funcionando.
- ❌ Diseñar algo nuevo sobre **modularidad** (`dnf module`): deprecada y sin contenido en RHEL 10.
- ❌ Editar `/etc/pam.d/` a mano en vez de usar `authselect` (rompe el contenido SSG/CIS).
- ❌ Mezclar reglas `nft` directas con `firewalld` en el mismo host.
- ❌ `versionlock` sin dueño ni fecha de caducidad.
- ❌ Administrar hosts de producción por Cockpit como método habitual (cambio manual no capturado),
  o exponer Cockpit fuera de la red de gestión.
- ❌ Correr RHEL en producción sin registrar (sin errata) o con derechos caducados.
- ❌ Poner en producción una minor anclada **impar** esperando cobertura ELC.
- ❌ Ejecutar `rpmbuild` fuera de `mock` para paquetes destinados a producción.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, fecha, EOL o estado de GA, **búscalo — no lo recuerdes**. Y en
particular: **nunca leas versiones o fechas de GitHub del render HTML — usa `api.github.com` o los
feeds Atom.**

1. **Ciclo de vida de RHEL** en `access.redhat.com/support/policy/updates/errata`: fases, minors
   con ELC, y qué add-on cubre qué. Es contenido comercial y cambia sin previo aviso.
2. **Versión actual y EOL** de RHEL, Fedora, CentOS Stream, AlmaLinux y Rocky en `endoflife.date`
   **y** en la fuente del vendor. Verificado ago-2026: RHEL 10.2 / 9.8 / 8.10; Fedora 44 (F43 EOL
   9-dic-2026, F42 ya EOL); CentOS Stream 10 hasta 31-may-2030 y Stream 9 hasta 31-may-2027;
   AlmaLinux 10.2 y Rocky 10.2, ambos con EOL 31-may-2035.
3. **Tabla oficial de rutas soportadas de `leapp`** (por minor de origen y destino) en la guía
   "Upgrading from RHEL 9 to RHEL 10" antes de planificar cualquier salto, y el nombre vigente del
   `--channel` tras la sustitución de EUS por ELC.
4. **Estado de GA vs. Technology Preview de cada pieza de image mode** en las release notes de tu
   versión exacta (bootc, `bootc-image-builder`, `%ostreecontainer`). Cambia por minor.
5. **Versión de `dnf5` en tu distro** y el estado del plugin concreto que necesites en
   `github.com/rpm-software-management/dnf5` — la paridad de plugins se cerró en su mayoría, pero
   quedan huecos de nicho.
6. **Disponibilidad de tus paquetes en EPEL 10** (repo por minor) antes de comprometer una
   migración a EL10.
7. **CVE activos** de `sudo`, `dnf`/`rpm`, `podman`, `subscription-manager` y de la imagen base que
   uses, priorizados con KEV/EPSS (`vulnerability-management-standards`).
8. **Requisito de microarquitectura** (`x86-64-v2` vs `v3`) del hardware destino antes de elegir
   distribución: es un bloqueante duro, no una degradación de rendimiento.

**Huecos declarados — NO verificados en la redacción de este documento; verifícalos antes de
apoyarte en ellos:**

- **Si RHEL 10 usa `dnf5` como gestor por defecto** — **no verificado**. Lo confirmado es que
  `dnf5` es el default **en Fedora desde la 41**. No asumas nada sobre RHEL 10 sin comprobarlo en
  el host o en las release notes.
- **Eliminación de `iptables` en RHEL 10**: la ausencia del módulo de kernel aparece en un reporte
  *downstream* (moby/moby); **no confirmado contra el capítulo "Removed features" de las release
  notes oficiales**. `nftables` es el reemplazo en cualquier caso.
- **Estado de RPM Fusion para EL10** (RHEL/Alma/Rocky 10) — **no verificado**. Solo confirmado para
  Fedora 44.
- **EOL de EPEL 9 y política de fin de vida de las ramas `epel10.N`** — **no verificado**.
- **Versión concreta de `tuned`, `cockpit`, `podman` y `leapp`** en cada distro viva — **no
  verificadas**. Se han descrito por criterio de uso, sin fijar número.
- **Estado exacto de GA del modo imagen por versión de RHEL** (qué es producto soportado y qué es
  Technology Preview en 9.x vs 10.x, minor a minor) — solo verificado que la ISO vía
  `bootc-image-builder` y `%ostreecontainer` son TP; **el resto no se ha desglosado por minor**.
- **Fechas exactas de fin de Full Support de RHEL 9 y 10** (el paso a Maintenance) — se ha citado
  el fin de ciclo, **no la frontera entre fases**.
- **Términos legales vigentes de la Developer Subscription** (uso productivo de los 16 sistemas):
  hay contradicción entre la FAQ de Red Hat y lecturas de *compliance* de terceros. **No
  resuelta**: consulta los términos oficiales antes de desplegar.
- **Detalle de los CVE citados** (`CVE-2025-32463`): CVSS, versiones afectadas y estado en KEV
  **no verificados**.
- **`dnf-automatic` y reinicio nativo**: verificado que Red Hat lo documenta como **no soportado**,
  pero **no se ha comprobado si alguna versión reciente añadió `reboot`/`reboot_command`** al
  paquete de tu distro.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
