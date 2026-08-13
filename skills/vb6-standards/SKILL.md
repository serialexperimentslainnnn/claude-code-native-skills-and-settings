---
name: vb6-standards
description: Visual Basic 6.0 legacy applications - freeze, isolate or rewrite. Use when working with .vbp/.vbg/.frm/.frx/.bas/.cls/.ctl/.dsr project and form files, the VB6 IDE (VB6.EXE) or its command-line compiler, msvbvm60.dll and the VB6 runtime redistributable, MSCOMCTL.OCX/COMCTL32.OCX/MSCOMM32.OCX/MSWINSCK.OCX/RICHTX32.OCX and other OCX or ActiveX controls, regsvr32 component registration, binary compatibility and interface GUID churn, Declare Function Lib for Win32 API P/Invoke, ADO/DAO/RDO data access, Err.Number and On Error GoTo, 32-bit-only processes under WOW64, VB6 apps on Windows Server 2019/2022/2025, and when evaluating VB6-to-.NET converters, application virtualization or containerized Windows isolation for a frozen VB6 build.
---

# Visual Basic 6.0 standards (legacy)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Native VB6** applications (no CLR) still in production: maintenance, freezing,
isolation and exit. Triggers: `.vbp`, `.vbg`, `.frm`, `.frx`, `.bas`, `.cls`, `.ctl`,
`msvbvm60.dll`, `VB6.EXE`, `regsvr32`, `.ocx`, binary compatibility, `Declare Function Lib`,
ADO/DAO/RDO, `On Error GoTo`.

**The central misunderstanding is "it works, therefore it is supported".** No. Two different things
are supported and they have to be separated surgically. Microsoft (*Support Statement for Visual
Basic 6.0*, rev. 18 Dec 2024), **verbatim**:

> "Microsoft's goal is "It Just Works" compatibility for pre-existing Visual Basic 6.0 applications
> on supported Windows versions. **The Visual Basic 6.0 runtime will be supported for the support
> lifetime of Windows versions.** The support bar is limited to serious regressions and critical
> security issues for existing applications."

And the other side, the one that decides:

> "VB6 development is no longer supported. This support statement does not change the support
> policy for the Visual Basic IDE. **The Visual Basic 6.0 IDE and Visual Studio 6.0 IDE are no
> longer supported as of April 8, 2008.** Because there is no supported method to create or maintain
> Visual Basic 6 applications, **Microsoft strongly recommends that you replace your applications
> with modern technology.**"

Translated into criteria: **the binary that already exists runs with support; the act of modifying
it is supported by nobody.** There have been no compiler or IDE patches since 2008. Every code change
in a VB6 app is made with an unsupported tool, on a machine that probably cannot be reinstalled
cleanly. **That is the real risk: the build environment, not the language.**

The official operating-system table confirms the pattern in every row — Windows 11, 10, 8.1
SP1, 7 SP1, Server 2025, 2022, 2019, 2016, 2012 R2, 2012, 2008 R2 — with **"Supported"** for *VB6
Runtime Files in OS* and *VB6 Runtime Extended Files*, and **"Not Supported"** for the *VB6 IDE*, without a
single exception. Two notes that are often ignored, verbatim: *"For Windows Server, only 64-bit
editions are supported. Server Core is not supported."*

**Not applicable**: `vbnet-standards` (**VB.NET is a different language on the CLR**; the syntactic
similarity is the most expensive trap in this domain — a `.vb` is not a `.bas`),
`dotnet-framework-legacy-standards` (.NET Framework 4.x, WebForms, WCF: the usual destination of a
rewrite *inside* the Microsoft world, and the owner of the COM interop criteria from .NET),
`dotnet-standards` (**modern .NET: if the rewrite ends up there, the resulting code is governed by
their criteria, not by these**), `classic-asp-standards` (server-side VBScript — VB6's own support
statement says **verbatim**: *"VBScript is unrelated to Visual Basic 6.0 and
this support statement"*).
`legacy-modernization-standards`: the portfolio decision to invest/migrate/
retire — here the technical criteria —, with `enterprise-architecture-standards`,
`project-management-standards`, `tech-leadership-standards`, `refactoring-tech-debt-standards`
(*strangler fig*) and `testing-qa-standards`. Infrastructure and containment: `vmware-standards`/`hyper-v-standards`
(**the host that sustains the frozen VM — the key operational piece in this domain**),
`windows-server-ad-standards`, `powershell-standards`, `backup-recovery-standards` (the build
machine's image **is** an asset to be backed up), `sqlserver-dba-standards` and `sql-standards`.
Security: `appsec-standards`, `vulnerability-management-standards`, `firewall-policy-standards`
(the network isolation §5 demands), `grc-compliance-standards`.

## 2. What is supported and what is not — default decisions

> Verify on the web before pinning it (§8): the statement is updated as Windows versions ship.

| Piece | Official status | Criterion |
|---|---|---|
| Runtime in the OS (`msvbvm60.dll` and the redist list) | Supported for as long as the host Windows lasts | The clock is the **Windows EOL**, not VB6's |
| *Runtime extended files* (the listed OCXs, including `MSCOMCTL.OCX`, `COMCTL32.OCX`, `MSWINSCK.OCX`, `RICHTX32.OCX`) | Supported, **but distributed by the application**, not by the OS | Version the redist alongside the installer; do not rely on whatever is on the machine |
| Controls on the *unsupported* list (`threed32.ocx`, `grid32.ocx`, `mschart.ocx`, `msoutl32.ocx`…) | **Not supported** | Replace or encapsulate; they are a hard blocker for certifying the OS |
| VB6 / VS6 IDE | **Not supported since 8 Apr 2008**, on every Windows in the table | No plan can depend on "we recompile if we need to" without solving §3 |
| Third-party controls | Outside Microsoft's support | *"Microsoft is unable to provide support for third party components, such as OCX/ActiveX controls."* |
| 64-bit | *"supported only in the WOW emulation environment"* | The app is **32-bit forever**: no access to >4 GB, no 64-bit drivers and no 64-bit ODBC |
| Server Core / 32-bit Server editions | **Not supported** | Rules out hardening by OS minimisation |
| VBA hosting the VB6 runtime | Supported only if the OS, Office **and** the specific file all are, at the same time | Three separate clocks: the shortest one wins |

**Correcting a frequent assumption**: `MSCOMCTL.OCX` **is not dead** — it appears in the official
list of *"Supported runtime files to distribute with your application"*. What is dead is
half a dozen old VB4/VB5 controls and **everything third-party**. Before declaring a
control unusable, check it against the real table in the support statement, not from memory.

## 3. The build environment problem (the real risk)

A VB6 application in production does not fail because the language is old: it fails the day it has
to be touched and nobody can rebuild the machine that compiles it. Hard rules:

- **The build machine is a production asset.** It must exist **at minimum** as a versioned
  VM image, with a tested backup (`backup-recovery-standards`) and the ability to boot on the
  current hypervisor (`vmware-standards`/`hyper-v-standards`). A single physical machine under a desk
  is an incident waiting for a date.
- **Document the environment as an inventory, not as a memory**: the exact IDE version and service pack,
  every third-party OCX with its version and origin, the registry keys its registration creates, the
  installation order, and the design-time licences of the commercial controls (many require a
  key that only lives in that machine's registry). That document is what separates "we can
  patch" from "we cannot".
- **The build output must be comparable**: keep the compiled binary of every delivered
  version alongside the code, so a future recompilation can be verified to produce something
  equivalent. Without that, there is no way to tell whether the machine has degraded.
- The source code goes in **Git** like anything else (`git-workflow-standards`): `.frx` and the like
  are binaries, treat them as such; no folders with date suffixes.

**Binary compatibility and GUIDs**: the project must be set to **binary
compatibility** against the last delivered binary, not "project compatibility" and not "no
compatibility". Otherwise every recompilation generates **new interface GUIDs**, and every COM client
registered against the previous version stops finding the component. It is the classic breakage in this
domain: it is recompiled "with no changes", deployed, and the system stops talking to itself. The
reference binary is versioned and kept as part of the artifact.

**Component registration**: registering an OCX/DLL with `regsvr32` is global machine state.
Every deployment must be **idempotent and reversible**, and written down (an installer or a
`powershell-standards` script), never in somebody's head. *DLL hell* from different versions of the same
OCX on different machines is the dominant cause of "it works on my machine".

## 4. Quality and testing

There is no modern toolchain here (linter, analyser, formatter: none exist for VB6 in a
supported state), so **this section reduces to the only thing that does apply**: before touching a line,
**characterise the observable behaviour** with end-to-end tests over the application
as it stands (inputs → outputs, files, database state). The strategy is set by
`testing-qa-standards`. Without that net, not even a minor change is defensible: there is no strict
compiler and no suite to warn you, and `On Error Resume Next` scattered through the code hides the failures you cause.

## 5. Stack security

**Hard rule: a VB6 application must not serve internet traffic.** Neither directly nor behind
a proxy that "already filters". It is code compiled with tools unpatched since 2008, with no
guaranteed modern mitigations (ASLR/DEP/CFG depend on flags that linker does not set), with
string handling prone to overflow in the `Declare Function Lib` calls into the Win32 API, and
with nobody who will publish a patch if a compiler bug appears.

- **Isolation by default**: a segmented network, reachable only from identified internal clients,
  with a *default-deny* rule inbound **and outbound** (`firewall-policy-standards`). If it needs
  publishing, **a modern service is published in front** that talks to it, not it.
- **`MSWINSCK.OCX` (Winsock) listening on a port** is exactly the forbidden scenario: a protocol
  parser written in VB6 exposed to the network.
- **SQL by concatenation** is the dominant pattern in this code. The real fix: `ADODB.Command`
  with typed `CreateParameter`/`Parameters.Append`; never `"... WHERE id=" & Text1.Text`. See
  `sql-standards`.
- **Credentials** embedded in the `.bas` or in an `.ini` next to the executable are the norm here. A
  VB6 binary decompiles easily: everything in there is published. Take them out
  (`secrets-management-standards`) and **rotate them**, assuming they are already known.
- **Privileges**: these apps usually need to write to `Program Files` or `HKLM`, and get "fixed" by
  being given administrator. FORBIDDEN. Redirect to user paths or isolate in their own VM/session.
- **Dependencies with no scanner**: third-party OCXs appear in no SCA. They enter the
  `vulnerability-management-standards` inventory by hand; a control whose vendor no longer exists is an
  explicitly accepted risk, not an oversight.

## 6. Operation

- **Freezing and isolating** is legitimate and often the right answer (§7): a dedicated VM, a snapshot before
  any change, a backed-up image with a tested restore, no automatic updates that
  break an OCX, and the **host Windows's EOL** as the only date in the risk register.
- 32-bit on 64-bit Windows: WOW64. To plan for: 32-bit ODBC is configured with
  `%SystemRoot%\SysWOW64\odbcad32.exe`, the registry goes to `HKLM\SOFTWARE\WOW6432Node`, and **no
  64-bit component can be loaded into that process** — modern database drivers included.
- Windows containerisation and application virtualisation **package and isolate** the binary,
  they do not modernise it: they make deployment reproducible and decouple it from the host OS. Verify
  first that the OCXs register inside the container and that the app does not need an interactive desktop.

## 7. Exit, prohibitions and when to freeze instead of migrating

**There is no good mechanical route, and saying so early saves a year.** VB6→.NET converters
produce code that compiles and that **has to be rewritten anyway**: the forms end up as
incomprehensible generated forms, `On Error` translates into useless `try/catch`, the logic stays
in the event handlers and the COM model is dragged along. The upgrade wizard from the early versions
of Visual Studio has already been withdrawn. Budgeting an automatic conversion as if it were the
migration is the classic mistake.

Real options, in order of increasing cost: **(a) freeze and isolate**; **(b) package/virtualise
or containerise** the binary to decouple it from the OS; **(c) *strangler fig*** — put a
modern service in front and move functionality module by module, leaving the VB6 app as a shrinking
engine; **(d) a full rewrite**, with the app live and its behaviour used as the reference.

**Freeze and isolate** is the right answer when: the application is stable with no roadmap; the
host Windows is still supported with a distant date; it can be fully isolated from the network; and
the build environment exists — or can be rebuilt — in case an urgent patch appears. **Migrating** is
mandatory when there is pending functional evolution, network exposure that cannot be removed,
a dependency on unsupported controls or dead third parties, or the Windows enters its countdown.

- ❌ FORBIDDEN to expose a VB6 application to the internet, directly or via port forwarding.
- ❌ FORBIDDEN: **new** development in VB6. What exists is maintained; anything new is written outside.
- ❌ FORBIDDEN to recompile without **binary compatibility** against the last delivered binary.
- ❌ FORBIDDEN for a single build machine to exist without a versioned image and a tested restore.
- ❌ FORBIDDEN: SQL by concatenation; typed ADO parameters instead.
- ❌ FORBIDDEN to run the application as administrator to avoid fixing its paths/permissions.
- ❌ FORBIDDEN: credentials embedded in the code or in an `.ini` next to the executable.
- ❌ FORBIDDEN: `On Error Resume Next` in new or modified code.
- ❌ FORBIDDEN to present the output of a VB6→.NET converter as a finished migration.
- ❌ FORBIDDEN to say "VB6 is supported" without the runtime/IDE distinction in §1: it is a half-truth and
  it leads to bad planning.
- ❌ FORBIDDEN to touch the code without prior behavioural characterisation (§4).

## 8. Mandatory web verification

Always check: the current **VB6 support statement** (it is updated as new Windows
versions ship — check whether the table already includes the estate's OS and whether it still says *"Not
Supported"* for the IDE); the **end-of-support date of the host Windows**, which is the only real
clock; which files remain on the supported *runtime extended files* list versus the *not
supported* one; the status of every third-party OCX's vendor; CVEs of the COM components in the
inventory.

**Declared gaps (no verified data, do NOT fill them from memory)**: not verified as of Aug 2026 whether
any Microsoft statement exists on VB6 runtime support in Windows versions
later than those listed in the table — **the absence of a row is neither a promise nor a
denial**, consult the updated statement —; the maintenance status and real output quality
of commercial VB6→.NET converters; the concrete feasibility of containerising a VB6
application with registered OCXs (it depends on each control: test, do not assume); the number of VB6 applications in
production or their market share — there is no reliable public figure, do not cite one.

If the web contradicts this document, **the web wins** — flag the discrepancy.
