---
name: solidity-standards
description: Solidity and EVM smart contract engineering standards. Trigger on .sol files, foundry.toml, remappings.txt, hardhat.config.ts, .solhint.json, forge/cast/anvil/foundryup, solc pragma and evm_version, OpenZeppelin Contracts and openzeppelin-upgrades, ERC-20/721/1155/4626/4337, EIP-712 and EIP-7702, UUPS/Transparent/Beacon proxies, reentrancy, oracle and flash-loan issues, invariant and fuzz tests, Slither, Echidna, Medusa, halmos, kontrol, Certora, SMTChecker, gas optimization, or pre-deployment audit and incident-response gates.
---

# Solidity and EVM contract standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Premise that governs everything else**: deployed code is **immutable, public and handles value directly**. There is no *hotfix*, no rollback, no "we'll fix it next sprint", and the attacker is **economically incentivised in real time** — they read your bytecode, your mempool and your commit before you deploy. That reorders the cost calculus of the whole catalogue: **a missing test is not a potential regression, it is an irreversible loss**; a skipped review does not delay a release, it funds a third party. Here the spend on prior verification is not justified by ROI, it is justified because **there is no later correction phase**.

Operational corollary: in this domain the expensive work goes **before** deployment (invariants, formal verification, audit, incident plan), not after (monitoring, patching). Inverting that order is the domain's structural mistake.

Applies to: `.sol` files, `foundry.toml`, `remappings.txt`, `hardhat.config.ts`, `.solhint.json`, `slither.config.json`, `forge script` deployment scripts, `*.t.sol` tests, and to every review of contracts on the **EVM** (Ethereum L1, L2s of the OP Stack / Arbitrum / zkEVM kind and compatible chains).

**Not applicable**: see `appsec-standards` (**AppSec methodology**: STRIDE, abuse cases, finding triage, choosing and calibrating SAST/DAST, ASVS — here the **vulnerability classes specific to contracts** and the code criteria that make them impossible), `cryptography-pki-standards` (**algorithm and curve choice, key life cycle and custody** — here only the **correct use of the primitives the chain already exposes**: signature verification, EIP-712, `ecrecover` and its malleability trap), `secrets-management-standards` (**custody of the deployment private key and of the `owner`/`upgrader` key is hers** —HSM, multisig, rotation, approvals—; here only the hard requirement that **it must not be a single hot key**), `typescript-standards` (deployment scripts and TS/JS Hardhat tests with `viem`/`ethers`: **the language and its tooling are hers**; the contract and its invariants, ours), `rust-standards` (**contracts on non-EVM chains** —Solana, CosmWasm, Arbitrum Stylus— and tooling written in Rust: **this skill is about Solidity and the EVM and claims nothing outside that**), `cicd-standards` (pipeline, runners, OIDC and artifact signing; **here the specific gate: nothing is deployed without green invariant tests, without a closed external audit and without a written incident plan**), `vulnerability-management-standards` (triage and SLA for CVEs in dependencies and tooling), `offensive-security-standards` (**offensive testing with scope and authorisation in writing**; this skill is **defensive**: it describes vulnerability classes **in order to prevent them** — see the prohibition in §7), `incident-response-forensics-standards` (managing the real incident, tracing funds, coordination with exchanges and law enforcement; here only the **plan and the on-chain mechanisms** that must exist beforehand), `grc-compliance-standards` (**the regulatory framework** —MiCA in the EU, anti-money-laundering obligations, sanctions—; no legal criteria are issued here), `observability-standards` (telemetry platform, alerts and SLOs; here **which event to emit and why**), `api-design-standards` (the contract of an HTTP/gRPC API; **the ABI of a deployed contract is also a public contract — and an immutable one too**: breaking it is not a *major bump*, it is a migration with a network-wide cost).

## 2. Default decisions / Toolchain

> Verify the latest version on the web before committing to it in a real project (§8). Data from Aug 2026: it expires fast.

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Compiler | **solc 0.8.36** (2026-07-09). Repo: **`argotorg/solidity`** (Argot Collective), **no longer** `ethereum/solidity` | The repo moved from the Ethereum Foundation to Argot Collective; the old links redirect. **Update remotes, CI and docs** |
| `pragma` in deployable contracts | **`pragma solidity 0.8.36;` — an exact version, no `^` and no ranges** | The deployed bytecode is unrepeatable: a `^` makes the binary depend on whichever solc the machine that compiled it happened to have. It breaks **reproducible verification** on Etherscan/Sourcify, changes gas and exposes you to unaudited codegen bugs. `^` only in **published libraries** so as not to fragment consumers |
| `evm_version` | **Set it explicitly**. The compiler default since 0.8.31: **`osaka`**. `amsterdam` supported since 0.8.36 but it is **not** the default | An L2 usually lags behind L1: compiling with opcodes the target chain does not implement deploys an **unusable and immutable** contract. Verify the hard fork supported by the target chain before every deployment |
| Framework | **Foundry** (`forge`/`cast`/`anvil`/`chisel`), latest tag **v1.7.1**; `master` at 1.8.0 | Tests, *fuzzing* and invariants in Solidity, with no change of language or mental model between contract and test; native execution. **Hardhat 3 is a legitimate alternative, not a leftover**: v3.12.0 (2026-07-30), an EDR runtime in Rust, first-class Solidity tests and multi-chain simulation. Criterion: **Foundry by default**; Hardhat 3 if the project lives off TS scripting, plugins and integrations (verification, Ignition) or the team already operates it. **Living with both is normal and is not debt** |
| Foundry pin | **An exact version in CI** (`foundryup --install v1.7.1`), not the `stable` channel nor `nightly` | See the discrepancy in §8: the page of the rolling `stable` tag showed v1.5.1 while the tag listing was already at v1.7.1. `nightly` changes the output of `forge fmt` and breaks CI |
| Base library | **OpenZeppelin Contracts 5.7.0** (2026-07-29), **MIT** (raw `LICENSE`: *"The MIT License (MIT) / Copyright (c) 2016-2026 Zeppelin Group Ltd"*) | ERC-20/721/1155/4626, `AccessControl`, `ReentrancyGuard` and proxies are not reimplemented. Policy: **a single minor version pinned in `remappings.txt` + lockfile**, upgraded deliberately after reading the CHANGELOG (5.7.0 brings *breaking changes* in the EIP-712 domain and in governance error names) |
| Upgradeability | **`openzeppelin-foundry-upgrades` / `openzeppelin-upgrades`** with automatic *storage* compatibility validation | They support UUPS, Transparent and Beacon; **they do not support Diamond (EIP-2535)** — choosing Diamond means taking on *storage* validation by hand |
| Lint / formatting | **`forge fmt`** + **`solhint` 6.2.3** (2026-06-19) | `forge fmt --check` and `solhint` as CI gates |
| Static analysis | **Slither 0.11.6** (2026-07-29), **AGPL-3.0** | Active, with Hardhat v3 and Sourcify support. AGPL: irrelevant for internal use in CI, **relevant if you integrate it into a SaaS** |
| Property fuzzing | **`forge test` (fuzz + invariant)** as the base; **Echidna 2.3.3** (2026-07-27, AGPL-3.0) and **Medusa 1.5.1** (2026-03-11, AGPL-3.0) for long campaigns | Writing the invariant *harness* reusably across engines (the Chimera pattern) avoids rewriting it per tool |
| Formal verification | **SMTChecker** (built into solc, zero adoption cost) → **`halmos`** or **`kontrol`** → **Certora Prover** for what is critical | `kontrol` **BSD-3-Clause**, v1.0.255 (2026-06-24), active. **Certora Prover open source since Feb 2025, GPL-3.0** (`LICENSE`: *"GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"*), free to self-host; the cloud is paid. **`halmos` AGPL-3.0 but with no release since v0.3.3 (2025-07-31) and no commits on `main` since Aug 2025**: verify its status before putting it in a CI gate |
| Legacy symbolic analysis | **Mythril: not as a gate** | MIT, but **last release v0.24.8 on 2024-03-27**. No effective maintenance: use it as an occasional confirmation, never as a control |

## 3. Structure and conventions

Reference layout (Foundry):

```
src/            # production contracts. One contract per file, name == file
  interfaces/   # IFoo.sol — the ABI is a public contract: it is designed, not derived
  libraries/
test/           # *.t.sol unit and integration tests
  invariant/    # handlers + invariants (mandatory, §4)
script/         # forge script for deployment and upgrades — versioned and reviewed
lib/            # dependencies as submodules (forge install)
foundry.toml
remappings.txt  # explicit and versioned: no implicit resolution
```

- **Explicit and versioned `remappings.txt`**. Implicit resolution makes two machines compile different trees; with immutable bytecode that is unacceptable.
- **Dependencies frozen to a *commit*, not to a branch**: submodules with a pinned SHA (or the package manager's lockfile). A `lib/` pointing at `master` is a dependency that changes on its own underneath an artifact that cannot change.
- **NatSpec mandatory** on every `external`/`public` and on every event and custom error: `@notice` (what it does, for the user who signs), `@param`, `@return`, `@dev` for invariants and assumptions. NatSpec feeds the human-readable signature in wallets: **without it the user signs blind**. `@custom:oz-upgrades-from` where the upgrades plugin requires it.
- **Custom errors** (`error Foo(uint256 x);` + `revert`) instead of `require` with a string: cheaper and **typed**, which makes the failure distinguishable from the client. Every `revert` must say *which* condition failed.
- **Conventions**: `CamelCase` for contracts and structs, `mixedCase` for functions and variables, `SCREAMING_SNAKE` for `constant`/`immutable`, a `_` prefix for internal/private. Member order: types, constants, `immutable`, *storage*, events, errors, modifiers, constructor, `external`, `public`, `internal`, `private`.
- **Explicit units in the name**: `amountWad`, `feeBps`, `deadlineTs`. The precision errors in §5 start with variables that have no unit.
- **Interfaces over implementations** in every external integration; never cast to somebody else's contract assuming its shape.

Reference `foundry.toml` — **what is decided here is reproducibility and the depth of the test campaigns**, not convenience:

```toml
[profile.default]
solc_version = "0.8.36"        # exact: the binary must be reproducible by third parties
evm_version = "prague"         # that of the TARGET chain, not the compiler default
optimizer = true
optimizer_runs = 200           # fewer runs = less code; measure, do not copy
bytecode_hash = "ipfs"         # coherent metadata for verification on Sourcify/Etherscan
deny_warnings = true           # a compiler warning in an immutable artifact is a bug
fs_permissions = []            # no disk access by default; open by path and only what is needed

[fuzz]
runs = 10_000                  # PR: enough to catch the obvious
[invariant]
runs = 256
depth = 500                    # depth = number of calls per sequence; this is what finds bugs
fail_on_revert = false         # with bounded handlers, raise to true and fix the spurious reverts

[profile.ci.fuzz]
runs = 100_000                 # nightly: a long campaign, not on every PR
```

## 4. Quality and testing

**No level in this list is optional in a contract that is going to custody value.** The order is one of increasing cost; the deployment gate requires all of them.

### 4.1 Unit tests
`forge test` with explicit coverage of the **happy path, edges and errors**: every `revert` has a test that triggers it (`vm.expectRevert(Foo.selector)`), every event one that verifies it (`vm.expectEmit`), every access control branch one per role and one per unauthorised actor. A `require` with no test that fires it is an unverified branch of the immutable binary.

### 4.2 Property fuzzing and invariant tests — **expected practice, not optional**
- **Per-function fuzzing** (`function testFuzz_x(uint256 amount)`) for every function that accepts amounts, with `vm.assume`/`bound` instead of discarding en masse.
- ***Stateful* invariants**: the properties that must hold **after any sequence of calls by any actor** — solvency (`sum(balances) <= totalAssets`), monotonicity of indices, value conservation, that no permitted operation leaves the protocol insolvent. They are written with **bounded handlers** (an unguided *fuzzer* sends almost everything to `revert` and the campaign proves nothing).
- Long campaigns outside the PR (nightly) with **Echidna** or **Medusa** over the same *harness*; the input corpus is versioned.
- **A broken invariant in CI blocks the merge.** Every bug fix also leaves its regression test.

### 4.3 Formal verification
Escalation by criticality: solc's **SMTChecker** (free, start there) → **`halmos`** (symbolic tests with the same syntax as Foundry's) or **`kontrol`** → **Certora Prover** with CVL specifications for the economic core. What it guarantees: that the **specified** property holds for all inputs within the model. What it does not: that the specified property is the right one, nor anything outside the model (*gas*, interaction with unmodelled external contracts, economic incentives). **An `UNKNOWN` from an SMT *timeout* is not a proof**: treat it as a failure.

### 4.4 *Forking* and simulation
Tests against real network state (`vm.createSelectFork` at a **pinned** block, not "the latest": tests must be deterministic) for every integration with third-party protocols, oracles and real tokens. Simulate the full deployment and **the upgrade** on a fork before executing them.

### 4.5 Coverage
`forge coverage` as a **signal, not a goal**. 100 % of lines with zero invariants is worse than 80 % with good invariants. What is measured seriously: error branches covered and properties formulated.

### 4.6 External audit — gate prior to deployment
Mandatory before the first deployment with real value and before every upgrade that touches custody or accounting logic.
- **What it guarantees**: that an independent team with a reputational incentive reviewed **a specific commit**, in **a specific scope**, over **a specific time**, and found no more than what it reports.
- **What it does NOT guarantee**: that the contract is secure. It does not cover what was left out of scope, nor changes after the audited commit, nor the economic design, nor key governance, nor external dependencies. **"Audited" is not an attribute of the protocol, it is a dated event about a hash.**
- Process requirements: scope and commit fixed in writing, **the report is published** (including the uncorrected findings and the reason), every fix is re-verified, and the report is referenced against the deployed hash. Two independent audits for anything custodying significant value; a public *audit contest* **complements**, it does not replace.

### 4.7 Bug bounties and incident response
- A *bug bounty* programme **before** deployment, with scope, a reward scale proportional to the value at risk and explicit *safe harbour*. A contact channel nobody reads is the reason an honest researcher turns into something else.
- **An on-chain incident response plan, written and rehearsed BEFORE deployment** — it is a deployment requirement, not later documentation. It must set out: who can **pause** and with what mechanism (and what is paused and what is not); what the **timelock** protects and what its window is; the *war room* (who, how it is convened, an out-of-band channel); prepared contacts with exchanges and with security and chain analysis providers; the criteria for public communication; and the recovery or migration procedure. **Rehearse it on testnet**: a `pause()` nobody has ever executed is not a control.
- A contradiction to be resolved by design, not ignored: **the same `pause` that saves the protocol is an exploitable centralisation**. Document who holds it and under what governance (§5.3).

### 4.8 CI gate (it breaks the build, in order of cost)
```
forge fmt --check
solhint 'src/**/*.sol'
forge build --sizes            # deployed code size limit
forge test -vvv                # unit + fuzz
forge test --match-path 'test/invariant/*'
slither . --fail-high --fail-medium
forge coverage --report summary
# nightly: Echidna/Medusa campaign + formal verification
```
In addition, a **deployment gate** (not a merge one): green invariants + closed audit + signed incident plan + reproducible deployment verified in the explorer (Sourcify/Etherscan) with the same solc, `evm_version` and *metadata*.

## 5. Security — the core

### 5.1 Reentrancy
- **Checks-Effects-Interactions is the basis and remains so**: validate, **write the state**, and only then call out. Most reentrancies are state written after the external call.
- CEI **plus** a guard (`ReentrancyGuard`, or its *transient storage* variant if the target chain supports EIP-1153 — verify §2 `evm_version`). Belt and braces: the guard covers what a future refactor breaks.
- Every external call is a **transfer of control**: `token.transfer` to a contract, an ERC-777/ERC-721 `onERC721Received`/ERC-1155 *callback*, `msg.sender.call{value:}`. Enumerate them explicitly in the review.
- **Cross-function and cross-contract reentrancy**: a per-function guard does not protect if two different functions touch the same state. The guard goes on the **shared state**, not on the fashionable function.
- **Read-only reentrancy** — the subtle one and the least known: during the external call the protocol's state is **temporarily inconsistent**, and a `view` function (a price, a `totalSupply`, a ratio) read **by a third party** at that instant returns a false value. The classic guard does not cover it because the `view` function mutates nothing. Criterion: **`view` functions that other protocols consume as a source of truth must respect the same guard** (or expose a reader that reverts if the guard is taken), and **never integrate by reading a third party's `view` without checking how it behaves mid-call**.

### 5.2 Access control and initialisation
- Every function that mutates sensitive state declares its authorisation explicitly. `Ownable` only for the trivial; **`AccessControl` with separate roles** (pauser ≠ upgrader ≠ treasury) by default. Least privilege on chain too.
- **`tx.origin` FORBIDDEN for authorisation** — no exceptions. It authorises the human, not the calling contract, and any intermediate contract the victim interacts with inherits their permissions. (Besides, EIP-7702 makes the EOA/contract distinction even less reliable: `msg.sender.code.length == 0` no longer means "it is a person".)
- **Uninitialised implementation contracts**: a logic contract behind a proxy **must** disable its initialiser in the constructor (`_disableInitializers()`); otherwise anybody initialises it, becomes `owner` of the implementation and —if the implementation has a reachable `delegatecall` or `selfdestruct`— can render the proxy permanently unusable.
- Ownership changes in **two steps** (`Ownable2Step`): a transfer to a wrong address is irreversible.
- **`delegatecall`** executes somebody else's code **over your own *storage*, your balance and your identity**. Only towards immutable addresses or ones governed by the same trust model; never towards an address parameterisable by the caller.

### 5.3 Proxies and upgradeability
- Choice: **UUPS** by default (upgrade logic in the implementation, cheaper proxy) — **with the trap accepted**: if an upgrade deploys an implementation without the upgrade logic, upgradeability is lost **for ever**. **Transparent** when you prefer to separate the admin from the call flow. **Beacon** when many instances must be upgraded atomically. **Diamond (EIP-2535)** only with a written justification: the OZ plugins do not validate its *storage*.
- ***Storage* collision**: the layout is a contract between versions. Never reorder, insert in the middle nor change the type of an existing variable; only **append at the end**. Use the upgrades plugin's automatic validation as a gate, `__gap` (or *namespaced storage*, ERC-7201) in inheritable contracts. **Simulate every upgrade over a fork of the real state** before executing it.
- **An upgradeable contract does not remove the risk: it transfers it entirely to whoever has the key.** The governance of that key **is part of the threat model** and is documented with the contract: a multisig with a threshold and independent signers (a single hot key is **FORBIDDEN**, see `secrets-management-standards`), a **timelock** with a window long enough for a user to exit before the change takes effect, and a declared path towards immutability or towards decentralised governance. **A "decentralised" protocol with an `upgradeTo` behind an individual key is a custodian that does not say so.**

### 5.4 Oracles and price manipulation
- **An AMM's *spot* price is not an oracle.** It is the instantaneous state of a reserve that anybody can move within the same transaction. Reading it to value collateral is the vulnerability, not an implementation detail.
- **TWAP** raises the cost of the attack but does not eliminate it: its security depends on the pair's **liquidity** and on the window; in a shallow market or on an L2 with a single sequencer it is manipulable. Choose the window with the manipulation cost calculated, not out of habit.
- **Signed / push oracles** (provider feeds): validate **freshness** (reject stale data), maximum **deviation** against the previous reading, and **the case where the feed does not respond** — a down oracle must pause or degrade, never silently return the last value. Check the feed's number of decimals, which does **not** have to match the token's.
- Tokenised vault ratios (ERC-4626) and third parties' `totalSupply`/`balanceOf`: **any `view` of another protocol is an oracle if you use it to decide**, with all the risks in §5.1.

### 5.5 Flash loans
They are not a vulnerability: they are a **capital amplifier that turns any economic flaw into something exploitable at maximum scale and with no prior capital**. Design criterion: **assume the attacker has unlimited capital during a transaction**. Any logic that depends on balances, votes, prices or proportions **measured at the instant** must use delayed values or a snapshot of a previous block. Blocking "contracts" or checking `msg.sender == tx.origin` **is not a mitigation** (and it breaks multisigs and smart accounts).

### 5.6 Arithmetic and precision
- 0.8.x reverts on overflow/underflow by default: `unchecked` only with the bound demonstrated in a comment and with an edge test.
- **Multiply before dividing**; every division truncates. Use fixed-point libraries (`mulDiv`) so as not to lose precision nor overflow in the intermediate.
- **Always round in favour of the protocol** (up on what the user pays or owes, down on what they receive). "Neutral" rounding is the vector of erosion-by-repetition attacks.
- **First depositor inflation attack** in vaults: the first *share* is manipulated by a direct donation. Mitigate with *dead shares*, a virtual offset or an initial deposit by the protocol itself.
- **Different decimals between tokens** (USDC's 6 versus most tokens' 18, and tokens with arbitrary decimals): normalise at the entry boundary, never assume 18. `decimals()` is optional in ERC-20 and may lie.

### 5.7 Randomness and front-running
- **On-chain randomness FORBIDDEN**: `block.timestamp`, `blockhash`, `block.prevrandao`, `block.difficulty`, state hashes — all of it is known, predictable or influenceable by whoever builds the block, which is exactly who has the incentive. Instead: a provider's **verifiable VRF**, or **commit-reveal** with a time window and a penalty for not revealing. The validator **can** revert the transaction that does not suit them: no single-transaction scheme is safe.
- **MEV and *front-running***: the mempool is public; the order of transactions is decided by a third party with an economic incentive. Every swap or liquidation exposes **slippage (`minAmountOut`) and `deadline` parameters that are mandatory and decided by the user** — a `minAmountOut = 0` or a `deadline = block.timestamp` is a blank cheque. Veto patterns susceptible to a *sandwich*; use commit-reveal or private submission where the value justifies it.
- **ERC-20 approvals**: the classic `approve` race. Use `increase/decreaseAllowance` or `permit`; **FORBIDDEN** to require infinite approval when the exact amount is enough.

### 5.8 Tokens that do not comply with the standard
The real ERC-20 is a heterogeneous mess. Assume by default:
- **Absent or non-boolean return** (USDT and others): always use `SafeERC20`; checking a `bool` that does not exist causes a revert.
- **Fee on transfer** and **rebasing**: never assume you receive what you sent — **measure the balance before and after**, or explicitly reject those tokens with an allowlist.
- **Double entry point** (two addresses controlling the same balance): it breaks any control based on the token's address.
- **Callbacks** (ERC-777, ERC-721/1155 `onReceived`): reentrancy through the back door.
- Criterion: **a reviewed token allowlist** in protocols that accept collateral. "Any ERC-20" is an attack surface open to the attacker deploying the token.

### 5.9 Denial of service
- **Unbounded loops** over arrays a third party can grow: the day comes when the function exceeds the block gas limit and **becomes inaccessible for ever**. Every iterable array must have a bound, or be iterated by pages.
- **Push versus pull**: never send funds in a loop to N recipients. One recipient that reverts (a contract with no `receive`, or malicious on purpose) blocks the rest. **Pull pattern: the beneficiary withdraws.**
- Dependency on an external call that may revert inside a critical function (liquidations, position closing): isolate it or make it tolerant to failure.
- ***Gas griefing* and the 63/64 rule**: a `call` forwards at most 63/64 of the remaining gas, so **the caller can choose how much gas to leave** so that the subcall fails while the outer transaction appears successful. In critical functions: check the result of the `call`, do not swallow the failure, and require a minimum of gas if the subcall must complete. Never wrap an external call in `try/catch` and carry on as if nothing happened.

### 5.10 Contract life cycle
- **`selfdestruct` is deprecated**: since EIP-6780 (Dencun, 2024) it only really destroys the contract if it runs **in the same transaction in which it was created**; in any other case it merely sends all the ether to the recipient. Every design that depends on "deleting the contract" is broken. **FORBIDDEN** in new contracts.
- **`CREATE2` and predictable addresses**: the address depends on `(deployer, salt, initcode)`. Two consequences: you can deposit into an address **before** a contract exists there (counterfactual), and the change in `selfdestruct` semantics alters the old assumptions about re-creation at the same address (metamorphic contracts). Set the `salt` so that a third party does not control it, and **never** assume an address with no code will stay that way.
- **`address.code.length == 0` does not mean "it is a person"**: it is false during the constructor and, with EIP-7702, also for EOAs with delegated code. Do not use it as access control.

### 5.11 Signatures
- **EIP-712** for every piece of data signed by a user: a domain separator with **`chainId`, `verifyingContract`, `name` and `version`**. Without `chainId` the signature is reusable on another chain (and on any fork); without `verifyingContract`, on another contract.
- **A `nonce` per signer and a `deadline` are mandatory**. Without a nonce, *replay* within the same chain; without a deadline, a signature lives for ever.
- **`ecrecover` malleability**: it accepts the pair `(s, n-s)` — two different valid signatures for the same message. And it returns `address(0)` on failure instead of reverting: **comparing against `address(0)` is not optional**. Use OpenZeppelin's `ECDSA` (it forces `s` into the low range and reverts) instead of bare `ecrecover`. **Never use the signature hash as a unique identifier** — it is malleable; the identifier is the nonce.
- **Curves other than secp256k1**: since Fusaka there is the **secp256r1 (P-256, EIP-7951)** precompile, which makes it viable to verify passkey and secure-enclave signatures on chain. Use the precompile, **never** a Solidity implementation of the curve. (Curve choice and the life cycle of those keys belong to `cryptography-pki-standards`.)
- **Smart accounts**: verify with **EIP-1271** (`isValidSignature`) in addition to ECDSA. With **EIP-7702** on mainnet since Pectra (2025-05-07), an EOA can have delegated code: any logic that assumes a codeless `msg.sender` is a person is broken.
- `permit` (EIP-2612): it improves UX but introduces one more signature that has to be bounded with a deadline and a nonce; and **not all tokens implement it** (check, with an alternative path).

### 5.12 Cross-chain bridges
The category with the greatest accumulated historical losses and **the one that tolerates a design error worst**: there is no shared consensus between the two chains, so security rests on a set of signers, on a proof, or on a verifier — and that component is the target. Criterion: **you do not write your own bridge**; if it is unavoidable, the trust model is documented explicitly (who can mint at the destination and with what proof), message verification validates **origin, destination, nonce and uniqueness**, and the signer set is subject to the rules in §5.3. Figures (§8, verify before citing): DefiLlama puts cumulative losses from exploitation at **more than USD 16.5bn**, of which ~7.7bn is DeFi; the bridge figure appears as **USD 2.9bn** in one report and as **USD 3,304m** on DefiLlama's own page — **declared discrepancy**, verify at the source before using it. Two figures that correct the domain's intuition: **private key compromise accounts for more than 25 % of thefts and appears in four of the ten largest**, above any class of contract bug; and the largest recorded incident (Bybit, Feb 2025) **was not a Solidity failure**, but a signing and interface-approval failure. Writing a perfect contract and holding the key badly is the dominant failure mode.

## 6. Gas and operability

- **Gas is a functional requirement, not an optimisation**: a function that exceeds the block gas limit is not slow, it is **unreachable for ever**. A gas budget per critical function, measured (`forge test --gas-report`, CI *snapshots* that fail on regressions) and **verified on the target chain**, not only on L1.
- **`storage` is the dominant cost**: reading and writing persistent storage dominates any micro-optimisation of computation. Cache in `memory` inside the function; pack variables that are read together into the same 32-byte slot (and **do not** pack the ones that are not, or you pay for the masking with no benefit). `immutable`/`constant` for what does not change. *Transient storage* (EIP-1153) for state that lives within a transaction — verify support on the target chain.
- **Events are a contract's telemetry**: there is no `stdout`, no agent, no *sidecar*. **Without events there is no possible operation** — no monitoring, no state reconstruction, no detection of an attack in progress, no indexing. Rule: **every relevant state transition emits an event**, with the fields you need to filter by as `indexed` (a maximum of 3), including actor and amount. Emit **after** writing the state. And conversely: events nobody consumes are pure cost — each one must have a declared consumer (indexer, alert, accounting).
- **Minimum production alerts**: role and ownership changes, timelock queuing and execution, `pause`/`unpause`, upgrades, and economic thresholds (anomalous withdrawals, oracle deviation, drop in collateralisation). With a real on-call recipient.
- **Deployed code size limit**: it is still that of **EIP-170 (24 KiB)**. EIP-7907 (raising the limit and metering the cost of loading code) **was pulled from Fusaka** at ACDE #216 and could be reconsidered for Glamsterdam: **do not design counting on more space**. `forge build --sizes` in CI; if it gets close, the problem is one of design (split into libraries or modules), not of optimiser flags.
- **Per-transaction gas cap** (EIP-7825, in Fusaka): a single transaction can no longer consume the whole block. Every heavy administrative operation (migration, mass initialisation, sweeping lists) must be **paginable and resumable** — if it does not fit under the cap, it does not exist.
- **Layer 2**: the cost model is different (data availability dominates over execution), and **the opcode set lags behind L1** (see `evm_version`, §2). The sequencer is normally **a single one**: it changes the MEV model, introduces a single point of failure and means `block.timestamp` and transaction ordering have different guarantees. Verify per chain before assuming anything.
- **Recent protocol changes that affect contract-writing criteria** (verify in §8, do not cite from memory):
  - **Pectra** (mainnet 2025-05-07) introduced **EIP-7702**, with the impact in §5.10 and §5.11.
  - **Fusaka** (meta **EIP-7607**, status *Final*), activated on mainnet at the end of 2025. From its list, what changes contract criteria: **EIP-7951** (the **secp256r1** curve precompile — it enables verifying passkey/Secure Enclave signatures on chain at reasonable cost, see §5.11), **EIP-7825** (per-transaction gas cap), **EIP-7939** (the `CLZ` opcode), **EIP-7823/7883** (bounds and repricing of `MODEXP`: review anything doing modular exponentiation), **EIP-7935** (default block gas to 60M). The rest (PeerDAS, `eth/69`, the RLP block limit) is infrastructure. solc set `osaka` as the default EVM in 0.8.31.
  - **Glamsterdam** (ePBS EIP-7732, block-level access lists EIP-7928, gas repricing) **was not activated on mainnet as of Aug 2026** — any criterion that depends on it is premature.
  - **EOF was dropped** from Fusaka and solc **removed** the experimental backend in 0.8.36: code, articles or tools that assume EOF are obsolete.

## 7. Sustainability and prohibitions

**Cadence**: review solc at every minor release (the bytecode of what is already deployed does not change, but anything new must be compiled with a compiler carrying the known bugfixes — consult the official list of bugs by version). OpenZeppelin: upgrade minors after reading the full CHANGELOG, never automatically. Security tooling, kept updated and with its version pinned in CI. **Every deployed contract is re-reviewed when an external dependency its security model relies on changes** (an oracle, a token, a bridge): you cannot update, but they can.

**When NOT to use a blockchain.** Honesty first: **if the problem is solved with a database and a signature, it does not need a contract.** A chain provides exactly one thing — verifiable execution with no shared trusted party — in exchange for cost per operation, latency, the impossibility of correcting, public exposure of data, and a regulatory regime of its own (MiCA: the transitional period for service providers in the EU **ended on 1 July 2026**; see `grc-compliance-standards`). If there is a trusted operator, if the data is personal (the right to erasure and an immutable record are incompatible), if errors need correcting, or if the only reason is the narrative: **the correct answer is not to deploy a contract**, and saying so is part of the job.

**FORBIDDEN** (requires written justification and explicit approval to make an exception):
- ❌ `tx.origin` for authorisation.
- ❌ Randomness derived from `block.timestamp`, `blockhash`, `block.prevrandao` or any on-chain state.
- ❌ A `pragma` with `^` or a range in deployable contracts; an unset `evm_version`; deploying without verifying the source code in the explorer.
- ❌ An AMM's *spot* price as an oracle; integrating a third party's `view` without analysing its behaviour under reentrancy.
- ❌ A value `call`/`transfer` before writing the state (a checks-effects-interactions violation); `delegatecall` to an address controllable by the caller.
- ❌ An implementation behind a proxy without `_disableInitializers()`; an upgrade without *storage* layout validation and without fork simulation.
- ❌ The `owner`/`upgrader` key in a single hot address; an upgrade with no timelock in a protocol holding third-party value.
- ❌ ERC-20 calls without `SafeERC20`; assuming 18 decimals; assuming that `transfer` moves exactly what was sent.
- ❌ Unbounded loops over data a third party grows; distributing funds by *push* in a loop.
- ❌ Swaps without `minAmountOut` and `deadline` decided by the user; infinite approval by default.
- ❌ Bare `ecrecover` (without checking `address(0)` nor normalising `s`); signed data without `chainId`, without a nonce and without a deadline.
- ❌ `unchecked` without a demonstrated bound; rounding in the user's favour in the protocol's accounts.
- ❌ Deploying without green invariant tests, without a closed external audit and without a written and rehearsed incident plan.
- ❌ `selfdestruct` in new contracts, and any design that depends on destroying or re-creating a contract at its address.
- ❌ `address.code.length == 0` or `msg.sender == tx.origin` as a check for "it is a person".
- ❌ Home-made cryptography; reimplementing a standard OpenZeppelin already provides audited.
- ❌ Mythril, or any unmaintained tool, as a security control (useful only as an occasional confirmation).
- ❌ **Including ready-to-use exploits, weaponised PoCs or attack recipes against specific third-party protocols.** This skill is **defensive**: it describes vulnerability classes **in order to prevent them**. All offensive testing goes with scope and authorisation in writing, under `offensive-security-standards`.

## 8. Mandatory web verification

Before committing any datum from this document to a real project, **verify on the web** (Atom feeds and raw files; `api.github.com` returns 403 unauthenticated and the page summariser invents dates):
1. **solc**: `https://github.com/argotorg/solidity/releases.atom` and the raw `Changelog.md`. Check the current version, the **default EVM** and the **official list of known bugs by version** before pinning a `pragma`.
2. **The EVM supported by the target chain** (L1 and every L2 used): the operator's documentation. It is the datum that expires the most and the one that breaks a deployment irreversibly.
3. **OpenZeppelin Contracts**: `releases.atom` + raw `LICENSE` + the CHANGELOG of *breaking changes*. Check whether a 6.x major already exists.
4. **Foundry and Hardhat**: the `v1.x` tags of the Foundry repo (do not trust the rolling `stable` tag, see the discrepancy below) and Hardhat's `releases.atom`.
5. **Security tools, one by one** (maintenance status **and** licence, both change): Slither, Echidna, Medusa (AGPL-3.0), halmos (AGPL-3.0), kontrol (BSD-3-Clause), Certora Prover (GPL-3.0), Mythril (MIT, unmaintained). A repo with little activity does **not** imply abandonment: cross-check with the project's official source before discarding it.
6. **Ethereum network upgrades**: what is activated on mainnet and which EIPs it includes — **read the fork's meta-EIP** (`eips.ethereum.org`, e.g. EIP-7607 for Fusaka) and the Ethereum Foundation's blog, **never third-party articles**: several published EIP lists still include proposals that were pulled from the fork before it activated (EIP-7907 is the clear case). As of Aug 2026: Pectra and Fusaka activated, **Glamsterdam not**.
7. **EIP-7702 and account abstraction**: what is deployed on mainnet and how wallets treat it. A hot topic.
8. **Loss figures**: DefiLlama (`/hacks`, `/hacks/total-value-lost`) or another source that publishes **data**, not headlines. Cite the date of consultation.
9. **Regulatory status (MiCA and equivalents)**: official sources (ESMA, the national authority). Engineering criteria only; the regulatory side belongs to `grc-compliance-standards`.

**Declared discrepancies (Aug 2026)**:
- **Foundry**: the page of the rolling `stable` tag showed *"Foundry v1.5.1 … bugfix release to support solc 0.8.31"* while the `v1.*` tag listing is headed by **v1.7.1** and `master` declares `version = "1.8.0"`. Practical consequence: **pin an exact version**, not the channel.
- **Bridge losses**: **USD 2.9bn** (a third-party report) versus **USD 3,304m** (DefiLlama's page). DefiLlama itself warns of overlap between the "bridge" label and the target protocol, and of entries with incomplete amounts.
- **H1-2026 losses**: **USD 1,316m across 344 incidents** (CertiK) versus **~USD 972m across 207** (another report). Different counting methodologies: cite the source and the date, never the figure alone.
- **Hardhat**: a third-party analysis from 2026 put the version at v3.9.1 while the official releases feed showed **v3.12.0** (2026-07-30). The feed wins.

**Declared gaps, not verified as of Aug 2026** — (a) whether an **OpenZeppelin Contracts 6.x** major is in preparation and its calendar; (b) the current pricing model of the **Certora Prover in the cloud** (Certora does not publish a price list; only the GPL-3.0 licence of the code was confirmed); (c) whether **`halmos`** is still maintained despite having no release and no commits on `main` since Aug 2025 — **cross-check with a16z crypto before discarding it or putting it in a gate**; (d) the **exact date and epoch of Fusaka's activation** on mainnet — the meta **EIP-7607** is in *Final* status and its EIP list was indeed verified at `eips.ethereum.org`, but the date appears only in a secondary source (2025-12-03): confirm it on the Ethereum Foundation's blog before citing it; (e) the **default EVM of solc 0.8.36**, inferred as `osaka` because its changelog contains no `Set default EVM Version` line after 0.8.31 — **confirm with `solc --help` or the official documentation** before omitting `evm_version`.

If the web contradicts this document, **the web wins** — flag the discrepancy.
