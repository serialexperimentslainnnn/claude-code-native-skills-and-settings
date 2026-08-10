---
name: server-hardware-standards
description: Choosing, sizing, securing and retiring physical servers. Use when specifying or reviewing a server BOM (socket count, DDR5 memory channels and DIMMs per channel, RDIMM versus MRDIMM, NUMA nodes and node-per-socket settings, PCIe Gen5 lanes and x8/x8 or x4/x4/x4/x4 bifurcation, drive bays, SAS expander versus direct-attach backplane, U.2/E3.S form factors, redundant PSUs on separate circuits, OCP NIC 3.0 slots), operating out-of-band management (iDRAC, iLO, XCC, BMC, ipmitool, Redfish ComputerSystem and UpdateService, KVM over IP, virtual media, serial-over-LAN, IPMI cipher zero, default BMC credentials, BMC firmware CVEs such as CVE-2024-54085 in AMI MegaRAC), managing firmware and BIOS as code (fwupd and LVFS, fwupdmgr, UEFI capsule updates, Dell DSU and Repository Manager, HPE SPP and iLO, Lenovo XCC, firmware signing and rollback), deciding RAID controller versus HBA in IT mode for ZFS or Ceph, picking drives by interface and endurance (SATA, SAS, NVMe, TBW, DWPD, SMART attributes and what they actually predict), sizing warranty and support contracts (next-business-day versus 4-hour onsite, post-year-3 renewal cost, spare parts pools), buying refurbished or second-hand enterprise gear, deciding when to refresh hardware on power draw versus on failure rate, or comparing buy versus lease versus cloud on cost.
---

# Server hardware standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **the iron as an engineering decision**: what is bought and why (§3), how it is accepted before
being put into production (§4), how its out-of-band plane and its firmware are managed without opening a
hole (§5), and how long it is kept, with what contract and with what renewal criterion (§6).

**Guiding principle**: **a server's bottleneck is almost never the processor's
frequency.** It is badly populated memory, ignored NUMA, the shared PCIe lane, the *backplane*
that does not reach all the bays or the single power supply. **Second principle, and it is the one that prevents the most
incidents: the BMC is a complete computer with total access to the server, running outside the control
of the operating system. It goes on an isolated management network. No exceptions.**

Triggers: server tender or BOM, "how much RAM do I put in it?", memory channels, DIMM per channel
(1DPC/2DPC), RDIMM/MRDIMM, NUMA / NPS, PCIe Gen5 lanes, x8/x8 or x4/x4/x4/x4 bifurcation, U.2/E3.S
bays, *backplane* with SAS expander, OCP NIC 3.0, redundant power supplies and separate circuits,
`ipmitool`, `racadm`, `ilorest`, `sum`, Redfish (`/redfish/v1/Systems`, `UpdateService`), KVM over
IP, virtual media, SOL, `cipher zero`, `fwupdmgr`, LVFS, UEFI capsule, Dell DSU/Repository Manager,
HPE SPP/iLO, Lenovo XCC, "hardware RAID or HBA?", IT mode, `smartctl`, TBW, DWPD, NBD versus 4h,
"renew the support contract", "second-hand server", "buy or cloud?".

**Not applicable**: see `onprem-standards` (**platform umbrella and routing table §1.2**: the fleet
as a whole, the choice of hypervisor and its invariants; **here the individual machine and its
component**), `datacenter-facilities-standards` (**everything outside
the chassis** —rack, PDU, circuits, UPS, cooling, hot/cold aisle, density per rack,
physical receiving and disposal—. Boundary in one line: *if it is bolted to the rack but not inside the
server, it is theirs*), `cmdb-inventory-standards` (**the asset record**: serial number as a
stable identifier, warranty, contract and lifecycle status are **stored there**; here what they
mean), `os-provisioning-standards` (installing the OS on this iron; **there Redfish/IPMI as a
boot trigger, here the BMC as a system to protect**), `linux-storage-standards`
(multipath, LVM, I/O schedulers, `nvme-cli`, the filesystem) and `zfs-standards` (**pool topology,
`ashift`, ARC, scrub**; here only why ZFS demands an HBA in IT mode and not a RAID controller),
`ha-clustering-standards` (service redundancy; here redundancy inside the chassis),
`backup-recovery-standards` and `bcdr-standards` (**hardware failure as a recovery
scenario**: real RTO = spare part time + restore time), `networking-standards` and
`datacenter-fabric-standards` (**the switch, the link and the management VLAN**; here only the NIC and the
requirement that this VLAN exists), `linux-hardening-standards` (OS baseline; **firmware and the
BMC belong here**), `vulnerability-management-standards` (triage of firmware CVEs with
CVSS/EPSS/**KEV**), `green-it-standards` (footprint and reporting, and the criterion that **extending the
service life usually weighs more than optimising consumption**), `finops-standards` (cloud cost),
`homelab-standards` (**economics of used *enterprise* gear**), `gpu-computing-standards` and
`high-speed-interconnect-standards` (accelerators and InfiniBand/RoCE), `hpc-standards`
(compute node and density), `macos-fleet-standards` and
`developer-workstation-standards` (the desk, not the server).

## 2. Default decisions

> Verify model, firmware version and compatibility matrix on the web before committing to anything (§8).

| Decision | Default | Reason / justifiable alternative |
|---|---|---|
| No. of sockets | **1 socket** unless there is measured justification | A modern socket reaches densities that five years ago required two, and **avoids the whole NUMA problem at the root**. Two sockets only if you need the memory or the PCIe lanes, not "just in case" |
| Memory population | **All channels populated, 1 DIMM per channel** | It is the memory decision that decides the most performance, above frequency. Half populated = proportionally lost bandwidth. **2DPC lowers the negotiated speed**: if you need capacity, larger DIMMs before more DIMMs |
| Out-of-band management | **BMC on an isolated management VLAN**, unique account per host, **Redfish** to automate | `ipmitool` only for what Redfish does not cover. **IPMI/LAN is disabled if Redfish is enough** (§5) |
| Local storage | **NVMe** (U.2/E3.S) for hot data; SATA/SAS only for capacity or for an existing array | The cost per IOPS of NVMe no longer justifies SAS in new servers |
| Controller | **HBA in IT mode** (pass-through) if the consumer is ZFS, Ceph or the OS itself | **Hardware RAID** only with mirrored boot or a legacy array. The RAID controller with cache and battery is a SPOF with its own firmware, and **hides SMART from the OS** |
| Power supplies | **2 PSUs, on different electrical circuits**, sized so that **a single one can carry the load** | Two power supplies on the same power strip are not redundancy: they are two power supplies. The circuit is set by `datacenter-facilities` |
| Network | **OCP 3.0 NIC + one PCIe** to separate failure domains | Dual port on the same NIC does not protect against NIC failure |
| Firmware | **As code**: vendor catalogue pinned by version, applied in a window, with `fwupd`/LVFS where there is coverage | **Verify the real coverage**: LVFS is strong on client and workstation; **server firmware still comes mostly from the vendor channel** (iLO/SPP, DSU, XCC) |
| Warranty | **NBD** by default; **4h onsite** only where the committed RTO is not covered by your own spare | The cheap and often better alternative: **your own spare parts stock + N+1**, which additionally works out of hours and without depending on the vendor |
| Purchase | **Buy** when the load is stable, predictable and with a life ≥ 4 years | **Cloud** for the elastic and uncertain; **rental/leasing** when the problem is cash flow or the forced renewal cycle, not the total cost |

## 3. Sizing: where performance is lost

- **Memory and channels**. Current platforms have **many channels** (as of Aug 2026, AMD EPYC
  9005 "Turin" declares up to **12 DDR5 channels per socket**; general-line Xeon 6 uses **8 channels**
  and compensates with **MRDIMM** at higher speed). The expensive mistake is buying 4 large DIMMs on a
  12-channel platform: you pay for the whole CPU and use a third of its bandwidth. **Populate
  all the channels, at 1DPC, with identical modules** and check in the vendor's population table
  the resulting negotiated speed, which depends on the model and the module's rank.
- **NUMA**. With two sockets —or with NUMA partitioning inside a socket (NPS)— **memory latency
  depends on where the process runs**. Practical consequence: size the VM or the
  container so that it **fits inside one NUMA node**, and if it does not fit, know that you are paying for the
  crossing. Setting affinity is the hypervisor's business (`libvirt-kvm`, `proxmox-ve`, `vmware`); here the
  decision **not to create the problem when buying**.
- **PCIe: lanes are finite and get shared out**. Before signing a BOM, add up the lanes that
  NIC, HBA, NVMe and accelerators ask for and compare them with those the socket exposes. Two frequent
  traps: **a physically x16 slot wired to x8** (or fed from the second socket, which
  disappears in a single-socket configuration) and **bifurcation**, which the BIOS must support
  —x8/x8 or x4/x4/x4/x4— for a carrier card with several NVMe to work. It is verified in
  the board manual, it is not assumed.
- **Bays and *backplane***. The number of bays says nothing on its own: what matters is **how they are
  cabled**. A *backplane* with a SAS expander shares bandwidth between bays; a direct-attach one
  does not. And **the NVMe bays are usually a subset** of the total bays: "24 bays" may
  mean 8 NVMe and 16 SAS. Always ask for the cabling diagram.
- **Drives and endurance**. Choose by **DWPD/TBW against the real measured daily write**, not by
  commercial category. A read-intensive SSD under a database journal or under Ceph
  wears out in months. **Deliberately mixing models and batches** within a redundant group reduces
  the risk of correlated failure from a manufacturing defect.
- **SMART predicts less than people think, and this is measured.** Google (Pinheiro, Weber &
  Barroso, *Failure Trends in a Large Disk Drive Population*, USENIX FAST '07; 100,000 drives, 5
  years) found that **more than 56 % of the drives that failed had no count in the
  four strong SMART signals** (scan errors, reallocations, offline reallocations and
  probational count), and that **36 % had no SMART signal at all**. Correct reading:
  **SMART with counters is a good reason to replace the drive; clean SMART is no guarantee of
  anything.** The design is done with redundancy and verified copies, not with prediction. (The study is
  of mechanical drives from 2007; for SSDs the useful signals are others —endurance consumed, reserved
  blocks, uncorrectable errors— but the structural conclusion holds.)

## 4. Acceptance of the iron before production

> *(Takes the place of "quality and testing" in the format: there is no toolchain to pin, but there is a gate.)*

No server enters production without passing, and with archived evidence:

1. **Inventory and firmware**: serial number recorded (`cmdb-inventory-standards`), firmware of
   BIOS/BMC/NIC/HBA/drives **brought to the fleet's reference level** before installing anything.
   Starting with factory firmware is starting with debt.
2. **BIOS configuration applied from the fleet profile**, not by hand through menus: power profile,
   NPS, SR-IOV, Secure Boot, watchdog, boot order. Exportable and comparable.
3. **24–72 h burn-in** with memory, CPU and disk load, **with the chassis in its final rack and
   at real ambient temperature**. Infant mortality is real and is far cheaper to find
   here than in production.
4. **Physical redundancy test**: **a power supply is unplugged** with the server loaded, and a
   network link is disconnected. An untested redundant path is not known to exist.
5. **OOB plane test**: remote console, virtual media, power on/off and **forced boot
   via Redfish**, from the bastion. It is what you will use at 3 in the morning.
6. **Baseline of power draw and temperature** recorded. Without it you will not be able to decide
   renewal on consumption (§6) nor detect a cooling degradation years later.

## 5. Security: the BMC and the firmware

**Hard rule, the most important in this skill: the BMC is never exposed.** Dedicated management network, with no
route to the internet or to the user network, reachable only from a bastion with MFA. The BMC boots
before the operating system, survives its reinstallation, sees memory and keyboard, and **no
OS control protects it**. Compromising it is compromising the server persistently and
invisibly.

- **Verified case, and that is why the rule is hard**: **CVE-2024-54085** in AMI **MegaRAC SPx**
  —BMC firmware present in servers from multiple vendors—, **CVSS 10.0**, complete bypass
  of authentication in the Redfish interface by manipulating HTTP headers; it allows remote control of the
  server, malware deployment, firmware manipulation and even bricking the board. **CISA
  added it to its KEV catalogue on 25-Jun-2025** (first BMC flaw to enter KEV), with a remediation
  deadline of 16-Jul-2025. It was discovered by Eclypsium while analysing the fix for an earlier
  2023 flaw (CVE-2023-34329): **the vendor's second attempt was also bypassable**.
- **Credentials**: unique per host, generated and stored in the secrets manager, **never shared
  between hosts nor the factory one**. Accounts per person/service with minimum role, not a common
  `admin` account. Revocation tied to the asset's decommissioning.
- **Protocols**: **disable IPMI over LAN if Redfish covers your automation**. IPMI drags along
  known design problems (among them `cipher zero` and the exposure of password hashes
  via RAKP) and is not going to be fixed. If it must stay, restricted by source and with `cipher zero`
  disabled.
- **Signed firmware with rollback**. Only vendor firmware, verified by signature. Devices
  with **dual bank** allow rollback and are preferable. A failure during the
  update leaves a brick: it is updated in a window, with an OOB console open and one machine
  of the HA pair out of service, never en masse and never on both at once.
- **Firmware patching cadence, written down**: **quarterly** review of the vendor catalogue
  for BIOS/NIC/HBA/drives, and **out of cycle on any BMC CVE** —especially if it enters
  **KEV**, which is the signal of real exploitation (triage in `vulnerability-management-standards`).
- **Tooling**: `fwupd`/LVFS when the vendor publishes there (metadata signed with JCat,
  mandatory verification on every refresh, and `ApprovalRequired` to approve only what has been tested). But
  **verify the coverage for servers**: the bulk of server firmware is still distributed
  through the vendor channel (Dell DSU/Repository Manager, HPE SPP/iLO, Lenovo XCC).
- **Secure Boot and the 2026 calendar**: Microsoft's 2011 CAs are expiring (KEK CA 2011
  expired on **27-Jun-2026**; Windows Production PCA 2011 expires in **October 2026**). **Check whether
  your server model has firmware with the 2023 CAs**: if the vendor no longer publishes it, that
  chassis has in effect entered its retirement phase, whatever you decide (§6).
- **End of life of the server**: **destruction or certified erasure of the drives** —and of the non-volatile
  memory of the BMC and of the RAID controller cache, which almost nobody wipes—. Factory reset
  of the BMC before the chassis leaves the building.

## 6. Lifecycle: warranty, spares and when to renew

- **The warranty is an RTO decision, not a peace-of-mind one.** Calculate the real RTO of a component
  failure: `detection time + contractual response time + replacement time +
  restore time`. A 4h contract is worth nothing if the data takes six hours to restore,
  and NBD is more than enough if you have N+1 and the service moves by itself. **What almost always wins on cost and on
  time: buying the critical spare (power supply, drive, fan, DIMM) and keeping it in the cupboard.**
- **Years 4 and 5 are where the contract gets expensive.** Renewal after the initial
  warranty usually costs per year an increasing fraction of the equipment's value, while the residual
  value falls. Rule: **every support renewal is compared in writing against (a) replacing the
  equipment and (b) self-insuring with spares and N+1.** If there is no such dated comparison, it is not
  signed. *(Concrete figures: they come from your quote, not from here — no vendor publishes rates.)*
- **When to renew: two different clocks and you have to look at both.**
  - **By failure**: when the failure rate rises, the spare part can no longer be obtained through the official channel, or
    the vendor stops publishing firmware (including the Secure Boot case in §5). **A server
    without new firmware is a server without security patches**, even if it powers on perfectly.
  - **By consumption**: the old equipment pays for itself in electricity and rack space when
    its performance per watt falls well behind. **Calculate it, do not quote it**: `(watts_old −
    watts_new × equivalent_units) × 8760 h × price_kWh × PUE_factor` against the cost of the
    new equipment. With expensive energy and high consolidation (several old machines into one new one) the
    payback can be 2–3 years; with cheap energy and a lightly loaded server, never. **The
    answer depends on your kWh price and on your consolidation ratio, and that is why there is no honest
    "renew every X years" rule.** And watch the counterweight from `green-it-standards`: the
    already embodied footprint of the existing equipment pushes the other way.
- **Second-hand**: legitimate and sometimes excellent —lab, non-production environments, reserve
  capacity, spares for a model you already operate—. Conditions for production: **spares
  available, firmware still published, and that it holds up nothing whose RTO is committed**. Verify
  before buying: power-on hours and drive cycles, absence of BMC licence
  locks (iDRAC Enterprise, iLO Advanced **are licensed and do not always transfer**), and
  transferable warranty status.
- **Buy versus rent versus cloud**: compare **total cost over 5 years** —equipment,
  support, energy, space, network, staff and cost of capital— against the equivalent cost in cloud
  **with the same utilisation profile**. The two symmetric mistakes: comparing the purchase price
  against the monthly cloud bill (ignores operations and depreciation), and comparing against a cloud
  sized for the peak (ignores elasticity, which is precisely what you pay for). **The decision is rarely
  global**: stable base in-house + peak in cloud almost always beats the pure extremes.

## 7. Sustainability and prohibitions

- ❌ **FORBIDDEN** to expose a BMC to the internet or to the user network; **FORBIDDEN** to leave factory
  credentials or to share BMC credentials between hosts (§5).
- ❌ Leaving IPMI over LAN enabled "just in case" when Redfish already covers the automation.
- ❌ Ignoring a BMC CVE because "it is on the internal network". The internal network is exactly where the
  attacker who is already in arrives; **KEV means real exploitation**.
- ❌ Buying a many-channel CPU and populating half the memory (§3).
- ❌ Accepting an x16 slot as good without checking its real cabling and the supported bifurcation.
- ❌ A RAID controller in front of ZFS or Ceph. **An HBA in IT mode is required.**
- ❌ Two power supplies on the same circuit and calling it redundancy.
- ❌ Putting a server into production without burn-in, without levelling firmware and **without having unplugged a
  power supply** (§4).
- ❌ Updating firmware simultaneously on both nodes of an HA pair, or without an OOB console open.
- ❌ Trusting clean SMART as proof of health, or SMART prediction as a substitute for
  redundancy and copies (§3).
- ❌ Renewing support without the written comparison against replacing or self-insuring (§6).
- ❌ Quoting "a server is renewed every N years" as a rule. It is calculated with your energy price and
  your consolidation ratio.
- ❌ Putting into production second-hand hardware whose vendor no longer publishes firmware.
- ❌ Retiring a chassis without certified erasure of drives, RAID cache and BMC configuration.
- ❌ Buying from a spec sheet without the *backplane* cabling diagram and the memory
  population table of the specific model.

## 8. Mandatory web verification

Before committing to anything, check on the web —and in the documentation of the **specific model**, not of the
family—, with a literal citation:

1. **Technical manual of the model**: memory population table (resulting speed by
   configuration and by rank), map of PCIe lanes per slot and per socket, supported bifurcation,
   and **the *backplane* cabling diagram** (which bays are NVMe and which hang off an expander).
   None of these data are written from memory.
2. **CPU platform**: number of memory channels, maximum speed per DPC and PCIe lanes of
   the current generation. As of Aug 2026: EPYC 9005 "Turin" up to **12 DDR5 channels** per socket; general-line
   Xeon 6 **8 channels** with the **MRDIMM** option at higher speed. **Declared gap: the
   measured bandwidth figures cited in the technical press (STREAM) were not checked against the
   original report**; do not use them for sizing without repeating the measurement.
3. **Redfish**: current version of the DMTF specification and of the *schema bundle* (as of Aug 2026,
   **release 2026.1**, specification **1.24.0**) and —what really matters— **which subset
   your vendor's BMC implements and in which firmware version**. The gap between the standard and
   the implementation is where automation breaks.
4. **Firmware security advisories** from the vendor and from the BMC supplier (AMI, Insyde), and the
   **CISA KEV catalogue** to know whether something is being exploited. Confirm that **CVE-2024-54085**
   is remediated at your firmware level (AMI-SA-2025003 and your vendor's equivalent advisory).
5. **Secure Boot**: availability of firmware with the 2023 CAs for your model (§5). If it does not exist,
   it is renewal data.
6. **`fwupd`/LVFS**: current version (as of Aug 2026, the **2.1.x** line) and **real coverage of your
   server model**. **Declared gap: it was not verified which vendors publish server firmware —not
   client— on LVFS**; the sources consulted indicate that HPE ProLiant still goes via iLO/SPP. Check it
   before designing your patching process around `fwupdmgr`.
7. **End of life of the model**: end-of-sale date, end-of-support date and **end of firmware
   publication** —they are three different dates and the third is the one that decides security—. And
   real availability of spares, which is channel data, not catalogue data.
8. **Prices**: no vendor publishes rates for support, extension or renewal. **No
   economic figure in §6 comes from this document: it comes from your quote and from your electricity bill.**
9. **Drives**: TBW/DWPD and warranty of the exact model (they vary between capacities in the same family) and
   whether the drive firmware is on your controller's compatibility list.

If the web contradicts this document, **the web wins** — flag the discrepancy.
