---
name: plsql-oracle-forms-standards
description: PL/SQL as a program language and Oracle Forms/Reports as a legacy application layer - two things with different futures. Use when writing or reviewing .pks/.pkb/.plb sources, CREATE OR REPLACE PACKAGE / PACKAGE BODY / PROCEDURE / FUNCTION / TRIGGER, anonymous PL/SQL blocks, %TYPE and %ROWTYPE declarations, ref cursors and cursor FOR loops, BULK COLLECT and FORALL with SAVE EXCEPTIONS and LIMIT, EXECUTE IMMEDIATE and DBMS_SQL dynamic SQL, DBMS_ASSERT input validation, bind variables versus literal concatenation, WHEN OTHERS exception handlers, RAISE_APPLICATION_ERROR, PRAGMA AUTONOMOUS_TRANSACTION, AUTHID DEFINER versus CURRENT_USER, package state and ORA-04068, invalid objects and recompilation, DBMS_PROFILER / DBMS_HPROF / PL/Scope, utPLSQL test suites, SQL Developer and SQLcl, and when working with Oracle Forms .fmb/.fmx/.pll/.olb/.mmb modules, Forms Builder, frmcmp and frmweb, WebUtil, Oracle Reports .rdf/.rep, Forms and Reports 12c or 14c, or planning a Forms-to-APEX / Forms-to-Java migration with ORDS.
---

# Estándares PL/SQL y Oracle Forms

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Código PL/SQL de negocio (paquetes, procedimientos, funciones, *triggers*) y aplicaciones Oracle
Forms/Reports. Triggers: `.pks`/`.pkb`, `CREATE OR REPLACE PACKAGE`, `BULK COLLECT`, `FORALL`,
`EXECUTE IMMEDIATE`, `DBMS_SQL`, `WHEN OTHERS`, `PRAGMA AUTONOMOUS_TRANSACTION`, `AUTHID`,
utPLSQL, `.fmb`/`.fmx`/`.pll`/`.rdf`, Forms Builder, WebUtil, migración a APEX.

**El eje: son dos cosas con destinos distintos y se citan siempre juntas.** Sepáralas antes de
decidir nada.

- **PL/SQL está vivo y es la base de muchísimo negocio.** No es un lenguaje en retirada: se compila
  dentro de un motor con soporte hasta bien entrados los 2030 (Oracle Database **19c**: Premier hasta
  **dic-2029**, Extended hasta **dic-2032**; **26ai**, LTS con GA **oct-2025**, Premier hasta
  **dic-2031** — verificado en el PDF *Oracle Technology Products — Oracle Lifetime Support Policy*,
  *Effective Date: May 1, 2026*). Escribir PL/SQL nuevo en 2026 puede ser una decisión correcta.
- **Oracle Forms es lo que hay que sacar de ahí** — pero **no porque esté desoportado, que es la
  suposición habitual y es falsa**. Dato verificado leyendo el PDF *Oracle Fusion Middleware — Oracle
  Lifetime Support Policy*, *Effective Date: April 13, 2026*: **Fusion Middleware 14.1.x** (GA
  **dic-2024**), cuyo pie de tabla incluye explícitamente *"Forms and Reports"*, tiene **Premier
  Support hasta dic-2030**, **Extended hasta dic-2033** y *Sustaining* indefinido. Lo que sí aprieta
  es la versión anterior: **FMW 12c (12.2.x), donde vive la inmensa mayoría del parque, tiene Premier
  hasta dic-2026 y Extended hasta dic-2027**. Y 11gR2 (11.1.2.x) lleva fuera desde dic-2016 (Premier)
  / dic-2018 (Extended).
- **Oracle Reports es otro caso**: está **deprecado desde 12.2.1.3.0**, declarado *terminal release*,
  y aunque se sigue empaquetando con 14.1.2 no recibe funcionalidad nueva, solo correcciones críticas
  y compatibilidad de pila; la ruta que Oracle señala es **Oracle Analytics Publisher**.

Conclusión operativa: **el reloj de Forms no es "está muerto", es "tu 12.2.x sale de Premier en
dic-2026"**. Y el argumento real para salir no es el calendario, sino que la plataforma cliente
—applet Java, luego Java Web Start, dependencias de JRE en el puesto— envejece más rápido que el
producto y que el mercado de gente que sabe mantenerlo se ha secado.

**No aplica**: `oracle-dba-standards` y `sql-standards` (**ya escritas**) son las dueñas del **motor
Oracle** (instancia, almacenamiento, RAC, backup, parcheo, planes de ejecución, índices, licencias
del motor) y del **lenguaje SQL**; aquí PL/SQL como **lenguaje de programa** y Forms como **capa de
aplicación**, con `data-platform-standards` y `data-warehouse-modeling-standards` para lo analítico.
`legacy-modernization-standards` es el paraguas del bloque —y
`migration-projects-standards` la ejecución del corte: ensayo, ventana, convivencia, cuadre del dato,
rollback y apagado del origen— y
`enterprise-architecture-standards` (**ya escrita**) pone inventario, modelo TIME y las "R" —aquí qué
implica técnicamente cada opción—, con `refactoring-tech-debt-standards` y `testing-qa-standards`
(**ya escritas**: *strangler fig*, caracterización sin tests), `project-management-standards`,
`tech-leadership-standards`, `cicd-standards` y `git-workflow-standards`. Si el destino es Java, manda
`jvm-spring-standards` (**ya escrita**: **Java moderno y Spring son suyos y son el destino habitual**);
para el front-end aparte, `frontend-frameworks-standards` y `api-design-standards`.
`appsec-standards` y `vulnerability-management-standards` (**ya escritas**) ponen metodología y
triaje; aquí solo los *sinks* concretos de PL/SQL. Hermanas de bloque legacy —**comparten la etiqueta
"legacy" y poco más**—: `abap-sap-standards`, `mainframe-zos-cobol-standards`, `ibm-i-rpg-standards`,
`jsp-struts-standards`, `coldfusion-standards`, `vb6-standards`.

## 2. Decisiones por defecto

> Verificar por web antes de fijarlo (§8): fechas de soporte de FMW y del motor, y versión de APEX.

| Decisión | Por defecto | Nota |
|---|---|---|
| Unidad de código | **Paquete** (`PACKAGE`/`PACKAGE BODY`) | Procedimientos sueltos solo para *jobs* triviales |
| SQL en PL/SQL | **Estático siempre que sea posible** | Se comprueba en compilación y registra dependencia |
| Dinámico inevitable | `EXECUTE IMMEDIATE` **con `USING`** + `DBMS_ASSERT` para identificadores | §5; nunca concatenar valores |
| Volumen | **`BULK COLLECT` con `LIMIT` + `FORALL`** | El bucle fila a fila es el defecto de rendimiento nº 1 |
| Excepciones | Capturar **lo esperado y nombrado**; relanzar el resto | `WHEN OTHERS THEN NULL`: prohibido (§3) |
| Derechos | **`AUTHID DEFINER`** por defecto, consciente | `CURRENT_USER` cuando el llamante debe poner sus permisos |
| Pruebas | **utPLSQL** (Apache-2.0, verificado en crudo) | §4 |
| Forms nuevo | **Ninguno**: no se crean módulos `.fmb` nuevos | Funcionalidad nueva, fuera (§7) |
| Destino frecuente | **APEX** si la lógica se queda en la base; **Java/web** si hay que salir de ella | §7 |

## 3. PL/SQL: convenciones que se exigen

- **Paquete como unidad de módulo**: especificación mínima (solo lo público), cuerpo con lo demás.
  La especificación es el contrato: cambiarla invalida a todos sus dependientes, el cuerpo no.
- **`%TYPE` y `%ROWTYPE` siempre** en vez de tipos literales: el código sigue al modelo cuando la
  columna cambia de tamaño.
- **Nada de SQL suelto repetido**: el acceso a una tabla se concentra en su paquete. Si el mismo
  `SELECT` aparece en once sitios, once sitios se romperán con el próximo cambio de modelo.
- **Excepciones**: cada `EXCEPTION` captura excepciones **nombradas** (`NO_DATA_FOUND`,
  `DUP_VAL_ON_INDEX`, o propias con `EXCEPTION_INIT`) y hace algo real con ellas. Para propagar con
  contexto: `RAISE_APPLICATION_ERROR(-20xxx, ...)` conservando `SQLERRM`/`DBMS_UTILITY.FORMAT_ERROR_
  BACKTRACE`, o `RAISE` a secas.
  **`WHEN OTHERS THEN NULL` es el antipatrón más dañino de este ecosistema**, y merece explicación
  porque se escribe por costumbre: convierte un fallo en un éxito silencioso. La transacción sigue,
  el proceso nocturno "termina bien", el registro no se insertó, nadie se entera hasta que cuadran
  las cuentas meses después, y para entonces no hay ni traza ni forma de saber cuántas filas
  faltaron. No es un mal estilo: es **pérdida de datos indetectable**. Su primo, `WHEN OTHERS` que
  hace `DBMS_OUTPUT.PUT_LINE` y no relanza, es lo mismo con más pasos. Regla: **un `WHEN OTHERS` que
  no termina en `RAISE` (o en `RAISE_APPLICATION_ERROR`) es un error de revisión**; el único uso
  legítimo es registrar y relanzar.
- **Transacciones**: `COMMIT`/`ROLLBACK` los decide **quien inicia la unidad de trabajo**, no el
  procedimiento de servicio que se llama desde tres sitios; un `COMMIT` enterrado en una función de
  utilidad rompe la atomicidad de todos sus llamantes.
- **`PRAGMA AUTONOMOUS_TRANSACTION` solo para lo que debe sobrevivir al `ROLLBACK`**: auditoría y
  registro de errores. Usarlo para "que no me moleste el bloqueo" o para evitar la mutación de un
  *trigger* **oculta el error y produce datos inconsistentes**, con el agravante de que la transacción
  autónoma no ve los cambios no confirmados de la principal y puede autobloquearse.
- **Triggers: los mínimos.** Lógica de negocio repartida en *triggers* es imposible de leer y de
  depurar: el orden de ejecución no es evidente y el efecto se dispara donde nadie lo espera. Para
  auditoría, mejor `FLASHBACK`/columnas de auditoría o *trigger* compuesto que una cascada.
- **Dependencias e invalidación**: cada objeto registra de qué depende; un DDL invalida a sus
  dependientes y la recompilación llega en la primera ejecución (o falla). Consecuencias operativas:
  desplegar cambios de especificación **con la aplicación parada o con el paquete sin sesiones
  activas**, porque cambiar un paquete con estado en uso provoca **ORA-04068** en las sesiones vivas;
  revisar `USER_OBJECTS` en busca de `INVALID` **después de cada despliegue** y tratarlo como fallo,
  no como ruido; y evitar el estado a nivel de paquete (variables globales) salvo necesidad
  justificada.
- **Rendimiento**: cambios de contexto SQL↔PL/SQL en bucle son el coste dominante. `BULK COLLECT`
  **siempre con `LIMIT`** (una colección sin límite carga la tabla entera en memoria de sesión),
  `FORALL` con `SAVE EXCEPTIONS` y revisión de `SQL%BULK_EXCEPTIONS`. Medir con `DBMS_HPROF` y
  `PL/Scope`, no por intuición; el plan de ejecución de las consultas es de `oracle-dba-standards`.

**La lógica de negocio en la base de datos, como decisión de arquitectura.** A favor, y es serio:
está donde están los datos (cero latencia de red por operación, conjuntos procesados en el motor),
la integridad se garantiza aunque haya varias aplicaciones y un ETL escribiendo, la transacción es
natural, y el código sobrevive a tres generaciones de framework de front-end —hay PL/SQL de los
noventa dando servicio hoy—. En contra, y también es serio: te ata al motor (y a su factura), el
*tooling* de ingeniería moderna llega tarde o mal (pruebas, dependencias, CI, revisión), escala solo
verticalmente con el servidor de base de datos, mezcla el despliegue de la aplicación con el de los
datos, y el mercado laboral es cada vez más estrecho. **Criterio**: reglas de integridad y procesos
de datos masivos, dentro; orquestación, integración con terceros, presentación y lógica que cambia
al ritmo del negocio, fuera. Y la decisión se toma **una vez y se escribe** (ADR), porque el fallo
caro es la lógica duplicada en los dos sitios, divergiendo en silencio.

## 4. Calidad y testing

- **utPLSQL** como marco de pruebas: verificado leyendo el fichero en crudo, licencia **Apache-2.0**
  (`LICENSE` presente tanto en `main` como en `develop`). Anotaciones (`--%suite`, `--%test`), salida
  en formatos consumibles por CI (JUnit/SonarQube), y **cobertura por bloque**. Es la herramienta que
  hace posible tratar PL/SQL como código de verdad.
- **Prueba lo que duele**: cálculos monetarios, reglas de negocio, cortes por fecha, y **los caminos
  de error** —qué pasa cuando la fila no existe, cuando el `FORALL` falla a la mitad, cuando dos
  sesiones tocan lo mismo—. Datos de prueba creados y destruidos por la propia suite; una suite que
  depende del contenido del esquema de desarrollo es un informe de estado, no un test.
- **Análisis estático**: los avisos del compilador **activados y tratados como errores**
  (`PLSQL_WARNINGS`), que detectan código muerto, `WHEN OTHERS` sin `RAISE` y parámetros mal usados;
  `PL/Scope` para dependencias e identificadores. Hay linters comerciales y libres para PL/SQL:
  verificar estado y licencia antes de adoptar uno (§8).
- **CI**: el esquema se construye desde el repositorio (**el fuente manda, no la base de datos**),
  se despliega en un esquema efímero, se ejecuta la suite y **se falla el build si queda algún objeto
  `INVALID`**. Ese último gate es barato y atrapa la mitad de los incidentes de despliegue.

## 5. Seguridad

- **Bind variables: requisito de seguridad *y* de rendimiento a la vez.** Concatenar valores en una
  sentencia es inyección SQL y además genera una sentencia distinta por valor, que llena la *shared
  pool* y provoca *hard parse* en cada ejecución. Con `USING` no hay ninguna de las dos cosas. No hay
  ningún caso en que concatenar un valor sea la opción correcta.
- **Lo que no admite *bind*** (nombres de tabla, columna, esquema; cláusulas `ORDER BY` dinámicas)
  se valida con **`DBMS_ASSERT`** (`SIMPLE_SQL_NAME`, `SQL_OBJECT_NAME`, `SCHEMA_NAME`) **y** contra
  una lista blanca cerrada. `DBMS_ASSERT` por sí solo no autoriza: comprueba forma, no permiso.
- **`AUTHID` es una decisión de seguridad, no un detalle**: `DEFINER` (por defecto) ejecuta con los
  privilegios del propietario, así que **un procedimiento `DEFINER` con SQL dinámico inyectable
  entrega los privilegios del propietario al atacante** — es el patrón de escalada clásico en Oracle.
  `CURRENT_USER` (*invoker rights*) obliga a que el llamante tenga sus propios permisos y limita el
  daño, a cambio de exigir un modelo de privilegios bien hecho. Regla: **API pública en `DEFINER`,
  mínima y sin dinámico; cualquier cosa con SQL dinámico, revisada línea a línea.**
- **Superficie de la base expuesta**: los permisos se conceden **sobre paquetes, no sobre tablas** —
  la aplicación no debería tener `SELECT`/`INSERT` directo sobre las tablas de negocio—. Roles
  específicos, nada de `GRANT ... TO PUBLIC`, revisión de paquetes peligrosos (`UTL_FILE`,
  `UTL_HTTP`, `UTL_SMTP`, `DBMS_SCHEDULER`, `DBMS_JAVA`) y de las ACL de red: **`UTL_HTTP` accesible
  convierte la base de datos en un cliente HTTP interno, es decir, SSRF desde el corazón del sistema**.
- **Si hay ORDS/APEX**, la base pasa a atender HTTP: es una **frontera de confianza nueva**. El
  esquema de análisis con los mínimos privilegios, los *endpoints* REST autenticados y autorizados
  uno por uno, y la consola de administración de APEX **nunca accesible desde internet**.
- **Forms**: credenciales en línea de comando de `frmweb`/en el `.fmb`, `EXEC_SQL` con literales, y
  la lógica de autorización implementada **solo en el cliente** (ocultar un botón no es un control)
  son los tres hallazgos habituales. La autorización se comprueba **en la base**, siempre.
- **Parcheo**: las *Critical Patch Updates* trimestrales de Oracle cubren base de datos y Fusion
  Middleware; un Forms 12.2.x sin CPU aplicada es un servidor Java heredado sin parches. Calendario y
  triaje, en `vulnerability-management-standards`.

## 6. Salida de Forms y Reports

Cuatro rutas reales, con su criterio:

1. **Oracle APEX** — el destino más frecuente cuando la lógica ya vive en PL/SQL. **Verificado**: es
   una **funcionalidad sin coste adicional de la base de datos Oracle** (todas las ediciones,
   incluida Free y Autonomous), **no un producto aparte que se licencie**; requiere **ORDS**;
   versión **26.1**, publicada el **14-may-2026** (no hubo 25.x), con soporte de la release hasta el
   **30-nov-2027** y ~18 meses por versión. **La dependencia clave, dicha claramente: APEX solo corre
   sobre motor Oracle.** Migrar a APEX **no te saca de la factura de Oracle** —te ata más—, y ese es
   exactamente el motivo por el que Oracle lo empuja como salida de Forms. Es una gran opción si vas
   a seguir con Oracle diez años; es la peor si el objetivo era dejarlo.
2. **Reescritura a Java/web** (o al stack que la casa mantenga): la única ruta que corta la
   dependencia. Cara, y la calidad del resultado la rige `jvm-spring-standards`, no ésta.
3. **Modernizar Forms *in situ*** (subir a 14c, quitar el applet, integrarlo por *reverse proxy*):
   compra 5-7 años de calendario, no resuelve el problema de plantilla ni de arquitectura. Es una
   decisión legítima de "invertir lo mínimo" para un sistema estable con fecha de retirada conocida.
4. **Herramientas de conversión automática** (Forms→APEX, Forms→Java): sirven para el inventario y
   para el andamiaje —pantallas, LOV, tablas—, y **producen código generado que hay que rehacer**:
   traducen la estructura de un cliente pesado, con su modelo de eventos y su estado por bloque, a un
   entorno sin estado, y lo que sale no es idiomático ni mantenible. Úsalas como acelerador del 60%
   mecánico, **nunca como entrega final**, y presupuesta la reescritura del resto.

**Y antes de las cuatro: PL/SQL se queda.** El error caro de estas migraciones es reescribir también
la lógica de negocio que ya está en paquetes y funciona. Se separa Forms (presentación y navegación)
de PL/SQL (negocio), se conserva lo segundo y se sustituye lo primero.

## 7. Prohibiciones

- ❌ PROHIBIDO `WHEN OTHERS THEN NULL`, y cualquier `WHEN OTHERS` que no relance.
- ❌ PROHIBIDO concatenar valores en SQL dinámico. Sin excepción por "es un número".
- ❌ PROHIBIDO SQL dinámico con identificadores sin `DBMS_ASSERT` **y** lista blanca.
- ❌ PROHIBIDO procesar fila a fila lo que resuelve una sentencia de conjunto o un `FORALL`.
- ❌ PROHIBIDO `BULK COLLECT` sin `LIMIT` sobre tablas de tamaño no acotado.
- ❌ PROHIBIDO `COMMIT`/`ROLLBACK` dentro de procedimientos de servicio reutilizables.
- ❌ PROHIBIDO `PRAGMA AUTONOMOUS_TRANSACTION` para esquivar bloqueos o *mutating tables*.
- ❌ PROHIBIDO conceder permisos sobre tablas de negocio a la aplicación pudiendo darlos sobre el API.
- ❌ PROHIBIDO `GRANT ... TO PUBLIC` y privilegios de `UTL_HTTP`/`UTL_FILE`/`DBMS_JAVA` sin caso de uso.
- ❌ PROHIBIDO desplegar dejando objetos `INVALID` sin revisar.
- ❌ PROHIBIDO tratar la base de datos como fuente de verdad del código: el repositorio manda.
- ❌ PROHIBIDO crear módulos Forms **nuevos**; la funcionalidad nueva se escribe fuera.
- ❌ PROHIBIDO la autorización implementada solo en el cliente Forms.
- ❌ PROHIBIDO entregar el resultado de una herramienta de conversión automática sin reescribirlo.
- ❌ PROHIBIDO planificar la salida de Forms sobre la fecha de soporte **recordada**: se lee del PDF
  vigente de *Lifetime Support Policy*, con la versión exacta instalada (§8).

## 8. Verificación web obligatoria

Comprobar siempre, en los PDF oficiales de **Oracle Lifetime Support Policy** (*Fusion Middleware* y
*Technology Products*, que llevan fecha de vigencia en portada y **se revisan varias veces al año**):
Premier/Extended de la **versión exacta** de Forms y Reports instalada y de la del motor; estado de
**Oracle Reports** y de la ruta a Analytics Publisher; versión vigente y ventana de soporte de
**APEX** y de **ORDS**; versión y licencia de **utPLSQL** y de cualquier linter de PL/SQL antes de
adoptarlo; y las **Critical Patch Updates** trimestrales.

**Huecos declarados (sin dato verificado, NO rellenar de memoria)**: (a) el **Statement of Direction
de Oracle Forms** no se ha podido leer en crudo — las dos URL del PDF probadas devolvieron **404**—,
así que la afirmación de que Reports es *terminal release* desde 12.2.1.3.0 y sigue empaquetado en
14.1.2 procede de **notas de versión citadas por buscador, no de cita verbatim**: reconfirmar antes
de usarla en un comité; (b) **no verificado el calendario de la versión 14.1.2 más allá de la fila
`Fusion Middleware 14.1.x`** del PDF —Oracle publica fechas de corrección de errores aparte, por Doc
ID en My Oracle Support (acceso autenticado)—, y **error correction ≠ Premier Support**: la fecha que
de verdad decide cuándo dejas de recibir parches puede ser anterior; (c) coste de licencia de Forms &
Reports (métricas y contrato) — no verificado, no citar cifras; (d) estado y licencia de las
herramientas comerciales de conversión Forms→APEX — no verificados.

**Discrepancia señalada**: la creencia extendida de que "Oracle Forms está desoportado" **contradice
el propio documento de Oracle** (14.1.x con Premier hasta dic-2030); y a la vez, fuentes secundarias
citaban Premier de 14c en dic-2029 o dic-2027 antes de la revisión de 2026 del documento. **Manda el
PDF vigente, con su fecha de vigencia en portada** — y anota esa fecha al citarlo.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
