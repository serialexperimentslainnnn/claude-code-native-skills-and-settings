---
name: fortran-standards
description: Modern and legacy Fortran for numerical and HPC codes. Use when working with .f/.for/.f77 fixed-form sources, .f90/.f95/.f03/.f08 free-form sources, .F90/.F/.FOR uppercase-suffixed files that go through the C preprocessor, .mod module files and module dependency ordering, gfortran/gcc -std=f2008/-std=f2018/-std=f2023, LLVM Flang (flang-new), Intel ifx and the retired ifort, NAG nagfor, Cray ftn, NVIDIA nvfortran, implicit none and IMPLICIT NONE (TYPE, EXTERNAL), COMMON blocks, EQUIVALENCE, ENTRY and computed GOTO, SAVE and initialization semantics, modules with USE ... ONLY and PRIVATE defaults, allocatable versus pointer, MOVE_ALLOC, selected_real_kind and iso_fortran_env real64/int64, iso_c_binding with bind(c) and c_ptr, coarrays with -fcoarray, this_image/num_images/sync all and OpenCoarrays caf/cafrun, DO CONCURRENT and its locality specifiers, OpenMP and OpenACC directives in Fortran, -fcheck=bounds/-fbacktrace/-ffpe-trap/-Wall -Wextra -pedantic, -ffree-line-length, CMake enable_language(Fortran), fpm and fpm.toml, or deciding whether to rewrite a Fortran numerical kernel in C++.
---

# Estándares de Fortran

Criterios verificados a **agosto de 2026**. Re-verificar por web antes de fijar nada (§8).

## 1. Alcance y triggers

**Fortran está vivo, y no por inercia: es el lenguaje del cómputo numérico de alto rendimiento.**
Los códigos de clima, CFD, química cuántica, estructuras, astrofísica y buena parte de LAPACK están
en Fortran, se siguen escribiendo en Fortran y **el estándar sigue evolucionando** — Fortran 2023
está publicado y la revisión siguiente está en trabajo activo (§2). Tratarlo como "COBOL con
matrices" es un error de encuadre que lleva directo a la reescritura fallida de §7.

El eje de esta skill: **en Fortran el compilador te da arrays multidimensionales de primera clase,
aliasing restringido por defecto en argumentos y un modelo de datos que el optimizador entiende.**
Esa es la ventaja, y casi todo el criterio de aquí consiste en **no destruirla** — ni con prácticas
de F77 (`COMMON`, `EQUIVALENCE`, tipado implícito) ni importando idiomas de C (punteros donde va
`allocatable`).

Cubre: estándar y forma de fuente, qué significa la mayúscula en `.F90`, compiladores y su soporte
real, disciplina de lenguaje (`implicit none`, módulos, `allocatable`, `kind`), interoperabilidad con
C, paralelismo (`do concurrent`, coarrays, OpenMP, OpenACC, MPI), flags de aviso y comprobación,
build (CMake, fpm) y la decisión de reescribir o no.

**No aplica**: ver `hpc` (**Ola 7, planificada**: el clúster y su explotación — Slurm, `sbatch`,
colas, particiones, planificación, contabilidad, sistemas de ficheros paralelos, dimensionado del
trabajo y **la ejecución y escalado de MPI a nivel de sitio**; **aquí solo el código Fortran y la
elección de su modelo de paralelismo**), `gpu-computing-standards` (**la GPU como recurso**: driver,
CUDA/ROCm, MIG, DCGM, coste — y el modelo de programación de GPU; **el `!$acc`/`!$omp target` que
escribes en el `.f90` y su corrección son de aquí, el kernel y la ocupación son suyos**),
`c-standards` y `cpp-standards` (**el otro lado de `iso_c_binding` es suyo**: cabeceras, ABI, ciclo
de vida de lo que se cede; **el lado Fortran —`bind(c)`, `c_ptr`, `value`, contigüidad, orden de
índices— es de aquí**; y son también el destino de una reescritura, cuya calidad se rige por su
criterio, no por el de aquí), `julia-standards` (**la alternativa moderna real para código numérico
nuevo de alto nivel**; §7 fija cuándo), `r-standards` y `python-standards` (código que **llama** a
kernels Fortran: la frontera —`f2py`, `ccall`, `.Fortran`— se diseña con `iso_c_binding` desde
aquí), `rust-standards` (memoria segura en sistemas; **no es competidor natural del kernel numérico
denso**, sí del código de infraestructura alrededor), `assembly-standards` (bajar a intrínsecos o
ensamblador: cuándo se justifica y cómo se mantiene), `performance-engineering-standards` (**método**
de medición y perfilado: hipótesis, medida antes que intuición; aquí solo qué mirar en Fortran),
`linux-administration-standards` y `rhel-fedora-standards` (módulos de entorno, paquetes y el host),
`cicd-standards` (la pipeline que ejecuta los gates de §4), `testing-qa-standards` (estrategia de
prueba), `git-workflow-standards`, `opensource-licensing-standards` (licencias de compiladores y
librerías numéricas), `refactoring-tech-debt-standards` (*strangler fig* y caracterización),
`legacy-modernization-standards` (cartera y decisión de invertir/migrar/
retirar), `green-it-standards` (consumo de un código que ocupa un clúster durante semanas).

## 2. Decisiones por defecto / Toolchain

> Verificar la última versión por web antes de fijarla en un proyecto real (§8).

| Decisión | Elección | Verificado a ago-2026 |
|---|---|---|
| Estándar objetivo | **Fortran 2018** para código nuevo portable; **2023** solo con la feature concreta verificada en tu compilador | **Fortran 2023 = ISO/IEC 1539-1:2023, publicado nov-2023** (5ª edición). **El soporte de F2023 es parcial en todos los compiladores**: se elige feature a feature, no como bandera global |
| Siguiente revisión | **F202Y / "Fortran 2028"** en trabajo activo | PWI ISO/IEC 1539-1 registrado en 2024; hay lista de trabajo y *committee draft* en WG5. Áreas: programación genérica y **preprocesador estandarizado**. **No planifiques con features de 2028** |
| Forma de fuente | **Libre siempre** en código nuevo (`.f90` y posteriores) | La forma fija (columnas 1-6, continuación en col. 6) es de F77. Convertir a libre es mecánico y de bajo riesgo, a diferencia de casi todo lo demás de §7 |
| Extensión y preprocesador | **`.f90` = sin preprocesador; `.F90` = con preprocesador C** | La mayúscula no es estilo: es lo que hace que el compilador pase el fichero por `cpp`. Un `#ifdef` en un `.f90` **falla o se ignora según compilador** |
| Compilador libre | **gfortran** (GCC) | **GCC 16.1 (2026-04-30)**; GCC 15.3 (2026-06-12) y 14.4 (2026-06-26) siguen mantenidas. F95 completo, casi todo F2003/2008, mucho de F2018 y **soporte inicial de F2023** |
| Compilador LLVM | **LLVM Flang** — maduro para F77/90/95, **no para coarrays** | Documento oficial: *"The two major missing features in Flang at present are coarrays and parameterized derived types (PDTs) with length type parameters."* Y sobre su propia tabla: *"The TODOs/Not Yet Implemented messages emitted by the compiler for unimplemented features should be treated as authoritative."* |
| Compilador Intel | **`ifx`** (basado en LLVM) | **`ifort` está retirado**: entró en *Legacy Product Support* en nov-2023, últimos cambios funcionales en abr-2024, **última versión 2024.2 (compilador 2021.13.0)** y **no se distribuye desde oneAPI 2025.0**. Si tu build llama a `ifort`, está roto o congelado |
| Trampa al migrar ifort→ifx | **`ifx` no genera 32 bits** y difiere en punto flotante | Sin IA-32: `-m32` / `/Qm32` no soportados (bloqueo de portado más común). `-fp-model fast` difiere en comparaciones con NaN: `-assume nan_compare` restaura el comportamiento de `ifort`. Compatible a nivel de `.o`/`.mod` con `ifort` |
| Compilador NVIDIA | **`nvfortran`** (NVIDIA HPC SDK) si el destino es GPU | HPC SDK **26.5** (jun-2026). SDK descargable sin coste bajo su EULA; **el soporte técnico es de pago aparte**. Cobertura: F2003 + parte de F2008, CUDA Fortran, OpenACC, OpenMP |
| Compilador Cray | `ftn` (Cray Compiling Environment) en máquinas HPE/Cray | Es el compilador con mejor soporte histórico de **coarrays**. **Solo existe en su plataforma**: no lo pongas como requisito de un código que debe correr fuera |
| Compilador de conformidad | **NAG `nagfor`** como *segundo* compilador de CI | Es el más estricto del mercado y encuentra lo que gfortran deja pasar. **Comercial y sin tarifa pública** (§8): licencia individual por tienda web, multiusuario a presupuesto |
| Gestor de paquetes / build | **CMake** (`enable_language(Fortran)`) por defecto; **fpm** para librerías y proyectos autocontenidos | **fpm v0.13.0 (2026-02-17), licencia MIT verificada en el `LICENSE` en crudo**. **Sigue en 0.x**: úsalo sabiendo que no promete estabilidad de interfaz; para integrarte en un código HPC existente con dependencias de sistema, manda CMake |
| Librerías numéricas | **No reimplementes BLAS/LAPACK.** OpenBLAS, MKL/oneMKL, AOCL o la del proveedor | Llamar a la BLAS optimizada del sitio bate a cualquier bucle propio. Verifica la licencia de la que enlaces |

**Regla dura de estándar**: se compila **siempre** con `-std=` explícito (`-std=f2018`) y
`-pedantic`. Sin él estás usando extensiones del compilador sin saberlo, y la portabilidad se
descubre el día que cambias de máquina.

## 3. Estructura y convenciones de lenguaje

- **`implicit none` en toda unidad de programa. Sin excepciones, sin discusión.** Es la regla más
  barata y la que más bugs evita: sin ella, una variable mal escrita se crea sola con tipo según su
  inicial. Con F2018, **`implicit none (type, external)`** — obliga además a declarar interfaz de
  todo procedimiento externo. En el build, `-fimplicit-none` (gfortran) como red.
- **Módulos, no `COMMON`.** `COMMON` y `EQUIVALENCE` son estado global sin tipo comprobado ni
  interfaz. Todo dato compartido va en un módulo con `private` por defecto y `public` explícito;
  todo procedimiento vive en un módulo o en `contains` para que **exista interfaz explícita** y el
  compilador compruebe los argumentos. Y **`use ..., only:` siempre**: `use` a pelo importa todo el
  módulo y colisiona en silencio.
- **`allocatable` frente a `pointer`: `allocatable` por defecto, siempre.** Se libera al salir de
  alcance y **no puede tener aliasing, por eso el optimizador genera mejor código**. `pointer` solo
  para estructuras que lo exigen (listas, árboles), con comprobación de `associated`. Para transferir
  propiedad sin copiar, `move_alloc`.
- **`intent(in|out|inout)` en todos los argumentos ficticios**: es documentación *y* comprobación.
  Ojo a la semántica de desasignación de `intent(out)` sobre derivados con componentes `allocatable`.
- **Precisión con `kind`, nunca `real*8` ni `double precision`.** `real*8` no es estándar: se usa
  `iso_fortran_env` (`real64`…) o `selected_real_kind`, con **una única constante de `kind` de
  proyecto**. Y los literales llevan kind: `1.0_wp`, no `1.0`, que es simple precisión y trunca.
- **Orden de índices: Fortran es *column-major*.** El bucle interno recorre el **primer** índice;
  al revés cuesta un orden de magnitud y es el error número uno de quien viene de C. Las expresiones
  de array pueden generar temporales: **mide**. `associate` para nombrar subexpresiones sin copia, y
  `contiguous` solo cuando de verdad lo es — mentir ahí es copia oculta o UB.
- **Prohibido en código nuevo**: `goto` calculado/asignado, `entry`, `equivalence`, `common`, `pause`,
  formato fijo, y **el `save` implícito**: una variable local con valor inicial en la declaración
  **es `save`** — bug clásico de reentrada; declárala `save` si lo quieres, o inicialízala en el cuerpo.
- **Nombres**: minúsculas y `snake_case` (el lenguaje es *case-insensitive*; mezclar solo rompe la
  búsqueda). **Un módulo por fichero, con el nombre del módulo**, porque el orden de compilación lo
  dictan las dependencias de `.mod` y el build tiene que deducirlas — CMake y fpm lo hacen; un
  `Makefile` a mano con esas dependencias desactualizadas da builds incrementales incorrectos.

## 4. Avisos, comprobaciones y gates de CI

Orden de coste creciente; los tres primeros son gate que rompe el build.

1. **Compilación limpia** (gfortran): `-std=f2018 -pedantic -Wall -Wextra -Wimplicit-interface
   -Wimplicit-procedure -Werror`. Un aviso de interfaz implícita significa que el compilador **no
   está comprobando** esa llamada: es un fallo, no un aviso.
2. **Build de depuración con comprobaciones en ejecución**, y la suite completa pasa ahí: `-g -O0
   -fcheck=all -fbacktrace -finit-real=snan -ffpe-trap=invalid,zero,overflow`. **`-fcheck=bounds` es
   lo más rentable de este documento**: el desbordamiento de array no da error, da números plausibles
   y equivocados. Y `-ffpe-trap` para el NaN que si no se propaga hasta la figura del paper.
3. **Segundo compilador en CI** (gfortran + `ifx`, `nagfor` o Flang): detector barato de dependencia
   de extensiones y de UB.
4. **Tests numéricos con tolerancia explícita y justificada**, nunca `==` sobre reales. Bordes: array
   de tamaño 0 y 1, denormales, NaN/Inf de entrada, dimensiones no contiguas. Marcos: `test-drive` o
   `pFUnit` (con soporte MPI). El código heredado sin tests se cubre primero con **caracterización**
   sobre salidas conocidas. Y `-fsanitize=address,undefined` en el código de interoperabilidad C.
5. **Reproducibilidad numérica como requisito declarado**: fija y documenta los flags de punto
   flotante. `-ffast-math` / `-fp-model fast` **reordenan operaciones y cambian el resultado**, y se
   prohíben en código que publica cifras salvo ADR con medida del error. Una reducción OpenMP con
   distinto número de hilos ya da resultados distintos: dilo tú, no lo descubra el revisor.

## 5. Seguridad y corrección del stack

- **La superficie de riesgo no es la web, es la entrada de datos**: mallas, *namelists*, binarios sin
  versionar, argumentos de línea de comandos. **Valida dimensiones y rangos al leer**; un `read` de
  binario con endianness o layout distinto no falla, corrompe.
- **`iostat`/`iomsg` en toda E/S y `stat=` en todo `allocate`. Nunca los ignores**: un `read` fallido
  deja la variable sin cambiar y el programa sigue. `character(len=:), allocatable` frente a longitud
  fija con `read` sin control, que es el desbordamiento clásico.
- **`iso_c_binding` es la frontera de confianza**: `bind(c)` explícito, tipos de `iso_c_binding`
  (nunca `integer` "a ver si coincide"), `c_null_char` explícito, y **quién libera qué escrito en la
  interfaz**. El otro lado, en `c-standards`.
- **Dependencias**: MPI, BLAS/LAPACK, HDF5, NetCDF y PETSc son C/C++ por debajo y sus CVEs son tuyos
  (`vulnerability-management-standards`). Sin secretos ni rutas de máquina en el fuente. Y las
  licencias de compilador y librería numérica (MKL, IMSL, NAG Library, Netlib) se leen en crudo antes
  de distribuir el binario (`opensource-licensing-standards`).

## 6. Paralelismo y rendimiento

- **Elige un modelo y decláralo.** Los cuatro que compiten:
  - **`do concurrent`**: estándar, portable, sin directivas, y con los especificadores de localidad
    (`local`, `local_init`, `shared`, `reduce`) de F2018/F2023 es la vía estándar de paralelismo de
    bucle; varios compiladores lo mapean a GPU. **Verifica qué hace el tuyo**: "conforme" no implica
    "paralelizado".
  - **OpenMP** (`!$omp`): el default para **memoria compartida dentro del nodo**, con *offload* a GPU
    (`target`). Es lo que se usa salvo motivo.
  - **OpenACC** (`!$acc`): más simple para llevar código existente a GPU, pero **su ecosistema real es
    NVIDIA** (`nvfortran`); gfortran lo soporta parcialmente. Elegirlo es acoplamiento de proveedor: ADR.
  - **MPI**: **imprescindible para múltiples nodos**. Módulo `mpi_f08` (interfaces con tipos
    comprobados), **nunca `include 'mpif.h'`** ni el módulo `mpi` antiguo.
- **Coarrays frente a MPI — el criterio honesto**: los coarrays están *en el estándar* y el código
  resultante es mucho más legible que MPI. Pero **el soporte real es desigual y es lo que decide**:
  Flang **no los implementa**; gfortran, a partir de **GCC 16.1**, soporta *nativamente* coarrays
  **en un solo nodo** con hilos y memoria compartida (incluido `team` de F2018) — verbatim del
  changelog: *"Coarrays using native shared memory mulithreading on single node machines and handling
  Fortran 2018's `TEAM` feature."* — y para **multi-nodo sigue haciendo falta la ruta
  `-fcoarray=lib` con OpenCoarrays sobre MPI** (`caf`/`cafrun`). `-fcoarray=single` es el modo serie
  para depurar. **Conclusión operativa: coarrays son razonables intra-nodo y para código nuevo que
  controla su compilador; para producción multi-nodo y portable, MPI.**
- **Rendimiento, por orden**: (1) orden de bucles (column-major, §3), (2) acceso a memoria y bloqueo
  por caché, (3) vectorización (`-O2`/`-O3 -march=native`, **leyendo el informe de vectorización**,
  no suponiendo), (4) librería optimizada frente a bucle propio — gana casi siempre la librería.
  **Nada de esto sin medir** (`performance-engineering-standards`).
- **Operabilidad de un trabajo largo**: *checkpoint* reanudable, progreso a stdout con *flush* y
  código de salida distinto de cero al fallar — un trabajo de 48 h que muere sin rastro cuesta 48 h.
  La cola, el `sbatch` y los límites de pared son de `hpc`.

## 7. Cuándo NO usar Fortran, cuándo reescribir, y prohibiciones

**Fortran es la elección correcta cuando**: el problema es cómputo numérico denso sobre arrays, ya
existe un código Fortran validado, o el destino es un clúster con toolchain HPC. **No lo es** para
servicios, herramientas de sistema, tratamiento de texto, interfaces de usuario o pegamento — para
eso, Python/Julia por arriba y C/Rust por abajo, llamando a los kernels Fortran por
`iso_c_binding`.

**Por qué reescribir un código Fortran científico en C++ suele salir mal** (mecanismos, no anécdota):

1. **Pierdes lo que te daba el lenguaje**: arrays multidimensionales nativos con secciones y aliasing
   restringido. En C++ se reconstruye con plantillas y librerías, y rara vez optimiza mejor.
2. **Lo valioso no es el código, es la validación**: décadas de comparación contra experimento. Una
   reescritura la reinicia a cero, y **detectar la diferencia numérica cuesta más que reescribir**.
3. **El código encierra física y numérica no documentada** (constantes empíricas, esquemas de
   discretización, cortes de estabilidad), que vive en el código o en la cabeza del autor.
4. **Los resultados no son idénticos y no pueden serlo**: cambiar de lenguaje cambia el orden de las
   operaciones en punto flotante. "El nuevo da otro número" arranca una investigación de meses.
5. **El equipo son científicos del dominio, no ingenieros de C++**: sustituir el lenguaje que dominan
   por el más complejo del catálogo es un coste de mantenimiento permanente.

**Lo que sí funciona, por orden**: (a) **modernizar en el sitio** — forma libre, `implicit none`,
módulos con interfaces, `allocatable`, matando `COMMON` por dominios, cada paso con test de
caracterización; (b) **envolver**: exponer el kernel por `iso_c_binding` y construir lo nuevo fuera
(Python, Julia, C++) contra esa interfaz; (c) **sustituir por kernels aislados y medidos**, nunca el
código entero.

**Prohibiciones:**

- ❌ **PROHIBIDO** código nuevo sin `implicit none`. Es la única regla de este documento sin
  excepción posible.
- ❌ Reescritura *big bang* de un código científico validado a otro lenguaje. Ver los cinco
  mecanismos de arriba.
- ❌ `COMMON`, `EQUIVALENCE`, `ENTRY`, `goto` calculado/asignado, `pause` y forma fija en código
  nuevo.
- ❌ `real*8`, `integer*4` y demás sintaxis de asterisco: no son estándar. Y **literales sin kind**
  (`1.0` en una expresión de doble precisión).
- ❌ `pointer` donde vale `allocatable`.
- ❌ `use` de módulo sin `only:`.
- ❌ `include 'mpif.h'` en código nuevo: `use mpi_f08`.
- ❌ Ignorar `iostat`/`stat` en E/S y en `allocate`.
- ❌ `-ffast-math` / `-fp-model fast` en código que publica cifras, sin ADR con medida del error.
- ❌ Compilar sin `-std=` explícito, o entregar sin haber pasado una vez por `-fcheck=all`
  y `-ffpe-trap`.
- ❌ Depender de `ifort`: **está retirado y no se distribuye desde oneAPI 2025.0** (§2).
- ❌ Poner `#ifdef` en un fichero `.f90` en minúsculas y confiar en que el compilador lo preprocese.
- ❌ Escribir tu propia multiplicación de matrices en producción en lugar de llamar a BLAS.
- ❌ Comprometer un código a coarrays multi-nodo sin verificar antes el soporte del compilador
  del sitio (§6).

## 8. Verificación web obligatoria

Antes de fijar nada en un proyecto real, comprobar por web:

1. **Estado de F2023 en tu compilador, feature a feature** — **no existe "soporte de F2023" como
   sí/no**: la tabla de cada proveedor (Flang: `flang.llvm.org/docs/FortranStandardsSupport.html`,
   que advierte de que **los mensajes "Not Yet Implemented" del compilador mandan sobre su tabla**;
   Intel, su tabla viva de F2023/OpenMP; gfortran, la sección Fortran de las notas de cada GCC).
2. **GCC/gfortran** (a ago-2026: **16.1**, 2026-04-30; 15.3 y 14.4 vigentes) y sus novedades de
   Fortran — **especialmente coarrays**, que cambiaron en 16.1.
3. **Intel**: estado de `ifort` (retirado; última 2024.2, fuera de los paquetes desde 2025.0),
   versión vigente de `ifx` y la guía oficial de portado `ifort`→`ifx`.
4. **NVIDIA HPC SDK** (a ago-2026: **26.5**, jun-2026): CUDA que empaqueta y cobertura OpenACC/OpenMP.
5. **NAG**: versión y **precio** — **hueco declarado: nAG no publica tarifa pública** (licencia
   individual por tienda web, multiusuario a presupuesto; hubo cambio de precios a principios de
   2026). Tampoco pude confirmar si hay release posterior a la **7.2** de su página de descargas.
6. **fpm**: versión (a ago-2026 **v0.13.0**, 2026-02-17), **el hecho de que sigue en 0.x**, y
   licencia **MIT verificada leyendo el `LICENSE` en crudo**.
7. **Progreso de F202Y/"Fortran 2028"** en WG5/J3 (genéricos, preprocesador estandarizado): para no
   diseñar contra features que aún no existen.
8. **CVEs** de MPI, HDF5, NetCDF, BLAS/LAPACK y del compilador, y licencias de las librerías que
   enlaces. **Estado de `hpc` (Ola 7, planificada)**: cuando exista, **el criterio de clúster, Slurm,
   colas y escalado es suyo**.

Si la web contradice este documento, **manda la web** y señala la discrepancia.
