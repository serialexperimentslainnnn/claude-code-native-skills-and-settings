---
name: dotnet-framework-legacy-standards
description: .NET Framework 4.x legacy maintenance and the migration decision to modern .NET. Use when a project targets net45/net461/net462/net472/net48/net481, an old-style non-SDK .csproj/.vbproj with <TargetFrameworkVersion> and AssemblyInfo.cs, packages.config, web.config or app.config with system.web/system.serviceModel/machineKey/bindingRedirect sections, Global.asax, .aspx/.ascx/.asmx/.svc files, ASP.NET WebForms or MVC5 on System.Web, WCF ServiceHost and ServiceContract on the server side, Windows Workflow Foundation, .NET Remoting, AppDomain.CreateDomain, BinaryFormatter, the GAC and gacutil, COM interop with tlbimp/regasm, msbuild.exe with v4.0.30319 or Visual Studio 2019 solutions, and when deciding on .NET Upgrade Assistant, try-convert, SDK-style migration, PackageReference, .NET Standard 2.0 shims or CoreWCF.
---

# .NET Framework legacy (4.x) standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Maintenance of applications on **.NET Framework 4.x** and **the decision whether or not to migrate**
to modern .NET. Triggers: TFM `net45`–`net481`, non-SDK-style `.csproj`/`.vbproj` with
`<TargetFrameworkVersion>`, `packages.config`, `web.config`/`app.config` with `system.web`,
`system.serviceModel`, `machineKey` or `bindingRedirect`, `Global.asax`, `.aspx`/`.ascx`/`.asmx`/`.svc`,
GAC, `regasm`/`tlbimp`, `BinaryFormatter`, `AppDomain.CreateDomain`.

**The misunderstanding to correct first**: .NET Framework 4.8/4.8.1 is **NOT out of
support** — it is an OS component and inherits its lifecycle (§2). This is not a bureaucratic detail: it is
**the economic reason why nobody migrates**, and any plan sold as "we have to get out because it dies
next year" is false and falls apart at the first review. The real argument is a different one:
performance, hiring, the package ecosystem and the fact that **the platform gets no new features**.

**.NET Framework and modern .NET are not the same platform in different versions**: they differ in
runtime, deployment and API surface. Migrating is **porting**, not upgrading — treat it as such in
the plan, the estimate and the testing.

**Not applicable**: `dotnet-standards` decides **everything about modern .NET** —SDK, TFM `net10.0`, LTS,
ASP.NET Core, EF Core, NuGet, publishing, Native AOT, containers— **and, critically, it owns
the destination of any migration: code that leaves here is governed by its criteria, not
by this skill's**. Here, only the 4.x side and the decision to cross.
`legacy-modernization-standards` carries the portfolio strategy —
invest / migrate / retire / freeze—; here, the technical criteria for this platform.
The sisters of this block: `vbnet-standards` (**the VB.NET language**, whether running on 4.x or on
modern .NET), `vb6-standards` (native VB6, no CLR) and `classic-asp-standards` (ASP with VBScript
on IIS) — they share the Microsoft ecosystem, not the platform.
Decision and framing: `enterprise-architecture-standards`, `refactoring-tech-debt-standards`
(*strangler fig*), `testing-qa-standards`, `project-management-standards`,
`tech-leadership-standards`. Infrastructure and operation: `web-app-servers-standards` (IIS as a server —sites, *app pools*, ARR, *listener* TLS—; here only what
the app's `web.config` decides), `windows-server-ad-standards`, `powershell-standards`,
`sqlserver-dba-standards` and `sql-standards`, `vmware-standards`/`hyper-v-standards` (the host of the
frozen VM), `cicd-standards`, `git-workflow-standards`. Security and compliance:
`appsec-standards`, `vulnerability-management-standards`, `secrets-management-standards`,
`grc-compliance-standards`, `opensource-licensing-standards`.

## 2. Support status — the expensive fact

> Verify on the web before pinning it in any document with consequences (§8).

Official statement (Microsoft Learn, *Lifecycle FAQ - .NET Framework*), **verbatim**:

> "Beginning with version 4.5.2 and later, .NET Framework is defined as a component of the Windows
> operating system (OS). Components receive the same support as their parent products, therefore,
> .NET Framework 4.5.2 and later follows the lifecycle policy of the underlying Windows OS on which
> it is installed."

> "There is no change to the lifecycle policy for .NET Framework 4.x and its updates which continue
> to be defined as a component of the OS and assume the same lifecycle policy as the Windows
> version on which it is installed."

> "**.NET Framework 4.8:** Support for .NET 4.8 follows the Lifecycle Policy of the parent OS. […]
> We recommend customers upgrade to .NET Framework 4.8 to receive the highest level of performance,
> reliability, and security." — and identically for 4.8.1: *"Support for .NET 4.8.1 follows the
> Lifecycle Policy of the parent OS."*

**Operational consequence**: on 4.8/4.8.1 there is **no end-of-support date of its own**; the one for
the underlying Windows wins, and that is the *EOL* that goes into the risk register. The lifecycle page leaves
the *End Date* column **empty** for 4.7, 4.7.1, 4.7.2, 4.8 and 4.8.1.

| Version | End of support (Microsoft Lifecycle, Aug 2026) |
|---|---|
| 4.8.1 (since 9 Aug 2022), 4.8, 4.7.2, 4.7.1, 4.7 | no date of its own — lifecycle of the host Windows |
| **4.6.2** | **12 Jan 2027** (table: `1/13/2027 6:59:59 AM` PT) — *still alive, but on the clock* |
| 4.6.1, 4.6, 4.5.2 | 26 Apr 2022 (withdrawn over SHA-1 signing) |
| 4.5.1, 4.5, 4.0 | 12 Jan 2016 |
| 3.5 SP1 | 9 Jan 2029 (standalone product since Windows 10 1809 / Server 2019) |

**Declared discrepancy**: the lifecycle page itself gives 4.6.2 an *End Date* of
1/13/2027, while the FAQ says that "Support for .NET 4.6.2 follows the Lifecycle Policy of the
parent OS". They are not the same thing. When in doubt, **the concrete date in the table is what you defend in
an audit**, and 4.6.2 is treated as "on countdown": upgrade in place to 4.8/4.8.1, which
the FAQ itself declares compatible without recompiling.

**4.8.1 is not on every Windows**: the FAQ lists it only from Windows 10 20H2 / Windows 11 and
Windows Server 2022/2025 onwards, and adds **verbatim**: *".NET Framework 4.8.1 is supported on Windows on
Arm starting with Windows 11 only, earlier versions including all versions of Windows 10 are not
supported on Arm."* Pinning 4.8.1 without checking the OS estate is a deployment failure.

**Baseline**: any 4.x app under maintenance is taken to **4.8** (or 4.8.1 if the estate allows
it) and stays there. Below 4.7.2, nothing new is accepted.

## 3. What has no port (and therefore anchors the project)

Official documentation (*".NET Framework technologies unavailable on .NET 6+"*), **verbatim** on what
decides:

- **App Domains** — *"Creating more app domains isn't supported, and there are no plans to add this
  capability in the future."* Replacement: separate processes, containers, `AssemblyLoadContext`.
- **.NET Remoting** — *".NET Remoting isn't supported on .NET 6+."* Furthermore, `BeginInvoke()`/
  `EndInvoke()` on delegates throw `PlatformNotSupportedException`.
- **CAS**, ***security transparency*** (withdrawn as a security boundary; they never were one),
  **`System.EnterpriseServices` (COM+)**, multi-module assemblies, XSLT `script` blocks.
- **Windows Workflow Foundation** — *"Windows Workflow Foundation (WF) is not supported in .NET 6+."*
  Alternative cited by Microsoft: **CoreWF** (UiPath, MIT verified in the raw `LICENSE`) —
  **it is a third-party project**, not a Microsoft product: evaluate it as a dependency.

**Server-side WCF**: the official note is "Windows Communication Foundation (WCF) server can be used
in .NET 6+ by using the CoreWCF NuGet packages". **CoreWCF** is the community successor under the .NET
Foundation, **MIT** licence (verified by reading the repo's raw `LICENSE`), most recent
release **v1.9.1 (16 Jun 2026)**, and that version is a security one. Criteria: CoreWCF serves to
**keep the existing SOAP contract alive during the port**, not as the target architecture; the
WCF client (`System.ServiceModel.*`) does have packages on modern .NET.

**WebForms is not migrated mechanically. There is no page converter.** `ViewState`, *postback* and
the page lifecycle have no equivalent: the UI is redone. Official route: **incremental
migration with YARP** (*strangler fig*), ASP.NET Core in front routing endpoint by endpoint, with
Blazor Server or Razor Pages as the destination. **Estimate it as a UI rewrite.**

**WinForms and WPF do have a port** and are the easy case: TFM `net10.0-windows` with
`<UseWindowsForms>`/`<UseWPF>`. Caveat: they are **Windows only**, and anything that depended on
`BinaryFormatter` (clipboard, *drag & drop*, `.resx` with custom types) requires explicit changes.

## 4. Migration route (by layers, not *big bang*)

1. **Convert to SDK-style first, without changing TFM.** It is the cheap and reversible step: the
   project stays on `net48` and the diff gets reviewed. `try-convert` automates most of it.
2. **`packages.config` → `PackageReference`.** It removes manual `bindingRedirect`s and the
   `packages/` folder. It can be done already on 4.x, and it unblocks dependency scanning (§5).
3. **Libraries before executables.** Domain and data access first; the executable and
   the UI last. The middle layer is where you discover what does not port.
4. **`.NET Standard 2.0` only as a bridge.** Official position verbatim: *"We recommend you skip
   .NET Standard 2.1 and go straight to .NET 10"* and *"No new versions of .NET Standard will be
   released"*; but also *"Use `netstandard2.0` to share code between .NET Framework and all
   other implementations of .NET."* → it is **exactly the right tool while the two platforms
   coexist**, and it is dropped as soon as the 4.x side is switched off. For new code that does not talk to
   4.x, `net10.0`. Multi-target `netstandard2.0;net10.0` rather than staying on Standard.
5. **The executable, last**, and there `dotnet-standards` already rules.

**Tooling — a finding that corrects the usual assumption**: the **.NET Upgrade Assistant is
officially deprecated**. Verbatim (doc. rev. 19 Mar 2026): *".NET Upgrade Assistant is officially
deprecated. Use the GitHub Copilot modernization chat agent instead, which is included with Visual
Studio 2026 and Visual Studio 2022 17.14.16 or later."* Any plan predating 2026 that leans on it
must be reviewed. And with whatever tool you use, **it produces a starting point that compiles, not a
finished migration**: the validation comes from the test suite, not from the green icon.

## 5. Stack security

- **`BinaryFormatter` is withdrawn**, not discouraged. Verbatim: *"Starting with .NET 9, we no
  longer include an implementation of BinaryFormatter in the runtime. The APIs are still present,
  but their implementation always throws a PlatformNotSupportedException, regardless of project
  type."* On **4.x it still works**, and that is where the danger is: it is executable CWE-502. Any
  `BinaryFormatter` over data crossing a trust boundary is a **critical finding today**,
  before migrating anything. The `System.Runtime.Serialization.Formatters` package that revives it on modern
  .NET is declared **"unsupported and not recommended"**: FORBIDDEN to use it as a solution.
- **TLS**: on 4.x the protocol is decided by the process, and `ServicePointManager.SecurityProtocol` set
  by hand ends up negotiating TLS 1.0. Criteria: **do not set it in code**; let the OS decide
  (`SystemDefault`, with `Switch.System.Net.DontEnableSystemDefaultTlsVersions=false`) and harden the
  OS (`windows-server-ad-standards`).
- **`machineKey`** in cleartext in the `web.config` is a secret in the repository and allows forging
  `ViewState` and authentication cookies: rotate it and take it out (`secrets-management-standards`).
  `ViewState` without MAC or encryption: forbidden.
- **`customErrors="On"` and `debug="false"`** in production: `debug="true"` leaks stack traces.
- **Dependencies**: `packages.config` does not scan well; migrating to `PackageReference` **is also a
  security control** (it enables `dotnet list package --vulnerable`, Renovate, SBOM). A 4.x
  project without a dependency inventory is unknown surface.
- Deserialisation, XXE (`XmlDocument` without `XmlResolver=null`) and SQL by concatenation: the
  vulnerability class is decided by `appsec-standards`.

## 6. Operation and environment

- **IIS and `web.config`**: the app decides *handlers*, *modules*, authentication and `system.web`; the site,
  the *app pool* and the *listener* TLS belong to `web-app-servers-standards`. Do not duplicate.
- **GAC and COM**: registering in the GAC or depending on `regasm` ties the deployment to the machine. It stays
  **documented as a machine dependency**, automated and versioned; never a manual step.
- **Reproducible build**: `msbuild.exe` from a pinned version of Visual Studio or of the *Build
  Tools*, available on the CI agent. A legacy app that only compiles on one person's laptop is
  the real risk, not the language.
- **Configuration**: transforms per environment; secrets, out. Modern configuration
  (`IConfiguration`) belongs to the destination: do not reimplement it on 4.x.

## 7. Sustainability, prohibitions and when NOT to migrate

**When NOT to migrate** — a legitimate decision, with an ADR and annual review: an application that is **stable, under
corrective maintenance**, with no functional roadmap, on a supported Windows and **with no direct
exposure to the internet**; a team that knows it and no short-term hiring risk; and end of life
of the **host Windows** far off and budgeted. **That is the clock**, not the framework. Migrating there
adds no value: the cost is real and the benefit, hypothetical.

**When yes, no discussion**: an active functional roadmap; it exposes services to the internet; it depends on
dead components with no patches; the host Windows enters countdown; or a compliance
requirement demands a stack with patches of its own.

**The total-rewrite trap**: replacing a working 4.x application with a brand-new product from scratch
is the most expensive and frequent failure mode of this domain — the business logic
written down nowhere gets underestimated and two years of evolution get stopped. By default, **incremental
migration with the application alive**. A rewrite is justified only if the product changes too.

- ❌ FORBIDDEN to use `BinaryFormatter` on untrusted data, and to use the *unsupported*
  compatibility package to revive it.
- ❌ FORBIDDEN to start **new** development on .NET Framework. What exists is maintained.
- ❌ FORBIDDEN targets below **4.7.2**; 4.6.2 and earlier, in-place upgrade now.
- ❌ FORBIDDEN `machineKey`, connection strings or credentials in a versioned `web.config`.
- ❌ FORBIDDEN `debug="true"` or `customErrors="Off"` in production.
- ❌ FORBIDDEN to pin `ServicePointManager.SecurityProtocol` to a specific protocol in code.
- ❌ FORBIDDEN to leave `packages.config` in a project under active maintenance: it blocks scanning.
- ❌ FORBIDDEN to justify a migration with "4.8 is going out of support": it is **false** (§2) and burns
  the credibility of the entire plan.
- ❌ FORBIDDEN to accept the output of an automatic converter without tests backing it up.
- ❌ FORBIDDEN to plan around the .NET Upgrade Assistant without first checking its status: it is
  **deprecated** (§4).

## 8. Mandatory web verification

Before pinning anything: **end-of-support date of the host Windows** (that is the fact that rules, not the
framework's) and the state of the .NET Framework lifecycle table, including the 4.6.2 date
and the discrepancy declared in §2; version and status of **CoreWCF** and **CoreWF** (releases and
licence read raw, not off the badge); current official position on **.NET Standard**; which
migration tool Microsoft recommends today (the Upgrade Assistant is deprecated: check what
replaces it and whether that has changed again); status of `BinaryFormatter` and of the compatibility
package; TLS 1.0/1.1 across the Windows estate; CVEs of the project's NuGet dependencies.

**Declared gaps (no verified data, do NOT fill in from memory)**: typical cost/timeline of a
4.x→modern .NET migration by code base size — there is no reliable public figure, it is estimated from
the project's real inventory; market share or number of 4.x applications in production; end-of-support
date of each specific Windows in the estate (looked up one by one in Microsoft
Lifecycle); maintenance status of `try-convert` as of today.

If the web contradicts this document, **the web wins** — flag the discrepancy.
