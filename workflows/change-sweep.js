export const meta = {
  name: 'change-sweep',
  description: 'Apply one mechanical change across many files, each in an isolated worktree, and verify every result',
  whenToUse: 'A migration or rename that is identical in shape across N files. Worktree isolation is what stops parallel edits colliding; without it this must run sequentially.',
  phases: [
    { title: 'Discover', detail: 'find the sites, if a list was not supplied' },
    { title: 'Transform', detail: 'one agent per file, isolated, five at a time' },
    { title: 'Verify', detail: 'check each result independently of the agent that made it' },
  ],
}

const WIDTH = 5
async function pool(items, fn) {
  const out = new Array(items.length)
  let next = 0
  await Promise.all(
    Array.from({ length: Math.min(WIDTH, items.length) }, async () => {
      while (next < items.length) {
        const i = next++
        out[i] = await fn(items[i], i)
      }
    }),
  )
  return out
}

const SITES = {
  type: 'object',
  required: ['files'],
  additionalProperties: false,
  properties: { files: { type: 'array', items: { type: 'string' } } },
}

const RESULT = {
  type: 'object',
  required: ['file', 'changed', 'summary'],
  additionalProperties: false,
  properties: {
    file: { type: 'string' },
    changed: { type: 'boolean' },
    summary: { type: 'string' },
    skippedBecause: { type: 'string', description: 'why no change was made, when changed is false' },
  },
}

const CHECK = {
  type: 'object',
  required: ['file', 'correct', 'reason'],
  additionalProperties: false,
  properties: {
    file: { type: 'string' },
    correct: { type: 'boolean' },
    reason: { type: 'string' },
    residue: { type: 'array', items: { type: 'string' }, description: 'anything the change was not supposed to touch but did' },
  },
}

const instruction = args && args.instruction
if (!instruction) return { error: 'change-sweep needs {instruction, files?}: what the change is, and optionally where' }

phase('Discover')
const sites = args.files
  ? { files: args.files }
  : await agent(
      `Find every file that needs this change: ${instruction}\n\n` +
        `Search, do not read on spec. Return paths only -- no analysis, no proposed edits.`,
      { label: 'discover', phase: 'Discover', schema: SITES },
    )

const files = (sites && sites.files) || []
if (!files.length) return { error: 'no files matched; nothing to sweep' }
log(`${files.length} files, five at a time, each in its own worktree`)

phase('Transform')
const done = await pool(files, (file) =>
  agent(
    `In ${file}, apply exactly this change and nothing else: ${instruction}\n\n` +
      `Do not fix unrelated defects you notice -- report them in the summary instead. If the file ` +
      `does not actually need the change, say so and change nothing: a forced edit is worse than a ` +
      `skip. Edit with Edit or Write so the change is reviewable.`,
    { label: `edit:${file}`, phase: 'Transform', schema: RESULT, isolation: 'worktree' },
  ),
)

phase('Verify')
const touched = done.filter((r) => r && r.changed)
const checks = await pool(touched, (r) =>
  agent(
    `Independently check ${r.file}. The change requested was: ${instruction}\n` +
      `The agent that made it reported: ${r.summary}\n\n` +
      `Read the file yourself and decide whether the change is actually correct and complete. ` +
      `Run the linter or type checker if one applies. List anything it touched that the change ` +
      `was not supposed to touch.`,
    { label: `check:${r.file}`, phase: 'Verify', schema: CHECK },
  ),
)

const failedToRun = done.filter((r) => !r).length
const skipped = done.filter((r) => r && !r.changed).map((r) => ({ file: r.file, why: r.skippedBecause || r.summary }))
const bad = checks.filter((c) => c && !c.correct)

// Silence about what did not happen reads as full coverage. It is not.
log(`changed ${touched.length} · skipped ${skipped.length} · failed to run ${failedToRun} · verification rejected ${bad.length}`)

return {
  instruction,
  attempted: files.length,
  changed: touched.map((r) => r.file),
  skipped,
  agentsThatDied: failedToRun,
  rejectedByVerification: bad,
  verificationsThatDied: checks.filter((c) => !c).length,
}
