---
name: robotics-ros-standards
description: Robotics with ROS 2, from workspace layout to machine safety. Use when working with package.xml and CMakeLists.txt using ament_cmake or ament_python, colcon build/test with --symlink-install and --packages-select, a src/ workspace and install/setup.bash overlay, rclcpp and rclpy nodes, lifecycle nodes and executors and callback groups, .msg/.srv/.action interfaces and rosidl generation, ros2 topic/node/param/service/bag/doctor CLI, launch.py and launch.xml files with parameter YAML, ROS_DOMAIN_ID and RMW_IMPLEMENTATION, DDS middleware (Fast DDS, Cyclone DDS, Connext) or rmw_zenoh, QoS reliability durability history and deadline mismatches where messages silently never arrive, tf2 transform trees and static_transform_publisher and TF_OLD_DATA or extrapolation errors, URDF and xacro and robot_state_publisher, Gazebo (Harmonic, Ionic, Jetty, Ignition or Gazebo Classic) and ros_gz_bridge, Nav2 behavior trees and costmaps, MoveIt 2 planning, ros2_control hardware interfaces and controller_manager, rosbag2 recording, real-time constraints with PREEMPT_RT and CPU isolation, SROS2 security enclaves and keystore, or ISO 10218 and ISO/TS 15066 machine safety obligations for an industrial or collaborative robot.
---

# Estándares de robótica con ROS 2

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Fija el criterio de ingeniería sobre **construir y operar un robot con ROS 2**: cómo se estructura el
espacio de trabajo, cómo se comunican los nodos y por qué a veces no lo hacen, qué exige el tiempo
real, qué se simula y con qué, cómo se asegura una red donde el tráfico mueve masa, y qué normas de
seguridad de máquina aplican antes de que el brazo se mueva con alguien delante.

**Dato duro que va primero: ROS 1 está muerto.** Verbatim de REP-3 (índice oficial de distribuciones
de ROS): **«Noetic Ninjemys (May 2020 - May 2025)»**. Noetic fue la **última** distribución de ROS 1
y su soporte terminó en **mayo de 2025**; no hay parches, no hay paquetes binarios nuevos, no hay
correcciones de seguridad. **Un proyecto que arranca hoy sobre ROS 1 arranca sin mantenimiento y sin
salida**, y uno que ya está sobre ROS 1 tiene una migración pendiente, no una decisión pendiente.
`ros1_bridge` sirve para migrar por partes, no para quedarse.

**Segundo eje: en ROS 2 el middleware es parte del diseño, no un detalle.** ROS 2 no transporta
mensajes por sí mismo: delega en DDS (o en Zenoh) a través de una capa RMW. De ahí sale la patología
número uno del dominio —**"publico y el otro nodo no recibe nada, y no hay ningún error"**— que casi
nunca es un bug: es **QoS incompatible**, o un `ROS_DOMAIN_ID` distinto, o multidifusión bloqueada
por la red. **El silencio es el modo de fallo por defecto de este sistema**, y por eso la QoS y el
descubrimiento se diseñan y se documentan como cualquier otro contrato.

**Tercer eje: aquí un fallo mueve masa.** Un desbordamiento en una web devuelve un 500; en un brazo
de 30 kg a 2 m/s es una lesión. Eso cambia el listón de todo lo demás: seguridad de red, control de
cambios, pruebas antes de tocar hardware y normativa de seguridad de máquina (§5, §6).

Triggers: `package.xml`, `CMakeLists.txt` con `ament_cmake`, `setup.py` con `ament_python`,
`colcon build`, `install/setup.bash`, `src/` con múltiples paquetes, `rclcpp::Node`,
`rclpy.node.Node`, `create_publisher`/`create_subscription`, `.msg`/`.srv`/`.action`,
`ros2 topic echo`, `ros2 doctor`, `ros2 bag record`, `*.launch.py`, `ros__parameters` en YAML,
`ROS_DOMAIN_ID`, `RMW_IMPLEMENTATION`, `rmw_fastrtps_cpp`, `rmw_cyclonedds_cpp`, `rmw_zenoh_cpp`,
`tf2_ros`, `TransformListener`, `static_transform_publisher`, "extrapolation into the future",
`urdf`/`xacro`, `robot_state_publisher`, `ros_gz_bridge`, `controller_manager`, `nav2_bringup`,
`move_group`, `sros2`, `--enclave`, y los síntomas: "el tópico está pero no llega nada", "va bien en
simulación y mal en el robot", "se cae la comunicación por wifi", "TF_OLD_DATA".

**No aplica**: ver `embedded-iot-standards` (**el microcontrolador y el firmware son suyos, sin
excepción**: MCU, arranque, particionado, watchdog, energía, actualización OTA del dispositivo,
identidad de hardware. **Frontera operativa**: si el código corre en un MCU sin sistema operativo
completo —incluido `micro-ROS` sobre un MCU—, **el firmware es suyo y aquí solo queda el contrato de
mensajes y la QoS del enlace**; si corre en un SBC/PC con Linux y `rclcpp`/`rclpy`, es de aquí),
`ot-ics-security-standards` (**la planta industrial es suya, sin excepción**: modelo Purdue/ISA-95,
zonas y conductos de IEC 62443, PLC/DCS/SCADA/SIS, protocolos de campo, monitorización pasiva,
ventana de parada. **Frontera**: un robot en una celda de producción **se diseña bajo esta skill y
se gobierna bajo la suya** — la segmentación, la política de acceso remoto del fabricante y el
gobierno del riesgo de proceso son de allí; el nodo, la QoS, TF y el control, de aquí),
`computer-vision-standards` (**percepción: SLAM, detección, segmentación, calibración de cámara,
etiquetado y evaluación son suyos**; aquí solo **consumir** el resultado en un tópico y su
temporización), `deep-learning-standards` y `model-finetuning-standards` (entrenar redes;
aprendizaje por refuerzo y política aprendida se diseñan allí y se **despliegan** con las reglas de
aquí), `local-inference-standards` (servir el modelo en el robot: motor, cuantización, memoria),
`gpu-computing-standards` (la GPU embebida como recurso: driver, reparto, toolchain),
`edge-computing-standards` (**el nodo de borde y la flota como sistema distribuido son suyos**:
orquestación remota, sincronización, despliegue sobre muchos aparatos; **aquí el robot como
sistema**), `linux-administration-standards` y `linux-hardening-standards` (el sistema operativo, su
hardening y `systemd`; **aquí solo lo específico**: `PREEMPT_RT`, aislamiento de CPU y prioridades),
`networking-standards` y `wireless-standards` (diseño de red, VLAN, y **el wifi como medio**: la
itinerancia y la pérdida de paquetes son suyas; aquí sus consecuencias en QoS y en descubrimiento),
`cpp-standards` y `c-standards` (el lenguaje: UB, RAII, sanitizers, MISRA/CERT), `python-standards`
(el Python fuera de `ament_python`), `cicd-standards` (pipeline y gates), `observability-standards`
(pipeline OTel y backend; aquí `rosbag2`, `/rosout` y los diagnósticos), `mlops-standards` (ciclo de
vida del modelo), `game-development-standards` y `xr-standards` (**lote 22**: motor de juego,
presupuesto de fotograma y teleoperación inmersiva — un visor para pilotar un robot es un cliente,
**el robot sigue siendo de aquí**), `functional-safety` como disciplina formal (**no existe en el
catálogo**: esta skill fija el criterio de ingeniería y las normas aplicables, **no sustituye a un
evaluador de seguridad funcional**).

## 2. Decisiones por defecto / Toolchain

> Verificar la distribución vigente, su EOL y el estado de las normas por web antes de fijarlas en un
> proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| Versión de ROS | **ROS 2 LTS** | — | ROS 1 sin soporte desde may-2025 |
| Distribución | **Lyrical Luth (LTS, EOL may-2031)** | Jazzy (EOL may-2029) si el ecosistema no ha migrado | Vida útil del robot |
| Distribución no-LTS | **No en producto** | Prototipo y I+D | 1,5 años de soporte |
| RMW | **El por defecto de la distro** (`rmw_fastrtps_cpp`) | Cyclone DDS; `rmw_zenoh_cpp` con enlace malo o WAN | Soporte Tier 1 y paquetes probados |
| Build | **`colcon` + `ament_cmake`/`ament_python`** | — | Es la cadena soportada |
| Lenguaje de nodo | **C++ (`rclcpp`)** en el lazo de control; Python (`rclpy`) en orquestación y herramientas | — | GIL y latencia no determinista |
| Nodos con estado | **Lifecycle nodes** (`rclcpp_lifecycle`) | Nodo simple en utilidades | Arranque y parada gobernables |
| Simulación | **Gazebo (Jetty LTS o Harmonic LTS)** | Isaac Sim / Webots / MuJoCo por caso | Integración `ros_gz` |
| Control | **`ros2_control`** | Controlador propio con ADR | Interfaces de hardware reutilizables |
| Navegación / manipulación | **Nav2** / **MoveIt 2** | Propio solo con requisito imposible | Coste de reimplementar |
| Tiempo real | `PREEMPT_RT` + aislamiento de CPU **para el lazo**, no para todo | Lazo en MCU/FPGA aparte | ROS 2 no es tiempo real duro §6 |
| Seguridad de red | **SROS2 activado desde el diseño** | Aislamiento físico documentado | DDS va en claro por defecto §5 |

**Calendario verificado de ROS 2** (fuente: `Releases.rst` de `ros2_documentation`, leído en crudo,
ago-2026):

| Distro | Publicación | EOL | Tipo |
|---|---|---|---|
| **Lyrical Luth** | 22-may-2026 | **may-2031** | **LTS** |
| Kilted Kaiju | 23-may-2025 | dic-2026 | no-LTS |
| **Jazzy Jalisco** | 23-may-2024 | **may-2029** | **LTS** |
| Iron Irwini | 23-may-2023 | 4-dic-2024 | EOL |
| **Humble Hawksbill** | 23-may-2022 | **may-2027** | LTS, **caduca en 9 meses** |

Plataforma y lenguajes de Lyrical, verificados en su página de plataformas soportadas: **Ubuntu
Resolute (26.04) Tier 1** en amd64 y arm64 (Ubuntu Noble en Tier 3, con EOL adelantado a
**2029-06-01**), **C++20**, **C17**, **Python 3.12–3.14**, **Gazebo Jetty** como dependencia, y
—verbatim— *«The default middleware in ROS Lyrical is rmw_fastrtps_cpp»*. `rmw_zenoh_cpp` entró
como **Tier 1** ya en Kilted (REP-2000). REP-2000 fija además el ritmo: *«New ROS 2 releases will be
published in a time based fashion every 12 months»*, LTS **5 años**, no-LTS **1,5 años**.

**Gazebo — el lío de nombres, aclarado con fechas verificadas.** Hubo tres cosas distintas llamadas
casi igual: **Gazebo Classic** (`gazebo11`, el de siempre), **Ignition Gazebo** (la reescritura) y
**Gazebo** (el nombre actual de la reescritura, tras devolverle el nombre en 2022; las versiones se
nombran por letra: Fortress, Garden, Harmonic, Ionic, Jetty…). Estado verificado:

- **Gazebo Classic**: verbatim de `classic.gazebosim.org` — *«This version of Gazebo, now called
  Gazebo classic, reaches end-of-life in January 2025»*, con fecha exacta *«end-of-life on January
  29, 2025»*. **Muerto. No se empieza nada nuevo con él y lo existente se migra.**
- **Gazebo (nuevo)**, según la tabla oficial de releases: **Jetty** sep-2025 → **may-2031 (LTS)**;
  **Ionic** sep-2024 → dic-2026; **Harmonic** sep-2023 → **may-2029 (LTS)**; **Fortress** sep-2021 →
  may-2027 (LTS); **Garden** EOL nov-2024.
- Regla práctica: **elegir la pareja distro-ROS ↔ versión de Gazebo que el propio REP/plataforma
  declara** (Lyrical→Jetty, Jazzy→Harmonic) y no mezclar. El puente es `ros_gz`.

## 3. Estructura y convenciones

**Espacio de trabajo.** Un `src/` con paquetes pequeños y de responsabilidad única; nunca un
mega-paquete con todo dentro. Separar por naturaleza, porque de eso depende poder reutilizar y poder
probar:

```
ws/src/
  mi_robot_msgs/        # SOLO interfaces .msg/.srv/.action  (cambian poco, rompen mucho)
  mi_robot_description/ # URDF/xacro, mallas, ros2_control tags
  mi_robot_bringup/     # launch + parámetros YAML por entorno (sim / robot / laboratorio)
  mi_robot_control/     # nodos de control (C++), sin dependencias de simulación
  mi_robot_perception/  # nodos que consumen sensores
  mi_robot_bt/          # árboles de comportamiento / lógica de misión
```

- **Las interfaces van en su propio paquete**: cualquiera que las use no arrastra tus dependencias, y
  su versionado es visible. **Cambiar un `.msg` publicado es un cambio incompatible**: se añade
  campo, no se reordena ni se reinterpreta; si hay que romper, se crea un tipo nuevo y se migra.
- **`colcon build --symlink-install`** en desarrollo; en CI y en el robot, build limpio. **Un solo
  *overlay* activo**: encadenar tres `setup.bash` de tres workspaces es la causa clásica de "ejecuta
  una versión antigua del nodo y no me explico por qué". `ros2 doctor` y `ros2 pkg prefix` antes de
  culpar al código.
- **Nada de rutas absolutas ni de `~/ws/...` en el código**: `ament_index` y `$(find-pkg-share ...)`.

**Parámetros y launch.** Todo lo configurable es **parámetro declarado** (con descriptor, rango y
valor por defecto), cargado desde YAML por entorno, nunca constante escondida ni variable de entorno
ad hoc. Los `launch` describen composición y nada más: sin lógica de negocio dentro. Para latencia,
**componer nodos en un mismo proceso** (composición de componentes) evita serialización y copia
—vale más que cualquier micro-optimización del nodo—.

**QoS — el contrato que nadie escribe y todo el mundo rompe.** Verbatim de la documentación oficial:
*«A connection between a publisher and a subscription is only made if the pair has compatible QoS
profiles»*, bajo modelo **«Request vs Offered»**: *«Subscriptions request a QoS profile that is the
"minimum quality" that it is willing to accept, and publishers offer a QoS profile that is the
"maximum quality" that it is able to provide»*. Las dos tablas que explican el 90 % de los
"mensajes que no llegan":

| Fiabilidad: publicador → suscriptor | ¿Compatible? |
|---|---|
| Best effort → Best effort | Sí |
| **Best effort → Reliable** | **No** |
| Reliable → Best effort | Sí |
| Reliable → Reliable | Sí |

| Durabilidad: publicador → suscriptor | ¿Compatible? | Resultado |
|---|---|---|
| Volatile → Volatile | Sí | Solo mensajes nuevos |
| **Volatile → Transient local** | **No** | **Sin comunicación** |
| Transient local → Volatile | Sí | Solo mensajes nuevos |
| Transient local → Transient local | Sí | Nuevos y antiguos |

Y el detalle que se paga caro: *«To achieve a "latched" topic that is visible to late subscribers,
both the publisher and subscriber must agree to use 'Transient Local'»* — el equivalente al *latched*
de ROS 1 exige **acuerdo en los dos extremos** (mapa, descripción del robot, configuración estática).
Los valores por defecto, también verbatim: *«By default, publishers and subscriptions in ROS 2 have
"keep last" for history with a queue size of 10, "reliable" for reliability, "volatile" for
durability»*; el perfil de **sensor data** usa *best effort* y cola pequeña, y los **servicios** son
fiables y **volátiles a propósito** —*«otherwise service servers that re-start may receive outdated
requests»*—. Reglas de la casa:

- **La QoS de cada tópico se declara en la documentación del paquete**, junto al tipo. Es parte de la
  interfaz.
- **Sensores de alta frecuencia → sensor data** (best effort, cola corta). **Mapas, TF estático,
  descripción del robot y estado de configuración → transient local en ambos extremos.** Comandos de
  actuación → reliable, cola 1 (no interesa un comando viejo).
- **`deadline` y `liveliness`** no son adorno: son la forma estándar de enterarse de que un nodo dejó
  de publicar. En un lazo de seguridad, el temporizador de vigilancia va aquí, no en un `if`.
- Ante "no llega nada": comprobar en este orden **`ROS_DOMAIN_ID` → misma red y multidifusión →
  `ros2 topic info -v` (perfiles de ambos extremos) → tipo de mensaje → *namespace*/remapeo**.

**TF2 — el árbol de transformadas.** Reglas que evitan casi todos sus fallos:

- **Un único padre por marco y un solo árbol conectado**: dos publicadores del mismo par
  padre→hijo es un error de diseño (el clásico: `odom→base_link` publicado por dos nodos).
- Convención de nombres y jerarquía estándar (`map` → `odom` → `base_link` → sensores; REP-105) y
  ejes según REP-103 (metros, radianes, x adelante, y izquierda, z arriba). Salirse cuesta
  integración con todo el ecosistema.
- **Todo dato lleva marca de tiempo del sensor, no del reloj de recepción.** Los errores de
  extrapolación y `TF_OLD_DATA` son casi siempre relojes sin sincronizar entre máquinas (NTP/PTP
  obligatorio en robots multi-computador) o *timestamps* rellenados con `now()`.
- Transformadas **fijas** con `static_transform_publisher` / `tf2_ros::StaticTransformBroadcaster`
  (que usan *transient local*), nunca republicadas a 100 Hz.
- **En simulación, `use_sim_time` a `true` en todos los nodos.** Uno solo con el reloj de pared
  desincroniza el árbol entero.

## 4. Calidad y testing

- **Pirámide adaptada al robot**: (1) tests unitarios de la lógica **separada del nodo** —extraer el
  algoritmo a una clase sin `rclcpp` es la decisión de diseño que más test permite—; (2) tests de
  nodo con `launch_testing` (arranque, parámetros, publicación esperada, QoS declarada); (3)
  **reproducción de `rosbag2`** grabado del robot real contra la versión nueva, comparando salidas;
  (4) simulación con escenarios; (5) banco de pruebas con el hardware; (6) robot en su entorno.
- **`rosbag2` es la herramienta de regresión del dominio**: cada incidente de campo deja un *bag*
  recortado y un test que lo reproduce. Sin eso, cada fallo se investiga desde cero.
- **La simulación miente y hay que saber en qué**: fricción, holguras, ruido de sensor, latencia de
  bus, deriva térmica y tiempos de CPU. Sirve para lógica, integración y casos peligrosos; **no
  valida tiempos ni tolerancias mecánicas**. "Funciona en Gazebo" no es un criterio de aceptación.
- **Gates de CI en orden de coste**: formateo y linters de `ament` (`ament_cpplint`,
  `ament_clang_format`, `ament_flake8`, `ament_mypy`, `ament_copyright`) → build con warnings como
  error → tests unitarios → `launch_testing` → reproducción de bags de referencia → simulación
  automatizada → despliegue a banco. **`main` verde o no se toca el robot.**
- **Análisis dinámico en el nodo de control**: ASan/UBSan/TSan en CI (`cpp-standards`); una condición
  de carrera en un lazo de control se manifiesta en movimiento.
- **Determinismo de arranque**: probar el orden de arranque desordenado —nodo que arranca antes que
  su fuente, TF incompleto, parámetro ausente—. Un sistema que solo funciona si todo arranca en el
  orden bonito falla en el primer reinicio de campo.
- **Prueba de red degradada obligatoria** si hay wifi: pérdida de paquetes, latencia y corte total.
  Comprobar qué hace el robot cuando se queda sin operador: **parar es la respuesta correcta por
  defecto**.

## 5. Seguridad del stack

**El hecho fundacional, verbatim de la documentación de diseño oficial de ROS 2
(`design.ros2.org`, artículo *ROS 2 DDS-Security integration*):**

> ***«By default, none of the security features of DDS are enabled in ROS 2.»***

Traducido: **sin `sros2` configurado, el tráfico de ROS 2 viaja sin autenticación, sin autorización y
sin cifrado**. Cualquier máquina con acceso a la red y el mismo `ROS_DOMAIN_ID` puede **descubrir
todos los tópicos, leerlos, publicar comandos de actuación, cambiar parámetros y llamar servicios**.
No hay contraseña que romper porque no hay contraseña. **En un robot, eso no es una fuga de datos:
es control físico del aparato en manos de cualquiera que llegue a la red.**

- **Un robot en una red plana es un riesgo de seguridad física**, no de TI. La primera medida es
  arquitectónica: segmento propio, sin ruta hacia (ni desde) la ofimática, sin wifi de invitados,
  acceso remoto solo por bastión y con autenticación fuerte. La red y el gobierno de esa zona son de
  `ot-ics-security-standards` y `networking-standards`; **la obligación de exigirlo es de aquí**.
- **`ROS_DOMAIN_ID` no es seguridad.** Es un separador de tráfico: cualquiera puede fijarlo. Tampoco
  lo es "está detrás del NAT" ni "es una VLAN".
- **SROS2** habilita DDS-Security: CA de identidad y de permisos, certificados X.509 por *enclave*,
  fichero de gobernanza que —verbatim del mismo documento— *«will encrypt all DDS traffic by
  default»*, y permisos expresados en términos de ROS (qué nodo puede publicar/suscribirse a qué).
  **Su coste es real y hay que presupuestarlo**: una PKI que alguien tiene que operar (emisión,
  distribución, caducidad, **revocación y rotación**), sobrecarga de CPU y de latencia en el cifrado
  y la firma, complejidad de despliegue y de depuración, y un fallo de configuración que se
  manifiesta —cómo no— **como silencio**. Se activa **desde el diseño**, no al final: retrofit de
  seguridad en un sistema de 40 nodos es un proyecto.
- **Mínimo privilegio real**: un *enclave* por nodo o por grupo funcional, con permisos explícitos de
  lectura/escritura por tópico. Un único enclave para todo el robot es cifrado sin autorización.
- **Superficie que no cubre DDS-Security**: interfaces de operador (web, `rosbridge`,
  `web_video_server`, Foxglove) **expuestas sin autenticación** —son un mando a distancia—; `rosbag2`
  con datos personales (vídeo del entorno, caras, matrículas: `privacy-engineering-standards`);
  actualización del software del robot sin firma ni verificación de origen; credenciales de nube en
  la imagen; y **puertos de depuración y consolas serie** accesibles en la máquina.
- **Cadena de suministro**: los paquetes de terceros de `rosdistro`, los drivers del fabricante y los
  modelos descargados son código que corre con permiso de mover el robot. Fijar versiones, revisar
  licencias (`opensource-licensing-standards`) y no instalar desde fuentes no verificadas.
- **Registro y trazabilidad**: quién habilitó el modo manual, quién cambió un parámetro de velocidad,
  quién anuló un límite. En un incidente con lesión, **eso es la prueba**.

## 6. Rendimiento y operabilidad

**Tiempo real: dónde está el límite, dicho sin ambigüedad.** **ROS 2 no es un sistema de tiempo real
duro por sí solo.** Que use DDS y tenga *executors* configurables no lo convierte en determinista:
sigue habiendo asignación dinámica de memoria, planificación del sistema operativo, GIL en `rclpy`,
copias en el transporte, descubrimiento en segundo plano y un núcleo Linux estándar que no garantiza
latencia. Lo que **sí** se puede construir:

- **Núcleo con `PREEMPT_RT`**: el parche de tiempo real **se fusionó en el núcleo Linux 6.12**
  (publicado el **17-nov-2024**), tras dos décadas fuera del árbol —verificado en el resumen oficial
  de la versión—. Deja de ser un parche externo, pero **sigue habiendo que compilarlo/activarlo y,
  sobre todo, ajustar el sistema entero**.
- **Aislamiento**: `isolcpus`/`cpuset` para el lazo de control, IRQ fuera de esos núcleos, gobernador
  de frecuencia fijo, sin ahorro de energía, sin *hyperthreading* compartido, **memoria bloqueada
  (`mlockall`) y sin asignaciones en el lazo**, prioridades `SCHED_FIFO` bien elegidas.
- **Medir, no suponer**: `cyclictest` para la latencia del núcleo y medición de *jitter* del lazo en
  el robot real, durante horas y con carga (percepción, red, disco). **La latencia media no importa:
  importa el peor caso.**
- **El límite honesto**: cuando el requisito es de seguridad y de microsegundos —parada de
  emergencia, lazo de corriente, límite de par—, **eso no vive en ROS 2**. Vive en el controlador del
  robot, en un MCU/FPGA o en un relé de seguridad certificado, y ROS 2 le habla desde fuera. **Un
  paro de emergencia implementado como un nodo de ROS 2 es un fallo de diseño de seguridad**, no una
  optimización pendiente.

**Operabilidad:**

- **Diagnósticos** (`diagnostic_updater`/`diagnostic_aggregator`) para cada subsistema, con estado
  legible por un operador, no solo por un desarrollador. `/rosout` estructurado y con nivel
  correcto; **nada de `INFO` a 100 Hz** (llena el disco y la CPU).
- **Métricas**: frecuencia real de cada tópico crítico frente a la esperada, latencia extremo a
  extremo, tiempo de ciclo del lazo (p99), mensajes perdidos, uso de CPU por nodo, temperatura,
  batería. Exportar al backend de `observability-standards`.
- **Grabación permanente en anillo** con `rosbag2` (tamaño acotado, con rotación) para tener el
  "antes" de cualquier incidente; con política de retención y de datos personales.
- **Arranque supervisado**: `systemd` con reinicio controlado, dependencias explícitas, y **estado
  seguro al arrancar** (frenos puestos, potencia de actuadores desactivada hasta habilitación
  explícita).
- **Degradación**: pérdida de sensor, de red o de operador → **estado seguro definido**, no
  "continuar con el último valor conocido". Cada nodo declara qué hace cuando su entrada envejece
  (para eso está `deadline`).
- **Actualización de campo**: imagen versionada, despliegue con vuelta atrás probada, y **nunca
  actualizar con el robot habilitado**. La ventana de mantenimiento se acuerda con quien opera.

**Seguridad de máquina (normativa) — estado verificado, y es un cambio grande de 2025:**

- **ISO 10218-1:2025** (robots industriales) e **ISO 10218-2:2025** (aplicaciones y celdas) se
  publicaron en **febrero de 2025** y sustituyen a las versiones de 2011. **ISO/TS 15066 deja de ser
  una especificación técnica aparte: su contenido —colaboración por limitación de potencia y fuerza
  (PFL), monitorización de velocidad y separación (SSM), guiado manual (HGC), y los límites de fuerza
  y presión— se ha incorporado a ISO 10218-2.** La nueva serie introduce además **dos clases de
  robot** (Clase 1 para robots muy débiles sin riesgo significativo, con requisitos de control
  reducidos; Clase 2 para el resto), abandona el nivel de prestaciones único PL d/cat. 3 en favor de
  un **PL por función de seguridad** (con opción de desviarse mediante evaluación de riesgos
  ampliada), exige una función de **parada normal** distinta de la de emergencia, e incorpora por
  primera vez **requisitos de ciberseguridad** en tanto afecten a la seguridad.
- **Terminología**: la nueva serie habla de **"aplicación colaborativa"**, no de "robot
  colaborativo": lo que se evalúa y se valida es **el uso concreto** —robot + herramienta + pieza +
  entorno + tarea—, no el aparato. Comprar un "cobot" **no** exime de evaluación de riesgos.
- **Marco legal en la UE**: el **Reglamento (UE) 2023/1230 de máquinas** sustituye a la Directiva
  2006/42/CE; verbatim de EUR-Lex: *«It shall apply from 14 January 2027»* y *«Directive 2006/42/EC
  is repealed with effect from 14 January 2027»*. **Fecha de planificación, no de sorpresa.**
- **Presunción de conformidad**: la citación de EN ISO 10218-1/-2 en el Diario Oficial de la UE
  estaba pendiente en el momento de la verificación (con un periodo transitorio de 24 meses
  solicitado). **Verificar el estado antes de apoyar un expediente técnico en ello (§8).**
- **Lo que esta skill no hace**: no sustituye la evaluación de riesgos, ni el cálculo de PL/SIL
  (ISO 13849-1 / IEC 62061), ni al organismo o evaluador correspondiente. Fija que **existe la
  obligación** y que se planifica desde el principio, no antes de entregar.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: producto sobre **LTS**, con salto planificado antes del EOL (Humble caduca en
  **may-2027**: si hay flota sobre Humble, la migración a Jazzy o Lyrical es trabajo de este año, no
  del año que viene). Las no-LTS solo para prototipo.
- **Migración como práctica continua**: probar contra `rolling` en un job de CI *no bloqueante* para
  enterarse pronto de las rupturas, en vez de descubrirlas todas juntas en el salto.
- **Vida del robot > vida de la distro**: un aparato industrial dura 10–15 años y ninguna distro de
  ROS 2 dura tanto. **Se planifica la migración desde el diseño**: dependencias acotadas, capa de
  abstracción sobre lo que cambia y capacidad de actualizar en campo. Si el robot no se puede
  actualizar, se está firmando su obsolescencia.
- **Documentar en ADR**: distribución y motivo, RMW elegido, perfiles de QoS por tópico, estrategia
  de tiempo real y dónde está la frontera de seguridad, decisión sobre SROS2, simulador y versión.

**Prohibiciones explícitas:**

- ❌ **Empezar un proyecto nuevo en ROS 1** o mantener uno "porque funciona": Noetic terminó en
  **mayo de 2025** y no recibe parches de seguridad.
- ❌ Ejecutar ROS 2 **sin SROS2 en una red a la que llegue algo más que el robot**, o creer que
  `ROS_DOMAIN_ID`, la VLAN o el NAT son seguridad.
- ❌ Exponer `rosbridge`, `web_video_server`, Foxglove o cualquier interfaz de teleoperación **sin
  autenticación**.
- ❌ **Implementar el paro de emergencia, el límite de par o el enclavamiento de seguridad como nodos
  de ROS 2.** La función de seguridad va en hardware/controlador certificado.
- ❌ Prometer "tiempo real" por usar ROS 2, o por instalar `PREEMPT_RT` sin aislar CPU, sin fijar
  prioridades, sin `mlockall` y **sin medir el peor caso**.
- ❌ Lógica de control en `rclpy` dentro del lazo caliente; asignar memoria, hacer E/S o esperar
  bloqueos dentro de un *callback* de control.
- ❌ Publicar TF del mismo par padre→hijo desde dos nodos, o usar `now()` como marca de tiempo de un
  dato de sensor.
- ❌ Usar QoS por defecto para todo y depurar a base de reiniciar; o declarar un tópico "latched" sin
  *transient local* **en ambos extremos**.
- ❌ Encadenar *overlays* de workspaces y depurar el binario equivocado.
- ❌ Cambiar un mensaje publicado (reordenar campos, reinterpretar unidades) sin tipo nuevo y ruta de
  migración.
- ❌ Validar solo en simulación y llamarlo listo; o probar el primer movimiento a velocidad de
  producción con personas cerca.
- ❌ Empezar nada nuevo sobre **Gazebo Classic** (EOL 29-ene-2025) o mezclar versiones de Gazebo con
  la distro que no le corresponde.
- ❌ Tratar la seguridad de máquina (ISO 10218 / Reglamento de máquinas) como papeleo del final. Es
  requisito de diseño con fecha: **14 de enero de 2027**.
- ❌ `INFO`/`DEBUG` a frecuencia de sensor en producción.

## 8. Verificación web obligatoria

Antes de decidir, comprobar en la fuente primaria:

1. **Distribución vigente y EOL**: `docs.ros.org` (página *Releases*/*Distributions*) y **REP-2000**
   —ojo: el REP en `master` **aún no listaba Lyrical** cuando se verificó este documento, mientras la
   documentación sí; **manda la documentación de la distro**. Verificado: Lyrical Luth 22-may-2026 →
   **may-2031 (LTS)**; Jazzy → may-2029; Humble → **may-2027**; Kilted → dic-2026.
2. **Plataforma y dependencias** de la distro elegida en su página de *Supported Platforms* (Ubuntu,
   C++/Python mínimos, RMW por defecto, versión de Gazebo). Verificado para Lyrical: Ubuntu Resolute
   26.04, C++20/C17, Python 3.12–3.14, `rmw_fastrtps_cpp`, Gazebo Jetty.
3. **REP-3** para confirmar que Noetic sigue siendo la última de ROS 1 y su EOL (verificado:
   *«Noetic Ninjemys (May 2020 - May 2025)»*).
4. **Gazebo**: tabla de releases y EOL en `gazebosim.org/docs/latest/releases/` (verificado: Jetty
   →may-2031, Ionic →dic-2026, Harmonic →may-2029, Fortress →may-2027) y el aviso de EOL de
   `classic.gazebosim.org` (verificado: **29-ene-2025**).
5. **Seguridad**: que la afirmación *«By default, none of the security features of DDS are enabled in
   ROS 2»* sigue vigente en `design.ros2.org` y en la documentación de `sros2`; avisos de seguridad
   de la implementación DDS usada (Fast DDS, Cyclone DDS, Connext) y del `rmw` correspondiente.
6. **Tiempo real**: estado de `PREEMPT_RT` en la versión de núcleo que se vaya a usar (verificado:
   fusionado en **Linux 6.12**, 17-nov-2024) y la guía de ajuste vigente.
7. **Normativa de seguridad de máquina**: estado de **ISO 10218-1/-2:2025**, de la absorción de
   **ISO/TS 15066** y —**crítico**— de su **citación en el DOUE** bajo el Reglamento (UE) 2023/1230,
   que estaba **pendiente** en la fecha de verificación. **Hueco declarado**: `iso.org` devuelve
   **HTTP 403** a acceso automatizado, así que el estado de las normas se verificó en fuente
   secundaria especializada; **el texto normativo hay que comprarlo y leerlo**, y las fechas de
   aplicación se contrastan en EUR-Lex (verificado allí: *«It shall apply from 14 January 2027»*).
8. **Nav2, MoveIt 2, `ros2_control` y drivers de fabricante**: qué distribuciones soportan hoy y con
   qué versión; suelen ir por detrás de la LTS recién publicada, **y eso puede decidir la distro**.
9. **CVEs** de la pila: núcleo, DDS, dependencias C++ y paquetes de `rosdistro` instalados.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
