---
name: load-expertise
description: Derive and invoke the skills a task actually activates, before writing anything. Use at the start of every substantial task, and again whenever the work turns - the files being touched change family, a new layer enters (data, network, identity, money, personal data), the request moves from designing to operating, or you catch yourself asserting a version, flag, threshold or default from memory instead of from a document. Covers deriving the domains from the artefacts in the repo rather than from the words in the request, the always-on set that no request ever names, invoking each skill with the Skill tool rather than reading its file, reconciling several co-activated skills through their §1 boundary lines, declaring a contradiction instead of silently resolving it, and what to do when no skill owns the domain.
---

# Load expertise — arming before writing

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **The problem it solves.** The catalogue only pays off if the right skills are loaded *before* the
> first line is written. The information is never missing — every skill's `description` is injected
> on every turn — so the failure is not lookup, it is **derivation**: deciding, from the actual
> change, which domains it touches. Skipped, the answer degrades to generic quality and nothing in
> the output says so.
>
> **The risk it introduces.** Arming is not free: bodies cost context. A skill loaded to look
> thorough is the same waste as a skill skipped, minus the defect. **Load what the change touches,
> and say which.**

## 1. Scope and triggers

**This skill is step ② of the start-of-work routine in `CLAUDE.md`. It fires automatically.**

- **Before the first substantial change** — anything beyond answering a question about a file
  already open. Run the derivation (§3), announce the result in one line, then write.
- **On every turn of the work** — and these are the concrete triggers, not a feeling:
  - the files being touched change **family** (a `.py` task that starts editing `.tf` or a Dockerfile);
  - a **new layer** enters: data, network, identity, money, personal data, cryptography;
  - the request moves from **designing to operating** (build it → run it, deploy it, debug it live);
  - you catch yourself **asserting a version, flag, threshold or default from memory**. That is not a
    memory lapse, it is an unloaded skill announcing itself.
- **After any interruption or correction from the user**: the set that was armed answered the
  previous question, not this one.

What this skill does **not** do: it cannot invoke another skill on your behalf. There is no
mechanism for that — a skill activates because its own description matched, because the user typed
`/name`, or because **you call the `Skill` tool with its name**. This is the procedure that decides
*which*, and it is worthless unless the invocation actually happens in the same turn.

**Invoking is not reading, and the difference is not cosmetic.** `Read` on a `SKILL.md` puts the
same characters in context, and that is where the equivalence ends. What `Read` returns is file
content — material to weigh — while an invoked skill enters as the instructions the turn runs under;
and only the invocation appears in the transcript as an invocation, which is what lets the user
catch a wrong arming (§6). **`Read` is how you inspect a skill you are editing. The `Skill` tool is
how you arm one.**

**Not applicable**: see `project-map` (step ①, where things live in *this* repo — it answers
*where*, this one answers *under what criteria*), `claude-code-skills-standards` (authoring, naming
and judging a skill, and the trigger-collision gate — this one **consumes** the catalogue, that one
**builds** it), `update-standards` (re-verifying a skill's content against the web and its
`Criteria verified as of` date), `lean-code-standards` (how much code the answer should be, once
armed), `knowledge-management-standards` (documentation for humans).

## 2. Default decisions

| Decision | Default | Why |
|---|---|---|
| How many skills | **However many the change touches — almost never one** | A real task crosses domains; picking the single best match is the commonest arming failure |
| When | **Before writing**, never after | A skill consulted to justify what you already wrote is decoration |
| **How to load one** | **The `Skill` tool**, never `Read` on its `SKILL.md` | `Read` returns the file as content and leaves nothing in the transcript the user can correct; invoking enters it as the turn's instructions. `Read` on a `SKILL.md` means you are editing that skill, not using it |
| How much of each | **The whole body — the tool has no partial mode** | Loading §1+§2 alone is not something `Skill` can do, and asking for it silently forces `Read`. A neighbour not worth a whole body is one you route around from its `description`, not one you peek at |
| Routing source | **The injected `description` lines already in context** | They are the index, and they are free — they are paid for on every turn whether used or not |
| Repo index (`skills/PROJECTMAP.md`) | **Only inside the config repo** | `install.sh` excludes it (`--exclude=PROJECTMAP.md`): it is repo navigation, not installed product. In any other session it does not exist |
| Announcing | **One line naming them**, at the start and at every re-arm | Naming is what makes an omission visible — to you and to the user |
| No owning skill | **Say so explicitly**, then verify on the web and fall back to `lean-code-standards` | A declared gap is recoverable; silent improvisation is exactly what the catalogue exists to prevent |
| Contradiction between two | **Declare it**, resolve with their §1 boundary lines | Silently picking one hides that the catalogue has a routing defect |

## 3. The derivation — from artefacts, not from the words

**The request describes the goal; the repository decides the domains.** "Add an endpoint" names one
task and activates five. Run these five passes in order — they are cheap, and each one asks a
different question:

1. **Substrate** — what language and runtime is actually being edited. From the extensions and
   manifests in the diff, not from what the repo is "about": `.py`/`pyproject.toml`, `.go`/`go.mod`,
   `.ts`/`package.json`, `.sh`, `.tf`, `.sql`.
2. **Habitat** — where the thing runs: Kubernetes manifests, a Dockerfile or Compose file, a cloud
   provider's SDK or IaC, a systemd unit, a CI workflow. The code skill does not cover the platform
   it lands on.
3. **Layer** — what the change moves. Data, network, identity and access, money, personal data,
   cryptography, UI. Each one has an owner in the catalogue and none of them is implied by the
   language.
4. **Blast radius** — what breaks if this is wrong: an exploitable defect, a privacy violation, an
   SLO, a compliance obligation, a bill. Answer it literally; the answer names a skill.
5. **Craft** — how the change ships: tests, review, refactoring, performance. These apply to the
   *act* of changing code, independently of what the code does.

### 3.1 The always-on set — nothing in the request ever names these

- **`lean-code-standards`** on any code in any language. It has no artefact of its own, so skipping
  it is invisible and stays invisible.
- **`project-map`** at the start of work in any repository, and again whenever your change moves,
  creates or renames something the map names.
- **`git-workflow-standards`** whenever history itself is the deliverable: commit granularity and
  message, branching, tags, releases.
- **`session-tooling-standards`** the moment you write a script instead of running a command.

### 3.2 Reconciling several at once

- **Each skill's §1 closes with a `**Not applicable**: see X` line. That line is the routing table** —
  it states what the skill deliberately does not own and who does. Follow it before assuming overlap.
- Co-activated skills are **reconciled, not chosen between**. Two skills covering different faces of
  one change both apply in full.
- **If two genuinely contradict on the same decision, say so out loud** and resolve it with their own
  boundary lines. If the boundary lines do not resolve it, the catalogue has a defect: report it
  rather than arbitrating in silence.
- **A skill beats this file and `CLAUDE.md` on a technical detail; the web beats the skill** (every
  §8 says so). Recency is the tiebreaker, not specificity alone.

## 4. Verifying the arming, before trusting it

The arming is a step with a failure mode, so it gets checked like any other:

- **Name the file families in the diff.** For each one, name the skill loaded for it. A family with
  no skill named is either a declared gap or a miss — decide which, out loud.
- **Answer "what breaks if this is wrong" in one sentence.** If the sentence contains *leak*,
  *unauthorised*, *personal data*, *outage*, *money* or *audit* and no skill from that family is
  loaded, the arming is wrong and the answer is not ready.
- **Watch for memory-shaped assertions.** A version number, a default port, a flag, a threshold or an
  EOL date produced without a document or a lookup behind it is the reliable symptom of a missing
  skill. Stop, arm, redo the claim.
- **Re-arm is a gate, not a courtesy.** When a §1 trigger fires mid-task, the announcement happens
  before the next edit, not in the summary at the end.
- **Every skill you name in the announcement has a matching `Skill` call in the same turn.** A named
  skill with no invocation behind it is a claim, and it is the one arming failure that reads exactly
  like success.

## 5. Security is assumed, never derived

The security family is the one arming miss that ships an exploitable defect rather than an ugly one,
so it does not wait to be implied by the request:

- Any change that accepts **input**, crosses a **trust boundary**, touches **authn/authz**,
  **secrets**, **cryptography** or **personal data** pulls in its owning skill — `appsec-standards`,
  `identity-access-management-standards`, `secrets-management-standards`,
  `cryptography-pki-standards`, `privacy-engineering-standards` — whether or not the request mentions
  security at all. Nobody writes "and make it secure".
- **Personal data is a second, independent activation**, not a flavour of security: a perfectly
  secure system can still be an unlawful one.
- **An exposed secret is reported the moment it is seen**, before the arming is even finished. It
  does not wait for the turn to end.

## 6. Cost and operability

- **The index is prepaid**: every description is injected every turn regardless. Reading them is
  free; only the bodies cost.
- **Bodies are the budget, and they come whole.** Two or three invoked bodies is the normal shape of
  a well-armed task. There is no half-body option, so a skill you are not willing to spend a whole
  body on is one you route around from its `description`. Ten bodies invoked speculatively is not
  thoroughness — it is context spent on documents that will not decide anything.
- **Load late for the far domains.** Arm the ones that shape the design now; invoke a skill for a
  sub-decision when that sub-decision arrives.
- **The announcement is the operability surface, and the invocations are its evidence.** One line
  naming them, plus a `Skill` call per name in the same turn, is what lets the user correct the
  routing before the work is done rather than after.

## 7. Prohibitions

- ❌ **Writing before arming.** Loading a skill afterwards to justify what already exists is
  decoration, and it reliably confirms rather than corrects.
- ❌ **`Read`-ing a `SKILL.md` in order to use it.** Same characters, different status, and nothing
  in the transcript for the user to catch. `Read` is for the skill you are editing.
- ❌ **Picking the single best match** when the change crosses domains. One skill is the answer
  roughly never.
- ❌ **Silently resolving a contradiction** between two co-activated skills. Declare it.
- ❌ **Claiming a skill was applied without having invoked it.** The description is a trigger, not
  content.
- ❌ **Skipping the announcement.** An unnamed skill set cannot be corrected by the user and cannot
  be audited by you.
- ❌ **Treating "I do not know a skill for this" as an excuse.** The descriptions are in context on
  every turn; not checking them is the defect, not the absence.
- ❌ **Invoking bodies speculatively** to look thorough. Context spent is context unavailable for the
  work.
- ❌ **Carrying interaction 5's skill set into interaction 60.** The set expires when the work turns.
- ❌ **Deciding a domain question from memory** once a skill for it exists — that is the exact case
  the catalogue was built to remove.

## 8. Mandatory web verification

1. **Against the catalogue, always**: the skill you are about to cite exists, its `name` matches its
   directory, and its §1 does not disclaim the very thing you are using it for.
2. **Against the skill's own date**: a body opening with a stale `Criteria verified as of` line is a
   candidate for `update-standards`, not a source to quote as current.
3. **Against the web**, for anything the skill states as a moving fact — versions, EOLs, flags, CVEs,
   prices, product names. The skill is dated; the web is not.
4. **Against Claude Code's own documentation**, for how skills are discovered and invoked: whether
   descriptions are still the only injected field, what the `Skill` tool loads and whether it has
   gained any partial mode, and what `disable-model-invocation` does to that. That mechanism is the
   premise of this whole file, and it is a product that changes.

If the web contradicts this document, **the web wins** — flag the discrepancy.
