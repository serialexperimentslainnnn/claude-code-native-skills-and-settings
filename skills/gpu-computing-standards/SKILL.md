---
name: gpu-computing-standards
description: Use when a GPU must be provisioned, shared, monitored or paid for — pinning the NVIDIA driver and CUDA toolkit to a compatibility matrix, nvidia-open versus proprietary kernel modules, DKMS rebuilds after a kernel update, Secure Boot module signing with MOK, blacklisting nouveau, nvidia-container-toolkit and nvidia-ctk with CDI, the Kubernetes device plugin, GPU Operator, DRA driver and nvidia.com/gpu requests, MIG profiles, CUDA MPS and time-slicing, nvidia-smi, nvidia-persistenced, DCGM and dcgm-exporter metrics, XID errors, ECC and thermal or power throttling, GPU TDP, rack density and liquid cooling, Slurm gres scheduling, AMD ROCm and HIP, or GPU utilization as a FinOps metric.
---

# Estándares de cómputo con GPU

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica cuando la GPU es **un recurso de infraestructura que hay que instalar, compartir,
medir, alimentar, refrigerar y pagar** — sirva para inferencia, entrenamiento, cómputo
científico, simulación o transcodificación:

- **El stack y sus versiones acopladas**: driver ↔ CUDA runtime ↔ framework.
- **Instalación en Linux**: módulos open (`nvidia-open`) vs. propietarios, DKMS, Secure Boot y
  firma de módulo, `nouveau`, `nvidia-persistenced`.
- **Contenedores con GPU**: NVIDIA Container Toolkit, `nvidia-ctk`, CDI; en Kubernetes,
  *device plugin*, GPU Operator y el driver DRA.
- **Compartir la GPU**: MIG, MPS, *time-slicing*, y qué aislamiento da cada uno.
- **Monitorización**: `nvidia-smi`, DCGM, `dcgm-exporter`, XID, ECC, *throttling*.
- **Físico y dimensionado**: TDP, alimentación, refrigeración, densidad de rack.
- **Coste**: comprar vs. alquilar, **utilización como métrica FinOps**, colas de trabajos.
- **Alternativas a CUDA**: AMD ROCm/HIP, y su madurez real.
- **Fiabilidad**: XID, GPU caída del bus, ECC, RMA.

**No aplica**: ver `local-inference-standards` (**servir modelos**: elección de motor,
cuantización, dimensionado de la caché KV, endpoint OpenAI y su seguridad — **si el servidor no
tiene GPU (CPU, Apple Silicon), sigue siendo suyo y no de esta skill**; aquí manda cuando el
problema es *la GPU*, allí cuando el problema es *el modelo*), `libvirt-kvm-standards` y
`proxmox-ve-standards` (**passthrough de GPU a una VM: SUYO, no de aquí** — VFIO, `vfio-pci`,
grupos IOMMU, `intel_iommu=on`/`amd_iommu=on`, volcado de vBIOS, reset de la tarjeta y la
pérdida de migración en vivo están cubiertos en su §3.8; esta skill llega hasta la frontera del
hipervisor y **no la cruza**: lo que sí es de aquí es el driver *dentro* del invitado, la
compartición sin virtualizar y todo lo de §5-§6), `kubernetes-standards` (manifiestos, Helm,
GitOps, políticas de admisión — aquí solo el criterio de **qué** recurso de GPU se pide y
cómo), `container-runtime-security-standards` (seccomp, escape de contenedor, `--privileged`
—aquí solo la superficie específica del toolkit de NVIDIA, §5.2),
`podman-systemd-containers-standards` (`--device nvidia.com/gpu=all` en una unidad Quadlet),
`onprem-standards` (**paraguas de plataforma**: rack, alimentación redundante, UPS, plano de
gestión OOB, ciclo de vida del hardware — esta skill es una capa dentro de su §1.2 y respeta
sus invariantes de §1.3; **la GPU no exime de telemetría, backup probado ni fencing**),
`homelab-standards` (**GPU en casa**: allí mandan el presupuesto, el ruido, el consumo y la
proporcionalidad — una 3090 de segunda mano en un lab no se dimensiona con criterios de CPD),
`linux-administration-standards` (systemd, kernel, paquetes), `rhel-fedora-standards`
(`dnf module`, `akmods`, `rpm-ostree` con driver), `linux-hardening-standards` (baseline CIS,
`modprobe.d`, sysctl), `selinux-standards` (contextos y políticas de los nodos de dispositivo),
`observability-standards` (Prometheus, PromQL, alertas — aquí solo **qué** métrica de GPU
importa y por qué), `sre-practice-standards` (SLO, capacidad como práctica),
`iac-standards` y `cicd-standards` (automatizar la instalación y el pin de versiones),
`vulnerability-management-standards` (triaje y SLA de los CVE de §5),
`bcdr-standards` y `backup-recovery-standards` (continuidad de un cluster de GPU),
`networking-standards` (la red del cluster; InfiniBand/RoCE queda **fuera de ambas** hasta que
tenga dueño: marcar como hueco), `firewall-policy-standards`,
`identity-access-management-standards`, `grc-compliance-standards`,
`datacenter-facilities-standards` (**la sala**: densidad por rack, distribución eléctrica y
refrigeración líquida —CDU, circuito, pasillo— **son suyas**; aquí el TDP y el requisito térmico
del acelerador que se les entrega como dato),
`python-standards`, `julia-standards` y `r-standards` (código que usa la GPU),
`fortran-standards` (**recíproco ya declarado desde su §1**: el `!$acc`/`!$omp target` que se
escribe en el `.f90` y su corrección son suyos; el kernel, la ocupación y el modelo de
programación de GPU, de aquí), `cpp-standards` y `c-standards` (**los kernels CUDA/HIP
son C++ y esa cercanía confunde**: el modelo de programación de la GPU —jerarquía de hilos, memoria
compartida, ocupación, *streams*, coalescencia— es de aquí; el **C++ del host** —estándar, RAII,
gestión de dependencias, `clang-tidy`, tests— es suyo), `green-it-standards` (**Ola 6**: la densidad de rack, el TDP, la refrigeración líquida y el consumo
como límite físico son de aquí; **su contabilidad de huella —energética e incorporada— y el criterio
para reportarla, suyos**), `webgl-webgpu-standards` (**Ola 6** — **son dos GPU distintas**: aquí la del **servidor**, que se
aprovisiona, se comparte, se monitoriza y se paga —driver, CUDA/ROCm, MIG, DCGM, densidad de rack—;
allí la del **cliente**, vista a través del navegador, con un modelo de permisos y de pérdida de
contexto que no existe en el servidor), `assembly-standards` (**Ola 5**: PTX y SASS
son ensamblador; el criterio de **cuándo se baja a ese nivel, cómo se justifica con una medida y
cómo se mantiene** —incluida su caducidad al cambiar de microarquitectura— es suyo), `llm-app-engineering-standards`, `rag-standards`,
`ai-agents-standards`, `mcp-standards` (capa de aplicación de IA), y `claude-api`
(**referencia canónica de la API de Anthropic**: la alternativa a comprar GPU es no comprarla —
ningún dato de modelos Claude, precio o límite se afirma de memoria).

**Ola 3, planificadas** (marcar como tal si se citan): `mlops-standards` (entrenamiento,
experimentos y ciclo de vida del modelo — **el hardware es de aquí, el pipeline es de allí**),
`llm-evaluation-standards`, `mlsecops-standards` (cadena de suministro del artefacto de
modelo), `ai-governance-standards`.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

### 2.1 El stack y sus versiones acopladas

**Es la fuente número uno de "no funciona".** Cuatro capas que se versionan por separado y se
rompen juntas:

```
driver del kernel (nvidia.ko / nvidia-open)
   └── CUDA driver API (libcuda.so — la trae el DRIVER, no el toolkit)
        └── CUDA runtime / toolkit (libcudart, cuBLAS, cuDNN, NCCL)
             └── framework (PyTorch, JAX, TensorRT, motor de inferencia)
```

Lo que hay que tener claro y **no** confundir:

- **El driver es compatible hacia atrás**: una aplicación compilada contra un CUDA antiguo
  sigue funcionando con un driver más nuevo. **Lo contrario no es cierto**.
- **Compatibilidad de versión menor** (texto verificado en las release notes del toolkit
  vigente, ago-2026): **CUDA 13.x requiere driver ≥ 580; 12.x, ≥ 525; 11.x, ≥ 450**. Es decir,
  dentro de una rama mayor no hace falta subir el driver en cada actualización de toolkit.
- **El toolkit vigente en ago-2026 es CUDA 13.3 Update 1**; la rama de driver de producción
  actual publicada como *open kernel modules* es **610.43.03** (jul-2026), con ramas anteriores
  595 y 580 aún activas.
- **Desde CUDA 13.1 el driver de Windows ya no viene empaquetado con el toolkit.** En Linux la
  separación siempre fue conceptualmente así: **instala el driver por el gestor de paquetes de
  la distribución y el toolkit aparte** (o, mejor, dentro del contenedor).
- **PyTorch trae su propio CUDA runtime en la rueda** (`torch-2.13.0+cu130`, `+cu132`,
  `+rocm7`, `+xpu` según el índice oficial en ago-2026). **Del sistema solo necesita el
  driver.** Por eso el error clásico "tengo CUDA 12 instalado y PyTorch pide 13" casi siempre
  es un problema de rueda mal elegida, no de toolkit.

**Regla de oro: en el host, solo el driver. Todo lo demás, dentro del contenedor.** Es lo que
convierte "actualizar el framework" en un cambio de imagen en vez de una intervención en el
host. En el host se instala driver + `nvidia-container-toolkit` y nada más.

**Todo se pinnea**: versión de driver, imagen base CUDA **por digest**, versión de framework,
versión de NCCL. La combinación exacta se registra como artefacto versionado
(`iac-standards`). Una actualización de driver es un cambio de plataforma con ventana y
rollback, no un `dnf update` de martes.

### 2.2 Instalación en Linux (NVIDIA)

| Decisión | Por defecto | Motivo / alternativa |
|---|---|---|
| Sabor de módulo | **Open kernel modules** (`nvidia-open`) | Doc oficial de NVIDIA, verbatim: *"Starting in the 560 driver release series, the open kernel module flavor is the default and suggested installation"*. Requiere **Turing o posterior**. El propietario queda para Maxwell/Pascal/Volta (arquitecturas ya fuera de las ramas nuevas) y como salida de emergencia |
| Origen del paquete | **Repositorio de la distribución o el de NVIDIA para esa distro**, no el `.run` | El `.run` no se integra con el gestor de paquetes: se rompe en cada `dnf/apt upgrade` y no deja rastro auditable |
| Compilación del módulo | **DKMS** (o `akmod` en Fedora/RHEL) | Recompila al actualizar el kernel. **Sin esto, el siguiente reinicio arranca sin GPU** |
| `nouveau` | **Blacklisteado explícitamente** en `modprobe.d` + regenerar initramfs | Si `nouveau` toma la tarjeta primero, el driver propietario no carga. Es el fallo de instalación más frecuente |
| Secure Boot | **Firmar el módulo y enrolar la MOK**, o desactivar Secure Boot **con decisión escrita** | Con Secure Boot activo y módulo sin firmar, el kernel rechaza cargarlo y el síntoma es "no hay GPU" sin error obvio. La clave de firma es un secreto (`secrets-management-standards`) |
| Persistencia | **`nvidia-persistenced` activo** en servidores | Sin él, el estado de la GPU se descarga al terminar el último cliente: inicialización lenta en cada arranque de proceso (más notoria con módulos open y GSP) |
| ECC | **Activado** en GPU de datacenter | Cuesta algo de VRAM y de ancho de banda; a cambio, detecta y corrige corrupción silenciosa. ❌ Desactivar ECC "para ganar memoria" en producción |
| Modo de cómputo | Por defecto, salvo requisito | `EXCLUSIVE_PROCESS` solo si el caso de uso lo exige |

**Riesgo operativo número uno: el kernel se actualiza y el módulo no compila.** Un kernel nuevo
puede romper la compilación DKMS del driver instalado. Mitigación obligatoria:

1. **Kernel pinneado** en nodos de GPU, con actualización deliberada y probada, no automática.
2. **Gate de arranque**: el nodo no vuelve a servicio hasta que `nvidia-smi` responde
   correctamente y una carga de prueba de CUDA pasa (§4).
3. **Poder volver atrás**: kernel anterior presente en el gestor de arranque.
4. En parcheo automatizado (`linux-hardening-standards`, `unattended-upgrades`/`dnf-automatic`),
   **excluir explícitamente kernel y driver** en nodos de GPU.

### 2.3 Contenedores con GPU

| Componente | Estado verificado (ago-2026) | Para qué |
|---|---|---|
| **NVIDIA Container Toolkit** (`nvidia-ctk`) | **v1.19.1** (may-2026) estable; **v1.20.0-rc.1** (jul-2026) en RC | Expone la GPU al contenedor en Docker/Podman/containerd. **CDI (Container Device Interface)** es el mecanismo preferente hoy: declarativo, y el modo legado de *hooks* es donde han vivido varios de los CVE de §5.2 |
| **NVIDIA GPU Operator** | **26.3.3** (jun-2026) | En Kubernetes, gestiona driver, toolkit, device plugin, DCGM y `node-feature-discovery` como un todo. **Es el camino por defecto en un cluster**: instalar cada pieza a mano diverge |
| **k8s-device-plugin** | **v0.19.3** (jun-2026) | Anuncia `nvidia.com/gpu` como *extended resource*. Mecanismo clásico: **entero, sin sobresuscripción** (`nvidia.com/gpu: 1` = una GPU entera) |
| **DRA driver para GPU NVIDIA** (`kubernetes-sigs/dra-driver-nvidia-gpu`) | Chart **0.4.x** (jun-2026). **DRA en el core de Kubernetes es GA desde 1.34**; el driver de NVIDIA para GPU está declarado **technology preview** (la parte de *ComputeDomains* para NVLink multinodo, soportada) | Futuro del scheduling de GPU: petición declarativa de características, compartición controlada, MIG dinámico. **Aún no es el default de producción**: evaluarlo, no apostar la plataforma |

**Criterio**: en Kubernetes, **GPU Operator + device plugin** hoy; DRA en piloto, con la
migración planificada, no improvisada. Fuera de Kubernetes, **CDI** con
`nvidia-ctk cdi generate` y `--device nvidia.com/gpu=…`.

### 2.4 Compartir la GPU

Las GPU no se sobresuscriben como la CPU. "Compartir" significa tres cosas muy distintas:

| Mecanismo | Aislamiento de memoria | Aislamiento de fallo | Requisitos | Cuándo |
|---|---|---|---|---|
| **Time-slicing** | ❌ Ninguno | ❌ Ninguno: comparten dominio de fallo; un OOM afecta a todos | Cualquier GPU; un flag en el device plugin | Cargas **de desarrollo, del mismo equipo, no críticas**. Sube densidad, no da garantías |
| **CUDA MPS** | ❌ **No hay aislamiento por hardware**: los límites se aplican en la capa de la API CUDA, no en silicio | ❌ **Peor que time-slicing**: un error CUDA fatal de un cliente **tumba el servidor MPS y con él a todos los demás clientes** | Procesos **confiables**, un solo usuario | Muchos procesos pequeños del mismo dueño que desperdician la GPU por separado. **Diseñado para entorno de un solo usuario** |
| **MIG** | ✅ **Particionado por hardware** | ✅ Real: agotas tu partición y el vecino no se entera | GPU con soporte MIG (Ampere+/datacenter); **perfiles estáticos**, planificados de antemano; máximo 7 instancias | **La única opción válida con inquilinos distintos**: equipos, clientes, radios de impacto separados |

Reglas:

- **Multi-inquilino real ⇒ MIG, o una GPU entera.** Time-slicing y MPS **no son fronteras de
  seguridad** y no deben presentarse como tales.
- **MPS y MIG no se combinan** (verificar en la versión de GPU Operator vigente).
- **El perfil MIG estático desperdicia**: si el perfil menor es de 20 GB y tu modelo ocupa 12,
  tiras 8 GB por instancia. La partición se planifica con datos de la carga, y se revisa.
- **La compartición no crea capacidad.** Si la GPU ya está saturada, repartirla solo reparte la
  cola.

### 2.5 AMD ROCm y alternativas — con honestidad

- **Versiones (ago-2026)**: la doc oficial de compatibilidad publica **ROCm 7.14.0**; existen a
  la vez releases de la línea **7.2.x** (7.2.4, may-2026). **Hay más de un flujo de release
  (producción vs. *technology preview*) y los números no son comparables entre sí**: verificar
  cuál es el flujo de producción antes de pinnear. PyTorch publica ruedas `+rocm7`.
- **Dónde funciona hoy**: PyTorch + vLLM/SGLang sobre Instinct (MI300X/MI355X y familia) es la
  combinación viable. La capacidad de HBM por tarjeta es una ventaja estructural real: modelos
  grandes con menos paralelismo de tensor.
- **Dónde no**: **no hay equivalente a TensorRT-LLM ni a FlashAttention 3**; kernels PTX
  personalizados hay que portarlos; `hipify` traduce código CUDA pero **no traduce llamadas a
  librerías CUDA** (cuDNN, cuBLAS, TensorRT). Las tarjetas de consumo van bastante por detrás
  de las Instinct en madurez de kernels.
- **El coste real no es de rendimiento, es de ecosistema**: cuando CUDA falla hay una década de
  respuestas publicadas; cuando ROCm falla, hay *issues* de GitHub. Ese coste lo paga tu
  equipo en horas, y hay que presupuestarlo.
- **Criterio**: ROCm es una opción **legítima y evaluable** si (a) tu stack es PyTorch + vLLM
  sin kernels propios, (b) tienes gente dispuesta a depurar, y (c) la ventaja de coste o de
  memoria es medible en tu carga. **Fuera de eso, CUDA sigue siendo el default**, y la prima
  que pagas compra ecosistema, no solo FLOPs. ❌ Elegir ROCm por ideología o por precio de
  catálogo sin un piloto medido.
- **Intel (`+xpu`)**: PyTorch publica ruedas; trátalo como evaluable, no como default.
  **Madurez no verificada en esta pasada** (§8).

## 3. Estructura y convenciones

- **Los nodos con GPU son una clase de nodo aparte**: etiquetados (`node-feature-discovery`),
  con *taints* para que no se les cuele carga sin GPU, kernel pinneado y ventana de parcheo
  propia. Mezclarlos con la flota general garantiza que un parcheo rutinario los rompa.
- **Inventario**: modelo de GPU, VRAM, capacidad de cómputo (SM), número de serie, versión de
  driver, versión de VBIOS y estado de ECC — como código, junto al resto de la flota
  (`onprem-standards`).
- **Una sola fuente de versiones**: un fichero versionado con driver, toolkit, framework y
  toolkit de contenedor de cada entorno. Sin él, "en mi nodo funciona" es indiscutible.
- **Reconstruible desde cero**: un nodo de GPU se reprovisiona desde código, incluida la
  instalación del driver y la firma del módulo. ❌ Nodos artesanales.
- **Nada de compilar dentro del nodo de producción**: la imagen con el framework se construye
  en CI (`cicd-standards`) y se promociona por digest.

## 4. Calidad y gates

**Validación de un nodo de GPU antes de ponerlo en servicio** (y después de cada actualización
de kernel o de driver) — en orden de coste creciente:

1. **`nvidia-smi` responde** y lista todas las GPU esperadas, con la versión de driver
   esperada. Si falta una, el nodo no entra.
2. **Módulo cargado y firmado**: el módulo carga con Secure Boot activo; DKMS/akmod reporta
   `installed` para el kernel en ejecución **y** para el anterior.
3. **Estado de salud**: ECC habilitado y **sin errores no corregibles**; ninguna GPU en modo
   degradado; enlace PCIe al ancho y generación esperados (un x16 negociado a x4 explica
   misteriosos problemas de rendimiento); ningún XID reciente en el journal.
4. **Prueba funcional de cómputo**: un contenedor con el toolkit ejecuta una carga CUDA real y
   comprueba el resultado. `nvidia-smi` dentro del contenedor no basta: prueba visibilidad,
   no cómputo.
5. **Prueba de estrés y térmica**: carga sostenida durante minutos, vigilando temperatura,
   potencia y **razones de throttling**. Los fallos de alimentación y de refrigeración solo
   aparecen bajo carga sostenida, nunca en un test corto.
6. **Multi-GPU**: prueba de ancho de banda entre GPU (NVLink/PCIe) y una prueba colectiva de
   NCCL. Una topología mal detectada convierte un cluster caro en uno lento.
7. **Diagnóstico DCGM** (`dcgmi diag`) al nivel apropiado, como paso final antes de aceptar el
   nodo o de devolverlo tras un incidente.

**Gates de CI/CD** que rompen el build o el despliegue:

- Versiones de driver/toolkit/framework **declaradas y pinneadas por digest**; drift detectado
  contra el inventario rompe el pipeline.
- La imagen no incluye el driver del host (error clásico); sí incluye el runtime y se prueba
  contra la versión de driver mínima soportada.
- Escaneo de CVE de la imagen base CUDA y del toolkit de contenedor
  (`vulnerability-management-standards`).
- Ningún manifiesto pide `nvidia.com/gpu` sin límite ni sin *toleration*; ningún pod de GPU
  corre como root ni con `--privileged` (`container-runtime-security-standards`).

## 5. Seguridad

### 5.1 Superficie del driver

- **El driver de GPU es un módulo de kernel enorme, propietario en parte, con una interfaz
  `ioctl` amplia expuesta a procesos sin privilegios a través de `/dev/nvidia*`.** Es
  superficie de escalada local de primer orden, y el historial lo confirma.
- Verificado en NVD (ago-2026): **CVE-2026-24187** (CVSS 8.8, *use-after-free* en el driver de
  **Linux**, con `S:C` — cambio de ámbito — y consecuencias que incluyen ejecución de código),
  **CVE-2026-24199** (4.7, condición de carrera en el módulo del kernel, DoS). El boletín
  asociado (may-2026) parchea las ramas **R595, R580 y R535**, y deja **R570 como EOL sin
  arreglo**: si tu `nvidia-smi` dice 570.x, no hay parche, hay migración de rama.
  **Verificar el boletín vigente antes de actuar** (§8).
- **Regla**: los boletines de NVIDIA se suscriben y se triagean como los del kernel
  (`vulnerability-management-standards`). El driver de GPU **no** es "un componente de
  escritorio".
- Endurecimiento: permisos restrictivos en `/dev/nvidia*`, confinamiento del proceso que puede
  emitir `ioctl` contra el driver (`selinux-standards`), y **descargar el módulo en hosts que
  no usan GPU**.

### 5.2 Container Toolkit — historial de escapes documentado

**El NVIDIA Container Toolkit ha tenido escapes de contenedor reales y repetidos.** Verificado
en NVD:

| CVE | CVSS | Qué |
|---|---|---|
| **CVE-2024-0132** | **9.0** | TOCTOU en configuración por defecto: una imagen de contenedor manipulada puede **acceder al sistema de ficheros del host**. La propia descripción de NVIDIA señala que **no afecta a los casos en que se usa CDI** |
| **CVE-2025-23359** | 8.3 | TOCTOU, bypass del anterior; mismo impacto |
| **CVE-2025-23266** | **9.0** | Vulnerabilidad en *hooks* de inicialización del contenedor: ejecución de código con permisos elevados |
| **CVE-2025-23267** | 8.5 | *Link following* en el hook `update-ldcache` |
| **CVE-2026-24260** | 8.5 | TOCTOU de nuevo (jul-2026), con `AV:N` y `S:C` |
| CVE-2024-0133/0134/0135/0136/0137 | 4.1–7.6 | Aislamiento impropio; **0134 afecta también al GPU Operator** |

Criterio derivado:

- **Preferir CDI** al modo legado de *hooks*: es el mecanismo declarativo y varios de los
  fallos son específicos de los hooks.
- **El toolkit se parchea rápido y se pinnea por versión**: es el componente con peor historial
  del stack y está en el camino crítico de todo contenedor con GPU.
- **Dar GPU a un contenedor es ampliar su superficie**, no solo darle cómputo. Contenedores que
  ejecutan carga no confiable **no reciben GPU** sin una capa adicional
  (`container-runtime-security-standards`).
- ❌ `--privileged` para "que funcione la GPU": si hace falta, la configuración del toolkit está
  mal.

### 5.3 Aislamiento entre inquilinos en GPU compartida

- **Time-slicing y MPS no aíslan memoria de GPU.** En MPS los procesos comparten espacio y los
  límites se aplican en la capa de API, no en hardware: un proceso hostil puede leer o corromper
  memoria de GPU de otro. **PROHIBIDO usarlos como frontera entre inquilinos.**
- **MIG es la única partición con respaldo de hardware.** Aun así, no es un hipervisor:
  para inquilinos verdaderamente hostiles, GPU dedicada o passthrough a VM
  (`libvirt-kvm-standards`, `proxmox-ve-standards`).
- **La memoria de GPU no se limpia sola de forma garantizada entre trabajos.** Con datos
  sensibles, política explícita de reset/limpieza entre trabajos de inquilinos distintos, y
  verificarla — no asumirla.
- **Passthrough tiene su propio riesgo y su propio dueño**: un dispositivo pasado hace DMA hacia
  el host, mediado por el IOMMU; con IOMMU mal configurado o con *overrides* de ACS, el
  invitado puede escribir memoria del host. **Eso lo gobierna `libvirt-kvm-standards` §3.8.**

## 6. Rendimiento, observabilidad y operación física

### 6.1 Monitorización: qué mide de verdad cada métrica

- **`utilization.gpu` de `nvidia-smi` (y `DCGM_FI_DEV_GPU_UTIL`) es engañosa.** Mide **la
  fracción de tiempo en que había al menos un kernel residente**, no cuánto trabajo se hace. Un
  kernel trivial en 1 de 132 SM marca **100%**. En *decode* de LLM esto es el estado normal:
  100% de "utilización" con los SM casi vacíos.
  **PROHIBIDO usar `utilization.gpu` como métrica de capacidad, de dimensionado o de FinOps.**
- **Lo que sí se mide** (DCGM, métricas de *profiling*):
  - `DCGM_FI_PROF_SM_ACTIVE` — ciclos con SM activo / ciclos totales.
  - `DCGM_FI_PROF_SM_OCCUPANCY` — llenado a nivel de *warp*.
  - `DCGM_FI_PROF_PIPE_TENSOR_ACTIVE` frente a `DCGM_FI_PROF_DRAM_ACTIVE` — **el diagnóstico
    útil**: tensor alto ⇒ limitado por cómputo; DRAM alto y tensor bajo ⇒ limitado por memoria
    (la situación normal del *decode*); ambos bajos con `GPU_UTIL` al 100% ⇒ kernels pequeños,
    sobrecoste de lanzamiento o *starvation* de datos.
  - **Memoria usada frente a memoria reservada** (un motor de inferencia reserva casi toda la
    VRAM por diseño: la métrica de reserva no dice nada sobre saturación).
  - **Temperatura, potencia, y `clocks_throttle_reasons`** — el *throttling* térmico o de
    potencia es la explicación más frecuente de "va más lento que ayer".
  - **ECC**: errores corregibles (tendencia) y **no corregibles (alerta inmediata)**;
    páginas retiradas / *row remapping*.
  - **Enlace**: generación y ancho PCIe negociados; errores de NVLink.
- **Caveats de recolección**: las métricas de *profiling* requieren privilegios (el
  `nv-hostengine` corre como superusuario), no todas se pueden recoger a la vez en todo
  hardware (DCGM multiplexa por muestreo), y hay incidencias conocidas de valores anómalos en
  dispositivos MIG. **No construyas una alerta crítica sobre una métrica que no has visto
  comportarse en tu hardware.**
- **Herramientas (ago-2026)**: **DCGM 4.6.0** (jul-2026) y **dcgm-exporter `4.6.0-4.8.3`**
  (jul-2026) hacia Prometheus. En Kubernetes lo despliega el GPU Operator.
  `nvidia-smi` es para diagnóstico interactivo, **no** para monitorización continua.
- El resto (retención, cardinalidad, diseño de alertas, dashboards como código) es de
  `observability-standards`.

### 6.2 Fiabilidad: XID y compañía

- **Los XID son el canal de error del driver.** Aparecen en el journal como
  `NVRM: Xid (PCI:0000:xx:00): <n>, …`. **Se recogen, se correlacionan y se alertan**; no son
  ruido de log.
- **XID 79 — "GPU has fallen off the bus"**: la GPU se desconecta del bus PCIe. Patrón típico:
  visible e idle correcta, cae al aplicar carga. Causas habituales por orden de probabilidad:
  **alimentación insuficiente o inestable, riser/adaptador (OCuLink, chasis de expansión, eGPU),
  temperatura, asiento del conector, hardware defectuoso** — y solo después, software.
  Diagnóstico: recoger el `nvidia-bug-report.sh` **antes** de descargar el módulo, revisar AER
  del PCIe en el journal, y **probar la tarjeta en otra ranura y en otra máquina**. Si tras
  reiniciar la GPU no aparece, asume hardware.
- **XID de "GPU Reset Required"**: el nodo debe drenarse y reiniciarse la GPU o el host. Un
  nodo en ese estado no acepta trabajos: **automatiza el *cordon*/*drain*** en vez de
  descubrirlo por trabajos que fallan.
- **ECC no corregible ⇒ el nodo sale de servicio.** No se "vigila a ver". Páginas retiradas en
  aumento ⇒ candidato a RMA.
- **Todo trabajo largo debe tener *checkpointing***: en una flota de GPU, el fallo de una
  tarjeta durante un entrenamiento de días no es una hipótesis, es una certeza estadística.
- **Runbook obligatorio** por familia de fallo (XID, ECC, throttling, caída de NCCL) con la
  acción y el criterio de RMA (`incident-management-standards`, `onprem-standards`).

### 6.3 Dimensionado y operación física — la GPU cambia el diseño del CPD

- **La GPU no se dimensiona como un servidor.** Un rack de servidores tradicional se mueve en
  el entorno de 5-15 kW; las plataformas de GPU actuales están un orden de magnitud por
  encima: los sistemas de escala de rack de generación Blackwell se especifican en torno a
  **~120-140 kW por rack** (la referencia GB200 NVL72 se documenta hasta **132 kW**), y las
  generaciones siguientes apuntan más arriba. **Verificar la cifra del modelo concreto en su
  ficha técnica** (§8).
- **Consecuencias que no son negociables**:
  - **Refrigeración líquida directa al chip** deja de ser opcional por encima de ~40-50 kW por
    rack: el aire no llega, y las puertas traseras de intercambio no cubren esa densidad. Eso
    arrastra CDU, bucle de agua de planta, caudal y temperatura de entrada.
  - **Alimentación trifásica dedicada** dimensionada a carga plena, con PDU y protecciones
    acordes (`onprem-standards`).
  - **Peso y estructura**: un rack de escala GPU pesa en el entorno de la tonelada. El suelo y
    el acceso importan.
  - **Diseña con margen**: la densidad por rack ha venido doblándose cada 18-24 meses. Un CPD
    especificado exactamente a la generación actual nace obsoleto.
  - **En homelab** todo esto se traduce en: consumo en reposo, ruido, y si el circuito
    eléctrico de casa aguanta. Manda `homelab-standards`.
- **Límite de potencia (`power limit`) como palanca**: bajar el techo de potencia suele costar
  poco rendimiento y ahorrar mucha energía y calor. **Se mide en tu carga**, no se supone.

### 6.4 Coste: comprar, alquilar y la métrica que importa

- **La métrica FinOps de una GPU es la utilización, y no la de `nvidia-smi`** (§6.1): es
  *fracción del tiempo con trabajo útil* respecto al tiempo amortizado. **Una GPU al 15% es
  dinero quemado** — y peor, es dinero quemado invisible, porque el panel marca "100% GPU util".
- **Comprar** se justifica con: utilización sostenida alta, horizonte de 2-3 años, dato que no
  puede salir, y capacidad de operar el hardware. **Alquilar** (cloud o *bare metal* por horas)
  se justifica con: carga a ráfagas, incertidumbre sobre el modelo o el tamaño, picos de
  entrenamiento, y no querer comprar una arquitectura que se queda vieja.
- **Coste total de propiedad**: compra + electricidad (24×7, y **con PUE**, no solo la TDP de
  la tarjeta) + refrigeración + espacio + red + garantía/RMA + **operación**. La partida de
  operación es la que se olvida y la que más crece.
- **Colas de trabajos** para exprimir el hardware — sin ellas la utilización se hunde:
  - **Slurm** (`gres.conf`, `--gres=gpu:N`, particiones, QoS, *preemption*, *fairshare*) para
    cargas por lotes, HPC y entrenamiento: es el estándar del mundo científico y hace bien lo
    que Kubernetes hace regular (colas con prioridad y *backfill*).
  - **Kubernetes** cuando la carga es de servicio (inferencia) o el resto de la plataforma ya
    está ahí; para lotes, con un planificador de colas encima (Kueue, Volcano o equivalente —
    **verificar el estado actual de cada uno**, §8) porque el scheduler por defecto **no tiene
    colas ni gang scheduling**.
  - **Regla**: no montes ambos por si acaso. Elige según la naturaleza de la carga dominante.
- **Chargeback/showback por equipo** con la métrica correcta: sin él, nadie libera una GPU
  reservada "por si acaso", y la reserva ociosa es el mayor sumidero de coste en toda flota de
  GPU.

## 7. Sostenibilidad y prohibiciones

- **Cadencia**: revisar boletines de seguridad de NVIDIA y CVE del Container Toolkit
  **mensualmente**; revisar rama de driver y su EOL **trimestralmente** (una rama EOL no recibe
  parche: hay que migrar); revisar matriz driver/CUDA/framework **antes de cada upgrade de
  framework**.
- **Política de ramas de driver**: usar ramas soportadas (LTS/producción) y **planificar la
  salida de una rama antes de su EOL**, no al descubrir que no hay parche para un CVE crítico.
- **Actualizar driver y kernel a la vez es pedir un incidente doble**: se hacen por separado,
  con validación de §4 en medio.
- **Ciclo de vida del hardware**: la generación anterior de GPU no se tira, se degrada a
  desarrollo, a inferencia menos exigente o a lab. Pero **el consumo eléctrico de hardware
  viejo puede hacer que salga más caro que reemplazarlo**: se calcula, no se supone.

**PROHIBIDO**

- ❌ Usar `utilization.gpu` / `DCGM_FI_DEV_GPU_UTIL` como métrica de capacidad, de saturación o
  de coste.
- ❌ Presentar time-slicing o MPS como aislamiento entre inquilinos.
- ❌ Desactivar ECC en producción para ganar VRAM.
- ❌ Instalar el driver con el `.run` en un servidor gestionado por paquetes.
- ❌ Actualización automática de kernel en un nodo de GPU, o parcheo sin gate de validación
  posterior (`nvidia-smi` + carga CUDA real).
- ❌ Dejar `nouveau` sin blacklistear y esperar que cargue el driver.
- ❌ Desactivar Secure Boot "porque el módulo no carga", sin decisión escrita y sin evaluar la
  firma con MOK.
- ❌ `--privileged` para acceder a la GPU desde un contenedor.
- ❌ Container Toolkit sin parchear, o modo legado de *hooks* cuando CDI está disponible.
- ❌ Dar GPU a un contenedor que ejecuta carga no confiable.
- ❌ Volver a servicio un nodo con XID recientes o errores ECC no corregibles sin diagnóstico.
- ❌ Trabajos largos sin checkpointing en una flota de GPU.
- ❌ Instalar el toolkit CUDA completo en el host cuando el framework lo trae en el contenedor.
- ❌ Mezclar versiones de driver dentro de un mismo pool de scheduling.
- ❌ Diseñar sala, alimentación o refrigeración con supuestos de rack de CPU.
- ❌ Comprar GPU sin un cálculo de utilización esperada y sin una cola que la llene.
- ❌ Adoptar ROCm (o cualquier alternativa a CUDA) sin un piloto medido en tu carga.
- ❌ Cubrir passthrough/VFIO aquí: es de `libvirt-kvm-standards` y `proxmox-ve-standards`.
- ❌ Afirmar de memoria una versión de driver, de CUDA, de ROCm, un TDP o una cifra de
  densidad de rack.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, número o nombre:

1. **Versiones**, por `api.github.com/.../releases/latest` o por el feed `releases.atom`
   (**nunca por el HTML de la página de releases: el resumidor se inventa el año**).
   Comprobado así en ago-2026: `nvidia-container-toolkit` **v1.19.1** (may-2026) con
   **v1.20.0-rc.1** (jul-2026), **GPU Operator 26.3.3** (jun-2026), `k8s-device-plugin`
   **v0.19.3** (jun-2026), **DCGM 4.6.0** (jul-2026), `dcgm-exporter` **4.6.0-4.8.3**
   (jul-2026), `open-gpu-kernel-modules` **610.43.03** (jul-2026), **ROCm 7.14.0** (jul-2026)
   y **7.2.4** (may-2026).
2. **CUDA**: versión vigente y **tabla de compatibilidad de versión menor** en las release
   notes oficiales. Verificado verbatim (ago-2026): toolkit **13.3 Update 1**; 13.x ⇒ driver
   **≥ 580**, 12.x ⇒ **≥ 525**, 11.x ⇒ **≥ 450**.
3. **Matriz driver ↔ CUDA ↔ framework**: el índice de ruedas de PyTorch
   (`download.pytorch.org/whl/torch/`) dice exactamente qué builds existen. Verificado
   (ago-2026): `torch 2.13.0` con `+cu126`, `+cu129`, `+cu130`, `+cu132`, `+rocm7`, `+xpu`.
4. **Sabor de módulo y arquitecturas soportadas**: la guía de instalación de NVIDIA y el README
   de la rama concreta. **Ojo, hay discrepancia entre fuentes oficiales** (§ hueco abajo).
5. **Boletines de seguridad de NVIDIA** (driver, vGPU, Container Toolkit, TensorRT-LLM) y NVD
   para el detalle y el CVSS. Verificado en NVD (ago-2026): CVE-2026-24187 (8.8),
   CVE-2026-24199 (4.7), CVE-2026-24260 (8.5), CVE-2025-23266 (9.0), CVE-2025-23267 (8.5),
   CVE-2025-23359 (8.3), CVE-2024-0132 (9.0).
6. **EOL de la rama de driver que usas**: el boletín de may-2026 dejó **R570 sin arreglo**.
   Comprobar el estado de tu rama **antes** de necesitarlo.
7. **Estado de DRA** para GPU en tu versión de Kubernetes y del driver NVIDIA (GA en el core
   desde 1.34; el driver de GPU, technology preview en ago-2026).
8. **Nombres exactos de campos DCGM** en la versión instalada y en la doc de `dcgm-exporter`.
9. **Códigos XID**: la lista canónica de NVIDIA (`docs.nvidia.com/deploy/xid-errors`).
10. **TDP, densidad de rack y requisitos de refrigeración** del modelo concreto, en su ficha
    técnica del fabricante. No de un blog.

**Huecos declarados (no verificados en esta pasada, no rellenar de memoria)**

- **Sabor de módulo por arquitectura: fuentes oficiales en conflicto.** La guía de instalación
  de datacenter dice que los módulos open son *"only for Turing and newer architectures"* y que
  los propietarios son necesarios para *"older GPUs from the Maxwell, Pascal, or Volta
  architectures"*; el README de ramas recientes indica que el sabor propietario cubre
  Turing–Hopper y que **Blackwell y posteriores son solo open**, y que la rama 580 fue la
  última con soporte de Maxwell/Pascal/Volta. **Consultar el README de la rama exacta que vas a
  instalar**; la guía general puede estar desactualizada.
- **ROCm: cuál es el flujo de release de producción**. Coexisten numeraciones (7.2.x y 7.1x.x)
  que parecen corresponder a flujos distintos (producción vs. *technology preview*/TheRock).
  **No verificado cuál se debe pinnear.**
- **Cifras de rendimiento ROCm frente a CUDA**: los rangos publicados van desde "37-66% de un
  H100" hasta "90-95% de paridad", según fuente, modelo y esfuerzo de tuning. **Ninguna
  verificada de forma independiente.** No citar un número sin piloto propio.
- **Madurez del backend Intel XPU**: no evaluada.
- **Estado actual de Kueue / Volcano** como planificador de colas sobre Kubernetes: nombres
  citados, versiones y madurez **no verificadas**.
- **Detalle de MIG**: número máximo de instancias, perfiles y arquitecturas soportadas hoy
  citados de fuentes secundarias. **Verificar en la doc de MIG de NVIDIA** antes de planificar
  una partición.
- **Densidad de rack**: las cifras de §6.3 son de plataformas de escala de rack de referencia,
  no de tu servidor. **El dato que manda es la ficha técnica del modelo que compras.**
- **InfiniBand / RoCE y la red del cluster de GPU**: **sin dueño en el catálogo**. No cubierto
  aquí ni en `networking-standards`. Candidato a skill futura.
- **Firma de módulo con MOK y su automatización** (kmodsign, procedimiento por distro):
  criterio fijado, comandos concretos **no verificados** en esta pasada.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
