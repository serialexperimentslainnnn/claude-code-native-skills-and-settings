---
name: streaming-multimedia-standards
description: Video/audio ingest, transcoding, packaging and delivery pipelines. Use when working with HLS playlists (.m3u8, #EXT-X-*), MPEG-DASH manifests (.mpd), CMAF/fMP4 segments, LL-HLS, codec selection H.264/AVC, HEVC, AV1, VVC and their patent pools, ffmpeg/ffprobe transcode commands and ladders, GStreamer pipelines (gst-launch-1.0), DRM with Widevine/FairPlay/PlayReady and CENC/cbcs, SCTE-35 ad markers, subtitle and caption delivery (WebVTT, TTML/IMSC, CEA-608/708, #EXT-X-MEDIA TYPE=SUBTITLES, DASH text AdaptationSet) and audio-description renditions, RTMP/SRT/WHIP (WebRTC) ingest, Media over QUIC (MoQ), media servers (MediaMTX, Ant Media, Wowza, OBS as encoder), or managed services (AWS MediaLive/MediaPackage/IVS, Mux, Cloudflare Stream).
---

# Streaming multimedia standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **media pipeline**: ingest (RTMP/SRT/WHIP), transcoding and the bitrate
ladder, packaging (HLS/DASH/CMAF), DRM, latency (VOD, standard live, LL-HLS, real time
with WebRTC/MoQ), codec choice **with its patent cost** — the expensive fact of this domain — and
the choice between running your own server and a managed service.

Triggers: `.m3u8`, `#EXT-X-VERSION`/`#EXT-X-PART` and the other HLS tags, `.mpd`,
fMP4/CMAF segments, `ffmpeg`/`ffprobe` (transcoding, `-c:v libx264/libx265/libsvtav1`, filters,
ABR ladders), `gst-launch-1.0` and GStreamer pipelines, Widevine/FairPlay/PlayReady,
CENC (`cenc`/`cbcs`), HEVC/AV1/VVC licensing, SCTE-35, RTMP, SRT, WHIP/WHEP, LL-HLS,
Media over QUIC, MediaMTX, Ant Media, Wowza, OBS, MediaLive/MediaPackage/IVS, Mux,
Cloudflare Stream, "the live stream arrives 30 seconds late", "the video does not play in
Safari/on iPhone".

**Not applicable**: see `caching-cdn-standards` (**the CDN, HTTP caching, its headers and its egress
cost are theirs** — an HLS segment is just one more cacheable HTTP object; here it is decided how it
is packaged and with what duration, there how the edge serves it), `webgl-webgpu-standards` (browser
rendering: canvas, WebGL/WebGPU, WebCodecs as a graphics API), `frontend-web-platform-standards`
(the `<video>` element, Media Source Extensions and EME as a generic web platform; here which
manifest and which DRM are delivered to it), `edge-computing-standards` (edge compute as a
platform; here only whether the transcode/repackage lives there), `e-commerce-standards` (the shop
embedding the video), `accessibility-standards` (**the conformance criteria and their legal scope are theirs**: WCAG
1.2.2/1.2.4/1.2.5, captions versus transcript, audio description, who signs the
statement. **Here the delivery mechanics of those tracks**: producing the WebVTT or the TTML/IMSC,
declaring it in `#EXT-X-MEDIA TYPE=SUBTITLES,FORCED` or in the text `AdaptationSet` of the `.mpd`,
embedded CEA-608/708 versus a side track, the audio-description track as a separate
*rendition*, and validating that each platform's player offers it. **The warning both sides hold:
a subtitle track the packager does not declare does not exist for the user**, and the requirement
counts as unmet even though the file sits in the bucket),
`gaming-infrastructure-standards` (in-game voice and match streams),
`object-storage-standards` (the VOD origin bucket), `gpu-computing-standards` (the GPU as a
compute resource; here only the hardware-versus-software encoder criterion).

## 2. Default decisions / Toolchain

> Verify the latest version **and the state of the patent pools** on the web before pinning
> anything in a real project (§8). Status verified as of Aug 2026:

| Decision | Default | Justifiable alternative | Reason |
|---|---|---|---|
| Delivery format | **HLS with CMAF (fMP4) segments** | DASH as well, if the business requires clients that will not take HLS | HLS plays everywhere (Apple requires it on iOS/Safari); CMAF allows a single set of segments for HLS+DASH |
| Base codec | **H.264/AVC** always present in the ladder | — | The only one the whole device base decodes; its essential patents are largely expired or expiring |
| Efficiency codec | **AV1** (SVT-AV1) where the client supports it, with an H.264 fallback | HEVC if the target base is Apple/TV and the licence cost is accepted | AV1 declared royalty-free by AOMedia; HEVC with a double toll (device and now distribution too) — see the warning below |
| VVC | **Not in production** | A pilot with hardware that supports it | Marginal decode support in the installed base and a patent pool still consolidating |
| Transcoder | **ffmpeg** (9.0, Aug 2026; 8.1.x branch maintained) | GStreamer (1.28.x; 1.30 expected Q4-2026) when the pipeline is long-lived, with appsink/appsrc or in-house elements | ffmpeg for batch/CLI; GStreamer as an embeddable framework |
| Live (contribution) encoder | **OBS Studio** (32.2.x, Jul 2026, GPL-2.0; native WHIP and WebRTC since 32.1) | A hardware encoder | The de facto contribution standard |
| Ingest | **SRT or WHIP (RFC 9725)** for a new design; RTMP only for compatibility | — | RTMP is legacy with no native encryption and no loss recovery; WHIP is already supported by OBS, IVS, Cloudflare and Mux |
| Lightweight self-hosted server | **MediaMTX** (v1.20.0, Aug 2026, **MIT** — read from the LICENSE): SRT/RTSP/RTMP/WebRTC/LL-HLS/MoQ in a single Go binary | Ant Media (CE + Enterprise ~USD 99/month/instance) for WebRTC at scale; Wowza (4.9.7, commercial, from ~USD 195/month) | Simplicity, clean licence, very active maintenance |
| Managed service | **Mux or Cloudflare Stream** for a product; **AWS IVS** for interactive latency <3 s; **MediaLive+MediaPackage** when fine-grained pipeline control is needed | — | Buying the pipeline is almost always cheaper than operating it; compare by encoded minutes + delivered minutes + storage |
| Target latency | VOD and normal live: **standard HLS (6-30 s)**; "near-live": **LL-HLS (2-6 s)**; conversational/auctions: **WebRTC (<500 ms)** | **MoQ**: promising (sub-second at CDN scale) but an **IETF draft (draft-ietf-moq-transport-17, Jul 2026), not an RFC** — pilots only | Every latency step multiplies cost and complexity: do not ask for real time if the business tolerates 6 s |
| DRM | **Multi-DRM over CMAF with common encryption**: Widevine (Android/Chrome), FairPlay (Apple), PlayReady (TV/Xbox/legacy Edge), served through a multi-DRM provider | No DRM + signed CDN tokens if only access control is needed | No single DRM covers the whole base; `cbcs` is the scheme all three support over CMAF — verify the exact matrix (§8) |

**Patent warning — the expensive fact (Aug 2026), web-verified, not from memory**:

- **Pool consolidation**: in Dec 2025 **Access Advance acquired administration of Via LA's
  HEVC/VVC pool** (renamed *VCL Advance*). The HEVC Advance pool raised rates by 25% for anyone
  signing after **30 Jun 2026** (a date already extended once — verify the current one).
- **Distribution is no longer free**: since 2025 there are pools claiming royalties **from the
  streaming service for the content distributed** (Avanci Video and Access Advance's *Video
  Distribution Patent Pool*, covering HEVC, VVC, VP9 **and AV1**), breaking the previous practice
  of charging the device only.
- **AV1's "royalty-free" status is in litigation**: in Mar 2026 Dolby (a licensor of Access Advance)
  sued Snap for infringement of **AV1** and HEVC patents — the first action against an AV1
  implementation. AV1 remains the best cost bet, but "free" is an AOMedia position, not a settled
  legal fact. **AV2**: spec finalised (May 2026); no decode base — not a production option yet.
- **Rule**: codec choice is a cost and legal decision, documented in an ADR with legal advice if
  the volume is serious, and the state of the pools is re-verified **before every renewal or
  launch** (§8).

## 3. Structure and conventions

- **An ABR ladder per content type, not a generic one**: resolutions/bitrates decided by the
  content (sport ≠ a talk), capped at the resolution the business pays for. Every rung is
  validated with a perceptual metric (VMAF/SSIM), not by eye. The minimum ladder always includes a
  low rung (~300-500 kbps) for bad networks.
- **Segment duration**: 4-6 s in standard HLS/DASH (a latency/cache-efficiency balance);
  parts of 0.3-1 s only in LL-HLS. Segments aligned across renditions (same
  keyframe cadence: `-g` = fps × duration, matching `keyint_min`) or ABR *switching* breaks.
- **A single CMAF**: one set of fMP4 segments referenced by both the HLS and DASH manifests;
  duplicating segments per format doubles storage and sinks the CDN hit ratio.
- **Immutable, versioned segment names** (never rewrite a published segment):
  the corresponding cache policy belongs to `caching-cdn-standards`.
- **Audio**: AAC-LC universally; Opus where the client supports it; normalised loudness (EBU R 128).
- **The pipeline is code**: ffmpeg commands/GStreamer pipelines versioned and parameterised,
  never "the command that worked in someone's terminal". Named presets and an ADR.

## 4. Quality and testing

- **Manifest and stream validation as a CI gate**: Apple's `mediastreamvalidator`/HLS
  report for HLS, DASH-IF conformance for DASH; `ffprobe` over the output (codec, profile,
  keyframe cadence, segment duration) after every preset change.
- **Measured perceptual quality**: VMAF per rung against the source over an in-house reference
  clip set; a VMAF regression when changing encoder or ffmpeg version **breaks the build**.
- **A real playback matrix**: Safari/iOS (the most restrictive client: native HLS, FairPlay,
  different codec support), Chrome/Android, one representative TV/stick. The emulator detects
  neither DRM nor hardware-decode failures.
- **Mandatory edges**: ingest loss mid-broadcast (does the manifest recover or is it
  poisoned?), quality switching on a degraded network, *seek* into the middle of a live stream with
  DVR, DRM licence expiry during playback, SCTE-35 discontinuities.

## 5. Stack security

- **DRM ≠ access control**: DRM protects licensed content; for "stop people who did not pay from
  watching" a signed URL/CDN token with short expiry is usually enough. Do not buy multi-DRM
  for a token problem.
- **Keys**: content keys and licence-server credentials never in the
  client or in the manifest; key rotation in long live streams.
- **Authenticated ingest**: stream keys treated as secrets (rotatable, revocable); SRT with a
  passphrase; WHIP with a short-lived token. An open RTMP endpoint is an anonymous publishing
  channel on your domain.
- **ffmpeg/GStreamer process hostile input**: a user-uploaded file is a potential exploit
  against the demuxer (a long CVE history in both). Transcode user content
  **in a sandbox/isolated worker with no credentials**, keep versions current, and restrict input
  formats with an allowlist.
- Content compliance: DRM and watermarking according to the contract with the licensor (the studio
  usually requires a specific Widevine/PlayReady security level per resolution — check the contract).

## 6. Performance and operability

- **Domain SLIs**: playback start-up time, rebuffering ratio, end-to-end live latency
  (measured, not estimated: embedded timestamp or visual marker),
  DRM licence errors, ingest failure rate. Player telemetry (or the managed service's data, such
  as Mux Data) is the only real view.
- **Cost**: streaming is an **egress** business; the ABR ladder and codec efficiency
  are cost decisions as much as quality ones (more rungs = more transcode + more storage;
  a better codec = fewer GB delivered). Egress and hit ratio → `caching-cdn-standards`.
- **Hardware encoders (NVENC/Quick Sync/VCN) for live at scale; software (x264/SVT-AV1) for
  VOD where quality per bit dominates** — hardware buys density with compression efficiency.

## 7. When NOT to / Prohibitions

- ❌ **WebRTC "because the live stream is slow"** when the business tolerates 3-6 s: LL-HLS scales
  over the CDN, WebRTC demands SFU infrastructure per viewer. Every latency step is justified by a
  requirement, not by a wish.
- ❌ MoQ in production as of Aug 2026 (a moving draft) except as a pilot with a fallback path.
- ❌ Choosing HEVC (or assuming AV1 is free) **without verifying the state of the patent pools on
  the date of the decision** — it is the most expensive decision in the domain and it changed twice
  in a year.
- ❌ RTMP as the ingest of a new design without justifying compatibility.
- ❌ Different segments per format when a single CMAF would serve; keyframes misaligned across
  renditions.
- ❌ Transcoding user content in the same process/host that handles credentials.
- ❌ Stream keys in repositories, logs or example URLs; an ingest endpoint without authentication.
- ❌ Building and operating your own streaming server when a managed one covers the case — the real
  cost is the pipeline's on-call, not the licence. Self-hosted only with a requirement (data, cost
  at scale, latency, sovereignty) written in an ADR.
- ❌ "It looks fine in my Chrome" as validation: Safari/iOS is the gate.
- ❌ Home-grown DRM or obfuscation as a substitute for Widevine/FairPlay/PlayReady if the contract
  requires content protection.

## 8. Mandatory web verification

1. **Patent pools** — the expensive fact: status of HEVC Advance/VCL Advance (Access Advance),
   Avanci Video and the Video Distribution Patent Pool; rates and the current deadline (the
   Jun 2026 one has already been extended once); status of the Dolby versus Snap litigation over AV1.
   Sources: `accessadvance.com`, primary press releases, not forums.
2. **ffmpeg**: latest release at `ffmpeg.org/download.html` (9.0 as of 2026-08-04; 8.1.x and
   7.1.x branches maintained) and demuxer CVEs.
3. **GStreamer**: `gstreamer.freedesktop.org/releases/` (1.28.6 as of Aug 2026, branch in
   maintenance; 1.30 expected Q4-2026).
4. **OBS**: `obsproject.com` and the GitHub releases (32.2.1, Jul 2026).
5. **MediaMTX**: `api.github.com/repos/bluenviron/mediamtx/releases` (v1.20.0, Aug 2026) and its
   `LICENSE` raw (MIT).
6. **MoQ**: status of `draft-ietf-moq-transport` at datatracker.ietf.org (still a draft or already
   an RFC?) — as of Jul 2026, draft-17.
7. **LL-HLS/HLS**: Apple's spec (`developer.apple.com`) and RFC 8216 + extensions; WHIP =
   **RFC 9725**.
8. **Managed services**: pricing and model (per encoded/delivered/stored minute) for
   Mux, Cloudflare Stream, IVS and MediaLive on their official pages — they change often.
9. **DRM/codec matrix per browser and device** (which combination of `cenc`/`cbcs`, codec and
   robustness each client supports): verify in each DRM's current documentation.
10. **Declared gaps** (not verified in this draft — do not fill them from memory): the pools'
    concrete per-unit rates (only their existence and the +25% were verified); exact
    Wowza and Ant Media pricing (taken from aggregators, not the official page); the exact
    `cbcs` versus `cenc` matrix per platform; the state of VVC support in 2026 hardware; the
    Widevine/PlayReady robustness levels the studios require today.

If the web contradicts this document, **the web wins** — flag the discrepancy.
