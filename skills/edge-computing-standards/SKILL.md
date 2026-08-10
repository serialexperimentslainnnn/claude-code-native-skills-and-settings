---
name: edge-computing-standards
description: Computing on nodes you cannot walk up to — fleet operations for edge sites and devices under an intermittent link. Use when deciding whether a workload actually belongs at the edge (latency budget, upstream bandwidth cost, data residency, offline survival) or is just a distributed monolith, designing an A/B dual-partition image update with automatic rollback and a health check gate (rpm-ostree, bootc, greenboot, balenaOS), rolling an update across thousands of nodes in waves with a kill switch, running a lightweight Kubernetes at the edge (k3s, MicroShift, KubeEdge, Akri) or deciding that systemd plus Podman Quadlet units are enough, store-and-forward telemetry, metric downsampling and egress cost per node, eventual reconciliation and conflict resolution after a reconnect, giving each node its own identity instead of one shared fleet credential, UEFI Secure Boot and measured boot on an unattended node, LUKS full-disk encryption where the attacker physically holds the device, zero-touch onboarding and remote attestation, certificate rotation on a node that was offline when the cert expired, or serving inference on an edge box.
---

# Edge computing standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **operating compute on nodes you cannot walk up to**: deciding whether the edge is
necessary, the topology, fleet management and safe updating, disconnected
operation, observability over an intermittent link, the security of a node that is
physically in someone else's hands, and provisioning without human intervention.

**Guiding principle**: **the edge is not defined by distance, but by constraint.** A
system is an edge system when at least one of these four things forces it to be, and you must be able to say
which:

1. **Latency**: there is a millisecond budget that the round trip to the centre does not meet.
2. **Bandwidth or upstream cost**: generating the data is cheap, transporting it is not.
3. **Sovereignty or regulation**: the data cannot leave a country, a building or a network.
4. **Survival without connectivity**: the site must keep working with the link down.

**If none of the four applies, it is not edge: it is a distributed monolith**, and you have
bought all the difficulty of fleet management with none of its advantages. That is the
first question in any design and the one most often skipped.

**Second thesis, which orders §3.2 onwards**: **the cost of the edge is not the hardware, it is the
fleet.** One node is easy. Three thousand nodes with different firmware, bad links, drifting
clocks, certificates about to expire and no console are an operations problem that
is only solved with automation tested before you need it.

Triggers: "does this go at the edge or at the centre?", "latency budget", "we cannot upload
all that video", "it has to work without a line", device fleet, A/B update,
dual partition, automatic *rollback*, `rpm-ostree`, `bootc`, `greenboot`, Mender, RAUC,
SWUpdate, `.swu`, balenaOS, wave rollout, *kill switch*, k3s, MicroShift, KubeEdge,
Akri, "do we need Kubernetes here?", *store-and-forward*, local telemetry queue,
reconciliation after reconnect, clock drift, TPM, secure element, Secure Boot, measured
boot, LUKS, "the same key on every device", zero-touch provisioning,
remote attestation, "the certificate expired while it was powered off", inference at the edge.

**Not applicable**: see `embedded-iot-standards` (**the microcontroller and
bare-metal or RTOS firmware** — if there is no general-purpose operating system with a package
manager and containers, it is theirs; here from the Linux SBC/gateway upwards.
**The A/B image boundary, which both could claim**: the mechanism is chosen by what is
underneath, not by where the box is — **firmware image** (MCUboot, RAUC, SWUpdate, Mender,
hawkBit, slots with a rollback counter) is theirs; **full OS image** (rpm-ostree, bootc,
greenboot, balenaOS) belongs here. What does **not** change sides: the **campaign** —waves, *kill
switch*, percentage and stop criteria across thousands of nodes— belongs here whatever the
mechanism, because it is a fleet problem, not a board problem),
`ot-ics-security-standards` (**the industrial plant**: PLC, SCADA, fieldbus protocols,
Purdue model, functional safety — an edge node in a factory falls under **their**
constraints, and theirs win over the ones here),
`kubernetes-standards` (**the central cluster and all of Kubernetes as a platform**: manifests,
Helm, GitOps, admission policies, CNI, operators — here only the criteria for **whether** to put
Kubernetes at the edge and which distribution), `podman-systemd-containers-standards` (**the
real alternative to Kubernetes at the edge**: Quadlet units, containers under systemd,
`podman auto-update` — the mechanism is theirs, here the decision to use it),
`os-provisioning-standards` (**installing the OS**: Kickstart, image, `bootc install`, PXE — here
the nuance that at the edge nobody is standing in front of it and installation arrives by USB or by
zero-touch provisioning), `rhel-fedora-standards` (**`rpm-ostree`, `bootc` and *image mode*
as a Red Hat ecosystem**; here as an A/B update pattern),
`iac-standards` (Ansible/Terraform and the code that configures; **careful: Ansible's *push* model
does not work against a node that is powered off or behind NAT — see §3.2**),
`local-inference-standards` (**the model and its engine**: quantisation, memory, endpoint — here
only how it reaches and is updated across the fleet), `gpu-computing-standards` (the accelerator),
`observability-standards` (**OTel, Prometheus, alerts and their design**; here the nuance of the
intermittent link and cost per byte), `networking-standards`, `vpn-standards` (**the tunnel back
home**: WireGuard, meshes), `dns-standards`, `firewall-policy-standards`,
`load-balancing-standards`, `caching-cdn-standards` (**the CDN edge and its functions**: if
the problem is serving HTTP content closer to the reader, it is theirs, not this skill's),
`gaming-infrastructure-standards` (**match servers near the player**: the generic edge platform
belongs here; session orchestration, matchmaking and the game fleet
are theirs),
`identity-access-management-standards` (the human IdP; here **machine** identity),
`cryptography-pki-standards` (**PKI, ACME, key custody and rotation**: the mechanics are
theirs, here the problem of rotating against a disconnected node),
`secrets-management-standards` (where the secret lives), `endpoint-security-standards` (the
managed workstation), `macos-fleet-standards` (Apple fleet with MDM),
`linux-hardening-standards` and `selinux-standards` (OS baseline),
`container-runtime-security-standards` (seccomp, escape, `--privileged`),
`cmdb-inventory-standards` (**the fleet inventory** as a record),
`bcdr-standards` (RTO/RPO and continuity), `backup-recovery-standards` (**do you back up an edge
node? Almost never: you rebuild it — see §3.5**), `datacenter-facilities-standards` (the
central plant), `finops-standards` (cost), `homelab-standards` (proportionality),
`privacy-engineering-standards` (personal data captured at the edge: minimisation at source),
`grc-compliance-standards`, `wireless-standards` (the radio access link),
`mobile-standards` (the phone app).

## 2. Default decisions

> Verify on the web the version, project status and **licence read raw** before committing
> to anything (§8).

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| Edge or centre? | **Centre**, unless one of the four constraints in §1 is named | The edge multiplies the operating cost of every decision by N. You pay it only with a written reason |
| Orchestration on the node | **systemd + containers (Podman/Quadlet)** | See §2.1. Kubernetes at the edge only when its model brings something systemd does not |
| Lightweight Kubernetes, if needed | **k3s** | **Apache-2.0** (read raw), **CNCF project at Sandbox level** since 2020, certified distribution, single binary. Alternatives: **MicroShift** if the site is already Red Hat and the subscription is paid for; **KubeEdge** (**graduated in the CNCF**) if its cloud-edge model with devices is genuinely needed |
| Update model | **Full A/B image with automatic *rollback*** | See §3.2. Updating by packages on an unreachable node is how a fleet is lost |
| Base system | **Immutable, transactional root filesystem** (`bootc`/`rpm-ostree`, or A/B image with RAUC/SWUpdate/Mender) | A node that can be modified live diverges, and divergence across a fleet is undiagnosable |
| Update gate | **Automatic health check that decides commit or revert** (`greenboot` or your own equivalent) | See §3.2: without a *health check*, A/B is not automatic *rollback*, it is just two partitions |
| Node identity | **One cryptographic identity per device**, anchored in a TPM or secure element | See §3.6. The shared credential is **the** design failure of this domain |
| Encryption at rest | **Yes, with the key sealed to the boot state (TPM)** | The attacker holds the device; the disk comes out with a screwdriver |
| Telemetry | **Aggregated and *store-and-forward* with a bounded local queue** | See §3.4. Sending everything raw is expensive and gets lost anyway when the link drops |
| Connectivity back home | **The node initiates the outbound connection**; never an exposed inbound port | The node is behind NAT, behind CGNAT or behind someone else's firewall. It also exposes no surface |
| Provisioning | **Zero-touch with attestation**: the device identifies itself and receives its configuration | Nobody with technical training is going to be standing there |

### 2.1 Kubernetes at the edge: when it is over-engineering

**An edge node with four containers does not need a control plane.** Kubernetes
solves **scheduling across nodes**, and at a single-node edge site there is nothing to
schedule. What it brings —scheduler, controllers, declarative API— costs memory, CPU,
a control plane that also has to be updated and a new failure mode (a corrupt `etcd`
at a site with no hands is a trip).

- **systemd + containers is enough** when: one node per site, a fixed set of services,
  ordered startup with dependencies, restart on failure, and updating by whole-system
  image. `systemd` already gives dependencies, retries, *watchdog*, sockets and
  timers; Quadlet adds declarative containers. **It is less software to
  maintain, and at the edge that is the metric that rules.**
- **Kubernetes at the edge is justified** when: there are several nodes per site with
  real rescheduling among them, the team already operates Kubernetes and the marginal cost of
  learning something else exceeds that of bringing it in, or you need the same declarative model
  end to end with GitOps all the way to the edge.
- **Honest check**: if the answer to *"what would the scheduler do here?"* is *"nothing,
  there is only one node"*, the answer is systemd.
- **Project status, verified** (re-verify, §8): **k3s** Apache-2.0, CNCF Sandbox,
  releases aligned with Kubernetes versions (v1.36 observed in 2026). **MicroShift**
  Apache-2.0 in the repository, but **the Red Hat build is consumed by subscription** (Red
  Hat Device Edge / OpenShift) and is **coupled by a version matrix to that of RHEL** — that
  is an architectural constraint, not a commercial detail. **KubeEdge** graduated in the
  CNCF. **Akri** (exposing field devices —IP cameras, USB— as Kubernetes resources)
  is still in **CNCF Sandbox** with recent activity, but it is a small project: assess
  its maintenance pace before depending on it.

## 3. Structure and conventions

### 3.1 Topology: four tiers and who decides what

- **Device**: sensor, camera, PLC, SBC. Minimal resources, sometimes with no general OS.
- **Far edge**: the node in the shop, the substation, the truck, the operating theatre.
  One or a few units, a link owned by someone else, zero technical staff. **It is the tier that
  defines this document.**
- **Near edge**: a regional cabinet or small room with several nodes, a decent link
  and perhaps schedulable physical access.
- **Region / centre**: where the control plane, the history and the trained model live.

**Split rules that avoid most mistakes**:

- **The control plane lives at the centre; the data plane, at the edge.** The edge executes;
  it does not decide global policies.
- **Every tier must work if the one above disappears**, with declared degradation. If the
  edge stops working without the centre, it was not an edge architecture.
- **Data is reduced as early as possible.** Filtering, aggregating and discarding on the node is the
  lever for cost, privacy and bandwidth all at once. Uploading raw data "just in case" is the
  most expensive decision made in this domain.

### 3.2 Updating: A/B, health and waves

**The design requirement is this: a bad update cannot require someone to drive
to the node.** Everything else follows from that.

Mandatory pattern:

1. **Two slots (A/B)** or transactional root: the new image is written to the inactive slot
   while the active one keeps serving. Reboot into the new slot.
2. **Health check after boot**, with criteria specific to the service (do the services
   start? is there network? does the control plane respond? is the disk healthy?).
3. **Automatic commit or revert**: if the check does not pass within a deadline, the
   bootloader returns to the previous slot on its own. **Without this step, A/B is not automatic
   *rollback*: it is two partitions and a phone call.**
4. **The image is signed and verified** before being written. An update channel without
   signature verification is remote code execution with home delivery.
5. **Atomic update, resilient to power loss**: cut the power halfway through
   writing and the node has to boot. That is the test case, not an unforeseen event.

Tools, with licence **read raw** (§8): **bootc** and **rpm-ostree** (Apache-2.0,
container boot image model, with `greenboot` as the health *gate* in the Red Hat
family), **RAUC** (**LGPL-2.1**, bundles and slots, widely used with Yocto), **SWUpdate**
(**GPL-2.0-only**, with an LGPL-2.1 control library and Lua extensions under MIT; `.swu`
format), **Mender** (client and server **Apache-2.0** in their repositories, with a commercial
offering on top — verify which edition is being deployed), **balenaOS/balena** (open OS
with a **commercial balenaCloud platform**: what locks you in is not the OS licence, it is the service).

Fleet rollout:

- **In waves, always.** A canary ring (dozens of representative nodes, not the
  best ones), then a percentage, then the rest. Between rings, **enough observation time
  for slow failures to show up**: memory leaks, disk filling up,
  certificates, weekly reboot.
- **Stop switch (*kill switch*)** that halts the rollout in progress. And it gets tested.
- **The cohort is defined by what differentiates the nodes**: hardware model, source
  version, country, link type. A "homogeneous" fleet never is.
- **Update window per site**: a node in an operating theatre or in a checkout till is not
  rebooted at just any hour.
- **Nodes that have been off for months**: the system must support jumping several versions
  at once, or declare and enforce a minimum version with a recovery path. This
  case always happens and is almost never tested.
- **The *push* does not work.** An Ansible-style model against nodes that are powered off, behind NAT or with a
  changing IP does not arrive. **The node polls and pulls its desired state**; the centre publishes.

### 3.3 Disconnected operation and reconciliation

- **You explicitly declare what works without the link and what does not.** Without that document, the
  behaviour during an outage is whatever comes out, and it will come out in production.
- **Bounded autonomy**: how long the node can operate alone (days, weeks), and what happens when
  that runs out (does it degrade? does it stop? does it carry on with stale data?). An authorisation cache that expires
  after an hour turns a network outage into a service outage.
- **Reconciliation on return**: you must decide **the conflict resolution rule** —
  last writer wins, the centre wins, union, or manual resolution with an exception queue.
  "It'll sync eventually" is not a rule.
- **Idempotency and retries**: everything the node sends will be retried; without idempotency
  keys, transactions get duplicated on reconnect.
- **The clock lies.** Without NTP for days the node drifts; events arrive with
  impossible stamps, certificates look expired and signatures fail. Monotonic clocks
  are used to measure intervals, the event is stamped with local time **and**
  with receipt time, and ordering is by sequence as well as by time.
- **Certificates**: the case that breaks fleets is the node that was disconnected when it was due to
  rotate. You design long lifetimes for the anchor identity, early and well-anticipated rotation
  for service ones, and **a recovery path that does not depend on the expired
  certificate**. Check the root CA's expiry before deploying, not after.

### 3.4 Observability over an intermittent link and cost per byte

- **Agent with a persistent, bounded local queue** (*store-and-forward*): it stores while there is no
  link and sends on return. **Bounded** is the key word: an unbounded queue fills the disk
  and takes the node down — at exactly the worst moment. On reaching the limit it discards by declared
  policy (oldest first, or lowest priority).
- **Aggregate on the node**: percentiles and counters per interval, not raw events. The cost
  of telemetry per node is multiplied by the size of the fleet; at 5,000 nodes, a few extra KB
  per second are a bill.
- **Sampling and levels**: very reduced normal logging, with **the ability to raise the detail on
  demand for a specific node** during an investigation. That lever is what replaces
  the console you do not have.
- **Alert on the fleet, not on the node.** Five thousand nodes generate individual failures
  constantly; the useful alert is "4 % of cohort X has not reported since yesterday's
  rollout". A downed node is a ticket, not a page.
- **Silence is a signal, and it has to be told apart**: a powered-off node, a dropped link, a dead agent
  and a stolen node all look the same from the centre. A heartbeat carrying the cause of last disconnection
  when it returns resolves most of it.
- **Bricked detection**: an explicit metric of nodes that do not come back after an
  update, with a threshold that triggers the *kill switch* from §3.2.

### 3.5 Disposable node

- **The node is not backed up: it is rebuilt.** Its state splits into three: **image** (comes
  from the registry), **configuration** (comes from the control plane), **local data** (the only
  irreplaceable part, and therefore synced to the centre or its loss explicitly accepted).
- **Replacing a node must be a field procedure someone untrained can carry out**:
  unplug, plug in the new one, power it on. Everything else is done by zero-touch
  provisioning (§3.6). If replacing it requires an engineer, the fleet does not scale.
- **Decommissioning**: a retired node has its identity and credentials revoked **and** its storage
  wiped or destroyed. A retired device still on the trust list is an
  open door with the keys left in.

### 3.6 Security: the attacker holds the device

This is the threat model change that separates the edge from the centre. There is no guard, no
door, no CCTV. You have to assume **full physical access, with time and tools**.

- **One cryptographic identity per device, not shared.** **The single credential for
  the whole fleet is the classic design failure of this domain**: compromising one single device —
  bought second-hand, stolen, or simply opened— hands over the entire fleet, and **there is no
  possible revocation without touching every node**. Per-device identity means that
  compromising one costs one, and revoking it is a routine operation.
- **Hardware trust anchor**: TPM 2.0 or secure element. The private key is generated
  inside and never leaves. A private key in a file on disk is a public key with
  extra steps.
- **Secure and measured boot**: UEFI Secure Boot with the owner's keys (not just the
  manufacturer's) so that only signed software boots, and measured boot into TPM PCRs
  so that the boot state is checkable.
- **Encryption at rest with the key sealed to the boot state**: LUKS with the key released
  by the TPM only if the measurements match. That way the extracted disk cannot be read and a tampered
  boot does not open the volume. **Without sealing, encryption on an unattended node protects little:
  the key is on the same device.**
- **Remote attestation**: before handing over credentials or configuration, the centre checks
  that the node is who it says it is and is in the expected state. That is what turns
  zero-touch provisioning into something other than "handing out credentials to whoever asks".
- **Ephemeral, least-privilege credentials**: the node obtains short-lived tokens for
  what it needs. Never a broad write credential against the central system; the node
  **pushes its telemetry** and **pulls its configuration**, and neither of the two permissions
  requires permissions over other nodes.
- **Minimal surface**: no unnecessary listening services, no permanent remote access
  enabled by default, serial console and debug (JTAG/UART) disabled or protected in
  production.
- **Tamper detection**: opening sensors, seals, and **the corresponding alert**.
  And the uncomfortable operational rule: **a node suspected of tampering is revoked first and
  investigated afterwards.**
- **The update channel is the fleet's most valuable asset.** Whoever controls it executes
  code on every node. Image signing with custodied keys, verification on the
  device, and the signing process treated as a critical system
  (`cryptography-pki-standards`, `secrets-management-standards`).

### 3.7 Inference at the edge

- **It is a specific case of the four constraints in §1**, and almost always of two: latency
  (you cannot wait for the centre) and bandwidth (the video does not fit in the uplink).
- **The model is a fleet artifact**, not a loose file: it is versioned, signed,
  distributed through the same channel as everything else, and **can be rolled back just like the software**.
  A model change is a ringed rollout, not an SSH copy.
- **You decide what goes up**: prediction yes, raw data almost never. That is where both the saving and
  the minimisation demanded by `privacy-engineering-standards` live.
- **Model drift at the edge is harder to see** than at the centre, because labels
  rarely come back. Monitoring and retraining belong to
  `mlops-standards`; here only the distribution and rollback mechanism.
- The engine, quantisation and memory sizing belong to `local-inference-standards`.

## 7. Long-term sustainability and prohibitions

> §4 (quality and testing) and §6 (performance and operability) are deliberately omitted: in this
> domain testing is that of the language skill and operability is spread between §2 and
> §3, where it is actually decided. The catalogue's canonical numbering is kept so that the cross
> references to §7 and §8 point to what they say.

**The horizon is long and that is the problem.** An edge node lives for years in places nobody
returns to. Consequences that are decided **before** buying:

- **Hardware and OS end of life dated from day one**, and a minimum supported version
  that is enforced. A fleet with six generations of everything is undeployable.
- **The expiry of certificates and of the root CA is planned at the scale of the device's
  lifetime**, not the project's.
- **A defined and demonstrated security update cadence**: if you cannot patch a
  critical CVE across the whole fleet within a declared deadline, that deadline is the real risk, not whatever
  the policy says.
- **Vendor exit**: if fleet management depends on someone else's cloud (balenaCloud,
  a subscription, or a proprietary service), you document **how control of the devices is
  recovered** if it disappears. Without that answer, the fleet is a hostage.

Prohibitions:

- ❌ **One credential, key or certificate shared across the whole fleet.**
- ❌ **Updating live via the package manager** on an unreachable node, with no alternative
  slot and no rollback.
- ❌ **A/B without an automatic health check that reverts.** It is half the mechanism.
- ❌ **Deploying to the whole fleet at once.** Rings or nothing.
- ❌ **An update channel without a signature verified on the device.**
- ❌ **An exposed inbound port on the node**, or permanent remote access enabled by default.
- ❌ **A telemetry queue with no size limit.** It fills the disk and takes the node down.
- ❌ **Uploading raw data by default** without having calculated the upload cost or the
  minimisation.
- ❌ **Assuming the node's clock is correct**, or ordering events only by their timestamp.
- ❌ **Encryption at rest with the key on the disk itself** on an unattended machine.
- ❌ **Putting Kubernetes on a single-node site** without being able to say what it schedules.
- ❌ **Decommissioning a node without revoking its identity** and without wiping or destroying its storage.
- ❌ **Calling "edge" a deployment that meets none of the four constraints in §1.**
- ❌ **Stating the licence or maturity status of k3s, MicroShift, KubeEdge, Akri, Mender,
  RAUC, SWUpdate or balenaOS from memory.** Several change commercial model (§8).

*(The separate "quality and testing" and "performance" sections are deliberately omitted:
in this domain the test **is** the ringed rollout with automatic revert (§3.2) and
capacity is measured as telemetry cost and autonomy without a link (§3.3–3.4). Separating them
would duplicate content without adding criteria.)*

## 8. Mandatory web verification

Before committing to any data in this document:

1. **Licences read raw — result of this verification (August 2026)**:
   - **k3s**: `LICENSE` on `master` → **Apache-2.0**.
   - **MicroShift**: `LICENSE` on `main` → **Apache-2.0** in the repository; **the supported
     Red Hat build requires a subscription** and is coupled by a version matrix to
     RHEL. Distinguish repository from product.
   - **Akri**: `LICENSE` on `main` → **Apache-2.0**.
   - **bootc**: `LICENSE-APACHE` present → **Apache-2.0** (verify whether it is dual with MIT).
   - **RAUC**: `COPYING` → **LGPL-2.1**.
   - **SWUpdate**: `COPYING` → **GPL-2.0**; the README itself states: *"SWUpdate is released
     under GPLv2. A library to control SWUpdate is part of the project and it is released under
     LGPLv2.1"*, with Lua extensions under MIT.
   - **Mender**: `LICENSE` of `mender` and of `mender-server` → **Apache-2.0** (Northern.tech AS);
     there is an overlaid commercial offering — **verify the specific edition**.
   - **balenaOS**: **declared gap.** The `LICENSE` of a board repository
     (`balena-raspberrypi`) is Apache-2.0, but **the licence file of
     `meta-balena` has not been located** on the paths tried (`master` and `main` return 404). Read it before
     stating the OS licence, and bear in mind that **the real lock-in is balenaCloud, which is
     a commercial service**, not the licence.
   - **KubeEdge**: **declared gap** — its licence file was not read in this pass.
2. **Status and maturity**: verified that **k3s** is in **CNCF Sandbox** (accepted in 2020, with
   the maintainers stating their intention to promote it), **KubeEdge** is **graduated** in
   the CNCF, and **Akri** is still in **Sandbox** since 2021 with recent activity (*commits* and
   a *release* in July–August 2026). Re-verify on `cncf.io` and in the *landscape*: the
   levels change and the press does not always cover it.
3. **Versions**: k3s follows Kubernetes versions (v1.36.x observed); check which
   Kubernetes version it supports and until when. bootc, RAUC, Mender and SWUpdate are verified
   through the repository's *releases* Atom feed. **`api.github.com` unauthenticated returns 403;
   use the Atom feeds.**
4. **MicroShift compatibility matrix with RHEL**: it changes per version and is an architectural
   constraint. Consult Red Hat's documentation before committing to a version.
5. **Hardware and secure boot**: the availability of TPM 2.0, of Secure Boot with your own
   keys and of LUKS sealing **depends on the specific board**. It is verified against the
   real model before designing on top of it; on many SBCs it is absent or unusable.
6. **CVEs in the update channel and the lightweight control plane**: triage with CVSS + EPSS +
   **KEV**. A CVE in the update agent is the worst possible case for this architecture.
7. **Figures**: **no "edge computing" market number, typical latency or bandwidth
   saving is written without a source and methodology.** The latency budget and the
   upload cost are calculated with the project's data, not with an industry statistic.

If the web contradicts this document, **the web wins** — flag the discrepancy.
