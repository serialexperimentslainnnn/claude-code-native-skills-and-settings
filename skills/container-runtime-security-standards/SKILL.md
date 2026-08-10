---
name: container-runtime-security-standards
description: Container runtime security and container escape defense. Use when writing or debugging seccomp profiles (RuntimeDefault, seccomp.json, --security-opt seccomp), choosing or pinning a container runtime (runc, crun, gVisor/runsc, Kata Containers, RuntimeClass), rootless Podman or user namespaces (hostUsers, /etc/subuid), --privileged, capability drops (CAP_SYS_ADMIN, CAP_SYS_MODULE, CAP_BPF), a mounted docker.sock or containerd.sock, hostPath/hostPID/hostNetwork/hostIPC exposure, runtime detection with Falco rules, Tetragon TracingPolicy, Tracee or KubeArmor, eBPF agent privileges, container drift and read-only rootfs, or forensic container checkpointing with CRIU/checkpointctl and node/runtime log capture.
---

# Estándares de seguridad del contenedor en ejecución

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **la seguridad del contenedor cuando ya está corriendo**: donde el manifiesto ya no
protege porque el proceso existe, tiene un kernel compartido debajo y un atacante dentro. Cubre el
modelo de aislamiento y sus límites, la elección y fijación del runtime, rootless y user
namespaces, seccomp, las rutas de escape de contenedor y su mitigación, la detección en tiempo de
ejecución (eBPF, Falco, Tetragon, Tracee, KubeArmor), el drift del contenedor inmutable, la
verificación de firma en el momento de ejecutar, el forense de contenedor y de nodo, y los
benchmarks aplicables.

Triggers: `seccomp`, `RuntimeDefault`, `seccomp.json`, `--security-opt seccomp=`,
`SeccompDefault`/`--seccomp-default`, `runc`, `crun`, `runsc`/gVisor, `kata-runtime`,
`containerd-shim-kata-v2`, `RuntimeClass`, `hostUsers`, `/etc/subuid`, `/etc/subgid`, rootless
Podman, `--privileged`, `no-new-privileges`, `CAP_SYS_ADMIN`, `CAP_SYS_MODULE`,
`CAP_DAC_READ_SEARCH`, `CAP_BPF`, `docker.sock`, `containerd.sock`, `crio.sock`, `hostPath`,
`hostPID`, `hostNetwork`, `hostIPC`, `/proc` y `/sys` montados, cgroups v1/v2, `falco`,
`falco_rules.yaml`, `tetragon`, `TracingPolicy`, `tracee`, `kubearmor`, `bpftool`,
`unprivileged_bpf_disabled`, `readOnlyRootFilesystem`, `criu`, `checkpointctl`, `/checkpoint/` del
kubelet, `kube-bench`, `docker-bench`, "escape de contenedor", "el contenedor se ha modificado en
ejecución".

**Principio rector**: **un contenedor es un proceso del host con namespaces y cgroups, no una
máquina virtual.** Comparte kernel, y por tanto comparte superficie: cada capability, cada montaje
del host y cada syscall no filtrada es una vía directa al nodo. Toda la §3 se deriva de ese hecho.
Corolario operativo: **lo que impide el escape es la configuración del runtime; lo que te entera de
que ha ocurrido es la detección en runtime. Son controles distintos y hacen falta los dos.**

**Postura**: esta skill es **defensiva**. Describe **clase de riesgo, indicador y mitigación**.
No contiene payloads, cadenas de explotación ni recetario paso a paso; lo ofensivo autorizado vive
en `offensive-security-standards`.

**No aplica**: ver `kubernetes-standards` (**división ya pactada por ambos lados**: allí *admisión*,
políticas Kyverno/Gatekeeper, Pod Security Standards, `securityContext` como **hardening declarativo
del Pod**, firma en admisión y toda la construcción de la imagen; **aquí** lo que ocurre después de
que el Pod arranca: runtime, seccomp, escape, detección, drift y forense de nodo);
`selinux-standards` (**el MAC del contenedor es suyo, sin excepción**: `container_t`,
`container_file_t`, categorías MCS, `container-selinux`, `:z`/`:Z`, `udica`, `seLinuxOptions`,
`seLinuxChangePolicy` y la autoría de perfiles AppArmor. **Aquí**: `seccomp` —que es de esta skill—,
y **detectar que el MAC se ha desactivado, se ha eludido o que un proceso ha escapado pese a él**;
si el problema es un AVC o una etiqueta, es de allí); `linux-hardening-standards` (**baseline del SO
del nodo**: CIS/STIG, `sysctl`, auditd, SSH, montajes, arranque medido — el nodo endurecido es su
frontera; aquí solo los `sysctl` y capabilities específicos del runtime y por qué importan);
`operating-systems-standards` (**el mecanismo es suyo**: qué es de verdad un namespace, qué aísla
un cgroup y qué **no** aísla ninguno de los dos; **aquí seccomp, el escape y su detección**);
`onprem-standards` (paraguas de plataforma: hardware, hipervisor, flota, plano OOB);
`incident-response-forensics-standards` (**el proceso forense completo**: fases, cadena de custodia,
orden de volatilidad, imaging, timeline, Velociraptor/Volatility — **aquí solo qué artefacto de
contenedor y de nodo existe, cuánto dura y cómo se captura antes de evaporarse**);
`incident-management-standards` (gobierno del incidente: severidad, IC, comunicación);
`detection-engineering-standards` (**frontera decidida y declarada**: *qué
señal de runtime importa y qué debe disparar* es de esta skill —ejecución inesperada de shell,
escritura en binarios, cambio de capabilities, montaje del socket—; *el ciclo de vida de la regla*
—backlog, cobertura ATT&CK, umbrales, tuning, gestión de falsos positivos, framework de test y
destino en el SIEM— es suyo. La regla Falco **nace aquí y se gobierna allí**);
`observability-standards` (recogida, retención y correlación de la telemetría);
`vulnerability-management-standards` (triaje y SLA de los CVE de runtime que se citan aquí);
`cicd-standards` (la pipeline que construye, firma y publica); `iac-standards` (aprovisionamiento
del nodo); `appsec-standards` (el fallo en el código de la aplicación que da la RCE inicial);
`cryptography-pki-standards` (custodia de claves de firma); `secrets-management-standards`
(custodia y rotación de los secretos que el contenedor consume);
`bcdr-standards` (continuidad y recuperación de la plataforma);
`offensive-security-standards` y `ctf-lab-standards` (verificación ofensiva del aislamiento y
detonación de muestras, **con alcance y autorización por escrito**; esta skill es defensiva);
`podman-systemd-containers-standards` (Podman y Quadlet como **forma de
ejecutar servicios** bajo systemd; **aquí su seguridad**); `linux-administration-standards` y
`ha-clustering-standards`; `azure-standards`/`aws-standards`/
`gcp-standards` (el runtime del nodo gestionado y sus advisories de imagen de nodo);
`grc-compliance-standards` (el control exigido y su evidencia); `webassembly-standards`
(el sandbox de un módulo Wasm y sus importaciones son suyos; **el aislamiento del nodo
que ejecuta el host de Wasm sigue siendo de aquí** — un host de Wasm es un proceso más, con su
`seccomp`, sus capacidades y su superficie de escape).

Nota cruzada: `windows-server-ad-standards` comparte con esta skill el patrón *plataforma cuyo
compromiso es total* — un nodo comprometido lo es para todos sus contenedores igual que un DC lo es
para todo el dominio. El criterio de contención por capas es análogo; el dominio técnico, no.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8). Este dominio se
> mueve por CVE de escape: una versión mínima aquí caduca de un día para otro.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Runtime OCI | **`crun`** en hosts cgroup v2; `runc` donde lo imponga la plataforma | Base de código mucho menor (C frente a Go), menor consumo y sin coste de compatibilidad. Verificado ago-2026: es el **default de Podman en RHEL/Fedora y de OpenShift**; el cambio es transparente para la carga |
| Versión mínima de runc | **1.2.8 / 1.3.3 / 1.4.0-rc.3 o superior** | Corrige la tríada de escape de nov-2025 (**CVE-2025-31133, CVE-2025-52565, CVE-2025-52881**): bypass de `maskedPaths`, redirección del montaje `/dev/console` y bypass de comprobaciones LSM vía `/proc/self/attr/*` hacia `core_pattern`/`sysrq-trigger`. **containerd 1.6.39+ / 1.7.28-2+** incorpora el fix. Un CVSS 4.0 "medium" **engaña**: refleja el modelo de amenaza de runc, no el de Kubernetes |
| Aislamiento reforzado | **gVisor (`runsc`)** para código no confiable orientado a red; **Kata Containers** cuando gVisor rompe por compatibilidad de kernel | Se activan por `RuntimeClass`, no globalmente. gVisor interpone un kernel en userspace (compatibilidad parcial, sin módulos ni syscalls exóticas); Kata arranca una microVM por Pod (compatibilidad total, coste de arranque y memoria). Kata **4.0.0** (20-jul-2026); su rama de Confidential Containers (SEV-SNP/TDX) es el escalón siguiente |
| Cuándo se justifica el coste | **Multi-tenant hostil, ejecución de código de terceros, detonación de muestras, build de código no confiable** | Fuera de esos casos, el sobrecoste no compra riesgo evitado: gasta ese presupuesto en rootless, seccomp y detección. Decisión explícita y documentada, nunca "por si acaso" |
| Modelo de ejecución | **Rootless siempre que sea posible** (Podman rootless; `hostUsers: false` en Kubernetes) | Un escape en rootful da **root en el nodo**; en rootless da **el usuario sin privilegios**. Verificado ago-2026: **user namespaces GA en Kubernetes v1.36** (beta activada por defecto desde 1.33); **exige kernel ≥6.3 en el nodo** — comprueba `uname -r`, muchos nodos gestionados no llegan |
| Docker rootless | **Solo como transición**; el destino es Podman rootless o Kubernetes con userns | Es un retrofit opt-in con limitaciones de red y almacenamiento (`fuse-overlayfs` en vez de overlay2, ~25-30 % de sobrecoste de arranque). En Podman rootless es el diseño, no un modo |
| Capabilities | **`drop: ALL`** y añadir la mínima lista justificada por escrito | Cada capability añadida es una vía de escape potencial. `CAP_SYS_ADMIN` equivale prácticamente a root en el host |
| Escalada | **`no-new-privileges` / `allowPrivilegeEscalation: false`** siempre | Neutraliza el binario SUID como escalón dentro del contenedor. No tiene contraindicación real |
| seccomp | **`RuntimeDefault` como suelo universal**; perfil a medida solo para cargas de alto riesgo | Verificado ago-2026: `SeccompDefault` sigue siendo **feature gate del kubelet + flag `--seccomp-default`**, no un default de cluster. **Si no lo activas, tus Pods corren `Unconfined`** salvo que el manifiesto lo diga. En control plane gestionado puede no estar a tu alcance: entonces se impone por admisión (`kubernetes-standards`) |
| MAC del contenedor | **Activo y en enforcing** (`container_t` + MCS, o perfil AppArmor) | La política y su autoría son de `selinux-standards`. **Aquí la regla es**: su desactivación (`label=disable`, `unconfined`) es un **evento de seguridad** que debe alertar |
| Detección en runtime | **Falco** como base (CNCF **graduado desde 29-feb-2024**; **v0.44.1**, jun-2026) | Es el default por madurez, gobernanza neutral y ecosistema de reglas. **Tetragon** cuando además quieres *prevención* en kernel (`bpf_send_signal`) o ya tienes Cilium; **Tracee** por su enfoque forense, asumiendo su mayor coste; **KubeArmor** (CNCF *Sandbox*) cuando el objetivo es *hardening* least-privilege vía LSM más que detección, o hay edge/IoT |
| Filesystem | **`readOnlyRootFilesystem: true`** + `emptyDir` para lo escribible | Sin esto no hay contenedor inmutable ni detección de drift creíble |
| Verificación de firma | **En admisión y, para lo crítico, también en el nodo al ejecutar** | La admisión valida lo que se pide; el runtime valida lo que realmente se ejecuta (`policy.json` de Podman/CRI-O con `sigstoreSigned`). No son redundantes |
| Escaneo en la cadena | **Grype + Syft** por defecto | Alineado con `kubernetes-standards` tras el **compromiso de `trivy-action`/`setup-trivy` (marzo 2026)**. Si usas Trivy: pin por digest, verifica firma y sigue sus advisories |

## 3. Modelo de aislamiento, escape y detección

### 3.1 Qué comparte un contenedor con el host (y por qué eso lo es todo)

- **Se comparte el kernel**: syscalls, tablas de páginas, drivers, `/proc` y `/sys` del host. Un
  fallo de kernel es un fallo de *todos* los contenedores del nodo a la vez.
- **Namespaces** (pid, net, mnt, uts, ipc, user, cgroup) dan *vista* separada, no *privilegio*
  separado — salvo el **user namespace**, que es el único que separa de verdad la identidad.
- **cgroups** limitan recursos, no acceso. Un cgroup no contiene a un atacante; evita que tire el
  nodo por consumo. **cgroups v2 es el requisito**: v1 tiene una superficie de escape conocida
  (delegación del controlador y `release_agent`) que v2 no reproduce, además de ser el modelo que
  asumen las herramientas modernas. **Un nodo en cgroups v1 en 2026 es un hallazgo.**
- Lo que realmente confina: **seccomp** (qué syscalls existen), **capabilities** (qué puede pedir
  al kernel), **MAC** (qué objetos puede tocar) y **user namespace** (con qué identidad real).
  Los cuatro a la vez o el modelo es de mentira.

### 3.2 Rutas de escape: clase de riesgo, indicador y mitigación

Se listan como **superficie a cerrar y a vigilar**, no como procedimiento.

| Clase de riesgo | Por qué es total | Mitigación (obligatoria) | Indicador a detectar |
|---|---|---|---|
| **Socket del runtime montado** (`docker.sock`, `containerd.sock`, `crio.sock`) | Quien habla con el socket **crea contenedores**: crear uno privilegiado con el nodo montado es root en el host. Montarlo **es** conceder root, no "dar acceso a la API" | **Prohibido** (§7). Si un agente necesita datos del runtime, usa su API con RBAC y solo lectura, o un socket-proxy con allowlist de endpoints | Contenedor con el socket en su lista de montajes; llamadas de creación desde una identidad que no es el orquestador |
| **`--privileged` / `privileged: true`** | Devuelve todas las capabilities, desactiva los filtros por defecto y expone dispositivos: es renunciar al aislamiento en un flag | **Prohibido** salvo excepción firmada, con caducidad, en namespace propio y en nodo dedicado | Cualquier Pod privilegiado que no esté en la lista de excepciones |
| **`hostPath` a rutas sensibles** (`/`, `/etc`, `/var/run`, `/var/lib/kubelet`, `/root`, `/proc`, `/sys`, dispositivos de bloque) | El filesystem del nodo montado es persistencia, robo de credenciales del kubelet y modificación de binarios del host | Prohibido a rutas sensibles; lo legítimo se resuelve con CSI o subruta dedicada y `readOnly: true` | Montaje nuevo de hostPath; escritura en rutas del host desde un contenedor |
| **`hostPID` / `hostNetwork` / `hostIPC`** | `hostPID` da visibilidad y señalización a procesos del nodo (y lectura de su `/proc/<pid>/environ`); `hostNetwork` elimina el aislamiento de red y expone servicios locales del nodo; `hostIPC` comparte memoria con el host | Prohibidos salvo agente de infraestructura justificado | Carga de aplicación con cualquiera de los tres |
| **Capabilities peligrosas**: `CAP_SYS_ADMIN`, `CAP_SYS_MODULE`, `CAP_SYS_PTRACE`, `CAP_DAC_READ_SEARCH`, `CAP_BPF`, `CAP_NET_ADMIN`, `CAP_SYS_RAWIO` | `SYS_ADMIN` es root a efectos prácticos; `SYS_MODULE` carga código en el kernel; `DAC_READ_SEARCH` lee cualquier fichero por handle; `BPF` permite instrumentar el kernel entero | `drop: ALL` + allowlist justificada. `SYS_MODULE` y `SYS_RAWIO`: **nunca** | Cambio del conjunto de capabilities de un proceso ya arrancado; carga de módulo de kernel |
| **`/proc` y `/sys` expuestos o desenmascarados** (`procMount: Unmasked`, montaje del `/proc` del host) | Los `maskedPaths`/`readonlyPaths` del runtime existen precisamente porque `core_pattern`, `sysrq-trigger`, `uevent_helper` y `kcore` son vías directas al nodo | Nunca `Unmasked`; nunca montar `/proc` del host | Escritura sobre ficheros de `/proc` y `/sys` normalmente enmascarados |
| **CVE de escape del runtime** (clase, no receta) | Precedente verificado: tríada runc de **nov-2025** (`CVE-2025-31133`, `-52565`, `-52881`), toda ella por manipulación de montajes en la creación del contenedor, alcanzable **desde una imagen o Dockerfile hostil** | Fijar versión mínima parcheada (§2), reconstruir la imagen de nodo, no ejecutar imágenes de origen no verificado. Mitigación upstream si no puedes parchear ya: **user namespaces sin mapear el root del host** | Advisories del proveedor de nodo (EKS/AKS/GKE) y versión de la imagen de nodo en el inventario |
| **cgroups v1** | Superficie de escape ya conocida y sin razón para existir hoy | Migrar el nodo a cgroups v2 (unificado) | Nodo reportando cgroup v1 en el inventario |
| **Kernel comprometido por debajo del MAC** | Un fallo de kernel anula SELinux/AppArmor y el aislamiento entero (`selinux-standards` documenta casos verificados de 2026) | Parcheo de kernel con prioridad; aislamiento reforzado para lo no confiable | Versión de kernel del nodo frente al advisory vigente |

### 3.3 seccomp con criterio

- **`RuntimeDefault` es el suelo, no el objetivo.** Bloquea el grupo de syscalls que nadie legítimo
  usa (`kexec_load`, `init_module`, `bpf` sin capability, etc.) con una tasa de rotura muy baja.
  **Verifícalo activado de verdad**: el default de Kubernetes sin `--seccomp-default` es
  `Unconfined`, y ese es el fallo silencioso más frecuente del dominio.
- **El perfil por defecto difiere entre runtimes** (containerd vs CRI-O), entre versiones y entre
  arquitecturas. Un perfil probado en x86_64 no está probado en arm64.
- **Perfil a medida**: solo para cargas de alto valor o expuestas a entrada no confiable. Se genera
  a partir de **observación real** (grabación de syscalls de la carga ejercitando su camino
  completo: arranque, tráfico, rotación de logs, apagado), no de una lista teórica.
- **Lista de bloqueo, no de permiso, salvo que puedas mantenerla**: un allowlist estricto rompe con
  cada actualización de runtime, libc o del propio lenguaje. Si lo adoptas, asume el mantenimiento
  como parte del ciclo de vida de la imagen.
- **`SCMP_ACT_LOG` antes que `SCMP_ACT_ERRNO`**: el perfil nuevo se despliega primero en modo
  registro sobre tráfico real, se revisa lo que habría bloqueado, y solo entonces se hace efectivo.
  Saltarse esta fase es programar una caída.
- El perfil es **código versionado** junto a la carga, con su prueba (§4). Un perfil que solo
  existe en un nodo es drift.

### 3.4 Detección en runtime

- **eBPF es la tecnología, no el control.** Da visibilidad de syscalls y eventos de kernel con bajo
  coste y sin módulos. Pero **cargar programas eBPF es una capacidad casi-root**: `CAP_BPF` (más
  `CAP_PERFMON`/`CAP_NET_ADMIN` según el tipo de programa) permite instrumentar el kernel entero.
  Reglas duras:
  - `kernel.unprivileged_bpf_disabled = 1` en todos los nodos, más endurecimiento del JIT
    (`net.core.bpf_jit_harden`), verificado por el baseline del nodo (`linux-hardening-standards`).
  - **Inventario explícito de quién tiene `CAP_BPF`/`CAP_SYS_ADMIN`**: casi siempre es un DaemonSet
    de observabilidad o de seguridad. Cada uno es un objetivo de cadena de suministro de máximo
    valor: un agente comprometido **puede silenciar selectivamente sus propias alertas y seguir
    pareciendo sano**.
  - **La carga de un programa eBPF nuevo es en sí una señal a detectar.** Un rootkit eBPF filtra el
    flujo de eventos que lee tu agente, que reportará fielmente datos ya manipulados: por eso hace
    falta una segunda fuente independiente (auditd del nodo, telemetría del runtime, control plane).
  - CVE reciente verificada como clase de riesgo: **CVE-2026-64036** (OOB en la ruta de
    `css_rstat_updated()` vía kfunc BPF, 7.8) — patrón repetido de bug de kfunc/verificador
    alcanzable por quien ya puede cargar programas.
- **Señales que importan de verdad** (esta skill decide *qué* debe disparar; el ciclo de vida de la
  regla es de `detection-engineering-standards`):
  - **Ejecución de shell o intérprete dentro de un contenedor** que no lo tiene como entrypoint —
    la señal de mayor relación valor/ruido del dominio.
  - **Escritura sobre binarios o rutas del sistema del contenedor** (`/bin`, `/usr`, `/lib`) y
    cualquier escritura si el rootfs es read-only (imposible por diseño ⇒ hallazgo).
  - **Cambio del conjunto de capabilities o del `no_new_privs`** de un proceso ya en marcha; uso de
    `setuid`/`setgid` inesperado.
  - **Acceso a `/proc` y `/sys` enmascarados**, a `/var/run/*.sock` del runtime, o al filesystem del
    nodo desde un contenedor.
  - **Conexión saliente a destino no previsto** (C2, exfiltración, minado) y resolución DNS anómala.
  - **Ejecución de binario que no venía en la imagen** (drift, §3.5), descarga y ejecución en
    memoria, `curl|sh`.
  - **Lectura de credenciales**: token de ServiceAccount, `/var/lib/kubelet`, IMDS del proveedor.
  - **Desactivación de controles**: MAC pasado a permisivo, perfil AppArmor `unconfined`, seccomp
    retirado, agente de detección detenido.
- **Antes de escribir reglas propias, agota el ruleset mantenido.** Falco trae reglas revisadas por
  la comunidad; el trabajo real es el *tuning* por entorno, no la creatividad. Toda regla propia
  nace con su prueba de disparo (§4).
- **La detección sin respuesta es decoración.** Cada señal de alta confianza tiene destino
  (`observability-standards`), dueño y acción — aislar el Pod, capturar (§3.6), escalar. Sin eso,
  el agente solo gasta CPU.

### 3.5 Contenedor inmutable y drift

- El contrato es: **la imagen es el contenedor**. `readOnlyRootFilesystem: true`, escritura solo en
  volúmenes declarados, cero instalación de paquetes en ejecución, cero `exec` de operador en
  producción fuera de break-glass.
- **Un contenedor que se modifica en ejecución es un hallazgo**, no una anomalía operativa: o es
  compromiso, o es una práctica de despliegue que debe corregirse. Ambas cosas se investigan.
- La comparación *imagen declarada ↔ proceso en ejecución* (binario ejecutado que no está en las
  capas, fichero nuevo en rutas del sistema) es una detección de alto valor y bajo ruido.
- `kubectl exec`/`podman exec` en producción: registrado, atribuido a una persona y alertado. Es a
  la vez herramienta legítima de emergencia y la técnica más cómoda para un atacante con
  credenciales del control plane.

### 3.6 Forense de contenedor y de nodo: la evidencia se evapora por diseño

- **El problema**: el orquestador **reprograma o reinicia el Pod**, y con él desaparecen memoria,
  procesos, ficheros temporales y el propio filesystem escribible. En un incidente, el
  comportamiento por defecto de la plataforma **destruye la prueba** mientras "se recupera".
- **Regla de oro**: ante sospecha, **capturar antes de contener**, y contener sin borrar. Aislar la
  red del Pod y marcar el nodo (`cordon`) preserva más que matar el Pod. El orden de volatilidad y
  la cadena de custodia son de `incident-response-forensics-standards`; **lo que sigue es qué
  artefacto existe en este dominio y cuánto dura**.
- **Checkpoint forense (CRIU)**: la API de checkpoint del kubelet crea una copia con estado
  (memoria, descriptores, sockets) **sin que el contenedor lo perciba**, para analizarla en un
  entorno aislado. Verificado ago-2026: **alpha en v1.25, beta y activada por defecto desde v1.30**;
  se invoca por `POST` al kubelet (`/checkpoint/<ns>/<pod>/<container>`, acceso restringido a
  administradores del cluster) y se inspecciona con **`checkpointctl`**. El **restore no está en el
  kubelet a propósito**: ocurre fuera de Kubernetes, en el motor de contenedores. **Un checkpoint
  contiene secretos y datos personales en memoria: trátalo con el mismo control que una imagen de
  RAM.**
- **Artefactos que sí sobreviven y hay que recoger**: logs del runtime (containerd/CRI-O) y del
  kubelet en el nodo, journal y auditd del host, eventos del control plane y del API server,
  registros del agente de detección (eBPF), capas de imagen y su digest real ejecutado, montajes y
  volúmenes persistentes, e imagen de disco/memoria del **nodo** si el compromiso es de nodo.
- **Si el compromiso es del nodo, el nodo entero es evidencia y ya no es de confianza**: se aísla,
  se preserva y se **reconstruye desde fuente confiable**; no se "limpia". Toda credencial que
  pasara por él (tokens de ServiceAccount, credenciales de IMDS, secretos montados) se considera
  comprometida y se rota.
- **Ensáyalo**. Un procedimiento de captura que nadie ha ejecutado nunca no funciona el día que
  hace falta, porque para entonces el Pod ya se reprogramó tres veces.

### 3.7 Cadena de suministro en el momento de ejecutar

- La admisión valida **lo que se pide**; el nodo ejecuta **lo que finalmente se descarga**.
  Verificación de firma también en el motor (`policy.json` con `sigstoreSigned` en Podman/CRI-O)
  para lo crítico, y **pin por digest** en todas partes: un tag es mutable por definición.
- **Precedente vigente**: el compromiso de `trivy-action`/`setup-trivy` de **marzo de 2026** y la
  campaña de envenenamiento de tags de 2026 (documentada en `offensive-security-standards`)
  demuestran que **la herramienta de seguridad es objetivo prioritario** — corre en CI y en los
  nodos, con privilegios altos, por diseño. Todo agente de runtime se fija por digest, se verifica
  su firma y se sigue su canal de advisories como si fuera parte del kernel.
- Registry privado con pull-through; nunca pull directo desde registries públicos en producción.

### 3.8 Hardening del nodo: la frontera

El nodo es de `linux-hardening-standards`, y su baseline (CIS/STIG, `sysctl`, auditd, montajes, MAC
en enforcing) es requisito previo, no complemento. **De este lado quedan solo** los invariantes que
existen por el hecho de ejecutar contenedores:

- cgroups **v2**, kernel ≥6.3 si se usan user namespaces, MAC en enforcing y activo para contenedor.
- `unprivileged_bpf_disabled=1` + JIT hardening; inventario de portadores de `CAP_BPF`.
- Socket del runtime con permisos mínimos y **nunca** expuesto por red ni montado en contenedores.
- Nodos segmentados por confianza: cargas hostiles o multi-tenant en **pool de nodos propio**, con
  su `RuntimeClass` reforzada. Mezclar tenants hostiles con cargas internas en el mismo nodo anula
  cualquier política que escribas encima.
- Imagen de nodo **inmutable y reconstruible**, actualizada por reemplazo, no por parcheo en vivo.

### 3.9 Benchmarks aplicables

- **CIS Kubernetes Benchmark v1.11.0**, auditado con `kube-bench` (perfil `cis-1.11`). Verificado
  ago-2026: ese perfil **cubre Kubernetes 1.29–1.32**; para clusters más nuevos sigue siendo la
  referencia práctica, pero **la cobertura no es oficial** — decláralo al reportar. **Nunca cites
  "el CIS de Kubernetes" en genérico: el CIS va por versión de producto.**
- **CIS Docker Benchmark**, auditado con `docker-bench` (que elige el set según la versión del
  demonio). **Hueco declarado (§8)**: no se confirmó el número de versión vigente en ago-2026.
- **NSA/CISA Kubernetes Hardening Guidance**: verificado ago-2026, **la versión vigente sigue siendo
  la 1.2, de 29-ago-2022**, sin revisión posterior localizada. Es una guía de *criterio* (explica el
  porqué y la vista del atacante) y **complementa** al CIS, que es de *configuración*. Úsala como
  argumento de diseño, no como checklist automatizable, y **ten presente su antigüedad**: no cubre
  user namespaces GA, cgroups v2 ni la generación actual de detección eBPF.
- El benchmark **mide**, no protege. Un score alto con un `docker.sock` montado sigue siendo un
  compromiso a un paso.

## 4. Gates de calidad (rompen el build o el despliegue)

1. **Perfil seccomp probado, no supuesto.** Gate funcional: la carga ejercita su camino completo
   (arranque, tráfico real, rotación de logs, apagado, reinicio) con el perfil activo y **sin una
   sola syscall denegada inesperada**. Que el contenedor arranque no prueba nada — las syscalls que
   faltan aparecen en el caso raro, en producción, de madrugada. Fase previa obligatoria en modo
   registro (§3.3).
2. **Política de runtime verificada en CI y en el nodo.** El pipeline falla ante `--privileged`,
   socket del runtime montado, `hostPath` a ruta sensible, `hostPID`/`hostNetwork`/`hostIPC`,
   capability vetada, ausencia de `seccompProfile` o `readOnlyRootFilesystem: false` sin excepción
   firmada. La misma política corre en admisión (`kubernetes-standards`) y **como verificación del
   estado real del nodo**, porque lo que se admitió no siempre es lo que corre.
3. **Test de que la detección dispara — validación adversaria.** Gate propio y no negociable: en un
   entorno de pruebas se ejecutan acciones benignas equivalentes a las técnicas vigiladas (abrir una
   shell en un contenedor que no la tiene, escribir en `/usr/bin`, leer un fichero de `/proc`
   enmascarado, montar un socket, iniciar una conexión saliente inesperada) y **se comprueba que la
   alerta llega a su destino con el contexto correcto**. Una regla que nunca se ha visto disparar no
   está desplegada, está escrita. Se re-ejecuta tras cada actualización de agente, kernel o runtime.
4. **Versión de runtime y de kernel verificadas contra el advisory vigente** en cada nodo del
   inventario, como gate de despliegue. Un nodo con runc por debajo del mínimo de §2 no admite
   cargas.
5. **Prueba de captura forense ensayada**: checkpoint de un Pod de prueba, inspección con
   `checkpointctl`, y recogida de los artefactos de §3.6 con su tiempo medido. Se ensaya al menos
   una vez por semestre y tras cada cambio de runtime.
6. **Inventario de excepciones con dueño y caducidad**: cada Pod privilegiado, cada capability
   añadida, cada `hostPath`, cada contenedor con MAC desactivado. Sin dueño y sin fecha, la
   excepción se retira.
7. **Benchmark ejecutado y con tendencia** (`kube-bench`, `docker-bench`): el valor está en la
   **serie temporal y en el tratamiento de las excepciones**, no en el número.

## 5. Seguridad: qué protege esto y qué no

- **Lo que aporta**: convierte "RCE en la aplicación" en "RCE dentro de un proceso sin privilegios,
  sin syscalls peligrosas, sin acceso al nodo y **con alguien mirando**". Es contención más
  detección; ninguna de las dos sola basta.
- **Lo que no aporta**: no arregla la vulnerabilidad de la aplicación (`appsec-standards`) ni un
  fallo de kernel. **Frente a un 0-day de kernel, el único aislamiento real es el que no comparte
  kernel** (Kata/microVM) o no comparte nodo.
- **Multi-tenant hostil**: si ejecutas código de terceros, el aislamiento por namespaces **no es
  suficiente por diseño**. La postura correcta es aislamiento reforzado + nodo dedicado + detección,
  y asumir el escape como escenario, no como hipótesis.
- **El agente de seguridad es superficie de ataque de máximo valor**: privilegiado, en todos los
  nodos, con acceso al kernel. Se fija por digest, se firma, se verifica y se vigila su propia
  salud — un agente caído o silenciado es una alerta de severidad alta, no una incidencia de
  observabilidad.
- **Secretos en runtime**: variables de entorno visibles en `/proc/<pid>/environ` (y por tanto para
  cualquiera con `hostPID` o `CAP_SYS_PTRACE`), tokens de ServiceAccount montados por defecto,
  credenciales de IMDS alcanzables desde el Pod. Preferir fichero sobre variable de entorno,
  `automountServiceAccountToken: false` y bloqueo del acceso a IMDS desde cargas. Custodia y
  rotación: `secrets-management-standards`.
- **Desactivar un control "para que funcione" es una decisión de riesgo**, y se toma como tal: con
  dueño, ticket, caducidad y compensación. Nunca en caliente y nunca como default silencioso.

## 6. Rendimiento y operabilidad

- **Coste realista**: seccomp `RuntimeDefault` y MAC son prácticamente gratis. gVisor paga en
  syscalls intensivas y I/O; Kata paga en arranque y memoria por Pod. Rootless paga ~25-30 % de
  arranque y `fuse-overlayfs`. Ninguno de esos costes justifica correr como root: mídelos en tu
  carga antes de descartarlos por rumor.
- **La detección tiene coste y ruido**: dimensiona CPU y volumen de eventos del agente, y trátalo
  como carga de plataforma con sus propios límites. Un agente sin límites que satura el nodo es un
  incidente de disponibilidad causado por seguridad. Verificado ago-2026: **Tracee consume
  notablemente más que Falco o Tetragon** en entornos de alto volumen (2-4× frente a Tetragon según
  reportes) y su configuración por defecto genera un volumen de eventos abrumador — **se despliega
  con filtrado desde el primer día, no después**.
- **Runbook escrito y probado** para: Pod sospechoso (aislar, capturar, escalar), nodo sospechoso
  (cordon, preservar, reconstruir), agente caído, y rollback de un perfil seccomp que rompe
  producción. Sin runbook, la incidencia de las 3 de la mañana acaba en `--privileged`.
- **Rollback**: todo endurecimiento de runtime (perfil nuevo, `RuntimeClass` reforzada, userns) se
  despliega por anillos con su reversión probada.
- **Cambios de kernel y de runtime rompen perfiles y agentes**: cada actualización del nodo
  re-ejecuta los gates 1, 3 y 4 de §4. Es la causa número uno de detección que deja de funcionar en
  silencio.

## 7. Sostenibilidad y prohibiciones

**Cadencia**
- **Advisories de runtime (runc, crun, containerd, CRI-O, gVisor, Kata) con seguimiento activo**: es
  el canal por el que llega el escape. Revisión al menos mensual y reacción inmediata a lo crítico.
- Kernel del nodo: prioridad máxima de parcheo cuando el hallazgo permita escape o bypass de MAC.
- Falco/Tetragon/Tracee/KubeArmor: versión y ruleset revisados trimestralmente; el ruleset envejece
  más rápido que el binario.
- Revisión trimestral del inventario de excepciones (§4.6) y del inventario de portadores de
  `CAP_BPF`/`CAP_SYS_ADMIN`.
- Reconstrucción programada de la imagen de nodo aunque nada cambie.

**PROHIBIDO** (gate automático donde sea posible)
- ❌ **Montar el socket del runtime** (`docker.sock`, `containerd.sock`, `crio.sock`) en un
  contenedor. Es conceder root en el nodo, con otro nombre.
- ❌ **`--privileged` / `privileged: true`** sin excepción firmada, acotada, caducada y en nodo
  dedicado.
- ❌ **`hostPath` a rutas sensibles** del nodo (`/`, `/etc`, `/proc`, `/sys`, `/var/run`,
  `/var/lib/kubelet`, dispositivos de bloque), y cualquier `hostPath` escribible sin justificación.
- ❌ `hostPID`, `hostNetwork` o `hostIPC` en cargas de aplicación.
- ❌ Correr como **root** (UID 0) sin justificación escrita; y root **con** `hostPath` o capabilities
  añadidas, nunca.
- ❌ `CAP_SYS_MODULE`, `CAP_SYS_RAWIO`; `CAP_SYS_ADMIN`, `CAP_BPF`, `CAP_DAC_READ_SEARCH` y
  `CAP_SYS_PTRACE` fuera de agentes de infraestructura aprobados.
- ❌ **Desactivar seccomp o el MAC "para que funcione"** (`seccompProfile: Unconfined`,
  `--security-opt seccomp=unconfined`, `label=disable`, AppArmor `unconfined`). El camino correcto
  es perfil a medida (seccomp, aquí) o política acotada (MAC, `selinux-standards`).
- ❌ `procMount: Unmasked` o montar `/proc`/`/sys` del host.
- ❌ **Contenedor sin detección en runtime en entorno multi-tenant** o que ejecute código no
  confiable. Sin detección no hay evidencia de que el aislamiento aguanta.
- ❌ Ejecutar código no confiable con runtime compartido (`runc`/`crun`) sin nodo dedicado.
- ❌ Nodos en **cgroups v1**, o con runtime por debajo de la versión mínima parcheada de §2.
- ❌ **Modificar el contenedor en ejecución**: instalar paquetes, parchear en caliente, `exec` de
  operador como práctica habitual, rootfs escribible sin motivo.
- ❌ Imagen por tag mutable o sin verificación de firma en el camino a producción.
- ❌ **Matar o reiniciar un Pod sospechoso antes de capturar evidencia**; borrar el nodo
  comprometido "para recuperar" sin preservarlo.
- ❌ Rehabilitar `unprivileged_bpf_disabled=0` o repartir `CAP_BPF` sin inventario.
- ❌ Agente de detección desplegado sin prueba de disparo (§4.3), o con alertas sin dueño ni destino.
- ❌ Fijar versiones de runtime, estados de feature gate o versiones de benchmark **de memoria**, sin
  la verificación de §8.

### Checklist de revisión rápida (carga que entra en producción)

- [ ] Runtime en versión parcheada; nodo en cgroups v2; kernel al día y ≥6.3 si hay userns.
- [ ] Rootless o `hostUsers: false` donde el nodo lo permite; si no, motivo escrito.
- [ ] `drop: ALL` + allowlist justificada; `allowPrivilegeEscalation: false`; no root o excepción firmada.
- [ ] `seccompProfile` explícito y **verificado activo en el nodo**; perfil a medida probado si aplica.
- [ ] MAC activo y en enforcing para el contenedor (política: `selinux-standards`).
- [ ] Sin socket del runtime, sin `hostPath` sensible, sin `hostPID`/`hostNetwork`/`hostIPC`, sin `privileged`.
- [ ] `readOnlyRootFilesystem: true` + volúmenes declarados; detección de drift activa.
- [ ] Imagen por digest y firma verificada; agente de runtime fijado por digest y firmado.
- [ ] Detección en runtime desplegada, con **prueba de disparo pasada** y alertas con dueño.
- [ ] Aislamiento reforzado (`RuntimeClass`) si la carga es no confiable o multi-tenant hostil.
- [ ] Procedimiento de captura forense ensayado y accesible en el runbook.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, estado de feature o número de benchmark, **búscalo — no lo
recuerdes**:

1. **CVE de escape de runtime**: es el dato que caduca más rápido de todo el documento. Verificado
   ago-2026: la tríada **runc de nov-2025** (`CVE-2025-31133`, `CVE-2025-52565`, `CVE-2025-52881`)
   sigue siendo el conjunto significativo más reciente; parcheada en **runc 1.2.8 / 1.3.3 /
   1.4.0-rc.3+** y **containerd 1.6.39+ / 1.7.28-2+**. **Huecos declarados**: no se verificó la
   **versión estable exacta de runc, crun, containerd y CRI-O** en ago-2026, ni se pudo confirmar el
   reporte aislado de *explotación activa en jun-2026* (una fuente lo afirma, el resto no) — trátalo
   como no confirmado y consulta el advisory upstream.
2. **Estado de user namespaces en Kubernetes** (verificado ago-2026: **GA en v1.36**, abr-2026;
   beta activada por defecto desde 1.33; **requiere kernel ≥6.3**, que muchos nodos gestionados aún
   no tienen). Comprueba tu versión de cluster y `uname -r` del nodo: esto cambia por release.
3. **`SeccompDefault`**: verificado ago-2026 que **sigue siendo feature gate del kubelet + flag
   `--seccomp-default`**, sin default de cluster. **Hueco declarado**: no se confirmó si ha
   graduado a GA ni si hay fecha para hacerlo default; consulta **KEP-2413** y la referencia de
   seccomp de tu versión.
4. **Checkpoint forense**: verificado ago-2026 **beta y activado por defecto desde v1.30**. **Hueco
   declarado**: **no se pudo confirmar su estado en v1.36** (¿sigue beta, ya es GA?). Léelo en las
   release notes de tu versión antes de basar un procedimiento de incidente en ello.
5. **Estado de las herramientas de detección**: verificado ago-2026 — **Falco graduado en CNCF
   (29-feb-2024)**, **v0.44.1** (jun-2026), con la documentación de sonda eBPF legacy, gVisor y gRPC
   retirada en may-2026; **Tetragon** activo como subproyecto de Cilium en CNCF; **Tracee** activo
   (Aqua) con coste notablemente mayor; **KubeArmor** en **CNCF Sandbox**. **Huecos declarados**:
   **no se verificaron las versiones actuales de Tetragon, Tracee ni KubeArmor**, ni señales duras
   de salud de mantenimiento (cadencia de commits, número de mantenedores, cambios de nivel CNCF en
   2026). Compruébalo en sus repos y en el CNCF landscape antes de apostar una plataforma.
6. **Versiones de aislamiento reforzado**: verificado ago-2026 **Kata Containers 4.0.0**
   (20-jul-2026), con bump de kernel del guest por **CVE-2026-31431**. **Hueco declarado**: **no se
   verificó la versión actual de gVisor** (publica releases muy frecuentes) ni la de `crun`.
7. **Benchmarks**: verificado ago-2026 — **CIS Kubernetes Benchmark v1.11.0** (perfil `kube-bench`
   `cis-1.11`, cobertura oficial **K8s 1.29-1.32**) y **NSA/CISA Kubernetes Hardening Guidance
   v1.2 de 29-ago-2022** como versión vigente, sin revisión posterior encontrada. **Huecos
   declarados**: **la versión vigente del CIS Docker Benchmark no se pudo confirmar** (consúltala en
   `cisecurity.org/benchmark/docker`, que solo lista las soportadas), y **no se comprobó si existe
   ya un CIS Kubernetes Benchmark posterior a v1.11.0**.
8. **Endurecimiento eBPF y sus CVE**: verificado ago-2026 **CVE-2026-64036** (OOB vía kfunc
   `css_rstat_updated()`, 7.8 CVSS v3.1 según kernel.org). Revisa el tracker de tu distro para el
   estado de parche y busca CVE posteriores del verificador/kfuncs antes de dar por segura una
   versión de kernel.
9. **Compromisos de cadena de suministro en herramientas de seguridad**: precedente verificado del
   catálogo — **`trivy-action`/`setup-trivy`, marzo de 2026**. Antes de introducir *cualquier* agente
   o escáner nuevo, busca incidentes recientes del proyecto: en este dominio la herramienta corre
   privilegiada en todos los nodos.
10. **Advisories del proveedor de nodo gestionado** (EKS/AKS/GKE) para la versión de imagen de nodo
    que estés ejecutando: el parche de runtime llega por ahí, no por tu pipeline.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
