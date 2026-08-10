# Map of `claudeonstereoids`

> Generated **2026-08-10** against `733b67a`. If anything here does not match the repo, **the repo
> wins**: fix the line and move on. Maintained per the `project-map` skill.
>
> **Working-tree warning at generation time**: ~140 files are modified and 3 skill directories are
> untracked (`chaos-engineering-`, `gaming-infrastructure-`, `streaming-multimedia-standards`).
> `HEAD` is far behind what is on disk. Counts below are **from disk**, not from `HEAD`.

## What this repo is

A Claude Code configuration and an **IT engineering skill catalogue**: 218 criteria documents,
~81.500 lines. The repo is the **single source of truth**; `~/.claude` is a *destination*, written
only by `./install.sh`. Editing `~/.claude/skills` directly is how divergence starts.

## I want to change… → go to…

| To… | Go to | Note |
|---|---|---|
| Write or edit a skill | `skills/<name>-standards/SKILL.md` | One dir per skill, **`name:` in frontmatter must equal the dir name** — gate 1 of `check.sh` |
| Know how a skill must be structured | `SKILL-TEMPLATE.md` (79 lines) | Canonical 8 sections. Deliberately **outside `skills/`**: any dir with a `SKILL.md` registers as an active skill |
| Change how skills are authored/judged | `skills/claude-code-skills-standards/SKILL.md` | The meta-skill. **§4.3 holds the trigger-collision gate** (Python script + `STOP` list) |
| Change how *I* work (doctrine, not facts) | `CLAUDE.md` (192 lines) | Global preferences. Its opening block marks a **core that must not be edited without asking** |
| Find project state / what to do next | `SKILLS-ROADMAP.md` (1365 lines) | Read **"PUNTO DE CONTINUACIÓN"** first; older ones below are history |
| Run the mechanical gates | `./check.sh` | 3 gates over `skills/`; exit 0 = green |
| Push the repo onto `~/.claude` | `./install.sh` | Mirrors `CLAUDE.md` + `skills/`; **`--dry-run` first** |
| Read the original plan | `plans/validated-swimming-treehouse.md` | Historical; the roadmap superseded it |
| See cross-session memory | `memory/` | Symlinked into `~/.claude/projects/<slug>/memory` by the installer |

## Structure

- `skills/` — **214 tracked + 3 untracked = 218 dirs**, each with a single `SKILL.md`. All but one
  use the `-standards` suffix; the exception is `skills/project-map/`, which is procedural
  (it governs this very file) rather than a domain.
- `memory/` — 5 markdown files, one fact each, plus `MEMORY.md` as the index. **Symlinked, not
  copied**, by the installer, so what a session writes lands in the repo.
- `plans/` — one historical planning document.
- Root — the two scripts, the four docs, `LICENSE`, `.gitignore`.

There is **no source code, no build, no test suite, no CI**. Everything here is markdown plus two
bash scripts; the "tests" are `check.sh` and the collision script in the meta-skill.

## Entry points

- `./check.sh` — the mechanical gates. Reads `skills/*/SKILL.md`.
- `./install.sh` — `install_all()` (default), `uninstall_all()` (`--uninstall`), `--dry-run`.
  Targets `${CLAUDE_HOME:-$HOME/.claude}`.
- `CLAUDE.md` — what a session loads as global instructions once installed.
- `SKILLS-ROADMAP.md` — where any new session must start reading.

## Commands

| What | Command | Verified |
|---|---|---|
| Mechanical gates (3) | `./check.sh` | 2026-08-10 — run repeatedly this session, exit 0 |
| Skill count / total lines / index cost | `./check.sh` (printed at the end) | 2026-08-10 |
| Trigger-collision gate | Python block in `skills/claude-code-skills-standards/SKILL.md` §4.3, run from `skills/` | 2026-08-10 — 35 pairs, all inherent |
| Delegation graph (dead ends, orphans) | ad-hoc Python over `` `x-standards` `` refs; see roadmap entry of 2026-08-10 | 2026-08-10 — 0 dead ends |
| Install onto `~/.claude` | `./install.sh --dry-run` then `./install.sh` | **NOT verified in this session** — validated with `--dry-run` in an earlier one, never executed |

## Conventions and invariants

- **Frontmatter**: `name:` (kebab-case, `-standards` suffix, equal to the dir) and `description:`
  (single line, **English**, artefact-level triggers, zero filler). The description is the only
  thing injected every turn — it is the index cost.
- **Body**: the canonical 8 sections. §1 must end with the `**No aplica**:` boundary line, §8 must
  close with the arbitration sentence. Both are enforced by `check.sh`.
- **Language**: bodies are currently Spanish; **a full migration to English was decided on
  2026-08-10** and is in progress — expect mixed state until it lands.
- **No dir with a `SKILL.md` may live outside `skills/`** or it silently registers as a skill.
- **Nothing factual from memory**: versions, EOLs, licences and flags are verified on the web and
  dated. A declared gap beats an invented fact.

## Minefields

- **`SKILLS-ROADMAP.md` is append-heavy and 1365 lines.** The live section is the **topmost**
  "PUNTO DE CONTINUACIÓN"; everything below is history kept on purpose. Do not edit the historical
  blocks, and renumber carefully — the "LO SIGUIENTE" list has been renumbered by hand several
  times.
- **`README.md` is stale**: it claims *164 documents, ~61.000 lines*. Real figures are **218 and
  ~81.500**. Fix it when touching the README; do not quote it as a source.
- **`skills/claude-code-skills-standards/SKILL.md` §4.3 embeds a runnable script inside a fenced
  block.** Editing its indentation breaks extraction. After touching the `STOP` list, re-extract
  and re-run it — the gate must stay reproducible.
- **`~/.claude/skills` is a stale, divergent copy** at the time of writing: `install.sh` has not
  been run since the catalogue grew. Anything read from `~/.claude` right now is out of date.
- **`install.sh` mirrors with `rsync --delete`**: it removes whatever is in the destination and
  not in the repo. It backs up first, but read `--dry-run` output before trusting it.
- **Git identity matters here**: commits must be signed as Lain with the YubiKey GPG key. Other
  keys in the keyring are the wrong ones for a public remote. Check `git config user.email` first.

## Out of the map

`backup-*/` (installer backups), `.idea/`, editor noise — all in `.gitignore`. The installed copy
under `~/.claude/` is a *destination*, never edited by hand.
