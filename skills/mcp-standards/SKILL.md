---
name: mcp-standards
description: Model Context Protocol server and client engineering. Use when building or auditing an MCP server or client with the official SDKs (modelcontextprotocol typescript-sdk, python-sdk, go-sdk, csharp-sdk, FastMCP), declaring tools/resources/prompts primitives, choosing stdio versus Streamable HTTP transport, protocol-revision fields (server/discover, _meta, Mcp-Method/Mcp-Name headers, resultType, MRTR inputRequests, ttlMs/cacheScope), mcp.json / .mcp.json / claude_desktop_config.json server entries, server.json and the MCP registry, MCP authorization (RFC 9728 protected resource metadata, RFC 8707 resource indicators, Client ID Metadata Documents, PKCE S256), or triaging tool poisoning, rug pull, server shadowing, token passthrough and confused-deputy exposure in installed servers.
---

# Estándares de Model Context Protocol (MCP)

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **diseñar, implementar, auditar u operar servidores y clientes MCP**, y al decidir
si MCP es siquiera la integración correcta. Cubre: el modelo host/cliente/servidor; las
primitivas (`tools`, `resources`, `prompts`) y su estado en la revisión vigente; transportes
(stdio y Streamable HTTP); diseño de la superficie de herramientas de un servidor;
autorización (OAuth 2.1 como *resource server*, RFC 9728, RFC 8707, CIMD); la clase de riesgo
que introduce un servidor de terceros que corre con tus permisos; y el gobierno operativo
(inventario, versionado, actualización, observabilidad).

Triggers por artefacto: `mcp.json`, `.mcp.json`, `claude_desktop_config.json`, `server.json`,
`@modelcontextprotocol/sdk`, `mcp` (PyPI), `FastMCP`, `go-sdk`/`csharp-sdk`,
`tools/list`, `tools/call`, `resources/read`, `prompts/get`, `server/discover`,
`subscriptions/listen`, `inputRequests`/`resultType`, cabeceras `Mcp-Method`/`Mcp-Name`,
`WWW-Authenticate` con `resource_metadata`, `/.well-known/oauth-protected-resource`,
`mcp-scan`, "servidor MCP", "tool poisoning", "rug pull".

**Principio rector**: **un servidor MCP no es una API**. Una API la consume un programa que
valida el contrato; un servidor MCP lo consume un modelo que lee texto y decide. La
descripción de la herramienta **es** superficie de ataque y **es** la especificación funcional.
Diseñar un servidor MCP como si fuera un wrapper de REST produce servidores inservibles
(demasiadas herramientas, salidas gigantes, errores opacos) e inseguros.

**No aplica**: ver
`claude-api` (**la implementación concreta del lado Anthropic**: el conector MCP de la
Messages API, `mcp_servers` + `mcp_toolset`, MCP en Managed Agents con vaults y credenciales
`mcp_oauth`, los helpers `anthropic.lib.tools.mcp`, IDs de modelo, `effort`, caché — todo eso
es **suyo**; aquí está el protocolo y el criterio de diseño, agnósticos de proveedor);
`ai-agents-standards` (el bucle autónomo, presupuesto de iteraciones,
gestión de contexto, multi-agente, tríada letal — MCP es *un* mecanismo para dar herramientas
a un agente, no el único, y un servidor MCP se consume desde muchos hosts que no son agentes
propios; la frontera está en el lado del cliente: **si estás decidiendo qué expone el servidor
y cómo se autoriza, es esta skill; si estás decidiendo cómo el agente elige, itera y para, es
la suya**);
`claude-code-skills-standards` (formato de contexto para agentes: `SKILL.md`, frontmatter,
activación — **frontera relevante**, porque skills y MCP son dos formas distintas de dar
capacidad a un agente: una skill inyecta *instrucciones*, un servidor MCP expone *ejecución*;
una skill no ejecuta nada por sí misma);
`api-design-standards` (**frontera que se confunde a diario**: OpenAPI/GraphQL/gRPC, códigos
HTTP, paginación, versionado del contrato de una API que consume un programa; si el consumidor
es determinista, es suya);
`identity-access-management-standards` (**diseño del IdP**: flujos OAuth 2.1/OIDC, PKCE,
emisión y validación de tokens, motores de autorización — el *uso* de esos flujos en el
protocolo MCP es de esta skill);
`secrets-management-standards` (custodia y rotación de las credenciales que consumen los
servidores MCP), `cryptography-pki-standards` (TLS, firma de artefactos);
`appsec-standards` (clases de vulnerabilidad clásicas: SSRF, path traversal, inyección de
comandos — que es exactamente lo que aparece en los CVE de servidores MCP; el triaje es suyo),
`vulnerability-management-standards` (ciclo de vida CVE/EPSS/KEV de los servidores instalados),
`container-runtime-security-standards` (sandboxing del servidor local: seccomp, capabilities,
rootless), `firewall-policy-standards` (egress del servidor y del host),
`observability-standards` (OpenTelemetry: MCP documenta propagación de `traceparent` en
`_meta`, pero el diseño de la telemetría es suyo),
`detection-engineering-standards` (reglas de detección sobre esa telemetría),
`incident-response-forensics-standards` (respuesta a un servidor comprometido),
`offensive-security-standards` (evaluación ofensiva **autorizada** de un servidor),
`python-standards`/`typescript-standards` (idiomática del lenguaje del SDK),
`cicd-standards` (pipeline que publica y firma el servidor),
`privacy-engineering-standards` / `grc-compliance-standards` (datos personales y gobierno).
`llm-app-engineering-standards` (la app de LLM de un turno o pipeline
determinista — prompting, salida estructurada, ventana de contexto, coste por petición).
Además: `rag-standards`, `llm-evaluation-standards`, `mlsecops-standards`,
`ai-governance-standards`.

## 2. Decisiones por defecto

> Verificar la revisión vigente por web antes de fijar nada (§8). **Este protocolo cambia por
> revisión fechada y la de 2026-07-28 rompió cosas grandes**: los datos siguientes caducan.

| Decisión | Por defecto | Motivo / alternativa |
|---|---|---|
| Revisión del protocolo | **`2026-07-28`** (final, publicada 28-jul-2026; sustituye a `2025-11-25`) | Las versiones son fechas `YYYY-MM-DD` que marcan el último cambio incompatible. Fijar la revisión explícitamente; no "la última" |
| Transporte local | **stdio** | Un proceso hijo del host; sin puerto abierto, sin superficie de red. Por defecto para todo servidor que corra en la máquina del usuario |
| Transporte remoto | **Streamable HTTP** | El HTTP+SSE original está **deprecado desde `2025-03-26`** y reclasificado como *Deprecated* bajo la política de ciclo de vida en `2026-07-28`. No se implementa en código nuevo |
| Estado del servidor | **Sin estado** | `2026-07-28` elimina las sesiones de protocolo y la cabecera `Mcp-Session-Id`; el estado entre llamadas se lleva en *handles* explícitos acuñados por el servidor y pasados como argumento de herramienta |
| ¿Servidor MCP o función normal? | **Función normal** si es **una** integración propia consumida por **un** host propio | MCP resuelve M×N → M+N. Con M=1 y N=1 solo añade proceso, transporte, superficie de ataque y una capa de traducción |
| Autorización remota | **OAuth 2.1 con PKCE (S256)**; el servidor MCP es **solo *resource server*** | Nunca emitir tokens desde el servidor MCP. RFC 9728 (metadatos de recurso protegido) + RFC 8707 (`resource`) obligatorios |
| Registro de cliente OAuth | **Client ID Metadata Documents (CIMD)** | Dynamic Client Registration (RFC 7591) está **deprecado** en `2026-07-28`; bajó de SHOULD a MAY en `2025-11-25`. DCR solo por compatibilidad con AS que no soporten CIMD |
| Número de herramientas por servidor | **Pocas y orientadas a tarea** (orden de unidades, no decenas) | Cada definición ocupa contexto en cada turno y compite por la atención del modelo. Exponer una API entera es el antipatrón más común |
| Esquemas | `inputSchema` estricto con `additionalProperties: false`, `required` explícito y `enum` donde aplique | El modelo rellena lo que el esquema permita. Un esquema laxo es una invitación a llamadas mal formadas |
| Salida de herramienta | **Acotada y paginada**; límite duro de tamaño en el servidor | Una herramienta que devuelve 200 KB envenena el contexto del host y arruina la caché de prompt |
| SDK | **Tier 1**: TypeScript, Python, C#, Go | Tier 2: Java, Rust, Ruby. Tier 3: Swift, PHP, Kotlin. Verificar la tabla de tiers antes de comprometer un lenguaje |
| Registro de servidores | Registro oficial **en preview**, no GA | `registry.modelcontextprotocol.io` sigue advirtiendo de posibles *breaking changes* y reseteos de datos. No es una cadena de confianza: **no valida seguridad**. Usar registro interno/curado para producción |
| Instalación de servidores de terceros | **Auditar + fijar versión por digest** | Un servidor MCP es ejecución arbitraria con tus permisos (§5) |

### Primitivas y su estado (revisión `2026-07-28`)

Quién controla qué es la mitad del diseño:

| Primitiva | Quién la controla | Estado |
|---|---|---|
| **Tools** (`tools/list`, `tools/call`) | **El modelo** decide invocarla | Activa. Es el 90 % de lo que se construye |
| **Resources** (`resources/list`, `resources/read`) | **La aplicación** las aporta al contexto | Activa. `resources/subscribe`/`unsubscribe` sustituidos por `subscriptions/listen` |
| **Prompts** (`prompts/list`, `prompts/get`) | **El usuario** las elige (menú, slash-command) | Activa. Poco adoptada por los clientes: verificar soporte del host antes de apoyarse en ellas |
| **Sampling** (`sampling/createMessage`) | Servidor → cliente | **DEPRECADA** en `2026-07-28`. Migración sugerida: integrar directamente con la API del proveedor del LLM |
| **Roots** (`roots/list`) | Servidor → cliente | **DEPRECADA**. Migración: pasar directorios/ficheros como parámetros de herramienta, URIs de recurso o configuración del servidor |
| **Logging** (`logging/setLevel`) | Servidor → cliente | **DEPRECADA**. Migración: `stderr` en stdio, u OpenTelemetry |
| **Elicitation** | Servidor → cliente | Reemplazada por el patrón **MRTR** (Multi Round-Trip Requests): el servidor devuelve `resultType: "input_required"` con `inputRequests`, y el cliente reintenta la petición original con `inputResponses` |

**Consecuencia de diseño**: no construyas nada nuevo sobre sampling, roots ni logging —
siguen funcionando durante la ventana de deprecación (mínimo 12 meses por la política de
ciclo de vida), pero son deuda desde el día uno. Si un diseño "necesita" sampling, casi
siempre lo que necesita es que el **host** haga la llamada al modelo.

## 3. Estructura y convenciones

### Diseño de la superficie de herramientas

- **Una herramienta = una tarea del usuario**, no un endpoint. `create_issue_with_labels` es
  mejor que `POST /issues` + `POST /issues/{id}/labels` expuestos por separado: menos turnos,
  menos estados intermedios, menos oportunidades de error.
- **La descripción dice *cuándo* llamarla, no solo qué hace.** «Consulta el estado de un
  despliegue. Úsala cuando el usuario pregunte si un cambio ya está en producción o por qué
  falló un release; **no** la uses para listar despliegues históricos — para eso, `list_deploys`.»
  Descripciones puramente declarativas producen infra-invocación en unos modelos y
  sobre-invocación en otros.
- **Nombres estables y con espacio de nombres propio** (`acme_deploy_status`). Colisiones de
  nombre entre servidores son la puerta de entrada del *shadowing* (§5).
- **Orden determinista** en `tools/list`: la revisión vigente recomienda devolver las
  herramientas en orden estable para que el cliente cachee y mejore el *hit rate* de la caché
  de prompt del modelo. Un orden aleatorio (iterar un `set`, un `dict` sin ordenar) invalida
  la caché en cada turno.
- **Errores que el modelo pueda recuperar**: texto accionable, no un stack trace ni un
  `500 Internal Server Error`. «El repositorio `x/y` no existe o no tienes acceso. Comprueba
  el nombre o usa `list_repos`.» El modelo reintenta bien con un mensaje así y entra en bucle
  con uno opaco.
- **Salidas acotadas por diseño**: paginación con cursor, truncado explícito y anunciado
  («mostrando 20 de 431; usa `cursor` para continuar»), y proyección de campos. Nunca
  devolver el objeto completo del sistema de origen «por si acaso».
- **Idempotencia y efectos**: marca en la descripción qué herramientas mutan estado y cuáles
  no; el host usa esa distinción para paralelizar las de lectura y pedir aprobación en las de
  escritura.

### Fichero de configuración y publicación

- Entradas de servidor en `mcp.json` / `.mcp.json` / configuración del host: **versión fijada**
  (digest de imagen o versión exacta de paquete), nunca `latest` ni una rama.
- `server.json` para publicación en el registro: metadatos e instrucciones de instalación; los
  artefactos siguen viviendo en npm/PyPI/OCI, con la cadena de suministro de esos registros
  (y sus riesgos — §5).
- **Versionar el servidor** con SemVer y declarar la revisión de protocolo soportada. Cambiar
  el esquema o la semántica de una herramienta existente es un cambio incompatible **para el
  modelo** aunque el JSON siga validando.

### Novedades de `2026-07-28` que afectan al código

- No hay handshake `initialize`/`notifications/initialized`: cada petición lleva versión de
  protocolo y capacidades del cliente en `_meta`.
- `server/discover` es **obligatorio** en el servidor para anunciar versiones soportadas,
  capacidades e identidad.
- Cabeceras `Mcp-Method` y `Mcp-Name` obligatorias en POST sobre Streamable HTTP — permiten a
  gateways, rate limiters y WAF enrutar y medir sin parsear el cuerpo. El servidor rechaza
  peticiones donde cabecera y cuerpo discrepan.
- `ttlMs` y `cacheScope` (`public`/`private`) obligatorios en los resultados de `tools/list`,
  `prompts/list`, `resources/list`, `resources/read` y `resources/templates/list`.
- Se elimina la reanudación de stream SSE (`Last-Event-ID`): un stream roto pierde la petición
  en vuelo y **el cliente debe reemitirla con un ID nuevo** — lo que exige idempotencia real
  en las herramientas de escritura.
- `resultType` obligatorio en todo resultado (`"complete"` o `"input_required"`).
- Tasks pasa de núcleo experimental a **extensión oficial** (`io.modelcontextprotocol/tasks`).

## 4. Calidad y gates

Gates en orden de coste creciente. Los marcados **[BLOQUEA]** rompen el build o el despliegue.

1. **[BLOQUEA] Validación de esquema**: todos los `inputSchema` con `additionalProperties: false`
   y `required` explícito. Un test que recorra `tools/list` y lo verifique.
2. **[BLOQUEA] Presupuesto de salida**: test que ejercita cada herramienta con la entrada más
   voluminosa razonable y falla si la respuesta supera el límite fijado (elige uno y
   documéntalo; el orden de magnitud útil son pocos miles de tokens, no cientos de miles).
3. **[BLOQUEA] Sin *token passthrough***: test que envía al servidor un token cuyo `aud` no es
   el servidor y comprueba que se **rechaza**. La especificación lo prohíbe con un MUST NOT
   explícito: *"MCP servers **MUST NOT** accept any tokens that were not explicitly issued for
   the MCP server."*
4. **[BLOQUEA] Autorización remota**: `/.well-known/oauth-protected-resource` (RFC 9728)
   servido y correcto; validación de audiencia; PKCE S256; validación del parámetro `iss` en
   la respuesta de autorización (RFC 9207) antes de canjear el código.
5. **[BLOQUEA] SCA + escaneo del artefacto** del servidor y de sus dependencias transitivas.
6. **Conformidad de protocolo**: `server/discover` responde; cabeceras `Mcp-Method`/`Mcp-Name`
   verificadas contra el cuerpo; `resultType` presente; `ttlMs`/`cacheScope` presentes.
7. **Determinismo de `tools/list`**: test que llama dos veces y compara el orden byte a byte.
8. **Prueba de bordes y errores**: entrada inválida, recurso inexistente, permiso denegado,
   timeout del sistema de origen — cada uno devuelve un error accionable, no un volcado.
9. **Prueba con un modelo real**: un servidor puede ser correcto y aun así inservible. Ejecuta
   un conjunto de tareas de extremo a extremo y mide **tasa de éxito de la tarea**, no
   cobertura de la API. Si el modelo elige mal la herramienta, el defecto está en la
   descripción, no en el modelo.
10. **Auditoría de descripciones** (`mcp-scan` o equivalente) sobre los servidores que
    instalas: detección de instrucciones embebidas y de solapamiento entre servidores.
11. **Fijación de definiciones**: hash de cada definición de herramienta al aprobarla y alerta
    cuando cambie (mitigación directa del *rug pull*, §5).

## 5. Seguridad — la sección crítica

**Premisa**: **un servidor MCP es código de terceros que corre con tus permisos.** Un servidor
local es un binario que ejecutas; uno remoto es un servicio al que le entregas contexto y
credenciales. La especificación es explícita: sin sandboxing y consentimiento, la instalación
en un clic permite *arbitrary code execution* con los privilegios del cliente, y advierte de
que *"Users have no insight into what commands are being executed."*

Todo lo que sigue es **clase de riesgo, indicador y mitigación**. Nada aquí es procedimiento
de explotación.

### Clases de riesgo propias de MCP

| Clase | Qué es | Indicador | Mitigación |
|---|---|---|---|
| **Tool poisoning** | Instrucciones para el modelo escondidas en la descripción, el esquema o el resultado de una herramienta. El usuario ve un nombre corto; el modelo lee el texto completo y lo obedece. **No hace falta invocar la herramienta**: basta con que esté cargada en contexto | Descripciones desproporcionadamente largas, texto imperativo dirigido al asistente, caracteres invisibles o de control, referencias a otras herramientas o a ficheros del usuario | Revisión humana de cada descripción antes de aprobar; escaneo automatizado; renderizar la descripción **completa** en la UI de aprobación, sin truncar |
| **Rug pull** | El servidor cambia la descripción **después** de que confiaste en él. La mayoría de clientes no avisan del cambio | Hash de la definición distinto al aprobado | Fijar versión por digest; hashear definiciones y **fallar cerrado** ante un cambio; re-aprobación explícita |
| **Shadowing entre servidores** | La descripción de un servidor malicioso altera el comportamiento del agente con herramientas de **otro** servidor de confianza. Combinado con rug pull, secuestra sin aparecer en el log visible | Nombres de herramienta colisionantes; una descripción que menciona herramientas ajenas | Espacios de nombres por servidor; aislar servidores por nivel de confianza; no mezclar servidores de terceros con herramientas sobre datos sensibles en la misma sesión |
| **Confused deputy** | Un proxy MCP con `client_id` estático ante el AS de terceros, registro dinámico de clientes y cookie de consentimiento permite obtener códigos de autorización **saltándose el consentimiento del usuario** | Proxy MCP que no guarda consentimiento por `client_id` | La especificación lo exige: *"MCP proxy servers **MUST** implement per-client consent"* — registro de `client_id` aprobados por usuario, comprobado **antes** de reenviar al AS de terceros; `redirect_uri` validada por coincidencia exacta; `state` de un solo uso creado **solo tras** aprobar el consentimiento |
| **Token passthrough** | El servidor acepta y reenvía tokens no emitidos para él | Ausencia de validación de `aud` | MUST NOT de §4.3; RFC 8707 `resource` en petición de autorización **y** de token |
| **State handle hijacking** | Con el protocolo sin estado, quien adivina u obtiene un *handle* accede al estado de otro usuario | Handles secuenciales o predecibles | *"MCP servers **MUST NOT** treat possession of a state handle as authentication."* Handles aleatorios seguros, ligados al usuario autenticado del lado servidor (`<user_id>:<handle>`), con expiración |
| **SSRF en el cliente** | El servidor malicioso publica URLs de descubrimiento OAuth apuntando a `169.254.169.254`, `localhost` o rangos privados | Peticiones del cliente a IPs internas | Exigir HTTPS, bloquear rangos privados/reservados/link-local, validar destinos de redirección, proxy de egress. **No implementar la validación de IP a mano** — los trucos de codificación (octal, hex, IPv4-mapped IPv6) se escapan |
| **Esquema de URL peligroso** | URL de autorización `javascript:`, `data:`, `file:` desde el servidor → XSS/RCE en el cliente | — | Allowlist `http`(loopback)/`https`; **nunca** abrir URLs vía shell |
| **Compromiso de la cadena de suministro** | Servidor troyanizado publicado en un registro con cuentas y personas creadas para dar apariencia de legitimidad; el registro oficial **no es una cadena de confianza** y sigue en preview | Paquete nuevo, mantenedor sin historial, sin repositorio verificable | Registro interno curado; revisión del código; fijación por digest; SBOM y firma; inventario de lo instalado |

### Reglas duras

- **PROHIBIDO instalar un servidor MCP de terceros sin auditar**: código, dependencias,
  mantenedor y permisos que pide. Es la misma decisión que instalar un binario.
- **stdio por defecto para servidores locales**; si hay transporte HTTP local, exigir token de
  autorización o socket unix con permisos restringidos. Un servidor local escuchando en
  localhost sin auth es alcanzable por DNS rebinding desde el navegador.
- **Sandboxing del servidor local**: contenedor o sandbox de plataforma, sistema de ficheros
  restringido a los directorios necesarios, sin red salvo la imprescindible, no-root. La
  especificación lo lista como SHOULD del cliente; trátalo como requisito propio.
- **Mínimo privilegio en las credenciales del servidor**: token con el alcance de la tarea, no
  el del administrador. La especificación desaconseja explícitamente *scopes* ómnibus
  (`*`, `all`, `full-access`) y publicar el catálogo completo en `scopes_supported`.
- **Consentimiento informado y por acción sensible**, no un «permitir todo» al instalar: el
  usuario debe ver el comando exacto sin truncar, qué se ejecuta y con qué privilegios. Un
  diálogo que trunca la descripción de la herramienta convierte el consentimiento en teatro.
- **Nunca** poner secretos en descripciones, prompts, recursos ni resultados: acaban en el
  contexto del modelo, en el historial y potencialmente en logs y resúmenes.
- El servidor **no puede confiar** en que el cliente aplique ninguna mitigación: valida en su
  propio borde.

### Realidad de la adopción (dato de contexto, no excusa)

La adopción de autorización en servidores MCP públicos es **baja** —del orden de un dígito
porcentual según análisis del ecosistema en 2026, y una fracción significativa de los
servidores registrados no ofrece autenticación efectiva. Traducción operativa: **asume que un
servidor público cualquiera está sin autenticar y mal mantenido hasta demostrar lo contrario.**
El volumen de CVE contra implementaciones MCP durante 2026 es alto, y las clases dominantes
son clásicas —path traversal, inyección de comandos, autenticación ausente en un endpoint
hermano— no exóticas: ver `appsec-standards` para el triaje.

## 6. Rendimiento y operabilidad

- **Inventario obligatorio** de servidores MCP instalados por host y por usuario: origen,
  versión fijada, credenciales que consume, permisos que tiene, quién lo aprobó y cuándo.
  Sin inventario no hay respuesta a incidentes ni gestión de vulnerabilidades. El *shadow MCP*
  —servidores instalados fuera del control de cambios— es el fallo de gobierno más común.
- **Observabilidad de invocaciones**: qué herramienta, de qué servidor, con qué argumentos
  (con los sensibles redactados), qué resultado, qué latencia, qué coste en tokens. La
  revisión vigente documenta la propagación de contexto de traza W3C/OpenTelemetry en `_meta`
  (`traceparent`, `tracestate`, `baggage`): úsala para correlacionar la llamada del modelo con
  la ejecución en el servidor y con la petición al sistema de origen.
- **Caché**: respetar `ttlMs` y `cacheScope`; `cacheScope: "private"` **nunca** se cachea en un
  intermediario compartido. Un `tools/list` con orden inestable rompe la caché de prompt del
  host y encarece cada turno.
- **Presupuesto de contexto**: el coste de un servidor no es solo su latencia; son los tokens
  que sus definiciones ocupan en **cada** turno. Medir ese coste y podar herramientas que no
  se usan.
- **Sin estado por diseño** (`2026-07-28`): un servidor remoto debe poder correr detrás de un
  balanceador round-robin sin sesiones pegajosas. Si el tuyo necesita afinidad, el estado está
  mal modelado.
- **Timeouts y límites** en toda llamada al sistema de origen; degradación con error accionable
  en vez de colgar el turno del modelo.
- **Actualización**: cadencia definida, changelog leído (no aplicado a ciegas — un update es un
  vector de rug pull), y re-aprobación cuando cambien definiciones de herramienta.

## 7. Sostenibilidad y prohibiciones

- **Cadencia de revisión**: este ecosistema se mueve por revisión fechada con ventana de
  deprecación mínima de 12 meses. Revisar la revisión de protocolo y las deprecaciones **cada
  trimestre**, no cada año.
- **Política de deprecación del propio servidor**: no romper la semántica de una herramienta
  existente; añadir una nueva y marcar la vieja. El "consumidor" es un modelo con prompts y
  evaluaciones construidos encima.

**PROHIBIDO**
- ❌ Montar un servidor MCP para **una** integración propia consumida por **un** host propio: es una función.
- ❌ Exponer una API entera como herramientas MCP, endpoint por endpoint.
- ❌ Descripciones de herramienta que solo dicen qué hace la herramienta y no **cuándo** usarla.
- ❌ Esquemas laxos: sin `additionalProperties: false`, sin `required`, con `string` libre donde cabe un `enum`.
- ❌ Herramientas con salida no acotada.
- ❌ Errores opacos (`500`, stack trace) devueltos al modelo.
- ❌ Implementar HTTP+SSE en código nuevo (deprecado desde `2025-03-26`).
- ❌ Construir sobre **sampling**, **roots** o **logging**: deprecadas en `2026-07-28`.
- ❌ Que el servidor MCP actúe como *authorization server* o emita tokens.
- ❌ Aceptar o reenviar tokens no emitidos para el servidor (**MUST NOT** de la especificación).
- ❌ Tratar la posesión de un *state handle* como autenticación.
- ❌ Dynamic Client Registration en código nuevo: usar CIMD.
- ❌ Instalar servidores de terceros sin auditar, o desde registros no verificados.
- ❌ `latest` / rama / paquete sin fijar en la configuración de un servidor.
- ❌ Servidor local con transporte HTTP sin autenticación.
- ❌ Ejecutar un servidor local sin sandbox y con acceso amplio al sistema de ficheros.
- ❌ Diálogo de consentimiento que trunca la descripción o el comando: es teatro de seguridad.
- ❌ Secretos en descripciones, prompts, recursos o resultados.
- ❌ Tratar el registro oficial como cadena de confianza o como GA.
- ❌ Aceptar la actualización de un servidor sin revisar cambios en las definiciones de herramienta.
- ❌ Confiar en que el cliente aplique las mitigaciones: el servidor valida en su borde.

## 8. Verificación web obligatoria

Antes de fijar cualquier versión, nombre de campo, primitiva o requisito normativo:

1. **Revisión vigente de la especificación** (`modelcontextprotocol.io/specification/...`) y su
   *changelog*: las versiones son fechas y la de `2026-07-28` eliminó sesiones, handshake,
   `ping`, `logging/setLevel` y la reanudación de stream. Comprobar si hay una posterior.
2. **Registro de features deprecadas** (`/specification/<rev>/deprecated`) y política de ciclo
   de vida: sampling, roots y logging están en ventana de deprecación — confirmar si ya se
   han **removido**.
3. **Especificación de autorización**: se ha revisado varias veces. Confirmar el estado de
   RFC 9728, RFC 8707, PKCE S256, validación de `iss` (RFC 9207) y el estado exacto de CIMD
   frente a DCR.
4. **Página de Security Best Practices** de la revisión vigente: es la fuente normativa de los
   MUST/MUST NOT citados en §5. Citar **verbatim** cualquier requisito que decida algo.
5. **Tabla de tiers de SDK** (`/docs/sdk` y `/community/sdk-tiers`): los tiers cambian.
6. **Estado del registro oficial**: sigue en preview a agosto 2026 — verificar si ha llegado a GA
   y qué garantías da.
7. **CVE e incidentes** en los servidores concretos que vayas a instalar (no en "MCP" en
   abstracto): NVD/GHSA por paquete, más el historial del mantenedor.
8. **Estado de las extensiones** (`tasks`, MCP Apps) y de proyectos vecinos (A2A bajo Linux
   Foundation) si el diseño depende de ellos.

### Huecos declarados (no verificados en esta redacción)

- **Cifras exactas de CVE e IDs concretos de vulnerabilidades de servidores MCP en 2026**: se
  describen como clase y volumen agregado a partir de fuentes secundarias; **no se fijan IDs
  ni CVSS aquí**. Verificar en NVD/GHSA antes de citar ninguno.
- **Porcentaje exacto de servidores públicos con OAuth implementado** y tamaño del registro:
  dato de fuente secundaria, orden de magnitud únicamente.
- **Detalle de la extensión `io.modelcontextprotocol/tasks` y de MCP Apps**: no verificado en
  profundidad; consultar la documentación de extensiones antes de diseñar sobre ellas.
- **Estado de `mcp-scan` y demás herramienta de auditoría de descripciones**: se cita como
  categoría; no se ha verificado su mantenimiento actual.
- **"MCP Top 10" de OWASP**: mencionado por fuentes secundarias como proyecto separado; no
  verificado contra la fuente primaria de OWASP.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
