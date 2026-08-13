---
name: jsp-struts-standards
description: Legacy Java web applications built on JSP and Apache Struts - a security problem before it is a maintenance problem. Use when working with .jsp, .jspf, .jspx and .tag files, scriptlets and expressions (<% %>, <%= %>, <%! %>), page/include/taglib directives, .tld tag libraries and JSTL c:/fmt:/fn: tags, struts-config.xml, struts.xml, validation.xml, tiles-defs.xml and tiles.xml, org.apache.struts Action / ActionForm / DispatchAction / LookupDispatchAction and ActionServlet, Struts 2 ActionSupport, interceptors, result types and OGNL expressions in %{...} or s: tags, the Struts file upload interceptor and Action File Upload, Struts 1 or Struts 2.3/2.5 dependencies in pom.xml or WEB-INF/lib, struts2-core and struts2-rest-plugin jars, web.xml servlet and filter mappings, .war packaging of an old Java web app, javax.servlet.http.HttpServlet and javax.servlet.jsp imports in legacy sources, JSP pages that build SQL or HTML by string concatenation, and when planning to migrate such an application to Spring Boot, to an API with a separate front end, or to rewrite it.
---

# JSP and Apache Struts standards (legacy Java web)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Legacy Java web applications built with **JSP** and **Struts 1 / Struts 2**: diagnosis,
containment, patching and exit. Triggers: `.jsp`/`.jspf`/`.tag`, `<% %>`/`<%= %>`, `struts-config.xml`,
`struts.xml`, `ActionForm`, `ActionSupport`, OGNL, `.tld`/JSTL, `web.xml`, `.war`, `struts2-core`.

**The axis, and it has to be said in the first meeting: a JSP/Struts application in production is
almost always a security problem before it is a maintenance problem.** This is not an opinion about
ugly code: it is the framework's track record. Data verified by reading the **CISA KEV catalogue**
(*Known Exploited Vulnerabilities*, JSON file downloaded raw, version **2026.08.04**, 1,660
entries): there are **eight** Struts vulnerabilities catalogued as **exploited in the wild** —
`CVE-2017-5638` (also marked with **known use in ransomware campaigns**; it is the one from the
Equifax breach), `CVE-2018-11776`, `CVE-2017-9805`, `CVE-2020-17530`, `CVE-2013-2251`,
`CVE-2012-0391`, and two from **Struts 1**: `CVE-2017-9791` and `CVE-2006-1547`. An application like
that, reachable from the internet and unpatched, is not "detected" when it is exploited: it is
detected months later.

**State of the frameworks, verified:**

- **Struts 1 has been retired since 2013.** From the project's official announcement, **verbatim**:
  *"the Struts 1.x web framework has reached its end of life and is no longer officially supported"*,
  with the last version —1.3.10— published in **December 2008**. And on what happens if a serious
  flaw appears, **verbatim**: *"Since the end of support is reached, you will either need to find
  mitigations, patch the existing Struts 1 source code yourself or migrate your project to another
  web framework."* Translated into a decision: **there is no patch for Struts 1, and there will not
  be one.**
- **Struts 2 is still alive, but in practice it is no longer called "2.x"**: the active branches are
  **7.x and 6.x** (verified in the Atom feed of releases of the official repository: **Struts 7.3.0**
  published on **1 Aug 2026** and **6.11.0** on 29 Jun 2026 — the site's `releases.html` page was
  behind, at 7.2.1, on the same day). **The 2.5.x branch, which is where most of the corporate estate
  sits, ended its life on 30 Apr 2024** after 2.5.33; 2.3 ended in May 2019. The project **does not
  publish an EOL calendar in advance**: it announces it a few months ahead, so "we are supported" is
  a claim with an unknown expiry date.
- **JSP is not dead, it is frozen.** It is still a **Jakarta EE** specification (*Jakarta Pages*
  **4.0** in **Jakarta EE 11**, published in Jun 2025; Tomcat 11 implements it), in maintenance mode:
  no new functionality and **no official retirement date**. That is, the problem with a JSP
  application is not that the standard expires, it is what people wrote inside it.
- **The real technical barrier of any migration is the `javax` → `jakarta` namespace change**
  (Jakarta EE 9 onwards). It is not a *search & replace*: it affects every `import`, every
  descriptor, the *tag libs* and **all the transitive dependencies**, including those no longer
  maintained. Verified in the Tomcat version table: **Tomcat 9.0.x is the last `javax` branch**
  (Servlet 4.0 / JSP 2.3, Java 8+), while **10.1.x** (Servlet 6.0 / Pages 3.1, Java 11+) and
  **11.0.x** (Servlet 6.1 / Pages 4.0, Java 17+) are already `jakarta`. **That jump is the project**,
  not the preamble to the project.

**Not applicable**: `web-app-servers-standards` (**already written**) owns the **server** —Tomcat,
WildFly, WebLogic, WebSphere, httpd/nginx in front, limits, threads, TLS, `server.xml`— and here only
the coupling that decides the migration appears (§2). `jvm-spring-standards` (**already written**)
wins on **modern Java and Spring, which are the destination** of this migration: the quality of the
resulting code is governed by their criteria, not by these. `legacy-modernization-standards`
(**already written**) is the umbrella and `enterprise-architecture-standards` (**already written**)
provides the inventory, the TIME model and the "R"s —here what each option implies technically—, with
`refactoring-tech-debt-standards` and `testing-qa-standards` (**already written**: *strangler fig*,
characterisation without tests), `project-management-standards`, `tech-leadership-standards`,
`cicd-standards` and `git-workflow-standards`.
`appsec-standards` and `vulnerability-management-standards` (**already written**) provide methodology,
triage and KEV/EPSS —here the concrete JSP/Struts *sinks*—, with `frontend-frameworks-standards` and
`api-design-standards` if the destination is API + separate front end, `sql-standards`,
`firewall-policy-standards` and `grc-compliance-standards`. Sister skills of the legacy block —**they
share the "legacy" label and little else**—: `abap-sap-standards`, `plsql-oracle-forms-standards`,
`coldfusion-standards`, `dotnet-framework-legacy-standards`, `php-standards`,
`classic-asp-standards`, `vb6-standards`.

## 2. Default decisions

> Verify on the web before pinning it (§8): the Struts version, the server calendar and KEV.

| Decision | By default | Note |
|---|---|---|
| Struts 1 in production | **Past the deadline. Exit plan with a date, now** | No patch is possible (§1) |
| Struts 2.3 / 2.5 | **Upgrade to a supported branch (6.x/7.x) or leave** | A major change, not a version *bump* |
| Logic in `.jsp` | **Zero.** The JSP only renders | §3 |
| Output in JSP | **`<c:out>` / `fn:escapeXml`**, never raw `<%= %>` | §5 |
| Data access from JSP | **Forbidden** | Neither `DriverManager` nor queries in the page |
| Exposure | **Never directly to the internet** while the framework is not up to date | §5 |
| Server | The one already there, **with its calendar in the inventory** | §2, table below |
| Migration destination | **Spring Boot without JSP** or **API + separate front end** (§6) | Decided by the state of the front end, not by taste |

**The application server calendar — it is half the project and almost nobody looks at it.** Verified
data: **Tomcat** today supports 11.0.x, 10.1.x and 9.0.x; **8.5.x died on 31 Mar 2024**, 10.0.x on
31 Oct 2022, 7.0.x on 31 Mar 2021 and 8.0.x on 30 Jun 2018 (official version table). **WebLogic**
(PDF *Oracle Lifetime Support Policy — Fusion Middleware*, effective 13 Apr 2026): **12.2.x Premier
until Dec 2026 and Extended until Dec 2027**; 14.1.x until Dec 2030/Dec 2033; 15.x (GA Oct 2025)
until Oct 2030/Oct 2033. **JBoss EAP 7**: maintenance support ended on **30 Jun 2025**, now in paid
ELS until **31 Oct 2027** (ELS-2 until 2030); **EAP 8 requires Java 17**. **WebSphere** is the
exception that breaks the assumption: IBM states that **there is no planned end-of-support date for
8.5.5 or 9.0.5** — there is no countdown there, although there is a practical limit: a *fix pack* is
only eligible for an *iFix* for two years from its publication (confirm in the primary source, §8).

Conclusion: **coupling to the server is what turns "upgrade the framework" into "migrate the
application"**. An application that depends on the container's JNDI, on EJBs, on the server's
security *realms*, on `jboss-web.xml`/`weblogic.xml` or on libraries dropped into the server's `lib`
**does not move on its own**: that has to be inventoried before estimating anything.

## 3. Typical architecture and why it hurts

The pattern is always the same: `ActionServlet` (Struts 1) or the dispatcher filter (Struts 2) routes
according to `struts-config.xml`/`struts.xml` towards an action; the action fills a form or a value
object and forwards to a `.jsp` that renders. On top of that, `Tiles` for templates and in-house
*tag libs*.

**The scriptlet is the structural problem.** A `<% %>` with logic inside the page mixes
presentation, business and data access in a file that **does not compile until somebody visits it**,
that **cannot be unit tested**, that appears in no dependency analysis and that the IDE barely
understands. Real consequences, not aesthetic ones: the same business rule ends up copied into six
pages and diverging; a model change forces you to review hundreds of JSPs by hand; and **injection
and XSS live there**, out of reach of any systematic review. That is why an application with logic in
the JSPs is, literally, **unrepairable piecewise**: no incremental refactor is possible without first
taking the logic out of the pages.

Rules for the code that survives for the duration of the migration:

- **Zero logic and zero data access in `.jsp`**; only tags and expressions over an already prepared
  model. Every new scriptlet is rejected in review.
- **JSTL and EL** instead of scriptlets, and `<c:out>` for **all** output.
- **No new functionality in Struts**: new things are written outside and linked (§6).
- **Dependencies are inventoried first**: the full `pom.xml`/`WEB-INF/lib`, with the version and the
  date of last maintenance of each jar. In these applications it is normal to find libraries
  abandoned more than a decade ago that no scanner recognises because they were dropped in by hand.

## 4. Quality and testing

Section **reduced to what adds value**: there is no comfortable modern *toolchain* for JSP —the
linter and static analysis see little inside a page, and unit tests over Struts 1 actions require
scaffolding that nobody maintains any more—. What is done, in this order: **SCA over the
dependencies** (§5) because that is where the real risk is and it is cheap; **end-to-end
characterisation tests** over the critical flows before touching anything, which are what allow you
to migrate without losing undocumented business rules (`testing-qa-standards`); and, as logic is
extracted from the JSPs into classes, **unit tests over those classes** with the criteria of
`jvm-spring-standards`. The minimum realistic CI gate: **reproducible build + SCA that breaks on a
known exploited critical vulnerability + E2E suite of the money and authentication flows**.

## 5. Security — main section

**1. Server-side expression evaluation (OGNL).** This is the family that made Struts 2 famous: the
framework evaluates OGNL expressions over parameters, headers or request values, and a manipulated
expression ends up executing code. `CVE-2017-5638` (multipart parser, `Content-Type` header) and
`CVE-2018-11776` (unvalidated `namespace` in the configuration) are **both in KEV**. Rules: **never**
pass user input into anything that gets evaluated (`%{...}`, `${...}` in results, dynamic
action/namespace names), and keep the framework on a supported branch, which is the only thing that
really cuts off this family.

**2. Deserialisation and RCE via *plugin*.** `CVE-2017-9805` (REST plugin with XStream over XML) is
in KEV: deserialising untrusted data is remote execution, full stop. Hard rule: **no endpoint
deserialises Java objects, XML or formats that instantiate arbitrary classes from the request**;
*plugins* that are not used, **uninstalled from the `.war`** —not routing them is not enough—.

**3. File upload.** `CVE-2023-50164` and `CVE-2024-53677` are *path traversal* in the upload logic
ending in RCE, and the second is an incomplete fix of the first; Apache's correction **is not
backwards compatible** (it forces `Action File Upload` and a branch upgrade), which is exactly why
many people did not apply it. Rules: server-generated name, validated canonical path, storage
**outside the served tree**, allowlist by content and a maximum size. **Exact, checkable datum**:
neither of those two CVEs appeared in the KEV consulted (version **2026.08.04**), despite public
reports of active exploitation — **the absence of a CVE from KEV does not mean it is not being
exploited**, and using KEV as the sole source of prioritisation is a triage error
(`vulnerability-management-standards`).

**4. XSS from unescaped output.** `<%= request.getParameter("x") %>` is direct reflected XSS, and it
is the dominant pattern in these codebases. You escape **on output and according to context** (HTML,
attribute, JavaScript, URL): `<c:out>`/`fn:escapeXml` cover HTML, **not** the rest —a variable
injected inside a `<script>` needs JavaScript encoding—. CSP helps, it does not fix.

**5. SQL injection** in JSPs and actions that concatenate strings: parameterised queries
(`PreparedStatement`), always; `sql-standards` for the detail.

**6. Dependencies.** The typical `.war` drags along dozens of old jars: **SCA mandatory**, with an
inventory of what was dropped in by hand into `WEB-INF/lib` (which the dependency manager does not
see) and of what lives in the server's `lib`.

**7. Descriptor hygiene**: no error pages with a stack trace, `WEB-INF` not servable, session cookies
`HttpOnly`/`Secure`/`SameSite`, directory listings disabled, container administration consoles
**off the internet and with rotated credentials**.

**Why an unpatched framework is not offset by a WAF.** A WAF filters patterns over the request; it
does not execute the application's logic. Against these families that means: OGNL payloads have
infinite variants (encoding, fragmentation, alternative fields) and **every Struts CVE has brought
its round of next-day *bypasses***; against deserialisation, the payload is a legitimate object from
a syntactic point of view; and against an authorisation flaw, the malicious request is identical to
the good one. A WAF **buys time while you patch or isolate**, and its real value is slowing down mass
automated scanning, which is not nothing. Declaring it a permanent compensating control before an
audit —or a reason not to upgrade— is untenable, and it is the decision that turns a finding into a
breach.

## 6. Exit

Three routes, and the choice is decided by **the state of the front end**, not by the team's
preference:

- **To Spring Boot with the JSPs removed.** It is the natural route when the business logic in Java
  has value and the interface is administrative forms. The dispatcher is replaced and the views are
  redone with a modern engine (Thymeleaf or another); **dragging the JSPs into Spring Boot is the
  trap**: technically possible in some scenarios, but it preserves the structural problem (§3) and
  adds packaging friction. *Strangler fig*: a *reverse proxy* in front and route by route.
- **API + separate front end.** When the interface has to be redone anyway: the logic is exposed as
  an API (`api-design-standards`) and the front end is built separately
  (`frontend-frameworks-standards`). More expensive, and the only way if the application must be
  usable on mobile or integrate with third parties.
- **Full rewrite.** Justified when the logic is in the JSPs (§3) and there is nothing salvageable, or
  when the domain has changed so much that migrating would freeze obsolete rules. It requires prior
  characterisation: **the living specification is in the code, not in a document**.

**Containment for the duration of the migration** (and it has to be sized at the start, not when it
fails): take the application off the internet or put it behind strong authentication and an
identified network, restrict the server's network egress —if it falls, do not let it call home—, a
database user with minimum permissions, and monitoring with rules specific to these families
(`detection-engineering-standards`).

## 7. Prohibitions

- ❌ FORBIDDEN to deploy a **new** application on JSP or Struts, in any variant.
- ❌ FORBIDDEN to expose to the internet an application on Struts 1 or on an unsupported Struts 2
  branch, without a dated exit plan.
- ❌ FORBIDDEN to add scriptlets (`<% %>`, `<%! %>`) or business logic to a `.jsp`.
- ❌ FORBIDDEN database access from a JSP page.
- ❌ FORBIDDEN `<%= %>` with data coming from the user or from the database, unescaped.
- ❌ FORBIDDEN to build SQL by concatenation in actions or pages.
- ❌ FORBIDDEN to pass user input into server-side evaluated expressions (OGNL, dynamic EL) or into
  action, *namespace* or result names.
- ❌ FORBIDDEN to deserialise objects coming from the request; and unused *plugins*, out of the `.war`.
- ❌ FORBIDDEN to store uploaded files inside the served tree or with the name the client gives.
- ❌ FORBIDDEN to leave jars in `WEB-INF/lib` outside the dependency manager and the SCA.
- ❌ FORBIDDEN error stack traces and container administration consoles reachable from outside.
- ❌ FORBIDDEN to declare a WAF the fix for a framework CVE or a reason not to patch.
- ❌ FORBIDDEN to "migrate" by changing application server without resolving `javax` → `jakarta`: that
  is the work, not the paperwork.
- ❌ FORBIDDEN to estimate the migration without first inventorying dependencies, container coupling
  and critical flows without tests.

## 8. Mandatory web verification

Always check: the **supported Struts branch and version** and its EOL announcements (the project site
lags behind the repository: cross-check with the *releases* feed), the **Struts security advisories**
(S2-xxx) and whether any applicable CVE is in the **CISA KEV catalogue** —downloadable as raw JSON,
with `catalogVersion` and date—, the **supported container version** (official Tomcat table with its
EOL column; Oracle's *Lifetime Support Policy* PDF for WebLogic, with its effective date on the
cover; lifecycle published by IBM and by Red Hat), the current version of **Jakarta EE** and of
**Jakarta Pages**, and the maintenance status of every jar in the inventory.

**Declared gaps (no verified datum, do NOT fill in from memory)**: (a) the Struts EOL policy **is not
formally documented** by the project —the window of "about six months of security fixes after the
announcement" comes from secondary sources, not from a published policy—: do not plan on it; (b) the
**WebSphere** dates ("no planned end-of-support date" for 8.5.5 and 9.0.5) and the **JBoss EAP** ones
(ELS-1 until 31 Oct 2027, ELS-2 until 2030) come from search-engine summaries of IBM and Red Hat
pages, **not from a verbatim citation of the primary source**: confirm before using them in a plan;
(c) the date of **Jakarta EE 12** — the sources consulted contradict each other (one release plan
pointed to **Jul 2026** and the project page to **Q2 2027**): **declared discrepancy, do not pick one
without checking it**; (d) the state of third-party commercial support for unsupported Struts
branches is not verified (it exists, but neither terms nor coverage have been checked).

If the web contradicts this document, **the web wins** — flag the discrepancy.
