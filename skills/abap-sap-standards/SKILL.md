---
name: abap-sap-standards
description: ABAP custom development inside SAP ERP - the clean core decision and the S/4HANA clock. Use when working with .abap sources, SE38 reports, SE80 / SE24 / SE11 repository objects, ADT (ABAP Development Tools for Eclipse), ABAP Cloud and the ABAP for Cloud Development language version, released APIs and C0/C1 release contracts, CDS view entities (DEFINE VIEW ENTITY), AMDP methods marked with AMDP_MARKER_HDB, RAP behavior definitions and projections, SEGW and OData service exposure, BAdI / user exits / enhancement points / implicit enhancements / modifications with SSCR key, packages and transport requests (SE09, SE10, STMS, $TMP), abapGit, ATC and Code Inspector variants such as SAP_CP_READINESS_REMOTE, ABAP Unit and CL_ABAP_UNIT_ASSERT, AUTHORITY-CHECK and authorization objects, SY-SUBRC handling, native SQL via EXEC SQL or ADBC, SELECT inside LOOP and other performance antipatterns, SNOTE and SAP Security Notes, or assessing what a S/4HANA move breaks in custom ABAP code.
---

# Estándares de desarrollo ABAP en SAP

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Código a medida dentro de un ERP de SAP: ABAP clásico y ABAP Cloud, objetos de repositorio,
transportes, rendimiento sobre HANA, extensibilidad y salida hacia S/4HANA. Triggers: `.abap`,
ADT/Eclipse, SE38/SE80/SE24/SE11, `DEFINE VIEW ENTITY`, AMDP, RAP, SEGW/OData, BAdI y *enhancements*,
SE09/SE10/STMS, abapGit, ATC/SCI, ABAP Unit, `AUTHORITY-CHECK`, `EXEC SQL`, SNOTE.

**El eje: ABAP no es un lenguaje que se elige, es el lenguaje del ERP que ya tienes.** Nadie arranca
un proyecto nuevo en ABAP por sus méritos técnicos; se escribe ABAP porque la lógica vive dentro de
un SAP que la empresa ya paga. De ahí se deriva todo lo demás: **ninguna decisión técnica aquí es
independiente del calendario de mantenimiento de SAP**, y ese calendario lo fija un proveedor con
interés comercial en que te muevas. Datos verificados (ago-2026, fuentes en §8):

- **SAP Business Suite 7 / SAP ERP 6.0 (ECC)**: mantenimiento *mainstream* hasta **31-dic-2027**, y
  ojo con el matiz que se cae de casi todas las presentaciones: esa fecha es **para EhP 6-8**; con
  **EhP 1-5 el mantenimiento ya terminó el 31-dic-2025**. Un ECC en EhP5 hoy **ya está fuera**.
- **Mantenimiento extendido opcional 2028-2030**, con recargo de **+2 puntos porcentuales** sobre la
  base de mantenimiento. Quien no lo contrata pasa **automáticamente** a *Customer-Specific
  Maintenance* (con contrato de soporte vigente), que **no es lo mismo**: correcciones sobre lo ya
  conocido, sin el compromiso de entrega de cambios legales/regulatorios nuevos — y en un ERP ese
  detalle es el que decide, porque nómina e impuestos cambian por ley todos los años.
- **La fecha ya se movió una vez**: el *mainstream* de Suite 7 era 2025 y SAP lo llevó a 2027 en el
  anuncio del **4-feb-2020**, el mismo que fijó el compromiso de S/4HANA hasta 2040. La prensa
  especializada y los analistas coinciden en ago-2026 en que **no habrá otra prórroga**; es una
  previsión, no un compromiso escrito: **no planifiques contando con ella en ninguna dirección**.
- **S/4HANA**: el "hasta 2040" es un **compromiso de innovación**, no la vida de tu release: SAP se
  compromete a que **siempre haya al menos una release en mantenimiento** hasta fin de 2040. Desde la
  **release 2023** la cadencia es **una release mayor cada dos años** (2023 → 2025 → 2027 prevista)
  con *feature packs* semestrales y **7 años de mainstream por release** (antes 5): 2023 hasta fin de
  **2030**, 2025 hasta fin de **2032**. Estar "en S/4HANA" no te saca del reloj: te mete en otro.
- **Compatibility Packs** (funciones de ECC usables temporalmente en S/4HANA): on-premise vencían el
  31-dic-2025 y SAP los prorrogó a **31-may-2026** —anuncio de dic-2025, declarado *final*—; bajo
  **RISE / SAP Cloud ERP Private** el derecho de uso llega a **31-dic-2030** (nota 2269324). Es
  derecho de uso, no bloqueo técnico: **la transacción sigue arrancando después de expirar**, y ahí
  está la trampa de auditoría.
- **Trampa de nomenclatura**: desde Sapphire 2025, **"SAP Business Suite" designa el paraguas de la
  oferta cloud**, no el Business Suite 7 que caduca en 2027. En un documento, escribe siempre la
  versión.

**No aplica**: `erp-sap-standards` (**SAP como decisión de empresa**: calendario de mantenimiento,
RISE/GROW y modelo de despliegue, licenciamiento, acceso indirecto y auditoría anual, gobierno del
dato maestro. **Arbitraje en una línea: *si se escribe en un objeto del repositorio es de ABAP; si
se firma en un contrato o se declara en una medición de licencia, es de ERP***).
`legacy-modernization-standards` es el paraguas del bloque,
`migration-projects-standards` la ejecución del corte a S/4HANA (ensayo, ventana, cuadre del dato,
convivencia, rollback y apagado del ECC de origen) y
`enterprise-architecture-standards` (**ya escrita**) pone el inventario, el modelo TIME y las "R" de
modernización — aquí solo qué implica **técnicamente** cada opción dentro de SAP. La base de datos y
el lenguaje SQL son de `oracle-dba-standards`, `sqlserver-dba-standards` y `sql-standards`
(**ya escritas**), y la analítica fuera del ERP de `data-platform-standards`, `data-engineering-standards`
y `analytics-bi-standards`; aquí SQL solo como ABAP SQL y *code pushdown*. Los desarrollos
*side-by-side* en BTP se escriben en Java/Node/Python y su calidad la rigen `jvm-spring-standards`,
`typescript-standards` y `python-standards` (**ya escritas**), con `api-design-standards` para el
contrato y `microservices-architecture-standards` para el reparto. Metodología de seguridad y triaje
en `appsec-standards` y `vulnerability-management-standards` (**ya escritas**) —aquí solo los *sinks*
concretos de ABAP—, identidad en `identity-access-management-standards`, y proceso en
`refactoring-tech-debt-standards`, `testing-qa-standards`, `cicd-standards`, `git-workflow-standards`,
`project-management-standards`, `tech-leadership-standards` y `grc-compliance-standards`
(**ya escritas**). Hermanas de bloque legacy: `mainframe-zos-cobol-standards`, `ibm-i-rpg-standards`,
`plsql-oracle-forms-standards`, `classic-asp-standards`, `vb6-standards`,
`dotnet-framework-legacy-standards`. **Comparten la etiqueta "legacy" y poco más.**

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): el calendario de SAP y el modelo de *clean core* se mueven.

| Decisión | Por defecto | Nota |
|---|---|---|
| Modelo de extensibilidad | **Clean core**: extensión por API liberada, nunca modificación | §3; es *la* decisión estructural |
| Versión de lenguaje para código nuevo | **ABAP for Cloud Development** (ABAP Cloud) | Standard ABAP solo con justificación escrita |
| Herramienta de desarrollo | **ADT (Eclipse)** | Es la **única** posible para ABAP Cloud; SE80 solo para lo clásico |
| Modelo de programación | **RAP** para servicios y aplicaciones nuevas | SEGW/BOPF/Dynpro = mantenimiento, no destino |
| Acceso a datos | **CDS view entity** + ABAP SQL; AMDP solo donde CDS no llega | `SELECT *` y `SELECT` en bucle: prohibidos (§6) |
| Versionado | **abapGit** (MIT, verificado en crudo) sobre el transporte, no en su lugar | §3: no sustituye a STMS |
| Calidad | **ATC** con variante corporativa, bloqueante en la liberación de la orden | §4 |
| Parcheo | **SAP Security Patch Day: segundo martes de cada mes** | Ciclo mensual con ventana asignada, no "cuando toque" |
| Lógica que no es del ERP | **Fuera del ERP** (§7) | El ERP no es tu servidor de aplicaciones de propósito general |

## 3. Clean core, repositorio y transporte

**La decisión que lo domina todo: dónde vive la extensión.** Tres sitios, en orden de preferencia:

1. **On-stack limpio (ABAP Cloud)**: código en el propio sistema, en `ABAP for Cloud Development`,
   consumiendo **solo APIs liberadas** por SAP con contrato de estabilidad. Es lo que sobrevive a un
   *upgrade* sin tocarse.
2. **Side-by-side en BTP**: servicio separado que habla con el ERP por OData/API liberada. Elección
   correcta cuando la lógica no es del núcleo del ERP, cuando necesita un ciclo de vida propio o
   cuando su lenguaje natural no es ABAP.
3. **On-stack clásico (Standard ABAP)**: donde no llega lo anterior. **Es deuda declarada**, con
   dueño y fecha de revisión, no un empate técnico.

**Y una que no está en la lista: modificar el núcleo.** Tocar un objeto SAP (modificación con clave
SSCR, *implicit enhancement* en código estándar, copia de un programa estándar a la Z) es
exactamente lo que hace **imposible actualizar**: cada *upgrade* o *support package* obliga a
reconciliar a mano (SPAU/SPDD) cada modificación, con un coste que crece con el tiempo y que en las
conversiones a S/4HANA es la partida que descarrila el proyecto. **Extender por el punto que SAP
ofrece (BAdI, evento, *extension point*, API liberada) es reversible; modificar no.**

**Estado del modelo a ago-2026 — dato que corrige la suposición habitual**: el conocido **modelo de
3 *tiers*** (tier 1 ABAP Cloud / tier 2 *wrapper* / tier 3 ABAP clásico) **fue sustituido en la
actualización de ago-2025 de la *ABAP Extensibility Guide*** por un modelo de **niveles de clean core
(A, B, C, D)**, que amplía las APIs disponibles y reduce la necesidad de *wrappers*. Criterio
operativo, estable bajo los dos modelos: **extiende siempre en el nivel más alto posible**, y una
extensión vale lo que **la peor tecnología que use por dentro**. Verificar la definición vigente de
cada nivel antes de escribirla en una norma interna (§8).

**Wrapper como puente, no como destino**: si la API que necesitas no está liberada, el patrón
soportado es envolver el objeto no liberado en un objeto propio y consumir el *wrapper* desde el
código restringido, **pidiendo a SAP la liberación** (Customer Influence) y **borrando el envoltorio
cuando llegue**. Un *wrapper* sin ticket de liberación y sin fecha es deuda disfrazada de patrón.

**Repositorio y transporte: por qué el ciclo de vida no se parece a Git.** El objeto ABAB vive en la
base de datos del sistema, no en ficheros; se organiza en **paquetes** (`$TMP` = local, no
transportable: nada productivo puede quedarse ahí) y se mueve entre entornos DEV → QAS → PRD dentro
de **órdenes de transporte** por la ruta que define STMS. Consecuencias que hay que asumir:

- El bloqueo es **pesimista y por objeto**: dos personas no editan el mismo objeto a la vez. No hay
  ramas, no hay *merge*; el "conflicto" se resuelve por turnos.
- **Lo que se promociona es la orden, no el commit.** Si la orden va incompleta —falta un objeto
  dependiente— el destino queda roto y el diagnóstico llega en el entorno equivocado.
- **El orden de importación importa**: dos órdenes fuera de secuencia sobreescriben una a otra.

**abapGit** (licencia **MIT**, verificada leyendo el fichero en crudo) exporta y reimporta objetos de
repositorio como ficheros, y eso habilita revisión de código en un servidor Git, historia legible,
*diff* real y pruebas de rama. **Lo que no hace: sustituir al transporte.** El paso a producción
sigue siendo la orden de transporte, y **usar abapGit como mecanismo de despliegue a PRD desacopla el
sistema del registro de cambios que la auditoría espera**. Uso correcto: Git como fuente de verdad
para revisar y compartir, STMS como mecanismo de promoción; los dos, no uno.

## 4. Calidad y testing

- **ATC (ABAP Test Cockpit)** con **variante corporativa única y versionada**, ejecutada en local
  antes de liberar y como **comprobación bloqueante en la liberación de la orden de transporte**. Sin
  ese enganche, ATC es un informe que nadie lee.
- **Comprobaciones de *clean core***: la variante debe incluir las de ABAP Cloud/API liberada — la
  variante global de Code Inspector **`SAP_CP_READINESS_REMOTE`** verifica el ámbito de
  `ABAP for Cloud Development` y marca *"Usage of not released API"* y errores de sintaxis fuera del
  ámbito restringido. Es la herramienta que convierte "queremos clean core" en un número.
- **ABAP Unit** (`CL_ABAP_UNIT_ASSERT`) para lógica nueva. **La dificultad real, dicha sin adornos**:
  el ABAP heredado es prácticamente intestable — lógica en programas de informe con `SELECT`
  incrustados, estado global, dependencias de Dynpro y de datos de cliente concretos. No se arregla
  escribiendo tests sobre eso, sino **extrayendo la lógica a clases con las dependencias inyectadas**
  y probando la clase; para el resto, **caracterización antes de tocar** (`testing-qa-standards`).
  Los dobles de prueba de RAP/EML y `CL_OSQL_TEST_ENVIRONMENT`/`CL_CDS_TEST_ENVIRONMENT` permiten
  probar contra datos simulados sin depender del contenido del sistema: úsalos o el test es un
  informe del estado del mandante.
- **Cobertura como señal, no como meta** — y prioriza: nómina, facturación, impuestos y cualquier
  cálculo que salga en un documento legal van primero.
- **CI**: no hay pipeline "nativo" cómodo, pero hay palancas reales — ATC por API/`abapLint` sobre el
  repositorio exportado con abapGit, y ejecución programada de ABAP Unit. El gate mínimo:
  **sintaxis + ATC de prioridad 1 + ABAP Unit del paquete tocado**, y ninguna orden se libera con
  hallazgos de prioridad 1 abiertos.

## 5. Seguridad

- **Autorizaciones**: la comprobación es explícita y **el programa que no llama a `AUTHORITY-CHECK`
  no tiene control de acceso**. Regla dura: `AUTHORITY-CHECK` **seguido inmediatamente de la
  evaluación de `SY-SUBRC`** (`IF sy-subrc <> 0` → salir); un `AUTHORITY-CHECK` cuyo resultado no se
  mira es peor que ninguno, porque aparenta control. Objeto de autorización propio para
  funcionalidad propia, y nunca `SAP_ALL` ni un rol comodín "para que funcione".
- **`SY-SUBRC` en general**: tras `SELECT`, `CALL FUNCTION`, `READ TABLE`, `OPEN DATASET` y
  `AUTHORITY-CHECK`. Ignorarlo produce ejecución con datos vacíos o parciales — y en un ERP eso es un
  asiento contable mal hecho, no una excepción visible.
- **Inyección en SQL nativo y en sentencias dinámicas**: ABAP SQL con variables *host* es seguro; el
  riesgo está en **`EXEC SQL`/ADBC con la consulta concatenada**, y en las cláusulas dinámicas
  (`WHERE (lv_cond)`, `SELECT (lv_fields)`, tabla dinámica). Regla: **nada de entrada de usuario en
  una cláusula dinámica**; lo dinámico se construye desde una **lista blanca cerrada** de campos y
  operadores, y los valores van **siempre** por variable *host*. Igual para `CALL TRANSACTION`,
  ejecución de programas por nombre y accesos a fichero con ruta derivada de la entrada.
- **Ejecución y ficheros**: `OPEN DATASET`/`CALL 'SYSTEM'` con rutas o comandos derivados de la
  entrada son ejecución arbitraria en el servidor de aplicaciones. Ruta validada contra lista blanca
  y comprobación de autorización de fichero (`S_DATASET`).
- **Notas de seguridad de SAP como proceso, no como incidencia suelta**: **SAP Security Patch Day el
  segundo martes de cada mes**; el proceso mínimo es revisar las notas del mes, valorar aplicabilidad
  por componente, aplicar por SNOTE en DEV y transportar con el mismo rigor que un desarrollo, con
  SLA por criticidad. Salen notas **fuera** del patch day: el proceso debe absorberlas.
- **Superficie externa**: RFC, servicios ICF y *gateway* son la puerta por la que entran los ataques
  reales a SAP. Desactivar los servicios ICF que no se usan, destinos RFC sin credenciales
  almacenadas de usuario de diálogo, `reginfo`/`secinfo` cerrados, y **el sistema nunca directamente
  expuesto a internet**. Los secretos, fuera del código (`secrets-management-standards`).
- **Datos personales**: los sistemas de no producción se **anonimizan** — copiar producción a un
  entorno de desarrollo con datos reales de nómina es un incidente esperando a ocurrir.

## 6. Rendimiento

**La regla de oro es una: el cálculo se hace donde están los datos (*code pushdown*).** Traer
millones de filas al servidor de aplicaciones para filtrarlas en ABAP es el error dominante en este
ecosistema, y sobre HANA es aún más caro en términos relativos. Orden de preferencia: **CDS view
entity** (agregación, *join*, filtrado declarativos, reutilizables y consumibles por OData) →
**AMDP** solo cuando hace falta lógica procedimental en el motor (y asumiendo que ata el código a
HANA) → ABAP SQL bien escrito → lógica en ABAP como último recurso.

Antipatrones clásicos, todos motivo de rechazo en revisión:

- **`SELECT` dentro de `LOOP`** — el más caro y el más frecuente. Se sustituye por `FOR ALL ENTRIES`
  (con la tabla base **comprobada como no vacía**, o borra la condición y lee toda la tabla) o, mejor,
  por un *join*/CDS que traiga el conjunto de una vez.
- **`SELECT *`** cuando se usan tres campos: sobre almacenamiento en columnas es un desperdicio
  directo. Lista de campos explícita, siempre.
- **`SELECT ... ENDSELECT`** y lecturas fila a fila: `INTO TABLE` y proceso en memoria.
- **Tablas internas sin la clave adecuada**: `READ TABLE ... WITH KEY` sobre una tabla **estándar** es
  búsqueda lineal; dentro de un bucle es cuadrático. Elegir el tipo (`SORTED`/`HASHED`) o declarar
  claves secundarias según el patrón de acceso, y usar `WITH TABLE KEY`/`BINARY SEARCH` con la tabla
  ordenada. Es la segunda causa de programas que "de repente" tardan horas cuando crecen los datos.
- **Filtrar o agregar en ABAP lo que sabe hacer la base de datos**; y `SELECT` sin `WHERE` sobre
  tablas de documentos.
- **Ausencia de proceso por bloques** en cargas masivas: paquetes con `COMMIT WORK` acotado, no una
  transacción de horas ni un `COMMIT` por registro.

Medición antes que intuición: SQL Trace (ST05), ABAP Trace (SAT/SE30), ST12 y el análisis de
rendimiento de HANA. **Ningún cambio de rendimiento se declara hecho sin medida antes y después.**

## 7. Sostenibilidad, salida y prohibiciones

**Cuándo un desarrollo NO debe estar en el ERP** — criterio honesto, porque el reflejo del equipo es
meterlo dentro: si no consume ni produce datos maestros o documentos del ERP; si su ciclo de vida es
más rápido que el del ERP; si necesita escalar o exponerse a usuarios externos; si su lenguaje
natural no es ABAP (analítica, integración, portales, cualquier cosa con front-end propio). Todo eso
va **side-by-side**, y su calidad la rigen las skills del lenguaje destino, no ésta.

**Cuándo sí queda dentro**: lógica transaccional acoplada al documento SAP, validaciones que deben
ejecutarse en la misma transacción de negocio, y extensiones de campo sobre objetos estándar. Para
eso, dentro y limpio (§3).

**Conversión a S/4HANA**: el custom code se **inventaria y se poda antes de convertir** (uso real por
estadísticas de ejecución: en toda instalación grande hay un tercio de Z que nadie ejecuta desde
hace años — se borra, no se migra), luego se analiza con las comprobaciones de compatibilidad, y solo
entonces se planifica. **Convertir código muerto es el gasto más fácil de evitar de todo el proyecto.**

- ❌ PROHIBIDO **modificar objetos estándar de SAP** (modificación con clave, *implicit enhancement*
  en código estándar) fuera de una nota de SAP o una excepción aprobada, documentada y con fecha.
- ❌ PROHIBIDO copiar un programa estándar a la Z para "adaptarlo": congelas la copia y pierdes todas
  las correcciones futuras de SAP, en silencio.
- ❌ PROHIBIDO escribir en tablas estándar de SAP con `INSERT`/`UPDATE`/`MODIFY` directos, saltándose
  el módulo de función o la API de negocio. Rompe consistencia, *update task* y auditoría.
- ❌ PROHIBIDO `SELECT` dentro de un bucle, `SELECT *` sin necesidad y `SELECT ... ENDSELECT`.
- ❌ PROHIBIDO `FOR ALL ENTRIES` sin comprobar que la tabla base no está vacía.
- ❌ PROHIBIDO concatenar entrada de usuario en `EXEC SQL`, en cláusulas dinámicas o en nombres de
  objeto ejecutables.
- ❌ PROHIBIDO un `AUTHORITY-CHECK` cuyo `SY-SUBRC` no se evalúa, y omitir la comprobación de
  autorización en cualquier punto de entrada nuevo.
- ❌ PROHIBIDO ignorar `SY-SUBRC` tras `SELECT`, `READ TABLE`, `CALL FUNCTION` u `OPEN DATASET`.
- ❌ PROHIBIDO dejar objetos productivos en `$TMP` o liberar órdenes incompletas.
- ❌ PROHIBIDO usar abapGit como **mecanismo de despliegue a producción** en sustitución de STMS.
- ❌ PROHIBIDO desarrollo nuevo en SE80/Dynpro/SEGW cuando ADT + RAP cubren el caso.
- ❌ PROHIBIDO liberar una orden con hallazgos ATC de prioridad 1 abiertos.
- ❌ PROHIBIDO credenciales, endpoints o certificados incrustados en código ABAP.
- ❌ PROHIBIDO copiar datos productivos a desarrollo sin anonimizar.
- ❌ PROHIBIDO planificar sobre una fecha de mantenimiento de SAP **recordada**: se comprueba en el
  portal de soporte, con la EhP y la release exactas del sistema, cada vez (§8).

## 8. Verificación web obligatoria

Comprobar siempre, en el **portal de soporte de SAP** (muchas páginas exigen S-user; las notas
**2881788**, **1648480**, **52505** y **2269324** son las de referencia) y contrastando con la
*Product Availability Matrix*: fin de *mainstream* de **Business Suite 7 / ERP 6.0 según la EhP
concreta**, condiciones y precio del mantenimiento extendido 2028-2030, qué incluye exactamente
*Customer-Specific Maintenance* en materia de **cambios legales**, fin de *mainstream* de **la release
de S/4HANA instalada** y calendario de la siguiente, vigencia de los **Compatibility Packs** por
modelo contractual, definición vigente de los **niveles de clean core** en la *ABAP Extensibility
Guide*, lista de **APIs liberadas** para el release destino, y las **notas de seguridad** del patch
day mensual.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: (a) el detalle contractual de
**"SAP ERP, private edition, transition option"** —opción de soporte más allá de 2030, condicionada a
compromisos de migración— aparece en prensa especializada pero **no se ha verificado contra fuente
primaria de SAP**: no citar condiciones ni precio; (b) la afirmación de que *Customer-Specific
Maintenance* **no entrega cambios legales nuevos** procede de fuentes secundarias consultadas, no de
la nota original (requiere S-user): verificar antes de usarla como argumento en un comité; (c) las
páginas oficiales de mantenimiento de SAP devolvieron **HTTP 403** a la consulta automatizada, así
que **todas las fechas de §1 provienen de fuentes secundarias coincidentes entre sí**, no de una cita
verbatim del portal — reconfirmar con S-user antes de fijarlas en un plan; (d) no verificado el
calendario de release ni el fin de mantenimiento de la S/4HANA **2027**.

**Discrepancia señalada**: SAP presenta cada prórroga como definitiva y su historial dice otra cosa —
Business Suite 7 pasó de 2025 a 2027, y los Compatibility Packs on-premise de 31-dic-2025 a
31-may-2026 con el anuncio calificado de *final*. Ni asumas otra prórroga ni descartes que llegue:
planifica contra la fecha vigente y revísala cada trimestre.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
