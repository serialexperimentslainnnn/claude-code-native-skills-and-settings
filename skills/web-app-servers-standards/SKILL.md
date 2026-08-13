---
name: web-app-servers-standards
description: The web server and application server as a host you operate, harden and patch — not as the proxy that decides routing. Use when working with Apache httpd (httpd.conf, apache2.conf, sites-available, a2enmod, .htaccess, AllowOverride, mpm_prefork/mpm_worker/mpm_event, MaxRequestWorkers, ServerLimit, ThreadsPerChild, ServerTokens, mod_ssl, mod_status, mod_security, apachectl configtest), nginx as an origin server (nginx.conf server blocks, worker_processes, worker_connections, worker_rlimit_nofile, client_max_body_size, sendfile, gzip, autoindex, server_tokens, nginx -t), IIS (applicationHost.config, web.config, appcmd, IISAdministration and WebAdministration PowerShell modules, application pools, ApplicationPoolIdentity, recycling and idleTimeout, request filtering, http.sys, ASP.NET Core Module), a Java application server (Tomcat server.xml, context.xml, catalina.sh, CATALINA_OPTS, Manager and Host Manager apps, Jetty jetty.xml and start.d, WildFly standalone.xml and jboss-cli, WebLogic config.xml, WLST, T3/IIOP, WebSphere Liberty server.xml and traditional wsadmin), the javax to jakarta namespace migration and Jakarta EE version targets, PHP-FPM pools (www.conf, pm dynamic/static/ondemand, pm.max_children, listen.owner), WSGI/ASGI servers behind the web server (gunicorn, uvicorn, waitress), sizing the process or thread model, request size limits, timeouts, file descriptor limits, a 502 or 504 that is really a server limit, TLS termination on the origin and automatic certificate renewal, response security headers, static file serving and compression, access log format and rotation, or hardening a server that runs as root, lists directories, leaks its version or exposes an admin console.
---

# Web and application server standards — the piece you operate, not the one that distributes

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: the origin server is not "where the code gets copied". It is a process with a
> concurrency model, limits and an attack surface of its own, and **almost every
> incident people attribute to the application is a badly set limit at this layer**.

## 1. Scope and triggers

Applies to **installing, sizing, hardening, patching and operating** the server that serves the
request: Apache httpd, nginx and IIS as web servers; Tomcat, Jetty, WildFly/JBoss EAP,
WebLogic and WebSphere as application servers; PHP-FPM and the WSGI/ASGI servers as the
process that runs the code; and their limits, origin TLS, headers, static files and
logging.

Triggers: `httpd.conf`, `apache2.conf`, `.htaccess`, `nginx.conf` (`server` block),
`applicationHost.config`, `web.config`, `appcmd`, `server.xml`, `context.xml`, `standalone.xml`,
`jboss-cli`, `config.xml`/WLST, Liberty's `server.xml`, PHP-FPM's `www.conf`, `mpm_event`,
`worker_connections`, `MaxRequestWorkers`, `pm.max_children`, `LimitNOFILE`, "502 Bad Gateway",
"504 Gateway Timeout", "application pool", "recycling", `javax` → `jakarta`.

**Not applicable**: distribution already has an owner — **`load-balancing-standards` owns the balancer and the
reverse proxy, its health checks, draining and edge TLS termination** (here the
**origin server** serving behind it and the checks it *exposes*), **`caching-cdn-standards`
the cache policy, the CDN and the headers that govern it**, `networking-standards` and
`firewall-policy-standards` connectivity and filtering, `dns-standards` the records, and
`cryptography-pki-standards` **the choice of algorithm, suite and the issuance of the certificate** (here
only its installation, renewal and reload). The **code running on top** belongs to `php-standards`,
`python-standards`, `jvm-spring-standards` and `dotnet-framework-legacy-standards` — **IIS is the
dependency of Microsoft legacy, which delegates to this skill** for the server —, while
`kubernetes-standards` owns the deployment if the service runs in a container, `cicd-standards` and
`iac-standards` how the configuration reaches the machine, `observability-standards` metrics and
dashboards, `sre-practice-standards` the SLO, `vulnerability-management-standards` CVE triage,
`appsec-standards` the application vulnerability, `identity-access-management-standards` the
OIDC, `privacy-engineering-standards` personal data in the log and `grc-compliance-standards`
the evidence. The operating system underneath belongs to `linux-administration-standards`,
`rhel-fedora-standards`, `linux-hardening-standards` and `windows-server-ad-standards`; backups to
`backup-recovery-standards`, and `onprem-standards` is the umbrella (with `homelab-standards` as a test
bench). Its batch siblings: `mail-servers-standards` and `file-servers-standards` are **another
service, not another configuration of the same one**.

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Recommended | Justifiable alternative |
|---|---|---|
| Generic web server | **nginx** stable branch (`1.30.x`; `1.30.0` opened on 14 Apr 2026, `1.30.4` with CVE-2026-42533 and CVE-2026-60005) for per-connection footprint | **Apache httpd 2.4.x** (`2.4.68`, 8 Jun 2026) if you need per-tenant `.htaccess`, third-party modules or integration with the distribution's package |
| nginx branch | **stable** in production; *mainline* (`1.31.x`, `1.31.3` of 15 Jul 2026) only if you need a specific feature | *mainline* in environments where patch cadence matters more than interface stability |
| httpd 2.6 | **No**: there is no GA; the development trunk runs as 2.5.x | — |
| httpd 2.2 | **FORBIDDEN**: EOL, last release `2.2.34` (Jul 2017) | — |
| Apache MPM | **`event`** with PHP-FPM or a proxy to the application | `prefork` **only** if a module is not thread-safe (classic `mod_php`) — and that is the signal that you need to get off it |
| The nginx ecosystem after the forks (F5, freenginx, Angie) | **Already verified in `load-balancing-standards`**: consult it there, it is not duplicated | — |
| Server on Windows | **IIS 10.0** (the version shipped with Windows Server 2025, supported until 10 Oct 2034). **There is no "Windows Server 2026"**: what ships in 2026 are cumulative updates | nginx/httpd on Windows for development only |
| Servlet container | **Tomcat 11.0.x** (Jakarta EE 11) for new code; **10.1.x** (EE 10) if the stack is not there yet | **Jetty 12.1** when embedding or when you need the `EE8/EE9/EE10/EE11` model in one binary |
| Tomcat 9.0.x | **Migrate**: supported until **31 Mar 2027**. There will be a `9.1.x` branch (until **31 Dec 2030**) but **without APR/native connectors** for HTTP, HTTPS and AJP: it is an extension, not a destination | — |
| Jetty 9/10/11 | **FORBIDDEN**: since **1 Jan 2026 they are no longer published to Maven Central**; paid support only (Webtide, HeroDevs, TuxCare) | — |
| Full Jakarta EE server | **WildFly 41.0.0.Final** (16 Jul 2026, EE 11 since WildFly 40, 21 May 2026) if there is no contract | **JBoss EAP 8.1** with commercial support; **WildFly EE 10** as a bridging variant if you cannot manage EE 11 yet |
| JBoss EAP 7.x | **Migrate to 8.1**: EAP 7 maintenance ended on **30 Jun 2025**; from then on only **ELS** (requires being on 7.4, renewable until **Oct 2027**) | — |
| WebLogic | **14.1.2 (14c)**, certified with JDK 17 and 21. **There is no "15c"** | Migrate to WildFly/EAP or to Liberty if the licence cost is not justified |
| WebSphere | **Liberty** (single-stream SSCD model, delivery roughly every 4 weeks, **with no end-of-support date**; `26.0.0.5` added Jakarta EE 11 and Spring Boot 4.0) | **WAS traditional 9.0.5**: IBM **announces no end date**, but the real pressure is the currency of the fix pack, of the Java and of the OS underneath |
| Running PHP | **PHP-FPM** over a Unix socket, one pool and one user per application | FrankenPHP/embedded server only with an explicit rationale |
| Running Python | **WSGI/ASGI behind the web server** (gunicorn+uvicorn workers, or uvicorn/hypercorn) — never directly exposed | — |

**Jakarta EE and the namespace change**: Jakarta EE 11 was released on **26 Jun 2025** (Core
Dec 2024, Web Profile Mar 2025), requires **Java 17+**, removes *Managed Beans*, the references to the
`SecurityManager` (JEP 411), SOAP with Attachments and XML Binding, and the optional
specifications. **Jakarta EE 12 is not released** and its dates contradict each other across sources (§8).
The `javax.*` → `jakarta.*` jump is **binary and non-negotiable**: it is the real cut between Tomcat 9 and
10+, and between EAP 7 and 8. **It is not a `sed`**: it affects transitive dependencies, descriptor
files and third-party bytecode; it is planned with the project's migration tool and
verified by running, not by compiling.

## 3. The process model: why the default sizing is almost always wrong

The default value is set by whoever packages it, **without knowing your memory or your request
profile**. A single rule: **the number of workers is dictated by the resident memory of the worst
process and by the nature of the waiting**, not by the number of cores.

- **Apache**: `prefork` (one process per connection, expensive memory, safe with non-reentrant modules),
  `worker` (a process/thread hybrid) and `event` (threads + asynchronous handling of idle and
  *keep-alive* connections). With `event`, `MaxRequestWorkers` and `ServerLimit` × `ThreadsPerChild` must be
  coherent or start-up silently trims them. **With `mod_php` you are tied to `prefork`**: that is
  the technical reason to move to PHP-FPM, not a fashion.
- **nginx**: `worker_processes auto` (one per core) and `worker_connections` as a **ceiling per
  worker that includes connections towards the *upstream***, not only the client's: the effective
  limit is roughly half when proxying. `worker_rlimit_nofile` must be greater than
  `worker_connections`, or the real limit will be file descriptors.
- **IIS**: the application pool is the **failure and identity boundary** (`ApplicationPoolIdentity`
  = a virtual account per pool). One pool per application, never shared between tenants. **Periodic
  clock-based recycling and `idleTimeout` are on by default**: in an application
  with an expensive start-up they are surprise latency and lost in-memory state — disable hourly
  recycling, keep memory/request-based recycling, and use pre-warming (`AlwaysRunning` +
  `preloadEnabled`). A *web garden* (`maxProcesses` > 1) **breaks in-memory sessions**: it is not a
  performance button.
- **PHP-FPM**: `pm = dynamic` with `pm.max_children` computed as *memory available to the
  pool / RSS of the worst process*, and `pm.max_requests` to bound leaks. `pm = static` when the load
  is stable and start-up latency matters; `ondemand` only in sparse multi-tenancy. A
  short `pm.max_children` is **the number one cause of intermittent 502s** with nginx in front.

## 4. Validation and gates

- **Nothing is reloaded without validation**: `apachectl configtest` / `httpd -t`, `nginx -t`,
  `appcmd list config` or the `web.config` schema. In CI, validation runs against the
  rendered configuration, not against the template.
- **Reload, do not restart**: `nginx -s reload`, `apachectl graceful`, overlapped recycling in IIS.
  A hard restart cuts in-flight requests; combined with balancer draining
  (`load-balancing-standards`) the deployment should not lose a single one.
- **Gates in order of cost**: (1) syntax validation; (2) a configuration linter and diffs
  against the reference; (3) an HTTP smoke test against the origin **without going through the balancer**;
  (4) TLS and header verification (`testssl.sh`, a header check) against the deployed
  environment; (5) a load test that confirms the chosen sizing, not the default.
- **The configuration is code**: outside `iac-standards` there are no manual changes in production. A
  `.htaccess` edited hot is by definition an unversioned change.

## 5. Stack security

- **An unprivileged user**: the master process may need root for the low port (or
  `CAP_NET_BIND_SERVICE`/`AmbientCapabilities`), the workers **never**. A Java application
  server running as root is a design failure, not a pending adjustment.
- **Directory listing disabled**: `Options -Indexes`, `autoindex off`, directory browsing
  off in IIS. And the document root **outside** the code tree and `.git`.
- **The version out of the headers**: `ServerTokens Prod` + `ServerSignature Off`,
  `server_tokens off`, and in IIS remove `Server`, `X-Powered-By` and `X-AspNet-Version`. It is not
  real security, but it is free reconnaissance for the attacker and a guaranteed audit finding.
- **Unnecessary modules out**: every loaded module is surface and is a CVE that forces you to
  patch. Review `mod_status`, `mod_info`, `mod_userdir`, `mod_autoindex`, WebDAV, CGI and third-party
  modules. In IIS, remove the role features you do not use and enable request
  filtering. In Tomcat/WildFly, delete the sample and documentation applications.
- **`.htaccess` is surface**: `AllowOverride None` by default. Enabling it delegates configuration
  to whoever can write in the directory — including a compromised file upload — and penalises
  every request with filesystem lookups. It is enabled per directory and with an explicit list
  of directives, never globally.
- **The commercial products' admin console**: Tomcat Manager/Host Manager, the WildFly console,
  WebLogic's `/console` and **T3/IIOP**, the WebSphere administrative console. **Never on the Internet**:
  they listen on the management network or on loopback behind a tunnel, with their own credential and MFA
  where it exists. **Exposed T3/IIOP has a history of deserialisation RCE**: if you do not use it,
  disable it; if you do, filter it by network and apply the allowed class list.
- **TLS**: TLS 1.2 as the absolute minimum, 1.3 preferred; SSLv3/TLS 1.0/1.1 disabled. OCSP
  stapling on, HSTS only once the whole domain is already on HTTPS (and `preload` only with a
  conscious decision: it is hard to reverse). **The choice of suite and curve belongs to
  `cryptography-pki-standards`.**
- **Automatic certificate renewal**: ACME with an automatic reload afterwards, and **expiry
  monitoring independent of the agent that renews** — the real failure is not that it expires, it is that the
  agent renewed and nobody reloaded the service.
- **Response headers that genuinely belong to the server**: `Strict-Transport-Security`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy`, `Content-Security-Policy` and
  `Permissions-Policy`. The CSP **policy** is defined by the application (`appsec-standards`); the
  server emits it consistently and **does not duplicate it** — a header repeated by server and
  application is undefined behaviour in practice. `X-XSS-Protection` is obsolete: do not
  set it.
- **Static files**: served from the web server, not from the interpreter. Deny by
  pattern whatever must never leave (`.git`, `.env`, `~` copies, `.bak`, configuration files) and
  disable interpreter execution in upload directories — **an upload served as
  code is RCE**, and it is the most repeated mistake in the domain.

## 6. Limits, 502/504 and logging

- **A 502/504 is, almost always, a badly set limit here, not an application failure.** Before
  touching code, check: backend worker exhaustion (`pm.max_children`,
  `maxThreads`, the accept queue), an upstream read timeout shorter than the request's real
  duration, a header or body size above the buffer (`proxy_buffer_size`,
  `client_max_body_size`, `LimitRequestBody`, `maxAllowedContentLength`), and exhausted descriptors.
- **Four limits that are always set, with a justified number**: maximum request and
  header size; client and upstream timeouts **coherent across layers** (the balancer's
  must be larger than the origin's, or you will see cuts with no trace); file descriptors
  (`LimitNOFILE` in the systemd unit, not in a script's `ulimit`); and a listen backlog
  matching `somaxconn`.
- **Logging**: access and error separated, structured format (JSON) if it goes to a collector, and
  **rotation by the system tool with descriptor reopening** — a rotation that only
  renames leaves the process writing to an orphaned inode and fills the disk without anybody seeing it.
  Reserve space: **a disk full of logs takes the service down**.
- **What is not logged**: `Authorization`, `Cookie`, POST bodies, tokens in the query
  string and passwords in the URL. The **IP is personal data**: bounded retention and anonymisation or
  pseudonymisation as set by `privacy-engineering-standards`.
- **Compression and static content**: `gzip`/`brotli` only over compressible types (compressing a JPEG or a
  ZIP burns CPU for nothing), pre-compressed variants when the content is static, `sendfile` and
  `tcp_nopush` on. Be careful compressing responses that mix a secret with user input
  over TLS (the BREACH class). **The cache policy and the CDN belong to `caching-cdn-standards`**; here
  only that the server knows how to emit `ETag`/`Last-Modified` and answer `304`.
- **Minimum metrics**: requests per second and per status code, latency per percentile, busy workers
  against the limit, active connections, the accept queue and upstream errors. Without
  "busy workers / limit" **you cannot tell saturation from slowness**.

## 7. Sustainability and prohibitions

Cadence: a server security patch **outside the window** if the CVE is remotely exploitable;
a minor branch jump planned quarterly; a major branch jump (Tomcat 9→11, EAP 7→8) treated
as a **project with a budget**, because it drags the namespace change along. Every server
has an **end-of-support date recorded in the inventory**: without it, the migration always arrives
late.

- ❌ Serving with an out-of-support server or branch (httpd 2.2, Tomcat 8.5/10.0, Jetty 9/10/11,
  EAP 7 without ELS) because "it works".
- ❌ Running workers as root, or the application server under the administrator's account.
- ❌ Leaving the default sizing in production without having computed memory per process.
- ❌ Exposing the admin console, `mod_status`, `/manager`, `/console` or T3/IIOP to the Internet.
- ❌ Enabling `.htaccess` globally, or letting the application's user write to the server's
  configuration.
- ❌ Allowing interpreter execution in directories where users upload files.
- ❌ Terminating TLS with obsolete versions or suites, or with a manually renewed certificate.
- ❌ Renewing with ACME without an automatic reload and without independent expiry monitoring.
- ❌ Logging authentication headers, POST bodies or tokens in the query string.
- ❌ Rotating logs by renaming without a reopen signal, or leaving the log disk with no quota and no alert.
- ❌ Treating a 502/504 as an application bug without first reviewing workers, timeouts and buffers.
- ❌ Setting an origin timeout larger than the balancer's (or the other way round unknowingly): it produces
  cuts with no trace in either of them.
- ❌ Changing configuration by hand in production and not returning it to the repository.
- ❌ Migrating `javax` → `jakarta` with search and replace, without running the integration tests.
- ❌ Duplicating security headers between server and application expecting "the stricter one to win".

## 8. Mandatory web verification

1. **The stable version and open CVEs** of httpd, nginx (stable branch versus *mainline*) and IIS/base
   OS. Check the project's advisory, not the distribution's package.
2. **The support calendar** for Tomcat (9.0.x/9.1.x dates), Jetty, WildFly, JBoss EAP,
   WebLogic and WebSphere. They change and they are the fact that decides the migration.
3. **The status of Jakarta EE 12**: not released as of Aug 2026. **Declared discrepancy**: InfoQ reported
   a plan with GA in Jul 2026 while the project's page at `jakarta.ee` marks it "Under
   Development" targeting a final release in **Q2-2027**. Do not pin a date without rereading the project's
   own source.
4. **Declared gap — WebLogic**: the exact Premier/Extended Support date for 14.1.2 lives in
   the Fusion Middleware *Lifetime Support Policy* document and in article **KB65053 of My
   Oracle Support**, which **requires a login and is not publicly verifiable**. The public policy
   confirms that Fusion Middleware 12c ends Premier in **Dec 2026** and Extended in **Dec 2027**;
   for 14c **you have to consult MOS with an account**. It is not filled in here.
5. **Declared gap — JBoss EAP 8.1**: Red Hat publishes the policy (7 years: 4 of Full Support +
   3 of Maintenance, plus optional ELS) but the concrete dates for 8.1 have to be taken from the
   *Product Life Cycles* table on the portal at decision time.
6. **The state of the nginx ecosystem after the forks**: **not re-verified here**, it is owned by
   `load-balancing-standards`; if that skill is out of date, update it there.
7. **Security headers**: check on MDN which are still current and which became obsolete
   before copying a template from years ago.
8. **The OS version that pins the server's** (IIS tied to Windows Server; httpd/nginx to the
   distribution's branch) and its end-of-support date.

If the web contradicts this document, **the web wins** — flag the discrepancy.
