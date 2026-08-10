---
name: vpn-standards
description: VPN tunnels and remote access as a designed, operated service. Use when writing or reviewing wg0.conf and its AllowedIPs, PersistentKeepalive, Endpoint, PresharedKey or Table= keys, running wg genkey/pubkey/show/setconf or wg-quick up/down, choosing wg-quick versus systemd-networkd [WireGuard]/[WireGuardPeer] or NetworkManager wireguard profiles, swanctl.conf and ipsec.conf/ipsec.secrets with charon, IKEv2 proposals and esp/ah rekeying, phase-2 proposal mismatch, MOBIKE, ke1_mlkem768 and RFC 9370 hybrid key exchange, client.ovpn and server.conf with tls-crypt, tls-auth, dev tun, redirect-gateway and the ovpn-dco kernel module, tailscale up --advertise-routes/--exit-node and tailnet ACL grants, netbird up, headscale nodes/preauthkeys, nebula-cert sign and lighthouse config, zerotier-cli join, rosenpass psk exchange, split tunneling and DNS-leak decisions, short-lived client certificates versus permanent keys, overlapping site subnets, concentrator redundancy and session logging, or hardening an internet-facing remote-access appliance.
---

# VPN standards — tunnels and remote access

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **choosing, designing, deploying, operating and retiring an encrypted tunnel and the
remote access built on it**: the choice between site-to-site, user remote access and mesh; the
market's shift towards ZTNA; WireGuard and its key model; meshes with a control plane (Tailscale,
NetBird, Netmaker, ZeroTier, Nebula, Headscale) and the risk of delegating that plane; IPsec/IKEv2
for interoperability; OpenVPN where it is still justified; device posture and the access lifecycle;
tunnel operation (MTU/MSS, resolution inside the tunnel, routes and overlaps, concentrator
redundancy and capacity); and the security of the concentrator both as an exposed asset and as a
source of forensic evidence.

Triggers: `wg0.conf`, `[Interface]`/`[Peer]`, `AllowedIPs`, `PersistentKeepalive`, `Endpoint`,
`PresharedKey`, `Table=`, `wg genkey|pubkey|show|setconf|syncconf`, `wg-quick up|down`,
`systemd-networkd` `.netdev` with `[WireGuard]`/`[WireGuardPeer]`, NetworkManager `wireguard`
profiles, `swanctl.conf`, `ipsec.conf`, `ipsec.secrets`, `charon`, `strongswan`,
`ke1_mlkem768`, `ppk=yes`, `client.ovpn`, `server.conf`, `tls-crypt`, `redirect-gateway`,
`ovpn-dco`/`win-dco`, `tailscale up`, `--advertise-routes`, `--exit-node`, tailnet ACL/`grants`,
`netbird up`, `headscale nodes|preauthkeys`, `nebula-cert`, `lighthouse`, `zerotier-cli join`,
`rosenpass`, "split tunneling", "DNS leak", "subnet overlap", "VPN concentrator",
"remote access", "always-on VPN".

**Guiding principle** (inherited from `networking-standards`: *the network is default-deny and
documented as code; what is not in the SoT does not exist*): **the tunnel transports, it does not
authorise**. A packet leaving `wg0` is an untrusted packet that has just entered your network: being
inside the VPN is not a credential, is not an authorisation and does not replace any policy. Every
tunnel has an owner, a written scope, an expiry date and a filtering rule that receives it.

**Not applicable**: see `networking-standards` (**parent**: topology and addressing/IPAM that avoids
the overlaps, VLANs and segmentation, routing and BGP to announce the tunnel prefixes,
**MTU/MSS as a network design criterion**, proxies and load balancing, **choice of the perimeter
platform** —OPNsense/VyOS/appliance—, OOB management plane and ZTNA as an architectural principle),
`firewall-policy-standards` (**the policy that filters the traffic leaving the tunnel**: flow
matrix, `forward` with `policy drop`, egress, owner/expiry of each rule, MSS clamping as a rule,
conntrack — a `wg0` that enters `forward` with no rules is a VPN without a firewall; **here we decide
which tunnel exists and how it is operated, there what traverses it**),
`network-troubleshooting-standards` (**reactive diagnosis**: "the VPN connects but I can't browse" is
**theirs** —it is MTU/PMTU and it is proven with a capture at both ends—, as are "it drops after 5
minutes", "it resolves badly inside the tunnel" or "it works for a while"; **here we fix the correct
value of MTU/keepalive/DNS and why**, there they work out which one is wrong in a specific case),
`identity-access-management-standards` (**identity**: IdP, OIDC/SAML, phishing-resistant MFA,
passkeys, SSO, SCIM and deprovisioning, PAM/JIT and break-glass accounts — **the user and their
authentication are theirs, the tunnel and its termination are ours**),
`cryptography-pki-standards` (**the algorithms, the PKI and the tunnel certificates**: suites,
key sizes, issuance and revocation of client and gateway certificates, CRL/OCSP, ACME,
CA custody, post-quantum migration criteria — **here only what is configured in the tunnel and
with what lifetime**), `secrets-management-standards` (custody and rotation of private keys,
PSKs and enrolment tokens; never in the repo nor in the config file),
`dns-standards` (**the DNS service and its data**: which resolver is legitimate, split-horizon,
internal zones; **here only which resolver is pushed to the client and how it is prevented from
querying outside**),
`detection-engineering-standards` (rules and analytics over VPN session logs: impossible
geolocation, brute force, concurrent sessions),
`incident-response-forensics-standards` (compromise of the concentrator as an incident: containment,
appliance imaging, chain of custody, mass credential rotation),
`vulnerability-management-standards` (triage and patching SLA for concentrator CVEs with
KEV/EPSS — **here the exposure argument, there the formal cadence**),
`observability-standards` (metrics, dashboards and alerts for the tunnel as a service),
`sre-practice-standards` (remote-access SLOs and error budget),
`incident-management-standards` (command and communication when the VPN outage is a declared
incident), `linux-hardening-standards` (baseline of the host terminating the tunnel, forwarding
`sysctl`, systemd sandboxing of the daemon), `selinux-standards` (process confinement),
`linux-administration-standards` (systemd units, `systemd-networkd`, `resolvectl` and resolution
**from the host**), `bash-linux-scripting-standards` (automation scripts),
`kubernetes-standards` (service mesh and mTLS between pods: this is **not** a VPN),
`microservices-architecture-standards` (east-west mTLS between services),
`aws-standards`/`azure-standards`/`gcp-standards` (Site-to-Site VPN, Virtual Network Gateway, Cloud
VPN and their managed ZTNA as a provider service), `iac-standards`/`cicd-standards` (the code
and the pipeline that deploy the config), `onprem-standards` (platform umbrella),
`homelab-standards` (home tunnel: the boundary is the rigour demanded, not the size),
`grc-compliance-standards` (remote access as an auditable control against ENS/ISO/NIS2/DORA),
`bcdr-standards` (remote access as a critical dependency of recovery: if DR depends on
the VPN, the VPN is part of DR), `offensive-security-standards` (offensive validation of remote
access, with scope and authorisation).

Also existing and on the boundary: `ha-clustering-standards` (the concentrator pair as a cluster
resource: VIP, quorum, fencing and failover — **the HA mechanics are theirs, the tunnel state that
must survive the failover is ours**) and `podman-systemd-containers-standards` (the tunnel daemon or
the mesh agent run as a container with Quadlet: unit, network and privileges are theirs).

## 2. Default decisions / Toolchain

> Verify the latest version and the project's status **on the web** before committing to anything (§8).
> Release dates obtained from `api.github.com` and from the upstream git, not from HTML pages.

| Area | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Tunnel protocol | **WireGuard** in-kernel (Linux ≥5.6; `wireguard-tools` **1.0.20260223**, 23 Feb 2026) | IPsec/IKEv2 with **strongSwan 6.0.7** (8 Jun 2026) when you have to interoperate with third-party equipment or FIPS/standardised PQC is required | PPTP, L2TP without IPsec, proprietary SSL-VPN with no patching, any negotiable crypto with weak suites |
| WireGuard in userspace | Only where there is **no** kernel implementation (macOS, Windows, unprivileged container): `wireguard-go` | — | `wireguard-go` on a modern Linux "because it works already": per-packet copy and fixed context-switch cost |
| WG interface management | **`systemd-networkd`** (`.netdev` with `[WireGuard]`/`[WireGuardPeer]` + `.network`) on servers | `wg-quick` on simple hosts and clients; NetworkManager on the desktop | Home-grown scripts that half-reimplement `wg-quick` |
| Mesh with a control plane | **NetBird** (100% open source and self-hostable control plane, unified binary since 0.65; **0.76.1**, 31 Jul 2026) or **Headscale 0.29.3** (29 Jul 2026) if you want the Tailscale client without its coordinator | **Tailscale** when the value is the managed product and you accept the model; **Nebula 1.11.0** (23 Jul 2026, MIT, certificate-based, no SaaS) for isolated or disconnected sites | Manual WireGuard mesh with more than ~10 nodes: key distribution does not scale |
| User remote access | **Per-application ZTNA** with IdP identity (`identity-access-management-standards`) over the tunnel | Concentrator VPN when the access is to a legacy network that cannot be published per application | Full-tunnel VPN that grants "the network" and calling that access control |
| SSL-VPN over TCP/443 | **OpenVPN 2.7.5** (2 Jul 2026) only for hostile networks that block UDP and for legacy clients | 2.6.21 (2 Jul 2026) where 2.7 is not yet packaged | OpenVPN as a new default out of habit; TCP-over-TCP as the usual mode |
| OpenVPN acceleration | **DCO**: `ovpn` module **upstream in Linux 6.16**, `win-dco` by default on Windows | `ovpn-backports` on earlier kernels; `tap-windows6` only for what `win-dco` does not cover | `wintun` on Windows (**removed in 2.7**) |
| Post-quantum | **strongSwan ≥6.0.x with RFC 9370** (`ke1_mlkem768`) + PPK (RFC 8784) when the requirement is real and standardised | Rosenpass over WireGuard (**pre-1.0**: v0.2.3, 3 Aug 2026) in scenarios where you accept pre-1.0 software | Promising "quantum-safe": **WireGuard does not ship PQC**; only the PSK hook |
| Termination | Dedicated, minimal Linux host, or the house's perimeter platform | Commercial appliance if it is already the standard, with the patching of §5 accepted as a commitment | Commercial concentrator with no emergency patching window committed in writing |
| Machine authentication | Registered WireGuard public key + optional PSK; or **short-lived** X.509 certificate in IPsec/OpenVPN | — | Permanent key or certificate with no expiry and no proven revocation |
| User authentication | **Phishing-resistant MFA** (passkeys/WebAuthn, FIDO2) delegated to the IdP | TOTP only as an interim step with an exit date | SMS, push without *number matching*, or "the certificate already identifies the user" |
| Filtering of tunnel traffic | `forward` with `policy drop` and a flow matrix (`firewall-policy-standards`) | — | `wg0` in `forward` with no rules |

**A criterion of choice, not of taste.** WireGuard if you control both ends. IPsec if the other
end imposes it or there is a certification requirement. OpenVPN if the path is hostile and you need
TCP/443. Managed mesh if you have mobile clients, NAT everywhere and identity-based ACLs.
ZTNA if what you need to publish is **an application**, not a network.

## 3. Structure and conventions

### 3.1 The starting decision: which model solves your problem

| Model | What it solves | What it does **not** solve |
|---|---|---|
| **Site to site** | Joining two networks with stable routing, few ends, known addresses | User identity, mobility, per-application granularity |
| **Concentrator remote access** | Getting a laptop "inside" to reach legacy services | Authorisation: it gives network, not applications. Scales badly and concentrates risk |
| **Mesh** | Many mobile ends behind NAT, direct peer-to-peer connectivity, identity-based ACLs | The control plane becomes your new root of trust |
| **ZTNA / per-application proxy** | Publishing a specific application to a specific identity, without giving network | Protocols that cannot be published per application; provider dependency |

- **The market shift is real and has a technical cause, not a fashion one**: the concentrator VPN
  grants *network* access after a single authentication, and that model broke along two
  simultaneous paths — (1) the concentrator became the preferred and exploited target (§5.1),
  and (2) the perimeter ceased to exist with SaaS and remote work. NIST SP 800-207 says it without
  hedging: location on the network does not grant trust.
- **Operational translation, not a slogan**: you do not have to "remove the VPN". You have to (a)
  **stop using the tunnel as authorisation** —each access is authorised by identity, device and
  application—, and (b) reduce the VPN to transporting what cannot yet be published per application,
  with minimal scope and an expiry date. The VPN survives as a **transport layer**, it dies as a
  **trust layer**.
- **Migration criterion**: publish first what is HTTP(S) (proxy/ZTNA), then what speaks a
  protocol with its own identity (SSH with certificates, RDP behind a broker), and leave the rest in
  the tunnel —with an inventory and a review date. A VPN that "stays for everything else" without a
  list is the same old VPN with a new name.

### 3.2 WireGuard: what you have to understand before writing a `wg0.conf`

- **Fixed crypto with no negotiation**: ChaCha20-Poly1305, Curve25519, BLAKE2s, HKDF. There are no
  suites to choose, no downgrade to negotiate and no "phase 1/phase 2" to mismatch. That is its main
  value against IPsec and it is not up for discussion; if your requirement demands cryptographic
  agility or a specific certified algorithm, **WireGuard is not your protocol** (see
  `cryptography-pki-standards`).
- **UDP and silence by design**: it does not answer anyone who does not present a valid key. A scan
  does not see it. That reduces surface, but it also means that **a connection failure tells you
  nothing**: diagnosis is asymmetric and needs a capture at both ends
  (`network-troubleshooting-standards`).
- **`AllowedIPs` is routing *and* access control at the same time — the most common conceptual error.**
  - On **egress**: it defines which destinations are routed through that peer (`wg-quick` creates the
    route).
  - On **ingress**: it is *cryptokey routing* — a packet arriving through the tunnel with a source
    **outside** that peer's `AllowedIPs` **is dropped**. It is the only authorisation WireGuard has.
  - Practical consequence: **`AllowedIPs = 0.0.0.0/0, ::/0` on a client peer of the server
    means "this peer can spoof any source"**. Each peer carries **exactly** its
    `/32` (and its `/128`), or the prefix of the site it legitimately routes, and nothing else.
  - `0.0.0.0/0` is legitimate **only on the client side towards the server** (full-tunnel) or on a
    peer that really is the default exit.
  - This does **not** replace the firewall: WireGuard validates the source, not the destination nor
    the port.
- **Keys**: one private key per device, generated **on the device** (`wg genkey`),
  never reused between nodes or between environments, `umask 077`, `0600` file, and never in the repo
  (`secrets-management-standards`). The public key is a device identifier, not a person's:
  **there is no user identity in WireGuard**.
- **Rotation**: WireGuard does not rotate keys on its own. Rotation is a coordinated operation (add
  the new peer, migrate, retire the old one) and for that reason, beyond a handful of nodes, it is
  automated or it does not happen — which is exactly the argument for a managed mesh (§3.3). Set a
  cadence (annual as a floor, immediate on a leaver or on suspicion) and **test the removal**: a peer
  deleted from the server loses access instantly; checking that is the gate.
- **`PresharedKey`**: an additional symmetric layer per peer pair. Its intended use is
  **post-quantum resistance** (§3.6), not generic "more security". If it is used, it is one more
  secret to hold in custody and rotate per pair.
- **`PersistentKeepalive`**: **25 s** is the reference value for the peer that is behind NAT or a
  stateful firewall, and it exists so the NAT association does not expire. Rules: it is set by **the
  side that is behind the NAT**, not by the public server; setting it on every peer of a mesh is
  traffic and battery in exchange for nothing. Without it, the symptom is the classic "it works when
  I initiate, not when they initiate" and "it drops when I stop using it".
- **Roaming**: WireGuard updates the peer's `Endpoint` upon receiving an authenticated packet from a
  new IP. That is its great mobile virtue, and also the reason why **filtering by the client's source
  IP does not work** as a control.
- **Real limits that must be said out loud**: no identity management, no user authentication, no
  MFA, no key distribution, no ACLs beyond `AllowedIPs`, no NAT traversal of its own (it needs a
  reachable end or a relay), no centralised revocation. All of that is provided by another layer; if
  you do not provide it, it is not there.
- **`Table = off`** when you want to control routing by hand (dynamic routing over the tunnel,
  policy routing); with automatic `Table` and `AllowedIPs = 0.0.0.0/0`, `wg-quick` installs policy
  rules that can break management access to the host itself. Remote change ⇒ rescue window open (§4).

### 3.3 Managed meshes: what you buy and what you give up

**What they add over plain WireGuard** (and why past a certain size it is not optional):
federated identity against your IdP, automatic key distribution and rotation, **identity-based
rather than IP-based ACLs**, NAT traversal (STUN/UPnP/hole punching) with **fallback relays** when
the punch fails —DERP in Tailscale/Headscale, own relays in NetBird—, mesh DNS, immediate joins and
removals, and visibility of which node talks to which.

**What you give up: the control plane is the new root of trust.**
- Whoever controls the coordinator **distributes keys, ACLs and routes**. Its compromise is not "a
  metadata leak": it is the ability to introduce a node into your network or to rewrite who can talk
  to whom. Treat it with the same criteria as your IdP or your CA, not as a network tool.
- **Evidence that the client and the plane are real surface, not theoretical** — Tailscale's own 2026
  bulletins (verbatim from their bulletins page): **TS-2026-004** (4 Jun) *Tailscale SSH
  Unix socket forwarding did not respect symlink permissions*; **TS-2026-005** (3 Jun) *Tailscale
  Serve Unix socket proxy targets were not restricted to `root`*; **TS-2026-006** (11 Jun) *Tailscale
  SSH allowed users to be addressed by numeric UID, bypassing `root` user restrictions*;
  **TS-2026-007** (10 Jul) *Insufficient inbound packet filtering in Services permitted access to
  loopback-bound listeners*; **TS-2026-008** (13 Jul) *A single malformed HTTP request to a node
  running Tailscale Serve or Funnel could pin a CPU core indefinitely*; **TS-2026-009** (13 Jul)
  *Insecure command line argument handling in Tailscale SSH permitted `root` user access in
  violation of ACLs*. Read it for what it is: **a privileged agent on all your nodes**, with
  features that expose services and that bypass ACLs when they fail. Subscribe to the bulletins of
  whichever provider you choose and treat its patching as privileged-agent patching, not app patching.
- **Questions answered in writing before adopting**: is the control plane
  self-hostable? can the provider add a node to your network without your consent? do the relays see
  cleartext traffic (they should not: encryption is end to end) or do they only forward it? where does
  the plane live and under which jurisdiction? what happens to the network if the provider goes down
  —do already-established tunnels survive, do new joins not? what bulletin history does it have? what
  licence and what business model, and what happens if they change?
- **The business model changes and it affects you**: in 2026 there was movement in prices and
  licences in this space (Tailscale towards per-seat pricing; ZeroTier tightening the self-hosted
  controller; NetBird formalising its self-hosted edition). **Do not pin any of those
  conditions from memory** — verify the current one before committing to a platform (§8).
- **A written exit criterion from day one**: what you do if the provider changes its licence, raises
  the price or disappears. The "whole plane in-house" option (Headscale/NetBird self-hosted/Nebula) is
  precisely the insurance against that, at the cost of operating it yourself.
- **Nebula** is the different choice: **certificate**-based with your own CA, no phoning home,
  no SaaS; in exchange, operating the CA and the `lighthouse` is on you
  (`cryptography-pki-standards`).

### 3.4 IPsec/IKEv2: when and with what discipline

- **It is used when the other end imposes it** (a third party's appliance, a carrier, a
  certification requirement) or when you need standardised PQC (§3.6). It is more complex and has
  more surface —strongSwan's 2026 CVE history confirms it (§8)—, but it is still alive because it is
  the only common denominator between vendors.
- **IKEv2 always**; IKEv1, aggressive mode, XAUTH and group PSKs are vetoed.
- **The classic phase-2 *mismatch***: phase 1 (IKE_SA) comes up, phase 2 (CHILD_SA) does not, and the
  log does not say so clearly. Causes in order of frequency: ESP proposals that do not match
  (encryption, MAC, PFS group), **traffic selectors** (`local_ts`/`remote_ts`) that are not identical
  and mirrored on both sides, and tunnel vs. transport mode. **Rule**: the proposal is agreed **in
  writing** with the third party before configuring, is written **explicitly** at both ends (no long
  lists "just in case", which mask the disagreement and negotiate downwards), and the selectors are
  compared literally. One side with `0.0.0.0/0` and the other with a `/24` is the number-one cause of
  "it comes up and it drops".
- **Rekeying**: define IKE_SA and CHILD_SA lifetimes that are coherent at both ends and with
  different margins, or you will have exactly periodic outages (symptom: "it drops every 8 hours").
  Suspect rekeying on any outage with a regular periodicity.
- **MOBIKE (RFC 4555)** for mobile clients: it allows changing IP/interface without renegotiating. It
  is what makes IKEv2 usable on a laptop hopping from WiFi to 4G. Enable it or accept reconnections.
- **IKE fragmentation**: messages with certificates or with PQ keys exceed the MTU. Enable IKEv2
  fragmentation (RFC 7383) and **do not block ICMP**; otherwise the tunnel "sometimes does not come
  up" depending on which certificate the client uses.
- **NAT-T (UDP/4500)**: needed in almost every real scenario. Modern `strongswan` is configured with
  `swanctl.conf`; `ipsec.conf`/`starter` is the legacy path and is being retired.
- **DPD (dead peer detection)** enabled on both sides, or a dead tunnel will still be "up" in the
  table and traffic will fall into a black hole.

### 3.5 OpenVPN: where it is still justified

- **Valid justifications, and only those**: the path blocks UDP and you need **TCP/443** to
  look like web traffic; there are legacy clients or platforms with no acceptable WireGuard client;
  you need integrated user authentication (PAM, LDAP, plugins) without building another layer.
- **TCP-over-TCP is a real penalty** (*TCP meltdown*): use it as plan B, not as the default.
  If UDP is available, UDP.
- **Non-negotiable minimum config**: `tls-crypt` (better than `tls-auth`: besides authenticating, it
  encrypts the control channel and hides OpenVPN's fingerprint), server **and** client certificates
  with `remote-cert-tls`, an active and tested CRL, AEAD encryption (AES-GCM/ChaCha20-Poly1305),
  TLS ≥1.2 with 1.3 preferred, and `verify-x509-name` so that a client certificate cannot impersonate
  the server.
- **DCO changes performance and the deployment model**: the `ovpn` module **upstream since Linux
  6.16** (replacing the out-of-tree `ovpn-dco-v2`; `ovpn-backports` for earlier kernels), and on
  Windows `win-dco` is the default with `tap-windows6` as fallback — `wintun` **was removed** in
  2.7. If you depended on `wintun`, that is a deployment change, not a detail.
- **`redirect-gateway`** turns the client into full-tunnel: it is a **risk decision**
  (§3.7), not a default value.

### 3.6 Post-quantum: what exists today and what does not

- **WireGuard does not ship PQC.** Its crypto is fixed; the only extension point is the
  `PresharedKey`, and by design (the project itself documents it as the intended use of that hook).
  **Selling a WireGuard deployment as "quantum-safe" is forbidden**.
- **Via WireGuard**: **Rosenpass** runs a separate PQ exchange and injects the result into the
  PSK hook, refreshing it periodically; the WireGuard protocol stays intact. Real status:
  **pre-1.0** (v0.2.3, 3 Aug 2026). Adopt it knowing it is pre-1.0 software and that its
  deployment is **all-or-nothing per peer** except in permissive mode. NetBird integrates it as an
  option.
- **Via IPsec**: **RFC 9370** (multiple key exchanges in IKEv2, with `IKE_INTERMEDIATE` so that
  large keys do not blow up `IKE_SA_INIT`) + **RFC 8784** (PPK) is the standardised route.
  strongSwan supports it since 6.0.0 (`ke1_mlkem768`, `ppk=yes`). It is the defensible option
  if the requirement is formal/certifiable.
- **Criterion**: the threat model is *harvest now, decrypt later*. If your traffic has value over
  10+ years, hybrid (classical **+** PQ, never PQ alone) is reasonable today in IPsec and experimental
  in WireGuard. The algorithms, their standardisation status and the migration plan are decided in
  `cryptography-pki-standards`, not here.

### 3.7 User remote access: the full cycle

- **Identity first**: authentication against the corporate IdP with **phishing-resistant MFA**
  (passkeys/FIDO2). No shared secret, no "the certificate is already the user", no
  SMS. The policy and the IdP, in `identity-access-management-standards`.
- **Short-lived credentials > permanent keys.** The goal is for the client credential to
  expire on its own: a short-lived certificate issued after authenticating at the IdP, or a
  token/profile that expires. A permanent key on a lost laptop is permanent access until someone
  remembers to revoke it. If you use permanent keys (plain WireGuard), **revocation is a process with
  an owner and with proof**, not an intention.
- **Split tunnelling: an explicit, documented risk decision**, never an inherited default.
  - *Full tunnel*: all traffic passes through the organisation — full inspection, filtering and
    logging; in exchange, latency, bandwidth cost, concentrator capacity and a connectivity SPOF
    for the user.
  - *Split tunnel*: only corporate traffic enters the tunnel — better performance and cost; in
    exchange, you lose visibility of the rest of the device's traffic and you accept that the
    endpoint is exposed to the Internet while it is "inside".
  - **Criterion**: if your content control and your telemetry live on the endpoint (EDR + forced
    DNS resolution + proxy), split tunnelling is defensible; if they live at the perimeter, split
    tunnelling disables them. Decide, write it down and **review it**; the hybrid (split by
    destination, with the sensitive traffic and DNS forced into the tunnel) is the usual balance
    point.
  - What is **never** acceptable: split tunnelling that leaves DNS resolution outside the tunnel
    (§3.8) or that lets the client act as a bridge between the Internet and the corporate network.
- **Device posture** as a condition of access: managed and inventoried device,
  encrypted disk, EDR alive and up to date, patched OS, and **continuous reassessment**, not just at
  connection time. A laptop that complied on connecting and stops complying an hour later must lose
  access. BYOD without posture ⇒ per-application ZTNA, never a network tunnel.
- **Deprovisioning the same day** — and "the same day" is a measurable commitment: the leaver in
  the IdP revokes VPN access, revokes the certificate, removes the peer from the concentrator and
  **cuts active sessions**. Most deployments fail at that last point: blocking the login
  does not evict whoever is already inside. Test deprovisioning quarterly with a test account (§4).
- **Always-on with a captive-portal exception**: the client brings the tunnel up at boot and only
  allows traffic outside it for the visited network's portal, with a short expiry.

### 3.8 Tunnel operation: what breaks in practice

- **MTU and MSS: the number-one cause of "the VPN connects but some websites don't load"** — the TCP
  handshake (small packets) works, the transfer (large packets with DF) hangs.
  - Adjust the **tunnel MTU** *and also* do **MSS clamping** in `forward`: they are
    complementary measures, not alternatives. The reference values and the calculation, in
    `networking-standards`; the nft rule that applies it, in `firewall-policy-standards`.
  - **Do not block ICMP type 3 code 4** (*fragmentation needed*) nor ICMPv6 *packet-too-big*: without
    them PMTUD dies and the failure is silent and intermittent.
  - Watch offload (GRO/GSO/TSO) on the tunnel interface: it aggregates above the MTU and
    drops with DF set.
  - **Diagnosing** a specific case belongs to `network-troubleshooting-standards`; here we fix
    that the value must be set, tested with a large packet and DF, and documented.
- **DNS inside the tunnel and DNS leaks**: the client must use the corporate resolver for
  corporate traffic. The typical leaks are (a) the client keeps the local DHCP resolver, (b) the OS
  queries several resolvers in parallel and the outside one wins, (c) the browser uses its **own DoH**
  and bypasses the whole system resolver, and (d) mDNS/NetBIOS resolving outside. Controls:
  push the resolver and the search domains from the tunnel, a browser policy that
  disables uncontrolled DoH, and **active verification** that the query leaves where it should.
  Which resolver is legitimate and how it is designed: `dns-standards`.
- **Routes and address overlap** — the classic of merging two sites with
  `192.168.1.0/24`: **there is no elegant fix**, only three ways out, in order of preference:
  (1) **renumber** one of the sides (correct, painful, definitive); (2) **1:1 NAT** of the overlapping
  prefix in the tunnel, with a documented "mirror" range in the IPAM —it works, it breaks everything
  that carries IPs embedded in the protocol or in configuration, and it multiplies the cost of
  diagnosis; (3) publish only specific services via proxy/ZTNA and do not join the networks. Prevention
  belongs to `networking-standards`: **an addressing plan with large blocks and no overlaps from
  day one**, because mergers do come.
- **Routes announced with judgement**: a peer that announces `0.0.0.0/0` to the mesh becomes
  everyone's exit without anyone deciding it. Tunnel routes are approved like any other
  routing change, and they are filtered (`AllowedIPs` in WireGuard, route ACLs in the mesh,
  `--advertise-routes` requiring explicit approval in Tailscale/Headscale/NetBird).
- **Concentrator redundancy and capacity**: active/passive or active/active pair with a DNS name or
  a virtual IP, **exercised** failover, and sizing by **concurrent users on the worst day**
  (not by headcount) with margin for the continuity scenario —March 2020 taught that the
  concentrator sized for 30% of headcount is a business incident. If DR depends on
  the VPN, the VPN is critical DR infrastructure (`bcdr-standards`).
- **The tunnel is monitored as a service, not as an interface**: "the peer is configured" is not
  "the tunnel works". See §6.

## 4. Mandatory quality gates

In increasing order of cost. The first five block the deployment.

1. **Configuration validation before applying**: `wg-quick strip` / `wg setconf` against the
   candidate config, `swanctl --load-all` in test mode, `openvpn --config ... --test-crypto`,
   `networkctl` for the units. A config that does not validate does not even reach staging.
2. **Review of `AllowedIPs` as a security gate, not a network one**: no peer with more reach than
   it should have; `0.0.0.0/0`/`::/0` only on the side that legitimately requires it and with
   written justification. This gate is the WireGuard equivalent of the firewall's "any/any".
3. **Rescue window open on every remote change** that touches the tunnel, routes or remote access:
   OOB console, a second administration path or a timed rollback
   (`systemd-run --on-active` restoring the previous config unless confirmed). Changing the tunnel
   through the tunnel itself with no safety net is the most predictable self-lockout in the trade.
4. **Mandatory negative test**: (a) a removed peer **loses** access immediately;
   (b) a source outside its `AllowedIPs` is dropped; (c) traffic between two VPN clients is
   denied if the policy says so; (d) the concentrator exposes nothing beyond its tunnel port.
   A tunnel tested only along the happy path is not tested.
5. **End-to-end MTU test with a large packet and the DF bit**, not just a default `ping`, and
   with the real application (a large transfer, not a `curl` to a one-line page). This is the
   gate that avoids 90% of the "the VPN is behaving oddly" tickets.
6. **DNS leak and route test** after each client or profile change: resolution goes out
   where it should, the traffic that must go to the tunnel goes to the tunnel, and what must not,
   does not. With split tunnelling active this test is mandatory on **every** profile change.
7. **Quarterly deprovisioning drill**: a test account marked as a leaver in the IdP ⇒ check that
   it loses access **and that its active session is cut**. Document the real time to cut-off.
8. **Concentrator failover drill** in a window: site-to-site tunnels re-establish, the
   clients reconnect, and how long it takes is measured. A secondary that is never exercised is not
   redundancy.
9. **Load test before the high season or the continuity event**: the target concurrent users
   with realistic traffic, measuring encryption CPU, sessions and bandwidth.
10. **Periodic review of the inventory of tunnels and peers** (quarterly): every tunnel and every peer
    with an owner, reason, scope and last activity; inactive ones are retired. A peer belonging to a
    provider whose contract ended a year ago is permanent access nobody remembers.

## 5. Security

### 5.1 The VPN concentrator is a first-order target — with data, not rhetoric

**Evidence (CISA KEV catalogue, version 2026.07.29, 1,656 entries; consulted directly from
CISA's JSON, not from a press note).** **Actively exploited** vulnerabilities in
remote-access and perimeter devices added since Jan 2025:

| Added | CVE | Product |
|---|---|---|
| 2025-01-08 | CVE-2025-0282 | Ivanti Connect Secure / Policy Secure / ZTA Gateways — stack overflow |
| 2025-01-24 | CVE-2025-23006 | SonicWall SMA1000 — deserialisation |
| 2025-02-18 | CVE-2024-53704 | SonicWall SonicOS **SSLVPN** — improper authentication |
| 2025-04-04 | CVE-2025-22457 | Ivanti Connect Secure / Policy Secure / ZTA Gateways — stack overflow |
| 2025-04-16 | CVE-2021-20035 | SonicWall SMA100 — command injection (a CVE **from 2021**, exploited in 2025) |
| 2025-05-01 | CVE-2023-44221 | SonicWall SMA100 — command injection |
| 2025-06-30 | CVE-2025-6543 | Citrix NetScaler ADC/Gateway — buffer overflow |
| 2025-07-10 | CVE-2025-5777 | Citrix NetScaler ADC/Gateway — out-of-bounds read |
| 2025-08-26 | CVE-2025-7775 | Citrix NetScaler — memory overflow |
| 2025-09-25 | CVE-2025-20333 and CVE-2025-20362 | Cisco Secure Firewall ASA / FTD |
| 2025-12-17 | CVE-2025-40602 | SonicWall SMA1000 — missing authorisation |
| 2026-02-25 | CVE-2026-20127 | Cisco Catalyst SD-WAN Controller/Manager — authentication bypass |
| 2026-03-30 | CVE-2026-3055 | Citrix NetScaler — out-of-bounds read |
| 2026-05-29 | CVE-2026-0257 | Palo Alto Networks PAN-OS — authentication bypass |
| 2026-06-08 | CVE-2026-50751 | Check Point Security Gateway — improper authentication |
| 2026-07-14 | CVE-2026-15409 and CVE-2026-15410 | SonicWall SMA1000 — SSRF and **code injection** (chainable) |
| 2026-07-22 | CVE-2026-16232 | Check Point SmartConsole — improper authentication |
| 2026-07-27 | CVE-2025-68686 | Fortinet FortiOS — information exposure |
| 2026-07-27 | CVE-2026-16812 | Arista VeloCloud Orchestrator |

**Mandatory reading of that table** (risk class, never an exploitation procedure):
- **The dominant family is pre-auth authentication bypass**, not execution after
  authenticating. The "only valid users" control does not protect a device whose flaw is
  *before* that check.
- **Exploitation arrives in days, sometimes hours**, and the groups using it seek persistence in the
  appliance itself —where your EDR does not reach and your software inventory does not look.
- **The old CVE kills**: CVE-2021-20035 was being actively exploited in 2025. An appliance with no
  patching window accumulates exploitable debt for years.
- **No vendor is clean.** The choice of brand is not a security control; the patching
  process is.

**Design consequences — this is what you have to do with that data**:
- **Minimal exposure**: only the tunnel port to the Internet. The **concentrator's management plane
  is never** published (neither administration HTTPS, nor SSH, nor API) — it is reached over OOB or
  via a bastion (`networking-standards`). A good part of the CVEs in the table affect management or
  portal interfaces that were exposed.
- **An emergency patching window committed in writing** before purchase: hours, not
  weeks, for a KEV on the edge device. The formal cadence and the risk-based SLA, in
  `vulnerability-management-standards`.
- **Minimal surface by design**: a WireGuard daemon on a minimal, hardened Linux host that is
  patchable in minutes has orders of magnitude less surface than an appliance with a web portal,
  integrated SSO, antivirus and management console. When you can choose, choose the small thing.
- **Assume the concentrator is compromised in the threat model**: segment what is behind it,
  filter the tunnel's outbound traffic, do not store domain credentials on the appliance and have
  decided in advance how you isolate it and rebuild it from a clean image
  (`incident-response-forensics-standards`). A compromised appliance is **not cleaned, it is
  rebuilt**.
- **Watch the vendor actively**: subscribe to its advisories, and review KEV as an operational
  trigger. One of your products entering KEV is an incident, not a maintenance task.

### 5.2 Cryptographic and key hygiene

- **No negotiation is better than negotiation**: where you can choose, prefer a fixed-suite
  protocol (WireGuard). Where you negotiate (IPsec/TLS), the proposal is **explicit and short**; long
  lists "for compatibility" are a downgrade waiting to happen.
- **No private key leaves the device that uses it.** Local generation, `0600` permissions,
  out of the repo and out of cleartext backups (`secrets-management-standards`).
- **Proven revocation**: CRL/OCSP working and verified with a genuinely revoked certificate;
  peer removal verified. An untested revocation does not exist.
- **PSKs and enrolment tokens**: short expiry, single use where possible, and rotation. A
  mesh enrolment token is a key to enter your network.
- Algorithms, lengths, PKI and the post-quantum plan: `cryptography-pki-standards`.

### 5.3 The tunnel does not authorise: filtering and segmenting what leaves it

- **`forward` with `policy drop` and a flow matrix** for the traffic entering from the tunnel, just
  as for any other zone (`firewall-policy-standards`). The VPN zone is one more zone and is usually
  the **least** trusted: devices you do not fully control, on networks you control not at all.
- **Isolation between VPN clients** unless there is an explicit requirement: by default, one client
  does not talk to another client.
- **Filtered tunnel egress**: a compromised client on full-tunnel uses your Internet exit
  with your reputation.
- **Access per application, not per network**, whenever the protocol allows it. The concentrator is
  the transport; authorisation is provided by identity.

### 5.4 Session logging and forensics

- **What is logged, as a minimum**: authenticated identity, device, public source IP and its
  geolocation, IP assigned inside the tunnel, start and end timestamps, disconnect
  reason, bytes, and **the result of the posture evaluation**. Without the association
  *tunnel-IP ↔ user ↔ time window*, no later investigation can attribute anything.
- **Retention** at least equal to the organisation's investigation window, with protected integrity
  and **off the concentrator itself** (if the appliance goes down, its logs go down with it — and if
  they compromise it, they delete them). Sent to the SIEM in near real time.
- **Signals that detection engineering exploits** (the rules belong to
  `detection-engineering-standards`): impossible travel, concurrent sessions from different
  geographies, authentication from a hosting/commercial-VPN ASN, bursts of failures followed by a
  success, a user's first access at an unusual hour, and anomalous outbound volume per session.
- **Forensic readiness of the appliance**: have documented in advance how to obtain an image or a
  state dump of the concentrator and which logs survive a reboot —many appliances make it
  hard, and that is discovered in the middle of the incident if it has not been tested before.

## 6. Performance and operability

- **First-class metrics** (collection, thresholds and alerts, in `observability-standards`):
  - **`latest handshake` per peer** in WireGuard — it is the only reliable signal of "the tunnel is
    alive"; the interface always exists, whether the peer is up or down. Alert on a handshake older
    than expected, not on interface state.
  - CHILD_SA and IKE_SA state in IPsec; active and rejected sessions in OpenVPN.
  - Concurrent sessions against the licensed/sized capacity, **with a warning threshold well
    below the limit**: the day it fills up is always the worst day.
  - Encryption CPU and throughput per tunnel (encryption saturates CPU before the link does on modest
    hardware; check whether acceleration is available).
  - Retransmissions, loss and RTT **inside** the tunnel versus outside —a tunnel that adds loss
    is a badly sized tunnel or one with the MTU set wrong.
  - Expiry of gateway and client certificates, and licence expiry.
- **End-to-end synthetic test**: a probe that traverses the tunnel and touches **a real
  application** on the other side, not a `ping` to the gateway. Half of VPN faults are "the tunnel is
  up and the service does not respond".
- **Capacity**: size by the percentile of real concurrency with margin for the continuity
  scenario (everyone remote at once). If the concentrator is also the firewall, encryption competes
  with filtering for CPU.
- **Cost and latency of full-tunnel**: all the user's traffic passes through your link. It is a
  capacity and a billing decision, not just a security one.
- **Runbooks with an owner**: primary concentrator outage, site-to-site tunnel that does not come up
  after a third party's change, expired gateway certificate, a client that connects but cannot browse
  (→ MTU, `network-troubleshooting-standards`), suspected concentrator compromise (isolation +
  mass rotation), concurrency spike from a continuity event, and **unblocking the administrator
  who locked themselves out** changing rules through the tunnel itself.
- **Recovery**: the tunnel config is restored from the repo and the keys from their custody, on
  a clean machine, in minutes — and that is tested (`bcdr-standards`). The appliance backup is
  evidence, not the source.

## 7. Sustainability and prohibitions

- **Cadence**: concentrator and client CVE review **monthly** and on entry into KEV
  (immediate trigger); review of the WireGuard/strongSwan/OpenVPN version and of the mesh agent
  quarterly; review of the inventory of tunnels and peers quarterly (§4.10); review of the
  full-tunnel vs. split decision and of the list of "what cannot yet be published per application"
  annually.
- **Client kept current**: the mesh agent or the VPN client is **privileged software on every
  endpoint**. Its patching has the same priority as the browser's, not that of a utility.
- **Real decommissioning**: retiring a tunnel includes deleting the peer, revoking the certificate,
  withdrawing the route, deleting the firewall rule, removing the IPAM entry and archiving the record.
  A tunnel that is "off but configured" comes back up on its own on the least opportune day.
- **No abandoned projects**: any component with no security release in 12 months or on an EOL
  branch is discarded before the technical discussion.

**FORBIDDEN**
- ❌ Treating "being inside the VPN" as authorisation, or giving access to the whole network when one
  application was enough.
- ❌ `AllowedIPs` broader than what the peer legitimately routes; `0.0.0.0/0` on the client peer
  on the server side.
- ❌ `wg0` (or any tunnel interface) in `forward` with no filtering rules.
- ❌ PPTP, L2TP without IPsec, IKEv1, aggressive mode, XAUTH, shared group PSK.
- ❌ User remote access without MFA, or with MFA over SMS / push without *number matching*.
- ❌ **Permanent** client keys or certificates with no expiry and no proven revocation.
- ❌ A private key generated in one place and distributed to the devices; a key in the repo, in the
  ticket or in the chat.
- ❌ Reusing the same key or the same certificate on several devices.
- ❌ Publishing the concentrator's management plane to the Internet (admin portal, SSH, API).
- ❌ A remote-access appliance with no emergency patching window committed in writing.
- ❌ Considering a compromised concentrator "cleanable": it is rebuilt from a clean image.
- ❌ Split tunnelling adopted by default, with no written risk analysis, or leaving DNS outside the
  tunnel.
- ❌ A tunnel without adjusting MTU **and** MSS, and then blaming the application.
- ❌ Blocking ICMP type 3 code 4 or ICMPv6 *packet-too-big* (it kills PMTUD and diagnosis).
- ❌ Joining two networks with overlapping addressing by means of NAT without documenting it in the
  IPAM and without a renumbering plan.
- ❌ Changing routes, rules or tunnel config remotely **through the tunnel itself** without a rescue
  window.
- ❌ A single concentrator with no redundancy, or a failover never exercised.
- ❌ Sizing concurrency by headcount instead of by the worst day.
- ❌ A user leaver process that does not cut their **active sessions**.
- ❌ Peers, tunnels or provider accounts with no owner, no expiry and no review.
- ❌ Adopting a managed mesh without answering in writing what happens if its control plane goes down
  or is compromised, and without an exit plan.
- ❌ Treating the mesh agent as one more app and not as privileged software on every node.
- ❌ Selling a deployment as "quantum-safe" (WireGuard does **not** ship PQC).
- ❌ Session logs that live **only** on the concentrator.
- ❌ `wireguard-go` on Linux with a modern kernel "because it works already".
- ❌ Long lists of cryptographic proposals "for compatibility" in IPsec/TLS.

## 8. Mandatory web verification

Before pinning any version, date, CVE or licence condition, **look it up — do not recall it**.
**Methodology**: the versions and dates in this document were obtained from `api.github.com/repos/…`,
from the upstream git (`git.zx2c4.com`) and from the **official JSON of CISA's KEV catalogue**, not
from summarised HTML pages. Repeat that method: the summary of a releases page invents years.

Verified Aug 2026:

- **WireGuard**: `wireguard-tools` **v1.0.20260223** (23 Feb 2026), from the official repository
  `git.zx2c4.com/wireguard-tools` — **GitHub is only a mirror and its releases page is
  out of date** (last tag there, v1.0.20210914). Kernel implementation in Linux since 5.6;
  `wireguard-go` is functionally equivalent at the protocol level but with per-packet copy and
  context-switch cost: explicit upstream recommendation to use the kernel module on Linux.
  A project in stable maintenance mode, authored by Jason A. Donenfeld.
- **strongSwan**: **6.0.7** (8 Jun 2026); 6.0.6 (22 Apr 2026) fixed **seven** CVEs
  (CVE-2026-35328 to CVE-2026-35334, incl. a *name constraints* bypass in the `constraints` plugin and
  possible RCE in `libsimaka`); 6.0.5 (23 Mar 2026) fixed CVE-2026-25075 (eap-ttls, pre-authentication
  DoS). PQC via **RFC 9370** (`ke1_mlkem768`) since 6.0.0, with PPK (RFC 8784).
- **OpenVPN**: **2.7.5** (2 Jul 2026) and **2.6.21** (2 Jul 2026); 2.7.0 came out in Feb 2026.
  **DCO**: `ovpn` module **upstream in Linux 6.16** (replacing `ovpn-dco-v2`), `ovpn-backports`
  for earlier kernels; on Windows `win-dco` by default and **`wintun` removed**. Other
  2.7 news: multi-socket, mbedTLS 4, `PUSH_UPDATE`.
- **Meshes** (releases via `api.github.com`): NetBird **v0.76.1** (31 Jul 2026), Netmaker **v1.6.0**
  (12 Jun 2026), Headscale **v0.29.3** (29 Jul 2026), Nebula **v1.11.0** (23 Jul 2026),
  ZeroTierOne **1.16.2** (28 May 2026), Rosenpass **v0.2.3** (3 Aug 2026, **pre-1.0**).
- **Tailscale security bulletins in 2026** (verbatim from their bulletins page): TS-2026-004
  and TS-2026-005 (3/4 Jun), TS-2026-006 (11 Jun), TS-2026-007 (10 Jul), TS-2026-008 and TS-2026-009
  (13 Jul) — SSH, Serve/Funnel and inbound packet filtering.
- **CISA KEV**: catalogue **2026.07.29**, **1,656** entries, **172 added in 2026** (Cisco 13,
  Fortinet 6, Ivanti 5 among the most frequent network vendors). The table in §5.1 comes from that
  JSON. **Re-download it** (`https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`)
  before using any exploitation data: it changes every week.
- **Post-quantum**: WireGuard has **no** native PQC; only the `PresharedKey` hook.
  Rosenpass is still **pre-1.0** and uses Classic McEliece + Kyber-512 (pre-FIPS). IKEv2 with RFC 9370
  and ML-KEM is the standardised route.

**Declared gaps — do NOT fill from memory, verify before using**:
1. **Current licence and pricing conditions** of Tailscale, ZeroTier, NetBird and Netmaker: only
   signals from secondary sources were obtained (Tailscale's move to per-seat pricing,
   the tightening of ZeroTier's self-hosted controller, NetBird's self-hosted tier). **Not
   verified against the official pricing/licence pages.** Confirm before committing to a
   platform.
2. **CVEs with a formal identifier in NetBird, Netmaker, Headscale, Nebula and ZeroTier**: not
   located in this pass. Only Tailscale's own bulletins (TS-2026-00x) are on record and,
   as a historical precedent, the Pulse Security advisory about ZeroTier (2021). Consult GitHub's
   advisory database per repository before claiming a project is clean.
3. **CVE-2026-47895 in strongSwan** (double free in identity cloning, possible RCE, since
   4.3.3): cited by a distribution advisory; **not verified** against strongSwan's official advisory
   nor against NVD. Check whether 6.0.7 includes it before pinning a minimum version.
4. **Distro-packaged versions** of `wireguard-tools`, strongSwan and OpenVPN in RHEL 10,
   Fedora, Debian 13 and Ubuntu LTS: **not verified**. What matters operationally is the
   package's version, not upstream's.
5. **Specific MTU/MSS values per encapsulation type**: delegated to `networking-standards`
   and **not re-verified** here. Recalculate them for your real encapsulation (WireGuard over
   Ethernet, over PPPoE, over IPv6, IPsec with NAT-T) instead of copying a number.
6. **Status of MOBIKE, IKEv2 fragmentation and DPD** in specific third-party implementations
   (Fortinet, Palo Alto, Cisco): described as criteria, **not verified** against each vendor's
   current documentation.
7. **The RFC numbers cited** (4555 MOBIKE, 7383 IKEv2 fragmentation, 8784 PPK, 9370 multiple key
   exchanges, NIST's 800-207): **not cross-checked against rfc-editor** in this pass.
   Verify them before citing them as authority.
8. **Capacity and model of the relays/DERP** (whether or not they see traffic, bandwidth limits,
   location): described by expected design, **not verified** against each provider's
   documentation.

If the web contradicts this document, **the web wins** — flag the discrepancy.
