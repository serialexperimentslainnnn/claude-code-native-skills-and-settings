---
name: computer-vision-standards
description: Applied computer vision as a data problem, not a model problem. Use when defining a vision task (classification, object detection, semantic versus instance versus panoptic segmentation, multi-object tracking, OCR, keypoint/pose estimation), building or auditing an image dataset and its label quality, inter-annotator agreement, annotating with CVAT, Label Studio, labelme, Roboflow, FiftyOne or supervision, converting between COCO JSON, YOLO .txt, Pascal VOC XML, YOLO data.yaml and instances_train.json, writing albumentations or kornia augmentation pipelines and spotting augmentation that breaks the label, choosing a detector or segmenter (Ultralytics YOLO/YOLO26, RT-DETR, RF-DETR, D-FINE, DEIM, YOLOX, Detectron2, MMDetection, SAM/SAM 2/SAM 3, Grounding DINO, DINOv2/DINOv3) and reading its weights licence before shipping, computing IoU, mAP@0.5:0.95, per-class confusion or PR curves, exporting to ONNX, TensorRT, OpenVINO, LiteRT or Core ML, matching train and serve preprocessing (resize, letterbox, BGR/RGB, normalisation), budgeting per-frame latency on an edge device, or handling camera, lens and lighting drift. Also covers biometric and CCTV footage constraints.
---

# Computer vision standards

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **solving a vision problem with images or video**: defining the task, building and
labelling the dataset, choosing a pretrained model and its licence, evaluating in the real
domain, exporting and deploying with a latency budget, and watching for sensor drift.

Triggers: `.jpg`/`.png`/`.mp4` as input data, `instances_train2017.json`, `data.yaml`,
YOLO `labels/*.txt`, Pascal VOC `Annotations/*.xml`, CVAT `annotations.xml`, `mAP`,
`IoU`, `NMS`, `conf`/`iou` thresholds, `letterbox`, `imgsz`, `albumentations`, `A.Compose`,
`kornia`, `cv2.imread`, `torchvision.transforms`, `ultralytics`, `YOLO(...)`, `RT-DETR`,
`RF-DETR`, `detectron2`, `mmdet`, `SamPredictor`, `GroundingDINO`, `DINOv3`, `.onnx`, `.engine`,
OpenVINO `.xml`+`.bin`, `.tflite`, `.mlpackage`, "detect defective parts", "count
people", "read number plates", "track objects across frames", "it does well on test and badly on
the shop floor", "it fails on the new camera".

**Thesis of the domain**: **almost every vision problem is solved with a pretrained model and a
well-labelled dataset; the model is almost never the bottleneck.** The real order of
impact on the metric is **task definition > label quality and consistency >
dataset representativeness > augmentation > architecture > hyperparameters**, and the work
is almost always distributed in reverse. Corollaries that set the criteria: **(a)** switching detector rarely
beats fixing 200 badly placed labels; **(b)** if the model fails, the first suspect
is the label, not the network; **(c)** a high public metric says nothing about your shop floor, your camera or
your lighting.

**Not applicable**:

- `deep-learning-standards`, `model-finetuning-standards` and `classical-ml-standards` (**written**):
  **training your own network and its loop belong to the first** (mixed precision, distributed,
  reproducibility, loss diagnosis, compression); **touching someone else's weights belongs
  to the second**; **tabular data belongs to the third**, along with the common mechanics of leakage,
  splitting, thresholding and calibration, which **are not duplicated here**: they apply just the same and live there. From
  this side only what is specific to images is asserted —which task, which label, which
  preprocessing and which sensor drift.
- `llm-app-engineering-standards`, `rag-standards` and `llm-evaluation-standards` (**written**):
  **the product on top of a third-party LLM belongs to the first, retrieval to the second and
  measuring non-deterministic systems to the third**; here the metrics are deterministic
  (IoU, mAP, confusion matrix) and are computed here. A VLM that describes an image in free text
  is an LLM product and is evaluated there; a detector that returns boxes belongs here.
- `mlops-standards`, `local-inference-standards`, `gpu-computing-standards`, `mlsecops-standards` and
  `ai-governance-standards` (**written**): **the production lifecycle belongs to the first**
  —registry, promotion, drift monitoring, retraining—, **serving your own weights to the
  second**, **the GPU as a resource to the third**, **weight provenance and attacks on the
  model to the fourth**, and **risk classification, the AI Act and the inventory to the fifth**.
  Here camera drift is **detected** (§6) and risk classification is **required** before
  deploying biometrics (§5); governance, there.
- Common ones: `privacy-engineering-standards` (**biometrics, faces and people's voices**),
  `opensource-licensing-standards` (**licence policy, including that of weights and datasets**),
  `data-engineering-standards` and `data-governance-quality-standards` (ingestion, lineage and data
  quality), `python-standards`, `finops-standards` and `green-it-standards` (cost and footprint of
  inference), `grc-compliance-standards`, `webgl-webgpu-standards` (inference in the browser) and
  `embedded-iot-standards` (the edge device as a system).
- `xr-standards` and `robotics-ros-standards`: **SLAM and perception belong here**; **consuming
  the result and its timing are theirs** — the frame budget and motion-to-photon
  latency there, the control loop and the QoS of the message carrying the detection
  over there. A correct detection that arrives late is their failure, not a failure of the metric here.
- Sister skills by modality: `nlp-standards` (text) and `multimodal-genai-standards` (image, audio and
  video generation). **They are three modalities, not three levels**: none is a prerequisite for
  another. **Arbitration rule with `multimodal-genai-standards`, reciprocal and already declared in its §1:
  if the output is boxes, masks, *keypoints* or labels, it belongs here; if it is prose, a description,
  semantic extraction from a document or a generated artifact, it is theirs.**

## 2. Default decisions

> Verify the latest version and the licence **of the weights** on the web before pinning it in a
> real project (§8). The repository's licence is **not** the weights' licence.

| Decision | Default | Justifiable alternative |
|---|---|---|
| Starting point | **Pretrained + your labelled data** | Training from scratch: requires justification (`deep-learning-standards` §1) |
| Detection, permissive licence | **RT-DETR / RF-DETR / D-FINE / DEIM / YOLOX** (Apache-2.0 verified) | Ultralytics YOLO **only** with an Enterprise licence or an AGPL project |
| Instance segmentation | **Detectron2 / MMDetection** (Apache-2.0) | Ultralytics `-seg` under the same conditions |
| Interactive / *zero-shot* segmentation | **SAM 2** (Apache-2.0 verified) | SAM 3: Meta's own licence, not OSI (§5) |
| General-purpose *backbone* | **DINOv2** (Apache-2.0 verified) | DINOv3: proprietary licence and restricted access (§5) |
| Free-text detection | Grounding DINO (Apache-2.0) to **prototype and pre-label**, not for production |
| Annotation | **CVAT** (MIT verified) self-hosted; **Label Studio** (Apache-2.0) if you mix modalities | Roboflow / SaaS: check what rights over your images you are granting and to whom |
| Dataset auditing | **FiftyOne** (Apache-2.0 verified) | Your own scripts: they end up being written anyway, worse |
| Augmentation | **albumentations** (MIT) | `kornia` (Apache-2.0) if augmentation runs on GPU inside the graph |
| Canonical format in the repo | **COCO JSON** as the source of truth; YOLO `.txt` derived | VOC XML only for legacy compatibility |
| Export | **ONNX** + ONNX Runtime (MIT) as a portable *baseline* | TensorRT (NVIDIA), OpenVINO (Intel), LiteRT / Core ML depending on the final hardware |

**Selection rule**: pin **the deployment hardware and the frame budget** first;
the model family afterwards. The other way round you end up with a model that does not fit on the device.

## 3. Define the task before the model

**Choosing the wrong task is the most expensive error in the domain**, because it is not detected until the
labelling has been paid for and has to be redone entirely.

| Business question | Task | Label you have to pay for |
|---|---|---|
| Is it present / what type is it? | Classification (single or multi-label) | One label per image |
| How many are there and where? | Detection | Box + class per instance |
| What area does it occupy? | **Semantic** segmentation (pixel → class, no instances) | Per-pixel mask |
| How many objects and which pixels belong to each? | **Instance** segmentation | Per-instance mask |
| Both at once, with no gaps or overlaps | **Panoptic** segmentation | The most expensive labelling of all |
| Is it the same object as in the previous frame? | Tracking (detection + association) | Persistent identity across frames |
| What does that text say? | OCR (detection + recognition) | Text boxes + transcription |
| What pose is it in? | Pose estimation | Keypoints per instance |

Hard criteria:

- **Semantic vs. instance is not a detail**: if you have to **count**, semantic is no use; two
  touching objects are a single region. Relabelling from semantic to instance costs almost as much
  as starting over.
- **Tracking is detection + association**: the tracking metric (identity switches) does not
  improve with a better detector if the problem is the association.
- **Detection with a single class and one object per image = classification**: do not pay for boxes.
- **Counting is not always detecting**: if the objects overlap a lot (cells, grain, crowds),
  density regression beats detection at a fraction of the labelling cost.
- **OCR of a structured document**: check first whether the producer of the document can give you the
  data at source. Recognising text that somebody printed from a database is an integration failure,
  not a vision problem.

## 4. Data: the dominant factor

**Acquisition**: capture with **the same sensor, optics, mounting and lighting** that production
will have. A dataset shot with the plant manager's phone predicts nothing about the industrial
camera that will be installed. Record per image: camera, lens, exposure, shift, line, batch —
they are the variables you will later use to split the dataset and diagnose drift.

**Labelling — quality and consistency beat quantity**:

- **Written labelling guide before the first label**, with edge cases resolved and
  "yes / no / doubtful" examples. Without a guide, each annotator invents their own and the metric's ceiling
  is set by that inconsistency.
- **Inter-annotator agreement measured, not assumed**: an overlapping subset labelled by ≥2
  people and an agreement statistic (for boxes, paired IoU and class match; for
  classification, a kappa-type index that corrects for chance). **If two annotators cannot agree,
  the model cannot learn it and the evaluation means nothing.** Agreement is the
  practical ceiling of the metric.
- **Review cycle**: label → review by a second person → correction of the guide. The
  discrepancies are the best detector of a badly defined task.
- **Audit of existing labels** before blaming the model: sort by loss and review
  the worst; label errors concentrate there. Public datasets have them too.
- **Traceability**: who labelled what and when, guide version and dataset version
  (`data-governance-quality-standards`). An unversioned dataset is not evaluable.

**Formats**: COCO JSON (one file, absolute `[x, y, w, h]` boxes, RLE or polygon masks),
YOLO (one `.txt` per image, **normalised** `[class, xc, yc, w, h]`), Pascal VOC (one XML per
image, `[xmin, ymin, xmax, ymax]`). **Converting between them is the classic source of shifted
boxes**: coordinate origin, absolute vs. normalised, corner vs. centre and class order.
Always verify **by overlaying the converted boxes on the image**, not by reading the
JSON.

**Augmentation with judgement**: augmentation simulates the variability **that will exist in production**,
not whatever occurs to you. If the camera is fixed and overhead, rotating 90° teaches a variation it will
never see and wastes capacity.

**Augmentation that breaks the label** — veto list:

- ❌ **Horizontal flip** when the class depends on handedness: text, digits, number plates,
  anatomical left/right, screws by thread direction, asymmetric signs.
- ❌ **Crop or translation without recomputing box/mask/keypoints**, or leaving boxes of objects
  that are no longer in the image. Use transforms that carry the annotation (`bbox_params`,
  `keypoint_params`) and **discard** boxes below a minimum visible area.
- ❌ **Aggressive colour changes** when the colour **is** the class: fruit ripeness, cable
  coding, traffic lights, rust, medical staining.
- ❌ **Strong blur, noise or compression** when the defect to detect is subtle: you erase
  the positive class.
- ❌ **Image mixing (mosaic, mixup, copy-paste)** in a **validation** set. Training
  only, never evaluation.
- ❌ Augmentation **after** normalising, or with a different pipeline from the inference one (§6).

**Imbalance and rare cases**: in industrial vision **the rare case is the objective** — the defect
that appears once every ten thousand parts is exactly the one to detect. Consequences:
oversample or weight the rare class in training, but **never in the evaluation set**,
which must keep the real prevalence; reserve a specific rare-case set and report it
separately; and if the positives are extremely few, consider **anomaly detection** (training only
on normals) instead of supervised classification.

## 5. Licences, biometrics and video surveillance

**The weights' licence is not the repository's, and this is the most common licensing error in the
domain.** Verified by reading the raw file (Aug 2026):

| Family | Verified licence | Consequence |
|---|---|---|
| **Ultralytics** (YOLOv5, YOLOv8, YOLO11, YOLO26, and their packaged RT-DETR/YOLO-World) | **AGPL-3.0** in `LICENSE`, with a paid Enterprise option | Their licensing page says it unambiguously: *"An Enterprise License is required if you want to use Ultralytics YOLO without open-sourcing your entire project"*, and expressly lists *"Internal business tools or private company applications"*, *"Embedded deployments in hardware, edge devices, robotics, cameras, or appliances"* and *"Using custom-trained or fine-tuned YOLO models in a proprietary or commercial setting"*. **Your model trained on your data is still affected** according to the licensor |
| YOLOv7, YOLOv9, YOLOv6 (Meituan), YOLO-World | **GPL-3.0** | Strong copyleft all the same |
| YOLOv10 (THU-MIG) | **AGPL-3.0** | Same as Ultralytics |
| **YOLOX** (Megvii), **RT-DETR**, **D-FINE**, **DEIM**, **RF-DETR** (Roboflow) | **Apache-2.0** | A genuinely permissive route for detection |
| Detectron2, MMDetection, Grounding DINO, **SAM 2**, **DINOv2** | **Apache-2.0** | Permissive |
| **SAM 3** (Meta, "SAM License", 19 Nov 2025) and **DINOv3** (Meta, 19 Aug 2025) | **Proprietary licence, not OSI** | Viral in form: *"If you distribute or make the … Materials, or any derivative works thereof, available to a third party, you may only do so under the terms of this Agreement"*; it forbids *"reverse engineer, decompile or discover the underlying components"*; it excludes military, nuclear and weapons uses via *Trade Controls*; **you indemnify Meta**; and **Meta can modify the agreement unilaterally** (*"All such changes will be effective immediately"*). DINOv3 additionally requires acceptance with personal data; its *EUPE* variants come under the **FAIR Noncommercial Research License** |

**Hard rules**: (1) an AGPL model trained on your data **is not deployed in a SaaS or in a
closed product** without a commercial licence — some vendors resell that commercial licence,
verify the exact scope; (2) `pip install` is not informed acceptance: the licence is read
**beforehand**; (3) compliance is automated in CI (`opensource-licensing-standards`), not
remembered.

**Datasets**: public datasets are mostly **research only**. Verified:
**ImageNet** — *"Researcher shall use the Database only for non-commercial research and educational
purposes"*, and it **binds your employer** if you work at a for-profit company; **Cityscapes**
— non-commercial, with permission to distribute "abstract representations" (trained models) but
not the data; **KITTI** — CC BY-NC-SA. In **COCO** the licence of **the annotations and that of the
images are not the same** (third-party images with their own terms): verify both.
A practical consequence almost nobody checks: **weights pretrained on a "research only" dataset
carry the doubt into the product**. Decide it with legal, not on a hunch.

**Biometrics and video surveillance** — the risk framework lives in `ai-governance-standards` (AI Act,
classification, inventory, timetable) and the processing of personal data in
`privacy-engineering-standards` (legal basis, DPIA, minimisation, retention, rights). What
this skill sets is the **technical stop**: a face, a number plate, a gait or a fingerprint are
**biometric data** as soon as they serve to identify, and such a project **does not start without a prior
assessment**. The **AI Act (Regulation (EU) 2024/1689) art. 5** expressly prohibits, verbatim:

- *"the placing on the market, the putting into service for this specific purpose, or the use of AI
  systems that create or expand facial recognition databases through the untargeted scraping of
  facial images from the internet or CCTV footage"* (art. 5.1.e);
- *"…the use of AI systems to infer emotions of a natural person in the areas of workplace and
  education institutions, except where the use of the AI system is intended to be put in place or
  into the market for medical or safety reasons"* (art. 5.1.f);
- *"…the use of biometric categorisation systems that categorise individually natural persons based
  on their biometric data to deduce or infer their race, political opinions, trade union
  membership, religious or philosophical beliefs, sex life or sexual orientation"* (art. 5.1.g);
- *"the use of 'real-time' remote biometric identification systems in publicly accessible spaces for
  the purposes of law enforcement"*, except for the enumerated exceptions of art. 5.1.h with prior
  judicial authorisation (art. 5.2-5.3).

These prohibitions **apply from 2 Feb 2025**. Biometric identification that is **not prohibited**
falls under **high risk** in Annex III with its full regime. In addition, art. 50.3 obliges the
deployer of an **emotion recognition or biometric categorisation** system to
*"inform the natural persons exposed thereto of the operation of the system"*. **Timetable and
nuances: `ai-governance-standards` §3.3, which already has them verified against the OJEU including the
Digital Omnibus.** Derived engineering rule: **when identity is not the objective, do not
capture it** — detecting presence, counting or measuring occupancy is done without recognising anyone, and choosing the
variant that does not identify removes the whole problem instead of managing it.

## 6. Evaluation, deployment and drift

**Evaluation**:

- **IoU** defines what counts as a hit; the threshold is a product decision, not a default
  value. **mAP** averages average precision over classes and over IoU thresholds.
- **mAP hides the class you care about.** An excellent global mAP coexists with 0.2 AP on the
  critical defect class if that class is a minority. **Always report per-class AP**, and set the
  acceptance criteria on the class that decides the business, not on the average.
- **Per-class confusion matrix** with backgrounds included: it separates "did not see it" from "saw it and
  called it something else". They are failures with different fixes (more data vs. a better labelling guide).
- **Full precision-recall curve** and an explicit choice of operating point according to the asymmetric
  cost: in inspection, a false negative that reaches the customer is not worth the same as a false
  positive that only costs a re-check.
- **Evaluate in the deployment domain, not on the public dataset.** The test set is
  captured on the line, in the shop or on the street where it is going to run, is frozen and **is
  not touched**. A public *benchmark* figure is a signal of the architecture's capability, never a prediction
  of your performance.
- **Split by group, not at random**: frames from the same video, images from the same batch, from the
  same part or from the same person go **whole** to the same side. Splitting consecutive frames
  at random is leakage and produces fantasy metrics (`classical-ml-standards`).

**Deployment**:

- **Explicit frame budget** before choosing a model: target FPS, input
  resolution, number of cameras per device and end-to-end latency (capture → preprocess →
  inference → postprocess → action). **NMS and preprocessing can cost more than the network**;
  measure them separately.
- **Quantisation and export**: export to ONNX as a portable base and compile to the final hardware's
  engine (TensorRT on NVIDIA, OpenVINO on Intel, LiteRT/NNAPI on Android, Core ML on Apple).
  **Re-evaluate the full metric after quantising** —not just a couple of images—: INT8 without
  representative calibration selectively sinks the rare classes, which are the ones that matter (§4).
- **Preprocessing must match exactly between training and production. It is the number
  one source of silent degradation** and it raises no error: it just gives lower accuracy. Real
  failure points: channel order (OpenCV's BGR vs. PIL/torchvision's RGB), resize algorithm
  and interpolation, *letterbox* with or without padding and its colour, normalisation mean and standard deviation,
  0-255 vs. 0-1 range, EXIF orientation applied or not, and the colour space of the video
  decoder. **Rule**: preprocessing is implemented **once**, versioned alongside the model and
  verified with a numerical equality test between the training pipeline and the serving one
  on the same images (§7).

**Drift** (detection here, governance in `mlops-standards`): in vision, drift is almost never
"the world changed", it is **the sensor changed**. Known triggers: camera or lens replacement,
a firmware update that alters white balance or compression, a change of light fittings, dirt
or condensation on the optics, repositioning of the mount, a change of season
or shift, and a change in the packaging or part format. Watch **image statistics**
(brightness, contrast, sharpness, per-channel histogram) and **the distribution of the outputs** (mean
confidence, number of detections per frame) — they degrade before anyone reports a failure.
**Any physical change in the installation triggers re-evaluation**, and that is agreed with the
maintenance lead, not discovered afterwards.

## 7. Sustainability and prohibitions

Maintenance: pin the **inference engine** (ONNX Runtime, TensorRT, OpenVINO) as a versioned
dependency and test the migration with the frozen dataset before bumping the version. Check the
**real activity** of a project before marrying it: as of Aug 2026, MMDetection has published no tagged
release since Jan 2024 and Detectron2 since 2021 — usable, but with no support to expect.

- ❌ **FORBIDDEN** to use an AGPL model (Ultralytics and derivatives, YOLOv10) in a closed product, SaaS
  or internal tool without a written commercial licence.
- ❌ **FORBIDDEN** to deploy weights without having read their licence file **in raw** and checked
  that it is not a vendor-proprietary licence with usage restrictions.
- ❌ **FORBIDDEN** to train or deploy with a "research only" dataset in a commercial product.
- ❌ **FORBIDDEN** to start labelling without a written guide and without measuring inter-annotator agreement.
- ❌ **FORBIDDEN** to report global mAP only: without per-class AP and a confusion matrix, the evaluation
  has not been done.
- ❌ **FORBIDDEN** to evaluate on a public dataset and deploy in another domain as if it measured the
  same thing.
- ❌ **FORBIDDEN** to randomly split frames from the same video or images of the same part
  between training and test.
- ❌ **FORBIDDEN** to apply augmentation that invalidates the label (flipping with text/handedness,
  colour when colour is the class) or mixing augmentation in validation.
- ❌ **FORBIDDEN** to have two different implementations of the preprocessing, one for training and one for
  serving. One only, versioned with the model and with a numerical equality test.
- ❌ **FORBIDDEN** to accept an export or a quantisation without re-evaluating the full metric
  on the frozen dataset.
- ❌ **FORBIDDEN** to tune the confidence threshold by looking at the test set.
- ❌ **FORBIDDEN** to capture or infer biometric identity when the task does not need it.
- ❌ **FORBIDDEN** to start a facial recognition, biometric categorisation or
  emotion inference project without a prior risk classification and a documented legal basis (§5).
- ❌ **FORBIDDEN** to store images of people without a retention and deletion policy.
- ❌ **FORBIDDEN** to change camera, lens, lighting or mounting without re-evaluating the model.

## 8. Mandatory web verification

1. **Licence of the weights, version by version and vendor by vendor** —the same model
   name changes licence between incarnations—, reading `LICENSE`/`LICENSE.md`/`COPYING` **in
   raw** on the right branch and the model card separately: **they are different documents**.
2. Status and terms of the **commercial resale licences** for AGPL models: which models
   they cover, with what scope and until when.
3. **Licence and terms of use of every dataset** —images and annotations separately— and of the
   weights pretrained on it.
4. **Real maintenance** of frameworks and annotation tools (last tagged release, commit
   tempo, open CVEs) before pinning them.
5. Version and hardware support of **ONNX / ONNX Runtime / TensorRT / OpenVINO / LiteRT / Core ML**
   and their compatibility matrix with the model you are exporting.
6. **AI Act**: current text of art. 5 and art. 50, timetable and amendments from the *Digital
   Omnibus* — cross-check it with `ai-governance-standards` §3.3 and with the OJEU.
7. **Declared gap**: this document **sets no accuracy, mAP, FPS or latency figure whatsoever**.
   No *benchmark* figures have been verified together with their measurement conditions (resolution, hardware,
   precision, batch size, whether it includes NMS and preprocessing), and **without those conditions a figure
   means nothing**. If you need to compare, measure it yourself on your hardware with your frozen dataset.

If the web contradicts this document, **the web wins** — flag the discrepancy.
