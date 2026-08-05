---
name: os-provisioning-standards
description: Unattended OS installation on bare metal and VMs — network boot and the answer file that drives the installer. Use when configuring PXE or UEFI HTTP Boot with dnsmasq, pxelinux.0, syslinux, grubx64.efi, shimx64.efi, iPXE (undionly.kpxe, ipxe.efi, chainloading, embedded scripts), DHCP option 66/67, option 60 HTTPClient vendor class or DHCPv6 option 59 bootfile-url, TFTP versus HTTP boot, writing a Kickstart ks.cfg with %packages/%pre/%post and inst.ks=, a Debian preseed.cfg with d-i directives, a SUSE Agama JSON profile replacing AutoYaST autoinst.xml, Ubuntu autoinstall.yaml or subiquity.autoinstallpath, cloud-init NoCloud seed ISOs and the user-data / meta-data / vendor-data / network-config split with ds=nocloud and seedfrom, Butane .bu transpiled to Ignition .ign for Fedora CoreOS or RHCOS, Windows unattend.xml with WDS or Configuration Manager OSD after MDT retirement, golden images versus scripted installs, building images with mkosi, osbuild, image-builder, bootc-image-builder or Packer, bootc install and rpm-ostree image mode, driving Cobbler, Foreman, MAAS or Tinkerbell, powering on hardware remotely with Redfish or ipmitool to boot an installer, or making a freshly installed host register itself in the inventory and the configuration management system.
---

# Estándares de aprovisionamiento de sistemas operativos

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **cómo un sistema operativo llega a un disco sin que nadie toque una tecla**: el arranque de
red (PXE/BIOS, UEFI HTTP Boot, iPXE, la cadena DHCP→TFTP/HTTP→bootloader→instalador), el fichero de
respuestas de cada instalador, la decisión **imagen dorada frente a instalación guionizada**, las
herramientas que construyen la imagen, los orquestadores de aprovisionamiento, el encendido remoto
del hierro (Redfish/IPMI) y —lo que casi siempre falta— el **cierre del ciclo**: la máquina recién
instalada se registra sola en el inventario y en el gestor de configuración, o el aprovisionamiento
no ha terminado.

**Principio rector**: **el aprovisionamiento no acaba cuando el instalador reinicia; acaba cuando el
host aparece en el inventario, en el gestor de configuración y en la monitorización.** El segundo
principio: **la instalación reproducible se demuestra reinstalando**, no leyendo el perfil.

Triggers: `pxelinux.0`, `shimx64.efi`, `grubx64.efi`, `ipxe.efi`, `undionly.kpxe`, `dnsmasq.conf`
con `dhcp-boot`/`pxe-service`, opciones DHCP **66/67**, **opción 60 `HTTPClient`**, DHCPv6 **opción
59 `bootfile-url`**, `ks.cfg`, `inst.ks=`, `%pre`/`%post`/`%packages`, `preseed.cfg`, `d-i`,
`autoinst.xml`, perfil **Agama** JSON, `autoinstall.yaml`, `subiquity.autoinstallpath`,
`user-data`/`meta-data`/`vendor-data`/`network-config`, `ds=nocloud`, `seedfrom`, `cloud-localds`,
`.bu`/`.ign`, `butane`, `unattend.xml`, `boot.wim`, WinPE/ADK, `mkosi.conf`, `osbuild`,
`image-builder`, `bootc install to-disk`, Packer, Cobbler, Foreman, MAAS, Tinkerbell
(Smee/Tootles/HookOS/Tink), `ipmitool chassis bootdev pxe`, Redfish `ComputerSystem.Boot`,
"instalar 40 servidores iguales", "el kickstart funcionaba y ya no".

**No aplica**: ver `onprem-standards` (**paraguas de plataforma y tabla de enrutado §1.2**; sus
invariantes de §1.3 mandan, en particular *ningún snowflake* y *todo servidor reconstruible desde
código* — **esta skill es el mecanismo que lo hace cierto**), `cmdb-inventory-standards` (**el
registro donde aterriza el host nuevo**: modelo de datos, identificador estable, reconciliación —
aquí solo el *gancho* que lo da de alta), `server-hardware-standards` (el hierro y su BMC: firmware,
red de gestión, garantía — **aquí solo Redfish/IPMI como disparador de arranque**),
`iac-standards` (**Ansible/Terraform y el código que configura la máquina *después* del primer
arranque**; la frontera exacta: **hasta el primer login manda esta skill, del primer login en
adelante manda `iac-standards`** — y el `%post` de un Kickstart que hace de gestor de configuración
es un antipatrón vetado, §7), `linux-administration-standards` (el SO ya instalado),
`rhel-fedora-standards` (**`rpm-ostree`, `bootc`, image mode y `dnf` como ecosistema de la familia
Red Hat**; aquí `bootc install` solo como método de instalación), `linux-hardening-standards` (el
baseline CIS/STIG sobre lo instalado: **una imagen dorada endurecida no sustituye a la medida del
baseline**), `proxmox-ve-standards`, `libvirt-kvm-standards`, `vmware-standards` (**la plantilla de
VM y el clonado son suyos**: `qm clone`, `virt-sysprep`, plantillas de vSphere; aquí el `cloud-init`
que la personaliza y el instalador que la crea), `windows-server-ad-standards` (dominio y GPO),
`macos-fleet-standards` (DEP/ADE y MDM: **el aprovisionamiento de Apple no pasa por PXE**),
`cicd-standards` (el pipeline que construye la imagen), `network-troubleshooting-standards` (**"el
PXE no arranca" como diagnóstico reactivo**), `bcdr-standards` (reconstrucción como estrategia de
recuperación), `homelab-standards` (proporcionalidad: un `cloud-localds` y un ISO bastan, no montes
Foreman), `datacenter-facilities-standards` (rack, energía y el recorrido
físico del servidor antes de que exista una IP), `hpc-standards`
(aprovisionamiento masivo de nodos, arranque sin disco, `xCAT`/Warewulf).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Transporte de arranque | **UEFI HTTP Boot** (opción 60 `HTTPClient` + opción 67 con **URI completa**) | TFTP no tiene control de flujo ni integridad y se ahoga con imágenes grandes. PXE/TFTP solo para firmware que no soporte HTTP Boot; **BIOS legacy solo en hierro que no arranca de otra forma** |
| Cadena de arranque | **iPXE** encadenado desde el firmware, con script embebido y firmado | Da HTTP(S), scripting, reintentos y decisión por MAC/UUID; el `pxelinux` plano no. Alternativa: `shim`+`grub` cuando Secure Boot exige la cadena firmada por la distro (§5) |
| Servidor mínimo | `dnsmasq` (DHCP proxy + TFTP) + un HTTP con los artefactos | Suficiente y auditable para decenas de hosts. `dnsmasq` en **modo proxy-DHCP** si el DHCP corporativo no es tuyo |
| Fichero de respuestas | El **nativo de la distribución**: Kickstart (RHEL/Fedora), preseed (Debian), **Agama JSON** (SLES 16+), `autoinstall.yaml` (Ubuntu), Butane→Ignition (CoreOS/RHCOS), `unattend.xml` (Windows) | No hay abstracción común que merezca la pena; los envoltorios multi-distro se rompen en cada release |
| SUSE | **Agama** (perfil JSON/Jsonnet) | **SLES 16 sustituye YaST/AutoYaST por Agama**; AutoYaST **no** migra 1:1 (§8). En SLES 15 sigue AutoYaST |
| Personalización de VM en nube/plantilla | **cloud-init**, datasource **NoCloud** para on-prem | Estándar de facto. **Ignition** cuando el SO es inmutable (CoreOS/RHCOS): se ejecuta una sola vez en el initramfs y no reconfigura en cada arranque |
| Imagen frente a instalación | **Imagen construida en pipeline** para flota homogénea y efímera; **instalación guionizada** para hierro heterogéneo y de vida larga | Regla: si vas a reinstalar más de lo que vas a parchear, imagen; si no, instalación + gestor de configuración |
| Constructor de imagen | `mkosi` (declarativo, del proyecto systemd, UKI de serie), **`image-builder` de osbuild** en el mundo RHEL, Packer cuando el destino es un hipervisor o una nube | **`bootc-image-builder` está en deprecación anunciada** hacia `image-builder` (§8) |
| SO de imagen | `bootc` / image mode cuando la flota tolera el modelo de contenedor arrancable | Upstream **v1.16.7 (4-ago-2026)**, cadencia semanal; **el repositorio vive en `bootc-dev/bootc`** |
| Orquestador | **Foreman** con flota mixta y ciclo de vida largo; **MAAS** si el parque es Ubuntu y quieres máquinas como recurso; **Tinkerbell** si el consumidor es Kubernetes/Cluster API | **Cobbler** solo si ya está: sigue mantenido pero lleva años en transición 3.3.x→4.0.0. Ninguno si son menos de ~20 hosts: `dnsmasq` + HTTP + repo |
| Encendido y selección de arranque | **Redfish** (`Boot/BootSourceOverrideTarget`) | `ipmitool` solo donde no haya Redfish. Detalle del BMC y su red: `server-hardware-standards` |

## 3. Estructura y convenciones

- **Un repositorio de aprovisionamiento**, versionado, con: perfiles por rol (no por host), plantillas
  del fichero de respuestas, scripts de iPXE, y el manifiesto de artefactos (ISO/kernel/initrd) **con
  su suma de verificación**. Todo lo que sirva el servidor de arranque sale de ahí.
- **El perfil es por rol y la diferencia por host es dato, no plantilla.** Hostname, IP, VLAN, rol y
  dueño se consultan al inventario en tiempo de aprovisionamiento (por MAC o por número de serie
  DMI), no se copian en 40 ficheros. Un perfil por host es el primer síntoma de *snowflake*.
- **`user-data`, `meta-data`, `vendor-data` y `network-config` son cuatro cosas distintas** y
  confundirlas es el fallo nº1 con cloud-init. Literal de la documentación 26.2: *"Cloud-init
  discovers four types of configuration at runtime"* (las cuatro anteriores, la **configuración de
  runtime**) y *"The purpose of the discovery configuration is to tell cloud-init where it can find
  the runtime configurations"* (`ds=nocloud`, `seedfrom`, DMI o línea de kernel: la **configuración
  de descubrimiento**). Consecuencias operativas: la identidad de la instancia (`instance-id`) va en
  `meta-data` y **cambiarla vuelve a ejecutar los módulos `per-instance`**; la red **no se puede
  cambiar desde `user-data`** (va en `network-config`, en la config del sistema o en la línea de
  kernel); `vendor-data` es del proveedor de la plataforma, no tuyo.
- **NoCloud sin servidor**: semilla en ISO/vfat con `user-data`, `meta-data` y opcionalmente
  `network-config` (`cloud-localds -N`). Con servidor: `ds=nocloud;s=https://…/` — y `seedfrom`
  admite expansión `__dmi.varname__`, que es la forma limpia de **servir configuración por número de
  serie del chasis** sin plantillas por host.
- **Butane/Ignition**: se escribe `.bu` y se transpila con `butane --strict`; **el `.ign` es
  artefacto generado y no se edita a mano**. Fija `variant: fcos` y una **versión estabilizada**
  (a ago-2026 la última estable es **1.7.0 → Ignition 3.6.0**; 1.8.0 es experimental y la propia
  documentación advierte: *"Do not use experimental specifications for anything beyond development
  and testing as they are subject to change without warning or announcement"*).
- **Windows**: `unattend.xml` con Configuration Manager OSD o WinPE propio del ADK. **MDT está
  retirado desde el 6-ene-2026** (sin actualizaciones, descargas retiradas) y **WDS ya no soporta
  desplegar Windows 11 ni Server 2025 con el `boot.wim` del medio de instalación**; el PXE de WDS
  sigue funcionando con imagen de arranque propia (§5 para el lado de seguridad).
- **Nombres y particionado deterministas**: esquema de particionado explícito en el perfil (nunca
  "usar todo el disco" en hierro con cabina conectada), selección de disco por WWN/serie y no por
  `/dev/sda`, y nombres de interfaz predecibles. Un instalador que elige por orden de enumeración
  instala en el LUN equivocado antes o después.

## 4. Validación: cómo se sabe que funciona

- **Gate 1 — sintaxis, en cada commit**: `ksvalidator` (Kickstart), `butane --strict`,
  `cloud-init schema --config-file`, validación del esquema de `autoinstall.yaml`, `mkosi` en modo
  build. Barato y atrapa la mitad de los fallos.
- **Gate 2 — instalación real en VM efímera, en cada cambio del perfil**: se levanta la VM, se
  aprovisiona de cero y se comprueban aserciones (usuarios, red, particionado, paquetes, servicios,
  registro en inventario). Sin este gate, el perfil se valida en producción.
- **Gate 3 — instalación en hierro representativo, por release de la distribución**: firmware, NIC,
  controladora y disco cambian el resultado. Un perfil validado solo en VM **no está validado para
  bare metal**.
- **Reinstalación periódica como ejercicio**: un host de cada rol se reinstala de cero en ventana
  acordada. Es la única prueba de que "reconstruible desde código" es cierto y de que el artefacto de
  la distribución sigue disponible.
- **Tiempo de aprovisionamiento medido** (de encendido a host en inventario y monitorización):
  decide si el modelo de imagen compensa, y hace creíble un plan de DR.

## 5. Seguridad: el arranque de red no está autenticado

**El punto crítico de esta skill.** La secuencia DHCP→TFTP→bootloader **no autentica nada por
defecto**: cualquiera en el mismo dominio de difusión puede responder al DHCP antes que tú y servir
su propio bootloader. Controles, en orden:

- **Red de aprovisionamiento aislada** (VLAN propia, sin salida a internet, sin usuarios). Es el
  control primario; los demás son defensa en profundidad.
- **DHCP snooping** en el switch de acceso: bloquea servidores DHCP no autorizados. **Y rompe tu
  aprovisionamiento si tu servidor está en un puerto no confiable** — el conflicto es real y se
  resuelve declarando el puerto del servidor de arranque como *trusted*, no desactivando snooping.
- **HTTPS en lugar de TFTP/HTTP** para todo lo que se pueda (UEFI HTTPS Boot exige el certificado
  raíz enrolado en el firmware) e **integridad verificada**: suma de verificación del artefacto en
  el script de iPXE.
- **Secure Boot activo también durante la instalación**: cadena `shim`→`grub`→kernel firmada.
  **Aviso de calendario, ago-2026**: la **Microsoft Corporation KEK CA 2011 expiró el 27-jun-2026** y
  la **Windows Production PCA 2011 expira en octubre de 2026**; sin las CA de 2023 enroladas (KEK
  2K CA 2023, UEFI CA 2023, Option ROM UEFI CA 2023) el equipo **sigue arrancando pero deja de poder
  recibir actualizaciones de DB/DBX y de confiar en binarios firmados con las nuevas claves**. Afecta
  a Linux: `shim` nuevo se firma con la CA de 2023. **Comprueba el estado por host antes de retirar
  la CA de 2011** y trátalo como tarea de firmware (`server-hardware-standards`).
- **PROHIBIDO servir secretos en `user-data`, en el Kickstart o en `unattend.xml`.** Van en claro por
  la red, quedan en `/var/lib/cloud/instance/` y en `/root/anaconda-ks.cfg`, y aparecen en los logs
  del instalador. Lo que se entrega en el primer arranque es **credencial de un solo uso, de corta
  vida y de alcance mínimo** (token de registro de Ansible/Vault/Foreman), y el secreto real se
  obtiene después contra el gestor de secretos. Una clave SSH pública sí; una privada, una contraseña
  o un token de larga vida, jamás.
- **Caso de estudio verificado**: **CVE-2026-0386** (WDS, CVSS 3.1 = 7.5, AV:A) — el `unattend.xml`
  viajaba por un canal RPC no autenticado y era accesible por el recurso `RemoteInstall` sin
  autenticación, permitiendo interceptarlo, robar credenciales incrustadas o inyectar código que se
  ejecuta durante el despliegue. Microsoft **deshabilitó por defecto el despliegue *hands-free*** con
  las actualizaciones del **14-abr-2026** (fase 2; fase 1 el 13-ene-2026). No es un fallo de Windows:
  es exactamente el modelo de amenaza de cualquier servidor de aprovisionamiento mal segmentado.
- **Contraseñas de instalación**: `rootpw` cifrado con algoritmo moderno o, mejor, **sin contraseña
  de root y solo clave SSH**; borrar el fichero de respuestas del sistema instalado en el `%post`.
  **Firma tu script de iPXE**: un iPXE genérico bajado de internet es código sin procedencia en tu
  ruta de arranque.

## 6. Cierre del ciclo: el host recién nacido se registra solo

El aprovisionamiento **debe terminar en tres altas automáticas**, ejecutadas por el propio host en su
primer arranque y no por una persona:

1. **Inventario**: alta o actualización del activo con su **identificador estable** (número de serie
   / UUID de DMI, **no el hostname ni la IP**), MAC(s), rol y fecha. Modelo y reconciliación:
   `cmdb-inventory-standards`.
2. **Gestor de configuración**: registro contra Ansible/Foreman/Salt con **token de un solo uso**, y
   primera convergencia completa. A partir de aquí manda `iac-standards`.
3. **Observabilidad**: alta en descubrimiento de métricas y envío de logs. El invariante de
   `onprem-standards` es literal: *sin telemetría no hay producción*.

**Y el cierre inverso, que casi nadie implementa**: al retirar el host se le da de baja en los tres
sitios. Un activo que se aprovisionó solo y se retiró a mano deja fantasmas en el inventario, alertas
huérfanas y credenciales vivas.

## 7. Sostenibilidad y prohibiciones

Cadencia: el artefacto base (ISO, kernel/initrd, imagen bootc) se **refresca al menos con cada
release menor** de la distribución; una imagen dorada de hace un año son cientos de parches que se
aplican en el primer arranque de cada host. Revisa por release que los perfiles siguen validando: los
instaladores cambian claves entre versiones mayores sin aviso amable.

- ❌ **PROHIBIDO** un fichero de respuestas con secretos de larga vida (§5).
- ❌ **PROHIBIDO** un perfil por host cuando la diferencia son cuatro datos: van al inventario.
- ❌ Usar el `%post` del Kickstart (o `runcmd` de cloud-init) **como gestor de configuración**. Su
  cometido termina en "arranca, tiene red e identidad, y llama al gestor de configuración".
- ❌ Imagen dorada construida a mano desde una VM "que ya estaba bien". Si no sale de un fichero
  versionado y de un pipeline, no es dorada: es un *snowflake* replicado N veces.
- ❌ Servidor de arranque en la VLAN de usuarios o con salida a internet.
- ❌ Desactivar DHCP snooping para "que funcione el PXE". Se declara confiable el puerto correcto.
- ❌ Desactivar Secure Boot para instalar y "ya lo activaremos". No se activa nunca.
- ❌ Fijar una versión **experimental** de spec de Butane en producción (§3).
- ❌ Depender de MDT (retirado) o de WDS con `boot.wim` de medio para Windows 11 / Server 2025.
- ❌ Depender del despliegue *hands-free* de WDS reactivando el override de CVE-2026-0386.
- ❌ Seleccionar disco de instalación por `/dev/sdX` en hierro con almacenamiento externo conectado.
- ❌ Declarar "reconstruible desde código" sin haber reinstalado nunca ese rol (§4).
- ❌ Dar por terminado el aprovisionamiento sin las tres altas de §6.

## 8. Verificación web obligatoria

Antes de fijar nada, comprobar por web —con cita literal, no con resumen automático:

1. **cloud-init**: versión vigente (a ago-2026 la documentación publicada es **26.2**, en
   `docs.cloud-init.io`) y, sobre todo, la página de **NoCloud**: la nomenclatura *discovery /
   runtime configuration* es reciente y la sintaxis de `ds=` ha cambiado entre versiones. **Hueco
   declarado: no se pudo verificar el estado exacto (válido, obsoleto o retirado) de `ds=nocloud-net`
   ni de la forma antigua `seedfrom` — la página actual solo documenta `ds=nocloud`.** Compruébalo
   contra la versión que empaqueta *tu* distribución, que suele ir por detrás de upstream.
2. **Butane/Ignition**: la tabla de `coreos.github.io/butane/specs/` cambia con cada estabilización.
   A ago-2026: estable **fcos 1.7.0 → Ignition 3.6.0**; experimental 1.8.0 → 3.7.0-experimental.
3. **bootc e image-builder**: versión de `bootc` (**repositorio en `bootc-dev/bootc`**, no en
   `containers/`) y, crítico, el **aviso de deprecación de `bootc-image-builder`** en
   `osbuild.org/docs/bootc/deprecation-notice/`, cuyo calendario está expresado en versiones de RHEL
   (9.8/10.2 → 9.9/10.3 → RHEL 11), no en fechas. Verifica a qué fecha corresponden hoy.
4. **SUSE**: que Agama sigue siendo el instalador de SLES 16+ y **qué construcciones de AutoYaST no
   migran**; SUSE documenta compatibilidad *alta* pero explícitamente **no 1:1**.
5. **Windows**: la guía de Microsoft sobre **CVE-2026-0386** (fases de 13-ene y 14-abr-2026) y la
   matriz vigente de qué versiones soporta WDS. Confirma también el estado de retirada de MDT
   (anunciada como inmediata el 6-ene-2026).
6. **Secure Boot**: estado del calendario de las CA de 2011 (KEK CA 2011 expirada el 27-jun-2026;
   Windows Production PCA 2011 en oct-2026) y **la disponibilidad de firmware con las CA de 2023 para
   tu modelo concreto de servidor**. En hardware fuera de soporte puede no llegar nunca: eso es un
   criterio de renovación, no un detalle.
7. **Orquestadores**: versión y soporte vigente de Foreman (ciclo corto: solo dos versiones
   soportadas a la vez), MAAS (**3.7 exige PostgreSQL 16**) y Cobbler (transición 3.3.x→4.0.0 aún
   abierta a mayo-2026). **Tinkerbell sigue en CNCF *Sandbox***, no incubación: pésalo como riesgo de
   adopción. **Hueco declarado: no se verificaron leyendo el `LICENSE` en crudo las licencias de
   Cobbler, Foreman, MAAS ni Tinkerbell.** Léelas antes de citarlas.
8. **Firmware del servidor**: si soporta **UEFI HTTP(S) Boot** y con qué limitaciones (tamaño de
   descarga, TLS, enrolado de CA). Varía por fabricante y por versión de BIOS, y es lo que decide si
   puedes abandonar TFTP.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
