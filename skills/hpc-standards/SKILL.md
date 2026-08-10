---
name: hpc-standards
description: High-performance computing clusters as an operated service — batch scheduling, the software environment and the parallel filesystem. Use when writing or debugging a Slurm job with sbatch, srun, salloc, squeue, scancel, sacct, sacctmgr, sinfo and scontrol, editing slurm.conf, slurmdbd.conf, cgroup.conf or a partition/QoS/fairshare/TRES limit definition, turning on job accounting, sizing a login/compute/management node split, a user who compiled on the login node, migrating from PBS Pro, OpenPBS qsub or IBM Spectrum LSF bsub, deciding whether a batch scheduler or a container orchestrator fits the workload, running an MPI job with Open MPI or MPICH and setting rank pinning and CPU affinity, measuring strong versus weak scaling, managing the software stack with environment modules, Lmod module load and module spider, Spack specs and environments, EasyBuild easyconfigs, or Apptainer .sif images and apptainer exec, operating Lustre with lfs setstripe and lfs quota, IBM Storage Scale/GPFS with mmlsfs, BeeGFS or CephFS under a small-file I/O pattern, setting a scratch purge policy against home and archive tiers, node provisioning with xCAT or Warewulf, benchmarking with HPL, HPCG or the Top500 list, or isolating users and sensitive data on a shared cluster.
---

# Estándares de HPC — el clúster de cálculo como servicio operado

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **el clúster de cálculo como servicio multiusuario**: su arquitectura de nodos, el
planificador de trabajos y su contabilidad, el entorno de software que los usuarios consumen,
el sistema de ficheros paralelo y su política de datos, la medida honesta del rendimiento, y
el aislamiento entre usuarios que comparten la máquina.

**Principio rector**: **un clúster de HPC no es "muchos servidores"; es un recurso compartido
escaso con una cola delante.** Todo lo que decide esta skill —particiones, límites, cuotas,
purga, contabilidad— existe para repartir escasez con criterio explícito. Un clúster sin
contabilidad ni límites no se comparte: se lo queda quien más rápido escribe `sbatch`.

Triggers: `sbatch`, `srun`, `salloc`, `squeue`, `scancel`, `sacct`, `sacctmgr`, `sinfo`,
`scontrol`, `slurm.conf`, `slurmdbd.conf`, `cgroup.conf`, `gres.conf`, partición, QoS,
*fairshare*, TRES, `qsub`/`qstat` (PBS), `bsub` (LSF), "nodo de login", "he compilado en el
login y va lentísimo", `mpirun`/`mpiexec`, *pinning*, afinidad, escalabilidad fuerte/débil,
`module load`, `module spider`, Lmod, `spack install`, `spack env`, `eb` / *easyconfig*,
`apptainer exec`, `.sif`, `lfs setstripe`, `lfs quota`, `mmlsfs`, BeeGFS, CephFS, *scratch*,
política de purga, cuota por proyecto, cola de GPU, HPL, HPCG, Top500, xCAT, Warewulf,
"el trabajo se ha quedado en PENDING", "millones de ficheros pequeños".

**No aplica**: ver `high-speed-interconnect-standards` (**la red RDMA es suya**: InfiniBand,
RoCE v2, `opensm`, particiones P_Key, UCX, GPUDirect, topología fat-tree y su
sobresuscripción — aquí solo se **exige** que exista y que MPI la use, y se mide el efecto),
`gpu-computing-standards` (**la GPU en sí**: driver, CUDA, MIG/MPS, DCGM, XID, consumo — aquí
solo la GPU **como recurso planificable y contabilizado**),
`datacenter-facilities-standards` (**la planta**: energía, kW/rack, refrigeración líquida,
peso y suelo; el clúster denso vive allí antes que aquí),
`server-hardware-standards` (el nodo como hierro, BMC y firmware),
`os-provisioning-standards` (**el mecanismo de instalación masiva**: PXE, Kickstart, imagen —
aquí xCAT/Warewulf solo como opción específica de HPC y el criterio de nodo sin estado),
`linux-storage-standards` (bloque local, LVM, NVMe, planificadores de E/S),
`zfs-standards` y `object-storage-standards` (otras capas de almacenamiento; aquí el
**paralelo** y el archivo), `kubernetes-standards` (**el orquestador de contenedores y su
clúster** — ver §2.2: no es sustituto directo de un planificador batch),
`podman-systemd-containers-standards` (contenedores en un host suelto),
`mlops-standards` y `deep-learning-standards` (**entrenar un modelo**: pipeline, registro,
deriva, DDP/FSDP; aquí solo la cola que le da los nodos),
`local-inference-standards` (servir un modelo), `fortran-standards`, `c-standards`,
`cpp-standards`, `julia-standards`, `r-standards`, `python-standards` (**el código numérico y
su calidad son suyos**; aquí cómo se compila, se empaqueta y se lanza),
`performance-engineering-standards` (**la metodología general de medir**: modelo de carga,
percentiles, perfilado — aquí la métrica propia del dominio, que es escalabilidad),
`observability-standards`, `sre-practice-standards`, `ha-clustering-standards` (HA de
servicio; aquí el clúster es *scale-out*, no *high-availability*),
`backup-recovery-standards` (**y su criterio se aplica al revés en §3.6: el `scratch` no se
respalda, y eso se declara**), `identity-access-management-standards` (el IdP que autentica al
usuario), `linux-hardening-standards`, `selinux-standards`, `privacy-engineering-standards`
(dato personal en el clúster), `grc-compliance-standards`, `finops-standards` (coste en nube y
la comparación contra hardware propio), `green-it-standards` (huella del cálculo),
`onprem-standards` (**paraguas de plataforma y su tabla de enrutado §1.2**: sus invariantes
mandan), `homelab-standards` (**proporcionalidad**: cuatro máquinas en casa no son un clúster
HPC y no necesitan Slurm), y `embedded-iot-standards`.

## 2. Decisiones por defecto

> Verificar la última versión, el estado del proyecto y **la licencia leyendo el fichero en
> crudo** antes de fijar nada (§8).

### 2.1 Toolchain

| Pieza | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| Planificador | **Slurm** | Estándar de facto en HPC académico y en buena parte del comercial; GPL (con excepción OpenSSL), soporte comercial de SchedMD disponible. Alternativas justificables abajo |
| Entorno de módulos | **Lmod** | Jerárquico, con `module spider` y bloqueo de conflictos; sustituye a `environment-modules` clásico sin romper la sintaxis `module load` |
| Construcción de software | **Spack** para el stack del sitio | Dual **Apache-2.0 / MIT** (verificado en crudo). Modela variantes, compiladores y dependencias como *specs*; genera módulos Lmod. **EasyBuild** (GPL-2.0, verificado en crudo) es alternativa legítima y madura, con *easyconfigs* más prescriptivos |
| Contenedores | **Apptainer** (`.sif`) | **BSD-3-Clause** y proyecto de la Linux Foundation (verificado en crudo, ver §3.4). Ejecuta como el usuario, sin demonio, y monta el sistema paralelo. **Docker no encaja** por su modelo de privilegios |
| MPI | **Open MPI** salvo motivo | El vendor MPI del fabricante de la red suele ganar en rendimiento y es alternativa legítima; **MPICH** es la otra base sólida y la que muchos MPI comerciales derivan |
| Sistema de ficheros paralelo | **Lustre** en instalaciones grandes; **CephFS** si ya hay Ceph | Ver §2.3: la elección la manda tanto la licencia y el soporte como el patrón de E/S |
| Aprovisionamiento de nodos | **Nodos de cálculo sin estado o reconstruibles** (imagen, no configuración acumulada) | Un nodo de cálculo *snowflake* rompe la reproducibilidad de los resultados, que aquí es el producto. `xCAT` y `Warewulf` son las herramientas propias del nicho; el criterio general es de `os-provisioning-standards` |
| Contabilidad | **`slurmdbd` desde el día uno** | No es opcional (§3.2) |

Versiones observadas en agosto de 2026 — **se verifican, no se copian** (§8): Slurm **26.05.x**
(cadencia semestral `YY.MM`, soporte 18 meses), Open MPI **5.0.x**, Apptainer **1.5.x**,
Spack **1.2.x**, Lustre LTS **2.15.x** con rama de características **2.17.x**.

### 2.2 Alternativas al planificador, y la comparación que se hace mal

- **PBS Pro / OpenPBS** (Altair). **Aviso de licencia, verificado en crudo**: OpenPBS es
  **AGPL-3.0-or-later**, no GPL ni permisiva. Se cree lo contrario con frecuencia; si hay
  cualquier modificación expuesta como servicio, cambia la conversación legal. PBS Professional
  es la edición comercial de Altair con licencia propietaria.
- **IBM Spectrum LSF**: propietario, fuerte en entornos industriales y de EDA. Migrar de LSF a
  Slurm es traducible en lo básico (`bsub` → `sbatch`) y doloroso en lo demás: políticas,
  contabilidad y scripts de usuario.
- **Kubernetes**: **no es un sustituto directo de un planificador batch**, y presentarlo como
  tal es el error de diseño de moda. Diferencias que no se cierran con un plugin:
  - K8s planifica **pods que deben seguir corriendo**; Slurm planifica **trabajos que deben
    terminar**, con reserva de nodos completos, *backfill* y tiempo límite como contrato.
  - Un trabajo MPI necesita **planificación en pandilla** (*gang scheduling*): todos los rangos
    arrancan a la vez o no arranca ninguno. El planificador por defecto de K8s no lo hace; hay
    proyectos que lo añaden (Volcano, Kueue, Slinky/Slurm-en-K8s). **El criterio de colas y
    *gang scheduling* dentro del clúster es de `kubernetes-standards` §6**, que los tiene
    verificados; **el criterio de cuándo esa carga no debe correr en Kubernetes es de aquí** y
    manda sobre la elección de herramienta. Slinky sigue sin verificar (§8).
  - Falta el equivalente nativo de **fairshare y contabilidad de consumo por proyecto**, que es
    la razón de ser de un clúster compartido.
  - **Cuándo sí**: cargas de servicio, inferencia, portales, CI y flujos de datos alrededor del
    clúster. **Convivir es lo normal; sustituir, casi nunca.** La decisión se toma por el modelo
    de trabajo (terminar vs. seguir corriendo), no por preferencia de plataforma.

### 2.3 Sistemas de ficheros paralelos — licencia y patrón de E/S

**Ninguna de estas licencias se afirma de memoria; están leídas en crudo o en la fuente del
fabricante** (§8).

| Sistema | Licencia / modelo | Cuándo, y qué lo mata |
|---|---|---|
| **Lustre** | Módulos de kernel bajo `GPL-2.0 WITH Linux-syscall-note` (verificado en el `COPYING` del repo); resto de componentes con licencias compatibles con GPL-2.0 | El caballo de batalla del HPC grande: caudal secuencial altísimo con *striping*. **Lo mata el metadato**: millones de ficheros pequeños saturan el MDS mucho antes que el ancho de banda |
| **IBM Storage Scale** (antes **Spectrum Scale**, antes **GPFS**) | **Propietario, de pago**, con ediciones (Data Access / Data Management / Erasure Code) y métrica de licencia por capacidad o por socket | Ecosistema empresarial, gestión del ciclo de vida del dato y niveles integrados. El coste y la métrica de licencia son parte de la decisión, no un detalle |
| **BeeGFS** | **No es open source.** El cliente kernel es GPL-2.0; **todo lo demás se rige por el *BeeGFS License Agreement*** (fichero en crudo verificado, **"As of February, 2026"**), con uso interno, límites de escala y **claves de licencia técnicas desde la versión 8** | Fácil de desplegar y muy rápido en cargas pequeñas y medianas. **Comprobar los términos y los umbrales antes de dimensionar**: han cambiado en 2026 |
| **CephFS** | LGPL-2.1/LGPL-3.0 (Ceph); verificar en crudo antes de citar | Coherente si ya se opera Ceph para bloque y objeto. Menos caudal por cliente que Lustre en el caso HPC clásico; a cambio, una sola plataforma que operar |

**Regla transversal, y es la que más cuesta a los usuarios**: **el enemigo de todo sistema de
ficheros paralelo es el fichero pequeño.** Está diseñado para pocos ficheros enormes leídos y
escritos en paralelo. Un trabajo que crea 10 millones de ficheros de 4 KB —típico de mallas,
de datasets de imágenes y de *checkpoints* por rango— degrada el clúster **entero**, no solo
su propio trabajo. Mitigación: empaquetar (tar, HDF5, formatos de dataset), E/S colectiva
(MPI-IO, parallel HDF5), un fichero por trabajo en vez de uno por rango, y usar el disco
local del nodo cuando exista.

## 3. Estructura y convenciones

### 3.1 Arquitectura del clúster

Roles separados, sin excepciones:

- **Nodo(s) de login**: puerta de entrada. Editar, enviar trabajos, mirar resultados. Nada más.
- **Nodos de cálculo**: donde ocurre el trabajo. Sin usuarios interactivos salvo por reserva
  del planificador.
- **Nodo(s) de gestión**: `slurmctld`, `slurmdbd`, base de datos, servicios de imagen y
  monitorización. **Separados del login**, porque el login es el nodo que los usuarios tiran.
- **Servidores del sistema de ficheros paralelo**: dedicados (MDS/OSS o equivalentes).
- **Nodo(s) de transferencia de datos** cuando hay entrada/salida masiva, para que la
  transferencia no compita con el login.

**Por qué nadie compila en el nodo de login**: el login está compartido por decenas de usuarios
sin aislamiento de recursos. Un `make -j$(nproc)` consume toda la CPU y toda la memoria del
nodo por el que **todo el mundo** entra; el resultado es que nadie puede ni mirar su cola.
Además, el binario resultante hereda las capacidades del procesador del login, que puede no
ser el de los nodos de cálculo — un `-march=native` allí produce un ejecutable que revienta
con instrucción ilegal en el cálculo, o que corre por debajo de sus posibilidades.
**Se compila en un trabajo interactivo (`salloc`/`srun`) o en un nodo dedicado a construcción.**
Y se aplica **límite de recursos por usuario en el login** (cgroups vía systemd, `ulimit`,
`arbiter`-like), porque la norma escrita no basta: se hace cumplir o no existe.

### 3.2 Slurm — lo que hay que decidir

- **Particiones por *función*, no por capricho**: cortas e interactivas, largas, de memoria
  grande, de GPU, de depuración. Cada partición con **tiempo límite explícito**. Una partición
  sin `MaxTime` es una cola donde los trabajos se quedan a vivir.
- **Nodo entero o compartido**: decidir y documentarlo. Compartir nodo exige
  **`cgroup.conf` con contención real de CPU y memoria**, o un trabajo que se pasa de memoria
  mata al vecino. Sin *cgroups*, el nodo se asigna entero.
- **Límites por asociación** (cuenta/usuario/partición): trabajos en cola, trabajos en
  ejecución, nodos, CPU-hora. Existen para que un solo usuario no ocupe el clúster; se ponen
  **antes** del incidente.
- **QoS** para expresar prioridad y política: alta prioridad con preferencia (*preemption*),
  baja prioridad y *preemptible* para relleno oportunista, QoS de depuración con límite corto y
  poca espera.
- ***Fairshare***: la prioridad se calcula contra el consumo histórico frente a la cuota
  asignada. Es lo que hace que un grupo que consumió mucho el mes pasado ceda el paso. **No
  funciona sin contabilidad.**
- ***Backfill***: rellena huecos con trabajos cortos, y **solo funciona si los usuarios piden
  tiempos realistas**. Pedir el máximo "por si acaso" es lo que degrada la eficiencia global
  del clúster; se combate mostrando al usuario su eficiencia real (`seff`/`sacct`).
- **Contabilidad (`slurmdbd`) — requisito, no lujo.** Sin ella no hay *fairshare*, no hay
  informe de uso por proyecto, no hay forma de justificar la compra siguiente, no hay forma de
  saber si el clúster se usa o se desperdicia, y no hay traza de quién ejecutó qué. Se instala
  el primer día; retrofitarla no recupera el histórico perdido.
- **Actualizaciones**: Slurm sostiene actualización en caliente desde las versiones mayores
  anteriores admitidas, en un orden concreto (`slurmdbd` primero) y **con copia de la base de
  datos antes**. Verificar la matriz de la versión concreta (§8) — saltarse una versión no
  admitida obliga a una migración manual.
- **Prólogo/epílogo**: limpiar procesos huérfanos, borrar temporales del nodo y sanear el
  estado entre trabajos. Un nodo que arrastra procesos del trabajo anterior es la causa
  silenciosa del "mi trabajo va la mitad de rápido que ayer".

### 3.3 MPI, afinidad y escalabilidad

- **La afinidad se fija siempre.** Sin *pinning*, el planificador del sistema operativo mueve
  los rangos entre núcleos y entre nodos NUMA; el rendimiento se vuelve no reproducible y cae.
  Se fija por el lanzador (`srun --cpu-bind`, opciones de *mapping* del MPI) y **se verifica**
  imprimiendo el mapa de rangos a núcleos antes de creerse una medida.
- **El error clásico del dominio: medir escalabilidad sin fijar afinidad.** La curva resultante
  no mide el código, mide la aleatoriedad del planificador. Toda medida de escalabilidad
  declara: afinidad, versión de MPI y de compilador, distribución de rangos, tamaño del
  problema, y si el nodo estaba en exclusiva.
- **Escalabilidad fuerte** (problema fijo, más recursos: ¿baja el tiempo?) frente a **débil**
  (problema crece con los recursos: ¿se mantiene el tiempo?). Se declara **cuál** se está
  midiendo. Una curva de escalabilidad fuerte que se aplana no es un fallo: es la ley de
  Amdahl, y el punto donde se aplana **es** el resultado útil, porque marca el número de nodos
  a partir del cual pedir más es desperdiciar cuota.
- **Un solo nodo primero.** Antes de escalar, se comprueba que el código usa bien un nodo:
  vectorización, memoria, hilos. Escalar código ineficiente multiplica el desperdicio.
- **Híbrido MPI+OpenMP**: reduce rangos y comunicación, pero exige colocar hilos por nodo NUMA.
  Se justifica con medida, no por defecto.

### 3.4 Entorno de software

- **El usuario no compila sus dependencias a mano.** Se le da un stack construido con Spack o
  EasyBuild y expuesto por Lmod. Lo contrario es un clúster con doce versiones de la misma
  biblioteca y ningún resultado reproducible.
- **Los módulos se versionan explícitamente.** `module load fftw` sin versión hace que el
  trabajo de la semana que viene use otra biblioteca sin avisar. En un script de trabajo, la
  versión va escrita.
- **El entorno del trabajo se declara dentro del script**, no se hereda del intérprete del
  usuario. Heredar `~/.bashrc` es la causa habitual de "en mi sesión funciona y en la cola no".
- **Contenedores en HPC: Apptainer**, y la razón es de modelo de privilegios. Docker exige un
  demonio con privilegios de root y coloca al usuario en un grupo equivalente a root en el
  nodo; en una máquina multiusuario compartida eso es inaceptable. Apptainer ejecuta la imagen
  **como el usuario que la lanza**, sin demonio, con el sistema de ficheros paralelo y la red
  del nodo visibles, y con la imagen como **un único fichero `.sif`** — que además es
  amable con el sistema de ficheros paralelo, al revés que un árbol de capas.
  - **Nota de nombre y gobernanza, verificada**: el proyecto se llamaba **Singularity** y pasó a
    llamarse **Apptainer** al entrar en la **Linux Foundation**; existe en paralelo un producto
    comercial homónimo de otra empresa. Al citar documentación hay que mirar **cuál** de los dos
    es. Licencia leída en crudo: **BSD-3-Clause**.
  - El contenedor **no exime de nada**: la imagen se versiona, se firma o se verifica por
    resumen, y se declara en el trabajo. Un `.sif` sin procedencia es un binario opaco corriendo
    con los datos del usuario.

### 3.5 Almacenamiento: home, scratch y archivo

Tres niveles con propósitos distintos, y **confundirlos es el origen de la mayoría de los
incidentes de datos del dominio**:

| Nivel | Para qué | Cuota | Respaldo | Rendimiento |
|---|---|---|---|---|
| `home` | Código, scripts, configuración | Pequeña y estricta | **Sí** | Modesto |
| `scratch` (paralelo) | Datos de trabajos en ejecución | Grande | **No** | Máximo |
| `archivo` / objeto / cinta | Resultados que hay que conservar | Grande | Sí, y es su razón de ser | Lento, latencia alta |

- **La política de purga es obligatoria, y se anuncia.** El `scratch` se purga por antigüedad
  de acceso (típicamente semanas). Sin purga, el `scratch` se llena, y un `scratch` lleno para
  el clúster entero, no a un usuario.
- **La purga se comunica antes, se avisa individualmente y se aplica sin excepción.** Las
  excepciones informales son cómo un sistema de purga deja de funcionar.
- **El `scratch` no se respalda, y eso se dice por escrito** en la documentación del servicio y
  en la incorporación de cada usuario. Un usuario que pierde tres meses de resultados porque
  creía que había copia es un fallo de comunicación del servicio, no del usuario.
- **Cuotas por proyecto además de por usuario**, en espacio **y en número de inodos**. La cuota
  de inodos es la que frena de verdad el problema del fichero pequeño (§2.3).
- ***Checkpointing*** de la aplicación: los trabajos largos escriben estado periódicamente y
  saben reanudar. Es lo que convierte un fallo de nodo en una hora perdida y no en una semana,
  y lo que permite tiempos límite de partición cortos y sanos.

### 3.6 GPU en el clúster

- **La GPU es un recurso planificable y contabilizado**, igual que la CPU y la memoria: se
  pide en el trabajo, se aísla por *cgroup* y **se contabiliza como TRES** para que entre en
  el *fairshare*. Un clúster que no contabiliza GPU-hora reparte lo más caro que tiene sin
  ninguna política.
- **La utilización real se mide.** El patrón dominante es el trabajo que reserva 8 GPU y usa
  una al 20 %. Se instrumenta y se le devuelve el dato al usuario; si no, la ampliación
  siguiente compra hardware para desperdiciarlo igual.
- **Colas de GPU separadas** de las de CPU, con límites propios: son el recurso escaso y el
  caro. Todo lo demás sobre la GPU (driver, MIG, DCGM, XID, alimentación) es de
  `gpu-computing-standards`.

### 3.7 Medir el clúster con honestidad

- **HPL** (el *benchmark* del Top500) mide álgebra lineal densa con altísima intensidad
  aritmética y **casi ninguna** presión de memoria o de red respecto al cómputo. Es una prueba
  de aceptación válida de que la máquina rinde lo comprado, y **una predicción pésima** del
  rendimiento de una aplicación real.
- **HPCG** existe precisamente por esa divergencia: patrones dispersos, limitados por ancho de
  banda de memoria y por comunicación. Los sistemas suelen alcanzar en HPCG una fracción muy
  pequeña de su cifra de HPL, y **esa brecha es la información**: dice cuánto de la máquina
  comprada es alcanzable por código real. Consultar las listas vigentes antes de citar cifras
  (§8); el Top500 se publica dos veces al año (junio y noviembre).
- **La medida que decide es la aplicación del sitio**, con sus datos, en un conjunto de casos
  representativos. Se conserva como línea base y se repite tras cada cambio de compilador,
  MPI, driver o kernel.
- **Toda cifra se publica con condiciones**: nodos, exclusividad, versiones, afinidad, tamaño
  del problema, y si el sistema estaba en producción. Sin eso, no es un número, es una anécdota.

### 3.8 Multiusuario: aislamiento y dato sensible

- **Un clúster compartido es un entorno hostil por defecto.** Los usuarios ven la misma máquina,
  los mismos sistemas de ficheros y los mismos nodos.
- **Permisos por proyecto**: directorios de grupo con `setgid` y ACL, `umask` restrictiva por
  defecto. El `home` legible por todo el mundo es la fuga de datos más común y más aburrida
  del dominio.
- **Contención por trabajo con *cgroups***: CPU, memoria y dispositivos. Sin ella, un trabajo
  se lleva por delante a sus vecinos y no hay política de reparto que valga.
- **Los nodos de cálculo no salen a Internet** por defecto, y el acceso a un nodo se concede
  **solo** mientras el usuario tiene un trabajo asignado en él.
- **Nada de credenciales compartidas ni cuentas de grupo.** La identidad es individual porque
  la contabilidad y la traza dependen de ella.
- **Dato sensible (personal, sanitario, clasificado) en un clúster compartido**: no se mete "y
  ya se verá". Exige decisión previa — partición o clúster segregado, cifrado en reposo,
  restricción de nodos, control de exportación y registro de acceso — y coordinación con
  `privacy-engineering-standards` y `grc-compliance-standards`. Un `scratch` compartido y sin
  respaldo es el peor sitio posible para un dato regulado.
- **Superficie propia del dominio**: el planificador ejecuta código de usuario en cientos de
  nodos con su propio demonio privilegiado. Los CVE de Slurm son de riesgo alto por diseño; el
  parcheo del planificador se trata como el de un servicio expuesto, no como el de una utilidad
  interna (`vulnerability-management-standards`).

## 4. Calidad y operación del servicio

- **Prueba de aceptación del clúster antes de abrirlo**: HPL o equivalente a plena carga (que
  además valida energía y refrigeración de la sala), verificación de la red de cómputo extremo a
  extremo, prueba de caudal y de metadatos del sistema paralelo, y una aplicación real.
- **Comprobación de salud del nodo** integrada en el planificador: antes y después de cada
  trabajo se verifica memoria, sistemas de ficheros montados, temperatura y estado de la red
  y de los aceleradores. **Un nodo que falla se marca `DRAIN` automáticamente**, no se deja
  devolviendo resultados corruptos o lentos. Este es el control de calidad más rentable del
  dominio: sin él, un solo nodo enfermo contamina semanas de resultados.
- **Métricas que importan**: ocupación por partición, tiempo de espera en cola por QoS,
  trabajos fallidos por causa, eficiencia de CPU y de memoria por trabajo, utilización de GPU,
  caudal y **operaciones de metadatos** del sistema paralelo, nodos en `DRAIN`.
- **Portal o informe de uso por proyecto**: el consumo se le enseña a quien lo paga y a quien
  lo consume. Sin eso, la contabilidad es un fichero que nadie mira.
- **Documentación del servicio** con lo mínimo: cómo entrar, cómo lanzar, qué particiones hay,
  qué límites, dónde escribir, **qué se purga y cuándo**, y qué no se respalda. Es parte del
  producto.
- **Ventanas de mantenimiento anunciadas y con reserva del planificador**, no apagones a mano:
  se crea una reserva que drena la cola sin matar trabajos en curso.

## 5. Sostenibilidad a largo plazo y prohibiciones

**Cadencia**: Slurm sigue versiones `YY.MM` semestrales con ~18 meses de soporte — planificar
al menos una actualización mayor al año y **no acumular saltos por encima de la ventana de
actualización directa admitida**. El stack de software (Spack/EasyBuild) se reconstruye por
generaciones, con la generación anterior conviviendo un tiempo declarado. El sistema de
ficheros paralelo se actualiza con matriz de compatibilidad cliente/servidor y kernel
verificada — es la actualización más arriesgada del clúster.

**Deuda propia del dominio**: el clúster acumula módulos que nadie usa, datos que nadie
reclama y cuentas de gente que se fue hace tres años. Revisión anual de las tres cosas, con
fecha.

Prohibiciones:

- ❌ **Compilar o ejecutar cálculo en el nodo de login.** Y no basta con prohibirlo en la
  documentación: se limita con *cgroups*.
- ❌ **Clúster en producción sin `slurmdbd`** ni contabilidad. Sin ella no hay *fairshare*, ni
  informe, ni traza.
- ❌ **Particiones sin tiempo límite** o sin límites por asociación.
- ❌ **Nodos compartidos sin contención de CPU y memoria por *cgroup*.**
- ❌ **`scratch` sin política de purga**, o con purga anunciada y no aplicada.
- ❌ **Prometer o insinuar respaldo del `scratch`.** Se dice explícitamente que no lo hay.
- ❌ **Millones de ficheros pequeños sobre el sistema paralelo** como patrón aceptado; se
  empaqueta, y la cuota de inodos lo hace cumplir.
- ❌ **`module load` sin versión** en un script de trabajo.
- ❌ **Publicar una medida de escalabilidad sin declarar afinidad**, versiones, tamaño de
  problema y exclusividad del nodo.
- ❌ **Usar HPL como predicción del rendimiento de una aplicación real**, o citar una cifra de
  Top500/HPCG sin la lista y la fecha.
- ❌ **Docker con demonio privilegiado en nodos de cálculo compartidos.**
- ❌ **`-march=native` compilado en un nodo distinto del de ejecución** sin verificar que la
  arquitectura coincide.
- ❌ **Cuentas compartidas o credenciales de grupo.**
- ❌ **Meter dato personal o regulado en el `scratch` compartido** sin decisión previa de
  segregación y control.
- ❌ **Afirmar la licencia de Lustre, BeeGFS, Storage Scale, Slurm, Apptainer, Spack o OpenPBS
  de memoria.** Cuatro de ellas no son lo que la gente cree, y una cambió en 2026 (§2.3).
- ❌ **Presentar Kubernetes como sustituto de un planificador batch** sin haber resuelto
  explícitamente planificación en pandilla, *fairshare* y contabilidad.

## 6. Verificación web obligatoria

Antes de fijar cualquier dato de este documento:

1. **Slurm**: última versión y ventana de actualización directa admitida. Verificado en agosto
   de 2026: tags `v26.05.2` y `v25.11.7` en el repositorio; cadencia semestral `YY.MM` con
   soporte de 18 meses (confirmado en la hoja de ruta de SchedMD presentada en SC'25).
   **`schedmd.com/slurm-support/release-announcements/` redirige a GitHub Releases** — usar el
   feed Atom de tags, no el feed de releases ni una API sin autenticar.
2. **Licencias, leídas en crudo — resultado de esta verificación**:
   - Slurm: `COPYING` del repositorio → **GPL con excepción explícita de enlazado con OpenSSL**.
   - Apptainer: `LICENSE.md` → **BSD-3-Clause**, "Apptainer a Series of LF Projects LLC".
   - Lustre: `COPYING` → `SPDX-License-Identifier: GPL-2.0 WITH Linux-syscall-note` para los
     módulos de kernel; resto de componentes, licencias compatibles con GPL-2.0.
   - OpenPBS: `LICENSE` → **AGPL-3.0-or-later** (Altair). **No es GPL ni permisiva.**
   - Spack: **Apache-2.0 / MIT** dual. EasyBuild: **GPL-2.0**.
   - BeeGFS: `LICENSE.txt` remite al *BeeGFS License Agreement*; el texto en crudo se declara
     **"As of February, 2026"** y limita el uso de la edición Community a uso interno, con
     claves de licencia técnicas desde la versión 8. **No es software libre.** Re-verificar
     antes de cualquier despliegue: los términos cambiaron en 2026 y pueden volver a cambiar.
   - **Hueco declarado**: la licencia de **CephFS** se ha dado por conocida (LGPL) pero **no se
     ha leído en crudo en esta pasada**; léela antes de citarla.
   - **Hueco declarado**: **IBM Storage Scale** es propietario y sus métricas de licencia
     (capacidad frente a socket, ediciones) se han tomado de documentación de IBM, no de un
     contrato. Cualquier cifra de coste se pide a IBM o al distribuidor.
3. **Lmod**: **hueco declarado** — el fichero de licencia no se ha localizado en la ruta
   probada (`COPYRIGHT` en `master` devuelve 404). Léela en el repositorio de TACC antes de
   afirmarla.
4. **Nombres y gobernanza**: Apptainer ↔ Singularity (cambio de nombre al entrar en la Linux
   Foundation, más un producto comercial homónimo de otra empresa) y GPFS ↔ Spectrum Scale ↔
   **IBM Storage Scale**. Comprobar de cuál habla la documentación que se esté leyendo.
5. **Kubernetes para HPC**: ~~estado y licencia de Volcano y Kueue~~ — **hueco CERRADO**: están
   verificados en `kubernetes-standards` §6 (con su versión, API, gobernanza y licencia); usa
   aquella y re-verifica allí. **Sigue abierto**: las integraciones Slurm–Kubernetes (Slinky y
   equivalentes), que no se han verificado y se citan como opción a evaluar, no como
   recomendación.
6. **Versiones**: Open MPI (5.0.x observado), MPICH, Apptainer (1.5.x), Spack (1.2.x), Lustre
   (LTS **2.15.x**, rama de características **2.17.x**) — y la **matriz de compatibilidad de
   kernel y de cliente/servidor** del sistema de ficheros, que es la que rompe una migración.
7. **CVE del planificador y del sistema de ficheros**: triaje con CVSS + EPSS + **KEV**. Slurm
   ha tenido vulnerabilidades de escalada de alto impacto; se vigila activamente.
8. **Cifras**: Top500/HPCG se publican en junio y noviembre; toda cifra citada lleva lista y
   fecha. **Ninguna estimación de "eficiencia media de un clúster" o de "porcentaje de pico
   alcanzable" se escribe sin fuente y metodología.**

Si la web contradice este documento, **manda la web** y señala la discrepancia.
