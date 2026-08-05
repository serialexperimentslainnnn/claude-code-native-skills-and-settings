---
name: php-standards
description: PHP engineering standards (modern PHP, Laravel, Symfony). Use when working with .php files, composer.json/composer.lock, artisan commands, phpunit.xml, phpstan.neon, psalm.xml, Blade/Twig templates, or any Laravel/Symfony project task (code, review, refactor, tests, CI).
---

# Estándares PHP (moderno, Laravel, Symfony)

## 1. Alcance y triggers

Aplica a todo trabajo sobre código PHP: ficheros `.php`, `composer.json`/`composer.lock`,
comandos `artisan`/`bin/console`, plantillas Blade/Twig, configuración de PHPStan/Psalm/PHPUnit/Pest,
pipelines CI de proyectos PHP. Cubre escribir, revisar, refactorizar y testear.

**No aplica**: ver `api-design-standards` (diseño del contrato HTTP/GraphQL — aquí solo su
implementación en Laravel/Symfony), `appsec-standards` (modelado de amenazas y clases de
vulnerabilidad agnósticas del stack; aquí solo los sinks y flags concretos de PHP),
`microservices-architecture-standards` (corte de servicios, eventos, colas distribuidas, sagas),
`data-platform-standards` (modelado, índices y tuning del motor; aquí solo Eloquent/Doctrine y sus
migraciones), `cicd-standards` (la pipeline que ejecuta los gates), `kubernetes-standards` (imagen
OCI, PHP-FPM en contenedor y despliegue), `onprem-standards` (el servidor web/PHP-FPM en host y su
hardening), `observability-standards` (pipeline OTel; aquí solo la instrumentación),
`git-workflow-standards` (rama, commits y tagging SemVer; la publicación en Packagist sí es de esta
skill), `identity-access-management-standards` (diseño del IdP; aquí solo cómo lo consume la app),
`sql-standards` (**Ola 5**: el SQL que Doctrine o Eloquent generan, y el que se escribe a mano).
**Elección de lenguaje** (manda la skill del lenguaje elegido): `python-standards`,
`typescript-standards`, `go-standards`, `jvm-spring-standards`, `dotnet-standards`,
`ruby-standards` (**la comparación más directa**: Laravel y Rails ocupan el mismo hueco; la
elección es de equipo y ecosistema, no de rendimiento), `elixir-erlang-standards`.

**Regla cero**: detecta primero el contexto del proyecto (`composer.json` → versión PHP, framework,
herramientas ya presentes) y respeta sus convenciones. Estos estándares fijan el criterio para
código nuevo y para señalar deuda; no reescribas lo existente fuera del alcance pedido.

## 2. Toolchain por defecto

> **Nota de verificación**: versiones comprobadas vía web el 2026-08-02 (php.net, laravel.com,
> symfony.com/releases, phpstan.org, pestphp.com). Antes de fijar una versión en un proyecto,
> **verifica en la web el estado actual** — este documento caduca.

- **PHP**: proyectos nuevos en **PHP 8.5** (actual, EOL 2029-12-31) o **8.4** (activa, EOL 2028-12-31).
  8.3 y 8.2 están en *security-only* (EOL 2027-12-31 y 2026-12-31); solo mantenimiento, no proyectos nuevos.
  ≤8.1 es EOL: tratarlo como incidencia de seguridad, no como preferencia.
- **Laravel**: **Laravel 13** (marzo 2026, requiere PHP ≥8.3). No existen releases LTS: cada major
  recibe 18 meses de bugfixes y 2 años de seguridad — planifica el upgrade anual.
- **Symfony**: **7.4 LTS** (soportada hasta nov. 2029) para productos de vida larga;
  **8.x** (actual 8.1, requiere PHP ≥8.4) si se asume la cadencia semestral de upgrades.
- **Composer**: 2.x siempre. `composer.lock` versionado en aplicaciones; en librerías no se versiona
  pero se prueba contra `--prefer-lowest` y latest en CI.
- **Testing**: **Pest 5** (sobre PHPUnit 13) por defecto en proyectos nuevos; **PHPUnit** puro es
  igual de válido si el proyecto ya lo usa. No mezclar estilos en el mismo suite.
- **Análisis estático**: **PHPStan 2.x** con `level: max` (hoy nivel 10) + `phpstan-strict-rules`
  (+ Larastan en Laravel, phpstan-symfony en Symfony). Psalm (`errorLevel="1"`) como alternativa
  si el proyecto ya lo usa; uno de los dos es obligatorio, no opcional.
- **Estilo**: PSR-12 (y PER Coding Style) con **PHP-CS-Fixer** o **Laravel Pint** (proyectos Laravel).
- **Auxiliares**: Rector para upgrades automatizados; `composer audit` para SCA.

## 3. Estructura y convenciones

- **`declare(strict_types=1);`** obligatorio en TODO fichero PHP nuevo, primera sentencia. En código
  legado sin él, señálalo; actívalo solo con cobertura de tests que respalde el cambio.
- **Tipos explícitos en todo**: parámetros, retornos (incl. `void`/`never`), propiedades tipadas.
  Nada de `mixed` salvo frontera real (deserialización, reflection) y siempre estrechado de inmediato.
- **Inmutabilidad por defecto**: `readonly` en propiedades y clases DTO/VO, `final` por defecto en
  clases no diseñadas para herencia, enums (`enum`) en lugar de constantes de clase sueltas,
  promoted constructor properties.
- PSR-4 para autoloading (`src/` → `App\` o vendor namespace); un tipo por fichero; nombres
  reveladores (`StudlyCaps` clases, `camelCase` métodos, `SCREAMING_SNAKE` constantes).
- **Laravel**: convenciones del framework primero — Form Requests para validación, Eloquent con
  casts/relaciones tipadas, colas para trabajo diferido, `config()` solo desde ficheros de config
  (nunca `env()` fuera de `config/`), políticas para autorización. Lógica de dominio fuera de
  controladores (acciones/servicios); controladores finos.
- **Symfony**: inyección por constructor con autowiring, servicios privados por defecto, atributos
  PHP (`#[Route]`, `#[AsMessageHandler]`) sobre YAML para lo local al código, Messenger para
  asincronía, `symfony/validator` en los bordes.
- Errores: excepciones específicas del dominio, nunca `@` ni catch vacío; `try/finally` o
  equivalentes para liberar recursos. Sin estados a medias.

## 4. Calidad: formato, lint, análisis estático, testing

Gates en CI, todos bloqueantes — no se mergea con alguno en rojo:

1. **Formato**: Pint (`pint --test`) o PHP-CS-Fixer (`--dry-run --diff`) contra PSR-12/PER.
2. **Estático**: `phpstan analyse --level=max` (o `psalm --show-info=false` a nivel 1) sin errores.
   - Baseline (`phpstan-baseline.neon`) solo para adoptar en legado: se congela y **solo decrece**;
     prohibido añadir entradas nuevas al baseline.
   - `@phpstan-ignore` puntual exige comentario con motivo; sin motivo, es un error a corregir.
3. **Tests**: `pest` / `phpunit` completos, deterministas, en paralelo cuando el suite crezca
   (`pest --parallel`, `paratest`).
4. **SCA**: `composer audit` sin vulnerabilidades conocidas sin triaje.
5. **Lock coherente**: `composer validate --strict` y `composer install --dry-run` limpios.

Criterio de testing:
- Comportamiento observable, no implementación. Cubre camino feliz, **bordes y errores** (entradas
  inválidas, límites, fallos de dependencias) — un suite sin tests de error está incompleto.
- Pirámide: unitarios rápidos y mayoritarios; integración (HTTP kernel, DB con transacción y
  rollback o RefreshDatabase) los justos; E2E mínimos.
- Mockea fronteras (HTTP, colas, reloj, filesystem), no clases propias. En Laravel usa fakes del
  framework (`Queue::fake()`, `Http::fake()`, `Event::fake()`); en Symfony, `clock-mock`/servicios
  de test. Nunca red real en tests.
- Todo bugfix entra con test de regresión que primero reproduce el fallo.
- Arch tests (Pest `arch()`) para invariantes estructurales: sin `dd()`/`dump()`/`var_dump` en
  producción, dependencias entre capas, `strict_types` presente.
- Mutation testing (Infection) recomendado en librerías y dominios críticos; cobertura como señal
  (líneas críticas cubiertas), nunca como meta numérica.

## 5. Seguridad del stack

- **OWASP Top 10 como checklist activa**: consultas SIEMPRE parametrizadas (Eloquent/Doctrine/PDO
  prepared) — prohibido concatenar input en SQL, incluso en `whereRaw`/DQL: usa bindings.
  Escapado por contexto: Blade `{{ }}` / Twig autoescape; `{!! !!}`/`|raw` solo con contenido
  saneado y justificado por escrito.
- **Deserialización**: nunca `unserialize()` sobre input externo (usa `json_decode` con validación
  o `allowed_classes: false` si no hay alternativa). Cuidado con SSRF en clientes HTTP que reciben
  URLs de usuario: valida esquema/host contra allowlist.
- **Autenticación/autorización**: primitivas del framework (Laravel `Auth`/policies/Sanctum;
  Symfony Security/voters), nunca caseras. `password_hash()` con Argon2id/bcrypt; comparaciones
  con `hash_equals()`. Autoriza en servidor cada acción, no solo oculta UI.
- **Mass assignment**: `$fillable` estricto (no `$guarded = []`) en Eloquent; DTOs/Form Requests
  como frontera de entrada. Valida SIEMPRE en el borde (Form Request / Validator / Symfony
  Validator), no en el controlador ad hoc.
- **Secretos**: solo en variables de entorno / gestor de secretos; `.env` fuera del VCS; nada en
  logs ni excepciones. `APP_DEBUG=false` en producción (Laravel expone secretos con debug activo).
- **Cabeceras y sesión**: cookies `Secure`, `HttpOnly`, `SameSite`; CSRF activo en formularios;
  HSTS; rate limiting en endpoints de autenticación.
- **SCA continuo**: `composer audit` en CI + Dependabot/Renovate; dependencias abandonadas se
  reemplazan, no se ignoran. Sin extensiones/paquetes con CVEs abiertos sin mitigación documentada.
- Cripto: `random_bytes`/`random_int`, sodium o OpenSSL AES-GCM. Prohibidos MD5/SHA-1 para
  seguridad, `mt_rand`/`rand` para tokens, cifrado casero.

## 6. Rendimiento y operabilidad

- **OPcache** habilitado siempre en producción; `composer install --no-dev --optimize-autoloader`
  (+ `--classmap-authoritative` en deploy inmutable). Preloading solo con medición que lo respalde.
- **N+1 es un bug**: eager loading (`with()`, joins, `Model::preventLazyLoading()` en no-producción;
  Doctrine `fetch join`). Paginación obligatoria en listados; nunca `all()` sin límite.
- Trabajo pesado a **colas/Messenger** con reintentos + backoff y `failed_jobs`/failure transport
  monitorizados; *jobs* idempotentes (reentrega ocurre). Cachea con invalidación explícita
  (tags/TTL), no "por si acaso".
- **PHP-FPM/worker mode**: dimensiona `pm.max_children` con datos; si usas Octane/FrankenPHP/
  RoadRunner, revisa fugas de estado entre peticiones (estáticos, contenedor).
- Observabilidad: logs estructurados (Monolog JSON) con contexto y sin datos sensibles; métricas y
  trazas (OpenTelemetry) en servicios; health checks (`/up`, liveness/readiness) para orquestador.
- Migraciones de BD compatibles hacia atrás (*expand/contract*); nunca migración destructiva en el
  mismo deploy que el código que deja de usar la columna.

## 7. Sostenibilidad: cadencia y prohibiciones

**Cadencia de upgrades**:
- PHP: subir de versión menor en <6 meses desde release; abandonar una línea ANTES de que entre en
  *security-only*. Cita EOL en el plan (endoflife.date/php).
- Laravel: major anual — presupuestar el upgrade cada año (Shift/Rector ayudan); no quedarse a más
  de un major de la actual. Symfony: saltar de LTS a LTS (7.4 → 8.4) o seguir la cadencia semestral,
  decisión explícita del proyecto.
- Dependencias: Renovate/Dependabot semanal; parches de seguridad en <72 h.

**LISTA DE PROHIBICIONES** (bloquean review):
- Fichero nuevo sin `declare(strict_types=1)`.
- `eval()`, `extract()`, `$$variables` variables, `@` (supresión de errores), `goto`.
- `exec`/`shell_exec`/`system`/`proc_open` con input no saneado; backticks.
- SQL/comandos concatenando input; `unserialize()` de datos externos.
- `env()` fuera de `config/` (Laravel); secretos hardcodeados; `APP_DEBUG=true` en producción.
- `mixed` sin justificación; `array` sin shape/docblock genérico en APIs públicas.
- Suprimir errores de PHPStan/Psalm sin comentario de motivo; crecer el baseline.
- `dd()`/`dump()`/`var_dump()`/`print_r()` en código de producción.
- Tests que dependen de red real, hora del sistema sin fake, u orden de ejecución.
- Nuevas dependencias sin justificar (¿lo resuelve el framework o la stdlib?); paquetes abandonados.
- Herencia como reutilización de código (usa composición); *service location* (`app()->make` en
  dominio) en lugar de inyección por constructor.
- Commits que mezclan formato masivo con cambios funcionales.

## 8. Verificación web obligatoria

Antes de fijar CUALQUIER versión, flag o API en un proyecto real, **búscalo en la web** — no lo
des por bueno desde este fichero ni de memoria:
- Versiones soportadas de PHP y fechas EOL: php.net/supported-versions, endoflife.date/php.
- Versión y política de soporte de Laravel (laravel.com/docs/releases) y Symfony
  (symfony.com/releases — confirma cuál es la LTS vigente).
- Compatibilidad PHPStan/Psalm/Pest/PHPUnit con la versión de PHP del proyecto (Packagist).
- CVEs de dependencias: `composer audit` + GitHub Advisories antes de recomendar un paquete.

Si el dato de la web contradice este documento, **manda la web** y menciona la discrepancia.
