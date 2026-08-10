---
name: performance-engineering-standards
description: Use when a backend, runtime or system is slow and someone must prove why — defining a latency objective as percentile plus concurrency plus hardware, tail latency at p99 and p99.9, coordinated omission in load generators, open versus closed workload models, wrk2 -R, vegeta -rate, k6 constant-arrival-rate and ramping-arrival-rate executors, Gatling injectOpen versus injectClosed, JMeter Open Model Thread Group, Locust, HdrHistogram, the USE method (utilization, saturation, errors) and the RED method (rate, errors, duration), perf record and perf script, FlameGraph flamegraph.pl and stackcollapse, bpftrace and eBPF tracing, perf_event_paranoid, go tool pprof and net/http/pprof, py-spy, async-profiler and JFR, continuous profiling with Pyroscope, Parca or Grafana Profiles Drilldown, OTLP profiles and the OpenTelemetry eBPF profiler, sampling versus instrumentation overhead, CPU and allocation profiles, Amdahl's law, Little's law and queueing saturation near full utilization, latency budgets split across services, load versus stress versus soak versus spike tests, or a benchmark whose result nobody can reproduce.
---

# Performance engineering standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **server-side performance methodology: system, runtime, service and the path that
joins them**. What is measured, with which statistic, with which load generator, how it is
profiled, in what order the culprits are hunted and what evidence is needed to accept that an
optimisation is an improvement and not a coincidence. **The thesis**: *measure before touching,
and know what to measure*. An optimisation without measurement before and after is not
engineering, it is superstition with a commit.

Triggers: `perf record`/`perf report`/`perf script`/`perf stat`, `perf_event_paranoid`,
`flamegraph.pl`, `stackcollapse-perf.pl`, *flame graph*, *off-CPU*, `bpftrace`, eBPF, BCC,
`pprof`, `net/http/pprof`, `go tool pprof`, `py-spy`, `async-profiler`, JFR, `jemalloc` /
`heaptrack` / `massif`, Pyroscope, Parca, Profiles Drilldown, continuous profiling, OTLP
Profiles, `wrk`/`wrk2 -R`, `vegeta -rate`, k6 `constant-arrival-rate` / `ramping-arrival-rate`
/ VU, Gatling `injectOpen` / `injectClosed` / `rampUsersPerSec`, JMeter *Open Model Thread
Group*, Locust, `ab`, HdrHistogram, *coordinated omission*, *tail latency*, p95/p99/p99.9,
USE, RED, *golden signals*, Little's law, Amdahl's law, latency budget, load / stress / *soak*
/ spike testing, N+1, *cold start*, GC pause.

**Not applicable**: see `web-performance-standards` (**the finest boundary in the catalogue,
and it is already written from the other side**: theirs are the **browser and the real user**
—Core Web Vitals, RUM at p75, *bundle* budget, hydration cost, CLS—; **here the server, the
runtime and the system**. The contact point is **TTFB**: *it is their input metric and my
output metric* — **how server response time is reduced belongs here; that this TTFB feeds into
LCP and how much it weighs in the field p75 is theirs**. Operational corollary: an impeccable
server p99 does not contradict a slow website, and vice versa; **a debate about one is never
closed with the other's number**), `sre-practice-standards` (**important boundary**: SLO, SLI,
*error budget*, *burn rate* alerts, capacity planning and production reliability are theirs.
Rule: ***"how much latency can we afford and what do we do if we exceed it?" belongs to
`sre-practice`; "why is it slow and what fixes it?" belongs here***. The SLO defines the
objective; this skill provides the method that meets it), `observability-standards` (**the
telemetry platform is theirs**: collectors, OTel Collector, storage, retention, trace sampling,
cardinality, dashboards and alerts — **continuous profiling is ingested and stored there**;
**here what is profiled, at what sampling frequency and how a *flame graph* is read**),
`testing-qa-standards` (**reciprocal declared in both directions**: there the load test is
**planned** as a test type —scenarios, data, stopping criteria, and the rule that it never goes
in the PR gate—; **here the load model (open or closed), the measurement methodology and the
interpretation of the result**, §4. A load script written there that uses a closed model
against an open system produces an invalid number according to this skill),
`data-platform-standards`, `sql-standards`, `mysql-mariadb-dba-standards`,
`oracle-dba-standards`, `sqlserver-dba-standards`, `nosql-standards`, `timeseries-db-standards`
and `search-engines-standards` (**engine, index and query plan tuning are theirs**; here only
the methodology that proves the bottleneck is in the database and with what evidence you knock
on their door), `python-standards`, `go-standards`, `rust-standards`,
`jvm-spring-standards`, `dotnet-standards`, `cpp-standards`, `c-standards`,
`typescript-standards` and the other language skills (**the runtime's specific profiler, its
flags and its garbage collector tuning are theirs**; here the common method and when to reach
for them), `gpu-computing-standards` (kernels, occupancy and GPU memory),
`caching-cdn-standards` (HTTP cache policy, the CDN and purging; **here the cache as an
architecture decision with a coherence cost**, §6.5), `networking-standards` and
`network-troubleshooting-standards` (**network diagnosis is theirs**: RTT, loss, MTU,
*retransmits*, capture; here only placing the network in the suspect tree and handing them the
case), `kubernetes-standards` (*requests*/*limits*, HPA, cgroup CPU *throttling*),
`linux-administration-standards` and `linux-storage-standards` (system and storage tuning),
`operating-systems-standards` (***"how is it measured?" belongs here; "what OS mechanism
produces that number?" is theirs*** — scheduler, memory management, the real cost of a system
call, `fsync` guarantees), `finops-standards` (**cost as a metric and its budget**; here cost
only appears as an argument for sizing) and `microservices-architecture-standards` (the
division of responsibilities between services; here the division of the **latency budget**
between them, §3.3), `refactoring-tech-debt-standards` (**optimising is not refactoring**:
refactoring changes the structure **without** changing observable behaviour; optimising changes
an observable characteristic —latency— and therefore **is measured before and after and is
justified with that data**. Debt criteria, its register and its funding are theirs; the
methodology of finding and proving the improvement, here. And the warning they share:
**optimised code expires** and needs a review date, whereas a well-done refactor does not),
`green-it-standards` (**the methodology of measuring before touching,
profiling and proving the improvement belongs here**; **the energy and carbon metric is
theirs**, with its own accounting and its own traps. Warning both share: **code efficiency and
footprint reduction are not the same thing** — the real order of impact starts with switching
off what is idle and right-sizing, and optimising code for sustainability is only justified at
a scale that has to be calculated, not inherited).

## 2. Default decisions

> Verify the latest version and the licence on the web before pinning it in a real project (§8).

### 2.1 The two named methods, cited at source

They are not styles: they are **checklists with an author, and they apply to different
things**. Using them crosswise is the most expensive framing error.

**USE — Brendan Gregg** (`brendangregg.com/usemethod.html`; published on his dtrace.org blog
on 29 Feb 2012 and in ACM Queue as *Thinking Methodically about Performance*, 2012, and in
CACM, 2013). Verbatim:

> *"For every resource, check utilization, saturation, and errors."*
> *"resource: all physical server functional components (CPUs, disks, busses, ...)"*
> *"utilization: the average time that the resource was busy servicing work"*
> *"saturation: the degree to which the resource has extra work which it can't service, often queued"*
> *"errors: the count of error events"*

Scope declared by the author himself, verbatim: *"It solves about 80% of server issues with 5%
of the effort"*, and its limit, also verbatim: *"There are many problem types it doesn't
solve, which will require other methods and longer time spans"* / *"While the USE Method may
find 80% of server issues, latency-based methodologies (eg, Method R) can approach finding 100%
of all issues."* **The 80/5 is cited as what it is —a claim by the author, not a study— or it
is not cited at all.**

**RED — Tom Wilkie**, created **in 2015** (Grafana Labs, *The RED Method: How to Instrument Your
Services*, presented at GrafanaCon EU 2018; Wilkie arrived at Grafana with the acquisition of
Kausal, and developed RED at Weaveworks). Verbatim from the definition:

> *"Rate (the number of requests per second), Errors (the number of those requests that are
> failing), Duration (the amount of time those requests take)"*

Declared reason, verbatim: *"The USE Method doesn't really apply to services; it applies to
hardware, network disks, things like this. We really wanted a microservices-oriented monitoring
philosophy, so we came up with the RED Method."* And the relationship with the two neighbours,
verbatim: on the *Four Golden Signals* (latency, traffic, errors, saturation), *"This is
basically the same as the RED Method, but includes saturation"*; and on using them together,
*"the RED Method is about caring about your users and how happy they are... and the USE Method
is about caring about your machines and how happy they are... They're complimentary."*

⚠ **Discrepancy declared in the source itself**: the Grafana article heads **both** lists with
*"For every resource, monitor:"*, including RED's, despite the text immediately before it
arguing that RED exists precisely because USE does **not** apply to services. The formulation
consistent with the rest of the article and with universal usage is **"for every *service*"**.
When citing RED, cite the triad, not the heading.

**Rule of use**: **USE for resources** (CPU, memory, disk, network, controllers, cgroups) and
**RED for services and endpoints**. In an incident you walk **both**: RED says *which service*
hurts, USE says *which resource* causes it. The SRE Book's *golden signals* are RED +
saturation and belong to `sre-practice-standards`; **here they are used as a search index, not
as an alert**.

### 2.2 Tools — status and licence verified as of Aug 2026

| Use | Default | Licence / verified status | Note |
|---|---|---|---|
| CPU profiling on Linux | **`perf`** | GPL-2.0 (`SPDX-License-Identifier: GPL-2.0` in `tools/perf` of the kernel tree) | Sampling, in the kernel; no third-party dependencies |
| Profile visualisation | **FlameGraph** (`stackcollapse-*.pl` + `flamegraph.pl`) | ⚠ **CDDL** — *"all files in this distribution are released under the Common Development and Distribution License (CDDL)"* (`docs/cddl1.txt`) | **It is not MIT nor Apache**: per-file copyleft. If it gets packaged, it goes through review |
| Ad hoc dynamic tracing | **`bpftrace`** | Apache-2.0 (raw `LICENSE`) — v0.26.1 (2 Jun 2026) | For questions no counter answers |
| Continuous profiling (OSS) | **Grafana Pyroscope** | ⚠ **AGPL-3.0** (raw `LICENSE`) — active weekly releases (Aug 2026) | AGPL: relevant if offered as a service. UI: *Profiles Drilldown* (plugin, **public preview**, not GA) |
| Continuous profiling (alternative) | **Parca** | Apache-2.0 (raw `LICENSE`) — active, engine behind Polar Signals Cloud | Permissive licence; smaller ecosystem |
| Interchange standard | **OTLP Profiles** | ⚠ **Public alpha since 26 Mar 2026** | §2.4. Do **not** bet critical production on it yet |
| Constant-rate load | **`wrk2`** (`-R` mandatory) | Apache-2.0 (raw `LICENSE`) | Historical reference for corrected latency; **old repo, verify before adopting** |
| Programmable load | **k6** with `constant-arrival-rate` / `ramping-arrival-rate` executor | ⚠ **AGPL-3.0** (raw `LICENSE.md`) — v2.1.0 (30 Jun 2026) | The VU default is a **closed model**: the executor has to be chosen by hand (§4.2) |
| JVM load | **Gatling** (`injectOpen`) | Apache-2.0 (`LICENSE.txt`; *"Gatling Open Source is licensed under Apache 2.0"*) — v3.15.1 (25 May 2026) | Gatling Enterprise is a separate paid product |
| Legacy GUI load | JMeter | Apache-2.0 — **5.6.3, no new release since Jan 2024** | *Open Model Thread Group* declared **experimental** (§4.2). It is not the default for anything new |
| Simple HTTP attack | `vegeta` (`-rate`) | MIT (raw `LICENSE`) | Good for one endpoint, not for a user journey |
| Load in Python | Locust | MIT (raw `LICENSE`) | Requires explicitly choosing the arrival model |
| Latency distribution | **HdrHistogram** | — | Latency recording is **always** a histogram, never a running average (§3.2) |

**Warnings that correct common assumptions**:
- **k6 is AGPL-3.0**, not Apache or MIT. If it is embedded in a product or offered as a
  service, that is a legal decision, not a tool choice.
- **Pyroscope is AGPL-3.0**; **Parca is Apache-2.0**. They are the same category with licences
  incompatible in purpose: the choice is made with the lawyer present, not by the UI.
- **FlameGraph is CDDL**, not permissive. It is the case most people assume is MIT.
- **JMeter has gone more than two years without a release** on its official site (5.6.3, Jan
  2024). The GitHub feed agrees here, but **the GitHub feed is not the source of truth**: Apache
  publishes at `jmeter.apache.org`. Check there (§8).

### 2.3 Sampling versus instrumentation

| | Sampling | Instrumentation (*tracing*/*instrumenting*) |
|---|---|---|
| What it does | Interrupts at a fixed frequency and records the stack | Records every event that has been marked |
| Bias | Statistical: misses the rare, sees the expensive well | Observer bias: the cost grows with the event's frequency |
| Cost | Bounded and predictable by frequency | **Unbounded**: an instrumented hot function can dominate its own profile |
| Use | **By default**, and the only acceptable one in continuous production | Ad hoc, bounded, on the already suspect path |
| Trap | Does not see **off-CPU** time (I/O wait, blocking, scheduler) | A counter per call turns the cheap into the expensive and **changes the result it was going to measure** |

**Hard rules**:
- **In production you profile by sampling.** Fine-grained instrumentation in production only
  with bounded scope, a time window and automatic deactivation.
- **Frequency by convention: non-round values** (e.g. `perf record -F 99` instead of
  100 Hz). A frequency that coincides with a timer, a `tick` or a system loop always samples
  the same phase and produces a biased profile that looks perfect.
- **A CPU profile does not explain a waiting latency.** If the service is slow but the CPU is
  idle, the CPU profile will come out empty of culprits: you need an **off-CPU** profile
  (blocking, scheduler, I/O) or traces. It is the most frequent diagnostic error after
  *coordinated omission*.
- **A *flame graph* is read by width, not by height.** Height is stack depth; width is time. A
  tall, narrow stack costs nothing.
- **Profiling CPU and profiling memory allocation are two different questions.** The
  allocation/*heap* profile is the one that explains GC pressure and many tail latencies; the
  CPU one does not see it. Both, or the diagnosis is incomplete.

### 2.4 OpenTelemetry Profiles — verified status, and why it matters

**Status: public alpha since 26 Mar 2026** (official OpenTelemetry announcement, *OpenTelemetry
Profiles Enters Public Alpha*, signed by the Profiling SIG). What is verifiable from it:

- Format with stack deduplication and dictionary tables; optional link to `trace_id` /
  `span_id` for **cross-signal correlation** (profile ↔ trace); on-wire size reduction cited by
  the announcement itself as **"40% smaller wire size"** for the string dictionary.
- Relationship with `pprof`, verbatim: *"Originally inspired by the pprof format and developed in
  collaboration with pprof maintainers, OTLP Profiles has evolved into an independent standard...
  Data in the original pprof format can be round-trip converted to/from OTLP Profiles with no
  loss of information."*
- The **whole-system eBPF profiler donated by Elastic** is already an official Collector
  component (receiver), with on-target symbolisation for Go, ARM64 for Node.js/V8, initial
  BEAM and .NET 9/10 support.
- Warning from the announcement itself, verbatim: *"As the signal is still under development,
  production-ready backends have not yet emerged but multiple vendors are working on supporting
  OpenTelemetry Profiles."*

**Criteria**: **alpha means alpha.** OTLP Profiles is adopted as the **target format** when
designing today (it avoids getting tied to a proprietary agent), but **the production backend
is still Pyroscope or Parca**, and the architectural commitment is reviewed at each release
(§8). Pinning a critical backend today on the alpha signal is debt with a due date.

## 3. The prior discipline: define the objective before measuring

### 3.1 A performance objective without these four pieces is not an objective

**Metric + percentile + load + hardware.** Miss one and the number is not comparable with
anything, not even with itself the following week.

```
p99 latency of /api/orders  ≤ 300 ms
  at 500 req/s sustained (open arrival model, Poisson)
  on 3 replicas of 2 vCPU / 4 GiB, database with the production dataset
  measured at the client, not at the server
```

- **"Fast" is not an objective.** Neither is "under 300 ms", if it does not say at which
  percentile nor under how much load: any system meets any latency with one user.
- **The objective is expressed in user terms**, not component terms: "search responds in X",
  not "the query takes Y". The per-component budget is **derived** from the objective (§3.3),
  never the other way round.
- **It is measured at the client.** The time the server thinks it took excludes accept
  queueing, TLS, and precisely the queue that causes the problem.

### 3.2 Why the mean lies, and what is used instead

- **The latency distribution is not normal**: it has a long right tail and is usually
  multimodal (cache hit / cache miss; fast path / slow path; with GC / without GC).
  **On a multimodal distribution the mean can fall in a valley where there is no real
  request at all.** A mean of 120 ms is compatible with "all of them take 120 ms" and with "90 %
  take 20 ms and 10 % take a second": they are two different systems and only one is acceptable.
- **The mean is insensitive to the tail by construction**; the tail is exactly what the user
  remembers and what saturates the system upstream.
- **The median lies just the same, more discreetly.** Decisions are made with **p99** as a
  minimum, and with **p99.9** in services with internal fan-out (§3.4).
- **Percentiles are not averaged and are not summed.** The mean of the p99s of ten instances is
  not the p99 of the set; summing the p99 of three dependencies does not give the p99 of the
  total. You aggregate with histograms (HdrHistogram, `histogram_quantile` over *buckets*),
  never with arithmetic over already-computed quantiles. A dashboard that averages percentiles
  is broken however pretty it looks.
- **Standard deviation over a long-tailed distribution means nothing.** It is not reported.
- **Maximum and p100**: they are recorded (they expose the worst case and pathological
  *outliers*), not used as an objective — a single event sets the number.

### 3.3 Latency budget and its division

The user objective is **divided** among the stages of the path, and **the sum of the budgets is
less than the objective**, not equal to it: the margin pays for retries, variance and what does
not exist yet.

- The budget is written **per dependency**, with a named owner, in the repository.
- **A service cannot promise a p99 better than the worst p99 on its critical path.** Before
  committing to a number, the floor of the synchronous dependencies is summed.
- **Every added synchronous hop consumes budget permanently.** Adding a network call to a hot
  path is an architecture decision with a price; the price is written in the ADR
  (`microservices-architecture-standards`).
- **Retries multiply load at the worst possible moment.** A retry without *backoff* with
  *jitter* and without a retry budget turns a degradation into a collapse. The pattern belongs
  to reliability (`sre-practice-standards`); **the effect on tail latency belongs here**: the
  retry is the user's time.
- **Timeouts are derived from the budget, they are not copied.** A client *timeout* larger than
  the stage's budget is a decorative *timeout*.

### 3.4 Tail amplification: why the internal p99 is the user's p50

If a user request opens **N** internal calls in parallel and waits for all of them, the
probability that **none** falls into the slow tail decays with N. With N=100 independent calls
and an internal p99, the probability that all 100 are below the p99 is
0.99¹⁰⁰ ≈ **0.366**: that is, **~63 % of user requests touch at least one call above the
internal p99**. It is arithmetic, not a study.

Operational consequences, and they are harsh:
- **In fan-out services you optimise p99.9, not p99.** The internal p99 is already the typical
  user case.
- **Reducing fan-out is a first-order latency optimisation**, often bigger than any
  micro-optimisation of code.
- **A single slow component on the path dominates the result** however fast the rest are. See
  §5.1 (Amdahl).

## 4. Measuring: load tests that produce a valid number

### 4.1 Coordinated omission — the most expensive and least known measurement error

**What it is.** Term coined by **Gil Tene**. The load generator **inadvertently coordinates
with the measured system**: if the next send depends on the previous one having finished, when
the system stalls **the generator stops sending** for exactly the bad interval. Result: instead
of the N slow requests a real user would have suffered, the histogram records **a single** slow
sample. High percentiles come out **orders of magnitude** better than they were.

**Why it is so toxic**: it is not a failure of the measured system, it is a failure of the one
measuring, and **it gets worse exactly when the system gets worse** — that is, the tool lies to
you more the more the truth matters. A closed generator can report an excellent p99 for a
service that stops for whole seconds.

**Canonical illustration** (mechanics, not an empirical figure): target 10 req/s, normal
service of 50 ms; the system stalls for 5 s. A closed generator records **one** request of
~5 s and none of the ~50 it should have sent in that gap. "Corrected" latency also counts the
time each pending request **should** have been waiting since its expected arrival instant.

**What avoids it, verified**:

| Tool | Model | Verified status |
|---|---|---|
| **`wrk2`** | Mandatory constant rate (`-R`), HdrHistogram, reports **corrected** and **uncorrected** latency | Designed by Tene specifically against CO |
| **k6** | `constant-arrival-rate` / `ramping-arrival-rate` = open; **VU in a loop = closed** | Its own documentation names it, verbatim: *"In some testing literature, this problem is known as coordinated omission"* — describing its **closed model** |
| **Gatling** | `injectOpen` (open, `rampUsersPerSec`) vs. `injectClosed` (closed); **they cannot be mixed in one scenario** | Explicit choice in the script |
| **`vegeta`** | `-rate` = open by design | One endpoint, not a user journey |
| **Locust** | Requires a choice; its documentation warns that a test which does not reach the throughput target shows artificially low response times | Explicit config |
| **JMeter** | *Open Model Thread Group*, verbatim from its documentation: ***"This thread group is experimental, and it might change in the future releases."*** | The classic *Thread Group*s are **closed** |
| **`ab`, `wrk` (original)** | Closed, no correction | **Banned** for measuring percentiles (§7) |

**Hard rules**:
- **The arrival model is declared in writing in the test report.** A result without a declared
  open or closed model is a number without units.
- **Open system → open generator.** A public API, a website, a database with independent
  clients are open systems: real users **do not wait** for the ones next to them to finish
  before clicking. Measuring them with a closed generator is measuring a different system.
- **The closed model is legitimate** when the real system *is* closed: a job queue with N fixed
  workers, a batch, an internal client with bounded concurrency. The rule is not "always open",
  it is **"the generator's model must be the system's model"**.
- **If the generator hits its own limits** (CPU, sockets, descriptors, a single node against a
  cluster), the test is **invalid and is discarded** — it is not interpreted. The generator is
  monitored with the same seriousness as the target.
- When using `wrk2`, **the corrected latency** is reported. Publishing the uncorrected one
  without saying so is publishing the error.

### 4.2 The four test types, and what each one answers

They are planned in `testing-qa-standards`; **the interpretation belongs here**.

| Type | Question | Duration | Failure signal |
|---|---|---|---|
| **Load** | Does it meet the objective under the expected load? | Enough to stabilise | The latency budget is exceeded |
| **Stress** | Where is the breaking point and **how** does it break? | Ramp until degradation | It breaks in an uncontrolled way (no *shed*, no degradation, with cascade) |
| **Endurance (*soak*)** | Does it degrade over time? | Hours or days | Growing drift in memory, descriptors, connections, latency; fragmentation; poisoned cache |
| **Spike** | Does it survive an abrupt jump and recover? | Minutes | It does not return to the previous level after the spike — the most expensive failure and the least tested |

**The *soak* is the one most people skip and the one that prevents the most incidents**: memory
and descriptor leaks do not show up in a ten-minute test, by definition.

### 4.3 Validity requirements for a test

Miss **one** and the result is not published:

1. **Declared environment parity.** **A load test against an environment that is not
   production parity does not produce a number: it produces a useless number.** The factors
   that break it and are not negotiable: **data volume and distribution** (an index over a
   thousand rows always fits in memory and is always fast; the query plan can be *another one*
   at real volume), **topology** (one replica versus three, with or without a real load balancer
   and real proxies), **machine class and noisy neighbours**, **real network latency between
   components**, **cgroup limits / CPU *throttling***, and **identical runtime configuration**
   (GC, *pools*, *timeouts*). If there is no parity, the result is only good for **comparing
   with itself** across identical runs, and it is written that way in the report.
2. **Warm-up and discard.** JIT, caches, connection *pools*, page tables and filesystem caches
   need a warm-up period **that is discarded from the result**. Including start-up in the
   histogram contaminates the tail with an artefact.
3. **Representative data with realistic cardinality.** A single user, a single key or a single
   product turns the test into a cache test. The access distribution matters as much as the
   volume (Zipf, not uniform).
4. **Duration long enough to reach steady state** and for the periodic events to occur: major
   GC, connection rotation, cache expiry, scheduled tasks, *compaction*.
5. **Repeatability**: N≥3 runs. If the variance between runs exceeds the difference you want to
   demonstrate, **nothing has been demonstrated**.
6. **System under test observed during the test**: USE on every resource, RED on every
   service. A test that only produces the final number does not allow diagnosing anything.
7. **Reproducible record**: artefact version, *commit*, configuration, dataset, tool, script,
   arrival model and hardware. **A result nobody can reproduce is an anecdote.**

### 4.4 Microbenchmarks

- **A microbenchmark measures the microbenchmark.** It is valid for comparing two
  implementations of the same function, and **not** for predicting the service's latency.
- The language's harness is used (it is theirs: JMH, `go test -bench`, `criterion`,
  `pytest-benchmark`), with warm-up and statistical significance. **Without reported variance,
  it is not accepted.**
- **The compiler can eliminate the measured code.** If the result is not consumed, the
  optimiser deletes it and you measure an empty loop. It is a silent failure.
- **Justifying an architecture change with a microbenchmark is forbidden** (§7).

## 5. The right order of the search

### 5.1 Amdahl's law: the ceiling is set by what you do not optimise

Amdahl (1967, *AFIPS Conference Proceedings* vol. 30, pp. 483-485 — verify the reference
before citing it in a formal document, §8). Formulation: if a fraction **p** of the time is
sped up by a factor **s**, the total improvement is **1 / ((1−p) + p/s)**.

Consequence that decides the order of work: **making infinitely fast a part that takes 5 % of
the time produces, at most, a 5.3 % improvement.** Therefore:

1. **Measure the whole hot path before touching anything.** The distribution of time by stage
   is the first artefact, always.
2. **Optimise in order of time fraction, not in order of ease or of interest.**
3. **Recalculate after each change**: once the bottleneck is removed, the bottleneck is another
   one and the priority list changes entirely. A performance task list **expires as soon as the
   first item is completed**.
4. **Scaling out does not fix what is serialised.** That is the practical corollary: if 20 % of
   the work is serial (a global lock, a hot table, a single service), doubling replicas does not
   give 2×. Gunther's Universal Scalability Law adds the **coherence** term (the cost of the
   replicas agreeing with each other), which can make **adding capacity make performance
   worse**. Verify the formulation before citing it (§8).

### 5.2 The suspect tree, by layer and in this order

You walk it top-down, and **each layer is ruled out with evidence**, not with intuition:

1. **Unnecessary work** — the optimisation that always wins. Is something being computed that
   nobody looks at? Is more being requested than is used? Is a whole object being serialised to
   read one field? It is removed; it is not optimised.
2. **Application**: algorithmic complexity over the **real** input size; **N+1** of queries or
   of remote calls (the classic and the most expensive); serialisation and deserialisation
   (often the biggest CPU consumer in a "network" service); data copies; locks and contention;
   synchronous work that should have been asynchronous.
3. **Runtime**: garbage collector pauses and pressure, *heap* size and policy, badly sized
   *pools* (connections, threads), cold start, JIT. **The specific tuning belongs to the
   language skill**; here only the evidence that it is there.
4. **Database**: query without an index, changed plan, locks, *pool* exhaustion, long
   transactions, `N+1`. **You knock on the engine skill's door with evidence**: the query, its
   plan and its share of total time.
5. **Network**: RTT, hops, MTU, loss and retransmission, TLS handshake, DNS.
   **`network-troubleshooting-standards` diagnoses**; here you only locate it and hand it over.
6. **Disk / storage**: service latency, queue depth, random vs. sequential pattern, `fsync`,
   IOPS saturation.
7. **Kernel and platform**: scheduler, cgroup *throttling* (the favourite cause of bad p99 on
   Kubernetes with aggressive CPU *limits*), NUMA, descriptor exhaustion, conntrack table,
   memory pressure.

**Cross-cutting rule**: **a layer is ruled out with a measurement, not with an argument.** "It
can't be the database" does not rule out the database.

### 5.3 Latency versus throughput: improving one worsens the other

They are not the same quantity and **they are optimised with opposing techniques**:

| Technique | Effect on throughput | Effect on latency |
|---|---|---|
| Batching | ↑↑ | ↑ (waits to fill the batch) |
| Deeper queue | ↑ (absorbs spikes) | ↑↑ (more waiting time) |
| More concurrency | ↑ until saturation | ↑ past saturation |
| Compression | ↑ if the network is the bottleneck | ↑ CPU at both ends |
| Speculative execution / *hedged* requests | ↓ (duplicated work) | ↓↓ in the tail |

**Hard rule**: **which of the two is being optimised is declared before starting.** One team
optimising throughput and another optimising latency on the same system undo each other's work.
And **a bigger queue never fixes a capacity problem**: it only turns fast errors into long
waits, which is worse.

## 6. Queues, saturation and sizing

### 6.1 Little's law

**J. D. C. Little (1961), *A Proof for the Queuing Formula: L = λW*, Operations Research
9(3):383-387.** L = mean number of units in the system, λ = mean arrival rate, W = mean time in
the system. It is **independent of the distribution** of arrivals, of service and of the queue
discipline: that is why it can be applied almost always.

Useful form in systems: **concurrency = throughput × latency**. Three calculations come out of
that, and they are done **before** touching configuration:

- **Sizing a *pool***: to serve 500 req/s with 40 ms of latency you need 500 × 0.04
  = **20** requests in flight. A *pool* of 200 threads does not give more throughput: it gives
  180 threads waiting and a hidden queue.
- **Detecting an impossible measurement**: if the generator says 1000 req/s with 10 ms of
  latency and only holds 2 connections, the numbers do not add up (2 ≠ 10). **One of the three
  is mismeasured** — usually latency, through *coordinated omission*.
- **Knowing how much queue there really is**: L grows when latency grows at constant
  throughput. That is the operational definition of saturation.

### 6.2 Why latency explodes near 100 % utilisation

In the **M/M/1** model (Poisson arrivals, exponential service, one server), with utilisation
ρ = λ/μ and service time S = 1/μ, mean response time is **R = S / (1 − ρ)**. Direct arithmetic
consequence —**it is not an empirical datum, it is the model**:

| Utilisation ρ | Response time R |
|---|---|
| 50 % | 2 × S |
| 80 % | 5 × S |
| 90 % | 10 × S |
| 95 % | 20 × S |
| 99 % | 100 × S |

What you have to take away, and it is what breaks almost every capacity plan:

- **The relationship between utilisation and latency is not linear: it is an asymptote.** The
  last percentage points of utilisation are unbearably expensive in latency.
- **A resource at 95 % is not "nearly fine": it is saturated.** The margin is not slack, it is
  the price of tail latency.
- **Variability makes the curve worse.** M/M/1 is the *benign* case; with service more variable
  than exponential (the norm in real software: multimodal, with GC, with cache misses) latency
  rises earlier and higher.
- **You never size to a target utilisation without declaring the associated latency objective.**
  "Target 80 % CPU" without latency alongside it is half a decision. The **specific target
  utilisation number depends on the system and is derived from the latency budget**: this skill
  does not fix it (§8).
- **Any target-utilisation table copied from a blog is suspect.** The derivation is done with
  your own measured S and your own p99 objective.

### 6.3 Saturation: what to look at, not what to assume

Utilisation hides saturation. You watch **the queues**, which is where latency lives: run queue
depth, I/O wait, connection *pool* queue, socket accept queue (*backlog*), block device queue
depth, cgroup *throttling*. **A CPU at 60 % with a permanent run queue is saturated**; the
utilisation percentage does not say so.

### 6.4 Concurrency, not capacity, is what has to be limited

- **Admission limits are set on in-flight concurrency**, not only on requests per second: that
  is what protects against the asymptote in §6.2.
- **Shedding load fast is better than queueing it**: a queue that grows indefinitely turns a
  spike into a total outage and also ruins the requests that could have been served. The design
  of degradation and *shedding* belongs to `sre-practice-standards`; **the argument for why
  belongs here**.
- **Retries**: they multiply load exactly when the system is saturated.

### 6.5 Cache: it is a decision with a cost, not a patch

- **A cache does not fix a bad algorithm: it hides it until the cache misses.** Before caching,
  you answer in writing: why is the thing you are about to cache expensive, and can it not be
  made cheap?
- **The real cost of a cache is invalidation and coherence**, not memory. Every cache adds: an
  ambiguous source of truth, a new failure mode (stale data served as good), and a cold-start
  scenario in which the system does **not** withstand its nominal load.
- **It is always declared**: what invalidates each entry, how long stale data is tolerated, and
  **what happens when the cache is empty or down**. If the answer to the last one is "everything
  falls over", the cache is not an optimisation: it is a critical component without redundancy.
- **A cache is measured by its effect on p99 latency, not by its hit rate.** A 95 % hit rate
  with the remaining 5 % at 2 s leaves an appalling p99.
- **Simultaneous reload spikes (*stampede*)** turn a cache miss into an outage. Mechanics and
  mitigation: `caching-cdn-standards`.

## 7. Sustainability and prohibitions

### 7.1 The record of the work

- **Every optimisation is accompanied by a before and after measurement, in the same
  environment, with the same script and with reported variance.** Without both halves, the
  change is reverted: there is no way to tell it apart from noise.
- **Per-service performance register**, versioned in the repository: current objective, dated
  baseline, applied optimisations with their measurement, and a **review date**.
- **Optimised code expires.** Every non-obvious optimisation carries a comment with: what was
  measured, how much it gained, over which version of which dependency, and a **review date**.
  The reasons it expires are routine: the compiler or the JIT changes, the data volume changes,
  the hardware changes, the library changes — and the optimisation goes from being an advantage
  to being complexity nobody dares touch. **An optimisation without a review date is debt with
  interest.**
- **Premature optimisation — the criteria, not the quote.** The rule is not "don't optimise": it
  is that the cost of an optimisation is **permanent complexity** and its benefit is
  **hypothetical until measured**. Therefore: you optimise when (a) there is a written objective
  that is not being met, and (b) there is a measurement that points at that specific code.
  Neither of the two conditions can be substituted by experience. **Explicit exception**:
  decisions that are **expensive to reverse** — data schema, concurrency model, service
  boundary, serialisation format — are reasoned with orders of magnitude **before** building.
  That is not premature optimisation: it is design. Confusing the two is the lazy reading of
  Knuth's sentence.
- **Cadence**: review the state of the profiling tools and of OTLP Profiles on the web
  **every quarter** while the signal is still in alpha (§8). Review the performance objectives
  when the data volume, the hardware or the topology changes — and at least once a year.

### 7.2 Explicit prohibitions

- ❌ **Optimising without measuring first.** Without a baseline there is no improvement: there
  is an opinion with a `git commit`.
- ❌ **Declaring an improvement without a subsequent measurement** in the same environment and
  with the same methodology as the baseline.
- ❌ **Deciding with the mean.** And also forbidden is the chart that only shows the mean, and
  the dashboard that **averages percentiles** across instances or sums them across services
  (§3.2).
- ❌ **Reporting percentiles obtained with a closed load generator against an open system**, or
  without declaring the arrival model. That is *coordinated omission* and the number is false
  (§4.1).
- ❌ **`ab` or the original `wrk` for measuring percentiles.** Without CO correction, they are
  good for "is it alive?" and nothing more.
- ❌ **Publishing the result of a load test without declaring the environment parity**, the
  dataset and the hardware. And it is **FORBIDDEN** to present as production capacity a number
  obtained in an environment that is not parity.
- ❌ **Load testing against production without written authorisation, an agreed window and a
  stop plan.** It is a self-inflicted denial of service.
- ❌ **Micro-optimising before having the time breakdown of the whole hot path** (§5.1).
- ❌ **Justifying an architecture decision with a microbenchmark** (§4.4).
- ❌ **Adding a cache to cover a slow query** without having answered why it is slow and without
  declaring invalidation and cold behaviour (§6.5).
- ❌ **Increasing the size of a *pool*, a queue or a *timeout* as a response to saturation.**
  It is moving the problem somewhere it takes longer to see and hurts more when it appears (§6.4).
- ❌ **Sizing to a target utilisation without an associated latency objective** (§6.2).
- ❌ **Profiling in production with unbounded instrumentation** or with a tool without a cost
  limit and without automatic deactivation (§2.3, §7.3).
- ❌ **Concluding that "the CPU is idle, therefore it is not performance"**: the off-CPU profile
  is missing.
- ❌ **Comparing two runs with different data, versions or environments** and calling it an
  improvement.
- ❌ **Adopting OTLP Profiles as the backend for critical production** while it remains in alpha
  (§2.4).
- ❌ **Pinning Pyroscope, k6 or FlameGraph into a product without reviewing its licence**
  (AGPL-3.0, AGPL-3.0 and CDDL respectively, §2.2).
- ❌ **Copying a "target utilisation" or "recommended p99" table from a blog** instead of
  deriving it from your own budget and your own measurement.

### 7.3 Profiling in production without opening a hole

- **Profiles carry data.** Function names, file paths, symbols and —in allocation profiles and
  *heap* dumps— **content**. A memory dump is maximum-sensitivity material: it contains secrets
  in the clear, tokens and personal data. It is handled with the access control of the most
  sensitive data that passes through the process, not with that of the repository.
- **eBPF and `perf` are privilege.** `perf` requires adjusting `perf_event_paranoid` or
  `CAP_PERFMON`; eBPF requires `CAP_BPF` (plus `CAP_PERFMON` / `CAP_SYS_ADMIN` depending on the
  case). Lowering `perf_event_paranoid` at node level opens side-channel surface between tenants.
  Container and node hardening belong to `container-runtime-security-standards` and
  `linux-hardening-standards`; **here the rule is that the privilege is granted scoped, with a
  window and with a record, not permanently "just in case"**.
- **The cost of profiling is measured, not assumed.** Continuous profiling is justified on the
  grounds of being low and bounded in cost; that cost is **verified** on your own system before
  leaving it switched on, and it is watched.
- **A badly resolved symbol lies.** Without `debuginfo`/symbols, the *flame graph* attributes
  time to addresses or to the wrong frames, and you optimise the wrong place with total
  conviction. Verify symbolisation before believing the profile.

## 8. Mandatory web verification

Before committing any datum from this document in a real project:

1. **USE and RED — source and formulation**: re-read `brendangregg.com/usemethod.html` and
   Grafana's article *The RED Method: How to Instrument Your Services* and copy the definitions
   **verbatim**. **Declared discrepancy** (§2.1): the Grafana article heads the RED list with
   *"For every resource, monitor:"* despite arguing in the previous paragraph that RED exists
   because USE does not apply to services. Check whether the source has been corrected; until
   then, cite the triad, not the heading. Also verify RED's creation date (Grafana places it in
   **2015**) and USE's publication references (dtrace.org blog 29 Feb 2012; ACM Queue 2012; CACM
   2013).
2. **Coordinated omission**: review the **current** documentation of the tool you are going to
   use and confirm which model applies **by default**. Verified as of Aug 2026: k6 names the
   problem in its *open vs closed model* documentation (*"In some testing literature, this
   problem is known as coordinated omission"*) referring to its closed model; JMeter's *Open
   Model Thread Group* is still declared ***"experimental, and it might change in the future
   releases"***. **Check whether JMeter has stabilised it** before relying on it.
3. **Versions and status verified as of Aug 2026, all of them perishable**: k6 **v2.1.0** (30 Jun 2026),
   Gatling **v3.15.1** (25 May 2026), `bpftrace` **v0.26.1** (2 Jun 2026), Pyroscope with
   active weekly releases, Parca active. **JMeter is still on 5.6.3 (Jan 2024)** according to its
   official site `jmeter.apache.org/download_jmeter.cgi`: **more than two years without a
   release**, a datum to reconfirm before recommending it. Remember that **the GitHub releases
   feed is not the source of truth**: Apache publishes on its own site, and several projects in
   the catalogue have moved registry.
4. **Licences — read the raw `LICENSE`, always**. Verified as of Aug 2026: **k6 AGPL-3.0**,
   **Pyroscope AGPL-3.0**, **FlameGraph CDDL**, Parca Apache-2.0, `bpftrace` Apache-2.0, `wrk2`
   Apache-2.0, Gatling Open Source Apache-2.0, Locust MIT, `vegeta` MIT, `perf` GPL-2.0
   (SPDX in the kernel tree). The first three are the ones most people assume are permissive.
5. **OpenTelemetry Profiling**: lifecycle status. Verified: **public alpha since
   26 Mar 2026**, with its own verbatim warning that *"production-ready backends have not yet
   emerged"*. **Check whether it has moved to Beta/GA** and which backends really support it,
   before committing architecture.
6. **Grafana Profiles Drilldown**: verified as **public preview**, not GA. Confirm status
   before depending on its UI.
7. **Academic references to confirm before citing them in a formal document**: Little
   (1961), *A Proof for the Queuing Formula: L = λW*, *Operations Research* 9(3):383-387 —
   verified in agreeing secondary sources, **not in the original paper**. Amdahl (1967),
   AFIPS vol. 30, pp. 483-485 — **same warning**. Gunther's Universal Scalability Law is
   mentioned without fixing its formulation: **verify it before using it for sizing**.
8. **Declared gap — target utilisation**: this document **does not fix** a target utilisation
   figure (neither 70 %, nor 80 %, nor any). They circulate on the web as if they were
   universal and **no primary source has been found backing them as a general threshold**. The
   §6.2 table is M/M/1 model arithmetic, not an empirical recommendation: your own target is
   **derived** from the latency budget and the measured service time.
9. **Declared gap — cost of continuous profiling**: no overhead percentage is fixed here
   ("less than 1 %" and similar circulate without a checkable primary source). **It is measured
   on your own system** before leaving it switched on.
10. **Declared gap — USE's 80 % / 5 %**: it is a claim by the method's author on his own
    page, **not a measured result**. Cite it as such or do not cite it.

If the web contradicts this document, **the web wins** — flag the discrepancy.
