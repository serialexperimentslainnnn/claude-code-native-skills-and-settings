---
name: caching-cdn-standards
description: Use when content is stored closer to the reader — Cache-Control directives, s-maxage, stale-while-revalidate and stale-if-error, CDN-Cache-Control (RFC 9213), Cache-Status (RFC 9211), Vary and its hit-rate cost, surrogate keys and purge-by-tag, cache key normalization, origin shield, edge functions, CloudFront/Cloudflare/Fastly/Akamai/bunny.net edge configuration and egress billing, maxmemory-policy with noeviction or allkeys-lru on a Valkey/Redis cache node, cache-aside and write-through designs, key naming and value-format versioning, thundering-herd stampede, penetration and avalanche mitigation, web cache poisoning and cache deception, or hit-ratio measurement per layer.
---

# Estándares de caché y entrega de contenido (CDN)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al decidir **si** cachear, **dónde** cachear y **quién invalida**: caché en proceso,
caché distribuida en memoria (Valkey/Redis usados *como caché*), caché de respuesta HTTP en
el proxy inverso, y CDN. Cubre patrones de caché, diseño e invalidación de claves, los fallos
clásicos con nombre propio, semántica de cabeceras HTTP de caché, configuración de borde,
riesgos de seguridad específicos de la caché y su medición.

Triggers: `Cache-Control`, `max-age`, `s-maxage`, `must-revalidate`, `private`/`no-store`,
`stale-while-revalidate`, `stale-if-error`, `CDN-Cache-Control`, `Surrogate-Control`,
`Surrogate-Key`/`Cache-Tag`, `Cache-Status`, `Age`, `Vary`, purga y `PURGE`, *origin shield*,
clave de caché y normalización de query string, *edge function*/Worker/Lambda@Edge,
`maxmemory`, `maxmemory-policy`, `noeviction`, `allkeys-lru`, `volatile-ttl`, `evicted_keys`,
`keyspace_hits`/`keyspace_misses`, `proxy_cache`/`proxy_cache_path`, *cache-aside*,
*read-through*, *write-through*, *write-behind*, *thundering herd*, *cache stampede*,
*hit ratio*, envenenamiento de caché y *web cache deception*.

**Tesis de la skill**: **cachear es duplicar estado, y todo estado duplicado se
desincroniza.** La pregunta correcta nunca es "¿cacheo esto?" sino **"¿qué pasa cuando esté
obsoleto y quién lo invalida?"**. Si no hay respuesta a la segunda, no hay caché: hay una
bomba de relojería con buena latencia. Corolario incómodo: **la caché es la solución por
defecto a problemas que nadie ha diagnosticado** — antes de añadir una capa, mide qué es
lento y por qué (§6.4).

**No aplica**: ver `data-platform-standards` (**skill madre**: fija **Valkey (BSD-3, Linux
Foundation) como motor de caché por defecto** frente a Redis 8+ tri-licenciado, y el criterio
básico de TTL y cache-aside. **Esta skill profundiza y no la contradice**: allí se elige el
motor y se declara la licencia, aquí se decide la política de desalojo, la estrategia de
invalidación y el comportamiento ante fallo), `networking-standards` (**el proxy inverso y el
balanceador como pieza de red son suyos**: HAProxy, nginx, Traefik y Caddy — su despliegue,
versiones, TLS, health checks, topología y hardening. **Aquí solo su rol como caché de
respuestas HTTP**: `proxy_cache`, clave de caché, coherencia con el borde y con el origen. La
frontera es limpia: *nginx como servidor y proxy → `networking-standards`; nginx como caché →
esta skill*), `api-design-standards` (**el contrato HTTP es suyo**: `ETag` obligatorio por
recurso, `If-Match`/`If-None-Match`, `412`/`428`, `304`, y la exigencia de declarar
`Cache-Control` y `Vary` correctos en toda respuesta. **Aquí el comportamiento de la
infraestructura que consume esas cabeceras**: qué hace el borde con ellas, `s-maxage` vs
`max-age`, `CDN-Cache-Control`, serve-stale y el coste de un `Vary` mal puesto sobre la tasa
de acierto. No dupliques la semántica de ETag: delégala), `message-brokers-standards`
(colas, brokers y logs distribuidos: Kafka/KRaft, RabbitMQ, NATS, Redpanda, Pulsar — y la
regla de que una tabla PostgreSQL con `SKIP LOCKED` suele bastar. **Redis/Valkey Streams
usado como cola cae de su lado.** Declaración de frontera: *la cola es suya, la caché es mía*; una instancia que hace de caché
**no** hace de cola — son cargas con durabilidad y HA distintas, y comparten proceso solo por
accidente), `microservices-architecture-standards` (propiedad del dato, outbox, sagas),
`aws-standards`/`azure-standards`/`gcp-standards` (**CloudFront, Azure Front Door, Cloud CDN,
ElastiCache/MemoryDB, Memorystore como servicios gestionados**: su IaC, IAM, WAF y facturación;
aquí el criterio de caché que aplica igual sea quien sea el proveedor), `cicd-standards` (la
**purga de CDN como paso del despliegue** y el versionado de assets con hash en el nombre),
`kubernetes-standards` (Ingress y despliegue del proxy), `cryptography-pki-standards` (TLS y
certificados en el borde), `appsec-standards` (metodología de amenazas y OWASP general; aquí
solo las clases de riesgo propias de la caché), `privacy-engineering-standards` (**dato
personal en caché**: base legal, minimización y **borrado efectivo incluyendo copias
cacheadas** — aquí solo la mecánica de purgarlas), `observability-standards` (plataforma de
métricas; aquí qué SLI de caché exportar), `sre-practice-standards` (SLO y presupuesto de
error), `object-storage-standards` (el origen estático detrás del CDN),
`mysql-mariadb-dba-standards` y `oracle-dba-standards` (**frontera crítica**: la caché suele
existir *porque la base de datos no aguanta*. Si la causa es un N+1, una consulta sin índice o
una PK mal elegida, **la respuesta correcta es arreglar la consulta, no añadir una caché** —
§6.4), `rag-standards`/`llm-app-engineering-standards` (caché semántica de prompts y
respuestas de LLM: dominio propio, con su propio criterio de acierto), `lua-standards`
(**Ola 5**: **la plataforma es de aquí** —nginx/OpenResty y su configuración, upstreams, TLS,
política de caché y purga; Redis/Valkey y su memoria, persistencia y expulsión—; **el Lua que corre
dentro es suyo**: los scripts `EVAL`/`EVALSHA` y su determinismo, y el código de las fases
`access_by_lua`/`content_by_lua` con su prohibición dura de llamadas bloqueantes en el ciclo de
eventos), `web-performance-standards` (**Ola 6**: **la política de caché, el CDN, las cabeceras y
la purga son de aquí**; **el efecto medido en el cliente** —LCP, TTFB al percentil 75, datos de
campo— **es suyo**. Una caché que mejora el *hit ratio* y no mueve la métrica de usuario no ha
resuelto nada), `pwa-standards` (**Ola 6** — **aviso operativo, no solo frontera**: la caché de un
*service worker* es **otra capa, por delante de todo lo que decide esta skill**, y puede **anular
la política de caché del CDN y del origen**. Un despliegue que no se ve en el navegador suele ser
un `sw.js` sirviendo HTML viejo, no un fallo de purga. El criterio de esa capa —qué se precachea,
con qué estrategia y cómo se desactiva un service worker roto— es suyo).

## 2. Decisiones por defecto

> Verificar la última versión, licencia y soporte real de directivas por web antes de fijarlo
> en un proyecto (§8). Datos de **agosto 2026**.

| Decisión | Por defecto | Motivo / alternativa justificable |
|---|---|---|
| ¿Añadir una caché? | **No, hasta que exista una medición** que identifique la consulta o la ruta lenta y demuestre que el dato tolera estar obsoleto | Cada capa de caché es una fuente de verdad más que mantener (§6.4) |
| Patrón | **Cache-aside** | Todo lo demás exige justificación (§3.2) |
| TTL | **Obligatorio en toda entrada**, corto y con *jitter* | "TTL corto imperfecto" gana a "invalidación perfecta" en casi todos los casos (§3.3) |
| Motor de caché distribuida | **Valkey** (BSD-3-Clause, Linux Foundation) — serie 9.1.x (9.1.1, jul-2026); ramas vivas 9.0.x, 8.1.x, 8.0.x, 7.2.x | Lo fija `data-platform-standards`. **Redis 8+ es tri-licencia RSALv2 / SSPLv1 / AGPLv3** (verbatim del `LICENSE.txt`): solo con visto bueno explícito de la política de licencias, o por dependencia real de módulos que Valkey no cubra. Contexto de adopción: AWS ElastiCache y Google Memorystore ofrecen Valkey y varias distribuciones lo empaquetan como `redis-server` por defecto — **verificar qué binario tienes realmente** (§8) |
| Política de desalojo | **`maxmemory` fijado + `allkeys-lru`** (o `allkeys-lfu` con patrón de acceso sesgado) | **`noeviction` en una caché es un incidente esperando fecha** (§3.6) |
| Persistencia en el nodo de caché | **Desactivada** (sin RDB ni AOF) | Una caché es descartable por definición. Si un dato necesita durabilidad, no es caché: es base de datos (§3.6) |
| Caché HTTP compartida | `Cache-Control` explícito en **toda** respuesta; **nunca por omisión** | Un endpoint sin política declarada acabará cacheado por alguien, en la capa que menos te conviene |
| Serve-stale | **`stale-while-revalidate` + `stale-if-error` siempre que el contenido lo tolere** | Son las dos directivas con mejor relación valor/riesgo del estándar (§3.7) |
| Control específico de CDN | **`CDN-Cache-Control`** (RFC 9213) cuando el borde y el navegador deban diferir | Evita el truco frágil de `s-maxage` para todo |
| Diagnóstico | **`Cache-Status`** (RFC 9211) habilitado en preproducción | En producción, solo a clientes autorizados: expone información sobre la clave de caché (§5) |
| Assets estáticos | **Nombre con hash de contenido** + `Cache-Control: public, max-age=31536000, immutable` | Elimina el problema de invalidación por construcción: es la mejor "estrategia de caché" que existe |
| Purga por etiqueta | Mecanismo del proveedor (`Surrogate-Key` en Fastly, `Cache-Tag` en Cloudflare, invalidación por path en CloudFront) | **No hay estándar IETF vigente**: `draft-ietf-httpbis-cache-groups` sigue en borrador. Es acoplamiento a proveedor consciente, con ADR |
| Funciones en el borde | **Solo** para lógica de clave de caché, normalización, redirecciones y cabeceras | Lógica de negocio en el borde es un despliegue paralelo sin observabilidad (§7) |

## 3. Criterio técnico

### 3.1 Las capas, de dentro a fuera

| Capa | Qué resuelve | Su fallo característico |
|---|---|---|
| **En proceso / en memoria del pod** | Latencia cero, datos minúsculos y muy calientes (configuración, catálogos, resultados de cálculo) | **Incoherencia entre réplicas**: N pods = N versiones del dato. Solo para datos donde la divergencia entre instancias es tolerable, y con TTL en segundos |
| **Distribuida (Valkey/Redis)** | Estado compartido entre instancias, descarga de la base de datos, sesiones | Se convierte en un SPOF si la aplicación no funciona sin ella; y en base de datos accidental si alguien guarda ahí lo único que existe |
| **De la base de datos** (buffer pool, plan cache, vistas materializadas) | Es la caché que **ya tienes y no gestionas** | Se olvida: se añade una caché externa para un dato que el buffer pool ya servía desde memoria. Mide antes (§6.4) |
| **Proxy inverso** (nginx/Varnish/Traefik) | Respuestas HTTP completas cerca del origen, protección del backend | Clave de caché mal definida → se sirve la respuesta de un usuario a otro (§5) |
| **CDN** | Latencia geográfica, absorción de picos, coste de salida del origen | Purga lenta y global; y todo lo que cachees mal se multiplica por el número de PoPs |

**Regla**: **cachear en la capa equivocada multiplica el problema en vez de resolverlo.** Un
dato personalizado por usuario cacheado en el CDN es una fuga de datos; un dato global
cacheado en cada pod es N copias divergentes de algo que debía estar en una sola. Coloca la
caché **en la capa más externa que sea correcta** (más beneficio) y **nunca más externa que
eso** (más riesgo).

**Regla de no-solape**: no apiles capas para el mismo dato sin decidir la relación entre sus
TTL. Dos cachés con TTL de 300 s en serie dan una obsolescencia máxima de 600 s, no de 300.

### 3.2 Patrones

- **Cache-aside (lazy loading) — el default.** La aplicación lee la caché; si falla, lee el
  origen y escribe la caché con TTL. Ventajas: simple, la caché nunca es camino crítico de
  escritura, resiste su propia caída. Coste: cada miss paga la latencia completa, y hay una
  ventana de carrera entre la lectura del origen y la escritura de la caché.
- **Read-through**: la caché (o su biblioteca) carga el dato en el miss. Encapsula mejor, pero
  acopla la aplicación a un componente que ahora es camino crítico de lectura.
- **Write-through**: escribe a la vez en caché y origen. Coherencia mejor, latencia de
  escritura mayor, y **llena la caché de datos que quizá nadie lea**.
- **Write-behind (write-back)**: escribe en caché y persiste asíncronamente. Máximo
  rendimiento y **máximo riesgo**: la caché contiene el único ejemplar del dato hasta que se
  vuelca. **Vetado** salvo con durabilidad propia demostrada y ADR que asuma la pérdida.
- **Invalidación al escribir: borra, no actualices.** `DELETE` de la clave tras la escritura
  tiene menos carreras que reescribir el valor (dos escritores concurrentes pueden dejar el
  valor antiguo si actualizan). El siguiente lector la repuebla.
- **Refresco proactivo (*cache warming*)** solo para un conjunto pequeño, conocido y crítico
  (portada, catálogo destacado). Precalentar "todo" reproduce la carga que querías evitar.

### 3.3 Invalidación: el problema difícil

En orden de preferencia:

1. **Por TTL** — simple, autolimitada, sin estado adicional, y **suficiente en la inmensa
   mayoría de los casos**. La pregunta de diseño es una sola: *¿cuántos segundos de datos
   obsoletos tolera el negocio para este dato?* Ponlo por escrito; suele ser mucho más de lo
   que el equipo asume, y bastante menos de lo que el TTL puesto por defecto refleja.
2. **Por evento** — el escritor invalida al cambiar el dato. Correcto y ajustado, pero
   introduce acoplamiento y **falla en silencio**: cuando el evento se pierde, nadie se entera.
   **Regla dura: la invalidación por evento se combina *siempre* con TTL como red de
   seguridad**, nunca la sustituye.
3. **Por etiqueta / surrogate key** — cuando un cambio invalida un conjunto ("todos los
   productos de esta categoría"). Es lo correcto para el borde. Coste: llevar el mapa de
   etiquetas y depender del mecanismo propietario del proveedor (§2).
4. **Por versión en la clave** — cambia el prefijo y la caché vieja muere por desalojo.
   Invalidación instantánea, atómica y sin purga; a cambio, un **miss del 100 %** justo
   después. Combínalo con calentamiento del conjunto crítico o con despliegue progresivo.

**Criterio rector**: **prefiere un TTL corto a una invalidación perfecta.** Un sistema de
invalidación por eventos es un sistema distribuido más que mantener, depurar y monitorizar,
con su propia clase de bugs; un TTL de 30 s no tiene bugs y a menudo resuelve el mismo
problema de negocio. Sube la complejidad solo cuando el coste del TTL corto (carga en origen)
esté medido y sea inasumible.

### 3.4 Los fallos clásicos con nombre propio

- **Estampida / *thundering herd* / *dog-piling***: expira una clave caliente y N peticiones
  concurrentes van al origen a la vez. Mitigaciones, combinables:
  - **Bloqueo o *single-flight***: solo un solicitante recalcula; el resto espera o recibe el
    valor obsoleto. El bloqueo debe tener **expiración obligatoria** (si el que recalcula
    muere, no puede bloquear a todos para siempre).
  - **Refresco anticipado (*probabilistic early expiration*)**: cuando la entrada se acerca a
    su expiración, un solicitante elegido probabilísticamente la refresca en segundo plano
    mientras los demás siguen sirviendo el valor vigente. Es el equivalente aplicativo de
    `stale-while-revalidate`.
  - **Soft TTL / hard TTL**: sirve el valor pasado el TTL blando mientras se refresca; solo
    bloquea al llegar al duro.
- **Penetración (claves inexistentes)**: peticiones de identificadores que no existen nunca
  aciertan en caché y siempre van al origen — vector de DoS trivial. Mitigación: **cachear el
  resultado negativo** con TTL corto (marcador explícito, no `null` ambiguo), validar el
  formato de la clave en el borde, y filtro de Bloom para espacios de clave grandes.
- **Avalancha (expiración simultánea)**: un lote de claves creadas a la vez expira a la vez.
  Mitigación: **jitter obligatorio en todo TTL** (p. ej. `ttl * (1 + rand(0, 0.2))`). Variante
  peligrosa: el reinicio o failover de la caché, que expira **todo** de golpe — la aplicación
  debe sobrevivir a un miss del 100 % (§6.3). Si no sobrevive, la caché no es una optimización:
  es una dependencia dura sin plan de HA.

### 3.5 Diseño de la clave

- **Formato explícito y documentado**: `<app>:<versión-formato>:<entidad>:<id>[:<variante>]`.
  Sin espacios ni datos libres del usuario sin normalizar.
- **La clave incluye todo lo que hace variar el valor**: identificador, idioma, moneda, país,
  versión de la API, rol o segmento si aplica. **Una dimensión olvidada = servir el contenido
  equivocado**; en la capa HTTP, el equivalente exacto es un `Vary` incompleto (§5).
- **Versiona el formato del valor en la clave.** Cuando cambies la forma serializada, cambia
  la versión: es la única forma segura de desplegar N y N-1 a la vez sin que el código nuevo
  lea estructuras viejas (o al revés). Nunca reutilices el mismo prefijo con otro esquema.
- **Nunca metas datos personales ni secretos en la clave**: las claves aparecen en logs,
  métricas, trazas y en la salida de diagnóstico. Usa un identificador opaco.
- **Cardinalidad acotada**: una clave por combinación de filtros libres del usuario es una
  caché con 0 % de acierto y presión de memoria infinita. Normaliza y acota el espacio de
  claves antes de cachear (lo mismo aplica a la clave de caché del CDN, §3.8).

### 3.6 Valkey/Redis **como caché** (no como base de datos)

La elección de motor y su licencia las fija `data-platform-standards` (Valkey por defecto,
BSD-3; Redis 8+ tri-licenciado). Aquí, la operación **en el rol de caché**:

- **`maxmemory` siempre fijado**, por debajo de la memoria del contenedor/host con margen para
  fragmentación y buffers de réplica y de cliente. Sin `maxmemory`, el proceso crece hasta que
  el OOM killer decide por ti.
- **`maxmemory-policy`**:
  - `allkeys-lru` / `allkeys-lfu` → **el default de una caché**. LFU si hay claves
    persistentemente calientes; LRU si el patrón es temporal.
  - `volatile-*` → solo si conviven en la misma instancia datos con y sin TTL. Trampa: si se
    quedan sin candidatos con TTL, **se comportan como `noeviction`**.
  - **`noeviction` en una instancia de caché es un incidente**: al llenarse, las escrituras
    empiezan a devolver error (`OOM command not allowed`) y la caché deja de aceptar entradas
    nuevas mientras sigue sirviendo las viejas. Se convierte silenciosamente en un almacén
    congelado y obsoleto. `noeviction` solo tiene sentido cuando la instancia **no** es caché
    (cola, contadores, locks) — y entonces es otra instancia, con otra skill (§1).
- **Fragmentación**: vigila `mem_fragmentation_ratio`. Valores muy por encima de 1 indican
  memoria retenida por el asignador; `activedefrag` es una opción, con coste de CPU. Valores
  por debajo de 1 significan *swap* — inaceptable en una caché: desactiva el swap o dimensiona.
- **Persistencia**: **desactivada** en el rol de caché. RDB provoca picos de memoria por
  *fork* (copy-on-write) y de I/O; AOF cuesta latencia. Salvo que quieras un **arranque
  caliente** tras un reinicio planificado — decisión consciente, con su coste medido, no el
  default heredado del paquete.
- **La diferencia caché vs base de datos**, explícita: una caché es **reconstruible desde la
  fuente de verdad, en cualquier momento y sin pérdida**. En el momento en que un dato solo
  existe ahí (sesión sin respaldo, contador de negocio, cola de trabajo), ya **no** es una
  caché: hereda requisitos de durabilidad, backup, HA y replicación — y probablemente esté en
  el almacén equivocado.
- **HA**: réplica y failover (Sentinel o modo cluster) **solo si el impacto de perder la caché
  lo justifica**, medido contra la pregunta de §6.3. Cluster para datasets que no caben en un
  nodo, no por moda. Antes de montar HA para una caché, pregunta si no es más barato hacer que
  el sistema tolere su ausencia.
- **Prohibido en producción**: `KEYS` (usa `SCAN`), `FLUSHALL`/`FLUSHDB` desde la aplicación,
  scripts Lua largos, y compartir la instancia de caché con cargas de cola o de locks.
- **Superficie de seguridad**: nunca expuesta a red no confiable, TLS y autenticación
  obligatorias, comandos administrativos renombrados o deshabilitados. Vigila los CVE: 2026 ha
  traído en esta familia DoS por *cluster bus* y **uso después de liberar con posibilidad de
  RCE** (incluido en el motor de scripting Lua) — con versiones mínimas de corrección
  publicadas por rama. **Verifica tu rama contra el aviso vigente** (§8).

### 3.7 HTTP: las directivas que de verdad importan

Delegación explícita: **la semántica de `ETag`, `If-None-Match`, `304`, `If-Match` y `412`, y
la obligación de declarar `Cache-Control` y `Vary` en toda respuesta, son de
`api-design-standards`.** Aquí, lo que la infraestructura hace con ello:

- **`max-age` vs `s-maxage`**: `max-age` aplica a todas las cachés; `s-maxage` solo a las
  compartidas (proxy, CDN) y **prevalece sobre `max-age`** en ellas. El patrón útil es
  `max-age` corto en el navegador (revalidación barata) y `s-maxage` largo en el borde (donde
  puedes purgar).
- **`CDN-Cache-Control` (RFC 9213, *Targeted HTTP Cache Control*)**: cuando el CDN debe hacer
  algo distinto del resto de cachés. Permite, por ejemplo, `Cache-Control: no-store` +
  `CDN-Cache-Control: max-age=600` (el borde cachea, nadie más). **Cuidado**: llevar dos
  políticas en la misma respuesta es una fuente conocida de confusión sobre dónde acaba
  almacenado un dato sensible — documenta la intención.
- **`stale-while-revalidate` y `stale-if-error` (RFC 5861) — las dos que más valor dan**:
  - `stale-while-revalidate=N`: sirve el valor obsoleto durante N s mientras revalida en
    segundo plano. Convierte el pico de latencia de la expiración en cero, y es la mitigación
    de estampida "de fábrica" en la capa HTTP.
  - `stale-if-error=N`: sirve el valor obsoleto si el origen responde error o no responde.
    **Convierte una caída de origen en una degradación**, no en una página de error. Cuesta
    cero en operación normal: ponlo generoso.
  - Estado verificado (agosto 2026): `stale-while-revalidate` lo honran Chrome, Firefox y Edge;
    **Safari no**. **`stale-if-error` no lo implementa ningún navegador importante**: es
    efectivamente una directiva de CDN/proxy. En el borde: CloudFront soporta ambas; Cloudflare
    hizo su SWR **completamente asíncrono en feb-2026** (antes la primera petición tras expirar
    bloqueaba); **Google Cloud CDN soporta SWR pero no `stale-if-error`** (y aplica
    `serveWhileStale` por defecto, 86400 s si no se especifica); Fastly da control completo.
    **"Servir obsoleto" no significa lo mismo en dos CDN: verifica el tuyo** (§8).
  - Ojo con la ventana: el refresco asíncrono solo ocurre si llega una petición dentro de la
    ventana SWR. Con tráfico escaso, una ventana pequeña deja peticiones bloqueando igual.
- **`immutable`** para assets con hash en el nombre: evita revalidaciones inútiles.
- **`private` vs `public` vs `no-store`**: `private` impide el almacenamiento en cachés
  compartidas pero **no** en el navegador; `no-store` es la única que impide almacenar en
  cualquier sitio. Todo lo autenticado o personalizado: `no-store` o `private` **y** una clave
  de caché que incluya al usuario. Nunca `public` en una respuesta que dependa de la sesión.
- **`Vary`: la directiva que destruye la tasa de acierto sin avisar.** Cada valor añadido
  multiplica las variantes almacenadas por la cardinalidad de esa cabecera.
  - `Vary: Accept-Encoding` → aceptable (2-3 variantes).
  - `Vary: Accept-Language` → tantas variantes como cadenas de idioma envíen los navegadores
    (cientos). **Normaliza a un conjunto cerrado en el borde antes de variar.**
  - **`Vary: User-Agent` → prohibido**: cardinalidad efectivamente infinita, tasa de acierto
    ≈0. Usa *client hints* normalizados o una decisión en el borde.
  - **`Vary: Cookie` o `Vary: Authorization` sobre contenido público → veto**: cualquier cookie
    de analítica fragmenta la caché por usuario. Si la respuesta depende de la sesión, no es
    contenido cacheable en una caché compartida (§5).
  - **Omitir un `Vary` necesario es peor que incluirlo**: es exactamente el mecanismo de fuga
    de datos entre usuarios (§5).
- **`Cache-Status` (RFC 9211)**: cabecera estándar para saber qué capa acertó y por qué falló
  (sin coincidencia de `Vary`, respuesta obsoleta, respuesta parcial…). Imprescindible para
  depurar una tasa de acierto baja. **En producción, solo a clientes autorizados**: revela
  información sobre la clave de caché, útil para un atacante (§5).
- **`Age`** para detectar obsolescencia real en producción, y para verificar que el borde y el
  navegador cuentan la frescura como esperas.

### 3.8 CDN

- **Qué va al borde**: estático (con hash en el nombre → `immutable`), imágenes y media,
  respuestas HTML anónimas, respuestas de API públicas y de lectura intensiva. **Qué no**:
  todo lo que dependa de sesión, cookie o cabecera de autorización, salvo con clave de caché
  que incluya explícitamente al principal — y aun así, con revisión de seguridad (§5).
- **Dinámico con SWR corto**: para contenido que cambia a menudo pero tolera segundos de
  antigüedad (listados, portadas, respuestas de API de lectura), `s-maxage` bajo +
  `stale-while-revalidate` + `stale-if-error` largo gana más que cualquier otra configuración.
- **Clave de caché y normalización — donde se gana o se pierde la tasa de acierto**:
  - **Ignora los parámetros de query irrelevantes** (`utm_*`, `fbclid`, `gclid`…): si entran en
    la clave, cada campaña de marketing te fabrica una caché vacía.
  - **Ordena y filtra la query a una lista permitida**; normaliza mayúsculas del host, barra
    final y codificación de la ruta.
  - **Cuidado con la normalización agresiva**: fusionar en la misma clave dos URL que el origen
    trata distinto es precisamente el mecanismo de envenenamiento por discrepancia de
    analizadores (§5). Normaliza igual en el borde y en el origen, o no normalices.
  - Cabeceras y cookies **fuera** de la clave salvo lista explícita.
- **Purga**: por etiqueta cuando el proveedor lo permita, por path si no; **por comodín, solo
  como último recurso** (equivale a vaciar). **Su latencia real no es cero**: la propagación a
  todos los PoP tarda, y en un CDN grande un PoP caído puede no completarla hasta volver. No
  diseñes flujos que asuman purga instantánea y global. **La estrategia superior sigue siendo
  no necesitar purgar**: hash en el nombre del asset y versión en la clave.
- **Origin shield**: una capa intermedia que consolida los misses de todos los PoP contra el
  origen. Reduce drásticamente la carga en origen y el coste de salida en contenido de cola
  larga; añade un salto de latencia en el miss y un punto más de configuración. Actívalo
  cuando el origen sufra por el número de PoP, no por defecto.
- **El coste de salida es criterio de diseño, no una sorpresa de facturación**: la tasa de
  acierto es una **variable de coste** además de una de rendimiento. Cada byte que no acierta
  se paga dos veces (salida del origen + transferencia del CDN), y la mayoría de proveedores
  factura además por peticiones y algunos por *cache fill*. Los modelos difieren de raíz
  (por GB, cuota fija con ancho de banda no medido, cuota base + GB): **una caída de la tasa de
  acierto es un incidente de coste**, y merece alerta (§6.2). Modela el coste **antes** de
  elegir proveedor y revisa las condiciones de uso: los planes de ancho de banda "no medido"
  suelen excluir la distribución masiva de vídeo o de ficheros grandes.
- **Funciones en el borde** (Workers, Lambda@Edge, edge middleware): úsalas para manipular la
  clave de caché, normalizar, redirigir, añadir cabeceras de seguridad y hacer pruebas A/B por
  variante controlada. **No** para lógica de negocio ni acceso a datos: es un entorno de
  ejecución distinto, con otro modelo de despliegue, otra observabilidad y otro modelo de
  fallo. Si acaba teniendo estado, ya no es una función de borde: es un servicio sin SRE.

## 4. Calidad y gates de CI

En orden de coste creciente. Los marcados **rompen el build**:

1. **Lint de cabeceras de respuesta**: toda ruta declara `Cache-Control` explícito; **fallo si
   una respuesta autenticada carece de `no-store`/`private`**, o si una respuesta `public`
   incluye `Set-Cookie` o depende de `Authorization`. **Gate**.
2. **Veto de `Vary: User-Agent`**, de `Vary: Cookie` sobre contenido público, y de `public` +
   `Vary: Authorization`. **Gate**.
3. **Tests de la capa de caché con caché real** (contenedor Valkey), no con un doble en
   memoria: los TTL, el desalojo y los errores de red son justamente lo que hay que probar.
4. **Tests de invalidación como camino feliz *y* como fallo**: escribir → leer obsoleto →
   invalidar → leer fresco; y el caso en que la invalidación **falla** — el TTL debe seguir
   acotando la obsolescencia. Un sistema de caché sin este test es un sistema sin garantía.
5. **Tests de bordes**: miss, expiración, resultado negativo cacheado, caché **caída**
   (la aplicación debe degradar, no fallar — §6.3), y caché que devuelve un valor con formato
   antiguo (versionado de clave, §3.5).
6. **Test de estampida**: N solicitantes concurrentes sobre una clave recién expirada generan
   **una** carga al origen, no N. Es la regresión que más silenciosamente vuelve.
7. **Prueba de coherencia del borde**: petición autenticada, purga, y verificación de que el
   contenido personalizado **no** aparece en una petición anónima posterior. Automatizable
   contra preproducción. **Gate en el pipeline de configuración del CDN**.
8. **Revisión de la configuración del CDN como código** (Terraform u OpenTofu; ver
   `iac-standards`), con diff revisado: la configuración del borde cambia el comportamiento de
   seguridad de toda la aplicación y **no puede editarse a mano en la consola**.
9. **Purga de CDN como paso explícito y verificado del despliegue** (ver `cicd-standards`),
   incluido el caso en que la purga falla.
10. **Prueba de deception en la batería de seguridad**: solicitar una ruta autenticada con un
    sufijo estático inventado (`/cuenta/perfil/x.css`, `.avif`, `.js`…) y comprobar que **no**
    se cachea (§5).

## 5. Seguridad de la caché

Las tres clases de riesgo son propias de este dominio y no las cubre `appsec-standards` con
este detalle:

- **Servir una respuesta personalizada a otro usuario — es una fuga de datos, no un bug de
  rendimiento.** Es el fallo más grave y más frecuente de la caché, y aparece por tres vías:
  clave de caché incompleta, `Vary` que omite la dimensión que personaliza, o `Cache-Control`
  ausente en un endpoint que alguien decidió cachear más arriba. **Trátalo como incidente de
  seguridad con notificación**, no como bug de caché: si ocurrió, hubo exposición de datos
  personales (ver `incident-response-forensics-standards` y `privacy-engineering-standards`).
  Defensa por diseño: **denegar por defecto** en el borde — nada se cachea salvo rutas en lista
  permitida; y `no-store` automático ante presencia de `Authorization` o cookie de sesión.
- **Envenenamiento de caché (*cache poisoning*)**: el atacante consigue que la caché almacene
  una respuesta manipulada que después se sirve a todos. Vectores: entradas no incluidas en la
  clave pero sí reflejadas en la respuesta (cabeceras "no clave" como `X-Forwarded-Host`,
  `X-Forwarded-Scheme`, parámetros de query ignorados en la clave pero usados por la
  aplicación), y **discrepancias de análisis de URL entre el borde y el origen** (barra final,
  codificación, delimitadores) — línea de investigación muy activa: los estudios a escala
  encuentran miles de sitios afectados y bypasses recurrentes de las protecciones de los CDN.
  Mitigación: **toda entrada que influya en la respuesta forma parte de la clave o se elimina
  en el borde**; normalización idéntica en borde y origen; no reflejar cabeceras no
  normalizadas; `Cache-Status` restringido; y pruebas activas en la batería de seguridad.
- **Cache deception (*web cache deception*)**: el atacante induce a la víctima a solicitar
  `/cuenta/perfil.css`; el origen ignora el sufijo y devuelve el perfil, el borde ve una
  extensión "estática" y lo cachea como público; el atacante lo recupera. Mitigación: **la
  decisión de cachear se toma por el `Content-Type` y por la política del *origen*, no por la
  extensión de la URL**; el origen envía `Cache-Control: no-store` en todo lo autenticado; y no
  confíes en las listas de extensiones "protegidas" del proveedor (se han demostrado bypasses
  con extensiones nuevas o poco comunes). Normaliza o rechaza rutas con sufijos inesperados.
- **Envenenamiento por *request smuggling*** y desincronización entre el proxy y el origen:
  el vector que convierte una discrepancia de análisis en control total de la caché. Es un
  riesgo de la cadena proxy↔origen (ver `networking-standards` para la pieza de red y
  `appsec-standards` para la técnica), pero **su amplificación es de la caché**: una respuesta
  envenenada se sirve a miles.
- **Datos personales en caché**: la caché es una copia más del dato, sujeta a la misma
  clasificación, cifrado y retención. **El derecho de supresión alcanza a las copias
  cacheadas**: sin capacidad de purga dirigida, el TTL es tu única garantía de borrado —
  documéntalo y acótalo. Nunca datos personales en la clave (§3.5) ni en los logs del borde.
- **DoS por caché**: peticiones a claves inexistentes (penetración, §3.4) y peticiones diseñadas
  para maximizar los misses (query aleatoria) convierten tu CDN en un amplificador contra tu
  propio origen — y en una factura. Normalización estricta de la clave, límite de tasa en el
  borde y caché de negativos.
- **Parcheo del software de caché y de proxy**: 2026 ha sido un año duro en esta superficie
  (desbordamientos en nginx con explotación activa en el mundo real, agotamiento de recursos por
  HTTP/2 afectando a múltiples proxies, uso-después-de-liberar en el motor de scripting de la
  familia Redis/Valkey). La caché está en el camino de **todo** el tráfico: su ventana de
  parcheo es la de un componente de borde, no la de un servicio interno. Ver
  `vulnerability-management-standards` y `networking-standards` (versiones del proxy).
- **Cadena de suministro** de las funciones de borde y de los paquetes que empaquetan: se
  despliegan en el camino de todo el tráfico. Fija por digest y verifica firma — recordando el
  precedente de 2026 (**Mini Shai-Hulud / CVE-2026-45321**, falsificación de atestaciones SLSA
  nivel 3): **la procedencia por sí sola ya no es prueba suficiente**.

## 6. Medición y operabilidad

### 6.1 SLI por capa
Ninguna métrica agregada sirve: **mide la tasa de acierto por capa y por clase de contenido**.
Un 95 % global puede esconder un 99 % en estáticos y un 20 % en la API, que es lo que duele.

- **Distribuida (Valkey/Redis)**: `keyspace_hits`/`keyspace_misses`, **`evicted_keys`** (si
  crece de forma sostenida, la caché es demasiado pequeña o los TTL demasiado largos),
  `expired_keys`, memoria usada vs `maxmemory`, `mem_fragmentation_ratio`, latencia p99,
  clientes bloqueados y conexiones rechazadas.
- **HTTP/CDN**: tasa de acierto (por PoP y por tipo de contenido), **peticiones y bytes al
  origen** (la métrica que se traduce en factura), latencia en origen vs en borde, `Age` de las
  respuestas servidas, tasa de servido-obsoleto (`stale-while-revalidate` / `stale-if-error`
  activándose: **un pico de `stale-if-error` es una alerta de origen caído disfrazada de
  normalidad**), errores 5xx del origen y tasa de purgas.
- **De negocio**: latencia p95/p99 percibida extremo a extremo — la única que justifica que la
  caché exista.

### 6.2 Alertas que valen la pena
Caída brusca de la tasa de acierto (**síntoma de despliegue que cambió la clave, `Vary` nuevo o
purga masiva** — y también incidente de coste); crecimiento sostenido de `evicted_keys`;
memoria acercándose a `maxmemory`; picos de servido-obsoleto por error; y **desviación del
gasto de salida** frente a la línea base.

### 6.3 La pregunta que define tu arquitectura
> **¿Qué pasa si la caché desaparece ahora mismo?**

Si la respuesta es "se cae el sistema", **no tienes una caché: tienes una base de datos en
memoria sin durabilidad, sin backup y sin HA**. Diseña para que la aplicación funcione
degradada sin caché (límite de tasa, degradación controlada, *circuit breaker* hacia el
origen, carga progresiva al repoblar) y **ensáyalo**: apagar la caché en un *game day* es una
de las pruebas más rentables que existen. Timeouts cortos hacia la caché: un miss debe costar
milisegundos, nunca convertirse en el cuello de botella que pretendía evitar.

### 6.4 La conversación incómoda: caché vs arreglar el origen
Antes de añadir cualquier capa, responde por escrito:
1. **¿Qué es exactamente lo lento?** (traza y plan de consulta, no intuición).
2. **¿Es un problema de la base de datos o de la aplicación?** Un **N+1** del ORM, una consulta
   sin índice, una PK que fragmenta el índice agrupado o una paginación por `OFFSET` **se
   arreglan en su sitio**. Cachear el resultado de una consulta sin índice esconde el problema,
   duplica el estado, añade una clase entera de bugs de coherencia y deja la bomba puesta para
   el primer miss masivo. Ver `mysql-mariadb-dba-standards` §6 y `data-platform-standards`.
3. **¿Cuánta obsolescencia tolera el negocio?** Si la respuesta es "ninguna", no hay caché
   posible: hay que hacer el origen más rápido.
4. **¿Quién invalida y qué pasa si falla?** (§3.3).
5. **¿Sobrevive el sistema sin la caché?** (§6.3).

Sin las cinco respuestas, la caché no está diseñada: está puesta.

### 6.5 Una tasa alta con datos obsoletos es peor que una baja
La tasa de acierto **no es la métrica de éxito**: es la métrica de eficiencia. Una caché que
acierta el 99 % sirviendo datos de hace una hora que debían tener 10 segundos está funcionando
perfectamente **y haciendo daño**, y además lo hace de forma silenciosa: no genera errores, no
dispara alertas y el usuario simplemente ve algo falso. Mide siempre la tasa de acierto **junto
a** la antigüedad servida (`Age`, p95 de obsolescencia) y trata la obsolescencia excesiva como
un defecto de corrección, no de rendimiento.

## 7. Sostenibilidad y prohibiciones

- **Toda caché tiene dueño y fecha de revisión.** Revisa semestralmente: prefijos sin tráfico,
  TTL que nadie recuerda haber elegido, reglas del CDN heredadas de una migración, purgas
  automatizadas contra rutas que ya no existen. Una regla de caché olvidada es deuda activa.
- **La configuración del borde es código**: versionada, revisada y desplegada por IaC, con
  entorno de preproducción propio. Cambiar caché en la consola del proveedor está vetado.
- Documenta en ADR: elección de proveedor de CDN (**puerta de un solo sentido** por el
  acoplamiento del mecanismo de purga y de las funciones de borde), estrategia de invalidación
  y ubicación de cada capa.
- Portabilidad: mantén la lógica de caché de la aplicación **agnóstica del proveedor** y
  concentra lo propietario (surrogate keys, funciones de borde, VCL) en una capa fina y
  aislada, con el coste de salida estimado.

**PROHIBIDO**
- ❌ Añadir una caché sin las cinco respuestas de §6.4. En particular, **cachear para tapar una
  consulta sin índice o un N+1**.
- ❌ Entradas **sin TTL**, o TTL sin jitter en lotes creados a la vez.
- ❌ Invalidación por evento **sin TTL de respaldo**.
- ❌ `noeviction` (o `volatile-*` sin candidatos) en una instancia de caché; instancia **sin
  `maxmemory`**.
- ❌ La caché como **única copia** de un dato de negocio; *write-behind* sin durabilidad propia
  y ADR.
- ❌ Compartir la instancia de caché con colas, locks o contadores de negocio.
- ❌ `KEYS`, `FLUSHALL`/`FLUSHDB` desde la aplicación en producción.
- ❌ Respuesta **autenticada o personalizada** cacheable en una caché compartida; `public` sobre
  contenido que depende de sesión o cookie.
- ❌ `Vary: User-Agent`; `Vary: Cookie` sobre contenido público; omitir un `Vary` necesario.
- ❌ Decidir la cacheabilidad **por la extensión de la URL** en lugar de por la política del
  origen (*cache deception*).
- ❌ Normalización de la clave distinta entre el borde y el origen (envenenamiento por
  discrepancia de analizadores).
- ❌ Datos personales o secretos en la clave de caché, en los logs del borde o en `Cache-Status`
  expuesto públicamente.
- ❌ Diseñar asumiendo **purga instantánea y global** del CDN.
- ❌ Endpoint sin `Cache-Control` explícito ("ya se encarga el framework").
- ❌ Lógica de negocio o acceso a datos en funciones de borde.
- ❌ Configurar el CDN a mano en la consola del proveedor.
- ❌ Presentar la tasa de acierto como métrica de éxito sin la antigüedad servida (§6.5).
- ❌ Fijar versiones, licencias o soporte de directivas **de memoria**, sin §8.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, licencia, directiva o comportamiento de proveedor:

1. **Valkey**: última versión y ramas mantenidas (`api.github.com/repos/valkey-io/valkey/releases`
   — datos crudos, no HTML de la página de releases) y licencia **verbatim** desde el fichero
   `COPYING` en crudo (a agosto 2026: `SPDX-License-Identifier: BSD-3-Clause`, "Copyright (c)
   2024-present, Valkey contributors"; última estable 9.1.1, 2026-07-21).
2. **Redis**: última versión (`api.github.com/repos/redis/redis/releases`; 8.10.0 a 2026-07-29)
   y licencia **verbatim** del `LICENSE.txt` en crudo — a agosto 2026 dice literalmente
   "tri-licensing model": **RSALv2 o SSPLv1 o AGPLv3**, con 7.2 y anteriores bajo BSD-3.
   **Confirma que sigue igual antes de aprobar su uso.**
3. **CVE** de Valkey/Redis por rama (avisos del proyecto, RHSA, ElastiCache) y de los proxies
   de borde que uses (nginx, HAProxy, Varnish, Envoy). En 2026 hubo explotación activa en
   nginx: **es superficie de borde, ventana de parcheo corta**.
4. **Soporte real de `stale-while-revalidate` y `stale-if-error` en tu CDN concreto** — no
   asumas paridad: a agosto 2026, Google Cloud CDN **no** soporta `stale-if-error`, Cloudflare
   hizo su SWR asíncrono en feb-2026 y Safari no implementa SWR en el navegador. Consulta la
   documentación del proveedor, no artículos.
5. **Purga por etiqueta**: comprobar si `draft-ietf-httpbis-cache-groups` ha avanzado a RFC
   (a agosto 2026 seguía en borrador, revisión -07 de may-2025). Mientras no lo sea, **el
   mecanismo es propietario**.
6. **RFC vigentes**: 9111 (caché HTTP), 9110/9110 §condicionales, **9213** (`CDN-Cache-Control`),
   **9211** (`Cache-Status`), **5861** (serve-stale). Verifica que no han sido obsoletados.
7. **Precios y modelo de facturación del CDN elegido** (por GB, cuota fija, cuota + GB, coste de
   *cache fill*, coste por petición) y las **condiciones de uso** del ancho de banda no medido.
   Cambian con frecuencia; modela con datos actuales.
8. **Cadena de suministro**: estado de **CVE-2026-45321 / Mini Shai-Hulud** y qué garantías de
   procedencia siguen siendo válidas para paquetes y funciones de borde.
9. **Huecos declarados** (no verificados en esta redacción — **no rellenar de memoria**):
   - **Comportamiento de `stale-if-error` en Azure Front Door y en Akamai**: no verificado
     contra documentación oficial.
   - **Estado de la protección "Cache Deception Armor" de Cloudflare** y de sus equivalentes en
     otros proveedores: se ha verificado que existieron bypasses documentados, **no** si la
     lista de extensiones protegida está actualizada hoy.
   - **Paridad de módulos Valkey vs Redis Stack** (búsqueda, JSON, vectorial): hay afirmaciones
     de fuentes secundarias, no contrastadas con documentación del proyecto.
   - **Qué serie de Valkey/Redis empaqueta cada distribución** hoy y bajo qué nombre de paquete:
     verificado solo por fuentes secundarias. **Comprueba el binario que realmente tienes.**
   - **Versión mínima exacta de corrección** para cada CVE de Valkey de 2026: las cifras vistas
     proceden de resúmenes de terceros y **deben confirmarse contra el aviso del proyecto**.
   - Cifras de precio por GB de los CDN: proceden de comparativas de terceros, **no** de las
     páginas de precios oficiales.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
