---
name: cpp-standards
description: Modern C++ engineering standards (staff-level). Trigger on .cpp/.cc/.cxx/.hpp/.ixx/.cppm files, -std=c++17/20/23/2c or /std:c++latest, CMakeLists.txt with add_library/target_link_libraries, CMakePresets.json, vcpkg.json, conanfile.py/conanfile.txt, .clang-tidy with cppcoreguidelines-* checks, GoogleTest/Catch2/doctest suites, Google Benchmark, std::unique_ptr/shared_ptr/move semantics/concepts/constexpr/ranges/coroutines/std::expected, C++ modules and import std, Boost or Abseil usage, the C++ Core Guidelines and GSL, or C++ memory-safety profiles and hardened standard library decisions.
---

# C++ standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all C++ work: `.cpp`/`.cc`/`.cxx`/`.hpp`/`.h` C++ files, module interfaces (`.ixx`/`.cppm`), the choice of `-std=`/`/std:`, `CMakeLists.txt` and `CMakePresets.json` of C++ targets, `vcpkg.json`, `conanfile.py`, `.clang-tidy`, GoogleTest/Catch2/doctest suites, benchmarks, and the language's design decisions (ownership, templates, `constexpr`, coroutines, error handling).

**Central axis**: **modern C++ is not "C with classes"**. The difference is not cosmetic: in C++ the correctness of resources is expressed in the **type system** (RAII, ownership, `const`, move, concepts), which in C is delegated to human discipline. C++ code that manages memory by hand with `new`/`delete`, passes raw pointers with implicit ownership, uses C arrays and `#define` instead of `constexpr`, or returns integer error codes, **is not badly written C++: it is misplaced C**, and it is reviewed as a design defect, not as a matter of style.

**Not applicable**: see `c-standards` (everything that decides on pure C: `-std=c23`, forbidden libc functions, MISRA C/CERT C, `-fanalyzer`, layout and guarantees of C headers, hardening of the C binary, and the **design** of the `extern "C"` header). Reciprocal **arbitration criterion** for code that compiles in both languages: the **standard the target is compiled under** wins (`-std=c++23` → this skill; `-std=c23` → `c-standards`), **not** the extension or the style. The `extern "C"` boundary is shared: `c-standards` sets the ABI contract and the shape of the header; **this skill sets the C++ side**: wrap the C resource in RAII at the same point where it is acquired (never leave a raw `FILE*`/handle circulating through C++ code), `noexcept` on callbacks invoked from C (an exception crossing a C boundary is UB), and a prohibition on exposing C++ types (`std::string`, templates, exceptions) across the boundary. See also `rust-standards` (language choice for **new components** when the memory safety answer is to change language, and the Rust side of the FFI: `cxx`, `bindgen`, `#[repr(C)]`), `bash-linux-scripting-standards` (build scripts), `linux-hardening-standards` (hardening of the **system**; that of the **binary** belongs to this skill), `appsec-standards` (threat modelling and process), `vulnerability-management-standards` (CVE triage and patching SLA), `gpu-computing-standards` (CUDA/HIP, kernels, GPU toolchain), `cicd-standards` (pipeline design and gates; here only the tool and its flags), `offensive-security-standards` (exploitation), `kubernetes-standards` (OCI packaging), `observability-standards` (OTel pipeline). Neighbouring languages: `zig-standards` and `nim-standards` (**already written**; Nim can emit C++ with `nim cpp`: the Nim is theirs, **the generated C++ and its flags fall here**), `assembly-standards` (**already written**; inline `asm` inside a C++ function is a shared boundary), `objective-c-standards` (**already written**, for Objective-C++ on Apple platforms: **the C++ contained in a `.mm` remains subject to this skill**).

## 2. Toolchain and default decisions

> **Verify the latest version on the web before pinning it in a real project** (§8). What follows is the state verified as of **Aug 2026**.

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Standard | **C++20** (`-std=c++20`) as the production base; **C++23** (`-std=c++23`) if the project's three compilers really support it | C++17 in codebases with a frozen toolchain or vendor SDKs | GCC 16.1 (2026-04-30) **changed the C++ frontend default to GNU C++20** and stopped marking the corresponding library parts as experimental; the C++20 ABI was not stable until GCC 16 — a decisive datum if binaries are mixed |
| C++26 | **Not in production yet**; yes for prototyping specific features with `-std=c++2c` | — | Technical work **completed on 28-29 March 2026** at the London (Croydon) meeting and sent to DIS ballot; GCC 16.1 supports most features. Real availability is uneven: e.g. **contracts in GCC 16.1 only emit warnings**, and in MSVC they are on the roadmap |
| Compiler | **GCC 16.x** + **Clang/LLVM 22.x** (22.1.8, 2026-06-16; the 23 series was in rc as of Jul 2026) in CI, both | MSVC when Windows is a first-class target | Compiling with two different frontends is the cheapest static analysis in existence |
| MSVC | **Build Tools 14.51** (compiler 19.51, VS 2026 v18.6, toolset v145) | 14.50 (VS 2026 v18.0) | **`/std:c++23` is not a final switch yet**: you use `/std:c++23preview` (only ratified features) or `/std:c++latest` (also in-progress/experimental C++26 ones). Full `/std:c++23` support arrives when 14.52 is the non-preview default. Servicing of 14.51: 9 months. Binary compatibility preserved since VS 2015 |
| Build | **CMake ≥ 4.4** (4.4.2, 2026-07-31) with `CMakePresets.json` | Meson in Linux-centric projects; Bazel in monorepos that already use it | CMake is the real common denominator of the C++ ecosystem |
| Dependency manager | See the reasoned decision below (**vcpkg** vs **Conan 2**) | `FetchContent`/subdirectories only in projects with ≤3 dependencies | |
| Tests | **GoogleTest 1.17.0** (BSD-3-Clause) if you need *mocking* (GMock) or the Google ecosystem; **Catch2 v3.15.x** (BSL-1.0, active Jul 2026) for expressive tests without a heavy dependency | **doctest v2.5.x** (MIT) when test compilation time rules (tests inside the production TU itself) | Verify maintenance: googletest **has not published a release since 1.17.0 (2025-04-30)** although the repo is still alive (*live at head* model); Catch2 and doctest published in Jul 2026 |
| Benchmarks | **Google Benchmark 1.9.5** (Apache-2.0, 2026-01) | nanobench in small projects | |
| Utilities outside the stdlib | **Abseil** (Apache-2.0, LTS of May 2026) when gRPC/protobuf is already in use | **Boost 1.91.0** (BSL-1.0) for what the stdlib does not cover (Asio if `std::execution` is not adopted, Beast, Spirit) | Hard rule: **the stdlib first**; a dependency only gets in if the stdlib does not cover the case or its available implementation does not |
| GSL | **microsoft/GSL 4.2.2** (MIT, 2026-05) only if the Core Guidelines are adopted with verification | — | In C++20+ much of the GSL is subsumed by `std::span`, `std::byte`, `<concepts>` and `[[nodiscard]]`: adopting the whole GSL is today the exception, not the default |

### vcpkg vs Conan 2 — reasoned decision
- **vcpkg** (Microsoft): a flat registry with a version *baseline*, manifest mode (`vcpkg.json`) and a CMake toolchain file; a larger catalogue and a better chance of finding obscure libraries. The **triplet** system forces rebuilds when the configuration does not match exactly; binary cache preferably over NuGet *feeds* (also a local on-disk cache). Releases with a date-based scheme (last verified: `2026-07-29`).
- **Conan 2** (2.31.1, 2026-07-24): dependency resolution **by graph** with version ranges and multiple remotes, `conanfile.py`/`conanfile.txt`, `conan lock create` for explicit lockfiles and **profiles** that pin the compiler and settings — which reduces unnecessary rebuilds and makes cross-compilation more manageable. Binary cache designed for Artifactory.
- **Criteria**: a project centred on Windows/MSVC or that needs uncommon libraries → **vcpkg**. A cross-platform project, with cross-compilation or embedded, or that already has Artifactory → **Conan 2**. **One manager per project**, documented; in both cases **pinned versions** (baseline + `vcpkg-configuration.json`, or a Conan lockfile) and consumption from CMake via `find_package`, so that the build does not depend on the specific manager.
- **Conan 1 is out of the discussion**: any new project is born on Conan 2; a codebase on Conan 1 has the migration as dated debt.

## 3. Structure, ownership and design

### Modern CMake — targets, not global variables
- Everything is expressed as **target properties**: `target_include_directories`, `target_compile_features`, `target_compile_options`, `target_link_libraries`, `target_compile_definitions`, with `PUBLIC`/`PRIVATE`/`INTERFACE` **always explicit** (the library's usability depends on it). **Forbidden**: `include_directories`, `link_libraries`, `add_definitions`, and modifying `CMAKE_CXX_FLAGS` globally.
- `cmake_minimum_required(VERSION 3.28)` as a reasonable floor (raise it if modules or `import std` are used), targets with a **namespace** (`add_library(px::core ALIAS px_core)`) so the consumer does not distinguish between a subdirectory and an installed package.
- Standard per target: `target_compile_features(px_core PUBLIC cxx_std_20)`; a global `set(CMAKE_CXX_STANDARD ...)` as the only source is **forbidden**. `CXX_EXTENSIONS OFF`.
- `CMakePresets.json` versioned with `debug`, `release`, `asan-ubsan`, `tsan` presets: the compilation line is not transmitted by oral tradition.
- Export an installable package (`install(TARGETS ... EXPORT)`, `*Config.cmake`, `write_basic_package_version_file`) in every library others consume.
- **Forbidden**: `file(GLOB)` to list sources: it breaks incremental rebuilding silently.

### Layout
- `include/<project>/` public headers, `src/` implementation and internal headers, `tests/`, `bench/`, `cmake/`. Project namespace mandatory; anonymous namespace for everything internal to a TU.
- **Forbidden**: `using namespace` in headers, in any case; in `.cpp`, only local to a function and with justification (`using std::swap` for ADL, yes).
- Headers: `#pragma once`, minimal includes (forward declaration where it suffices), and `<...>` for external dependencies / `"..."` for your own. IWYU (`include-what-you-use`) as a periodic check, not as a mandatory gate (it is noisy).
- Minimal and stable public API: the implementation goes in `src/` or in `detail::`; `detail` is not API and is documented as such.

### RAII and ownership — the guiding principle
- **Every resource has an owner and its release is in a destructor.** Memory, files, sockets, locks, OS handles, transactions, timers. If a third-party resource does not come with an RAII class, you write a wrapper for it before using it, not after.
- **Ownership is expressed in the type in the signature**, and this is not negotiable:
  - `std::unique_ptr<T>` — exclusive, transferable ownership. It is the default.
  - `std::shared_ptr<T>` — **genuinely shared** ownership, with a lifetime undetermined at compile time. It requires written justification: it is an atomic counter, it is cost, and it usually indicates an unresolved ownership design.
  - `std::weak_ptr<T>` — to break `shared_ptr` cycles; its presence obliges you to document the cycle.
  - `T&` / `const T&` / raw `T*` / `std::span<T>` / `std::string_view` — **observation without ownership**, with lifetime guaranteed by the caller. A raw pointer in a signature means "I am not the owner", never anything else.
- **When NOT to use smart pointers**: when the object is a value (`std::string`, `std::vector`, your own type with value semantics) — `unique_ptr<std::string>` is almost always a design error; when the object is a member by value of its owner; when it is an observer (there go a reference, `span`, `string_view` or a raw pointer); when the lifetime is block scoped; when it is a polymorphic object stored in a container of values via `std::variant`. `shared_ptr` **never** as "the default pointer because it is convenient".
- `std::make_unique`/`std::make_shared` instead of `new` (`make_shared` combines the allocation; careful if there are long-lived `weak_ptr`s over large objects: it keeps the block alive). **Explicit `new` and `delete` are forbidden** outside the implementation of an RAII wrapper, an allocator or an arena, with a comment justifying it.
- Lifetimes: never return a `string_view`/`span`/reference to a temporary or to a member of an object that dies; careful with `for (auto x : f().items())` when `f()` returns by value (lifetime extension only of the outer temporary — fixed in C++23 for range-for, verify the target's standard). `-Wdangling` and `clang-tidy bugprone-dangling-handle` enabled.
- Resources shared between threads and their lifetime are a design problem, not a `shared_ptr` problem: `shared_ptr` is *thread-safe* in the counter, **not** in the pointed-to object.

### Move semantics and the rules of zero/three/five
- **Rule of zero**: most classes declare no destructor, no copy and no move — their members are types that already handle it. It is the default goal.
- If **one** of {destructor, copy-ctor, copy-assignment, move-ctor, move-assignment} is declared, you decide explicitly about **all five** (`= default`/`= delete`/definition). Declaring a destructor **suppresses** the generated moves and silently turns moves into copies: it is an invisible performance regression.
- Move-ctor and move-assignment **`noexcept`** whenever possible: without `noexcept`, `std::vector` copies instead of moving when reallocating.
- A moved-from object is left in a **valid but unspecified** state: you may only destroy it or reassign it, unless the class documents more. No reusing a moved-from object "because it works in this implementation".
- `std::move` over a `const` does not move (it copies silently); `std::move` in the `return` of a local variable **prevents NRVO** — do not write it. `std::forward` only on forwarding references.
- Parameters: by value + `std::move` when it is going to be stored (sink rule); by `const&` when it is only read; by `&&` only in deliberate overloads. Avoid the proliferation of `const&`/`&&` overloads without measurement.

### `const`-correctness and types
- `const` by default in local variables, read-only parameters and methods that do not mutate observable state. `constexpr`/`consteval` where the value is known at compile time. `mutable` only for a documented internal cache/mutex.
- **`const` on a method is a promise of logical *thread-safety*** in the practice of the standard ecosystem: if a `const` method mutates internal state, it must be safe to invoke concurrently (mutex/atomic), or the opposite must be documented.
- `[[nodiscard]]` on every function whose return value would be a bug to ignore (factories, pure functions, error types). `explicit` on one-argument constructors and on conversion operators, unless the conversion is deliberate.
- **Strong types** for IDs, units and flags: no three consecutive `int`s in a signature. `enum class` always (never an unscoped `enum`). `std::optional` for absence, `std::variant` for alternatives, `std::span` for "pointer + length" (it eliminates the whole class of desynchronised-length errors).
- **No C arrays** (`T v[N]`) in interfaces: `std::array` or `std::span`. No `char*` for text: `std::string`/`std::string_view`. No `#define` for constants or functions: `constexpr`/`inline constexpr`/a function.

### Templates, concepts and `constexpr`
- **Concepts in every public template** (C++20): they constrain the interface and turn a wall of instantiation errors into a readable diagnostic. An unconstrained template in a public API = design defect.
- SFINAE (`enable_if`, *tag dispatch*) is left for codebases that cannot use concepts yet; in C++20+ it is debt to be migrated.
- Metaprogramming is justified by a requirement (measured performance, elimination of real duplication, type safety), never by elegance. **Compilation cost is operational cost**: a template that instantiates a lot gets measured (`-ftime-trace` in Clang) and taken out of the header if it dominates.
- Generous `constexpr` (pure functions, tables, literal validation); `consteval` when compile-time evaluation is a requirement, not an option; `static_assert` with a message for type invariants.
- Reflection (C++26, available in GCC 16.1 and in the clang-p2996 branch) will solve many of the cases done by hand today — it is **not** adopted in production until the project toolchain's support is verified.
- Prefer `if constexpr` to specialisation when it suffices; `ranges` to loops with raw iterators (C++20); stdlib algorithms to hand-written loops.

### Modules and `import std` — real state, not a promise
State verified as of Aug 2026, with more misinformation than facts around it:
- **Compilers**: `import std;` works in **GCC 15/16**, **Clang 21+** and **MSVC** (modules since toolset 14.34 / VS 17.4+). In GCC 16.1 there is a module **performance gap** attributed to its BMI format not being optimised for large headers, with improvement expected in GCC 17+.
- **CMake**: `import std` is still **experimental** — it requires enabling `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD` with a **GUID specific to the CMake version, which changes between releases** (a preset that worked stops working when you bump CMake). Only with **Ninja generators**; the Visual Studio generators do not support building BMIs for IMPORTED targets. Opt-in per target with the `CXX_MODULE_STD` property, on targets with at least C++23.
- **Not supported**: *header units* (`import <header>;`), and building BMIs from IMPORTED targets.
- **Tooling/IDE is the weak link**: clangd has experimental support (editing a module interface does **not** update the BMI, and the clangd version must match the Clang one exactly); VS IntelliSense still labels C++20 modules as experimental; VS Code extensions flag `import std;` as an error with GCC 15+.
- **Ecosystem**: almost no library ships module definitions (Boost has a per-library prototype, with reported build-time reductions of around 45 %).
- **Criteria**: do **not** migrate an existing codebase to modules in 2026. Acceptable in new, internal projects with a fixed toolchain (Ninja + a recent CMake + a single compiler) and with the team aware that the IDE is going to suffer. Precompiled headers (`target_precompile_headers`) are still the build-time improvement with the best cost/benefit ratio today.

### Coroutines and concurrency
- Coroutines (C++20) **only on top of a task library**, never bare: the standard delivers the language mechanism with no task types, scheduler or cancellation. Options: the project's library (Asio, cppcoro, folly, libunifex) or `std::execution` (sender/receiver, adopted in C++26 — verify real support before basing architecture on it).
- Coroutine traps that always get reviewed: capturing by reference in a lambda-coroutine (the lambda dies before the frame), passing parameters by reference to a coroutine (the parameters are copied into the frame, what is referenced is not), and a lack of structured cancellation. Lifetime in asynchronous code is harder than in synchronous code, not easier.
- General concurrency: `std::jthread` + `std::stop_token` instead of `std::thread` (which on destruction without `join` calls `terminate`); `std::scoped_lock` over multiple mutexes (it avoids deadlock by ordering); `std::atomic` with an **explicit and justified** memory order — `memory_order_relaxed` requires a written argument.
- `volatile` is **not** synchronisation. A data race = UB, and the gate is TSan.
- Mutable global state is forbidden; if it is unavoidable, `constinit`/`inline constexpr` or a singleton with a local `static` (guaranteed *thread-safe* initialisation) — knowing that destruction order between TUs is not guaranteed.

### Error handling
- **Two mechanisms, with an explicit and documented criterion per project**:
  - **Exceptions** for exceptional errors that cross layers. They require documented guarantees (basic / strong / `noexcept`) and total RAII discipline. `noexcept` on destructors, moves, `swap` and on every function invoked from C.
  - **`std::expected<T,E>`** (C++23) for expected and local errors (parsing, validation, foreseeable I/O), where the caller decides on the spot. In C++20, `tl::expected` or your own `Result`, with the migration planned.
- Exceptions **disabled** (`-fno-exceptions`) is a legitimate decision in embedded, kernel or environments with a bounded real-time requirement, but it is **a whole-project decision**: it forces `expected`/codes everywhere and makes part of the stdlib unusable. It is not taken per module.
- **Forbidden**: raw integer error codes as a general strategy in new C++; `catch (...)` that swallows without logging or rethrowing; exceptions for expected control flow; throwing from a destructor; an exception escaping from a `noexcept` (it calls `terminate`).
- A custom error type derives from `std::exception` (or encapsulates `std::error_code`) and carries enough context to diagnose without guessing.

## 4. Quality: analysis, testing and CI gates

### Warnings (gate)
```
GCC/Clang: -Wall -Wextra -Wpedantic -Werror
  -Wshadow -Wconversion -Wsign-conversion -Wdouble-promotion
  -Wold-style-cast -Wcast-qual -Wuseless-cast
  -Wnon-virtual-dtor -Woverloaded-virtual
  -Wnull-dereference -Wimplicit-fallthrough -Wformat=2
  -Wextra-semi -Wmisleading-indentation -Wdangling
MSVC: /W4 /WX /permissive- /Zc:__cplusplus /Zc:preprocessor /EHsc
```
- `/permissive-` in MSVC is **mandatory**: without it, the compiler accepts non-conforming code that does not compile anywhere else. `/Zc:__cplusplus` because without it the macro lies.
- `-Wold-style-cast` is the line that separates C++ from "C with classes": casts in C++ are `static_cast`/`const_cast`/`reinterpret_cast`, and `reinterpret_cast` requires written justification.
- `-Wconversion`/`-Wsign-conversion` are introduced per module if the noise in an existing codebase prevents otherwise; they are never turned off globally.

### Formatting and static analysis
- `clang-format` with a versioned `.clang-format`; `clang-format --dry-run --Werror` in CI. Mass reformatting in a separate commit + `.git-blame-ignore-revs`.
- **`clang-tidy` is the central gate in C++**, with a versioned `.clang-tidy`. Starting set: `bugprone-*`, `cppcoreguidelines-*`, `modernize-*`, `performance-*`, `readability-*`, `concurrency-*`, `misc-*`, `clang-analyzer-*`. Checks enabled explicitly for their value: `cppcoreguidelines-owning-memory`, `cppcoreguidelines-pro-type-reinterpret-cast`, `cppcoreguidelines-special-member-functions`, `modernize-use-nullptr`, `modernize-use-override`, `bugprone-use-after-move`, `bugprone-dangling-handle`, `performance-unnecessary-value-param`.
- Reasonable trims: `cppcoreguidelines-pro-bounds-*` is very noisy in code with C interoperability — it is enabled per module. `modernize-use-trailing-return-type` is style, decided once.
- MSVC: `/analyze` (it includes lifetime analysis based on the Core Guidelines) in the Windows job.
- **GCC's `-fanalyzer` does not count as a gate in C++**: its C++ support is incomplete and *best-effort* (RAII, smart pointers, exceptions and templates are poorly covered; paths through the standard library are noisy). It is useful in the tree's C code → `c-standards`.
- **CodeQL** (or equivalent) on a schedule, for data-flow queries across translation units.
- **C++ Core Guidelines** as the project's normative reference, applied **by the automated clang-tidy and `/analyze` checks**, not by reading. Maintenance warning: the `isocpp/CppCoreGuidelines` repository is a living document with no tagged releases since 2017 — its status is verified by repository activity, not by looking for a version.

### Sanitizers (separate builds)
- **ASan + UBSan + LSan** in the test build by default: `-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=all -g -O1`.
- **TSan** in a separate job (`-fsanitize=thread`): **incompatible with ASan** — the runtimes assume different memory maps and the compiler rejects the combination with an error. It implies PIE and requires instrumenting all the code.
- **MSan** only Clang/Linux and a separate build; it requires instrumenting **all** the dependencies, **including libc++** (`-stdlib=libc++` with an instrumented libc++): if that cost is not paid, it is not used, because it generates false positives. Valgrind Memcheck is the practicable alternative for uninitialised memory over already built binaries, at the cost of not seeing overflows in locals/globals or use-after-return.
- Production **never** with sanitizers.
- **Hardened standard library** — this is the cheap mitigation that gets forgotten:
  - libstdc++: `-D_GLIBCXX_ASSERTIONS` in release (lightweight). `-D_GLIBCXX_DEBUG` is heavy and **breaks ABI**: only in debug builds, with the whole tree compiled the same way.
  - libc++: `-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST` in production; `_EXTENSIVE` and `_DEBUG` for tests.
  - MSVC: `_ITERATOR_DEBUG_LEVEL=1` for checks in release.
  - GCC additionally offers `-fhardened` as an umbrella (it includes `_FORTIFY_SOURCE=3`): verify exactly what it enables in the version used before replacing the explicit list with it.

### Testing
- Framework per §2, one single framework per project. Tests as CMake targets registered with `add_test`/`gtest_discover_tests`/`catch_discover_tests` and run with `ctest --output-on-failure`.
- AAA structure, one failure reason per test, no logic in the test, no global state shared between tests.
- Mandatory coverage of **edges and errors**: empty containers, type limits, allocation failures, exception paths (`EXPECT_THROW` and also the exception guarantee: that the object is left consistent), `std::expected` in its error branch, moved-from, self-assignment, and **`const`/thread correctness** in the types that promise it.
- **Mock your own boundaries** (project interfaces), not the stdlib or the system. Prefer injection by template or by interface depending on cost; GMock where it adds value.
- **Property testing** (RapidCheck) for algebraic invariants; **fuzzing** (libFuzzer/AFL++, versioned corpus, harness under ASan+UBSan) in **every parser or deserialiser of untrusted input** — mandatory, and in OSS-Fuzz if the project is open.
- Every fixed bug leaves a regression test that fails before the fix.
- Coverage as a signal, not as a target: `llvm-cov`/`gcovr` published, with attention to the error branches.

### Minimum CI gate (everything breaks the build)
```
1. clang-format --dry-run --Werror
2. build GCC   (-Wall -Wextra -Wpedantic -Werror + set from §4)
3. build Clang (same)
4. build MSVC  (/W4 /WX /permissive-)   [if Windows is a target]
5. clang-tidy over compile_commands.json
6. ctest under ASan+UBSan (-fno-sanitize-recover=all)
7. ctest under TSan (separate job, if there are threads)
8. short fuzz corpus per harness
9. dependency SCA (vcpkg/Conan) + SBOM of the artifact
10. release build with the hardening of §5 + verification of the binary (checksec)
11. [libraries with an ABI contract] abidiff against the previous version
```

## 5. Stack security, hardening and memory safety

### Binary hardening
A base aligned with the *OpenSSF Compiler Options Hardening Guide for C and C++* (a living document, re-verify before freezing it):
```
-O2 -Wall -Wformat=2 -Werror=format-security -Wconversion -Wimplicit-fallthrough
-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3
-D_GLIBCXX_ASSERTIONS            # or -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST
-fstrict-flex-arrays=3
-fstack-clash-protection -fstack-protector-strong
-fPIE -pie
-Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,-z,nodlopen
-Wl,--as-needed -Wl,--no-copy-dt-needed-entries
```
Add with measurement: `-ftrivial-auto-var-init=zero`, `-fcf-protection=full` (x86-64) / `-mbranch-protection=standard` (AArch64), and `-fsanitize=cfi` with LTO (Clang) for *forward-edge CFI* in polymorphic hierarchies — which in C++ is where type confusion and corrupted vtables turn into code execution. **Verify the produced binary** (`checksec`, `readelf -d`), do not trust that the flag reached the link. Strip the release with symbols archived separately (build-id) to symbolise crashes.

### Dependencies and supply chain
- **Pinned** versions (vcpkg baseline / Conan lockfile) and the lock file versioned. Dependency updates as a reviewed change, not automatic and blind.
- **SBOM** (SPDX/CycloneDX) generated in the build and published with the artifact; SCA against CVEs of what is embedded. Vendored/`FetchContent` code is exactly where CVEs get lost.
- Licences verified in the project's real `LICENSE` (verified as of Aug 2026: GoogleTest BSD-3-Clause, Catch2 Boost Software License 1.0, doctest MIT, Google Benchmark Apache-2.0, Abseil Apache-2.0, microsoft/GSL MIT, Boost BSL-1.0), not in what an aggregator says — and **re-verify** before pinning a default: the catalogue has precedents of licence changes (Trivy) and of projects declared *feature complete* with commercial action (gitleaks v2).
- Every new dependency is a decision of trust and of compilation cost, not a free import. Abseil imposes the *live at head* model (quarterly LTS if you cannot follow HEAD); Boost imposes build weight. Both must be justified.

### Code
- External input validated at the edge, with types that represent it (`span`, `string_view`, strong types) and not with "the caller already checked it".
- Indices and arithmetic: `.at()` or an explicit check in the paths with external data; `size_t` and `-Wsign-conversion` so as not to mix signs; `std::ssize` when a subtraction of sizes could go negative.
- `reinterpret_cast` and *type punning*: `std::bit_cast` (C++20) is the correct mechanism; `reinterpret_cast` requires a comment justifying its validity and it is not valid as an aliasing bridge.
- Secrets: never in code or in logs; erased with a function the optimiser cannot eliminate (`explicit_bzero`, `SecureZeroMemory`, or `std::fill` over `volatile` — verify the guarantee in the specific compiler); constant-time comparison for cryptographic material.
- Crypto with an audited library (libsodium, OpenSSL 3.x, BoringSSL, mbedTLS). No home-made crypto.
- SQL/commands: always parameterised / vectorised `argv`; never concatenation of input.

### Memory safety in C++ — real state and project posture
Verified as of Aug 2026; it is a technical strategy decision, not a matter of opinion:
- **Regulatory pressure**: the joint **CISA/FBI "Product Security Bad Practices"** guidance (*Secure by Design* initiative) establishes that, for existing products written in memory-unsafe languages, not having published a **memory safety roadmap before 1 January 2026** *"is dangerous and significantly elevates risk to national security, national economic security, and national public health and safety"*. It is **voluntary guidance**, not a rule with sanctions: the risk is liability and reputation, and there is an exemption for products whose support ends before 1 January 2030. The NSA lists Rust, Java, C#, Go, Delphi/Object Pascal, Ruby, Python and Swift as memory-safe. **Practical consequence**: a C++ project with network surface or cryptography needs a written roadmap — prioritise exposed components, and decide per component between rewriting in a safe language, isolating, or hardening.
- **Safe C++ (P3390)**: the security subgroup voted to **prioritise *profiles* over Safe C++**, and Sean Baxter declared in June 2025 that he is not continuing the work. Important nuance: it was not a formal rejection — according to Erich Keane (EWG co-chair) the encouragement vote was ~20 of 45 in favour of Baxter's paper and ~30 of 45 in favour of working on profiles, and Baxter is still welcome to standardise. The disagreement is about design: EWG adopted evolution principles that discourage a "safe" function annotation that can only call safe functions — the core of the proposal. **Do not count on a Rust-style safe subset inside C++ in the medium term.**
- **What did make it into C++26**: **contracts** (`pre`/`post`, `contract_assert`, with *ignore/observe/enforce* evaluation semantics; the finalisation vote was **not unanimous**: 114 in favour, 12 against, 3 abstentions, precisely because of contracts), a **hardened standard library** (P3471: it turns stdlib UB, such as out-of-range access of `vector`, into contract violations when *hardening* is enabled — *"initial cross-platform library security guarantees, including bounds safety for dozens of the most widely used bounded operations on common standard types"*), **reflection** (P2996) and **`std::execution`**.
- **What was deferred to C++29**: the **`[[profiles::enforce]]`** attribute and the general profiles framework (Sutter's P3081, Dos Reis's P3589, Stroustrup's P3984), which remain in SG23 targeting C++29. The C++29 cycle was adopted as another three-year cycle, with memory safety as the declared focus.
- **Project posture set by this skill**: do not wait for profiles. What **is available today** and is therefore enforceable: RAII and ownership in the type (§3), a hardened standard library enabled in release (§4), sanitizers as a gate, fuzzing of every parser, binary hardening and CFI, and a **written roadmap** for the most exposed components. Contracts and profiles are adopted when the project's toolchain really supports them — remember that in GCC 16.1 contracts **only emit warnings**.

## 6. Performance and operability

- **Measure before optimising**: Google Benchmark for micro, `perf`/VTune for macro, `-ftime-trace` (Clang) for compilation time. A performance change without a before/after number is not merged.
- Careful with micro-benchmarks: `benchmark::DoNotOptimize`/`ClobberMemory` or the compiler deletes the measured code; report dispersion, not a single run.
- The real cost is in allocations, indirections and cache misses, not in `virtual`: prefer contiguous containers (`vector` by default; `map`/`unordered_map` only when access justifies it), `reserve()` when the size is known, and avoid `shared_ptr` in hot loops.
- `-O2` default; `-O3` only with a benchmark. **`-march=native` forbidden in distributable artifacts**. LTO (`-flto=thin`) in release if build time allows it. `-ffast-math` forbidden in code that validates or compares floats.
- **Compilation time is operational cost**: precompiled headers, `extern template` for expensive templates, the pImpl idiom where the header drags in half the world, and avoiding unnecessary `#include`s in public headers. Watch it with `-ftime-trace` and with timed CI builds.
- **ABI**: changing the layout of a public type, adding a virtual member, changing the order of an `enum` or the `noexcept` of an exported function breaks ABI even if it compiles. Libraries with an ABI contract: pImpl, `-fvisibility=hidden` + an export macro, a version script, versioned `SONAME` and **`abidiff` in CI**. Remember that the **C++20 ABI in libstdc++ was not stable until GCC 16**.
- **Operability**: structured logging with a configurable level (`std::format`/fmt; **no debugging `std::cout`** in production); metrics and traces via OpenTelemetry (pipeline → `observability-standards`); clean exit on SIGTERM with orderly destruction of resources (`jthread` + `stop_token`); a *crash handler* that dumps symbolisable diagnostics; `std::stacktrace` (C++23) where the toolchain supports it.
- `assert` disappears with `NDEBUG` and is **not** input validation; for invariants that must hold in release, an explicit check, or contracts when the toolchain really enforces them.

## 7. Sustainability: upgrades and prohibitions

**Cadence**: test the next GCC major (annual, ~April) and LLVM major (~every six months) in CI **before** it becomes mandatory; MSVC 14.51 has 9 months of servicing, so the jump is planned, not suffered. Language standard: review the move to C++23 when the project's three compilers cover it; C++26 comes in through concrete, verified features, not as a block. Dated debts: SFINAE → concepts, `enable_if` → `requires`, macros → `constexpr`, `tl::expected` → `std::expected`, Conan 1 → Conan 2, `std::thread` → `std::jthread`.

**Deprecation**: `[[deprecated("use X")]]` with a window of at least one major version; in libraries with an ABI contract, a new `SONAME` when it breaks. Document the minimum supported standard policy as a contract with consumers.

**Conscious debt**: every shortcut leaves `// TODO(user): reason — issue #N`; every lint/sanitizer suppression with a reason and a review date.

**FORBIDDEN** (requires written justification and approval to make an exception):
- ❌ **Writing C in C++ files**: `malloc`/`free` instead of RAII, C arrays in interfaces, `char*` for text, `#define` for constants or functions, C-style casts, `printf` instead of `std::format`/fmt, integer error codes as a general strategy. It is a design defect, not a style one.
- ❌ Explicit `new`/`delete` outside the implementation of an RAII wrapper or an allocator; `delete` of a non-owning pointer; `new[]`/`delete[]` instead of `std::vector`/`std::array`.
- ❌ `shared_ptr` as the default pointer; `unique_ptr` over types that are already values; raw pointers with implicit ownership in signatures.
- ❌ Declaring a destructor without deciding about the five special members; moves without `noexcept`; using a moved-from object beyond destroying/reassigning it.
- ❌ `using namespace` in headers (in any case); `using namespace std;` in production; unprefixed macros in public headers.
- ❌ `reinterpret_cast` without written justification; `const_cast` to write over an originally `const` object (UB); type punning by pointer cast instead of `std::bit_cast`/`memcpy`.
- ❌ Returning a `string_view`/`span`/reference to a temporary or to an object that dies earlier; capturing by reference in lambdas that outlive the scope (and very especially in coroutines).
- ❌ Exceptions for expected control flow; `catch (...)` that swallows silently; throwing from a destructor; letting an exception escape from a `noexcept` or across an `extern "C"` boundary.
- ❌ `volatile` as synchronisation; mutable global state; `std::thread` without managed `join`/`detach` (use `jthread`); `memory_order_relaxed` without a written argument.
- ❌ Inheritance to reuse implementation (composition); public inheritance without a virtual destructor or without `final` when it is not a base; deep hierarchies for elegance; base classes without a clean `-Wnon-virtual-dtor`.
- ❌ CMake with global variables (`include_directories`, `CMAKE_CXX_FLAGS` overwritten, `link_libraries`, `add_definitions`), `file(GLOB)` of sources, and a global `CMAKE_CXX_STANDARD` as the only standard declaration.
- ❌ Two dependency managers in the same project; dependencies without a pinned version; Conan 1 in a new project.
- ❌ `-Werror` disabled in CI; MSVC without `/permissive-`; `// NOLINT` without a specific lint or a reason; `#pragma warning(disable)` without `push`/`pop`.
- ❌ Combining ASan with TSan/MSan in the same build (the compiler rejects it); deploying production with sanitizers; a release without a hardened standard library in code that processes external input.
- ❌ `-march=native` in distributable artifacts; `-O3` without a benchmark; `-ffast-math` with float validation.
- ❌ An untrusted input parser without a fuzzing harness.
- ❌ Migrating an existing codebase to C++ modules in 2026 on the basis of an article instead of the verified support of the team's toolchain and IDE (§3).
- ❌ Adopting metaprogramming as an end in itself: templates without `concepts` in a public API, TMP where `if constexpr`, `ranges` or a normal function suffice.
- ❌ **Including in this skill or in the code it produces: exploits, ROP/JOP gadgets, concrete mitigation bypasses, shellcode or payloads.** This skill is **defensive**: it describes vulnerability classes (use-after-free, type confusion, vtable corruption, overflow, double free, *iterator invalidation*) **in order to prevent them**, never to exploit them. Offensive work → `offensive-security-standards`, with scope and authorisation in writing.

## 8. Mandatory web verification

Before pinning versions, flags or asserting the state of the ecosystem, **verify on the web** (never from memory):
1. **Per-compiler support of each feature**: the table at https://en.cppreference.com/w/cpp/compiler_support **cross-checked** with the official release notes — https://gcc.gnu.org/projects/cxx-status.html, https://clang.llvm.org/cxx_status.html, https://libcxx.llvm.org/Status/ and https://learn.microsoft.com/cpp/overview/visual-cpp-language-conformance. Language and **library** are verified separately: having the language feature does not imply having the stdlib one.
2. **Modules and `import std`**: the `cmake-cxxmodules(7)` doc of the exact version used (the `CMAKE_EXPERIMENTAL_CXX_IMPORT_STD` GUID **changes between releases**) and the compiler release notes. It is the area with the most misinformation: do **not** accept blog claims without cross-checking them against the doc of the specific version.
3. **Versions and lifecycle**: GCC (https://gcc.gnu.org/develop.html, https://gcc.gnu.org/releases.html), LLVM (`https://github.com/llvm/llvm-project/releases.atom`), MSVC (the C++ team blog and the conformance table; check which toolset is the non-preview default and its servicing window).
4. **Dependency managers**: releases of vcpkg (date-based scheme) and of Conan 2 via their Atom feeds; changes to the binary cache model and to the registries.
5. **Maintenance status and licence** of every library before pinning it as a default: `/releases.atom` feed + raw `LICENSE` from `raw.githubusercontent.com`. Precedents in the catalogue: Trivy changed licence; gitleaks declared itself *feature complete* and its action requires a commercial licence for organisations from v2. Specific attention to **googletest** (no tagged release since 1.17.0, 2025-04-30, *live at head* model) and to the **C++ Core Guidelines** (no releases since 2017; it is a living document — measure by repo activity).
6. **Memory safety**: committee minutes and *trip reports* (isocpp.org, herbsutter.com) for the state of profiles targeting C++29, and CISA/NSA/ONCD for the evolution of the regulatory requirement. It is an area that moves per meeting and per administration.
7. **OpenSSF Compiler Options Hardening Guide** (living document): https://best.openssf.org/Compiler-Hardening-Guides/ — reread before freezing flags.

**Declared gaps (not verified as of Aug 2026, verify before using as a rule)**:
- The effective date of the **ISO publication of C++26** (technical work was completed in March 2026 and moved to DIS ballot; publication was expected "later in 2026"): **not verified**.
- **Formal EOL dates** of GCC 14/15/16 and of the LLVM branches: **not verified** (GCC does not publish an EOL table).
- The date on which **MSVC 14.52** becomes the non-preview default and with it full `/std:c++23`: **not verified**.
- Support by specific version of `-ftrivial-auto-var-init=zero`, `-fsanitize=cfi`, `-fhardened` and `std::stacktrace` in the project's toolchain: **not verified per version**.
- The **verbatim** licence of Conan and of vcpkg, and the licence status of Boost per individual library: **not verified verbatim** (verified verbatim: GSL → *"This code is licensed under the MIT License (MIT)"*; Catch2 → *"Boost Software License - Version 1.0 - August 17th, 2003"*; doctest → *"The MIT License (MIT)"*; Abseil → *"Apache License Version 2.0"*).
- The state of **`std::execution`** in real stdlib implementations (not just in the compiler frontend): **not verified**.
- C++26 coverage by standard library (libstdc++ / libc++ / MSVC's STL) beyond the headline "GCC 16.1 supports most C++26 features": **not verified per feature**.

**Declared discrepancy**: on the finalisation of C++26, the sources consulted give **28 March 2026** and **29 March 2026** as the date the technical work closed at the London/Croydon meeting; Herb Sutter's *trip report* says literally *"On Saturday, the ISO C++ committee completed technical work on C++26"* without fixing a day in the sentence. Neither is chosen: if the exact date matters, verify it in the committee's official minutes.

If the web contradicts this document, **the web wins** — flag the discrepancy.
