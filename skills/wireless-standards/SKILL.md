---
name: wireless-standards
description: Enterprise Wi-Fi as a designed radio system — site survey, spectrum and capacity, not just placing access points. Use when planning or reviewing a WLAN design, a predictive or validation site survey in Ekahau, Hamina or TamoGraph, AP placement and transmit power, channel plan and channel width (20/40/80/160/320 MHz), 2.4/5/6 GHz band selection, DFS and radar events, 6 GHz LPI and VLP power limits and AFC, Wi-Fi 6 (802.11ax), Wi-Fi 6E, Wi-Fi 7 (802.11be-2024) and multi-link operation, 802.11k neighbour reports, 802.11v BSS transition management and 802.11r fast BSS transition, band steering and sticky clients, minimum basic rate and disabling low data rates, RSSI and SNR targets, co-channel interference and airtime utilization, WPA2 versus WPA3-Personal SAE and WPA3-Enterprise, transition mode and RSN overriding, 802.1X with EAP-TLS or PEAP and server certificate validation on the client, hostapd.conf, wpa_supplicant.conf, FreeRADIUS eap.conf, guest SSID isolation and captive portals, WIDS/WIPS and rogue AP classification, controller versus cloud versus standalone AP management, or Wi-Fi complaints that turn out to be capacity, roaming or client driver problems.
---

# Enterprise Wi-Fi standards — designed by radio, operated by data

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **designing, validating and operating a corporate WLAN**: site survey, spectrum and
channel plan, capacity sizing, roaming, wireless authentication and encryption,
SSID segmentation, WIDS/WIPS, and management architecture (controller, cloud, standalone).

Triggers: "site survey", "survey", Ekahau/Hamina/TamoGraph/AirMagnet, "heatmap", "RSSI",
"SNR", "co-channel", "airtime", "DFS", "6 GHz", "AFC", "LPI", "VLP", 802.11ax/ac/be/bn,
"Wi-Fi 6E/7/8", "MLO", 802.11k/v/r/w, "band steering", "sticky client", "minimum basic rate",
WPA2/WPA3/SAE/OWE, 802.1X, EAP-TLS/PEAP/EAP-TTLS, `hostapd.conf`, `wpa_supplicant.conf`,
FreeRADIUS (`eap.conf`, `clients.conf`), "guest SSID", "captive portal", "rogue AP".

**Not applicable**: the catalogue already divides this up — `networking-standards` is the **trunk**
(VLANs, addressing, MTU, the OOB management plane) and **already delegates the depth**, while
`routing-switching-standards` owns the **wired campus**, port-based 802.1X, PoE, VRRP and
control-plane security, `datacenter-fabric-standards` owns the fabric, VXLAN/EVPN and
lossless Ethernet, and `network-automation-standards` the configuration-as-code of any
network device, access points included. Outward: **filtering what leaves the SSID belongs to
`firewall-policy-standards`**, **RADIUS as an identity service, the client certificate lifecycle
and the MDM that distributes it belong to `identity-access-management-standards`** (and
the PKI, to `cryptography-pki-standards`), the methodology for measuring and the load model to
`performance-engineering-standards`, metrics and alerts to `observability-standards`, the SLO to
`sre-practice-standards`, the reactive method to `network-troubleshooting-standards`, detection to
`detection-engineering-standards`, and the umbrella of `onprem-standards` (alongside
`datacenter-facilities-standards` and `hpc-standards`). Among the three
sisters of this batch: `wireless-standards` is the **access network**,
`load-balancing-standards` the **service network** and `high-speed-interconnect-standards` the
**compute network**; **the domain's mistake is applying the same criteria to all three**.

**Governing principle**: **a corporate Wi-Fi is designed with a site survey and operated with
data.** Putting up access points until "there is coverage" is not a design: it is a bet that is
paid for in tickets. The medium is shared, half-duplex and cannot be over-provisioned by buying more
bandwidth from the carrier.

## 2. Default decisions

> Verify on the web the generation, the IEEE number, the regulatory status and the version before
> committing to anything (§8).

| Decision | Default | Justifiable alternative / vetoed |
|---|---|---|
| Target generation | **Wi-Fi 6 / 6E (802.11ax)** as the floor; **Wi-Fi 7 (IEEE Std 802.11be-2024)** on refresh with a modern client estate | ❌ Buying Wi-Fi 7 expecting a gain with 802.11ac clients; **Wi-Fi 8 (802.11bn, UHR) is not deployable in 2026**: certification expected 2027-2028 |
| Main data band | **5 GHz**, and **6 GHz** where the estate supports it | 2.4 GHz **only** for IoT and legacy, always 20 MHz |
| Channel width | **20 MHz in high density; 40 MHz as the usual ceiling in 5 GHz** | 80 MHz only with demonstrably clean spectrum and low concurrency; ❌ 160/320 MHz in a dense office |
| Signal target | **≥ −67 dBm RSSI and ≥ 25 dB SNR** across the whole useful area, measured in 5/6 GHz | More demanding thresholds for real-time voice/video; ❌ designing by looking only at 2.4 GHz |
| Transmit power | **Low and uniform**, small cells, with headroom for the client to answer | ❌ Power at maximum: it creates asymmetric cells and sticky clients |
| Basic rates | **Disable the low rates** (1/2/5.5/11 Mbps and the lowest OFDM ones) and set the minimum basic rate | ❌ Leaving 1 Mbps enabled: every management frame consumes everyone else's airtime |
| Corporate security | **WPA3-Enterprise with 802.1X and EAP-TLS** (client certificate) | EAP-TTLS/PEAP with MSCHAPv2 only as a transitional measure and **with strict validation of the server certificate**; ❌ a shared corporate PSK |
| Security in 6 GHz | **WPA3 mandatory** and PMF (802.11w) mandatory in the band; no transition mode | ❌ Trying to extend a WPA2 SSID to 6 GHz |
| Legacy compatibility | **A separate SSID with a retirement date**, or *RSN overriding* (the Wi-Fi Alliance's compatibility mode) | WPA3 transition mode only with `Transition Disable` planned; it is vulnerable to downgrade |
| Roaming | **802.11k + 802.11v enabled**; **802.11r (FT)** when the estate tolerates it | ❌ Enabling FT blindly on a heterogeneous estate with no test window |
| Guests | **An isolated SSID on its own VLAN**, client-to-client isolation, filtered egress, **OWE** or a portal over TLS | ❌ Guests on the corporate VLAN "with rules"; ❌ a guest PSK written on the wall with no expiry |
| Management | **Cloud or controller**, depending on who operates it and what WAN availability there is | Standalone APs only in 1-3 AP installations; ❌ a fleet with no central management and no inventory |
| Site survey | **Predictive to design + mandatory measured validation** | ❌ Predictive with no validation; ❌ "APoD" (*AP on a stick*) as the only methodology in new builds |

## 3. Design

**What each generation really brings — and what depends on the client**
- **Wi-Fi 6 (802.11ax)**: OFDMA, uplink MU-MIMO, BSS coloring and TWT. Its real value is
  **efficiency in density**, not peak speed. Almost all of it requires **the client** to implement
  it: an estate that is mostly 802.11ac gets no benefit from OFDMA even if the AP advertises it.
- **Wi-Fi 6E**: it is Wi-Fi 6 **in 6 GHz**. The value is clean spectrum with no legacy, not a new
  PHY.
- **Wi-Fi 7 (802.11be-2024)**: 320 MHz channels, 4096-QAM and **MLO** (multi-link). The only one of
  the three that changes the design is MLO, and **only if the client supports it and in the mode it
  supports** (many do link switching, not simultaneous aggregation). 320 MHz is inapplicable with the
  480 MHz of the lower 6 GHz band in the EU.
- **Rule**: the ceiling is set by **the worst relevant client**, not by the AP's datasheet. Before
  justifying a purchase, inventory the estate: spatial streams, bands and driver status.

**Spectrum**
- **2.4 GHz**: 3 non-overlapping channels (1/6/11), non-Wi-Fi noise (Bluetooth, microwaves,
  lighting). It is a compatibility band, not a capacity one.
- **5 GHz**: the working band. It includes sub-bands subject to **DFS**, where the AP must vacate the
  channel on radar detection: with radar nearby (coast, airports, weather) **exclude DFS
  from the plan**, and verify which sub-bands are indoor-mandatory in your jurisdiction (§8).
- **6 GHz**: in the **EU** only the **lower band, 5945-6425 MHz** (480 MHz) is harmonised, with
  **LPI limited to 23 dBm EIRP and indoor use** and **VLP** (portables, ~14 dBm EIRP) also permitted
  outdoors. **There is no standard power with AFC in the EU**: that is what decides the design —
  6 GHz **does not cover outdoors or large warehouses** here, unlike the USA. In **Spain** the band
  was incorporated into the CNAF under the same European conditions. The **upper band (6425-7125
  MHz) is unresolved in the EU** (a mandate to CEPT, decisions expected 2026-2027, with the United
  Kingdom on a different track): **do not design counting on it**.
- **Why wide channels reduce capacity in density**: every doubling of the width **finds half the
  reusable channels** and spreads the same power over more spectrum (less SNR at the
  edge). Moreover, the clear-channel assessment is over the whole channel: **a single occupied
  20 MHz subchannel blocks the entire transmission**. More width raises one client's peak and lowers
  the building's aggregate.

**Size by capacity, not by coverage**
- **The domain's most common mistake**: designing until the map is green. Coverage is the
  trivial requirement; the one that fails is **capacity** — clients per radio, applications and their
  throughput, and above all **available airtime**.
- Method: a device census per zone (not a people census) → throughput per application → clients per
  radio as an explicit budget → the APs needed → **and only then** check that the coverage
  works out. If capacity governs, the result is more APs at lower power, not fewer APs at higher
  power.
- **Overlap and reuse**: enough overlap to roam and **minimum co-channel interference**;
  channel utilisation is the saturation metric —above sustained thresholds the problem is
  airtime, not signal. High density and high ceilings demand **directional antennas and
  control of vertical propagation**.

**Site survey**
- The **predictive** one (scale drawings, real materials, calibrated attenuations) is a
  **hypothesis**; the **measured validation** with the real AP and antenna, in the bands that will be
  used and with spectrum analysis for non-Wi-Fi interference, is the result. A design that has not
  been validated has not been delivered.
- Documented deliverable: the channel and power plan, locations with a reason, target thresholds, and
  the areas where it was accepted that they would not be met.

**Roaming**
- **The decision to jump is always taken by the client.** The network informs (**802.11k**, neighbour
  report) and suggests (**802.11v**, BSS Transition Management, optionally with *disassociation
  imminent*); **802.11r** only makes the jump **fast** once decided, by reusing cryptographic
  material. None of them compels.
- Consequence: **sticky clients** are not fixed on the AP, they are fixed **by removing reasons
  to stay** — small cells, low powers, high minimum rates and correct overlap.
- 802.11r is the one that breaks old estates most: deploy it per SSID and in phases, with a test
  window and a rollback plan.

## 4. Quality gates

- **Measured validation** against the thresholds of §2 before signing off an installation, in the
  real bands, with the typical client and with the real application (not just ping).
- **A roaming test with the critical application** (voice, terminal, scanner) walking the
  real route, measuring drops, not watching bars.
- **A negative isolation test**: from the guest SSID, verify that the corporate network is **not**
  reachable, nor is another client on the same SSID. A guest network tested only on the happy path
  has not been tested.
- **An AP failure test**: switch it off and check the residual coverage and capacity of its
  neighbours. If the design does not withstand it, it is either declared or it is wrong.
- **An authentication test**: a client with an expired, revoked or wrong-CA certificate **must
  be rejected**. If it connects, the 802.1X is decorative.
- **Config as code and diff**: the SSID, RADIUS and radio configuration lives in a repo and is
  applied by automation (`network-automation-standards`); an AP that differs from its peers is a
  finding.

## 5. Security

- **WPA3 by default**; WPA2-Personal is dead for corporate use (a shared PSK = a credential
  nobody can rotate or revoke per user). **SAE** eliminates the offline dictionary attack
  on the 4-way handshake and requires **PMF (802.11w)**.
- **WPA3/WPA2 transition mode is an announced downgrade**: while it exists, an attacker
  forces WPA2. If it is used, with a retirement date and `Transition Disable` planned; in 6 GHz it
  does not exist. For problematic clients, the **compatibility mode with RSN overriding** does not
  expose WPA2 to the capable ones.
- **802.1X/EAP with certificates (EAP-TLS)** rather than a PSK: identity per device/user,
  revocable, with no shared secret. With PEAP/TTLS there are still passwords in play.
- **The most common silent failure: the client does not validate the RADIUS server's certificate.**
  Without validation of the CA **and** of the server name, a fake AP captures corporate credentials
  and nobody notices. It is **client** configuration, not network configuration: it is distributed by
  MDM/GPO as a mandatory profile, manually "trusting" is forbidden, and it is verified in the §4
  gate. An 802.1X deployment without this is worse than useless, because it generates unjustified
  confidence.
- **Guests**: their own VLAN, client-to-client isolation, filtered and limited egress, with no route
  towards management or servers. A captive portal always over TLS with a name of its own; **OWE**
  encrypts the air with no credential but **does not authenticate**: do not sell it as an access
  control.
- **WIDS/WIPS**: useful for inventorying unauthorised APs and deauthentication attacks, but
  **it generates a lot of noise** and its automatic "rogue" classification includes legitimate
  neighbours. Radio containment is enabled only over what has been classified by hand and **never
  over third-party spectrum** (counterproductive and potentially illegal). With nobody to triage, it
  is not a control.
- **What is not a security control**: **hiding the SSID** (the name travels in the clients'
  requests and worsens their roaming) and **MAC filtering** (a MAC is spoofed with one command, and
  modern clients' MAC randomisation breaks the list anyway). Naming them as measures in a security
  document is a finding.
- APs are network devices: OOB management, no factory credentials, up-to-date firmware and **an
  access port with 802.1X** — an AP ripped off the wall gives access to its trunk.

## 6. Operation

- **It is measured with client data, not with theoretical heatmaps.** The signals that decide:
  channel utilisation and airtime per radio, SNR and MCS **per client**, retries, association and
  authentication failures by cause, roams and their duration, and DFS events. A green map with 80%
  utilisation is a network that is down.
- **Correlate with the application**: the complaint "the Wi-Fi is bad" is almost never the Wi-Fi.
  Rule out in order: airtime → client/driver → authentication/RADIUS → DHCP/DNS → WAN before touching
  the design.
- **Updates** of APs and controller in phases, with a window and a rollback; firmware
  changes alter roaming and radio behaviour. The cloud updates itself: **set a window
  and rings, or you will suffer them during working hours**.
- **Cloud management**: verify what happens when the WAN goes down (the APs must keep serving and
  authenticating: local RADIUS or a cache) and where the telemetry resides (personal data). **The
  radio is reviewed periodically**: the furniture, the density and the neighbours change; a channel
  plan from three years ago is no longer the plan.

## 7. Sustainability and prohibitions

- **Cadence**: AP and controller firmware quarterly and on an exploitable CVE; the AP
  estate planned by generations, with the manufacturer's end of support inventoried before it bites.
- **SSID rule**: few and with a written reason —each SSID emits beacons on every AP and in every
  band, so the list is an airtime budget, not a menu— and a retired SSID really disappears
  (configuration, RADIUS, documentation).

**FORBIDDEN**
- ❌ Deploying APs without a site survey, or delivering a predictive survey with no measured
  validation.
- ❌ Designing by coverage when the requirement is capacity; "more power" as the solution.
- ❌ Channels of 80 MHz or more in a dense environment; 40 MHz in 2.4 GHz (always).
- ❌ Leaving the lowest data rates enabled and then complaining about channel utilisation.
- ❌ A shared PSK on the corporate Wi-Fi, or a guest PSK with no expiry.
- ❌ WPA2 in new deployments; WPA3 transition mode with no retirement date.
- ❌ 802.1X without mandatory validation of the server certificate on the client (CA **and** name).
- ❌ Presenting a hidden SSID or MAC filtering as a security control.
- ❌ A guest SSID with no VLAN of its own, no client-to-client isolation and no egress filtering.
- ❌ Automatic WIPS containment over third-party networks, or WIPS with nobody to triage its alerts.
- ❌ Designing 6 GHz for outdoors or for long distances under the current European regulation.
- ❌ Counting on the upper 6 GHz band or on AFC in the EU before there is a decision.
- ❌ Enabling 802.11r across the whole fleet at once with no test window and no rollback.
- ❌ Justifying a purchase by generation without inventorying the client estate that would exploit it.
- ❌ DFS channels in areas with known radar, or an automatic channel plan that is never reviewed.

## 8. Mandatory web verification

**Methodology**: the IEEE numbers and the regulatory status are verified against the primary source
(the IEEE 802.11 WG, European Commission/CEPT decisions, the CNAF published in the BOE), not against
blogs.

**Verified Aug-2026**: **Wi-Fi 7 = IEEE Std 802.11be-2024**, approved on 26-Sep-2024 and **published
on 22-Jul-2025**; **the current base revision is IEEE Std 802.11-2024**, published on 28-Apr-2025.
**Wi-Fi 6 = 802.11ax**; **Wi-Fi 8 = 802.11bn (UHR)**, with draft 1.0 in 2025 and publication and
certification expected **2027-2028**: it is not a purchasing option today. **802.11k/v/r are already
incorporated into the base revision** (they are not live amendments): cite them by their function,
not as standalone standards. **WPA3 is mandatory in every new Wi-Fi Alliance certification since
2020 and in 6 GHz**, along with PMF; the **transition mode is a deployment option, not a mandate, and
it does not exist in 6 GHz**. **6 GHz in the EU**: only **5945-6425 MHz** harmonised, **LPI 23 dBm
EIRP and indoors**, **VLP** at a much lower power also outdoors, **with no standard power and no
AFC**; the upper band **6425-7125 MHz** is under a mandate to CEPT with a decision expected
**2026-2027**. In **Spain** the lower band entered the CNAF through **Order ETD/1449/2021** with the
conditions of Implementing Decision (EU) 2021/1067.

**Declared discrepancy**: the sources diverge on the Wi-Fi 8 timeline — IEEE publication in
Mar-2028 according to some and completion in May-2028 according to others, with Wi-Fi Alliance
certification placed between Dec-2027 and Jan-2028. All agree on what decides the matter: **not in
2026**.

**Declared gaps — do NOT fill from memory**:
1. **The exact CNAF UN note for 6 GHz and its current wording**: the reference was located in
   secondary sources; **verify the consolidated text in the BOE** before citing a note number or
   limits in a formal document.
2. **The exact EIRP for VLP** and the conditions for VLP outdoors: not transcribed from a primary
   source.
3. **The 5 GHz sub-bands subject to DFS/TPC and to mandatory indoor use** in Spain and in the EU:
   **not verified** in this pass. They are jurisdiction-specific and they change the channel plan.
4. **Concrete thresholds for channel utilisation, clients per radio and RSSI/SNR per application**:
   they are engineering criteria and vendor guidance, not universal measures. Validate them with real
   load.
5. **The status of MLO per client and the supported mode** (aggregation versus switching) by chipset
   and OS: **not verified**, and it is what decides whether Wi-Fi 7 contributes anything.
6. **Version, maintenance and raw licence** of `hostapd`/`wpa_supplicant`, FreeRADIUS and of the
   site survey tools, and **the behaviour of MAC randomisation** per operating system and its effect
   on NAC: **not verified**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
