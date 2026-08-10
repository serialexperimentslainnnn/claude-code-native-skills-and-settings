---
name: rpa-workflow-automation-standards
description: Automating a business process with a robot that drives a user interface, and knowing when not to. Use when deciding between RPA and an API integration, when a screen-scraping or UI-driving automation is proposed against an ERP, a mainframe emulator, a legacy web app or a Citrix session, when building or reviewing robots in UiPath Studio (.xaml projects, Orchestrator queues, assets and Credential Stores), Automation Anywhere, SS&C Blue Prism, Power Automate Desktop (desktop flows, machine registration, attended versus unattended bots, Power Automate Premium/Process/Hosted Process licensing per bot), Robot Framework (.robot suites, SeleniumLibrary, Browser library) or Playwright driving a real application, when the robot needs an identity and credentials of its own instead of a named employee's account, when designing work queues, idempotent retries, partial-failure recovery and the half-completed transaction, when setting SLA, monitoring and alerting for an unattended process, when inventorying robots and finding the orphaned one still moving money, or when choosing a real workflow engine (Temporal, Camunda, Apache Airflow, Windmill, n8n) instead of RPA.
---

# Estándares de RPA y automatización de procesos

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **automatizar un proceso de negocio de extremo a extremo**: decidir con qué se automatiza,
construir el robot o el flujo, darle identidad y credenciales, orquestarlo, hacerlo resistente al
fallo parcial, vigilarlo y **gobernarlo durante los años que va a seguir ejecutándose**.

Triggers: "automatizar este proceso", "el sistema no tiene API", `.xaml` de UiPath Studio,
Orchestrator, colas y *assets*, Automation Anywhere Control Room, SS&C Blue Prism, *digital worker*,
Power Automate Desktop, *desktop flow*, registro de máquina, bot atendido y desatendido,
`.robot` de Robot Framework, Playwright o Selenium conduciendo una aplicación real (no un test),
emulador 3270/5250, sesión Citrix, OCR sobre una pantalla, "el robot se ha roto porque han cambiado
la pantalla", cola de trabajo, reintento, "el proceso se quedó a medias", inventario de robots,
"¿de quién es este robot?", Temporal, Camunda, Airflow, Windmill, n8n.

**Regla dura que ordena todo el documento: si hay API, la RPA es la última opción, no la primera.**
La RPA imita a una persona ante una interfaz de usuario; la integración por API habla el contrato que
el sistema publica. La primera se rompe cuando alguien mueve un botón —y ese alguien no eres tú—; la
segunda se rompe cuando el proveedor cambia el contrato, que es un evento anunciado, versionado y
negociable. **Esa asimetría no se compensa con ninguna herramienta.**

**La RPA es legítima, y solo, cuando se cumple al menos una y se documenta cuál:**

1. **El sistema no tiene API** y no la tendrá (producto cerrado, mainframe, aplicación de escritorio
   sin integración).
2. **El proveedor tiene API pero no la abre**, o cobra por ella un múltiplo del coste del robot.
3. **El coste de integrar es desproporcionado frente a la vida del proceso**: proceso que desaparece
   en 12 meses por una migración ya planificada.
4. **Puente temporal explícito**, con fecha de retirada escrita, mientras se construye la integración
   de verdad.

Fuera de esos cuatro casos, un robot es **deuda técnica con nómina**: se ha comprado la fragilidad
sin ninguna de las ventajas.

**Segunda tesis, la que causa los incidentes reales: el estado peligroso no es el robot caído, es el
proceso a medio ejecutar.** Un robot que falla en el paso 7 de 12 deja una factura registrada sin
asentar, un pedido creado sin confirmar, un pago iniciado sin conciliar. La caída se ve; el estado
inconsistente, no. Todo §3.3 existe por esto.

**No aplica**: ver `lowcode-governance-standards` (hermana directa y con
frontera nítida, porque Power Automate aparece en las dos: **suyo el gobierno de la plataforma
low-code** —catálogo de aplicaciones y flujos, entornos y su ciclo de vida (ALM), *citizen
developers* y su habilitación, políticas de prevención de pérdida de datos de conectores, *shadow
IT*, modelo de licenciamiento de la plataforma, quién puede crear qué—; **de aquí el robot y su
credencial**: que la automatización conduzca una interfaz de usuario, la identidad no humana con la
que lo hace, la bóveda de la que saca la contraseña, la cola de trabajo, el reintento idempotente, la
recuperación del proceso a medias y el SLA del proceso automatizado. Un *cloud flow* que llama a un
conector es gobierno de plataforma; un *desktop flow* que pulsa botones con las credenciales de
alguien es de aquí), `api-design-standards` (**la alternativa correcta**: contrato, versionado,
paginación, idempotencia y compatibilidad de la integración que deberías estar construyendo en vez
del robot), `identity-access-management-standards` (**diseño del IdP, ciclo de vida de la identidad
no humana, RBAC y revisión de accesos son suyos**; aquí la exigencia de que el robot tenga identidad
propia y qué se registra de lo que hace), `secrets-management-standards` (**la bóveda, la rotación y
la emisión de credenciales efímeras son suyas**; aquí la regla de que el robot nunca guarda la
contraseña y de qué pasa cuando la rotación rompe al robot), `ai-agents-standards` (**el bucle
agéntico, el diseño de herramientas, el límite de iteraciones, la aprobación humana y los riesgos
OWASP ASI son suyos**; ver §7.3: un LLM que pulsa botones hereda *todos* los problemas de esta skill
y añade no determinismo), `ai-agent-workflow-standards` (agentes de codificación en el equipo, no
robots de negocio), `testing-qa-standards` (**Playwright, Selenium y Robot Framework como herramienta
de *test* son suyos**; aquí las mismas herramientas usadas para **operar** un sistema en producción,
que es un uso distinto con riesgos distintos), `data-engineering-standards` y
`streaming-cdc-standards` (**si el proceso es mover y transformar datos, la respuesta es un pipeline,
no un robot**), `observability-standards` (plataforma de telemetría; aquí qué instrumenta un proceso
automatizado), `incident-management-standards` e `itsm-itil-standards` (guardia, escalado, cambio y
CMDB; aquí el robot como servicio que entra en esos procesos), `grc-compliance-standards` (SoA,
control y auditoría; aquí la trazabilidad técnica que hace posible auditar al robot),
`privacy-engineering-standards` (**el robot ve pantallas con datos personales y hace capturas**:
minimización, retención y tratamiento son suyos), `appsec-standards` (clases de vulnerabilidad
agnósticas), `python-standards` / `powershell-standards` (**muchas veces la respuesta honesta es un
script de 40 líneas**, y su calidad se rige por ellas), `git-workflow-standards` (versionado del
robot, que sí es obligatorio §4), `cicd-standards` (despliegue del robot entre entornos).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión, licencia y modelo de precio por web antes de fijarlos (§8).

### 2.1 La escalera de decisión, de arriba abajo

Se elige **la primera que resuelve el problema**. Bajar un peldaño exige justificar por escrito por
qué falla el anterior.

1. **No automatizar**: eliminar el paso. Muchos procesos son residuos de un sistema que ya no existe.
   Automatizar un proceso malo produce un proceso malo más rápido.
2. **Configurar el sistema** para que haga lo que hace la persona (regla, *workflow* nativo, informe
   programado).
3. **Integración por API / evento / webhook** entre los sistemas implicados.
4. **Base de datos o fichero de intercambio**, si el proveedor lo soporta oficialmente.
5. **Motor de workflow** con actividades codificadas (Temporal, Camunda, Airflow) para orquestar 3 y
   4 cuando el proceso es largo, tiene estados y necesita durabilidad.
6. **RPA**, con uno de los cuatro justificantes de §1 y **fecha de revisión**.
7. **Persona con lista de comprobación**, si el volumen no justifica nada de lo anterior. Es una
   respuesta válida y se descarta demasiado pronto.

### 2.2 Herramientas

| Herramienta | Licencia / modelo de coste | Cuándo |
|---|---|---|
| **Power Automate Desktop** | Comercial por suscripción. A ago-2026, precios de lista: **Premium $15 usuario/mes** (RPA *atendido*), **Process $150 bot/mes** (RPA *desatendido*), **Hosted Process $215 bot/mes** (incluye VM alojada) | Casa Microsoft con Entra ID y Power Platform ya en marcha. **El salto de atendido a desatendido multiplica el coste por diez: es la decisión económica, no técnica** |
| **UiPath** | Comercial. Nivel de entrada *Basic* publicado desde ~**$25/mes** con **2 robots**; el resto es "contact sales". Unidades: usuarios *Basic/Plus/Pro* y robots *Unattended* | Despliegues grandes con Orchestrator, colas y *Credential Store*. La madurez del orquestador es su ventaja real |
| **Automation Anywhere** | Comercial, por bot/usuario. **No verificable en la web pública desde este documento** (§8) | Alternativa de la misma categoría |
| **SS&C Blue Prism** | Comercial, históricamente por *digital worker*. **No verificable desde este documento** (§8) | Entornos muy regulados con control central fuerte |
| **Robot Framework** | **Apache-2.0** (`LICENSE.txt` del repositorio) | Automatización guiada por palabras clave, legible por negocio, y sobre todo **testing**. Como RPA de producción exige que tú montes orquestación, colas y bóveda |
| **Playwright** | **Apache-2.0** (`LICENSE` del repositorio) | Conducir un navegador de forma fiable. **La mejor opción técnica cuando el sistema objetivo es web**: selectores robustos, espera automática, trazas. Sin orquestador: se combina con 5 |
| **Temporal** | **MIT** (`LICENSE` del repositorio) — servicio gestionado aparte | Procesos de larga duración con **durabilidad de la ejecución**, reintentos y compensaciones. El estado del proceso **es** el código |
| **Camunda 8** | **Camunda License 1.0** — *source-available*, **no es open source**: *"If Your Use of the Software does not comply with the terms and conditions described in this License, You must purchase a commercial license"* | Procesos que negocio debe **ver y modelar** (BPMN), con tareas humanas |
| **Apache Airflow** | **Apache-2.0** (`LICENSE`) | **Lotes programados con dependencias entre tareas.** No es un motor de procesos de negocio ni tiene tareas humanas |

### 2.3 Motor de workflow ≠ RPA

Se confunden constantemente y no compiten:

- **RPA** = la **mano** que opera una interfaz que no te pertenece. Frágil por construcción.
- **Motor de workflow** = el **cerebro** que sabe en qué paso va el proceso, reintenta, compensa,
  espera a una persona y sobrevive a un reinicio. No toca ninguna pantalla.
- **Se usan juntos**: el motor orquesta y el robot es una de sus actividades, la más frágil, con
  *timeout* y compensación propios. **Un robot que orquesta a otros robots es un motor de workflow
  casero, mal hecho y sin durabilidad** — ese es el antipatrón más común del dominio.
- Diferencias que deciden: Temporal da **durabilidad de la ejecución** (el proceso sobrevive al
  reinicio del *worker* sin escribir estado a mano); Camunda da **modelo BPMN visible para negocio y
  tareas humanas**; Airflow da **planificación de lotes con grafo de dependencias**. Elegir Airflow
  para un proceso de negocio con esperas humanas es un error de categoría.

## 3. Estructura y convenciones

### 3.1 El robot como sistema, no como grabación

- **Todo robot vive en control de versiones** y se despliega por pipeline entre entornos
  (`git-workflow-standards`, `cicd-standards`). Un robot que solo existe en el orquestador es un
  robot que no se puede revisar, revertir ni auditar.
- **Nada de grabar y reproducir.** La grabación produce selectores por coordenadas y por índice, que
  es exactamente lo que se rompe. Selectores **por identificador estable, por rol o por texto
  anclado**; nunca por posición en pantalla, nunca por índice de tabla, nunca por captura de píxeles
  si existe otra vía.
- **Configuración fuera del robot**: URLs, rutas, umbrales, buzones. Un robot con el entorno
  incrustado no se puede probar en preproducción.
- **Separación por capas**: (a) *conectores* que hablan con cada sistema, (b) *reglas de negocio*,
  (c) *orquestación*. Un cambio de pantalla debe tocar solo (a). Sin esta separación, cada cambio del
  proveedor obliga a releer el proceso entero.
- **OCR y visión por computador son el último recurso**, con umbral de confianza explícito y **rechazo
  a cola de excepción** por debajo de él. Un OCR sin umbral inventa cifras en silencio, y esa es la
  peor propiedad posible en un proceso financiero.

### 3.2 Colas de trabajo

La unidad de trabajo es el **elemento de cola**, no "la ejecución del robot". Ejecutar en bucle sobre
una lista en memoria hace imposible el reintento parcial y la observabilidad.

- Cada elemento tiene **identificador de negocio único** (número de factura, de pedido), **estado**
  explícito (`pendiente`/`en curso`/`hecho`/`excepción de negocio`/`excepción de sistema`),
  **contador de intentos** y **traza**.
- **Distinguir excepción de negocio de excepción de sistema.** La primera (el cliente no existe, falta
  el documento) **no se reintenta**: va a revisión humana. La segunda (la pantalla no respondió) se
  reintenta con retroceso exponencial y un máximo. Confundirlas produce robots que reintentan 200
  veces algo que nunca funcionará, o que descartan trabajo válido.
- **Límite de reintentos y destino final explícito** (cola muerta con dueño), nunca reintento
  infinito.
- **Idempotencia obligatoria**: antes de crear algo, comprobar si ya existe por su clave de negocio.
  Un reintento **no puede** duplicar un pago, un pedido ni un asiento. Si el sistema destino admite
  clave de idempotencia, se usa; si no, se consulta antes de escribir.

### 3.3 El proceso a medio ejecutar

Es el requisito de diseño, no una mejora:

- **Punto de control tras cada paso con efecto externo**, persistido fuera del robot.
- **Compensación definida para cada paso reversible** y **frontera explícita para los irreversibles**:
  hay pasos que no se pueden deshacer (un correo enviado, un pago emitido) y el diseño debe
  concentrarlos **al final** y detrás de la validación completa.
- **Recuperación por reanudación**, no por reejecución completa: al arrancar, el robot consulta el
  estado real del sistema destino y decide, en vez de suponer que empieza de cero.
- **Cierre limpio**: ante señal de parada o ventana de mantenimiento, el robot **termina el elemento
  en curso y no coge otro**. Matar el proceso a mitad de un elemento es cómo se generan los estados
  inconsistentes que nadie encuentra hasta el cierre contable.
- **Interruptor de parada global** accesible sin desplegar nada, y **probado**. Cuando un robot
  empieza a hacer daño, el tiempo hasta pararlo es la métrica que importa.

### 3.4 Entorno de ejecución

- **El robot desatendido corre en su propia máquina o sesión**, dedicada, no en el portátil de
  nadie. La documentación de Microsoft lo dice sin rodeos: antes de registrar una máquina para
  ejecutar flujos desde la nube, *"ensure the machine is secured and the machine's admins are
  trusted"*, y al crear una conexión *"you allow Power Automate to create a Windows session on your
  machine to run your desktop flows. Make sure you trust co-owners of your flows before using your
  connection in a flow."* Traducción operativa: **quien administra esa máquina o co-posee ese flujo
  tiene, de facto, los permisos del robot.**
- **Máquina reconstruible desde código** (imagen + configuración), porque se va a corromper.
- **Atendido frente a desatendido no es solo precio**: el atendido corre con la sesión y los permisos
  de una persona presente y por tanto **hereda su identidad** —es la vía rápida al problema de §5.1—;
  el desatendido exige identidad propia y por eso es la única forma correcta de operar en producción.

## 4. Calidad y testing

Gates en orden de coste creciente:

1. **Revisión de código del robot**, con las mismas reglas que cualquier otro código
   (`code-review-standards`). Un `.xaml` es código.
2. **Análisis estático de la herramienta** (analizadores de UiPath, `robocop` para Robot Framework):
   selectores frágiles, credenciales en claro, actividades obsoletas → rompen el build.
3. **Tests de las reglas de negocio aisladas de la interfaz.** Si la lógica solo se puede probar
   pulsando botones, la arquitectura de §3.1 está mal.
4. **Entorno de preproducción con datos realistas** y ejecución completa del proceso. **PROHIBIDO
   probar en producción "porque no hay otro entorno"**: si el sistema objetivo no tiene entorno de
   pruebas, eso es un riesgo del proyecto que se escala, no una excusa.
5. **Prueba de fallo inyectado**: matar el robot a mitad de elemento, cortar la red, devolver una
   pantalla inesperada, expirar la sesión. **Verificar que el estado queda consistente y reanudable.**
   Este es el test que distingue un robot serio de una grabación.
6. **Prueba de rotación de credenciales**: rotar el secreto y comprobar que el robot sigue. Sin este
   test, la rotación se acaba desactivando "porque rompe los robots", y ahí se pierde la partida.
7. **Prueba de resistencia al cambio de interfaz**: al menos una revisión periódica contra la versión
   más reciente del sistema objetivo, y **suscripción a sus notas de versión** — que es el único aviso
   previo que vas a tener.

## 5. Seguridad del stack

### 5.1 El pecado original: la credencial del robot

El fallo estructural del dominio es un robot que corre **con la cuenta de una persona real**,
normalmente la del analista que lo construyó, con sus permisos completos, sin caducidad y sin forma
de distinguir en el registro qué hizo la persona y qué hizo el robot. Cuando esa persona cambia de
puesto o se va, o el robot desaparece o alguien "hereda" una cuenta fantasma. Es, además, la vía
directa a fraude no detectable: **el registro de auditoría del sistema destino dice que lo hizo
Juan**.

Reglas duras:

- **Identidad propia por robot y por proceso.** Cuenta de servicio nominativa (`svc-rpa-<proceso>`),
  no genérica, no compartida entre robots, no de persona. **Ni siquiera se comparte entre dos
  procesos distintos del mismo robot**: si comparten, no puedes retirar permisos de uno sin romper el
  otro.
- **Mínimo privilegio real**: los permisos del proceso, no los del analista. Y **revisión periódica**
  como cualquier otra identidad (`identity-access-management-standards`).
- **La contraseña vive en la bóveda, no en el robot ni en el orquestador en claro**: Credential Store
  de UiPath, Azure Key Vault, HashiCorp Vault, CyberArk. **Credenciales efímeras o rotación
  automática siempre que el sistema destino lo admita**; si no lo admite, rotación programada y
  documentada como riesgo aceptado.
- **El robot no puede tener MFA interactivo** — es su limitación técnica y no se resuelve
  desactivando MFA para toda la organización ni "recordando el dispositivo". Se resuelve con
  autenticación no interactiva (certificado, clave gestionada, identidad de carga de trabajo) o se
  documenta como riesgo con compensaciones (aislamiento de red, ventana horaria, límites de importe).
- **Trazabilidad**: cada acción del robot enlaza `id de proceso + id de elemento de cola + versión del
  robot + quién lo lanzó`. Auditar un proceso automatizado sin ese enlace es imposible.
- **Segregación de funciones**: quien construye el robot **no** aprueba su despliegue a producción ni
  administra su credencial. En procesos financieros esto es control, no burocracia
  (`grc-compliance-standards`).

### 5.2 Superficie del robot

- **La máquina del robot es un sistema de producción** con acceso privilegiado a sistemas de negocio:
  se endurece, se parchea y se monitoriza como tal. **PROHIBIDO** usarla como escritorio de nadie ni
  darle navegación libre.
- **Capturas de pantalla y registros con datos personales**: el robot ve nóminas, historiales y
  cuentas. Capturas solo bajo error, con retención corta, cifradas y con acceso restringido
  (`privacy-engineering-standards`).
- **Entrada no confiable**: los datos que el robot lee de correos, PDFs o pantallas son entrada de
  terceros. Se validan antes de escribirlos en ningún sitio, y **jamás se interpolan en un comando,
  una consulta o una fórmula**.
- **Límites de acción**: importe máximo, número máximo de elementos por ejecución, ventana horaria
  permitida. Un robot sin techo es una amplificación de errores a velocidad de máquina.

## 6. Rendimiento y operabilidad

- **El SLA es del proceso de negocio, no del robot.** "El robot estuvo arriba el 99 %" no dice nada;
  lo que se mide es **elementos completados dentro del plazo comprometido**.
- Métricas mínimas por proceso: elementos procesados, **tasa de excepción de negocio** y **de
  sistema** por separado, tiempo por elemento, antigüedad del elemento más viejo en cola, y
  **backlog** — que es la señal temprana de que algo va mal.
- **Alertas sobre síntomas de negocio**: "la cola crece", "cero elementos procesados en la ventana
  esperada", "la tasa de excepción supera el umbral". No sobre "el proceso no responde".
- **Silencio sospechoso**: un robot programado que **no** se ejecuta no genera errores. Alerta por
  ausencia (*dead man's switch*) obligatoria; sin ella, un robot parado pasa semanas inadvertido.
- **Vuelta al proceso manual**: para todo proceso automatizado crítico hay un procedimiento manual
  escrito y una estimación de cuánta gente hace falta. Si al automatizar se eliminó la capacidad de
  hacerlo a mano y el robot cae en cierre de mes, el problema es de negocio, no de TI.
- **Coste real por proceso**: licencia del bot, máquina, mantenimiento y **el tiempo humano de
  gestionar la cola de excepciones**, que es lo que nadie suma. Un proceso con 30 % de excepciones no
  está automatizado.

## 7. Sostenibilidad a largo plazo

### 7.1 Gobierno: el robot huérfano

**Un robot sin dueño de negocio sigue moviendo dinero.** No se para solo, no avisa y no aparece en
ningún inventario de aplicaciones. Requisitos de existencia:

- **Inventario central de robots** con: proceso, sistemas que toca, **dueño de negocio nombrado**,
  dueño técnico, identidad que usa, permisos, criticidad, fecha de última revisión y **fecha de
  caducidad**.
- **Caducidad por defecto**: todo robot se revisa al menos anualmente; si nadie lo reclama, **se
  apaga** (con periodo de gracia y aviso). Es la única forma conocida de evitar la acumulación.
- **Registro en la CMDB y en el proceso de cambio** (`itsm-itil-standards`): un cambio en un sistema
  del que depende un robot debe poder identificar ese robot **antes** del cambio.
- **Plan de salida**: para cada robot, la condición bajo la que se sustituye por integración real y
  quién la vigila. Sin esto, el "puente temporal" del justificante 4 de §1 es permanente.

### 7.2 Prohibiciones

- ❌ **PROHIBIDO** construir un robot contra un sistema que **sí** expone API, sin justificación
  escrita y aprobada.
- ❌ **PROHIBIDO** que un robot corra con la cuenta de una persona física.
- ❌ **PROHIBIDO** compartir una identidad entre varios robots o procesos.
- ❌ **PROHIBIDO** almacenar credenciales en el robot, en un fichero, en el repositorio o en el
  orquestador en claro.
- ❌ **PROHIBIDO** desactivar MFA de una organización, o excluir usuarios reales de MFA, "para que
  funcione el robot".
- ❌ **PROHIBIDO** grabar y reproducir, y prohibidos los selectores por coordenadas, por índice
  posicional o por comparación de píxeles cuando existe alternativa.
- ❌ **PROHIBIDO** un robot que no esté en control de versiones.
- ❌ **PROHIBIDO** desplegar y probar directamente en producción.
- ❌ **PROHIBIDO** un paso con efecto externo sin comprobación de idempotencia previa.
- ❌ **PROHIBIDO** reintentar una excepción de negocio, y prohibido el reintento sin máximo ni
  destino final.
- ❌ **PROHIBIDO** un proceso sin interruptor de parada probado.
- ❌ **PROHIBIDO** un robot en producción sin dueño de negocio nombrado ni fecha de revisión.
- ❌ **PROHIBIDO** usar la máquina del robot como puesto de trabajo o darle navegación libre.
- ❌ **PROHIBIDO** capturar pantallas con datos personales fuera de un error, sin cifrado y sin
  retención acotada.
- ❌ **PROHIBIDO** justificar un programa de RPA con cifras de ahorro de FTE del fabricante. **Las
  cifras del tipo "la RPA ahorra un X % de FTE" son material comercial sin metodología publicada.** Si
  hay que justificar la inversión, se mide **el proceso concreto antes y después**, contando la cola
  de excepciones y el mantenimiento; si no se ha medido, se dice que no se ha medido.
- ❌ **PROHIBIDO** llamar "automatizado" a un proceso cuyo porcentaje de excepciones manuales no se
  publica.

### 7.3 Cuando el robot es un LLM

Un agente que "usa el ordenador" (pulsa botones, lee pantallas) **es RPA**, y por tanto hereda todo
lo anterior: identidad propia, bóveda, mínimo privilegio, cola, idempotencia, límites, trazabilidad,
interruptor de parada. **Y añade dos problemas que la RPA clásica no tiene**:

1. **No determinismo**: la misma pantalla puede producir dos acciones distintas. Todo lo que en RPA
   clásica se prueba una vez, aquí hay que probarlo estadísticamente
   (`llm-evaluation-standards`).
2. **Inyección de prompt indirecta**: el texto de la pantalla que el agente lee **es entrada del
   atacante**. Un correo, un PDF o un campo de un formulario pueden contener instrucciones. Con
   credenciales de negocio y acceso a sistemas transaccionales, esto es la tríada letal completa.

Consecuencia operativa, no filosófica: **aprobación humana obligatoria antes de cualquier acción
irreversible o con impacto económico**, sin excepción, y límites de importe y de volumen impuestos
**fuera** del agente. El diseño del bucle, sus topes y su *sandbox* son de `ai-agents-standards`; que
además cumpla lo de aquí, no es opcional.

## 8. Verificación web obligatoria

- **Modelos de precio, que cambian y son la mitad de la decisión**: página oficial de precios de
  Power Automate (a ago-2026, lista: **Premium $15 usuario/mes**, **Process $150 bot/mes**, **Hosted
  Process $215 bot/mes**), de UiPath (*Basic* desde ~**$25/mes** con 2 robots; el resto "contact
  sales"). **Huecos declarados: no se pudo obtener el modelo de precio ni las condiciones de licencia
  de Automation Anywhere ni de SS&C Blue Prism** desde fuentes públicas (una devolvió 404 y la otra
  no resolvió). Antes de compararlos, exigir la oferta por escrito al fabricante y **verificar si el
  precio es por robot concurrente, por proceso o por ejecución** — la diferencia decide el TCO.
- **Licencias leídas en crudo**, no por la etiqueta de GitHub: Robot Framework **Apache-2.0**
  (`LICENSE.txt`), Playwright **Apache-2.0** (`LICENSE`), Temporal **MIT** (`LICENSE`), Airflow
  **Apache-2.0** (`LICENSE`), y **Camunda: `Camunda License 1.0`, *source-available* y no OSI** —
  releerla antes de asumir nada, porque condiciona el uso en producto.
- **Versión y soporte** de la herramienta de RPA elegida, y **su matriz de compatibilidad con la
  versión del sistema objetivo** (navegador, ERP, emulador). Es la causa número uno de rotura tras
  una actualización.
- **Notas de versión del sistema objetivo**: suscripción obligatoria; es el único aviso previo de que
  la interfaz va a cambiar.
- **CVEs** del orquestador y del *runtime* del robot: son sistemas con credenciales de negocio, no
  herramientas de escritorio.
- Estado actual de las capacidades de "uso del ordenador" de los modelos y de sus guías de seguridad
  antes de proponer un agente para un proceso transaccional.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
