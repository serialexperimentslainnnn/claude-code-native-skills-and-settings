---
name: perl-standards
description: Use when working with Perl code - .pl/.pm/.t/.psgi files, "#!/usr/bin/perl" scripts, cpanfile, cpanfile.snapshot, Makefile.PL/Build.PL, .perlcriticrc, .perltidyrc, dist.ini, cpanm/carton/local::lib/perlbrew/plenv, Moose/Moo/Object::Pad or the native class feature, Try::Tiny and eval/$@ error handling, prove and Test2::V0 or Test::More suites, taint mode -T, DBI, Mojolicious, Dancer2, or maintaining and deciding whether to rewrite a legacy Perl codebase.
---

# Perl standards (reference: August 2026)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**The real Perl case today is living legacy**: 10- or 20-year-old code that brings in revenue, that
nobody wants to touch and that has no tests. Most of the work here is **maintaining, containing and
deciding**, not creating. This document is written from there: first do not break it, then improve
it, and only with explicit criteria rewrite it. Perl is not the answer for new code unless the team
already maintains it (§7).

Triggers: `.pl`, `.pm`, `.t`, `.psgi`, `cpanfile`, `cpanfile.snapshot`, `Makefile.PL`, `Build.PL`,
`.perlcriticrc`, `.perltidyrc`, `dist.ini`, `cpanm`, `carton`, `perlbrew`, `plenv`, `prove`,
`Moose`/`Moo`/`Object::Pad`, `DBI`, `Mojolicious`, `Dancer2`, `-T`.

**Not applicable**: see `bash-linux-scripting-standards` (**a reciprocal and very real boundary**:
Perl was the historical successor to the shell when a script got too clever, and that rule is still
alive **only in reverse** — today the destination of a growing shell script is `python-standards`,
not Perl. A `.sh` that needs data structures does not become a `.pl`), `python-standards` (**the
natural destination of a rewrite**: when §7 says "rewrite", that is where it means),
`linux-administration-standards` and `rhel-fedora-standards` (**the system Perl, its RPM/DEB packages
and the OS tools that depend on it**), `lua-standards` and `groovy-standards` (nothing in common),
`appsec-standards` (methodology; here only Perl's concrete sinks), `sql-standards` (the SQL that goes
through `DBI`), `vulnerability-management-standards`, `secrets-management-standards`,
`observability-standards`.

## 2. Default decisions: interpreter and dependencies

> Verify the latest version on the web before pinning it in a real project (§8).

**Versions and support** (`perlpolicy`, verified as of Aug 2026):

| Series | Status |
|---|---|
| **5.44.x** | Current stable, released on **2026-07-15**. *Full support* |
| **5.42.x** | Previous stable (since 2025-07-03). *Full support* |
| 5.40.x | Since 2024-06-09. **Security fixes only** |
| 5.45.x | **Development** series (odd X). **Never in production** |

Policy quoted verbatim: *"To the best of our ability, we will provide 'critical' security patches /
releases for any major version of Perl whose 5.x.0 release was within the past three years."*
Numbering: even X = stable, odd X = development.

**"Perl 7" does not exist and is not going to exist as announced.** The history is necessary because
it still causes confusion: it was announced in June 2020 (Sawyer X) as "Perl 5 with modern defaults";
rejection over process and over backward compatibility stopped it, it led to a governance crisis that
produced `perlgov` and the Perl Steering Council, and the original idea died. **The 5.x series
continues without interruption**; `perlpolicy` as of Aug 2026 does not mention Perl 7. If someone is
planning around "when Perl 7 comes out", the plan is wrong.

**FORBIDDEN to touch the system Perl.** On RHEL/Fedora and Debian/Ubuntu the interpreter and its
modules are part of the OS: they are used by the package manager, boot tooling, `debconf` and
maintenance scripts. Installing modules with `cpan`/`cpanm` as root over `/usr/lib/perl5`, or
replacing the binary, **breaks the operating system** and leaves a machine that is neither
reproducible nor patchable. Rules:
- Modules the OS needs → **distro package** (`perl-*`), never CPAN over the system tree.
- Your own applications → their own interpreter with **`perlbrew`** or **`plenv`**, or at least an
  isolated module tree with **`local::lib`**. Each application with its own tree; never shared.
- In a container: an image with its Perl and its `cpanfile.snapshot`; no `cpanm` at runtime.

**Dependencies**:

| Piece | Choice | Verified (MetaCPAN, Aug 2026) |
|---|---|---|
| Installer | **`cpanm`** (App-cpanminus) | 1.7049 (2026-03-17) |
| Declaration | **`cpanfile`** with bounded ranges | — |
| Lock + reproducibility | **`Carton`** (`cpanfile.snapshot`, `carton install --deployment`) | v1.0.35, **2022-05-07** |
| Isolation | `local::lib` | 2.000029, **2022-04-20** |
| Formatting | **perltidy** | 20260705, **GPL-2.0** licence (not "same as Perl") |
| Lint | **Perl::Critic** | **1.156** (2024-10-23) |
| Tests | **Test2::V0** + `prove` / `yath` | see §8 (declared discrepancy) |
| Coverage | `Devel::Cover` | 1.52 (2026-03-07) |
| Auditing | **`CPAN::Audit`** / `cpan-audit` | 20260622.001 (2026-06-22) |

`Carton` and `local::lib` have gone years without a release: **they work and they are the de facto
standard, but they are not actively maintained software** — a fact to declare, not to hide. `Carmel`
is the same author's alternative and is even more stalled. Criterion: `cpanfile` +
`cpanfile.snapshot` **committed**, and reproducible installation from the snapshot; if the team can
afford it, freezing the module tree in the container image is more robust than trusting a resolution
from CPAN on every build.

## 3. The language: line zero and what breaks

**Line zero, non-negotiable, in every `.pl`, `.pm` and `.t` file:**

```perl
use strict;
use warnings;
```

Without `strict` no refactor is possible: a typo silently creates a new global symbol. It is the
difference between "maintainable Perl" and "Perl of legend". Acceptable alternative:
`use Modern::Perl` or `use v5.36;` or above — **`use VERSION` with 5.36+ enables `strict`, `warnings`
and `signatures` automatically** and is the preferred form in new code. Migration warning: Perl 5.40
warned that **repeated `use VERSION` declarations stop being allowed in 5.44**.

- **Sigils and context are the number one source of bugs.** `$x`, `@x` and `%x` are different
  variables, and the sigil indicates **what you get**, not what the variable is (`$array[0]`,
  `$hash{k}`). Above all: **scalar vs list context**. `my ($x) = f();` takes the first element of the
  list; `my $x = f();` puts the function in scalar context (for an array, its length). An empty list
  gives `undef` in scalar context and **disappears** when interpolated into another list. Rule: every
  function returning collections **returns a reference** (`\@result`), except with a deliberate,
  documented list contract. It is the only way to stop context biting you.
- **References**: nested structures only with references (`$h->{a}[0]{b}`). Beware
  **autovivification**: reading `$h->{a}{b}` creates `$h->{a}`; use `exists` if the creation matters.
- **`my` / `our` / `local`**: `my` is lexical and covers 99%. `our` is an alias to the package: only
  constants and `$VERSION`. **`local` is not local**: it is a temporary dynamic value over a global
  (`local $/;`); necessary for special variables, poison for anything else.
- **Object systems**, explicit criteria:
  - **Native `class` in the core**: it has existed since **5.38** (the "Corinna" project), and **it is
    still experimental as of 5.44** (warnings in the `experimental::class` category; the 5.44
    perldelta adds an entry in `perlexperiment` for "New object system and `class` syntax").
    Operational translation: **it is the future and can already be used in an internal project that
    controls its own interpreter, but not in a CPAN distribution nor in a system that cannot absorb a
    syntax change.**
  - **`Object::Pad`** (0.825, 2026-03) is the laboratory `class` came out of, actively maintained: the
    bridge if you want that syntax today and accept following its changes.
  - **`Moo`** (2.005005, **2023-01**): lightweight, no XS, fast startup; stable but without a release
    in years. **`Moose`** (2.4000, 2025-07): complete (roles, *type constraints*, MOP) with a real
    startup and memory cost — only if you already use it or genuinely need the MOP.
  - **Criterion**: a codebase already using Moose → Moose. A new, controlled codebase → native `class`
    accepting its experimental status, or `Moo` if you want stability today. **Never hand-written
    `bless`** in new code, and never two object systems in the same project.
- **Errors**: `eval { }; if ($@) { }` is correct **in a subtle and fragile way**. Real traps: `$@` can
  be clobbered by the destructor of an object released on leaving the `eval`; `$@` false but with an
  error having occurred if the exception was the string `"0"`; and `eval` without a block
  (`eval EXPR`) is something completely different. **Use `Try::Tiny`** (or `feature 'try'` if your
  interpreter has it and you accept its status) and always check the **return value** of `eval`, not
  just `$@`. Exception objects (your own class or `Throwable`) over strings: an error that is only
  text can neither be classified nor retried.
- **Regular expressions: Perl's strong point and its biggest risk.**
  - Precompile with `qr//` anything used in a loop; use `/x` in any pattern longer than one line (with
    comments) — a dense regex without `/x` is unreviewable code.
  - Names, not numbers: `(?<name>...)` and `$+{name}`. `$1`, `$2`… break when you reorder.
  - **ReDoS is real**: Perl's engine does *backtracking* and a pattern with nested quantifiers
    (`(a+)+`) over user input takes the CPU with it. Over untrusted input: bound the subject's length,
    avoid nested quantifiers and overlapping alternations, prefer negated character classes to `.*`,
    and **never accept a user-supplied pattern**.
  - `/e` (evaluates the replacement as code) over external data is `eval STRING` in disguise: vetoed.

## 4. Quality: formatting, lint, tests

- **Formatting**: `perltidy` with a committed `.perltidyrc`; `perltidy -b` locally and **`perltidy` in
  check mode as a gate**. No style debates.
- **Lint**: `Perl::Critic` with `.perlcriticrc` in the repo. Severity criteria:
  - New code or an already cleaned-up module: **severity 3** (`--severity 3`, "harsh") as the gate.
  - Legacy entering the pipeline for the first time: **severity 5** (`gentle`) as the gate, dropping
    one level per quarter. Setting severity 1 on a 100k-line legacy codebase does not produce quality,
    it produces a `## no critic` in every file and the abandonment of the linter.
  - Mandatory policies whatever the severity: `RequireUseStrict`, `RequireUseWarnings`,
    `ProhibitTwoArgOpen`, `ProhibitStringyEval`, `ProhibitBacktickOperators`.
  - `## no critic (PolicyName)` **always with the policy named and a reason**; never bare.
  - Warning: Perl::Critic has not published a release since 2024-10 (1.156) — it is still the tool,
    but its cadence is slow.
- **Tests**:
  - `Test2::V0` for new suites; `Test::More` is acceptable and ubiquitous in legacy, **do not migrate
    it for taste**. Runner: `prove -lr t/` (or `yath`), in parallel (`-j`) only if the tests really
    are independent.
  - Cover the happy path, **edges and errors**: empty inputs, `undef`, encoding (Perl and UTF-8 is a
    minefield: decide where you decode and test with non-ASCII), DB errors, timeouts.
  - `Devel::Cover` to measure, **not** as a religious threshold. In legacy with no tests, useful
    coverage is built from the edge: first a characterisation test that pins the current observable
    behaviour (however absurd), then you touch it.
  - Every bugfix leaves a regression test. An unstable test: fix it or delete it.
- **CI gates** (they block the merge, from cheap to expensive):
  1. `perl -c` over every modified file (it compiles).
  2. `perltidy` in check mode.
  3. `Perl::Critic` at the agreed severity.
  4. Full `prove`.
  5. `cpan-audit` over the `cpanfile.snapshot`.
- The suite runs against **the same interpreter version as production**, installed with perlbrew/plenv
  or in the container. "It passes on my machine with the system Perl" is not a signal.

## 5. Security

- **Taint mode (`-T`)**: enables the marking of external data (arguments, environment, files, network)
  and makes its use in dangerous operations fatal; it is enabled **automatically** in setuid scripts.
  It is still documented in `perlsec` as a live feature and **is still Perl's only systemic safety
  net** for code processing external input with privileges. Criterion: **enable it in any network,
  CGI or privileged script**; in large legacy, enable it on new entry points. Two limits you must be
  aware of: (a) *untainting* is done with a regex capture, i.e. **your pattern provides the security**,
  not Perl — a `=~ /(.*)/s` is untainting without validation and is worth nothing; (b) there is a
  long-running plan to make taint support a compile-time option and perhaps retire it (see the gap in
  §8): **do not design an architecture whose only defence is taint**.
- **Command execution — the list form versus the string form.** `system("cmd $x")`, `exec("cmd $x")`
  and backticks `` `cmd $x` `` pass the string **through the shell**: direct injection. **Always use
  the list form**: `system('cmd', $x)` / `open(my $fh, '-|', 'cmd', $x)`, which does an `exec` without
  a shell. If you need to capture output with variable arguments, `IPC::Run3`/`IPC::Run` with an
  argument list. **Always** check the exit status (`$?`): an unchecked `system` is a silent failure.
- **Two-argument `open`: FORBIDDEN.** `open(FH, $file)` interprets metacharacters in `$file`: a name
  starting with `>` writes, and one ending in `|` **runs a command**. Always three arguments with an
  explicit mode and a *lexical filehandle*: `open(my $fh, '<', $file) or die ...`. And always check the
  return of `open`, `close`, `print` and `unlink`.
- **`eval STRING`: FORBIDDEN** with any data coming from outside. `eval { BLOCK }` (exception handling)
  is a different construct and is legitimate. Equally vetoed: `/e` in substitutions over external data,
  and `sprintf`/`printf` with a format that comes from the user.
- **Deserialisation**: **`Storable` is unsafe over untrusted input** — `thaw`/`retrieve` over data you
  did not generate yourself is code execution and memory corruption; its own documentation warns about
  it. Vetoed as an interchange format with third parties; acceptable only for data your own process
  wrote into a trusted store. Alternatives: **JSON** (`JSON::PP`/`Cpanel::JSON::XS`, without *blessed
  objects*, with `max_depth`/`max_size`), and **YAML only with a safe loader** (`YAML::PP` in safe
  mode / `YAML::XS` with `$YAML::XS::LoadBlessed = 0`) — a YAML loader that instantiates objects is a
  remote `eval`.
- **SQL**: only DBI *placeholders* (`$dbh->prepare("... WHERE id = ?")` + `execute($id)`).
  Interpolating a variable into SQL is an absolute veto; identifiers that do not accept a placeholder
  (table/column names) are validated against an **allowlist**, never quoted by hand.
- **Paths and files**: canonicalise (`Cwd::realpath`) and check the path is still inside the allowed
  directory before opening; temporaries with `File::Temp`, never predictable names.
- **Secrets** outside the code, the `cpanfile` and the logs; `DBI` with credentials from the
  environment; a `Dumper` of a connection structure carries the password.
- **SCA**: `cpan-audit` over the `cpanfile.snapshot` as a CI gate. CPAN has abandoned modules with no
  successor: every dependency with no release in >5 years that touches network, crypto or parsing gets
  reviewed.
- **Cryptography**: nothing home-made. Password hashing with `Crypt::Argon2` or `Crypt::Bcrypt`;
  **never** `crypt()`, MD5 or SHA-1 for passwords. TLS with `IO::Socket::SSL` **with certificate
  verification enabled** (`SSL_verify_mode => SSL_VERIFY_PEER`) — disabling it is a veto.

## 6. Performance and operability

- Before optimising, profile (`Devel::NYTProf`). In Perl the cost is usually in I/O, in badly written
  regexes, in `DBI` doing N+1 and in loading half of CPAN at startup (`Moose` versus `Moo` matters in
  short-lived processes such as CGI or cron).
- Long-lived processes (PSGI/Plack, daemons): **leaks from circular references** — the reference
  counter does not release them; break the cycle with `Scalar::Util::weaken`. Watch RSS: monotonic
  growth = a cycle or an unbounded cache.
- Web deployment: **PSGI/Plack** with Starman/uWSGI behind a proxy. CGI is kept if it already exists;
  it is not chosen.
- Explicit timeouts in every HTTP client (`LWP::UserAgent`, `HTTP::Tiny`) and in the DB; retries with
  backoff only on idempotent operations.
- Structured logs (`Log::Any`/`Log::Log4perl` with JSON output) and a correlation id; `warn`/`die`
  reach the log with context. Scattered `print STDERR` is not observability. In a supervised process,
  autoflush enabled (or you lose the last logs when it dies) and `SIGTERM` handled for a clean
  shutdown.
- Encoding: decide the boundary (`binmode`, `:encoding(UTF-8)`, `use open`) once and document it;
  *mojibake* in Perl is almost always an undeclared boundary.

## 7. Sustainability: maintain, contain, and when to rewrite

- **Cadence**: follow Perl's stable series with at most one major version jump per year, and never
  leave the interpreter outside security support (a 3-year window). Upgrading the Perl of a legacy
  application is a project with its own test plan, not a `perlbrew install`.
- Dependencies: quarterly review with `cpan-audit`; an abandoned dependency that touches the attack
  surface is replaced or vendored, and its maintenance is taken on in writing.
- **Document the system while you touch it**: in legacy with no tests, a README with "what it does,
  who calls it, what breaks if it dies" is worth more than a refactor.

**When it gets rewritten and when it does not** (honest criteria):
- **You do not rewrite** a Perl that works, is in production and **has no tests**. Rewriting without
  tests is exchanging a **known, bounded risk** (ugly code that has worked for 15 years, with all its
  edge cases already discovered by reality) for an **unknown risk** (pretty code that has not found
  any of them yet). The cost is not the one estimated: the expensive part is the invisible list of
  behaviours nobody documented and that somebody depends on continuing to happen.
- **You contain it first**: pin the interpreter, put the repo in CI, add `strict`/`warnings` file by
  file, write characterisation tests over the real inputs and outputs, isolate the module behind a
  stable interface. That work has value even if you never rewrite — and **it is a prerequisite** if
  you do rewrite, because the characterisation tests are the acceptance criteria for the rewrite.
- **You rewrite** when at least one hard condition holds, not an aesthetic one: nobody on the team can
  maintain it and you cannot hire for it; it depends on a Perl version or on modules already out of
  security support with no upgrade path; the business change requires touching the core every sprint;
  or the cost of incidents already exceeds that of the rewrite, **measured**.
- **How you rewrite**: in pieces, with the old and the new coexisting behind an interface (strangler),
  with the characterisation tests as the oracle, and with a declared destination — usually Python (see
  `python-standards`). *Big bang* never.

**List of prohibitions (veto):**
- ❌ Any file without `use strict; use warnings;` (or `use v5.36;`+). Not even one-line scripts.
- ❌ **FORBIDDEN** to install CPAN modules over the system Perl or replace its binary on RHEL/Debian.
- ❌ **FORBIDDEN**: two-argument `open`.
- ❌ **FORBIDDEN**: `eval STRING` over external data; `/e` with input; `sprintf` with a user-supplied
  format.
- ❌ **FORBIDDEN**: `system`/`exec`/backticks in string form with variable data. Always the list form.
- ❌ **FORBIDDEN**: `Storable::thaw`/`retrieve` over untrusted input; YAML with a loader that
  instantiates objects.
- ❌ SQL by interpolation; `IO::Socket::SSL` without certificate verification; `crypt`/MD5/SHA-1 for
  passwords.
- ❌ User-supplied regex patterns; nested quantifiers over unbounded input.
- ❌ `## no critic` without a named policy and a reason; `$@` as the only failure signal from an `eval`.
- ❌ Hand-written `bless`, or two object systems in the same project.
- ❌ Returning lists from functions that return collections (return references) without a documented
  contract.
- ❌ Deploying without `cpanfile.snapshot`, or installing from CPAN at service startup.
- ❌ Running the suite against a Perl version different from production's.
- ❌ Rewriting a legacy codebase without prior characterisation tests.
- ❌ **Choosing Perl for new code.** With one exception: the team already maintains Perl, already has
  the interpreter, the experience and the internal libraries, and the new work is a natural extension
  of that system. Outside that, hiring, the ecosystem and the tooling cadence play against you: the
  default destination is Python.

## 8. Mandatory web verification

Before pinning versions or APIs, **verify online** (WebSearch/WebFetch; MetaCPAN
`https://fastapi.metacpan.org/v1/release/<Dist>` for CPAN versions and licences — **for Perl modules
the source of truth is CPAN, not the GitHub releases**, which are often out of date or non-existent):
1. `perldoc.perl.org/perlpolicy`: which series are supported today (as of Aug 2026: **5.44 and 5.42
   full support, 5.40 security only**) and whether 5.46 is already out. Never deploy an odd X series.
2. The `perldelta` of the target version before any series jump: 5.44 made fatal things that used to
   warn (`goto` into a block, "Attempt to call undefined ... method") and removed repeated
   `use VERSION` declarations.
3. **Status of `use feature 'class'`**: as of Aug 2026 it is **still experimental** (the
   `experimental::class` warning category); check the core tracking issue and the `perlexperiment` of
   your version before betting on it for anything publishable.
4. Versions and licences on CPAN of: Perl::Critic (1.156, no release since 2024-10), perltidy
   (**GPL-2.0**), Carton (**no release since 2022**), local::lib (**2022**), Moo (**2023-01**),
   Moose (2.4000), Object::Pad (0.825), Try::Tiny (MIT), Devel::Cover, CPAN::Audit.
5. Vulnerabilities: an up-to-date `cpan-audit` + osv.dev/GitHub Advisories for the modules with XS.
6. If the project is web: version and status of Mojolicious (9.48 as of Aug 2026, Artistic-2.0),
   Dancer2, DBI and its DBD.

**Gaps not verified as of Aug 2026** (do not fill from memory; check before deciding):
- **The real status of *taint mode*.** It is documented as alive in `perlsec` and there is a public,
  long-running plan to make it a compile-time option (`-Utaint_support`, introduced around 5.36) and
  eventually retire it. **It is not verified whether the default changed in 5.42/5.44 nor whether
  there is a retirement date**: check it in the `perldelta` of your version and in the core issue
  tracker before basing a design on `-T`.

**Declared discrepancies**:
- The GitHub releases feed for `Perl-Critic/Perl-Critic` shows **v1.154 (2024-10-21)** while MetaCPAN
  gives **1.156 (2024-10-23)** for the same distribution. MetaCPAN wins (CPAN is the publication
  channel); the GitHub feed is incomplete.
- The MetaCPAN API resolves the module **`Test2::V0` to the `Test-Simple` distribution 1.302222**
  (2026-06-15), not to `Test2-Suite`, and the direct query for the `Test2-Suite` release returned no
  data. **It is not verified** which distribution `Test2::V0` lives in today: check it on MetaCPAN
  before writing it into a `cpanfile`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
