---
name: claude-code-skills-standards
description: Use when authoring, reviewing or debugging Claude Code Agent Skills — SKILL.md files, frontmatter fields, description triggers, skill activation problems, catalog organization, or deciding whether something belongs in a skill, CLAUDE.md or a subagent.
---

# Claude Code skill authoring standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when creating, reviewing, debugging or reorganising skills: `SKILL.md` files, frontmatter,
`description` design, activation problems ("the skill doesn't fire" / "the wrong one
fires"), and the decision of where a rule lives.

**Not applicable**: `update-config` (harness configuration in `settings.json`, hooks and
permissions), `knowledge-management-standards` (documentation for humans: ADR, runbooks, README),
`ai-agent-workflow-standards` (how agents are used safely, not how their skills are
written), `update-standards` (**re-verifying an already written skill against the web**: refresh
cadence, the `Criteria verified as of` line, closing a `Declared gap`, and the traps that make a
refresh assert a confident falsehood — **this skill decides how a skill is built, that one how an
existing one stops being false**).

## 2. Default decisions

> Verify the current specification on the web before pinning frontmatter fields (§8):
> the Agent Skills standard and the Claude Code extensions diverge and keep evolving.

| Decision | Default | Reason |
|---|---|---|
| Location | `~/.claude/skills/<slug>/SKILL.md` (global) or `.claude/skills/` (project) | Automatic filesystem discovery; the project one wins on a name collision |
| Frontmatter fields | Only `name` + `description` | They are the only indispensable ones; everything else adds surface and, in some cases, permission friction |
| `allowed-tools` | **Do not use without demonstrated need** | Marked experimental in the standard; there is an open report that it is parsed but **not enforced**, and its presence requires user approval on first use. Do not rely on it as a security control |
| `disable-model-invocation` | **The correct choice for anything with side effects or user-owned timing** (`/deploy`, `/commit`, a refresh that rewrites criteria) | **Corrected 2026-08-13 against the official documentation**: this field does **not** merely stop auto-activation — with it, *"Description not in context, full skill loads when you invoke"*. So a manual-only skill costs **zero index**, and the old claim here that it "pays index cost without automatic benefit" was false and pushed the decision the wrong way. Its counterpart `user-invocable: false` (only the model invokes) **does** keep the description in context |
| Language | `description` in **English**, body in the working language | Routing is done over the description; English is the language of technical triggers |
| Body length | **Dictated by the content, not by a quota** | The body is not loaded until activation: going long costs no index. The real limit is **density** — every line pins a decision, a prohibition or a verification. A dense domain can ask for 400+ lines; a niche one, 80 |
| Auxiliary files | `references/`, `scripts/` next to the `SKILL.md` when the content doesn't fit | They are loaded on demand from the body, not in the index |

**Golden rule of the catalogue**: the `description` is paid on **every turn**; the body only
when the skill activates. Optimise the description for routing, the body for use.

## 3. Structure and conventions

- **Directory = slug = `name`**. Suffix `-standards` for domain-criteria skills.
- Do not put templates or reference files inside `~/.claude/skills/`: any
  directory with a `SKILL.md` gets registered and pollutes the index. Outside the tree.
- Body with the 8 canonical sections. Canonical template: **`SKILL-TEMPLATE.md` at the root of the
  catalogue repository** — the repo is the source of truth. It is deliberately **not** installed by
  `install.sh`, so any copy sitting in `~/.claude/` is a stale orphan: do not read it.
- **Explicit boundary in §1** — the line `**Not applicable**: see <skill-x> (what it decides),
  <skill-y> (what it decides)` — written on **both sides** of every pair that could compete. State
  *what each one decides*, not what topic it covers: topics overlap, decisions do not. Without this,
  two neighbouring skills tread on each other and routing becomes chance.
- Reference date on the first line of the body.

### `description` design (the most important part of the file)

- **No hard word limit.** The rule is *zero filler, zero overlap with siblings*:
  a long description is justified if every term is a distinct trigger (service
  names of a cloud, for instance); a short but conceptual one is worse than a long and
  concrete one. Trimming to a quota destroys legitimate triggers.
- Start with `Use when …` and enumerate **concrete artifacts**: extensions (`.tf`, `.rs`),
  files (`pyproject.toml`, `Chart.yaml`), binaries (`nft`, `cosign`), frameworks.
- **Forbidden** to describe by abstract concept: `for best practices and quality` fires
  nothing because it matches no token of a real task.
- **Mandatory collision test**: before adding a skill, compare its description with
  those of its family. If they share more than 2-3 trigger terms, either the
  triggers get narrowed or the skills get merged.

## 4. Quality and verification

**How a gate must be written, before the list of gates itself.** These are the two ways a gate stops
measuring what it claims to measure, and both produce a **false green** — which is worse than a red
build, because a red build gets fixed and a green one gets trusted:

- **Match the exact declared literal, never a substring of it.** A gate that greps `Not applicable`
  instead of `**Not applicable**:`, or the phrase `the web wins` anywhere in the file instead of the
  §8 closing sentence, passes files that do not conform. The document then says the gate enforces
  something it does not, and nobody finds out.
- **A gate loosened for a migration is retired the day the migration ends.** While it accepts two
  forms it **cannot distinguish a finished migration from a regression**. Loosening one is a decision
  with an expiry date attached, not a permanent convenience.
- Related: the *absence* of a gate is invisible. Any criterion the catalogue declares mandatory and
  no gate checks (a verification date, the existence of cited slugs) is enforced by discipline alone,
  which is to say not at all. And a figure a gate reports must count what is really paid.

Gates before calling a skill good:

1. **Valid frontmatter**: `grep -c '^name:'` and `name` == directory name.
2. **Description without filler**: there is no word quota (§3) — the gate is that **every term
   is a trigger**. If a description is long because it enumerates services or extensions,
   that's fine; if it is long because of conceptual prose, that prose gets trimmed, never the triggers.
3. **Declared boundary**: the `**Not applicable**` line exists and every skill it cites exists.
   Mechanical catalogue test — trigger-term overlap between pairs of the same family:
   ```bash
   python3 - <<'EOF'
   import re,glob,itertools
   STOP=set("""use when working with or and the a an for of to in on writing reviewing designing
   standards engineering apply any code project service services files file level staff principal via
   targeting provider security architecture work like from than rather that this these under over
   into out system state model mapping source config configuring extension trigger triggers editing
   options profiles new real also both per each all more most other their your you we they what how
   why between across within without running versus its it choosing instead backing debugging
   diagnosing server exit mode access block control design rules production pools volumes deciding
   belongs whole end one every
   are was were be been being has have had does did not must should can may will would
   cost data time whether before after first already inside where who which while until
   query queries schema metrics management operating managed self-hosted major-version upgrades
   decision decisions impact business core standard enterprise licence license tiers retention
   storage capacity sizing lifecycle versioning replication partition partitioning snapshot
   snapshots restore backup index indexes indexing key keys log logs engine engines platform
   pipeline api cli sql postgresql apache open public deep long late two them their
   human framework governance policy policies audit incident process vendor approval change
   content ownership owned severity customer contract lineage catalog metadata coverage
   analysis compression deduplication topology plan plans isolation limits store stored
   task success building against picking measuring judging reading writes fields field
   team teams people person individual role roles owner ownership adoption evidence practice
   review reviewing reviewer deciding choosing writing running applying setting measured
   report reporting metric metrics target targets threshold thresholds budget budgets
   organization organizational internal external corporate enterprise product delivery
   framework frameworks method methods model models standard standards guide guidance
   licence licensing cost costs price pricing plan planning scope quality risk risks
   documentation docs document documents page pages content contents
   standards. code. decision. it. all. network. own itself about someone nobody covers
   application app apps applications component components module modules package packages library
   libraries plugin plugins tool tools suite suites stack layer layers
   migration migrating migrate legacy modernization rewrite replacing replacement
   evaluating checking check checks validation verifying tracking managing manager
   configuration setup provisioning deployment deploying deployed environment environments
   runtime native custom dynamic static shared distributed hybrid remote offline online live
   support supported unsupported maintenance updates update refresh release releases freeze
   version versions edition editions
   test tests testing gate gates rule ruleset criteria constraint constraints
   error errors failure failures problem problems issue issues
   node nodes host hosts cluster clusters server servers instance instances machine machines
   disk memory cpu port ports path paths directory root
   user users group groups identity credential credentials token tokens secret secrets
   certificate certificates encryption signing rotation trust
   traffic route routes egress ingress exposure
   image images container containers registry
   agent agents automation automated scripts script scheduling
   event events session sessions channel channels protocol protocols format formats
   inventory assets asset record records tree naming named set sets lists list
   type types classes classification
   compliance regulation regulations iso iso/iec nist rfc
   availability recovery rollback hardening telemetry monitoring observability
   third-party saas proprietary vendor-managed training weights inference serving
   publishing shipping pinning feature features functions
   context switch split plus full quotas quota limit rates rate templates template
   latency slow breaks cannot never safe red blue green 2.0 3.0 1.0
   actually enough such several defining citing works hand read reading picking judging
   closure handover stakeholder stakeholders status lead leads operations declaring
   community cycle feed feeds knowledge relationship relationships analytics detection
   comparing specifying scoping reconciling moving securing responding defending
   build builds repository repo entry manual drift discovery
   class fixed backlog reports feedback performance technical
   low minimum captive count regex first-class whose owns skill umbrella estate
   sources programs devices device element parts media controller
   history durability evolution warranted rollout canary streaming
   findings guardrails admission workload infrastructure
   volume assessment indicator indicators triage triaging tier tiering fatigue
   bias calibrating rubric scoring validity budgeting injection output prompt
   idle exhaustion ephemeral endpoints keepalive
   connect extensions subscriptions software integration messages
   cooling power rack room feeds ups density thermal liquid physical
   boot secure attestation uefi fleet kernel driver
   per-class label handling agreement auditing semantic retain retire rehost replatform
   cognitive load topologies sense dora toil reduction slos
   automate desktop flows orphaned studio admin center cmdlets
   gateway upstream bootstrap proxy termination timeouts blocks prefix routed
   spectrum roaming standalone ghz controls poisoning sla idempotent retries
   non-deterministic article articles duties
   date expiry landscape functional local option private""".split())
   d={}
   for p in glob.glob("*/SKILL.md"):
       desc=re.search(r'^description:\s*(.+)$',open(p).read(),re.M).group(1)
       d[p.split('/')[0]]={w for w in re.findall(r'[A-Za-z0-9_.\-/*]{3,}',desc.lower()) if w not in STOP}
   for a,b in itertools.combinations(sorted(d),2):
       sh=d[a]&d[b]
       if len(sh)>=4: print(len(sh),a,'<->',b,':',', '.join(sorted(sh)))
   EOF
   ```
   A pair sharing ≥4 terms requires narrowing the triggers, or justifying the overlap as
   inherent. **Only artifact-level trigger terms count**: if what is shared are connectors or
   generic nouns, it is tokeniser noise — widen `STOP` instead of
   mutilating the description. Inherent overlaps already accepted in the catalogue:
   - the three clouds (`*.tf`, `terraform`, `iac`, `finops`), disambiguated by service name and
     by `provider aws|azurerm|google`;
   - the security family, which shares **standard names** (`nis2`, `dora`, `iso`, `gdpr`) and
     framework names (`att`): they are domain vocabulary, not a claim on the same work. What
     separates them is the `**Not applicable**` line, which must exist on **both** sides and state what
     each one decides;
   - the skills carrying European legal obligations (`accessibility`, `e-commerce`, `ai-governance`,
     `green-it`, `govtech-eidas`, `technical-hiring`), which share `act`, `directive`,
     `european`, `omnibus`, `decreto`: the same reason as the security family;
   - crypto (`cryptography-pki` ↔ `post-quantum-crypto` ↔ `vpn`) over `tls`, `1.3`, `ikev2`,
     `rfc 9370`: the algorithm is the vocabulary, the split is in each one's §1;
   - the game engines (`game-development` ↔ `xr`) over `unity`, `unreal`, `godot`;
   - the data orchestrators (`data-engineering` ↔ `mlops`) over `airflow`, `dagster`,
     `prefect` — explicitly declared inherent in the body of `mlops`;
   - `endpoint-security` ↔ `macos-fleet` over `escrow`/`mdm`/`macos`, which are **homonyms**
     (BitLocker versus FileVault) with the arbitration written into both §1s;
   - `ibm-i-rpg` ↔ `mainframe-zos-cobol` over `db2`, `ebcdic`, `packed`, `decimal`, `ibm`: it is
     vendor vocabulary, and **both expressly declare in their §1 that they are different
     platforms which people lump together** and that criteria are not extrapolated between them.
     The term overlap is precisely why that boundary is written.

   **Run of 2026-08-10 over 218 skills**: the original `STOP` produced **420 pairs** (a useless
   gate). Widened with ~220 generic terms → **41 pairs**, of which **8 were real
   overlaps** and were corrected by **narrowing the neighbour's `description`, never the body**:
   `onprem` ceded physical hardware, the BMC and the room to `server-hardware` and
   `datacenter-facilities` (this skill's third pruning, the usual pattern);
   `dns` ceded SPF/DKIM/DMARC/MTA-STS/TLS-RPT to `email-security`; `datacenter-fabric` kept
   the switch's PFC/ETS/DCBX configuration and released RDMA, while `high-speed-interconnect`
   released PFC deadlock and oversubscription; `abap-sap` ceded the S/4HANA conversion
   as a project to `erp-sap` (and that one released OData); `edge-computing` ceded RAUC/SWUpdate/Mender
   and TPM-based identity to `embedded-iot`; `os-provisioning` ceded `bootc-image-builder` and
   `rpm-ostree` to `rhel-fedora`; `game-development` ceded `matchmaking` to
   `gaming-infrastructure`. Final result: **35 pairs, none ≥8, all inherent.**
4. **A real functional test**: open a representative file of the domain and check that
   **that** skill fires and not a neighbour. A skill that never fires is worse than not
   having it: it pays index cost and contributes nothing.
5. **A non-activation test**: check that it does NOT fire on neighbouring domains' tasks.
6. **Security review** of the batch (`/security-review`): no embedded execution
   instructions, no secrets, no paths or commands that should not be there.

## 5. Security

- A skill is **text that enters the context and steers behaviour**: treat it as
  privileged code. Review the diff of every third-party skill before installing it.
- **Unaudited third-party skills are forbidden**: a `SKILL.md` can contain
  exfiltration or covert-execution instructions. Authored in house or reviewed line
  by line.
- Do not embed secrets, tokens, sensitive internal paths or real example
  credentials — the content ends up in context and potentially in logs.
- `allowed-tools` **is not a security boundary** (see §2): do not use it to contain
  a skill you do not trust; the real containment is not installing it.
- Skills that invoke scripts (`scripts/`): the script runs with your permissions. Review it
  with the same criteria as any binary you execute.

## 6. Catalogue operability

- **Measure the index cost** periodically: sum the `description` of every skill
  and watch that it does not grow unchecked as more are added.
- **Symptom of a sick catalogue**: the right skill does not fire, or a neighbour does.
  The cause is almost always overlapping descriptions, not missing content.
- **Skills that never fire**: review quarterly and prune. Theoretical coverage that
  goes unused is maintenance debt.
- Catalogue changes (adding, renaming, deleting) take effect without a restart:
  discovery is by filesystem on every turn.

## 7. Sustainability

- **Cadence**: review skills carrying version data at least every 6 months; those in
  volatile ecosystems (AI, regulation) every 3. Each skill's §8 is what stops expired
  content being asserted as current.
- **A visible reference date** in the body: it turns an obsolete skill into a dated
  skill, which is recoverable.
- **Re-verification itself is governed by `update-standards`**: cadence, mechanical selection of
  the batch, literals that are not paraphrased, and the verification traps. Here it is only fixed
  that the date must exist; the refresh cycle is theirs.
- Renaming a skill breaks the boundary lines that cite it: search for references in **the repo,
  which is the source of truth** (`grep -rl '<old-slug>' skills/`), never in `~/.claude/skills/`,
  which is a destination.

**FORBIDDEN**
- ❌ A description by abstract concept with no concrete artifacts.
- ❌ Descriptions with filler, or that duplicate a neighbouring skill's triggers.
- ❌ Trimming a description to a word quota, destroying legitimate triggers.
- ❌ A skill with no `**Not applicable**` boundary line when it has neighbours in its family.
- ❌ Putting cross-cutting doctrine into a skill: that belongs in `CLAUDE.md`.
- ❌ Putting a specific domain's criteria into `CLAUDE.md`: that belongs in a skill.
- ❌ Templates, drafts or auxiliary files inside `~/.claude/skills/`.
- ❌ Installing third-party skills without auditing them line by line.
- ❌ Trusting `allowed-tools` as a security control.
- ❌ Tutorial and filler: a skill fixes criteria, it does not teach programming.
- ❌ Pinning versions or EOL dates from memory without the verification in §8.

## 8. Mandatory web verification

Before pinning any field, behaviour or limit of the skills system:

1. **The canonical frontmatter reference**: `code.claude.com/docs/en/skills` — which fields
   exist today, which belong to the Agent Skills standard and which are a Claude Code extension.
2. **The status of `allowed-tools`**: still marked experimental and with open enforcement
   issues; confirm before recommending it for anything.
3. **CLI versus SDK differences**: there are fields supported only in the Claude Code CLI that do
   not apply through the SDK.
4. **Harness behaviour changes** (discovery, project/global precedence,
   permission approval on first use) in the Claude Code changelog.

If the web contradicts this document, **the web wins** — flag the discrepancy.
