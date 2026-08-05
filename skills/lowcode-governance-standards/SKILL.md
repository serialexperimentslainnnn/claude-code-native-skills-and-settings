---
name: lowcode-governance-standards
description: Governance of low-code and no-code platforms - shadow IT, ownership, data policies and the cost that shows up later. Use when working with Microsoft Power Platform (Power Apps, Power Automate cloud and desktop flows, Microsoft Dataverse, Copilot Studio, Power Pages), the tenant default environment, environment strategy and environment groups, managed environments, Power Platform data policies / DLP connector groups (Business, Non-Business, Blocked), premium and custom connectors, connection references and orphaned flows when the owner leaves, solutions and solution-aware ALM, the CoE Starter Kit and application inventory, Power Platform admin center and Get-AdminFlow / Set-AdminFlowOwnerRole PowerShell cmdlets, OutSystems, Mendix, Appian, Retool, n8n, Zapier or Airtable adoption, citizen developer programmes and maker enablement, an app built by a business team that 200 people now depend on, per-user versus per-app versus per-task versus consumption licensing and premium connector price jumps, or deciding when a low-code app must be rewritten as real software.
---

# Estándares de gobierno de low-code / no-code

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Gobierno de plataformas de desarrollo con poco o ningún código: quién puede construir, dónde, con qué
datos, con qué credenciales, quién responde después y qué cuesta cuando ya dependes.

Triggers: Power Platform (Power Apps, Power Automate, Dataverse, Copilot Studio, Power Pages),
*default environment*, entornos y grupos de entornos, *managed environments*, políticas de datos /
DLP y sus grupos de conectores, conectores *premium* y personalizados, referencias de conexión,
flujos huérfanos, soluciones y ALM, CoE Starter Kit, `Get-AdminFlow`/`Set-AdminFlowOwnerRole`,
OutSystems, Mendix, Appian, Retool, n8n, Zapier, Airtable, *citizen developer*, *shadow IT*.

**Tesis de la skill, y todo lo demás se deriva de ella: el problema del low-code no es técnico, es de
gobierno.** La plataforma funciona; lo que falla es que **nadie sabe qué existe, con la identidad de
quién corre, quién lo mantiene y qué costará el año que viene**. Un error de código produce una
excepción; un error de gobierno produce una aplicación crítica sin dueño, un conector con las
credenciales de alguien que ya no trabaja aquí y una factura que se descubre en la renovación.

Corolario falsable, aplicable a cualquier programa de *citizen development* que te presenten:
**enséñame el inventario.** Si no existe una lista de aplicaciones y automatizaciones con dueño
nombrado, criticidad y última revisión, no hay programa de low-code: hay *shadow IT* con logo
corporativo. Segundo corolario, incómodo: **prohibirlo no es una estrategia de gobierno** — solo
mueve la actividad a hojas de cálculo con macros y a cuentas personales de SaaS, donde no ves nada.

**No aplica**: ver `ai-governance-standards` (**frontera crítica y muy transitada**: **suyos** el
inventario de sistemas de IA, la clasificación por riesgo del AI Act, el reparto proveedor/desplegador,
la supervisión humana, la transparencia y el incidente grave. **Mío**, cuando ese agente vive dentro
de una plataforma low-code: **dónde se despliega, con qué identidad se ejecuta, a qué conectores
llega, quién es su dueño y qué consume**. Regla de arbitraje: *si la pregunta es si ese agente puede
existir y bajo qué obligaciones, es suya; si es en qué entorno vive, con qué credencial corre y quién
lo mantiene, es de aquí*. **Los dos inventarios se referencian, no se duplican**),
`enterprise-architecture-standards` (**recíproca dura**: el **inventario corporativo de aplicaciones**
con dueño, criticidad y ciclo de vida es suyo, y es el destino natural de lo que se promociona desde
aquí. Una app low-code que pasa a crítica **entra en su inventario**; el catálogo de las que siguen
siendo herramienta personal se queda aquí), `itsm-itil-standards` (el servicio, el SLA y el proceso
de cambio cuando la app ya es un servicio soportado), `identity-access-management-standards`
(identidad, SSO, cuentas de servicio y el ciclo joiner-mover-leaver — **aquí el efecto concreto de la
baja de un empleado sobre una conexión**, §3.3), `secrets-management-standards` (custodia y rotación
de credenciales), `privacy-engineering-standards` (dato personal, minimización, retención y borrado
en apps ciudadanas), `accessibility-standards` (criterio técnico WCAG y su verificación; aquí solo la
**obligación de que aplique también a lo que hace negocio**), `grc-compliance-standards` (marco de
control, riesgo y evidencia de auditoría), `finops-standards` (método de coste por unidad económica;
aquí el **modelo de licencia** y sus saltos), `crm-salesforce-standards` (Salesforce como plataforma
configurable tiene su propio documento: Flow, permisos, límites de gobernador y paquetes),
`erp-sap-standards` (**aviso recíproco relevante**: un flujo low-code que crea documentos en SAP
dispara **acceso indirecto** y se factura — se valora allí **antes** de construirse aquí),
`opensource-licensing-standards` (**frontera de método**: allí SPDX, copyleft y el gate en el PR;
aquí licencias **comerciales de plataforma**. Punto de contacto real: **n8n no es software libre OSI**
—Sustainable Use License, *fair-code*— y esa distinción se resuelve con su método, §3.6),
`cicd-standards` (el pipeline; aquí qué se promociona y desde dónde),
`refactoring-tech-debt-standards` (deuda técnica general; aquí el criterio de reescritura, §3.7).

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): licencias, cuotas y nombres de producto de estas
> plataformas cambian **varias veces al año**, y los precios de las de gama empresarial **no se
> publican**.

| Decisión | Por defecto | Nota |
|---|---|---|
| Entorno por defecto del tenant | **Restringido y renombrado**, nunca producción | §3.2 |
| Dónde construye un *maker* nuevo | **Su propio entorno de desarrollo**, no el default | §3.2 |
| Creación de entornos | **Restringida a administración** | §3.2 |
| Políticas de datos (DLP) | **Default-deny**: todo conector nuevo, bloqueado hasta clasificar | §3.4 |
| Identidad de ejecución de algo compartido | **Cuenta de servicio / principal de servicio**, jamás una persona | §3.3 |
| Inventario | **Obligatorio y automatizado**, con dueño nombrado por artefacto | §3.5 |
| Clasificación | Personal / departamental / **crítica**, con criterios escritos | §3.5 |
| App crítica | ALM real: soluciones, entornos separados, control de versiones | §3.7 |
| Edición en producción | **Prohibida** para lo clasificado como crítico | §3.7 |
| Conector personalizado | Revisión de seguridad antes de publicar en el tenant | §3.4 |
| Dato personal en app ciudadana | Requiere revisión previa; no es decisión del *maker* | §3.8 |
| Coste | Modelado **antes** de depender, con el escenario de éxito | §3.6 |

## 3. Estructura y convenciones

### 3.1 Lo que hace distinto a este dominio

Tres propiedades cambian el problema respecto a software normal, y conviene tenerlas explícitas:
1. **El constructor no es de TI y no tiene por qué serlo.** Cualquier control que exija que lo sea,
   fracasa: lo esquivan o dejan de usar la plataforma.
2. **El artefacto no es un fichero.** No hay repositorio por defecto, ni PR, ni `grep`. Si no lo
   inventarías con la API de administración, **no existe para ti** aunque exista para 200 personas.
3. **La identidad de ejecución es la de una persona por defecto.** Ese es el pecado original del
   dominio y el origen de casi todos los incidentes (§3.3).

### 3.2 El *default environment*: abierto por diseño

Datos verificados verbatim en la documentación de Microsoft (ago-2026, §8), porque es el punto que
más se malinterpreta:
- *"Each tenant has a default environment that's created automatically."* — **existe ya, lo mires o no.**
- *"All licensed users have the environment maker role"* — y la lista de "licenciados" incluye
  usuarios de **Microsoft 365** y licencias gratuitas o de prueba. En la práctica: **toda tu empresa
  es *maker* ahí**.
- *"Whenever a new user signs up for Power Apps, they're automatically added to the Maker role of the
  default environment. No users are automatically added to the Environment Admin role"* — **nadie
  administra por defecto**.
- *"This is a predefined type of environment intended for experimentation, exploration, and
  lightweight, app trial development. The default environment doesn't provide any backup guarantees
  and shouldn't be used for production workloads."* — lo dice el fabricante. Aun así **es donde
  aparece la mitad de lo crítico**, porque es donde el botón lleva por defecto.
- *"You can't delete the default environment. You can't manually back up the default environment"* —
  **no puedes hacerlo desaparecer**: solo puedes gobernarlo.
- Capacidad incluida: **3 GB de base de datos Dataverse, 3 GB de ficheros, 1 GB de logs**, con tope de
  **1 TB** de almacenamiento en el entorno.

**Acciones mínimas, y son el primer día del programa:**
1. **Renombrarlo** a algo que diga lo que es (Microsoft sugiere literalmente algo como *Personal
   Productivity Environment*). El nombre es un control: comunica que no es producción.
2. **Asignar administradores nominales** —Microsoft advierte del riesgo de bloqueo administrativo si
   nadie tiene el rol de administrador del sistema—, y hacerlo con unos pocos usuarios de confianza.
3. **Aplicar la política de datos más estricta del tenant** ahí (§3.4).
4. **Restringir la creación de entornos** a administración, y **dar a cada *maker* su entorno de
   desarrollo**: no se pide que dejen de construir, se les da otro sitio mejor.
5. **Inventariar lo que ya hay dentro** (§3.5) antes de tocar nada: es donde están las sorpresas.
6. Diseñar la **arquitectura de entornos** —desarrollo / pruebas / producción por dominio, con grupos
   de entornos y reglas— para lo que se promociona (§3.7).

### 3.3 La identidad de ejecución: el conector con las credenciales de quien se va

**El mecanismo, verificado (documentación de Microsoft, verbatim):** *"When a maker first adds a
connector to an app, they establish a connection by using the authentication protocols that the
connector supports. These connections represent a saved credential and are stored within the
environment that hosts the app or flow."* Traducido: **la automatización guarda la credencial de una
persona y actúa como esa persona**, con todos sus permisos, indefinidamente.

Las dos caras del mismo fallo:
- **Mientras la persona está**: el flujo tiene los permisos de un humano, no los que necesita. Un
  administrativo con acceso amplio construye un flujo que, de hecho, expone ese acceso amplio a
  cualquiera con quien comparta la app. Es escalada de privilegios sin exploit.
- **Cuando la persona se va**: el flujo queda **huérfano**. Microsoft lo documenta con ese nombre —
  *"An orphaned flow is a flow that no longer has a valid owner. These flows can fail if they use
  connections tied to that user account."* La consecuencia operativa que nadie ensaya: **la nómina,
  la conciliación o el aviso al cliente dejan de ejecutarse el día que RRHH desactiva la cuenta**, y
  el diagnóstico tarda semanas porque nadie sabía que ese proceso era un flujo.

**Controles, en orden de eficacia:**
1. **Cualquier automatización de la que dependa alguien más que su autor corre con una cuenta de
   servicio o un principal de servicio.** No es una recomendación: es la condición para clasificarla
   por encima de "personal" (§3.5).
2. **Co-propietario obligatorio** —mínimo dos— en todo lo compartido. Es el mínimo barato.
3. **El proceso de baja de empleado incluye el barrido de la plataforma.** Se detecta con la API de
   administración: en Power Platform, `Get-AdminFlow` + `Get-AdminFlowOwnerRole` contra el directorio,
   y `Set-AdminFlowOwnerRole` para reasignar. Automatizado y **ejecutado antes** de la baja, no
   después. Un *leaver* que se descubre por un flujo caído es un fallo del proceso de identidad
   (`identity-access-management-standards`), y esta es su manifestación más cara.
4. **Reasignar dueño no arregla la conexión**: la credencial es del usuario y hay que **rehacer la
   conexión**. Contar con ello en el runbook.
5. **Conectores personalizados y credenciales**: nunca secretos incrustados en la definición;
   custodia según `secrets-management-standards`.

### 3.4 Políticas de datos (DLP): control real, con límites reales

**Cómo funcionan** (documentación de Microsoft, ago-2026): las políticas clasifican **conectores** en
grupos —negocio, no-negocio y bloqueados— y **un artefacto no puede combinar conectores de grupos
distintos**. Es un control de **superficie**, y es efectivo: impide construir el puente entre el
sistema corporativo y el destino personal.

**Lo que hay que saber para no sobreestimarlo — y esto decide el diseño del control:**
- **Clasifica conectores, no datos.** No inspecciona contenido: si dos conectores están en el mismo
  grupo, mover datos entre ellos es legítimo para la política aunque sea una fuga.
- **Diseño y ejecución son dos momentos distintos.** En diseño el *maker* no puede guardar; en
  ejecución, lo ya construido pasa a **suspendido/cuarentena** y las conexiones bloqueadas a
  **deshabilitadas**. Es decir: **una política nueva rompe automatizaciones existentes**. Se
  introduce midiendo el impacto primero, con aviso y ventana — o produce una caída autoinfligida.
- **La aplicación no es inmediata**: verbatim, *"For the most extreme cases, the latency for full
  enforcement is 24 hours. In most cases, it's within an hour."* **No es un control en tiempo real
  y no sirve como respuesta a incidente.**
- **Hay conectores que no se pueden bloquear** (*nonblockable*), y existen conectores "virtuales" que
  gobiernan funciones y no APIs, con reglas propias en evolución. **Verifica cuáles antes de asumir
  que tu política cubre todo.**
- **El conector personalizado es la puerta lateral**: permite llegar a cualquier API. Su publicación
  a nivel de tenant se revisa como un cambio de seguridad, no como una configuración.

**Postura por defecto**: **default-deny** — conector nuevo, bloqueado hasta que alguien lo clasifique;
política estricta en el entorno por defecto y en los de desarrollo; políticas por entorno/grupo para
lo productivo, con excepciones **nominales, motivadas y con caducidad**.

### 3.5 Inventario, dueño y criticidad: el núcleo del gobierno

**Sin inventario no hay gobierno, y el inventario tiene que ser automático.** Se construye desde la
API de administración de la plataforma (en Power Platform, el CoE Starter Kit es la vía habitual y de
Microsoft, pero es **una solución de código abierto que tú operas y mantienes**, no un producto con
soporte: trátalo como una aplicación interna con dueño). Campos mínimos por artefacto: **dueño
nombrado y suplente, propósito en una frase, entorno, conectores y sistemas que toca, número de
usuarios reales, dato personal sí/no, criticidad, fecha de última revisión**.

**Clasificación, con criterios escritos y consecuencias distintas:**

| Nivel | Definición operativa | Qué se le exige |
|---|---|---|
| **Personal** | Un solo usuario, sin dato sensible, sin impacto si se cae | Nada. Se tolera y no se molesta al autor |
| **Departamental** | Varios usuarios de un área; su caída molesta pero no para el negocio | Dueño y suplente, co-propiedad, inventario, revisión anual |
| **Crítica** | Otros dependen para operar, o toca dato personal/financiero/regulado | ALM real, cuenta de servicio, respaldo, soporte, ver §3.7 |

**El disparador que nadie vigila y hay que vigilar: el crecimiento.** La app que hizo alguien de
finanzas para sí y de la que hoy dependen 200 personas **cambió de categoría sin que nadie lo
decidiera**. Regla dura: **el número de usuarios y la criticidad se revisan periódicamente de forma
automática, y un salto de umbral abre un ticket**, no un correo. La pregunta "¿quién mantiene esto?"
tiene que hacerse **antes** de que la respuesta sea "nadie, se fue".

**Ciclo de vida completo, o el inventario se pudre:** alta con dueño → uso medido → revisión periódica
(¿sigue usándose? ¿sigue teniendo dueño?) → **retirada**. Lo que nadie usa en un trimestre se
desactiva tras aviso; lo desactivado que nadie reclama, se borra. Sin retirada, un inventario es una
lista que crece hasta ser inútil.

### 3.6 El coste que aparece después

**El patrón del dominio: barato para empezar, caro cuando ya dependes.** El punto de decisión honesto
es **antes** de construir, modelando el **escenario de éxito** (¿y si lo usan 500 personas?), no el
piloto de diez.

Precios de Microsoft verificados verbatim en `microsoft.com` (ago-2026, §8):
- **Power Apps Premium**: *"$20.00 user/month, paid yearly"*, con **250 MB de base de datos y 2 GB de
  fichero** en Dataverse. Con mínimo de 2 000 asientos, *"$12.00 user/month, paid yearly"*.
- **Power Apps Developer Plan**: *"Free"*, **2 GB de base de datos**, **750 flujos al mes** — es plan
  de desarrollo, **no** de producción.
- **Power Automate Premium**: *"$15.00 user/month, paid yearly"*, incluye RPA **atendida**.
  **Power Automate Process**: *"$150.00 bot/month"*, RPA **desatendida**. **Hosted Process**:
  *"$215.00 bot/month"*, con máquina virtual gestionada.
- **Copilot Studio**: *"sold as tenant-wide license which includes Copilot Credit capacity packs of
  25,000 Copilot Credits each, priced at $200.00/pack/month"*, y *"Whenever an action or response is
  completed by an agent, a varying number of Copilot Credits will be billed depending on the specific
  usage"*. **Traducción de gobierno: el consumo por interacción es variable y no lo controla el
  presupuesto, lo controla el diseño del agente.** Un agente mal diseñado multiplica el coste sin
  cambiar de funcionalidad — presupuestar por número de usuarios es un error de método.

**El salto que descubres tarde, y merece nombre propio: los conectores *premium*.** Lo que se
construye con conectores estándar sale con la licencia que ya tienes; en cuanto la app toca un
conector *premium* —bases de datos, muchos SaaS, HTTP genérico, conectores personalizados—
**cada usuario de esa app necesita licencia de pago**. La regla operativa que evita el desastre:
**la decisión de usar un conector premium se toma con la cuenta hecha de usuarios finales**, no como
detalle técnico del *maker*. Es exactamente el mismo error, con otro nombre, en todas las plataformas.

**Los otros modelos de metering, para reconocer el patrón** *(vía búsqueda web; salvo Microsoft y n8n,
**ninguna de estas cifras está verificada contra la fuente del fabricante** — OutSystems y Appian **no
publican precios**: "no publicado" es el dato)*:

| Plataforma | Se factura por | Dónde salta el coste |
|---|---|---|
| Power Platform | Usuario + capacidad + créditos de IA | Conector premium, capacidad de Dataverse, créditos |
| OutSystems | Aplicación (objetos de aplicación) + usuarios; **cotizado** | La complejidad de la app sube de tramo sin más usuarios |
| Mendix | Híbrido: usuario **y** unidades de capacidad por app | Consumo de capacidad y *true-ups* anuales |
| Appian | Usuario **por aplicación**; **cotizado** | Multiplicar aplicaciones |
| Retool | Asiento por rol (constructor / interno / externo) + ejecuciones | Cada constructor nuevo; cuotas de ejecución |
| Zapier | **Tarea ejecutada**, no usuario | Un flujo de muchos pasos y alto volumen |
| Airtable | **Editor** (los lectores no cuentan) + créditos + automatizaciones | Umbral de registros que fuerza subir de plan |

**Y la licencia, no solo el precio**: **n8n no es software libre según la OSI**. Su `LICENSE.md`
(verificado en crudo) es la **Sustainable Use License** —*fair-code*—: concede uso *"for your own
internal business purposes or for non-commercial or personal use"*, prohíbe la distribución comercial
y **segrega las funciones *enterprise*** (ficheros y directorios con `.ee`) bajo licencia aparte.
Autohospedarlo **no** te libera de condiciones. Si alguien lo mete en el catálogo como "open source",
corrígelo: el análisis de la cláusula es de `opensource-licensing-standards`.

**Regla transversal de coste, y es la única que funciona: el modelo de licencia se documenta en la
ficha de inventario del artefacto** (§3.5), con el coste marginal de un usuario más. La renovación se
prepara **seis meses antes** con consumo medido, asientos realmente usados y lista de lo que nadie usa.

### 3.7 ALM real, y cuándo dejar de usar low-code

**Para lo clasificado como crítico, ALM real y sin excepciones:** entornos separados de desarrollo,
pruebas y producción; el artefacto empaquetado (en Power Platform, **soluciones** con referencias de
conexión y variables de entorno, para que la promoción no arrastre credenciales ni URLs de
desarrollo); exportación al control de versiones; despliegue automatizado; y **producción sin edición
manual**. "Editar en producción" es la práctica que hace que ningún entorno inferior represente la
realidad, y a partir de ahí ninguna prueba significa nada. La mecánica del pipeline es de
`cicd-standards`; **la regla de que exista es de aquí**.

Lo que casi nunca se hace y debe hacerse: **respaldo y prueba de restauración** del artefacto y de sus
datos, y **pruebas** —aunque sean una lista de comprobación manual firmada— para lo crítico. Ojo: el
entorno por defecto **no ofrece garantías de respaldo**, y eso lo dice el fabricante (§3.2).

**Criterio para reescribir como software de verdad.** No es "el low-code es peor": es que hay señales
que indican que el coste de quedarse ya supera al de salir. **Dos o más de estas → se planifica la
reescritura**:
- La lógica ya no cabe: docenas de pasos, condiciones anidadas y nadie puede razonar el flujo.
- **No se puede probar** de forma automática y su fallo tiene consecuencias reales.
- El **rendimiento o el volumen** chocan con los límites de la plataforma de forma recurrente.
- El **coste de licencia** por usuario supera al de construirlo y operarlo (haz la cuenta con años,
  no con meses).
- La necesita gente **fuera** de la organización, o es cara al cliente.
- **Riesgo de proveedor**: quedas atado a un motor propietario del que no hay salida documentada.
- Ya la mantiene TI en la práctica, con lo que el ahorro que justificaba el low-code **ya no existe**.

**Y el criterio simétrico, que se olvida**: si no se cumple ninguna, **reescribir es destruir valor**.
La aplicación de tres pantallas que resuelve un problema real de un departamento no necesita
convertirse en un microservicio. La respuesta correcta muchas veces es **adoptarla como está**:
ponerle dueño, cuenta de servicio, respaldo y una línea en el inventario.

### 3.8 Datos personales y accesibilidad en apps ciudadanas

- **El *maker* no decide sobre dato personal.** Cualquier artefacto que trate datos personales pasa por
  revisión previa: base jurídica, minimización, retención y borrado (`privacy-engineering-standards`).
  El caso típico y prohibido: extraer un listado con datos de empleados o clientes a un fichero
  personal "para trabajar con él".
- **Retención y borrado también aplican al historial de ejecución** de las automatizaciones y a los
  datos que se quedan en la plataforma. Se define al alta, no cuando llega el DSAR.
- **Accesibilidad**: si la app la usa personal propio o público, **las obligaciones de accesibilidad
  aplican igual** — que la haya hecho alguien de finanzas con un asistente no cambia la norma. La
  plantilla corporativa y una lista de comprobación mínima son el control barato;
  el criterio técnico es de `accessibility-standards`.
- **Agentes y copilotos dentro de la plataforma**: entran en el inventario de IA y en la clasificación
  de riesgo de `ai-governance-standards`. Lo que se exige aquí: entorno, identidad de ejecución,
  conectores alcanzables, dueño y consumo (§3.3, §3.6).

## 4. Controles y verificación

En orden de coste creciente. Los tres primeros son la línea de base de cualquier programa:
1. **Inventario automatizado y actualizado** de todo artefacto, entorno, conector personalizado y
   conexión, con dueño (§3.5). Sin esto, ningún control siguiente tiene alcance enumerable.
2. **Barrido de huérfanos** programado, cruzando propietarios contra el directorio (§3.3), integrado
   con el proceso de baja de empleado.
3. **Política de datos aplicada** con inventario previo de impacto y ventana de aviso (§3.4).
4. **Revisión de artefactos críticos**: que tengan cuenta de servicio, co-propietario, respaldo,
   entorno productivo propio y una prueba documentada.
5. **Revisión de conectores personalizados** publicados a nivel de tenant, como cambio de seguridad.
6. **Medición de consumo y coste** por entorno y por artefacto, con alerta antes del umbral (§3.6).
7. **Auditoría trimestral**: artefactos sin uso, sin dueño, con permisos amplios o compartidos con
   "toda la organización" — este último es el equivalente aquí de un bucket público.

## 5. Seguridad

- **Compartir con "todos los de la organización"** es una decisión de seguridad y se trata como tal:
  se registra, se revisa y por defecto se desaconseja.
- **Los permisos del *maker* son los permisos del artefacto** (§3.3). Un flujo no puede acceder a
  menos de lo que accede su credencial: **el mínimo privilegio se implementa en la cuenta de servicio**,
  no en el diseño del flujo.
- **Exfiltración por conector**: el escenario canónico es correo o almacenamiento personal en el
  mismo grupo que un sistema corporativo. Es exactamente lo que las políticas de §3.4 existen para
  cortar, y por eso su clasificación no puede ser laxa.
- **Registro de auditoría** de la plataforma activado y retenido, con quién creó, compartió y ejecutó
  qué. Verifica si tu licencia lo incluye: **en varias plataformas la auditoría fina es un nivel
  superior de precio** — y descubrirlo durante un incidente es tarde.
- **Portales y sitios públicos** construidos con estas plataformas son aplicaciones expuestas a
  Internet: modelado de amenazas y revisión previa obligatorios (`appsec-standards`). Que se hayan
  hecho con el ratón no cambia su superficie de ataque.
- **Secretos**: nunca en variables visibles, en el cuerpo del flujo ni en la definición de un conector
  personalizado.

## 6. Operabilidad

- **Lo crítico necesita alerta y guardia.** Un flujo que falla silenciosamente y nadie mira es un
  incidente diferido. Mínimo: notificación de fallo a un buzón de equipo (**no a una persona**) y
  panel de ejecuciones fallidas revisado.
- **Runbook mínimo por artefacto crítico**: qué hace, de qué depende, qué hacer si falla, a quién
  avisar. Cabe en una página; su ausencia es lo que convierte una caída en tres días de arqueología.
- **Reintentos y volumen**: una automatización que reintenta en bucle contra un sistema corporativo es
  a la vez una caída y una factura (de tareas, de créditos o de acceso indirecto).
- **Límites de servicio de la plataforma** (peticiones por conexión, tamaño, concurrencia): se
  verifican antes de diseñar algo de alto volumen. Si el diseño depende de estar justo por debajo de
  un límite, el diseño está mal.

## 7. Sostenibilidad y prohibiciones

- ❌ **PROHIBIDO** que una automatización de la que dependa más de una persona corra con la credencial
  personal de alguien.
- ❌ **PROHIBIDO** un artefacto compartido sin dueño nombrado, suplente e inventario. Sin dueño, se
  desactiva tras aviso.
- ❌ **PROHIBIDO** usar el **entorno por defecto** como producción. Lo dice el fabricante y no ofrece
  garantías de respaldo.
- ❌ **PROHIBIDO** dejar el entorno por defecto sin política de datos estricta y sin administradores
  nominales.
- ❌ **PROHIBIDO** desplegar una política de datos sin medir antes qué artefactos rompe: **suspende lo
  existente**, y con hasta 24 h de latencia.
- ❌ **PROHIBIDO** editar en producción un artefacto clasificado como crítico.
- ❌ **PROHIBIDO** tratar dato personal en una app ciudadana sin revisión previa, y **prohibido** copiar
  datos de producción a un entorno de pruebas sin enmascarar.
- ❌ **PROHIBIDO** usar un conector *premium* o personalizado sin la cuenta hecha del coste por usuario
  final y sin revisión de seguridad del conector.
- ❌ **PROHIBIDO** publicar un conector personalizado a nivel de tenant sin revisión.
- ❌ **PROHIBIDO** prohibir el low-code sin ofrecer alternativa: empuja la actividad a donde no la ves.
- ❌ **PROHIBIDO** citar cifras de productividad de low-code ("X veces más rápido", "10× menos código")
  como argumento de decisión. **Son cifras de marketing del fabricante, sin metodología ni muestra
  publicadas, y comparan un piloto contra un desarrollo completo.** Lo defendible se mide en tu casa:
  tiempo hasta el primer uso real y coste total a tres años, incluidos licencia, mantenimiento y la
  reescritura si llega (§3.7). El catálogo ya ha desmontado el mismo patrón con el CHAOS Report
  (`project-management-standards`) y con las tasas de fracaso de ERP (`erp-sap-standards`).
- ❌ **PROHIBIDO** declarar "tenemos gobierno de low-code" sin poder enseñar el inventario con dueños y
  la fecha de la última revisión.
- **Cadencia**: inventario continuo, barrido de huérfanos en cada baja de empleado, revisión de
  criticidad y de uso trimestral, revisión de políticas de datos y conectores nuevos trimestral
  (las plataformas **añaden conectores constantemente**, y un conector nuevo sin clasificar es un
  agujero por omisión), y revisión de contrato seis meses antes de la renovación.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento:

1. **Entorno por defecto y tipos de entorno**: verificado verbatim en
   `learn.microsoft.com/power-platform/admin/environments-overview` (ago-2026). Comprueba capacidades
   incluidas y roles, que Microsoft cambia sin previo aviso.
2. **Políticas de datos**: verificado verbatim en `learn.microsoft.com/power-platform/admin/wp-data-loss-prevention`.
   **Verifica en particular la lista de conectores *no bloqueables* y el estado de los conectores
   virtuales y de las *advanced connector policies*, que estaban en transición en ago-2026.**
3. **Flujos huérfanos**: procedimiento y cmdlets verificados en el fuente en crudo del artículo de
   soporte de Microsoft (`SupportArticles-docs`, `manage-orphan-flow-when-owner-leaves-org.md`,
   fecha del documento 11-jun-2026). **Aviso**: el ejemplo oficial usa el módulo AzureAD, que está
   **en desuso** — reescríbelo contra Microsoft Graph antes de usarlo.
4. **Precios de Microsoft**: verificados verbatim en `microsoft.com` (Power Apps, Power Automate,
   Copilot Studio) en ago-2026. Cambian, y el modelo de Copilot Studio migró de "mensajes" a
   "créditos": **verifica el nombre y la unidad vigentes antes de presupuestar**.
5. **Precios del resto de plataformas**: **hueco declarado.** Las cifras de OutSystems, Mendix,
   Appian, Retool, Zapier y Airtable de §3.6 provienen de **búsqueda web y páginas de terceros**, no
   de la fuente del fabricante; **OutSystems y Appian no publican precios** y solo cotizan. Úsalas
   para reconocer el **modelo de metering**, nunca como cifra en un presupuesto.
6. **Licencia de n8n**: verificada en crudo (`LICENSE.md` del repositorio). Re-léela antes de
   desplegar: es *fair-code*, no OSI, y **han cambiado los términos en el pasado**.
7. **Estado de los productos**: retiradas, renombrados y cambios de empaquetado. En este dominio los
   nombres cambian cada pocos trimestres y los límites de servicio con ellos.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
