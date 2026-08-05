---
name: refactoring-tech-debt-standards
description: Standards for managing technical debt and refactoring legacy code. Use when writing or triaging a technical debt register or TODO/FIXME backlog, deciding what debt to pay and how to fund it (fixed capacity slice, boy scout rule, dedicated cleanup project), refactoring code smells (long method, god class, feature envy, primitive obsession, shotgun surgery), adding characterization or golden-master tests to untested legacy code, running large-scale migrations with strangler fig, branch by abstraction, expand/contract and parallel change, debating a full rewrite, reading SonarQube/CodeScene/Code Climate reports, cyclomatic complexity and maintainability index thresholds, change-coupling and hotspot analysis over git history, or separating a refactor commit from a behavioural change.
---

# Estándares de refactorización y deuda técnica

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre **el camino desde el código que hay hasta el diseño que se quiere**: qué es deuda y qué no, cómo se registra, cómo se prioriza, cómo se financia, y con qué técnicas se paga sin romper el sistema. Triggers: "deuda técnica", "refactor", "refactorizar", "código legacy", "code smell", "characterization test", "golden master", "strangler fig", "rama por abstracción", "branch by abstraction", "expand/contract", "parallel change", "reescritura", "big rewrite", "hotspot", "complejidad ciclomática", "índice de mantenibilidad", "SonarQube", "CodeScene", "registro de deuda", "boy scout rule".

**Principio rector — la deuda técnica es una metáfora financiera y solo sirve si se usa como tal.** Tiene **principal** (el trabajo de arreglarlo), **intereses** (el sobrecoste que pagas en cada cambio mientras no lo arreglas) y una **decisión de amortizar** que se toma comparando ambos. Si no puedes nombrar el interés que estás pagando, no tienes deuda: tienes una opinión sobre el código. Corolario duro: **"deuda" no es sinónimo de "código que no me gusta"**, ni de "código viejo", ni de "el estilo del equipo anterior".

**No aplica**:
- `software-architecture-patterns-standards` (**recíproca**: **suyo el destino** — qué estilo, qué límites, qué patrón y qué fuerza lo justifica; **aquí el camino** — cómo se llega hasta ahí sin romper nada). Advertencia compartida: **migrar a un patrón nuevo sin tests es cambiar una deuda por otra mayor**.
- `testing-qa-standards` (**ya escrita — es la precondición de esta skill**: la estrategia de prueba, la pirámide, el criterio de cobertura y la calidad del test son suyos; **aquí** solo la exigencia no negociable de **cubrir el comportamiento antes de tocarlo** y la técnica de caracterización para legacy).
- `code-review-standards` (**ya escrita**: mecánica y criterio de la revisión; desde este lado se fija que **un refactor y un cambio funcional no se revisan igual y no van en el mismo commit** — el refactor se revisa contra "¿sigue igual el comportamiento?", el cambio funcional contra "¿es correcto el nuevo comportamiento?").
- `git-workflow-standards` (tamaño del cambio, ramas, historia, mecánica del commit).
- `vulnerability-management-standards` (**suyos** los CVE de dependencias, el triaje por riesgo y el EOL; **aquí** la deuda de *no haber actualizado* como decisión con interés creciente).
- `opensource-licensing-standards` (**Ola 6, en curso**: una dependencia que **relicencia** crea deuda con fecha de vencimiento — su criterio legal es de esa skill; aquí, el registro y el plazo).
- `cicd-standards` (el gate de calidad que se ejecuta y cómo se ejecuta).
- `tech-leadership-standards` (**Ola 6, en curso**: la decisión de inversión y su registro corporativo), `project-management-standards` (**ya escrita**: cómo se financia el trabajo, se planifica y se negocia con las partes interesadas).
- `performance-engineering-standards` (**optimizar no es refactorizar**: la optimización cambia características observables y a menudo empeora la legibilidad a propósito. Se mide, se justifica y se revisa aparte).

## 2. Decisiones por defecto

> Verificar la última versión, licencia y precio por web antes de fijarlo en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Precondición para refactorizar | **Tests que cubran el comportamiento afectado** | Ninguna. Si no hay, se caracteriza primero (§3) |
| Tamaño del paso | **El más pequeño que deje el sistema verde**; commit por paso | Pasos mayores solo con refactor automatizado por herramienta |
| Herramienta de refactor | **La del IDE/toolchain** (rename, extract, inline, move) | Manual solo donde no exista, y con test antes |
| Refactor vs cambio funcional | **Commits separados, siempre** | — |
| Migración grande | **Strangler fig** o **rama por abstracción** + **expand/contract** | Reescritura completa: solo con los criterios de §6 |
| Priorización | **Interés medido** (frecuencia de cambio × coste de cambiar) | Nunca por antigüedad ni por puntuación estética |
| Registro | **Deuda en el mismo backlog que el resto**, con dueño y disparador | Registro aparte solo si el backlog principal no admite metadatos |
| Financiación | **Porcentaje fijo de capacidad por iteración** + boy scout rule | Proyecto dedicado solo con los criterios de §6 |
| Análisis estático | El **linter/formatter** del stack, en CI y bloqueante | Plataforma de calidad si aporta señal nueva (§4) |
| Métrica de decisión | **Mapa de calor de cambio (git) cruzado con dificultad de cambio** | Ningún índice agregado como métrica única (§4) |

### 2.1 La metáfora, bien atribuida y bien usada

- **Origen: Ward Cunningham**, *"The WyCash Portfolio Management System"*, **experience report de OOPSLA '92** (Addendum to the Proceedings, pp. 29–30, DOI `10.1145/157709.157715`; texto en `c2.com/doc/oopsla92.html`). Su formulación: entregar código a la primera **es como endeudarse** — un poco de deuda acelera el desarrollo **mientras se devuelva puntualmente con una reescritura**; el peligro está en no devolverla, porque **cada minuto en código no-del-todo-correcto cuenta como interés**. **Matiz de atribución**: en el texto Cunningham desarrolla la metáfora de deuda e interés; la etiqueta "technical debt" se consolidó después.
  - **Lo que Cunningham NO dijo**: que la deuda sea escribir mal a propósito. Su deuda es el **desajuste entre lo que el código expresa y lo que ahora se entiende del dominio** — deuda por aprendizaje, no por chapuza. Usar su cita para justificar prisa es tergiversarlo.
- **Cuadrante: Martin Fowler**, bliki *"Technical Debt Quadrant"*, **14-oct-2009**. Dos ejes: **deliberada vs inadvertida** (¿sabíamos que la contraíamos?) y **prudente vs imprudente** (¿fue una decisión razonada?):
  - *Deliberada y prudente*: "hay que entregar ya y asumimos las consecuencias" — legítima **si se registra** (§5).
  - *Deliberada e imprudente*: "no tenemos tiempo para diseñar" — no es deuda, es daño.
  - *Inadvertida y prudente*: "ahora sabemos cómo deberíamos haberlo hecho" — inevitable en cualquier equipo bueno; es la de Cunningham.
  - *Inadvertida e imprudente*: "¿qué es eso de las capas?" — se resuelve con formación, no con backlog.
  - La observación de Fowler que hay que retener: **la distinción útil no es entre deuda y no-deuda, sino entre deuda deliberada e inadvertida.**
- **Consecuencia operativa**: cada entrada del registro (§5) declara su cuadrante. Las imprudentes no se "gestionan": se corta la causa (revisión, formación, gate en CI). Las prudentes se gestionan como deuda de verdad: principal, interés, disparador.

## 3. Refactorizar: definición, precondición y mecánica

### 3.1 Definición canónica (verbatim) y su consecuencia

**Martin Fowler**, *Refactoring: Improving the Design of Existing Code* (definiciones publicadas también en `refactoring.com`):

> *"noun: a change made to the internal structure of software to make it easier to understand and cheaper to modify without changing its observable behavior"*
>
> *"verb: to restructure software by applying a series of refactorings without changing its observable behavior"*

Fowler precisa que **"observable behavior" es deliberadamente impreciso**: el código debe hacer, a grandes rasgos, lo mismo que antes; la pila de llamadas cambia con un *extract function* y el rendimiento puede variar — **no debe cambiar nada que al usuario le importe**.

Consecuencias no negociables:
- **Un refactor que cambia comportamiento es un cambio funcional disfrazado** y se revisa, se prueba y se despliega como tal. Etiquetarlo "refactor" para que pase con menos escrutinio es un fallo de proceso, no un detalle de nomenclatura.
- **Refactorizar ≠ reestructurar ≠ optimizar ≠ reescribir.** Fowler usa "restructuring" como término general; la optimización de rendimiento a menudo **empeora** la legibilidad a propósito, y por eso no es refactor (→ `performance-engineering-standards`).
- Un PR titulado "refactor" con 40 ficheros y una corrección de bug dentro es irrevisable: nadie puede distinguir lo que cambió de lo que se movió.

### 3.2 La precondición no negociable

**Sin tests que cubran el comportamiento afectado, no se refactoriza: se reescribe a ciegas.** El test es lo único que convierte "cambié la estructura" en "no cambié el comportamiento". El criterio y la calidad de esos tests son de `testing-qa-standards`; lo que se fija aquí es que **existan antes del primer cambio**.

**Legacy sin tests** — obra de referencia y terminología: **Michael Feathers**, *Working Effectively with Legacy Code* (2004). Su definición operativa, deliberadamente incómoda: **legacy code es "código sin tests"** (no "código viejo"): sin tests no hay forma de verificar que sigue haciendo lo que hacía. Consecuencia: se puede escribir código legacy hoy mismo.

Procedimiento cuando no hay tests:
1. **Caracterizar primero.** Un **characterization test** (término acuñado por Feathers; también *golden master*) *"is a test that characterizes the actual behavior of a piece of code"*: documenta el comportamiento **real**, **no el que desearías que tuviera**. Mecánica del libro: escribe una aserción que sabes que fallará, lee el valor real en la salida del fallo y fíjalo.
2. **Los bugs también se caracterizan.** Si el comportamiento actual es incorrecto, se fija tal cual y se anota; corregirlo es un **cambio funcional aparte**, con su propia decisión y su propio commit.
3. **Encontrar el punto de corte** (*seam*) para poder instanciar y aislar la unidad; romper la dependencia con la mínima intervención posible (la más segura primero: extraer e inyectar, no rediseñar).
4. Solo entonces refactorizar, en pasos pequeños.
5. Para migraciones grandes con dependencias enmarañadas, el **Mikado Method** (Ola Ellnestam y Daniel Brolund, Manning, 2014) da un procedimiento explícito: intenta el cambio, anota lo que se rompe como prerrequisito, **revierte**, y ataca las hojas del grafo. La clave es que **se revierte**: el árbol se descubre con el sistema siempre verde.

### 3.3 Mecánica: orden, herramienta y tamaño del paso

- **Orden seguro**: primero lo que la herramienta puede hacer sola (renombrar, extraer, mover, cambiar firma), después lo que exige criterio (extraer clase, romper dependencia, cambiar el modelo). Nunca al revés.
- **Refactor automatizado > manual** siempre que exista: el IDE preserva referencias y no se salta usos. Vigila los puntos ciegos: reflexión, cadenas mágicas, inyección por nombre, SQL embebido, plantillas, configuración externa — ahí el "rename" seguro no lo es.
- **El tamaño del paso es el criterio de seguridad, no la velocidad.** Regla: si tras el paso no puedes ejecutar los tests y verlos verdes, el paso era demasiado grande. Cuanto peor conoces el código, más pequeño el paso.
- **Commit por paso verde**, con mensaje que diga qué transformación es. Una historia de refactor legible es lo que permite bisecar cuando algo se rompió tres semanas después.
- **Regla de los dos sombreros**: en cada momento o añades funcionalidad o refactorizas, nunca ambas. Si al refactorizar descubres un bug, anótalo y sigue; lo arreglas después, en su commit.

## 4. Qué se paga: interés, mapas de calor y la trampa de las métricas

### 4.1 Se prioriza por interés, no por antigüedad ni por fealdad

**El código feo que nadie toca no cuesta nada.** Un módulo horrible, estable, sin incidencias y sin cambios en dos años tiene interés ≈ 0: refactorizarlo es gasto puro y encima introduce riesgo. La deuda que se paga es la que **cobra intereses**:

**Interés ≈ frecuencia de cambio × dificultad de cambiar × impacto del fallo.**

Señales de interés real, todas observables:
- **Mapa de calor de cambio**: frecuencia de commits por fichero/módulo en el historial de Git, cruzada con dificultad de cambiar ese código. La actividad se concentra en pocos módulos: ahí, y solo ahí, la mala calidad se paga cada semana.
- **Acoplamiento por cambio**: ficheros que cambian siempre juntos sin estar relacionados por diseño (señal de límite mal puesto → `software-architecture-patterns-standards`).
- **Densidad de defectos y tiempo de resolución** por módulo.
- **Tiempo de ciclo** de los cambios que tocan esa zona, comparado con la media.
- **Bus factor**: si solo una persona puede tocarlo, el interés incluye el riesgo de que se vaya.

### 4.2 La trampa de las métricas

Las métricas agregadas dan sensación de objetividad y sustituyen la conversación. Estado real de las dos más citadas:

- **Complejidad ciclomática (McCabe)**: crítica publicada y no refutada.
  - **Shepperd, M. (1988), "A critique of cyclomatic complexity as a software metric", *Software Engineering Journal*** (IET, DOI `10.1049/sej.1988.0003`): fundamentos teóricos pobres y, para gran parte del software, **no es más que un sustituto de las líneas de código**, a menudo superado por ellas.
  - **Jay, G. et al. (2009), "Cyclomatic Complexity and Lines of Code: Empirical Evidence of a Stable Linear Relationship"** (*JSEA*): relación lineal estable y prácticamente perfecta entre CC y LOC, verificada sobre más de 1,2 millones de ficheros; concluyen que **CC no aporta poder explicativo propio** más allá del tamaño.
  - **Uso permitido**: umbral local como *olor* que abre una conversación sobre una función concreta. **Uso prohibido**: como KPI de calidad, como objetivo de equipo o como criterio de priorización de deuda.
- **Índice de mantenibilidad (MI)** (Oman & Hagemeister, 1992): peor. Es una combinación ponderada de volumen de Halstead, complejidad ciclomática, LOC y ratio de comentarios; **hereda el problema de CC y añade los suyos**.
  - **Arie van Deursen, "Think Twice Before Using the Maintainability Index" (2014)**: origen en un proyecto interno de HP con 16 proyectos valorados a ojo y decenas de modelos de regresión; los autores originales lo propusieron para comparaciones **relativas dentro del mismo equipo**, advertencia sistemáticamente ignorada.
  - Crítica de tooling (Teamscale, entre otros): **distintas herramientas calculan valores distintos** porque ajustan la fórmula, y el desarrollador **no puede predecir** cómo afectará su cambio — extraer un método baja la complejidad pero sube LOC, de modo que mejorar el código puede empeorar el índice. Además, promedia y oculta la distribución real.
  - **Criterio: no se usa el MI para decidir nada.**
- **Regla general**: una métrica sirve como **señal que abre una investigación**, nunca como objetivo (en cuanto es objetivo, se optimiza la métrica y no el código). **Prohibido medir la calidad por un único índice.**

### 4.3 Herramientas (verificar licencia y precio, §8)

- **Linter y formatter del stack**, en CI y bloqueantes: es el 80 % del valor por el 0 % del coste, y evita la discusión de estilo en revisión.
- **Fitness functions de arquitectura** (ArchUnit — Apache-2.0 — y equivalentes) para que la estructura no se erosione mientras pagas deuda. El criterio de qué regla escribir es de `software-architecture-patterns-standards`.
- **SonarQube**: **no es simplemente "open source"**. Desde el **29-nov-2024** el binario de **SonarQube Community Build** (antes *Community Edition*) sigue bajo **LGPLv3**, pero **los analizadores empaquetados pasaron a la Sonar Source-Available License v1 (SSALv1)**, una licencia *source-available* con restricción de uso competitivo — **no es open source** por la definición OSI. Community Build **no analiza ramas ni decora PRs**: esa es la puerta de pago. Las ediciones comerciales se facturan **por líneas de código**, no por usuario, así que el coste crece con el tamaño del repositorio. **Verificar precios vigentes en el proveedor antes de citarlos: las cifras que circulan en blogs son de terceros y divergen entre sí.**
- **Semgrep**: motor CLI open source (LGPL-2.1, copyleft — relevante si empaquetas producto); la plataforma en la nube es de pago por contribuidor y **las tarifas publicadas por terceros se contradicen entre sí** ($35 vs $40+ por contribuidor/mes según fuente): confirmar con el proveedor.
- **CodeScene**: análisis de comportamiento sobre el historial de Git (hotspots, change coupling, X-Ray a nivel de función, métrica *Code Health*). Es la categoría que mejor encaja con §4.1. **Producto comercial** y **métrica propietaria**: sus estudios de respaldo están firmados por su fundador y usan su propia métrica — conflicto de interés que hay que declarar antes de citarlos como evidencia independiente.
- **Regla transversal**: ninguna herramienta decide qué deuda se paga. Producen candidatos; la decisión es humana y va al registro (§5).

## 5. El registro de deuda (§5 sustituida: "seguridad del stack" resultaría artificial en un dominio de proceso — la seguridad aparece aquí como deuda de dependencias y como criterio de priorización, y su gestión pertenece a `vulnerability-management-standards`)

Una entrada de deuda que no se pueda accionar es ruido. Campos mínimos, y **todos obligatorios**:

| Campo | Por qué |
|---|---|
| **Qué es** | Descripción concreta y localizable (módulo/fichero), no "el backend está mal" |
| **Cuadrante** (§2.1) | Deliberada/inadvertida × prudente/imprudente: determina si se gestiona o se corta la causa |
| **Principal** | Estimación del trabajo de arreglarlo |
| **Interés observado** | La evidencia de §4.1, con dato: "toca 3 de cada 4 sprints", "4 incidentes en 6 meses" |
| **Consecuencia si no se paga** | Qué se degrada y para quién |
| **Dueño** | Persona nombrada, no un equipo genérico |
| **Disparador** | El evento que la convierte en trabajo planificado |
| **Fecha de revisión** | Cuándo se vuelve a mirar si sigue teniendo sentido |

Reglas:
- **Una deuda sin dueño ni fecha no existe**: se cierra o se borra. Un registro que solo crece es un cementerio y a los seis meses nadie lo abre.
- **El disparador es lo que evita el registro-cementerio**. Formas útiles: "cuando toquemos este módulo por tercera vez", "antes de añadir el segundo proveedor de pago", "cuando la versión X entre en EOL (fecha)", "si el tiempo de ciclo de esta área supera N".
- La deuda vive **en el mismo backlog** que el resto del trabajo y compite por prioridad con datos, no en un documento paralelo que ninguna planificación mira.
- **`TODO`/`FIXME` en el código no son un registro**: son notas. Si algo importa, se registra con dueño; si no, se borra. Un `TODO` de 2019 es una mentira firmada.
- **Deuda deliberada y prudente ⇒ se registra en el mismo PR que la contrae**, con su motivo. Ese es el único momento en que el contexto está fresco.

## 6. Estrategias a gran escala y financiación (operabilidad del cambio)

### 6.1 Estrategias, con atribución verificada

- **Strangler fig** — **Martin Fowler**, *"Strangler Application"*, **29-jun-2004**, **renombrado después a "Strangler Fig Application"** (el texto original se conserva en `OriginalStranglerFigApplication.html`). Metáfora tomada de las higueras estranguladoras de la selva de Queensland. Idea: hacer crecer el sistema nuevo **por los bordes** del viejo, desviando tráfico funcionalidad a funcionalidad hasta poder retirarlo. Requisitos: un punto de intercepción (fachada, proxy, enrutado) y **telemetría de uso** para saber cuándo lo viejo ya no se usa. **La retirada del código viejo es parte de la tarea**, no deuda futura.
- **Rama por abstracción** — **Paul Hammant** documentó y dio nombre al término en **2007** (acreditando la acuñación a **Stacy Curl**); Hammant es explícito en que **no lo inventó**, era práctica conocida sin nombre. **Jez Humble** y **Martin Fowler** lo divulgaron después con casos reales. **Atribuir el origen conjuntamente a Hammant y Humble es incorrecto.** Idea: introduce una abstracción sobre el proveedor actual, migra a los clientes para que solo hablen con ella, implementa el proveedor nuevo detrás, conmuta, y **elimina la abstracción si ya no aporta**. Es la alternativa a una rama larga: permite entregar mientras el cambio grande está a medias.
- **Expand/contract (parallel change)** — la referencia canónica es **Danilo Sato**, bliki *"ParallelChange"* en martinfowler.com, **13-may-2014**; el nombre "expand and contract" procede del mundo de la evolución de esquemas (*Refactoring Databases*, Scott Ambler y Pramod Sadalage). Tres fases: **expand** (añadir lo nuevo sin quitar lo viejo) → **migrate** (mover a todos los consumidores) → **contract** (retirar lo viejo).
  - **Para esquema de base de datos**: nunca renombrar ni borrar en la misma release que despliega el código; columna nueva, escritura doble, backfill, lectura de la nueva, y borrado de la vieja **en una release posterior** con el uso ya a cero.
  - **Para API**: lo nuevo convive con lo viejo, se mide el uso por consumidor y se retira con plazo comunicado (el gobierno del contrato es de `api-design-standards` / `microservices-architecture-standards`).
  - **La fase *contract* es obligatoria y hay que planificarla.** Un expand/contract que nunca contrae ha duplicado la deuda con permiso.

### 6.2 Por qué la reescritura completa es casi siempre la peor opción

Referencia clásica: **Joel Spolsky, "Things You Should Never Do, Part I", 6-abr-2000**, escrita a raíz de Netscape 6, a la que llama *"the single worst strategic mistake that any software company can make: They decided to rewrite the code from scratch"*. **Es un argumento, no un dato**: se cita por su razonamiento, no como evidencia empírica.

Razones que se sostienen:
- El código viejo contiene **años de correcciones de casos reales que no están documentados en ninguna otra parte**. La reescritura los pierde y los vuelve a descubrir en producción, uno a uno.
- Durante la reescritura hay **dos sistemas que mantener** y funcionalidad nueva congelada; el negocio rara vez aguanta esa congelación, así que la vieja sigue creciendo y la meta se aleja.
- El equipo nuevo suele **subestimar el dominio, no la tecnología**: lo difícil no era el framework.
- Es **big bang**: el riesgo se concentra en un único corte, sin retroalimentación intermedia y sin marcha atrás realista.

**Condiciones excepcionales en las que sí puede ser la opción correcta** (todas verificadas, y en ADR — `software-architecture-patterns-standards`):
- La plataforma base está **muerta o sin soporte** y no hay ruta de migración (runtime/lenguaje/proveedor descontinuado sin salida).
- El sistema es **pequeño y su comportamiento está especificado o es reproducible** (se puede caracterizar entero y comparar salidas en paralelo).
- **No hay nadie** que pueda modificarlo y no es viable adquirir el conocimiento (el código ya es una caja negra de facto).
- El requisito nuevo es **incompatible en su núcleo** con el modelo actual (p. ej. multi-tenancy o normativa que atraviesa todo el modelo de datos) y el coste de adaptar supera al de rehacer, **calculado**, no intuido.
- Aun así: hazlo **por partes con strangler fig y ejecución en paralelo comparando salidas**, no como corte único.

### 6.3 Cómo se financia el trabajo

Tres modelos; se combinan, no se eligen en exclusiva. La negociación y la planificación son de `project-management-standards`.

| Modelo | Cuándo | Riesgo |
|---|---|---|
| **Porcentaje fijo de capacidad** (p. ej. una fracción acordada de cada iteración) | **Default**. Deuda continua, previsible, no necesita justificarse caso a caso | Se evapora bajo presión si no está protegido; hay que hacerlo visible en la planificación, no invisible |
| **Oportunismo / boy scout rule** | Deuda local, en el código que ya vas a tocar. Coste marginal casi nulo | Solo escala a lo pequeño; si el arreglo desborda el PR, se registra y se planifica |
| **Proyecto dedicado** | Solo migraciones estructurales con principal grande e indivisible (cambio de motor, de plataforma, de modelo de datos) | Alto (ver abajo) |

- **Boy scout rule**: "deja el código mejor de como lo encontraste", **adaptada al software por Robert C. Martin** en *Clean Code* (2008) desde el lema del escultismo — **popularización y adaptación, no invención**: la formulación del campamento es muy anterior. Límite operativo: **la mejora oportunista no puede engordar el diff del cambio funcional** (choca con `code-review-standards`). Si no cabe en el mismo PR de forma revisable, va en un PR de refactor propio, antes o después.
- **Por qué el proyecto dedicado de "limpieza" suele fracasar**: no entrega valor visible durante meses, así que es el primero en cancelarse cuando aprieta el negocio; congela o duplica el trabajo del equipo de producto; se mide por trabajo hecho y no por interés eliminado, con lo que suele limpiar lo que es fácil en vez de lo que es caro; y termina siendo una reescritura encubierta con los riesgos de §6.2. **Si se hace: alcance cerrado, entregable incremental cada pocas semanas, criterio de éxito medible sobre el interés (§4.1) y fecha de fin.**
- **Regla de negociación honesta**: se argumenta con **interés**, no con moral. "Este módulo se toca en 3 de cada 4 iteraciones y cada cambio cuesta el doble que la media" convence; "el código está sucio" no, y con razón.

## 7. Deuda que no es de código, sostenibilidad y prohibiciones

La deuda no vive solo en el código. Estas categorías se registran igual (§5) y suelen tener **interés creciente y fecha dura**:

- **Dependencias sin actualizar**: el coste de saltar N versiones crece más rápido que lineal. Default: actualización continua y automatizada (bot de dependencias) con CI que la valide; el salto grande se evita, no se planifica. Los CVE y su triaje son de `vulnerability-management-standards`.
- **Versiones fuera de soporte (EOL)**: es la única deuda con **fecha conocida de antemano**; entra en el registro con el disparador puesto el día que se publica el calendario de fin de soporte, no el día que expira.
- **Cambio de licencia de una dependencia**: relicenciar aguas arriba (a *source-available* o copyleft fuerte) convierte una dependencia inocua en deuda con plazo. Detectarlo exige leer el `LICENSE` en crudo, no el README. Criterio legal: `opensource-licensing-standards`.
- **Infraestructura no reproducible**: servidores mascota, configuración manual, entornos que solo funcionan en una máquina. El interés se cobra entero el día del incidente.
- **Conocimiento en una sola cabeza**: es deuda con riesgo de impago total. Se amortiza con revisión cruzada, rotación, documentación del *porqué* y pairing sobre el módulo crítico.
- **Deuda de pruebas**: suite lenta (nadie la ejecuta), tests inestables (nadie se los cree), cobertura concentrada en lo trivial y ausente en lo crítico, tests acoplados a la implementación (impiden refactorizar — la peor de todas, porque **bloquea el pago del resto de la deuda**). El criterio de qué es un buen test es de `testing-qa-standards`.
- **Deuda de proceso y de datos**: despliegues manuales, ausencia de rollback probado, datos históricos con esquemas incompatibles.

### Lista de prohibiciones
- ❌ **PROHIBIDO llamar "deuda" a cualquier cosa**: sin principal, interés observable y consecuencia declarada, es una preferencia de estilo. Y el estilo lo resuelve el formatter, no el backlog.
- ❌ **PROHIBIDO refactorizar sin tests que cubran el comportamiento afectado.** Si no existen, se caracterizan primero (§3.2).
- ❌ **PROHIBIDO mezclar refactor y cambio funcional en el mismo commit** (y, salvo caso trivial, en el mismo PR): se revisan con criterios distintos y juntos son irrevisables.
- ❌ Etiquetar como "refactor" un cambio que altera el comportamiento observable.
- ❌ **Reescritura completa como respuesta por defecto**, o sin cumplir y documentar los criterios excepcionales de §6.2.
- ❌ **Medir la calidad por un único índice** (complejidad ciclomática, índice de mantenibilidad, cobertura, deuda en "días" de una herramienta) o convertirlo en objetivo de equipo.
- ❌ Usar el **índice de mantenibilidad** para decidir prioridades (§4.2).
- ❌ Priorizar deuda por antigüedad, por fealdad o por puntuación de herramienta en lugar de por interés medido.
- ❌ Refactorizar código estable que nadie toca "de paso" (riesgo sin retorno).
- ❌ Entradas de deuda **sin dueño, sin disparador o sin fecha de revisión**.
- ❌ `TODO`/`FIXME` sin issue asociado como sustituto del registro.
- ❌ Rama de refactor de larga vida en paralelo a la de desarrollo (usa rama por abstracción; ver `git-workflow-standards`).
- ❌ Expand/contract sin la fase **contract** planificada y ejecutada.
- ❌ Corregir un bug descubierto durante la caracterización dentro del mismo commit: se fija el comportamiento real y se corrige aparte.
- ❌ **Migrar a un patrón o arquitectura nueva sin tests: es cambiar una deuda por otra mayor** (recíproca de `software-architecture-patterns-standards`).
- ❌ Citar cifras de este dominio sin estudio primario y metodología (§8).

## 8. Verificación web obligatoria

Antes de fijar nada de este documento en un entregable real, **verifica con WebSearch/WebFetch** (los datos son de agosto de 2026):

1. **SonarQube**: licencia vigente del binario Community Build (LGPLv3 a la fecha) **y de los analizadores** (SSALv1 desde el 29-nov-2024) leída en `sonarsource.com/license/` y en el `LICENSE` en crudo del repositorio; qué queda fuera de Community Build (análisis de ramas, decoración de PR); **precios actuales confirmados con el proveedor** — las tablas de blogs de terceros son estimaciones y **se contradicen entre sí**. Igual para **Semgrep** (LGPL-2.1 el CLI; tarifas de la nube en disputa entre fuentes) y para **CodeScene** (comercial; su precio no aparece publicado con claridad).
2. **ArchUnit** y equivalentes por stack: versión y licencia desde el `LICENSE` en crudo, no desde agregadores (MvnRepository lista licencias mezcladas por dependencias empaquetadas).
3. **Estado de las críticas metodológicas** de §4.2 (Shepperd 1988; Jay et al. 2009; van Deursen 2014): comprobar si existe refutación posterior antes de apoyarse en ellas. A ago-2026 no la hay localizada.
4. **Bibliografía y atribuciones**: fecha y URL canónica de Fowler (*TechnicalDebtQuadrant*, *StranglerFigApplication*), Sato (*ParallelChange*), Hammant (*Branch by Abstraction*), Cunningham (OOPSLA '92) y edición vigente de Fowler *Refactoring* y Feathers *Working Effectively with Legacy Code*. **Una atribución incorrecta es un error de hecho.**
5. **EOL de las dependencias** que declares como deuda con fecha: `endoflife.date` y la fuente oficial del proyecto. `api.github.com` devuelve **403 sin autenticar**: para actividad de un repositorio, usa la web o el feed Atom de releases.

**Hueco declarado (sin presupuesto de investigación en esta redacción)** — pendiente de verificar antes de usarse:
- **Cifras de coste de la deuda técnica**: no se ha localizado un estudio primario con metodología sólida que permita afirmar un porcentaje de tiempo de desarrollo perdido por mala calidad. **Descartadas por falta de fuente primaria**: el "coste 10×/100× de arreglar un defecto por fase" (el rastro muere en notas internas de IBM de 1981 vía Pressman; documentado por Bossavit, *The Leprechauns of Software Engineering*) y el "80 % del coste del ciclo de vida es mantenimiento" (entró en la literatura como estimación informal citada en Lientz & Swanson, no como medición). **Discrepancia declarada**: el "hasta 42 % del tiempo de los desarrolladores desperdiciado" que circula ampliamente procede de encuestas de proveedor, no de medición; el estudio *Code Red* (Tornhill & Borg, TechDebt 2022, DOI `10.1145/3524843.3528091`) sí es revisado por pares y con paquete de replicación, pero **usa la métrica propietaria de la herramienta de uno de sus autores** — cítalo declarando ese conflicto de interés o no lo cites.
- **Umbrales concretos** de cualquier métrica (complejidad, tamaño, cobertura): no se fijan aquí a propósito; cualquier número que se adopte debe justificarse contra el propio código base, no copiarse.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
