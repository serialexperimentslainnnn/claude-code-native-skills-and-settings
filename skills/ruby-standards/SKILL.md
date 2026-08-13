---
name: ruby-standards
description: Use when writing, reviewing or upgrading Ruby code and Rails applications - .rb/.rake/.gemspec/.erb files, Gemfile, Gemfile.lock, .ruby-version, Rakefile, config/application.rb, db/migrate, ActiveRecord models, Sidekiq or Solid Queue workers, RSpec spec/ or Minitest test/, .rubocop.yml, standardrb, Brakeman, bundler-audit, RBS sig/ or Sorbet sorbet/rbi, rbenv/mise/asdf Ruby toolchains, bundle exec, gem publishing to RubyGems, or Rails upgrades and YJIT/ZJIT tuning.
---

# Ruby and Rails standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all Ruby work: Rails applications, gems, Ruby scripts, Rakefiles, review and upgrade.
Triggers: `.rb`, `.rake`, `.gemspec`, `.erb`, `Gemfile`, `Gemfile.lock`, `.ruby-version`, `.rubocop.yml`,
`config/`, `app/models`, `db/migrate`, `spec/`, `test/`, `sig/`, `sorbet/`, `bundle`, `rails`, `gem`.
Sets **criteria** (what to use, what is vetoed, what to verify), not tutorials.

**Not applicable**: see `api-design-standards` (the API **contract** — resources, codes, pagination,
RFC 9457, versioning — is theirs; here only its implementation in controllers and serializers),
`microservices-architecture-standards` (where a service is cut and how they talk to each other; here only
the Ruby inside), `kubernetes-standards` and `container-runtime-security-standards` (OCI packaging
and runtime of the container running Puma), `cicd-standards` (the pipeline and its gates; here only which
tool is run and with what configuration), `secrets-management-standards` (owner of the choice
of secrets manager and of the secret scanner; here only that Rails does not put them in the repo),
`appsec-standards` and `vulnerability-management-standards` (threat modelling, process and triage;
here the code criteria and which gate breaks the build), `sql-standards` (the SQL language itself),
`data-platform-standards`, `mysql-mariadb-dba-standards`, `oracle-dba-standards` and
`sqlserver-dba-standards` (engine operation: tuning, replicas, backup, HA). Active Record decides
**how the application accesses**, not how the database is operated.
`python-standards`, `go-standards`, `typescript-standards`, `jvm-spring-standards`, `rust-standards`,
`php-standards`, `elixir-erlang-standards` (choice of language and implementation in each);
against **`elixir-erlang-standards`** in particular: they share syntactic origin and much of the
community, but **not** the execution model — the boundary is the BEAM (processes, supervision,
distribution) versus the CRuby VM (GVL, OS processes, Puma/Sidekiq).
`bash-linux-scripting-standards` (system automation: if the Ruby operations script is
glue around commands, it is theirs; if it needs data structures and tests, it comes back here),
`iac-standards` (the **infrastructure DSL** of Chef/Puppet/Vagrant belongs to `iac-standards` even if
written in Ruby; the **Ruby that is written** inside — libraries, custom resources, tests — belongs to
this skill), `observability-standards` (telemetry strategy and pipeline; here the instrumentation
in the code), `message-brokers-standards` (Kafka/RabbitMQ as infrastructure; here the Ruby
consumer and the job queue), `crystal-standards` (boundary named because the
confusion is real: **Crystal's compatibility with Ruby is syntactic, not semantic nor of
libraries**. There are no gems, no runtime `method_missing`, no dynamic monkey patching:
a Ruby file is not ported by changing its extension. If the reason to migrate is performance,
measure it first with YJIT), `smalltalk-standards` (**direct lineage**: Ruby's object and
message model comes from there; living Smalltalk —Pharo, Squeak, GemStone/S, VAST— is theirs).

## 2. Default toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Minimum | Why |
|---|---|---|---|
| Runtime | **CRuby (MRI)** | **3.4** in maintenance; **4.0** in greenfield | 4.0 shipped 2025-12-25 (4.0.6 as of 2026-07); 3.4 EOL 2028-03-31, 3.3 EOL 2027-03-31 |
| Version manager | **mise** (or `rbenv` if the team already uses it) | — | `asdf` valid if it already manages other runtimes; **never** the system Ruby |
| Version pinning | `.ruby-version` + `ruby "x.y.z"` in `Gemfile` | — | A single source of truth, read by the manager and by Bundler |
| Dependencies | **Bundler** + committed `Gemfile.lock` | — | `bundle install --frozen` / `BUNDLE_FROZEN=true` in CI |
| Web framework | **Rails 8.1** | 8.0 minimum | 8.1 shipped 2025-10-22, EOL 2027-10-10; 7.2 EOL 2026-08-09; 8.1 requires Ruby ≥3.2 |
| Linter/formatter | **RuboCop 1.88+** with `rubocop-rails`, `rubocop-rspec`, `rubocop-performance` | — | MIT. Alternative: `standard` (closed config) |
| SAST | **Brakeman 8.x** | — | ⚠️ **NOT MIT**: "Brakeman Public Use License" (Synopsys) — commercial use requires a paid licence (§7) |
| SCA | `bundler-audit` (ruby-advisory-db) + Dependabot/Renovate | 0.9.3+ | GPL-3.0-or-later |
| Tests | **RSpec 3.13** or **Minitest 6** (criteria below) | — | RSpec 4 only in beta as of 2026-08 (`4.0.0.beta1`, Feb 2026): **not** in production |
| Safe migrations | **strong_migrations** | 2.8+ | Blocks DDL that takes long locks |
| Jobs | **Solid Queue** (Rails 8 default) or **Sidekiq 8** | — | Solid Queue 1.6+; Sidekiq is **LGPL-3.0**, check the legal fit |
| Gradual typing | **RBS 4 + Steep 2** or **Sorbet** (criteria below) | — | Neither is mandatory; adopt only with a maintenance budget |
| Server | **Puma** | — | Workers and threads sized, not left at defaults |

**Ruby version policy**: one Ruby minor per year, within 6 months of its release.
Ruby ≤3.2 is EOL (3.2 died 2026-03-31) → **it is not deployed**, not "we will upgrade later".
Rails: from supported release to supported release; an app on a Rails whose support has expired is an open
security incident, not technical debt.

**JIT**: **YJIT** is the production option (mature since Ruby 3.2, deployed at scale at Shopify,
Discourse, Mastodon; real gains of 15-25 % in Rails apps, much smaller if the bottleneck is the
database or an external API). **ZJIT** (Ruby 4.0, written in Rust, `--zjit`) is **experimental**:
Ruby 4.0's own notes describe it as faster than the interpreter but **slower than
YJIT** → forbidden in production until the official source says otherwise. Enable YJIT
explicitly (`--yjit` / `RUBY_YJIT_ENABLE=1`) and **measure before and after**; verify in §8 whether some
version already enables it by default. YJIT consumes extra memory: bound it with `--yjit-mem-size`.

**RSpec vs Minitest — criteria, not sides**:
- **Minitest** if: it is a gem, the team is small, you want zero DSL and the Rails default.
- **RSpec** if: the app is large, the team already masters it, and you exploit `shared_examples` and domain
  matchers. The cost is the DSL: nested `let` and implicit `subject` produce unreadable tests.
- **Pick one per repo**. Two test frameworks coexisting is debt, not flexibility.

**Gradual typing — real state as of 2026-08 and criteria**:
- **RBS** (official from the core team, ships with Ruby) 4.1.x + **Steep** 2.0: signatures in separate
  `.rbs` files, structural typing. Advantage: it is the language standard. Cost: worse editor tooling
  and signatures that drift out of sync with the code.
- **Sorbet** (Stripe/Shopify, Apache-2.0, continuous releases — `0.6.x` with build-based versioning):
  inline `sig` annotations + `.rbi`, nominal typing, checking also at runtime. Advantage: more polished
  tooling and the largest industrial adoption base. Cost: invasive syntax in the Ruby code.
- **Neither is the ecosystem default**. Adopt types only if there is a domain with invariants that the
  tests do not cover well and **continuous budget** to maintain the signatures. A published experiment
  measured that raising test coverage found more bugs than gradual typing: if you have to choose
  with limited resources, tests first.
- If you adopt: only one, gate in CI (`steep check` or `srb tc`), and `sig`/`sig/` mandatory on the public
  API. Half-done typing without a gate is worth nothing.

## 3. Structure and conventions

- **Convention over configuration**: in Rails, respect the standard layout. Relocating directories or
  inventing your own autoloading breaks Zeitwerk and adds nothing.
- Modern Rails = **Rails 8 defaults**: Propshaft (not Sprockets), Solid Queue / Solid Cache /
  Solid Cable, Kamal 2 for deploy, Importmap or jsbundling depending on the front end. In existing apps the
  migration to the "Solid" stack is **optional and incremental** — it is not a requirement to be current.
- `app/models` is not the dumping ground for logic. Domain objects in `app/services`,
  `app/queries`, `app/policies`, `app/forms`; the model persists and validates, it does not orchestrate.
- **Active Record callbacks**: the number one source of hidden coupling. Veto `after_save` that
  calls external services, sends mail or enqueues jobs without transactional control. Whatever triggers
  effects goes in an explicit service object, invoked from the use case.
- **`default_scope`: forbidden**. It contaminates every query, surprises in `unscoped`, breaks
  `create`/`update` and makes any debugging unreadable. Use named scopes.
- **`Concern` with state**: an `ActiveSupport::Concern` that adds callbacks and attributes to the
  including class is inheritance in disguise. Concerns only for behaviour without shared state.
- Migrations and `schema.rb`/`structure.sql` committed; a single source of truth for the schema.
  If you use PostgreSQL features that `schema.rb` does not represent (types, functions, triggers,
  exclusion constraints), switch to `structure.sql` — not "it almost works".
- **Gem vs monolith**: extract a gem only when there are ≥2 real consumers and an owner. An internal
  gem with one consumer is a monolith with an extra repo, version and CI hop. Inside
  the monolith, use modules/engines with explicit boundaries before splitting it.
- Publishable gems: `.gemspec` with `required_ruby_version`, `metadata["rubygems_mfa_required"] =
  "true"`, SemVer, changelog, and publication from CI with **Trusted Publishing (OIDC)** — never with
  a long-lived API key in a secret nor `gem push` from the laptop.
- `Gemfile`: no version → forbidden in production. Constraint by `~>` in gems, exact in the lock.
  No `git:` or `path:` pointing at branches on the main branch.
- **Dependency policy**: every new gem is justified (what does it solve that stdlib or
  Rails does not?), maintenance is checked (last release, open issues, number of maintainers) and
  licence. A gem with no release in >18 months is reviewed or replaced.

## 4. Quality and testing

- **Format and lint**: `rubocop` with `NewCops: enable` and the extensions `rubocop-rails`,
  `rubocop-rspec`/`rubocop-minitest`, `rubocop-performance`. **Exact** pin of the RuboCop version
  in the `Gemfile`: every minor adds cops and breaks CI if it floats.
  - Mandatory cops (do not disable): the whole `Security` department (`Security/Eval`,
    `Security/Open`, `Security/YAMLLoad`, `Security/MarshalLoad`, `Security/JSONLoad`),
    `Lint/*` (especially `Lint/SuppressedException`, `Lint/ShadowedException`), `Rails/SaveBang`,
    `Rails/OutputSafety`, `Rails/SkipsModelValidations`, `Rails/UniqueValidationWithoutIndex`,
    `Rails/HasManyOrHasOneDependent`, `Rails/Output`, `Rails/TimeZone`.
  - Debatable and team-adjustable: `Metrics/*`, `Style/*`. Set the values once in
    `.rubocop.yml` and stop arguing about them.
  - `rubocop:disable` **always** with a specific cop and a reason on the same line. `.rubocop_todo.yml`
    is a debt list with an expiry date, not a permanent file.
- **`standard` (standardrb)** as an alternative: when the team loses more time arguing about
  `.rubocop.yml` than writing code. It is RuboCop with closed configuration. You give up the domain
  cops (Rails, RSpec) unless you add their plugins. If you need your own rules, it is RuboCop.
- **Tests**:
  - AAA, one failure reason per test, names that describe observable behaviour.
  - Happy path **and edges and errors**: invalid input, non-existent record, denied permissions,
    race conditions, external service timeouts, uniqueness validations under concurrency.
  - **Logic in tests is forbidden**: no `if`/`each`/calculations that rebuild the expected
    result. Literal expected value or the test proves nothing.
  - **`factory_bot`**: minimal factories (only what is mandatory), `build`/`build_stubbed` by default and
    `create` only when the DB is needed. Traits for variants; factories that create
    association trees "just in case" are forbidden — they are the usual reason for a slow suite.
  - **Fixtures**: valid and fast for stable reference data (countries, plans, roles). As the
    base of all domain tests they become global coupling; do not mix them with
    factories for the same thing.
  - System tests (Capybara) only as many as needed: expensive and fragile. Pyramid, not hourglass.
  - Forbidden: `sleep` in tests, order dependence and calls to the public network (`webmock`/`vcr` with
    reviewed cassettes and no secrets inside).
  - Every fixed bug leaves a regression test. Flaky = fixed or deleted.
- **CI gates** (block merge, from cheap to expensive):
  1. `bundle install --frozen` / `bundle exec bundler-audit check --update`
  2. `rubocop --parallel` (or `standardrb`)
  3. `brakeman --no-pager -q -w2` (fails on high/medium confidence findings)
  4. `steep check` / `srb tc` if the repo adopted types
  5. `rspec`/`rails test` unit → integration with the **same** database as production
  6. Migration audit (`strong_migrations`) and image build
- Rails 8.1 ships `bin/ci` to run the same sequence locally: use it, but **CI is the
  authority**, not the local hook. If CI does something irreproducible locally, it is a pipeline bug.
- Coverage (`simplecov`) as a signal, not a target; agreed threshold, no tricks to raise it.

## 5. Stack security

- **Deserialisation — Ruby's historic sink**:
  - ❌ `YAML.load`, `YAML.load_file`, `Psych.load` over untrusted input. Use
    `YAML.safe_load` with explicit `permitted_classes`. (Psych 4+ makes `load` safe by default,
    but do **not** depend on the version: write `safe_load` and leave the `Security/YAMLLoad` cop enabled.)
  - ❌ `Marshal.load` over any data coming from outside the process. Never, without exception.
  - ❌ `JSON.load` (use `JSON.parse`), `ERB` with a user-controllable template. Recent
    precedent: CVE-2026-41316, bypass of `ERB`'s deserialisation guard via
    `def_module`/`def_method`/`def_class` — verify the advisory in §8.
  - ❌ Session cookies with `Marshal` as serialiser: use `:json`.
- **Dynamic execution**: ❌ `eval`, `instance_eval`, `class_eval`, `binding.eval` with user
  data. ❌ `send`/`public_send`/`constantize`/`safe_constantize` with a name coming from the
  request — if you need dynamic dispatch, an explicit allowlist of permitted symbols.
  ❌ `system`, backticks, `Kernel#open`, `%x{}` with interpolation of input.
- **Mass assignment**: strong parameters always (`params.require(...).permit(...)`). ❌ `permit!`.
  ❌ `permit` including `:role`, `:admin`, `:user_id` or any authorisation field.
- **SQL injection**: only parameterised queries (hash conditions or `where("x = ?", v)`). ❌
  string interpolation in `where`, `order`, `pluck`, `find_by_sql`, `joins`. `order` with a
  user parameter requires a column allowlist — it is the classic vector and the ORM does not protect you.
- **XSS**: ERB escapes by default; ❌ `html_safe`, `raw` and `sanitize` over user content without
  a strict allowlist. Cop `Rails/OutputSafety` enabled. CSP configured (`content_security_policy` in
  Rails), not permissive for convenience.
- **CSRF**: `protect_from_forgery` with the default strategy (`:exception`), never `:null_session`
  on endpoints with a session. ❌ global `skip_before_action :verify_authenticity_token`; if an API
  endpoint needs it, it is because it should authenticate with a token and not with a session cookie.
- **Authorisation**: on **every** action, not just in the generic `before_action`. Pundit/Action Policy
  with default deny and a test that verifies no action is left without a policy. IDOR is prevented
  by always querying from the user's scope (`current_user.orders.find(params[:id])`), never
  `Order.find(params[:id])`.
- **Secrets**: `config/credentials.yml.enc` is acceptable for small apps if `master.key` is **not**
  in the repo and is injected by environment; in an organisation, an external manager (see
  `secrets-management-standards`). ❌ secrets in plain `config/*.yml`, in logs or in fixtures.
  `filter_parameters` covering password, token, secret, and the sensitive domain fields.
- **SAST**: Brakeman as a gate. ⚠️ Its licence is **not OSS**: "Brakeman Public Use License" from
  Synopsys — analysing your own software is not "commercial use", but distributing it or including it in a
  paid service does require a commercial licence. Verify the current text before putting it into a
  product (§8).
- **SCA and supply chain** — RubyGems has been the scene of real and recent attacks:
  - 2026-05: massive flood of accounts and malicious gems that forced RubyGems.org to **temporarily
    suspend registration of new accounts**; none had a CVE and maintainer reputation
    was useless (freshly created accounts).
  - 2026-04/05: campaign attributed to "BufferZoneCorp", gems impersonating well-known names
    (`activesupport-logger`, `devise-jwt`) targeting **CI runners** to steal credentials.
  - 2026-06: 14 gems used as a *dead drop* for data exfiltrated by a browser extension.
  - 2026-07: "SleeperGem" campaign (`git_credential_manager`, `Dendreo`) with a second-stage payload.
  - Operational consequences, not optional: **`bundler-audit` as a gate**; committed lockfile and
    `--frozen` in CI; human review of **every new gem** (exact name, maintainer, downloads,
    date of first release); `bundle config set --local disable_platform_warnings` does not replace
    reading the `Gemfile.lock` diff in the PR; **CI does not expose secrets to the installation of
    dependencies** (`bundle install` in a job without cloud credentials or a write `GITHUB_TOKEN`).
  - A `gemspec` can execute code during `bundle install` (native extensions, build hooks):
    assume that installing a gem is **executing third-party code** and isolate the job accordingly.
  - Consider a *cooldown* on new versions (delaying adoption of a freshly published release);
    several tools and mirrors already offer it — verify which applies to your registry (§8).
- **Publication**: Trusted Publishing (OIDC) from GitHub Actions with `id-token: write` and a protected
  environment; `rubygems_mfa_required` in the gemspec. RubyGems.org's mandatory MFA covers only the
  most downloaded gems: do not assume your gem is protected by registry policy.
- **Errors**: never a stack trace or internal path to the client; `config.consider_all_requests_local =
  false` in production, neutral error page with a correlation id.

## 6. Performance and operability

- **N+1 is a bug, not a pending optimisation**: `includes`/`preload`/`eager_load` as appropriate
  (`includes` decides on its own; `preload` forces two queries; `eager_load` forces the JOIN). Automatic
  detection in the test/development environment (`bullet` or Rails' `strict_loading`) and **test
  failure**, not a log nobody reads. `strict_loading` by default in new models.
- **Always** paginate collections (default and maximum limit). `find_each`/`in_batches` for
  massive traversals; ❌ `.all.each` over a production table.
- **Safe migrations** (`strong_migrations`): no adding a column with a non-volatile default on
  old engines, no indexes without `algorithm: :concurrently` on PostgreSQL, no `change_column` that
  rewrites the table, nor renaming/removing columns in the same release as the code that uses them.
  **Expand/contract** pattern mandatory: the migration must be compatible with version N-1 of the
  code throughout the rolling deploy. Destructive ones go in a later release.
- **Jobs**: `ActiveJob` as the interface, explicit backend. **Solid Queue** (Rails 8 default, uses
  `FOR UPDATE SKIP LOCKED`, does not require Redis) is the default option in greenfield; **Sidekiq 8**
  if it is already there, if you need its ecosystem, or for measured performance — with the
  **LGPL-3.0** licence warning for Sidekiq OSS. Common rules:
  - Serialisable and **small** arguments: pass IDs, not objects or payloads.
  - **Idempotency mandatory**: every job is retried; if retrying it charges twice, it is a bug.
  - Enqueue **after** the commit (`after_commit`), never inside the transaction: the worker may
    pick up the job before the row exists.
  - Explicit timeouts and retry limits; monitored failure queue (dead set).
  - Queues separated by latency (critical / default / slow), not by team.
  - Long jobs: Rails 8.1 brings **Active Job Continuations** (splitting into resumable steps) —
    relevant because a deploy with Kamal gives the jobs container a short shutdown window.
- **Cache**: Solid Cache (Rails 8 default, database-backed) or Redis/Valkey if it already exists.
  Key with schema version, explicit TTL, designed invalidation. Russian doll caching in views
  only if there is measurement behind it. ❌ cache without TTL "we will clean it by hand later".
- **Puma**: `WEB_CONCURRENCY` (processes) and threads sized against the Active Record pool —
  `pool` ≥ threads per process, or you will see checkout timeouts under load. The GVL means threads
  only help with I/O; real CPU parallelism is processes.
- **Timeouts on everything**: HTTP client (explicit `open_timeout` and `read_timeout` — many Ruby
  clients have no default), `statement_timeout` in PostgreSQL, `rack-timeout` or equivalent at the
  edge. Retries with backoff+jitter only on idempotent operations.
- **Observability**: structured logs with `request_id`; `ActiveSupport::Notifications` /
  Rails 8.1 Structured Event Reporting as the event source; OpenTelemetry for traces and metrics.
  Liveness/readiness endpoints (`rails/health` out of the box, extend it with a dependency check).
  ❌ personal data or secrets in logs.
- **Memory**: CRuby fragments; watch RSS per worker and restart workers with a limit if needed
  (`puma_worker_killer` is a patch, not a diagnosis). Profile with `stackprof`/`memory_profiler`
  before optimising; no speculative micro-optimisation.
- Orderly shutdown: SIGTERM drains in-flight requests and jobs; do not break it with `exit!` or orphan
  threads.

## 7. Long-term sustainability

- **Cadence**: security patches immediately; gem minors with Renovate/Dependabot and lock;
  Ruby one minor a year; Rails from supported release to supported release. A big upgrade is
  cheaper in small, frequent steps than as a six-month project every three years.
- Maintenance budget in every sprint. Rails deprecations (`ActiveSupport::Deprecation`)
  are resolved in the current release, they are not silenced.
- `.rubocop_todo.yml` with a date; conscious debt = TODO with reason and a linked issue.
- Rails 8.1 allows marking associations `deprecated: true` (`:warn`/`:raise`/`:notify`): use it to
  retire dead relations measurably instead of "grepping for usages".

**Prohibition list (veto):**
- ❌ Deploying on an EOL version of Ruby (≤3.2 as of 2026-08) or of Rails without support.
- ❌ `YAML.load` / `Marshal.load` / `JSON.load` over untrusted input. **FORBIDDEN** without exception.
- ❌ `eval`/`instance_eval`/`class_eval`/`send`/`public_send`/`constantize` with user data.
- ❌ `system`/backticks/`Kernel#open` with interpolation of input.
- ❌ SQL by string interpolation in `where`, `order`, `pluck`, `joins`, `find_by_sql`.
- ❌ `permit!`, or permitting role/ownership fields in strong parameters.
- ❌ Global `skip_before_action :verify_authenticity_token`; `protect_from_forgery with: :null_session`
  on routes with a session.
- ❌ `html_safe`/`raw` over user content.
- ❌ `default_scope`. ❌ Active Record callbacks with external effects (mail, HTTP, jobs).
- ❌ `update_column`/`update_all`/`save(validate: false)` to skip validations without a written reason.
- ❌ `rescue => e` that swallows the exception without logging or re-raising; `rescue Exception`.
- ❌ Monkey patching gems or the core in the app (use refinements or a fork with an upstream issue).
- ❌ Gems without a version in the `Gemfile`; deploying without `Gemfile.lock`; `bundle update` without reviewing the diff.
- ❌ Installing dependencies in a CI job that has production credentials at hand.
- ❌ Tests with logic, with `sleep`, order-dependent or that call the public network.
- ❌ ZJIT in production (experimental as of 2026-08, slower than YJIT according to the official notes).
- ❌ Destructive migration in the same release as the code that stops using the column.
- ❌ Enqueuing jobs inside the transaction that creates the data the job needs.
- ❌ Extracting an internal gem with a single consumer.
- ❌ Assuming that Brakeman or Sidekiq are MIT: verify their licence before putting them into a product.

## 8. Mandatory web verification

Before pinning versions or claims in a project, **verify online**:
1. **Ruby**: latest stable and EOL calendar (`endoflife.date/ruby`, ruby-lang.org/en/downloads).
   Is 4.0 still the current series? Has 4.1 shipped? Is 3.3 already EOL (planned 2027-03-31)?
2. **Rails**: supported version (`endoflife.date/rails`, rubyonrails.org). 7.2 EOL 2026-08-09 and
   8.0 EOL 2026-11-07 → check whether they have passed. Rails 9?
3. **JIT**: does ZJIT already match or beat YJIT and is it recommended in production? Is YJIT enabled by
   default in some version? Source: official release notes from ruby-lang.org, not blogs.
4. **Typing**: state of RBS/Steep and of Sorbet — has either become the ecosystem default or has
   typing entered the Ruby compiler? As of 2026-08 neither is mandatory.
5. **Tools**: RuboCop (2.0?), RSpec (4.0 final already, or still in beta?), Minitest, Brakeman,
   bundler-audit, strong_migrations, Solid Queue, Sidekiq. Pin the exact RuboCop version.
6. **Licences**: Brakeman (Synopsys, not OSS), Sidekiq (LGPL-3.0), bundler-audit (GPL-3.0-or-later),
   and any tool you are going to set as a default. Recent precedents of licence
   changes that broke pipelines: **Trivy** and **gitleaks** (its action requires a commercial licence
   for organisations from v2). Check the raw `LICENSE` file, not the README badge.
7. **Security**: advisories from ruby-lang.org and GitHub Advisories / osv.dev for Ruby, Rails and the gems
   in the `Gemfile.lock` before pinning versions. Verify specifically the CVEs cited here
   (CVE-2026-41316 in ERB, CVE-2026-46727 in getaddrinfo) and whether there are later ones.
8. **RubyGems**: state of the registry after the 2026 incidents (new MFA policies, version cooldown,
   gem signing?), and whether RubyGems.org still has operational restrictions.

**Declared gaps (not verified as of Aug 2026)**:
- Whether YJIT becomes enabled by default in some Ruby 4.x version: **not verified**.
- Exact coverage of RubyGems.org's mandatory MFA policy in 2026 (the download-based threshold
  appears to still be in force, but no updated official announcement was located): **not verified**.
- General availability of Sigstore-style gem signing on RubyGems.org: **not verified**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
