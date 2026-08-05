---
name: lisp-standards
description: The Lisp family except Clojure - Common Lisp and Scheme. Use when working with .lisp, .lsp, .cl, .asd, .scm, .ss, .sls, .sld, .rkt or .el files, ASDF defsystem forms, Quicklisp (ql:quickload, quicklisp.lisp, dists, qlfile/qlfile.lock with Qlot, ocicl and ocicl.csv), SBCL, Clozure CL, ECL, ABCL, CLASP, CLISP, CMUCL, LispWorks or Allegro CL images, save-lisp-and-die and dumped Lisp images, SLIME or Sly and swank/slynk REPL sessions, defmacro and macroexpand-1, CLOS defclass/defgeneric/defmethod and the MOP, the condition system (handler-bind, handler-case, restart-case, invoke-restart, signal, cerror), declaim/declare optimize speed safety, fiveam/parachute/rove test systems, Racket raco and #lang, Guile, Chez Scheme, Gambit, Chicken, R7RS libraries and SRFIs, or Emacs Lisp init.el and package.el.
---

# Estándares de la familia Lisp (Common Lisp y Scheme)

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Common Lisp está vivo, pero en nichos concretos y con un ecosistema pequeño.** No es una
tecnología muerta ni un ejercicio de nostalgia: hay implementaciones con releases mensuales (SBCL
publicó 2.6.7 el 28-jul-2026), hay proveedores comerciales cobrando por soporte y hay sistemas en
producción. Lo que **no** hay es masa crítica: la superficie de librerías, la profundidad del
tooling y el mercado laboral son órdenes de magnitud menores que los de cualquier lenguaje
mayoritario, y eso es un riesgo de proyecto, no una opinión estética.

**Elígelo con criterio, no por gusto.** Donde gana de verdad: sistemas de larga vida donde el
dominio se modela mejor como lenguaje propio (macros, DSL, compiladores, motores de reglas y de
planificación, CAD/CAM, sistemas simbólicos), exploración interactiva sobre estado vivo (el REPL
sobre una imagen conectada es una ventaja real, no una preferencia), y equipos que ya lo dominan.
Donde no gana: CRUD, glue de infraestructura, y todo lo que vaya a rotar entre muchas manos.
**Antes de la primera línea:** ¿hay ≥3 personas capaces de operarlo y modificarlo? Si no, ver §7.

Cubre: Common Lisp ANSI y sus implementaciones (libres y comerciales, con su coste); ASDF y la
distribución de librerías (**Quicklisp y su modelo de integridad, que es el dato de seguridad del
ecosistema** — §5); imagen, `save-lisp-and-die` y por qué eso rompe el CI moderno; el REPL como
método; **sistema de condiciones y reinicios** frente a excepciones; macros y cuándo **no** escribir
una; CLOS y el MOP. También Scheme (R7RS, Racket, Guile, Chez) y Emacs Lisp como caso aparte.

**No aplica**: ver `clojure-standards` (**Clojure y ClojureScript son un Lisp y tienen skill propia:
cédelos enteros** — `deps.edn`, `project.clj`, `.clj`/`.cljs`/`.cljc`/`.edn`, la JVM, `clj-kondo`,
el REPL nREPL, la inmutabilidad por defecto y su modelo de estado. **La frontera no es "es un
Lisp"**: Clojure no tiene sistema de condiciones, ni CLOS, ni imagen, ni `read-eval` sobre datos
mutables, y su gestión de dependencias es la de Maven; aquí no se extrapola nada de allí),
`haskell-fp-standards` y `ocaml-fsharp-standards` (**lo funcional tipado**: la frontera es el
sistema de tipos estático y la evaluación, no el paradigma), `scala-standards`, `julia-standards`
(**otro lenguaje homoicónico con macros y REPL-driven, orientado a cómputo numérico**: si el
problema es numérico, es suyo), `elixir-erlang-standards` (macros y el `defmacro` de Elixir viven
allí), `python-standards`/`go-standards`/`typescript-standards` (la alternativa real cuando §7 dice
que no toca Lisp), `developer-workstation-standards` (**la configuración de Emacs como editor es
suya**; aquí solo Emacs Lisp *como lenguaje*), `refactoring-tech-debt-standards` y
`enterprise-architecture-standards` (estrategia de modernización y cartera),
`legacy-modernization-standards` (**skill paraguas** de un sistema heredado en Lisp: qué "R" se
elige, si se congela, se reescribe o se retira, y la arqueología previa) y
`migration-projects-standards` (**la ejecución del corte** una vez decidido: ensayo, ventana,
cuadre del dato, rollback y apagado del origen), `opensource-licensing-standards` (el análisis de licencias; aquí solo qué licencia tiene cada
implementación y qué implica, §2), `cicd-standards` (la pipeline; aquí el problema específico de
construir desde una imagen), `appsec-standards` y `vulnerability-management-standards` (metodología
y triaje; aquí los sinks concretos y el modelo de integridad de Quicklisp), `webassembly-standards`
(si el destino es Wasm), `solidity-standards`, `mumps-standards` e `ibm-i-rpg-standards` (**no son
comparables**: aquellos son plataformas legacy sin elección; Common Lisp sigue siendo una elección
posible y hay que defenderla).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Elección | Nota verificada (ago-2026) |
|---|---|---|
| Implementación CL por defecto | **SBCL** | **2.6.7, 28-jul-2026**; cadencia ~mensual. Compilador nativo, el mejor rendimiento y el mejor soporte de la comunidad. Es el default salvo motivo escrito |
| Licencia de SBCL | **Dominio público + BSD/MIT parciales** — leída en crudo del `COPYING` | *"SBCL is derived from CMU CL, which was released into the public domain"*; los cambios posteriores van a dominio público *"or under the FreeBSD licence where not"*, con MIT en LOOP/PCL/CityHash. **No es "MIT" ni "GPL": no lo supongas** |
| CL sobre JVM | **ABCL**, solo si el requisito es interop Java | **Licencia verificada en crudo (`COPYING`): GPL v2 con una excepción tipo Classpath (13.º término)** — no es MIT ni BSD; afecta a cómo distribuyes. **Hueco: no pude verificar su versión vigente** (§8) |
| CL embebido / C++ | **ECL** (embebible, compila a C) o **CLASP** (sobre LLVM, interop C++) | ECL: tag **26.5.5** (5-may-2026) en **GitLab**, no en GitHub. CLASP: **v3.0.1** (jun-2026). Ambos activos |
| CCL (Clozure) | **Solo mantenimiento**: no para proyectos nuevos | Última release **1.13 (2024)**; sin releases en 2025-2026. No está muerto, pero su cadencia no sostiene una elección nueva |
| Implementación comercial | **LispWorks** o **Allegro CL**, solo con requisito que las justifique (GUI multiplataforma, entrega móvil, soporte contractual, deliverables cerrados) | **LispWorks publica precios**: 8.1 Professional **1.500 USD (32-bit) / 3.000 USD (64-bit)**, Enterprise **4.500 USD**, por usuario, sin royalties de runtime. **Allegro CL no publica tarifas: es solo por presupuesto** ("contact … for a customized price quote"). El coste de licencia es el dato caro, no la sintaxis |
| Definición de sistema | **ASDF** (`.asd`), sin alternativa | Última estable **3.3.7 (ene-2024)**. Vive en `gitlab.common-lisp.net`; **el repo `fare/asdf` de GitHub está congelado desde 2018 y no es la fuente de verdad** |
| Distribución de librerías | **Quicklisp** como base + **Qlot** (`qlfile.lock`) o **ocicl** (`ocicl.csv`) para fijar versiones | **Obligatorio un lockfile versionado.** `ql:quickload` a pelo no es reproducible |
| Alternativa moderna | **ocicl**: artefactos OCI, HTTPS, firmas sigstore, instalación local por proyecto | Licencia **MIT**, leída en crudo del `LICENSE`. Es la opción con mejor historia de cadena de suministro (§5) |
| Dist rolling | **Ultralisp: prohibido en producción** | Rolling sin curación: amplía la superficie de suministro sin contrapartida operativa |
| Editor / REPL | **SLIME (swank)** o **Sly (slynk)** sobre Emacs; alternativas para VS Code/Vim | El REPL conectado a la imagen es el método de trabajo, con la disciplina de §3 |
| Tests | **FiveAM** o **Parachute** | Ejecutables desde CLI en un proceso limpio, no solo desde el REPL (§4) |
| Scheme: aplicación | **Racket** | **v9.2 (26-may-2026)**. Es el Scheme con ecosistema, docs y tooling propios (`raco`, `#lang`); si dudas entre Schemes, este |
| Scheme: embebido / extensión | **Guile** (GNU, LGPL — verificar) | Última serie estable verificada **3.0.11**. Elección obligada si extiendes software GNU |
| Scheme: rendimiento | **Chez Scheme** | **10.4.1 (may-2026)**, en `cisco/ChezScheme`. Es además el backend de Racket CS |
| Estándar Scheme | **R7RS-small** como objetivo de portabilidad | **R7RS-large NO está cerrado**: avanza por *color dockets* (Red 2016, Tangerine 2019) y **no existe un evento de ratificación único**. Su desarrollo se movió a **Codeberg**. **No escribas "conforme a R7RS-large" en ningún documento** |
| Emacs Lisp | **Caso aparte**: lenguaje de extensión de un editor, no de aplicación | No se escribe una aplicación en Elisp. La config del editor es de `developer-workstation-standards` |

## 3. Estructura y convenciones

- **Un sistema ASDF por unidad desplegable**, con `:depends-on` explícito y **sin dependencias
  circulares entre sistemas**. Los tests van en un sistema aparte (`foo/tests`), nunca colgando del
  sistema principal: si no, el binario de producción arrastra el framework de test.
- **Paquetes (`defpackage`) explícitos, con `:export` como contrato.** Nada de `:use` de paquetes
  ajenos que no sean `:cl` — importar símbolos a granel provoca colisiones que solo aparecen al
  actualizar una dependencia. `uiop` se referencia con prefijo.
- **Macros: la última herramienta, no la primera.** Escribe una macro **solo** cuando necesites
  controlar la evaluación (nuevo *binding*, orden de evaluación, sintaxis nueva). Si una función,
  una función de orden superior o un `&rest` lo resuelven, **es una función**. Toda macro: captura
  de variables evitada con `gensym`, evaluación única de cada argumento, y `macroexpand-1` en el
  test. Una macro exportada es una API que no se puede cambiar sin recompilar a los consumidores.
- **Condiciones y reinicios, no excepciones.** Es la ventaja técnica más infravalorada del lenguaje:
  `handler-bind` corre el manejador **antes de desenrollar la pila**, así que un `restart-case`
  puede reparar y continuar. Criterio: las librerías **señalan** condiciones y **ofrecen reinicios**
  con nombre; **la aplicación decide** con `handler-case`/`invoke-restart`. Define tus condiciones
  como subclases de `error`/`warning` propias; **nunca señalizar `simple-error` con un string**.
- **CLOS**: métodos genéricos y `defmethod` sobre clases propias; herencia múltiple con moderación.
  **El MOP es potente y casi siempre innecesario**: tocarlo hace tu código dependiente de detalles
  de implementación y hostil a quien venga detrás. Justificación escrita para cada uso.
- **`declaim`/`declare optimize`**: por defecto **`(safety 1)` o superior**. `(safety 0)` desactiva
  comprobaciones de tipo y convierte un error en corrupción de memoria; se usa en un bloque acotado
  y medido, jamás global.
- **El estado vivo del REPL no es el programa.** Todo lo que funciona en tu imagen debe funcionar
  tras cargar el sistema desde cero en un proceso nuevo. Redefinir en caliente es la herramienta;
  **el fichero es la verdad**.

## 4. Calidad, tests y CI (el problema de la imagen)

- **La imagen es el problema estructural con CI.** `save-lisp-and-die` produce un artefacto que
  contiene todo el estado acumulado en la sesión — incluidas definiciones que ya no están en ningún
  fichero y, si te descuidas, **secretos leídos durante el build**. Reglas: la imagen se construye
  **en un proceso limpio, desde fuente, con script no interactivo**, en un solo paso reproducible; y
  **cero secretos en el entorno del build** (quedan dentro del binario).
- **Gate de CI mínimo, en orden de coste**: (1) el sistema **carga desde cero** en imagen limpia
  sin *warnings* de compilación — un `STYLE-WARNING` de función indefinida es casi siempre un typo
  que en Lisp no falla hasta la llamada; (2) la suite (FiveAM/Parachute) pasa **ejecutada desde CLI**
  con código de salida distinto de cero al fallar; (3) el lockfile (`qlfile.lock`/`ocicl.csv`) está
  commiteado y no ha derivado; (4) la imagen se construye y arranca.
- **Tests**: comportamiento observable, con cobertura explícita de **condiciones señaladas y
  reinicios ofrecidos** — es la parte del contrato que más se rompe en silencio. Property-based con
  `cl-quickcheck`/`check-it` donde el dominio lo permita.
- **Sin sistema de tipos que te cubra**: la validación en los bordes es manual y obligatoria.
  Declaraciones de tipo en interfaces públicas (SBCL las comprueba y las usa para optimizar).

*§6 se omite deliberadamente*: la observabilidad, los timeouts y la capacidad de un servicio Lisp
no tienen criterio propio del lenguaje — se rigen por `observability-standards` y por la skill de la
plataforma. Lo único específico (imagen, GC, `save-lisp-and-die`) está en §4 y §5.

## 5. Seguridad del stack

- **El dato de seguridad del ecosistema: Quicklisp distribuye sobre HTTP en claro, y su integridad
  por librería es MD5 y SHA-1.** Verificado leyendo el cliente y los metadatos en crudo: el dist
  vigente es `version: 2026-01-01`, y `distinfo.txt`, `releases.txt`, `systems.txt` y los tarballs
  se sirven desde `http://beta.quicklisp.org/` sin TLS; `releases.txt` lista `file-md5` y
  `content-sha1` por release. **Lo único firmado con OpenPGP es el fichero de arranque
  `quicklisp.lisp`** (huella publicada en quicklisp.org/beta), no las librerías. Consecuencias:
  - **Ni MD5 ni SHA-1 resisten colisiones**, y el índice que los contiene llega por un canal sin
    autenticar: **no hay verificación de integridad utilizable frente a un atacante en la red**.
  - **No hay firma del autor de cada librería**: la curación del dist comprueba que **compila
    junto**, no que sea seguro. No es una auditoría.
  - **Criterio**: verificar la firma PGP del bootstrap; **lockfile obligatorio**; instalar en un
    entorno de build sin acceso de escritura a producción; y, para cadena de suministro seria,
    **`ocicl`** (HTTPS + artefactos OCI direccionados por digest + sigstore) o vendorizar y revisar
    las dependencias críticas. **Adicionalmente: forzar HTTPS/proxy de confianza a nivel de red.**
- **`read` es un sink**: el *reader* de Common Lisp evalúa con `#.` si `*read-eval*` está activo, e
  interna símbolos sin límite. **Nunca `read` sobre entrada no confiable**: `*read-eval*` a `nil`,
  `with-standard-io-syntax`, y preferir un parser explícito (JSON/EDN/lo que sea) a leer S-expresiones
  ajenas. Un `read` sobre datos de usuario es ejecución remota de código.
- **`eval`, `compile` y `intern` en tiempo de ejecución sobre datos externos: prohibidos.** Interning
  sin cota es además una fuga de memoria explotable.
- **La imagen guardada contiene todo lo que había en memoria**: variables con credenciales, tokens de
  build, historial. Trátala como artefacto sensible; genérala sin secretos y escanéala.
- **`safety 0` es un fallo de seguridad**, no una optimización: elimina las comprobaciones que
  convierten un bug en error controlado en vez de en corrupción de memoria.
- **Swank/slynk es una consola remota con ejecución arbitraria**: **jamás escuchando en producción**
  ni en una interfaz que no sea `127.0.0.1`, y solo sobre túnel SSH.

## 7. Sostenibilidad, migración y prohibiciones

**Criterio de adopción (decidir *antes*, no después):**
1. **Bus factor ≥3** con gente que pueda operar y modificar. Si el sistema lo sostiene una persona,
   estás construyendo un pasivo, por bueno que sea el código.
2. **La ventaja tiene que ser del lenguaje**: macros/DSL, exploración interactiva sobre estado vivo,
   modelado simbólico. Si el argumento es "es más elegante", no es argumento.
3. **Presupuesto de formación y de tooling propio**: parte del tooling que das por hecho no existe y
   lo vas a escribir tú.
4. Si (1)-(3) no se cumplen: **otro lenguaje**. Es la respuesta correcta la mayoría de las veces, y
   decirlo aquí es más barato que descubrirlo en el año tres.

**Salida de un sistema CL existente** — se aplica solo si hay un motivo real (relevo imposible,
dependencia comercial insostenible), no por moda: **encapsular y congelar** antes que reescribir.
Extrae el núcleo de valor detrás de una interfaz estable (proceso separado, HTTP/gRPC), construye lo
nuevo fuera contra esa interfaz (*strangler fig*, ver `refactoring-tech-debt-standards`) y **no
traduzcas macros automáticamente a nada**: no hay destino equivalente, y el resultado hereda la
estructura sin conservar la semántica.

**Prohibiciones:**
- ❌ **PROHIBIDO** `ql:quickload` sin lockfile commiteado (`qlfile.lock` / `ocicl.csv`): el build no
  es reproducible y la dependencia flota.
- ❌ **PROHIBIDO** `read`/`eval`/`compile`/`intern` sobre entrada no confiable; `*read-eval*` activo
  al leer datos ajenos.
- ❌ Swank/slynk expuesto fuera de `localhost`; REPL remoto contra producción como método de
  operación ("me conecto y lo arreglo en caliente" no es un procedimiento: no deja traza ni rollback).
- ❌ Construir la imagen desde una sesión interactiva, o desplegar una imagen que no salga de un
  build limpio desde fuente. Una imagen no es reproducible por definición si el proceso no lo es.
- ❌ Secretos presentes en el entorno del build de la imagen.
- ❌ `(safety 0)` global, o `(speed 3)` sin haber medido.
- ❌ Escribir una macro donde basta una función; macros exportadas sin test de `macroexpand-1`.
- ❌ Usar el MOP sin justificación escrita.
- ❌ Ultralisp u otro dist rolling en producción.
- ❌ Declarar conformidad con **R7RS-large**: no está cerrado (§2).
- ❌ Asumir la licencia de una implementación: **SBCL no es MIT, ABCL no es BSD** — se lee el
  `COPYING` en crudo (§2).
- ❌ Comprometer un proyecto con LispWorks o Allegro CL sin el coste de licencia **y de renovación**
  por escrito, y sin plan si el proveedor cambia condiciones.
- ❌ Elegir CCL para un proyecto nuevo (§2).
- ❌ Escribir una aplicación en Emacs Lisp.

## 8. Verificación web obligatoria

1. **SBCL**: última release en `sbcl.org/news.html` (a ago-2026, **2.6.7 del 28-jul-2026**) y estado
   de tu plataforma en la *platform table* — no todas tienen binario reciente.
2. **ECL y CLASP**: ECL publica sus tags **en GitLab** (26.5.5, may-2026), CLASP en GitHub (v3.0.1,
   jun-2026). **CCL**: confirmar si ha habido release posterior a 1.13 (2024) antes de descartarlo.
3. **ABCL — hueco declarado**: `abcl.org` no respondió en la verificación y **el repositorio de
   GitHub no publica ni tags ni releases** (es un puente hacia su SVN), así que **no pude fijar su
   versión vigente**. No la inventes: consúltala en `abcl.org/release-notes.shtml` o en el SVN del
   proyecto. Su licencia **sí** está verificada (GPLv2 + excepción).
4. **ASDF**: última estable (a ago-2026, **3.3.7 de ene-2024**) en `asdf.common-lisp.dev` y en
   `gitlab.common-lisp.net`. **El mirror `fare/asdf` de GitHub está congelado en 2018: no es fuente.**
5. **Quicklisp**: fecha del dist vigente (a ago-2026, **2026-01-01** — siete meses sin actualizar;
   comprobar si la cadencia se ha reanudado, porque **un dist estancado es un riesgo de seguridad de
   dependencias**), la huella de la clave de firma del bootstrap, y si el transporte sigue siendo
   HTTP en claro. **ocicl**: versión y estado de su verificación sigstore.
6. **LispWorks**: precios y ediciones vigentes en `lispworks.com/buy/` (a ago-2026, 8.1: Professional
   1.500/3.000 USD, Enterprise 4.500 USD) — **confírmalos en la página antes de presupuestar**.
   **Allegro CL: hueco estructural — Franz no publica tarifas**; cualquier cifra tiene que venir de
   una oferta contractual.
7. **Racket** (v9.2, may-2026), **Guile** (serie 3.0.x, verificada 3.0.11) y **Chez** (10.4.1,
   may-2026): versión vigente y su licencia leída en crudo (**Guile es LGPL: verifícalo, condiciona
   la distribución**).
8. **R7RS-large**: estado de los *color dockets* en el repositorio de **Codeberg** y actas de WG2
   antes de asumir que algo es "estándar".
9. CVEs y avisos de las librerías de red/TLS del ecosistema (`cl+ssl`, servidores HTTP), que es donde
   está la superficie real de ataque, y de la propia implementación.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
