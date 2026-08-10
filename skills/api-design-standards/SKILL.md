---
name: api-design-standards
description: REST, GraphQL and gRPC API design standards. Use when writing or reviewing openapi.yaml/swagger.json, .graphql/.proto schemas, .spectral.yaml or redocly.yaml, HTTP status codes, pagination, ETags, RFC 9457 problem details, idempotency keys, rate-limit headers or webhook signatures.
---

# Estándares de diseño de APIs

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al diseñar, revisar o evolucionar el **contrato** de una API y su gobierno: `openapi.yaml`/`openapi.json`/`swagger.json`, ficheros `.graphql`/`.graphqls`, `.proto`, `.spectral.yaml`/`.spectral.js`, `redocly.yaml`, `buf.yaml`/`buf.gen.yaml`, colecciones de ejemplos y portales de desarrollador. Triggers: verbos y códigos HTTP, ETags y peticiones condicionales, paginación, filtrado, formato de error, `Idempotency-Key`, cabeceras de cuota, versionado y `Deprecation`/`Sunset`, esquema GraphQL, evolución de protobuf, webhooks y firma de payload, operaciones asíncronas, endpoints bulk, API gateway.

Principio rector: **el contrato es el producto y es irrevocable en la práctica**. Un endpoint publicado tiene consumidores que no controlas; toda decisión de diseño se toma sabiendo que retirarla costará meses de convivencia y comunicación (§7). Diseña primero el contrato, genera después el código — nunca al revés.

**No aplica**: ver `microservices-architecture-standards` (topología, corte de límites entre servicios, contratos AsyncAPI y diseño de eventos, sagas, resiliencia distribuida), las skills de lenguaje —`python-standards`, `typescript-standards`, `go-standards`, `rust-standards`, `jvm-spring-standards`, `dotnet-standards`, `php-standards`— (implementación concreta del framework HTTP: routing, serialización, DI), `appsec-standards` (modelado de amenazas y triaje de hallazgos), `identity-access-management-standards` (flujos OAuth 2.1/OIDC, PKCE, emisión y validación de tokens, motores de autorización), `cicd-standards` (la pipeline que ejecuta los gates de §4), `i18n-standards` (**el contrato fija el formato de intercambio** —ISO 8601 con zona, importes en unidades mínimas con su código ISO 4217, etiquetas BCP 47 y negociación por `Accept-Language`—; **cómo se presenta eso al usuario en su idioma y región es suyo**. La regla que evita el bug clásico: **una API no devuelve texto ya formateado ni fechas sin zona**), `solidity-standards` (frontera que conviene nombrar: **el ABI de un contrato también es un contrato público**, pero con una diferencia que invierte el criterio de esta skill: **es inmutable y no se versiona**. No hay `/v2`, no hay deprecación ordenada ni ventana de migración; lo que se despliega se queda. El diseño de esa interfaz y su evolución vía proxy son suyos).

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Estilo | **REST sobre HTTP/JSON**, diseño *contract-first* | GraphQL si el problema es agregación multi-fuente para clientes heterogéneos; gRPC para RPC interno de alto rendimiento |
| Formato de contrato | **OpenAPI 3.2.0** (estable desde sept-2025; migración desde 3.1 sin ruptura) | 3.1 si el tooling crítico aún no soporta 3.2 |
| OpenAPI 4.0 "Moonwalk" | **No usar**: sin release ni fecha; la propia OAI recomienda 3.x | — |
| Linter de contrato | **vacuum** (Go, compatible 100% con rulesets Spectral, soporta OAS 3.0/3.1/3.2) o **Redocly CLI** (`@redocly/cli` 2.x, ESM-only, Node ≥ 22.12) | Spectral solo en repos ya montados sobre él (§7: mantenimiento degradado, sin soporte 3.2) |
| Formato de error | **RFC 9457** *problem details* (`application/problem+json`), obsoleta RFC 7807 | — |
| Paginación de colecciones | **Cursor/keyset** | Offset solo en catálogos pequeños, acotados y con orden estable |
| Idempotencia de `POST` | Cabecera **`Idempotency-Key`** (aún I-D, no RFC) | — |
| Cuotas | Cabeceras `RateLimit` / `RateLimit-Policy` del I-D `httpapi-ratelimit-headers` | `X-RateLimit-*` solo por compatibilidad con clientes existentes |
| Deprecación | **RFC 9745** (`Deprecation`) + **RFC 8594** (`Sunset`) | — |
| Versionado | **Mayor en la ruta** (`/v1`), aditivo dentro de la mayor | Versión por cabecera/media type solo con gobierno y tooling que la soporten |
| Firma de webhooks | **HMAC-SHA256** sobre `id.timestamp.payload` (esquema Standard Webhooks) | RFC 9421 (HTTP Message Signatures) si necesitas asimétrico o rotación sin secreto compartido |
| Esquema gRPC | **proto3** | Editions (`edition = "2024"`) solo con migración deliberada (§3.9) |
| Breaking changes protobuf | **`buf breaking`** en CI contra la rama base | — |

## 3. Estructura y convenciones

### 3.1 Modelado de recursos y semántica HTTP

- Recursos = **sustantivos en plural**, minúsculas, `kebab-case` en la ruta (`/payment-methods/{id}`), campos JSON con una única convención por API (`snake_case` o `camelCase`, elegida y linteada). Nunca verbos en la ruta salvo acciones que no son recursos (`/orders/{id}/cancel`) — y esas, mínimas y documentadas.
- Anidamiento máximo **dos niveles** (`/orders/{id}/items`); más profundo, expón el subrecurso como raíz con filtro.
- Semántica no negociable: `GET`/`HEAD` **seguros** (jamás mutan estado, ni "solo un contador"); `PUT`, `DELETE` idempotentes; `PATCH` no idempotente salvo diseño explícito; `POST` no seguro ni idempotente → §3.5.
- `PATCH` con **media type declarado**: `application/merge-patch+json` (semántica de fusión, `null` borra) o `application/json-patch+json` (operaciones). Prohibido un "PATCH artesanal" sin media type ni semántica documentada del `null`.
- Códigos de estado con significado, no decorativos: `201` + `Location` al crear; `202` para aceptación asíncrona (§3.7); `204` sin cuerpo; `400` sintaxis/validación, `401` sin credencial válida, `403` credencial válida sin permiso, `404` para ocultar existencia cuando revelarla filtra información, `409` conflicto de estado, `412` precondición fallida, `422` semántica inválida, `429` cuota, `503` + `Retry-After` en indisponibilidad. **Prohibido** `200` con `{"error": ...}` dentro.
- Errores con **RFC 9457**: `type` (URI estable y resoluble a documentación), `title`, `status`, `detail`, `instance` + extensiones propias (p. ej. `errors[]` por campo). Registra los `type` en un catálogo versionado del contrato; el `detail` es para humanos, el `type` para máquinas. Nunca stack traces, rutas internas ni SQL en el cuerpo del error.
- Fechas en **RFC 3339/ISO 8601 con offset** (UTC por defecto), dinero en unidades menores enteras + ISO 4217, enumeraciones cerradas documentadas y extensibles (los clientes deben tolerar valores nuevos).

### 3.2 Peticiones condicionales y caché

- Toda respuesta de recurso individual lleva **`ETag`**; los `PUT`/`PATCH`/`DELETE` sobre él exigen `If-Match` para evitar *lost update*: sin `If-Match` → `428 Precondition Required` (política) o aceptación explícita documentada; con `If-Match` obsoleto → `412`.
- `GET` con `If-None-Match` → `304` sin cuerpo. ETag débil (`W/"…"`) si la representación varía en detalles irrelevantes.
- `Cache-Control` explícito en **todas** las respuestas (incluidas las privadas: `no-store` para datos sensibles) y `Vary` correcto cuando la respuesta depende de `Accept`, `Accept-Language` o autenticación. Un endpoint sin política de caché declarada acabará cacheado por alguien.

### 3.3 Paginación, filtrado, ordenación y sparse fieldsets

- **Cursor opaco** (`?limit=&cursor=`) con respuesta `{ data: [...], next_cursor|links.next }`. El cursor es opaco por contrato: los clientes no lo parsean y tú puedes cambiar su codificación. Incluye siempre un `limit` **con máximo forzado por el servidor** (p. ej. 100) y valor por defecto documentado.
- Offset (`?page=&per_page=`) solo con conjunto pequeño, acotado y orden estable: es O(n) en BD y produce duplicados/saltos ante escrituras concurrentes. Keyset (`?after_id=&after_created_at=`) cuando necesitas orden natural estable sin opacidad.
- `total_count` **opcional y bajo demanda** (`?include_total=true`): calcularlo siempre es el coste oculto que mata la colección grande.
- Filtrado y ordenación con **allowlist declarada en el contrato** (`?status=active&sort=-created_at`): nada de traducir parámetros arbitrarios a la query (inyección y DoS por índice inexistente). Máximo de campos de orden y de filtros combinables, documentado.
- *Sparse fieldsets* (`?fields=id,name`) para reducir payload; si la API es un árbol de agregación con muchas formas por cliente, eso es la señal de que el caso es de GraphQL (§3.8), no de parámetros infinitos.

### 3.4 Versionado y deprecación

- Versión **mayor en la ruta** (`/v1/…`). Dentro de una mayor, solo cambios **aditivos**: campos opcionales nuevos, endpoints nuevos, valores nuevos en enums extensibles. Renombrar, eliminar, cambiar tipo, endurecer validación o cambiar semántica **es breaking** aunque el esquema "compile".
- Los clientes son *tolerant readers*: ignoran campos desconocidos. Documéntalo como requisito del consumidor; es lo que hace viable la evolución aditiva.
- Ciclo de retirada: publicar `vN+1` → anunciar → **`Deprecation`** (RFC 9745) en las respuestas de `vN` → **`Sunset`** (RFC 8594) con fecha ≥ la de `Deprecation` → `Link` con `rel="deprecation"`/`rel="sunset"` a la guía de migración → medir uso por consumidor → retirar. Ventana mínima publicada por escrito (típico: 6-12 meses en APIs públicas).
- La retirada se decide con **telemetría por consumidor**, no con fe. Sin métrica de uso por versión y por cliente, no hay deprecación posible.

### 3.5 Idempotencia y operaciones no seguras

- `POST` con efectos de negocio (pagos, pedidos, envíos) acepta **`Idempotency-Key`** (UUID generado por el cliente). Contrato: misma clave + mismo payload → misma respuesta almacenada; misma clave + payload distinto → `422`/`409` (no ejecutes); clave nueva → ejecuta. TTL de retención declarado (24h típico) y purga posterior.
- La deduplicación se implementa con **restricción de unicidad en BD**, no con un `SELECT` previo: la concurrencia real es el caso de prueba (§4).
- Estado de la clave: guarda `in_progress` para que dos peticiones simultáneas con la misma clave no ejecuten dos veces (`409` a la segunda, o espera).

### 3.6 Endpoints bulk y batch

- Solo cuando hay evidencia de N+1 en el cliente; no por defecto. Semántica **explícita**: o todo-o-nada (transaccional, `400` global) o parcial con `207`-equivalente detallando el resultado por elemento con su propio problem detail. Ambigüedad aquí = incidencia garantizada.
- Límite duro de elementos por lote, documentado y validado. Bulk grande ⇒ conviértelo en operación asíncrona (§3.7).

### 3.7 Operaciones asíncronas y de larga duración

- `POST` → **`202 Accepted`** + `Location` al recurso de operación + `Retry-After`. `GET /operations/{id}` devuelve `{status: pending|running|succeeded|failed, result|error}` con el error en formato RFC 9457.
- La operación es un **recurso de primera clase** con id estable, timestamps y retención declarada; se puede consultar después de terminar. Cancelación explícita (`POST /operations/{id}/cancel`) si el negocio la necesita.
- Notificación de fin por **webhook** (§3.10) además del polling; el polling es el fallback siempre disponible, nunca el único mecanismo en operaciones largas.

### 3.8 GraphQL

- Aplica cuando el cliente necesita **elegir la forma del dato** sobre muchas fuentes. No es una alternativa "moderna" a REST: cambia el problema de sobre-fetching por el de coste de consulta arbitraria.
- Esquema: nomenclatura estable (`PascalCase` tipos, `camelCase` campos), nullability deliberada (no todo nullable "por si acaso"), paginación **Relay connections** (`edges`/`node`/`pageInfo`), mutaciones con input type único y payload con errores de dominio tipados (los errores de negocio son datos del esquema, no entradas en `errors[]`).
- **N+1 obligatoriamente resuelto con dataloader** (batch + cache por request). Un resolver que consulta por elemento en una lista es un bug de rendimiento, no una optimización pendiente.
- Límites duros en producción: **profundidad máxima**, **complejidad/coste por consulta** con presupuesto por cliente, límite de aliases y de batching (el batching por array es un multiplicador de ataque), timeout de ejecución.
- **Persisted operations / trusted documents** como allowlist en clientes propios: el cliente envía un id, el servidor solo ejecuta documentos conocidos. Distíngueles de **APQ** (Automatic Persisted Queries), que es ahorro de ancho de banda y **no** es un control de seguridad. Para APIs públicas el allowlist no es viable → límites de profundidad/coste + rate limiting son obligatorios.
- Introspección desactivada en producción (defensa en profundidad, no barrera: asume que el esquema se puede inferir). `GET` solo para consultas de lectura y con protección CSRF; `application/graphql-response+json` como media type de respuesta.
- Evolución: GraphQL no versiona; se **deprecan campos** (`@deprecated(reason:)`) y se retiran con telemetría de uso por campo. `@defer`/`@stream` siguen **fuera de la spec ratificada**: no los pongas en el contrato público (§8).

### 3.9 gRPC y protobuf

- Compatibilidad de wire es responsabilidad del esquema: **nunca reutilices números de campo ni cambies su tipo**; usa `reserved` para números y nombres retirados. Campos nuevos siempre opcionales con default sensato.
- Enums: reserva el valor `0` como `UNSPECIFIED`; añadir valores es aditivo, quitarlos no.
- `buf breaking` contra la rama base como gate de CI (§4) y `buf lint` con ruleset estándar. Registro de esquemas (BSR o equivalente) si hay consumidores externos.
- **proto3 por defecto**: Editions (`edition = "2023"/"2024"`) no aporta funcionalidad nueva y cambia defaults sensibles (`features.field_presence` pasa a `EXPLICIT`), lo que convierte una migración descuidada en breaking change. Migra solo con plan y verificación (§8).
- Errores: `google.rpc.Status` con códigos canónicos; el mapeo a HTTP se documenta si hay pasarela gRPC↔REST.

### 3.10 Webhooks

- Payload firmado con **HMAC-SHA256 sobre `id.timestamp.payload`** (concatenación con `.`), cabeceras `webhook-id`, `webhook-timestamp`, `webhook-signature`. El receptor verifica **sobre los bytes crudos** del cuerpo, antes de deserializar.
- **Anti-replay**: rechazar timestamps fuera de una ventana de tolerancia (300 s es el valor recomendado por Standard Webhooks y el default de Stripe) **y** deduplicar por `webhook-id` como clave de idempotencia. Ambas cosas, no una.
- Comparación de firmas en **tiempo constante**. Soporte de **múltiples secretos activos** para rotación sin corte (firma con el nuevo, acepta ambos durante la ventana).
- Entrega at-least-once con reintentos y backoff exponencial + jitter, límite de intentos, endpoint de reentrega manual y visibilidad del historial de intentos. El consumidor responde `2xx` **rápido** y procesa en background; timeout corto del emisor documentado.
- Egress controlado: lista de IPs de salida publicada o mTLS; el receptor valida que el destino sea suyo. Del lado del que registra URLs de webhook, valida contra **SSRF** (sin IPs privadas/loopback/metadata, sin redirecciones a rangos internos).

### 3.11 HATEOAS, con criterio

- Hipermedia completa (HAL, JSON:API, Siren) solo aporta cuando hay clientes genéricos o flujos con transiciones dependientes del estado. En APIs consumidas por clientes propios genera coste sin retorno.
- Regla práctica: incluye `links` para **paginación**, para **recursos relacionados** y para **acciones disponibles según estado** (`cancelable`), y nada más. No inventes un motor de hipermedia que nadie va a usar.

## 4. Calidad y gates de CI

En orden de coste creciente; todos bloquean el merge (main siempre verde):

1. **Validación estructural** del contrato (`redocly lint` / `vacuum lint` / `buf lint`): rompe si el documento no es válido para la versión declarada.
2. **Ruleset de estilo propio** versionado en el repo (naming, plural, `operationId` único, `description` obligatoria, ejemplos, `4xx`/`5xx` declarados con `application/problem+json`, `security` presente en cada operación). El ruleset es el que convierte "buenas prácticas" en gate.
3. **Diff de compatibilidad** contra la versión publicada: `redocly` / `oasdiff` para OpenAPI, `buf breaking` para protobuf, comprobación de esquema GraphQL (`graphql-inspector` o equivalente). Un breaking change sin bump de mayor rompe el build.
4. **Contract tests**: el servidor se valida contra su propio contrato (request/response validation en tests de integración) y los consumidores clave contra dobles verificados. Generar cliente y servidor del mismo contrato no demuestra nada: valida respuestas reales.
5. **Tests de bordes obligatorios**, no solo camino feliz: paginación en el último elemento y con cursor inválido/caducado; `If-Match` obsoleto → `412`; `Idempotency-Key` repetida **concurrentemente** (dos peticiones simultáneas, no secuenciales); payload en el límite y por encima del límite; enum desconocido; `429` con cabeceras de cuota correctas; webhook con firma inválida, timestamp caducado e id duplicado.
6. **Ejemplos del contrato validados contra sus esquemas** (un ejemplo que no valida es documentación falsa) y documentación generada en CI.

## 5. Seguridad

- Referencia: **OWASP API Security Top 10 — edición 2023** (sigue siendo la vigente en ago-2026; no existe edición 2026 pese a lo que anuncian blogs de terceros). Prioridad real: BOLA/BOPLA (autorización a nivel de objeto y de propiedad) e inventario de APIs.
- **Autorización por objeto en cada endpoint**: que el id exista no significa que sea del que pregunta. Prohibido confiar en ids no adivinables como control de acceso. Autorización **a nivel de propiedad** también: no serialices el modelo entero (`role`, `internal_notes`) ni aceptes binding masivo — allowlist de campos de entrada y de salida.
- Autenticación: **OAuth 2.1 / OIDC con tokens de vida corta** para acceso de usuario y `client_credentials` para máquina-a-máquina; verifica `iss`, `aud`, `exp` y firma en **cada** servicio. API keys solo para identificación de aplicación y cuota, nunca como única autenticación de operaciones sensibles; si existen, con prefijo identificable, hash en reposo, scoping y rotación. **Prohibido**: tokens de larga vida sin rotación, secretos en query string, `Basic` fuera de canal interno con mTLS.
- Declara `security` **por operación** en el contrato, no solo global: un endpoint que se olvidó de heredarlo es un endpoint abierto.
- **Validación estricta en el borde** contra el esquema del contrato: tipos, formatos, longitudes, rangos, `additionalProperties: false` donde aplique, tamaño máximo de cuerpo y de profundidad de JSON. Rechaza lo que no encaje; no "sanees" adivinando.
- Rate limiting **por identidad y por operación** (no solo por IP), con coste diferenciado para endpoints caros; `429` + `Retry-After` + cabeceras de cuota. Límite global de concurrencia y de tamaño de página como protección contra DoS de aplicación.
- Nunca filtres en el error existencia, estructura interna, versiones ni trazas: el `detail` de RFC 9457 lo escribes tú, no el framework. Correlaciona con un `trace_id` en la respuesta para soporte.
- CORS restrictivo: origen explícito, jamás reflejo del `Origin` con `Access-Control-Allow-Credentials: true`.
- **Inventario**: toda API desplegada está en el catálogo con dueño, versión y estado. Las APIs *shadow* y las versiones "que ya nadie usa" pero siguen respondiendo son el hallazgo recurrente en auditoría.

## 6. Rendimiento y operabilidad

- **Presupuesto de latencia por endpoint** y SLO publicado en el portal (p95/p99 + disponibilidad). Sin SLO, la API no tiene contrato operativo.
- Métricas por operación (`operationId`, no por URL con ids): latencia, tasa de error por código, uso de cuota, y **uso por versión y por consumidor** (imprescindible para §3.4).
- Compresión negociada, `Content-Length` conocido, streaming (SSE o chunked) para respuestas grandes — OpenAPI 3.2 ya describe streaming de forma nativa.
- **API gateway** para lo transversal: TLS 1.2+/1.3, authn, rate limiting, validación contra el contrato, observabilidad. Prohibido meter lógica de negocio o transformaciones de payload específicas de dominio en el gateway.
- Portal de desarrollador generado **desde el contrato** (nunca escrito a mano en paralelo): referencia, guía de autenticación, changelog por versión, catálogo de `type` de errores, entorno de pruebas y política de deprecación. Documentación divergente del contrato = documentación falsa.
- Sandbox/mock server generado del contrato para que los consumidores integren antes de que exista la implementación.

## 7. Sostenibilidad y gobierno

- **Design-first**: el contrato se revisa en PR antes de implementar, con revisor de API distinto del autor en APIs públicas. El review de contrato es un gate humano, no un trámite.
- Ruleset de estilo **compartido entre APIs** de la organización, versionado y con proceso para cambiarlo. La consistencia entre APIs es un atributo de producto.
- ADR para decisiones one-way: estilo (REST/GraphQL/gRPC), esquema de versionado, formato de error, modelo de autenticación, política de deprecación.
- Política de breaking changes **escrita y publicada**: qué se considera breaking, ventana mínima de convivencia, canal de aviso, compromiso de soporte por versión mayor. En APIs públicas es un compromiso contractual, no una intención.
- Cadencia: revisión trimestral del inventario (versiones vivas, uso por consumidor, candidatas a retirada) y de las versiones del tooling (§8).

### PROHIBIDO
- ❌ Breaking change dentro de una versión mayor (renombrar/eliminar campos, cambiar tipo o semántica, endurecer validación de entrada).
- ❌ `200 OK` con error en el cuerpo; errores sin RFC 9457; `detail` con stack trace, SQL o rutas internas.
- ❌ `GET` que muta estado; `POST` con efectos sin soporte de `Idempotency-Key`.
- ❌ Paginación por offset en colecciones que crecen; colección sin `limit` máximo forzado por el servidor.
- ❌ Filtros u ordenación construidos desde parámetros arbitrarios sin allowlist.
- ❌ Autorización basada en ids no adivinables; serializar el modelo interno completo; binding masivo de la entrada.
- ❌ Endpoint sin `security` declarado en el contrato, o sin autorización a nivel de objeto.
- ❌ Deprecar sin `Deprecation`/`Sunset`, sin plazo publicado y sin telemetría de uso por consumidor.
- ❌ Retirar una versión antes del plazo comunicado — o dejarla viva indefinidamente "por si acaso".
- ❌ Documentación escrita a mano en paralelo al contrato; ejemplos que no validan contra su esquema.
- ❌ GraphQL en producción sin límite de profundidad/complejidad, sin dataloader o con introspección abierta.
- ❌ Confundir APQ con allowlist de operaciones y llamarlo control de seguridad.
- ❌ Reutilizar números de campo protobuf o cambiar su tipo; publicar `.proto` sin `buf breaking` en CI.
- ❌ Webhooks sin firma, sin ventana de tolerancia de timestamp o sin deduplicación por id.
- ❌ Aceptar URLs de webhook sin validación anti-SSRF.
- ❌ Adoptar OpenAPI 4.0 "Moonwalk" en un proyecto real (no existe release).
- ❌ Lógica de negocio en el API gateway.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento en un entregable, **búscalo — no lo recuerdes**:

1. **OpenAPI**: versión estable vigente (3.2.0 desde sept-2025) y estado real de 4.0/Moonwalk en `github.com/OAI/sig-moonwalk` y `openapis.org` — a ago-2026 sigue sin fecha y la propia OAI recomienda 3.x.
2. **RFCs y drafts** en `datatracker.ietf.org` antes de citarlos: RFC 9457 (problem details, jul-2023, obsoleta 7807) ✔; RFC 9745 (`Deprecation`) ✔; RFC 8594 (`Sunset`, informational) ✔; RFC 9110 (HTTP Semantics) ✔; RFC 9651 (Structured Fields) ✔. **Ojo**: RFC 9331 **no** es rate limiting, es ECN/L4S — las cabeceras de cuota siguen en `draft-ietf-httpapi-ratelimit-headers` (rev. -11, may-2026, expira nov-2026) y su **sintaxis ha cambiado varias veces** (hoy `RateLimit-Policy: "sliding";q=12;w=1` / `RateLimit: "sliding";q=12;r=1;t=1`): verifica la revisión vigente antes de implementarla. `Idempotency-Key` sigue siendo I-D, no RFC.
3. **Linters**: última versión de Redocly CLI (`@redocly/cli`, 2.x, ESM-only, Node ≥ 22.12) y vacuum, y su soporte de OAS 3.2. Estado de mantenimiento de Spectral (actividad muy degradada en 2025-2026, sin soporte 3.2; existe fork comunitario) antes de elegirlo para un proyecto nuevo.
4. **GraphQL**: edición ratificada vigente (September2025 en `spec.graphql.org`) y estado de `@defer`/`@stream` e incremental delivery — a ago-2026 seguían pendientes de spec pese a estar en graphql-js v17+. Estado de la estandarización de *persisted documents* en GraphQL-over-HTTP.
5. **Protobuf/gRPC**: versión del Buf CLI y su guía vigente sobre Editions vs proto3 (`buf.build/docs`, `protobuf.dev/editions`) — la recomendación conservadora que se cita aquí es de 2024.
6. **Webhooks**: revisión vigente de la spec de Standard Webhooks (`standardwebhooks.com`) y de RFC 9421 antes de fijar cabeceras o algoritmo.
7. **OWASP API Security Top 10**: edición oficial vigente en `owasp.org/API-Security` — a ago-2026 es la **2023**; los artículos titulados "2026" reempaquetan esa lista.
8. CVEs y EOL de cualquier gateway, servidor GraphQL o librería que recomiendes (`endoflife.date`, avisos del proyecto).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
