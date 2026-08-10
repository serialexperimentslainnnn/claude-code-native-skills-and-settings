---
name: microservices-architecture-standards
description: Standards for systems already split across the network - the distributed topology, not the internal design of one deployable. Use when cutting service boundaries and their ownership, inter-service contracts (OpenAPI, AsyncAPI, protobuf/gRPC) and their versioning, synchronous versus asynchronous communication, sagas and distributed transactions, the outbox pattern, message queues between services, resilience patterns (circuit breaker, retries with backoff, timeouts, bulkheads), API gateways, service mesh and mTLS between services, identity propagation across service calls, or distributed tracing correlation.
---

# Estándares de arquitectura de microservicios

## 1. Alcance y triggers

Aplica al diseñar, revisar o evolucionar: servicios distribuidos, límites entre servicios, contratos de API (REST/gRPC/eventos), comunicación asíncrona, resiliencia, observabilidad distribuida y la decisión previa monolito vs microservicios. Triggers: "microservicio", "bounded context", "event-driven", "saga", "outbox", "API gateway", "contrato", "OpenAPI", "AsyncAPI", "protobuf", "circuit breaker", "strangler".

**No aplica**: ver `api-design-standards` (el **diseño interno** de un contrato concreto: recursos, verbos, códigos HTTP, paginación, ETags, RFC 9457, idempotency keys, versionado del contrato — aquí solo qué contrato existe entre qué servicios y cómo se gobierna su evolución), `data-platform-standards` (el motor por debajo: modelado, índices, particionado y retención de Kafka, tuning de PostgreSQL — aquí el patrón outbox, la propiedad del dato por servicio y por qué no se comparte base de datos), `kubernetes-standards` (cómo se despliega cada servicio: manifiestos, Gateway API, mesh como implementación), `observability-standards` (instrumentación OTel, muestreo, cardinalidad y el backend de trazas — aquí solo la exigencia de correlación distribuida), `sre-practice-standards` (SLO por servicio, error budget, on-call y la operación del sistema resultante), `identity-access-management-standards` (emisión y validación de la identidad que se propaga entre servicios), `appsec-standards` (clases de vulnerabilidad en el código de cada servicio), `cryptography-pki-standards` (la PKI que sostiene el mTLS interno), `aws-standards`/`azure-standards`/`gcp-standards` (los servicios gestionados de cola, bus y gateway del proveedor), las skills de lenguaje (implementación concreta de cada patrón), `software-architecture-patterns-standards` (**frontera crítica, espejada desde su §1**: **el diseño interno de un sistema y la decisión previa de si hace falta distribuir son suyos** —monolito modular como default, capas, hexagonal/puertos y adaptadores, límites de módulo, contexto delimitado, CQRS y event sourcing, ADR, C4, atributos de calidad—; **aquí la topología distribuida**: corte de servicios, comunicación por la red, saga y outbox en su ejecución, resiliencia distribuida, mTLS y mallas. Regla: ***si la pregunta es cómo se comunican dos procesos separados por la red, es de aquí; si es cómo se estructura el código dentro de un despliegue, es suya***. Corolario que ninguna de las dos debe suavizar: **el monolito modular es el default del catálogo y esta skill no se activa para justificarlo, sino cuando ya hay una fuerza que obliga a distribuir**), `refactoring-tech-debt-standards` (**el *strangler fig*, la rama por abstracción y el expand/contract como técnicas de migración segura son suyos**; aquí el destino distribuido al que se migra y sus contratos).

Principio rector: **los microservicios son una técnica de escalado organizativo con coste distribuido permanente** — se adoptan por necesidad demostrada (§2.1), se cortan por dominio (§3) y se pagan con disciplina de contratos, resiliencia y observabilidad (§3–§6); sin esa disciplina, el resultado es un monolito distribuido, el peor de ambos mundos.

## 2. Decisiones por defecto

> **Verificación web obligatoria antes de fijar versiones**: los valores siguientes se verificaron en agosto 2026; re-verifica con WebSearch en cada uso real (ver §8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Arquitectura inicial | **Monolito modular** con límites internos por dominio | Microservicios solo con justificación (§2.1) |
| Contrato REST | **OpenAPI 3.1/3.2** (3.2.0 estable desde sept 2025), *design-first* | — |
| Contrato eventos | **AsyncAPI 3.x** (3.1 actual) | — |
| RPC interno de alto rendimiento | **gRPC + protobuf** (proto3) | REST si el equipo no lo domina |
| Broker de eventos | **Kafka 4.x** (4.2.1 actual, KRaft; sin ZooKeeper desde 4.0) | RabbitMQ para colas de trabajo clásicas; NATS para ligereza |
| Observabilidad | **OpenTelemetry** (trazas/métricas/logs estables; CNCF *graduated* 2026; *profiles* aún alpha — no depender de ello en prod) | — |
| Borde | API gateway con authn/authz centralizada; **mTLS** interno | Service mesh solo si ya se necesita por escala |
| Decisiones irreversibles | **ADR obligatorio** | — |

### 2.1 Cuándo NO usar microservicios (decisión explícita, no default)

Microservicios es una decisión *one-way* cara. **Prohibido** adoptarlos sin que se cumpla al menos una de estas condiciones, documentada en ADR:

- Equipos múltiples (>2) que necesitan desplegar de forma independiente y chocan en el mismo código.
- Requisitos de escala/aislamiento de fallo claramente divergentes entre dominios (medidos, no supuestos).
- Dominios con ciclos de vida o cumplimiento normativo que exigen aislamiento (datos, despliegue, auditoría).

En su ausencia: **monolito modular** — módulos con límites de dominio explícitos, dependencias dirigidas y verificadas (ArchUnit o equivalente), esquema de BD por módulo. Eso deja la puerta abierta a extraer servicios después (§7, strangler fig) sin pagar hoy el coste distribuido (latencia de red, consistencia eventual, operación N sistemas).

Coste que se asume al distribuir (nómbralo en el ADR, no lo descubras en prod):
- La red falla, tiene latencia y no es segura (falacias del computing distribuido): todo lo que era una llamada a función pasa a poder fallar parcialmente.
- Consistencia eventual entre servicios: la UX y el negocio deben tolerarla explícitamente.
- Coste operativo ×N: pipelines, observabilidad, on-call, versionado y seguridad por servicio.

## 3. Diseño y límites

### Límites por dominio (DDD)
- Un servicio = un **bounded context** (o parte de uno); nunca un context repartido entre servicios ni servicios "por capa técnica" (entidad-service, CRUD-service).
- Entre contexts, traducción explícita (anti-corruption layer); no compartir modelos de dominio ni librerías de entidades entre servicios.
- Heurística de corte: alta cohesión transaccional dentro, comunicación asíncrona y tolerante a retraso fuera. Si dos "servicios" necesitan desplegarse o transaccionar juntos, son uno.

### Contratos versionados
- **El contrato es la fuente de verdad**: OpenAPI/AsyncAPI/`.proto` versionados en repo, revisados en PR, con linting (Spectral o equivalente) y diff de compatibilidad en CI.
- Convenciones REST mínimas: recursos en plural, errores con formato uniforme (RFC 9457 *problem details*), paginación por cursor en colecciones que crecen, filtros documentados en el contrato, idempotencia en `PUT`/`DELETE` e `Idempotency-Key` para `POST` con efectos (pagos, pedidos).
- Tolerant reader: los consumidores ignoran campos desconocidos (no validación cerrada del payload completo); esa tolerancia es lo que hace viables los cambios aditivos.
- **Compatibilidad hacia atrás obligatoria** dentro de una versión mayor: añadir campos opcionales sí; renombrar, eliminar o cambiar tipo/semántica, no. Protobuf: nunca reutilizar números de campo ni cambiar su tipo; usa `reserved`.
- Breaking change ⇒ **nueva versión mayor publicada en paralelo** (`/v2`, nuevo topic o nuevo tipo de evento), con periodo de convivencia y plan de retirada comunicado a consumidores. Ver prohibiciones en §7.
- Eventos con **schema registry** y política de compatibilidad `BACKWARD` (mínimo) verificada en CI; el evento lleva identificador de esquema y versión.

### Diseño de eventos
- Distingue y elige conscientemente el tipo de evento:
  - **Notificación** (`OrderPlaced` + id): mínimo acoplamiento de esquema, pero provoca llamadas de vuelta al productor — cuidado con re-crear acoplamiento síncrono.
  - **Event-carried state transfer** (evento con el estado necesario): elimina la llamada de vuelta a costa de más superficie de contrato y más PII en tránsito (§5).
  - **Domain events** internos ≠ eventos públicos de integración: no publiques tal cual los eventos internos del agregado; el evento público es un contrato curado y estable.
- Todo evento lleva: `event_id` (único, para deduplicar), `occurred_at`, versión de esquema, y clave de correlación/causación para trazabilidad.
- Nombra en pasado y por hecho de negocio (`InvoiceIssued`), nunca por intención técnica (`UpdateInvoiceRow`).

### Comunicación: síncrona vs eventos
- **Síncrono (REST/gRPC)** solo cuando el llamante necesita la respuesta para continuar. Cada llamada síncrona añade acoplamiento temporal y multiplica la probabilidad de fallo: una cadena de >2-3 saltos síncronos es olor a *distributed monolith*.
- **Eventos** para propagación de estado y flujos entre dominios. Reglas no negociables:
  - **Idempotencia del consumidor**: entrega at-least-once es la norma; deduplica por clave de negocio o event-id. Nunca asumas exactly-once extremo a extremo.
  - **Transactional outbox** para publicar eventos junto a cambios de estado (misma transacción local + relay/CDC). Prohibido el doble write "BD y luego broker".
  - **Backpressure**: consumidores con límites de concurrencia y lag monitorizado; productores que degradan o rechazan bajo presión, nunca buffering ilimitado en memoria.
  - **DLQ** con alerta y runbook de reproceso; un mensaje venenoso no puede bloquear la partición (límite de reintentos antes de DLQ).
  - Orden solo se garantiza por partición: elige la clave de partición por la entidad cuya secuencia importa.

### Datos y transacciones
- **Base de datos por servicio**: cada servicio posee su esquema; ningún otro servicio lee/escribe en él (ni "solo lectura", ni vistas compartidas). La integración de datos va por API o eventos.
- **Sin transacciones distribuidas** (2PC/XA prohibido entre servicios). Consistencia entre servicios vía **sagas**: preferir coreografía por eventos para flujos simples, orquestador explícito para flujos con lógica de compensación compleja. Cada paso tiene compensación definida y probada; los estados intermedios son visibles y consultables.
- Reglas de saga: pasos idempotentes; timeouts por paso con acción definida (compensar o alertar, nunca colgado indefinido); las compensaciones son operaciones de negocio (`CancelReservation`), no "rollbacks" técnicos, y también pueden fallar — diseña el reintento y la intervención manual (runbook).
- Consultas cross-servicio: composición en el llamante/gateway (pocos datos) o **vista materializada local alimentada por eventos** (CQRS ligero) para lecturas frecuentes; acepta y comunica la consistencia eventual de esa vista. Prohibido resolverlas con JOINs a la BD de otro servicio.
- Si un flujo "necesita" ACID entre dos servicios, el límite está mal cortado: únelos.

## 4. Calidad y testing

- **Contract testing obligatorio** entre servicios: consumer-driven (Pact o equivalente) o verificación de compatibilidad de esquemas en CI. Un proveedor no puede mergear un cambio que rompa un contrato verificado por un consumidor.
- Pirámide: unitarios rápidos por servicio > tests de contrato > pocos E2E de humo sobre flujos críticos. **Prohibido** basar la confianza en E2E masivos sobre el entorno completo (frágiles, lentos, no escalan con N servicios).
- Tests de resiliencia: simula timeout, error 5xx y respuesta lenta del *downstream* (Toxiproxy/WireMock); verifica que saltan circuit breakers y degradación controlada, no solo el camino feliz.
- Tests de idempotencia y reentrega: todo consumidor de eventos se prueba con mensajes duplicados y desordenados.
- Tests de saga: cubre el camino feliz, el fallo en cada paso (¿compensa?) y el fallo de la propia compensación (¿alerta + runbook?). Un flujo de saga sin tests de compensación no está terminado.
- Entornos: cada servicio se prueba contra dobles verificados por contrato de sus dependencias, no contra el entorno completo; el entorno integrado sirve para humo y exploración, no como gate de merge.
- Gates de CI: lint de contrato + diff de compatibilidad + contract tests + build del servicio aislado. Main siempre verde; cada servicio desplegable de forma independiente (si no puede, es distributed monolith).

## 5. Seguridad y datos personales

- **Zero-trust interno**: mTLS entre servicios (idealmente con identidad de workload tipo SPIFFE/certificados de corta vida); authn/authz en cada servicio, no solo en el gateway. Sin confianza por red.
- **API gateway** como único punto de entrada norte-sur: terminación TLS 1.2+/1.3, validación de tokens (OIDC/JWT con expiración corta y verificación de audience/issuer), rate limiting, validación de entrada contra el contrato.
- **Propagación de identidad**: la identidad del usuario final viaja con la petición (JWT propagado o *token exchange*), no se pierde en el primer salto; cada servicio autoriza con el contexto del usuario, no con la identidad genérica del servicio llamante. Scopes/permisos por servicio, no un token omnipotente.
- Mínimo privilegio en broker: ACLs por servicio y topic (un servicio solo produce/consume lo declarado).
- Validación en los bordes de cada servicio: valida contra el contrato en entrada (no confíes en que el gateway ya validó) y sanea salida según contexto.
- Secretos fuera del código y de la imagen: gestor de secretos, credenciales efímeras, OIDC en CI.
- Cadena de suministro: imágenes mínimas non-root, firmadas y verificadas antes de desplegar; SBOM y escaneo (SAST/SCA/imagenes) como gates.
- **Datos personales**: minimización en eventos (publica identificadores y lo estrictamente necesario, no el agregado entero); clasifica los topics que llevan PII; para derecho al olvido en logs de eventos inmutables usa *crypto-shredding* (cifrado por sujeto con clave destruible) o retención corta + estado en el servicio dueño. Un evento publicado es una API y un dato replicado: piensa GDPR antes de publicarlo.

## 6. Operabilidad

- **OpenTelemetry extremo a extremo**: propagación de contexto W3C `traceparent` en HTTP, gRPC y cabeceras de mensajes; trazas, métricas y logs **correlacionados** por trace_id. Logs estructurados (JSON) siempre.
- **SLO por servicio** sobre síntomas (golden signals: latencia p95/p99, tráfico, tasa de error, saturación) con error budget; alertas accionables sobre SLO, no sobre causas internas ruidosas. Lag de consumidores y profundidad de DLQ son SLI de primera clase en sistemas de eventos.
- **Resiliencia por defecto** en todo cliente saliente: timeout explícito (siempre; sin timeout = incidente diferido), retries con **backoff exponencial + jitter** solo para operaciones idempotentes y con budget de reintentos, **circuit breaker** por dependencia, **bulkheads** (pools/límites de concurrencia por dependencia) y degradación definida (¿qué respondes cuando el downstream está caído?).
- Health checks separados: liveness (proceso vivo) vs readiness (dependencias listas); readiness no debe encadenar dependencias transitivas.
- Presupuesto de latencia extremo a extremo: reparte el SLO de la petición entre saltos (los timeouts de cada salto deben ser coherentes con el del llamante: decrecientes hacia abajo, nunca mayores).
- Idempotencia también al servir: los endpoints que los clientes reintentarán (por sus propios retries) deben tolerar la repetición sin efectos dobles.
- Despliegues: canary o rolling con rollback automatizado probado; compatibilidad N/N-1 entre servicio y sus consumidores durante el rollout; feature flags para desacoplar deploy de release. Capacity: dimensiona con datos de carga (particiones, réplicas, pools), no por intuición; prueba de carga antes de comprometer SLO.
- Cada servicio con runbook mínimo: dependencias, dashboards, cómo reprocesar su DLQ, cómo degradarlo, a quién despierta. Un servicio que nadie sabe operar no está "hecho".
- Plantillas/chasis compartido para lo transversal (telemetría, health, resiliencia, authn): la uniformidad operativa se consigue por plataforma, no copiando código entre servicios.

## 7. Sostenibilidad y evolución

- **Strangler fig** para migrar monolito → servicios: extrae un dominio, enruta tráfico gradualmente (fachada/gateway), retira el código viejo al terminar. Nunca reescritura big-bang. Orden de extracción: primero el dominio con más presión de cambio/escala y menos acoplamiento de datos; extrae primero el código (módulo), luego los datos (BD propia), por ese orden.
- **Política de deprecación formal**: todo endpoint/evento deprecado se anuncia (cabecera `Deprecation`/`Sunset` en REST, changelog del contrato), con fecha de retirada y telemetría de uso por consumidor; se retira cuando el uso es cero o venció el plazo comunicado — no antes ni "nunca".
- Contratos con *changelog* semántico por versión; los consumidores se enteran por el repo del contrato, no por el incidente.
- **Expand/contract** para todo cambio de contrato o esquema: publica lo nuevo junto a lo viejo, migra consumidores, mide que ya nadie usa lo viejo (telemetría, no fe), retira. La retirada es parte de la tarea, no deuda implícita.
- **ADR obligatorio** para decisiones one-way: adopción de microservicios, corte de límites, elección de broker, estrategia de sagas, versionado. Formato corto: contexto, decisión, alternativas, consecuencias. Las decisiones two-way se toman rápido y se revierten si fallan.

### Lista de prohibiciones
- ❌ Breaking change de contrato o evento sin nueva versión mayor y periodo de convivencia.
- ❌ Base de datos compartida entre servicios (incluye lectura directa, vistas y "solo este JOIN").
- ❌ Distributed monolith: servicios que deben desplegarse juntos, versionarse juntos o transaccionar juntos.
- ❌ 2PC/XA o transacciones distribuidas entre servicios.
- ❌ Doble write BD + broker sin outbox/CDC.
- ❌ Consumidores no idempotentes en entrega at-least-once.
- ❌ Llamadas salientes sin timeout, o retries sin backoff+jitter, o retry de operaciones no idempotentes.
- ❌ Cadenas síncronas largas (>3 saltos) en el camino de una petición de usuario.
- ❌ Compartir librerías de entidades/modelos de dominio entre servicios.
- ❌ Eventos sin esquema en registry ni política de compatibilidad.
- ❌ Comunicación entre servicios sin TLS/mTLS ni authz "porque es red interna".
- ❌ Microservicios sin ADR que justifique el coste frente al monolito modular.
- ❌ Servicio sin SLO, sin trazas propagadas o con logs sin trace_id.
- ❌ Lógica de negocio en el gateway o en el mesh (ahí solo transversales: routing, authn, rate limit, TLS).
- ❌ Saga sin compensaciones definidas y probadas, o con estados intermedios invisibles.
- ❌ Endpoints deprecados retirados sin anuncio, telemetría de uso y plazo comunicado.

Señales de corte de límites erróneo (revisa el diseño, no parchees): cambios de negocio que siempre tocan varios servicios a la vez; cascadas de llamadas para pintar una pantalla; datos duplicados que divergen sin dueño claro; releases coordinadas recurrentes.

## 8. Verificación web obligatoria

Antes de fijar en un entregable cualquier versión, licencia o recomendación de este documento, **verifica con WebSearch** (los datos de §2 son de agosto 2026 y caducan):

1. Versión estable de Kafka (¿sigue 4.2.x?) y estado de KIPs relevantes (p. ej. KIP-932 Queues, aún preview en 4.1/4.2).
2. Versión vigente de OpenAPI (3.2.x; estado real de 4.0 "Moonwalk") y AsyncAPI (3.x).
3. Estado de OpenTelemetry por señal (profiles estaba en alpha en marzo 2026) y semantic conventions aplicables.
4. Licencias de brokers/registries elegidos (Confluent Community License vs Apache 2.0: Karapace/Apicurio).
5. CVEs y EOL de las versiones que vayas a recomendar (endoflife.date).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
