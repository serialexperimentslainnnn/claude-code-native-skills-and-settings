---
name: rust-standards
description: Rust engineering standards (staff-level). Trigger on any Rust work - files with .rs extension, Cargo.toml/Cargo.lock, workspace manifests, clippy/rustfmt config, deny.toml, or crates/frameworks like tokio, axum, actix-web, serde, thiserror, anyhow, sqlx. Apply when writing, reviewing, refactoring, or configuring CI for Rust code.
---

# Estándares Rust

## 1. Alcance y triggers

Aplica a todo trabajo en Rust: ficheros `.rs`, `Cargo.toml`/`Cargo.lock`, `rustfmt.toml`, `clippy.toml`, `deny.toml`, `rust-toolchain.toml`, pipelines de CI que compilan/testean Rust. Cubre servicios backend, CLIs, librerías y workspaces multi-crate. Este skill fija **criterio** (qué usar, qué está prohibido, qué verificar); no es un tutorial.

**No aplica**: ver `api-design-standards` (diseño del contrato HTTP/gRPC — aquí solo su implementación con axum/tonic), `microservices-architecture-standards` (corte de servicios, eventos, sagas, resiliencia distribuida), `appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas del stack; aquí solo `unsafe`, FFI y los sinks concretos de Rust), `go-standards` (la otra skill de lenguaje de sistemas: elección Rust-vs-Go por workload, no por inercia), `c-standards` y `cpp-standards` (**frontera recíproca de FFI y de elección de lenguaje**: el lado C/C++ de la interfaz —cabeceras, `extern "C"`, ABI, ciclo de vida de lo que se cede al otro lado— es suyo; **el lado Rust —`unsafe`, `bindgen`/`cbindgen`, invariantes que el `unsafe` promete y `#[repr(C)]`— es de aquí**. Para código de sistemas **nuevo**, Rust es el default del catálogo; C y C++ cubren lo que ya existe, lo que exige un ABI concreto y lo que tiene requisito normativo —MISRA, CERT—), `haskell-fp-standards` y `ocaml-fsharp-standards` (**comparten con Rust el linaje ML**: ADTs, *pattern matching* exhaustivo, inferencia. La frontera no es "funcional": es el **modelo de memoria y el propósito** —aquí, control sin recolector de basura y despliegue como binario de sistemas; allí, expresividad del sistema de tipos con GC—. Si la discusión es *"¿tipos algebraicos o herencia?"* no es de nadie de estas tres en particular; si es *"¿quién libera esto y cuándo?"*, es de aquí), `zig-standards`, `nim-standards` y `crystal-standards` (**los tres nicho que compiten con Rust y lo citan como comparación obligada**; la frontera no es el rendimiento, es el **modelo de memoria y la madurez**: Zig, control manual sin runtime y **sin haber llegado a 1.0** —cada versión menor rompe—; Nim, GC configurable y metaprogramación; Crystal, GC y ergonomía tipo Ruby. Rust sigue siendo el default del catálogo para sistemas nuevo: elegir uno de los tres exige justificar ecosistema, contratación y estabilidad del lenguaje en un ADR), `ada-standards` (**la comparación obligada cuando la memoria segura tiene que ser además *certificable***: SPARK, sus niveles de adopción y la prueba formal son suyos, y su §7 arbitra Ada/SPARK frente a Rust —incluido el estado real de cualificación de **Ferrocene**— con los mismos datos que se usan aquí), `data-platform-standards` (modelado, índices y tuning del motor; aquí solo el uso de sqlx/SeaORM), `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards` (imagen OCI y despliegue), `observability-standards` (pipeline OTel; aquí solo `tracing` y la instrumentación en el código), `git-workflow-standards` (rama, commits y tagging SemVer; la publicación en crates.io sí es de esta skill), `cryptography-pki-standards` (elección de algoritmos y gestión de claves; aquí solo qué crates criptográficos usar y cuáles están sin mantenimiento), `assembly-standards` (`core::arch`, los intrínsecos y el `asm!` son frontera compartida — el criterio de **cuándo se justifica escribir ensamblador y cómo se mantiene** es suyo, incluidas las ABIs y el tiempo constante; el `unsafe` que lo rodea y sus invariantes, de aquí), `webassembly-standards` (Rust es el lenguaje de origen más habitual para Wasm y la frontera es limpia: **el código Rust, su build y sus tests son de aquí**; **el objetivo de compilación, el runtime, el modelo de componentes, los límites del sandbox y el tamaño del artefacto son suyos** — incluida la elección entre `wasm32-unknown-unknown`, `wasm32-wasip1` y `wasm32-wasip2`, y el nivel de soporte real de cada target).

## 2. Toolchain por defecto

> **Verificar la última versión por web antes de fijarla en un proyecto** (releases.rs / blog.rust-lang.org). Lo siguiente es el estado verificado a 2026-08-02.

- **Rust estable: 1.97.x** (1.97.1, 2026-07-16). Cadencia de 6 semanas; **solo el último stable recibe parches** — no hay LTS: quedarse atrás es quedarse sin fixes de seguridad.
- **Edición: 2024** (estabilizada en 1.85). Todo crate nuevo nace en `edition = "2024"`; migrar los existentes con `cargo fix --edition`. La próxima edición se espera ~2027.
- `rust-toolchain.toml` versionado con `channel = "1.97.1"` (o la stable vigente) para builds reproducibles; `rust-version` (MSRV) declarado en `Cargo.toml` de librerías.
- **Herramientas core**: `rustfmt` + `clippy` (componentes oficiales), **cargo-deny** (subsume a cargo-audit: advisories + licencias + bans + sources), `cargo-nextest` como runner de tests en CI, `taiki-e/install-action` para instalar tooling en GitHub Actions.
- **Runtime async: tokio 1.x** (1.52.x actual; líneas LTS 1.47/1.51 disponibles). No existe "tokio 2.0" pese a artículos que lo afirmen.
- **Web: axum 0.8** por defecto (equipo tokio, Tower, hyper). actix-web solo si el equipo ya lo opera o necesita su modelo de actores.

## 3. Estructura y convenciones de proyecto

- **Workspace desde el principio** en cualquier proyecto no trivial: `[workspace]` con `resolver = "3"`, crates en `crates/`, binarios finos que delegan en crates de librería.
- `[workspace.dependencies]` **obligatorio**: toda versión de dependencia se declara una vez en la raíz y los miembros usan `dep.workspace = true`. Igual con `[workspace.lints]` y `[workspace.package]` (edition, rust-version, license). Cero versiones duplicadas dispersas. Raíz de referencia:

```toml
[workspace]
resolver = "3"
members = ["crates/*"]

[workspace.package]
edition = "2024"
rust-version = "1.97"        # verificar stable vigente antes de fijar
license = "..."

[workspace.dependencies]
tokio = { version = "1", features = ["full"] }   # recortar features en cada crate
axum = "0.8"
thiserror = "2"
anyhow = "1"

[workspace.lints.clippy]
all = { level = "warn", priority = -1 }
pedantic = { level = "warn", priority = -1 }
unwrap_used = "deny"
dbg_macro = "deny"
todo = "deny"
undocumented_unsafe_blocks = "deny"

[profile.release]
lto = "thin"
codegen-units = 1
```
- `Cargo.lock` **versionado siempre**, también en librerías (recomendación oficial vigente).
- Módulos por dominio, no por tipo técnico; `mod.rs` no — ficheros con nombre del módulo (estilo 2018+). API pública mínima: `pub(crate)` por defecto, `pub` es decisión deliberada; `#![warn(missing_docs)]` en librerías publicadas.
- Newtypes sobre primitivos para IDs y unidades (`UserId(Uuid)`); estados imposibles irrepresentables (enums con datos > flags booleanos + Option). El type system es la primera línea de tests.

## 4. Calidad: formato, lint, testing

### Manejo de errores (criterio por capa)
- **Librerías / crates de dominio**: errores tipados con **`thiserror`** — enum por módulo/operación, variantes con contexto, `#[from]` para conversiones. El llamante debe poder hacer match.
- **Binarios / aplicaciones (capa top)**: **`anyhow`** (`anyhow::Result`, `.context("leyendo config {path}")`) donde el error solo se reporta, no se distingue.
- Regla: anyhow **nunca** en la API pública de una librería; thiserror en binarios solo si el binario necesita distinguir variantes.
- **Prohibido** `unwrap()`/`expect()` en código de producción salvo invariante demostrada con comentario (`// invariante: validado en construcción`); en tests son aceptables. `clippy::unwrap_used` activado como warn/deny en crates de producción.
- Los errores se propagan con `?`; prohibido `let _ = fallible()` que trague un `Result` (`#[must_use]` existe por algo).

### Formato y lint (gates que rompen build)
- `cargo fmt --check` en CI; `rustfmt.toml` mínimo (defaults + `imports_granularity` si el equipo lo acuerda) — no pelearse con el formatter.
- `cargo clippy --workspace --all-targets --all-features -- -D warnings` en CI. Lints en `[workspace.lints]`: `clippy::all`, `clippy::pedantic` como warn (triando excepciones), y como deny: `clippy::unwrap_used`, `clippy::dbg_macro`, `clippy::todo`, `clippy::undocumented_unsafe_blocks`.
- `#[allow]` siempre con lint específico y motivo en comentario; nunca `#[allow(clippy::all)]`.

### Async (tokio)
- Un solo runtime: tokio. Prohibido mezclar runtimes (async-std está descontinuado) o crear runtimes anidados.
- **Nunca bloquear el executor**: I/O síncrona, CPU-bound >~100µs o locks de `std::sync` mantenidos a través de `.await` van a `spawn_blocking` / `rayon`. Usar `tokio::sync::{Mutex, RwLock}` solo cuando el lock cruza un await; si no, `std::sync` o `parking_lot`.
- Toda task spawneada tiene dueño: `JoinSet`/`TaskTracker` + `CancellationToken` (tokio-util) para ciclo de vida; prohibido `tokio::spawn` fire-and-forget cuyo `JoinHandle` y errores nadie observa.
- Cancelación es siempre posible en async: código cancel-safe en `select!`; documentar cancel-safety de funciones propias que se usen en `select!`.
- Channels con límite (`mpsc::channel(n)` bounded) por defecto — backpressure explícita; `unbounded` requiere justificación.

### Unsafe — prohibido salvo justificación documentada
- `#![forbid(unsafe_code)]` en todo crate de aplicación y en librerías que no lo necesiten.
- Excepción solo por FFI o rendimiento **medido**: bloque mínimo, encapsulado en API segura, con `// SAFETY:` que demuestre las invariantes (lint `undocumented_unsafe_blocks` lo fuerza), test dedicado y **Miri** en CI para los crates con unsafe. Vigilar el unsafe heredado del árbol de deps con `cargo-geiger` cuando el perfil de riesgo lo exija.

### Testing
- Unit tests junto al código (`#[cfg(test)]`), integración en `tests/`, doctests en librerías (documentan y verifican a la vez).
- Cobertura de **bordes y errores**: variantes de error de cada API, entradas vacías/límite, cancelación de futures, timeouts.
- **Property testing** (`proptest`) para lógica con invariantes; **fuzzing** (`cargo-fuzz`) en todo parser/decoder de entrada no confiable, corpus versionado.
- Concurrencia: `tokio::test(start_paused = true)` para tiempo virtual determinista (nada de sleeps reales en tests); `loom` para primitivas de sincronización propias.
- Integración con deps reales vía `testcontainers` (Postgres, Redis...) mejor que mocks de driver; mockear fronteras propias (traits), no el mundo.
- Todo bugfix deja test de regresión que reproduce el bug antes del fix.
- Gate mínimo de CI (todo rompe el build):

```
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo nextest run --workspace
cargo test --doc --workspace
cargo doc --no-deps          # RUSTDOCFLAGS="-D warnings"
cargo deny check
```

Main siempre verde; no se mergea con CI roja. Test flaky: se arregla o se borra.

## 5. Seguridad del stack

- **Secretos**: nunca en código, `Cargo.toml`, logs ni `Debug` derivado — usar `secrecy::SecretString` (redacta en Debug/Display) para credenciales en structs de config. Env vars o gestor (Vault/KMS).
- **SCA / supply chain**: `cargo deny check` en cada PR **y programado** (diario) contra RustSec; `cargo-vet` cuando se requiera revisión humana de deps (perfil alto). `deny.toml` de partida (`cargo deny init` y endurecer):

```toml
[advisories]
yanked = "deny"                 # unmaintained/unsound se trian, no se ignoran a ciegas

[licenses]
allow = ["MIT", "Apache-2.0", "BSD-3-Clause", "ISC", "Unicode-3.0"]  # allowlist, no denylist

[bans]
multiple-versions = "warn"      # subir a deny cuando el árbol esté limpio
wildcards = "deny"

[sources]
unknown-registry = "deny"
unknown-git = "deny"
```
- Recordar el modelo de amenaza real: `build.rs` y proc-macros **ejecutan código arbitrario en build** con permisos del runner — cada dependencia nueva es una decisión de confianza, no un import gratis. Minimizar deps; preferir stdlib y crates del ecosistema núcleo (tokio/serde/tower).
- SQL solo parametrizado: `sqlx` (query checking) o diesel; prohibido formatear input en queries. Validación en los bordes con tipos (`serde` + validación en `TryFrom`/constructores, no structs "abiertos").
- Crypto: `ring`, `aws-lc-rs`, RustCrypto (AES-GCM, ChaCha20-Poly1305, SHA-256+, Argon2); `rustls` para TLS (no openssl salvo requisito). Aleatoriedad de seguridad con `rand::rngs::OsRng`/`getrandom`. Nada de crypto casera.
- Contenedores: build multi-stage, binario release (`opt-level = 3`, `lto = "thin"`, `codegen-units = 1`, `panic = "abort"` en binarios si no se necesita unwind), imagen distroless/scratch, **non-root**, FS read-only. `cargo auditable` para embeber el SBOM de deps en el binario.

## 6. Rendimiento y operabilidad

- **Logging/trazas**: `tracing` + `tracing-subscriber` (JSON en prod) con spans por request; OpenTelemetry (`tracing-opentelemetry`) para trazas distribuidas y métricas. Prohibido `println!`/`dbg!` en código de servicio (clippy lo veta).
- **Timeouts y límites en todo borde**: `reqwest`/`hyper` client con timeout explícito (el default sin timeout es inaceptable), `tower` layers para timeout/concurrency-limit/rate-limit en axum, límites de body (`DefaultBodyLimit`), pools de DB acotados (`sqlx::PoolOptions`: max_connections, acquire_timeout). Retries con backoff + jitter solo en idempotentes.
- **Graceful shutdown obligatorio**: `axum::serve(...).with_graceful_shutdown(señal SIGTERM/ctrl_c)`, `CancellationToken` propagado a workers, `TaskTracker::wait()` con deadline para drenar tasks, cerrar recursos en orden. Sin shutdown limpio no hay deploy rolling fiable.
- Health endpoints separados: liveness trivial y readiness que verifica deps.
- Perfilado antes de optimizar: `cargo flamegraph`, `criterion`/`divan` para benchmarks comparables; no micro-optimizar sin medir. `clone()` no es pecado hasta que el profiler lo diga — claridad primero, `Arc`/borrows donde el dato lo justifique.
- Builds: perfil `release` para prod siempre; caché de CI (sccache o `Swatinem/rust-cache`) para mantener pipelines <10 min.

## 7. Sostenibilidad: upgrades y prohibiciones

**Cadencia**: subir de stable en días tras cada release (6 semanas) — sin LTS, la versión vieja no recibe parches; point releases (1.x.y) inmediatos. Deps con Renovate/Dependabot agrupado semanal; majors revisados a mano con changelog. Edición nueva: migrar dentro del año siguiente a su estabilización. En librerías, la MSRV declarada es un contrato: subirla es al menos minor bump y se anota en changelog.

**Estabilidad de API**: SemVer estricto (con `cargo-semver-checks` en CI de librerías publicadas); seguir las Rust API Guidelines (C-*) en crates públicos. Deprecar con `#[deprecated(note = "...")]` y ventana de migración antes de eliminar.

**Deuda consciente**: todo atajo deja `// TODO(usuario): motivo — link a issue`; nada de complejidad accidental silenciosa. Revisar TODOs en cada ciclo de planificación.

**PROHIBIDO** (requiere justificación escrita y aprobación para excepcionar):
- `unsafe` sin `// SAFETY:` + encapsulación + Miri (ver §4); `unsafe` "por rendimiento" sin benchmark que lo demuestre.
- `unwrap()`/`expect()`/`panic!` como manejo de errores en producción; `todo!()`/`unimplemented!()` mergeados a main.
- `anyhow` en API pública de librería; errores como `String`/`Box<dyn Error>` en APIs tipables.
- Bloquear el executor async (I/O síncrona o CPU-bound en tasks); `std::sync::Mutex` mantenido a través de `.await`; `block_on` dentro de contexto async.
- Runtimes async distintos de tokio en el mismo árbol; channels unbounded sin justificar.
- `Cargo.lock` fuera del VCS; deps con `git = ...` sin `rev` fijado; wildcard versions (`*`); features `default` sin revisar en deps pesadas.
- Añadir dependencia para lo que hace la stdlib o un crate ya presente (left-pad-ismo); crates sin mantenimiento (RUSTSEC unmaintained) — cargo-deny los caza.
- `#[allow]` global de clippy; CI sin `-D warnings`; merge con CI rojo o tests flaky.
- MD5/SHA-1/DES/ECB, openssl vendored sin motivo, TLS <1.2.
- Macros procedurales propias para lo que resuelve un derive existente o código explícito (coste de compilación + opacidad).

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmar estado del ecosistema en un proyecto real, **verificar por web** (no de memoria):
1. Rust stable y edición vigente: https://releases.rs y https://blog.rust-lang.org (endoflife.date/rust como resumen).
2. Versiones de crates clave (tokio y sus líneas LTS, axum, serde, sqlx): crates.io / docs.rs — desconfiar de artículos que anuncien majors inexistentes ("tokio 2.0").
3. Advisories: https://rustsec.org y salida real de `cargo deny check advisories`.
4. Estado de features del lenguaje (¿estable, nightly?): The Rust Reference / release notes oficiales, no posts de terceros.

Regla: si un dato de este skill contradice lo que devuelve la verificación web, **manda la web** y conviene actualizar este skill.
