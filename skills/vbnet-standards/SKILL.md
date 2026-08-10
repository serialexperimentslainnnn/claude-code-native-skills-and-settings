---
name: vbnet-standards
description: Visual Basic .NET as a frozen-but-supported language, and the stay-or-convert-to-C# decision. Use when editing .vb files, a .vbproj project, My.Settings/My.Resources/My.Application code, Option Strict / Option Explicit / Option Infer / Option Compare directives, Microsoft.VisualBasic namespace calls (CInt, CType, IsNothing, Mid, Left, InStr, Format, MsgBox, InputBox, IIf, On Error Resume Next, Err.Number), Handles and WithEvents, Module and Sub Main in VB, ByRef/ByVal parameters, VB WinForms designer files (.Designer.vb, Form1.vb), Microsoft.VisualBasic.FileIO.TextFieldParser, and when choosing VB templates in dotnet new (classlib, console, winforms, wpf) or evaluating a VB-to-C# converter such as ICSharpCode CodeConverter.
---

# Visual Basic .NET standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**VB.NET** code (`.vb`, `.vbproj`), whether it runs on .NET Framework 4.x or on modern .NET, and the
decision to keep it or convert it. Triggers: `Option Strict`/`Explicit`/`Infer`/`Compare`,
the `Microsoft.VisualBasic` namespace, `My.*`, `Handles`/`WithEvents`, `On Error Resume Next`,
`.Designer.vb`, `Module`, `MsgBox`, `TextFieldParser`.

**The axis: VB.NET is supported, but frozen.** That is not the same as dead and not the same as
alive. Microsoft's statement (Visual Basic team blog, **11-Mar-2020**), **verbatim**:

> "One of the major benefits of using Visual Basic is that the language has been stable for a very
> long time. The significant number of programmers using Visual Basic demonstrates that its
> stability and descriptive style is valued. **Going forward, we do not plan to evolve Visual Basic
> as a language.** This supports language stability and maintains compatibility between the .NET
> Core and .NET Framework versions of Visual Basic. Future features of .NET Core that require
> language changes may not be supported in Visual Basic."

The practical consequence, which is the one that decides: **the compiler and the runtime do evolve;
the language does not.** Everything that reaches the platform and needs new syntax — records, modern
pattern matching, nullable reference types, idiomatic `Span<T>`, top-level statements, source
generators with their own syntax — reaches C# and **does not reach here**. VB consumes what it can
from libraries; what demands grammar, it does not. This is not an opinion about the language: it is
the design constraint you plan with.

**Not applicable**: `dotnet-standards` decides **the modern .NET platform** — SDK, TFM, LTS, NuGet,
ASP.NET Core, EF Core, publishing, testing, CI — and **it owns the destination if you convert to
C#**: the quality of the resulting C# is governed by its criteria, not by the ones here. Here, only
the VB language and the decision.
`dotnet-framework-legacy-standards` decides the **4.x platform** and the port to modern .NET
(WebForms, WCF, `packages.config`, SDK-style): if the problem is "I cannot get off 4.8", it is
theirs; if it is "how is this `.vb` written", it is ours. A `.vbproj` on `net48` touches both: **the
project and its TFM there, the code here.**
Sisters: `vb6-standards` (VB6 is **another language and another runtime**, with no CLR — the
syntactic similarity is a trap) and `classic-asp-standards` (server-side VBScript, also not this).
`legacy-modernization-standards`: portfolio strategy, with
`enterprise-architecture-standards`, `project-management-standards` and `tech-leadership-standards`.
Also `refactoring-tech-debt-standards` (safe conversion), `testing-qa-standards` (the net that makes
it defensible), `sql-standards` and `sqlserver-dba-standards` (the embedded SQL, which here is
usually half the code), `appsec-standards`, `cicd-standards`, `git-workflow-standards`.

## 2. What is supported today — default decisions

> Verify on the web before pinning it in a real project (§8).

**VB project templates in the modern SDK.** Official `dotnet new` table, *Language* column,
**verbatim** in what matters: `classlib` → `[C#], F#, VB`; `console` → `[C#], F#, VB`;
`winforms` and `winformslib` → `[C#], VB` (*Introduced*: `3.0 (5.0 for VB)`); `wpf`, `wpflib`,
`wpfcustomcontrollib`, `wpfusercontrollib` → `[C#], VB`; `mstest`, `mstest-class`, `nunit`,
`nunit-test`, `xunit` → `[C#], F#, VB`.

**Declared discrepancy — important.** The 2020 announcement promised **verbatim** these project
types for VB in .NET 5: *"Class Library, Console, Windows Forms, WPF, Worker Service, ASP.NET
Core Web API"*. The current SDK template table **does not list VB** either in `worker` (`[C#]`) or
in `webapi` (`[C#], F#`). That is: **what was promised in 2020 is not in today's templates**. It
does not necessarily mean the compiler prevents it — you can start from a VB `classlib` and
reference ASP.NET Core by hand — but **without a template there is no supported path**: any plan
that assumes "web API in VB" must be verified with `dotnet new list --language VB` on the real SDK
before committing to it.

| Decision | By default | Justifiable alternative |
|---|---|---|
| Area for **new** VB.NET | **None**: no new project is started in VB | A module inside an existing VB solution that a VB team maintains |
| Viable app type | **WinForms/WPF** desktop, libraries, console, tests | Service/worker/API: only after verifying the SDK; by default, C# |
| Target platform if ported | `net10.0-windows` (WinForms/WPF) or `net10.0` | `netstandard2.0` while it coexists with 4.x |
| Mixed solution | **Yes**: VB and C# coexist per project | — |
| Conversion to C# | Only with an explicit reason (§5) | Keep VB if the team maintains it well |

**C#/VB.NET interoperability**: both compile to the same IL and one solution can have projects of
both. **The boundary is per project, not per file**: a `.vbproj` does not accept `.cs` or vice
versa. Criteria: if you convert, you convert **project by project**, leaving the solution compiling
and green at every step — never file by file with the solution broken. New code goes into new C#
projects that reference the existing VB ones; that is already an incremental migration without
touching a line of VB.

## 3. The non-negotiable baseline: `Option Strict On`

`Option Strict Off` and `Option Explicit Off` are VB's historical default and **the cause of most
of this ecosystem's bugs**. With them, the compiler accepts lossy implicit conversions, binds at run
time (*late binding*) and creates variables by mistyping them. The result: type errors that show up
in production with real data instead of at compile time.

- **`Option Strict On` and `Option Explicit On` in every project**, at `.vbproj` level, not file by
  file. `Option Infer On` is acceptable and desirable.
- Turning it on in a code base that is currently `Off` produces hundreds of errors. **That is not a
  reason not to do it**: it is the real measure of the debt. Route: project by project, from the one
  with the fewest dependencies upwards, with every explicit conversion reviewed — before, the
  runtime made it blindly.
- **`DirectCast` versus `CType`**: the first fails if the type is not the expected one, the second
  tries to convert. By default `DirectCast` (or `TryCast` checking for `Nothing`): let it fail early.
- ❌ `On Error Resume Next`/`GoTo` → `Try/Catch/Finally`. A `Resume Next` is a global empty `catch`:
  it swallows errors and leaves the state half-done.
- ❌ Comparing strings with `=` depending on `Option Compare Text`: set `Option Compare Binary` and
  use `String.Equals(..., StringComparison...)`.
- `Nothing` is not C#'s `null` in every context (on an `Integer` it is `0`): a classic trap at the
  boundary with C# and in automatic conversion. `Is Nothing`, reference types only.

**`Microsoft.VisualBasic`**: it exists in modern .NET (`Microsoft.VisualBasic.Core`), but **not
everything survives**: `ApplicationServices`, `Devices` and `MyServices` — the ones that hold up
`My.Application`, `My.Computer` and company — had a gap in .NET Core 3.x, and their state per
version must be **verified on the VB breaking-changes page before porting** (§8). Criteria: in code
that is going to be ported, **replace the compatibility functions (`Left`, `Mid`, `InStr`, `Format`,
`IIf`, `MsgBox`) with their BCL equivalents**. This is not purism: `IIf` evaluates both branches and
`MsgBox` ties you to Windows. `TextFieldParser` is still available and is useful: do not reinvent it.

## 4. Quality and testing

The gates from `dotnet-standards` apply (Roslyn analyzers, `.editorconfig`, SCA, CI). Specific to
here, and all of it must **break the build**:

- `Option Strict On`/`Explicit On` verified in the `.vbproj`, not just in the file.
- `<TreatWarningsAsErrors>` on; in VB, implicit-conversion warnings are the real finding.
- **Coverage before converting**: without a test suite over observable behaviour, a conversion to C#
  is neither defensible nor verifiable. The strategy is set by `testing-qa-standards`;
  here the rule is hard: **the net first, the conversion after**.
- `.Designer.vb` files are generated: they are not edited by hand nor reviewed as code.

## 5. Migration to C# — honest criteria

**Converting is not modernising.** Automatic converters (ICSharpCode CodeConverter and similar)
produce C# that **compiles but is not idiomatic**: `Nothing` mistranslated, `On Error` turned into
empty `try/catch`, `IIf` into calls that evaluate both branches, properties and events with machine
names. What comes out is a C# code base nobody wrote and nobody wants to maintain. If the goal was
"so the team can hire people", that result does not achieve it.

- **Yes** when: the application is going to keep evolving and needs features that require syntax;
  it has to be unified with an already-majority C# code base; or the required project type **has no
  VB template** (web, worker — §2).
- **No** when: it is stable, the team maintaining it knows VB and does a good job, and there is no
  roadmap. VB.NET is **supported**; frozen is not a security risk in itself. Converting
  for aesthetics is spending budget on zero value.
- If you convert: **project by project**, a green suite before and after every step, and a human
  review pass that **rewrites what the converter left ugly** — budget for it explicitly;
  without it the result is new debt with different syntax. **Never** convert and port
  platform in the same commit: if something breaks, you will not know which of the two it was.

## 6. Stack security

There is no attack surface specific to the language: `appsec-standards` rules and, on 4.x,
`dotnet-framework-legacy-standards` (`BinaryFormatter`, `machineKey`, TLS). Specific to VB:
**`Option Strict Off` is a security problem**, not just a quality one — *late binding* lets a
string decide which member gets invoked —; **SQL by concatenation** (`"... WHERE id=" &
txt.Text`) is the dominant pattern in legacy VB code and its only fix is `SqlCommand` with typed
`Parameters.Add` (`sql-standards`); and `My.Settings` with passwords or connection strings is
cleartext configuration inside the artifact: out, to `secrets-management-standards`.

## 7. Long-term sustainability and prohibitions

Cadence: the application is kept on the highest supported TFM its platform allows;
NuGet dependencies are updated with the same cadence as a C# project. **The language being frozen
does not freeze the runtime or the dependencies** — that is the characteristic maintenance mistake
of these code bases: they stop being updated "because VB does not change any more".

- ❌ FORBIDDEN `Option Strict Off` or `Option Explicit Off` in any project, new or legacy.
- ❌ FORBIDDEN `On Error Resume Next` / `On Error GoTo`.
- ❌ FORBIDDEN *late binding* over `Object` to access members.
- ❌ FORBIDDEN SQL by string concatenation.
- ❌ FORBIDDEN starting a **new** project in VB.NET outside an existing VB solution.
- ❌ FORBIDDEN shipping the output of an automatic converter without the human rewrite pass.
- ❌ FORBIDDEN converting to C# without a prior test suite over observable behaviour.
- ❌ FORBIDDEN editing `.Designer.vb` by hand.
- ❌ FORBIDDEN claiming VB.NET "is not supported": it is (§1); what it does not get is new language.
  Selling a migration with that argument sinks it at the first review.

## 8. Mandatory web verification

Check: whether Microsoft has published **anything after March 2020** that changes or qualifies the
language-freeze statement (it is the fact that holds up this whole skill); which VB templates the
installed SDK lists (`dotnet new list --language VB`) against the official table, and whether the
§2 discrepancy about `worker`/`webapi` has been resolved either way; the state per version of
`Microsoft.VisualBasic.ApplicationServices`, `.Devices` and `.MyServices` on the VB breaking-changes
page; the current .NET LTS version and its end-of-support date (set by
`dotnet-standards`); CVEs of the NuGet dependencies.

**Declared gaps (no verified data, do NOT fill in from memory)**: not verified as of Aug 2026 whether
a support statement for the **VB.NET language with an end date** exists — as of today there is none
on record, and the absence of a date **must not be written as if it were an indefinite guarantee**;
maintenance state and output quality of the specific VB→C# converters; real availability (not
template availability) of ASP.NET Core and Worker Service in VB on the current SDK; the percentage of
the .NET code base written in VB — there is no reliable public figure, do not cite one.

If the web contradicts this document, **the web wins** — flag the discrepancy.
