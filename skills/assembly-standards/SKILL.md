---
name: assembly-standards
description: Engineering standards for when and how to write assembly. Trigger on .s/.S/.asm files, GCC/Clang extended inline asm ("asm volatile" with input/output/clobber constraint lists) and asm goto, MSVC __asm and ml64/MASM, NASM or GAS invocations, AT&T versus Intel syntax, x86-64 System V or Microsoft x64 calling conventions, AArch64 AAPCS64, RISC-V ABI, callee-saved registers, stack alignment and red zone, compiler intrinsics as an alternative (immintrin.h, arm_neon.h), .note.GNU-stack markings, endbr64/CET/IBT, BTI and PAC branch protection, constant-time cryptographic routines and dudect/TIMECOP/ctgrind verification, Spectre mitigations such as lfence or retpoline, or objdump/perf/godbolt review of generated code.
---

# Assembly standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **when assembly is written, how it is justified and how it is maintained**: `.s`/`.S`/`.asm` files, GCC/Clang extended `asm` and `asm goto`, MASM/`ml64`, intrinsics as an alternative, ABIs and calling conventions, ELF marking of the produced object, and the discipline of tests, *benchmarks* and review that keeps that code correct three years from now. **It does not teach instruction sets**: it sets engineering criteria.

**The prior question is whether to write it at all, and almost always the answer is no.** The mandatory order is: **measure** (profile and locate the real bottleneck) → **change the algorithm or the memory access pattern** → **compiler intrinsics** → **assembly**, and only with a measured number backing the jump. A 2026 compiler almost always wins on general code; where it does not win is on what the language cannot express (guaranteed constant time, instructions with no intrinsic, startup with no runtime, hand-written ABI). Writing assembly turns a function into **code with an owner, a review date and a permanent maintenance cost**: you either accept that cost consciously or you do not write it.

**Not applicable**: see `c-standards` and `cpp-standards` (**inline `asm` inside a C/C++ function is a shared boundary**: the correctness of the `asm` block, its input/output/clobber constraints and the decision to write it are from here; the rest of the function —types, UB, resource management, compilation flags and binary hardening— is theirs), `rust-standards` (`core::arch`, `std::arch::asm!`, `#[target_feature]` and the `unsafe` that wraps it), `zig-standards` (its `asm` syntax and its toolchain), `gpu-computing-standards` (PTX/SASS, kernels and the GPU toolchain: not this skill), `cryptography-pki-standards` (**critical boundary: the choice of algorithm, the key size, the mode of operation and key lifecycle management are theirs** — here only the constant-time implementation and the wiping of secrets in memory; and the hard rule: **FORBIDDEN to implement your own cryptography**, you use an audited library, and this document exists to *review* the one already in use or for the rare, justified case where a primitive has to be touched), `linux-hardening-standards` (hardening of the **system**; that of the **binary** belongs to `c`/`cpp`), `offensive-security-standards` (exploitation: shellcode, gadgets, evasion — **it is not here and it will not be**, §7), `incident-response-forensics-standards` (analysing someone else's binary to respond to an incident), `observability-standards` (`perf` and continuous profiling in production; here `perf` only as a one-off decision tool), `objective-c-standards` (a `.mm` can contain `asm`: the assembly criteria are from here), `cicd-standards`, `appsec-standards`, `vulnerability-management-standards` and `secrets-management-standards`.

## 2. Default decisions

> **Verify the latest version on the web before pinning it in a real project** (§8). What follows is the state verified as of **Aug 2026**.

### Legitimate and illegitimate cases

| Legitimate | Illegitimate |
|---|---|
| A cryptographic routine that requires verifiable **constant time** (the compiler can introduce branches or secret-dependent accesses and there is no way to forbid it in C) | "It is faster than C" **with no profile or benchmark** |
| A *hot loop* with a **prior measurement** proving the compiler does not generate what is needed, and with instructions that have no intrinsic available | Optimising code that does not show up in the profile |
| Startup, context switching, exception handlers, trampolines: **before there is a runtime or a usable stack** | Replacing an intrinsic that does the same thing |
| Embedded with no libc and access to hardware registers or privileged instructions | A style exercise, inherited from an engineer who is no longer around |
| ABI *shims* (adapting calling conventions, *thunks*, low-level FFI) | Code copied from the internet whose licence and correctness nobody verified |
| Instructions with no exposure in the language (cryptographic, exotic atomics, timers) | Anything with no assigned owner |

### Ways of using it, in strict order of preference

1. **Compiler intrinsics** (`<immintrin.h>`, `<arm_neon.h>`, `__builtin_*`). The compiler still allocates registers, schedules and respects the ABI; the code is debuggable, inlinable and portable. It is the default option for SIMD and for specific instructions. With *runtime dispatch* (`__builtin_cpu_supports`, *function multiversioning*) so as not to produce a binary that dies with SIGILL on another machine.
2. **GCC/Clang extended `asm`** only for very short and very local sequences. Hard rules: a complete list of **output, input and clobber operands** (including `"cc"` and `"memory"` where appropriate), `volatile` when the block has effects the compiler cannot see, `%%` for registers in the template syntax, and **never** assume the compiler preserves a register that is not declared. An omitted clobber is a bug that shows up months later when the optimisation level changes. `asm goto` to jump to C labels (and `asm goto` with outputs, available in recent GCC/Clang — **verify the minimum version**, §8) is preferable to returning a flag and branching afterwards.
   - **Basic `asm` (no operands) is banned** outside functions: it declares nothing to the compiler and its behaviour inside a function body is not what people assume.
   - **MSVC**: verified — **it does not support `__asm` on x64** (nor on ARM64); `__declspec(naked)` is not available on x64 either. Its two documented routes are **intrinsics** and a **separate `.asm` file assembled with `ml64`**. Concrete warning: with `ml64`, write explicit prologue/epilogue with *unwind* directives (`PROC FRAME`, `.ALLOCSTACK`, `.SAVEREG`, `.ENDPROLOG`); the automatically generated one has produced incorrect `.xdata` and epilogues with `leave`, which is illegal on x64 and breaks stack unwinding.
3. **Separate `.s`/`.S` files — the preferred option for anything non-trivial.** It is readable, testable, versionable, annotatable and replaceable without touching the rest of the code. `.S` (uppercase) goes through the C preprocessor: that is what is used to share constants with the headers. Every routine longer than a few instructions goes here, not inline.

### Assemblers

| Tool | Status verified as of Aug 2026 | Criteria |
|---|---|---|
| **GAS** (GNU as, binutils) | **binutils 2.47**, announced on **2026-07-26**; 2.46 in Feb 2026. Active. Note: **gold is no longer shipped by default** in 2.47 (separate tarball) | **Default on Unix**: it is the toolchain's assembler, it integrates with the build and with preprocessed `.S`. AT&T syntax by default on x86; `.intel_syntax noprefix` if Intel is preferred |
| **Clang integrated assembler** | Part of LLVM, active | Default when the project is already Clang; it accepts most of GAS's syntax but **not all of it**: test in CI with the project's real assembler, do not assume equivalence |
| **NASM** | **3.02 (2026-06-29)**, verified via Atom feed. **Active**. Licence verified in the raw `LICENSE`: **BSD-2-Clause** (*"NASM is now licensed under the 2-clause BSD license, also known as the simplified BSD license"*) | A reasonable choice for standalone files with Intel syntax, especially cross-platform or in projects that do not want to depend on binutils |
| **YASM** | Latest release **1.3.0 (2019-07-25)**, verified via Atom feed. **No releases in ~7 years** | **Do not adopt in a new project.** If a project uses it, migrate to NASM (very close syntax) or to GAS. *(Pending check: the official site `yasm.tortall.net` **did not resolve in DNS** during verification — an additional data point in favour of treating it as dormant, but declared as a gap in §8)* |
| **MASM / ml64** | Part of Visual Studio | Mandatory on Windows/MSVC if an assembler is needed (see above) |

### ABIs: the thing you really have to respect

The ABI is not a portability detail, it is the **correctness** of the code. A routine that does not save a callee-preserved register corrupts the caller silently and non-deterministically.

- **x86-64 System V** (Linux, macOS, BSD) versus **Microsoft x64**: they are incompatible in everything that matters. They differ in the argument registers, in which registers are *callee-saved*, in the stack space reserved for arguments, and in the existence of a **red zone** (System V defines it; Microsoft x64 does **not**). Kernel code and signal/interrupt handlers **cannot use the red zone** even where the ABI allows it (`-mno-red-zone`).
- **AArch64 AAPCS64**: argument and return registers, callee-preserved registers, and **16-byte stack alignment at every public boundary** — violating the alignment produces failures in SIMD instructions and in libc calls that show up far from the origin.
- **RISC-V**: the ABI depends on the variant (`lp64`/`lp64d`/`ilp32`...); mixing variants in the same link is a link failure or, worse, silent corruption of floating-point arguments.
- **Cross-cutting rules**: passing and returning structures (by value in registers, by hidden memory, or by pointer, depending on size and content) is **the number one source of errors** when writing a *shim* by hand; you consult the ABI document, you do not deduce it from the disassembly of one case. Stack alignment **at the point of the call** is always respected. The state of the SIMD/FPU unit (e.g. `vzeroupper` after AVX code before returning to SSE code) is part of the contract.
- **Verify against the current ABI document** (§8), not against memory and not against a blog: ABIs get amended.

## 3. Structure and conventions

- All assembly lives in its own directory (`src/asm/<arch>/`), one file per routine or per family of routines, with the architecture and the ABI in the name or in the path. Never scattered across the tree.
- **Every routine has a reference implementation in C** in the same repository, selectable at build time (`USE_ASM=0`). Without it there is no differential test, no portability and no way out when the assembly version breaks.
- Symbols with a project prefix and restricted visibility (`.hidden`/`.local` except for what is API). Type and size declared (`.type foo, @function` / `.size foo, .-foo`): without them *unwinding*, profiling and disassembly are blind.
- **Unwind information is mandatory** in every routine that can appear on a stack: CFI directives (`.cfi_startproc`/`.cfi_def_cfa_offset`/`.cfi_endproc`) in GAS, or MASM's *unwind* directives on Windows. Without CFI, a *core dump* or a `perf` that traverses the routine produces no usable trace, and C++ exception handling breaks.
- **Syntax**: a single one per project, declared. AT&T (destination on the right, `%` on registers, `$` on immediates) is GAS's default on x86; Intel (destination on the left) is NASM/MASM's. Mixing them in the same tree is the fastest way to introduce a swapped-operand bug.
- **A mandatory comment per block explaining the *why***, not the what. `add %rax, %rbx  // add` is noise; what is needed is which invariant is maintained, which register holds what at that point, why this sequence and not the obvious one, and which microarchitecture motivated the decision. Each file's header declares: **target ABI, required ISA extensions, input/output contract and modified registers, owner, and review date**.
- Constants and structure offsets **are not written by hand**: they are generated from the C headers (an `asm-offsets`-style mechanism) or shared via preprocessed `.S`. A hardcoded offset survives a struct change and silently corrupts memory.

## 4. Correctness: tests, benchmarks and CI

- **A differential test against the C reference implementation** for every routine: same input vectors, bit-for-bit identical outputs. Edges are included (length 0, 1, block size ± 1, unaligned, overlap if the API allows it, extreme values) and random inputs with a recorded seed (*property-based*).
- Official test vectors (KAT) when the standard publishes them, in addition to the differential. A test that only compares against itself proves nothing.
- **A benchmark that justifies its existence**, with a before/after number against the C reference compiled with release flags, on the declared microarchitecture, with repetitions and dispersion. **If the benchmark stops showing an advantage, the routine is deleted** — that is its condition for staying, and it is re-run at every review.
- CI: assemble and link on **all** supported architectures/ABIs (QEMU emulation is acceptable for correctness; not for benchmarks); run the differential under the normal binary and, when the rest of the program is instrumented, check that the routine does not break the caller's sanitizers. **ASan/MSan do not see inside assembly**: the memory it touches by hand is not instrumented, so the differential test and human review are the only net.
- Review: **two reviewers**, one of them with the specific architecture as a declared competence. `godbolt`/Compiler Explorer is a legitimate review tool (comparing what the compiler generates against what is hand-written and demonstrating the difference), not a production one.
- Every bug fix leaves a regression test with the vector that reproduces it.

## 5. Low-level security and correctness

### Constant time (cryptography)
- **FORBIDDEN to implement your own cryptography.** An audited library is used (§1). This section governs reviewing the one already in use or the justified case of touching an existing primitive.
- The requirement is that **neither the control flow nor the memory addresses accessed depend on the secret**: no branches conditioned on secret material, no table indices derived from the secret (an S-box indexed by key is a cache leak), no division and no instructions with operand-dependent latency. The correct patterns are branchless selection (masks, `cmov` with the caveat that **its constant time is not architecturally guaranteed**) and cumulative OR comparison.
- **Verification, not trust**: tools verified as of Aug 2026 —
  - **TIMECOP** (part of SUPERCOP): marks secrets as uninitialised memory with the client requests `VALGRIND_MAKE_MEM_UNDEFINED`/`..._DEFINED` and lets Memcheck flag the branches and indices that depend on them. It is the modern presentation of the idea of **ctgrind** and **does not require patching Valgrind**: the original ctgrind patch is unmaintained and is no longer needed with current Valgrind. Used with Valgrind 3.23.0 in recent studies of NIST PQ candidates.
  - **Clang's MemorySanitizer** as an alternative to the Valgrind approach, instrumenting at compile time (it does not cover what is written in pure assembly).
  - **dudect**: statistical and black-box (Welch's t-test on measured timings). It detects that something depends on the secret, **not where**: it is a complement, not a substitute.
  - **ct-verif** and family: formal analysis; a compared catalogue at `crocs-muni.github.io/ct-tools`. Verify status and applicability before pinning it as a gate (§8).
  - **Known limit of all the dynamic ones**: they do not see the timing variability of a specific instruction depending on its operands (microarchitectural leak) nor the code that is not executed during the test. Coverage matters.
- **Wiping secrets**: the compiler removes a `memset` over memory that is no longer read. Use `explicit_bzero`/`memset_explicit`/`SecureZeroMemory` or a compiler barrier (`asm volatile("" ::: "memory")`). And remember what the wipe does **not** cover: copies in registers, on the stack (spills), in the *shadow stack* of a swap to disk, in a *core dump* (`prctl(PR_SET_DUMPABLE, 0)`) or in the memory of the language's virtual machine.

### Speculative side channel
- Spectre and family are mitigated with **retpoline** or with hardware mitigations (IBRS/eIBRS, IBPB), and with speculation barriers (`lfence` on x86, `csdb`/`sb` on AArch64) after a bounds check that protects a secret.
- **This changes with every microarchitecture and with every new CVE.** A hand-written set of mitigations that is correct today is incorrect or needlessly expensive tomorrow. Criteria: **leave the mitigation to the compiler and the kernel** (`-mindirect-branch=thunk`, `-mretpoline`, boot parameters) whenever possible; write it by hand only in code with no compiler involved, with the variant and the CPU documented and a **mandatory review date**.
- Check the mitigation status on the real system (`/sys/devices/system/cpu/vulnerabilities/`) before claiming something is mitigated.

### Marking the produced object
- **`.note.GNU-stack` is mandatory in every assembly file on ELF.** Compilers emit it on their own; **the assembler does not**, and its absence makes the linker assume an **executable stack** for the whole binary. Since binutils 2.39 the linker warns: `missing .note.GNU-stack section implies executable stack`, with a note that the behaviour is deprecated and will be withdrawn. Correct forms: the section at the end of the file (`.section .note.GNU-stack,"",%progbits` — `@progbits` on x86, `%progbits` on ARM/AArch64), or assembling with `-Wa,--noexecstack`. **FORBIDDEN** to silence it with `--no-warn-execstack` or to link with an executable stack "so it compiles": that disables NX for the whole process.
- **CET / IBT (x86-64)**: every indirect jump or call target must start with `endbr64` and the object must declare `GNU_PROPERTY_X86_FEATURE_1_IBT`/`SHSTK` in `.note.gnu.property`. Status verified as of Aug 2026: hardware, kernel (kernel IBT since 5.18, userspace *shadow stack* since 6.4) and toolchain are ready; **Fedora and Ubuntu already compile with `-fcf-protection` by default**, and Fedora has a *Change* under way to enable the *shadow stack* by default in the dynamic linker, with IBT deferred to a later version. glibc 2.39 added `--enable-cet` but **upstream leaves it inactive by default** (enableable via `GLIBC_TUNABLES=glibc.cpu.hwcaps=SHSTK`).
- **BTI / PAC (AArch64)**: `-mbranch-protection=standard` is equivalent to `bti+pac-ret`; the object declares `GNU_PROPERTY_AARCH64_FEATURE_1_BTI`. **A single object without the marking disables BTI for the whole linked binary** — and hand-written assembly is precisely the usual obstacle in deploying this mitigation. It is instrumented with the corresponding `bti`/`paciasp`/`autiasp` instructions.
- **Verify the produced binary, not the flags**: `readelf -n` for the GNU properties (IBT/SHSTK/BTI/PAC), `readelf -lW`/`checksec` for the non-executable stack and RELRO, and `--force-bti` / `--warn-execstack` in the CI link so that an unmarked object breaks the build. A flag being in `CFLAGS` does not mean the `.S` respects it.
- Assembly **does not get** automatic hardening: `_FORTIFY_SOURCE`, the stack canary, `-fstack-clash-protection` and the compiler's bounds checks **do not exist** inside a hand-written routine. All length and pointer validation is done explicitly in the C wrapper.

## 6. Debugging, profiling and expiry

- Tools: `perf` (`perf stat`, `perf record`, `perf annotate` to see the routine instruction by instruction with its samples), `objdump -d` on the object **actually linked** (not on what was written: the assembler and the linker transform), `gdb` with `layout asm`/`info registers`, and `godbolt` for comparative review.
- Profiling traverses the routine **only if there is CFI** (§3). Without it, traces get cut off and the work is attributed to the wrong caller.
- **Assembly optimised for one microarchitecture expires.** The optimal sequence for one CPU generation can be worse on the next (latencies, execution ports, vector widths and the cost of mitigations all change). That is why every routine carries a **review date** and a **reference microarchitecture** in its header, and at every review the benchmark is re-run against the C reference. No measurable advantage → it is deleted.
- Every routine has a **named owner**. An assembly routine with no owner is a block nobody dares to touch and nobody can validate: it is pure debt.

## 7. Long-term sustainability and prohibitions

**Framing — a defensive and engineering skill.** This skill deals with writing and maintaining **your own assembly, in your own code, for the purpose of performance, startup, hardware interfacing or cryptographic correctness**. **It does not and will not include an exploitation cookbook**: shellcode, ROP/JOP gadgets, detection evasion techniques, or *payload* construction. Mitigations are described here **so they can be applied correctly**, never to bypass them. That work, with scope and **written authorisation**, belongs to `offensive-security-standards`; analysing someone else's binary to respond to an incident, to `incident-response-forensics-standards`.

**Cadence**: review every routine at least once a year and **always** when changing toolchain, target architecture or target CPU generation. When upgrading the compiler, re-measure: the most frequent reason for deleting assembly is that the compiler now does it just as well.

**Planned exit**: every assembly routine is written with the retirement path already in place (the C reference, selectable at build time). The default goal of every review is **to be able to delete it**.

**FORBIDDEN** (requires written justification and approval to make an exception):
- ❌ **Writing assembly with no prior measurement to justify it** (profile + benchmark), **with no reference implementation**, **with no tests** and **with no owner**. All four, not three out of four.
- ❌ **Copying routines from the internet without understanding them or verifying their licence.** Origin, version, licence and reviewer are recorded; a cryptic routine with no provenance does not get in.
- ❌ Writing it when there is an **intrinsic** that does the same thing; writing it before exhausting the algorithmic change.
- ❌ Inline `asm` for anything non-trivial (it goes to a separate `.S`); basic `asm` with no operands inside a function; an `asm` block with an incomplete clobber list or without `volatile` when it has hidden effects.
- ❌ Violating the ABI: not preserving a *callee-saved* register, breaking stack alignment, using the red zone in kernel or signal-handler code, deducing structure passing from the disassembly instead of reading the ABI.
- ❌ A routine with no **CFI/unwind info**, no `.type`/`.size`, no project prefix or no header with ABI, ISA, contract, owner and review date.
- ❌ An ELF assembly file **with no `.note.GNU-stack`**; silencing `--warn-execstack`; linking with an executable stack.
- ❌ An object with no `endbr64`/IBT marking on x86-64 or no BTI marking on AArch64 in a project that deploys those mitigations (**one unmarked object disables them for the whole binary**).
- ❌ **Implementing your own cryptography**; in cryptographic code, branches or memory indices dependent on the secret; `memset` to wipe secrets; comparing secrets with an early exit.
- ❌ Declaring a routine "constant time" **without verifying it** with TIMECOP/Valgrind, MemSan or equivalent.
- ❌ Hand-written speculative mitigations with no documented CPU and review date, when they could be left to the compiler/kernel.
- ❌ Structure offsets or constants **hardcoded** instead of generated from the headers.
- ❌ Mixing AT&T and Intel syntax in the same tree; adopting **YASM** in a new project.
- ❌ Assuming that ASan/MSan/UBSan cover what the assembly does, or that the compiler's hardening applies inside it.
- ❌ Keeping a routine whose benchmark no longer shows an advantage over the C reference.

## 8. Mandatory web verification

Before pinning versions or flags, or claiming the state of the ecosystem, **verify on the web** (never from memory):
1. **Current ABI documents**: System V AMD64 psABI (repo `gitlab.com/x86-psABIs/x86-64-ABI`), Microsoft's *x64 calling convention* on learn.microsoft.com, AAPCS64 at `github.com/ARM-software/abi-aa`, and the RISC-V ABI specs. They get amended: do not cite from memory.
2. **Assemblers**: binutils at https://sourceware.org/binutils/ (verified: **2.47**, 2026-07-26; **gold is no longer shipped by default**), NASM via `https://github.com/netwide-assembler/nasm/releases.atom` (verified: **3.02**, 2026-06-29; licence **BSD-2-Clause** in the raw `LICENSE`), YASM via `https://github.com/yasm/yasm/releases.atom` (verified: **1.3.0, 2019**).
3. **MSVC**: the *Inline Assembler* page on learn.microsoft.com to confirm it is still unsupported on x64/ARM64, and the intrinsics and `ml64` reference.
4. **`asm goto` with outputs and other extensions**: the exact minimum GCC/Clang version in the documentation of the version in use.
5. **Constant time**: the catalogue at https://crocs-muni.github.io/ct-tools/, Trail of Bits' TIMECOP guide (appsec.guide) and the status of the `dudect` and `ct-verif` repos before pinning a gate.
6. **CET/IBT and BTI/PAC**: `https://fedoraproject.org/wiki/Changes/Enable_Shadow_Stack_Userspace_Support`, the glibc notes and the kernel documentation (`docs.kernel.org/arch/x86/shstk.html`), and `dpkg-buildflags --export` / `redhat-rpm-config` macros on the target distro. The status per distribution changes with each release.
7. **Status of the speculative mitigations** on the target hardware: `/sys/devices/system/cpu/vulnerabilities/` and the vendor's advisories; every new CVE changes the criteria.
8. **Licence and maintenance** of every third-party tool or routine before pinning it as a default: the raw `LICENSE` from `raw.githubusercontent.com` and the Atom releases feed, never an aggregator.

**Declared gaps (not verified as of Aug 2026, verify before using as a rule)**:
- **YASM**: its official site `yasm.tortall.net` **did not resolve in DNS** during verification, so the "dormant" conclusion rests only on the GitHub Atom feed (latest release 2019). **Not confirmed against the project's official source** — verify before stating it in writing to third parties.
- The exact minimum GCC/Clang version for **`asm goto` with outputs**: **not verified**.
- The status of **Ubuntu 26.04** regarding *runtime* enablement of shadow stack (only that it compiles with `-fcf-protection` is on record): **not verified**. Likewise the current status of BTI/PAC by default on Fedora 42+ and Ubuntu 26.04: the sources found are from 2022–2024.
- Maintenance status and current applicability of **ct-verif** and **dudect** (activity of their repos): **not verified**; the source consulted did not confirm it either.
- The specific Fedora version that enables the *shadow stack* by default and its status in FESCo: **not verified**.
- Details of the interaction between `--fatal-warnings` and `--warn-execstack` (bug ld/31299) in the project's binutils version: **not verified per version**.

If the web contradicts this document, **the web wins** — flag the discrepancy.
