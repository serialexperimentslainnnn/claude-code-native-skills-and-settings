---
name: crm-salesforce-standards
description: Salesforce and configurable business SaaS - governor limits as an architectural constraint, clicks versus code, and licence cost as a design input. Use when working with Apex classes and triggers (.cls, .trigger), Lightning Web Components (.js-meta.xml, lwc/ directories), Visualforce, Flow Builder and .flow-meta.xml, Process Builder or Workflow Rule end of support and Migrate to Flow, SOQL and SOSL, Apex governor limits (100 SOQL, 150 DML, 10000 ms CPU, 6 MB heap) and bulkification, custom objects and __c / __r fields, record types, validation rules, profiles, permission sets and permission set groups, organization-wide defaults, role hierarchy, sharing rules and Apex managed sharing, WITH USER_MODE, WITH SECURITY_ENFORCED, Security.stripInaccessible and without sharing classes, sfdx-project.json, package.xml, Metadata API, Salesforce CLI (sf project deploy), scratch orgs, unlocked and managed packages, sandbox types and refresh intervals, change sets, AppExchange package due diligence and the security review, Salesforce API request allocations per edition, data and file storage allocations, Sales Cloud or Service Cloud edition pricing, or a Salesforce renewal negotiation.
---

# Estándares de CRM Salesforce y SaaS de negocio configurable

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Salesforce como **plataforma multi-inquilino configurable**: los límites que impone y que no se
negocian, el criterio de configuración frente a código, el modelo de datos y su coste, la seguridad
de registro y de campo —que es donde se filtran los datos—, el gobierno de entornos y despliegue, la
*due diligence* de un paquete de AppExchange, y **la licencia y el coste como entrada de diseño, no
como partida de compras**.

Triggers: `.cls`, `.trigger`, `lwc/`, `.js-meta.xml`, Visualforce, Flow Builder, `.flow-meta.xml`,
Migrate to Flow, SOQL/SOSL, límites de gobernador, *bulkification*, objetos y campos `__c`/`__r`,
tipos de registro, reglas de validación, perfiles, conjuntos de permisos y grupos de conjuntos,
OWD, jerarquía de roles, reglas de compartición, `WITH USER_MODE`, `WITH SECURITY_ENFORCED`,
`Security.stripInaccessible`, `without sharing`, `sfdx-project.json`, `package.xml`, Metadata API,
`sf project deploy`, *scratch orgs*, paquetes desbloqueados y gestionados, *sandboxes* y su intervalo
de refresco, *change sets*, AppExchange, cuota de API por edición, almacenamiento de datos y de
ficheros, ediciones y renovación.

**Tesis de la skill: en Salesforce no eliges tu arquitectura, eliges cómo vives dentro de la de
otro.** Los límites de gobernador, el calendario de tres releases al año, el modelo de compartición y
la lista de precios son constantes externas. Todo el diseño consiste en **acomodarse a ellas antes de
construir**, porque descubrirlas después no produce un refactor: produce un rediseño con datos ya en
producción. Corolario que ordena el documento: **cualquier decisión que multiplique registros,
llamadas a API, almacenamiento o asientos es una decisión de coste**, y el coste se estima en el
diseño, no en la factura.

**No aplica**: ver `api-design-standards` (**frontera dura**: el **contrato** de la integración —
OpenAPI, versionado, paginación, `Idempotency-Key`, formato de error, firma de webhook. Aquí solo
**cuánto consume ese contrato de tu cuota** y qué límite de plataforma lo rompe),
`identity-access-management-standards` (SSO/SAML/OIDC, MFA, aprovisionamiento SCIM, ciclo
joiner-mover-leaver. Aquí la **autorización dentro de la org** —perfiles, permisos, compartición— que
es cosa distinta: quién entra es suyo, qué ve una vez dentro es de aquí), `cicd-standards` (el
*pipeline*, sus *gates*, OIDC y firma de artefacto. Aquí **qué se despliega y desde dónde**, y por qué
un cambio en producción es el pecado original de la plataforma), `privacy-engineering-standards`
(**recíproca declarada y de uso constante**: la obligación de minimizar, retener y suprimir, el DSAR
y la anonimización de entornos no productivos. Aquí, **su implementación en esta plataforma** y el
hecho de que el almacenamiento sea una partida creciente),
`data-governance-quality-standards` (propiedad del dato, catálogo, dimensiones de calidad),
`data-platform-standards` y `analytics-bi-standards` (la analítica fuera del CRM; sacar datos del CRM
a un almacén es casi siempre la respuesta correcta, y su diseño es suyo),
`opensource-licensing-standards` (licencias de software libre; aquí licencia **comercial de SaaS**),
`erp-sap-standards` (**recíproca del bloque**: allí el ERP como sistema de registro y su
licenciamiento por documento — y ojo, **un CRM que crea pedidos en un SAP dispara acceso indirecto**:
esa decisión se valora allí antes de construirse aquí), `appsec-standards` (metodología de amenazas y
triaje), `testing-qa-standards` (estrategia de prueba general), `frontend-frameworks-standards` (LWC
usa estándares web, pero su ciclo de vida y sus límites son de esta plataforma),
`ai-governance-standards` (gobierno de los agentes y copilotos que se despliegan sobre el CRM).

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): límites, ediciones, precios y nombres de producto de
> Salesforce **cambian cada release** (tres al año) y los precios subieron en 2025.

| Decisión | Por defecto | Alternativa justificable |
|---|---|---|
| Automatización nueva | **Flow** (record-triggered), uno por objeto y por contexto | Apex si hay lógica que Flow no expresa o requiere pruebas unitarias serias |
| Lógica en trigger | **Un trigger por objeto**, delegando a una clase manejadora | Nunca varios triggers sobre el mismo objeto |
| Consulta y DML | **Siempre en bloque** (fuera de bucles), sin excepción | No hay |
| Modo de ejecución de Apex | **Modo usuario** (`WITH USER_MODE` / `AccessLevel.USER_MODE`) | `SYSTEM_MODE` explícito, documentado y revisado |
| Compartición por defecto | **OWD `Private`** y abrir con permisos/reglas | `Public Read` solo si el dato no es sensible y se justifica |
| Asignación de permisos | **Conjuntos de permisos y grupos**; perfil mínimo | El perfil como contenedor de permisos es legado |
| UI nueva | **LWC** | Visualforce solo para mantener lo existente |
| Despliegue | **Metadata en control de versiones + Salesforce CLI** | *Change sets* solo como parche de emergencia registrado |
| Empaquetado interno | **Paquetes desbloqueados** con dependencias explícitas | Metadata suelta si el dominio es pequeño y está claro |
| Entorno de desarrollo | *Scratch org* o Developer sandbox por persona | Compartir un sandbox de desarrollo es fuente de colisiones |
| Entorno de UAT | **Partial Copy** con plantilla y datos enmascarados | Full solo para regresión final y prueba de carga |
| Datos históricos y analítica | **Fuera de la org**, en el almacén | Dentro solo si el proceso operativo lo necesita |

## 3. Estructura y convenciones

### 3.1 Límites de gobernador: restricción arquitectónica, no detalle

Verificados en la *Apex Developer Guide* (ago-2026, §8). **Por transacción**:

| Límite | Síncrono | Asíncrono |
|---|---|---|
| Consultas SOQL emitidas | **100** | **200** |
| Registros recuperados por SOQL | **50 000** | 50 000 |
| Sentencias DML | **150** | 150 |
| Registros procesados por DML | **10 000** | 10 000 |
| Tiempo de CPU | **10 000 ms** | **60 000 ms** |
| Tamaño de *heap* | **6 MB** | **12 MB** |
| Llamadas salientes (callouts) | 100 | 100 |
| Timeout acumulado de callouts | 120 s | 120 s |
| `sendEmail` | 10 | 10 |
| Duración máxima de la transacción | 10 min | 10 min |
| Profundidad de pila de triggers recursivos | 16 | 16 |

**Lo que esto obliga, y es la consecuencia entera:** el disparador no se ejecuta una vez por registro,
se ejecuta **una vez por lote**. Todo código se escribe asumiendo 200 registros de entrada:
- **Ninguna consulta ni DML dentro de un bucle.** Es la causa del 90 % de las excepciones de límite.
- Colecciones (`Map`, `Set`) para relacionar en memoria en vez de consultar por registro.
- **Nada de recursión sin guarda**: un trigger que actualiza el mismo objeto se reentra.
- Lo que no cabe en una transacción va a **asíncrono** (`Queueable`, Batch) **por diseño desde el
  principio**, no como parche cuando revienta. Convertir síncrono en asíncrono tarde cambia la
  semántica visible para el usuario.
- **El límite de CPU es el que más sorprende**: no lo consume la base de datos, lo consumen los bucles
  anidados y las cadenas de *flows* y triggers encadenados. Un límite de CPU agotado en producción y
  no en el sandbox suele significar **volumen de datos**, no un cambio de código.
- **Las pruebas deben ejercitar el volumen**: un test con un registro no prueba nada sobre el límite.
  Test obligatorio con 200 registros para cualquier trigger o flujo de registro.

### 3.2 Clics o código: el criterio honesto

Falso debate mal planteado. El criterio no es "declarativo siempre que se pueda" sino **quién podrá
entenderlo y cambiarlo dentro de tres años, y con qué red de seguridad**.

| Elige **configuración** cuando | Elige **código** cuando |
|---|---|
| La lógica cabe en una decisión con pocas ramas | Hay lógica compleja, bucles reales o algoritmo |
| El dueño funcional necesita cambiarla sin desplegar | Necesitas pruebas unitarias con aserciones serias |
| No hay requisito de rendimiento en bloque | Procesas miles de registros o consumes CPU |
| El comportamiento es visible y auditable en la UI | Hace falta control de errores y transaccionalidad fina |

**Lo que se paga por el lado declarativo y casi nadie contabiliza:**
- **La deuda del flujo que nadie sabe que existe.** Un Flow no aparece en un `grep`, no lo revisa
  nadie en un PR si no está en el repositorio, y se dispara desde un cambio de registro cualquiera.
  Cinco flujos sobre el mismo objeto producen un orden de ejecución que **nadie puede razonar**.
  Regla dura: **el metadato declarativo vive en el control de versiones igual que el código**, y todo
  Flow tiene descripción, dueño y motivo. Un Flow activo sin dueño se desactiva.
- **La cadena declarativa es CPU.** Flujos que se disparan entre sí agotan el mismo límite que Apex,
  y el error resultante señala a un sitio que no es la causa.
- **Legado ya sin soporte**: Salesforce **terminó el soporte de Workflow Rules y Process Builder el
  31-dic-2025**. No es una retirada —lo activo sigue ejecutándose— pero **no hay soporte ni
  correcciones**, y ya no se pueden crear nuevos. Tratar la migración a Flow como **deuda técnica
  urgente con fecha vencida**, no como tarea de mantenimiento. Ojo con las automatizaciones legadas
  **dentro de paquetes gestionados**: no las puedes editar; las tiene que migrar el proveedor, y ese
  es un punto de la *due diligence* de §3.6.

**Regla de oro transversal**: si la solución declarativa requiere quince pasos, dos subflujos y una
fórmula ilegible, ya no es declarativa: es código escrito con el ratón, y sin pruebas.

### 3.3 Modelo de datos y su coste

- **Objetos estándar antes que personalizados.** Un objeto `__c` que duplica `Opportunity` pierde
  informes, previsiones, apps móviles y todo lo que la plataforma da gratis.
- **Los límites de objetos, campos y relaciones dependen de la edición** y son duros: verifícalos
  antes de diseñar (§8). Un modelo que no cabe en la edición contratada no es un problema de
  presupuesto, es un rediseño.
- **Relaciones maestro-detalle vs. lookup**: la primera hereda compartición y borrado en cascada — es
  una decisión de **seguridad y de ciclo de vida**, no de modelado. Cambiarla con datos cargados es
  costoso.
- **Campos de fórmula y roll-up**: se evalúan al vuelo y consumen; un informe sobre fórmulas cruzadas
  es la causa habitual de un tiempo de espera que nadie explica.
- **Almacenamiento como partida creciente, y es el coste que sorprende:** asignación (verificada,
  ago-2026, fuente secundaria — §8) de **10 GB de datos por org** más **20 MB por usuario**, y
  **10 GB de ficheros por org** más **2 GB por licencia** en Enterprise/Performance/Unlimited. Un
  registro cuenta ~**2 KB** con independencia de lo lleno que esté. Consecuencias:
  - **El histórico de actividad, correos y campos de auditoría es lo que llena la org**, no los datos
    de negocio. Diez millones de registros de actividad son ~20 GB que pagas cada año.
  - **Política de archivado y retención desde el día uno**, con destino fuera de la org y borrado
    programado. Sin ella, el coste crece monótonamente y solo se descubre en la renovación.
  - **Adjuntos**: el patrón por defecto es almacenar el fichero fuera (almacén de objetos) y guardar
    la referencia, salvo requisito explícito.

### 3.4 Seguridad: es donde se filtran los datos

**Modelo en capas, y hay que entender que se suman:** organización → objeto (perfil/permisos) →
campo (FLS) → registro (OWD, roles, reglas de compartición) → código.

- **OWD `Private` por defecto** y se abre hacia arriba con jerarquía de roles, reglas de compartición
  y compartición manual. Empezar abierto y cerrar después es imposible en la práctica: nadie sabe
  quién dependía de qué.
- **Perfiles al mínimo, todo lo demás en conjuntos de permisos y grupos de conjuntos.** El perfil como
  contenedor de todo produce N perfiles casi idénticos que nadie puede auditar.
- **Permisos que se revisan uno por uno, siempre**: `Modify All Data`, `View All Data`,
  `Author Apex`, `Manage Users`, `Customize Application`, `API Enabled`, exportación de informes.
  Cada uno es una vía de exfiltración completa. Lista nominal de quién los tiene, revisada
  trimestralmente.
- **Apex y la seguridad — el cambio grande de 2026, verbatim de la documentación**: *"In API version
  67.0 and later, Apex runs in user context by default, meaning that the current user's permissions
  and field-level security (FLS) are enforced during code execution. In API version 66.0 and earlier,
  system mode is the default."* Consecuencias operativas, y son dos en direcciones opuestas:
  1. **Código nuevo**: se escribe en modo usuario y punto. `SYSTEM_MODE` es una excepción explícita,
     comentada con el motivo y revisada por alguien más.
  2. **Código existente**: subir la versión de API de una clase antigua **puede romperla** al empezar
     a aplicarse FLS y compartición. Subir versión de API es un cambio funcional, **se prueba**.
- **`WITH USER_MODE` frente a `WITH SECURITY_ENFORCED`**: el segundo es el mecanismo antiguo y tiene
  agujeros conocidos — **solo aplica a las cláusulas `SELECT` y `FROM`**, de modo que un campo sin
  acceso usado en `WHERE` u `ORDER BY` **no da error**, y no cubre DML. Por defecto: **`WITH
  USER_MODE`**, que además respeta reglas de restricción y de alcance. `Security.stripInaccessible`
  cuando el requisito es **degradar** (quitar los campos inaccesibles y seguir) en vez de fallar.
- **`without sharing`** solo con justificación escrita en el propio código. Una clase `without
  sharing` invocada desde un componente accesible por cualquier usuario es un IDOR de manual.
- **Sitios públicos y Experience Cloud**: el usuario invitado es el vector clásico de filtración
  masiva. Sus permisos y su OWD se revisan aparte y con lupa; cualquier objeto accesible por el
  usuario invitado se declara y se justifica.
- **SOQL con concatenación de cadenas** (`Database.query`) sin `String.escapeSingleQuotes` o *bind*
  es inyección SOQL. Metodología en `appsec-standards`; aquí el veto (§7).
- **Datos personales**: el CRM es, por definición, un almacén de datos personales. Retención, borrado
  y DSAR se diseñan desde el principio (cruza con `privacy-engineering-standards`) y **alcanzan a los
  sandboxes**: una copia Full de producción en un entorno de pruebas es una brecha con nombre.

### 3.5 Entornos y despliegue: el pecado original

**El cambio directo en producción es el modo de fallo estructural de la plataforma**, porque la
plataforma lo permite y lo hace cómodo. La consecuencia no es que se rompa algo hoy: es que **nadie
puede reconstruir cómo llegó la org a su estado actual**, y a partir de ahí ningún entorno inferior
representa la realidad.

Reglas:
- **La fuente de verdad es el repositorio**, no la org. Metadato en git, revisado en PR — incluido el
  declarativo (§3.2).
- **Producción es de solo lectura para humanos** salvo un conjunto cerrado y documentado de cambios
  (parámetros operativos, usuarios). Todo lo demás llega desplegado.
- **Excepción de emergencia**: existe, se registra con motivo y autor, y **se devuelve al repositorio
  en menos de 24 h**. Un *hotfix* no reconciliado es una divergencia permanente.
- **Tipos de sandbox y su restricción real** (verificado, ago-2026 — fuente secundaria, §8):

  | Tipo | Almacenamiento | Datos | Refresco mínimo |
  |---|---|---|---|
  | Developer | 200 MB | Solo metadatos | 1 día |
  | Developer Pro | 1 GB | Solo metadatos | 1 día |
  | Partial Copy | 5 GB | Muestra por plantilla | 5 días |
  | Full | Igual que producción | Todos los registros y adjuntos | **29 días** |

  **El intervalo de 29 días del Full es una restricción de planificación, no un detalle**: si tu plan
  de release necesita un Full recién refrescado dos veces al mes, tu plan no es ejecutable. Y el Full
  es el **único** entorno válido para prueba de rendimiento y carga, además de una partida de coste
  propia (suele venderse aparte o venir contado por edición).
- **Datos en no productivos**: Partial Copy con plantilla y **enmascarado**. Copiar producción entera
  a UAT "para probar bien" es la práctica que convierte una prueba en un incidente de privacidad.
- **Paquetes desbloqueados** para modularizar metadato propio con dependencias explícitas; *change
  sets* solo como parche registrado. La mecánica del pipeline es de `cicd-standards`.

### 3.6 AppExchange: un paquete gestionado corre con tus datos

Instalar un paquete gestionado es **dar ejecución dentro de tu org a código que no puedes leer**.
Salesforce lo dice sin rodeos en su propia documentación (verbatim): *"Notwithstanding any security
review of a Partner Application, Salesforce makes no guarantees regarding the quality or security of
any Partner Application."* La revisión de seguridad es una condición para publicar, **no una garantía
para ti**.

Lista mínima antes de instalar, y ninguna es opcional:
1. **Qué permisos pide** el paquete y qué objetos toca. Si pide `Modify All Data`, la respuesta por
   defecto es no.
2. **Si hace llamadas salientes**, a dónde y con qué dato. Sitios remotos autorizados, revisados.
3. **Qué consume**: llamadas a API, almacenamiento, límites de objetos y campos personalizados — que
   son finitos por edición y **el paquete los gasta de tu cuota**.
4. **Estado de sus automatizaciones legadas** (Workflow/Process Builder sin soporte desde
   dic-2025): no las puedes tocar tú.
5. **Salida**: qué queda al desinstalar, dónde van los datos que creó y si te los llevas.
6. **Viabilidad del proveedor** y su calendario frente a las tres releases anuales de Salesforce.
7. **Instalación primero en sandbox**, siempre, con revisión de lo que aparece en la org.

### 3.7 Licencia y coste: la renovación es el único momento de negociar

- **La cuota de API es por edición y por licencia** (verificado, ago-2026): Enterprise y Professional
  con acceso a API, **1 000 llamadas por licencia**; Unlimited y Performance, **5 000**; total =
  **100 000 + (licencias × llamadas por tipo) + add-ons comprados**. Developer Edition, **15 000**.
  Full sandbox, **5 000 000**. **Concurrencia**: 25 peticiones concurrentes de larga duración en
  producción y sandbox, 5 en Developer/trial.
  - **Consecuencia de diseño**: una integración que sondea cada minuto consume ~43 200 llamadas/día
    **de tu cuota compartida**, y cuando la agota **fallan todas las integraciones, no solo la
    culpable**. Por defecto: eventos y APIs en bloque (Bulk/Composite) frente a sondeo por registro.
    El límite de concurrencia obliga además a acotar consultas largas: 25 no es un número grande.
- **Ediciones y precio**: la lista pública de Salesforce cambia y **subió en 2025**. En ago-2026 las
  fuentes secundarias sitúan Sales Cloud en Starter Suite 25 $, Pro Suite 100 $, Enterprise 175 $,
  Unlimited 350 $ y el nivel superior (Agentforce 1 Sales, antes Einstein 1) 550 $ por usuario y mes
  con facturación anual. **`salesforce.com` devolvió 403 a la verificación automatizada: trátalo como
  orden de magnitud y confírmalo en la página oficial antes de usarlo (§8).** Muchas páginas siguen
  citando la lista anterior (165 $/330 $): **cifra sin fecha, cifra inservible**.
- **Lo que no está en el precio por asiento** y hay que presupuestar aparte: sandboxes adicionales
  (señaladamente el Full), llamadas de API adicionales, almacenamiento por encima de la asignación,
  planes de soporte superiores (un porcentaje sobre la licencia neta), y las licencias de los
  paquetes de AppExchange.
- **La renovación es el único momento con palanca real.** Prepararla **seis meses antes**, con:
  inventario de asientos **realmente usados** (login en los últimos 90 días), tipos de licencia
  ajustados a la tarea, consumo medido de API y almacenamiento, y lista de módulos contratados que
  nadie usa. Sin ese dato, la renovación es aceptar la propuesta del proveedor.
- **Auditoría del propio uso, trimestral**: asientos inactivos, permisos administrativos, paquetes
  instalados, integraciones activas. En SaaS el coste no crece por decisión, crece por acumulación.

## 4. Calidad y verificación

En orden de coste creciente; los tres primeros son gates que rompen el build:
1. **Análisis estático** con el escáner de código de Salesforce (Code Analyzer / PMD con el ruleset
   de Apex) sobre reglas duras: DML o SOQL en bucle, `without sharing` sin justificar, SOQL dinámica
   sin escapar, ausencia de aserciones.
2. **Pruebas Apex con aserciones reales.** El mínimo del **75 % de cobertura para desplegar es un
   umbral de la plataforma, no un objetivo de calidad**: un test sin `Assert` cubre líneas y no
   comprueba nada. Prohibido `SeeAllData=true` (§7); los datos los crea el test.
3. **Prueba en bloque obligatoria**: 200 registros por trigger y por flujo de registro. Un test de un
   registro no dice nada sobre los límites de §3.1.
4. **Prueba negativa de permisos**: ejecutar como usuario de perfil restringido (`System.runAs`) y
   comprobar que **no** ve lo que no debe. Es el único test que detecta la fuga de §3.4.
5. **Despliegue validado contra Full sandbox** antes de producción, con el conjunto de pruebas local.
6. **Regresión de proceso de negocio de extremo a extremo** en cada una de las **tres releases
   anuales** de Salesforce: la actualización llega tanto si estás listo como si no. La ventana de
   *preview* del sandbox existe para esto y se usa.

## 5. Seguridad del stack

Cubierto en §3.4 (modelo de permisos y modo de ejecución) y §3.6 (paquetes). Añadidos:
- **Registro de eventos y monitorización**: exportación de informes, descargas masivas y accesos de
  API se vigilan. La exfiltración típica no es un exploit: es un usuario legítimo exportando un
  informe completo. Requiere edición/complemento concreto — verifica qué te da el tuyo.
- **Cuentas de integración**: una por integración, con conjunto de permisos mínimo, sin interfaz de
  usuario y con credenciales en gestor de secretos. Jamás la cuenta de un administrador humano.
- **Restricción de IP y políticas de sesión** para perfiles administrativos y de integración.
- **La cuenta del administrador es objetivo prioritario**: MFA obligatorio, número mínimo de
  administradores, revisión nominal. Detalle de identidad en `identity-access-management-standards`.
- **Secretos en el metadato**: prohibido. Ni en fórmulas, ni en configuración personalizada visible,
  ni en Flows. Named Credentials y Protected Custom Metadata.

## 6. Rendimiento y operabilidad

- **El rendimiento depende del volumen de datos, no del código**: un objeto con millones de registros
  degrada informes y consultas. Se diseña con **índices** (campos únicos, externos, `Salesforce`
  estándar) y **desviación de propiedad** controlada (muchos registros del mismo dueño degradan el
  cálculo de compartición).
- **Archivado**: la política de §3.3 es también una política de rendimiento.
- **Errores en integraciones**: reintento con backoff y **contrapresión**. Un cliente que reintenta en
  bucle contra el límite de API deja fuera al resto de la empresa.
- **Observabilidad**: el estado de la plataforma lo publica el proveedor y hay que consumirlo; lo tuyo
  es medir errores de tus integraciones, consumo de cuota de API y de almacenamiento **con alerta
  antes del umbral**, no cuando ya falla.
- **Salida (exit)**: exportación periódica y probada de datos y metadatos fuera de la plataforma. Una
  exportación que nunca se ha restaurado en ningún sitio no es una salida, es un fichero.

## 7. Sostenibilidad y prohibiciones

- ❌ **PROHIBIDO** SOQL o DML dentro de un bucle. Sin excepciones.
- ❌ **PROHIBIDO** más de un trigger por objeto, y triggers con lógica dentro.
- ❌ **PROHIBIDO** `@isTest(SeeAllData=true)` y los tests sin aserciones. La cobertura del 75 % es un
  peaje de la plataforma, no una medida de calidad.
- ❌ **PROHIBIDO** `without sharing` sin justificación escrita en el propio código y revisada.
- ❌ **PROHIBIDO** SOQL dinámica con concatenación de entrada sin escapar o *bind*.
- ❌ **PROHIBIDO** cambiar configuración o metadato **directamente en producción** fuera del conjunto
  cerrado y documentado, y prohibido dejar un *hotfix* sin reconciliar con el repositorio.
- ❌ **PROHIBIDO** copiar producción a un sandbox sin enmascarar datos personales.
- ❌ **PROHIBIDO** instalar un paquete de AppExchange directamente en producción o sin la lista de
  §3.6. La revisión de seguridad de Salesforce **no es una garantía**, y ellos lo dicen por escrito.
- ❌ **PROHIBIDO** crear un objeto personalizado que duplique un objeto estándar sin decisión
  registrada.
- ❌ **PROHIBIDO** dar `Modify All Data` o `View All Data` por comodidad, y prohibido que un perfil
  administrativo carezca de MFA.
- ❌ **PROHIBIDO** una integración por sondeo por registro cuando existe API en bloque o evento.
- ❌ **PROHIBIDO** dejar un Flow activo sin dueño, sin descripción y fuera del control de versiones.
- ❌ **PROHIBIDO** citar un precio de Salesforce sin fecha y sin fuente: la lista cambió en 2025 y
  medio internet cita la anterior.
- **Cadencia**: las **tres releases anuales** son obligatorias y no se posponen — cada una tiene una
  ventana de *preview* en sandbox que se usa para la regresión de §4. Revisión trimestral de asientos,
  permisos administrativos, paquetes instalados e integraciones activas. Revisión de contrato **seis
  meses antes** de la renovación.
- **Deuda característica del dominio**: la org que acumula quince años de configuración de gente que
  ya no está. Se combate con una sola disciplina — **nada activo sin dueño nombrado**: ni Flow, ni
  campo, ni informe, ni integración, ni paquete. Lo que no tiene dueño se desactiva tras aviso, y lo
  desactivado que nadie reclama en un trimestre se borra.

## 8. Verificación web obligatoria

Antes de fijar cualquier dato de este documento:

1. **Límites de gobernador**: la tabla de §3.1 se verificó verbatim en la *Apex Developer Guide*
   (`developer.salesforce.com`, `apex_gov_limits.htm`). **Revalidar por release**: Salesforce publica
   tres al año y los límites por edición varían.
2. **Modo de ejecución por defecto**: la cita de la v67.0 procede verbatim de
   `apex_classes_perms_enforcing.htm`. Verifica la versión de API de **tus** clases antes de asumir
   qué modo aplica.
3. **Cuotas de API y de almacenamiento**: la cuota de API se verificó en la *Salesforce Developer
   Limits Cheat Sheet*. **La asignación de almacenamiento y la tabla de sandboxes de §3.3 y §3.5
   proceden de fuentes secundarias coincidentes** —`help.salesforce.com` no se dejó recuperar de forma
   automatizada (página renderizada por JavaScript)—: **hueco declarado**, confírmalas en la ayuda
   oficial o en Setup de tu propia org, que es la fuente definitiva.
4. **Precios y ediciones**: **hueco declarado** — `salesforce.com/sales/pricing` devolvió **403** a la
   verificación automatizada en ago-2026; las cifras de §3.7 vienen de fuentes secundarias
   posteriores a la subida de 2025. **El único precio que te aplica es el de tu contrato**, y los
   descuentos no se publican.
5. **Fin de soporte y retiradas**: Workflow Rules y Process Builder (31-dic-2025) y cualquier
   retirada anunciada en las notas de la release vigente. Comprueba también qué versiones de API
   están marcadas como retiradas: Salesforce retira versiones antiguas y eso **rompe integraciones**.
6. **Nombres de producto y empaquetado**: Salesforce renombra con frecuencia (Einstein 1 →
   Agentforce). Verifica el nombre exacto antes de escribirlo en un contrato o un documento.
7. **Notas de la release** de las tres entregas del año, para límites nuevos, cambios de seguridad por
   defecto y funciones que cambian de edición.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
