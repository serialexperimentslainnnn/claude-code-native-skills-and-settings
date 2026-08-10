---
name: go-standards
description: Go engineering standards (staff-level). Trigger on any Go work - files with .go extension, go.mod/go.sum, Makefile targets invoking go build/test, golangci-lint config, or frameworks/routers like net/http, chi, gin, echo, gRPC, and libraries like errgroup or sqlc. Apply when writing, reviewing, refactoring, or configuring CI for Go code.
---

# Go standards

## 1. Scope and triggers

Applies to all Go work: `.go` files, `go.mod`/`go.sum`, `.golangci.yml`, `Dockerfile`s for Go services, CI pipelines that build/test Go. Covers backend services, CLIs and libraries. This skill fixes **criteria** (what to use, what is forbidden, what to verify); it is not a tutorial.

**Not applicable**: see `api-design-standards` (HTTP/gRPC contract design: resources, status codes, pagination, RFC 9457, versioning — here only its implementation with `net/http`/chi/gRPC), `microservices-architecture-standards` (service boundaries, events, sagas, distributed resilience), `appsec-standards` (threat modelling and stack-agnostic vulnerability classes; here only Go's concrete sinks and flags), `rust-standards` (the other systems-language skill: Go-vs-Rust chosen by workload, not by inertia), `data-platform-standards` (modelling, indexes and engine tuning; here only the use of `database/sql`/sqlc), `cicd-standards` (the pipeline that runs the gates), `kubernetes-standards` (OCI image, deployment and the production `Dockerfile`), `observability-standards` (OTel/Prometheus pipeline; here only the instrumentation in the code), `git-workflow-standards` (branch, commits and SemVer tagging, which in Go **is** the module publication mechanism), `bash-linux-scripting-standards` (system scripts), `c-standards` and `cpp-standards` (**the native
side of cgo**: the C code that gets compiled and its flags are theirs; the cgo boundary —call
cost, pointers that cross, `runtime.Pinner`— is ours, and the rule is still **avoid cgo
unless necessary**), `sql-standards` (the SQL that sqlc generates or that you write by hand), `webassembly-standards`
(`GOOS=wasip1` and TinyGo are their compilation targets, along with the runtime, the sandbox
limits and the artifact size; the Go that gets written is ours — and the warning both
share: **the Go runtime is heavy**, TinyGo exists because of that and is not full Go). **Language
choice** (the chosen language's skill wins): `python-standards`, `typescript-standards`,
`jvm-spring-standards`, `dotnet-standards`, `ruby-standards`, `elixir-erlang-standards`
(**the most relevant comparison for concurrent services**: Go gives cheap concurrency on a
single runtime; the BEAM gives per-process isolation and supervision — not the same thing), `scala-standards`,
`clojure-standards`, `haskell-fp-standards`, `ocaml-fsharp-standards`, `zig-standards`,
`nim-standards`, `crystal-standards` (all three compete with Go on "binary with no
dependencies" with far smaller ecosystems).

## 2. Default toolchain

> **Verify the latest version on the web before pinning it in a project** (go.dev/doc/devel/release). What follows is the state verified as of 2026-08-02.

- **Stable Go: 1.26.x** (1.26.5, 2026-07-07). Go 1.27 is in RC and ships in mid-August 2026; do not pin 1.27 until it is stable. Official support: only the last two majors (1.26 and 1.25) — never start a project on an unsupported version.
- `go.mod`: `go` directive with the full minor (`go 1.26.0`); use `toolchain` to pin the exact reproducible version in CI.
- **golangci-lint v2** (v2.12.x): config format `version: "2"`. v1 is obsolete; migrate with `golangci-lint migrate`.
- **Formatting**: `gofumpt` (strict superset of gofmt) via golangci-lint v2's `formatters` section, + `goimports` with the module's `local-prefixes`.
- **Vulnerabilities**: `govulncheck` (official, analyses real reachability by call graph, not just the dependency graph).
- Tool version management: `go tool` (Go ≥1.24) or the `tool` directive in go.mod — no hand-installed binaries without a pinned version.

## 3. Project structure and conventions

- **Minimal layout that grows**: start flat; `cmd/<binary>/main.go` when there is more than one binary, `internal/` for everything non-exportable (by default EVERYTHING goes in `internal/`, exporting is an explicit decision). `pkg/` only if there really is a public API consumed by third parties — not out of habit.
- Do not copy "golang-standards/project-layout" blindly: it is not an official standard. Valid reference: go.dev/doc/modules/layout.
- Packages by **domain/capability**, not by technical type (`user`, `billing`; never `models`, `utils`, `helpers`, `common`).
- Minimal `main.go`: parses config, builds dependencies (manual constructor injection — no DI frameworks), calls a testable `run(ctx, ...) error`.
- Config from env vars validated at startup (fail fast with a clear message), never read scattered across the code.
- Interfaces: **the consumer defines them**, small (1-3 methods), where they are used — not next to the implementation nor "just in case".
- Generics for reusable containers/algorithms; not for "future flexibility". When in doubt, concrete type.
- Reference layout for a service:

```
.
├── go.mod                  # go 1.26.0 + toolchain fijado
├── .golangci.yml           # version: "2"
├── cmd/api/main.go         # wiring mínimo, llama a internal/app.Run
├── internal/
│   ├── app/                # arranque: config, servidor, shutdown
│   ├── user/               # dominio: tipos, servicio, repo interface
│   ├── postgres/           # implementaciones de repos
│   └── httpapi/            # handlers, middleware, routing
└── Dockerfile              # multi-stage, distroless, non-root
```

## 4. Quality: formatting, lint, testing

### Error handling (non-negotiable)
- Every error is handled or propagated with context: `fmt.Errorf("opening config %s: %w", path, err)`. **Forbidden**: silent `_ = err`, and forbidden to log-and-return (duplicates noise: either you handle it or you propagate it).
- Sentinel errors (`var ErrNotFound = errors.New(...)`) or custom types for whatever the caller must distinguish; compare with `errors.Is`/`errors.As`, never with string matching.
- `panic` only for impossible programming invariants; never as flow control. HTTP/gRPC handlers carry recover middleware.

### Context
- `context.Context` as the first parameter of every function that does I/O, waits or can be cancelled. Never in structs, never `context.Background()` deep down (only in main/tests/root goroutine startup).
- Every `context.WithCancel/WithTimeout` with its `defer cancel()`. Context values only for cross-cutting request data (trace ID, auth), never business parameters.

### Concurrency
- Every launched goroutine has a **known owner and a known end**: who waits for it (errgroup/WaitGroup) and how it terminates (context). Forbidden: fire-and-forget `go func()` with no panic handling and no lifecycle.
- `golang.org/x/sync/errgroup` as the default primitive for fan-out with error propagation and cancellation.
- Share by communicating (channels) or protect with a mutex — chosen explicitly, not mixed. Shared mutable state without synchronisation = bug, even if it "works".
- Channels: the sender closes; buffer size justified (0 by default).

### Lint and CI (gates that break the build)
Recommended baseline: maratori's "golden config" (gist "Golden config for golangci-lint"), adapted — do not invent a config from scratch. Minimal v2 skeleton:

```yaml
version: "2"
linters:
  default: none
  enable:
    [errcheck, govet, staticcheck, unused, ineffassign, revive,
     gosec, errorlint, bodyclose, noctx, sqlclosecheck, rowserrcheck,
     copyloopvar, contextcheck, nilerr, unparam, gocritic, gocheckcompilerdirectives,
     musttag, testifylint, thelper, tparallel, usetesting]
  settings:
    govet: { enable: [shadow] }
formatters:
  enable: [gofumpt, goimports]
  settings:
    goimports: { local-prefixes: [github.com/org/modulo] }
```

`//nolint` always with a specific linter and a reason: `//nolint:gosec // G404: no criptográfico, jitter de retry`. Forbidden to disable linters repo-wide to dodge debt: it gets triaged and fixed.

### Testing
- **Table tests** as the default form; subtests with `t.Run(tt.name, ...)`; cases covering the happy path, **edges and errors** (empty input, nil, limits, cancelled contexts).
- `go test -race ./...` **always in CI** — a concurrent service without the race detector in CI is not tested.
- `t.Parallel()` on independent tests; `t.Cleanup` for resources; `testing/synctest` (stable in 1.25+) for deterministic tests of concurrent/time-dependent code instead of sleeps.
- Native fuzzing (`go test -fuzz`) on every parser/decoder of untrusted input; the corpus is versioned.
- `go-cmp` for deep comparisons with readable diffs. Mock boundaries (your own interfaces over I/O), not everything; prefer in-memory fakes over mock frameworks. Integration with real dependencies via `testcontainers-go` (Postgres, Kafka...) beats driver mocks.
- Every bugfix leaves a regression test that reproduces the bug before the fix.
- Minimum CI gate (everything breaks the build):

```
golangci-lint run            # incluye verificación de formato (formatters)
go build ./...
go test -race -shuffle=on -count=1 ./...
govulncheck ./...
```

Main always green; nothing merges with CI red.

## 5. Stack security

- **Secrets**: never in code, in flags visible in `ps`, or in logs. Env vars or a manager (Vault/KMS); wrapper types that redact in `String()`/`LogValue()` to avoid leaks through accidental logging.
- **SCA**: `govulncheck` in CI and scheduled (daily/weekly) — it catches new CVEs in already-frozen dependencies. `go.sum` always versioned; `GOFLAGS=-mod=readonly` in CI; explicit `GOPROXY`/`GONOSUMDB` in corporate environments.
- SQL only parameterised (`$1`/`?`); forbidden to concatenate input into queries, commands (`exec.Command` with separate args, never `sh -c` with input) or paths (validate against `filepath.Clean` + prefix).
- `html/template` (auto-escaping) for HTML, never `text/template` with user data.
- Crypto: stdlib only (`crypto/*`) — AES-GCM, ChaCha20-Poly1305, `crypto/rand` (never `math/rand` for tokens/nonces), `golang.org/x/crypto/argon2` or bcrypt for passwords. No home-made crypto.
- Containers: multi-stage, `CGO_ENABLED=0` where possible, final image distroless/scratch, **non-root**, read-only FS. Binary with `-trimpath` and `-ldflags="-s -w"` in release.
- HTTP server: the `net/http` defaults (no limits) are unacceptable in production. Baseline:

```go
srv := &http.Server{
    Addr: addr, Handler: mux,
    ReadHeaderTimeout: 5 * time.Second,
    ReadTimeout:       10 * time.Second,
    WriteTimeout:      30 * time.Second,
    IdleTimeout:       120 * time.Second,
    MaxHeaderBytes:    1 << 20,
}
```

  Limit the body with `http.MaxBytesReader`; tune the values to the service's SLO, do not leave them "because they were there".

## 6. Performance and operability

- **Router**: `net/http` with the standard ServeMux (methods + wildcards since 1.22) is the default; **chi** when middleware composition is needed while keeping `net/http` compatibility. Gin/Echo only if the team already operates them; Fiber (fasthttp, incompatible with net/http) requires written justification.
- **Logging**: structured `log/slog` (JSON in prod), with a correlated `TraceID`. Forbidden: `fmt.Println`/`log.Printf` in service code.
- **Observability**: OpenTelemetry for traces and metrics; separate `/healthz` (liveness) and `/readyz` (readiness with dependency checks); `expvar`/pprof enabled on an internal listener, never publicly exposed.
- **Timeouts and limits at every boundary**: your own `http.Client` with `Timeout` (the default is infinite — `http.DefaultClient` forbidden in production), dialer/TLS timeouts, `SetMaxOpenConns`/`SetMaxIdleConns`/`SetConnMaxLifetime` in `database/sql`. Retries with exponential backoff + jitter only on idempotent operations.
- **Graceful shutdown mandatory**: capture `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)`, `server.Shutdown(ctx)` with a deadline, drain workers via context, close resources in reverse order. A service that dies half-way through a `kill` corrupts state.
- Profile before optimising: `pprof` + benchmarks (`go test -bench -benchmem`) with `benchstat` to compare; do not micro-optimise without data. GC: `GOMEMLIMIT` in containers with a memory limit.

## 7. Sustainability: upgrades and prohibitions

**Cadence**: a Go minor every 6 months (Feb/Aug) — upgrade within the following quarter so you do not fall out of support; patches (`1.x.y`) applied within days (they are usually security). Dependencies: Dependabot/Renovate with weekly grouping; `go get -u ./... && go mod tidy` reviewed, never automerge of majors.

**Module API stability**: strict SemVer; a compatibility break requires a major (`/v2` in the module path). In libraries, every export is a contract — prefer not to export. Deprecate with `// Deprecated:` and a migration window before removing.

**Conscious debt**: every shortcut leaves a `// TODO(usuario): motivo — link a issue`; no silent accidental complexity. Review TODOs in every planning cycle.

**FORBIDDEN** (requires written justification and approval to make an exception):
- Ignoring errors (`_ = err`) or `panic` as flow control.
- Mutable global variables; `init()` with logic (trivial registration only).
- `interface{}`/`any` where a concrete type or a generic works; `reflect` outside serialisation boundaries.
- `unsafe`, `//go:linkname`: only with a comment justifying the invariants and a dedicated test.
- `time.Sleep` as synchronisation (in tests or production); polling where there is a signal.
- `http.DefaultClient`/`http.DefaultServeMux` in services; servers without timeouts.
- CGO without real need (breaks cross-compilation, static builds and deployment simplicity).
- Reflection-based DI frameworks (wire codegen is acceptable; dig/fx require justification).
- `math/rand` for any security use; MD5/SHA-1 except for documented legacy compatibility.
- Vendoring (`vendor/`) without a reason (air-gap, audit); heavy ORMs by default — prefer `database/sql` + `sqlc`/`pgx`; an ORM only by team decision.
- Merging with CI red, flaky tests ("fix it or delete it") or missing edge coverage in new code.

## 8. Mandatory web verification

Before pinning versions or asserting the state of the ecosystem in a real project, **verify on the web** (not from memory):
1. Stable Go version and support window: https://go.dev/doc/devel/release and https://endoflife.date/go
2. golangci-lint (version, new/deprecated linters): https://golangci-lint.run/docs/product/changelog/
3. Vulnerability advisories: https://pkg.go.dev/vuln/ and the real output of `govulncheck`.
4. Status of "new" features (e.g. json/v2, generics in methods): official release notes, not Medium articles.

Rule: if a datum in this skill contradicts what web verification returns, **the web wins** and this skill should be updated.
