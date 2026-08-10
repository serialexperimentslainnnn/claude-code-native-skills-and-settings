---
name: elixir-erlang-standards
description: Use when writing, reviewing or operating Elixir and Erlang/OTP systems on the BEAM - .ex/.exs/.erl/.hrl/.heex files, mix.exs, mix.lock, .formatter.exs, .credo.exs, rebar.config, GenServer/Supervisor/Task/Agent/Registry modules, ETS and :persistent_term, GenStage/Broadway/Flow pipelines, Ecto schemas migrations and Ecto.Multi, Phoenix contexts controllers channels and LiveView, Plug pipelines, ExUnit tests with Mox or StreamData, mix release and vm.args, distributed Erlang cookies epmd and TLS distribution, Dialyzer/Dialyxir, sobelow, or :telemetry and recon instrumentation.
---

# Elixir / Erlang standards (BEAM and OTP)

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to every system on the **BEAM**: Elixir, Erlang, OTP, Phoenix, Ecto, releases and their operation.
Triggers: `.ex`, `.exs`, `.erl`, `.hrl`, `.heex`, `mix.exs`, `mix.lock`, `.formatter.exs`, `.credo.exs`,
`rebar.config`, `vm.args`, `GenServer`, `Supervisor`, `Registry`, `:ets`, `Ecto`, `Phoenix`, `LiveView`,
`Plug`, `ExUnit`, `Mox`, `mix release`, `epmd`, `libcluster`.

The axis of this skill is the **BEAM execution model** (isolated processes, supervision,
distribution), not "yet another functional language". Almost every design decision here is justified by OTP.

**Not applicable**: see `api-design-standards` (the API **contract** — resources, codes, pagination,
RFC 9457, versioning — is theirs; here only its implementation in Plug/Phoenix/Absinthe),
`microservices-architecture-standards` (where a service is cut and how they talk to each other; on the BEAM
the answer is usually "don't cut it yet", but the decision is theirs),
`kubernetes-standards` and `container-runtime-security-standards` (OCI packaging of the release and container
runtime), `cicd-standards` (the pipeline and its gates; here only which tool and with what
configuration), `secrets-management-standards` (owner of the secrets-manager choice and of the
secret scanner; here only how they reach the release and that `RELEASE_COOKIE` must not live in the image),
`appsec-standards` and `vulnerability-management-standards` (threat modelling, process and triage;
here the code criteria and which gate breaks the build), `sql-standards` (the SQL language itself),
`data-platform-standards`, `mysql-mariadb-dba-standards`, `oracle-dba-standards` and
`sqlserver-dba-standards` (engine operation: tuning, replicas, backup, HA). Ecto decides **how the
application accesses** the database, not how the database is operated.
`observability-standards` (telemetry strategy and pipeline, SLIs and dashboards; `:telemetry` and its
instrumentation in the code belong to this skill), `sre-practice-standards` (SLOs, error budget and
operational reliability; here the supervision and back-pressure design that makes them possible),
`message-brokers-standards` (Kafka/RabbitMQ/NATS as infrastructure — **do not confuse with
`Phoenix.PubSub` or with message passing between BEAM processes**: PubSub is *in-cluster*, with no
persistence and no delivery guarantee, and it does not replace a broker; Broadway is the consumer of a
broker, not the broker).
Other languages: `ruby-standards`, `python-standards`, `go-standards`, `typescript-standards`,
`rust-standards`, `jvm-spring-standards`, `php-standards`, `haskell-fp-standards`, `scala-standards`,
`clojure-standards`, `ocaml-fsharp-standards`. Against **`ruby-standards`** in particular:
they share syntactic origin and much of the community, but **not** the execution model — the
boundary is the BEAM. A Rails pattern translated into Elixir without rethinking processes and supervision is a
design error, not a migration.
`iac-standards` (cluster provisioning) and `bash-linux-scripting-standards` (system scripts
around the release).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Component | Choice | Minimum | Why |
|---|---|---|---|
| Elixir | **1.20.x** | 1.18 | 1.20 shipped 2026-06-03: first milestone of the type system complete |
| Erlang/OTP | **28** (or 29 if the ecosystem keeps up) | 27 | OTP 29 shipped 2026-05-11 (EOL 2029-05-11); OTP 26 EOL 2026-05-26 |
| Compatibility | Elixir 1.20 → **OTP 27-29**; 1.19 → 26-28; 1.18 → 25-27 | — | Official compatibility table; **pin both versions**, not just Elixir |
| Version manager | **mise** or `asdf` with the erlang and elixir plugins | — | Both versions in `.tool-versions`/`mise.toml`, never the system ones |
| Dependencies | `mix` + **`mix.lock` committed** | — | `mix deps.get --check-locked` in CI |
| Web framework | **Phoenix 1.8.x** | 1.7 | 1.8 brings *scopes*, `phx.gen.auth` with magic link, simplified layouts; requires OTP 25+ |
| LiveView | **1.2.x** | 1.0 | 1.2 adds Colocated CSS (`@scope`) and test warnings for forms without an `id` |
| HTTP server | **Bandit** | 1.12+ | Default in modern Phoenix; Cowboy only if a dependency demands it |
| Data access | **Ecto 3.14** + `ecto_sql` | — | Apache-2.0 |
| Formatter | `mix format` (built-in) | — | Zero style debate; `--check-formatted` in CI |
| Linter | **Credo 1.7.19** | — | MIT, active (release Jun 2026) |
| Static analysis | **Dialyxir 1.4.7** on top of Dialyzer | — | Apache-2.0. See the real cost below |
| Tests | **ExUnit** (built-in) + **Mox 1.2** + **StreamData 1.4** | — | — |
| SAST | **Sobelow 0.14.1** | — | Apache-2.0. Slow cadence (last release Oct 2025): check activity (§8) |
| SCA | **`mix deps.audit`** (`mix_audit` 2.1.5) + `mix hex.audit` | — | `mix_audit` cross-checks the advisory DB; `hex.audit` detects *retired* packages |
| Back-pressure | **Broadway 1.3** (external sources) / **GenStage 1.3** (your own pipelines) | — | Flow 1.2.4 with no releases since 2023: use it only if it fits exactly |
| Releases | **`mix release`** (built-in) | — | No Distillery, no hand-rolled packaging |
| Telemetry | **`:telemetry` 1.4** + `telemetry_metrics` + OTel/Prometheus exporter | — | — |

**Version policy**: Elixir applies *bug fixes* only to the latest minor and **security patches to
the last 5 minors** (verbatim from the official docs: *"Elixir applies bug fixes only to the latest
minor branch. Security patches are available for the last 5 minor branches"*). OTP maintains 3 branches
(the current one and the two previous). Operational translation: **one Elixir minor per release (2/year) and
one OTP major per year**. Falling two years behind on OTP means going without patches.

**Elixir's type system — actual state as of 2026-08** (this has changed and must not be stated from
memory): Elixir 1.20 completed the **first milestone** of the *gradual set-theoretic types*: the compiler
**infers and checks types of any Elixir program without annotations**, reporting dead code and
guaranteed runtime violations, with a low false-positive rate. What there is **not** yet:
**user-defined type signatures or a public API for the type system**. The next announced milestones
are typed structs and then function signatures. Consequences:
- Type-compiler warnings **are errors**: `--warnings-as-errors` in CI, no exceptions.
- Pattern matching is now *load-bearing*: writing `%User{} = user` gives the compiler evidence.
  Matching the struct explicitly goes from style to technical decision.
- `@spec` is still the only way to declare intent and **is still Dialyzer's business**, not
  the compiler's. Do not confuse them or assume one replaces the other.

**Dialyzer/Dialyxir — real cost, decide with your eyes open**: it is *success typing*, not a type
checker; it does not fail on a missing spec and produces false negatives happily. The first
run builds a PLT that takes minutes, and its messages are notoriously cryptic. Criteria:
- Adopt it **only** with a cached PLT in CI and with a versioned `.dialyzer_ignore.exs` that is **empty as a
  goal**, not a dumping ground.
- `@spec` mandatory on each module's **public API** and on *behaviours*; optional inside.
- If the team is not going to read its warnings, do not install it: a gate everyone skips is worse than
  none. With Elixir 1.20 the compiler already covers part of what used to justify Dialyzer:
  re-evaluate the cost/benefit on every upgrade (§8).

## 3. Structure and conventions: the concurrency model

**What the BEAM gives you and what it implies**: lightweight processes with **their own heap** (no mutable
shared memory), pre-emptively scheduled, communicating only by **asynchronous message passing**.
The rules come from that, not from taste:

- **One process per unit of real concurrency**, not per unit of code. A process is not an
  object: if it does not represent a concurrent activity, an owned piece of state or a failure isolation,
  it is a function.
- **`let it crash` properly understood**: it means *do not program defensively against errors you do not
  expect*, letting the process die and the supervisor restore a clean, known state.
  It does **not** mean not handling errors. Operational rule:
  - **Expected** domain errors (validation fails, resource does not exist, remote returns 429) →
    return value `{:ok, _} | {:error, _}`, handled explicitly. Crashing here is a bug.
  - **Unexpected** errors (broken invariant, impossible state, bug) → crash. Do not rescue them.
  - `try/rescue` is the exception, not the style. A `rescue` that swallows and carries on with corrupt state is
    **forbidden**: you have turned a recoverable crash into silent corruption.
  - A crash with no **telemetry or deliberate supervision** is not *let it crash*, it is an outage.
- **Supervision tree = design, not boilerplate**. Every application declares its tree in
  `application.ex` with an explicit startup order. Strategies:
  - `:one_for_one` — independent children. Default; if you do not know which to use, it is this one.
  - `:one_for_all` — the children share state or a connection: if one falls, the rest are inconsistent.
  - `:rest_for_one` — chained dependency (child N depends on the previous ones). It is the one almost
    nobody uses and the correct one more often than it seems.
  - `max_restarts`/`max_seconds` with **deliberate** values: if a child cannot start (bad config,
    dependency down), you want the supervisor to give up and the process to really die so the
    orchestrator reschedules it, not an infinite restart loop the healthcheck never sees.
  - `:transient` for work that finishes normally; `:temporary` for tasks that must not be
    restarted (an idempotent job is re-enqueued by its queue, not by the supervisor).
  - `DynamicSupervisor` for per-entity processes (a connection, a game, a device) +
    `Registry` to locate them by key. That is the pattern, not a global map in a GenServer.
- **When NOT to use a GenServer** — the most expensive antipattern on the BEAM: a GenServer is a **single-threaded
  bottleneck**. Every `handle_call` serialises. It is forbidden to use it for:
  - Holding configuration or read-only data → `:persistent_term` (copy-free reads, extremely expensive
    writes: only for near-immutable data) or `:ets` with `read_concurrency: true`.
  - Caching data read by many processes → `:ets` (`:public`/`:protected` table, `named_table`),
    not a GenServer that copies the value on every `call`.
  - Wrapping pure functions "to have state" → pass it as an argument.
  - Parallelising work → `Task.async_stream` with explicit `max_concurrency` and `timeout`.
  - **Rule**: if the process only reads, it is not a process. If `handle_call` shows up in a profile as
    wait time, you already have the bottleneck.
  - `Agent` is a GenServer with less ceremony and **the same** serialisation problems: for
    trivial state and no concurrency. If it starts growing, it is a GenServer and you need to review whether
    it should be ETS.
- **State in the process**: a GenServer's `state` is lost on restart — that is the point. What
  cannot be lost goes to the database or to ETS with a supervised owner; what is lost must
  be reconstructible in `init/1` (and `init/1` must be fast: heavy work in
  `handle_continue`, never blocking the supervisor's startup).
- **`:ets`**: the table dies with its owner process → the owner is a dedicated supervised process
  (or use `heir`). `:ets` is not replicated across nodes and is not a database.
- **Back-pressure — mandatory in every ingest path**: a process's mailbox is **unbounded**. A
  producer faster than the consumer does not error: it fills memory until the node dies from
  OOM. Never do `GenServer.cast` in a loop over input data.
  - External source (SQS, Kafka, RabbitMQ, HTTP) → **Broadway**: demand, batches, retries,
    *rate limiting* and telemetry out of the box.
  - Internal pipeline with stages → **GenStage** (explicit demand).
  - One-off work over a bounded collection → `Task.async_stream` with `max_concurrency`.
  - `Flow` only for parallel collection processing and if you accept its maintenance
    cadence (no releases since 2023).
- **Timeouts**: `GenServer.call/3` with an explicit timeout (the 5000 ms default is also a
  decision, take it deliberately). A `call` between two GenServers that can block each other is
  a deadlock waiting to happen: break the cycle with `cast` + asynchronous reply or reorder the
  responsibility.
- **Naming and organisation**: one module per file, `lib/<app>/<context>/`; no
  `Utils` junk drawer. Process modules (`GenServer`) separate from pure-logic ones — the
  logic is tested without starting processes.

**Ecto**:
- `Repo` is the only database access point. Interpolated raw SQL is forbidden
  (`Ecto.Adapters.SQL.query!` with an interpolated string); if you need SQL, `fragment/1` with parameters.
- **Changesets** at the edge: `cast/4` with an explicit field list (never every field in the
  schema), `validate_*`, and the **database constraints** (`unique_constraint`,
  `foreign_key_constraint`, `check_constraint`) declared — a validation without a constraint is a
  race condition, not a validation.
- **`Ecto.Multi`** for any operation with more than one write: one transaction, errors typed per
  step, and no `Repo.transaction(fn -> ... end)` with exceptions as flow control.
- **The connection pool is the app's real concurrency limit**, not the number of processes.
  With `pool_size: 10`, the eleventh simultaneous query waits. Size it against the engine's `max_connections`
  and the number of nodes (`pool_size × replicas ≤ engine limit`), set `queue_target` and
  `queue_interval`, and **alert on checkout wait**: it is the metric that anticipates the incident.
  Long or analytical queries go to a separate `Repo` with its own pool.
- N+1: explicit `preload` (or `Ecto.Query` with `join` + `preload`). Ecto does no lazy loading — if
  you see `Ecto.Association.NotLoaded`, the query design is wrong, not missing magic.
- Migrations: reversible (`up`/`down` or a verifiable `change`), **backwards compatible**
  (expand/contract) because version N-1 of the code is still alive during the rolling deploy;
  PostgreSQL indexes with `concurrently: true` and `@disable_ddl_transaction true`. Destructive ones
  in a later release. Data migrations do **not** belong in schema migrations: script or job.

**Phoenix**:
- **Contexts**: the domain's public boundary. The controller/LiveView calls the context; **never**
  `Repo` or a schema directly. A context that only does `Repo.all/1` is an empty layer:
  either it has rules, or the cut is badly made. Phoenix 1.8 introduces *scopes* so that context
  functions carry the access scope (user/organisation) in the signature — use it: it turns
  access control into something the compiler and the generator can see.
- **LiveView — the state lives on the server**, one process per connection:
  - **Authorisation on EVERY event**, not just in `mount/3`. `handle_event` receives client data and
    the client can send any event in any order: if the check is only at
    mount time, you have IDOR. Same for `handle_params` and for `handle_info` triggered by PubSub.
  - Assigns that are not rendered still live in server memory: **do not put secrets,
    tokens or large datasets in assigns**. Multiply by the number of connections to size it.
  - What goes to the client (`phx-value-*` attributes, forms) is **untrusted input**. Validate
    with a changeset just like in a controller.
  - The LiveView session is established at the handshake: `live_session` with `on_mount` for
    authentication, and a signed `Phoenix.LiveView.Socket` — but *signing* guarantees integrity, not
    current authorisation. Revalidate permissions that may have changed.
  - Slow work in `handle_event` blocks that user's UI: `start_async`/`assign_async` or a
    supervised `Task`.
  - `temporary_assigns` and streams for large lists; sending 10,000 rows in every diff is LiveView's
    classic performance bug.
- **Channels / PubSub**: `join/3` authorises the topic (never accept a topic built from client
  data without checking it), and each `handle_in` authorises again. `Phoenix.PubSub` is *best effort*
  within the cluster: no persistence, no global ordering, no guaranteed delivery. If the message
  cannot be lost, it goes to a broker (`message-brokers-standards`) or to the database.
- **Plug**: explicit pipelines per traffic type (`:browser`, `:api`); CSRF enabled on session
  ones; the authentication plug **before** any resource router, and authorisation as
  close as possible to the data, not just in the pipeline.

**Releases and deployment**:
- `mix release` with `MIX_ENV=prod`, `runtime.exs` for all environment-dependent config
  (`config.exs` is frozen at compile time: a secret there ends up **inside the artefact**).
- **Hot code upgrade — you almost never want it.** Verbatim from the official `mix release` docs:
  *"this feature is not supported out of the box by Elixir releases"*, because *"they are very
  complicated to perform in practice, as they require careful coding of your processes and
  applications as well as extensive testing"*, and *"Given most teams can use other techniques that are
  language agnostic to upgrade their systems, such as Blue/Green deployments, Canary deployments,
  Rolling deployments, and others, hot upgrades are rarely a viable option."* Criteria: **rolling or
  blue/green**. A hot upgrade is only justified in systems with state impossible to drain
  (telecoms, embedded devices with no restart window) and with the budget to hand-write
  `.appup`/`.relup` and test them.
- Orderly shutdown: SIGTERM → `:init.stop` drains the supervision tree top down. Give enough
  headroom in the orchestrator (`terminationGracePeriodSeconds`) for processes with in-flight work to
  finish; a `terminate/2` that does not run is lost work and `terminate/2` is **not
  guaranteed** in all cases (brutal kills, `:brutal_kill`) — do not put critical logic there.

## 4. Quality and testing

- **Formatting**: `mix format` with a versioned `.formatter.exs`; `mix format --check-formatted` in CI.
  Zero style debate.
- **Compilation**: `mix compile --warnings-as-errors`. With 1.20's type system this is no longer
  hygiene, it is a type checker with a gate.
- **Credo**: `mix credo --strict`. Design rules (`Credo.Check.Design.*`) tuned once and
  fixed in `.credo.exs`; no silencing `Warning` or `Readability` checks wholesale.
- **ExUnit**:
  - `async: true` **by default**, and understand when it breaks: any test touching **shared global
    state** — a globally registered named process, `:persistent_term`, a named `:ets`
    table, `Application.put_env`, the filesystem, a fixed port, or the database with
    `Ecto.Adapters.SQL.Sandbox` in `:shared` mode — must be `async: false`. With the sandbox in
    `:manual` mode and a per-test checkout, Ecto tests **can** be async.
  - One failure reason per test, AAA, names that describe observable behaviour.
  - Cover the happy path **and edges and errors**: invalid input, remote process timeout, crash
    of the supervised process (verify the supervisor restarts and the system converges), full
    mailbox, constraint conflict under concurrency.
  - **Logic in tests is forbidden** and so is `Process.sleep` for synchronisation: use
    `assert_receive`/`refute_receive` with a timeout, `Task.await`, or `:telemetry` messages.
  - Test pure logic without starting processes; test the process by its **observable contract**
    (messages it emits, effects it produces), not by its internal `state`.
- **Mox and the *behaviours* pattern** — the only way to mock here:
  - Define a `@behaviour` for the boundary (HTTP client, payment gateway, clock), inject the
    implementation via configuration, and `Mox.defmock` in test. `set_mox_global` only as a last
    resort, and then `async: false`.
  - **Mock only system boundaries**, never your own modules. Replacing your own code with a
    mock is testing the mock.
  - ❌ Libraries that rewrite modules at runtime (`meck` and derivatives): they break `async: true` and
    hide signature changes.
  - Verification in `setup :verify_on_exit!`: an uncalled mock is a test that lies.
- **Property-based with StreamData** for logic with invariants (parsers, serialisation,
  normalisation, state machines, domain arithmetic): it does not replace example-based tests, it
  complements them. `ExUnitProperties` with a recorded seed to reproduce failures.
- **CI gates** (block merge, cheap to expensive):
  1. `mix deps.get --check-locked` + `mix format --check-formatted`
  2. `mix compile --warnings-as-errors`
  3. `mix credo --strict`
  4. `mix deps.audit` + `mix hex.audit` + `mix sobelow --exit` (in Phoenix projects)
  5. `mix test` (with `--warnings-as-errors`)
  6. `mix dialyzer` with a cached PLT (the most expensive; if it takes too long, in a separate job, but
     **blocking**)
- Coverage (`mix test --cover`, ExCoveralls) as a signal, not a target.

## 5. Stack security

- **Atom exhaustion — the BEAM's signature vulnerability**. Atoms are **not garbage
  collected** and the atom table has a fixed limit (configurable with `+t` in `vm.args`);
  reaching it kills the whole node. Therefore:
  - ❌ **FORBIDDEN** `String.to_atom/1` with any data coming from outside (request, queue
    message, file, database). Use `String.to_existing_atom/1` inside a `try/rescue` or, better,
    a `case` with an allowlist of permitted values.
  - ❌ `:erlang.binary_to_atom/2`, `List.to_atom/1`, `Module.concat/1` with user input
    (`Module.concat` creates atoms **and** can resolve to a loadable module: that is arbitrary execution).
  - ❌ `Jason.decode!(payload, keys: :atoms)` — the shortcut that turns every attacker key into a
    permanent atom. Use `keys: :strings` (default) or `keys: :atoms!`.
  - ❌ Dynamic `:telemetry` keys, process names or ETS table names derived from input.
- **Deserialisation**. Verbatim recommendation from the Erlang Ecosystem Foundation Security WG:
  *"Use the `:safe` option when calling :erlang.binary_to_term/2 on untrusted input"*, with the
  explicit limitation that *"The safe option does not affect the deserialisation of functions and
  other unsafe terms"*. Criteria:
  - ❌ **FORBIDDEN** `:erlang.binary_to_term/1` (no options) over external data.
  - With external data: `Plug.Crypto.non_executable_binary_to_term/2` with `[:safe]` — it covers both
    atom creation and function deserialisation.
  - Better still: **do not use External Term Format as an interchange format with the outside world**. JSON or
    Protobuf at the edge; ETF only between nodes of your own cluster.
- **Dynamic execution**: ❌ `Code.eval_string/3`, `Code.eval_quoted/3`, `Code.compile_string/2`,
  `EEx` with a user-controlled template, `apply/3` with a module or function coming from the
  request. If you need dynamic dispatch, an explicit allowlist.
- **Ports and NIFs**: ❌ `System.cmd/3` or `:os.cmd/1` with input interpolation (`System.cmd`
  with an argument list and no shell is the correct form). A NIF that crashes **kills the whole node**,
  bypassing the entire isolation model: treat every third-party NIF as privileged code and
  audit it before adding it.
- **Distributed Elixir — it is NOT secure by default. This is the most important thing in this section.**
  Verbatim quotes from the EEF Security WG:
  - *"Cookies enable rudimentary access control, letting nodes decide which other nodes can join a
    cluster. The cookie value is not transmitted on the wire (a challenge/response mechanism is used),
    but no protections are in place against an active (man-in-the-middle) attack."*
  - *"The default distribution protocol transmits all application data in the clear, using a variant
    of External Term Format."*
  - *"The EPMD protocol allows unauthenticated clients to look up a node by name, as well as to
    retrieve the full list of known nodes... Running EPMD on an untrusted network therefore exposes
    information about the distributed Erlang cluster(s) known at the host."*
  - Textual recommendations: *"Enable strong authentication, confidentiality and integrity
    protection by using TLS rather than TCP for the distribution protocol"*, *"Isolate the
    distribution protocol and EPMD from client facing network interfaces"*, *"Use an SSH tunnel or
    VPN for remote access to the Erlang shell"*.
  - The consequence that must be said out loud: **whoever reaches the distribution port and knows the
    cookie executes arbitrary code on every node in the cluster**. The cookie is effectively a
    distributed root credential.
  - **On Kubernetes**, this translates into concrete, non-negotiable requirements:
    1. A **randomly generated** cookie, in a `Secret`, injected as `RELEASE_COOKIE` — never in
       the image, in the repo, or in a committed `vm.args`. One cookie per environment.
    2. A *default deny* `NetworkPolicy` that only allows port 4369 (EPMD) and the distribution
       range **between the pods of the release itself**; never exposed in a Service or Ingress.
    3. A pinned distribution range (`inet_dist_listen_min`/`max`) so the network policy is
       writable.
    4. **Distribution TLS** (`-proto_dist inet_tls`) with mutual verification against a cluster
       CA, as soon as inter-node traffic leaves a trusted network plane. Assume it
       costs effort: Erlang distribution certificates are fussy.
    5. Discovery with `libcluster` and a headless `Service`; optionally `-start_epmd false` with your own
       `epmd_module` to eliminate EPMD.
    6. ❌ **Never** use Erlang distribution to cross architecture layers (application →
       database, or between two services of different domains): it provides no isolation whatsoever.
  - `:observer` and `remote_console` in production: only through an authenticated tunnel, with a named account and
    auditing. A remote `iex` is a root shell over the entire system.
- **Phoenix hardening**: `sobelow` as a gate (detects XSS in `raw`, insecure config, traversal, disabled
  CSRF, `Code.eval` and secrets in the repo). Also: `secret_key_base` from the environment,
  `force_ssl` with HSTS, `put_secure_browser_headers` with an explicit CSP, socket `check_origin`
  **with a real list** (❌ `check_origin: false` in production), session cookies `secure`,
  `http_only`, `same_site`.
- **XSS in HEEx**: HEEx escapes interpolation by default; ❌ `raw/1` and `Phoenix.HTML.raw` over
  user content. Dynamically built attributes and an `href` with a user-supplied scheme are
  vectors that escaping does **not** cover.
- **Authorisation**: default deny; the scope travels in the query (`from u in User, where: u.org_id ==
  ^scope.org_id`), not in a later `if`. With Phoenix 1.8 *scopes*, in the context signature.
- **SCA and supply chain**: `mix.lock` committed and verified in CI; `mix deps.audit` and
  `mix hex.audit` as gates; human review of every new dependency (maintainer, activity,
  downloads, licence). Remember that `mix deps.compile` **executes third-party code** (`mix.exs`,
  custom compilers, NIFs that compile C): the job that installs dependencies must not have production
  credentials within reach.
- **Secrets**: `runtime.exs` reading from the environment or from a manager; ❌ secrets in `config/prod.exs`
  (they end up compiled inside the release), in the image or in logs. Filter sensitive parameters in
  Phoenix (`filter_parameters`) and in telemetry.

## 6. Performance and operability

- **`:telemetry` is the native instrumentation and it is not optional**: events at the boundaries (HTTP,
  Ecto, jobs, external clients, LiveView), `telemetry_metrics` for aggregation and an exporter
  (OpenTelemetry or Prometheus). Phoenix and Ecto already emit events: consume them, do not reinvent.
  - Minimum runtime metrics: **mailbox lengths** (a growing mailbox is the early
    warning of almost every BEAM incident), number of processes vs `+P`, memory by type
    (processes/binaries/ETS/atoms), scheduler utilisation, **Ecto pool checkout
    wait**, job queue time, supervisor restarts.
  - ❌ Telemetry event names built from user data (it creates atoms, §5).
- **Live diagnosis**: `:observer` (or `observer_cli`) in development; in production **`recon`** is
  the right tool — it is designed to be safe on a loaded node (`recon:proc_count/2`,
  `recon:bin_leak/1` for the classic growth from fragmented *refc binaries*). ❌ `:erlang.processes()`
  + manual inspection on a production node with hundreds of thousands of processes.
- **Binaries**: binaries >64 bytes go to the shared heap with a refcount; a `:binary.part/3` over
  a large binary keeps the whole original alive. Use `:binary.copy/1` when storing fragments
  of large payloads in long-lived state — it is the usual cause of "memory goes up and never comes down".
- **Sizing**: the BEAM uses all cores by default; in a container **pin the schedulers to
  the real CPU limit** (`+S`/`+SDio` or the equivalent variable) or the scheduler will compete with
  itself under *cgroup throttling*. Reserve memory counting: process heaps + binaries + ETS.
- **Classic bottlenecks, in order of frequency**: (1) a GenServer serialising work,
  (2) the Ecto pool, (3) a mailbox growing for lack of back-pressure, (4) `:ets` with write
  contention (`write_concurrency`), (5) retained binaries. Profile (`recon`, `:fprof` in development)
  before optimising.
- **Reliability**: explicit timeouts on every external client (Finch/Req with `receive_timeout`),
  circuit breaker on fragile dependencies, retries with backoff+jitter only on idempotent
  operations. An unsupervised `Task` that dies takes silence with it: use `Task.Supervisor`.
- **Persistent jobs**: the work queue is **not** an in-memory process. If the work must
  survive a restart, it goes to a persistent queue (Oban or another database-backed one —
  verify its licence and status in §8), with idempotency, a retry limit and a monitored
  dead-letter queue. A `Task.start/1` is not a job.
- **Health**: a liveness endpoint that only checks the VM responds and a readiness one that checks
  dependencies (Ecto pool, migrations applied). A node whose supervision tree is restarting
  in a loop must fail readiness, not keep receiving traffic.
- **Structured logs** with metadata (`request_id`, `trace_id`); level `:info` in production,
  `:debug` switchable; ❌ personal data or secrets in logs.

## 7. Long-term sustainability

- **Cadence**: security patches immediately; Elixir one minor per release (2 a year, within
  6 months); OTP one major a year. Remember that Elixir only patches security in the **last 5
  minors** and that the compatibility matrix ties both versions: plan the jumps together.
- Elixir/Phoenix/Ecto deprecations: resolved in the current release. `mix compile
  --warnings-as-errors` already forces it; do not disable it "temporarily".
- A Hex dependency with no releases in >18 months is reviewed or replaced (Flow is the living example).
  `mix hex.outdated` in the periodic review, `mix hex.audit` in CI.
- Conscious debt: shortcut = TODO with a reason and a linked issue.

**List of prohibitions (veto):**
- ❌ **FORBIDDEN** `String.to_atom/1` (and `binary_to_atom`, `List.to_atom`, `Module.concat`) with
  user input. ❌ `keys: :atoms` when decoding external JSON.
- ❌ **FORBIDDEN** `:erlang.binary_to_term/1` without `[:safe]` over external data; use
  `Plug.Crypto.non_executable_binary_to_term/2`.
- ❌ `Code.eval_string`/`Code.eval_quoted`/`Code.compile_string`, `EEx` with a user template,
  `apply/3` with a module or function from the request.
- ❌ `System.cmd`/`:os.cmd` with input interpolation.
- ❌ Exposing the distribution port or EPMD outside the cluster; a cookie in the image, in the repo or
  shared between environments; Erlang distribution across layers or between services of different domains.
- ❌ `check_origin: false`, CSRF disabled, `raw/1` over user content in production.
- ❌ Authorising only in a LiveView's `mount/3`: every `handle_event`/`handle_params` re-authorises.
- ❌ Secrets or large datasets in LiveView assigns; secrets in `config/prod.exs`.
- ❌ GenServer as a cache, as a read-only configuration store or as a wrapper for
  pure functions. ❌ `Agent` for state that grows.
- ❌ Sending messages to a process with no back-pressure mechanism (`cast` in a loop over an ingest).
- ❌ `try/rescue` that swallows the exception and continues with potentially corrupt state; using
  exceptions as domain flow control.
- ❌ Critical logic in `terminate/2` (it is not guaranteed to run).
- ❌ `Process.sleep` to synchronise tests; tests with logic; `async: true` in tests that touch
  global state, `:persistent_term`, a named ETS table or `Application.put_env`.
- ❌ Mocking your own modules or rewriting modules at runtime (`meck`); mocks without `verify_on_exit!`.
- ❌ Interpolated SQL in `Ecto.Adapters.SQL.query!`; `cast/4` with the schema's full field
  list; uniqueness validation without `unique_constraint` and without a unique index.
- ❌ A destructive migration in the same release as the code that stops using the column.
- ❌ Hot code upgrade as the default deployment strategy (rolling or blue/green).
- ❌ Deploying on Elixir or OTP outside the security-patch window, or with a combination
  outside the official compatibility matrix.
- ❌ Adding a third-party NIF without auditing it: a NIF that crashes kills the whole node.

## 8. Mandatory web verification

Before pinning versions or claims in a project, **verify online**:
1. **Elixir**: latest stable and support policy (`elixir-lang.org`, `endoflife.date/elixir`).
   Is 1.20 still the current series or is 1.21 already out? Remember: bug fixes only in the latest minor,
   security in the last 5.
2. **Erlang/OTP**: latest major and EOL (`erlang.org`, `endoflife.date/erlang`). OTP 29 (2026-05-11,
   EOL 2029-05-11), OTP 28 and OTP 27 alive; OTP 26 EOL 2026-05-26 → confirm.
3. **Elixir ↔ OTP compatibility matrix**: official table at
   `hexdocs.pm/elixir/compatibility-and-deprecations.html`. Never assume it from memory; it changes on
   every release.
4. **Type system**: is the *typed structs* or *function signatures* milestone already available?
   As of 2026-08 there are **no user type signatures and no public API**. Source: `elixir-lang.org/blog` and
   `gradual-set-theoretic-types.html`, not third-party blogs.
5. **Phoenix and LiveView**: current major version (1.8.x / 1.2.x as of 2026-08) and whether there is 1.9 / 1.3 with
   generator or authentication changes. `phoenixframework.org/blog`.
6. **Tools**: Credo, Dialyxir, Sobelow (slow cadence: **confirm it is still maintained before
   pinning it as a gate**), Mox, StreamData, Broadway, GenStage, Flow (no releases since 2023),
   `mix_audit`, Bandit, Ecto.
7. **Licences and business model** of everything you are going to pin as a default — check the
   raw `LICENSE`, not the README badge. Recent precedents that broke pipelines:
   **Trivy** changed its licence and **gitleaks** declared itself *feature complete* with its action requiring
   a commercial licence for organisations from v2 onwards. Apply the same scrutiny to **Oban** (it has
   paid editions) before assuming it as the default queue.
8. **Security**: advisories from the Erlang Ecosystem Foundation Security WG (`security.erlef.org`),
   `erlang.org/doc` for distribution, GitHub Advisories / osv.dev for Hex. Check specifically
   whether there are later advisories in OTP's `ssh`/`ssl` and whether the distribution hardening guide has
   changed.

**Declared gaps (not verified as of Aug 2026)**:
- Current maintenance status of **Sobelow** (last release located: 0.14.1, Oct 2025) and of
  **Mox** (1.2.0, Aug 2024): **not verified** whether they are still active or in maintenance mode.
- Version, licence and model of **Oban** as the default job queue: **not verified**.
- Whether OTP 29 already has enough adoption in the Hex ecosystem (NIFs and precompiled builds) to be the
  default in greenfield over OTP 28: **not verified**.
- Default value of the atom table limit (`+t`) in OTP 28/29: **not verified** — read it from
  `erlang.org/doc/apps/erts/erl_cmd.html` before quoting it.

If the web contradicts this document, **the web wins** — flag the discrepancy.
