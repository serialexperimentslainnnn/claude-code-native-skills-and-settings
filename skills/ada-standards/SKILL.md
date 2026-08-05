---
name: ada-standards
description: Ada and SPARK for high-integrity software. Use when working with .ads/.adb specification and body files, .gpr GNAT project files and gprbuild/gprclean/gprinstall, alire.toml and the alr package manager, GNAT compilation with -gnat2012/-gnat2022/-gnatwa/-gnatwe/-gnata/-gnato/-gnatX, GNAT Pro versus GNAT FSF builds, gnatprove and SPARK_Mode with the Stone/Bronze/Silver/Gold/Platinum adoption levels, contract aspects Pre/Post/Contract_Cases/Type_Invariant/Predicate/Global/Depends/Loop_Invariant/Loop_Variant, subtype and range constraints with Constraint_Error, pragma Restrictions and pragma Profile (Ravenscar) or Profile (Jorvik), tasks protected objects entries and rendezvous, Ada.Containers Bounded and Formal containers, Unchecked_Deallocation and Unchecked_Conversion, representation clauses and Interfaces.C bindings, gnattest/AUnit, gnatcov coverage and gnatcheck/GNATformat, or evaluating Ada against Rust and Ferrocene for a DO-178C, EN 50128, IEC 61508 or ISO 26262 project.
---

# Estándares de Ada y SPARK

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Ada y su subconjunto verificable **SPARK** en software donde **un fallo cuesta vidas o dinero
irrecuperable**: aviónica, ferrocarril, defensa, espacio, automoción, dispositivos médicos e
infraestructura crítica. Se sigue eligiendo para sistemas nuevos en esos dominios, y ahí no es
legacy — es una decisión técnica actual.

**El eje de esta skill, y la razón de ser del lenguaje: en Ada la mayor parte de la especificación
se escribe en el sistema de tipos, y el compilador o el probador la comprueban.** Un rango de
valores válido no es un `if` al principio de la función: es un subtipo. Una invariante de estructura
no es un comentario: es un `Type_Invariant`. Un contrato de entrada/salida no es un test: es
`Pre`/`Post`, y con SPARK se **prueba** en vez de ejercitarse. Todo el criterio de aquí consiste en
**mover la comprobación al tipo y al contrato** — un código Ada escrito con `Integer` en todas
partes y comprobaciones a mano es C con sintaxis rara, y no compra nada.

Y la contrapartida, dicha sin adornos: **Ada es cara**. Cara en curva de aprendizaje, cara en
contratación (el mercado es pequeño y concentrado en unos pocos sectores y proveedores), y cara en
herramientas si vas a certificar. §7 fija dónde eso se paga solo y dónde es sobrecoste puro.

Cubre: versiones del lenguaje y su soporte; distribuciones de GNAT y su licencia; Alire como
gestor; tipos, subtipos y contratos como mecanismo de diseño; SPARK y los niveles de adopción;
tasking y perfiles de tiempo real; interoperabilidad; y la comparación honesta con Rust.

**No aplica**: ver `safety-critical` (**Ola 7, planificada**: **suyo todo el proceso de seguridad
funcional y certificación** — análisis de peligros, asignación de DAL/SIL/ASIL, objetivos y
evidencias de DO-178C/DO-330, EN 50128, IEC 61508, ISO 26262, cualificación de herramientas,
trazabilidad de requisitos, auditoría y relación con la autoridad; **aquí solo qué aporta el
lenguaje y la prueba formal a esas evidencias, y con qué flags**), `embedded-iot` (**Ola 7,
planificada**: el objetivo físico — MCU, arranque, memoria, periféricos, RTOS, consumo, actualización
en campo; **aquí el código Ada que corre encima y la elección de runtime restringido**),
`rust-standards` (**el competidor directo en memoria segura y la comparación obligada de §7**: el
Rust y su toolchain son suyos; **la elección entre ambos para un proyecto de alta integridad se
argumenta aquí y allí con los mismos datos**), `c-standards` y `cpp-standards` (**el otro lado de
`Interfaces.C`**, y el dueño de MISRA C / CERT C — la alternativa realista cuando la respuesta no
es Ada), `assembly-standards` (código máquina insertado y su justificación),
`cryptography-pki-standards` (elección de algoritmos), `appsec-standards`
(modelado de amenazas), `vulnerability-management-standards` (triaje y SLA),
`testing-qa-standards` (estrategia de prueba: **la prueba formal no sustituye a la estrategia, la
complementa**), `cicd-standards` (la pipeline que ejecuta los gates de §4),
`git-workflow-standards`, `opensource-licensing-standards` (**la excepción de runtime de GNAT es el
dato que decide si puedes distribuir tu binario**, §2), `grc-compliance-standards` (marco
normativo general), `refactoring-tech-debt-standards`, `legacy-modernization-standards` (**Ola 7,
planificada**: hay mucho Ada 83/95 antiguo que no es "alta integridad", solo viejo — la decisión de
cartera es suya).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Elección | Verificado a ago-2026 |
|---|---|---|
| Versión del lenguaje | **Ada 2012** como base segura; **Ada 2022** cuando el compilador y el proceso lo permitan | **Ada 2022 = ISO/IEC 8652:2023, publicado mayo-2023**. GNAT lo implementa con `-gnat2022`; **el default de GNAT sigue siendo Ada 2012** — si quieres 2022, lo pides |
| Estado de Ada 2022 en GNAT | Implementado; **verificar por *Ada Issue*, no en bloque** | El *GNAT Reference Manual* tiene un capítulo "Implementation of Ada 2022 Features" organizado **por AI aprobado por WG9**: esa es la referencia, no un "sí/no". GNAT Pro 22 declaró finalizada la implementación |
| Extensiones experimentales | **Prohibidas en producción** | `-gnatX` habilita features de la plataforma de RFCs; AdaCore las marca explícitamente como no destinadas a producción y sujetas a cambio |
| Distribución comercial | **GNAT Pro** (AdaCore) si vas a certificar | Es lo que trae soporte, cualificación de herramientas y runtimes certificables. **Sin tarifa pública: hueco declarado (§8)** — el coste se negocia y es una partida de proyecto, no un detalle |
| Distribución libre | **GNAT FSF** vía **Alire** | **GNAT Community está discontinuado: 2021 fue la última release** (anuncio de mayo-2022). No lo instales "porque sale primero en Google"; sirve como mucho para *bootstrap* |
| Cómo se instala hoy | **Alire (`alr`)**: elige compilador en el primer arranque y trae el GNAT FSF más reciente | **Alire v2.1.1 (2026-05-29)**. SPARK se añade con `alr with gnatprove`. Los binarios salen de `alire-project/GNAT-FSF-builds` (paquetes: `gnat`, `gprbuild`, `gnatprove`, `gnatdoc`, `gnatcov`, `gnattest`, `gnatformat`) |
| Licencia de Alire | **GPL-3.0, verificada leyendo `LICENSE.txt` en crudo** | Es la licencia **de la herramienta `alr`**, no la de tu código ni la de tus dependencias — pero **léela tú antes de asumir "será MIT"**, que es exactamente la suposición que falla |
| Licencia del runtime | **El dato que decide si puedes distribuir** | La fricción histórica de GNAT era el runtime bajo GPL puro (distribuir el binario exigía términos compatibles con la GPL). El planteamiento actual de AdaCore separa **GNAT Pro** (industrial) de **GNAT FSF** (comunidad, *"without pure GPL run-times"*). **Verifica la excepción de runtime de la distribución exacta que uses antes de distribuir un binario cerrado** (§8) |
| Build | **gprbuild** con ficheros `.gpr` | Es el estándar del ecosistema y lo que entienden las herramientas (`gnatprove`, `gnatcov`, `gnattest`). Alire genera y gestiona el `.gpr` |
| Dependencias | `alire.toml` versionado; versiones fijadas | Ecosistema pequeño: **audita cada crate que metas**, no hay volumen que dé confianza estadística |
| Prueba formal | **SPARK / `gnatprove`**, adoptado por niveles (§4) | Se aplica a **subconjuntos del código**, no al programa entero — ese es el modelo de uso previsto |
| Tiempo real | **`pragma Profile (Ravenscar)`**; `Jorvik` si Ravenscar aprieta de más | **Jorvik es de Ada 2022** (AI12-0291) y está definido junto a Ravenscar en **RM D.13** |

## 3. Diseño: el tipo es el contrato

- **Nunca uses `Integer` para un dominio acotado.** Se declara el tipo o subtipo con su rango
  (`subtype Percent is Integer range 0 .. 100`), y el compilador inserta la comprobación que lanza
  `Constraint_Error` en el punto de la violación — no 200 líneas después. **Una unidad física
  distinta es un tipo distinto**: mezclar metros y pies debe ser un error de compilación, no un
  incidente.
- **Contratos con aspectos, no con comentarios**: `Pre`, `Post`, `Contract_Cases`,
  `Type_Invariant`, `Dynamic_Predicate`/`Static_Predicate`, `Default_Initial_Condition`. Y para
  SPARK, además `Global` y `Depends` (qué estado global toca y de qué depende cada salida) y
  `Loop_Invariant`/`Loop_Variant` en los bucles.
- **`Global => null` es una afirmación fuerte y gratuita**: declara que el subprograma no toca estado
  global. Ponlo donde sea cierto; el probador lo usa y el revisor lo lee.
- **Paquetes con parte privada**: el tipo se exporta como `private` (o `limited private`) y las
  operaciones son las del paquete. Exponer la representación es el fallo de diseño más común en Ada
  escrito por gente que viene de C.
- **Aspectos frente a `pragma`**: Ada 2012 introdujo la sintaxis de aspectos y **es la forma
  preferente** para lo que existe en ambas. `pragma` queda para lo que no tiene aspecto
  (`Restrictions`, `Profile`, `Assertion_Policy`, `Ada_2022`).
- **Memoria dinámica: por defecto, no.** En alta integridad se prohíbe la asignación en montón tras
  la inicialización (`pragma Restrictions (No_Allocators)` o equivalente) y se usan **contenedores
  acotados** (`Ada.Containers.Bounded_*`) o **formales** (`Ada.Containers.Formal_*`, probables con
  SPARK). Si hace falta montón, va con *storage pool* propio y acotado.
- **`Unchecked_Deallocation` y `Unchecked_Conversion` llevan "Unchecked" en el nombre por algo**:
  cada uso es una excepción al modelo, se justifica por escrito y se aísla en un paquete pequeño con
  su propio análisis. Igual con `Address` y las cláusulas de representación.
- **Excepciones**: útiles en el nivel de aplicación, **restringidas o prohibidas** en el nivel
  certificado (coste de análisis y de código de runtime). Decide la política **una vez**, escríbela
  en `pragma Restrictions`, y que el compilador la haga cumplir. `others =>` que traga y sigue está
  prohibido siempre.
- **Tasking**: bajo `Ravenscar` o `Jorvik`, o no lo uses. La diferencia práctica —verificada en
  RM D.13— es que **Jorvik relaja** `No_Implicit_Heap_Allocations`, `No_Relative_Delay`,
  `Max_Entry_Queue_Length => 1`, `Max_Protected_Entries => 1`, la dependencia de `Ada.Calendar` y de
  `Ada.Synchronous_Barriers`, y sustituye `Simple_Barriers` por `Pure_Barriers`; **`No_Requeue_Statements`
  sigue prohibido en ambos**, y **todo código Ravenscar es válido en Jorvik** (no al revés).
  Criterio: **Ravenscar por defecto** porque es lo que da el mejor análisis temporal y la evidencia
  de certificación más asentada; Jorvik cuando Ravenscar obliga a contorsiones (varias entradas por
  objeto protegido, colas no unitarias, `delay` relativo) — **y eso se justifica en un ADR, porque
  compras expresividad pagando analizabilidad**.

## 4. Verificación: niveles de SPARK y gates de CI

**SPARK se adopta por niveles**, no de golpe. Nombres **verbatim** de la guía conjunta AdaCore–Thales
*Implementation Guidance for the Adoption of SPARK*: *"Stone level – valid SPARK; Bronze level –
initialization and correct data flow; Silver level – absence of run-time errors (AoRTE); Gold level –
proof of key integrity properties; and Platinum level – full functional proof of requirements."*

Y su recomendación de uso, que es la parte que la gente se salta: **Stone solo como nivel
intermedio durante la adopción; Bronze en la mayor parte del código posible; Silver como objetivo
por defecto del software crítico; Gold solo en el subconjunto con necesidad específica de seguridad**.
Cada nivel es un subconjunto del anterior. **Platinum es excepcional**: prueba funcional completa
contra requisitos, y su coste lo justifica muy poca gente.

Objetivo por defecto de un proyecto nuevo de alta integridad: **Silver en el núcleo, Bronze en el
resto, Gold en las propiedades que el análisis de peligros señale.**

Gates de CI, en orden de coste creciente:

1. **Compilación sin avisos**: `-gnatwa -gnatwe` (todos los avisos, y los avisos son errores),
   `-gnatf` (mensajes completos), `-gnat2012`/`-gnat2022` explícito y `-gnaty` con el estilo del
   proyecto en el `.gpr`. **`gnatcheck`** con las reglas del proyecto y **GNATformat** para el
   formato — el formato no se discute en revisión.
2. **Build de validación con todas las comprobaciones activas**: `-gnata` (activa `Pre`/`Post` y
   assertions), `-gnato` (comprobación de desbordamiento en enteros), y **sin desactivar
   comprobaciones**. **`pragma Suppress` está prohibido salvo con medida de rendimiento y ADR** —
   quitar las comprobaciones de rango es tirar lo único por lo que estás pagando el lenguaje.
3. **`gnatprove` al nivel comprometido**, y **el nivel es un gate**: si el paquete está declarado
   Silver, un objetivo de prueba sin descargar rompe el build. Las justificaciones (`pragma
   Annotate` para descartar un mensaje) se revisan **una por una** como se revisa un `unsafe` en
   Rust: cada una es una promesa humana que sustituye a una prueba.
4. **Tests con `AUnit`/`gnattest`** cubriendo camino feliz, **bordes y errores** — incluidas las
   excepciones que el diseño permite. La prueba formal cubre ausencia de error de ejecución y
   propiedades; **no cubre que hayas entendido el requisito**.
5. **Cobertura con `gnatcov`** al criterio que exija el nivel de asignación (en aviónica, hasta
   MC/DC). **El criterio de cobertura lo fija la norma, no el equipo** — ver `safety-critical`.
6. **Análisis temporal (WCET) y de pila** si hay requisitos de tiempo real: es lo que el perfil
   Ravenscar/Jorvik existe para hacer posible; si no lo mides, el perfil no te compró nada.

## 5. Seguridad del stack

- **Ada elimina por construcción buena parte de CWE clásicas** (desbordamiento de búfer, índice fuera
  de rango, desbordamiento entero silencioso, uso de no inicializado con SPARK Bronze) — **siempre
  que no desactives las comprobaciones**: un binario con `-gnatp` pierde justamente eso.
- **Lo que Ada NO te da**: corrección lógica, autorización, inyección hacia sistemas externos,
  criptografía mal usada, gestión de secretos, y **nada de lo que pasa al otro lado de
  `Interfaces.C`**. La superficie real de un sistema Ada son sus interfaces y sus bindings.
- **Bindings**: cada uno es una frontera donde se pierden los subtipos. Se envuelve en un paquete que
  **revalida al entrar** (convierte al subtipo Ada y deja saltar `Constraint_Error`) y documenta
  quién libera qué. El lado C es de `c-standards`. Igual con los datos de entrada: se valida
  convirtiendo a subtipos restringidos, no con `if` dispersos, y los protocolos binarios se leen con
  cláusulas de representación, nunca con `Unchecked_Conversion` sobre el búfer.
- **Cadena de suministro**: ecosistema pequeño = pocas manos revisando. Fija versiones en
  `alire.toml`, audita lo que metes y **no asumas la licencia** (§2). CVEs del compilador, runtime,
  RTOS y librerías C enlazadas, en `vulnerability-management-standards`.

## 6. Rendimiento y operabilidad

En este dominio el requisito dominante es **determinismo**, no rendimiento medio; sección breve.

- **Se dimensiona por peor caso** (WCET, uso máximo de pila, cota de memoria), no por media. Un
  sistema que va rápido "casi siempre" no cumple.
- **El coste de las comprobaciones de rango es real pero pequeño y casi nunca es el cuello.** Mide
  antes de suprimir; y si hay que suprimir, en el subprograma concreto y **solo si SPARK ha probado
  que la comprobación no puede fallar** — la única supresión defendible, y para eso está Silver.
- **Sin asignación dinámica tras la inicialización** (§3): fuera fragmentación y latencia
  impredecible. **Runtime**: el más pequeño que cumpla (light / light-tasking / embedded / full);
  cada escalón añade superficie que justificar en certificación.
- **Operabilidad**: manejador de última instancia que registre y lleve el sistema a un estado seguro
  definido. Un `Constraint_Error` en producción es diagnóstico de primer orden: hay que capturarlo.

## 7. Cuándo Ada, cuándo Rust, cuándo ninguno de los dos — y prohibiciones

**Ada/SPARK se paga solo cuando** hay (a) requisito de certificación con evidencia formal admisible,
(b) coste de fallo catastrófico o irreversible, (c) vida útil del sistema en décadas —Ada envejece
excepcionalmente bien y el código de los 90 sigue compilando—, o (d) ya existe una base Ada y un
equipo que la conoce.

**Ada es sobrecoste puro cuando** el problema es una aplicación de negocio, un servicio web, una
herramienta interna o cualquier cosa con requisitos cambiantes y sin coste de fallo catastrófico.
El rigor del sistema de tipos no compensa el coste de contratación y de ecosistema. **Decirlo es
parte del criterio**: recomendar Ada por elegancia técnica en un CRUD es mal asesoramiento.

**Ada frente a Rust — la comparación honesta, con los datos de 2026:**

| Eje | Ada/SPARK | Rust |
|---|---|---|
| Seguridad de memoria | Por comprobaciones + subtipos; **sin uso-después-de-liberar garantizado** salvo con restricciones y SPARK | Garantizada en tiempo de compilación por el *borrow checker* fuera de `unsafe` |
| Prueba formal | **Madura e integrada en el lenguaje** (`gnatprove`, niveles Stone→Platinum). Es su ventaja diferencial y no tiene equivalente en Rust | Herramientas de verificación existen pero **no al nivel de madurez ni de integración de SPARK** |
| Concurrencia | Tasking en el lenguaje, con perfiles analizables (Ravenscar/Jorvik) | Ausencia de *data races* por tipos (`Send`/`Sync`), sin perfil de análisis temporal estándar |
| Cadena certificada | Décadas de historial y de aceptación por autoridades | **Ferrocene**: cualificado por TÜV SÜD para **ISO 26262 (ASIL D)**, **IEC 61508 (SIL 3)** e **IEC 62304 (Clase C)**, y **da soporte a esfuerzos de certificación de cliente hacia IEC 61508 SIL 4 y DO-178C (DAL C)** — que **no es lo mismo que estar cualificado a esos niveles**; hay fuentes que lo confunden. La release 26.02.0 añade **ISO 26262 (ASIL B)** para el subconjunto certificado de `core` |
| Ecosistema y contratación | Pequeño, concentrado, caro; gente escasa pero muy estable | Mucho mayor y creciendo; más fácil contratar, menos historial en certificación |

**Criterio de arbitraje**: si necesitas **prueba formal de propiedades funcionales**, es SPARK, sin
discusión. Si necesitas **seguridad de memoria en código de sistemas con ecosistema y contratación
viables** y el nivel de certificación exigido está dentro de lo que la cadena Rust cubre hoy, Rust
es defendible y cada vez más. **Y no mezcles los niveles entre normas**: el mapeo cruzado
SIL↔ASIL↔DAL que circula en tablas **no es normativo** —ISO 26262 no lo define ni informativamente,
y ASIL es cualitativo mientras SIL es probabilístico—, así que un componente SIL 3 **no** se declara
ASIL D sin evidencia propia. Además, los DAL se asignan por **ARP4754/ARP4761**; DO-178C define los
objetivos de aseguramiento para el DAL dado. Cítalo bien o `safety-critical` te lo corregirá.

**Prohibiciones:**

- ❌ **PROHIBIDO** `pragma Suppress` / `-gnatp` sin medida de rendimiento y sin prueba SPARK de que
  la comprobación suprimida no puede fallar. Es tirar lo único que justifica el lenguaje.
- ❌ Compilar sin `-gnatwa -gnatwe`, o entregar con avisos.
- ❌ `-gnatX` (extensiones experimentales) en producción: AdaCore lo desaconseja explícitamente.
- ❌ `Integer`/`Float` desnudos para dominios acotados; declarar el subtipo es la regla.
- ❌ `Unchecked_Conversion`, `Unchecked_Deallocation`, `Address` y cláusulas de representación sin
  justificación escrita y sin aislamiento en un paquete pequeño.
- ❌ Asignación dinámica tras la inicialización en código certificado.
- ❌ Tasking sin `pragma Profile (Ravenscar)` o `(Jorvik)` en tiempo real; y **Jorvik sin ADR**.
- ❌ `when others =>` que captura y continúa sin registrar ni llevar el sistema a estado seguro.
- ❌ Declarar un nivel SPARK y no hacerlo gate de CI: un nivel que no rompe el build es marketing.
- ❌ Justificaciones de `gnatprove` (`pragma Annotate`) aceptadas en bloque o sin revisor: se
  revisan una a una.
- ❌ Instalar **GNAT Community**: discontinuado, última release 2021 (§2).
- ❌ Distribuir un binario cerrado sin haber leído la excepción de runtime de tu distribución de
  GNAT (§2, §8).
- ❌ Presentar el mapeo SIL↔ASIL↔DAL como normativo (§7).
- ❌ Recomendar Ada para un dominio sin requisito de integridad "porque es más seguro": el coste de
  ecosistema y contratación no se recupera.

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Estado de Ada 2022 en tu compilador**, en el capítulo *"Implementation of Ada 2022 Features"*
   del GNAT Reference Manual, **por Ada Issue**. Confirmar también que Ada 2022 = **ISO/IEC
   8652:2023 (mayo-2023)**.
2. **Distribución de GNAT**: versión de GNAT Pro vigente y su hoja de ruta; versión de GNAT FSF que
   sirve Alire; y **que GNAT Community sigue discontinuado** (última release 2021).
3. **Alire**: versión (a ago-2026 **v2.1.1**, 2026-05-29) y licencia — **GPL-3.0 verificada leyendo
   `LICENSE.txt` en crudo**; los paquetes disponibles en `GNAT-FSF-builds`.
4. **La excepción de runtime de tu distribución exacta**, leída en crudo, **antes de distribuir un
   binario**. Es el dato caro de licencia de este dominio y no se resuelve por analogía con otro
   proyecto GCC. Con `opensource-licensing-standards`.
5. **Coste de GNAT Pro y de las herramientas cualificadas**: **hueco declarado — AdaCore no publica
   tarifas**. Cualquier cifra de coste tiene que venir de tu oferta contractual. Lo mismo para el
   coste de la cualificación de herramientas (DO-330) y de los runtimes certificables.
6. **SPARK**: versión de `gnatprove`, probadores que empaqueta, y **los nombres exactos de los cinco
   niveles** en la edición vigente de *Implementation Guidance for the Adoption of SPARK*.
7. **Ferrocene** (para el arbitraje de §7): niveles **cualificados** frente a niveles **soportados
   para esfuerzos de certificación de cliente** — a ago-2026, ASIL D / SIL 3 / IEC 62304 Clase C
   cualificados, y SIL 4 y DO-178C DAL C como soporte; release 26.02.0 con ASIL B para el
   subconjunto de `core`. **Este matiz se malinterpreta en fuentes secundarias, incluidas académicas.**
8. **Ediciones vigentes de las normas** (DO-178C/DO-330, EN 50128, IEC 61508, ISO 26262) y sus
   nombres de nivel **verbatim** — con `safety-critical` (Ola 7, planificada), que cuando exista es
   **la dueña de todo ese criterio**.
9. CVEs y avisos del compilador, del runtime, del RTOS y de las librerías C enlazadas.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
