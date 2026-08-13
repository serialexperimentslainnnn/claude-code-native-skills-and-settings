---
name: powershell-standards
description: Use when writing or reviewing PowerShell — .ps1/.psm1/.psd1/.ps1xml files, pwsh vs powershell.exe, Set-StrictMode, CmdletBinding, SupportsShouldProcess with -WhatIf/-Confirm, ValidateSet, ValueFromPipeline, $ErrorActionPreference, PSScriptAnalyzer and PSScriptAnalyzerSettings.psd1, Pester *.Tests.ps1, PSResourceGet/Install-PSResource and PowerShell Gallery publishing, SecretManagement and SecretStore, Set-ExecutionPolicy, Authenticode script signing, JEA .pssc session configurations, Constrained Language Mode, ScriptBlock Logging, transcription and AMSI, PSRemoting over WinRM or SSH, or PowerShell steps in CI.
---

# PowerShell standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to all PowerShell code: automation scripts, publishable modules, advanced functions,
PowerShell steps in pipelines and their packaging, signing and distribution.
Triggers: `.ps1`, `.psm1`, `.psd1`, `.ps1xml`, `.pssc`, `*.Tests.ps1`, `PSScriptAnalyzerSettings.psd1`,
`pwsh`/`powershell.exe`, `Install-PSResource`, `Invoke-Pester`, `Enter-PSSession`,
`New-PSSessionConfigurationFile`.
It sets **criteria** (what to use, what is vetoed, what to verify), not tutorials.

**Not applicable**: see
- `windows-server-ad-standards` (**what is being administered is theirs**: forest, domain, OU, GPO,
  Kerberos/NTLM, gMSA/dMSA, Tier 0, PAW, Windows Server roles. **Here only how the script is
  written** that calls the `ActiveDirectory` module. Cut-off rule: if the directory takes the
  decision, it is theirs; if the code takes it, it is this skill's. **Forbidden to duplicate AD
  criteria here.**).
- `bash-linux-scripting-standards` (**reciprocal boundary**): POSIX/bash shell is theirs, PowerShell
  is this skill's. Choice criterion on cross-platform: **if the target is a Linux host, its binaries
  and its text through pipes, write it in bash**; if the target is Windows, an API returning objects
  (.NET, Graph, Az, Exchange, VMware) or you need to manipulate structures with properties,
  **PowerShell**. Their escape threshold still applies here: past the point where the script is an
  application, it goes to `python-standards`/`go-standards`, not to an 800-line `.ps1`.
- `dotnet-standards` (**PowerShell runs on .NET, and that does not make it .NET**): if the problem
  calls for an **application** — service, API, worker, distributable binary, measured performance —
  it is .NET; if it calls for **administrative automation** — orchestrating cmdlets, touching
  systems, packaging a module — it is PowerShell. Binary cmdlets in C# and the `.csproj` that
  compiles them belong there; the module manifest and contract belong here.
- `iac-standards` (Terraform/OpenTofu and Ansible: **if Ansible or the provider does it
  idempotently, you do not write a script**; PowerShell DSC and `Invoke-DscResource` are decided
  there), `cicd-standards` (the pipeline running the §4 gates, its OIDC and action pinning),
  `secrets-management-standards` (**owner of the secrets manager choice**: Vault/KMS/cloud manager,
  rotation and policy. Here only **how the script consumes** the secret without leaking it, and
  `SecretManagement` as a façade),
- `identity-access-management-standards` (IdP design, OAuth 2.1/OIDC, PAM/JIT; here only how the
  script authenticates without a static secret),
- `appsec-standards` (methodology and agnostic vulnerability classes; here PowerShell's concrete
  sinks: `Invoke-Expression`, deserialisation, argument injection),
- `offensive-security-standards` (**authorised pentest/red team, with written scope**. PowerShell is
  a common offensive tool and **this skill is strictly defensive**: see the hard prohibition in §7 —
  no AMSI bypasses, obfuscation, downloaders or logging evasion are written here).

## 2. Toolchain and default decisions

> Verify the latest version on the web before fixing it in a real project (§8).

| Piece | Choice | Status 2026-08 | Reason |
|---|---|---|---|
| Target runtime | **PowerShell 7.6 (LTS)** | GA 2026-03-18, end of support **2028-11-14**, on .NET 10 | It is the current LTS and the default for all greenfield |
| Runtime to abandon | PowerShell 7.4 (LTS) and 7.5 | **both die on 2026-11-10** | Migrate now; there is no margin left |
| Windows PowerShell 5.1 | **Compatibility only**, never a target | An OS component, supported through the **Windows** lifecycle, not PowerShell's; still the default shell of Windows Server 2025 | **Frozen in functionality**: it gets no features, only servicing. Writing *for* 5.1 is writing for a runtime that is dead while walking |
| Backwards compatibility | Declare it, do not assume it: `#Requires -Version 7.4` and `CompatiblePSEditions` in the manifest | — | Windows PowerShell 2.0 was **removed from Windows Server 2025 in the Sept-2025 update**; the pattern repeats |
| Linter (gate) | **PSScriptAnalyzer** 1.25.x (MIT) | latest release 2026-03 | The ecosystem's only standard style/security gate |
| Formatting | PSScriptAnalyzer's `Invoke-Formatter` with a versioned `PSScriptAnalyzerSettings.psd1` | — | There is no `black`/`ruff format` in PowerShell: consistency is fixed by settings, not by taste |
| Tests | **Pester 6.x** (Apache-2.0) | **6.0.0 GA 2026-07-07**, 6.0.1 current; **v5 moves to maintenance** (critical bugs and security only) | v6 runs on 5.1 and 7.4+; a new assertion family, profiler-based coverage, experimental parallel runner |
| Module manager | **Microsoft.PowerShell.PSResourceGet** 1.2.x (MIT) — `Install-PSResource`, `Save-PSResource` | Inbox since PowerShell 7.4 | Replaces PowerShellGet 2.x: faster, with `-TrustRepository` and explicit verification |
| PowerShellGet | Only as a **compatibility layer** (v3 maps v2 syntax onto PSResourceGet) or legacy v2.2.5 | 7.4 did **not** ship the compatibility layer; both modules coexist | New code: `*-PSResource` cmdlets. **Verify which version your runtime ships before assuming** |
| Secrets in scripts | **Microsoft.PowerShell.SecretManagement** + the real manager's extension (Vault, Key Vault, KeePass) | verify version (§8) | The local `SecretStore` only for a workstation or single-node CI; never as a corporate vault |
| Editor/LSP | The VS Code PowerShell extension (it uses PSScriptAnalyzer underneath) | — | The gate that counts is CI, not the editor |

**Target version rule**: a module declares *one* compatibility surface and tests it. Supporting 5.1
**and** 7.x at once is a decision with a cost (double CI matrix, divergent .NET APIs, no modern
operators): it is taken with an ADR, not by inertia.

## 3. Structure and conventions

- **Command naming**: `Verb-Noun`, a verb **from the approved list** (`Get-Verb`) and a **singular**
  noun, with a module prefix to avoid collisions (`Get-AcmeUser`, not `Get-Users`). An unapproved
  verb is a PSScriptAnalyzer warning and breaks discovery via `Get-Command -Verb`.
- **Casing**: `PascalCase` for functions, parameters and properties; `camelCase` for local variables;
  constants in `PascalCase`. Four spaces, never tabs.
- **Aliases FORBIDDEN in a script or module** (`?`, `%`, `ls`, `cat`, `select`, `where`, `gci`,
  `curl`/`wget` as aliases of `Invoke-WebRequest`): interactive console only. Parameters always by
  full name.
- **Module layout**:
  ```
  MyModule/
    MyModule.psd1          # manifest: single source of truth for version and contract
    MyModule.psm1          # dot-source of Public/Private + Export-ModuleMember
    Public/Get-Thing.ps1   # one public function per file, same name
    Private/ConvertTo-X.ps1
    Tests/Get-Thing.Tests.ps1
    en-US/                 # external help (MAML) if applicable
  ```
- **A `.psd1` manifest is mandatory** and complete: `ModuleVersion` (SemVer), `RootModule`, `GUID`,
  `PowerShellVersion`, `CompatiblePSEditions`, `RequiredModules` with versions, and
  **`FunctionsToExport`, `CmdletsToExport`, `AliasesToExport` and `VariablesToExport` enumerated
  explicitly** — never `'*'`: the wildcard destroys command-discovery performance and leaks internal
  API.
- **Every public function is an advanced function**: `[CmdletBinding()]`, `begin/process/end` blocks,
  typed parameters, and a declared `[OutputType()]`.
- **Parameters**: explicit typing always; `[Parameter(Mandatory)]` on what is required (never
  `Read-Host` to ask for it); `ValidateSet`, `ValidateRange`, `ValidatePattern`,
  `ValidateNotNullOrEmpty` at the edge — validation goes in the attribute, not in an `if` inside the
  body; `ParameterSetName` instead of mutually exclusive flags checked by hand.
- **Pipeline**: `ValueFromPipeline` / `ValueFromPipelineByPropertyName` on the entity parameter, and
  the logic **in `process`**, not in `end`. A function that accepts pipeline input and processes
  everything in `end` is a bug.
- **`SupportsShouldProcess` mandatory in every function that changes state**:
  `[CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]` + `if
  ($PSCmdlet.ShouldProcess($target, $action))`. `-WhatIf` must be real and propagate to internal
  calls. Destructive without `ShouldProcess` = veto.
- **Output = objects, never text**: emit `[pscustomobject]` with stable properties (or a `class`/type
  with a `.ps1xml` format file). `Write-Host` **only** for interaction with a human at the console;
  never as a data or log channel. Formatting (`Format-Table`, `Out-String`) is the end consumer's
  business, never that of a function someone else will consume.
- **Streams with a purpose**: `Write-Output` for data, `Write-Verbose` for optional tracing,
  `Write-Debug` for diagnostics, `Write-Warning` for a recoverable anomaly, `Write-Error` for a
  non-terminating error, `Write-Information` for a structured message. A `return` that returns a
  formatted string instead of an object is debt.
- **`Set-StrictMode -Version Latest` as the default**, on the first line of the module or script,
  alongside `$ErrorActionPreference = 'Stop'`. Without strict mode, a misspelt property returns
  `$null` silently and the script continues: it is the language's most expensive class of bug.
- **Paths**: `Join-Path`, `$PSScriptRoot`, `[System.IO.Path]`; never concatenation with `\` (it
  breaks on Linux/macOS). No implicit `cd`: cmdlets accept `-Path`.
- **`#Requires`** in scripts: `-Version`, `-Modules`, `-RunAsAdministrator` — declare the
  precondition, do not discover it halfway through execution.
- **Comment-based help** on every public function: `.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`, `.OUTPUTS`.
  It is public API, not optional documentation.

## 4. Quality: lint, analysis and tests

- **PSScriptAnalyzer as a gate that breaks the build**: `Invoke-ScriptAnalyzer -Path . -Recurse
  -Settings ./PSScriptAnalyzerSettings.psd1 -Severity Error,Warning`, and **fail the job if there
  are findings**. The settings file is versioned; suppressions go with
  `[Diagnostics.CodeAnalysis.SuppressMessageAttribute]` **with a specific rule and a written
  `Justification`** — a global suppression or a mass `ExcludeRules` is a veto. Rules that are never
  suppressed: `PSAvoidUsingPlainTextForPassword`, `PSAvoidUsingConvertToSecureStringWithPlainText`,
  `PSUsePSCredentialType`, `PSAvoidUsingInvokeExpression`,
  `PSUseShouldProcessForStateChangingFunctions`, `PSAvoidUsingCmdletAliases`.
- **Compatibility as an automated check**, not as a belief: the rules
  `PSUseCompatibleCmdlets`/`PSUseCompatibleSyntax`/`PSUseCompatibleCommands` configured with the
  profiles of the platforms actually supported.
- **Pester 6** for every module with more than one function:
  - `Describe`/`Context`/`It` structure, one reason to fail per test, AAA. A `*.Tests.ps1` file
    beside the module, configuration via a `New-PesterConfiguration` object (never loose parameters
    scattered through CI).
  - **Cover the happy path, edges and errors**: invalid parameters, empty pipeline input,
    non-existent object, permission denied, timeout, `-WhatIf` (which must **not** touch anything).
  - `Mock` at the **boundaries** (cmdlets that touch systems: `Invoke-RestMethod`, `Get-ADUser`,
    `Set-Content`), never of the code under test. Verification with `Should -Invoke` /
    `Should-Invoke`.
  - **v4 → v5 break** (still alive in legacy repos): in v4 the variables and code inside `Describe`
    ran on the fly; v5 split execution into **Discovery** and **Run**, so loose code inside
    `Describe`/`Context` runs in Discovery and **setup must go in `BeforeAll`/`BeforeEach`**;
    `-TestCases` is resolved in Discovery. Migrating from v4 is not changing the version: it is
    rewriting the setup.
  - **v5 → v6 break** (verified in the official migration guide, §8): discovery and execution become
    **per file** (this enables the parallel runner; each file must bring its own discovery setup);
    `Assert-MockCalled` and `Assert-VerifiableMock` **removed**; an empty or `$null`
    `-ForEach`/`-TestCases` now **fails** unless `-AllowNullOrEmptyForEach`; duplicate
    `BeforeAll`/`AfterAll` blocks in the same scope forbidden; profiler-based coverage by default and
    the `CoverageGutters` output retired. Support limited to Windows PowerShell 5.1 and PowerShell
    7.4+.
  - Zero `Start-Sleep` as synchronisation in tests. Flaky = fixed or deleted. Every bug leaves a
    regression test.
- **CI gates, in increasing order of cost** (all of them block the merge):
  1. Parsing/syntax (`[System.Management.Automation.Language.Parser]::ParseFile`) and
     `Test-ModuleManifest`.
  2. `Invoke-ScriptAnalyzer` with the repo's settings.
  3. `Invoke-Pester` unit tests with coverage.
  4. Integration tests against a real system or container, **in a platform matrix** (Windows + Linux
     if the module is declared cross-platform; and 5.1 only if you really support it).
  5. Authenticode signing of the artifact and publication.
- The same command locally and in CI. If CI does something that cannot be reproduced locally, that
  is a pipeline bug.
- Coverage: a signal, not a goal. A threshold agreed by the team, main always green.

## 5. Security

**Errors** (the basis of everything else):
- `$ErrorActionPreference = 'Stop'` at the start. PowerShell distinguishes **terminating errors**
  (they abort the pipeline and are catchable with `try/catch`) from **non-terminating** ones (they go
  to `$Error` and **the script carries on**): a failed `Remove-Item` without `-ErrorAction Stop`
  throws no exception and the script continues believing it deleted something.
- `try/catch/finally` with a **typed** `catch` (`catch [System.IO.FileNotFoundException]`) before the
  generic one. `finally` to release resources (sessions, files, `Dispose`), always.
- `throw` to abort your own flow; `Write-Error` to report a per-item failure without aborting the
  batch (with `-ErrorAction Stop` at the call site if the consumer wants it to abort).
  `$PSCmdlet.ThrowTerminatingError()` in advanced functions when the error belongs to the cmdlet, not
  to the item.
- **FORBIDDEN**: `-ErrorAction SilentlyContinue` to hide a failure that has not been understood, and
  an empty `catch {}`. Silence only with a comment explaining why that error is expected.

**Execution and policy**:
- **`Set-ExecutionPolicy` is NOT a security control.** It is a barrier against accidental execution,
  documented as such, and it is trivially bypassed by design (`-EncodedCommand`, piping via stdin,
  copying and pasting the content). Treating it as a control in a design, an audit report or a risk
  exception is a technical error. `RemoteSigned` is the reasonable default on servers; **permanent
  `Bypass`/`Unrestricted` are vetoed**.
- **The real control is App Control for Business (WDAC)** with a signed policy: under it, only
  authorised code runs in `FullLanguage` and **everything else falls into `ConstrainedLanguage`**,
  where arbitrary access to .NET and COM disappears. AppLocker **is not formally deprecated as of
  2026-02** but Microsoft states that it **does not meet the MSRC's security feature servicing
  criteria**, whereas App Control does: do not use it as the sole CLM mechanism. **Verify the status
  before fixing it (§8).**
- **Authenticode signing** of every script and module that is distributed, with a code-signing
  certificate from a CA (internal or public) and the **key in an HSM/non-exportable store**; time
  stamping (`-TimestampServer`) is mandatory so the signature survives certificate expiry. Verify
  with `Get-AuthenticodeSignature` at the destination, do not trust the origin.

**Logging and detection** (they are configured, not avoided):
- **Module Logging**, **Script Block Logging** (it records the real block, including deobfuscation)
  and **transcription** (`Start-Transcript`/GPO, to a central write-only share) enabled on all managed
  hosts, with the events forwarded to the SIEM. **AMSI** enabled: PowerShell submits every block to
  the antimalware before executing it.
- Consequence for whoever writes: **everything you run is logged, including the secrets you pass on
  the command line**. Never a secret as an argument (`ps`, history, script block logs, transcription,
  `Get-History`).

**Credentials**:
- `[PSCredential]` and `[SecureString]` as in-memory transport types; the credential parameter is
  declared `[PSCredential]` with `[System.Management.Automation.Credential()]`.
- **FORBIDDEN**: `ConvertTo-SecureString -AsPlainText -Force` with a secret written in the file, and
  `ConvertFrom-SecureString` to a file as a "store" (on Windows it depends on the user's DPAPI; **on
  Linux and macOS it encrypts nothing**, it is obfuscated plaintext). `SecureString` **is not a
  protection control**: documented by Microsoft as not recommended for new cross-platform code. It
  reduces accidental exposure, it is not encryption.
- The secret is obtained at **run time** from the manager (`Get-Secret` from SecretManagement over
  the Vault/Key Vault extension) or from a federated identity (managed identity, CI runner OIDC).
  **Prefer having no secret at all**: the choice of manager and the rotation policy belong to
  `secrets-management-standards`.
- Never secrets in `.psd1`, in `PrivateData`, in the repo, in persisted environment variables, or in
  logs.

**Injection and untrusted input**:
- **`Invoke-Expression` is vetoed** with no practical exception: it is PowerShell's `eval` and the
  number one injection vector. Alternatives: a direct call, *splatting* (`@params`), `& $command
  @args`, a `[scriptblock]` built in your own code.
- Do not build a command line by concatenating user input for `Start-Process`/`cmd /c`: pass
  arguments as an array (`-ArgumentList @(...)`).
- SQL from PowerShell: **parameterised queries only** (`Invoke-Sqlcmd -Variable`, or `SqlCommand`
  with `Parameters.AddWithValue`). Concatenation is a veto — see `sql-standards`.
- Deserialisation: **`Import-Clixml` over untrusted data is vetoed** (it reconstructs types and is an
  execution vector). For external data, `ConvertFrom-Json` (and `-AsHashtable` where applicable) with
  subsequent schema validation.
- Downloading code: `Invoke-WebRequest`/`Invoke-RestMethod` with TLS verified; **FORBIDDEN**
  `-SkipCertificateCheck` and any manipulation of `ServerCertificateValidationCallback` outside a
  lab. Never `iwr ... | iex`.

**Remoting and surface**:
- **PowerShell Remoting over SSH** is the default in new and cross-platform scenarios (key-based
  authentication, without WinRM's surface). **WinRM** only in a domain, with Kerberos (never Basic
  nor cleartext credentials), HTTPS, and firewall-restricted to the administration origins.
- **JEA (Just Enough Administration)** for every operational delegation: a session configuration
  (`.pssc` + `RoleCapabilities` `.psrc`) with `SessionType = 'RestrictedRemoteServer'`, running under
  a **virtual account or gMSA**, with an allowlist of cmdlets and parameters. The operator does not
  need to be an admin to restart a service. JEA without transcription enabled is incomplete.
- Minimum surface: do not enable PSRemoting on hosts that do not need it; `Enable-PSRemoting` is not
  part of a base template by default.

## 6. Performance and operability

- **The pipeline is the mechanism, not an ornament**: filter at the source (`Get-ChildItem -Filter`,
  `Get-ADUser -Filter`, the server's `-Query`) before pulling everything and filtering with
  `Where-Object`. Pulling 100k objects to discard 99k is the most common performance antipattern.
- **Never `$array += $item` in a loop**: it recreates the whole array on every iteration (O(n²)). Use
  `[System.Collections.Generic.List[T]]`, or let the pipeline collect the output.
- Strings: `-join` or `StringBuilder`, not `$s += "..."` in a loop.
- **Concurrency**: `ForEach-Object -Parallel -ThrottleLimit` (7.x) for I/O; `Start-ThreadJob` for work
  with controlled shared state; `Start-Job` (a full process) only when isolation is needed. Beware
  `$using:` and the cost of serialisation — measure before parallelising.
- **Explicit timeouts** on every network call (`Invoke-RestMethod -TimeoutSec`,
  `-OperationTimeoutSeconds`, `-ConnectionTimeoutSeconds`) and on remote sessions: the default may be
  too permissive or too aggressive, but it must never be implicit.
- **Retries** with backoff on **idempotent** operations (`-MaximumRetryCount`/`-RetryIntervalSec` in
  `Invoke-RestMethod`; your own with jitter elsewhere). Retrying a non-idempotent `POST` is
  duplicating data.
- **Idempotency**: an automation script runs twice with no harm, or it is not an automation script.
  Check state before changing; `-WhatIf` as a real dry-run mode.
- **Exit codes**: `exit 0` on success and non-zero on failure, always — CI and schedulers depend on
  it. `$LASTEXITCODE` is checked after calling native binaries (`$?` is not enough); in 7.4+ there is
  `$PSNativeCommandUseErrorActionPreference` to integrate native exit codes with `ErrorAction`:
  **verify your version's default before relying on it (§8)**.
- **Structured logging**: emit objects and let the consumer decide, or `Write-Information` with an
  object; in production, JSON output (`ConvertTo-Json -Depth` explicit — the default truncates to 2
  levels and has bitten everyone). A correlation id on long-running operations. Never personal data
  or secrets in the log.
- **Progress and cancellation**: `Write-Progress` on long interactive operations (and disableable in
  CI with `$ProgressPreference = 'SilentlyContinue'`, which also speeds up `Invoke-WebRequest`
  noticeably); a `finally` that cleans up sessions and temporary files on `Ctrl+C`.
- Heavy modules: import what you use (`Import-Module -Name X -Function Y`); autoloading with
  `FunctionsToExport = '*'` degrades every session start.

## 7. Long-term sustainability

- **Cadence**: follow PowerShell's LTS (which follows .NET's) and plan the migration **before** the
  end-of-support date, not after. As of 2026-08 the critical clock is **7.4 and 7.5 dying on
  2026-11-10**.
- Your own modules versioned with **SemVer** in the manifest, with a `CHANGELOG` and publication from
  CI (never `Publish-PSResource` from a laptop with a personal API key). Deprecate with a warning + a
  window.
- PSGallery dependencies: **pin versions** (`RequiredVersion`/`MinimumVersion` in `RequiredModules`),
  register the repository as `-Trusted` explicitly and consciously, and prefer an **internal
  mirrored feed** (Azure Artifacts, ProGet, Nexus) in a corporate environment: the Gallery is a public
  registry with no strong curation and module-name *typosquatting* is real. A module with no release
  in >18 months is reviewed or replaced.
- 5.1 → 7.x migration: inventory the modules that only exist on Windows PowerShell and test
  `Import-Module -UseWindowsPowerShell` as a **temporary bridge with a cost** (a proxy over local
  remoting, deserialised objects without methods), never as the final architecture.
- Conscious debt: a shortcut = a TODO with a reason and a linked issue.

**Prohibition list (veto):**
- ❌ `Invoke-Expression` (and `iex`) over anything that is not your own literal. Never `iwr | iex`.
- ❌ Aliases in scripts and modules; positional parameters in non-trivial calls.
- ❌ A script or module without `Set-StrictMode -Version Latest` and without
  `$ErrorActionPreference = 'Stop'`.
- ❌ An empty `catch {}`, `-ErrorAction SilentlyContinue` as a way of ignoring a failure that has not
  been understood.
- ❌ A function that changes state without `SupportsShouldProcess`/`ShouldProcess`, or with a
  decorative `-WhatIf`.
- ❌ `Write-Host` as a data or log channel. Returning formatted strings instead of objects.
- ❌ `ConvertTo-SecureString -AsPlainText -Force` with the secret in the file; secrets in `.psd1`, in
  command-line parameters, in the history or in persisted environment variables.
- ❌ `-SkipCertificateCheck`, disabling TLS validation, or setting
  `[Net.ServicePointManager]::SecurityProtocol` to obsolete protocols.
- ❌ `Import-Clixml` over external data. `ConvertFrom-Json` without validating what was deserialised.
- ❌ `FunctionsToExport = '*'` in a published manifest.
- ❌ `$array += ...` inside a loop over non-trivial collections.
- ❌ Persistent `Set-ExecutionPolicy Bypass`, or presenting the execution policy as a security
  control.
- ❌ WinRM with Basic authentication, or over HTTP outside an isolated lab.
- ❌ **Evasion techniques: AMSI bypass or patching, disabling or tampering with Script Block Logging
  and transcription, script obfuscation, downloaders (*stagers*) and in-memory loaders.** This skill
  is **defensive**: here those controls are configured and verified, not circumvented. All offensive
  work — including the legitimate kind — lives in `offensive-security-standards`, with written scope
  and authorisation, and **is not documented here**.
- ❌ Writing new code exclusively targeting Windows PowerShell 5.1 without an ADR justifying it.

## 8. Mandatory web verification

Before fixing versions or claims in a project, **verify online** (WebSearch/WebFetch), preferring
`api.github.com/repos/OWNER/REPO/releases/latest` or the `/releases.atom` feeds over the releases
HTML:
1. **PowerShell lifecycle** on the official *support lifecycle* page: is 7.6 still the LTS? Has 7.7
   (on .NET 11) shipped and on what date? Confirm that 7.4/7.5 are already dead (scheduled
   2026-11-10).
2. **Status of Windows PowerShell 5.1** and of the current Windows Server (as of 2026-08, Windows
   Server 2025 is the latest version; there is a *vNext* in preview with no product name): any formal
   deprecation announcement, or a change of default shell?
3. **Pester**: is 6.1 stable yet? Re-read the official guide `pester.dev/docs/migrations/v5-to-v6`
   before migrating; as of 2026-08 v5 is in maintenance (critical bugs and security only).
4. **PSScriptAnalyzer** (1.25.0 as of 2026-03, MIT): a new version, new rules, default severity
   changes that break the gate? Pin the exact version in CI.
5. **PSResourceGet vs PowerShellGet**: which version **your** runtime ships (`Get-Module
   -ListAvailable`), and whether the PowerShellGet v3 compatibility layer is stable and inbox yet. Do
   not assume it.
6. **SecretManagement / SecretStore**: current version and maintenance status — **not verified as of
   Aug-2026**, confirm before fixing a version.
7. **App Control for Business vs AppLocker**: check the official Windows *deprecated features* list
   before asserting AppLocker's status (as of 2026-02 it did **not** appear as deprecated, but
   Microsoft states it does not meet the MSRC's security servicing criteria). Also verify the status
   of `WldpCanExecuteFile` and the CLM behaviour in the Windows build in use.
8. **JEA**: status and documented limitations in the target PowerShell version — **not verified in
   detail as of Aug-2026**.
9. Defaults that change with the version: `$PSNativeCommandUseErrorActionPreference`, experimental
   features (`Get-ExperimentalFeature`), and runtime CVEs (GitHub Advisories / MSRC) before fixing a
   version.

If the web contradicts this document, **the web wins** — flag the discrepancy.
