---
name: technical-hiring-standards
description: A hiring process is a measuring instrument and is judged by its validity and reliability. Use when writing a role definition or job description before interviewing, building a scoring rubric and scorecard before seeing the first candidate, choosing between a work sample, a walkthrough of the candidate's own code, live problem solving, a system design interview or a structured behavioural interview, setting a take-home exercise and its time limit or deciding to pay for it, running an interview loop and a debrief, calibrating interviewers, citing predictive validity of selection methods (Schmidt & Hunter 1998, Sackett Zhang Berry & Lievens 2022), replacing "culture fit" with observable values, offering reasonable adjustments and alternative formats to a candidate, publishing stages, timelines and feedback, designing a technical test when candidates use AI assistants, screening applicants with an automated employment decision tool or a resume screener, NYC Local Law 144 bias audits, Illinois HB 3773 or the Colorado AI Act, pay transparency under Directive (EU) 2023/970 and salary ranges in job ads, retaining or deleting candidate data, or measuring hiring by post-hire performance and retention rather than time-to-fill.
---

# Technical hiring standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Covers **the design and execution of the technical selection process as a measuring instrument**:
role definition, rubric, choice of assessment formats and their evidence, interview
structure, interviewer calibration, decision, candidate experience, use of AI by both
parties, and onboarding as the last stage of the process.

Triggers: "role definition", "job description", "rubric", "scorecard", "assessment
criteria", "work sample", "technical test", "take-home", "homework exercise",
"pair programming in an interview", "system design interview", "behavioural
interview", "STAR", "structured interview", "interviewer calibration", "debrief",
"culture fit", "culture add", "reasonable adjustments", "candidate experience", "candidate
feedback", "AI in the interview", "automated CV screening", "ATS", "AEDT", "bias audit", "AI
Act employment", "pay transparency", "salary range in the ad", "candidate data",
"onboarding", "time to fill", "retention".

**Guiding principle**: **a hiring process is a measuring instrument, and as such it is judged
by its validity and its reliability, not by how good it feels.** *Validity*: does it measure what predicts
performance in **this** role? *Reliability*: do two different interviewers, or the same one on two
different days, reach the same conclusion? **A process that cannot answer those two questions is not
selecting: it is recording impressions and calling them data.** A falsifiable test applicable to
any proposed stage: **name what signal it produces, with which rubric it is scored, and what decision
would change if that stage did not exist.** Whatever does not pass it is removed — every stage costs team
time and candidates who drop out.

**Scope warning — read before applying anything in this document.** Hiring carries **real
legal obligations**: non-discrimination, protection of candidates' personal data and
**specific rules on the use of AI in employment decisions**. This document fixes **engineering
and process criteria**; **it is not legal or HR advice**. Every decision
with legal effect —wording of job ads, admissible questions, legal bases for processing,
deployment of an automated screening tool, pay policy— **is checked with
legal counsel and with the organisation's HR function before being applied**, and in the
specific jurisdiction. The regulatory references in §5 are a map of where to ask, not a
ruling.

**Not applicable**:
- `tech-leadership-standards` (**already written**): **reciprocal and strict**. There it is decided **which profile
  is needed, why, which gap in the team it fills and which level of the ladder it corresponds to**; here,
  **how a candidate is measured against that definition**. One-sentence boundary: **leadership
  defines the role; this process is the measuring instrument.** Also theirs are subsequent
  development, performance evaluation and departure from the team.
- `privacy-engineering-standards`: **candidates' personal data is theirs** — legal basis,
  minimisation, retention periods, data subject rights, erasure and DPIA. Here only the
  obligation that the process respects them and **the prohibition on keeping what is not going to be used**
  (§5).
- `grc-compliance-standards`: **the applicable regulatory framework and the formal evidence** — which rule
  obliges, how compliance is demonstrated to an auditor, register of regulatory risks.
- `ai-governance-standards`: **the use of AI in decisions affecting people and its risk
  classification are theirs** — system inventory, status as provider or deployer,
  fundamental rights impact assessment, meaningful human oversight.
  Here, **the concrete practice of the selection process** (§5): what can be automated, what requires
  a person, and what the candidate is told.
- `accessibility-standards` (**already written**): **conformance and adjustments are theirs** — WCAG, EN 301 549,
  accessible formats. Here, the obligation to offer them at every stage and not to penalise anyone for
  asking for them (§3.7).
- `identity-access-management-standards`: **access provisioning and deprovisioning** at onboarding and at
  departure — provisioning, least privilege, dated revocation. Here only that the onboarding
  plan includes them and that revocation is verifiable (§6).
- `knowledge-management-standards`: **the documentation that makes a fast
  onboarding possible** — where it lives, who maintains it, how staleness is detected. Here
  only that the first week of a new joiner is the best auditor that documentation will ever
  have (§6).
- `code-review-standards`: the criteria for reviewing a real diff. It is **reused** when evaluating a
  candidate's code, it is not reinvented here.
- `project-management-standards`: hiring as a project with deadlines and stakeholders.
- `ai-agent-workflow-standards` (**already written**): the team policy on coding agents
  in day-to-day work. Here, **what it implies for test design** that the candidate uses one
  (§5.1).

## 2. Default decisions

> Verify on the web the status of the sources and of the rules cited before applying them (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Before publishing the ad | **Written role definition**: problem it solves, evidence that would demonstrate it, level of the ladder (§3.1) | — |
| Rubric | **Written and agreed before seeing the first candidate** (§3.2) | Never "after the first interviews, once we know what we are looking for" |
| Interview structure | **Structured**: same questions, same order, same scale, for every candidate for the same role | — |
| Main assessment format | **Work sample** or **walkthrough of the candidate's own code** (§3.3) | Live problem solving with a realistic brief |
| Whiteboard algorithm puzzles | **Not used** unless the role actually requires them (§3.3, §7) | — |
| Take-home exercise | **≤ 2-3 h declared and respected**, or **it is paid for** (§3.4) | Replace it with a guided session of the same duration |
| System design | Only if the role designs systems; with a problem from the real domain | — |
| Behaviour / experience | **Structured behavioural interview** with fixed questions and behavioural anchors | — |
| "Culture fit" | **Forbidden as a criterion** (§3.6, §7). Replaced by **observable values and behaviours** with anchors | — |
| Scoring | **Each interviewer writes their evidence and their score BEFORE the discussion** (§3.5) | — |
| Decision | **Against the rubric, with evidence cited**; a tie = no hire and the process is reviewed | — |
| Number of stages | **The minimum that produces a distinct signal at each one** (by default ≤ 3-4 contacts) | More stages only with demonstrable new signal |
| AI screening | **Never decides**: at most it ranks or labels, with a person reviewing and a record (§5.2) | — |
| Pay transparency | **Range published in the ad** (§5.3) | — |
| Headline metric | **Subsequent performance and retention** (§6), not time to fill | — |

### Evidence on selection methods: the two sources, and why both are needed

**This is the point most frequently miscited in all of engineering.** There is a heavily
cited classic meta-analysis and a later review that corrected its figures **downwards**. Citing only the first is
citing an estimate that its own successors consider inflated; citing only the second, without the
critique that motivated it, is giving a number without its history.

**(A) The classic.** **Frank L. Schmidt and John E. Hunter, "The validity and utility of selection
methods in personnel psychology: Practical and theoretical implications of 85 years of research
findings", *Psychological Bulletin* 124(2):262-274 (1998)**, DOI 10.1037/0033-2909.124.2.262.
It synthesises the validity of **19 procedures** for predicting job and training performance.
Most-cited values: **general mental ability ≈ .51**, **structured interview ≈ .51**,
**unstructured interview ≈ .38**; combination of structured interview + ability ≈ .63.
**The method, which is what almost nobody cites**: these are correlations **corrected** for measurement error
in the criterion (usually supervisor ratings) and for **range restriction**. That
correction is exactly what was later called into question.

**(B) The review that corrected them downwards.** **Paul R. Sackett, Charlene Zhang, Christopher M.
Berry and Filip Lievens, "Revisiting meta-analytic estimates of validity in personnel selection:
Addressing systematic overcorrection for restriction of range", *Journal of Applied Psychology*
107(11):2040-2068 (2022)**, DOI 10.1037/apl0000994 (online 30-Dec-2021). **Verbatim from the abstract**,
extracted from the PDF, not from a commentary: *"After outlining and critiquing five approaches that have
commonly been used to create and apply range restriction artifact distributions, we conclude that
each has significant issues that often result in substantial overcorrection and that therefore the
validity of many selection procedures for predicting job performance has been substantially
overestimated. Revisiting prior meta-analytic conclusions produces revised validity estimates. Key
findings are that most of the same selection procedures that ranked high in prior summaries remain
high in rank, but with mean validity estimates reduced by .10–.20 points. Structured interviews
emerged as the top-ranked selection procedure. […] We conclude that our selection procedures remain
useful, but selection predictor–criterion relationships are considerably lower than previously
thought."*

Revised operational validity estimates **extracted from the article itself** (with their method
alongside, because without it the figure means nothing):

| Method | Sackett et al. (2022) | Provenance declared in the article |
|---|---|---|
| **Structured interview** | **.42** | N-weighted mean of McDaniel et al. (1994) and Huffcutt et al. (2014), corrected only for criterion reliability (.60), **without correction for range restriction** |
| **Un**structured interview | **.19** | Same provenance |
| Job knowledge test | **.40** | Dye et al. (1993), subset of job-specific tests; correction only for reliability |
| General mental ability | **≈ .31** | Mean observed validity .236; no correction for range restriction considered defensible |
| Situational judgment test (SJT) | **.26** | McDaniel et al. (2007); .20 observed, corrected for reliability .60 |
| Integrity test | **.31** | **Weighted mean of two irreconcilable meta-analyses (see discrepancy)** |

Aggregate change, **verbatim from the article**: *"The mean across Schmidt and Hunter's top five was .49,
while the mean across our top five is .37."* The reordering matters: **the structured interview
becomes the strongest predictor** —Schmidt-Hunter placed cognitive ability as the focal predictor—
and *"the strongest predictors in our re-analysis (structured interviews, job knowledge tests,
empirically keyed biodata, and work samples) are all job-specific measures"*.

**Declared discrepancies, exactly as the article itself declares them:**
- **Integrity tests**: two high-quality meta-analyses give **.44 and .18**. Sackett and Schmitt
  (2012) tried to reconcile them and **failed**; the raw data of one of them are not
  available. The **.31** in the table is a **weighted mean of two results nobody
  knows how to reconcile**, not a consensus. Practical consequence: **do not base a process decision
  on integrity tests**.
- **The mean does not apply to your organisation.** The article insists on this: it publishes a residual
  standard deviation precisely as *"an essential reminder that a given employer cannot count on
  the mean value as applicable to their organization"*. **A mean validity of .42 does not mean that
  your structured interview is worth .42**; it means the method can get there if it is well
  built.
- **Validity and diversity do not go together.** The article pairs validity with mean differences between
  subgroups: within its "top five", **work samples, knowledge tests and cognitive
  tests show substantial differences**, whereas **structured interviews, biodata and
  integrity show much smaller ones**. Related work by the same authors concludes that
  **excluding cognitive tests barely affects validity and substantially reduces
  adverse impact**. This is process design criteria, not a footnote.
- **Work samples**: they remain in the "top five" and drop relative to Schmidt-Hunter, but **the
  exact revised value was not extracted in this verification** — a declared gap in §8. **No figure is
  written for work samples until it is confirmed in the article.**
- **Intermediate update**: Schmidt, Oh and Shaffer (2016) already lowered work samples
  relative to 1998 and added new predictors. There is also Sackett et al. (2023), *Industrial and
  Organizational Psychology* 16(3):283-300, with the applied implications.

**How these figures are used, and this is the only thing that matters operationally:**
1. **As an order of preference between methods**, not as a prediction of outcome. The conclusion
   robust across both sources: **structuring the interview is the highest-impact change
   available** — the same format, structured or not, goes from ~.42 to ~.19 (2022) or from ~.51 to ~.38
   (1998). **No other cheap intervention moves the needle as much.**
2. **Never as a number in a job ad, a slide or a discussion with management** without its year, its
   correction and its interval. A correlation of .42 explains a modest fraction of the variance:
   **an excellent process still gets it wrong often**, and a process that promises otherwise
   is lying.
3. **Citing only Schmidt-Hunter 1998 is forbidden.** Its own figures have been corrected downwards by
   the later literature (§7).

### Famous figures: what is NOT used as data

- ❌ **"The cost of a bad hire is 1.5 times the salary"** (and its variants: 30 % of
  first-year compensation "according to the US Department of Labor", 213 %, $240,000).
  **There is no locatable primary study.** What there is, is citation drift: SBA data on
  the cost of **hiring** (1.25-1.4× base) turned into the cost of a **bad** hire;
  SHRM ranges cited inconsistently with each other (½-2×, 50-200 %, bands by level); a 30 %
  attributed to the DOL **with no report title, year or methodology**; the 213 % that actually comes
  from a Center for American Progress (2012) meta-analysis on **turnover**, not on bad
  hires; a self-reported CareerBuilder survey (2011); and a $240,000 figure that
  is **one recruiter's estimate**. Add that almost all the sources spreading it **sell
  hiring services**. **It is not written.** If a number is needed to decide, **it is
  built bottom-up with your own data**: recruitment spend, salary paid, ramp-up time
  and the cost of repeating the process.
- ❌ **Turnover percentages attributed to "a bad boss"** and **"people leave managers, not companies"**:
  discarded with their refutation in `tech-leadership-standards` §2.
- ❌ **Any "the best engineers are 10x" figure** used to justify a salary band
  or a hiring bar: the foundational figure is dismantled
  (`tech-leadership-standards` §2, Prechelt 1999).
- ❌ **Conversion and "candidates per opening" statistics from ATS vendors** without a published sample or
  method.

**General rule**: **a figure with a primary source, year, sample and method, or it is not written.**

## 3. Structure and conventions

### 3.1 Define the role before interviewing

**No process is opened without this document.** Three questions, answered in writing by whoever
leads technically (`tech-leadership-standards`):

1. **What problem does this person solve over the next 12 months?** Concrete and verifiable. *"Make
   the billing service safe to change: today it accounts for 3 out of every 7 incidents"*, not
   *"strengthen the backend team"*.
2. **What evidence would demonstrate that they can do it?** The stages of the process come out of this. If a
   proposed stage does not produce evidence from this list, **it is surplus**.
3. **Which level of the published ladder is it, and in which pay band?** Decided **before**
   meeting candidates. Adjusting the level to the candidate who turned up is how internal grievances
   and pay inequities get built — the ones you then have to audit.

Rules:
- **Separate requirements from wishes.** A requirement is something without which the person **cannot** do the
  job from the first month. Everything else is desirable and **does not filter**. Inflated
  requirement lists shrink the candidate pool asymmetrically and without gaining signal.
- **Asking for years of experience as a substitute for competence is forbidden** (§7). "5 years of X" is not
  a skill; it is a datum that correlates poorly and that excludes non-linear trajectories. You ask for
  the capability and you measure it.
- **Asking for experience in a technology for longer than that technology has existed is forbidden**
  — the classic mistake, and a reliable indicator that nobody read the ad.
- **The ad declares**: pay band (§5.3), working arrangement, the process stages with their
  duration, and who decides. **The absence of a band is a signal to the candidate, and it is the correct one.**

### 3.2 The rubric: written before the first candidate

**If there is no written rubric before seeing the first candidate, you are not measuring competence: you
are measuring personal impression, and justification will be sought afterwards.** This is not an opinion about
style: it is the difference between a structured and an unstructured interview, which is the factor with the
largest documented effect on validity (§2).

Minimum format per competency:

```yaml
competency: Systems design under real constraints
why_it_matters: "The role defines interfaces between 3 teams; a bad contract costs quarters"
assessed_in: [design exercise, walkthrough of own code]
scale:
  1_does_not_meet: "Proposes a solution without asking about constraints or volume"
  2_partial:       "Asks about constraints; does not reason about failure or evolution"
  3_meets:         "States assumptions, reasons about failure and cost, proposes an alternative and rejects it with a reason"
  4_exceeds:       "Also identifies the trade-off the brief was hiding and proposes how to validate it cheaply"
evidence_required: "Verbatim quote or description of what the person did or said. Without a quote, the score does not count"
```

- **Behavioural anchors, not adjectives.** "Good communication" is not an anchor. "Explained a
  technical decision to someone without context and checked that it had been understood" is.
- **Even scale (1-4)** to force a decision; the midpoint of an odd scale absorbs half the
  scores and destroys the signal.
- **The rubric is the same for every candidate for the role**, and it is archived with the process.
- **Changing the rubric mid-process invalidates the previous comparisons.** If it has to be
  changed, it is declared, and the candidates already assessed are re-assessed or dropped from the
  comparison set — **they are not mixed**.
- **Every interviewer knows which competencies are theirs and which are not.** Two interviewers measuring
  the same thing is a wasted stage; a competency with no owner is a gap that will be filled with
  intuition.

### 3.3 Formats: what each one is for

| Format | What it really measures | When it is used | Typical failure |
|---|---|---|---|
| **Work sample** (task representative of the role, in a realistic environment) | Ability to do the job | Almost always; it is the format with the best behaviour-criterion correspondence | It turns into an artificial exam and stops being a sample |
| **Walkthrough of the candidate's own code** (or of a project of theirs) | Technical judgement, ability to explain decisions, honesty about trade-offs | **Excellent alternative when the person has their own material**; near-zero cost to the candidate | Penalises anyone who cannot show code (NDA, sector, no free time): **an equivalent alternative must exist** |
| **Live problem solving** on a realistic brief, with support | How they think when they do not know, how they ask, how they debug | When the process matters more than the result | It turns into an exam with an audience; the interviewer talks more than the candidate |
| **System design** | Reasoning about constraints, failure, evolution and cost | Only if the role designs systems | It is scored by matching the interviewer's solution instead of by the quality of the reasoning |
| **Structured behavioural interview** (past situations, fixed questions, behavioural anchors) | Past behaviour in analogous situations | Always; it is the best-placed format in the revised evidence (§2) | It becomes unstructured on the fly and reverts to a chat |
| **Whiteboard algorithm puzzle** | **Mostly specific preparation for that kind of exam** | **Only if the role actually demands that work** (compilers, engines, crypto, embedded systems) | It is used by default for everything, filtering by free time to prepare and by familiarity with the format, not by ability |

Cross-cutting rules:
- **The brief resembles the work.** The further the test is from the real task, the more it measures
  something else — and that something else usually correlates with access, free time and cultural familiarity
  with the format.
- **Consulting documentation is allowed**, as in real work. Forbidding search measures memory,
  which is not the skill of the role.
- **The same test for every candidate for the role.** Changing the difficulty "depending on how the
  candidate looks" destroys comparability and is the silent route by which bias enters.
- **Nobody interviews without having done the test** they are going to set. Discovering that the "45
  minute" test takes two hours must happen to the interviewer, not to the candidate.
- **Algorithm puzzles are not forbidden for being hard**, but because **they mostly
  measure specific preparation**: the same candidate scores very differently before and after
  two months practising a format they will never use again. That is exactly the opposite of a
  valid instrument for the role.

### 3.4 Take-home exercises: the time limit is an ethical question

A take-home exercise shifts the cost of the process onto the candidate, who is already working somewhere
else. It is admissible **with hard conditions**:

1. **A declared and real time limit** (by default **2-3 hours**), **verified by someone on the
   team who has done it**. If the team takes three hours, the candidate will take longer.
2. **The limit is respected when assessing.** Rewarding whoever went over the limit is forbidden: doing so
   turns the limit into a trap and **selects by availability of free time**, which
   discriminates by caring responsibilities, health, a second job and financial situation.
3. **Bounded scope and a closed brief.** "Do what you can" cannot be scored and guarantees that
   every candidate delivers something incomparable.
4. **An alternative always available**: a guided session of the same duration with the team, or a walkthrough
   of their own code (§3.3). **Never a single route.**
5. **If the exercise exceeds a few hours, it is paid at market rate**, with a contract or an invoice.
   **There is no third option**: either it is short, or it is paid. A long unpaid exercise is free work
   for a stranger.
6. **FORBIDDEN to use candidates' work in production**, even if they are not hired. If the brief
   solves a real product problem, it is no longer a test: it is a commission.
7. **Feedback is returned** on the exercise. Whoever has invested three hours has the right to know what
   went wrong, even if in three lines.

### 3.5 Structure, calibration and decision

**Structured versus unstructured interview: the highest-impact change available** (§2). And
it is cheap — it requires no tool, no budget and no consultancy, just writing the questions beforehand.

- **Structured** means all four things at once: **same questions**, **same order**, **same
  scale with anchors**, and **written notes with evidence**. If one is missing, it is not structured.
- **Bounded follow-up questions**: probing is allowed, but from a prepared list. Free
  follow-up is the door through which the interview becomes unstructured without anyone noticing.

**Interviewer calibration** — without this the rubric is a document, not an instrument:
- **Nobody interviews alone before having shadowed** several interviews and having been shadowed
  scoring in parallel.
- **Periodic calibration exercise**: two or three interviewers score the **same** recording or
  the same exercise and compare. **Systematic divergence by one interviewer = they are recalibrated or leave
  the panel.** It is literally the inter-rater reliability of the instrument.
- **A panel as diverse as possible**, and **always more than one person per decision**.

**Decision — the rule that changes the most outcomes and the most broken one:**
> **Each interviewer writes their evidence and their score BEFORE the discussion meeting and without seeing
> anyone else's.**

Without this, the discussion does not aggregate information: the first opinion stated drags the rest along and
the result is **an opinion in the shape of a consensus**. Rules of the discussion:
- **Disagreements** are discussed, not everything is walked through. A disagreement forces the citation of the
  specific evidence supporting each score.
- **A "no" with evidence against the rubric weighs more than three "yes" without it.** And the other way round: a "no"
  without evidence **does not block**.
- **A tie or reasonable doubt → no hire**, and **which stage failed to produce signal is reviewed**. Hiring
  in doubt is how you get to the difficult and expensive separation six months later.
- **The decision is recorded** with the evidence cited: it is what allows it to be defended, reviewed and —
  if one day it is needed — to demonstrate that the criteria were the same for everyone.
- **Reopening the decision under calendar pressure is forbidden** ("we have been searching for three months"). The
  urgency of filling a role is not evidence about the candidate.

### 3.6 Bias, and the "culture fit" trap

- **"Culture fit" is the best-documented and most socially accepted route for bias to
  enter**, because it does not sound like discrimination: it sounds like criteria. In practice
  similarity is scored —background, class, hobbies, way of speaking, school— and labelled as culture. Effect:
  it homogenises the team and reduces exactly the cognitive diversity it claims to seek. **It is
  forbidden as a criterion** (§7).
- **It is replaced by observable values and behaviours**, with anchors and with evidence, just like
  any other competency. Usable examples: *"describe a time you changed your mind because of
  a piece of data"* (evidence: cite the datum and what they did next); *"tell me about a technical disagreement and how
  it ended"* (evidence: the procedure, not a favourable outcome). **What is measured is behaviour, not
  affinity.**
- **If the team wants to measure "brings something we do not have"**, that is called *culture add* and **it also
  needs a written anchor**, or it is the same bias with a new name.
- **Other bias entry points with a concrete countermeasure**:
  - *Halo effect* from a company or university name on the CV → **screening without those fields** when
    the process allows it, and a rubric that does not score them.
  - *Anchoring* from the first impression → scoring written before the discussion (§3.5).
  - *Similarity bias* → a diverse panel and behavioural anchors.
  - *Unequal test* → the same brief and the same time for everyone.
- **Illegal or irrelevant questions**: age, origin, family situation, pregnancy, health,
  disability, religion, orientation, trade union membership, and **previous salary** (§5.3).
  **Forbidden**, including "as informal conversation" and including in the coffee beforehand (§7). If an
  interviewer does not know what they may ask, they do not interview until they do: training is the
  responsibility of whoever assembles the panel, in coordination with HR.

### 3.7 Accessibility and inclusion of the process

The conformance criteria belong to `accessibility-standards`. **Here, the obligations of the process:**
- **Offer reasonable adjustments proactively and at every stage**, in the invitation message, not
  only if the candidate asks. Operational wording: *"If you need any adjustment to format, timing
  or tooling, tell us and we will arrange it; it does not affect the assessment."*
- **FORBIDDEN for asking for an adjustment to influence the assessment**, and forbidden to record it in the
  assessment record: it is health data (§5.4, `privacy-engineering-standards`).
- **Alternative formats by default**, not as an exception: take-home ↔ guided session; own
  code ↔ exercise; video interview ↔ voice or written.
- **The assessment platform is also assessed.** An online code editor that does not work with
  a screen reader, or a timed test with no possibility of extra time, excludes candidates
  before measuring anything. It is checked before adopting it.
- **Neurodivergence**: the signals many interviewers score without declaring them —eye
  contact, social fluency, quick response under pressure— **are not in the rubric and are not the
  job**. Scoring them is measuring something else. Sending the questions or the brief in advance
  improves the signal for everybody and **is not an unfair advantage**: it is reducing noise.

### 3.8 Candidate experience

A candidate is a professional in the sector who will talk about the process with their colleagues. **The cost of an
interminable process is reputational and is paid in the next hires**, not in this one.

- **Stages and duration published** in the ad, and respected. If they change, notice is given.
- **Committed timelines**: a reply after each stage within a declared window (by default ≤ 5 working
  days). **Exceeding it without notice is breaking a commitment, not an administrative slip.**
- **Nobody is left without a reply.** Silence after a three-hour test is the process failure most
  cited by candidates and the cheapest to fix.
- **Specific feedback to whoever completed a test**, even if brief. The
  "we have decided to proceed with other profiles" to someone who invested hours is forbidden.
- **Bounded number of stages.** Each additional stage must produce **distinct signal** (§1); if not,
  it only produces drop-out, and drop-out is not random: those with alternatives leave first.
- **The person who decides appears in the process.** A candidate who never speaks with their future
  manager cannot assess the offer, and the assessment is mutual.

## 4. Instrument quality: verifiable controls

*(This section replaces the canonical §4 on testing: here what is subjected to control **is the selection
process itself**.)*

Auditable controls over the process, with a fixed cadence. **Their failure stops the process or opens
work with an owner; it does not generate a report.**

| Control | Fails if | Action |
|---|---|---|
| Role undefined | the §3.1 document does not exist before publishing | The ad is not published |
| Late rubric | the rubric did not exist before the first candidate | The process is stopped and those already seen are re-assessed |
| Stage without signal | a stage scores no competency in the rubric | The stage is removed |
| Score without evidence | a score without a quote or a description of behaviour | It does not count |
| Contaminated discussion | someone scores after hearing others | The score is discarded |
| Uncalibrated interviewer | interviews alone without having calibrated | They are withdrawn from the panel |
| Systematic divergence | an interviewer persistently deviates from the panel | Mandatory recalibration |
| Unequal test | two candidates for the same role with different briefs or times | The comparison is voided |
| Exercise over the limit | the exercise exceeds the declared time as measured by the team | It is cut down or paid for |
| Adjustment not offered | the invitation does not mention reasonable adjustments | The template is fixed |
| Missed deadline | a reply outside the published window without notice | Notice is given and it is recorded as a process failure |
| Forbidden criterion | "culture fit", "attitude", "energy" or similar appears in a record | That score is voided and the interviewer is recalibrated |
| Automated screening without a person | a candidate rejected without human review | It is reversed and the tool is reviewed (§5.2) |
| Data past its window | CVs or notes kept beyond the declared window | Erasure and recording of the incident |
| No subsequent data | performance and retention at 6-12 months are not measured | The process cannot be improved: it is instrumented (§6) |

**Instrument reliability test, literally executable**: give the same material (recording,
submitted exercise) to two independent interviewers. **If their scores do not agree within one
point of the scale, the problem is not the candidate: it is the rubric or the calibration.**

## 5. AI in hiring, legal regime and candidate data

**A mandatory section with a short expiry date.** The legal framework moves; §8 requires
re-verifying it before applying it.

### 5.1 Candidates who use AI assistants in the technical test

**Realistic starting point: forbidding it is neither enforceable nor desirable.** It cannot be verified
reliably without intrusive surveillance —which has its own legal and data problem— and it also **forbids
the tool the person will use on their first day of work**.

Consequences for the **design** of the test, which is what you actually control:
- **If the test is solved by a general-purpose model in two minutes, the test was measuring
  what no longer needs measuring.** It is not a cheating problem: it is a validity problem of
  the instrument, and it is fixed by changing the test.
- **The signal shifts towards what the assistant does not provide**: **judgement** (why this option and not
  the other), **critique of the output** (given this code, what is wrong and what is missing), **constraints
  of the real domain** (the brief that requires asking), **debugging a non-obvious failure**, and
  **the ability to explain and defend what was delivered**.
- **Robust format by default**: submission + **a conversation about the submission**. Whoever cannot
  explain a decision in their own code did not make it. It is the cheapest test and it requires no
  surveillance of anything.
- **A policy declared to the candidate, in writing and in advance**: if assistants are allowed
  (recommended), it is said; if at some specific stage they are not —and there must be a reason—, it is said **beforehand**.
  **FORBIDDEN to assess in secret whether the candidate used AI**, and forbidden to reject on suspicion without
  evidence (§7).
- ❌ **FORBIDDEN intrusive remote surveillance of the candidate** (desktop monitoring, continuous screen
  capture, eye tracking, biometric analysis). Beyond its legal regime, it measures
  anxiety and equipment, not competence.

### 5.2 Use of AI to screen candidates, and its legal regime

**A process rule, which is independent of jurisdiction: a model may rank or label;
it does not reject.** Every rejection is confirmed by a named person, against the rubric and with a record.
Without local validation and without effective human oversight, a screening tool is historical
bias automated and scaled.

**European Union — AI Regulation (AI Act).** Employment is a **high-risk case**: **Annex III,
point 4** covers AI systems intended for recruitment or selection (among others, targeted job
advertising, analysing and filtering applications and evaluating candidates), as well as decisions on
promotion, termination, task allocation and performance monitoring.

**Application dates — verified and with the correction almost nobody has taken on board:**
- **Original** timetable: high-risk obligations of **Annex III from 2-Aug-2026**; Annex I
  (AI embedded in regulated products) from **2-Aug-2027**.
- **That timetable has been postponed.** After the Commission's proposal of **19-Nov-2025** (*Digital
  Omnibus* on AI), there was a **political agreement between Council and Parliament on 7-May-2026** and
  confirmation by the Council on **29-Jun-2026**: **Annex III (including employment) moves to 2-Dec-2027**
  (a 16-month extension) and **Annex I to 2-Aug-2028** (12 months).
- **What has NOT moved**: the **prohibited practices of Article 5** and the duty of
  **AI literacy of Article 4**, applicable **from 2-Feb-2025**; the obligations for
  general-purpose models **from 2-Aug-2025**; and the transparency obligations of
  **Article 50**.
- **A prohibition directly relevant to selection: Article 5 prohibits emotion
  recognition systems in the workplace and in educational institutions, except for
  medical or safety reasons.** Practical consequence: **the analysis of facial expression, tone of voice or
  "engagement" in a video interview is in forbidden territory or on its immediate boundary**, and
  the exact delimitation with respect to an external candidate is a legal question that **is consulted
  with legal counsel before contracting the tool**, not afterwards.
- **Status warning — this is not a settled datum**: the postponement requires **formal adoption and
  publication in the OJEU** to take effect. `ai-governance-standards` references it as
  **Regulation (EU) 2026/1744**. **Before planning against the Dec-2027 date, confirm the
  publication in the OJEU and the regulation number** (§8): if it was not published before
  2-Aug-2026, the original timetable applies exactly as written.
- **Engineering stance, regardless of the date**: 16 more months are **headroom, not
  cancellation**. The obligations —risk management, technical documentation, event logging,
  human oversight, conformity assessment and system registration— **arrive all the same**, with less
  time if they are parked.

**United States — local rules already in force**, relevant if you hire there:
- **New York, Local Law 144** (in force 1-Jan-2023, enforcement from 5-Jul-2023): **a bias
  audit of the AEDT carried out no more than one year before its use**, **publication of the summary of the
  audit** on the website, and **notice to the candidate at least 10 business days** in advance
  stating that it will be used, how and what data are collected. Penalties of **$500 to $1,500 per day**.
  **An uncomfortable and verified datum**: an audit by the State Comptroller of **2-Dec-2025** concluded
  that enforcement of the law by the DCWP was **ineffective**; and a published study (*Null
  Compliance*, arXiv) found that **out of 391 employers examined only 18 published the audit
  report and 13 the transparency notice**. **The correct reading: a low probability of a penalty is not
  compliance, and scrutiny is going to increase.**
- **Illinois, HB 3773** (an amendment to the *Human Rights Act*), signed 9-Aug-2024, **in force
  1-Jan-2026**: notice to the candidate when AI is used in employment decisions, a prohibition on using the
  ZIP code as a proxy for a protected characteristic, and a prohibition on uses with a
  discriminatory outcome. **The implementing regulation is unstable**: the IDHR published a
  proposal on 15-May-2026 and **temporarily withdrew it**, cancelling the hearing of 10-Jun-2026.
  **The legal obligations remain in force** notwithstanding.
- **Colorado**: the original law (SB 24-205) had **its application suspended by court order**
  (27-Apr-2026) and has been **replaced by SB 26-189**, signed on 14-May-2026, effective
  **1-Jan-2027** and with trimmed requirements. **Employment remains covered in both.** It is the most
  volatile framework of the three: **do not plan against it without verifying the status in the current month.**

**Spain**, in addition to the AI Act:
- **Article 64.4.d) of the Estatuto de los Trabajadores** (introduced by the *Ley Rider*, **Ley
  12/2021**, originating in RDL 9/2021). **Verbatim of the right granted to worker
  representatives**: *"ser informado por la empresa de los parámetros, reglas e instrucciones en los que se
  basan los algoritmos o sistemas de inteligencia artificial que afectan a la toma de decisiones que
  pueden incidir en las condiciones de trabajo, el acceso y mantenimiento del empleo, incluida la
  elaboración de perfiles"*. **"Access to employment" and "profiling" cover candidate screening
  squarely.** There is a court ruling that has held that **failing to inform infringes
  the fundamental right to freedom of association**, with compensation; it is cited as an indication that
  the right is enforceable, **not as settled doctrine** — its exact scope is checked with employment
  counsel.
- **Automated decisions and the GDPR** (art. 22) and information to the data subject:
  `privacy-engineering-standards`.

### 5.3 Pay transparency

- **A pay band in the ad, by default.** It is not only compliance: it reduces the number of processes
  that end in a financial mismatch after five stages, which is pure cost for both parties.
- **Directive (EU) 2023/970**, of 10-May-2023, on strengthening equal pay through
  transparency. Published in the OJEU on **17-May-2023**, in force on **6-Jun-2023**, with a **transposition
  deadline of 7-Jun-2026** (arts. 34 and 36). Among its requirements: **information about
  the starting pay or its range to candidates before the interview**, **a prohibition on
  asking the candidate about their previous salary**, the workforce's right to know average pay
  levels broken down by sex, and **a joint pay assessment when the gap
  exceeds 5 % without justification**.
- **Status in Spain as of Aug 2026: NOT transposed.** The 7-Jun-2026 deadline **passed without
  transposition**; the Ministry of Labour opened a prior public consultation on the transposing royal
  decree, closed on **8-May-2026**, with no known subsequent steps. Spain starts from **Real
  Decreto 902/2020** on equal pay (mandatory pay register and pay
  audit), which **is in force**. **The delay does not eliminate the principle of equal
  pay**, already recognised in the legal order.
- **Announced reporting timetable** (according to secondary sources, **check against the text of the
  directive before planning**, §8): companies of **≥ 250 people**, annually, **first report before
  7-Jun-2027**; **150-249**, every three years, first report also in Jun 2027; **100-149**, later
  on.
- **Engineering criteria, applicable now and regardless of transposition**: **a published band,
  do not ask about previous salary, and an offer built on the level of the role (§3.1), not
  on what the person earned before.** Anchoring the offer to previous salary **imports inequities
  from other organisations** and perpetuates them inside your own.

### 5.4 Candidate data

The full criteria —legal basis, minimisation, windows, rights and erasure— belong to
`privacy-engineering-standards`. **Rules this process must comply with no matter what:**
- **A declared legal basis** for processing the data, and a **retention window declared to the candidate**
  from first contact. Keeping a CV "just in case" without a basis or a window is processing without
  cover.
- **Separate and verifiable consent** to keep the application for future processes, with a
  **window and automatic erasure on expiry**. A consent with no expiry date is not a
  consent: it is a permanent archive.
- **Minimisation**: date of birth, photo, marital status, nationality and health data are not
  requested. If the ATS asks for them by default, **it is configured not to**.
- **Interview notes are personal data** and are accessible to the data subject. Operational
  corollary: **they are written as if the candidate were going to read them** — behavioural evidence, without judgements
  about the person. It is also the best rubric discipline there is.
- **FORBIDDEN** to store candidate data in personal spreadsheets, chat channels or
  shared drives outside the system with access control and an audit trail.
- **The adjustments requested (§3.7) are health data**: restricted processing, outside the assessment
  record, and erased when they are no longer necessary.
- **Reference checking**: only with the candidate's knowledge and about verifiable facts
  related to the role. **Contacting their current employer without explicit permission is forbidden.**

## 6. Onboarding and the right metric

*(The canonical §6 —performance and operability— does not apply to a process domain; **it is replaced,
declaring it so**, by the last stage of the process and by its measurement.)*

**Onboarding is part of the hiring process, not what comes afterwards.** A process that
selects well and then abandons the person has wasted its own result.

- **Everything is prepared before day one**: access and equipment (`identity-access-management-standards`,
  with **least privilege from day one**, not "everything and we will take it away later"), a named
  reference person, and **a realistic first contribution for the first week**.
- **Written 30 / 60 / 90 day objectives**, agreed and reviewed in the 1:1
  (`tech-leadership-standards` §3.9).
- **The new joiner is the best auditor of the documentation the team will ever have**, and they only
  are one once: **their list of "this was not written down" turns into tickets in the same month**
  (`knowledge-management-standards`). Wasting that window is throwing away the only external
  point of view available.
- **Onboarding metric**: **time to the first contribution in production** and **time
  to the first on-call shift in autonomy** (if the team has on-call). Both say more about the
  organisation's system than about the person.
- **Verifiable revocation on departure**: access, credentials, devices and keys, with a list and
  a date (`identity-access-management-standards`). A departure without recorded revocation is an orphaned
  account with permissions.

**The metric of the hiring process, and this is the correction to hold against whoever
measures something else:**

| Metric | What it is | Use |
|---|---|---|
| ❌ **Time to fill the role** (*time to fill*) | Speed of the process | **It is not a quality measure.** It is optimised by lowering the bar; it is the metric that worsens the outcome fastest |
| ❌ Number of candidates interviewed, CVs received | Activity | Noise |
| ✅ **Subsequent performance** at 6-12 months, assessed against the original rubric | Validity of the instrument | **The main measure.** It is the only one that closes the loop |
| ✅ **Retention** at 12 and 24 months, and the **stated reason for leaving** | Validity and honesty of the offer | Concentrated early departures = the process sold something else, or measured something else |
| ✅ **Correlation between the process score and subsequent performance** | **Local** predictive validity | It is what turns the general evidence of §2 into your own datum |
| ✅ Inter-rater reliability (§4) | Reliability of the instrument | Corrected with calibration |
| ✅ Drop-out rate per stage | The cost the process imposes | A stage with high drop-out is redesigned |
| ✅ % of offers accepted and reason for rejection | Competitiveness and experience | With a reason, or it is a number with no action |

- **Closing the loop is mandatory.** An organisation that does not compare the process score with
  subsequent performance **does not know whether its process works**, whether it has been using it for twenty years or two. It is
  exactly the local validation that §2 demands and that no meta-analysis figure replaces.
- **Small sample, prudent conclusions.** With 10 hires a year there is no statistical
  power: **it serves to detect gross failures** (a stage that never discriminates, an
  interviewer who always diverges), not to fine-tune coefficients. **Saying it out loud avoids the
  next mistake**, which is treating your own data with more confidence than it can bear.

## 7. Long-term sustainability and prohibitions

**Cadence**: rubric reviewed when opening each process; interviewer calibration at least
half-yearly and whenever someone new joins the panel; stages and their signal, half-yearly (the §1 test);
data retention windows, quarterly; **the legal regime for AI in employment and pay
transparency, before every tool change and at minimum half-yearly** (§8) — it is what moves
the most.

**Deprecation**: every stage is introduced with the condition that would make it unnecessary. A process grows
by accumulation —one stage for every remembered bad hire— and **nobody ever removes anything**, until
the process takes two months and only those with no alternatives finish it.

FORBIDDEN:
- ❌ **Interviewing without a written rubric before the first candidate.** Without it you do not measure competence,
  you measure impression and then justify it.
- ❌ **Deciding by impression**: "good vibes", "attitude", "energy", "I am not convinced" without
  behavioural evidence cited against the rubric.
- ❌ **Using "culture fit" as a criterion** (§3.6). It is replaced by observable values and behaviours
  with anchors.
- ❌ **Scoring after hearing the others.** The evidence and the score are written before the discussion.
- ❌ **Tests beyond a reasonable time limit without paying for them** (§3.4), and **rewarding whoever went
  over the declared limit**.
- ❌ **Using a candidate's work in production.**
- ❌ **Illegal or irrelevant questions**: age, origin, family situation, pregnancy, health,
  disability, religion, orientation, trade union membership — and **previous salary**. Not
  "off the record" either, nor outside the room.
- ❌ **Screening with a model without local validation or effective human oversight**, nor rejecting
  anyone without a named person confirming it against the rubric (§5.2).
- ❌ **Analysis of emotions, facial expression, tone of voice or candidate "engagement"**: forbidden
  in the workplace by Article 5 of the AI Act and, in any case, without demonstrated validity for
  the role (§5.2).
- ❌ **Intrusive remote surveillance during a test** (continuous screen capture, eye
  tracking, biometrics).
- ❌ **Assessing in secret whether the candidate used AI**, or rejecting them on suspicion without evidence (§5.1).
- ❌ **Algorithm puzzles as a default filter** for roles that do not do that work:
  they mostly measure specific preparation for the format (§3.3).
- ❌ **Changing the test or its difficulty depending on the candidate**: it destroys comparability and is the
  silent route of bias.
- ❌ **Citing Schmidt-Hunter (1998) without the later correction**, or **giving a validity figure without its
  year, its correction and the warning that the mean does not apply to your organisation** (§2).
- ❌ **Using "the cost of a bad hire is 1.5× the salary"** or any variant: without a locatable
  primary study (§2).
- ❌ **Optimising the process for time to fill** (§6). It is improved by lowering the bar.
- ❌ **Hiring in doubt under calendar pressure.** A tie is a "no", and a signal about the
  process.
- ❌ **Leaving candidates without a reply**, or missing the published deadlines without notice.
- ❌ **Keeping candidate data without a legal basis and without a declared window**, or outside the system with
  access control.
- ❌ **Letting the request for a reasonable adjustment influence the assessment**, or be recorded in the record.
- ❌ **Contacting the candidate's current employer without explicit permission.**
- ❌ **Anchoring the offer to the candidate's previous salary** instead of to the level of the role (§5.3).
- ❌ **Publishing an ad without a pay band** when the band exists internally.
- ❌ **Interviewing without having done beforehand the test you are setting.**
- ❌ **Applying this document as if it were legal or HR advice** (§1). Anything with
  legal effect is checked with legal counsel and with HR before being applied.

## 8. Mandatory web verification

Before committing to any of these points in a real process:

1. **The AI Act and its postponement — the most volatile point.** Confirm in **EUR-Lex / OJEU**: (a) that the
   *Digital Omnibus* was **formally published** and its exact regulation number
   (`ai-governance-standards` references it as **Regulation (EU) 2026/1744**: **verify**);
   (b) that the application date of **Annex III, point 4 (employment)** is indeed
   **2-Dec-2027** and that of **Annex I** is **2-Aug-2028**; (c) that **Article 5 (prohibitions) and
   Article 4 (literacy) still apply from 2-Feb-2025**. **If the postponement was not published before
   2-Aug-2026, the original timetable governs.** Always cite the text
   of the regulation, **not a law-firm summary**.
2. **Emotion recognition and the boundary of Article 5**: whether the **Commission's guidelines
   on prohibited practices** have been updated, and **how they delimit "workplace" with respect to
   an external candidate**. It is the specific doubt that decides whether a video-interview tool is
   legal: **it is resolved with legal counsel, not with this document.**
3. **Pay transparency**: status of the **Spanish transposition** of **Directive (EU)
   2023/970** (as of Aug 2026: **deadline expired on 7-Jun-2026 without transposition**, with a prior public
   consultation closed on 8-May-2026). Verify whether the royal decree has been approved, whether
   infringement proceedings have been opened, and **check the reporting timetable by company size against
   the text of the directive**, not against law-firm articles — the dates in §5.3 come from
   secondary sources.
4. **Local rules on AI in employment**, if you hire outside the EU: **NYC Local Law 144**
   (bias audit, publication, 10-business-day notice; and whether the DCWP has tightened
   enforcement after the Comptroller's audit of Dec 2025), **Illinois HB 3773** (in force since
   1-Jan-2026; status of the IDHR regulation, withdrawn in May 2026) and **Colorado** (SB 24-205
   suspended by the courts; **SB 26-189 effective 1-Jan-2027**). **This block expires fast:
   verify the status in the current month before any deployment.**
5. **Spain**: the validity and wording of **art. 64.4.d) ET** and the status of the case law on the
   right to algorithmic information; and **RD 902/2020** on equal pay.
6. **Predictive validity — a declared gap.** The **revised value for work samples** in
   Sackett et al. (2022) **was not extracted in this verification** and that is why **it does not appear as a figure in
   §2**. Obtain it from **Table 3 of the original article** before using it. Verify likewise whether
   a meta-analysis later than 2022-2023 has appeared that revises these estimates again, and whether the
   debate about the correction for range restriction has produced a published reply. **Never give
   a figure without its method and its year.**
7. **Any figure on hiring cost, turnover or productivity**: locate the primary
   study, year, sample and method. If it does not appear, or if the citation chain ends in a commercial
   blog (the case of the "1.5×" and of the "30 % from the DOL", §2), **it is not used**.
8. **Tools**: ATS and assessment platforms — where they host the data, subprocessors,
   international transfers, whether they perform automated screening and whether they publish a bias
   audit; the real accessibility of the coding platform (§3.7). For *open source*, **read the
   raw `LICENSE` of the repository**.
9. **Employment and non-discrimination framework** of the specific jurisdiction (in Spain, the Estatuto de los
   Trabajadores, LO 3/2007 and the applicable collective agreement): which questions are admissible, which equality
   obligations apply by company size and what must be recorded. **With legal counsel and with HR,
   always** (§1).

If the web contradicts this document, **the web wins** — flag the discrepancy.
