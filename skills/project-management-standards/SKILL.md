---
name: project-management-standards
description: Use when work is organized as a project or delivery programme — choosing predictive, agile or hybrid delivery for a given piece of work, writing a project charter, statement of work or product backlog, declaring which of scope, time, cost, quality and risk is fixed and which floats, estimating with ranges instead of single dates, relative estimation and story points, Monte Carlo forecasting over throughput data, planning fallacy and reference class forecasting, WIP limits, lead time and cycle time, cumulative flow and burnup charts, a RAID or risk-and-assumption log with owner and trigger, cross-team dependency tracking and critical path, a RACI and stakeholder communication plan, RAG status reports and watermelon reporting, milestone versus incremental delivery, change-request and scope-change control, decision records for management decisions, project closure with acceptance criteria and handover to operations, retrospectives with owned actions, PMBOK Guide Eighth Edition, PRINCE2 7, the Scrum Guide, SAFe, Kanban, or citing Standish CHAOS Report figures.
---

# Estándares de gestión de proyectos y entrega

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **cómo se entrega trabajo ya decidido**: elección del enfoque de entrega, compromisos y su
formulación, estimación y previsión, gestión del flujo, riesgos y supuestos, dependencias entre
equipos, comunicación con interesados, registro de decisiones y cierre con traspaso a operación.

Triggers: "acta de proyecto", "charter", "SOW", "alcance", "triángulo de hierro", "estimación", "story
points", "velocity", "Monte Carlo", "throughput", "lead time", "cycle time", "WIP", "burnup", "camino
crítico", "dependencias", "RAID", "registro de riesgos", "supuestos", "RACI", "plan de comunicación",
"informe de estado", "RAG", "semáforo", "hito", "control de cambios", "petición de cambio",
"retrospectiva", "cierre de proyecto", "traspaso a operación", "PMBOK", "PRINCE2", "Scrum Guide",
"SAFe", "Kanban", "CHAOS Report".

**Principio rector**: **entregar valor con restricciones conocidas y decisiones registradas — no
rellenar plantillas.** Un artefacto de gestión solo se justifica si **cambia una decisión**: si el
registro de riesgos no ha alterado ninguna prioridad en tres meses, no es un registro de riesgos, es un
documento. Test falsable aplicable a cualquier artefacto o ceremonia propuesta: **nombra la decisión
que habilita, quién la toma y con qué frecuencia se ha tomado realmente en el último trimestre.** Lo
que no lo supere, se elimina.

Corolario: **la incertidumbre no se elimina declarando una fecha; se acota y se declara.**

**No aplica**:
- `product-discovery-standards` (**Ola 6, planificada**): **qué se construye y por qué** — problema,
  usuario, hipótesis, validación, priorización por valor y decisión de matar una idea. Aquí, **cómo se
  entrega lo ya decidido**. Frontera dura: si la discusión es *"¿merece la pena esto?"*, no es esta
  skill; si es *"¿cuándo y con qué riesgo estará?"*, sí.
- `tech-leadership-standards` (**Ola 6, planificada**): decisiones técnicas, diseño de equipo,
  desarrollo profesional, *career ladder* y la conversación individual. Aquí no se gestionan personas,
  se gestiona trabajo.
- `sre-practice-standards`: **las métricas DORA y el trabajo no planificado son suyos**, igual que SLO,
  error budget y capacity planning. Aquí se usa el dato de trabajo no planificado como **restricción de
  capacidad** al comprometer, no se define.
- `itsm-itil-standards`: **el servicio, su catálogo, el SLA y la operación continua**. Recíproca:
  **el proyecto entrega, el servicio opera.** El traspaso es un artefacto con criterios de aceptación
  (lista canónica en su §3) y **un proyecto que entrega algo que nadie puede operar no ha terminado**:
  sin dueño de servicio, runbook, alerta y restauración probada, el proyecto sigue abierto.
- `testing-qa-standards` y `code-review-standards` (ya escritas): la ***Definition of Done* técnica
  vive allí** — cobertura, gates, criterios de merge. Aquí la DoD de **entrega** (aceptado por el
  interesado, desplegado, operable, comunicado). No se duplican: la DoD de gestión **incluye por
  referencia** la técnica, no la reescribe.
- `git-workflow-standards`: tamaño de PR, ramas, versionado y release. La cadencia de integración es
  suya; aquí sus consecuencias sobre el flujo.
- `cicd-standards`: pipeline y automatización de despliegue.
- `enterprise-architecture-standards` (**Ola 6, planificada**): hoja de ruta de capacidades, gobierno
  de arquitectura y la cartera de aplicaciones. La cartera de **proyectos** se cruza con ella: qué
  proyecto toca qué capacidad.
- `finops-standards` (**Ola 6, en curso**): **el coste como restricción medida** — presupuesto cloud,
  unidad económica, previsión de gasto. Aquí el coste es una de las variables del compromiso; su
  modelado y control corresponden allí.
- `grc-compliance-standards`: obligaciones regulatorias que condicionan el alcance y las evidencias
  formales de aprobación exigidas por un marco.
- `refactoring-tech-debt-standards` (**Ola 6**): **qué deuda existe, cuánto cuesta su interés y qué
  técnica la paga es suyo**; **cómo se financia ese trabajo dentro de la entrega es de aquí** —
  porcentaje fijo de capacidad, oportunismo o proyecto dedicado, y la negociación con las partes
  interesadas. Aviso que ambas comparten y que esta skill debe sostener ante presión: **el proyecto
  dedicado de "limpieza" suele fracasar** porque compite con funcionalidad y pierde; la asignación
  sostenida de capacidad es lo que sí funciona.
- `software-architecture-patterns-standards` (**Ola 6**): el criterio técnico de estilo, límites y
  decisiones registradas es suyo; aquí el plan, el riesgo y el compromiso de fechas que rodean esa
  decisión.

## 2. Decisiones por defecto

> Verificar por web ediciones vigentes, propiedad y precios antes de fijarlos en un proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Enfoque de entrega | **Iterativo con incremento entregable** (Scrum o Kanban según variabilidad de la demanda) | Predictivo cuando el alcance está contractualmente fijado y el coste del cambio tardío es bajo |
| Marco citado en documentos | **Scrum Guide** (gratuita) y **Kanban / métricas de flujo** | PMBOK/PRINCE2 solo si el cliente o el pliego lo exigen |
| Unidad de compromiso | **Incremento desplegado y aceptado** | Hito documental **solo** con obligación contractual explícita |
| Forma de una fecha | **Rango con probabilidad** ("85 % antes del 12-nov") | Fecha única **solo** si es una restricción externa impuesta, y entonces flota el alcance |
| Método de previsión | **Monte Carlo sobre throughput histórico** (≥ 8-12 periodos) | Estimación relativa + velocity si no hay historial; estimación absoluta en horas solo para tareas conocidas y acotadas |
| Variable que flota | **El alcance**, declarado por escrito en el acta | Coste (añadir gente rara vez ayuda) o calidad (**nunca**: se prohíbe en §7) |
| Gestión del flujo | **Límite de WIP explícito por columna**, revisado mensualmente | — |
| Registro de riesgos | **RAID vivo** con dueño, disparador y fecha de revisión | — |
| Registro de decisiones | **ADR para lo técnico** + **registro de decisiones de gestión** con el mismo formato | — |
| Informe de estado | **Estado por evidencia observable**, no por color subjetivo | RAG **solo** con criterio numérico publicado que determine el color |
| Métrica de cabecera | **Lead time del ítem y previsión probabilística de la fecha** | — |
| Métrica prohibida como objetivo | Velocity, utilización de personas, horas imputadas (§7) | — |

**Estado real de los marcos (verificado ago-2026, re-verificar §8)**:
- **PMI / PMBOK**: la página oficial de estándares de PMI lista **A Guide to the Project Management
  Body of Knowledge (PMBOK Guide) — Eighth Edition** junto con *The Standard for Project Management*;
  mantiene principios y dominios de desempeño de la 7.ª edición y reintroduce guía de procesos de forma
  no prescriptiva. **De pago** (históricamente con PDF incluido en la membresía de PMI).
  **Discrepancia declarada**: las fechas exactas de publicación (nov-2025 vs. inicio de 2026) y la de
  actualización del examen PMP proceden de blogs de formación y **se contradicen entre sí**; el PDF del
  índice alojado en pmi.org lleva sello de sep-2025. **No citar una fecha sin confirmarla en pmi.org.**
  El examen PMP se rige por el *Examination Content Outline*, no por el PMBOK: son objetos distintos.
- **PRINCE2**: **propiedad de PeopleCert**, que adquirió AXELOS (adquisición completada en jul-2021;
  antes era una *joint venture* del Cabinet Office británico y Capita). Edición vigente **PRINCE2 7**,
  disponible desde **sep-2023**; los "temas" pasaron a llamarse **prácticas**. **Material de pago**: el
  manual va incluido en el examen y **no se puede reproducir en documentación interna**.
- **Scrum Guide**: versión vigente **noviembre 2020**, gratuita en `scrumguides.org`, mantenida por
  Schwaber y Sutherland al margen de cualquier empresa. **Es el único marco de esta lista que se puede
  citar y redistribuir sin coste**; scrum.org y Scrum Alliance publican comentario, no la norma.
- **SAFe**: **de pago y con licencia de marca**. Scaled Agile **ha abandonado los números de versión**:
  6.0 fue la última numerada y ahora se publica por fecha (`[año].[mes]`), con la marca actual
  **AI-Native SAFe** (anuncio de jun-2026). **Consecuencia práctica: escribir "SAFe 7" en un documento
  es un error de hecho.** Verificar el nombre y la fecha de release exactos antes de citarlo.
- **Regla de citabilidad**: en documentación interna o en una respuesta a un pliego, **cita la Scrum
  Guide o describe el proceso con vocabulario propio**. PMBOK, PRINCE2 y SAFe se mencionan como
  referencia, nunca se transcriben.

**Cifras famosas: qué NO se usa como dato.**
- ❌ **Standish Group / CHAOS Report**. Es el ejemplo canónico de cifra famosa con metodología
  cuestionada. **Eveleens y Verhoef, "The Rise and Fall of the Chaos Report Figures", *IEEE Software*
  27(1):30-36, ene-2010** (DOI 10.1109/MS.2009.154) documentan cuatro fallos: definiciones engañosas
  basadas solo en exactitud de la estimación, medida de exactitud unilateral, incentivos perversos, y
  agregación con sesgo desconocido; aplicando las definiciones de Standish a 5.457 previsiones sobre
  1.211 proyectos reales, los resultados no reproducían los de Standish. Añádase que **los datos
  brutos y el marco muestral no son públicos** y que el diseño original (solicitar historias de fracaso
  a directivos de TI) introduce sesgo de selección. **Última edición: CHAOS 2020**, así que cualquier
  "dato CHAOS 2025" es reciclado. **Uso permitido**: como *dirección* citando explícitamente el
  informe, su año y la crítica de Eveleens-Verhoef. **Uso prohibido**: como porcentaje en una
  justificación, una diapositiva o una decisión de inversión.
- ❌ **"El 70 % de las transformaciones fracasa"** y variantes. Circula sin estudio primario
  localizable. **No se escribe.**
- ✅ **Lo que sí es citable con fuente**: el **sesgo de planificación** (*planning fallacy*), nombrado
  por **Kahneman y Tversky, "Intuitive Prediction: Biases and Corrective Procedures", TIMS Studies in
  Management Science 12:313-327 (1979)** — la tendencia sistemática a subestimar tiempo, coste y riesgo
  incluso teniendo experiencia directa de casos similares; y su corrección, la **vista externa /
  *reference class forecasting*** (Lovallo y Kahneman 2003; Flyvbjerg 2008, *European Planning Studies*
  16(1):3-21), respaldada por la American Planning Association desde 2005. **Existe crítica reciente**
  a la RCF (*Production Planning & Control*, 2025): su base experimental es limitada y en la práctica
  se aplica como recargo *post hoc*. Cítese con esa reserva, no como ley.

## 3. Estructura y convenciones

### Elección del enfoque: por naturaleza del trabajo, no por moda

Se decide con estas cuatro preguntas, respondidas por escrito en el acta. **No hay puntuación: si
alguna respuesta cae en la columna derecha, el enfoque predictivo puro está descartado.**

| Pregunta | Predictivo apto si… | Iterativo apto si… |
|---|---|---|
| ¿Se conocen los requisitos con detalle suficiente para construir? | Sí, y están estables | No, o se aprenderán al usar el producto |
| ¿Cuánto cuesta cambiar de opinión tarde? | Poco (obra sobre plano, migración con destino fijo) | Mucho (producto con usuarios, integración desconocida) |
| ¿Hay obligación contractual o regulatoria de alcance y fecha fijos? | Sí | No |
| ¿Se puede entregar valor en trozos usables? | No (indivisible: una migración, una certificación) | Sí |

**Híbrido honesto**: el proyecto tiene **fases con naturaleza distinta** y cada una usa su enfoque, con
la frontera declarada — p. ej. hardware y obra civil predictivos con fecha de entrega, software encima
iterativo con alcance flotante. Se escribe cuál es cuál y qué se compromete en cada una.

**Híbrido como excusa** (reconocible y vetado): se ejecuta en sprints pero **el alcance, la fecha y el
coste siguen fijos desde el día uno**. Eso no es híbrido, es predictivo con ceremonias: se paga el coste
de ambos (la sobrecarga de la iteración y la rigidez del plan) sin obtener el beneficio de ninguno.
**Síntoma diagnóstico**: existe un backlog "priorizado" en el que nada se ha despriorizado nunca.

### El triángulo y su versión honesta

Cinco variables, no tres: **alcance, tiempo, coste, calidad y riesgo**. Regla:

> **Se fijan como máximo dos. Al menos una flota, y se declara por escrito cuál, en el acta, firmada
> por quien paga.**

- **La calidad no es una variable que flote.** Recortar calidad no libera tiempo: lo adelanta y lo cobra
  con intereses en operación. Lo que sí puede flotar es el **alcance de la calidad** (qué escenarios se
  soportan, qué navegadores, qué carga), declarado explícitamente — no el rigor sobre lo que se entrega.
- **El riesgo es la variable que se olvida y la que explota.** Comprimir plazo sin reducir alcance no
  hace desaparecer el trabajo: lo convierte en riesgo aceptado tácitamente. Si se acepta, se acepta
  **por escrito y con nombre** (`grc-compliance-standards` para el formalismo de aceptación de riesgo).
- Frase que debe aparecer literalmente en el acta: *"Es fijo X. Flota Y. Ante conflicto, se sacrifica Y
  y decide Z."* Sin ella, en el primer conflicto se sacrificará la calidad en silencio.

### Estimación y previsión

1. **Las estimaciones absolutas fallan de forma sistemática y direccional**, no aleatoria: es el sesgo
   de planificación (§2, Kahneman y Tversky 1979). Consecuencia: **promediar estimaciones optimistas no
   las corrige**; hay que introducir información distribucional externa.
2. **Estimación relativa** (tallas, puntos) para ordenar y dimensionar el backlog. **Nunca se convierte
   a horas ni a euros**: la conversión reintroduce el sesgo y añade una falsa precisión.
3. **Previsión probabilística como método defendible**: Monte Carlo sobre el **throughput histórico**
   (ítems terminados por periodo) responde *"¿cuándo estarán N ítems?"* y *"¿cuántos ítems para la
   fecha F?"* con probabilidades. Requisitos duros para que el resultado signifique algo:
   - **≥ 8-12 periodos** de historial del **mismo equipo y mismo tipo de trabajo**.
   - **Proceso estable con WIP limitado**. Sin límite de WIP no hay flujo estable y la previsión es
     ruido con formato de gráfico.
   - **Re-ejecución cada 1-2 semanas**; una previsión es perecedera, no un compromiso.
   - Publicar **percentiles 50 / 85 / 95**, no la media. La media de una distribución con cola larga
     no es una fecha útil.
4. **Vista externa antes de comprometer**: buscar 3-5 trabajos comparables ya terminados y su duración
   real. Si la estimación interna es mejor que **todos** los comparables, la estimación está mal —
   no el mundo.
5. **Regla de compromiso, sin excepciones**:

   > **No se compromete una fecha sin rango.** Una fecha única es un rango cuyo intervalo se ha
   > ocultado, y siempre se interpreta como el percentil 50 presentado como percentil 95.

   Formulación válida: *"85 % de probabilidad de estar antes del 12-nov; 50 % antes del 28-oct"*.
   Formulación inválida: *"estará el 28 de octubre"*.
6. **Descomposición como control de calidad de la estimación**: si un ítem no se puede descomponer,
   es que no se entiende; **estimarlo en horas es simular conocimiento** (prohibido, §7). Se
   convierte primero en una *spike* con caja de tiempo fija y resultado documentado.
7. **La estimación cuesta dinero.** Si el trabajo es homogéneo y hay historial, **el conteo de ítems
   pronostica igual de bien que estimarlos**: dejar de estimar es una decisión legítima y medible.

### Flujo

- **WIP limitado por columna** y visible. La justificación es aritmética, no cultural: por la ley de
  Little, `lead time = WIP / throughput`; con throughput dado, **doblar el WIP dobla el lead time sin
  entregar más**. Todo trabajo en curso adicional es trabajo terminado más tarde.
- **Métricas de flujo mínimas y públicas**: `lead time` (desde el compromiso con el cliente hasta la
  entrega — es lo que el cliente experimenta), `cycle time` (desde que se empieza), `throughput`,
  **edad del trabajo en curso** (la única que permite actuar *hoy*: el ítem que supera el percentil 85
  de cycle time se escala antes de convertirse en sorpresa) y **% de trabajo no planificado**
  (`sre-practice-standards` lo define; aquí resta de la capacidad comprometible).
- **La utilización de personas es contraproducente como objetivo, y es teoría de colas, no opinión**:
  en cualquier sistema con variabilidad, el tiempo de espera crece de forma no lineal con la ocupación
  y tiende a infinito al acercarse al 100 %. Planificar al 100 % de ocupación **garantiza** que
  cualquier imprevisto se propague como retraso. Se optimiza el flujo del **trabajo**, no la ocupación
  de las **personas**. Un equipo con holgura entrega antes; uno saturado entrega tarde y con más
  defectos.
- **Retraso de rehacer**: contabilizar el retrabajo como categoría propia. Un flujo aparentemente sano
  con 30 % de retrabajo no es un flujo sano.

### Riesgos y supuestos: registro vivo o no existe

Un registro que se escribe al inicio y no se vuelve a mirar es un pasivo: da falsa cobertura. Formato
mínimo obligatorio por entrada — **una entrada sin `disparador` y sin `dueño` no se acepta**:

```yaml
- id: R-014
  tipo: riesgo                       # riesgo | supuesto | incidencia | dependencia
  enunciado: "Si el proveedor X no entrega la API antes del 30-sep, el módulo de cobros no arranca"
  dueño: nombre.apellido             # persona con autoridad para actuar, no el PM por defecto
  disparador: "30-sep sin entorno de pruebas del proveedor"   # observable y fechado
  probabilidad: media                # o cualitativo, pero consistente en todo el registro
  impacto: "3 semanas de retraso en el hito de cobros"        # cuantificado
  respuesta: "Mitigar: desarrollar simulador de la API (5 d)" # evitar|mitigar|transferir|aceptar
  accion_hasta: 2026-09-15           # fecha, no 'en curso'
  estado: abierto
  revisado: 2026-08-20
```

- **Un supuesto es un riesgo con la probabilidad puesta a 1 por comodidad.** Todo supuesto lleva
  disparador de invalidación; cuando salta, se convierte en riesgo o en incidencia el mismo día.
- **Revisión quincenal con quórum**; cada entrada se cierra, se reevalúa o cambia de dueño. Una entrada
  sin revisar en dos ciclos se escala: o importa, o se borra.
- **Riesgo aceptado = decisión registrada** (abajo), con nombre de quien acepta. "Lo asumimos" dicho en
  una reunión no es aceptación de riesgo.

### Dependencias entre equipos: la causa dominante del retraso real

En organizaciones con varios equipos, **el tiempo se pierde esperando, no ejecutando**. La media de
ejecución de una tarea rara vez explica el retraso; la cola frente al equipo del que se depende, sí.

- **Registro explícito de dependencia**: quién necesita qué, de quién, para cuándo, y **qué se hace si
  no llega** (ruta alternativa). Una dependencia sin plan B es una fecha regalada a otro equipo.
- **Cada dependencia tiene fecha de compromiso acordada con el equipo proveedor**, no asignada por el
  que depende. Una fecha no acordada no es un compromiso, es una expectativa.
- **Estrategia por orden de preferencia**: (1) **eliminar** la dependencia (duplicar o autoservicio),
  (2) **desacoplar** con contrato de interfaz y simulador, (3) **secuenciar** con compromiso mutuo,
  (4) escalar. La (1) casi nunca se considera y suele ser la más barata.
- **Métrica**: tiempo bloqueado por dependencia externa como % del lead time. Si supera el 30 %, el
  problema no es de planificación sino de arquitectura organizativa: escalarlo como tal
  (`enterprise-architecture-standards`, `platform-engineering-standards`).

### Interesados y comunicación

- **Mapa de interesados con nivel de decisión**: quién aprueba, quién debe ser consultado, quién solo
  informado. Un RACI **con una sola A por decisión**; dos "accountable" es cero.
- **Cadencia fija y contenido fijo**, escrito de antemano:

| Audiencia | Cadencia | Contenido |
|---|---|---|
| Equipo | Diaria (≤ 15 min) | Bloqueos y edad del trabajo en curso; **no** informe de estado individual |
| Patrocinador / dueño del presupuesto | Quincenal | Previsión con rango, riesgos con disparador vencido, decisiones que necesita tomar |
| Interesados amplios | Por incremento entregado | Qué se puede usar ya y qué cambió respecto de lo previsto |
| Comité / dirección | Mensual o por excepción | Desviación frente al compromiso declarado y la decisión pedida |

- **El informe que no miente**. El patrón a evitar tiene nombre: ***watermelon reporting*** — verde por
  fuera, rojo por dentro; el estado se vuelve más verde a medida que sube por la jerarquía, y de golpe
  se pone rojo cuando ya no hay margen. Su causa raíz **no es deshonestidad individual sino cultura de
  culpa**: si informar en rojo trae reproche en vez de ayuda, nadie informa en rojo. Contramedidas
  concretas y verificables:
  1. **El color se calcula, no se opina**: se deriva de un criterio numérico publicado (p. ej. la
     previsión al percentil 85 excede la fecha comprometida → rojo). Si el color se elige a mano, es
     una opinión con formato de dato.
  2. **Toda casilla no verde exige la petición asociada** ("necesito X de Y antes de Z"). Un rojo sin
     petición es queja; un rojo con petición es gestión.
  3. **Se informa la previsión, no el porcentaje de avance.** "80 % completado" no es información;
     "85 % de probabilidad de terminar antes del 12-nov" sí.
  4. **Prohibido cambiar el color al subir de nivel.** El informe agregado enlaza el original sin
     retocarlo; cualquier matiz va como comentario firmado, no como recoloreado.
  5. **Rojo se trata como petición de ayuda**, y quien lo declara pronto no recibe reproche. Esto es
     una regla de conducta del patrocinador, y sin ella las cuatro anteriores no funcionan.

### Decisiones registradas

**Una decisión sin registro se vuelve a discutir** — y la segunda discusión es más cara porque ya hay
código escrito y egos invertidos. Dos registros con el mismo formato y el mismo repositorio:

- **ADR** para decisiones técnicas (arquitectura, tecnología, patrón).
- **Registro de decisión de gestión** para alcance, secuencia, contratación, aceptación de riesgo,
  cambio de compromiso.

Campos mínimos: `fecha`, `decisor` (persona), `contexto`, `opciones consideradas`, `decisión`,
`consecuencias`, `fecha de revisión` y **`reversibilidad`** (puerta de un sentido / de dos sentidos).
**Regla de velocidad derivada de la reversibilidad**: una decisión reversible se toma rápido y al nivel
más bajo posible; una irreversible se instruye, se documenta y se decide arriba. **Tratar todas las
decisiones como irreversibles es la forma más común de parálisis en gestión.**

Cambios de alcance: **toda petición de cambio se registra con su impacto en las cinco variables (§3)
antes de aceptarse o rechazarse**. Aceptar alcance sin declarar qué se mueve es la mecánica exacta del
*scope creep* — no un accidente, una omisión.

### Cierre

Un proyecto cierra cuando **el receptor lo acepta y alguien puede operarlo**, no cuando se agota el
presupuesto ni cuando el equipo se disuelve.

1. **Criterios de aceptación escritos antes de empezar** y verificados por el interesado que los
   escribió, no por el equipo que los implementó.
2. **Traspaso a operación completo** según la lista de `itsm-itil-standards` §3 (dueño de servicio,
   catálogo, SLA u OLA, runbooks, alertas, backup con restauración probada, CMDB, formación,
   *hypercare* con fecha de fin). **Sin ella el proyecto no está cerrado**, esté como esté la factura.
3. **Retrospectiva con acciones que alguien ejecuta**: cada acción tiene dueño, fecha y aparece en el
   backlog del siguiente ciclo. **Una retrospectiva cuyas acciones no se ejecutan enseña al equipo que
   la retrospectiva es teatro**, y es peor que no hacerla. Métrica: % de acciones de retro cerradas en
   el ciclo siguiente; si baja del 70 %, se dejan de generar acciones y se arregla el mecanismo.
4. **Comparación previsión vs. real archivada**: alimenta la clase de referencia del siguiente proyecto
   (vista externa, §3). Sin este paso la organización repite el sesgo de planificación indefinidamente.
5. **Cierre administrativo**: contratos, licencias, accesos revocados, entornos temporales destruidos y
   coste recurrente heredado declarado (`finops-standards`).

## 4. Calidad de la gestión y controles

Controles automatizables sobre los datos del sistema de gestión. Se ejecutan programados; su fallo abre
trabajo, no un informe.

| Control | Falla si | Acción |
|---|---|---|
| Compromiso sin rango | existe una fecha comprometida sin percentil asociado | Bloquear publicación del compromiso |
| Variable flotante no declarada | acta sin la frase "es fijo X, flota Y" | No arrancar el proyecto |
| Riesgo sin dueño o sin disparador | campo vacío | Rechazar la entrada |
| Registro estancado | entrada sin revisar en 2 ciclos | Escalar al patrocinador |
| Supuesto vencido | fecha del disparador pasada sin evaluar | Convertir en riesgo o incidencia el mismo día |
| Dependencia sin fecha acordada | falta confirmación del equipo proveedor | Marcar como riesgo, no como plan |
| WIP por encima del límite | supera el límite de la columna | Parar de empezar, empezar a terminar |
| Ítem envejecido | edad > percentil 85 del cycle time | Escalar antes de que sea sorpresa |
| Estado sin evidencia | color no derivable del criterio numérico publicado | Rechazar el informe |
| Acciones de retro | < 70 % cerradas en el ciclo siguiente | Dejar de generar acciones; arreglar el mecanismo |
| Previsión caducada | Monte Carlo no re-ejecutado en > 2 semanas | Marcar la previsión como no válida |

**La DoD de entrega** (distinta de la técnica, que vive en `testing-qa-standards` y
`code-review-standards`, e **incluida por referencia**): aceptado por el interesado nombrado, desplegado
en producción, operable según el traspaso, documentado para quien lo use, y comunicado a los afectados.
**Un ítem "terminado" que no está desplegado no está terminado** — es inventario, y el inventario en
software solo se deprecia.

## 5. Seguridad y confidencialidad de la información de gestión

- **Los artefactos de gestión son información sensible**: el registro de riesgos, la previsión real y
  las actas contienen debilidades explotables, datos de proveedores y a veces información de personas.
  Control de acceso por rol, no "todo el mundo con el enlace".
- **Prohibido meter credenciales, datos personales o datos de cliente en tickets, hojas de cálculo de
  seguimiento o actas**. El backlog es un repositorio de texto libre con historial: lo que entra, se
  queda (`secrets-management-standards`, `privacy-engineering-standards`).
- **Requisitos regulatorios y de seguridad son alcance, no "no funcionales" que se recortan al final.**
  Se identifican en el acta con su fuente normativa (`grc-compliance-standards`). Un proyecto que
  descubre en la semana 20 que necesita una DPIA ya lleva 20 semanas de retraso sin saberlo.
- **Proveedores y subcontratas**: la dependencia contractual entra en el registro de riesgos con su
  cláusula de salida. Un proveedor crítico sin plan de salida es riesgo de continuidad
  (`bcdr-standards`).
- **Herramienta de gestión**: SSO con MFA, auditoría de cambios de estado y de fechas comprometidas.
  Una fecha comprometida que se puede editar sin traza invita a reescribir la historia.

## 6. Sostenibilidad del sistema de gestión y capacidad

*(La §6 canónica —rendimiento y operabilidad— no aplica a un dominio de proceso; **se sustituye
declarándolo** por la operabilidad del propio sistema de gestión.)*

- **Capacidad comprometible = capacidad bruta − trabajo no planificado histórico − ausencias − soporte**.
  Comprometer sobre capacidad bruta es la forma más común y menos discutida de incumplir. El porcentaje
  histórico de trabajo no planificado se toma del dato, no de la esperanza.
- **Cada ceremonia y cada artefacto se auditan semestralmente** con el test de §1 (qué decisión
  habilita, quién la toma, cuántas veces se ha tomado). Lo que no lo pase, se elimina — la sobrecarga
  de gestión crece por acumulación, nunca por decisión.
- **Coste de coordinación**: sumar personas a un proyecto tardío añade coordinación antes que capacidad.
  Antes de contratar, agotar: reducir alcance, eliminar dependencias, subir el límite de flujo.
- **Multiproyecto**: una persona en tres proyectos no aporta un tercio a cada uno; el cambio de contexto
  se lleva una parte que no se contabiliza en ningún sitio. **Asignación por defecto: una persona, un
  flujo de trabajo.**
- **Continuidad del conocimiento**: el registro de decisiones y el traspaso a operación son lo único que
  sobrevive al equipo. Un proyecto cuyo estado solo existe en la cabeza del PM tiene un SPOF con
  vacaciones.
- **Sucesión del rol**: si el PM desaparece una semana, el sistema debe seguir siendo legible. Si no lo
  es, el problema no es el PM: es que el estado no está escrito.

## 7. Sostenibilidad a largo plazo y prohibiciones

**Cadencia**: acta y variables fijas revisadas en cada cambio de compromiso; RAID quincenal; previsión
cada 1-2 semanas; límites de WIP mensualmente; ceremonias y artefactos semestralmente; clase de
referencia actualizada al cierre de cada proyecto.

**Deprecación de proceso**: cada norma de gestión se introduce con la condición que la haría innecesaria.
Una norma sin condición de retirada es permanente por omisión, y así se acumula la burocracia que nadie
defendió nunca explícitamente.

PROHIBIDO:
- ❌ **Comprometer fecha, alcance y coste a la vez.** Es la mentira fundacional del proyecto: se
  descubrirá tarde y se pagará con calidad, que es la única variable que nadie declaró.
- ❌ **Estimar en horas lo que no se entiende.** Si no se puede descomponer, no se estima: se investiga
  con una *spike* de caja de tiempo fija.
- ❌ **Convertir puntos o tallas en horas o euros.** Reintroduce el sesgo y añade precisión falsa.
- ❌ **Comprometer una fecha sin rango ni probabilidad.**
- ❌ **Gestionar por hitos sin incremento entregable.** Un hito documental mide actividad, no valor, y
  permite estar "al 80 %" durante meses.
- ❌ **Usar la velocity como medida de productividad individual** (ni de equipo frente a otro equipo).
  Se infla de inmediato: los puntos son gratis. Mide capacidad de un equipo consigo mismo, nada más.
- ❌ **Objetivos de utilización de personas** (≥ 90 % facturable/ocupado). Garantiza colas y retrasos.
- ❌ **El informe verde por cortesía** (*watermelon*): color no derivable de un criterio publicado,
  recoloreado al agregar hacia arriba, o rojo sin petición asociada.
- ❌ **Recortar calidad como palanca de plazo.** Adelanta trabajo, no lo elimina, y lo cobra en operación.
- ❌ **Registro de riesgos escrito al inicio y no revisado**, o con entradas sin dueño ni disparador.
- ❌ **Aceptar un cambio de alcance sin declarar qué se mueve** en tiempo, coste o alcance existente.
- ❌ **Dependencia con fecha asignada unilateralmente** al equipo proveedor y sin ruta alternativa.
- ❌ **Cerrar un proyecto sin traspaso a operación aceptado** (`itsm-itil-standards` §3): si nadie puede
  operarlo, no ha terminado.
- ❌ **Retrospectivas sin acciones con dueño y fecha**, o con acciones que sistemáticamente no se cierran.
- ❌ **Citar cifras del CHAOS Report (u otras cifras de fracaso sin metodología pública) como dato** para
  justificar una decisión o un presupuesto (§2).
- ❌ **Copiar texto de PMBOK, PRINCE2 o SAFe en documentación interna**: material propietario de PMI,
  PeopleCert y Scaled Agile respectivamente. Se cita la Scrum Guide o se describe con vocabulario propio.
- ❌ **Escribir "SAFe 7"**: Scaled Agile abandonó el versionado numérico (§2).
- ❌ **Adoptar un marco escalado para resolver un problema de dependencias arquitectónicas**: añade
  ceremonias sobre el mismo acoplamiento y encarece el síntoma sin tocar la causa.
- ❌ **Una persona asignada a más de dos flujos de trabajo simultáneos** sin declarar el coste de cambio
  de contexto.

## 8. Verificación web obligatoria

Antes de fijar cualquiera de estos puntos en un proyecto real:

1. **PMI**: edición vigente en `pmi.org/standards/pmbok` — a ago-2026 aparece la **8.ª edición**, pero
   **la fecha de publicación es contradictoria entre fuentes de terceros** (nov-2025 vs. inicio de 2026;
   el índice alojado en pmi.org lleva sello de sep-2025). Confirmar fecha, precio, condiciones de acceso
   para miembros y el estado del *Examination Content Outline* del PMP, que se actualiza aparte.
2. **PRINCE2**: si PRINCE2 7 (sep-2023) sigue siendo la edición vigente y si PeopleCert continúa siendo
   el propietario; términos de uso de marca y material antes de citarlo.
3. **Scrum Guide**: comprobar en `scrumguides.org` si sigue vigente la versión de **noviembre 2020** —
   es la referencia gratuita por defecto de este documento y una revisión cambiaría vocabulario.
4. **SAFe**: nombre y fecha de la release actual en `framework.scaledagile.com` (esquema
   `[año].[mes]`, marca **AI-Native SAFe** a jun-2026) y condiciones de licencia. **Nunca escribir un
   número de versión sin verificarlo.**
5. **Cifras**: antes de usar cualquier porcentaje de fracaso, éxito o "transformaciones que fallan",
   localizar el **estudio primario, su año, su muestra y su método**. Si no aparece, o si la metodología
   está cuestionada (caso CHAOS/Standish, §2), **no se usa**. Verificar también si Standish ha publicado
   algo posterior a CHAOS 2020.
6. **Sesgo de planificación y *reference class forecasting***: comprobar el estado del debate — hay
   crítica publicada reciente a la RCF (*Production Planning & Control*, 2025) que conviene citar junto
   a Kahneman-Tversky (1979) y Flyvbjerg (2008) para no presentar la corrección como más sólida de lo
   que es.
7. **Herramientas de gestión y previsión**: estado, licencia y precio de lo que se proponga (Jira y su
   reorganización de oferta y retirada de Data Center, Azure DevOps, ActionableAgile, alternativas
   libres). Para lo *open source*, **leer el `LICENSE` en crudo del repositorio**.
8. **Marco contractual y regulatorio** del proyecto concreto (pliego, DORA-UE, NIS2, ENS, EU AI Act si
   hay componente de IA): puede imponer un marco de gestión, evidencias formales o plazos —
   `grc-compliance-standards` y `ai-governance-standards`.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
