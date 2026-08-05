---
name: software-architecture-patterns-standards
description: Standards for choosing and justifying an internal architecture style. Use when deciding modular monolith vs distributing, applying layered, hexagonal/ports-and-adapters, clean or onion architecture, event-driven, pipes-and-filters, plugin/microkernel or space-based styles, drawing module boundaries and dependency rules, bounded contexts and ubiquitous language, CQRS and event sourcing, ADRs (Nygard/MADR templates), C4 model diagrams and Structurizr DSL, ArchUnit or dependency-cruiser fitness functions, ISO/IEC 25010 quality attributes and quality-attribute scenarios, or diagnosing big ball of mud, anemic domain model, shared database and excessive-layering antipatterns.
---

# Estándares de patrones y arquitectura de software

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Cubre el **diseño interno de un sistema**: elección de estilo arquitectónico, límites de módulo, reglas de dependencia, modelado de dominio, patrones de datos y consistencia dentro del despliegue, documentación de decisiones (ADR), notación (C4), atributos de calidad y su verificación automática (fitness functions). Triggers: "monolito modular", "hexagonal", "puertos y adaptadores", "clean architecture", "onion", "capas", "event-driven", "pipes and filters", "plugin/microkernel", "space-based", "bounded context", "lenguaje ubicuo", "CQRS", "event sourcing", "regla de dependencia", "acoplamiento/cohesión", "ADR", "C4", "ArchUnit", "fitness function", "ISO 25010", "big ball of mud".

**Principio rector — un patrón es la respuesta a una fuerza concreta.** Antes de nombrar un patrón hay que nombrar la fuerza que lo justifica (un atributo de calidad medible, un eje de cambio previsto, una restricción de negocio o normativa). **Un patrón aplicado sin esa fuerza no es arquitectura: es complejidad accidental**, y se paga en cada cambio futuro. Corolario operativo: en el ADR (§6) la sección que decide no es "decisión", es "fuerza y consecuencias".

**No aplica**:
- `microservices-architecture-standards` (**frontera crítica**): **suya** toda la topología distribuida — corte en servicios desplegables por separado, comunicación entre procesos por red (REST/gRPC/eventos), contratos entre servicios y su gobierno, **saga y outbox en su ejecución**, base de datos por servicio como regla operativa, resiliencia distribuida (timeouts, circuit breaker, backpressure, DLQ), mTLS, API gateway y service mesh, trazado distribuido. **Aquí** el diseño interno de un despliegue y **la decisión previa de si hace falta distribuir**, más el criterio de negocio sobre consistencia eventual. Regla de arbitraje: **si la pregunta es cómo se comunican dos procesos separados por la red, es suya; si es cómo se estructura el código dentro de un despliegue, es de aquí.**
- `api-design-standards` (el **contrato hacia fuera**: recursos, verbos, códigos, paginación, versionado del contrato).
- `data-platform-standards` y `sql-standards` (modelado físico, motor, índices, migraciones, tuning).
- `enterprise-architecture-standards` (**Ola 6, en curso**; frontera fina: **suyo** el paisaje de aplicaciones de la organización, la gobernanza, el inventario y los estándares transversales; **aquí** el diseño de **un** sistema).
- `tech-leadership-standards` (**Ola 6, en curso**: la decisión de invertir, el registro y la negociación; aquí el criterio técnico).
- `refactoring-tech-debt-standards` (**el camino**: cómo se llega desde el diseño actual al que decide esta skill; aquí el destino).
- `privacy-engineering-standards` (**suyo** el criterio sobre derecho de supresión frente a un log inmutable, base legal, minimización; aquí solo la consecuencia arquitectónica de elegir event sourcing).
- `performance-engineering-standards` (medición, presupuestos y optimización), `sre-practice-standards` (SLO, error budget, operación), `testing-qa-standards` (estrategia de prueba), y las **skills de lenguaje** (cómo se implementa el patrón en cada stack).

## 2. Decisiones por defecto

> Verificar la última versión/estado por web antes de fijarlo en un proyecto real (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| Topología | **Monolito modular** (un despliegue, módulos con límites duros) | Distribuir solo con fuerza demostrada → `microservices-architecture-standards` |
| Estilo interno | **Puertos y adaptadores** (dominio sin dependencias a tecnología) | Capas simples en CRUD sin lógica de dominio; *pipes and filters* en transformación de datos; plugin/microkernel si la variabilidad es la fuerza dominante |
| Límite de módulo | **Por dominio de negocio** (vertical) | Nunca por capa técnica como límite de primer nivel |
| Modelo de dominio | **Contexto delimitado + lenguaje ubicuo** (DDD estratégico) | DDD táctico solo donde hay invariantes reales (§4) |
| Lectura/escritura | Un único modelo | **CQRS** solo con asimetría medida de carga o de forma del modelo |
| Persistencia | Estado actual en BD relacional | **Event sourcing** solo con requisito real de auditoría/temporalidad y ADR de versionado + borrado (§5) |
| Decisiones | **ADR obligatorio** para toda decisión *one-way* (plantilla Nygard o MADR) | — |
| Notación | **C4 model** (Simon Brown; sitio y diagramas de ejemplo bajo **CC BY 4.0**) | UML donde el equipo ya lo domina |
| Diagramas | **Modelo como código** (Structurizr DSL, o PlantUML/Mermaid en repo) | Herramienta gráfica solo si se regenera desde fuente |
| Atributos de calidad | **ISO/IEC 25010:2023** (2.ª ed., 15-nov-2023) como checklist | — |
| Verificación | **Fitness functions en CI** (ArchUnit — Apache-2.0 — en JVM; equivalente por stack) | — |

### 2.1 La decisión previa: monolito modular por defecto

Es la decisión más importante y la más barata de acertar. **Default: un despliegue, módulos con límites explícitos y verificados en CI.** No es "monolito por pereza": es la topología que conserva la opción de distribuir después (extrayendo un módulo ya aislado) sin pagar hoy latencia de red, consistencia eventual, fallos parciales y coste operativo ×N.

Fuerzas que **sí** justifican salir del monolito modular (documentadas en ADR; el diseño resultante lo gobierna `microservices-architecture-standards`):
- **Organizativa**: varios equipos que necesitan desplegar con cadencias distintas y colisionan en el mismo repo/release.
- **Escala o aislamiento de fallo divergente** entre dominios, **medido** (no supuesto): un dominio necesita otra curva de recursos o no puede caer con el resto.
- **Cumplimiento o ciclo de vida**: un dominio exige aislamiento de datos, de despliegue o de auditoría por norma.
- **Heterogeneidad tecnológica obligada** (un dominio requiere un runtime que no cabe en el proceso principal).

Fuerzas que **no** lo justifican: "está de moda", "escalará algún día", "así el código queda limpio", "queremos usar Kubernetes". Un monolito mal modularizado no mejora al distribuirlo: se convierte en monolito distribuido, con los mismos acoplamientos y latencia de red encima.

**Ley de Conway** (Melvin E. Conway, *"How Do Committees Invent?"*, **Datamation 14(5):28–31, abril 1968**; el nombre "Conway's law" es posterior — atribuido a Fred Brooks en *The Mythical Man-Month*, con reclamación previa de George Mealy en 1968): las organizaciones producen diseños que **copian su estructura de comunicación**. Consecuencia práctica: la arquitectura elegida y el organigrama tienen que ser coherentes; si no puedes cambiar los equipos, tu margen real de diseño es menor de lo que crees. **Matiz honesto**: el enunciado original es de correspondencia, no de causalidad — no afirma que la comunicación *cause* la estructura.

## 3. Estilos y su criterio de elección

No hay estilo "mejor": hay estilo que atiende la fuerza dominante. Elige uno como base y aplica los demás como patrones locales.

| Estilo | Fuerza que atiende | Coste que impone | Prohibido cuando |
|---|---|---|---|
| **Capas** | Orden mínimo, incorporación rápida | Límites técnicos, no de dominio; tiende a bola de barro con lasaña encima | Hay lógica de dominio rica y varios ejes de cambio |
| **Puertos y adaptadores / clean / onion** | Aislar el dominio de la tecnología; testabilidad sin infra | Indirección y mapeo entre modelos | El "dominio" es CRUD puro (indirección sin beneficio) |
| **Basada en eventos** | Desacoplo temporal, extensibilidad, reacción asíncrona | Flujo no lineal, depuración y orden difíciles, consistencia eventual | El caso de uso exige respuesta inmediata y transaccional |
| **Pipes and filters** | Transformación de datos por etapas, reusabilidad de etapas | Estado compartido difícil; latencia acumulada | El proceso necesita decidir con contexto global |
| **Plugin / microkernel** | Variabilidad conocida: mismo núcleo, muchas variantes | Contrato de extensión que hay que versionar y sostener | No hay variantes reales todavía (abstracción especulativa) |
| **Space-based** | Escalado extremo con contención en la base de datos | Complejidad de replicación/consistencia en memoria muy alta | La contención no está medida |

### 3.1 Hexagonal, clean y onion: la honestidad que toca

- **Puertos y adaptadores (hexagonal)**: **Alistair Cockburn** (documentada en el wiki de Portland; nombre "Ports and Adapters" adoptado hacia 2005; libro *Hexagonal Architecture Explained*, con Juan Manuel Garrido de Paz). El hexágono no significa "seis": se eligió para poder dibujar varios puertos sin la falsa linealidad de las capas.
- **Onion**: **Jeffrey Palermo** (2008). **Clean**: **Robert C. Martin** (2012; libro *Clean Architecture*, 2017).
- **En gran medida son la misma idea con nombres distintos**: dominio en el centro, tecnología en el borde y **todas las dependencias de código fuente apuntando hacia dentro**. El propio Cockburn lo dice en *Hexagonal Architecture Explained*: onion y clean tienen la misma estructura de dependencias que puertos y adaptadores, con dos diferencias — **no exigen especificar puertos** y **añaden capas que puertos y adaptadores no impone**.
- **Criterio**: elige **una** nomenclatura por sistema y escríbela en el ADR. Discutir cuál de las tres es "la buena" no produce ningún atributo de calidad. Lo que sí importa y es verificable en CI: **el dominio no nombra ninguna tecnología**.

### 3.2 La regla de dependencia y su implicación práctica

Las dependencias de código apuntan **hacia el dominio**; cuando la llamada va en el sentido contrario, se invierte con una interfaz **declarada por el dominio** e implementada por el adaptador. Implicaciones que sí se notan:
- El dominio **no importa** el ORM, el cliente HTTP, el framework web ni el SDK del proveedor cloud. Si tu entidad de dominio lleva anotaciones de persistencia, no tienes esta arquitectura: tienes capas con nombre bonito.
- Los tipos del dominio **no cruzan** hacia fuera sin traducción; el adaptador mapea. El coste del mapeo es el precio de la regla — si no estás dispuesto a pagarlo, elige capas y dilo.
- **La regla se verifica en CI o no existe** (§4). Una regla de dependencia sostenida solo por revisión humana se erosiona en meses.

### 3.3 Módulos: acoplamiento, cohesión y qué oculta cada módulo

- **Límites por dominio, no por capa técnica**. Un módulo `pedidos` que contiene su propio controlador, dominio y persistencia es un límite; un módulo `repositorios` que contiene los repositorios de los ocho dominios no lo es.
- **Un módulo se define por lo que oculta**, no por lo que agrupa: **David L. Parnas**, *"On the Criteria To Be Used in Decomposing Systems into Modules"*, **CACM 15(12):1053–1058, dic. 1972** — descomponer por **decisiones de diseño difíciles o susceptibles de cambiar**, ocultando cada una tras un módulo, y **no** por el diagrama de flujo de datos. Criterio de bolsillo: si un cambio previsible obliga a tocar varios módulos, el límite está mal puesto.
- **Vocabulario preciso de acoplamiento**: la taxonomía publicada reciente es la de **Vlad Khononov**, *Balancing Coupling in Software Design* (Addison-Wesley, **2024**; material asociado en `coupling.dev`), que sintetiza el *structured design* de los 70 y la *connascence* de los 90 en tres dimensiones:
  - **Integration strength** (cuánto conocimiento se comparte a través del límite), con cuatro niveles de mayor a menor: **intrusive → functional → model → contract**. *Intrusive* es integrarse por los detalles internos del otro (leer su tabla, tocar su privado).
  - **Distance** (esfuerzo de cambiar ambos lados: misma clase < mismo módulo < mismo despliegue < otro servicio/equipo).
  - **Volatility** (con qué frecuencia se espera que eso cambie).
  - Regla: **cuanto mayor la distancia, menor debe ser el conocimiento compartido** — por eso la coupling intrusiva entre servicios es catastrófica y entre dos clases del mismo módulo puede ser irrelevante. El acoplamiento fuerte no es un pecado en sí; lo es cuando coincide con distancia grande **y** volatilidad alta.
- **Cohesión**: lo que cambia junto vive junto. Si dos módulos aparecen siempre en el mismo commit, o son uno o el límite está donde no toca (señal medible: acoplamiento por cambio en el historial de Git, §4).

### 3.4 DDD: lo que de verdad aporta

- **Aporta el estratégico**: **contexto delimitado** (dentro de él un término significa una sola cosa) y **lenguaje ubicuo** (el mismo vocabulario en conversación, código y tests). Es la mejor herramienta disponible para **decidir dónde va el límite** — y el límite es la decisión que más caro sale corregir.
- **Aviso honesto**: **el DDD táctico se aplica mal más veces de las que se aplica bien**. Agregados, entidades, objetos valor, repositorios y servicios de dominio son útiles **donde hay invariantes de negocio que proteger**; aplicados a un CRUD producen ceremonia sin beneficio y un modelo anémico con nombres de DDD.
- Criterio: aplica táctico **por subdominio**, y solo en el **núcleo** (el que da ventaja competitiva). En subdominios de soporte y genéricos: lo más simple que funcione, o comprar en vez de construir.
- El modelo anémico (**Martin Fowler, bliki, 25-nov-2003**, discutido con Eric Evans) no es un fallo si lo has elegido: es un *transaction script*. Es un fallo cuando pretendes que es DDD.

## 4. Verificación: atributos de calidad y fitness functions

**El input real del diseño son los atributos de calidad, no los patrones.** Un requisito no funcional sin escenario no es verificable y por tanto no restringe el diseño.

- **Catálogo de referencia: ISO/IEC 25010:2023** (2.ª edición, publicada **15-nov-2023**, ISO/IEC JTC 1/SC 7), **nueve características**. Cambios frente a 2011 que hay que conocer: se **añade Safety**; **Usability → Interaction capability** y **Portability → Flexibility**; el resto del modelo antiguo se repartió a **ISO/IEC 25002** (visión general de modelos) y **ISO/IEC 25019** (calidad en uso). Usar "ISO 25010" citando las características de 2011 es un error de hecho.
- **Escenario de atributo de calidad** (formato mínimo, estilo ATAM/SEI): *fuente → estímulo → artefacto → entorno → respuesta → **medida de respuesta***. Sin la medida de respuesta no hay escenario, hay deseo. Ejemplo: "ante 3× el pico habitual (estímulo) en horario comercial (entorno), el listado responde por debajo de 300 ms p95 (medida)".
- **Fitness functions**: término introducido en ***Building Evolutionary Architectures*** (Neal Ford, Rebecca Parsons, Patrick Kua; O'Reilly **2017**; 2.ª ed. **2023** con Pramod Sadalage). Definición de la 2.ª edición: *"any mechanism that provides an objective integrity assessment of some architecture characteristic or combination of characteristics"*. Categorías útiles: **atómica vs holística**, **disparada vs continua**.
- Fitness functions **mínimas** que deben romper el build:
  - **Reglas de dependencia entre módulos y capas** (ArchUnit en JVM — Apache-2.0; equivalentes por stack: dependency-cruiser, import-linter, deptrac, `go list`/`depguard`, `cargo-deny`). Sin esto, la arquitectura documentada y la real divergen.
  - **Ausencia de ciclos** entre módulos.
  - **Prohibición de importar tecnología desde el dominio** (paquetes vetados).
  - Presupuestos de rendimiento y de tamaño donde el atributo lo exija (delegar el método a `performance-engineering-standards`).
- Tests: el dominio se prueba **sin infraestructura** (esa es la razón práctica de puertos y adaptadores); los adaptadores se prueban contra la tecnología real (contenedores efímeros). La estrategia completa es de `testing-qa-standards`.
- **Señal de erosión**: acoplamiento por cambio en el historial (ficheros de módulos distintos que cambian siempre juntos). Es evidencia, no opinión — cruzarla con el criterio de deuda de `refactoring-tech-debt-standards`.

## 5. Datos, consistencia y decisiones caras

### CQRS
- **Qué resuelve de verdad**: la asimetría entre el modelo que necesita **proteger invariantes al escribir** y el que necesita **servir consultas** con otra forma, otra carga u otro SLA. Linaje: **CQS** de **Bertrand Meyer** (*Object-Oriented Software Construction*, 1988) a nivel de método; **CQRS** lo eleva a nivel arquitectónico y es de **Greg Young** (promovido también por Udi Dahan; documento "CQRS Documents" de 2010).
- **Qué cuesta**: dos modelos que mantener y **consistencia eventual visible por el usuario** si las proyecciones son asíncronas. El propio Fowler advierte que en la mayoría de sistemas CQRS añade complejidad arriesgada.
- **Criterio**: aplícalo **por contexto delimitado**, nunca "en todo el sistema". Sin asimetría medida, no se aplica. CQRS **no implica** dos bases de datos ni event sourcing.

### Event sourcing — decisión casi irreversible
Guarda todo cambio de estado como una secuencia de eventos y reconstruye el estado reproduciéndolos (**Martin Fowler**, *Event Sourcing*, **12-dic-2005**; el propio Fowler marca ese material como borrador). Resuelve auditoría íntegra, consulta del estado en cualquier instante y reproyección hacia modelos nuevos.

**Es casi irreversible porque el log es el sistema.** Antes de adoptarlo, el ADR debe responder, con diseño, a las tres:
1. **Versionado de eventos**: el esquema cambiará. Estrategia decidida de entrada (upcasting en lectura, eventos versionados, copia-y-transforma del stream) y **prohibido** cambiar el significado de un evento ya publicado.
2. **Reproyección**: coste y tiempo de reconstruir todas las proyecciones desde cero con el volumen previsto **a 3 años**, y snapshots si no cabe en la ventana operativa.
3. **Borrado de datos personales frente a un log inmutable**: el derecho de supresión choca de frente con un log que por diseño no se borra. Técnica arquitectónica habitual: **crypto-shredding** (cifrar los datos del sujeto con clave por sujeto y destruir la clave), o mantener los datos personales **fuera del log** y referenciarlos por identificador. **El criterio jurídico y de suficiencia es de `privacy-engineering-standards`**: aquí solo se fija que **sin esa respuesta escrita no se adopta event sourcing**.

Si lo que necesitas es "saber quién cambió qué", casi siempre basta una tabla de auditoría o CDC: mucho más barato y reversible.

### Consistencia y patrones de datos
- **Dentro de un despliegue**: transacción de base de datos. No inventes consistencia eventual donde ACID local resuelve — es la forma más común de complejidad accidental.
- **Base de datos por servicio, saga y outbox**: su **ejecución** es de `microservices-architecture-standards`. Lo que se decide **aquí** es lo previo: **si el negocio tolera consistencia eventual**, y eso no lo decide el arquitecto solo.
- **Cuándo es aceptable la consistencia eventual** (criterio de negocio, con dueño de producto en el ADR): la ventana de inconsistencia es **acotada y comunicable**; existe **compensación de negocio** posible (cancelar, reembolsar, reintentar) y alguien la ha aceptado por escrito; la UX muestra el estado intermedio en vez de mentir ("en proceso", no "hecho"); y ningún requisito legal o de seguridad exige lectura consistente (saldo, control de acceso, stock con sobreventa penalizada).
- **Cuándo no lo es**: invariantes de dinero o de seguridad que se romperían durante la ventana, y flujos donde la compensación no existe en el mundo real (correo enviado, mercancía embarcada).

## 6. Decisiones y documentación (§6 sustituida: aquí "rendimiento y operabilidad" resultaría artificial — el rendimiento se trata como atributo de calidad en §4 y su método pertenece a `performance-engineering-standards`)

- **ADR obligatorio** para toda decisión *one-way*: topología, estilo base, límites de contexto, persistencia (event sourcing, motor), formato de contratos internos, adopción de una plataforma difícil de abandonar. Origen del formato: **Michael Nygard, "Documenting Architecture Decisions", 15-nov-2011** (Cognitect), con linaje en la *decision view* de Philippe Kruchten. Plantilla Nygard: **título, estado, contexto, decisión, consecuencias**; **MADR** añade *decision drivers* y *considered options* (MADR 3.x; en 3.0.0-beta se renombró a "Markdown **Any** Decision Records").
- **ADR versionado junto al código**, revisado en PR, **inmutable una vez aceptado**: no se edita, se **supersede** con otro ADR. Estados mínimos: propuesta → aceptada → deprecada/superseded.
- **Puertas de un solo sentido vs reversibles**: las reversibles se deciden rápido, al nivel más bajo posible y sin ceremonia; las irreversibles piden ADR, alternativas y una estimación explícita de coste de salida. **Clasificar mal una puerta es el error caro**: tratar una irreversible como reversible se paga años; lo contrario paraliza al equipo.
- **Notación por defecto: C4 model** (creado por **Simon Brown**; el sitio y los diagramas de ejemplo están bajo **Creative Commons Attribution 4.0 International**). Cuatro niveles: **System Context, Container, Component, Code**. En la práctica: mantén **contexto y contenedores** siempre; **componentes** solo donde aporte; **código** casi nunca (lo genera el IDE mejor que tú).
- **El diagrama que se desactualiza solo no debe existir.** Un diagrama es válido si (a) se genera desde el código o desde un modelo versionado (Structurizr DSL, PlantUML, Mermaid en repo), o (b) tiene **dueño nombrado y fecha de revisión**. Si no cumple ninguna, bórralo: un diagrama falso es peor que ninguno porque se usa para decidir.
- Documenta el **porqué**, no el cómo: el cómo lo cuenta el código; el porqué se pierde en cuanto se va la persona que lo sabía.

## 7. Sostenibilidad, antipatrones y prohibiciones

**Evolución**: la arquitectura se juzga por cuánto facilita el próximo cambio, no por su elegancia. Revisa límites cuando aparezcan las señales de erosión (§4) y aplica el camino de `refactoring-tech-debt-standards`.

Antipatrones, con la consecuencia que provocan:
- **Gran bola de barro** (*Big Ball of Mud*, **Brian Foote y Joseph Yoder, PLoP '97**, sept. 1997; también cap. 29 de *PLoPD 4*): estructura dictada por la conveniencia, no por diseño. Consecuencia: coste de cambio impredecible y conocimiento concentrado en pocas personas.
- **Arquitectura de lasaña / capas en exceso**: capas que solo delegan (métodos y clases *pass-through*). Consecuencia: cada cambio toca N ficheros sin añadir valor. Variante conocida: *architecture sinkhole*, peticiones que atraviesan todas las capas sin lógica.
- **Servicio/dominio anémico**: entidades sin comportamiento y lógica dispersa en servicios. Consecuencia: invariantes sin dueño, duplicadas y divergentes. Distribuido, se multiplica.
- **Base de datos compartida** entre módulos o servicios: el esquema se convierte en el contrato real y nadie puede cambiarlo. Consecuencia: acoplamiento *intrusive* a distancia máxima (§3.3), el peor cuadrante posible.
- **`Enterprise`/`Manager`/`Helper`/`Util` en el nombre**: nombre que no revela responsabilidad. Consecuencia: cajón de sastre, cohesión cero, imposible de dividir después.
- **Monolito distribuido**: módulos que se despliegan y versionan juntos, pero por la red. Consecuencia: todos los costes de distribuir, ninguna de sus ventajas.

### Lista de prohibiciones
- ❌ **PROHIBIDO aplicar un patrón sin nombrar la fuerza concreta que lo justifica** en el ADR (atributo de calidad, eje de cambio, restricción legal).
- ❌ Microservicios por defecto, o sin ADR que compare con el monolito modular (§2.1).
- ❌ **Event sourcing sin plan escrito de versionado de eventos, de reproyección y de borrado de datos personales.**
- ❌ CQRS "en todo el sistema" o sin asimetría medida entre lectura y escritura.
- ❌ Abstracción especulativa: interfaz con una sola implementación "por si acaso", plugin sin plugins, capa de portabilidad para una base de datos que nunca se cambiará.
- ❌ Límites de primer nivel por capa técnica (`controllers/`, `services/`, `repositories/` como estructura de dominio).
- ❌ Dominio que importa framework, ORM, SDK cloud o cliente HTTP.
- ❌ Reglas de dependencia no verificadas en CI (documentación sin fitness function = ficción).
- ❌ **Diagrama sin dueño ni fecha de revisión, o no generado desde fuente versionada.**
- ❌ ADR editado tras ser aceptado (se supersede, no se reescribe) o decisión *one-way* sin ADR.
- ❌ Consistencia eventual introducida sin que negocio/producto la acepte por escrito y sin compensación definida.
- ❌ Transacción distribuida (2PC/XA) usada para tapar un límite mal cortado.
- ❌ Citar "ISO 25010" con las características de la edición 2011 (§4).
- ❌ Migrar a un patrón nuevo sin tests que cubran el comportamiento: **es cambiar una deuda por otra mayor** (ver `refactoring-tech-debt-standards`).

## 8. Verificación web obligatoria

Antes de fijar nada de este documento en un entregable real, **verifica con WebSearch/WebFetch** (los datos son de agosto de 2026):

1. **ISO/IEC 25010**: ¿sigue vigente la 2.ª ed. de 2023? ¿Estado de ISO/IEC 25002 y 25019? Las características exactas se citan de la norma comprada, no de blogs (las webs divergen al listarlas).
2. **C4 model**: licencia vigente del sitio y de los materiales (CC BY 4.0 a fecha de verificación), estado de Structurizr (DSL, versiones on-premises/cloud y su modelo de precio).
3. **ArchUnit** y el equivalente de tu stack: última versión, licencia leída del `LICENSE` en crudo (no del README ni de agregadores) y compatibilidad con la versión del lenguaje.
4. **MADR / adr-tools**: versión vigente de la plantilla y mantenimiento real del repositorio (último commit), no la estrella de GitHub. `api.github.com` devuelve 403 sin autenticar: usa la web o los feeds Atom de releases.
5. **Bibliografía citada**: ediciones vigentes de *Fundamentals of Software Architecture* (2.ª ed., abr-2025), *Building Evolutionary Architectures* (2.ª ed., 2023) y *Balancing Coupling in Software Design* (2024) antes de atribuir un término a una edición concreta.
6. **Cifras**: este dominio arrastra folclore. **No se escribe ninguna cifra sin estudio primario localizable y metodología**. Ya descartadas aquí por falta de fuente primaria: el "coste 10×/100× por fase" (rastro muerto en notas internas de IBM de 1981 vía Pressman; documentado por Bossavit, *The Leprechauns of Software Engineering*) y el "80 % del coste es mantenimiento" (entró en la literatura como estimación informal citada por Lientz & Swanson, no como medición).
7. **Frontera con `microservices-architecture-standards`**: si esa skill cambia de alcance, re-verifica la regla de arbitraje de §1 en ambas direcciones.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
