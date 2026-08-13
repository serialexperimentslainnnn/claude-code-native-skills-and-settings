---
name: testing-qa-standards
description: Test strategy across languages - deciding what to test and in what proportion, not which runner to use. Use when writing or reviewing a test plan or test pyramid/trophy split, a coverage threshold in CI (codecov.yml, .coveragerc, jacoco check, --cov-fail-under), a mutation testing run (Stryker, PIT/pitest, cargo-mutants, mutmut, stryker.conf.json), Testcontainers-based integration tests, consumer-driven contract tests with Pact (pact_broker, can-i-deploy, pacts/*.json), end-to-end suites in Playwright, Cypress or Selenium, property-based tests (Hypothesis, fast-check, jqwik, proptest) or fuzzing harnesses, snapshot/golden files, load and performance test scripts (k6, Gatling, Locust, JMeter, .jmx), test fixtures and factories or synthetic test data, flaky-test quarantine policy, test environment parity, testing in production (canary, feature flags, shadow traffic), or the QA role versus team-owned quality.
---

# Test strategy and quality standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when deciding **what gets tested, in what proportion, against what quality criterion and
what breaks the build**: the split across test levels, coverage and mutation policy, the criterion
for choosing between container-based integration tests and test doubles, *consumer-driven*
contracts, E2E, *property-based* testing, *fuzzing*, *snapshots*, load, test data, doubles, flaky
test policy, the suite's time budget, environment parity and testing in production.

**This skill does NOT choose the *runner* nor its file conventions.** Each language skill already
fixes its test framework in its §4 and that is where it stays: `python-standards` (pytest),
`typescript-standards` (Vitest + Playwright), `go-standards` (`go test`), `rust-standards`
(`cargo test`), `jvm-spring-standards` (JUnit), `dotnet-standards` (xUnit), `php-standards`,
`ruby-standards` (RSpec), `elixir-erlang-standards` (ExUnit), `scala-standards`,
`clojure-standards`, `haskell-fp-standards`, `ocaml-fsharp-standards`, `c-standards`,
`cpp-standards`, `solidity-standards` (`forge test`), `mobile-standards` (XCTest),
`dart-standards`, `sql-standards`, `bash-linux-scripting-standards` (bats), `powershell-standards`
(Pester), `groovy-standards` (Spock). If "use pytest" appears written here, it is stepping on
`python-standards`: that is a defect of this skill, not of that one.

**Arbitration rule, unambiguous**:

| Question | Owner |
|---|---|
| Which binary/library writes and runs the test? How is the file named? Which *matcher*, *fixture* or annotation is used? How is it parallelised in that ecosystem? | **The language skill** |
| Which behaviour must be covered? How many tests at each level? Which threshold breaks the build? Is this test accepted as evidence or is it noise? What is done with a flaky test? | **This skill** |
| Conflict between the two | The language skill wins **on the mechanics**; this one wins **on the acceptance criterion**. If the conflict is real (e.g. the language skill fixes a different coverage threshold), it is resolved by ADR and whichever is out of date gets fixed. |

**Not applicable**: see the language skills cited above (framework, syntax and *runner*
configuration), `cicd-standards` (**the pipeline and its gates are theirs**: jobs, ordering, caches,
runners, matrix; here **what each gate must check and with what threshold**),
`git-workflow-standards` (PR size and PR mechanics), `code-review-standards` (what gets reviewed in
a test's diff and how it is commented), `appsec-standards` (threat modelling and finding triage;
here only *fuzzing* and negative tests as **generators** of those findings),
`sre-practice-standards` (**mandatory coordination**: production reliability, SLOs and the *error
budget* — testing in production and progressive delivery are designed here as tests and **operated**
there), `observability-standards` (the telemetry those tests read),
`performance-engineering-standards` and `web-performance-standards` (**load tests are designed
here**; **latency thresholds and the optimisation methodology are theirs**),
`chaos-engineering-standards` (**deliberate fault injection with a steady-state hypothesis is
theirs**; here the deterministic test — a Toxiproxy *toxic* in an integration test is configured
under their criteria, and the test and its gates belong here), `accessibility-standards` (the WCAG
conformance criterion is theirs; here only automating it as a test that breaks the build),
`privacy-engineering-standards` (**personal data policy is theirs**; here the operational ban on
putting it into a test environment), `incident-management-standards` (blameless postmortem; here
the regression test every fixed bug mandatorily leaves behind), `llm-evaluation-standards`
(evaluating a model's non-deterministic outputs: not this skill), `ai-agents-standards` and
`ai-agent-workflow-standards` (working with agents), `data-governance-quality-standards` (quality
assertions **over production data**, not over code), `kubernetes-standards` and `iac-standards`
(manifest and infrastructure testing), `refactoring-tech-debt-standards` (**this skill is its
precondition and it is worth saying in both directions**: **what gets tested, in what proportion
and against what quality criterion belongs here**; **the requirement to cover observable behaviour
BEFORE touching the structure, and characterisation tests over untested legacy code, are theirs**.
The rule both hold up: **without tests you do not refactor, you rewrite blind**).

## 2. Default decisions

> Verify the latest version on the web before fixing it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Acceptance criterion for a test | It tests **observable behaviour** through a public contract (API, exported function, event, persisted row) | An implementation test **only** for algorithms with internal invariants that are expensive to observe, and documented |
| Level split | **Trophy** in services dominated by I/O: mostly integration with real containerised dependencies, unit tests on pure logic, minimal E2E | **Classic pyramid** when domain logic weighs more than I/O (calculation engines, compilers, libraries) |
| Dependencies in integration tests | **Testcontainers** (MIT, a real container of the dependency) | A shared environment service **only** if the container is unfeasible (mainframe, per-host licence) |
| Contract between services | **Pact** *consumer-driven* + Pact Broker (**both MIT**) for internal HTTP/messaging | A versioned shared schema (OpenAPI/protobuf) + verification in CI when you do not control the consumer |
| Browser / E2E | **Playwright** (Apache-2.0) | **Cypress** (MIT) only in an existing suite that already works; **Selenium** (Apache-2.0) when you need a grid of real browsers/OSes or *bindings* outside JS |
| Case generation | **Property-based** on parsers, serialisers, invariants and data structures; the library is fixed by the language skill | A hand-written case table when the space is small and enumerable |
| Untrusted inputs | **Continuous fuzzing** of every parser of external input | Point-in-time *fuzzing* campaigns if the binary is not an exposed service |
| Load | **k6** (**AGPL-3.0**, Grafana Labs; 2.x series) by default | **Gatling** (Apache-2.0) in JVM/Scala teams; **Locust** (MIT) if the scenario needs arbitrary Python |
| Mutation | Yes, **incremental over the diff**, never over the whole repo | No mutation on code with no decision logic (DTOs, mappings) |
| Coverage | **A signal, measured and published; the global threshold is not the main gate** (§4.2) | A hard threshold **only** on code with a regulatory or functional-safety requirement |
| Test data | **Factories** in code (they build the minimal valid object and expose only what is relevant to the test) | Declarative *fixtures* for stable reference data (catalogues, tariffs) |
| Isolation between tests | State created and destroyed by the test itself; **implicit ordering forbidden** | A read-only seeded database, shared and never mutated |
| Clock, randomness and network | **Injected** (fake clock, fixed seed, network simulated at the edge) | — |
| Flaky test | **Immediate quarantine with an owner and a date**; it gets fixed or deleted (§4.4) | — |

**Verified tool status** (Aug-2026, see §8):

- **Pact**: `pact-js` v17.0.1 (Jul-2026), `pact_broker` **MIT** (raw `LICENSE.txt`), `pact-js`
  **MIT**. The project is under the **"SmartBear supported"** model. Verbatim from `docs.pact.io`:
  the original commitment was *"As a policy, we commit at least 10% of our engineering time toward
  open source development"*, and the page itself declares it insufficient — *"that commitment is not
  enough"*, *"the % itself is irrelevant"* — while *"transitioning to a new model we are calling
  'SmartBear supported' that aims a little higher than simply a minimum resource allocation"*.
  **Declared discrepancy**: the core is still OSS and MIT, but **PactFlow / API Hub for Contract
  Testing is commercial** and features such as AI-assisted contract generation **are not in the OSS
  and there is no plan to open them**. Criterion consequence: **the self-hosted Broker (MIT) is the
  default**; PactFlow is a purchasing decision, not an engineering one.
- **k6**: **AGPL-3.0** (raw `LICENSE.md`, not Apache-2.0 as is usually assumed). Owned by **Grafana
  Labs since 2021** (previously Load Impact); **no change of ownership or licence in 2026 has been
  located**: the "change of hands" is the 2021 one and it still stands. Current series **2.x**
  (v2.1.0, Jun-2026). The AGPL only matters if you **modify** k6 and expose it over a network.
- **JMeter**: latest release **5.6.3, January 2024** — **more than two years with no release** as of
  Aug-2026, corroborated by two sources (`jmeter.apache.org/download_jmeter.cgi` and the tag feed of
  `apache/jmeter`). **FORBIDDEN to choose JMeter for a new project**; in existing suites, an exit
  plan.
- **Gatling**: Apache-2.0, v3.15.1 (May-2026), active. **Locust**: MIT, 2.46.x (Aug-2026), active.
- **Testcontainers**: MIT. **AtomicJar was acquired by Docker (2023)**; Docker sponsors the
  implementations for the most used languages and **the rest are *community-driven***.
  `testcontainers-java` 2.x (2.0.5, Apr-2026). **No licence change nor foundation donation has been
  located**. Real risk to watch: **Testcontainers Desktop requires a Docker account** and
  **Testcontainers Cloud is paid** — the library is OSS, the tooling around it is not.
- **E2E**: Playwright v1.62.x (Apache-2.0), Cypress v15.x (MIT), Selenium 4.46.x (Apache-2.0); all
  three active. **Cypress.io has NOT been acquired**: the news of the purchase by John Deere is an
  April Fools' joke from 2025 — it is not cited as a migration reason.
- **Mutation**: Stryker (JS/TS, .NET, Scala) v9.6.x; PIT/pitest (JVM) 1.25.x (Jul-2026);
  `cargo-mutants` (Rust) v27.x; `mutmut` (Python) 3.7.0 (Jul-2026). All with a recent release; the
  per-language status is re-verified before fixing it in CI (§8).

## 3. What is a test that adds value and what is noise

### 3.1 Rules of form

- **AAA**: *arrange / act / assert*, in that order and visually separated. If the *arrange* takes
  more space than the rest, the subject's design is wrong, not the test.
- **One reason to fail per test.** Several asserts are fine if they all describe the **same**
  behaviour; they are wrong if the test can fail for two unrelated reasons.
- **Zero logic in the test**: no `if`, no loops that decide, no recomputing the expected result with
  the same formula as the subject. The expected value is written literally.
- The test's name states the **behaviour and the condition**, not the method invoked:
  `rejects_transfer_if_insufficient_balance`, not `test_transfer_2`.
- A failing test must say **which behaviour broke** without opening the code.
- **Determinism mandatory**: the same result on the author's machine, in CI, in parallel and in
  random order. Run the suite in random order at least in the nightly job.

### 3.2 Noise to delete as soon as it is spotted

- Tests that only exercise *getters*, *setters*, trivial constructors or generated mappings.
- Tests that reimplement the subject in the `assert`.
- Tests that verify **calls to a double** when observable behaviour is already verifiable: that
  tests the double, not the system (§3.4).
- Tests with `sleep`/*polling*: replaced by waiting on a condition or a controlled clock.
- Tests that depend on ordering, on the previous *test* or on leftover data.
- Tests disabled with no ticket, no owner and no date (§4.4).

### 3.3 The split across levels: real criteria, not dogma

The pyramid (many unit tests, few E2E) optimises **cost and speed**. Its critiques — the *trophy*
(more weight on integration) and the *honeycomb* (little unit, much integration, little E2E) — are
right for a specific kind of system, not universally. The operational criterion:

- **The split is dictated by where the risk lives, not by a geometric figure.** Count the last 20
  real incidents: if most came from I/O, schemas, transactions or inter-service integration, the
  classic pyramid is making you write tests at the wrong layer.
- **Service dominated by I/O** (CRUD, orchestration, glue): weight on **integration with the real
  dependency in a container**. A unit test that mocks the repository proves nothing that fails in
  production.
- **Dense domain logic** (calculation, rules, algorithms, parsers): weight on **unit tests**; there
  the unit test is fast, expressive and finds the real failure.
- **E2E**: a **fixed and small** number of critical business flows (authentication, payment,
  sign-up, the main CRUD). What a lower layer already covers is not replicated in E2E. Every new E2E
  is justified in writing or it does not go in.
- Each level tests **what only it can test**. Duplicating a case across two levels doubles the
  maintenance cost without adding signal.

### 3.4 Test doubles

- **Mock boundaries, not everything.** A boundary = someone else's process, a network you do not
  control, the clock, randomness, the filesystem, a third-party service that is paid or has
  irreversible effects.
- **FORBIDDEN to mock a type of your own module** in order to avoid starting a dependency
  Testcontainers brings up in seconds.
- **A mock that replicates the implementation is a test that only tests the mock**: if refactoring
  without changing behaviour breaks the test, that test is debt, not a safety net.
- A double of an **external** dependency is only valid if its fidelity is verified: by a contract
  test (§3.5) or by a real integration test against the provider in the nightly job.
- Prefer the simplest double that works: real value > *stub* > *fake* > *mock* with interaction
  verification (last resort, and only when the interaction **is** the behaviour: e.g. "exactly one
  event was published").

### 3.5 *Consumer-driven* contracts

- Mandatory as soon as **two different teams** deploy at different rhythms on either side of an
  interface. With a single team owning both sides, an integration test is enough.
- The **consumer** writes the expectation; the **provider** verifies it in its own CI. A contract
  written by the provider is not a contract, it is documentation.
- The provider's deployment gate consults the Broker (`can-i-deploy`) **before** deploying: if it
  breaks a consumer with a deployed version, it does not ship.
- The contract does **not** replace the provider's behaviour tests: it verifies shape and
  compatibility, not that the logic is correct.
- The design of the HTTP/gRPC contract itself belongs to `api-design-standards`; here only its
  verification.

### 3.6 Property-based and fuzzing: the most under-used, highest-yield tools

- **Property-based mandatory** wherever a statable invariant exists: round-trip
  (`decode(encode(x)) == x`), idempotency, commutativity, total ordering, sum conservation,
  monotonicity. A single *property test* replaces dozens of example cases and finds the edge nobody
  wrote.
- Every counterexample found is **frozen as a deterministic regression test** with its seed and its
  shrunk value. Without that, the property breaks again and nobody notices.
- Seed **random in the nightly job** and **fixed in the PR gate**: a PR cannot fail because of a new
  case unrelated to the change.
- **Fuzzing mandatory** on every parser of untrusted input (binary formats, deserialisation,
  protocols, user-uploaded files). Corpus versioned in the repo, a continuous campaign outside the
  PR, and **every crash goes in as a regression test before the fix**.
- *Fuzzing* is also a security control: findings are triaged under `appsec-standards`.

### 3.7 Snapshot testing and its degeneration

- Valid only when the output is **large, stable and human-readable** and the diff is reviewable:
  rendered HTML, a contract JSON response, CLI output, an infrastructure plan.
- **Typical and forbidden degeneration**: `--update-snapshots` as a reflex to any failure. That
  command turns the suite into a record of what the code does today, not of what it should do, and
  **approves regressions automatically**.
- Hard rules: the *snapshot* file **is reviewed as code** in the PR; an unreadable *snapshot* or one
  thousands of lines long is replaced by explicit asserts; a *snapshot* is **never** updated in the
  same commit that changes behaviour without explaining it in the description.
- Volatile values (dates, IDs, hashes) are normalised before serialising, not tolerated.

## 4. Quality gates: what breaks the build

### 4.1 Increasing order of cost (the cheap gate goes first)

1. Formatter and linter (fixed by the language skill) — **breaks**.
2. Types / static analysis — **breaks**.
3. Unit tests — **breaks**.
4. Integration with Testcontainers — **breaks**.
5. Contract: provider verification + `can-i-deploy` — **breaks the deployment**, not the PR.
6. E2E of the critical set against a preview deployment — **breaks**.
7. Incremental mutation over the diff — **warns**; breaks only in modules declared critical.
8. Load and a11y — **outside the PR** (nightly or pre-release), they break the release.

The execution, the actual ordering and the caching of those steps belong to `cicd-standards`;
**what is fixed here is which one breaks what**.

### 4.2 Coverage: a signal, not a goal

- **Coverage measures which code ran, not which behaviour was verified.** A suite without a single
  `assert` can reach high coverage. That is why the global threshold is a weak gate.
- **It is always measured and always published**; *lowering* coverage without a written
  justification in the PR is forbidden. The useful gate is **differential over the diff** (new or
  modified lines and branches), not the repository's global percentage.
- Available evidence, with source: in *Code Coverage at Google* (Ivanković, Petrović, Just, Fraser —
  **ESEC/FSE 2019**, pp. 955-963, DOI 10.1145/3338906.3340459) coverage is computed daily over a
  billion lines in seven languages, and **the actionability lever is applying it at the *changeset*
  and code review level**, with **thresholds that projects adopt voluntarily**, not imposed
  globally. The **exact numeric values** of the paper's threshold table **could not be verified in
  this pass** (§8): **they are not written here**.
- **No primary source has been located** supporting a specific coverage threshold (80%, 90%) as
  optimal. **Therefore none is fixed in this skill.** Whoever fixes one in their project does so as
  a team convention, and declares it as such.
- Branches and conditions > lines. 100% line coverage with 40% branch coverage is a lying metric.
- Exclude generated code, DTOs and bootstrap code from the metric; **FORBIDDEN** to exclude files to
  make the number look better.

### 4.3 Mutation: what coverage does not measure

- Mutation answers the question coverage does not: **if I change the code, does any test fail?** A
  surviving mutant in code with high coverage is a test with no useful `assert`.
- **Always incremental over the diff** and with a limit on mutants per line and per review: full
  repository mutation is neither viable nor informative.
- Evidence, with source: in *Practical Mutation Testing at Scale* (Petrović, Ivanković, Fraser, Just
  — arXiv 2102.11378, an evaluation over almost 17 million mutants and 760,000 changes, with 2
  million mutants shown during code review), developers initially classified **85% of the mutants as
  unproductive**, and filtering and context-based suppression **raised the proportion of productive
  mutants from 15% to 89%**. Direct criterion consequence: **mutation without filtering of
  unproductive mutants dies on its own** — if you enable it without filtering, the team switches it
  off within two weeks.
- It is applied where there is decision logic. In mappings and DTOs it is noise.

### 4.4 Flaky tests: a hard policy

- **Detection, not intuition**: a test is flaky when it produces different results with the **same**
  commit. It is detected by (a) systematically re-running the suite on `main` with no changes, (b) a
  per-test historical record of the failure rate, (c) running in random order and in parallel, (d)
  flagging as suspect every test whose failure disappears on retry.
- Magnitude of the problem, with source — *Flaky Tests at Google and How We Mitigate Them*, John
  Micco, Google Testing Blog, May 2016, verbatim: *"across our entire corpus of tests, we see a
  continual rate of about 1.5% of all test runs reporting a 'flaky' result"*; *"Almost 16% of our
  tests have some level of flakiness associated with them!"*; *"about 84% of the transitions we
  observe from pass to fail involve a flaky test"*. That last figure is what sets the policy: **if
  most red failures are noise, the team stops looking at red** — and then the suite protects
  nothing.
- **Policy**: **immediate** quarantine (out of the gate, still running and still recorded), **a
  ticket with a named owner and a deadline**. Once the deadline passes: **it is fixed or it is
  deleted**. There is no third option.
- **FORBIDDEN: automatic retry as a solution.** A retry hides the failure, and the next one to pay
  for it will be production. A retry is admissible **only** as instrumentation that flags the test
  as flaky and triggers quarantine, never as a way of turning the build green.
- An explicit ceiling for the suite: if quarantine exceeds the threshold the team declares,
  **product work stops until it comes down**. A suite with chronic flakiness is a dead suite.

### 4.5 Suite time as a functional requirement

- **A slow suite stops being run**, and a suite that is not run does not exist. Time is a
  requirement, not a consequence.
- Default budgets (adjustable by ADR, not by resignation): **a module's unit tests locally < 10 s**;
  **full PR gate < 10 min**; **critical E2E < 15 min**. Once the budget is exceeded, the action is
  not "remove tests": it is parallelise, move cases to the right level and delete duplicates across
  levels.
- Per-test time is measured and published; the 20 slowest are reviewed periodically.
- The full suite (including nightlies, load, mutation) can take as long as needed **outside** the
  PR's critical path.

### 4.6 Mandatory regression

- **Every fixed bug leaves a test that fails before the fix and passes after.** Without that test,
  the fix is not approved (`code-review-standards`). The incident postmortem belongs to
  `incident-management-standards`; the test belongs here and is non-negotiable.
- TDD where it adds value: complex logic and **always** in a *bugfix* — first the test that
  reproduces it.

## 5. Security and test data

- **FORBIDDEN to copy personal data from production into any test environment**, including the
  "identical pre-production" one. Even if the environment is locked down: it changes the scope of
  processing, multiplies access and breaks minimisation. The policy and its legal basis belong to
  `privacy-engineering-standards`; **here the ban is operational and admits no exception for
  urgency**.
- Alternatives, in order: **synthetic data generated by factories**; derived data with
  **irreversible** anonymisation verified against re-identification (the technique and its
  validation are set by `privacy-engineering-standards`); a minimal *subset* of non-personal data.
- A test environment's *seed* is versioned in the repo and generated; a production dump is never
  restored.
- **FORBIDDEN to use real credentials, production tokens or live keys in tests.** Test secrets are
  fictitious and do not resemble the real ones. If a test secret can be used against a real system,
  it is a production secret (`secrets-management-standards`).
- Tests do **not** point at production, except for testing in production explicitly designed as such
  (§6.3), with data marked synthetic and isolated from analytics and billing.
- **Negative tests mandatory** on every boundary: malformed input, oversized input, wrong types,
  someone else's authorisation and no authentication. The happy path is not an acceptance criterion
  on its own. Vulnerability classes and their triage belong to `appsec-standards`.
- The test suite is supply-chain attack surface: Testcontainers images **pinned by digest**, test
  dependencies treated with the same rigour as production ones, and the CI runner without production
  credentials (`cicd-standards`).

## 6. Environments, testing in production and automating a11y and performance

### 6.1 Environment parity: the problem, said without euphemisms

- **No test environment equals production**, and chasing that equality is an endless expense: they
  differ in data, volume, concurrency, real latency, versions of managed dependencies, network
  topology and failure profile.
- **Which dimensions have parity** and which do not is declared **explicitly**: major version of the
  database engine and of the *runtime* **yes**; data volume and real traffic **no**. What has no
  parity **is not validated there**: it is validated with progressive delivery in production (§6.3).
- An **ephemeral environment per PR** > a long-lived shared environment. A shared environment
  accumulates state, turns into a *snowflake* and its failures stop being information.
- The environment is created with the **same** infrastructure code as production (`iac-standards`);
  otherwise its green means nothing.

### 6.2 What each environment tests

- Local and CI: unit tests, container-based integration, contracts.
- PR preview: critical E2E, automated a11y, *smoke*.
- Pre-production: data migrations against a realistic **synthetic** volume, a *rollback* rehearsal.
- Production: what only exists there (§6.3).

### 6.3 Testing in production

- It is not an excuse for not testing beforehand: it is the only way to validate **real traffic,
  real data and real scale**. It is designed as a test and operated under `sre-practice-standards`;
  the deployment mechanism belongs to `cicd-standards`.
- **Canary**: a small initial percentage, an **abort criterion defined before deploying** over
  symptom signals (latency, errors, saturation), and **automatic rollback**. A canary with no
  automated abort criterion is not a canary: it is a deployment with witnesses.
- **Feature flags**: they decouple *deploy* from *release* and allow enabling per cohort. Every flag
  is born with an **owner and a removal date**; a permanent flag is a dead branch in production.
- **Shadow traffic** (mirroring real traffic against the new version without returning its
  response): the way to validate performance and compatibility with real data. **It is mandatory to
  verify that the mirrored path produces no side effects**: no writes, no charges, no emails, no
  domain events. If you cannot guarantee it, do not enable it.
- **Data migrations**: backwards compatible (*expand/contract*), rehearsed on a copy with a
  realistic volume, with a tested *rollback*. It is the change that produces the most serious
  incidents and the one least tested.
- Every test in production requires **telemetry beforehand** (`observability-standards`): with no
  signal there is no test, there is a bet.

### 6.4 Accessibility and performance as automatable tests

- **Accessibility**: conformance is defined by `accessibility-standards`. Here: the automated check
  runs in the PR gate over the critical screens and **breaks the build** on a new violation.
  Mandatory honesty rule: **automated analysis covers a fraction of the criteria**; automated green
  is **not** conformance, and the accessibility skill sets what requires manual review.
- **Load**: it is designed here (scenarios, arrival profile, data, duration, stopping criterion);
  **latency thresholds and percentiles and the optimisation methodology belong to
  `performance-engineering-standards` / `web-performance-standards`**. Rules of this skill's own:
  the load test **never** goes in the PR gate (it is slow and noisy); it runs against an environment
  of declared size; its results are only comparable across runs with the **same** environment and
  **the same** data; and a load test with no prior hypothesis ("does it hold X req/s with p99 < Y?")
  is resource consumption, not a test.

## 7. Sustainability and prohibitions

- The suite is production code: it is refactored, dead parts are deleted and it is reviewed the same
  way (`code-review-standards`). An unmaintained test lies before it fails.
- Periodic review: the slowest tests, tests that have never failed in a year (candidates for
  deletion if they duplicate another level), quarantined tests, recurrent surviving mutants.
- Test tooling is updated at the same cadence as production tooling; an abandoned test tool blocks
  the language *upgrade*.
- **QA as a role is not the owner of quality**: quality is the responsibility of the team that
  delivers. A QA role adds value when it designs the strategy, builds instrumentation, explores what
  automation cannot see and challenges the acceptance criteria. **FORBIDDEN: the "QA at the end of
  the sprint validating what is already done" model**: it turns quality into an external filter,
  delays the signal and removes responsibility from whoever wrote the code. **Nobody approves their
  own acceptance criteria** and **nobody external signs off the quality of code they did not
  review**.

### Explicit prohibitions

- ❌ **FORBIDDEN** to fix here a language's *runner* or test syntax: that belongs to its skill (§1).
- ❌ **FORBIDDEN** to merge with tests disabled, commented out or marked *skip* without a ticket,
  owner and date.
- ❌ **FORBIDDEN** automatic retry to turn the build green (§4.4).
- ❌ **FORBIDDEN** to use coverage as a team goal or as an individual performance metric; it produces
  assert-less tests immediately and predictably.
- ❌ **FORBIDDEN** to exclude files from the coverage calculation to raise the number.
- ❌ **FORBIDDEN** `--update-snapshots` as a reaction to a failure without reviewing the diff (§3.7).
- ❌ **FORBIDDEN** real personal data in test environments, with no exception for urgency (§5). **The
  catalogue's only exception, and this skill does not grant it**: a migration's **cutover rehearsal**
  is done with **masked** real data on equivalent infrastructure, because its purpose is to measure
  duration and reconciliation, not to test code — the criterion belongs to
  `migration-projects-standards` and the masking to `privacy-engineering-standards`. Masked means
  irreversibly transformed before leaving the source, not "copied to an environment with fewer
  people watching".
- ❌ **FORBIDDEN** real credentials, tokens or keys in tests or in *fixtures*.
- ❌ **FORBIDDEN** `sleep`/*polling* as synchronisation in a test.
- ❌ **FORBIDDEN** for a test to depend on execution order or on state left by another.
- ❌ **FORBIDDEN** to mock your own internal components to avoid starting a dependency Testcontainers
  boots in seconds.
- ❌ **FORBIDDEN** to fix a bug without a regression test that fails before the fix (§4.6).
- ❌ **FORBIDDEN** E2E as the primary safety net: slow, unstable and with poor diagnostics.
- ❌ **FORBIDDEN** *shadow traffic* over routes with side effects (§6.3).
- ❌ **FORBIDDEN** to choose JMeter for a new project while it remains without releases (§2).
- ❌ **FORBIDDEN** to declare accessibility conformance based on an automated scanner's green.
- ❌ **FORBIDDEN** a load test with no hypothesis, no declared environment and no comparable data.

## 8. Mandatory web verification

Before fixing any of these points in a real project, check online:

1. **Pact**: the licence in the raw `LICENSE` of `pact-foundation/pact_broker` and of the *binding*
   you use; the status of the **"SmartBear supported"** model and what has become exclusive to
   PactFlow / API Hub for Contract Testing. Verified as of Aug-2026: core MIT; **gap**: there is no
   public quantified commitment replacing the old "10% of our engineering time".
2. **k6**: whether it is still **AGPL-3.0** and under Grafana Labs; the 2.x series version and
   whether any licence or ownership change appears after Aug-2026.
3. **JMeter**: whether a version after **5.6.3 (Jan-2024)** has been released. If one appears, revisit
   this prohibition. **Gap**: no official project statement about its maintenance status has been
   located — the conclusion here is inferred from the absence of releases, not declared.
4. **Gatling / Locust**: latest version and licence; and whether Gatling's OSS/Enterprise split has
   moved features to the commercial side.
5. **Testcontainers**: licence (MIT) and governance after Docker's acquisition of AtomicJar; which
   modules remain *community-driven*; Testcontainers Desktop account requirements. **Gap**: no
   official project governance page (maintainers, decision process) has been located — only product
   documentation.
6. **Playwright / Cypress / Selenium**: latest version, licence and activity. Do not accept any
   acquisition news without a primary source (precedent: the "purchase of Cypress.io by John Deere"
   is an April Fools' joke from 2025-04-01).
7. **Mutation**: per-language status of Stryker, PIT, `cargo-mutants`, `mutmut` and the equivalents
   in Go, PHP and .NET; and whether there is support for incremental mutation over the diff (without
   it, do not enable it).
8. **Coverage**: the exact values in the threshold table of *Code coverage at Google* (ESEC/FSE
   2019) — **declared gap, not verified in this pass**; and whether there is later published
   evidence about optimal coverage thresholds, which as of Aug-2026 **has not been located**.
9. **The cost of finding a defect late**: the folkloric "10x/100x per phase" figure **is not written
   in this skill** because its primary study has not been located. **Declared gap**: if the original
   source and its methodology are found, revisit.
10. Any tool in this skill that changes licence or enters maintenance (precedents from the
    catalogue: Trivy changed licence; gitleaks declared itself *feature complete*; Brakeman turned
    out to be paid despite the general belief). Source: the raw `LICENSE` and the project's official
    site, **not** the GitHub feed on its own — a project that moves organisation looks abandoned in
    the feed.

If the web contradicts this document, **the web wins** — flag the discrepancy.
