---
name: clojure-standards
description: Clojure and ClojureScript engineering standards (staff-level). Trigger on .clj/.cljs/.cljc/.edn files, deps.edn, project.clj, bb.edn, shadow-cljs.edn, tools.build build.clj, .clj-kondo/config.edn, .cljfmt.edn, tests.edn (kaocha), and on libraries such as ring, reitit, pedestal, next.jdbc, honeysql, integrant, component, mount, malli, clojure.spec, core.async, test.check, clj-kondo, eastwood or nREPL. Apply when writing, reviewing or setting up CI for Clojure, when doing REPL-driven development, and when choosing state management, schema validation or component lifecycle.
---

# Clojure standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all Clojure/ClojureScript code: `.clj`, `.cljs`, `.cljc`, `.edn` files, `deps.edn`, `project.clj`, `bb.edn`, `shadow-cljs.edn`, `build.clj` (tools.build), `.clj-kondo/config.edn`, `.cljfmt.edn`, `tests.edn`, and the pipelines that compile/test Clojure. Covers backend services, jobs, libraries, scripts (babashka) and the REPL-driven working method. It sets **criteria**: what to use, what is forbidden, what to verify.

**Not applicable**: see `jvm-spring-standards` (**the JVM itself and Spring**: JDK distribution and version, LTS, GC and its tuning, startup flags, JFR, containerising the JVM — if a Clojure project uses Spring, **`jvm-spring-standards` wins for Spring**; here only the Clojure code, its native builds —`deps.edn`/tools.build, Leiningen— and its libraries), `scala-standards` (the other JVM language in the catalogue: same runtime, opposite paradigms —dynamic and homoiconic versus rich static typing—; the choice between the two is one of **team and ecosystem**, not performance), `lisp-standards` (**the rest of the Lisp family, outside the JVM**: Common Lisp, Scheme and Emacs Lisp — image and `save-lisp-and-die`, condition system and restarts, CLOS and the MOP, ASDF/Quicklisp; **the boundary is not "it is a Lisp"**: none of that extrapolates to Clojure or the other way round), `data-engineering-standards` and `lakehouse-standards` (**Spark is theirs as a platform**: pipeline, orchestration, table format and cost; the Clojure/Scala code of the job belongs to the language skills), `streaming-cdc-standards` (Kafka Streams/Flink as a platform), `api-design-standards` (HTTP contract design; here only its implementation with ring/reitit/pedestal), `sql-standards` (**the SQL itself**: schema, indexes, plans — HoneySQL generates SQL and that SQL is subject to their criteria), `data-platform-standards` (engine modelling and tuning), `microservices-architecture-standards` (service boundaries, sagas, distributed resilience), `appsec-standards` (threat modelling and agnostic vulnerability classes; here only the concrete Clojure sinks), `vulnerability-management-standards` (CVE triage and SLA; here only the build gate), `secrets-management-standards`, `observability-standards` (OTel pipeline; here only the in-code instrumentation), `cicd-standards`, `kubernetes-standards`, `python-standards`/`go-standards`/`rust-standards` (language choice), `groovy-standards` (**the third JVM language in the catalogue**, with a different role: it is above all a configuration language for other tools — Gradle's Groovy DSL and the `Jenkinsfile` are theirs).

## 2. Toolchain and default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Piece | Choice | Status as of 2026-08 | Note |
|---|---|---|---|
| Language | **Clojure 1.12.5** (stable) | 1.13.0-alpha6 in progress | 1.13 will require **Java 17+** and takes `spec` out of the core artifact |
| Build/deps | **`deps.edn` + `tools.deps` + `tools.build`** | CLI 1.12.5.x, tools.build 0.10.14 | Default for new projects |
| Alternative build | **Leiningen 2.13.0** | **Canonical repo moved to Codeberg**; GitHub is a "temporary convenience mirror" | Alive, not abandoned; kept only in repos that already use it |
| Scripting | **babashka 1.13.x** | — | Replaces bash in non-trivial automation |
| Lint (gate) | **clj-kondo** (calendar versioning, EPL-1.0) | v2026.08.x | **A CI gate, not a suggestion** |
| Formatting | **cljfmt 0.16.x** | — | Versioned config; formatting is not up for debate |
| Semantic lint | **eastwood 1.4.3** | — | Optional, complements clj-kondo; slower (it loads the code) |
| Test runner | **kaocha 1.91.x** (EPL-1.0) | — | Alternative: `cognitect-labs/test-runner`, simpler |
| Properties | **test.check 1.1.3** | — | Mandatory in logic with invariants |
| Schemas | **Malli 0.20.x** (EPL-2.0) for new code | `spec.alpha` 0.6.x still maintained | **spec 2 (`spec-alpha2`) has no release: do not architect on it** |
| Lifecycle | **Integrant 1.0.x** | Component 1.2.0, mount 0.1.16 | See §3 |
| Web | **ring 1.15.x + reitit 0.10.x** | pedestal as an alternative | ring is the common substrate |
| Data | **next.jdbc 1.3.x + HoneySQL 2.7.x** | — | `clojure.java.jdbc` is legacy |
| Concurrency | **core.async 1.9.865** (stable) | 1.10.x in alpha | See §6 on virtual threads |
| SCA | **nvd-clojure 5.3.0** | **clj-holmes with no releases since 2022/2023** | See §5 |

**Stability as a design value, not as stagnation.** Clojure breaks compatibility very rarely and libraries from years ago still work. Operational consequences:
- A dependency "with no commits in 3 years" **is not automatically abandoned** in this ecosystem, unlike in others. The criterion is: does it solve the problem, does it have a small surface, are there open issues with no answer that affect you, are there CVEs in its transitives? It is decided with that data, not with the date of the last commit.
- The corollary: nor is any upgrade "free". Bumping the Clojure version is cheap; bumping the **JDK** underneath may not be (1.13 moves the minimum to Java 17). That jump is governed by `jvm-spring-standards`.

**`deps.edn` versus Leiningen.** New project: `deps.edn` + tools.build (data model, composable aliases, no plugins that run third-party code in the build by default, it is the core team's tool). Leiningen is still alive and maintained —2.13.0, with the **canonical repo on Codeberg** since 2025— and is defensible in a repo that already uses it and depends on its plugins; migrating for fashion is cost without benefit. **Do not mix the two** in the same project (two sources of truth for dependencies = duplicated classes on the classpath). `deps.edn` versioned; separate `:dev`/`:test`/`:build` aliases, and **development tools (nREPL, cider) never in the base dependencies** (§5).

## 3. Structure, state and architecture

**REPL-driven development is the working method, with rules.**
- You evaluate in the editor against a REPL connected to the project; the cycle is write → evaluate the form → try it in the REPL → **pin the result as a test**. Whatever works in the REPL and does not become a test does not exist.
- **The live REPL state is also a source of bugs.** A long session accumulates redefined vars, namespaces with definitions deleted from the file but still loaded, recompiled protocols with old instances, multimethods with orphan methods and half-started components. Classic symptom: works in the REPL, fails in CI (or the other way round).
- Rule: **reload in a directed way** (`clojure.tools.namespace.repl/refresh` or the component system's reset) after structural changes; **restart the REPL** —do not argue with it— on any of these: a change to a protocol/`deftype`/`defrecord`, a change of dependencies, a `refresh` that fails, or inexplicable behaviour. Before saying "fixed", the change is validated in a **clean process** (`clj -M:test` from scratch), never only in the live session.
- A system with a lifecycle (§ below) makes `reset` reliable; without one, reloading is a lottery.

**Immutability and persistent structures** are the default: values are not modified, they are derived (`assoc`, `update`, `conj`). Transients (`transient`/`persistent!`) only inside a function, over local data, when the profiler justifies it; never escaping to another part of the program.

**State management — every primitive has its case, and none is "the place where I keep everything".**
| Primitive | When |
|---|---|
| `atom` | Independent, synchronous state, updated with a pure function. 90 % of the legitimate cases |
| `ref` (STM) | **Only** when two or more pieces of state must change in a coordinated and atomic way |
| `agent` | Serialised asynchronous updates over a value (rare today; a queue is usually better) |
| `var` with `binding` | Dynamic context scoped to the call stack (`*out*`, request context). It is not application state |
| `volatile!` | Local, non-shared state in a transducer/hot loop |

- **The global atom antipattern**: `(defonce app-state (atom {}))` as the store for everything. It turns the program into a world with invisible coupling, impossible to test in parallel or to reason about; tests contaminate each other and load order matters. State is passed as an argument or lives in the component that owns it.
- Functions that mutate an `atom` receive **the pure function** that computes the new value (`swap!` with a separately testable function). `swap!` can retry: the function **must be pure** — no I/O and no effects inside.
- No hidden side effects in apparently pure functions; names with `!` mark effects.

**Components and lifecycle: something is needed.** Without an explicit system, state with start/stop (connection pools, HTTP server, consumers, schedulers) ends up in `defonce` + global atoms: it cannot be restarted without restarting the JVM, the REPL becomes inconsistent and integration tests cannot bring up two instances.
- **Integrant** by default: the system is **data** (an EDN configuration map), the keys are `init-key`/`halt-key!` multimethods, dependencies are expressed with `ig/ref`. Configuration outside the code and a system composable in tests.
- **Component** is equally valid and older (`Lifecycle` protocol, system as a registry); pick one per repo.
- **mount** only if the team accepts its model: it uses global vars, which reintroduces the implicit coupling that Integrant/Component avoid. It is not the default option.
- Hard rule, whichever you use: **the dependency is injected, not looked up**. No handler reaching into a `defonce` in another namespace.

**Maps as the interface, records and protocols as the exception.**
- Data between functions and between services is **maps and plain collections**; `defrecord` only when you need to implement a protocol or the performance of fixed fields has been measured; `deftype` almost never.
- **Protocols for polymorphism at boundaries** (a storage adapter, an external client) — that is how you substitute a double in tests. Multimethods when dispatch is by a value in the data (event type) and the set is open.
- **Namespaced keywords** (`:user/id`, `::db/spec`) in every piece of data that crosses a boundary: they avoid collisions when merging maps and they document provenance.
- **Destructuring** in the signature for what the function actually uses (`{:keys [id email]}`); no dragging the whole map around and looking inside it. Clojure 1.13 will add checked destructuring directives (`:keys!`) that fail if the key is missing — today, that contract is expressed with a schema (§ below).
- **Namespaces**: one per unit of responsibility, name = file path; explicit layers (`app.http.*` → `app.domain.*` → `app.db.*`) with dependencies in a single direction and **no cycles** (clj-kondo detects them). `:require` with an explicit alias always; **`:refer :all` and `use` are forbidden**.

**Schemas: Malli or spec, decided once per repo.**
- **Malli** for new code: schemas are **values** (manipulable data), local registries, built-in coercion and transformation, good error messages, JSON Schema/OpenAPI generation and direct integration with reitit. Cost: built-in coercion mixes validation and transformation — it is used explicitly at the edges, not implicitly everywhere.
- **`clojure.spec.alpha`** is still maintained and is defensible in codebases that already use it, especially if they rely on its generation for `test.check` and `instrument`. **`spec-alpha2` (spec 2) has no release and no tag; spending years in alpha rules it out as a basis for decisions** — do not plan migrations towards it. Watch the change under way: Clojure 1.13 moves spec out of the core artifact into its own library.
- Where to validate: **at the edges** (HTTP input, queue messages, files, third-party responses) and at important module boundaries. Validating everything everywhere is cost without signal.
- Function instrumentation (`malli.dev`/`stest/instrument`) is for **development and test**, not production.

## 4. Quality and testing

**clj-kondo is a build gate, not advice.** `.clj-kondo/config.edn` versioned, `clj-kondo --lint src test --fail-level warning` in CI; export library configs (`--copy-configs`). Veto by lint what §7 forbids: `:refer-all`, unused namespaces, redefined vars, shadowing of core vars, use of `clojure.core/read-string`, `eval` and `println` in service code. A baseline only for adoption in legacy code and **with an expiry date**.

**cljfmt** with versioned config, `cljfmt check` in CI. **eastwood** optional, in a separate job (it loads the code and is slow); useful for *reflection warnings* and semantic suspicions clj-kondo does not see.

**Testing.**
- `clojure.test` is the base; **kaocha** adds plugins (coverage, watch, randomisation, reports) and a versioned `tests.edn`. `cognitect-labs/test-runner` if nothing more is needed.
- **Property-based with `test.check` is mandatory** wherever there are invariants: round-trip serialisation, data transformation functions, combinatorial business rules, any parser. In a dynamic language, properties are the real substitute for the type-checker.
- Coverage of **edges and errors**: `nil` in every argument that can arrive as `nil` (the `NullPointerException` is still the number one failure in Clojure), empty collections, absent keys versus keys with a `nil` value (**they are not the same**), large numbers and division by zero, inputs outside the schema.
- Explicit fixtures (`use-fixtures`) to start/stop the Integrant/Component system; **each test gets its own system**, not a shared global one. Deterministic and parallelisable tests: no order dependencies and no state in global vars.
- Doubles: `with-redefs` **only in the test that needs it and over your own boundaries**; abusing it is a sign that an injected protocol is missing. Never `with-redefs` in a concurrent test (it is global and not thread-safe).
- Integration against real dependencies with testcontainers (same image and version as prod); replacing the real DB with a different embedded one is forbidden.
- Every bugfix leaves a regression test. A flaky test: it gets fixed or deleted. Coverage (cloverage) as a signal, not as a target.

**CI gates, in increasing order of cost (they break the build):**
```
cljfmt check  →  clj-kondo --fail-level warning  →  unit tests  →  integration tests  →  dependency SCA
```
Main always green; nothing is merged with CI red.

**Errors.**
- **`ex-info` is the standard**: `(throw (ex-info "message" {:error/type ::db-timeout :ctx ...}))`, with structured data in the map (`ex-data`) and `:cause` when it wraps another exception. No `(throw (Exception. (str ...)))`: it loses the information the caller needs in order to decide.
- You catch by **data**, not by class: `(catch clojure.lang.ExceptionInfo e (case (:error/type (ex-data e)) ...))`. Whatever you do not know how to handle is rethrown.
- **The `ex-info` map ends up in logs**: do not put secrets or PII in it (§5).
- Expected domain errors may be returned as a value (`[:ok v]` / `[:error m]` or a map with `:error`) instead of an exception; what does **not** work is mixing both styles in the same layer with no rule.
- **Clojure stack traces are a real operational problem**: machinery frames (`clojure.lang.AFn`, `RestFn`, `invokeStatic`), demangled names (`my_ns$my_fn`), the useful cause buried under several wrappers and, in `future`/`pmap`/pool, the worker thread's trace without the context of whoever launched it. Mitigations: your own context in `ex-data` (do not trust the trace), structured logging that serialises `ex-data` and the full cause chain, a top-level handler that records `Throwable->map`, and `-XX:-OmitStackTraceInFastThrow` so as not to lose repeated traces.

## 5. Stack security

- **`read-string` is FORBIDDEN over untrusted input.** `clojure.core/read-string` uses the full reader, which honours `*read-eval*` and therefore **executes code** (`#=(...)`) as well as instantiating objects via tags. For external data: **`clojure.edn/read-string` always**, with explicit `:readers` if tags are needed and `:default` for unknown tags. `clojure.edn` does not evaluate. Veto it in clj-kondo. The same applies to `read` over an input stream and to third-party tagged literals from `data_readers.clj`.
- **`eval` is forbidden over any data that comes from outside the code** (request, DB, file, remote config). The "configurable rules system" that evaluates Clojure sent by the user is RCE by design. The same for `load-string`, `load-reader`, `resolve`/`requiring-resolve` over input symbols (allowing them is equivalent to invoking any function on the classpath) and `Compiler/load`.
- **nREPL in production is unauthenticated remote code execution**, by design: whoever reaches the port runs whatever they want with the process's permissions. Rules: the nREPL dependency and its startup live **only in the `:dev` alias**, never in the production uberjar; if in an emergency a REPL is needed in a real environment, **bind to `127.0.0.1`** (nREPL's default is already localhost after it was fixed as a security bug) plus an SSH tunnel, or TLS with key authentication if you really have to listen on another interface; port closed in firewall/SecurityGroup/NetworkPolicy; audited session with an expiry. An open nREPL is worse than a typical RCE: it needs no exploit.
- **Dependencies resolved from Git (`:git/url` + `:git/sha` in `deps.edn`) are a supply chain decision.** Implications: the artifact **is not on Maven Central** nor signed, the SCA scanner that queries Maven coordinates does not see it, it is compiled from source on the machine that resolves it, and its own `deps.edn` drags in equally opaque transitives. Criteria: prefer Maven/Clojars dependencies; a Git dependency requires a **full pinned SHA** (never a branch or `:git/tag` without `:git/sha`), written justification, a review of the source repo and your own update tracking mechanism (the bot does not see it). `deps.lock`/`-Sdeps`/`clojure -P` in CI for reproducible resolution, and `~/.gitlibs` treated as a cache of third-party code.
- **SCA**: `nvd-clojure` (active, 5.3.0) against the dependency tree in CI and on a schedule; remember it only covers what has Maven coordinates. **`clj-holmes` (Clojure-specific SAST) has had no releases since 2022/2023: do not pin it as a mandatory gate; verify its status before adopting it** (§8). `antq` to detect outdated dependencies. The CVE triage SLA is set by `vulnerability-management-standards`.
- **Parameterised SQL only**: `next.jdbc` with a vector `["select ... where id = ?" id]` or **HoneySQL** (it generates parameterised SQL from data). **Using `str`/interpolation to build SQL is forbidden**; watch out for dynamic identifiers (table/column names), which are not parameterisable: allowlist, never concatenation. The criteria for the resulting SQL belong to `sql-standards`.
- **Native Java serialisation is forbidden** for external data (`ObjectInputStream`, and therefore also any cache/session that uses it underneath). EDN, Transit or JSON with bounded readers.
- **HTTP input**: schema validation (Malli/spec) at the edge before touching the domain; body size and depth limits; in ring, **`wrap-anti-forgery` in apps with sessions** (do not disable it "because it gets in the way"), `HttpOnly`/`Secure`/`SameSite` cookies, and security headers (`ring-defaults` with `secure-site-defaults` as a starting point, reviewing what it enables).
- **Secrets** never in `deps.edn`, `project.clj`, a versioned `resources/config.edn`, `ex-data` or logs. Config from the environment or a manager (`aero`/`integrant` reading variables); in the REPL, take special care: printing the whole system (`(ig/init ...)`) dumps credentials into the editor buffer and into the history.
- Security randomness with `java.security.SecureRandom`, never `rand`/`rand-int`.

## 6. Performance and operability

- **The JVM (GC, heap, flags, JFR, container) is `jvm-spring-standards` territory.** Here, what is Clojure-specific:
- **Concurrency — the map as of 2026**: `core.async` **1.9.865** is the stable line and already reimplements `go` blocks on top of **virtual threads** when Java 21+ is present (`clojure.core.async.vthreads` property: unset = opportunistic use; `target` = requires vthreads; `avoid` = falls back to the IOC transformation). The old rule still stands: **blocking I/O does not go inside a `go`** — that is what `io-thread` is for. `clojure.core.async.flow` (introduced in 2025) separates logic from execution and is today the recommended way to build topologies with core.async.
- Criteria: **core.async is not the default for "doing things in parallel"**. With virtual threads, a `future`/virtual executor + normal queues solves most I/O concurrency cases with far less conceptual complexity. core.async is justified when there are **channels, transducers, explicit backpressure or a process topology** (there, `flow`); using it as a replacement for a pool is accidental complexity. Watch out for `pmap` (fixed parallelism, chunked, bad for I/O) and for `future` over the unbounded `agent` pool.
- **Queues and bounded limits always**: channel buffers with a size (`chan 100`), never `(chan)` without a buffer used as an infinite queue nor `dropping-buffer` without a conscious decision; connection pools (HikariCP with next.jdbc) sized with data; timeouts in every HTTP/JDBC client.
- **Lazy by default = leaks and surprises**: a lazy sequence consumed outside the `with-open` gives "stream closed"; a lazy seq retained by the head eats the heap. Force with `doall`/`into`/`run!` inside the resource's scope, and use **transducers** (`into`, `transduce`, `sequence`) for pipelines without intermediate sequences.
- **Type hints and reflection**: enable `(set! *warn-on-reflection* true)` in namespaces with interop; reflection in a hot loop is orders of magnitude slower. Zero *reflection warnings* in the build is an achievable target.
- **Startup**: namespace loading dominates the startup of a Clojure service. AOT (`compile`) of the entrypoint and a release uberjar; for CLIs, **babashka** or GraalVM native-image (with the known restrictions: no dynamic `eval` and no code loading at runtime).
- **Observability**: structured logging (`mulog`, or `clojure.tools.logging` over SLF4J with a JSON appender) with request context and traceId; **`println` is forbidden** in service code. Serialise `ex-data` and the cause chain. OTel instrumentation per `observability-standards`.
- **Graceful shutdown mandatory**: a shutdown hook that runs `ig/halt!`/`component/stop` in reverse order (drain the HTTP server, close consumers, close pools) aligned with the orchestrator's grace period. A service that does not stop cleanly does not support rolling deploys.
- Separate health endpoints: trivial liveness, readiness that checks dependencies.

**Java interop and the exceptions that cross the boundary.**
- Interop is first class (`(.method obj)`, `Klass/staticMethod`, `(Klass. args)`), but **it is the point through which `null` and checked exceptions enter** a language that does not have them: Clojure does not force you to declare `throws`, so **any Java call can throw with nothing to indicate it** — including those that happen inside a lazy sequence and blow up far away, at realisation time, or on another thread.
- Rules: wrap the Java boundary in a Clojure function that catches and **translates to `ex-info`** with `:cause` and domain context; never let a Java library exception escape to the business layer. Every value coming from Java is treated as potentially `nil` on the very same line. Java resources always with `with-open` (and force the sequence inside it, see above). Do not catch `Throwable` to swallow it.

**ClojureScript — bounded.** ClojureScript (1.12.x) with **shadow-cljs** as the default build tool (solid npm interop and REPL) is the option for sharing logic and validations via `.cljc` between backend and frontend. All web frontend criteria (framework, bundling, UI performance, accessibility) are **not this skill's**. Differences that do matter here: there is no `ref`/`agent` and no STM, interop and errors are JavaScript's, and the Closure compiler's dead code elimination **penalises the use of dynamic `eval`/`resolve`** — another reason not to use them.

## 7. Sustainability: upgrades and prohibitions

**Cadence.** Clojure: bump to the stable version in the quarter after its release (the jumps are cheap); **plan the Java 17+ requirement of the 1.13 line ahead of time**. Dependencies reviewed with `antq` on a schedule; upgrading those that carry CVEs, immediately. Tools (clj-kondo, cljfmt, kaocha) always on their latest version: they are gates, not runtime.

**Deprecation.** `^:deprecated` metadata with a reason and a replacement in the docstring; an explicit window before removing a public function. Internal libraries publish to a repository of their own with a version; they are not consumed via `:local/root` across different repos.

**Conscious debt.** Every shortcut with `;; TODO(user): reason — link to issue`.

**FORBIDDEN** (exception only with written justification and approval):
- ❌ **`clojure.core/read-string` (or `read`) over untrusted input** — use `clojure.edn/read-string` with `:readers`/`:default`.
- ❌ **`eval`, `load-string`, `resolve`/`requiring-resolve` over external data**; "configurable rules" that evaluate code sent by the user.
- ❌ **nREPL (or any network REPL) in the production image/uberjar**; nREPL listening on `0.0.0.0` without TLS or authentication.
- ❌ `:git/url` dependencies without a full pinned `:git/sha`, or pointing at a branch; Git dependencies without justification and without your own update tracking.
- ❌ String interpolation to build SQL; dynamic identifiers without an allowlist.
- ❌ **A global atom as the application state store**; `defonce` holding service state instead of a system with a lifecycle; looking up dependencies in other namespaces' vars instead of injecting them.
- ❌ I/O or effects inside the function passed to `swap!` (it can retry); `ref`/STM with side effects inside `dosync`.
- ❌ Blocking I/O inside a `go` block; unbuffered channels used as work queues; `pmap` for I/O.
- ❌ `:refer :all` and `use`; `:require` without an alias; cycles between namespaces.
- ❌ `with-redefs` in concurrent tests or as a systematic substitute for dependency injection; tests that depend on order or on shared global state.
- ❌ Returning lazy sequences outside the scope of the resource that feeds them (`with-open` + lazy seq without forcing).
- ❌ `(throw (Exception. "..."))` instead of `ex-info` with data; catching `Throwable` and carrying on without a decision; secrets or PII inside `ex-data`.
- ❌ `println`/`prn` as logging in service code; printing the full system (with credentials) in the REPL or in logs.
- ❌ Declaring "fixed" having validated only in the live REPL session, without running in a clean process.
- ❌ Mixing `deps.edn` and Leiningen as dependency sources in the same project.
- ❌ Architecting on **spec 2 / `spec-alpha2`** (no release); mixing Malli and spec as edge validators in the same repo with no written rule.
- ❌ Reflection in hot paths with `*warn-on-reflection*` disabled; your own macros for what a function solves (macros do not compose and complicate debugging).
- ❌ CI without clj-kondo as a gate; a lint baseline without an expiry date; merging with CI red or flaky tests.

## 8. Mandatory web verification

Before pinning versions or asserting the state of the ecosystem, check online (not from memory):
1. **Clojure**: the current stable and the state of 1.13 (has the final shipped? does it confirm Java 17+ and spec leaving the core artifact?) — clojure.org/releases/downloads and clojure.org/news.
2. **Core tooling**: the version of the CLI/`tools.deps` and of `tools.build` (clojure.org/releases/tools). **Leiningen: releases and status at `codeberg.org/leiningen/leiningen`**, not on the GitHub mirror.
3. **core.async**: the latest stable versus the alpha line, and whether the guidance on virtual threads or `flow` has changed (clojure.org/news; repo releases). Cross-check against the JDK policy set by `jvm-spring-standards`.
4. **Malli vs spec**: the latest Malli, the state of `spec.alpha` and **whether `spec-alpha2` has finally published any release/tag** (as of Aug 2026, none).
5. **Quality**: clj-kondo (calendar versioning, moves fast), cljfmt, kaocha, eastwood, test.check — latest version **and licence**.
6. **Dependency security**: the maintenance status of **clj-holmes** (no releases since 2022/2023) and of **nvd-clojure**; check whether they have changed licence or been replaced before pinning them as a gate.
7. **Web and data stack**: ring, reitit, pedestal, next.jdbc, HoneySQL, Integrant/Component/mount — versions and advisories.
8. **CVEs** of the Java transitives in the tree (Jetty/undertow, Jackson, JDBC drivers, logging) in NVD before freezing versions.
9. **Declared gaps, not verified as of Aug 2026**: the exact final release date of Clojure 1.13; whether Leiningen has formally declared maintenance mode (only the hosting move to Codeberg was verified, not a status declaration); the exact core.async version in which `flow` stopped being alpha; the current status of the clj-holmes project (dormant, not declared archived).

If the web contradicts this document, **the web wins** — flag the discrepancy.
