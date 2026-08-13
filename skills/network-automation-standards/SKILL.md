---
name: network-automation-standards
description: Network as code — source of truth, generation, validation and safe rollout of device configuration. Use when driving devices from Ansible network collections (ansible.netcommon, cisco.ios, arista.eos, junipernetworks.junos, nokia.srlinux), Nornir with nornir-napalm or nornir-netmiko, NAPALM get_facts/compare_config/commit_config, netmiko send_config_set, scrapli or scrapli-netconf, Jinja templates rendering device config, NetBox as source of truth with pynetbox, custom fields, config contexts, config templates or the NetBox Ansible/Nornir inventory plugin, YAML intent data and schema validation, NETCONF (RFC 6241), RESTCONF (RFC 8040), YANG 1.1 (RFC 7950), NMDA (RFC 8342), candidate datastores and confirmed-commit, gNMI Get/Set/Subscribe with gnmic or pygnmi, OpenConfig versus IETF versus native YANG models, streaming telemetry replacing SNMP polling, containerlab .clab.yml topologies, netlab, vrnetlab or GNS3/EVE-NG virtual labs, pre-checks and post-checks, config diff and dry-run, drift detection against intent, batched canary rollout with tested rollback, commit-confirm timers, Batfish or pyATS/Genie operational-state validation, or storing device configs and credentials in a git repository.
---

# Network automation standards — the network as code

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **automating the configuration and verification of network devices**: source of truth
and its governance, intent data model, configuration generation, device interfaces (CLI,
NETCONF/RESTCONF, gNMI), testing and operational-state validation, virtual lab, network CI/CD with
batched rollout and tested rollback, drift detection, streaming telemetry, and the **custody of the
credentials that grant access to the entire fleet**.

Triggers: `*.clab.yml`, `containerlab`, `netlab`, `vrnetlab`, `nornir_config.yaml`, `hosts.yaml`,
`groups.yaml`, `napalm`, `netmiko`, `scrapli`, `pynetbox`, `ansible.netcommon`,
`cisco.ios`/`arista.eos`/`junipernetworks.junos`/`nokia.srlinux`, `gnmic`, `pygnmi`, `ncclient`,
`pyang`, `batfish`, `pyats`/`genie`, network configuration `*.j2`, "config context",
"config template", "source of truth", "drift", "pre-check"/"post-check", "commit-confirm",
"streaming telemetry", "dial-in"/"dial-out".

**Not applicable** — each skill **decides** a different thing:
`networking-standards` (**the trunk, the parent**: decides **addressing and IPAM, VLANs, routing
fundamentals, MTU/MSS and that NetBox is the intent SoT**; none of that is repeated here, here what
gets decided is **how that intent is modelled, how the configuration is generated and how it reaches
the device without breaking anything**); `routing-switching-standards` (**decides what the campus and
edge configuration must say**: STP, LACP, MLAG, IGP, BGP policy, RPKI, CoPP, AAA);
`datacenter-fabric-standards` (**decides what the fabric configuration must say**: Clos, EVPN, VRF,
MTU, lossless networking). **Those two design; this one automates what they design.**
`network-troubleshooting-standards` (**decides the reactive method** when the automated change broke
something); `iac-standards` (**decides Terraform and Ansible as tools and how they are written** —
here only what is network-specific); `secrets-management-standards` (**decides the secrets manager**,
rotation and ephemeral credentials); `observability-standards` (**decides the platform, the
thresholds and the alerts** — here only where the device data comes from and over which protocol);
`cicd-standards` (**decides the pipeline engine**); `firewall-policy-standards` (**decides the
filtering policy and its governance**, even when it is applied with these tools);
`opensource-licensing-standards` (**decides the acceptable licence** of every tool adopted). Also
bordering: `sre-practice-standards`, `dns-standards`, `vpn-standards`, `kubernetes-standards`,
`onprem-standards` (umbrella), `identity-access-management-standards`, `linux-hardening-standards`,
`vulnerability-management-standards`, `finops-standards`, `offensive-security-standards` (**this
skill is defensive**), and `network-vendors-standards`, `wan-legacy-standards`,
`telco-5g-standards`, `high-speed-interconnect-standards` and `datacenter-facilities-standards`.

**Governing principle**: **automating a badly designed network breaks it faster and in more places at
once.** Automation does not fix the design: it multiplies it. That is why the order is **first read
and check, then generate, and only at the end apply**, and why the hard rule is that **a network
change either rolls itself back or it is not applied**.

## 2. Default decisions

> Versions and licences verified Aug 2026 against the **PyPI JSON API**, the **Atom release feeds**
> and the **raw `LICENSE` file**. Re-verify before committing to anything (§8).

| Area | Default | Justifiable alternative / vetoed |
|---|---|---|
| Source of truth | **NetBox 4.6.7** (30 Jul 2026; **Apache-2.0**, verified in the raw `LICENSE.txt`) as the **intent** SoT | ❌ Spreadsheet; ❌ the device configuration as SoT; ❌ populating it by discovery and calling that intent |
| Data model | **Versioned declarative intent** (YAML or NetBox objects) **with a schema validated in CI** | ❌ Intent embedded in the templates; ❌ schema-less data |
| General orchestrator | **Ansible** (`ansible-core` 2.21.2, **GPL-3.0-or-later**) with network collections, if it is already the house standard | Slow execution model on large fleets and crude per-host error handling |
| Python framework | **Nornir 3.6.0** (2 Aug 2026, **Apache-2.0**) when real logic, concurrency and tests are needed | Nornir is a framework, not a toolbox: it brings inventory and parallelism, **you supply the drivers** (`nornir-napalm` 0.6.0, `nornir-netmiko`) |
| Multi-vendor abstraction | **NAPALM 5.2.0** (27 Jul 2026, **Apache-2.0**) for normalised `get_*`, `compare_config` and confirmed commit | Limited and uneven platform coverage: **verify the driver for your NOS before designing on top of it** |
| CLI transport | **netmiko 4.7.0** (12 May 2026, **MIT**) as the safe option; **scrapli** (**MIT**) for performance, async or NETCONF | **scrapli is in transition** (§8): the latest non-prerelease on PyPI is `2026.2.20` and the 2.0 rewrite is at *release candidate*. **Do not pin it as the default yet** |
| Templates | **Jinja 3.1.6** (**BSD-3-Clause**), with **dumb templates and rich data** | ❌ Business logic in the template: code without tests |
| Device interface | **gNMI** for telemetry and, where support is solid, for configuration; **NETCONF (RFC 6241)** for transactional configuration | **CLI** only when there is no data model; **RESTCONF (RFC 8040)** where it is the only thing available |
| gNMI client | **`gnmic` 0.46.0** (14 May 2026, **Apache-2.0**, under the **openconfig** organisation); **`pygnmi`** (BSD-3-Clause) from Python | Writing your own gRPC client without needing to |
| YANG models | **OpenConfig** first in a multi-vendor environment; **IETF** for the basics (interfaces, IP, routing); **native** only for what neither covers | ❌ Designing the whole automation on native models: that is CLI with a different syntax |
| Virtual lab | **containerlab v0.77.0** (28 Jun 2026; **BSD-3-Clause**, copyright **Nokia**, verified raw) | **netlab** (package `networklab` 26.7, **MIT**) on top; GNS3/EVE-NG and `vrnetlab` if only VM images exist. **NOS images have their own licence and redistribution restrictions: that is a legal problem** |
| Validation | **Operational-state pre-checks and post-checks**, plus static configuration analysis and intent validation | ❌ Validating only that the configuration got written |
| Telemetry | **Streaming telemetry (gNMI `Subscribe`)** where the NOS supports it; **SNMP as a fallback** | ❌ Mass SNMP polling as the only telemetry on a large fleet |

## 3. The right order and its structure

**The order, and no step gets skipped**
1. **Read and check** — inventory, current state, drift against the SoT. Everything read-only is
   automated first: it delivers value without risk and builds confidence and knowledge of the real
   estate before touching anything.
2. **Generate** — configuration rendered from the intent, into a reviewable artifact. **The diff is
   the object under review**, not the template.
3. **Apply** — only at the end, in batches, with rollback armed.

**The source of truth, decided before the tool**
- **An intent SoT and a discovery SoT are different things and do not get mixed.** NetBox holds
  **what must be**; discovery produces **what there is**; the difference is **drift**, and drift is a
  finding with an owner. Auto-populating the SoT from the network erases exactly that signal.
- **Where each thing lives** (what `networking-standards` does not decide): data and relations in
  **NetBox** (sites, devices, interfaces, prefixes, VLANs, circuits); parameters that modulate the
  template in hierarchical **config contexts**; rendering in **config templates** or in the Git
  repository. Split rule: **if two systems can answer the same question with different answers, one
  of them is redundant.**
- **Every piece of intent data has a schema and is validated in CI**: a schema-less YAML is a
  production failure waiting for the first typo. Fail in the pipeline, not on the device.
- **The SoT closes in both directions**: after every change, the SoT reflects the intended reality or
  the change is not finished.

**Device interfaces: the data model is what makes automation portable**
- **CLI by *screen-scraping*** works on everything and **breaks with anything**: a format change in a
  minor version, a banner, a warning, paginated output. There is no contract, no transaction and no
  validation; and the parsing (TextFSM, TTP, home-made templates) is code to maintain per platform
  and per version.
- **NETCONF (RFC 6241) with YANG (RFC 7950)** brings what the CLI does not have: **candidate
  datastore, transaction, prior validation and confirmed commit**. With **NMDA (RFC 8342)** the
  separation between intended configuration, applied configuration and operational state stops being
  ambiguous — which is exactly the distinction that lets you verify intent against reality.
- **gNMI/gRPC** is the best option for **telemetry** (subscription, high frequency, efficient) and
  increasingly valid for configuration; **its declared weak point is the transaction**, where it is
  more limited than NETCONF.
- **The data model is the portability**: writing against **OpenConfig** or IETF models means the same
  code serves another vendor; against native models or CLI, it means rewriting it at the next
  purchase. **The realistic answer is hybrid**: OpenConfig is operationally complete, not exhaustive,
  and real interoperability between vendors is still imperfect. Design with a standard model and
  **isolate in an adapter** whatever demands a native model or CLI.

**Templates**: rich data, dumb templates — every decision that can be taken in the data is taken in
the data. One template per role, composable in blocks, with **deterministic rendering** (same data →
same text, byte for byte) so that the `diff` means something.

## 4. Testing, validation and network CI/CD

- **Virtual lab with the same NOS versions as production**, and with the topology **generated from
  the same SoT**: if the lab is described by hand, it tests a different network.
- **Network pipeline, in increasing cost order**: (1) lint and **schema validation** of the intent;
  (2) rendering and **configuration `diff`** as a reviewable artifact in the PR; (3) static analysis
  of the rendered configuration (reachability, policy, design errors) where the tooling allows it;
  (4) deployment to the **lab** and functional tests; (5) **canary batch** in production with
  post-checks; (6) the rest of the fleet **in batches**, with an abort criterion between batches.
- **Pre-checks and post-checks on operational state, not on configuration**: what matters is not that
  the line got written, but that **adjacencies are still up, the expected prefixes are still there,
  interfaces are not accumulating errors and application traffic passes**. They are captured before,
  compared after, and the comparison is automatic.
- **Intent validation as a continuous gate**: periodic checking that the network behaves as the SoT
  says (routes, neighbours, VLANs, zero drift). A failure here is a finding with an owner.
- **The hard rule: a network change either rolls itself back or it is not applied.** Timed rollback
  (`commit-confirm` or equivalent) armed **before** the change, with a window sized to the
  verification time, and the rollback plan **tested in the lab** as part of the change: an unrehearsed
  rollback is not a plan, it is a hope. Always with an OOB console available.
- **Verified idempotence**: the second run changes nothing. If it changes something, the playbook is
  lying about state and is useless for detecting drift.

## 5. Security: the automation holds the credentials to the whole network

This is the dominant risk of this skill: **whoever controls the automation system controls every
device at once, with changes that also look legitimate.**

- **No credential in the repository or in the inventory**: they are fetched at run time from the
  secrets manager (`secrets-management-standards`); in CI, **OIDC/workload identity** rather than
  long-lived static keys.
- **Named service accounts, with least privilege**: a **read-only** one for inventory, drift and
  telemetry — which is most of the work — and a different, write-capable one only for the apply step.
  **TACACS+ allows per-command authorisation**: use it to bound what the automation account can do
  (`routing-switching-standards`, `identity-access-management-standards`).
- **Ephemeral credentials and rotation**; never a password shared between humans and automation,
  because it destroys the traceability of who changed what.
- **A record of every change, correlatable end to end**: who requested it, which PR approved it, which
  run applied it, to which devices and with which diff. If the device logs and the automation logs
  cannot be cross-referenced, a malicious change is indistinguishable from a routine one.
- **The network configuration repository is a high-value target**: it contains topology, addressing,
  filtering policy and — if someone was careless — credentials. Restricted access, mandatory review,
  **commit signing**, branch protection and **secret scanning as a gate that breaks the build**. A
  secret that reached the history is compromised: it gets **rotated**.
- **Backed-up configurations: encrypted and sanitised** — they contain password hashes, pre-shared
  keys, SNMP communities and certificates.
- **The automation system is critical infrastructure**: management network, minimal surface, patching
  up to date, MFA for whoever operates it, and its own recovery plan (if it goes down, you can
  neither change nor roll back).
- **Supply chain**: collections, PyPI packages and NOS images **pinned by version or digest**, with
  SCA in CI. A compromised collection runs against the entire fleet.

## 6. Telemetry and operability

- **Streaming versus polling**: subscription (gNMI `Subscribe`, dial-in or dial-out) gives higher
  frequency, lower CPU cost on the device and data already structured per the YANG model. Mass SNMP
  polling scales badly and misses short events. **Criterion**: streaming where the NOS supports it,
  **SNMP as a fallback** for the older estate and for what the model does not expose — it is not
  switched off out of dogma. The platform that receives, stores and alerts belongs to
  `observability-standards`.
- **The automation's own signals**: success rate per run and per device, **drift detected** (count and
  age), time from commit to applied change, number of rollbacks, and **unmanaged devices** — those
  last ones are what break rollouts.
- **Declared coverage**: what percentage of the estate is automated and what is left out, with a
  reason. A half-automated estate is more dangerous than a manual one if nobody knows which is which.
- **Toil**: a manual task repeated three times is a candidate for automation; and automation that
  requires routine manual intervention is badly built (`sre-practice-standards`).

## 7. Sustainability and prohibitions

- **Start with reading**: inventory, drift and telemetry first. Immediate value, zero risk, and it
  builds what makes the write phase viable.
- **Cadence**: review version, **maintenance status and licence** every quarter; pin versions and
  upgrade deliberately. **A tool that changes licence or goes into maintenance mode is an architecture
  decision**, not a footnote (`opensource-licensing-standards`).
- **Deprecation**: unused templates, playbooks and scripts get deleted — dead code gets executed by
  accident one day.

**FORBIDDEN**
- ❌ **Applying to the whole fleet with no test batch.** Canary first, batches after, with a written
  abort criterion between batches.
- ❌ **Automating without a reliable inventory**: without a complete and correct SoT, errors propagate
  at scale.
- ❌ **Storing configurations with cleartext credentials in the repository** (or secrets in
  inventories, group variables, templates or run logs).
- ❌ **Relying on the CLI when there is a data model** available on the platform.
- ❌ Applying a change without an armed and **tested** rollback, or without an OOB console available.
- ❌ Changing configuration by hand in production "and I will put it in the repo later".
- ❌ Populating the SoT by automatic discovery and calling it intent.
- ❌ Intent data with no schema and no validation in CI.
- ❌ Business logic inside the Jinja templates.
- ❌ Reviewing the template in the PR instead of the **rendered configuration diff**.
- ❌ Post-checks that only verify that the configuration got written.
- ❌ Running with a shared administrator account, or with the same credential for reading and writing.
- ❌ Long-lived credentials in CI when OIDC/workload identity is available.
- ❌ Collections, packages or images without a pinned version or digest.
- ❌ Automating a network whose design is not settled: fix the design first
  (`routing-switching-standards`, `datacenter-fabric-standards`).
- ❌ A non-idempotent playbook used as a drift detector.
- ❌ Redistributing virtual-lab NOS images without checking their licence.

## 8. Mandatory web verification

**Methodology**: versions from the **PyPI JSON API** and the **GitHub Atom release feeds**
(`api.github.com` returns 403 unauthenticated); **licences read from the raw `LICENSE` file**, not
from the label GitHub's interface shows nor from a summary.

**Verified Aug 2026 (version | date | licence checked raw)**. **NetBox 4.6.7** |
30 Jul 2026 | **Apache-2.0** (`LICENSE.txt` on `main` and `master`; plain `LICENSE` **returns 404** —
the path matters when verifying), with `v4.6.8-rc2` in flight (4 Aug 2026). **Nornir 3.6.0** |
2 Aug 2026 | **Apache-2.0** (slow but alive cadence: 3.5.0 was from Jan 2025). **NAPALM 5.2.0** |
27 Jul 2026 | **Apache-2.0**. **netmiko 4.7.0** | 12 May 2026 | **MIT**. **Jinja2 3.1.6** |
**BSD-3-Clause**. **ansible-core 2.21.2** | **GPL-3.0-or-later**. **pygnmi 0.8.15** |
**BSD-3-Clause**. **gnmic 0.46.0** | 14 May 2026 | **Apache-2.0**, and it **lives under the
`openconfig` organisation**, not under the original personal repository: the project **moved**, and
searching for the old repo gives a false impression of abandonment. **containerlab v0.77.0** |
28 Jun 2026 | **BSD-3-Clause with Nokia copyright** (read in the raw `LICENSE`): **it is not
Apache-2.0**, which is the usual assumption. **netlab** = PyPI package **`networklab` 26.7** |
**MIT** (ipspace and contributors), CalVer, and **the package name does not match the project name**.

**Declared discrepancy — scrapli**: **GitHub and PyPI give different versions for the same thing.**
The Atom feed shows `v2.0.0-rc.16` (20 Jul 2026); PyPI publishes that artifact as `2026.7.20rc16` and
declares **`2026.2.20`** (Feb 2026) as the current version, because under PEP 440 the CalVer sorts
above `2.0.0rc`. **Operational conclusion**: the 2.0 rewrite is at *release candidate*, a
`pip install scrapli` without `--pre` installs the Feb 2026 CalVer line, and **pinning scrapli 2.0 as
the default today is premature**.

**State of OpenConfig/gNMI (qualitative)**: active project (gnmic, ygot, ygnmi, gNOI and
`featureprofiles` with activity in 2026). The models are written in **YANG 1.0** and are
"operationally complete", not exhaustive; **real interoperability between vendors is still
imperfect**, and gNMI is **weaker than NETCONF for transactional configuration** (although the
specification requires that a `SetRequest` spanning several *origins* be treated as a transaction
with rollback). **No authoritative adoption-share figure was found**: treat any number about
OpenConfig or gNMI adoption as unverified.

**RFCs verified one by one against `rfc-editor.org`**: NETCONF **RFC 6241** (Jun 2011, updated by
7803 and 8526); RESTCONF **RFC 8040** (Feb 2017, updated by 8527); YANG 1.1 **RFC 7950** (Aug 2016,
updated by 8342 and 8526); NMDA **RFC 8342** (Mar 2018); YANG Library **RFC 8525** (Mar 2019,
obsoletes RFC 7895).

**Declared gaps — do NOT fill from memory**:
1. **Versions and status of the Ansible network collections** (`ansible.netcommon`, `cisco.ios`,
   `arista.eos`, `junipernetworks.junos`, `nokia.srlinux`): **not verified**; their cadence is
   independent of `ansible-core`.
2. **NAPALM's real coverage per platform and NOS version**: **not verified**, and it is what decides
   whether NAPALM is usable in your estate.
3. **Status, version and licence of Batfish and of pyATS/Genie**: **not verified**; they are mentioned
   as a category, **not as a pinned default**.
4. **Status and licence of GNS3, EVE-NG and `vrnetlab`**: **not verified**. EVE-NG has commercial
   editions: check the specific edition.
5. **Licence and redistribution of lab NOS images**: **vendor-specific and not verified**. It is a
   legal question (`opensource-licensing-standards`).
6. **gNMI and NETCONF support per platform and NOS version**, and the concrete models exposed: **not
   verified**. Check it with `Capabilities` on the real device.
7. **The relationship between NetBox Community (Apache-2.0) and NetBox Labs' commercial offerings**
   and what functionality falls outside the open edition: **not verified**.
8. **`ncclient`, `pyang`, TextFSM/`ntc-templates` and TTP**: version, maintenance and licence **not
   verified**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
