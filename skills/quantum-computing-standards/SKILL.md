---
name: quantum-computing-standards
description: Quantum computing as an R&D decision with honest expectations — what today's hardware can and cannot do. Use when evaluating a quantum proposal or vendor pitch, reading qubit-count and quantum-advantage claims and separating physical from logical qubits, fidelity and error rates, NISQ limits, decoherence and T1/T2, surface codes and qLDPC error correction and the physical-to-logical overhead, gate-based versus quantum annealing (D-Wave) and why they are not interchangeable, algorithms with a proven speedup (Shor factoring, Grover's quadratic search, quantum phase estimation, Hamiltonian simulation of chemistry and materials) versus QAOA/VQE heuristics with no proven advantage, resource estimation for a quantum attack, writing circuits with Qiskit, Cirq, PennyLane, Q#/QDK, Braket or OpenQASM, buying cloud quantum access (IBM Quantum Platform, Amazon Braket, Azure Quantum), quantum-inspired classical algorithms, or budgeting quantum R&D and training. Also covers "quantum" marketing claims in a procurement or board setting.
---

# Quantum computing standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers: what can be done today and what cannot

This skill exists for **one thing only**: that nobody commits budget, architecture or a product
promise to a capability that does not exist. The technical content is secondary to the criteria
in §1 and the prohibitions in §7.

### 1.1 What CANNOT be done today

- **RSA and elliptic-curve cryptography cannot be broken.** No machine is anywhere near it.
  Cost reference, verbatim from Craig Gidney's own paper
  (arXiv:2505.15917, 21 May 2025): *"In Gidney+Ekerå 2019, I co-published an estimate stating
  that 2048 bit RSA integers could be factored in eight hours by a quantum computer with 20
  million noisy qubits. In this paper, I substantially reduce the number of qubits required.
  I estimate that a 2048 bit RSA integer could be factored in less than a week by a quantum
  computer with less than a million noisy qubits."* Under explicit assumptions: *"a uniform
  gate error rate of 0.1%, a surface code cycle time of 1 microsecond, and a control system
  reaction time of 10 microseconds"*. **Fewer than a million noisy physical qubits, and current
  machines have on the order of hundreds.** Note also the direction of the figure: the
  estimate **dropped from 20 million to under 1 million in six years**, not through better
  hardware but through better algorithms. That is why the threat timeline is uncertain.
- **There is no demonstrated advantage in enterprise optimisation, machine learning or finance.**
  Variational algorithms (VQE, QAOA) are heuristics: **they have no proof of asymptotic
  advantage**, and in practice they compete badly against a good classical solver. Any
  presentation promising to "optimise the delivery route" with quantum is selling a
  heuristic with no guarantees against one that already works.
- **There is no fault-tolerant quantum computer.** Nobody today runs a long algorithm with
  full error correction. What exists are demonstrations that correction **starts**
  to work.
- **It cannot be used in production.** Not on capacity, not on availability, not on cost,
  not on reproducibility of results.

### 1.2 What can be done today

- **Experiment, build up a team and estimate resources.** Write circuits, run them on a
  simulator and on real hardware over the cloud, and above all **calculate how many logical
  qubits and how many gates your problem would need** — which is the most useful result, because
  it almost always proves the problem is not a candidate.
- **Quantum simulation of chemistry and materials**: the most credible medium-term use case,
  because it is the problem the machine is structurally suited to (simulating a quantum
  system with a quantum system) and where algorithms with demonstrated exponential advantage
  exist for specific tasks. It is still not production.
- **Take advantage of "quantum-inspired" algorithms**: several classical advances have come out
  of trying to simulate quantum algorithms. That return is real and is collected today, with no hardware.

### 1.3 NISQ, noise and the distance between a physical and a logical qubit

We are in the **NISQ** era (*Noisy Intermediate-Scale Quantum*): few qubits, noisy and with no
effective error correction. A qubit loses its state through **decoherence** in microseconds
to milliseconds, and every gate introduces error. With a per-gate error on the order of 10⁻³, a
circuit of a few thousand gates already produces noise instead of a result. **That is the
real ceiling, not the qubit count.**

**Quantum error correction** encodes a **logical qubit** in many **physical
qubits**. The reference milestone is Google Quantum AI, *"Quantum error correction below the
surface code threshold"* (arXiv:2408.13687, Aug 2024; Nature 638, 2025), with these figures
verbatim: **distance-7 code over 101 physical qubits**, *"The logical error rate of our
larger quantum memory is suppressed by a factor of Λ = 2.14 ± 0.02 when increasing the code
distance by two"*, logical error of *"0.143% ± 0.003% error per cycle"*, and a logical memory
*"exceeding its best physical qubit's lifetime by a factor of 2.4 ± 0.3"*.

**How to read that result, which is what matters**: it is a first-rate scientific milestone —
it demonstrates that adding physical qubits now **reduces** the error instead of increasing it,
which is the precondition for everything else. And at the same time: **101 physical qubits for ONE
logical memory qubit**, with an improvement factor of 2.4× over the best physical qubit. It is not a
logical qubit computing, it is a logical qubit **remembering**. Extrapolating from there to "breaking
RSA" jumps some four orders of magnitude and several capabilities that do not yet exist (high-fidelity
logical gates, magic-state distillation at scale, sustained real-time decoding).

**Rule for reading any announcement**: a qubit count with no **two-qubit gate fidelity**,
no **connectivity** and no statement of whether they are **physical or logical** is advertising, not
a specification.

**Not applicable**: see **`post-quantum-crypto-standards`** (**hard boundary**: *harvest now,
decrypt later*, cryptographic inventory and CBOM, choice of ML-KEM/ML-DSA/SLH-DSA, hybrids
in TLS/SSH/IPsec, cryptographic agility and **the whole regulatory calendar** —NIST IR 8547,
SP 800-131A, CNSA 2.0—. **The only practical and urgent consequence of this discipline today is
that migration, and it is entirely theirs**: here we only explain *why* the threat exists and
link out), `cryptography-pki-standards` (classical algorithms, PKI and key custody),
`hpc-standards` (cluster, Slurm scheduler, MPI and the software environment of the classical
computing it competes with and against which it must be compared), `gpu-computing-standards` (accelerators
and their provisioning — **quantum simulators run here**), `deep-learning-standards`
and `classical-ml-standards` (the classical baseline any "quantum ML" proposal must
beat **before** being considered), `ai-governance-standards` (governance of technology
claims and vendor due diligence), `grc-compliance-standards` (formal acceptance
of technology risk and evidence), `tech-leadership-standards` (the
*build-vs-buy* decision and investing in non-productive R&D), `python-standards` (the language of
Qiskit, Cirq and PennyLane), `blockchain-web3-standards` (the "quantum risk" to chain
signatures is handled there as a risk, and its remedy in `post-quantum-crypto`),
`llm-app-engineering-standards` and `mlsecops-standards` (**nothing to do with this**: "quantum" in
AI marketing is not this).

## 2. Default decisions

> Verify on the web before committing to anything (§8). This domain changes headline every quarter and
> half the headlines get corrected afterwards.

| Decision | Default | Justifiable alternative | Vetoed |
|---|---|---|---|
| Invest? | **R&D and training, with a bounded budget and a learning objective** | Applied research if the business is chemistry, materials or pharma | Production project with a delivery date |
| First deliverable | **Resource estimation** of your problem in logical qubits and gates | Prototype on a simulator | Running on real hardware "to see what comes out" |
| Baseline | **Always the best available classical algorithm**, measured | — | Comparing against classical brute force to inflate the advantage |
| Hardware access | **Cloud by the hour** (IBM Quantum Platform, Amazon Braket, Azure Quantum) | Agreement with a research centre | **Buying hardware**: obsolete before it pays for itself |
| SDK | **Qiskit** (**Apache-2.0**, `LICENSE.txt`: *"Copyright 2017 IBM and its contributors / Apache License Version 2.0"*) if the target is IBM; **Cirq** (**Apache-2.0**) for Google; **PennyLane** (**Apache-2.0**) for variational work and automatic differentiation; **Q#/QDK** (**MIT**, *"Copyright (c) Microsoft Corporation"*) for the Microsoft ecosystem | Writing/exporting to **OpenQASM** so as not to be tied to the SDK | Designing on a proprietary SDK from a single vendor |
| Model | **Gates** for any algorithm with demonstrated advantage | **Annealing** (D-Wave) **only** for combinatorial optimisation expressible as QUBO/Ising, and compared against a classical solver | Presenting annealing and gates as the same thing |
| Crypto | **Go to `post-quantum-crypto-standards` and execute its plan** | — | Waiting for "when the quantum computer arrives" |

## 3. Models and algorithms: where there is advantage and where there is not

### 3.1 Gates versus *annealing* — they are not the same

- **Gate model** (IBM, Google, Quantinuum, IonQ…): universal. It is the only one that can
  run Shor, Grover, phase estimation or Hamiltonian simulation. It is where all the theory of
  demonstrated advantage lives.
- **Quantum annealing** (D-Wave): **it is not universal**. It solves a specific family of
  optimisation problems (expressible as QUBO/Ising) by seeking the ground state of
  a Hamiltonian. It has many more qubits, and that figure **is not comparable** with that of a
  gate machine: they are different units. **It cannot run Shor.** The advantage of
  annealing over the best classical heuristics remains disputed, and several
  demonstrations have been matched or beaten by classical methods.

Confusing the two models, or comparing their qubit counts, is the most common reading error
in commercial material and in the press.

### 3.2 Algorithms with demonstrated advantage

| Algorithm | Advantage | Real status |
|---|---|---|
| **Shor** (factoring, discrete log) | **Exponential** | Demonstrated in theory. Unachievable with current hardware (§1.1) |
| **Grover** (unstructured search) | **Quadratic** (√N) | Real but modest; the cost of loading the data usually eats the advantage |
| **Phase estimation / Hamiltonian simulation** | Exponential for certain systems | The most credible use case: quantum chemistry and materials |
| **VQE / QAOA** (variational) | **None demonstrated** | Heuristics. They suffer *barren plateaus*. They compete badly with classical solvers |
| **"Quantum machine learning"** | **None demonstrated** on classical data | The bottleneck is loading classical data into quantum states |

### 3.3 Grover does NOT break symmetric cryptography — say it explicitly

It is the most widespread confusion and the one that diverts the most budget. **Grover's advantage is
quadratic, not exponential**: it reduces a search from 2ⁿ to 2^(n/2). On AES-128 that amounts
to an attack of ~2⁶⁴ **sequential** quantum operations, which is not a practical threat —
and on AES-256 it is nowhere close.

NIST IR 8105, *Report on Post-Quantum Cryptography* (April 2016), §2, verbatim:

> *"Grover's algorithm provides a quadratic speed-up for quantum search algorithms in
> comparison with search algorithms on classical computers. We don't know that Grover's
> algorithm will ever be practically relevant, but if it is, doubling the key size will be
> sufficient to preserve security. Furthermore, it has been shown that an exponential speed up
> for search algorithms is impossible, suggesting that symmetric algorithms and hash functions
> should be usable in a quantum era."*

And its Table 1: **AES → "Larger key sizes needed"**; **SHA-2, SHA-3 → "Larger output needed"**;
**RSA, ECDSA/ECDH, DSA → "No longer secure"**.

Operational conclusion: **the problem is exclusively public-key cryptography.**
AES-256 and SHA-384 still hold. Anyone selling you "replace your symmetric encryption with quantum"
has not read this. **The public-key replacement plan belongs to
`post-quantum-crypto-standards`.**

### 3.4 "Harvest now, decrypt later": the only urgent thing today

Traffic and data encrypted **today** with classical public key may be being
captured and stored to be decrypted once the machine exists. If your data must remain
confidential 10-20 years from now (medical records, trade secrets, classified
information, long-lived personal data), **the exposure is already happening**, regardless
of when the hardware arrives.

**And this skill ends here**: the prioritisation criteria by data lifetime, the
cryptographic inventory, the algorithm choice, the hybrids and the regulatory calendar
are **entirely `post-quantum-crypto-standards`'**. Nothing is duplicated here. If the
question is "what do I do", the answer is to go there.

## 4. Quantum advantage: the dominant pattern is refutation

**Every quantum-advantage claim must be treated as provisional until it survives
several years of classical algorithm improvement.** This is not scepticism: it is the record.

Reference case. Google claimed quantum supremacy in 2019 with Sycamore (53 qubits, 200
seconds against an estimated 10,000 classical years). In 2024-2025, *"Leapfrogging Sycamore:
harnessing 1432 GPUs for 7× faster quantum random circuit sampling"* (*National Science
Review*, March 2025 collection), abstract verbatim: *"Here we report an energy-efficient
classical simulation algorithm, using 1432 GPUs to simulate quantum random circuit sampling
that generates uncorrelated samples with a higher linear cross-entropy score and is 7× faster
than the Sycamore 53-qubit experiment."* And its conclusion, also verbatim: *"Our work
provides the first unambiguous experimental evidence to refute Sycamore's claim of quantum
advantage, and redefines the boundary of quantum computational advantage using random circuit
sampling."*

That is: **the most famous supremacy demonstration in the history of the field was refuted
classically**, not through better hardware but through better software, on commercially
available GPUs. The same pattern has repeated with several *boson sampling* claims.

Methodological consequences:
- The bar of "this is classically impossible" moves **downwards** over time. An
  advantage demonstrated this year may be a cluster calculation next year.
- **The tasks in advantage demonstrations are not useful.** *Random circuit sampling* and
  *boson sampling* are chosen precisely because they are hard to simulate, not because they solve
  anything. Advantage ≠ usefulness.
- More recent claims (in October 2025 Google presented an experiment called
  *Quantum Echoes* on a 65-qubit subset of Willow, described as the first
  **verifiable** quantum advantage, with a cited factor of ~13,000×) **could not be
  verified against a primary source in this pass** and must be treated as a vendor
  claim pending independent replication (§8).

**Roadmap qubit figures**: vendor plans (e.g. IBM announcing a
fault-tolerant system with **200 logical qubits and 100 million gates by 2029**)
are **commercial targets**, not delivered capability, and that figure entered here through a web
search and **not through a primary source** (IBM's site returned 403). Treat every roadmap as
what it is: an intention, with a track record of slippage across the whole sector.

## 5. Cost and when investing makes sense

- **The investment that almost always makes sense**: training two or three people, a
  small budget of cloud time, and **a resource estimation** for the business's candidate
  problems. Low cost, main return: **being able to say no** with grounds
  when the vendor turns up.
- **The investment that almost never makes sense**: buying hardware, committing to a product
  date, or funding an enterprise optimisation pilot with no measured classical baseline.
- **Three-question filter for any proposal**:
  1. What is the **mathematically formulated problem** and which specific quantum algorithm
     solves it?
  2. How many **logical qubits** and how many gates does it require, and when will they be available
     according to the resource estimation?
  3. What does the **best classical algorithm** do today with the same problem, measured?
  If any of the three is missing, the answer is no.
- **The classical baseline is measured, not assumed.** Many "quantum problems" disappear
  when somebody profiles the existing classical code.
- **Reproducibility**: quantum hardware is noisy and changeable. A result with no number
  of *shots*, no device calibration for the day, no seed and no error-mitigation
  strategy used **is neither reproducible nor comparable**.

## 6. Engineering practices (if you are going to experiment anyway)

- **Circuits in version control**, with export to **OpenQASM** as well as the SDK, so as
  not to depend on a vendor.
- **Simulator first, always.** If the circuit does not work without noise, it is not going to work with
  noise. The simulator is deterministic and cheap; the hardware is neither.
- **Log per run**: device, date, calibration, number of *shots*,
  transpilation applied and error-mitigation method. Without that the result cannot be
  defended.
- **Transpilation changes the circuit**: mapping to the real connectivity inserts SWAP
  gates and can multiply the depth. Measure the **transpiled** circuit, not the one written.
- **Cloud cost bounded by a hard budget**: QPU time is billed per run and
  a badly planned parameter sweep eats the quarter's budget.
- **Sensitive data**: running on a quantum cloud is running on a third party. The
  same data classification rules apply as to any SaaS.

## 7. Sustainability and prohibitions

Cadence: review the state of the field **once a year**, not with every headline. What really
changes —gate fidelity, operational logical qubits, Shor resource cost— moves
over years. What changes every week is the marketing.

**Explicit prohibitions:**

- ❌ **FORBIDDEN** to sell, promise or budget "quantum advantage" in a business project
  **without a mathematically formulated problem**, without the specific algorithm that solves it and
  without the resource estimation that says when it would be executable.
- ❌ **FORBIDDEN** to cite qubit figures **without distinguishing physical from logical** and without the
  two-qubit gate fidelity and the connectivity. A qubit count alone means
  nothing.
- ❌ **FORBIDDEN** to present a vendor roadmap as available capability.
- ❌ **FORBIDDEN** to claim that quantum computing "breaks encryption" without specifying that it
  refers **only to public key**, and that Grover does **not** break symmetric (§3.3).
- ❌ **FORBIDDEN** to compare qubit counts between *annealing* and the gate model, or
  to present them as the same technology.
- ❌ **FORBIDDEN** to cite a quantum-advantage claim without checking whether it has been matched
  or refuted classically. The Sycamore case is the precedent, not the exception.
- ❌ **FORBIDDEN** to propose an optimisation or "quantum machine learning" pilot without a
  **measured** classical baseline using the best available solver.
- ❌ **FORBIDDEN** to justify a quantum hardware purchase with positioning
  or image arguments.
- ❌ **FORBIDDEN** to publish a quantum hardware result without *shots*, calibration,
  transpilation and error-mitigation method.
- ❌ **FORBIDDEN** to duplicate post-quantum migration criteria here: algorithms, deadlines and
  inventory belong to `post-quantum-crypto-standards`.
- ❌ **FORBIDDEN** to postpone post-quantum migration on the grounds that "the machine does not exist": the
  threat model is capture today and decrypt later (§3.4).

## 8. Mandatory web verification

Before committing to anything:

1. **State of error correction**: number of **operational logical qubits** (not
   memory ones) and their error rate, in a peer-reviewed publication. What was verified here:
   Google, distance 7 over **101 physical qubits**, Λ = 2.14 ± 0.02, 0.143 % logical error
   per cycle, lifetime 2.4 ± 0.3× that of the best physical qubit (arXiv:2408.13687, verbatim from the
   abstract). Check what has changed since then.
2. **Cost of an attack on RSA/ECC**: the current estimate. The last one verified is Gidney
   2025: *"less than a week … with less than a million noisy qubits"* for RSA-2048, under
   explicit assumptions on error rate and cycle times. **This figure has dropped 20× in
   six years through algorithmic improvements: re-checking it is mandatory, not optional.**
3. **Quantum-advantage claims**: whether the one being cited to you still stands. Verified here:
   Sycamore 2019 **refuted** by classical simulation on 1432 GPUs (*National Science
   Review*, verbatim). **Declared gap**: Google's *Quantum Echoes* experiment
   (Oct 2025, ~65 qubits, ~13,000×, "verifiable quantum advantage") **came in via WebSearch and
   could not be confirmed against a primary source** — Google's blog returned 404 and the arXiv
   identifier tried corresponded to a different paper. **Do not use it without verifying it.**
4. **Vendor roadmaps**: IBM Starling (200 logical qubits, 100 M gates, 2029),
   Nighthawk and Loon **came in via WebSearch**: `ibm.com/roadmaps/quantum` and the IBM
   Quantum blog returned 403. **Declared gap**: confirm against a primary source before citing
   any of those numbers, and always treat them as a target, not as capability.
5. **SDKs**: current version and licence. Verified raw: **Qiskit Apache-2.0**, **Cirq
   Apache-2.0**, **PennyLane Apache-2.0**, **Q#/QDK MIT**. Also check whether the SDK is still
   active and whether the vendor has changed the hardware access model.
6. **NIST IR 8105** is from **April 2016**: its table on the impact per algorithm is still
   conceptually correct, but **the calendar and the specific algorithms are superseded**
   by FIPS 203/204/205 and by NIST IR 8547 — all of that lives in
   `post-quantum-crypto-standards`, which is where to go.
7. **D-Wave and annealing**: whether the advantage claim being cited has been matched by
   classical methods. It has happened several times.

If the web contradicts this document, **the web wins** — flag the discrepancy.
