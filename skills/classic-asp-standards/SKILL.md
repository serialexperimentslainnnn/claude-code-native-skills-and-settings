---
name: classic-asp-standards
description: Classic ASP (ASP 3.0) on IIS - the worst attack surface in the Microsoft legacy catalogue, and the migrate-or-isolate decision. Use when working with .asp and .asa files, global.asa, server-side VBScript or JScript in <% %> blocks, the asp.dll ISAPI extension and the IIS ASP feature, Response.Write / Request.QueryString / Request.Form / Server.MapPath / Server.Execute / Server.Transfer / Session and Application objects, #include file and #include virtual directives, ADODB.Connection / ADODB.Recordset / ADODB.Command with CreateParameter, Scripting.FileSystemObject, Server.CreateObject with registered COM components, ASPError and detailed error pages, and when planning around the VBScript Feature on Demand deprecation or migrating Classic ASP to ASP.NET Core.
---

# Classic ASP (ASP 3.0) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Classic ASP** applications (ASP 3.0) served by IIS: corrective maintenance, hardening,
isolation and exit. Triggers: `.asp`, `.asa`, `global.asa`, `<% %>` blocks with server-side
VBScript or JScript, `asp.dll`, `Response.Write`, `Request.QueryString`/`Form`, `Server.CreateObject`,
`Server.Execute`, `ADODB.*`, `Scripting.FileSystemObject`, `#include file`/`#include virtual`.

**The crux: it still works, and that is why it survives.** Microsoft's statement (*Active Server Pages
(ASP) support in Windows*, KB 2669020; published 2020, revised 13-Aug-2025), **verbatim**:

> "The use of ASP pages with Microsoft Internet Information Services (IIS) is currently supported in
> all supported versions of IIS."

> "IIS is included in Windows operating systems. Therefore, both ASP and IIS support lifetimes are
> tied to the support lifecycle of the host operating system."

That is: **ASP has no end-of-support date of its own**; it inherits the host Windows Server's,
just like .NET Framework 4.8. Installing the ASP feature on the IIS of a supported Windows Server
is a supported configuration, not a tolerated bodge. **And that is exactly the problem**: there is
no force pushing anyone out, while the code accumulates twenty years of insecure patterns that
no modern analyser looks at. It is the worst attack surface in this legacy catalogue: **the
only one of the four that, by definition, serves untrusted HTTP traffic**.

**The real clock is not ASP: it is VBScript.** Official row of *Deprecated features in the Windows
client*, **verbatim**: *"VBScript is deprecated. In future releases of Windows, VBScript will be
available as a feature on demand before its removal from the operating system."* — announced in
**October 2023**. And in *Resources for deprecated features*, **verbatim**: *"VBScript will be
available as a feature on demand before being retired in future Windows releases. Initially, the
VBScript feature on demand will be preinstalled to allow for uninterrupted use while you prepare for
the retirement of VBScript."*

The three phases are therefore: **(1)** FOD **preinstalled and active** → **(2)** FOD **no longer active by
default**: it must be enabled explicitly for the application to keep working → **(3)**
**removal from the operating system**, with no way back. Planning criteria: **a Classic ASP
application written in VBScript has an expiry date even though ASP does not**, and phase 2 is the one that
breaks deployments by surprise —the day a new server is provisioned and the FOD no longer comes
installed—. The concrete dates for phases 2 and 3 **are not written here without verifying them**: see §8.

**Not applicable**: `web-app-servers-standards` decides **IIS as a server** —
sites, *application pools* and their identity, recycling, limits, ARR, certificates and TLS of the
*listener*, access logging—; here, only what the ASP code and its application `web.config`/metabase
decide. `dotnet-framework-legacy-standards` (ASP.NET **with** `System.Web`: WebForms, MVC5 —
**a different technology**, even if it shares IIS and mental bracket) and `dotnet-standards` (**ASP.NET Core:
the migration target, and the owner of the criteria for the resulting code**).
Siblings: `vb6-standards` (native VB6 — VB6's own support statement says **verbatim**
*"VBScript is unrelated to Visual Basic 6.0 and this support statement"*) and `vbnet-standards`
(VB.NET on the CLR). Three different things that look alike when you read them.
`legacy-modernization-standards`: portfolio and the invest/migrate/
retire decision, with `enterprise-architecture-standards`, `project-management-standards`,
`tech-leadership-standards`, `refactoring-tech-debt-standards` and `testing-qa-standards`. Also
`appsec-standards` (**vulnerability classes and threat modelling**; here only the concrete ASP
sinks), `vulnerability-management-standards`, `secrets-management-standards`,
`firewall-policy-standards` and `vpn-standards` (the isolation §5 demands), `sql-standards` and
`sqlserver-dba-standards`, `windows-server-ad-standards`, `powershell-standards`,
`grc-compliance-standards`.

## 2. Default decisions

> Verify on the web before pinning it (§8): the VBScript calendar is what changes.

| Decision | Default | Note |
|---|---|---|
| **New** ASP application | **None.** Forbidden | No exception, not even "just one little page" |
| Exposure | **Never directly to the internet** | §5; it is the rule that dominates everything else |
| Script engine | VBScript (what is there) | Count it as **debt with a clock** (§1), not as stable |
| Data access | ADO with **parameterised commands** | `ADODB.Command` + `CreateParameter`; nothing else |
| Errors in production | Generic `<httpErrors>`, `scriptErrorSentToBrowser=false` | Detail only to the server log |
| Session state | Avoid `Session` for sensitive data; never for authorisation | `Session` is in-process, lost when the *pool* recycles |
| Exit route | **Migrate or isolate** (§7) | There is no honest third option |

**Inventory first.** Before deciding anything: list the `.asp` files, the `#include`s, the COM components
the application registers or instantiates (`Server.CreateObject` with the exact ProgID), their vendor and
whether it still exists, and the data engine it talks to. **A registered COM component with no living vendor is a
hard blocker for any plan**, and it shows up in no dependency scanner.

## 3. Conventions for the code that survives

While it exists, the code that gets touched complies with:

- **`Option Explicit` on the first line of every `.asp`.** Without it, VBScript creates variables when you
  misspell them, silently, and that is the origin of real authorisation failures (a misspelled
  permission variable evaluates to empty and passes the check).
- **`On Error Resume Next` only scoped** to the specific statement that needs it, with an immediate
  check of `Err.Number` and `On Error GoTo 0` right after. At page level it is a global error
  swallower: the application carries on with corrupt state.
- **Close and release**: `Recordset`/`Connection` with `.Close` and `Set x = Nothing` — the connection
  *pool* and the COM objects are not collected on their own and one leak takes down the *app pool*.
- **`#include` is textual and happens at page compile time**: it takes no dynamic paths and nested
  inclusions create invisible dependencies. Document the graph; it is the first thing that
  surprises people in any migration.
- **No new logic in ASP**: new functionality is written outside (§7) and linked in.

## 4. Quality and testing

Section **omitted as artificial**: there is no supported modern toolchain (linter, static analysis,
formatter, test framework) for Classic ASP with VBScript. The only thing applicable is
characterising the observable behaviour with end-to-end tests before touching anything, and that
is set by `testing-qa-standards`.

## 5. Security — main section

**It is the reason this skill exists.** Typical Classic ASP code was written before OWASP
existed and has not been reviewed since. The dominant patterns, with their actual
fix:

**1. SQL injection by concatenation — the number one pattern in this code.** The native idiom of
ASP is to build the query with `&` from `Request.QueryString` or `Request.Form`. Every one of
those lines is a critical vulnerability exploitable without authentication. False fixes that
appear constantly in these codebases and that must be **rejected**: doubling single
quotes, filtering keywords (`SELECT`, `UNION`), limiting the field length, or validating in
client-side JavaScript. **The only fix is parameterisation**: `ADODB.Command` with
`CreateParameter` (name, type, direction, size, value) and `Parameters.Append`, or stored
procedures invoked with parameters —**never** a stored procedure that concatenates
inside—. Types and sizes are declared for real, not copied from the example next door.

**2. Reflected and stored XSS.** `Response.Write Request.QueryString("x")` writes the input as
is. Encode **on output and according to context** (HTML, attribute, JavaScript, URL); `Server.
HTMLEncode` covers the HTML case and **not** the rest. Adding CSP in the headers is mitigation, not
a fix.

**3. Dynamic inclusion and execution.** `Server.Execute` and `Server.Transfer` with a path derived from
the request allow any `.asp` on the server to be executed; combined with a file upload,
they are **remote code execution**. Rule: the target of `Server.Execute` is **always** a
constant or a value from a closed allowlist. The same for any `Server.MapPath` with
user input: *path traversal* straight into the filesystem.

**4. File upload.** The fatal failure is storing the file **under a directory that IIS
executes**: uploading a disguised `.asp` and requesting it over HTTP is RCE. Hard rules: store **outside the
web tree** and serve through a handler that reads the file; allowlist of extensions and verification
of the content, not of the name nor the `Content-Type`; server-generated name; and the uploads
directory with **script execution permissions disabled in IIS**, not just by convention.

**5. Detailed error messages exposed.** An uncontrolled ASP error prints the query, the
physical path and sometimes the connection string. It is free reconnaissance for the attacker and a data
leak in itself. `scriptErrorSentToBrowser=false`, generic error page, and the detail only
in the server log.

**6. Credentials in the code.** Connection strings with user and password in `global.asa` or in
a configuration `include`: it is the norm here. Take them out (`secrets-management-standards`), rotate them
assuming they are already known, and check that **no configuration file is servable over
HTTP** (an included `.inc` or `.txt` downloads as is: rename it to `.asp` or take it out of the tree).

**7. Session and authorisation.** Check authorisation **on every page**, not on the login page nor in
an `#include` that someone can forget. The ASP session cookie must be `HttpOnly` and `Secure`.
And do not trust `Session` for anything that an *app pool* recycle can throw away.

**Why a WAF in front fixes none of this.** A WAF filters by patterns over the request: it does not
know the query that is going to be built, nor which file is going to be executed, nor whether whoever uploads the
file is authorised. Against injection by concatenation it reduces automated noise and **does not
stop an attacker who tunes the payload**; against an authorisation failure —the most common and the most
expensive— it can do absolutely nothing, because the malicious request is syntactically identical to
the legitimate one. A WAF is **a layer that buys time while the code is fixed or the
application is isolated**; declaring it a permanent compensating control in front of an audit is unsustainable, and
treating it as a fix is the decision that turns a finding into a breach.

**Privileges and containment**: *application pool* with its own minimal identity, without write permissions
over the web tree, without `sysadmin` on the database engine —a user with permissions only
over the objects it uses—, and restricted network egress (`firewall-policy-standards`): if the
application is compromised, it must not be able to call home.

## 6. Operability

Section **deliberately reduced**: server operation —*app pools*, recycling, limits,
TLS, logging— belongs to `web-app-servers-standards` and is not duplicated here. What is specific to the
code: `Session` is in-process state and **any recycle loses it**, so no load balancing without
affinity and no horizontal scaling without redesigning the state; and COM object leaks (§3) are the
usual cause of cascading restarts. Useful telemetry comes out of the IIS log, not from instrumentation in
the code: there is none.

## 7. Exit: migrate or isolate, and prohibitions

**There are only two honest recommendations, and the choice is decided by one question: is the
application reachable from an untrusted network?**

- **If it is public or reachable from the internet: migrate.** There is no configuration that makes this
  codebase acceptable against hostile traffic. Route: **strangler fig** — put ASP.NET Core in front as a
  *reverse proxy* (YARP) and move route by route, starting with the ones that touch data and authentication, with
  the application live. The target and its quality are governed by `dotnet-standards`. Rewrite in parts,
  never all at once: the business logic of these applications is not documented anywhere else
  and the *big bang* loses rules nobody knew existed.
- **If it is strictly internal, stable and with no roadmap: isolate** and freeze, with a review date.
  Segmented network and *default-deny* on ingress and egress, access only via VPN or from an identified
  network, strong authentication in front, rotated credentials, silenced errors, and the SQL
  injections **fixed all the same** (the insider threat and lateral movement exist). Isolation
  buys time; it does not absolve you of §5.
- **Migrating the script engine is not an option**: rewriting the VBScript in server-side JScript
  keeps every problem and adds a new one. The VBScript calendar (§1) is a reason to
  leave ASP, not to change language within ASP.

- ❌ FORBIDDEN to create a **new** Classic ASP page, under any circumstance.
- ❌ FORBIDDEN to expose a Classic ASP application directly to the internet.
- ❌ FORBIDDEN to build SQL by concatenating user input. No exception for "it is a numeric id".
- ❌ FORBIDDEN to "sanitise" by doubling quotes or filtering keywords instead of parameterising.
- ❌ FORBIDDEN `Server.Execute`/`Server.Transfer`/`Server.MapPath` with paths derived from the request.
- ❌ FORBIDDEN to store uploaded files in a directory with script execution enabled.
- ❌ FORBIDDEN to send detailed errors to the browser in production.
- ❌ FORBIDDEN credentials in `global.asa` or in files servable over HTTP (`.inc`, `.txt`).
- ❌ FORBIDDEN to omit `Option Explicit`.
- ❌ FORBIDDEN `On Error Resume Next` at page level.
- ❌ FORBIDDEN to declare a WAF as the fix for an injection or authorisation finding.
- ❌ FORBIDDEN to plan as if ASP were indefinite: ASP has no EOL of its own, **VBScript does have a
  retirement calendar** (§1), and that is the one that rules.

## 8. Mandatory web verification

Always check: the **VBScript retirement calendar** —phases, and above all **in which version of
Windows the FOD stops coming enabled by default and when it is retired**—, against the Windows
deprecated features page and the Windows IT Pro blog; whether the ASP support statement
(KB 2669020) still says *"currently supported in all supported versions of IIS"*; the end-of-support
date of the **host Windows Server**, which is ASP's clock; the status of the vendor of each
COM component in the inventory; CVEs of IIS and of those components.

**Declared gaps (no verified data, do NOT fill in from memory)**: **the concrete dates of
phase 2 (VBScript disabled by default) and of phase 3 (retirement) are not verified verbatim as of
Aug 2026** — the official Microsoft documentation consulted describes the phases *"in future Windows
releases"* **without giving a year**, and the figures circulating in the technical press do not agree with each other; **do not
write a date into a plan without getting it from the primary source**. Also a **Declared gap**: whether
the IIS ASP feature is still installable on the latest published version of Windows Server (test it,
do not assume); number of Classic ASP sites in production or market share — there is no reliable public
figure, do not cite any.

If the web contradicts this document, **the web wins** — flag the discrepancy.
