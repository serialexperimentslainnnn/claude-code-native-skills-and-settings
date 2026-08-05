---
name: crystal-standards
description: Crystal engineering standards (staff-level). Trigger on .cr files, shard.yml, shard.lock, shards install/update/build/--frozen, crystal build/run/spec, crystal tool format, ameba.yml, spec/*_spec.cr, Fiber::ExecutionContext and spawn, -Dpreview_mt or --threads build flags, nilable unions and .not_nil!, macro/{% %} metaprogramming, or the Lucky, Amber and Kemal web frameworks.
---

# Estándares Crystal

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a ficheros `.cr`, `shard.yml`, `shard.lock`, invocaciones `crystal build`/`run`/`spec`/`tool format`, `shards`, `ameba.yml`, specs en `spec/`, contextos de ejecución y fibras, macros, y a los frameworks web Lucky/Amber/Kemal. Fija criterio: qué se gana, qué cuesta y cuándo la respuesta correcta es **no usar Crystal**.

**No aplica**: ver `zig-standards` (el nicho compilado de **control manual y explícito, sin runtime ni GC**), `nim-standards` (nicho compilado con **GC configurable y metaprogramación en AST**: si la palanca que se busca es elegir el modelo de memoria o escribir macros pesadas, es Nim) — la frontera entre los tres **no es el rendimiento, es el modelo de memoria y el propósito**: aquí, **GC no configurable y ergonomía tipo Ruby con tipado estático**; `ruby-standards` (**la frontera crítica, marcada — Ola 5, en curso**: **la compatibilidad con Ruby es de sintaxis, no de semántica ni de librerías**. No corre gemas, no hay `method_missing` ni `define_method` en runtime, no hay monkey patching dinámico, no hay `eval`, y el sistema de tipos cambia el diseño. Portar Ruby a Crystal es reescribir, no migrar); `rust-standards` (**la comparación obligada y el default del catálogo para código de sistemas nuevo**: Crystal se justifica frente a Rust **solo** por productividad de escritura sobre un equipo que ya piensa en Ruby; Rust gana en garantías del compilador, madurez del ecosistema, estabilidad y contratación); `go-standards` (la otra vía a binarios distribuibles sin dependencias, con ecosistema y contratación mucho mayores: para un servicio de red nuevo con equipo que no viene de Ruby, suele ser la respuesta); `c-standards` y `cpp-standards` (el lado C de los *bindings* `lib`/`fun`, hardening del binario y el toolchain nativo); `api-design-standards` (el contrato HTTP; aquí solo su implementación), `sql-standards`, `cicd-standards`, `kubernetes-standards`, `appsec-standards`, `vulnerability-management-standards`, `secrets-management-standards`, `observability-standards`.

## 2. Toolchain por defecto

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Valor verificado a ago-2026 | Motivo |
|---|---|---|
| Compilador estable | **1.21.0** (2026-07-16) | Última publicada en crystal-lang.org. Cadencia ~trimestral; sin LTS declarada |
| Licencia | **Apache License, Version 2.0** — «Apache License / Version 2.0, January 2004 / http://www.apache.org/licenses/» (`LICENSE`, verbatim) | Permisiva con cláusula de patentes |
| Gestor de dependencias | **shards** (`shard.yml` + `shard.lock`) | Único; ver §3 |
| Formato | **`crystal tool format --check`** como gate de CI | Oficial, integrado, sin configuración: cero debate de estilo |
| Lint | **ameba** — **evaluar antes de fijarlo como gate**: última estable v1.6.4 (nov-2024), con v1.7.0-**dev** (jun-2026) como única etiqueta posterior. Señal de mantenimiento irregular | Complemento, no sustituto del formatter |
| Tests | **`crystal spec`** (framework `spec` integrado) | No hace falta dependencia externa |
| Plataformas | **Tier 1**: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux-gnu`, `x86_64-linux-musl` | Ver §6: Windows es **Tier 3** |

**Pin del compilador** en `shard.yml` (`crystal: "~> 1.21"`) **y** en la imagen de CI/desarrollo. Sin pin, un bump menor del compilador puede romper el build por cambios de inferencia.

## 3. La promesa y su coste

**Lo que da**: sintaxis casi idéntica a Ruby, **tipado estático con inferencia global** (apenas hay anotaciones), compilación a binario nativo vía LLVM, y rendimiento de orden nativo. Un equipo Ruby escribe Crystal casi sin curva de sintaxis.

**Lo que cuesta — y es la decisión de arquitectura, no un detalle**: la inferencia global obliga a analizar **el programa entero en cada compilación**. La semántica se rehace desde cero cada vez, incluida la stdlib y todas las *shards*; **no hay compilación incremental**. Consecuencia directa: **el tiempo de compilación crece con el tamaño del proyecto y no se amortiza con caché**, y la herramienta de lenguaje (LSP) sufre lo mismo. Es un problema estructural conocido y discutido desde 2015, no un bug pendiente.

**Criterio de descarte, explícito**:
- Si el flujo de trabajo del equipo depende de un ciclo editar→ver de segundos (desarrollo web iterativo, TDD de grano fino), **Crystal se descarta o se acota a componentes pequeños**. Medir el *build limpio* de un proyecto representativo antes de comprometerse, no al empezar con 500 líneas.
- Si el proyecto va a superar decenas de miles de líneas con equipo grande, se mide la curva de compilación **antes** de que sea irreversible y se define un umbral de abandono.
- Mitigaciones reales, no soluciones: dividir en varios binarios/shards con superficie de API estrecha, y correr los specs por fichero en desarrollo (`crystal spec spec/foo_spec.cr`) reservando la suite completa para CI.

## 4. Sistema de tipos, estructura y testing

### Nil como tipo — la ganancia real sobre Ruby
`Nil` es un tipo y participa en las uniones (`String | Nil`, o `String?`). Al invocar un método sobre una unión, **el compilador exige que el método exista y tipe para cada miembro**; como `Nil` no responde, **el `NoMethodError` en runtime de Ruby se convierte en error de compilación**. Es el argumento técnico central a favor de Crystal frente a Ruby.

- Se aprovecha con *flow typing*: `if x` estrecha el tipo dentro de la rama; `x || default`; `x.try { ... }`.
- **`.not_nil!` es un ANTIPATRÓN**: no comprueba nada, **afirma** — convierte un error visible en compilación en un `NilAssertionError` en runtime, exactamente lo que se venía a evitar. Prohibido en código nuevo salvo invariante demostrada en comentario; si se usa, **siempre con mensaje** (`not_nil!("...")`) para que la traza sea diagnosticable. Regla de revisión: cada `.not_nil!` es una pregunta al autor.
- Cuidado con `try`: si el valor es nil el bloque **se salta en silencio** — traga errores de lógica igual de bien que gestiona nil. Usar `if`/`case` cuando el caso nil requiere una acción.
- Anotar tipos en la **API pública** (argumentos y retorno de métodos públicos, variables de instancia) aunque la inferencia no lo exija: documenta el contrato, mejora los mensajes de error y acota el trabajo del compilador.

### Macros
Metaprogramación en **tiempo de compilación** (`macro`, `{% %}`, `{{ }}`), no en runtime: no hay `define_method` dinámico ni monkey patching en caliente. Sirven para lo que en Ruby se hacía con metaprogramación (DSLs, serializadores, código repetitivo).
**Criterio**: la macro más simple que resuelve el problema; nunca una macro donde basta un genérico o un método normal. Toda macro lleva tests del código generado y dueño nombrado. Coste directo: tiempo de compilación (que ya es el cuello de botella) y errores de compilación ilegibles.

### Estructura y dependencias (`shards`)
- `src/`, `spec/`, `shard.yml` y `shard.lock`. **Aplicación: `shard.lock` commiteado. Librería: `shard.lock` en `.gitignore`** (`crystal init` ya lo hace así).
- Dependencias git: se resuelven por **etiquetas semver con prefijo `v`** (`v1.2.3`). **Prohibido `branch:`/`commit:` flotante en producción**: `shards install` con una dependencia por rama puede arrastrar cambios no fijados. Se pin por versión, o por commit inmutable si no hay releases.
- CI y despliegue: **`shards install --frozen`** (falla si falta `shard.lock` o si está desincronizado), con `--without-development`. `--production` solo no basta: `--frozen` es el flag estricto.
- Sin registro central con auditoría ni base de advisories: no hay `cargo deny` equivalente. Cada dependencia es una decisión de confianza y de bus factor; minimizar el número y revisar cada bump a mano.

### Testing y gates
- `crystal spec` (`describe`/`it`/`should`), specs en `spec/*_spec.cr`. Cubrir camino feliz, **bordes y errores** — en particular cada rama nil y cada excepción declarada.
- Correr la suite **también con `--release`**: el compilador optimiza distinto y los tiempos y el comportamiento de concurrencia cambian.
- Gate de CI, coste creciente: `crystal tool format --check` → `shards install --frozen` → `crystal spec` → `ameba` (si se adopta, ver §2) → `crystal build --release` de los targets soportados.
- Presupuesto de compilación como métrica de CI: si el build limpio supera el umbral acordado, es un defecto a triar, no ruido.

## 5. Seguridad del stack

- **Dependencias por Git en `shard.yml`** es el vector principal: sin registro firmado, sin advisories, sin proceso de abandono. Obligatorio `shard.lock` commiteado en aplicaciones + `--frozen` en CI, `branch:` prohibido, y revisión del diff en cada actualización. Vendorizar o cachear las dependencias si el proyecto es crítico.
- La stdlib **ha tenido vulnerabilidades explotables por red**: en abr-2026 el equipo recibió un reporte de *HTTP request smuggling* en `HTTP::Server`, con post mortem publicado en may-2026. Lectura operativa: el servidor HTTP integrado **no** tiene la superficie de revisión de nginx o de un stack maduro — **poner un proxy inverso endurecido delante** y seguir de cerca los avisos del proyecto.
- Entrada no confiable: validar en el borde y aprovechar el sistema de tipos (constructores que devuelven el tipo estrecho, no `String` crudo). SQL solo parametrizado; prohibido interpolar en la query — la interpolación de Crystal invita al error tanto como la de Ruby.
- Secretos nunca en `shard.yml`, en el código ni en el binario; env vars o gestor.
- Binario: compilación estática contra musl (`x86_64-linux-musl` es Tier 1) → imagen `scratch`/distroless, non-root, FS read-only. Es una de las mejores bazas operativas de Crystal.

## 6. Concurrencia, plataformas y operabilidad

### Contextos de ejecución y multihilo — verificar por versión, ha cambiado
Estado verificado en **1.21.0**: los *execution contexts* (RFC 0002) están **habilitados por defecto**, sustituyendo el antiguo `-Dpreview_mt`. Del anuncio, verbatim: «Execution contexts from RFC 0002 are enabled by default. The default context has parallelism 1, i.e. it is single-threaded.» y «fibers are no longer pinned to one thread. Even with parallelism 1, fibers may switch threads.»

Consecuencias que hay que asumir en código existente (roturas declaradas en el propio anuncio, verbatim):
- «Fibers in parallel execution contexts can resume in a different thread.»
- «Fibers in concurrent execution contexts can switch threads on a blocking syscall.»
- «Execution contexts don't support `spawn(same_thread:)`» — en contextos paralelos **levanta en runtime**.

Criterio: **el paralelismo no es automático**; se opta explícitamente (dimensionando el contexto por defecto en código, o vía la opción de hilos en el build). **Cualquier código que asumiera que una fibra permanece en el mismo hilo está roto** — variables *thread-local*, punteros a estado de hilo y bindings C con estado por hilo se auditan uno a uno antes de subir a 1.21. El estado de la parte multihilo lleva años en movimiento (financiado por 84codes desde ~2023): **verificar contra la versión concreta, nunca contra un tutorial**.

### Plataformas
Tiers oficiales, verbatim: **Tier 1** «guaranteed to work»; **Tier 2** «expected to work»; **Tier 3** «partially works. The Crystal codebase has support for these platforms, but there are some major limitations».
- **Tier 1**: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux-gnu`, `x86_64-linux-musl`.
- **Tier 2**: `aarch64-linux-gnu`, `aarch64-linux-musl`, `arm-linux-gnueabihf`, `i386-linux-*`, `x86_64-freebsd`, `x86_64-openbsd`.
- **Windows es Tier 3** (`x86_64-windows-msvc`, `x86_64-windows-gnu`, `aarch64-windows-msvc`, `aarch64-windows-gnu`), pese al trabajo continuado en él (soporte de OpenSSL 4.x en MSVC en 1.21). **Criterio: no comprometer un despliegue de producción en Windows**; para desarrollo en Windows, WSL2 sobre un target Tier 1. También `aarch64-linux-*` es Tier 2: verificar antes de asumir ARM en servidor.

### Ecosistema web — datos de actividad, no de reputación
- **Kemal** (micro-framework, estilo Sinatra): cadencia sostenida y reciente (v1.12.0, jul-2026). Opción por defecto para un servicio HTTP pequeño.
- **Lucky** (full-stack, tipado extremo): activo pero con releases muy espaciadas (v1.5.0 abr-2026; v1.4.0 jun-2025; v1.3.0 nov-2024).
- **Amber** (full-stack estilo Rails): **estuvo casi tres años sin release** (v1.4.1 ago-2023) y ha vuelto en ago-2026 con v1.5.0 «Crystal 1.21 support» y una serie 2.0.0-beta. Adoptar solo tras verificar que la reactivación se sostiene — un repo que revive no es lo mismo que un repo mantenido.
- En los tres casos, la superficie de integraciones (auth, colas, pasarelas de pago, SDK de cloud) es **una fracción** de la de Rails/Django/Spring: contar el coste de escribir esos bindings.

### Operabilidad
- Observabilidad: no dar por hecho un SDK de OpenTelemetry equiparable al de lenguajes mayoritarios — **verificar el estado real antes de diseñar la instrumentación**; si no lo hay, exportar métricas propias y trazas por el borde HTTP.
- Timeouts explícitos en todo cliente; apagado ordenado que cierre el servidor y drene fibras antes de salir.
- El GC es un Boehm-Demers-Weiser conservador y **no es configurable como en Nim**: no hay palanca de latencia. Si el requisito es latencia acotada, Crystal no es el lenguaje.

## 7. Sostenibilidad y prohibiciones

**Cadencia y compatibilidad.** Post-1.0 (2021) la línea 1.x mantiene compatibilidad razonable, pero cada minor trae roturas acotadas y anunciadas (1.21: contextos de ejecución por defecto, fin del *fallback* automático a PCRE legacy). **No hay LTS**: se sigue la última estable, leyendo el changelog de cada minor. Subir de versión implica recompilar todo el árbol y re-testear la concurrencia.

**Salud del proyecto, con cifras.** Crystal vive de dos patrocinadores: **84codes (22.000 €/mes desde abr-2018, ~941.000 € acumulados)** y **Manas.Tech (5.000 $/mes desde 2009, ~1.430.000 $ acumulados)**, más Open Collective y soporte comercial (Crystal Compass). Cambio de liderazgo reciente: Beta Ziliani dejó la posición de *lead* en sep-2025 y la tomó Johannes Müller. Lectura honesta: **proyecto vivo, financiado y con equipo, pero con una concentración de financiación de dos empresas y una comunidad pequeña**. Va en la decisión de adopción.

**PROHIBIDO** (excepción con justificación escrita):
- ❌ `.not_nil!` como forma habitual de tratar nilables; `.not_nil!` sin mensaje; `try` donde el caso nil requiere una acción.
- ❌ Dependencias con `branch:` o sin fijar en producción; `shards install` sin `--frozen` en CI; `shard.lock` sin commitear en una aplicación.
- ❌ Comprometer despliegue de producción sobre un target **Tier 3** (Windows) o asumir Tier 2 (ARM Linux) sin haberlo probado en CI.
- ❌ Subir a 1.21+ sin auditar el código que asumía fibras ancladas a un hilo (`spawn(same_thread:)`, estado *thread-local*, bindings C con estado por hilo).
- ❌ Exponer el `HTTP::Server` de la stdlib directamente a Internet sin proxy inverso endurecido delante.
- ❌ Macros para lo que resuelve un método o un genérico; macro sin tests del código generado.
- ❌ Adoptar Crystal **sin haber medido el tiempo de compilación limpio de un proyecto representativo**, ni haber fijado el umbral que dispara la revisión de la decisión.
- ❌ Prometer "portamos la app Ruby a Crystal": no hay gemas, no hay metaprogramación en runtime, no hay `eval`. **Es una reescritura.**
- ❌ **Elegir Crystal cuando**: el equipo no viene de Ruby (la única ventaja diferencial se evapora); hay que contratar en el mercado abierto; se necesita ecosistema maduro y auditado; el requisito es latencia acotada o Windows en producción; o el proyecto crecerá mucho y el ciclo de compilación es crítico. En esos casos: **quedarse en Ruby** (si el cuello de botella no es la CPU — casi nunca lo es en una app web, y Ruby aporta ecosistema, contratación y velocidad de iteración incomparables), **irse a Go** (servicios de red, binarios distribuibles, contratación) o **a Rust** (garantías del compilador, sistemas). Crystal es defendible para: un equipo Ruby con un componente concreto limitado por CPU, CLIs y demonios de tamaño medio donde el binario nativo y el arranque instantáneo importan, y servicios pequeños con superficie de dependencias controlada.

## 8. Verificación web obligatoria

1. **Estable vigente y changelog**: https://crystal-lang.org/ y el blog de la release (`crystal-lang.org/<año>/<mes>/<día>/<v>-released/`); feed https://github.com/crystal-lang/crystal/releases.atom (no `api.github.com`: 403 sin autenticar).
2. **Estado del multihilo** en la versión concreta: anuncio de la release + RFC 0002 y el post «Releasing Execution Contexts». Es el área que más ha cambiado; **nunca fiarse de tutoriales ni de menciones a `-Dpreview_mt`**.
3. **Tiers de plataforma**: https://crystal-lang.org/reference/syntax_and_semantics/platform_support.html — comprobar el tier del target de despliegue **antes** de diseñar, especialmente Windows y ARM.
4. **Avisos de seguridad** del proyecto (blog y security advisories del repo) antes de exponer el `HTTP::Server` de la stdlib.
5. **Salud de cada shard** que se vaya a usar: cadencia real de releases (feed Atom del repo), número de mantenedores, licencia en el `LICENSE` en crudo. Aplicar en particular a Lucky/Amber/Kemal y a `ameba`.
6. **Flags de `shards`** (`--frozen`, `--production`, `--without-development`) en la versión usada: `crystal-lang.org/reference/<v>/man/shards/`.

**Huecos no verificados a ago-2026**: la sintaxis exacta para elevar el paralelismo del contexto por defecto (opción de build vs. llamada en código) **no verificada** contra la documentación oficial de 1.21 — solo contra hilos de foro, que ofrecían dos formas distintas; el estado del soporte de **OpenTelemetry** en el ecosistema Crystal **no verificado**; si existe una **política de LTS** o de soporte de versiones antiguas **no verificado** (no se encontró declaración); el detalle y la severidad asignada al *HTTP request smuggling* de abr-2026 **no verificados** más allá de la existencia del reporte y del post mortem.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
