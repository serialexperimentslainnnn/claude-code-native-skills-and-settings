---
name: green-it-standards
description: Use when the carbon or energy footprint of IT has to be a number someone can defend — Software Carbon Intensity and ISO/IEC 21031, the SCI formula (E × I + M) per R and choosing a functional unit, GHG Protocol scopes 1/2/3 and the scope 2 market-based versus location-based split, the GHG Protocol scope 2 revision with hourly matching and deliverability, grid carbon intensity data per region and hour (Electricity Maps, WattTime marginal MOER, Ember, CO2 Signal, Carbon Aware SDK, grid-intensity CLI), carbon-aware scheduling and region or time shifting, embodied versus operational emissions and hardware lifetime extension, PUE, WUE, ERF and REF under ISO/IEC 30134-2 and the EU data centre reporting scheme (Energy Efficiency Directive 2023/1791, Delegated Regulation 2024/1364, the European Database on Data Centres and its 15 May deadline), CSRD and ESRS E1 after the Omnibus Directive (EU) 2026/470, cloud provider carbon tools (AWS Sustainability console and the deprecated Customer Carbon Footprint Tool, Google Cloud Carbon Footprint, Microsoft Emissions Impact Dashboard) and why their numbers are not comparable, Cloud Carbon Footprint, Kepler, Scaphandre, RAPL and powercap energy readings, offsets versus real reduction, 100% renewable claims by certificate versus hourly matching, idle and zombie resource elimination, e-waste, WEEE, Ecodesign Regulation 2019/424 for servers and right to repair, or the energy cost of training and inference.
---

# Sustainable IT standards (Green IT)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**IT sustainability is measured or it does not exist.** There is no third option, and this
document grants none. A sustainability claim without a **baseline**, a **declared method**, a
**system boundary** and a **functional unit** is not a weak claim: **it is an empty claim**, and
it is treated as such — rejected in review exactly as a *benchmark* without execution conditions
would be rejected.

And the second half of the thesis, which is the uncomfortable one: **most of what gets published
about Green IT is not measurable**. "We optimised the code to reduce the footprint", "we migrated
to the cloud and we are greener", "our region is 100% renewable" — none of the three is
verifiable as written, and all three are real sentences from corporate material. This skill is
deliberately **severe with empty prose**: if a sentence carries no number, method and source, it
does not go into a document, a report or a PR.

**Starting rule, and it orders everything else**: *first turn it off, then size it, then place it,
and only then — if the scale justifies it — optimise the code* (§3.4). Almost all published Green
IT work attacks the last step, which is the one with the least impact and the highest cost. **A
switched-off server has zero carbon intensity with absolute certainty and zero engineering cost.**
No optimisation competes with that.

Covers: what can really be measured and what cannot; **SCI / ISO/IEC 21031** and the choice of
functional unit; **GHG Protocol** and why scope 3 concentrates the impact **and** the uncertainty;
**embodied vs. operational footprint** and the counter-intuitive consequence about equipment
lifetime; **grid carbon intensity per region and hour** and its data sources; the real order of
the levers; the relationship — and the **divergence** — with FinOps; **greenwashing** and creative
accounting; regulation (**CSRD** after the Omnibus, **EED** and the data centre reporting scheme,
ecodesign and **WEEE**); e-waste and life cycle; and tools, with their real reliability.

Triggers: SCI, `E × I + M`, functional unit, ISO/IEC 21031, ISO/IEC 30134-2, PUE, WUE, ERF,
REF, GHG Protocol, scope 1/2/3, *market-based* / *location-based*, *hourly matching*,
*deliverability*, MOER, marginal vs. average carbon intensity, Electricity Maps, WattTime,
Ember, CO2 Signal, Carbon Aware SDK, `grid-intensity`, Cloud Carbon Footprint, Kepler,
Scaphandre, RAPL, `powercap`, `intel-rapl`, Redfish, AWS Sustainability console, Customer Carbon
Footprint Tool, Google Cloud Carbon Footprint, Emissions Impact Dashboard, embodied footprint,
*embodied carbon*, LCA, ISO 14040/14044, PCF, CSRD, ESRS E1, Directive (EU) 2026/470,
Directive (EU) 2023/1791, Delegated Regulation (EU) 2024/1364, European Database on Data Centres,
Regulation (EU) 2019/424, WEEE, RAEE, right to repair, offsets, REC/GO/PPA,
*carbon-aware scheduling*, idle resources, *zombie*.

**Not applicable**: see `finops-standards` (**already written — an important and reciprocal
boundary, and the easiest one to confuse**: the levers are almost the same — switch off the idle,
right-size, choose a region, commit capacity — but **the metric is not**. **The economic unit —
cost per request, per user, per GB, per token — is theirs; the carbon unit — gCO2e per that same
functional unit — is ours.** Usage data is shared and **the idle-resource inventory is shared**,
but when cost and carbon diverge — and they do, §3.5 — **neither of the two wins automatically:
the divergence is declared and a human decides with both figures in front of them**),
`onprem-standards` and `homelab-standards` (**the physical data centre is theirs**: cooling,
electrical distribution, UPS, aisle containment, on-site generation, rack sizing. **Here only the
accounting of what they consume and which metrics of that data centre are reportable**),
`gpu-computing-standards` (**density, TDP, liquid cooling and GPU scheduling are already theirs**;
here **the accounting of their footprint**, operational and embodied), `aws-standards` /
`azure-standards` / `gcp-standards` (**each provider's data, tool and methodology are theirs**,
together with the concrete choice of region and service; here **why those numbers are not
comparable across providers** and what can be claimed with them), `kubernetes-standards`
(**utilisation, *requests*/*limits*, scaling and node consolidation are theirs**; here the fact
that utilisation is the highest-impact carbon lever and how it is accounted for),
`grc-compliance-standards` (**the corporate sustainability report, its assurance, the double
materiality analysis and the audit evidence are theirs**; here the technical datum that feeds it
and its method), `local-inference-standards` and `mlops-standards` (**the energy cost of training
and inference — which model, which quantisation, which batch, which accelerator — is theirs**;
here how that consumption is converted into gCO2e and with what uncertainty),
`performance-engineering-standards` (**already written**: **the methodology of measuring and
optimising — profiling, load generator, statistics, experiment reproduction — is theirs, without
exception**; here **the carbon metric** that couples to it. Corollary: *a performance optimisation
is validated with their method, not mine*; this skill does not re-decide how anything is
profiled), `opensource-licensing-standards` (**the licence of carbon measurement tools is governed
by that skill** — and there is a reason: grid intensity data has terms of use ranging from
CC BY 4.0 to "non-commercial", §2).

## 2. Default decisions

> Verify the latest version on the web before fixing it in a real project (§8).

| Area | Default | Reason / justifiable alternative |
|---|---|---|
| Software metric | **SCI** — `SCI = (E × I + M) per R` (verbatim from the GSF) | **It is a *rate*, not a total**: that is why it cannot be reduced by growing less or by buying anything. It is the only property that makes it useful for engineering |
| Reference standard | **ISO/IEC 21031:2024** (SCI) | The GSF describes it as "The only ISO-accredited carbon measurement standard for software". Verify the edition in force (§8) |
| Corporate accounting framework | **GHG Protocol** (Corporate Standard + Scope 2 Guidance + Scope 3 Standard) | It is the language CSRD, CDP and SBTi require. **It is not interchangeable with SCI** (§3.1) |
| Scope 2 | **ALWAYS report both: *location-based* and *market-based*** | CSRD requires both, and **the difference between them is the direct measure of your potential greenwashing** (§3.6). Publishing only the *market-based* one is alarm signal number one |
| Grid intensity data | **Ember** (CC BY 4.0) as the redistributable base; **Electricity Maps** or **WattTime** for hourly granularity | Ember is open and clearly licensed, but **monthly/annual**: it cannot decide *at what hour*. The other two: free tier **for a single zone**, and **non-commercial** in the case of Electricity Maps (§2 of `opensource-licensing-standards`) |
| Average vs. marginal signal | **Average for accounting; marginal (MOER) for load-shifting decisions** | **They are not interchangeable and confusing them is the most common error in the domain.** The average answers "how much did what I consumed emit"; the marginal, "how much does it change if I consume more or less right now". Using the average to justify a load shift is an invalid result |
| Host energy measurement | **RAPL / `powercap`** via Kepler or Scaphandre | It is the only thing available without a BMC. **It is the *package*, not your process**: attribution to a container or process is an **allocation model**, not a measurement (§4.2). Sampling ≥10 ms: below that you increase cost without improving accuracy |
| Physical machine energy | **Redfish / BMC / metered PDU** where access exists | It is the only real measurement of the machine. **In public cloud you do not have it**, and that is the hard limit on everything else |
| Kubernetes tool | **Kepler** (CNCF sandbox, Apache-2.0), **≥ 0.10.0** | 0.10.0 is a **complete rewrite** that dynamically discovers the structure of the host's power meter instead of assuming a fixed RAPL topology — the previous design **attributed data to a non-existent reality**. The 0.9.x line is **frozen**: no fixes, no features. **The migration is not transparent** |
| Multi-cloud estimation | **Cloud Carbon Footprint** (Apache-2.0) only for **normalised internal comparison** | It uses average constants: **it estimates, it does not measure**. And its release cadence is low (the coefficients repository is archived). **Do not use it as a source for a regulated report** |
| Cloud data for an external report | **The provider's own tool** | It is the only one the provider backs. Verify per provider whether the datum is **third-party verified** (§3.6): as of August 2026 not all are |
| Hardware lifetime in the calculation | **Always declare the assumed one** (4-5 years is usual; CCF assumes 4) | **Changing 4 for 6 years alters the result more than any code optimisation.** If it is not declared, the figure is not interpretable |
| Offsets | **Outside the reduction calculation** | They are reported **separately and afterwards**, never subtracted from the gross figure. See §7 |

## 3. What can be measured, what is estimated and what is not known

### 3.1 SCI: a rate, and the difference with corporate accounting

`SCI = (E × I + M) per R`, where **E** = energy consumed, **I** = carbon intensity of that
energy, **M** = embodied emissions of the hardware, **R** = functional unit.

Three operational consequences that must be understood before using it:

1. **It is a rate, and that is deliberate.** It does not drop because the business shrinks, nor
   because you buy certificates. It only drops if you do **more work with less**, or the same
   work with cleaner energy. **It is the only metric in this skill that an engineering team can
   move.**
2. **The functional unit `R` is the decision that determines whether the metric is useful.** It
   must be something the team *produces*: request, active user, transaction, *build*, token,
   training job. **`R` = "per server" or "per month" turns SCI into a total in disguise and
   renders it useless.** It is chosen once, documented and **not changed without recalculating
   the historical series** — changing `R` halfway through is the cleanest way to manufacture an
   improvement that does not exist.
3. **SCI uses a *consequential* approach** — quantifying the marginal change a decision causes —
   as opposed to the **attributional** approach of corporate accounting, based on average data.
   **An SCI and a GHG inventory do not add up, do not compare and do not validate each other.**
   Presenting them as if they were the same figure is a method error, not a rounding one.

**Normative status**: published as **ISO/IEC 21031:2024**. **Declared discrepancy**: the GSF page
places the ISO accreditation in **April 2024**, while other sources give publication in **March
2024** and its adoption in **May 2024**; the GSF specification was at **v1.1** (Oct 2024). The
three data points coexist in different sources. **Before citing a date in a formal document,
verify in the ISO catalogue** (§8).

### 3.2 GHG Protocol: where the impact is and where the uncertainty is

- **Scope 1**: direct combustion. In IT, practically only backup generators and leaked
  refrigerants. **Marginal, and well measured.**
- **Scope 2**: purchased electricity. **Two mandatory and non-equivalent methods**:
  *location-based* (the real intensity of the grid where you consume) and *market-based* (reflects
  the certificates, GOs and PPAs contracted). **Well measured and easy to dress up** (§3.6).
- **Scope 3**: everything else in the value chain — **hardware manufacturing, the cloud services
  you buy, the full life cycle of the equipment, your users' devices**.

**In IT, scope 3 concentrates at once almost all the impact and almost all the uncertainty, and
that is no coincidence: it is the same fact seen twice.** It is large because it includes
everything you do not control, and it is uncertain **precisely for that reason**: it depends on
manufacturer data with different methodologies, on average sectoral emission factors, and on
economic *input-output* models that convert euros spent into kg of CO2e with enormous error
margins. A company reporting scope 3 to two decimal places does not mean it knows it to two
decimal places.

**Hard rule**: **a scope 3 figure is always accompanied by its calculation method** (process-based
LCA, extrapolation, category average, or economic *input-output*) and **by the associated
uncertainty**. Without that, it is not a datum: it is an estimate presented as a datum. And a
prohibition follows: **never compare two scope 3 figures calculated with different methods** —
the difference you see will be the difference between the methods, not between the companies.

**Ongoing revision of the Scope 2 Guidance (2015) — it affects decisions you are taking today.**
Verified status: the public consultation opened on **20 Oct 2025**, closed on **31 Jan 2026** with
more than **400 responses**, and a **second consultation during 2026** is expected with **final
publication planned for 2027** (some secondary sources say **2027-2028** — **declared
discrepancy**). The draft **keeps both methods** and adds to the *market-based* one: **hourly
matching** of contractual instruments, a **deliverability requirement** (a credible geographical
link with the generator) and a complementary metric of **marginal emissions impact**. The
independent board approved taking it to consultation by **10-1** on both methods. It includes
exemptions for small organisations (**whose definition is still not settled**), a grandfathering
clause for existing contracts and phased implementation.

**Consequence for today, and this is the actionable part**: **annual certificate matching has a
known expiry date**. A PPA or a certificate portfolio that only balances in the annual total **is
going to stop supporting a clean energy claim**. If you are going to sign a multi-year energy
contract in 2026, **assess it against the hourly criterion, not the current one**. And do not
confuse scopes: this **changes the accounting, not the procurement objective**; it does not imply
an hourly matching target next year.

### 3.3 Embodied vs. operational footprint: the counter-intuitive consequence

The split between **embodied emissions** (manufacturing, transport, end of life) and
**operational** ones (electricity in use) is the most frequently misquoted datum in the domain,
because **there is no single number**: there is a range that depends on three variables that are
almost never declared.

What is documented, with its source and its method:

- A systematic study (SCARIF) compiled **96 product footprint reports from Dell, HP and
  Lenovo**, for servers published **between 2014 and 2022**, all of them produced with the
  **PAIA** tool flow. Result for the **manufacturing phase** over the total life cycle:
  **Dell 9.5%-27.7%; HP 5.4%-28.4%; Lenovo 2.9%-59.5%**.
- A 2025 study on AI hardware, *cradle-to-grave*, with a lifetime of **4-5 years**, gives the
  operational complement: **70%-90%** (2 Dell servers), **66%-94%** (2 HP),
  **39%-97%** (2 Lenovo).
- The extreme case published by the manufacturer itself: a Dell rack server with
  **5,960 kg CO2eq of use phase, more than 90% of the total** over 4 years of continuous
  operation.

**The three variables that produce that range — and they are the three that must always be
declared:**

1. **Grid carbon intensity.** On a very clean grid, **the proportion inverts**: the literature
   notes that with wind electricity the embodied fraction of an x86 processor would move to around
   **80%**. **In a decarbonised region, your problem is manufacturing, not consumption.** It is
   exactly the opposite of what the usual discourse assumes.
2. **Configuration.** In the Dell R740 LCA, **close to 80% of the embodied footprint is
   attributed to the SSDs**, and it grows linearly with capacity. **Oversizing storage is an
   embodied carbon decision, not a cost one.**
3. **Assumed lifetime.** Cloud Carbon Footprint assumes **4 years**. Changing that assumption
   moves the result more than any optimisation you are going to do.

And end of life is small: **end-of-life processing does not usually exceed 5%** of the full
cycle, and Dell's LCA estimates that recycling reduces the embodied footprint by around **1.8%**.
**This is not an argument against recycling** — recycling matters for critical raw materials and
toxicity, not for CO2e (§3.7) — it is an argument against **presenting recycling as a carbon
lever**, which is where most reports end up.

**The counter-intuitive consequence, and it is the most actionable conclusion in this skill:**
**extending equipment lifetime usually weighs more than optimising its consumption.** The embodied
footprint is a **one-off payment** amortised over the life of the equipment: going from 4 to 6
years reduces the annualised embodied portion by **a third**, without writing a line of code and
without buying anything. No energy efficiency optimisation you are going to achieve comes close to
that magnitude. **The exception that must be checked, not assumed**: if the new equipment is
substantially more efficient **and** you operate on a dirty grid, the swap may pay off. It is a
concrete calculation — annualised embodied of the new equipment vs. excess operational of the old
one — and **it must be done, not invoked**. On a clean grid it almost never comes out in favour of
renewing.

**Method trap that invalidates entire reports**: **LCA** (ISO 14040/14044) allows **amortising**
the embodied footprint over the lifetime of the functional unit; the **GHG Protocol Corporate
Standard does NOT allow amortising** capital goods emissions over the life of the hardware. **The
same fleet produces two different figures and both are correct within their framework.** Mixing
them — the usual practice — produces a number that means nothing. Always declare which framework
you are in.

### 3.4 The real order of the levers

By decreasing impact and increasing engineering cost. **The order is the rule; skipping it is the
prohibition in §7.**

1. **Switch off the idle.** Non-production environments outside working hours, orphan instances,
   unattached volumes, reserved public IPs with no use, load balancers with no *backend*, test
   clusters from two quarters ago. **Exact and verifiable reduction: 100% of what they were
   consuming.** It is the only lever with a result that requires estimating nothing. The inventory
   is literally the same one `finops-standards` uses; **it is done once and serves both**.
2. **Right-size and consolidate.** A server at 10% utilisation consumes a very high fraction of
   its maximum power: **power is not proportional to load**, and that is why consolidating two
   machines at 20% into one at 40% saves real energy and **avoids one unit of embodied
   footprint**, which is the big saving. Utilisation is the most powerful carbon lever that exists
   in `kubernetes-standards`.
3. **Extend hardware lifetime** (§3.3). Cheap, measurable and among the highest in magnitude.
4. **Choose the region.** The difference in carbon intensity between regions of the same provider
   is **more than an order of magnitude** between the best and the worst. It is a deployment
   decision with almost zero cost — **with the constraint that the region is also a decision about
   latency, data sovereignty and cost**, and those three rule over this one.
5. **Choose the hour** (*carbon-aware scheduling*). Applies **only to deferrable load**: *batch*,
   training, nightly *builds*, compactions, backups. **It does not apply to interactive load**,
   and proposing it for interactive load is the classic error. **It is decided with the marginal
   signal, not the average one** (§2). And its benefit is **estimated**; do not declare it as
   measured.
6. **Code efficiency.** **Only when the scale justifies it.** A service at 100 rps does not
   justify a rewrite for carbon: the carbon of the engineering work and of the CI hours exceeds
   the saving. At a scale of millions of requests, it does. **The threshold is calculated, not
   intuited**, and the methodology for measuring the improvement belongs to
   `performance-engineering-standards`, without exception.

**PUE is not in this list**, and that is intentional: **PUE does not measure your software**
(§4.1).

### 3.5 FinOps and carbon: they correlate, they are not the same metric

They correlate because they share levers: **switching off the idle lowers both, always**;
right-sizing too. That is why the inventory, tag-based allocation and idle resource detection
**are shared with `finops-standards` and not duplicated**.

**But they diverge, and it must be named with concrete cases:**

- **Reserved instances and savings plans**: they reduce cost **and do not change a gram of
  CO2e**. It is the purest divergence there is: **pure discount with no physical effect**. A 90%
  commitment coverage is excellent FinOps news and **a non-news** for carbon.
- **Spot instances** are much cheaper **and can worsen carbon**: an interruption forces work to be
  re-run, and **repeated work is repeated energy**. Cheap ≠ efficient.
- **Placing load in the cleanest region** may be **more expensive** than the cheap region, and
  also have worse latency. There the three things diverge at once.
- **Shifting load in time** to catch the clean window may fall into a band of high energy price or
  high provider tariff.
- **Extending hardware life** reduces carbon and **may increase operational cost**: old equipment
  consumes more per unit of work, takes up more rack and fails more.
- **New and more efficient hardware** improves cost per unit of work **and adds a new embodied
  footprint all at once** (§3.3).

**Arbitration rule**: when cost and carbon diverge, **no metric wins by default**. **Both figures
with their method** are presented and a human decides with business judgement. And the
corresponding prohibition: **a cost saving is not presented as if it were a carbon saving**, nor
the other way round. They are two numbers and both are stated.

### 3.6 Greenwashing and creative accounting

The four patterns you have to be able to detect, because you will find them **in your own
organisation** before you find them elsewhere:

1. **Offsetting instead of reducing.** An offset is a financial transaction over a third party's
   emissions; **it does not reduce a single gram of yours**. It is reported **separately and
   after** the gross reduction figure, never subtracting from it. **Hard prohibition in §7.**
2. **"100% renewable" by certificates.** Buying enough GOs/RECs to cover annual consumption allows
   reporting zero in *market-based* **while the grid feeding you burns gas at three in the
   morning**. It is accounting-correct today and **it is exactly what the Scope 2 Guidance
   revision wants to fix with hourly matching and deliverability** (§3.2). **The *location-based*
   one is the one that cannot be dressed up by buying anything.** Rule: **report both and publish
   the difference**; that difference is the honest metric of how much of your "zero" is contract
   and how much is physics.
3. **Moving system boundaries.** Migrating to the cloud "reduces" your scope 2 because **it turns
   it into someone else's scope 3** — electricity consumption has not changed; it has changed box.
   Same with outsourcing. **A boundary change is not a reduction, and presenting it as one is the
   most common form of involuntary greenwashing.**
4. **Figures without method.** A reduction percentage with no baseline, no boundary and no method
   is not comparable even with its own historical series.

**Why cloud providers' data is NOT comparable with each other.** Verified as of August 2026:

| Provider | What it publishes | Restrictions that prevent comparison |
|---|---|---|
| **AWS** | **AWS Sustainability console** (announced 31 Mar 2026), with **MBM and LBM**, broken down by region, service and scope 1/2/3. Methodology based on GHG Protocol and ISO 14064, with ICT sectoral guidance. Scope 3 (Oct 2025) covers FERA, hardware, buildings, equipment and transport; hardware is estimated with **four different routes** (process LCA, extrapolation, category average, economic *input-output*). Programmatic API (`sustainability`, `get_estimated_carbon_emissions`) and `CARBON_EMISSIONS` table in Data Exports | **The *Customer Carbon Footprint Tool* is deprecated on 30 Jun 2026**: any dashboard or script pointing at it stops working. Service granularity historically limited (EC2, S3, CloudFront; the rest aggregated into "Other"). **Four calculation routes for the same scope 3 means two of your services may not be comparable with each other** |
| **Google Cloud** | **Carbon Footprint**, following GHG Protocol; allocates its scopes 1, 2 and 3 to customers by usage; per-project data via BigQuery | **Customer-specific data is NOT verified or assured by a third party.** And starting from the **January 2026** data it changed the model for allocating to services the AI inference emissions previously unallocated: **the reported figures go up without anything having changed in your usage** — a series break that has to be annotated in the baseline |
| **Microsoft Azure** | **Emissions Impact Dashboard**, with MBM and LBM | Methodology less accessible than Google's (PDF versus web documentation) |

**Hard rule, and it admits no exception**: **do not compare carbon figures across providers.**
The system boundary, the customer allocation method, the treatment of scope 3, the temporal
granularity, the publication lag and the independent verification status all differ. The only
defensible comparison across providers is **with a third-party tool applying the same model to all
of them** (Cloud Carbon Footprint) — and then **you are comparing the model, not reality**, and it
has to be said that way in the report. The **intra-provider comparison over time is valid**,
provided you annotate series breaks such as Google's of January 2026.

### 3.7 E-waste and life cycle

- **Hierarchy, in this order and with no skips**: *do not buy* > **extend** (§3.3) > **reuse**
  (sale or donation with certified erasure) > **refurbish** > **recycle** > discard.
  Recycling is the **penultimate** resort, not the first, and its main benefit is the recovery of
  **critical raw materials and the control of toxics**, not CO2e (§3.3).
- **Equipment decommissioning**: certified erasure or destruction with evidence — it is a security
  requirement **before** a sustainability one, and that is why the criterion is governed by
  `linux-hardening-standards` / `grc-compliance-standards`; here only the requirement that
  **certified erasure is the route that enables reuse**, instead of the shredder by default.
- **Recycler chain of custody**: authorised operator and documentary traceability. Without a
  treatment certificate, **waste export becomes your legal problem**, nobody else's.
- **Procurement**: demand the manufacturer's **product footprint (PCF)** with its methodology, and
  repairability and spare-part availability requirements in the tender. **Procurement is the only
  moment when you can influence the embodied footprint** — afterwards it is already spent.

## 4. Measurement: what is a datum and what is an estimate

### 4.1 Facility metrics, and why PUE is not enough

**PUE** (ISO/IEC 30134-2) compares the total power of the facility with the power delivered to the
IT equipment. **It measures the data centre, not your software**, and this is not an external
criticism: **it is in the standard itself**, verbatim:

> "In order to determine the overall resource effectiveness or efficiency of a data centre, a
> holistic suite of metrics is required."

Four limits to bear in mind before citing a PUE:

1. **A server at 5% utilisation and another at full useful load are identical for the metric.**
   IT consumption is the **denominator**, and the standard does not assess whether that
   consumption does anything useful. **An excellent PUE is compatible with total waste.**
2. **The series sets no limits or targets** for any KPI, nor does it contemplate aggregating
   several into an overall score. Citing a PUE as a sustainability grade is a use the standard
   explicitly does not endorse — even though other schemes (EN 50600-4-2, the EU Code of Conduct)
   do set thresholds.
3. **The measurement categories break comparability**: PUE0 are estimates with no direct
   measurement; PUE1 measures after the UPS; PUE2 after the PDUs. **Two facilities citing "PUE" in
   different categories are not comparable** — and the category almost never appears in commercial
   material.
4. The standard deliberately avoids calling it *efficiency*: it uses **"effectiveness"**,
   reserving *efficiency* for ratios with the same units above and below.

There is a **2026 edition** of ISO/IEC 30134-2, with guidance for mixed-use buildings (the
**mPUE** variant), updated measurement requirements and greater clarity on unaccounted energy and
on-site generation. **Verify which one is in force and which edition your regulatory obligation
rests on** (§8). For IT-side efficiency, the metrics are elsewhere in the same series (ITEUsv /
ITEEsv and the work-per-energy ones).

### 4.2 Host measurement: what is measurement and what is allocation

- **RAPL / `powercap`** reports energy **at package/node level**. What Kepler or Scaphandre give
  you **per container, pod or process is an allocation model** — typically proportional to CPU
  utilisation — **not a measurement**. It is stated that way in the report, always. Scaphandre and
  similar tools use ratio models with linear scaling against utilisation: **valid for internal
  chargeback and trend; invalid for attributing consumption at method or function level**.
- **Concrete warning about Kepler**: up to 0.9.x it assumed a fixed power structure (core, DRAM,
  others) that **does not correspond to the real topology of many hosts** — that is, it
  **attributed data to a non-existent reality**. From **0.10.0** it discovers the meter structure
  at runtime. **If you have 0.9.x in production, your historical series carry that bias** and are
  not comparable with the new ones. And there is published academic criticism that Kepler **"has
  not been assessed for its accuracy and therefore fitness for purpose"**: **cite it with that
  caveat, not as instrumented truth.**
- **Sampling**: RAPL readings are stable at intervals of **10 ms or coarser**; below the
  millisecond you only add overhead without gaining accuracy.
- **In public cloud there is no reliable RAPL and no BMC/Redfish access.** There **everything is
  an estimate**, and the only source defensible before an auditor is the provider's.
- **Measurement has its own energy cost.** One agent per node, with its *scrape*, its series
  storage and its dashboards, consumes. **Instrumenting more than you are going to use for
  deciding is a net loss, in carbon too.**

### 4.3 What is required of a claim for it to be accepted

These are the **review gates**. A sustainability claim that does not meet them **is rejected in
review, just like a test without an assertion**:

- ❌ **No explicit baseline** (period, scope, system boundary).
- ❌ **No declared method** (SCI / GHG Protocol / LCA — and which of its routes).
- ❌ **No functional unit**, when an efficiency is claimed.
- ❌ **No source and version of the emission factor** and of the grid intensity used.
- ❌ **No declaration of whether it is measured, estimated or modelled.** Almost everything is
  estimated: saying so does not weaken the result, it makes it usable.
- ❌ **No declaration of the assumed lifetime**, when embodied footprint is involved.
- ❌ **No declaration of whether the grid signal is average or marginal** (§2).
- ❌ **With a change of functional unit, boundary or provider model mid-series**, without
  recalculating the history or annotating the break.

## 5. Regulation and third-party data

**This is not legal advice.** These dates and thresholds are engineering criteria for knowing
which data you have to be able to produce and when; your entity's specific obligation is
determined by qualified counsel and `grc-compliance-standards`.

### 5.1 CSRD after the simplification package (Omnibus)

**It changed substantially and much 2024-2025 documentation is already false.** Verified as of
August 2026:

- The "Omnibus" directive was published in the OJEU on **26 Feb 2026** after its adoption by the
  Council on **24 Feb 2026** (Parliament had approved the agreement on **16 Dec 2025**). It is
  **Directive (EU) 2026/470**, in force since **18 Mar 2026**.
- **Much raised thresholds**: from financial year **2027** (report in **2028**) CSRD applies to
  large listed EU companies, EU companies with **more than 1,000 employees and more than €450M of
  net turnover**, and non-EU companies with **more than €450M** of EU turnover with a subsidiary
  or branch exceeding **€200M**. Listed SMEs and financial holding companies are **exempt**.
- **Around 90% of the companies previously in scope (some 42,000) fall outside.**
- **Limited assurance**: retained; the planned move to reasonable assurance is **removed**.
  Sectoral ESRS are **dropped**. The obligation to prepare a climate transition plan compatible
  with the Paris Agreement **disappears**.
- **Transposition**: **19 Mar 2027** for the amendments to the Accounting Directive/CSRD and
  **26 Jul 2028** for the CSDDD. There is a threshold review clause.

**Engineering consequence, and it is the only one that matters here**: **it is very likely that
your organisation has fallen out of scope**. That **does not remove the need for the datum**: it
still arrives via **the value chain** (your in-scope customers will ask you for it as their scope
3), via public procurement, via financing and via the EED (§5.2), which **does not depend on
CSRD**. **Do not dismantle the instrumentation because the reporting obligation has fallen away**:
what changed is who signs the report, not who needs the number.

### 5.2 Data centres: the EED and the EU reporting scheme

This obligation **was not touched by the Omnibus** and it is the one that most directly affects
whoever operates their own infrastructure.

- Basis: **Energy Efficiency Directive (EU) 2023/1791** and **Delegated Regulation (EU)
  2024/1364** (adopted in March 2024, **in force on 6 Jun 2024**), the first phase of the Union's
  common data centre rating scheme.
- **Threshold**: every data centre with **installed IT power ≥ 500 kW** reports **annually** to
  the **European Database on Data Centres**, through each Member State's national system. Defence
  and civil protection are exempt. It covers **enterprise, *colocation* and *co-hosting***
  centres.
- **Deadlines**: the first report (year 2023) was due on **15 Sep 2024**; **from 2025 the deadline
  is 15 May** of the year following the one reported — **15 May 2026 for calendar year 2025**.
- **Content**: **24 data points** on energy and sustainability, ICT capacity and traffic. Four
  indicators are calculated and published: **PUE, WUE, ERF and REF**. **The ICT equipment report
  concerns only equipment installed after 6 Jun 2024**.
- **What is coming**: a **second delegated regulation in June 2026** is expected with the formal
  rating and labelling scheme; and **from 15 Aug 2027**, and annually, the European database will
  automatically generate an **electronic label** for the centres that have reported, valid from 15
  August to 15 August. **Verify (§8): these are expected dates.**
- **Declared real friction**: at the start of 2025 only a few Member States had implemented the
  national reporting system (Germany and Austria among them). **Check the one in your jurisdiction
  before assuming a channel exists.**

### 5.3 Ecodesign, waste and repair

- **Regulation (EU) 2019/424** — ecodesign requirements for servers and data storage products:
  minimum power supply and active state efficiency, material efficiency (disassembly of certain
  components) and operating condition class information. **It is under revision and a revised
  version is expected in 2026**; the known draft **removes exemptions** for *server appliances*,
  large servers and fully fault-tolerant servers. **Verify before writing a procurement tender**
  (§8).
- **WEEE (Directive 2012/19/EU)** — under revision. The Commission published its evaluation on
  **2 Jul 2025** with five major shortcomings; a **formal proposal is expected in Q3 2026** within
  the Circular Economy Act, with the possibility of **upgrading it from a Directive to a
  Regulation** (direct applicability, no transposition). **Gap: the final legal form is not
  decided — do not take it for granted** (§8).
- **Right to repair — Directive (EU) 2024/1799**: obligations applicable in the EU from
  **31 Jul 2026**. It affects specified product categories (spare-part availability and repair
  information) and repairability-oriented design. **Check whether your equipment falls in scope
  before invoking it.**

### 5.4 Grid intensity data: licence before integration

| Source | Granularity | Signal | Terms (verify, §8) |
|---|---|---|---|
| **Ember** | Monthly / annual, 215 countries | Average | **CC BY 4.0**, open and redistributable. Own REST API. **The only one with no practical restriction for commercial use** |
| **Electricity Maps** | **Hourly, real time**, 200+ zones | **Average** (not marginal) | Free tier: **a single zone**, **50 requests/hour**, **non-commercial use**, **no forecast**. Extended academic access with an institutional email |
| **WattTime** | Hourly | **Marginal (MOER)** | Free tier: **one region**. The absolute MOER is free only in `CAISO_NORTH`; the rest requires a subscription. Coverage extended to ~210 countries |

**Documented method warning**: it was reported against the *Carbon Aware SDK* that it documented
providing "marginal intensity" when **Electricity Maps delivers an average signal**. **Verify
which signal your provider gives you before building a decision on top of it**: the library's
label is no guarantee.

**Operational rule**: the licence of these sources is decided with
`opensource-licensing-standards`. A **non-commercial** free tier in a production service is a
licence breach, not a billing detail — **and it is exactly the kind of case §3.6 of that skill
documents**.

## 6. Operation and observability of the metric

- **A time series, not an annual report.** Carbon is instrumented like any other signal: it is
  exported to the same stack as `observability-standards`, with the same retention and the same
  allocation tags that `finops-standards` uses. **A datum that only exists in an annual PDF has
  changed no decision.**
- **Shared tagging, not duplicated.** Carbon is allocated with **exactly the same** tag scheme as
  cost. Two parallel taxonomies guarantee that neither balances.
- **Minimum dashboard, and five things are enough**: kWh per environment; *location-based* and
  *market-based* gCO2e separately; SCI per functional unit; **idle resource inventory**; average
  fleet utilisation. Everything else is decoration until somebody uses it to decide.
- **Alert on the actionable**, which in this domain means **one thing**: idle or underused
  resources appearing. Alerting on absolute gCO2e produces noise: it goes up when the business
  grows, and that is not an incident.
- **Series breaks with an owner**: provider model change (Google, Jan 2026), tool change (Kepler
  0.9→0.10), emission factor change, assumed lifetime change. **They are annotated in the series
  itself**, not in an email. A series with an undocumented break is a retroactively useless
  series.
- **Measurement must earn its place.** If a per-node energy agent has not changed a decision in
  two quarters, it is withdrawn. **Instrumentation without a decision is consumption with an
  alibi.**

## 7. Long-term sustainability and prohibitions

**Cadence**: idle resource review, **monthly** (shared with FinOps); review of emission factors
and of the grid intensity source, **annual**; review of the assumed lifetime and of the fleet
renewal plan, **annual**; verification of regulatory dates and thresholds, **half-yearly** — this
domain moved wholesale between 2025 and 2026 and will move again.

**Active deprecations to watch**: AWS's *Customer Carbon Footprint Tool* **ceases to exist on
30 Jun 2026** (migrate to the Sustainability console and its API); **Kepler 0.9.x is frozen**;
Google's model changed with the **January 2026** data. Any dashboard, *script* or IAM policy
pointing at a deprecated source is debt with a known date.

**FORBIDDEN:**

- ❌ **Claiming a reduction without a baseline and without a declared method.** It is the parent
  prohibition: all the others are particular cases of it.
- ❌ **Using offsets as a substitute for reducing**, or subtracting them from the gross figure.
  They are reported separately and afterwards.
- ❌ **Comparing carbon figures from different cloud providers** (§3.6). Boundaries, allocation
  methods, granularity and verification status are incomparable by construction.
- ❌ **Optimising code for sustainability without having switched off the idle first.** Skipping
  the order in §3.4 is the operational definition of sustainability theatre: maximum effort,
  minimum effect, maximum visibility.
- ❌ **Publishing only the *market-based* scope 2 figure.** Both or neither.
- ❌ **Presenting a system boundary change as a reduction** (migrating to the cloud, outsourcing,
  moving to *colocation*).
- ❌ **Presenting a cost saving as a carbon saving, or the other way round.** Commitments and
  reservations are the canonical counter-example: cost down, carbon unchanged.
- ❌ **Using an average grid intensity signal to justify a load shift.** That requires a marginal
  signal, and using the average gives an invalid result, not an approximate one.
- ❌ **Presenting as a measurement a figure that is a modelled allocation** (energy per container
  from RAPL, any public cloud datum, any Cloud Carbon Footprint output).
- ❌ **Citing a PUE as an indicator of your software's efficiency**, or comparing PUEs from
  different measurement categories.
- ❌ **Mixing amortised LCA figures with GHG Protocol capital goods figures** (§3.3).
- ❌ **Changing the SCI functional unit without recalculating the historical series.**
- ❌ **Renewing hardware invoking efficiency without having done the calculation** of annualised
  embodied footprint against excess consumption (§3.3).
- ❌ **Writing a figure with no source and no methodology.** There is none in this document; there
  should be none in yours either.
- ❌ **Dismantling the instrumentation because the Omnibus took you out of CSRD scope** (§5.1).
- ❌ **Integrating a grid intensity data source without verifying its licence** — several free
  tiers are non-commercial use.

## 8. Mandatory web verification

This domain combines the worst of two worlds: **regulation with moving dates** and
**low-maintenance tools**. Everything below expires.

**Always check:**

1. **SCI / ISO/IEC 21031**: the edition in force in the ISO catalogue and the version of the GSF
   specification. **Declared discrepancy** (§3.1): the GSF places the accreditation in **April
   2024**, other sources give **March 2024** as publication and **May 2024** as adoption.
   **Confirm with ISO before citing a date in a formal document.**
2. **Revision of the GHG Protocol Scope 2 Guidance**: whether the second consultation has closed,
   whether there is a final text and what happened to the definition of the exempt "small
   organisation". **Declared discrepancy**: final publication planned for **2027** according to
   the GHG Protocol, **2027-2028** according to secondary sources.
3. **CSRD / Omnibus**: confirm thresholds, dates and transposition of **Directive (EU) 2026/470**
   in its OJEU text, **not in consultancy summaries** — almost all 2024-2025 CSRD material is
   obsolete and still circulating.
4. **EED and data centres**: whether the **second delegated regulation** (rating and labelling,
   expected Jun 2026) has been published; whether your jurisdiction's national reporting system
   exists; and **whether the date of the first electronic label is still 15 Aug 2027**.
5. **Revised Ecodesign (EU) 2019/424**, and the **final legal form of the WEEE revision**
   (Directive or Regulation? proposal expected Q3 2026). **Open gap: not decided.**
6. **ISO/IEC 30134-2**: which edition is in force (there is **2016** and **2026**) and which one
   your regulatory obligation references — they may not be the same.
7. **Tools**: status and licence of **Cloud Carbon Footprint** (Apache-2.0, low release cadence,
   coefficients repository archived — **verify whether it is still alive**), **Kepler** (CNCF
   sandbox, Apache-2.0, ≥0.10.0) and **Scaphandre** (Apache-2.0). And the deprecation date of
   AWS's **CCFT (30 Jun 2026)**: if it has already passed, the migration is not optional.
8. **Grid intensity sources**: exact limits and **licence** of the free tiers of Electricity Maps
   and WattTime, which **have already been restricted once** (from multi-zone to a single zone),
   and whether Ember's API covers the granularity you need.
9. **Each cloud provider's methodology**: what changed since your last baseline and whether the
   customer data is **third-party verified** — as of August 2026 Google's **was not**.

**Declared gaps — do not fill them without verifying:**

- **No carbon intensity figure per region is fixed**: they change by hour and by year, and a
  figure written here would be false within weeks. They are read from the source at the moment of
  deciding.
- **No single embodied footprint percentage is fixed**: only the published range with its study,
  its sample and its method (§3.3). **Any "servers are 20/80" without declaring lifetime,
  configuration and grid intensity is rejected.**
- **No expected saving from *carbon-aware scheduling* is fixed**: the magnitude depends entirely
  on the region, the window and the flexibility of the load, and no study with a replicable
  methodology has been verified for this text.
- **No price or cost is fixed** for tools, data subscriptions or assurance services: without a
  verified budget no figure gets written.
- **Size threshold at which code optimisation pays off** (§3.4, lever 6): there is no source with
  a replicable methodology. **It is calculated in your case; it is not inherited.**

And the rule that governs all of the above: **a figure with no source and no methodology does not
get written.** If on verifying the methodology does not appear, **the gap is declared** — it is
not filled with the most widely circulated figure.

If the web contradicts this document, **the web wins** — flag the discrepancy.
