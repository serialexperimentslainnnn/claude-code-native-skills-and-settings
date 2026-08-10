---
name: platform-engineering-standards
description: An internal platform is a product whose customers can refuse to use it. Use when deciding whether to build an internal developer platform at all, defining a golden path and its documented escape hatch, writing catalog-info.yaml or app-config.yaml, running or upgrading Backstage and its scaffolder software templates (template.yaml, the new frontend system, plugin migration), evaluating Port blueprints, Cortex, Humanitec Platform Orchestrator or a Backstage distribution, designing service catalog metadata and ownership, versioning the platform API as a contract, choosing between Crossplane (CompositeResourceDefinition, Composition, composition functions, namespaced XRs in v2) and reusable infrastructure modules or an operator, adopting Score (score.yaml) as a workload spec, building self-service with guardrails through admission policy, quotas and ephemeral environments, setting platform SLOs and a deprecation policy for a platform capability, measuring adoption by time-to-first-deploy and toil reduction instead of registered users, reducing team cognitive load in the Team Topologies sense, or citing DORA findings on internal developer platforms.
---

# Estándares de ingeniería de plataforma

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Una plataforma interna es un producto con clientes internos que pueden no usarla.** De ahí se
deriva todo lo demás: tiene dueño, hoja de ruta, versiones, soporte, documentación, deprecación y
una métrica de adopción que puede salir mal. Si el equipo la esquiva —despliega por su cuenta,
copia el módulo y lo modifica, abre un ticket para saltársela— **la plataforma ha fallado**, y el
fallo es de la plataforma, no del equipo.

Corolario que gobierna el resto del documento: **la adopción forzada oculta el fallo en vez de
arreglarlo.** Obligar por decreto elimina la única señal fiable que la plataforma tenía —la
deserción— y sustituye la pregunta *"¿por qué no la usan?"* por *"¿quién la está incumpliendo?"*.
La plataforma sigue siendo mala y ahora nadie lo puede medir. Esto **no** es un argumento contra
los controles obligatorios: hay controles que sí son obligatorios (política de seguridad, gates de
cumplimiento). Lo que no puede ser obligatorio es **la conveniencia**: el camino pavimentado se
impone porque es el más rápido, no porque esté prohibido el otro.

Cubre: la decisión de construirla o no, la diferencia operativa con DevOps y con SRE, el camino
pavimentado y su salida documentada, el portal y el catálogo de servicios, las plantillas de
creación de servicio, la API de la plataforma como contrato versionado, las abstracciones de
infraestructura (Crossplane y operadores frente a módulos), el autoservicio con barandillas
(admisión, cuotas, entornos efímeros), la plataforma como producto (dueño, hoja de ruta, métricas,
soporte, deprecación), DORA como medida de resultado y la carga cognitiva como fundamento teórico.

**No aplica**: ver `sre-practice-standards` (**SLO, guardias, *error budget* y fiabilidad del
servicio son suyos**; **la plataforma también tiene SLO y se le aplican tal cual** —§6.1—: es un
servicio en producción cuyo fallo bloquea a todos los equipos a la vez), `cicd-standards` (**la
pipeline concreta es suya**: jobs, runners, OIDC, firma, SLSA; aquí solo **que exista una plantilla
de pipeline en el camino pavimentado, quién la mantiene y cómo se actualiza en los repos que ya la
usan**), `kubernetes-standards` e `iac-standards` (**el sustrato**: cómo se escribe un manifiesto,
un módulo o un estado; **aquí la abstracción que se ofrece encima, qué se oculta y qué se deja
pasar**), `observability-standards` (la plataforma de telemetría, sus SLI y su instrumentación;
**aquí solo que el camino pavimentado la traiga de serie y sin trabajo del equipo**),
`identity-access-management-standards` (federación, RBAC, ciclo de vida de identidad; aquí la
identidad **de la plataforma** como sujeto privilegiado —§5), `secrets-management-standards`
(gestión, rotación y consumo de secretos; aquí que la plantilla no obligue a nadie a pegar uno),
`container-runtime-security-standards` (aislamiento y detección en tiempo de ejecución de lo que la
plataforma despliega), `api-design-standards` (**el contrato de la API de la plataforma se diseña
con sus reglas**: versionado, errores, paginación, compatibilidad; aquí solo la obligación de que
esa API *exista* y sea un contrato), `developer-workstation-standards` (la
máquina del desarrollador, sus dotfiles y su entorno local; **aquí lo que corre del lado del
servidor**; el punto de encuentro es el entorno de desarrollo reproducible, que se decide allí),
`testing-qa-standards` y `code-review-standards` (estrategia de prueba y control de calidad del
diff; **la plataforma las aplica a su propio código como cualquier producto, no las redefine**),
`tech-leadership-standards`, `enterprise-architecture-standards`, `itsm-itil-standards`,
`knowledge-management-standards` y `product-discovery-standards` (gobierno,
arquitectura de empresa, gestión de servicio y conocimiento; **la plataforma es un producto y su
descubrimiento de necesidades se rige por `product-discovery-standards`** — aquí no se reinventa
cómo se entrevista a un usuario), `microservices-architecture-standards` (descomposición en
servicios y topología del sistema; **la plataforma no decide cuántos servicios debe haber, solo
abarata crear y operar cada uno**), `finops-standards` (**recíproca: el coste de la plataforma es
una unidad económica más y se mide con su método**; y **la plataforma es donde se implantan los
gates de etiquetado** que esa skill define).

## 2. Decisiones por defecto

> Verificar la última versión y el estado de los proyectos citados por web antes de fijar nada (§8).

| Ámbito | Default | Alternativa justificable |
|---|---|---|
| ¿Construir plataforma? | **No, hasta que se cumpla el umbral de §3.1** | Sí, con dueño nombrado y presupuesto permanente |
| Ámbito inicial | **Un camino pavimentado, para el caso más repetido** | Varios, solo si son de verdad distintos |
| Interfaz primaria | **Git + la pipeline existente** (el desarrollador ya vive ahí) | Portal web si hay que agregar información dispersa (§3.5) |
| Portal | **Backstage** (Apache-2.0, CNCF *Incubating*) si se autohospeda | Producto comercial (Port, Cortex, Humanitec) si no hay equipo para mantener el portal como software propio (§2.1) |
| Contrato de despliegue | **API versionada de la plataforma** (declarativa, en Git) | `Score` (`score.yaml`, CNCF *Sandbox*) si se necesita una especificación de carga portable entre destinos |
| Abstracción de infraestructura | **Módulos reutilizables de IaC** para el 80 % de los casos | **Crossplane** cuando se necesita reconciliación continua y una API de Kubernetes propia (§3.7) |
| Barandillas | **Política como código en admisión** + cuotas | Revisión humana solo donde la política no puede expresarse |
| Entornos efímeros | **Por defecto, con TTL y destrucción automática** | Entornos permanentes por equipo si el coste de arranque es prohibitivo |
| Métrica principal de éxito | **Tiempo hasta el primer despliegue en producción de un servicio nuevo** + **reducción de *toil*** | — |
| Adopción | **Voluntaria y ganada** | Obligatoria **solo** para controles de seguridad y cumplimiento, nunca para la conveniencia (§1) |

### 2.1 Estado, licencia y gobernanza de las piezas (verificado)

| Pieza | Licencia (`LICENSE` en crudo) | Estado / gobernanza | Nota de decisión |
|---|---|---|---|
| **Backstage** | **Apache-2.0** (`backstage/backstage`) | **CNCF**: aceptado el **8-sep-2020**, **Incubating desde el 15-mar-2022**; **sigue sin graduarse** a ago-2026. Creado en Spotify (2016), abierto en 2020 | Es un **framework**, no un producto instalable: se compila una aplicación propia. Ese es su mayor coste y la razón nº 1 de abandono |
| **Crossplane** | **Apache-2.0** (`crossplane/crossplane`) | **CNCF Graduated desde el 28-oct-2025** (aceptado 25-jun-2020, incubating 14-sep-2021). Línea actual **v2.x** | **v2 cambió la arquitectura** (§3.7): no asumir documentación de v1 |
| **Score** | Especificación abierta (`score.dev`) | **CNCF Sandbox** desde el **8-jul-2024**; no consta promoción a incubación a ago-2026. Origen: Humanitec | Sandbox = madurez baja. Adoptar solo con la implantación de referencia probada |
| **Port** | Producto comercial (SaaS) | Empresa privada | Precio y términos por proveedor: no fijar de memoria (§8) |
| **Cortex** (`cortex.io`) | Producto comercial (SaaS) | Empresa privada | **Colisión de nombre, trampa real**: en el catálogo de la CNCF, `Cortex` es el proyecto de métricas escalables de Prometheus, **no** este portal. No confundir el estado de madurez de uno con el del otro |
| **Humanitec** | Producto comercial (Platform Orchestrator, Portal) | Empresa privada, con sede en Berlín; **no consta adquisición** a ago-2026, pese a rumores recurrentes | Verificar antes de fijarla como dependencia estratégica |

**Política de versiones de Backstage, verbatim de su documentación** (importa porque determina el
esfuerzo de mantenimiento, que es el coste real): línea principal *"Monthly, specifically on the
Tuesday before the third Wednesday of each month"*; línea `next` *"Weekly, specifically on
Tuesdays"* con *"fewer guarantees around breaking changes in these releases, where moving from one
release to the next may introduce significant breaking changes"*. Sobre seguridad: *"Vulnerabilities
with a severity of `high` or `critical` will always be backported to releases for the last 6 months
if feasible."* Deprecación de exports estables: *"The deprecation must have been released for at
least one mainline release before it can be removed."*

**Consecuencia de decisión, no negociable**: **una release mensual con ventana de retroportación de
seguridad de 6 meses implica un compromiso de mantenimiento continuo**, no un "lo instalamos y
listo". Si nadie tiene asignado tiempo recurrente para subir versión de Backstage, **no se elige
Backstage**. Ese cálculo se hace antes, no cuando la instancia lleve un año sin actualizar. A esto
se suma la migración al **New Frontend System**, que no es un "Backstage 2.0" sino un cambio
arquitectónico entregado dentro de la línea 1.x (APIs estabilizadas y migración recomendada a
partir de v1.42.0, con fase híbrida documentada): **es trabajo de migración planificable, no
opcional a largo plazo**.

## 3. Estructura y convenciones

### 3.1 Cuándo NO construir una plataforma

Regla de entrada: **no se construye plataforma hasta que el mismo problema de entrega se haya
resuelto ad hoc al menos tres veces por equipos distintos**. Antes de eso no hay patrón, hay
suposición, y lo que se construye es la abstracción equivocada — que sale más cara de retirar que
de no haber hecho nada.

**No la construyas si**:
- **Hay un solo equipo de producto.** Con un equipo, "la plataforma" es el repositorio del equipo.
  Una capa de indirección entre tú y tú mismo solo añade latencia.
- **La organización es pequeña.** No hay número mágico publicado con metodología, y no se va a
  inventar uno aquí (§8): el criterio falsable es el de las tres repeticiones y el de §6.2 (si no
  puedes nombrar el *toil* concreto que eliminas y cuantificarlo en horas/mes, no hay caso).
- **El problema real es de proceso, no de herramienta.** Diagnóstico honesto: si los despliegues
  tardan tres semanas porque hay un comité de aprobación, una plataforma **no** arregla eso — le
  pone una interfaz bonita al comité. Igual con equipos que no pueden desplegar por falta de
  permisos, con una arquitectura que impide desplegar por partes, o con un cuello de botella
  organizativo. **Prueba de la pregunta**: *"si construimos esto y funciona perfecto, ¿desaparece
  el problema?"* Si la respuesta es no, el problema no era técnico.
- **Nadie puede ser dueño a tiempo completo.** Una plataforma sin dueño se degrada a un conjunto de
  scripts sin mantenedor que todo el mundo teme tocar. Peor que no tenerla.
- **Se está copiando lo que hizo una empresa 50 veces mayor.** Su plataforma resuelve su problema
  de escala organizativa, no el tuyo.

**El coste permanente, que casi nadie presupuesta.** Una plataforma no se "termina": se mantiene.
Presupuestar de forma explícita, y por escrito, antes de empezar:
1. **Actualizaciones del sustrato** (Kubernetes, proveedor, portal) que rompen sus abstracciones.
2. **Soporte a usuarios internos**: preguntas, depuración de fallos que parecen de la plataforma y
   no lo son (o al revés). Es la partida que más se subestima.
3. **Documentación** que caduca en cada cambio.
4. **Migraciones** que la plataforma impone a sus usuarios cuando deprecia algo.
5. **Guardia**: si un equipo no puede desplegar porque la plataforma está caída, alguien la
   levanta (§6.1).
6. **El coste de infraestructura de la propia plataforma**, medido como unidad económica
   (`finops-standards`).

Si esas seis partidas no tienen personas asignadas, el proyecto no está aprobado: está apostado.

### 3.2 La diferencia con DevOps y con SRE, escrita con precisión

Sin eslóganes. Las tres coexisten y responden preguntas distintas:

| | Pregunta que responde | Objeto | Modo de trabajo | Fracasa cuando |
|---|---|---|---|---|
| **DevOps** | ¿Cómo eliminamos el traspaso entre quien construye y quien opera? | El **flujo de trabajo** y la propiedad *end-to-end* | Cultural y organizativo; **no es un equipo ni un producto** | Se crea un "equipo DevOps" que es el antiguo equipo de operaciones con nombre nuevo: reinstala el traspaso que venía a eliminar |
| **SRE** | ¿Cómo garantizamos que el servicio en producción cumple su objetivo de fiabilidad? | El **servicio en producción**: SLO, *error budget*, guardia, capacidad, postmortem | Ingeniería aplicada a la operación, con un presupuesto de error como árbitro | Se convierte en el equipo que arregla lo que otros rompen, sin poder para frenar despliegues |
| **Ingeniería de plataforma** | ¿Cómo reducimos la carga cognitiva del equipo de producto sobre el sustrato? | Un **producto interno** con usuarios, versiones y soporte | Producto: descubrimiento, hoja de ruta, adopción medida, deprecación | Se mide por lo que construye en vez de por lo que sus usuarios consiguen; o se impone por decreto (§1) |

Reparto en una frase por si hay duda: **DevOps es cómo trabaja la organización; SRE es quién
responde de que el servicio esté vivo y con qué presupuesto; la plataforma es qué producto se les
ofrece a ambos para que les salga más barato.** La plataforma **no** absorbe la responsabilidad de
producción del equipo de producto: si el equipo deja de responder de su servicio porque "lo lleva
la plataforma", se ha reconstruido el silo de operaciones con otro nombre.

### 3.3 El camino pavimentado (*golden path*)

**Definición operativa**: un recorrido completo, opinado y soportado, desde *no existe nada* hasta
*está en producción y observado*, para **un tipo concreto de trabajo**. Un camino pavimentado no es
una lista de herramientas recomendadas ni una página de wiki: es algo que se **ejecuta** y produce
un servicio funcionando.

Cubre, como mínimo y sin trabajo del equipo:
- Repositorio creado, con propiedad, protección de rama y revisión configuradas.
- Pipeline de construcción, prueba y despliegue **funcionando en el primer commit**.
- Identidad de carga de trabajo y acceso a secretos, **sin que nadie pegue una credencial**.
- Observabilidad de serie: logs estructurados, métricas y trazas ya emitidas y ya visibles
  (`observability-standards`), con panel y alerta base.
- Entorno de no producción y ruta a producción.
- Registro en el catálogo con dueño (§3.5).
- Etiquetas de coste obligatorias ya puestas (`finops-standards` §3.2).

**Qué lo distingue de un mandato**, punto por punto:

| | Camino pavimentado | Mandato |
|---|---|---|
| Por qué se usa | Porque es **el camino más rápido** al mismo resultado | Porque está prohibido lo otro |
| Qué pasa si no encaja | Se sale por la salida documentada (abajo) y **eso es una señal de producto** | Se pide excepción a un comité y se registra un incumplimiento |
| Qué mide su éxito | Adopción voluntaria (§6.2) | Cumplimiento — que no dice nada sobre si es bueno |
| Quién carga con el mal encaje | La plataforma: es su trabajo arreglarlo | El equipo de producto |

**Regla dura: debe existir una salida documentada.** Todo camino pavimentado publica, en el mismo
sitio que la guía de uso: qué casos **no** cubre; cómo se sale (interfaz de más bajo nivel, permisos
necesarios, plantilla mínima); **qué se pierde al salir** (soporte, actualizaciones automáticas,
paneles de serie), escrito sin ambigüedad; y **qué se sigue exigiendo igualmente** (los controles de
seguridad y cumplimiento no son parte del camino pavimentado, son requisitos del entorno — se
aplican en admisión y valen para todos, §3.8).

Sin salida documentada, las opciones del equipo son cumplir aunque no encaje o construirse una
plataforma en la sombra. La segunda es lo que ocurre siempre, y encima sin que nadie la vea.
**Cada uso de la salida es un dato de producto**: se cuenta, se pregunta por qué y alimenta la hoja
de ruta. Si la salida se usa mucho para el mismo motivo, ese motivo es el próximo trabajo.

### 3.4 La API de la plataforma es un contrato versionado

La superficie que la plataforma ofrece —el esquema del descriptor de servicio, los recursos
personalizados, los parámetros de la plantilla, el punto final de despliegue— **es una API pública
con clientes que no controlas**. Por tanto:

- **Versionada explícitamente** y con compatibilidad hacia atrás dentro de una versión mayor. El
  diseño concreto (esquema, errores, deprecación de campos, negociación de versión) se rige por
  `api-design-standards`; aquí solo la obligación de tratarla como API.
- **Declarativa y en Git**. La intención del equipo vive en su repositorio; la plataforma reconcilia.
  Una plataforma cuya única interfaz es un botón en una web no es reproducible ni auditable, y no
  sirve para recuperación ante desastre.
- **Cambio incompatible = migración con plazo, herramienta y comunicación**, nunca un *breaking
  change* silencioso en una release menor (§7.2).
- **Superficie mínima**: cada campo expuesto es un compromiso perpetuo. Es más barato añadir un
  campo dentro de un año que retirarlo.
- **Los valores por defecto son la decisión de producto más importante que toma la plataforma**:
  determinan lo que hace el 95 % de los servicios. Se revisan y se versionan como código, no se
  dejan caer en un `if` de una plantilla.

### 3.5 Portal, catálogo y plantillas

**El portal se justifica cuando hace falta agregar información que hoy está dispersa** (quién es
dueño de qué, qué versión hay desplegada, qué depende de qué, qué alertas tiene, qué documentación
existe). Si eso ya está resuelto, el portal es una capa más que mantener. **Un portal no es una
plataforma**: es una interfaz. Construir el portal primero y la plataforma después es el error de
secuencia más frecuente del dominio — se acaba con un directorio bonito de servicios que nadie
puede crear ni desplegar desde ahí.

**Catálogo de servicios**. Es el sustrato de todo lo demás, y su único requisito duro es que **sea
cierto**. Metadatos mínimos por entrada, con propietario mecánico:
- **Dueño**: identificador de **equipo** del directorio corporativo, **nunca** una persona. Las
  personas se van; los equipos se reasignan de forma explícita.
- **Nivel de criticidad** (determina SLO, guardia y requisitos de despliegue).
- **Dependencias** declaradas (qué consume, qué expone).
- **Enlaces vivos**: repositorio, pipeline, panel, runbook, documentación.
- **Clasificación de datos** que maneja (`grc-compliance-standards`, `privacy-engineering-standards`).
- **Etiquetas de coste** coherentes con `finops-standards` §3.2.
- **Ciclo de vida**: experimental / producción / **deprecado**. Sin el tercer estado, el catálogo
  crece para siempre.

**Reglas del catálogo, falsables**:
1. **Se genera desde el código**, no se rellena a mano. El descriptor vive en el repositorio del
   servicio (p. ej. `catalog-info.yaml`) y se descubre; un catálogo mantenido a mano está
   desactualizado en un trimestre.
2. **Entrada sin dueño válido = entrada rota.** Se detecta automáticamente y se reporta, y hay un
   plazo tras el cual el servicio se marca como huérfano de forma visible.
3. **Un catálogo con datos falsos es peor que no tener catálogo**: la gente decide con él. Prueba
   automática de coherencia (el dueño existe en el directorio, los enlaces responden, el servicio
   declarado existe en el clúster).

**Plantillas de creación de servicio (*scaffolding*)**. Regla central, y es la que separa una
plataforma viva de un generador de deuda: **generar código a partir de una plantilla crea una copia
que ya no recibe mejoras**. Estrategia obligatoria:
- **Lo que debe evolucionar centralizado no se copia: se referencia.** Pipeline como plantilla
  reutilizable versionada (propiedad de `cicd-standards`), configuración común como dependencia,
  módulos de infraestructura como versión fijada. La plantilla genera **lo mínimo propio del
  servicio**.
- **Actualización de lo ya generado**: si algo se copia, tiene que existir un mecanismo para
  actualizar los repositorios que lo copiaron (PR automatizado o herramienta de migración) **y estar
  probado**. Sin eso, cada plantilla nueva es un incendio futuro repartido en N repositorios.
- **La plantilla se prueba en CI**: se ejecuta, se construye el servicio generado, se despliega en
  efímero y se destruye. Una plantilla rota bloquea a todos los servicios nuevos a la vez.
- **Las plantillas son código ejecutable con privilegios**: ver §5.

### 3.6 Abstracciones de infraestructura: cuándo Crossplane, cuándo módulos

**Crossplane, estado verificado**: Apache-2.0, **CNCF Graduated desde el 28-oct-2025**, línea
**v2.x**. **Ha tenido un cambio arquitectónico relevante y toda la documentación de terceros
anterior a él induce a error**:

- En **v2**, los *composite resources* (XR) y **todos** los *managed resources* pasan a ser
  **namespaced**; un XR puede componer **cualquier** recurso de Kubernetes, no solo *managed
  resources*.
- **Los *claims* desaparecen.** Eran el mecanismo por el que un objeto de espacio de nombres
  producía un XR de ámbito de clúster. Con XR ya *namespaced* dejan de tener sentido: lo que antes
  era un *Claim* ahora **es directamente un XR**. En la referencia de API, `claimNames` está marcado
  como deprecado y no se soporta en `apiextensions.crossplane.io/v2`.
- El XRD gana un campo **`scope`** con tres valores: `Namespaced` (**el default de v2** y el
  recomendado, por aislamiento y por convención de Kubernetes), `Cluster` (para recursos de nivel
  plataforma) y **`LegacyCluster`** (compatibilidad v1, el único que sigue soportando *claims*; es
  a lo que se resuelve `scope` si se usa la versión v1 del API del XRD).
- **Consecuencia práctica**: cualquier diseño, tutorial o módulo que gire alrededor de *claims* está
  describiendo v1. Antes de copiarlo, comprobar contra qué versión está escrito.

**Criterio de elección**, en este orden:

| Situación | Elección |
|---|---|
| Infraestructura que se crea, se cambia poco y se destruye con el servicio | **Módulo de IaC versionado.** Es lo que el equipo ya entiende, se depura con las herramientas de siempre y no añade un plano de control que mantener |
| Se necesita **reconciliación continua** (que la deriva se corrija sola, no en el siguiente `apply`) | **Crossplane** o un **operador** |
| Se quiere ofrecer una **API propia de dominio** ("una base de datos de producto") consumible desde Kubernetes por los mismos medios que el resto | **Crossplane** (XRD + Composition) |
| El comportamiento a automatizar es **específico de un producto y con lógica de ciclo de vida propia** (conmutación, copia, actualización mayor) | **Operador dedicado** del proveedor de ese producto, no una composición casera |
| El equipo de plataforma **no tiene capacidad para operar un plano de control adicional** | **Módulos.** Crossplane añade un componente crítico más al camino de despliegue |

**Advertencia de honestidad**, porque es donde más dinero se pierde: **una abstracción que solo
reenvía parámetros no aporta nada y cuesta mantenimiento.** Si el XRD o el módulo expone
prácticamente los mismos campos que el recurso subyacente, no has abstraído: has añadido una capa de
indirección, un vocabulario nuevo que enseñar y un punto de fallo. La abstracción se justifica
cuando **decide** algo (aplica los valores por defecto correctos, compone varias piezas, impone
política) y **oculta** algo que el equipo no debería tener que saber. La regla de qué **no** ocultar
está en §7.

### 3.7 Autoservicio con barandillas

Autoservicio sin barandillas es un incidente esperando fecha; barandillas sin autoservicio es un
proceso de tickets con más pasos. Las dos, siempre juntas:

- **Política como código en admisión**, no en revisión humana. Es el único punto donde el control
  se aplica **con independencia del camino que haya tomado el equipo** — camino pavimentado, salida
  documentada o herramienta propia. Por eso los controles obligatorios viven aquí y no en la
  plantilla: una plantilla se puede no usar. La mecánica de admisión y sus herramientas son de
  `kubernetes-standards`; **la decisión de qué es obligatorio para todos** se toma con seguridad y
  cumplimiento, no la inventa la plataforma sola.
- **Cada política nueva entra primero en modo aviso**, con informe de cuántos objetos existentes
  incumpliría, y solo después bloquea. Publicar una política que rompe cargas ya desplegadas es la
  forma más rápida de perder la confianza que la adopción voluntaria necesita.
- **La denegación tiene que explicar cómo arreglarlo.** Un rechazo de admisión con un mensaje
  críptico convierte el autoservicio en un ticket, que es justo lo que se venía a eliminar. Mensaje
  con: qué regla, por qué existe, qué cambiar y a quién preguntar.
- **Cuotas por espacio de nombres/equipo** como límite superior de daño (recursos y coste). Una
  cuota que nadie ha alcanzado nunca está mal calibrada o es decorativa: revísala.
  **Límite duro, alineado con `finops-standards` §7**: una cuota puede **frenar la creación de
  recursos nuevos**, y en no-producción puede frenarla del todo; **PROHIBIDO que topar la cuota
  bloquee el despliegue de una versión nueva de un servicio que ya corre en producción** —eso
  convierte una desviación contable en un incidente de disponibilidad—. Si la cuota se alcanza en
  producción, la admisión **avisa y escala al dueño del presupuesto**, no deniega el rollout.
- **Entornos efímeros**: los tres requisitos son **TTL obligatorio**, **destrucción automática
  verificada** (y alertada si falla) y **datos no productivos**. Un entorno efímero que sobrevive es
  un entorno permanente sin dueño, sin parches y con datos de origen desconocido. Prohibido crear
  efímeros sin TTL "temporalmente".
- **Todo lo que se puede crear por autoservicio se tiene que poder destruir por autoservicio.** Si
  crear es un botón y borrar es un ticket, la organización acumula recursos para siempre.

## 4. Calidad y gates

La plataforma es software de producción y se le aplican `testing-qa-standards` y
`code-review-standards` sin descuento. Lo específico del dominio:

| # | Gate | Qué prueba | Rompe |
|---|---|---|---|
| 1 | Lint y validación de esquema de los descriptores (catálogo, plantillas, XRD/Composition) | Que el contrato es sintácticamente válido | Sí |
| 2 | **Test de contrato de la API de la plataforma** | Que un descriptor de la versión anterior **sigue siendo aceptado** | Sí |
| 3 | **Test de extremo a extremo de cada plantilla**: generar → construir → desplegar en efímero → comprobar salud → destruir | Que el camino pavimentado funciona hoy | Sí. **Es el gate más valioso de la plataforma** |
| 4 | Test de las políticas de admisión con casos que **deben** pasar y casos que **deben** ser rechazados | Que la barandilla no bloquea lo legítimo ni deja pasar lo prohibido | Sí |
| 5 | Simulacro de actualización: aplicar la versión nueva de la plataforma sobre un entorno con servicios creados por la versión anterior | Que no se rompen los usuarios ya existentes | Sí |
| 6 | Verificación diaria del catálogo (dueños existentes, enlaces vivos, entradas huérfanas) | Que el catálogo es cierto (§3.5) | Reporta y abre ticket |
| 7 | Comprobación sintética periódica del camino pavimentado en producción | Que crear un servicio nuevo funciona **ahora** | Alerta a la guardia de la plataforma |

**Bordes que hay que probar explícitamente**, porque son los que rompen en producción: nombre de
servicio que ya existe; repositorio existente; permisos insuficientes del usuario que ejecuta la
plantilla; **la plantilla a mitad de camino** (repositorio creado y pipeline no) — la creación debe
ser idempotente y reintentar sin duplicar, o dejar un estado limpio; el proveedor de nube devolviendo
error de cuota; el servicio generado con caracteres no ASCII o nombres largos; la actualización de
un servicio creado por una versión antigua de la plantilla.

## 5. Seguridad: la plataforma es un punto único de compromiso

Esta sección es la razón de que la plataforma tenga que ser mejor que la media de lo que despliega.
**Sus credenciales, sus plantillas y su cadena de suministro afectan a todo lo que despliega**: quien
la controla puede desplegar código arbitrario en todos los entornos, con la identidad legítima de la
plataforma y sin disparar ninguna alarma de "cambio no autorizado", porque desplegar es exactamente
lo que hace. Es un objetivo de alto valor por diseño.

- **Identidad**: la plataforma **no** usa una credencial única con permisos sobre todo. Identidad
  por operación y por entorno, federada y de vida corta (OIDC), con el permiso mínimo para la acción
  concreta. Un token estático de administrador en la plataforma es el peor secreto de la
  organización (`identity-access-management-standards`, `secrets-management-standards`).
- **La plataforma nunca ve el secreto de la aplicación**: conecta la carga con el gestor de secretos
  y se aparta. Si el valor pasa por la plataforma, la plataforma es ahora el mayor almacén de
  secretos de la empresa y nadie lo diseñó así.
- **Las plantillas son código ejecutable con los privilegios de la plataforma.** Precedente
  concreto y verificado, no hipotético: en Backstage, la mayoría de los avisos de seguridad del
  *scaffolder* dependen de que el atacante pueda **registrar o editar una plantilla en el catálogo**
  — inyección de plantilla del lado servidor con captura de tokens de git (**CVE-2024-53983**,
  medio), travesía de ruta, ejecución remota de código en plantillas `v1beta3` (el motor asumía que
  las plantillas eran de confianza), XSS almacenado en el catálogo, y **CVE-2026-29184** (marzo de
  2026), evasión de la redacción de logs que permite exfiltrar secretos de una ejecución a través de
  los eventos de la tarea. **Conclusión de diseño**: *quién puede registrar una plantilla* es un
  control de seguridad de primer nivel, equivalente a *quién puede desplegar en producción*. Las
  plantillas viven en un repositorio con `CODEOWNERS` y revisión obligatoria; el registro de
  plantillas desde repositorios arbitrarios está **prohibido**.
- **Cadena de suministro de la propia plataforma**: sus imágenes base, sus plugins de terceros y sus
  módulos son dependencias transitivas de **todos** los servicios. Fijar por digest, SBOM, firma y
  verificación de procedencia (`cicd-standards`). Recordatorio del catálogo: **la procedencia firmada
  no basta** — han circulado paquetes maliciosos con atestaciones válidas; el corte real es el pin
  por digest y la revisión de qué se añade.
- **Plugins de portal de terceros**: en un portal que se compila como aplicación propia (Backstage),
  un plugin **corre con los privilegios del portal** y ve lo que el portal ve. Cada plugin nuevo es
  una decisión de seguridad con revisión, no una casilla que se marca.
- **Multi-inquilino**: la frontera entre equipos se impone en el sustrato (espacios de nombres,
  políticas de red, RBAC, cuotas), **no** en la interfaz. Si la única cosa que impide a un equipo
  ver o tocar lo de otro es que el portal no le muestra el botón, no hay aislamiento: hay
  ocultación.
- **Auditoría**: toda acción de autoservicio deja registro inmutable de **quién, qué, cuándo, sobre
  qué entorno y con qué versión de plantilla**. Es lo que convierte el autoservicio en algo
  defendible ante `grc-compliance-standards`, y lo que permite responder "¿qué desplegó esto?"
  durante un incidente.
- **La plataforma no puede ser el único camino a producción en una emergencia.** Debe existir un
  procedimiento de rotura de cristal documentado y **ensayado**, con identidad distinta, alerta
  automática al usarse y revisión posterior. Si la plataforma cae y nadie puede desplegar un
  arreglo, la plataforma ha convertido su propia indisponibilidad en una indisponibilidad de todos
  los productos (`bcdr-standards`, `incident-management-standards`).

## 6. Operación y medida

### 6.1 La plataforma tiene SLO y guardia

No es opcional y no es negociable: **la plataforma es un servicio de producción cuyo fallo bloquea a
todos los equipos a la vez.** Los SLO se definen y se operan con el método de
`sre-practice-standards` (allí viven SLI, *error budget* y política de guardia); aquí, qué hay que
declarar como mínimo:

- **Disponibilidad de la ruta de despliegue** — el camino de un commit a producción. Es el SLI que
  importa; el *uptime* del portal es secundario.
- **Latencia de aprovisionamiento** de los recursos que la plataforma ofrece (percentil, no media).
- **Tasa de éxito de la creación de servicio** desde plantilla.
- **Frescura y corrección del catálogo** (§3.5).

Y una regla de conducta: **el consumo de presupuesto de error de la plataforma se comunica a sus
usuarios**, igual que un proveedor externo comunica su estado. Un usuario interno que no sabe si el
fallo es suyo o de la plataforma pierde el doble de tiempo.

### 6.2 Métricas de adopción reales

**La métrica correcta es el tiempo hasta el primer despliegue en producción de un servicio nuevo y
la reducción de *toil*.** Las dos miden lo mismo desde los dos extremos: cuánto cuesta empezar y
cuánto cuesta seguir.

| Métrica | Cómo se mide | Por qué es la correcta |
|---|---|---|
| **Tiempo hasta el primer despliegue en producción** de un servicio nuevo | Desde la decisión de crearlo hasta que sirve tráfico real, medido de punta a punta, incluidas las esperas por aprobaciones y accesos | Es el resultado por el que existe la plataforma. Incluye todo lo que el equipo sufre, no solo lo que la plataforma automatiza |
| **Reducción de *toil*** | Horas/mes de trabajo manual, repetitivo y automatizable que el equipo de producto ya no hace. Se estima antes y se vuelve a medir después | Es el ahorro que paga la plataforma. Si no se puede nombrar el *toil* concreto, no hay caso de negocio (§3.1) |
| Adopción voluntaria | % de servicios nuevos que eligen el camino pavimentado **teniendo alternativa** | Sin alternativa, el número no significa nada |
| Uso de la salida documentada | Nº de veces y **motivo** (§3.3) | Es la hoja de ruta escribiéndose sola |
| Satisfacción del usuario interno | Encuesta corta y periódica, con pregunta abierta | Detecta el descontento antes de la deserción |
| Tiempo de resolución de las peticiones de soporte a la plataforma | Igual que un producto externo | Un soporte lento anula cualquier ahorro |
| Coste de la plataforma por equipo servido | Unidad económica (`finops-standards`) | Es un producto y tiene precio |

**Por qué el número de usuarios registrados es una métrica falsa**: cuenta el registro, no el uso;
sube cuando alguien entra una vez a mirar; sube automáticamente al integrar el inicio de sesión
único, sin que nadie haya usado nada; y **es incapaz de bajar** — con lo que no puede detectar un
fracaso, que es lo único que se le pediría a una métrica de adopción. Lo mismo aplica al número de
servicios en el catálogo (mide cuántos servicios hay, no cuánto ayuda la plataforma) y al número de
plugins instalados.

### 6.3 DORA como medida de resultado, con sus matices

**Estado verificado de la fuente, que casi todo el mundo cita mal**: DORA dejó de publicar bajo el
nombre *Accelerate State of DevOps*; la edición **2025** se titula **"State of AI-assisted Software
Development"**, y la publicación más reciente a ago-2026 es **"The ROI of AI-Assisted Software
Development (2026.01)"**. **No existe un "DORA State of DevOps 2026"**: lo que circula con ese
nombre para 2026 es el informe de **Puppet** (*State of DevOps Report: Platform Engineering
Edition*) y el de **Perforce**, que son de otros autores y otra metodología. Citar la edición
correcta o no citar.

**Lo que DORA dice realmente sobre plataformas internas**, y es contraintuitivo — verbatim de
`dora.dev`:

- *"platforms improve productivity and organizational performance, they can sometimes lead to a
  decrease in throughput and change stability if not carefully managed."*
- *"developer independence, the ability to perform tasks without relying on an enabling team,
  resulted in a 5% improvement in productivity at both the team and individual levels."*
- Sobre la interacción con IA: *"When platform quality is high, the effect of AI adoption on
  organizational performance becomes strong and positive. Conversely, when platform quality is low,
  the effect of AI adoption on organizational performance is negligible."*

Tres consecuencias directas, y son el núcleo del criterio de este documento:

1. **Una plataforma puede empeorar la entrega.** No es un riesgo teórico: es un hallazgo de la
   fuente de referencia del sector. Las explicaciones que se manejan —pasos adicionales antes de
   producción, capas nuevas de complejidad, más traspasos y dependencias, y funcionalidad que
   encaja mal cuando el uso es obligatorio— **se pueden comprobar en tu organización**: mide
   *throughput* y estabilidad **antes** de introducir la plataforma y vuelve a medir después. Si el
   equipo de plataforma no puede enseñar esas dos series, no sabe si está ayudando.
2. **La independencia del desarrollador es la variable que hay que optimizar**, no la centralización.
   Una plataforma que sustituye "abrir un ticket a operaciones" por "abrir un ticket a plataforma"
   no ha movido la aguja: el efecto medido está asociado a **poder hacer las cosas sin depender de
   otro equipo**.
3. **Calidad de la plataforma como multiplicador**: es el argumento honesto para invertir en
   calidad interna en vez de en más funcionalidad. Una plataforma mediocre no solo no ayuda: anula
   el efecto de otras inversiones.

**Cifras**: la edición **2024** es la que cuantificó el efecto de las plataformas, y las cifras que
circulan (mejoras de productividad individual y de equipo, con caídas de *throughput* y de
estabilidad, esta última asociada al **uso obligatorio y exclusivo** de la plataforma) proceden en
su mayoría de **lecturas secundarias del informe**, no de la página oficial. **No se fijan aquí como
dato**: si vas a citar un porcentaje, sácalo del PDF del informe y cita su año, o no lo cites. Y
descarta sin excepción las cifras de proveedores de plataformas ("*N* % más rápido con nuestra
herramienta") que no publican muestra ni método: no son datos, son material comercial.

**Advertencia de uso de DORA, la más importante**: las cuatro métricas miden **el sistema de
entrega**, no al equipo. Convertirlas en objetivo individual o en comparación entre equipos las
destruye (se despliega más a menudo y más pequeño para mover el número, sin valor añadido). Y son
**métricas de resultado del producto**, no de la plataforma: la plataforma influye en ellas, no las
posee. La medida propia de la plataforma es §6.2.

### 6.4 Carga cognitiva: el fundamento teórico

El argumento por el que existe este dominio. Fuente original: **John Sweller, "Cognitive load during
problem solving: Effects on learning", *Cognitive Science* 12(2), 257–285 (1988)** — teoría
formulada sobre **aprendizaje individual y diseño instruccional**. Su traslado a equipos de software
es de **Matthew Skelton y Manuel Pais, *Team Topologies* (2019)**, que lo convierte en restricción
de diseño organizativo: el equipo se dimensiona y se delimita para que pueda entender, operar y
mejorar su parte del sistema. Los tres tipos: **intrínseca** (inherente al problema y a la
tecnología), **extraña** (impuesta por el entorno: configurar, desplegar, pelearse con el sustrato)
y **germana** (la que sí produce valor: el dominio del negocio).

Regla de decisión que se deriva, y es la única que hace falta: **la plataforma existe para eliminar
carga extraña; nunca para eliminar carga germana.** La carga extraña —montar un entorno, cablear
observabilidad, escribir la pipeline número mil— es coste puro y se automatiza sin remordimiento.
La germana —el dominio del negocio, las decisiones de diseño, la responsabilidad sobre el
comportamiento en producción de lo propio— **es el trabajo**, y una plataforma que se la quita al
equipo no lo alivia: lo desapodera y reconstruye el silo de operaciones (§3.2).

**Honestidad sobre la fuente, porque el catálogo no cita marketing**: la extensión de un constructo
de psicología cognitiva **individual** a un **equipo** es una analogía útil, no una medición
validada. La carga cognitiva de equipo **no tiene una unidad medible**; usarla como argumento
cualitativo de diseño es legítimo, presentar un "índice de carga cognitiva" como dato duro no lo es.
Lo que sí se puede medir es el proxy: cuántas herramientas, repositorios, tecnologías y sistemas
distintos tiene que sostener un equipo, y cuántas horas al mes dedica a algo que no es su dominio.

### 6.5 La plataforma como producto: dueño, hoja de ruta, soporte, deprecación

- **Dueño único y nominal**, con autoridad para decir que no. Un producto con varios dueños no tiene
  ninguno. Es la condición de entrada de §3.1 y la primera prohibición de §7.
- **Hoja de ruta pública para sus usuarios**, con lo que **no** se va a hacer escrito de forma
  explícita. Un "no" claro permite al equipo resolverlo por su cuenta; el silencio le hace esperar.
- **Descubrimiento de necesidades con método**, no por el ticket que más grita ni por lo que al
  equipo de plataforma le apetece construir. La técnica es de
  `product-discovery-standards`; lo obligatorio aquí es que exista una vía formal y que **el uso de la salida
  documentada (§3.3) sea una de sus entradas**.
- **Soporte con canal, horario y expectativa de respuesta publicados.** Un producto interno sin
  soporte declarado se abandona en el primer bloqueo.
- **Documentación tratada como parte del producto**: se versiona con el código, se prueba
  (los ejemplos ejecutables se ejecutan en CI) y **se borra cuando caduca**. Documentación mentirosa
  cuesta más que ninguna.
- **Ciclo de deprecación explícito para cada capacidad**: anuncio → alternativa **disponible y
  documentada** → periodo de convivencia con plazo → herramienta o PR automatizado de migración →
  retirada. **Prohibido deprecar sin alternativa lista**: eso no es deprecar, es dejar tirado al
  usuario. Y **la migración la paga la plataforma**, en trabajo o en herramienta: es ella quien
  decidió el cambio.
- **Capacidad que nadie usa se retira.** Cada característica viva cuesta mantenimiento, superficie
  de ataque y documentación. Revisión periódica con datos de uso.

## 7. Sostenibilidad y prohibiciones

### 7.1 Cadencia

- **Backstage**: release mensual y ventana de retroportación de seguridad de **6 meses** (§2.1) →
  cadencia de actualización **mensual o, como máximo, trimestral**. Pasado el medio año, se está
  corriendo con vulnerabilidades altas o críticas sin parche disponible en tu línea.
- **Crossplane**: verificar la línea soportada y planificar la migración de v1 a v2 con el cambio de
  ámbito y la retirada de *claims* (§3.6) como proyecto propio, no como efecto colateral de un
  `helm upgrade`.
- **Sustrato**: cada actualización mayor de Kubernetes o del proveedor puede romper una abstracción
  de la plataforma. Probarlo en el gate 5 de §4 **antes** de que llegue a los usuarios.
- **Revisión anual de la propia existencia de la plataforma**: si sus métricas de §6.2 no mejoran
  durante un año, la decisión correcta puede ser reducirla, no ampliarla.

### 7.2 Prohibiciones

- ❌ **Plataforma sin dueño.** Sin una persona responsable con autoridad, no se aprueba, no se
  arranca y no se mantiene. Es la primera causa de plataformas zombi.
- ❌ **Obligar a usarla para justificar su existencia.** La adopción forzada elimina la señal de
  fallo (§1). Los controles de seguridad y cumplimiento sí son obligatorios, y por eso viven en
  admisión y se aplican a todos los caminos por igual (§3.7): esa es la diferencia.
- ❌ **Abstraer lo que el equipo necesita controlar.** Prohibido ocultar: la configuración que el
  equipo tiene que ajustar para cumplir su SLO (recursos, escalado, tiempos de espera,
  reintentos); lo que necesita para **depurar** en producción (logs, trazas, acceso, la relación
  entre su abstracción y los recursos reales); y lo que le van a exigir en una auditoría. Una
  abstracción que hay que romper para diagnosticar un incidente **es una abstracción rota** — y se
  rompe siempre en el peor momento.
- ❌ **Medir la adopción por usuarios registrados** (§6.2), por servicios en el catálogo o por
  plugins instalados.
- ❌ **Construir el portal antes que el camino pavimentado.** Se acaba con un directorio de servicios
  desde el que no se puede hacer nada.
- ❌ **Camino pavimentado sin salida documentada** (§3.3). Produce plataformas en la sombra que nadie
  ve ni gobierna.
- ❌ **Deprecar sin alternativa disponible y sin ruta de migración** (§6.5).
- ❌ **Plantillas que copian código que luego debe evolucionar de forma central**, sin mecanismo
  probado para actualizar lo ya generado (§3.5).
- ❌ **Registro de plantillas del *scaffolder* desde repositorios arbitrarios o sin revisión.** Es
  ejecución de código con los privilegios de la plataforma (§5).
- ❌ **Credencial única y estática con permisos amplios** para la plataforma (§5).
- ❌ **Que la plataforma sea el único camino a producción** sin procedimiento de rotura de cristal
  ensayado (§5).
- ❌ **Aislamiento entre inquilinos basado en la interfaz.** Si el portal es lo único que separa a
  dos equipos, no hay separación.
- ❌ **Entorno efímero sin TTL** ni destrucción verificada (§3.7).
- ❌ **Abstracción que solo reenvía parámetros** (§3.6): coste sin beneficio.
- ❌ **Citar cifras de plataformas sin metodología** —de proveedor, o un porcentaje de DORA sin
  indicar la edición del informe— y **citar un "DORA State of DevOps 2026"**, que no existe (§6.3).
- ❌ **Presentar la carga cognitiva de equipo como una magnitud medida** (§6.4).
- ❌ **Que el equipo de producto deje de responder de su servicio en producción porque "lo lleva la
  plataforma"** (§3.2).

## 8. Verificación web obligatoria

Antes de fijar nada de este documento en un proyecto real:

1. **Backstage**: versión estable actual (a ago-2026 la línea es **1.5x**; el feed Atom del
   repositorio mezcla releases `next` semanales con las mensuales — **filtrar los `-next`**),
   `LICENSE` **en crudo** (Apache-2.0 verificado), estado de la **política de versiones y de
   retroportación de seguridad**, avisos de seguridad abiertos, estado del **New Frontend System** y
   su ruta de migración, y **si ha graduado en la CNCF** (a ago-2026 sigue *Incubating* desde el
   15-mar-2022). Recordatorio del catálogo: **el feed de releases de GitHub no es la fuente de
   verdad** — contrastar con `backstage.io`.
2. **Crossplane**: línea soportada y estado de la migración v1→v2 (`scope`, `LegacyCluster`,
   retirada de *claims*), y confirmar la madurez CNCF (a ago-2026: **Graduated desde el
   28-oct-2025** — mucha documentación de terceros sigue diciendo *Incubating*).
3. **CNCF**: página del proyecto para cada pieza que fijes, para su nivel de madurez y sus fechas.
   **Cuidado con la colisión de nombres**: el `Cortex` de la CNCF **no** es el portal `cortex.io`
   (§2.1).
4. **Port, Cortex, Humanitec**: estado de la empresa, precio y términos actuales, y **si ha habido
   adquisición o cambio de modelo**. Nada de esto se escribe de memoria; a ago-2026 no consta
   adquisición de Humanitec, pero es exactamente el tipo de dato que caduca.
5. **Score**: si sigue en *Sandbox* de la CNCF o ha promocionado; el estado de sus implantaciones de
   referencia. Sandbox implica riesgo de adopción.
6. **DORA**: **edición vigente y su nombre exacto** (cambió: ya no es *Accelerate State of DevOps*),
   qué dice la edición actual sobre plataformas internas, y **de qué informe y año procede cualquier
   porcentaje que vayas a citar**. No confundir con los informes de Puppet o Perforce, que son de
   otros autores (§6.3).
7. **Licencias**: `LICENSE` **en crudo** de toda herramienta que fijes como default, incluidas las
   que "todo el mundo sabe" que son abiertas. El catálogo acumula casos de lo contrario, el último
   un producto que dejó de ser open source mientras la documentación de terceros seguía diciendo
   que lo era. Comprobar además si alguna ha cambiado de propiedad o está en modo mantenimiento.
8. **Huecos declarados de este documento** (no rellenados por falta de fuente con metodología, no
   por olvido):
   - **No hay aquí un tamaño de organización a partir del cual construir plataforma**: no se
     localizó fuente con metodología publicada. Se usa el criterio falsable de las tres
     repeticiones y el del *toil* cuantificado (§3.1).
   - **No hay aquí un tamaño recomendado de equipo de plataforma**: la página de capacidades de
     DORA no lo especifica y las cifras que circulan son de proveedor.
   - **No se fijan los porcentajes de DORA sobre plataformas**: la página oficial da la dirección
     del efecto pero no los números; los que circulan son de lecturas secundarias del informe 2024
     (§6.3). Sácalos del PDF con su año o no los uses.
   - **Precios de Port, Cortex y Humanitec: no se fijan** (punto 4).
   - **No hay aquí una cifra de reducción de *toil* típica**: se mide en tu organización, antes y
     después (§6.2).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
