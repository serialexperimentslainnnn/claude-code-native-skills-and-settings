---
name: telco-5g-standards
description: Mobile operator networks from the point of view of whoever integrates or buys them, including private cellular. Use when deciding between 5G Non-Standalone and Standalone (NSA option 3x versus SA option 2) and which features actually exist in each, working with 5G core network functions AMF, SMF, UPF, AUSF, UDM, NRF, NSSF, PCF and the service-based interface, gNB / CU / DU / RU functional split, Open RAN and the fronthaul, network slicing and S-NSSAI, SST and SD values, a slice SLA and GSMA GST/NEST templates, a private or campus 4G/5G network and its spectrum regime (licensed, locally assigned, shared, CBRS, Bundesnetzagentur 3.7-3.8 GHz local assignments, the Spanish CNAF and autoprestación), deciding between private cellular and enterprise wireless LAN, ETSI MEC and a local UPF breakout, SIM, eUICC and eSIM remote provisioning with GSMA SGP.22 or SGP.32 and an eIM, IMSI/SUPI/SUCI and device identity, IMEI, cellular IoT with NB-IoT, LTE-M or RedCap and 2G/3G sunset dates, a private APN, static IP SIMs and roaming agreements, SS7, SIGTRAN and Diameter interconnect exposure, SEPP and the N32 interface with PRINS (3GPP TS 33.501), or someone proposing that a SIM card counts as application authentication.
---

# Operator network and 5G standards — what you buy, what you integrate and what does not exist

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when you have to **integrate, procure, size or secure cellular connectivity**, whether
from a public operator or from a private network of your own: the choice between NSA and SA and its
real consequences; the 5G core (5GC) and its functions; *network slicing* and what it guarantees
contractually; **private 4G/5G networks** and their spectrum regime; MEC and local user plane
breakout; device identity (SIM/eSIM/eUICC, IMSI/SUPI); cellular IoT (NB-IoT, LTE-M, RedCap) and the
2G/3G sunsets; private APNs, static IP and *roaming*; and the **security of the operator's trust
model**.

Triggers: `5GC`, `AMF`, `SMF`, `UPF`, `AUSF`, `UDM`, `NRF`, `NSSF`, `PCF`, `SBI`, `gNB`, `CU`/`DU`/
`RU`, `N2`/`N3`/`N6`/`N32`, `S-NSSAI`, `SST`, `SD`, `SUPI`, `SUCI`, `concealed SUPI`, `IMSI`,
`eUICC`, `SGP.22`, `SGP.32`, `eIM`, `SEPP`, `PRINS`, `NB-IoT`, `LTE-M`, `RedCap`, `CBRS`, `APN`,
`URLLC`, `eMBB`, `mMTC`, ETSI MEC; "private 5G network", "campus network", "autoprestación",
"2G/3G sunset", "SIM with a static IP".

**Not applicable** — hard boundaries: **the Wi-Fi radio link belongs to `wireless-standards`**
(802.11ax/be, 6 GHz, site survey, WPA3, 802.1X over WLAN — here only **when private cellular wins or
loses against Wi-Fi**); **edge compute belongs to `edge-computing-standards`**
(here only the local UPF and what MEC enables, not how the compute platform is
operated); **the embedded device belongs to `embedded-iot-standards`**
(firmware, power draw, device OTA updates). In addition: `networking-standards`
(**the backbone**: addressing, VLANs, MTU, the IP network where the APN lands),
`wan-legacy-standards` (MPLS, SD-WAN, legacy circuits and **mobile access as a site backup
or FWA**), `network-vendors-standards` (operating model, licences, EoS and **the regulatory
risk of the RAN vendor**), `routing-switching-standards`, `firewall-policy-standards`
(the policy filtering what leaves the APN), `vpn-standards` (the tunnel that **does** authenticate the
device), `identity-access-management-standards` (**application identity and its
authentication — the SIM is not that, §5**), `ot-ics-security-standards` (the industrial system that
uses the private network), `observability-standards`, `high-speed-interconnect-standards`,
`offensive-security-standards` (**this skill is defensive**).

## 2. Default decisions

> Verify on the web the operator's deployment status, the real availability of each capability
> **in the specific coverage area**, and the **country's spectrum regime** before committing to anything (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Site connectivity | Fixed (fibre/DIA) as primary; **cellular as a backup over a different medium** | 5G FWA as primary only where there is no fibre, with the SLA read |
| Indoor industrial data coverage | Well-designed **Wi-Fi** (`wireless-standards`) | Private cellular if the §3 checklist is met |
| Cellular architecture to demand in a tender | **SA**, if you need slicing, bounded latency, a static IP or a local UPF | NSA is acceptable for plain broadband |
| IoT device identity | **eSIM/eUICC with remote provisioning** (SGP.22 consumer / SGP.32 IoT) | A soldered physical SIM (MFF2) in environments without remote management |
| Cellular IoT technology | **LTE-M** if there is mobility, voice or latency; **NB-IoT** if it is static low-throughput telemetry | RedCap for the mid range if the operator and the module support it |
| Device data egress | **A private APN delivered into your own network** and filtered at the edge | A public APN **only** with an end-to-end encrypted tunnel |
| Application authentication over cellular | A client certificate / mTLS / a token, **independent of the SIM** | — (there is no alternative: §5) |

## 3. Architecture — what each thing is and what it decides

### NSA versus SA: the difference decides which capabilities exist

- **NSA (Non-Standalone, option 3x)**: the 5G radio (gNB) is anchored to an **LTE eNB** and to the
  **4G EPC core**. It gives more throughput and little else. **There is no 5GC**, hence **there is no slicing, no
  URLLC, no local user plane breakout, and none of 5G's new security functions**.
- **SA (Standalone, option 2)**: a gNB against a full **5GC**. It is where *slicing*, the
  distributable UPF, permanent-identifier concealment (SUCI) and low-latency capabilities really exist.

**A practical and non-negotiable consequence**: if a commercial offer promises *slicing*, deterministic
latency or local breakout, **you must demand in writing that the coverage of the specific locations
is SA**, not that "the operator has 5G SA". Most of the world's deployment is still
NSA: according to GSA data collected in 2026, of the order of **95 operators** had launched 5G SA
against **~390 operators with 5G launched** — roughly **a quarter**. The figures
vary by report edition (85/89/95 depending on the date and on whether soft launches are counted): **quote
the exact edition and verify (§8)**.

### 5GC: what each function does and why it matters to the integrator

- **AMF** — access and mobility management; it is the termination point for the terminal's
  signalling (N1/N2). It is the **control plane**: if it goes down, devices neither register nor move.
- **SMF** — session management: it establishes the PDU session, assigns an IP address and **controls the UPF**.
- **UPF** — **the only user plane element**. It is the one that can be **distributed**: putting it
  close to the site is what gives low latency and what allows the traffic **not to leave** for the
  operator's network. Without SA there is no UPF to place.
- **AUSF / UDM / UDR** — authentication and subscription data (the evolved equivalent of the HSS).
- **NRF** — function registration and discovery; **NSSF** — *slice* selection; **PCF** —
  policy (QoS, throughput, charging).
- **SBI** — the functions talk to each other over **HTTP/2 + JSON with a REST API**, not over classic
  telecom protocols. An enormous consequence: **the mobile core is today a microservices
  architecture**, with the same problems (service-to-service authorisation, certificate management,
  discovery) and the same tooling. A platform engineer understands a 5GC better than
  they expect.
- **RAN**: the gNB split into **CU / DU / RU**. Open RAN opens those interfaces (fronthaul). For the
  integrator this only matters if they are going to operate their own RAN; in a managed private network, it does not.

### Network slicing: what it guarantees and what it does not

- A *slice* is identified by an **S-NSSAI** = **SST** (service type: eMBB, URLLC, mMTC…) + **SD**
  (an optional differentiator). The terminal requests a *slice*; the network decides whether to grant it.
- **What slicing really is**: logical isolation of core resources and a differentiated QoS policy,
  with **the radio as a shared resource unless it is explicitly reserved**.
- ❌ **What it is not**: a physical guarantee. If the contract does not set **minimum throughput, maximum latency,
  availability, measurement point and penalty**, the *slice* is a priority setting with a marketing
  name.
- **What to demand in writing**: the *slice*'s parameters (GSMA uses GST/NEST templates as a
  common vocabulary — verify the applicable version, §8), **where it is measured**, at what frequency,
  what happens under congestion, and **whether the reservation reaches the radio resource or only the core**. Without that,
  there is no SLA, there is a label.
- A *slice* **does not replace encryption**: it is operator segmentation, exactly like MPLS
  (`wan-legacy-standards` §5).

### Private 4G/5G networks: spectrum and decision criteria

**Spectrum is the first filter, and it is national.** Coexisting models:

- **Spectrum assigned locally to the end user** — the model that makes a truly private network
  viable. Germany is the mature precedent: the Bundesnetzagentur locally assigns **3,700–3,800
  MHz** for private networks, per site or business premises, with a fee calculated by **area and
  years of assignment**; the published holders include heavy industry, automotive, port
  and agricultural logistics. **The current number of assignments was not verified** (§8), and the
  published list is incomplete due to commercial confidentiality: only those who consented appear.
- **Spain** — the new **Cuadro Nacional de Atribución de Frecuencias (CNAF)**, updated by
  ministerial order in **July 2026**, reassigns the **3,800–4,200 MHz** band (previously fixed
  satellite service) to local mobile use, distinguishing **concession** (provided by an operator) and
  **autoprestación** (a network of one's own). Reported split: **3,800–3,920 MHz** local broadband at low
  and medium power, under concession or autoprestación; **3,920–4,020 MHz** Defence; **3,920–4,120 MHz**
  electronic news gathering under autoprestación; **4,020–4,120 MHz** local broadband autoprestación.
  There is also a prior reservation for autoprestación at 26 GHz. **The exact conditions (powers,
  procedure, fees, coordination with Defence and with satellite) are in the BOE text and in the
  CNAF's UN note; they were not verified here (§8) and they are what decides whether a specific deployment is
  viable.**
- **Shared spectrum** — the CBRS model (USA, the 3.5 GHz band with SAS coordination). A different
  regime and **not extrapolable** to Europe.
- **Operator spectrum** — the private network is deployed and operated by the operator on its licence
  (*private network as a service*). Faster to procure; **it is not autonomy**: you go back to
  depending on the operator, and the continuity model has to be read.

**When private cellular beats Wi-Fi 6E/7** — only if **several** of these are met:

1. **Wide outdoor coverage or real mobility** (a port, a mine, a large campus, AGVs crossing
   buildings): cellular handover between cells is in another category from Wi-Fi roaming.
2. **A hostile RF environment** (metal, obstruction, severe multipath) where the
   cellular link with licensed power and planning behaves better.
3. **A determinism requirement with an internal SLA**, not "low latency" by eye.
4. **Licensed spectrum available** in the country and at the location: without this, there is no conversation.
5. **Device density with a predictable traffic profile** and a long lifecycle.

**When it is extremely expensive over-engineering** — and this is the majority case:

- Offices, conventional covered warehouses, indoor coverage for generic data: **well-designed Wi-Fi
  is cheaper, more flexible and more people know how to operate it**.
- When **the devices do not have a cellular modem** and cannot carry one: every terminal needs a
  module and a SIM. The per-device cost, multiplied, usually decides the project.
- When there is nobody who is going to operate a mobile core. A private network brings RAN, core, SIM
  management, upgrades and spectrum. **It is a miniature operator**, with its implicit headcount.
- When the real problem was a bad Wi-Fi design. **Before proposing private cellular, demand
  the site survey and the data from the current WLAN** (`wireless-standards`): most of the
  "the Wi-Fi doesn't work" complaints are capacity, roaming or a client *driver*, not technology.

### MEC and local breakout

**ETSI MEC** defines the application platform at the operator's edge; what makes it useful on the
network is the **local UPF**: placing the user plane at the site or at the operator's edge so that
the traffic **does not cross the central core**. That is what really reduces latency and what
keeps the data inside the premises.

- It requires **SA**. In NSA it does not exist.
- **What to ask**: where is the UPF physically? Is the local breakout into my network or into the
  operator's Internet? Who operates the platform and with what SLA? What happens if the link to the central core goes down?
- Operating the edge compute platform belongs to `edge-computing-standards`.
  Here only **the user plane topology** is decided.

> **Latency figures: vendor folklore.** The "1 ms of 5G" is a **radio interface target under specific
> conditions** from the URLLC specification (of the order of 1 ms with 10⁻⁵ reliability
> for small packets), **not an end-to-end application latency**. The
> NGMN/3GPP vision put the general target at around **10 ms end to end**, with 1 ms reserved for
> extreme cases, and the air segment is only part of the total: the core contributes the rest. Independent
> measurements on commercial networks put the achievable figure at **single-digit milliseconds in
> the best case** (a third-party evaluation reports as low as ~6 ms end to end) and in
> practice at one to two digits. **Measured sub-millisecond has been observed at the physical layer, in
> private millimetre-wave deployments with line of sight**, not on a public macro network. **Rule: do not
> quote a latency that has not been measured at the real location and with the real terminal.**

## 4. Quality and verification

- **Acceptance testing at the real location, with the real terminal**: signal level and quality
  (RSRP/RSRQ/SINR), throughput in both directions at peak hour, sustained latency and *jitter*,
  behaviour under mobility and **reconnection time after coverage loss**. The coverage on the
  commercial map is not an engineering datum.
- **Verify SA independently**: check on the terminal that it registers against a 5GC (not an
  LTE anchor) at the specific locations. A tender that buys SA and receives NSA is a frequent case
  and is only detected by measuring.
- **Test the degradation**: what the device does when the *slice* is not available, when it falls
  back to 4G or when it enters an area with no coverage. A system that assumes permanent connectivity over
  cellular is badly designed. Retries with exponential backoff and *jitter*, local queuing and
  degraded operation.
- **Test eSIM profile transfer** before deploying a fleet: download, activate, deactivate and
  restore a profile on the real device. **Remote provisioning that has not been exercised does not
  exist** — and in IoT the typical failure is a device left with no active profile and no way
  to recover over the air.

## 5. Security

### The SIM is not application authentication

It is the most dangerous claim in this domain, and it appears constantly in IoT designs.

- The SIM/eUICC authenticates **the subscription to the operator's network**. It proves that that subscriber
  can use the network. **It does not prove** which device it is, nor that the firmware is legitimate, nor that whoever
  opens the TCP connection is the expected application.
- A SIM can be **pulled out and put in another device**. A private APN is a network, and **anything
  inside that network reaches the server**. An IMSI or an APN IP **are not credentials**.
- ❌ **FORBIDDEN** to authorise by the APN's source IP, by IMSI, by IMEI or by "it's in our
  private network". Every device authenticates with **its own rotatable application credential**
  (a client certificate with mTLS, or a short-lived token), and the server authorises by that
  identity. Cellular connectivity is **transport**, not identity.
- The IMEI is an identifier **declared by the terminal**: it is good for inventory, never for
  access control.

### The operator network's trust model

- The user plane **is not end-to-end encrypted** by virtue of being cellular. Radio encryption
  protects the air segment; inside the operator the traffic is visible to the operator. **All
  sensitive data goes encrypted on top** (TLS or a tunnel), including over a private APN and including over a
  *slice*.
- **A private APN**: it reduces exposure (the traffic does not go out to the Internet and lands in your network), and for that
  very reason **it moves the perimeter to your side**. It is filtered at the delivery point with default-deny
  (`firewall-policy-standards`), it is not assumed clean.
- **A static IP per SIM**: useful for inventory and correlation. **It is not an access control** (see
  above).

### SS7, Diameter and interconnect: the historical surface

- Legacy interconnect signalling — **SS7/SIGTRAN** in 2G/3G and **Diameter** in 4G — was
  designed on the assumption that all interconnected operators were trustworthy. That
  assumption has been false for more than a decade: interconnect has been exploited for
  location tracking, SMS interception and fraud. **A direct and actionable consequence**: ❌ **SMS and
  voice calls are not a strong second factor**. Any design depending on SMS OTP inherits the
  surface of the weakest interconnected operator on the planet (see
  `identity-access-management-standards`).
- **5G addresses it structurally** with the **SEPP** (Security Edge Protection Proxy) at
  each network's border and the **N32** interface (3GPP TS 33.501): **N32-c** to manage the connection
  and **N32-f** for the protected messages. Two modes: **direct TLS between SEPPs** when there are no
  intermediaries, and **PRINS** (*PRotocol for N32 INterconnect Security*) when there are IPX providers
  in the path — the message travels protected with **JWE** (RFC 7516) and the IPX's modifications are
  added as signed **JWS** objects (RFC 7515), which the receiving SEPP validates and applies. The
  modification policy is agreed with the IPX and exchanged during the N32-c negotiation.
- **The small print that decides**: the GSMA warns in its 5G *roaming* guidelines that the hop-by-hop
  concentration model with link protection **is not specified by 3GPP and does not give end-to-end
  security between networks**, only TLS between hops. That is: **having a SEPP does not
  guarantee end-to-end protection**; it depends on the deployed model. If *roaming* matters
  for the use case, **ask explicitly about the N32 model and request it in writing**.
- **Translation for whoever integrates, not for whoever operates a core**: the design must not depend
  on the operator's network being trustworthy. End-to-end encryption, your own application
  authentication, and no secret travelling over SMS.

### SIM identity and provisioning

- In 5G SA the permanent identifier (**SUPI**) is transmitted **concealed** (**SUCI**, encrypted with the
  home network's public key), which cuts off the IMSI tracking that was trivial in 4G — but
  **only in SA and only if it is configured properly**. In NSA it does not apply.
- **eSIM/eUICC**: `SGP.22` is the consumer profile (it assumes there is a user who accepts);
  **`SGP.32` is the IoT one** and introduces the **eIM** (*eSIM IoT remote Manager*), which triggers the
  download, activation, deactivation or deletion of profiles **with no user present**. Published
  versions: 1.0 (2023), 1.1 (2024), 1.2 as the certification baseline, and **1.3 published in
  May 2026** — sources disagree about which is the current certification baseline:
  **verify on the GSMA's specifications page (§8)**.
- **The eIM is a platform that can leave the entire fleet without connectivity.** It is treated as a
  critical identity system: MFA, least privilege, an audit log of every profile operation,
  and a **tested recovery procedure** for a device with no active profile.
- ❌ **FORBIDDEN** to deploy a fleet with remote provisioning whose recovery procedure has not been
  exercised on real hardware.

## 6. Operability and lifecycle

- **2G/3G sunsets**: they are the biggest operational risk for deployed cellular IoT, and **the calendar
  is per country and per operator**. An estate of meters, alarms, lifts or eCall devices with a
  2G/3G modem stops working on a specific date that **the estate's owner usually does
  not know**. **It is verified and tabulated per country and operator (§8); it is not written from memory.**
  3G is withdrawn before 2G in almost all markets, because 2G is retained for M2M and
  fallback voice.
- **NB-IoT and LTE-M are not dying technologies**: 3GPP keeps them evolving **within the
  5G specifications** and **retaining the LTE waveform** — there is no migration to NR planned, and
  they are supported against a 5G core. They coexist with NR. Release 17 added efficiency, **RedCap**
  (the mid range, formerly "NR-Light") and initial support for non-terrestrial networks for NR, NB-IoT and LTE-M.
  Deployment of the order of **115 LTE-M and 137 NB-IoT networks** as of mid-2025 according to GSMA
  (**verify the edition and date, §8**). **But**: there are operators who have announced the withdrawal of their
  NB-IoT/LTE-M networks; **the technology's longevity does not guarantee that of your operator's service
  in your country**. That is the datum to demand contractually.
- **Coverage ≠ service**: NB-IoT and LTE-M are sized by link budget in deep indoor locations
  (basements, chambers). It is validated by measuring at the worst location, not on the map.
- **Roaming for IoT**: read whether it is permanent *roaming* (prohibited or limited in several
  jurisdictions), which visited networks are guaranteed, and **what happens when the visited network switches off the
  technology**. A device in permanent roaming with a single agreement is a single point of
  contractual failure.
- **Cost**: the cellular IoT charging model (per SIM, per byte, per event) dominates the TCO
  over the hardware. It is modelled with the real measured traffic profile, not the estimated one
  (`finops-standards`).

## 7. Sustainability and prohibitions

- Review the cellular estate **annually** against: sunset calendars (2G/3G and, later,
  4G), module end of support, eSIM specification versions and the validity of the
  agreement with the operator.
- Every deployed cellular device carries in the inventory: supported radio technology,
  band, operator, SIM type (physical/eUICC), provisioning specification version, APN and the module's
  end-of-support date. **Without this inventory you cannot respond to a sunset
  announcement.**
- Document in an ADR the private-cellular-versus-WLAN decision with the conditions that would reopen it
  (a change in available spectrum, extended outdoor coverage, a new determinism requirement).

Prohibitions:

- ❌ **FORBIDDEN** to treat the SIM, the IMSI, the IMEI, the APN IP or membership of a private network
  as application authentication or authorisation.
- ❌ **FORBIDDEN** to use SMS or a voice call as a second authentication factor in a system with
  value. The legacy interconnect surface has made it inadvisable for more than a decade.
- ❌ **FORBIDDEN** to send sensitive data without end-to-end encryption by trusting the private
  APN, the *slice* or "it's an operator network".
- ❌ **FORBIDDEN** to buy *slicing*, URLLC, a static IP or local breakout without written confirmation that
  **the specific locations are covered by SA**.
- ❌ **FORBIDDEN** to accept a *slice* without measurable parameters, a measurement point, behaviour under
  congestion and a penalty in writing. Without that it is a priority label.
- ❌ **FORBIDDEN** to quote "1 ms" or any 5G latency figure that has not been measured at the
  real location and with the real terminal.
- ❌ **FORBIDDEN** to propose a private cellular network without (a) confirming the country's spectrum regime
  and its availability at the location, (b) the study of the current WLAN ruling out that the problem
  is a Wi-Fi design one, and (c) the operating model with a named owner.
- ❌ **FORBIDDEN** to deploy a cellular IoT fleet without a verified table of 2G/3G sunset dates per
  country and operator.
- ❌ **FORBIDDEN** to deploy eSIM remote provisioning without a recovery procedure tested on
  real hardware.
- ❌ **FORBIDDEN** to write from memory a 3GPP or GSMA specification version, a frequency
  band, a licensing regime or a regulatory date (§8).
- ❌ **FORBIDDEN** to include here SS7/Diameter exploitation techniques, IMSI catchers or
  equivalent material. This skill sets a defensive posture and purchasing criteria; offensive work
  requires written scope and authorisation (`offensive-security-standards`).

## 8. Mandatory web verification

**Always** check, in a primary source (3GPP, GSMA, the national regulator, the official gazette, the
operator's contract):

1. **The spectrum regime for private networks in the specific country**, with the regulatory text: in Spain,
   the ministerial order of the **CNAF** (July 2026) published in the **BOE** and the applicable **UN
   note** — powers, procedure, fees and coordination with Defence and satellite **were not
   verified here**. In Germany, the **Bundesnetzagentur**'s Verwaltungsvorschrift for
   3,700–3,800 MHz, its fee and the **current number of assignments** (**not verified**).
2. **The operator's SA deployment status at the specific locations**, and the edition and date of the
   GSA report any SA/NSA operator figure comes from (the figures vary by edition).
3. **The 2G and 3G sunset calendar per country and per operator**, and any NB-IoT/LTE-M withdrawal if
   there is one. **It is the datum most often asserted wrongly.** In Spain, the roadmap is being worked on by the Ministry
   for Digital Transformation: **the per-operator dates circulating in the press are
   inconsistent and were not verified in a primary source.**
4. **The current version of the GSMA eSIM specifications** (SGP.22 and SGP.32) and **which is the
   certification baseline** — there is disagreement between v1.2 and v1.3 (published 28-05-2026) in
   the sources consulted.
5. **The applicable version of 3GPP TS 33.501** and of the GSMA's 5G *roaming* guidelines (NG.113) before
   quoting any interconnect security clause.
6. **Slice templates** (GSMA GST/NEST) and their version, if the contract references them.
7. **The regulatory status of the RAN vendor** in the deployment country if it is a supplier subject to
   restrictions (`network-vendors-standards` §5).
8. **Any latency, throughput, saving or market-share figure**: demand the methodology and the measurement point. If
   there is none, **it is not quoted**.

**Declared gaps**: (a) neither the BOE text nor the Spanish CNAF's UN note was verified — the
split of the 3,800–4,200 MHz band comes from technical press quoting the order, not from the order. (b)
The current number of local 3.7 GHz assignments from the Bundesnetzagentur was not obtained. (c) The
2G/3G sunset dates in Spain could not be established from a primary source: the secondary sources
contradict each other and **are not written here**. (d) The 5G SA operator figures come from summaries
of GSA reports with variation between editions (85/89/95). (e) The figure of 115 LTE-M / 137
NB-IoT networks comes from a GSMA citation from mid-2025, without the original report being verified. (f) The
NB-IoT/LTE-M withdrawal plans of specific operators were not verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
