---
name: legacy-modernization-standards
description: Umbrella skill for inherited systems - what to do with a system before touching its code, and the router to the platform skill that owns it. Use when facing a system nobody can rebuild from source, a production binary that does not match the repository, a lost or unreproducible build, code archaeology on an undocumented estate, choosing between the R strategies (rehost, replatform, refactor, rearchitect, rebuild, replace, retain, retire) for one system, a runtime or vendor that has stopped shipping updates with no upgrade path, business rules that exist only in the code and in one person about to retire, auto-translation or LLM-assisted rewrite of an old codebase, deciding to freeze and contain a system on purpose, or identifying which legacy platform skill applies to COBOL, RPG, MUMPS, VB6, Delphi, ColdFusion, Struts, Forms, ABAP or a proprietary Unix.
---

# Estándares de modernización de sistemas heredados — skill paraguas

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

> **Esta skill es un paraguas.** Fija los **invariantes** de cualquier modernización y **enruta** a la
> skill de la plataforma concreta (§1.2). Si la pregunta es *"¿cómo se hace esto en COBOL / en RPG /
> en Delphi?"*, manda la skill profunda. Este documento manda **antes**: qué se va a hacer con el
> sistema, con qué precondiciones y con qué criterio de parada.

## 1. Alcance y triggers

### 1.1 Qué decide esta skill

- **La estrategia frente a un sistema heredado, antes de tocar código**: qué "R" se elige y por qué,
  o si la respuesta correcta es **no hacer nada y contenerlo** (§3.3).
- **Las precondiciones duras**: reconstruir el build, identificar el fuente que de verdad corresponde
  al binario en producción, caracterizar el comportamiento — y qué hacer cuando nada de eso existe
  (**arqueología**, §4).
- **Aplicabilidad real de los patrones incrementales**: si hay costura interceptable o no (§3.1).
- **Coste de no hacer nada**, explícito y fechado: soporte, superficie de ataque, personas (§5).
- **Enrutado**: ante un sistema concreto, decidir qué skill de plataforma manda (§1.2).

### 1.2 Enrutado a las skills de plataforma

| Si el sistema está escrito en / corre sobre… | Manda | Estado |
|---|---|---|
| COBOL, JCL, CICS, IMS, VSAM, Db2 z/OS — mainframe IBM Z | `mainframe-zos-cobol-standards` | existe |
| RPG, CL, DDS, ILE — IBM i / AS-400 / iSeries sobre Power | `ibm-i-rpg-standards` | existe |
| MUMPS/M y globals — IRIS/Caché, YottaDB/GT.M, VistA, Epic | `mumps-standards` | existe |
| Visual Basic 6 — `.vbp`/`.frm`/`.cls`, OCX, `msvbvm60.dll` | `vb6-standards` | existe |
| VB.NET — `.vb`, `.vbproj`, `Option Strict`, `Microsoft.VisualBasic` | `vbnet-standards` | existe |
| .NET Framework 4.x — WebForms, WCF, `packages.config`, `web.config` | `dotnet-framework-legacy-standards` | existe |
| Classic ASP 3.0 sobre IIS — `.asp`, `global.asa`, VBScript en `<% %>` | `classic-asp-standards` | existe |
| ABAP dentro de SAP ERP — SE38/SE80, transportes, ECC→S/4HANA | `abap-sap-standards` | existe |
| PL/SQL, Oracle Forms y Reports — `.pks`/`.pkb`, `.fmb` | `plsql-oracle-forms-standards` | existe |
| CFML — Adobe ColdFusion, Lucee, BoxLang, `.cfm`/`.cfc` | `coldfusion-standards` | existe |
| JSP, scriptlets y Apache Struts 1/2 — `struts-config.xml`, OGNL | `jsp-struts-standards` | existe |
| Fortran — forma fija `.f`/`.for`, `COMMON`, `EQUIVALENCE`, HPC numérico | `fortran-standards` | existe |
| Ada y SPARK — `.ads`/`.adb`, GNAT, alta integridad certificada | `ada-standards` | existe |
| Object Pascal — Delphi/RAD Studio (`.pas`/`.dpr`/`.dfm`), Free Pascal/Lazarus | `pascal-delphi-standards` | existe |
| Common Lisp o Scheme — imágenes SBCL, ASDF, `.lisp`/`.scm`/`.rkt` | `lisp-standards` | existe |
| Prolog — `.pl`/`.pro`, SWI/SICStus, cláusulas de Horn, CLP(FD) | `prolog-standards` | existe |
| Smalltalk — imagen viva, `.image`/`.changes`, Pharo, GemStone/S, VisualWorks | `smalltalk-standards` | existe |
| ActionScript, Flash, Flex y AIR — `.as`/`.fla`/`.swf`, AVM1/AVM2 | `actionscript-standards` | existe |
| AIX en Power, Solaris en SPARC, HP-UX en Itanium (Unix propietario) | `aix-solaris-hpux-standards` | existe |
| FreeBSD, OpenBSD, NetBSD y derivados (pfSense/OPNsense/TrueNAS) | `bsd-systems-standards` | existe |

**Regla de arbitraje**: si la fila existe, **el criterio técnico de esa plataforma manda sobre este
documento** — hay plataformas donde la traducción automática produce código inmantenible y otras
donde congelar y encapsular es la respuesta correcta, y eso solo lo sabe la skill de la plataforma.
Este documento manda en **la decisión previa** y en los invariantes de §1.3, que no admiten
excepción de plataforma. **Si la fila no existe** (un sistema propio en un lenguaje vivo pero
abandonado), aplica §1.3 + §3 + §4 y trata la ausencia de skill como lo que es: **no hay criterio
específico verificado, así que se investiga antes de decidir** (§8).

### 1.3 Invariantes de toda modernización

Falsables: cada uno se puede comprobar en una tarde, y el resultado decide si el proyecto existe.

1. **Un sistema que nadie sabe reconstruir desde el fuente no se puede modernizar: se puede
   reescribir.** La prueba es reconstruir el artefacto de producción desde el repositorio en una
   máquina limpia. Si no sale, no hay proyecto de modernización — hay un proyecto de arqueología
   (§4.2), y ese va primero.
2. **Sin caracterización no hay cambio.** Un comportamiento que no está capturado (test, *golden
   master*, tráfico grabado y reproducible) **no se puede preservar**: solo se puede confiar en que
   sí. La caracterización es el gate, no un entregable posterior.
3. **La lógica de negocio no está donde dice la documentación.** Se asume que está en el código y en
   personas, hasta que se demuestre lo contrario contrastando ambas contra el comportamiento real.
4. **Migrar sin fecha de apagado no es migrar, es duplicar.** Toda estrategia incremental nace con
   la fecha de retirada del sistema viejo escrita y con dueño; sin ella, el resultado por defecto es
   dos sistemas vivos para siempre y el doble de coste.
5. **El dato sobrevive al código.** El modelo de datos es el activo que se transfiere; el código es
   reemplazable. Si el plan no dice qué pasa con el dato y cómo se demuestra que cuadra, no es un
   plan (§6).
6. **Congelar es una decisión, no una derrota — pero solo si tiene contención, ventana de parcheo y
   plan de salida fechado.** Congelar sin las tres cosas no es congelar: es abandonar (§3.3).
7. **Nada se decide con una cifra sin metodología.** En este dominio circulan más bulos que datos
   (§2.2). El argumento válido es el mecanismo y el inventario de tu sistema, no un porcentaje.

**No aplica**: además de las plataformas enrutadas en §1.2 —que mandan sobre este documento en su
dominio—, ver `migration-projects-standards` (**la ejecución del corte**: inventario de
dependencias, ensayo, ventana de *cutover*, criterios de abortar, verificación de integridad,
descomisionado. **Frontera dura: la estrategia y qué hacer con el sistema, aquí; el corte, allí**);
`refactoring-tech-debt-standards` (**suyas** las técnicas y su atribución: *strangler fig*, rama por
abstracción, expand/contract, tests de caracterización como técnica, el registro de deuda con
principal e interés. **Aquí solo cuándo son aplicables a un sistema heredado y qué hacer cuando no
lo son**, §3.1); `enterprise-architecture-standards` (**suyos** el inventario de aplicaciones, el
modelo TIME y la elección de "R" **a nivel de cartera**; aquí la "R" **de este sistema** con el
criterio técnico delante); `software-architecture-patterns-standards` (el diseño del destino);
`project-management-standards` (cómo se financia, planifica y compromete el programa);
`microservices-architecture-standards` (**aviso compartido**: descomponer un monolito heredado en
servicios es una *rearchitect*, no una modernización barata); `data-engineering-standards` (los
pipelines de extracción y reproceso en sí); `testing-qa-standards` (estrategia de prueba);
`bcdr-standards` (RTO/RPO y desastre); `itsm-itil-standards` (el servicio y el cambio en operación);
`product-discovery-standards` (si la funcionalidad heredada sigue teniendo valor);
`tech-leadership-standards` (la decisión de inversión y su registro).

## 2. Decisiones por defecto: las "R" y el criterio de cada una

### 2.1 Taxonomía, con atribución verificada

> **No hay una taxonomía canónica de "las R", y las que circulan no significan lo mismo.** Antes de
> usar el término en una reunión, define cuál. Dos fuentes verificables:

- **Gartner (Richard Watson), *"Migrating Applications to the Cloud: Rehost, Refactor, Revise,
  Rebuild, or Replace?"*** — cinco alternativas. Es el origen que citan las demás; **el documento es
  de pago y no pude leer el original**, así que la fecha (2010 según fuentes secundarias, 2011 según
  quien lo cita) **queda declarada como no verificada** (§8).
- **AWS Prescriptive Guidance**, *About the migration strategies*, **verbatim**: *"There are seven
  migration strategies for moving applications to the cloud, known as the 7 Rs"* — **retire, retain,
  rehost, relocate, repurchase, replatform, refactor or re-architect**. Origen del "6 R": Stephen
  Orban, *6 Strategies for Migrating Applications to the Cloud* (blog de AWS, 2016), que acredita
  explícitamente las 5 R de Gartner. **`relocate` es posterior.**

Consecuencia práctica: **"refactor" en las R no es refactorizar** en el sentido de
`refactoring-tech-debt-standards` (cambiar estructura preservando comportamiento). En las R
significa rediseñar. Es la confusión de vocabulario más cara de este dominio.

### 2.2 Cifras que NO se usan

| Cifra | Por qué no |
|---|---|
| "El 70 % de las transformaciones fracasa" | Sin estudio primario; cadena de citas circular. **Ya desmentida en `project-management-standards` §2** — se referencia, no se repite |
| CHAOS Report / Standish | Metodología cuestionada; **desmentida en `project-management-standards`** (Eveleens & Verhoef) |
| "El 84 % de las migraciones de datos fracasa" | Restatement de **Bloor Research 2007**, que medía *overrun or aborted* (retraso o sobrecoste), **no fracaso**. La propia Bloor publicó en **2011** una cifra muy inferior con la misma metodología. Ambos informes son **de analista comercial, patrocinados por fabricante y tras formulario**: no pude leer el primario (§8). **Un proyecto que acaba una semana tarde y uno abortado no son el mismo suceso** |
| "N mil millones de líneas de COBOL", "el 10x developer", "un bug cuesta 100× más tarde" | **Ya descartadas por folclóricas en este catálogo**; ninguna tiene censo o metodología publicada. No sirven para justificar una modernización |
| Cualquier "% de aplicaciones que se pueden retirar" | Circula en material de fabricante sin censo. **Tu porcentaje sale de tu inventario**, y suele salir alto — pero eso se mide, no se cita |

**Regla**: si una cifra famosa no tiene metodología publicada, **decirlo tiene más valor que
citarla**. La modernización se justifica con el mecanismo, el inventario y el coste medido (§5.2).

### 2.3 Criterio por estrategia

| Estrategia | Cuándo es la correcta | Señal de que es la equivocada |
|---|---|---|
| **Retain** (no tocar) | Funciona, tiene soporte vigente, el coste de cambio supera al beneficio, hay dependencias que migran antes | Se elige por no haber mirado; "retain" sin fecha de revisión es §3.3 mal hecho |
| **Retire** (apagar) | Nadie lo usa, o su función la cubre otro sistema. **Se demuestra con telemetría de uso, no preguntando** | Se apaga sin medir y aparece el proceso trimestral que sí lo usaba |
| **Rehost** (mover el mismo binario) | El problema es el **hierro o el contrato** (datacenter que cierra, hardware sin repuestos, soporte del SO caducado), no el software | Se espera que arreglar la infraestructura arregle la aplicación. No lo hace: mueves el problema con menos gente que lo entienda |
| **Replatform** (cambios mínimos) | Hay un componente concreto que se puede sustituir por uno gestionado o soportado sin tocar la lógica (motor de BD, servidor de aplicaciones, versión del runtime) | El "cambio mínimo" acaba tocando el modelo de datos: ya no es replatform |
| **Refactor / rearchitect** | El sistema es tuyo, se puede caracterizar (§4.1), y hay un eje de cambio que el diseño actual bloquea de forma demostrable | Se justifica con "es un monolito". Un monolito que cumple no es un motivo |
| **Rebuild** (reescribir) | Solo con las condiciones excepcionales de `refactoring-tech-debt-standards` §6.2 verificadas **y** el build reconstruido (§4.2). Y aun así, por partes | "Lo reescribimos en N meses". Ver §7 |
| **Replace / repurchase** (comprar) | La funcionalidad es común al sector y no es diferenciadora. **Coste de salida evaluado antes de firmar** | Se compra para no hacer arqueología. La migración de datos y las reglas incrustadas siguen siendo tuyas, y ahora sin fuente |

**El sistema no se elige entero**: una cartera real mezcla varias R por subsistema, y la elección se
revisa cuando cambia un hecho (fin de soporte, pérdida de la persona clave, incidente de seguridad).

## 3. Estrategias incrementales y sus condiciones reales

### 3.1 Strangler fig: necesita una costura interceptable

La técnica y su atribución (Fowler, *Strangler Fig Application*; el texto vigente en su bliki está
fechado el **22-ago-2024** y describe la metáfora observada en Queensland en 2001) son de
`refactoring-tech-debt-standards` §6.1. **Lo que decide aquí es la precondición**:

- **Requiere un punto donde interceptar y desviar tráfico funcionalidad a funcionalidad**, y
  **telemetría de uso** para saber cuándo lo viejo dejó de usarse. Sin ambas cosas no es aplicable.
- **Costuras que sí existen**: HTTP delante de la aplicación, cola o *broker* de mensajes, el
  esquema de base de datos, una capa de servicios ya expuesta, un fichero de intercambio entre lotes.
- **Costuras que la gente cree que existen y no**: una pantalla 5250/3270, un formulario cliente-
  servidor compilado, un job de lote monolítico que lee y escribe la misma base, código que compone
  y ejecuta código en tiempo de ejecución (indirección, `EVAL`, SQL dinámico).
- **Si no hay costura, la primera tarea del proyecto es crearla**, y es un proyecto en sí:
  interponer una fachada, extraer un contrato, o mediar por el dato. **Presentar strangler fig como
  plan cuando no hay costura es un plan que no existe.**
- **La retirada de lo viejo es parte de la tarea**, con fecha (invariante 4). Un strangler fig sin
  fase de retirada ha creado dos sistemas.

### 3.2 Big bang: por qué casi siempre falla y cuándo sí es la única vía

Mecanismos, no estadística: concentra todo el riesgo en un instante sin retroalimentación
intermedia; obliga a congelar funcionalidad durante meses mientras el sistema viejo sigue cambiando
(la meta se aleja sola); y la marcha atrás es teórica porque el dato ya se movió.

**Excepción honesta — hay casos donde es la única vía**, y negarlo es tan deshonesto como
recomendarlo:
- **No existe costura y crearla cuesta más que el corte**: sistemas pequeños, monolíticos y
  autónomos donde interponer una fachada es más trabajo que rehacerlos.
- **El estado no puede vivir partido**: un libro mayor, un sistema de saldos o un registro legal con
  invariantes transaccionales que no toleran doble verdad ni siquiera unas horas. La doble escritura
  aquí no reduce riesgo: lo multiplica.
- **La licencia o el contrato terminan en fecha** y no hay prórroga comprable: el corte es la fecha,
  te guste o no.
- **El sistema origen no permite convivencia técnica**: un solo asiento de licencia, un solo
  identificador de dispositivo, un integrador que no admite dos consumidores.

En esos casos el big bang **no se mitiga con optimismo, se mitiga con ensayo**: la ejecución
(ensayo previo con datos reales, criterios de abortar, verificación de integridad, rollback probado)
es de `migration-projects-standards`.

### 3.3 Congelar con contención: decisión legítima

Congelar es la respuesta correcta cuando el sistema cumple, el conocimiento para cambiarlo no
existe, y el coste de modernizar supera el riesgo residual **contenido**. Exige las tres cosas, por
escrito y con dueño:

1. **Aislamiento**: segmentación de red y default-deny, acceso solo por bastión, **egress filtrado**,
   fachada delante para que ningún consumidor nuevo dependa de su forma interna, y superficie
   expuesta reducida a los flujos documentados (`firewall-policy-standards`, `networking-standards`).
2. **Ventana de parcheo**: qué se parchea, con qué cadencia, y **qué se hace cuando el fabricante
   deja de publicar parches**. Verificado ago-2026 como ejemplo de que la contención tiene reloj
   ajeno: el programa ESU de Windows Server se documenta como *"a last resort option"* y para
   Windows Server 2012/2012 R2 dura **tres años, con fin el 13-oct-2026** — la fecha la pone el
   fabricante, no tú (§8).
3. **Plan de salida fechado**: qué evento dispara la salida (fin de soporte, pérdida de la persona,
   CVE explotable sin parche, cambio normativo), quién lo declara y qué se hace ese día.

**Congelar sin las tres es abandonar.** Y **congelado no significa intocable**: se corrige y se
cumple normativa; lo nuevo se construye fuera, contra la fachada.

## 4. Precondiciones duras: caracterización y arqueología

### 4.1 Caracterización antes de tocar

- **Definición operativa que se usa aquí**: *legacy* es código sin pruebas que capturen su
  comportamiento — **Michael Feathers, *Working Effectively with Legacy Code*, Prentice Hall PTR,
  2004**, de donde procede también el **test de caracterización**: documenta el comportamiento
  **real**, no el correcto. Si el observado difiere de la especificación, **manda el observado** y la
  discrepancia se registra como hallazgo, no se "arregla" de paso.
- **Formas que funcionan en sistemas heredados**, en orden de coste creciente:
  - **Golden master de lotes**: se ejecuta con una entrada representativa y se congela la salida
    completa (ficheros, informes, tablas resultantes) como referencia binaria o normalizada.
  - **Captura de tráfico y reproducción**: se graba tráfico real de producción (respetando
    minimización y enmascarado de dato personal — `privacy-engineering-standards`) y se reproduce
    contra viejo y nuevo comparando respuestas. Es lo que convierte un strangler fig en verificable.
  - **Ejecución en paralelo (*shadow*)**: ambos sistemas procesan lo mismo, solo uno responde, y se
    reconcilian diferencias durante semanas antes de conmutar.
- **Representatividad, no cobertura**: la entrada de caracterización debe incluir el cierre de mes,
  el festivo, el registro corrupto histórico y el caso raro que motivó un parche en 2009. Un juego de
  datos sintético y limpio **caracteriza un sistema que no existe**.
- **Lo que la caracterización no puede capturar** —efectos laterales fuera del sistema (correos,
  ficheros a terceros, impresión, integraciones) y comportamiento dependiente del reloj— se
  inventaría explícitamente. Es donde salen los incidentes del corte.

### 4.2 Arqueología: reconstruir el build y encontrar el fuente

Orden de trabajo, sin saltarse pasos:

1. **Reconstruir el build en una máquina limpia**, no en la del compañero que lleva veinte años.
   Compilador exacto, versión exacta, librerías, licencias del *toolchain*, orden de enlazado,
   parches locales. **Hasta que esto sale, el proyecto de modernización no ha empezado.**
2. **Comparar el artefacto reconstruido con el binario de producción.** Diferencias esperables
   (marcas de tiempo, rutas de build, orden no determinista) se neutralizan antes de concluir nada:
   `SOURCE_DATE_EPOCH` es exactamente eso — *"a standardised environment variable that distributions
   can set centrally and have build tools consume this in order to produce reproducible output"*
   (reproducible-builds.org, verbatim).
3. **Si no coinciden**, y es lo normal, el fuente del repositorio **no es** el de producción. Hay
   parches aplicados en caliente, una rama que nunca se fusionó o una máquina de build perdida. Qué
   se hace:
   - Se **decompila o desensambla lo justo para localizar la diferencia**, no para reescribir.
   - Se busca en copias de seguridad, imágenes de servidores retirados y estaciones de trabajo del
     personal antiguo — **con autorización y con criterio de dato personal**.
   - Si la diferencia no se puede explicar, **el binario es la especificación**: se caracteriza el
     binario (§4.1) y el fuente se degrada a documentación de baja confianza. Se escribe así en el
     ADR, con nombre y fecha.
4. **Congelar el resultado**: el build reproducible, su entorno (contenedor o imagen versionada) y
   el procedimiento entran en el repositorio. Es el entregable que sobrevive aunque el proyecto se
   cancele, y el único que hace estimable cualquier decisión futura.

## 5. Seguridad y coste de no hacer nada

- **La postura por defecto de un sistema heredado es "asume comprometible"**: runtime sin parches,
  criptografía obsoleta, dependencias sin proveedor. El detalle es de la skill de plataforma (§1.2)
  y de `vulnerability-management-standards`; aquí la consecuencia: **la contención (§3.3) es un
  control de seguridad, no una comodidad**, y su ausencia se registra como riesgo aceptado con firma.
- **Datos de producción fuera de producción**: cualquier caracterización, ensayo o entorno paralelo
  que use datos reales exige enmascarado y base jurídica. Es la vulneración más frecuente de estos
  proyectos y es evitable (`privacy-engineering-standards`).
- **El coste de no hacer nada se calcula y se pone en la misma tabla que el de modernizar**, con tres
  partidas y **con tu factura, no con benchmarks**:
  1. **Soporte extendido y contratos**: precio del soporte del fabricante, su escalada anual y su
     **fecha de fin dura** (§3.3). Verificado ago-2026: Microsoft **no publica el precio del ESU en
     la página del programa** — la cifra sale de tu oferta, no de esta skill (§8).
  2. **Riesgo de seguridad**: superficie expuesta, CVEs sin parche disponible y el coste del control
     compensatorio que ya estás pagando.
  3. **Personas**: no "escasez de programadores de X" en abstracto, sino **cuántas personas de tu
     organización pueden modificar el sistema hoy, y su horizonte**. Si la respuesta es una, ya
     tienes el motivo y la fecha.

## 6. Los dos activos reales: el dato y la persona

- **El modelo de datos es el activo que se transfiere.** Antes de elegir estrategia: dónde está el
  dato, cuál es el sistema de registro, **qué reglas de integridad viven fuera del esquema** (en el
  código, en un lote nocturno, en una hoja de cálculo) y qué pasa con el histórico que la aplicación
  nueva no modela. Documentarlo con dueño es **el único trabajo que hay que hacer aunque nunca se
  migre**.
- **La extracción no es la migración.** Sacar el dato es lo fácil; demostrar que cuadra en destino es
  lo que se subestima, y su ejecución es de `migration-projects-standards` (integridad,
  reconciliación) con los pipelines en `data-engineering-standards`.
- **La lógica que solo existe en el código y en una persona** es riesgo con dueño y fecha: se extrae
  de esa persona **la regla, no la documentación** —qué decide, con qué entradas, con qué
  excepciones— y **cada regla se convierte en un caso de caracterización ejecutable** (§4.1). Una
  entrevista sin test asociado se evapora; su conservación es de `knowledge-management-standards`.
- **Aviso**: la persona clave suele ser también quien mantiene el sistema en pie. Programar su
  sustitución y la modernización a la vez es la forma más habitual de perder ambas cosas.

## 7. Sostenibilidad y prohibiciones

**Cadencia**: la decisión sobre un sistema heredado **caduca**. Se revisa al menos anualmente y
siempre que cambie un hecho: fin de soporte anunciado, CVE explotable sin parche, salida de la
persona clave, cambio normativo, o que el fabricante venda el producto. La revisión produce una
decisión fechada, no un informe.

**PROHIBIDO**
- ❌ **Reescribir sin tests de caracterización.** Sin comportamiento capturado no se está migrando
  funcionalidad: se está adivinando cuál era.
- ❌ **Migrar y mantener las dos versiones vivas indefinidamente sin fecha de apagado.** Toda
  estrategia incremental nace con la fecha de retirada del viejo y con dueño (invariante 4).
- ❌ **"Lo reescribimos en N meses" sin haber reconstruido antes el build** (§4.2). Una estimación
  sobre un sistema que no se sabe compilar no es una estimación.
- ❌ Presentar **strangler fig** como plan cuando **no hay costura interceptable** (§3.1).
- ❌ **Traducción automática de código a otro lenguaje presentada como modernización**: hereda la
  estructura del original, pierde los idiomas del destino y sustituye un sistema que alguien entendía
  por uno que no entiende nadie. Como paso intermedio con caracterización y plan de rehumanización
  posterior, puede valer; **como entregable final, no**.
- ❌ **Justificar la decisión con cifras de fracaso sin metodología** (§2.2), en cualquier dirección.
- ❌ **Reescritura asistida por LLM presentada con una cifra de productividad.** El único ensayo
  aleatorizado con metodología publicada en esta línea —METR, arXiv 2507.09089— midió **lo contrario
  de lo esperado** en desarrolladores experimentados sobre **su propio** código maduro, y **la propia
  METR lo marca como histórico**; la evidencia la mantiene `ai-agent-workflow-standards`. **La
  consecuencia aquí**: el LLM es excelente **leyendo** código heredado —explicar una rutina, localizar
  dónde se decide algo, proponer candidatos de test de caracterización— y **su salida se verifica
  contra la caracterización, siempre**. Su límite honesto: no sabe qué regla de negocio hay detrás de
  un caso especial escrito en 1998, porque esa información **no está en el código**.
- ❌ Congelar **sin** aislamiento, ventana de parcheo y plan de salida fechado (§3.3).
- ❌ Copiar datos de producción a un entorno de caracterización o ensayo **sin enmascarar**.
- ❌ Apagar un sistema **sin telemetría de uso** que demuestre que nadie lo usa (§2.3, *retire*).
- ❌ Elegir "R" en una hoja de cálculo **sin el criterio técnico de la plataforma delante** (§1.2).
- ❌ Tratar el fuente del repositorio como el de producción **sin haberlo comprobado** (§4.2).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, **búscalo — no lo recuerdes**:

1. **Fin de soporte y de soporte extendido** de cada componente del sistema (SO, runtime, motor de
   BD, servidor de aplicaciones, hardware), en la **página de ciclo de vida del fabricante**, no en
   un agregador. Es el dato que fija la fecha del plan de salida (§3.3) y el que más caduca.
2. **Precio y condiciones del soporte extendido** (§5): **hueco declarado** — ni Microsoft en la
   página del ESU ni Oracle, IBM o SAP publican tarifa. Sale de tu contrato; no se cita de un blog.
3. **CVEs sin parche disponible** del stack heredado, con KEV/EPSS, antes de decidir contener en vez
   de migrar (`vulnerability-management-standards`).
4. **Taxonomía de las R** (§2.1): **hueco declarado** — el documento de Gartner es de pago y las
   fuentes secundarias discrepan entre 2010 y 2011. La lista de AWS sí es pública y está citada
   verbatim; confirma que no ha cambiado.
5. **Cifras de fracaso de migraciones** (§2.2): **hueco declarado** — los informes de Bloor Research
   (2007 y 2011, Philip Howard) están tras formulario y patrocinados por fabricante y **no pude leer
   el primario**. Si necesitas citarlas, léelas tú y di **qué miden exactamente**.
6. **Evidencia sobre asistencia por LLM en código heredado**: estado de los estudios con metodología
   publicada vía `ai-agent-workflow-standards`, que es quien la mantiene. **Cualquier cifra de
   productividad de un fabricante de herramientas es material comercial** salvo que publique diseño
   y datos.
7. **Estado de las skills de plataforma de §1.2** y si ha aparecido alguna nueva: la tabla es el
   valor principal de esta skill y degrada en silencio si se queda vieja.

Si no puedes verificar, dilo explícitamente en vez de suponer.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
