# Global preferences

**Language: answer in [Insert Your Language Here] by default.** Use the project's language (code, docs, issues) when that
is the context.

**The working method (`How to work — strict, from [Insert your name here], no exceptions`) is not in this file on
purpose**: it arrives on every prompt through the `UserPromptSubmit` hook, from
`~/.claude/how-to-work.md`, so it never sinks as the conversation grows. If a turn arrives without
it, the hook is broken — say so.

## Skills — how they load

There is a **skill catalogue** (`~/.claude/skills/<domain>-standards/`) holding each domain's
criteria. Only each skill's one-line `description` is injected every turn; the body loads when the
task triggers it.

- **Before deciding anything in a domain, load its skill** with the `Skill` tool — before writing,
  not to justify what was written. Deriving which domains a task touches is itself a skill:
  `load-expertise`. Derive from the actual context (the stack, the files, the layer, what breaks
  if it is wrong), not from the words of the request.
- **State which skills you are working under** at the start of a substantial task, in one line.
- **It is almost never one skill**: co-activated skills are reconciled, not chosen between; each
  declares in §1 what is not its business. If two contradict each other, say so.
- **Re-arm when the task turns**: new file family, new layer (data, network, identity, money,
  personal data), design to operation, or deciding from memory instead of a document.
- **Always on, whatever the task**: `load-expertise`, `lean-code-standards` (any code, any
  language), `tool-usage-standards`; `claude-code-skills-standards` governs the catalogue itself.
- If a skill contradicts this document on a technical detail, the skill wins; if it contradicts
  the web, the web wins. Moving facts (versions, flags, APIs) are looked up, never recalled.
