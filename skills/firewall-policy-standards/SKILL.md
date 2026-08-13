---
name: firewall-policy-standards
description: Firewall policy as a governed engineering artifact. Use when writing or reviewing nftables rulesets (nftables.conf, nft -c -f, tables/chains/hooks/priorities, sets, maps, verdict maps, ct state, meters), firewalld zones, services, policies and rich rules (firewall-cmd), ufw profiles, DOCKER-USER chains and Docker firewall-backend published-port bypass, kube-proxy nftables mode, cloud security group and NSG rule sets as filtering policy, egress allow-listing, zone-to-zone flow matrices, rule ownership, expiry dates and change approval, shadowed, duplicate, orphaned or any/any rule review, conntrack table exhaustion and asymmetric-routing state loss, MSS clamping and NAT interaction with filtering, deny logging volume and forwarding, or IPv6 rule parity with IPv4.
---

# Firewall policy standards — the rule as an engineering artifact

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **designing, writing, approving, deploying, reviewing and retiring filtering policy**:
default-deny on ingress and egress, zone-to-zone flow matrix, rule lifecycle (who requests it,
who approves it, why it exists, when it expires), policy as code and its deployment
through CI, drift against the SoT, implementation in `nftables`/`firewalld`/`ufw`, network firewall
versus host firewall, *stateful* filtering pitfalls, ruleset review and cleanup,
deny logging, and the special cases that rewrite your rules (containers,
Kubernetes, clouds) and the chronic neglect of IPv6.

Triggers: `nftables.conf`, `/etc/nftables.d/*.nft`, `nft list ruleset`, `nft -c -f`,
`table inet`, `hook prerouting|input|forward|output|postrouting`, `policy drop`, `ct state`,
`define`/`set`/`map`/`vmap`, `firewall-cmd`, `firewalld.conf`, `/etc/firewalld/zones/*.xml`,
`rich rule`, `ufw allow|deny|status`, `iptables-save`/`iptables-nft`/`iptables-legacy`,
`DOCKER-USER`, `daemon.json` with `iptables`/`firewall-backend`, `conntrack -L`,
`nf_conntrack_max`, `security group` / `NSG` / `network ACL` as policy, "flow matrix",
"temporary rule", "any/any", "open a port", "rule review", "the firewall is blocking it".

**Guiding principle** (inherits verbatim the one in `networking-standards`: *the network is default-deny and
documented as code; what is not in the SoT does not exist*): **a rule is a commitment with an
owner, a reason and an expiry date**. A ruleset is the sum of live decisions, not the sediment
of old requests: if nobody knows why a rule exists, that rule is already an administrative
vulnerability, regardless of what it permits.

**Not applicable**: see `networking-standards` (**parent**: network design, addressing and IPAM,
VLANs and segmentation, routing/BGP, RPKI, MTU/MSS at design level, proxies and load balancers,
overlays, OOB plane — **it defines the topology and the zones; which flow is permitted between
zones, under what governance and with what proof, belongs here**), `linux-hardening-standards` (**the
*host* firewall as a CIS/STIG baseline control and its measurement with `oscap`/Lynis**: that the
host has default-deny on ingress, filtered egress and a versioned ruleset is **their** control
and is audited as part of the baseline; **how that policy is designed, approved, expressed and governed
—including nftables syntax and its lifecycle— belongs here**. In practice: they require and
score, this skill decides the content),
`dns-standards` (**it exists**: the DNS service, its zones and its telemetry — **it defines which
resolver is legitimate and what it logs; you write and govern the rule** that allows `53`/`853`
towards that resolver, blocks outbound DNS to anything else and filters egress),
`detection-engineering-standards` (**what is done with your logs**: the detection rules, the
ECS/OCSF normalisation and the analytics on `deny` are theirs; **the telemetry you generate —what
is logged, with which fields, at what rate and to where— is yours**),
`observability-standards` (metrics, dashboards and alerts for the firewall as a service),
`selinux-standards` (MAC as an orthogonal control: network filtering does not replace process
confinement), `kubernetes-standards` (`NetworkPolicy`, CNI and in-cluster policy;
**here only the interaction of kube-proxy/CNI with the node's ruleset**),
`container-runtime-security-standards` (container isolation and escape),
`aws-standards`/`azure-standards`/`gcp-standards` (Security Groups, NSG, NACL and managed
firewalls as a **provider service**: their model, limits and IaC are theirs; **the criteria of
default-deny, rule ownership and expiry belong here and apply just the same**),
`iac-standards` (Terraform/Ansible that deploy the policy: module structure, Molecule,
lint), `cicd-standards` (the pipeline that validates and applies), `grc-compliance-standards` (the
periodic rule review as an auditable control for ENS/ISO 27001/NIS2/PCI),
`incident-response-forensics-standards` (the firewall log as evidence and containment
blocking during a compromise), `identity-access-management-standards` (bastion identity
and JIT elevation versus IP-based access), `onprem-standards` (platform umbrella),
`homelab-standards` (your own lab: the boundary is the rigour required, not the size),
`bcdr-standards` (ruleset restoration as part of recovery),
`offensive-security-standards` (offensive validation of the policy, with scope and authorisation),
`ot-ics-security-standards` (**which conduit may exist between industrial zones is decided there**
—IEC 62443-3-2 zones and conduits, level 3.5 DMZ, data diode—; **here the rule that implements it is
written, approved and governed**).

Also:
`vpn-standards` (**the tunnel is theirs; the policy that filters the traffic leaving the tunnel is
yours** — a `wg0` that enters `forward` with no rules is a VPN without a firewall),
`network-troubleshooting-standards` (**diagnosis**: you set what the correct policy is and
prove that what is denied gets denied; they work out **why** a specific packet does not arrive —
when the symptom is "this does not connect", the answer "a rule is missing" belongs here and the answer
"state is lost through asymmetric routing" is diagnosed there and fixed here),
`linux-administration-standards`, `ha-clustering-standards`, `proxmox-ve-standards`.

## 2. Default decisions / Toolchain

> Verify the latest version and its status on the project's **exact distro** before committing to anything
> (§8): the `iptables`↔`nftables` compatibility layer changes between versions and between distros.

| Area | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Filtering engine on Linux | **nftables** native, a single `inet` table with IPv4+IPv6 (upstream 1.1.6, 2025-12-05; Fedora 44 packages 1.1.4) | `firewalld` (**2.5.0**, 2026-07-08, nftables backend) when there are dynamic zones, interfaces that come and go, or integration with NetworkManager/Podman/libvirt | `iptables-legacy`; **mixing** `iptables` commands and `nft` rules on the same host |
| Compatibility layer | `iptables-nft` **only as a shim for third parties** that do not yet speak nft | Temporary coexistence, documented and with an exit date | Writing new policy in iptables syntax |
| Simple host, single administrator | **nftables directly** with a versioned file | `ufw` only on a host with a trivial profile (`allow 22`, `allow 443`) | `ufw` as corporate policy: **it has no native nft backend**, only `backend_iptables.py` on top of `iptables-nft`, and it competes for ownership of the ruleset with any other manager |
| Perimeter | The organisation's platform (OPNsense/VyOS/appliance) governed as code — the platform choice, in `networking-standards` | — | Rules written by hand in the GUI with no reflection in the SoT |
| Source of truth | **Git repo off the device**; the device is a deployment target, not the source | Export from the device as *evidence* compared against the repo | The running config as the only copy of the policy |
| Rule object | **Named sets and maps** (`@mgmt_nets`, `@web_ports`) and `vmap` for verdict routing | Literals only in genuinely unique rules | Hundreds of near-identical rules that should be a set (a structural source of duplication and shadowing) |
| Application | `nft -f` (**atomic**: either the whole ruleset applies or none of it does) from CI | `firewall-cmd --permanent` + `--reload` | Interactive incremental rules in production |
| Kubernetes | `kube-proxy` in **nftables** mode (GA in 1.33, requires kernel ≥5.13) on large clusters | `iptables` mode (**still the upstream default**, with no announced change date) | `IPVS` in new deployments (**deprecated in 1.35**) |
| Docker | `DOCKER-USER` as the policy insertion point with the iptables backend | **Experimental nftables backend** (Docker Engine 29, `"firewall-backend": "nftables"` in `daemon.json`) in lab only | `DOCKER_INSECURE_NO_IPTABLES_RAW=1` in production |
| Kernel | Pin a minimum of **≥6.18.10 / 6.19**, or backports **5.15.200, 6.1.163, 6.6.124, 6.12.70** | The distro kernel with the CVE already backported (verify, do not assume) | A kernel without the **CVE-2026-23111** patch (UAF in `nf_tables`, local LPE, CVSS 7.8) with unprivileged user namespaces enabled |

## 3. Structure and conventions

### 3.1 Default-deny for real: ingress **and** egress

- `policy drop` on `input`, `forward` **and `output`**. A policy that only looks inwards is
  half built: **egress filtering is what cuts C2, exfiltration and second-stage
  downloads**, and it is exactly what almost nobody does because it hurts for two weeks.
- **Egress by allow-list, by destination and by source**: which hosts may go out, where and
  to which port. Cases that must be resolved explicitly before enabling it: DNS (only towards the
  corporate resolver — see `dns-standards` for which one is legitimate), NTP, package and image
  repositories, telemetry, ACME, outbound mail, and OS updates themselves.
- **Adoption strategy without cutting the service**: (1) `output` in logging mode with a final rule
  `log prefix "EGRESS-WOULD-DROP " counter` and `accept`; (2) analyse the log for one or two
  complete business cycles (including month-end close and backup windows); (3) write the
  rules with an owner; (4) flip to `drop` with the rescue session open. **Skipping step 2
  is how you break production on a Friday.**
- Egress via an **explicit proxy** when the destination is HTTP(S): filtering by IP in the CDN era is
  chasing a moving target. The proxy gives you a name, not just an address (proxy choice and deployment,
  in `networking-standards`).
- **An exception that is not an exception**: ICMP and ICMPv6. Do not block `destination-unreachable` /
  `fragmentation needed` (it kills PMTUD) nor ICMPv6 in general (it breaks ND and with it IPv6).

### 3.2 The lifecycle of a rule

Every rule has, in the repo, **six mandatory fields**; without them the PR is not approved:

| Field | Meaning |
|---|---|
| `id` | Stable identifier, citable in tickets and in the review |
| `owner` | **A person or team**, not "infrastructure". When that person leaves, the rule is reassigned or retired |
| `justification` | The **business or technical reason**, not the description of the rule ("allows tcp/5432" is not a justification) |
| `requested_by` / `approved_by` | Who requested it and who approved it. High risk (broad egress, ingress from the Internet, `any`) requires security approval, not just network approval |
| `expires` | **Mandatory expiry date.** Permanent is an explicit and exceptional value, not the default |
| `review` | Date of the last review and its outcome |

- **A rule without an owner or a date is permanent debt.** The system default must be
  expiry: what has to be justified is permanence, not termination.
- **Rules that expire on their own**: temporary vendor access, maintenance window,
  debugging, migration. They are implemented with a **native timeout** (an nftables set element with
  `timeout 4h`, which the kernel expires by itself) or with a CI job that rebuilds the ruleset from the
  repo and leaves out whatever has expired. **Always** prefer the automatic mechanism: human discipline
  does not revert rules at 3 in the morning.
- **The "temporary any/any" that has been there for four years** is the central anti-pattern of this document.
  Its origin is always the same: incident + haste + "we will tighten it tomorrow" + no date. The defence
  is not cultural, it is mechanical: **every emergency rule is born with `expires` at ≤72 h** and its
  renewal requires a new PR with justification. If nobody claims it when it expires, it falls away on its own —and
  that is precisely the desired outcome.
- **Retirement**: removing a rule includes retiring it from the repo, from the device, from the flow
  inventory and from the documentation. A rule "commented out just in case" is still a pending
  decision; it gets deleted, that is what Git history is for.

### 3.3 Zone design and flow matrix

- Zones are defined by the topology (`networking-standards`); **the matrix belongs here**: a table
  source × destination where each permitted cell lists protocol, port, direction of initiation,
  owner, justification and expiry. Every unlisted cell is `deny`.
- **The matrix is the approved document**; the ruleset is its compilation. It is reviewed with the business and
  with security, it is versioned, and it is used as audit evidence.
- **East-west microsegmentation**: most of a datacenter's traffic never crosses the
  perimeter. Filtering only north-south leaves lateral movement uncontrolled. Location on the network
  does not confer trust (NIST SP 800-207).
- **Named addresses and groups**: the matrix speaks of roles (`web`, `db`, `mgmt`), not of IPs.
  Sets translate role→addresses and are fed from the IPAM/SoT.

### 3.4 Host firewall **and** network firewall: both

- **They are not alternatives, they are layers.** The network one applies policy between zones and survives
  compromise of the host; the host one applies policy **per service**, sees traffic that never crosses
  a router (same segment, same hypervisor, same node) and is the only defence against
  lateral movement within a VLAN. Whoever says "the perimeter already filters that" is asserting that
  their VLAN is a flat trust zone.
- The host firewall is moreover **the measurable baseline control** (`linux-hardening-standards`):
  they require it to exist and they score it; **its content and governance are decided here**, with the same
  lifecycle, the same repo and the same gates as network policy.
- **Mandatory coherence**: host and network are generated from the **same** flow SoT. Two policies
  written separately diverge within weeks and produce the worst kind of diagnosis ("it works
  from here but not from there").

### 3.5 Stateful and its pitfalls

- **`ct state established,related accept` first, `ct state invalid drop` always.** Without the
  second, out-of-state packets traverse rules meant for new connections.
- **Asymmetric routes**: if the outbound and return paths go through different firewalls (or through only one in one
  direction), state does not exist for the return leg and traffic drops **intermittently and
  irreproducibly**. Classic symptom: "it works for a while and then it cuts out". It is a path design
  problem, not a rule problem: it is fixed by enforcing symmetric routing or by synchronising state between the pair
  (`conntrackd`/pfsync), never by adding a broad `accept` to "make it work".
- **Conntrack exhaustion**: `nf_conntrack_max` reached ⇒ silent drops and one line
  in `dmesg` that nobody looks at. **Monitor table occupancy as a first-class metric**
  (§6), size it against the box's memory and review the timeouts: `tcp_timeout_established`
  defaults to days and keeps dead flows that hold NAT open and fill the table. A load balancer
  or a server with a huge number of short connections may justify selective `notrack` on traffic
  that does not need it —a conscious, documented decision, and never on traffic filtered by state.
- **UDP and "state" are a useful fiction**: conntrack infers UDP flows by timeout. Tune
  UDP timeouts and consider the NAT impact for applications with long keepalives.
- **MTU/MSS and fragmentation**: a fragment carries no ports, so only the first one matches
  L4 rules. Apply **MSS clamping** on `forward` over tunnels (`tcp flags syn tcp option maxseg
  size set rt mtu`) — the values and the MTU design, in `networking-standards`. A firewall that
  simply drops fragments breaks large DNS, IPsec and VPN.
- **NAT and filtering are evaluated at different moments**: DNAT happens in `prerouting`, before
  `forward`, so that the filtering rules see the **already translated internal IP**, not the
  published one. Writing the rule against the public IP is the rookie mistake that opens what you thought you were
  closing. The order: `prerouting` translates, `forward` decides. And SNAT/masquerade filters nothing:
  hiding is not protecting, and with IPv6 that illusion disappears.

### 3.6 Reference skeleton (nftables, single `inet` table)

```nft
# SoT: repo/firewall/base.nft — deployed by CI with `nft -f` (atomic). Do not edit on the host.
table inet policy {
  set mgmt_nets   { type ipv4_addr; flags interval; elements = { 10.0.10.0/24 } }
  set mgmt_nets6  { type ipv6_addr; flags interval; elements = { 2001:db8:10::/64 } }
  set temp_access { type ipv4_addr; flags timeout; }        # added with `timeout`, they expire on their own

  chain input {
    type filter hook input priority filter; policy drop;
    ct state established,related accept
    ct state invalid drop
    iif lo accept
    ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded } accept
    icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert,
                  echo-request, packet-too-big, time-exceeded, parameter-problem } accept
    # id=FW-001 owner=plataforma expires=2027-01-31 just="administration via bastion"
    ip  saddr @mgmt_nets  tcp dport 22 accept
    ip6 saddr @mgmt_nets6 tcp dport 22 accept
    limit rate 10/second burst 20 packets log prefix "IN-DENY " level info counter
  }

  chain forward {
    type filter hook forward priority filter; policy drop;
    tcp flags syn tcp option maxseg size set rt mtu     # MSS clamping on tunnels
    ct state established,related accept
    ct state invalid drop
    limit rate 10/second burst 20 packets log prefix "FWD-DENY " level info counter
  }

  chain output {
    type filter hook output priority filter; policy drop; # egress filtered, not decorative
    ct state established,related accept
    # id=FW-010 owner=plataforma expires=permanent just="internal resolution (see dns-standards)"
    ip daddr @resolvers udp dport 53 accept
    ip daddr @resolvers tcp dport { 53, 853 } accept
    limit rate 10/second burst 20 packets log prefix "OUT-DENY " level info counter
  }
}
```

Notes on form that are criteria, not style: **a single `inet` table** (IPv4 and IPv6 in the same
rules avoids divergence); **a comment with `id`, `owner`, `expires` and justification on every
permit rule**; **named sets** instead of repeated literals; `counter` on the rules
you want to be able to audit by usage; and the deny `log` **always rate-limited**.

## 4. Mandatory quality gates

In order of increasing cost. **Gates 1, 2, 3 and 5 are automatable and break the build or the
deployment. Gate 4 is not a gate: it is a hard operational precondition** — nothing in a pipeline
can assert that a rescue session is open, so it blocks the human making the change, not the merge.
Do not implement it as CI and do not report it as automated coverage.

1. **Syntax validation**: `nft -c -f ruleset.nft` (and `firewall-cmd --check-config` where
   applicable) on every PR. A policy that does not validate does not even reach staging.
2. **Policy lint** in CI, failing hard:
   - No base chain without `policy drop`.
   - No permit rule without `id`, `owner`, `justification` and `expires`.
   - **No expired rule** (`expires` in the past) and a warning at 30 days.
   - No `any`/`0.0.0.0/0`/`::/0` in source **and** destination at the same time without the approved
     exception tag.
   - **IPv6 parity**: every IPv4 rule has its IPv6 equivalent or a justified exemption. This
     gate exists because **forgetting IPv6 is the most common failure in the trade**: the service listens
     on `::`, the attacker arrives over IPv6 and the policy only covered IPv4.
   - No orphaned rule: every `id` exists in the approved flow matrix.
3. **Testing in an equivalent environment before production**: apply the ruleset on a twin host or VM
   and run the connectivity test suite. New topology or protocol changes,
   in a lab (containerlab) before touching hardware.
4. **Application with a safety net — no exceptions.** Every remote firewall change is made
   with a **rescue session open or an OOB console available**, and with timed rollback:
   `commit-confirm` (VyOS), safe mode (RouterOS), or on Linux an `at`/`systemd-run --on-active`
   that restores the previous ruleset in N minutes unless explicitly confirmed. Without that, **do not
   touch it**. Locking yourself out of the firewall is the most predictable and most avoidable incident there is.
5. **Mandatory negative testing**: verify that what is permitted works **and that what is denied gets
   denied**, from the real source and against the real destination. A port sweep from one zone
   towards another confirming that only the expected things respond (with internal authorisation;
   `offensive-security-standards` for formal validation). A firewall tested only along the
   happy path **is not tested**: you do not know whether your rule works or whether the service was already
   down.
6. **Drift detection**: periodic and automatic comparison between `nft list ruleset` (or the
   device export) and the artifact generated from the repo. Every difference is a finding
   with an owner. Drift is the metric of whether your governance is real or theatre.
7. **Periodic ruleset review** (quarterly at the perimeter, twice-yearly internally) producing
   a report with: **expired** rules, rules **without an owner**, **unused** ones (counter at zero for the whole
   period), **shadowed** ones (never reached because of an earlier rule), **duplicate** ones,
   **redundant** ones (a subset of another), **generalised** ones and **excessively permissive** ones. Each
   finding is closed with an action, not with a "reviewed". This report is direct evidence for
   `grc-compliance-standards`.
8. **Reachability verification before merge** in complex topologies (several firewalls in the
   path): model the change and check what it really opens and closes, including the rules of
   the other devices along the path. It is the only way to detect shadowing *between* boxes.

## 5. Security

### 5.1 Logging and observability of the policy

- **`deny` events are logged, and they matter more than the `allow` ones.** An expected `allow` tells you
  nothing; a repeated denial is either an attack, or an uncommunicated change, or a missing
  rule. All three cases require action.
- **Format and fields**: a stable prefix identifiable per chain (`IN-DENY`, `FWD-DENY`,
  `OUT-DENY`), with source/destination IP, ports, protocol, interface and timestamp. The prefix is a
  contract: `detection-engineering-standards` builds rules on top of it and breaking it breaks their
  detections.
- **Volume and cost are a design problem, not an accident**: a `log` without `limit` in an Internet-facing
  `drop` chain is a self-denial of service and a SIEM bill. Always use
  `limit rate`, aggregate with `counter` whatever you only need to count, and decide what is sent
  to the SIEM and what stays in cheap storage. Logging everything at the same priority amounts to
  logging nothing.
- **Denied egress is the golden signal**: an internal host trying to reach a destination that is not
  permitted is, almost always, either misconfigured software or something that should not be there. That
  signal only exists if there is an egress policy.
- **Per-rule counters** as the source for the unused-rule review (§4.7) and for
  sizing. Without counters, "this rule is no longer needed" is an opinion.

### 5.2 Containers: the classic of publishing a port and bypassing the firewall

- **The failure**: when publishing a port (`-p 5432:5432`), Docker inserts its own NAT rules
  in `prerouting` and forwarding rules in `forward`. Inbound traffic towards the container **never
  traverses `input`**, which is where `ufw`'s policy and that of most host rulesets live.
  Result: "the port is blocked" and "the port is open" are true at the same time, and the
  service ends up exposed to the network while you believe otherwise. **Risk class: unintended
  exposure through a bypass of the filtering chain**, not a product vulnerability.
- **Mitigations, in order of preference**:
  1. **Do not publish what must not be public**: explicit bind to loopback (`127.0.0.1:5432:5432`)
     and a reverse proxy as the only surface. Most of these incidents are solved here.
  2. **Policy in `DOCKER-USER`**, which Docker evaluates **before** its own accept
     rules: it is the supported insertion point with the iptables backend, and it survives
     daemon restarts and container recreation.
  3. `internal` networks for whatever must not go out, and `expose` instead of `publish` when
     container-to-container communication is enough.
  4. Persist your rules with a systemd unit that runs **after** Docker; verify
     with a scan **from another machine**, never from the host itself.
- **What has changed (verified Aug 2026)**: **Docker Engine 28.0** hardened the default
  behaviour — unsolicited inbound traffic towards a container's internal IP is
  dropped unless the port has been explicitly published, closing the case of containers
  reachable from the LAN with `FORWARD` set to `ACCEPT`. **There is still an `input` bypass** for
  the ports you do publish: the fundamental pattern has **not** gone away.
  `DOCKER_INSECURE_NO_IPTABLES_RAW=1` disables `raw` table rules and **reopens** part of that
  hardening (including the protection of ports published on 127.0.0.1): vetoed in production.
- **Docker Engine 29** introduces an **experimental nftables backend**
  (`"firewall-backend": "nftables"`), which creates its own `ip docker-bridges` /
  `ip6 docker-bridges` tables, does **not** create a `DOCKER-USER` chain and does **not** support Swarm. Operational
  translation: if you enable it, your policy insertion point changes and your current rules stop
  applying. Lab only until it stops being experimental.
- **Distribution trap** (Debian 13 and equivalents): a container whose image ships
  `iptables-legacy` writing rules while the host uses `iptables-nft` leaves those rules in
  tables the kernel **does not consult**. They fail silently: the operator believes they have filtered.
- **Kubernetes**: `kube-proxy` and the CNI generate and regenerate their own chains on the node. **Do not
  edit their chains**; write your policy in your own tables/priorities that are evaluated earlier, and
  use `NetworkPolicy` for what is pod policy (`kubernetes-standards`). `kube-proxy` in
  nftables mode has been GA since 1.33 but **iptables is still the default**, and both modes
  coexist across a heterogeneous fleet: your node ruleset must tolerate both.
- Podman/netavark: the nftables driver is the supported path and the iptables one is being retired;
  verify which is active before writing rules around it.

### 5.3 Clouds: security groups as the logical equivalent

- Security Groups, NSG and NACL **are filtering policy** and **everything** in this document applies to them:
  default-deny, owner, justification, expiry, periodic review, IPv6 parity and deployment by
  code. The specific model and its limits, in `aws-standards`/`azure-standards`/`gcp-standards`.
- Differences that change the design and that must be kept in mind: SGs are usually **stateful and
  allow-only** (there is no "explicit deny", which eliminates shadowing but also the
  ability to make exceptions), NACLs are **stateless** (you have to open the return path and the ephemeral
  ports by hand, a common mistake), and there are **hard rule limits per group** that push you to
  group by role —which is, moreover, the correct design.
- **The SG does not replace the host firewall**: within the same group, traffic is usually
  permitted implicitly. And `0.0.0.0/0` in an SG is exactly the same finding as in
  a physical firewall.

### 5.4 Management plane

- Firewall administration arrives **only** from the OOB/bastion network, with MFA and named
  accounts; the firewall itself does not expose its management plane to user networks or to the Internet
  (OOB design in `networking-standards`, identity in
  `identity-access-management-standards`).
- **Golden anti-lockout rule**: the rule that permits your management access is the first one
  written, the last one touched and the one that never depends on a change in flight.
- Every change is **attributed to a person**: applied by CI from a signed PR. A
  change applied by hand on the device is, by definition, a change with no verifiable author.
- **Kernel and engine up to date**: netfilter itself is surface. **CVE-2026-23111** (UAF in
  `nf_tables`, local escalation to root via user namespaces, CVSS 7.8, published 2026-02-13) requires
  kernel ≥6.18.10/6.19 or the backports 5.15.200 / 6.1.163 / 6.6.124 / 6.12.70. Complementary
  mitigation while patching: restrict unprivileged `user namespaces` and access to
  `CAP_NET_ADMIN` (baseline detail in `linux-hardening-standards`).

## 6. Performance and operability

- **First-class metrics**: conntrack table occupancy against `nf_conntrack_max`
  (alert at 70-80%: it is a silent outage announced in advance), packet drop rate per chain,
  per-rule counters, network *softirq* CPU, and added latency along the path. Collection,
  thresholds and alerts, in `observability-standards`.
- **The cost of a badly written ruleset**: evaluation is linear per chain. Thousands of sequential
  rules where a **set** or a **map** would resolve in constant time is a performance
  *and* maintainability problem. nftables sets and maps are not syntactic sugar: they are the
  difference between reviewing 40 rules and reviewing 4,000.
- **Order by frequency, not by aesthetics**: `ct state established,related accept` first,
  always; the most common, earlier; the exceptional, later. And with `vmap` instead of long chains
  of comparisons when the criterion is a discrete value.
- **HA**: a firewall pair with state synchronisation (`conntrackd`/pfsync/VRRP) and **exercised**
  failover. Without synchronisation, every failover cuts all active sessions —sometimes that is
  acceptable, but it must be a decision, not a surprise.
- **Recovery**: the ruleset is restored from the repo onto a clean box in minutes, and that is
  tested (`bcdr-standards`). The backup of the device configuration is evidence, not
  a source.
- **Runbooks with an owner**: accidental lockout of management access, conntrack exhausted, loss of one
  node of the HA pair, an expired rule that cuts a service in production, legitimate traffic denied
  after a deployment, emergency opening (with its ≤72 h expiry already included in the
  template).

## 7. Sustainability and prohibitions

- **Cadence**: rule review quarterly at the perimeter and twice-yearly internally (§4.7); review
  of the engine version (nftables/firewalld) and of kernel/netfilter CVEs monthly; migration of everything
  still left in iptables syntax with a written exit date.
- **Continuous simplification**: each review must **reduce** the number of rules or justify why
  it grows. A ruleset that only grows is a ruleset nobody understands any more, and a ruleset nobody
  understands cannot be audited or changed safely.
- **Single ownership of the ruleset**: one manager per host. `ufw` + `firewalld` + your own nft
  rules + Docker fighting over the same ruleset produces unpredictable effective policy. Decide
  who is in charge and disable the rest explicitly.

**FORBIDDEN**
- ❌ A base chain without `policy drop`; "default-allow and we will close things down as we go".
- ❌ A firewall without **egress** filtering; "it is an internal network, no need to filter outbound".
- ❌ A rule without an owner, without a business justification or without an expiry date.
- ❌ `any/any` (or `0.0.0.0/0`↔`::/0`) "temporary" without `expires` and without security approval.
- ❌ Changing the firewall remotely without a rescue session, an OOB console or timed rollback.
- ❌ Accepting a policy as good without **negative proof** that what is denied gets denied.
- ❌ Editing rules by hand on the device instead of through PR + CI; leaving drift uncorrected.
- ❌ The *running* configuration as the source of truth for the policy.
- ❌ Mixing `iptables` and `nftables` on the same host; writing new policy in iptables syntax;
  `iptables-legacy` on new systems.
- ❌ Several managers competing for the ruleset (`ufw` + `firewalld` + nft + Docker).
- ❌ **IPv4 policy without its IPv6 equivalent** (the most common and most exploited omission).
- ❌ Blocking ICMP indiscriminately (it kills PMTUD and diagnosis) or ICMPv6 (it breaks ND).
- ❌ `log` without `limit rate` in exposed drop chains.
- ❌ Not logging denials, or not forwarding them to detection engineering.
- ❌ Filtering against the public IP in rules that are evaluated **after** DNAT.
- ❌ Ignoring `ct state invalid`, or adding a broad `accept` to paper over an asymmetric route.
- ❌ Not monitoring conntrack occupancy.
- ❌ Publishing container ports without checking the real exposure **from another machine**.
- ❌ `DOCKER_INSECURE_NO_IPTABLES_RAW=1` in production; editing by hand the Docker,
  `kube-proxy` or CNI chains.
- ❌ Treating cloud Security Groups as something other than firewall policy.
- ❌ Relying on NAT/masquerade as a security control.
- ❌ A firewall management plane reachable from user networks or from the Internet.
- ❌ A kernel without the CVE-2026-23111 patch on multi-user hosts or hosts with untrusted containers.
- ❌ Hundreds of near-identical rules where a set or a map was the right answer.

## 8. Mandatory web verification

Before pinning any version, behaviour or limit, **look it up — do not recall it**.
Verified Aug 2026:

- **nftables**: latest upstream **1.1.6 (2025-12-05)**; previous 1.1.5 (2025-08-27) and
  1.1.4 (2025-08-06). **firewalld 2.5.0 (2026-07-08)**, nftables backend.
- **iptables→nftables migration**: nftables is the default framework across all major
  distros; **`iptables-nft` still exists as a shim** in RHEL 9/10, Debian 13 (trixie) and
  Ubuntu — **its removal has not been confirmed in any of them**, only its deprecation.
  Verify on the project's **exact** distro. Confirmed trap: containers with
  `iptables-legacy` on an `iptables-nft` host write rules the kernel ignores.
- **ufw**: **it has no native nftables backend**; only `backend_iptables.py` on top of `iptables-nft`.
  The maintainer states ongoing maintenance but no priority for `backend_nft.py`.
- **Docker**: Engine **28.0** drops unsolicited inbound traffic to container IPs unless the
  port is published; the `input` bypass for published ports **persists**;
  `DOCKER_INSECURE_NO_IPTABLES_RAW=1` discouraged. Engine **29** adds
  `"firewall-backend": "nftables"` as **experimental** (tables `ip docker-bridges`/`ip6
  docker-bridges`, **no `DOCKER-USER`**, **no Swarm**).
- **Kubernetes**: `kube-proxy` nftables mode **GA in 1.33**, requires kernel ≥5.13, **is not the
  default** (iptables still is, with no announced change date); **IPVS deprecated in 1.35**.
- **CVE**: **CVE-2026-23111** — UAF in `nf_tables` (`nft_map_catchall_activate()`, inverted
  check), local LPE via user namespaces, **CVSS 7.8 (AV:L/AC:L/PR:L/UI:N/C:H/I:H/A:H)**,
  published 2026-02-13. Patched in **≥6.18.10 and 6.19**, backports **5.15.200, 6.1.163,
  6.6.124, 6.12.70**. Re-verify the current month's netfilter CVEs before pinning a minimum.

**Declared gaps — do NOT fill from memory, verify before use**:
1. **nftables version packaged by distro**: only 1.1.4 on Fedora 44 is on record (inherited from
   `networking-standards`, not re-verified). The versions in RHEL 10, Debian 13 and Ubuntu LTS
   are **not verified**.
2. **Specific `ufw` version** current in 2026: **not obtained**. Check with `ufw --version`
   or on the distro's package page.
3. **Ruleset auditing tools**: `audit-springbok` exists (anomaly taxonomy:
   shadowing, redundancy, generalisation, correlation) and Batfish for pre-merge reachability
   verification, but **no native shadowing/redundancy analyser has been found
   for nftables**, and **the maintenance status and current version of both tools are not
   verified**. Do not recommend them as products without checking; the anomaly taxonomy in
   §4.7 is valid as a criterion.
4. **Detail of the Security Groups/NSG/NACL model** (rule limits, exact stateful semantics,
   IPv6 support): described at the level of criteria, **not verified against the current
   documentation of each provider**. Cross-check with `aws-standards`/`azure-standards`/`gcp-standards`.
5. **Status of the iptables driver in Podman/netavark** (deprecated or already removed?, in which version):
   only a maintainer's declared intent is on record. Verify before asserting it.
6. **Exact syntax and availability of `--check-config` in firewalld 2.5.0**: cited from memory,
   **not verified**.
7. **Status of conntrackd/pfsync and of state synchronisation options** on the specific
   perimeter platforms: not verified in this pass.

If the web contradicts this document, **the web wins** — flag the discrepancy.
