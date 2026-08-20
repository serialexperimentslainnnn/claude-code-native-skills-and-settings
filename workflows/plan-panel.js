export const meta = {
  name: 'plan-panel',
  description: 'Draft a design from several independent angles, judge them against each other, and synthesise the winner',
  whenToUse: 'A decision wide enough that the first plausible answer is probably not the best one. One attempt iterated converges on its own first idea; independent attempts judged against each other do not.',
  phases: [
    { title: 'Draft', detail: 'three independent plans, deliberately different angles' },
    { title: 'Judge', detail: 'each plan scored by three lenses' },
    { title: 'Synthesise', detail: 'build from the winner, graft the best of the rest' },
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

// Different angles, not different wordings of one angle. Three drafters that would all
// reach for the same shape are one drafter with a bigger bill.
const ANGLES = [
  { key: 'smallest', brief: 'the smallest thing that solves the problem well. Reject every part that is not load-bearing; name what you deliberately left out and what would have to happen before it is earned.' },
  { key: 'failure', brief: 'start from how it breaks. Enumerate the failure modes, the concurrency and partial-failure cases, and design backwards from surviving them.' },
  { key: 'operator', brief: 'start from whoever runs and debugs this at three in the morning. Design for the diagnosis, the rollback and the observability first; the happy path second.' },
]

const LENSES = ['correctness', 'operability', 'cost of being wrong']

const PLAN = {
  type: 'object',
  required: ['approach', 'steps', 'tradeoffs', 'rejected'],
  additionalProperties: false,
  properties: {
    approach: { type: 'string', description: 'one paragraph: the shape of the solution' },
    steps: { type: 'array', items: { type: 'string' } },
    tradeoffs: { type: 'array', items: { type: 'string' } },
    rejected: { type: 'array', items: { type: 'string' }, description: 'what was considered and left out, and why' },
    unknowns: { type: 'array', items: { type: 'string' }, description: 'what would have to be checked before committing' },
  },
}

const SCORE = {
  type: 'object',
  required: ['score', 'reason', 'fatal'],
  additionalProperties: false,
  properties: {
    score: { type: 'integer', minimum: 1, maximum: 5 },
    reason: { type: 'string' },
    fatal: { type: 'boolean', description: 'true if this plan fails outright on this lens, whatever its score' },
    steal: { type: 'string', description: 'the one idea here worth taking even if this plan loses' },
  },
}

const question = typeof args === 'string' ? args : args && args.question
if (!question) return { error: 'plan-panel needs a question: /plan-panel <the decision to make>' }

phase('Draft')
const plans = await pool(ANGLES, (a) =>
  agent(
    `Design an approach to this:\n\n${question}\n\nYour angle: ${a.brief}\n\n` +
      `Read whatever code you need before proposing anything -- a plan written without looking is a ` +
      `guess. Do not hedge across several options: commit to one and defend it.`,
    { label: `draft:${a.key}`, phase: 'Draft', schema: PLAN },
  ).then((p) => (p ? { angle: a.key, plan: p } : null)),
)

const drafted = plans.filter(Boolean)
if (!drafted.length) return { error: 'every drafter failed' }
if (drafted.length < ANGLES.length) log(`${ANGLES.length - drafted.length} drafters died; judging ${drafted.length}`)

phase('Judge')
const jobs = drafted.flatMap((d) => LENSES.map((lens) => ({ d, lens })))
const scored = await pool(jobs, (j) =>
  agent(
    `Judge this plan for "${question}" through one lens only: ${j.lens}.\n\n` +
      `${JSON.stringify(j.d.plan, null, 2)}\n\n` +
      `Be a hostile reviewer, not a supportive one. Mark it fatal if it fails outright on your lens ` +
      `regardless of its other merits. Name the single idea worth stealing even if the plan loses.`,
    { label: `judge:${j.d.angle}/${j.lens}`, phase: 'Judge', schema: SCORE },
  ).then((s) => ({ angle: j.d.angle, lens: j.lens, verdict: s })),
)

const tally = drafted.map((d) => {
  const mine = scored.filter((s) => s && s.angle === d.angle && s.verdict)
  return {
    angle: d.angle,
    plan: d.plan,
    total: mine.reduce((n, s) => n + s.verdict.score, 0),
    fatal: mine.some((s) => s.verdict.fatal),
    steals: mine.map((s) => s.verdict.steal).filter(Boolean),
    critiques: mine.map((s) => `${s.lens}: ${s.verdict.reason}`),
  }
})

// A fatal verdict outranks a high total: a plan that fails on one lens does not win
// because it scored well on the other two.
const ranked = tally.slice().sort((a, b) => Number(a.fatal) - Number(b.fatal) || b.total - a.total)
const winner = ranked[0]
if (winner.fatal) log('every plan drew a fatal verdict; synthesising from the least bad and saying so')

phase('Synthesise')
const final = await agent(
  `Produce the plan of record for:\n\n${question}\n\n` +
    `The winning approach (${winner.angle}${winner.fatal ? ', which still drew a FATAL verdict' : ''}):\n` +
    `${JSON.stringify(winner.plan, null, 2)}\n\n` +
    `What the judges said about it:\n${winner.critiques.join('\n')}\n\n` +
    `Ideas worth grafting from every plan, including the losers:\n` +
    `${tally.flatMap((t) => t.steals).map((s) => `- ${s}`).join('\n')}\n\n` +
    `Rejected approaches, so they are not re-proposed later:\n` +
    `${ranked.slice(1).map((t) => `- ${t.angle}: ${t.plan.approach}`).join('\n')}\n\n` +
    `Write one plan: the steps, what was rejected and why, what remains unverified, and -- if the ` +
    `winner drew a fatal verdict -- say plainly that no approach survived judging and what would ` +
    `have to change.`,
  { label: 'synthesise', phase: 'Synthesise' },
)

return { question, winner: winner.angle, anyFatal: tally.some((t) => t.fatal), ranking: ranked.map((t) => ({ angle: t.angle, total: t.total, fatal: t.fatal })), plan: final }
