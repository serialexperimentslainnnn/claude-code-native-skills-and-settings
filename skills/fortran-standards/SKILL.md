---
name: fortran-standards
description: Modern and legacy Fortran for numerical and HPC codes. Use when working with .f/.for/.f77 fixed-form sources, .f90/.f95/.f03/.f08 free-form sources, .F90/.F/.FOR uppercase-suffixed files that go through the C preprocessor, .mod module files and module dependency ordering, gfortran/gcc -std=f2008/-std=f2018/-std=f2023, LLVM Flang (flang-new), Intel ifx and the retired ifort, NAG nagfor, Cray ftn, NVIDIA nvfortran, implicit none and IMPLICIT NONE (TYPE, EXTERNAL), COMMON blocks, EQUIVALENCE, ENTRY and computed GOTO, SAVE and initialization semantics, modules with USE ... ONLY and PRIVATE defaults, allocatable versus pointer, MOVE_ALLOC, selected_real_kind and iso_fortran_env real64/int64, iso_c_binding with bind(c) and c_ptr, coarrays with -fcoarray, this_image/num_images/sync all and OpenCoarrays caf/cafrun, DO CONCURRENT and its locality specifiers, OpenMP and OpenACC directives in Fortran, -fcheck=bounds/-fbacktrace/-ffpe-trap/-Wall -Wextra -pedantic, -ffree-line-length, CMake enable_language(Fortran), fpm and fpm.toml, or deciding whether to rewrite a Fortran numerical kernel in C++.
---

# Fortran standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Fortran is alive, and not out of inertia: it is the language of high-performance numerical computing.**
The codes for climate, CFD, quantum chemistry, structures, astrophysics and a good part of LAPACK are
in Fortran, are still being written in Fortran and **the standard keeps evolving** — Fortran 2023
is published and the next revision is under active work (§2). Treating it as "COBOL with
arrays" is a framing error that leads straight to the failed rewrite of §7.

The axis of this skill: **in Fortran the compiler gives you first-class multidimensional arrays,
aliasing restricted by default in arguments and a data model the optimiser understands.**
That is the advantage, and almost all the criteria here consist of **not destroying it** — neither with F77
practices (`COMMON`, `EQUIVALENCE`, implicit typing) nor by importing idioms from C (pointers where
`allocatable` belongs).

Covers: standard and source form, what the uppercase in `.F90` means, compilers and their real
support, language discipline (`implicit none`, modules, `allocatable`, `kind`), interoperability with
C, parallelism (`do concurrent`, coarrays, OpenMP, OpenACC, MPI), warning and checking flags,
build (CMake, fpm) and the decision whether to rewrite.

**Not applicable**: see `hpc-standards` (the cluster and its exploitation — Slurm, `sbatch`,
queues, partitions, scheduling, accounting, parallel filesystems, job sizing
and **MPI execution and scaling at site level**; **here only the Fortran code and the
choice of its parallelism model**), `gpu-computing-standards` (**the GPU as a resource**: driver,
CUDA/ROCm, MIG, DCGM, cost — and the GPU programming model; **the `!$acc`/`!$omp target` you
write in the `.f90` and its correctness are ours, the kernel and the occupancy are theirs**),
`c-standards` and `cpp-standards` (**the other side of `iso_c_binding` is theirs**: headers, ABI, life
cycle of what is handed over; **the Fortran side —`bind(c)`, `c_ptr`, `value`, contiguity, index
order— is ours**; and they are also the destination of a rewrite, whose quality is governed by their
criteria, not by these), `julia-standards` (**the real modern alternative for new high-level
numerical code**; §7 sets when), `r-standards` and `python-standards` (code that **calls** Fortran
kernels: the boundary —`f2py`, `ccall`, `.Fortran`— is designed with `iso_c_binding` from
here), `rust-standards` (memory safety in systems; **not a natural competitor to the dense numerical
kernel**, but yes to the infrastructure code around it), `assembly-standards` (dropping to intrinsics or
assembly: when it is justified and how it is maintained), `performance-engineering-standards` (**method**
of measurement and profiling: hypothesis, measurement over intuition; here only what to look at in Fortran),
`linux-administration-standards` and `rhel-fedora-standards` (environment modules, packages and the host),
`cicd-standards` (the pipeline that runs the §4 gates), `testing-qa-standards` (test
strategy), `git-workflow-standards`, `opensource-licensing-standards` (licences of compilers and
numerical libraries), `refactoring-tech-debt-standards` (*strangler fig* and characterisation),
`legacy-modernization-standards` (portfolio and the decision to invest/migrate/
retire), `green-it-standards` (the consumption of a code that occupies a cluster for weeks).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Choice | Verified as of Aug 2026 |
|---|---|---|
| Target standard | **Fortran 2018** for portable new code; **2023** only with the concrete feature verified in your compiler | **Fortran 2023 = ISO/IEC 1539-1:2023, published Nov 2023** (5th edition). **F2023 support is partial in every compiler**: it is chosen feature by feature, not as a global flag |
| Next revision | **F202Y / "Fortran 2028"** under active work | PWI ISO/IEC 1539-1 registered in 2024; there is a work list and a *committee draft* in WG5. Areas: generic programming and a **standardised preprocessor**. **Do not plan around 2028 features** |
| Source form | **Free always** in new code (`.f90` and later) | Fixed form (columns 1-6, continuation in col. 6) is from F77. Converting to free form is mechanical and low risk, unlike almost everything else in §7 |
| Extension and preprocessor | **`.f90` = no preprocessor; `.F90` = with the C preprocessor** | The uppercase is not style: it is what makes the compiler run the file through `cpp`. An `#ifdef` in a `.f90` **fails or is ignored depending on the compiler** |
| Free compiler | **gfortran** (GCC) | **GCC 16.1 (2026-04-30)**; GCC 15.3 (2026-06-12) and 14.4 (2026-06-26) are still maintained. Full F95, nearly all of F2003/2008, much of F2018 and **initial F2023 support** |
| LLVM compiler | **LLVM Flang** — mature for F77/90/95, **not for coarrays** | Official document: *"The two major missing features in Flang at present are coarrays and parameterized derived types (PDTs) with length type parameters."* And about its own table: *"The TODOs/Not Yet Implemented messages emitted by the compiler for unimplemented features should be treated as authoritative."* |
| Intel compiler | **`ifx`** (LLVM-based) | **`ifort` is retired**: it entered *Legacy Product Support* in Nov 2023, last functional changes in Apr 2024, **last version 2024.2 (compiler 2021.13.0)** and **it is not shipped from oneAPI 2025.0 onwards**. If your build calls `ifort`, it is broken or frozen |
| ifort→ifx migration trap | **`ifx` does not generate 32-bit** and differs in floating point | No IA-32: `-m32` / `/Qm32` unsupported (the most common porting blocker). `-fp-model fast` differs in NaN comparisons: `-assume nan_compare` restores `ifort` behaviour. Compatible at the `.o`/`.mod` level with `ifort` |
| NVIDIA compiler | **`nvfortran`** (NVIDIA HPC SDK) if the target is a GPU | HPC SDK **26.5** (Jun 2026). SDK downloadable at no cost under its EULA; **technical support is paid separately**. Coverage: F2003 + part of F2008, CUDA Fortran, OpenACC, OpenMP |
| Cray compiler | `ftn` (Cray Compiling Environment) on HPE/Cray machines | It is the compiler with the best historical **coarray** support. **It only exists on its platform**: do not make it a requirement of a code that must run elsewhere |
| Conformance compiler | **NAG `nagfor`** as a *second* CI compiler | It is the strictest on the market and finds what gfortran lets through. **Commercial and with no public price list** (§8): individual licence via the web shop, multi-user by quote |
| Package manager / build | **CMake** (`enable_language(Fortran)`) by default; **fpm** for libraries and self-contained projects | **fpm v0.13.0 (2026-02-17), MIT licence verified in the raw `LICENSE`**. **Still on 0.x**: use it knowing it promises no interface stability; to integrate into an existing HPC code with system dependencies, CMake wins |
| Numerical libraries | **Do not reimplement BLAS/LAPACK.** OpenBLAS, MKL/oneMKL, AOCL or the vendor's | Calling the site's optimised BLAS beats any loop of your own. Verify the licence of the one you link |

**Hard standard rule**: **always** compile with an explicit `-std=` (`-std=f2018`) and
`-pedantic`. Without it you are using compiler extensions without knowing it, and portability gets
discovered the day you change machine.

## 3. Structure and language conventions

- **`implicit none` in every program unit. No exceptions, no discussion.** It is the cheapest rule and
  the one that prevents most bugs: without it, a misspelled variable creates itself with a type based on its
  initial letter. With F2018, **`implicit none (type, external)`** — it additionally forces declaring an interface for
  every external procedure. In the build, `-fimplicit-none` (gfortran) as a net.
- **Modules, not `COMMON`.** `COMMON` and `EQUIVALENCE` are global state with no checked type nor
  interface. All shared data goes in a module with `private` by default and explicit `public`;
  every procedure lives in a module or in `contains` so that **an explicit interface exists** and the
  compiler checks the arguments. And **`use ..., only:` always**: a bare `use` imports the whole
  module and collides silently.
- **`allocatable` versus `pointer`: `allocatable` by default, always.** It is freed on leaving
  scope and **cannot have aliasing, which is why the optimiser generates better code**. `pointer` only
  for structures that demand it (lists, trees), with an `associated` check. To transfer
  ownership without copying, `move_alloc`.
- **`intent(in|out|inout)` on all dummy arguments**: it is documentation *and* checking.
  Watch the deallocation semantics of `intent(out)` on derived types with `allocatable` components.
- **Precision with `kind`, never `real*8` nor `double precision`.** `real*8` is not standard: use
  `iso_fortran_env` (`real64`…) or `selected_real_kind`, with **a single project-wide `kind`
  constant**. And literals carry a kind: `1.0_wp`, not `1.0`, which is single precision and truncates.
- **Index order: Fortran is *column-major*.** The inner loop walks the **first** index;
  the other way round costs an order of magnitude and is the number-one mistake of anyone coming from C. Array
  expressions can generate temporaries: **measure**. `associate` to name subexpressions without a copy, and
  `contiguous` only when it truly is — lying there means a hidden copy or UB.
- **Forbidden in new code**: computed/assigned `goto`, `entry`, `equivalence`, `common`, `pause`,
  fixed form, and **the implicit `save`**: a local variable with an initial value in its declaration
  **is `save`** — a classic reentrancy bug; declare it `save` if that is what you want, or initialise it in the body.
- **Names**: lowercase and `snake_case` (the language is *case-insensitive*; mixing only breaks
  search). **One module per file, named after the module**, because the compilation order is
  dictated by the `.mod` dependencies and the build has to derive them — CMake and fpm do; a
  hand-written `Makefile` with those dependencies out of date gives incorrect incremental builds.

## 4. Warnings, checks and CI gates

In increasing order of cost; the first three are a gate that breaks the build.

1. **Clean compilation** (gfortran): `-std=f2018 -pedantic -Wall -Wextra -Wimplicit-interface
   -Wimplicit-procedure -Werror`. An implicit-interface warning means the compiler is **not
   checking** that call: it is a failure, not a warning.
2. **Debug build with runtime checks**, and the full suite passes there: `-g -O0
   -fcheck=all -fbacktrace -finit-real=snan -ffpe-trap=invalid,zero,overflow`. **`-fcheck=bounds` is
   the highest-return item in this document**: an array overrun does not give an error, it gives plausible
   and wrong numbers. And `-ffpe-trap` for the NaN that otherwise propagates all the way to the figure in the paper.
3. **A second compiler in CI** (gfortran + `ifx`, `nagfor` or Flang): a cheap detector of dependence
   on extensions and of UB.
4. **Numerical tests with an explicit, justified tolerance**, never `==` on reals. Edges: arrays
   of size 0 and 1, denormals, NaN/Inf inputs, non-contiguous dimensions. Frameworks: `test-drive` or
   `pFUnit` (with MPI support). Inherited code without tests is covered first with **characterisation**
   against known outputs. And `-fsanitize=address,undefined` in the C interoperability code.
5. **Numerical reproducibility as a declared requirement**: pin and document the floating-point
   flags. `-ffast-math` / `-fp-model fast` **reorder operations and change the result**, and are
   forbidden in code that publishes figures except with an ADR that measures the error. An OpenMP reduction with
   a different thread count already gives different results: say it yourself, do not let the reviewer discover it.

## 5. Stack security and correctness

- **The risk surface is not the web, it is data input**: meshes, *namelists*, unversioned
  binaries, command-line arguments. **Validate dimensions and ranges on read**; a binary `read`
  with a different endianness or layout does not fail, it corrupts.
- **`iostat`/`iomsg` on all I/O and `stat=` on every `allocate`. Never ignore them**: a failed `read`
  leaves the variable unchanged and the program carries on. `character(len=:), allocatable` over fixed
  length with an unchecked `read`, which is the classic overflow.
- **`iso_c_binding` is the trust boundary**: explicit `bind(c)`, `iso_c_binding` types
  (never an `integer` "let's see if it matches"), explicit `c_null_char`, and **who frees what written in the
  interface**. The other side, in `c-standards`.
- **Dependencies**: MPI, BLAS/LAPACK, HDF5, NetCDF and PETSc are C/C++ underneath and their CVEs are yours
  (`vulnerability-management-standards`). No secrets nor machine paths in the source. And the
  licences of the compiler and the numerical library (MKL, IMSL, NAG Library, Netlib) are read raw before
  distributing the binary (`opensource-licensing-standards`).

## 6. Parallelism and performance

- **Pick a model and declare it.** The four that compete:
  - **`do concurrent`**: standard, portable, directive-free, and with the locality specifiers
    (`local`, `local_init`, `shared`, `reduce`) of F2018/F2023 it is the standard route to loop
    parallelism; several compilers map it to the GPU. **Verify what yours does**: "conforming" does not imply
    "parallelised".
  - **OpenMP** (`!$omp`): the default for **shared memory within the node**, with *offload* to GPU
    (`target`). It is what gets used unless there is a reason otherwise.
  - **OpenACC** (`!$acc`): simpler for taking existing code to the GPU, but **its real ecosystem is
    NVIDIA** (`nvfortran`); gfortran supports it partially. Choosing it is vendor coupling: ADR.
  - **MPI**: **essential for multiple nodes**. `mpi_f08` module (interfaces with checked
    types), **never `include 'mpif.h'`** nor the old `mpi` module.
- **Coarrays versus MPI — the honest criteria**: coarrays are *in the standard* and the resulting
  code is far more readable than MPI. But **real support is uneven and that is what decides**:
  Flang **does not implement them**; gfortran, from **GCC 16.1**, supports coarrays *natively*
  **on a single node** with threads and shared memory (including F2018's `team`) — verbatim from the
  changelog: *"Coarrays using native shared memory mulithreading on single node machines and handling
  Fortran 2018's `TEAM` feature."* — and for **multi-node you still need the
  `-fcoarray=lib` route with OpenCoarrays over MPI** (`caf`/`cafrun`). `-fcoarray=single` is the serial mode
  for debugging. **Operational conclusion: coarrays are reasonable intra-node and for new code that
  controls its compiler; for portable multi-node production, MPI.**
- **Performance, in order**: (1) loop order (column-major, §3), (2) memory access and cache
  blocking, (3) vectorisation (`-O2`/`-O3 -march=native`, **reading the vectorisation report**,
  not assuming), (4) optimised library versus your own loop — the library wins nearly always.
  **None of this without measuring** (`performance-engineering-standards`).
- **Operability of a long job**: resumable *checkpoint*, progress to stdout with *flush* and
  a non-zero exit code on failure — a 48 h job that dies without a trace costs 48 h.
  The queue, the `sbatch` and the wall limits belong to `hpc`.

## 7. When NOT to use Fortran, when to rewrite, and prohibitions

**Fortran is the right choice when**: the problem is dense numerical computation over arrays, a
validated Fortran code already exists, or the target is a cluster with an HPC toolchain. **It is not** for
services, system tools, text processing, user interfaces or glue — for
that, Python/Julia on top and C/Rust underneath, calling the Fortran kernels via
`iso_c_binding`.

**Why rewriting a scientific Fortran code in C++ usually goes badly** (mechanisms, not anecdote):

1. **You lose what the language gave you**: native multidimensional arrays with sections and restricted
   aliasing. In C++ it is reconstructed with templates and libraries, and rarely optimises better.
2. **What is valuable is not the code, it is the validation**: decades of comparison against experiment. A
   rewrite resets it to zero, and **detecting the numerical difference costs more than rewriting**.
3. **The code encodes undocumented physics and numerics** (empirical constants, discretisation
   schemes, stability cutoffs), which live in the code or in the author's head.
4. **The results are not identical and cannot be**: changing language changes the order of
   floating-point operations. "The new one gives a different number" starts a months-long investigation.
5. **The team are domain scientists, not C++ engineers**: replacing the language they master
   with the most complex in the catalogue is a permanent maintenance cost.

**What does work, in order**: (a) **modernise in place** — free form, `implicit none`,
modules with interfaces, `allocatable`, killing `COMMON` domain by domain, each step with a characterisation
test; (b) **wrap**: expose the kernel via `iso_c_binding` and build the new thing outside
(Python, Julia, C++) against that interface; (c) **replace with isolated, measured kernels**, never the
whole code.

**Prohibitions:**

- ❌ **FORBIDDEN** new code without `implicit none`. It is the only rule in this document with no
  possible exception.
- ❌ *Big bang* rewrite of a validated scientific code into another language. See the five
  mechanisms above.
- ❌ `COMMON`, `EQUIVALENCE`, `ENTRY`, computed/assigned `goto`, `pause` and fixed form in new
  code.
- ❌ `real*8`, `integer*4` and the rest of the asterisk syntax: they are not standard. And **literals without a kind**
  (`1.0` in a double-precision expression).
- ❌ `pointer` where `allocatable` will do.
- ❌ `use` of a module without `only:`.
- ❌ `include 'mpif.h'` in new code: `use mpi_f08`.
- ❌ Ignoring `iostat`/`stat` in I/O and in `allocate`.
- ❌ `-ffast-math` / `-fp-model fast` in code that publishes figures, without an ADR measuring the error.
- ❌ Compiling without an explicit `-std=`, or delivering without having gone once through `-fcheck=all`
  and `-ffpe-trap`.
- ❌ Depending on `ifort`: **it is retired and not shipped from oneAPI 2025.0 onwards** (§2).
- ❌ Putting an `#ifdef` in a lowercase `.f90` file and trusting the compiler to preprocess it.
- ❌ Writing your own matrix multiplication in production instead of calling BLAS.
- ❌ Committing a code to multi-node coarrays without first verifying the support of the site's
  compiler (§6).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **The state of F2023 in your compiler, feature by feature** — **there is no "F2023 support" as a
   yes/no**: each vendor's table (Flang: `flang.llvm.org/docs/FortranStandardsSupport.html`,
   which warns that **the compiler's "Not Yet Implemented" messages win over its table**;
   Intel, its live F2023/OpenMP table; gfortran, the Fortran section of each GCC's release notes).
2. **GCC/gfortran** (as of Aug 2026: **16.1**, 2026-04-30; 15.3 and 14.4 current) and its Fortran
   news — **especially coarrays**, which changed in 16.1.
3. **Intel**: the state of `ifort` (retired; last 2024.2, out of the packages since 2025.0),
   the current version of `ifx` and the official `ifort`→`ifx` porting guide.
4. **NVIDIA HPC SDK** (as of Aug 2026: **26.5**, Jun 2026): the CUDA it bundles and OpenACC/OpenMP coverage.
5. **NAG**: version and **price** — **declared gap: NAG does not publish a public price list**
   (individual licence via the web shop, multi-user by quote; there was a price change in early
   2026). Nor could I confirm whether there is a release later than the **7.2** on their downloads page.
6. **fpm**: version (as of Aug 2026 **v0.13.0**, 2026-02-17), **the fact that it is still on 0.x**, and
   the **MIT licence verified by reading the raw `LICENSE`**.
7. **Progress of F202Y/"Fortran 2028"** in WG5/J3 (generics, standardised preprocessor): so as not to
   design against features that do not yet exist.
8. **CVEs** of MPI, HDF5, NetCDF, BLAS/LAPACK and of the compiler, and the licences of the libraries you
   link. **`hpc-standards` already exists**: **the criteria for cluster, Slurm, queues and scaling are
   theirs**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
