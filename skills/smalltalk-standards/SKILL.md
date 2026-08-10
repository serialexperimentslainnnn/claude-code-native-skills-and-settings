---
name: smalltalk-standards
description: Smalltalk and its live image-based development model. Use when working with .st, .cs (change set), .image, .changes or .sources files, Tonel or FileTree package directories with package.st and .class.st, Pharo (Pharo Launcher, Metacello baselines and ConfigurationOf/BaselineOf, Iceberg, Monticello .mcz packages, Spec/Bloc/Morphic UIs, Seaside or Teapot web apps), Squeak, Cuis Smalltalk, the OpenSmalltalk VM, GemStone/S 64 Bit and GemTalk topaz sessions, Cincom VisualWorks or ObjectStudio, Instantiations VAST Platform and ENVY, Dolphin Smalltalk, SUnit TestCase subclasses, smalltalkCI headless CI runs, doesNotUnderstand: and message-based dispatch, become:, thisContext, the class browser and the live debugger with restart/proceed on a running stack, or deciding whether to keep, extend or migrate an image-based system.
---

# Smalltalk standards (live image-based development)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Smalltalk is not dead, but neither is it a defensible choice for new third-party software.**
The data, verified: Pharo has active development (stable **13.1.0**, Jun 2025, with
Pharo 14 announced and **delayed** in 2026); Squeak keeps publishing images; **GemStone/S 64 Bit**
published **3.7.5 in March 2026**; **VAST Platform 2026 (v15.0.0) came out on 18-Feb-2026**. There are
vendors charging money, there are releases and there is production. And even so:

**Honest position, stated here and not hidden in §7:**
- **For a new product you are going to deliver to a client and that another team will maintain: it is
  almost never the right choice.** Not because of the language —which is excellent— but because of
  what it costs around it: hiring is very hard, the tooling does not fit the standard delivery chain
  (§4) and every operational decision requires explaining the image model to people who have never
  seen it.
- **It is the right choice**, without complexes, in: **language and tooling research and
  prototyping**, **teaching**, **maintenance and evolution of existing systems** (and there are
  such systems, large and profitable, in insurance, banking, logistics and manufacturing), and
  **systems with GemStone where transparent object persistence is the central value**.
- **The real argument in favour is not the syntax, it is the environment**: class browser and **live
  debugger** —stop at the exception, inspect and **modify the method, restart the stack frame and
  continue** without relaunching the system— are still, in 2026, a debugging experience that
  almost no modern stack matches. If that is the reason, defend it with that.

Covers: free and commercial implementations and their cost; **the image as an artifact and why it
breaks the modern CI chain**; real version control (Iceberg/Tonel on Git, Monticello as
history); code and package conventions; tests with SUnit and headless CI; image security;
and the decision to maintain, encapsulate or migrate.

**Not applicable**: see `ruby-standards` (**the direct descendant of the object model and of the
blocks**; if the question is "how do I write this today with these ideas", it is usually the answer —but
Ruby has no image, no live debugger, no `become:`), `clojure-standards` and `lisp-standards`
(**the other lineage with a REPL over live state**: the boundary is that there the file is the truth and
the image is a product of the build, here the image has historically been **the** artifact — it is the
difference that explains §4), `objective-c-standards` (**it inherits message passing and its selector
syntax from Smalltalk**; the boundary is the runtime and the Apple platform), `python-standards`,
`typescript-standards`, `jvm-spring-standards`, `dotnet-standards`, `go-standards` (**real
destinations of a migration and the default alternative for anything new**: the quality of the
destination code is theirs), `refactoring-tech-debt-standards` (**theirs** are *strangler fig*, branch
by abstraction and characterization of code without tests), `enterprise-architecture-standards`
(inventory, TIME model and the "R"s), `legacy-modernization-standards` (**umbrella skill** for an
inherited image: which "R" is chosen, whether it is frozen, encapsulated or rewritten, and the prior
archaeology) and
`migration-projects-standards` (**the execution of the cutover** once decided: rehearsal, window, data
reconciliation, rollback and shutdown of the source), `tech-leadership-standards` and `technical-hiring-standards` (**the hiring problem
is real and managing it is theirs**; here it is only declared as a decision criterion),
`nosql-standards` and `data-platform-standards` (GemStone as an object database is decided with
criteria from here, but operating a data engine —backup, HA, tuning— is theirs),
`opensource-licensing-standards` (license analysis; here which license each implementation has,
§2), `cicd-standards` (the pipeline; here the specific problem of building from an image),
`testing-qa-standards` (split across levels and coverage policy; here SUnit and the runner),
`appsec-standards` and `vulnerability-management-standards` (methodology and triage),
`mumps-standards`, `ibm-i-rpg-standards`, `vb6-standards` (**they are not comparable**: those are
platforms with no choice; Smalltalk still has a community, releases and a possible decision).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Choice | Verified note (Aug 2026) |
|---|---|---|
| Default free implementation | **Pharo** | Stable **13.1.0** (26-Jun-2025). **Pharo 14 is delayed**: the project itself published on 29-Jun-2026 that *"our usual April–May release did not happen this year"*. **Plan on 13, not on 14** |
| Pharo license | **MIT with parts under Apache** — read raw from the `LICENSE` | *"Licensed under the MIT License with parts under the Apache License."* **It is not plain "MIT"**: if you are going to redistribute, review the Apache parts (patent notice and `NOTICE`) |
| Squeak | **Research, teaching and historical compatibility** | **Declared discrepancy**: the downloads page gives **Squeak 6.0** as the *Current Release* (build 22156, images regenerated in Jun 2026), but the site also publishes release notes for **6.1**. Confirm which one is current before pinning it (§8) |
| Cuis Smalltalk | Minimalist alternative to Squeak, small and clean core | A reasonable choice for teaching and small embedded systems; a much smaller ecosystem |
| Object persistence | **GemStone/S 64 Bit** (GemTalk Systems) — **the strongest commercial case** | **3.7.5, March 2026**. Transactional, multi-user object database with Smalltalk inside: persistence is transparent and that is the value. **License**: a free or low-cost *Community/Web Edition* **that allows commercial use in production**, and a bespoke perpetual *Enterprise*. **Read the keyfile and the terms: the capabilities depend on the license** |
| Cross-platform commercial | **Cincom Smalltalk** (VisualWorks + ObjectStudio) | A live commercial platform; public documentation around release **9.5**. **Gap: it does not publish rates** (§8) |
| Enterprise commercial | **VAST Platform** (Instantiations, ex VA Smalltalk) | **2026 = v15.0.0, published 18-Feb-2026**; sustained annual cadence (2025 = 14.x, 2024 = 13.x). It uses **ENVY** as the historical repository and has been improving its **Tonel** support for working against Git. **Gap: it does not publish rates** |
| Dolphin Smalltalk | Windows only; **not for new projects** | Verify its maintenance status before even considering it |
| VM | **OpenSmalltalk VM** for Pharo/Squeak/Cuis | It is the common VM of the free world; its release constrains which image you can run |
| Version control | **Git, with Iceberg and the Tonel format** (one file per class, one directory per package) | **Mandatory.** It is what makes the diff reviewable and the repository compatible with the rest of the world |
| Monticello (`.mcz`) | **Historical only**: reading old repositories | It is a binary per-package format: it gives no reviewable diffs and does not integrate with Git. **Migrate to Tonel** any repository that is still being touched |
| Dependency management | **Metacello with `BaselineOf`** (not `ConfigurationOf`, which is the old model) | External dependencies are pinned **by commit or tag**, never by branch |
| Tests | **SUnit** (subclasses of `TestCase`) — the origin of xUnit | Run **headless** from the CLI, see §4 |
| CI | **smalltalkCI** | **Active** project (commits in August 2026; release **v3.0.8**, May 2026). It runs the suite headless on Pharo/Squeak/GemStone from a standard pipeline |

## 3. Structure and conventions

- **The source code lives in Git in Tonel format, and the repository is the truth. The image is a
  product of the build.** This inversion is the whole modernization of the platform in one sentence, and it is
  the criterion that §4 and §7 depend on. A project that keeps distributing `.image` as the primary
  artifact and `.changes` as history has no version control: it has a backup.
- **One package = one loading unit with `BaselineOf`.** No circular dependencies between packages.
  Tests go in a separate `-Tests` package, which is not loaded into the production image.
- **Names**: project prefix in class names (there are no real namespaces in classic
  Smalltalk: `Foo` collides globally and the second `Foo` that gets loaded **silently overwrites the
  first**). Selectors that read like a sentence; short methods; categories/protocols
  maintained, because they are the real navigation of the system.
- **Extensions to system classes (*monkey patching*): permitted by design, and dangerous for
  the same reason.** Rule: only in a protocol with **your project prefix** (`*MyProject`), so
  that the extension travels with your package and not with the base class; never modifying an
  existing method of the base class; and zero extensions that change inherited behaviour. An extension
  that alters `Object` or `Collection` is a global failure that will show up in another package.
- **`doesNotUnderstand:` for proxies and DSLs: with written justification.** It turns compilation
  errors into runtime behaviour and destroys reference navigation.
- **`become:`, `thisContext` and stack reflection are tool-builder's tools**,
  not application code tools. They are vetoed outside infrastructure, with a reason.
- **No "code that only exists in my image".** Every change is saved into the package and
  committed; the `.changes` is a safety net against a crash, not a history.

## 4. Quality, tests and CI (the image problem)

**The axis of this section: the image breaks every assumption of a modern delivery chain**, and
they have to be compensated for explicitly.

- **The image is accumulated mutable state**: it contains everything that went through that session —definitions
  already deleted from the files, live objects, and **any secret that was read or typed**.
  It is not reproducible by construction, it is not diffable and it is not auditable.
- **Non-negotiable rule**: the production image is generated **from a published base image, in
  a headless process, loading the code from Git via Metacello, in a single repeatable step**.
  Never from anyone's working image.
- **Minimum CI gate**, in increasing order of cost: (1) the baseline **loads clean** in a freshly
  downloaded base image, with no dialogs and no errors; (2) **headless SUnit** with `smalltalkCI` and a
  non-zero exit code on failure; (3) the Tonel tree has no uncommitted changes after loading
  (it detects code that only existed in someone's image); (4) the production image is
  built and starts. Add the environment's own quality rule analysis where it exists
  (in Pharo, the *Quality Assistant*/Renraku critiques) as a warning, not as an initial block.
- **Modal dialogs are the enemy of CI**: any load that asks something (an Iceberg
  conflict, a credential, an update) hangs the pipeline with no useful message. The whole startup runs with
  explicit configuration and no interaction.
- **Tests**: observable behaviour, with coverage of edges and errors. Watch out for the local vice of
  **tests that depend on the state of the image** (class variables, singletons, registered
  objects): real `setUp`/`tearDown` and an execution order that does not matter.
- **Zero secrets in the build environment**: they would end up inside the image binary.

*§6 is deliberately omitted*: the observability, the limits and the capacity of a Smalltalk
service are governed by `observability-standards` and by the deployment platform's skill; the
only thing specific to this one —image, headless startup, GemStone— is in §4 and §5.

## 5. Stack security

- **The image is a sensitive and opaque artifact**: it holds credentials, tokens and data that have
  passed through memory. Treat it as a secret at rest (encrypted, with restricted access), not as
  just another binary, and **regenerate it**, do not patch it.
- **The "server" is the whole image**: in Smalltalk, exposing a service means the exposed
  process contains the compiler, the browser and full reflection capability. An RCE is not an
  escalation: it is complete access to the system from the first step. Consequences:
  - **The production image is deployed without development tools loaded** when the
    implementation allows it, and **with no remote console exposed**.
  - **Any remote code evaluation channel (remote workspace, an endpoint that compiles or
    evaluates expressions) is forbidden in production.** It is the exact equivalent of leaving swank or
    an `eval` open.
  - Always serve behind a reverse proxy, listening on localhost, with TLS terminated outside.
- **Run as an unprivileged user, with a read-only filesystem except for the working
  directory**: the image rewrites itself if you let it (`Smalltalk snapshot`).
- **Dependencies**: Metacello loads **from third-party Git repositories**, and in Smalltalk loading
  code *is executing it* (class methods run on load). **Pin by commit, never by
  branch**; review what you load; the ecosystem is small and there is no audit process and no signatures.
- **GemStone**: authorization belongs to the object server, not to the application. Named accounts,
  minimal and audited; `topaz` and administrative sessions, restricted. Backup and **tested
  restore** (see `backup-recovery-standards`).

## 7. Sustainability, migration and prohibitions

**Decision criteria** (before writing or rewriting, in writing):
1. **Is it maintenance or is it new?** Maintaining and extending a healthy Smalltalk system is correct and
   is usually by far the cheapest option. **Rewriting it "because it is Smalltalk" is the decision that
   destroys value** — the system encapsulates decades of business rules not specified anywhere
   else.
2. **Can you cover the succession?** It is the dominant constraint and it is honest to acknowledge: the market
   is tiny. The viable answer is almost never to hire Smalltalkers: it is to **train** good
   people (it is learned fast: the language is tiny) and to **document** the startup, the build and the
   deployment so that they do not depend on anyone's memory. Budget for it.
3. **What justifies staying?** The live debugger, GemStone's persistence or the cost of the
   alternative. If none of that applies and the system is small, migrating is defensible.
4. **If you migrate**: **never *big bang*, never automatic translation**. Encapsulate behind a stable
   interface (HTTP/gRPC), build the new thing outside against it (*strangler fig*) and replace **by
   domain**. The destination is governed by the destination language's skill.

**Prohibitions:**
- ❌ **FORBIDDEN** to treat the `.image` as the primary code artifact or the `.changes` as
  version history. The Git repository in Tonel is the truth (§3).
- ❌ **FORBIDDEN** to deploy an image that does not come out of a reproducible headless build from Git; or
  to build it from a developer's working image.
- ❌ Secrets in the build environment or present in the delivered image.
- ❌ Any remote code evaluation channel in production (§5).
- ❌ Metacello dependencies pinned by branch instead of by commit or tag.
- ❌ New repositories in Monticello (`.mcz`); keeping in Monticello anything that is still being touched.
- ❌ Extensions to system classes outside a protocol with your own prefix, or that modify
  existing behaviour.
- ❌ `become:`, `thisContext` or `doesNotUnderstand:` in application code without written justification.
- ❌ New classes without a project prefix (silent global collision).
- ❌ CI loads that can open a modal dialog.
- ❌ Tests that depend on the accumulated state of the image.
- ❌ **Choosing Smalltalk for a new product that a third party will maintain, without a written reason from
  those in §1 and without a succession plan.** And, symmetrically: **rewriting a healthy Smalltalk system just because of
  the language.** Both are the same error of judgement in opposite directions.
- ❌ Committing to Cincom, VAST or GemStone Enterprise without the license cost **and the renewal cost**
  in writing; or assuming that GemStone's *Community Edition* covers your case without reading the keyfile.
- ❌ Assuming that Pharo is "MIT": the `LICENSE` says **MIT with parts under Apache** (§2).

## 8. Mandatory web verification

1. **Pharo**: current stable version (as of Aug 2026, **13.1.0** of Jun 2025) and **the real status of
   Pharo 14**, announced as delayed on 29-Jun-2026. Do not plan on an unpublished
   release. License read raw from the `LICENSE`.
2. **Squeak — declared discrepancy, resolve it before pinning a version**: the downloads page
   presents **6.0** (build 22156) as the *Current Release*, while the site publishes release notes
   for **6.1**. Check which one is recommended and which VM (OpenSmalltalk) it requires.
3. **GemStone/S 64 Bit**: current version (as of Aug 2026, **3.7.5** of March 2026), support
   calendar for the one you use, and **the exact terms of the license you are applying** (Community/Web
   allows commercial use in production with limits; Enterprise is bespoke). Read them, do not assume them.
4. **VAST Platform**: current version (as of Aug 2026, **15.0.0** of 18-Feb-2026) and its cadence.
   **Cincom Smalltalk**: current release (public documentation around **9.5**).
   **Declared gap in both: they do not publish rates.** Any cost figure has to come from
   a contractual quote — and the **renewal** cost is the data point that gets forgotten.
5. **OpenSmalltalk VM**: current release and which images it supports; it is what limits which version
   you can move up to.
6. **smalltalkCI**: version and supported platforms (as of Aug 2026, **v3.0.8** of May 2026, with
   commits in August 2026).
7. **Iceberg and Tonel**: support status in your implementation —especially in VAST, where
   the bridge between ENVY and Tonel is what decides whether you can really work against Git.
8. CVEs and advisories for the VM, for the HTTP/TLS stack you embed and for the Metacello libraries you load.
9. **Dolphin Smalltalk**: current maintenance status, before considering it for anything.

If the web contradicts this document, **the web wins** — flag the discrepancy.
