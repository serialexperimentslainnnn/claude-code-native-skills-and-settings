---
name: observability-standards
description: Observability standards. Use when working with OpenTelemetry SDKs/Collector configs, Prometheus scrape configs and recording/alerting rules, Alertmanager routing, Grafana dashboards as code, Loki, Tempo, Mimir, Pyroscope, structured logging, trace sampling, metric cardinality, or exporters and PromQL.
---

# Observability standards — telemetry, dashboards and alerts

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when instrumenting, deploying or reviewing: OpenTelemetry (SDK, auto-instrumentation,
semantic conventions, Collector and receivers/processors/exporters pipeline design),
structured logging and correlation, W3C context propagation, sampling strategy,
metric types, naming, label design and cardinality control, exemplars, RED/USE,
Prometheus (exporters, scrape, recording rules, retention, remote write), long-term
storage, Grafana and dashboards as code, log and trace backends, continuous
profiling, Alertmanager and the **cost** of telemetry.

Triggers: `prometheus.yml`, `rules/*.yml`, `alertmanager.yml`, `otel-collector-config.yaml`,
`config.alloy`, `loki-config.yaml`, `tempo.yaml`, `mimir.yaml`, `grafana.ini`,
`provisioning/`, `dashboard.json`, `OTEL_*` env vars, PromQL/LogQL/TraceQL, `promtool`,
`amtool`, `otelcol`, `weaver`, "cardinality", "exemplar", "tail sampling", "trace_id".

**Not applicable**: see `sre-practice-standards` (SLO, error budget, on-call, postmortems: here
only the mechanics of the alert and its routing), `onprem-standards` (node_exporter and
basic fleet monitoring), `kubernetes-standards` (Prometheus Operator,
ServiceMonitor and deploying the stack in the cluster), `networking-standards` (NetFlow/IPFIX
flow telemetry and network signals), `dataviz` (visual design of the chart: mark type,
colour, axes, legends), `aws-standards`/`azure-standards`/`gcp-standards` (CloudWatch,
Azure Monitor, Cloud Monitoring), `detection-engineering-standards` (security telemetry,
SIEM and detection rules; the boundary is the purpose, not the tool — the same log feeds
both, here to diagnose, there to detect), `incident-management-standards` (declaring
the incident, command and communication, once the alert has fired),
`privacy-engineering-standards` (PII that leaks into logs, traces and metrics, and its retention),
`web-performance-standards` (**the telemetry platform, the OTel pipeline and the
alerts belong here**; **which real user experience metric is collected, at which percentile it is
decided and with what threshold** is theirs — RUM arrives through this platform but they interpret it),
`timeseries-db-standards` (**boundary declared from their side and accepted by this skill**: the
**business or process** series —sensor telemetry, industrial historian, a measurement someone
queries as data— is theirs, with its own engine and its own retention; **here, platform telemetry**
—metrics, traces and logs of the system in order to operate it—. **They are not mixed in the same cluster**, and
Prometheus is not the destination for a process datapoint), `finops-standards` (**the cost of
telemetry is one more economic unit and is measured with their method**; here, what is emitted, with what
cardinality and how long it is retained — cardinality is the cost lever, and this skill owns it),
`platform-engineering-standards` (the telemetry *stack* as an internal product of the paved
path), `performance-engineering-standards` (continuous profiling is ingested and
stored here; **what is profiled and how a *flame graph* is read** is theirs).

**Guiding principle**: without telemetry there is no production, but **cost is a first-class
design constraint**, not a billing surprise. Telemetry nobody queries is paid for the
same as the telemetry that saves an incident: decide what is emitted **before**
emitting it, and every signal exists to answer a concrete question.

## 2. Default decisions

> Versions verified Aug 2026. **Verify the latest stable on the web before pinning it in
> a real project** (§8): this stack ships every few weeks.

| Area | Default | Forbidden / alternative |
|---|---|---|
| Instrumentation | **OpenTelemetry** (spec 1.59.0): traces API/SDK/protocol **stable**, logs stable (Bridge API), metrics API and protocol stable with a **"mixed" SDK**, **profiles in Development** | Depending on *profiles* in production; vendor-proprietary instrumentation that ties the code to the backend |
| Metrics | **Prometheus 3.13 LTS** (3.13.2, Jul 2026, EOL Jul 2027) | Prometheus 3.5 LTS (**EOL Jul 2026**, already expired); a non-LTS minor in prod if you are not going to upgrade every 6 weeks |
| Collection/pipeline | **OTel Collector v0.157.0** (`v1.63.0/v0.157.0`) in an **agent (DaemonSet) → gateway** pattern | A single Collector for the whole platform; `alpha` components on the critical path |
| Agent alternative | **Grafana Alloy 1.18.0** if you already live in the Grafana ecosystem | **Promtail: EOL 2 Mar 2026** — migrating to Alloy is mandatory, not optional |
| Logs | **Loki 3.7.4** with schema v13 and `structured_metadata` enabled | Elastic/OpenSearch without a real need for full-text search (far higher cost and operational burden) |
| Traces | **Tempo 3.0.2** (TraceQL) | Jaeger **v2.20.0** only if already deployed; Zipkin on new projects |
| Long-term metrics | **Mimir 3.1.4** when one Prometheus stops being enough | Thanos or VictoriaMetrics are valid and defensible alternatives; **deploying any of the three "just in case"** with a single Prometheus in front, no (KISS) |
| Dashboards | **Grafana 13.1.x** (13.1.1, Jun 2026); 12.4 (EOL May 2027) if you need a longer cycle | Dashboards created only through the UI and not versioned |
| Dashboards as code | **Git Sync** (GA Apr 2026) + **Grafana Foundation SDK** (Go/TS/Python/Java/PHP) | **Grafonnet: not officially supported** — do not start anything new there. Perses (CNCF Sandbox) only if you want a pure dashboard layer with no alerting or storage |
| Alerting | **Alertmanager 0.33.1** (or unified Grafana Alerting, one of the two, not both) | Two alerting systems in parallel: nobody knows which one woke whom |
| Continuous profiling | **Pyroscope 2.2.0** on services with recurring CPU/memory problems | Continuous profiling across the whole fleet "for completeness" (cost with no question to answer) |
| Log format | **Structured JSON** with `trace_id`, `span_id`, `service.name`, level and ISO-8601 UTC timestamp | Free-text logs parsed with regex in the backend |
| Context propagation | **W3C `traceparent`/`tracestate`** over HTTP, gRPC and message headers | Proprietary headers (B3, loose X-Request-ID) with no bridge to W3C |

## 3. Structure and conventions

**Correlation: the property that makes the whole thing useful**
- The three pillars are worth something for their **correlation**, not for existing: `trace_id` in all
  logs, **exemplars** on histograms to jump from the metric to the trace, linking from trace
  to logs and to profile. A trace you cannot reach from the chart where you see the
  problem will never be used.
- Exemplars: enable `storage.exemplars.max_exemplars` (Prometheus/Mimir) and the internal
  link to the trace datasource in Grafana. Native histograms map losslessly to
  OTLP *exponential histograms* and preserve exemplars.

**Semantic conventions and naming**
- Use the **OpenTelemetry semantic conventions**; do not invent attributes that already exist.
  If you need your own attributes, declare them in a registry with **Weaver** and validate in CI
  (`weaver check`): telemetry is a public API, with a version and a change policy.
- Two naming conventions coexist and **you must pick one per platform and write it down**:
  Prometheus (base units, `_total`, `_seconds` suffixes) versus OTel (dots and UCUM
  units). The OTLP→Prometheus translation is controlled with `translation_strategy`, whose default
  value is `UnderscoreEscapingWithSuffixes`; `NoTranslation` requires UTF-8 enabled, and
  **any strategy without suffixes allows collisions** between metrics of the same name
  with a different type or unit.
- A metric without a unit in the name, or with a unit other than the base one, is a contract bug.

**Label design and cardinality control** (the decision with the biggest impact on the bill)
- **Never** as a metric label/attribute: `user_id`, `request_id`, `trace_id`, email, URL
  with path parameters, pod name with a hash, IP, timestamp. They are unbounded dimensions.
- Rule: a label must have **bounded values known in advance**, and somebody must
  group or filter by it in a real dashboard or alert. If not, it is not a label.
- Cost: each active series takes on the order of **1-8 KiB** in the *head block* (the
  estimates vary a lot by source; measure, do not assume) and real RSS can double the
  calculation. Watch `prometheus_tsdb_head_series` and plan ahead of memory pressure.
- Diagnosis: `/api/v1/status/tsdb?limit=50`, `promtool tsdb analyze /prometheus`,
  `topk(10, count by (__name__)({__name__=~".+"}))` and churn with
  `topk(20, increase(scrape_series_added[1h]))`. Check for double scraping too (same
  target via the service and via pods): it doubles series while adding nothing.
- Containment: `sample_limit` per scrape, `metric_relabel_configs` to drop what is not
  used. Careful: the drop happens **before** storage and is irreversible — confirm that
  nobody uses it in dashboards or alerts before applying it.
- **Loki has the same discipline under another name**: few static labels (default
  limit 15) and everything high-cardinality but searchable into **structured metadata**
  (requires `allow_structured_metadata: true` and schema ≥ v13).

**What to measure: RED and USE, not "everything"**
- **RED** for services and requests: *Rate*, *Errors*, *Duration*.
- **USE** for resources (CPU, memory, disk, queues, pools): *Utilization*, *Saturation*,
  *Errors*.
- In messaging systems, **consumer lag** and DLQ depth are first-class SLIs,
  not secondary metrics.

**Collector pipeline — the order of the processors is not cosmetic**
```yaml
processors:
  memory_limiter:            # SIEMPRE el primero: aplica backpressure antes del OOM
    check_interval: 1s
    limit_mib: 1600          # ~70-80% de la memoria del contenedor; GOMEMLIMIT al 80% de esto
    spike_limit_mib: 320     # ~20% del límite duro
  k8sattributes: {}          # enriquecer antes de filtrar, si el filtro usa esos atributos
  filter: {}                 # tirar ruido...
  tail_sampling: {}          # ...y muestrear ANTES de batchear
  batch:                     # último: no batchees lo que vas a descartar
    timeout: 5s
    send_batch_size: 8192
```
- The container memory limit must be **higher** than the `memory_limiter` one, or the
  orchestrator will kill the process before it can apply backpressure.
- A large `sending_queue` + large batches can exceed the ceiling under a spike: they are
  sized together.

## 4. Mandatory quality gates

- **Validation in CI**: `promtool check config`, `promtool check rules`, `amtool check-config`,
  validation of the Collector YAML and `weaver check` of your own conventions registry.
- **Unit tests for alerting rules** (`promtool test rules`): every new alert arrives with a
  test proving that it fires with the series that must fire it and **not** with the one that must not.
- **Every alert carries `runbook_url`, an owner and a severity**; without a runbook it is not merged.
- **Instrumentation review in the PR**: name, unit, type and **bounded labels**. A
  new label of unknown cardinality is a block, not a comment.
- **Cardinality gate** before production: measure the series added by the change in
  staging and reject anything that grows without explanation.
- **Versioned dashboards and alerts** (Git Sync + Foundation SDK) deployed by
  pipeline; anything hand-made in the UI gets lost or diverges.
- **End-to-end propagation test** in the integration test: one request generates
  a complete trace, with `trace_id` present in the logs of every hop. If it breaks
  at the first hop, distributed observability does not exist.

## 5. Security and privacy

- **No PII in telemetry**: not in labels, not in span attributes, not in log messages.
  Redaction happens **at the edge** (agent `transform`/`filter` processor), not by
  trusting the backend to hide it at render time.
- Common risks that sneak in by themselves: URLs with tokens in the query string,
  `Authorization` headers, request and response bodies, error messages with business data,
  and stack traces with internal paths and credentials.
- **Cardinality as a DoS vector**: if a label takes its value from user input
  (path, user-agent, parameter), an attacker can take down the TSDB. Bound it in the code, not
  in the backend.
- OTLP always with **TLS and authentication**; the Collector endpoint is an entry point
  into the internal network, not an open mailbox. Least privilege on exporters and credentials
  from a secrets manager, never in the repo's YAML.
- **Retention by purpose and minimisation** (GDPR): operational telemetry is not a
  personal-data store. **Defaults from this skill, so that a number exists instead of an
  intention**: traces **7 days**, application logs **30 days**, aggregated metrics **13 months**
  (year-on-year comparison). Anything exceeding those periods is justified in writing with its
  purpose, and if the purpose is regulatory **the period is set by `grc-compliance-standards`, not
  this skill**. Minimisation and personal data inside telemetry belong to
  `privacy-engineering-standards`; **the default number and the cost of sustaining it belong here**.
- Grafana: RBAC per team, anonymous access disabled, datasource credentials
  provisioned from a secret (never embedded in exported dashboard JSON).
- **Audit/security logs are kept separate** from operational telemetry: different integrity,
  retention and access control (and their natural destination is the SIEM, not Loki).

## 6. Performance, cost and operability

**Cost drives the design**
- First understand **which unit you are billed on**, because it defines what to optimise: hosts + custom
  metrics + indexed GB/events (Datadog), **active series** + GB of logs/traces (Grafana
  Cloud), events (Honeycomb), GB ingested + users (New Relic). Self-hosting is also
  paid for: head block RAM, disk and object storage.
- Levers, **in this order** (from most to least effective):
  1. **Not generating** what nobody queries (always the cheapest reduction).
  2. **Aggregate before ingesting**: stream aggregation (VictoriaMetrics), Adaptive Metrics
     (Grafana Cloud), aggregation in the Collector. Typical reductions of 20-50%.
  3. **Drop at scrape time** via `metric_relabel_configs`.
  4. **Recording rules** for expensive queries — but careful: they are computed over data already
     stored, so **you pay the cardinality first**; they are not an ingestion reduction.
  5. **Tiered retention** to object storage.
  6. **Trace sampling**.
- Before aggregating or dropping something, check its actual usage (dashboards, alerts, queries). And
  accept the price: aggregation is irreversible backwards.

**Trace sampling**
- **Head sampling** (`parentbased_traceidratio`): cheap, decided at the start, trivially scalable
  — but it cannot keep the rare error because it has not happened yet.
- **Tail sampling**: decides with the complete trace (keep errors and latency tails),
  but requires that **all spans of a trace reach the same Collector**: a balancing
  layer with the `load_balancing` exporter, `routing_key: traceID`, stable backends
  (StatefulSet + headless service) and a second layer that samples. Same constraint for
  `spanmetrics` and `servicegraph`.
- **Bias, the error you pay for late**: if you only keep errors and slow requests, everything
  derived from traces (percentiles, counts) lies. Generate the metrics before
  sampling, not after.
- At extreme volume, combine: light head sampling at the edge to protect the pipeline and
  tail sampling afterwards. Use *consistent probability sampling* (`th`/`rv` keys in OTel's
  `tracestate`) so the decision is coherent across services and re-weightable.

**Alerts that do not burn anyone out**
- Alert on **symptoms** (golden signals and SLO), not on internal causes. Every alert
  answers: is there user impact and is there something to do **now**? If not, it is not a page.
- **Multi-window multi-burn-rate** over the error budget (SRE Workbook, ch. 5): a short and a
  long window that must both hold, with several levels (e.g. 14.4× over 1h+5m for
  2% of the budget, and slower levels for sustained burn). **The budget window
  is set by `sre-practice-standards` (28 days *rolling* by default) and this skill
  takes it from there**: computing the *burn rate* over another window produces a different alert with the
  same name, which is the expensive mistake. The
  long window is what stops you waking someone for a 5-minute spike that has already resolved.
- Known limitation: with **low traffic** the burn rate loses signal (few samples in the
  window). Mitigate by grouping services or with synthetic traffic — not by pretending the alert
  works. **Changing the objective is not a mitigation owned by this skill**: the SLO and its
  renegotiation belong to `sre-practice-standards`, and an objective lowered so the alert
  goes quiet is a falsified objective.
- Alertmanager: route tree by team/severity, `group_by` with the labels that
  define *one* incident (not `...`), `inhibit_rules` so the root cause silences the
  derived ones, `mute_time_intervals` for known windows, and **silences always with
  an expiry**.
- **Hygiene**: an alert that is systematically ignored or that has no possible action **is
  deleted**. Periodic review of alerts fired vs. actions taken.

**Dashboards by audience** (the visual design belongs to `dataviz`; here, the content)
- One **service** dashboard on a single screen with RED and SLO status; one **resource** one with USE;
  one **business** one if there is someone to look at it. No walls of 60 panels that nobody reads during an
  incident. Every panel answers a question and its absence is noticed.

## 7. Sustainability and prohibitions

- **Cadence**: follow the Prometheus **LTS** line (3.13 until Jul 2027); Grafana with a
  major every ~6 months, reading the breaking changes; the Collector ships very fast — **pin the
  version by tag/digest** and upgrade in a planned way.
- **Live migrations that admit no delay**: Promtail EOL (Mar 2026) → Alloy;
  Loki schema to v13 for structured metadata; Angular plugins removed in Grafana.
- Telemetry is **retired** the way it is added: a metric, dashboard or alert that stops being
  used is removed in the same PR that orphans it.

**FORBIDDEN**
- ❌ Metric labels or attributes of unbounded cardinality (`user_id`, `request_id`,
  `trace_id`, IP, URL with parameters, pod name with a hash).
- ❌ Emitting telemetry "just in case" with no question to answer and no budget assigned.
- ❌ Free-text logs with no structure, or logs without `trace_id` in a distributed system.
- ❌ An alert with no runbook, no owner, or that does not require immediate human action.
- ❌ Permanent or non-expiring silences; noisy alerts kept "just in case".
- ❌ Alerting on causes (CPU at 90%) instead of symptoms with impact (SLO burning).
- ❌ Tail sampling without a balancing layer by `traceID`: it produces fragmented traces and
  silently incorrect decisions.
- ❌ Deriving metrics (percentiles, counts) **after** sampling and presenting them as
  exact.
- ❌ A `memory_limiter` that is not the first processor, or `batch` before filtering/sampling.
- ❌ Dashboards and alerts that exist only in the UI, not versioned or provisioned.
- ❌ PII, secrets or authorization headers in logs, spans or labels.
- ❌ Exposing OTLP without TLS or authentication.
- ❌ Starting new dashboards in Grafonnet (no official support) or staying on Promtail (EOL).
- ❌ Deploying Thanos/Mimir/VictoriaMetrics before one Prometheus falls short.
- ❌ Running EOL versions of the stack (Prometheus 3.5 LTS expired in Jul 2026) with no dated plan.
- ❌ Two alerting systems in parallel (Alertmanager + Grafana Alerting) over the same rules.

## 8. Mandatory web verification

Before pinning any version or feature status, **look it up — do not recall it**.
Verified Aug 2026 (expires fast): Prometheus **3.13.2 LTS** (Jul 2026, EOL Jul 2027) and
3.5 LTS **already EOL**; Grafana **13.1.1** (13.0.4, and 12.4.x with EOL May 2027); OTel spec
**1.59.0**; OTel Collector **v1.63.0/v0.157.0**; Grafana Alloy **1.18.0**; Loki **3.7.4**;
Tempo **3.0.2**; Mimir **3.1.4**; Pyroscope **2.2.0**; Alertmanager **0.33.1**;
Jaeger **v2.20.0**; Git Sync GA since Apr 2026; Promtail EOL 2 Mar 2026.

1. **Status per OpenTelemetry signal** at `opentelemetry.io/docs/specs/status/`: traces
   stable, logs stable (Bridge API), metrics with a "mixed" SDK, **profiles in
   Development**. Do not promise what is not stable yet.
2. **Stability of the specific Collector component** you are going to use (the core is
   "mixed"): it is in each component's README, not in the binary's version.
3. **Latest LTS and EOL** for Prometheus and Grafana (endoflife.date) before pinning a version.
4. Status of features that move around: native histograms, remote write 2.0, the OTLP
   receiver and UTF-8 in Prometheus; bloom filters and schema in Loki; TraceQL in Tempo.
5. Versions and status of VictoriaMetrics, Thanos, Parca, OBI/Beyla and the OpenTelemetry
   operator — **not verified in this document**.
6. **Current billing model and unit** of the managed backend before committing to a
   design: the billable unit changes what has to be optimised, and prices rotate.
7. Semantic conventions: which groups are already stable for your domain (HTTP, database,
   messaging, gen-ai) before inventing your own attributes.

If the web contradicts this document, **the web wins** — flag the discrepancy.
