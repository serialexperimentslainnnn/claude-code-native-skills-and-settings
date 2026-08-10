---
name: home-automation-standards
description: Engineering a home that keeps working when the internet, the vendor or the hub goes down. Use when designing or reviewing a smart home built on Home Assistant (configuration.yaml, automations.yaml, scripts.yaml, secrets.yaml, templates and Jinja2 triggers, HACS custom components, Home Assistant OS versus Container installs, add-ons/apps, the monthly 20XX.M release train and its backward-incompatible changes), openHAB, Node-RED, Zigbee2MQTT and its coordinator firmware, ZHA, ESPHome YAML device configs, MQTT and Mosquitto topics and retained state, choosing between Zigbee, Z-Wave, Thread and Matter (commissioning, border routers, fabrics, multi-admin) versus cloud-only Wi-Fi devices, putting IoT devices on their own VLAN with egress filtering, an abandoned device whose vendor stopped shipping firmware, cameras, microphones and presence detection inside a home, voice assistants and local speech processing, robust versus fragile automations (state versus event triggers, the automation that locks someone out or leaves the house cold), physical switch fallback, or backing up and rebuilding the whole configuration from scratch.
---

# Home automation standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **automating a home**: choosing devices and protocols, setting up the control
platform, segmenting the network, writing automations that do no harm, maintaining the whole thing when
a vendor disappears, and protecting the privacy of the people who live inside.

Triggers: `configuration.yaml`, `automations.yaml`, `scripts.yaml`, `secrets.yaml`, Home Assistant
Jinja2 templates, HACS, *add-ons*/apps, Home Assistant OS versus Container, openHAB, Node-RED,
Zigbee2MQTT, ZHA, Zigbee coordinator firmware, ESPHome and its device YAML, MQTT/Mosquitto,
*retained*, Zigbee, Z-Wave, Thread, Matter, *border router*, *fabric*, *multi-admin*, "the device
needs the cloud", "the vendor has shut down the service", IoT VLAN, camera, microphone, presence
detection, voice assistant, "the automation locked me out of the house", "the heating switched off",
configuration backup.

**Guiding principle, and it is an acceptance criterion, not a preference: the house has to keep
working when the internet, the vendor or the automation server go down.** A home is not
a service with an SLA; it is the place where somebody has to be able to turn on a light, open the door and
not be cold at three in the morning. Three absolute rules follow from that:

1. **The physical switch is never replaced.** Every controlled load keeps a manual control
   that works with the platform switched off. A smart relay behind the wall switch, not in
   place of it; a "smart" bulb powered by a switch that people can turn off is
   a design fault, not an integration.
2. **Local control by default.** A device that needs to reach the internet to turn on a light
   introduces an external dependency in a basic household function. The purchase criterion is
   "does it work with the router disconnected?", and it is tested **before** installing the second one.
3. **Degradation is a requirement.** With the platform down, the house is left in a safe state and
   operable by hand: lights switchable, locks openable, climate working with its thermostat.

**Second thesis: the cheap connected device is the weakest link in your network**, and not as an
opinion — it is a computer with an old Linux, embedded credentials and a vendor that will stop
publishing firmware before you throw it away. That is why §3.2 (segmentation) is not paranoia: it is the only
mitigation that keeps working when the vendor abandons the product.

**Not applicable**: see `homelab-standards` (**the server and the lab are theirs**: the hardware, the
hypervisor, Docker/Podman, the reverse proxy with TLS, the SSO in front of the applications, remote
access without opening ports, the UPS, the lab backup policy and the proportionality criteria.
**Clean boundary: where Home Assistant runs is theirs; which device enters the house, with which
protocol, and which automation is written, belongs here**), `embedded-iot-standards` (**building the
device is theirs**: silicon, RTOS, bootloader, OTA firmware update, per-device identity,
CRA/EN 18031. Here the device **as a product you buy and deploy**, and what
you do when its vendor stops updating it), `edge-computing-standards` (fleet of nodes and
A/B updates at scale; a house is not a fleet), `ot-ics-security-standards` (**industrial
building, BMS, KNX/BACnet in a professional installation, personal safety in a physical process**:
theirs. A single-family home belongs here; a building with contracted maintenance and certified
safety systems, theirs), `networking-standards` (**network design, VLANs, addressing,
routing, mDNS across segments**: theirs) and `firewall-policy-standards` (**the rule as an artefact**:
default-deny, flow matrix, lifecycle. **Here it is decided which segment exists and what has to be
able to talk to what; there the rule is written and governed**), `wireless-standards` (Wi-Fi, channels,
coverage and coexistence on 2.4 GHz — which is the real cause of half the Zigbee problems),
`dns-standards` (internal resolution, `home.arpa`), `vpn-standards` (remote access to the house: WireGuard,
Tailscale — **here only the prohibition on opening ports**), `privacy-engineering-standards`
(**minimisation, retention and rights are theirs**; here the decision of which sensor goes in which
room and what leaves the house), `backup-recovery-standards` (mechanics of the copy and restore
testing), `vulnerability-management-standards` (CVE triage), `observability-standards`
(telemetry as a platform), `local-inference-standards` (**serving a model locally**, if the
voice assistant uses an LLM: engine, quantisation and sizing are theirs),
`ai-agents-standards` (an agent that acts on the house: loop, caps and human approval),
`physical-security-standards` (certified alarm, professional access control, video surveillance with
legal obligations — **a home camera pointing at the public road stops being a domestic
matter**), `green-it-standards` (consumption and energy efficiency as a discipline).

## 2. Default decisions / Toolchain

> Verify the latest version, licence and status on the web before pinning them (§8).

### 2.1 Platform

| Platform | Licence (read raw) | When |
|---|---|---|
| **Home Assistant** | **Apache-2.0** (`LICENSE.md` of `home-assistant/core`) | **By default.** Largest integration catalogue, real local control, active community. As of Aug 2026: **2026.8**, released on **5-Aug-2026** |
| **openHAB** | **EPL-2.0** (`LICENSE` of `openhab-core`) | Mature JVM-based alternative; more formal rules, smaller community |
| **Node-RED** | **Apache-2.0** (`LICENSE`) | **Complement, not substitute**: visual flows for complex or integration logic, alongside HA |
| **Zigbee2MQTT** | **GPL-3.0** (`LICENSE`) | Zigbee → MQTT bridge independent of the hub. As of Aug 2026: **2.13.0** (1-Aug-2026) |
| **ESPHome** | **Dual and by file extension**: its own `LICENSE` says that *"The ESPHome License is made up of two base licenses: MIT and the GNU"* — **GPLv3 for the C++/runtime code** (`.c`, `.cpp`, `.h`, `.hpp`, `.tcc`, `.ino`) and **MIT for the rest** | Own devices and **recovering devices from abandoned vendors** by reflashing them |

**Home Assistant's cadence, which is an operational commitment**: **one major per month** (`YYYY.M`) and
weekly patches —the 2026.8 note says it: *"Our goal is to release a patch release once a
week, aiming for Friday"*—, and **every release brings a *"Backward-incompatible changes"* section**
in which the project itself acknowledges that *"sometimes it is inevitable"*. Consequences:

- **Reading the release notes before updating is not optional**, and that is the only moment when
  the system warns you that an integration is going to stop working.
- **Do not update on release day.** Wait for the first patches unless the update
  closes a vulnerability.
- **Never update without a recent and tested backup** (§7.1).
- Deprecations are announced with **more than a year of lead time** on the developer blog (as of
  Jul 2026, several pointed to Core 2027.7/2027.8). That lead time exists for you to use it, not for you
  to ignore it.

**Installation**: as of Aug 2026 the official documentation presents **Home Assistant OS** (with apps/add-ons,
one-click updates and backups) and **Home Assistant Container** (you bring the system and manage
the updates), and warns that *"Home Assistant Container installations don't have access to
apps"*, which leaves out app-controlled integrations such as **Thread and Z-Wave**. If you are going to use
Thread or Z-Wave, **that sentence decides your installation method**. (Verify §8: the catalogue of methods
and its naming have changed.)

### 2.2 Protocols

| Protocol | Band / topology | Verdict |
|---|---|---|
| **Zigbee** | 2.4 GHz, mesh | **Default option** for sensors and lights. Cheap, local, huge ecosystem. **It collides with Wi-Fi on 2.4 GHz**: choosing the channel is mandatory, not optional (§6.2). Mains-powered devices act as repeaters; battery ones do not |
| **Z-Wave** | Sub-GHz (868 MHz in Europe), mesh | Less interference and better penetration; smaller catalogue and **more expensive**. A good choice for locks and critical sensors. Z-Wave Long Range for range |
| **Thread** | 2.4 GHz, IPv6 mesh | **Transport, not ecosystem**: it needs a *border router* and, in practice, Matter on top. Current spec **1.4.1** (verify §8) |
| **Matter** | Over Thread, Wi-Fi or Ethernet | **The smokiest area in the sector.** See §2.3 |
| **Wi-Fi** | 2.4/5 GHz, star | Only with **local firmware** (ESPHome, Tasmota, WLED) or documented local control. **Every Wi-Fi device is one more client saturating the network and one more point of presence on your LAN** |
| **BLE** | 2.4 GHz | Proximity sensors and beacons; short range, needs *proxies* spread around |
| **Proprietary RF 433/868 MHz** | Point to point | Cheap and **with no security whatsoever**: most are fixed codes, clonable with €20 hardware. **Never for locks, garages or alarms** |
| **KNX / wired** | Wired bus | Professional installation, far superior reliability, cost and building work. In a full refurbishment, the best option for what must not fail |

### 2.3 Matter: what actually works

Matter solved the problem of **commissioning** and of basic **interoperability** between
ecosystems (Apple, Google, Amazon, Samsung), and that achievement is real: a Matter device is
commissioned with a QR code and can be shared with several controllers (*multi-admin*). What it did **not**
solve, and is worth saying before buying:

- **Device type support goes by specification version, and your controller lags
  behind.** As of Aug 2026 the CSA publishes up to **Matter 1.6** (with 1.5.1, 1.5 and the 1.4 series still
  available). That the spec supports a category **does not mean** your app or your hub support it.
- **The vendor's advanced features remain outside Matter.** The device works for the
  basics and for everything else it asks for its app —and its cloud—. Buying Matter does **not** free you from the vendor.
- **Matter over Wi-Fi is not guaranteed local control**: local control belongs to the *fabric*, but the
  device can keep talking to its cloud in parallel. It is checked at the firewall (§3.2),
  not in the brochure.
- **Thread needs a *border router*** and having several from different vendors has been, repeatedly,
  a source of network problems. One properly placed is worth more than three scattered around.
- **Practical rule**: Matter is excellent for **standardising commissioning** and for not being
  tied to one ecosystem. **Do not buy it for what is announced; buy the device that already works today
  with your controller**, and verify it in the compatibility list before paying.

## 3. Structure and conventions

### 3.1 Configuration as code

- **All configuration in Git**, with `secrets.yaml` **outside** the repository (or encrypted with
  SOPS/`git-crypt`). Without this there is no diff, no revert and no rebuild.
- **Stable naming convention, by function, not by brand**:
  `<domain>.<floor>_<room>_<function>` (`light.gf_living_main`). The vendor's identifiers
  change when the device is replaced; the functional name does not. **Renaming entities afterwards
  breaks every automation that cites them**, so it is decided on day one.
- **Areas, devices and labels** properly set: they let you write automations by zone
  instead of by list of entities, which is what survives a bulb change.
- **Templates and complex logic outside the automation** (scripts, *blueprints*, or Node-RED if
  the flow calls for it). An automation with 60 lines of Jinja2 is code without tests.

### 3.2 Network: segmentation is a requirement

- **Its own VLAN for IoT**, no exceptions, with **default-deny** towards the trusted network. Network
  design and rule: `networking-standards` and `firewall-policy-standards`. Here, the flows that must be
  allowed and nothing more:
  - IoT → controller (HA/MQTT): **only the necessary ports**.
  - Controller → IoT: what is needed for control.
  - IoT → internet: **egress filtering**, and by default **blocked**. Many devices
    work perfectly without egress; for those that do not, document where they go and why.
  - Trusted → IoT: initiated from the trusted side, not the other way round.
- **Discovery (mDNS/SSDP) does not cross VLANs by itself**: an mDNS reflector/proxy scoped to
  the specific services is required. Opening the reflector "for everything" cancels out the segmentation.
- **Isolated guest Wi-Fi** and **a different PSK for the IoT SSID**. A compromised device
  must not be able to see the NAS.
- **Remote access: never by opening ports.** VPN (WireGuard/Tailscale) or outbound tunnel. **FORBIDDEN
  to publish the controller's interface on the internet**, with or without a password.
- **Blocked egress is also the mitigation for the abandoned device** (§7.2): when the
  vendor stops patching, the device will keep working locally and can neither be reached nor
  phone home.

### 3.3 Robust versus fragile automations

The difference between a house that helps and one that punishes:

- **Trigger on state, not on event.** An event is lost if the platform was restarting; the
  state gets re-evaluated. Rule: **the goal of an automation is that the world ends up in the
  desired state**, not that an action is executed. After a restart, the system must converge.
- **Idempotence**: running the automation twice produces the same result. "Toggling"
  (*toggle*) is the antipattern: if an event is lost, the state stays inverted forever.
- **Explicit conditions for human override.** If somebody turned the light on by hand, the
  automation does **not** turn it off five minutes later. A presence sensor with a timer that
  ignores the manual action is the number one reason people uninstall home automation.
- **No values coupled to the clock time** when what matters is the light or the presence:
  use the sensor, not the time.
- **Test sensor failure**: what does the automation do if the presence sensor has gone 6 hours
  without reporting because its battery ran out? The right answer is almost never "assume there is
  nobody there".
- **One change, one automation.** Several automations writing to the same entity
  produce oscillations that nobody diagnoses. If there are two, there is a third that arbitrates.

### 3.4 The household failure that does matter

It is not the light that does not turn on. It is this, and each one carries a design barrier:

| Failure | Mandatory barrier |
|---|---|
| **Somebody locked in or out** | A lock with a **working physical key** always. Never an automation that throws the bolt without a verified presence condition. Manual opening from inside, without electricity |
| **In the dark** | Emergency lighting or at least one light per floor outside automatic control. Never "turn everything off" without exceptions for an occupied room |
| **No heating / no cooling** | The thermostat keeps its own logic and its limits; the controller **suggests**, it does not govern. **Minimum anti-freeze floor** and maximum ceiling, enforced in the thermostat, not in the automation |
| **Pump, irrigation or valve stuck open** | Safety timer **in the device**, not in the software. Flow meter or cut-off by maximum time |
| **Alarm / smoke / CO** | **Certified standalone detectors, mains- or battery-powered**, independent of the home automation. Home automation **notifies**; it is not the detection system |
| **Power cut** | The state after power is restored is **decided**: each relay configured to "last state" or "on" according to the load. A freezer behind a socket that starts up off is an expensive failure |

## 4. Quality and testing

Scaled to what it is —a house, not a bank—, but these five are not skipped:

1. **Configuration validation before reloading** (`hass --script check_config` or equivalent) and
   a YAML linter. A badly indented YAML leaves the system unable to start.
2. **Manual test of every new automation, including the error path**, before calling it
   good. And **a restart test**: reload the platform and check that the state converges.
3. **Test instance** for big changes (major update, change of Zigbee
   integration, coordinator migration). With Home Assistant it is a backup restored into a VM: cheap and
   it saves you the lost weekend.
4. **Restore tested, not just backup taken** (§7.1). A backup that has not been restored does not exist →
   `backup-recovery-standards`.
5. **Review of the release notes before each major update**, looking specifically for
   the incompatible changes section and the integrations you use.

## 5. Security and privacy

### 5.1 The house as attack surface

- **Segmentation (§3.2) first**; it is what keeps working when everything else fails.
- **Credentials**: a unique password per service, **MFA enabled on the controller**, and **separate
  accounts per person** — not one shared "house" account. Guests do not get the
  administrator's.
- **No ports open to the internet.** Neither the controller, nor the camera, nor the NVR, nor "just
  8123 with a good password".
- **Third-party integrations (HACS and equivalents) are unreviewed code running with the
  controller's permissions.** Install the minimum, from repositories with activity and with the
  licence read; keep them updated; and remove them when the author abandons them. It is a supply chain,
  even if it is your house's.
- **Updates**: controller and bridges (Zigbee2MQTT, ESPHome) up to date; device firmware
  too, **but one at a time and with the ability to roll back**, because a bad firmware can
  leave a device useless and many do not allow a *downgrade*.

### 5.2 Cameras, microphones and presence

This is the part of home automation that handles intimate data of people who **have signed nothing**:
housemates, minors, visitors, domestic staff.

- **Cameras: local recording (NVR/HA), no cloud by default.** If the model requires the cloud to work,
  it does not come in. Short and explicit retention.
- **No camera or microphone in bedrooms or bathrooms.** It is not a recommendation: it is the limit.
- **Consent and information for those who live there and those who visit.** And if a camera captures the public
  road or a common area, **it stops being a domestic matter** and enters legal obligations →
  `physical-security-standards`, `privacy-engineering-standards`.
- **Voice assistants: local whenever possible** (local voice processing, or your own model →
  `local-inference-standards`). If it is cloud-based, explicitly accept that **the audio of your living room
  leaves the house**, and place it where that is acceptable.
- **Presence detection is a record of a life**: who is at home, at what time, in which
  room. Keep the minimum and with bounded retention; **the infinite presence history is the most
  sensitive database in the house** and almost nobody treats it as such.
- **Vendor cloud accounts**: before creating one, the question is what it takes with it. If the vendor
  disappears, the account takes the device with it — another reason to demand local control.

## 6. Performance and operability

### 6.1 Latency and perceived reliability

**The bar is the wall switch: under ~200 ms from the press to the light, or
people go back to the switch.** A physical remote that goes through Zigbee → bridge → MQTT → automation →
Zigbee and on top of that goes out to the cloud does not make it. **Direct binding** (Zigbee *binding*, Z-Wave
association) between remote and light wherever it exists: it works even with the controller switched off, which is
precisely the requirement of §1.

### 6.2 Radio

- **Zigbee channel chosen so as not to overlap with the 2.4 GHz Wi-Fi channel**, and documented. This single
  setting resolves most of the "sometimes it does not respond".
- **Zigbee coordinator kept away from the computer with a USB extension cable** and away from USB 3.0 and power
  supplies: USB 3 interference on 2.4 GHz is real and baffles people for months.
- **The mesh is held up by the mains-powered devices**, not the battery ones. A house with only battery
  sensors does not have a mesh, it has a star with bad range.
- **Record of the coordinator and its firmware**, and **a backup of the Zigbee/Z-Wave network** (network keys): without
  it, changing coordinator means pairing every device again, one by one, up a
  ladder.

### 6.3 Proportionate monitoring

What has to be monitored in a house is short and concrete:

- **Low battery** on each sensor, with a threshold and a warning with lead time.
- **A device that has gone N hours without reporting** — that is the warning of a dead sensor, and without it the
  automation keeps "working" with yesterday's data.
- **Controller down** (warning from outside the controller itself; if it warns itself, it does not warn).
- **Power cuts and UPS status** → `homelab-standards`.
- **The most recent backup and its age.**
- Everything else is optional. A panel with 200 graphs at home is a hobby, not observability.

## 7. Long-term sustainability

### 7.1 Backup and rebuild

The question that orders this section: **if the controller's disk dies today, how long until you have
the house working again?** If the answer is "a weekend", the design has failed.

- **Automatic and periodic backup**, **off the machine itself** (domestic 3-2-1: local + NAS + off-
  site, encrypted) → `backup-recovery-standards`.
- **Include what is not in the YAML**: the database if you care about the history, Zigbee/Z-Wave
  network keys, `secrets.yaml`, ESPHome configurations, Node-RED *flows*, and the device
  inventory.
- **Restore tested at least once a year** in a VM. It is the only way to know whether the backup
  is any good.
- **One-page rebuild document**: what hardware, what gets installed, in what order, where
  the keys are. Written for somebody who is not you —including the case where you are not around—.

### 7.2 The device the vendor abandons

It always happens, and the plan is made before buying, not afterwards:

- **Purchase criteria**: does it work without the cloud? can it be integrated locally? is it reflashable
  (ESPHome/Tasmota)? is there a community? A device that fails all four is rented, not bought.
- **When the vendor abandons it**, in this order: (a) reflash with free firmware if the
  hardware allows it; (b) keep it **with no internet egress** and controlled locally; (c)
  replace it. **What is not done is leaving it plugged in, with unpatched firmware and with access to
  the internet.**
- **Segmentation with blocked egress (§3.2) is what turns (b) into a defensible option**, and
  that is why it is set up from the start, not when the bad news arrives.

### 7.3 Prohibitions

- ❌ **FORBIDDEN** to remove or disable the manual control of any load.
- ❌ **FORBIDDEN** for a basic household function (light, lock, climate) to depend on the internet or on
  a vendor's cloud.
- ❌ **FORBIDDEN** IoT devices on the same VLAN as computers, NAS or phones.
- ❌ **FORBIDDEN** to expose the controller, a camera or an NVR directly to the internet, with or without a
  password; remote access goes over VPN or a tunnel.
- ❌ **FORBIDDEN** to allow internet egress by default from the IoT VLAN.
- ❌ **FORBIDDEN** proprietary 433 MHz RF with a fixed code on locks, garages or alarms.
- ❌ **FORBIDDEN** cameras or microphones in bedrooms and bathrooms; and forbidden to install them without informing
  those who live there.
- ❌ **FORBIDDEN** to keep presence history without a defined retention.
- ❌ **FORBIDDEN** to update the platform without reading the incompatible changes and without a recent backup.
- ❌ **FORBIDDEN** to update the firmware of several devices at once.
- ❌ **FORBIDDEN** automations based on *toggle* or on non-re-evaluable events.
- ❌ **FORBIDDEN** an automation that throws the bolt, turns off all the lights or cuts the heating
  without a presence condition and without a safety limit in the device itself.
- ❌ **FORBIDDEN** to entrust smoke, CO or intrusion detection to home automation: certified standalone
  detectors, and home automation only notifies.
- ❌ **FORBIDDEN** to leave on the network a device abandoned by its vendor with internet egress.
- ❌ **FORBIDDEN** a configuration that is not in Git, and forbidden `secrets.yaml` inside the
  repository.
- ❌ **FORBIDDEN** to accept a backup that has never been restored.
- ❌ **FORBIDDEN** to buy on the "Matter" label without checking that **that** device works
  with **your** controller today (§2.3).

## 8. Mandatory web verification

- **Home Assistant**: current version and its **incompatible changes** (as of Aug 2026, **2026.8**, of
  5-Aug-2026; monthly majors and weekly patches on Fridays). Developer blog for
  announced deprecations. **Current installation methods and their naming**, which have changed:
  as of Aug 2026 the official page presents **OS** and **Container**, and warns that Container **does not have
  access to apps**, which affects **Thread and Z-Wave**.
- **Licences read raw** (`LICENSE`, `LICENSE.md`, `COPYING`; watch out for `master` versus `main`).
  Verified for this document: Home Assistant **Apache-2.0**, openHAB core **EPL-2.0**, Node-RED
  **Apache-2.0**, Zigbee2MQTT **GPL-3.0**, and **ESPHome with a dual licence by file extension**
  (MIT + GPLv3 for the C++/runtime code) — if you are going to redistribute anything derived, that is the one you
  have to read in full.
- **Matter**: version of the specification published by the CSA (as of Aug 2026, **1.6** available alongside
  1.5.1, 1.5 and the 1.4 series) **and, separately, which version your controller implements**. They are not
  the same and that difference is the source of the smoke.
- **Thread**: current version of the specification (as of Aug 2026, **1.4.1**) and compatibility of your
  *border routers*.
- **Zigbee**: core revision (as of Aug 2026 the CSA publishes **R23.2**) and recommended firmware for your
  coordinator.
- **Zigbee2MQTT / ESPHome**: current version (Zigbee2MQTT **2.13.0**, 1-Aug-2026) and compatibility with
  the Home Assistant version before updating either of the two.
- **End of support for devices and vendor services**: actively search whether the vendor has
  announced a service shutdown or end of firmware, **before** buying and **at least once a year**
  afterwards.
- **CVEs** of the controller, of the bridges and of the device models installed →
  `vulnerability-management-standards`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
