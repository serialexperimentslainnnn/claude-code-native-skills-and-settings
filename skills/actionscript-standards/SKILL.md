---
name: actionscript-standards
description: ActionScript, Flash and AIR - a dead runtime, its surviving artifacts and the exit route. Use when working with .as, .fla, .swf, .swc, .flv, .f4v, .abc (ActionScript Byte Code), .mxml or .air files, ActionScript 2 versus ActionScript 3 and AVM1/AVM2, the Flex SDK and Apache Flex, Apache Royale as the Flex migration path, mxmlc/compc/asc2 compilers, air-sdk-description.xml and AIR application descriptors, ADT packaging and adl, HARMAN Adobe AIR SDK licensing tiers and air.system.License, Adobe Animate documents and HTML5 Canvas export, Flash Player projectors and the standalone player, ExternalInterface, crossdomain.xml, allowScriptAccess, Ruffle emulation of AVM1/AVM2 content, or auditing, archiving, isolating or removing Flash content from an estate.
---

# ActionScript, Flash and AIR standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**Flash is dead. That is not an opinion nor a forecast: it is a fact with two Adobe dates, quoted
verbatim from their end-of-life page:**

> *"Adobe stopped supporting Flash Player beginning December 31, 2020 ("EOL Date")"*
> *"Adobe blocked Flash content from running in Flash Player beginning January 12, 2021"*

**Security framing, which is the one this skill enforces: a served `.swf` and a Flash runtime
installed on a corporate network in 2026 are not "tolerable legacy", they are a vulnerability
finding.** The runtime has gone more than five years without patches, its exploitation record was the
worst in the industry (for a decade it was the preferred vector of *exploit kits*), and the versions
that still work **are precisely the ones where someone disabled the block or installed them from an
unofficial source** — that is, a binary with no provenance. Treat it as such: inventory, risk,
retirement plan with a date.

**So why does this skill exist? Because of what still exists:**
1. **Artifacts**: `.swf`, `.fla`, `.as`, `.swc` in repositories, intranets, training material, SCORM
   courses, SCADA/HMI systems and kiosks. You have to **know how to read them to decide what to do
   with them**, and often to reconstruct the content they represent.
2. **Adobe AIR**, which **did not die with Flash**: HARMAN maintains and licenses it (§2). There are
   desktop and mobile applications in production written in ActionScript 3 on AIR, and their owners
   need support and cost criteria, not a sermon.
3. **Preservation and archiving**: cultural, historical and institutional content that only exists as
   `.swf` and is preserved through emulation (§7), not with the original runtime.

**Nothing new is written in ActionScript for the web.** For AIR, maintaining and updating an existing
application is legitimate; starting a new one is not (§7).

**Not applicable**: see `frontend-web-platform-standards` (**the default destination of all
interactive Flash content**: HTML, CSS, browser APIs, Canvas, load budget and client security),
`webgl-webgpu-standards` (**the destination of what was accelerated graphics or Stage3D**: canvas,
GPU pipeline and frame budget), `webassembly-standards` (**the destination of ported engines and of
the Ruffle runtime**: the module, its sandbox and its size are theirs),
`frontend-frameworks-standards` and `typescript-standards` (**the destination language and framework
of a rewrite**: ActionScript 3 and TypeScript share an ancestor —ECMAScript 4— and that makes the
translation *deceptively* easy, but the display list model, the events and the lifecycle have no
equivalent: it is not a port, it is a rewrite), `mobile-standards` (**if the destination of an AIR
app is native iOS/Android**), `dart-standards` (**Flutter as a cross-platform destination**),
`vulnerability-management-standards` (**the inventory, triage and retirement SLA process is theirs**;
here, why this asset enters it with priority), `appsec-standards` (threat modeling and vulnerability
classes), `detection-engineering-standards` and `soc-operations-standards` (detecting Flash execution
across the estate), `linux-hardening-standards`, `macos-fleet-standards` and
`windows-server-ad-standards` (**removing the runtime from the estate is theirs**),
`knowledge-management-standards` (documentary preservation), `refactoring-tech-debt-standards`
(*strangler fig* and characterization), `enterprise-architecture-standards` (portfolio and the
decision to retire), `legacy-modernization-standards` (**umbrella skill**: which "R" is chosen for the
Flash/AIR asset —freeze and contain, rewrite or retire— and the dated cost of doing nothing) and
`migration-projects-standards` (**the execution of the cutover** once decided: rehearsal, window,
rollback and decommissioning date of the content and of the runtime),
`opensource-licensing-standards` (licensing; here, AIR's, §2),
`jsp-struts-standards`, `classic-asp-standards`, `coldfusion-standards` and `vb6-standards` (**other
dead or frozen technologies in the catalog, with different problems**: there the server still
executes; **here the problem is that the client can no longer execute anything**, and that changes the
whole strategy — do not extrapolate criteria between them).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criteria | Verified note (Aug 2026) |
|---|---|---|
| Flash Player | **Remove from the estate. No exceptions, no "until we migrate"** | Unsupported since **31-Dec-2020**; content blocked since **12-Jan-2021** (verbatim quotes in §1). Any player that still works is outside the official channel |
| `.swf` content that must still be viewed | **Ruffle**, emulator in Rust/Wasm, **isolated** | **Very active** (daily *nightly* builds, the latest on 5-Aug-2026) and **with no stable release**: it is consumed via nightly, with everything that implies for reproducibility. **Partial compatibility, and it has to be said**: their own page states **AVM1 (AS1/AS2): language 99 %, API 82 %**; **AVM2 (AS3): language 90 %, API 80 %**, with *"decent support for AVM 2 … most games will work well enough to be played"*. **It is not a transparent replacement for the player**: it is an access and preservation route |
| Adobe AIR | **Alive, under HARMAN, and paid** | Still maintained and updated for current OSes. **Annual subscription licensing model with four tiers —`enterprise`, `professional`, `basic`, `free`— verified in the official API reference for `air.system.License`**, which also exposes `expiryDate`, `numberOfSeats` and `checkDetailsOnline`: **the runtime itself checks the license**. The free tier imposes a **HARMAN/Adobe branded splash screen** and provides no support. **Prices are on request: license cost and its renewal is the expensive data point of this skill** |
| AIR SDK version | **51.x series** | **Declared gap: I could not verify it at the official source** — HARMAN's site is a SPA that does not serve the data in HTML. Check it in their authenticated portal; **do not pin it from a secondary source** (§8) |
| Flex applications | **Apache Royale** is the documented migration route (compiles MXML and AS3 to JavaScript) | **Latest verified release: 0.9.12, from 11-Dec-2024** — more than a year and a half without a release, and still at `0.x` after years. **It is an exit route, not a destination platform**: use it to reduce the cost of converting a large Flex codebase, with the explicit commitment to end up in HTML/TS |
| Apache Flex / Flex SDK | **End of the road** | Only to compile and analyze what exists. Nothing new |
| AS2 (AVM1) versus AS3 (AVM2) | **They are different languages and virtual machines**, not two versions | AS2 is weakly typed, with `_root`/`_global`, *timeline scripting* and `on(...)` on clips: there is no mechanical migration to AS3. AS3 has classes, packages, typing, `Event`/`EventDispatcher` and a display list. **AS2 is only touched to archive** |
| `.fla` | **Proprietary Adobe Animate format**, not text | It is not versionable nor reviewable in Git. The code lives in external `.as` files; the `.fla` is the design asset. **Adobe Animate still exists and exports to HTML5 Canvas/WebGL: it is the route for animation content** — verify its status and its licensing before committing (§8) |
| `.swf` as a format | **Public specification and decompilable binary** | A `.swf` **protects nothing**: ABC bytecode decompilable with common tools. If it contains a key, an internal endpoint or sensitive business logic, **that is already exposed** (§5) |

## 3. Stack security

*(This skill replaces the canonical §5 with this block: in a dead technology, security **is** the
criteria, not one more section.)*

- **Mandatory posture: the Flash runtime is removed; the content is isolated or converted.** There is
  no "update to a patched version": it does not exist.
- **A hosted `.swf` is an asset to inventory**, even if nobody can execute it any more: it is served,
  indexed and **can be downloaded and decompiled**. Before archiving or publishing it, review it for
  **embedded credentials, tokens, internal endpoints, paths and authorization logic** — it is an
  extremely frequent finding, because for years the `.swf` was assumed to be opaque.
- **`crossdomain.xml` is a cross-origin policy that is still alive on your server.** A
  `crossdomain.xml` with `allow-access-from domain="*"` at the root of an authenticated domain is a
  vulnerability **that does not depend on Flash existing**: other clients honour it and it still
  documents your surface. **Delete it if it no longer serves any purpose**, and never with a wildcard.
- **`allowScriptAccess`, `allowDomain`, `ExternalInterface`** describe a bidirectional bridge between
  untrusted content and the DOM. If embedded content remains, that bridge is an XSS with extra steps.
- **Ruffle does not eliminate the risk, it bounds it**: it is an emulator that executes untrusted
  content, and its surface is that of an interpreter written in Rust and compiled to Wasm. Serve
  **archived and known content**, from an **isolated origin** (your own subdomain, without session
  cookies, with a restrictive CSP), never from the domain of the authenticated application. Its
  sandbox and limits criteria belong to `webassembly-standards`.
- **"Portable" players, *projectors* and patches to bypass Adobe's block: forbidden.**
  They are binaries of unknown provenance distributed precisely to reactivate a runtime
  blocked by its manufacturer. Detect them in the estate and remove them (`detection-engineering-standards`).
- **AIR**: the packaged application **includes the runtime**. Updating AIR means **repackaging and
  redistributing the application**; if you do not, your users run an old runtime even if HARMAN has
  published the fix. Explicit repackaging cadence, and application signing with a valid, rotated
  certificate.

*§4 and §6 are deliberately omitted*: there is no live testing or operability practice to set for a
retired platform. What does apply —tests and CI of the AIR application you keep maintaining, and of
the migration destination— belongs to `testing-qa-standards`, `cicd-standards` and to the destination
language's skill.

## 7. Exit route and prohibitions

**There is no "maintain" strategy: there is an exit route.** Choose by content type:

| What it is | Destination |
|---|---|
| Animation or training material | Re-export from the original `.fla` to **HTML5 Canvas/WebGL** (Animate) or redo it as video if it is linear. **Without the `.fla`, it is reconstruction, not conversion** |
| Game or interactive application | Rewrite on **Canvas/WebGL** (`frontend-web-platform-standards`, `webgl-webgpu-standards`), or a modern engine; if the original engine is C/C++, **WebAssembly** |
| Enterprise Flex application | **Apache Royale** as a bridge to reduce cost, **with a written commitment to a final destination in HTML/TS** (§2); or direct rewrite by domain |
| Live desktop/mobile AIR application | Maintain under HARMAN licensing while the cost justifies it, **with license and renewal figures in writing**, or migrate to native/Flutter/web |
| Historical content with no owner | **Preservation**: keep the `.swf` as an archival object with metadata, and serve it with **Ruffle from an isolated origin** (§3). It is the only honest route when there is no source |
| Content with no identified value | **Retire.** Most of the `.swf` in an estate falls here, and it is the cheapest and safest option |

**Decision rule**: if no owner or value shows up in the inventory, **it is deleted**; the burden of
proof is on whoever wants to keep it, not on whoever retires it.

**Prohibitions:**
- ❌ **FORBIDDEN** to install, reactivate or maintain Flash Player on any machine in the estate, or to
  distribute third-party players/*projectors* to bypass the 12-Jan-2021 block.
- ❌ **FORBIDDEN** to write new content in ActionScript for the web, or to start a new project on AIR.
- ❌ `crossdomain.xml` with a wildcard, or left on the server "just in case".
- ❌ Serving `.swf` content (even via Ruffle) from the origin of an authenticated application.
- ❌ Treating a `.swf` as a secure container: **keys, tokens or internal endpoints inside a `.swf` are
  considered compromised** and are rotated (§3).
- ❌ Automatic AS2 → AS3, or AS3 → TypeScript migration, presented as a conversion: they are rewrites
  (§2).
- ❌ Redistributing an AIR application without repackaging with an updated SDK, or with an expired
  signing certificate.
- ❌ Committing to HARMAN's free tier without accepting the branded splash screen and the absence of
  support; or budgeting any commercial tier without a written license **and renewal** figure.
- ❌ Presenting Ruffle as full compatibility: its AVM2 is at **90 % of the language and 80 % of the
  API** according to the project itself (§2).
- ❌ Leaving ownerless `.swf` in an inventory indefinitely. They either have a retirement date or they
  have an owner.

## 8. Mandatory web verification

1. **The two Adobe dates** (31-Dec-2020 end of support; 12-Jan-2021 content block) on their official
   Flash Player end-of-life page. **Quote them verbatim; do not paraphrase them nor round them to
   "2021".**
2. **HARMAN's AIR SDK — declared gap**: the current version (51.x series according to secondary
   sources) **is not verifiable from their public site**, which is a SPA. Check it in the product
   portal. **The licensing tiers are verified** in the official `air.system.License` reference
   (`enterprise`/`professional`/`basic`/`free`, with `expiryDate` and `numberOfSeats`).
3. **AIR pricing — structural gap**: HARMAN does not publish rates; they are on request and by revenue
   threshold. Any figure has to come from a contractual quote, and you have to ask explicitly about
   **renewal** and about audit terms.
4. **Ruffle**: AVM2 compatibility status on their compatibility page (as of Aug 2026: language 90 %,
   API 80 %) and whether a stable release has appeared — as of Aug 2026 they only publish *nightlies*
   (latest verified, 5-Aug-2026). Also verify its CVEs: it is an interpreter of hostile content.
5. **Apache Royale**: whether there is a release later than **0.9.12 (11-Dec-2024)** and whether it has
   left `0.x`. A migration bridge with no releases is a risk that has to be put in writing.
6. **Adobe Animate**: product status, its licensing model and what it exports today (HTML5 Canvas,
   WebGL), before committing to a conversion with it.
7. Historical Flash Player and AIR CVEs associated with whatever you still have deployed, and CVEs of
   Ruffle itself if you deploy it.
8. Flash blocking status in the browsers and systems of your estate, to confirm that **nobody has
   reactivated anything** (it is what the audit usually finds).

If the web contradicts this document, **the web wins** — flag the discrepancy.
