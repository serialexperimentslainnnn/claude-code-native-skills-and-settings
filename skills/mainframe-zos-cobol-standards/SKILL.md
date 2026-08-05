---
name: mainframe-zos-cobol-standards
description: IBM Z mainframe engineering and the COBOL application estate on z/OS. Use when working with .cbl/.cob/.cpy COBOL sources and copybooks, JCL jobs (//STEP EXEC PGM=, SYSIN DD, IEBGENER, IDCAMS, SORT/DFSORT), CICS command-level EXEC CICS programs and BMS maps, IMS DB/TM and PSB/DBD, Db2 for z/OS with EXEC SQL and DCLGEN and BIND PACKAGE/PLAN, VSAM KSDS/ESDS/RRDS clusters, QSAM datasets and PDS/PDSE members, IBM MQ for z/OS, TSO/ISPF, SDSF, RACF ACF2 or Top Secret profiles, SMF records, WLM service classes, MSU MIPS and rolling four-hour average capacity billing, Tailored Fit Pricing and sub-capacity SCRT reporting, Enterprise COBOL for z/OS or GnuCOBOL compilation, EBCDIC to ASCII conversion, COMP-3 packed decimal and REDEFINES layouts, Rocket Git for z/OS and IBM Dependency Based Build with zAppBuild, Zowe and z/OSMF, z/OS Connect REST APIs over CICS, Wazi and zD&T emulation, or deciding whether to rehost, recompile, auto-translate or rewrite a COBOL application off the mainframe.
---

# Estándares de mainframe z/OS y COBOL

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**El mainframe no es tecnología muerta: es tecnología cara, opaca y con muy poca gente que la
mantenga.** Sigue teniendo hardware nuevo, sistema operativo con hoja de ruta y soporte de
fabricante (§2). Lo que lo convierte en un problema no es que funcione mal —normalmente funciona
mejor que su sustituto— sino tres hechos simultáneos: **el coste es de licencia y consumo, no de
hierro; la lógica de negocio no está donde parece; y el conocimiento no está escrito.**

Por eso, en casi todo compromiso real, **la decisión que está sobre la mesa es migrar o no**, y
esta skill existe para que esa decisión se tome con el criterio técnico correcto —incluida la
opción, muy frecuentemente correcta, de **no migrar**.

Honestidad de partida, dicha aquí y no escondida en §7:
- **Escribir una aplicación *nueva* en COBOL sobre z/OS no se recomienda** salvo que se integre en
  un núcleo COBOL existente que se va a conservar. No es una crítica al lenguaje: es el mercado
  laboral y el coste de plataforma.
- **Mantener y evolucionar la aplicación COBOL existente sí es una opción legítima y a menudo la
  más barata.** "Legacy" no es un diagnóstico.
- **Casi todos los argumentos que se usan para justificar una migración están sin medir** — el
  riesgo de personal el primero (§7).

Cubre: ciclo de vida y soporte de z/OS; el **modelo de licenciamiento como hecho económico
dominante**; el estándar COBOL y la elección de compilador; el ecosistema donde vive de verdad la
lógica (JCL, CICS, IMS, Db2, VSAM, MQ); los datos (EBCDIC, `COMP-3`, `REDEFINES`, copybooks como
esquema); ingeniería moderna real (Git, CI/CD, pruebas, cobertura); exposición por API; y el
catálogo de estrategias de migración con sus modos de fallo.

**No aplica**:
- `legacy-modernization-standards` (**skill paraguas de este bloque**): suya
  la **estrategia** de modernización, el análisis de cartera y la decisión de invertir, migrar o
  retirar; **aquí el criterio técnico de esta plataforma**.
- `migration-projects-standards`: suya la **ejecución del corte** — ensayo, ventana, doble escritura
  y su reconciliación durante la convivencia, cuadre del dato, rollback ensayado y fecha de apagado
  del z/OS de origen.
- `enterprise-architecture-standards` (**ya escrita**): suyos el inventario de aplicaciones, el
  modelo **TIME** y las **"R"** de modernización; aquí qué implica técnicamente cada "R" *en z/OS*.
- `tech-leadership-standards` y `project-management-standards` (cómo se financia y se decide un
  programa de migración; aquí no se hace el caso de negocio).
- `refactoring-tech-debt-standards` (**suyos** *strangler fig*, rama por abstracción y
  caracterización de código sin tests; aquí solo lo específico de la plataforma).
- `testing-qa-standards` (estrategia de prueba), `cicd-standards` (la pipeline),
  `git-workflow-standards` (ramas, commits, releases).
- `sql-standards`, `data-platform-standards`, `oracle-dba-standards`, `sqlserver-dba-standards`
  (motor y lenguaje SQL; **aquí Db2 for z/OS solo en lo que decide sobre el programa**: BIND,
  copybook/DCLGEN, plan de acceso estático).
- `dotnet-standards`, `jvm-spring-standards`, `python-standards`, `go-standards` (destinos
  habituales de una reescritura: **la calidad del código destino es suya, no de aquí**).
- `grc-compliance-standards`, `privacy-engineering-standards`,
  `identity-access-management-standards`, `bcdr-standards`, `backup-recovery-standards`,
  `observability-standards`, `vulnerability-management-standards`.
- `offensive-security-standards`: **esta skill es defensiva**; no contiene técnicas de ataque.
- `ibm-i-rpg-standards` y `mumps-standards`: **son tres plataformas distintas que la gente mete en
  el mismo saco de "legacy" y que no comparten casi nada** — ni sistema operativo, ni modelo de
  datos, ni lenguaje, ni economía. No extrapoles criterio entre ellas.

## 2. Decisiones por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Criterio | Nota verificada |
|---|---|---|
| Release de z/OS | La vigente en soporte, no la más nueva por moda | **z/OS 3.2**: anunciada 22-jul-2025, **GA 30-sep-2025**. z/OS 3.1: GA 29-sep-2023 |
| Ventana de soporte | Planificar el upgrade con ≥12 meses de margen | Política IBM: servicio **5 años desde GA** por release, extensible; ≥12 meses de aviso previo. Patrón confirmado en 2.3 (GA 29-sep-2017 → EOS 30-sep-2022). **EOS de 3.2 no publicada a ago-2026** (§8) |
| Hardware | z17 (Telum II) es la generación vigente | Anuncio 8-abr-2025, GA jun-2025 |
| Estándar COBOL | **ISO/IEC 1989:2023** (3.ª edición, ene-2023) | Cancela y sustituye a ISO/IEC 1989:2014. De pago (CHF 227 en ISO) |
| Compilador en z/OS | **Enterprise COBOL for z/OS** de IBM | Único con soporte pleno de CICS/Db2/IMS y de las optimizaciones del hardware |
| Compilador fuera de z/OS | **GnuCOBOL** para pruebas, CI y rehosting parcial | Estable **3.2 (28-jul-2023)**; trunk en `4.0-early-dev`. **No es sustituto del compilador IBM en producción crítica** |
| Licencia de GnuCOBOL | Verificada leyendo el árbol en crudo | `COPYING` = *"GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"*; `COPYING.LESSER` = *"GNU LESSER GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"* → **compilador GPLv3, runtime LGPLv3** (el binario COBOL propio no queda contaminado) |
| ISAM en GnuCOBOL | Comprobar con qué backend se compiló | El uso de Berkeley DB (`libdb`) para ficheros indexados arrastra condiciones de licencia de Oracle; alternativas: VBISAM o compilar sin ISAM |
| Modelo de licencia z/OS | **Es la variable dominante del TCO, por encima de cualquier decisión de código** | Ver §2.1 |
| SCM | **Git** (Rocket Git for z/OS, o el Git de IBM Open Enterprise Foundation for z/OS) | El repositorio vive fuera del mainframe; ISPF/PDS no es control de versiones |
| Build | **IBM Dependency Based Build (DBB)** + `zAppBuild` | Construcción incremental por dependencias; orquestable desde Jenkins/GitLab/Azure DevOps |
| Acceso desde IDE | **VS Code + Zowe** (o IDz/RDz si ya está pagado) | Conexión vía z/OSMF/SSH o RSE API |

### 2.1 El hecho económico: MSU, R4HA y consumo

**El coste del mainframe se factura por capacidad de software consumida, no por servidor.** Sin
entender esto no se puede evaluar ninguna migración:

- La unidad es el **MSU**; los **MIPS** son medida de marketing/capacidad, no de factura.
- El modelo clásico (MLC sub-capacity) factura por el **pico mensual del *rolling four-hour
  average*** (R4HA) de MSU por LPAR, reportado a IBM con **SCRT**. Consecuencia perversa: **un pico
  de cuatro horas al mes fija el coste del mes entero**, y de ahí prácticas como el *capping* y el
  desplazamiento nocturno de batch.
- **Tailored Fit Pricing (TFP)** es la familia de alternativas al R4HA. Verificado: la *Software
  Consumption Solution* factura el **MSU realmente consumido a lo largo del año, agregado por
  hora**, sobre una **línea base anual comprometida** más una tasa de crecimiento; existen además
  *Hardware Consumption*, *Enterprise Capacity*, *Application Development and Test* y *New
  Application*.
- **Criterio duro**: TFP **no es automáticamente más barato**. El ahorro depende por completo de la
  línea base negociada; una línea base por encima del consumo real devuelve el ahorro a IBM.
  **Exige un análisis del año base con datos SMF/SCRT propios antes de firmar.**
- Antes de proponer una migración por coste, **mide**: perfil de MSU por LPAR y por aplicación,
  peso del batch frente al online, y qué porción del gasto es ISV de terceros (a menudo mayor que
  la de IBM). **Migración cuyo caso de negocio no distingue coste IBM de coste ISV: no es un caso
  de negocio.**
- Los motores especializados (**zIIP**) desplazan carga elegible fuera de la facturación de
  propósito general: la explotación de zIIP es una palanca de coste antes que de rendimiento.

## 3. Estructura y convenciones

- **La lógica de negocio no está solo en el COBOL.** Está repartida entre **JCL** (orden de pasos,
  `COND`/`IF`, ficheros que se crean y borran, `PARM`), **transacciones CICS** y mapas BMS,
  **rutinas IMS/DL-I**, **procedimientos y triggers Db2**, **copybooks** y **tablas de parámetros
  en VSAM**. Un análisis de impacto que solo lee programas COBOL **está incompleto por
  construcción**: empieza por el grafo JCL→PGM→copybook→fichero/tabla.
- **Un copybook es un esquema de datos, no un `#include`**: se versiona y se rompe con las reglas
  de un contrato de datos. Cambiar un `PIC` es incompatible para todo programa que lo copie y para
  todo fichero ya escrito. **Quien toca un copybook publica programas y datasets afectados.**
- **Datos**: el juego nativo es **EBCDIC** (típico `IBM-1047`); toda salida a Git o a un sistema
  distribuido pasa por conversión explícita (eso hace `.gitattributes` en el Git portado). `COMP-3`
  y `COMP` **no son legibles como texto** y su ancho depende del `PIC`; los **`REDEFINES`** dan
  tipos distintos al mismo byte según un discriminante que **a menudo no está en el copybook**. Por
  eso se atasca una extracción "trivial".
- Convenciones de nombres del sitio (HLQ, entornos): **respétalas**; RACF, JCL, backup y SMS
  enrutan por prefijo.
- **`GOTO`, `ALTER`, `PERFORM THRU`** son el patrón real del código antiguo: no los reescribas en
  masa "por limpieza"; solo con test de caracterización previo
  (`refactoring-tech-debt-standards`).

## 4. Calidad y CI

- **Control de versiones real o nada**: el código vive en Git y el mainframe es un destino de
  despliegue. Pasar de PDS a Git **antes** de cualquier modernización.
- **Build reproducible con DBB/zAppBuild**, nunca compilación manual por ISPF: un despliegue debe
  poder rehacerse desde un commit.
- **Pruebas**: unidad de programa/módulo (herramientas de test de z/OS, o ejecución bajo GnuCOBOL
  fuera de plataforma para batch puro) y **regresión por comparación de ficheros de salida**, que
  en batch es lo que más cubre por euro. **Cobertura medida por herramienta, no estimada**; que
  exista y no baje importa más que el número.
- **Datos de prueba enmascarados** y **entornos separados por LPAR o región CICS** con su propio
  catálogo. "El mismo sitio con otro HLQ" no es un entorno.

## 5. Seguridad del stack

- **El ESM (RACF, ACF2 o Top Secret) es la autoridad**; el programa no implementa autorización
  propia. Revisa `UPDATE`/`ALTER` excesivo sobre datasets de producción, `SPECIAL`/`OPERATIONS`
  repartidos, IDs de arranque compartidos y contraseñas de servicio que no caducan.
- **En CICS manda la definición de la transacción y el `USERID` de la región**: un programa
  alcanzable por una transacción mal protegida elude cualquier control escrito en COBOL.
- **Cifrado**: *pervasive encryption* en reposo con claves en ICSF/CEX y capacidades
  **quantum-safe** anunciadas con z/OS 3.2 y z17. Es configuración de plataforma: **no inventes
  cifrado en COBOL**.
- **Objetivo de alto valor con superficie moderna.** El riesgo real no es un ataque exótico a z/OS:
  es **FTP y Telnet heredados sin TLS**, credenciales estáticas en JCL o parámetros, APIs de z/OS
  Connect sin autorización granular, MQ sin control y emuladores 3270 con la sesión guardada.
- **Secretos**: nunca en JCL, `SYSIN`, parámetros ni copybooks (`secrets-management-standards`).
  **SMF al SIEM**: un mainframe cuyos SMF no salen de la plataforma es una zona ciega.

## 6. Exposición por API y rendimiento

- **z/OS Connect** y las APIs REST sobre CICS/IMS/Db2 son la vía soportada. Regla: **envolver no es
  modernizar** — una API sobre una transacción 3270 hereda su modelo conversacional, su
  granularidad y su acoplamiento. Dilo cuando alguien presente el envoltorio como fin del proyecto.
- El trabajo se gobierna por **WLM**, no por prioridad de proceso; y todo cambio que mueva CPU entre
  horas mueve la factura (§2.1): **rendimiento y coste son aquí la misma conversación.**

## 7. Migrar, no migrar, y prohibiciones

**Catálogo de estrategias y lo que cada una compra de verdad:**

| Estrategia | Qué compra | Qué no arregla |
|---|---|---|
| **Rehost / emulación** (COBOL sobre x86 o cloud, Wazi/zD&T y equivalentes) | Salir de la factura MSU manteniendo el código | Nada del código; añade dependencia de un nuevo proveedor de runtime y riesgo de divergencia numérica/EBCDIC |
| **Recompilación** con otro compilador COBOL | Portabilidad, CI fuera de plataforma | Diferencias de dialecto, `COMP-3`, ordenación EBCDIC, y todo lo que estaba en JCL/CICS |
| **Reescritura automática** (COBOL→Java/C#) | Velocidad aparente y un hito de proyecto | **Produce código ilegible que nadie puede mantener**: conserva la estructura COBOL (variables globales, párrafos, `GOTO` traducidos) en un lenguaje que no la soporta. El resultado suele ser *peor* de mantener que el original |
| **Reescritura manual** (con *strangler fig*) | Un sistema realmente mantenible | Es la más cara y la más larga; exige que alguien sepa **qué hace** el sistema, y esa es justo la información que falta |
| **Sustitución por producto** (core bancario, ERP) | Deja de ser problema de ingeniería propio | El *gap fit* y la migración de datos; y el proceso de negocio se adapta al producto, no al revés |

**Criterio de decisión**: no elijas estrategia sin (a) inventario real de artefactos —programas,
JCL, copybooks, transacciones, tablas—, (b) **perfil de coste medido** (§2.1) y (c) al menos un
módulo con test de caracterización que demuestre que sabes reproducir el comportamiento. Sin las
tres, cualquier plan es una apuesta.

**Tasas de éxito y riesgo de personal**: los porcentajes de fracaso que circulan **no se sostienen
en ningún estudio primario localizable**, y el riesgo de personal —el argumento más citado— casi
nunca se mide. Mídelo en tu casa: cuántas personas pueden desplegar en producción, quién conoce
cada subsistema, jubilaciones reales, tiempo de reemplazo observado. Las cifras del sector son no
fiables (§8).

**Prohibiciones:**

- ❌ **PROHIBIDO** citar como hecho las cifras famosas de COBOL ("800.000 millones de líneas",
  "95 % de los cajeros", "80 % de las transacciones presenciales", "edad media 55 años"): son
  extrapolaciones de encuestas de fabricante o citas circulares (§8).
- ❌ Presentar una **reescritura automática** como modernización sin decir que el resultado hereda
  la estructura del original.
- ❌ Firmar un modelo de licenciamiento (TFP incluido) **sin análisis del año base con datos
  propios**.
- ❌ Tratar el **copybook** como detalle de implementación, o cambiar un `PIC` sin analizar los
  datos ya escritos.
- ❌ Exportar datos EBCDIC/`COMP-3` sin resolver antes los `REDEFINES` y sus discriminantes.
- ❌ **Copiar datos de producción a test sin enmascarar.**
- ❌ Usar PDS/PDSE, un gestor de cambios propietario o "el que estaba" **como sustituto de Git** en
  un proyecto nuevo de modernización.
- ❌ Escribir lógica nueva en JCL (`COND`, pasos condicionales encadenados) en vez de en el
  programa.
- ❌ Secretos en JCL, `SYSIN` o parámetros; FTP/Telnet sin TLS hacia z/OS.
- ❌ Declarar terminada una modernización cuando solo se ha puesto una API delante (§6).
- ❌ Migrar "porque es legacy". **Retener es una decisión válida y hay que poder defenderla.**

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Release vigente de z/OS y su calendario.** **Hueco declarado**: a ago-2026 **no localicé la
   fecha de fin de servicio anunciada para z/OS 3.2**; la página de ciclo de vida de IBM
   (`ibm.com/support/pages/zos320`) no la publicaba. La política general (5 años desde GA,
   extensible, ≥12 meses de aviso) apuntaría a finales de 2030, **pero eso es inferencia, no un
   anuncio**: verifícalo en el *lifecycle* de IBM por PID (5650-ZOS) antes de planificar.
2. **Estado de los modelos de licenciamiento por consumo** (Tailored Fit Pricing y sus variantes):
   términos, líneas base y condiciones cambian por anuncio y por contrato. Precios y descuentos
   **no se documentan aquí**: son negociados y confidenciales.
3. **Edición vigente del estándar COBOL** (a ago-2026, ISO/IEC 1989:2023) y nivel de conformidad
   real del compilador que uses; ningún compilador implementa el estándar completo.
4. **GnuCOBOL**: versión estable (a ago-2026, **3.2 de 28-jul-2023**; 4.0 en desarrollo) y licencia
   **leída en crudo** (`COPYING` GPLv3 / `COPYING.LESSER` LGPLv3), además del backend ISAM con que
   se compiló el binario que vas a usar.
5. **Git y CI/CD en z/OS**: qué Git está soportado en tu release (Rocket Git for z/OS frente al
   incluido en IBM Open Enterprise Foundation for z/OS), versión de DBB/zAppBuild y de Zowe.
6. **Cifras del dominio — descartadas aquí por falta de estudio primario:**
   - *"800.000 millones de líneas de COBOL"*: encuesta encargada por **Micro Focus** (fabricante de
     herramientas COBOL, feb-2022), realizada por Vanson Bourne sobre ~1.104 profesionales
     autoseleccionados; el propio Open Mainframe Project estimó ~250.000 millones. **Dos
     estimaciones que difieren más de 3× — discrepancia declarada: ninguna es citable como dato.**
   - *"95 % de los cajeros" / "80 % de las transacciones presenciales" / "43 % de los sistemas
     bancarios"*: proceden de un **gráfico de Reuters de 2017** cuyas fuentes son declaraciones de
     fabricantes, sin metodología ni muestra publicadas. **No citar.**
   - *"220.000 millones de líneas"*: rastreable a estimaciones de los años 90 recicladas por
     prensa. **No citar.**
   - *"Edad media del programador COBOL: 55 años"*: procede de una encuesta de Computerworld (2006,
     357 respuestas) donde el 22 % situaba a su plantilla en 55+ —no una media— y de declaraciones
     posteriores de fabricante. **Indicio de que es un dato circular: no ha cambiado en dos
     décadas**, cuando el envejecimiento de una cohorte fija exigiría que subiera. **No citar.**
7. CVEs y avisos de seguridad de z/OS, CICS, Db2 for z/OS, MQ y z/OS Connect en el canal de IBM.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
