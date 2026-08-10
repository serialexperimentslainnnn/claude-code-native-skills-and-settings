---
name: ai-agents-standards
description: Autonomous agent engineering, provider-agnostic. Use when choosing between an autonomous agent loop and a deterministic workflow, designing an agent's tool surface and tool descriptions, bounding the agent loop (max iterations, token and wall-clock budgets, stop criteria, unproductive-loop detection), compacting or pruning stale tool results and file-backed agent memory, orchestrating coordinator/worker subagent fan-out, building on LangGraph, CrewAI, OpenAI Agents SDK, Pydantic AI, Google ADK or Microsoft Agent Framework, human approval gates for irreversible tool calls, agent sandboxing and egress containment, end-to-end agent success rate and per-task cost tracing, or the lethal trifecta and the OWASP ASI01-ASI10 agentic risks.
---

# Autonomous agent standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **deciding on, designing, bounding, securing, evaluating and operating an autonomous
agent**: a system where a model chooses in a loop which tools to invoke until it considers the task
finished. Covers the prior question (do you need an agent?), the simplicity ladder,
the design of the tool surface, loop control, context management in
long runs, multi-agent, security, evaluation and operation. **Provider-agnostic**:
patterns, criteria and governance.

Triggers: "autonomous agent", "agentic loop", `while stop_reason == tool_use` loop,
`max_iterations`/`max_turns`/`recursion_limit`, token or time budget per task,
compaction and pruning of tool results, persistent agent memory,
coordinator and subagents, human approval of irreversible actions, agent execution
sandbox, `LangGraph`/`create_agent`/`StateGraph`, `CrewAI`, `OpenAI Agents SDK`,
`Pydantic AI`, `Google ADK`, `Microsoft Agent Framework`, "lethal trifecta", "indirect prompt
injection", `OWASP ASI01`–`ASI10`, trace and cost per task.

**Not applicable**: see
`claude-api` (**the concrete implementation with Anthropic**: the SDK's *tool runner* and its
per-turn *hooks*, Managed Agents and their hosted loop, `mcp_servers` + `mcp_toolset`, Agent
Skills, model IDs, `effort`, `task_budget`, API compaction and context editing,
prompt cache, the Claude Agent SDK — **all of that is theirs**; here you get the agnostic criteria:
when an agent, how to design the tool surface, how to bound the loop and how to
secure it. If the task names Claude/Anthropic or asks for concrete code, it is theirs);
`mcp-standards` (the MCP protocol — primitives, transports, authorization,
design and security of a server. **MCP is *one* mechanism for giving tools to an agent,
not the only one**: a local function, an HTTP API, a subprocess and the provider's SDK are just as valid, and
an MCP server is consumed from many hosts that are not your own agents. The boundary: if
you decide **what the server exposes and how it is authorized**, it is theirs; if you decide **how the agent
chooses, iterates and stops**, it is this one);
`claude-code-skills-standards` (how a Claude Code skill is written: it is a **context**
format for an agent. A skill injects instructions; a tool executes. Do not
confuse «giving the agent criteria» with «giving it capability»);
`llm-app-engineering-standards` (**key boundary**: the single-turn or
*deterministic pipeline* LLM app: prompting and versioned templates, structured output and
its validation, model choice and routing, context window and prefix cache,
streaming and cancellation, retries and spend limits, testing the non-deterministic. **The
autonomous loop belongs to this skill**; as soon as the model decides *how many* steps to take and *which*,
you cross the line. The shared vocabulary —`prompt injection`, `context`, `llm`— is inherent
to the domain, not a claim on the same work: prompt injection here is treated as
**hijacking the goal of an agent with tools and permissions** (lethal trifecta, ASI01),
there as **untrusted input to a call**);
`rag-standards` (chunking, embeddings, hybrid retrieval, reranking
— here retrieval appears only as *one more tool* of the agent),
`llm-evaluation-standards` (evaluation methodology, LLM-as-judge,
datasets — here only which agent metrics matter and why demos deceive),
`mlsecops-standards` / `ai-governance-standards` / `mlops-standards` / `local-inference-standards`
/ `gpu-computing-standards`.
Also: `appsec-standards` (STRIDE and classic vulnerability classes — prompt
injection is **not** one of them and is not mitigated with the same techniques),
`identity-access-management-standards` (agent identity as a principal, short-lived
tokens, JIT elevation), `secrets-management-standards` (custody of the credentials it uses),
`container-runtime-security-standards` (sandbox for what the agent executes),
`rpa-workflow-automation-standards` (**an agent that clicks buttons is RPA**: it inherits from there the
robot's own identity, the credential vault, the work queue, idempotency under
partial failure and the stop — it is not redesigned here),
`firewall-policy-standards` (agent egress: the communication leg of the lethal trifecta),
`kubernetes-standards`, `observability-standards` (the three pillars and OpenTelemetry),
`sre-practice-standards` (SLO, error budget, operation), `detection-engineering-standards`
(detections over the agent's trace), `incident-response-forensics-standards` (response
when the agent does damage), `offensive-security-standards` (**red teaming of agents: the
authorized exercise with RoE is theirs**), `vulnerability-management-standards`,
`privacy-engineering-standards`, `grc-compliance-standards` (NIST AI RMF, ISO/IEC 42001, EU AI
Act), `python-standards`/`typescript-standards`, `cicd-standards`, `api-design-standards`,
`ai-agent-workflow-standards` (**the strongest collision pair of this skill, explicit
arbitration**: **building an agentic system belongs here** —loop, tools, memory, context,
evaluation, deployment and operation of the agent as a product—; **working with coding agents
in an engineering team is theirs** —which task is given to an agent and which is not, repository
instruction files, scope of permissions and credentials on the workstation and in CI, review
of the generated diff, and who answers for the change—. Short rule: **if the agent is the product, it belongs
here; if the agent is the tool with which the product is built, it is theirs**).

## 2. Default decisions

> Verify framework versions and status on the web before pinning them (§8). This
> ecosystem moved more in the first half of 2026 than in all of 2025.

### 2.1 The prior question: do you need an agent?

**It is the most important decision in this document and almost always the answer is no.** Four
criteria; **if one fails, step down a rung**:

| Criteria | Honest question | Fails if… |
|---|---|---|
| **Real complexity** | Are the steps *impossible to specify in advance* because they depend on what is found along the way? | You can draw the flowchart. Then implement it: it is a workflow |
| **Value** | Does the outcome justify cost **and latency**? A loop is N model calls with growing context | The saving does not cover the spend, or the user expects an answer in seconds |
| **Feasibility** | Does the model do this task well *today*, measured, not assumed? | You have not measured it. Measure it first |
| **Cost of a recoverable error** | If it gets it wrong, is it detected and reverted? (tests, review, rollback, transaction) | The error is silent or irreversible. **Without recovery there is no autonomy**: there is human approval or there is no agent |

### 2.2 The simplicity ladder

Step up a rung only when the previous one proves insufficient. **Each rung adds cost,
latency, non-determinism and attack surface.**

| Rung | What it is | When |
|---|---|---|
| **1. One call** | Prompt → response | Classify, extract, summarise, rewrite, answer |
| **2. Deterministic chain** | Several calls chained with **your** logic; the model does not choose the flow | Known pipeline: extract → validate → transform. Debuggable, cacheable, testable |
| **3. Workflow with tools** | The model chooses *inside* a graph you control: routing, branches, bounded number of steps | Most of what is called an "agent" in production **should stay here** |
| **4. Agent** | Autonomous loop: the model decides how many steps, which ones and when to stop | Only when 1–3 are not enough and the four criteria in §2.1 are met |

**Rule**: the autonomous loop is the **expensive and non-deterministic** option. It is chosen when the
alternatives are not enough, never by default nor by fashion. A workflow with a good graph wins
almost always on cost, latency, debuggability and auditability.

### 2.3 Frameworks (August 2026)

| Framework | Status | Criteria |
|---|---|---|
| **LangGraph** | 1.x stable (1.0 in Oct 2025; 1.1 in Mar 2026). Python ≥3.10 | Default for stateful workflows in production: explicit graph, durable execution, checkpointing and *time travel*. It is the one that best fits auditing and rollback |
| **Pydantic AI** | v2 (Jun 2026) | Best option when the priority is typing and validation with lightweight orchestration. Pydantic is already the schema layer inside several of the others |
| **OpenAI Agents SDK** | Active, minimalist | Central abstraction: *handoff* between agents. **Coupled to OpenAI models** |
| **Google ADK** | 2.0 (Python, Go, TypeScript) | If the stack is Google Cloud/Vertex |
| **Microsoft Agent Framework** | 1.0 GA (Apr 2026), Python and .NET | Convergence of Semantic Kernel + AutoGen. If the stack is Azure |
| **CrewAI** | Active | Fast prototyping with role-based *crews*. Low curve; worse latency profile. Not my default for production |
| **AutoGen / AG2** | **Maintenance mode** | ❌ Do not use in new projects. Existing ones: migrate (LangGraph is the closest architectural fit) |
| **Semantic Kernel** | Supported for what exists | New agent work → Microsoft Agent Framework |
| Provider harness | Varies | A "batteries included" harness from the model provider (built-in tools, loop, permissions) is the fastest route when you are already coupled to that provider. **Cost**: coupling. See the provider's skill |
| **No framework** | Always valid | A 40-line `while` loop with your tools is debuggable and dependency-free. Start here to understand the problem before choosing a framework |

**Mandatory scepticism**: choosing by GitHub stars or by marketing is the
recurring mistake. The deciding axes are **measured cost, reliability, and observability**.

### 2.4 Interoperability between agents

**A2A** (Agent2Agent) has been under the Linux Foundation since 2025, with stable v1.0, SDKs in
several languages and adoption in the three big clouds. It is complementary to MCP, not an
alternative: **A2A between agents from different platforms; MCP for an agent's access to
tools**. Adopt it only if the real problem is cooperation between agents from *different
organisations or platforms*; for your own subagents it is free complexity.

## 3. Structure and conventions

### 3.1 Design of the tool surface

This is where an agent's quality is won or lost, more than in the prompt.

**What is exposed as a tool and what is not.** A **dedicated** tool gives the *harness* a
**typed** interception point: it can ask for approval, audit the concrete argument,
render it in the UI, decide whether it is parallelisable and reject it by policy. A generic
`bash` gives the harness **an opaque string, identical for every action**: it does not distinguish a
`grep` (parallelisable, harmless) from a `git push` (irreversible). Criteria:

| Promote to a dedicated tool when… | Reason |
|---|---|
| The action is **hard to revert** (send mail, delete, pay, deploy) | It is the point where human approval goes |
| You need to **audit the argument**, not the command | «sent mail to X» is auditable; `curl -X POST ...` is not |
| You need **your own rendering** (question to the user, diff, confirmation) | The harness needs to block the loop and show UI |
| You want to **parallelise** reads safely | You can only mark as parallelisable what you recognise |
| There is an **invariant to enforce** (do not write a file changed since the last read) | `bash` cannot enforce it |

Practical rule: **start with `bash` for breadth, promote to a dedicated tool whatever you
need to control.** And if your security policy demands control, `bash` is not an option:
grant it or do not grant it, but do not pretend to govern it with regular expressions over the
string.

**Descriptions that say *when*.** The model chooses by reading the description. One that only
says *what it does* produces under- or over-invocation depending on the model. Write the trigger
condition, and the non-trigger one: «Use it when… Do not use it for… — for that, `otra_tool`.»

**Number of tools and their cost.** Each definition takes up context on **every turn** and
competes for the model's attention. Ten well-named tools beat fifty.
When the catalogue is unavoidably large, load on demand (tool search /
lazy loading) instead of injecting everything — and measure the impact on the prompt cache, because
changing the tool set mid-conversation usually invalidates it.

**Strict schemas**: `additionalProperties: false`, explicit `required`, `enum` where the
domain is closed, precise types. The model fills in whatever the schema allows.

**Bounded results**: pagination, announced truncation, field projection. A 200 KB result
poisons the context and displaces what matters.

**Actionable errors**: the error message is a prompt. «The file does not exist; use `glob`
to locate it» produces recovery; a stack trace produces a loop.

### 3.2 The loop: control and stopping

An agent without limits is an incident waiting its turn. **Every loop carries the five things**:

1. **Maximum iterations**, chosen and justified. Reaching it is not a system error: it is
   an end condition that must be **reported as a partial result**, not swallowed.
2. **Token budget** per task (accumulated input + output, not per call), with a hard
   cut-off. Some providers expose a budget that the model itself *sees* and with which it
   self-regulates — better than the blind cut-off, but **it does not replace the hard limit**.
3. **Wall-clock budget**, independent of the token one: a slow model with
   slow tools burns minutes without burning tokens.
4. **Explicit stop criteria**: what "finished" means and who decides it. If the model decides it
   alone, you have to accept that sometimes it will declare itself finished without being so. A verifiable
   criterion —tests pass, schema validates, rubric met— is infinitely better than
   "whenever the model says so".
5. **Unproductive-loop detection**: repetition of the same call with the same
   arguments, alternation between two states, N iterations with no observable state change,
   growing tool error rate. On detecting it: **do not retry more of the same** —
   break the pattern (change strategy, ask the human for help, abort with a partial).

**When the agent gets stuck**: the typical failure is not that it stops, it is that it insists. Recovery
ladder: (a) return a more informative tool error; (b) inject a
replanning instruction; (c) restart with compacted context and the goal reaffirmed;
(d) escalate to the human with the work done so far. Never (e) raise `max_iterations`.

### 3.3 Context in long runs

The loop accumulates: every call drags the whole history along. Three mechanisms, with their trade-off:

| Mechanism | What it does | Trade-off |
|---|---|---|
| **Pruning old results** | Removes tool results that are no longer relevant | Cheap and deterministic. **You lose the detail**: if the agent needs it later, it calls again (cost) or hallucinates (worse) |
| **Compaction / summary** | Replaces history with a summary | Preserves coherence with far fewer tokens. **It is a generated summary**: it loses precision and can introduce error. Never compact decisions or hard constraints — re-compress them verbatim |
| **Persistent memory** (file or store) | The agent writes down what it learned and re-reads it | Survives the session and compaction; it is the only form of learning between runs. **Attack surface**: memory is a persistent injection channel (ASI06) — see §5 |

Rules: **never put secrets in memory** (they are replayed in every future session); make the
memory **readable and auditable** by a human; give it a retention policy; and always anchor the
original goal outside what can be compacted — goal drift in long runs almost always comes
from having summarised the goal.

### 3.4 Multi-agent

**When it pays off**: *fan-out* over **genuinely independent and voluminous** work —
exploring N unrelated files, evaluating N candidates, running N isolated checks.
The benefit is isolated context per worker (each one explores without contaminating the rest) and
real parallelism.

**When it is pure cost**: **each subagent re-establishes context from scratch** — it receives the
instruction, explores, reports; and the coordinator reads the report again. For work that
the coordinator would close in three calls, a subagent multiplies cost and latency without gaining
anything. **Splitting a small task into subagents is the antipattern**, and it is especially
tempting because it *looks* sophisticated.

Default pattern: **coordinator + workers**, a single level of delegation. The
coordinator holds the goal and composes; the workers do not delegate in turn (nested
delegation makes the cost and the trace incomprehensible). Rules:

- **Complete briefing the first time**: a badly instructed worker costs two rounds.
- **Hard ceiling on concurrent subagents**, decided and configurable.
- **Do not re-derive**: if you delegated, accept the result or discard it; redoing it yourself is paying twice.
- **Do not delegate verification** by default: it normally belongs to the main loop.
- **Asynchronous** communication when the framework allows it: blocking the coordinator on the
  slowest worker throws parallelism out of the window.

## 4. Gates

In order of increasing cost. **[BLOCKS]** = breaks the build or the deployment.

1. **[BLOCKS] Limits present**: test that verifies that `max_iterations`, a token budget
   and a wall-clock timeout exist, and that reaching them produces a reported partial result, not
   a swallowed exception nor an infinite loop.
2. **[BLOCKS] Strict schemas**: every tool with `additionalProperties: false` and
   `required`.
3. **[BLOCKS] Approval gate**: test that proves that **no** action marked as
   irreversible is executed without the configured approval. It is the gate that avoids the headline.
4. **[BLOCKS] Verified least privilege**: test confirming that the agent's credential
   **cannot** do what it must not (not that "it will not").
5. **[BLOCKS] Complete trace**: every run emits a trace with every tool call,
   arguments (sensitive ones redacted), result, latency and tokens. Without a trace there is no
   production — you cannot debug or audit a non-deterministic system without it.
6. **[BLOCKS] Idempotency of actions with effects**: double-execution test with the same
   key, verifying that the effect happens **once**.
7. **End-to-end evaluation** over a fixed set of tasks: **success rate of the
   complete task**, not step metrics. Defined threshold; a regression breaks the build.
8. **Cost and latency per task** measured on every run of the evaluation, with a threshold. A
   quality improvement that triples the cost is a decision, not an accident.
9. **Failure cases in the evaluation set**: a tool that fails, an empty result,
   ambiguous input, content with an embedded instruction (check that it does **not** obey it),
   an impossible goal (check that it stops and says so).
10. **Unproductive-loop test**: a scenario built to get it stuck; verify detection
    and breaking of the pattern.
11. **Review of the tool surface** in every PR that touches it: does this tool
    need approval? does its description say when to use it? is its output bounded?

## 5. Security — the critical section

**Premise: the agent acts with the permissions you give it.** There is no "the agent would not do that": if
the credential can, the agent can, and a text on a web page is enough for it to try.

### 5.1 The lethal trifecta

Formulation by **Simon Willison** (*"The lethal trifecta for AI agents: private data,
untrusted content, and external communication"*, 16-jun-2025). An agent is exploitable for
exfiltration when it combines **all three**:

1. **Access to private data** — which is usually exactly what you built it for.
2. **Exposure to untrusted content** — any text or image an attacker controls
   and that reaches the model: a web page, a ticket, an email, an issue, a PDF, a
   dependency's README, a tool's output.
3. **Ability to communicate outward** — in a way that data can be taken out.

**Breaking one of the three is enough**, and that is the real mitigation, because **there is no known reliable
way to prevent it** on the model's side. The *guardrail* products that promise to detect
injection are probabilistic mitigation: useful as a layer, **unacceptable as a sole
control**.

In practice, the leg you can break is almost always the **third**: without arbitrary
egress there is no exfiltration, even if the agent is fooled. So containment of an
agent is, to a large degree, a **network and permissions** problem, not a prompting one.

### 5.2 Indirect prompt injection

**Every tool input is attacker input.** The model does not distinguish instruction from
data: it processes both on the same channel. It is LLM01 of the OWASP Top 10 for LLM applications (2025
edition, the one in force) and ASI01 (*Agent Goal Hijack*) of the agentic Top 10. Design consequences:

- **No tool result is trustworthy.** Treat it as unauthenticated user
  input, and **never** as an instruction with authority.
- **Separate channels**: the operator's instruction must travel over the privileged channel the
  platform offers, not embedded as text in a turn that any content could
  imitate.
- **Authority does not travel with the text**: content saying «the administrator authorises» does not
  authorise anything. Authorisation is checked outside the model.
- **Multimodal counts**: instructions in images and documents are the same problem.
- **Memory is injection persistence** (ASI06): what was written poisoned will be
  re-read in every future session. Audit what goes into memory.

### 5.3 Containment

- **Least privilege, for real**: a credential per agent and per task, minimum scope, short
  life, revocable. The agent's own identity (do not reuse a human's) so that
  auditing distinguishes who did what. No administrator tokens «because it is simpler».
- **Human approval for the irreversible.** The criterion is not "sensitive": it is
  **reversibility**. Sending a message, paying, deleting, deploying, modifying production, talking
  to a third party. The approval has to be **informed** —show the action and the exact
  argument, untruncated— or it is theatre. And it has to be **per action**, not an «allow everything» at
  startup; a user who approves 200 times a day is not approving, they are clicking.
- **Sandboxing** of what the agent executes: unprivileged container, non-root, read-only
  FS except a working directory, trimmed capabilities, no network access except
  what is listed. See `container-runtime-security-standards`.
- **Egress allow-list** with default-deny. It is the most practical leg of the trifecta and the one that
  blocks the side channel. See `firewall-policy-standards`.
- **Side-channel exfiltration**: the data does not always leave via an obvious HTTP request.
  It leaves in an image URL the client renders, in a parameter of a link the
  user will click, in a branch name, in a DNS lookup, in a commit. Treat the
  **rendering of the agent's output** as surface: do not automatically load remote resources
  from content the agent produced out of private data.
- **Audit of every action**, not of every response: an immutable log of which tool was
  invoked, with which arguments, with which identity, with which result, and whether there was human
  approval and from whom. It is what you will need on incident day.
- **Isolate by trust level**: do not mix in the same session tools over sensitive
  data with tools that ingest third-party content. If they have to coexist,
  break the third leg.

### 5.4 Frame of reference: OWASP Top 10 for agentic applications (2026)

Published on **9-dic-2025** by the OWASP GenAI Security Project (prefix **ASI**, *Agentic
Security Initiative*; v2.01 in Jun 2026). It **extends, does not replace**, the Top 10 for LLM
applications (the **2025** edition in force; there is no 2026 revision of that list): an agent is
also an LLM application and inherits its risks.

| ID | Risk |
|---|---|
| ASI01 | Agent Goal Hijack |
| ASI02 | Tool Misuse & Exploitation |
| ASI03 | Identity & Privilege Abuse |
| ASI04 | Agentic Supply Chain (tools, plugins, registries, MCP servers) |
| ASI05 | Unexpected Code Execution (RCE) |
| ASI06 | Memory & Context Poisoning |
| ASI07 | Insecure Inter-Agent Communication |
| ASI08 | Cascading Failures |
| ASI09 | Human-Agent Trust Exploitation |
| ASI10 | Rogue Agents |

Use: **as coverage, not as a compliance checklist**. Map your design against the ten and
justify the ones that do not apply. ASI04 and ASI07 are the most sensitive to the choice of framework
and of third-party servers.

**Posture**: defensive and authorized. *Red teaming* of agents is valuable and belongs to
`offensive-security-standards`, with scope and permission in writing.

## 6. Evaluation, observability and operation

### 6.1 Evaluation

- **The demo deceives, and it deceives systematically.** A trace that goes well says nothing: the
  system is stochastic, you chose the task, and you watched it finish. The only signal is
  **N runs over a fixed set of tasks, measuring end-to-end success
  rate**. Run each task several times: the variance between identical runs *is* the
  most important datum you are going to get.
- **End-to-end success > step metrics.** «It chose the right tool 94 %
  of the time» is compatible with failing the complete task 40 % of the time (errors compound
  along the loop). Measure the outcome that matters to the user, with a **programmatic**
  verifier whenever possible.
- **Measure cost and latency alongside quality, not afterwards.** Without the three together there is no decision:
  any improvement can be bought with tokens.
- **Failure cases in the set**: tool failure, ambiguous input, impossible
  goal, content with an embedded instruction.
- **Anchor the evaluation before touching the prompt.** Without a baseline, every prompt iteration is
  superstition.

### 6.2 Observability

- **Complete trace per run** as a first-class artifact: call tree
  (subagents included), arguments, results, latencies, tokens, stop decisions.
  OpenTelemetry with propagated context; see `observability-standards`.
- **Minimum metrics**: success rate, tokens and cost per task, iterations per task
  (distribution, not mean), error rate per tool, human intervention rate,
  p95 latency.
- **Actionable alarm signals**: iterations per task rising, intervention rate
  rising, cost per task rising with flat success. All three mean real degradation,
  and none appears in a unit test.
- **A model change or model version change is a behaviour change**: re-evaluate
  before promoting it. What was a good prompt for one model may be too
  prescriptive for the next.

### 6.3 Operation

- **Deployment** of the agent like any service: immutable artifact, promotion of the same
  artifact, canary, tested rollback. Pin the **model version** and treat it as a
  dependency: an implicit `latest` is ungoverned *drift*.
- **Retries**: distinguish a transport failure (retryable with backoff+jitter) from a failure of
  the task (not blindly retryable). Retrying a whole loop from scratch is expensive and can
  duplicate effects already applied.
- **Idempotency of the agent's actions**: an idempotency key on every action with an
  effect. **It is not optional**, because the agent retries on its own, the user retries,
  and the loop's retry goes through there again.
- **Failure halfway through a sequence with effects already applied** — the hard case. Design in this
  order of preference:
  1. **Avoid it**: group the effects into a single transactional action where the target
     system allows it.
  2. **Make it resumable**: persist the loop state (checkpointing) with what has been done, to
     resume without repeating. It is the main reason to choose a framework with durable
     execution.
  3. **Compensate it**: an explicit inverse action for each effect (saga pattern), logged.
  4. **Escalate it**: if you cannot revert, stop and hand the human the exact state — what was
     applied, what was not, and what is left inconsistent. **Never leave the system half-done silently.**
- **Runbook** for the agent: how to stop it hot, how to revoke its credentials, how to
  find everything it did in a time window, who the owner is. An agent without a documented *kill
  switch* should not be in production.

## 7. Sustainability and prohibitions

- **Quarterly review cadence**: models, frameworks and security frameworks move
  every week. What requires an agent today may be solved tomorrow by a single call.
- **Step down a rung when you can**: if model capabilities or a product change
  allow replacing the loop with a workflow, do it. Stepping down a rung is an improvement, not a
  regression.
- **Conscious debt**: if you grant a broad permission or skip an approval for deadline reasons,
  log it with the reason and a review date.

**FORBIDDEN**
- ❌ Building an agent when a call, a chain or a workflow is enough — the most expensive and most common failure.
- ❌ A loop without a maximum number of iterations, without a token budget and without a wall-clock timeout.
- ❌ Raising `max_iterations` as the answer to an agent that gets stuck.
- ❌ Autonomy over irreversible actions without informed and **per-action** human approval.
- ❌ Approval that truncates the action or the argument: it is security theatre.
- ❌ Giving the agent credentials broader than its task, or reusing a human's identity.
- ❌ Trusting a tool's result as if it were an instruction with authority.
- ❌ Combining private data + untrusted content + arbitrary egress without breaking a leg.
- ❌ Relying on injection-detection *guardrails* as the sole control.
- ❌ Executing agent-generated code without a sandbox.
- ❌ Secrets in the prompt, in persistent memory or in logged tool arguments without redaction.
- ❌ Actions with effects without an idempotency key.
- ❌ Running in production without a complete trace per run.
- ❌ Declaring that it works based on a demo or on step metrics.
- ❌ A generic `bash` when the policy requires intercepting concrete actions.
- ❌ Tool descriptions that do not say **when** to invoke it.
- ❌ Tools with unbounded output.
- ❌ Splitting a small task among subagents; nested delegation of more than one level.
- ❌ Compacting the goal or the hard constraints.
- ❌ AutoGen/AG2 in new projects (maintenance mode).
- ❌ Choosing a framework by GitHub stars.
- ❌ An agent in production without a *kill switch* or a revocation runbook.

## 8. Mandatory web verification

Before pinning a version, feature name or status claim:

1. **Status and version of the frameworks**: LangGraph, Pydantic AI, OpenAI Agents SDK, Google
   ADK, Microsoft Agent Framework, CrewAI. Confirm active maintenance and *breaking changes*;
   AutoGen/AG2 and Semantic Kernel are in maintenance — verify whether they have been archived.
2. **Capabilities and limits of the model** you are going to use: context window, cost, parallel
   tool support, reasoning behaviour. **Never from memory** — the model
   line changes every few months. If it is Claude/Anthropic, the source is the `claude-api` skill.
3. **OWASP Top 10 for agentic applications**: edition in force and **exact wording** of
   ASI01–ASI10; secondary sources vary in the title of several entries (ASI03, ASI04,
   ASI08). Check against the PDF at `genai.owasp.org`.
4. **OWASP Top 10 for LLM applications**: the **2025** edition is the one in force as of August 2026 and there is
   an update process under way — check whether a new one has already come out before citing
   `LLM01:2025`.
5. **Lethal trifecta**: original formulation and attribution (Simon Willison, 16-jun-2025).
   Verify the post before paraphrasing it; there is a **different** "lethal trifecta" in the
   AI security literature that is not this one.
6. **Status of A2A** and of any other agent interoperability standard.
7. **Supply chain incidents** in the framework, the tools or the third-party servers
   you recommend (ASI04): NVD/GHSA per package.
8. **Governance frameworks** if applicable: NIST AI RMF, ISO/IEC 42001, EU AI Act — dates of
   application and concrete obligations (see `grc-compliance-standards`).

### Declared gaps (not verified in this drafting)

- **Exact version numbers and framework release dates** beyond those cited
  (LangGraph 1.0 Oct 2025 / 1.1 Mar 2026; Pydantic AI v2 Jun 2026; Microsoft Agent Framework 1.0
  Apr 2026; Google ADK 2.0): they come from secondary sources. **Verify in the repository or
  package registry** before pinning a minimum version in a project.
- **Exact wording of ASI03, ASI04 and ASI08**: the secondary sources consulted disagree
  ("Identity & Privilege Abuse" vs "Agent Identity & Privilege Abuse", "Vulnerabilities" vs
  "Compromise", "Cascading Failures" vs "Cascading Agent Failures"). Not verified against the primary
  PDF.
- **Detailed status of the OpenAI Agents SDK and of CrewAI in 2026** (version, cadence, roadmap):
  not verified in depth.
- **A concrete agent observability tool** (specialised tracing, LLM-as-judge in
  production): deliberately none is recommended; the criteria are OpenTelemetry and your own trace.
  Verify the market if the project needs a platform.
- **Quantitative data on the efficacy of anti-injection guardrails**: not verified; the
  criteria in §5 (not using them as sole control) rest on the formulation of the lethal trifecta,
  not on figures.

If the web contradicts this document, **the web wins** — flag the discrepancy.
