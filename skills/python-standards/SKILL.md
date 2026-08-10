---
name: python-standards
description: Use when writing, reviewing, or designing Python code or projects - .py files, pyproject.toml, uv, ruff, FastAPI, Django, SQLAlchemy, pydantic, asyncio, pytest, alembic, uvicorn, celery, Python packaging, virtualenvs, type hints, or Python CI/CD pipelines.
---

# Python standards (reference: August 2026)

## 1. Scope and triggers

Applies to all Python work: new code, review, design, refactor, packaging, CI and deployment.
Triggers: `.py`, `pyproject.toml`, `uv.lock`, FastAPI, Django, SQLAlchemy, pydantic, asyncio, pytest, alembic.
This document sets **criteria** (what to use, what is vetoed, what to verify), not tutorials.

**Not applicable**: see `api-design-standards` (HTTP/GraphQL/gRPC contract design: resources, status codes,
pagination, RFC 9457, versioning — here only its implementation in FastAPI/Django),
`microservices-architecture-standards` (service boundaries, events, sagas, distributed resilience),
`appsec-standards` (threat modelling and stack-agnostic vulnerability classes; here only
Python's concrete sinks and flags), `data-platform-standards` (modelling, indexes, tuning and
PostgreSQL replicas; here only the use of SQLAlchemy/Alembic), `cicd-standards` (the pipeline that
runs the §4 gates), `kubernetes-standards` (OCI image and service deployment),
`observability-standards` (OTel/Prometheus pipeline; here only the instrumentation in the code),
`git-workflow-standards` (branch, commits and SemVer tagging of the repo; publishing to PyPI *is*
this skill's), `bash-linux-scripting-standards` (system scripts: if the script goes past ~50 lines or
needs data structures, it gets rewritten in Python and comes back here), `c-standards`/`cpp-standards`
and `rust-standards` (**native extensions**: the packaging, the wheels and the Python API boundary
—`cffi`, `pybind11`, `PyO3`, the GIL and its release— are ours; the **native code on the other
side** —memory, UB, sanitizers, compiler flags— is theirs), `sql-standards` (the SQL that
SQLAlchemy generates or that you write by hand in `text()`). **Language choice** (the skill that wins
is the one for the chosen language, not this one): `go-standards`, `rust-standards`, `typescript-standards`,
`jvm-spring-standards`, `dotnet-standards`, `php-standards`, `ruby-standards`,
`elixir-erlang-standards`, `scala-standards`, `clojure-standards`, `haskell-fp-standards`,
`ocaml-fsharp-standards`, `perl-standards` (**reciprocal destination**: Python is the natural target of
a Perl rewrite, but **rewriting a Perl that works and has no tests is trading a known risk for an
unknown one** — the decision to rewrite is theirs, the quality of the resulting Python is
ours), `r-standards`, `julia-standards` — these last two for statistical
analysis and intensive numerical computing, where Python is **not** automatically the answer.

## 2. Default toolchain

> **Note**: the versions cited are the state verified as of 2026-08. **Before pinning versions in a
> real project, verify the latest stable on the web** (section 8). Never pin versions from memory.

| Piece | Choice | Minimum | Why |
|---|---|---|---|
| Runtime | CPython | **3.12**; prefer 3.13/3.14 on greenfield | 3.14 stable since 2025-10; Django 6 requires ≥3.12 |
| Package/env manager | **uv** (Astral) | 0.12+ | De facto standard: replaces pip, pip-tools, virtualenv, pyenv and pipx |
| Formatter | **ruff format** | 0.16+ | Replaces black; a single binary with the linter |
| Linter | **ruff check** | 0.16+ | 400+ rules by default since 0.16; exact pin in dev-deps |
| Type checker (CI gate) | **pyright** in `strict` mode | — | Leader in spec conformance (~98%). `ty` (Astral) is still in beta (~53% conformance): useful as an LSP/editor tool, **not as a CI gate** yet. mypy only if the repo already uses it |
| Testing | **pytest** + pytest-asyncio + coverage | — | — |
| Async API | **FastAPI** | 0.136+ | Most used Python framework (JetBrains 2025) |
| "Batteries included" web | **Django** | **5.2 LTS** (supported until 2028-04) or 6.0 if you take on the annual cadence | 4.2 LTS died in 2026-04 |
| Validation/serialisation | **pydantic v2** | 2.11+ | v3 NOT released as of 2026-08; do not assume a v3 API |
| SQL ORM (non-Django) | **SQLAlchemy 2.0** in 2.0 style (`Mapped[]`, `mapped_column`) | 2.0.50+ | 2.1 still in beta; migrate when it is final |
| Migrations | alembic (SQLAlchemy) / native migrations (Django) | — | — |
| ASGI server | uvicorn (workers via systemd/k8s, not an improvised `--workers`) | — | — |
| Settings | pydantic-settings from env vars | — | Config outside the artifact, 12-factor |

Canonical commands: `uv init` / `uv add` / `uv sync --locked` / `uv run` / `uvx`. Never `pip install` by hand inside a uv project.
The project's Python version pinned in `.python-version` and managed with `uv python install` — do not depend on the system Python.

**Concurrency model criteria** (pick one, do not mix them without a clear boundary):
- I/O-bound with many connections → asyncio (FastAPI, asyncpg, httpx).
- Simple I/O-bound or synchronous libs → threads (`ThreadPoolExecutor`) or synchronous workers; do not force async.
- CPU-bound → processes (`ProcessPoolExecutor`) or task queue; free-threading (3.14, PEP 779) is still an
  experimental opt-in for prod: verify ecosystem support before using it.
- Django: synchronous by default is still valid; async only where there is measured benefit.

**pydantic vs dataclasses criteria**: pydantic at the edges (parsing/validation of external data);
`dataclasses`/`attrs` (frozen by default) for already-validated internal domain types — do not pay for
validation where there is no untrusted input.

## 3. Structure and conventions

- **`src/` layout** mandatory in packages: `src/<package>/`, `tests/` outside the package.
- A single `pyproject.toml` as the source of truth: metadata, deps, `[dependency-groups]` (dev, test),
  ruff/pyright/pytest/coverage config inside. Zero `setup.py`, `setup.cfg`, `requirements.txt` (except a one-off export for legacy platforms: `uv export`).
- `uv.lock` **always committed** (apps and libraries too, for their CI).
- Explicit `requires-python = ">=3.12"`; coherent classifiers.
- Names: short `snake_case` modules; no catch-all `utils.py` — modules by domain.
- FastAPI: routers by domain (`app/<domain>/router.py`, `schemas.py`, `service.py`, `models.py`),
  dependencies with `Depends` for the DB session/auth/config; lifespan with `asynccontextmanager` (not `@app.on_event`, deprecated).
- Django: small, cohesive apps; logic in services/managers, not in views or signals; settings split by environment with env vars (django-environ or pydantic-settings), `DEBUG=False` by default.
- Separate API schemas (pydantic) from persistence models (SQLAlchemy/Django): never expose the ORM model directly in the API.
- **HTTP API design**: versioning in the path (`/v1`), errors in RFC 9457 format (problem+json) or a bespoke one
  consistent across the whole API, mandatory pagination on collections (cursor for large datasets),
  explicit `response_model` on every FastAPI endpoint (never return dicts without a schema).
- **Publishable libraries**: `uv build` + publishing from CI with OIDC/attestations (PyPI Trusted Publishers),
  never with a static token locally; explicit `__all__`, `py.typed` included, SemVer and changelog.
- Transactions: one session/transaction per request (dependency in FastAPI, `ATOMIC_REQUESTS` or
  `transaction.atomic` in Django); commit/rollback in a single place, not scattered across the services.

## 4. Quality: formatting, lint, types, tests

- **Formatting**: `ruff format`, no style debate; line length 100 or 120, pick one and pin it.
- **Lint**: `ruff check` with 0.16+ defaults plus `I` (isort), `B` (bugbear), `UP` (pyupgrade), `S` (bandit),
  `PTH` (pathlib), `RUF`. `noqa` always with a concrete code and a reason.
- **Types**: `pyright` in `strict` for new code; in legacy, `basic` + strict per directory as you advance.
  Annotate the whole public API. `Any` is a failure except at a justified boundary; use `TypedDict`, `Protocol`, PEP 695 generics, `Self`.
- **Tests** (pytest):
  - AAA, one failure reason per test; names that describe behaviour.
  - Cover the happy path, **edges and errors** (invalid inputs, timeouts, concurrency conflicts, permissions).
  - FastAPI: `httpx.AsyncClient` + `ASGITransport` against the real app; dependency overrides, not framework mocks.
  - DB: integration tests against a real Postgres (testcontainers or a CI service), not SQLite "because it is faster" if prod is Postgres.
  - Async: `pytest-asyncio` in `auto` mode; `time.sleep`/polling forbidden in tests — use events or the `anyio` fake clock.
  - Every bugfix leaves a regression test. Flaky = fixed or deleted.
- **CI gates** (all block the merge, in this order — cheapest first):
  1. `uv sync --locked` (fails if the lock is out of date)
  2. `ruff format --check` and `ruff check`
  3. `pyright` (strict on new code)
  4. `pytest --cov` unit (fast) → integration (real DB/services)
  5. `pip-audit` / SCA + package or image build
  Coverage threshold agreed by the team — coverage is a signal, not a target. Main always green.
- Exact pin of ruff and pyright in dev-deps: their updates change defaults and break CI if they float (ruff 0.16 proved it).
- Pre-commit optional but recommended (ruff format+check); CI is the authority, not the local hook.
- Same command locally and in CI (`uv run pytest`, `uv run ruff check`): if CI does something you cannot
  reproduce locally, that is a pipeline bug.

## 5. Stack security

- **Inputs**: validate EVERYTHING at the edge with pydantic (strict types, `Field` with limits, `max_length` on strings, payload size limits). In Django, forms/serializers always; never raw `request.GET[...]` into logic.
- **SQL**: parameterised queries only (ORM or `text()` with bind params). Concatenating input into SQL/`os.system`/`subprocess(shell=True)` = absolute veto.
- **Secrets**: env vars or a manager (Vault/KMS); never in code, `pyproject`, logs or fixtures. Django's `SECRET_KEY` rotatable and per environment.
- **AuthN/Z**: standard OAuth2/OIDC; passwords with Argon2 (`argon2-cffi` / Django's Argon2 hasher). JWT: fixed algorithm (RS256/EdDSA), short expiry, `aud`/`iss` verification.
- **Deserialisation**: `pickle`/`eval`/`exec`/`yaml.load` without `SafeLoader` forbidden on external data.
- **SSRF**: when fetching user-supplied URLs, allowlist schemes/hosts and block private ranges.
- **SCA**: `pip-audit` (or `uv`-compatible) + image scanning in CI as a gate; dependencies pinned in the lock, updated on a cadence (section 7). Flag abandoned deps.
- **Django hardening**: `SECURE_*` settings, CSP (native in 6.0+ or django-csp), strict `ALLOWED_HOSTS`, CSRF enabled.
- **FastAPI hardening**: CORS with an explicit allowlist (never `*` with credentials), docs (`/docs`, `/openapi.json`) disabled or authenticated in prod if the API is internal, rate limiting at the edge.
- **Errors**: never leak stack traces or internal paths to the client; a global handler that logs with context and returns a neutral error with a correlation id.
- Containers: slim/distroless image, non-root, multi-stage with `uv sync --locked --no-dev`.

## 6. Performance and operability

- **Async with discipline**: no blocking I/O on the event loop — async drivers (asyncpg, `httpx.AsyncClient`)
  or `run_in_threadpool`/`asyncio.to_thread` for synchronous work. In FastAPI, an `async def` endpoint with a blocking call inside is a bug, not a detail.
- **Timeouts everywhere**: httpx with an explicit `timeout` always (the infinite default of many libs is an incident waiting to happen); DB pool with `pool_size`, `max_overflow`, `pool_timeout`, `pool_pre_ping`.
- Retries with backoff+jitter (tenacity) only on idempotent operations; circuit breaker on fragile dependencies.
- **Graceful shutdown**: a lifespan that closes pools and drains tasks; the process honours SIGTERM (uvicorn does; do not break it with `os._exit`, non-daemon threads or orphan tasks — keep references to your `asyncio.create_task`).
- **Observability**: structured JSON logging (structlog) with a correlation id; OpenTelemetry (traces+metrics) instrumenting ASGI, DB and the HTTP client; `/healthz` (liveness) and `/readyz` (readiness with dependency checks) endpoints. No telemetry, no production.
- ORM: N+1 forbidden — `selectinload`/`joinedload` (SQLAlchemy), `select_related`/`prefetch_related` (Django); always paginate listings (default and maximum limit).
- Heavy work outside the request: task queue (celery/arq/taskiq, or Django 6 native Tasks) — not FastAPI's `BackgroundTasks` for anything critical or long-running.
- Profile before optimising (`py-spy`, `cProfile`); no speculative micro-optimisation.
- Cache with criteria: explicit TTL and a key carrying the schema version; invalidation designed, not "we'll flush it by hand".
- Backward-compatible migrations (*expand/contract*): never a migration that breaks version N-1
  of the code during a rolling deploy; destructive migrations in a later release.
- Logs: INFO level in prod, DEBUG enableable by env; never personal data/secrets in logs (review the
  `repr` of models with sensitive fields — use pydantic's `SecretStr`).

## 7. Long-term sustainability

- **Cadence**: security patches immediately; dependency minors monthly/fortnightly (Renovate/Dependabot with lock);
  CPython within a year of its release (once the ecosystem catches up); Django from LTS to LTS unless features demand otherwise.
- Maintenance budget in every sprint; a dependency with no release in >18 months gets reviewed or replaced.
- Your own deprecations: warning + changelog + removal window; third-party `DeprecationWarning`s are treated as debt with an issue, not silenced.
- Conscious debt: shortcut = TODO with a reason and a linked issue; silent accidental complexity forbidden.

**List of prohibitions (veto):**
- `pip install` / `requirements.txt` as the source of truth in a new project (uv + `pyproject` + lock).
- Publishing/deploying without a lockfile or with unpinned deps.
- `except Exception: pass` or catches that swallow errors without logging or re-raising.
- Mutables as argument defaults; mutable global state as "config".
- Unsafe `pickle`/`eval`/`exec`/`yaml.load` on external data; `subprocess(shell=True)` with input.
- SQL by concatenation/f-string. MD5/SHA-1 for passwords; home-made crypto.
- Blocking I/O in async code; legacy `asyncio.get_event_loop()` (use `asyncio.run`/the running loop).
- Exposing ORM models directly as the API schema.
- `# type: ignore` / `noqa` without a rule code and without a reason.
- Tests that depend on order, the public network or `sleep`; mocks of the very code under test.
- pydantic v1 models (`class Config`, `.dict()`, `.parse_obj`) in new code — v2 API (`model_config`, `model_dump`, `model_validate`).
- SQLAlchemy 1.x style (`Query`, legacy `declarative_base`) in new code.
- `@app.on_event("startup")` in FastAPI (use lifespan). Business logic in Django signals.
- EOL versions: CPython <3.12 (new), Django <5.2, Node… (see the TS skill). No "we'll upgrade it later".

## 8. Mandatory web verification

Before pinning versions or APIs in a project, **verify online** (WebSearch/WebFetch):
1. Latest stable and EOL calendar for: CPython (python.org/endoflife.date), Django (djangoproject.com — did 6.1 ship? a new LTS?), FastAPI, pydantic (**has v3 shipped yet?** As of 2026-08 no), SQLAlchemy (**is 2.1 final yet?** As of 2026-08 in beta), uv and ruff (astral-sh releases — ruff 0.16 changed the defaults and breaks CI without a pin).
2. Status of `ty` (Astral): if its conformance now makes it fit as a CI gate, re-evaluate pyright.
3. Recent CVEs in the chosen stack (GitHub Advisories / osv.dev) before pinning a concrete version.
4. Breaking changes from the official changelog before any major upgrade — not from memory, nor from third-party blogs without checking against the official source.

If the web contradicts this document, **the web wins** — flag the discrepancy.
