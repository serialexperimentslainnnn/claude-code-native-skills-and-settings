---
name: _template
description: CANONICAL TEMPLATE — not an activatable skill. Structural reference for authoring catalogue skills. Copy this file when creating a new one.
---

# CANONICAL SKILL TEMPLATE

> This file **is not a skill**: it is the structural reference for the `~/.claude/skills/`
> catalogue. When creating a new skill, copy it and replace.

## Front-matter rules (mandatory)

- `name`: kebab-case slug, `-standards` suffix, identical to the directory name.
- `description`: **in English, a single line**. It is the only thing injected every turn; whether
  the skill activates at all depends on its precision. **No hard word limit**: the rule is *zero
  filler and zero overlap with sibling skills*. A long description is justified when every term is
  a distinct trigger (cloud service names, for instance); a short but conceptual one ("best
  practices and quality") is worse.
  - Triggers by **concrete artefact**, not by concept: file extensions, config file names,
    binaries, frameworks, commands.
  - Correct: `Use when writing .py files, pyproject.toml, uv, ruff, FastAPI, Django...`
  - Wrong: `Use for Python best practices and quality` (triggers nothing).
  - Avoid terms already claimed by another skill in the same family (collision test).

## Body structure

Body in **English**. **Length is dictated by content, not by a quota**: the body is not loaded
until the skill activates, so going long costs no index. The criterion is **density**: every line
fixes a decision, a prohibition or something to verify. A dense domain (cryptography, networking,
GRC) may need 400+ lines; a niche legacy one stops at 80 and omits sections 4 and 6 if they would
be artificial. What is counterproductive is not size, it is filler: tutorials and prose bury the
decision the reader came for.

First line of the body, always:
`Criteria verified as of **<month-year>**. Re-verify on the web before committing to anything (§8).`

### 1. Scope and triggers
What it covers, with the concrete triggers. **Mandatory** closing boundary line:
`**Not applicable**: see <skill-x> (for …), <skill-y> (for …).`
Without this line the skill collides with its neighbours and routing degrades.

### 2. Default decisions / Toolchain
Table of concrete choices with minimum version and reason. Mandatory header:
`> Verify the latest version on the web before pinning it in a real project (§8).`
For criteria domains with no toolchain (architecture, process), replace with "Default decisions"
and a table of recommended option vs. justifiable alternative.

### 3. Structure and conventions
Layout, naming, organisation. One reference code block if it earns its place.

### 4. Quality and testing
Formatter, linter, static analysis, test strategy (happy path **plus edges and errors**), and the
**CI gates that break the build**, in order of increasing cost.

### 5. Stack security
OWASP applied to the domain, secrets, SCA/dependencies, specific hardening.

### 6. Performance and operability
Observability, timeouts, limits, graceful shutdown, capacity.

### 7. Long-term sustainability
Upgrade cadence, deprecation policy, and an **explicit list of prohibitions** (vetoed
anti-patterns, short-term shortcuts). Bullet format with ❌ or `FORBIDDEN`.

### 8. Mandatory web verification
What to check online before deciding: latest stable, EOL, CVEs, breaking changes, exact feature
names. Always close with:
`If the web contradicts this document, **the web wins** — flag the discrepancy.`

## Cross-cutting rules

- **Fix criteria, do not teach**: the model already knows how to program. The skill decides what to
  use, what is vetoed and what to verify. Zero tutorial, zero filler.
- **Extend `CLAUDE.md`, do not repeat it**: the cross-cutting doctrine is already there.
- **No concrete fact from memory**: versions, EOL, flags and names are verified on the web.
- **Offensive security skills**: §1 sets scope and written authorisation (or an own lab / CTF
  environment) as a hard precondition. §7 explicitly forbids including ready-made payloads, product
  bypasses or third-party default credentials: methodology and governance, not a cookbook.

## Enforced strings (do not paraphrase)

`./check.sh` greps for these literally. Changing the wording silently disables a gate:

- `**Not applicable**:` — the §1 boundary line.
- `If the web contradicts this document, **the web wins** — flag the discrepancy.` — the §8 close.
- `name:` in the front matter must equal the directory name.

> **Migration note (August 2026)**: the catalogue was written in Spanish and is being translated to
> English. While that lasts, `check.sh` accepts both the English strings above and their Spanish
> originals (`**No aplica**:` and `manda la web`). Once no Spanish body remains, drop the
> alternative from the gate patterns so a regression cannot pass unnoticed.
