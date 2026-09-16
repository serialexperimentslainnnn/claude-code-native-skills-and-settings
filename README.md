# Claude Code Native — Skills and Settings

**More than two hundred engineering-standards skills, the doctrine that makes Claude apply them, and the
settings that bind it all to a JetBrains IDE through
[Claude Code Native](https://github.com/serialexperimentslainnnn/claude-code-native).** Install it and
the Claude you get is the one this catalogue was built for: staff-level by default, verified against
primary sources, batching every call, and refusing to assert a version, a flag or a licence from memory.

## The catalogue

`skills/` holds one criteria document per domain — languages and runtimes, cloud, platform and
containers, infrastructure and on-prem, networking, the whole security family (AppSec, SOC, offensive,
GRC, privacy), data and analytics, AI/ML and LLM, frontend and web, engineering craft, management,
legacy platforms, industry verticals. For the exact count, line total and index cost run `./check.sh`;
the per-domain index is `skills/PROJECTMAP.md`.

A skill here **does not teach** — the model already knows how to program. It fixes **what gets decided,
what is forbidden and what must be verified before asserting it**: default toolchains with the reason,
structure, the CI gates that break the build, the stack's security, operability, an explicit list of
vetoed anti-patterns, and what to check on the web before deciding — every body closes with *if the web
contradicts this document, the web wins*. No concrete fact from memory: versions, end-of-support dates,
licences (read raw from the file), RFC numbers and figures are verified, and what cannot be verified is a
**declared gap**, never filler. Folklore figures with no primary source were thrown out.

Each skill's one-line `description` is the only thing in context every turn, so triggers are **concrete
artifacts** — extensions, config files, binaries, commands — and every skill names in its §1 what is
*not* its business, so neighbours do not collide. The always-on set no request ever names:
`load-expertise` derives which skills a task activates, `lean-code-standards` keeps the diff the
smallest correct one, `tool-usage-standards` and `ide-tools-standards` decide the instrument.

## Inside the IDE

This configuration is written for a session that lives in the IDE. There the CLI's native tools
(`Read`, `Edit`, `Write`, `Grep`, `Glob`, `Bash`) are retired: the plugin serves four MCP servers —
`code`, `run`, `vcs`, `ops` — that read through the index, edit through the document model, refactor
with the refactoring engine, build, test and debug through the run system, drive Git and the forge
through the IDE's own account, and work the Services panel, a whole list per call for a fraction of the
tokens. Two pieces make Claude use them and keep using them as the conversation grows:

- `hook/how-to-work.md` — the working method, **re-injected on every prompt** by a `UserPromptSubmit`
  hook: the IDE's servers are the tools, the batched `search_text` → `read_file` → `replace_text` loop,
  write everything first and build and test once at the end, signed atomic commits, docs as state.
- `skills/ide-tools-standards/` — which of the IDE's tools does each job, the `domains()` →
  `tools(domain)` → `run(tool, args)` ladder, batching, the Security Guard, and the inventory of the
  plugin's tools in `references/{code,run,vcs,ops}.md`.

## Install

With the plugin — a JetBrains IDE with
[Claude Code Native](https://plugins.jetbrains.com/plugin/31965-claude-code-native), the `claude` CLI it
runs, `rsync` and `jq`:

```bash
git clone git@github.com:serialexperimentslainnnn/claudeonstereoids.git
cd claudeonstereoids
./install.sh --dry-run   # shows what it will do, touching nothing
./install.sh
```

The repository is the single source of truth and `~/.claude` is a destination: **you work here, then you
install**. The installer copies `CLAUDE.md`, `hook/how-to-work.md`, `skills/` and `workflows/` onto
`~/.claude` (one-way, deleting in the destination what the repo no longer has, with a timestamped backup
first), writes the hook into `~/.claude/settings.json` without touching your `env`, `permissions` or
`model`, and symlinks the project memory into the repo. `./install.sh --uninstall` reverses all of it.

**Without the plugin**, take only the catalogue — the skills work in any Claude Code; the hook and the
rulebook assume the IDE and would tell a terminal session it is somewhere it is not:

```bash
rsync -a --exclude=PROJECTMAP.md skills/ ~/.claude/skills/
```

## What is here

| Path | What it is |
|---|---|
| `skills/<domain>-standards/` | The catalogue. Index: `skills/PROJECTMAP.md`. |
| `skills/ide-tools-standards/` | The IDE's tools: routing, the ladder, the guard, the inventory. |
| `hook/how-to-work.md` · `hook/settings.sh` | The per-prompt method, and the only code that touches `~/.claude/settings.json`. |
| `CLAUDE.md` | The rulebook, installed as `~/.claude/CLAUDE.md`. |
| `workflows/` | Orchestration scripts, installed as `/<name>` commands. |
| `SKILL-TEMPLATE.md` | The canonical skill shape. Outside `skills/` on purpose: any directory with a `SKILL.md` registers as a skill. |
| `PROJECTMAP.md` | The index of this repository. |
| `install.sh` · `check.sh` | Installer and mechanical gates. |

## Writing a skill

Eight fixed sections, body in English, triggers by concrete artifact, a `**Not applicable**` boundary in
§1 and the arbitration close in §8. The rules are `skills/claude-code-skills-standards/SKILL.md`; the
shape is `SKILL-TEMPLATE.md`; `./check.sh` enforces the literals, and the trigger-collision test lives in
the meta-skill's §4.3. Contributions follow the same gates.

## Licence

GPL-3.0 — see [LICENSE](LICENSE). *Claude* and *Claude Code* are trademarks of Anthropic, PBC;
*JetBrains* and the IDE names are trademarks of JetBrains s.r.o. This project is not affiliated with,
sponsored by, or endorsed by either.
