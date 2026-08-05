---
name: coldfusion-standards
description: CFML applications on Adobe ColdFusion, Lucee or BoxLang - a commercial runtime with a heavy exploitation history, and the migrate-or-freeze decision. Use when working with .cfm, .cfc and .cfml files, Application.cfc and Application.cfm, cfscript blocks and tag-based CFML, cfquery and cfqueryparam, cfoutput, cfloop, cfinclude, cfmodule, cfinvoke, cffile and cfftp, cfhttp, cfexecute, cfdocument and cfpdf, cfmail, cflock, cfthread, cfform, CFCs with access="remote" methods, application-scope and session-scope variables, evaluate() and iif() dynamic evaluation, serializeJSON and deserializeJSON, the CFIDE/administrator and cf_scripts directories, WEB-INF/cfusion, neo-*.xml configuration files, lucee-server.xml and lucee-web.xml, box.json and CommandBox servers, BoxLang runtimes and the bx-compat-cfml module, Adobe ColdFusion 2021 / 2023 / 2025 licensing and updates, or planning a move from Adobe ColdFusion to Lucee, to BoxLang, or to a rewrite.
---

# Estándares ColdFusion / CFML

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplicaciones CFML sobre **Adobe ColdFusion**, **Lucee** o **BoxLang**: mantenimiento, endurecimiento,
cambio de motor y salida. Triggers: `.cfm`/`.cfc`, `Application.cfc`, `cfquery`, `cfqueryparam`,
`cfscript`, `cffile`, `cfexecute`, `CFIDE/administrator`, `lucee-server.xml`, `box.json`, BoxLang.

**El eje: ColdFusion sigue existiendo y es comercial — y esa es la mitad de la decisión.** No es un
lenguaje abandonado que arrastras: es un producto de pago, con versiones vivas y una factura anual
que ha cambiado de forma. La otra mitad la pone su historial de seguridad (§5). Datos verificados:

- **Adobe ColdFusion**, leído de la propia matriz de fin de vida de Adobe (`helpx.adobe.com`, HTML
  descargado y parseado, HTTP 200): **CF 2025** — disponibilidad **25-feb-2025**, fin de *core
  support* **26-feb-2030**, *extended support* **N/A**; **CF 2023** — GA 17-may-2023, core hasta
  **16-may-2028**, extendido hasta 16-may-2029; **CF 2021** — core terminado el **10-nov-2025** (ya
  pasó), extendido hasta **10-nov-2026**; CF 2018 y anteriores, fuera hace años. Los dos matices que
  deciden: **el soporte extendido de Adobe es "mejor esfuerzo" para migrar y no incluye parches de
  seguridad** —o sea, un CF 2021 hoy es un servidor **sin parches** aunque figure "en soporte"— y
  **CF 2025 no tiene fase extendida listada**, así que su fecha real es una sola.
- **Modelo de licencia: cambió.** Desde CF 2025 Adobe vende **solo suscripción** —perpetuas
  descontinuadas, las ya compradas de 2021/2023 siguen siendo válidas—, por servidor y con cobertura
  de núcleos (**Standard cubre 2 núcleos**, **Enterprise hasta 8**), activada por Adobe Admin
  Console. El coste anual publicado ronda los **≈2.930 $/año (Enterprise)** y **≈960 $/año
  (Standard)**, con fuentes que dan otra cifra para Standard: cifras **orientativas y a verificar**
  (§8). La consecuencia práctica de contar núcleos en máquinas virtuales grandes es que la factura de
  quien venía de perpetua puede multiplicarse, y ese es hoy el principal motor de la migración a
  Lucee.
- **Lucee** (alternativa de código abierto): licencia **LGPL-2.1**, verificada leyendo el fichero en
  crudo — y con la trampa habitual: **no está en `LICENSE` ni en `main`/`master`**, sino en
  **`License.txt` sobre la rama por defecto `7.0`** (la API del repositorio lo confirma como
  `LGPL-2.1`). Dos líneas estables mantenidas en paralelo: **7.0.4.34** y **6.2.7.16**, ambas del
  **4-jun-2026**.
- **BoxLang** (Ortus Solutions): **no es "otro CFML"**, es un **lenguaje dinámico nuevo para la JVM**
  con **módulo de compatibilidad CFML** (`bx-compat-cfml`, con modo `adobe` o `lucee`) que permite
  ejecutar aplicaciones existentes. Licencia **Apache-2.0**, verificada en crudo — y aquí el fichero
  es **`license.txt` en minúsculas sobre la rama `development`**, con un preámbulo comercial delante
  que hace que la API de GitHub lo clasifique como `NOASSERTION`: **leer el fichero, no fiarse de la
  etiqueta**. Versión **1.16.0** (30-jul-2026), con cadencia mensual. Modelo de núcleo abierto: el
  runtime es Apache-2.0 y hay suscripciones de pago (BoxLang+) para soporte, SLA y módulos premium.

**No aplica**: `web-app-servers-standards` (**ya escrita**) es la dueña del **servidor** que sirve
CFML (Tomcat/IIS/Apache delante, conectores, TLS, límites); aquí solo lo que decide el código y la
configuración del motor CFML. `legacy-modernization-standards` es el
paraguas y `enterprise-architecture-standards` (**ya escrita**) pone inventario, modelo TIME y las
"R" —aquí qué implica técnicamente cada opción—, con `refactoring-tech-debt-standards`,
`testing-qa-standards`, `project-management-standards`, `tech-leadership-standards`, `cicd-standards`
y `git-workflow-standards` (**ya escritas**). `appsec-standards` y `vulnerability-management-standards`
(**ya escritas**) ponen metodología, triaje y el uso correcto de KEV/EPSS —aquí los *sinks*
concretos de CFML—, con `opensource-licensing-standards` (**ya escrita**: el análisis de LGPL y
Apache-2.0 es suyo), `sql-standards`, `firewall-policy-standards` y `grc-compliance-standards`. Si el
destino es reescritura, mandan `jvm-spring-standards`, `dotnet-standards`, `php-standards` o
`python-standards` según el stack. Hermanas de bloque legacy —**comparten la etiqueta "legacy" y poco
más**—: `jsp-struts-standards`, `classic-asp-standards`, `abap-sap-standards`,
`plsql-oracle-forms-standards`, `vb6-standards`, `dotnet-framework-legacy-standards`.

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): versiones, calendario de Adobe, licencias y KEV.

| Decisión | Por defecto | Nota |
|---|---|---|
| Motor en versión sin *core support* | **Actualizar o migrar. Ya** | Sin parches = incidente pendiente (§1) |
| Consultas | **`cfqueryparam` en todos los parámetros. Innegociable** | §5 |
| Estilo | **`cfscript`** para lógica; etiquetas para la vista | §3 |
| Panel de administración | **Nunca accesible desde internet** | §5; regla que domina todo lo demás |
| Aplicación nueva en CFML | **No**, salvo equipo CFML consolidado y decisión escrita | §7 |
| Alternativa libre | **Lucee** (LGPL-2.1) si el objetivo es quitar la licencia | §7: **migración, no interruptor** |
| Compatibilidad Adobe↔Lucee | **Asumir trabajo de adaptación**, siempre | §3 |
| Actualizaciones de seguridad | Aplicar **fuera del ciclo normal**, con ventana propia | §5 |

## 3. Lenguaje y aplicación típica

**Etiquetas frente a *script***: CFML admite las dos formas para casi todo (`<cfquery>`/`queryExecute`,
`<cfloop>`/`for`). Criterio: **la lógica va en `cfscript`** —dentro de componentes— y las etiquetas se
quedan para la plantilla de salida. Mezclar lógica de negocio en la página `.cfm` reproduce el
problema del *scriptlet*: no se prueba, no se reutiliza y esconde los fallos de seguridad.

**Estructura mínima que se exige**: `Application.cfc` con el ciclo de vida explícito (`onApplicationStart`,
`onSessionStart`, `onRequestStart`, `onError`), componentes `.cfc` con métodos de acceso declarado
(`private`/`package`/`public`, y `remote` **solo** donde hay un endpoint de verdad), y las consultas
encapsuladas en componentes de acceso a datos, nunca esparcidas por las vistas. Los ámbitos
(`application`, `session`, `request`, `variables`) se declaran siempre de forma explícita: el
**ámbito implícito** es la fuente clásica de fugas de datos entre peticiones y de condiciones de
carrera. Escritura sobre `application`/`server`, **siempre dentro de `cflock`**.

**Adobe CF y Lucee no son intercambiables sin trabajo, y hay que decirlo antes de firmar el
proyecto.** Comparten el 90% del lenguaje y ahí terminan los parecidos cómodos: difieren en
funciones y etiquetas propietarias (generación de PDF, integración con .NET, servicios que solo
existen en uno), en el tratamiento de nulos y de la conversión de tipos, en la administración
—consola, API de administración, tareas programadas, orígenes de datos, mapeos—, en los ajustes de
seguridad por defecto, y en el comportamiento en los bordes que ninguna documentación describe pero
del que tu código depende. **Regla de planificación: la migración Adobe→Lucee se estima con un
inventario y una prueba real de los flujos críticos, no con "es CFML, funcionará".** Lo mismo, con
más motivo, para BoxLang: su módulo de compatibilidad reduce el cambio, no lo elimina.

## 4. Calidad y testing

Sección **reducida a lo aplicable**: no hay una *toolchain* comparable a la de los ecosistemas
mayoritarios. Lo que sí se usa: pruebas con los marcos de la comunidad (estilo xUnit para CFML) sobre
componentes —lo cual **exige** haber sacado la lógica de las páginas (§3)—, **caracterización de
extremo a extremo** de los flujos críticos antes de cambiar de motor (es el único control que detecta
las diferencias Adobe↔Lucee), y un **linter/analizador de CFML** si el proyecto lo tiene: verificar
estado y licencia antes de adoptarlo (§8). El gate de CI mínimo y realista: **el build despliega en un
motor limpio de la versión destino y ejecuta la suite E2E**; sin eso, cualquier cambio de motor o de
versión es una apuesta.

## 5. Seguridad — sección principal

**El historial no es anecdótico, es estructural.** Verificado descargando el **catálogo KEV de CISA**
(JSON en crudo, versión **2026.08.04**): hay **16 vulnerabilidades de Adobe ColdFusion catalogadas
como explotadas en el mundo real**, y no son todas antiguas — la más reciente, **`CVE-2026-48282`
(*path traversal*), se añadió el 7-jul-2026**. Otras señaladas: `CVE-2024-20767` (control de acceso,
añadida dic-2024), `CVE-2023-29300` y `CVE-2023-38203` (deserialización, **ambas marcadas con uso
conocido en campañas de ransomware**), `CVE-2023-26360`, `CVE-2023-29298`, `CVE-2023-38205`,
`CVE-2017-3066`, `CVE-2018-15961` (subida de ficheros sin restringir), `CVE-2010-2861` (también
ransomware). **Patrón que se repite**: recorrido de rutas y control de acceso al **panel de
administración**, y deserialización. Consecuencia operativa: **la actualización de seguridad de
ColdFusion no espera a la ventana trimestral**; se aplica con procedimiento propio y con prisa, y el
motor sin *core support* no recibe ninguna.

**Reglas duras del código:**

- **`cfqueryparam` en todos los parámetros de toda consulta. Requisito no negociable.** Concatenar
  variables dentro de `<cfquery>` es inyección SQL directa, y es el patrón dominante en el CFML
  antiguo. Correcciones falsas que hay que rechazar: `#` con `htmlEditFormat()`, comprobar
  `isNumeric()` "y ya", o filtrar palabras clave. Además del parámetro, se declara **`cfsqltype`** —
  sin él se pierde parte de la validación de tipo—. Lo mismo en `queryExecute()` con
  parámetros nombrados. Los procedimientos almacenados, con `cfprocparam`.
- **Evaluación dinámica**: `evaluate()`, `iif()` con cadenas construidas, `cfinclude` con plantilla
  derivada de la petición y `cfmodule` dinámico permiten ejecutar código o incluir ficheros
  arbitrarios. Sustituir por estructuras y listas blancas cerradas; **nunca** entrada de usuario ahí.
- **`cfexecute`** con argumentos derivados de la petición es ejecución de comandos del sistema. Si no
  hay más remedio, ruta absoluta fija y argumentos de una lista blanca.
- **Subida de ficheros (`cffile action="upload"`)**: es la vía histórica de la *webshell* en este
  ecosistema. Almacenar **fuera del árbol servido**, nombre generado por el servidor, lista blanca por
  contenido y **`accept`/`strict` configurados** —el `Content-Type` del cliente no es prueba de
  nada—, y el directorio de subidas **sin ejecución de CFML** en el mapeo del servidor.
- **XSS**: `#variable#` en la salida escribe tal cual. Codificar **según contexto** con las funciones
  de codificación de salida (`encodeForHTML`, `encodeForHTMLAttribute`, `encodeForJavaScript`,
  `encodeForURL`); `htmlEditFormat()` es insuficiente y está superado.
- **Deserialización**: no deserializar objetos que vengan de la petición; `deserializeJSON` sobre
  entrada no confiable, con validación de forma posterior.
- **Errores y depuración**: salida de depuración desactivada en producción (imprime consultas,
  variables y rutas), página de error genérica con `onError`, y detalle **solo al log**.
- **Secretos**: credenciales de orígenes de datos y claves **fuera del código y de los ficheros
  servibles**; `secrets-management-standards`.

**La regla que resume todo lo demás: el panel de administración no se expone a internet.** `/CFIDE/`
—y en particular `/CFIDE/administrator`—, la consola de Lucee y cualquier interfaz de administración
del motor **se restringen por red** (escucha en interfaz interna o filtro por IP en el servidor
delante), con contraseña propia rotada, y **se comprueba que no sea alcanzable desde fuera** en cada
despliegue. La mayoría de las CVE de la lista anterior se explotan contra esa superficie: quitarla de
internet convierte una crítica en una alta, y a menudo en inexplotable. Complemento obligatorio:
**restringir la salida de red del servidor** —si cae, que no llame a casa— y ejecutar el motor con un
usuario sin privilegios y sin escritura sobre el árbol de la aplicación.

## 6. Operabilidad

Lo específico del motor: el estado de `session`/`application` vive **en el proceso** salvo que se
configure almacenamiento externo, así que **no hay balanceo sin afinidad ni escalado horizontal** sin
resolverlo antes; `cfthread` y las tareas programadas del motor son trabajo que se pierde en cada
reinicio y que nadie monitoriza hasta que falla; y las fugas típicas —consultas sin límite volcadas a
memoria, cachés en `application` sin política de expiración— tumban la JVM entera. Métricas de JVM
(memoria, GC, hilos) y de peticiones lentas: es un servidor Java, se instrumenta como tal
(`observability-standards`). El dimensionado del contenedor y del servidor web es de
`web-app-servers-standards`.

## 7. Decisión: migrar, cambiar de motor o no tocar nada

**Cuándo migrar a Lucee (quitarse la licencia)**: cuando el coste de suscripción es el problema
dominante, la aplicación **no usa funcionalidad propietaria de Adobe** (PDF avanzado, integración con
.NET, servicios exclusivos) y hay equipo para probarla de verdad. Es una migración con inventario,
banco de pruebas y plan de vuelta atrás, **no un cambio de instalación** (§3). Ganas: coste cero de
licencia y un motor mantenido en abierto. Pierdes: soporte comercial del fabricante —salvo que lo
contrates aparte— y las funciones que no existen.

**Cuándo mirar BoxLang**: cuando además del coste te pesa el lenguaje y quieres una salida gradual
hacia la JVM manteniendo el código en marcha. Es lo más nuevo de las tres opciones y por tanto lo
menos probado en producción a gran escala; su cadencia mensual es señal de proyecto vivo, no de
madurez demostrada. **Decisión con piloto real, no con presentación.**

**Cuándo reescribir**: cuando la aplicación tiene lógica en las páginas y nadie la entiende, cuando
depende de un motor sin soporte y la actualización arrastra medio código, o cuando el negocio ha
cambiado. La reescritura se hace por partes (*strangler fig*) y la calidad del destino la rige la
skill del stack elegido.

**Cuándo NO tocar nada — y es una recomendación legítima, no pereza**: aplicación **interna**, estable,
sin desarrollo pendiente, sobre un motor **con soporte y parcheado**, y sin exposición a internet. Ahí
el trabajo correcto es **congelar con higiene**: versión soportada, parches al día, panel de
administración fuera de la red no confiable, copias de seguridad probadas, inventario de dependencias
y **fecha de revisión anual escrita**. Migrar por estética cuesta dinero y añade riesgo sin retorno.
Lo que **no** es una opción es "no tocar nada" sobre un motor sin *core support*: eso no es congelar,
es acumular un incidente.

- ❌ PROHIBIDO ejecutar en producción un motor sin *core support* del fabricante (o sin mantenimiento
  en el caso de Lucee/BoxLang).
- ❌ PROHIBIDO exponer `/CFIDE/administrator` o la consola de Lucee a redes no confiables.
- ❌ PROHIBIDO cualquier consulta con variables sin `cfqueryparam`/parámetro nombrado. Sin excepciones.
- ❌ PROHIBIDO "sanear" con `htmlEditFormat()`, `isNumeric()` o filtros de palabras en vez de parametrizar.
- ❌ PROHIBIDO `evaluate()`, `iif()` con cadenas, `cfinclude`/`cfmodule` o `cfexecute` con entrada de usuario.
- ❌ PROHIBIDO guardar ficheros subidos dentro del árbol servido o confiar en el `Content-Type`.
- ❌ PROHIBIDO dejar la depuración activada, o mostrar trazas y consultas al usuario en producción.
- ❌ PROHIBIDO escribir en `application`/`server` sin `cflock`, y usar ámbitos implícitos.
- ❌ PROHIBIDO credenciales en el código o en ficheros alcanzables por HTTP.
- ❌ PROHIBIDO tratar el cambio Adobe→Lucee (o →BoxLang) como un cambio de instalación sin pruebas.
- ❌ PROHIBIDO retrasar una actualización de seguridad de ColdFusion a la ventana trimestral ordinaria.
- ❌ PROHIBIDO declarar un WAF como corrección de una CVE del motor o del panel de administración.
- ❌ PROHIBIDO planificar la renovación con la licencia **recordada**: el modelo cambió con CF 2025 y
  se cuenta por núcleos (§8).
- ❌ PROHIBIDO desarrollo nuevo en CFML sin decisión escrita, con dueño, sobre motor y horizonte.

## 8. Verificación web obligatoria

Comprobar siempre: la **matriz de fin de vida de Adobe** (`helpx.adobe.com/support/programs/eol-matrix.html`,
que da GA, fin de *core* y fin de *extended* por versión) y qué incluye exactamente el soporte
extendido; la versión y el nivel de actualización instalados frente a las **actualizaciones de
seguridad** publicadas por Adobe; las versiones estables vigentes de **Lucee** y de **BoxLang** y su
licencia **leyendo el fichero en crudo** —recordar: Lucee lo tiene en `License.txt` sobre la rama
`7.0`, BoxLang en `license.txt` sobre `development`, y la etiqueta automática de GitHub para BoxLang
dice `NOASSERTION` aunque el texto sea Apache-2.0—; el **catálogo KEV de CISA** en JSON, filtrando por
`Adobe ColdFusion`, con su `catalogVersion`; y el precio y las condiciones de la suscripción de Adobe
antes de presupuestar.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: (a) la afirmación de que el
**soporte extendido de Adobe no incluye parches de seguridad** procede de resúmenes de buscador sobre
la política de Adobe, **no de cita verbatim de la fuente primaria**: es un dato crítico para CF 2021
(en fase extendida hasta nov-2026) — confirmarlo antes de usarlo como argumento; (b) **precios**:
las cifras de §1 provienen de terceros y **no coinciden entre sí para la edición Standard**, y el
coste real depende de núcleos, región y distribuidor: pedir presupuesto, no citar estas cifras;
(c) el detalle de qué funcionalidad de Adobe **no** existe en Lucee o en BoxLang no está verificado —
se determina con un inventario del código, no con una tabla comparativa; (d) estado y licencia de los
marcos de prueba y linters de CFML — no verificados; (e) política de soporte y EOL de **Lucee** por
línea de versión (6.2 frente a 7.0) — no localizada, no suponerla.

**Discrepancias señaladas**: la matriz de Adobe da el fin de *core support* de **CF 2025 el
26-feb-2030** y **sin fase extendida**, mientras fuentes secundarias citan "8 de abril de 2030" y una
fase extendida hasta 2031 — **manda la matriz de Adobe**. Y la versión "actual" de **BoxLang** que
anuncian las notas de prensa (1.13) va por detrás de la que publica el repositorio (**1.16.0**,
30-jul-2026): comprobar la fuente del propio proyecto, no la nota de prensa.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
