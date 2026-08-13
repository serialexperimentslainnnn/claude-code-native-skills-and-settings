---
name: code-review-standards
description: Code review as an explicit quality control, not an opinion about someone else's style. Use when reviewing or authoring a pull/merge request diff, writing a PR description or review checklist, deciding what blocks a merge versus what is a suggestion, labelling review comments (Conventional Comments, nit:, blocking:), setting review SLA and stale-PR policy, assigning reviewers or debugging a CODEOWNERS bottleneck, requiring a second or specialist reviewer for high-risk changes (data migrations, authn/authz, cryptography, concurrency, infrastructure), reviewing AI-generated or agent-authored diffs, arguing about formatting in a review, escalating a review disagreement to an ADR, choosing review metrics, or replacing async review with pair or mob programming.
---

# Code review standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **what is looked at inside a diff, in what order, what blocks, how the comment is written
and who has to sign off according to the risk of the change**: search order by value, blocking
criteria, comment label convention, required content of the PR description,
reviewer assignment and the `CODEOWNERS` bottleneck, review of high-risk changes,
review of AI-generated code, resolution of disagreements, automation before review
and process metrics.

Guiding principle: **review is a quality control with explicit criteria, not an opinion
about someone else's style.** A quality control has defined inputs (a small diff, green in
CI and with written context), falsifiable criteria (this blocks, this does not) and a binary output
(approved / changes requested with a reason). Anything that does not fit that — aesthetic preference,
demonstration of knowledge, power negotiation — **is not review**.

**Fine boundary with `git-workflow-standards`** (read from its §1 and its §3.4, which already claims PR
size, description, SLA, `CODEOWNERS` and branch protection). The split, with no ambiguity:

| Question | Owner |
|---|---|
| How do you branch, commit, *squash* and tag? What is the repo's **numeric limit** on diff size? Which paths require an *owner* and which rules protect `main`? What is the first-response SLA as a repository rule? | **`git-workflow-standards`** |
| What does the reviewer look for inside that diff and in what order? What constitutes grounds for blocking? How is the comment written? What does a high-risk change require? How do you review a diff an agent wrote? What do you do when there is disagreement? | **This skill** |
| Both fix a number on the same thing (PR size, SLA) | **`git-workflow-standards` wins**: it is the repository's mechanical rule. Here we provide the **evidence** of why that number exists and what happens to the effectiveness of review when it is exceeded (§3.4). If the two numbers diverge, the one in this skill is corrected. |

**Not applicable**: see `git-workflow-standards` (above), `cicd-standards` (**the pipeline and its gates
are theirs**: jobs, order, runners, *required checks*; here **what must be green before a
person looks at the diff** and with what threshold), `testing-qa-standards` (what is tested, in what proportion
and what breaks the build; here only **the test as an object of review** and the requirement for a regression
test), `appsec-standards` (**threat modelling and finding triage are theirs**; here human
review as a control and the diff's risk *checklist* — §5), `secrets-management-standards`
(secret management and rotation; here only detecting the secret that comes in through the diff),
`sre-practice-standards` (reliability, SLOs and *error budget*; **the progressive rollout of the reviewed
change is coordinated there**), `incident-management-standards` (blameless postmortem; here the rule
that the fix arrives with a regression test and review by a second pair of eyes),
`observability-standards` (what telemetry must exist; here requiring it in the diff that needs it),
`grc-compliance-standards` (segregation of duties and the audit evidence review
produces), `ai-agents-standards` (engineering the agent itself) and `ai-agent-workflow-standards`
(how a team works with coding agents; **here only the review of the
result**), `claude-code-skills-standards` (skill authoring), the language skills (what is
idiomatic in that language: the reviewer cites them, they do not reinvent them in the thread),
`tech-leadership-standards` (the criteria for what is reviewed and how it is commented belong here;
**that review does not become an instrument of power nor a single person's bottleneck is a
leadership responsibility and is theirs** — as is the decision not to use review metrics
to evaluate individuals), `refactoring-tech-debt-standards` (the criteria for what is refactored and how
debt is recorded are theirs; **here the consequence for review, which is not minor: a refactor and a functional
change are not reviewed the same way and do not go in the same commit**. A diff where the restructuring
hides a behaviour change is unreviewable, and that is reason enough to send it back).

## 2. Default decisions

> Verify the latest version and the status of the cited sources on the web before pinning anything (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| What review decides | Correctness, risk and maintainability | — |
| Who decides formatting | **The automatic formatter in CI**, never the reviewer | — |
| Approvals | **1** on an ordinary change; **2, one of them a specialist**, on high risk (§5) | 1 in single-owner repos with documented later asynchronous review |
| Comment labelling | **Conventional Comments** (`issue:`, `suggestion:`, `nitpick:`, `question:`, `praise:`, `note:`) with explicit `(blocking)` / `(non-blocking)` | A minimal in-house convention: `blocking:` / `nit:` prefix — but **written down and applied by everyone** |
| A comment's default | **Non-blocking** unless there is an explicit blocking label | — |
| PR description | Mandatory, with the four answers of §3.3 | — |
| Round-trip threshold | **3**; on the fourth, a synchronous conversation and a written summary in the PR | — |
| Unresolved disagreement | Escalated to a technical third party; if it is a design decision, an **ADR** and the PR is unblocked | — |
| High-risk review | **Mandatory specific reviewer** by domain (§5) | — |
| AI-generated code | **Same bar, more scepticism**; whoever submits it answers for it (§6) | — |
| Automatic reviewer (LLM) | **An adviser, never an approver**: its comments are hypotheses to be verified | — |
| Alternative to asynchronous review | **Pair/mob** on exploratory, high-risk or knowledge-transfer changes; it replaces review if the second pair of eyes was present **during** the writing and it is recorded | — |
| Metrics | Only aggregated and about the **process** (§4.3) | — |

## 3. What a review decides and what it does not

### 3.1 Style is not discussed in a review

- **Formatting is decided by the automatic formatter.** There is no negotiation, no preference and no
  comment: it runs in CI and it breaks the build. The specific tool is fixed by the
  language's skill.
- **If formatting is discussed in a review, a formatter is missing from CI.** Put plainly: every thread
  about quotes, indentation, import order or line length is a **repository configuration
  defect**, not a disagreement between people. The correct action is not to reply to the thread:
  it is to open the PR that adds the formatter and close the thread with the link.
- The same applies to anything a linter or a *type checker* can decide: if a rule is
  automatable and the team wants it, it is automated; if it is not automated, **it stops being
  enforceable in review**.

### 3.2 Search order, from highest to lowest value

You review in this order and you stop when the diff yields no more. A reviewer who starts at the end
of this list is spending their attention on the cheap stuff.

1. **Correctness and edge cases**: does it do what the description says? Null/empty values,
   collections of zero and of one, limits, overflow, units and time zones, decimal
   precision in money, idempotency on retry.
2. **Security**: unvalidated input reaching a *sink*, missing authorisation or authorisation evaluated on the
   client, a secret in the diff, a new dependency, deserialisation, dynamic construction of
   queries or commands. Classes and triage: `appsec-standards`.
3. **Broken contract**: an incompatible change in an API, schema, event or persisted format; and its
   consequence for already-deployed consumers.
4. **Concurrency and shared state**: an unprotected critical section, lock ordering,
   *check-then-act*, reentrancy, an assumption of running in a single process.
5. **Error and resource handling**: swallowed error, error without context, half-finished state after a
   failure, resource not released, missing *timeout* or limit.
6. **Observability**: can this be diagnosed in production at 3 a.m.? Structured
   log with correlation, a metric on the new path, and **no personal data and no secret in
   the log**.
7. **Tests**: do they test behaviour or implementation? Do they cover the edge the diff introduces?
   Is there a regression test if this is a *bugfix*? Criteria: `testing-qa-standards`.
8. **Maintainability**: names that reveal intent, size and responsibility of the unit,
   **essential** duplication (not accidental), new coupling, debt declared with a TODO + reason.

### 3.3 What NOT to look for

- ❌ Formatting, member ordering, quote or brace style (§3.1).
- ❌ Equivalent rewrites out of taste ("I'd have done it with `map`").
- ❌ Refactors outside the PR's scope. They are noted as `note:` or a ticket; **they do not block**.
- ❌ Architecture that was already decided: if the design was discussed beforehand, the time to object was
  beforehand. If the reviewer thinks the decision was bad, the vehicle is an ADR, not blocking the PR.
- ❌ Defects a tool ought to find: if the reviewer keeps finding them by hand
  repeatedly, the fix is to add the tool (§4.1).
- ❌ Rewriting the author's code in the thread unless asked: a suggestion is proposed,
  authorship is respected.

### 3.4 PR description: an entry requirement, not a courtesy

A PR without the four answers **is not ready for review** and is sent back without reading the diff:

1. **What changes** (in observable behaviour, not in files touched).
2. **Why** (the problem, the ticket, the discarded alternative).
3. **How it was tested** (what new test, what was verified by hand and in which environment).
4. **What risk it carries and how it is reverted** (migration, *feature flag*, *rollback* plan).

Honesty rule: if the answer to "how was it tested" is *"the assistant said it was
fine"*, the PR is not ready (§6). The title format and the PR mechanics belong to
`git-workflow-standards`.

### 3.5 Change size: the factor with the greatest impact, with the available evidence

It is the only variable with consistent published evidence. It is cited with the source, and with its caveats.

- **Cisco / SmartBear study** (*Code Review at Cisco Systems*, a chapter of *Best Kept Secrets
  of Peer Code Review*; 10 months, Jul-2005 to May-2006, Cisco Systems' MeetingPlace group,
  **2,500 reviews of 3.2 million lines written by 50 developers**). Verbatim:
  - *"Reviewers are most effective at reviewing small amounts of code. Anything below 200 lines
    produces a relatively high rate of defects, often several times the average. After that the
    results trail off considerably; no review larger than 250 lines produced more than 37 defects
    per 1000 lines of code"*.
  - *"Reviewers slower than 400 lines per hour were above average in their ability to uncover
    defects. But when faster than 450 lines/hour the defect density is below average in 87% of the
    cases."*
  - *"Total review time should be less than 60 minutes, not to exceed 90. Defect detection rates
    plummet after that time."*
  - *"the single best piece of advice we can give is to review between 100 and 300 lines of code at
    a time and spend 30-60 minutes to review it."*
  - **Caveats the study itself declares and that have to be cited with it**: it assumes a constant defect
    density — *"we're tacitly assuming that true defect density is constant over both
    large and small code changes"* —, so that "fewer defects per kLOC in large reviews"
    is interpreted as *less effectiveness*, not as *better code*. Add that **it was conducted by the
    vendor of the tool under review**: the direction of the effect is credible and consistent with
    practice, the exact values are not a universal.
- **Google's published practice** (*Google Engineering Practices*, the "Small CLs" guide), verbatim:
  *"100 lines is usually a reasonable size for a CL, and 1000 lines is usually too large"*;
  *"The number of files that a change is spread across also affects its 'size.' A 200-line change
  in one file might be okay, but spread across 50 files it would usually be too large"*; and the rule
  to copy as is: *"Reviewers have discretion to reject your change outright for the
  sole reason of it being too large"*.
- **Observational data** (Sadowski, Söderberg, Church, Sipko, Bacchelli, *Modern Code Review:
  A Case Study at Google*, **ICSE-SEIP 2018**, pp. 181-190, DOI 10.1145/3183519.3183525; log
  analysis of **9 million reviews**), verbatim: *"Over 10% of changes modify only a
  single line of code, and the median number of lines modified is 24"*; *"over 35% of the changes
  under consideration modify only a single file and about 90% modify fewer than 10 files"*;
  *"fewer than 25% of changes have more than one reviewer, and over 99% have at most five reviewers
  with a median reviewer count of 1"*; *"the average number of comments per change grows with the
  number of lines changed, reaching a peak of 12.5 comments per change for changes of about 1250
  lines"*.

**The operational criterion that follows**: the reviewer **rejects on size without reading** when the diff
exceeds the repository's limit (fixed by `git-workflow-standards`) with no declared justification;
a review session does not go beyond ~60 minutes; and a diff that does not fit in a session is split, it is not
"skimmed". **Declared exception**: mechanical changes (generated code, mass renaming,
*lockfiles*) are separated **into their own PR** and reviewed by the command that produced them, not line by
line.

### 3.6 Response time and the cost of a stalled PR

- **A stalled PR is depreciating inventory**: it ages against `main`, blocks the author,
  causes context switching and grows when the author "takes the opportunity" to add something else.
- Published reference rule (*Google Engineering Practices*, "Speed of Code Reviews"),
  verbatim: *"One business day is the maximum time it should take to respond to a code review
  request (i.e., first thing the next morning)"*, and on the cost: *"The velocity of the team as a
  whole is decreased. Yes, the individual who doesn't respond quickly to the review gets other work
  done. However, new features and bug fixes for the rest of the team are delayed by days, weeks, or
  months as each CL waits for review and re-review."* The repository's specific SLA is fixed by
  `git-workflow-standards`.
- **Responding fast ≠ approving fast.** The metric is the time to the **first response**;
  a valid response can be "I can't today, pass it to X".
- **Explicit partial review**: if you have only reviewed a part, say so and approve only that part.
  Silence + a late LGTM is worse than "only reviewed the payments module".
- A PR open with no activity beyond the repo's deadline: it is closed or rescued; it is not left to pile up.

### 3.7 Reviewer assignment and the `CODEOWNERS` bottleneck

- `CODEOWNERS` protects the paths where a mistake is expensive (authentication, migrations, IaC,
  CI workflows, API contracts). The file and branch protection belong to
  `git-workflow-standards`; **here the human effect**.
- **The bottleneck is real and has to be managed, not denied**: if one person or one team
  appears on most PRs, the process is designed to stall whenever that person is
  busy, on holiday or leaves. Signals: PRs waiting for an *owner* beyond the SLA
  systematically; a single name approving most of an area's changes.
- Mitigations, in order: **at least two *owners* per path** and never a single person; explicit
  review rotation; widening the group through paired review (the *owner* reviews alongside
  whoever is being trained) until they can be added; and **narrowing the scope** of `CODEOWNERS` to what is
  really critical — the more it covers, the more gets approved without reading.
- **FORBIDDEN to use `CODEOWNERS` as territorial control**: ownership is of the quality of the
  code, not of the permission to touch it.

### 3.8 How a comment is written

- **A label is mandatory**, and blocking is explicit. With Conventional Comments, the format is
  `<label> [decorations]: <subject>` and the canonical definitions: `issue:` — *"Issues highlight
  specific problems with the subject under review"*; `suggestion:` — *"Suggestions propose
  improvements to the current subject. It's important to be explicit and clear on what is being
  suggested and why it is an improvement"*; `nitpick:` — *"Nitpicks are trivial preference-based
  requests. These should be non-blocking by nature"*; `question:` — *"Questions are appropriate if
  you have a potential concern but are not quite sure if it's relevant or not"*; `note:` —
  *"Notes are always non-blocking and simply highlight something the reader should take note of"*;
  `praise:` — *"Praises highlight something positive. Try to leave at least one of these comments
  per review"*. **A comment with no label reads as blocking and wastes everybody's
  time.**
- **You ask for the change with the reason, not with the preference.** Required format: *what* is wrong,
  *why* it matters (a defect, a risk, a concrete future cost) and *what* would resolve it. "I don't
  like this" and "I'd do it differently" **are not reasons** and block nothing.
- **You attack the code, not the person.** You write about the code in the third person ("this
  function leaves the connection open if it throws"), not about the author ("you leave the connection open").
  No sarcasm, no "obviously", no "again". The "why" is always explained: a comment
  with no reason is an order, and an order in a review is a power relationship, not a quality
  control.
- **A personal preference never blocks.** If it really matters, it becomes a team rule
  (a linter or a document) and then it does block — everyone, always, and without arguing in the thread.
- **The author replies to every thread**: accepts, rebuts with a reason or opens a ticket. Closing a thread
  without replying is equivalent to ignoring a finding.
- **Disagreement**: it is argued with data (behaviour, cost, risk). If it is still alive after one
  exchange, **immediate escalation** to an agreed technical third party. If it is about design, it is recorded
  as an **ADR** and the PR **is unblocked** — a PR is not where an architecture is decided.
  Indefinite blocking over an unresolved disagreement is forbidden (§7).

## 4. Prior automation and process metrics

### 4.1 The person reviews what only a person can review

Before a human opens the diff, it must already be green (the execution belongs to `cicd-standards`;
what follows is what this skill **requires** to be checked):

1. **Formatter** — a check, not a suggestion. Its absence generates style threads (§3.1).
2. **Linter** and the ecosystem's rules.
3. **Types / static analysis**.
4. **Tests**, unit and integration, with a regression test if it is a *bugfix*
   (`testing-qa-standards`).
5. **Scanners**: secrets in the diff, SCA of new dependencies, SAST, IaC.
6. **Contract checks** when the diff touches a published interface.

Hard rule: **no automatable finding is left to human review**. And its converse:
**a person does not approve a PR with CI red** "because the failure is unrelated". If the gate is not
reliable, the gate gets fixed — you do not learn to ignore it.

What **only** a person can do, and therefore where their attention must go: whether the change
solves the real problem, whether the design will withstand the next requirement, whether the domain's
edge case is covered, whether the declared risk is the real risk, and whether the code will be
understandable two years from now.

### 4.2 The LLM-based automatic reviewer

- **An adviser, never an approver.** Its comments are hypotheses: the human reviewer verifies or
  discards them, and answers for the decision. An LLM cannot be held accountable.
- Its real contribution is in the mechanical and repetitive (known patterns, omissions, inconsistencies
  with the description). Its typical failure is the **self-confident false positive**, which consumes
  exactly the attention the review needed.
- **Measured noise = tool switched off**: if a rule of the automatic reviewer generates comments that are
  systematically discarded, that rule is disabled.
- **FORBIDDEN** for an automatic approval to count as the approval required by
  branch protection.

### 4.3 Metrics: to improve the process, never to evaluate people

- These are measured, **only aggregated by team and as a time series**: time to first
  response, total time to *merge*, diff size, number of round trips, proportion
  of PRs approved with no comments, PRs open beyond the deadline, and **defects escaped to
  production** (the signal that really matters).
- **FORBIDDEN to use any review metric to evaluate an individual** (comments
  issued, PRs approved, approval speed, lines reviewed). The reason is mechanical, not
  moral: every review metric is trivially optimised by approving faster and commenting
  less, that is, **by destroying exactly the control it was meant to measure**. The same
  mechanics apply to any activity proxy turned into a target; **no figure is cited here**
  because no verifiable primary source has been located for the ones that usually accompany
  this claim (§8).
- A metric that goes up without escaped defects going down is not an improvement: it is a more
  superficial review.
- The DORA delivery metrics and pipeline telemetry belong to `observability-standards` and
  `cicd-standards`.

### 4.4 Pair and mob programming as an alternative

- **They replace asynchronous review** when the second pair of eyes was present *during* the
  writing: continuous review, zero latency, knowledge transfer built in.
  Condition for it to count as a control: **it is recorded in the PR who co-wrote it**
  (`Co-authored-by:`) and that the change was made in a pair.
- It fits best in: exploratory or open-design changes, high risk (§5), onboarding of
  new people and areas with a single *owner* (§3.7).
- **It does not replace review** when an **independent** reviewer is needed for a segregation
  of duties requirement (`grc-compliance-standards`) or when the change touches a domain
  neither of the two specialises in.
- It is not free: it consumes two people at once. It is chosen by the risk of the change, not by fashion.

## 5. Review of high-risk changes

Classes that **require a domain-specific reviewer in addition to the ordinary reviewer**, because the error
is not caught by general reading and its cost is not proportional to the size of the diff:

| Class | Why it requires a specialist | What is checked, at a minimum |
|---|---|---|
| **Data migration** | It is the change with the least real *rollback* and the most irreversible impact | Backwards compatibility (*expand/contract*), behaviour at real volume, locks and duration on a hot table, reversal plan **executed** in a rehearsal, idempotency on re-execution |
| **Authentication and authorisation** | A failure here does not produce an error: it produces access | Where the decision is evaluated (the server, always), object **and** identity checked together (IDOR/BOLA), expiry and revocation, a path that skips the *middleware*, a role change that silently widens privilege |
| **Cryptography** | The error is indistinguishable from the correct thing in functional tests | Algorithm, mode and key size; the IV/nonce's origin and its uniqueness; constant-time comparison; the key's provenance and life cycle; **zero home-made cryptography**. Criteria: `cryptography-pki-standards` |
| **Concurrency and shared state** | The failure is non-deterministic and not reproducible in review | Protected invariant, lock ordering, *check-then-act*, single-process assumption, behaviour on retry |
| **Infrastructure and deployment** | The *blast radius* is the whole system | The diff of the applied plan (not just the code), destruction/recreation of resources, network exposure, widened IAM permissions, secrets. Criteria: `iac-standards` and the cloud skills |
| **New dependency or major version bump** | Supply chain surface | Maintenance and licence, breaking *changelog*, size of the added surface against what it solves |
| **Public contract change** | It breaks third parties who are not in the PR | Compatibility, versioning and deprecation plan (`api-design-standards`) |
| **Feature flag and configuration** | It changes behaviour without going through the pipeline | Safe default value, scope, owner and **retirement date** |

Cross-cutting rules for this section:

- **A secret detected in a diff**: the thread is not "remove it". The secret **is compromised as of
  the push**: it is rotated, and the history rewrite is coordinated as in `git-workflow-standards`.
  `secrets-management-standards` fixes the rotation.
- **SELF-APPROVAL FORBIDDEN** in any of these classes, including for a person who is the
  only *owner*: you find a reviewer outside the team rather than approving yourself.
- A high-risk change **mixed with a refactor or with formatting changes** is sent back to be
  separated: the signal is lost in the noise and the specialist reviewer cannot do their job.
- The risk *checklist* applies to the **diff**, not to the ticket: what counts is what the
  change touches, not what it says it does.

## 6. Review of AI-generated code

> The template's canonical §6 (performance and operability) does not apply to this domain and **is
> replaced** by what is today the biggest operational change in review.

### 6.1 What changes when the author is not human

- **The bar does not drop and the scepticism goes up.** Generated code is *plausible by
  construction*: it follows the conventions, it looks good and the names are right. Those signals, which
  in a human author correlated with care, **stop being evidence of anything**. Reviewing by
  "it reads well" is, with AI, reviewing by the one thing the tool guarantees out of the box.
- **The effort asymmetry is the structural problem**: generating is cheap and reviewing still
  costs the same. Without a size rule enforced harshly (§3.5), the process breaks on
  the review side, not on the production side.
- **The specific trap to name**: a large, coherent and plausible diff produces superficial
  review with **more** confidence than a small, odd diff. Operational countermeasure: faced with a
  generated and large diff, **it is rejected on size before being read** and splitting is demanded. You do not
  do "a quick pass".
- Areas where generation fails most often and where the reviewer's attention must go:
  edge cases and error branches, authorisation, correct use of the API it claims to use (methods and
  parameters may not exist), assumptions about concurrency, and **tests that reproduce the
  same misunderstanding as the code** — a test generated from generated code verifies
  nothing, it only freezes it.

### 6.2 Responsibility rule

**Whoever submits the change answers for it even if they did not write it.** With no nuance: material
authorship is irrelevant to responsibility. Hence, enforceable and checkable requirements:

- The author **can explain every line** of the diff they submit. If they cannot, they do not submit it.
- The description declares **how it was verified** (§3.4). *"The assistant said it was fine"* is not
  a verification and it sends the PR back unreviewed.
- The use of an assistant **is declared** in the PR (and the co-authorship in the commit, per
  `git-workflow-standards`). It is not a badge of shame: it is information the reviewer needs
  to calibrate where to look.
- **FORBIDDEN to request review of a diff the author has not read in full.** Sending for
  review what you have not read shifts the work to the reviewer and turns review into the
  first real control, which is exactly what it must not be.
- A change authored by an agent goes through **the same** pipeline, the same gates and the same
  human review as any other. **No fast lane for generated code.**

### 6.3 Available evidence, and what has been discarded

- **DORA, *State of AI-assisted Software Development* (2025, presented by Google Cloud;
  published in September 2025 — as of Aug 2026 there is no 2026 edition of that report)**: its
  central thesis, verbatim from dora.dev, is that *"AI's primary role is that of an amplifier, magnifying the
  strengths of high-performing organizations and the dysfunctions of struggling ones."*
  Direct consequence for this skill: **AI does not fix a bad review, it saturates it.** A
  team with no automatic gates, no size limit and no blocking criteria gets worse when it adopts it.
- **METR, randomised controlled trial (Jul-2025)**, verbatim: *"we recruited 16 experienced
  developers from large open-source repositories (averaging 22k+ stars and 1M+ lines of code)"*,
  on *"real issues (246 total)"*; *"When developers are allowed to use AI tools, they take 19%
  longer to complete issues—a significant slowdown"*; and the datum that matters here:
  *"developers expected AI to speed them up by 24%, and even after experiencing the slowdown, they
  still believed AI had sped them up by 20%"*. The rule that follows: **the author's perception of
  speed is not evidence** and is not accepted as an argument for relaxing review. (Caveats
  of the design itself: small sample, large OSS projects the participants already knew;
  it does not extrapolate to every context.)
- **Discarded for lack of a primary source** (not written as criteria): tool vendors'
  figures about "N× more logic bugs in generated code" and vendor telemetry about
  increased review time or PR size — they are product data, with no published methodology
  and no independent review. If you need a number, **measure your own**:
  escaped defects and PR size before and after adopting the assistant.
- **Declared gap (§8)**: no normative guidance from a standards organisation specific to the
  review of AI-generated code has been located. What is published as of Aug 2026 are
  academic papers on the redistribution of responsibility and vendor guides.

## 7. Sustainability and prohibitions

- The review rules live in the repository (`CONTRIBUTING.md` or equivalent), they are cited by
  link in comments and **they are changed by PR**, like code. A rule that only exists in
  the senior reviewer's head is not a rule: it is a habit.
- Periodic review of the process itself: PRs beyond the deadline, style threads that appeared
  (they indicate a missing formatter, §3.1), `CODEOWNERS` paths with a single effective *owner*, automatic
  reviewer rules with a high discard rate, and escaped defects that the review should
  have caught — with a **blameless postmortem** and a rule change, never a warning to a person
  (`incident-management-standards`).
- Review is also the team's training vehicle: every well-written `note:` is
  documentation. But **training does not justify blocking**.

### Explicit prohibitions

- ❌ **FORBIDDEN to approve without reading.** An LGTM is a signature: if you have not read the diff, you do not sign.
- ❌ **FORBIDDEN** to accept for review a PR of hundreds of files without splitting it or declaring the
  mechanical part; the reviewer rejects it on size **without reading it** (§3.5).
- ❌ **FORBIDDEN to discuss automatable formatting or style** in a review thread (§3.1).
- ❌ **FORBIDDEN to block on personal preference**, on architectural taste already decided or on a
  refactor outside the scope.
- ❌ **FORBIDDEN to use review as power control**: withholding approvals to negotiate,
  systematically blocking someone's work, demanding changes with no written reason or imposing
  your own style through the signature. It is a process failure and it is escalated as such.
- ❌ **FORBIDDEN** the comment aimed at the person instead of at the code, sarcasm and
  condescension. No exception for seniority and none for urgency.
- ❌ **FORBIDDEN** to leave a PR blocked indefinitely by a disagreement: it is escalated or
  recorded as an ADR and unblocked (§3.8).
- ❌ **SELF-APPROVAL FORBIDDEN** on paths with an *owner* and in every high-risk class (§5).
- ❌ **FORBIDDEN** to approve with CI red, or to disable a *required check* in order to merge.
- ❌ **FORBIDDEN** for an automatic reviewer's (LLM) approval to count as the required human
  approval (§4.2).
- ❌ **FORBIDDEN** to send for review a generated diff the author has not read in full (§6.2).
- ❌ **FORBIDDEN** any fast lane or review exemption for AI-generated code.
- ❌ **FORBIDDEN** to use review metrics to evaluate individuals (§4.3).
- ❌ **FORBIDDEN** to mix refactor, formatting and behaviour change in the same high-risk
  PR.

## 8. Mandatory web verification

Before fixing any of these points in a real team, check online:

1. **Conventional Comments**: that the specification and the list of labels are still as cited
   (`conventionalcomments.org`), and whether the project is still maintained. The definitions in §3.8 were
   taken verbatim as of Aug 2026.
2. **Google Engineering Practices** (`google.github.io/eng-practices`): that the "Small CLs" and
   "Speed of Code Reviews" guides are still published with that wording; they are among the few
   public and citable normative sources in this domain.
3. **Evidence on PR size**: the Cisco/SmartBear study is from **2005-2006** and was conducted by
   the vendor of the tool. **Declared gap**: no independent and recent study has been located in
   this pass that replicates the relationship size ↔ density of defects found.
   Look for it before presenting those figures as universal; if one appears, the
   new one wins.
4. **Sadowski et al., ICSE-SEIP 2018**: their figures describe **Google in 2018**, not a universal
   optimum nor a target to imitate. Check whether there is a later replication in another context.
5. **Review of AI-generated code**: look for whether normative guidance has appeared (ISO/IEC, NIST,
   OpenSSF, Linux Foundation) or an independent study. **Declared gap as of Aug 2026: not
   located.** Ignore vendor figures with no published methodology (§6.3).
6. **DORA**: whether a **2026** edition of the *State of AI-assisted Software Development* now exists
   (as of Aug 2026 only the Sep-2025 one is on record, plus the *ROI of AI-assisted Software Development*
   updated in Apr-2026). Check any figure against the original report, **not** against
   third-party summaries.
7. **METR**: whether there are replications or extensions of the Jul-2025 trial with a larger sample; the
   study itself declares limitations that prevent generalising.
8. Automatic review and diff analysis tools: licence change, maintenance
   mode or acquisition (precedents in the catalogue: Trivy changed its licence; gitleaks
   declared itself *feature complete*; Brakeman turned out to be paid despite the general belief). Source:
   the raw `LICENSE` and the official website, **not** the GitHub feed on its own — a project that
   moves organisation looks abandoned in the feed. And do not take any acquisition news
   as true without a primary source (precedent: the "purchase of Cypress.io by John Deere" is an
   April Fools' joke from 1-Apr-2025).

If the web contradicts this document, **the web wins** — flag the discrepancy.
