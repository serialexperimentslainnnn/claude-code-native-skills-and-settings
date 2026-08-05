---
name: ai-agents-standards
description: Autonomous agent engineering, provider-agnostic. Use when choosing between an autonomous agent loop and a deterministic workflow, designing an agent's tool surface and tool descriptions, bounding the agent loop (max iterations, token and wall-clock budgets, stop criteria, unproductive-loop detection), compacting or pruning stale tool results and file-backed agent memory, orchestrating coordinator/worker subagent fan-out, building on LangGraph, CrewAI, OpenAI Agents SDK, Pydantic AI, Google ADK or Microsoft Agent Framework, human approval gates for irreversible tool calls, agent sandboxing and egress containment, end-to-end agent success rate and per-task cost tracing, or the lethal trifecta and the OWASP ASI01-ASI10 agentic risks.
---

# Estándares de agentes autónomos

Criterios verificados a **agosto 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica al **decidir, diseñar, acotar, asegurar, evaluar y operar un agente autónomo**: un
sistema donde un modelo elige en bucle qué herramientas invocar hasta considerar la tarea
terminada. Cubre la pregunta previa (¿necesitas un agente?), la escalera de simplicidad,
el diseño de la superficie de herramientas, el control del bucle, la gestión de contexto en
ejecución larga, multi-agente, seguridad, evaluación y operación. **Agnóstico de proveedor**:
patrones, criterio y gobierno.

Triggers: "agente autónomo", "agentic loop", bucle `while stop_reason == tool_use`,
`max_iterations`/`max_turns`/`recursion_limit`, presupuesto de tokens o de tiempo por tarea,
compactación y poda de resultados de herramienta, memoria persistente del agente,
coordinador y subagentes, aprobación humana de acciones irreversibles, sandbox de ejecución
del agente, `LangGraph`/`create_agent`/`StateGraph`, `CrewAI`, `OpenAI Agents SDK`,
`Pydantic AI`, `Google ADK`, `Microsoft Agent Framework`, "tríada letal", "prompt injection
indirecta", `OWASP ASI01`–`ASI10`, traza y coste por tarea.

**No aplica**: ver
`claude-api` (**la implementación concreta con Anthropic**: el *tool runner* del SDK y sus
*hooks* por turno, Managed Agents y su bucle alojado, `mcp_servers` + `mcp_toolset`, Agent
Skills, IDs de modelo, `effort`, `task_budget`, compactación y context editing del API,
caché de prompt, el Claude Agent SDK — **todo eso es suyo**; aquí está el criterio agnóstico:
cuándo un agente, cómo diseñar la superficie de herramientas, cómo acotar el bucle y cómo
asegurarlo. Si la tarea nombra Claude/Anthropic o pide código concreto, es la suya);
`mcp-standards` (**Ola 3, escrita**: el protocolo MCP —primitivas, transportes, autorización,
diseño y seguridad de un servidor. **MCP es *un* mecanismo para dar herramientas a un agente,
no el único**: función local, API HTTP, subproceso y SDK del proveedor son igual de válidos, y
un servidor MCP se consume desde muchos hosts que no son agentes propios. La frontera: si
decides **qué expone y cómo se autoriza el servidor**, es la suya; si decides **cómo el agente
elige, itera y para**, es esta);
`claude-code-skills-standards` (cómo se escribe una skill de Claude Code: es formato de
**contexto** para un agente. Una skill inyecta instrucciones; una herramienta ejecuta. No
confundir «darle criterio al agente» con «darle capacidad»);
`llm-app-engineering-standards` (**existe, Ola 3** — **frontera clave**: la app de LLM de un
turno o de *pipeline determinista*: prompting y plantillas versionadas, salida estructurada y
su validación, elección y enrutado de modelo, ventana de contexto y caché de prefijo,
streaming y cancelación, reintentos y límites de gasto, testing de lo no determinista. **El
bucle autónomo es de esta skill**; en cuanto el modelo decide *cuántos* pasos dar y *cuáles*,
cruzas la línea. El vocabulario compartido —`prompt injection`, `context`, `llm`— es inherente
al dominio, no reclamación del mismo trabajo: la inyección de prompt aquí se trata como
**secuestro del objetivo de un agente con herramientas y permisos** (tríada letal, ASI01),
allí como **entrada no confiable de una llamada**);
`rag-standards` (**Ola 3, planificada**: chunking, embeddings, recuperación híbrida, reranking
— aquí la recuperación aparece solo como *una herramienta más* del agente),
`llm-evaluation-standards` (**Ola 3, planificada**: metodología de evaluación, LLM-as-judge,
datasets — aquí solo qué métricas de agente importan y por qué las demos engañan),
`mlsecops-standards` / `ai-governance-standards` / `mlops-standards` / `local-inference-standards`
/ `gpu-computing-standards` (**Ola 3, planificadas**).
Además: `appsec-standards` (STRIDE y clases de vulnerabilidad clásicas — la inyección de
prompt **no** es una de ellas y no se mitiga con las mismas técnicas),
`identity-access-management-standards` (identidad del agente como principal, tokens de vida
corta, elevación JIT), `secrets-management-standards` (custodia de las credenciales que usa),
`container-runtime-security-standards` (sandbox de lo que el agente ejecuta),
`rpa-workflow-automation-standards` (**un agente que pulsa botones es RPA**: hereda de allí la
identidad propia del robot, la bóveda de credenciales, la cola de trabajo, la idempotencia ante
fallo parcial y la parada — no se rediseña aquí),
`firewall-policy-standards` (egress del agente: la pata de comunicación de la tríada letal),
`kubernetes-standards`, `observability-standards` (los tres pilares y OpenTelemetry),
`sre-practice-standards` (SLO, error budget, operación), `detection-engineering-standards`
(detecciones sobre la traza del agente), `incident-response-forensics-standards` (respuesta
cuando el agente hace daño), `offensive-security-standards` (**red teaming de agentes: el
ejercicio autorizado con RoE es suyo**), `vulnerability-management-standards`,
`privacy-engineering-standards`, `grc-compliance-standards` (NIST AI RMF, ISO/IEC 42001, EU AI
Act), `python-standards`/`typescript-standards`, `cicd-standards`, `api-design-standards`,
`ai-agent-workflow-standards` (**Ola 6 — el par de colisión más fuerte de esta skill, arbitraje
explícito**: **construir un sistema agéntico es de aquí** —bucle, herramientas, memoria, contexto,
evaluación, despliegue y operación del agente como producto—; **trabajar con agentes de codificación
en un equipo de ingeniería es suyo** —qué tarea se le da a un agente y cuál no, ficheros de
instrucciones del repositorio, alcance de permisos y credenciales en la estación y en CI, revisión
del diff generado, y quién responde del cambio—. Regla corta: **si el agente es el producto, es de
aquí; si el agente es la herramienta con la que se construye el producto, es suya**).

## 2. Decisiones por defecto

> Verificar versiones y estado de los frameworks por web antes de fijarlos (§8). Este
> ecosistema se movió más en el primer semestre de 2026 que en todo 2025.

### 2.1 La pregunta previa: ¿necesitas un agente?

**Es la decisión más importante del documento y casi siempre la respuesta es no.** Cuatro
criterios; **si falla uno, baja un escalón**:

| Criterio | Pregunta honesta | Falla si… |
|---|---|---|
| **Complejidad real** | ¿Los pasos son *imposibles de especificar de antemano* porque dependen de lo que se encuentre por el camino? | Puedes dibujar el diagrama de flujo. Entonces impleméntalo: es un workflow |
| **Valor** | ¿El resultado justifica coste **y latencia**? Un bucle son N llamadas al modelo con contexto creciente | El ahorro no cubre el gasto, o el usuario espera respuesta en segundos |
| **Viabilidad** | ¿El modelo hace bien esta tarea *hoy*, medido, no supuesto? | No lo has medido. Mídelo antes |
| **Coste del error recuperable** | Si se equivoca, ¿se detecta y se revierte? (tests, revisión, rollback, transacción) | El error es silencioso o irreversible. **Sin recuperación no hay autonomía**: hay aprobación humana o no hay agente |

### 2.2 La escalera de simplicidad

Sube un escalón solo cuando el anterior demuestre no bastar. **Cada escalón añade coste,
latencia, no-determinismo y superficie de ataque.**

| Escalón | Qué es | Cuándo |
|---|---|---|
| **1. Una llamada** | Prompt → respuesta | Clasificar, extraer, resumir, reescribir, responder |
| **2. Cadena determinista** | Varias llamadas encadenadas con lógica **tuya**; el modelo no elige el flujo | Pipeline conocido: extraer → validar → transformar. Depurable, cacheable, testeable |
| **3. Workflow con herramientas** | El modelo elige *dentro* de un grafo que tú controlas: enrutado, ramas, número de pasos acotado | La mayoría de lo que se llama "agente" en producción **debería quedarse aquí** |
| **4. Agente** | Bucle autónomo: el modelo decide cuántos pasos, cuáles y cuándo parar | Solo cuando 1–3 no bastan y los cuatro criterios de §2.1 se cumplen |

**Regla**: el bucle autónomo es la opción **cara y no determinista**. Se elige cuando las
alternativas no bastan, nunca por defecto ni por moda. Un workflow con un buen grafo gana
casi siempre en coste, latencia, depurabilidad y auditabilidad.

### 2.3 Frameworks (agosto 2026)

| Framework | Estado | Criterio |
|---|---|---|
| **LangGraph** | 1.x estable (1.0 en oct-2025; 1.1 en mar-2026). Python ≥3.10 | Default para workflows con estado en producción: grafo explícito, ejecución duradera, checkpointing y *time travel*. Es el que mejor encaja con auditoría y rollback |
| **Pydantic AI** | v2 (jun-2026) | Mejor opción cuando la prioridad es tipado y validación con orquestación ligera. Pydantic ya es la capa de esquema dentro de varios de los demás |
| **OpenAI Agents SDK** | Activo, minimalista | Abstracción central: *handoff* entre agentes. **Acoplado a modelos OpenAI** |
| **Google ADK** | 2.0 (Python, Go, TypeScript) | Si el stack es Google Cloud/Vertex |
| **Microsoft Agent Framework** | 1.0 GA (abr-2026), Python y .NET | Convergencia de Semantic Kernel + AutoGen. Si el stack es Azure |
| **CrewAI** | Activo | Prototipado rápido con *crews* por rol. Curva baja; peor perfil de latencia. No es mi default para producción |
| **AutoGen / AG2** | **Modo mantenimiento** | ❌ No usar en proyectos nuevos. Existentes: migrar (LangGraph es el encaje arquitectónico más cercano) |
| **Semantic Kernel** | Soportado para lo existente | Trabajo nuevo de agentes → Microsoft Agent Framework |
| Harness del proveedor | Varía | Un harness "con pilas incluidas" del proveedor del modelo (herramientas integradas, bucle, permisos) es la vía más rápida cuando ya estás acoplado a ese proveedor. **Coste**: acoplamiento. Ver la skill del proveedor |
| **Sin framework** | Siempre válido | Un bucle `while` de 40 líneas con tus herramientas es depurable y sin dependencias. Empieza aquí para entender el problema antes de elegir framework |

**Escepticismo obligatorio**: elegir por estrellas de GitHub o por marketing es el error
recurrente. Los ejes que deciden son **coste medido, fiabilidad, y observabilidad**.

### 2.4 Interoperabilidad entre agentes

**A2A** (Agent2Agent) está bajo la Linux Foundation desde 2025, con v1.0 estable, SDKs en
varios lenguajes y adopción en las tres grandes nubes. Es complementario a MCP, no
alternativo: **A2A entre agentes de plataformas distintas; MCP para el acceso a herramientas
de un agente**. Adóptalo solo si el problema real es cooperación entre agentes de *distintas
organizaciones o plataformas*; para subagentes propios es complejidad gratuita.

## 3. Estructura y convenciones

### 3.1 Diseño de la superficie de herramientas

Es donde se gana o se pierde la calidad de un agente, más que en el prompt.

**Qué se expone como herramienta y qué no.** Una herramienta **dedicada** da al *harness* un
punto de intercepción **tipado**: puede pedir aprobación, auditar el argumento concreto,
renderizarlo en la UI, decidir si es paralelizable y rechazarlo por política. Un `bash`
genérico da al harness **una cadena opaca, idéntica para toda acción**: no distingue un
`grep` (paralelizable, inocuo) de un `git push` (irreversible). Criterio:

| Promueve a herramienta dedicada cuando… | Motivo |
|---|---|
| La acción es **difícil de revertir** (enviar correo, borrar, pagar, desplegar) | Es el punto donde va la aprobación humana |
| Necesitas **auditar el argumento**, no el comando | «envió correo a X» es auditable; `curl -X POST ...` no |
| Necesitas **renderizado propio** (pregunta al usuario, diff, confirmación) | El harness necesita bloquear el bucle y mostrar UI |
| Quieres **paralelizar** lecturas con seguridad | Solo puedes marcar como paralelizable lo que reconoces |
| Hay un **invariante que imponer** (no escribir un fichero cambiado desde la última lectura) | `bash` no puede imponerlo |

Regla práctica: **empieza con `bash` por amplitud, promueve a herramienta dedicada lo que
necesites controlar.** Y si tu política de seguridad exige control, `bash` no es una opción:
concédelo o no lo concedas, pero no pretendas gobernarlo con expresiones regulares sobre la
cadena.

**Descripciones que digan *cuándo*.** El modelo elige leyendo la descripción. Una que solo
dice *qué hace* produce infra o sobre-invocación según el modelo. Escribe la condición de
disparo, y la de no-disparo: «Úsala cuando… No la uses para… — para eso, `otra_tool`.»

**Número de herramientas y su coste.** Cada definición ocupa contexto en **cada turno** y
compite por la atención del modelo. Diez herramientas bien nombradas superan a cincuenta.
Cuando el catálogo es inevitablemente grande, carga bajo demanda (búsqueda de herramientas /
carga diferida) en vez de inyectarlo todo — y mide el impacto en la caché de prompt, porque
cambiar el conjunto de herramientas a mitad de conversación suele invalidarla.

**Esquemas estrictos**: `additionalProperties: false`, `required` explícito, `enum` donde el
dominio sea cerrado, tipos precisos. El modelo rellena lo que el esquema permita.

**Resultados acotados**: paginación, truncado anunciado, proyección de campos. Un resultado de
200 KB envenena el contexto y desplaza lo que importa.

**Errores accionables**: el mensaje de error es un prompt. «El fichero no existe; usa `glob`
para localizarlo» produce recuperación; un stack trace produce bucle.

### 3.2 El bucle: control y parada

Un agente sin límites es un incidente esperando su turno. **Todo bucle lleva las cinco cosas**:

1. **Máximo de iteraciones**, elegido y justificado. Alcanzarlo no es un error del sistema: es
   una condición de fin que debe **reportarse como resultado parcial**, no tragarse.
2. **Presupuesto de tokens** por tarea (entrada + salida acumuladas, no por llamada), con corte
   duro. Algunos proveedores exponen un presupuesto que el propio modelo *ve* y con el que se
   autorregula — mejor que el corte ciego, pero **no sustituye al límite duro**.
3. **Presupuesto de tiempo de reloj**, independiente del de tokens: un modelo lento con
   herramientas lentas agota minutos sin agotar tokens.
4. **Criterio de parada explícito**: qué significa "terminado" y quién lo decide. Si lo decide
   solo el modelo, tienes que aceptar que a veces se declare terminado sin estarlo. Un criterio
   verificable —tests pasan, esquema valida, rúbrica cumplida— es infinitamente mejor que
   "cuando el modelo diga".
5. **Detección de bucle improductivo**: repetición de la misma llamada con los mismos
   argumentos, alternancia entre dos estados, N iteraciones sin cambio de estado observable,
   tasa de error de herramienta creciente. Al detectarlo: **no reintentar más de lo mismo** —
   romper el patrón (cambiar de estrategia, pedir ayuda al humano, abortar con parcial).

**Cuando el agente se atasca**: el fallo típico no es que pare, es que insista. Escalón de
recuperación: (a) devolver un error de herramienta más informativo; (b) inyectar una
instrucción de replanteo; (c) reiniciar con contexto compactado y el objetivo reafirmado;
(d) escalar al humano con el trabajo hecho hasta ahí. Nunca (e) subir `max_iterations`.

### 3.3 Contexto en ejecución larga

El bucle acumula: cada llamada arrastra todo el historial. Tres mecanismos, con su compromiso:

| Mecanismo | Qué hace | Compromiso |
|---|---|---|
| **Poda de resultados antiguos** | Elimina resultados de herramienta que ya no son relevantes | Barato y determinista. **Pierdes el detalle**: si el agente lo necesita luego, vuelve a llamar (coste) o alucina (peor) |
| **Compactación / resumen** | Sustituye historial por un resumen | Conserva coherencia con muchos menos tokens. **Es un resumen generado**: pierde precisión y puede introducir error. Nunca compactes decisiones ni restricciones duras — recomprímelas literalmente |
| **Memoria persistente** (fichero o almacén) | El agente escribe lo aprendido y lo relee | Sobrevive a la sesión y a la compactación; es la única forma de aprendizaje entre ejecuciones. **Superficie de ataque**: la memoria es un canal de inyección persistente (ASI06) — ver §5 |

Reglas: **nunca metas secretos en la memoria** (se reproducen en cada sesión futura); haz la
memoria **legible y auditable** por un humano; ponle política de retención; y ancla siempre el
objetivo original fuera de lo compactable — la deriva de objetivo en ejecuciones largas nace
casi siempre de haber resumido el objetivo.

### 3.4 Multi-agente

**Cuándo compensa**: *fan-out* sobre trabajo **genuinamente independiente y voluminoso** —
explorar N ficheros sin relación, evaluar N candidatos, ejecutar N comprobaciones aisladas.
El beneficio es contexto aislado por trabajador (cada uno explora sin contaminar al resto) y
paralelismo real.

**Cuándo es puro coste**: **cada subagente reestablece contexto desde cero** — recibe la
instrucción, explora, informa; y el coordinador vuelve a leer el informe. Para un trabajo que
el coordinador cerraría en tres llamadas, un subagente multiplica coste y latencia sin ganar
nada. **Partir una tarea pequeña en subagentes es el antipatrón**, y es especialmente
tentador porque *parece* sofisticado.

Patrón por defecto: **coordinador + trabajadores**, un solo nivel de delegación. El
coordinador mantiene el objetivo y compone; los trabajadores no delegan a su vez (la
delegación anidada hace el coste y la traza incomprensibles). Reglas:

- **Briefing completo a la primera**: un trabajador mal instruido cuesta dos rondas.
- **Techo duro de subagentes concurrentes**, decidido y configurable.
- **No re-derivar**: si delegaste, acepta el resultado o descártalo; rehacerlo tú es pagar dos veces.
- **No delegues la verificación** por defecto: normalmente pertenece al bucle principal.
- Comunicación **asíncrona** cuando el framework lo permite: bloquear al coordinador en el
  trabajador más lento tira el paralelismo por la ventana.

## 4. Gates

En orden de coste creciente. **[BLOQUEA]** = rompe el build o el despliegue.

1. **[BLOQUEA] Límites presentes**: test que verifica que existen `max_iterations`, presupuesto
   de tokens y timeout de reloj, y que alcanzarlos produce un resultado parcial reportado, no
   una excepción tragada ni un bucle infinito.
2. **[BLOQUEA] Esquemas estrictos**: toda herramienta con `additionalProperties: false` y
   `required`.
3. **[BLOQUEA] Puerta de aprobación**: test que demuestra que **ninguna** acción marcada como
   irreversible se ejecuta sin la aprobación configurada. Es el gate que evita el titular.
4. **[BLOQUEA] Mínimo privilegio verificado**: test que confirma que la credencial del agente
   **no** puede hacer lo que no debe (no que "no lo hará").
5. **[BLOQUEA] Traza completa**: cada ejecución emite traza con toda llamada a herramienta,
   argumentos (sensibles redactados), resultado, latencia y tokens. Sin traza no hay
   producción — no puedes depurar ni auditar un no-determinista sin ella.
6. **[BLOQUEA] Idempotencia de las acciones con efecto**: test de doble ejecución con la misma
   clave, que verifica que el efecto ocurre **una** vez.
7. **Evaluación de extremo a extremo** sobre un conjunto fijo de tareas: **tasa de éxito de la
   tarea completa**, no métricas de paso. Umbral definido; regresión rompe el build.
8. **Coste y latencia por tarea** medidos en cada ejecución de la evaluación, con umbral. Una
   mejora de calidad que triplica el coste es una decisión, no un accidente.
9. **Casos de fallo en el conjunto de evaluación**: herramienta que falla, resultado vacío,
   entrada ambigua, contenido con instrucción embebida (comprobar que **no** la obedece),
   objetivo imposible (comprobar que para y lo dice).
10. **Prueba de bucle improductivo**: escenario construido para atascarlo; verificar detección
    y ruptura del patrón.
11. **Revisión de la superficie de herramientas** en cada PR que la toque: ¿esta herramienta
    necesita aprobación? ¿su descripción dice cuándo usarla? ¿su salida está acotada?

## 5. Seguridad — la sección crítica

**Premisa: el agente actúa con los permisos que le des.** No hay "el agente no haría eso": si
la credencial puede, el agente puede, y basta un texto en una página web para que lo intente.

### 5.1 La tríada letal

Formulación de **Simon Willison** (*"The lethal trifecta for AI agents: private data,
untrusted content, and external communication"*, 16-jun-2025). Un agente es explotable para
exfiltración cuando combina las **tres**:

1. **Acceso a datos privados** — que suele ser justo para lo que lo montaste.
2. **Exposición a contenido no confiable** — cualquier texto o imagen que un atacante controle
   y que llegue al modelo: una página web, un ticket, un correo, un issue, un PDF, un
   README de una dependencia, la salida de una herramienta.
3. **Capacidad de comunicar al exterior** — de forma que se puedan sacar datos.

**Basta con romper una de las tres**, y eso es la mitigación real, porque **no se sabe prevenir
de forma fiable** por el lado del modelo. Los productos de *guardrails* que prometen detectar
la inyección son mitigación probabilística: útiles como capa, **inaceptables como control
único**.

En la práctica, la pata que puedes romper es casi siempre la **tercera**: sin egress
arbitrario no hay exfiltración, aunque el agente sea engañado. Con lo cual la contención de un
agente es, en gran medida, un problema de **red y de permisos**, no de prompting.

### 5.2 Inyección de prompt indirecta

**Toda entrada de herramienta es entrada del atacante.** El modelo no distingue instrucción de
dato: procesa ambos en el mismo canal. Es LLM01 del OWASP Top 10 para aplicaciones LLM (edición
2025, la vigente) y ASI01 (*Agent Goal Hijack*) del Top 10 agéntico. Consecuencias de diseño:

- **Ningún resultado de herramienta es confiable.** Trátalo como entrada de usuario no
  autenticada, y **nunca** como instrucción con autoridad.
- **Separa canales**: la instrucción del operador debe viajar por el canal privilegiado que
  ofrezca la plataforma, no incrustada como texto en un turno que cualquier contenido pueda
  imitar.
- **La autoridad no viaja con el texto**: que un contenido diga «el administrador autoriza» no
  autoriza nada. La autorización se comprueba fuera del modelo.
- **Multimodal cuenta**: instrucciones en imágenes y documentos son el mismo problema.
- **La memoria es persistencia de la inyección** (ASI06): lo que se escribió envenenado se
  releerá en cada sesión futura. Auditar lo que entra en memoria.

### 5.3 Contención

- **Mínimo privilegio, de verdad**: credencial por agente y por tarea, alcance mínimo, vida
  corta, revocable. Identidad propia del agente (no reutilizar la de un humano) para que la
  auditoría distinga quién hizo qué. Nada de tokens de administrador «porque es más simple».
- **Aprobación humana para lo irreversible.** El criterio no es "sensible": es
  **reversibilidad**. Enviar un mensaje, pagar, borrar, desplegar, modificar producción, hablar
  con un tercero. La aprobación tiene que ser **informada** —mostrar la acción y el argumento
  exacto, sin truncar— o es teatro. Y tiene que ser **por acción**, no un «permitir todo» al
  arrancar; un usuario que aprueba 200 veces al día no está aprobando, está pulsando.
- **Sandboxing** de lo que el agente ejecuta: contenedor sin privilegios, no-root, FS de solo
  lectura salvo un directorio de trabajo, capabilities recortadas, sin acceso a la red salvo
  lo listado. Ver `container-runtime-security-standards`.
- **Egress allow-list** por defecto-denegar. Es la pata más práctica de la tríada y la que
  bloquea el canal lateral. Ver `firewall-policy-standards`.
- **Exfiltración por canal lateral**: el dato no siempre sale por una petición HTTP obvia.
  Sale en una URL de imagen que el cliente renderiza, en un parámetro de un enlace que el
  usuario pinchará, en el nombre de una rama, en un DNS lookup, en un commit. Trata el
  **renderizado de la salida del agente** como superficie: no cargues recursos remotos
  automáticamente desde contenido que el agente produjo a partir de datos privados.
- **Auditoría de cada acción**, no de cada respuesta: registro inmutable de qué herramienta se
  invocó, con qué argumentos, con qué identidad, con qué resultado, y si hubo aprobación
  humana y de quién. Es lo que necesitarás el día del incidente.
- **Aislar por nivel de confianza**: no mezcles en la misma sesión herramientas sobre datos
  sensibles con herramientas que ingieren contenido de terceros. Si tienen que convivir,
  rompe la tercera pata.

### 5.4 Marco de referencia: OWASP Top 10 para aplicaciones agénticas (2026)

Publicado el **9-dic-2025** por el OWASP GenAI Security Project (prefijo **ASI**, *Agentic
Security Initiative*; v2.01 en jun-2026). **Extiende, no sustituye**, al Top 10 para
aplicaciones LLM (edición **2025** vigente; no hay revisión 2026 de esa lista): un agente es
también una aplicación LLM y hereda sus riesgos.

| ID | Riesgo |
|---|---|
| ASI01 | Agent Goal Hijack |
| ASI02 | Tool Misuse & Exploitation |
| ASI03 | Identity & Privilege Abuse |
| ASI04 | Agentic Supply Chain (herramientas, plugins, registros, servidores MCP) |
| ASI05 | Unexpected Code Execution (RCE) |
| ASI06 | Memory & Context Poisoning |
| ASI07 | Insecure Inter-Agent Communication |
| ASI08 | Cascading Failures |
| ASI09 | Human-Agent Trust Exploitation |
| ASI10 | Rogue Agents |

Uso: **como cobertura, no como checklist de cumplimiento**. Mapea tu diseño contra los diez y
justifica los que no apliquen. ASI04 y ASI07 son los más sensibles a la elección de framework
y de servidores de terceros.

**Postura**: defensiva y autorizada. El *red teaming* de agentes es valioso y pertenece a
`offensive-security-standards`, con alcance y permiso por escrito.

## 6. Evaluación, observabilidad y operación

### 6.1 Evaluación

- **La demo engaña, y engaña sistemáticamente.** Una traza que sale bien no dice nada: el
  sistema es estocástico, tú elegiste la tarea, y la viste terminar. La única señal es
  **N ejecuciones sobre un conjunto fijo de tareas, midiendo tasa de éxito de extremo a
  extremo**. Ejecuta cada tarea varias veces: la varianza entre ejecuciones idénticas *es* el
  dato más importante que vas a obtener.
- **Éxito de extremo a extremo > métricas de paso.** «Eligió la herramienta correcta el 94 %
  de las veces» es compatible con fallar la tarea completa el 40 % (los errores se componen a
  lo largo del bucle). Mide el resultado que le importa al usuario, con un verificador
  **programático** siempre que sea posible.
- **Mide coste y latencia con la calidad, no después.** Sin las tres juntas no hay decisión:
  cualquier mejora se puede comprar con tokens.
- **Casos de fallo en el conjunto**: fallo de herramienta, entrada ambigua, objetivo
  imposible, contenido con instrucción embebida.
- **Ancla la evaluación antes de tocar el prompt.** Sin línea base, toda iteración de prompt es
  superstición.

### 6.2 Observabilidad

- **Traza completa por ejecución** como artefacto de primera clase: árbol de llamadas
  (incluidos subagentes), argumentos, resultados, latencias, tokens, decisiones de parada.
  OpenTelemetry con contexto propagado; ver `observability-standards`.
- **Métricas mínimas**: tasa de éxito, tokens y coste por tarea, iteraciones por tarea
  (distribución, no media), tasa de error por herramienta, tasa de intervención humana,
  latencia p95.
- **Señales de alarma accionables**: iteraciones por tarea subiendo, tasa de intervención
  subiendo, coste por tarea subiendo con éxito plano. Las tres significan degradación real,
  y ninguna aparece en un test unitario.
- **Un cambio de modelo o de versión de modelo es un cambio de comportamiento**: re-evalúa
  antes de promocionarlo. Lo que era un buen prompt para un modelo puede ser demasiado
  prescriptivo para el siguiente.

### 6.3 Operación

- **Despliegue** del agente como cualquier servicio: artefacto inmutable, promoción del mismo
  artefacto, canary, rollback probado. Fija la **versión del modelo** y trátala como una
  dependencia: `latest` implícito es *drift* no gobernado.
- **Reintentos**: distingue fallo de transporte (reintentable con backoff+jitter) de fallo de
  la tarea (no reintentable a ciegas). Reintentar un bucle entero desde cero es caro y puede
  duplicar efectos ya aplicados.
- **Idempotencia de las acciones del agente**: clave de idempotencia en toda acción con
  efecto. **No es opcional**, porque el agente reintenta por su cuenta, el usuario reintenta,
  y el reintento del bucle vuelve a pasar por ahí.
- **Fallo a mitad de una secuencia con efectos ya aplicados** — el caso duro. Diseña por este
  orden de preferencia:
  1. **Evítalo**: agrupa los efectos en una acción única y transaccional donde el sistema de
     destino lo permita.
  2. **Hazlo reanudable**: persiste el estado del bucle (checkpointing) con lo ya hecho, para
     retomar sin repetir. Es la razón principal para elegir un framework con ejecución
     duradera.
  3. **Compénsalo**: acción inversa explícita por cada efecto (patrón saga), registrada.
  4. **Escálalo**: si no puedes revertir, para y entrega al humano el estado exacto — qué se
     aplicó, qué no, y qué queda inconsistente. **Nunca dejes el sistema a medias en silencio.**
- **Runbook** del agente: cómo pararlo en caliente, cómo revocar sus credenciales, cómo
  localizar todo lo que hizo en una ventana de tiempo, quién es el dueño. Un agente sin *kill
  switch* documentado no debería estar en producción.

## 7. Sostenibilidad y prohibiciones

- **Cadencia de revisión trimestral**: modelos, frameworks y marcos de seguridad se mueven
  cada semana. Lo que hoy exige un agente puede resolverlo mañana una llamada.
- **Baja de escalón cuando puedas**: si las capacidades del modelo o un cambio del producto
  permiten sustituir el bucle por un workflow, hazlo. Bajar de escalón es una mejora, no una
  regresión.
- **Deuda consciente**: si concedes un permiso amplio o saltas una aprobación por plazo,
  regístralo con motivo y fecha de revisión.

**PROHIBIDO**
- ❌ Montar un agente cuando basta una llamada, una cadena o un workflow — el fallo más caro y más común.
- ❌ Un bucle sin máximo de iteraciones, sin presupuesto de tokens y sin timeout de reloj.
- ❌ Subir `max_iterations` como respuesta a un agente que se atasca.
- ❌ Autonomía sobre acciones irreversibles sin aprobación humana informada y **por acción**.
- ❌ Aprobación que trunca la acción o el argumento: es teatro de seguridad.
- ❌ Dar al agente credenciales más amplias que su tarea, o reutilizar la identidad de un humano.
- ❌ Confiar en el resultado de una herramienta como si fuera instrucción con autoridad.
- ❌ Combinar datos privados + contenido no confiable + egress arbitrario sin romper una pata.
- ❌ Depender de *guardrails* de detección de inyección como control único.
- ❌ Ejecutar código generado por el agente sin sandbox.
- ❌ Secretos en el prompt, en la memoria persistente o en argumentos de herramienta registrados sin redactar.
- ❌ Acciones con efecto sin clave de idempotencia.
- ❌ Ejecutar en producción sin traza completa por ejecución.
- ❌ Declarar que funciona a partir de una demo o de métricas de paso.
- ❌ Un `bash` genérico cuando la política exige interceptar acciones concretas.
- ❌ Descripciones de herramienta que no dicen **cuándo** invocarla.
- ❌ Herramientas con salida no acotada.
- ❌ Partir una tarea pequeña entre subagentes; delegación anidada de más de un nivel.
- ❌ Compactar el objetivo o las restricciones duras.
- ❌ AutoGen/AG2 en proyectos nuevos (modo mantenimiento).
- ❌ Elegir framework por estrellas de GitHub.
- ❌ Un agente en producción sin *kill switch* ni runbook de revocación.

## 8. Verificación web obligatoria

Antes de fijar versión, nombre de feature o afirmación de estado:

1. **Estado y versión de los frameworks**: LangGraph, Pydantic AI, OpenAI Agents SDK, Google
   ADK, Microsoft Agent Framework, CrewAI. Confirmar mantenimiento activo y *breaking changes*;
   AutoGen/AG2 y Semantic Kernel están en mantenimiento — verificar si han sido archivados.
2. **Capacidades y límites del modelo** que vas a usar: ventana de contexto, coste, soporte de
   herramientas en paralelo, comportamiento de razonamiento. **Nunca de memoria** — la línea de
   modelos cambia cada pocos meses. Si es Claude/Anthropic, la fuente es la skill `claude-api`.
3. **OWASP Top 10 para aplicaciones agénticas**: edición vigente y **redacción exacta** de
   ASI01–ASI10; las fuentes secundarias varían en el título de varias entradas (ASI03, ASI04,
   ASI08). Contrastar contra el PDF de `genai.owasp.org`.
4. **OWASP Top 10 para aplicaciones LLM**: la edición **2025** es la vigente a agosto 2026 y hay
   un proceso de actualización en marcha — comprobar si ya salió una nueva antes de citar
   `LLM01:2025`.
5. **Tríada letal**: formulación y atribución originales (Simon Willison, 16-jun-2025).
   Verificar el post antes de parafrasearlo; existe un "lethal trifecta" **distinto** en la
   literatura de seguridad de IA que no es este.
6. **Estado de A2A** y de cualquier otro estándar de interoperabilidad entre agentes.
7. **Incidentes de cadena de suministro** en el framework, las herramientas o los servidores de
   terceros que recomiendes (ASI04): NVD/GHSA por paquete.
8. **Marcos de gobierno** si aplica: NIST AI RMF, ISO/IEC 42001, EU AI Act — fechas de
   aplicación y obligaciones concretas (ver `grc-compliance-standards`).

### Huecos declarados (no verificados en esta redacción)

- **Números de versión exactos y fechas de release de los frameworks** más allá de los citados
  (LangGraph 1.0 oct-2025 / 1.1 mar-2026; Pydantic AI v2 jun-2026; Microsoft Agent Framework 1.0
  abr-2026; Google ADK 2.0): proceden de fuentes secundarias. **Verificar en el repositorio o
  registro de paquetes** antes de fijar una versión mínima en un proyecto.
- **Redacción exacta de ASI03, ASI04 y ASI08**: las fuentes secundarias consultadas discrepan
  ("Identity & Privilege Abuse" vs "Agent Identity & Privilege Abuse", "Vulnerabilities" vs
  "Compromise", "Cascading Failures" vs "Cascading Agent Failures"). No verificado contra el PDF
  primario.
- **Estado detallado del OpenAI Agents SDK y de CrewAI en 2026** (versión, cadencia, roadmap):
  no verificado en profundidad.
- **Herramienta concreta de observabilidad de agentes** (trazado especializado, LLM-as-judge en
  producción): deliberadamente no se recomienda ninguna; el criterio es OpenTelemetry y traza
  propia. Verificar el mercado si el proyecto necesita una plataforma.
- **Datos cuantitativos sobre eficacia de guardrails anti-inyección**: no verificados; el
  criterio de §5 (no usarlos como control único) se apoya en la formulación de la tríada letal,
  no en cifras.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
