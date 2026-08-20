export const meta = {
  name: 'repo-recon',
  description: 'Read an unfamiliar repository in parallel, ask what was missed, and draft its PROJECTMAP.md',
  whenToUse: 'First contact with a repository you have not worked in. Produces the orientation index instead of paying for the same grep, find and blind reads in every future session.',
  phases: [
    { title: 'Survey', detail: 'establish the real shape of the repository' },
    { title: 'Read', detail: 'one agent per subsystem' },
    { title: 'Critique', detail: 'what was not read, and would it have changed the map' },
    { title: 'Draft', detail: 'assemble PROJECTMAP.md' },
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

const SURVEY = {
  type: 'object',
  required: ['subsystems', 'buildCommand', 'testCommand'],
  additionalProperties: false,
  properties: {
    subsystems: {
      type: 'array',
      items: {
        type: 'object',
        required: ['path', 'why'],
        additionalProperties: false,
        properties: {
          path: { type: 'string' },
          why: { type: 'string', description: 'what this directory appears to own' },
        },
      },
    },
    buildCommand: { type: 'string', description: 'empty string if there is none' },
    testCommand: { type: 'string', description: 'empty string if there is none' },
    stack: { type: 'string' },
  },
}

const READING = {
  type: 'object',
  required: ['path', 'owns', 'entryPoints', 'conventions', 'landmines'],
  additionalProperties: false,
  properties: {
    path: { type: 'string' },
    owns: { type: 'string', description: 'one sentence: what decisions live here' },
    entryPoints: { type: 'array', items: { type: 'string' } },
    conventions: { type: 'array', items: { type: 'string' }, description: 'only what contradicts the ecosystem default' },
    landmines: { type: 'array', items: { type: 'string' }, description: 'what silently breaks, and by what mechanism' },
  },
}

const root = (args && args.path) || (typeof args === 'string' ? args : '.')

phase('Survey')
const survey = await agent(
  `Establish the real shape of the repository at ${root}. Use \`git ls-files\` rather than \`find\`: ` +
    `it skips ignored and generated noise for free. Identify the directories that actually own ` +
    `distinct concerns -- not every directory, only the ones a newcomer must understand -- plus the ` +
    `build and test commands as they really are, read from the manifests rather than assumed.`,
  { label: 'survey', phase: 'Survey', schema: SURVEY },
)

const subsystems = (survey && survey.subsystems) || []
if (!subsystems.length) return { error: 'survey found no subsystems; is the path a repository?' }
log(`${subsystems.length} subsystems · stack: ${survey.stack || 'unknown'}`)

phase('Read')
const readings = await pool(subsystems, (s) =>
  agent(
    `Read ${s.path} in the repository at ${root}. It appears to own: ${s.why}.\n\n` +
      `Report what a newcomer needs and could not deduce: what decisions live there, its entry ` +
      `points, the conventions that CONTRADICT the ecosystem default (skip the ones that match it, ` +
      `they cost context and add nothing), and the landmines -- what breaks silently, stated with ` +
      `its mechanism rather than as a warning.`,
    { label: `read:${s.path}`, phase: 'Read', schema: READING },
  ),
)

const solid = readings.filter(Boolean)
if (solid.length < readings.length) log(`${readings.length - solid.length} subsystem readings failed and are missing from the map`)

phase('Critique')
const critique = await agent(
  `Here is what was read of the repository at ${root}:\n\n${JSON.stringify(solid, null, 2)}\n\n` +
    `Survey said the build is "${survey.buildCommand}" and the tests are "${survey.testCommand}".\n\n` +
    `What is MISSING? Name directories nobody opened, claims asserted with no file behind them, ` +
    `and any question a newcomer would ask on day one that this does not answer. Be specific: a ` +
    `path, or a question. Do not restate what is already covered.`,
  { label: 'critique', phase: 'Critique' },
)

phase('Draft')
const map = await agent(
  `Draft PROJECTMAP.md for the repository at ${root}, following the \`project-map\` skill -- invoke ` +
    `it first, do not improvise the format.\n\nReadings:\n${JSON.stringify(solid, null, 2)}\n\n` +
    `Survey: ${JSON.stringify({ stack: survey.stack, build: survey.buildCommand, test: survey.testCommand })}\n\n` +
    `Gaps the critic found:\n${critique}\n\n` +
    `Store COMMANDS, never their output -- a measurement quoted in a map is stale the day after. ` +
    `Write the file to ${root}/PROJECTMAP.md and return the path plus anything you deliberately left out.`,
  { label: 'draft', phase: 'Draft' },
)

return { root, subsystemsRead: solid.length, gaps: critique, map }
