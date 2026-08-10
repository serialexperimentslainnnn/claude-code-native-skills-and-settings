---
name: ibm-i-rpg-standards
description: IBM i (AS/400, iSeries, System i) application engineering on Power. Use when working with RPG sources (.rpgle, .sqlrpgle, RPG III/RPGLE, **FREE fully free-form, /COPY and /INCLUDE prototypes), CL programs (.clle, CRTBNDCL, CL commands like WRKACTJOB, WRKSPLF, DSPFFD), DDS physical and logical files and display files (.pf, .lf, .dspf, .prtf), ILE modules, service programs, binding directories and activation groups (CRTRPGMOD, CRTSRVPGM, CRTPGM, ACTGRP), IFS and QSYS.LIB objects, library lists and *LIBL, Db2 for i with embedded SQL, SQL stored procedures, Run SQL Scripts, ACS, and IBM i Services SQL views (QSYS2, SYSTOOLS), record-level access opcodes (CHAIN, SETLL, READE, WRITE, UPDATE), journaling and commitment control, extracting business rules from RPG/CL/DDS for a characterization or modernization gate (DSPPGMREF, DSPDBR, QSYS2.PROGRAM_INFO, BOUND_MODULE_INFO, exit points via WRKREGINF or QSYS2.EXIT_POINT_INFO, Query/400 *QRYDFN, DDS validity-checking keywords, ADDPFTRG/ADDPFCST triggers and constraints), Db2 for i as a migration or CDC source (journals and journal receivers, CRTJRNRCV, CRTJRN, STRJRNPF, IMAGES(*BOTH), MNGRCV, ADDRMTJRN, RCVJRNE, QSYS2.DISPLAY_JOURNAL, remote journal, CPYTOIMPF and STMFCCSID, multi-member physical files and CREATE ALIAS, packed and zoned decimal, numeric dates, EBCDIC and CCSID 65535), IBM i Access Client Solutions, Rational Developer for i (RDi), VS Code with Code for IBM i, Merlin, Integrated Web Services (IWS), 5250 green-screen modernization, user profiles and adopted authority (USRPRF *OWNER, *ALLOBJ), QSECURITY system value, Technology Refresh levels, or IBM i release upgrades and per-core subscription licensing tiers.
---

# Estándares de IBM i y RPG

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**IBM i (AS/400) es la plataforma legacy que mejor envejece y peor se entiende desde fuera.** No
está congelada: tiene releases nuevos, *Technology Refresh* periódicos, hardware nuevo (Power11) y
hoja de ruta pública (§2). La compatibilidad hacia atrás es real: un programa RPG de los años 90
compila y corre hoy. Eso es una virtud de ingeniería, no un síntoma de abandono.

Lo que sí es cierto —y hay que decirlo aquí— es lo siguiente:
- **Es una plataforma de proveedor único.** Sistema operativo, base de datos, hardware y buena
  parte del tooling salen de IBM. No hay salida parcial: se está o no se está.
- **El modelo de licencia se ha movido a suscripción** (§2), lo que convierte un coste antes
  amortizado en un coste recurrente. Ese es el cambio económico relevante de los últimos años, no
  la sintaxis del lenguaje.
- **Escribir aplicaciones nuevas en RPG solo tiene sentido dentro de una base RPG existente que se
  va a conservar**, y en ese caso se escribe en **formato totalmente libre** (§3), sin excepción.
- **La deuda real de casi todas estas casas no es el lenguaje: es el estilo** — programas
  monolíticos con acceso nativo por registro, sin ILE, sin control de versiones y con la lógica
  atada a la pantalla 5250.

Cubre: releases y soporte; economía de licencia; RPG y la regla de formato libre; **ILE** (módulos,
programas de servicio, grupos de activación); **Db2 for i** y SQL frente a acceso nativo;
herramientas modernas y control de versiones real; integración (IWS, servicios web, **IBM i
Services**); modernización de pantallas; y seguridad de perfiles y autoridades.

**No aplica**:
- `legacy-modernization-standards` (**skill paraguas de este bloque**): suya la estrategia de
  modernización **de este sistema** —qué "R" se le aplica y con qué costura— y el enrutado a la
  skill de cada plataforma heredada; **aquí el criterio técnico de qué implica cada "R" en IBM i**.
- `migration-projects-standards`: suya la **ejecución del corte** — ensayo, ventana, convivencia y
  reconciliación entre IBM i y el destino, criterio de rollback y descomisionado.
- `enterprise-architecture-standards`: suyos el inventario de aplicaciones y el modelo **TIME**
  **a nivel de cartera** —qué sistemas se tocan, en qué orden y con qué presupuesto—; la "R" de
  **este** sistema la decide `legacy-modernization-standards` dentro de ese marco, y **aquí qué
  implica técnicamente cada opción en IBM i**. Los tres niveles, en una frase: *la cartera es de
  EA, el sistema es de `legacy-modernization`, la plataforma es de aquí.*
- `erp-sap-standards` (**destino frecuente cuando este sistema se sustituye por un paquete**, su
  §3.8: la decisión estándar-frente-a-proceso-propio, el despliegue y la licencia son suyos —y
  condicionan la fecha—; **aquí de dónde sale la regla y de dónde sale el dato**, §3.4 y §3.5. El
  aviso que ambas sostienen: **que SAP traiga un proceso estándar no descubre por sí solo las
  reglas que este sistema ejecuta hoy**, y esas hay que extraerlas igual).
- `tech-leadership-standards` y `project-management-standards` (cómo se financia y se decide).
- `refactoring-tech-debt-standards` (**suyos** *strangler fig*, rama por abstracción y
  caracterización de código sin tests **como técnica**; **aquí dónde vive la lógica de negocio en
  esta plataforma, con qué se localiza y qué forma tiene el caso ejecutable**, §3.4).
- `streaming-cdc-standards` (**la CDC como disciplina es suya**: log frente a triggers frente a
  sondeo, orden y semántica de entrega, esquema del evento, *snapshot* inicial y operación del
  flujo. **Aquí el mecanismo de esta plataforma** —diarios y receptores, qué activar, qué cuesta y
  qué rompe—, §3.5. Regla corta: **el diario es de aquí; leerlo como flujo de cambios es de allí.**
  Aviso: **su catálogo de mecanismos por motor no incluye Db2 for i** (§8)).
- `testing-qa-standards` (estrategia de prueba), `cicd-standards` (la pipeline),
  `git-workflow-standards` (ramas, commits, releases).
- `sql-standards` y `data-platform-standards` (el lenguaje SQL y el diseño de datos genérico;
  **aquí Db2 for i solo en lo que decide sobre el programa**), `oracle-dba-standards` y
  `sqlserver-dba-standards` (otros motores).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (destinos de una
  reescritura: **la calidad del código destino es suya**).
- `grc-compliance-standards`, `privacy-engineering-standards`,
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **esta skill es defensiva**.
- `mainframe-zos-cobol-standards` y `mumps-standards`: **son tres plataformas distintas que la
  gente mete en el mismo saco de "legacy" y que no comparten casi nada** — IBM i no es un
  mainframe, no cobra por MSU, no usa JCL y su base de datos es parte del sistema operativo. No
  extrapoles criterio entre ellas.
- `aix-solaris-hpux-standards` (**la confusión más frecuente de todas, porque comparten
  hardware**): **AIX e IBM i corren sobre Power y pueden convivir como particiones del mismo
  servidor, pero son sistemas operativos distintos y no comparten nada del criterio de aplicación.**
  AIX es Unix —`smit`, LVM, JFS2, `mksysb`, shell y binarios— y es de esa skill; IBM i tiene objetos,
  bibliotecas, ILE y Db2 integrado en el sistema operativo, y es de aquí. **Lo que sí comparten y
  vive allí**: PowerVM, LPAR, VIOS y la HMC, el ciclo de vida del hardware Power y el contrato de
  soporte. Regla corta: **si la respuesta cambia al cambiar de partición, es de la skill del sistema
  operativo; si es del hipervisor o del hierro, es de la de Unix propietario.**

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Release objetivo | **IBM i 7.6** para hardware nuevo; **7.5** si hay Power9 en el parque | 7.6: anunciada 8-abr-2025, **GA 18-abr-2025**; requiere **Power10 o superior**. 7.5 disponible desde may-2022 |
| Release a abandonar | **7.4** | Retirada de comercialización 30-abr-2026; **cambio de nivel de servicio 30-sep-2026**; extensión de pago hasta 30-sep-2029 (política *Enhanced*: 5 años + 3 de extensión). GA de 7.4: 21-jun-2019 |
| Techo por hardware | El release lo limita la generación Power, no el software | Power8 → 7.4 es el último; Power9 → 7.5 es el último; Power10/11 → 7.5 y 7.6 |
| Cadencia | Aplicar **Technology Refresh** con calendario propio | Un TR trae funciones nuevas, no solo correcciones; quedarse en un TR viejo cierra puertas (IBM i Services, open source) |
| Licencia | **Por *tier* de procesador (P05/P10/P20/P30) y, en tiers bajos, por usuarios** | P05/P10: procesador + usuarios (con opción ilimitada); **P20 y superiores: solo por core**. Verificado en el documento de *software tiers* de IBM |
| Modelo comercial | **Suscripción**: la perpetua está en retirada | Perpetuas P05/P10 retiradas 7-may-2024; **P20/P30 retiradas con efecto 1-ene-2026**; en Power11 las licencias IBM i son **solo por suscripción** |
| Lenguaje | **RPG en formato totalmente libre (`**FREE`)** para todo lo nuevo | Ver §3 |
| Acceso a datos | **SQL embebido (`.sqlrpgle`) por defecto** | Ver §3.2 |
| Arquitectura de programa | **ILE**: módulos + programas de servicio + directorio de vinculación | Ver §3.1 |
| IDE | **VS Code + Code for IBM i** como opción por defecto; **RDi** si ya está licenciado | Code for IBM i: repo `codefori/vscode-ibmi`, **licencia MIT** (verificada en el `package.json` del repo), publicado en el Marketplace por HalcyonTech. **No es un producto IBM ni tiene soporte IBM** |
| RDi | Vigilar su calendario | RDi **9.8 discontinúa soporte el 30-abr-2026**; **9.9** publicada el 5-dic-2025. RDi es producto IBM desarrollado y soportado por Fortra |
| Administración | **IBM i Services** (vistas y procedimientos SQL en `QSYS2`/`SYSTOOLS`) | Ver §3.3 |
| SCM | **Git**, con el fuente en el **IFS** (no en miembros de fuente) | Ver §4 |

**Discrepancia declarada**: la terminología de IBM cambió — lo que antes se llamaba *end of
standard support* ahora se anuncia como *date change for service level*. Fuentes de terceros lo
publican como "fin de soporte de 7.4 el 30-sep-2026", pero **no es fin de vida**: hay extensión de
pago hasta 2029. No cites "EOL 2026" sin ese matiz.

**Sobre la comparación de coste perpetua vs. suscripción**: circulan porcentajes (del orden de
+20 %/+40 % a siete años) procedentes de análisis de prensa especializada, no de tarifas
publicadas. **IBM no publica precios en las cartas de anuncio**: cualquier cifra que uses tiene que
venir de tu propia oferta de partner. Ver §8.

## 3. Estructura y convenciones

### 3.1 ILE es la línea que separa mantenible de no mantenible

- **Nada de programas monolíticos nuevos.** Lógica en **módulos** (`CRTRPGMOD`), agrupados en
  **programas de servicio** (`CRTSRVPGM`) y enlazados por **directorio de vinculación**. El
  programa de entrada solo orquesta.
- **Prototipos y `/COPY` de interfaz**: la firma de cada procedimiento exportado vive en un fuente
  de copia compartido; nadie llama a un procedimiento con una firma escrita a mano.
- **Grupos de activación**: elección deliberada y documentada. `*NEW` por llamada es un coste de
  arranque; `*CALLER` propaga; un grupo con nombre por aplicación es lo habitual. **`*DFTACTGRP` es
  compatibilidad con OPM: no en código nuevo.** El grupo de activación determina el ámbito del
  control de compromiso y de los ficheros abiertos: equivocarse aquí produce bugs de transacción,
  no de rendimiento.
- **Firma del programa de servicio**: gestiona el fichero de exportación con control de versiones.
  Añadir exportaciones al final es compatible; reordenarlas obliga a recompilar a todos los
  clientes. Es un contrato binario.

### 3.2 SQL frente a acceso nativo por registro

- **SQL embebido es el default moderno**, y no por moda: el optimizador (SQE) trabaja sobre
  conjuntos, aprovecha índices que no tienes que abrir a mano, y **el código dice qué quiere, no
  cómo recorrerlo**. Un `CHAIN`/`READE` dentro de un bucle es un *join* escrito a mano y sin
  estadísticas.
- Lo que hay que reponer al dejar los *opcodes* nativos: control explícito del bloqueo de registro
  y el "leer una fila por clave" (cursor o `SELECT INTO`). Ninguna de las dos cosas justifica
  escribir la aplicación entera en acceso nativo.
- **Regla dura**: código nuevo con SQL; el antiguo se convierte **solo** cuando toque por otra
  razón y con test que compare resultados. **No hay campaña de conversión masiva que salga bien.**
- **DDS en modo mantenimiento para datos**: tablas, vistas e índices nuevos **con SQL DDL**, no
  PF/LF. DDS sigue siendo lo que hay para pantallas (DSPF) e impresos (PRTF).
- **Journaling y control de compromiso activados** en todo fichero de negocio: es el prerequisito
  de la recuperación y de la replicación, y se descubre tarde.
- La **`*LIBL`** es resolución dinámica y fuente inagotable de incidentes: **la lista de
  bibliotecas de un job de producción es configuración versionada**, no un ajuste de sesión.

### 3.3 Administrar con SQL, no con pantallas

**IBM i Services** (vistas y procedimientos SQL en `QSYS2`/`SYSTOOLS`) son **la vía moderna de
administrar**: objetos, PTFs, jobs, autoridades, usuarios y red se consultan con `SELECT`, lo que
es automatizable, comparable entre entornos y auditable — un `WRKxxx` no deja evidencia. Todo
control periódico (autoridades públicas excesivas, perfiles inactivos, PTFs pendientes) se escribe
como consulta guardada en el repositorio, no como procedimiento manual.

### 3.4 Dónde vive la lógica de negocio y cómo se localiza

**Este es el trabajo que decide si una migración de IBM i sale o no sale**, y el que nadie hace
antes de firmar el proyecto. `legacy-modernization-standards` lo convierte en gate —*sin
caracterización no hay cambio*— y `refactoring-tech-debt-standards` aporta la técnica genérica
(*characterization test*, *golden master*). **Lo que se decide aquí es dónde buscar en esta
plataforma, con qué se busca y qué límite tiene cada herramienta.**

**La regla no está en "los programas RPG". Está repartida en al menos ocho sitios:**

1. **RPG de formato fijo y RPG III/OPM**: además del código, la lógica está en el **ciclo del
   programa** (lo que ejecuta sin que nadie lo escriba), en las **especificaciones de salida** y en
   los **indicadores numéricos** — un `*IN37` que decide un descuento **es** una regla de negocio, y
   no la encuentras buscando texto. Es lo más caro de leer y donde más regla hay.
2. **RPG libre e ILE**: es lo legible, y por eso se sobrepondera. Si el sistema ya está en
   procedimientos y programas de servicio (§3.1), la extracción es más barata, pero **cubre la parte
   del sistema que menos riesgo tiene**.
3. **CL**: pasa por "fontanería" y no siempre lo es. Un `CL` que decide qué programa llamar según el
   contenido de un área de datos, o que fija la `*LIBL` de un proceso, transporta reglas
   —calendario, sociedad, entorno— que no aparecen en ningún RPG.
4. **La base de datos**: *triggers* (`ADDPFTRG`, o `CREATE TRIGGER` en SQL) y **restricciones**
   (`ADDPFCST`: clave, comprobación, referencial). Un trigger es lógica que se ejecuta **sin que
   ningún programa la llame**: si migras los datos sin migrar el trigger, la regla desaparece en
   silencio.
5. **DDS**: la comprobación de validez vive en las palabras clave del propio DDS —`COMP`/`CMP`,
   `RANGE`, `VALUES`, `CHECK`, con `CHKMSGID` para el mensaje— y **se copia del fichero físico al
   fichero de pantalla por referencia de campo en el momento de crear el DSPF**. Verificado en la
   documentación DDS de IBM. Consecuencia doble: (a) hay reglas de dominio declaradas fuera de todo
   programa; (b) **solo se aplican al pasar por la pantalla**: ODBC, DFU, SQL o un servicio web
   escriben sin ellas. Si la regla importa, no está donde la gente cree que está.
6. **La pantalla 5250 misma**: orden de campos, campos protegidos según el caso, la secuencia de
   pantallas que impide llegar a un estado inválido. Es diseño de proceso convertido en control de
   acceso; se pierde entero al sustituir la interfaz.
7. **Puntos de salida (*exit points*)**: programas registrados en la **facilidad de registro**
   (`WRKREGINF`, y las vistas SQL `QSYS2.EXIT_POINT_INFO` y `QSYS2.EXIT_PROGRAM_INFO`, disponibles
   desde 7.4 TR3 / 7.3 TR9 — verificado en la documentación de IBM i Services). Filtran FTP, ODBC,
   DDM o el arranque de sesión, y a menudo llevan reglas de negocio ("este usuario no puede
   descargar esta tabla"). **No aparecen leyendo la aplicación**: hay que ir a buscarlos.
8. **Lo que vive fuera del código**: definiciones de **Query/400** (objetos `*QRYDFN`, `WRKQRY` /
   `RUNQRY`; el producto sigue entregándose con el sistema operativo tras la simplificación de
   licencias de IBM, no está retirado) y, sobre todo, **las hojas de cálculo del usuario final**
   colgando del sistema por ODBC. Ahí es donde suele estar el cálculo real de comisiones, márgenes
   o previsión — el sistema solo guarda los datos. **Un inventario que no las incluye subestima el
   alcance por completo.**

**Herramientas del propio sistema, y qué NO ven:**

| Herramienta | Qué da | Límite que hay que declarar |
|---|---|---|
| `DSPPGMREF` | Objetos a los que se refiere cada programa o paquete SQL: ficheros (con su uso: entrada/salida/actualización), programas, áreas de datos, `*SRVPGM` | **Es lo que había al compilar**, no lo que hay: los nombres pueden no coincidir si hubo *override*. Al actualizar un programa ILE (`UPDPGM`/`UPDSRVPGM`) **se añaden entradas pero nunca se quitan**, así que sobra información obsoleta. **No admite más de una biblioteca por invocación**: hay que recorrerlas. Salida a fichero con el formato `QWHDRPPR` (`QADSPPGM` en `QSYS`) para poder consultarla con SQL |
| `DSPDBR` | Ficheros lógicos y físicos dependientes de uno dado, y dependencias a nivel de miembro | **No muestra todas las relaciones padre/hijo de restricción** — límite reconocido por el propio soporte de IBM, que publica `DSPEDBR` dentro de `QMGTOOLS` para cubrirlo |
| IBM i Services (`QSYS2.PROGRAM_INFO`, `BOUND_MODULE_INFO`, `BOUND_SRVPGM_INFO`, `PROGRAM_EXPORT_IMPORT_INFO`) | El grafo ILE completo **en SQL**: qué módulos hay en cada programa, qué programas de servicio se vinculan, qué se exporta e importa, con qué fuente se compiló | Caras de materializar a nivel de sistema; **IBM recomienda expresamente hacer una instantánea en tabla** y consultar sobre ella. Solo cubren ILE con la profundidad útil |
| Catálogo SQL (`QSYS2.SYSTRIGGERS`, `SYSCST`, `SYSKEYCST`, `SYSINDEXES`, `SYSTABLES`, `SYSCOLUMNS`) | La lógica declarada **en la base**: triggers y restricciones existentes | Solo lo declarado en la base; nada de lo que hace el programa |
| `QSYS2.EXIT_POINT_INFO` / `EXIT_PROGRAM_INFO` | Puntos de salida y programas registrados | Ver punto 7 arriba |

**El punto ciego común, y hay que decirlo antes de prometer cobertura**: todo lo anterior es
**análisis estático**. No ve las llamadas resueltas en ejecución (`CALL` con el nombre en una
variable), ni el SQL dinámico, ni qué biblioteca resolvió realmente la `*LIBL` de ese job. **Un
análisis estático de IBM i nunca está completo**, y el hueco tiene la forma exacta de lo que menos
te esperas. Se complementa con evidencia de ejecución (traza, journal de auditoría, uso real de
objetos) para saber **qué se usa**, y con las herramientas comerciales de análisis del ecosistema
si el presupuesto lo permite — **no cites una por nombre sin verificar que sigue viva y qué cubre**
(§8).

**Qué es una regla de negocio y qué es fontanería.** Sin este filtro se "extraen" 200.000 líneas y
no se caracteriza nada. **Es regla** lo que un responsable del negocio podría querer cambiar sin
tocar tecnología: cálculo (precio, descuento, comisión, impuesto, intereses), elegibilidad y
condición ("este cliente no puede pedir a crédito por encima de X"), transición de estado (qué pasa
al confirmar un pedido y qué queda prohibido después), plazo y calendario, y **derivación de datos**
(cómo se rellena un campo a partir de otros). **Es fontanería** —y no se extrae, se descarta o se
reescribe en el destino con sus propias reglas— la navegación entre pantallas, la validación de
formato, el formateo y edición de números y fechas, la gestión de subficheros y ventanas, el
control de errores de E/S, los *overrides* de fichero, el manejo de `*LIBL` y la apertura y cierre
de ficheros. **Regla dura: si al describirlo en una frase aparece un concepto de la empresa, es
regla; si solo aparecen conceptos de la plataforma, es fontanería.** El caso dudoso —la validación
que es a la vez formato y dominio— se resuelve por el lado caro: se trata como regla.

**El aviso que sostiene todo lo demás**: **una regla que solo existe en el código y que nadie del
negocio reconoce sigue siendo la regla que ejecuta la empresa hoy.** No se descarta porque no
aparezca en ningún documento ni porque el responsable diga que "eso no se hace así": lleva años
decidiendo, y el destino que no la reproduzca cambiará resultados el primer día. Se documenta como
**comportamiento observado**, se lleva a decisión explícita del negocio —conservar, cambiar o
eliminar— y **el cambio, si se decide, es un cambio funcional aparte del corte**, nunca un efecto
lateral de la migración. Lo mismo con los defectos: un cálculo que está mal desde 1998 se
caracteriza **tal como está** y se corrige después.

**Qué se entrega** (es el artefacto que `legacy-modernization-standards` exige como gate, con la
forma que tiene en esta plataforma):
- **Inventario de objetos con dueño y uso real**: programas, ficheros, triggers, restricciones,
  puntos de salida, `*QRYDFN` y consumidores externos por ODBC/DDM — generado con SQL sobre las
  vistas de arriba, **versionado en Git y regenerable**, no un Excel de una vez.
- **Catálogo de reglas**: cada regla con identificador, enunciado en lenguaje de negocio, entradas y
  salidas, excepciones, **evidencia** (programa, procedimiento y línea; o trigger; o palabra clave
  DDS) y dueño de negocio que la ha confirmado o rechazado.
- **Un caso de caracterización ejecutable por regla**, con sus datos: en esta plataforma, lo que
  funciona es la comparación de salidas de **procesos batch** contra ficheros de referencia y la
  llamada directa a procedimientos ILE (§3.1, §4). Una regla sin caso ejecutable **no está
  caracterizada**: está anotada.
- **Lista explícita de lo no cubierto**: lo dinámico, lo interactivo que solo se prueba por 5250 y
  lo que vive en hojas de cálculo. **Un hueco declarado es el entregable; un hueco silencioso es el
  riesgo.**

### 3.5 Db2 for i como origen de datos: journals, extracción y cuadre

**Reparto de autoridad, explícito**: `streaming-cdc-standards` es dueña de **la CDC como disciplina**
—por qué el log gana a los triggers y al sondeo por marca de tiempo, orden y semántica de entrega,
esquema y contrato del evento, gestión del *backfill* y del *snapshot* inicial, y la operación del
flujo—. **De aquí es el mecanismo concreto de esta plataforma**: qué es el diario, qué hay que
activar, qué cuesta y qué rompe. Y hay que decirlo porque la confusión es cara: **el catálogo de
mecanismos de captura por motor no incluye Db2 for i** (§8), así que quien llegue buscando "el
binlog del AS/400" no encuentra nada. El equivalente existe y **es de primera clase**: el *journal*.

**Qué es un *journal* y un *journal receiver*.** El **diario** (`*JRN`) es el objeto lógico que
define qué se registra; el **receptor de diario** (`*JRNRCV`) es el objeto que **contiene
físicamente las entradas de cambio**. Cada cambio a un fichero diariado escribe una entrada con el
tipo de operación, la imagen del registro, y quién, qué programa, qué job y cuándo. Es el mismo
mecanismo que sostiene el control de compromiso, la recuperación y la replicación de alta
disponibilidad de la plataforma: **por eso, en la mayoría de estas casas, ya está encendido**, y
descubrirlo cambia el presupuesto de la migración. Al crear un esquema SQL, Db2 for i crea diario y
receptor y **diaria automáticamente** las tablas creadas en él (`QSQJRN`); lo creado con DDS, no —
ahí hay que activarlo a mano.

**Qué hay que activar y qué cuesta:**
- Se crea el receptor (`CRTJRNRCV`), se crea el diario (`CRTJRN`) y se arranca el diariado de cada
  fichero físico (`STRJRNPF`). Comandos verificados en la documentación de IBM.
- **`IMAGES(*BOTH)` frente a `IMAGES(*AFTER)`** es la decisión que más condiciona el destino:
  `*AFTER` graba solo la imagen posterior; `*BOTH` graba también la anterior, y **es lo que permite
  reconstruir un `UPDATE` como cambio y no como "estado nuevo"**. Herramientas de CDC comerciales
  exigen `*BOTH` o `*AFTER` según el caso. Cuesta el doble de escritura en el receptor: se decide,
  no se hereda.
- **Gestión de receptores**: con `MNGRCV(*SYSTEM)` el sistema desconecta el receptor lleno y engancha
  uno nuevo al alcanzar el umbral; `DLTRCV` decide si además los borra. **Esta es la trampa
  operativa número uno de una CDC sobre IBM i**: si el sistema borra receptores que el lector aún no
  ha procesado, **hay pérdida de datos silenciosa**. La retención de receptores es un requisito
  acordado con el equipo de sistemas antes de conectar nada, y coordinado con la política de copias
  (los receptores viven en disco y son de lo que más crece).
- **Coste**: el diariado escribe a disco en cada cambio y hay sobrecarga adicional por apertura y
  cierre de objetos; a más objetos diariados, más impacto. Se dimensiona con el equipo de
  operaciones, no se enciende masivamente el viernes.
- **Caché de diario** (`JRNCACHE`, opción **42 del sistema operativo, *HA Journal Performance*,
  facturable): mejora el rendimiento agrupando entradas en memoria, pero **las entradas en caché no
  son visibles** para `DSPJRN`, `RCVJRNE`, `RTVJRNE` ni la API `QjoRetrieveJournalEntries`, **ni se
  envían al diario remoto**. Verificado en la documentación de IBM. Traducción: si el lector de CDC
  "va perdiendo la cola", puede no ser un fallo del lector. Y en caída del sistema, lo que está en
  memoria se pierde.
- **Diario remoto**: se añade con `ADDRMTJRN` (no con `CRTJRN`) y permite leer el flujo desde otra
  máquina, con distinción entre entradas confirmadas y no confirmadas. **Es la forma de no poner al
  lector de CDC en el sistema de producción.**

**Vías de lectura y extracción, con criterio:**

| Vía | Cuándo | Advertencia |
|---|---|---|
| `QSYS2.DISPLAY_JOURNAL` (función de tabla SQL, disponible desde 7.1) | Leer entradas de diario **con SQL**; es sobre lo que construyen varias herramientas comerciales | Hay que acotar los parámetros de entrada o el coste se dispara; **interpretar el BLOB con la imagen del registro no es trivial** y es donde se atasca todo el mundo que se lo construye a mano |
| `RCVJRNE` / `RTVJRNE` / API `QjoRetrieveJournalEntries` | La vía de programa: `RCVJRNE` entrega entradas de forma continua a un programa de salida, y es lo que usan productos de replicación | Programa de salida en la máquina; sujeto a la caché de diario (arriba) |
| **SQL sobre el catálogo y las tablas** (JDBC/ODBC, `Run SQL Scripts`) | Carga inicial, perfilado y cuadre | Es la vía correcta para el *snapshot*; el impacto en el sistema de producción se negocia y se ejecuta en ventana |
| `CPYTOIMPF` a fichero de flujo en el IFS | Volcado delimitado cuando no hay conectividad directa | **Se decide el CCSID explícitamente** (`STMFCCSID`): el flujo hereda por defecto el CCSID EBCDIC de la tabla. Verificado en la documentación de IBM |
| DDM / DRDA / servicios web (IWS, §6) | Integración puntual y consulta, no carga masiva | DDM y DRDA son además superficie de acceso a controlar (§5) |
| Herramientas de terceros | Cuando la CDC es continua y el proyecto la paga | **Verifica producto, versión y mecanismo antes de citarlo** (§8) |

**Sobre las herramientas de terceros, sin marketing**: las que se apoyan en esta plataforma leen el
diario, por una de las dos vías de arriba. A ago-2026 se ha verificado que **Qlik Replicate** y el
conector de **Fivetran/HVR** capturan vía `DISPLAY_JOURNAL`, que **Informatica PowerExchange** captura
desde los receptores, y que **Matillion** publica un conector de *streaming* para Db2 for i basado en
entradas de diario. **El conector Db2 oficial de Debezium es de Db2 para Linux/UNIX/Windows y no
cubre Db2 for i**; existe un conector comunitario de terceros que sí lee el diario — **no lo trates
como equivalente en soporte**. Esta lista es señal de mercado, no recomendación: se re-verifica (§8).

**Las trampas del dato que rompen la migración** (esto es lo que hace que el proyecto se retrase, no
el volumen):
- **Empaquetado y con signo** (*packed* / *zoned*): números almacenados con el signo en el último
  medio byte. Décadas de programas escribiendo directo dejan **valores con nibble de signo o de
  dígito inválido** que ningún `SELECT` de muestra descubre y que revientan al convertir en masa.
  **Se perfila el 100 % de las columnas numéricas antes de mover nada**, no una muestra.
- **Fechas en numérico de 6, 7 u 8 dígitos**: `YYMMDD`, el formato de 7 dígitos con siglo delante, o
  `YYYYMMDD`. Trae `0`, `999999`, día 31 en meses de 30, y **ventanas de siglo implícitas en el
  código** ("menor que 40 es 20xx") que hay que extraer como regla (§3.4), no adivinar. Cada
  combinación centinela se decide con el negocio: no todas significan "nulo".
- **Archivos multi-miembro**: un fichero físico con varios miembros —típicamente un histórico por
  año o por sociedad—. **SQL no tiene equivalente y usa el primer miembro por defecto**, así que una
  extracción por SQL se lleva un trozo y parece correcta. Verificado en la documentación de IBM: se
  accede con `CREATE ALIAS` sobre el miembro concreto (o con un lógico sobre todos, u `OVRDBF`).
  **Comprobar la existencia de miembros múltiples es un paso obligatorio del inventario**, y además
  la partición por miembro **es** una regla de negocio implícita.
- **Longitud fija con relleno**: los `CHAR` vienen rellenos de blancos; claves de negocio que en el
  destino se comparan con `VARCHAR` dejan de casar. Se decide una política de recorte **una vez** y
  se aplica igual en carga y en cuadre.
- **EBCDIC y CCSID**: el dato nace en EBCDIC. **`CCSID 65535` (`*HEX`) significa "no convertir"** y es
  el hallazgo clásico: el cliente ODBC/JDBC lo trata como binario o falla. Hay que distinguir la
  columna que es **de verdad binaria** de la que es texto que nunca se etiquetó, y etiquetarla; a
  ciegas se corrompen acentos, `Ñ` y símbolos de moneda. **Redefinir el CCSID no reescribe los
  bytes: cambia cómo se interpretan** — con lo que un error aquí es invisible hasta que alguien lee
  un nombre propio.
- **Campos redefinidos y reutilizados**: un campo cuyo significado depende del valor de otro, un
  `CHAR(30)` que lleva tres subcampos dentro, un "código de estado" al que se le añadieron
  significados nuevos sin cambiar la estructura, o campos declarados y ya no usados que siguen
  llenos de datos viejos. **Ninguna herramienta lo detecta: sale del perfilado de valores reales más
  la extracción de reglas de §3.4.** Un campo con dos significados **se separa en dos en el
  destino**, y esa es una decisión de negocio con dueño.

**El cuadre no es opcional y se diseña antes de extraer.** Mínimo: recuento de filas y **sumas de
control por columna numérica de negocio** (importes, no identificadores) por partición
—ejercicio/sociedad/almacén—, comparadas contra el origen **en el mismo instante lógico**; recuento
de valores distintos y de nulos/centinelas en las columnas clave; y para la CDC, el desfase entre la
última entrada de diario aplicada y la del origen. El cuadre **se ejecuta en el ensayo y en el
corte**, con la tolerancia acordada **por escrito antes** —la ejecución del corte y su
reconciliación son de `migration-projects-standards`; **la definición de qué se cuadra en esta
plataforma es de aquí**—. Una extracción que no cuadra **no se corrige a mano en el destino**: se
corrige el proceso y se vuelve a ejecutar, porque el arreglo manual no es repetible y el corte se
ejecuta más de una vez.

## 4. Calidad, control de versiones y CI

- **El fuente vive en Git, en el IFS** (`.rpgle`/`.sqlrpgle`/`.clle`/`.sql`), **no en miembros de
  `QSYS.LIB`**: un miembro con fecha de modificación no es historia y no permite ramas, diff ni
  revisión. **Es el cambio con más retorno de toda la modernización, y es previo a los demás.**
- **Build reproducible**: script versionado (utilidades del ecosistema Code for IBM i, o CL propio)
  que reconstruye desde cero en una biblioteca limpia. Si nadie sabe recompilar todo, no hay
  entrega: hay parcheo.
- **Entornos separados por biblioteca y `*LIBL`**, con datos de test propios y **enmascarados**.
- **Pruebas**: unidad sobre procedimientos ILE (lo hace posible el diseño de §3.1) y regresión por
  comparación de salidas en batch. Un programa monolítico que solo se prueba por 5250 es, en la
  práctica, no testeable: eso es lo primero que hay que romper.
- **Gate de CI mínimo**: compila limpio sin ignorar avisos, la suite pasa, y **ningún objeto se
  crea a mano en producción**.

## 5. Seguridad del stack

- **`QSECURITY` 40 como mínimo**; 50 en entornos regulados. Por debajo de 40 la integridad del
  sistema no está garantizada; subirlo es un proyecto, pero **quedarse en 30 no es defendible**.
- **`*ALLOBJ` es el problema.** Todo perfil con `*ALLOBJ`/`*SECOFR` es administrador total del
  sistema y de los datos. Inventaría quién lo tiene —incluido por perfil de grupo—, justifícalo uno
  a uno y elimina el resto: aquí aparecen perfiles de aplicación y usuarios de servicio con
  autoridad total.
- **Autoridad pública**: `*EXCLUDE` en objetos de datos y concesión por lista de autorización.
  `*PUBLIC *CHANGE` en bibliotecas de negocio es el hallazgo de auditoría garantizado.
- **Autoridad adoptada (`USRPRF(*OWNER)`)** da acceso solo mientras corre el programa, y es riesgo
  si el programa permite llegar a línea de comandos. Adopta desde el objeto más pequeño posible,
  controla la propagación (`USEADPAUT`), y **ningún programa que adopta autoridad ofrece entrada de
  comandos**.
- **La puerta trasera no es el 5250**: son las interfaces abiertas (FTP, ODBC/JDBC, DRDA, DDM,
  REST). Un usuario limitado por menú puede leer todas las tablas por ODBC si no hay programas de
  salida ni autoridad a nivel de objeto. **La seguridad va en el objeto, no en el menú.**
- **MFA nativa**: 7.6 incorpora TOTP en el sistema operativo, aplicable a todos los puntos de
  autenticación (5250, FTP) y a perfiles SST/DST, sin coste adicional — razón suficiente, por sí
  sola, para planificar el salto. 7.6 añade además cifrado del ASP del sistema (SYSBAS): verifica
  el impacto operativo antes de activarlo.
- **`QAUDJRN` activado y exportado al SIEM**: si el journal de auditoría no sale de la máquina, es
  una zona ciega.

## 6. Integración y modernización de la interfaz

- **Servicios web**: **IWS** expone un programa o procedimiento como REST/SOAP sin salir de la
  plataforma; para consumo, cliente HTTP nativo o funciones SQL. Con volumen o integración compleja,
  la alternativa es un servicio externo que hable Db2 for i por SQL.
- **La trampa habitual: envolver la pantalla 5250 en web sin rediseñar el flujo.** Sale la misma
  secuencia de pantallas con CSS, con su navegación paso a paso, su validación campo a campo y su
  sesión conversacional: **se gana aspecto, no usabilidad ni desacoplamiento**. Requisito previo a
  cualquier interfaz nueva: que la lógica esté en procedimientos ILE invocables sin pantalla
  (§3.1). Mientras viva en el programa de la DSPF, la capa web es maquillaje.
- **API antes que pantalla**: la unidad de reutilización es el procedimiento, no el programa
  interactivo.

## 7. Cuándo quedarse, cuándo migrar y prohibiciones

**Quedarse es correcto —y lo es más veces de lo que se cree— cuando:**
- La aplicación cubre el negocio, el coste total (licencia + soporte + personal) es conocido y
  competitivo, y hay hardware Power en soporte con camino a 7.5/7.6.
- La operación es lo que la plataforma hace excepcionalmente bien: batch fiable, base de datos
  integrada, muy poca administración por transacción, disponibilidad alta con equipo pequeño.
- Se puede modernizar *dentro*: ILE, SQL, Git, CI, APIs. **Esa ruta es dramáticamente más barata
  que reescribir y casi nadie la agota antes de plantear la migración.**

**Migrar tiene sentido cuando** el proveedor único es un riesgo aceptado por dirección, cuando el
coste de suscripción deja de ser competitivo frente al valor, cuando la funcionalidad se compra ya
hecha (ERP), o cuando no hay ni habrá personal — **medido en tu casa, no en un artículo**.

**Prohibiciones:**

- ❌ **PROHIBIDO** escribir código nuevo en RPG de formato fijo (columnas), en RPG III/OPM o con
  indicadores numéricos como lógica. Todo lo nuevo: **`**FREE`**, procedimientos, variables con
  nombre.
- ❌ Programas monolíticos nuevos sin ILE, o `DFTACTGRP(*YES)` en código nuevo.
- ❌ Acceso nativo por registro para lógica de conjunto nueva (bucles `CHAIN`/`READE` que son un
  *join*).
- ❌ Definir tablas nuevas con DDS en lugar de SQL DDL.
- ❌ **Miembros de fuente de `QSYS.LIB` como control de versiones.** El fuente va a Git, en el IFS.
- ❌ Compilar o crear objetos a mano en producción.
- ❌ `QSECURITY` por debajo de 40; `*ALLOBJ` repartido; `*PUBLIC *CHANGE` en bibliotecas de datos.
- ❌ Programas que adoptan autoridad y permiten línea de comandos.
- ❌ Confiar la seguridad al menú 5250 dejando ODBC/FTP/DDM sin controlar.
- ❌ Presentar como modernización un envoltorio web de las mismas pantallas 5250 (§6).
- ❌ **Prometer que se ha extraído la lógica de negocio a partir de análisis estático** (`DSPPGMREF`,
  vistas de IBM i Services) **sin declarar el punto ciego**: llamadas dinámicas, SQL dinámico y
  resolución por `*LIBL` no se ven ahí (§3.4).
- ❌ Descartar una regla porque nadie del negocio la reconozca, o corregirla dentro del mismo cambio
  que la migra. Se caracteriza tal como está y el cambio funcional va aparte (§3.4).
- ❌ Dar por inventariada la lógica sin haber mirado **triggers, restricciones, palabras clave de
  validez en DDS, programas de puntos de salida, `*QRYDFN` y las hojas de cálculo por ODBC** (§3.4).
- ❌ **Extraer por SQL de un fichero multi-miembro sin comprobar los miembros**: SQL usa el primero y
  el resultado parece correcto (§3.5).
- ❌ Convertir columnas numéricas o fechas en numérico **sobre una muestra**: el perfilado es del
  100 % de las filas (§3.5).
- ❌ Mover datos ignorando el CCSID, o "arreglar" un `CCSID 65535` cambiando la etiqueta sin decidir
  antes si la columna es binaria o texto sin etiquetar (§3.5).
- ❌ Montar una CDC sobre diarios **sin acordar antes la retención de los receptores** con el equipo
  de sistemas: si se borran antes de procesarse, la pérdida es silenciosa (§3.5).
- ❌ Diagnosticar un lector de CDC "que pierde la cola" sin descartar la **caché de diario**: sus
  entradas no son visibles ni se envían al diario remoto (§3.5).
- ❌ Ejecutar un corte sin cuadre definido y tolerancia acordada por escrito, o reparar a mano en el
  destino lo que no cuadró (§3.5).
- ❌ Planificar un upgrade de release sin comprobar antes el techo que impone la generación Power.
- ❌ Citar cifras de coste perpetua-vs-suscripción o de cuota de mercado de IDE sin nombrar la
  fuente y su método (§8).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Release vigente de IBM i y su calendario**: a ago-2026, soportadas 7.6, 7.5 y 7.4 (esta última
   con cambio de nivel de servicio el 30-sep-2026 y extensión hasta 30-sep-2029). **Hueco
   declarado: IBM no había anunciado fechas de fin de soporte para 7.5 ni 7.6.** No las infieras
   como si fueran anuncio; consulta la página oficial de soporte de releases de IBM i (PID
   5770-SS1).
2. **Matriz release ↔ generación Power** y nivel mínimo de firmware antes de comprometer un
   upgrade.
3. **Modelo de licencia vigente**: qué tiers siguen teniendo perpetua, condiciones de la
   suscripción y del *5250 Enterprise Enablement*. **Precios no se documentan aquí: IBM no los
   publica en las cartas de anuncio y solo son fiables vía oferta de partner.**
4. **Estado y licencia de Code for IBM i**: a ago-2026, `codefori/vscode-ibmi`, **licencia MIT**
   verificada en el repositorio; proyecto **comunitario, sin soporte de IBM**. Verifica también si
   sigue siendo el repositorio activo antes de apoyar una decisión en él — el feed de releases de
   GitHub no es la fuente de verdad si el proyecto se muda.
5. **Estado de RDi**: 9.8 con discontinuación de soporte el 30-abr-2026; 9.9 publicada el
   5-dic-2025. Verifica el calendario de 9.9 y quién la soporta (IBM contrata a Fortra).
6. **Nivel de Technology Refresh** vigente para tu release y qué IBM i Services añade: la lista de
   vistas SQL crece en cada TR y determina qué puedes automatizar.
7. Boletines de seguridad de IBM i, PTFs de seguridad acumulativos y CVEs de los componentes open
   source portados (que llegan con su propio calendario).
8. **Cifras de adopción de herramientas** (encuestas de mercado tipo Fortra): son encuestas de
   autoinforme con muestra no publicada; **úsalas como señal de tendencia, nunca como dato duro**.
9. **Todo nombre de comando o de vista SQL de esta skill, contra `ibm.com/docs` del release del
   cliente, antes de teclearlo.** Verificados a ago-2026 en documentación de IBM: `DSPPGMREF`
   (formato de salida `QWHDRPPR` sobre `QADSPPGM`, una sola biblioteca por invocación, entradas que
   se añaden pero no se quitan al actualizar un programa ILE), `DSPDBR` (y el límite con las
   restricciones padre/hijo, que IBM cubre con `DSPEDBR` de `QMGTOOLS`), `WRKREGINF`,
   `QSYS2.EXIT_POINT_INFO` y `EXIT_PROGRAM_INFO` (7.4 TR3 / 7.3 TR9), `QSYS2.PROGRAM_INFO`,
   `BOUND_MODULE_INFO`, `BOUND_SRVPGM_INFO`, `PROGRAM_EXPORT_IMPORT_INFO`, las palabras clave DDS
   `COMP`/`CMP`, `RANGE`, `VALUES`, `CHECK` y `CHKMSGID`, `CRTJRNRCV`, `CRTJRN`, `STRJRNPF`,
   `CHGJRN`, `IMAGES(*BOTH)`/`(*AFTER)`, `MNGRCV(*SYSTEM)`, `DLTRCV`, `ADDRMTJRN`, `RCVJRNE`,
   `RTVJRNE`, `QjoRetrieveJournalEntries`, `JRNCACHE` (opción 42, *HA Journal Performance*),
   `QSYS2.DISPLAY_JOURNAL` (desde 7.1), `CPYTOIMPF` con `STMFCCSID`, y `CREATE ALIAS` sobre un
   miembro concreto. **Un comando inventado le cuesta un día a quien lo teclee: si no lo confirmas,
   no lo escribas.**
10. **Hueco declarado — sintaxis y parámetros exactos**: aquí se fija **qué se decide**, no la
    sintaxis. Los parámetros concretos de `RCVJRNE`, `RCVSIZOPT`, `FIXLENDTA` y el formato de las
    entradas de diario **no se documentan en esta skill** y se consultan en el manual de *Journal
    management* del release en uso. Parte de la verificación anterior se apoyó en documentación de
    releases 7.1-7.6 indistintamente: **confirma en el release del cliente** antes de comprometer un
    diseño.
11. **Herramientas de CDC y análisis de terceros**: a ago-2026 se verificó que Qlik Replicate y el
    conector de Fivetran/HVR capturan vía `QSYS2.DISPLAY_JOURNAL`, que Informatica PowerExchange
    captura desde los receptores de diario, y que Matillion publica un conector de *streaming* para
    Db2 for i basado en entradas de diario. **El conector Db2 oficial de Debezium es de Db2 LUW**;
    para IBM i existe un conector comunitario de terceros. **Hueco declarado: esto se contrastó con
    documentación de producto y discusión de comunidad, no con una matriz de soporte publicada por
    Debezium** — verifica antes de apoyar una decisión de compra, y verifica igual cualquier
    herramienta comercial de análisis de código del ecosistema antes de nombrarla.
12. **Db2 for i no aparece en el catálogo de mecanismos de captura de `streaming-cdc-standards`**
    (verificado en el propio catálogo de skills, ago-2026): esa skill enumera WAL de PostgreSQL,
    binlog de MySQL/MariaDB, LogMiner de Oracle, CDC de SQL Server y *change streams* de MongoDB. El
    mecanismo de esta plataforma es el diario y está en §3.5. **No infieras de esa ausencia que IBM i
    no tiene captura por log: la tiene, y es de primera clase.**

Si la web contradice este documento, **manda la web** y señala la discrepancia.
