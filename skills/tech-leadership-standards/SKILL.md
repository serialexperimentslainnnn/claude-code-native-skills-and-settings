---
name: tech-leadership-standards
description: Technical leadership as a set of decisions and artifacts, not a personality trait. Use when defining or applying an engineering career ladder and the IC-versus-manager track, assigning work by Staff+ archetype (tech lead, architect, solver, right hand), writing or reviewing an ADR and classifying a decision as a one-way or two-way door, writing a design document and running a design review with acceptance criteria, deciding who decides and at what level, budgeting technical debt as an explicit business decision, protecting a blameless postmortem under management pressure, running a 1:1 with a report-owned agenda, giving written performance feedback, being asked for individual productivity metrics such as lines of code, commits, velocity or DORA per engineer, citing SPACE or DORA in a measurement argument, sizing a team and its cognitive load in the Team Topologies sense, mapping inter-team dependencies, resolving a technical disagreement and applying disagree-and-commit, deciding whether to adopt coding agents and who pays the organizational cost, or being handed responsibility without authority.
---

# Estándares de liderazgo técnico

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **las decisiones que toma quien lidera técnicamente y los artefactos en los que quedan
escritas**: vías de carrera y alcance real de cada nivel, arquetipos de rol staff+, quién decide qué
y a qué velocidad, el registro de decisiones, el documento y la revisión de diseño, la deuda técnica
como partida presupuestaria, la conversación individual y la evaluación, el dimensionamiento del
equipo y sus dependencias, y la resolución de desacuerdos técnicos.

Triggers: "career ladder", "escala de niveles", "senior/staff/principal", "IC vs. management",
"arquetipo staff", "tech lead", "ADR", "registro de decisiones", "puerta de un sentido",
"reversible", "documento de diseño", "design doc", "revisión de diseño", "RFC técnico", "deuda
técnica", "presupuesto de refactor", "postmortem sin culpa", "1:1", "feedback", "evaluación de
desempeño", "métricas de productividad individual", "líneas de código", "commits por persona",
"DORA por ingeniero", "SPACE", "carga cognitiva", "Team Topologies", "tamaño de equipo",
"dependencias entre equipos", "desacuerdo técnico", "disagree and commit", "responsabilidad sin
autoridad".

**Principio rector**: **el liderazgo técnico es un conjunto de decisiones y artefactos, no un rasgo
de carácter.** No se evalúa por cómo se percibe a la persona, sino por lo que existe escrito y por
lo que el equipo consigue: decisiones registradas con su reversibilidad, diseños revisados antes de
construir, interfaces entre equipos definidas, deuda con presupuesto asignado y personas con
feedback específico y fechado. **Test falsable aplicable a cualquier afirmación sobre liderazgo:
nombra el artefacto que produce, quién lo lee y qué decisión cambia.** Si no se puede nombrar, la
afirmación es motivacional y no se escribe aquí.

Corolario duro: **"liderar con el ejemplo", "fomentar la confianza" y frases del mismo género no
fijan nada.** No son criterio, son adorno. Su equivalente accionable siempre existe y es lo único
que este documento admite: *"toda decisión de arquitectura vive en un ADR con reversibilidad
declarada"*, *"el postmortem no nombra personas y el líder lo defiende ante dirección por escrito"*.

**No aplica**:
- `technical-hiring-standards`: **recíproca y estricta**. Aquí se decide **qué perfil hace falta,
  por qué, y qué hueco del equipo cubre** (§3.7); allí **cómo se mide a un candidato** — rúbrica,
  formato de prueba, validez del método, sesgo, régimen legal e incorporación. Frontera de una
  frase: **el liderazgo define el puesto; el proceso de selección es el instrumento de medida.**
- `project-management-standards` (**ya escrita**): **la entrega, el plan, el compromiso, la
  estimación, el riesgo y las partes interesadas son suyos**, incluido el registro de decisiones de
  *gestión*. Aquí la **decisión técnica** y el **desarrollo del equipo**. Frontera: si la pregunta
  es *"¿cuándo estará y con qué riesgo?"*, es suya; si es *"¿cómo se construye y quién lo decide?"*,
  es de aquí. **El formato de registro de decisiones es el mismo en ambas** (§3.3) para no bifurcar
  el repositorio.
- `product-discovery-standards`: **qué se construye y por qué** — problema,
  usuario, hipótesis, priorización por valor y decisión de matar una idea. Aquí no se decide el qué.
- `enterprise-architecture-standards`: gobierno de arquitectura de la
  organización, hoja de ruta de capacidades y cartera de aplicaciones. Aquí el alcance es el equipo
  y su vecindad inmediata, no la empresa. Recíproca declarada en su §1.
- `software-architecture-patterns-standards` y `refactoring-tech-debt-standards` (**ya escritas**):
  **el criterio técnico es suyo** — qué patrón aplica, cuándo un módulo se refactoriza
  y con qué técnica. Aquí solo **la decisión de invertir en ello, su presupuesto y cómo se defiende**
  (§3.5). Ambas ya declaran la recíproca en su §1.
- `microservices-architecture-standards`: límites de servicio y contratos concretos. Aquí, el
  reflejo organizativo de esos límites (§3.6).
- `code-review-standards` (**ya escrita**): **el criterio de revisión es suyo** — qué bloquea, cómo
  se redacta el comentario, qué exige un cambio de alto riesgo. Aquí solo la regla de que **la
  revisión no se use como instrumento de poder** (§3.8) y quién arbitra el desacuerdo que la revisión
  no cierra.
- `testing-qa-standards`: estrategia de prueba y gates. Aquí, la decisión de financiarla.
- `sre-practice-standards`: **SLO, *error budget*, guardia, capacidad y las métricas DORA son
  suyos**. Aquí, únicamente, que **DORA es medida de sistema y su uso individual está prohibido**
  (§3.9, §7).
- `incident-management-standards`: **el proceso de incidente y el postmortem sin culpa son suyos**
  — roles, cronología, acciones. Aquí lo que corresponde al liderazgo y solo eso: **proteger el
  postmortem sin culpa cuando hay presión de arriba para nombrar un culpable** (§3.10).
- `platform-engineering-standards` (**ya escrita**): **la plataforma como producto interno**, su
  camino pavimentado, sus SLO y su adopción. Aquí, la decisión de crear el equipo y qué carga se le
  transfiere.
- `itsm-itil-standards`: servicio, catálogo y operación continua.
- `grc-compliance-standards`: marco normativo, evidencia formal, segregación de funciones.
- `ai-agent-workflow-standards` (**ya escrita**): **la política de equipo sobre agentes de
  codificación es suya** — qué tarea se delega, ficheros de instrucciones, permisos, revisión del
  diff, atribución. Aquí solo **la decisión de adoptarla, quién paga su coste organizativo y qué
  métricas NO se usan para justificarla** (§3.11).
- `knowledge-management-standards`: dónde vive la documentación y cómo se
  mantiene viva. Aquí, la obligación de que la decisión quede escrita.

## 2. Decisiones por defecto

> Verificar por web el estado de las fuentes citadas antes de apoyarse en ellas (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Qué distingue un nivel de otro | **Alcance del impacto, tipo de decisión y horizonte temporal** (§3.1) | Nunca años de experiencia ni dominio de una tecnología |
| Vía de carrera | **Dos vías con paridad de nivel, ámbito y retribución**, publicadas | Vía única solo en organizaciones < 15 ingenieros, y declarándolo |
| Asignación de trabajo staff+ | **Por arquetipo declarado** (§3.2), acordado con la persona y revisable | — |
| Registro de decisiones técnicas | **ADR obligatorio**, formato Nygard, en el repositorio del código afectado | Registro central **solo** si la decisión cruza varios repositorios |
| Velocidad de decisión | **Derivada de la reversibilidad** (§3.3): reversible → rápida y al nivel más bajo; irreversible → instruida y arriba | — |
| Antes de construir algo no trivial | **Documento de diseño revisado** con criterios de aceptación (§3.4) | Prototipo desechable con caja de tiempo, si el problema es que no se entiende |
| Deuda técnica | **Partida presupuestaria explícita y recurrente**, con su unidad de medida (§3.5) | Nunca "cuando haya tiempo" |
| Medida de un líder técnico | **Resultado del equipo**: entrega, fiabilidad, autonomía, decisiones registradas | — |
| Contacto del líder con el código | **Mínimo suficiente para juzgar** (§3.8): revisar, leer el diseño, tocar el sistema periódicamente | — |
| Métrica individual de productividad | **No existe.** Prohibida (§7) | Evaluación cualitativa con evidencia escrita y fechada |
| Cadencia de 1:1 | **Semanal o quincenal, agenda del subordinado**, nunca informe de estado (§3.9) | — |
| Tamaño de equipo | **Estable, con carga acotada y dueño único de cada sistema** (§3.6) | — |
| Desacuerdo técnico | **Se resuelve con datos, con plazo, y se cierra con desacuerdo comprometido** (§3.7) | Escalado **solo** tras agotar el experimento acotado |

### Fuentes: qué se cita y con qué reserva

- ✅ **Puertas de un sentido / de dos sentidos.** Fuente primaria: **Jeff Bezos, carta a los
  accionistas de Amazon de 2015** (`ir.aboutamazon.com`, PDF). **Verbatim** (extraído del PDF
  oficial, no de un resumen): *"Some decisions are consequential and irreversible or nearly
  irreversible – one-way doors – and these decisions must be made methodically, carefully, slowly,
  with great deliberation and consultation. If you walk through and don't like what you see on the
  other side, you can't get back to where you were before. We can call these Type 1 decisions. But
  most decisions aren't like that – they are changeable, reversible – they're two-way doors. If
  you've made a suboptimal Type 2 decision, you don't have to live with the consequences for that
  long. You can reopen the door and go back through. Type 2 decisions can and should be made quickly
  by high judgment individuals or small groups."* Y el diagnóstico que interesa aquí: *"As
  organizations get larger, there seems to be a tendency to use the heavy-weight Type 1
  decision-making process on most decisions, including many Type 2 decisions. The end result of this
  is slowness, unthoughtful risk aversion, failure to experiment sufficiently, and consequently
  diminished invention."* **Discrepancia declarada**: numerosas fuentes secundarias sitúan el marco
  en la carta de **2016**; es incorrecto — la terminología Type 1 / Type 2 aparece en la de **2015**.
  La de 2016 contiene material relacionado (*disagree and commit*), que es otra cosa.
- ✅ **ADR.** Fuente primaria: **Michael Nygard, "Documenting Architecture Decisions", 15-nov-2011**,
  publicado originalmente en el blog de Relevance/ThinkRelevance y hoy en `cognitect.com`. Plantilla
  de cinco secciones: **Título** (frase nominal corta con número secuencial que nunca se reutiliza),
  **Estado** (propuesto / aceptado / obsoleto / sustituido por ADR-NNNN), **Contexto** (las fuerzas
  en juego, en lenguaje neutro), **Decisión**, **Consecuencias** (positivas y negativas). Regla
  derivada: **un ADR aceptado no se edita**; si cambia la conclusión, se escribe uno nuevo que
  sustituye al anterior y actualiza su estado.
- ⚠️ **Arquetipos staff+.** Sí existe taxonomía publicada de referencia: **Will Larson, *Staff
  Engineer: Leadership beyond the management track* (2021)** y su origen en abierto
  (`lethain.com/staff-engineer-archetypes/`, `staffeng.com/guides/staff-archetypes/`). Cuatro
  arquetipos: **tech lead**, **architect**, **solver**, **right hand**. **Reserva explícita**: es
  una **taxonomía descriptiva de observación en empresas tecnológicas de crecimiento rápido, no un
  resultado de investigación**, y tiene crítica publicada por profesionales (Sean Goedecke: los
  arquetipos existen pero son mal consejo como objetivo de carrera, porque *solver* y *right hand*
  dependen de confianza acumulada y no se pueden perseguir directamente; Alex Ewerlöf: no deben
  usarse como títulos de puesto). **Uso admitido: vocabulario para repartir trabajo y aclarar
  expectativas. Uso prohibido: convertirlos en niveles, títulos o casillas de una escala.**
- ⚠️ **Carga cognitiva de equipo.** Fuente original **John Sweller, "Cognitive load during problem
  solving: Effects on learning", *Cognitive Science* 12(2):257-285 (1988)** — teoría de
  **aprendizaje individual y diseño instruccional**. Su traslado a equipos es de **Matthew Skelton y
  Manuel Pais, *Team Topologies* (2019)**. **Trátese como analogía útil, no como medición validada**,
  exactamente igual que en `platform-engineering-standards` §6.4: la carga cognitiva de equipo **no
  tiene unidad medible**, la suma de cargas individuales no es un constructo definido en la teoría
  original, y literatura académica de DevOps señala que el libro **no aporta evidencia científica**
  y se apoya en experiencia y casos. Sirve para **decidir el reparto de sistemas entre equipos**; no
  sirve como número en una diapositiva.
- ✅ **SPACE.** **Nicole Forsgren, Margaret-Anne Storey, Chandra Maddila, Thomas Zimmermann, Brian
  Houck y Jenna Butler, "The SPACE of Developer Productivity: There's more to it than you think",
  *ACM Queue* 19(1):20-48 (2021), DOI 10.1145/3454122.3454124** (también en *CACM*). Cinco
  dimensiones: satisfacción y bienestar, rendimiento, actividad, comunicación y colaboración,
  eficiencia y flujo. Regla operativa que se toma de ahí: **medir al menos tres dimensiones a la
  vez, combinando métricas objetivas y encuesta**; la actividad **jamás en aislamiento** para premiar
  o penalizar. **Discrepancia declarada y advertencia de uso**: circula la afirmación de que "SPACE
  mide al individuo y DORA al equipo" — **es una lectura errónea**: uno de los mitos que el propio
  artículo desmonta es que la productividad sea *solo* rendimiento individual, y su tesis central es
  que no se captura con una sola métrica ni con datos de actividad. **No se ha podido recuperar el
  texto completo en verbatim** (ACM Queue y CACM devuelven 403 a la descarga automatizada): las
  formulaciones de arriba proceden de fuentes secundarias concordantes y **deben contrastarse contra
  el artículo original antes de citarlas literalmente** (§8).
- ✅ **DORA como medida de sistema.** Las cuatro métricas miden **entrega del equipo y del sistema**,
  no personas. Informe **2025: *State of AI-assisted Software Development*** (`dora.dev/dora-report-2025/`,
  ~5.000 profesionales); informe **2026: *The ROI of AI-Assisted Software Development*** (cobertura de
  InfoQ, may-2026). **Reserva sobre el de 2026**: hay crítica publicada de que, frente al rigor
  investigador de ediciones anteriores, es en buena parte un conjunto de recomendaciones
  especulativas. Cítese la edición y el año; **nunca "DORA dice" a secas**.

### Cifras famosas: qué NO se usa como dato

Este dominio está saturado de números que circulan sin estudio primario localizable o con
metodología desmontada. Se descartan expresamente:

- ❌ **El "programador 10x".** Origen: **Sackman, Erikson y Grant, "Exploratory Experimental Studies
  Comparing Online and Offline Programming Performance", *CACM* 11(1):3-11, ene-1968**. Refutación
  metodológica: **Lutz Prechelt, "The 28:1 Grant/Sackman legend is misleading, or: How large is
  interpersonal variation really?", Technical Report 1999-18, Universität Karlsruhe, dic-1999**
  (`page.mi.fu-berlin.de/prechelt/Biblio/varianceTR.pdf`). Fallos del original: **12 sujetos**,
  tareas triviales y de naturaleza matemática, y **mezcla de programadores en lenguaje de bajo y de
  alto nivel en el mismo grupo**, lo que infla el cociente mejor/peor. Prechelt reanaliza un conjunto
  mucho mayor y sostiene que **comparar el mejor con el peor es la comparación equivocada**: contra
  la mediana del cuartil peor frente a la del mejor, el cociente **rara vez supera 4**, y la razón
  desviación típica/media ronda **0,5**. **Uso permitido**: "existe variación interpersonal
  sustancial, del orden de 2-4x según tarea, con distribuciones solapadas". **Uso prohibido**:
  "10x", y sobre todo **usarlo para justificar retribución, dotación de personal o despidos**.
- ❌ **"Una interrupción cuesta 23 minutos y 15 segundos".** **No existe el artículo que lo
  respalda.** El paper que se cita, **Mark, González y Harris, "No Task Left Behind? Examining the
  Nature of Fragmented Work", CHI '05**, mide la **probabilidad de reanudar una tarea el mismo día**
  y **no contiene esa cifra**. El otro habitualmente citado, *"The Cost of Interrupted Work: More
  Speed and Stress"*, encuentra que **los sujetos interrumpidos completaron las tareas más rápido**,
  con más estrés. La cifra procede de **una entrevista de 2006** con Gloria Mark, no de un artículo
  revisado. **No se escribe, ni con matices.** Lo defendible sin cifra: la fragmentación tiene coste
  y **el argumento para proteger bloques de trabajo no necesita un número inventado**.
- ❌ **"El 70 % de la variación en el compromiso del equipo lo determina el jefe"** (Gallup, *State
  of the American Manager*, 2015). **Análisis propietario, no revisado por pares, sin datos brutos
  publicados**, y con dos problemas de interpretación que la difusión ignora: se refiere a varianza
  **entre equipos** (no es una afirmación de nivel individual), y "efecto del jefe" absorbe todo lo
  que se agrupa a nivel de equipo (función, ubicación, carga, dotación). **No se usa como dato para
  justificar una decisión.**
- ❌ **"La gente deja jefes, no empresas"** (*First, Break All the Rules*, Gallup). Hay refutación
  publicada por **Culture Amp (2017)** sobre 175 equipos: la gente sí deja malos jefes, pero **no es
  la primera razón**, y en organizaciones malas **tener buen o mal jefe apenas cambia la decisión de
  irse**. Se sostiene la versión débil ("la calidad del jefe es *uno* de los factores, condicionado a
  que la organización sea decente"); el eslogan, no.
- ❌ **Porcentajes de rotación atribuidos a "mal jefe"** y **el coste de una mala contratación
  expresado como múltiplo del salario** (§ `technical-hiring-standards`): se descartan por la misma
  razón, allí con detalle.

**Regla general**: **una cifra sin estudio primario, año, muestra y método no entra en un documento,
una diapositiva ni una petición de presupuesto.** Si el argumento solo se sostiene con la cifra, el
argumento era malo.

## 3. Estructura y convenciones

### 3.1 Vías de carrera: qué cambia realmente

**Lo que cambia al subir de nivel no es "el nivel": son tres variables observables.**

| Variable | Senior | Staff | Principal |
|---|---|---|---|
| **Alcance del impacto** | Su equipo y el sistema del que responde | Varios equipos, o un área crítica de la que depende la organización | La organización de ingeniería o una capacidad transversal |
| **Tipo de decisión** | Cómo se implementa; elige entre opciones conocidas | Qué opciones existen; define el problema y las interfaces | Qué se deja de hacer; decisiones irreversibles y compromisos entre áreas |
| **Horizonte temporal** | Semanas a un trimestre | Trimestres a un año | Uno a varios años |
| **Evidencia exigible** | Sistemas entregados y operables | Diseños ajenos mejorados, decisiones registradas, personas subidas de nivel | Cambios de rumbo que la organización siguió y que se pueden trazar |

Reglas duras:
1. **La escala se publica.** Una escala que solo conoce el jefe no es una escala, es una excusa
   retroactiva. Existen referencias públicas para no partir de cero — **Rent the Runway (2015, con
   Camille Fournier como CTO), Dropbox, CircleCI, Square, Kickstarter**, agregadas en
   `progression.fyi` y `github.com/bmoeskau/engineering-ladders`. **Se adaptan, no se copian**: una
   escala ajena describe una organización ajena.
2. **Paridad real entre vías.** La vía de contribuidor individual y la de gestión tienen **el mismo
   techo de nivel, la misma banda salarial y la misma presencia en los foros de decisión**. Sin las
   tres, la vía técnica es decorativa y todo el mundo lo sabe a los seis meses.
3. **Gestionar no es un ascenso, es un cambio de puesto.** El trabajo, la medida y la habilidad son
   distintos. Corolario operativo: **hay camino de vuelta declarado**, y usarlo no es un fracaso
   registrable en la evaluación.
4. **El nivel se asigna por evidencia escrita**, no por antigüedad ni por simpatía. Si no se puede
   escribir la evidencia con hechos fechados, no hay nivel.
5. **Ningún nivel se define por tecnología.** "Senior de Kubernetes" no es un nivel, es una
   dependencia de una herramienta con fecha de caducidad.

### 3.2 Arquetipos staff+: para qué sirven realmente

Sirven para una sola cosa, y por eso están aquí: **evitar asignar trabajo que la persona no puede
hacer desde donde está.** Taxonomía y reservas en §2.

| Arquetipo | Trabajo que le corresponde | Trabajo que le destruye el impacto |
|---|---|---|
| **Tech lead** | Aproximación y ejecución de **un** equipo, junto al mánager | Ser el cuello de botella de las decisiones de otros tres equipos |
| **Architect** | Dirección, calidad y enfoque de **un área crítica**, con horizonte plurianual | Apagar fuegos fuera de su área; hacer que su área dependa de su presencia |
| **Solver** | Entrar en un problema difícil y acotado y salir con camino resuelto | Convertirse en dueño permanente de lo que arregló |
| **Right hand** | Extender el alcance de un directivo en una organización grande | Existir en una organización que no lo necesita: reproduce jerarquía sin añadir criterio |

Reglas:
- **El arquetipo se acuerda por escrito con la persona y se revisa** (por defecto, cada semestre o
  al cambiar de proyecto). Un *solver* al que se le adjudica el mantenimiento de todo lo que tocó
  deja de ser *solver* en un trimestre.
- **Architect y right hand solo aparecen a cierta escala.** Larson los observa surgiendo en torno a
  ~100 y ~1.000 ingenieros respectivamente. **Crearlos antes fabrica una capa de decisión sin
  problema que resolver.**
- **PROHIBIDO usarlos como títulos** o como niveles de la escala (§7).

### 3.3 Decisiones: qué se decide, quién decide y a qué velocidad

**Quién decide, por defecto:**

| Tipo de decisión | Decide | Se consulta | Se registra en |
|---|---|---|---|
| Implementación dentro de un módulo del propio equipo | **Quien lo implementa** | Revisor del PR | El código y el PR |
| Elección de biblioteca o patrón dentro del equipo | **El equipo**, tech lead arbitra | — | **ADR del repositorio** |
| Contrato o interfaz entre dos equipos | **Los dos equipos, conjuntamente** | Arquitecto del área | **ADR + contrato versionado** (`api-design-standards`) |
| Tecnología nueva en la organización, o retirada de una existente | **Nivel staff+ o arquitectura**, con criterios publicados | Plataforma, seguridad, FinOps | **ADR + inventario** |
| Compromiso de alcance o fecha | **No es esta skill** | — | `project-management-standards` |
| Aceptación de un riesgo regulatorio | **Quien tiene la autoridad formal** | — | `grc-compliance-standards` |

**El ADR es obligación, no cortesía.** Regla mínima: **si una decisión técnica va a condicionar el
trabajo de alguien que no estuvo en la conversación, se escribe.** Formato Nygard (§2), en el
repositorio afectado, numerado y no editable una vez aceptado.

**La velocidad la fija la reversibilidad, no la importancia percibida** (Bezos 2015, verbatim en §2):

| | Puerta de un sentido (Tipo 1) | Puerta de dos sentidos (Tipo 2) |
|---|---|---|
| Ejemplos típicos | Modelo de datos público, esquema de identidad, formato de API expuesta a terceros, migración con pérdida, elección de proveedor con salida cara | Biblioteca interna, estructura de carpetas, formato de log interno, framework de test |
| Velocidad | **Lenta, deliberada, instruida**: documento de diseño, alternativas evaluadas, revisión formal | **Rápida**, por la persona o el grupo pequeño más cercano al problema |
| Nivel que decide | Arriba, con consulta | El más bajo posible |
| Coste de equivocarse | Alto y permanente | Bajo: se reabre la puerta |

- **Todo ADR lleva un campo `reversibilidad` con valor explícito.** Sin él, la organización trata
  todo como Tipo 1 y se paraliza — el fallo que la propia carta de 2015 describe.
- **La clasificación se puede impugnar, pero por escrito y con argumento.** "Esto es irreversible"
  es una afirmación falsable: se pide el coste estimado de revertirlo.
- **Una decisión Tipo 2 que lleva tres semanas en discusión ya costó más que equivocarse.** Regla:
  caja de tiempo, y si vence, decide la persona con la responsabilidad y se registra.

### 3.4 Documento de diseño y revisión de diseño

**La revisión de diseño es el punto del ciclo donde un error todavía cuesta barato.** Después hay
código, dependencias, datos migrados y gente que ya lo defendió en público.

**Cuándo es obligatorio un documento de diseño** (basta con uno):
- La decisión cruza el límite de un equipo o crea/cambia una interfaz entre equipos.
- Es una puerta de un sentido (§3.3).
- Toca datos personales, autenticación, autorización, criptografía o dinero.
- El esfuerzo estimado supera un umbral que el equipo publica (por defecto: **dos semanas-persona**).
- Se introduce una tecnología que la organización no opera todavía.

**Plantilla mínima. Un documento sin las secciones 5, 6 y 8 se devuelve sin revisar.**

```markdown
# Diseño: <nombre>            Autor: <persona>   Estado: borrador|en revisión|aceptado|sustituido
1. Problema            # qué falla hoy, con evidencia observable (dato, incidente, ticket)
2. Restricciones       # plazo, presupuesto, normativa, compatibilidad, equipo disponible
3. No objetivos        # lo que este diseño explícitamente NO resuelve
4. Propuesta           # la solución, con el diagrama mínimo que la explique
5. Alternativas descartadas   # >=2, con el motivo del descarte. Sin esto no hay diseño, hay preferencia
6. Criterios de aceptación    # falsables y medibles: cómo se sabrá que funcionó, y cuándo se mira
7. Impacto             # migración, compatibilidad hacia atrás, coste recurrente, operabilidad, seguridad
8. Reversibilidad      # Tipo 1 o Tipo 2, y coste estimado de revertir
9. Riesgos abiertos    # con dueño
```

**Reglas de la revisión:**
- **Se revisa el problema antes que la solución.** Si los revisores no están de acuerdo en el
  problema, discutir la solución es tiempo perdido y siempre acaba en estética.
- **Lectura previa obligatoria, con plazo** (por defecto 48 h). Una reunión donde se lee el documento
  en directo es una reunión de lectura, no de revisión.
- **Los comentarios se etiquetan como bloqueantes o no bloqueantes**, igual que en revisión de código
  (`code-review-standards`). Un revisor que no marca nada como bloqueante ha aprobado.
- **La revisión termina con una decisión y una fecha, no con "seguimos hablando".** Los estados
  válidos son: aceptado, aceptado con condiciones listadas, rechazado con motivo, o pospuesto con
  fecha y con lo que falta por saber.
- **El documento aceptado se convierte en ADR o lo enlaza.** Un diseño que no deja rastro de decisión
  se vuelve a discutir en seis meses.
- **Criterios de aceptación con fecha de comprobación.** Se revisita cuando toca: si no se cumplieron,
  eso es información sobre cómo diseña el equipo, y es el insumo más barato que existe para mejorar.

### 3.5 Deuda técnica: decisión de negocio con presupuesto

El criterio técnico —qué refactorizar, con qué técnica y con qué red de test— es de
`refactoring-tech-debt-standards` (**ya escrita**). **Aquí solo la decisión de invertir y
cómo se defiende.**

1. **La deuda se registra como cualquier otro trabajo**, en el mismo backlog, con dueño y con el
   **coste que impone hoy** — no con adjetivos. Formulación admisible: *"cada cambio en el módulo de
   facturación exige tocar cuatro sitios y en el último trimestre generó 3 de los 7 incidentes"*.
   Formulación inadmisible: *"el código está mal"*.
2. **Distinguir deuda deliberada de degradación.** La deliberada se contrajo con una decisión
   registrada y una fecha de revisión (si no la tiene, no fue una decisión: fue un descuido). La
   degradación es acumulación silenciosa y se detecta por síntoma, no por opinión.
3. **Presupuesto explícito y recurrente.** Se declara un porcentaje de capacidad por ciclo, se
   publica y **se protege como se protege una fecha comprometida**. Un porcentaje que se cancela en
   el primer trimestre con presión no era un presupuesto: era una intención.
4. **Cómo se defiende ante quien paga — y esto es lo que falla siempre.** La deuda técnica no se
   defiende como calidad de código: **se defiende con el coste que ya está pagando el negocio**, en
   su vocabulario. Argumentos que funcionan porque son verificables:
   - **Tiempo de entrega**: el mismo cambio tarda X en este módulo y Y en el resto.
   - **Fiabilidad**: proporción de incidentes que se concentran en el componente
     (`incident-management-standards` da el dato).
   - **Coste directo**: infraestructura sobredimensionada, licencias, horas de operación manual
     (`finops-standards`).
   - **Riesgo con nombre**: dependencia sin soporte, versión sin parches de seguridad
     (`vulnerability-management-standards`), incumplimiento normativo (`grc-compliance-standards`).
   - **Opción que se pierde**: qué no se podrá hacer, y cuándo, si no se toca.
5. **Una petición de refactor sin ninguno de esos cinco argumentos se rechaza**, la haga quien la
   haga. Y se rechaza aquí, dentro de ingeniería, antes de que la rechace el negocio: **la
   credibilidad se gasta una vez**.
6. **Nunca "una release de refactor" que no entrega nada.** El trabajo de deuda se entrega en
   incrementos con efecto observable; si no se puede trocear, el problema es el diseño de la
   intervención, no el calendario.

### 3.6 El equipo como sistema

- **Dueño único por sistema.** Un sistema sin dueño nombrado lo mantiene quien tuvo la mala suerte
  de tocarlo el último. Dos dueños es cero dueños.
- **Carga acotada, en el sentido analógico de la carga cognitiva** (§2, con su reserva): un equipo
  responde de tantos sistemas como pueda **entender, operar y mejorar**. Prueba operativa y
  falsable, que no requiere métrica inventada: *¿puede el equipo desplegar, diagnosticar en
  producción y explicar el modelo de datos de cada sistema del que responde, sin depender de una
  persona concreta?* Si no, la carga excede al equipo — se reduce el alcance o se transfiere carga
  extraña a la plataforma (`platform-engineering-standards`).
- **Equipos estables.** Reorganizar equipos reinicia el conocimiento del sistema y las relaciones de
  confianza. **Toda reorganización se justifica por escrito con el problema que resuelve y su coste
  esperado**, o no se hace.
- **Tamaño**: suficientemente pequeño para que todos conozcan el trabajo de todos, suficientemente
  grande para sostener una guardia sin quemar a nadie (`sre-practice-standards` fija lo segundo).
  **Añadir personas a un equipo saturado añade coordinación antes que capacidad**
  (`project-management-standards` §6).
- **Dependencias entre equipos: se gestionan por interfaz, no por reunión.** Preferencia, en orden:
  (1) eliminar la dependencia, (2) desacoplar con contrato de interfaz y simulador, (3) secuenciar
  con compromiso mutuo del equipo proveedor, (4) escalar. **Añadir una reunión de sincronización
  recurrente es admitir que se eligió (4) y llamarlo (3).**
- **La estructura del equipo y la del sistema convergen** (Conway). Consecuencia práctica: **si se
  quiere una arquitectura distinta, hay que cambiar los límites de los equipos, no solo el
  diagrama.**

### 3.7 Conflicto técnico

**Un desacuerdo técnico sin procedimiento se resuelve por jerarquía o por cansancio, y ambas
producen la peor decisión disponible.** Procedimiento, en este orden y con plazo:

1. **Explicitar el desacuerdo**: cada parte escribe, en un párrafo, qué defiende y **qué evidencia le
   haría cambiar de opinión**. Quien no puede responder a lo segundo no tiene una posición técnica,
   tiene una preferencia — y las preferencias no bloquean.
2. **Buscar el dato**: prototipo, medición, prueba de carga, revisión de un incidente pasado. **Con
   caja de tiempo fija y acordada de antemano.**
3. **Si el dato no discrimina** (empate real), decide **quién responde de las consecuencias** —
   normalmente el dueño del sistema afectado — y se registra en un ADR con las alternativas y el
   empate declarado.
4. **Desacuerdo comprometido, como norma explícita del equipo.** Referencia: principio de liderazgo
   de Amazon **"Have Backbone; Disagree and Commit"** (`amazon.jobs`) — obligación de cuestionar la
   decisión con respeto aunque sea incómodo, y **compromiso pleno una vez tomada**. El término es
   anterior a Amazon (Intel, *constructive confrontation*). Regla local, que es lo aplicable:
   **una vez cerrada la decisión, nadie la sabotea pasivamente ni la reabre en pasillos**; se reabre
   solo con evidencia nueva y por el mismo cauce.
5. **Cuándo se escala**: cuando el desacuerdo cruza la frontera de dos equipos y bloquea trabajo más
   de una semana, o cuando implica riesgo de seguridad, legal o de datos personales. **Escalar no es
   perder**: escalar tarde sí.
6. **Un desacuerdo que se repite es un problema de diseño organizativo**, no de las personas: las
   fronteras de responsabilidad están mal trazadas (§3.6).

### 3.8 El trabajo del líder técnico que no es escribir código

**Su valor se mide en el resultado del equipo, no en su propio *output*.** Consecuencias directas:
si la persona más productiva del equipo es el líder, el equipo está infraaprovechado; si el líder
está en el camino crítico de cada entrega, es un SPOF con vacaciones.

Trabajo que sí es suyo, y es el que produce apalancamiento:
- **Desbloquear**: identificar quién está parado y por qué, y quitarlo de en medio. Es la actividad
  de mayor retorno del puesto y la primera que se sacrifica cuando el líder se pone a programar.
- **Definir interfaces entre equipos** antes de que dos equipos construyan contra supuestos
  distintos (§3.6).
- **Revisar diseños y decisiones ajenas** (§3.4) — no reescribirlos.
- **Escribir lo que la organización va a necesitar recordar**: ADR, contexto, criterios.
- **Crear las condiciones para que otro tome la decisión**, y aceptar que la tome distinta a como la
  habría tomado él si el resultado es aceptable. **El líder que solo delega las decisiones que
  coincidirían con la suya no ha delegado nada.**
- **Desarrollar personas** (§3.9): es trabajo con calendario, no un subproducto.

**La trampa contraria, y es igual de real: el líder que deja de tocar el código pierde la capacidad
de juzgar.** Sin contacto con el sistema, las estimaciones ajenas se vuelven incontrastables, los
diseños se aprueban por confianza en la persona y no por el contenido, y la deuda técnica se vuelve
un relato sin evidencia. **Mínimo operativo, no negociable:**
- Revisar código de verdad con regularidad (`code-review-standards`), incluyendo cambios que no
  entiende del todo, que es donde se aprende dónde está el sistema.
- **Estar en la rotación de guardia** si el equipo la tiene, o al menos participar de la respuesta a
  incidentes (`incident-management-standards`).
- **Coger trabajo real, pero nunca en el camino crítico**: herramientas internas, correcciones,
  pruebas, la tarea que nadie quiere. **PROHIBIDO adjudicarse la funcionalidad crítica del
  trimestre**: se convierte en cuello de botella y el equipo se queda sin la parte formativa.
- Regla de arbitraje entre las dos trampas: **si el equipo entrega igual de bien cuando el líder está
  dos semanas fuera, el reparto es correcto.** Es la única prueba que importa, y se puede ejecutar
  literalmente.

**La revisión de código no se usa como instrumento de poder.** Manifestaciones vetadas: bloquear un
PR por preferencia estética, exigir la propia solución sin argumento técnico, retener la aprobación
como palanca en una negociación ajena al diff. El criterio de qué bloquea es de
`code-review-standards`; **la obligación de que el líder no lo distorsione es de aquí**.

### 3.9 1:1, feedback y evaluación

**El 1:1 es del subordinado.** Reglas concretas:
- **Agenda la pone quien reporta**, y existe antes de la reunión. Si no hay agenda, la pregunta por
  defecto no es "¿cómo va X?" sino **"¿qué es lo que más te está estorbando?"**.
- **PROHIBIDO que sea un informe de estado**: el estado del trabajo está en el sistema de gestión
  (`project-management-standards`) y consultarlo es responsabilidad del líder, no minutos de la
  persona.
- **Cadencia fija y protegida** (semanal o quincenal por defecto). **Cancelarla repetidamente
  comunica una prioridad con más claridad que cualquier discurso.**
- **Notas compartidas y compromisos con dueño y fecha.** Un 1:1 sin rastro se repite idéntico durante
  un año.
- Al menos una vez por trimestre, el 1:1 es de **carrera**: nivel actual, evidencia que falta,
  arquetipo (§3.2), qué trabajo hace falta buscar para llegar. Con la escala publicada delante.

**Feedback:**
- **Específico, fechado y sobre conducta observable**, no sobre rasgos. *"En la revisión del diseño de
  cobros del 12 de mayo cerraste la discusión antes de que Ana expusiera su alternativa"* es
  accionable. *"Eres poco colaborativo"* no lo es: no se puede corregir lo que no se puede observar.
- **Cerca del hecho.** Feedback guardado seis meses para la evaluación anual no es feedback: es una
  emboscada, y destruye la credibilidad del proceso entero.
- **Sin sorpresas en la evaluación.** Regla falsable: **si algo aparece en la evaluación anual y es
  la primera vez que la persona lo oye, el fallo es del líder, y se registra como tal.**
- El feedback difícil se da en privado, por escrito además de en voz, y **con lo que se espera
  distinto y para cuándo**.

**Por qué las métricas individuales de productividad de ingeniería son contraproducentes** — y esta
es la parte que hay que poder defender ante dirección con fuente en la mano:
1. **Posición publicada de la investigación de referencia del sector.** **DORA**: las cuatro métricas
   miden **entrega del equipo y del sistema** y no deben usarse para evaluar el rendimiento de
   ingenieros individuales; aplicarlas a personas crea incentivos perversos. **SPACE** (Forsgren et
   al., 2021, §2) desmonta dos mitos directamente aplicables: que la productividad sea actividad, y
   que sea **solo** rendimiento individual; y establece que **las métricas de actividad nunca se usan
   en aislamiento para premiar o penalizar**.
2. **Son triviales de manipular y la manipulación es racional**: líneas, commits, PRs y puntos son
   gratis de inflar y el coste de inflarlos lo paga otro (el revisor, el que mantiene).
3. **Miden lo visible y castigan lo valioso**: revisar, emparejarse, mentorizar, estar de guardia,
   borrar código y evitar que se construya lo innecesario no dejan rastro en ningún contador.
4. **El trabajo de ingeniería es interdependiente**: atribuir el resultado a un individuo dentro de
   un sistema con colas, dependencias y revisión es un error de atribución, no una medición
   imprecisa.
5. **Alternativa que sí se usa**: evaluación cualitativa **con evidencia escrita y fechada** contra
   la escala publicada (§3.1) — diseños, decisiones registradas, incidentes resueltos, personas
   desarrolladas, sistemas que funcionan sin su autor. **Es más trabajo para el líder. Ese es el
   coste del puesto.**

### 3.10 Incidentes: lo que corresponde al liderazgo

El proceso completo es de `incident-management-standards`. **Aquí solo la parte que solo el
liderazgo puede hacer, y que es donde la cultura sin culpa se rompe en la práctica:**
- **Proteger el postmortem sin culpa cuando hay presión de arriba para nombrar a alguien.** La
  presión es real y llega en forma de pregunta razonable ("¿quién lo desplegó?"). Respuesta
  estándar, en el mismo idioma de quien pregunta: **el sistema permitió que un error individual
  llegara a producción; ese es el defecto y es el que se arregla, porque es el único que no se
  repetirá.** Sustituir a la persona deja el sistema idéntico para el siguiente.
- **Regla verificable de redacción**: **el postmortem no contiene nombres propios como causa.** Si
  aparece "X ejecutó Y", se reescribe como "el procedimiento permitía ejecutar Y sin confirmación".
- **Contraindicación honesta**: sin culpa **no significa sin responsabilidad**. Negligencia
  reiterada, saltarse controles a sabiendas o actuar sin autorización son un asunto de conducta y se
  tratan **fuera del postmortem, por otro cauce y con RR. HH.** Mezclarlos destruye ambos.
- **Las acciones del postmortem se financian.** Un postmortem cuyas acciones no entran en el plan
  del ciclo siguiente enseña al equipo que el ejercicio es teatro, y a partir de ahí los postmortem
  se escriben para archivar.
- **El líder asume públicamente el fallo del equipo y atribuye públicamente el acierto.** Es una
  regla de conducta con efecto verificable: sin ella, nadie informa de un problema pronto.

### 3.11 Agentes de codificación: qué decide el liderazgo

La política concreta —qué tarea se delega, ficheros de instrucciones, permisos, revisión del diff,
atribución— es de `ai-agent-workflow-standards`. **Aquí, tres decisiones y una prohibición:**
- **Decisión de adoptar**: se toma como cualquier otra decisión técnica, con ADR y reversibilidad
  declarada. Y con lo que casi nunca se declara: **qué pasa con el coste de revisión**. Un agente
  desplaza esfuerzo de escribir a **revisar**, y la capacidad de revisión del equipo es finita y no
  aumenta sola.
- **Quién paga el coste organizativo**: formación, tiempo de revisión, gobierno de permisos y
  respuesta a incidentes de calidad. Si no se asigna capacidad explícita, se financia recortando
  revisión — que es exactamente el control que la adopción vuelve más necesario.
- **Efecto sobre el desarrollo de las personas junior**: si el trabajo formativo se automatiza
  entero, la organización deja de fabricar seniors. **Se decide y se declara qué trabajo se reserva
  para aprender**, no se descubre a los dos años.
- ❌ **PROHIBIDO justificar la adopción con métricas individuales de aceptación o volumen generado**
  (§3.9, §7). La evidencia admisible es de sistema y se cita con su edición y su año
  (`ai-agent-workflow-standards` mantiene el estado de la evidencia).

## 4. Controles verificables sobre el sistema de liderazgo

Controles auditables, no encuestas de clima. Se ejecutan con cadencia fija; **su fallo abre trabajo
con dueño, no genera un informe**.

| Control | Falla si | Acción |
|---|---|---|
| Decisión sin registrar | existe una decisión técnica en producción sin ADR que la explique | Escribirlo retroactivamente y nombrar al decisor |
| ADR sin reversibilidad | campo `reversibilidad` ausente | Rechazar el ADR |
| Puerta de un sentido decidida en una reunión | sin documento de diseño ni alternativas | Revertir el proceso: se instruye y se decide de nuevo |
| Diseño sin alternativas descartadas | sección 5 vacía | Devolver sin revisar |
| Criterios de aceptación no revisitados | fecha de comprobación vencida sin evaluar | Evaluar y registrar el resultado, se cumpliera o no |
| Escala no publicada | la escala de niveles no es accesible a todo el equipo | Bloquear cualquier promoción hasta publicarla |
| Sorpresa en la evaluación | un punto aparece por primera vez en la evaluación | Registrar como fallo del líder; no computa para la persona |
| 1:1 cancelado | > 2 cancelaciones seguidas por parte del líder | Escalar al nivel superior |
| Deuda sin presupuesto | 0 % de capacidad asignada en el ciclo | Declararlo por escrito como decisión, con su motivo y fecha de revisión |
| Postmortem con nombre propio como causa | aparece una persona como causa raíz | Reescribir; el que lo aprobó responde |
| Acciones de postmortem sin financiar | no están en el plan del ciclo siguiente | Escalar: el postmortem pierde su función |
| Sistema sin dueño | un sistema en producción sin equipo dueño nombrado | Asignarlo o retirarlo |
| Líder en el camino crítico | el equipo se bloquea cuando el líder se ausenta | Redistribuir; es un defecto de diseño del equipo |
| Métrica individual en circulación | existe un panel que ordena personas por commits, líneas, PRs o puntos | Retirarlo; §7 |

**Prueba de ausencia, aplicable literalmente**: el equipo debe entregar y operar con normalidad
durante dos semanas de ausencia del líder. **Es el único indicador de liderazgo técnico que no se
puede simular.**

## 5. Seguridad, riesgo y ética del rol

- **Autoridad y responsabilidad viajan juntas.** Asignar a alguien la responsabilidad de un resultado
  sin la autoridad para tomar las decisiones que lo determinan (presupuesto, prioridad, personas,
  arquitectura) **no es delegar: es transferir culpa**. Regla: **al delegar se escribe qué decide la
  persona sin consultar, qué consulta y qué escala.** Sin ese reparto escrito, no hay delegación.
- **El líder es un objetivo de ingeniería social y un punto de acumulación de privilegio.** Revisar
  periódicamente qué accesos tiene y por qué (`identity-access-management-standards`); acceso a
  producción **solo si su rol lo exige de hecho**, no por precaución. Un líder con permisos de todo
  "por si acaso" es un único compromiso de cuenta con alcance total.
- **Información de personas**: notas de 1:1, evaluaciones, retribución y salud son **datos
  personales, algunos de categoría especial**. Control de acceso, plazo de conservación y
  eliminación (`privacy-engineering-standards`). **PROHIBIDO** en canales de chat de equipo, en
  tickets o en documentos con enlace abierto.
- **Presión para actuar contra el criterio técnico** (saltarse una revisión de seguridad, desplegar
  sin control, ocultar un incidente): se responde **por escrito**, con el riesgo nombrado y la
  decisión atribuida a quien tiene autoridad para asumirla. **Aceptar riesgo verbalmente es aceptarlo
  en solitario**; la formalización de la aceptación es de `grc-compliance-standards`.
- **Obligaciones de notificación**: un incidente puede activar plazos legales
  (`incident-response-forensics-standards`, `grc-compliance-standards`, `privacy-engineering-standards`).
  **El líder no decide si se notifica**: escala inmediatamente al que sí decide. Silenciar es la
  única respuesta que agrava el problema en todos los escenarios.
- **Retención por presión** (contraofertas, "no puedes irte ahora"): la salida ordenada se planifica
  — traspaso de sistemas, revocación de accesos, entrevista de salida cuyo contenido se usa. Las
  bajas y altas de acceso son de `identity-access-management-standards`; el proceso, de
  `technical-hiring-standards`.

## 6. Sostenibilidad del propio rol y del equipo

*(La §6 canónica —rendimiento y operabilidad— no aplica a un dominio de proceso; **se sustituye
declarándolo** por la operabilidad del rol y la del equipo como sistema.)*

- **Sucesión declarada.** Para cada responsabilidad crítica del líder existe alguien que ya la ha
  ejercido, no alguien que "podría". Se prueba ejerciéndola: rotar quien dirige la revisión de
  diseño, quien responde de incidentes, quien lleva la relación con otro equipo.
- **Bus factor por sistema y por decisión.** Un sistema que solo una persona sabe operar es un riesgo
  operativo con nombre; una decisión que solo una persona sabe justificar es la misma discusión
  otra vez dentro de un año. Ambos se corrigen con documento, no con confianza.
- **Carga de guardia y horario**: la operación fuera de horario es de `sre-practice-standards`, pero
  **la decisión de sostener una guardia con dotación insuficiente es de liderazgo, y es una decisión
  de riesgo**: se declara por escrito con su fecha de revisión, como cualquier riesgo aceptado.
- **La urgencia no es un método de gestión.** Un equipo en urgencia permanente no puede distinguir lo
  importante, deja de invertir en lo que reduciría la urgencia, y deja de creer las urgencias reales.
  **Indicador falsable**: proporción de trabajo no planificado en el ciclo (`sre-practice-standards`
  lo define). Si supera de forma sostenida el umbral que el equipo publique, **la causa está en la
  planificación o en el sistema, y esa es la conversación**, no exigir más esfuerzo.
- **Tiempo del líder auditado como cualquier recurso**: si más del ~50 % se va en reuniones sin
  decisión asociada, se aplica el test de §1 a cada reunión recurrente y se elimina lo que no lo pase.
- **Cadencia mínima de revisión**: escala y niveles, anual; arquetipos y asignaciones staff+,
  semestral; presupuesto de deuda, por ciclo de planificación; ADR con fecha de revisión vencida,
  trimestral; fronteras de equipo y dependencias, semestral o ante reorganización.

## 7. Sostenibilidad a largo plazo y prohibiciones

**Deprecación de norma de equipo**: toda regla que el líder introduzca se introduce **con la
condición que la haría innecesaria**. Sin condición de retirada, una norma es permanente por
omisión, y así se acumula el proceso que nadie defendió nunca explícitamente.

**Traspaso del rol**: un líder que cambia de puesto entrega escrito el mapa de decisiones abiertas,
los compromisos con otros equipos, el estado de desarrollo de cada persona y las decisiones
pendientes con su fecha. **Sin ese documento, el sucesor descubre los problemas por la vía del
incidente.**

PROHIBIDO:
- ❌ **Decidir sin registrar.** Si condiciona a alguien que no estuvo en la sala, se escribe (§3.3).
  Una decisión no registrada se vuelve a discutir, y la segunda discusión es más cara.
- ❌ **ADR sin campo de reversibilidad**, y **tratar toda decisión como irreversible**: es la causa
  documentada de parálisis organizativa (Bezos 2015, §2).
- ❌ **Medir a personas por líneas de código, commits, PRs, puntos, *velocity* o métricas DORA
  individuales**, ni en evaluaciones, ni en paneles, ni "solo para verlo". Contradice la posición
  publicada de DORA y de SPACE (§3.9) y se manipula el día que se publica.
- ❌ **Clasificar personas con el vocabulario del "10x"** o con cualquier cociente de productividad
  individual: la cifra fundacional está desmontada (Prechelt 1999, §2).
- ❌ **Usar cifras sin estudio primario, muestra y método** en un documento, una diapositiva o una
  petición de presupuesto (§2). Aplica en particular a los minutos por interrupción y a los
  porcentajes de rotación por mal jefe.
- ❌ **Usar la urgencia como método de gestión.** Todo urgente = nada priorizado, y el equipo deja de
  creer la siguiente urgencia, que será la de verdad.
- ❌ **Ser el cuello de botella de todas las decisiones.** Si nada avanza sin el líder, el problema
  es el reparto de autoridad, no la capacidad del equipo (§3.8, prueba de ausencia en §4).
- ❌ **Delegar responsabilidad sin autoridad** (§5). Es transferencia de culpa, y se detecta porque
  la persona no puede nombrar ni una decisión que pueda tomar sin consultar.
- ❌ **Adjudicarse el líder la funcionalidad crítica del trimestre**: crea un SPOF y desactiva la
  parte formativa del trabajo.
- ❌ **Dejar de tocar el sistema por completo.** Sin contacto no hay criterio: los diseños se aprueban
  por confianza en la persona en vez de por su contenido (§3.8).
- ❌ **Usar la revisión de código como palanca de poder**: bloquear por estética, imponer la propia
  solución sin argumento, o retener aprobación para negociar otra cosa.
- ❌ **Nombrar personas como causa raíz en un postmortem**, y **ceder a la presión de arriba para
  identificar un culpable** (§3.10).
- ❌ **Cerrar un postmortem cuyas acciones no entran en el plan del ciclo siguiente.**
- ❌ **Arquetipos staff+ convertidos en títulos, niveles o casillas** de la escala (§3.2): la propia
  taxonomía es descriptiva y tiene crítica publicada.
- ❌ **Escala de niveles no publicada**, o promoción sin evidencia escrita contra ella.
- ❌ **Sorpresas en la evaluación de desempeño**: si es la primera vez que la persona lo oye, el fallo
  es del líder.
- ❌ **1:1 convertido en informe de estado**, o cancelado sistemáticamente por el líder.
- ❌ **Definir un nivel por una tecnología** ("senior de X"): caduca con la herramienta.
- ❌ **Reorganizar equipos sin problema declarado por escrito y sin coste esperado.**
- ❌ **"Release de refactor" que no entrega nada observable**, y **peticiones de refactor sin coste
  de negocio cuantificado** (§3.5).
- ❌ **Adoptar agentes de codificación sin asignar capacidad de revisión** ni declarar qué trabajo se
  reserva para el aprendizaje de los junior (§3.11).
- ❌ **Escribir en esta skill —o en cualquier documento de liderazgo del equipo— una frase que no
  decide nada.** "Fomentar la confianza", "liderar con el ejemplo", "cultura de excelencia": si no
  nombra artefacto, umbral o prohibición, sobra.

## 8. Verificación web obligatoria

Antes de fijar cualquiera de estos puntos:

1. **SPACE — hueco declarado.** El texto completo **no se ha podido recuperar en verbatim**: ACM
   Queue (`queue.acm.org/detail.cfm?id=3454124`) y CACM devuelven **403** a la descarga
   automatizada, y `dl.acm.org` está tras muro. Las formulaciones de §2 y §3.9 proceden de fuentes
   secundarias concordantes. **Antes de citar literalmente el artículo, obtener el PDF por una vía
   con acceso** (biblioteca institucional, la página de publicación de Microsoft Research) y
   confirmar la redacción exacta de los mitos y de la recomendación de medir ≥ 3 dimensiones.
2. **DORA**: edición vigente y su título en `dora.dev`. A ago-2026: **2025 = *State of AI-assisted
   Software Development***; **2026 = *The ROI of AI-Assisted Software Development*** (según cobertura
   de InfoQ, may-2026, **no confirmado contra `dora.dev` en esta verificación** — confirmarlo).
   Existe crítica publicada al informe de 2026 por apoyarse en recomendaciones especulativas frente
   al rigor investigador previo: **verificar el método declarado antes de citarlo como evidencia**.
   Confirmar también que sigue vigente la posición de no usar las métricas a nivel individual.
3. **Arquetipos staff+**: si `staffeng.com` / `lethain.com` mantienen los cuatro arquetipos y los
   umbrales de escala (~100 / ~1.000 ingenieros), y si ha aparecido crítica o taxonomía alternativa
   con mejor base. **Nunca presentarlos como resultado de investigación.**
4. **Carga cognitiva y topologías de equipo**: comprobar si ha aparecido **evidencia empírica**
   (instrumento validado, réplica) que permita subir el estatus de la analogía. Hasta entonces se
   cita como analogía, no como medición, coherente con `platform-engineering-standards` §6.4.
5. **Carta de Bezos 2015**: el verbatim de §2 se extrajo del PDF oficial. Si se vuelve a citar,
   **extraerlo del PDF, no de un resumen** — la mayoría de fuentes secundarias lo fecha mal en 2016.
6. **ADR**: si `adr.github.io` recomienda otro formato por defecto y si la plantilla Nygard sigue
   siendo la de referencia; herramientas (`adr-tools` y sucesores) y su mantenimiento real —
   **leer el `LICENSE` en crudo** antes de adoptar ninguna.
7. **Cualquier cifra sobre personas, productividad, rotación o interrupciones**: localizar estudio
   primario, año, muestra y método **antes** de usarla. Si no aparece, o si la metodología está
   cuestionada (10x/Sackman, los 23 minutos, el 70 % de Gallup — §2), **no se usa**. Este es el
   dominio del catálogo con mayor densidad de cifras folclóricas.
8. **Escalas de carrera públicas**: `progression.fyi` y `github.com/bmoeskau/engineering-ladders`
   siguen vivos y qué escalas mantienen. Comprobar la fecha de cada una: varias son de 2015-2019 y
   describen organizaciones que ya no existen en esa forma.
9. **Marco laboral aplicable** a evaluación, retribución, clasificación profesional y despido en la
   jurisdicción concreta (en España: convenio aplicable y Estatuto de los Trabajadores). **Este
   documento fija criterio de ingeniería, no asesoramiento laboral**: la parte con efectos jurídicos
   se contrasta con asesoría legal y con RR. HH.
10. **Uso de IA en decisiones sobre personas** (evaluación, promoción, asignación): régimen legal en
    evolución — `ai-governance-standards` y `technical-hiring-standards` §5 mantienen el estado del
    **AI Act** y sus fechas. Verificarlo antes de introducir cualquier herramienta que puntúe
    personas.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
