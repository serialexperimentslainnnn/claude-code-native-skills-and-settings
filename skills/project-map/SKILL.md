---
name: project-map
description: Build and maintain PROJECTMAP.md, the orientation index of whatever repository you are working in, so the same grep/find/read is never paid for twice. Use at the very start of work in ANY repository - before the first substantial task - whenever PROJECTMAP.md is missing, whenever it is stale or contradicted by the repo, whenever you catch yourself searching for where something lives, whenever structure changes (new directory, moved module, different build/test command, new convention), and whenever you hand work over to another session or a subagent. Covers what goes in the map, what must never go in it, how to size it for a code repo versus a content repo, how to generate it cheaply with a script instead of by hand, how to keep it honest, and where to put it so it does not pollute a repository that is not yours.
---

# Project map — `PROJECTMAP.md`

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **The problem it solves.** Without a map, every session rediscovers the same repository: the same
> `find`, the same `grep`, the same reads of files that turn out not to be the one. It is paid in
> full every time, and the context fills with exploration noise instead of work.
>
> **The risk it introduces.** A stale map is **worse than no map**: nobody checks it, everybody
> believes it. Everything below exists so the map does not lie.

## 1. Scope and triggers

**This skill fires automatically. It is not opt-in.**

- **Starting work in any repository**: read `PROJECTMAP.md` **before exploring anything**. If it
  does not exist, **create it before the first substantial task** — not at the end, not "if there
  is time". Creating it is the cheapest exploration you will ever do, because you were going to pay
  for it anyway, unindexed.
- It exists but **contradicts the repo**, or is stale (§5 detects that in one command).
- **You catch yourself searching for where something lives.** That surprise is the signal: what you
  just learned goes into the map, in this turn.
- **Structure changes**: new directory, moved module, different build/test command, new convention.
  Updated **in the same turn**, never "later".
- **You hand work over** to another session or a subagent: the map is the cheapest handover there is.

What counts as "substantial": anything beyond answering a question about a file already open. A
one-line fix does not require a map; changing behaviour, adding a feature, debugging or reviewing
does.

**Not applicable**: see `knowledge-management-standards` (documentation for humans: ADRs, runbooks,
wiki, who maintains what — the map is **not** product documentation and does not replace a README),
`claude-code-skills-standards` (authoring skills and `CLAUDE.md`: **the map describes the repo, the
`CLAUDE.md` sets how work is done in it** — if in doubt, the rule goes to `CLAUDE.md`, the fact goes
to the map), `software-architecture-patterns-standards` (deciding the architecture; here it is only
**described**, not judged), `code-review-standards` (reviewing the change), `git-workflow-standards`
(history and branches).

## 2. Default decisions

| Decision | Default | Why |
|---|---|---|
| Name and location | `PROJECTMAP.md` at the repo root | Predictable; any session finds it without searching |
| Size | **As small as it can be while still answering "where is X?"** — see §2.1 | The cap is usefulness, not a line count |
| Versioning in your own repo | Commit it, if the team wants it | It pays off across people and sessions |
| Versioning in **someone else's repo** | **Do NOT commit**: `.git/info/exclude` | That exclusion is **local**; `.gitignore` is versioned and touching it dirties another team's repo |
| Monorepo | One root map plus one per large package | A single 800-line map gets read by nobody, including you |
| Generation state | Header with date and **short HEAD SHA** | Without it, staleness cannot be detected |
| Language | The repository's | Consistency with code, docs and issues |

### 2.0 The reader is the model, not a person

**Write this file for the agent that will consume it, not for a human onboarding.** Everything else
in this section follows from that, and getting it backwards is why most maps are useless:

- **Optimise for lookup, not for reading.** Stable table shapes, exact identifiers, `path:line`
  anchors, one fact per row. No narrative, no "as we saw above", no motivational prose. A sentence
  that would be cut from a README for being dry is usually the right line here.
- **Density beats brevity.** The cost is context tokens weighed against tool calls saved — not a
  reader's patience. A 600-line map that removes twenty `grep`s per session is cheap. A 120-line map
  that removes none is expensive at any size.
- **Ambiguity is the real enemy, not length.** `handles auth` is noise; `POST /session →
  src/auth/session.ts:BeginSession` is a lookup. Prefer the fully qualified name over the readable
  paraphrase, always.
- **Be greppable.** Keep identifiers verbatim as they appear in the code, so a search for the symbol
  finds both the map row and the definition. Do not pretty-print, pluralise or translate names.
- A human may read it, and that is fine. But **no line earns its place by being nice to read** —
  only by answering a question that would otherwise cost a tool call.
- **It is consumed with one `Read`, whole — never `grep`ped, paged with `sed` or sampled.** The size
  ceilings in §2.1 exist precisely so a single pass is affordable; searching inside it is the
  behaviour the map was built to remove. A matched line arrives without the section that gave it
  meaning — which heading it sat under, which minefield qualified it — so the reader guesses or
  searches again and pays twice for a worse answer. **A map being grepped is a map that failed**:
  either it is too long for one pass, or its consumer was never given the fragment it needed
  (§4.6). Fix the map or fix the routing; do not normalise the grep.
- **`sed`/`awk` never touch it at all.** On a governing document that is editing, and edits go
  through the single writer that applies the deltas (§4.7) — never through whoever happened to open
  it last.

### 2.1 How deep, really

The old rule of thumb was ~150 lines. **That was a human-readability heuristic and it does not
apply** (§2.0). The governing constraint is different: **every line must save a search, and every
line must be true.** Depth is bounded by what can be kept honest, not by what fits on a screen.

- **Content repository** (each file is a self-contained unit looked up by name — a skill catalogue,
  a docs site, a policy set, a notebook collection) → **the per-file table is the map**: file, what
  it decides or contains, size. This is a database index, and indexes list rows. **Not optional and
  not deferrable**: without it the map cannot answer "which file decides X?", every session falls
  back to `grep`, and the map is doing none of its job. Too large to write by hand is an argument
  for generating it (§4.5), never for omitting it.
- **Code repository** → **index the public surface, not the directory tree, and go to symbol level.**
  Directories and entry points alone answer "where do I go to change something" and leave the
  expensive question — "where is the thing that does X?" — to `grep`, which is the failure this
  whole skill exists to prevent. See §2.3 for what to index and how to keep it true.
- The test is the same either way: **would this line save a search?** If not it is decoration — cut
  it, whatever the total length.

### 2.3 Code repositories: index the surface, and generate it

**The file is not the unit of lookup in code.** `src/utils/helpers.ts` answers nothing; a dumped
`tree` is the same problem with more tokens. What gets looked up is the **surface**: the names and
routes through which the system is entered and extended.

Index these, whichever the project has — one row each, with a `path:line` anchor:

| Surface | Row shape |
|---|---|
| HTTP/RPC routes | method + path → handler symbol → `file:line` |
| CLI commands / subcommands | command → entry symbol → `file:line` |
| Background jobs, cron, queue consumers | trigger/topic → consumer symbol → `file:line` |
| Events published and consumed | event name → producer, consumers |
| Public exports of each module/package | symbol → `file:line`, one line on what it owns |
| Domain types and their invariants | type → owning module → where it is validated |
| Persistence | table/collection → owning module → migration directory |
| Config and feature flags | key/env var → where it is read → default |
| Extension points | interface/hook → implementations |

**Two rules that make the depth survivable:**

1. **Generate it from the code, never write it by hand.** Hand-written symbol detail in an active
   codebase is fiction within a sprint, and a confidently wrong map is worse than no map. Extract
   from what cannot drift: the router table, the CLI registry, the DI container, exported symbols,
   migration filenames, the OpenAPI document, `ctags`/LSP output, the framework's own manifest.
   Regenerate in CI or a pre-commit hook and **fail the build when the map and the code disagree** —
   that gate is what converts the map from documentation into an invariant.
2. **Split before it becomes one unreadable file**: a root map with the cross-cutting picture, plus
   one generated map per package/service. Monorepos get one per workspace, not one of 4,000 rows.

**What stays hand-written** is exactly what a generator cannot know and what does not churn: why a
boundary exists, which module must not depend on which, the minefields, the invariants, the
"looks wrong but is deliberate" notes. **Generated content answers *where*; hand-written content
answers *why* and *careful*.** Never mix them in the same section — the generated part is
overwritten, and hand-written notes inside it are lost on the next run.

### 2.2 Locations and invariants, never derived state

The single most common way a map rots: storing **the result of a measurement** instead of the way to
obtain it.

- **Belongs in the map**: where something lives, what a directory is for, which command builds or
  tests, what is invariant, what is a minefield. These change when the repository is restructured —
  rarely.
- **Never belongs in the map**: counts, line totals, percentages of progress, "N files pending",
  test-pass numbers, sizes that move with the work. **These are stale the next time anybody commits**,
  and a wrong number is worse than an absent one because it gets quoted.
- The rule that resolves it: **store the command, not its output.** `Pending items: run
  scripts/pending.sh` ages well; `Pending items: 64` is a lie by tomorrow.
- Corollary for the reader: **a map removes the need to *search*, never the need to *measure*.**
  Locating a file is a map question; "how many are left?" is a command. Do not blame the map for the
  second, and do not try to make it answer it.
- The only figures that may appear are the ones in the header (generation date and short SHA), and
  they exist precisely so staleness is detectable.

## 3. What it contains (and in what order)

Order matters: what gets consulted most goes on top.

```markdown
# Map of <project>

> Generated <YYYY-MM-DD> against `<short-sha>`. If anything here does not match the repo, **the repo
> wins**: fix the line and move on. Maintained per the `project-map` skill.

## I want to change… → go to…
| To… | Go to | Note |
|---|---|---|
| Add an endpoint | `src/api/routes/` | Central registry at `src/api/router.ts:40` |
| Change the DB schema | `migrations/` | Never by hand in `models/`: it is generated |

## Structure
- `src/` — production code. `src/core/` depends on nothing in `src/adapters/`.
- `tests/` — unit next to the code; integration ones here.

## Entry points
- CLI: `src/cli/main.py` → `cmd_*` per subcommand.
- HTTP: `src/api/app.ts`, listens on `:8080`.

## Commands
| What | Command | Verified |
|---|---|---|
| Build | `make build` | 2026-08-05 |
| Tests | `pytest -q` | 2026-08-05 |

## Conventions and invariants
- Tests live next to the module, `_test` suffix.
- No DB access outside `repositories/`.

## Minefields
- `src/legacy/billing.py`: no tests, real billing depends on it. Read `docs/adr/0007` first.

## Out of the map
`node_modules/`, `dist/`, `.venv/`, generated files (`*_pb2.py`).
```

**The "I want to change… → go to…" table is the heart of the file.** It is the one that saves the
greps. If you only have time for one section, it is that one. A directory tree without it is
decorative.

For a content repository, add the **per-file index** (§2.1) as its own section, generated rather
than hand-written wherever possible: derive each row from the file's own front matter, title or
first heading, so it cannot drift into fiction.

## 4. How to generate it cheaply

Do not read the whole repository: **index, do not copy**.

1. **Inventory, not dump.** `git ls-files` grouped by first and second path level gives the real
   shape without listing 10,000 paths. What is not in git (generated, ignored) stays out unless it
   is a minefield.
2. **Read the files that are already maps**: `README`, `CONTRIBUTING`, `CLAUDE.md`/`AGENTS.md`,
   `Makefile`/`justfile`, `package.json` scripts, `pyproject.toml`, `docker-compose.yml`, CI under
   `.github/workflows/`. Commands come from there, not from memory.
3. **Entry points by ecosystem convention**: `main`, `index`, `app`, `cmd/`, `bin/`,
   `[project.scripts]`, the Dockerfile `entrypoint`, compose `services:`.
4. **Minefields from history**: the most-churned files (`git log --format= --name-only | sort |
   uniq -c | sort -rn | head`) show where it hurts. Cross that with missing tests and the minefield
   list writes itself.
5. **Generate the index with a script, not by hand** (§2.1, §2.3) — a loop that extracts each file's
   own summary line, or each module's exported symbols, is exact, repeatable and free of invention.
   In a content repository the source is the file's own front matter or first heading; in a code
   repository it is the router table, the CLI registry, exported symbols, `ctags`/LSP output or the
   OpenAPI document. **Commit the generator next to the map**: a generated file whose generator is
   lost becomes hand-written again on the first edit.
6. **Gate it**: regenerate in CI or a pre-commit hook and fail when the map and the code disagree.
   Without that gate the map is documentation and it rots; with it, it is an invariant.
7. **Delegable**: in a large repo an exploration subagent returns the draft and you verify it. That
   is precisely the cost the map stops you repeating.

### 4.6 Slice the map into the agent prompts — the slice *is* the partition

When work is delegated to a fleet, **paste into each agent's prompt exactly the fragment of the map
that its slice needs, and nothing else**. Every tier repeats this downwards: an agent that fans out
passes each of its subagents only the part of *its own* fragment that the subagent needs. The slice
narrows monotonically as you descend.

This is not only context economy. **The fragment is how the boundary is communicated**: an agent
holding only its own rows has its territory written down, so "do not touch anything outside your
slice" stops depending on it remembering. Handing the whole map to everyone does the opposite — it
shows each agent the files it must not touch, and pays tokens ×N for the privilege.

Two traps that make the difference between this working and it causing an incident:

- **Carry the minefields that touch those files, even when they look out of scope.** The slice is
  cut by *relevance*, never by section: a warning about a file the agent will edit belongs in its
  fragment whichever heading it lives under. An agent that walks into a trap you had documented and
  did not forward is your failure, not its.
- **The slice inherits the map's honesty, amplified.** A wrong line handed to one reader is one
  mistake; handed to eight agents it is eight, made simultaneously and confidently. Regenerate the
  fragments from the current map on every run — never from a cached copy of a previous one.
- **The prompt is the only channel, so agents never open the map themselves.** If they may fetch what
  the fragment lacks, the fragment stops being a boundary and becomes a suggestion — and the routing
  defect that produced the gap is hidden instead of fixed. **An agent whose fragment is missing,
  incomplete or contradicted by disk reports that and works from the files**; the tier above amends
  the brief in flight. That is what keeps the boundary absolute while still being survivable: an
  agent starved of context has a way out that does not involve reading rows it was never meant to
  see, and the gap gets fixed once, above, for every sibling at the same time.

**Make the surprise rule (§5) travel too**: require each agent to report back when the fragment
failed it — a path that does not exist, a command that does not run, a convention that turned out
different. That turns the fleet into a distributed verification pass over the map: they find the
errors in parallel, and you fix them once, at the top.

### 4.7 Close the loop: every agent returns a map delta

**A fleet rots the map faster than solo work does** — eight agents move, rename and create things in
parallel and none of it reaches the index. So the return leg is mandatory, not a courtesy:

- **Every agent ends its report with a `map delta` section**: what it changed that the map names or
  should name, what the map got wrong, what it had to discover because the map did not say. Empty is
  a valid delta and is stated explicitly — silence is indistinguishable from forgetting.
- **Two kinds, and both are wanted**: *(a) the map was wrong* (surprise rule, §5) and *(b) the work
  changed the repo* (same-turn rule, §5). The first fixes the past, the second records the present.
- **Each tier aggregates and deduplicates its children's deltas before passing its own upwards.**
  Eight agents touching one subsystem produce one merged delta, not eight overlapping ones.
- **Agents never edit the map.** It is a single file: N writers on it violates disjoint ownership and
  produces lost updates or conflicts. They emit the delta; **the top applies it, in one pass, in the
  same turn the fleet lands** — which is how the same-turn rule survives delegation instead of being
  quietly voided by it.
- Prefer deltas stated as an edit, not as prose: *"row `X` → path is now `Y`"*, *"new entry needed:
  `Z` owns …"*, *"minefield stale: the `.htaccess` warning no longer applies"*. A delta you have to
  interpret is a delta you will apply wrong.

**A command you have not run is not written as verified.** Either run it, or mark it `Declared gap`.

## 5. Keeping it honest

- **Surprise rule**: every time the map fails you — a path that no longer exists, a command that
  does not work — **you fix that line there and then**. It is the only maintenance that survives.
- **Same-turn rule**: if your change moves, creates or renames something the map names, you update
  the map **in that turn**. A map updated "at the end" is not updated.
- **Mechanical path check** (cheap, run it when picking work back up):

  ```bash
  grep -oE '`[a-zA-Z0-9_./-]+/[a-zA-Z0-9_./-]*`' PROJECTMAP.md | tr -d '`' |
    while read -r p; do [ -e "$p" ] || echo "DEAD PATH: $p"; done
  ```
- **Drift against the code**: compare the header SHA with `git rev-parse --short HEAD`. Many commits
  of difference do not invalidate the map — structure moves slowly — but they do mean looking at
  `git diff --stat <map-sha>..HEAD -- '*/'` for new directories.
- **Working tree vs. HEAD**: with many uncommitted changes, say so in the header and state which
  figures come from disk and which from `HEAD`. A map that silently mixes both misleads.
- **If the map contradicts the repository, the repository wins.** Always. The map is an index, not a
  source of truth.

## 6. Prohibitions

- ❌ **Starting substantial work in a repo without a map when creating one was possible.** The
  exploration you are about to do *is* the map: not writing it down is choosing to pay twice.
- ❌ **Copying code content into the map** (signatures, function bodies, full schemas). Duplication
  guarantees divergence. Cite `file:line`, do not transcribe.
- ❌ **A hand-written file dump.** Not because it is long — because it is unmaintainable and will
  lie. Depth in a code repository is legitimate and wanted, but **generated from the code and gated
  in CI** (§2.3). The prohibition is on the hand-written part, not on the detail.
- ❌ **Indexing a code repository by path instead of by surface** (§2.3): a `tree` with comments
  answers "where do I go", never "where is the thing that does X" — which is the search you are
  paying for.
- ❌ **Hand-written notes inside a generated section.** They are silently destroyed on the next
  regeneration. Keep *where* (generated) and *why/careful* (hand-written) in separate sections.
- ❌ **Writing what you have not verified.** No "the tests are probably run with…". Either check it
  or mark it `Declared gap`.
- ❌ **Storing a measurement instead of the command that produces it** (§2.2): counts, totals,
  progress percentages. They are stale on the next commit and they get quoted as if they were not.
- ❌ **Shipping a content repository's map without the per-file index** (§2.1) and calling it done.
  That table is the whole point; everything else is preamble.
- ❌ **Letting it expire in silence.** If you detect it is stale and cannot fix it whole, **mark the
  affected section as unreliable** instead of leaving it looking valid.
- ❌ **Putting doctrine in the map** (how work is done, what is forbidden): that belongs in
  `CLAUDE.md`. The map says **where** things are, not **how** they must be done.
- ❌ **Secrets, identifiable internal paths, IPs, production hostnames.** Maps tend to end up
  versioned; treat one as public code.
- ❌ **Creating `PROJECTMAP.md` and never looking at it again.** A map not read at the start saves
  nothing: the habit is reading it **before** exploring, not after.
- ❌ **Committing it in someone else's repository without permission.** It goes in
  `.git/info/exclude`, which is local.

## 7. Long-term sustainability

- The map is **disposable and regenerable**: if a large refactor invalidates it, regenerate from
  scratch (§4). Its history is not worth preserving.
- **Growth is not the failure mode; drift is.** Do not trim a map because it got long — trim it
  because a section stopped being consulted or stopped being true. When it does need splitting, split
  by package/service (§2.3), never by truncating detail. The one thing that always goes first is a
  hand-maintained full tree: maximum length, minimum answers.
- In repos with rich `AGENTS.md`/`CLAUDE.md`, **do not duplicate**: link to them.

## 8. Mandatory web verification

1. **Against the repository, always**: paths exist (§5), commands run, entry points start. **If the
   map contradicts the repo, the repo wins.**
2. **Against the web**, only for external things the map cites: build tool names and versions,
   package-manager commands, the canonical location of a framework's config file. Those expire and
   are not fixed from memory.

If the web contradicts this document, **the web wins** — flag the discrepancy.
