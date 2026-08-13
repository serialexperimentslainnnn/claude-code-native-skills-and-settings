---
name: knowledge-management-standards
description: Documentation as infrastructure with a maintenance cost, for human readers. Use when deciding what to document and what to delete, applying the Diataxis framework (tutorial, how-to guide, reference, explanation) and splitting a document that mixes them, running docs-as-code with docs/ in the repository reviewed in the PR and built in CI, adding a broken-link gate with lychee or a prose linter with Vale, choosing or migrating a documentation stack (MkDocs Material, Docusaurus, Sphinx, Antora, Read the Docs, BookStack, Wiki.js, Outline, Confluence, Notion) and checking its licence and per-user price, generating reference from the source of truth (OpenAPI, JSON Schema, CLI --help, database schema) instead of writing it by hand, writing a README, a runbook nobody has executed, a design document, an onboarding guide or a postmortem write-up, setting a per-document owner and review-by date and deleting stale pages, fixing discoverability and search when three wikis exist, measuring bus factor and turning one person's undocumented knowledge into an artifact, using documentation as context for coding agents, or reviewing LLM-generated documentation that is plausible and wrong.
---

# Knowledge management and documentation standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Documentation is infrastructure with a maintenance cost.** It is not a deliverable that gets
finished: it is a system that degrades if nobody operates it. Hence the rule that governs this
document: **documentation that is not maintained is worse than not having it, because it lies with
authority**. A reader who finds nothing looks for a person; a reader who finds an obsolete procedure
executes it.

Immediate operational consequence: **creating a document is taking on a recurring obligation**. If
nobody accepts the owner role and the review date (§4.1), **it does not get written**. And
**deleting obsolete documentation is maintenance work, not loss of heritage**.

Covers: the criterion of what gets documented, Diataxis as the default structure, *docs as code*,
expiry and ownership, generation from the source, document types with a template and criteria
(README, runbook, postmortem, design document, onboarding guide), unwritten knowledge and the *bus
factor*, search and discoverability, tools, and documentation in the presence of LLMs and agents.

**Declared coverage**: **there is no `technical-documentation` skill in the catalogue; this one
covers it.**

**Not applicable**:
- `ai-agent-workflow-standards` (**theirs** are the repository instruction files —
  `AGENTS.md`, `CLAUDE.md`, `.cursorrules` — and the work with coding agents; **here the
  documentation for people**. Contact point in §6.3: human documentation is the agent's context,
  but **it is not written for the agent**).
- `claude-code-skills-standards` (**skill authoring is theirs**: frontmatter, triggers,
  activation).
- `code-review-standards` and `git-workflow-standards` (the diff, the commit message and its
  history; **here that a behaviour change carries the documentation change in the same PR**).
- `incident-management-standards` (**the postmortem as a process is theirs**: severity, roles,
  actions, follow-up; **here its format, where it lives and how long it is kept**).
- `sre-practice-standards` (**the operational runbook and its content are theirs**: which alert,
  what to check, what to mitigate; **here the criterion that it exists, has an owner and is
  tested** — §5.2).
- `itsm-itil-standards` (**the service knowledge base and known errors are theirs**, with their
  life cycle and their support audience).
- `technical-hiring-standards` (hiring and **the onboarding** of the person; **here the onboarding
  artifact and its test**, §5.5).
- `api-design-standards` (**API documentation is generated from the contract, which is theirs**:
  here only the obligation to generate it and not rewrite it by hand).
- `i18n-standards` (multilingual documentation: what gets translated, how it is synchronised and
  what happens when the translation falls behind).
- `software-architecture-patterns-standards` and `tech-leadership-standards` (**the decision
  criterion for an ADR is theirs**; here that the ADR exists, is immutable and is findable).
- `enterprise-architecture-standards` and `product-discovery-standards`. **The landscape decides
  which systems exist; discovery, what gets built; documentation is what remains written of both
  decisions.**

## 2. Default decisions

> Verify version, licence and price on the web before fixing it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Structure | **Diataxis** (tutorial / how-to / reference / explanation), CC BY-SA 4.0 (§2.1) | Your own **written** structure, if the product does not fit |
| Location | **`docs/` in the same repository as the code** | A separate documentation repository only for a multi-repo product |
| Format | **Markdown** (or AsciiDoc if advanced composition is needed) | Never a proprietary binary format for anything versionable |
| Review | **In the same PR as the behaviour change** | None |
| Publishing | **CI builds and deploys**; nobody uploads by hand | — |
| CI gate | **Broken links break the build** (lychee, Apache-2.0/MIT) | — |
| Site | **MkDocs Material** (MIT) | **Docusaurus** (MIT) if there is React and doc versioning; **Sphinx** (2-clause BSD) in Python; **Antora** for multi-repo AsciiDoc |
| Non-technical wiki | **BookStack** (MIT) self-hosted | Confluence if it is already paid for and the company lives there (§2.3) |
| Reference | **Generated from the source** (OpenAPI, JSON Schema, `--help`, DB schema) | Hand-written: **FORBIDDEN** if it is generable (§4.3) |
| Style | **Vale** (MIT) with a minimal style, in warning rather than blocking mode | — |
| Owner | **A person per document** + review date in the frontmatter | A team with a named rotation |

### 2.1 Diataxis: source, licence and the most common error

- **Authorship**: **Daniele Procida**. Site: `diataxis.fr`; source at `github.com/evildmp/
  diataxis-documentation-framework`. **Licence: CC BY-SA 4.0** (attribution + share alike).
  **Practical consequence: applying the framework is free; copying or adapting its text in your
  documentation drags attribution and ShareAlike onto that derivative work.** Write yours in your
  own words and link the source. (The framework's precedent is in the author's work during his time
  at Divio, 2014-2021, which he himself qualifies as partly superseded.)
- The four types and their belonging test:

| Type | The reader… | Test that it is correctly placed |
|---|---|---|
| **Tutorial** | learns by doing, deciding nothing | If the reader has to choose between options, it is not a tutorial |
| **How-to guide** | already knows what they want and is looking for the steps | If it explains why, that part does not belong there |
| **Reference** | looks up an exact datum | If it narrates, it is not reference |
| **Explanation** | wants to understand the why | If it contains executable steps, it is not explanation |

- **The most common failure is mixing all four in one document**, and it is not a matter of
  aesthetics: **each type has a reader with a different need at a different moment**. A tutorial with
  options and warnings stops the beginner; a reference with narrative forces you to read three
  paragraphs to extract a default value; a guide with theory gets abandoned halfway, and an
  explanation with commands gets executed without context. The result is a document that **serves
  none of the four** and that also expires four times as fast.
- **Cut rule**: if a document cannot be labelled with **one** of the four types, **it gets split**.
  It is labelled in the frontmatter and the navigation is ordered by type.

### 2.2 Site and wiki tools: licences verified raw

| Tool | Licence (verified) | The deciding note |
|---|---|---|
| **MkDocs Material** | **MIT** | There is an *Insiders* edition by sponsorship: deferred features. Verify what you need before assuming it |
| **Docusaurus** | **MIT** | Versioning and i18n out of the box; drags in React tooling |
| **Sphinx** | **2-clause BSD** (verbatim in `LICENSE.rst`: *"all code in the Sphinx project is licenced under the two clause BSD licence"*) | Default in Python; reStructuredText or MyST |
| **BookStack** | **MIT** | Self-hosted wiki, shelf/book/chapter/page hierarchy |
| **Wiki.js** | **AGPL-3.0** | **The AGPL applies to the service offered over a network**: if it is modified, there are obligations → `opensource-licensing-standards` |
| **Outline** | **Business Source License 1.1** (licensor General Outline, Inc.; an *Additional Use Grant* that **forbids using it to provide a "Document Service"**) | **It is not open source**. A common and wrong assumption; verified raw |
| **Vale** | **MIT** — repository at `vale-cli/vale` | The old `errata-ai/vale` **redirects**: the old repository's feed is not the source |
| **lychee** | **Apache-2.0** (dual with MIT in the repository) | Link checker for the CI gate |

### 2.3 Paid tools: what there is and what cannot be asserted

- **Confluence Cloud**: a **free plan limited to 10 users and 2 GB** in the sources consulted;
  Standard and Premium plans paid per user. **Declared discrepancy: third-party trackers give
  different figures for the same plan** (Standard ~5.4 / ~6.05 / ~6.40 USD per user per month;
  Premium ~10.4 / ~12.3), and several mention a **billing minimum of 10 users** and limited AI
  credits. **I have verified none of those figures against Atlassian's official page: price → gap
  in §8.** Do not budget with these numbers.
- **Purchasing rule**: the tool is not the problem. **Migrating wikis does not fix ownerless
  documentation**; it only moves the mess and adds a migration. Before comparing products, check
  that owner, review and CI gate exist (§4).

## 3. What gets documented and what does not

Criterion: **cost-benefit per reader and per useful life**, applicable document by document:

| Always write | Write with an owner and an expiry | **Do not write** |
|---|---|---|
| Why an irreversible decision was taken (ADR) | A guide to a task that repeats and is not obvious | What the code already says (§7) |
| How the project is started from scratch (README) | A runbook for an alert that pages | Reference generable by hand (§4.3) |
| What failed and what was changed (postmortem) | Onboarding for a specific role | A procedure for an interface being redesigned |
| The contract of an interface between teams | An explanation of a domain-specific concept | A screenshot of a UI that changes (§7) |

Questions that decide, in order:

1. **Who is the reader and what are they trying to do?** With no identifiable reader, it does not
   get written.
2. **How long does this live?** A procedure that changes every two weeks gets automated or put into
   the code, it does not get documented.
3. **Can it be generated from the source?** If so, **it gets generated** (§4.3).
4. **Can the need be eliminated?** A clear error message, a sensible default or an automatic check
   eliminate entire pages. **The best documentation is the documentation that stops being
   necessary.**
5. **How many people will read it in a year?** A document with one reader a year is a conversation,
   not a document.

## 4. Docs as code, expiry and generation

*(Section 4 of the template — quality and testing — applied to the domain: here "the build" is the
documentation and the gates are its quality controls.)*

### 4.1 Ownership and expiry: the real problem

- **Mandatory frontmatter in every document**: `owner` (a person), `last_review` (date),
  `review_every` (period), `type` (Diataxis type), `status` (`active` | `deprecated`).
- **Cycle**: when `last_review + review_every` falls due, a task is automatically opened for the
  owner. No response in 30 days → the document is marked **obsolete visibly in the header** (it is
  not deleted silently); at 90 days it is archived.
- **An obsolescence banner > immediate deletion**: the reader arriving through an old link needs to
  know they arrived late. **A document with no visible date reads as current**: the last review date
  is shown to the reader, not just in the repository.
- **Documentation changes in the same PR as the behaviour.** If the PR touches an interface, a
  flag, a procedure or a contract and does not touch `docs/`, the reviewer says so
  (→ `code-review-standards`). **Documenting later is documenting never.**

### 4.2 Minimum pipeline (gates in order of increasing cost)

1. **Documentation build**: if it does not compile, it breaks.
2. **Broken links** (lychee or equivalent): **breaks the build**; external links with an exception
   list and a retry, so the gate does not become flaky.
3. **Executable code examples**: the snippets that can be tested are tested (doctest, compiling the
   snippet). **An example that does not compile is a failure, not a typo.**
4. **Prose lint** (Vale) with a minimal style — forbidden terms, product names, capitalisation
   consistency —. **Warning, not blocking**, except the brand vocabulary. A blocking prose linter
   turns documentation into a toll and people stop writing.
5. **Per-PR preview** (ephemeral deployment): reviewing Markdown in the diff does not catch broken
   navigation.

### 4.3 Generate from the source — **what is generated does not lie**

- **Mandatory to generate, not to write by hand**: API reference (from the OpenAPI/proto → the
  `api-design-standards` contract), CLI options (from `--help`), schemas and data models,
  configuration variables, the version compatibility matrix, the ADR index.
- **Hard rule**: if a datum exists in the code or in a schema, **the documentation references it or
  generates it; it does not copy it.** Every hand-copied datum diverges; it is a question of when.
- What is generated **does not replace** the explanation: a generated reference says *what* is
  there; the explanation of *why* and *when* is written by a person. **Do not generate tutorials or
  explanations from a schema**: they come out correct and empty.
- The generator lives **in CI**: if the generated documentation differs from the committed one, **it
  breaks the build**.

## 5. Document types, template and criteria

### 5.1 README

It answers exactly: **what this is (one sentence), for whom, how it starts from scratch, how it is
tested, where the rest is**. Rules: **the start-up commands run as written on a clean machine** (if
they require three unwritten steps, the README is broken), it links and does not duplicate, and **it
fits on one screen**; everything else goes to `docs/`.

### 5.2 Runbook — **a runbook that has not been executed is fiction**

- Content and operational scope → `sre-practice-standards`. **Here the conditions of existence**: a
  named owner, the date of the last **execution** (not the last edit), and a link from the alert
  that triggers it.
- **It is tested**: in a *game day*, in a restore test or in the first real incident, and **whoever
  executes it corrects it on the spot**. A runbook that has gone more than 12 months without being
  executed is marked as unverified in its header.
- **FORBIDDEN** is the runbook that starts with "contact so-and-so": that is a phone number, not a
  procedure.

### 5.3 ADR and design document

- **The criterion for when an ADR is needed and how it is decided belongs to
  `software-architecture-patterns-standards` and `tech-leadership-standards`.** Here:
  **immutability** (an ADR is not edited: it is superseded by another that references it), stable
  numbering, a fixed location (`docs/adr/`), a generated index, and an **explicit status** (proposed
  / accepted / superseded).
- Design document: it is **pre-decision** and **expires on implementation**. When it closes, it
  either becomes an ADR + living documentation, or **it is archived marked as historical**. A design
  document left as "the system's documentation" is the most common cause of documentation that lies.

### 5.4 Postmortem

- **The process belongs to `incident-management-standards`.** Here: **a stable format and
  retention**. Fixed sections — impact with figures, timeline with times, contributing factors, what
  worked, actions with an owner and a date —, **with no names of people attached to blame**, and
  **public within the organisation by default**: a postmortem only the affected team sees teaches
  nobody anything.
- **They are kept indefinitely and indexed**: their value is that somebody finds the similar
  incident three years from now. A postmortem that cannot be found is wasted effort.

### 5.5 Onboarding guide

- **It is validated by executing it**: **the next person who joins follows it from scratch and fixes
  what fails, on the same day**; that is its maintenance. Nobody else reviews it.
- Falsifiable metric: **time to the new person's first change in production**. If it goes up between
  onboardings, the guide is expiring.
- **FORBIDDEN** to grant access "when they ask for it": the per-role access list is part of the
  guide and is processed before day one (→ `identity-access-management-standards`).

### 5.6 The knowledge that is not written down

- **Bus factor**: the number of people who can disappear before a system is left with nobody who
  understands it. **Bus factor 1 on a critical system is an operational risk**, it is recorded as
  such (a risk with an owner, not an anecdote) and it is attacked.
- How it is turned into an artifact, in order of effectiveness:
  1. **The single person should not be the one who writes it alone**: somebody else executes the
     procedure while the expert watches; **the one who does not know writes it up**, because the
     expert omits what seems obvious to them — and the obvious is exactly what is missing.
  2. **On-call and task rotation**: rotation is a documentation mechanism, not just a rest one.
  3. **Pair / mob in the concentrated area**, bounded and with a written objective.
  4. **Documentation inside the definition of done** of the work that touches the area.
- **What does not work**: asking the single person to "document everything" in the week before they
  leave. You get a dump with no reader, impossible to maintain and expiring on the first change.

## 6. Discoverability, and documentation in the presence of AI

### 6.1 **Documentation that cannot be found does not exist**

- When there is volume, **the problem stops being writing and becomes finding**. Warning sign:
  people ask in chat something that is documented. **That is not reader laziness: it is a search
  failure**, and it is treated as a failure.
- **The cost of having three wikis**: nobody knows which one rules, search returns three different
  versions, the oldest is usually ranked best and **the reader stops trusting all of them**. Rule:
  **one canonical destination per content type** (code→repo, operations→runbooks, process→corporate
  wiki) and **redirects from the rest**; never copies.
- **Minimum taxonomy**: product/service, Diataxis type, status. **Three axes and none of them
  free-form.** A taxonomy with fifteen free tags becomes noise within a quarter.
- **Search before structure**: full-text search with good titles beats any hierarchy. **The title is
  80% of the search**: it is written with the words the searcher would use, not the author's.
- Consolidation: **the only migration worth doing is the one that deletes**. Migrating 4,000 pages
  to a new tool without pruning is paying twice for the same mess.

### 6.2 Metrics (none of them counts pages)

| Metric | Signal |
|---|---|
| % of documents with an owner and a current review | System health |
| Pages never visited in 12 months | Deletion candidates |
| Chat questions resolved with an existing link | Discoverability failure (§6.1) |
| Time to a new person's first change in production | Onboarding quality |
| Runbooks executed in the last 12 months / total | Operational fiction |
| Median age of the documents **consulted** | Whether what is alive is up to date |

The metric "number of pages created" is **FORBIDDEN**: it rewards exactly the failure in §1.

### 6.3 AI and documentation

- **Documentation is context for coding agents.** Practical consequence: a clean `docs/`, with
  explicit titles and no contradictions, improves the agent's work; a wiki with three versions of
  the same truth makes it worse, because **the agent cannot know which one is current and will pick
  one**. The repository instruction files (`AGENTS.md`, `CLAUDE.md`) and their governance belong to
  `ai-agent-workflow-standards`: **they are not duplicated here**. The only rule of our own: **the
  instruction file links to the canonical documentation; it does not rewrite it**, or there will be
  two divergent sources.
- **LLM generation: human review is mandatory and named.** A generated text is published only if a
  person **with knowledge of the system** has verified it line by line against the source.
  **Whoever presses "approve" is the author for all purposes** (the same accountability rule as a
  generated diff, → `ai-agent-workflow-standards`, `code-review-standards`).
- **The specific risk is plausible and false documentation at scale.** It is different from stale
  documentation: it is well written, well structured, coherent and **describes a system that does
  not exist** — an option that is not there, a flag with a different name, an invented default
  behaviour. **It is more believable than the good documentation** and it survives a superficial
  review. Rules:
  - Generate **preferably what is verifiable**: guides with commands that run in CI (§4.2),
    summaries of existing content that can be cross-checked.
  - **FORBIDDEN** to generate reference (options, parameters, default values): that is generated
    from the source, which is authoritative (§4.3).
  - **Forbidden to publish in bulk**: if the volume generated exceeds what a human can verify, that
    is the batch limit.
  - **Mark the origin** in the frontmatter (`generated_by`, `reviewed_by`) so you can audit later
    what was generated when the first systematic error shows up.
- **AI does not fix ownerless documentation**: it speeds up its production, which is exactly the
  cheap part. The cost is in maintenance, and that does not drop on its own.

## 7. Long-term sustainability and prohibitions

- **Pruning with a cadence**: half-yearly review of unvisited pages and of overdue documents. **A
  deletion campaign once a year is a symptom; continuous maintenance is the cure.**
- **Migrations**: only with a prior inventory, pruning before moving and **redirects from the old
  URLs**. Mass broken links destroy trust faster than obsolete documentation.
- **Deprecating a document**: a visible banner with a link to the replacement and an archiving date;
  never silent deletion.
- Prohibitions:
  - ❌ **Documenting what the code already says** (commenting getters, describing the signature the
    signature already declares, "this function adds two numbers"). It duplicates the truth and
    expires on the first refactor.
  - ❌ **A wiki with no owner.** A shared space belonging to everyone belongs to nobody, and its
    half-life is a year.
  - ❌ **A screenshot as documentation of an interface that changes.** It expires silently and
    nobody reviews it. Describe the action; the screenshot only for what does not change or to
    explain a visual concept.
  - ❌ **Onboarding documentation nobody executes from scratch** (§5.5).
  - ❌ **A never-executed runbook presented as a valid procedure** (§5.2).
  - ❌ **A document with no owner and no review date** (§4.1).
  - ❌ **Hand-copying a datum that exists in a schema, a contract or a `--help`** (§4.3).
  - ❌ **Two canonical sources on the same topic.** One rules and the other redirects.
  - ❌ **Publishing LLM-generated documentation with no named human reviewer** (§6.3).
  - ❌ **Editing an already-accepted ADR** instead of superseding it (§5.3).
  - ❌ **Measuring documentation by number of pages** (§6.2).
  - ❌ **Mixing the four Diataxis types in one document** (§2.1).
  - ❌ **Copying text from Diataxis (or from any CC BY-SA source) without attribution and without
    taking on ShareAlike** in the derivative work.

## 8. Mandatory web verification

Check before fixing anything:

1. **Diataxis**: authorship (Daniele Procida), site `diataxis.fr`, repository `evildmp/
   diataxis-documentation-framework` and **licence CC BY-SA 4.0**. Re-verify the licence before
   reusing text: it conditions your derivative work.
2. **Tool licences** — verified raw as of August 2026: MkDocs Material **MIT**,
   Docusaurus **MIT**, BookStack **MIT**, Wiki.js **AGPL-3.0**, Vale **MIT** (current repository
   `vale-cli/vale`; the old `errata-ai/vale` **redirects** — the old repository's feed is not the
   source of truth), lychee **Apache-2.0/MIT**, Sphinx **2-clause BSD** (verbatim in
   `LICENSE.rst`), **Outline: BUSL-1.1 with the "Document Service" restriction — it is not open
   source**. Re-read the raw `LICENSE` before fixing any of them: they change.
3. **Prices** → **declared gap**: Confluence Cloud (free plan limited to 10 users / 2 GB according
   to secondary sources; **Standard and Premium figures inconsistent between trackers and not
   verified against Atlassian**), Notion and Read the Docs. **Consult the vendor's official page
   before budgeting; do not use the third-party figures in this document.**
4. **MkDocs Material Insiders**: which features are behind sponsorship at the moment of deciding.
5. **Generators**: versions and compatibility of OpenAPI/Sphinx/Antora before fixing the generation
   chain.
6. **Figures about documentation** ("developers lose X% of their time looking for information",
   "Y% of documentation is out of date"): **they are not used without a primary study and an
   accessible methodology**. I have not located a reliable one for this domain: **declared gap**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
