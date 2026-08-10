---
name: plsql-oracle-forms-standards
description: PL/SQL as a program language and Oracle Forms/Reports as a legacy application layer - two things with different futures. Use when writing or reviewing .pks/.pkb/.plb sources, CREATE OR REPLACE PACKAGE / PACKAGE BODY / PROCEDURE / FUNCTION / TRIGGER, anonymous PL/SQL blocks, %TYPE and %ROWTYPE declarations, ref cursors and cursor FOR loops, BULK COLLECT and FORALL with SAVE EXCEPTIONS and LIMIT, EXECUTE IMMEDIATE and DBMS_SQL dynamic SQL, DBMS_ASSERT input validation, bind variables versus literal concatenation, WHEN OTHERS exception handlers, RAISE_APPLICATION_ERROR, PRAGMA AUTONOMOUS_TRANSACTION, AUTHID DEFINER versus CURRENT_USER, package state and ORA-04068, invalid objects and recompilation, DBMS_PROFILER / DBMS_HPROF / PL/Scope, utPLSQL test suites, SQL Developer and SQLcl, and when working with Oracle Forms .fmb/.fmx/.pll/.olb/.mmb modules, Forms Builder, frmcmp and frmweb, WebUtil, Oracle Reports .rdf/.rep, Forms and Reports 12c or 14c, or planning a Forms-to-APEX / Forms-to-Java migration with ORDS.
---

# PL/SQL and Oracle Forms standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Business PL/SQL code (packages, procedures, functions, *triggers*) and Oracle Forms/Reports
applications. Triggers: `.pks`/`.pkb`, `CREATE OR REPLACE PACKAGE`, `BULK COLLECT`, `FORALL`,
`EXECUTE IMMEDIATE`, `DBMS_SQL`, `WHEN OTHERS`, `PRAGMA AUTONOMOUS_TRANSACTION`, `AUTHID`,
utPLSQL, `.fmb`/`.fmx`/`.pll`/`.rdf`, Forms Builder, WebUtil, migration to APEX.

**The axis: these are two things with different destinies and they are always mentioned together.**
Separate them before deciding anything.

- **PL/SQL is alive and is the foundation of a great deal of business.** It is not a language in
  retreat: it compiles inside an engine with support well into the 2030s (Oracle Database **19c**:
  Premier until **Dec 2029**, Extended until **Dec 2032**; **26ai**, LTS with GA **Oct 2025**, Premier
  until **Dec 2031** — verified in the PDF *Oracle Technology Products — Oracle Lifetime Support
  Policy*, *Effective Date: May 1, 2026*). Writing new PL/SQL in 2026 can be the right decision.
- **Oracle Forms is what has to be got out of there** — but **not because it is unsupported, which is
  the usual assumption and is false**. Datum verified by reading the PDF *Oracle Fusion Middleware —
  Oracle Lifetime Support Policy*, *Effective Date: April 13, 2026*: **Fusion Middleware 14.1.x** (GA
  **Dec 2024**), whose table footnote explicitly includes *"Forms and Reports"*, has **Premier Support
  until Dec 2030**, **Extended until Dec 2033** and indefinite *Sustaining*. What does press is the
  previous version: **FMW 12c (12.2.x), where the vast majority of the estate lives, has Premier until
  Dec 2026 and Extended until Dec 2027**. And 11gR2 (11.1.2.x) has been out since Dec 2016 (Premier)
  / Dec 2018 (Extended).
- **Oracle Reports is another case**: it is **deprecated since 12.2.1.3.0**, declared a *terminal
  release*, and although it is still packaged with 14.1.2 it receives no new functionality, only
  critical fixes and stack compatibility; the route Oracle points to is **Oracle Analytics Publisher**.

Operational conclusion: **the Forms clock is not "it is dead", it is "your 12.2.x leaves Premier in
Dec 2026"**. And the real argument for leaving is not the calendar, but that the client platform
—Java applet, then Java Web Start, JRE dependencies on the desktop— ages faster than the product and
that the labour market of people who know how to maintain it has dried up.

**Not applicable**: `oracle-dba-standards` and `sql-standards` (**already written**) own the **Oracle
engine** (instance, storage, RAC, backup, patching, execution plans, indexes, engine licensing) and
the **SQL language**; here PL/SQL as a **program language** and Forms as an **application layer**,
with `data-platform-standards` and `data-warehouse-modeling-standards` for the analytical side.
`legacy-modernization-standards` is the umbrella of the block —and
`migration-projects-standards` the execution of the cutover: rehearsal, window, coexistence, data
reconciliation, rollback and shutdown of the source— and
`enterprise-architecture-standards` (**already written**) provides the inventory, the TIME model and
the "R"s —here what each option implies technically—, with `refactoring-tech-debt-standards` and
`testing-qa-standards` (**already written**: *strangler fig*, characterisation without tests),
`project-management-standards`, `tech-leadership-standards`, `cicd-standards` and
`git-workflow-standards`. If the destination is Java, `jvm-spring-standards` wins (**already
written**: **modern Java and Spring are theirs and are the usual destination**); for a separate
front-end, `frontend-frameworks-standards` and `api-design-standards`.
`appsec-standards` and `vulnerability-management-standards` (**already written**) provide methodology
and triage; here only the concrete PL/SQL *sinks*. Sister skills of the legacy block —**they share the
"legacy" label and little else**—: `abap-sap-standards`, `mainframe-zos-cobol-standards`,
`ibm-i-rpg-standards`, `jsp-struts-standards`, `coldfusion-standards`, `vb6-standards`.

## 2. Default decisions

> Verify on the web before pinning it (§8): FMW and engine support dates, and the APEX version.

| Decision | By default | Note |
|---|---|---|
| Unit of code | **Package** (`PACKAGE`/`PACKAGE BODY`) | Standalone procedures only for trivial *jobs* |
| SQL in PL/SQL | **Static whenever possible** | It is checked at compile time and records the dependency |
| Unavoidable dynamic | `EXECUTE IMMEDIATE` **with `USING`** + `DBMS_ASSERT` for identifiers | §5; never concatenate values |
| Volume | **`BULK COLLECT` with `LIMIT` + `FORALL`** | The row-by-row loop is performance defect no. 1 |
| Exceptions | Catch **what is expected and named**; rethrow the rest | `WHEN OTHERS THEN NULL`: forbidden (§3) |
| Rights | **`AUTHID DEFINER`** by default, consciously | `CURRENT_USER` when the caller must supply their own permissions |
| Tests | **utPLSQL** (Apache-2.0, verified from the raw file) | §4 |
| New Forms | **None**: no new `.fmb` modules are created | New functionality, outside (§7) |
| Frequent destination | **APEX** if the logic stays in the database; **Java/web** if you have to get out of it | §7 |

## 3. PL/SQL: conventions that are required

- **Package as the unit of module**: minimal specification (only what is public), body with the rest.
  The specification is the contract: changing it invalidates all its dependents, the body does not.
- **`%TYPE` and `%ROWTYPE` always** instead of literal types: the code follows the model when the
  column changes size.
- **No repeated loose SQL**: access to a table is concentrated in its package. If the same
  `SELECT` appears in eleven places, eleven places will break with the next model change.
- **Exceptions**: every `EXCEPTION` catches **named** exceptions (`NO_DATA_FOUND`,
  `DUP_VAL_ON_INDEX`, or your own with `EXCEPTION_INIT`) and does something real with them. To
  propagate with context: `RAISE_APPLICATION_ERROR(-20xxx, ...)` preserving
  `SQLERRM`/`DBMS_UTILITY.FORMAT_ERROR_BACKTRACE`, or a bare `RAISE`.
  **`WHEN OTHERS THEN NULL` is the most damaging antipattern in this ecosystem**, and it deserves an
  explanation because it gets written out of habit: it turns a failure into a silent success. The
  transaction carries on, the nightly process "finishes fine", the record was not inserted, nobody
  finds out until the accounts are reconciled months later, and by then there is neither a trace nor
  any way to know how many rows were missing. It is not bad style: it is **undetectable data loss**.
  Its cousin, the `WHEN OTHERS` that does `DBMS_OUTPUT.PUT_LINE` and does not rethrow, is the same
  thing with more steps. Rule: **a `WHEN OTHERS` that does not end in `RAISE` (or in
  `RAISE_APPLICATION_ERROR`) is a review error**; the only legitimate use is to log and rethrow.
- **Transactions**: `COMMIT`/`ROLLBACK` are decided by **whoever starts the unit of work**, not by the
  service procedure that is called from three places; a `COMMIT` buried in a utility function breaks
  the atomicity of all its callers.
- **`PRAGMA AUTONOMOUS_TRANSACTION` only for what must survive the `ROLLBACK`**: auditing and error
  logging. Using it "so the lock stops bothering me" or to avoid a *trigger*'s mutation **hides the
  error and produces inconsistent data**, aggravated by the fact that the autonomous transaction does
  not see the uncommitted changes of the main one and can deadlock against itself.
- **Triggers: the fewest possible.** Business logic spread across *triggers* is impossible to read and
  to debug: the execution order is not evident and the effect fires where nobody expects it. For
  auditing, `FLASHBACK`/audit columns or a compound *trigger* is better than a cascade.
- **Dependencies and invalidation**: every object records what it depends on; a DDL invalidates its
  dependents and recompilation arrives on the first execution (or fails). Operational consequences:
  deploy specification changes **with the application stopped or with the package free of active
  sessions**, because changing a package with state in use causes **ORA-04068** in live sessions;
  review `USER_OBJECTS` looking for `INVALID` **after every deployment** and treat it as a failure,
  not as noise; and avoid package-level state (global variables) unless there is a justified need.
- **Performance**: SQL↔PL/SQL context switches in a loop are the dominant cost. `BULK COLLECT`
  **always with `LIMIT`** (an unbounded collection loads the whole table into session memory),
  `FORALL` with `SAVE EXCEPTIONS` and review of `SQL%BULK_EXCEPTIONS`. Measure with `DBMS_HPROF` and
  `PL/Scope`, not by intuition; the execution plan of the queries belongs to `oracle-dba-standards`.

**Business logic in the database, as an architecture decision.** In favour, and it is serious: it is
where the data is (zero network latency per operation, sets processed in the engine), integrity is
guaranteed even with several applications and an ETL writing, the transaction is natural, and the code
survives three generations of front-end framework —there is PL/SQL from the nineties serving today—.
Against, and this is serious too: it ties you to the engine (and to its bill), modern engineering
*tooling* arrives late or badly (tests, dependencies, CI, review), it scales only vertically with the
database server, it mixes the application deployment with that of the data, and the labour market gets
narrower every year. **Criteria**: integrity rules and bulk data processes, inside; orchestration,
third-party integration, presentation and logic that changes at the pace of the business, outside. And
the decision is taken **once and written down** (ADR), because the expensive failure is logic
duplicated in both places, diverging in silence.

## 4. Quality and testing

- **utPLSQL** as the test framework: verified by reading the raw file, **Apache-2.0** licence
  (`LICENSE` present in both `main` and `develop`). Annotations (`--%suite`, `--%test`), output in
  formats consumable by CI (JUnit/SonarQube), and **per-block coverage**. It is the tool that makes it
  possible to treat PL/SQL as real code.
- **Test what hurts**: monetary calculations, business rules, date cut-offs, and **the error paths**
  —what happens when the row does not exist, when the `FORALL` fails halfway, when two sessions touch
  the same thing—. Test data created and destroyed by the suite itself; a suite that depends on the
  content of the development schema is a status report, not a test.
- **Static analysis**: compiler warnings **enabled and treated as errors** (`PLSQL_WARNINGS`), which
  detect dead code, `WHEN OTHERS` without `RAISE` and misused parameters; `PL/Scope` for dependencies
  and identifiers. There are commercial and free linters for PL/SQL: verify status and licence before
  adopting one (§8).
- **CI**: the schema is built from the repository (**the source wins, not the database**), it is
  deployed to an ephemeral schema, the suite is run and **the build fails if any object is left
  `INVALID`**. That last gate is cheap and catches half the deployment incidents.

## 5. Security

- **Bind variables: a security requirement *and* a performance one at the same time.** Concatenating
  values into a statement is SQL injection and additionally generates a different statement per value,
  which fills the *shared pool* and causes a *hard parse* on every execution. With `USING` neither
  happens. There is no case in which concatenating a value is the right option.
- **What does not accept a *bind*** (table, column, schema names; dynamic `ORDER BY` clauses) is
  validated with **`DBMS_ASSERT`** (`SIMPLE_SQL_NAME`, `SQL_OBJECT_NAME`, `SCHEMA_NAME`) **and**
  against a closed allowlist. `DBMS_ASSERT` on its own does not authorise: it checks shape, not
  permission.
- **`AUTHID` is a security decision, not a detail**: `DEFINER` (the default) executes with the owner's
  privileges, so **a `DEFINER` procedure with injectable dynamic SQL hands the owner's privileges to
  the attacker** — it is the classic escalation pattern in Oracle. `CURRENT_USER` (*invoker rights*)
  forces the caller to have their own permissions and limits the damage, in exchange for demanding a
  properly built privilege model. Rule: **public API in `DEFINER`, minimal and with no dynamic SQL;
  anything with dynamic SQL, reviewed line by line.**
- **Exposed database surface**: permissions are granted **on packages, not on tables** — the
  application should not have direct `SELECT`/`INSERT` on the business tables—. Specific roles, no
  `GRANT ... TO PUBLIC`, review of dangerous packages (`UTL_FILE`, `UTL_HTTP`, `UTL_SMTP`,
  `DBMS_SCHEDULER`, `DBMS_JAVA`) and of the network ACLs: **an accessible `UTL_HTTP` turns the
  database into an internal HTTP client, that is, SSRF from the heart of the system**.
- **If there is ORDS/APEX**, the database starts serving HTTP: it is a **new trust boundary**. The
  parsing schema with the fewest privileges, the REST *endpoints* authenticated and authorised one by
  one, and the APEX administration console **never reachable from the internet**.
- **Forms**: credentials on the `frmweb` command line/in the `.fmb`, `EXEC_SQL` with literals, and
  authorisation logic implemented **only in the client** (hiding a button is not a control) are the
  three usual findings. Authorisation is checked **in the database**, always.
- **Patching**: Oracle's quarterly *Critical Patch Updates* cover the database and Fusion Middleware;
  a Forms 12.2.x with no CPU applied is a legacy Java server with no patches. Calendar and triage, in
  `vulnerability-management-standards`.

## 6. Exit from Forms and Reports

Four real routes, with their criteria:

1. **Oracle APEX** — the most frequent destination when the logic already lives in PL/SQL.
   **Verified**: it is a **no-additional-cost feature of the Oracle database** (all editions,
   including Free and Autonomous), **not a separate product that is licensed**; it requires **ORDS**;
   version **26.1**, released on **14 May 2026** (there was no 25.x), with release support until
   **30 Nov 2027** and ~18 months per version. **The key dependency, stated plainly: APEX only runs on
   an Oracle engine.** Migrating to APEX **does not get you off the Oracle bill** —it ties you in
   further—, and that is exactly why Oracle pushes it as the exit from Forms. It is a great option if
   you are going to stay with Oracle for ten years; it is the worst one if the goal was to leave it.
2. **Rewrite to Java/web** (or to whatever stack the house maintains): the only route that cuts the
   dependency. Expensive, and the quality of the result is governed by `jvm-spring-standards`, not by
   this one.
3. **Modernise Forms *in situ*** (move up to 14c, remove the applet, integrate it behind a *reverse
   proxy*): it buys 5-7 years of calendar, it does not solve the staffing or the architecture problem.
   It is a legitimate "invest the minimum" decision for a stable system with a known retirement date.
4. **Automatic conversion tools** (Forms→APEX, Forms→Java): they are useful for the inventory and for
   the scaffolding —screens, LOVs, tables—, and **they produce generated code that has to be redone**:
   they translate the structure of a fat client, with its event model and its per-block state, into a
   stateless environment, and what comes out is neither idiomatic nor maintainable. Use them as an
   accelerator for the mechanical 60%, **never as the final delivery**, and budget the rewrite of the
   rest.

**And before all four: PL/SQL stays.** The expensive mistake in these migrations is rewriting the
business logic that is already in packages and works too. Forms (presentation and navigation) is
separated from PL/SQL (business), the latter is kept and the former is replaced.

## 7. Prohibitions

- ❌ FORBIDDEN `WHEN OTHERS THEN NULL`, and any `WHEN OTHERS` that does not rethrow.
- ❌ FORBIDDEN to concatenate values in dynamic SQL. No exception for "it is a number".
- ❌ FORBIDDEN dynamic SQL with identifiers without `DBMS_ASSERT` **and** an allowlist.
- ❌ FORBIDDEN to process row by row what a set statement or a `FORALL` resolves.
- ❌ FORBIDDEN `BULK COLLECT` without `LIMIT` over tables of unbounded size.
- ❌ FORBIDDEN `COMMIT`/`ROLLBACK` inside reusable service procedures.
- ❌ FORBIDDEN `PRAGMA AUTONOMOUS_TRANSACTION` to dodge locks or *mutating tables*.
- ❌ FORBIDDEN to grant permissions on business tables to the application when they can be granted on the API.
- ❌ FORBIDDEN `GRANT ... TO PUBLIC` and `UTL_HTTP`/`UTL_FILE`/`DBMS_JAVA` privileges without a use case.
- ❌ FORBIDDEN to deploy leaving `INVALID` objects unreviewed.
- ❌ FORBIDDEN to treat the database as the source of truth for the code: the repository wins.
- ❌ FORBIDDEN to create **new** Forms modules; new functionality is written outside.
- ❌ FORBIDDEN authorisation implemented only in the Forms client.
- ❌ FORBIDDEN to deliver the output of an automatic conversion tool without rewriting it.
- ❌ FORBIDDEN to plan the exit from Forms on a **remembered** support date: it is read from the
  current *Lifetime Support Policy* PDF, with the exact installed version (§8).

## 8. Mandatory web verification

Always check, in the official **Oracle Lifetime Support Policy** PDFs (*Fusion Middleware* and
*Technology Products*, which carry an effective date on the cover and **are revised several times a
year**): Premier/Extended for the **exact version** of Forms and Reports installed and for that of the
engine; the status of **Oracle Reports** and of the route to Analytics Publisher; the current version
and support window of **APEX** and of **ORDS**; the version and licence of **utPLSQL** and of any
PL/SQL linter before adopting it; and the quarterly **Critical Patch Updates**.

**Declared gaps (no verified datum, do NOT fill in from memory)**: (a) the **Oracle Forms Statement of
Direction** could not be read raw — the two PDF URLs tried returned **404**—, so the assertion that
Reports is a *terminal release* since 12.2.1.3.0 and is still packaged in 14.1.2 comes from **release
notes quoted by a search engine, not from a verbatim citation**: reconfirm before using it in a
committee; (b) **the calendar of version 14.1.2 beyond the `Fusion Middleware 14.1.x` row** of the PDF
is not verified —Oracle publishes error correction dates separately, by Doc ID in My Oracle Support
(authenticated access)—, and **error correction ≠ Premier Support**: the date that really decides when
you stop receiving patches may be earlier; (c) Forms & Reports licence cost (metrics and contract) —
not verified, do not quote figures; (d) the status and licence of the commercial Forms→APEX conversion
tools — not verified.

**Flagged discrepancy**: the widespread belief that "Oracle Forms is unsupported" **contradicts
Oracle's own document** (14.1.x with Premier until Dec 2030); and at the same time, secondary sources
were quoting 14c Premier at Dec 2029 or Dec 2027 before the 2026 revision of the document. **The
current PDF wins, with its effective date on the cover** — and note that date when quoting it.

If the web contradicts this document, **the web wins** — flag the discrepancy.
