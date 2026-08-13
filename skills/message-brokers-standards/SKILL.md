---
name: message-brokers-standards
description: Use when a broker is chosen, sized, secured or operated as infrastructure — deciding whether a PostgreSQL table with SELECT ... FOR UPDATE SKIP LOCKED already covers the work queue before running a distributed system, telling a distributed log (retained and re-readable) apart from a queue (consumed and gone) and from lightweight messaging, KRaft controllers and the post-ZooKeeper world (server.properties, controller.quorum.voters, kafka-storage.sh format, kafka-reassign-partitions.sh, kafka-consumer-groups.sh, --describe), replication factor with min.insync.replicas and acks=all, log.retention.ms/log.retention.bytes and cleanup.policy=compact, consumer rebalance stop-the-world pauses, tiered storage, RabbitMQ exchanges, bindings and quorum queues after classic mirrored queues were removed in 4.0, Khepri, rabbitmq.conf, rabbitmqctl, rabbitmqadmin, publisher confirms, basic.qos prefetch and unacked message growth, NATS JetStream and nats-server.conf, Redpanda rpk and its BSL terms, Apache Pulsar with BookKeeper, brokers exposed without authentication, SASL/mTLS and per-topic ACLs, multi-tenancy and quotas, offline or under-replicated partitions, rolling major-version upgrades without dropping traffic, disk and network capacity as one decision with retention, or managed versus self-hosted broker cost.
---

# Message broker standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: **the broker is deployed, almost always, for workloads a table would have
> handled.** A distributed broker is a system with consensus, replicas, partitions, disk, network,
> major upgrades and on-call. It is adopted once the need has been demonstrated, not because
> "we are going to decouple things".

## 1. Scope and triggers

Applies to the **broker as a piece of infrastructure**: whether it is needed, which one, how it is
sized, how it is configured so the guarantees it promises are true, how it is secured, how it is
operated, how it is upgraded and what it really costs.

Triggers: `server.properties`, `controller.quorum.voters`, `process.roles`,
`kafka-storage.sh format`, `kafka-topics.sh`, `kafka-configs.sh`, `kafka-reassign-partitions.sh`,
`kafka-consumer-groups.sh --describe`, `min.insync.replicas`, `acks=all`, `unclean.leader.election`,
`log.retention.ms`, `log.retention.bytes`, `cleanup.policy=compact`, `segment.bytes`,
`rack.awareness`, `rabbitmq.conf`, `advanced.config`, `rabbitmqctl`, `rabbitmq-diagnostics`,
`rabbitmqadmin`, `x-queue-type=quorum`, `basic.qos`, `publisher confirms`, `Khepri`,
`nats-server.conf`, `nats stream add`, `jetstream`, `rpk`, `redpanda.yaml`, `broker.conf`,
`bookkeeper`, `mosquitto.conf`, `visibility timeout`, and the phrases of the domain: "we need a
queue", "we want to decouple the services", "the consumer is stuck", "messages are piling up",
"we have to reprocess yesterday's messages", "the broker disk is at 90%", "how many partitions do
we set?", "we have to do a major-version upgrade without stopping".

**Not applicable**: see
- `data-platform-standards` (**parent**): **Kafka as the platform's streaming engine is theirs**
  —default choice, partitioning, per-topic retention, the **schema registry** (Karapace,
  Apicurio) and the **event format** (Avro/protobuf)— just like **PostgreSQL and its
  `SELECT ... FOR UPDATE SKIP LOCKED` for work queues**, which is the alternative this skill
  reinforces in §2.1. Here, **deep broker operation, the alternatives to Kafka and the criterion
  for choosing between families**.
- `elixir-erlang-standards` (a boundary named because it is a real confusion):
  `Phoenix.PubSub` and BEAM message passing **are not a broker**. They live inside the application
  cluster, with no durability, no retry and no retention: if the process dies, the message is
  lost. **If the message must outlive the process that emitted it, you need a broker and this
  skill governs**; in-memory delivery between processes of the same application is theirs.
- `streaming-cdc-standards` (**sister; its cut-off rule is mirrored here word for word**):
  *if the broker makes the decision, it is theirs; if the producer, the consumer or the processor
  makes it, it belongs here* — that is, **to this skill**. Theirs: **delivery semantics,
  consumer idempotency, per-partition ordering and key choice, schema evolution, event time,
  windows, watermarks, consumer *lag*, reprocessing and dead-letter queues.** *"How many partitions
  can the cluster take?"* belongs here; *"which partition key do I choose and what ordering does it
  guarantee me?"* is theirs. **Here, only the broker configuration that makes their patterns
  possible** (§3.6).
- `microservices-architecture-standards`: **outbox, sagas, domain events, per-service data ownership
  and distributed resilience are theirs.** Here, the transport underneath. A broker **does not
  solve** atomicity between writing to your database and publishing: that is outbox, and it is
  theirs.
- `timeseries-db-standards` (**line declared on both sides**): **a broker
  transports the measurements, a time-series database stores them for querying.** They meet in IoT
  ingestion: the broker receives from the device, a consumer writes in batches to the store.
  **The broker is not the store** (§7).
- `api-design-standards`: the outward-facing message contract, versioning and webhooks.
- `identity-access-management-standards` (the identity of whoever connects),
  `cryptography-pki-standards` (**TLS and mTLS: algorithm choice, certificate issuance and rotation
  are theirs**; here only the requirement and its configuration in the broker),
  `secrets-management-standards` (broker credentials), `networking-standards` and
  `firewall-policy-standards` (segmentation and port exposure),
  `kubernetes-standards` (operators and in-cluster deployment), `iac-standards`, `cicd-standards`,
  `observability-standards` (**the metrics backend, PromQL and the dashboards are theirs**;
  here **what to measure** on a broker), `sre-practice-standards` (SLOs, on-call),
  `incident-management-standards`, `backup-recovery-standards` (**the broker log is not a
  backup**), `bcdr-standards`, `vulnerability-management-standards` (CVEs and EOL),
  `grc-compliance-standards`, `privacy-engineering-standards` (**a topic with long retention is one
  more copy of the personal data**), `jvm-spring-standards` (**Kafka and Pulsar are JVM**: *build*,
  GC, tests and packaging of clients and applications are theirs), `python-standards`,
  `aws-standards`/`azure-standards`/`gcp-standards` (**MSK, Event Hubs, Pub/Sub, SQS/SNS and other
  managed services**: their concrete limits, quotas, IAM and pricing are theirs; **here the
  criterion for when managed is the right answer**, §2.4), `caching-cdn-standards`
  (**Redis/Valkey as a cache is theirs**; **Redis Streams or lists used as a queue belong here**,
  and the criterion is in §2.3).

**Governing principle**: **a broker is not a technology decision, it is a topology decision.**
What you are really choosing is not "Kafka or RabbitMQ", it is **whether the message is retained and
can be re-read, or consumed and gone**. Getting that wrong means redoing the architecture; getting
the product wrong inside the right family is an annoying migration.

## 2. Default decisions

> Verify version, licence and **ownership** on the web before committing to it in a real project (§8).
> In 2026 this sector changed hands and licences: **IBM completed the acquisition of Confluent on
> 17-Mar-2026** and **Synadia attempted to relicense NATS under BSL in 2025**.

### 2.1 The prior question: do you need a broker?

`data-platform-standards` already says it —**a store by need, not by fashion**— and here it is
reinforced without diplomacy: **a PostgreSQL table with `SELECT ... FOR UPDATE SKIP LOCKED` solves a
simple work queue without operating one more distributed system.** And it throws in for free what is
hardest to build around a broker: **the task and the business state change in the same
transaction**, SQL queries over the queue, and backup, HA and monitoring you already have in place.

| Need | Simplest solution | When it genuinely stops serving |
|---|---|---|
| Run deferred work (emails, reports, thumbnails) at moderate volume | **Table + `SKIP LOCKED`** in the database you already have | When the rate saturates the database, or the work competes with the transactional load |
| The same, but without wanting to write the machinery | **A queue library over the database itself** from the language's ecosystem | Same as above |
| Notify **one** known service, with no tolerable loss | **HTTP call with retries and outbox** (see `microservices-architecture-standards`) | When there are many recipients or they are not known in advance |
| **Several** independent consumers of the **same** event, each at its own pace | **Distributed log** | — |
| Distributing work between workers with criteria-based routing and per-message retries | **Message queue** | — |
| Absorbing peaks the database cannot take, or decoupling teams with different SLAs | **Broker** | — |

Questions that settle the argument:
1. **How many messages per second, measured at peak?** If it is tens or hundreds, the table is more
   than enough.
2. **Does anyone need to re-read what has already been processed?** If not, you do not need a log; a
   queue is enough.
3. **Who operates the cluster, upgrades it and answers at 3 a.m.?** If there is no answer, the
   answer is managed or the table.

### 2.2 The two families that get confused — **the central difference**

| | **Distributed log** | **Message queue** | **Lightweight messaging** |
|---|---|---|---|
| Examples | Kafka, Pulsar, Redpanda | RabbitMQ, ActiveMQ, SQS | NATS (core) |
| What happens to the message | **Retained by policy (time/size) and re-readable**; the consumer carries its position | **Consumed and gone** on acknowledgement | Delivered to whoever is listening **now**; if nobody is, it is lost |
| Several consumers of the same message | Natural: each group carries its own position | Needs duplication via *exchange*/*fanout*, with one queue per consumer | Natural (publish/subscribe) |
| Ordering | Guaranteed **within a partition** | Per queue, and broken by distribution across several consumers | Not guaranteed |
| Reprocessing from the beginning | **Yes**: it is its whole reason for existing | **No**: what was consumed is gone | No |
| Criteria-based routing | Poor: the consumer filters | **Rich**: *exchanges*, *bindings*, priorities, TTL, header-based routing | By subject, with wildcards |
| Cost to operate | **High** | Medium | **Low** |
| Typical failure | Retention set wrong and full disk | A queue growing with no consumer that takes the node down | Durability is assumed where none exists |

**Getting the family right is what matters**:
- **Do you need to re-read, feed several independent systems, or rebuild a new destination from
  history?** → **log**.
- **Do you need to distribute work with routing, priority, retry and per-message discard?** →
  **queue**.
- **Do you need low-latency signalling or request/response between services, and can you lose
  whatever nobody listened to?** → **lightweight messaging**.

**Choosing a log for a work queue** forces you to hand-build per-message retries, priorities and
discards, and your parallelism ends up tied to the number of partitions. **Choosing a queue for an
event stream** leaves you without reprocessing the day you need it — and that day comes. **It is the
architecture that gets redone, not the configuration.**

### 2.3 Toolchain

| Area | Default | Verified status (Aug 2026) | When to choose it |
|---|---|---|---|
| **None** | **Table + `SKIP LOCKED`** | See `data-platform-standards` | Tier 0. Most "queues" |
| **Distributed log** | **Apache Kafka 4.3.x** (4.3.1 on the distribution site; live branches 4.1.2, 4.2.1, 4.3.1) | **Apache 2.0, ASF.** **KRaft is the only mode since 4.0** (18-Mar-2025): ZooKeeper **removed**, not deprecated. **IBM's acquisition of Confluent does not affect Kafka's licence**: the project belongs to the ASF | Default of the log family. Unbeatable ecosystem and hiring pool |
| Log, Kafka-API-compatible alternative | **Redpanda 26.2.1** (28-Jul-2026) | **Not open source**: core under **BSL 1.1** with an *Additional Use Grant* that **forbids using it to offer a "Streaming or Queuing Service"**; **Change Date = 4 years from each release's date**, *Change License* Apache 2.0. Enterprise features under a separate **Redpanda Community License Agreement** | Fewer pieces to operate (no JVM, no ZooKeeper) in exchange for a non-OSI licence and a smaller ecosystem. **ADR mandatory** |
| Log, multi-tenant alternative | **Apache Pulsar 4.2.4** (3-Aug-2026; LTS branch **4.0.x** with 4.0.13 the same day; **5.0.0-M1** in Jun-2026) | **Apache 2.0, ASF. Live project**, with a real cadence and an LTS | Native multi-tenancy, geo-replication and compute/storage separation. **Cost**: two stateful systems (brokers + BookKeeper) and fewer people who know how to operate it |
| **Message queue** | **RabbitMQ 4.3.x** (4.3.0 on 23-Apr-2026; 4.3.4 on 23-Jul-2026) | **MPL 2.0** for the server and its tier-1 *plugins* (*verbatim* from `LICENSE`). In 4.0 **classic mirrored queues were removed**; in 4.3 **Khepri is the only metadata store and Mnesia is gone**. Erlang 27 as a minimum in the 4.3 series. **Careful: community support for the 4.3 series ends on 30-Nov-2026** — this branch's cadence is short and forces an upgrade plan | Default of the queue family. Rich routing and maturity |
| **Lightweight messaging** | **NATS 2.14.4** (30-Jul-2026) | **Apache 2.0** (*verbatim* from `LICENSE`). **Governance resolved**: after Synadia's attempt to relicense under BSL and claim the trademark (Mar-Apr 2025), the agreement with the CNCF (May-2025) **assigned the trademarks to the Linux Foundation** and left repositories and domain under the CNCF, with the core guaranteed under Apache 2.0 | Low latency, minimal footprint, edge/IoT. **JetStream** adds persistence and streams when durability is needed |
| **Provider-managed** | **The right answer more often than is admitted** | Concrete services and limits in the cloud skills | §2.4 |
| **MQTT** (edge/IoT) | Dedicated MQTT broker in front, bridged to the log | Product and version **not verified** in this revision (§8) | When the producer is a field device. **Do not expose the main broker to the devices** |
| **Redis/Valkey as a queue** | **No** by default | Use as a cache belongs to `caching-cdn-standards` | Acceptable only for ephemeral, loss-tolerant work, **declared as such in an ADR**, with its durability and its HA evaluated separately. Never "taking advantage of" the cache instance |

**Status that must be stated**: **ActiveMQ and the classic JMS brokers** remain valid where they
already exist and there is genuine JMS integration; **they are not the choice for something new**
barring a protocol requirement. **ZooKeeper as a Kafka dependency no longer exists** (§3.1): any
guide, image or `docker-compose` that includes it is out of date and is a warning sign about that
source.

### 2.4 Managed versus self-managed

**If you are already in a cloud and have no dedicated platform team, use its managed service.** It is
not laziness: it is not standing up a stateful consensus system that has to be patched, rebalanced
and upgraded. Honest criterion:

| Choose **managed** if | Choose **self-managed** if |
|---|---|
| You have no platform team with on-call | You have a team that already operates stateful systems |
| The volume is moderate and the peak is bounded | The volume is high and sustained: **that is where managed blows up** |
| You are in a single cloud and the exit cost is acceptable | Multi-cloud, on-prem, or data sovereignty |
| You need compliance and certifications already done | You need to tune the engine deeply |

**The real break-even point is about staffing, not the invoice**: managed gets expensive by volume,
self-managed gets expensive by **person-year** (§6.4). And the exit cost of managed is the
**rewriting of producers and consumers** if the protocol is proprietary: **prefer the managed
service that speaks the open project's protocol** (Kafka, AMQP) and record it in the ADR.

## 3. Configuration and operation

### 3.1 Kafka: the real operation

This is what `data-platform-standards` does not cover and what decides whether your cluster holds up.

**KRaft and the end of ZooKeeper**
- **Since Kafka 4.0 only KRaft exists.** ZooKeeper mode was **removed**. Migrating from a cluster
  with ZooKeeper requires going through the **3.9 bridge version** before moving to 4.x: **there is
  no direct jump**, and if you try to upgrade without migrating, it will not start.
- **The controllers are a Raft quorum**: an odd number (**3 in production; 5 only with
  justification**), in different failure domains. Losing the controller quorum **stops metadata
  operations** for the whole cluster.
- **Dedicated controllers versus combined nodes**: combined (`process.roles=broker,controller`)
  only in a lab or small clusters with the risk accepted; **in production, dedicated**.
- **Formatting the storage is an irreversible step** with a cluster identifier: if you format a node
  with the wrong identifier, it will not join. It goes into the provisioning procedure, not into
  anyone's memory.

**Partitions: the decision that is hard to undo**
- **The number of partitions fixes the maximum parallelism of a consumer group.** More consumers
  than partitions = idle consumers.
- **Increasing partitions is easy; decreasing them is not.** There is no reduction operation: it is
  done by creating a new topic and migrating producers and consumers. **And increasing them is not
  free either**: **it breaks the affinity of the key with the partition**, so messages from the same
  entity stop going to the same partition and **historical ordering is lost** (key choice and its
  consequences belong to `streaming-cdc-standards`).
- Sizing rule: **start from the consumption parallelism you need, with reasonable headroom for
  growth, not from a figure copied off a blog.** Over-sizing is not free either: each partition
  costs descriptors, memory, metadata and **recovery time after a node goes down**. Thousands of
  partitions per node is an operational problem, not a virtue.
- **Watch for skew**: a hot key saturates its partition while the rest of the cluster idles.
- **Reassigning partitions between nodes consumes network**: do it with rate limiting (*throttle*)
  or you will degrade production for as long as it lasts.

**Durability: `acks`, replicas and the trade-off with latency**

| Configuration | What it guarantees | Cost |
|---|---|---|
| `acks=0` | Nothing. The producer does not wait | **Silent loss. Vetoed** except for declared disposable telemetry |
| `acks=1` | The leader has it; **if the leader falls before replicating, it is lost** | Lower latency, real loss on failure |
| **`acks=all` + `RF=3` + `min.insync.replicas=2`** | The message is on at least 2 replicas before acknowledgement | **Default for any data that matters.** More write latency |

- **`min.insync.replicas` without `acks=all` does nothing.** It is the most common misconfiguration
  of the product: the guarantee comes from **the two together**.
- **`RF=3` with `min.insync.replicas=2` is the right point**: it tolerates one node down **without
  ceasing to accept writes**. With `RF=3` and `min.insync=3`, a single node down **stops writes**.
- **`unclean.leader.election` disabled**: enabling it means accepting in writing the loss of
  acknowledged data in exchange for availability. It can be a legitimate decision; **never an
  oversight**.
- **Spread across failure domains** (`rack awareness` or equivalent): three replicas in the same
  rack or zone are not three replicas.

**Retention and compaction**
- **Time-based and size-based retention are two limits that act at once**, and **whichever is met
  first wins**. Set **both**: time only, and a traffic spike fills the disk; size only, and you
  cannot promise a reprocessing window.
- **Retention is set per topic, never only globally.** And the global default is the one that fills
  disks in shared clusters.
- **Compaction (`cleanup.policy=compact`)**: keeps **the last value per key**, so current state is
  reconstructible. Use it for **keyed state changes** (reference tables, configuration, per-entity
  state). **Do not use it** for event streams where each occurrence matters in its own right:
  **compaction destroys history** and that loss is unrecoverable.
  Caveats: **it is not immediate** (it depends on the cleaner and the segment thresholds), **it
  requires a non-null key**, and **a deletion is represented by a message with a null value** whose
  handling in the consumer belongs to `streaming-cdc-standards`.
- **Tiered storage** when you want long retention without expensive disk: verify its status in your
  version and **test reading from the cold tier**, which is where the latency and retrieval-cost
  surprises show up.

**Consumer rebalances and their pauses**
- **A rebalance pauses the group's consumption.** With the classic protocol it is a full stop of the
  group; with the new consumer group protocol (available in the 4.x series) the impact is much
  smaller. **Verify which protocol your clients use**, because upgrading the cluster is not enough.
- **Avoidable causes of rebalance**: rolling deployments without stable identity, badly tuned
  session timeouts, and above all **a consumer that takes longer to process a batch than the maximum
  allowed interval** — the cluster considers it dead and triggers a rebalance, which slows things
  down further, which triggers another one. **It is a classic degradation loop**: it is cut by
  lowering the batch size or raising the interval, with judgement.
- **Reduce the impact** with static membership and cooperative rebalancing, and **deploy
  carefully**: every consumer restart is a rebalance.

**The real cost of operating Kafka** — say it before anyone signs:
controllers in quorum, replicas and their rebalancing, disk per topic with retention, replication
network, coordinated rolling upgrades, protocol versions between clients and brokers, authentication
and per-principal ACLs, and **on-call**. **Kafka is not "one more service": it is a platform.** If
nobody is going to devote time to it, it is either managed or it is not Kafka.

### 3.2 RabbitMQ

- **Model**: the producer publishes to an ***exchange***, the ***bindings*** decide which queues it
  enters, and the consumer reads from the queue. **Routing lives in the broker**, which is exactly
  what a log does not give you. Use `direct` for exact routing, `topic` for patterns, `fanout` for
  broadcast; and **declare everything as code** (`rabbitmqadmin` or exported definitions), never by
  hand in the console.
- **Quorum queues by default for anything that matters.** **Classic mirrored queues were removed in
  RabbitMQ 4.0**, after years of deprecation: if a guide or a definitions file mentions them, **it
  is expired**. Classic queues still exist, but **they are no longer replicable**: they are good for
  ephemeral single-node work and little else.
- ***Stream* queues** when what you want is a re-readable log inside RabbitMQ. **Before using them,
  ask whether the case really belongs to the log family** (§2.2): sometimes the answer is that the
  right broker was a different one.
- **Khepri**: in the 4.3 series, **the only metadata store; Mnesia was removed**. Good operational
  consequence: recovery after a network partition becomes uniform (Raft semantics for metadata,
  quorum queues and *streams*). Bad consequence: **it is a stateful change during the upgrade** —
  rehearse it (§4).
- **Confirmations, in both directions, and they are mandatory**:
  - **On the producer side**: *publisher confirms*. **Without them, publishing is fire-and-forget
    and the message is lost on a broker failure**, even though your code sees no error.
  - **On the consumer side**: **manual acknowledgement, after processing**. Automatic
    acknowledgement = silent loss as soon as the process dies halfway.
- **`prefetch` (`basic.qos`) always set, and low.** With no limit, one consumer takes thousands of
  messages into memory, the others are left without work and, if it dies, **all of that goes back to
  the queue at once**. High values only with very small messages and very fast processing, measured.
- **Unacknowledged messages consume broker memory**: a slow consumer with a high `prefetch` is one
  of the usual ways to take a node down. **Watch `messages_unacknowledged`**, not just queue depth.
- **Per-queue limits** (maximum length, message TTL, discard policy) declared as policy. **A queue
  with no limit grows until the broker blocks under memory or disk pressure**, and then *everything*
  stops, not just that queue.

### 3.3 NATS and JetStream

- **The NATS core is not durable**: whatever is published with no active subscriber is lost. It is a
  design, not a defect, and **it is exactly the misunderstanding that causes the incident**.
- **JetStream** adds persistence, streams and durable consumers, with limits-based, interest-based or
  work-queue retention. **If you need durability, you need it explicitly**: enable JetStream, define
  the stream, its storage, its replicas and its retention. None of that comes for free.
- **Stream replicas**: 3 to tolerate failure (Raft). A stream with one replica is a convenience, not
  durability.
- **Right fit**: low latency, small footprint, edge, devices, inter-service communication with
  request/response. **Do not choose it as a drop-in replacement for a high-volume log with massive
  reprocessing without having tested it with your load.**
- **Governance (an adoption fact, not an anecdote)**: the 2025 episode —the attempt to move to BSL
  and to claim the trademark, resolved by assigning the trademarks to the Linux Foundation and
  guaranteeing the core under Apache 2.0— **is the reason NATS remains adoptable**. Verify it is
  still current (§8).

### 3.4 Pulsar and Redpanda: criterion

- **Pulsar** is worth it if you need **real multi-tenancy with per-tenant isolation and quotas,
  built-in geo-replication, or separating compute from storage** to scale them independently.
  **Price**: **you operate two stateful systems** (brokers and BookKeeper), and there are far fewer
  people with experience. If your reason is "it is more modern", the reason is not enough.
- **Redpanda** is worth it if you want **the Kafka API with far fewer pieces** (no JVM, no external
  quorum) and less tuning. **Price**: **it is not open source** — BSL 1.1 with a use grant that
  **excludes offering a streaming or queuing service**, and Enterprise features under a separate
  proprietary licence. **Read it before adopting it if your product is a platform for third
  parties**, because that is where the clause bites. **ADR mandatory** with the licence analysis and
  the exit plan (Kafka API compatibility is what makes it viable: keep it as leverage, do not depend
  on proprietary extensions).

### 3.5 Multi-tenancy and isolation

- **A shared cluster with no quotas is an incident waiting to happen**: an out-of-control producer
  exhausts disk, network or connections and affects everyone. Set **per-client/per-principal quotas**
  (production, consumption and request rates) from the start, not after the first scare.
- **Namespaces and a topic/queue naming convention** with an identifiable owner:
  `domain.entity.event` or equivalent, **decided and written down**. A cluster with names invented by
  each team is impossible to govern and to decommission.
- **Separate by criticality, not by convenience**: the cluster holding up payments does not share
  fate with the experimentation one.

### 3.6 What the broker does not solve on its own (and the part that is its job)

**The patterns —retries, dead-letter queues, poison messages, deduplication and idempotency— belong
to `streaming-cdc-standards`.** What corresponds to this skill is **leaving the broker configured so
they are possible**:

- **Retries**: the broker must allow **redelivery without blocking the partition or the queue** —
  in the queue model, with requeueing and a delivery counter; in the log model, **per-message retry
  does not exist**, so retry is implemented with tiered retry topics or outside the broker. **It is
  a family difference that must be known before choosing** (§2.2).
- **Dead-letter queue**: it is **one more destination that has to be created, sized, retained,
  secured and monitored like any other** (and it contains real data: its own access control and
  retention). The broker does not create it on its own.
- **Poison message**: set **a delivery limit** or your broker's equivalent. A message retried
  endlessly **blocks the partition or saturates the queue**, and stops the whole flow.
- **Deduplication**: **if your broker offers deduplication, know its window and its scope** — it is
  usually bounded in time and per producer, and **it does not replace consumer idempotency**, which
  is the only real defence.
- **Ordering**: the broker guarantees ordering **per partition or per queue without distribution**.
  The moment several consumers share a queue, **ordering is over**. Say it at design time, not at
  debugging time.

## 4. Quality and testing — gates

In increasing order of cost. **The ones marked as a gate break the build or the deployment.**

1. **ADR for §2.1 and §2.2**: why a broker is needed rather than a table with `SKIP LOCKED`, and why
   **that family**. *Design gate.*
2. **Topics, queues, policies, quotas and ACLs as code**, versioned and applied by the pipeline.
   **Nothing created by hand in the production console.** *CI gate.*
3. **No secrets in the configuration or the definitions files**: credentials from the secrets
   manager. *CI gate.*
4. **Validation of critical configuration in CI**: every topic of important data with `RF>=3`,
   `min.insync.replicas=2`, `acks=all` on the producer, **retention declared by time *and* by
   size**, and `unclean.leader.election` disabled. A change that breaks this **breaks the build**.
   *Gate.*
5. **Automatic topic creation forbidden** in production (`auto.create.topics.enable=false`) and its
   queue equivalent: a typo must not create infrastructure. *Gate.*
6. **Integration tests against the real broker in a container**, not against doubles: **the broker's
   behaviour is what is being tested**. Covering edges: **broker unavailable when publishing**,
   **consumer that dies between processing and acknowledging**, **message that exceeds the maximum
   size**, **empty queue/partition**, **delivery limit reached**.
7. **Producer confirmation test**: verify that **a publish without confirmation is not taken as
   good** in the code. It is the most expensive silent failure on the producer side.
8. **Node failure test** with traffic in flight: verify that no acknowledged message is lost and
   measure how long the unavailability lasts. **Before production, not after.**
9. **Major-version upgrade rehearsal** on a mirror, with representative data and clients and a
   **defined rollback plan** (§6.3). Mandatory if there is a metadata store change (Khepri) or a
   quorum mode change.
10. **Restore test** of the broker state and its definitions (§6.2).
11. **Dependencies, images and clients pinned by digest**, with an SBOM (§5). *CI gate.*

## 5. Stack security

- **No broker without authentication. Ever.** It is the recurring finding of the domain: brokers on
  "trusted" internal networks, management ports open, listeners with no authentication "so the
  devices can connect". A broker without authentication is **read and write access to the entire
  business flow** for anyone who can reach the port.
- **Strong, per-principal authentication**: SASL with a modern mechanism or **mTLS**, with a
  per-application identity —**not one credential shared by the whole department**— and rotation.
  Certificate issuance and rotation belong to `cryptography-pki-standards`.
- **Authorisation per topic/queue and per operation**, with **deny by default**. Hard rules:
  **a producer does not need read permission**; a consumer of one topic does not need permission over
  the others; **no application holds administration permission**.
- **TLS in transit always**, including between cluster nodes (replication) and on the management
  plane. "It is an internal network" is not an argument.
- **The console and the management API are first-class attack surface**: behind identity, with
  network-restricted access, and **never exposed to the Internet**. There is a 2026 CVE of stored XSS
  in RabbitMQ's management interface (CVE-2026-44839) precisely there.
- **Mind the clients, not just the server**: **CVE-2026-35554 (CVSS 8.7, published on 7-Apr-2026)
  affects Kafka's Java producer client** —a race condition in the buffer *pool* that can **deliver
  messages to the wrong topic, silently and without error**, with the consequent data exposure to
  unauthorised consumers—. **Fixed in 3.9.2, 4.0.2, 4.1.2 and 4.2.0 or later; on branches 2.8-3.8
  there is no fix**. Corollary: **inventory the client versions, not just the cluster's.**
- **Retention and personal data**: a retained topic is **one more copy of the data**, with its
  classification, its declared retention and its access control; **a deletion at the source does not
  delete the earlier messages**. The policy belongs to `privacy-engineering-standards`; **the
  parameter is set here**.
- **No PII in topic, queue or consumer group names** — they end up in metrics, logs and dashboards.
- **Supply chain**: pin images, operators and client libraries **by digest**; SBOM; a quarantine of
  days before adopting a freshly published version. Precedents verified in the catalogue: Trivy
  (Mar-2026), LiteLLM (Mar-2026), `elementary-data` (Apr-2026) and **Mini Shai-Hulud /
  CVE-2026-45321**, which **forges SLSA level 3 attestations**: **provenance is no longer sufficient
  proof on its own**.
- **Licence and ownership risk as supply security risk**: **IBM completed the purchase of Confluent
  on 17-Mar-2026** (~$11bn, $31/share, wholly owned subsidiary, delisted from Nasdaq). **Kafka is
  unaffected: it belongs to the ASF.** But the **Confluent Community License** —which covers Schema
  Registry, REST Proxy, ksqlDB and several connectors— **is not OSI** and forbids offering those
  components as a competing service. **Record in the ADR which non-OSI-licensed components you
  depend on** and prefer Apache alternatives (a criterion already set in
  `data-platform-standards`).

## 6. Performance and operability

### 6.1 What to monitor (the backend and the dashboards belong to `observability-standards`)

- **Consumer lag**: it is the main signal, but **its interpretation and its alerting belong to
  `streaming-cdc-standards`**. What corresponds here is **that the broker exposes it and that it
  exists**.
- **Cluster health, which is this skill's own business**: **partitions without a leader** (`offline`)
  and **under-replicated partitions**, shrinking of the in-sync replica set, controller quorum
  health, and **leader changes** (a constant trickle is a symptom, not noise).
- **Queues**: depth, **unacknowledged messages**, incoming rate versus outgoing rate (the
  derivative, not the absolute value), and **queues with no consumer** — which is a disk leak in the
  shape of a queue.
- **Resources**: **disk per node and per topic with an exhaustion projection** (the useful alert is
  "N days left", not "85% full"), replication network, file descriptors, connections and memory.
- **Actionable alert with a runbook**: what broke, what depends on it, how it is recovered, how long
  it takes.
- **A broker with an availability commitment requires on-call.** Without on-call, the commitment is a
  documented lie (`sre-practice-standards`).

### 6.2 Backup and recovery

- **A broker's backup is above all the backup of its *configuration*: topic/queue definitions,
  policies, quotas, ACLs and users.** If that is as code (§4.2), you already have it; if not, that is
  the first thing to fix.
- **Restoring a broker's data is different from restoring a database** and you have to decide in
  advance what recovery means: in many cases, the right answer is **rebuilding the cluster and
  replaying from the source**, not restoring messages. **Write it into the DR plan before the
  incident.**
- **The broker log is not a backup** (§7): it has neither the recovery model, nor the verification,
  nor the isolation of one (`backup-recovery-standards`).
- **Geo-replication** (mirroring between clusters, native geo-replication): it is a continuity tool
  **with lag and with pains of its own** —positions that do not translate between clusters,
  replication loops, ordering— and **its promise has to be tested with a real exercise**
  (`bcdr-standards`), not taken for granted because the product advertises it.

### 6.3 Upgrades without stopping traffic

- **Rolling upgrade, node by node**, waiting for replicas to be back in sync **before touching the
  next one**. Skipping that wait is how you lose data while upgrading.
- **Read the full major-version release notes** looking for three things: **removals** (ZooKeeper in
  Kafka 4.0, mirrored queues in RabbitMQ 4.0, Mnesia in RabbitMQ 4.3), **metadata store changes**
  and **minimum base platform version** (Erlang 27 for RabbitMQ 4.3).
- **Check whether there is a mandatory bridge version**: Kafka requires going through **3.9** to
  migrate from ZooKeeper to KRaft before 4.x.
- **Clients and cluster are upgraded separately and in the right order.** An old client with a new
  cluster can work and still leave you without a feature you thought you had (the new consumer group
  protocol, §3.1). **Inventory client versions per application.**
- **Watch the branch's end of support**, which in some products is **short**: RabbitMQ's 4.3 series
  has community support **until 30-Nov-2026**. Plan the next upgrade the day you finish the previous
  one.
- **Never a `.0` in production.** And never a major upgrade without a mirror rehearsal (§4.9).

### 6.4 Capacity and cost

- **Disk, network and retention are the same decision.** The disk needed is, in essence:
  *incoming rate × replication factor × retention window*, with headroom. **If the number does not
  fit, what gets adjusted is the retention, not the budget.** And **replication also multiplies
  network traffic**, which is what almost nobody sizes until it saturates.
- **Leave real disk headroom**: a broker with a full disk **does not degrade, it stops**, and
  recovering it with the disk at 100% is an unpleasant hot operation. Alert on days remaining.
- **The cost of self-managed is measured in person-years**, not in instances: provisioning, patching,
  upgrades, rebalances, on-call and training. **The cost of managed is measured in volume** and grows
  with it, plus cross-zone traffic, which surprises everyone.
- **The real break-even point**: while the volume is moderate, **managed almost always wins** because
  the staff cost is higher than the bill. Beyond a high, sustained volume, self-managed starts to pay
  off **if and only if you already have the team** — not if it has to be created.
- **Retire what is dead**: a topic or queue with no traffic and no consumers for a quarter is flagged
  and retired. Silent accumulation is what fills disks and confuses whoever arrives later.

## 7. Sustainability and prohibitions

- **Cadence**: review **every quarter** the version, licence **and ownership** of the broker **and of
  the clients**. This sector changed hands and licences in 2025-2026 (IBM/Confluent; the BSL attempt
  in NATS; Redpanda under BSL from the start).
- **ADR mandatory** for: introducing a broker (versus the table of §2.1), **choosing a family**
  (log / queue / lightweight), choosing managed versus self-managed, adopting a product with a
  non-OSI licence, setting a topic's retention, and **changing the number of partitions of a keyed
  topic**.
- **Capacity document** with the calculation of §6.4 and the projected disk exhaustion point.

**FORBIDDEN**
- ❌ Deploying a broker without having ruled out in writing the table with `SKIP LOCKED` and the call
  with retries.
- ❌ Choosing a family by fashion: **a log for a work queue**, or **a queue for a stream that will
  have to be re-read**.
- ❌ `acks=0` for data that matters; **`min.insync.replicas` without `acks=all`** (guarantees
  nothing).
- ❌ `RF=1` in production; three replicas in the same failure domain.
- ❌ Unclean leader election enabled without a written decision accepting the loss.
- ❌ A topic with no retention declared **by time and by size**; infinite retention "just in case".
- ❌ **Compaction on a stream where every event matters in its own right** (it destroys history).
- ❌ Automatic topic creation enabled in production.
- ❌ A queue with no length limit and no discard policy.
- ❌ Publishing without producer confirmation; acknowledging consumption automatically or before
  processing.
- ❌ A consumer without a bounded `prefetch`; ignoring unacknowledged messages in monitoring.
- ❌ Retry with no delivery limit: a poison message blocks the partition or the queue.
- ❌ **A broker without authentication**, or with a credential shared by several applications.
- ❌ A management console or API exposed to the Internet, or with no identity in front.
- ❌ Optional TLS "because it is an internal network"; inter-node replication in the clear.
- ❌ Administration permissions for an application; a producer with read permission on the topic.
- ❌ A shared cluster with no per-principal quotas; mixing payments and experimentation in the same
  cluster.
- ❌ Topics, queues or ACLs created by hand in the production console.
- ❌ **Using the broker as a database or as a queryable store** (state lives in a real store; for
  time series, see `timeseries-db-standards`).
- ❌ **Using the broker log as a backup.**
- ❌ Doing a major-version upgrade without a mirror rehearsal, without a rollback plan or skipping the
  mandatory bridge version.
- ❌ Inventorying only the cluster version and not the clients' (CVE-2026-35554).
- ❌ Following any guide, image or `compose` that deploys Kafka with ZooKeeper.
- ❌ Configuring classic mirrored queues in RabbitMQ (**removed in 4.0**).
- ❌ Assuming durability in the NATS core without JetStream, or a stream with a single replica.
- ❌ Adopting a product with a non-OSI licence without an ADR and without reading the use clause.
- ❌ PII in topic, queue or consumer group names.
- ❌ Stating versions, licences or ownership of a broker from memory (§8).

## 8. Mandatory web verification

The data in §2, §3 and §5 are from **August 2026**, taken from `api.github.com` and the ASF
distribution site (versions and dates) and from the raw licence files (licences).
Before committing to anything in a deliverable, verify:

1. **Kafka**: the current branch (**4.3.1** on the distribution site, alongside 4.2.1 and 4.1.2;
   **Apache 2.0**, ASF) and that **KRaft is still the only mode** since 4.0 (18-Mar-2025), with
   **3.9 as the bridge version** from ZooKeeper. Also verify the status of the **new consumer group
   protocol** and of **tiered storage** in your specific version.
2. **Ownership and licences**: **IBM completed the acquisition of Confluent on 17-Mar-2026** (~$11bn,
   $31/share, wholly owned subsidiary, delisted from Nasdaq). Check the **current status of the
   Confluent Community License** (non-OSI) and whether the pricing or support model has changed under
   IBM.
3. **Redpanda**: version (**26.2.1**, 28-Jul-2026) and **the exact BSL 1.1 terms** verified
   *verbatim* in `licenses/bsl.md` —an additional grant excluding offering a *"Streaming or Queuing
   Service"*, **Change Date 4 years from each release**, *Change License* Apache 2.0— plus the
   **Redpanda Community License Agreement** (`licenses/rcl.md`) governing Community and Enterprise.
4. **Pulsar**: **4.2.4** (3-Aug-2026), LTS branch **4.0.x** (4.0.13 on 3-Aug-2026) and **5.0.0-M1**
   (Jun-2026). Apache 2.0, ASF. Real cadence: live project.
5. **RabbitMQ**: **4.3.4** (23-Jul-2026; 4.3.0 on 23-Apr-2026), **MPL 2.0** (*verbatim* from
   `LICENSE`), **classic mirrored queues removed in 4.0**, **Khepri the only metadata store and
   Mnesia removed in 4.3**, Erlang 27 minimum, and **end of community support for the 4.3 series on
   30-Nov-2026**. **Confirm that date and the next series' before planning.**
6. **NATS**: **2.14.4** (30-Jul-2026), **Apache 2.0** (*verbatim*), and that the CNCF-Synadia
   agreement of May-2025 is still in force (trademarks assigned to the Linux Foundation, repositories
   and domain under the CNCF, core under Apache 2.0). **It is an adoption fact: re-verify it.**
7. **CVEs**: **CVE-2026-35554** in `kafka-clients` (CVSS 8.7, 7-Apr-2026; fixed in 3.9.2, 4.0.2,
   4.1.2, 4.2.0+; **no fix on branches 2.8-3.8**) and **CVE-2026-44839** (stored XSS in RabbitMQ's
   management interface). Review the project's official CVE list and your clients', and the evolution
   of **Mini Shai-Hulud (CVE-2026-45321)** in the supply chain.
8. **Managed services**: limits, quotas, pricing model and **cross-zone traffic cost** of your
   cloud's service, and whether it speaks the open project's protocol or a proprietary one.

**Declared gaps in this revision** (do not fill from memory):
- **Confluent Community License under IBM**: the transaction (17-Mar-2026) and its financial terms
  are verified; **not verified** is any change to the licence, the price or the support after the
  close. **Do not assert anything about its future.**
- **Redpanda**: the BSL text and the existence of the RCL are verified; **no numerical cap** (of
  cores, nodes or volume) for the free edition has been verified. If you need a concrete limit, read
  it in the product documentation.
- **QuestDB/others do not apply here**; on the other hand, **the recommended MQTT broker (Mosquitto,
  EMQX, HiveMQ, NanoMQ) has not been verified** in version, licence or status. Do not cite any of
  them as a default.
- **ActiveMQ / Artemis**: version, licence and project status **not verified**.
- **Kafka tiered storage**: **not verified** as to its maturity status or its exact availability by
  version and by distribution.
- **New consumer group protocol (next-generation cooperative rebalance)**: verified that it exists in
  the 4.x line; **not verified** in which exact version it became generally available or which
  minimum client versions support it.
- **Managed versus self-managed cost figures**: **none verified**. All the public comparisons are
  published by vendors with a stake in the answer. Work it out with your prices and your staff cost.
- **Performance comparisons between brokers**: published by the manufacturers themselves
  (Redpanda-Kafka is the obvious case). Treat them as marketing, not as data.
- **Pulsar, NATS and Redpanda CVEs**: **not reviewed** one by one in this revision.

If the web contradicts this document, **the web wins** — flag the discrepancy.
