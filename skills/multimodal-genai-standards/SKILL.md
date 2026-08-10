---
name: multimodal-genai-standards
description: Generative and understanding systems over non-text modalities — image, audio, video and document — as an engineering problem, provider-agnostic. Use when sending an image, a PDF page, a screenshot, a chart, an audio file or a video frame into a vision-language model, choosing between a classical OCR pipeline (Tesseract, PaddleOCR, docTR, Surya/Marker) and a VLM-based document reader (dots.ocr, olmOCR, DeepSeek-OCR, PaddleOCR-VL, Docling) and benchmarking with OmniDocBench or olmOCR-Bench, generating images with diffusion models (Stable Diffusion, FLUX.1 dev/schnell/pro, ComfyUI, ControlNet, LoRA adapters, seed/CFG/steps, negative prompts) and budgeting cost per image, running speech-to-text (Whisper large-v3 and turbo, faster-whisper, whisper.cpp, Parakeet TDT, Canary-Qwen, Voxtral, WER measurement, diarization, timestamps) or text-to-speech and voice cloning consent, processing video (frame sampling rate, keyframes, temporal cost), estimating latency and cost per modality and per token of image or audio, evaluating multimodal output (why CLIPScore, FID and BLEU decide nothing), defending against prompt injection embedded in images, screenshots and documents, applying C2PA Content Credentials, durable soft bindings and watermarking, or resolving rights over training data, over generated output and over the model weights license.
---

# Multimodal generative AI standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **building a product on models that understand or generate non-text modalities**:
image, audio, video and document. Covers the modality decision, the choice between a classical
pipeline and a generative model, cost and latency per modality, the evaluation of an output that
has no single correct answer, the **security of an input the model treats as an
instruction**, and the rights over input, weights and output.

**Guiding principle: in multimodal, the input data is also an instruction channel.** A
pixel, a frame or a hidden layer of a PDF comes in through the same path as your *system prompt* and the
model does not tell one from the other. All of §5 follows from that. Corollaries:

1. **You almost never need generation; you almost always need understanding.** And understanding a
   document is usually better solved by a pipeline with spatial grounding than by a free-running VLM (§2).
2. **Automatic multimodal metrics decide little.** FID, CLIPScore or aggregate WER do not tell you whether your
   product works (§4).
3. **The cost is not in the prompt: it is in the resolution, the number of pages and the frame
   rate** (§6). It is the variable discovered on the bill.

Triggers: those in the frontmatter.

**Not applicable**:
- **`claude-api`** (installed skill, **the canonical reference on the Anthropic side**): **every
  model fact, identifier, price, context window, size limit or image/PDF format from
  Anthropic comes from there, NEVER from memory nor from this document.** If the answer contains an Anthropic
  model ID, a rate or a parameter name, it is theirs. Here, provider-agnostic criteria.
- `llm-app-engineering-standards`: **the text LLM application** — prompt as an artifact, structured
  output, context window, prefix cache, streaming, retries, spend limits,
  prompt injection **in the text channel**. Here only what **the modality adds**: the visual and
  documentary injection vector, the cost per image/second, and the evaluation of non-textual
  output. **Their reliability and prompting criteria are not duplicated.**
- `computer-vision-standards`: **classical perception** — detection, segmentation, tracking,
  labelling, mAP/IoU, edge deployment, sensor drift. **Arbitration rule already declared in
  their §1 and respected here: if the output is boxes, masks or classes, it is theirs; if it is prose,
  description, semantic extraction or a generated artifact, it is ours.**
- `nlp-standards`: pure text and its three-way decision (rule / small model / LLM). **It applies
  just the same before reaching for a VLM**: if the document is clean digital text, extracting and using NLP is
  cheaper, more accurate and more auditable than looking at it with a model.
- `deep-learning-standards` and `model-finetuning-standards`: **training and touching weights**. A diffusion
  LoRA or a VLM fine-tune is theirs, including **the licence of the base weights**; here only
  the use of the resulting model and the cost of its inference.
- `rag-standards`: **the retrieval** — ingestion, chunking, index, hybrid, reranking, citation.
  **A fine and frequent boundary**: turning a PDF into usable text and chunks is **document
  parsing and is ours**; what gets indexed, how it is chunked and how it is retrieved is **theirs**.
- `llm-evaluation-standards`: **the evaluation machinery** — golden sets, LLM judges and their
  calibration, significance, CI regression. Here, **what is measured in multimodal and why automatic
  metrics are not enough** (§4); the apparatus, there.
- `ai-agents-standards` (the autonomous loop, and the agent that looks at a screen),
  `mlops-standards` (production lifecycle), `local-inference-standards` (serving your own
  weights), `gpu-computing-standards` (the GPU as a resource), `mlsecops-standards` (weight provenance
  and attacks on the model), `ai-governance-standards` (**AI Act, risk classification,
  inventory and the transparency and marking obligations of article 50 — they are theirs**; here only
  the technical mechanism, §5), `privacy-engineering-standards` (biometrics, images of people, voice
  as personal data), `opensource-licensing-standards` (weight and dataset licences),
  `accessibility-standards` (**generated alt text and automatic captions are
  an aid, not conformance**: the WCAG criteria are theirs), `finops-standards` (economic unit).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criteria | Verified note |
|---|---|---|
| Multimodal or not? | **If the data exists in structured or textual form, use it.** Looking at a screenshot of a dashboard when the API exists is paying to guess | Decided before the model |
| **Digital** document (PDF with a text layer) | **Direct extraction**, not a VLM | It is exact, cheap, deterministic and auditable. A VLM here only adds cost and hallucination risk |
| **Scanned** document, with tables, charts or handwriting | **Document VLM with spatial grounding** (*bounding boxes*) | Grounding is the anti-hallucination control: it forces the extracted text to point at a region. An extractor without coordinates is not verifiable |
| Classical OCR versus VLM | **It depends on the task; there is no winner** | Classical wins on clean input, stable formats, latency and cost. VLM wins on complex layouts, tables, charts and semantic extraction. **VLMs are of the order of 5-10× slower and can hallucinate plausible but false text** — the dangerous failure, because it looks correct |
| Cascaded pipeline | **Watch out for compounded error** | A 2 % per-character error rate per stage propagates and ruins the extraction downstream. That is the real argument for the single-pass model, not the hype |
| Document extraction evaluation | **Against your documents, always** | `OmniDocBench` and `olmOCR-Bench` are the public references; they serve to rule out, **not to decide**. A good part of the 2026 comparisons are vendor blogs with a commercial interest |
| Transcription (STT) | **Whisper large-v3 / turbo** as the multilingual default; alternatives if the case is English or real time | As of Aug 2026 **there is no recorded successor to Whisper**: `large-v3` and its *turbo* distillation are still the reference open checkpoint (>99 languages). Measured alternatives: **Parakeet TDT 0.6B v3** (better average WER and much faster, but **English and European languages only**), **Canary-Qwen 2.5B** (better in English, **English only**) |
| STT model licence | **It decides as much as the WER** | Verified: **Whisper is MIT**; **Parakeet TDT 0.6B v3 and Canary-Qwen are CC-BY-4.0** → commercial use permitted **with mandatory attribution**, which in an embedded or white-label product is a real obligation. **It is a legitimate reason to deploy the model that is not the most accurate** |
| Image generation | **Diffusion with explicit control**; without control, it is a surprise machine | Seed, steps, CFG and ControlNet pinned and **recorded with every output**. Without a recorded seed there is no reproduction and no debugging |
| Generation weights licence | **Read raw, always** | Verified literally: **FLUX.1 [dev] Non-Commercial License v1.1.1** — *"You may only access, use, Distribute, or create Derivatives of the FLUX.1 [dev] Model or Derivatives for Non-Commercial Purposes"*. **And yet, on the output**: *"We claim no ownership rights in and to the Outputs… You may use Output for any purpose (including for commercial purposes)"*, except training a competing model. **The weights and the output have different licences: confusing them is the expensive mistake of this domain** |
| Video | **Frame sampling before "passing the video"** | Cost and latency grow linearly with the frames. Start with keyframes and go up only if the metric demands it |
| Synthetic voice / cloning | **Explicit, written and revocable consent from the voice owner** | A hard precondition, not a *nice to have*. Voice is biometric data (`privacy-engineering-standards`) |
| Marking generated content | **C2PA + watermark, knowing it is forensic and not preventive** (§5) | Published specification line: **2.4**. C2PA was created in 2021; **>6,000 members and affiliates as of Jan 2026** |

## 3. Structure and conventions

- **A multimodal artifact is recorded with its full provenance**: model and version, seed,
  parameters, input hash, cost and date. Without that you cannot reproduce a failure, nor
  answer a complaint, nor audit.
- **Normalise the input at the edge, not in the model**: maximum resolution, DPI, deskew,
  orientation, format and **maximum size**. A user uploading a 200 MB TIFF must not reach the
  model; they must reach the validator.
- **Resolution is the cost parameter, not a quality detail.** Pin the minimum that sustains
  the metric and measure it; raising resolution "just in case" multiplies the spend without moving the result.
- **Structured output mandatory** for extraction: a declared and validated schema, with
  source coordinates per field. **A field with no anchor is an unverifiable field.**
- **Fallback and human review path declared in advance**: what happens when confidence
  drops below threshold, who reviews and with what SLA. A document extractor with no review queue implicitly
  assumes a 100 % hit rate that does not exist.
- **Idempotency and cache by input hash**: the same image is not processed twice. It is the
  cost optimisation with the best effort/benefit ratio in this domain.
- **Audio: the unit is the segment, not the file.** Segmentation, timestamps and, where applicable,
  diarisation; long files are chunked to bound the failure and the retry.
- **Generated alt text and captions are marked as generated** and go through review if
  they are somebody's access path. Conformance is set by `accessibility-standards`.

## 4. Evaluation: why automatic metrics are not enough

- **The structural problem**: in multimodal generation **there is no correct answer**, and
  automatic metrics measure similarity to an arbitrary reference or alignment in a learned
  space — not usefulness. **FID** compares distributions and is sensitive to the set and the sample
  size; **CLIPScore** inherits the biases and blind spots of CLIP itself and rewards what CLIP
  recognises; **BLEU/ROUGE** over image descriptions penalise a better-written description.
  **None of them is a product gate.** They serve to detect gross regressions, and nothing else.
- **WER is the partial exception**: it is objective, but **aggregate WER hides exactly what
  matters** — proper nouns, figures, domain jargon, accented speakers, noisy audio.
  **Measure WER per segment and per speaker class**, and add a business metric (was the policy number
  extracted correctly?).
- **Document extraction**: the metric is **per-field accuracy on your documents**, and per field
  type (numeric fields and tables fail differently from prose). Add the **human correction
  rate**, which is the real cost.
- **Your own golden set, mandatory**: 100–300 representative samples —including **the ugly
  cases**: a skewed photocopy, a stamp on top of the text, a table split across pages, audio with two
  people talking at once—. The machinery (judges, significance, CI) belongs to
  `llm-evaluation-standards`; **the content of the set is this domain's responsibility**.
- **Human evaluation with a rubric** for generation: written criteria, more than one evaluator,
  measured agreement. "I like it better" is not an evaluation.
- **CI gate**: the golden set runs on every change of model, prompt or preprocessing.
  **Changing a model version without re-evaluating is deploying blind**, and in multimodal the
  regressions are silent: the output still looks plausible.

## 5. Stack security

**5.1 Prompt injection by image and by document — the risk that defines the domain.**

- **It is architectural, not a bug**: current VLMs **do not distinguish the visual content you want
  to show from the instructions embedded in it**; once past the vision encoder, everything
  comes in through the same instruction-following path. It is catalogued as **OWASP LLM01**.
- **Verified attack classes**: typographic text embedded in the image and made barely visible
  to a human but readable by the model; **adversarial perturbations with no legible text**, which
  work **even when the model has no OCR** (the line of work of Bagdasaryan et al. and successors);
  instructions in metadata, hidden layers or white text of a document; and in 2026, **injection
  from the physical world** (signs, packaging, screens within the field of view of an agent with a
  camera).
- **State of the defences, unvarnished: they are behind.** The most cited commercial guardrails
  are still **text only** in their public APIs; there is no reliable production defence for
  image, audio and document. **Design assuming multimodal injection works.**
- **Controls that do work, because they do not depend on detecting the attack**:
  1. **All uncontrolled input is data, never instruction.** Explicit separation in the prompt and,
     above all, in the permissions.
  2. **The model's output executes nothing with privilege.** No tool with a side effect, no
     network call, no write, without independent validation or human approval
     (`ai-agents-standards` for the loop).
  3. **Least privilege for the process that looks at third-party content**, and restricted egress: the
     exfiltration via a URL in the response is the usual monetisation vector.
  4. **Output filtering** of anything that exfiltrates (URLs with data, remote image
     markdown).
  5. **Careful with OCR as a defence**: perturbation attacks ignore it, and early-fusion
     models treat visual symbols (emoji, rebus) as instruction — a keyword
     filter does not see them.
- **The specific surface of screenshots**: an agent looking at the screen sees everything on
  it, including a mail window with hostile instructions. Treat it as input from
  the Internet.

**5.2 Marking, provenance and its honest limit.**

- **C2PA is forensic, not preventive.** It proves a key signed a manifest and that the file has not
  changed since; **it does not prove the image is true, or fair, or yours**, and the
  specification does not address human or organisational identity. Verified limitations: the
  embedded manifest **is lost whenever any incompatible tool rewrites the file**
  (WhatsApp, iMessage and Facebook re-encode on upload), and **a screenshot or a photo of
  the screen breaks the binding**. A file with no credential **says nothing**: it may never have
  had one, or it may have been stripped.
- **Durable Content Credentials** combine a *hard binding* (SHA-256 hash over the bytes) with a *soft
  binding* (watermark or perceptual fingerprint) to find the manifest again in a repository.
  Rule from the specification itself: **a *soft binding* is not used as a *hard binding***.
- **No watermark resists a dedicated adversary with access to the model.** Use it for
  traceability and compliance, never as a security control.
- **The regulatory obligation to mark and disclose synthetic content belongs to
  `ai-governance-standards`** (AI Act, article 50 and the associated codes of practice). Here only the
  mechanism and its limits. **Verify the dates there and on the web; do not cite them from memory.**

**5.3 Rights.**

- **Three different and separate licences, and people mix them up**: (a) the model's **training
  data**, (b) the **weights**, (c) the **output**. The FLUX.1 [dev] case illustrates it literally
  (§2): weights **non-commercial**, output **commercially usable**.
- **The licence is read raw**, from the licence file in the weights repository, never from the
  project's website nor from a summary. And it is re-read on a version change: **model licences
  change between releases**.
- **The provenance of the training data is an open risk** (litigation ongoing in several
  jurisdictions as of Aug 2026). Default stance: **do not generate material that deliberately imitates
  the identifiable style of an author or a third party's brand**, and do not publish it without review.
- **Images and voices of people**: personal data, and often biometric. Legal basis, minimisation and
  explicit consent to clone a voice or a face (`privacy-engineering-standards`).
- **User data towards the provider**: what is retained, for how long and whether it is trained on, is
  verified in the specific provider's contract — **for Anthropic, in `claude-api`**.

## 6. Cost, latency and operability

- **Instrument cost per modality and per business unit from day one** (per page, per
  minute of audio, per generated image, per frame). In text the cost surprises you; in multimodal
  **it derails**, because a single variable —resolution, pages, fps— multiplies it.
- **Real orders of magnitude**: document extraction ranges from **cents per thousand pages**
  with a self-hosted open model to **several orders more** with a large commercial model per
  page. **The difference decides the architecture, not the margin.** The concrete figures are verified
  on the web and, for Anthropic, in `claude-api`.
- **Latency**: perception and image/audio generation take seconds. Design asynchronously with
  state and notification; a synchronous endpoint waiting on a diffusion model is a timeout with
  a date. **Per-request and per-user budget with a hard cut-off** — the loop that reprocesses a 900-page
  PDF is the classic cost incident.
- **Explicit degradation**: if the model fails or exceeds budget, the alternative path is a
  classical pipeline + human review, not a 500 error.
- **Watch**: cost and p95 latency per modality, rejection rate of the input validator, human
  correction rate, and **quality drift after a provider version change** — which
  happens without notice and does not raise an error.

## 7. Sustainability and prohibitions

- **Every model is re-evaluated against the golden set when its version changes**, including a
  managed model you "have not touched".
- **Weights and their licences are re-audited per release** (§5.3).

- ❌ **FORBIDDEN** to treat a visual or documentary input of uncontrolled origin as if it did not
  contain instructions (§5.1).
- ❌ Giving a VLM's output the ability to execute tools with side effects without independent
  validation or human approval.
- ❌ Using a VLM to read a document that already has an extractable text layer.
- ❌ Extracting fields without spatial grounding and presenting them as verified, or deploying document
  extraction with no human review queue and no confidence threshold.
- ❌ Using FID, CLIPScore, BLEU or aggregate WER as a product acceptance criterion (§4).
- ❌ Changing model or version without re-running the golden set.
- ❌ Confusing the licence of the weights with that of the output (§5.3, the FLUX.1 [dev] case), or assuming a
  licence from the project's website: **the file is read raw**.
- ❌ Cloning a voice or a face without explicit, written and revocable consent.
- ❌ Presenting C2PA or a watermark as proof of authenticity or as a preventive control, **or treating
  the absence of a credential as proof of manipulation** (§5.2).
- ❌ Relying on a text guardrail to contain injection by image or audio.
- ❌ Sending a whole video to a model with no frame sampling policy; raising resolution, DPI or
  fps without measuring whether it moves the metric; or deploying with no per-request budget and hard cut-off.
- ❌ **Citing an Anthropic model identifier, price or limit from memory: it comes from
  `claude-api`.**
- ❌ Treating automatically generated captions or alt text as accessibility
  conformance.

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Every Anthropic model fact** (IDs, prices, image and PDF size and format limits,
   parameters): **from the `claude-api` skill**, not from here nor from memory.
2. **Prices and per-modality limits of the provider you use**: they change often and the cost per
   image or per minute of audio is the variable that decides the architecture (§6).
3. **Status of Whisper and its alternatives**: as of Aug 2026 **no announced successor to
   Whisper is on record**; `large-v3`/turbo are still the reference open checkpoint. Reconfirm before
   committing an STT architecture, and **verify the licence of each checkpoint**
   (Whisper = MIT; Parakeet TDT 0.6B v3 and Canary-Qwen = CC-BY-4.0, with mandatory attribution).
4. **Image generation weight licences read raw** — the case verified here is
   **FLUX.1 [dev] Non-Commercial License v1.1.1** (non-commercial weights, commercial output permitted
   except training a competitor). Check Stable Diffusion too, and any third-party LoRA,
   which drags in its own licence.
   - **Declared gap**: I did not verify the current licence of Stable Diffusion 3.x nor the terms
     of FLUX.1 [pro]/[schnell]; they are read raw before using them.
5. **Current C2PA specification** at `spec.c2pa.org` (verified published line: **2.4**),
   status of the conformance programme and of the *Trust List*, and **which platforms preserve or strip
   the manifest on upload** — that is what decides whether the marking is any use in your distribution channel.
6. **Regulatory marking and disclosure obligations**: **they belong to `ai-governance-standards`**;
   verify there and on the web the AI Act application dates (article 50) and the status of the code
   of practice on marking. **Do not cite regulatory dates from memory.**
7. **State of the defences against multimodal injection**: it is the fastest-moving area. **Declared
   gap**: as of Aug 2026 I found no production defence with independently demonstrated effectiveness
   for image/audio/document; the detection figures that circulate come from
   the authors of each framework themselves. Design with the controls in §5.1, which do not depend on detecting.
8. **Document extraction benchmarks** (`OmniDocBench`, `olmOCR-Bench`) and the current open
   model: leadership changes every few months and **a good part of the published comparisons come
   from vendors with a commercial interest**. Reproduce on your documents before deciding.

If the web contradicts this document, **the web wins** — flag the discrepancy.
