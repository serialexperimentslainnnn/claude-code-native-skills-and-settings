---
name: air-gapped-standards
description: Operating systems with no Internet path — what a real air gap is, how software gets in and what breaks when nothing can phone home. Use when designing or auditing an isolated, disconnected or "offline" environment, a unidirectional gateway or data diode, a sneakernet transfer process with one-time media and chain of custody, an internal mirror of dnf/apt/pip/npm/crates/maven or a container registry (Pulp with pulp export / pulp import and its toc.json, Foreman/Katello, Harbor proxy cache and replication, Sonatype Nexus Repository Community Edition and its usage limits, JFrog Artifactory, reposync, createrepo_c, apt-mirror, devpi, verdaccio), moving images with skopeo copy --dir, docker save, oras pull or a local registry:2 for cephadm/Rook/Kubernetes bootstrap, verifying signatures on the isolated side (rpm --import, gpgcheck, apt Signed-By, cosign verify --key/--trusted-root/--insecure-ignore-tlog, cosign save and --local-image), running a vulnerability scanner without feed access (trivy self-hosted DB, --offline-scan, --skip-version-check, --disable-telemetry, grype db import), patching and CVE triage with no NVD access, GNSS/GPS stratum-1 time and chrony when NTP has no upstream (Kerberos clockskew, expired TLS certificates), an offline root CA with internal CRL distribution and nextUpdate expiry, software licences that require activation or a license server reachable over the Internet, backups and DR inside the isolated enclave, telemetry and observability that cannot leave, or deciding whether the air gap is the right control at all or expensive theatre that makes patching impossible.
---

# Isolated (air-gapped) environment standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: **an air gap is not a security control, it is a network restriction that shifts
> the risk.** What it removes — direct remote access — it swaps for two others that almost nobody
> budgets for: **a human, physical entry channel** (which is the documented vector) and **the
> structural inability to patch in time**. A badly operated isolated environment is less secure than
> a connected and well-patched one. The decision is not "isolate or not", it is **whether you can
> pay the operational cost of being isolated**.

## 1. Scope and triggers

Applies to the **design and operation of an environment with no Internet path**: which isolation
model is chosen and what it guarantees, how software gets in and how it is verified **inside**,
physical transfer and its governance, patching and vulnerability triage without feeds, time,
internal PKI, licences that phone home, backup and recovery inside the enclave, observability that
cannot leave, and the criterion for when isolation is the right answer.

Triggers: "air gap", "air-gapped", "isolated environment", "no Internet access", "separate
network", "offline", "sneakernet", "data diode", "unidirectional gateway", `pulp export`/`pulp
import`, `toc.json`, `reposync`, `createrepo_c`, `apt-mirror`, `debmirror`, `devpi`, `verdaccio`,
`skopeo copy --dir`, `docker save`/`load`, `oras pull`, local `registry:2`, `cosign save`,
`cosign verify --trusted-root`/`--insecure-ignore-tlog`/`--local-image`, `rpm --import`,
`gpgcheck=1`, `Signed-By`, `trivy --offline-scan`/`--skip-version-check`, `grype db import`,
`chronyc sources` with no upstream, GNSS/GPS stratum 1, `clockskew`, CRL `nextUpdate`, licence
server, "activation", "cannot phone home".

**Not applicable**: see `ot-ics-security-standards` (**the sibling boundary and the most likely
one**: **industrial** isolation — the Purdue model, the level 3.5 DMZ, IEC 62443-3-2 zones and
conduits, a diode between plant and corporate, EWS, PLC project files, 20-year-old assets that are
not patched for physical safety reasons — is **theirs**. Here, isolation **as a general operating
mode**, applicable also to an R&D enclave, a backup vault, an offline root CA, a malware lab or a
non-industrial regulated environment. Arbitration rule: **if on the other side of the diode there
is a physical process that can kill somebody, `ot-ics` rules; if on the other side there is data
and servers, this skill rules**. And the order of priorities changes with it: there *safety* above
everything; here confidentiality is usually what motivated the isolation),
`ctf-lab-standards` (a disposable security lab and sample detonation: **isolation there protects
the world from the lab; here it protects the enclave from the world** — they are two different
threat directions and two different designs), `firewall-policy-standards` (the rule as an artifact
and its life cycle; **here it is decided whether a path exists, there the rule is written**.
Corollary of §2.1: an environment with firewall rules **is not isolated**, it is segmented),
`networking-standards` and `routing-switching-standards` (VLANs, VRFs, addressing and switching of
the enclave), `vulnerability-management-standards` (**triage, CVSS/EPSS/KEV, VEX and remediation
SLAs are theirs**; here **why the calendar changes** and how the data arrives with no connection),
`backup-recovery-standards` (the mechanics of the copy and the tested restore; here the constraint
that the repository and its keys cannot be outside the enclave),
`bcdr-standards` (RTO/RPO and exercises: **a DR plan that assumes downloading something from the
Internet is not a plan in this environment**), `secrets-management-standards` (secrets manager,
rotation; here that it **cannot depend on a cloud KMS**), `cryptography-pki-standards` (algorithms,
custody and the **offline root CA as a practice** — the offline root is an air gap and that skill
owns it; here the PKI *of the enclave* and the availability of its CRLs),
`identity-access-management-standards` (IdP, MFA and federation: **federating with a cloud IdP is
exactly the data path that isolation denies**),
`opensource-licensing-standards` (licence obligations of the mirrored software; here only the
verified licence status of the tools in §2.3),
`cicd-standards` (the pipeline and its gates; here the pipeline **split in two** by the cut),
`iac-standards` (Terraform/Ansible and their providers and collections, which also have to be
mirrored), `kubernetes-standards` (registry, admission and verified signatures in the cluster),
`ceph-standards` (**sister**: `cephadm` explicitly documents deployment in an isolated environment
against a local container registry; the registry belongs here, the cluster is theirs),
`observability-standards` (telemetry stack; here that it **cannot export**),
`grc-compliance-standards` (regulatory framework, evidence and the eventual accreditation of the
enclave), `incident-response-forensics-standards` (response and forensics inside the enclave,
including the extraction of evidence through the same physical channel as everything else),
`detection-engineering-standards` (rules and their update with no feed).

## 2. Default decisions

> Verify on the web before fixing anything in a real project (§8). Licences and usage limits of the
> mirroring tools change, and they are the kind of datum most often written from memory.

### 2.1 What a real air gap is

**Operational, not commercial definition**: an environment is isolated if **no data path exists**
between it and an untrusted network. A data path is anything that moves bytes, whether or not it
has an IP address.

| What gets called an air gap | What it is | What to assume |
|---|---|---|
| A separate VLAN with a firewall and egress rules | **Segmented network** | There is a path. If there is a rule, there is a flow, and a badly placed rule opens it |
| Separate network + jump host / bastion | **Segmented network with a bottleneck** | There is a path, and the bottleneck is the target |
| Separate network + data diode (egress) | **Unidirectional isolation** | Nothing enters over the network **by physical design**; there is still a human entry path |
| Separate network, no link, transfer by media | **Air gap with sneakernet** | The USB **is** the path, and it is the documented vector |
| No link and no transfer of any kind | Total isolation | Very little of this exists: the software has to get in at some point |

**The three paths nobody draws on the diagram**: **removable media**, the **vendor's or
integrator's laptop** that gets plugged in to do a job, and the **firmware update** (BMC, BIOS,
storage array, switch) that arrives in an image downloaded by somebody. If your threat model does
not cover them, you have not modelled the air gap: you have drawn a VLAN.

### 2.2 Models and when to use them

| Model | Fits when | Real cost |
|---|---|---|
| **Totally isolated** | The enclave needs no fresh data and its content never leaves (backup vault, offline root CA, legal archive) | Low. It is the only case where the air gap comes cheap |
| **Unidirectional with a data diode** | You need to **get out** telemetry, logs or results without admitting anything back | High: specific hardware, protocols that tolerate having no ACK, and **zero return channel** — not even to confirm arrival |
| **Controlled sneakernet** | You need to **bring in** software and data regularly | The most expensive in people and the most dangerous. It is a process, not a cable |

**The diode does not solve entry.** A diode guarantees that nothing enters over that link; the
software still has to get in somewhere else, and that somewhere else is where the risk lives.
Designing the diode and leaving USB ungoverned is optimising the armoured door of a house with the
window open.

### 2.3 Internal mirroring: choice and verified licence

| Tool | Licence (verified raw) | Criterion |
|---|---|---|
| **Pulp 3** (`pulpcore`) | **GPLv2** — `LICENSE` file of `pulp/pulpcore@main` | **Default for RPM/DEB/PyPI/containers** when the case is exactly "isolated downstream instance": it is the only one with an **export/import** flow designed for it (§3.1) |
| **Foreman** / **Katello** | Foreman **GPL-3.0**, Katello **GPL-2.0** — `LICENSE`/`LICENSE.txt` files of `theforeman/foreman@develop` and `Katello/katello@master` | If you already manage the RHEL/Debian fleet with Foreman; Katello is Pulp with content management on top |
| **Harbor** | **Apache-2.0** — `LICENSE` file of `goharbor/harbor@main` | **Default for a container registry**: a CNCF project, with a *proxy cache*, replication between instances, immutable tags and cosign signature verification in the project policy |
| **Sonatype Nexus Repository Community Edition** | **EPL-1.0** — `LICENSE.txt` file of `sonatype/nexus-public@master` | **Licence trap**: the code is EPL, but the free edition **has usage limits** — the current documentation cites **40,000 components and 100,000 requests/day**, with ingest paused when exceeded (after a grace period). **A full mirror of a distribution exceeds 40,000 components easily**: if your case is an operating system mirror, this tool forces you to buy. Verify the current numbers before choosing it (§8) |
| **JFrog Artifactory** | **Proprietary** | There is no public source repository to read (`jfrog/artifactory-oss` returns 404). Valid if it is already paid for; **do not count on a free tier** without verifying it. **Declared gap**: the current status of its free editions has not been verified |
| `reposync` + `createrepo_c`, `apt-mirror`/`debmirror`, `devpi`, `verdaccio`, `registry:2` | Each with its own | **Valid and often sufficient.** Less governance and less traceability, but no usage limits and no surprise licence. For a small enclave, a `reposync` in cron and an `rsync` to media beat a platform nobody maintains |

**Rule before choosing**: enumerate **all** the ecosystems the enclave consumes — RPM/DEB, PyPI,
npm, crates, Maven, Go modules, OCI images, Ansible collections, Terraform providers, Helm charts,
IDE extensions, scanner databases — and check which ones the tool supports. **Whatever is missing,
somebody will bring in on a USB**, and that is exactly the failure you wanted to avoid.

## 3. Structure and conventions

### 3.1 How software gets in

Canonical flow, in three legs, with the verification **repeated on the internal side**:

1. **Outside (connected zone)**: it is synchronised against the upstream origin with **signature
   verification enabled** (`gpgcheck=1`/`repo_gpgcheck=1` in `dnf`, `Signed-By` in `apt`'s
   `.sources`, hashes pinned in the language *lockfiles*, `cosign verify` for images). A **transfer
   artifact** is produced with its hash manifest.
2. **Crossing**: physical media or diode. The manifest travels **alongside** the content and, if
   the threat model demands it, **signed with a key of the internal enclave**, not with the outside
   one.
3. **Inside**: it is verified **again**, with the public key that already lives inside the enclave
   and that arrived through a different channel (an installation ceremony, not the same USB).

**Non-negotiable rule**: **a signature verified only on the connected side protects nothing.** The
attacker you are worried about is in transit, not at the origin. If the internal importer accepts
what arrives because "it was already verified outside", the air gap has only added latency.

**Pulp export/import** is the mechanism that implements this out of the box: the *upstream*
instance generates a `.tar` of the selected repository versions plus a **`-toc.json` file with the
global and per-file SHA-256 hash**, which the *downstream* instance — described in the
documentation as **network-isolated** — uses to verify and import. It supports **incremental
export** (`full=False`, with `start_versions=` to fix the starting point) and **chunking** by
`chunk_size` so it fits on the media. That is the pattern to replicate even if you do not use Pulp:
**content + signed manifest + verification at the destination + incrementality**.

**Container images**: `skopeo copy --dest-dir` or `oras` produce a transportable OCI directory;
`docker save`/`load` works but loses signatures and metadata. Inside, they are pushed to Harbor or
to a local `registry:2`. If the consumer is `cephadm`, Rook or Kubernetes, **the internal registry
must exist before the bootstrap**: `cephadm`'s documentation describes exactly this scenario and
requires all the images (Ceph, Prometheus, node-exporter, Grafana) to be inside already.

**Signing on the isolated side with cosign**: `cosign verify` can work without going out to the
Internet with `--key` and a **`--trusted-root` (Sigstore trusted root JSON file) copied inside**,
and with `--local-image` over images saved with `cosign save`. `--insecure-ignore-tlog` exists and
is sometimes unavoidable, but **it is a degradation**: it gives up the inclusion proof in the
transparency log. If you use it, make it a written decision, not a flag copied from a blog.

### 3.2 The physical transfer

USB is the documented vector. This is not theory:

- **Stuxnet** got into an isolated enrichment facility through removable media. It is the canonical
  case and the reason "isolated" stopped meaning "secure".
- **Agent.BTZ / Operation Buckshot Yankee (2008)**: an infected USB stick plugged into a US CENTCOM
  laptop propagated the worm to **SIPRNet**, the Department of Defense's classified network. The
  cleanup took on the order of **14 months**, prompted the ban on removable media and contributed to
  the creation of US Cyber Command. Textbook isolation, defeated by a removable drive.
- **GoldenJackal** (ESET research, published in October 2024): a cyberespionage group with **two
  different toolsets, specifically designed to jump into isolated systems**, used against an embassy
  in Belarus (2019) and against a European government body (May 2022 – March 2024). The pattern: a
  component on the USB collects from the isolated machine and **waits for that same USB to go back
  to a connected machine** in order to exfiltrate. You do not need a connection: you need a cycle.

Minimum controls, and they are process, not product:

- **One-way, single-use media** for entry: labelled, used once, destroyed or reformatted with a
  procedure. **No USBs that come and go**: the round trip is literally GoldenJackal's exfiltration
  mechanism.
- **A dedicated intermediate scanning station**, with different engines from the enclave's,
  isolated itself and with a rebuildable image. It is a sacrificial machine, not anybody's laptop.
- **Chain of custody**: who generated the artifact, who transported it, who imported it, with what
  hash and at what time. It is the record you will need when an incident has to be reconstructed.
- **Autorun disabled and device control** across the enclave: only registered media, by identifier,
  and only on the designated machines.
- **The vendor's laptop does not come in.** If they have to work, they do it from an enclave
  machine, with a named account and a logged session. It is the point that gets negotiated most and
  the one that costs most when conceded.

### 3.3 Patching and vulnerabilities with no connection

**Isolation does not exempt you from patching: it changes its calendar and its cost.** And that
change is the real argument against an unnecessary air gap — an environment where a patch takes
weeks to get in is an environment where an actively exploited vulnerability lives for weeks.

- **Vulnerability data has to be brought in like any other artifact**: scanner databases, vendor
  advisories, the distribution's OVAL. Trivy explicitly documents the scenario: its databases
  (vulnerabilities, Java, *checks*, VEX Hub) are packaged as **self-hostable OCI images** in your
  own registry; the *checks* bundle is **embedded in the binary** as a fallback, with the date of
  the release you use; `--offline-scan` avoids the calls to Maven Central; and
  `--skip-version-check --disable-telemetry` — **both, one alone is not enough** — cut the
  connections to `check.trivy.dev`. Verify the equivalent for your scanner before assuming it.
- **The scanner is software that also comes in through the physical channel**, and scanners are a
  supply chain target: `kubernetes-standards` §2 documents the compromise of Trivy's *actions* in
  March 2026. Pin by digest and verify signatures **also** for security tools.
- **Honest calendar**: define an import SLA (e.g. a weekly content window, plus a **rehearsed
  emergency route** for a critical KEV) and measure it. Triage follows the rules of
  `vulnerability-management-standards`; what changes here is that **the clock starts when the datum
  gets in, not when the CVE is published**, and that difference has to be measured and reported,
  not hidden.
- **Inventory and SBOM are more important here, not less**: without them you cannot answer "does it
  affect me?" when the advisory arrives through a slow channel.

### 3.4 Time

With no external source, **the clock drifts**, and the drift breaks things nobody associates with
the clock:

- **Kerberos**: the maximum tolerated skew by default in MIT krb5 is **300 seconds (five
  minutes)** (`clockskew` in `krb5.conf`). Once exceeded, authentication fails wholesale and the
  symptom is "I can't log in to anything", not "the clock is wrong".
- **TLS**: a fast clock invalidates valid certificates; a slow one accepts expired ones. And in an
  isolated enclave **nobody gets the expiry warning by email**.
- **Logs and forensics**: with no common reference, correlating two servers is impossible.

Design: **a stratum-1 source inside the enclave** — a GNSS/GPS receiver with an antenna, or a
disciplined oscillator — and `chrony` as the internal server, with **at least two sources** so you
can detect that one is lying. Without GNSS, the minimum acceptable pattern is a **documented and
periodic** manual adjustment procedure against a reliable reference, with a record. Watch drift as
a first-class metric: it is one of the few that degrades silently until it breaks everything at
once.

### 3.5 Internal PKI

- The enclave needs **its own hierarchy**: an offline root (inside the enclave itself, or held
  separately), an online issuing CA, and **internal and reachable CRL/OCSP distribution points**.
- **The classic failure**: certificates issued by a CA whose CRL DP points at an Internet URL.
  Clients that validate revocation strictly fail; those that do not, accept revoked certificates.
  Neither is what you wanted.
- **The CRL expires**: its `nextUpdate` is a time bomb if nobody republishes. Automate the
  regeneration and **monitor the remaining time**, just as you monitor certificate expiry.
- No trust anchors that depend on an external service. The whole chain is resolved inside.

### 3.6 Licences and dependencies that phone home

**It is the design failure discovered on cut-over day, not before.** Before isolating, inventory
which component needs to talk to the outside to **function**, not just to update:

- Product activation and licence servers (including those that only check "every now and then" and
  fail after N days).
- Certificate revocation checks and timestamping (RFC 3161).
- Mandatory telemetry and version checks.
- DNS resolution of external domains, including the ones a library does at start-up.
- Federated authentication against a cloud IdP. **Federating with an external IdP means having a
  data path**: either the IdP lives inside, or the enclave is not isolated.
- Models, dictionaries and databases that a service downloads on first start.

Demand contractually, **before buying**, the answer to "does it work with no Internet access and
for how long?" and an offline licensing route. Verify it **in a genuinely cut-off environment** —
not with a firewall rule you can remove — because the commercial answer and the technical one
rarely match.

### 3.7 Backup, recovery and observability

- **The copy lives inside the enclave** and so does its key: an encrypted repository whose secret
  is in a cloud KMS is a backup you cannot restore. The mechanics are in
  `backup-recovery-standards`; the constraint belongs here.
- **The DR plan cannot assume downloads.** Everything needed to rebuild — ISO images, packages,
  container images, the restore tools' binaries, the documentation itself — has to be inside and
  **tested from inside**. A runbook that starts with `curl https://…` is not a runbook in this
  environment.
- **Telemetry**: metrics, logs and traces stay inside; the observability stack is deployed in full
  within the enclave. If something has to get out (reports, alerts to the corporate SOC), **the
  diode is the correct mechanism** and you have to accept that there will be no return channel:
  nobody will be able to "ask for more context" from outside. Design what leaves to be
  self-sufficient.
- **The SOC outside does not see the enclave.** Either there are analysts inside, or there is a
  well-designed unidirectional flow, or the enclave is a detection blind spot — which is exactly
  where an attacker who is already in wants to be.

## 4. Verification

Isolation is demonstrated, not declared.

1. **Path test**: from several enclave hosts, an active attempt to get out over HTTP(S), DNS, NTP,
   ICMP and common protocols towards controlled external destinations. **Everything** must fail,
   and you also have to review what was logged at the edge. Repeat after every network change.
2. **Inventory of physical paths**: enabled USB ports, optical drives, BMCs and their management
   network, serial consoles, Wi-Fi and Bluetooth on laptops and servers, and **any out-of-band
   management interface** somebody has connected to the corporate network "just for monitoring".
   That last one is the most common and the one that breaks the whole isolation.
3. **Import chain test**: bring in an artifact **with a deliberately tampered signature** and check
   that **the internal side rejects it**. If it goes through, your verification is decorative.
4. **Clock test**: shift a server's clock beyond `clockskew` and check that detection fires before
   it breaks authentication.
5. **Licence and cold start test**: restart the whole enclave with no connectivity at all and check
   what does not come up. Doing it for the first time during a disaster is the scenario you were
   trying to avoid.
6. **Emergency route rehearsal**: time how long it takes for a critical patch to be applied inside,
   end to end. That number is your real exposure, and it goes in the risk register.

## 5. Security

- **Correct threat model**: isolation removes the opportunistic remote attacker. It **does not
  remove** the insider, the vendor, the supply chain of the software you import or the patient
  attacker waiting for a USB to make the return trip. Design for those four.
- **Defence in depth inside the enclave**: the most expensive mistake is treating the interior as a
  trust zone. With no Internet access, lateral movement is just as easy and **much less visible**.
  Internal segmentation, least privilege, MFA, EDR and hardening remain mandatory
  (`linux-hardening-standards`, `identity-access-management-standards`).
- **Exfiltration is physical too.** The same media controls you apply on entry apply on exit, and
  all the more so if what motivated the isolation was confidentiality.
- **Watch what remains**: attempts to reach the Internet from the enclave are an extremely
  high-value detection signal — either there is a configuration leak, or there is something trying
  to phone home. That they fail does not mean you should not alert. On the contrary: they are the
  cleanest alert you are going to get.
- **Cryptography**: the enclave cannot lean on external timestamping, transparency or key
  management services. Everything inside, with its own custody and rotation.

## 6. When the air gap is the right answer

| Situation | Verdict |
|---|---|
| Immutable backup vault, offline root CA, long-term archive | **Correct and cheap.** Little content, low frequency, low operational cost |
| A system whose compromise has physical or national security consequences, with a long service life and no capacity for fast patching | **Correct**, and the cost is justified (here the doctrine is set by `ot-ics-security-standards`) |
| Data whose classification requires it by rule | **Correct by obligation**; the work is doing it well, not arguing about it |
| A malware analysis or R&D lab with sensitive material | **Correct**, with the threat direction inverted (`ctf-lab-standards`) |
| A normal business application, "just in case" | **Expensive theatre.** It degrades security: patching becomes slow, observability blind, and the team ends up opening exceptions nobody audits |
| Replacing access management and segmentation nobody wants to do | **Incorrect.** The air gap is not a shortcut for skipping IAM or network policy; it is an additional control **on top of** both |

**Criterion in one line**: the air gap is justified when **the cost of being disconnected is lower
than the risk of being connected**, and that calculation has to be written with numbers — patching
time, dedicated people, cost of the mirror — not with adjectives.

## 7. Long-term sustainability and prohibitions

- **A recurring cost, not a project**: the mirror, the import window, the scanning station, the
  time source, the PKI and the DR rehearsal are **continuous work with a named owner**. An air gap
  with no operational budget degrades to "an old unpatched network with firewall rules".
- **Review the decision every year**: is there still a reason? An isolated enclave kept by inertia
  is pure cost, and an enclave where three "temporary" exceptions have already been opened is no
  longer isolated — it is worse than segmented, because nobody reviews its rules.

Explicit prohibitions:

- ❌ Calling a network with firewall rules towards the Internet an "air gap". **FORBIDDEN** in any
  design or audit document: the word sets risk expectations that reality does not meet.
- ❌ Verifying the signature **only** on the connected side.
- ❌ Removable media that go in and out of the enclave (the round trip).
- ❌ Personal media, and vendor machines connected to the enclave's network.
- ❌ Autorun enabled; writing with no device control.
- ❌ "There is no need to patch here because it is isolated". It is the statement that turns
  isolation into a long-lived vulnerability.
- ❌ An enclave with no defined and monitored time source.
- ❌ CRLs or distribution points pointing outside; trust anchors that depend on an external
  service.
- ❌ "Temporary" exceptions to the isolation with no expiry date and no review.
- ❌ Federating the enclave's identity against an external IdP.
- ❌ Backups or encryption keys of the enclave held outside and only outside.
- ❌ A DR plan that at some step requires downloading something.
- ❌ Isolating without having inventoried which components need to phone home to function.
- ❌ Choosing a mirroring platform by its code licence without checking the **usage limits of the
  free binary** (§2.3).
- ❌ Treating the inside of the enclave as a flat trust zone.

## 8. Mandatory web verification

Before fixing anything from this document in a real design:

1. **Licences and limits of the mirroring platforms**: verified raw as of August 2026 —
   Pulp **GPLv2** (`pulp/pulpcore@main:LICENSE`), Harbor **Apache-2.0**
   (`goharbor/harbor@main:LICENSE`), Nexus **EPL-1.0** (`sonatype/nexus-public@master:LICENSE.txt`),
   Foreman **GPL-3.0**, Katello **GPL-2.0**. **JFrog Artifactory is proprietary** and has no public
   source repository. Always re-verify **by reading the licence file**, not the GitHub label or the
   commercial site.
2. **Usage limits of Nexus Repository Community Edition**: the current documentation cites
   **40,000 components / 100,000 daily requests**; Sonatype's original announcement cited different
   figures (100,000 components / 200,000 requests). **Declared discrepancy**: check
   `help.sonatype.com` for your version before sizing. **Declared gap**: that page could not be read
   raw (a JS application); the datum came in through a web search, not verbatim.
3. **Status of JFrog's free editions** (Artifactory OSS, JFrog Container Registry):
   **declared gap**, not verified.
4. **Your scanner's connectivity requirements**: Trivy's air-gap guide is the reference verified
   here (databases as self-hostable OCI images, embedded *checks*, `--offline-scan`,
   `--skip-version-check` **and** `--disable-telemetry`). For Grype, Wazuh, OpenSCAP or anything
   else, verify the equivalent in its documentation — do not assume it by analogy.
5. **`cosign verify` flags** (`--key`, `--trusted-root`, `--local-image`,
   `--insecure-ignore-tlog`): verified against `doc/cosign_verify.md` of `sigstore/cosign@main`.
   They change between major versions; check the ones in your binary.
6. **Kerberos `clockskew`**: 300 s by default according to MIT krb5's documentation. Active
   Directory has its own parameter and its own policy — verify it separately if the enclave is
   Windows.
7. **Cases cited**: Stuxnet, Agent.BTZ / Buckshot Yankee (2008, SIPRNet) and GoldenJackal (ESET,
   October 2024). If you need to cite them formally, go to ESET's original publication and to the
   primary sources of the 2008 case; the attribution details are disputed and **this document takes
   no side on attribution**, it only uses the cases as proof that the vector exists.
8. **Regulation applicable to the enclave** (ENS, national classification schemes, IEC 62443 if it
   is industrial): it is set by `grc-compliance-standards` or `ot-ics-security-standards`.
   **Declared gap**: this document cites no requirements for classified environments; the defence
   sources consulted historically in this catalogue block automated access.

If the web contradicts this document, **the web wins** — flag the discrepancy.
