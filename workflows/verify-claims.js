export const meta = {
  name: 'verify-claims',
  description: 'Check every moving fact in a document against its primary source, then try to refute what survived',
  whenToUse: 'A document asserts versions, flags, EOLs, thresholds or product names and you need to know which of them are still true. The characteristic defect of a criteria catalogue is a confident stale fact, and it never announces itself.',
  phases: [
    { title: 'Extract', detail: 'pull the checkable claims out of the document' },
    { title: 'Verify', detail: 'one agent per claim, against the primary source' },
    { title: 'Refute', detail: 'a second, adversarial pass over what survived' },
    { title: 'Report', detail: 'group by verdict, keeping the unverifiable visible' },
  ],
}

// Five in flight, never more. The runtime's own cap is 16 and parallel() hands it
// everything at once, so the ceiling has to live here. Module loading is unavailable
// in a workflow script, so this is repeated in every workflow rather than shared.
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

const CLAIMS = {
  type: 'object',
  required: ['claims'],
  additionalProperties: false,
  properties: {
    claims: {
      type: 'array',
      items: {
        type: 'object',
        required: ['text', 'kind', 'locator'],
        additionalProperties: false,
        properties: {
          text: { type: 'string', description: 'the assertion, quoted or tightly paraphrased' },
          kind: { type: 'string', enum: ['version', 'eol', 'flag', 'threshold', 'name', 'url', 'other'] },
          locator: { type: 'string', description: 'file and line, or section heading' },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  required: ['verdict', 'evidence'],
  additionalProperties: false,
  properties: {
    verdict: { type: 'string', enum: ['confirmed', 'refuted', 'unverifiable'] },
    evidence: { type: 'string', description: 'what the primary source actually says, quoted' },
    source: { type: 'string', description: 'the URL the evidence came from, empty when unverifiable' },
    correction: { type: 'string', description: 'the true value, when refuted' },
  },
}

const target = typeof args === 'string' ? args : args && args.path
if (!target) return { error: 'verify-claims needs a path: /verify-claims <file>' }

phase('Extract')
const found = await agent(
  `Read ${target}. List every assertion in it that could be false today because the world moved: ` +
    `version numbers, end-of-life dates, command flags, thresholds, default ports, product and ` +
    `service names, and URLs. Ignore claims of judgement, criteria and prohibitions -- they cannot ` +
    `be checked against a source. Quote each claim and give its location.`,
  { label: 'extract', phase: 'Extract', schema: CLAIMS },
)

const claims = (found && found.claims) || []
if (!claims.length) return { target, checked: 0, note: 'no checkable factual claims found' }
log(`${claims.length} checkable claims in ${target}`)

phase('Verify')
const verified = await pool(claims, (c, i) =>
  agent(
    `Verify this claim against its PRIMARY source -- the vendor's own documentation, changelog or ` +
      `release notes, never a blog or a summary:\n\n"${c.text}"\n\nContext: ${c.locator} (${c.kind}).\n\n` +
      `Search, then fetch the source and quote what it actually says. Return "unverifiable" rather ` +
      `than guessing when no primary source can be reached -- an unverifiable claim is a known gap, ` +
      `a guessed one is a new defect.`,
    { label: `verify:${i + 1}`, phase: 'Verify', schema: VERDICT },
  ).then((v) => ({ claim: c, first: v })),
)

// Only what survived is worth attacking: a claim already refuted needs no second opinion,
// and an unverifiable one has no source for a refuter to read either.
phase('Refute')
const survivors = verified.filter((r) => r.first && r.first.verdict === 'confirmed')
const attacked = await pool(survivors, (r, i) =>
  agent(
    `A previous check concluded this claim is CURRENT:\n\n"${r.claim.text}"\n\n` +
      `It cited: ${r.first.evidence}\nSource: ${r.first.source}\n\n` +
      `Your job is to REFUTE it. Look for a newer release, a superseding document, a deprecation ` +
      `notice, a renamed flag, or a source that contradicts the one cited. Default to refuted=false ` +
      `only if you genuinely cannot find contrary evidence after looking.`,
    { label: `refute:${i + 1}`, phase: 'Refute', schema: VERDICT },
  ).then((v) => ({ ...r, second: v })),
)

phase('Report')
const attackedByText = new Map(attacked.map((r) => [r.claim.text, r]))
const rows = verified.map((r) => {
  const second = attackedByText.get(r.claim.text)
  const overturned = second && second.second && second.second.verdict === 'refuted'
  return {
    claim: r.claim.text,
    at: r.claim.locator,
    verdict: overturned ? 'refuted' : r.first ? r.first.verdict : 'unverifiable',
    evidence: overturned ? second.second.evidence : r.first && r.first.evidence,
    correction: overturned ? second.second.correction : r.first && r.first.correction,
    source: overturned ? second.second.source : r.first && r.first.source,
    overturnedOnSecondPass: Boolean(overturned),
  }
})

const by = (v) => rows.filter((r) => r.verdict === v)
log(`confirmed ${by('confirmed').length} · refuted ${by('refuted').length} · unverifiable ${by('unverifiable').length}`)

return {
  target,
  checked: rows.length,
  refuted: by('refuted'),
  unverifiable: by('unverifiable'),
  confirmed: by('confirmed'),
}
