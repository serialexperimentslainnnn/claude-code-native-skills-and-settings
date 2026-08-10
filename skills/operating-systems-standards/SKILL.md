---
name: operating-systems-standards
description: Operating-system mechanics as an engineering constraint — what the kernel actually does to your program and which design decisions follow from it. Use when reasoning about CPU scheduling and latency (EEVDF versus the older CFS, sysctl_sched_base_slice, nice and sched_setscheduler, SCHED_FIFO/SCHED_RR/SCHED_DEADLINE via chrt, isolcpus and CPU pinning with taskset, sched_ext BPF schedulers, PREEMPT_RT and preempt=none/voluntary/full, interrupt latency and threaded IRQs, cyclictest), the real cost of a system call and a context switch (vDSO, KPTI and speculative-execution mitigation overhead, syscall batching), virtual memory (page faults, TLB misses, transparent huge pages and MADV_HUGEPAGE versus hugetlbfs, vm.overcommit_memory and Committed_AS, the OOM killer and oom_score_adj, memory.high versus memory.max in cgroup v2, PSI pressure metrics, swappiness and zram/zswap), I/O models (blocking versus O_NONBLOCK, select/poll/epoll, io_uring and its security history, O_DIRECT, readahead, page cache and dirty writeback tuning), filesystem durability semantics (fsync, fdatasync, sync_file_range, the fsync error-reporting problem and why a successful write is not a durable write, journalling modes, write barriers and volatile disk caches), namespaces and capabilities as the actual substance of a container, NUMA topology and numactl, virtualization and paravirtualization (KVM, virtio, steal time, ballooning), monolithic versus microkernel designs (seL4, QNX, Redox, Fuchsia/Zircon) and hard versus soft real-time requirements.
---

# Estándares de sistemas operativos aplicados

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **usar el conocimiento del sistema operativo para decidir**: por qué un servicio tiene picos
de latencia que no se explican por el código, por qué el proceso murió sin traza, por qué "lo escribí
y se perdió", cuánto cuesta de verdad una llamada al sistema, qué garantiza y qué no garantiza un
contenedor, y cuándo un requisito de tiempo real es real. **No es teoría de facultad**: cada apartado
existe porque decide una elección de diseño o cierra una discusión.

Triggers: EEVDF, CFS, `sysctl_sched_base_slice`, `nice`, `sched_setscheduler`, `chrt`, `SCHED_FIFO`,
`SCHED_RR`, `SCHED_DEADLINE`, `SCHED_IDLE`, `taskset`, `isolcpus`, `nohz_full`, `sched_ext`/SCX,
`PREEMPT_RT`, `preempt=none|voluntary|full`, `cyclictest`, "latencia de interrupción", vDSO,
`getpid()` barato, KPTI, mitigaciones especulativas, cambio de contexto, `vm.overcommit_memory`,
`CommitLimit`, `Committed_AS`, OOM killer, `oom_score_adj`, `/dev/kmsg` con "Out of memory: Killed
process", `transparent_hugepage`, `MADV_HUGEPAGE`, `hugetlbfs`, TLB, `vm.swappiness`, `zswap`,
`zram`, `memory.max`, `memory.high`, `memory.pressure`, PSI (`/proc/pressure/*`), `cpu.max`,
"throttling de CPU en el contenedor", `epoll`, `io_uring`, `O_NONBLOCK`, `O_DIRECT`, `fsync`,
`fdatasync`, `sync_file_range`, `data=ordered`/`data=writeback`, *write barrier*, caché volátil de
disco, `unshare`, `clone(CLONE_NEW*)`, `/proc/self/ns/`, `capabilities(7)`, `CAP_SYS_ADMIN`,
`numactl`, `numastat`, "acceso remoto a memoria NUMA", KVM, virtio, *steal time*, *ballooning*,
microkernel, seL4, QNX, Redox, Fuchsia/Zircon, "tiempo real duro", "tiempo real blando".

**Principio rector**: **el sistema operativo no es un detalle de implementación; es el que decide.**
Un programa correcto sobre supuestos falsos del SO —que `write()` persiste, que un contenedor aísla,
que un límite de memoria produce un error y no una muerte, que `nice` da tiempo real— falla en
producción de la peor manera: tarde, sin traza y de forma no reproducible. La regla de trabajo que
se deriva: **ningún comportamiento del SO se afirma de memoria; se lee de su documentación o se mide
en el sistema concreto** (§4), porque **la respuesta depende de la versión del kernel, del sistema de
ficheros, del hipervisor y del hardware**, y las cuatro cambian.

**No aplica**: ver `linux-administration-standards` (**la administración diaria es suya, sin
excepción**: unidades systemd y su `Type=`/`Restart=`/dependencias, `journalctl` y retención,
`systemd-analyze blame`, red del host, paquetes, hora, y el **diagnóstico operativo** de un host que
va lento o no arranca. **Frontera precisa y pactada por este lado**: *el pomo de systemd es suyo, la
semántica del kernel que hay detrás es mía* — `MemoryMax=` y `systemd-oomd` se configuran allí;
**por qué `memory.high` estrangula y `memory.max` mata, y por qué eso es una decisión de diseño y no
un accidente, es de aquí**), `performance-engineering-standards` (**la metodología de medición y el
perfilado son suyos**: definir el objetivo de latencia como percentil + concurrencia + hardware,
modelos de carga abierto/cerrado, omisión coordinada, muestreo, *flame graphs*, perfilado continuo,
USE y RED. **Regla de arbitraje: *"¿cómo se mide y cómo se interpreta el número?" es suyo; "¿qué
mecanismo del SO produce ese número y qué se cambia para moverlo?" es de aquí***. Un ajuste de esta
skill sin la medición de la suya es superstición), `container-runtime-security-standards` (**el
aislamiento del contenedor como control de seguridad es suyo**: perfiles seccomp, runtimes
alternativos —gVisor, Kata—, escape, detección en runtime, capabilities como hardening del Pod.
**Aquí solo el mecanismo**: qué es un namespace, qué comparte y qué no, y por qué un contenedor no es
una máquina virtual), `kernel-drivers-standards` (**hermana directa**: el **código** que se escribe
dentro del kernel, su concurrencia —spinlocks, RCU, contextos atómicos—, su DMA, su depuración con
KASAN/lockdep y su proceso upstream. *"¿Cómo escribo este driver?" es suyo; "¿por qué el sistema se
comporta así?" es de aquí*), `linux-hardening-standards` (baseline CIS/STIG y su medida; los
`sysctl` de seguridad son suyos, los de comportamiento del SO son de aquí), `selinux-standards`
(MAC), `linux-storage-standards` y `zfs-standards` (LVM, RAID, capas de bloque, ZFS — **la semántica
de durabilidad y `fsync` se argumenta aquí y se implementa allí**), `sre-practice-standards`
(SLO, error budget), `observability-standards` (plataforma de telemetría), `libvirt-kvm-standards`,
`proxmox-ve-standards`, `vmware-standards`, `hyper-v-standards` y `xen-standards` (**operar el
hipervisor es suyo**; aquí solo qué implica la virtualización para el programa que corre dentro:
*steal time*, reloj, NUMA virtual), `kubernetes-standards` (requests/limits como objeto declarativo;
**aquí qué hace el kernel cuando se alcanza ese límite**), `embedded-iot-standards` (**hermana**:
el dispositivo físico, el RTOS y el superloop — **la discusión de tiempo real duro es
frontera compartida**: el criterio de qué es tiempo real y qué garantiza `PREEMPT_RT` es de aquí, la
elección de RTOS para un MCU es suya), `bsd-systems-standards` y `aix-solaris-hpux-standards` (otros
sistemas operativos como plataforma de producción), `c-standards`, `cpp-standards`, `rust-standards`
y `go-standards` (el lenguaje, su runtime y sus abstracciones sobre todo esto).

## 2. Decisiones por defecto

> Verificar por web contra la versión de kernel concreta antes de fijar nada (§8). Estado
> **verificado** a agosto de 2026 contra el árbol de `git.kernel.org` y `kernel.org`.

| Tema | Default | Cuándo se desvía, y con qué prueba |
|---|---|---|
| Planificación | **No tocar nada.** El planificador por defecto es correcto para el 95% de las cargas | Solo con medida que demuestre que la latencia de planificación —no la de otra cosa— es el cuello |
| Prioridad de tiempo real | **Prohibida por defecto** en servicios de propósito general | Solo con `SCHED_FIFO`/`SCHED_RR` acotado, presupuesto de CPU limitado y watchdog: **un bucle a prioridad RT sin ceder CPU cuelga el núcleo** |
| Fijado de CPU | No | Cuando hay aislamiento estricto de núcleos (`isolcpus`, `nohz_full`) y se ha medido la ganancia frente al coste de perder equilibrado |
| Huge pages | **`madvise`**, no `always` | `always` solo tras medir; `hugetlbfs` con reserva cuando la base de datos o la VM lo pida explícitamente |
| Overcommit | **Modo 0 (heurístico)**, el default del kernel | Modo 2 solo cuando se exige que la asignación falle en vez de que el proceso muera |
| Swap | **Sí, con swap configurado** (aunque sea pequeño, o `zram`/`zswap`) | Sin swap el kernel pierde la vía de reclamar páginas anónimas frías y llega antes al OOM killer: "quitar el swap" **no evita el OOM, lo adelanta** |
| Límite de memoria | **`memory.max`** como red de seguridad + **`memory.high`** para estrangular antes | Ver §6.2: son mecanismos distintos, no dos formas de lo mismo |
| E/S de red concurrente | **`epoll` en modo *level-triggered***, ya sea directo o vía el runtime del lenguaje | `io_uring` solo con justificación medida y decisión de seguridad explícita (§5.3) |
| Durabilidad | **`fsync`/`fdatasync` con el error tratado como fatal** | Nunca "reintentar el `fsync`" (§6.4) |
| Aislamiento fuerte | Máquina virtual | El contenedor **comparte kernel**: si el modelo de amenaza incluye una escalada por fallo del kernel, el contenedor no es la frontera (§5.2) |
| Tiempo real | **Casi siempre es tiempo real *blando*** y se resuelve con presupuesto de latencia y colas | `PREEMPT_RT` cuando el plazo es duro en Linux; RTOS o microkernel cuando el plazo es duro **y** hay que certificarlo |

### 2.1 Planificador vigente — el dato que más se cita mal

**CFS ya no es el planificador de la clase justa de Linux: es EEVDF.** Verbatim de
`Documentation/scheduler/sched-eevdf.rst` en el árbol actual: *"The Linux kernel began transitioning
to EEVDF in version 6.6 … moving away from the earlier Completely Fair Scheduler (CFS) in favor of a
version of EEVDF proposed by Peter Zijlstra in 2023"*. Consecuencias prácticas:

- Los *tunables* clásicos de CFS (`sched_latency_ns`, `sched_min_granularity_ns`) **ya no son el
  modelo**; el parámetro relevante es la *rebanada* base (`sysctl_sched_base_slice`). **Cualquier
  guía de tuning que hable de `sched_latency_ns` está describiendo un kernel que no tienes.**
- EEVDF asigna a cada tarea una *petición* (rebanada) y un plazo virtual, y elige la de plazo más
  temprano entre las que tienen *lag* no negativo. Traducción operativa: una tarea que despierta y
  ha consumido poco **puede expulsar** a la que corre, lo cual **mejora** la latencia interactiva y
  **puede empeorar** el rendimiento agregado de cargas de lotes. Si un cambio de kernel movió el
  perfil de latencia de un servicio, este es el primer sospechoso.
- **`nice` no es prioridad de tiempo real.** Es un peso dentro de la clase justa: un proceso con
  `nice -20` sigue cediendo ante cualquier tarea `SCHED_FIFO`, y no garantiza plazo alguno.
- **`sched_ext` (SCX)** está en mainline desde 6.12: permite cargar planificadores escritos en eBPF y
  cambiarlos en caliente, y la jerarquía de clases queda `stop > deadline > rt > ext > fair (EEVDF)
  > idle`. Es una herramienta real —hay despliegues en juegos y en servidores— **y también una vía
  rápida a un comportamiento no reproducible**: si se usa, el planificador cargado forma parte de la
  configuración versionada del sistema y se declara en cualquier informe de rendimiento.

### 2.2 Tiempo real: duro, blando y `PREEMPT_RT`

**Tiempo real no significa rápido: significa acotado.** Un sistema de tiempo real duro es el que
tiene un plazo cuyo incumplimiento es un fallo del sistema, no una degradación. Casi todo lo que se
llama "tiempo real" en una discusión de backend es **tiempo real blando** y se resuelve con
presupuesto de latencia, colas acotadas y degradación controlada — no tocando el planificador.

`PREEMPT_RT` **está en el árbol principal**, como opción de configuración. Verbatim de
`kernel/Kconfig.preempt`: *"This option turns the kernel into a real-time kernel by replacing various
locking primitives (spinlocks, rwlocks, etc.) with preemptible priority-inheritance aware variants,
enforcing interrupt threading and introducing mechanisms to break up long non-preemptible sections."*
Lo que hay que saber antes de activarlo:

- Depende de `EXPERT` y de `ARCH_SUPPORTS_RT`: **no todas las arquitecturas lo soportan**, y hay que
  comprobarlo para la tuya.
- **Reduce la latencia máxima a costa del rendimiento agregado.** Es un intercambio, no una mejora:
  quien lo activa "por si acaso" paga throughput sin necesitarlo.
- No convierte tu aplicación en tiempo real: si la aplicación reserva memoria en el camino crítico,
  falla de página, toca disco o llama a un servicio remoto, el plazo lo rompe ella. `PREEMPT_RT`
  garantiza el kernel, no tu código.
- **Se verifica midiendo la latencia máxima con carga real** (`cyclictest` con la carga de fondo del
  sistema, durante horas), no leyendo la configuración.

### 2.3 Monolítico frente a microkernel — qué decide de verdad

El debate no lo decide la elegancia ni el rendimiento: lo deciden **la certificación y el
ecosistema de drivers**.

| Sistema | Estado verificado (ago-2026) | Qué lo hace elegible |
|---|---|---|
| **Linux** (monolítico modular) | Mainline 7.2-rc6, stable 7.1.6, LTS 6.18/6.12/6.6/6.1/5.15/5.10 | **Ecosistema**: soporta más hardware en más arquitecturas que nada. Casi siempre es la respuesta |
| **seL4** (microkernel) | Kernel bajo **GPL-2.0-only**, código de usuario mayoritariamente **BSD-2-Clause** (`LICENSE.md`, SPDX por fichero); con **nota de syscall** análoga a la de Linux: usar servicios del kernel por llamada normal **no** convierte tu código en obra derivada | **Verificación formal** del kernel. Elegible cuando la garantía matemática es un requisito (defensa, aviónica, aislamiento crítico) — y solo entonces, porque el ecosistema es mínimo |
| **QNX** (microkernel, comercial) | Propietario, con soporte y certificaciones de seguridad funcional | **Automoción y sistemas críticos con certificación y soporte comercial**. Se paga por el papel, y a veces el papel es el requisito |
| **Fuchsia / Zircon** (microkernel) | Vivo: release **F30 (2026-04-07)**; su despliegue comercial sigue siendo esencialmente pantallas inteligentes de Google | Interés técnico y de investigación. **No es una plataforma sobre la que construir producto de terceros hoy** |
| **Redox** (microkernel, Rust) | **MIT** (`LICENSE` en `gitlab.redox-os.org`) | Proyecto de investigación e ingeniería de referencia. No es plataforma de producción |

Regla: **elegir microkernel es elegir un ecosistema pequeño a cambio de una propiedad concreta**
(verificación formal, aislamiento de drivers, certificación). Si no se puede nombrar esa propiedad
y quién la exige por escrito, la respuesta es Linux.

## 3. Modelo mental e invariantes

Los seis invariantes que esta skill exige asumir en cualquier diseño:

1. **Una llamada al sistema no es una llamada a función.** Cuesta el cambio de modo, más el coste de
   las mitigaciones de ejecución especulativa activas en ese sistema, más el efecto sobre cachés y
   TLB. Por eso existen el **vDSO** (`clock_gettime`, `getpid` y compañía resueltos sin entrar al
   kernel), la E/S por lotes y `epoll` frente a un `poll` por descriptor. El coste **no es una
   constante universal**: depende del hardware y de qué mitigaciones estén activas — **se mide en el
   sistema objetivo**.
2. **Un cambio de contexto cuesta más que su tiempo de CPU**: se paga sobre todo en cachés y TLB
   fríos. De ahí que "más hilos" deje de ayudar mucho antes de lo que la intuición dice, y que la
   afinidad de CPU importe.
3. **`write()` no significa "en disco"; significa "en la caché de páginas"** (§6.4).
4. **La memoria virtual no es memoria.** Reservar no es tocar; `Committed_AS` no es RSS; una página
   solo existe cuando se falla sobre ella. Medir "memoria usada" por el tamaño virtual es medir
   nada.
5. **El contenedor comparte kernel.** Todo lo que aísla son namespaces, cgroups, capabilities y
   filtrado de llamadas: mecanismos del mismo kernel que se comparte (§5.2).
6. **Bajo un hipervisor, el reloj y la CPU mienten.** *Steal time* significa que tu vCPU estaba
   lista y no corría; una latencia inexplicable en una VM se busca **primero** ahí, y una medida de
   tiempo tomada dentro de un invitado tiene ruido que no existe en bare metal.

## 4. Cómo se verifica una afirmación sobre el sistema (calidad)

Esta skill no tiene *linter*; tiene una disciplina, y es un gate: **una afirmación sobre el
comportamiento del SO no entra en un diseño, un informe ni un postmortem sin una de estas tres
pruebas**:

1. **Cita de la documentación del kernel de la versión concreta** (`docs.kernel.org` o el fichero en
   crudo de `git.kernel.org`; `man 2`/`man 7` para la interfaz de usuario). No de un blog, no de
   memoria — la mitad de las guías de tuning que circulan describen kernels de hace diez años (§2.1
   es el ejemplo canónico).
2. **Lectura del estado real del sistema**: `/proc/pressure/*`, `/sys/fs/cgroup/.../memory.*`,
   `/proc/meminfo`, `/proc/interrupts`, `numastat`, `/sys/kernel/mm/transparent_hugepage/enabled`,
   `chrt -p`, `taskset -pc`, `uname -r`. **El sistema sabe cómo está configurado; nadie más.**
3. **Medida antes/después con la carga real**, con la metodología de
   `performance-engineering-standards` y variando **un** parámetro. Un ajuste de `sysctl` sin
   medición previa y posterior es folclore, y se revierte.

Reglas adicionales: **el experimento se hace en un sistema idéntico al de producción** (misma
versión de kernel, mismo hipervisor, mismo sistema de ficheros) — un resultado obtenido en el portátil
no dice nada del servidor. Y **todo cambio de `sysctl`, parámetro de arranque o política de
planificación se versiona como código** con el motivo escrito; un `sysctl` puesto a mano en
producción desaparece en el siguiente reinicio, y su ausencia se diagnostica como "regresión
misteriosa".

## 5. Seguridad del stack

### 5.1 La frontera que importa es el cambio de privilegio
La superficie de ataque del sistema es **el conjunto de llamadas al sistema y de interfaces del
kernel que un proceso puede alcanzar**. Reducirla es más eficaz que endurecer al proceso: menos
llamadas alcanzables, menos código del kernel expuesto a entrada hostil. Los mecanismos concretos
—perfiles seccomp, MAC, capabilities del Pod— son de las skills hermanas; **lo que esta skill fija
es el criterio**: todo servicio expuesto corre con el conjunto mínimo de capacidades y de llamadas
que necesita, y ese conjunto se determina observando, no adivinando.

### 5.2 Namespaces y capabilities: la sustancia real del contenedor
- Un contenedor **es** un proceso con namespaces (pid, mount, net, uts, ipc, user, cgroup, time),
  un cgroup con límites, un conjunto de capabilities y un filtro de llamadas. **No hay nada más.**
  No hay hipervisor, no hay frontera de hardware: **el kernel es uno y es el mismo**.
- **`CAP_SYS_ADMIN` es equivalente a root** a efectos prácticos: agrupa tantas operaciones distintas
  que concederla anula el resto del ejercicio de mínimo privilegio.
- **El *user namespace* es el que cambia el modelo**, porque permite que el root del contenedor no
  sea el root del host. También ha sido, históricamente, fuente de vulnerabilidades por sí mismo:
  es un intercambio consciente, no una mejora gratuita.
- **Regla dura de diseño**: si el modelo de amenaza incluye *"el atacante controla el proceso y hay
  un fallo del kernel"*, **el contenedor no es la frontera de seguridad**. Ahí van máquina virtual o
  runtime con kernel propio. Decidir eso es una decisión de arquitectura, y se documenta.
- **Lo que un namespace no aísla también es diseño**: el reloj (salvo *time namespace*), el
  planificador, el estado del kernel, muchos ficheros de `/proc` y `/sys`, y —crucialmente para el
  rendimiento— **la información que ven las bibliotecas de tiempo de ejecución**: un runtime que lee
  el número de CPU del host dentro de un contenedor limitado a media CPU dimensionará mal su pool de
  hilos y se auto-estrangulará (§6.3).

### 5.3 `io_uring`: rendimiento con un historial que hay que conocer
`io_uring` es la interfaz de E/S asíncrona moderna de Linux y es genuinamente rápida. **También ha
sido, con diferencia, la fuente más productiva de escaladas de privilegio del kernel de los últimos
años**: Google reportó en 2023 que el **60% de los exploits** enviados a su programa de recompensas
en 2022 explotaban `io_uring`, y que estuvo presente en **todas** las entregas que sortearon sus
mitigaciones. Las consecuencias siguen vigentes y son operativas: **Google lo deshabilitó en
ChromeOS** (a nivel de compilación) y lo restringió en Android y en sus servidores, y **Docker y
containerd lo retiraron de su perfil seccomp por defecto** — de modo que **en un contenedor con el
perfil estándar, `io_uring` simplemente no funciona**, y ese es un descubrimiento caro si se hace en
producción. El subsistema ha madurado mucho desde entonces y sigue recibiendo CVE por su superficie
creciente.

**Criterio**: `io_uring` se habilita **deliberadamente, para la carga que lo justifique con una
medida**, con la decisión de riesgo escrita — no por defecto en todas partes. Si la ganancia sobre
`epoll` no se ha medido, no hay caso.

### 5.4 Los mecanismos del SO como control, no como accidente
Límites de recursos (`RLIMIT_*`, `cgroup v2`), `oom_score_adj`, `sysctl` de comportamiento y
namespaces **son controles de disponibilidad**: un proceso sin límite de memoria en un host
compartido es una denegación de servicio esperando a ocurrir, y la víctima que elija el OOM killer
probablemente no será el culpable (§6.2). Se configuran a propósito y se documentan.

## 6. Rendimiento y operabilidad

### 6.1 Memoria virtual, TLB y huge pages
Cada acceso a memoria pasa por la traducción de dirección; el **TLB** la acelera y es pequeño. Una
carga con conjunto de trabajo grande y acceso disperso puede pasar una fracción significativa de su
tiempo en fallos de TLB **sin que aparezca en ningún perfil de CPU como algo reconocible**. Las
*huge pages* atacan exactamente eso: menos entradas para cubrir la misma memoria.

**Pero THP no es gratis** y la propia documentación del kernel lo dice. Verbatim de
`Documentation/admin-guide/mm/transhuge.rst`: *"In certain cases when hugepages are enabled system
wide, application may end up allocating more memory resources"*, y la recomendación explícita:
*"Applications that gets a lot of benefit from hugepages and that don't risk to lose memory by using
hugepages, should use madvise(MADV_HUGEPAGE) on their critical mmapped regions"*, con la regla dura
para el otro extremo del espectro: *"Embedded systems should enable hugepages only inside madvise
regions to eliminate any risk of wasting any precious byte of memory"*. De ahí el default de §2:
**`madvise`, no `always`** — `always` tiene historial de latencias erráticas por compactación y de
memoria desperdiciada, y varias bases de datos recomiendan desactivarlo. **Se decide midiendo, y la
decisión se documenta.**

### 6.2 Overcommit, OOM killer y límites — decisiones de diseño, no accidentes
Linux **sobrecompromete memoria por defecto**, y eso es una elección deliberada. Verbatim de
`Documentation/mm/overcommit-accounting.rst`, modo 0: *"Heuristic overcommit handling. Obvious
overcommits of address space are refused. Used for a typical system. It ensures a seriously wild
allocation fails while allowing overcommit to reduce swap usage. This is the default."* Y modo 2:
*"Don't overcommit … in most situations this means a process will not be killed while accessing
pages but will receive errors on memory allocation as appropriate."*

**Ahí está el intercambio completo, y es una decisión de arquitectura**: o el sistema promete lo que
no tiene y algún día mata a alguien (modo 0/1), o rechaza asignaciones antes y el fallo aparece como
error manejable en el punto de asignación (modo 2). Elegir modo 2 exige que las aplicaciones
**manejen el fallo de asignación**, lo que muchas no hacen. Elegir el default significa aceptar que
**el OOM killer es parte del diseño del sistema** y que hay que decirle a quién preferir: eso es
`oom_score_adj` y la asignación de límites por servicio, no una plegaria.

En `cgroup v2` hay **dos mecanismos distintos**, y confundirlos es el error habitual. Verbatim de
`Documentation/admin-guide/cgroup-v2.rst`:
- `memory.high`: *"Memory usage throttle limit. If a cgroup's usage goes over the high boundary, the
  processes of the cgroup are throttled and put under heavy reclaim pressure. **Going over the high
  limit never invokes the OOM killer** and under extreme conditions the limit may be breached."*
- `memory.max`: *"Memory usage hard limit. This is the main mechanism to limit memory usage of a
  cgroup. If a cgroup's memory usage reaches this limit and can't be reduced, **the OOM killer is
  invoked in the cgroup**."*

Traducción a criterio: **`memory.high` es la señal y el freno; `memory.max` es el disparo.** El
diseño correcto pone `high` por debajo de `max` para que el sistema estrangule y avise antes de
matar, y **vigila la presión (PSI, `/proc/pressure/memory` y `memory.pressure`)**: la presión sube
mucho antes de que llegue la muerte, y es la única señal que permite reaccionar a tiempo. Un
servicio con solo `max` no tiene aviso previo, tiene autopsia. Lo mismo con CPU: `cpu.max` produce
*throttling* que se ve como latencia de cola inexplicable — **la métrica de estrangulamiento del
cgroup es de recogida obligatoria** en cualquier despliegue con límites.

### 6.3 NUMA, virtualización y lo que el proceso cree saber de la máquina
- **NUMA**: en un servidor de varios sockets, la memoria remota es más lenta y su ancho de banda es
  compartido. Un proceso cuyos hilos migran entre nodos y cuya memoria está en el nodo equivocado
  paga sin que nada lo indique. Se mira `numastat` antes de teorizar; se ancla (`numactl`) solo con
  medida, porque anclar mal es peor que no anclar.
- **Virtualización**: *steal time* (la vCPU lista que no corría) es lo primero que se mira ante
  latencia inexplicable dentro de una VM; el *ballooning* puede retirar memoria bajo los pies del
  invitado; y la paravirtualización (virtio) frente a la emulación completa cambia el rendimiento de
  E/S en órdenes de magnitud — **saber cuál está en uso es un dato, no una curiosidad**.
- **Lo que el proceso cree saber**: número de CPU, memoria total y topología leídos del host dentro
  de un contenedor limitado producen pools de hilos y heaps mal dimensionados, y el resultado es
  auto-estrangulamiento. **Todo runtime que dimensione recursos automáticamente se configura
  explícitamente en entornos con límites.** Es una de las causas más comunes y más silenciosas de
  latencia en Kubernetes.

### 6.4 Durabilidad: "lo escribí" no significa "está en disco"
Un `write()` con éxito deja el dato en la **caché de páginas**; el kernel lo escribirá cuando le
convenga. Solo `fsync`/`fdatasync` (o `O_DIRECT` con las condiciones adecuadas, o `O_SYNC`) piden la
persistencia — y aun así, **si el disco tiene caché volátil y las barreras de escritura están
desactivadas, el dato puede seguir sin estar en medio estable**. Toda promesa de durabilidad
depende de la cadena completa: aplicación → sistema de ficheros → capa de bloques → controlador →
disco. **Un eslabón mentiroso invalida la cadena entera.**

**Y `fsync` puede mentir de una manera concreta y bien documentada.** El episodio conocido como
*fsyncgate* (PostgreSQL, 2018) estableció el modelo mental correcto: cuando la escritura diferida
falla, el kernel marca el error y lo **entrega una sola vez**; un segundo `fsync` sobre el mismo
descriptor **puede devolver éxito aunque el dato nunca llegara a disco**, porque el error ya se
consumió y las páginas se marcaron limpias. El propio Linux mejoró el reporte de errores de
*writeback* (infraestructura `errseq_t` a partir de 4.13 y refinamientos posteriores), pero **la
regla de diseño que salió de ahí sigue siendo la correcta y es la de esta skill**:

> **Un `fsync` fallido es un fallo fatal, no un reintento.** No se puede reescribir el buffer
> —tanto el de la aplicación como el del kernel pueden estar ya reutilizados—; la única recuperación
> válida es abortar y reconstruir desde el registro (WAL) o desde la copia.

Es exactamente lo que hizo PostgreSQL: entrar en pánico ante `fsync` fallido, cambio retroportado a
todas las ramas soportadas. **Cualquier código propio que persista datos y trate `fsync` como
reintentable tiene el mismo fallo latente.** Corolario para el diseño de sistemas: **si el dato
importa, la durabilidad se prueba arrancando la máquina de un tirón** (corte de alimentación real o
simulado a nivel de dispositivo) y comprobando que el último commit reconocido sobrevive. Una
promesa de durabilidad sin esa prueba es una suposición.

### 6.5 Modelo de E/S
- **Bloqueante con un hilo por conexión** escala hasta donde escale el número de hilos; es simple y
  correcto, y sigue siendo la respuesta correcta para concurrencias moderadas. No se descarta por
  moda.
- **`epoll` en modo *level-triggered*** es el default para alta concurrencia: el *edge-triggered* es
  más rápido en el papel y **es una fuente clásica de fallos por eventos perdidos** si no se drena
  el descriptor por completo. Se elige `epoll` casi siempre a través del runtime del lenguaje, no a
  mano.
- **`O_DIRECT` esquiva la caché de páginas**: útil cuando la aplicación gestiona su propia caché
  (bases de datos), **contraproducente en casi todo lo demás**, y con requisitos estrictos de
  alineamiento que se incumplen fácil.
- **La escritura diferida (*dirty writeback*) es un pico de latencia esperándote**: acumular
  gigabytes de páginas sucias y vaciarlas de golpe produce paradas visibles. Si el perfil de
  escritura es grande y a ráfagas, los umbrales de páginas sucias **son un parámetro de diseño**, no
  un ajuste esotérico.

## 7. Sostenibilidad a largo plazo y prohibiciones

- **La versión de kernel es una decisión de arquitectura con fecha.** Se elige una rama **LTS**
  soportada, se conoce su EOL y se planifica el salto **antes** de que llegue. Un ajuste validado en
  una versión **se revalida** al saltar: EEVDF (§2.1) es la demostración de que un cambio de
  planificador puede mover el perfil de latencia de un servicio sin que nadie tocara el código.
- **Todo `sysctl`, parámetro de arranque, política de planificación y límite de cgroup vive como
  código versionado**, con el motivo y la medida que lo justificó. Sin eso, dentro de un año nadie
  sabrá si se puede quitar — y no se quitará nunca.

Prohibiciones explícitas:
- ❌ **Tocar el planificador, `sysctl` de memoria o parámetros de E/S sin medida antes y después**, y
  sin variar un solo parámetro por experimento. PROHIBIDO el "tuning" copiado de un blog.
- ❌ **Citar `sched_latency_ns`, `sched_min_granularity_ns` o "CFS" como si describieran el
  planificador vigente.** Es EEVDF desde 6.6 (§2.1).
- ❌ **Dar prioridad de tiempo real (`SCHED_FIFO`/`SCHED_RR`) a un proceso que puede consumir CPU sin
  ceder.** Cuelga el núcleo. Si se hace, con presupuesto de CPU acotado y prueba de que no lo agota.
- ❌ **Reintentar un `fsync` fallido** o suponer que un `write()` con éxito es durable (§6.4).
  PROHIBIDO, sin matices.
- ❌ **Desactivar el swap "para que no haya OOM"**: adelanta el OOM en vez de evitarlo.
- ❌ **Desactivar el OOM killer globalmente** o poner `oom_score_adj` al mínimo en servicios grandes
  sin haber pensado a quién quieres que mate el sistema en su lugar.
- ❌ **Poner `memory.max` sin `memory.high` ni vigilancia de PSI**: es elegir la autopsia sobre el
  aviso (§6.2).
- ❌ **Desplegar con límites de CPU y no recoger la métrica de estrangulamiento del cgroup.** Es
  latencia de cola invisible por construcción.
- ❌ **Dejar que un runtime dimensione hilos o heap leyendo la topología del host dentro de un
  contenedor limitado.**
- ❌ **Tratar el contenedor como frontera de seguridad frente a un atacante con ejecución de código**
  cuando el modelo de amenaza incluye fallos del kernel (§5.2).
- ❌ **Conceder `CAP_SYS_ADMIN`** y llamar a eso mínimo privilegio.
- ❌ **Habilitar `io_uring` por defecto** sin decisión de riesgo escrita y sin ganancia medida (§5.3).
- ❌ **`transparent_hugepage=always` sin medir**, especialmente bajo bases de datos.
- ❌ **Activar `PREEMPT_RT` "por si acaso"**: se paga en rendimiento agregado y no arregla una
  aplicación que reserva memoria o toca disco en el camino crítico (§2.2).
- ❌ **Elegir microkernel sin poder nombrar la propiedad concreta que se necesita y quién la exige**
  (§2.3).
- ❌ **Medir "memoria usada" por el tamaño virtual del proceso.**
- ❌ **Extrapolar una medida tomada en el portátil, en otra versión de kernel o en otro hipervisor.**

## 8. Verificación web obligatoria

Fuentes autoritativas: `kernel.org` y `docs.kernel.org`, el fichero en crudo del árbol
(`git.kernel.org/.../plain/...`, que evita cualquier resumidor de por medio), `man7.org` para las
interfaces de usuario, y `lwn.net` para el contexto y la historia de un subsistema. Comprobar antes
de fijar nada:

1. **Versión de kernel del sistema objetivo** y **qué ramas LTS siguen soportadas y hasta cuándo**
   (`kernel.org/releases.json`). Todo lo demás depende de este dato.
2. **Planificador vigente y sus parámetros** en `Documentation/scheduler/` de esa versión, y estado
   de `sched_ext`. Verificado a ago-2026: **EEVDF** desde 6.6, `sched_ext` en mainline desde 6.12.
3. **`PREEMPT_RT`**: soporte de tu arquitectura (`ARCH_SUPPORTS_RT`) y estado de las opciones en
   `kernel/Kconfig.preempt` de esa versión.
4. **Semántica exacta de los ficheros de `cgroup v2`** que vayas a usar en
   `Documentation/admin-guide/cgroup-v2.rst` **de tu kernel**: los ficheros y su comportamiento se
   añaden y se matizan entre versiones.
5. **Modos de overcommit y comportamiento del OOM** en `Documentation/mm/` de tu versión.
6. **Estado de seguridad de `io_uring`**: CVE recientes, si tu distribución lo trae habilitado, y si
   el perfil seccomp por defecto de tu runtime de contenedores lo bloquea (a ago-2026, Docker y
   containerd lo bloquean en `RuntimeDefault`).
7. **Semántica de durabilidad de tu sistema de ficheros concreto** (ext4, XFS, Btrfs, ZFS, NFS) y de
   la pila de bloques: modo de *journal*, barreras de escritura, y si la caché del dispositivo es
   volátil. **NFS y los sistemas de ficheros en red tienen semántica propia** y no se asume la de
   local.
8. **Estado de los proyectos citados en §2.3** si van a decidir algo: última release y despliegue
   real de Fuchsia, licencias de seL4 y Redox leídas **del fichero en crudo del repositorio**
   (seL4 vive en GitHub, **Redox en `gitlab.redox-os.org`**), y las condiciones comerciales de QNX.

**Huecos declarados**: (a) **no se dan aquí cifras de coste de llamada al sistema, de cambio de
contexto ni de sobrecoste de las mitigaciones especulativas**, porque dependen del microarquitectura,
de qué mitigaciones estén activas y del kernel: **se miden en el sistema objetivo**, y cualquier
número absoluto citado de memoria estaría mal. (b) El estado exacto de `io_uring` en ChromeOS y en la
política SELinux de Android a día de hoy **no se ha podido confirmar con fuente primaria fechada**;
lo verificado es la restricción original y su efecto sobre los perfiles seccomp de los runtimes de
contenedores. (c) La documentación de QNX y sus certificaciones está tras registro comercial y **no
se ha verificado verbatim**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
