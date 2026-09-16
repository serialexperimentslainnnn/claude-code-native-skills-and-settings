# Claude Code Native — Skills and Settings

The Claude Code configuration for **[Claude Code Native](https://github.com/serialexperimentslainnnn/claude-code-native)**,
the plugin that runs Claude Code inside a JetBrains IDE and hands it the IDE itself: a rulebook, a
per-prompt hook, and an **IT engineering skill catalogue** — one criteria document per domain, verified
against primary sources — with a skill that tells Claude which of the IDE's tools does each job.

It is written for a session that lives in the IDE. The CLI's native tools (`Read`, `Edit`, `Write`,
`Grep`, `Glob`, `Bash`) are retired there: the plugin serves four MCP servers — `code`, `run`, `vcs`,
`ops` — that read through the index, edit through the document model, build, test, debug, drive Git and
the forge, and work the Services panel, batching a whole list per call for a fraction of the tokens. This
repository makes Claude use them, and keeps using them as the conversation grows.

## Install

Requirements: a JetBrains IDE with the
[Claude Code Native](https://plugins.jetbrains.com/plugin/31965-claude-code-native) plugin, the `claude`
CLI it runs, `rsync` and `jq`.

```bash
git clone git@github.com:serialexperimentslainnnn/claudeonstereoids.git
cd claudeonstereoids
./install.sh --dry-run   # shows what it will do, touching nothing
./install.sh
```

The repository is the single source of truth and `~/.claude` is a destination: **you work here, then you
install**. The installer copies `CLAUDE.md`, `hook/how-to-work.md`, `skills/` and `workflows/` onto
`~/.claude` (one-way, deleting in the destination what the repo no longer has, with a timestamped backup
first), writes the `UserPromptSubmit` hook into `~/.claude/settings.json` without touching your `env`,
`permissions` or `model`, and symlinks the project memory into the repo. `./install.sh --uninstall`
reverses all of it. Then open the project in the IDE and start a chat.

## What is here

| Path | What it is |
|---|---|
| `CLAUDE.md` | The rulebook, installed as `~/.claude/CLAUDE.md`: language, how skills load. |
| `hook/how-to-work.md` | The working method, **re-injected on every prompt** by the hook so it never fades: the IDE's servers are the tools, the batched loop, one build and one test run at the end, commits, docs as state. |
| `hook/settings.sh` | The only code that touches `~/.claude/settings.json`: installs, deduplicates and removes the hook. Sourced by `install.sh`. |
| `skills/ide-tools-standards/` | Which IDE tool does each job, the `domains()` → `tools()` → `run()` ladder, batching, the Security Guard; the inventory of the plugin's tools in `references/{code,run,vcs,ops}.md`. |
| `skills/<domain>-standards/` | The catalogue: what gets decided, what is forbidden and what must be verified before asserting it, per domain. Index: `skills/PROJECTMAP.md`. |
| `workflows/` | Orchestration scripts, installed as `/<name>` commands. |
| `SKILL-TEMPLATE.md` | The canonical skill shape. Outside `skills/` on purpose: any directory with a `SKILL.md` registers as a skill. |
| `PROJECTMAP.md` | The index of this repository. |
| `install.sh` · `check.sh` | Installer and mechanical gates. |

## How a skill is written

Eight fixed sections, body in English, a one-line `description` with triggers by **concrete artifact**
(extensions, config files, binaries, commands): that line is the only thing injected every turn, and
whether the skill activates depends on it. A skill fixes criteria; it does not teach. No concrete fact
from memory — versions, end-of-support dates, licences and figures are verified on the web, and what
cannot be verified is a **declared gap**, never filler. The rules are in
`skills/claude-code-skills-standards/SKILL.md`.

## Gates

```bash
./check.sh
```

Front-matter `name` equals the directory, every skill declares its `**Not applicable**` boundary, and
every §8 closes with the arbitration formula. The trigger-collision test lives in the meta-skill, §4.3.

## Licence

GPL-3.0 — see [LICENSE](LICENSE). *Claude* and *Claude Code* are trademarks of Anthropic, PBC;
*JetBrains* and the IDE names are trademarks of JetBrains s.r.o. This project is not affiliated with,
sponsored by, or endorsed by either.
