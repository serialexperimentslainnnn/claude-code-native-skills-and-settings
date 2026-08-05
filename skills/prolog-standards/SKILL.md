---
name: prolog-standards
description: Logic programming in Prolog and its constraint solving niche. Use when working with .pl, .pro, .prolog, .plt, .P or .qlf files, SWI-Prolog (swipl, pack_install, library(clpfd), library(http/thread_httpd), plunit, :- begin_tests, saved states via qsave_program), SICStus Prolog (sicstus, spld, library(clpfd) and library(clpb)), GNU Prolog (gprolog, gplc), Scryer Prolog (library(clpz)), Trealla, XSB or Ciao, ISO Prolog conformance, Horn clauses, unification and backtracking, the cut operator, first-argument clause indexing, assert/asserta/assertz/retract of dynamic predicates, tabling and SLG resolution (:- table), DCG rules with --> and phrase/2, constraint programming with #=/#\=/label/labeling, or deciding between Prolog and a dedicated solver such as MiniZinc, OR-Tools CP-SAT or an SMT solver.
---

# Estándares de Prolog y programación lógica

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Prolog está vivo, pero su nicho es mucho más estrecho de lo que sugiere su fama.** Hay
implementaciones mantenidas (SWI-Prolog publicó la serie estable **10.0** con parches en 2026), hay
un proveedor comercial vendiendo licencias (SICStus) y hay producción real en planificación,
verificación, análisis de programas y sistemas expertos. Lo que casi nunca hay es una razón para
escribir en Prolog una aplicación de propósito general.

**Cuándo lo eliges de verdad** — y son pocos casos, todos con la misma forma: *el problema es una
relación, no un procedimiento*:

1. **Restricciones combinatorias** (CLP(FD)): horarios, asignación de recursos, secuenciación,
   configuración de producto. **Es el único nicho donde Prolog compite de tú a tú**, y aun así hay
   que comparar (abajo).
2. **Parsing y transformación de lenguaje** con **DCG**: gramáticas declarativas, reversibles y
   probadas por décadas; siguen siendo excelentes para formatos irregulares y NLP simbólico.
3. **Razonamiento sobre hechos y reglas**: análisis estático, consultas sobre grafos de
   dependencias, comprobación de políticas, sistemas expertos con encadenamiento hacia atrás.
4. **Prototipado de semántica**: intérpretes, sistemas de tipos, especificaciones ejecutables.

**La comparación honesta que hay que hacer antes de elegirlo** (y que casi nadie hace):

- **Si el problema es de restricciones puras, un solver dedicado suele ganar.** **MiniZinc** (2.10.0,
  jul-2026) te da un lenguaje de modelado declarativo y **te deja cambiar de backend** —CP, MIP,
  SAT— sin reescribir el modelo. **OR-Tools CP-SAT** (v9.15, 2026) es, en problemas grandes de
  scheduling y asignación, sencillamente más rápido y más operable, y se invoca desde Python o C++
  como una librería más. Un **SMT** (Z3, cvc5) es la respuesta cuando hay aritmética y lógica
  mezcladas o hace falta demostrar insatisfacibilidad. Prolog+CLP(FD) gana cuando el modelo va
  **entrelazado con lógica simbólica**, cuando necesitas generar el modelo con las mismas reglas que
  lo resuelven, o cuando la búsqueda a medida (`labeling/2` con tu heurística) es el valor.
- **Si el problema es "reglas de negocio", un motor de reglas o una tabla de decisión (DMN) es más
  barato de operar y de auditar**, y lo puede mantener alguien que no sepa Prolog.
- **Si el problema es consultar relaciones sobre datos, es una base de datos.** Datalog (recursivo,
  terminante, sin cut) es un punto intermedio muy razonable y muchos motores lo hablan.

**No aplica**: **ningún otro lenguaje del catálogo compite directamente con este** — Prolog no se
sustituye por un lenguaje, se sustituye por un solver o por una base de datos. Frontera formal:
`python-standards`, `go-standards`, `rust-standards`, `typescript-standards`, `jvm-spring-standards`,
`clojure-standards`, `lisp-standards`, `haskell-fp-standards` (**lenguajes de propósito general: el
sistema que rodea al motor lógico se escribe en uno de ellos, con su criterio — y en la arquitectura
por defecto de §3, ellos son el anfitrión y Prolog el componente**); `julia-standards` y
`classical-ml-standards` (**si el problema es de optimización numérica o estadística, no es de aquí**);
`sql-standards` y `graph-db-standards` (**consultas sobre datos relacionados: si la recursión es
sobre un grafo persistente, es suyo**); `nlp-standards` (**PLN estadístico y con modelos**: aquí solo
las DCG como parser simbólico); `ai-agents-standards` y `llm-app-engineering-standards`
(**razonamiento con LLM**: aquí lo simbólico, verificable y determinista — son complementarios, no
alternativas); `data-governance-quality-standards` (reglas de calidad de dato como gobierno);
`software-architecture-patterns-standards` (dónde encaja un componente de razonamiento);
`legacy-modernization-standards` (**skill paraguas** de un motor Prolog heredado: qué "R" se elige,
si se congela, se reescribe o se retira) y `migration-projects-standards` (**la ejecución del
corte** una vez decidido: ensayo, ventana, cuadre del dato, rollback y apagado del origen);
`appsec-standards` y `vulnerability-management-standards` (metodología y triaje; aquí los sinks
concretos, §5); `opensource-licensing-standards` (análisis de licencias; aquí qué licencia tiene cada
implementación, §2); `cicd-standards` (la pipeline).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Elección | Nota verificada (ago-2026) |
|---|---|---|
| Implementación por defecto | **SWI-Prolog** | Serie estable **10.0** (descargas vigentes **10.0.2**); serie de desarrollo 10.1.x. Es la única con ecosistema completo: `pack`, servidor HTTP, `plunit`, tabling, CLP(FD), depurador, build a Wasm |
| Licencia de SWI-Prolog | **BSD Simplificada (BSD-2-Clause)** — leída en crudo del `LICENSE` | *"SWI-Prolog is covered by the Simplified BSD license"*. **Corrige una creencia extendida: muchas fuentes secundarias siguen diciendo LGPL/GPL.** Aviso propio del fichero: puede enlazar librerías con licencias más restrictivas — **comprueba tu build concreto con `?- license.`**, no la portada del proyecto |
| Implementación comercial | **SICStus Prolog**, solo con requisito que lo justifique (soporte contractual, rendimiento de su CLP(FD)/CLP(B), certificación, plataformas exóticas) | **4.10.1, publicada el 3-jul-2025**. Propietaria, licenciada por RISE AB; **no publica tarifas**: licencia + mantenimiento anual, con recargo de reinstauración si dejas caducar el mantenimiento. **El coste de licencia y su renovación es el dato caro** |
| GNU Prolog | **No para proyectos nuevos** | Última estable **1.5.0**, con aviso de copyright hasta **2021** y sin release posterior publicada en su web. Compila a nativo y es ISO-céntrico, pero su ecosistema es mínimo y su cadencia, nula |
| Scryer Prolog | **Solo para trabajo experimental o de conformidad ISO** | Escrito en Rust, muy centrado en ISO y en `library(clpz)`. **Repositorio activo (commits en jul-2026) pero última release etiquetada v0.10.0 (sep-2025) y numeración pre-1.0**: repo vivo ≠ apto para producción. Úsalo por su rigor, no por su estabilidad |
| Estándar | **ISO/IEC 13211** como línea base de portabilidad | **El código real no es portable**: módulos, tabling, CLP(FD), E/S y las librerías están fuera o divergen entre implementaciones. **Asume que eliges implementación, no lenguaje**, y dilo en el ADR |
| Restricciones | **`library(clpfd)`** en SWI/SICStus; `library(clpz)` en Scryer | **Y compáralo con MiniZinc / OR-Tools CP-SAT / SMT antes de decidir** (§1). Si el modelo es de restricciones puras, documenta por qué no usas el solver dedicado |
| Alternativa de solver | **MiniZinc 2.10.0** (jul-2026) o **OR-Tools v9.15** (2026) | MiniZinc desacopla modelo y backend; CP-SAT suele ganar a escala. Ambos se operan desde un lenguaje mayoritario |
| Tabling (SLG) | **`:- table` para todo predicado recursivo sobre datos** | Convierte recursión izquierda no terminante en consulta terminante con memoización. **Es lo que hace utilizable el razonamiento sobre grafos** y evita el 90 % de los cortes defensivos |
| Aritmética | `#=`/`#\=` (CLP(FD), relacional y reversible) frente a `is/2` (direccional) | En código de restricciones, **`is/2` es un error de diseño**: rompe la reversibilidad que justificaba usar Prolog |
| Tests | **plunit** (`:- begin_tests/end_tests`, ficheros `.plt`) | Ejecutable desde CLI con código de salida; ver §4 |
| Empaquetado | **Estado guardado** (`qsave_program`) o script con shebang; SWI `pack` para librerías | El estado guardado tiene el mismo problema de reproducibilidad que una imagen Lisp: se genera desde build limpio, nunca desde una sesión interactiva |

## 3. Estructura y convenciones

- **Arquitectura por defecto: Prolog es un componente, no la aplicación.** El motor lógico vive
  detrás de una interfaz explícita (proceso separado, HTTP, o embebido con su API C/Python) y el
  resto del sistema se escribe en un lenguaje mayoritario. Esto acota el riesgo de relevo, permite
  probar el modelo aislado y hace posible **sustituir el motor por un solver** si §1 cambia de
  respuesta. Escribir el servicio HTTP, la persistencia y la operación entera en Prolog es la
  decisión que convierte un componente valioso en un sistema que nadie quiere tocar.
- **Módulos siempre** (`:- module(nombre, [pred/Aridad, ...])`), con la lista de exportación como
  contrato. Sin módulos, todo predicado es global y una redefinición silenciosa es un bug de horas.
- **Cada predicado documentado con su modo y determinismo** (`+`/`-`/`?`, det/semidet/nondet/multi).
  En Prolog no hay tipos: **el modo y el determinismo son el único contrato**, y si no está escrito,
  no existe.
- **El corte (`!`) es el mayor coste de mantenibilidad del lenguaje.** No es una optimización: cambia
  la semántica declarativa, y un corte añadido para "arreglar" una duplicación rompe la solución
  correcta en el caso que aún no has probado. Criterio:
  - **Prohibido el corte rojo** (el que altera el conjunto de soluciones). Si lo necesitas, la
    lógica está mal factorizada.
  - Para elegir entre alternativas, **`( Cond -> Entonces ; Si_no )`**, que es local y legible.
  - Para determinismo, **primero indexación y guardas al principio del cuerpo**; el corte verde solo
    cuando esas dos no bastan, con comentario que diga qué elección poda.
  - Un corte dentro de una disyunción o después de un `->` es casi siempre un error.
- **Rendimiento = indexación de cláusulas, y la indexación es sobre el primer argumento.** El diseño
  de la cabecera del predicado *es* el diseño del índice: pon el argumento discriminante primero,
  con functor o átomo constante. Un predicado con miles de cláusulas y primer argumento variable
  recorre todas ellas en cada llamada. **Antes de optimizar nada más, mira la indexación** (SWI
  soporta además indexación multiargumento y JIT: verifica qué hace tu implementación, §8).
- **DCG (`-->`, `phrase/2,3`) para todo parsing**: no escribas un parser a mano manipulando listas.
  Y **`phrase/2` con `string_codes`/`atom_codes` explícito**, no con representaciones implícitas.
- **`assert`/`retract` como estado global: prohibidos salvo para hechos cargados una vez.** Son
  variables globales con el peor perfil posible: rompen el backtracking, invalidan índices, no son
  transaccionales y hacen los tests dependientes del orden. El estado se pasa por argumentos.
- **Sin *failure-driven loops*** (`forall/2` y `foldl/4` existen); **sin recursión izquierda sin
  `:- table`**; **listas por diferencias solo donde el perfil lo justifique** (destruyen la
  legibilidad).

## 4. Calidad y CI

- **plunit obligatorio, ejecutable desde CLI** (`swipl -g run_tests -t halt`) con código de salida
  no nulo al fallar. Un test que solo corre en el toplevel no es un gate.
- **Prueba el determinismo, no solo el resultado**: un predicado que debía ser `semidet` y devuelve
  dos soluciones es el bug característico de este lenguaje, y `assertion/1` con
  `forall(Objetivo, ...)` o una comprobación explícita del segundo punto de elección lo detecta.
  Cubre además **fallo** y **excepción** como resultados esperados, no solo el éxito.
- **Gate mínimo**: (1) carga sin warnings de *singleton variables* ni de predicados no definidos —en
  Prolog un typo en un nombre de variable es un warning, no un error, y produce un fallo silencioso;
  (2) comprobación estática disponible en tu implementación (en SWI, `check/0`, `list_undefined/0`,
  `xref`); (3) `plunit` verde; (4) para modelos CLP(FD), **un caso con solución conocida y un caso
  insatisfacible**, ambos con **límite de tiempo**, porque una búsqueda sin cota no falla: cuelga.
- **Todo objetivo de búsqueda lleva presupuesto**: `call_with_time_limit/2`, `call_with_inference_limit/3`
  o el equivalente de tu implementación. Sin cota no hay operabilidad.

*§6 se omite deliberadamente*: la observabilidad, el despliegue y la capacidad de un servicio que
embebe Prolog son de la skill de la plataforma anfitriona (§3) y de `observability-standards`; lo
único específico —cotas de inferencia y de tiempo— está en §4, y el consumo de memoria de la
búsqueda, en §5.

## 5. Seguridad del stack

- **`read_term/2` y familia sobre entrada no confiable es ejecución de código y agotamiento de
  recursos.** Leer un término ajeno **crea átomos y functores arbitrarios** (tabla de átomos:
  superficie de DoS por memoria) y, si luego ese término se pasa a `call/1`, es RCE directa. Criterio:
  **nunca `call/1`, `=..`  ni `assert/1` sobre términos derivados de entrada externa**; parsear con
  DCG a una estructura cerrada y validar contra una lista blanca de functores.
- **`library(sandbox)` de SWI existe y es la respuesta correcta si tienes que evaluar objetivos de
  usuario** (p. ej. un endpoint de consulta). Verifica su estado y sus limitaciones antes de
  confiarle nada: un sandbox de lenguaje es una superficie de bypass, no una garantía.
- **El servidor HTTP de SWI-Prolog es un servidor de aplicaciones completo**: si lo expones, se le
  aplica todo el criterio de `appsec-standards` (autenticación, cabeceras, TLS terminado donde
  corresponda). **Por defecto, no lo expongas**: sirve detrás de un proxy y escuchando en localhost.
- **`shell/1,2` y `process_create/3`**: nunca con argumentos concatenados desde entrada externa.
- **DoS por búsqueda**: un objetivo sin cota de tiempo ni de inferencias es un vector de denegación
  trivial contra cualquier interfaz que acepte parámetros del usuario (§4). El límite es obligatorio
  **en el borde**, no confiado al modelo.
- **Dependencias**: `pack_install/1` descarga y **compila** código de terceros (paquetes con
  extensiones en C). Verifica origen, fija versión y revisa lo que compila; el ecosistema es pequeño
  y no tiene proceso de auditoría.

## 7. Sostenibilidad, migración y prohibiciones

**Criterio de adopción** (decidir antes, y por escrito):
1. **¿El problema es una relación o un procedimiento?** Si es un procedimiento, no es Prolog.
2. **¿Un solver dedicado o Datalog lo resuelven?** Si sí, úsalo: se opera y se contrata mejor (§1).
3. **¿El componente queda acotado detrás de una interfaz?** Si el plan es escribir el sistema entero
   en Prolog, la respuesta es no.
4. **¿Hay ≥2 personas capaces de mantenerlo, y una forma de formar a la tercera?** El mercado laboral
   es minúsculo; el conocimiento es enseñable, pero hay que presupuestarlo.

**Criterio de migración de un Prolog existente**: no se traduce a otro lenguaje —una traducción
mecánica de backtracking y unificación produce código ilegible y más lento—. Se **reespecifica**:
extrae las reglas a una forma declarativa (tabla de decisión, modelo MiniZinc, esquema Datalog),
verifícala contra el sistema vivo con casos reales, y sustituye por dominio. Si el sistema funciona
y está acotado, **congelarlo es una opción legítima**; documenta el modo y determinismo de cada
predicado público como parte del congelado.

**Prohibiciones:**
- ❌ **PROHIBIDO el corte rojo**; corte dentro de una disyunción o tras `->`; cortes añadidos para
  "quitar soluciones de más" sin entender de dónde salen (§3).
- ❌ **PROHIBIDO** `call/1`, `=..` o `assert/1` sobre términos que vengan de entrada externa; `read_term`
  sobre datos no confiables sin lista blanca de functores (§5).
- ❌ `assert`/`retract` como estado mutable de la aplicación.
- ❌ Objetivos de búsqueda sin límite de tiempo o de inferencias expuestos a un usuario.
- ❌ Recursión sobre grafos o datos sin `:- table` "porque en las pruebas termina".
- ❌ `is/2` donde el modelo debía ser CLP(FD) y reversible.
- ❌ Predicados públicos sin modo ni determinismo documentados.
- ❌ Programar sin módulos.
- ❌ Elegir Prolog para un problema de restricciones puras **sin haber comparado con MiniZinc, CP-SAT
  o un SMT** y sin dejarlo escrito.
- ❌ Escribir el sistema completo (HTTP, persistencia, operación) en Prolog.
- ❌ Asumir portabilidad ISO entre implementaciones (§2), o asumir la licencia de SWI-Prolog por lo
  que diga una fuente secundaria: **se lee el `LICENSE` en crudo y se ejecuta `?- license.`**.
- ❌ Elegir GNU Prolog o Scryer para producción (§2).
- ❌ Comprometer un proyecto con SICStus sin coste de licencia **y de mantenimiento anual** por
  escrito, sabiendo que dejarlo caducar tiene recargo de reinstauración.
- ❌ Exponer el servidor HTTP de SWI-Prolog directamente a Internet.

## 8. Verificación web obligatoria

1. **SWI-Prolog**: versión estable vigente (a ago-2026, serie **10.0**, descargas **10.0.2**; las
   series con minor impar son de desarrollo) y su changelog; y **la licencia leída en crudo**
   (`LICENSE` = BSD Simplificada) más `?- license.` sobre **tu** build, por las librerías enlazadas.
2. **SICStus**: release vigente (a ago-2026, **4.10.1 del 3-jul-2025**) y, sobre todo, **el precio —
   hueco declarado: RISE no publica tarifas**. Cualquier cifra tiene que salir de una oferta.
   Confirma también el recargo por mantenimiento caducado antes de dejarlo vencer.
3. **Scryer**: si ha salido release posterior a v0.10.0 y si ha alcanzado 1.0; **GNU Prolog**: si hay
   algo posterior a 1.5.0. En ambos casos, mira **commits**, no solo releases (§ regla del catálogo:
   un repo sin releases recientes no implica proyecto muerto, ni al revés).
4. **MiniZinc y OR-Tools**: versión vigente (a ago-2026, **MiniZinc 2.10.0** de jul-2026 y **OR-Tools
   v9.15** de 2026) y qué backends soporta cada uno — es la comparación que decide si Prolog entra.
5. **Tabling e indexación de tu implementación**: qué indexa (primer argumento, multiargumento, JIT),
   qué modos de tabling ofrece (`incremental`, `subsumptive`, *answer subsumption*) y sus límites de
   memoria. Es lo que determina si el modelo escala, y varía por implementación y versión.
6. **`library(sandbox)`**: estado, limitaciones conocidas y avisos, antes de evaluar objetivos de
   usuario.
7. CVEs y avisos de seguridad de la implementación y del stack HTTP/TLS que embebas, y del código
   nativo que traigan los `pack` que instales.
8. **Conformidad ISO** de la implementación concreta y sus desviaciones documentadas, si la
   portabilidad es un requisito real (normalmente no lo es: §2).

Si la web contradice este documento, **manda la web** y señala la discrepancia.
