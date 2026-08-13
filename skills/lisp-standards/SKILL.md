---
name: lisp-standards
description: The Lisp family except Clojure - Common Lisp and Scheme. Use when working with .lisp, .lsp, .cl, .asd, .scm, .ss, .sls, .sld, .rkt or .el files, ASDF defsystem forms, Quicklisp (ql:quickload, quicklisp.lisp, dists, qlfile/qlfile.lock with Qlot, ocicl and ocicl.csv), SBCL, Clozure CL, ECL, ABCL, CLASP, CLISP, CMUCL, LispWorks or Allegro CL images, save-lisp-and-die and dumped Lisp images, SLIME or Sly and swank/slynk REPL sessions, defmacro and macroexpand-1, CLOS defclass/defgeneric/defmethod and the MOP, the condition system (handler-bind, handler-case, restart-case, invoke-restart, signal, cerror), declaim/declare optimize speed safety, fiveam/parachute/rove test systems, Racket raco and #lang, Guile, Chez Scheme, Gambit, Chicken, R7RS libraries and SRFIs, or Emacs Lisp init.el and package.el.
---

# Lisp family standards (Common Lisp and Scheme)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Common Lisp is alive, but in specific niches and with a small ecosystem.** It is not a
dead technology nor an exercise in nostalgia: there are implementations with monthly releases (SBCL
published 2.6.7 on 28 Jul 2026), there are commercial vendors charging for support and there are systems in
production. What there is **not** is critical mass: the library surface, the depth of the
tooling and the job market are orders of magnitude smaller than those of any
mainstream language, and that is a project risk, not an aesthetic opinion.

**Choose it on criteria, not on taste.** Where it genuinely wins: long-lived systems where the
domain is better modelled as its own language (macros, DSLs, compilers, rule and
planning engines, CAD/CAM, symbolic systems), interactive exploration over live state (a REPL
attached to a connected image is a real advantage, not a preference), and teams that already know it.
Where it does not win: CRUD, infrastructure glue, and anything that will rotate between many hands.
**Before the first line:** are there ≥3 people able to operate and modify it? If not, see §7.

Covers: ANSI Common Lisp and its implementations (free and commercial, with their cost); ASDF and
library distribution (**Quicklisp and its integrity model, which is the ecosystem's security fact**
— §5); the image, `save-lisp-and-die` and why that breaks modern CI; the REPL as a
method; **the condition and restart system** versus exceptions; macros and when **not** to write
one; CLOS and the MOP. Also Scheme (R7RS, Racket, Guile, Chez) and Emacs Lisp as a separate case.

**Not applicable**: see `clojure-standards` (**Clojure and ClojureScript are a Lisp and have their own
skill: cede them entirely** — `deps.edn`, `project.clj`, `.clj`/`.cljs`/`.cljc`/`.edn`, the JVM, `clj-kondo`,
the nREPL, immutability by default and its state model. **The boundary is not "it is a
Lisp"**: Clojure has no condition system, no CLOS, no image, no `read-eval` over mutable
data, and its dependency management is Maven's; nothing is extrapolated from there to here),
`haskell-fp-standards` and `ocaml-fsharp-standards` (**typed functional programming**: the boundary is the
static type system and evaluation, not the paradigm), `scala-standards`, `julia-standards`
(**another homoiconic language with macros and REPL-driven development, aimed at numerical computing**: if the
problem is numerical, it is theirs), `elixir-erlang-standards` (macros and Elixir's `defmacro` live
there), `python-standards`/`go-standards`/`typescript-standards` (the real alternative when §7 says
Lisp is not the answer), `developer-workstation-standards` (**configuring Emacs as an editor is
theirs**; here only Emacs Lisp *as a language*), `refactoring-tech-debt-standards` and
`enterprise-architecture-standards` (modernisation and portfolio strategy),
`legacy-modernization-standards` (**the umbrella skill** for an inherited Lisp system: which "R" is
chosen, whether it is frozen, rewritten or retired, and the archaeology beforehand) and
`migration-projects-standards` (**executing the cutover** once decided: rehearsal, window,
data reconciliation, rollback and switching off the source), `opensource-licensing-standards` (licence analysis; here only which licence each
implementation carries and what it implies, §2), `cicd-standards` (the pipeline; here the specific problem of
building from an image), `appsec-standards` and `vulnerability-management-standards` (methodology
and triage; here the concrete sinks and Quicklisp's integrity model), `webassembly-standards`
(if the target is Wasm), `solidity-standards`, `mumps-standards` and `ibm-i-rpg-standards` (**they are not
comparable**: those are legacy platforms with no choice; Common Lisp is still a possible
choice and it has to be defended).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Choice | Verified note (Aug 2026) |
|---|---|---|
| Default CL implementation | **SBCL** | **2.6.7, 28 Jul 2026**; roughly monthly cadence. A native compiler, the best performance and the best community support. It is the default unless there is a written reason |
| SBCL's licence | **Public domain + partial BSD/MIT** — read raw from `COPYING` | *"SBCL is derived from CMU CL, which was released into the public domain"*; later changes go to the public domain *"or under the FreeBSD licence where not"*, with MIT on LOOP/PCL/CityHash. **It is not "MIT" and not "GPL": do not assume** |
| CL on the JVM | **ABCL**, only if the requirement is Java interop | **Licence verified raw (`COPYING`): GPL v2 with a Classpath-style exception (13th term)** — not MIT and not BSD; it affects how you distribute. **Gap: I could not verify its current version** (§8) |
| Embedded CL / C++ | **ECL** (embeddable, compiles to C) or **CLASP** (on LLVM, C++ interop) | ECL: tag **26.5.5** (5 May 2026) on **GitLab**, not GitHub. CLASP: **v3.0.1** (Jun 2026). Both active |
| CCL (Clozure) | **Maintenance only**: not for new projects | Latest release **1.13 (2024)**; no releases in 2025-2026. It is not dead, but its cadence does not sustain a new choice |
| Commercial implementation | **LispWorks** or **Allegro CL**, only with a requirement that justifies them (cross-platform GUI, mobile delivery, contractual support, closed deliverables) | **LispWorks publishes prices**: 8.1 Professional **USD 1,500 (32-bit) / USD 3,000 (64-bit)**, Enterprise **USD 4,500**, per user, with no runtime royalties. **Allegro CL does not publish rates: it is quote-only** ("contact … for a customized price quote"). The licence cost is the expensive fact, not the syntax |
| System definition | **ASDF** (`.asd`), no alternative | Latest stable **3.3.7 (Jan 2024)**. It lives on `gitlab.common-lisp.net`; **the `fare/asdf` GitHub repository has been frozen since 2018 and is not the source of truth** |
| Library distribution | **Quicklisp** as the base + **Qlot** (`qlfile.lock`) or **ocicl** (`ocicl.csv`) to pin versions | **A versioned lockfile is mandatory.** Bare `ql:quickload` is not reproducible |
| Modern alternative | **ocicl**: OCI artifacts, HTTPS, sigstore signatures, per-project local installation | **MIT** licence, read raw from `LICENSE`. It is the option with the best supply-chain story (§5) |
| Rolling dist | **Ultralisp: forbidden in production** | Rolling with no curation: it widens the supply surface with no operational compensation |
| Editor / REPL | **SLIME (swank)** or **Sly (slynk)** on Emacs; alternatives for VS Code/Vim | The REPL attached to the image is the working method, with the discipline in §3 |
| Tests | **FiveAM** or **Parachute** | Runnable from the CLI in a clean process, not only from the REPL (§4) |
| Scheme: applications | **Racket** | **v9.2 (26 May 2026)**. It is the Scheme with an ecosystem, documentation and tooling of its own (`raco`, `#lang`); if in doubt between Schemes, this one |
| Scheme: embedded / extension | **Guile** (GNU, LGPL — verify) | Latest verified stable series **3.0.11**. The forced choice if you extend GNU software |
| Scheme: performance | **Chez Scheme** | **10.4.1 (May 2026)**, in `cisco/ChezScheme`. It is also Racket CS's backend |
| Scheme standard | **R7RS-small** as the portability target | **R7RS-large is NOT closed**: it advances through *colour dockets* (Red 2016, Tangerine 2019) and **there is no single ratification event**. Its development moved to **Codeberg**. **Do not write "R7RS-large compliant" in any document** |
| Emacs Lisp | **A separate case**: an editor's extension language, not an application language | You do not write an application in Elisp. Editor configuration belongs to `developer-workstation-standards` |

## 3. Structure and conventions

- **One ASDF system per deployable unit**, with an explicit `:depends-on` and **no circular
  dependencies between systems**. Tests go in a separate system (`foo/tests`), never hanging off the
  main system: otherwise the production binary drags the test framework along.
- **Explicit packages (`defpackage`), with `:export` as the contract.** No `:use` of other people's
  packages beyond `:cl` — importing symbols wholesale causes collisions that only appear when
  updating a dependency. `uiop` is referenced with a prefix.
- **Macros: the last tool, not the first.** Write a macro **only** when you need to
  control evaluation (a new binding, evaluation order, new syntax). If a function,
  a higher-order function or an `&rest` solves it, **it is a function**. Every macro: variable capture
  avoided with `gensym`, single evaluation of each argument, and `macroexpand-1` in the
  test. An exported macro is an API that cannot be changed without recompiling its consumers.
- **Conditions and restarts, not exceptions.** It is the most underrated technical advantage of the language:
  `handler-bind` runs the handler **before unwinding the stack**, so a `restart-case`
  can repair and continue. Criterion: libraries **signal** conditions and **offer named restarts**;
  **the application decides** with `handler-case`/`invoke-restart`. Define your conditions
  as subclasses of your own `error`/`warning`; **never signal `simple-error` with a string**.
- **CLOS**: generic methods and `defmethod` over your own classes; multiple inheritance in moderation.
  **The MOP is powerful and almost always unnecessary**: touching it makes your code depend on implementation
  details and hostile to whoever comes next. Written justification for every use.
- **`declaim`/`declare optimize`**: by default **`(safety 1)` or higher**. `(safety 0)` disables type
  checks and turns an error into memory corruption; it is used in a bounded, measured block,
  never globally.
- **The REPL's live state is not the program.** Everything that works in your image must work
  after loading the system from scratch in a new process. Redefining hot is the tool;
  **the file is the truth**.

## 4. Quality, tests and CI (the image problem)

- **The image is the structural problem with CI.** `save-lisp-and-die` produces an artifact that
  contains all the state accumulated in the session — including definitions that are no longer in any
  file and, if you are careless, **secrets read during the build**. Rules: the image is built
  **in a clean process, from source, with a non-interactive script**, in a single reproducible step; and
  **zero secrets in the build environment** (they end up inside the binary).
- **Minimum CI gate, in order of cost**: (1) the system **loads from scratch** in a clean image
  with no compilation warnings — a `STYLE-WARNING` about an undefined function is almost always a typo
  that in Lisp does not fail until the call; (2) the suite (FiveAM/Parachute) passes **run from the CLI**
  with a non-zero exit code on failure; (3) the lockfile (`qlfile.lock`/`ocicl.csv`) is
  committed and has not drifted; (4) the image builds and starts.
- **Tests**: observable behaviour, with explicit coverage of **signalled conditions and
  offered restarts** — that is the part of the contract that most often breaks silently. Property-based with
  `cl-quickcheck`/`check-it` where the domain allows it.
- **With no type system to cover you**: edge validation is manual and mandatory.
  Type declarations on public interfaces (SBCL checks them and uses them to optimise).

*§6 is deliberately omitted*: the observability, timeouts and capacity of a Lisp service
have no language-specific criteria — they are governed by `observability-standards` and by the
platform's skill. The only specific parts (the image, GC, `save-lisp-and-die`) are in §4 and §5.

## 5. Stack security

- **The ecosystem's security fact: Quicklisp distributes over plaintext HTTP, and its per-library
  integrity is MD5 and SHA-1.** Verified by reading the client and the metadata raw: the current
  dist is `version: 2026-01-01`, and `distinfo.txt`, `releases.txt`, `systems.txt` and the tarballs
  are served from `http://beta.quicklisp.org/` without TLS; `releases.txt` lists `file-md5` and
  `content-sha1` per release. **The only thing signed with OpenPGP is the bootstrap file
  `quicklisp.lisp`** (fingerprint published at quicklisp.org/beta), not the libraries. Consequences:
  - **Neither MD5 nor SHA-1 resists collisions**, and the index containing them arrives over an
    unauthenticated channel: **there is no usable integrity verification against an attacker on the network**.
  - **There is no per-library author signature**: the dist's curation checks that it **builds
    together**, not that it is safe. It is not an audit.
  - **Criterion**: verify the bootstrap's PGP signature; **a lockfile is mandatory**; install in a
    build environment with no write access to production; and, for a serious supply chain,
    **`ocicl`** (HTTPS + digest-addressed OCI artifacts + sigstore) or vendor and review
    the critical dependencies. **Additionally: force HTTPS/a trusted proxy at the network level.**
- **`read` is a sink**: Common Lisp's reader evaluates with `#.` if `*read-eval*` is on, and it
  interns symbols without limit. **Never `read` untrusted input**: `*read-eval*` set to `nil`,
  `with-standard-io-syntax`, and prefer an explicit parser (JSON/EDN/whatever) to reading someone else's
  S-expressions. A `read` over user data is remote code execution.
- **`eval`, `compile` and `intern` at runtime over external data: forbidden.** Unbounded interning
  is additionally an exploitable memory leak.
- **The saved image contains everything that was in memory**: variables with credentials, build
  tokens, history. Treat it as a sensitive artifact; generate it without secrets and scan it.
- **`safety 0` is a security defect**, not an optimisation: it removes the checks that
  turn a bug into a controlled error instead of memory corruption.
- **Swank/slynk is a remote console with arbitrary execution**: **never listening in production**
  nor on any interface other than `127.0.0.1`, and only over an SSH tunnel.

## 7. Sustainability, migration and prohibitions

**Adoption criteria (decide *beforehand*, not afterwards):**
1. **Bus factor ≥3** with people who can operate and modify it. If one person sustains the
   system, you are building a liability, however good the code is.
2. **The advantage has to come from the language**: macros/DSLs, interactive exploration over live state,
   symbolic modelling. If the argument is "it is more elegant", it is not an argument.
3. **A budget for training and for in-house tooling**: some of the tooling you take for granted does not exist and
   you are going to write it.
4. If (1)-(3) do not hold: **another language**. It is the right answer most of the time, and
   saying it here is cheaper than discovering it in year three.

**Exiting an existing CL system** — this applies only if there is a real reason (impossible
succession, unsustainable commercial dependency), not fashion: **encapsulate and freeze** rather than rewrite.
Extract the core of value behind a stable interface (a separate process, HTTP/gRPC), build the
new thing outside against that interface (*strangler fig*, see `refactoring-tech-debt-standards`) and **do not
automatically translate macros into anything**: there is no equivalent target, and the result inherits the
structure without preserving the semantics.

**Prohibitions:**
- ❌ **FORBIDDEN**: `ql:quickload` without a committed lockfile (`qlfile.lock` / `ocicl.csv`): the build is not
  reproducible and the dependency floats.
- ❌ **FORBIDDEN**: `read`/`eval`/`compile`/`intern` over untrusted input; `*read-eval*` enabled
  when reading someone else's data.
- ❌ Swank/slynk exposed beyond `localhost`; a remote REPL against production as an operating
  method ("I connect and fix it hot" is not a procedure: it leaves no trace and no rollback).
- ❌ Building the image from an interactive session, or deploying an image that does not come from a
  clean build from source. An image is by definition not reproducible if the process is not.
- ❌ Secrets present in the image build's environment.
- ❌ Global `(safety 0)`, or `(speed 3)` without having measured.
- ❌ Writing a macro where a function suffices; exported macros with no `macroexpand-1` test.
- ❌ Using the MOP without written justification.
- ❌ Ultralisp or any other rolling dist in production.
- ❌ Declaring conformance to **R7RS-large**: it is not closed (§2).
- ❌ Assuming an implementation's licence: **SBCL is not MIT, ABCL is not BSD** — read the
  `COPYING` raw (§2).
- ❌ Committing a project to LispWorks or Allegro CL without the licence **and renewal** cost
  in writing, and without a plan if the vendor changes terms.
- ❌ Choosing CCL for a new project (§2).
- ❌ Writing an application in Emacs Lisp.

## 8. Mandatory web verification

1. **SBCL**: latest release at `sbcl.org/news.html` (as of Aug 2026, **2.6.7 of 28 Jul 2026**) and the status
   of your platform in the *platform table* — not all of them have a recent binary.
2. **ECL and CLASP**: ECL publishes its tags **on GitLab** (26.5.5, May 2026), CLASP on GitHub (v3.0.1,
   Jun 2026). **CCL**: confirm whether there has been a release after 1.13 (2024) before ruling it out.
3. **ABCL — declared gap**: `abcl.org` did not respond during verification and **the GitHub
   repository publishes neither tags nor releases** (it is a bridge to their SVN), so **I could not pin its
   current version**. Do not invent it: look it up at `abcl.org/release-notes.shtml` or in the project's
   SVN. Its licence **is** verified (GPLv2 + exception).
4. **ASDF**: latest stable (as of Aug 2026, **3.3.7 of Jan 2024**) at `asdf.common-lisp.dev` and on
   `gitlab.common-lisp.net`. **The `fare/asdf` GitHub mirror is frozen at 2018: it is not a source.**
5. **Quicklisp**: the date of the current dist (as of Aug 2026, **2026-01-01** — seven months without an update;
   check whether the cadence has resumed, because **a stalled dist is a dependency security
   risk**), the fingerprint of the bootstrap signing key, and whether the transport is still
   plaintext HTTP. **ocicl**: version and the state of its sigstore verification.
6. **LispWorks**: current pricing and editions at `lispworks.com/buy/` (as of Aug 2026, 8.1: Professional
   USD 1,500/3,000, Enterprise USD 4,500) — **confirm them on the page before budgeting**.
   **Allegro CL: a structural gap — Franz publishes no rates**; any figure has to come from
   a contractual quote.
7. **Racket** (v9.2, May 2026), **Guile** (3.0.x series, 3.0.11 verified) and **Chez** (10.4.1,
   May 2026): current version and its licence read raw (**Guile is LGPL: verify it, it constrains
   distribution**).
8. **R7RS-large**: the status of the *colour dockets* in the **Codeberg** repository and the WG2 minutes
   before assuming anything is "standard".
9. CVEs and advisories for the ecosystem's network/TLS libraries (`cl+ssl`, HTTP servers), which is where
   the real attack surface is, and for the implementation itself.

If the web contradicts this document, **the web wins** — flag the discrepancy.
