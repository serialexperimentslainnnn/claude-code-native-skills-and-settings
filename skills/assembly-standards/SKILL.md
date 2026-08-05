---
name: assembly-standards
description: Engineering standards for when and how to write assembly. Trigger on .s/.S/.asm files, GCC/Clang extended inline asm ("asm volatile" with input/output/clobber constraint lists) and asm goto, MSVC __asm and ml64/MASM, NASM or GAS invocations, AT&T versus Intel syntax, x86-64 System V or Microsoft x64 calling conventions, AArch64 AAPCS64, RISC-V ABI, callee-saved registers, stack alignment and red zone, compiler intrinsics as an alternative (immintrin.h, arm_neon.h), .note.GNU-stack markings, endbr64/CET/IBT, BTI and PAC branch protection, constant-time cryptographic routines and dudect/TIMECOP/ctgrind verification, Spectre mitigations such as lfence or retpoline, or objdump/perf/godbolt review of generated code.
---

# Estándares de ensamblador

Criterios verificados a **ago-2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

Aplica a **cuándo se escribe ensamblador, cómo se justifica y cómo se mantiene**: ficheros `.s`/`.S`/`.asm`, `asm` extendido de GCC/Clang y `asm goto`, MASM/`ml64`, intrínsecos como alternativa, ABIs y convenciones de llamada, marcado ELF del objeto producido, y la disciplina de tests, *benchmarks* y revisión que hace que ese código siga siendo correcto dentro de tres años. **No enseña juegos de instrucciones**: fija criterio de ingeniería.

**La pregunta previa es si escribirlo, y casi siempre la respuesta es no.** El orden obligatorio es: **medir** (perfilar y localizar el cuello de botella real) → **cambiar el algoritmo o el patrón de acceso a memoria** → **intrínsecos del compilador** → **ensamblador**, y solo con un número medido que respalde el salto. Un compilador de 2026 gana casi siempre en código general; donde no gana es en lo que el lenguaje no puede expresar (tiempo constante garantizado, instrucciones sin intrínseco, arranque sin runtime, ABI a mano). Escribir ensamblador convierte una función en **código con dueño, fecha de revisión y coste de mantenimiento permanente**: se acepta ese coste conscientemente o no se escribe.

**No aplica**: ver `c-standards` y `cpp-standards` (**el `asm` en línea dentro de una función C/C++ es frontera compartida**: la corrección del bloque `asm`, sus restricciones de entrada/salida/clobber y la elección de escribirlo son de aquí; el resto de la función —tipos, UB, gestión de recursos, flags de compilación y hardening del binario— es de ellas), `rust-standards` (`core::arch`, `std::arch::asm!`, `#[target_feature]` y el `unsafe` que lo envuelve), `zig-standards` (su sintaxis `asm` y su toolchain), `gpu-computing-standards` (PTX/SASS, kernels y el toolchain de GPU: no es esta skill), `cryptography-pki-standards` (**frontera crítica: la elección de algoritmo, el tamaño de clave, el modo de operación y la gestión del ciclo de vida de las claves son suyos** — aquí solo la implementación de tiempo constante y el borrado de secretos en memoria; y la regla dura: **PROHIBIDO implementar criptografía propia**, se usa una biblioteca auditada, y este documento existe para *revisar* la que ya se usa o para el caso raro y justificado en que haya que tocar una primitiva), `linux-hardening-standards` (hardening del **sistema**; el del **binario** es de `c`/`cpp`), `offensive-security-standards` (explotación: shellcode, gadgets, evasión — **no está aquí y no lo estará**, §7), `incident-response-forensics-standards` (análisis de un binario ajeno para responder a un incidente), `observability-standards` (`perf` y el perfilado continuo en producción; aquí `perf` solo como herramienta puntual de decisión), `objective-c-standards` (un `.mm` puede contener `asm`: el criterio de ensamblador es de aquí), `cicd-standards`, `appsec-standards`, `vulnerability-management-standards` y `secrets-management-standards`.

## 2. Decisiones por defecto

> **Verificar la última versión por web antes de fijarla en un proyecto real** (§8). Lo siguiente es el estado verificado a **ago-2026**.

### Casos legítimos y casos ilegítimos

| Legítimo | Ilegítimo |
|---|---|
| Rutina criptográfica que exige **tiempo constante** verificable (el compilador puede introducir ramas o accesos dependientes del secreto y no hay forma de prohibírselo en C) | "Es más rápido que C" **sin perfil ni benchmark** |
| *Hot loop* con **medida previa** que demuestra que el compilador no genera lo que se necesita, y con instrucciones sin intrínseco disponible | Optimizar código que no aparece en el perfil |
| Arranque, cambio de contexto, manejadores de excepción, trampolines: **antes de que exista runtime o pila utilizable** | Sustituir a un intrínseco que hace lo mismo |
| Embebido sin libc y acceso a registros de hardware o instrucciones privilegiadas | Ejercicio de estilo, herencia de un ingeniero que ya no está |
| *Shims* de ABI (adaptar convenciones de llamada, *thunks*, FFI de bajo nivel) | Código copiado de internet cuya licencia y corrección nadie verificó |
| Instrucciones sin exposición en el lenguaje (criptográficas, atómicas exóticas, temporizadores) | Cualquier cosa que no tenga dueño asignado |

### Formas de usarlo, en orden estricto de preferencia

1. **Intrínsecos del compilador** (`<immintrin.h>`, `<arm_neon.h>`, `__builtin_*`). El compilador sigue asignando registros, planificando y respetando la ABI; el código se depura, se inline-a y se porta. Es la opción por defecto para SIMD y para instrucciones concretas. Con *runtime dispatch* (`__builtin_cpu_supports`, *function multiversioning*) para no producir un binario que muera con SIGILL en otra máquina.
2. **`asm` extendido de GCC/Clang** solo para secuencias muy cortas y muy locales. Reglas duras: lista completa de **operandos de salida, de entrada y de clobber** (incluido `"cc"` y `"memory"` cuando corresponda), `volatile` cuando el bloque tiene efectos que el compilador no ve, `%%` para registros en la sintaxis de plantilla, y **nunca** asumir que el compilador conserva un registro que no está declarado. Un clobber omitido es un bug que aparece meses después al cambiar de nivel de optimización. `asm goto` para saltar a etiquetas C (y `asm goto` con salidas, disponible en GCC/Clang recientes — **verificar la versión mínima**, §8) es preferible a devolver un flag y ramificar después.
   - **`asm` básico (sin operandos) está vetado** fuera de funciones: no declara nada al compilador y su comportamiento en un cuerpo de función no es el que la gente supone.
   - **MSVC**: verificado — **no soporta `__asm` en x64** (ni en ARM64); `__declspec(naked)` tampoco está disponible en x64. Sus dos vías documentadas son **intrínsecos** y **fichero `.asm` separado ensamblado con `ml64`**. Aviso concreto: con `ml64`, escribir prólogo/epílogo explícitos con directivas de *unwind* (`PROC FRAME`, `.ALLOCSTACK`, `.SAVEREG`, `.ENDPROLOG`); el generado automáticamente ha producido `.xdata` incorrecto y epílogos con `leave`, que es ilegal en x64 y rompe el desenrollado de pila.
3. **Ficheros `.s`/`.S` separados — la opción preferida para cualquier cosa no trivial.** Se lee, se prueba, se versiona, se anota y se sustituye sin tocar el resto del código. `.S` (mayúscula) pasa por el preprocesador de C: es lo que se usa para compartir constantes con las cabeceras. Toda rutina de más de unas pocas instrucciones va aquí, no en línea.

### Ensambladores

| Herramienta | Estado verificado a ago-2026 | Criterio |
|---|---|---|
| **GAS** (GNU as, binutils) | **binutils 2.47**, anunciada el **26-jul-2026**; 2.46 en feb-2026. Activa. Nota: **gold ya no se distribuye por defecto** en 2.47 (tarball aparte) | **Default en Unix**: es el ensamblador del toolchain, integra con el build y con `.S` preprocesado. Sintaxis AT&T por defecto en x86; `.intel_syntax noprefix` si se prefiere Intel |
| **Clang integrated assembler** | Parte de LLVM, activo | Default cuando el proyecto ya es Clang; acepta la mayoría de la sintaxis de GAS pero **no toda**: probar en CI con el ensamblador real del proyecto, no asumir equivalencia |
| **NASM** | **3.02 (2026-06-29)**, verificado por feed Atom. **Activo**. Licencia verificada en el `LICENSE` en crudo: **BSD-2-Clause** (*"NASM is now licensed under the 2-clause BSD license, also known as the simplified BSD license"*) | Elección razonable para ficheros independientes con sintaxis Intel, especialmente multiplataforma o en proyectos que no quieren depender de binutils |
| **YASM** | Última release **1.3.0 (2019-07-25)**, verificado por feed Atom. **Sin releases en ~7 años** | **No adoptar en proyecto nuevo.** Si un proyecto lo usa, migrar a NASM (sintaxis muy próxima) o a GAS. *(Comprobación pendiente: el sitio oficial `yasm.tortall.net` **no resolvió por DNS** en la verificación — dato adicional a favor de tratarlo como dormido, pero declarado como hueco en §8)* |
| **MASM / ml64** | Parte de Visual Studio | Obligado en Windows/MSVC si hace falta ensamblador (ver arriba) |

### ABIs: el dato que de verdad hay que respetar

La ABI no es un detalle de portabilidad, es la **corrección** del código. Una rutina que no salva un registro preservado por el llamado corrompe al llamante de forma silenciosa y no determinista.

- **x86-64 System V** (Linux, macOS, BSD) frente a **Microsoft x64**: son incompatibles en todo lo que importa. Difieren en los registros de argumentos, en qué registros son *callee-saved*, en el espacio reservado en pila para los argumentos, y en la existencia de **red zone** (System V la define; Microsoft x64 **no**). El código de kernel y los manejadores de señal/interrupción **no pueden usar la red zone** aunque la ABI la permita (`-mno-red-zone`).
- **AArch64 AAPCS64**: registros de argumentos y de retorno, registros preservados por el llamado, y **alineación de la pila a 16 bytes en toda frontera pública** — violar la alineación produce fallos en instrucciones SIMD y en llamadas a libc que aparecen lejos del origen.
- **RISC-V**: la ABI depende de la variante (`lp64`/`lp64d`/`ilp32`...); mezclar variantes en el mismo enlace es un fallo de enlazado o, peor, corrupción silenciosa de argumentos en coma flotante.
- **Reglas transversales**: paso y retorno de estructuras (por valor en registros, por memoria oculta, o por puntero, según tamaño y contenido) es **la fuente número uno de errores** al escribir un *shim* a mano; se consulta el documento de la ABI, no se deduce del desensamblado de un caso. La alineación de la pila **en el punto de la llamada** se respeta siempre. El estado de la unidad SIMD/FPU (p. ej. `vzeroupper` tras código AVX antes de volver a código SSE) es parte del contrato.
- **Verificar contra el documento de la ABI vigente** (§8), no contra la memoria ni contra un blog: las ABIs se enmiendan.

## 3. Estructura y convenciones

- Todo el ensamblador vive en un directorio propio (`src/asm/<arch>/`), un fichero por rutina o por familia de rutinas, con el nombre de la arquitectura y la ABI en el nombre o en la ruta. Nunca esparcido por el árbol.
- **Cada rutina tiene una implementación de referencia en C** en el mismo repositorio, seleccionable en build (`USE_ASM=0`). Sin ella no hay test diferencial, no hay portabilidad y no hay salida cuando la versión en ensamblador se rompe.
- Símbolos con prefijo de proyecto y visibilidad restringida (`.hidden`/`.local` salvo lo que sea API). Tipo y tamaño declarados (`.type foo, @function` / `.size foo, .-foo`): sin ellos el *unwinding*, el perfilado y el desensamblado quedan ciegos.
- **Información de desenrollado obligatoria** en toda rutina que pueda aparecer en una pila: directivas CFI (`.cfi_startproc`/`.cfi_def_cfa_offset`/`.cfi_endproc`) en GAS, o las de *unwind* de MASM en Windows. Sin CFI, un *core dump* o un `perf` que atraviese la rutina no produce traza utilizable, y el manejo de excepciones de C++ se rompe.
- **Sintaxis**: una sola por proyecto, declarada. AT&T (destino a la derecha, `%` en registros, `$` en inmediatos) es la de GAS por defecto en x86; Intel (destino a la izquierda) es la de NASM/MASM. Mezclarlas en un mismo árbol es el modo más rápido de introducir un bug de operandos invertidos.
- **Comentario obligatorio por bloque explicando el *porqué***, no el qué. `add %rax, %rbx  // suma` es ruido; lo que hace falta es qué invariante se mantiene, qué registro contiene qué en ese punto, por qué esta secuencia y no la obvia, y qué microarquitectura motivó la decisión. La cabecera de cada fichero declara: **ABI de destino, extensiones de ISA requeridas, contrato de entrada/salida y registros modificados, dueño, y fecha de revisión**.
- Constantes y desplazamientos de estructura **no se escriben a mano**: se generan desde las cabeceras C (mecanismo tipo `asm-offsets`) o se comparten vía `.S` preprocesado. Un desplazamiento hardcodeado sobrevive al cambio de la struct y corrompe memoria en silencio.

## 4. Corrección: tests, benchmarks y CI

- **Test diferencial contra la implementación de referencia en C** para toda rutina: mismos vectores de entrada, salidas idénticas bit a bit. Se incluyen bordes (longitud 0, 1, tamaño de bloque ± 1, desalineados, solapamiento si la API lo permite, valores extremos) y entradas aleatorias con semilla registrada (*property-based*).
- Vectores de prueba oficiales (KAT) cuando el estándar los publique, además del diferencial. Un test que solo compara contra uno mismo no prueba nada.
- **Benchmark que justifique su existencia**, con número antes/después frente a la referencia en C compilada con los flags de release, en la microarquitectura declarada, con repeticiones y dispersión. **Si el benchmark deja de mostrar ventaja, la rutina se borra** — esa es su condición de permanencia, y se re-ejecuta en cada revisión.
- CI: ensamblar y enlazar en **todas** las arquitecturas/ABIs soportadas (emulación con QEMU es aceptable para corrección; no para benchmarks); ejecutar el diferencial bajo el binario normal y, cuando el resto del programa está instrumentado, comprobar que la rutina no rompe los sanitizers del llamante. **ASan/MSan no ven dentro del ensamblador**: la memoria que toca a mano no está instrumentada, así que el test diferencial y la revisión humana son la única red.
- Revisión: **dos revisores**, uno de ellos con la arquitectura concreta como competencia declarada. `godbolt`/Compiler Explorer es herramienta legítima de revisión (comparar lo que genera el compilador con lo escrito a mano y demostrar la diferencia), no de producción.
- Toda corrección de bug deja test de regresión con el vector que lo reproduce.

## 5. Seguridad y corrección de bajo nivel

### Tiempo constante (criptografía)
- **PROHIBIDO implementar criptografía propia.** Se usa una biblioteca auditada (§1). Este apartado rige para revisar la que ya se usa o para el caso justificado de tocar una primitiva existente.
- El requisito es que **ni el flujo de control ni las direcciones de memoria accedidas dependan del secreto**: nada de ramas condicionadas por material secreto, nada de índices de tabla derivados del secreto (una tabla-S indexada por clave es una fuga por caché), nada de división ni de instrucciones con latencia dependiente de los operandos. Los patrones correctos son selección sin ramas (máscaras, `cmov` con la advertencia de que **su tiempo constante no está arquitectónicamente garantizado**) y comparación acumulativa por OR.
- **Verificación, no confianza**: herramientas verificadas a ago-2026 —
  - **TIMECOP** (parte de SUPERCOP): marca los secretos como memoria no inicializada con las peticiones cliente `VALGRIND_MAKE_MEM_UNDEFINED`/`..._DEFINED` y deja que Memcheck señale las ramas y los índices que dependen de ellos. Es la presentación moderna de la idea de **ctgrind** y **no requiere parchear Valgrind**: el parche original de ctgrind está sin mantener y ya no hace falta con Valgrind actual. Usado con Valgrind 3.23.0 en estudios recientes de candidatos NIST PQ.
  - **MemorySanitizer** de Clang como alternativa al enfoque Valgrind, instrumentando en compilación (no cubre lo que está escrito en ensamblador puro).
  - **dudect**: estadístico y de caja negra (t-test de Welch sobre tiempos medidos). Detecta que algo depende del secreto, **no dónde**: es complemento, no sustituto.
  - **ct-verif** y familia: análisis formal; catálogo comparado en `crocs-muni.github.io/ct-tools`. Verificar estado y aplicabilidad antes de fijarlo como gate (§8).
  - **Límite conocido de todas las dinámicas**: no ven la variabilidad de tiempo de una instrucción concreta según sus operandos (fuga microarquitectural) ni el código que no se ejecuta en la prueba. La cobertura importa.
- **Borrado de secretos**: el compilador elimina un `memset` sobre memoria que ya no se lee. Se usa `explicit_bzero`/`memset_explicit`/`SecureZeroMemory` o una barrera de compilador (`asm volatile("" ::: "memory")`). Y se recuerda lo que el borrado **no** cubre: copias en registros, en pila (spills), en el *shadow stack* de un swap a disco, en un *core dump* (`prctl(PR_SET_DUMPABLE, 0)`) o en la memoria de la máquina virtual del lenguaje.

### Canal lateral especulativo
- Spectre y familia se mitigan con **retpoline** o con las mitigaciones de hardware (IBRS/eIBRS, IBPB), y con barreras de especulación (`lfence` en x86, `csdb`/`sb` en AArch64) tras una comprobación de límites que proteja un secreto.
- **Esto cambia con cada microarquitectura y con cada CVE nuevo.** Un conjunto de mitigaciones escrito a mano hoy es incorrecto o innecesariamente caro mañana. Criterio: **dejar la mitigación al compilador y al kernel** (`-mindirect-branch=thunk`, `-mretpoline`, parámetros de arranque) siempre que sea posible; escribirla a mano solo en código sin compilador de por medio, con la variante y la CPU documentadas y **fecha de revisión obligatoria**.
- Consultar el estado de la mitigación en el sistema real (`/sys/devices/system/cpu/vulnerabilities/`) antes de afirmar que algo está mitigado.

### Marcado del objeto producido
- **`.note.GNU-stack` es obligatorio en todo fichero de ensamblador en ELF.** Los compiladores lo emiten solos; **el ensamblador no**, y su ausencia hace que el enlazador asuma **pila ejecutable** para todo el binario. Desde binutils 2.39 el enlazador avisa: `missing .note.GNU-stack section implies executable stack`, con nota de que el comportamiento está deprecado y se retirará. Formas correctas: la sección al final del fichero (`.section .note.GNU-stack,"",%progbits` — `@progbits` en x86, `%progbits` en ARM/AArch64), o ensamblar con `-Wa,--noexecstack`. **PROHIBIDO** silenciarlo con `--no-warn-execstack` o enlazar con pila ejecutable "para que compile": eso desactiva NX en todo el proceso.
- **CET / IBT (x86-64)**: cada destino de salto o llamada indirecta debe empezar por `endbr64` y el objeto debe declarar `GNU_PROPERTY_X86_FEATURE_1_IBT`/`SHSTK` en `.note.gnu.property`. Estado verificado a ago-2026: hardware, kernel (IBT de kernel desde 5.18, *shadow stack* de espacio de usuario desde 6.4) y toolchain están listos; **Fedora y Ubuntu ya compilan con `-fcf-protection` por defecto**, y Fedora tiene un *Change* en curso para activar el *shadow stack* por defecto en el enlazador dinámico, con IBT diferido a una versión posterior. glibc 2.39 añadió `--enable-cet` pero **upstream lo deja inactivo por defecto** (activable por `GLIBC_TUNABLES=glibc.cpu.hwcaps=SHSTK`).
- **BTI / PAC (AArch64)**: `-mbranch-protection=standard` equivale a `bti+pac-ret`; el objeto declara `GNU_PROPERTY_AARCH64_FEATURE_1_BTI`. **Un solo objeto sin la marca desactiva BTI para todo el binario enlazado** — y el ensamblador escrito a mano es justamente el obstáculo habitual en el despliegue de esta mitigación. Se instrumenta con las instrucciones `bti`/`paciasp`/`autiasp` correspondientes.
- **Verificar el binario producido, no los flags**: `readelf -n` para las propiedades GNU (IBT/SHSTK/BTI/PAC), `readelf -lW`/`checksec` para la pila no ejecutable y RELRO, y `--force-bti` / `--warn-execstack` en el enlace de CI para que un objeto sin marcar rompa el build. Que un flag esté en `CFLAGS` no significa que el `.S` lo respete.
- El ensamblador **no obtiene** hardening automático: `_FORTIFY_SOURCE`, canario de pila, `-fstack-clash-protection` y comprobaciones de límites del compilador **no existen** dentro de una rutina escrita a mano. Toda validación de longitudes y de punteros se hace explícitamente en el envoltorio C.

## 6. Depuración, perfilado y caducidad

- Herramientas: `perf` (`perf stat`, `perf record`, `perf annotate` para ver la rutina instrucción a instrucción con sus muestras), `objdump -d` sobre el objeto **realmente enlazado** (no sobre lo que se escribió: el ensamblador y el enlazador transforman), `gdb` con `layout asm`/`info registers`, y `godbolt` para la revisión comparativa.
- El perfilado atraviesa la rutina **solo si hay CFI** (§3). Sin ello, las trazas se cortan y el trabajo se atribuye al llamante equivocado.
- **El ensamblador optimizado para una microarquitectura caduca.** La secuencia óptima para una generación de CPU puede ser peor en la siguiente (cambian latencias, puertos de ejecución, anchos de vector, coste de las mitigaciones). Por eso cada rutina lleva **fecha de revisión** y **microarquitectura de referencia** en la cabecera, y en cada revisión se re-ejecuta el benchmark contra la referencia en C. Sin ventaja medible → se borra.
- Cada rutina tiene **dueño nominal**. Una rutina en ensamblador sin dueño es un bloque que nadie se atreve a tocar y que nadie puede validar: es deuda pura.

## 7. Sostenibilidad y prohibiciones

**Encuadre — skill defensiva y de ingeniería.** Esta skill trata la escritura y el mantenimiento de ensamblador **propio, en código propio, con propósito de rendimiento, arranque, interfaz con hardware o corrección criptográfica**. **No incluye ni incluirá recetario de explotación**: shellcode, gadgets ROP/JOP, técnicas de evasión de detección, ni construcción de *payloads*. Las mitigaciones se describen aquí **para aplicarlas correctamente**, nunca para eludirlas. Ese trabajo, con alcance y **autorización por escrito**, pertenece a `offensive-security-standards`; el análisis de un binario ajeno para responder a un incidente, a `incident-response-forensics-standards`.

**Cadencia**: revisar cada rutina al menos una vez al año y **siempre** al cambiar de toolchain, de arquitectura de destino o de generación de CPU objetivo. Al subir de compilador, re-medir: la razón más frecuente para borrar ensamblador es que el compilador ya lo hace igual de bien.

**Salida planificada**: toda rutina en ensamblador se escribe con la ruta de retirada ya prevista (la referencia en C, seleccionable en build). El objetivo por defecto de cada revisión es **poder borrarla**.

**PROHIBIDO** (requiere justificación escrita y aprobación para excepcionar):
- ❌ **Escribir ensamblador sin una medida previa que lo justifique** (perfil + benchmark), **sin implementación de referencia**, **sin tests** y **sin dueño**. Los cuatro, no tres de cuatro.
- ❌ **Copiar rutinas de internet sin entenderlas ni verificar su licencia.** Origen, versión, licencia y revisor quedan registrados; una rutina críptica sin procedencia no entra.
- ❌ Escribirlo cuando hay un **intrínseco** que hace lo mismo; escribirlo antes de agotar el cambio algorítmico.
- ❌ `asm` en línea para algo no trivial (va a un `.S` separado); `asm` básico sin operandos dentro de una función; bloque `asm` con lista de clobber incompleta o sin `volatile` cuando tiene efectos ocultos.
- ❌ Violar la ABI: no preservar un registro *callee-saved*, romper la alineación de pila, usar la red zone en código de kernel o de manejador de señal, deducir el paso de estructuras del desensamblado en vez de leer la ABI.
- ❌ Rutina sin **CFI/unwind info**, sin `.type`/`.size`, sin prefijo de proyecto o sin cabecera con ABI, ISA, contrato, dueño y fecha de revisión.
- ❌ Fichero de ensamblador ELF **sin `.note.GNU-stack`**; silenciar `--warn-execstack`; enlazar con pila ejecutable.
- ❌ Objeto sin `endbr64`/marcado IBT en x86-64 o sin marcado BTI en AArch64 en un proyecto que despliega esas mitigaciones (**un objeto sin marcar las desactiva para todo el binario**).
- ❌ **Implementar criptografía propia**; en código criptográfico, ramas o índices de memoria dependientes del secreto; `memset` para borrar secretos; comparación de secretos con salida temprana.
- ❌ Declarar una rutina "de tiempo constante" **sin verificarla** con TIMECOP/Valgrind, MemSan o equivalente.
- ❌ Mitigaciones especulativas escritas a mano sin CPU documentada y fecha de revisión, pudiendo dejarlas al compilador/kernel.
- ❌ Desplazamientos de estructura o constantes **hardcodeados** en vez de generados desde las cabeceras.
- ❌ Mezclar sintaxis AT&T e Intel en el mismo árbol; adoptar **YASM** en un proyecto nuevo.
- ❌ Suponer que ASan/MSan/UBSan cubren lo que hace el ensamblador, o que el hardening del compilador se aplica dentro de él.
- ❌ Mantener una rutina cuyo benchmark ya no muestra ventaja sobre la referencia en C.

## 8. Verificación web obligatoria

Antes de fijar versiones, flags o afirmar estado del ecosistema, **verificar por web** (nunca de memoria):
1. **Documentos de ABI vigentes**: System V AMD64 psABI (repo `gitlab.com/x86-psABIs/x86-64-ABI`), *x64 calling convention* de Microsoft en learn.microsoft.com, AAPCS64 en `github.com/ARM-software/abi-aa`, y las ABI specs de RISC-V. Se enmiendan: no citar de memoria.
2. **Ensambladores**: binutils en https://sourceware.org/binutils/ (verificado: **2.47**, 26-jul-2026; **gold ya no se distribuye por defecto**), NASM por `https://github.com/netwide-assembler/nasm/releases.atom` (verificado: **3.02**, 2026-06-29; licencia **BSD-2-Clause** en el `LICENSE` en crudo), YASM por `https://github.com/yasm/yasm/releases.atom` (verificado: **1.3.0, 2019**).
3. **MSVC**: página *Inline Assembler* de learn.microsoft.com para confirmar que sigue sin soporte en x64/ARM64, y la referencia de intrínsecos y de `ml64`.
4. **`asm goto` con salidas y otras extensiones**: versión mínima exacta de GCC/Clang en la documentación de la versión usada.
5. **Tiempo constante**: catálogo en https://crocs-muni.github.io/ct-tools/, guía de TIMECOP de Trail of Bits (appsec.guide) y estado de los repos de `dudect` y `ct-verif` antes de fijar un gate.
6. **CET/IBT y BTI/PAC**: `https://fedoraproject.org/wiki/Changes/Enable_Shadow_Stack_Userspace_Support`, notas de glibc y documentación del kernel (`docs.kernel.org/arch/x86/shstk.html`), y `dpkg-buildflags --export` / macros de `redhat-rpm-config` en la distro de destino. El estado por distribución cambia por release.
7. **Estado de las mitigaciones especulativas** en el hardware de destino: `/sys/devices/system/cpu/vulnerabilities/` y los avisos del fabricante; cada CVE nuevo cambia el criterio.
8. **Licencia y mantenimiento** de toda herramienta o rutina de terceros antes de fijarla como default: `LICENSE` en crudo desde `raw.githubusercontent.com` y feed Atom de releases, nunca un agregador.

**Huecos declarados (no verificados a ago-2026, verificar antes de usar como norma)**:
- **YASM**: su sitio oficial `yasm.tortall.net` **no resolvió por DNS** durante la verificación, así que la conclusión "dormido" se apoya solo en el feed Atom de GitHub (última release 2019). **No confirmado contra fuente oficial del proyecto** — verificar antes de afirmarlo por escrito ante terceros.
- Versión mínima exacta de GCC/Clang para **`asm goto` con salidas**: **no verificada**.
- Estado de **Ubuntu 26.04** respecto a la activación en *runtime* de shadow stack (solo consta que compila con `-fcf-protection`): **no verificado**. Idem el estado actual de BTI/PAC por defecto en Fedora 42+ y Ubuntu 26.04: las fuentes halladas son de 2022–2024.
- Estado de mantenimiento y aplicabilidad actual de **ct-verif** y **dudect** (actividad de sus repos): **no verificado**; la fuente consultada tampoco lo confirmaba.
- Versión concreta de Fedora que activa el *shadow stack* por defecto y su estado en FESCo: **no verificado**.
- Detalles de la interacción entre `--fatal-warnings` y `--warn-execstack` (bug ld/31299) en la versión de binutils del proyecto: **no verificado por versión**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
