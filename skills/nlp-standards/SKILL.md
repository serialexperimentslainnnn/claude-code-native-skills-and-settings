---
name: nlp-standards
description: Natural language processing as a discipline, deciding between a regex, a small specialised model and an LLM. Use when building text classification, named entity recognition, sentiment analysis, summarisation, semantic similarity, clustering or translation, working with spaCy (en_core_web_sm, es_core_news_sm, nlp.pipe, Doc, Span, EntityRuler), NLTK, Stanza, Flair, gensim, scikit-learn TfidfVectorizer, setfit or a fine-tuned encoder, choosing an embedding model (sentence-transformers, BAAI/bge, intfloat/e5, nomic-embed, Alibaba gte, Qwen3-Embedding, jina-embeddings) and reading its weights licence, planning a re-index after changing embedding model, evaluating with MTEB, tokenising with tiktoken, sentencepiece or huggingface tokenizers and explaining why token count is not word count, normalising Unicode with NFC/NFKC, detecting language with fastText lid, lingua or langdetect, handling accents, casing, emoji and zero-width characters, measuring macro-F1 and per-class recall on an imbalanced label set, auditing an annotated text corpus and inter-annotator agreement, or checking that a model that works in English also works in Spanish.
---

# Natural language processing (NLP) standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **NLP as a discipline**: deciding what to solve a text task with, preparing the
text, choosing and evaluating small models and embedding models, building labelled corpora and
measuring honestly — including **per-language measurement**.

Triggers: `spacy`, `nlp(...)`, `nlp.pipe`, `en_core_web_sm`, `es_core_news_sm`, `EntityRuler`,
`nltk`, `stanza`, `flair`, `gensim`, `TfidfVectorizer`, `CountVectorizer`, `setfit`,
`sentence-transformers`, `SentenceTransformer(...)`, `model.encode(...)`, `bge-`/`e5-`/`gte-`/
`nomic-embed`/`jina-embeddings`, `mteb`, `tiktoken`, `sentencepiece`, `AutoTokenizer`,
`unicodedata.normalize`, `NFC`/`NFKC`, `casefold()`, `langdetect`, `lingua`, `lid.176`,
`macro-F1`, `classification_report`, "classify tickets", "extract entities", "detect
sentiment", "summarise documents", "find similar texts", "group comments", "translate",
"it works in English but not in Spanish", "how many tokens does this take up".

**Domain thesis**: **many tasks that once required a trained NLP model are today solved by
an LLM with a prompt, and many others should not use an LLM at all.** The criteria are three-way
and are decided **in this order**:

1. **Rule or regular expression** — when the pattern is formal and closed: NIF, IBAN, licence plate,
   product code, date, URL, invoice number. **It is exact, auditable, free, instantaneous and
   deterministic.** A model has none of those four properties.
2. **Small specialised model** — when there is high volume, stable in-house labels, or
   constraints of cost, latency, determinism or data sovereignty. A classifier over
   embeddings, a fine-tuned encoder, `setfit` with few examples, or a spaCy pipeline.
3. **LLM** — when the task is open-ended, the output is free text, the classes change often, there
   is no labelled data and the volume is low or the value per document is high.

**The expensive mistake goes in both directions**: putting an LLM where a `re.match` was enough adds cost,
latency and permanent non-determinism; and setting up a six-month labelling project for
a task a prompt solved in an afternoon is throwing away the budget. **Prototype with an LLM to
discover whether the task is feasible and to generate the initial labelled set; decide afterwards whether it
stays or is distilled into a small model** (§3.2).

**Not applicable**:

- `llm-app-engineering-standards`, `rag-standards` and `llm-evaluation-standards` (**written —
  critical boundary**): **the product built on a third-party LLM belongs to the first** (prompt as an
  artifact, structured output, context window, retries, prompt injection), **retrieval
  belongs to the second** (ingestion, *chunking*, index, hybrid, *reranking*, citation) and
  **measuring the generative and non-deterministic belongs to the third** (LLM judges, golden cases,
  significance). What remains here is NLP as a discipline: **the three-way decision**, real text, the
  small models, embeddings **as an artifact** and deterministic metrics. Arbitration
  rule: if the output is a label, a vector or a span of the text, it belongs here; if it is generated
  prose, it belongs to them.
- `deep-learning-standards`, `model-finetuning-standards` and `classical-ml-standards` (**written**):
  **training your own network and its loop belong to the first**, **moving the weights of someone else's model
  to the second** and **tabular data to the third**, which additionally owns the common mechanics —leakage,
  splitting, calibration, decision threshold, baseline— that are **not duplicated here**. A text
  vectorised and fed into a `LogisticRegression` is a tabular problem with a peculiar preprocessing
  step, and its validation is done with the rules from there.
- `mlops-standards`, `local-inference-standards`, `gpu-computing-standards`, `mlsecops-standards` and
  `ai-governance-standards` (**written**): **the production lifecycle belongs to the first**
  —registry, promotion, drift, retraining—, **serving your own weights to the second**, **the GPU
  as a resource to the third**, **the provenance of the weights and attacks on the model to the
  fourth**, and **risk classification, the AI Act and the inventory to the fifth**.
- Common ones: `vector-db-standards` (**the vector store, its indexes and its operation**),
  `i18n-standards` (**collation, locale formats, plurals, text direction and the Unicode
  detail**; here only what breaks a model), `search-engines-standards` (lexical search),
  `privacy-engineering-standards` (**free text is the worst place for personal data**),
  `opensource-licensing-standards` (licence policy, including those of models and corpora),
  `data-engineering-standards` and `data-governance-quality-standards`, `python-standards`,
  `finops-standards` and `green-it-standards` (cost and footprint of inference),
  `grc-compliance-standards`.
- Sibling modality skills: `computer-vision-standards` (image and video) and
  `multimodal-genai-standards` (image, audio and video generation). **They are three modalities, not
  three levels**: none is a prerequisite of another. **Arbitration rule with
  `multimodal-genai-standards`: the label, the vector and the span of text belong here; prose,
  semantic extraction and generation over image, audio, video or document —including
  turning a PDF or a scan into usable text— are theirs.** If the document is already clean
  digital text, extracting it and applying NLP is cheaper, more exact and more auditable than looking at it with a VLM.

## 2. Default decisions

> Verify the latest version and **the licence of the weights, model by model and language by language**,
> on the web before pinning it in a real project (§8).

| Decision | Default | Justifiable alternative |
|---|---|---|
| Formal, closed pattern | **Regular expression with a case test** | Nothing. It is the answer |
| Classification baseline | **TF-IDF + logistic regression** (`scikit-learn`) | Useful to know whether the problem is easy; if it wins, you are done |
| Classification with few examples | **Embeddings + linear classifier**, or `setfit` | LLM with a prompt if the classes change every week |
| Generic entity extraction | **spaCy** (MIT), with the right language model | Stanza (Apache-2.0) if accuracy matters more than speed |
| In-house entity extraction | Rules (`EntityRuler`) first, model afterwards | LLM with a schema if the domain is open-ended and the volume low |
| Similarity and clustering | **Embeddings** from a permissive model | TF-IDF if the vocabulary is closed and technical |
| Summarisation and translation | **LLM** (`llm-app-engineering-standards`) | A dedicated model only if there is massive volume or the data cannot leave |
| Self-hosted embeddings | **`bge-m3` (MIT), `multilingual-e5-large` (MIT), `gte-multilingual-base` (Apache-2.0), `Qwen3-Embedding` (Apache-2.0), `nomic-embed-text-v2-moe` (Apache-2.0)** — licences verified | A managed API if there is no data-egress restriction |
| Language detection | **`lingua`** (Apache-2.0 verified) | `fastText` LID **only after verifying its licence**: the model card on Hugging Face declares **CC-BY-NC-4.0** (§5) |
| Normalisation | **NFC** to store; NFKC only to compare | Never NFKD "by default" without knowing what it collapses |
| Vectors and their store | See `vector-db-standards` | — |

## 3. Classic tasks and the right answer today

### 3.1 What to use for each task

| Task | Default answer today | When it is not that |
|---|---|---|
| **Text classification** | Stable labels + volume → **small model**; changing labels or no data → LLM | If there are two classes and they are separable by keywords, it is a rule |
| **Entity extraction** | Generic entities (person, place, date, money) → **spaCy/Stanza**; domain-specific entities → rules + fine-tuned model | Fixed format (invoices, codes) → **regular expression**, not a model |
| **Sentiment analysis** | **LLM** for open text; small model if volume is high | What is almost always really wanted is to **classify the reason for the complaint**, not the polarity. Ask what decision the result changes before building anything |
| **Summarisation** | **LLM**, no discussion | If extractive and verifiable output is needed, selecting sentences from the original is more defensible |
| **Semantic similarity** | **Embeddings** + cosine | Exact or near duplicates: *hashing* and edit distance, no model |
| **Clustering** | Embeddings + clustering, and **a human naming the groups** | Without names, a clustering is not a result: it is a picture |
| **Translation** | **LLM** or dedicated service | Highly technical domain with an in-house glossary: demands a forced glossary and human review |

### 3.2 When a small model beats the LLM

Five reasons, and one is enough to justify it:

- **Cost per million documents.** An API LLM charges per input and output token on
  **each** document; an encoder or a linear classifier is paid for once in your own compute. **Do
  the maths with your volume, your average document length and the current price** —not with an
  intuition nor with a remembered figure— and compare it against the cost of training and maintaining the small one.
  Beyond a certain volume the difference is orders of magnitude, and that crossover point is
  calculated, not estimated.
- **Latency.** A classifier over embeddings answers in milliseconds and **in batches**; an
  LLM does not. If it is on the synchronous path of a user request, this usually decides it on its own.
- **Local execution.** CPU, edge or isolated network: the small model fits where the LLM does not.
- **Determinism.** Same input, same output, always. Auditable, testable with exact equality
  and explainable to whoever asks. An LLM offers none of that.
- **Data that cannot leave.** Medical records, court files, data about minors, trade
  secrets. If the answer to "can we send this to a third party?" is no, the debate is over.

**Recommended pattern**: use the LLM to **label** an initial corpus (with human review of a
sample, §4.3), train the small model with it and **compare the two on the same test
set**. If the small one gets close enough, the small one stays. **Distillation is a
cost decision, not a quality one**: document the loss you accept.

## 4. Real text, corpora and labelling

### 4.1 Normalisation

- **Explicit Unicode normalisation at ingestion**: two visually identical texts with different
  composition forms (precomposed `é` vs. `e` + combining accent) are different strings, do not
  match in an index and produce phantom duplicates. **NFC to store; NFKC only when the
  comparison must ignore compatibility variants**, knowing that NFKC collapses ligatures,
  superscripts, widths and symbols and **can change the meaning**.
- **Mandatory minimum cleaning**: zero-width characters and bidirectional controls (a real vector
  for spoofing and injection, see `mlsecops-standards`), non-breaking spaces, typographic
  quotes, assorted dashes and heterogeneous line breaks.
- **`lower()` is not `casefold()`** and neither is safe by default: in Turkish the `I` does not behave
  as it does in Spanish, and lowercasing destroys signal in acronyms and proper nouns. Decide whether
  to lowercase **per task**, not out of habit.
- **Emoji and punctuation are signal**, not noise, in user text. Deleting them "to clean up" is
  losing information.
- **Language detection before processing**: each text carries its detected language as metadata.
  Detectors fail on short texts and on mixtures; for strings of a few words, **confidence
  matters more than the label** and you need an "unknown" branch.

### 4.2 Tokenisation and counting

**The token count is not the word count nor the character count**, and it depends on the specific
tokeniser of the specific model. Practical consequences:

- **To estimate cost or context, count with the tokeniser of the model you are going to use**, not with
  `len(text.split())` nor with a rule of three. Changing model changes the count.
- **Non-English text consumes more tokens** than the same content in English with most
  tokenisers, and languages with non-Latin scripts, even more. That is **more cost and less
  effective content per window** for the same document — measure it in your languages before
  budgeting.
- **Truncating by tokens splits words and multibyte characters**: truncate by units of the
  tokeniser, not by characters, and never by bytes.
- The detail of collation, locale-specific casing, plurals and text direction lives in
  `i18n-standards`; here only what breaks a model.

### 4.3 Labelled corpus — the same rigour as in vision

- **Labelling guide written before the first label**, with edge cases and examples.
- **Inter-annotator agreement measured** over an overlapping subset, with a statistic that corrects
  for chance. **If two people do not agree, the model cannot learn it and the evaluation means
  nothing**: agreement is the ceiling of the metric.
- **Closed and disjoint taxonomy**, or declared multi-label. Half of classification
  projects fail because the classes overlap and nobody said so.
- **Labels generated by an LLM are audited with a human sample** and marked as synthetic in the
  lineage. A test set is **never** labelled by an LLM alone: it turns into measuring the
  similarity to that LLM.
- **Split by group**: messages from the same thread, the same customer or the same author go whole
  to the same side. And if the data has time, **temporal split**.
- **Version the corpus and the guide** (`data-governance-quality-standards`). A corpus without a version is
  neither evaluable nor reproducible.

## 5. Licences, personal data and bias

**The licence of the code is not that of the model, and in NLP it changes even between languages of the same
package.** Verified by reading the raw metadata (Aug 2026):

- **spaCy** is MIT, but **its models do not share the licence**: `en_core_web_sm` and `en_core_web_trf`
  are **MIT**, `de_core_news_sm` and `xx_ent_wiki_sm` **MIT**, but **`es_core_news_sm/md`,
  `es_dep_news_trf` and `ca_core_news_sm` are GNU GPL 3.0**, `fr_core_news_sm` is **LGPL-LR**,
  `pt_core_news_sm` and `nl_core_news_sm` are **CC BY-SA 4.0** and `it_core_news_sm` is
  **CC BY-NC-SA 3.0 — non-commercial**. The cause is the training corpus, which drags its
  licence into the model. **Running `python -m spacy download es_core_news_sm` in a closed product
  is a licence problem nobody looks at.**
- **Embedding models**: `jina-embeddings-v3` declares **CC-BY-NC-4.0** on its card, that is,
  **non-commercial without a separate licence**; and **`facebook/fasttext-language-identification`, the
  most copied language detector in the world, declares CC-BY-NC-4.0 on Hugging Face.** Against them,
  verified as permissive: `bge-m3` (MIT), `multilingual-e5-large` (MIT),
  `gte-multilingual-base` (Apache-2.0), `Qwen3-Embedding` (Apache-2.0), `nomic-embed-text-v2-moe`
  (Apache-2.0), `mxbai-embed-large-v1` (Apache-2.0), `all-MiniLM-L6-v2` (Apache-2.0).
  **Declared discrepancy**: on `jina-embeddings-v4` the sources contradict each other —it was published
  labelled as CC-BY-NC-4.0 and was later corrected towards the research licence of the base model
  it derives from—; **do not use it without verifying the current card yourself**.
- **Copyleft in libraries**: `gensim` is **LGPL-2.1**, not permissive. `NLTK`, `Stanza`,
  `sentence-transformers`, `tokenizers`, `sentencepiece` and `MTEB` are **Apache-2.0**; `spaCy`,
  `Flair`, `fastText` (code) and `tiktoken` are **MIT**. Verified raw.
- **Corpora**: many are research-only or carry a *ShareAlike* clause, which **contaminates the
  model trained with them**. The corpus licence is a project requirement, not a detail
  of the bibliography.

**Personal data**: **free text is the worst place in the system for personal data** — it is not
in a column, it cannot be typed and it appears where nobody expects it (comments, attachments,
transcripts, "notes" fields). Criteria: detect and **pseudonymise at ingestion**, not
before display; keep the reversal map separately and with its own access control; and remember that
**a model trained on text with personal data is hard to "unlabel" and very hard to
subject to a deletion**. Legal basis, DPIA, retention and rights: `privacy-engineering-standards`.

**Bias and fairness as a property of the system, not of the model**: measure it over **your** output and **your**
subgroups —language, regional variety, formal/informal register, text length, channel—
comparing error rates **per subgroup**, not overall accuracy. A content moderator that
flags colloquial Spanish more than formal Spanish, or a CV classifier that performs worse with
names of a given origin, is a system failure even if the base model is the same for everyone.
What is not measured per subgroup is discovered through complaints.

## 6. Embeddings, evaluation and production

**Embeddings**: an embedding model turns text into a vector whose **geometry belongs
to that model**. Hence the rule that is most expensive to ignore:

- **Changing embedding model forces reindexing the whole corpus.** The vectors of the new
  model and those of the old one are not comparable even if they have the same dimension; mixing them degrades
  search silently, with no error or alarm. **Treat it as a data migration**: new
  collection, full reindex, quality comparison against the previous one and atomic switchover,
  with a possible rollback. Never a partial reindex "as it goes".
- **The exact name and version of the model, its dimension, whether it normalises the vector, the distance
  metric and the instruction prefix it requires** (several models require prefixing query and
  document differently, and omitting it degrades a lot without warning) are **versioned alongside the index**
  as mandatory metadata.
- **Choice**: multilingual if your corpus is —an English-only model over Spanish text is a
  silent failure—, size and dimension in line with the cost of storage and querying, maximum
  input length compatible with your documents, and **verified licence** (§5).
- **Embedding evaluation**: public rankings (MTEB) serve to **rule out**, not to
  choose. The choice is made with **your** set of real queries and documents and an agreed retrieval
  metric. The store, its indexes and its operation: `vector-db-standards`.

**Evaluation**:

- **Overall accuracy misleads as soon as there is imbalance.** With 95 % of one class, "always the
  majority one" scores 95 % and is useless. **Report macro-F1 and per-class precision/recall/F1**,
  and set the acceptance criterion on the class that decides the business.
- **Full confusion matrix**, always: it distinguishes "it did not detect it" from "it confused it with
  something else"; they have different fixes.
- **Decision threshold as a product decision**, with the asymmetric cost made explicit, and **chosen
  on validation, never by looking at the test set** (`classical-ml-standards`).
- **Mandatory baseline** (rule, TF-IDF, majority class) on the same set. A model that
  does not beat it is not deployed.
- **Generative tasks —summarisation, translation, rewriting— are not evaluated with these metrics**:
  method, judges and significance in `llm-evaluation-standards`. Here only the requirement that
  evaluation **exists** before deploying.
- **Language is a first-class evaluation dimension.** A model that does well in English
  can do badly in Spanish, and worse in Catalan, Galician or Basque. **Report the metric broken down by
  language and by variety**, with a test set of its own for each; an overall average dominated
  by English hides exactly the failure that is going to hurt you. The same applies to mixed text
  (two languages in one sentence), which is the norm in support and social media, not the exception.

**Production**:

- **The preprocessing pipeline is versioned with the model and there is only one.** Normalisation,
  cleaning, tokenisation and truncation must be **identical** in training and in serving; a
  difference does not raise an error, it gives less accuracy. Equality test over reference texts, in CI.
- **Log the detected language, the length in tokens and the confidence of the prediction** per
  request: they are the three signals that anticipate degradation before anyone complains.
- **Language drift**: new vocabulary, slang, channel change (from email to chat), campaigns and
  new product names. Watch the rate of "unknown"/low confidence and the proportion of
  out-of-vocabulary tokens. Drift governance: `mlops-standards`.

## 7. Sustainability and prohibitions

Maintenance: pin the version of the model, the tokeniser and the preprocessing pipeline as a single
artifact. When upgrading the version of an NLP library, **re-run the full evaluation before
promoting**: a change of tokeniser or of default model moves the metrics without warning.

- ❌ **FORBIDDEN** to use an LLM for what a regular expression or a lookup table solves.
- ❌ **FORBIDDEN** to set up a labelling project without first checking with a prototype that
  the task is feasible and that the label is consistent.
- ❌ **FORBIDDEN** to compare models on a public set and deploy in another domain as if
  it measured the same thing.
- ❌ **FORBIDDEN** to change embedding model without reindexing the whole corpus.
- ❌ **FORBIDDEN** to mix vectors from two models or two versions in the same index.
- ❌ **FORBIDDEN** to report overall accuracy on an imbalanced problem without per-class metrics.
- ❌ **FORBIDDEN** to evaluate only in English a system that will be used in other languages.
- ❌ **FORBIDDEN** to deploy model weights without having read their licence (and that of the corpus they
  were trained on): in spaCy it changes per language, and there are general-purpose models that are **non-commercial**.
- ❌ **FORBIDDEN** to use `gensim` or another copyleft dependency without putting it through the licence policy.
- ❌ **FORBIDDEN** to label the test set with an LLM without human review.
- ❌ **FORBIDDEN** to have two implementations of the preprocessing, one for training and one for serving.
- ❌ **FORBIDDEN** to tune the threshold by looking at the test set.
- ❌ **FORBIDDEN** to send text with personal data to a third party without a legal basis and without having
  pseudonymised what can be pseudonymised.
- ❌ **FORBIDDEN** to treat sentiment analysis as a business result: without the decision
  it changes, it is a decorative metric.
- ❌ **FORBIDDEN** to deliver a clustering without a human having named and validated the groups.

## 8. Mandatory web verification

1. **Licence of the weights, model by model and —in spaCy— language by language**, reading the metadata or the
   card raw. The licence of the code package is **not** that of the model.
2. **Licence of the corpus** the model you are going to use was trained on, and whether it drags *NonCommercial*
   or *ShareAlike* into the result.
3. **Current status and licence of `jina-embeddings-v4`**: the sources contradict each other (§5).
4. Latest version and maintenance status of spaCy, Stanza, sentence-transformers and of the chosen
   embedding model; and whether the tokeniser changed between versions.
5. **Current price per token** of the provider you compare cost against, and the real context
   size — the crossover-point calculation (§3.2) expires with every tariff change.
6. Status of MTEB and of any ranking you use to rule out candidates: it changes sets and
   methodology.
7. **Declared gap**: this document **pins no figure for accuracy, F1, latency, cost per
   million documents or ranking position**. No figures have been verified with their measurement
   conditions (set, language, length, hardware, model version), and **without those conditions a
   figure means nothing**. Measure yourself, with your corpus and your hardware.

If the web contradicts this document, **the web wins** — flag the discrepancy.
