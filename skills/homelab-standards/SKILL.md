---
name: homelab-standards
description: Homelab and self-hosting standards for a personal lab. Use for docker-compose.yml stacks, Podman Quadlet .container units, single-node k3s or Talos, restic/Kopia/borgmatic backups, btrfs snapshots, Proxmox lab hosts, home.arpa/.internal naming, NUT/UPS, lab power budget, or self-host-versus-SaaS decisions.
---

# Homelab and self-hosting standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when designing, building, operating or reviewing a **personal lab**:
- The **self-host vs. SaaS** decision and what is worth maintaining.
- Stack organisation (Docker Compose / Podman Quadlet), naming and the lab repo.
- Reverse proxy with TLS and **SSO in front of every app**; internal DNS and the lab's PKI.
- **Remote access without opening ports** (Tailscale/Headscale, WireGuard, tunnel, bastion).
- Single-node Kubernetes (k3s, Talos, MicroK8s) **vs.** Compose: when the complexity pays off.
- Backup on a tight budget and **tested restore**; btrfs/ZFS snapshots and their limit.
- UPS, power draw, noise, hardware selection and the economics of used *enterprise* kit.
- Update strategy, *blast radius*, proportionate monitoring and documentation
  written for the you of six months from now.
- **Proportionality criteria** (§6): which *enterprise* practice does apply at home and which is
  over-engineering. This is the skill's central contribution.

**Not applicable**: see onprem-standards (for **production/business with datacenter rigour**: HA with
fencing, DR with committed RTO/RPO, audited CIS hardening, a managed fleet), and with it
kubernetes-standards, iac-standards, networking-standards (network design and routing),
identity-access-management-standards (OIDC/SAML/RBAC design), cryptography-pki-standards (ACME,
step-ca, algorithm choice), observability-standards (OTel, PromQL, alerting) and
vulnerability-management-standards (CVE triage). Also `ctf-lab-standards` (the **security**
lab: disposable, isolated VMs for detonating challenge binaries or samples, training
platforms and their ToS — the boundary is purpose and isolation, not hardware: if the
lab shares a network or credentials with the homelab's services, it is badly designed) and
`offensive-security-standards` (authorised exercises against third-party systems: nothing you
practise at home is applied outside without written authorisation), `developer-workstation-standards`
(**the machine you work with is not the lab**. The workstation is provisioned
as code, hardened and rebuilt; the lab exists to be broken. **Using
the workstation as the lab's server is forbidden**: it mixes the two threat models and means
a broken experiment leaves you without your working tool), `home-automation-standards`
(**the device, the protocol and the home's automation are theirs** —Zigbee/Z-Wave/
Matter, Home Assistant and its automations, IoT VLAN, cameras and domestic privacy—;
**here the server and the lab** underneath).

**Boundary in both directions, explicitly:**
- If the system has **users outside your household, third-party data, an SLA, a regulatory
  obligation or somebody being paid for its availability** → it is production: use **onprem-standards**
  and the technical skills, even if the hardware is in your living room.
- If it is your personal lab, with no third parties and no SLA → **this skill wins**: applying full
  datacenter rigour to four services is the over-engineering this skill exists to stop.
- Grey area (Home Assistant, DNS, family Immich): **they have no SLA but they do have real users**.
  Treat them as the lab's top tier: verified backup, minimal dependency and a failure plan — not
  as production with HA.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Area | Default | Justifiable alternative / Forbidden |
|---|---|---|
| Container runtime | **Rootless Podman + Quadlet** (`.container`/`.pod`/`.network` in `/etc/containers/systemd/`, ≥ Podman 4.4) on Fedora/RHEL hosts: real systemd units, journald, `AutoUpdate=registry` with `podman-auto-update.timer` | `podman generate systemd` (deprecated); `podman-compose` as the base of a stable stack |
| Multi-service stacks | **Docker Compose v2** when the upstream project publishes it and there are dependencies between services: one file, versioned, diffable | Hand-translating to Quadlet an upstream compose that changes every release |
| Orchestrator | **Compose/Quadlet on one host.** k3s (the **1.36** line, May 2026) or **Talos** (1.13.x) **only if operating Kubernetes is the lab's goal**, not the means | Kubernetes for four services "because it is what everyone does": it multiplies pieces, upgrades and failure modes without giving anything back |
| Reverse proxy | **Traefik v3.7.x** with the Docker/Podman provider (automatic discovery) or **Caddy 2.11.x** if you prefer minimal config-as-code | **Nginx Proxy Manager**: config in SQLite (neither versionable nor diffable) and CVE-2026-40519 (authenticated command injection) affecting 2.9.14-2.15.1 — verify the fixed release before even considering it |
| Lab TLS | **ACME DNS-01 with a wildcard** (`*.lab.yourdomain.tld`) over a domain of your own: valid public certificates **without exposing anything to the Internet** | Your own internal PKI (Vault PKI, step-ca, FreeIPA's Dogtag) only if you need to issue to machines/services outside ACME: it means distributing the CA to every device |
| Internal naming | A subdomain of **your own domain** (`lab.yourdomain.tld`) with **split-horizon**; without your own domain, `home.arpa` (RFC 8375) or `.internal` (reserved by ICANN, Jul 2024) | ❌ `.local` (collides with mDNS) and ❌ `.lan`, `.home`, made-up ones: they break resolution and admit neither a public cert nor DNSSEC |
| SSO | **Authelia 4.39.x** (lightweight, *forward-auth* + OIDC) in front of the proxy by default; **Authentik 2026.5.x** if you need SAML/SCIM/LDAP or *outposts*; **Pocket ID** if you only want OIDC with passkeys | Duplicating the directory: if **FreeIPA** is already there, it is the LDAP/Kerberos backend and the IdP leans on it. ❌ Exposing an app with no authn of its own hoping "nobody will find it" |
| Remote access | **Tailscale** (Personal plan since Apr 2026: 6 users, unlimited user devices, ~50 *tagged resources*) or **Headscale** if you want your own control plane; plain **WireGuard** if you prefer zero dependencies | **Cloudflare Tunnel** only for what genuinely has to be public. ❌ Port-forwarding SSH, RDP, management panels or any app: the lab **does not open inbound ports** |
| Backup | **restic 0.19.x** or **Kopia 0.23.x** (both with an active stable line), client-side encryption and dedup; **borgmatic/Borg 1.4.x** if you already use it | ❌ **Borg 2.0**: still in beta (2.0.0b22, Jul 2026) and it breaks repository compatibility — not on data that matters |
| Offsite destination | **Cheap 3-2-1**: Hetzner Storage Box (free egress, SSH/rsync/restic) or **Backblaze B2** (~$6/TB-month) / rsync.net; a second local copy on a rotated external disk | ❌ A single copy, or offsite in the same house. Watch the **cost of egress and of operations** before choosing (R2 penalises small writes) |
| Snapshots | **btrfs (snapper/btrbk) or ZFS** for instant rollback and a short window | ❌ A snapshot ≠ a backup: it lives in the same pool and dies with it (deletion, ransomware, controller) |
| Hypervisor | **Proxmox VE 9.x** (turnkey: UI, backup, cluster, firewall) | **Incus** if you prefer a daemon on top of your distro; free ESXi came back but with limits and no future |
| Monitoring | **Proportionate**: Uptime Kuma (availability + notifications) + Beszel (agent ~10-15 MB, per-host resources) covers a small lab | Prometheus + Grafana (+ Alloy, the replacement for the deprecated Grafana Agent) **only** if you want PromQL, log correlation or you already operate >5-10 hosts. Netdata: 200-500 MB RAM per host, charge it the price |
| Secrets | **Vault** (if you already have it, with a written *unseal* procedure and keys outside the lab) or **sops+age** in the repo | ❌ Secrets in `docker-compose.yml`, in an unencrypted `.env` or in the git history |
| MFA | **FIDO2/WebAuthn (YubiKey)** on the IdP and on SSH (`ed25519-sk`); **two keys** always registered | ❌ A single key with no backup: losing it means losing the lab |

## 3. Structure and conventions

**One repo, all the truth.** No configuration that exists only on the host: if the
disk is wiped, the lab is rebuilt from the repo plus the data backup.

```
homelab/
├─ hosts/<hostname>/            # what is specific to each machine
├─ stacks/<service>/            # compose.yaml + .env.sops + README.md
├─ quadlet/                     # *.container, *.network, *.volume
├─ ansible/                     # host bootstrap and config
├─ backup/                      # restic/kopia policies + restore-test jobs
├─ docs/
│  ├─ services.md               # what it is, why it exists, who uses it, how it is restored
│  ├─ network.md                # VLANs, IPAM, DNS, diagram
│  └─ decisions.md              # 3 lines per decision: what, why, what I discarded
└─ .sops.yaml
```

**New service checklist** (if one fails, it does not enter the lab):
① what data does it generate and **is it in the backup**? · ② is it behind SSO or does it have decent authn of its own? ·
③ valid TLS? · ④ which VLAN and with what egress to the Internet? · ⑤ image **pinned by digest**? ·
⑥ two lines in `docs/services.md` with how it is restored? · ⑦ what does it depend on to start?

**Naming**: `<service>.lab.<domain>` for access, hostname by role+index for machines,
one VLAN per trust zone. IPAM in `docs/network.md`; **no network data from memory**.

## 4. Proportionate quality gates

Four of them, automated, without an enterprise CI:
1. **Pre-commit**: `yamllint`, `shellcheck`, a secret scanner (which one, in
   `secrets-management-standards`) and a check that nothing unencrypted enters
   the repo. Cheap and it prevents 90% of the silly disasters.
2. **Monthly restore test, automated — THE lab gate**: restore a specific file *and* a
   complete service on a disposable VM, verify that it starts and notify the result
   (ntfy/Healthchecks). Complemented with periodic `restic check --read-data-subset` (it verifies the
   repository, not that your data is recoverable: they are different tests).
3. **Cold start**, once a year: shut everything down and power it up. It is the only way to discover
   **circular dependencies** (the DNS that lives in the cluster that needs DNS, the IdP that needs
   the database that needs the storage that needs DNS) and the sealed Vault.
4. **Updating with a way back**: a btrfs/Proxmox snapshot **first**, one change per window, and
   a check that the service really responds (not that systemd says `active`).

## 5. Security

- **Zero inbound ports**. Ingress is via an overlay (Tailscale/WireGuard) or an outbound tunnel. If
  something must be public: an isolated VLAN, no credentials shared with the rest, no lateral access
  and assuming it will fall.
- **SSO in front of everything** that does not have serious authentication of its own; FIDO2 MFA on the IdP; SSH with
  `ed25519`/`ed25519-sk` keys, no password and no remote root.
- **Realistic minimum segmentation**: management (Proxmox/IPMI/switch) · services · **IoT** · guests.
  IoT does not talk to management and reaches the Internet only where necessary. Cheap gadgets are the
  most likely way into a domestic lab.
- **Containers**: rootless where possible, never `--privileged` out of habit, and ❌ **never mount
  the daemon socket** (`/var/run/docker.sock`) into an app — it is root on the host, gift-wrapped.
- **Automatic OS security updates**; images pinned by digest and updated
  deliberately (Renovate tells you what changes before you change it).
- **Backups encrypted with the key kept outside the lab** (password manager, paper somewhere
  else): an encrypted backup with no recoverable key = total loss. At least one **immutable or
  offline** copy; domestic ransomware deletes whatever is mounted first.
- **A separate management plane**: IPMI/iDRAC and the hypervisor UI only over VPN, with unique
  credentials and up-to-date firmware. It is the first thing forgotten in a lab and the worst thing to lose.

## 6. Proportionality — the central criteria

| *Enterprise* practice | In a homelab? | Why |
|---|---|---|
| 3-2-1 backup with a **tested restore** | **YES, non-negotiable** | It is the only practice whose failure is irreversible. Everything else can be redone |
| TLS everywhere + automated ACME | **YES** | It costs an afternoon and permanently eliminates warnings, MITM on the wifi and browser exceptions |
| Not exposing ports / access via overlay | **YES** | The cost is zero and it avoids 100% of the Internet's mass scanning |
| Config versioned in git + encrypted secrets | **YES** | It is what turns "my disk died" into an afternoon rather than a month |
| VLAN segmentation (at least IoT) | **YES** | Cheap on any decent switch; IoT is the real weak link |
| Basic monitoring with an alert to your phone | **YES, but only actionable** | Disk full, failed backup, failed restore test, SMART, certificate about to expire. Nothing else |
| Documenting decisions (3 lines) | **YES** | The you of six months from now is literally another person with no context |
| An inventory of what runs and why | **YES** | Without it, the lab accumulates zombie services nobody uses and everybody patches |
| **3-node HA, quorum, Ceph** | **NO** (unless learning HA *is* the goal) | It triples cost, power, noise and complexity for an SLA that does not exist. One node with a tested backup is restored faster than a poorly understood cluster is repaired |
| **GitOps (Argo/Flux) for 4 services** | **NO** | The repo + `podman auto-update`/Compose already gives you versioning and reproducibility. Argo adds one more critical component to maintain |
| Service mesh, east-west mTLS | **NO** | It solves a problem (trust in a shared multi-tenant network) your lab does not have |
| A full SIEM, correlation, long retention | **NO** | Centralised logs with short retention and decent search cover the real case: understanding what happened last night |
| SLOs with an *error budget*, formal postmortems | **NO** | The real SLI is "did anyone at home complain?". One line in `docs/decisions.md` closes the incident |
| A permanent staging environment | **NO** | A disposable VM + a prior snapshot covers the same thing with no fixed cost |

**Power and noise — the cost forgotten at purchase time.**
`annual_cost ≈ average_W × 8.76 × €/kWh`. With the Spanish domestic price as of Aug 2026 (≈0.10-0.20
€/kWh depending on tariff and time band; **verify**), every permanent watt costs on the order of 1-2 €/year.
An N100/N150 mini-PC at idle sits around 5-10 W (≈8-20 €/year); a second-hand *enterprise* server
(R730, DL380 Gen9) starts at 100-200 W idle: **hundreds of euros a year**, plus airport-grade noise and
a rack that does not fit. The rule: **add three years of electricity to the purchase price** before
deciding. Used iron wins when you need cheap ECC RAM, many disks or PCIe lanes; it loses
at almost everything else.

**UPS**: size it for an **orderly shutdown**, not for riding out the outage. NUT (or apcupsd)
configured, integrated with Proxmox/hosts, and the shutdown **tested by pulling the cable** — a UPS that
shuts nothing down is an expensive paperweight.

**Document the lab you will forget**: every stack with a four-line README (what it is, why
it is there, how it is restored, what breaks if I turn it off), a network diagram updated whenever
the network changes, and `docs/decisions.md` with the **why** — the what is read from the code, the why is not.

## 7. Sustainability and prohibitions

**Cadence and *blast radius***
- OS security: automatic. Apps: monthly, in a window you choose (not when the house is
  watching Jellyfin). *Majors*: reading the release notes, one per session.
- **Law of the lab: one change, one night.** Never touch DNS, IdP, proxy or storage on the same day
  along with something else: they are the four dependencies of everything else and debugging two changes at once
  costs three times as much.
- Snapshot first, a rollback plan written **before** starting. Traefik only supports the
  latest minor: budget for frequent upgrades or choose Caddy.
- Half-yearly pruning: a service nobody has used in six months gets turned off (and deleted a month later, if
  nobody claims it). A lab grows by accumulation until it stops being maintainable.

**FORBIDDEN**
- ❌ Opening inbound ports on the router towards panels, SSH, RDP or apps "just for a moment".
- ❌ `latest` on any image that stores data; updating without knowing which version came before.
- ❌ Mounting the container daemon socket into an app; `--privileged` by default.
- ❌ Secrets in compose, in a cleartext `.env` or in the git history.
- ❌ Calling a snapshot, a RAID or a sync a backup (Syncthing propagates the deletion).
- ❌ A backup without a **tested restore**, or with the encryption key kept only inside the lab.
- ❌ Circular dependencies at startup (DNS/IdP/secrets inside what they need in order to live).
- ❌ Making the lab a SPOF for services the family uses with no failure plan and no warning (the house's
  DNS and Home Assistant are the repeat offenders).
- ❌ Buying hardware without calculating power draw, noise and where it physically goes.
- ❌ `.local`/`.lan`/made-up TLDs for internal DNS.
- ❌ "I will document it later" and "I will fix it later" without a dated note in the repo.
- ❌ Copying an enterprise architecture (HA, mesh, GitOps, SIEM) without being able to explain **what
  concrete failure of your lab** it prevents.

## 8. Mandatory web verification

Before pinning any version or datum, **look it up — do not recall it**. This ecosystem moves
by the week:
- Latest stable of: **k3s / Talos** (and which Kubernetes they package), **Traefik / Caddy** (and which
  minors are still supported), **Authentik / Authelia**, **restic / Kopia / Borg** (is Borg 2.0 still
  in beta?), **Podman** (Quadlet), **Proxmox VE**, **NUT**, **Uptime Kuma / Beszel**.
- **Open CVEs** for the service you are going to expose or put in the critical path (proxy, IdP, panel)
  before deploying it — with special attention to NPM (CVE-2026-40519) and any management UI.
- **ACME/Let's Encrypt news**: profiles (`shortlived`, 160 h, GA Jan 2026), certificates
  for IP addresses, and the end of expiry notices by email (Jun 2025) — if you relied on those
  emails to find out, they no longer arrive: monitor expiry yourself.
- **Tailscale/Cloudflare/Headscale plans and limits**: they changed in Apr 2026 and will change again.
- **Offsite storage prices** (Hetzner, B2, rsync.net, R2) and their egress and operations
  policy before calculating the monthly cost.
- **The current kWh price** and consumption measured with a plug meter before justifying a hardware
  purchase on efficiency grounds.

If you cannot verify, say so explicitly instead of assuming.
If the web contradicts this document, **the web wins** — flag the discrepancy.
