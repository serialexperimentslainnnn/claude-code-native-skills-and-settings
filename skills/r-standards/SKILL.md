---
name: r-standards
description: Use when writing, reviewing or productionizing R code - .R/.Rmd/.qmd/.Rproj files, DESCRIPTION, NAMESPACE, renv.lock, .Rprofile, .lintr, _pkgdown.yml, testthat tests, roxygen2 blocks, tidyverse/dplyr/ggplot2 or data.table pipelines, non-standard evaluation with {{ }} and .data, CRAN/Bioconductor/Posit Package Manager repositories, Shiny apps (app.R, server.R, ui.R), Plumber APIs (plumber.R), Quarto or R Markdown reports, Rcpp/cpp11 native code, or rocker/r-base container images.
---

# R standards (reference: August 2026)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all work in R: exploratory analysis, packages, reproducible reports, APIs, Shiny apps,
packaging and deployment. Triggers: `.R`, `.Rmd`, `.qmd`, `DESCRIPTION`, `NAMESPACE`, `renv.lock`,
`.Rprofile`, `.lintr`, `app.R`, `plumber.R`, `tests/testthat/`, `src/*.cpp` with Rcpp/cpp11.

**The axis of this skill**: R is an *analysis* language that ends up in production without having
been designed for it. A script that started on an analyst's laptop ends up serving an endpoint,
a scheduled report or a dashboard. This document sets out how that leap is made **with a safety
net**: reproducible environment, packaged code, tests, and an explicit trust boundary. R's
characteristic failure in production is not performance: it is that **nobody can rebuild the
environment that produced the number**.

**Not applicable**: see `mlops-standards` (**the model life cycle is hers**: model registry and
versioning, *feature store*, model serving and deployment, drift monitoring,
retraining, *train/serve skew* — **how the R that trains or scores is written is ours**),
`data-engineering-standards` (the data platform: ingestion, orchestration, idempotency, *backfill*,
Parquet, freshness SLA; the analysis code that consumes that platform is ours),
`analytics-bi-standards` (the dashboard as a decision artifact and its governance —
**a Quarto report or a Shiny app that replaces a BI tool is a decision of hers**;
the code of that report or app, ours), `data-warehouse-modeling-standards` (the shape of the
analytical model: grain, star, SCD), `lakehouse-standards` (table format and catalog behind
`arrow`/`duckdb`), `sql-standards` (**the SQL that `dbplyr` generates or that you write in
`DBI::dbGetQuery` is subject to her criteria**), `python-standards` (§7 sets when the correct
answer is Python), `julia-standards` (numerical performance; see §7), `gpu-computing-standards` (the
GPU as a resource that is provisioned, shared, monitored and paid for; the R code that uses it,
ours), `llm-app-engineering-standards` and `rag-standards` (AI application layer),
`ai-governance-standards` (model governance and regulatory compliance),
`c-standards`/`cpp-standards` (**the native code on the other side of `Rcpp`/`cpp11`**: memory, UB,
sanitizers, compiler flags; the boundary with R —`SEXP`, GC protection, packaging— is ours),
`fortran-standards` (**the Fortran kernel on the other side of `.Fortran()` or of a package with
`src/*.f90`**: `bind(c)`, contiguity, index order and compiler flags are hers; the boundary from R
is ours),
`cicd-standards` (the pipeline that runs the gates in §4), `kubernetes-standards` (deployment of the
image), `appsec-standards` (agnostic threat modelling; here only R's *sinks*),
`vulnerability-management-standards` (triage and SLA of the finding; here only scanning the
project), `secrets-management-standards`,
`observability-standards` (the OTel/Prometheus pipeline; here only the instrumentation in the code),
`api-design-standards` (the **contract** of a Plumber API: resources, codes, pagination,
versioning).

## 2. Default toolchain

> Verify the latest version on the web before committing to it in a real project (§8).

| Component | Choice | Verified as of Aug 2026 | Why |
|---|---|---|---|
| Runtime | **R** of the current stable series | 4.6.1 (2026-06-24); 4.6.0 came out 2026-04-24 | Minor **once a year, in spring**; patches when needed |
| "Conservative" version | Last patch of the previous series | 4.5.3 (2026-03-11) | R Core publishes a final patch of the previous series shortly before the next x.y.0. **R has no LTS**: the closest thing is that last patch, never >1 year old |
| Environment/reproducibility | **`renv`** | 1.2.3 (2026-05-16), MIT | **Non-negotiable**: `renv.lock` versioned or the project is not reproducible |
| Repository | **Posit Package Manager (P3M)** with a date snapshot | `https://packagemanager.posit.co/cran/YYYY-MM-DD` | Daily snapshots (working days) since 2017-10-10; Linux binaries. Plain CRAN does not give temporal reproducibility |
| Bioconductor | Only if the domain requires it | 3.23 (2026-04-29) ↔ R 4.6 | **Cycle coupled to R**: 2 releases/year; the Bioc version fixes the R version, not the other way round |
| Data manipulation | `dplyr`/`tidyverse` **or** `data.table` — choose one per project | dplyr 1.2.1 (2026-04-03), MIT; data.table 1.18.4 (2026-05-06), MPL-2.0 | See criteria below |
| Style | **`styler`** | 1.11.0 (2025-10-13), MIT | The GitHub repo has published no *release* since 2024 but **CRAN has**: it is not abandoned, it publishes via CRAN |
| Lint (CI gate) | **`lintr`** | 3.4.0 (2026-07-16) | Config in a versioned `.lintr` |
| Tests | **`testthat` 3rd edition** | 3.3.2 (2026-01-12) | Enabled **explicitly**: `Config/testthat/edition: 3` in `DESCRIPTION`. It is not the default |
| Documentation | **`roxygen2`** | 8.0.0 (2026-05-01) | Recent major: review breaking changes before upgrading |
| Reports | **Quarto** | quarto-cli 1.11.1 (2026-07-28) | Replaces R Markdown in a new project; Rmd only in legacy |
| HTTP API | **`plumber`** | 1.3.3 (2026-01-28), MIT | — |
| Interactive app | **`shiny`** (R package) | MIT | The **package** is MIT; the hosting is not (see §5/§7) |
| Data that does not fit | `arrow` + `duckdb` | — | It pushes the work outside R's RAM before rewriting in another language |
| Native | `cpp11` in new code; `Rcpp` in legacy | — | `cpp11` does not use heavy C++ macros and compiles faster; `Rcpp` is still the majority ecosystem |
| Container | **Rocker** images (`rocker/r-ver:<version>`) | — | `r-ver` pins the R version **and** the repository snapshot |

**Binary compatibility trap (verified)**: R 4.6.0 changed headers and the version of the graphics
engine API (16 → 17); already installed **compiled** packages stopped loading (reported cases:
`data.table`, `RSQLite`). Rule: when upgrading an R minor, **reinstall the whole library of compiled
packages**, do not reuse the previous `.libPaths()`. `renv::rebuild()` or a new image.

**tidyverse vs data.table vs base R criteria** (it is a criterion, not a side):
- **tidyverse** when the code is going to be read and maintained by analysts, when the project is
  already tidyverse, and when the volume fits comfortably in RAM. Cost: a large dependency
  tree and an API that evolves (deprecations with a cycle, but it evolves).
- **data.table** when performance or memory rule (aggregations over millions of rows,
  *updates by reference*), or when you want **a single dependency**. Its API is
  extraordinarily stable — a real argument for long-lived code. Cost: dense syntax.
- **base R** for packages with minimal `Imports` and for infrastructure utilities. Cost:
  verbosity and traps (§3).
- Forbidden to **mix the three styles in the same file**. A package may have different
  modules with different styles; a function, no.

## 3. Structure and conventions

**Loose script vs package — the criterion that defines this skill.** An analysis stops being a
script and becomes a **package** as soon as any of these happens: (a) a function is used from two
files, (b) somebody else is going to run it, (c) the result feeds a recurring decision, (d) it has
to be tested. Turning it into a package is what gives you, for free, everything an analysis in
production needs: a namespace, dependencies declared in `DESCRIPTION`, documentation with
`roxygen2`, tests with `testthat`, and `R CMD check` as a gate. **You do not need to publish on CRAN
to package.**

```
project/
  DESCRIPTION          # deps declared: Imports (real use), Suggests (optional), Depends almost never
  NAMESPACE            # generated by roxygen2 — never by hand
  renv.lock            # ALWAYS versioned
  .Rprofile            # activates renv; no business logic
  R/                   # functions; no code with effects on load
  tests/testthat/
  inst/                # entry-point scripts, templates
  analysis/ or vignettes/  # Quarto/Rmd that CALL R/, not that contain the logic
  src/                 # cpp11/Rcpp if applicable
```

- `library()` and `setwd()` **forbidden inside `R/`**: in a package, dependencies are declared in
  `DESCRIPTION` and used with `pkg::fun()` or `@importFrom`. Paths with `here::here()` or
  `system.file()`.
- No side effects on load: no `library()`, no global `options()`, no DB connections nor
  file reads in the body of `R/*.R`. Anything needing state goes in `.onLoad`/an explicit function.
- A Quarto/Rmd report **is not the place for the logic**: `.qmd` orchestrates and narrates; the
  functions live in `R/` and are tested. A report with 300 lines of embedded transformation is debt
  by default.
- Names: `snake_case` verbal functions; no `df`, `df2`, `tmp`; no `.` as a separator (it clashes with
  S3 dispatch). No catch-all `utils.R`.
- **S3 objects by default**; S4 only if the domain already requires it (Bioconductor) or dispatch on
  multiple arguments is needed; R5/RC practically never. **S7** exists but verify its maturity (§8)
  before committing to it in a new project.
- `options(stringsAsFactors)` no longer exists as a trap: since R 4.0.0 the default is `FALSE`. But
  legacy code that **assumed** factors still exists — when touching pre-4.0 code, check whether it
  depended on the coercion. Factors are created **explicitly**, with `levels` fixed by hand
  when the order matters; a factor with levels inferred from today's data breaks tomorrow.

**Language traps that are first-class bugs** (treat them as such, not as folklore):
- **Silent vector recycling**: `x + y` with different lengths does not always warn. Validate
  lengths at the edges; in critical arithmetic, `stopifnot(length(x) == length(y))`.
- **`NA` propagates**: `sum(x)` without `na.rm` gives `NA`; `if (NA)` is an error; `x == NA` is `NA`,
  use `is.na()`. Decide **explicitly** per column what `NA` means — never `na.rm = TRUE` by
  reflex, because it changes the semantics of the result without leaving a trace.
- `[` on a `data.frame` with a single result collapses to a vector: use `drop = FALSE` or tibbles.
- `sapply()` returns different types depending on the data: in production code, `vapply()` with
  an explicit `FUN.VALUE` or `purrr`'s typed variants (`map_dbl`, `map_chr`).
- Comparing floats with `==`: `all.equal()` / a tolerance.
- Lazy evaluation of arguments: `force()` when you capture arguments in closures.

**Non-standard evaluation (NSE)**. *Tidy* evaluation is what makes `dplyr` readable **and what
breaks defensive programming**: inside `filter(data, x > 1)`, `x` is not a variable of the
environment, it is a column, and if the column does not exist R may silently pick up an object from
the environment with that name. Hard rules:
- In **package functions**, always reference columns with the `.data$col` pronoun (or
  `.data[[var]]`) — that way the failure is "non-existent column", not "it took your global
  variable".
- To pass column names from your function's arguments: `{{ arg }}` (*embracing*); for
  several, `...` passed through as is. `!!sym(chr)` only if the name arrives as a string.
- `aes_string()`, `filter_()`, `mutate_()` and the rest of the `_` variants are **retired**: they
  are not used.
- Declare `.data` (and the column names you use in NSE) so that `R CMD check` does not generate the
  classic "no visible binding for global variable" — with `utils::globalVariables()` as a last
  resort, not as the norm.

**Errors and conditions**:
- `stop()`/`warning()` with an actionable message; in new packages, `rlang::abort()` with a
  **condition class** so that the caller can catch by class (`tryCatch(err_empty_data = ...)`)
  instead of by `grepl` over the message.
- **Failing is correct; returning a half-finished result is not.** Forbidden: `try(..., silent =
  TRUE)` without inspecting the result, and blanket `suppressWarnings()` over a whole block.
- `on.exit(add = TRUE)` to release connections, files and modified `options()` — R's `defer`.
- `warning()` does not interrupt: nothing critical is signalled with `warning`.

## 4. Quality: formatting, linting, tests, documentation

- **Formatting**: `styler` (tidyverse style guide) applied to the whole repo; a single
  configuration.
- **Lint**: `lintr` with a versioned `.lintr`, run in CI as a gate. Minimum: a fixed line length,
  `object_name_linter`, `seq_linter` (`1:n` is a bug when `n == 0` → `seq_len(n)`),
  `undesirable_function_linter` (vetoes `attach`, `setwd`, `sapply`, `library` in `R/`),
  `T`/`F` forbidden (they are reassignable variables; use `TRUE`/`FALSE`).
- **Tests with `testthat` 3rd edition** (`Config/testthat/edition: 3`):
  - One test file per file in `R/`; `expect_*` with AAA and one failure reason per test.
  - Cover the happy path **and the edges**: empty vector, `NA`, `NULL`, missing column, unexpected
    type, factor with an unseen level, date in another time zone, duplicates.
  - Snapshot tests (`expect_snapshot`) for error messages and formatted outputs; review the
    `_snaps/` in the PR as code.
  - Randomness: explicit `set.seed()` in the test, or `withr::local_seed()`. No tests that
    depend on the environment's global `RNGkind`.
  - No public network and no writing to the user's directory: `withr::local_tempdir()`.
  - Every fixed bug leaves a regression test. Flaky = fixed or deleted.
- **Documentation**: `roxygen2` for every exported function (`@param`, `@return`, runnable
  `@examples`). An `@export` without documentation is a review failure. `pkgdown` if the package is
  consumed by third parties.
- **CI gates** (they block the merge, cheapest first):
  1. `renv::status()` — fails if the lock is out of sync.
  2. `styler` in check mode + `lintr::lint_package()`.
  3. `R CMD check --as-cran` (or `devtools::check()`): **zero ERROR, zero WARNING**; NOTEs are
     justified in writing or fixed.
  4. `testthat` with coverage (`covr`); an agreed threshold — coverage is a signal, not a goal.
  5. Dependency audit (§5) and building the image.
- **CI matrix**: the R version pinned in production, plus the previous one if you support external
  users. Pin the P3M snapshot in CI so that a CRAN release does not break yesterday's build.

## 5. Stack security

**`readRDS()` / `load()` / `unserialize()` over untrusted input is code execution.** A serialised R
object can carry environments, promises and classes with methods that run when printed or when
restored. Rule: **never** deserialise an `.rds`/`.RData` that comes from outside your
trust boundary; for exchange use pure data formats (Parquet, CSV, JSON) validated when
read. `load()` also pollutes the global environment — forbidden in package code.

- **`eval(parse(text = ...))` over user input: FORBIDDEN.** It is R's `eval` and it is the classic
  Shiny vulnerability. Nor `parse()`, `str2lang()`, `source()` of paths built
  with input, nor `do.call(name_as_text, ...)` without an allowlist.
- **Shiny exposes R to the Internet.** Every `input$*` is hostile input:
  - Validate **on the server**, not in the UI: the constraint of a `selectInput` does not exist in
    the protocol, a client can send any value. `validate()`/`req()` are not security
    validation.
  - Never use `input$*` to build SQL, file paths, object names or commands
    (`system()`, `system2()`). An allowlist of permitted values, not a *blacklist*.
  - `fileInput`: a size limit (`shiny.maxRequestSize`), type verified by content, and the
    file processed in a temporary location — never served back and never deserialised.
  - HTML: `HTML()`, `tags$script`, `htmltools::HTML` and `renderText` with `escape = FALSE` are XSS
    if input gets in. By default, escaped text.
  - Authentication: **open source Shiny Server ships no authentication** — it is solved in front
    (reverse proxy with OIDC) or with a product that includes it. Do not implement login in the
    `server()` itself.
- **SQL**: `DBI::dbGetQuery` with `params = list(...)` or `glue::glue_sql()`; `paste0()` of input
  into a query is an absolute veto. With `dbplyr`, review the generated SQL (`show_query()`) — its
  criteria belong to `sql-standards`.
- **`install.packages()` at run time: FORBIDDEN in production.** Installing from the
  started container or from an app's `server()` means the artifact is not immutable,
  that the build depends on the network and that the version running today is not the one that was
  tested. All dependencies are installed at build time, from a pinned snapshot. The same for
  `remotes::install_github()` outside a `Dockerfile` with the commit pinned by SHA.
- **CRAN does not audit security.** CRAN checks that the package *works*, not that it is secure nor
  that its maintainer is still alive. Before adding a dependency: recent maintenance, number of
  maintainers, licence, and whether it drags in a `SystemRequirements` that widens the container's
  surface. A package can execute arbitrary code on installation (`configure`, `.onLoad`).
- **Dependency audit**: the R ecosystem **has no mature equivalent to `pip-audit`**.
  What there is: **`oysteR`** (CRAN 0.1.4, 2025-10-09, Apache-2.0), which queries Sonatype OSS
  Index; the project itself states that it **is not supported by Sonatype** (a community
  contribution) and that heavy use runs into *rate limiting*. Use it as a signal
  (`audit_renv_lock()` in CI, non-blocking at first), complemented with OSV/GitHub Advisories over
  the `renv.lock`, and **assume incomplete coverage**: the absence of findings in R is not evidence
  of the absence of vulnerabilities. Check in §8 whether something better has appeared.
- **Secrets**: never in `.Rprofile`, a versioned `.Renviron`, `renv.lock`, code or reports. Env
  vars or a manager; local `.Renviron` in `.gitignore`. Careful with `.RData` files saved on exit:
  disable automatic session saving (`--no-save`, `--no-restore` in any non-interactive
  run) — an `.RData` with credentials in the repo is a classic incident.
- **Reports**: a rendered Quarto/Rmd embeds whatever you print. Check that no connection
  strings, tokens or personal data come out in the outputs or in the warning messages.
- **Containers**: an image based on `rocker/r-ver` with the R version and snapshot pinned, non-root,
  multi-stage. **The real problem with R in containers is the system dependencies**: many
  packages compile against OS libraries (`libcurl`, `libxml2`, `libssl`, `libgdal`, `libproj`,
  `libgit2`). Install them explicitly in the `Dockerfile` (P3M exposes the `SystemRequirements`);
  do not trust that "they were in the base image". And do not leave them in the final image if they
  were only needed to compile.

## 6. Performance and operability

- **Order of attack**, in this order and no other: (1) measure (`profvis`, `bench::mark`) — never
  optimise by intuition; (2) vectorise and eliminate object growth in loops (`x <- c(x, i)` is
  quadratic: preallocate or use `vapply`); (3) `data.table` for heavy aggregation/joins; (4) push
  the computation to `arrow`/`duckdb` or to the database when the data does not fit in RAM; (5)
  `cpp11`/`Rcpp` only for the loop that genuinely cannot be vectorised, and only after 1-4.
- **R copies on modify** and the memory peak is the problem, not the CPU. `data.table` modifies by
  reference (`:=`) — powerful and a source of bugs if the object is shared: document when a
  function mutates its argument, or return an explicit copy.
- Parallelism: `future`/`furrr` or `parallel`. `multicore` (fork) **is not safe on a Shiny/
  Plumber server nor on Windows**: use `multisession` or external processes. Never launch more
  *workers* than the cores assigned to the container — R does not see the cgroup limit on its own.
- **Plumber**: it is **single-threaded**. One slow request blocks everybody. Scale with multiple
  processes behind a load balancer, explicit timeouts on every outbound call
  (`httr2::req_timeout`), and heavy work outside the request. `/healthz` and `/readyz` endpoints;
  structured logging with a *correlation id*.
- **Shiny in production**: each session is state on the server and one R process serves N sessions in
  **a single thread**. Consequences: any long computation in `server()` freezes all the users
  of that process (move it to `future`/a job queue or precompute); session state does not survive
  the process crashing nor migrate between replicas (**session affinity mandatory** on the load
  balancer, and an app that "restarts on its own" is a user losing their work); badly isolated
  reactivity = data leaks between sessions if you put state in the global environment. Size by
  **concurrent sessions and RAM per session**, not by requests/second. Large shared read-only
  objects: load them once outside `server()` (they are shared across sessions of the same process),
  never per-user data.
- DB connections: a *pool* (`pool`) with limits; one connection per Shiny session exhausts itself.
  Always close with `on.exit`.
- Scheduled reports: idempotent, with explicit parameters and versioned output. A report that
  fails must **fail loudly**, not publish yesterday's version.
- Seed and versions in the artifact: every report/model publishes the R version, the `renv.lock` (or
  its hash) and the seed. Without that, a number is not reproducible even if the code is in git.

## 7. Long-term sustainability

- **Cadence**: an R minor once a year (spring) — plan it as an event, with reinstallation of
  compiled packages and a full run of the suite. R patches, apply them. P3M snapshot:
  **advance it deliberately** (quarterly, with the suite green) instead of floating or freezing it
  for years; a 3-year-old snapshot is as dangerous as having none, because the day it has to be
  moved the jump is impossible.
- Bioconductor drags the R version along: if you depend on it, your calendar **is theirs** (two
  releases a year), not the other way round.
- Deprecations: tidyverse warns with long cycles but it warns; `lifecycle` badges and
  `DeprecationWarning` are treated as debt with an issue, they are not silenced. `data.table`
  hardly ever breaks its API — that is its value.
- A dependency with no release in >2 years or with a single maintainer is reviewed; if it is on the
  critical path of production, the function you use is vendored or replaced.
- **Debt from an analysis that becomes a service**: when a script starts serving traffic,
  **it is rewritten as a package with tests** before exposing it, not afterwards. "We'll wrap it in
  Plumber and that's it" is the most expensive debt in this ecosystem: nobody knows what inputs it
  accepts, there are no tests, the state lives in the global environment and the first incident is
  at 3 in the morning. If there is no budget for the rewrite, there is no budget for the service:
  publish it as a scheduled report.

**When NOT to choose R** (honesty first):
- ❌ R as a general-purpose *application* language (transactional backend, system CLI,
  microservice with business logic): use Python, Go or TypeScript.
- ❌ R for pipeline or infrastructure orchestration: that is `data-engineering-standards`.
- ❌ R because "the analyst knows it": if the artifact is a service with an SLA and nobody on the
  team maintains R in production, the correct choice is to port it.
- ✅ **R is the right answer** against Python in: serious statistical modelling (mixed models,
  survival, time series, Bayesian inference, experimental design), biostatistics and
  Bioconductor, publication-quality graphics (`ggplot2`), and reproducible reports where the
  narrative and the computation go together. There R's ecosystem of specialised packages has no
  equivalent.
- ✅ **Python** (see `python-standards`) when the work is *engineering* around the analysis:
  serving, integration, production ML, orchestration, or when the team that will maintain it is an
  engineering one. Pragmatic boundary: if the result is a number or a report, R; if the result is a
  system, Python.
- ✅ **Julia** (see `julia-standards`) only when the bottleneck is a numerical loop that does not
  vectorise. The choice is almost never "R or Julia": R is statistics and communication of results,
  Julia is numerical performance. They share the niche of "a scientific language that is not
  Python" and little else.

**List of prohibitions (veto):**
- ❌ A project in production without a versioned `renv.lock`, or with a CRAN repository without a
  pinned snapshot.
- ❌ `install.packages()` / `remotes::install_github()` at run time in production.
- ❌ `readRDS()`/`load()`/`unserialize()` over untrusted input. `load()` inside a package.
- ❌ `eval(parse(text = ...))` with user input. `source()` of a path built with input.
- ❌ `setwd()`, `attach()`, `library()` inside `R/`; `rm(list = ls())` as a "restart".
- ❌ Relying on the session's saved `.RData`: always run with `--no-save --no-restore`.
- ❌ SQL via `paste0`. Shiny input into `system()`, paths or object names without an allowlist.
- ❌ `T`/`F` instead of `TRUE`/`FALSE`. `1:n` where `n` may be 0. `sapply()` in production code.
- ❌ `na.rm = TRUE` by reflex, without deciding what `NA` means in that column.
- ❌ Blanket `suppressWarnings()`/`try(silent = TRUE)`; catching and swallowing with no log and no
  re-raise.
- ❌ Retired NSE variants (`aes_string`, `*_` with an underscore) in new code.
- ❌ Business logic inside a `.qmd`/`.Rmd` instead of in `R/` with tests.
- ❌ `R CMD check` with a WARNING and "we'll look at it later"; a NOTE with no written justification.
- ❌ User state in the global environment of a Shiny app (leakage between sessions).
- ❌ Upgrading an R minor while reusing the previous library of compiled packages (see §2).
- ❌ A long synchronous computation inside Shiny's `server()` or a Plumber endpoint.

## 8. Mandatory web verification

Before committing to versions or decisions, **verify online** (WebSearch/WebFetch; for versions, the
Atom feeds of GitHub Releases and the CRAN pages — not the summariser over GitHub's HTML):
1. The latest stable R and the last patch of the previous series (`cran.r-project.org/src/base/R-4/`,
   `developer.r-project.org`). As of Aug 2026: **4.6.1 (2026-06-24)** and **4.5.3 (2026-03-11)**.
   **R has no declared LTS** — do not assert it.
2. The Bioconductor version and the R version it is coupled to
   (`bioconductor.org/about/release-announcements/`). As of Aug 2026: **3.23 ↔ R 4.6**.
3. The state of Posit Package Manager (snapshot URL, binary coverage per distro, availability
   of the public service and its terms of use). Public snapshots exist since 2017-10-10 and only
   on working days.
4. Versions and **licences** of `renv`, `styler`, `lintr`, `testthat`, `roxygen2`, `plumber`,
   `data.table` (MPL-2.0, not MIT), `shiny`. Check **CRAN as well as GitHub**: `styler` has
   published no *release* on GitHub since 2024 but its latest CRAN version is 1.11.0 (2025-10-13) —
   a quiet repo ≠ an abandoned package.
5. **Posit's commercial model** (an expensive and changing figure): the `shiny` package is MIT and
   **open source Shiny Server is AGPL-3.0**, but **Shiny Server Pro was discontinued on 2026-03-31**
   and Posit directs you to **Posit Connect**, commercial and licensed by active users;
   anonymous public access to interactive content is a **paid entitlement** (Enhanced/Advanced
   licence). Verify before designing hosting: prices not published, alternatives ShinyProxy (open
   source) and Connect Cloud/shinyapps.io. **Declared discrepancy**: I have found no official
   Posit statement putting open source Shiny Server into maintenance mode, but its last *release*
   on GitHub is from **2024-09-30**; treat its future as an open risk, not as a fact.
6. Vulnerability auditing: the state of `oysteR` and whether a maintained alternative already exists
   (post-check: as of Aug 2026 there is none). **Declared gap, not verified as of Aug 2026**: the real coverage
   of CRAN in OSV/OSS Index (what percentage of packages have advisories) I have not been able to
   quantify — do not assert it.
7. **Declared gap, not verified as of Aug 2026**: the maturity of **S7** as the default object system and
   whether it has already entered base R; and the state of `cpp11` versus `Rcpp` after the header
   change in R 4.6.0.
8. Breaking changes in `roxygen2` 8.x and in R's 4.6 series (graphics API 16→17, headers) from the
   official `NEWS` before any upgrade — never from third-party blogs without cross-checking.

If the web contradicts this document, **the web wins** — flag the discrepancy.
