---
name: dns-standards
description: DNS service architecture, zone design and DNS security. Use when editing zone files or named.conf, unbound.conf, knot.conf, kresd config, nsd.conf, pdns.conf, dnsmasq.conf or pihole.toml, designing SOA timers, TTL, delegation and glue, CNAME-at-apex with ALIAS/ANAME, CAA, HTTPS/SVCB, SSHFP, TLSA/DANE, PTR records, DNSSEC signing and KSK/ZSK rollover, NSEC3 parameters, RRL, TSIG-protected AXFR/IXFR, split-horizon views, anycast authoritatives, .internal or home.arpa naming, zone-as-code with dnscontrol or octodns, named-checkzone, kdig, dig +trace, DoT/DoH/DoQ resolver transport, dangling subdomain takeover, DNS tunneling exfiltration or registrar/NS hijack.
---

# DNS standards — critical service and attack surface

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, deploying, reviewing or auditing **the DNS service and its data**:
authoritative/recursive separation, redundancy and anycast, software choice by role, zone design
(SOA, TTL, delegation, glue, apex), modern record types, mail authentication in DNS, DNSSEC and
its lifecycle, encrypted transport (DoT/DoH/DoQ), internal namespace, zone as code, validation
and monitoring, and the security of the name as an asset (registrar, NS, dangling subdomains,
tunneling, amplification, transfers).

Triggers: zone files (`db.*`, `*.zone`, `$ORIGIN`, `$TTL`), `named.conf`,
`named-checkconf`/`named-checkzone`, `unbound.conf`, `unbound-checkconf`, `knot.conf`,
`kresd`/`kresctl`, `nsd.conf`, `pdns.conf`, `recursor.conf`, `dnsdist.conf`, `dnsmasq.conf`,
`pihole.toml`, `Corefile` *outside* Kubernetes, `dnscontrol`/`dnsconfig.js`, `octodns`
(`config/*.yaml`), `dig`/`kdig`/`delv`/`drill`, `dnsviz`, `zonemaster`, `keymgr`/`dnssec-signzone`,
`rndc`, `TSIG`, "TTL", "SOA", "glue", "CNAME at the apex", "DMARC", "SPF", "DKIM", "MTA-STS",
"CAA", "expired DNSSEC", "NXDOMAIN", "dangling subdomain", "takeover".

**Guiding principle** (inherits the one from `networking-standards`: *the network is default-deny
and documented as code; what is not in the SoT does not exist*): **the zone is code and the name is
an identity asset**. Every record exists because someone justified it and it landed in the repo;
every name that no longer serves a purpose is deleted the day it stops serving one. Whoever
controls your delegation controls your mail, your certificates and your identity: DNS is not
"supporting infrastructure", it is the operational root of trust of almost everything else.

**Not applicable**: see `networking-standards` (**parent**: network design, addressing and IPAM,
VLAN, routing/BGP and RPKI, MTU/MSS, proxies and load balancers, overlays, resolver placement in
the topology and blocking outbound DNS at the edge as a *network decision* — here the **DNS
server, its zone and its data**), `firewall-policy-standards` (the policy that permits `53/853/443`
towards the resolver and that filters DNS egress: **you define which resolver is legitimate and what
telemetry it produces; they write and govern the rule**), `linux-hardening-standards` (CIS baseline
of the host serving DNS, including its host firewall, `systemd` sandboxing of the daemon and
`resolv.conf` as a baseline control), `cryptography-pki-standards` (**DNSSEC algorithm choice
and key management/custody**, TLS for DoT/DoH, ACME issuance and `CAA` as an issuance control seen
from the PKI — here only the **published record** and its operation),
`detection-engineering-standards` (**detection rules over query logs**: tunneling,
DGA, anomalous NXDOMAIN, C2 — the telemetry and its quality are this skill's, the analytics are
theirs), `observability-standards` (service metrics, dashboards and alerts), `onprem-standards`
(platform umbrella and OOB plane), `homelab-standards` (Pi-hole/AdGuard and home DNS: the
boundary is the rigour required, not the size), `kubernetes-standards` (**CoreDNS inside the
cluster**, `dnsPolicy`, `ndots`, Gateway API), `aws-standards`/`azure-standards`/`gcp-standards`
(Route 53, Azure DNS and Cloud DNS as the provider's managed service, including their private
zones), `secrets-management-standards` (custody of the **DNS provider API credentials**
used by ACME DNS-01 challenges), `identity-access-management-standards` (MFA and registrar
accounts as privileged identity), `incident-response-forensics-standards` (the DNS log
as evidence and its chain of custody during a compromise), `data-platform-standards`
(retention and cost of the query log store), `grc-compliance-standards` (DNS as a
control against ENS/ISO/NIS2), `bcdr-standards` (RTO/RPO of the name service),
`iac-standards`/`cicd-standards` (the repo and the pipeline that deploy the zone).

Also:
`vpn-standards` (resolution inside the tunnel, VPN client *split* DNS and DNS leakage outside
the tunnel), `network-troubleshooting-standards` (**diagnosis**: you set what the correct answer
is and who must give it; they find out why the packet or the answer does not arrive — when
the symptom is "it does not resolve", the zone and resolver design is from here, the capture and
the layer-by-layer tracking is theirs), `linux-administration-standards` (`resolv.conf`, `resolvectl`,
`systemd-resolved`, `nsswitch.conf` and resolution **from the host**),
`ha-clustering-standards`, `proxmox-ve-standards`.

## 2. Default decisions / Toolchain

> Verify the latest version and maintenance status on the web before pinning it in a
> real project (§8). **2026 is an anomalous year**: LLM-assisted analysis has driven up the volume of
> CVEs in BIND, Unbound and dnsmasq, and the branches publish security patches almost monthly.
> A version pinned today = debt tomorrow; what gets pinned is the **branch**, not the point release.

| Role | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Authoritative | **Knot DNS 3.5.x** (3.5.6 the most recent tagged) for automatic signing and performance | **BIND 9.20.x** (9.20.26, 22 Jul 2026) if you need its ecosystem; **NSD 4.15.0** (7 Jul 2026) as a minimalist secondary; **PowerDNS Authoritative 5.1.x** with an SQL/LMDB backend if the zone lives in a database | **BIND 9.18 (EOL Jun 2026)**; development branches (9.21/9.23) in production; the same process serving authoritative and recursive |
| Recursive/validator | **Unbound 1.25.x** (1.25.2, 22 Jul 2026, security release) or **Knot Resolver 6.4.x** (6.4.0, 17 Jun 2026) | BIND 9.20.x as recursive if it is already the house standard | `dnsmasq` and `systemd-resolved` as reference **DNSSEC validators**; a resolver open to the Internet |
| DNS load balancing/proxy and protection | **dnsdist 2.0.x/2.1.x** in front of recursives and authoritatives (rate limiting, DoH/DoT/DoQ termination, policies) | Anycast + ECMP with no proxy on pure authoritatives | Publishing the recursive directly to the Internet "for testing" |
| Cluster DNS | **CoreDNS 1.14.6** (10 Jul 2026) — **its configuration inside Kubernetes is set by `kubernetes-standards`** | CoreDNS as a general-purpose recursive only in very bounded scenarios | CoreDNS as a public authoritative for business zones |
| Lightweight forwarder / small DHCP-DNS | `dnsmasq` **2.93** (pin ≥2.93: closes the batch of 6 coordinated CVEs from May 2026, incl. heap overflow CVE-2026-2291) | The router's forwarder in a lab only | Any `dnsmasq` < 2.92rel2 exposed |
| Lab/home DNS filtering | **Pi-hole FTL 6.7** (6 Jul 2026, embeds dnsmasq 2.93) or **AdGuard Home 0.107.78** (13 Jul 2026) | — | Home filtering as the sole corporate resolver or without redundancy |
| Zone as code | **dnscontrol 4.45.0** (1 Aug 2026) for multi-provider with `preview`/`push`; **octoDNS 1.21.1** (1 Aug 2026) if you prefer declarative YAML and Python | Terraform with the DNS provider's provider when the zone already lives in IaC of the same cloud | Editing zones in the registrar's or provider's web console |
| Public authoritative DNS | **Two independent operators** (e.g. self-hosted + managed), each one anycast | A single provider **only** with an SLA, multi-region anycast and a written exit plan | All NS in the same AS, the same datacenter or the same provider |
| Stub-to-resolver transport | **DoT (853)** towards the corporate resolver, or `53` on a trusted network with egress blocked | **DoQ (RFC 9250, May 2022)** where the software supports it and the operator controls it | Application DoH towards a third party, with no policy |
| Diagnosis | `kdig`, `dig +trace`, `delv`, `dnsviz`, `zonemaster` | `drill` | `nslookup` as a diagnostic tool (it hides the detail you need) |

**Choice criteria, not taste**: authoritative → Knot/NSD if you want minimal and fast, BIND if
you want the ecosystem, PowerDNS if the data lives in SQL. Recursive → Unbound/Knot Resolver.
Any candidate is discarded if it has no **security release in the last 12 months** or its
branch is EOL: that is the filter that precedes any technical discussion.

## 3. Structure and conventions

### 3.1 Architecture

- **Authoritative and recursive NEVER on the same server nor in the same process.** They are two
  services with two opposite threat models: the authoritative one is public and must not cache
  anything from third parties; the recursive one is internal, caches everything and must not answer
  anyone from outside. Mixing them enables cache poisoning with "authoritative" data and turns a
  failure of one into an outage of the other. If the software offers both roles, they are deployed separately anyway.
- **Minimum authoritatives: two, and with real diversity** — different software or at least a different
  process and version, different network/AS, different location, ideally a different provider.
  Two NS on the same hypervisor are one NS with two names. Rule of thumb: 2 providers × anycast.
- **Anycast for public authoritatives**: the same IP announced from several locations, with a
  health check that **withdraws the BGP announcement** when the daemon stops answering (the BGP design,
  in `networking-standards`). Without automatic withdrawal, anycast aggravates the failure instead of mitigating it.
- **Recursives**: at least two per site, in different failure domains, with the same policy and
  the same RPZ/filtering content. A single resolver is a SPOF that takes down the whole site.
- **Hidden model (`hidden primary`)**: the primary that signs is not published in the NS RRset;
  only the secondaries are. It reduces surface and separates "who edits" from "who answers".
- **Split-horizon with judgement**: only when the same name must resolve to something different inside
  and outside, and assuming its cost (two truths that diverge). Prefer **different names** or
  a delegated internal subdomain. If you use views, the internal view is an explicit and
  documented superset, and both are generated from the **same** SoT.

### 3.2 Zone: TTL, SOA, delegation

- **TTL with judgement, not a copied number**: stable records (NS, MX, SPF/DKIM/DMARC)
  hours; production service records 300-3600 s; failover and health-based records,
  30-60 s assuming the cost in queries. A high TTL is resilience against the authoritative going down;
  a low one is agility. Choose knowingly.
- **Lower the TTL BEFORE migrating** — the classic and most expensive mistake. Sequence: lower the TTL to 60 s
  → **wait at least the full previous TTL** (if it was at 86400, you wait a day) → migrate →
  verify from several public resolvers and regions → restore the TTL. Lowering it the same day
  as the cutover is worthless: resolvers keep serving the old value.
- **SOA**: `refresh` and `retry` are irrelevant if you use **NOTIFY + IXFR** (which is what you should
  use); what really matters is **`expire`** (how long a secondary serves without being able to talk
  to the primary — do not set it short: it is your cushion against a partition) and **`minimum`**, which
  today means **negative NXDOMAIN TTL** (RFC 2308), not a default TTL. Serial:
  `YYYYMMDDnn` or an incremental integer generated by the tool, **never by hand**.
- **Delegation and glue**: the child's `NS` must match the parent's exactly; the
  **glue** (A/AAAA record in the parent) is mandatory and only mandatory when the NS is
  *inside* the delegated zone. Stale glue after changing an NS's IP is one of the hardest
  faults to see from inside: it is diagnosed **from outside**, with `dig +trace` and a direct query
  to the TLD's servers.
- **Consistency between parent and child**: NS RRset, `DS` and glue are verified as a gate (§4).
  Any divergence is a finding, not a curiosity.
- **`CNAME` at the apex is forbidden by the protocol** (the apex has SOA and NS, and CNAME cannot
  coexist). Alternatives, in order: (1) the provider's `ALIAS`/`ANAME` —resolution on the
  server side, not an IETF standard, behaviour and geolocation depend on the provider;
  (2) an **`HTTPS`** record at the apex with `AliasMode` (RFC 9460) —the right thing going forward, but
  a client that does not support it still needs A/AAAA; (3) fixed A/AAAA updated by
  automation. Never "point the apex at a CNAME and hope the resolver forgives it".
- **Modern records that do get pinned**:
  - **`CAA` (RFC 8659) mandatory in every zone**: restricts which CA can issue for the domain,
    with `issue`, `issuewild` (set it to `;` if you do not use wildcards) and `iodef` for notification.
    It is cheap, it is checked at issuance time and it stops mis-issuance.
  - **`HTTPS`/`SVCB` (RFC 9460, Nov 2023)**: queried by default by Firefox, Safari and Chrome;
    they enable HTTP/3 without the *upgrade dance*, upgrade to https and **ECH**. Publish at least
    `alpn="h3,h2"` on web services. RFC 9461 (DoH mapping, `dohpath`) and RFC 9462 (DDR)
    depend on them to discover encrypted resolvers. Old clients ignore them: there is
    no compatibility risk, but there is the risk of forgetting to keep them consistent with A/AAAA.
  - **`SSHFP`**: useful only if the client validates and the zone is signed; without DNSSEC it adds no
    security, only convenience.
  - **`TLSA`/DANE**: **honesty** — real adoption is residual. In a scan of 5.5M
    domains (Feb 2026) around **30** published TLSA versus ~16,000 with MTA-STS. M365 validates
    both; Google Workspace and Yahoo support MTA-STS and **not** DANE. Postfix and Exim ship DANE
    natively (MTA-STS requires an add-on such as `postfix-tlspol`). **Criteria**: publish TLSA only
    if your zone is signed, you have certificate rotation and TLSA **coupled and tested**, and your
    ecosystem (`.nl`/`.de` mail, internet.nl requirements, European public sector) demands it.
    Outside that, **MTA-STS first**; badly operated DANE is a guaranteed mail outage.
- **PTR**: maintain the reverse for anything that sends mail or takes part in mutual TLS; FCrDNS (consistent
  A→PTR→A) is a practical deliverability requirement. IPv6 reverse delegation (`ip6.arpa`) by
  automation or it will not exist.
- **Wildcards (`*`)**: forbidden except in a justified and bounded case. They hide typos,
  break NXDOMAIN as a signal and turn any made-up subdomain into valid surface.

### 3.3 Mail: authentication in DNS

- **SPF**: a single TXT record per domain, ending in **`-all`** (fail) once validated with
  real data; `~all` only as a temporary phase with a written exit date. **Hard limit of 10
  DNS lookups** (`include`, `a`, `mx`, `ptr`, `exists`, `redirect`): exceeding it produces
  `PermError` and **SPF stops being worth anything**, silently. It is measured in CI, not estimated.
  `ptr` is deprecated: it is not used. Domains that do not send mail: `v=spf1 -all` + `MX .` + DMARC
  `p=reject` ("parked" domains are the most forgotten spoofing vector).
- **DKIM**: **RSA-2048 or Ed25519** keys (the algorithms and their custody, in
  `cryptography-pki-standards`), one selector per sending system, scheduled rotation with
  overlap (publish new selector → migrate signers → retire the old one). Selectors of
  providers you no longer use: they get deleted.
- **DMARC**: the goal is **`p=reject`**. `p=none` is an **observation phase with an end
  date**, not a permanent state; a `p=none` older than a quarter is a decision not to
  protect the domain, taken by omission. Route: `p=none` + `rua` → analyse reports → align
  senders → `p=quarantine` with increasing `pct` → `p=reject`, including subdomains (`sp=`).
  Updated normative basis: **DMARCbis — RFC 9989** (Standards Track, May 2026, obsoletes
  RFC 7489 and 9091) and **RFC 9990** (aggregate reports).
- **Current requirements of the big providers** (verified Aug 2026): Google and Yahoo require
  aligned SPF+DKIM+DMARC from senders of **≥5,000 messages/day** since Feb 2024, and Gmail moved from
  `421` deferral to **permanent `550` rejection in Nov 2025**; **Microsoft** has applied since
  **5 May 2025** direct rejection (`550 5.7.515`) for outlook.com/hotmail.com/live.com, with no warning
  phase; La Poste joined in Sep 2025. All of them additionally require one-click unsubscribe
  (`List-Unsubscribe` + `List-Unsubscribe-Post`, RFC 8058) and a complaint rate below 0.3%
  (operate below 0.1%). The declared trend is to harden towards strict policies:
  **assume `p=none` will stop being sufficient and get ahead of it**.
- **MTA-STS (RFC 8461) and TLS-RPT (RFC 8460)**: publish both. MTA-STS requires the TXT at
  `_mta-sts.<domain>` **and** the policy served over HTTPS at `mta-sts.<domain>/.well-known/`
  with a valid certificate — two systems that must expire together and do not do so on their own: it is the
  usual cause of ~30% of measured deployments being misconfigured. Start at
  `mode: testing`, move to `enforce` when TLS-RPT is clean. The policy `id` changes with
  every modification or senders will serve the cached one.

### 3.4 Internal namespace

- **Use a subdomain of a domain you own** (`corp.example.com`, `internal.example.com`):
  it is the only option that allows DNSSEC, public certificates and coexistence with split-horizon
  without collisions.
- Reserved and legitimate alternatives: **`.internal`** (reserved by ICANN on 29 Jul 2024 for
  private use, it will never be delegated in the root) and **`home.arpa`** (RFC 8375, home network).
  Both are **insecure by definition**: there is no possible DNSSEC chain nor public certificate.
- **FORBIDDEN to invent TLDs** (`.local` —which is also mDNS, RFC 6762—, `.lan`, `.corp`, `.home`,
  `.dev` as internal, `.intranet`): collision with real delegations, leakage of queries to the root,
  and when the TLD ends up genuinely delegated, a third party receives your internal traffic with your
  credentials inside. The `.dev` case already happened.
- **DHCP/directory integration**: dynamic DNS update from the DHCP server (Kea) with
  **TSIG** and scope bounded to the dynamic zone, never with a global shared key. In environments
  with Active Directory, DNS integrated in the directory with **secure updates only**
  (the AD detail, in `windows-server-ad-standards`), and explicit delegation between the AD zone
  and the corporate zone: two authorities over the same name is an incident waiting for a date.
- **Minimal search (`search`)**: long lists multiply queries and create accidental
  resolutions. Qualified names (FQDN) in service configuration, always.

### 3.5 Zone as code

- The **SoT is the repo**, not the provider's panel. `dnscontrol` or `octoDNS` generate and push;
  human access to the panel is left for emergencies, with MFA and auditing.
- The pipeline: PR → syntax and policy validation → `preview`/`plan` with an **explicit diff**
  → mandatory human review for NS, DS, MX and mail authentication records → `push`.
- Periodic **drift detection**: diff between what is published and the repo. A difference is a
  finding with an owner (or a manual change someone made under pressure and did not document).
- DNS provider API credentials: in a secrets manager, with permissions limited to the zones
  required (`secrets-management-standards`). That token allows issuing certificates via DNS-01
  for **all** of your domain: treat it as an identity key, not as config.

## 4. Mandatory quality gates

In order of increasing cost. The first four break the build.

1. **Syntax and load**: `named-checkconf` + `named-checkzone` (or `knotc zone-check`,
   `unbound-checkconf`, `pdnsutil check-all-zones`, `kresctl validate`) over every zone and every
   config. A zone that does not load is a total outage, not a warning.
2. **Zone policy in CI**:
   - SPF: **count the DNS lookups** and fail above 10; a single `v=spf1` record.
   - DMARC present; **fail if `p=none` exceeds the deadline** recorded in the repo.
   - `CAA` present at the apex and consistent with the CA that actually issues.
   - No `CNAME` at the apex; no `CNAME` coexisting with other types.
   - TTL within ranges agreed by record class.
   - Serial increasing with respect to the published one.
3. **Parent-child coherence and delegation**: parent NS == child NS, correct glue, `DS`
   matching the published DNSKEY. `dig +trace`, `dnsviz` or `zonemaster` in the pipeline.
4. **Negative test**: verify that the **internal recursive does not answer from outside**, that the
   **authoritative does not recurse** (`RD` ignored, no answer for foreign names), and that
   `AXFR` is denied to anyone without TSIG. A DNS tested only along the happy path is not
   tested.
5. **Continuous resolution from outside**: probes from several regions and several public resolvers
   —not just from your network, where the cache lies to you— checking correct answer, coherence
   between all NS, and latency. Add end-to-end **DNSSEC validation** verification.
6. **Expiry watch, with early alerting and an owner**:
   - **RRSIG signatures** (alert at 50% of remaining life; an expired signature is a total
     and self-inflicted outage, and the validating recursive leaves you off the Internet).
   - **Domain registration** (multi-year + auto-renewal **and** an alert independent of the
     registrar: if the alert is sent by the one who is going to cut you off, it is not an alert).
   - Certificate of the **MTA-STS** policy and of the DoH/DoT endpoint.
   - DKIM selectors and rotation window.
7. **Rollover and restore rehearsal**: the first KSK rotation is not done in production
   without having done it in an identical environment. Restore the zone from the repo on a clean server at
   least once every six months.
8. **Failover test**: shut down an authoritative and a recursive (in a window) and check that
   nobody notices. A secondary that is never exercised does not count as redundancy.

## 5. Security

### 5.1 DNSSEC

- **Always validate on the recursive** (zero operational cost, immediate benefit). Global
  validation is around **35-36%** of users (APNIC) and ~49% in the EU: you are on the right side of that
  statistic, not on the marginal one. Normative reference: **RFC 9364 (BCP 237)**.
- **Signing your own zone: when it pays off.** Yes, if the name supports mail, certificates,
  federated identity or financial services, or if you need DANE/SSHFP with real value. No —or not
  yet— if you cannot automate signing and rotation, because the failure mode is
  **total outage of the name**, not degradation. Honest data: signed delegations are around
  **7%**, `.com` ~4.3% and `.net` ~5.3%; and although ~8% of queries go to signed domains,
  only ~0.5-0.6% are validated end to end (Cloudflare Radar, 2026, growing steadily).
  Signing is correct; believing that it protects you from an attacker already present in the client's resolver,
  not.
- **Automated or it does not get done**: inline signing and key management by the server itself
  (Knot `keymgr`/automatic DNSSEC, BIND `dnssec-policy`, PowerDNS `pdnsutil`). Automatic ZSK
  rotation; **KSK with CDS/CDNSKEY (RFC 7344/8078)** so that the parent updates itself where
  the registrar supports it. **Signing by hand with cron and `dnssec-signzone` is vetoed**: 100%
  of the DNSSEC outages you will see are expired signatures or a DS that was not updated.
- **NSEC3 only if you need to prevent enumeration**, and with the parameters of **RFC 9276 (BCP 236)**:
  **0 iterations and empty salt**. High iteration counts are cost for you and amplification for the
  attacker, not security. If zone enumeration is not a problem, **plain NSEC** is
  simpler and cheaper.
- **Monitor the full chain** (DS in the parent ↔ DNSKEY ↔ RRSIG ↔ expiry) from an
  external validator, not from your own server.
- Algorithms, lengths and key custody: `cryptography-pki-standards`.

### 5.2 Availability and abuse

- **Never an open resolver**: the recursive answers only to your own networks (`access-control` /
  `allow-query`). An open recursive is an amplifier for third parties and a poisoning channel
  for you.
- **Amplification on authoritatives**: **RRL (Response Rate Limiting)** enabled with `slip` so as
  not to punish legitimate clients, **minimal-any (RFC 8482)** so as not to answer a full ANY, and
  minimal responses. Complement with rate limiting in dnsdist and upstream anti-DDoS.
- **Cache poisoning**: current mitigations (random source port, 0x20, DNS cookies
  RFC 7873, DNSSEC, QNAME minimisation RFC 9156) **are enough but with no margin to spare**: variants
  keep appearing (e.g. promiscuous NS, CVE-2025-11411 in Unbound, cross-zone poisoning
  CVE-2026-13321 in BIND in Jul 2026). **Operational translation: patch fast**; the structural
  defence exists, but every quarter someone finds a crack in the implementation.
- **Recursive hygiene**: QNAME minimisation active, `harden-below-nxdomain`, NXDOMAIN cut
  (RFC 8020), rejection of out-of-bailiwick answers, and **do not** rewrite NXDOMAIN to an IP
  of your own (it breaks the signal, mail and detection).

### 5.3 The name as an asset: hijack and abandonment

- **Domain hijacking: the cheapest route to total compromise that exists.** With control of the
  registrar or the NS, an attacker issues valid certificates (DNS-01/HTTP-01), redirects
  mail, passes any password reset and impersonates the brand — without touching a single server
  of yours. **Non-negotiable** controls:
  - **Registrar lock / transfer lock** enabled and, in the TLDs that offer it, **registry lock**
    (lock at the registry, with out-of-band unlocking) for business domains.
  - **Phishing-resistant MFA** on the registrar and DNS provider account; named
    accounts, with no contact address in the very domain you manage (circular dependency).
  - **Multi-year auto-renewal** and an expiry alert independent of the registrar.
  - **Watch the NS RRset and the DS**: alert on any change not originating in the repo.
    An NS change that does not come from a PR is an incident until proven otherwise.
  - `CAA` with `iodef` and **Certificate Transparency monitoring** to detect unauthorised
    issuance for your names.
- **Dangling subdomains and takeover**: a `CNAME` or A/AAAA pointing at a released resource
  (bucket, PaaS, CDN, returned elastic IP) allows a third party to claim that destination and
  serve content under your name —with cookies, SSO and brand trust included.
  - **Indicator**: records that resolve to a destination returning a "resource not
    claimed" error, or whose IP no longer belongs to any of your ranges or accounts.
  - **Mitigation**: deleting the DNS record is part of the **same** operation as decommissioning
    the resource (`iac-standards`: destroy the resource and its record in the same `apply`);
    periodic cross-inventory between zone and active resources as a recurring gate; low TTL
    on short-lived records. Pay special attention to campaign subdomains and
    temporary environments, which nobody remembers to decommission.
- **Lifecycle**: every record has an owner and a reason in the repo. A record without an owner = a record
  to delete, with a grace period and prior traffic observation.

### 5.4 DNS as a channel and as a control

- **Log 100% of the resolver's queries** with client, name, type and answer.
  It is the security telemetry with the highest value/cost ratio that exists. You guarantee its
  **quality, coverage and retention**; the analytics and the rules belong to
  `detection-engineering-standards`.
- **Exfiltration and C2 over DNS**: a real risk class and a low-cost one for the attacker.
  **Indicators** (for the operator, not a procedure): anomalous query volume to a single
  second-level domain, long high-entropy labels, an unusual number of unique subdomains,
  predominance of TXT/NULL/CNAME, and a high NXDOMAIN rate per client.
  **Mitigation**: forced resolution through the corporate resolver, per-client rate limiting,
  blocking of newly registered domains and of risk categories (RPZ), and backup with EDR
  —because DoH inside HTTPS cannot be closed with network alone.
- **Zone transfers**: `AXFR`/`IXFR` **only with TSIG (RFC 8945, STD 93)** and an IP ACL,
  different keys per server pair and rotated. An open `AXFR` hands the complete map of your
  infrastructure to anyone. Verify it is denied as a negative test (§4).
- **Privacy and encrypted transport — what it implies for the operator**: DoT (853) is
  distinguishable and therefore **governable**; DoH (443) is indistinguishable from web traffic and
  **nullifies DNS filtering and visibility** if the application enables it. Criteria: offer **your
  own** DoT/DoH/DoQ (better privacy on the last hop without losing control), enforce browser policy
  (`DnsOverHttpsMode` in Chrome/Edge, `network.trr.mode` in Firefox) and coordinate with
  `firewall-policy-standards` the blocking of outbound `53`/`853` and of known public DoH
  resolvers. And assume what changes on the wire: with **ECH** (via `HTTPS` records) the SNI stops
  being visible — SNI-based inspection is a capability going extinct, not a strategy.
- Encrypting the transport does **not** anonymise you against the resolver's operator: it moves trust, it does not
  remove it. Choosing a public resolver "for privacy" is changing observer.

## 6. Performance and operability

- **Signals that are always watched**: QPS and its distribution by type, response latency
  (p50/p95/p99), SERVFAIL and NXDOMAIN rate, cache hit ratio, DNSSEC validation
  failures, queries rejected by ACL/RRL, transfer lag between primary and secondaries
  (divergent serial), and time to RRSIG and domain expiry. Thresholds and alerts, in
  `observability-standards`.
- **SERVFAIL is the most important and worst understood signal**: it can be a validation failure,
  a downed authoritative or a timeout. Distinguishing the three cases requires the recursive's log, not the client's.
- **Capacity**: size by real QPS percentile with margin for NXDOMAIN spikes (malware and
  broken applications generate them by the thousand). The cache is what sustains the service: watch its
  hit rate before the CPU.
- **Cost of a low TTL**: every reduction multiplies queries to your authoritatives. A 30 s TTL
  on a heavily queried record is a capacity decision, not just an agility one.
- **Runbooks with an owner**: expired DNSSEC signature, incorrect DS after rollover, secondary that does not
  transfer, downed resolver, domain close to expiring, suspected NS hijack, subdomain
  claimed by a third party, resolver under amplification. Each one with its check from outside.
- **Recovery**: the state you must be able to restore is the **zone repo + the DNSSEC
  keys** (custody and encrypted backup in `cryptography-pki-standards` and `bcdr-standards`).
  Losing the KSK without a backup forces an emergency rollover with a window of unavailability.

## 7. Sustainability and prohibitions

- **Cadence**: version and CVE review of the whole DNS stack **monthly** during 2026 (BIND,
  Unbound and dnsmasq are publishing security patches almost every month due to the flood of
  LLM-assisted findings); no EOL branch in production without a dated exit plan.
- **Half-yearly review of the zone content**: records without an owner, pointing at
  non-existent resources, orphan DKIM selectors, SPF `include` of providers you no longer use.
- **Real deprecation**: retiring a service includes deleting its DNS record, its DKIM selector, its
  SPF entry and its firewall rule on the same day.

**FORBIDDEN**
- ❌ Serving authoritative and recursive from the same server or process.
- ❌ A recursive resolver open to the Internet; an authoritative that recurses.
- ❌ A single authoritative server, or several without network/provider/location diversity.
- ❌ Migrating without having lowered the TTL at least a full TTL in advance.
- ❌ `CNAME` at the apex, or `CNAME` coexisting with other types.
- ❌ A signed zone with **manual** signing or rotation; DNSSEC without expiry monitoring.
- ❌ NSEC3 with iterations > 0 or with salt (against RFC 9276).
- ❌ `AXFR` without TSIG and without an ACL; a single TSIG key shared by the whole infrastructure.
- ❌ Invented TLDs (`.local`, `.lan`, `.corp`, `.home`) for internal names.
- ❌ SPF with more than 10 lookups, multiple `v=spf1` records, or the `ptr` mechanism.
- ❌ DMARC at `p=none` indefinitely; a domain without mail lacking `v=spf1 -all` + `p=reject` + `MX .`.
- ❌ A zone without `CAA`, or `CAA` that does not match the CA that actually issues.
- ❌ Publishing `TLSA`/DANE without a signed zone or without rotation coupled to the certificate.
- ❌ Editing zones in the provider's panel instead of the repo; ignoring detected drift.
- ❌ A domain without registrar lock, without MFA at the registrar or without an expiry alert
  independent of the registrar itself.
- ❌ The domain's administrative contact at an address in the very domain being managed.
- ❌ Deleting a resource without deleting its DNS record (dangling subdomain).
- ❌ Rewriting NXDOMAIN to an IP of your own ("search hijacking").
- ❌ Wildcards at the apex or in production zones without bounded justification.
- ❌ A resolver without query logging, or with retention below the investigation window.
- ❌ Allowing application DoH towards third parties without browser policy.
- ❌ `dnsmasq` < 2.93, BIND 9.18 or any EOL branch exposed.

## 8. Mandatory web verification

Before pinning any version, RFC, adoption figure or provider requirement,
**look it up — do not recall it**. Verified Aug 2026:

- **Software** (branch and latest published): BIND **9.20.26** (22 Jul 2026; 9.18 **EOL Jun 2026**;
  9.20 supported until ~Q1 2028; **9.22 delayed to at least Q4 2026**), Unbound **1.25.2**
  (22 Jul 2026), NSD **4.15.0** (7 Jul 2026), Knot DNS **3.5.6** (latest tag), Knot Resolver
  **6.4.x** (6.4.0, 17 Jun 2026), PowerDNS Recursor **5.4.4**, PowerDNS Authoritative branch
  **5.1.x**, dnsdist **2.0.7/2.1.0**, CoreDNS **1.14.6** (10 Jul 2026), dnsmasq **2.93**,
  Pi-hole FTL **6.7** (6 Jul 2026), AdGuard Home **0.107.78** (13 Jul 2026),
  dnscontrol **4.45.0** and octoDNS **1.21.1** (both 1 Aug 2026). All actively maintained.
- **CVE**: CVE-2026-13321 (BIND, cross-zone poisoning, CVSS 8.6, fixed in 9.20.26 on
  22 Jul 2026, along with 8 others); CVE-2025-11411 (Unbound, promiscuous NS, 1.24.1/1.24.2);
  coordinated batch of 6 CVEs in dnsmasq (11 May 2026) with CVE-2026-2291 fixed in 2.93/2.92rel2.
  **Re-verify the current month**: the 2026 cadence is monthly.
- **Mail**: Google/Yahoo since Feb 2024 (≥5,000/day); Gmail from `421` to `550` rejection in
  Nov 2025; Microsoft since 5 May 2025 with `550 5.7.515` with no warning phase; La Poste Sep 2025.
  DMARCbis published in **RFC 9989** (Standards Track, May 2026, obsoletes 7489 and 9091) and
  **RFC 9990** (aggregate reports).
- **Adoption**: DNSSEC — validation ~35-36% globally / ~49% EU (APNIC, 2025-2026), signed
  delegations ~7%, `.com` ~4.3% and `.net` ~5.3%; end-to-end validation ~0.47% (Q1 2026) →
  ~0.596% (May 2026) over ~8% of queries to signed domains (Cloudflare Radar). DANE — ~30
  domains with TLSA versus ~16,000 with MTA-STS out of 5.5M scanned (Feb 2026); MTA-STS below
  1% of the top 1M and ~30% misconfigured (IMC'25).
- **Verified RFCs**: 9460 (SVCB/HTTPS, Nov 2023), 9461/9462 (DoH mapping and DDR), 8659 (CAA,
  obsoletes 6844), 8461 (MTA-STS), 8460 (TLS-RPT), 8945 (TSIG, **STD 93**), 8482 (minimal ANY),
  9250 (DoQ, May 2022), 9276 (NSEC3, **BCP 236**), 9364 (DNSSEC, **BCP 237**), 8375 (`home.arpa`).

**Declared gaps — DO NOT fill from memory, verify before using**:
1. **PowerDNS Authoritative**: the blog dates found for 5.1.0 (3 Jun 2026) and 5.1.3
   (30 May 2026) are **mutually inconsistent**; the exact current point release of the 5.1.x branch and the
   support status of 5.0.x/4.9.x are **not confirmed**. Verify at
   `doc.powerdns.com/authoritative/changelog/` before pinning a version.
2. **RFC 9991** (DMARCbis failure reports): cited by secondary sources, **not verified**
   against rfc-editor. Check the number and status before referencing it.
3. **`.internal`**: reserved by ICANN (29 Jul 2024), but **no published IETF RFC is on record**;
   only an Internet-Draft. Verify in the datatracker if you need a normative basis.
4. **Exact release dates of Knot DNS 3.5.6 and of the Knot LTS branch**: obtained from
   repository tags, with no confirmed date nor verified support policy.
5. **RFC 2308 (negative TTL), 7873 (DNS cookies), 9156 (QNAME minimisation), 7344/8078 (CDS/CDNSKEY),
   8058 (one-click unsubscribe), 6762 (mDNS/`.local`), 8020 (NXDOMAIN cut)**: numbers cited from
   memory and **not verified** in this pass. Cross-check before citing them as authority.
6. **Apple's requirements** as a mail provider: alignment with Google/Microsoft is anticipated
   but **there is no confirmed formal policy**. Do not state it as a requirement.
7. **Maintenance status of `zonemaster` and `dnsviz`**: not verified.

If the web contradicts this document, **the web wins** — flag the discrepancy.
