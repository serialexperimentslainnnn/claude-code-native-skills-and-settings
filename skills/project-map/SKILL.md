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

### 2.1 How big, really

The old rule of thumb was ~150 lines. **That is a heuristic for code repositories, not a law**, and
it breaks on one specific shape: repositories whose *content is the product* — a skill catalogue, a
docs site, a rules or policy set, a collection of notebooks. There each file is an independent unit,
and **a per-file index is exactly what stops the greps**.

The real rule:

- **Code repository** → index directories and entry points, never every file. A dumped `tree` is the
  same problem with more tokens. Stay terse.
- **Content repository** (each file is a self-contained unit looked up by name) → **the per-file
  table is the map**: file, what it decides or contains, size. This is a database index, and indexes
  list rows.
- Either way the test is the same: **would this line save a search?** If not it is decoration — cut
  it, whatever the total length.

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
5. **Generate the per-file index with a script, not by hand** (§2.1) — a loop that extracts each
   file's own summary line is exact, repeatable and free of invention.
6. **Delegable**: in a large repo an exploration subagent returns the draft and you verify it. That
   is precisely the cost the map stops you repeating.

**A command you have not run is not written as verified.** Either run it, or mark it `unverified`.

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
- ❌ **Listing every file in a code repository.** Name directories and the files that genuinely are
  entry points. (In a content repository the per-file index is the point — §2.1.)
- ❌ **Writing what you have not verified.** No "the tests are probably run with…". Either check it
  or mark it `unverified`.
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
- If it grows past what anyone reads, **do not extend it: split it** (one per package) or cut what
  is never consulted. The full tree is the first thing to go.
- In repos with rich `AGENTS.md`/`CLAUDE.md`, **do not duplicate**: link to them.

## 8. Mandatory web verification

1. **Against the repository, always**: paths exist (§5), commands run, entry points start. **If the
   map contradicts the repo, the repo wins.**
2. **Against the web**, only for external things the map cites: build tool names and versions,
   package-manager commands, the canonical location of a framework's config file. Those expire and
   are not fixed from memory.

If the web contradicts this document, **the web wins** — flag the discrepancy.
