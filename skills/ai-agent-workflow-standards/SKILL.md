---
name: ai-agent-workflow-standards
description: Use when an engineering team works with coding agents day to day — deciding which task to hand to an agent and which to write by hand, AGENTS.md, CLAUDE.md, .cursorrules and .github/copilot-instructions.md repository instruction files, agent permission allowlists and settings.json approval rules, filesystem scope and which credentials the agent process can read, sandboxing a coding agent on a workstation, running an agent in CI (claude-code-action, GitHub Agentic Workflows, Copilot coding agent) and scoping its token and OIDC identity, indirect prompt injection through issues, PR comments, fetched web pages, dependency READMEs and tool output, reviewing a large plausible agent-authored diff, who is accountable for a merged agent-written change, disclosure and trailer conventions for AI-generated commits, copyright and licensing of generated code, or citing productivity evidence (METR RCT, DORA report) in a rollout decision.
---

# Standards for teamwork with coding agents

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **how an engineering team works with coding agents**: which task is given
to an agent and which is not, what context it needs from the repository, what permissions it has, what happens
to the result before it is merged, who is accountable for it and what is disclosed.

Guiding principle: **the agent does not remove work, it moves it somewhere else.** It moves effort from
*writing* to *specifying and verifying*. The net gain exists **only if verifying is
cheaper than writing**; when it is not, the agent produces volume that someone has to
audit, and the balance turns negative without anyone noticing, because the displaced work
—review— is not measured and the saved work —typing— is perceived. **That perception bias
has been measured (§6.1) and is the reason this document sets rules instead of recommendations.**

Triggers: `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`;
agent permission `settings.json`, allowed-command lists, approval of irreversible
actions; the agent's filesystem scope; credentials readable by the agent
process; agent in CI (`claude-code-action`, GitHub Agentic Workflows, Copilot coding
agent); indirect prompt injection from issues, PR comments, web pages,
dependencies or tool output; a large diff written by an agent; co-authorship *trailer*
in the commit; licence and authorship of generated code; productivity evidence.

### The triple boundary — read before routing

| Question | Owner |
|---|---|
| How is an agentic system **built**? Loop, tool surface, memory, subagents, iteration budget, sandbox of the agent *you* deploy, evaluation and cost per task | **`ai-agents-standards`** |
| How is a Claude Code skill **written and organised**? `SKILL.md`, frontmatter, `description` design, activation, catalogue | **`claude-code-skills-standards`** |
| How does **an engineering team work** with a third-party coding agent? Which task it is given, what context and what permissions, how what it produces is reviewed, who is accountable, what is disclosed | **This skill** |

Said in all three directions from this side, without ambiguity:

- **If you write the loop, it is `ai-agents-standards`. If you consume someone else's loop, it belongs here.**
  Designing the tool the agent invokes and when it stops: theirs. Deciding whether your team lets
  an agent touch the billing repository: here.
- **If the artifact you produce is a `SKILL.md`, it is `claude-code-skills-standards`.** Here the
  artifact is the repository's **`AGENTS.md`/`CLAUDE.md`** — a project convention for
  any agent, not a catalogue skill. If in doubt: does the file live in the product
  repository and is it read by any agent? Here. Does it live in `~/.claude/skills/` or `.claude/skills/`
  and define reusable domain criteria? Theirs.
- **If the question is "how do I make the agent do X better?", it is almost always one of the other
  two. Here the question is "should the agent do X, with what permissions, and who signs off?"**

**Not applicable**: see
`ai-agents-standards` and `claude-code-skills-standards` (table above);
`mcp-standards` (**the protocol**: primitives, transports, authorisation and design/security of
an MCP server. Here only the workflow consequence: **every connected MCP server widens the
agent's untrusted-read and action surface** (§5), and therefore enters the inventory and the team's
approval);
`llm-app-engineering-standards` (the deterministic LLM app: versioned prompting, structured
output, model routing, cost per call — **building a product with an LLM, not working
with an agent**);
`llm-evaluation-standards` (**evaluation methodology**: datasets, LLM-as-judge, measuring the
quality of an AI system. Here no model is evaluated: a workflow is decided);
`mlsecops-standards` (**the security of the AI system as a product is theirs**: model,
model supply chain, attacks on inference, defence of the service you deploy.
**Here the operational risk of the workflow**: what can happen to *your repository and your
credentials* because an agent read something hostile. If the question is "how do I protect the AI
system I serve", it is theirs; if it is "how do I stop the agent I use from stealing my CI token", here);
`ai-governance-standards` (**the governance and regulatory compliance of AI use in the
organisation are theirs**: AI system inventory, classification under the AI Act, corporate
acceptable-use policy, impact assessment, vendor due diligence, ISO/IEC
42001. **Here the engineering practice**: the rule the team applies inside the repository.
If the answer is signed off by the risk committee or the DPO, it is theirs; if it is enforced by `CODEOWNERS`, here);
`code-review-standards` (**already written, and it has its own section on reviewing AI-generated
code — it is not duplicated**: what is looked at in a diff, in what order, what blocks, how
the comment is labelled, who signs off a high-risk change. **It cedes the review criteria**; here only
**which task is delegated, with what permissions, and what peculiarity of an agent diff
must be anticipated before it reaches review** (§4) is retained);
`testing-qa-standards` (**already written**: what is tested, in what proportion and what breaks the build.
Here only the use of the test **as a delegation criterion**: without cheap verification, nothing is delegated);
`git-workflow-standards` (branch, commit, PR size, `CODEOWNERS`, branch protection; **the
co-authorship *trailer* and the commit convention are theirs**, here only the requirement that
one exists);
`cicd-standards` (**the pipeline is theirs**: jobs, runners, OIDC, *required checks*. Here **which
identity and which permissions an agent running inside that pipeline has**, §5.4);
`secrets-management-standards` (custody, rotation and vault; here **which secrets the
agent process can reach**, which is a workflow question, not a management one);
`developer-workstation-standards` (**hardening the machine where
the agent runs is theirs** — operating system sandbox, development container, user
permissions, disk encryption. Here only the requirement: *that isolation exists*, not how it is
implemented);
`appsec-standards` (STRIDE and the classic vulnerability classes; **prompt injection is not
one of them and is not mitigated with the same techniques** — §5.2);
`grc-compliance-standards` (audit evidence and segregation of duties),
`tech-leadership-standards` (organisational adoption, budget,
build-vs-buy and the effect on the team's careers; here the technical rule),
`i18n-standards` (**fine boundary**: LLM machine translation appears in both. **The
workflow with the model belongs here** — what it is asked to do, what permissions, how it is reviewed. **The
linguistic quality criteria and where an unreviewed translation is unacceptable are theirs**).

## 2. Default decisions

> Verify the state of tools, security advisories and cited studies on the web before
> committing to anything (§8). This domain moves faster than the ability to verify it.

| Decision | Default | Justifiable alternative |
|---|---|---|
| Delegation criteria | **The three filters of §3.1** (reversibility, scope, cost of verification). If one fails, nothing is delegated | — |
| Version control | **Mandatory and prior.** An agent only works on a clean, versioned tree | None |
| Execution isolation | **Container or disposable *worktree*** for tasks that execute commands | Direct execution on the machine only with an allowed-command list and no write credentials |
| Filesystem scope | **The working repository and nothing else**; never `$HOME`, never another repository | An explicit temporary data directory |
| Credentials visible to the process | **None with write access, none from production** (§5.3) | A read-only, short-lived token scoped to a single repository |
| Irreversible actions | **Explicit human approval per action**: `push --force`, deletion, migration, deployment, package publication, permission change, spend | None that batch-auto-approves them |
| Repository context | **`AGENTS.md` at the root**, versioned and reviewed as code (§3.3) | Vendor format if the team's toolchain is a single one |
| Authority of conventions | **What is not written in the repository does not exist** (§3.3) | — |
| Review | **Human and mandatory before merging. No exception for size or for "it's trivial"** | — |
| Accountability | **Whoever submits the change is accountable**, whether they wrote it or not (§4.3) | None |
| Disclosure | **It is disclosed** that the change was generated with AI assistance, using the repo's convention | — |
| Agent in CI triggered by a public event | **Forbidden by default** (third-party issue, comment or PR); if enabled, all of §5.4 | Private repository with trusted actors and a minimal token |
| External content the agent reads | **Untrusted, always** (§5.2) | — |
| Adoption metric | **None individual.** Only aggregated and outcome-based (§6.3) | — |

## 3. What is delegated, what is not, and with what context

### 3.1 The three filters

They are applied **before** writing the prompt, and **it is enough for one to fail** not to delegate.

1. **Reversibility.** Is the result undone with a `git revert` and nothing else? If the effect leaves
   the repository —touching production, migrating data, publishing an artifact, sending email, spending
   money, changing permissions, rotating a key— **execution is not delegated**. At most
   **the proposal** is delegated: the agent writes the script or the plan and a person runs it.
2. **Scope.** Does the change fit in a diff a reviewer understands in one sitting? An agent
   can produce in minutes a diff nobody will really review. If the task cannot be
   bounded to a reviewable change, **it is decomposed first**; delegating the decomposition is
   legitimate, delegating the execution of the undecomposed task is not.
3. **Cost of verification.** Is there a **cheap and objective** way to know whether the result is
   correct —a test that fails before and passes after, types, a checkable property, comparison with
   a known output— **before a person reads the code**? If the only possible verification
   is "read it all and reason about it", the agent **does not save work: it displaces it to
   review**, which is the team's scarcest and worst-measured resource.

**Operational corollary**: the best delegation candidate is a **bounded, reversible task with
a cheap oracle**. The worst is a **large task, with an external effect and no way of checking it
other than reading it**. Between the two extremes, filter 3 decides.

### 3.2 Decision table

| Task | Delegate | Reason |
|---|---|---|
| Reproduce a bug with a failing test | **Yes, first** | Perfect oracle, reversible, bounded |
| Fix a bug **with the regression test already written** | Yes | Cheap and objective verification |
| Mechanical refactor with a green test and real coverage | Yes | Reversible; the test is the oracle |
| Repetitive API migration across many files | Yes, **in reviewable batches** | Boundable; the large diff is split, not accepted whole |
| Scaffolding, boilerplate, initial configuration | Yes | Reversible and low risk |
| Writing tests for a module that already works | **With care** | Real risk: tests that mirror the implementation instead of the behaviour, and that always pass. Criteria in `testing-qa-standards` |
| Exploring and reading unfamiliar code | Yes | No effect; the result is understanding, which is verified when used |
| Architecture design, ADR | **Not as a decision**; yes as a generator of alternatives | The decision is signed off by a person who is accountable for it |
| Change to authentication, authorisation or cryptography | **No** | Extremely high cost of verification; silent and catastrophic failure |
| Data migration / destructive DDL | **Not the execution** | Irreversible (filter 1) |
| Anything against production | **No** | Filter 1, and §7 forbids it explicitly |
| Fixing an incident in progress | **Not on the critical path** | Verification costs more than writing it, under pressure and with no margin |
| Change to the code that governs the agent itself (CI workflow, `AGENTS.md`, permissions) | **Not without a second pair of eyes reviewing** | It is privilege escalation: §5.4 |

### 3.3 Context: the scarce resource

- **The instruction that is not written in the repository does not exist.** A convention that lives in
  someone's head, in a chat thread or in one person's prompt **does not apply to anyone
  else's work**. If a rule matters, it is written in the repository and reviewed as code.
- **One instruction file at the root** (`AGENTS.md` is the converging convention;
  vendor-specific files are functional equivalents). Content rules:
  - **Only what the agent cannot deduce from the repository.** Repeating the obvious —"use
    TypeScript", "there are tests"— burns context without adding anything. What adds value is the **non-obvious**:
    the exact build and test command, the convention that contradicts the ecosystem's
    default, the forbidden directory, the reason something is the way it is.
  - **Imperative and falsifiable**, not aspirational. "Run `make test` before finishing" works;
    "write quality code" does not.
  - **Versioned, reviewed and with an owner.** An out-of-date `AGENTS.md` does active harm: the
    agent follows an instruction that is already false and produces a plausible, wrong change.
  - **Hierarchical in a monorepo**: one file per package, the nearest one wins.
  - **FORBIDDEN** to put secrets, sensitive internal URLs or personal data in it: it is a file that
    is sent to the model provider on every task.
- **Context is a budget, not a warehouse.** An instruction file that grows without
  pruning displaces the code the agent needs to read. It is reviewed and trimmed periodically.
- **Evidence on this — a single study, and with its size stated**: *On the Impact of AGENTS.md Files
  on the Efficiency of AI Coding Agents* (arXiv 2601.20404, 28 Jan 2026; Lulla, Mohsenimofidi,
  Galster, Zhang, Baltes, Treude). Design, *verbatim*: «We analyze 10 repositories and 124 pull
  requests, executing agents under two conditions: with and without an AGENTS.md file.»
  Result, *verbatim*: «the presence of AGENTS.md is associated with a lower median runtime
  (Δ 28.64%) and reduced output token consumption (Δ 16.58%), while maintaining a comparable
  task completion behavior.» **Read it for what it is**: 10 repositories, a *preprint*, efficiency
  metrics (time and tokens), **not result quality**. It does not support "AGENTS.md files
  improve the code"; it supports that they reduce time and tokens in that sample.

### 3.4 How the task is commissioned

- **Acceptance criteria before the prompt.** If you cannot write down how you will know it is right,
  it is not ready to be delegated (that is filter 3 in operational form).
- **One task, one change, one PR.** Commissioning three things at once produces a diff that mixes three
  risks and cannot be reverted in parts.
- **Plan before code on any non-trivial task**, and the plan gets read. Correcting a plan
  costs minutes; correcting an 800-line diff costs an afternoon.
- **Two failed attempts = stop and write it yourself.** Iterating on an agent that does not converge is the
  most common way to lose time without noticing, and it is exactly the mechanism by which the
  perception of speed decouples from the clock (§6.1).

## 4. Reviewing the result

**The review criteria are set by `code-review-standards`, which already has its own section on
reviewing AI-generated code. Here only what is specific to this workflow, which must be
anticipated before the diff reaches review.**

### 4.1 The plausible, large diff

- **The characteristic risk of agent code is not that it looks bad: it is that it looks fine.**
  Coherent style, reasonable names, conventional structure. Review by "smell" —the
  heuristic an experienced reviewer uses to decide where to look— **does not fire**, because the
  code does not smell. You have to look where it does not smell.
- **Size is bounded at the source, not at review.** A diff limit that applies to the human and
  not to the agent is not a limit. If the agent produces more than is reviewable, **it is rejected and
  the task is split**; it is not reviewed "roughly".
- **Concrete disclosures to demand in the PR** (the submitter's obligation, not the reviewer's):
  what was asked for, what was verified and **how**, what was left out and which parts the author does not fully
  understand. That last one is the most useful and the one nobody writes voluntarily.

### 4.2 The trap: it compiles, passes the tests, and does not do what was asked

An agent optimises towards observable signals. Characteristic failures, in order of frequency:

- **Requirement met literally and wrongly**: it does exactly what the prompt says and
  not what was needed. Re-reading **the requirement**, not the diff, catches it.
- **Test adapted to the code instead of code to the test**: the test that was failing now passes because
  the test changed. **Always check that the regression test fails without the fix.**
- **Silenced edge case**: a broad `try/except`, a default value, a `?? 0` that turns
  an error into incorrect data that travels onward. The agent prefers the program not to fail.
- **Swallowed or generic error handling**, with no context and no propagation.
- **A new dependency** for something the codebase already solved, or **reimplementation** of
  something that already existed three directories away.
- **Overflowed scope**: unrequested "while I was at it" changes, mixed in with the real change.
- **Plausible things that do not exist**: an invented configuration option, flag or library
  function. It is caught by running, not by reading.
- **Injection artifacts** (§5.2): a new network call, an encoded blob, a change to a workflow
  file, to `.env` handling or to the dependency list. **Any of these in an
  agent diff is grounds for blocking and specific review, not a minor comment.**

### 4.3 Accountability

- **Whoever submits the change is accountable for it, whether they wrote it or not.** There is no category "the agent
  wrote it" that spreads the blame. If the change breaks production, the postmortem does not change
  shape because there is an agent in the story.
- **Hard corollary: if you do not understand it, you do not submit it.** There is no exception for urgency. A change
  nobody on the team understands is debt with interest and a future incident with nobody to
  diagnose it.
- The reviewer does not inherit the author's accountability: reviewing is not rewriting. A PR that requires
  the reviewer to reconstruct the intent **is sent back**.

## 5. Security and permissions

### 5.1 Threat model in one line

**The agent is a process that executes actions with your permissions and whose instructions may
come, in part, from someone who should not have them.** From that come the two controls: **bounding what
it can do** (§5.3) and **treating everything it reads as hostile** (§5.2). Neither of the two
works alone.

### 5.2 Indirect prompt injection — the vulnerability class specific to this workflow

- **Precise definition**: content the agent **reads as data** during its work, and which
  contains text written so the model interprets it as an **instruction**. There is no
  structural separation between data and instructions in an LLM's input, so the
  attacker needs access to nothing: **it is enough for their text to end up in the context**.
- **Real surfaces, all already exploited**: the body and comments of an *issue*, the title and
  description of a PR, commit messages, a dependency's `README` and *changelog*,
  comments in the code, test data files, fetched web pages, the output of a
  tool or an MCP server, and third-party API responses.
- **The difference from XSS or SQLi is one of mitigation**: there, there is a grammar and you can
  escape or parameterise. **Here there is not**: there is no `prepared statement` for natural language.
  Filtering, detecting patterns or asking the model to ignore instructions **reduces the rate, it does
  not close the class**. Any vendor claiming otherwise is checked before being believed.
- **That is why the effective control is about permissions, not content**: if the agent cannot read a
  secret nor reach the egress network nor write where it matters, the injection succeeds and
  **the damage is bounded**. That is the design; filtering is defence in depth.
- **Verified reference case** — `claude-code-action`, public disclosure on **1 Jun 2026**
  (GMO Flatt Security / RyotaK). *Verbatim* quotes from the report: the flaw allowed «an attacker
  to compromise any repository that uses the Claude Code workflow, including Anthropic's own
  repositories»; the root cause was that `checkWritePermissions` «unconditionally allows any GitHub
  App to pass, regardless of its actual permissions» due to an `if (actor.endsWith("[bot]"))` condition;
  and the real target was not the `GITHUB_TOKEN` but that «the most critical are
  `ACTIONS_ID_TOKEN_REQUEST_TOKEN` and `ACTIONS_ID_TOKEN_REQUEST_URL`» — that is, **theft of the
  OIDC token and supply chain compromise**. Fixed in `claude-code-action` v1.0.94.
  **Lessons retained, not the anecdote**:
  1. The full chain was **public issue → injection → environment variable exfiltration →
     write to the repository**. Every link was a permission granted for convenience.
  2. **The actor identifier is not an authorisation.** Trusting a name suffix is the
     same old mistake in new clothes.
  3. **The exfiltration channels are any output of the agent**: writing in the issue,
     passing a URL as an argument to a legitimate tool, or the public summary of the
     run itself. Bounding "the network" without bounding the tools is useless.
- **Team rule**: **an agent triggered by third-party content and with access to secrets is
  a vulnerability, not a configuration.** And no vendor "has fixed it": several of
  these exposures have been classified as an architectural limitation, not a one-off defect.

### 5.3 Permissions on the workstation

- **File scope**: the working repository. **Never `$HOME`**, never `~/.ssh`,
  `~/.aws`, `~/.kube`, `~/.config`, the password manager or another repository.
- **Credentials**: the agent process **does not see write or production credentials**.
  If the development environment exports variables with real tokens, the agent reads them: **the
  environment is cleaned first**, you do not trust that it will not use them. Custody and rotation belong to
  `secrets-management-standards`; the workflow requirement is this one.
- **Command execution**: explicit allowlist. **BLANKET AUTO-APPROVAL IS FORBIDDEN**
  (the "let it do whatever it wants" mode) outside a disposable container and without credentials. Any
  arbitrary outbound network execution is, on its own, an exfiltration channel.
- **Approval per irreversible action** (§2), not per session nor per batch: approving once "everything
  that comes" nullifies the control.
- **Isolation**: container or disposable *worktree*. **Hardening the machine belongs to
  `developer-workstation-standards`**; here the requirement that it exists and that the agent does not
  share identity with the person.
- **Version control before agent**: without a clean tree and a prior commit there is no way to
  know what changed or to undo it. It is the cheap condition that makes almost everything else reversible.

### 5.4 The agent in CI is an identity with permissions

- **It is one more principal**, and it is treated as such: its own identity, minimum permissions, ephemeral
  credentials (OIDC before a static key), auditing of what it does.
- **Never trigger an agent with secrets from an event a third party can originate** (issue,
  comment, fork PR) without: verification that the actor is human and has **real** write
  permission (not by name, §5.2), token permissions reduced to the minimum, and no
  secret in the environment beyond the strictly necessary.
- **No write permission over**: workflow files, the action's own configuration,
  protected branches, releases, package registry. That an agent can modify the workflow that
  runs it is **privilege escalation by design**.
- **An agent in CI does not approve PRs, does not merge and does not publish.** It proposes; a person signs off.
- **Pin the action version by digest**, not by a moving tag, and follow its security
  advisories: in this ecosystem patches arrive by incident, not by calendar.
- **Log**: what it ran, what it read and what it wrote. Without a trace there is no incident response.

## 6. Evidence, measurement and cost

> *Replaces «Performance and operability» from the template: in a process domain what is
> operated and measured is the team's workflow, not a runtime.*

### 6.1 The real evidence on productivity

**Rule for this section: cite what has a published methodology, with its n and its design, and
discard everything else by name.**

**1. The controlled trial with experienced developers — a result contrary to the
participants' perception.** *Measuring the Impact of Early-2025 AI on Experienced
Open-Source Developer Productivity* (METR, arXiv 2507.09089; published 10 Jul 2025). Design:
**16 developers** with an average of ~5 years of experience on their own mature repositories,
**246 real tasks** from their backlog, **randomisation per task** (allowed / not allowed to use
AI), paid at $150/h. Result: **tasks took 19 % longer** with AI allowed.
**The finding that matters is not the 19 %**: participants expected a 24 % improvement and,
**after doing it, still estimated a 20 % improvement**. The perception of speed and the
clock pointed in opposite directions. Limits that must be cited alongside the figure: small n,
early-2025 tooling, and a deliberately adverse scenario (an expert on code
they know inside out).

**2. The follow-up, and why it does not close the debate.** METR, *We are Changing our Developer
Productivity Experiment Design* (24 Feb 2026). *Verbatim* quotes: «Early 2025 study found the use
of AI causes tasks to take 19% longer, with a confidence interval between +2% and +39%»; «For the
subset of the original developers who participated in the later study, we now estimate a speedup
of -18% with a confidence interval between -38% and +9%»; «Among newly-recruited developers the
estimated speedup is -4%, with a confidence interval between -15% and +9%»; sample: «We have data
from 57 developers, across 143 repos, and 800+ tasks». And the reason **they themselves do not
consider it valid**: «The primary reason is that we have observed a significant increase in
developers choosing not to participate in the study because they do not wish to work without AI,
which likely biases downwards our estimate of AI-assisted speedup.» **Both intervals cross
zero.** Correct reading: there are signs of improvement relative to 2025, the magnitude is not
established, and **METR marks the original study as historical**. Anyone citing the "-18 %" as a
clean result is citing the source wrongly.

**3. The controlled trial in a company, with a result in the other direction.** *How much does AI impact
development speed? An enterprise-based randomized controlled trial* (Paradis et al., arXiv
2410.12944, Oct 2024; ICSE-SEIP 2025). Design: **96 full-time Google engineers**,
random assignment to treatment (autocomplete, *smart paste* and chat enabled) or control
(disabled), **one realistic enterprise task** (building a *logging* service, ~10
files and ~474 lines). Result: **~21 % faster** (96 min vs. 114 min on average),
**with a wide confidence interval** and p = .038.
**How it is reconciled with 1**: they do not contradict each other, they measure different situations. A bounded,
well-defined task with limited context → gain. A huge repository the developer already
masters → loss. **That is exactly filter 3 of §3.1, with data.**

**4. The reference industry report — and which is the current edition.** The flagship is
**«2025 State of AI-assisted Software Development»** by DORA (Google Cloud): ~5,000 professionals
surveyed, fieldwork from **13 Jun to 21 Jul 2025**, more than 100 hours of qualitative data;
it drops the performance clusters and proposes seven team archetypes; its central
thesis is that **AI amplifies existing organisational strengths and weaknesses**.
**Mandatory caution when citing it: its productivity measures are self-reported** — that is,
they measure exactly the variable that the trial in point 1 showed diverges from the clock. It is useful
for reading adoption, practices and organisational conditions; **it is not usable as proof of real
acceleration**.
*Declared discrepancy about the edition*: `dora.dev/research/publications/` lists, without a year,
«ROI of AI-assisted Software Development report», «DORA AI Capabilities Model report» and
«2025 State of AI-assisted Software Development report», and **shows no publication
dated 2026**; yet DORA itself versions the ROI report as **2026.1** and
press coverage places it in April-May 2026. **Conclusion: the current flagship report is
the 2025 one; the ROI one is a different document, more recent and prescriptive in nature (a calculation
framework and a J curve), not a new study.** Confusing them is the usual edition mistake.

**Explicitly discarded, and why**: the acceleration figures published by tool
vendors —percentages of "tasks completed faster", "lines accepted" or "X % of
productivity"— **circulate without methodology, without n, without a control group and without a definition of the
task**. They are not cited in a team decision, not put on a slide and not used to
justify a rollout. **If there is no published design, there is no data.** The same applies to
"percentage of code written by AI" metrics: they measure generation, not value, and are trivially
inflatable.

### 6.2 What you can actually measure in your team

- **Delivery flow metrics that already exist** (`sre-practice-standards`, `git-workflow-standards`):
  *lead time*, deployment frequency, **change failure rate** and **time to restore**.
  They are the only honest counterweight: if speed goes up and change failure does too, there is no
  gain, there is a cost transfer to production.
- **Review time and number of round trips per PR**, separating the change's origin. It is
  where the displaced work of §1 shows up.
- **Rework**: the proportion of changes reverted or corrected in the following days.
- **Cost**: spend per team and per task, with a ceiling. An agent with no spending limit is a
  billing incident waiting its turn.
- **Before rolling out the tool, the baseline is fixed.** Without prior measurement there is no possible
  comparison and the evaluation ends up being the perception of §6.1.

### 6.3 How NOT to measure

- ❌ **No individual metric.** Not lines generated, not acceptance rate, not PRs per
  person, not "percentage of AI use". Measuring adoption per person turns the tool
  into a target and corrupts the data on day one.
- ❌ Perception of speed as proof of speed (§6.1).
- ❌ Comparing teams against each other with these metrics.

## 7. Sustainability, team policy and prohibitions

### 7.1 Attribution and licensing of generated code

- **What is published and firm (USA)**: the Copyright Office published in
  **January 2025** *Copyright and Artificial Intelligence, Part 2: Copyrightability*. It holds
  that **human authorship is a requirement**, that **the prompt alone is not enough** with
  current technology to constitute authorship, that **using AI as an assistance tool does not
  harm** the protection of the resulting work, and that a mixed work can be protected **in the
  part with sufficient human authorship**, with AI-generated material having to be **disclaimed**
  when registering. The third part of the report, on training and liability, is a
  different document.
- **What is NOT resolved, and is stated as such**: the concrete application to **source code**
  (where the threshold of "sufficient human authorship" lies in an assisted diff), the effect on an
  open source project's **output licence**, and the situation in **other
  jurisdictions**, which is not uniform. **There is no firm, universal published position.**
  Any categorical claim that "AI code is public domain" or "it is yours without
  caveats" is false through excess of precision.
- **Rules that can be fixed today, without depending on that**:
  - **It is disclosed.** The commit or the PR states there was AI assistance, using the
    repository's convention (`git-workflow-standards` sets the *trailer* format).
  - **Long, recognisable fragments from a known project do not get in.** If the result
    looks copied from an identifiable source, its origin and licence are verified before
    merging. This is provenance, not style.
  - **The vendor's terms on ownership, indemnification and use of your code for
    training are read before adopting the tool** and reviewed at renewal. Vendor due
    diligence is governed by `ai-governance-standards`; here only the obligation
    that no tool is adopted without having read them.
  - In projects with a **CLA or a strict copyleft licence**, consult first: the authorship
    declaration the contributor signs may not fit a mostly generated
    change.

### 7.2 Team policy — what is disclosed, what is logged, what requires human review

It is written once, lives in the repository (or in the organisation's `AGENTS.md`) and is reviewed
on a cadence. Minimum content:

1. **Which tools are approved** and which are not, with their minimum version and their security
   advisories followed.
2. **What is disclosed**: every AI-assisted change, in the commit or in the PR.
3. **What is logged**: agent use in CI (what it ran, what it read, what it wrote), spend per
   team, and approvals of irreversible actions.
4. **What requires mandatory human review — without exception**: **everything**. And **reinforced review
   (a second specialist reviewer)** for: authentication and authorisation, cryptography, data
   migrations, infrastructure and permissions, payment or billing code, personal data
   processing, and **any change to the agent workflow itself** (workflow, `AGENTS.md`,
   permissions, allowed-command list).
5. **What is forbidden to delegate** (§3.2 and §7.3), in this team's concrete list.
6. **What is done in an incident caused by an agent change**: a normal blameless postmortem,
   with one added question — **which of the three filters of §3.1 failed**.
7. **Onboarding training**: someone who does not know how to review agent code should not submit
   agent code. The skill to teach is **verifying**, not *prompting*.

### 7.3 Prohibitions

- ❌ **FORBIDDEN to give an agent production credentials**, in any form: environment
  variable, configuration file, active cloud profile, open session or tunnel. There is no task
  that justifies it.
- ❌ **FORBIDDEN to run an agent on a tree without version control** or with uncommitted
  changes. Without a baseline there is no reversion and no diagnosis.
- ❌ **FORBIDDEN to merge a change nobody on the team understands.** Not for urgency, not because
  the tests pass, not because "it works".
- ❌ Merging without human review. An agent's approval **does not count as approval**.
- ❌ Blanket auto-approval of commands outside a disposable container and without credentials.
- ❌ Giving the agent access to `$HOME`, to SSH keys, to cloud credentials or to another repository.
- ❌ Triggering an agent with secrets from an event originated by a third party (§5.4).
- ❌ An agent having write permission over the workflow, the configuration or the permissions
  that govern it.
- ❌ An agent approving a PR, merging it, publishing a package, creating a release or deploying.
- ❌ Delegating the **execution** of an irreversible action (migration, deletion, deployment, spend).
- ❌ Delegating the fix on the critical path of an incident in progress.
- ❌ Accepting a diff because it compiles and passes the tests, without checking that it **does what was asked**
  and that the regression test **fails without the fix**.
- ❌ Treating the content the agent reads (issue, web, dependency, tool output)
  as trusted.
- ❌ Putting secrets, sensitive internal URLs or personal data in `AGENTS.md`/`CLAUDE.md`.
- ❌ Measuring people by their AI use, or publishing individual adoption metrics.
- ❌ Citing productivity figures **without a published methodology** —vendor or blog— to
  justify a team decision (§6.1).
- ❌ Using a CI agent action pinned by a **moving tag** instead of by digest.
- ❌ Adopting an agent tool without having read its terms on code ownership and
  use of your repository for training.

## 8. Mandatory web verification

Check **before committing to anything** in a real team:

1. **Productivity studies**: whether METR has published the redesign announced in Feb 2026 and with
   what result; whether there are new controlled trials with a published methodology. **Verified in
   this pass**: METR arXiv 2507.09089 (16 developers, 246 tasks, +19 % duration);
   METR 24 Feb 2026 (57 developers, 143 repos, 800+ tasks; **intervals that cross zero
   and a selection bias declared by the authors themselves**); Paradis et al. arXiv 2410.12944
   (96 Google engineers, ~21 % faster, wide CI, p = .038).
2. **Industry report**: **which is the current edition**. Verified: the flagship is
   «2025 State of AI-assisted Software Development» (DORA/Google Cloud, fieldwork Jun-Jul 2025,
   ~5,000 responses, **self-reported measures**); the «ROI of AI-assisted Software Development»
   is versioned **2026.1** and is a different, prescriptive document. **Discrepancy declared
   in §6.1**: DORA's publications page shows no publication dated 2026
   despite that version. Verify on `dora.dev` before citing an edition.
3. **Prompt injection in coding agents**: security advisories and patched versions
   of the specific tool you use. The `claude-code-action` case was verified
   (disclosure 1 Jun 2026, fixed in v1.0.94). **Check whether there are later advisories**: in
   this ecosystem the cadence is set by incidents.
4. **Guides and taxonomies**: the state of OWASP for LLM and agentic risks, and whether
   specific guidance has appeared for coding agents in the supply chain. **This point is
   verified, not recalled**: the identifiers and names of those lists have changed
   between editions.
5. **Authorship and licensing**: whether there is anything new after *Copyright and Artificial Intelligence, Part 2*
   (Jan 2025) and, above all, **whether a firm position applicable to source code** or to the
   European scope exists. **As of Aug 2026 none has been located**: §7.1 declares it unresolved
   instead of filling it in.
6. **`AGENTS.md`**: the state of the specification and its governance, and which tools really
   support it. *Calibration note*: the adoption figures that circulate (tens of thousands of
   repositories) **come from promotional material and vary between sources by more than 50 %**;
   they are not used here as data.
7. **The specific tool**: version, current permission model, what it does by default and what
   telemetry it sends. **Permission defaults change between minor versions**: read them on
   every update, not once.
8. **Declared gaps (no verification budget in this pass)**:
   - No study with a published methodology has been located on **the effect of agent-generated
     code on review load or review effectiveness** —which is precisely the central variable
     of §1—. **No number is invented**: the claim in §1 is a mechanism argument,
     not an empirical result, and it is written as such.
   - The status and permission model of the alternatives has not been verified
     (Copilot coding agent, Cursor, Devin, Windsurf, Codex, Gemini CLI, Aider): §5 sets the
     permission criteria that **any** of them must meet; the detail of each one is
     verified in its documentation before approving it.
   - The studies questioning LLM-generated `AGENTS.md` files (reduced success rate)
     appear in 2026 *preprints* that **have not been read at source** in this pass; §3.3
     only cites the one that was verified verbatim. Before claiming otherwise, read them.

If the web contradicts this document, **the web wins** — flag the discrepancy.
