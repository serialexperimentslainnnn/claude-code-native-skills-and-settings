---
name: webgl-webgpu-standards
description: Use when the browser drives the GPU - <canvas> with getContext("webgl2") or getContext("webgpu"), navigator.gpu and requestAdapter/requestDevice, GPUDevice, GPUBuffer, GPURenderPipeline, GPUComputePipeline, GPUBindGroup, .wgsl shaders and WGSL compilation errors, GLSL ES 300 vertex/fragment shaders, three.js and three/webgpu WebGPURenderer with TSL node materials, Babylon.js WebGPUEngine, PixiJS, regl or raw WebGL2, glTF/GLB assets and KHR_texture_basisu, .ktx2 and Basis Universal transcoders, draw calls and instancing with drawElementsInstanced or drawIndexed, frame budget and requestAnimationFrame jank on a canvas, texture memory and GPU out-of-memory, webglcontextlost/webglcontextrestored and GPUDevice.lost, timestamp-query GPU profiling, compute shaders in the browser, OffscreenCanvas in a worker, WebGL2 fallback and navigator.gpu feature detection, or making a canvas accessible.
---

# Browser GPU graphics and compute standards (WebGL2 / WebGPU)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Fixes the criteria for **using the GPU from the browser**: when an accelerated canvas is justified,
which API is chosen, how it degrades, what budget a frame has, what is measured and with what, and what
risks it adds.

**Axis: the most important decision is whether it is needed at all.** WebGL/WebGPU brings a permanent cost —
mandatory degradation, context loss, GPU memory, battery, accessibility broken by default,
profiling that almost nobody on the team knows how to read. That cost is only paid when the problem is really
a GPU problem: 3D scenes, maps with a great many entities, tens or hundreds of thousands of points per frame,
real-time image or video processing, simulation, or client-side inference.

**When NOT to**: a data chart **does not need WebGL**. Bars, lines, areas, pies, scatter with
a few thousand points: **SVG** (accessible, inspectable, printable, selectable) or **Canvas 2D**
(when the number of elements breaks the DOM). A WebGL canvas for a dashboard is accidental
complexity: you lose accessibility, SEO and debuggability in exchange for frames nobody needs. The reasonable
threshold for jumping to the GPU is "Canvas 2D no longer copes, **measured**", not "it'll look more modern".

Triggers: `getContext('webgl2'|'webgpu')`, `navigator.gpu`, `requestAdapter`/`requestDevice`,
`.wgsl` files, GLSL ES 300 shaders, `three`/`three/webgpu`, `@babylonjs/core`, `.ktx2`, glTF with
`KHR_texture_basisu`, `webglcontextlost`, `device.lost`, `timestamp-query`, `OffscreenCanvas`, and the
classic symptom: "on mobile it looks fine for a while and then goes black".

**Not applicable**:
- `frontend-web-platform-standards` (**already written**) — **HTML, CSS, the general browser APIs, the
  loading model, the CSP and the build tool are theirs**. Here only the canvas and the GPU: what is
  drawn inside and how much it costs.
- `frontend-frameworks-standards` (**already written**) — **the framework and its rendering model** are
  theirs; here the canvas render loop, which is **not** the framework's render cycle and must **not**
  be coupled to it (a canvas that is remounted on every component render loses the GPU context).
- `web-performance-standards` (**already written**) — **Core Web Vitals, the page's budgets and their
  measurement are theirs** (LCP, INP, CLS, bundle weight). **Here the *frame* budget and the GPU
  cost, which are a different metric and a different bottleneck**: an app can have perfect CWV and 12 fps
  inside the canvas, and it can have 120 fps and a disastrous LCP. They do not compete: they are measured separately. The weight of
  3D *assets* (models, textures) does count towards the page's byte budget → there.
- `accessibility-standards` (**already written**) — **the WCAG conformance criteria are theirs**. Here their
  technical consequence: **a canvas is opaque to assistive technology** (it is a pixel map, it
  contains no semantics), therefore it requires an equivalent alternative; and `prefers-reduced-motion` as a real
  switch for the animation.
- `gpu-computing-standards` — **the server's GPU, its driver, its sharing (MIG, time-slicing), its
  scheduling and its cost are theirs**. **Here the client's GPU as seen from the browser**: you do not choose
  the hardware, you do not see the driver and the user may have anything.
- `local-inference-standards` — if the case is **running a model**, the choice of model,
  quantisation, format and evaluation is theirs. **Here only the compute substrate** (WebGPU compute,
  device limits, memory).
- `webassembly-standards` (**already written**) — **the Wasm module and its runtime are theirs**; it is frequent in
  this domain (KTX2/Basis transcoders, physics, ported engines). Here only its interaction with
  the GPU and with the frame budget.
- `game-development-standards` — **the simulation loop and the simulation itself are theirs** (update
  order, physics, ECS, the frame budget as an architectural constraint). **Here the
  graphics API and its cost**: pipelines, *bind groups*, *draw calls*, textures and context loss.
- `xr-standards` — **the session model and comfort are theirs** (WebXR, reprojection, motion-to-photon
  latency, motion sickness as a functional requirement); here the rendering inside that frame.
- `pwa-standards` — service worker, installation and offline. A PWA can contain a WebGPU canvas: they are
  different layers. Caching heavy 3D assets is theirs; their format and their GPU cost, ours.
- `caching-cdn-standards` (delivery of models and textures, ranges and compression in transit),
  `object-storage-standards` (where the assets live), `appsec-standards` (methodology; here the
  concrete controls), `privacy-engineering-standards` (**GPU fingerprinting**: the legal and
  consent criteria are theirs), `observability-standards` (telemetry platform; here which GPU
  metrics to emit), `mobile-standards` (native app with its own engine), `i18n-standards`.

## 2. Default decisions

> Verify the latest version and the support status on the web before pinning them in a real project (§8).

### API choice

State verified as of Aug 2026 (`webstatus.dev` + MDN/BCD; **quote it verbatim, not from memory**):

| API | Status | Detail |
|---|---|---|
| **WebGL2** | **Baseline widely available** — `newly` 2021-09-20, `widely` 2024-03-20 | Chrome 56, Chrome Android 58, Edge 79, Firefox 51, Safari 15 / iOS 15 |
| **WebGPU** | **Baseline limited.** MDN, verbatim: *"This feature is not Baseline because it does not work in some of the most widely-used browsers."* | See the breakdown below |

WebGPU breakdown per **MDN browser-compat-data** (verbatim from the notes):
- **Chrome 144**: *"Supported on ChromeOS, macOS, Windows, and Linux (Intel Gen12+ GPUs only)"*. Previously,
  113–143 marked as a partial implementation on ChromeOS, macOS and Windows. **Linux is still the
  hole**: Intel Gen12+ only.
- **Chrome Android 121**: supported (real support depends on the device and the driver).
- **Firefox 141**: **partial** implementation — *"Supports all contexts except service workers"*;
  *"Supports Windows since Firefox 141"*; *"Supports macOS Tahoe on Apple silicon since Firefox 145"*.
- **Firefox Android**: `version_added: false`. **There is no support.**
- **Safari 26 / iOS 26** (and derivatives on iOS, which are WebKit).

**Choice criteria:**

| Situation | Decision |
|---|---|
| Public product, general audience, mobile included | **WebGL2 as the base**, WebGPU as an optional accelerated path. Degradation **is not optional today** |
| Real GPU compute (compute shaders), inference, simulation | **WebGPU**, and a written answer to what happens without it (CPU/Wasm, server, or feature disabled) |
| Controlled audience (intranet, kiosk, known machine estate) | **WebGPU directly**, with the estate verified — including the driver version |
| Simple scene, few objects, no compute | **WebGL2** and that is it. WebGPU does not accelerate what was not slow |
| Linux or Firefox Android in the audience | **WebGL2 mandatory**: that is where WebGPU is not |

**Degradation**: it is implemented **once**, in the engine. Writing two renderers by hand (one WebGPU,
one WebGL2) is duplicating the bug surface; that is why the default is an engine that already does it.

### WGSL and the state of the specification

- **WebGPU**: *"W3C Candidate Recommendation Draft, 14 July 2026"*.
- **WGSL** (WebGPU Shading Language): *"W3C Candidate Recommendation Draft"*, **16 July 2026**.

Consequence: **it is a living specification, not a closed standard**. Pin the engine version and read
its migration notes on every update; do not depend on extensions marked as experimental
(e.g. those named `chromium-experimental-*`), which exist behind a *flag* and disappear without warning.

### Engines and libraries

| Piece | Status as of Aug 2026 | Criteria |
|---|---|---|
| **three.js** (`three`) | **0.185.1** (2026-07-01), **MIT** (read from `LICENSE`) | Unbeatable ecosystem and examples. `WebGPURenderer` (imported from `three/webgpu`) is **universal**: it tries WebGPU and **falls back to WebGL2 automatically**; the *node materials* / TSL only live there. **Careful: it is still on `0.x` and breaks between revisions (`rXXX`)** — the exact version is pinned and the *Migration Guide* is read at every jump |
| **Babylon.js** (`@babylonjs/core`) | **9.19.0** (2026-07-30), **Apache-2.0 — it is NOT MIT** (read from `license.md`) | A batteries-included engine (editor, inspector, physics, XR, node material system). Dual WebGPU/WebGL2 backend out of the box. The better option when the project is "a 3D application", not "a website with 3D". The Apache-2.0 licence matters if there is a licence policy |
| Low level (raw WebGL2/WebGPU, `regl`, thin wrappers) | — | **Only** with a written reason: total pipeline control, a very narrow case or a byte budget that does not allow an engine. The cost is that you reimplement context loss, resource management, degradation and profiling |
| Accelerated 2D engine (PixiJS and similar) | Verify the version and licence before pinning (§8) | For massive 2D (particles, sprites, maps), where a 3D engine is overkill |

**Rule**: **one** engine is chosen per project and two engines managing the GPU context are not mixed. Before
pinning any of them: **exact version, licence read from the raw `LICENSE` and latest release**.

### Assets

| Piece | Choice | Notes |
|---|---|---|
| Scene format | **glTF 2.0 / GLB** | Khronos standard, supported by every engine |
| Textures | **KTX2 with Basis Universal** (`KHR_texture_basisu`) | ETC1S for colour, UASTC for non-colour data (normals, roughness-metallic), per Khronos's own extension |
| Tools | **KTX-Software** (Khronos) and **basis_universal** (Binomial) — both **Apache-2.0**, read from `LICENSE` | The browser **does not decode KTX2 natively**: the engine transcodes on the client (Wasm) to the format the GPU supports |

## 3. Structure and conventions

### Performance: the frame budget is the axis of the domain

- **60 Hz → 16.7 ms per frame** (1000/60 = 16.67). That is the **total**, not your budget: inside it
  fit the JS work, the style/layout of the rest of the page, compositing and the GPU work
  itself. A reasonable work budget: **~10-12 ms**, leaving headroom for the browser.
- **Not everyone runs at 60 Hz.** 120 Hz → **8.3 ms**; 144 Hz → **6.9 ms**. `requestAnimationFrame`
  matches the display: on a 120 Hz phone your "comfortably 60 fps" scene starts dropping
  frames. **60 is not assumed**: the real delta is measured and animation is done **as a function of elapsed
  time, never per frame** (`delta`), or the scene runs at double speed on a
  120 Hz panel. If the cost does not fit, **the frame rate is capped on purpose** (rendering at a stable 30/60 fps) instead
  of delivering an irregular cadence: *jank* is perceived as worse than a lower, constant fps.
- **Draw calls**: the dominant cost in most web scenes is not the number of triangles, it is the
  number of draw calls and state changes. Group by material, merge static
  geometry, **instance** what repeats (`drawElementsInstanced` / `drawIndexed` with instances): a
  forest of 5,000 trees is **one** call, not 5,000.
- **CPU↔GPU transfer**: uploading buffers or textures every frame is the second classic bottleneck. Static
  data is uploaded once; dynamic data goes in persistent buffers updated by ranges.
  **Reading back from the GPU (`readPixels`, `mapAsync`) synchronises and wrecks the pipeline**: if it is
  needed, it is done asynchronously and with several frames of latency accepted.
- **Compressed textures, always, in production**: a PNG/JPEG decompresses to uncompressed RGBA in
  GPU memory (2048×2048 RGBA ≈ 16 MB, plus mipmaps). KTX2/Basis transcodes to the device's native
  format. State of the extensions (webstatus.dev): **ASTC widely available** (`newly` 2020-01-15,
  `widely` 2022-07-15); **BPTC/BC7 (`EXT_texture_compression_bptc`) and RGTC: Baseline limited**. That is why
  you ship **KTX2 and transcode on the client**, instead of serving a fixed format per platform.
  Mipmaps always on anything seen in perspective.
- **LOD and culling**: levels of detail by distance, *frustum culling* (the engine does it, you just have to not
  break it with odd hierarchies), and *occlusion culling* only if profiling justifies it. Less
  geometry uploaded than discarded.
- **Resolution**: rendering at full `devicePixelRatio` on a mid-range phone is cause number
  one of overheating. It is capped (`min(dpr, 2)` or less) and **dynamic resolution scaling** is applied
  when the frame goes over budget.
- **OffscreenCanvas in a worker** (webstatus.dev: **Baseline widely available**, `widely` 2025-09-27)
  to move the render loop off the main thread: the scene stops blocking interaction and
  interaction stops dropping frames. It is the structural decision with the highest payoff in mixed apps.
- **Post-processing**: every full-screen pass is a fixed per-pixel cost. Passes are counted and
  justified one by one.

### Measurement: CPU profiling does not see the GPU bottleneck

This is what is almost always done wrong. The JavaScript *flame chart* shows the main thread; the
GPU works **asynchronously**. If the GPU is saturated, in the CPU profile you will see idle JS and
long frames with no apparent cause — or, worse, you will see time inside an API call that is
actually **waiting** for the GPU queue.

- Diagnostic rule: **if lowering the canvas resolution improves the fps, the bottleneck is on the GPU
  (fragments/fill); if nothing changes, it is on the CPU or in draw calls.** It is the two-minute test
  that avoids days of misdirected optimisation.
- **Chrome DevTools → Performance with the GPU track enabled**, and `chrome://gpu` as the source of truth
  for video memory. The Firefox Profiler for the Gecko equivalent.
- **WebGPU's `timestamp-query`** to measure GPU passes. **It is quantised to 100 µs by default** (it is
  a mitigation against timing attacks); the quantisation is only disabled with the
  `chrome://flags/#enable-webgpu-developer-features` *flag*, which **is not a production environment**. Besides, the
  GPU's counters can reset and produce negative deltas: those are discarded.
- **`timestamp-query` is not enough**: a pass that is fast on the clock may be slow in throughput. The final
  test is real load (increasing the number of objects/resolution until the fps drop).
- Frame capture tools (WebGL/WebGPU state inspector, engine captures) to see
  draw calls, state changes and uploaded textures. Babylon.js's inspector and three.js's development
  tools give the call and triangle counts: **that counter goes in the development HUD
  from day one**.
- Measurement is done **on the target hardware**, and the target hardware includes **a mid-range phone from three
  years ago**. A development laptop measures nothing relevant to the user.

### GPU memory and context loss

- **GPU memory is not managed by the JS garbage collector.** Textures, buffers, geometries,
  render targets and pipelines are **released explicitly** (the engine's `dispose()`, `destroy()` in
  WebGPU). Changing scene without releasing is the most common memory leak in the domain and it ends in
  a lost context or a dead tab.
- **Handling context loss is NOT optional: on mobile it happens.** The browser can drop the
  GPU context because of memory pressure, app switching, suspension, a driver update or simply
  because the system needs the GPU. Without handling, the canvas stays **black forever**.
  - WebGL: listen for **`webglcontextlost`** (and call `event.preventDefault()`, or there will be no restoration)
    and **`webglcontextrestored`** to rebuild **all** GPU resources. `WEBGL_lose_context` is
    Baseline **widely available** and serves to **trigger the loss in a test** — it is tested, you do not
    wait for it to happen in production.
  - WebGPU: `device.lost` is a promise; when it resolves you have to **request a new device** and
    recreate everything. A lost `GPUDevice` is not recovered.
  - The generic `contextlost`/`contextrestored` events on `<canvas>` are **Baseline limited**
    (webstatus.dev: Chrome 99, Firefox 125, **no Safari**): you do not depend on them.
- Texture memory budget **declared** (e.g. "≤ X MB of textures in the scene") and verified
  in the development HUD. On mobile the ceiling is far lower than the device's RAM suggests.

### GPU compute in the browser

WebGPU's *compute shaders* are the first real path to general GPU compute from the web (WebGL2
does not have them: emulating them with *transform feedback* or render-to-texture is a hack). Real cases:
particle and physics simulation, image and video processing, GPU *culling* and sorting,
procedural generation, and **model inference on the client**.

- **Client-side inference**: WebGPU is today the substrate of browser inference libraries. The
  decision of **which model, which quantisation and which evaluation** belongs to `local-inference-standards`; here
  only the substrate: check `navigator.gpu`, check the **adapter's limits**
  (`maxBufferSize`, `maxStorageBufferBindingSize`, `maxComputeWorkgroup*`) before deciding that the model
  fits, and have a written answer for the device without WebGPU (Wasm on CPU, server, or a feature
  not available — but **explained**, not broken).
- A long GPU computation **blocks the GPU that also draws the interface**. It is split into units that
  fit within the frame budget, or you explicitly accept that the UI freezes and you warn about it.
  On mobile it is also battery drain the user notices.
- The result is read back asynchronously (`mapAsync`), never in the frame's critical path.

### Accessibility

- **A canvas is opaque to assistive technology**: it has no structure and no text; to a screen
  reader it is an image with no content. **All information conveyed only by the canvas must exist in
  another form**: fallback content inside the `<canvas>` element, an equivalent table or list,
  a textual description, or an alternative view. A decorative 3D viewer is marked as decorative; a
  chart with data **needs the data**. The conformance criteria (which WCAG level requires what) belong to
  `accessibility-standards`; the technical obligation belongs here.
- Interaction: if it can be done with the mouse inside the canvas, **it must be doable with the keyboard**, and
  focus must be visible. Real HTML controls outside the canvas whenever possible; recreating a
  button by drawing it in pixels is starting accessibility from zero.
- **`prefers-reduced-motion`** (webstatus.dev: **Baseline widely available**, `widely` 2022-07-15) is a
  **real** switch: automatic cameras, parallax, continuous rotations, particles and transitions are
  reduced or stopped. It is not "slowing it down a bit": non-essential animation is turned off.
- No induced epilepsy: no flashes above the thresholds, and no decorative strobes.

### Compatibility and degradation

- **Capability detection, never browser detection.** `if (navigator.gpu)`, then
  `await navigator.gpu.requestAdapter()` — **which can return `null` even if `navigator.gpu` exists**
  (no compatible GPU, blocked driver, software adapter). Also check `adapter.features` and
  `adapter.limits` before assuming anything: **an adapter is not a capability contract**.
- `requestDevice()` can also fail and the device can be lost **immediately**. The whole
  initialisation path is asynchronous and fallible.
- A written degradation chain: **WebGPU → WebGL2 → (optionally) Canvas 2D / static image / alternative
  view**. Every step must be a usable experience, not an error message.
- **No GPU** (software rendering, GPU on the browser's blocklist, very limited device): it is
  detected and the alternative view is offered. Software-rendering a heavy scene turns the
  user's laptop into a radiator and draws nothing useful.
- **WebGL extensions** are checked one by one (`getExtension`) — their support varies far more than
  WebGL2's (see BPTC/RGTC above, both *limited*).

## 4. Quality and CI gates

In order of increasing cost:

1. **Shader compilation in CI**: validate WGSL/GLSL at build time (a shader compilation error is
   a runtime failure and it happens in the user's face). Shaders live in versioned and
   linted files, not in template literals scattered around.
2. **Asset budget**: model and texture size per scene, number of textures, and **fail the
   build** if the declared limit is exceeded. An 80 MB `.glb` comes in through the back door without this gate.
3. **Format verification**: textures in KTX2 (no loose PNG/JPEG in production), geometry with
   compression where applicable, and no 4096² textures for 100 px elements.
4. **Degradation test**: start with WebGPU disabled and check that the WebGL2 path works; and
   with both disabled, that the alternative appears. **Without this test, degradation does not exist: it is
   an intention.**
5. **Context loss test**: force it with `WEBGL_lose_context` (or the WebGPU equivalent) and
   verify that the scene is rebuilt. Automatable and almost nobody does it.
6. **Accessibility test of the alternative**: that the equivalent content exists and is reachable by
   keyboard and by screen reader (tool and criteria → `accessibility-standards`).
7. **Visual regression** of reference frames: useful but **unstable across GPUs and drivers**; you
   pin the environment (same runner, same backend, difference tolerance) or it produces perpetual noise.
8. **Performance regression**: frame time and draw calls on a canonical scene, on fixed
   hardware. A warning, not a failure, except on a large deviation: the variance is real.

## 5. Security

**The GPU is attack surface, and one of the most profitable.** The browser's model is: web content
talks to the GPU process over IPC; that process has driver access, **is less isolated than the
renderer process and is shared between origins**. A bug there is privilege escalation.

Mitigations the browser applies (not yours, but they condition what you can do):
- **Strict validation and shader translation**: WGSL is validated and translated (Tint in Chromium/Dawn,
  wgpu in Firefox, Apple's stack in WebKit) into the native backend's language (D3D12/Metal/Vulkan). A
  shader does not reach the driver raw, and module or pipeline creation **fails before executing** if
  it does not validate.
- **Process isolation** and sanitisation of the IPC messages between the renderer and the GPU process.
- **Quantisation of `timestamp-query` to 100 µs** and no exposure in non-isolated contexts, precisely
  to make timing attacks and GPU cache side channels harder.
- **GPU/driver blocklists**: the browser disables acceleration on configurations
  known to be problematic. That is why `requestAdapter()` can return `null` on a machine with a GPU.

And its real track record, verified on NVD (Aug 2026):
- **CVE-2026-5281**, verbatim: *"Use after free in Dawn in Google Chrome prior to 146.0.7680.178 allowed a
  remote attacker who had compromised the renderer process to execute arbitrary code via a crafted HTML
  page. (Chromium security severity: High)"*
- **CVE-2026-6310**, verbatim: *"Use after free in Dawn in Google Chrome prior to 147.0.7727.101 allowed a
  remote attacker who had compromised the renderer process to potentially perform a sandbox escape via a
  crafted HTML page. (Chromium security severity: High)"*

What this means for your design:
- **Running third-party *shaders* is running untrusted code against the most fragile surface of the
  browser.** A shader uploaded by a user, or fetched from someone else's URL, is not "some text": it is hostile
  input to the shader compiler. If the product allows it (effects editor, community shader
  gallery), it is a **written risk decision**: isolated origin, strict CSP, no
  session and no data on that origin, and with the assumption that a browser bug affects you directly.
  The same with third-party glTF models: they are input for complex *parsers*.
- Updating the browser **is** the main control, and you do not control it. On a managed estate
  (kiosks, terminals), the browser's update policy is part of the system.
- **Fingerprinting**: the GPU is one of the browser's most stable identification signals —
  adapter, limits, supported features and compilation times. Instantiating a WebGL context
  just to "detect capabilities" **is a fingerprinting technique**, intended or not. Legal
  basis, consent and minimisation → `privacy-engineering-standards`.
- **There are no secrets on the client**, and a shader is downloadable text: no licence logic,
  "invisible" watermarks or keys inside the shader or the asset.
- Assets and transcoders are **third-party Wasm on your page**: they are pinned by version, served
  from your origin and follow the supply policy of `frontend-web-platform-standards`.

### Battery and thermals: the real cost on mobile

- The GPU is, along with the screen, the device's biggest consumer. A scene that keeps the GPU at
  100% **heats the phone, makes it downclock (*thermal throttling*) and drains the battery**.
  The characteristic symptom is "it runs fine for 30 seconds and then at half the fps": that is not fixed
  by optimising micro-details, it is fixed by **reducing the work per frame**.
- Mandatory: **stop the render loop when the canvas is not visible**
  (`IntersectionObserver` + `visibilitychange`). A `requestAnimationFrame` that keeps running in a
  background tab or off screen is pure consumption. It is the cheapest optimisation and the most forgotten.
- Render **on demand** (only when something changes) in static or nearly static scenes, instead of
  at a perpetual 60 fps.
- Dynamic resolution scaling and an fps cap as a policy, not as a reaction.

## 6. Performance and operability

- Telemetry from the client (what to instrument; the platform → `observability-standards`):
  chosen backend (WebGPU/WebGL2/alternative), adapter vendor and model **aggregated** (mind
  privacy), frame time p50/p95, **context loss events**, failures of
  `requestAdapter`/`requestDevice`, shader compilation errors and scene load time.
- **Context loss is an operational metric**, not a curiosity: a spike on a specific phone
  model is a memory bug in your scene, and that is how it is discovered.
- Progressive loading: the scene appears in levels (basic geometry → textures → detail), never a
  20-second blank screen. A real progress indicator.
- Budgets declared in the repo: ms per frame, draw calls, MB of textures, MB of assets per
  scene. With no written numbers there is no detectable regression.

## 7. Sustainability and prohibitions

- **Re-evaluate WebGPU support every 6 months** (`webstatus.dev`/MDN): the day it is Baseline widely
  available, the WebGL2 path becomes debt to be retired — with a date, not "someday". Today **it is not**.
- three.js is on `0.x`: the exact revision is pinned, the *Migration Guide* is read at every jump and it is
  updated on a cadence, not all at once after two years. Babylon.js follows semver, but its major cycle is
  real.
- Shaders are code: they are reviewed, commented and tested. A shader copied from a gallery and not
  understood is opaque debt with an unknown GPU cost.
- Every extension, feature or limit behind feature detection carries a written retirement condition.

**FORBIDDEN:**
- ❌ Using WebGL/WebGPU for a data chart that Canvas 2D or SVG solves — you lose accessibility and
  debuggability in exchange for nothing.
- ❌ Shipping WebGPU only, with no degradation to WebGL2: **it is not Baseline** (Linux except Intel Gen12+, Firefox
  Android, Firefox Linux, old browsers).
- ❌ Assuming that `navigator.gpu` implies an adapter: `requestAdapter()` can return `null`.
- ❌ *User agent* detection instead of capability detection.
- ❌ Not handling `webglcontextlost` / `device.lost` — on mobile it happens and it leaves the canvas black. Not calling
  `preventDefault()` in `webglcontextlost` (without it there is no restoration).
- ❌ Not releasing GPU resources when changing scene (`dispose()`/`destroy()`): the GPU has no GC.
- ❌ `requestAnimationFrame` running with the canvas off screen or the tab hidden.
- ❌ Animating per frame instead of per elapsed time: on a 120 Hz panel the scene runs at double speed.
- ❌ Rendering at unlimited `devicePixelRatio` on mobile.
- ❌ Serving uncompressed PNG/JPEG textures for the GPU in production, or 4096² textures for small
  elements; forgetting mipmaps.
- ❌ Synchronous GPU reads (`readPixels` and equivalents) inside the frame loop.
- ❌ A canvas with no accessible alternative when it conveys information; ignoring `prefers-reduced-motion`.
- ❌ Optimising guided only by the CPU profile: **it does not see the GPU bottleneck**. First, the test of lowering
  the resolution.
- ❌ Depending on `chrome://flags/#enable-webgpu-developer-features` or on
  `chromium-experimental-*` extensions for anything that reaches production.
- ❌ Compiling third-party (or user) shaders without a written risk decision and origin isolation.
- ❌ Creating a WebGL context just to profile the device: that is fingerprinting.
- ❌ Two engines managing the GPU context on the same page.
- ❌ Copying WebGPU's support status from memory (or from a blog). It is checked (§8).

## 8. Mandatory web verification

Before pinning anything, check online (WebSearch/WebFetch; **MDN/BCD and `webstatus.dev` for support**,
W3C for the specification's status, NVD for CVEs, GitHub Atom feeds for versions —
**`api.github.com` returns 403 unauthenticated**; licences read from the raw `LICENSE`):

1. **WebGPU support per browser *and per platform*** on `webstatus.dev`/MDN-BCD, not on a blog: today
   **Baseline limited**, with Linux limited to Intel Gen12+ in Chrome, Firefox partial (Windows and macOS
   Tahoe on Apple silicon) and **no Firefox Android**. Check whether it has already changed: it is what decides the
   project's architecture.
2. **Specification status**: WebGPU (CR Draft 14-Jul-2026) and WGSL (CR Draft 16-Jul-2026). Is there a
   Recommendation? New standardised features (subgroups, etc.)?
3. **Versions and licences** of whatever you pin: three.js (`0.185.1`, **MIT**, and still on `0.x`),
   Babylon.js (`@babylonjs/core` `9.19.0`, **Apache-2.0, not MIT**), KTX-Software and basis_universal
   (**Apache-2.0**), and the 2D library you choose. Also check for **maintenance mode or a change of
   ownership**.
4. **Compressed texture extensions** (ASTC widely; BPTC/RGTC **limited**) and the state of the
   KTX2/Basis pipeline, including new transcoder formats that **may not yet be
   standardised in KTX/glTF**.
5. **Browser advisories**: Chrome Releases and NVD for Dawn/GPU/ANGLE CVEs. In 2026 there are several
   UAFs in Dawn (§5). It is context for the decision to expose WebGPU on a managed estate.
6. **Profiling tools**: the state of the GPU track in DevTools, of `timestamp-query` and its
   quantisation, and of the engines' inspectors.
7. **Baseline of the supporting APIs**: `OffscreenCanvas` (widely), `prefers-reduced-motion` (widely),
   `canvas-context-lost` (**limited, no Safari**), WebGL2 (widely).

**Declared gaps, not verified as of Aug 2026** (do not fill them from memory; check before using):
- **WebGPU support in Android WebView and in Chromium-derived browsers** (Samsung Internet,
  Opera; BCD marks them as `mirror`, which does not guarantee real parity per device): **not verified**.
- **WebGPU status in Firefox for Linux and Android** beyond "in development": **not verified**;
  the target dates in circulation come from secondary sources.
- **Version and licence of the accelerated 2D library** (PixiJS or another) from §2: **not verified**, deliberately
  left unpinned.
- **GPU memory quota or ceiling per tab** in each browser: **not verified** and probably not
  documented. The budgets in §6 are project agreements, **not measured data**.
- **WebGPU status in *service workers*** beyond Firefox's note (*"Supports all contexts
  except service workers"*): **not verified** for the other engines.
- **Concrete GPU side-channel mitigations** (compilation caches, WebGPU-SPY and similar work)
  and which browser applies which: **not verified**; the quantisation of `timestamp-query` is
  the only one confirmed by Chromium documentation.
- **The frame figures in §3** (10-12 ms of useful work): a design rule, **not a measurement**; the
  real budget is established by measuring on the target hardware.

**Declared discrepancy**: multiple secondary sources (including "WebGPU 2026" notes) claim that
**WebGPU reached Baseline in January 2026 in all major browsers**. **It is false according to the
primary sources**: `webstatus.dev` classifies `webgpu` as **Baseline limited** (with no Firefox
entry) and MDN labels it, verbatim, *"This feature is not Baseline because it does not work in some of
the most widely-used browsers."* MDN/`webstatus.dev` wins. Second discrepancy: several articles
describe CVE-2026-5281 as *"zero-click"* exploitable by merely visiting a page; **NVD's text
says it requires an attacker *"who had compromised the renderer process"*** (§5) — the difference between
"visiting a website compromises you" and "you need to chain another vulnerability" is the whole risk
assessment. NVD / the Chromium advisory wins.

If the web contradicts this document, **the web wins** — flag the discrepancy.
