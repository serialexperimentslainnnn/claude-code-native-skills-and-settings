---
name: compilers-dsl-standards
description: Building a language or a language processor, and deciding first whether you need one at all. Use when designing an internal (embedded) or external DSL, writing a lexer and parser by hand or with a generator (ANTLR .g4 grammars, Tree-sitter grammar.js and node-types.json, lex/flex .l and yacc/bison .y files, PEG parsers with pest .pest / peg.js / Lark, parser combinators like nom, chumsky, megaparsec or FParsec), building an AST and its source spans, name resolution and scoping, a type checker or Hindley-Milner inference, choosing a backend (LLVM IR and llvm-sys/inkwell/llvmlite, Cranelift, WebAssembly as a target, transpiling to another language, or a tree-walking versus bytecode interpreter), deciding whether a JIT is worth it, designing compiler diagnostics with spans, labels and fix-its (ariadne, codespan-reporting, miette), snapshot-testing compiler output, fuzzing a parser, building a conformance suite, or shipping the tooling a language needs to be usable - a Language Server Protocol server, formatter, debugger and syntax highlighting.
---

# Estándares de compiladores y DSL

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **construir un procesador de lenguaje**: un DSL propio, un intérprete, un compilador, un
transpilador, un *linter* con su propio parser, o un formato de entrada con sintaxis suficiente para
necesitar gramática. Cubre la decisión previa (¿hace falta un lenguaje?), el frontend, la
representación intermedia, el sistema de tipos, el backend, la calidad de los diagnósticos, el
testing y el tooling que hace usable un lenguaje.

Triggers: `.g4` de ANTLR, `grammar.js` y `node-types.json` de Tree-sitter, `.l`/`.y` de flex/bison,
`.pest`, `.lark`, `.ebnf`, combinadores (`nom`, `chumsky`, `megaparsec`, `FParsec`, `parsec`),
`llvm-sys`/`inkwell`/`llvmlite`/`libLLVM`, `.ll` y `.bc`, Cranelift `cranelift-codegen`,
`wasm32` como destino de un compilador propio, "AST", "IR", "SSA", "resolución de nombres",
"inferencia de tipos", "tabla de símbolos", "recuperación de errores del parser", "árbol frente a
bytecode", "¿le pongo un JIT?", `textDocument/publishDiagnostics` y demás métodos LSP,
`ariadne`/`codespan-reporting`/`miette`, `insta`/`expect-test`/`lit`/`FileCheck`, "gramática
ambigua", "conflicto shift/reduce", "left recursion".

**Principio rector, y es una prohibición antes que un consejo: el DSL propio es la sobreingeniería
más cara que existe.** No cuesta el parser —el parser es un fin de semana—; cuesta la documentación,
el resaltado, el formateador, el LSP, el depurador, los mensajes de error, la formación de cada
persona nueva y la migración cuando la sintaxis cambie, **durante toda la vida del sistema**. Un
lenguaje sin ese presupuesto comprometido no se empieza. La escalera se sube de abajo arriba y solo
se sube un peldaño cuando el anterior ha fallado **con un caso concreto y demostrado**:

1. **Datos**: JSON/YAML/TOML con esquema (JSON Schema) validado. Cubre el 80 % de lo que la gente
   llama DSL.
2. **Biblioteca / API**: funciones y tipos del lenguaje anfitrión. Cero tooling nuevo, el IDE ya
   funciona, el *type checker* ya existe.
3. **DSL interno (embebido)**: *builder*, operadores, macros o metaprogramación del anfitrión.
   Hereda editor, depurador, tipos y ecosistema. **Es la respuesta correcta casi siempre.**
4. **DSL externo con gramática propia**: solo si el usuario **no es programador**, o si la sintaxis
   ha de ser portable entre varios anfitriones, o si el lenguaje debe ser analizable/verificable de
   una forma que el anfitrión impide (p. ej. terminación garantizada, ejecución en *sandbox*).
5. **Lenguaje de propósito general**: casi nunca, y no en un proyecto de producto.

**Segunda tesis, que ordena §3.5 y §4**: **la calidad de los mensajes de error es una característica
de producto, no un pulido posterior.** Es lo que decide si un lenguaje se adopta o se odia; y es la
razón técnica por la que casi todos los compiladores serios acaban con un parser escrito a mano.

**No aplica**: ver `rust-standards`, `c-standards`, `cpp-standards`, `zig-standards`,
`haskell-fp-standards`, `ocaml-fsharp-standards`, `typescript-standards`, `python-standards`,
`go-standards` (**el lenguaje en el que escribes el compilador es suyo**: build, lint, tests
unitarios, gestión de dependencias, idiomas. Aquí la arquitectura del procesador de lenguaje, no
cómo se escribe el código que lo implementa. OCaml/Haskell/F# aparecen aquí porque sus tipos suma y
*pattern matching* son la herramienta natural para un AST, pero esa recomendación es de §2, no un
reenvío de alcance), `webassembly-standards` (**Wasm como destino y como runtime es suyo**: target
`wasm32-*`, Component Model y WIT, límites del *sandbox*, *fuel*/epoch y presupuesto de tamaño del
módulo. Aquí solo la decisión de **emitir** Wasm desde tu backend y qué pierdes al hacerlo),
`lowcode-governance-standards` (**la plataforma low-code como producto de
terceros y su gobierno** —ciclo de vida, propiedad, catálogo, licencias, *shadow IT*— es suya.
Frontera limpia: **construir un lenguaje es de aquí; gobernar el uso de uno que compraste, de
ella**. Un editor visual de flujos que serializa a JSON es una plataforma, no un DSL de este
documento), `sql-standards` (**SQL ya es el DSL que casi nadie necesita reinventar**; si el problema
es consultar datos, la respuesta suele ser SQL, no una gramática nueva), `api-design-standards`
(**si el usuario es un programa, la respuesta es una API, no una sintaxis**: contrato, versionado y
compatibilidad son suyos), `testing-qa-standards` (estrategia de calidad general; aquí las técnicas
específicas: *snapshot*, *fuzzing* del parser, suites de conformidad), `appsec-standards` (modelado
de amenazas y clases de vulnerabilidad agnósticas; aquí solo los *sinks* propios de ejecutar código
de terceros), `performance-engineering-standards` (metodología de medición y perfilado; aquí solo
qué medir en un compilador y cuándo un JIT no compensa), `opensource-licensing-standards` (la
licencia como restricción legal; aquí solo el dato de que LLVM es **Apache-2.0 WITH
LLVM-exception**), `ai-agents-standards` (un agente que *genera* código en tu DSL; aquí el DSL).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Por defecto | Alternativa justificable | Motivo |
|---|---|---|---|
| ¿DSL? | **No.** Datos con esquema o API del anfitrión | DSL interno | La escalera de §1; el peldaño 4 exige justificación escrita |
| DSL interno vs. externo | **Interno** | Externo si el usuario no programa | El interno hereda IDE, tipos, depurador y ecosistema gratis |
| Parser de producción | **Descenso recursivo a mano** (+ *Pratt* para expresiones) | Generador para prototipar o para un lenguaje ajeno ya especificado | Control total de mensajes y **recuperación de errores**; sin conflictos opacos |
| Generador, si lo usas | **ANTLR 4** (`.g4`, BSD-3-Clause) | bison/flex en C heredado | ALL(*) admite recursión izquierda; ecosistema maduro. **Última release 4.13.2, agosto de 2024** (verificar §8): proyecto estable pero de cadencia muy lenta — dato de riesgo, no descalificador |
| Parser incremental / editor | **Tree-sitter** (MIT, `0.26.x` a jul-2026) | LSP con reparse completo si el fichero es pequeño | Reparse incremental y tolerante a errores; es lo que quiere un editor. **Sigue en `0.x`: la API rompe entre minors** |
| PEG | **Solo con orden de alternativas documentado** | — | El operador `/` **ordenado elimina la ambigüedad sin avisarte**: una regla que nunca se alcanza no da error, da silencio. Ver §7 |
| AST | Tipos suma inmutables + **`Span` en cada nodo** | CST/árbol concreto si hay que reimprimir el original | Sin `Span` no hay diagnóstico ni *fix-it* ni LSP |
| Diagnósticos | Librería de *render* con spans y etiquetas (`ariadne`, `codespan-reporting`, `miette`) | Formato propio `fichero:línea:col:` compatible con editores | Un mensaje sin fragmento de código señalado es un mensaje inútil |
| Ejecución | **Intérprete de bytecode** (VM de pila) | Árbol si el lenguaje es de configuración y corre una vez | El árbol es 5–20× más lento; el bytecode no complica tanto como parece |
| JIT | **No, hasta tener el perfil que lo pida** | Cuando el mismo código se ejecuta millones de veces en un proceso largo | Ver §6.2 |
| Backend nativo | **LLVM** si necesitas código máquina de calidad | **Cranelift** si prima el tiempo de compilación (JIT, Wasm) | LLVM optimiza mejor; Cranelift compila mucho más rápido y es Rust puro |
| Backend "barato" | **Transpilar** a C, Rust, Go o TypeScript | — | Heredas su optimizador, su portabilidad y su depurador. La opción más infravalorada |
| Destino portable | **WebAssembly** | — | Un backend, muchas plataformas, *sandbox* incluido → `webassembly-standards` |
| Tests de salida | **Snapshot** (`insta`, `expect-test`, `lit`+`FileCheck`) | — | Un compilador es una función pura de texto a texto: el snapshot es su test natural |
| Fuzzing del parser | **Obligatorio** (`cargo-fuzz`/libFuzzer/AFL++) | — | El parser es la superficie de ataque; ver §5 |
| Tooling mínimo para publicar | **LSP + formateador + resaltado** | — | Sin los tres, el lenguaje no es usable fuera de su autor |

**Sobre LLVM, y es el dato que rompe proyectos: la IR de LLVM no es un formato estable.** La política
oficial dice, textualmente, que *"The textual format is not backwards compatible. We don't change it
too often, but there are no specific promises."* Del *bitcode* sí hay garantía de lectura hacia atrás
(*"The current LLVM version supports loading any bitcode since version 3.0"*), pero con matices que
importan: *"Newer releases can ignore features from older releases, but they cannot miscompile them"*
y *"Debug metadata is special in that it is currently dropped during upgrades"*. Consecuencias
operativas, no teóricas:

- **Fija la versión mayor de LLVM en el build y trátala como dependencia de plataforma**, no como
  librería intercambiable. Subir de mayor es un proyecto, con su ventana y sus tests.
- **No guardes `.ll` ni `.bc` como artefacto de largo plazo** ni como formato de intercambio entre
  componentes que se actualizan por separado. Ese es el error clásico.
- El *binding* (`inkwell`, `llvmlite`, `llvm-sys`) va **atado a la mayor de LLVM**: el ritmo de
  actualización de tu proyecto lo marca el más lento de los dos.
- LLVM publica dos majors al año y patches frecuentes (a jun-2026, **22.1.8**; verificar §8).
  Licencia **Apache-2.0 WITH LLVM-exception**.

## 3. Estructura y convenciones

### 3.1 Fases, y la regla de que cada una produce un dato

```
texto → [léxico] → tokens (+span) → [sintaxis] → CST/AST (+span)
      → [resolución de nombres] → AST resuelto → [tipos] → AST tipado
      → [lowering] → IR → [optimización] → IR → [backend] → salida
```

- **Cada fase es una función pura de una estructura a otra.** Nada de mutar el AST en sitio desde
  cinco fases distintas: destruye la trazabilidad y hace imposible el test por fase.
- **Cada nodo lleva su `Span`** (offset inicial, offset final, id de fichero). El `Span` sobrevive a
  todas las fases; si se pierde en el *lowering*, el error de tipos no puede señalar código.
- **`SourceMap` centralizado**: los offsets son bytes, la conversión a línea/columna se hace una vez
  al renderizar. Cuidado con UTF-8: la columna que espera un editor suele ser **UTF-16** (el LSP usa
  UTF-16 por defecto); esto se decide y se documenta una vez, no por función.
- **Errores como datos, no como excepciones**: el compilador acumula diagnósticos y sigue. Abortar al
  primer error es la peor experiencia posible y hace inviable el LSP.

### 3.2 Parser: por qué a mano

El generador es más rápido de escribir y peor de usar. Un parser generado produce *"syntax error at
line 42"*; uno a mano produce *"falta `)` — el paréntesis que abre está en la línea 39"*. Lo que
inclina la balanza no es el rendimiento, es esto:

- **Recuperación de errores**: el LSP necesita un árbol razonable de un fichero que el usuario está
  escribiendo y por definición es inválido. Recuperación por puntos de sincronización (`;`, `}`,
  inicio de declaración) y **nodos `Error` en el árbol**, no excepción.
- **Mensajes con contexto**: solo tú sabes qué esperaba el parser y por qué.
- **Precedencia de expresiones**: *Pratt parsing* / *precedence climbing*, tabla explícita de
  precedencia y asociatividad. Es la parte que el descenso recursivo puro hace mal.
- Si usas generador: **prototipa con él y cambia a mano cuando la gramática se estabilice**. Migrar
  con la gramática ya escrita como especificación es barato; empezar a mano sin saber la gramática,
  no.

### 3.3 Resolución de nombres y tipos

- **Resolución de nombres es una fase propia**, separada del parser y del *type checker*. Ámbitos
  explícitos, no una tabla global mutable.
- **Inferencia**: Hindley-Milner (Algorithm W / nivel-based generalization) si el lenguaje es
  funcional y quieres inferencia completa; comprobación bidireccional si hay subtipado, genéricos o
  sobrecarga. **Elegir uno, y saber cuál**, porque mezclarlos a ojo produce un sistema de tipos
  imposible de explicar y de dar mensajes.
- **Corolario práctico y poco intuitivo: la inferencia global empeora los mensajes de error.** El
  error aparece lejos de su causa. Exigir anotaciones en los límites (funciones públicas, campos) es
  una decisión de usabilidad, no una limitación técnica.

### 3.4 Backend: elegir el más barato que cumpla

Por coste creciente: **intérprete de árbol → bytecode → transpilar → Wasm → Cranelift → LLVM →
generación de código propia**. Nunca se sube un escalón sin un número que lo justifique. Transpilar a
un lenguaje con buen ecosistema es la vía más infravalorada: heredas optimizador, plataformas,
depurador y perfilador; el precio es que **los mensajes de error del lenguaje destino se filtran al
usuario** —y eso hay que taparlo activamente con *source maps* o con una capa de traducción.

### 3.5 Diagnósticos, como especificación

Un diagnóstico completo tiene: **código estable** (`E0308`, `TS2345`) documentado y buscable;
**severidad**; **span primario** con el fragmento renderizado; **spans secundarios etiquetados**
("aquí se declaró como `Int`"); **nota** que explica la regla; y, cuando exista una corrección
mecánica, **`fix-it` estructurado** (rango + texto de reemplazo) que el LSP pueda aplicar. El código
de error es contrato: **una vez publicado no se reutiliza para otra cosa**.

## 4. Calidad y testing

Gates en orden de coste creciente; los tres primeros rompen el build.

1. **Tests unitarios por fase**: lexer, parser, resolución, tipos. Cada uno con su entrada mínima.
2. **Snapshot de la salida**, y de los **errores**: para cada programa de prueba se congela el AST
   serializado, el IR y **el texto exacto del diagnóstico**. Que el mensaje de error esté bajo
   control de versiones es lo que impide que se degrade sin que nadie lo note. `insta`,
   `expect-test`, o `lit` + `FileCheck` al estilo LLVM.
3. **Suite de programas inválidos, tan grande como la de válidos.** Un compilador se juzga por lo que
   rechaza y por cómo lo explica. Cada error definido tiene al menos un caso.
4. **Fuzzing del parser** (libFuzzer/AFL++, con corpus semilla de la suite): objetivo **cero
   *panics*, cero desbordamiento de pila, cero bucles infinitos** ante cualquier entrada. Un parser
   recursivo desborda la pila con paréntesis anidados: **límite de profundidad explícito**, no
   confianza.
5. ***Round-trip* / propiedades**: `parse(print(parse(x))) == parse(x)` para el formateador;
   generación aleatoria de ASTs válidos y comprobación de que imprimen y vuelven a parsear.
6. **Diferencial**, si reimplementas algo existente: compara contra la implementación de referencia
   sobre un corpus real.
7. **Conformidad**: si el lenguaje tiene especificación (propia o ajena), la suite de conformidad es
   un artefacto versionado aparte, y el porcentaje de conformidad se publica. **Sin suite, la
   "especificación" es la implementación**, y entonces no hay especificación.
8. **Regresión de rendimiento**: tiempo de compilación de un corpus fijo, medido en CI con umbral. Un
   compilador que se vuelve lento pierde usuarios exactamente igual que uno que da errores malos.

## 5. Seguridad del stack

- **Ejecutar el lenguaje de otro es ejecutar código de otro.** Si el DSL lo escriben usuarios,
  clientes o un LLM, el intérprete es una frontera de confianza: **límite de instrucciones, límite de
  memoria, límite de tiempo de pared, límite de profundidad de recursión y de anidamiento de datos**,
  todos obligatorios y todos configurables. Sin ellos, un bucle de tres líneas es una denegación de
  servicio.
- **Decide y documenta si el DSL es Turing-completo.** Si no necesita serlo, **no lo hagas**: un
  lenguaje total (sin bucles no acotados) se puede analizar, acotar y ejecutar sin miedo. Es la
  ventaja real de un DSL frente a "que escriban Python".
- **Superficie del *host*: la lista de funciones nativas expuestas es la superficie de ataque
  completa.** Nada de exponer el sistema de ficheros, la red o `exec` "por comodidad". Lista blanca
  explícita, revisada como se revisa una API pública.
- **Denegación de servicio en el parser**: retroceso exponencial en PEG y en expresiones regulares
  (ReDoS), profundidad de anidamiento, entradas de tamaño ilimitado. Todo con límite y con test.
- **Nada de `eval` del anfitrión** para implementar el DSL. Un "DSL" que compila a `eval()` de
  Python/JS **no es un DSL: es inyección de código con sintaxis bonita**.
- **La caché de compilación es un vector de cadena de suministro**: si guardas artefactos compilados
  (bytecode, `.bc`, objetos) o descargas gramáticas/plugins de terceros, van con verificación de
  integridad. Un fichero de gramática de Tree-sitter compila a C nativo que se carga en tu proceso.
- **Los mensajes de error no filtran rutas absolutas ni entorno** cuando el compilador corre como
  servicio. Este error es tan clásico como aburrido.

## 6. Rendimiento y operabilidad

### 6.1 Qué medir

Tiempo por fase (léxico, sintaxis, tipos, backend) sobre un corpus fijo; **el reparto casi nunca es
el que crees** —en compiladores maduros el backend y la resolución dominan, no el parser—. En un LSP,
lo que importa es la **latencia percibida**: *completion* y *hover* por debajo de ~100 ms, y
diagnósticos por debajo de ~500 ms desde la última tecla. Eso se consigue con parseo incremental y
consulta perezosa (arquitectura *query-based* con memoización), no optimizando el lexer.

### 6.2 Cuándo un JIT no compensa

Un JIT solo gana cuando el **tiempo de ejecución acumulado del código caliente supera con holgura el
coste de compilarlo**, y ese coste incluye lo que casi nadie cuenta: complejidad de depuración,
imposibilidad de W^X en plataformas que lo prohíben (iOS, consolas, muchos entornos con
`seccomp`/SELinux estrictos), superficie de ataque de páginas ejecutables escribibles, y el trabajo
de mantenerlo por arquitectura. **No compensa** en: procesos cortos, código que se ejecuta una vez
(configuración, plantillas, reglas), cargas dominadas por E/S, y cualquier sitio donde la
portabilidad importe más que el pico. **Antes de un JIT**: bytecode compacto, *inline caching*,
*superinstructions*, y —lo primero de todo— comprobar que el intérprete no está perdiendo el tiempo
en asignaciones de memoria.

### 6.3 Tooling sin el cual el lenguaje no existe

- **LSP** (spec 3.18 en desarrollo a ago-2026; 3.17 es la última publicada como estable — verificar
  §8). Mínimo viable: diagnósticos, *hover*, ir a definición, autocompletado, símbolos del documento.
- **Formateador canónico y sin opciones.** La lección de `gofmt`: cero configuración elimina el
  debate para siempre. Se entrega **desde la primera versión**, porque un formateador retroactivo
  reescribe todo el código existente de golpe.
- **Resaltado**: gramática Tree-sitter (editores modernos) y/o TextMate `.tmLanguage.json` (VS Code,
  y sigue siendo el mínimo común denominador).
- **Depuración**: si el lenguaje se transpila o compila, o emites información de depuración real
  (DWARF, *source maps*) o asumes que **nadie podrá depurar**. Decisión consciente, documentada.
- **Versionado del lenguaje**: SemVer sobre la **sintaxis y la semántica**, no sobre el binario. Un
  cambio que hace inválido un programa antes válido es *breaking*, siempre.

## 7. Sostenibilidad a largo plazo

**Un DSL sin dueño es deuda que no se puede refactorizar.** Un lenguaje no tiene *find usages* fiable
fuera de su propio tooling, así que el código escrito en él se vuelve intocable en cuanto la persona
que lo diseñó se va. Requisitos de existencia, no recomendaciones: **dueño nombrado**,
**especificación escrita** (aunque sea un documento corto), **suite de conformidad**, **política de
compatibilidad** y **plan de migración automatizada** (`fix`/*codemod*) para cada cambio de sintaxis.
Si alguno falta, el DSL no se aprueba.

- ❌ **PROHIBIDO** crear un DSL externo sin haber agotado —y documentado por qué fallan— los peldaños
  1 a 3 de la escalera de §1.
- ❌ **PROHIBIDO** implementar el DSL sobre `eval()`/`exec()` del lenguaje anfitrión.
- ❌ **PROHIBIDO** ejecutar código de usuario sin límites de tiempo, memoria, instrucciones y
  profundidad.
- ❌ **PROHIBIDO** exponer al DSL funciones nativas de ficheros, red o proceso sin lista blanca
  revisada.
- ❌ **PROHIBIDO** un AST sin `Span`. Un nodo sin posición es un diagnóstico que no se puede dar.
- ❌ **PROHIBIDO** abortar la compilación en el primer error de sintaxis o de tipos.
- ❌ **PROHIBIDO** tratar la IR de LLVM como formato estable de intercambio o de almacenamiento
  (§2), y prohibido dejar la versión mayor de LLVM sin fijar en el build.
- ❌ **PROHIBIDO** publicar un lenguaje sin formateador ni resaltado. "Ya vendrá" significa nunca.
- ❌ **PROHIBIDO** cambiar el texto de un diagnóstico sin que un snapshot lo registre.
- ❌ **PROHIBIDO** reutilizar un código de error retirado para otro significado.
- ❌ **PROHIBIDO** una gramática PEG con alternativas cuyo orden no esté documentado: una regla
  inalcanzable **no da error, da silencio** (§2).
- ❌ **PROHIBIDO** parser recursivo sin límite de profundidad ni test de *fuzzing* que lo verifique.
- ❌ **PROHIBIDO** "lo optimizamos con un JIT" sin perfil previo (§6.2).
- ❌ **PROHIBIDO** romper la sintaxis sin *codemod* y sin periodo de aviso con ambas formas válidas.
- ❌ **PROHIBIDO** dejar la "especificación" como sinónimo de "lo que hace la implementación actual".

## 8. Verificación web obligatoria

Antes de fijar cualquier cosa en un proyecto real, comprobar por web:

- **LLVM**: última versión mayor y de parche, calendario de releases, y **releer la sección *IR
  Backwards Compatibility* de `llvm.org/docs/DeveloperPolicy.html`** — es la fuente, no este resumen.
  Compatibilidad del *binding* que uses (`inkwell`, `llvmlite`, `llvm-sys`) con esa mayor.
- **ANTLR**: última release y actividad del proyecto (a ago-2026 la última publicada era **4.13.2, de
  agosto de 2024**; si sigue igual, pésalo como riesgo de mantenimiento). Licencia **BSD-3-Clause**,
  leída en `LICENSE.txt` del repositorio.
- **Tree-sitter**: versión (sigue en `0.x`, con rupturas entre *minors*), estado de la API de
  *bindings* y licencia **MIT** leída en `LICENSE`.
- **Cranelift / Wasmtime**: versión, arquitecturas soportadas y estado de producción.
- **LSP**: si 3.18 ya está publicada como final o sigue "under development"; cambios en la
  negociación de `positionEncoding` (UTF-8 vs. UTF-16).
- **Licencias en crudo** (`LICENSE`, `COPYING`, `LICENSE.txt`, ojo con `master` frente a `main`) de
  toda librería de parsing, *codegen* o *runtime* que enlaces —especialmente si enlazas LLVM: es
  **Apache-2.0 WITH LLVM-exception** y la excepción importa.
- **CVEs** del *runtime* que embebas (LLVM, motores de expresiones regulares, cargadores de
  gramáticas nativas).
- Estado del *target* Wasm si compilas a él: WASI 0.2/0.3, Component Model, y qué runtime lo soporta
  hoy.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
