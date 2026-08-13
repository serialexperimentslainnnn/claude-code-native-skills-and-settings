# claudeonstereoids

Claude Code configuration and an **IT engineering skill catalogue**: 219 criteria documents,
~81,800 lines, written and verified one by one against primary sources.

A skill in this catalogue **does not teach** — the model already knows how to program. It fixes
**what gets decided, what is forbidden and what must be verified before asserting it**.

## Install

```bash
git clone git@github.com:serialexperimentslainnnn/claudeonstereoids.git
cd claudeonstereoids
./install.sh --dry-run   # shows what it will do, touching nothing
./install.sh
```

The repo is the single source of truth: **you work here, then you install**. The installer
**flattens** the global `CLAUDE.md`, the core directives and the skill catalogue onto `~/.claude`
(copy, one-way repo → home, deleting in the destination whatever no longer exists in the repo). It
copies instead of symlinking on purpose: a half-written skill does not become active in your session
until you decide to install it. Anything that was there before is backed up with a timestamp;
nothing is ever deleted without a copy. `./install.sh --uninstall` reverses it and tells you how to
restore.

Two things it also does, and they matter:

- **Merges a `UserPromptSubmit` hook** into `~/.claude/settings.json` — without touching your `env`,
  `permissions` or `model` — that re-injects `core-directives.md` on **every turn**. That is the only
  mechanism that stops the directives from being diluted as a conversation grows: a document loaded
  once at the start loses against the pattern of the last twenty turns.
- **Symlinks the project memory** instead of copying it: Claude Code writes it under
  `~/.claude/projects/<slug>/memory` during the session, so this way it lands inside the repo and
  gets versioned.

Then always work from the repository root:

```bash
cd claudeonstereoids && claude
```

## What is here

| Path | What it is |
|---|---|
| `skills/<name>-standards/SKILL.md` | The catalogue. One skill per directory. |
| `CLAUDE.md` | The user's engineering doctrine (installed as `~/.claude/CLAUDE.md`). |
| `core-directives.md` | The subset re-injected every turn by the hook (installed as `~/.claude/core-directives.md`). |
| `PROJECTMAP.md` | Index of this repository, maintained per the `project-map` skill. |
| `SKILLS-ROADMAP.md` | **Continuity file**: state, waves, method, lessons and findings. |
| `SKILL-TEMPLATE.md` | Canonical template. Deliberately outside `skills/`: any directory holding a `SKILL.md` registers as an activatable skill. |
| `plans/` | Original plan with the full taxonomy by family. |
| `memory/` | Persistent project memory. |
| `install.sh` · `check.sh` | Installer and mechanical gates. |

## State

**219 skills — the catalogue is complete.** Waves 0-7 done, trigger-collision test re-run and
arbitrated, delegation graph clean, and a composition pass over eight multi-domain scenarios
applied. The exact state and the pending tasks in order live in the `PUNTO DE CONTINUACIÓN` block of
`SKILLS-ROADMAP.md`, which is **the first thing to read** when picking the work back up.

The bodies are being migrated from Spanish to English (August 2026); expect a mixed state until it
lands. While it does, `check.sh` accepts both wordings of the enforced strings.

## How a skill is written here

Eight fixed sections, body in English, a one-line English `description` with triggers by **concrete
artifact** (extensions, config files, binaries, commands) — because that line is the only thing
injected every turn, and whether the skill activates depends on its precision.

Three rules that are expensive to learn and are already paid for here:

1. **No concrete fact from memory.** Versions, end-of-support dates, licences, RFC numbers and
   figures are verified on the web. Cannot verify → **declared gap**, never filler.
2. **A figure with a source and a methodology, or it does not get written.** This catalogue has
   discarded as folklore the Standish CHAOS Report, the "10x developer", the 10×/100× cost of a late
   bug, the "23 minutes" to recover from an interruption, and the COBOL lines-of-code figures.
3. **The licence is read from the file, raw.** Fourteen wrongly assumed cases in the catalogue, with
   the file named `COPYING`, `LICENSE.txt`, `LICENSE.md` or `license.txt`, and living on `master`,
   `7.0` or `development` instead of `main`. GitHub's automatic classification gets it wrong too.

## Gates

```bash
./check.sh
```

Checks that the front-matter `name` matches the directory, that every skill declares its
`**Not applicable**` boundary, and that it closes §8 with the arbitration formula (*if the web
contradicts this document, the web wins*). The **trigger-collision test** lives inside the
meta-skill `skills/claude-code-skills-standards/SKILL.md` §4.3.

## Licence

GPL-3.0. See [LICENSE](LICENSE).
