---
name: python-standards
description: Use when writing, reviewing, or designing Python code or projects - .py files, pyproject.toml, uv, ruff, FastAPI, Django, SQLAlchemy, pydantic, asyncio, pytest, alembic, uvicorn, celery, Python packaging, virtualenvs, type hints, or Python CI/CD pipelines.
---

# Estándares Python (referencia: agosto 2026)

## 1. Alcance y triggers

Aplica a todo trabajo Python: código nuevo, revisión, diseño, refactor, packaging, CI y despliegue.
Triggers: `.py`, `pyproject.toml`, `uv.lock`, FastAPI, Django, SQLAlchemy, pydantic, asyncio, pytest, alembic.
Este documento fija **criterio** (qué usar, qué está vetado, qué verificar), no tutoriales.

**No aplica**: ver `api-design-standards` (diseño del contrato HTTP/GraphQL/gRPC: recursos, códigos,
paginación, RFC 9457, versionado — aquí solo su implementación en FastAPI/Django),
`microservices-architecture-standards` (corte de servicios, eventos, sagas, resiliencia distribuida),
`appsec-standards` (modelado de amenazas y clases de vulnerabilidad agnósticas del stack; aquí solo
los sinks y flags concretos de Python), `data-platform-standards` (modelado, índices, tuning y
réplicas de PostgreSQL; aquí solo el uso de SQLAlchemy/Alembic), `cicd-standards` (la pipeline que
ejecuta los gates de §4), `kubernetes-standards` (imagen OCI y despliegue del servicio),
`observability-standards` (pipeline OTel/Prometheus; aquí solo la instrumentación en el código),
`git-workflow-standards` (rama, commits y tagging SemVer del repo; la publicación en PyPI sí es de
esta skill), `bash-linux-scripting-standards` (scripts de sistema: si el script pasa de ~50 líneas o
necesita estructuras de datos, se reescribe en Python y vuelve aquí), `c-standards`/`cpp-standards`
y `rust-standards` (**extensiones nativas**: el empaquetado, las ruedas y la frontera de la API de
Python —`cffi`, `pybind11`, `PyO3`, la GIL y su liberación— son de aquí; el **código nativo que hay
al otro lado** —memoria, UB, sanitizers, flags del compilador— es suyo), `sql-standards` (el SQL que
SQLAlchemy genera o que escribes a mano en `text()`). **Elección de lenguaje** (la skill que manda
es la del lenguaje elegido, no ésta): `go-standards`, `rust-standards`, `typescript-standards`,
`jvm-spring-standards`, `dotnet-standards`, `php-standards`, `ruby-standards`,
`elixir-erlang-standards`, `scala-standards`, `clojure-standards`, `haskell-fp-standards`,
`ocaml-fsharp-standards`, `perl-standards` (**destino recíproco**: Python es el destino natural de
una reescritura de Perl, pero **reescribir un Perl que funciona y no tiene tests es cambiar un
riesgo conocido por uno desconocido** — la decisión de reescribir es suya, la calidad del Python
resultante es de aquí), `r-standards`, `julia-standards` — estas dos últimas para análisis
estadístico y computación numérica intensiva, donde Python **no** es automáticamente la respuesta.

## 2. Toolchain por defecto

> **Nota**: las versiones citadas son el estado verificado a 2026-08. **Antes de fijar versiones en un
> proyecto real, verifica la última estable por web** (sección 8). Nunca fijes versiones de memoria.

| Pieza | Elección | Mínimo | Por qué |
|---|---|---|---|
| Runtime | CPython | **3.12**; preferir 3.13/3.14 en greenfield | 3.14 estable desde 2025-10; Django 6 exige ≥3.12 |
| Gestor/entornos | **uv** (Astral) | 0.12+ | Estándar de facto: reemplaza pip, pip-tools, virtualenv, pyenv y pipx |
| Formatter | **ruff format** | 0.16+ | Sustituye a black; un solo binario con el linter |
| Linter | **ruff check** | 0.16+ | 400+ reglas por defecto desde 0.16; pin exacto en dev-deps |
| Type checker (gate CI) | **pyright** modo `strict` | — | Líder en conformidad con la spec (~98%). `ty` (Astral) sigue en beta (~53% conformidad): útil como LSP/editor, **no como gate de CI** todavía. mypy solo si el repo ya lo usa |
| Testing | **pytest** + pytest-asyncio + coverage | — | — |
| API async | **FastAPI** | 0.136+ | Framework Python más usado (JetBrains 2025) |
| Web "batteries included" | **Django** | **5.2 LTS** (soporte hasta 2028-04) o 6.0 si asumes cadencia anual | 4.2 LTS murió en 2026-04 |
| Validación/serialización | **pydantic v2** | 2.11+ | v3 NO publicada a 2026-08; no asumas API v3 |
| ORM SQL (no-Django) | **SQLAlchemy 2.0** estilo 2.0 (`Mapped[]`, `mapped_column`) | 2.0.50+ | 2.1 aún en beta; migrar cuando sea final |
| Migraciones | alembic (SQLAlchemy) / migrations nativas (Django) | — | — |
| Servidor ASGI | uvicorn (workers via systemd/k8s, no `--workers` improvisado) | — | — |
| Settings | pydantic-settings desde env vars | — | Config fuera del artefacto, 12-factor |

Comandos canónicos: `uv init` / `uv add` / `uv sync --locked` / `uv run` / `uvx`. Nunca `pip install` a mano dentro de un proyecto uv.
Versión de Python del proyecto fijada en `.python-version` y gestionada con `uv python install` — no dependas del Python del sistema.

**Criterio de modelo de concurrencia** (elige uno, no los mezcles sin frontera clara):
- I/O-bound con muchas conexiones → asyncio (FastAPI, asyncpg, httpx).
- I/O-bound simple o libs síncronas → threads (`ThreadPoolExecutor`) o workers síncronos; no fuerces async.
- CPU-bound → procesos (`ProcessPoolExecutor`) o task queue; free-threading (3.14, PEP 779) aún es opt-in
  experimental para prod: verifica soporte del ecosistema antes de usarlo.
- Django: síncrono por defecto sigue siendo válido; async solo donde haya beneficio medido.

**Criterio pydantic vs dataclasses**: pydantic en los bordes (parsing/validación de datos externos);
`dataclasses`/`attrs` (frozen por defecto) para tipos internos de dominio ya validados — no pagues
validación donde no hay datos no confiables.

## 3. Estructura y convenciones

- **Layout `src/`** obligatorio en paquetes: `src/<paquete>/`, `tests/` fuera del paquete.
- Un solo `pyproject.toml` como fuente de verdad: metadata, deps, `[dependency-groups]` (dev, test),
  config de ruff/pyright/pytest/coverage dentro. Cero `setup.py`, `setup.cfg`, `requirements.txt` (salvo export puntual para plataformas legacy: `uv export`).
- `uv.lock` **committeado siempre** (apps y también librerías para su CI).
- `requires-python = ">=3.12"` explícito; classifiers coherentes.
- Nombres: módulos `snake_case` cortos; sin `utils.py` cajón de sastre — módulos por dominio.
- FastAPI: routers por dominio (`app/<dominio>/router.py`, `schemas.py`, `service.py`, `models.py`),
  dependencias con `Depends` para sesión DB/auth/config; lifespan con `asynccontextmanager` (no `@app.on_event`, deprecado).
- Django: apps pequeñas y cohesivas; lógica en services/managers, no en views ni signals; settings partidos por entorno con env vars (django-environ o pydantic-settings), `DEBUG=False` por defecto.
- Separa esquemas de API (pydantic) de modelos de persistencia (SQLAlchemy/Django): nunca expongas el modelo ORM directamente en la API.
- **Diseño de API HTTP**: versionado en path (`/v1`), errores con formato RFC 9457 (problem+json) o uno propio
  consistente en toda la API, paginación obligatoria en colecciones (cursor para datasets grandes),
  `response_model` explícito en cada endpoint FastAPI (nunca devolver dicts sin schema).
- **Librerías publicables**: `uv build` + publicación desde CI con OIDC/attestations (PyPI Trusted Publishers),
  nunca con token estático en local; `__all__` explícito, `py.typed` incluido, SemVer y changelog.
- Transacciones: una sesión/transacción por request (dependency en FastAPI, `ATOMIC_REQUESTS` o
  `transaction.atomic` en Django); commit/rollback en un solo sitio, no repartido por los services.

## 4. Calidad: formato, lint, tipos, tests

- **Formato**: `ruff format` sin discusión de estilo; línea 100 o 120, elegir una y fijarla.
- **Lint**: `ruff check` con defaults 0.16+ y además `I` (isort), `B` (bugbear), `UP` (pyupgrade), `S` (bandit),
  `PTH` (pathlib), `RUF`. `noqa` siempre con código concreto y motivo.
- **Tipos**: `pyright` en `strict` para código nuevo; en legacy, `basic` + strict por directorios en avance.
  Anota todo el API público. `Any` es fallo salvo frontera justificada; usa `TypedDict`, `Protocol`, genéricos PEP 695, `Self`.
- **Tests** (pytest):
  - AAA, un motivo de fallo por test; nombres que describen comportamiento.
  - Cubrir camino feliz, **bordes y errores** (entradas inválidas, timeouts, conflictos de concurrencia, permisos).
  - FastAPI: `httpx.AsyncClient` + `ASGITransport` contra la app real; override de dependencias, no mocks del framework.
  - DB: tests de integración contra Postgres real (testcontainers o servicio de CI), no SQLite "porque es más rápido" si prod es Postgres.
  - Async: `pytest-asyncio` en modo `auto`; prohibido `time.sleep`/polling en tests — usa eventos o `anyio` fake clock.
  - Todo bugfix deja test de regresión. Flaky = se arregla o se borra.
- **Gates de CI** (todos bloquean el merge, en este orden — lo barato primero):
  1. `uv sync --locked` (falla si el lock está desactualizado)
  2. `ruff format --check` y `ruff check`
  3. `pyright` (strict en código nuevo)
  4. `pytest --cov` unit (rápidos) → integración (DB/servicios reales)
  5. `pip-audit` / SCA + build del paquete o imagen
  Umbral de cobertura acordado por equipo — la cobertura es señal, no meta. Main siempre verde.
- Pin exacto de ruff y pyright en dev-deps: sus updates cambian defaults y rompen CI si flotan (ruff 0.16 lo demostró).
- Pre-commit opcional pero recomendado (ruff format+check); CI es la autoridad, no el hook local.
- Mismo comando en local y en CI (`uv run pytest`, `uv run ruff check`): si CI hace algo que no puedes
  reproducir en local, es un bug del pipeline.

## 5. Seguridad del stack

- **Entradas**: valida TODO en el borde con pydantic (tipos estrictos, `Field` con límites, `max_length` en strings, límites de tamaño de payload). En Django, forms/serializers siempre; nunca `request.GET[...]` crudo a lógica.
- **SQL**: solo consultas parametrizadas (ORM o `text()` con bind params). Concatenar input en SQL/`os.system`/`subprocess(shell=True)` = veto absoluto.
- **Secretos**: env vars o gestor (Vault/KMS); jamás en código, `pyproject`, logs, ni fixtures. `SECRET_KEY` de Django rotable y por entorno.
- **AuthN/Z**: OAuth2/OIDC estándar; passwords con Argon2 (`argon2-cffi` / hasher Argon2 de Django). JWT: algoritmo fijado (RS256/EdDSA), expiración corta, verificación de `aud`/`iss`.
- **Deserialización**: prohibido `pickle`/`eval`/`exec`/`yaml.load` sin `SafeLoader` sobre datos externos.
- **SSRF**: al hacer fetch de URLs de usuario, allowlist de esquemas/hosts y bloqueo de rangos privados.
- **SCA**: `pip-audit` (o `uv`-compatible) + escaneo de imagen en CI como gate; dependencias con pin en lock, actualizadas con cadencia (sección 7). Señala deps abandonadas.
- **Django hardening**: `SECURE_*` settings, CSP (nativo en 6.0+ o django-csp), `ALLOWED_HOSTS` estricto, CSRF activo.
- **FastAPI hardening**: CORS con allowlist explícita (nunca `*` con credenciales), docs (`/docs`, `/openapi.json`) desactivadas o autenticadas en prod si la API es interna, rate limiting en el borde.
- **Errores**: nunca filtrar stack traces ni rutas internas al cliente; handler global que loguea con contexto y devuelve error neutro con correlation id.
- Contenedores: imagen slim/distroless, non-root, multi-stage con `uv sync --locked --no-dev`.

## 6. Rendimiento y operabilidad

- **Async con disciplina**: nada de I/O bloqueante en el event loop — drivers async (asyncpg, `httpx.AsyncClient`)
  o `run_in_threadpool`/`asyncio.to_thread` para lo síncrono. En FastAPI, un endpoint `async def` con llamada bloqueante dentro es un bug, no un detalle.
- **Timeouts en todo**: httpx con `timeout` explícito siempre (el default infinito de muchas libs es un incidente esperando); pool de DB con `pool_size`, `max_overflow`, `pool_timeout`, `pool_pre_ping`.
- Retries con backoff+jitter (tenacity) solo en operaciones idempotentes; circuit breaker en dependencias frágiles.
- **Graceful shutdown**: lifespan que cierra pools y drena tareas; el proceso respeta SIGTERM (uvicorn lo hace; no lo rompas con `os._exit`, threads no-daemon o tareas huérfanas — guarda referencias a tus `asyncio.create_task`).
- **Observabilidad**: logging estructurado JSON (structlog) con correlation id; OpenTelemetry (trazas+métricas) instrumentando ASGI, DB y HTTP client; endpoints `/healthz` (liveness) y `/readyz` (readiness con chequeo de deps). Sin telemetría no hay producción.
- ORM: prohibido el N+1 — `selectinload`/`joinedload` (SQLAlchemy), `select_related`/`prefetch_related` (Django); pagina siempre listados (limit por defecto y máximo).
- Trabajo pesado fuera del request: task queue (celery/arq/taskiq, o Tasks nativas de Django 6) — no `BackgroundTasks` de FastAPI para nada crítico o de larga duración.
- Perfilado antes de optimizar (`py-spy`, `cProfile`); nada de micro-optimización especulativa.
- Cache con criterio: TTL explícito y clave con versión de schema; invalidación diseñada, no "ya lo vaciamos a mano".
- Migraciones compatibles hacia atrás (*expand/contract*): nunca una migración que rompa la versión N-1
  del código en un rolling deploy; migraciones destructivas en release posterior.
- Logs: nivel INFO en prod, DEBUG activable por env; jamás datos personales/secretos en logs (revisa
  `repr` de modelos con campos sensibles — usa `SecretStr` de pydantic).

## 7. Sostenibilidad a largo plazo

- **Cadencia**: parches de seguridad inmediatos; minor de deps mensual/quincenal (Renovate/Dependabot con lock);
  CPython al año de su release (cuando el ecosistema alcanza); Django de LTS a LTS salvo necesidad de features.
- Presupuesto de mantenimiento en cada sprint; una dependencia sin release en >18 meses se revisa o se reemplaza.
- Deprecaciones propias: warning + changelog + ventana de retirada; los `DeprecationWarning` de terceros se tratan como deuda con issue, no se silencian.
- Deuda consciente: atajo = TODO con motivo e issue enlazada; prohibida la complejidad accidental silenciosa.

**Lista de prohibiciones (veto):**
- `pip install` / `requirements.txt` como fuente de verdad en proyecto nuevo (uv + `pyproject` + lock).
- Publicar/deployar sin lockfile o con deps sin pin.
- `except Exception: pass` o capturas que tragan errores sin log ni re-raise.
- Mutables como default de argumento; estado global mutable como "config".
- `pickle`/`eval`/`exec`/`yaml.load` inseguro sobre datos externos; `subprocess(shell=True)` con input.
- SQL por concatenación/f-string. MD5/SHA-1 para passwords; crypto casera.
- I/O bloqueante en código async; `asyncio.get_event_loop()` legacy (usa `asyncio.run`/loop en curso).
- Exponer modelos ORM directamente como schema de API.
- `# type: ignore` / `noqa` sin código de regla y sin motivo.
- Tests que dependen de orden, red pública o `sleep`; mocks del propio código bajo test.
- Modelos pydantic v1 (`class Config`, `.dict()`, `.parse_obj`) en código nuevo — API v2 (`model_config`, `model_dump`, `model_validate`).
- SQLAlchemy estilo 1.x (`Query`, `declarative_base` legacy) en código nuevo.
- `@app.on_event("startup")` en FastAPI (usa lifespan). Lógica de negocio en signals de Django.
- Versiones EOL: CPython <3.12 (nuevo), Django <5.2, Node… (ver skill TS). Nada de "ya lo subiremos".

## 8. Verificación web obligatoria

Antes de fijar versiones o APIs en un proyecto, **verifica online** (WebSearch/WebFetch):
1. Última estable y calendario EOL de: CPython (python.org/endoflife.date), Django (djangoproject.com — ¿salió 6.1? ¿nueva LTS?), FastAPI, pydantic (**¿ya salió v3?** A 2026-08 no), SQLAlchemy (**¿2.1 ya es final?** A 2026-08 en beta), uv y ruff (releases de astral-sh — ruff 0.16 cambió los defaults y rompe CI sin pin).
2. Estado de `ty` (Astral): si su conformidad ya lo hace apto como gate de CI, reevalúa pyright.
3. CVEs recientes del stack elegido (GitHub Advisories / osv.dev) antes de fijar una versión concreta.
4. Breaking changes del changelog oficial antes de cualquier upgrade mayor — no de memoria, ni de blogs de terceros sin contrastar con la fuente oficial.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
