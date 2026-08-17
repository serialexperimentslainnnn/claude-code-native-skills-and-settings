---
name: lean-code-standards
description: Use when deciding how much code to write, in any language — whether a wrapper, adapter, interface with one implementation, factory, config flag, extra layer or defensive branch is earned yet, and whether a diff is adding indirection, unused parameters, speculative generality or unmeasured optimisation. The smallest correct solution wins by default.
---

# Lean code standards — the code you did not write has no bugs

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: a capable writer does not fail by writing badly, it fails by **writing more**. The
> extra layer, the flag nobody sets, the defensive branch the type system already forbids — all
> competent, all passing tests, all **arriving looking finished**. That is the expensive defect:
> nobody re-reads code that looks done.

## 1. Scope and triggers

Applies at **the moment of authorship, before the code exists**: deciding what to write, what to
leave out, whether an abstraction is earned yet, and whether the thing should be written at all.
Applies to **every language** — it decides quantity and shape, never syntax.

**Name it by slug in every brief that produces code.** Its triggers are *shapes* (a wrapper, a
one-implementation interface, a config flag), never artifacts — it applies to all of them — so a task
described in domain terms may not fire it on its own.

**Not applicable**: `refactoring-tech-debt-standards` owns **code that already exists** — debt
registers, legacy, characterisation tests, strangler migrations; the boundary is temporal, before
versus after the code exists. `code-review-standards` owns **judging someone else's diff** and what
blocks a merge; here, what never reaches the diff. `performance-engineering-standards` owns **proving
why something is slow** — percentiles, load generation, profiling — and therefore owns every
optimisation this document permits. `software-architecture-patterns-standards` owns the **style
choice** (modular monolith, hexagonal, event-driven); here, the layer *inside* it that was not
earned. `testing-qa-standards` owns **what to test and in what proportion**; here only that a test
asserting on its own mock is bloat. The **language skills** own idiom, formatter, linter config and
type system; here only how much code gets written in them.

## 2. Default decisions — the tie-breakers

> Verify tool names and flags on the web before pinning them in a real project (§8).

| Decision | Rule | Why |
|---|---|---|
| Size vs speed | **Smallest correct solution wins by default** | An optimisation without a measurement is a guess that costs branches, state and bugs forever |
| When to optimise | **Only with a measurement that justifies it** — owned by `performance-engineering-standards` | "It might be slow" is not data. Being wrong costs permanent complexity |
| Build vs reuse | **stdlib > well-known dependency > own code** | Both directions need justification: adding a dependency **and** rewriting what stdlib already does |
| When to abstract | **One call site ⇒ no abstraction.** Rule of three before extracting | Two call sites is coincidence; the wrong abstraction is more expensive than duplication and much harder to undo |
| Configurability | **No flag, parameter or hook without a second consumer that exists today** | Anticipated consumers do not arrive, and the flag stays forever with both branches to maintain |
| Error handling | **Handle it where you can act; otherwise let it propagate** | A `try` that only re-raises adds a frame and hides the origin |
| Naming a thing | **The behaviour it has, not the pattern it uses** | `Manager`, `Helper`, `Util`, `Handler` name nothing and attract unrelated code |

**The governing sentence**: *as simple as possible, but no simpler*. **Effort goes into researching,
verifying and covering edge cases — never into inflating the solution.** Exhaustive work, simple
design.

## 3. Bloat catalogue — recognisable while writing, not in review

Named as they appear at the keyboard, because a pattern you must deduce is a pattern you will not
catch in time. **Language-neutral by construction**: each names the shape, then how it spells itself
in a few of the ~50 languages this catalogue covers. The shape is the pattern; the spelling varies.

- **Wrapper with a single implementation** — one implementer behind a Java/C# `interface`, a Go
  `interface`, a Python `Protocol`/ABC, a C++ pure-virtual base, a Rust `trait`, a TypeScript
  `interface`, a factory returning one type. Write the concrete thing; extract when the second
  arrives.
- **Defence against states the type already forbids** — a nil/None/null check on a non-nullable, a
  `default:` on an exhaustive `match`/`switch`, re-validating what the caller validated. Validate
  **at the edges**, once.
- **Catch that only re-raises** — `try/except: raise`, `catch (e) { throw e; }`, `if err != nil {
  return err }` adding nothing, a `Result` unwrapped and rewrapped unchanged. And its twin, **the
  swallow**: `except: pass`, `catch {}`, `_ = err`, `rescue nil` — a failure converted into wrong
  behaviour later.
- **Comment restating the line below.** A comment earns its place explaining **why**, never what.
- **Doc comment on a trivial private helper** — docstring, javadoc, `///`, `--`. The signature says it.
- **Flag nobody sets** — parameter, env var, build tag, `#ifdef`, `if DEBUG` with one real branch.
- **Reimplementing the standard library** — hand-rolled sort or grouping, path building by string
  concatenation, a hand-made value type where the language has `dataclass`/`record`/`struct`/`case
  class`. Check the stdlib before writing an algorithm.
- **Enterprise pattern in a 200-line program** — builder for three fields, registry with one entry,
  DI container for a single call, event bus between two functions, `AbstractSingletonProxyFactoryBean`
  energy in a script.
- **Parameters nobody passes**, and pass-through-only variadics: `**kwargs`, `...args`,
  `params object[]`, `va_list` that only forward.
- **Test asserting on its own mock** — proves the mock was configured, nothing about the code.
- **Accessor with no logic** where the language has fields, properties or attributes.
- **Near-identical blocks that should be data** — three branches differing in one string are a table.
- **Premature `async`/goroutines/generics/caching/batching** with no measured need.
- **A layer that only forwards** — a module, package or class whose every function calls one function
  of the next with the same arguments.

**Legacy languages get the same rule, not a softer one** (COBOL, RPG, ABAP, MUMPS, VB6, Classic ASP,
Delphi): there the dominant bloat is **copy-paste divergence** — near-identical paragraphs, programs
or forms that drifted. The fix is the same test in §4, and the extra constraint that the surrounding
style is honoured rather than modernised in passing.

## 4. Verification — how it is checked, not how it feels

- **The deletion test, and it is the strongest one**: remove the construct and see whether anything
  breaks. If everything still works and reads no worse, **it was bloat**. Applies to a parameter, a
  branch, a layer, a comment, a whole file.
- **Count the call sites** before extracting anything: `grep -c` on the symbol. One ⇒ inline it.
- **A diff that adds an abstraction names its second consumer**, in the diff, by name. Cannot name
  one ⇒ it is not earned yet.
- **Complexity and length are signals, never targets**: a long function that reads top-to-bottom is
  better than five helpers used once. Chasing the metric produces the indirection this document
  forbids.
- **Dead-code detection is a tool job, and the tool belongs to the language skill** — verify the
  current one on the web (§8) rather than assuming; what is decided here is that the finding is
  **removed, not documented**.

## 5. Security — what is never bloat, under any reading

**This is the section that keeps the document from turning against itself.** A misapplied minimalism
deletes exactly what protects, calls it simplicity, and passes review because the code got shorter.

**Never removable as bloat, in any language, at any size:**

- **Input validation at the trust boundary** — including when "the caller already validates".
- **Authorisation checks.** One removed check is not less code, it is a vulnerability.
- **Error handling that acts**: closing a resource, rolling back, returning a correct status.
- **Resource release** (`with`, `defer`, RAII) — never "simplified" into a manual close.
- **Parameterised queries.** Concatenating is shorter and is the vulnerability.
- **The logs and metrics that make a service operable** (§6).

**Less code is less attack surface only when what is removed was not defence.** When in doubt about a
guard: it stays, and the doubt goes in `NOTES` for the level above.

## 6. Performance and operability

- **Minimal code is not minimal work.** An `O(n²)` hidden in a nested comprehension is short and
  expensive; a `SELECT` inside a loop is one line and an outage. **Short is not the goal, unnecessary
  is the enemy.**
- **Bounded inputs and outputs**: no unbounded read, no unlimited concurrency, no retry without a
  ceiling. These bounds are not bloat, they are what keeps the process alive.
- **Timeouts on everything that crosses a process boundary.** A missing timeout is not simplicity, it
  is a hang.
- **Observability is not decoration**: a service with no metric and no actionable alert is not
  deployed, it is abandoned. What *is* bloat is the log nobody reads and the metric nobody alerts on.

## 7. Sustainability and prohibitions

- ❌ **Abstracting for a future requirement.** It does not arrive, or it arrives different.
- ❌ **Copying a pattern because it is common** rather than because this code needs it.
- ❌ **"Improving" code outside the assigned scope.** Report it; do not touch it.
- ❌ **A configurability option with no consumer today.**
- ❌ **Comments explaining what the code says.**
- ❌ **Deleting validation, authorisation, resource release or bounds in the name of simplicity** (§5).
- ❌ **Optimising without a measurement**, and equally ❌ **writing knowingly quadratic code because
  "it is simpler"** without saying so.
- **Deliberate exception**: a shortcut may be taken **with the reason written down** — `TODO` naming
  what it costs and what would trigger fixing it. Silent accidental complexity does not get that
  privilege.

## 8. Mandatory web verification

Before pinning anything: current name and flags of the dead-code and complexity tooling for the
language in play, whether the function used is still the stdlib's recommendation (they get
deprecated), and the current status of any dependency proposed instead of own code — licence,
maintenance, last release.

If the web contradicts this document, **the web wins** — flag the discrepancy.
