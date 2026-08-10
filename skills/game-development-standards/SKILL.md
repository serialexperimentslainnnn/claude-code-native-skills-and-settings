---
name: game-development-standards
description: Game development as engineering, governed by the frame budget. Use when working with Unity (.unity scenes, .prefab, .meta files, Assets/ and ProjectSettings/, Packages/manifest.json, MonoBehaviour, FixedUpdate, Burst/Jobs, DOTS/Entities, Addressables, IL2CPP, Unity 6 LTS and Unity Personal/Pro/Enterprise revenue thresholds), Unreal Engine (.uproject, .uasset, .umap, Build.cs and Target.cs, UPROPERTY/UFUNCTION, Blueprints, Nanite, Lumen, Chaos, World Partition, UE royalty and per-seat licensing), Godot (project.godot, .tscn, .tres, GDScript .gd, _process versus _physics_process), a game loop with fixed timestep and interpolation, frame-time percentiles, stutter and hitching, GC spikes and object pooling, asset streaming and level loading, ECS and data-oriented design, deterministic simulation and floating-point desync, netcode with server authority, client-side prediction, rollback and lag compensation, cheating and anti-cheat, lobby and party flow in the client, large binary assets under Git LFS or Perforce P4/Helix Core, console certification and platform TRC/TCR submission, in-game accessibility (remapping, subtitles, motion options), or loot boxes, in-game purchases and PEGI descriptors.
---

# Video game development standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Fixes the engineering criteria for **building a game**: which engine and under which licence, how
the simulation loop is organised, how memory and loading are managed, how multiplayer is designed
when the client is hostile by default, how gigabytes of binaries are versioned, what a console
demands before letting you publish, and what legal obligations come with monetising through chance and with minors.

**The axis of the domain: the frame budget dominates everything.** It is not one performance metric
among others — it is the constraint from which the entire architecture derives. At 60 fps there are **16.6 ms**
per frame to simulate, animate, resolve physics, culling, prepare and issue *draw calls*, audio,
networking and input; at 30 fps, 33.3 ms; at 120 fps, 8.3 ms; at 90 Hz of XR, 11.1 ms (see `xr-standards`). From
that number come all the decisions that in another domain would be a matter of opinion: why memory is pooled
instead of allocated, why allocation in the hot loop is avoided, why data is laid out
in columns, why the level is loaded in parts. **A design that does not fit in the
budget is not a slow design: it is an incorrect design.**

**The corollary that decides the daily work: the percentile wins, not the mean.** 240 fps on average with an
80 ms frame every two seconds feels **worse** than a stable 60 fps. The product metric
is **frame time** (ms) at **p99 / p99.9** and the number of frames that go over
budget (*hitches*), not average fps. Fps are a reciprocal average: they hide exactly the
failure the player notices. **No performance target is written in average fps.**

Triggers: `.unity`, `.prefab`, `.meta`, `Assets/`, `ProjectSettings/`, `Packages/manifest.json`,
`MonoBehaviour`, `Update`/`FixedUpdate`/`LateUpdate`, `[BurstCompile]`, `Entities`, `Addressables`,
IL2CPP; `.uproject`, `.uasset`, `.umap`, `*.Build.cs`, `UPROPERTY`, `UCLASS`, Blueprint, Nanite,
Lumen, Chaos, World Partition; `project.godot`, `.tscn`, `.tres`, `.gd`, `_physics_process`;
`.gitattributes` with `filter=lfs`, `p4 sync`, `p4 edit`, `typemap`; "it stutters", "it freezes when
entering the zone", "players are teleporting", "it fails cert", "it desyncs in the
network match".

**Not applicable**: see `webgl-webgpu-standards` (**the browser and the graphics API are theirs, without
exception**: `getContext('webgl2'|'webgpu')`, WGSL/GLSL, three.js/Babylon, context loss,
KTX2/Basis, and **the frame budget inside a web canvas**. Operational boundary: **if the
target is the browser, the graphics layer is theirs and here only the loop design, the
simulation and asset production remain**; if the target is a native or console executable, the
graphics fall under the engine and its documentation, not under this skill —this skill does **not** fix criteria for a
native graphics API: it does not claim Vulkan, D3D12 or Metal), `xr-standards` (**batch 22, direct sister**:
**comfort, motion sickness, motion-to-photon latency, OpenXR, hand and controller interaction and
biometric privacy are theirs**; **here the engine, the loop and content production**. A
VR game is built under this skill and **validated under theirs**: if the budget is justified
by nausea and not by smoothness, it belongs there), `cpp-standards` and `c-standards` (the language: RAII,
UB, sanitizers, compilation flags — here only the use the engine makes of it),
`dotnet-standards` (**C# as a language**; note: **Unity does not use the modern .NET runtime nor its
conventions**, and their §1 explicitly excludes it — Unity's scripting C# is ours, server
C# is theirs), `rust-standards` (language; engines in Rust are an immature ecosystem: demands an ADR),
`performance-engineering-standards` (**the profiling and optimisation methodology is theirs**:
the USE method, *flame graphs*, measure before optimising, Amdahl's law. **Here only the
specific constraint —the per-frame budget— and the engine's tools**), `gaming-infrastructure-standards`
(**dedicated servers, session orchestration, scaling and fleet cost,
transport, matchmaking as a service**. Here the game's **protocol and authority model**, not
the infrastructure hosting it), `mobile-standards` (store, packaging, permissions, app life cycle
and App Store/Play policy; here only the game running inside), `accessibility-standards`
(**the WCAG conformance criteria and their legal scope are theirs**; **a game is not a web page and
WCAG does not apply to it directly** — here in-game accessibility options), `i18n-standards`
(localisation, formats, pseudolocalisation and translation vendor; here the cost it imposes on the
engine: text in atlases, variable length, dubbing), `privacy-engineering-standards` (GDPR applied,
DPIA, telemetry and minors' data as design; here only the domain trigger),
`git-workflow-standards` (branch, commits, LFS as a tool and repo policy),
`testing-qa-standards` (test strategy and QA as a function), `cicd-standards` (pipeline and gates),
`deep-learning-standards` / `local-inference-standards` (AI as a trained model; the "AI" of
NPC behaviour —state machines, *behavior trees*, GOAP, *pathfinding*— **is ours**),
`opensource-licensing-standards` (licence of dependencies and of assets), `webassembly-standards`
(the Wasm target and its runtime).

## 2. Default decisions / Toolchain

> Verify the latest version and **the current commercial terms** on the web before pinning them in
> a real project (§8). **Unity's and Unreal's terms have changed twice in three years; almost
> everything circulating in forums is out of date.**

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| 3D engine for a small/medium team | **Unity 6 LTS** | Unreal | Ecosystem, platforms, hiring |
| High graphical fidelity / AAA | **Unreal Engine 5** | Unity with HDRP | Nanite, Lumen, cinematic tools |
| 2D, indie, no licence strings | **Godot 4** | Unity | MIT, no thresholds and no royalties |
| Unacceptable licence risk | **Godot** | In-house engine | The only one of the three with no commercial counterparty |
| In-house engine | **No**, unless the requirement is impossible | — | Permanent cost of tooling and porting |
| Gameplay language | The engine's (C#, C++/Blueprint, GDScript) | — | Stepping outside breaks the *tooling* |
| Art version control | **Perforce (P4/Helix Core)** in production with artists | Git + LFS in a small team | Exclusive locking of binaries |
| Performance target | **p99 ms per platform**, not average fps | — | *Stutter* is the real failure |
| Competitive multiplayer | **Server authority** | — | The client is hostile by definition |
| Small co-op multiplayer | Host-client with host authority | Deterministic P2P (*lockstep*) | Cost against cheat surface |
| Fast-action networking | Prediction + reconciliation + lag compensation | *Rollback* (fighting games) | Perceived latency |

**Verified state of the licences (August 2026)** — this is the datum that decides a project:

- **Unity**: the *Runtime Fee* **was cancelled**. Verbatim from the announcement (Matt Bromberg, CEO, 12-Sep-2024):
  *«we've made the decision to cancel the Runtime Fee for our games customers, effective immediately.
  Non-gaming Industry customers are not impacted by this modification»* and *«we're reverting to our
  existing seat-based subscription model for all gaming customers»*. Current model per
  `unity.com/pricing` (consulted Aug 2026): **Personal free** below **200,000 USD** of
  revenue or funding in the last 12 months; **Pro mandatory above 200,000 USD**
  (**210 USD/month per seat**, from **2,310 USD/year**); **Enterprise mandatory above
  25M USD**; **Unity Industry** for applications **outside games/entertainment** with more than
  1M USD. **Verify the thresholds and the price before budgeting**: they went up on 1-Jan-2025 and have
  moved again.
- **Unity, versions**: `unity.com/releases` (Aug 2026) — **Unity 6.3 LTS supported until December
  2027**; **Unity 6.0 LTS until October 2026** (that is, **it expires this month: migrate now**). Annual
  LTS with **two years** of support; *Update releases* are only supported **until the
  next one ships**. Live production → LTS; mid-cycle production → Update.
- **Unreal Engine**: a **5 % royalty on lifetime gross revenue above
  1,000,000 USD per product**, excluding sales on the Epic Games Store, and a **seat
  model** (*Unreal Subscription*, introduced with UE 5.4, of the order of **1,850 USD/seat/year**)
  for **non-game** enterprise use above 1M USD. **⚠ This block is NOT verified
  verbatim**: `unrealengine.com/eula/unreal` and `/license` return **403** to any automated
  access (see §8). **Before signing anything, read the EULA in a browser and confirm
  the percentage, the threshold, the calculation base (gross before the store's commission) and the exclusions.**
- **Unreal, versions**: **UE 5.8 (June 2026)** is the last planned major release of the
  UE5 line; **UE6 is aiming at Early Access in late 2027** (source: State of Unreal 2026
  coverage via web search; **not verbatim** — confirm before planning a migration).
- **Godot**: **MIT**, verbatim from `LICENSE.txt` on `master`: *«Permission is hereby granted, free of
  charge, to any person obtaining a copy of this software … to deal in the Software without
  restriction»*. **No royalties, no revenue thresholds, no seats.** Latest stable verified
  through the releases Atom feed: **4.7.1-stable**. The price is paid in tooling maturity, high-end
  3D and console support (which comes from third parties, not from the project).
- **Governance rule**: the engine licence is a **one-way door decision** in the
  middle of production. It is documented in an ADR with **the exact version of the accepted terms** and
  the continuity clause (Unity committed to whoever stays on a version keeping the
  terms of that version: **verify that it still holds**). Keep a dated copy of the EULA.

## 3. Structure and conventions

**Game loop — the non-negotiable split.** Simulation at a **fixed step**, rendering at a variable step,
interpolation between states for drawing:

```
acumulador += dt_real (acotado: nunca más de N pasos por fotograma → "espiral de la muerte")
mientras acumulador >= dt_fijo:  simular(dt_fijo); acumulador -= dt_fijo
render(alpha = acumulador / dt_fijo)   // interpolar estado previo→actual
```

- **Physics and deterministic gameplay logic go in the fixed step** (`FixedUpdate`,
  `_physics_process`, the physics `Tick`). Input, camera, animation and UI go in the variable one.
- **FORBIDDEN** to multiply by `deltaTime` inside the fixed step or to put physics logic in the variable
  step: it is the cause of "on a fast PC the character jumps higher".
- The `dt_real` **is always bounded** (e.g. 0.25 s): with no cap, a load spike generates more simulation
  steps, which generate more load, which generate more steps.

**Memory.** The garbage collector and the allocator are the primary source of p99 spikes.

- **Zero allocations in the hot loop.** In C#: no LINQ, no concatenated `string`, no *boxing*, no
  capturing *lambdas*, no `foreach` over collections that allocate an enumerator, and no `GetComponent` per
  frame. In C++: no `new`/`shared_ptr` per frame; arenas and *pools*.
- ***Pooling*** for everything that is born and dies in chains: projectiles, particles, enemies, UI
  entries, sound effects. The *pool* is sized to the **measured worst case**, not the typical one, and it is
  pre-warmed at load time, not on the first shot.
- Memory budget **per platform** and a build failure if it is exceeded. The console has no
  *swap*: going over does not degrade, it kills the process.

**Data and ECS.** ECS (Unity Entities/DOTS, `flecs`, `bevy_ecs`) genuinely pays off when there are **many
homogeneous entities updating every frame** —thousands of units, projectiles, particles,
*boids*— and the bottleneck is memory traversal and cache misses. **It does not pay off** in a game with
few heterogeneous entities with scripted logic: there it costs complexity, worse *tooling*, worse
debugging and worse hiring in exchange for nothing. **Rule**: ECS is adopted **on the measured subsystem
that needs it**, not on the whole project, and it is justified with the profiling that motivated it.

**Loading and *streaming*.** The goal is that **nothing is ever loaded synchronously in a gameplay
frame**. Every asset is loaded through an indirect and asynchronous reference (Addressables, the *asset registry* and
*soft references* in Unreal, `ResourceLoader.load_threaded_request` in Godot), with
per-cell/per-level *streaming* and an I/O budget per frame. Loading by path and on demand is
the classic origin of the *hitch* when entering a zone.

**Repo organisation.** Folders by *feature*, not by asset type, once the team grows;
a stable, automated naming convention (the importer and the *build* depend on it); **nothing
generated is committed** (`Library/`, `Temp/`, `Intermediate/`, `Saved/`, `DerivedDataCache/`,
`.godot/`). In Unity, **the `.meta` files are always committed** and `ProjectSettings/` goes under version
control and under review: changing there is changing the build.

**Large binaries.** A `.psd`, an `.fbx` or a `.uasset` **do not merge**. Two options:

- **Git + LFS**: viable if the art is moderate and the team is technical. It demands a disciplined
  `.gitattributes` from commit 1, a *pruning* policy and knowing that **the LFS history grows without
  limit**. LFS file locking exists but is fragile against a team of artists.
- **Perforce (P4/Helix Core)**: still alive in the industry for two concrete reasons Git does not
  cover well: **exclusive locking (*checkout*) of binaries** and **partial synchronisation of a huge
  depot without cloning the history**. Verified at `perforce.com` (Aug 2026): *«Perforce P4
  is free for up to 5 users and 20 workspaces»* — the free tier covers a small team; beyond
  that it is cost and administration. Take care of the `typemap` (binaries as `binary+l`) from
  day 1.
- **Rule**: the decision is driven by **who touches the files**, not by the programming team's
  preference. If there are full-time artists, you choose for them.

## 4. Quality and testing

- **Determinism first**: simulation logic is separated from presentation so it can be
  **tested without the engine**. If you cannot run a simulation step in a unit test, the
  design is coupled to `MonoBehaviour`/`AActor` and it has to be extracted.
- **Match replay tests** (*replay*): record inputs + seed, replay and compare
  the final state. It is the most profitable regression test in the domain: it detects desync,
  *frame rate* dependence and uncontrolled randomness.
- **Randomness**: your own PRNG with an explicit seed and per-system state. **FORBIDDEN** to use the
  runtime's global random in logic that must be reproducible or synchronised.
- **Performance tests as a gate**: reference scene + fixed path (*flythrough*) run
  in CI on representative hardware, with a **threshold on p99 ms**, not on the mean. It breaks the build.
- **Automatic budgets**: number of *draw calls*, triangles, texture memory, package size
  and load time per level, verified in the asset pipeline.
- **Profiling with the engine's tool** (Unity Profiler/Profile Analyzer, Unreal Insights,
  Godot Profiler) **on a release build on the target device**. Profiling in the editor, on
  the programmer's PC, measures something else. RenderDoc/PIX for the GPU side.
- Order of increasing cost in CI: static analysis and project rules → simulation unit
  tests → deterministic *replays* → per-platform build → performance scene → automated *smoke test*
  on device → manual QA session and *playtest*.
- **QA is a function, not a phase**: mandatory edges in the test plan — loss of focus,
  disconnection mid-load, disk full when saving, controller disconnected, alt-tab, console
  suspension, resolution change, two players with the same name, altered system clock.

## 5. Stack security

**Hard multiplayer rule: never trust the client.** The client is in the attacker's hands:
its memory is editable, its traffic is interceptable and its binary is disassemblable. Hence:

- The **server is the only authority** over state, damage, inventory, currency, collision and
  outcome. The client **proposes input**, not results. Any message of the kind "I killed
  X" or "I have Y gold" is a design failure, not a validation failure.
- **Validate on the server** everything: movement range per tick (*speed hack*), line of sight and
  distance when shooting, rate of fire, ownership of the item being used, transaction price.
- **Do not send what the client must not know**: the position of the enemy behind the wall is a
  *wallhack* served by the server itself. Area-of-interest *culling* **for security**, not only
  for bandwidth.
- **Prediction and reconciliation**: the client predicts to hide latency, the server corrects
  and the client re-simulates from the last confirmed state. Lag compensation
  rewinds the server state to the instant of the attacker's shot: it is competitively
  correct and **it has to be documented**, because it generates the "I got killed behind the
  corner".
- **Floating-point determinism**: two machines with different compilers, different CPUs, different
  optimisations (`-ffast-math`, FMA, SIMD) or a different iteration order **can diverge bit by
  bit**. That is why deterministic multiplayer (*lockstep*) is hard: it demands fixed-point arithmetic
  or a deterministic library, a stable iteration order, the same engine version on all
  ends and a prohibition on using presentation state in the simulation. If it cannot be
  guaranteed, **you do not choose *lockstep***: you choose server authority with replicated state.
- **Anticheat**: client-side detection is an arms race lost in the long run. The correct
  order: (1) design with server authority, (2) **statistical detection on the server** over
  telemetry (impossible accuracy, reaction times, trajectories), (3) only then, the client.
  **Kernel-mode** anticheat buys detection at a high and explicit price: it is a
  privileged driver on the player's machine —attack surface, blue-screen risk,
  community rejection, incompatibility with Linux/Steam Deck and with virtual machines— and a
  **privacy matter that must be declared** (`privacy-engineering-standards`). It is decided in an
  ADR with the support cost accounted for, never by default.
- **Classic surface**: deserialisation of saved games and of *mods* (executable code from a
  user file → sandbox or signature), *replays* and community levels as untrusted
  input, exposed match servers with no rate limiting (UDP amplification), and API keys
  for services (analytics, stores, backend) **embedded in the client binary**: any key
  that travels in the client **is published**.
- **Accounts and stores**: the purchase is validated by the server against the store (receipt verified on the
  server); never by the client. Store *webhooks* are verified by signature.
- **Minors**: if the game is accessible to minors, telemetry, advertising, chat and personal
  data fall under a different regime (COPPA in the USA, GDPR and reinforced protection of minors
  in the EU, age verification). **You do not collect what you do not need**; open chat demands
  moderation and reporting. Design and legal basis → `privacy-engineering-standards`.

## 6. Performance and operability

- **Product metric**: frame-time histogram with **p50/p95/p99/p99.9** and a count of
  frames above budget, **per platform and per scene**. Average fps are only good
  for marketing.
- **Performance telemetry in production**, with consent and anonymised: device
  model, GPU, frame-time distribution, load times, unexpected crashes. Without
  this you cannot know what is broken on the hardware you do not own.
- **Per-subsystem budget** published (e.g. at 16.6 ms: X ms of simulation, Y of animation, Z
  of render preparation) and watched in CI: with no split, each team eats the other's headroom.
- **Typical *hitch* causes** in order of real frequency: garbage collection, synchronous asset
  loading, **shader compilation on demand** (PSO precompilation/*warm-up* mandatory), first
  use of an un-warmed system, save I/O on the main thread, and instantiation *spikes*.
- **Quality scalability**: levels of detail and quality options that can be degraded per
  device, with conservative detection. No game performs the same across the whole PC catalogue.
- **Build and platforms**: *build once* per platform in CI, versioned and signed artifact, and
  a target platform matrix declared from the start (changing target mid-way is a
  project cost, not a sprint cost). Deterministic asset compilation and a shared cache.
- **Console certification**: each manufacturer imposes its own technical requirements (TRC/TCR/lotcheck
  and equivalents) on suspend and resume, user management and sign-outs, saving and
  insufficient space, disconnected controllers, UI nomenclature, boot times and trophies.
  **They are read at the start of the project and tested during development, not in the
  delivery week**: failing cert restarts a cycle of days or weeks. Their content is under the manufacturer's
  NDA and **is not reproduced here**: it is consulted in the corresponding developer portal.
- **Post-launch**: patches and downloadable content with save-game compatibility
  (version the save format from v1 and migrate forward), server *feature flags*
  to disable broken content without shipping a patch, and a communicated maintenance window.

**In-game accessibility** — it is a product requirement, not a courtesy. Enforceable minimums:

- **Full remapping** of controls (keyboard, mouse and controller), including *quick-time events*;
  an alternative to holding down (*toggle* instead of *hold*) and to repeated pressing (*mashing*).
- **Subtitles** legible by default: adjustable size, optional opaque background, speaker name and
  **captioning of gameplay-relevant effects**; separation between voice, effects and
  music volume.
- **Motion and vision**: options to reduce camera shake and flashes, field-of-view
  adjustment, disabling *motion blur*; avoid photosensitive-risk patterns.
- **Colour and contrast**: never information **only** by colour; alternative palettes and adjustable
  contrast in the UI; interface scaling.
- **Difficulty and assistance** as separate options (aim assist, invulnerability, skipping
  puzzles) with no social punishment and no content lock-out.
- Store accessibility labels and *badges*: declared with what actually exists.

**i18n**: text outside the code and outside the texture from day 1, variable length anticipated in the UI
(German and Russian grow; Japanese does not break lines the same way), fonts with glyph coverage and
a properly sized atlas, RTL support if applicable, dubbing and lip sync as a production cost, and
pseudolocalisation in QA. Criteria and vendor → `i18n-standards`.

**Monetisation and regulation** — verify the state before designing the economy:

- **Loot boxes**: **Belgium** has considered them gambling since 2018 and bans them de facto
  (**verify the current status and scope**). In **Spain** there has been since 2022 a **draft bill
  regulating random reward mechanisms** (Ministry of Consumer Affairs/DGOJ) with
  identity verification for minors and advertising restrictions: **as of August 2026 there is no record
  that it became law** — check it, do not assume it (§8). In the **EU**, the **Digital Fairness Act**
  is the piece that may ban or restrict loot boxes, virtual currencies and addictive design
  for minors: as of August 2026 it is an **expected proposal, not law in force**.
- **PEGI** already publishes specific descriptors verifiable at `pegi.info`: **«Paid random items»**,
  **«In-game purchases»**, **«Pressure to play»**, **«Time-limited offers»** and **«Cryptocurrency»**.
  Design with them in mind: the descriptor affects the rating and the store.
- Engineering criteria that survive any regulation: **publish the odds**,
  **show the price in real money** next to the virtual currency, **do not chain currencies** to
  hide the cost, **do not target time-limited offers at minors' accounts**, and keep an
  auditable record of every transaction and every draw (seed, result, balance) so you can answer
  a complaint or a regulator.

## 7. Long-term sustainability

- **Engine cadence**: you move up a **major** version between projects, not mid-production;
  within a project only patches of the same LTS are applied, with the version **pinned** in the
  repo and in CI. Every upgrade is tested with the deterministic *replays* and with the performance scene.
- **End of support**: staying on an unsupported version is acceptable only if the game is closed and
  receives no content; if it is still live, the upgrade is planned in advance (see the case of Unity 6.0
  LTS expiring in October 2026).
- **Dependencies**: every *Asset Store*/Marketplace/AssetLib package is a dependency with a
  licence, maintenance and security surface. They are audited like any library
  (`opensource-licensing-standards`); **FORBIDDEN** to integrate third-party assets without recording
  the licence and version.
- **Document the "why" with an ADR**: engine and version of its terms, network model, ECS yes/no,
  anticheat, VCS, target platforms.

**Explicit prohibitions:**

- ❌ **Setting targets or celebrating improvements in average fps.** The budget is expressed in **ms** and is
  measured in **percentiles**.
- ❌ **Trusting any data coming from the client** in a game with competition, an economy or
  shared progression. No exceptions "because it's co-op".
- ❌ *Frame rate*-dependent logic: no physics in `Update`, no `deltaTime` inside the
  fixed step, and no simulation loops without bounding the accumulator.
- ❌ Allocating memory, loading assets, compiling shaders or touching the disk **in the hot loop**.
- ❌ `GameObject.Find`, `GetComponent`, lookup by tag/name or `Blueprint tick` with heavy
  logic per frame. It is resolved at load time and cached.
- ❌ Verbose `Debug.Log`/`UE_LOG` in the release loop: it is not free.
- ❌ Unseeded global randomness in game logic, and `System.Random`/`rand()` shared between
  threads.
- ❌ **Kernel-mode anticheat by default**, with no ADR, without evaluating the cost in privacy, support and
  compatibility with Linux/Steam Deck.
- ❌ API keys, backend secrets or store credentials **in the client binary**.
- ❌ Committing generated artifacts (`Library/`, `Intermediate/`, `Saved/`, `.godot/`) or large
  binaries without LFS/Perforce configured before the first commit. Fixing it afterwards means rewriting
  history.
- ❌ A repository without Unity `.meta` files versioned: it breaks references for the whole team.
- ❌ Leaving accessibility, localisation and console certification **to the end**. All
  three are architectural constraints, not polish.
- ❌ Saving without a format version and without a migration path.
- ❌ Designing an economy with paid chance **without publishing the odds** or the price in real money, or
  targeting it at minors' accounts.
- ❌ An in-house engine "because we'll have more control" without a requirement no commercial engine covers,
  accounting for the cost of the editor, the asset pipeline, the console port and hiring.
- ❌ Adopting ECS/DOTS across the whole project as a fashion, with no profiling to motivate it.
- ❌ Copying Unity's or Unreal's licence terms from a forum. **They are read at the source and
  archived with a date.**

## 8. Mandatory web verification

Before deciding, check the primary source (and **not** forums or third-party summaries):

1. **Unity**: `unity.com/pricing` and the *Unity Terms of Service* — Personal/Pro/
   Enterprise/Industry thresholds, price per seat, and whether the per-version continuity clause still holds.
   Versions and support at `unity.com/releases` (Unity 6.0 LTS expires in **October 2026**).
2. **Unreal**: `unrealengine.com/eula/unreal` and `unrealengine.com/license` **read in a browser**.
   **Declared gap**: both return **HTTP 403** to automated access, and the attempt to fetch
   an archived copy returned **429**; the percentage (5 %), the threshold (1M USD of lifetime gross
   revenue per product), the Epic Games Store exclusion, the 3.5 % of *Launch Everywhere
   with Epic* and the per-seat price of *Unreal Subscription* come from **web search, not from
   verbatim EULA text**. Verify them before signing or budgeting.
3. **Unreal, roadmap**: that UE 5.8 (Jun-2026) is the last major of UE5 and that UE6 is aiming at
   Early Access in late 2027 comes from press coverage via search; confirm on Epic's
   site before planning a migration.
4. **Godot**: `LICENSE.txt` in the repository (MIT) and the latest stable in the releases feed
   (4.7.1-stable as of Aug 2026); status of third-party console support.
5. **Perforce/P4**: free tier limits (verified: *«free for up to 5 users and 20
   workspaces»*) and the price of the next tier.
6. **Loot box regulation**: status of the **Spanish draft bill** (is it still a draft,
   was it approved, was it withdrawn?), status of the **Digital Fairness Act** in the EU (proposal, trilogues,
   entry into force) and the real scope of the **Belgian** ban. **All three were moving
   data at the verification date.** Check against BOE/EUR-Lex, not against the press.
7. **PEGI**: current list of descriptors and their effect on the rating (`pegi.info`).
8. **Platforms**: current certification requirements and SDKs in each manufacturer's portal (under
   NDA), and mobile store policy (`mobile-standards`).
9. **CVEs and advisories** for the engine and for the integrated third-party packages; patch cadence.

If the web contradicts this document, **the web wins** — flag the discrepancy.
