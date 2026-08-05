---
name: selinux-standards
description: Mandatory access control on Linux with SELinux and AppArmor. Use when diagnosing AVC denials with ausearch, sealert, audit2allow or audit2why, managing labels and ports with semanage, restorecon, fixfiles, matchpathcon or chcon, toggling booleans with getsebool/setsebool, writing .te/.if/.fc or CIL policy modules with checkmodule, semodule, semodule_package, sepolicy generate, secilc or udica, editing /etc/selinux/config and enforcing/permissive modes, labeling containers (container_t, container_file_t, :z/:Z, container-selinux, seLinuxOptions/seLinuxChangePolicy), context= mount options for NFS, or writing AppArmor profiles with aa-genprof, aa-logprof, aa-complain, aa-enforce or aa-status.
---

# Estándares de control de acceso obligatorio (SELinux y AppArmor)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **operar, diagnosticar y escribir control de acceso obligatorio (MAC)** en Linux:
elección entre SELinux y AppArmor, modos y estados, etiquetado de ficheros y puertos, booleanos,
lectura y triaje de denegaciones, desarrollo y empaquetado de política propia, MAC en contenedores
y en almacenamiento compartido, y perfiles de AppArmor.

Triggers: `AVC`, `avc: denied`, `ausearch`, `sealert`, `setroubleshoot`, `audit2allow`, `audit2why`,
`semanage`, `restorecon`, `fixfiles`, `setfiles`, `chcon`, `matchpathcon`, `getsebool`, `setsebool`,
`semodule`, `checkmodule`, `semodule_package`, `secilc`, `sepolicy generate`, `udica`, ficheros
`.te`/`.if`/`.fc`/`.cil`/`.pp`, `/etc/selinux/config`, `getenforce`/`setenforce`, `sestatus`,
`container_t`, `container_file_t`, `:z`/`:Z`, `seLinuxOptions`, `seLinuxChangePolicy`, `context=`
como opción de montaje, `aa-genprof`, `aa-logprof`, `aa-status`, `/etc/apparmor.d/`,
"el servicio no arranca desde que activé SELinux", "funciona en permissive".

**Principio rector**: **la respuesta correcta casi nunca es desactivarlo, y casi siempre es una
etiqueta.** La gran mayoría de las incidencias de SELinux son **etiquetado incorrecto** (fichero,
directorio o puerto con el contexto que no toca), no ausencia de política. El orden de resolución es
fijo y no se salta: *¿es un problema de etiqueta?* → *¿hay un booleano para esto?* → *¿hay un puerto
que registrar?* → y solo entonces *política propia, escrita y revisada a mano*.

**No aplica**: ver `linux-hardening-standards` (**el baseline del sistema completo y su medición**:
CIS/STIG/ANSSI/CCN-STIC, OpenSCAP/Lynis, `sysctl`, SSH, auditd, sudo/PAM, montajes, sandboxing de
systemd, arranque medido — esa skill **exige** "MAC en `enforcing`" como control y lo audita; esta
explica cómo se opera y se escribe la política que lo hace posible), `onprem-standards` (paraguas de
plataforma: hardware, plano OOB, hipervisor, flota), `bash-linux-scripting-standards` (los scripts
que automatizan cualquier cosa de aquí), `iac-standards` (Ansible como herramienta y el CI del repo
de infraestructura — aquí solo qué se versiona y qué se prueba), `kubernetes-standards`
(`securityContext` completo, admisión, Pod Security Standards y política declarativa del cluster —
**aquí solo la parte SELinux**: `seLinuxOptions`, `seLinuxChangePolicy`, etiquetado de volúmenes),
`observability-standards` (recogida, retención y correlación de los eventos AVC en el SIEM),
`vulnerability-management-standards` (triaje y SLA de los CVE que se citan aquí),
`grc-compliance-standards` (MAC como control exigido por ENS/ISO/NIST y su evidencia),
`identity-access-management-standards` (identidad, SSO, MFA y elevación — el mapeo de usuarios
SELinux confinados es de aquí, la identidad corporativa es de allí), `networking-standards` (diseño
de red y firewall entre zonas; el registro de puertos con `semanage port` es de aquí),
`cryptography-pki-standards`, `appsec-standards` (fallos en el código de aplicación),
`homelab-standards`, `offensive-security-standards` (verificación ofensiva del confinamiento, con
alcance y autorización).

Planificadas — hasta que existan, esta skill es criterio provisional en su solapa:
`container-runtime-security-standards` (**Ola 1**: seguridad del runtime — seccomp, eBPF/Falco,
detección de escape de contenedor. **Frontera precisa: el MAC del contenedor es de esta skill**
—`container_t`, `container-selinux`, `:z`/`:Z`, udica, perfiles AppArmor del contenedor—; **la
detección en tiempo de ejecución de que algo ha escapado es suya**),
`detection-engineering-standards` (**Ola 1**: convertir los AVC en reglas de detección y casos de
uso del SIEM), `linux-administration-standards` y `rhel-fedora-standards` (**Ola 2**: día a día del
SO y particularidades de la familia RHEL).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Qué MAC se usa | **El nativo de la distro**: SELinux en RHEL/CentOS Stream/Fedora/Rocky/Alma **y ahora también en SUSE**; AppArmor en Ubuntu y Debian | Cambiar el MAC de una distro te deja sin la política que su empaquetado asume y con toda la carga de mantenimiento. Verificado ago-2026: **SLES 16.0 (GA 4-nov-2025) elimina AppArmor y arranca con SELinux en enforcing** con política de **+400 módulos**; openSUSE Tumbleweed desde el snapshot 20250211 y Leap 16 hicieron el mismo cambio en instalaciones nuevas (excepción: **SLES for SAP 16 se pone en permissive automáticamente**) |
| Modo | **`enforcing`, siempre en producción** | `permissive` es una herramienta de diagnóstico con fecha de fin, no un estado de despliegue (§4) |
| Política SELinux | **`targeted`** | Confina los servicios de red y deja el resto sin confinar: es la relación coste/beneficio correcta. `mls` solo con requisito formal de multinivel y equipo que lo domine; `minimum` solo en casos muy acotados |
| Deshabilitar SELinux | **Nunca en producción.** Si un laboratorio lo exige: **`grubby --update-kernel ALL --args selinux=0`** | **Verificado ago-2026: `SELINUX=disabled` en `/etc/selinux/config` está deprecado desde RHEL 8 y el soporte de kernel se eliminó en RHEL 9.0.** El sistema arranca con **SELinux habilitado y sin política cargada**: los hooks LSM siguen registrados (y consumiendo recursos), `sestatus` dice "disabled" y **parece** que funcionó. Es la peor combinación posible: ni protección ni claridad. Red Hat **desaconseja explícitamente `selinux=0` en producción** y recomienda `permissive` para depurar |
| Modelo de SELinux | Etiquetas sobre **todos** los objetos (proceso, fichero, socket, puerto), transiciones de dominio y confinamiento por tipo | Cubre todo el sistema por etiqueta, sobrevive al `mv` y al renombrado, y confina también lo que no tiene ruta previsible. A cambio: curva de aprendizaje alta y fallos por etiquetado |
| Modelo de AppArmor | Perfiles **por ruta** de ejecutable, con abstracciones reutilizables | Mucho más fácil de escribir y leer; ideal para confinar una aplicación concreta. A cambio: lo que no tiene perfil queda **sin confinar** (`unconfined` es el estado por defecto), y el confinamiento por ruta se puede eludir con enlaces, montajes y renombrados que SELinux sí cubre |
| Userspace SELinux | El de la distro; upstream **3.11** (1-jul-2026; anterior 3.10, feb-2025) | 3.11 añade **`secilcheck`**, endurecimiento del relabelado y mejoras de seguridad en `libselinux`, `dbus`, `gui`, `mcstrans` y `sandbox`. Verificado ago-2026: **RHEL 10 lleva userspace 3.8** y rebasa `setools` a 4.6.0 en 10.2; Fedora 44 lleva libselinux/policycoreutils **3.10** y `setools` 4.6.0 |
| Herramientas de diagnóstico | **`setroubleshoot-server`** (`sealert`), **`policycoreutils-python-utils`** (`semanage`, `audit2allow`, `audit2why`), **`setools-console`** (`sesearch`, `seinfo`) | **No están en la instalación base**: instálalas explícitamente en los hosts donde vayas a diagnosticar (y **reinicia auditd** tras instalar `setroubleshoot-server` para que cargue el plugin). Verificado ago-2026: `setroubleshoot` **sigue vivo y mantenido** en RHEL 10 (3.3.35) y Fedora 44 (3.3.36) — no está deprecado |
| Contenedores | **`container-selinux`** (upstream **v2.250.0**) con `container_t` y separación MCS por contenedor | Es el confinamiento por defecto de Podman/Docker/CRI-O y **la razón por la que una fuga de contenedor no es automáticamente una fuga de host**. Desactivarlo (`--security-opt label=disable`) es una decisión de riesgo, no de conveniencia |
| Política propia para un contenedor | **`udica` v0.2.9** antes que escribir un `.te` a mano | Genera política a partir de la inspección real del contenedor (Podman, Docker, containerd, CRI-O, LXD): bloques por puerto expuesto, por volumen montado y su modo. Produce **CIL** cargable con `semodule -i`, y se aplica con `--security-opt label=type:<tipo>.process` |
| Lenguaje de política | **`.te` + macros de interfaz** (`selinux-policy-devel`) para política propia; **CIL** cuando lo genere una herramienta o necesites depurar | **Todo acaba en CIL de todos modos**: `semodule` convierte los `.pp` con el compilador HLL de `/usr/libexec/selinux/hll/`. Escribir CIL a mano solo compensa en generación automática. Truco de diagnóstico: `/usr/libexec/selinux/hll/pp modulo.pp > modulo.cil` para leer qué hace un módulo binario |
| Prioridad de módulos | `semodule -X <1-999>` para que tu módulo gane al del sistema sin tocarlo | Nunca edites ni sustituyas los módulos de `selinux-policy`: se pierden en cada actualización |
| AppArmor | **Serie 4.1 (LTS, abr-2025, 5 años de soporte)** como base estable; 5.x solo cuando lo traiga la distro | Verificado ago-2026: **5.0** (23-abr-2026) es un release *puente* declarado de **vida corta y sin soporte a largo plazo**; 5.0.1 (10-jun-2026). **4.1.5 es defectuosa — usar 4.1.6+**. Empaquetado: Ubuntu 24.04 → 4.0.1; **Ubuntu 26.04 → 5.0.0~beta1**; Debian 13 → 4.1.0. Nota de migración: la política construida con 4.1.x anterior a 4.1.4 podía ocupar 2-8× más — **reconstruye las cachés de política tras actualizar** |
| SELinux en Debian/Ubuntu | **No, salvo requisito explícito** (`selinux-basics` 0.6.0 existe en trixie y está mantenido) | Es soporte de segunda clase frente a AppArmor en esas distros: la política empaquetada no recibe la misma atención. Si te lo exige un marco, valídalo tú, no lo asumas |

## 3. Operación y diagnóstico

### 3.1 Conceptos que hay que manejar (y ninguno más para empezar)

- **Contexto**: `usuario_u:rol_r:tipo_t:nivel` en todo objeto y proceso (`ls -Z`, `ps -Z`, `id -Z`).
  En política `targeted` **el que decide es el tipo**; usuario, rol y nivel MCS importan en casos
  concretos (usuarios confinados, contenedores).
- **Dominio**: el tipo de un proceso. **Transición de dominio**: al ejecutar un binario con un tipo
  *entrypoint*, el proceso cambia de dominio. Que un servicio corra como `unconfined_t` en vez de su
  dominio propio **es un fallo de etiquetado del binario o de la unidad**, no "SELinux que no aplica".
- **Booleano**: interruptor previsto por la política para variantes de comportamiento habituales.
- **Modos**: `enforcing` (aplica y registra), `permissive` (solo registra), `disabled` (ver §2 — con
  matices importantes en RHEL 9+).

### 3.2 Los tres estados que hay que distinguir siempre

| Estado | Qué significa | Qué se hace |
|---|---|---|
| **Denegación real** | La operación se bloqueó y el servicio falla | Diagnóstico completo (§3.3) |
| **`dontaudit`** | La política **silencia** denegaciones esperadas e inofensivas | Solo se desilencian temporalmente para diagnosticar (§3.4) |
| **Denegación irrelevante** | Se registró, pero el servicio funciona igual | **No se "arregla"**: añadir permisos por ruido es ampliar la superficie gratis |

### 3.3 Diagnóstico: el orden fijo

1. **Confirmar que es SELinux**: `ausearch -m AVC,USER_AVC,SELINUX_ERR -ts recent`, `journalctl -t
   setroubleshoot`, `dmesg`. Si el fallo persiste en `permissive` **no es SELinux** — deja de mirar
   aquí (y vuelve a `enforcing` inmediatamente).
2. **Leer el AVC de verdad**, no el resumen: qué **`scontext`** (dominio origen), qué **`tcontext`**
   (contexto destino), qué **`tclass`** (clase de objeto) y qué **permiso**. Ese cuarteto es el
   diagnóstico entero. `sealert -l <id>` da explicación y sugerencias ordenadas por confianza — **la
   primera suele ser correcta y las siguientes suelen ser demasiado amplias**.
3. **¿Es etiquetado?** Es la causa del 80 % de los casos. Compara el contexto real con el esperado
   por la política: `ls -Z`, `matchpathcon`/`selabel_lookup`, `restorecon -nv <ruta>` (dry-run que
   dice exactamente qué cambiaría). Si el fichero está en el sitio no habitual, la solución no es
   permitir el acceso: es **registrar el contexto correcto para esa ruta** (§3.6).
4. **¿Hay un booleano?** `semanage boolean -l | grep <pista>`, `getsebool -a`. Si lo hay, se usa
   (§3.5). Escribir política propia existiendo un booleano es error de novato con coste permanente.
5. **¿Es un puerto?** Servicio escuchando en puerto no estándar → `semanage port -a -t <tipo> -p tcp
   <puerto>` (`-m` si el puerto ya está registrado para otro tipo). Nunca se resuelve con política.
6. **¿Es realmente política?** Solo entonces (§3.7). Y con un módulo propio, revisado y versionado.

### 3.4 `dontaudit`: cómo no perder media tarde

Si el servicio falla y **no ves ningún AVC**, sospecha de `dontaudit`:

- Desactivar temporalmente: **`semodule -DB`** (`-D` quita los `dontaudit`, `-B` reconstruye y
  recarga la política).
- Reproducir el fallo y volver a mirar: `ausearch -m AVC -ts recent`.
- **Restaurar siempre**: **`semodule -B`**. El estado "sin dontaudit" **sobrevive al reinicio**, así
  que olvidarse deja el host generando ruido indefinidamente. Ojo: cualquier reconstrucción de
  política (`semodule -i`, `setsebool -P`) lo revierte por su cuenta, lo que produce diagnósticos
  irreproducibles si no lo controlas.

### 3.5 Booleanos antes que política propia

```
semanage boolean -l          # listado con estado actual, pendiente y descripción
getsebool -a                 # listado crudo
setsebool <bool> on          # temporal, para probar
setsebool -P <bool> on       # persistente (reconstruye la política)
```
Regla: **si existe un booleano que cubre el caso, se usa y se registra en el código de configuración
con un comentario que diga por qué**. Un booleano activado a mano en un host es drift y desaparece
en la siguiente reconstrucción del servidor.

### 3.6 Etiquetado persistente: `semanage fcontext` + `restorecon`, nunca `chcon`

```
semanage fcontext -a -t httpd_sys_content_t "/data/nginx(/.*)?"   # regla en la política
restorecon -Rv /data/nginx/                                        # aplicar a los ficheros
```
- **`chcon` no es persistente**: se pierde en el siguiente relabel o `restorecon`. Vale para una
  prueba de 30 segundos y para nada más (§7).
- Es **expresión regular, no glob**, y **las comillas son obligatorias**: `(/.*)?` significa "el
  directorio y todo lo que cuelga".
- `-a` añadir, `-m` modificar, `-d` borrar, `-l` listar (**`-C` para ver solo las locales**, que es
  lo que de verdad quieres auditar).
- `restorecon` por defecto **solo corrige el campo `type`**; usa **`-F`** para resetear los cuatro
  campos. `-n` para dry-run, `-R` recursivo, `-v` para ver qué cambia.
- **Relabel completo**: `fixfiles relabel` o `touch /.autorelabel` + reinicio. En un host grande
  cuesta tiempo real: planifícalo, no lo lances en caliente.
- Los ficheros nuevos **heredan el tipo del directorio padre** salvo que la política defina una
  `type_transition`. Por eso "he movido el fichero con `mv` y ha dejado de funcionar" es un clásico:
  `mv` conserva el contexto de origen, `cp` hereda el del destino.
- **Cambio en RHEL 10 a tener en cuenta**: `semanage` **ya no ordena las definiciones locales de
  `fcontext`** — el orden en que las añades importa. Y el formato binario de `file_contexts.bin`
  cambió: **los ficheros en formato antiguo se ignoran**, hay que reconstruir la política.

### 3.7 Escribir política propia

- **`audit2allow` es un generador de borradores, no una solución.** Genera reglas a partir de lo que
  vio, y lo que vio suele ser *demasiado* — concede permisos amplios sobre tipos genéricos y, si el
  proceso estaba haciendo algo indebido, **le concede permiso a hacerlo**. Aplicar su salida sin
  leerla está prohibido (§7). Uso correcto:
  ```
  ausearch -m AVC -ts recent | audit2allow -R          # sugerencias con macros de interfaz
  ausearch -m AVC -ts recent | audit2allow -M mimodulo # genera .te y .pp
  audit2allow -w -a                                     # audit2why: por qué se denegó
  ```
  Se **lee el `.te` línea a línea**, se sustituyen tipos genéricos por los específicos, se eliminan
  los permisos que no hacen falta, y **solo entonces** se compila. Si el `.te` generado tiene
  docenas de reglas, el problema casi seguro es etiquetado, no política. (Verificado ago-2026: en
  RHEL 10, `audit2allow -C` produce salida en **CIL**.)
- **Punto de partida limpio**: `sepolicy generate` (de `policycoreutils-devel`) para un servicio
  nuevo, o **`udica`** si es un contenedor. Producen un esqueleto con dominio, transición y ficheros
  `.te`/`.if`/`.fc` coherentes, que es mucho mejor base que un `audit2allow` acumulado.
- **Anatomía**: `.te` (reglas y tipos), `.if` (interfaces reutilizables por otros módulos), `.fc`
  (contextos de fichero por ruta). Compilación clásica:
  ```
  checkmodule -M -m -o mimodulo.mod mimodulo.te
  semodule_package -o mimodulo.pp -m mimodulo.mod -f mimodulo.fc
  semodule -X 400 -i mimodulo.pp
  ```
  Los módulos CIL se cargan directamente con `semodule -i mimodulo.cil`.
- **Ciclo de desarrollo**: escribir → cargar en un host de pruebas → ejecutar el servicio en
  `permissive` **solo en ese host** → recoger AVC → refinar → volver a `enforcing` → **probar que el
  servicio funciona de verdad** → empaquetar.
- **Empaquetado y distribución**: la política propia se distribuye como **paquete** (RPM con el
  `.pp`/`.cil` y los scriptlets de `semodule -i`/`-r`) o como rol idempotente, **versionada en el
  mismo repo que el resto de la configuración del servicio**. Una política que solo existe en el
  host donde alguien la cargó a mano es un snowflake garantizado.

### 3.8 SELinux y contenedores

- **Modelo**: los procesos del contenedor corren como **`container_t`**, solo pueden leer y ejecutar
  de `/usr` y escribir sobre **`container_file_t`**; el runtime asigna **dos categorías MCS únicas**
  por contenedor, que es lo que aísla un contenedor de otro. `spc_t` (super privileged container) es
  el escape legítimo: un contenedor `spc_t` **no está confinado** — trátalo como código en el host.
- **Volúmenes**: `:z` = `relabel=shared` (etiqueta que permite el acceso a **todos** los
  contenedores); `:Z` = `relabel=private` (categoría MCS única, solo ese contenedor). **`:Z` por
  defecto**; `:z` solo cuando varios contenedores comparten el volumen a propósito. **Peligro
  clásico**: `:Z` sobre un directorio del sistema (`/home`, `/var`, `/usr`) reetiqueta
  recursivamente **el directorio real del host** y puede dejarlo inservible. Monta subdirectorios
  dedicados, nunca rutas del sistema.
- **Booleanos útiles antes que política**: `container_use_devices`, `container_connect_any`,
  `container_manage_cgroup`, `container_read_certs`, `container_can_execstack`. Cada uno amplía
  superficie: se activa el que hace falta, no el que "parece razonable".
- **`--security-opt label=disable` está prohibido como atajo** (§7). Si un contenedor necesita más
  de lo que `container_t` concede, la respuesta es **udica** (política propia acotada) y
  `--security-opt label=type:<tipo>.process`, no quitar el confinamiento.
- **Kubernetes** — verificado ago-2026 (§8): `securityContext.seLinuxOptions` (user/role/type/level)
  es estable a nivel de Pod y de contenedor. En **v1.36** pasaron a **GA `SELinuxMountReadWriteOncePod`
  y `SELinuxChangePolicy`**; **`SELinuxMount` sigue en beta y deshabilitado por defecto**, y se
  espera que pase a GA activado en **v1.37** (aún no publicada a esta fecha). El cambio es real: se
  sustituye el reetiquetado recursivo por **`mount -o context=`**, lo que acelera mucho el arranque
  de Pods **pero impone una sola etiqueta por montaje** — dos Pods con etiquetas distintas
  compartiendo volumen en el mismo nodo fallarán al arrancar. Acciones obligatorias antes de la
  migración: habilitar el `selinux-warning-controller` en `kube-controller-manager` y vigilar las
  métricas `selinux_warning_controller_selinux_volume_conflict` y
  `volume_manager_selinux_volume_context_mismatch_warnings_total`; el opt-out por carga es
  `spec.securityContext.seLinuxChangePolicy: Recursive`. Requiere además que el driver CSI declare
  `CSIDriver.spec.seLinuxMount: true`.

### 3.9 SELinux, systemd, NFS y almacenamiento compartido

- **systemd**: el confinamiento del servicio depende de que el binario tenga el tipo *entrypoint*
  correcto. Si `ps -Z` muestra el servicio en `unconfined_service_t`, revisa la etiqueta del binario
  y de la unidad antes de tocar política. El sandboxing de systemd es **complementario**, no
  sustitutivo: `systemd-analyze security` **ignora SELinux y AppArmor** (ver
  `linux-hardening-standards`).
- **Filesystems sin xattr** (NFS clásico, FAT, CIFS): `semanage fcontext` + `restorecon` **no
  sirven** — no hay dónde escribir la etiqueta. El mecanismo es la **opción de montaje**:
  - `context=<contexto>` — fuerza un contexto único para **todo** el montaje. No se escribe a disco;
    los contextos originales reaparecen al montar sin la opción.
  - `defcontext=` — contexto por defecto para ficheros sin etiquetar (los nuevos **sí** persisten).
  - `fscontext=` — etiqueta el superbloque sin cambiar las etiquetas de los ficheros.
  - `rootcontext=` — etiqueta el inodo raíz antes de que sea visible a userspace.
- Por defecto los montajes NFS reciben el tipo **`nfs_t`**, que es lo que suele impedir que `httpd` u
  otro servicio lea el share sin `context=` o sin el booleano correspondiente.
- **Labeled NFS** (transporte real de contextos): requiere **NFSv4.2**, la opción **`security_label`
  en el export del servidor** (explícita desde kernel 4.11; antes era el comportamiento por defecto)
  y el cliente montando con **`vers=4.2`** — **no existe opción `security_label` en el cliente**.
  `context=` y el etiquetado nativo son **mutuamente excluyentes**. Bug conocido a tener presente: el
  punto de montaje puede aparecer transitoriamente como `unlabeled` justo tras montar, generando
  denegaciones sobre `unlabeled_t`.

### 3.10 AppArmor: criterio de uso

- **Perfiles en `/etc/apparmor.d/`**, versionados en el repo del servicio, apoyados en las
  **abstracciones** (`abstractions/base`, `nameservice`, `openssl`…) en vez de reescribir reglas.
- **Ciclo**: `aa-genprof <binario>` para el borrador ejecutando la app, `aa-logprof` para refinar a
  partir del log, `aa-complain` (equivalente a `permissive`, **por perfil**) durante el ajuste,
  `aa-enforce` al terminar. `aa-status` para saber qué está confinado de verdad — y **lo que no
  aparece ahí está sin confinar**, que es la diferencia estructural con SELinux.
- **Límites honestos frente a SELinux**: confinamiento **por ruta**, no por etiqueta (enlaces,
  bind-mounts y renombrados requieren cuidado explícito); sin control de tipo sobre sockets y
  puertos comparable; sin MCS para aislar N instancias del mismo binario entre sí; y **todo lo que
  no tiene perfil queda `unconfined`**. A cambio: se escribe y se lee en una tarde.
- **Ubuntu 24.04+/26.04**: la restricción de user namespaces no privilegiados se implementa **como
  AppArmor** (`kernel.apparmor_restrict_unprivileged_userns=1` por defecto). Es un control de
  seguridad real: antes de bajarlo por una app que "no arranca", escribe un perfil para esa app
  (patrón `bwrap-userns-restrict` de upstream). Contexto: Qualys publicó en mar-2025 **tres bypasses**
  de esa restricción (vía `aa-exec` hacia perfiles permisivos y vía el perfil por defecto de
  busybox) — no la trates como frontera dura.
- **Riesgo actual conocido — CrackArmor (Qualys, 12-mar-2026)**: nueve vulnerabilidades en el
  **módulo AppArmor del kernel**, presentes desde v4.11 (2017), con CVEs asignados
  (**CVE-2026-23268, -23269, -23403 … -23411**). Vector central: *confused deputy* — un usuario sin
  privilegios induce a un binario privilegiado a escribir en
  `/sys/kernel/security/apparmor/{.load,.replace,.remove}`, con impactos que llegan a **manipular la
  política** (cargar un perfil deny-all para `sshd`), escalada local a root vía use-after-free en
  load/replace de perfil, y DoS por subperfiles anidados que agotan el stack de kernel. **Acción**:
  parchear el kernel de la distro y confirmar cobertura en el tracker del vendor.

## 4. Gates de calidad

1. **Nunca se despliega en `permissive` "y ya veremos".** `permissive` se usa **solo** en no
   producción, **solo** durante el desarrollo de la política, y con **fecha de fin en el ticket**.
   Un host que lleva meses en permissive no está protegido y nadie se ha enterado. Gate mecánico en
   CI/inventario: `getenforce` distinto de `Enforcing` en producción = **hallazgo**, igual que un
   parche pendiente.
2. **Prueba de que la política no rompe el servicio**: el gate es funcional, no de arranque. Ejercer
   el camino real (peticiones, escritura de ficheros, conexión a base de datos, rotación de logs,
   reinicio del servicio) con la política cargada y en `enforcing`, y **verificar que no aparece
   ningún AVC nuevo**: `ausearch -m AVC -ts <inicio-del-test>` debe volver vacío. Que systemd diga
   `active` no prueba nada.
3. **Prueba de reinicio y de relabel**: la política y las etiquetas deben sobrevivir a un reinicio y
   a un `restorecon -R` sobre las rutas afectadas. Este gate es el que caza los `chcon` clandestinos.
4. **Política versionada en el repo, junto al resto de la configuración del servicio**: `.te`, `.fc`,
   `.if` (o `.cil`), reglas de `semanage fcontext`, `semanage port` y booleanos, todo como código
   idempotente. Revisión por PR con la misma exigencia que cualquier cambio de seguridad.
5. **Revisión humana obligatoria de toda salida de `audit2allow`** antes de compilar, con
   justificación por regla en el commit. Nadie mergea un `.te` que no ha leído.
6. **Detección de drift**: booleanos, contextos locales (`semanage fcontext -C -l`, `semanage port
   -C -l`) y módulos cargados (`semodule -l`) se comparan con lo declarado. Cualquier diferencia es
   hallazgo — es la firma típica de "alguien arregló algo a las 3 de la mañana".
7. **Los AVC van al SIEM y tienen dueño.** Una denegación en producción es una señal: o falta
   configuración o alguien está haciendo algo que no debería. Un flujo de AVC que nadie mira
   convierte el MAC en decoración (destino de la telemetría: `observability-standards`; su
   explotación como detección: `detection-engineering-standards`).

## 5. Seguridad: qué protege el MAC y qué no

- **Lo que aporta**: contención tras la explotación. Un servicio comprometido queda encerrado en su
  dominio; una fuga de contenedor choca con `container_t` y con las categorías MCS. Es el control
  que convierte "RCE en el servicio web" en "RCE dentro de `httpd_t`".
- **Lo que no aporta**: no arregla vulnerabilidades ni sustituye al parcheo. **Un fallo de kernel
  puede anular sus garantías por completo**, y 2026 ha dado ejemplos verificados: **CVE-2026-53362**
  (RHSB-2026-009: escritura fuera de límites en la ruta IPv6 → lectura/escritura arbitraria de
  kernel, **bypass de SELinux** y escape de contenedor, explotable porque la configuración por
  defecto de RHEL 10 concede user namespaces a usuarios no privilegiados) y **CVE-2026-64600**
  ("RefluXFS", Qualys, jul-2026: *race* en la ruta copy-on-write de XFS que da root al host **incluso
  con SELinux en Enforcing**, porque opera por debajo de la capa de política; única mitigación
  fiable: parchear y reiniciar). Prioriza el parcheo del kernel: MAC es defensa en profundidad, no
  sustituto.
- **La política propia amplía superficie**: cada `allow` que añades es un permiso que el atacante
  también tiene. Escribe el mínimo, revisa el diff, y prefiere un booleano existente a una regla
  nueva.
- **Vigila los dominios sin confinar**: servicios corriendo como `unconfined_service_t`,
  contenedores en `spc_t`, procesos con `--security-opt label=disable`, ejecutables sin perfil
  AppArmor. Ese inventario **es** tu superficie real, y suele sorprender.
- **Los usuarios también se confinan**: `semanage login` para mapear cuentas a usuarios SELinux
  (`user_u`, `staff_u`, `guest_u`) en hosts multiusuario o de acceso compartido. Poco usado y muy
  eficaz cuando aplica.
- **`setenforce 0` es un evento de seguridad, no una operación rutinaria**: debe generar alerta,
  quedar registrado y requerir justificación. Es exactamente lo que hace un atacante con root.

## 6. Rendimiento y operabilidad

- **Coste**: el chequeo de SELinux es barato; lo caro es el **relabelado**. Un `fixfiles relabel` o
  un `touch /.autorelabel` en un filesystem grande es una ventana de mantenimiento, no un comando.
  Igual con `:Z` sobre volúmenes enormes en contenedores: cada arranque reetiqueta. Ese es el
  problema exacto que resuelve el montaje con `-o context=` en Kubernetes (§3.8).
- **`restorecon -R` acotado a la ruta afectada** en vez de relabel global; en hosts con poca memoria
  y muchos hard links, RHEL 10.2 añade `setfiles -A` para desactivar el seguimiento de conflictos de
  inodos.
- **Runbook de diagnóstico** escrito y probado: cómo se recogen AVC, cómo se activa `permissive` en
  **un** host con ticket y caducidad, cómo se revierte, y a quién se escala. Sin runbook, la
  incidencia de las 3 de la mañana acaba en `setenforce 0` permanente.
- **Empaquetado en RHEL 10 a tener en cuenta**: los módulos de política solo-EPEL salieron de
  `selinux-policy` a subpaquetes `-extra` (repo CRB), lo que reduce el tamaño y acelera la
  reconstrucción y carga de política. Si un servicio de EPEL "no tiene política", comprueba que el
  subpaquete está instalado antes de escribir la tuya.
- **Rollback**: `semodule -r <modulo>` y `semanage -d` de las entradas añadidas, probados. Toda
  política propia se despliega con su desinstalación verificada.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- Revisar la política propia en cada actualización mayor de distro y de `selinux-policy`: las
  interfaces cambian y un módulo que compilaba puede dejar de hacerlo (RHEL 10 cambió además el
  formato binario de `file_contexts.bin` e ignora el antiguo).
- Reconstruir cachés de política de AppArmor tras actualizar la serie 4.1.x y al saltar de 4.x a 5.x
  (política 4.0 es compatible en 5.0, pero 5.0 introduce features no retrocompatibles).
- Revisar trimestralmente el inventario de excepciones: booleanos activados, módulos propios
  cargados, contenedores con `label=disable`, ejecutables sin perfil AppArmor. Cada excepción con
  dueño y fecha de reevaluación.
- Parchear kernel con prioridad cuando el hallazgo afecte al propio módulo LSM (CrackArmor) o
  permita bypass del MAC (§5).

**PROHIBIDO**
- ❌ **`setenforce 0` como solución.** Es diagnóstico temporal en un host, con ticket, y se revierte
  en la misma sesión. Como "arreglo" es desactivar el control de seguridad y dejarlo así.
- ❌ **`selinux=0` en la línea de arranque** de un sistema en producción (ni `enforcing=0`
  permanente). Y **`SELINUX=disabled` en `/etc/selinux/config`** en RHEL 9+, que ni siquiera hace lo
  que aparenta (§2).
- ❌ **Aplicar la salida de `audit2allow` sin leerla**, o mergear un `.te` generado sin revisión
  humana regla a regla.
- ❌ **`chcon` como arreglo permanente**: se usa `semanage fcontext` + `restorecon`. Un `chcon` en un
  playbook o en un script de arranque es deuda que revienta en el siguiente relabel.
- ❌ **Política propia sin tests**: sin prueba funcional en `enforcing`, sin prueba de reinicio y
  relabel, y sin verificar que no aparecen AVC nuevos.
- ❌ Política propia que solo existe en un host, cargada a mano y no versionada.
- ❌ Editar o sustituir módulos de `selinux-policy` del sistema en vez de cargar un módulo propio con
  prioridad (`semodule -X`).
- ❌ Desplegar en `permissive` "hasta que haya tiempo", o dejar `semodule -DB` puesto tras
  diagnosticar.
- ❌ **`--security-opt label=disable`**, `privileged` con MAC desactivado o contenedores en `spc_t`
  como forma habitual de resolver una denegación.
- ❌ `:Z` sobre directorios del sistema del host (`/`, `/usr`, `/var`, `/home`) — reetiqueta
  recursivamente y puede dejar el host inservible.
- ❌ Añadir reglas por **ruido**: denegaciones registradas que no afectan al funcionamiento se
  investigan, no se permiten.
- ❌ Sustituir el MAC nativo de la distro (SELinux↔AppArmor) sin necesidad real y sin asumir el
  mantenimiento completo de la política.
- ❌ Tratar el MAC como sustituto del parcheo del kernel (§5).
- ❌ Fijar versiones, nombres de tipo, opciones de montaje o estados de feature **de memoria** sin la
  verificación de §8.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato concreto, **búscalo — no lo recuerdes**:

1. **Estado de `SELINUX=disabled`** en la versión exacta de tu distro (verificado ago-2026:
   deprecado desde RHEL 8, **soporte de kernel eliminado en RHEL 9.0**; método soportado
   `grubby --update-kernel ALL --args selinux=0`). **Hueco declarado**: no se localizó una nota
   equivalente **de Fedora** que lo declare explícitamente; el comportamiento se asume igual por
   compartir kernel y userspace, pero **no está verificado**.
2. **Versión de `selinux-policy`, userspace y `container-selinux`** en tu distro (verificado
   ago-2026: userspace upstream **3.11**, 1-jul-2026, con `secilcheck`; **RHEL 10 lleva userspace
   3.8**; Fedora 44 lleva 3.10 y `selinux-policy` 44.5; `container-selinux` **v2.250.0**).
   **Huecos declarados**: el **NVR exacto de `selinux-policy` en RHEL 9.x y 10.x GA**, la **versión
   de userspace en RHEL 9**, y las **fechas de release de `container-selinux` 2.250.0 y de `udica`
   0.2.9** no se pudieron confirmar.
3. **Estado de `setroubleshoot`/`sealert`** en tu versión (verificado ago-2026: **no deprecado**,
   presente y mantenido en RHEL 10 y Fedora 44). **Huecos declarados**: no se pudo leer el capítulo
   *Deprecated functionality* de las notas de RHEL 10.x (403) — la ausencia de deprecación es
   inferida, no leída; tampoco se confirmó **si sigue instalándose por defecto** (en imágenes
   mínimas y Image Mode probablemente no).
4. **Cambios de herramientas por versión**: `audit2allow -C` (salida CIL), `semanage` que ya no
   ordena fcontext locales, formato nuevo de `file_contexts.bin`, `setfiles -A`, `seinfo
   --role_types` — todos verificados en las notas de RHEL 10.x, pero **léelas para tu versión** antes
   de dar por buena una sintaxis. **Huecos declarados**: si el binario **`matchpathcon`** ha sido
   eliminado (está obsoleto a nivel de API desde hace años en favor de `selabel_lookup`) y el estado
   exacto de **`sepolicy generate`** en RHEL 10.
5. **`semodule -DB` / `-B`** frente a `semanage dontaudit off/on`: **hueco declarado** — solo
   `semodule -D/-B` está documentado con precisión en el man; la equivalencia de `semanage dontaudit`
   procede de una respuesta informal en lista de correo. Usa `semodule`.
6. **Estado de los feature gates de SELinux en Kubernetes** en la versión exacta del cluster
   (verificado ago-2026: `SELinuxMountReadWriteOncePod` y `SELinuxChangePolicy` **GA en v1.36**;
   `SELinuxMount` **beta y off por defecto en v1.36**, con GA prevista en v1.37, **aún no
   publicada**). Esto cambia por release: no lo cites de memoria. **Hueco declarado**: la
   configuración específica de **CRI-O** no se verificó.
7. **Estado de labeled NFS por distro**: **hueco declarado** — no se encontró una declaración de
   soporte formal (¿soportado, *tech preview*?) para RHEL 10 u otras. Verifícalo antes de diseñar
   sobre ello.
8. **AppArmor**: última versión y su serie de soporte (verificado ago-2026: **5.0** 23-abr-2026 como
   release *puente* sin soporte largo, **5.0.1** 10-jun-2026, **4.1 LTS** de abr-2025; **4.1.5
   defectuosa**; Ubuntu 24.04 → 4.0.1, Ubuntu 26.04 → 5.0.0~beta1, Debian 13 → 4.1.0). **Huecos
   declarados**: la fecha upstream de **5.0.2**, el detalle del manifiesto de herramientas de 5.0, y
   una confirmación por nota de release de **Debian** de que AppArmor es el MAC por defecto en
   trixie.
9. **Estado del soporte de SELinux en Debian/Ubuntu**: `selinux-basics` 0.6.0 existe y está
   mantenido en trixie. **Hueco declarado**: **no hay evaluación verificada de su usabilidad real**
   (cobertura y frescura de la política empaquetada) — no lo des por bueno sin probarlo tú.
10. **CVEs**: verificados y citables — **CrackArmor** (kernel AppArmor, Qualys 12-mar-2026,
    CVE-2026-23268/23269/23403-23411), **CVE-2026-53362** (RHSB-2026-009, bypass de SELinux y escape
    de contenedor), **CVE-2026-64600** ("RefluXFS", root con SELinux en Enforcing), y los tres
    bypasses de la restricción de userns de Ubuntu (Qualys, mar-2025, **sin CVE asignado**).
    **Huecos declarados**: **no se encontró ningún CVE 2025-2026 específico del userspace de SELinux**
    (`libselinux`, `policycoreutils`, `setools`) ni de `container-selinux` — la release 3.11 menciona
    mejoras de seguridad genéricas sin CVE asociado; y **las fechas de parche por vendor de
    CrackArmor no se verificaron** (consúltalas en el tracker de tu distro). `CVE-2025-0078` circula
    como "bypass de SELinux": **es de Android/AOSP, no del userspace upstream** — no lo cites como
    tal.
11. **Migración de SUSE a SELinux** si operas esa familia (verificado ago-2026: SLES 16.0 GA
    4-nov-2025 con AppArmor eliminado y SELinux enforcing; SLES for SAP en permissive; openSUSE
    Tumbleweed desde el snapshot 20250211 y Leap 16). **Hueco declarado**: el estado de **SLE 15
    SP7** no se verificó individualmente.
12. **Plan de la política fuente hacia CIL**: **hueco declarado** — no se encontró evidencia de
    ningún anuncio de migrar `selinux-policy`/refpolicy a CIL como lenguaje **fuente** por defecto.
    Hoy el camino soportado sigue siendo `.te` + macros de interfaz.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
