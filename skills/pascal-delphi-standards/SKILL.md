---
name: pascal-delphi-standards
description: Object Pascal in production - Embarcadero Delphi and Free Pascal/Lazarus, and the migrate/wrap/freeze decision. Use when working with .pas/.dpr/.dpk/.dfm/.fmx/.dproj/.groupproj Delphi files or .lpr/.lpi/.lfm/.lpk Lazarus files, the RAD Studio IDE and its Florence/Athens/Sydney/Berlin/Tokyo releases, dcc32/dcc64/msbuild command-line Delphi builds and .dcu/.bpl output, fpc and lazbuild, VCL versus FireMonkey/FMX, TForm/TDataModule/TComponent and published properties with RTTI, third-party VCL component packages and their .bpl runtime packages, string/AnsiString/UnicodeString/WideString and the Delphi 2009 Unicode break, PChar and PAnsiChar, ShortString, TStringList, BDE and IDAPI.CFG legacy data access, dbExpress, FireDAC with TFDQuery and FDConnectionDefs.ini, ADO/ODBC layers, exports and stdcall/cdecl DLL interop, COM/ActiveX with TypeLib, Delphi Community Edition eligibility and RAD Studio per-developer licensing cost, Lazarus LCL widgetset cross-compilation, or evaluating a Delphi codebase for rewrite to .NET.
---

# Object Pascal standards (Delphi and Free Pascal/Lazarus)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Object Pascal** applications in production: maintenance, containment and exit. Two worlds that
share a language and almost nothing else — **Delphi** (Embarcadero, commercial, paid per developer) and
**Free Pascal + Lazarus** (free).

**An honest statement of the domain, here and not hidden in §7**: Delphi **is not dead** — there are recent
releases, with a new compiler for Windows on Arm and up-to-date Android support (§2) — but **its
ecosystem has been shrinking for decades**: market share is marginal, hiring is difficult
and expensive, the third-party component catalogue is full of abandoned pieces that whole
applications depend on, and **the licence cost per developer is four figures a year** (§2).
On the free side the diagnosis is different and equally uncomfortable: **the latest stable version of Free
Pascal is 3.2.2, from May 2021**, and Lazarus keeps publishing bugfixes built on top of it. It
is not abandonment — there is continuous activity — but **the free compiler's release cadence is measured
in years**, and that is a risk fact to put on the table before betting.

Translated into criteria: **a Delphi application that works and does not grow gets maintained; one that grows
needs an explicit plan** (§7). And **starting a new project in Delphi is justified only if you already
have the team, the licences and a codebase to reuse** — never by choosing it from scratch.

Covers: versions and licences of both chains, file types, VCL versus FMX, the Unicode
scar, data access, interoperability, and the decision to migrate, wrap or freeze.

**Not applicable**: see `vb6-standards` and `classic-asp-standards` (**Microsoft legacy from the same
era**: they share the "1990s desktop app that still bills" pattern, **not the
platform** — Delphi compiles natively, has a compiler and IDE with current support and a company
behind it charging for them; VB6 has none of the three. **Do not extrapolate criteria between
them**), `dotnet-framework-legacy-standards` (.NET Framework 4.x: the intermediate step in the Microsoft
world), `dotnet-standards` (**the most common destination of a rewrite, and the owner of the
criteria for the resulting code** — SDK, TFM, ASP.NET Core, EF Core, packaging — **not this skill**),
`legacy-modernization-standards` (**theirs is the strategy** — portfolio analysis, the decision to
invest/migrate/retire/freeze, sequencing, funding; **here the technical criteria of this
platform and the facts that feed that decision**), `migration-projects-standards` (**theirs is the
execution of the cutover** once decided: runbook, rehearsal, window, abort criteria, a rehearsed
rollback and decommissioning of the source system),
`refactoring-tech-debt-standards` (*strangler fig*, branch by abstraction, characterisation of untested
code), `enterprise-architecture-standards` (inventory, the TIME model),
`testing-qa-standards` (test strategy), `cicd-standards` (the pipeline),
`git-workflow-standards` (**and especially handling binaries and generated files**),
`sql-standards` and `sqlserver-dba-standards`/`oracle-dba-standards`/`mysql-mariadb-dba-standards`
(the engine behind FireDAC), `api-design-standards` (the contract of the service that wraps the
monolith), `appsec-standards` (threat modelling), `vulnerability-management-standards`,
`opensource-licensing-standards` (**FPC's RTL static-linking exception is the fact that
decides whether you can distribute closed source**, §2), `windows-server-ad-standards`,
`vmware-standards`/`hyper-v-standards` (the host of a frozen build machine),
`backup-recovery-standards` (**the build machine and its third-party components are an asset to be
backed up**), `c-standards`/`cpp-standards` (the other side of a native DLL).

## 2. Default decisions — versions, licence and cost

> Verify on the web before pinning it in any document with consequences (§8).

| Decision | Criterion | Verified as of Aug 2026 |
|---|---|---|
| Commercial Delphi | **RAD Studio 13.1 "Florence"** | RAD Studio/Delphi/C++Builder **13 "Florence"** shipped on **10 Sept 2025**; **13.1 (Release 1)** with an updated build on **18 Mar 2026**. Relevant new features: a **native Arm64EC Delphi compiler** (Windows on Arm, Arm64EC ABI → mixing with existing x64 binaries), **Android API 36.1** (required by Google Play from Aug 2026) and an LSP engine with LSIF |
| **Cost per developer — the expensive fact** | **Four figures per seat, and it is a named licence** | Starting prices for a **new licence** at a reseller (ComponentSource, Aug 2026): **Professional ≈ USD 1,583**, **Enterprise ≈ USD 3,959**, **Architect ≈ USD 5,939**. **Named User (Workstation)** model: one person, one machine, no concurrent use, **valid only in the country of purchase** (except for mobility within the EU). The subscription requires **annual renewal** to keep using the product. **List and reseller prices differ: request a quote (§8)** |
| Community Edition | **Fine for learning and for a micro-business; not for a company** | Free, a renewable 1-year licence, **until the individual's or company's annual revenue reaches USD 5,000** or the team exceeds **5 developers**. The threshold is on **total revenue**, not on what the app generates; a company billing more **cannot use it, not even internally**. **It is not a trial version** (there is a 30-day trial for that). **There is no RAD Studio CE**: only Delphi CE and C++Builder CE |
| Free Pascal | **FPC 3.2.2 — and that is the uncomfortable fact** | **3.2.2 is from May 2021** and is still the stable release; **3.2.4 exists only as an RC** (used for Lazarus's macOS builds). The project's site also warns that 3.2.2 is not available for every platform or format for lack of release builders and testers |
| Lazarus | **Lazarus 4.8** (bugfix) | **11 Jun 2026**, *"built with FPC 3.2.2, and FPC 3.2.4RC1 for macOS"* (verbatim from the project's site). A healthy bugfix cadence, on top of a compiler whose stable release does not move |
| FPC/Lazarus licence | **It permits a closed product — but read it, do not assume** | The **compiler and utilities are under the GPL**; the **RTL and the packages that end up inside your executable are under a modified LGPL with a static-linking exception**, and that exception is what makes distributing proprietary binaries legal. **Remaining obligations**: state where the RTL source can be downloaded from, and **publish your RTL modifications if you modified it**. Legal advice for the specific case |
| Choosing between them | **Delphi** if there is already a large VCL codebase, commercial components and budget; **FPC/Lazarus** if the criterion is zero cost, control of the chain or broad cross-compilation | Source compatibility is **good but not total** (`{$MODE DELPHI}`/`{$MODE OBJFPC}`); the commercial visual components and the newer parts of Delphi's RTL **do not port** |
| Data access | **FireDAC**. **BDE vetoed** | Embarcadero's DocWiki: the BDE **is deprecated and will not be improved** — *it will never have Unicode support* —, no new development should use it and you must migrate to FireDAC. Since XE7 (2014) it is not even installed with the product. Assisted migration with `reFind` and the rules file `FireDAC_Migrate_BDE.txt`; aliases move from `IDAPI.CFG` to `FDConnectionDefs.ini` |
| VCL versus FMX | **VCL** for Windows desktop; **FMX** only if there genuinely is cross-platform work | They are not interchangeable: switching framework **means rewriting the whole presentation layer**. "We move it to FMX and it is cross-platform" is false and is the promise that has sunk the most projects in this domain |

## 3. Structure, conventions and the Unicode scar

- **Files and what goes in Git**: `.pas` (unit), `.dpr` (program), `.dpk` (package), `.dfm`/`.fmx`
  (form, **save as text, never binary** — otherwise reviewing diffs and merging
  are impossible), `.dproj`/`.groupproj` (MSBuild project). In Lazarus: `.lpr`, `.lpi`, `.lfm`,
  `.lpk`. **Never in Git**: `.dcu`, `.ppu`, `.o`, `.exe`, `.bpl`, `.dproj.local`, `.identcache`,
  `__history/`, `__recovery/` and the output directory.
- **A reproducible command-line build**, not one from the IDE: `msbuild` over the
  `.dproj` (or `dcc32`/`dcc64` directly), `lazbuild` in Lazarus. **A project that only builds with
  the IDE open on somebody's machine does not have a build, it has a ritual.** And search paths
  are declared in the project, relative, not in each person's global IDE options.
- **Delphi 2009's ANSI→Unicode migration is the scar that still splits projects.** There `string`
  went from `AnsiString` to `UnicodeString` (UTF-16) and `Char` to 2 bytes. What still bites:
  **`Length(S)` is no longer bytes** (everything that assumed 1 byte = 1 character is wrong: `SizeOf(Char)` or
  `TEncoding`, never constants); **`PChar` became `PWideChar`**, so every call into the Windows API
  or into a third-party DLL has to be reviewed one by one; and above all **binary I/O and
  persisted structures**: writing a `string` to a file, socket or BLOB with pre-2009 code changes
  the on-disk format — **that is how this migration corrupts data, silently**. Operational rule:
  if the project has not crossed 2009, **that is a project of its own, with characterisation over real
  files and BLOBs**, not a step inside another one; and explicit `AnsiString`/`RawByteString` with a declared
  code page wherever the on-disk or on-the-wire format is bytes.
- **No logic in the form**: the business lives in units with no VCL dependency. That is what
  makes testing possible (§4) and what decides whether a future migration is even conceivable. A `TForm` of
  8,000 lines with SQL inside is the domain's default pattern and **it is the work to undo**.
- **Resources**: `try..finally` for every object created, always. And with interfaces, reference counting
  acts on the **interface**, not on the variable declared as a class: mixing both
  accesses to the same object is the classic leak.
- **Third-party components**: a written inventory with version, licence, source available yes/no and
  maintenance status. **A binary component with no source and no living vendor is a hard
  limit on portability and on compiler version**, and you need to know it before planning, not
  during.

## 4. Quality, tests and CI

A deliberately short section: this ecosystem's tooling is limited and it is better not to pretend
otherwise.

- **Tests**: **DUnitX** in modern Delphi (`FPCUnit` in Lazarus). A real precondition: **the logic
  must be outside the forms**; what lives in the `TForm` is not testable without a GUI and will not
  get tested.
- **Compilation as a gate**: a command-line build in CI, **warnings and hints treated as
  errors** in your own code, and **zero new warnings** as a merge rule. It is the static
  analysis you are guaranteed to have.
- **Analysis and style**: tools exist (IDE formatters, commercial analysers, and
  on the free side `pas2js`/FPC utilities), but **the linter ecosystem is poor compared
  with any mainstream stack**. Do not plan quality relying on tools you will not
  have: rely on review and on tests.
- **Inherited code with no tests**: characterisation first — capture real inputs and outputs
  (files, reports, rows) and freeze them as a reference — before touching anything.
- **§6 (Performance and operability) is omitted as artificial** in this domain: there are no operability
  decisions specific to Object Pascal that do not belong to the operating system, the data engine or the
  deployment, and those already have owners. The only specific parts — the 32-bit process, the installer and
  component registration — are covered in §7.

## 5. Stack security

- **The real surface is three things**: **SQL by concatenation** in old forms, **binary
  third-party components with no source and no patches**, and the **channel** — a client-server
  application talking to the database over the internal network without TLS.
- **Always parameterised SQL** (`TFDQuery.Params`). Here injection does not arrive over the web: it arrives through a
  field in a desktop form connected directly to the database.
- **Credentials**: out of the `.dfm`, the executable and any plaintext `.ini` next to the `.exe`. **And the
  application does not connect with a shared privileged user** — that inherited pattern is what
  turns any failure into total compromise.
- **Abandoned third-party components**: there are no patches. If one handles a file format,
  cryptography or a network protocol, **it is a vulnerability with no fix date**: wrap,
  replace or isolate (`vulnerability-management-standards`). No home-grown cryptography and no
  encryption components from the 2000s (`cryptography-pki-standards`).
- **Validation at the boundary**, including configuration files and imports: a
  `TStringList.LoadFromFile` over a file in a shared directory is untrusted input.

## 6. — omitted

See the note at the end of §4.

## 7. Migrate, wrap or freeze — and prohibitions

**The three routes, with the criterion for choosing:**

1. **Freeze**. The app works, does not change and the business asks nothing of it. It gets armoured: a
   reproducible command-line build, a build machine (with the IDE, licences and third-party
   components installed) **backed up as an image with a tested restore**, dependencies
   inventoried, and changes only for corrections or regulation. **It is the right option more often
   than people admit**, and it is not surrender: it is ceasing to pay to evolve something that does not need it.
2. **Wrap**. The app works but has to be integrated or given a new interface. The logic is exposed
   as a service (HTTP/REST from Delphi itself, or a DLL/COM consumed from .NET) and **everything
   new is built outside** against that contract — *strangler fig*, from
   `refactoring-tech-debt-standards`. **Precondition: the logic has to be outside the
   forms** (§3); if it is not, that is the first job, and it is the one that pays off for any
   subsequent route.
3. **Migrate**. Only when there is a real business reason (the Windows desktop no longer serves, there is nobody
   to hire, the licence cost is unsustainable) **and** budget to rewrite the whole
   presentation layer. **Domain by domain, never all at once.**

**On automatic Delphi→.NET converters**: they produce C# code with the structure of a
form-oriented Object Pascal program, with no idiom of the target and none of the equivalent
libraries. **It is not a migration, it is a translation you then have to maintain.** If it is used, it is as
scaffolding with a planned subsequent rewrite, and the result is governed by `dotnet-standards`.

**Hard signals that you have to get out** (not opinions, verifiable facts): the app depends on a
binary third-party component with no source whose vendor no longer exists; it only builds on one specific
machine that nobody knows how to reinstall; it is still 32-bit against a driver that no longer exists in 64-bit;
it has not crossed the Unicode barrier and internationalisation is needed; or **nobody is left on staff who
knows how to maintain it and the cost of hiring exceeds the cost of rewriting**.

**Prohibitions:**

- ❌ **FORBIDDEN**: new development with the **BDE**: deprecated by the vendor, with no Unicode and no
  future (§2). Migrate to FireDAC.
- ❌ Saving `.dfm`/`.lfm` in binary format.
- ❌ Committing `.dcu`, `.ppu`, `.exe`, `.bpl` or `__history`/`__recovery` directories.
- ❌ Projects that only build from the IDE, or that depend on absolute paths and on one particular
  developer's global IDE options.
- ❌ SQL by string concatenation; credentials in the `.dfm`, in the binary or in a plaintext
  `.ini`; a privileged database user shared by the application.
- ❌ Assuming `Length(S)` is bytes, or persisting a `string` to a file/BLOB/socket without explicit
  encoding (§3).
- ❌ Promising cross-platform by swapping VCL for FMX without budgeting the rewrite of the
  presentation layer.
- ❌ Adding a third-party component **with no source** or with no living vendor to an application you
  expect to maintain for more than two years.
- ❌ Putting new business logic into a `TForm`.
- ❌ Automatic translation to C# presented as modernisation.
- ❌ **Using Community Edition in a company billing more than USD 5,000 a year**, even for
  internal use or as a substitute for the trial: it breaches the licence (§2).
- ❌ Planning on licence prices taken from a blog: they are requested in writing (§8).
- ❌ Losing the build machine with no backed-up image and no tested restore.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **The current RAD Studio/Delphi version** (as of Aug 2026: **13.1 "Florence"**, with an updated build on
   18 Mar 2026) and what it brings over the one you use.
2. **The real price per developer and the licence terms**: the figures in §2 are **reseller starting
   prices** (Professional ≈ USD 1,583, Enterprise ≈ USD 3,959, Architect ≈ USD 5,939)
   and **Embarcadero's list price and the volume/upgrade/academic ones differ**. **Declared
   gap**: request a written quote; do not plan with these figures. Also verify the
   *Named User* nature, the country restriction and the **annual renewal obligation**.
3. **Community Edition eligibility** in the current EULA: the revenue threshold (USD 5,000/year),
   the 5-developer limit and the exclusions. **The EULA overrides any summary.**
4. **Support and end of life of Delphi versions**: **declared gap — Embarcadero does not publish
   an EOL calendar comparable to other vendors'**; support is tied to the current update
   subscription. If you need a date for a plan, request it contractually.
5. **Free Pascal**: whether **3.2.2 (May 2021)** is still the stable release or 3.2.4/3.4 has shipped — it is the
   health indicator of the free side. And **Lazarus** (as of Aug 2026: **4.8**, 11 Jun 2026, on FPC
   3.2.2 and FPC 3.2.4RC1 on macOS).
6. **The FPC/Lazarus licence read raw** before distributing closed source: GPL for the compiler,
   a **modified LGPL with a static-linking exception** for the RTL and packages, plus the obligation to
   publish your RTL modifications. With `opensource-licensing-standards` and legal advice.
7. **The status of every third-party component in the inventory**: latest version, compatibility with your
   Delphi version, licence, source availability and whether the vendor still exists. **It is the
   verification work that changes the plan most and the one that systematically does not get done.**
8. **CVEs** of the linked native libraries, of the database drivers and of the third-party
   network/cryptography components.
9. **The status of `legacy-modernization-standards`**: **the migration strategy is theirs** — and the
   execution of the cutover belongs to `migration-projects-standards` — and this skill only contributes the
   platform's technical facts.

If the web contradicts this document, **the web wins** — flag the discrepancy.
