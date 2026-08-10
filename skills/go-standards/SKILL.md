---
name: go-standards
description: Go engineering standards (staff-level). Trigger on any Go work - files with .go extension, go.mod/go.sum, Makefile targets invoking go build/test, golangci-lint config, or frameworks/routers like net/http, chi, gin, echo, gRPC, and libraries like errgroup or sqlc. Apply when writing, reviewing, refactoring, or configuring CI for Go code.
---

# Estándares Go

## 1. Alcance y triggers

Aplica a todo trabajo en Go: ficheros `.go`, `go.mod`/`go.sum`, `.golangci.yml`, `Dockerfile` de servicios Go, pipelines de CI que compilan/testean Go. Cubre servicios backend, CLIs y librerías. Este skill fija **criterio** (qué usar, qué está prohibido, qué verificar); no es un tutorial.

**No aplica**: ver `api-design-standards` (diseño del contrato HTTP/gRPC: recursos, códigos, paginación, RFC 9457, versionado — aquí solo su implementación con `net/http`/chi/gRPC), `microservices-architecture-standards` (corte de servicios, eventos, sagas, resiliencia distribuida), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas del stack; aquí solo los sinks y flags concretos de Go), `rust-standards` (la otra skill de lenguaje de sistemas: elección Go-vs-Rust por workload, no por inercia), `data-platform-standards` (modelado, índices y tuning del motor; aquí solo el uso de `database/sql`/sqlc), `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards` (imagen OCI, despliegue y el `Dockerfile` de producción), `observability-standards` (pipeline OTel/Prometheus; aquí solo la instrumentación en el código), `git-workflow-standards` (rama, commits y tagging SemVer, que en Go **es** el mecanismo de publicación del módulo), `bash-linux-scripting-standards` (scripts de sistema), `c-standards` y `cpp-standards` (**el lado
nativo de cgo**: el código C que se compila y sus flags son suyos; la frontera cgo —coste de la
llamada, punteros que cruzan, `runtime.Pinner`— es de aquí, y la regla sigue siendo **evitar cgo
salvo necesidad**), `sql-standards` (el SQL que sqlc genera o que escribes a mano), `webassembly-standards`
(`GOOS=wasip1` y TinyGo son objetivos de compilación suyos, junto con el runtime, los límites del
sandbox y el tamaño del artefacto; el Go que se escribe es de aquí — y el aviso que ambas
comparten: **el runtime de Go pesa**, TinyGo existe por eso y no es Go completo). **Elección de
lenguaje** (manda la skill del lenguaje elegido): `python-standards`, `typescript-standards`,
`jvm-spring-standards`, `dotnet-standards`, `ruby-standards`, `elixir-erlang-standards`
(**la comparación más relevante para servicios concurrentes**: Go da concurrencia barata sobre un
runtime único; la BEAM da aislamiento por proceso y supervisión — no es lo mismo), `scala-standards`,
`clojure-standards`, `haskell-fp-standards`, `ocaml-fsharp-standards`, `zig-standards`,
`nim-standards`, `crystal-standards` (las tres compiten con Go en "binario sin
dependencias" con ecosistemas mucho menores).

## 2. Toolchain por defecto

> **Verificar la última versión por web antes de fijarla en un proyecto** (go.dev/doc/devel/release). Lo siguiente es el estado verificado a 2026-08-02.

- **Go estable: 1.26.x** (1.26.5, 2026-07-07). Go 1.27 está en RC y sale a mediados de agosto de 2026; no fijar 1.27 hasta que sea estable. Soporte oficial: solo las dos últimas majors (1.26 y 1.25) — nunca arrancar proyecto en una versión fuera de soporte.
- `go.mod`: directiva `go` con la minor completa (`go 1.26.0`); usar `toolchain` para fijar la versión exacta reproducible en CI.
- **golangci-lint v2** (v2.12.x): formato de config `version: "2"`. v1 está obsoleto; migrar con `golangci-lint migrate`.
- **Formato**: `gofumpt` (superset estricto de gofmt) vía la sección `formatters` de golangci-lint v2, + `goimports` con `local-prefixes` del módulo.
- **Vulnerabilidades**: `govulncheck` (oficial, analiza alcance real por call graph, no solo el grafo de deps).
- Gestión de versiones de herramientas: `go tool` (Go ≥1.24) o directiva `tool` en go.mod — no binarios instalados a mano sin versión fijada.

## 3. Estructura y convenciones de proyecto

- **Layout mínimo que crece**: empezar plano; `cmd/<binario>/main.go` cuando hay más de un binario, `internal/` para todo lo no exportable (por defecto TODO va en `internal/`, exportar es decisión explícita). `pkg/` solo si de verdad hay API pública consumida por terceros — no por costumbre.
- No copiar "golang-standards/project-layout" a ciegas: no es estándar oficial. Referencia válida: go.dev/doc/modules/layout.
- Paquetes por **dominio/capacidad**, no por tipo técnico (`user`, `billing`; nunca `models`, `utils`, `helpers`, `common`).
- `main.go` mínimo: parsea config, construye dependencias (inyección manual por constructor — no frameworks de DI), llama a un `run(ctx, ...) error` testeable.
- Config por env vars con validación al arranque (fallar rápido con mensaje claro), nunca leídas dispersas por el código.
- Interfaces: **las define el consumidor**, pequeñas (1-3 métodos), donde se usan — no junto a la implementación ni "por si acaso".
- Generics para contenedores/algoritmos reutilizables; no para "flexibilidad futura". Ante la duda, tipo concreto.
- Layout de referencia para un servicio:

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

## 4. Calidad: formato, lint, testing

### Manejo de errores (innegociable)
- Todo error se maneja o se propaga con contexto: `fmt.Errorf("opening config %s: %w", path, err)`. **Prohibido** `_ = err` silencioso y prohibido loggear-y-devolver (duplica ruido: o manejas o propagas).
- Errores sentinel (`var ErrNotFound = errors.New(...)`) o tipos propios para lo que el llamante deba distinguir; comparar con `errors.Is`/`errors.As`, nunca con string matching.
- `panic` solo para invariantes de programación imposibles; nunca como control de flujo. Los handlers HTTP/gRPC llevan recover middleware.

### Context
- `context.Context` primer parámetro de toda función que hace I/O, espera o puede cancelarse. Nunca en structs, nunca `context.Background()` en profundidad (solo en main/tests/arranque de goroutine raíz).
- Todo `context.WithCancel/WithTimeout` con su `defer cancel()`. Valores en context solo para datos transversales de request (trace ID, auth), nunca parámetros de negocio.

### Concurrencia
- Toda goroutine lanzada tiene **dueño y final conocidos**: quién la espera (errgroup/WaitGroup) y cómo termina (context). Prohibido `go func()` fire-and-forget sin gestión de pánico ni ciclo de vida.
- `golang.org/x/sync/errgroup` como primitiva por defecto para fan-out con propagación de error y cancelación.
- Compartir por comunicación (channels) o proteger con mutex — elegido explícitamente, no mezclado. Estado mutable compartido sin sincronización = bug, aunque "funcione".
- Channels: el emisor cierra; tamaño de buffer justificado (0 por defecto).

### Lint y CI (gates que rompen build)
Base recomendada: la "golden config" de maratori (gist "Golden config for golangci-lint"), adaptada — no inventar config desde cero. Esqueleto mínimo v2:

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

`//nolint` siempre con linter específico y motivo: `//nolint:gosec // G404: no criptográfico, jitter de retry`. Prohibido desactivar linters a nivel de repo para esquivar deuda: se tria y se arregla.

### Testing
- **Table tests** como forma por defecto; subtests con `t.Run(tt.name, ...)`; casos que cubran camino feliz, **bordes y errores** (entrada vacía, nil, límites, contextos cancelados).
- `go test -race ./...` **siempre en CI** — un servicio concurrente sin race detector en CI no está testeado.
- `t.Parallel()` en tests independientes; `t.Cleanup` para recursos; `testing/synctest` (estable en 1.25+) para tests deterministas de código concurrente/temporal en lugar de sleeps.
- Fuzzing nativo (`go test -fuzz`) en todo parser/decoder de entrada no confiable; el corpus se versiona.
- `go-cmp` para comparaciones profundas con diffs legibles. Mockear fronteras (interfaces propias sobre I/O), no todo; preferir fakes en memoria a frameworks de mocks. Integración con deps reales vía `testcontainers-go` (Postgres, Kafka...) mejor que mocks de driver.
- Todo bugfix deja test de regresión que reproduce el bug antes del fix.
- Gate de CI mínimo (todo rompe el build):

```
golangci-lint run            # incluye verificación de formato (formatters)
go build ./...
go test -race -shuffle=on -count=1 ./...
govulncheck ./...
```

Main siempre verde; no se mergea con CI roja.

## 5. Seguridad del stack

- **Secretos**: nunca en código, flags visibles en `ps`, ni logs. Env vars o gestor (Vault/KMS); tipos wrapper que redactan en `String()`/`LogValue()` para evitar fugas por logging accidental.
- **SCA**: `govulncheck` en CI y programado (diario/semanal) — detecta CVEs nuevos en deps ya congeladas. `go.sum` versionado siempre; `GOFLAGS=-mod=readonly` en CI; `GOPROXY`/`GONOSUMDB` explícitos en entornos corporativos.
- SQL solo parametrizado (`$1`/`?`); prohibida concatenación de input en queries, comandos (`exec.Command` con args separados, jamás `sh -c` con input) o rutas (validar contra `filepath.Clean` + prefijo).
- `html/template` (auto-escaping) para HTML, jamás `text/template` con datos de usuario.
- Crypto: solo stdlib (`crypto/*`) — AES-GCM, ChaCha20-Poly1305, `crypto/rand` (nunca `math/rand` para tokens/nonces), `golang.org/x/crypto/argon2` o bcrypt para passwords. Nada de crypto casera.
- Contenedores: multi-stage, `CGO_ENABLED=0` cuando sea posible, imagen final distroless/scratch, **non-root**, FS read-only. Binario con `-trimpath` y `-ldflags="-s -w"` en release.
- HTTP server: los defaults de `net/http` (sin límites) son inaceptables en producción. Baseline:

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

  Limitar body con `http.MaxBytesReader`; ajustar valores al SLO del servicio, no dejarlos "porque estaban".

## 6. Rendimiento y operabilidad

- **Router**: `net/http` con el ServeMux estándar (métodos + wildcards desde 1.22) es el default; **chi** cuando se necesite composición de middleware manteniendo compatibilidad `net/http`. Gin/Echo solo si el equipo ya los opera; Fiber (fasthttp, incompatible con net/http) requiere justificación escrita.
- **Logging**: `log/slog` estructurado (JSON en prod), con `TraceID` correlado. Prohibido `fmt.Println`/`log.Printf` en código de servicio.
- **Observabilidad**: OpenTelemetry para trazas y métricas; `/healthz` (liveness) y `/readyz` (readiness con chequeo de deps) separados; `expvar`/pprof habilitado en listener interno, jamás expuesto públicamente.
- **Timeouts y límites en todo borde**: `http.Client` propio con `Timeout` (el default es infinito — prohibido `http.DefaultClient` en producción), timeouts de dialer/TLS, `SetMaxOpenConns`/`SetMaxIdleConns`/`SetConnMaxLifetime` en `database/sql`. Retries con backoff exponencial + jitter solo en operaciones idempotentes.
- **Graceful shutdown obligatorio**: capturar `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)`, `server.Shutdown(ctx)` con deadline, drenar workers vía context, cerrar recursos en orden inverso. Un servicio que muere con `kill` a medias corrompe estado.
- Perfilado antes de optimizar: `pprof` + benchmarks (`go test -bench -benchmem`) con `benchstat` para comparar; no micro-optimizar sin dato. GC: `GOMEMLIMIT` en contenedores con límite de memoria.

## 7. Sostenibilidad: upgrades y prohibiciones

**Cadencia**: minor de Go cada 6 meses (feb/ago) — actualizar dentro del trimestre siguiente al release para no caer fuera de soporte; patches (`1.x.y`) aplicar en días (suelen ser seguridad). Deps: Dependabot/Renovate con agrupación semanal; `go get -u ./... && go mod tidy` revisado, nunca automerge de majors.

**Estabilidad de API de módulos**: SemVer estricto; ruptura de compatibilidad exige major (`/v2` en module path). En librerías, cada export es un contrato — preferir no exportar. Deprecar con `// Deprecated:` y ventana de migración antes de eliminar.

**Deuda consciente**: todo atajo deja `// TODO(usuario): motivo — link a issue`; nada de complejidad accidental silenciosa. Revisar TODOs en cada ciclo de planificación.

**PROHIBIDO** (requiere justificación escrita y aprobación para excepcionar):
- Ignorar errores (`_ = err`) o `panic` como control de flujo.
- Variables globales mutables; `init()` con lógica (solo registro trivial).
- `interface{}`/`any` donde un tipo concreto o generic sirve; `reflect` fuera de fronteras de serialización.
- `unsafe`, `//go:linkname`: solo con comentario que justifique invariantes y test dedicado.
- `time.Sleep` como sincronización (en tests o producción); polling donde hay señal.
- `http.DefaultClient`/`http.DefaultServeMux` en servicios; servers sin timeouts.
- CGO sin necesidad real (rompe cross-compile, builds estáticos y simplicidad de despliegue).
- Frameworks de DI por reflexión (wire codegen es aceptable; dig/fx requieren justificación).
- `math/rand` para cualquier uso de seguridad; MD5/SHA-1 salvo compatibilidad legacy documentada.
- Vendorizar (`vendor/`) sin motivo (air-gap, auditoría); ORMs pesados por defecto — preferir `database/sql` + `sqlc`/`pgx`; ORM solo por decisión de equipo.
- Merge con CI rojo, tests flaky ("se arregla o se borra") o cobertura de bordes ausente en código nuevo.

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmar estado del ecosistema en un proyecto real, **verificar por web** (no de memoria):
1. Versión estable de Go y ventana de soporte: https://go.dev/doc/devel/release y https://endoflife.date/go
2. golangci-lint (versión, linters nuevos/deprecados): https://golangci-lint.run/docs/product/changelog/
3. Advisories de vulnerabilidades: https://pkg.go.dev/vuln/ y salida real de `govulncheck`.
4. Estado de features "nuevas" (p. ej. json/v2, generics en métodos): release notes oficiales, no artículos de Medium.

Regla: si un dato de este skill contradice lo que devuelve la verificación web, **manda la web** y conviene actualizar este skill.
