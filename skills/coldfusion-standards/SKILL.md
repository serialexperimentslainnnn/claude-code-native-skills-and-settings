---
name: coldfusion-standards
description: CFML applications on Adobe ColdFusion, Lucee or BoxLang - a commercial runtime with a heavy exploitation history, and the migrate-or-freeze decision. Use when working with .cfm, .cfc and .cfml files, Application.cfc and Application.cfm, cfscript blocks and tag-based CFML, cfquery and cfqueryparam, cfoutput, cfloop, cfinclude, cfmodule, cfinvoke, cffile and cfftp, cfhttp, cfexecute, cfdocument and cfpdf, cfmail, cflock, cfthread, cfform, CFCs with access="remote" methods, application-scope and session-scope variables, evaluate() and iif() dynamic evaluation, serializeJSON and deserializeJSON, the CFIDE/administrator and cf_scripts directories, WEB-INF/cfusion, neo-*.xml configuration files, lucee-server.xml and lucee-web.xml, box.json and CommandBox servers, BoxLang runtimes and the bx-compat-cfml module, Adobe ColdFusion 2021 / 2023 / 2025 licensing and updates, or planning a move from Adobe ColdFusion to Lucee, to BoxLang, or to a rewrite.
---

# ColdFusion / CFML standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

CFML applications on **Adobe ColdFusion**, **Lucee** or **BoxLang**: maintenance, hardening, engine
change and exit. Triggers: `.cfm`/`.cfc`, `Application.cfc`, `cfquery`, `cfqueryparam`, `cfscript`,
`cffile`, `cfexecute`, `CFIDE/administrator`, `lucee-server.xml`, `box.json`, BoxLang.

**The axis: ColdFusion still exists and it is commercial — and that is half the decision.** It is not
an abandoned language you drag along: it is a paid product, with live versions and an annual invoice
that has changed shape. The other half comes from its security record (§5). Verified data:

- **Adobe ColdFusion**, read from Adobe's own end-of-life matrix (`helpx.adobe.com`, HTML downloaded
  and parsed, HTTP 200): **CF 2025** — availability **2025-02-25**, end of *core support*
  **2030-02-26**, *extended support* **N/A**; **CF 2023** — GA 2023-05-17, core until **2028-05-16**,
  extended until 2029-05-16; **CF 2021** — core ended on **2025-11-10** (already past), extended
  until **2026-11-10**; CF 2018 and earlier, out for years. The two nuances that decide: **Adobe's
  extended support is "best effort" for migrating and does not include security patches** — that is,
  a CF 2021 today is an **unpatched** server even though it appears "in support" — and **CF 2025 has
  no extended phase listed**, so its real date is a single one.
- **Licensing model: it changed.** Since CF 2025 Adobe sells **subscription only** — perpetuals
  discontinued, the 2021/2023 ones already purchased remain valid — per server and with core coverage
  (**Standard covers 2 cores**, **Enterprise up to 8**), activated through the Adobe Admin Console.
  The published annual cost is around **≈$2,930/year (Enterprise)** and **≈$960/year (Standard)**,
  with sources giving a different figure for Standard: figures **indicative and to be verified**
  (§8). The practical consequence of counting cores on large virtual machines is that the invoice for
  someone coming from perpetual can multiply, and that is today the main driver of the migration to
  Lucee.
- **Lucee** (the open source alternative): licence **LGPL-2.1**, verified by reading the raw file —
  and with the usual trap: **it is not in `LICENSE` nor on `main`/`master`**, but in **`License.txt`
  on the default branch `7.0`** (the repository API confirms it as `LGPL-2.1`). Two stable lines
  maintained in parallel: **7.0.4.34** and **6.2.7.16**, both from **2026-06-04**.
- **BoxLang** (Ortus Solutions): **it is not "another CFML"**, it is a **new dynamic language for the
  JVM** with a **CFML compatibility module** (`bx-compat-cfml`, with `adobe` or `lucee` mode) that
  allows running existing applications. Licence **Apache-2.0**, verified raw — and here the file is
  **`license.txt` in lowercase on the `development` branch**, with a commercial preamble in front
  that makes the GitHub API classify it as `NOASSERTION`: **read the file, do not trust the label**.
  Version **1.16.0** (2026-07-30), on a monthly cadence. Open-core model: the runtime is Apache-2.0
  and there are paid subscriptions (BoxLang+) for support, SLA and premium modules.

**Not applicable**: `web-app-servers-standards` (**already written**) owns the **server** that serves
CFML (Tomcat/IIS/Apache in front, connectors, TLS, limits); here only what the code and the CFML
engine's configuration decide. `legacy-modernization-standards` is the umbrella and
`enterprise-architecture-standards` (**already written**) provides inventory, the TIME model and the
"R"s — here what each option implies technically —, with `refactoring-tech-debt-standards`,
`testing-qa-standards`, `project-management-standards`, `tech-leadership-standards`,
`cicd-standards` and `git-workflow-standards` (**already written**). `appsec-standards` and
`vulnerability-management-standards` (**already written**) provide methodology, triage and the
correct use of KEV/EPSS — here CFML's concrete *sinks* —, with `opensource-licensing-standards`
(**already written**: analysing LGPL and Apache-2.0 is theirs), `sql-standards`,
`firewall-policy-standards` and `grc-compliance-standards`. If the destination is a rewrite,
`jvm-spring-standards`, `dotnet-standards`, `php-standards` or `python-standards` rule depending on
the stack. Sister skills of the legacy block — **they share the "legacy" label and little else** —:
`jsp-struts-standards`, `classic-asp-standards`, `abap-sap-standards`,
`plsql-oracle-forms-standards`, `vb6-standards`, `dotnet-framework-legacy-standards`.

## 2. Default decisions

> Verify on the web before fixing it (§8): versions, Adobe's calendar, licences and KEV.

| Decision | Default | Note |
|---|---|---|
| Engine on a version without *core support* | **Update or migrate. Now** | No patches = a pending incident (§1) |
| Queries | **`cfqueryparam` on every parameter. Non-negotiable** | §5 |
| Style | **`cfscript`** for logic; tags for the view | §3 |
| Administration panel | **Never reachable from the internet** | §5; the rule that dominates everything else |
| A new application in CFML | **No**, unless there is a consolidated CFML team and a written decision | §7 |
| Free alternative | **Lucee** (LGPL-2.1) if the goal is removing the licence | §7: **a migration, not a switch** |
| Adobe↔Lucee compatibility | **Assume adaptation work**, always | §3 |
| Security updates | Apply them **outside the normal cycle**, with their own window | §5 |

## 3. The language and the typical application

**Tags versus *script***: CFML admits both forms for almost everything
(`<cfquery>`/`queryExecute`, `<cfloop>`/`for`). Criterion: **logic goes in `cfscript`** — inside
components — and tags stay for the output template. Mixing business logic into the `.cfm` page
reproduces the *scriptlet* problem: it is not tested, not reused and it hides the security failures.

**The minimum structure that is required**: `Application.cfc` with an explicit lifecycle
(`onApplicationStart`, `onSessionStart`, `onRequestStart`, `onError`), `.cfc` components with
declared method access (`private`/`package`/`public`, and `remote` **only** where there is a real
endpoint), and queries encapsulated in data access components, never scattered through the views.
Scopes (`application`, `session`, `request`, `variables`) are always declared explicitly: the
**implicit scope** is the classic source of data leaks between requests and of race conditions.
Writing to `application`/`server`, **always inside a `cflock`**.

**Adobe CF and Lucee are not interchangeable without work, and it must be said before signing the
project.** They share 90% of the language and there the comfortable similarities end: they differ in
proprietary functions and tags (PDF generation, .NET integration, services that only exist in one),
in the handling of nulls and type conversion, in administration — console, admin API, scheduled
tasks, datasources, mappings —, in the default security settings, and in the edge-case behaviour that
no documentation describes but that your code depends on. **Planning rule: the Adobe→Lucee migration
is estimated with an inventory and a real test of the critical flows, not with "it is CFML, it will
work".** The same, all the more so, for BoxLang: its compatibility module reduces the change, it does
not eliminate it.

## 4. Quality and testing

A section **reduced to what applies**: there is no *toolchain* comparable to that of the mainstream
ecosystems. What is used: testing with the community frameworks (xUnit style for CFML) over
components — which **requires** having taken the logic out of the pages (§3) —, **end-to-end
characterisation** of the critical flows before changing engine (it is the only control that detects
the Adobe↔Lucee differences), and a **CFML linter/analyser** if the project has one: verify its
status and licence before adopting it (§8). The minimum realistic CI gate: **the build deploys to a
clean engine of the target version and runs the E2E suite**; without that, any engine or version
change is a gamble.

## 5. Security — the main section

**The record is not anecdotal, it is structural.** Verified by downloading **CISA's KEV catalogue**
(raw JSON, version **2026.08.04**): there are **16 Adobe ColdFusion vulnerabilities catalogued as
exploited in the wild**, and they are not all old — the most recent, **`CVE-2026-48282` (*path
traversal*), was added on 2026-07-07**. Others flagged: `CVE-2024-20767` (access control, added
Dec-2024), `CVE-2023-29300` and `CVE-2023-38203` (deserialisation, **both marked with known use in
ransomware campaigns**), `CVE-2023-26360`, `CVE-2023-29298`, `CVE-2023-38205`, `CVE-2017-3066`,
`CVE-2018-15961` (unrestricted file upload), `CVE-2010-2861` (also ransomware). **The recurring
pattern**: path traversal and access control on the **administration panel**, and deserialisation.
Operational consequence: **a ColdFusion security update does not wait for the quarterly window**; it
is applied with its own procedure and in a hurry, and an engine without *core support* receives none
at all.

**Hard code rules:**

- **`cfqueryparam` on every parameter of every query. A non-negotiable requirement.** Concatenating
  variables inside `<cfquery>` is direct SQL injection, and it is the dominant pattern in old CFML.
  False fixes to be rejected: `#` with `htmlEditFormat()`, checking `isNumeric()` "and that is it",
  or filtering keywords. In addition to the parameter, **`cfsqltype`** is declared — without it part
  of the type validation is lost. The same in `queryExecute()` with named parameters. Stored
  procedures, with `cfprocparam`.
- **Dynamic evaluation**: `evaluate()`, `iif()` with constructed strings, `cfinclude` with a template
  derived from the request and dynamic `cfmodule` allow executing code or including arbitrary files.
  Replace with structures and closed allowlists; **never** user input there.
- **`cfexecute`** with arguments derived from the request is system command execution. If there is no
  alternative, a fixed absolute path and arguments from an allowlist.
- **File uploads (`cffile action="upload"`)**: it is the historical *webshell* route in this
  ecosystem. Store **outside the served tree**, a server-generated name, an allowlist by content and
  **`accept`/`strict` configured** — the client's `Content-Type` proves nothing —, and the upload
  directory **with no CFML execution** in the server's mapping.
- **XSS**: `#variable#` in the output writes it as-is. Encode **per context** with the output
  encoding functions (`encodeForHTML`, `encodeForHTMLAttribute`, `encodeForJavaScript`,
  `encodeForURL`); `htmlEditFormat()` is insufficient and superseded.
- **Deserialisation**: do not deserialise objects coming from the request; `deserializeJSON` over
  untrusted input, with subsequent shape validation.
- **Errors and debugging**: debug output disabled in production (it prints queries, variables and
  paths), a generic error page with `onError`, and detail **only to the log**.
- **Secrets**: datasource credentials and keys **outside the code and outside servable files**;
  `secrets-management-standards`.

**The rule that summarises everything else: the administration panel is not exposed to the
internet.** `/CFIDE/` — and in particular `/CFIDE/administrator` —, the Lucee console and any engine
administration interface **are restricted at the network level** (listening on an internal interface
or IP filtering on the server in front), with their own rotated password, and **it is checked that
they are not reachable from outside** on every deployment. Most of the CVEs in the list above are
exploited against that surface: taking it off the internet turns a critical into a high, and often
into something unexploitable. Mandatory complement: **restrict the server's outbound network
traffic** — if it falls, let it not phone home — and run the engine as an unprivileged user with no
write access to the application tree.

## 6. Operability

What is specific to the engine: `session`/`application` state lives **in the process** unless
external storage is configured, so **there is no load balancing without affinity and no horizontal
scaling** without solving that first; `cfthread` and the engine's scheduled tasks are work that is
lost on every restart and that nobody monitors until it fails; and the typical leaks — unbounded
queries dumped into memory, caches in `application` with no expiry policy — take down the whole JVM.
JVM metrics (memory, GC, threads) and slow requests: it is a Java server, it is instrumented as such
(`observability-standards`). Sizing the container and the web server belongs to
`web-app-servers-standards`.

## 7. Decision: migrate, change engine or touch nothing

**When to migrate to Lucee (dropping the licence)**: when the subscription cost is the dominant
problem, the application **does not use Adobe proprietary functionality** (advanced PDF, .NET
integration, exclusive services) and there is a team to test it properly. It is a migration with an
inventory, a test bench and a rollback plan, **not an installation change** (§3). You gain: zero
licence cost and an openly maintained engine. You lose: the vendor's commercial support — unless you
contract it separately — and the features that do not exist.

**When to look at BoxLang**: when on top of the cost the language itself weighs on you and you want a
gradual exit towards the JVM while keeping the code running. It is the newest of the three options
and therefore the least proven in large-scale production; its monthly cadence is a sign of a living
project, not of demonstrated maturity. **A decision made with a real pilot, not with a slide deck.**

**When to rewrite**: when the application has logic in the pages and nobody understands it, when it
depends on an unsupported engine and updating drags half the code along, or when the business has
changed. The rewrite is done in parts (*strangler fig*) and the quality of the destination is
governed by the chosen stack's skill.

**When NOT to touch anything — and it is a legitimate recommendation, not laziness**: an **internal**
application, stable, with no pending development, on a **supported and patched** engine, and with no
internet exposure. There the right work is to **freeze with hygiene**: a supported version, patches
up to date, the administration panel off untrusted networks, tested backups, a dependency inventory
and **a written annual review date**. Migrating for aesthetics costs money and adds risk with no
return. What is **not** an option is "touch nothing" on an engine without *core support*: that is not
freezing, it is accumulating an incident.

- ❌ FORBIDDEN to run in production an engine without the vendor's *core support* (or without
  maintenance in the case of Lucee/BoxLang).
- ❌ FORBIDDEN to expose `/CFIDE/administrator` or the Lucee console to untrusted networks.
- ❌ FORBIDDEN any query with variables without `cfqueryparam`/a named parameter. No exceptions.
- ❌ FORBIDDEN to "sanitise" with `htmlEditFormat()`, `isNumeric()` or word filters instead of
  parameterising.
- ❌ FORBIDDEN `evaluate()`, `iif()` with strings, `cfinclude`/`cfmodule` or `cfexecute` with user
  input.
- ❌ FORBIDDEN to store uploaded files inside the served tree or to trust the `Content-Type`.
- ❌ FORBIDDEN to leave debugging enabled, or to show stack traces and queries to the user in
  production.
- ❌ FORBIDDEN to write to `application`/`server` without `cflock`, and to use implicit scopes.
- ❌ FORBIDDEN credentials in the code or in files reachable over HTTP.
- ❌ FORBIDDEN to treat the Adobe→Lucee (or →BoxLang) change as an installation change with no
  testing.
- ❌ FORBIDDEN to delay a ColdFusion security update to the ordinary quarterly window.
- ❌ FORBIDDEN to declare a WAF as the fix for a CVE in the engine or in the administration panel.
- ❌ FORBIDDEN to plan the renewal with the licence **remembered**: the model changed with CF 2025 and
  it is counted per core (§8).
- ❌ FORBIDDEN new development in CFML without a written decision, with an owner, on the engine and
  the horizon.

## 8. Mandatory web verification

Always check: **Adobe's end-of-life matrix**
(`helpx.adobe.com/support/programs/eol-matrix.html`, which gives GA, end of *core* and end of
*extended* per version) and what exactly extended support includes; the installed version and update
level against the **security updates** published by Adobe; the current stable versions of **Lucee**
and **BoxLang** and their licence **by reading the raw file** — remember: Lucee has it in
`License.txt` on branch `7.0`, BoxLang in `license.txt` on `development`, and GitHub's automatic
label for BoxLang says `NOASSERTION` even though the text is Apache-2.0 —; **CISA's KEV catalogue**
in JSON, filtering by `Adobe ColdFusion`, with its `catalogVersion`; and the price and terms of
Adobe's subscription before budgeting.

**Declared gaps (no verified data, do NOT fill from memory)**: (a) the claim that **Adobe's extended
support does not include security patches** comes from search-engine summaries of Adobe's policy,
**not from a verbatim quote of the primary source**: it is a critical fact for CF 2021 (in its
extended phase until Nov-2026) — confirm it before using it as an argument; (b) **prices**: the
figures in §1 come from third parties and **do not agree with each other for the Standard edition**,
and the real cost depends on cores, region and reseller: ask for a quote, do not cite these figures;
(c) the detail of which Adobe functionality does **not** exist in Lucee or in BoxLang is not verified
— it is determined with a code inventory, not with a comparison table; (d) the status and licence of
CFML test frameworks and linters — not verified; (e) **Lucee**'s support and EOL policy per version
line (6.2 versus 7.0) — not located, do not assume it.

**Flagged discrepancies**: Adobe's matrix gives the end of *core support* for **CF 2025 as
2030-02-26** and **with no extended phase**, while secondary sources cite "8 April 2030" and an
extended phase until 2031 — **Adobe's matrix wins**. And the "current" version of **BoxLang**
announced in press releases (1.13) is behind the one the repository publishes (**1.16.0**,
2026-07-30): check the project's own source, not the press release.

If the web contradicts this document, **the web wins** — flag the discrepancy.
