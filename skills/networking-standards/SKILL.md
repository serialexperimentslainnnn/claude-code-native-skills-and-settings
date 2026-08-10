---
name: networking-standards
description: Network engineering standards. Use when working with IP addressing and VLANs, BGP/OSPF (FRR, BIRD), nftables/firewalld rules, DNS (BIND, Unbound, CoreDNS, Pi-hole), Kea DHCP, HAProxy/nginx/Traefik/Caddy proxies, WireGuard/Tailscale/NetBird overlays, MTU/MSS, tcpdump/Wireshark, NetBox, OPNsense/VyOS/RouterOS.
---

# Network standards — design, operation and security

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, configuring, reviewing or diagnosing: IP addressing and subnetting,
IPAM, VLANs and segmentation, routing (static, OSPF, BGP, prefix filtering, RPKI, ECMP),
switching (STP, LACP, MLAG), stateful firewall policy, NAT, DNS and DHCP architecture,
L4/L7 load balancing and reverse proxies, VPNs and overlays, ZTNA, IPv6 and dual stack, QoS, MTU/MSS,
hardening of network equipment and the OOB management plane, 802.1X/NAC, layered diagnosis,
flow telemetry and network automation.

Triggers: `nft`/`nftables.conf`, `firewalld`, `frr.conf`, `bird.conf`, `named.conf`,
`unbound.conf`, `Corefile`, `kea-dhcp4.conf`, `haproxy.cfg`, `nginx.conf`, `Caddyfile`,
`wg0.conf`, `netplan`/`systemd-networkd`/NetworkManager, `tcpdump`, `mtr`, `ss`, NetBox,
containerlab (`*.clab.yml`), OPNsense/pfSense/VyOS/RouterOS/UniFi, "VLAN", "BGP", "MTU",
"DNS", "subnet", "peering", "MSS clamping".

**Not applicable**: see `onprem-standards` (firewall and VLANs at host/server level,
basic fleet monitoring), `aws-standards`/`azure-standards`/`gcp-standards` (VPC,
Security Groups/NSG, the provider's managed load balancers and DNS),
`kubernetes-standards` (CNI, NetworkPolicy, Service/Ingress, service mesh),
`observability-standards` (network metrics, logs, traces and alerts),
`sre-practice-standards` (SLOs and error budget), `detection-engineering-standards` (security
telemetry, SIEM and detection rules — Suricata/Zeek signatures are governed there, the sensor and its
placement in the network, here), `incident-response-forensics-standards` (capture and preservation of
traffic during a compromise), `linux-hardening-standards` (**host** firewall and OS baseline
as opposed to the network design fixed here),
`firewall-policy-standards` (**which flow is allowed between zones and with what governance**: design of the
nftables/firewalld ruleset, owner, approval and expiry of each rule, egress filtering,
review of shadowed and orphaned rules), `dns-standards` (**the DNS server, its zone and its
data**: SOA and TTL, DNSSEC, mail records, DoT/DoH, domain hijacking), and
`vpn-standards` and `network-troubleshooting-standards` (tunnels and
diagnosis). This skill keeps **topology, addressing and VLANs, routing and BGP, design-level MTU/MSS,
proxies and load balancing, overlays, the OOB management plane and the choice of perimeter platform**,
plus the governance of the network as code.

**Delegation of depth** — this skill is the **trunk**: it fixes the general
criteria and **hands the detail** to three skills that do cover it. If the answer requires more than the
principle, it is theirs:
- `routing-switching-standards`: **campus and edge in depth** — STP and routed access, MLAG,
  first-hop redundancy, and above all **the complete BGP policy** (attributes, communities,
  outbound filtering, **RPKI/ROV and IRR**, BCP 38/84, BFD, CoPP, 802.1X, MACsec).
- `datacenter-fabric-standards`: **the data centre fabric** — leaf-spine Clos, VXLAN with
  EVPN, symmetric IRB, ESI multihoming, encapsulation MTU and lossless Ethernet.
- `network-automation-standards`: **the network as code** — source of truth and operational IPAM,
  NETCONF/RESTCONF/YANG and gNMI as opposed to the CLI, virtual lab, pre- and post-validation,
  batched rollout with tested rollback, and continuous streaming telemetry as opposed to SNMP polling.
  **What this skill says about "network as code" is the principle; the procedure is theirs.**
- `wireless-standards`: **the corporate wireless network as a radio system** — site survey,
  spectrum and capacity, channel plan, roaming, WPA3 and 802.1X with certificate validation on the
  client. **This skill's prohibition on the shared PSK still holds; the design that
  replaces it is theirs.**
- `high-speed-interconnect-standards`: **InfiniBand, RoCE v2 and compute and storage RDMA**,
  which is **a different network from the data one** and is not designed with the same criteria.
- `load-balancing-standards`: **the load balancer and the reverse proxy** — health checks,
  draining, TLS termination and high availability of the balancer itself. **The products this
  skill fixes in §2 (HAProxy, nginx, Traefik, Caddy) are chosen and operated there.**

**Guiding principle**: the network is **default-deny and documented as code**. Every allowed
flow exists because somebody justified it and it was written down; what is not in the SoT does
not exist, and what cannot be diagnosed layer by layer is not in production.

## 2. Default decisions

> Versions verified Aug 2026. **Verify the latest stable on the web before pinning it in
> a real project** (§8): this stack rotates every quarter.

| Area | Default | Forbidden / alternative |
|---|---|---|
| Firewall on Linux | **nftables** (Fedora 44: nftables 1.1.4, firewalld 2.4.0 with the nftables backend since firewalld 0.6). A single `inet` table with IPv4+IPv6 | `iptables-legacy`; mixing nft rules and `iptables` commands (the `iptables-nft` shim translates silently). `iptables-nft`/`ipset` deprecated since RHEL 9 and no longer a documented option in RHEL 10 |
| Perimeter router/firewall | **OPNsense 26.7 "Xenial Xenops"** (FreeBSD 15.1 base; half-yearly cycle Jan/Jul) or **VyOS** for network-as-code | pfSense CE 2.8.1 (latest CE, Sep-2025; slow CE cadence) only if it is already in house. MikroTik **RouterOS 7.23** stable / **7.21.5** long-term |
| VyOS images | **Stream** (2026.03, quarterly, free) for lab/non-critical; **LTS** requires a paid or contributor subscription | Rolling/nightly in production |
| Dynamic routing | **FRR 10.7.0** (Jul-2026) on Linux hosts/routers; **BIRD 3.3.1** (LTS 3.1.x) on route servers and IXPs | Static routes in topologies with more than one path; redistribution without filters |
| Site-to-site VPN | **WireGuard** in-kernel; IPsec IKEv2 only for interoperability with third parties | PPTP, L2TP without IPsec, proprietary SSLVPN without patching |
| Overlay with a control plane | **NetBird ≥ 0.65** (100% open source, self-hostable control plane, unified binary) or **Tailscale**; **Headscale 0.29.x** (beta) if you want the Tailscale client without its coordinator | Manual WireGuard mesh with more than ~10 nodes (key distribution does not scale) |
| Internal recursive DNS | **Unbound 1.24.2** or **Knot Resolver**, with DNSSEC validation enabled | `systemd-resolved` and `dnsmasq` as DNSSEC validators (failures documented in SIDN's independent evaluation) |
| Authoritative DNS | **Knot DNS 3.5.4** or **BIND 9.20.x ESV** (9.20.26 with critical DNSSEC patches) | BIND **9.18 (EOL Jun-2026)**; development branches 9.21/9.23 in production |
| Lab/home DNS filtering | **Pi-hole v6** (FTL 6.7 / Core 6.4.3, Jul-2026) or AdGuard Home | Pi-hole as the only resolver with no redundancy |
| DHCP | **Kea** (ISC's official successor); reservations and options from the SoT | ISC `dhcpd` in new deployments (no active maintenance — confirm the status, §8) |
| Reverse proxy / L7 LB | **HAProxy 3.2.x LTS** (supported to 2030-Q2) or 3.4.0 LTS; **nginx 1.30.x stable**; **Traefik v3.7.x** in dynamic environments; **Caddy 2.11.x** when the value is automatic ACME | nginx mainline in prod; Traefik v2 (patches only); an LB without active health checks |
| IPAM and source of truth | **NetBox 4.6.7** as the SoT of **intent** (not of discovery) | Spreadsheets; auto-populating NetBox from a network scan as if it were intent |
| IPv6 | **Dual stack by default** in new designs (IPv6 to Google passed 50% in Mar-2026) | Deploying IPv4-only "because it'll come later"; NAT66 out of habit |
| Diagnosis | `tcpdump`/Wireshark, `mtr`, `ss`, `ip`, `nft list ruleset` | `netstat`, `ifconfig`, `route` (obsolete, they hide state) |
| Flow telemetry | **IPFIX/NetFlow v9** (sFlow if the hardware only supports that) to a collector (Akvorado/pmacct/GoFlow2) | A network with no flow visibility: you can neither investigate nor size it |

## 3. Structure and conventions

**Addressing and IPAM**
- Hierarchical and **aggregable** plan by site → zone → role, with reserved room for
  growth; no overlaps between sites, VPNs and clouds (RFC 1918 runs out fast in
  mergers — allocate large, documented blocks).
- Point-to-point links: `/31` in IPv4 and `/127` in IPv6. Loopbacks `/32` and `/128` as the
  device's stable identity (router-id, BGP session termination, management).
- IPv6: **GUA** for everything that routes, ULA (`fc00::/7`) only for what never leaves;
  SLAAC for clients, static addressing or DHCPv6 for servers. No
  MAC-derived interface addresses on servers (they break firewalling and DNS).
- **NetBox holds the intent**; the network must converge towards it. Close the loop in
  both directions: after every change, the SoT is updated or the change is not finished.

**Segmentation**
- Minimum zones: management (OOB) / servers / users / IoT / DMZ / storage and
  replication / guests. **Industrial zoning is not one of these zones and is not designed
  with these criteria**: Purdue levels, conduits with a security level, level 3.5 DMZ and
  the isolation of the SIS belong to `ot-ics-security-standards`, and there *Safety* wins over
  availability. Putting the plant into an "IoT-OT" VLAN from this list is the classic mistake. One VLAN = one broadcast domain = one subnet = one policy
  zone. **Default-deny between zones**, every allowed flow with a written owner and reason.
- East-west microsegmentation where the data justifies it (NIST SP 800-207 and SP 800-215
  as the framework): location in the network grants no trust.

**Routing**
- OSPF for the interior (real areas, not everything in area 0); BGP for multihoming, DC fabric
  (leaf-spine eBGP) and overlays. iBGP with route reflectors only when a full mesh
  stops being reasonable.
- **On every eBGP**: inbound and outbound prefix-list or route-map (deny by default),
  `maximum-prefix` with an action, AS-path filtering, and RPKI **ROV** with your own validator
  (Routinator/rpki-client) — invalid = reject. Global ROA coverage 67.4% (Jun-2026), but
  only ~12.3% of ASes apply full ROV: signing ROAs protects nobody if nobody validates.
- Complement it with **RFC 9234 (Only-to-Customer)** against route leaks. **ASPA is still an
  IETF draft** (`draft-ietf-sidrops-aspa-verification`), not a finished product: useful,
  not to be trusted as the only control.
- ECMP with per-flow hashing (not per-packet: it reorders and wrecks TCP). uRPF and BCP 38
  antispoofing at the edge.

**Switching**
- **LACP** aggregation (active, not `static`) against a stack/MLAG; never a single uplink on
  anything that matters.
- STP: RSTP/MSTP with the **root bridge explicitly pinned** and a priority for the secondary;
  `bpduguard` + `rootguard` + `portfast/edge` on access ports. STP with the root elected
  by MAC is a topology nobody controls.

**MTU, MSS and fragmentation** — the usual cause of "SSH works but SCP hangs":
```
MSS = MTU − 40 (IPv4)      # 20 IP + 20 TCP;  −60 en IPv6
WireGuard sobre Ethernet 1500 → MTU 1420 → clamp MSS 1380
WireGuard sobre PPPoE  (1492) → MTU 1412 → clamp MSS 1372
```
- Adjust the tunnel MTU **and also** do MSS clamping; they are not alternatives.
- `--clamp-mss-to-pmtu` when the path MTU is unknown; an explicit value when it is known.
- **Do not block ICMP type 3 code 4** (fragmentation needed): without it, PMTUD dies and
  large packets disappear silently. This is not a hole: it is diagnosis.
- Check offloading (GRO/GSO) on tunnel interfaces: it aggregates packets above the MTU
  and drops them with DF set.

**nftables skeleton (host and router)**
```nft
table inet filter {
  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iif lo accept
    ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } accept
    ip6 nexthdr icmpv6 accept                       # ICMPv6 es obligatorio, no opcional
    tcp dport 22 ip saddr @mgmt_nets accept
  }
  chain forward {
    type filter hook forward priority filter; policy drop;
    tcp flags syn tcp option maxseg size set rt mtu  # MSS clamping a PMTU
    ct state established,related accept
    # cada regla de permiso: origen, destino, puerto y comentario con el motivo
  }
  chain output { type filter hook output priority filter; policy drop; }  # egress filtrado
}
```

## 4. Mandatory quality gates

- **Syntax validation before applying**, always: `nft -c -f ruleset.nft`,
  `named-checkconf`/`named-checkzone`, `unbound-checkconf`, `haproxy -c -f`, `nginx -t`,
  `vtysh -C`, `kea-dhcp4 -t`. A config that does not validate does not even reach staging.
- **A safety net on every remote firewall/routing change**: `commit-confirm` (VyOS),
  safe mode (RouterOS), timed rollback or an open OOB console. Without it, you do not touch it.
- **Lab before production** for new topologies or protocols: containerlab or
  VMs with the same image versions as production.
- **Negative tests mandatory**: verify that what is allowed works **and that what is
  forbidden is forbidden**. A firewall tested only along the happy path is not tested.
- **Post-change test by layers**: link and interface errors → ARP/ND → route →
  connectivity → MTU with DF (`ping -M do -s`) → DNS → the real application (not just ping).
- **Drift detection as a gate**: periodic diff between the running config and the SoT
  (NetBox + templates). A difference is a finding with an owner, not a curiosity.
- Network changes by reviewed PR in the repo (templates, playbooks, rules), never by ad hoc
  CLI in production; configuration backup of every device, versioned and restorable.

## 5. Security

**Filtering policy**
- **Default-deny inbound and outbound**. Egress filtering is what stops C2 and
  exfiltration; a perimeter that only looks inwards is half built.
- Stateful firewall: beware of **asymmetric routes**, which break state tracking
  and produce intermittent failures impossible to diagnose from the application.
- Rate limiting, anti-DDoS protection and a WAF in front of what is exposed; minimum published
  surface, and what is published, inventoried.

**DNS as a security control and as a leak channel**
- All clients resolve **only** against the corporate resolver: block `udp/tcp 53`
  outbound and `853` (DoT) at the edge.
- Neutralise uncontrolled DoH: browser policy (`DnsOverHttpsMode` = off in
  Chrome, `network.trr.mode` = 5 in Firefox), blocking public DoH resolver IPs on
  443, and your own *pinned* DoH if you want encryption in transit. Application-level DoH is the
  real bypass of all DNS filtering.
- **Log 100% of the resolver's queries** and analyse label length,
  entropy, number of subdomains, volume and NXDOMAIN rate: DNS exfiltration lives
  there. Assume that purely network-based detection does not close DoH-inside-HTTPS: back it with EDR.
- DNSSEC: validation on the recursive resolver (always) and signing of your own zones.
  `HTTPS`/`SVCB` (RFC 9460) and ECH change what is visible on the wire: keep it in the model.

**Management plane and devices**
- **Out-of-band** management, on a dedicated VLAN with no route from user networks, reachable only
  via bastion/VPN. It is target number one after the first compromise.
- SSH with keys, **SNMPv3** only, centralised AAA (RADIUS/TACACS+) with named
  accounts, `enable`/local for emergencies only, in a secrets manager. No telnet, no HTTP,
  no SNMP v1/v2c, no factory credentials, unnecessary services off.
- Hardening per the vendor's CIS benchmark; firmware reviewed quarterly and on an exploitable CVE.

**Access and trust**
- **Per-application ZTNA** rather than a full-tunnel VPN that grants access to "the network"; strong
  identity (OIDC/MFA) and device posture before location.
- 802.1X on wired access and WiFi (WPA3-Enterprise), with dynamic VLAN and a quarantine
  network; `port-security` where 802.1X does not reach. MACsec on links between cabinets or
  campuses when the medium is not trusted.
- mTLS or IPsec for sensitive east-west traffic; TLS 1.2+ / 1.3 on everything published.

## 6. Performance and operability

- **Network signals that are always watched**: latency and jitter (RTT per hop), packet
  loss, per-interface errors/discards, link utilisation and saturation, routing table
  size and BGP/OSPF session state, certificate expiry and DHCP leases.
- **Flows (IPFIX/NetFlow/sFlow)** to know who talks to whom: without them there is no
  incident investigation and no sizing with data. Complement with gNMI/OpenConfig
  (streaming telemetry) where the device supports it, instead of massive SNMP polling.
- **Layered diagnosis, in order and with no skipping**: physical (light, CRC errors, negotiation)
  → link (VLAN, MAC/ARP/ND, STP) → network (route, MTU, ICMP) → transport (`ss`, retransmissions,
  handshake in a capture) → application (DNS, TLS, HTTP). Skipping layers is how hours get lost.
- **QoS**: `fq_codel`/CAKE at the edge solves bufferbloat, which is 90% of the real "the network is
  slow". DSCP is only useful if it is marked, honoured and not wiped end to end;
  marking without agreement across every hop is decorative. L4S is emerging: do not assume it.
- **Capacity with data**: plan on percentiles of real utilisation, with an action threshold
  around 70% sustained; do not size by intuition or by an anecdotal peak.
- **HA with no SPOF**: dual uplink over different paths, VRRP/CARP with **tested** failover,
  redundancy of DNS and DHCP resolvers, diversified power and switches. A failover
  that has not been exercised does not count.
- Runbooks per scenario: uplink loss, a firewall down, a route leak, DHCP pool
  exhaustion, DNS poisoning/outage, layer 2 loop. Versioned and with an owner.

## 7. Sustainability and prohibitions

- **Network as code**: topology, addressing, rules and baselines in a repo, reviewed
  by PR; idempotent automation (Ansible network collections) fed by NetBox;
  containerlab to validate before touching hardware.
- **Cadence**: firmware/IOS/RouterOS and the NOS reviewed every quarter and on a CVE with
  relevant KEV/EPSS; LTS branches of HAProxy/BIND/FRR rather than the latest minor; no
  EOL version in production without a dated exit plan (BIND 9.18 EOL Jun-2026 is the
  reminder of the quarter).
- Deprecation with a plan: every retired rule, VPN or VLAN is really deleted (config, SoT and
  documentation), it is not left "just in case" accumulating surface.

**FORBIDDEN**
- ❌ Permanent `any/any`, rules with no comment giving the reason, or `0.0.0.0/0` inbound without
  written justification.
- ❌ A firewall without egress filtering; "it's the internal network, no need to filter".
- ❌ Mixing `iptables` and `nftables` on the same host; `iptables-legacy` on new systems.
- ❌ Blocking ICMP indiscriminately (it kills PMTUD and diagnosis) or ICMPv6 in IPv6 (it breaks ND).
- ❌ Changing firewall/routing remotely without commit-confirm, timed rollback or an OOB console.
- ❌ eBGP without prefix filters, without `maximum-prefix` and without RPKI ROV.
- ❌ Management interfaces (switches, firewalls, BMC, hypervisors) reachable from user
  networks or from the Internet.
- ❌ Telnet, HTTP management, SNMP v1/v2c, default credentials, shared accounts.
- ❌ Allowing outbound DNS to any resolver, or leaving the browser's DoH without a policy.
- ❌ A single resolver, DHCP server or firewall with no redundancy on anything that matters.
- ❌ A flat VLAN "because it's easier"; IoT/OT in the same zone as servers or users.
- ❌ Tunnels without adjusting MTU or MSS and then blaming the application.
- ❌ Manual configuration not reflected in the SoT/repo (snowflakes) and uncorrected drift.
- ❌ A full-tunnel VPN granting access to the whole network instead of per-application access.
- ❌ Corporate Wi-Fi with a shared PSK instead of WPA3/802.1X.
- ❌ Populating NetBox by automatic discovery and calling it "intent".

## 8. Mandatory web verification

Before pinning any version, flag or concrete datum, **look it up — do not recall it**.
Verified Aug 2026 (expires fast): nftables 1.1.4 / firewalld 2.4.0 on Fedora 44;
OPNsense 26.7 (FreeBSD 15.1); pfSense CE 2.8.1; RouterOS 7.23 stable / 7.21.5 long-term;
VyOS Stream 2026.03; FRR 10.7.0; BIRD 3.3.1 (LTS 3.1.x); BIND 9.20.26 ESV (9.18 EOL
Jun-2026); Unbound 1.24.2; Knot DNS 3.5.4; Pi-hole FTL 6.7 / Core 6.4.3; HAProxy 3.2.x and
3.4.0 LTS; nginx 1.30.x stable / 1.31.x mainline; Traefik v3.7.10; Caddy 2.11.4;
NetBox 4.6.7; NetBird 0.65+; Headscale 0.29.x (beta).

1. Latest stable and **EOL** of every component you are going to install (endoflife.date + the
   vendor's release notes), most especially BIND, nginx, HAProxy and the device's NOS.
2. **Active CVEs with KEV/EPSS** before deciding the urgency of a patch — 2026 has been a
   dense year for nginx and BIND.
3. The state of `iptables`/`nftables` on the project's **exact** distribution (RHEL 10, Fedora,
   Debian) before writing rules: the compatibility layer changes between versions.
4. The state of **Kea** and ISC `dhcpd`, and of containerlab, FreeRADIUS, Wireshark, Akvorado and
   the UniFi Network Application — not verified in this document.
5. The state of **RPKI/ASPA** (ASPA is still a draft), ROV adoption and IPv6 figures
   (Google/APNIC): these are data that change every quarter.
6. VyOS image policy (LTS only with a subscription or contribution) and the release
   cycle of OPNsense/pfSense CE before committing to a platform.
7. The exact RFC before citing it (SVCB/HTTPS, DoQ, OTC, L4S, IPv6-mostly): number and status.

If the web contradicts this document, **the web wins** — flag the discrepancy.
