---
name: kernel-drivers-standards
description: Writing, reviewing and shipping code that runs inside an OS kernel, and deciding whether it should live there at all. Use when working on a Linux kernel module or driver (module_init/module_exit, MODULE_LICENSE, EXPORT_SYMBOL_GPL, struct file_operations, platform_driver, of_match_table and devicetree bindings, probe/remove, devm_* managed resources, misc/char/block/net/input subsystems, dma_alloc_coherent and DMA-API-HOWTO, request_irq and threaded IRQ handlers, spinlock_t vs mutex, might_sleep, in_atomic, RCU with rcu_read_lock and synchronize_rcu, copy_from_user/copy_to_user, an out-of-tree kmod or DKMS package), submitting patches upstream (scripts/checkpatch.pl, scripts/get_maintainer.pl, MAINTAINERS, git send-email, b4, Signed-off-by and the Developer Certificate of Origin, a linux-*@vger.kernel.org list, staging), kernel debugging and hardening (dmesg oops and taint flags, ftrace and trace_printk, kgdb/kdb, KASAN, UBSAN, KCSAN, KFENCE, lockdep, sparse, smatch, Coccinelle, KUnit, syzkaller), Rust in the kernel (rust/kernel crate, rustavailable, CONFIG_RUST, Rust MSRV), module signing under Secure Boot and kernel lockdown, or choosing a userspace alternative instead (FUSE, uio, vfio-pci, iommufd, spidev, i2c-dev, libusb, SPDK/DPDK) — and Windows KMDF/WDM/UMDF drivers with Partner Center attestation or WHQL signing, or macOS kexts versus DriverKit and System Extensions.
---

# Estándares de desarrollo dentro del kernel

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **escribir código que se ejecuta en modo supervisor**: drivers y módulos del kernel Linux,
su relación con el desarrollo upstream, el modelo de concurrencia y memoria del kernel, su
depuración y su firma; y, en menor extensión pero con criterio propio, drivers de Windows y de
macOS. Aplica **antes** de escribir la primera línea: la decisión más valiosa de esta skill es
**decidir que no hace falta un driver de kernel**.

Triggers: `module_init`/`module_exit`, `MODULE_LICENSE`, `EXPORT_SYMBOL`/`EXPORT_SYMBOL_GPL`,
`struct file_operations`, `platform_driver`, `probe`/`remove`, `of_match_table`, *bindings* de
devicetree en `Documentation/devicetree/bindings/`, `devm_kzalloc` y familia `devm_*`, `misc_register`,
`cdev_add`, `alloc_netdev`, `blk_mq`, `input_register_device`, `dma_alloc_coherent`, `dma_map_single`,
`request_irq`/`request_threaded_irq`, `spinlock_t`, `mutex_lock`, `might_sleep`, `in_atomic`,
`rcu_read_lock`, `synchronize_rcu`, `copy_from_user`/`copy_to_user`, `container_of`, `ERR_PTR`,
`printk`/`pr_err`/`dev_err`, `Kbuild`/`Makefile` con `obj-m`, DKMS, `insmod`/`modprobe`/`modinfo`,
`scripts/checkpatch.pl`, `scripts/get_maintainer.pl`, `MAINTAINERS`, `git send-email`, `b4`,
`Signed-off-by`, `vger.kernel.org`, `drivers/staging/`, `dmesg`, "Oops", "kernel panic",
"tainted kernel", `ftrace`, `kgdb`, `KASAN`, `UBSAN`, `KCSAN`, `KFENCE`, `lockdep`, `sparse`,
`smatch`, `coccinelle`, `KUnit`, `syzkaller`, `CONFIG_RUST`, `make rustavailable`, `rust/kernel`,
`CONFIG_MODULE_SIG_FORCE`, `sign-file`, *lockdown*, MOK/`mokutil`, KMDF/WDM/UMDF, `.inf`, WDK,
Partner Center, WHQL, `kext`, DriverKit, System Extensions.

**Principio rector**: **dentro del kernel no hay red de seguridad.** No hay proceso que matar, no hay
`SIGSEGV` que contener, no hay reinicio del servicio: un puntero mal desreferenciado es el sistema
entero, y un fallo desplegado a escala es un incidente global (§2.4). De ahí las dos reglas de la
casa: **(1) el código que puede vivir en espacio de usuario, vive en espacio de usuario**; **(2) el
código que sí debe estar en el kernel, va upstream** — todo lo demás es deuda que se paga cada
versión, para siempre.

**Postura estrictamente defensiva.** Esta skill trata la firma de módulos, el *lockdown*, los
drivers vulnerables y los mecanismos de persistencia en kernel **como riesgos a mitigar**. No
contiene ni contendrá recetario de BYOVD, de rootkits ni de evasión (§7).

**No aplica**: ver `operating-systems-standards` (**hermana directa, frontera declarada**: los
**conceptos** de sistema operativo y sus consecuencias de ingeniería —planificación y latencia, coste
de la llamada al sistema, paginación y TLB, OOM killer, `cgroup v2`, semántica de `fsync`, `epoll`
frente a `io_uring`, namespaces, NUMA, microkernel frente a monolítico, tiempo real duro frente a
blando— son **suyos**; **aquí el código que se escribe dentro del kernel y su proceso**. Regla de
arbitraje: *"¿por qué el sistema se comporta así?" es suyo; "¿cómo escribo, depuro y subo este
driver?" es de aquí*), `linux-administration-standards` (operar el host: unidades systemd,
`journalctl`, diagnóstico de un servidor — **cargar un módulo para operar** es suyo; **escribirlo** es
de aquí), `linux-hardening-standards` (baseline del sistema, Secure Boot como control del baseline,
`sysctl`, auditd — **aquí la firma del módulo desde el lado del que lo produce**),
`selinux-standards` (MAC y su política), `container-runtime-security-standards` (**el eBPF de
seguridad y el agente de runtime son suyos**: Falco, Tetragon, Tracee, privilegios del agente eBPF —
aquí solo por qué eBPF es la alternativa correcta a un módulo para observar el sistema),
`c-standards` (**el C es suyo**: `-std=`, UB, MISRA/CERT, sanitizers de espacio de usuario,
hardening del binario — **matiz obligatorio**: el kernel **no** se compila contra la libc, no usa
`malloc`, tiene su propio estilo y sus propios sanitizers; **cuando una regla de `c-standards`
choque con el kernel, manda el kernel**), `rust-standards` (**el Rust y su toolchain son suyos**;
aquí solo el estado y las restricciones del Rust *dentro* del kernel), `assembly-standards` (el
ensamblador y su justificación), `embedded-iot-standards` (**hermana**: el dispositivo físico,
el arranque, el device tree como descripción del hardware del producto y la actualización en campo —
**aquí el código del driver que ese device tree enlaza**), `gpu-computing-standards` (CUDA/HIP y el
toolchain de GPU; el driver del kernel de la GPU es de aquí), `performance-engineering-standards`
(metodología de perfilado y medición; **el `perf` y el `ftrace` como herramienta de diagnóstico de
un driver son de aquí**), `appsec-standards` y `vulnerability-management-standards` (modelado de
amenazas de aplicación, triaje CVSS/EPSS/KEV), `incident-response-forensics-standards` (análisis
forense de un sistema con módulo hostil), `offensive-security-standards` (explotación, con alcance y
autorización — **no está aquí**), `windows-server-ad-standards` y `macos-fleet-standards`
(administración de esas plataformas; aquí solo el desarrollo del driver),
`opensource-licensing-standards` (el análisis de licencia como programa; aquí `MODULE_LICENSE` y el
símbolo GPL-only como hecho técnico), `git-workflow-standards` (**no aplica al kernel**: el kernel
usa correo, `Signed-off-by`/DCO y `b4`, no *pull requests*).

## 2. Decisiones por defecto

> Verificar versiones, estado y fechas por web antes de fijar nada (§8). Estado **verificado** a
> agosto de 2026 contra `kernel.org` y el árbol de Torvalds — **el kernel Linux no vive en GitHub**.

### 2.1 Lo primero: ¿de verdad hace falta un driver de kernel?

**La respuesta por defecto es "no".** Antes de escribir un módulo se agota esta lista, en orden:

| Alternativa en espacio de usuario | Para qué | Coste real |
|---|---|---|
| **`spidev` / `i2c-dev`** (`/dev/spidev*`, ioctl `I2C_SLAVE`) | Cualquier periférico SPI o I²C de baja velocidad | Ninguno: bus expuesto como *char device*, se pilota desde C o desde un script |
| **`libusb`** | Dispositivo USB propietario, actualizadores de firmware, instrumentación | Latencia y throughput algo peores; a cambio, cero código en kernel |
| **`uio`** | Registros memory-mapped e interrupción simple, típico en FPGA | **Sin IOMMU**: el dispositivo puede escribir en cualquier sitio por DMA. Aceptable solo sin DMA o con confianza total en el hardware |
| **`vfio-pci` / `iommufd`** | Driver de usuario con DMA **y protección de IOMMU**, base de DPDK/SPDK y del passthrough a VM | Más complejo (ioctls, binding), pero es **la única forma segura** de hacer DMA desde usuario |
| **FUSE** | Sistema de ficheros | Coste por cambio de contexto; irrelevante en la mayoría de casos y decisivo en pocos |
| **eBPF** | Observar, filtrar o extender comportamiento del kernel sin código propio en él | Verificador, límites del programa, y una API que sí es estable |
| **`gpiod`, `iio`, `hidraw`, `sg`/`bsg`, `serial`** | Ya existe subsistema que expone el dato | Cero: **primero se comprueba si el subsistema ya lo hace** |

**Cuándo sí hay que estar en el kernel**: latencia de interrupción de microsegundos; DMA que exige
configurar hardware y gestionar buffers del kernel; participación en un subsistema (una tarjeta de
red **es** un `net_device`, un disco **es** un `blk_mq`); necesidad de primitivas que no existen
fuera (spinlocks, RCU, contextos atómicos); o que el proceso de usuario pueda ser matado o
suspendido y eso sea inaceptable. Un proceso de usuario **se puede matar; un módulo del kernel, no** —
esa asimetría es el argumento válido, y también la razón de que un fallo cueste tanto.

### 2.2 Upstream o fuera del árbol — no es una preferencia, es aritmética

**La API interna del kernel no es estable, y no lo es por diseño.** No es un descuido ni una
promesa incumplida: es política explícita, documentada en
`Documentation/process/stable-api-nonsense.rst`. Verbatim:

> *"This is being written to try to explain why Linux **does not have a binary kernel interface, nor
> does it have a stable kernel interface**."*

Y su distinción crítica, que se confunde constantemente:

> *"Please realize that this article describes the **in kernel** interfaces, not the kernel to
> userspace interfaces. The kernel to userspace interface is the one that application programs use,
> the syscall interface. That interface is **very** stable over time, and will not break."*

Es decir: **la ABI hacia espacio de usuario es sagrada** (romperla es un `git revert`), y la API
*interna* cambia cuando conviene. De ahí la conclusión del propio documento sobre qué hacer con un
driver fuera del árbol:

> *"Simple, get your kernel driver into the main kernel tree … If your driver is in the tree, and a
> kernel interface changes, it will be fixed up by the person who did the kernel change in the first
> place."*

**Qué cuesta subirlo** (y hay que decirlo entero, porque el coste es real): escribir al estilo del
kernel, pasar `checkpatch.pl`, documentar los *bindings* de devicetree en su esquema YAML, encontrar
al *maintainer* con `get_maintainer.pl`, enviar por correo en texto plano, y **aguantar varias
rondas de revisión pública que serán directas**. Semanas o meses. **Qué cuesta no subirlo**: portar
el driver a cada versión del kernel, para siempre, para cada distribución y cada rama de fabricante;
empaquetarlo por DKMS y que se rompa en cada actualización de kernel del cliente; quedarse fuera de
cualquier refactor que se lleve por delante la API que usas; y no poder usar símbolos `EXPORT_SYMBOL_GPL`
si el módulo no es GPL (§5.3). **Es deuda permanente con interés compuesto.**

`drivers/staging/` existe como camino intermedio para código que aún no cumple el listón, con reglas
propias y con la expectativa explícita de que sale de ahí o se borra. **No es un aparcamiento
indefinido**, y un driver en staging no está mantenido por nadie más que su autor.

### 2.3 Versiones y toolchain — verificado en `kernel.org`

| Dato | Valor verificado (2026-08-05, `kernel.org/releases.json`) |
|---|---|
| mainline | **7.2-rc6** |
| stable | **7.1.6** |
| longterm | **6.18.42**, **6.12.101**, **6.6.148**, **6.1.180**, **5.15.213**, **5.10.262** |
| GCC mínimo | **8.1** (`Documentation/process/changes.rst`) |
| Clang/LLVM mínimo (opcional) | **17.0.1** |
| binutils mínimo | **2.30** |
| Rust mínimo (opcional) | **1.85.0** |
| bindgen mínimo (opcional) | **0.71.1** |

**Contra qué se desarrolla**: el trabajo nuevo se hace contra **mainline o `linux-next`**, no contra
el kernel de la distribución. Un parche que solo aplica sobre el árbol de un fabricante no es
enviable y no será revisado.

### 2.4 Rust en el kernel — estado real, no folclore

Es el tema del catálogo con más desinformación en ambas direcciones ("ya está todo en Rust" / "es un
experimento que no compila"). Estado **verificado** a agosto de 2026:

- **Es soporte de primera clase pero opcional**: `Documentation/process/changes.rst` lista Rust como
  *"(optional)"* con mínimo **1.85.0**, y `bindgen` como *"(optional)"* con mínimo 0.71.1. Sin
  `CONFIG_RUST`, el kernel se compila exactamente como siempre. `make rustavailable` dice por qué no
  está disponible el toolchain.
- **Política de versión mínima**: desde principios de 2026 el proyecto **sigue la versión de Rust de
  Debian Stable** como mínimo soportado (Debian 13 *Trixie* → 1.85.0), en vigor desde Linux v7.1.
  Las ramas LTS mantienen su propio mínimo (6.18.y sigue con 1.78.0): **no se asume el mínimo de
  mainline al portar a una LTS**.
- **Arquitecturas soportadas**, verbatim de `Documentation/rust/arch-support.rst`, todas con nivel
  *Maintained*: `arm` (*"ARMv7 Little Endian only"*), `arm64` (*"Little Endian only"*), `loongarch`,
  `riscv` (*"riscv64 and LLVM/Clang only"*), `s390` (*"CONFIG_EXPOLINE must be disabled"*), `um`, y
  `x86` (*"x86_64 only"*). **No es universal**: si el objetivo no está en esa tabla, no hay debate.
- **Hay drivers reales**: Binder en Rust se fusionó en 6.18, junto con Tyr (GPU Mali CSF). Las
  *bindings* de USB están presentes pero **desactivadas en el build** hasta que llegue un driver real
  que las use.
- **Sigue apoyándose en features inestables** del lenguaje dentro del *crate* `kernel`; fuera de él
  (en drivers) solo se permite un conjunto mínimo. Ese es el trabajo abierto.

**Criterio de esta skill**: para un driver nuevo, en una arquitectura soportada, en un subsistema
donde ya existen abstracciones Rust, **Rust es una elección defendible y hay que justificar la
contraria**. Fuera de esas condiciones, **C sigue siendo el default del kernel** — y esa afirmación
tiene fecha de caducidad: se re-verifica (§8), no se hereda.

### 2.5 Windows y macOS

**Windows.** Marco por defecto: **KMDF** (Kernel-Mode Driver Framework) para lo que deba estar en
kernel, **UMDF** para lo que pueda estar en usuario — y esa es la primera decisión, igual que en
Linux. **WDM crudo solo cuando KMDF no cubre el caso**, y con justificación escrita. Firma:
**desde Windows 10 1607 un driver de kernel solo carga si lo ha firmado Microsoft**; el certificado
EV del fabricante firma el CAB que se sube a Partner Center, y Microsoft devuelve el binario
firmado (*attestation signing*, o **WHQL** con pruebas HLK si se quiere distribución por Windows
Update y cobertura de Windows Server). **El *cross-signing* está muerto**: retirado desde 2021, con
los certificados caducados, y la actualización de abril de 2026 eliminó la confianza por defecto en
drivers *cross-signed* en Windows 11 24H2/25H2/26H1 y Windows Server 2025 — **cualquier driver
antiguo que dependiera de ello hay que resubmitirlo**. Verificar el estado exacto antes de
planificar (§8).

**El precedente de CrowdStrike (julio de 2024) es el argumento de esta skill, no una anécdota.** Un
proveedor de seguridad con driver de kernel **firmado por WHQL** distribuyó un fichero de contenido
—no el driver— que el driver consumió mal, y el resultado fue un pantallazo azul en bucle en
millones de máquinas, con recuperación manual por equipo. Las tres lecciones son de diseño y aplican
a cualquier driver: **(1)** el radio de explosión de un fallo en kernel es la máquina entera y no hay
degradación posible; **(2)** los **datos** que consume el driver son superficie de fallo con el mismo
peso que el código, y hay que validarlos con la misma paranoia; **(3)** el despliegue de cualquier
cosa que llegue al kernel exige **canario y despliegue por fases**, sin excepción por urgencia. La
consecuencia estructural es que Microsoft está llevando la seguridad de endpoint **fuera del
kernel** (Windows Endpoint Security Platform, dentro de la Windows Resiliency Initiative) — el mismo
movimiento que en Linux ya ocurrió al pasar los agentes de módulo propio a **eBPF**.

**macOS.** Los **kexts están deprecados desde WWDC19**; desde Big Sur macOS no carga por defecto
kexts que usen KPIs deprecadas, y la alternativa es **DriverKit** (USB, serie, red, HID) y
**System Extensions** (Network Extension, Endpoint Security) — que **corren en espacio de usuario**.
Verificado a 2026: **Apple no ha anunciado fecha de retirada total** y los kexts siguen cargando en
las versiones actuales, con aprobación del usuario y seguridad reducida en Apple Silicon. Criterio:
**nada nuevo en kext**; DriverKit/System Extensions y solicitar el *entitlement* correspondiente a
Apple **antes** de comprometer el diseño, porque no es automático.

## 3. Estructura y convenciones (Linux)

- **Estilo**: `Documentation/process/coding-style.rst` es la norma y no se discute — tabulaciones de
  8, llaves del kernel, líneas según el límite vigente del árbol. `clang-format` con el `.clang-format`
  **del propio árbol**, nunca el del proyecto de fuera.
- **`scripts/checkpatch.pl` antes de enviar nada.** Su propia documentación fija cómo se lee, verbatim
  desde `Documentation/process/submitting-patches.rst`: *"the style checker should be viewed as a
  guide, not as a replacement for human judgment"*, con tres niveles —*"ERROR: things that are very
  likely to be wrong / WARNING: things requiring careful review / CHECK: things requiring thought"*— y
  la regla que importa: *"You should be able to justify all violations that remain in your patch."*
  Un `checkpatch` limpio no garantiza que el parche sea bueno; uno sucio garantiza que no será
  leído.
- **Destinatarios**: `scripts/get_maintainer.pl` sobre el propio parche. Verbatim del mismo
  documento: *"If you cannot find a maintainer for the subsystem you are working on, Andrew Morton
  (akpm@linux-foundation.org) serves as a maintainer of last resort"* y *"linux-kernel@vger.kernel.org
  should be used by default for all patches"* — con la advertencia explícita de **no** enviar a
  listas ni personas no relacionadas.
- **Envío por correo, en texto plano**, serie ordenada, un cambio lógico por parche, mensaje que
  explica **el porqué** (el qué ya está en el diff). `Signed-off-by:` es la **DCO**, no una
  formalidad: es una declaración legal sobre la procedencia del código. **`b4` es la herramienta
  recomendada** para gestionar series, dependencias y envío; el propio documento la cita como ayuda
  *"with things like tracking dependencies, running checkpatch and with formatting and sending
  mails"*.
- **Elegir bien la capa**: no se escribe un *char device* propio cuando existe subsistema. Un sensor
  es **IIO**; un botón, **input**; una tarjeta de red, **netdev**; un almacenamiento, **blk-mq**; un
  regulador, **regulator**. Un driver que inventa su propio `ioctl` para lo que un subsistema ya
  expone será rechazado upstream — y con razón: rompe todas las herramientas existentes.
- **`ioctl` como último recurso, y cuando lo sea, con contrato blindado**: estructuras de tamaño fijo
  y explícito, campos de padding a cero y verificados, sin punteros embebidos si se puede evitar,
  compatibilidad 32/64 bits pensada desde el primer día. **Es ABI hacia espacio de usuario: una vez
  publicado, no se cambia nunca.**
- **Devicetree**: los *bindings* se documentan en esquema YAML en
  `Documentation/devicetree/bindings/` y se validan con `make dt_binding_check`. El binding es
  **contrato con el firmware de miles de placas** y también es ABI: no se rompe.
- **Recursos gestionados** (`devm_kzalloc`, `devm_request_irq`, `devm_ioremap_resource`) por defecto:
  eliminan la clase entera de fugas en el camino de error de `probe()`. Cuando no se puedan usar,
  el camino de error se escribe con etiquetas en orden inverso a la adquisición, y se revisa entero.

## 4. Calidad y testing

En orden de coste creciente. Los cuatro primeros son **gates**: si no pasan, el parche no sale.

1. **`checkpatch.pl` limpio** (con las violaciones restantes justificadas) y compilación **sin
   warnings nuevos** con `make W=1`.
2. **`sparse`** (`make C=1`): comprueba las anotaciones de espacio de direcciones (`__user`,
   `__iomem`, `__rcu`) y el endianness. **Es la herramienta que atrapa el error más caro y más
   silencioso del kernel: desreferenciar un puntero de usuario directamente.**
3. **`smatch` y `coccinelle`** (`make coccicheck`): fugas en caminos de error, comprobaciones de
   nulo ausentes, patrones ya vetados en el árbol.
4. **Compilar el módulo contra varias versiones** si —contra el criterio de §2.2— vive fuera del
   árbol: mainline, `linux-next` y cada LTS soportada. Es el precio del que no sube.
5. **Sanitizers, en un kernel de desarrollo, ejecutando la carga real**: `KASAN` (use-after-free y
   desbordamientos; es **el** hallazgo típico de un driver), `UBSAN`, `KCSAN` (*data races*),
   `KFENCE` (bajo coste, apto incluso en producción de flota grande), y **`lockdep`
   (`CONFIG_PROVE_LOCKING`) siempre activado en desarrollo**: detecta el orden de bloqueo incorrecto
   *antes* de que produzca el interbloqueo, no después. `CONFIG_DEBUG_ATOMIC_SLEEP` para cazar los
   `might_sleep` en contexto atómico.
6. **KUnit** para la lógica pura que se pueda aislar (parseo, cálculo, máquinas de estado). No todo
   un driver es testeable así — pero la parte que decide **sí** lo es, y suele ser donde están los
   fallos.
7. **`syzkaller`** contra cualquier interfaz expuesta a espacio de usuario (`ioctl`, `read`/`write`,
   `netlink`, sysfs). Si el driver acepta entrada de usuario y nunca ha visto un *fuzzer*, no está
   probado: está sin estrenar.
8. **Prueba de camino de error real**: fallo de asignación, `probe` que falla a mitad, `remove` con
   el dispositivo en uso, desconexión en caliente durante una transferencia, `rmmod` con un fichero
   abierto. **Los caminos de error de un driver son donde vive la mayoría de sus bugs**, porque son
   los que nadie ejecuta.

**Depuración**: `dmesg` y las **banderas de taint** primero (dicen si hay módulo propietario, si el
kernel ya había fallado antes, si se forzó una carga); `ftrace`/`trace_printk` para el flujo y la
latencia sin parar el sistema; `dynamic_debug` (`pr_debug` activable en caliente) en vez de dejar
`printk` a pelo; `kgdb`/`kdb` para el caso que lo exija; `crash`/`kdump` sobre el volcado cuando el
fallo no se reproduce. **`printk` en camino caliente altera el propio problema** —serializa,
sincroniza y cambia el *timing*—: el mismo argumento que el `printf` por UART en firmware.

## 5. Seguridad del stack

### 5.1 La frontera con espacio de usuario es una frontera de confianza
- **Todo dato que cruza desde usuario es hostil.** `copy_from_user`/`copy_to_user` **siempre** con
  comprobación del retorno; nunca desreferenciar un puntero de usuario. Validar longitudes **antes**
  de usarlas, con aritmética que no desborde, y comprobar `TOCTOU`: un valor copiado dos veces puede
  haber cambiado entre ambas.
- **Nunca se filtra memoria del kernel hacia usuario**: estructuras a copiar inicializadas a cero
  completas (el *padding* también), sin punteros ni direcciones del kernel en salidas ni en logs
  (`%p` está ofuscado por defecto y esa ofuscación no se anula "para depurar" en producción).
- **Todo lo que se expone es ABI para siempre**: cada `ioctl`, cada fichero de sysfs y cada atributo
  de debugfs que se publique habrá que sostenerlo. Lo experimental va a `debugfs` y se dice que lo
  es; lo estable va donde corresponda y se documenta en `Documentation/ABI/`.

### 5.2 Firma de módulos, Secure Boot y *lockdown*
- El kernel firma módulos con certificados X.509 y verifica en la carga. Verbatim de
  `Documentation/admin-guide/module-signing.rst`: *"Module signing increases security by making it
  harder to load a malicious module into the kernel. The module signature checking is done by the
  kernel so that it is not necessary to have trusted userspace bits."* Algoritmos soportados por la
  facilidad integrada, verbatim: *"the built-in facility currently only supports the RSA, NIST P-384
  ECDSA and NIST FIPS-204 ML-DSA public key signing standards"* — **ya hay firma post-cuántica en el
  árbol; comprobar el soporte real de la rama que se usa**.
- **`CONFIG_MODULE_SIG_FORCE`** (o `module.sig_enforce=1`) es lo que convierte la firma en un
  control: sin él, un módulo sin firma se carga y solo *tainta* el kernel. Con Secure Boot activo,
  la distribución activa además el **lockdown**, que restringe las vías por las que espacio de
  usuario puede escribir en el kernel (`/dev/mem`, `kexec` no firmado, parámetros peligrosos).
- **La clave privada de firma no vive en el sistema que arranca.** Firma en HSM o servicio de firma;
  para desarrollo, MOK propia enrolada con `mokutil` **solo en máquinas de laboratorio** y nunca la
  misma clave que en producción.

### 5.3 Licencia: `MODULE_LICENSE` y el símbolo GPL-only
`MODULE_LICENSE` **no es metadato decorativo**: determina si el módulo puede enlazar con símbolos
exportados con `EXPORT_SYMBOL_GPL`. Verbatim de `include/linux/module.h`, sobre el propósito de la
cadena: *"The sole purpose is to make the 'Proprietary' flagging work and to refuse to bind symbols
which are exported with EXPORT_SYMBOL_GPL when a non free module is loaded."* Y el mismo comentario
aclara los límites de lo que la etiqueta significa: *"the 'only/or later' distinction is completely
irrelevant and does neither replace the proper license identifiers in the corresponding source file
nor amends them in any way"* — es decir, **la licencia real está en el fichero fuente, no en la
macro**. Sus tres razones declaradas, verbatim: *"1. So modinfo can show license info for users
wanting to vet their setup is free / 2. So the community can ignore bug reports including
proprietary modules / 3. So vendors can do likewise based on their own policies"*.

Consecuencias prácticas: un módulo propietario **taintea** el kernel, **no puede** usar la mayoría de
la API moderna (que está exportada como GPL-only), **nadie va a mirar tu reporte de fallo**, y
cualquier *shim* GPL que envuelva un blob propietario para sortear la comprobación es un problema
legal, no un truco técnico. **Consultar con abogado, no con Stack Overflow** — el propio documento de
Greg KH se niega explícitamente a tratar el tema legal.

### 5.4 Drivers vulnerables como riesgo (BYOVD), tratado como defensa
Un driver firmado y con un fallo explotable es una llave para el kernel que **el atacante no tiene
que fabricar: la trae puesta**. Esta skill lo trata exclusivamente desde dos lados:

- **Como autor**: tu driver firmado es infraestructura de ataque si expone primitivas genéricas.
  **PROHIBIDO** exponer por `ioctl` lectura/escritura de memoria física arbitraria, acceso a MSR, a
  puertos de E/S o mapeo de rangos arbitrarios "para una herramienta de diagnóstico" — es el patrón
  exacto de los drivers que acaban en las listas de bloqueo. Todo `ioctl` privilegiado exige
  comprobación de capacidad (`capable()`/`ns_capable()`) **y** rango cerrado de operaciones.
- **Como defensor**: en Windows, la **lista de bloqueo de drivers vulnerables de Microsoft** está
  activada por defecto y se refuerza con **HVCI**, Smart App Control o modo S; los bloqueos se ven en
  el visor de eventos (IDs 3023 y 3033). Microsoft advierte explícitamente que **no garantiza
  bloquear todo driver débil** por equilibrio con la compatibilidad, y hay al menos un hueco
  documentado (CVE-2025-59033) en sistemas **sin HVCI**. Conclusión operativa: **la lista de bloqueo
  no sustituye a un control de aplicaciones con lista de permitidos**, y su desactivación —que exige
  desactivar antes HVCI— es una decisión de riesgo que se documenta. En Linux, el equivalente es
  `CONFIG_MODULE_SIG_FORCE` + lockdown + no cargar módulos de terceros sin origen verificado.

**PROHIBIDO en este documento**: procedimientos de BYOVD, listas de drivers explotables con su
primitiva, técnicas de ocultación en kernel, o cualquier variante de rootkit. La postura es
defensiva; el trabajo ofensivo requiere alcance y autorización y es de `offensive-security-standards`.

## 6. Concurrencia, memoria y operabilidad

- **Saber en qué contexto se ejecuta cada función es requisito, no detalle.** Contexto de proceso
  (puede dormir) frente a contexto atómico —ISR, con spinlock tomado, RCU de lectura— donde **dormir
  es un fallo**: nada de `mutex_lock`, `kmalloc(GFP_KERNEL)`, `copy_from_user` ni `msleep`. Se
  documenta el contexto esperado de cada función, y `might_sleep()` + `CONFIG_DEBUG_ATOMIC_SLEEP`
  lo comprueban en tiempo de ejecución.
- **Elección de primitiva**: `mutex` por defecto en contexto de proceso; `spinlock` solo cuando se
  comparte con una ISR o la sección es de nanosegundos (y entonces la sección crítica **debe** ser
  minúscula); `spin_lock_irqsave` cuando el dato se toca desde interrupción; **RCU** cuando la
  lectura domina abrumadoramente y la escritura es rara — con la disciplina que impone (el lector no
  puede dormir en la sección clásica, el escritor publica con barreras y libera con `call_rcu`).
  **Un orden de bloqueo documentado por escrito** y `lockdep` activado, siempre.
- **Interrupciones**: el *top half* hace lo mínimo y despacha; el trabajo va a *threaded IRQ*
  (`request_threaded_irq`), *workqueue* o *tasklet* según la latencia exigida. Una ISR larga es
  latencia para todo el sistema, no solo para tu dispositivo.
- **Memoria**: `GFP_KERNEL` solo donde se puede dormir, `GFP_ATOMIC` es un recurso escaso que se
  agota y hay que justificarlo; nada de asignaciones grandes y contiguas si `vmalloc` o una lista de
  fragmentos sirve; la pila del kernel es **pequeña y fija** — sin arrays grandes en pila, sin VLA,
  sin recursión.
- **DMA**: se usa la **DMA API** (`dma_alloc_coherent`, `dma_map_single`/`dma_map_sg`), nunca
  direcciones físicas a mano; se respetan las máscaras del dispositivo (`dma_set_mask_and_coherent`)
  y la propiedad del buffer (mientras está mapeado al dispositivo, **la CPU no lo toca**). Con
  IOMMU y en VM, esto no es teoría: es la diferencia entre funcionar y corromper memoria ajena.
- **Camino de descarga (`remove`/`rmmod`)**: es el que menos se prueba y el que más rompe. Todo lo
  registrado se desregistra en orden inverso, los temporizadores y *workqueues* se cancelan y se
  espera a que terminen, y no queda ninguna referencia viva. Un `rmmod` que provoca *use-after-free*
  es el bug clásico.
- **Logging con criterio**: `dev_err`/`dev_warn`/`dev_info` (que identifican el dispositivo) frente
  a `pr_*`; **nada de logs por operación en camino caliente** —inundan el journal y son un vector de
  DoS desde usuario—; `dev_err_ratelimited` para lo que pueda repetirse.

## 7. Sostenibilidad a largo plazo y prohibiciones

- **Cadencia**: si el código está upstream, sigue el árbol y el trabajo de mantenimiento lo absorbe
  la comunidad. Si está fuera, el proyecto asume un compromiso explícito: **probar contra cada nueva
  LTS y contra `linux-next`**, con presupuesto asignado. Un módulo fuera del árbol sin nadie
  asignado a portarlo no es un producto: es una fecha de caducidad sin escribir.
- **Backports**: los parches de corrección van primero a mainline y de ahí a estable; **nunca al
  revés**. Un fix que solo existe en la rama del fabricante desaparece en la siguiente versión.

Prohibiciones explícitas:
- ❌ **Escribir un driver de kernel sin haber descartado las alternativas de §2.1 por escrito.**
- ❌ **Desreferenciar un puntero de espacio de usuario** o usar un tamaño venido de usuario sin
  validar. PROHIBIDO, sin matices.
- ❌ **Dormir en contexto atómico** (`mutex`, `GFP_KERNEL`, `copy_*_user`, `msleep` con spinlock
  tomado o dentro de una ISR).
- ❌ **Ignorar el retorno** de `copy_from_user`, `kmalloc`, `register_*` o cualquier función que pueda
  fallar. En el kernel no hay excepciones que recojan el descuido.
- ❌ **`ioctl` que exponga lectura/escritura de memoria física, MSR o puertos arbitrarios.** Es
  fabricar un BYOVD firmado con tu nombre (§5.4).
- ❌ **Exponer ABI nueva sin pensarla como permanente**, y **PROHIBIDO romper ABI de usuario ya
  publicada**: es la única regla verdaderamente inviolable del kernel.
- ❌ **`MODULE_LICENSE("GPL")` en un módulo que no lo es**, o cualquier *shim* GPL que envuelva un
  blob para acceder a símbolos `EXPORT_SYMBOL_GPL`.
- ❌ **Desactivar la comprobación de firma o el lockdown en producción** para cargar un módulo. Si
  hace falta, el módulo se firma; no se baja el control.
- ❌ **Desplegar a la flota sin canario y sin fases** ningún módulo, driver ni **fichero de datos que
  el driver consuma**. La lección de julio de 2024 (§2.5) es exactamente esta.
- ❌ **`printk` sin límite de tasa en camino caliente** o dependiente de entrada de usuario.
- ❌ **Recursión, VLA o arrays grandes en la pila del kernel.**
- ❌ **Parchear el árbol de la distribución en lugar de enviar upstream** cuando el cambio es de
  interés general: garantiza tener que rehacerlo en cada actualización.
- ❌ **Kext nuevo en macOS** habiendo DriverKit o System Extension que cubra el caso.
- ❌ **PROHIBIDO en esta skill**: recetario de BYOVD, técnicas de rootkit, ocultación de módulos,
  evasión de EDR o abuso de drivers vulnerables de terceros. Solo mitigación.

## 8. Verificación web obligatoria

**El kernel Linux no vive en GitHub.** Las fuentes autoritativas son `kernel.org`, `git.kernel.org`
(en formato **plano**, `.../plain/...`, para leer el fichero sin resumidor de por medio),
`docs.kernel.org`, `lore.kernel.org` para las listas y `lwn.net` para el contexto. Comprobar antes de
fijar nada:

1. **Versiones vigentes** en `kernel.org/releases.json`: mainline, stable y **qué ramas LTS siguen
   soportadas y hasta cuándo** — el calendario de EOL de las longterm cambia y decide a qué se
   portea.
2. **Mínimos de toolchain** en `Documentation/process/changes.rst` del árbol concreto: GCC, Clang,
   binutils, Rust, bindgen. Difieren entre mainline y cada LTS.
3. **Estado de Rust en el kernel**: `Documentation/rust/arch-support.rst` (la tabla de arquitecturas
   cambia), la política de versión mínima en `rust-for-linux.com/rust-version-policy`, y qué
   subsistemas tienen abstracciones utilizables. **Es el dato que peor envejece de este documento.**
4. **Los documentos de proceso citados aquí verbatim** (`stable-api-nonsense.rst`,
   `submitting-patches.rst`, `coding-style.rst`, `module-signing.rst`, `include/linux/module.h`):
   leerlos del árbol contra el que se trabaja, porque el texto se edita.
5. **El subsistema concreto**: `MAINTAINERS`, la lista correspondiente en `lore.kernel.org`, si hay
   refactor en curso (`linux-next`) que cambie la API que vas a usar, y si ya existe un driver para
   ese hardware.
6. **Windows**: estado de *attestation signing* frente a WHQL en `learn.microsoft.com`, el estado del
   *cross-signing* retirado, la versión vigente de la lista de bloqueo de drivers vulnerables, y el
   estado (preview o disponibilidad general) de la plataforma de seguridad de endpoint fuera del
   kernel.
7. **macOS**: si Apple ha anunciado ya fecha de retirada de kexts, qué KPIs se han eliminado en la
   versión objetivo y qué *entitlements* de DriverKit/Endpoint Security siguen requiriendo
   aprobación.
8. **CVE del subsistema** en el que se trabaja y si la rama LTS objetivo recibe el parche.

**Huecos declarados**: (a) el estado de disponibilidad general de la plataforma de seguridad de
endpoint de Windows fuera del kernel **no se ha podido confirmar con fuente primaria fechada en
2026**; se documenta como iniciativa anunciada, no como hecho consumado. (b) La fecha de retirada
definitiva de los kexts de macOS **no existe**: Apple no la ha anunciado, y cualquier documento que
la dé está inventando. (c) No se dan aquí cifras de latencia, *throughput* ni sobrecoste de las
alternativas de §2.1 porque **dependen del hardware y de la carga**: se miden en el sistema objetivo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
