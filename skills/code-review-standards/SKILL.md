---
name: code-review-standards
description: Code review as an explicit quality control, not an opinion about someone else's style. Use when reviewing or authoring a pull/merge request diff, writing a PR description or review checklist, deciding what blocks a merge versus what is a suggestion, labelling review comments (Conventional Comments, nit:, blocking:), setting review SLA and stale-PR policy, assigning reviewers or debugging a CODEOWNERS bottleneck, requiring a second or specialist reviewer for high-risk changes (data migrations, authn/authz, cryptography, concurrency, infrastructure), reviewing AI-generated or agent-authored diffs, arguing about formatting in a review, escalating a review disagreement to an ADR, choosing review metrics, or replacing async review with pair or mob programming.
---

# Estándares de revisión de código

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **qué se mira dentro de un diff, en qué orden, qué bloquea, cómo se escribe el comentario
y quién tiene que firmar según el riesgo del cambio**: orden de búsqueda por valor, criterio de
bloqueo, convención de etiquetas de comentario, contenido exigible de la descripción del PR,
asignación de revisores y cuello de botella de `CODEOWNERS`, revisión de cambios de alto riesgo,
revisión de código generado por IA, resolución de desacuerdos, automatización previa a la revisión
y métricas del proceso.

Principio rector: **la revisión es un control de calidad con criterios explícitos, no una opinión
sobre el estilo ajeno.** Un control de calidad tiene entradas definidas (un diff pequeño, verde en
CI y con contexto escrito), criterios falsables (esto bloquea, esto no) y una salida binaria
(aprobado / cambios requeridos con razón). Todo lo que no encaje en eso — preferencia estética,
demostración de conocimiento, negociación de poder — **no es revisión**.

**Frontera fina con `git-workflow-standards`** (leída de su §1 y su §3.4, que ya reclama tamaño de
PR, descripción, SLA, `CODEOWNERS` y protección de rama). Reparto, sin ambigüedad:

| Pregunta | Dueño |
|---|---|
| ¿Cómo se rama, se commitea, se hace *squash* y se etiqueta? ¿Cuál es el **límite numérico** de tamaño de diff del repo? ¿Qué rutas exigen *owner* y qué reglas protegen `main`? ¿Cuál es el SLA de primera respuesta como regla del repositorio? | **`git-workflow-standards`** |
| ¿Qué busca el revisor dentro de ese diff y en qué orden? ¿Qué constituye motivo de bloqueo? ¿Cómo se redacta el comentario? ¿Qué exige un cambio de alto riesgo? ¿Cómo se revisa un diff que escribió un agente? ¿Qué se hace ante desacuerdo? | **Esta skill** |
| Ambas fijan un número sobre lo mismo (tamaño de PR, SLA) | **Manda `git-workflow-standards`**: es la regla mecánica del repositorio. Aquí se aporta la **evidencia** de por qué ese número existe y qué le pasa a la eficacia de la revisión al superarlo (§3.4). Si los dos números divergen, se corrige el de esta skill. |

**No aplica**: ver `git-workflow-standards` (arriba), `cicd-standards` (**la pipeline y sus gates
son suyos**: jobs, orden, runners, *required checks*; aquí **qué debe estar verde antes de que una
persona mire el diff** y con qué umbral), `testing-qa-standards` (qué se prueba, en qué proporción
y qué rompe el build; aquí solo **el test como objeto de revisión** y la exigencia de test de
regresión), `appsec-standards` (**modelado de amenazas y triaje de hallazgos son suyos**; aquí la
revisión humana como control y el *checklist* de riesgo del diff — §5), `secrets-management-standards`
(gestión y rotación de secretos; aquí solo detectar el secreto que entra por el diff),
`sre-practice-standards` (fiabilidad, SLO y *error budget*; **el despliegue progresivo del cambio
revisado se coordina allí**), `incident-management-standards` (postmortem sin culpa; aquí la regla
de que el arreglo llega con test de regresión y revisión de un segundo par de ojos),
`observability-standards` (qué telemetría debe existir; aquí exigirla en el diff que la necesita),
`grc-compliance-standards` (segregación de funciones y evidencia de auditoría que la revisión
produce), `ai-agents-standards` (ingeniería del agente en sí) y `ai-agent-workflow-standards`
(cómo se trabaja con agentes de código en equipo; **aquí solo la revisión del
resultado**), `claude-code-skills-standards` (autoría de skills), las skills de lenguaje (qué es
idiomático en ese lenguaje: el revisor las cita, no las reinventa en el hilo),
`tech-leadership-standards` (el criterio de qué se revisa y cómo se comenta es de aquí;
**que la revisión no se convierta en instrumento de poder ni en cuello de botella de una persona es
responsabilidad de liderazgo y es suyo** — igual que la decisión de no usar métricas de revisión
para evaluar individuos), `refactoring-tech-debt-standards` (el criterio de qué se refactoriza y cómo se registra
la deuda es suyo; **aquí la consecuencia para la revisión, que no es menor: un refactor y un cambio
funcional no se revisan igual y no van en el mismo commit**. Un diff donde la reestructuración
esconde un cambio de comportamiento es irrevisable, y esa es razón suficiente para devolverlo).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de las fuentes citadas por web antes de fijar nada (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Qué decide la revisión | Corrección, riesgo y mantenibilidad | — |
| Quién decide el formato | **El formateador automático en CI**, nunca el revisor | — |
| Aprobaciones | **1** en cambio ordinario; **2, uno de ellos especialista**, en alto riesgo (§5) | 1 en repos de un solo dueño con revisión asíncrona posterior documentada |
| Etiquetado de comentarios | **Conventional Comments** (`issue:`, `suggestion:`, `nitpick:`, `question:`, `praise:`, `note:`) con `(blocking)` / `(non-blocking)` explícito | Convención propia mínima: prefijo `blocking:` / `nit:` — pero **escrita y aplicada por todos** |
| Por defecto de un comentario | **No bloqueante** salvo etiqueta explícita de bloqueo | — |
| Descripción del PR | Obligatoria, con las cuatro respuestas del §3.3 | — |
| Umbral de idas y vueltas | **3**; a la cuarta, conversación síncrona y resumen escrito en el PR | — |
| Desacuerdo no resuelto | Escalado a un tercero técnico; si es una decisión de diseño, **ADR** y se desbloquea el PR | — |
| Revisión de alto riesgo | **Revisor específico obligatorio** por dominio (§5) | — |
| Código generado por IA | **Mismo listón, más escepticismo**; responde quien lo envía (§6) | — |
| Revisor automático (LLM) | **Asesor, nunca aprobador**: sus comentarios son hipótesis a verificar | — |
| Alternativa a la revisión asíncrona | **Pair/mob** en cambios exploratorios, de alto riesgo o de transferencia de conocimiento; sustituye a la revisión si el segundo par de ojos estuvo presente **durante** la escritura y queda constancia | — |
| Métricas | Solo agregadas y de **proceso** (§4.3) | — |

## 3. Qué decide una revisión y qué no

### 3.1 El estilo no se discute en una revisión

- **El formato lo decide el formateador automático.** No hay negociación, no hay preferencia y no
  hay comentario: se ejecuta en CI y rompe el build. La herramienta concreta la fija la skill del
  lenguaje.
- **Si se discute formato en una revisión, falta un formateador en CI.** Dicho así: cada hilo
  sobre comillas, sangrado, orden de imports o longitud de línea es un **defecto de configuración
  del repositorio**, no un desacuerdo entre personas. La acción correcta no es responder al hilo:
  es abrir el PR que añade el formateador y cerrar el hilo con el enlace.
- Lo mismo aplica a lo que un linter o un *type checker* puede decidir: si una regla es
  automatizable y el equipo la quiere, se automatiza; si no se automatiza, **deja de ser
  exigible en revisión**.

### 3.2 Orden de búsqueda, de mayor a menor valor

Se revisa en este orden y se para cuando el diff ya no da más. Un revisor que empieza por el final
de esta lista está gastando su atención en lo barato.

1. **Corrección y casos límite**: ¿hace lo que dice la descripción? Valores nulos/vacíos,
   colecciones de cero y de uno, límites, desbordamiento, unidades y zonas horarias, precisión
   decimal en dinero, idempotencia ante reintento.
2. **Seguridad**: entrada no validada llegando a un *sink*, autorización ausente o evaluada en el
   cliente, secreto en el diff, dependencia nueva, deserialización, construcción dinámica de
   consultas o comandos. Clases y triaje: `appsec-standards`.
3. **Contrato roto**: cambio incompatible en API, esquema, evento o formato persistido; y su
   consecuencia sobre consumidores ya desplegados.
4. **Concurrencia y estado compartido**: sección crítica sin protección, orden de bloqueo,
   *check-then-act*, reentrada, suposición de ejecución en un único proceso.
5. **Manejo de errores y recursos**: error tragado, error sin contexto, estado a medias tras
   fallo, recurso no liberado, ausencia de *timeout* o de límite.
6. **Observabilidad**: ¿se puede diagnosticar esto en producción a las 3 de la mañana? Log
   estructurado con correlación, métrica del camino nuevo, y **ningún dato personal ni secreto en
   el log**.
7. **Tests**: ¿prueban comportamiento o implementación? ¿Cubren el borde que el diff introduce?
   ¿Hay test de regresión si esto es un *bugfix*? Criterio: `testing-qa-standards`.
8. **Mantenibilidad**: nombres que revelan intención, tamaño y responsabilidad de la unidad,
   duplicación **esencial** (no accidental), acoplamiento nuevo, deuda declarada con TODO + motivo.

### 3.3 Lo que NO hay que buscar

- ❌ Formato, orden de miembros, estilo de comillas o de llaves (§3.1).
- ❌ Reescrituras equivalentes por gusto ("yo lo habría hecho con `map`").
- ❌ Refactors fuera del alcance del PR. Se anotan como `note:` o ticket; **no bloquean**.
- ❌ Arquitectura que ya se decidió: si el diseño se discutió antes, el momento de objetar era
  antes. Si el revisor cree que la decisión fue mala, el vehículo es un ADR, no bloquear el PR.
- ❌ Defectos que una herramienta debería encontrar: si el revisor los encuentra a mano de forma
  recurrente, el arreglo es añadir la herramienta (§4.1).
- ❌ Reescribir el código del autor en el hilo salvo que se pida: la sugerencia se propone, la
  autoría se respeta.

### 3.4 Descripción del PR: requisito de entrada, no cortesía

Un PR sin las cuatro respuestas **no está listo para revisión** y se devuelve sin leer el diff:

1. **Qué cambia** (en comportamiento observable, no en ficheros tocados).
2. **Por qué** (el problema, el ticket, la alternativa descartada).
3. **Cómo se ha probado** (qué test nuevo, qué se verificó a mano y en qué entorno).
4. **Qué riesgo tiene y cómo se revierte** (migración, *feature flag*, plan de *rollback*).

Regla de honestidad: si la respuesta a "cómo se ha probado" es *"el asistente dijo que estaba
bien"*, el PR no está listo (§6). El formato del título y la mecánica del PR son de
`git-workflow-standards`.

### 3.5 Tamaño del cambio: el factor con más impacto, con la evidencia disponible

Es la única variable con evidencia publicada consistente. Se cita con fuente, y con sus reservas.

- **Estudio de Cisco / SmartBear** (*Code Review at Cisco Systems*, capítulo de *Best Kept Secrets
  of Peer Code Review*; 10 meses, jul-2005 a may-2006, grupo MeetingPlace de Cisco Systems,
  **2500 revisiones de 3,2 millones de líneas escritas por 50 desarrolladores**). Verbatim:
  - *"Reviewers are most effective at reviewing small amounts of code. Anything below 200 lines
    produces a relatively high rate of defects, often several times the average. After that the
    results trail off considerably; no review larger than 250 lines produced more than 37 defects
    per 1000 lines of code"*.
  - *"Reviewers slower than 400 lines per hour were above average in their ability to uncover
    defects. But when faster than 450 lines/hour the defect density is below average in 87% of the
    cases."*
  - *"Total review time should be less than 60 minutes, not to exceed 90. Defect detection rates
    plummet after that time."*
  - *"the single best piece of advice we can give is to review between 100 and 300 lines of code at
    a time and spend 30-60 minutes to review it."*
  - **Reservas que el propio estudio declara y que hay que citar con él**: asume densidad de
    defectos constante — *"we're tacitly assuming that true defect density is constant over both
    large and small code changes"* —, de modo que "menos defectos por kLOC en revisiones grandes"
    se interpreta como *menos eficacia*, no como *mejor código*. Añádase que **lo condujo el
    fabricante de la herramienta revisada**: la dirección del efecto es creíble y coherente con la
    práctica, los valores exactos no son un universal.
- **Práctica publicada de Google** (*Google Engineering Practices*, guía "Small CLs"), verbatim:
  *"100 lines is usually a reasonable size for a CL, and 1000 lines is usually too large"*;
  *"The number of files that a change is spread across also affects its 'size.' A 200-line change
  in one file might be okay, but spread across 50 files it would usually be too large"*; y la regla
  que hay que copiar tal cual: *"Reviewers have discretion to reject your change outright for the
  sole reason of it being too large"*.
- **Datos observacionales** (Sadowski, Söderberg, Church, Sipko, Bacchelli, *Modern Code Review:
  A Case Study at Google*, **ICSE-SEIP 2018**, pp. 181-190, DOI 10.1145/3183519.3183525; análisis
  de registros de **9 millones de revisiones**), verbatim: *"Over 10% of changes modify only a
  single line of code, and the median number of lines modified is 24"*; *"over 35% of the changes
  under consideration modify only a single file and about 90% modify fewer than 10 files"*;
  *"fewer than 25% of changes have more than one reviewer, and over 99% have at most five reviewers
  with a median reviewer count of 1"*; *"the average number of comments per change grows with the
  number of lines changed, reaching a peak of 12.5 comments per change for changes of about 1250
  lines"*.

**Criterio operativo que se deriva**: el revisor **rechaza por tamaño sin leer** cuando el diff
supera el límite del repositorio (que fija `git-workflow-standards`) sin justificación declarada;
una sesión de revisión no pasa de ~60 minutos; y un diff que no cabe en una sesión se trocea, no se
"revisa por encima". **Excepción declarada**: cambios mecánicos (generados, renombrado masivo,
*lockfiles*) se separan **en su propio PR** y se revisan por el comando que los produjo, no línea a
línea.

### 3.6 Tiempo de respuesta y el coste de un PR parado

- **Un PR parado es inventario que se deprecia**: envejece contra `main`, bloquea al autor,
  provoca cambio de contexto y crece cuando el autor "aprovecha" para meter otra cosa.
- Regla publicada de referencia (*Google Engineering Practices*, "Speed of Code Reviews"),
  verbatim: *"One business day is the maximum time it should take to respond to a code review
  request (i.e., first thing the next morning)"*, y sobre el coste: *"The velocity of the team as a
  whole is decreased. Yes, the individual who doesn't respond quickly to the review gets other work
  done. However, new features and bug fixes for the rest of the team are delayed by days, weeks, or
  months as each CL waits for review and re-review."* El SLA concreto del repositorio lo fija
  `git-workflow-standards`.
- **Responder rápido ≠ aprobar rápido.** La métrica es el tiempo hasta la **primera respuesta**;
  una respuesta válida puede ser "no puedo hoy, pásalo a X".
- **Revisión parcial explícita**: si solo has revisado una parte, dilo y aprueba solo esa parte.
  Silencio + LGTM tardío es peor que un "revisado solo el módulo de pagos".
- PR abierto y sin actividad más allá del plazo del repo: se cierra o se rescata; no se acumula.

### 3.7 Asignación de revisores y el cuello de botella de `CODEOWNERS`

- `CODEOWNERS` protege las rutas donde un error cuesta caro (autenticación, migraciones, IaC,
  workflows de CI, contratos de API). El fichero y la protección de rama son de
  `git-workflow-standards`; **aquí el efecto humano**.
- **El cuello de botella es real y hay que gestionarlo, no negarlo**: si una persona o un equipo
  aparece en la mayoría de los PR, el proceso está diseñado para pararse cuando esa persona esté
  ocupada, de vacaciones o se marche. Señales: PRs esperando *owner* más allá del SLA de forma
  sistemática; un solo nombre aprobando la mayoría de los cambios de un área.
- Mitigaciones, en orden: **mínimo dos *owners* por ruta** y nunca una persona sola; rotación
  explícita de revisión; ampliar el grupo mediante revisión emparejada (el *owner* revisa junto a
  quien se está formando) hasta poder añadirlo; y **reducir el ámbito** de `CODEOWNERS` a lo que
  realmente es crítico — cuanto más cubre, más se aprueba sin leer.
- **PROHIBIDO usar `CODEOWNERS` como control de territorio**: la propiedad es de la calidad del
  código, no del permiso para tocarlo.

### 3.8 Cómo se escribe un comentario

- **Etiqueta obligatoria**, y el bloqueo es explícito. Con Conventional Comments, formato
  `<label> [decorations]: <subject>` y las definiciones canónicas: `issue:` — *"Issues highlight
  specific problems with the subject under review"*; `suggestion:` — *"Suggestions propose
  improvements to the current subject. It's important to be explicit and clear on what is being
  suggested and why it is an improvement"*; `nitpick:` — *"Nitpicks are trivial preference-based
  requests. These should be non-blocking by nature"*; `question:` — *"Questions are appropriate if
  you have a potential concern but are not quite sure if it's relevant or not"*; `note:` —
  *"Notes are always non-blocking and simply highlight something the reader should take note of"*;
  `praise:` — *"Praises highlight something positive. Try to leave at least one of these comments
  per review"*. **Un comentario sin etiqueta se lee como bloqueante y hace perder el tiempo a todo
  el mundo.**
- **Se pide el cambio con la razón, no con la preferencia.** Formato exigible: *qué* está mal,
  *por qué* importa (defecto, riesgo, coste futuro concreto) y *qué* lo resolvería. "Esto no me
  gusta" y "yo lo haría distinto" **no son razones** y no bloquean nada.
- **Se ataca el código, no a la persona.** Se escribe sobre el código en tercera persona ("esta
  función deja la conexión abierta si lanza"), no sobre el autor ("dejas la conexión abierta").
  Sin sarcasmo, sin "obviamente", sin "otra vez". El "por qué" se explica siempre: un comentario
  sin razón es una orden, y una orden en una revisión es una relación de poder, no un control de
  calidad.
- **Una preferencia personal nunca bloquea.** Si de verdad importa, se convierte en regla del
  equipo (linter o documento) y entonces sí bloquea — a todos, siempre, y sin discutirlo en el hilo.
- **El autor responde a todos los hilos**: acepta, rebate con razón o abre ticket. Cerrar un hilo
  sin responder es equivalente a ignorar un hallazgo.
- **Desacuerdo**: se argumenta con datos (comportamiento, coste, riesgo). Si sigue vivo tras un
  intercambio, **escalado inmediato** a un tercero técnico acordado. Si es de diseño, se registra
  como **ADR** y el PR **se desbloquea** — un PR no es el sitio donde se decide una arquitectura.
  El bloqueo indefinido por desacuerdo no resuelto está prohibido (§7).

## 4. Automatización previa y métricas del proceso

### 4.1 La persona revisa lo que solo una persona puede revisar

Antes de que un ser humano abra el diff, ya debe estar verde (la ejecución es de `cicd-standards`;
lo que sigue es lo que esta skill **exige** que se compruebe):

1. **Formateador** — comprobación, no sugerencia. Su ausencia genera hilos de estilo (§3.1).
2. **Linter** y reglas del ecosistema.
3. **Tipos / análisis estático**.
4. **Tests** unitarios y de integración, con test de regresión si es *bugfix*
   (`testing-qa-standards`).
5. **Escáneres**: secretos en el diff, SCA de dependencias nuevas, SAST, IaC.
6. **Comprobaciones de contrato** cuando el diff toca una interfaz publicada.

Regla dura: **ningún hallazgo automatizable se deja para la revisión humana**. Y su recíproca:
**una persona no aprueba un PR con CI en rojo** "porque el fallo no tiene que ver". Si el gate no
es fiable, se arregla el gate — no se aprende a ignorarlo.

Lo que **solo** puede hacer una persona, y por tanto es donde debe ir su atención: si el cambio
resuelve el problema real, si el diseño soportará el siguiente requisito, si el caso límite del
dominio está contemplado, si el riesgo declarado es el riesgo real, y si el código será
comprensible dentro de dos años.

### 4.2 El revisor automático basado en LLM

- **Asesor, nunca aprobador.** Sus comentarios son hipótesis: el revisor humano las verifica o las
  descarta, y responde de la decisión. Un LLM no puede rendir cuentas.
- Su aportación real está en lo mecánico y repetitivo (patrones conocidos, olvidos, incoherencias
  con la descripción). Su fallo típico es el **falso positivo seguro de sí mismo**, que consume
  exactamente la atención que la revisión necesitaba.
- **Ruido medido = herramienta apagada**: si una regla del revisor automático genera comentarios
  descartados de forma sistemática, se desactiva esa regla.
- **PROHIBIDO** que una aprobación automática cuente como la aprobación requerida por la
  protección de rama.

### 4.3 Métricas: para mejorar el proceso, nunca para evaluar personas

- Se miden, **solo agregadas por equipo y como serie temporal**: tiempo hasta la primera
  respuesta, tiempo total hasta el *merge*, tamaño del diff, número de idas y vueltas, proporción
  de PR aprobados sin comentarios, PRs abiertos por encima del plazo, y **defectos escapados a
  producción** (la señal que de verdad importa).
- **PROHIBIDO usar cualquier métrica de revisión para evaluar a un individuo** (comentarios
  emitidos, PRs aprobados, velocidad de aprobación, líneas revisadas). El motivo es mecánico, no
  moral: toda métrica de revisión se optimiza trivialmente aprobando más rápido y comentando
  menos, es decir, **destruyendo justo el control que se pretendía medir**. La misma
  mecánica aplica a cualquier proxy de actividad convertido en objetivo; **no se cita aquí ninguna
  cifra** porque no se ha localizado fuente primaria verificable para las que suelen acompañar a
  esta afirmación (§8).
- Una métrica que sube sin que bajen los defectos escapados no es una mejora: es una revisión más
  superficial.
- Las métricas DORA de entrega y la telemetría del pipeline son de `observability-standards` y
  `cicd-standards`.

### 4.4 Pair y mob programming como alternativa

- **Sustituyen a la revisión asíncrona** cuando el segundo par de ojos estuvo presente *durante* la
  escritura: revisión continua, latencia cero, transferencia de conocimiento incorporada.
  Condición para que cuente como control: **queda constancia en el PR de quién co-escribió**
  (`Co-authored-by:`) y de que el cambio se hizo emparejado.
- Encaja mejor en: cambios exploratorios o de diseño abierto, alto riesgo (§5), incorporación de
  personas nuevas y áreas con un único *owner* (§3.7).
- **No sustituye a la revisión** cuando se necesita un revisor **independiente** por requisito de
  segregación de funciones (`grc-compliance-standards`) o cuando el cambio toca un dominio del que
  ninguno de los dos es especialista.
- No es gratis: consume dos personas a la vez. Se elige por riesgo del cambio, no por moda.

## 5. Revisión de cambios de alto riesgo

Clases que **exigen revisor específico del dominio además del revisor ordinario**, porque el error
no se detecta con lectura general y su coste no es proporcional al tamaño del diff:

| Clase | Por qué exige especialista | Qué se comprueba, como mínimo |
|---|---|---|
| **Migración de datos** | Es el cambio con menos *rollback* real y más impacto irreversible | Compatibilidad hacia atrás (*expand/contract*), comportamiento con el volumen real, bloqueos y duración sobre tabla caliente, plan de reversión **ejecutado** en ensayo, idempotencia ante reejecución |
| **Autenticación y autorización** | Un fallo aquí no produce error: produce acceso | Dónde se evalúa la decisión (servidor, siempre), objeto **e** identidad comprobados juntos (IDOR/BOLA), expiración y revocación, ruta que se salta el *middleware*, cambio de rol que amplía privilegio en silencio |
| **Criptografía** | El error es indistinguible del acierto en pruebas funcionales | Algoritmo, modo y tamaño de clave; origen del IV/nonce y su unicidad; comparación en tiempo constante; procedencia y ciclo de vida de la clave; **cero criptografía casera**. Criterio: `cryptography-pki-standards` |
| **Concurrencia y estado compartido** | El fallo es no determinista y no reproducible en revisión | Invariante protegida, orden de bloqueo, *check-then-act*, suposición de proceso único, comportamiento ante reintento |
| **Infraestructura y despliegue** | El *blast radius* es el sistema entero | Diff del plan aplicado (no solo el código), destrucción/recreación de recursos, exposición de red, permisos IAM ampliados, secretos. Criterio: `iac-standards` y las skills de nube |
| **Dependencia nueva o cambio de versión mayor** | Superficie de cadena de suministro | Mantenimiento y licencia, *changelog* de rotura, tamaño de la superficie añadida frente a lo que resuelve |
| **Cambio de contrato público** | Rompe a terceros que no están en el PR | Compatibilidad, versionado y plan de deprecación (`api-design-standards`) |
| **Feature flag y configuración** | Cambia el comportamiento sin pasar por la pipeline | Valor por defecto seguro, alcance, dueño y **fecha de retirada** |

Reglas transversales de esta sección:

- **Secreto detectado en un diff**: el hilo no es "quítalo". El secreto **está comprometido desde
  el push**: se rota, y el borrado del historial se coordina como en `git-workflow-standards`.
  `secrets-management-standards` fija la rotación.
- **PROHIBIDA la autoaprobación** en cualquiera de estas clases, incluida la persona que sea el
  único *owner*: se busca revisor fuera del equipo antes que aprobarse a uno mismo.
- Un cambio de alto riesgo **mezclado con refactor o con cambios de formato** se devuelve para que
  se separe: la señal se pierde en el ruido y el revisor especialista no puede hacer su trabajo.
- El *checklist* de riesgo se aplica al **diff**, no al ticket: lo que cuenta es lo que toca el
  cambio, no lo que dice que hace.

## 6. Revisión de código generado por IA

> La §6 canónica de la plantilla (rendimiento y operabilidad) no aplica a este dominio y **se
> sustituye** por lo que hoy es el mayor cambio operativo de la revisión.

### 6.1 Qué cambia cuando el autor no es humano

- **El listón no baja y el escepticismo sube.** El código generado es *plausible por
  construcción*: sigue las convenciones, tiene buen aspecto y nombres correctos. Esas señales, que
  en un autor humano correlacionaban con cuidado, **dejan de ser evidencia de nada**. Revisar por
  "se lee bien" es, con IA, revisar por lo único que la herramienta garantiza de serie.
- **La asimetría de esfuerzo es el problema estructural**: generar es barato y revisar sigue
  costando lo mismo. Sin una regla de tamaño aplicada con dureza (§3.5), el proceso se rompe por
  el lado de la revisión, no por el de la producción.
- **La trampa concreta a nombrar**: un diff grande, coherente y plausible produce revisión
  superficial con **más** confianza que un diff pequeño y raro. Contramedida operativa: ante un
  diff generado y grande, **se rechaza por tamaño antes de leerlo** y se exige troceado. No se
  hace "una pasada rápida".
- Zonas donde la generación falla con más frecuencia y donde debe ir la atención del revisor:
  casos límite y ramas de error, autorización, uso correcto de la API que dice usar (métodos y
  parámetros pueden no existir), suposiciones sobre concurrencia, y **tests que reproducen el
  mismo malentendido que el código** — un test generado a partir del código generado no verifica
  nada, solo lo congela.

### 6.2 Regla de responsabilidad

**El que envía el cambio responde de él aunque no lo haya escrito.** Sin matices: la autoría
material es irrelevante para la responsabilidad. De ahí, requisitos exigibles y comprobables:

- El autor **puede explicar cada línea** del diff que envía. Si no puede, no lo envía.
- La descripción declara **cómo se verificó** (§3.4). *"El asistente dijo que estaba bien"* no es
  una verificación y devuelve el PR sin revisar.
- El uso de asistente **se declara** en el PR (y la coautoría en el commit, según
  `git-workflow-standards`). No es una marca de vergüenza: es información que el revisor necesita
  para calibrar dónde mirar.
- **PROHIBIDO exigir revisión de un diff que el propio autor no ha leído entero.** Enviar a
  revisión lo que uno no ha leído traslada el trabajo al revisor y convierte la revisión en el
  primer control real, que es exactamente lo que no debe ser.
- Un cambio autoría de un agente pasa por **la misma** pipeline, los mismos gates y la misma
  revisión humana que cualquier otro. **Nada de vía rápida para código generado.**

### 6.3 Evidencia disponible, y lo que se ha descartado

- **DORA, *State of AI-assisted Software Development* (2025, presentado por Google Cloud;
  publicado en septiembre de 2025 — a ago-2026 no hay edición 2026 de ese informe)**: su tesis
  central, verbatim de dora.dev, es que *"AI's primary role is that of an amplifier, magnifying the
  strengths of high-performing organizations and the dysfunctions of struggling ones."*
  Consecuencia directa para esta skill: **la IA no arregla una revisión mala, la satura.** Un
  equipo sin gates automáticos, sin límite de tamaño y sin criterio de bloqueo empeora al adoptarla.
- **METR, ensayo controlado aleatorizado (jul-2025)**, verbatim: *"we recruited 16 experienced
  developers from large open-source repositories (averaging 22k+ stars and 1M+ lines of code)"*,
  sobre *"real issues (246 total)"*; *"When developers are allowed to use AI tools, they take 19%
  longer to complete issues—a significant slowdown"*; y el dato que importa aquí:
  *"developers expected AI to speed them up by 24%, and even after experiencing the slowdown, they
  still believed AI had sped them up by 20%"*. Regla que se deriva: **la percepción de velocidad
  del autor no es evidencia** y no se acepta como argumento para relajar la revisión. (Reservas
  del propio diseño: muestra pequeña, proyectos OSS grandes que los participantes ya conocían;
  no se extrapola a todo contexto.)
- **Descartado por falta de fuente primaria** (no se escribe como criterio): las cifras de
  proveedores de herramientas sobre "N× más bugs lógicos en código generado" y las telemetrías de
  vendedores sobre aumento del tiempo de revisión o del tamaño de PR — son datos de producto, sin
  metodología publicada ni revisión independiente. Si necesitas un número, **mide el tuyo**:
  defectos escapados y tamaño de PR antes y después de adoptar el asistente.
- **Hueco declarado (§8)**: no se ha localizado una guía normativa de una organización de
  estándares específica para la revisión de código generado por IA. Lo publicado a ago-2026 son
  artículos académicos sobre redistribución de la responsabilidad y guías de proveedor.

## 7. Sostenibilidad y prohibiciones

- Las reglas de revisión viven en el repositorio (`CONTRIBUTING.md` o equivalente), se citan por
  enlace en los comentarios y **se cambian por PR**, como el código. Una regla que solo existe en
  la cabeza del revisor senior no es una regla: es una costumbre.
- Revisión periódica del propio proceso: PRs por encima del plazo, hilos de estilo que aparecieron
  (indican formateador ausente, §3.1), rutas de `CODEOWNERS` con un solo *owner* efectivo, reglas
  del revisor automático con alta tasa de descarte, y defectos escapados que la revisión debería
  haber visto — con **postmortem sin culpa** y cambio de regla, nunca aviso a una persona
  (`incident-management-standards`).
- La revisión es también el vehículo de formación del equipo: cada `note:` bien escrita es
  documentación. Pero **formar no justifica bloquear**.

### Prohibiciones explícitas

- ❌ **PROHIBIDO aprobar sin leer.** Un LGTM es una firma: si no has leído el diff, no firmas.
- ❌ **PROHIBIDO** aceptar a revisión un PR de cientos de ficheros sin trocear ni declarar la parte
  mecánica; el revisor lo rechaza por tamaño **sin leerlo** (§3.5).
- ❌ **PROHIBIDO discutir formato o estilo automatizable** en un hilo de revisión (§3.1).
- ❌ **PROHIBIDO bloquear por preferencia personal**, por gusto arquitectónico ya decidido o por
  refactor fuera de alcance.
- ❌ **PROHIBIDO usar la revisión como control de poder**: retener aprobaciones para negociar,
  bloquear el trabajo de alguien de forma sistemática, exigir cambios sin razón escrita o imponer
  el propio estilo mediante la firma. Es un fallo de proceso y se escala como tal.
- ❌ **PROHIBIDO** el comentario dirigido a la persona en lugar de al código, el sarcasmo y la
  condescendencia. Sin excepción por antigüedad ni por urgencia.
- ❌ **PROHIBIDO** dejar un PR bloqueado indefinidamente por un desacuerdo: se escala o se
  registra como ADR y se desbloquea (§3.8).
- ❌ **PROHIBIDA la autoaprobación** en rutas con *owner* y en toda clase de alto riesgo (§5).
- ❌ **PROHIBIDO** aprobar con CI en rojo, o desactivar un *required check* para poder mergear.
- ❌ **PROHIBIDO** que la aprobación de un revisor automático (LLM) cuente como la aprobación
  humana requerida (§4.2).
- ❌ **PROHIBIDO** enviar a revisión un diff generado que el autor no ha leído entero (§6.2).
- ❌ **PROHIBIDO** cualquier vía rápida o exención de revisión para código generado por IA.
- ❌ **PROHIBIDO** usar métricas de revisión para evaluar a individuos (§4.3).
- ❌ **PROHIBIDO** mezclar refactor, formato y cambio de comportamiento en el mismo PR de alto
  riesgo.

## 8. Verificación web obligatoria

Antes de fijar cualquiera de estos puntos en un equipo real, comprobar online:

1. **Conventional Comments**: que la especificación y la lista de etiquetas siguen como se citan
   (`conventionalcomments.org`), y si el proyecto sigue mantenido. Las definiciones de §3.8 están
   tomadas verbatim a ago-2026.
2. **Google Engineering Practices** (`google.github.io/eng-practices`): que las guías "Small CLs" y
   "Speed of Code Reviews" siguen publicadas con esa redacción; son de las pocas fuentes
   normativas públicas y citables de este dominio.
3. **Evidencia sobre tamaño de PR**: el estudio de Cisco/SmartBear es de **2005-2006** y lo condujo
   el fabricante de la herramienta. **Hueco declarado**: no se ha localizado en esta pasada un
   estudio independiente y reciente que replique la relación tamaño ↔ densidad de defectos
   encontrados. Buscarlo antes de presentar esas cifras como universales; si aparece, manda el
   nuevo.
4. **Sadowski et al., ICSE-SEIP 2018**: sus cifras describen **Google en 2018**, no un óptimo
   universal ni un objetivo a imitar. Comprobar si hay réplica posterior en otro contexto.
5. **Revisión de código generado por IA**: buscar si ha aparecido guía normativa (ISO/IEC, NIST,
   OpenSSF, Linux Foundation) o estudio independiente. **Hueco declarado a ago-2026: no
   localizado.** Ignorar las cifras de proveedores sin metodología publicada (§6.3).
6. **DORA**: si existe ya una edición **2026** del *State of AI-assisted Software Development*
   (a ago-2026 solo consta la de sep-2025, más el *ROI of AI-assisted Software Development*
   actualizado en abr-2026). Contrastar cualquier cifra contra el informe original, **no** contra
   resúmenes de terceros.
7. **METR**: si hay réplicas o ampliaciones del ensayo de jul-2025 con muestra mayor; el propio
   estudio declara limitaciones que impiden generalizar.
8. Herramientas de revisión automática y de análisis del diff: cambio de licencia, modo
   mantenimiento o adquisición (precedentes del catálogo: Trivy cambió de licencia; gitleaks se
   declaró *feature complete*; Brakeman resultó ser de pago pese a la creencia general). Fuente:
   el `LICENSE` en crudo y la web oficial, **no** el feed de GitHub por sí solo — un proyecto que
   se muda de organización aparenta abandono en el feed. Y no dar por buena ninguna noticia de
   adquisición sin fuente primaria (precedente: la "compra de Cypress.io por John Deere" es una
   broma del 1-abr-2025).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
