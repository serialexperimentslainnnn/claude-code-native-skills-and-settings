---
name: c-standards
description: C language engineering standards (staff-level). Trigger on .c files and C-only headers, -std=c11/c17/c23/gnu23, gcc/clang C invocations, Makefile/CMakeLists.txt/meson.build building C targets, compile_commands.json, .clang-tidy, .clang-format, cppcheck, -fanalyzer, -fsanitize=address/undefined/memory/thread, valgrind/memcheck, libFuzzer/AFL++/OSS-Fuzz harnesses, MISRA C or CERT C compliance, Unity/CMocka/Criterion tests, glibc/musl/newlib targets, _FORTIFY_SOURCE and binary hardening flags, or extern "C" ABI headers.
---

# C standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all work in C: `.c` files and C headers, choice of `-std=`, compiler and linker flags, `Makefile`/`CMakeLists.txt`/`meson.build` for C targets, `compile_commands.json`, sanitizer configuration, static analysis (`-fanalyzer`, clang-tidy, cppcheck), fuzzing, MISRA C / CERT C conformance, unit tests and hardening of the produced binary. Covers firmware/embedded, user-space drivers, system libraries, CLIs and high-performance code. It sets **criteria**: what is used, what is vetoed and what must be verified. It is not a C tutorial.

**Central axis of this skill**: in C the compiler manages neither resources nor bounds checking, so **the lifecycle of every resource and undefined behavior are design requirements**, not implementation details. Everything else (build, tests, CI) exists to make that discipline verifiable.

**Not applicable**: see `cpp-standards` (everything it decides about C++: RAII, templates, the C++ standard library, `new`/`delete`, exceptions, target-oriented CMake for C++ and the memory safety debate in the ISO C++ committee — **no** C++ here). **Arbitration criteria** for code that compiles in both: the **standard the target is compiled under** wins (`-std=c23` → this skill; `-std=c++23` → `cpp-standards`), **not** the file extension nor the code style; a header consumed from both worlds is designed under `c-standards` (C subset, no C++-only constructs) and its `extern "C"` wrapper is a shared boundary: the ABI guarantee is set by this skill, consumption from C++ is set by `cpp-standards`. See also `rust-standards` (language choice for **new systems code** — C is not the default by inertia — and the Rust side of the FFI: `bindgen`/`cbindgen`, `#[repr(C)]`, `unsafe`), `bash-linux-scripting-standards` (build scripts, wrappers and shell automation), `linux-hardening-standards` (hardening of the **system**: kernel, sysctl, MAC, systemd; hardening of the **binary** — RELRO, PIE, stack protector, CFI — belongs to this skill), `kernel-drivers-standards` (**reciprocity already declared from its §1: when a rule of this skill clashes with the kernel, the kernel wins** — there is no libc, there is no `malloc`, style and sanitizers are the tree's own), `appsec-standards` (threat modelling and the AppSec process), `vulnerability-management-standards` (CVE triage, patching SLA, VEX), `gpu-computing-standards` (CUDA/HIP, kernels and GPU toolchain), `cicd-standards` (pipeline design and gates; here only which tool runs and with which flags), `offensive-security-standards` (exploitation), `kubernetes-standards` (OCI image of the binary), `linux-storage-standards` and `observability-standards` for what belongs to them. Neighbouring languages: `zig-standards` (**already written**) for the modern alternative to C — **and for the special case of `zig cc`: using Zig as a cross-compilation toolchain is their decision, but the C it compiles remains subject to this skill**—, `nim-standards` (**already written**: Nim **generates C** and compiles it with a C compiler; the Nim is theirs, **the generated C and the flags it is compiled with fall here**), `lua-standards` (**already written**: the **Lua C API** —stack, `lua_State`, `luaL_*`, value lifecycle against the collector— is a shared boundary; the C of the native extension and its correctness belong to this skill, the contract with the interpreter is theirs), `assembly-standards` (**already written**) for inline assembly and intrinsics — **the `asm` inside a C function is a shared boundary**: the compiler constraint and the correctness of the `asm` are theirs, the rest of the function is ours—, `objective-c-standards` (**already written**: Objective-C is a superset of C, so **the C contained in a `.m` remains subject to this skill**; what is specific to the Objective-C runtime is theirs).

## 2. Default toolchain

> **Verify the latest version on the web before pinning it in a real project** (§8). The following is the state verified as of **Aug 2026**.

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Standard | **C17** (`-std=gnu17`) for portable production code; **C23** (`-std=gnu23`) if the project's minimum toolchain is GCC ≥ 15 / Clang ≥ 18 and there are no vendor compilers involved | C11 in legacy codebases or frozen vendor toolchains | GCC states *"GCC has support for ISO C23, the 2023 revision of the ISO C standard (published in 2024)"* and *"C23 mode is the default since GCC 15"*; Clang accepts `-std=c23` since Clang 18 but its C23 support is **partial, paper by paper** (see `clang.llvm.org/c_status.html`). C99 is the absolute minimum: **forbidden** C89/K&R in new code |
| Compiler | **GCC 16.x** (16.1, 2026-04-30) or **Clang/LLVM 22.x** (22.1.8, 2026-06-16) | Vendor toolchain when the silicon forces it | Compile **with both** in CI: each diagnoses what the other stays silent about |
| Build | **CMake ≥ 4.4** for libraries/projects others consume; **Meson ≥ 1.11** when the project is Linux-centric and readability is the priority | Make only in single-binary projects with no external dependencies | Hand-written Make does not scale to cross-compilation, sanitizer builds and `compile_commands.json` |
| Static analysis | `clang-tidy` (same release as the Clang in use) + `gcc -fanalyzer` | `cppcheck` 2.21.x (GPL-3.0) as a third opinion | `-fanalyzer` is the most mature **for C**: in C++ it is *best-effort*; in C it is usable as a gate |
| Tests | **Unity** 2.7.0 (MIT, 2026-07) in embedded and code without a full libc; **Criterion** 2.4.3 (2025-10) on Linux/POSIX when per-process isolation is wanted | CMocka 2.0.x when already in use (mocking by *link-time wrapping*) | Verify maintenance before pinning: the **CMocka mirror on GitHub is frozen at 1.1.5 (2019/2022)**; the authoritative source is `cmocka.org` / cryptomilk's git, which announces the 2.0 series |
| Fuzzing | **libFuzzer** for a fast in-process harness + **AFL++** 5.02c (2026-06) for long campaigns | Honggfuzz | libFuzzer is **deprecated in LLVM upstream** in the sense that it receives no new features: verify its state in the release notes of the specific version before basing a whole programme on it |
| Dynamic memory | The target libc's `malloc` | Custom allocator / arenas only with measured justification | A custom allocator shifts the burden of proof: it demands its own ASan+fuzzing |

Toolchain rules:
- **No implicit compiler flags**: the full compilation line lives in the build system and is versioned. `CFLAGS` injected by the environment are **appended**, not substituted.
- `compile_commands.json` always generated (`CMAKE_EXPORT_COMPILE_COMMANDS=ON` / Meson generates it by itself). Without it there is no clang-tidy, no clangd and no reproducible analysis.
- Cross-compilation via a versioned *toolchain file* (CMake) or *cross file* (Meson) — **forbidden** to detect the cross-compiler with ad-hoc conditionals.
- Minimum warning set, and **it is a gate**:

```
-std=gnu17 -Wall -Wextra -Werror
-Wshadow -Wconversion -Wsign-conversion -Wdouble-promotion
-Wformat=2 -Werror=format-security
-Wcast-qual -Wcast-align -Wpointer-arith -Wwrite-strings
-Wstrict-prototypes -Wold-style-definition -Wmissing-prototypes -Wmissing-declarations
-Wvla -Walloca -Wstack-protector
-Wnull-dereference -Wimplicit-fallthrough
-Werror=implicit-function-declaration -Werror=incompatible-pointer-types -Werror=int-conversion
```
- The four `-Werror=` on the last line are **non-negotiable**: in C17 and earlier those three constructs are diagnostics that many compilers accepted with a warning and are a direct source of memory corruption. C23 turns them into language errors; forcing them beforehand avoids the surprise on migration.
- `-Wconversion`/`-Wsign-conversion` are noisy in existing code: they are enabled **per new module** and extended from there; they are never switched off globally to "fix the build".
- `-Werror` **always in CI**; in the developer's local build it may stay as a warning so as not to break the flow, but merging requires the CI build.

## 3. Structure, conventions and resource lifecycle

### Layout
- `src/` implementation, `include/<project>/` public headers (always with a project directory: the consumer's `#include`s are `<project/foo.h>`), `tests/`, `fuzz/`, `cmake/` or `meson/`.
- **One public header = one contract**. Everything else is `static` or lives in internal headers outside `include/`. Visibility enforced in the linker: `-fvisibility=hidden` + an explicit export macro in shared libraries.
- Include guards `#pragma once` if every compiler in the project supports it; if there is a dubious vendor toolchain, classic guards with a unique name `PROJECT_MODULE_H`.
- Project prefix **mandatory** on every symbol with external linkage (`px_buffer_new`): C has no namespaces and the linker resolves collisions silently with absurd results.
- Public headers: types and functions only, zero unnecessary `#include`s (forward declaration where it suffices), zero unprefixed macros, and `extern "C"` guarded by `#ifdef __cplusplus` in every header a C++ consumer might include.

### Resource lifecycle — the axis of the language
- **Explicit ownership rule**: every pointer crossing an API boundary has documented in the header who frees it and with which function. Without that line, the API is incomplete.
- **Paired constructor/destructor per type**: `T *t_new(...)` / `void t_free(T *)`, and `t_free(NULL)` is a *no-op* (like `free`). Forbidden to spread the freeing across the caller field by field.
- **A single exit point for cleanup** in functions with several acquisitions: cascading `goto fail_*` pattern in reverse order. It is the correct idiom in C, not a forbidden *goto* — MISRA C:2025 **withdraws** the single-exit-point rule, but the project criteria remain: centralised cleanup, in reverse order.
- After freeing, **the pointer is nulled** in the owning structure (`p = NULL`) if its life continues: use-after-free becomes a null deref, which is a deterministic failure.
- **Ownership is not shared by default**. If sharing is needed, explicit refcount with the policy documented and a concurrency test; never "it gets freed at some point".
- `alloca` and VLAs: **forbidden** (`-Walloca -Wvla`). Stack size is a finite and uncheckable resource; a VLA with a size derived from input is a remote stack overflow.
- Buffers with input-derived size: check the calculation **before** multiplying (`__builtin_mul_overflow` / `ckd_mul` from `<stdckdint.h>` in C23), not afterwards.
- Closing descriptors and `FILE*`: same pattern as memory; check the return of `fclose`/`close` when there was a write (I/O errors show up there, not in `write`).

### Undefined behavior as a first-class bug
A UB is not "something that usually works": the optimiser **assumes it does not happen** and deletes the code that checks for it. It is treated as a high-severity defect even if the current binary works.
- Categories reviewed in every code review: out-of-bounds access, use-after-free/double-free, reading uninitialised memory, **signed** integer overflow, shift ≥ the type's width or with a negative operand, *strict aliasing* violation, misaligned pointers, `memcpy` with overlapping pointers (`memmove` is what applies), pointer arithmetic outside the object (including `ptr + n` beyond "one past the end"), comparison of pointers to distinct objects, division by zero, `NULL` passed to `<string.h>` functions even with length 0, and *data races*.
- The arithmetic ones are caught at runtime with UBSan; the aliasing ones are not: if the project does *type punning*, it is done with `memcpy` or with a union, **never** with a pointer cast, or it is compiled with `-fno-strict-aliasing` **declared and justified in the build** (a legitimate option, but a project decision, not a silent patch).
- `-fwrapv` / `-fno-strict-overflow` as a safety net in inherited codebases: acceptable and explicit, but it does not replace fixing the overflow; and it is not portable to vendor compilers.

### Integers
- `size_t` for sizes and indices; **never** `int` for lengths. Fixed-width types (`<stdint.h>`) for binary formats, protocols and hardware registers; `int`/`long` only for local arithmetic.
- **Implicit promotions and conversions** are the most frequent bug in the language: `-Wconversion -Wsign-conversion` enabled and zero casts "to silence the warning". A cast is an assertion that the range has been checked; if it has not, it is a bug wearing makeup.
- Comparing `signed` with `unsigned` is vetoed (`-Wsign-compare` comes with `-Wextra`); in C23 there is `<stdckdint.h>` (`ckd_add`/`ckd_sub`/`ckd_mul`) — verify real availability in the target's libc before depending on it; in C17, GCC/Clang's `__builtin_*_overflow`.
- **Signed** integer overflow **is UB**; unsigned overflow is defined but is usually just as much of a bug (size truncation). Both are checked.
- `char` without an explicit `signed`/`unsigned` has *implementation-defined* signedness: for bytes, `uint8_t` or `unsigned char`.

### Forbidden functions and their real replacement
| ❌ Forbidden | Replacement | Note |
|---|---|---|
| `gets` | `fgets` + check the `\n` | Removed from the language since C11 |
| `strcpy`, `strcat` | Explicit checked length: measure and `memcpy`; `snprintf` for composition | `strncpy` is **not** the replacement: it does not guarantee termination |
| `strncpy` | `snprintf`, or `memcpy` with manual termination | Pads with zeros and truncates without warning |
| `sprintf`, `vsprintf` | `snprintf`/`vsnprintf` **checking the return** (`>= size` is truncation, and truncating is usually a logic bug) | |
| `atoi`, `atol`, `atof` | `strtol`/`strtoll`/`strtod` with `errno` set to 0 beforehand and `endptr` checked | `atoi` does not distinguish error from zero: UB on overflow |
| `alloca`, VLA | `malloc` + limit, or a fixed sized buffer | |
| `rand`, `random` | The OS CSPRNG (`getrandom`, `arc4random_buf`, `BCryptGenRandom`) for any security use | |
| `system`, `popen` with a composed string | `posix_spawn`/`fork`+`execve` with a vectorised `argv` | Concatenating input into a command is injection |
| `strtok` | `strtok_r`/`strsep` | Global state: not reentrant |
| `gmtime`, `localtime`, `ctime`, `asctime` | The `_r` variants | Shared static buffer |
| `memcpy` over overlapping regions | `memmove` | UB even when it "works" |
| `scanf("%s")` | `fgets` + parsing, or `%<n>s` with a width | |
| Annex K (`strcpy_s`, `_s`) | Do not adopt it as a strategy | Real support is almost non-existent outside MSVC and questioned by WG14: it is **not** the portable solution |

Mechanical enforcement: a list of vetoed symbols in clang-tidy (`bugprone-unsafe-functions`, `cert-*`) and, in high-assurance projects, `--defsym`/wrap or a linker check on the imported symbol.

### Concurrency
- One threading model per project: `pthreads` on POSIX or C11 threads (`<threads.h>`) if the toolchain really has them (verify: glibc exposes them since 2.28; some libcs do not). **Do not mix**.
- Every shared variable is protected by a mutex or is `_Atomic` with an **explicit and justified** memory order; `volatile` is **not** a concurrency primitive (it is for MMIO and `sig_atomic_t`, nothing more).
- Lock acquisition order documented and global; no nested locks without a hierarchy.
- Signal handlers: only *async-signal-safe* functions and `volatile sig_atomic_t`; the correct pattern is to write to a pipe/eventfd (*self-pipe*) and process it in the main loop.
- Data race = UB. TSan is the gate.

## 4. Quality: formatting, analysis, tests and CI gates

### Formatting
- `clang-format` with a versioned `.clang-format` (LLVM or GNU base, tuned once and not re-debated). `clang-format --dry-run --Werror` in CI.
- **Forbidden** to reformat en masse alongside functional changes: the formatting commit goes separately and is recorded in `.git-blame-ignore-revs`.

### Static analysis (in order of increasing cost)
1. Compiler warnings with `-Werror` (already covered, zero cost).
2. `gcc -fanalyzer` over the C tree: catches double free, use-after-free, leaks, NULL derefs and descriptor misuse. Noisy in macros; it gets triaged, not switched off. *(Verified state: its C++ support is incomplete/best-effort — irrelevant here, this is the C skill.)*
3. `clang-tidy` with a versioned `.clang-tidy`. Starting set: `bugprone-*`, `cert-*`, `clang-analyzer-*`, `misc-*`, `performance-*`, `portability-*`, `readability-*` (trimming the style ones that clash with clang-format), and `-checks=-readability-magic-numbers` only if the project has its own constants policy. `WarningsAsErrors` for the stabilised part.
4. `cppcheck --enable=warning,style,performance,portability --error-exitcode=1` with versioned suppressions (`suppressions.txt`) — a third opinion, a different family of heuristics. Verify the current licence before pinning it as a corporate default (as of Aug 2026 the open project is GPL-3.0 and there is also a commercial *Premium* edition: they are different products).
5. **CodeQL** in the repo (or the provider's equivalent) for data-flow queries across translation units, scheduled as well as on PR.

No `// NOLINT` without a specific lint and a reason; no `#pragma GCC diagnostic ignored` without `push`/`pop` and a comment.

### Sanitizers (separate builds, never a single one "with everything")
- **ASan + UBSan + LSan** in the same build: `-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all -g -O1`. LSan comes with ASan on Linux. This is the default test build in CI.
- **TSan** in a **separate** build: `-fsanitize=thread`. **Incompatible with ASan**: the runtimes assume different memory maps and the compiler emits a hard error when combining them. It implies PIE and requires instrumenting all the code.
- **MSan** in a **separate** build and Clang/Linux only (`-fsanitize=memory -fPIE -pie -fno-omit-frame-pointer -fno-optimize-sibling-calls -O1`). It requires **all** dependencies, including libc++/libc as the case may be, to be instrumented: without that it produces false positives. If that cost is not bearable, coverage of uninitialised memory reads is covered with **Valgrind Memcheck**, which remains the practicable route in that gap.
- `-fno-sanitize-recover=all` mandatory: a finding must **abort** the test, not print and continue. `UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1`, `ASAN_OPTIONS=detect_stack_use_after_return=1:strict_string_checks=1:detect_leaks=1`.
- **Valgrind still has its place**, and for concrete reasons, not out of nostalgia: it works on **already compiled** binaries (third-party code, blobs, already-published artifacts) and covers uninitialised memory without recompiling the world. In exchange it does not see overflows in local or global variables nor *use-after-return*, and its cost is an order of magnitude over ASan. Criteria: ASan+UBSan on every PR, TSan in a separate job, Valgrind on a periodic run or to triage a binary that cannot be recompiled.
- Production is **never** deployed with sanitizers active (they are debugging tools and they widen the attack surface: `ASAN_OPTIONS` is read from the environment).

### Fuzzing
- **Every parser, decoder, deserialiser or untrusted input entry point has a fuzzing harness**. It is not optional: it is where the bugs appear that the fuzzer finds in minutes and human review does not see in years.
- `LLVMFuzzerTestOneInput` harness (compatible with libFuzzer and AFL++ via `afl-clang-lto`), compiled with ASan+UBSan, **versioned** and minimised corpus (`-merge=1`), dictionary when the format has one.
- CI: a short run (60–300 s) of the corpus on every PR as a regression test; a long scheduled campaign (nightly/weekly) with AFL++.
- Relevant open source project: integrate it into **OSS-Fuzz** (Google, active — daily commits as of Aug 2026). Every *crash* reported by the fuzzer enters as a bug with a regression test in the corpus.
- The fuzzed binary is **not** the release binary: different builds.

### Testing
- Framework as per §2; each test is an isolated case, with no shared global state, and the runner reports in a CI-consumable format (TAP/JUnit).
- Mandatory coverage of **edges and errors**, not the happy path: length 0, maximum length, `NULL`, boundary values of each integer type, `malloc` failure (fault injection via wrapper or `LD_PRELOAD`), truncation, unterminated input.
- **Every fixed bug leaves a regression test** that fails before the fix; if it came from a fuzzer, it also enters the corpus.
- Coverage as a signal: `--coverage`/`llvm-cov` published, focused on error branches. A percentage is not a target.
- Deterministic tests: no dependence on timing, hash order or the network. A flaky test is fixed or deleted.

### Minimum CI gate (everything breaks the build)
```
1. clang-format --dry-run --Werror
2. build GCC   -Wall -Wextra -Werror (+ set from §2)
3. build Clang -Wall -Wextra -Werror (+ set from §2)
4. clang-tidy over compile_commands.json (diff or whole tree)
5. gcc -fanalyzer
6. tests under ASan+UBSan (-fno-sanitize-recover=all)
7. tests under TSan (separate job, if there are threads)
8. short fuzz corpus over each harness
9. dependency SCA + SBOM of the artifact
10. clean release build with the hardening flags from §5 and verification of the binary
```
Main always green. Nothing is merged with CI red.

## 5. Stack security and binary hardening

### Hardening flags (release build)
Base aligned with the *OpenSSF Compiler Options Hardening Guide for C and C++* (a living document: re-verify before freezing it in a project):

```
-O2 -Wall -Wformat -Wformat=2 -Wconversion -Wimplicit-fallthrough
-Werror=format-security
-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3
-fstrict-flex-arrays=3
-fstack-clash-protection -fstack-protector-strong
-fPIE -pie
-Wl,-z,relro -Wl,-z,now
-Wl,-z,noexecstack -Wl,-z,nodlopen
-Wl,--as-needed -Wl,--no-copy-dt-needed-entries
```
- `-U_FORTIFY_SOURCE` before `-D_FORTIFY_SOURCE=3` **matters**: many distros already define it and redefining it without undefining warns or is ignored. `_FORTIFY_SOURCE` requires `-O1` or higher and depends on the libc (glibc implements it; on musl it is essentially inoperative — **verify on the real target**, do not assume it).
- **Also add** (with impact measurement):
  - `-ftrivial-auto-var-init=zero`: eliminates the whole class of "reading an uninitialised local" in production. Low cost; verify support in the project's specific GCC/Clang version.
  - `-fcf-protection=full` (x86-64) and `-mbranch-protection=standard` (AArch64) for hardware CFI.
  - `-fsanitize=cfi` with LTO (Clang) or `-fsanitize=undefined -fsanitize-minimal-runtime -fsanitize-trap=undefined` as a minimal-cost UBSan **in production** to turn detectable UB into a deterministic *trap* — a project decision, measure first.
  - `-fno-delete-null-pointer-checks` and `-fno-strict-aliasing` in inherited codebases whose correctness cannot be fully audited (declared and justified).
- **Verify the produced binary**, do not trust the flags: `checksec`, `hardening-check` or `readelf -d` in CI, checking PIE, full RELRO, NX, stack canary and the absence of unsafe `RPATH`/`RUNPATH`. A flag being in `CFLAGS` does not mean it reached the link.
- Symbol strip on the release artifact, with **build-id and debug symbols archived separately** (`objcopy --only-keep-debug`) so crashes can be symbolised.

### Supply chain and dependencies
- **Every C dependency is code that will run with the process's privileges**: it is justified in writing. Prefer the libc and what is already present over adding a library for one utility.
- Dependencies by exact *pin* (tag + hash), never `master`. Vendoring (submodule/subproject with a pinned revision) is acceptable and often preferable to a package manager in C; what is not acceptable is copying code without a record of origin, version and licence.
- **SBOM** (SPDX or CycloneDX) generated in the build and published with the artifact; SCA against CVEs of the embedded libraries. Vendored code is exactly where CVEs get lost.
- Licences verified in the project's real `LICENSE`, not in whatever an aggregator says.

### Code
- **All external input is validated at the boundary** (length, range, termination, encoding) before touching the rest of the programme. A binary format parser always assumes hostile input.
- Check **every** return: `malloc`, `realloc` (never `p = realloc(p, n)` — the original pointer is lost if it fails), `snprintf`, `read`/`write` (partials), `fclose`. Ignoring a return is a decision that gets marked (`(void)` + comment), not an oversight.
- Secrets: never in code or in logs; erase sensitive material with `explicit_bzero`/`memset_explicit` (C23) — a normal `memset` gets removed by the optimiser. Consider `mlock` for keys and prevent them reaching *core dumps* (`prctl(PR_SET_DUMPABLE, 0)` where applicable).
- Crypto: use an audited library (libsodium, OpenSSL 3.x, BoringSSL/mbedTLS depending on the target). **No rolling your own crypto**, nor comparing secrets with `memcmp` (constant time: `sodium_memcmp`/`CRYPTO_memcmp`).
- Path and file comparison: `openat`/`O_NOFOLLOW`/`O_CLOEXEC` and temporary files with `mkstemp`; no check-then-open (TOCTOU).
- `O_CLOEXEC`/`SOCK_CLOEXEC` by default on every descriptor: leaking descriptors to child processes is a silent escalation.

### MISRA C and CERT C — when they apply
- **CERT C**: applicable to any C project with a security surface; its rules overlap with clang-tidy `cert-*`. It is adopted as a set of automated checks, not as a document to read.
- **MISRA C**: mandatory only when the domain requires it (automotive/ISO 26262, IEC 61508, avionics/DO-178C, medical devices/IEC 62304). Current edition verified: **MISRA C:2025** (published March 2025), successor to MISRA C:2023; covers C90/C99/C11/C18, ~225 active guidelines, and **withdraws** the historical single-exit-point rule (although IEC 61508 / ISO 26262 may still require similar practices on their own). It treats AI-generated code the same as hand-written code for conformance purposes.
- MISRA requires **MISRA Compliance:2020** as its framework: guideline matrix, documented and approved deviations, and evidence. Adopting MISRA "in name" without that framework is not conformance, it is theatre.
- **Do not** apply MISRA to a project that does not need it: it penalises legitimate constructs and consumes review budget that pays off better in sanitizers and fuzzing.

## 6. Performance, ABI, portability and operability

### Performance
- Measure before optimising: `perf`, `flamegraph`, `cachegrind`. A performance change with no measured before/after number does not get merged.
- Reproducible benchmarks (fixed frequency, CPU *pinning*, several repetitions with reported spread); no comparing timings from a single run.
- `-O2` is the default; `-O3` only if the benchmark justifies it on that specific binary. `-march=native` **forbidden** in distributable artifacts (it produces binaries that fail with SIGILL on another machine); *runtime dispatch* or *function multiversioning* if AVX-512 is needed.
- LTO (`-flto=thin` on Clang, `-flto` on GCC) by default in release if build time allows; verify that it does not break with alias symbols/`__attribute__((used))`.
- Hand micro-optimisations are the last resort; the 2026 compiler wins almost always. The real gain is in the algorithm and in the memory access pattern.

### ABI and interoperability
- **The ABI is a contract**: changing the size or layout of a public struct, the order of an enum, the prototype of an exported function or the *calling convention* is a **breaking change** even if the API compiles.
- Shared libraries: versioned `SONAME`, `-fvisibility=hidden` + export macro, and a **version script** (`--version-script`) to control the exported set. `abi-compliance-checker` or `abidiff` (libabigail) in the CI of libraries with an ABI contract.
- Public structs: prefer **opaque types** (`typedef struct px_ctx px_ctx;`) so they can evolve without breaking the ABI. If the struct must be public, no fields are added in the middle and the padding is documented.
- FFI: the C boundary is the lowest common denominator for Rust/Python/Go/C++. Rules: no platform-dependent types in the signature (use `<stdint.h>`), fixed-size integers, ownership documented on every parameter, **no propagating `errno` as a contract** across languages, and a `*_free` function exported for every object the library returns (the consumer cannot call another libc's `free` — on Windows it is a straight failure).
- Consumption from C++: header with `#ifdef __cplusplus extern "C" {`, no `bool` from `<stdbool.h>` in the signature if old compilers are involved, no *flexible array members* in types C++ must define, and no names that are reserved words in C++ (`class`, `new`, `template`, `operator`...). The C++ side of the contract is set by `cpp-standards`.

### Portability
- Explicitly declare the set of supported targets (architecture, libc, OS, compiler and minimum version) in the README **and test them in CI**. What is not tested is not supported.
- Assume: `char` may be signed or unsigned; integers may be 32 or 64 bits (`long` is 32 on Windows and 64 on Linux — use `<stdint.h>`); byte order varies; misaligned accesses abort on some architectures; the evaluation order of a function's arguments is unspecified.
- Feature test macros (`_POSIX_C_SOURCE`, `_GNU_SOURCE`) defined in the build system, not scattered across the `.c` files.
- No dependence on the behaviour of a specific compiler version; `__builtin_*` and `__attribute__` are wrapped in macros with a fallback.

### Operability
- Structured logging to `stderr` (or syslog/journald depending on the deployment) with a configurable level; **no debug `printf`** in production code.
- Exit codes with meaning; errors via `errno`-like or a documented custom enum — never magic codes without a table.
- Clean exit on SIGTERM/SIGINT: *self-pipe*, draining of work in progress, resource release. A daemon that only dies by SIGKILL is not deployable with a rolling update.
- Crashes: `build-id`, archived symbols, `core_pattern`/coredumpctl or a crash collector; a crash without a symbolisable trace is wasted time.
- `assert` is not error handling and **disappears with `NDEBUG`**: never put side effects inside it, nor use it to validate external input. For invariants that must hold in release, an explicit check with `abort()` or a `static_assert` (C11+) if it is compile-time.

## 7. Sustainability: upgrades and prohibitions

**Cadence**: upgrade the compiler at least once a year (GCC publishes one major annually, ~April; LLVM every ~6 months) and test the next one in CI **before** it becomes mandatory — a three-version jump accumulates new warnings and optimisation changes that expose latent UB. A new failure after a compiler upgrade is, by default, your own bug, not a compiler regression. Language standard: review the migration to C23 when the project's minimum toolchain allows it; C2y/C29 (working draft in progress, publication expected at the end of the decade) is **not** used in production.

**Deprecation**: in libraries with an ABI contract, deprecate with `__attribute__((deprecated("use X")))`, a window of at least one major version, and a new `SONAME` when the ABI breaks. In internal binaries, compatibility flags are not accumulated "just in case".

**Conscious debt**: every shortcut leaves `/* TODO(user): reason — issue #N */`. Every lint/sanitizer suppression comes with a reason and a review date.

**FORBIDDEN** (requires written justification and approval to make an exception):
- ❌ The functions in the §3 table (`gets`, `strcpy`, `strcat`, `strncpy`, `sprintf`, `atoi`, `alloca`, `strtok`, `rand` for security, `system` with a composed string...).
- ❌ VLAs and `alloca` with an input-derived size; stack buffers sized "with margin".
- ❌ Ignoring the return of `malloc`/`realloc`/`snprintf`/`read`/`write`/`fclose`; `p = realloc(p, n)`.
- ❌ Pointer casts for *type punning* (strict aliasing violation); casts to silence `-Wconversion`.
- ❌ `-Werror` disabled in CI; `#pragma GCC diagnostic ignored` without `push`/`pop` and a reason; `// NOLINT` without a specific lint.
- ❌ Combining ASan with TSan/MSan in the same build (the compiler rejects it); deploying production with sanitizers.
- ❌ `-march=native` in distributable artifacts; `-O3` without a benchmark; `-ffast-math` in code that compares or validates floats.
- ❌ `volatile` as a synchronisation mechanism between threads; shared global variables without a lock or `_Atomic`.
- ❌ Pointer arithmetic outside the object; comparing pointers of distinct objects; `memcpy` with overlap.
- ❌ Public headers without a project prefix, without an include guard or dragging in unnecessary `#include`s; external symbols without a prefix.
- ❌ Mutable global state in libraries (breaks reentrancy and tests); functions with a static return buffer.
- ❌ Macros that do what a `static inline` function would do; multi-statement macros without `do { } while (0)`; macros that evaluate an argument twice.
- ❌ Home-made crypto, comparing secrets with `memcmp`, `memset` to erase secrets.
- ❌ Copying third-party code without a record of origin, version and licence; dependencies pointing at a branch instead of at tag+hash.
- ❌ An untrusted input parser **without a fuzzing harness**.
- ❌ Annex K (`*_s`) as a portability strategy.
- ❌ Declaring "it's only a warning": a compiler warning in C is a bug until proven otherwise.
- ❌ **Including in this skill or in the code it produces: exploits, ROP gadgets, concrete mitigation bypasses, shellcode or payloads.** This skill is **defensive**: it describes vulnerability classes (overflow, use-after-free, format string, TOCTOU, type confusion) **in order to prevent them**, never to exploit them. Offensive work → `offensive-security-standards`, with written scope and authorisation.

## 8. Mandatory web verification

Before pinning versions, flags or asserting the state of the ecosystem, **verify on the web** (never from memory):
1. **Real C23 state per compiler**: https://gcc.gnu.org/projects/c-status.html and https://clang.llvm.org/c_status.html (paper-by-paper table). Do not assume parity between GCC and Clang: as of Aug 2026 GCC declares C23 support and default since GCC 15; Clang accepts `-std=c23` since 18 with **partial** support.
2. **Versions and lifecycle**: https://gcc.gnu.org/develop.html + https://gcc.gnu.org/releases.html (GCC publishes no formal EOL table: it maintains ~3 branches and closes the oldest after a final release — **a datum to confirm each time**), LLVM releases via `https://github.com/llvm/llvm-project/releases.atom`, and the MSVC notes if the project supports it.
3. **Real support in the target libc** for whatever is used from C23 (`<stdckdint.h>`, `memset_explicit`, `<threads.h>`) — glibc, musl and newlib are **not** at the same level; check in the libc documentation, not the compiler's.
4. **OpenSSF Compiler Options Hardening Guide** (living document, it changes): https://best.openssf.org/Compiler-Hardening-Guides/ — reread before freezing the flag set.
5. **Maintenance state and licence** of every tool before pinning it as a default: precedents in the catalogue (Trivy changed licence; gitleaks declared itself *feature complete* and its action requires a commercial licence for organisations since v2). Check via the releases Atom feed (`/releases.atom`) and via the raw `LICENSE` from `raw.githubusercontent.com`, not via what an aggregator says. Special attention to: **CMocka** (GitHub mirror frozen; real source `cmocka.org`), **cppcheck** (open source GPL-3.0 vs. commercial *Premium* edition) and **libFuzzer** (no active feature development in LLVM).
6. **MISRA**: current edition and addenda at https://misra.org.uk/publications/ (verified: MISRA C:2025, March 2025). Verify which edition the contracted analysis tool actually supports — it usually lags behind.
7. **CERT C**: the SEI's official wiki for the specific rule before citing it as a standard.
8. **Sanitizers**: the supported combinations and the exact flags change between releases — Clang/GCC documentation for the version in use, not articles.

**Declared gaps (not verified as of Aug 2026, verify before using as a standard)**:
- Version and support state of **MSVC** for C (its C frontend has lagged far behind on C11/C17/C23): **not verified**.
- Formal EOL dates of the GCC 14/15/16 branches and of the LLVM releases: **not verified** (GCC publishes no EOL table; the ~3 active branches pattern is description, not commitment).
- Exact state of `-ftrivial-auto-var-init=zero` and of `-fsanitize=cfi` in the project's specific GCC/Clang version: **not verified per version**.
- Verbatim licences of Criterion, CMocka and GSL/other dependencies mentioned in passing: **not verified verbatim** (Unity → MIT is, verified in its `LICENSE.txt`; cppcheck → GPL-3.0 according to the project, confirm in the file).
- Real C23 coverage in each target's libc (glibc/musl/newlib): **not verified**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
