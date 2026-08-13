# Map of `claudeonstereoids`

> Refreshed **2026-08-13** against `fe9f68c`. If anything here does not match the repo, **the repo
> wins**: fix the line and move on. Maintained per the `project-map` skill.
>
> **Working tree at refresh time**: 3 files modified (`.gitignore`, `SKILLS-ROADMAP.md`,
> `skills/claude-code-skills-standards/SKILL.md`) and 2 skill directories untracked
> (`backup-recovery-standards`, `update-standards`). **All counts below are from disk**, not from
> `HEAD`.

## What this repo is

A Claude Code configuration and an **IT engineering skill catalogue**: one criteria document per
directory under `skills/`, of the order of 80,000 lines. **For the exact count, line total and index
cost, run `./check.sh`** — those are measurements, and per `project-map` §2.2 this file stores the
command, not its output. The repo is the **single source of truth**; `~/.claude` is a *destination*,
written only by `./install.sh`. Editing `~/.claude/skills` directly is how divergence starts.

## I want to change… → go to…

| To… | Go to | Note |
|---|---|---|
| Write or edit a skill | `skills/<name>-standards/SKILL.md` | One dir per skill, **`name:` in frontmatter must equal the dir name** — gate 1 of `check.sh` |
| **Re-verify an existing skill** against the web | `skills/update-standards/SKILL.md` | Cadence, the `Criteria verified as of` line, closing a `Declared gap`, and the verification traps. **Bounded to `skills/` in this repo** |
| Know how a skill must be structured | `SKILL-TEMPLATE.md` (91 lines) | Canonical 8 sections + the enforced literals. Deliberately **outside `skills/`**: any dir with a `SKILL.md` registers as an active skill |
| Change how skills are authored/judged | `skills/claude-code-skills-standards/SKILL.md` | The meta-skill. **§4.3 holds the trigger-collision gate** (Python script + `STOP` list) |
| Change how *I* work (doctrine, not facts) | `CLAUDE.md` (315 lines) | Global preferences. Its opening block marks a **core that must not be edited without asking** |
| Change what is re-injected **every turn** | `core-directives.md` (43 lines) | Payload of the `UserPromptSubmit` hook. ~3 KB, paid on every prompt — the anti-dilution mechanism |
| Find project state / what to do next | `SKILLS-ROADMAP.md` (1559 lines) | Read the **topmost `CONTINUATION POINT`** (2026-08-13) first; everything below is history |
| Run the mechanical gates | `./check.sh` | 3 gates over `skills/`; exit 0 = green |
| Push the repo onto `~/.claude` | `./install.sh` | Mirrors `CLAUDE.md` + `core-directives.md` + `skills/`, and merges the hook into `settings.json`. **`--dry-run` first** |
| Read the original plan | `plans/validated-swimming-treehouse.md` | Historical; the roadmap superseded it |
| See cross-session memory | `memory/` | **Currently empty.** Symlinked into `~/.claude/projects/<slug>/memory` by the installer |

## Structure

- `skills/` — one directory per skill, each with a single `SKILL.md`. All but two
  use the `-standards` suffix; the exceptions are `skills/project-map/` and
  `skills/update-standards/`, which are **procedural** (they govern this repo's own upkeep) rather
  than domains. **Two directories are untracked and must go in the next commit**:
  `backup-recovery-standards` (was swallowed by `.gitignore`, see Minefields) and
  `update-standards`.
- `memory/` — holds only `.gitkeep` so far. That file exists **so the directory survives a clone**:
  without it `install.sh:163` leaves a dangling symlink (see Minefields).
- `plans/` — one historical planning document.
- Root — the two scripts, five docs (`CLAUDE.md`, `core-directives.md`, `README.md`,
  `SKILL-TEMPLATE.md`, `SKILLS-ROADMAP.md`), this map, `LICENSE`, `.gitignore`.

There is **no source code, no build, no test suite, no CI**. Everything here is markdown plus two
bash scripts; the "tests" are `check.sh` and the collision script in the meta-skill.

## ⚠️ Known defect: the per-file index is missing

**This map is incomplete, and the missing piece is the important one.** `project-map` §2.1 requires a
**per-file index** for a content repository — file, what it decides, size — because that table *is*
the map here: it is what answers "which skill decides X?" without a `grep`. Everything above only
answers "where do I go to change something".

It was deferred until the English translation landed so the generated one-line summaries would not
be written twice. **That reason expires the moment the translation does**, and then this section gets
replaced by the generated table. Generate it with a script over each file's own `description:`
(§4.5) — never by hand, or it drifts into fiction.

Until then: **if you catch yourself grepping to find out which skill owns a domain, that is this
defect, not a failure of the tool.**

## Entry points

- `./check.sh` — the mechanical gates. Reads `skills/*/SKILL.md`.
- `./install.sh` — `install_all()` (default), `uninstall_all()` (`--uninstall`), `--dry-run`.
  Targets `${CLAUDE_HOME:-$HOME/.claude}`.
- `CLAUDE.md` — what a session loads as global instructions once installed.
- `SKILLS-ROADMAP.md` — where any new session must start reading.

## Commands

**These are commands, not results.** Run them; do not quote a figure from here (`project-map` §2.2).
The date is the last time the command was seen to run clean, nothing more.

| What | Command | Last seen clean |
|---|---|---|
| Mechanical gates (3), plus skill count, line total and index cost | `./check.sh` — exit 0 = green | 2026-08-13 |
| Trigger-collision gate | Python block in `skills/claude-code-skills-standards/SKILL.md` §4.3, run from `skills/` | 2026-08-13 (all surviving pairs inherent and argued in that section) |
| Skills still in Spanish | `cd skills && grep -lE '^\*\*No aplica\*\*' */SKILL.md` — **anchor the pattern**: a bare `grep -l 'No aplica'` also matches the two files that merely *document* the literal | 2026-08-13 |
| Skills with no verification date | `grep -LE '^(Criteria verified as of\|Criterios verificados)' skills/*/SKILL.md` — the top of the `update-standards` queue | 2026-08-13 |
| Destination in sync with the repo | `diff -rq skills ~/.claude/skills` — empty output = in sync | 2026-08-13 |
| Install onto `~/.claude` | `./install.sh --dry-run` then `./install.sh` | 2026-08-13 |
| Delegation graph (dead ends, orphans) | ad-hoc Python over `` `x-standards` `` refs; see the roadmap entry of 2026-08-10 | 2026-08-10 |

## Conventions and invariants

- **Frontmatter**: `name:` (kebab-case, equal to the dir) and `description:` (single line,
  **English**, artifact-level triggers, zero filler). The description is the only thing injected
  every turn — it is the index cost. Catalogue average **118 words**, max 262.
- **Body**: the canonical 8 sections. §1 must end with the `**Not applicable**:` boundary line, §8
  must close with the arbitration sentence. Both are enforced by `check.sh`, which **greps for the
  literal** — paraphrasing silently disables the gate.
- **Language**: descriptions are English; bodies are mid-migration — **154 English, 65 Spanish**. A
  full migration to English was decided on 2026-08-10. `check.sh` accepts both forms meanwhile.
- **Verification date**: every body should open with `Criteria verified as of **<Month Year>**`.
  **17 files have no such line** and five spellings are in circulation; `update-standards` §2 fixes
  the canonical form.
- **No dir with a `SKILL.md` may live outside `skills/`** or it silently registers as a skill.
- **Nothing factual from memory**: versions, EOLs, licences and flags are verified on the web and
  dated. A declared gap beats an invented fact.

## Minefields

- **`.gitignore` swallowed a whole skill until 2026-08-13.** `backup-*/` was unanchored, so git
  applied it at any depth and ignored `skills/backup-recovery-standards/` — never committed, absent
  from the remote, invisible locally because `install.sh` mirrors with `rsync`. Now `/backup-*/`.
  **That directory and `skills/update-standards/` must be included in the next commit.**
- **`SKILLS-ROADMAP.md` is append-heavy and 1,559 lines.** The live section is the **topmost**
  `CONTINUATION POINT` (2026-08-13); everything below is history kept on purpose. Do not edit the
  historical blocks. **Its older "PENDING" list contains two claims verified false** — corrected in
  the topmost block, not in place.
- **`skills/claude-code-skills-standards/SKILL.md` §4.3 embeds a runnable script inside a fenced
  block.** Editing its indentation breaks extraction. After touching the `STOP` list, re-extract and
  re-run it — the gate must stay reproducible.
- **`~/.claude/SKILL-TEMPLATE.md` is a stale orphan** (2 Aug, Spanish). `install.sh:43` does not
  install it, by deliberate decision, yet the meta-skill §3 points at that path. The reference
  drifts by design; repoint it at the repo.
- **`install.sh:163` does `ln -s "$REPO/memory"` without checking the target exists**, so an absent
  `memory/` yields a **dangling symlink** on a clean install. Closed on 2026-08-13 with
  `memory/.gitkeep`; do not delete that file thinking it is noise.
- **`install.sh` mirrors with `rsync --delete`**: it removes whatever is in the destination and not
  in the repo. It backs up first — and never prunes: `~/.claude` already holds **7** `backup-*`
  directories, one full copy of the tree each.
- **The hook fails silently by design**: `jq … 2>/dev/null || true`. Missing `jq` or missing
  `~/.claude/core-directives.md` turns the anti-dilution mechanism off with **zero signal**. It also
  hard-codes `$HOME/.claude/core-directives.md` and **ignores `CLAUDE_HOME`**, which `install.sh:24`
  honours.
- **Git identity matters here**: commits must be signed as Lain with the YubiKey GPG key. Other keys
  in the keyring are the wrong ones for a public remote. Check `git config user.email` first.

## Out of the map

`/backup-*/` (installer backups, root-anchored), `.idea/`, editor noise — all in `.gitignore`. The
installed copy under `~/.claude/` is a *destination*, never edited by hand.
