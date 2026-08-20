# Map of `skills/`

> Part of the distributed map. **Root: `../PROJECTMAP.md`** — go there for repository-wide commands,
> invariants, minefields and the index of every other subdirectory map.
> Refreshed **2026-08-14**. If anything here does not match the repo, **the repo wins**: fix the line
> and move on. Maintained per the `project-map` skill.

## What lives here

**The catalogue: one directory per skill, each holding exactly one `SKILL.md`, and nothing else.**
This is a content repository, so the per-file index below **is** the map — it is what answers *"which
skill decides X?"* without a `grep`. Directories are never nested: `skills/<name>/SKILL.md`, always.

Three names are **procedural** rather than domains — two govern this repo's own upkeep,
`project-map/` (this format) and `update-standards/` (re-verifying the catalogue against the web),
and `load-expertise/` governs how the catalogue is *consumed*: which skills a task activates.
Every other name carries the `-standards` suffix.

**No directory holding a `SKILL.md` may exist outside this one**, or it silently registers as an
active skill — which is why `SKILL-TEMPLATE.md` lives at the repository root.

## Index — which skill decides what

**Generated, never hand-written** (`project-map` §2.1, §4.5). Regenerate with
`.claudetools/skills/index.sh` after adding, renaming or retitling a skill; the column is derived
from each file's own `description:` (first sentence) or, when that opens with a trigger list, its
`#` title. Lines are the file's own length — a size signal, not a measurement to quote elsewhere.

| Skill | What it decides | Lines |
|---|---|---|
| `abap-sap-standards` | ABAP custom development inside SAP ERP - the clean core decision and the S/4HANA clock | 293 |
| `accessibility-standards` | Digital accessibility standards | 587 |
| `actionscript-standards` | ActionScript, Flash and AIR - a dead runtime, its surviving artifacts and the exit route | 176 |
| `ada-standards` | Ada and SPARK for high-integrity software | 264 |
| `ai-agents-standards` | Autonomous agent engineering, provider-agnostic | 514 |
| `ai-agent-workflow-standards` | Standards for teamwork with coding agents | 562 |
| `ai-governance-standards` | AI governance standards | 555 |
| `air-gapped-standards` | Operating systems with no Internet path — what a real air gap is, how software gets in and what breaks when nothing can phone home | 409 |
| `aix-solaris-hpux-standards` | Proprietary Unix operating systems still in production — IBM AIX on Power, Oracle Solaris on SPARC and x86, and HP-UX on Itanium | 261 |
| `analytics-bi-standards` | Analytics and BI standards | 478 |
| `api-design-standards` | REST, GraphQL and gRPC API design standards | 191 |
| `appsec-standards` | Application security methodology | 191 |
| `assembly-standards` | Engineering standards for when and how to write assembly | 157 |
| `aws-standards` | AWS architecture, security and FinOps standards | 177 |
| `azure-standards` | Azure architecture, security and FinOps standards | 189 |
| `backup-recovery-standards` | Backup and restore mechanics — how the copy is made, where it lands and how the restore is proven | 586 |
| `bash-linux-scripting-standards` | Shell scripting and Linux automation standards | 324 |
| `bcdr-standards` | Business continuity and disaster recovery as a program | 674 |
| `blockchain-web3-standards` | Blockchain and web3 as infrastructure, custody and regulation — not as smart-contract code | 467 |
| `bsd-systems-standards` | FreeBSD, OpenBSD and NetBSD as deliberate production choices, and their derivatives | 245 |
| `caching-cdn-standards` | Caching and content delivery (CDN) standards | 571 |
| `ceph-standards` | Ceph as distributed storage — the RADOS cluster, its daemons and the decisions that decide whether it survives | 426 |
| `chaos-engineering-standards` | Deliberate fault injection as an engineering discipline | 180 |
| `cicd-standards` | CI/CD standards for GitHub Actions and GitLab CI | 214 |
| `classical-ml-standards` | Classical (non-deep) machine learning on tabular data as an engineering discipline | 293 |
| `classic-asp-standards` | Classic ASP (ASP 3.0) on IIS - the worst attack surface in the Microsoft legacy catalogue, and the migrate-or-isolate decision | 231 |
| `claude-code-skills-standards` | Claude Code skill authoring standards | 293 |
| `clojure-standards` | Clojure and ClojureScript engineering standards (staff-level) | 187 |
| `cloud-security-posture-standards` | Cloud security posture as a transversal discipline across AWS, Azure and Google Cloud at once — what the per-provider skills cannot answer | 385 |
| `cmdb-inventory-standards` | Knowing what you actually own — asset inventory and CMDB as engineering artifacts, not audit paperwork | 264 |
| `cms-jamstack-standards` | CMS and Jamstack standards | 496 |
| `code-review-standards` | Code review as an explicit quality control, not an opinion about someone else's style | 487 |
| `coldfusion-standards` | CFML applications on Adobe ColdFusion, Lucee or BoxLang - a commercial runtime with a heavy exploitation history, and the migrate-or-freeze decision | 255 |
| `compilers-dsl-standards` | Building a language or a language processor, and deciding first whether you need one at all | 316 |
| `computer-vision-standards` | Applied computer vision as a data problem, not a model problem | 341 |
| `container-runtime-security-standards` | Container runtime security and container escape defense | 465 |
| `cpp-standards` | Modern C++ engineering standards (staff-level) | 276 |
| `crm-salesforce-standards` | Salesforce and configurable business SaaS - governor limits as an architectural constraint, clicks versus code, and licence cost as a design input | 390 |
| `cross-platform-desktop-standards` | Shipping a desktop application to Windows, macOS and Linux from one codebase, and paying its real cost | 393 |
| `cryptography-pki-standards` | Applied cryptography and PKI standards | 297 |
| `crystal-standards` | Crystal engineering standards (staff-level) | 134 |
| `c-standards` | C language engineering standards (staff-level) | 283 |
| `ctf-lab-standards` | Security lab and CTF standards | 362 |
| `dart-standards` | Dart standards (language and tooling) | 368 |
| `datacenter-fabric-standards` | The data centre network as a routed Clos fabric, not one big switched network | 273 |
| `datacenter-facilities-standards` | The physical plant of a data centre or server room — everything bolted to the rack but not inside the server | 475 |
| `data-engineering-standards` | Data engineering standards | 451 |
| `data-governance-quality-standards` | Data governance and quality standards | 562 |
| `data-platform-standards` | Standards for data platform design and operations | 160 |
| `data-warehouse-modeling-standards` | Data warehouse modelling standards | 459 |
| `deep-learning-standards` | Training your own deep neural network as an engineering decision, not a default | 280 |
| `design-systems-standards` | Design system standards | 445 |
| `detection-engineering-standards` | Security detection engineering — building and governing SIEM detections as code | 500 |
| `developer-workstation-standards` | Developer workstation standards | 575 |
| `dns-standards` | DNS service architecture, zone design and DNS security | 473 |
| `dotnet-framework-legacy-standards` | .NET Framework 4.x legacy maintenance and the migration decision to modern .NET | 228 |
| `dotnet-standards` | C#/.NET engineering standards for backend services | 187 |
| `e-commerce-standards` | E-commerce standards | 553 |
| `edge-computing-standards` | Computing on nodes you cannot walk up to — fleet operations for edge sites and devices under an intermittent link | 400 |
| `elixir-erlang-standards` | Elixir / Erlang standards (BEAM and OTP) | 477 |
| `email-security-standards` | Email as an attack surface and the DNS records that defend it | 277 |
| `embedded-iot-standards` | Engineering a physical connected device — microcontroller or embedded Linux — from silicon choice to field update and its EU regulatory deadline | 394 |
| `endpoint-security-standards` | Defending the endpoint as a control, and measuring whether the control is actually there | 274 |
| `enterprise-architecture-standards` | The application landscape of an organization, not the design of one system | 443 |
| `erp-sap-standards` | SAP as a commercial and platform decision - the maintenance clock, the deployment model and the licence audit | 625 |
| `file-servers-standards` | Classic file-sharing servers — the protocol that exposes a directory tree to other machines, and its blast radius | 196 |
| `finops-standards` | Cost as an engineering metric, not a monthly invoice report | 618 |
| `fintech-payments-standards` | Payments and fintech standards | 579 |
| `firewall-policy-standards` | Firewall policy as a governed engineering artifact | 500 |
| `fortran-standards` | Modern and legacy Fortran for numerical and HPC codes | 250 |
| `frontend-frameworks-standards` | Frontend frameworks standards | 357 |
| `frontend-web-platform-standards` | Web platform (frontend) standards | 395 |
| `game-development-standards` | Game development as engineering, governed by the frame budget | 402 |
| `gaming-infrastructure-standards` | Multiplayer game hosting infrastructure | 193 |
| `gcp-standards` | Google Cloud (GCP) architecture, security and FinOps standards | 204 |
| `gis-geospatial-standards` | Geospatial data as an engineering discipline — coordinate reference systems, formats and spatial SQL | 434 |
| `git-workflow-standards` | Git branching, commit and release process standards | 207 |
| `go-standards` | Go engineering standards (staff-level) | 180 |
| `govtech-eidas-standards` | European e-government engineering — electronic identity, trust services and administrative procedure | 487 |
| `gpu-computing-standards` | GPU computing standards | 517 |
| `graph-db-standards` | Graph database standards | 406 |
| `grc-compliance-standards` | Governance, risk and compliance standards | 253 |
| `green-it-standards` | Sustainable IT standards (Green IT) | 629 |
| `groovy-standards` | Groovy standards (reference: August 2026) | 297 |
| `ha-clustering-standards` | High availability for services running inside an OS, with Pacemaker/Corosync as reference | 553 |
| `haskell-fp-standards` | Haskell production engineering standards | 277 |
| `healthtech-fhir-standards` | Clinical interoperability and health software engineering | 488 |
| `high-speed-interconnect-standards` | RDMA interconnects for HPC, AI and storage — InfiniBand, RoCE v2 and iWARP as a separate network from the data network | 275 |
| `home-automation-standards` | Engineering a home that keeps working when the internet, the vendor or the hub goes down | 381 |
| `homelab-standards` | Homelab and self-hosting standards for a personal lab | 223 |
| `hpc-standards` | High-performance computing clusters as an operated service — batch scheduling, the software environment and the parallel filesystem | 417 |
| `hyper-v-standards` | Hyper-V on Windows Server and Azure Local as a production virtualization platform | 255 |
| `i18n-standards` | Internationalisation (i18n) standards | 548 |
| `iac-standards` | Infrastructure as Code standards (staff/principal level) | 157 |
| `ibm-i-rpg-standards` | IBM i (AS/400, iSeries, System i) application engineering on Power | 531 |
| `identity-access-management-standards` | Identity and access management standards | 294 |
| `identity-threat-detection-standards` | ITDR — detecting and responding to attacks against identity itself, which is where the perimeter actually is | 457 |
| `incident-management-standards` | Incident management standards — the process, whatever the cause | 417 |
| `incident-response-forensics-standards` | Security incident response and digital forensics standards | 446 |
| `itsm-itil-standards` | ITSM / ITIL standards — the service contract with the business | 466 |
| `jsp-struts-standards` | Legacy Java web applications built on JSP and Apache Struts - a security problem before it is a maintenance problem | 259 |
| `julia-standards` | Julia standards (reference: August 2026) | 374 |
| `jvm-spring-standards` | JVM engineering standards for Java/Kotlin backends with Spring Boot | 175 |
| `kernel-drivers-standards` | Writing, reviewing and shipping code that runs inside an OS kernel, and deciding whether it should live there at all | 471 |
| `knowledge-management-standards` | Documentation as infrastructure with a maintenance cost, for human readers | 374 |
| `kubernetes-standards` | Kubernetes and container standards (staff/principal level) | 288 |
| `lakehouse-standards` | Lakehouse standards (open table format) | 612 |
| `lean-code-standards` | Lean code standards — the code you did not write has no bugs | 159 |
| `legacy-modernization-standards` | Umbrella skill for inherited systems - what to do with a system before touching its code, and the router to the platform skill that owns it | 381 |
| `libvirt-kvm-standards` | Bare KVM/QEMU with libvirt on standalone hosts, with no management platform above it | 464 |
| `linux-administration-standards` | Day-to-day Linux system administration, distribution-agnostic | 468 |
| `linux-hardening-standards` | Linux OS hardening baselines and their measurement | 566 |
| `linux-storage-standards` | Linux block storage and traditional filesystems, everything except ZFS | 537 |
| `lisp-standards` | The Lisp family except Clojure - Common Lisp and Scheme | 228 |
| `llm-app-engineering-standards` | Provider-agnostic engineering standards for product code backed by an LLM | 577 |
| `llm-evaluation-standards` | Measuring non-deterministic LLM systems as an engineering discipline | 496 |
| `load-balancing-standards` | Load balancing as a failure-handling decision, not just traffic sharing — health checks, draining and TLS termination are where the value is | 258 |
| `load-expertise` | Derive and load the skills a task actually activates, before writing anything | 175 |
| `local-inference-standards` | Local inference standards | 551 |
| `lowcode-governance-standards` | Governance of low-code and no-code platforms - shadow IT, ownership, data policies and the cost that shows up later | 419 |
| `lua-standards` | Lua standards (reference: August 2026) | 318 |
| `macos-fleet-standards` | Managing a fleet of corporate Macs — enrollment, MDM, compliance and lifecycle, not using one Mac | 238 |
| `mail-servers-standards` | Running your own mail server — the decision first, the daemons second, because deliverability reputation decides the outcome | 230 |
| `mainframe-zos-cobol-standards` | IBM Z mainframe engineering and the COBOL application estate on z/OS | 246 |
| `mcp-standards` | Model Context Protocol server and client engineering | 352 |
| `message-brokers-standards` | Message broker standards | 609 |
| `microservices-architecture-standards` | Standards for systems already split across the network - the distributed topology, not the internal design of one deployable | 156 |
| `migration-projects-standards` | How a platform or infrastructure migration is actually executed - the cutover, not the strategy | 284 |
| `mlops-standards` | MLOps standards — the model lifecycle as production engineering | 513 |
| `mlsecops-standards` | Security of the model lifecycle and the AI supply chain | 615 |
| `mobile-standards` | Native mobile engineering standards for iOS and Android | 217 |
| `model-finetuning-standards` | Fine-tuning an existing model's weights as the last resort, after prompting and retrieval | 299 |
| `multimodal-genai-standards` | Generative and understanding systems over non-text modalities — image, audio, video and document — as an engineering problem, provider-agnostic | 280 |
| `mumps-standards` | MUMPS/M language and globals-based systems, almost exclusively healthcare | 246 |
| `mysql-mariadb-dba-standards` | MySQL / MariaDB / Percona standards (DBA) | 521 |
| `network-automation-standards` | Network as code — source of truth, generation, validation and safe rollout of device configuration | 277 |
| `networking-standards` | Network engineering standards | 308 |
| `network-troubleshooting-standards` | Reactive network fault diagnosis method — bisecting the path, forming a falsifiable hypothesis and proving root cause | 539 |
| `network-vendors-standards` | What actually changes when the box has a different logo — vendor operating models, licensing, lifecycle and vendor risk | 350 |
| `nim-standards` | Nim engineering standards (staff-level) | 123 |
| `nlp-standards` | Natural language processing as a discipline, deciding between a regex, a small specialised model and an LLM | 330 |
| `nosql-standards` | NoSQL data store standards | 424 |
| `objective-c-standards` | Objective-C and Objective-C++ engineering standards for legacy maintenance and Swift interoperability | 198 |
| `object-storage-standards` | Object storage as a model distinct from block and file — the S3 API, its self-hosted implementations and its failure modes | 532 |
| `observability-standards` | Observability standards | 303 |
| `ocaml-fsharp-standards` | OCaml and F# language engineering standards (the strict ML family) | 268 |
| `offensive-security-standards` | Offensive security standards (pentest, red team, purple team) | 407 |
| `onprem-standards` | On-premise platform umbrella - the whole datacenter or server room as one system, and the router to the deep infra skill that owns each layer | 269 |
| `opensource-licensing-standards` | Open source licensing and compliance standards | 657 |
| `operating-systems-standards` | Operating-system mechanics as an engineering constraint — what the kernel actually does to your program and which design decisions follow from it | 436 |
| `oracle-dba-standards` | Oracle Database administration standards | 683 |
| `os-provisioning-standards` | Unattended OS installation on bare metal and VMs — network boot and the answer file that drives the installer | 240 |
| `ot-ics-security-standards` | Securing industrial control and operational technology where availability and physical safety outrank confidentiality | 305 |
| `pascal-delphi-standards` | Object Pascal in production - Embarcadero Delphi and Free Pascal/Lazarus, and the migrate/wrap/freeze decision | 233 |
| `performance-engineering-standards` | Performance engineering standards | 679 |
| `perl-standards` | Perl standards (reference: August 2026) | 331 |
| `php-standards` | PHP engineering standards (modern PHP, Laravel, Symfony) | 181 |
| `physical-security-standards` | Physical security as it applies to IT assets — the controls that matter once someone can touch the hardware | 435 |
| `platform-engineering-standards` | An internal platform is a product whose customers can refuse to use it | 644 |
| `plsql-oracle-forms-standards` | PL/SQL as a program language and Oracle Forms/Reports as a legacy application layer - two things with different futures | 252 |
| `podman-systemd-containers-standards` | Containers as systemd services on a single host with Podman and Quadlet, without an orchestrator | 567 |
| `post-quantum-crypto-standards` | Planning and executing the migration to post-quantum cryptography — the transition, not the PKI | 348 |
| `powershell-standards` | PowerShell standards | 367 |
| `privacy-engineering-standards` | Privacy engineering standards | 515 |
| `product-discovery-standards` | Reducing the risk of building something nobody needs, before it is built | 386 |
| `project-management-standards` | Project and delivery management standards | 512 |
| `project-map` | Build and maintain PROJECTMAP.md, the orientation index of whatever repository you are working in, so the same grep/find/read is never paid for twice | 363 |
| `prolog-standards` | Logic programming in Prolog and its constraint solving niche | 222 |
| `proxmox-ve-standards` | Proxmox VE and Proxmox Backup Server as a production virtualization platform | 439 |
| `pwa-standards` | PWA standards (installable web app) | 532 |
| `python-standards` | Python standards (reference: August 2026) | 182 |
| `quantum-computing-standards` | Quantum computing as an R&D decision with honest expectations — what today's hardware can and cannot do | 320 |
| `rag-standards` | Retrieval-augmented generation treated as a retrieval problem | 604 |
| `refactoring-tech-debt-standards` | Standards for managing technical debt and refactoring legacy code | 243 |
| `rhel-fedora-standards` | Red Hat family specifics - RHEL, CentOS Stream, Fedora, AlmaLinux, Rocky | 505 |
| `robotics-ros-standards` | Robotics with ROS 2, from workspace layout to machine safety | 421 |
| `routing-switching-standards` | Campus and edge switching/routing design decisions that outlive the hardware | 260 |
| `rpa-workflow-automation-standards` | Automating a business process with a robot that drives a user interface, and knowing when not to | 373 |
| `r-standards` | R standards (reference: August 2026) | 383 |
| `ruby-standards` | Ruby and Rails standards | 343 |
| `rust-standards` | Rust engineering standards (staff-level) | 169 |
| `safety-critical-standards` | Functional safety and certification evidence for software whose failure can injure or kill | 479 |
| `scala-standards` | Scala engineering standards (staff-level) | 181 |
| `search-engines-standards` | Text search and document indexing engines as infrastructure | 537 |
| `secrets-management-standards` | Secrets lifecycle for already-generated credentials | 517 |
| `selinux-standards` | Mandatory access control on Linux with SELinux and AppArmor | 462 |
| `server-hardware-standards` | Choosing, sizing, securing and retiring physical servers | 266 |
| `session-tooling-standards` | Session tooling standards — the workshop is derivable, ignored, and free of secrets | 165 |
| `smalltalk-standards` | Smalltalk and its live image-based development model | 224 |
| `soc-operations-standards` | Running the security operations function as an operation, not a product | 270 |
| `software-architecture-patterns-standards` | Standards for choosing and justifying an internal architecture style | 190 |
| `solidity-standards` | Solidity and EVM smart contract engineering standards | 266 |
| `sqlserver-dba-standards` | Microsoft SQL Server administration standards | 704 |
| `sql-standards` | SQL language standards | 377 |
| `sre-practice-standards` | SRE practice standards for service reliability | 314 |
| `streaming-cdc-standards` | Streaming and change data capture (CDC) standards | 625 |
| `streaming-multimedia-standards` | Video/audio ingest, transcoding, packaging and delivery pipelines | 188 |
| `tech-leadership-standards` | Technical leadership as a set of decisions and artifacts, not a personality trait | 721 |
| `technical-hiring-standards` | A hiring process is a measuring instrument and is judged by its validity and reliability | 748 |
| `telco-5g-standards` | Mobile operator networks from the point of view of whoever integrates or buys them, including private cellular | 373 |
| `testing-qa-standards` | Test strategy across languages - deciding what to test and in what proportion, not which runner to use | 474 |
| `threat-intelligence-standards` | Cyber threat intelligence as a production discipline — producing, scoring, ageing out and retiring knowledge about the adversary | 251 |
| `timeseries-db-standards` | Time-series database standards | 532 |
| `tool-usage-standards` | Which instrument does a job inside the harness itself — routing, the IDE index, delegation, workflows and the session window | 344 |
| `typescript-standards` | TypeScript / Node / React standards (reference: August 2026) | 192 |
| `update-standards` | Re-verify the criteria documents this repository emits against the web, and refresh what has decayed **manual-only** | 239 |
| `vb6-standards` | Visual Basic 6.0 legacy applications - freeze, isolate or rewrite | 211 |
| `vbnet-standards` | Visual Basic .NET as a frozen-but-supported language, and the stay-or-convert-to-C# decision | 190 |
| `vector-db-standards` | Operating a vector search engine as a piece of infrastructure | 506 |
| `vmware-standards` | VMware vSphere / VCF as a production platform under Broadcom, and the stay-or-exit decision | 249 |
| `vpn-standards` | VPN tunnels and remote access as a designed, operated service | 657 |
| `vulnerability-management-standards` | Vulnerability management standards | 168 |
| `wan-legacy-standards` | The inherited wide-area network that is still carrying production traffic, and the replace-or-keep decision | 332 |
| `web-app-servers-standards` | The web server and application server as a host you operate, harden and patch — not as the proxy that decides routing | 243 |
| `webassembly-standards` | WebAssembly standards (compilation target and runtime) | 410 |
| `webgl-webgpu-standards` | Browser GPU graphics and compute standards (WebGL2 / WebGPU) | 452 |
| `web-performance-standards` | Web performance standards | 474 |
| `windows-server-ad-standards` | Windows Server and Active Directory Domain Services security standards | 614 |
| `wireless-standards` | Enterprise Wi-Fi as a designed radio system — site survey, spectrum and capacity, not just placing access points | 264 |
| `xen-standards` | The Xen hypervisor, XCP-ng and the XenServer legacy - dom0/domU, PV/HVM/PVH and when Xen is still the right answer | 234 |
| `xr-standards` | Virtual, augmented and mixed reality engineering where comfort, latency and biometric privacy are hard requirements | 385 |
| `zfs-standards` | OpenZFS pool design and operation on Linux and FreeBSD | 451 |
| `zig-standards` | Zig engineering standards (staff-level) | 126 |

## Conventions here

- **Frontmatter**: `name:` in kebab-case, **equal to the directory name** — gate 1 of `../check.sh`.
  `description:` on a single line, in **English**, stating artifact-level triggers with zero filler.
  **The description is the only part injected every turn**: it is the index cost the whole catalogue
  pays on every prompt, so it is written to be a trigger, not a summary.
- **Body**: the canonical 8 sections of `../SKILL-TEMPLATE.md`. §1 must end with the
  `**Not applicable**:` boundary line and §8 must close with the arbitration sentence — both are
  greps for the **literal** in `../check.sh`, so paraphrasing silently disables the gate.
- **Verification date**: the body opens with `Criteria verified as of **<Month Year>**`.
  `update-standards` §2 fixes the canonical spelling.
- **Nothing factual from memory**: versions, EOLs, licences, flags and prices are verified on the web
  and dated. **A declared gap beats an invented fact.**
- **The `-standards` suffix marks a domain**; its absence marks a procedural skill governing this
  repository.

## Minefields here

- **`disable-model-invocation: true` is stronger than "does not auto-fire".** The `Skill` tool
  refuses it outright, so the skill can only be launched by the user as `/<slug>` — it will never
  fire from a trigger, however well the `description:` is written. Only `update-standards/` carries
  it. List them with `grep -l '^disable-model-invocation: true' */SKILL.md`.
- **`claude-code-skills-standards/SKILL.md` §4.3 embeds a runnable script inside a fenced block.**
  Editing its indentation breaks extraction. After touching its `STOP` list, re-extract and re-run
  it, or the trigger-collision gate stops being reproducible.
- **The language migration is finished — descriptions and bodies are all English.** `../check.sh`
  still accepts the Spanish §1 form, so a translation regression would pass the gate silently. Detect
  it with `grep -lE '^\*\*No aplica\*\*' */SKILL.md`, which must return nothing — **anchor the
  pattern**, because a bare `grep -l 'No aplica'` also matches the files that merely *document* the
  literal.
- **Adding a skill is not free.** Every new `description:` is paid on every prompt of every session
  forever; `../check.sh` prints the running index cost for exactly that reason.
- **A new skill's triggers can collide with an existing one's**, which is invisible until both fire
  or neither does. The gate for it lives in `claude-code-skills-standards/` §4.3, not here.
- **Renaming a skill is two edits, not one.** The directory and the `name:` in its frontmatter must
  match or `../check.sh` fails; the row above is regenerated, never hand-patched.

## Neighbours

- Everything repository-wide (gates, installer, doctrine, git identity) → `../PROJECTMAP.md`
