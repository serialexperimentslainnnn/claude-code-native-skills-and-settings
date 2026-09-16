# Claude Code Native — Skills and Settings

Configuration for **[Claude Code Native](https://github.com/serialexperimentslainnnn/claude-code-native)**,
the JetBrains plugin that runs Claude Code inside the IDE. The plugin gives Claude the IDE's tools;
this repository tells Claude how to use them and which engineering standards to apply. It installs
onto `~/.claude`.

## What the plugin changes

Inside the IDE, Claude Code's native tools (`Read`, `Edit`, `Write`, `Grep`, `Glob`, `Bash`) are
replaced by four MCP servers the plugin serves — `code`, `run`, `vcs`, `ops`. They resolve symbols
through the index, edit through the document model as reviewable diffs, build, test and debug through
the run system, drive Git and GitHub through the IDE's account, and work the Services panel. One call
carries a whole list of files, and the result is compact, so they spend a fraction of the tokens.

This repository makes Claude use them and keep using them as the conversation grows:

- `hook/how-to-work.md` — the working method, injected on **every prompt** by a `UserPromptSubmit`
  hook: the IDE's servers are the tools, batch every call, write everything first and build and test
  once at the end, plain commands, read every answer, signed atomic commits.
- `skills/ide-tools-standards/` — which IDE tool does each job, the `domains()` → `tools()` →
  `run()` ladder, the Security Guard, and the tool inventory in `references/{code,run,vcs,ops}.md`.
- `CLAUDE.md` — the rulebook: language, how skills load.

## Skills

`skills/` holds one file per domain — languages, cloud, containers, infrastructure, networking,
security, data, AI/ML, frontend, engineering craft, management, legacy platforms, verticals. Count
and index cost: `./check.sh`.

A skill is a criteria document, not a tutorial. Eight sections: scope and triggers, default
decisions with the reason, structure, quality gates, security, operability, forbidden anti-patterns,
and what to verify on the web before deciding. Every moving fact — versions, end-of-support dates,
licences, thresholds — is verified against its primary source or declared a gap; every body closes
with *if the web contradicts this document, the web wins*.

How they load: only each skill's one-line `description` is in context every turn; the body loads
when a task touches its domain. Descriptions trigger on **concrete artifacts** (`.tf`, `Chart.yaml`,
`cosign`, `nft`), and each skill's §1 names what is *not* its business so neighbours do not
collide. Always on: `load-expertise` (which skills a task activates), `lean-code-standards` (the
smallest correct diff), `tool-usage-standards` and `ide-tools-standards` (the instrument).

## Workflows

`workflows/` are orchestration scripts for Claude Code's Workflow runtime, installed as `/<name>`
commands. Each fans out subagents five at a time and reduces the result:

| Command | What it does | When |
|---|---|---|
| `/repo-recon` | Reads an unfamiliar repository in parallel, one agent per subsystem, asks what was missed, drafts `PROJECTMAP.md` | First contact with a repo |
| `/plan-panel` | Three independent designs from different angles, each judged by three lenses, the winner synthesised with the best of the rest | A decision where the first plausible answer is probably not the best |
| `/change-sweep` | One mechanical change across N files, each in its own worktree, every result verified by a different agent | A migration or rename identical in shape across many files |
| `/verify-claims` | Extracts every checkable fact from a document, verifies each against its primary source, then tries to refute what survived | A document asserting versions, flags, EOLs or thresholds |
| `/catalogue-audit` | Sweeps `skills/` for stale verification dates, boundary lines citing slugs that no longer exist, and trigger collisions | Catalogue maintenance; finds what `check.sh` cannot |

## Install

A JetBrains IDE with [Claude Code Native](https://plugins.jetbrains.com/plugin/31965-claude-code-native),
the `claude` CLI, `rsync` and `jq`:

```bash
git clone git@github.com:serialexperimentslainnnn/claude-code-native-skills-and-settings.git
cd claude-code-native-skills-and-settings
./install.sh --dry-run
./install.sh
```

The repo is the source; `~/.claude` is the destination. The installer copies `CLAUDE.md`,
`hook/how-to-work.md`, `skills/` and `workflows/` (one-way, timestamped backup first), writes the
hook into `~/.claude/settings.json` without touching `env`, `permissions` or `model`, and symlinks
the project memory into the repo. `./install.sh --uninstall` reverses it. Replace the
`[Insert …]` placeholders in `CLAUDE.md` and `hook/how-to-work.md` with your name and language.

**Without the plugin**, take only the catalogue — the skills work in any Claude Code; the hook and
the rulebook assume the IDE:

```bash
rsync -a skills/ ~/.claude/skills/
```

## Layout

| Path | What it is |
|---|---|
| `skills/<domain>-standards/` | The catalogue |
| `skills/ide-tools-standards/` | The IDE's tools: routing, the ladder, the guard, the inventory |
| `hook/how-to-work.md` · `hook/settings.sh` | The per-prompt method; the only code that touches `~/.claude/settings.json` |
| `workflows/*.js` | The five orchestration scripts |
| `CLAUDE.md` | The rulebook, installed as `~/.claude/CLAUDE.md` |
| `SKILL-TEMPLATE.md` | The canonical skill shape; outside `skills/` because any dir with a `SKILL.md` registers as a skill |
| `install.sh` · `check.sh` | Installer; gates (`name` = directory, `**Not applicable**` boundary, §8 close) |

## Licence

GPL-3.0 — see [LICENSE](LICENSE). *Claude* and *Claude Code* are trademarks of Anthropic, PBC;
*JetBrains* and the IDE names are trademarks of JetBrains s.r.o. Not affiliated with, sponsored by,
or endorsed by either.
