---
name: ai-agent-workflow-standards
description: Use when an engineering team works with coding agents day to day — deciding which task to hand to an agent and which to write by hand, AGENTS.md, CLAUDE.md, .cursorrules and .github/copilot-instructions.md repository instruction files, agent permission allowlists and settings.json approval rules, filesystem scope and which credentials the agent process can read, sandboxing a coding agent on a workstation, running an agent in CI (claude-code-action, GitHub Agentic Workflows, Copilot coding agent) and scoping its token and OIDC identity, indirect prompt injection through issues, PR comments, fetched web pages, dependency READMEs and tool output, reviewing a large plausible agent-authored diff, who is accountable for a merged agent-written change, disclosure and trailer conventions for AI-generated commits, copyright and licensing of generated code, or citing productivity evidence (METR RCT, DORA report) in a rollout decision.
---

# Estándares de trabajo en equipo con agentes de codificación

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **cómo trabaja un equipo de ingeniería con agentes de codificación**: qué tarea se le
da a un agente y cuál no, qué contexto necesita del repositorio, qué permisos tiene, qué pasa
con el resultado antes de fusionarse, quién responde de él y qué se declara.

Principio rector: **el agente no elimina trabajo, lo mueve de sitio.** Mueve esfuerzo de
*escribir* a *especificar y verificar*. La ganancia neta existe **solo si verificar es más
barato que escribir**; cuando no lo es, el agente produce volumen que alguien tiene que
auditar, y el balance se vuelve negativo sin que nadie lo note, porque el trabajo desplazado
—revisión— no se mide y el trabajo ahorrado —tecleo— sí se percibe. **Ese sesgo de percepción
está medido (§6.1) y es la razón de que este documento fije reglas en vez de recomendaciones.**

Triggers: `AGENTS.md`, `CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`;
`settings.json` de permisos de agente, listas de comandos permitidos, aprobación de acciones
irreversibles; alcance de sistema de ficheros del agente; credenciales legibles por el proceso
del agente; agente en CI (`claude-code-action`, GitHub Agentic Workflows, Copilot coding
agent); inyección de prompt indirecta desde issues, comentarios de PR, páginas web,
dependencias o salida de herramienta; diff grande escrito por un agente; *trailer* de
coautoría en el commit; licencia y autoría del código generado; evidencia de productividad.

### La frontera triple — leer antes de enrutar

| Pregunta | Dueño |
|---|---|
| ¿Cómo se **construye** un sistema agéntico? Bucle, superficie de herramientas, memoria, subagentes, presupuesto de iteraciones, sandbox del agente que *tú* despliegas, evaluación y coste por tarea | **`ai-agents-standards`** |
| ¿Cómo se **escribe y organiza** una skill de Claude Code? `SKILL.md`, frontmatter, diseño de `description`, activación, catálogo | **`claude-code-skills-standards`** |
| ¿Cómo **trabaja un equipo de ingeniería** con un agente de codificación de terceros? Qué tarea se le da, qué contexto y qué permisos, cómo se revisa lo que produce, quién responde, qué se declara | **Esta skill** |

Dicho en las tres direcciones desde este lado, sin ambigüedad:

- **Si escribes el bucle, es `ai-agents-standards`. Si consumes el bucle de otro, es de aquí.**
  Diseñar la herramienta que el agente invoca y cuándo para: suya. Decidir si tu equipo deja
  que un agente toque el repositorio de facturación: de aquí.
- **Si el artefacto que produces es un `SKILL.md`, es `claude-code-skills-standards`.** Aquí el
  artefacto es un **`AGENTS.md`/`CLAUDE.md` del repositorio** — convención de proyecto para
  cualquier agente, no una skill del catálogo. Si dudas: ¿el fichero vive en el repositorio del
  producto y lo lee cualquier agente? De aquí. ¿Vive en `~/.claude/skills/` o `.claude/skills/`
  y define criterio de dominio reutilizable? Suya.
- **Si la pregunta es "¿cómo hago que el agente haga X mejor?", casi siempre es una de las otras
  dos. Aquí la pregunta es "¿debería el agente hacer X, con qué permisos, y quién firma?"**

**No aplica**: ver
`ai-agents-standards` y `claude-code-skills-standards` (tabla de arriba);
`mcp-standards` (**el protocolo**: primitivas, transportes, autorización y diseño/seguridad de
un servidor MCP. Aquí solo la consecuencia de flujo: **cada servidor MCP conectado amplía la
superficie de lectura no confiable y de acción del agente** (§5), y por tanto entra en el
inventario y en la aprobación del equipo);
`llm-app-engineering-standards` (la app de LLM determinista: prompting versionado, salida
estructurada, enrutado de modelo, coste por llamada — **construir producto con LLM, no trabajar
con un agente**);
`llm-evaluation-standards` (**metodología de evaluación**: datasets, LLM-as-judge, medir la
calidad de un sistema de IA. Aquí no se evalúa un modelo: se decide un flujo de trabajo);
`mlsecops-standards` (**la seguridad del sistema de IA como producto es suya**: modelo,
cadena de suministro del modelo, ataques a la inferencia, defensa del servicio que despliegas.
**Aquí el riesgo operativo del flujo de trabajo**: qué puede pasarle a *tu repositorio y a tus
credenciales* porque un agente leyó algo hostil. Si la pregunta es "cómo protejo el sistema de
IA que sirvo", es suya; si es "cómo evito que el agente que uso me robe el token de CI", de aquí);
`ai-governance-standards` (**la gobernanza y el cumplimiento normativo del uso de IA en la
organización son suyos**: inventario de sistemas de IA, clasificación por el AI Act, política
corporativa de uso aceptable, evaluación de impacto, debida diligencia del proveedor, ISO/IEC
42001. **Aquí la práctica de ingeniería**: la regla que aplica el equipo dentro del repositorio.
Si la respuesta la firma el comité de riesgo o el DPO, es suya; si la aplica el `CODEOWNERS`, de aquí);
`code-review-standards` (**ya escrita, y tiene sección propia de revisión de código generado
por IA — no se duplica**: qué se mira en un diff, en qué orden, qué bloquea, cómo se etiqueta
el comentario, quién firma un cambio de alto riesgo. **Cede el criterio de revisión**; aquí se
retiene solo **qué tarea se delega, con qué permisos, y qué particularidad del diff de agente
hay que anticipar antes de que llegue a revisión** (§4));
`testing-qa-standards` (**ya escrita**: qué se prueba, en qué proporción y qué rompe el build.
Aquí solo el uso del test **como criterio de delegación**: sin verificación barata, no se delega);
`git-workflow-standards` (rama, commit, tamaño de PR, `CODEOWNERS`, protección de rama; **el
*trailer* de coautoría y la convención de commit son suyos**, aquí solo la exigencia de que
exista);
`cicd-standards` (**la pipeline es suya**: jobs, runners, OIDC, *required checks*. Aquí **qué
identidad y qué permisos tiene un agente que corre dentro de esa pipeline**, §5.4);
`secrets-management-standards` (custodia, rotación y bóveda; aquí **a qué secretos alcanza el
proceso del agente**, que es una pregunta de flujo, no de gestión);
`developer-workstation-standards` (**el endurecimiento de la máquina donde
corre el agente es suyo** — sandbox del sistema operativo, contenedor de desarrollo, permisos
del usuario, cifrado del disco. Aquí solo el requisito: *que exista aislamiento*, no cómo se
implementa);
`appsec-standards` (STRIDE y clases clásicas de vulnerabilidad; **la inyección de prompt no es
una de ellas y no se mitiga con las mismas técnicas** — §5.2);
`grc-compliance-standards` (evidencia de auditoría y segregación de funciones),
`tech-leadership-standards` (adopción organizativa, presupuesto,
build-vs-buy y el efecto en la carrera del equipo; aquí la regla técnica),
`i18n-standards` (**frontera fina**: la traducción automática con LLM aparece en las dos. **El
flujo con el modelo es de aquí** — qué se le encarga, qué permisos, cómo se revisa. **El
criterio de calidad lingüística y dónde una traducción sin revisar es inaceptable es suyo**).

## 2. Decisiones por defecto

> Verificar el estado de herramientas, avisos de seguridad y estudios citados por web antes de
> fijar nada (§8). Este dominio se mueve más rápido que la capacidad de verificarlo.

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Criterio de delegación | **Los tres filtros del §3.1** (reversibilidad, alcance, coste de verificación). Si falla uno, no se delega | — |
| Control de versiones | **Obligatorio y previo.** Un agente solo trabaja sobre un árbol limpio y versionado | Ninguna |
| Aislamiento de ejecución | **Contenedor o *worktree* desechable** para tareas con ejecución de comandos | Ejecución directa en la máquina solo con lista de comandos permitidos y sin credenciales de escritura |
| Alcance de sistema de ficheros | **El repositorio de trabajo y nada más**; nunca `$HOME`, nunca otro repositorio | Directorio de datos temporales explícito |
| Credenciales visibles al proceso | **Ninguna de escritura, ninguna de producción** (§5.3) | Token de solo lectura, de vida corta y con alcance a un repositorio |
| Acciones irreversibles | **Aprobación humana explícita por acción**: `push --force`, borrado, migración, despliegue, publicación de paquete, cambio de permisos, gasto | Ninguna que las autoapruebe por lote |
| Contexto del repositorio | **`AGENTS.md` en la raíz**, versionado y revisado como código (§3.3) | Formato del proveedor si la cadena de herramientas del equipo es única |
| Autoridad de las convenciones | **Lo que no está escrito en el repositorio no existe** (§3.3) | — |
| Revisión | **Humana y obligatoria antes de fusionar. Sin excepción por tamaño ni por "es trivial"** | — |
| Responsabilidad | **Responde quien envía el cambio**, lo haya escrito o no (§4.3) | Ninguna |
| Declaración | **Se declara** que el cambio se generó con asistencia de IA, con la convención del repo | — |
| Agente en CI disparado por evento público | **Prohibido por defecto** (issue, comentario o PR de terceros); si se habilita, §5.4 completo | Repositorio privado con actores de confianza y token mínimo |
| Contenido externo que el agente lee | **No confiable, siempre** (§5.2) | — |
| Métrica de adopción | **Ninguna individual.** Solo agregadas y de resultado (§6.3) | — |

## 3. Qué se delega, qué no, y con qué contexto

### 3.1 Los tres filtros

Se aplican **antes** de escribir el prompt, y **basta que falle uno** para no delegar.

1. **Reversibilidad.** ¿Se deshace el resultado con un `git revert` y nada más? Si el efecto sale
   del repositorio —tocar producción, migrar datos, publicar un artefacto, enviar correo, gastar
   dinero, cambiar permisos, rotar una clave— **no se delega la ejecución**. Se delega, como
   mucho, **la propuesta**: el agente escribe el script o el plan y una persona lo ejecuta.
2. **Alcance.** ¿Cabe el cambio en un diff que un revisor entiende de una sentada? Un agente
   puede producir en minutos un diff que nadie revisará de verdad. Si la tarea no se puede
   acotar a un cambio revisable, **primero se descompone**; delegar la descomposición es
   legítimo, delegar la ejecución de la tarea sin descomponer no lo es.
3. **Coste de verificación.** ¿Existe una forma **barata y objetiva** de saber si el resultado es
   correcto —test que falla antes y pasa después, tipos, propiedad comprobable, comparación con
   una salida conocida— **antes de que una persona lea el código**? Si la única verificación
   posible es "leerlo entero y razonar", el agente **no ahorra trabajo: lo desplaza a la
   revisión**, que es el recurso más escaso y el peor medido del equipo.

**Corolario operativo**: el mejor candidato a delegación es una tarea **acotada, reversible y con
un oráculo barato**. El peor es una tarea **grande, con efecto externo y sin forma de comprobarla
salvo leyéndola**. Entre ambos extremos, decide el filtro 3.

### 3.2 Tabla de decisión

| Tarea | Delegar | Motivo |
|---|---|---|
| Reproducir un bug con un test que falla | **Sí, primero** | Oráculo perfecto, reversible, acotado |
| Arreglar un bug **con test de regresión ya escrito** | Sí | Verificación barata y objetiva |
| Refactor mecánico con test verde y cobertura real | Sí | Reversible; el test es el oráculo |
| Migración de API repetitiva en muchos ficheros | Sí, **por lotes revisables** | Acotable; el diff grande se parte, no se acepta entero |
| Andamiaje, boilerplate, configuración inicial | Sí | Reversible y de bajo riesgo |
| Escribir tests de un módulo que ya funciona | **Con cuidado** | Riesgo real: tests que reflejan la implementación en vez del comportamiento, y que pasan siempre. Criterio en `testing-qa-standards` |
| Exploración y lectura de código desconocido | Sí | Sin efecto; el resultado es entendimiento, que se verifica al usarlo |
| Diseño de arquitectura, ADR | **No como decisión**; sí como generador de alternativas | La decisión la firma una persona que responde de ella |
| Cambio en autenticación, autorización o criptografía | **No** | Coste de verificación altísimo; fallo silencioso y catastrófico |
| Migración de datos / DDL destructivo | **No la ejecución** | Irreversible (filtro 1) |
| Cualquier cosa contra producción | **No** | Filtro 1, y §7 lo prohíbe explícitamente |
| Arreglo de un incidente en curso | **No en la ruta crítica** | La verificación cuesta más que escribirlo, bajo presión y sin margen |
| Cambio en el código que gobierna al propio agente (workflow de CI, `AGENTS.md`, permisos) | **No sin revisión de un segundo par de ojos** | Es escalada de privilegio: §5.4 |

### 3.3 Contexto: el recurso escaso

- **La instrucción que no está escrita en el repositorio no existe.** Una convención que vive en
  la cabeza de alguien, en un hilo de chat o en el prompt de una persona **no aplica al trabajo
  de nadie más**. Si una regla importa, se escribe en el repositorio y se revisa como código.
- **Un fichero de instrucciones en la raíz** (`AGENTS.md` es la convención convergente; los
  ficheros específicos de proveedor son equivalentes funcionales). Reglas de contenido:
  - **Solo lo que el agente no puede deducir del repositorio.** Repetir lo obvio —"usa
    TypeScript", "hay tests"— gasta contexto sin aportar. Lo que aporta es lo **no evidente**:
    el comando exacto de build y de test, la convención que contradice el default del
    ecosistema, el directorio prohibido, la razón por la que algo está como está.
  - **Imperativo y falsable**, no aspiracional. "Ejecuta `make test` antes de terminar" sirve;
    "escribe código de calidad" no.
  - **Versionado, revisado y con dueño.** Un `AGENTS.md` desactualizado hace daño activo: el
    agente sigue una instrucción que ya es falsa y produce un cambio plausible y equivocado.
  - **Jerárquico en monorepo**: fichero por paquete, el más cercano gana.
  - **PROHIBIDO** meter secretos, URLs internas sensibles o datos personales: es un fichero que
    se envía al proveedor del modelo en cada tarea.
- **El contexto es un presupuesto, no un almacén.** Un fichero de instrucciones que crece sin
  poda desplaza al código que el agente necesita leer. Se revisa y se recorta periódicamente.
- **Evidencia sobre esto — un solo estudio y con su tamaño**: *On the Impact of AGENTS.md Files
  on the Efficiency of AI Coding Agents* (arXiv 2601.20404, 28-ene-2026; Lulla, Mohsenimofidi,
  Galster, Zhang, Baltes, Treude). Diseño, *verbatim*: «We analyze 10 repositories and 124 pull
  requests, executing agents under two conditions: with and without an AGENTS.md file.»
  Resultado, *verbatim*: «the presence of AGENTS.md is associated with a lower median runtime
  (Δ 28.64%) and reduced output token consumption (Δ 16.58%), while maintaining a comparable
  task completion behavior.» **Léase por lo que es**: 10 repositorios, un *preprint*, métricas de
  eficiencia (tiempo y tokens), **no de calidad del resultado**. No sostiene "los AGENTS.md
  mejoran el código"; sostiene que reducen tiempo y tokens en esa muestra.

### 3.4 Cómo se encarga la tarea

- **Criterio de aceptación antes del prompt.** Si no puedes escribir cómo sabrás que está bien,
  no está lista para delegarse (es el filtro 3 en forma operativa).
- **Una tarea, un cambio, un PR.** Encargar tres cosas a la vez produce un diff que mezcla tres
  riesgos y no se puede revertir por partes.
- **Plan antes de código en cualquier tarea no trivial**, y el plan se lee. Corregir un plan
  cuesta minutos; corregir un diff de 800 líneas cuesta una tarde.
- **Dos intentos fallidos = para y escribe tú.** Iterar sobre un agente que no converge es la
  forma más común de perder tiempo sin darse cuenta, y es exactamente el mecanismo por el que la
  percepción de velocidad se despega del reloj (§6.1).

## 4. Revisión del resultado

**El criterio de revisión lo fija `code-review-standards`, que ya tiene sección propia de
revisión de código generado por IA. Aquí solo lo específico de este flujo, que hay que
anticipar antes de que el diff llegue a revisión.**

### 4.1 El diff plausible y grande

- **El riesgo característico del código de agente no es que parezca malo: es que parece bien.**
  Estilo coherente, nombres razonables, estructura convencional. La revisión por "olor" —la
  heurística que un revisor experimentado usa para decidir dónde mirar— **no dispara**, porque el
  código no huele. Hay que mirar donde no huele.
- **El tamaño se acota en origen, no en revisión.** Un límite de diff que se aplica al humano y
  no al agente no es un límite. Si el agente produce más de lo revisable, **se rechaza y se parte
  la tarea**; no se revisa "por encima".
- **Anticipos concretos que hay que exigir en el PR** (obligación de quien envía, no del revisor):
  qué se pidió, qué se verificó y **cómo**, qué quedó fuera y qué partes el autor no entiende del
  todo. Esta última es la más útil y la que nadie escribe voluntariamente.

### 4.2 La trampa: compila, pasa los tests, y no hace lo pedido

Un agente optimiza hacia señales observables. Fallos característicos, en orden de frecuencia:

- **Requisito cumplido de forma literal y equivocada**: hace exactamente lo que dice el prompt y
  no lo que hacía falta. Lo detecta releer **el requisito**, no el diff.
- **Test adaptado al código en vez de código al test**: el test que fallaba ahora pasa porque
  cambió el test. **Comprobar siempre que el test de regresión falla sin el arreglo.**
- **Caso borde silenciado**: un `try/except` amplio, un valor por defecto, un `?? 0` que convierte
  un error en un dato incorrecto que viaja. El agente prefiere que el programa no falle.
- **Manejo de error tragado o genérico**, sin contexto y sin propagación.
- **Dependencia nueva** para algo que la base de código ya resolvía, o **reimplementación** de
  algo que ya existía tres directorios más allá.
- **Alcance desbordado**: cambios "de paso" no pedidos, mezclados con el cambio real.
- **Cosas plausibles que no existen**: una opción de configuración, un flag o una función de
  librería inventados. Se detecta ejecutando, no leyendo.
- **Artefactos de inyección** (§5.2): llamada de red nueva, blob codificado, cambio en un fichero
  de workflow, en el manejo de `.env` o en la lista de dependencias. **Cualquiera de estos en un
  diff de agente es motivo de bloqueo y de revisión específica, no un comentario menor.**

### 4.3 Responsabilidad

- **Quien envía el cambio responde de él, lo haya escrito o no.** No hay categoría "lo escribió
  el agente" que reparta la culpa. Si el cambio rompe producción, el postmortem no cambia de
  forma porque haya un agente en la historia.
- **Corolario duro: si no lo entiendes, no lo envías.** No hay excepción por urgencia. Un cambio
  que nadie del equipo entiende es deuda con intereses y un incidente futuro sin quien lo
  diagnostique.
- El revisor no hereda la responsabilidad del autor: revisar no es reescribir. Un PR que exige
  que el revisor reconstruya la intención **se devuelve**.

## 5. Seguridad y permisos

### 5.1 Modelo de amenaza en una línea

**El agente es un proceso que ejecuta acciones con tus permisos y cuyas instrucciones pueden
venir, en parte, de quien no debería tenerlas.** De ahí salen los dos controles: **acotar lo
que puede hacer** (§5.3) y **tratar como hostil todo lo que lee** (§5.2). Ninguno de los dos
funciona solo.

### 5.2 Inyección de prompt indirecta — la clase de vulnerabilidad propia de este flujo

- **Definición precisa**: contenido que el agente **lee como dato** durante su trabajo, y que
  contiene texto redactado para que el modelo lo interprete como **instrucción**. No hay
  separación estructural entre datos e instrucciones en la entrada de un LLM, así que el
  atacante no necesita acceso a nada: **le basta con que su texto acabe en el contexto**.
- **Superficies reales, todas ya explotadas**: cuerpo y comentarios de un *issue*, título y
  descripción de un PR, mensajes de commit, `README` y *changelog* de una dependencia,
  comentarios en el código, ficheros de datos de prueba, páginas web recuperadas, salida de una
  herramienta o de un servidor MCP, y respuestas de una API de terceros.
- **La diferencia con el XSS o la SQLi es de mitigación**: allí hay una gramática y se puede
  escapar o parametrizar. **Aquí no**: no existe un `prepared statement` para lenguaje natural.
  Filtrar, detectar patrones o pedirle al modelo que ignore instrucciones **reduce la tasa, no
  cierra la clase**. Cualquier proveedor que afirme lo contrario se contrasta antes de creerlo.
- **Por eso el control efectivo es de permisos, no de contenido**: si el agente no puede leer un
  secreto ni alcanzar la red de salida ni escribir donde importa, la inyección tiene éxito y
  **daño acotado**. Ese es el diseño; el filtrado es defensa en profundidad.
- **Caso de referencia verificado** — `claude-code-action`, divulgación pública el **1-jun-2026**
  (GMO Flatt Security / RyotaK). Citas *verbatim* del informe: el fallo permitía a «an attacker
  to compromise any repository that uses the Claude Code workflow, including Anthropic's own
  repositories»; la causa raíz era que `checkWritePermissions` «unconditionally allows any GitHub
  App to pass, regardless of its actual permissions» por una condición `if (actor.endsWith("[bot]"))`;
  y el objetivo real no era el `GITHUB_TOKEN` sino que «the most critical are
  `ACTIONS_ID_TOKEN_REQUEST_TOKEN` and `ACTIONS_ID_TOKEN_REQUEST_URL`» — es decir, **robo del
  token OIDC y compromiso de la cadena de suministro**. Corregido en `claude-code-action` v1.0.94.
  **Lecciones que se retienen, no la anécdota**:
  1. La cadena completa fue **issue público → inyección → exfiltración de variables de entorno →
     escritura en el repositorio**. Cada eslabón era un permiso concedido por comodidad.
  2. **El identificador de actor no es una autorización.** Confiar en un sufijo de nombre es el
     mismo error de siempre, con ropa nueva.
  3. **Los canales de exfiltración son cualquier salida del agente**: escribir en el issue,
     pasar una URL como argumento a una herramienta legítima, o el propio resumen público de la
     ejecución. Acotar "la red" sin acotar las herramientas no sirve.
- **Regla de equipo**: **un agente disparado por contenido de terceros y con acceso a secretos es
  una vulnerabilidad, no una configuración.** Y ningún proveedor "lo ha arreglado": varias de
  estas exposiciones se han clasificado como limitación arquitectónica, no como defecto puntual.

### 5.3 Permisos en la estación de trabajo

- **Alcance de ficheros**: el repositorio de trabajo. **Nunca `$HOME`**, nunca `~/.ssh`,
  `~/.aws`, `~/.kube`, `~/.config`, el gestor de contraseñas ni otro repositorio.
- **Credenciales**: el proceso del agente **no ve credenciales de escritura ni de producción**.
  Si el entorno de desarrollo exporta variables con tokens reales, el agente las lee: **el
  entorno se limpia antes**, no se confía en que no las use. La custodia y rotación son de
  `secrets-management-standards`; el requisito de flujo es este.
- **Ejecución de comandos**: lista de permitidos explícita. **PROHIBIDA la autoaprobación total**
  (el modo "que haga lo que quiera") fuera de un contenedor desechable y sin credenciales. Toda
  ejecución de red saliente arbitraria es, por sí sola, un canal de exfiltración.
- **Aprobación por acción irreversible** (§2), no por sesión ni por lote: aprobar una vez "todo
  lo que venga" anula el control.
- **Aislamiento**: contenedor o *worktree* desechable. **El endurecimiento de la máquina es de
  `developer-workstation-standards`**; aquí el requisito de que exista y de que el agente no
  comparta identidad con la persona.
- **Control de versiones antes que agente**: sin árbol limpio y commit previo no hay forma de
  saber qué cambió ni de deshacerlo. Es la condición barata que hace reversible casi todo lo demás.

### 5.4 El agente en CI es una identidad con permisos

- **Es un principal más**, y se trata como tal: identidad propia, permisos mínimos, credenciales
  efímeras (OIDC antes que clave estática), auditoría de lo que hace.
- **Nunca disparar un agente con secretos desde un evento que puede originar un tercero** (issue,
  comentario, PR de fork) sin: verificación de que el actor es humano y tiene permiso de
  escritura **real** (no por nombre, §5.2), permisos del token reducidos al mínimo, y ningún
  secreto en el entorno más allá de lo estrictamente necesario.
- **Sin permiso de escritura sobre**: ficheros de workflow, configuración de la propia acción,
  ramas protegidas, releases, registro de paquetes. Que un agente pueda modificar el workflow que
  lo ejecuta es **escalada de privilegio por diseño**.
- **Un agente en CI no aprueba PRs, no fusiona y no publica.** Propone; firma una persona.
- **Fijar la versión de la acción por digest**, no por etiqueta móvil, y seguir sus avisos de
  seguridad: en este ecosistema los parches llegan por incidente, no por calendario.
- **Registrar**: qué ejecutó, qué leyó y qué escribió. Sin traza no hay respuesta a incidente.

## 6. Evidencia, medición y coste

> *Sustituye a «Rendimiento y operabilidad» de la plantilla: en un dominio de proceso lo que se
> opera y se mide es el flujo del equipo, no un runtime.*

### 6.1 La evidencia real sobre productividad

**Regla de esta sección: se cita lo que tiene metodología publicada, con su n y su diseño, y se
descarta lo demás por nombre.**

**1. El ensayo controlado con desarrolladores experimentados — resultado contrario a la
percepción de los participantes.** *Measuring the Impact of Early-2025 AI on Experienced
Open-Source Developer Productivity* (METR, arXiv 2507.09089; publicado 10-jul-2025). Diseño:
**16 desarrolladores** con experiencia media de ~5 años en sus propios repositorios maduros,
**246 tareas** reales de su backlog, **aleatorización por tarea** (permitido / no permitido usar
IA), retribuidos a 150 $/h. Resultado: **las tareas tardaron un 19 % más** con IA permitida.
**El hallazgo que importa no es el 19 %**: los participantes preveían un 24 % de mejora y,
**después de hacerlo, seguían estimando un 20 % de mejora**. La percepción de velocidad y el
reloj apuntaron en direcciones opuestas. Límites que hay que citar con el dato: n pequeño,
herramientas de principios de 2025, y un escenario deliberadamente adverso (experto en código
que conoce a fondo).

**2. El seguimiento, y por qué no cierra el debate.** METR, *We are Changing our Developer
Productivity Experiment Design* (24-feb-2026). Citas *verbatim*: «Early 2025 study found the use
of AI causes tasks to take 19% longer, with a confidence interval between +2% and +39%»; «For the
subset of the original developers who participated in the later study, we now estimate a speedup
of -18% with a confidence interval between -38% and +9%»; «Among newly-recruited developers the
estimated speedup is -4%, with a confidence interval between -15% and +9%»; muestra: «We have data
from 57 developers, across 143 repos, and 800+ tasks». Y el motivo por el que **ellos mismos no
lo dan por válido**: «The primary reason is that we have observed a significant increase in
developers choosing not to participate in the study because they do not wish to work without AI,
which likely biases downwards our estimate of AI-assisted speedup.» **Los dos intervalos cruzan
el cero.** Lectura correcta: hay indicios de mejora respecto a 2025, la magnitud no está
establecida, y **METR marca el estudio original como histórico**. Quien cite el "-18 %" como
resultado limpio está citando mal a la fuente.

**3. El ensayo controlado en empresa, con resultado en el otro sentido.** *How much does AI impact
development speed? An enterprise-based randomized controlled trial* (Paradis et al., arXiv
2410.12944, oct-2024; ICSE-SEIP 2025). Diseño: **96 ingenieros a tiempo completo de Google**,
asignación aleatoria a tratamiento (autocompletado, *smart paste* y chat activados) o control
(desactivados), **una tarea empresarial realista** (construir un servicio de *logging*, ~10
ficheros y ~474 líneas). Resultado: **~21 % más rápido** (96 min vs. 114 min de media),
**con intervalo de confianza amplio** y p = .038.
**Cómo se reconcilia con el 1**: no se contradicen, miden situaciones distintas. Tarea acotada,
bien definida y con contexto limitado → ganancia. Repositorio enorme que el desarrollador ya
domina → pérdida. **Eso es exactamente el filtro 3 del §3.1, con datos.**

**4. El informe sectorial de referencia — y cuál es la edición vigente.** El buque insignia es
**«2025 State of AI-assisted Software Development»** de DORA (Google Cloud): ~5.000 profesionales
encuestados, trabajo de campo del **13-jun al 21-jul-2025**, más de 100 horas de datos
cualitativos; abandona los grupos de rendimiento y propone siete arquetipos de equipo; su tesis
central es que **la IA amplifica las fortalezas y las debilidades organizativas existentes**.
**Precaución obligatoria al citarlo: sus medidas de productividad son autodeclaradas** — es decir,
miden exactamente la variable que el ensayo del punto 1 demostró que se desvía del reloj. Sirve
para leer adopción, prácticas y condiciones organizativas; **no sirve como prueba de aceleración
real**.
*Discrepancia declarada sobre la edición*: `dora.dev/research/publications/` lista, sin año,
«ROI of AI-assisted Software Development report», «DORA AI Capabilities Model report» y
«2025 State of AI-assisted Software Development report», y **no muestra ninguna publicación
fechada en 2026**; sin embargo el propio DORA versiona el informe de ROI como **2026.1** y la
cobertura de prensa lo sitúa en abril-mayo de 2026. **Conclusión: el informe insignia vigente es
el de 2025; el de ROI es un documento distinto, más reciente y de naturaleza prescriptiva (marco
de cálculo y curva en J), no un estudio nuevo.** Confundirlos es el error de edición habitual.

**Descartado explícitamente, y por qué**: las cifras de aceleración publicadas por proveedores de
herramientas —porcentajes de "tareas completadas más rápido", "líneas aceptadas" o "X % de
productividad"— **circulan sin metodología, sin n, sin grupo de control y sin definición de la
tarea**. No se citan en una decisión de equipo, no se ponen en una diapositiva y no se usan para
justificar un despliegue. **Si no hay diseño publicado, no hay dato.** Lo mismo aplica a las
métricas de "porcentaje de código escrito por IA": miden generación, no valor, y son trivialmente
inflables.

### 6.2 Lo que sí puedes medir en tu equipo

- **Métricas de flujo de entrega ya existentes** (`sre-practice-standards`, `git-workflow-standards`):
  *lead time*, frecuencia de despliegue, **tasa de fallo de cambio** y **tiempo de restauración**.
  Son el único contrapeso honesto: si la velocidad sube y el fallo de cambio también, no hay
  ganancia, hay traslado de coste a producción.
- **Tiempo de revisión y número de idas y vueltas por PR**, separando el origen del cambio. Es
  donde aparece el trabajo desplazado del §1.
- **Retrabajo**: proporción de cambios que se revierten o se corrigen en los días siguientes.
- **Coste**: gasto por equipo y por tarea, con techo. Un agente sin límite de gasto es un
  incidente de facturación esperando su turno.
- **Antes de desplegar la herramienta, se fija la línea base.** Sin medición previa no hay
  comparación posible y la evaluación acaba siendo la percepción del §6.1.

### 6.3 Cómo NO se mide

- ❌ **Ninguna métrica individual.** Ni líneas generadas, ni tasa de aceptación, ni PRs por
  persona, ni "porcentaje de uso de IA". Medir la adopción por persona convierte la herramienta
  en un objetivo y corrompe el dato el primer día.
- ❌ Percepción de velocidad como prueba de velocidad (§6.1).
- ❌ Comparar equipos entre sí con estas métricas.

## 7. Sostenibilidad, política de equipo y prohibiciones

### 7.1 Atribución y licencia del código generado

- **Lo que sí hay publicado y firme (EE. UU.)**: la Oficina de Derechos de Autor publicó en
  **enero de 2025** *Copyright and Artificial Intelligence, Part 2: Copyrightability*. Sostiene
  que **la autoría humana es requisito**, que **el prompt por sí solo no basta** con la
  tecnología actual para constituir autoría, que **usar IA como herramienta de asistencia no
  perjudica** la protección de la obra resultante, y que una obra mixta puede protegerse **en la
  parte con autoría humana suficiente**, debiendo **excluirse (*disclaim*) lo generado por IA**
  al registrar. La tercera parte del informe, sobre entrenamiento y responsabilidad, es un
  documento distinto.
- **Lo que NO está resuelto, y se dice así**: la aplicación concreta al **código fuente**
  (dónde está el umbral de "autoría humana suficiente" en un diff asistido), el efecto en la
  **licencia de salida** de un proyecto de código abierto, y la situación en **otras
  jurisdicciones**, que no es uniforme. **No hay una posición firme y universal publicada.**
  Cualquier afirmación tajante sobre "el código de IA es de dominio público" o "es tuyo sin
  matices" es falsa por exceso de precisión.
- **Reglas que sí se pueden fijar hoy, sin depender de eso**:
  - **Se declara**. El commit o el PR indica que hubo asistencia de IA, con la convención del
    repositorio (`git-workflow-standards` fija el formato del *trailer*).
  - **Fragmentos largos y reconocibles de un proyecto conocido no entran.** Si el resultado
    parece copiado de una fuente identificable, se verifica el origen y su licencia antes de
    fusionar. Esto es procedencia, no estilo.
  - **Los términos del proveedor sobre propiedad, indemnización y uso de tu código para
    entrenamiento se leen antes de adoptar la herramienta** y se revisan al renovar. La debida
    diligencia del proveedor la gobierna `ai-governance-standards`; aquí solo la obligación de
    que no se adopte una herramienta sin haberlo leído.
  - En proyectos con **CLA o con licencia copyleft estricta**, consultar antes: la declaración
    de autoría que firma el contribuidor puede no encajar con un cambio mayoritariamente
    generado.

### 7.2 Política de equipo — qué se declara, qué se registra, qué exige revisión humana

Se escribe una vez, vive en el repositorio (o en el `AGENTS.md` de la organización) y se revisa
con cadencia. Contenido mínimo:

1. **Qué herramientas están aprobadas** y cuáles no, con su versión mínima y sus avisos de
   seguridad seguidos.
2. **Qué se declara**: todo cambio con asistencia de IA, en el commit o en el PR.
3. **Qué se registra**: uso del agente en CI (qué ejecutó, qué leyó, qué escribió), gasto por
   equipo, y las aprobaciones de acciones irreversibles.
4. **Qué exige revisión humana obligatoria — sin excepción**: **todo**. Y **revisión reforzada
   (segundo revisor especialista)** en: autenticación y autorización, criptografía, migraciones
   de datos, infraestructura y permisos, código de pago o facturación, tratamiento de datos
   personales, y **cualquier cambio en el propio flujo de agentes** (workflow, `AGENTS.md`,
   permisos, lista de comandos permitidos).
5. **Qué está prohibido delegar** (§3.2 y §7.3), en la lista concreta de este equipo.
6. **Qué se hace ante un incidente causado por un cambio de agente**: postmortem sin culpa
   normal, con una pregunta añadida — **cuál de los tres filtros del §3.1 falló**.
7. **Formación de quien entra**: alguien que no sabe revisar código de agente no debería enviar
   código de agente. La destreza que hay que enseñar es **verificar**, no *promptear*.

### 7.3 Prohibiciones

- ❌ **PROHIBIDO dar a un agente credenciales de producción**, en cualquier forma: variable de
  entorno, fichero de configuración, perfil de nube activo, sesión abierta o túnel. No hay tarea
  que lo justifique.
- ❌ **PROHIBIDO ejecutar un agente sobre un árbol sin control de versiones** o con cambios sin
  confirmar. Sin línea base no hay reversión ni diagnóstico.
- ❌ **PROHIBIDO fusionar un cambio que nadie del equipo entiende.** Ni por urgencia, ni porque
  los tests pasen, ni porque "funciona".
- ❌ Fusionar sin revisión humana. La aprobación de un agente **no cuenta como aprobación**.
- ❌ Autoaprobación total de comandos fuera de un contenedor desechable y sin credenciales.
- ❌ Dar al agente acceso a `$HOME`, a claves SSH, a credenciales de nube o a otro repositorio.
- ❌ Disparar un agente con secretos desde un evento originado por un tercero (§5.4).
- ❌ Que un agente tenga permiso de escritura sobre el workflow, la configuración o los permisos
  que lo gobiernan.
- ❌ Que un agente apruebe un PR, lo fusione, publique un paquete, cree un release o despliegue.
- ❌ Delegar la **ejecución** de una acción irreversible (migración, borrado, despliegue, gasto).
- ❌ Delegar el arreglo en la ruta crítica de un incidente en curso.
- ❌ Aceptar un diff porque compila y pasa los tests, sin comprobar que **hace lo que se pidió**
  y que el test de regresión **falla sin el arreglo**.
- ❌ Tratar el contenido leído por el agente (issue, web, dependencia, salida de herramienta)
  como confiable.
- ❌ Poner secretos, URLs internas sensibles o datos personales en `AGENTS.md`/`CLAUDE.md`.
- ❌ Medir a personas por su uso de IA, o publicar métricas individuales de adopción.
- ❌ Citar cifras de productividad **sin metodología publicada** —de proveedor o de blog— para
  justificar una decisión de equipo (§6.1).
- ❌ Usar una acción de agente en CI fijada por **etiqueta móvil** en lugar de por digest.
- ❌ Adoptar una herramienta de agente sin haber leído sus términos sobre propiedad del código y
  uso de tu repositorio para entrenamiento.

## 8. Verificación web obligatoria

Comprobar **antes de fijar nada** en un equipo real:

1. **Estudios de productividad**: si METR ha publicado el rediseño anunciado en feb-2026 y con
   qué resultado; si hay nuevos ensayos controlados con metodología publicada. **Verificado en
   esta pasada**: METR arXiv 2507.09089 (16 desarrolladores, 246 tareas, +19 % de duración);
   METR 24-feb-2026 (57 desarrolladores, 143 repos, 800+ tareas; **intervalos que cruzan el cero
   y sesgo de selección declarado por los propios autores**); Paradis et al. arXiv 2410.12944
   (96 ingenieros de Google, ~21 % más rápido, IC amplio, p = .038).
2. **Informe sectorial**: **cuál es la edición vigente**. Verificado: el insignia es
   «2025 State of AI-assisted Software Development» (DORA/Google Cloud, campo jun-jul 2025,
   ~5.000 respuestas, **medidas autodeclaradas**); el «ROI of AI-assisted Software Development»
   está versionado **2026.1** y es un documento distinto, prescriptivo. **Discrepancia declarada
   en §6.1**: la página de publicaciones de DORA no muestra ninguna publicación fechada en 2026
   pese a esa versión. Verificar en `dora.dev` antes de citar una edición.
3. **Inyección de prompt en agentes de codificación**: avisos de seguridad y versiones parcheadas
   de la herramienta concreta que uses. Verificado el caso de `claude-code-action`
   (divulgación 1-jun-2026, corregido en v1.0.94). **Verificar si hay avisos posteriores**: en
   este ecosistema la cadencia la marcan los incidentes.
4. **Guías y taxonomías**: estado de OWASP para riesgos de LLM y agénticos, y si ha aparecido
   guía específica para agentes de codificación en cadena de suministro. **Este punto se
   verifica, no se recuerda**: los identificadores y los nombres de esas listas han cambiado
   entre ediciones.
5. **Autoría y licencia**: si hay novedades tras *Copyright and Artificial Intelligence, Part 2*
   (ene-2025) y, sobre todo, **si existe posición firme aplicable al código fuente** o al
   ámbito europeo. **En ago-2026 no se ha localizado ninguna**: §7.1 lo declara como no resuelto
   en vez de rellenarlo.
6. **`AGENTS.md`**: estado de la especificación y su gobernanza, y qué herramientas la soportan
   de verdad. *Nota de calibración*: las cifras de adopción que circulan (decenas de miles de
   repositorios) **provienen de material divulgativo y varían entre fuentes por más del 50 %**;
   no se usan aquí como dato.
7. **Herramienta concreta**: versión, modelo de permisos vigente, qué hace por defecto y qué
   telemetría envía. **Los defaults de permisos cambian entre versiones menores**: leerlos en
   cada actualización, no una vez.
8. **Huecos declarados (sin presupuesto de verificación en esta pasada)**:
   - No se ha localizado ningún estudio con metodología publicada sobre **el efecto del código
     generado por agente en la carga o la eficacia de la revisión** —que es justo la variable
     central del §1—. **No se inventa un número**: la afirmación del §1 es un argumento de
     mecanismo, no un resultado empírico, y así está escrita.
   - No se ha verificado el estado ni el modelo de permisos de las alternativas
     (Copilot coding agent, Cursor, Devin, Windsurf, Codex, Gemini CLI, Aider): §5 fija el
     criterio de permisos que **cualquiera** de ellas debe cumplir; el detalle de cada una se
     verifica en su documentación antes de aprobarla.
   - Los estudios que cuestionan los `AGENTS.md` generados por LLM (reducción de tasa de éxito)
     aparecen en *preprints* de 2026 que **no se han leído en origen** en esta pasada; el §3.3
     solo cita el que sí se verificó verbatim. Antes de afirmar lo contrario, leerlos.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
