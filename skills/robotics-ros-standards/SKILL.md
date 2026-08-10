---
name: robotics-ros-standards
description: Robotics with ROS 2, from workspace layout to machine safety. Use when working with package.xml and CMakeLists.txt using ament_cmake or ament_python, colcon build/test with --symlink-install and --packages-select, a src/ workspace and install/setup.bash overlay, rclcpp and rclpy nodes, lifecycle nodes and executors and callback groups, .msg/.srv/.action interfaces and rosidl generation, ros2 topic/node/param/service/bag/doctor CLI, launch.py and launch.xml files with parameter YAML, ROS_DOMAIN_ID and RMW_IMPLEMENTATION, DDS middleware (Fast DDS, Cyclone DDS, Connext) or rmw_zenoh, QoS reliability durability history and deadline mismatches where messages silently never arrive, tf2 transform trees and static_transform_publisher and TF_OLD_DATA or extrapolation errors, URDF and xacro and robot_state_publisher, Gazebo (Harmonic, Ionic, Jetty, Ignition or Gazebo Classic) and ros_gz_bridge, Nav2 behavior trees and costmaps, MoveIt 2 planning, ros2_control hardware interfaces and controller_manager, rosbag2 recording, real-time constraints with PREEMPT_RT and CPU isolation, SROS2 security enclaves and keystore, or ISO 10218 and ISO/TS 15066 machine safety obligations for an industrial or collaborative robot.
---

# ROS 2 robotics standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Sets the engineering criteria for **building and operating a robot with ROS 2**: how the workspace
is structured, how nodes communicate and why sometimes they do not, what real time demands, what
gets simulated and with what, how to secure a network where the traffic moves mass, and which
machine safety standards apply before the arm moves with someone standing in front of it.

**Hard fact that comes first: ROS 1 is dead.** Verbatim from REP-3 (the official index of ROS
distributions): **«Noetic Ninjemys (May 2020 - May 2025)»**. Noetic was the **last** ROS 1
distribution and its support ended in **May 2025**; there are no patches, no new binary packages, no
security fixes. **A project starting today on ROS 1 starts unmaintained and with no way out**, and
one already on ROS 1 has a pending migration, not a pending decision.
`ros1_bridge` is for migrating piece by piece, not for staying put.

**Second axis: in ROS 2 the middleware is part of the design, not a detail.** ROS 2 does not
transport messages by itself: it delegates to DDS (or to Zenoh) through an RMW layer. That is where
the domain's number one pathology comes from —**"I publish and the other node receives nothing, and
there is no error at all"**— which is almost never a bug: it is **incompatible QoS**, or a different
`ROS_DOMAIN_ID`, or multicast blocked by the network. **Silence is this system's default failure
mode**, and that is why QoS and discovery are designed and documented like any other contract.

**Third axis: here a failure moves mass.** An overflow on a website returns a 500; on a 30 kg arm at
2 m/s it is an injury. That raises the bar for everything else: network security, change control,
testing before touching hardware and machine safety regulation (§5, §6).

Triggers: `package.xml`, `CMakeLists.txt` with `ament_cmake`, `setup.py` with `ament_python`,
`colcon build`, `install/setup.bash`, `src/` with multiple packages, `rclcpp::Node`,
`rclpy.node.Node`, `create_publisher`/`create_subscription`, `.msg`/`.srv`/`.action`,
`ros2 topic echo`, `ros2 doctor`, `ros2 bag record`, `*.launch.py`, `ros__parameters` in YAML,
`ROS_DOMAIN_ID`, `RMW_IMPLEMENTATION`, `rmw_fastrtps_cpp`, `rmw_cyclonedds_cpp`, `rmw_zenoh_cpp`,
`tf2_ros`, `TransformListener`, `static_transform_publisher`, "extrapolation into the future",
`urdf`/`xacro`, `robot_state_publisher`, `ros_gz_bridge`, `controller_manager`, `nav2_bringup`,
`move_group`, `sros2`, `--enclave`, and the symptoms: "the topic is there but nothing arrives", "it
works in simulation and fails on the robot", "communication drops over wifi", "TF_OLD_DATA".

**Not applicable**: see `embedded-iot-standards` (**the microcontroller and the firmware are theirs,
without exception**: MCU, boot, partitioning, watchdog, power, device OTA update, hardware identity.
**Operational boundary**: if the code runs on an MCU without a full operating system —including
`micro-ROS` on an MCU—, **the firmware is theirs and all that remains here is the message contract
and the link QoS**; if it runs on an SBC/PC with Linux and `rclcpp`/`rclpy`, it belongs here),
`ot-ics-security-standards` (**the industrial plant is theirs, without exception**: Purdue/ISA-95
model, IEC 62443 zones and conduits, PLC/DCS/SCADA/SIS, fieldbus protocols, passive monitoring,
shutdown window. **Boundary**: a robot in a production cell **is designed under this skill and
governed under theirs** — segmentation, the vendor's remote access policy and process risk
governance are theirs; the node, QoS, TF and control are ours),
`computer-vision-standards` (**perception: SLAM, detection, segmentation, camera calibration,
labelling and evaluation are theirs**; here only **consuming** the result on a topic and its
timing), `deep-learning-standards` and `model-finetuning-standards` (training networks;
reinforcement learning and learned policy are designed there and **deployed** with the rules from
here), `local-inference-standards` (serving the model on the robot: engine, quantisation, memory),
`gpu-computing-standards` (the embedded GPU as a resource: driver, sharing, toolchain),
`edge-computing-standards` (**the edge node and the fleet as a distributed system are theirs**:
remote orchestration, synchronisation, deployment across many devices; **here the robot as a
system**), `linux-administration-standards` and `linux-hardening-standards` (the operating system,
its hardening and `systemd`; **here only the specifics**: `PREEMPT_RT`, CPU isolation and
priorities), `networking-standards` and `wireless-standards` (network design, VLANs, and **wifi as a
medium**: roaming and packet loss are theirs; here their consequences on QoS and discovery),
`cpp-standards` and `c-standards` (the language: UB, RAII, sanitizers, MISRA/CERT), `python-standards`
(Python outside `ament_python`), `cicd-standards` (pipeline and gates), `observability-standards`
(OTel pipeline and backend; here `rosbag2`, `/rosout` and diagnostics), `mlops-standards` (model
lifecycle), `game-development-standards` and `xr-standards` (**batch 22**: game engine,
frame budget and immersive teleoperation — a headset for piloting a robot is a client,
**the robot still belongs here**), `functional-safety` as a formal discipline (**does not exist in
the catalogue**: this skill sets the engineering criteria and the applicable standards, **it does
not replace a functional safety assessor**).

## 2. Default decisions / Toolchain

> Verify the current distribution, its EOL and the status of the standards on the web before pinning
> them in a real project (§8).

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| ROS version | **ROS 2 LTS** | — | ROS 1 unsupported since May 2025 |
| Distribution | **Lyrical Luth (LTS, EOL May 2031)** | Jazzy (EOL May 2029) if the ecosystem has not migrated | Robot service life |
| Non-LTS distribution | **Not in a product** | Prototype and R&D | 1.5 years of support |
| RMW | **The distro default** (`rmw_fastrtps_cpp`) | Cyclone DDS; `rmw_zenoh_cpp` on a bad link or WAN | Tier 1 support and tested packages |
| Build | **`colcon` + `ament_cmake`/`ament_python`** | — | It is the supported toolchain |
| Node language | **C++ (`rclcpp`)** in the control loop; Python (`rclpy`) in orchestration and tooling | — | GIL and non-deterministic latency |
| Stateful nodes | **Lifecycle nodes** (`rclcpp_lifecycle`) | Plain node in utilities | Governable startup and shutdown |
| Simulation | **Gazebo (Jetty LTS or Harmonic LTS)** | Isaac Sim / Webots / MuJoCo case by case | `ros_gz` integration |
| Control | **`ros2_control`** | Own controller with an ADR | Reusable hardware interfaces |
| Navigation / manipulation | **Nav2** / **MoveIt 2** | Own only with an impossible requirement | Cost of reimplementing |
| Real time | `PREEMPT_RT` + CPU isolation **for the loop**, not for everything | Loop on a separate MCU/FPGA | ROS 2 is not hard real time §6 |
| Network security | **SROS2 enabled from the design stage** | Documented physical isolation | DDS runs in the clear by default §5 |

**Verified ROS 2 calendar** (source: `Releases.rst` from `ros2_documentation`, read raw,
Aug 2026):

| Distro | Release | EOL | Type |
|---|---|---|---|
| **Lyrical Luth** | 22 May 2026 | **May 2031** | **LTS** |
| Kilted Kaiju | 23 May 2025 | Dec 2026 | non-LTS |
| **Jazzy Jalisco** | 23 May 2024 | **May 2029** | **LTS** |
| Iron Irwini | 23 May 2023 | 4 Dec 2024 | EOL |
| **Humble Hawksbill** | 23 May 2022 | **May 2027** | LTS, **expires in 9 months** |

Lyrical's platform and languages, verified on its supported platforms page: **Ubuntu
Resolute (26.04) Tier 1** on amd64 and arm64 (Ubuntu Noble on Tier 3, with EOL brought forward to
**2029-06-01**), **C++20**, **C17**, **Python 3.12–3.14**, **Gazebo Jetty** as a dependency, and
—verbatim— *«The default middleware in ROS Lyrical is rmw_fastrtps_cpp»*. `rmw_zenoh_cpp` entered
as **Tier 1** already in Kilted (REP-2000). REP-2000 also sets the rhythm: *«New ROS 2 releases will be
published in a time based fashion every 12 months»*, LTS **5 years**, non-LTS **1.5 years**.

**Gazebo — the naming mess, cleared up with verified dates.** There were three different things
named almost the same: **Gazebo Classic** (`gazebo11`, the old one), **Ignition Gazebo** (the rewrite)
and **Gazebo** (the current name of the rewrite, after the name was given back in 2022; versions are
named by letter: Fortress, Garden, Harmonic, Ionic, Jetty…). Verified status:

- **Gazebo Classic**: verbatim from `classic.gazebosim.org` — *«This version of Gazebo, now called
  Gazebo classic, reaches end-of-life in January 2025»*, with the exact date *«end-of-life on January
  29, 2025»*. **Dead. Nothing new is started on it and what exists gets migrated.**
- **Gazebo (new)**, per the official releases table: **Jetty** Sep 2025 → **May 2031 (LTS)**;
  **Ionic** Sep 2024 → Dec 2026; **Harmonic** Sep 2023 → **May 2029 (LTS)**; **Fortress** Sep 2021 →
  May 2027 (LTS); **Garden** EOL Nov 2024.
- Practical rule: **pick the ROS distro ↔ Gazebo version pairing that the REP/platform itself
  declares** (Lyrical→Jetty, Jazzy→Harmonic) and do not mix. The bridge is `ros_gz`.

## 3. Structure and conventions

**Workspace.** One `src/` with small, single-responsibility packages; never a
mega-package with everything inside. Separate by nature, because reusability and testability depend
on it:

```
ws/src/
  mi_robot_msgs/        # ONLY .msg/.srv/.action interfaces  (change little, break a lot)
  mi_robot_description/ # URDF/xacro, meshes, ros2_control tags
  mi_robot_bringup/     # launch + per-environment YAML parameters (sim / robot / lab)
  mi_robot_control/     # control nodes (C++), with no simulation dependencies
  mi_robot_perception/  # nodes that consume sensors
  mi_robot_bt/          # behaviour trees / mission logic
```

- **Interfaces go in their own package**: anyone using them does not drag in your dependencies, and
  their versioning is visible. **Changing a published `.msg` is a breaking change**: you add a
  field, you do not reorder or reinterpret; if you must break, create a new type and migrate.
- **`colcon build --symlink-install`** in development; in CI and on the robot, a clean build. **A
  single active *overlay***: chaining three `setup.bash` from three workspaces is the classic cause of
  "it runs an old version of the node and I cannot explain why". `ros2 doctor` and `ros2 pkg prefix`
  before blaming the code.
- **No absolute paths and no `~/ws/...` in the code**: `ament_index` and `$(find-pkg-share ...)`.

**Parameters and launch.** Everything configurable is a **declared parameter** (with descriptor,
range and default value), loaded from per-environment YAML, never a hidden constant nor an ad hoc
environment variable. `launch` files describe composition and nothing else: no business logic inside.
For latency, **composing nodes in the same process** (component composition) avoids serialisation and
copying —worth more than any micro-optimisation of the node—.

**QoS — the contract nobody writes and everybody breaks.** Verbatim from the official documentation:
*«A connection between a publisher and a subscription is only made if the pair has compatible QoS
profiles»*, under the **«Request vs Offered»** model: *«Subscriptions request a QoS profile that is the
"minimum quality" that it is willing to accept, and publishers offer a QoS profile that is the
"maximum quality" that it is able to provide»*. The two tables that explain 90 % of
"messages that never arrive":

| Reliability: publisher → subscriber | Compatible? |
|---|---|
| Best effort → Best effort | Yes |
| **Best effort → Reliable** | **No** |
| Reliable → Best effort | Yes |
| Reliable → Reliable | Yes |

| Durability: publisher → subscriber | Compatible? | Result |
|---|---|---|
| Volatile → Volatile | Yes | New messages only |
| **Volatile → Transient local** | **No** | **No communication** |
| Transient local → Volatile | Yes | New messages only |
| Transient local → Transient local | Yes | New and old |

And the detail that gets paid for dearly: *«To achieve a "latched" topic that is visible to late subscribers,
both the publisher and subscriber must agree to use 'Transient Local'»* — the equivalent of the ROS 1
*latched* requires **agreement at both ends** (map, robot description, static configuration).
The defaults, also verbatim: *«By default, publishers and subscriptions in ROS 2 have
"keep last" for history with a queue size of 10, "reliable" for reliability, "volatile" for
durability»*; the **sensor data** profile uses *best effort* and a small queue, and **services** are
reliable and **volatile on purpose** —*«otherwise service servers that re-start may receive outdated
requests»*—. House rules:

- **Each topic's QoS is declared in the package documentation**, next to the type. It is part of the
  interface.
- **High-frequency sensors → sensor data** (best effort, short queue). **Maps, static TF, robot
  description and configuration state → transient local at both ends.** Actuation commands
  → reliable, queue 1 (an old command is of no interest).
- **`deadline` and `liveliness`** are not decoration: they are the standard way of finding out that a
  node stopped publishing. In a safety loop, the watchdog timer goes here, not in an `if`.
- Faced with "nothing arrives": check in this order **`ROS_DOMAIN_ID` → same network and multicast →
  `ros2 topic info -v` (profiles at both ends) → message type → *namespace*/remapping**.

**TF2 — the transform tree.** Rules that avoid almost all of its failures:

- **A single parent per frame and a single connected tree**: two publishers of the same
  parent→child pair is a design error (the classic: `odom→base_link` published by two nodes).
- Standard naming convention and hierarchy (`map` → `odom` → `base_link` → sensors; REP-105) and
  axes per REP-103 (metres, radians, x forward, y left, z up). Departing from it costs you
  integration with the whole ecosystem.
- **Every piece of data carries the sensor's timestamp, not the receiving clock's.** Extrapolation
  errors and `TF_OLD_DATA` are almost always unsynchronised clocks across machines (NTP/PTP
  mandatory on multi-computer robots) or *timestamps* filled in with `now()`.
- **Fixed** transforms with `static_transform_publisher` / `tf2_ros::StaticTransformBroadcaster`
  (which use *transient local*), never republished at 100 Hz.
- **In simulation, `use_sim_time` set to `true` on every node.** A single one on the wall clock
  desynchronises the entire tree.

## 4. Quality and testing

- **Pyramid adapted to the robot**: (1) unit tests of the logic **separated from the node** —extracting
  the algorithm into a class without `rclcpp` is the design decision that enables the most testing—; (2)
  node tests with `launch_testing` (startup, parameters, expected publication, declared QoS); (3)
  **replay of a `rosbag2`** recorded from the real robot against the new version, comparing outputs;
  (4) simulation with scenarios; (5) test bench with the hardware; (6) the robot in its environment.
- **`rosbag2` is the domain's regression tool**: every field incident leaves a trimmed *bag* and a
  test that reproduces it. Without that, every failure is investigated from scratch.
- **Simulation lies and you have to know where**: friction, backlash, sensor noise, bus latency,
  thermal drift and CPU timings. It is good for logic, integration and dangerous cases; **it does not
  validate timings or mechanical tolerances**. "It works in Gazebo" is not an acceptance criterion.
- **CI gates in order of cost**: formatting and `ament` linters (`ament_cpplint`,
  `ament_clang_format`, `ament_flake8`, `ament_mypy`, `ament_copyright`) → build with warnings as
  errors → unit tests → `launch_testing` → replay of reference bags → automated simulation
  → deployment to the bench. **`main` green or the robot is not touched.**
- **Dynamic analysis in the control node**: ASan/UBSan/TSan in CI (`cpp-standards`); a race
  condition in a control loop shows up as movement.
- **Startup determinism**: test out-of-order startup —a node that starts before its source,
  incomplete TF, a missing parameter—. A system that only works if everything starts in the
  pretty order fails at the first field restart.
- **Degraded network test mandatory** if there is wifi: packet loss, latency and total outage.
  Check what the robot does when it loses its operator: **stopping is the correct default
  answer**.

## 5. Stack security

**The founding fact, verbatim from the official ROS 2 design documentation
(`design.ros2.org`, article *ROS 2 DDS-Security integration*):**

> ***«By default, none of the security features of DDS are enabled in ROS 2.»***

Translated: **without `sros2` configured, ROS 2 traffic travels with no authentication, no
authorisation and no encryption**. Any machine with access to the network and the same
`ROS_DOMAIN_ID` can **discover every topic, read them, publish actuation commands, change parameters
and call services**. There is no password to break because there is no password. **On a robot, that
is not a data leak: it is physical control of the device in the hands of anyone who reaches the network.**

- **A robot on a flat network is a physical security risk**, not an IT one. The first measure is
  architectural: its own segment, no route to (or from) the office network, no guest wifi, remote
  access only through a bastion and with strong authentication. The network and governance of that
  zone belong to `ot-ics-security-standards` and `networking-standards`; **demanding it is our duty**.
- **`ROS_DOMAIN_ID` is not security.** It is a traffic separator: anyone can set it. Neither is
  "it is behind NAT" nor "it is a VLAN".
- **SROS2** enables DDS-Security: identity and permissions CA, X.509 certificates per *enclave*, a
  governance file that —verbatim from the same document— *«will encrypt all DDS traffic by
  default»*, and permissions expressed in ROS terms (which node may publish/subscribe to what).
  **Its cost is real and must be budgeted for**: a PKI someone has to operate (issuance,
  distribution, expiry, **revocation and rotation**), CPU and latency overhead from encryption
  and signing, deployment and debugging complexity, and a configuration mistake that shows up
  —how else— **as silence**. It is enabled **from the design stage**, not at the end: retrofitting
  security into a 40-node system is a project.
- **Real least privilege**: one *enclave* per node or per functional group, with explicit read/write
  permissions per topic. A single enclave for the whole robot is encryption without authorisation.
- **Surface that DDS-Security does not cover**: operator interfaces (web, `rosbridge`,
  `web_video_server`, Foxglove) **exposed without authentication** —they are a remote control—;
  `rosbag2` with personal data (video of the surroundings, faces, number plates:
  `privacy-engineering-standards`); robot software updates without signing or origin verification;
  cloud credentials in the image; and **debug ports and serial consoles** reachable on the machine.
- **Supply chain**: third-party packages from `rosdistro`, the manufacturer's drivers and the
  downloaded models are code that runs with permission to move the robot. Pin versions, review
  licences (`opensource-licensing-standards`) and do not install from unverified sources.
- **Logging and traceability**: who enabled manual mode, who changed a speed parameter,
  who overrode a limit. In an incident with an injury, **that is the evidence**.

## 6. Performance and operability

**Real time: where the limit is, said without ambiguity.** **ROS 2 is not a hard real-time system
on its own.** That it uses DDS and has configurable *executors* does not make it deterministic:
there is still dynamic memory allocation, operating system scheduling, the GIL in `rclpy`,
copies in the transport, background discovery and a standard Linux kernel that does not guarantee
latency. What you **can** build:

- **Kernel with `PREEMPT_RT`**: the real-time patch **was merged into Linux kernel 6.12**
  (released on **17 Nov 2024**), after two decades out of tree —verified in the official release
  summary—. It stops being an external patch, but **you still have to compile/enable it and, above
  all, tune the entire system**.
- **Isolation**: `isolcpus`/`cpuset` for the control loop, IRQs off those cores, a fixed frequency
  governor, no power saving, no shared *hyperthreading*, **locked memory
  (`mlockall`) and no allocations in the loop**, well-chosen `SCHED_FIFO` priorities.
- **Measure, do not assume**: `cyclictest` for kernel latency and loop *jitter* measurement on the
  real robot, over hours and under load (perception, network, disk). **Average latency does not
  matter: the worst case does.**
- **The honest limit**: when the requirement is safety-related and measured in microseconds
  —emergency stop, current loop, torque limit—, **that does not live in ROS 2**. It lives in the
  robot controller, in an MCU/FPGA or in a certified safety relay, and ROS 2 talks to it from
  outside. **An emergency stop implemented as a ROS 2 node is a safety design failure**, not a
  pending optimisation.

**Operability:**

- **Diagnostics** (`diagnostic_updater`/`diagnostic_aggregator`) for every subsystem, with status
  readable by an operator, not only by a developer. `/rosout` structured and at the
  right level; **no `INFO` at 100 Hz** (it fills the disk and the CPU).
- **Metrics**: actual frequency of every critical topic against the expected one, end-to-end
  latency, loop cycle time (p99), lost messages, CPU usage per node, temperature,
  battery. Export to the `observability-standards` backend.
- **Permanent ring recording** with `rosbag2` (bounded size, with rotation) so you have the
  "before" of any incident; with a retention and personal data policy.
- **Supervised startup**: `systemd` with controlled restart, explicit dependencies, and a **safe
  state at boot** (brakes engaged, actuator power disabled until explicit
  enablement).
- **Degradation**: loss of a sensor, of the network or of the operator → **a defined safe state**, not
  "carry on with the last known value". Each node declares what it does when its input ages
  (that is what `deadline` is for).
- **Field update**: versioned image, deployment with tested rollback, and **never
  update with the robot enabled**. The maintenance window is agreed with whoever operates it.

**Machine safety (regulation) — verified status, and it is a big change from 2025:**

- **ISO 10218-1:2025** (industrial robots) and **ISO 10218-2:2025** (applications and cells) were
  published in **February 2025** and supersede the 2011 versions. **ISO/TS 15066 ceases to be
  a separate technical specification: its content —collaboration by power and force limiting
  (PFL), speed and separation monitoring (SSM), hand guiding (HGC), and the force
  and pressure limits— has been incorporated into ISO 10218-2.** The new series additionally introduces **two robot
  classes** (Class 1 for very weak robots with no significant risk, with reduced control
  requirements; Class 2 for the rest), abandons the single performance level PL d/cat. 3 in favour of
  a **PL per safety function** (with the option to deviate through an extended risk assessment),
  requires a **normal stop** function distinct from the emergency stop, and incorporates for the first
  time **cybersecurity requirements** insofar as they affect safety.
- **Terminology**: the new series speaks of a **"collaborative application"**, not a "collaborative
  robot": what is assessed and validated is **the specific use** —robot + tool + workpiece +
  environment + task—, not the device. Buying a "cobot" does **not** exempt you from a risk assessment.
- **Legal framework in the EU**: the **Machinery Regulation (EU) 2023/1230** supersedes Directive
  2006/42/EC; verbatim from EUR-Lex: *«It shall apply from 14 January 2027»* and *«Directive 2006/42/EC
  is repealed with effect from 14 January 2027»*. **A planning date, not a surprise.**
- **Presumption of conformity**: the citation of EN ISO 10218-1/-2 in the Official Journal of the EU
  was pending at the time of verification (with a 24-month transitional period
  requested). **Verify the status before resting a technical file on it (§8).**
- **What this skill does not do**: it does not replace the risk assessment, nor the PL/SIL calculation
  (ISO 13849-1 / IEC 62061), nor the relevant body or assessor. It establishes that **the
  obligation exists** and that it is planned from the start, not just before delivery.

## 7. Long-term sustainability

- **Cadence**: product on **LTS**, with a planned jump before EOL (Humble expires in
  **May 2027**: if there is a fleet on Humble, migrating to Jazzy or Lyrical is this year's work, not
  next year's). Non-LTS only for prototypes.
- **Migration as a continuous practice**: test against `rolling` in a *non-blocking* CI job to
  find out about breakage early, instead of discovering it all at once at the jump.
- **Robot life > distro life**: an industrial device lasts 10–15 years and no ROS 2 distro
  lasts that long. **Migration is planned from the design stage**: bounded dependencies, an
  abstraction layer over what changes and the ability to update in the field. If the robot cannot be
  updated, you are signing off on its obsolescence.
- **Document in an ADR**: distribution and reason, chosen RMW, QoS profiles per topic, real-time
  strategy and where the safety boundary is, the decision on SROS2, simulator and version.

**Explicit prohibitions:**

- ❌ **Starting a new project on ROS 1** or keeping one "because it works": Noetic ended in
  **May 2025** and receives no security patches.
- ❌ Running ROS 2 **without SROS2 on a network reachable by anything other than the robot**, or believing that
  `ROS_DOMAIN_ID`, the VLAN or NAT are security.
- ❌ Exposing `rosbridge`, `web_video_server`, Foxglove or any teleoperation interface **without
  authentication**.
- ❌ **Implementing the emergency stop, the torque limit or the safety interlock as ROS 2
  nodes.** The safety function goes in certified hardware/controller.
- ❌ Promising "real time" because you use ROS 2, or because you installed `PREEMPT_RT` without isolating CPUs, without setting
  priorities, without `mlockall` and **without measuring the worst case**.
- ❌ Control logic in `rclpy` inside the hot loop; allocating memory, doing I/O or waiting on
  locks inside a control *callback*.
- ❌ Publishing TF for the same parent→child pair from two nodes, or using `now()` as the timestamp of a
  sensor reading.
- ❌ Using default QoS for everything and debugging by restarting; or declaring a topic "latched" without
  *transient local* **at both ends**.
- ❌ Chaining workspace *overlays* and debugging the wrong binary.
- ❌ Changing a published message (reordering fields, reinterpreting units) without a new type and a
  migration path.
- ❌ Validating only in simulation and calling it done; or testing the first movement at production
  speed with people nearby.
- ❌ Starting anything new on **Gazebo Classic** (EOL 29 Jan 2025) or mixing Gazebo versions with
  the distro they do not correspond to.
- ❌ Treating machine safety (ISO 10218 / the Machinery Regulation) as end-of-project paperwork. It is
  a design requirement with a date: **14 January 2027**.
- ❌ `INFO`/`DEBUG` at sensor frequency in production.

## 8. Mandatory web verification

Before deciding, check against the primary source:

1. **Current distribution and EOL**: `docs.ros.org` (*Releases*/*Distributions* page) and **REP-2000**
   —careful: the REP on `master` **did not yet list Lyrical** when this document was verified, while the
   documentation did; **the distro documentation wins**. Verified: Lyrical Luth 22 May 2026 →
   **May 2031 (LTS)**; Jazzy → May 2029; Humble → **May 2027**; Kilted → Dec 2026.
2. **Platform and dependencies** of the chosen distro on its *Supported Platforms* page (Ubuntu,
   minimum C++/Python, default RMW, Gazebo version). Verified for Lyrical: Ubuntu Resolute
   26.04, C++20/C17, Python 3.12–3.14, `rmw_fastrtps_cpp`, Gazebo Jetty.
3. **REP-3** to confirm that Noetic is still the last ROS 1 release and its EOL (verified:
   *«Noetic Ninjemys (May 2020 - May 2025)»*).
4. **Gazebo**: releases and EOL table at `gazebosim.org/docs/latest/releases/` (verified: Jetty
   →May 2031, Ionic →Dec 2026, Harmonic →May 2029, Fortress →May 2027) and the EOL notice at
   `classic.gazebosim.org` (verified: **29 Jan 2025**).
5. **Security**: that the statement *«By default, none of the security features of DDS are enabled in
   ROS 2»* is still current on `design.ros2.org` and in the `sros2` documentation; security advisories
   for the DDS implementation in use (Fast DDS, Cyclone DDS, Connext) and for the corresponding `rmw`.
6. **Real time**: the status of `PREEMPT_RT` in the kernel version you intend to use (verified:
   merged into **Linux 6.12**, 17 Nov 2024) and the current tuning guide.
7. **Machine safety regulation**: the status of **ISO 10218-1/-2:2025**, of the absorption of
   **ISO/TS 15066** and —**critically**— of their **citation in the OJEU** under Regulation (EU) 2023/1230,
   which was **pending** on the verification date. **Declared gap**: `iso.org` returns
   **HTTP 403** to automated access, so the status of the standards was verified against a specialised
   secondary source; **the normative text has to be bought and read**, and the dates of
   application are cross-checked on EUR-Lex (verified there: *«It shall apply from 14 January 2027»*).
8. **Nav2, MoveIt 2, `ros2_control` and manufacturer drivers**: which distributions they support today and with
   which version; they usually lag behind a freshly released LTS, **and that may decide the distro**.
9. **CVEs** in the stack: kernel, DDS, C++ dependencies and installed `rosdistro` packages.

If the web contradicts this document, **the web wins** — flag the discrepancy.
