---
name: php-standards
description: PHP engineering standards (modern PHP, Laravel, Symfony). Use when working with .php files, composer.json/composer.lock, artisan commands, phpunit.xml, phpstan.neon, psalm.xml, Blade/Twig templates, or any Laravel/Symfony project task (code, review, refactor, tests, CI).
---

# PHP standards (modern, Laravel, Symfony)

## 1. Scope and triggers

Applies to all work on PHP code: `.php` files, `composer.json`/`composer.lock`,
`artisan`/`bin/console` commands, Blade/Twig templates, PHPStan/Psalm/PHPUnit/Pest configuration,
CI pipelines of PHP projects. Covers writing, reviewing, refactoring and testing.

**Not applicable**: see `api-design-standards` (HTTP/GraphQL contract design — here only its
implementation in Laravel/Symfony), `appsec-standards` (threat modelling and stack-agnostic
vulnerability classes; here only PHP's concrete sinks and flags),
`microservices-architecture-standards` (service boundaries, events, distributed queues, sagas),
`data-platform-standards` (modelling, indexes and engine tuning; here only Eloquent/Doctrine and their
migrations), `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards` (OCI
image, PHP-FPM in a container and deployment), `onprem-standards` (the web server/PHP-FPM on the host and its
hardening), `observability-standards` (OTel pipeline; here only the instrumentation),
`git-workflow-standards` (branch, commits and SemVer tagging; publishing to Packagist *is* this
skill's), `identity-access-management-standards` (IdP design; here only how the app consumes it),
`sql-standards` (the SQL that Doctrine or Eloquent generate, and the SQL written by hand).
**Language choice** (the skill for the chosen language wins): `python-standards`,
`typescript-standards`, `go-standards`, `jvm-spring-standards`, `dotnet-standards`,
`ruby-standards` (**the most direct comparison**: Laravel and Rails occupy the same slot; the
choice is one of team and ecosystem, not of performance), `elixir-erlang-standards`.

**Rule zero**: detect the project context first (`composer.json` → PHP version, framework,
tools already present) and respect its conventions. These standards set the criteria for
new code and for flagging debt; do not rewrite what exists outside the requested scope.

## 2. Default toolchain

> **Verification note**: versions checked via the web on 2026-08-02 (php.net, laravel.com,
> symfony.com/releases, phpstan.org, pestphp.com). Before pinning a version in a project,
> **verify the current state on the web** — this document expires.

- **PHP**: new projects on **PHP 8.5** (current, EOL 2029-12-31) or **8.4** (active, EOL 2028-12-31).
  8.3 and 8.2 are in *security-only* (EOL 2027-12-31 and 2026-12-31); maintenance only, not new projects.
  ≤8.1 is EOL: treat it as a security incident, not as a preference.
- **Laravel**: **Laravel 13** (March 2026, requires PHP ≥8.3). There are no LTS releases: each major
  gets 18 months of bugfixes and 2 years of security — plan the annual upgrade.
- **Symfony**: **7.4 LTS** (supported until Nov 2029) for long-lived products;
  **8.x** (currently 8.1, requires PHP ≥8.4) if you take on the six-monthly upgrade cadence.
- **Composer**: 2.x always. `composer.lock` versioned in applications; in libraries it is not versioned
  but is tested against `--prefer-lowest` and latest in CI.
- **Testing**: **Pest 5** (on top of PHPUnit 13) by default in new projects; plain **PHPUnit** is
  just as valid if the project already uses it. Do not mix styles in the same suite.
- **Static analysis**: **PHPStan 2.x** with `level: max` (today level 10) + `phpstan-strict-rules`
  (+ Larastan on Laravel, phpstan-symfony on Symfony). Psalm (`errorLevel="1"`) as an alternative
  if the project already uses it; one of the two is mandatory, not optional.
- **Style**: PSR-12 (and PER Coding Style) with **PHP-CS-Fixer** or **Laravel Pint** (Laravel projects).
- **Auxiliaries**: Rector for automated upgrades; `composer audit` for SCA.

## 3. Structure and conventions

- **`declare(strict_types=1);`** mandatory in EVERY new PHP file, as the first statement. In legacy
  code without it, flag it; enable it only with test coverage that backs the change.
- **Explicit types everywhere**: parameters, returns (incl. `void`/`never`), typed properties.
  No `mixed` except at a real boundary (deserialisation, reflection) and always narrowed immediately.
- **Immutability by default**: `readonly` on properties and DTO/VO classes, `final` by default on
  classes not designed for inheritance, enums (`enum`) instead of loose class constants,
  promoted constructor properties.
- PSR-4 for autoloading (`src/` → `App\` or the vendor namespace); one type per file; revealing
  names (`StudlyCaps` classes, `camelCase` methods, `SCREAMING_SNAKE` constants).
- **Laravel**: framework conventions first — Form Requests for validation, Eloquent with
  typed casts/relations, queues for deferred work, `config()` only from config files
  (never `env()` outside `config/`), policies for authorisation. Domain logic outside
  controllers (actions/services); thin controllers.
- **Symfony**: constructor injection with autowiring, private services by default, PHP
  attributes (`#[Route]`, `#[AsMessageHandler]`) over YAML for what is local to the code, Messenger for
  asynchrony, `symfony/validator` at the edges.
- Errors: domain-specific exceptions, never `@` nor an empty catch; `try/finally` or
  equivalents to release resources. No half-done states.

## 4. Quality: formatting, lint, static analysis, testing

Gates in CI, all blocking — nothing is merged with any of them red:

1. **Formatting**: Pint (`pint --test`) or PHP-CS-Fixer (`--dry-run --diff`) against PSR-12/PER.
2. **Static**: `phpstan analyse --level=max` (or `psalm --show-info=false` at level 1) with no errors.
   - The baseline (`phpstan-baseline.neon`) only for adoption in legacy: it is frozen and **only shrinks**;
     adding new entries to the baseline is forbidden.
   - A one-off `@phpstan-ignore` requires a comment with the reason; without a reason, it is an error to fix.
3. **Tests**: `pest` / `phpunit` complete, deterministic, in parallel once the suite grows
   (`pest --parallel`, `paratest`).
4. **SCA**: `composer audit` with no known vulnerabilities left untriaged.
5. **Coherent lock**: `composer validate --strict` and `composer install --dry-run` clean.

Testing criteria:
- Observable behaviour, not implementation. Cover the happy path, **edges and errors** (invalid
  inputs, limits, dependency failures) — a suite with no error tests is incomplete.
- Pyramid: fast unit tests as the majority; integration (HTTP kernel, DB with transaction and
  rollback or RefreshDatabase) just enough; E2E minimal.
- Mock boundaries (HTTP, queues, clock, filesystem), not your own classes. In Laravel use the framework's
  fakes (`Queue::fake()`, `Http::fake()`, `Event::fake()`); in Symfony, `clock-mock`/test
  services. Never a real network in tests.
- Every bugfix lands with a regression test that first reproduces the failure.
- Arch tests (Pest `arch()`) for structural invariants: no `dd()`/`dump()`/`var_dump` in
  production, dependencies between layers, `strict_types` present.
- Mutation testing (Infection) recommended in libraries and critical domains; coverage as a signal
  (critical lines covered), never as a numeric target.

## 5. Stack security

- **OWASP Top 10 as an active checklist**: queries ALWAYS parameterised (Eloquent/Doctrine/PDO
  prepared) — concatenating input into SQL is forbidden, even in `whereRaw`/DQL: use bindings.
  Context-aware escaping: Blade `{{ }}` / Twig autoescape; `{!! !!}`/`|raw` only with sanitised
  content and justified in writing.
- **Deserialisation**: never `unserialize()` on external input (use `json_decode` with validation
  or `allowed_classes: false` if there is no alternative). Watch out for SSRF in HTTP clients that receive
  user-supplied URLs: validate scheme/host against an allowlist.
- **Authentication/authorisation**: framework primitives (Laravel `Auth`/policies/Sanctum;
  Symfony Security/voters), never home-made. `password_hash()` with Argon2id/bcrypt; comparisons
  with `hash_equals()`. Authorise every action server-side, do not just hide UI.
- **Mass assignment**: strict `$fillable` (not `$guarded = []`) in Eloquent; DTOs/Form Requests
  as the input boundary. ALWAYS validate at the edge (Form Request / Validator / Symfony
  Validator), not ad hoc in the controller.
- **Secrets**: only in environment variables / a secrets manager; `.env` outside VCS; nothing in
  logs or exceptions. `APP_DEBUG=false` in production (Laravel exposes secrets with debug on).
- **Headers and session**: `Secure`, `HttpOnly`, `SameSite` cookies; CSRF enabled on forms;
  HSTS; rate limiting on authentication endpoints.
- **Continuous SCA**: `composer audit` in CI + Dependabot/Renovate; abandoned dependencies are
  replaced, not ignored. No extensions/packages with open CVEs without documented mitigation.
- Crypto: `random_bytes`/`random_int`, sodium or OpenSSL AES-GCM. MD5/SHA-1 for
  security, `mt_rand`/`rand` for tokens and home-made encryption are forbidden.

## 6. Performance and operability

- **OPcache** always enabled in production; `composer install --no-dev --optimize-autoloader`
  (+ `--classmap-authoritative` on an immutable deploy). Preloading only with measurement to back it.
- **N+1 is a bug**: eager loading (`with()`, joins, `Model::preventLazyLoading()` in non-production;
  Doctrine `fetch join`). Pagination mandatory in listings; never `all()` without a limit.
- Heavy work onto **queues/Messenger** with retries + backoff and monitored `failed_jobs`/failure
  transport; idempotent *jobs* (redelivery happens). Cache with explicit invalidation
  (tags/TTL), not "just in case".
- **PHP-FPM/worker mode**: size `pm.max_children` with data; if you use Octane/FrankenPHP/
  RoadRunner, check for state leaks between requests (statics, container).
- Observability: structured logs (Monolog JSON) with context and without sensitive data; metrics and
  traces (OpenTelemetry) in services; health checks (`/up`, liveness/readiness) for the orchestrator.
- Backward-compatible DB migrations (*expand/contract*); never a destructive migration in the
  same deploy as the code that stops using the column.

## 7. Sustainability: cadence and prohibitions

**Upgrade cadence**:
- PHP: move up a minor version within <6 months of release; abandon a line BEFORE it enters
  *security-only*. Cite the EOL in the plan (endoflife.date/php).
- Laravel: annual major — budget the upgrade every year (Shift/Rector help); do not fall more
  than one major behind the current one. Symfony: jump from LTS to LTS (7.4 → 8.4) or follow the six-monthly cadence,
  an explicit project decision.
- Dependencies: Renovate/Dependabot weekly; security patches in <72 h.

**LIST OF PROHIBITIONS** (they block review):
- A new file without `declare(strict_types=1)`.
- `eval()`, `extract()`, `$$variables` variable variables, `@` (error suppression), `goto`.
- `exec`/`shell_exec`/`system`/`proc_open` with unsanitised input; backticks.
- SQL/commands concatenating input; `unserialize()` of external data.
- `env()` outside `config/` (Laravel); hardcoded secrets; `APP_DEBUG=true` in production.
- `mixed` without justification; `array` without a shape/generic docblock in public APIs.
- Suppressing PHPStan/Psalm errors without a comment giving the reason; growing the baseline.
- `dd()`/`dump()`/`var_dump()`/`print_r()` in production code.
- Tests that depend on a real network, the system clock without a fake, or execution order.
- New dependencies without justification (does the framework or the stdlib solve it?); abandoned packages.
- Inheritance as code reuse (use composition); *service location* (`app()->make` in the
  domain) instead of constructor injection.
- Commits that mix mass reformatting with functional changes.

## 8. Mandatory web verification

Before pinning ANY version, flag or API in a real project, **search for it on the web** — do not
take it as good from this file or from memory:
- Supported PHP versions and EOL dates: php.net/supported-versions, endoflife.date/php.
- Version and support policy of Laravel (laravel.com/docs/releases) and Symfony
  (symfony.com/releases — confirm which is the current LTS).
- Compatibility of PHPStan/Psalm/Pest/PHPUnit with the project's PHP version (Packagist).
- Dependency CVEs: `composer audit` + GitHub Advisories before recommending a package.

If the web's data contradicts this document, **the web wins** — mention the discrepancy.
