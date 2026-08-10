---
name: ruby-standards
description: Use when writing, reviewing or upgrading Ruby code and Rails applications - .rb/.rake/.gemspec/.erb files, Gemfile, Gemfile.lock, .ruby-version, Rakefile, config/application.rb, db/migrate, ActiveRecord models, Sidekiq or Solid Queue workers, RSpec spec/ or Minitest test/, .rubocop.yml, standardrb, Brakeman, bundler-audit, RBS sig/ or Sorbet sorbet/rbi, rbenv/mise/asdf Ruby toolchains, bundle exec, gem publishing to RubyGems, or Rails upgrades and YJIT/ZJIT tuning.
---

# Estándares Ruby y Rails

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a todo trabajo Ruby: aplicaciones Rails, gemas, scripts Ruby, Rakefiles, revisión y upgrade.
Triggers: `.rb`, `.rake`, `.gemspec`, `.erb`, `Gemfile`, `Gemfile.lock`, `.ruby-version`, `.rubocop.yml`,
`config/`, `app/models`, `db/migrate`, `spec/`, `test/`, `sig/`, `sorbet/`, `bundle`, `rails`, `gem`.
Fija **criterio** (qué usar, qué está vetado, qué verificar), no tutoriales.

**No aplica**: ver `api-design-standards` (el **contrato** de la API — recursos, códigos, paginación,
RFC 9457, versionado — es suyo; aquí solo su implementación en controllers y serializers),
`microservices-architecture-standards` (dónde se corta un servicio y cómo hablan entre sí; aquí solo
el Ruby de dentro), `kubernetes-standards` y `container-runtime-security-standards` (empaquetado OCI
y runtime del contenedor que ejecuta Puma), `cicd-standards` (la pipeline y sus gates; aquí solo qué
herramienta se ejecuta y con qué configuración), `secrets-management-standards` (dueño de la elección
de gestor de secretos y del escáner de secretos; aquí solo que Rails no los meta en el repo),
`appsec-standards` y `vulnerability-management-standards` (modelado de amenazas, proceso y triaje;
aquí el criterio de código y qué gate rompe el build), `sql-standards` (el lenguaje SQL en sí),
`data-platform-standards`, `mysql-mariadb-dba-standards`, `oracle-dba-standards` y
`sqlserver-dba-standards` (operación del motor: tuning, réplicas, backup, HA). Active Record decide
**cómo accede la aplicación**, no cómo se opera la base de datos.
`python-standards`, `go-standards`, `typescript-standards`, `jvm-spring-standards`, `rust-standards`,
`php-standards`, `elixir-erlang-standards` (elección de lenguaje e implementación en cada uno);
frente a **`elixir-erlang-standards`** en particular: comparten origen sintáctico y buena parte de la
comunidad, pero **no** el modelo de ejecución — la frontera es la BEAM (procesos, supervisión,
distribución) frente a la VM de CRuby (GVL, procesos OS, Puma/Sidekiq).
`bash-linux-scripting-standards` (automatización de sistema: si el script Ruby de operaciones es un
pegamento de comandos, es suyo; si necesita estructuras de datos y tests, vuelve aquí),
`iac-standards` (el **DSL de infraestructura** de Chef/Puppet/Vagrant es de `iac-standards` aunque
esté escrito en Ruby; el **Ruby que se escribe** dentro — librerías, custom resources, tests — es de
esta skill), `observability-standards` (estrategia y pipeline de telemetría; aquí la instrumentación
en el código), `message-brokers-standards` (Kafka/RabbitMQ como infraestructura; aquí el consumidor
Ruby y la cola de jobs), `crystal-standards` (frontera nombrada porque la
confusión es real: **la compatibilidad de Crystal con Ruby es de sintaxis, no de semántica ni de
librerías**. No hay gemas, ni `method_missing` en tiempo de ejecución, ni monkey patching dinámico:
un fichero Ruby no se porta cambiándole la extensión. Si el motivo para migrar es el rendimiento,
mídelo primero con YJIT), `smalltalk-standards` (**linaje directo**: el modelo de objetos y de
mensajes de Ruby viene de ahí; el Smalltalk vivo —Pharo, Squeak, GemStone/S, VAST— es suyo).

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Pieza | Elección | Mínimo | Por qué |
|---|---|---|---|
| Runtime | **CRuby (MRI)** | **3.4** en mantenimiento; **4.0** en greenfield | 4.0 salió 2025-12-25 (4.0.6 a 2026-07); 3.4 EOL 2028-03-31, 3.3 EOL 2027-03-31 |
| Gestor de versiones | **mise** (o `rbenv` si el equipo ya lo usa) | — | `asdf` válido si ya gestiona otros runtimes; **nunca** el Ruby del sistema |
| Fijación de versión | `.ruby-version` + `ruby "x.y.z"` en `Gemfile` | — | Una sola fuente de verdad, leída por el gestor y por Bundler |
| Dependencias | **Bundler** + `Gemfile.lock` committeado | — | `bundle install --frozen` / `BUNDLE_FROZEN=true` en CI |
| Framework web | **Rails 8.1** | 8.0 mínimo | 8.1 salió 2025-10-22, EOL 2027-10-10; 7.2 EOL 2026-08-09; 8.1 exige Ruby ≥3.2 |
| Linter/formatter | **RuboCop 1.88+** con `rubocop-rails`, `rubocop-rspec`, `rubocop-performance` | — | MIT. Alternativa: `standard` (config cerrada) |
| SAST | **Brakeman 8.x** | — | ⚠️ **NO es MIT**: "Brakeman Public Use License" (Synopsys) — uso comercial requiere licencia de pago (§7) |
| SCA | `bundler-audit` (ruby-advisory-db) + Dependabot/Renovate | 0.9.3+ | GPL-3.0-or-later |
| Tests | **RSpec 3.13** o **Minitest 6** (criterio abajo) | — | RSpec 4 solo en beta a 2026-08 (`4.0.0.beta1`, feb-2026): **no** en producción |
| Migraciones seguras | **strong_migrations** | 2.8+ | Bloquea DDL que toma locks largos |
| Jobs | **Solid Queue** (default Rails 8) o **Sidekiq 8** | — | Solid Queue 1.6+; Sidekiq es **LGPL-3.0**, verifica encaje legal |
| Tipado gradual | **RBS 4 + Steep 2** o **Sorbet** (criterio abajo) | — | Ninguno es obligatorio; adoptar solo con presupuesto de mantenimiento |
| Servidor | **Puma** | — | Workers y threads dimensionados, no por defecto |

**Política de versión de Ruby**: una minor de Ruby por año, dentro de los 6 meses de su release.
Ruby ≤3.2 está EOL (3.2 murió 2026-03-31) → **no se despliega**, no se "sube más adelante".
Rails: de release a release soportado; una app en Rails con soporte vencido es un incidente de
seguridad abierto, no deuda técnica.

**JIT**: **YJIT** es la opción de producción (madura desde Ruby 3.2, desplegada a escala en Shopify,
Discourse, Mastodon; ganancias reales del 15-25 % en apps Rails, mucho menores si el cuello es la
base de datos o una API externa). **ZJIT** (Ruby 4.0, escrito en Rust, `--zjit`) es **experimental**:
las propias notas de Ruby 4.0 lo describen como más rápido que el intérprete pero **más lento que
YJIT** → prohibido en producción hasta que la fuente oficial diga lo contrario. Activa YJIT de forma
explícita (`--yjit` / `RUBY_YJIT_ENABLE=1`) y **mide antes y después**; verifica en §8 si alguna
versión ya lo activa por defecto. YJIT consume memoria extra: acota con `--yjit-mem-size`.

**RSpec vs Minitest — criterio, no bando**:
- **Minitest** si: es una gema, el equipo es pequeño, quieres cero DSL y el default de Rails.
- **RSpec** si: la app es grande, el equipo ya lo domina, y aprovechas `shared_examples` y matchers
  de dominio. El coste es el DSL: `let` anidado y `subject` implícito producen tests ilegibles.
- **Elegir uno por repo**. Dos frameworks de test conviviendo es deuda, no flexibilidad.

**Tipado gradual — estado real a 2026-08 y criterio**:
- **RBS** (oficial del core team, ships con Ruby) 4.1.x + **Steep** 2.0: firmas en ficheros `.rbs`
  separados, tipado estructural. Ventaja: es el estándar del lenguaje. Coste: tooling de editor peor
  y firmas que se desincronizan del código.
- **Sorbet** (Stripe/Shopify, Apache-2.0, releases continuos — `0.6.x` con versionado por build):
  anotaciones `sig` inline + `.rbi`, tipado nominal, chequeo también en runtime. Ventaja: tooling
  más pulido y la mayor base de adopción industrial. Coste: sintaxis invasiva en el código Ruby.
- **Ninguno es el default del ecosistema**. Adopta tipos solo si hay dominio con invariantes que los
  tests no cubren bien y **presupuesto continuo** para mantener las firmas. Un experimento publicado
  midió que subir cobertura de tests encontró más bugs que el tipado gradual: si tienes que elegir
  con recursos limitados, primero los tests.
- Si adoptas: uno solo, gate en CI (`steep check` o `srb tc`), y `sig`/`sig/` obligatorios en el API
  público. Tipado a medias sin gate no sirve de nada.

## 3. Estructura y convenciones

- **Convención sobre configuración**: en Rails, respeta el layout estándar. Reubicar directorios o
  inventar autoloading propio rompe Zeitwerk y no aporta nada.
- Rails moderno = **Rails 8 defaults**: Propshaft (no Sprockets), Solid Queue / Solid Cache /
  Solid Cable, Kamal 2 para deploy, Importmap o jsbundling según el front. En apps existentes la
  migración a la pila "Solid" es **opcional e incremental** — no es un requisito para estar al día.
- `app/models` no es el vertedero de la lógica. Objetos de dominio en `app/services`,
  `app/queries`, `app/policies`, `app/forms`; el modelo persiste y valida, no orquesta.
- **Callbacks de Active Record**: fuente número uno de acoplamiento oculto. Veta `after_save` que
  llame a servicios externos, envíe correo o encole jobs sin control transaccional. Lo que dispara
  efectos va en un service object explícito, invocado desde el caso de uso.
- **`default_scope`: prohibido**. Contamina toda consulta, sorprende en `unscoped`, rompe
  `create`/`update` y hace ilegible cualquier depuración. Usa scopes con nombre.
- **`Concern` con estado**: un `ActiveSupport::Concern` que añade callbacks y atributos a la clase
  incluyente es herencia disfrazada. Concerns solo para comportamiento sin estado compartido.
- Migraciones y `schema.rb`/`structure.sql` committeados; una única fuente de verdad del esquema.
  Si usas features de PostgreSQL que `schema.rb` no representa (tipos, funciones, triggers,
  constraints de exclusión), cambia a `structure.sql` — no "casi funciona".
- **Gema vs monolito**: extrae una gema solo cuando hay ≥2 consumidores reales y un dueño. Una gema
  interna con un consumidor es un monolito con un salto de repo, versión y CI de más. Dentro del
  monolito, usa módulos/engines con fronteras explícitas antes de partirlo.
- Gemas publicables: `.gemspec` con `required_ruby_version`, `metadata["rubygems_mfa_required"] =
  "true"`, SemVer, changelog, y publicación desde CI con **Trusted Publishing (OIDC)** — nunca con
  API key de larga vida en un secret ni `gem push` desde el portátil.
- `Gemfile`: sin versión → prohibido en producción. Restricción por `~>` en gemas, exacta en el lock.
  Sin `git:` ni `path:` apuntando a ramas en la rama principal.
- **Política de dependencias**: cada gema nueva se justifica (¿qué resuelve que no resuelve stdlib o
  Rails?), se comprueba mantenimiento (último release, issues abiertas, número de mantenedores) y
  licencia. Una gema sin release en >18 meses se revisa o se sustituye.

## 4. Calidad y testing

- **Formato y lint**: `rubocop` con `NewCops: enable` y las extensiones `rubocop-rails`,
  `rubocop-rspec`/`rubocop-minitest`, `rubocop-performance`. Pin **exacto** de la versión de RuboCop
  en el `Gemfile`: cada minor añade cops y rompe CI si flota.
  - Cops obligatorios (no desactivar): departamento `Security` completo (`Security/Eval`,
    `Security/Open`, `Security/YAMLLoad`, `Security/MarshalLoad`, `Security/JSONLoad`),
    `Lint/*` (en especial `Lint/SuppressedException`, `Lint/ShadowedException`), `Rails/SaveBang`,
    `Rails/OutputSafety`, `Rails/SkipsModelValidations`, `Rails/UniqueValidationWithoutIndex`,
    `Rails/HasManyOrHasOneDependent`, `Rails/Output`, `Rails/TimeZone`.
  - Discutibles y ajustables por equipo: `Metrics/*`, `Style/*`. Fija los valores una vez en
    `.rubocop.yml` y deja de discutirlos.
  - `rubocop:disable` **siempre** con cop concreto y motivo en la misma línea. `.rubocop_todo.yml`
    es una lista de deuda con fecha de caducidad, no un archivo permanente.
- **`standard` (standardrb)** como alternativa: cuando el equipo pierde más tiempo discutiendo
  `.rubocop.yml` que escribiendo código. Es RuboCop con configuración cerrada. Renuncias a los cops
  de dominio (Rails, RSpec) salvo que añadas sus plugins. Si necesitas reglas propias, es RuboCop.
- **Tests**:
  - AAA, un motivo de fallo por test, nombres que describen comportamiento observable.
  - Camino feliz **y bordes y errores**: entrada inválida, registro inexistente, permisos denegados,
    condiciones de carrera, timeouts de servicios externos, validaciones de unicidad bajo concurrencia.
  - **Prohibida la lógica en los tests**: nada de `if`/`each`/cálculos que reconstruyan el resultado
    esperado. Valor literal esperado o el test no prueba nada.
  - **`factory_bot`**: factories mínimas (solo lo obligatorio), `build`/`build_stubbed` por defecto y
    `create` solo cuando hace falta la DB. Traits para variantes; prohibidas factories que crean
    árboles de asociaciones "por si acaso" — son el motivo habitual de una suite lenta.
  - **Fixtures**: válidas y rápidas para datos de referencia estables (países, planes, roles). Como
    base de todos los tests de dominio se convierten en acoplamiento global; no las mezcles con
    factories para lo mismo.
  - Tests de sistema (Capybara) los justos: caros y frágiles. Pirámide, no reloj de arena.
  - Prohibido `sleep` en tests, dependencia del orden y llamadas a red pública (`webmock`/`vcr` con
    cassettes revisadas y sin secretos dentro).
  - Todo bug arreglado deja test de regresión. Flaky = se arregla o se borra.
- **Gates de CI** (bloquean merge, de barato a caro):
  1. `bundle install --frozen` / `bundle exec bundler-audit check --update`
  2. `rubocop --parallel` (o `standardrb`)
  3. `brakeman --no-pager -q -w2` (falla con hallazgos de confianza alta/media)
  4. `steep check` / `srb tc` si el repo adoptó tipos
  5. `rspec`/`rails test` unitarios → integración con la **misma** base de datos que producción
  6. Auditoría de migraciones (`strong_migrations`) y build de imagen
- Rails 8.1 trae `bin/ci` para ejecutar en local la misma secuencia: úsalo, pero **CI es la
  autoridad**, no el hook local. Si CI hace algo irreproducible en local, es un bug del pipeline.
- Cobertura (`simplecov`) como señal, no como meta; umbral acordado, sin trucos para subirlo.

## 5. Seguridad del stack

- **Deserialización — el sink histórico de Ruby**:
  - ❌ `YAML.load`, `YAML.load_file`, `Psych.load` sobre entrada no confiable. Usa
    `YAML.safe_load` con `permitted_classes` explícito. (Psych 4+ hace `load` seguro por defecto,
    pero **no** dependas de la versión: escribe `safe_load` y deja el cop `Security/YAMLLoad` activo.)
  - ❌ `Marshal.load` sobre cualquier dato que venga de fuera del proceso. Nunca, sin excepción.
  - ❌ `JSON.load` (usa `JSON.parse`), `ERB` con plantilla controlable por el usuario. Precedente
    reciente: CVE-2026-41316, bypass del guard de deserialización de `ERB` vía
    `def_module`/`def_method`/`def_class` — verifica el aviso en §8.
  - ❌ Cookies de sesión con `Marshal` como serializador: usa `:json`.
- **Ejecución dinámica**: ❌ `eval`, `instance_eval`, `class_eval`, `binding.eval` con datos de
  usuario. ❌ `send`/`public_send`/`constantize`/`safe_constantize` con un nombre que venga del
  request — si necesitas despacho dinámico, allowlist explícita de símbolos permitidos.
  ❌ `system`, backticks, `Kernel#open`, `%x{}` con interpolación de input.
- **Mass assignment**: strong parameters siempre (`params.require(...).permit(...)`). ❌ `permit!`.
  ❌ `permit` incluyendo `:role`, `:admin`, `:user_id` o cualquier campo de autorización.
- **Inyección SQL**: solo consultas parametrizadas (hash conditions o `where("x = ?", v)`). ❌
  interpolación de strings en `where`, `order`, `pluck`, `find_by_sql`, `joins`. `order` con un
  parámetro del usuario requiere allowlist de columnas — es el vector clásico y el ORM no te protege.
- **XSS**: ERB escapa por defecto; ❌ `html_safe`, `raw` y `sanitize` sobre contenido de usuario sin
  allowlist estricta. Cop `Rails/OutputSafety` activo. CSP configurada (`content_security_policy` en
  Rails), no permisiva por comodidad.
- **CSRF**: `protect_from_forgery` con la estrategia por defecto (`:exception`), nunca `:null_session`
  en endpoints con sesión. ❌ `skip_before_action :verify_authenticity_token` global; si un endpoint
  de API lo necesita, es porque debería autenticar con token y no con cookie de sesión.
- **Autorización**: en **cada** acción, no solo en el `before_action` genérico. Pundit/Action Policy
  con default deny y test que verifica que ninguna acción queda sin política. IDOR se previene
  consultando siempre desde el ámbito del usuario (`current_user.orders.find(params[:id])`), nunca
  `Order.find(params[:id])`.
- **Secretos**: `config/credentials.yml.enc` es aceptable para apps pequeñas si `master.key` **no**
  está en el repo y se inyecta por entorno; en organización, gestor externo (ver
  `secrets-management-standards`). ❌ secretos en `config/*.yml` planos, en logs o en fixtures.
  `filter_parameters` cubriendo password, token, secret, y los campos de dominio sensibles.
- **SAST**: Brakeman como gate. ⚠️ Su licencia **no es OSS**: "Brakeman Public Use License" de
  Synopsys — analizar tu propio software no es "uso comercial", pero distribuirlo o incluirlo en un
  servicio de pago sí requiere licencia comercial. Verifica el texto vigente antes de meterlo en un
  producto (§8).
- **SCA y cadena de suministro** — RubyGems ha sido escenario de ataques reales y recientes:
  - 2026-05: inundación masiva de cuentas y gemas maliciosas que forzó a RubyGems.org a **suspender
    temporalmente el registro de cuentas nuevas**; ninguna tenía CVE y la reputación del mantenedor
    era inútil (cuentas recién creadas).
  - 2026-04/05: campaña atribuida a "BufferZoneCorp", gemas suplantando nombres conocidos
    (`activesupport-logger`, `devise-jwt`) dirigidas a **runners de CI** para robar credenciales.
  - 2026-06: 14 gemas usadas como *dead drop* de datos exfiltrados por una extensión de navegador.
  - 2026-07: campaña "SleeperGem" (`git_credential_manager`, `Dendreo`) con payload de segunda etapa.
  - Consecuencias operativas, no opcionales: **`bundler-audit` como gate**; lockfile committeado y
    `--frozen` en CI; revisión humana de **toda gema nueva** (nombre exacto, mantenedor, downloads,
    fecha del primer release); `bundle config set --local disable_platform_warnings` no sustituye a
    leer el diff del `Gemfile.lock` en la PR; **el CI no expone secretos a la instalación de
    dependencias** (`bundle install` en un job sin credenciales de nube ni `GITHUB_TOKEN` de escritura).
  - Un `gemspec` puede ejecutar código en `bundle install` (extensiones nativas, hooks de build):
    asume que instalar una gema es **ejecutar código de un tercero** y aísla el job en consecuencia.
  - Considera *cooldown* de versiones nuevas (retrasar la adopción de un release recién publicado);
    varias herramientas y mirrors ya lo ofrecen — verifica cuál aplica a tu registro (§8).
- **Publicación**: Trusted Publishing (OIDC) desde GitHub Actions con `id-token: write` y environment
  protegido; `rubygems_mfa_required` en el gemspec. La MFA obligatoria de RubyGems.org solo cubre las
  gemas más descargadas: no asumas que tu gema está protegida por política del registro.
- **Errores**: nunca stack trace ni ruta interna al cliente; `config.consider_all_requests_local =
  false` en producción, página de error neutra con correlation id.

## 6. Rendimiento y operabilidad

- **N+1 es un bug, no una optimización pendiente**: `includes`/`preload`/`eager_load` según el caso
  (`includes` decide solo; `preload` fuerza dos consultas; `eager_load` fuerza el JOIN). Detección
  automática en el entorno de test/desarrollo (`bullet` o `strict_loading` de Rails) y **fallo del
  test**, no un log que nadie lee. `strict_loading` por defecto en modelos nuevos.
- Pagina **siempre** las colecciones (límite por defecto y máximo). `find_each`/`in_batches` para
  recorridos masivos; ❌ `.all.each` sobre una tabla de producción.
- **Migraciones seguras** (`strong_migrations`): nada de añadir columna con default no volátil en
  motores antiguos, índices sin `algorithm: :concurrently` en PostgreSQL, `change_column` que
  reescribe la tabla, ni renombrar/eliminar columnas en la misma release que el código que las usa.
  Patrón **expand/contract** obligatorio: la migración debe ser compatible con la versión N-1 del
  código durante todo el rolling deploy. Las destructivas van en una release posterior.
- **Jobs**: `ActiveJob` como interfaz, backend explícito. **Solid Queue** (default de Rails 8, usa
  `FOR UPDATE SKIP LOCKED`, no requiere Redis) es la opción por defecto en greenfield; **Sidekiq 8**
  si ya está, si necesitas su ecosistema, o por rendimiento medido — con la advertencia de licencia
  **LGPL-3.0** de Sidekiq OSS. Reglas comunes:
  - Argumentos serializables y **pequeños**: pasa IDs, no objetos ni payloads.
  - **Idempotencia obligatoria**: todo job se reintenta; si reintentarlo cobra dos veces, es un bug.
  - Encolar **después** del commit (`after_commit`), nunca dentro de la transacción: el worker puede
    coger el job antes de que la fila exista.
  - Timeouts y límite de reintentos explícitos; cola de fallos (dead set) monitorizada.
  - Colas separadas por latencia (crítica / por defecto / lenta), no por equipo.
  - Jobs largos: Rails 8.1 aporta **Active Job Continuations** (dividir en pasos reanudables) —
    relevante porque un deploy con Kamal da al contenedor de jobs una ventana corta de apagado.
- **Caché**: Solid Cache (default Rails 8, respaldada en base de datos) o Redis/Valkey si ya existe.
  Clave con versión de esquema, TTL explícito, invalidación diseñada. Russian doll caching en vistas
  solo si hay medición detrás. ❌ caché sin TTL "que ya limpiaremos a mano".
- **Puma**: `WEB_CONCURRENCY` (procesos) y threads dimensionados contra el pool de Active Record —
  `pool` ≥ threads por proceso, o verás timeouts de checkout bajo carga. La GVL hace que los threads
  solo ayuden en I/O; el paralelismo real de CPU son procesos.
- **Timeouts en todo**: cliente HTTP (`open_timeout` y `read_timeout` explícitos — muchos clientes
  Ruby no tienen default), `statement_timeout` en PostgreSQL, `rack-timeout` o equivalente en el
  borde. Retries con backoff+jitter solo en operaciones idempotentes.
- **Observabilidad**: logs estructurados con `request_id`; `ActiveSupport::Notifications` /
  Rails 8.1 Structured Event Reporting como fuente de eventos; OpenTelemetry para trazas y métricas.
  Endpoints de liveness/readiness (`rails/health` de serie, amplíalo con chequeo de dependencias).
  ❌ datos personales o secretos en logs.
- **Memoria**: CRuby fragmenta; vigila RSS por worker y reinicia workers con límite si hace falta
  (`puma_worker_killer` es un parche, no un diagnóstico). Perfila con `stackprof`/`memory_profiler`
  antes de optimizar; nada de micro-optimización especulativa.
- Apagado ordenado: SIGTERM drena requests y jobs en vuelo; no lo rompas con `exit!` ni hilos
  huérfanos.

## 7. Sostenibilidad a largo plazo

- **Cadencia**: parches de seguridad de inmediato; minors de gemas con Renovate/Dependabot y lock;
  Ruby una minor al año; Rails de release soportado a release soportado. Un upgrade grande es más
  barato en pasos pequeños y frecuentes que en un proyecto de seis meses cada tres años.
- Presupuesto de mantenimiento en cada sprint. Las deprecaciones de Rails (`ActiveSupport::Deprecation`)
  se resuelven en la release en curso, no se silencian.
- `.rubocop_todo.yml` con fecha; deuda consciente = TODO con motivo e issue enlazada.
- Rails 8.1 permite marcar asociaciones `deprecated: true` (`:warn`/`:raise`/`:notify`): úsalo para
  retirar relaciones muertas de forma medible en vez de "buscar usos con grep".

**Lista de prohibiciones (veto):**
- ❌ Desplegar en una versión EOL de Ruby (≤3.2 a 2026-08) o de Rails sin soporte.
- ❌ `YAML.load` / `Marshal.load` / `JSON.load` sobre entrada no confiable. **PROHIBIDO** sin excepción.
- ❌ `eval`/`instance_eval`/`class_eval`/`send`/`public_send`/`constantize` con datos del usuario.
- ❌ `system`/backticks/`Kernel#open` con interpolación de input.
- ❌ SQL por interpolación de strings en `where`, `order`, `pluck`, `joins`, `find_by_sql`.
- ❌ `permit!`, o permitir en strong parameters campos de rol/propiedad.
- ❌ `skip_before_action :verify_authenticity_token` global; `protect_from_forgery with: :null_session`
  en rutas con sesión.
- ❌ `html_safe`/`raw` sobre contenido de usuario.
- ❌ `default_scope`. ❌ callbacks de Active Record con efectos externos (correo, HTTP, jobs).
- ❌ `update_column`/`update_all`/`save(validate: false)` para saltarse validaciones sin motivo escrito.
- ❌ `rescue => e` que traga la excepción sin log ni re-raise; `rescue Exception`.
- ❌ Monkey patching de gemas o del core en la app (usa refinements o un fork con issue upstream).
- ❌ Gemas sin versión en el `Gemfile`; desplegar sin `Gemfile.lock`; `bundle update` sin revisar diff.
- ❌ Instalar dependencias en un job de CI que tenga credenciales de producción a mano.
- ❌ Tests con lógica, con `sleep`, dependientes del orden o que llaman a red pública.
- ❌ ZJIT en producción (experimental a 2026-08, más lento que YJIT según las notas oficiales).
- ❌ Migración destructiva en la misma release que el código que deja de usar la columna.
- ❌ Encolar jobs dentro de la transacción que crea los datos que el job necesita.
- ❌ Extraer una gema interna con un solo consumidor.
- ❌ Asumir que Brakeman o Sidekiq son MIT: verifica su licencia antes de meterlos en un producto.

## 8. Verificación web obligatoria

Antes de fijar versiones o afirmaciones en un proyecto, **verifica online**:
1. **Ruby**: última estable y calendario EOL (`endoflife.date/ruby`, ruby-lang.org/en/downloads).
   ¿Sigue 4.0 como serie actual? ¿Ha salido 4.1? ¿3.3 ya está EOL (previsto 2027-03-31)?
2. **Rails**: versión con soporte (`endoflife.date/rails`, rubyonrails.org). 7.2 EOL 2026-08-09 y
   8.0 EOL 2026-11-07 → comprueba si ya pasaron. ¿Rails 9?
3. **JIT**: ¿ZJIT ya alcanza o supera a YJIT y se recomienda en producción? ¿YJIT se activa por
   defecto en alguna versión? Fuente: notas de release oficiales de ruby-lang.org, no blogs.
4. **Tipado**: estado de RBS/Steep y de Sorbet — ¿alguno se ha vuelto default del ecosistema o ha
   entrado tipado en el compilador de Ruby? A 2026-08 ninguno es obligatorio.
5. **Herramientas**: RuboCop (¿2.0?), RSpec (¿4.0 final ya, o sigue en beta?), Minitest, Brakeman,
   bundler-audit, strong_migrations, Solid Queue, Sidekiq. Fija versión exacta de RuboCop.
6. **Licencias**: Brakeman (Synopsys, no OSS), Sidekiq (LGPL-3.0), bundler-audit (GPL-3.0-or-later),
   y cualquier herramienta que vayas a fijar como default. Precedentes recientes de cambios de
   licencia que rompieron pipelines: **Trivy** y **gitleaks** (su acción exige licencia comercial
   para organizaciones desde v2). Comprueba el fichero `LICENSE` en crudo, no la etiqueta del README.
7. **Seguridad**: avisos de ruby-lang.org y GitHub Advisories / osv.dev para Ruby, Rails y las gemas
   del `Gemfile.lock` antes de fijar versiones. Verifica en concreto los CVE citados aquí
   (CVE-2026-41316 en ERB, CVE-2026-46727 en getaddrinfo) y si hay posteriores.
8. **RubyGems**: estado del registro tras los incidentes de 2026 (¿nuevas políticas de MFA, cooldown
   de versiones, firma de gemas?), y si RubyGems.org sigue con restricciones operativas.

**Huecos declarados (no verificados a ago-2026)**:
- Si YJIT pasa a estar activo por defecto en alguna versión de Ruby 4.x: **no verificado**.
- Cobertura exacta de la política de MFA obligatoria de RubyGems.org en 2026 (el umbral por
  descargas parece seguir vigente, pero no se localizó anuncio oficial actualizado): **no verificado**.
- Disponibilidad de firma de gemas tipo Sigstore de forma general en RubyGems.org: **no verificado**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
