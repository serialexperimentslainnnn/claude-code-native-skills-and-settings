---
name: xr-standards
description: Virtual, augmented and mixed reality engineering where comfort, latency and biometric privacy are hard requirements. Use when building with OpenXR (xrCreateInstance, XrSession, XrSpace, xrWaitFrame/xrBeginFrame/xrEndFrame, XR_KHR_composition_layer_depth, XR_EXT_hand_tracking, XR_EXT_eye_gaze_interaction, XR_EXT_plane_detection, XR_EXT_spatial_anchor, vendor XR_FB_/XR_META_/XR_ANDROID_ extensions), Unity XR Interaction Toolkit and OpenXR plugin, Unreal VR templates and OpenXR runtime, Godot XR, or WebXR (navigator.xr, requestSession("immersive-vr"/"immersive-ar"), XRReferenceSpace, hit-test and anchors), motion-to-photon latency, reprojection, timewarp, Application SpaceWarp and stale frames, headset refresh rates and per-frame budget on standalone hardware, locomotion, teleport, snap turn, vignette and simulator sickness, room-scale guardian and boundary, seated versus standing play, hand tracking versus controllers, raycast interaction, gaze and pinch, passthrough and scene understanding, spatial anchors and a persisted 3D mesh of the user's home, eye or face tracking data and emotion inference under the EU AI Act, Quest store VRC submission checks, or spatial audio and spatial subtitles.
---

# XR standards (virtual, augmented and mixed reality)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Sets the engineering criteria for **building an application worn on your head**: frame budget and
latency, comfort and motion sickness as a functional requirement, standard API versus vendor
extension, interaction with hands and controllers, accessibility in a medium that assumes one
specific body, and **the privacy of the data that only exists in XR** — gaze, face, body and a
three-dimensional map of the user's home.

**The domain's axis: comfort and safety are not polish, they are a functional requirement.** On a
screen, a dropped frame is an annoyance; on your head, **it is a physical symptom**. A game with bad
physics plays badly; an XR application that makes people dizzy **does not get used** — the headset
comes off and does not go back on. That is why the order of priorities is rigid and not negotiated
with design:

1. **A stable frame rate within the device's budget** — not "high on average".
2. **Minimum motion-to-photon latency**: the image must respond to the head before the inner ear
   notices the lag.
3. **No acceleration imposed on the user**: not of the camera, not of the horizon, not of the scale.
4. And only then: visual fidelity, content and features.

**Golden rule, the most broken one: do not move the user's camera unless the user moved it.** No
cutscenes that turn the head, no camera shake, no weapon recoil that rotates the view, no imposed
"smoothing" on collision, no fade that drags the horizon. The vector of motion sickness is the
**conflict between what the eye sees and what the inner ear feels**; any movement the body did not
command is a dose of that conflict.

**Reprojection is a safety net, not a plan.** *Timewarp*/*reprojection* and their variants
(*Application SpaceWarp* and equivalents) rescue the occasional dropped frame by generating a
synthetic one from the previous frame; used as a design budget they produce visible artifacts
(trails, torn edges, ghosting on fast objects) and they do not fix simulation latency. **Design to
meet the budget without them.**

Triggers: `xrCreateInstance`, `XrSession`, `XrSpace`, `xrWaitFrame`, `xrEndFrame`,
`XR_EXT_hand_tracking`, `XR_EXT_eye_gaze_interaction`, `XR_EXT_plane_detection`,
`XR_EXT_spatial_anchor`, `XR_FB_*`/`XR_META_*`/`XR_ANDROID_*`, `com.oculus.permission.USE_SCENE`,
`XRInteractionManager`, `XROrigin`, `navigator.xr`, `requestSession('immersive-vr')`,
`XRReferenceSpace`, `local-floor`, `hit-test`, OVR Metrics Tool, *stale frames*, store VRCs, and the
symptoms: "it makes me sick", "it stutters when I turn my head", "the hands lag", "it does not
detect the floor", "the headset comes off after 10 minutes".

**Not applicable**: see `game-development-standards` (**batch 22, direct sister and the main
boundary**: **the engine, the game loop, the fixed timestep, ECS, *pooling*, asset *streaming*,
multiplayer with server authority, binary version control, certification and monetisation are
theirs**. **Here what changes because it is worn**: budget and stability per device, comfort,
locomotion, spatial interaction, XR accessibility and biometric privacy. Arbitration rule: *if the
answer would be the same on a flat screen, it belongs to `game-development`; if it changes because
the user has the device on their head, it belongs here*), `webgl-webgpu-standards` (**the browser
and the graphics API are theirs without exception**: WebGL2/WebGPU, WGSL/GLSL, three.js/Babylon,
context loss, compressed textures. **WebXR rests on them: here the session model, reference spaces,
input and comfort; there what is drawn and what it costs**), `computer-vision-standards` (**SLAM,
*inside-out* tracking, reconstruction, plane and marker detection, and any perception model are
theirs**; here only **consuming** the result the runtime exposes — anchors, meshes, planes — and the
obligations that data brings), `mobile-standards` (Android packaging, permissions, app lifecycle and
store policy; a standalone headset is an Android with rules of its own), `cpp-standards` /
`c-standards` (the language of the *loader* and the extensions), `dotnet-standards` (C# outside
Unity), `accessibility-standards` (**the WCAG and EN 301 549 conformance criterion and its legal
scope are theirs**; **here what WCAG does not cover**: height, reach, dominant hand, seated/standing,
spatial subtitles), `i18n-standards` (translation, formats and vendor; here only the spatial cost of
text), `privacy-engineering-standards` (**the privacy discipline — legal basis, DPIA, minimisation,
data subject rights, retention — is theirs, in full**. **Here only XR's differentiating fact**: which
sensors exist, what is derived from them and what is forbidden to capture. Gaze data processing is
**designed** with this skill and **governed** with theirs), `ai-governance-standards` (**the AI Act
as a compliance framework — inventory, provider and deployer roles, assessments, governance — is
theirs**; here only the concrete trigger: emotion inference from biometrics),
`deep-learning-standards` and `local-inference-standards` (training and serving models),
`performance-engineering-standards` (profiling methodology), `gaming-infrastructure-standards`
(servers and multi-user sessions), `frontend-web-platform-standards` (the page hosting the WebXR
experience), `embedded-iot-standards` (the device as a physical object; here third-party hardware is
assumed).

## 2. Default decisions / Toolchain

> Verify the latest version, the current device catalogue and their refresh rates on the web before
> fixing them in a real project (§8). **The XR hardware catalogue rotates fast and the sales figures
> in circulation are not verifiable: they are not cited.**

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Device API | **OpenXR** | Proprietary SDK | Khronos standard; avoids rewriting per vendor |
| Vendor extensions | Only after proven degradation | — | Every `XR_FB_`/`XR_META_` is coupling |
| Engine | Unity + XR Interaction Toolkit / Unreal / Godot XR | Native with OpenXR + Vulkan | Tooling and interaction already solved |
| Performance target | **p99 ms within the device's budget** | — | A dropped frame is felt in the body |
| Default locomotion | **Teleport + *snap turn*** | Continuous **as an option** with vignetting | Less vestibular conflict |
| Reference frame | `local-floor`/*stage* with height calibration | `local` seated | Correct scale and floor |
| Input | **Controllers** as the primary path | Hands as an alternative | Reliability, precision and fatigue |
| Distance interaction | *Raycast* with clear feedback | Direct interaction (near) | Ergonomics of reach |
| Gaze as input | **Only with explicit confirmation** | — | Gaze is not an intent |
| Gaze/face data | **Does not leave the device** | Never by default | Biometrics §5 |
| Web | **WebXR** when it suffices and reach matters | Native when performance matters | Distribution without a store |
| Reprojection | Safety net | — | It is not a design budget |

**Verified status of the standard (August 2026):**

- **OpenXR** publishes its specification on the **1.1** line (`registry.khronos.org/OpenXR/`:
  *«OpenXR 1.1 API Specifications (also applies to 1.0 development)»*; 1.0.34 appears marked
  *Obsolete*). Latest SDK release verified via the releases Atom feed: **OpenXR SDK 1.1.62**.
- **What falls outside the standard, with a figure and a method**: counting the extensions declared
  in the official registry `specification/registry/xr.xml` (`main` branch of `OpenXR-SDK`, excluding
  reserved placeholders of the `XR_META_extension_NNN` kind), there are **261 extensions with a real
  name**, of which only **35 are `XR_KHR_`** and **38 `XR_EXT_`** (multi-vendor). The **remaining 188
  are vendor-specific**: `XR_FB_` 41, `XR_META_` 34, `XR_ANDROID_` 27, `XR_BD_` 16, `XR_MSFT_` 15,
  `XR_ML_` 13, `XR_HTC_` 9, `XR_VARJO_` 7, `XR_QCOM_` 6… **Reading**: OpenXR standardises the core
  well — session, spaces, layers, input, frame cycle — and **almost everything differentiating
  (passthrough, scene mesh, face and body tracking, shared anchors, *depth*) still arrives via vendor
  extension**. Real portability = standard core + your own abstraction layer over whatever extension
  is used + **proven degradation** when the extension is absent.
- **WebXR Device API**: **W3C Candidate Recommendation Draft of 9 June 2026** (`w3.org/TR/webxr/`).
  That is: a standard in progress, not a Recommendation; browser and platform support **is checked
  before promising it**, and the modules (AR, *hit test*, anchors, layers, hands) go through separate
  specifications with different maturity.
- **Frame budget per device — verified normative data.** Meta store requirement
  `VRC.Quest.Performance.1` (updated 2025-10-22), verbatim: *«The app must run at an allowed refresh
  rate and maintain a rendering rate (fps) of at least 60 fps»*, *«Interactive applications must use
  a refresh rate of 72 Hz, 80 Hz, 90 Hz, 96 Hz, 100 Hz or 120 Hz (96 Hz, 100 Hz, and 120 Hz not
  available on all devices)»* and *«Media applications may use a refresh of 60 Hz on devices that
  support 60 Hz»*. The same vendor's Unity performance guide additionally states: *«Interactive
  applications must achieve a minimum of 72 FPS»*. **Translated into a budget**: 72 Hz → **13.9 ms**;
  80 Hz → 12.5 ms; 90 Hz → **11.1 ms**; 120 Hz → 8.3 ms **per frame, for everything** (simulation,
  physics, animation, culling, two eyes of rendering, composition, audio, networking). And **per
  eye**: the render cost is paid twice unless single-pass rendering (*single-pass
  instanced*/*multiview*) is used, which is the correct default setting.
- **Documented exception**: the same VRC allows *«a rendering rate (fps) of half the refresh rate
  (such as … 36 fps for 72 Hz), for portions of their experience utilizing Application SpaceWarp»*
  and requires generating motion vectors that minimise artifacts. **It is an exception with
  conditions, not a licence to design at half budget.**
- **Other vendors**: each store has its own equivalent requirements document. **Do not assume one
  vendor's applies to another**: read the target's before fixing the goal (§8).

## 3. Structure and conventions

**Loop and synchronisation.** The OpenXR cycle (`xrWaitFrame` → `xrBeginFrame` → render →
`xrEndFrame`) is governed by **the runtime**, not the application: `xrWaitFrame` is what decides when
to begin and delivers the `predictedDisplayTime`. Rules:

- **Every pose is queried for the predicted display time**, not for "now". Using the previous frame's
  pose or the system clock introduces latency and *judder*.
- **Never block the render thread**: asset loading, networking, decoding and heavy physics go
  elsewhere. A 30 ms block is a dropped frame, and a dropped frame is a jolt in the head.
- **Always submit composition layers with correct depth** (`XR_KHR_composition_layer_depth` where
  available): reprojection works much better with depth.
- **The UI is not stuck to the face.** Interface anchored to the world or to the body, at a
  comfortable reading distance, with sufficient angular text size. A *head-locked* UI causes sickness
  and is the hallmark of the lazy port from a flat screen.

**Reference spaces and scale.** Declare explicitly which one is used (`local`, `local-floor`,
`stage`/*bounded*) and **respect 1:1 scale**: a virtual metre is a real metre. Changing the world's
scale or the interpupillary distance without reason breaks depth perception and causes sickness. The
play boundary (*guardian*) is a **physical safety** feature: never hide it, never incite the user to
step outside it, plan for the small-space case.

**Locomotion — a catalogue with criteria:**

- **Teleport** with a destination indicator: the most comfortable, with almost no vestibular
  conflict. The default.
- **Snap turn** (30°/45°) versus continuous turn: snap by default; continuous as an option.
- **Continuous locomotion**: only as an **opt-in option**, with **dynamic vignetting** (reducing the
  peripheral field of view while moving), constant speed and **no acceleration** (acceleration is
  what causes sickness, not speed), with no strafing combined with turning.
- **A static reference frame** (cockpit, virtual nose, grid or frame fixed relative to the body) when
  movement is unavoidable: it reduces the conflict by giving the eye a reference that does not move.
  It is why driving/flight simulators are comfortable.
- **Always forbidden**: stairs/ramps that sway the camera, *head bobbing*, uncommanded vertical
  movement, long free falls, and taking view control away from the user.
- **All of the above is offered as a setting**, with conservative defaults, accessible at any moment
  **without leaving the application**.

**Interaction.**

- **Controllers** for what demands precision, haptic feedback and low fatigue. **Hands** for social,
  short or accessory-free interaction: tracking fails under occlusion, in low light and outside the
  cameras' field of view, so **every hand interaction needs an alternative path** and tolerance to
  tracking loss.
- ***Gorilla arm* is a design requirement**: no holding the arm up, no repeated gestures; short
  interactions, at chest height, with rest.
- **Multimodal feedback**: every targeted object is highlighted, every action confirms with sound
  and/or haptics. In XR, without feedback the user does not know whether the system heard them.
- **Gaze is not a click.** With eye tracking, gaze may select but **another gesture confirms** (pinch,
  button). *Dwell* (holding the gaze) only as an explicit accessibility option.
- **Comfort zone**: interactive content within reach without moving; nothing critical above the head,
  below the waist or behind the user. If something important is outside the field of view, it must be
  **indicated** (spatial audio, arrow, halo).

**Spatial audio** as part of the simulation, not as decoration: it is the channel that places what is
out of sight and reduces neck work. With occlusion and reverberation consistent with the scene.

## 4. Quality and testing

- **Profile on the device, in a release build, always.** The editor with a headset preview does not
  measure what the device measures: thermals, mobile GPU, real resolution and composition. On
  standalone hardware, moreover, **performance degrades with heat**: a valid test lasts **more than
  15–20 minutes**, not two.
- **Metrics**: p99 frame time, **dropped frames and *stale frames*** (frames repeated by the
  compositor), and the level of CPU/GPU thermal *throttling*. Average fps is worthless.
- **Comfort testing with people**, including people with no prior XR experience and people prone to
  motion sickness: **the development team's tolerance is the worst possible reference** (habituation).
  Timed sessions, with the option to stop at any moment, and a symptom log. **No figure of the "X% get
  sick" kind is cited without a study and its methodology: that is industry folklore.**
- **A mandatory physical test matrix**: standing and seated; a large space and a 1×1 m space; a tall
  user and a short user (or a user seated in a wheelchair); left-handed and right-handed; with
  glasses; in low light and in direct light (it affects *inside-out* tracking); taking the headset
  off and putting it back on mid-session; losing tracking of one hand; a controller with a dead
  battery.
- **Extension degradation**: a test that boots with vendor extensions disabled and verifies the
  application works or degrades cleanly.
- **CI gates in order of cost**: static analysis → logic tests without the headset → per-platform
  build → a reference scene measured on-device with a threshold in ms → automated check of store
  requirements (VRC/equivalent) → a comfort session with people.
- **Before submitting to a store**: go through the vendor's full requirements list. The most frequent
  failures are not render technicalities, they are policy — privacy, age rating, content, metadata.

## 5. Stack security

**This is where XR separates from everything else in the catalogue: the sensors it needs to work are
sensors for bodily and domestic surveillance.** The headset measures where you look, how much your
pupils dilate, how your face moves, how your body moves and **what the room you live in looks like
inside**. None of that is "telemetry".

- **Gaze (*eye tracking*)**: it reveals attention, interest, cognitive load and — according to the
  literature — allows identifying a person by their eye movement pattern. **Hard criterion: gaze data
  is processed on the device and does not leave it.** If the use case is *foveated rendering* or
  aiming, the application needs the current vector, **not the history**: it is not stored, not
  logged, not transmitted, not used for advertising nor for attention analytics.
- **Face and body**: facial expression and posture are behavioural data derived from biometric
  sensors. Same criterion: local, ephemeral, with a declared purpose (avatar) and with no persistence.
- **3D map of the home**: the scene mesh, the planes and the spatial anchors are **a floor plan of the
  user's house**, with furniture, size and sometimes contents. On Meta's platform access sits behind
  an explicit runtime permission — `com.oculus.permission.USE_SCENE`, declared in the
  `AndroidManifest.xml`, with a consent dialog — and the documentation requires **planning the
  alternative path if the user denies it**. Criterion: **ask for it only when it is used, explain it
  at that moment, work without it and never export it off the device**. Uploading a scene mesh to
  your own server is processing that requires a legal basis, a DPIA and minimisation
  (`privacy-engineering-standards`).
- ***Passthrough* cameras** and camera frame access: it is a domestic camera with everything that
  implies — including non-consenting third parties in the scene. It is treated as a camera, with a
  visible capture indicator and no silent recording.
- **Legal framework, verbatim from the source:**
  - **GDPR, art. 4(14)**: *«‘biometric data’ means personal data resulting from specific technical
    processing relating to the physical, physiological or behavioural characteristics of a natural
    person, which allow or confirm the unique identification of that natural person…»*. **Art. 9(1)**:
    the processing of *«biometric data for the purpose of uniquely identifying a natural person»*
    **is prohibited** save for an exception under 9(2) — explicit consent among them. That is: gaze
    or face data **is not automatically art. 9**; it becomes so **when it is used to uniquely
    identify**. The practical consequence does not change: it is personal data that is sensitive by
    context, and the correct design is that it is not persisted.
  - **AI Regulation (EU) 2024/1689 — emotion inference**. Definition (art. 3): *«‘emotion recognition
    system’ means an AI system for the purpose of identifying or inferring emotions or intentions of
    natural persons on the basis of their biometric data»*. **Prohibition (art. 5)**, verbatim: *«the
    placing on the market, the putting into service for this specific purpose, or the use of AI
    systems to infer emotions of a natural person in the areas of workplace and education
    institutions, except where the use of the AI system is intended to be put in place or into the
    market for medical or safety reasons»*. Outside work and education it **is not prohibited, but it
    is high risk**: Annex III lists *«AI systems intended to be used for emotion recognition»*. And
    art. 50(3) requires: *«Deployers of an emotion recognition system or a biometric categorisation
    system shall inform the natural persons exposed thereto of the operation of the system»*. The
    Regulation itself warns in its recitals that there are *«serious concerns about the scientific
    basis of AI systems aiming to identify or infer emotions»*. **Engineering translation**: a
    "detect how the user feels" feature based on face, gaze or voice is, in workplace training or
    education in the EU, **illegal**; in every other case it drags in the high-risk regime and the
    duty to inform. **It is not implemented without going through `ai-governance-standards`.**
- **Minors**: headsets have minimum ages and child account modes. Content, voice chat, data capture
  and advertising change regime. Verify the platform's policy and the child protection framework
  before designing social features.
- **Verified store requirement** (`VRC.Quest.Privacy.4`, updated 2026-04-08): the privacy policy must
  explain how **any** user requests deletion of their data, and *«Requiring users to pay a fee for
  deletion of user data is prohibited»*. It is also, according to the vendor itself, **one of the most
  frequently failed requirements**.
- **The classic surface that does not disappear just because it is XR**: multiplayer with server
  authority and a hostile client (`game-development-standards` §5), keys embedded in the binary,
  user-downloaded content, and **harassment in social spaces** — which in XR is bodily (invasion of
  personal space): a personal bubble, muting, blocking and reporting are safety features, not
  community features.

## 6. Performance and operability

- **Double cost per eye**: enable single-pass instanced rendering (*single-pass
  instanced*/multiview) by default; measure whether you are paying twice by mistake.
- **Real levers on standalone hardware**, in order of return: reduce *draw calls* and material
  changes (static/dynamic batching, atlases), dynamic resolution and *foveation* (fixed or
  gaze-driven), simple mobile *shaders* with no overdraw (**overdraw with transparencies is killer
  number one**), *lightmaps* instead of dynamic lighting, aggressive LOD, and avoiding full-screen
  post-processing. Geometry is rarely the bottleneck; fill rate and calls almost always are.
- **Thermals**: a standalone device throttles itself. Measure with a long session and leave headroom
  (~10–20%) over the nominal budget; no design that depends on running at 99% of the budget survives
  minute 20.
- **Session telemetry** (with consent): frame time, dropped frames, *throttling*, session duration
  and **early abandonment**. A spike of drop-offs in the first few minutes is the signature of motion
  sickness, not of the plot.
- **Start-up and resumption**: the user takes the headset off and puts it back on constantly; save and
  restore state, pause without punishment, do not lose progress on losing focus.
- **Battery and weight**: the typical session does not last hours. Design experiences with natural
  exit points every few minutes.
- **Accessibility in XR** — enforceable minimums, and none of them optional:
  - **Adjustable height and reach**: height recalibration without leaving the app; everything
    interactive reachable **seated**; a real seated mode (not "standing but shorter").
  - **Configurable dominant hand** and every action available with **one hand**.
  - **An alternative to physically turning around**: controller turning always available (not
    everyone can turn 360°, nor has the room).
  - **Configurable locomotion** (teleport/continuous, vignetting, snap/continuous turn, speed).
  - **Spatial subtitles**: legible, with an indication of the speaker's direction when out of sight;
    adjustable size and contrast; no *head-locked* subtitle stuck to the face.
  - **No requirement for stereo hearing or binocular vision**: do not encode information **only** in
    spatial audio nor **only** in stereoscopic depth.
  - **No requirement for fine gestures, strength or speed**; adjustable timeouts; *dwell* as an
    alternative to pressing.
  - **Photosensitivity**: no flashes and no fast high-contrast patterns; an option to reduce effects.

## 7. Long-term sustainability

- **Portability as an architectural decision**: a core on OpenXR, and **a thin layer of your own**
  over every vendor extension used, with a documented *no-op* implementation. Today's flagship device
  gets discontinued; the proprietary SDK that saved two weeks costs the entire port.
- **Cadence**: the vendor's runtime updates itself on the user's device. Test against the new runtime
  version **before** it reaches the public (test channels) and pin the SDK/plugin version in the repo
  and in CI.
- **Deprecation**: `XR_FB_*` extensions have gradually been replaced by `XR_META_*` and some features
  by already-standardised `XR_EXT_*`. Review at every bump what has been promoted to the core and
  migrate towards the standard, not away from it.
- **Document in an ADR**: target devices and their budget, non-standard extensions used and why,
  locomotion and comfort decisions, and **which sensor data is touched and on what legal basis**.

**Explicit prohibitions:**

- ❌ **Moving, rotating, tilting or shaking the user's camera** by application decision. Includes
  *head bobbing*, weapon recoil, cutscenes that turn the view and physical "shoves".
- ❌ Designing while counting on reprojection/*SpaceWarp* to hit the budget.
- ❌ Setting the target in **average fps** or measuring only in the editor and on the development PC.
- ❌ Acceleration in continuous locomotion, or continuous locomotion **without** a teleport
  alternative and **without** configurable vignetting.
- ❌ A *head-locked* UI, small text at the wrong reading distance, or menus that force neck rotation.
- ❌ Hiding, disabling or encouraging the user to ignore the play boundary (*guardian*).
- ❌ **Storing, logging or transmitting gaze, facial expression, body or scene mesh data.** Neither
  "anonymised", nor "to improve the product".
- ❌ **Inferring emotions or psychological state** from biometrics in a workplace or educational
  context in the EU (art. 5 prohibition of the AI Regulation), and doing so in any other context
  without high-risk governance and without informing the person (Annex III and art. 50(3)).
- ❌ Requesting the spatial data permission at start-up "just in case", with no explanation and no
  alternative path if denied.
- ❌ Recording *passthrough* or camera without a visible indicator.
- ❌ Assuming a standard body: a standing user, two functional hands, 1.75 m, no glasses, with 2×2 m
  free. It is the medium's default exclusion.
- ❌ Blocking the render thread with asset loading, networking or heavy physics.
- ❌ Depending on a vendor extension with no proven degradation path.
- ❌ Citing motion sickness, market share or device sales figures without a study and its
  methodology.
- ❌ Porting a flat-screen application to XR keeping its camera, UI and pacing. It is the origin of
  95% of bad experiences… a figure which, by the way, **also has no source: do not repeat it**.

## 8. Mandatory web verification

Before deciding, check against the primary source:

1. **OpenXR**: the current specification version at `registry.khronos.org/OpenXR/` (verified: the
   **1.1** line) and the latest SDK release (verified: **1.1.62**). Review in
   `specification/registry/xr.xml` which extensions have been promoted to `XR_EXT_`/`XR_KHR_` since
   last time: **it is the only reliable way to know what has stopped being proprietary**.
2. **Budget per device**: the technical requirements document of **each target store** (only Meta's
   verified: `VRC.Quest.Performance.1`, allowed rates and a 60 fps minimum with the AppSW exception).
   **Declared gap**: it has not been possible to verify against a primary source the target refresh
   rate nor the equivalent requirements document for **visionOS/Apple Vision Pro** nor for other
   vendors (JavaScript-rendered pages, no retrievable text); **verify before fixing a target on those
   platforms**.
3. **WebXR**: the document's status at `w3.org/TR/webxr/` (verified: **Candidate Recommendation
   Draft, 2026-06-09**) and real browser/platform support for the modules you intend to use (AR, *hit
   test*, anchors, layers, hands) — Safari/visionOS and Android headset support is what changes most.
4. **Device catalogue**: current models, supported rates, resolution, sensors (gaze, face, body) and
   minimum ages. **Do not marry a vendor and do not cite sales.**
5. **AI Regulation (EU) 2024/1689**: the consolidated text on EUR-Lex and **the application dates in
   force** — they have been amended by the digital omnibus package; the correct timetable is set by
   `ai-governance-standards`, not by this document.
6. **GDPR**: AEPD and EDPB guidance on biometrics and sensor-derived data; the interpretation of
   "unique identification" is what decides whether art. 9 applies.
7. **Store privacy and publishing requirements** (verified: `VRC.Quest.Privacy.4`, 2026-04-08) and
   each platform's policy on minors.
8. **CVEs and advisories** for the runtime, the OpenXR *loader*, the engine and vendor SDKs.

If the web contradicts this document, **the web wins** — flag the discrepancy.
