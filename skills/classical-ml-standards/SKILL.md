---
name: classical-ml-standards
description: Classical (non-deep) machine learning on tabular data as an engineering discipline. Use when deciding whether a model is needed at all instead of a SQL query, a business rule or a heuristic, splitting data with train_test_split, StratifiedKFold, GroupKFold, TimeSeriesSplit or nested cross-validation, hunting data leakage from a scaler fit on the full dataset, a target-encoded column, an ID column or a future timestamp, building a scikit-learn Pipeline and ColumnTransformer so preprocessing is fit inside the fold, training gradient boosting with xgboost, lightgbm, catboost, HistGradientBoostingClassifier or a linear/logistic baseline with statsmodels, choosing metrics with accuracy_score, roc_auc_score, average_precision_score, precision_recall_curve, f1_score, confusion_matrix, calibrating probabilities with CalibratedClassifierCV, brier_score_loss or a reliability diagram, picking a decision threshold as a product decision, resampling with imbalanced-learn SMOTE and its calibration cost, interpreting with feature_importances_, permutation_importance, shap or partial dependence, or backtesting a time series with walk-forward validation.
---

# Classical machine learning standards (tabular)

Criteria verified as of **Aug 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **building and evaluating a non-deep predictive model on structured data**: whether
a model is needed at all, splitting, leakage, validation, metrics and threshold, calibration, model
family, features, imbalance, interpretability and time series.

Triggers: `sklearn`, `Pipeline`, `ColumnTransformer`, `train_test_split`, `StratifiedKFold`,
`GroupKFold`, `TimeSeriesSplit`, `cross_val_score`, `xgboost`, `lightgbm`, `catboost`,
`HistGradientBoostingClassifier`, `LogisticRegression`, `statsmodels`, `roc_auc_score`,
`average_precision_score`, `brier_score_loss`, `CalibratedClassifierCV`, `feature_importances_`,
`permutation_importance`, `shap`, `imblearn`/`SMOTE`, `joblib.dump`, "0.99 accuracy", "imbalanced
classes", "which threshold do I set?", "the probabilities do not add up", "leakage", "backtest",
"predict churn / default / fraud / demand".

**Domain thesis — it orders the rest of the document**:

1. **The first question is not which model, but whether a model is needed at all.** A business rule,
   a heuristic or a SQL query solves a good part of what arrives labelled as an "ML case",
   with almost zero operational cost and auditable behaviour (§2.0).
2. **In tabular data, classical ML is still the *default*** — by comparative evidence (§2.1) and
   by inference cost, training time and debuggability.
3. **Data leakage is the number one cause of fake models**: excellent metrics
   in validation and useless ones in production almost always mean the model saw something
   that will not exist at prediction time.
4. **A number without a baseline means nothing.** AUC 0.84 can be excellent or worse than
   always predicting the majority class; without a baseline there is no way to know which.

**`classical-ml` is not "small deep learning"**: it is another family of models, with other
assumptions, other failure modes and another economics.

**Not applicable**:

- `mlops-standards` (**written — critical boundary**): **the model's lifecycle in
  production is theirs** — data and experiment versioning, registry, *feature store*,
  deployment, *train/serve skew*, drift, retraining and retirement. **Here, how the model is trained and
  evaluated before getting there.** Arbitration: "is it good and why should I believe it?" belongs
  here; "how do I promote it, watch it and roll it back?" is theirs. *Fairness* and the threshold are
  computed here; monitoring them over time is theirs.
- `deep-learning-standards` and `model-finetuning-standards` (**this same wave**): your own deep
  networks and modification of pretrained weights. The boundary is the model family, not the
  data domain: **if you are going to train a network on tabular data, the justification against
  *gradient boosting* is required here (§2.1) and the training mechanics live there.**
- `llm-app-engineering-standards`, `rag-standards`, `llm-evaluation-standards`,
  `ai-agents-standards` (**written**): everything that happens on top of a third-party LLM. Practical
  boundary: **a tabular classification with historical labels is not a job for an LLM**;
  free text without labels is not a job for this skill.
- `data-engineering-standards`, `data-governance-quality-standards`,
  `data-warehouse-modeling-standards`, `sql-standards` (**written**): the pipeline, the contract,
  the quality, the grain and the query. Here it is **required** that the training data have a
  stable definition and a reliable timestamp; producing it is theirs. **If the solution was a
  `GROUP BY`, §2.0 rules and the implementation is theirs.**
- `privacy-engineering-standards` (**personal data in the training set**: lawfulness,
  minimisation, retention, DPIA and erasure on an already-trained model — here only asking
  the question before training is required) and `ai-governance-standards` (**risk classification,
  AI Act and inventory**: a threshold that denies credit or filters candidates is a regulated decision —
  the number is computed here, acceptability is decided there).
- `analytics-bi-standards` (dashboard, not automated prediction); `python-standards`,
  `r-standards`, `julia-standards` (language and environment); `finops-standards`, `green-it-standards`
  (cost and footprint); `mlsecops-standards` (poisoning, provenance, attacks);
  `gpu-computing-standards` (the GPU as a resource); `computer-vision-standards`, `nlp-standards`,
  `multimodal-genai-standards` (applications per modality).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

### 2.0 Is a model needed? (mandatory gate)

| Situation | Correct solution |
|---|---|
| An expert can write the rule and it fits in 10 conditions | **Business rule**, versioned in code |
| The criterion is an aggregate or a ranking over existing data | **SQL query / view** |
| There is weak signal but the volume of decisions is low and the cost of error high | **Heuristic + human review** |
| There are no labels, or there are <1000 and they are noisy | **There is no model**: instrument and label first |
| Multivariate relationship, abundant labels, repetitive and error-tolerant decision | **Model** |

**Hard rule**: a model introduces retraining, monitoring, drift and an explanation
surface towards the customer; if a rule obtains most of the benefit, the model must
justify the rest against that permanent cost.

### 2.1 Tabular: classical as the default — the evidence

- Grinsztajn, Oyallon and Varoquaux, *"Why do tree-based models still outperform deep learning on
  tabular data?"* (arXiv:2207.08815, v1 18 Jul 2022). Methodology, verbatim: *"We define a
  standard set of 45 datasets from varied domains with clear characteristics of tabular data and
  a benchmarking methodology accounting for both fitting models and finding good
  hyperparameters"*; conclusion verbatim: *"tree-based models remain state-of-the-art on
  medium-sized data (~10K samples) even without accounting for their superior speed"*. **Limit
  declared by the authors: medium size (~10K).**
- Erickson et al., *TabArena: A Living Benchmark for Machine Learning on Tabular Data*
  (arXiv:2506.16791, v1 20 Jun 2025, v4 3 Nov 2025). Verbatim: *"While gradient-boosted trees are
  still strong contenders on practical tabular datasets, we observe that deep learning methods
  have caught up under larger time budgets with ensembling. At the same time, foundation models
  excel on smaller datasets."*; and their own warning: *"some deep learning models are
  overrepresented in cross-model ensembles due to validation set overfitting"*.

**Read this as criteria, not as a headline**: *gradient boosting* is the correct starting point in
tabular data, and the one that loses the comparison is the network **with the compute and ensembling
budget of a real project**, not that of a paper. Tabular foundation models (the TabPFN line) are
a moving front and **their strongest figures come from reports by their own authors:
they are not cited here as established** — measure on your own dataset against a tuned GBDT (§8).

### 2.2 Toolchain

| Piece | Choice | Verified version (Aug 2026) | Licence (read in the repo) |
|---|---|---|---|
| Base | scikit-learn | 1.9.0 (2 Jun 2026, PyPI) | BSD-3-Clause |
| General GBDT | XGBoost | 3.4.0 (4 Aug 2026, PyPI; requires Python ≥3.12) | Apache-2.0 |
| Fast GBDT / large volume | LightGBM | 4.7.0 (18 Jul 2026, PyPI) | MIT |
| GBDT with native categoricals | CatBoost | 1.2.10 (18 Feb 2026, PyPI) | Apache-2.0 (© 2017-2026 YANDEX LLC) |
| Explainability | SHAP | 0.52.0 (28 May 2026, PyPI) | MIT |
| Statistical inference / CI | statsmodels | verify | verify |

- **The three boosting libraries are permissive and suitable for commercial use.** LightGBM is MIT, without the
  patent grant that Apache-2.0 gives (XGBoost, CatBoost): if your policy requires a *patent
  grant*, that decides it (`opensource-licensing-standards`).
- **Verified change of origin**: LightGBM is no longer published from `microsoft/LightGBM`; PyPI
  4.7.0 points to `github.com/lightgbm-org/LightGBM`, whose raw `LICENSE` keeps MIT with
  copyright by Microsoft **and** "The LightGBM developers". Update URLs, SBOM and *pins*.
- **Without a GPU and with a medium-sized dataset, `HistGradientBoostingClassifier` avoids a whole
  dependency.** Adding XGBoost/LightGBM/CatBoost is justified by measured performance, native
  categoricals or distributed training, not by habit.

## 3. Minimum defensible workflow

1. **Decision unit and prediction instant**: what is predicted, for whom, when and with what
   information **available at that moment**. Without this there is no correct dataset.
2. **Split the data BEFORE looking at anything**: exploration, statistics, feature selection and
   imputation are decided on the training set; the test set is separated first and is not touched (§7).
3. **Dumb baseline** (majority class, mean, "the same as yesterday", the rule in production) and
   **honest baseline** (regularised regression or a single tree, inside the `Pipeline`).
4. **Candidate model**: *gradient boosting*, with validation appropriate to the data (§4.2).
5. **Calibration and threshold** (§4.3, §4.4) and **a single evaluation on the test set**, with the baseline alongside.

All preprocessing lives **inside** the `Pipeline`/`ColumnTransformer` that is fitted in each
fold: a `fit_transform` over the full dataset before splitting is leakage, even if it is "only"
a `StandardScaler`.

## 4. Validation, metrics and threshold

### 4.1 Data leakage — the three cases that produce almost every fake model

- **Temporal leakage**: a feature that will not yet exist in production, or computed with
  information later than the prediction instant (aggregates over "the whole history", columns
  updated *in place*, tables without versioning). Symptom: unrealistic metrics and a dominant
  variable that "makes sense" after the fact.
- **Leakage from preprocessing fitted on the whole set**: scaling, imputing with the global
  mean, selecting features or encoding the *target* using the validation set too. **The *target
  encoding* is the most treacherous case: it requires out-of-fold encoding.**
- **Identifier leakage**: an `id`, hash, case number or sequential code that encodes the
  order or the class; it gives itself away as a causally meaningless variable high up in importance.
- **Detection**: if the model beats the baseline by a surprising margin, the default
  hypothesis is leakage, not talent. Reproduce it with a real temporal cut before celebrating.

### 4.2 Validation

| Data structure | Correct split | Forbidden |
|---|---|---|
| i.i.d., balanced classes | K-fold | — |
| i.i.d., imbalanced classes | Stratified K-fold | — |
| Several rows per entity (customer, patient, device) | `GroupKFold` / `StratifiedGroupKFold` by entity | Random split: the same entity in train and test |
| Temporal | Walk-forward validation, cut by date, `TimeSeriesSplit` | Random split: training with the future |
| Hyperparameter selection + error estimation | Nested cross-validation | Reporting the best CV as an unbiased estimate |

**A random split is incorrect on temporal or grouped data**, and it produces
exactly the same symptom as leakage: a number that does not reproduce in production.

### 4.3 Metrics with judgement

- ***Accuracy* is useless with imbalanced classes**: at 1 % positives,
  always predicting "negative" gives 99 %. It is never reported on its own.
- **Precision / recall / F1**: they are chosen by the asymmetric cost of the error. F1 has no
  business meaning of its own: it is for comparing, not for justifying.
- **ROC versus precision-recall**: with scarce positives the ROC is optimistic (the false
  positive rate is diluted in a huge denominator). **With strong imbalance the precision-recall curve
  and its *average precision* rule**, with the prevalence written alongside as a baseline.
- **Calibration: what almost nobody measures and what the business needs.** If the model says 0.7,
  does it happen 70 % of the time? It is measured with the *Brier score* and a reliability diagram and corrected
  with calibration (Platt/isotonic) fitted on a separate set. Good discrimination with
  poor calibration is useless for any decision that multiplies probability by an amount.
- **Regression**: MAE/RMSE depending on whether you penalise the large error; MAPE breaks with zeros and small
  values. Report in business units alongside the baseline.

### 4.4 The threshold is a product decision

The model produces a probability; **the threshold turns it into an action and belongs to whoever bears
the cost of the error**, not to whoever trains it. It is set with the cost matrix (false positive ×
volume against false negative × volume) or with an operational constraint (cases reviewable per
day), it is chosen on validation, it is declared and it is versioned alongside the model. **Choosing it by looking at the
test set invalidates the error estimate** (§7).

### 4.5 CI gates, in order of cost

1. A test that fails if there is a `fit`/`fit_transform` outside the `Pipeline` or before the split.
2. Dataset schema: columns, types, ranges, expected nulls.
3. No-leakage: forbidden columns excluded; an alert if a variable exceeds an absurd importance
   threshold.
4. Validation metric **against the baseline**, with a threshold that breaks the build.
5. Fixed seed and the same metric across two runs.

## 5. Data, features and imbalance

- **Feature engineering and leakage are the same problem seen twice.** Every
  feature requires answering: does this value exist at the prediction instant, with that
  latency and computed only from the past? Focus on temporal aggregates: a closed window
  before the cut.
- **High-cardinality categoricals**: native ones in CatBoost/LightGBM or out-of-fold *target
  encoding*. `OneHotEncoder` over thousands of levels is a cost mistake.
- **Imbalance**: first ask whether it is a real problem or just low prevalence. With GBDT,
  `scale_pos_weight`/class weights and an appropriate metric (§4.3) usually suffice.
- **Synthetic resampling worsens calibration.** van den Goorbergh, van Smeden, Timmerman and
  Van Calster, JAMIA 29(9):1525-1534 (2022), doi:10.1093/jamia/ocac093. Methodology: standard and
  *ridge* logistic regression under four treatments (no correction, *undersampling*,
  *oversampling* and SMOTE), evaluated on discrimination, calibration and classification, with
  Monte Carlo simulation varying size, number of predictors and event fraction.
  Result: the corrections **damage calibration by overestimating the minority class, with no
  benefit in discrimination**. **Declared discrepancy**: the follow-up on ML algorithms
  (Carriero et al., *Statistics in Medicine*, 2025) **does not generalise it to every algorithm** (§8).
  Criteria: **SMOTE is not the default step; if you use it, measure calibration before and after.**
- **PII in the training set**: lawfulness, minimisation and retention are decided in
  `privacy-engineering-standards` **before** building the dataset.

## 6. Interpretability and time series

- **Explaining the model ≠ explaining the decision.** Global importance describes the model; the
  person you are denying something asks about *their* case. Two different deliverables, and the second
  is usually the legally mandatory one.
- **Importance traps**: *split*/gain importance favours high cardinality and is
  distributed arbitrarily among correlated variables; permutation importance is preferable, it
  degrades with strong correlation and **must be computed on unseen data**.
- **SHAP and its limits**: additive local attribution, with independence assumptions in its
  usual approximations and a real compute cost. **It is not a causal measure** nor does it say what would happen
  if you changed the variable: it is for debugging and explaining a case, not for arguing for an intervention.
- **When interpretability rules, a linear model is preferable**: coefficients with
  intervals and stable behaviour. In regulated domains, the AUC difference against a
  GBDT rarely compensates for losing defensibility.
- **Time series**: walk-forward validation with retraining at each cut; lags and
  rolling windows computed only from the past; seasonality and calendar as explicit
  variables; declared horizon. Mandatory baseline: *naïve* and seasonal *naïve*.

## 7. Sustainability and prohibitions

- Review major versions of scikit-learn and of the boosting libraries every quarter. A model serialised
  with `pickle`/`joblib` **is not portable across versions**: pin the version alongside the artifact and
  test loading it in CI. Retraining, drift and retirement: `mlops-standards`.

**FORBIDDEN**:

- ❌ **Evaluating on the training data** and presenting that metric as the result.
- ❌ **Choosing the threshold by looking at the test set** (or any hyperparameter).
- ❌ **Presenting metrics without a baseline** or without the prevalence of the positive class.
- ❌ **Using feature importance as causality** ("variable X causes churn").
- ❌ Fitting any transformation on the full set before splitting.
- ❌ A random split with temporal data or with several rows per entity.
- ❌ Reporting *accuracy* as the main metric under imbalance, or AUC-ROC as the only metric with
  low prevalence.
- ❌ Delivering probabilities without measuring calibration when they feed an economic decision.
- ❌ Touching the test set more than once, or "trying another idea" on it.
- ❌ Training a model when a rule, a query or a heuristic solved the case.
- ❌ *Benchmark* figures without measurement conditions: dataset, split, tuning budget
  and baseline.

## 8. Mandatory web verification

Before committing anything in a real project, check on the web:

- Latest stable version and Python support of **scikit-learn, XGBoost, LightGBM, CatBoost, SHAP and
  statsmodels**; XGBoost 3.4.0 already requires Python ≥3.12. Breaking API changes before moving up a
  major version.
- **The origin and licence of each library read in the repo's raw `LICENSE`**, not in a
  summary. LightGBM changed organisation (`microsoft/` → `lightgbm-org/`).
- **State of the tabular classical-vs-deep literature**: the `tabarena.ai` scoreboard and
  publications after Nov 2025. Tabular foundation models move fast and
  **their most favourable figures come from their own authors**: demand methodology, compute
  budget and independent evaluation before citing them.
- **Declared gaps**: (a) no comparative performance figure (AUC, Elo, *leaderboard*
  positions) is pinned here — the available ones lack homogeneous measurement conditions and
  independent evaluation; (b) the version and licence of `statsmodels` and `imbalanced-learn` were not
  verified in this draft.
- **Declared discrepancy**: van den Goorbergh et al. (2022) concludes against imbalance
  corrections in logistic regression; the follow-up by Carriero et al. (2025) does not generalise it to
  every ML algorithm. Check the current status and measure calibration in your case.

If the web contradicts this document, **the web wins** — flag the discrepancy.
