export const meta = {
  name: 'catalogue-audit',
  description: 'Sweep the skill catalogue for stale verification dates, dangling boundary citations and trigger collisions',
  whenToUse: 'Maintenance of skills/. Finds what check.sh cannot: a criteria date that has aged out, a **Not applicable** line citing a slug that no longer exists, and descriptions whose triggers overlap enough to make routing a coin flip.',
  phases: [
    { title: 'Inventory', detail: 'list the catalogue' },
    { title: 'Inspect', detail: 'one agent per skill, five at a time' },
    { title: 'Correlate', detail: 'cross-skill checks that need every result at once' },
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

const INVENTORY = {
  type: 'object',
  required: ['slugs'],
  additionalProperties: false,
  properties: { slugs: { type: 'array', items: { type: 'string' } } },
}

const INSPECTION = {
  type: 'object',
  required: ['slug', 'verifiedAs', 'cites', 'triggerTerms', 'problems'],
  additionalProperties: false,
  properties: {
    slug: { type: 'string' },
    verifiedAs: { type: 'string', description: 'the "Criteria verified as of" value, or empty if absent' },
    cites: { type: 'array', items: { type: 'string' }, description: 'slugs named in the section 1 boundary line' },
    triggerTerms: { type: 'array', items: { type: 'string' }, description: 'artifact-level trigger terms from the description: extensions, filenames, binaries, product names. No generic words' },
    problems: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'what'],
        additionalProperties: false,
        properties: {
          severity: { type: 'string', enum: ['blocking', 'stale', 'cosmetic'] },
          what: { type: 'string' },
        },
      },
    },
  },
}

const only = args && args.slugs

phase('Inventory')
const inv = only
  ? { slugs: only }
  : await agent('List every directory name under skills/ that contains a SKILL.md. Names only.', {
      label: 'inventory',
      phase: 'Inventory',
      schema: INVENTORY,
    })

const slugs = (inv && inv.slugs) || []
if (!slugs.length) return { error: 'no skills found under skills/' }
log(`${slugs.length} skills to inspect, five at a time`)

phase('Inspect')
const seen = await pool(slugs, (slug) =>
  agent(
    `Read skills/${slug}/SKILL.md. Do NOT rewrite it and do NOT verify its content against the web ` +
      `-- that is a different job. Report only its structure:\n\n` +
      `- the "Criteria verified as of" value, verbatim, or empty if the line is missing\n` +
      `- every skill slug cited in its section 1 "Not applicable" boundary line\n` +
      `- the artifact-level trigger terms in its frontmatter description: extensions, filenames, ` +
      `binaries, framework and product names. Exclude generic vocabulary -- it is tokeniser noise\n` +
      `- structural problems: a missing boundary line, a missing arbitration close in section 8, ` +
      `a description that triggers on concepts rather than artifacts, or prose that teaches instead ` +
      `of fixing a decision`,
    { label: slug, phase: 'Inspect', schema: INSPECTION },
  ),
)

// A barrier is correct here and only here: dangling citations and trigger collisions are
// both cross-skill properties, undecidable from any single inspection.
phase('Correlate')
const ok = seen.filter(Boolean)
if (ok.length < seen.length) log(`${seen.length - ok.length} inspections failed; the correlation below is incomplete and says so`)

const present = new Set(ok.map((s) => s.slug))
const dangling = ok
  .map((s) => ({ slug: s.slug, missing: s.cites.filter((c) => !present.has(c)) }))
  .filter((r) => r.missing.length)

const undated = ok.filter((s) => !s.verifiedAs).map((s) => s.slug)

const collisions = []
for (let i = 0; i < ok.length; i++) {
  for (let j = i + 1; j < ok.length; j++) {
    const a = ok[i]
    const b = ok[j]
    const shared = a.triggerTerms.filter((t) => b.triggerTerms.includes(t))
    if (shared.length >= 4) collisions.push({ pair: [a.slug, b.slug], shared })
  }
}

const blocking = ok.flatMap((s) => s.problems.filter((p) => p.severity === 'blocking').map((p) => ({ slug: s.slug, what: p.what })))

log(`${blocking.length} blocking · ${dangling.length} dangling citations · ${collisions.length} collisions · ${undated.length} undated`)

return {
  inspected: ok.length,
  inspectionsFailed: seen.length - ok.length,
  blocking,
  danglingCitations: dangling,
  triggerCollisions: collisions,
  undated,
  stale: ok.flatMap((s) => s.problems.filter((p) => p.severity === 'stale').map((p) => ({ slug: s.slug, what: p.what }))),
}
