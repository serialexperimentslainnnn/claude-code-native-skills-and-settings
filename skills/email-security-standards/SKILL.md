---
name: email-security-standards
description: Email as an attack surface and the DNS records that defend it. Use when publishing or auditing SPF (v=spf1, the 10 DNS-lookup limit, +all, chained include, ~all vs -all), DKIM selectors, key length and rotation (selector._domainkey, rsa-sha256, ed25519-sha256), DMARC (_dmarc TXT, p=none/quarantine/reject, sp, np, t, adkim/aspf alignment, rua/ruf, the DMARCbis tree walk and the removal of pct), aggregate and failure report parsing, ARC and mailing-list or forwarding breakage, Authentication-Results headers, MTA-STS (_mta-sts TXT and .well-known/mta-sts.txt), TLS-RPT (_smtp._tls), DANE TLSA for SMTP with DNSSEC, BIMI (default._bimi, VMC/CMC, Mark Verifying Authority), third-party sending providers and the inventory of who sends on your behalf, Gmail/Yahoo/Outlook bulk-sender requirements and one-click unsubscribe (List-Unsubscribe-Post), inbound filtering, attachment and URL isolation, business email compromise and out-of-band payment verification, phishing simulations, or the reported-phish mailbox.
---

# Email security standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **defending the email channel**: sender authentication (SPF, DKIM, DMARC) and its
full rollout up to a reject policy; the inventory of **who sends on your behalf**;
transport security (MTA-STS, TLS-RPT, DANE); brand indicators (BIMI); subdomain and
sending-provider policy; interpretation of aggregate and failure reports;
survival of email across lists and forwarding (ARC); inbound defence (filtering, isolation
of attachments and links, quarantine, external-origin *banners*); business email
compromise fraud (BEC) and its process control; training and simulations; and the reporting
mailbox as a signal source.

Triggers: `v=spf1`, `_dmarc`, `v=DMARC1`, `p=none`/`p=quarantine`/`p=reject`, `sp=`, `np=`,
`t=y`, `rua=`/`ruf=`, `adkim`/`aspf`, `pct=`, `selector._domainkey`, `v=DKIM1; k=rsa; p=`,
`v=ARC1`, `Authentication-Results:`, `ARC-Seal`, `_mta-sts`, `.well-known/mta-sts.txt`,
`_smtp._tls`, `v=TLSRPTv1`, `_25._tcp` TLSA, `default._bimi`, `v=BIMI1`, VMC/CMC,
`List-Unsubscribe-Post: List-Unsubscribe=One-Click`, `550 5.7.26`, `dmarcian`/`parsedmarc`,
`opendkim`/`opendmarc`, `swaks`, "aggregate report", "alignment", "domain spoofing",
"phishing", "BEC", "CEO fraud", "bank account change", "phishing simulation".

**Guiding principle**: email is the most used inbound channel against the people of an
organisation, and **it is the only one whose baseline defence depends on three DNS records that almost
nobody reviews**. Here the criteria are concrete and verifiable: either the record is published and
aligned, or it is not — you check it in 30 seconds with `dig`. Corollary: **DMARC is not a
DNS project, it is an inventory project**. 90 % of the real work of getting to
`p=reject` is discovering who sends on your behalf (billing, HR, the CRM, the print shop,
that plugin) and **the part that fails is not the technical one, it is that nobody had that list**.

**Not applicable**: the **detection rule and its analytic content** (including turning a
reported email into a detection) belong to `detection-engineering-standards`, the **confirmed
incident, the containment that preserves evidence and mailbox forensics** belong to
`incident-response-forensics-standards`, and the **incident process** — severity, command,
communication, postmortem — belongs to `incident-management-standards`; here it ends the moment
there is confirmed compromise. **DNS zone operation** (delegation, DNSSEC, TTL,
registrar management) belongs to `dns-standards` — here we set **what the record must contain and
why** —, **identity and mailbox access** (MFA, conditional access, OAuth tokens,
session revocation, forwarding rules as an IoC of a compromised account) belong to
`identity-access-management-standards`, **cryptography and PKI** (key size, TLS,
certificate chains, S/MIME) to `cryptography-pki-standards`, **CVE triage** of the
mail product to `vulnerability-management-standards`, **the SOC's queue, shift and metrics**
to `soc-operations-standards`, and **the indicator, its expiry and intelligence
about brand impersonation** to `threat-intelligence-standards`.
Also: `mail-servers-standards` (**the server that implements these controls**: Postfix,
Exim, Dovecot, Rspamd, queues, storage and outbound IP reputation — **here the
policy and the content of the record, there the daemon that applies them**),
`offensive-security-standards` (**any simulated campaign requires written scope and
authorisation**; this skill is **defensive**), `privacy-engineering-standards`
(the mailbox and its headers are personal data: legal basis, minimisation and retention of the
simulations and of archiving), `grc-compliance-standards` (regulatory notification duty
and audit evidence), `networking-standards` and `firewall-policy-standards`
(outbound SMTP, egress and IP reputation), `observability-standards` (telemetry
platform), `itsm-itil-standards` (the ticket and the SLA), `macos-fleet-standards` and
`endpoint-security-standards` (the mail client and what happens
after the click), `ai-governance-standards` and `mlsecops-standards` (if the filter decides with a
model: governance, bias and evaluation).

## 2. Default decisions

> Verify on the web the status of every RFC and draft before pinning it in a project (§8).

| Control | Verified standard | Default decision |
|---|---|---|
| SPF | **RFC 7208**, Proposed Standard (obsoletes RFC 4408; updated by 7372, 8553, 8616) | A single `v=spf1` record, ending in `-all`. `~all` only during rollout |
| DKIM | **RFC 6376**, Internet Standard (updated by 8301, 8463, 8553, 8616) | Always sign. `rsa-sha256` with **≥2048 bits**; `ed25519-sha256` (RFC 8463) as a dual signature, never alone |
| DMARC | **RFC 9989** (core) + **RFC 9990** (aggregate report) + **RFC 9991** (failure report), Proposed Standard, May 2026 — **they obsolete RFC 7489 and RFC 9091** | Destination `p=reject` with `rua` active. Explicit `sp` and `np` |
| ARC | **RFC 8617**, **Experimental** | Seal at your own intermediaries (lists, gateways); do **not** trust someone else's ARC without a trust list |
| Auth-Results | **RFC 8601**, Proposed Standard (obsoletes 7601) | The edge MTA writes the header and **deletes the forged ones** arriving from outside |
| MTA-STS | **RFC 8461**, Proposed Standard | `mode: enforce`, high `max_age` (maximum allowed 31,557,600 s). `testing` only as a prior step with TLS-RPT active |
| TLS-RPT | **RFC 8460**, Proposed Standard | Always, and **before** MTA-STS/DANE: it is the only way to see what you break |
| DANE SMTP | **RFC 7672** (TLSA: RFC 6698, upd. by 7218, 7671, 8749), Proposed Standard | Only if **your zone and the MXs' zones are signed with DNSSEC**; otherwise, MTA-STS |
| BIMI | **NOT an RFC**: `draft-brand-indicators-for-message-identification-14` (May 2026), *Individual Submission*, IESG state "I-D Exists" | Optional and **last**. Requires DMARC at `quarantine`/`reject`, an SVG logo and a **paid VMC/CMC** issued by an MVA |
| List unsubscribe | **RFC 8058**, Proposed Standard | `List-Unsubscribe` + `List-Unsubscribe-Post` in every commercial or subscribed email |

**What changed with DMARCbis and has to be rewritten** (RFC 9989, verified in the IANA registry
of the document itself): `pct`, `rf` and `ri` move to **historic**; `np` is added (policy for
**non-existent** subdomains), `psd` (the domain is a public suffix) and **`t` (test
mode)**. The public suffix list (PSL) is replaced by the **DNS Tree Walk**: up to
**8 queries** ascending the tree (if the name has ≥8 labels, it jumps to the rightmost 7).
And the fact that corrects the usual belief: **DMARC is no longer Informational of the
independent stream — it is now Proposed Standard of the IETF stream.**

## 3. Structure and conventions

```dns
; --- SPF: only one, ≤10 terms with a DNS lookup, ending in -all
example.com.               IN TXT "v=spf1 include:_spf.proveedor.example -all"
; --- DKIM: one selector per sender and per rotation; k=rsa p=<key ≥2048b>
2026q3._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; t=s; p=MIIBIjAN..."
; --- DMARC: final destination; np=reject is published from day 1
_dmarc.example.com.        IN TXT "v=DMARC1; p=reject; sp=reject; np=reject; adkim=s; aspf=s; rua=mailto:dmarc@example.com"
; --- Authorisation of the external report destination (RFC 9990 §4)
example.com._report._dmarc.proveedor.example. IN TXT "v=DMARC1"
; --- Transport
_mta-sts.example.com.      IN TXT "v=STSv1; id=20260805T120000Z;"   ; policy at https://mta-sts.example.com/.well-known/mta-sts.txt
_smtp._tls.example.com.    IN TXT "v=TLSRPTv1; rua=mailto:tlsrpt@example.com"
_25._tcp.mx1.example.com.  IN TLSA 3 1 1 <hash>                      ; only with DNSSEC
; --- Subdomain that does NOT send: empty SPF and reject DMARC
_dmarc.static.example.com. IN TXT "v=DMARC1; p=reject;"
static.example.com.        IN TXT "v=spf1 -all"
```

- **One subdomain per sending use case** (`mkt.`, `invoices.`, `notif.`), each with its own
  SPF and its own DKIM. It isolates a provider's failure and allows an `sp` different from the root domain's.
- **Every domain and subdomain that does not send email publishes `v=spf1 -all` and a reject DMARC**,
  including *parked* domains, old campaign ones and defensive registrations.
- **Strict alignment (`adkim=s; aspf=s`) is the goal**, not the starting point: the
  relaxed one accepts the organisational subdomain and it is what allows a compromised
  provider to sign as you. Tighten **after** closing the inventory.
- **`np=reject` from day one**: no legitimate email comes from a subdomain that does not
  exist. Zero cost, it covers impersonation through an invented subdomain.
- **A selector per sender and per rotation** (`2026q3._domainkey`), never a shared selector:
  rotating without a new selector implies a window in which in-transit signatures break.

## 4. Verification and gates

- **The inventory is the deliverable, not the DNS record.** It is built with `rua` at `p=none`
  until **every sender in the aggregate report is identified and classified** (legitimate
  authenticated / legitimate unauthenticated / unknown / impersonator). Without that table closed,
  moving up to `quarantine` cuts real mail.
- **The ramp with DMARCbis is no longer by percentage** (`pct` is historic): you move up by publishing
  `p=quarantine` with **`t=y`** — the receiver does not apply the policy but does report — and then
  `t=n`. Careful: `t` **has no effect** when the policy is `none`.
- **Automated gates** (they break the build or open a ticket, in order of cost): (1) `dig` +
  an SPF/DKIM/DMARC/MTA-STS syntax validator over **all** the domains in the inventory,
  daily; (2) **SPF DNS query counter** — the standard mandates `permerror` on exceeding
  **10 querying terms** (`include`, `a`, `mx`, `ptr`, `exists`, `redirect`), and
  recommends a maximum of **2 *void lookups***, so the alarm threshold is 8, not 10;
  (3) DKIM key length and algorithm; (4) expiry of the MTA-STS policy certificate
  and of the VMC; (5) a *diff* of the DNS record against the expected one (drift detection).
- **Parse the aggregate reports with a tool, not by eye**: they are compressed XML, one
  per receiver per day (RFC 9990: feedback **daily or more frequently**). Without an aggregator there is
  no rollout.
- **Test the failure path, not just the happy one**: send from an unauthorised source and
  check that the receiver rejects it; deliberately break the MTA-STS policy in `testing` and
  check that the TLS-RPT report arrives.
- **Audit the `ruf`** before publishing it: the failure report carries message content and
  is **personal data**; many receivers do not send it and publishing it without a legal basis and without
  minimisation is a privacy problem, not a security improvement.

## 5. Inbound defence, BEC and people

- **Modern phishing rarely carries a malicious attachment.** It carries a link to a credential
  harvesting page or to an OAuth consent flow, or simply **text**
  asking for an action. A programme that only measures blocked attachments is measuring the
  easy part. The controls that do matter: URL rewriting and **detonation at click
  time** (not only at delivery), attachment isolation, blocking by the file's **real
  type** and not by extension, and a **visible external-origin header** in the client.
- **Lookalike impersonation**: DMARC protects **your** domain, it does not protect against `exarnple.com`.
  You need lookalike-domain monitoring and a quarantine rule for a *display name* that
  imitates an internal executive when the `From` is external.
- **BEC: no technical control stops it on its own.** The fraud carries no malware and no link, and
  frequently comes from a **legitimate and compromised** mailbox, so it passes SPF, DKIM and DMARC. The
  only control that works is a process one: **mandatory out-of-band verification** —
  a call to a number from the supplier master, never to the one in the email — for every onboarding or
  **bank account change** and for every payment above a threshold, with **dual
  approval** and no exception for urgency or hierarchy. The exception "the CEO is asking and it is
  urgent" **is** the attack.
- **Magnitude, with a primary source and its declared bias**: the FBI IC3's *Internet Crime Report 2025*
  records **24,768 BEC complaints and 3,046,598,558 USD** in reported
  losses, second by amount after investment fraud, against **32,320,105 USD** in
  *ransomware*. Methodology and limits, verbatim from the report: they are **voluntary
  complaints**, mostly from the US, with possible duplicates, and the *ransomware*
  figure **"does not include estimates from lost business, time, wages, files, or equipment"**
  — which is why they cannot be compared as if they were the same type of data. What the data does
  support: **BEC moves money by direct transfer** (the report itself puts
  wire/ACH transfer at 86 % as the BEC route) and that is why its direct loss is
  disproportionate to its case volume.
- **Training and simulations**: a simulation measures **the reporting rate**, which is the actionable
  metric; the click rate only measures which lure you used. Rules: never lures involving salary,
  dismissal, bonus or health; **zero individual consequences** for falling for it; aggregate results,
  never a named *ranking*; and the declared objective is **reducing the time to the first
  report**. A programme that punishes produces the worst possible outcome: people who fall for it and
  do not tell anyone.
- **The reporting mailbox is a first-order detection source** — a "report" button in the
  client, with acknowledgement and a response — because a user who reports detects campaigns the
  filter let through. Here the channel and the response commitment are defined; **the rule
  written from that signal belongs to `detection-engineering-standards`** and the retroactive search
  and purge of the same message across all mailboxes is incident containment.

## 6. Outbound, third parties and operability

- **A live inventory of authorised senders**, with a business owner, assigned subdomain,
  authentication method and review date. **Onboarding a provider = an entry in the inventory
  + a subdomain + its own DKIM**; if it does not fit in the SPF, it fits in a delegated subdomain.
- **Chained SPF breaks by itself**: every SaaS `include:` drags in its own and the
  budget of 10 lookups runs out without warning. Faced with the limit: flattening **no** (it breaks
  when the provider changes IPs), delegating by subdomain **yes**, and prioritising **DKIM**, which
  does not consume the DNS budget and survives forwarding.
- **Requirements of the large mailbox providers** (verified in Google's source): since
  **1-Feb-2024**, every sender to Gmail needs **SPF or DKIM**, valid forward and reverse DNS (PTR),
  a **TLS** connection, RFC 5322 format and a **spam rate <0.3 %** in Postmaster Tools;
  anyone sending **>5000 messages/day** needs **SPF and DKIM**, **DMARC** (the policy may be
  `p=none`), **alignment** of the `From` with SPF or DKIM and **one-click unsubscribe** plus a visible link.
  Additional Google guidance: stay **below 0.10 %** and never reach 0.30 %.
- **Lists and forwarding always break SPF, and DKIM when the intermediary modifies the message**
  (a prefixed subject, an added footer). Mitigation in order: do not modify the body, rewrite
  the `From` to a list domain (`From` rewriting), and **ARC** so the final receiver
  can evaluate the previous authentication — remembering that ARC is **Experimental** and only helps
  if the receiver trusts that sealer.
- **Operability**: alert on **a drop in aggregate report volume** (it indicates a broken record
  or a badly published zone), on the appearance of an unknown sender with volume, on
  a change to the MTA-STS policy and on TLS validation failures in TLS-RPT. Rehearse DKIM key
  rotation before you need it.

## 7. Long-term sustainability and prohibitions

Quarterly review of the sender inventory and of the DNS record; DKIM key rotation
at least annually with a new selector; review of the status of the drafts (BIMI, DKIM2) every
cycle. Every record change versioned in the zone repository.

- ❌ **Leaving DMARC at `p=none` indefinitely.** `p=none` protects against nothing: it is only the
  measuring instrument. Without an agreed exit date, the project is dead and published.
- ❌ **`+all` in SPF** — it authorises the whole internet to send on your behalf. Equally vetoed are
  `?all` in production and a second `v=spf1` record on the same name (`permerror`).
- ❌ Publishing **DKIM with a key <2048 bits**. RFC 8301 requires ≥1024 and **forbids**
  verifiers from treating a signature with less as valid; 1024 is the legal minimum, not the criteria.
- ❌ **`rsa-sha1`**: RFC 8301 explicitly forbids it for signing and for verifying.
- ❌ **Adding a sending provider without inventorying it.** It is the number one cause of a
  DMARC rollout cutting legitimate mail months later.
- ❌ **Flattening the SPF** by expanding a third party's IPs to dodge the limit of 10.
  It breaks silently the day the provider changes range.
- ❌ Measuring training by **click rate** and nothing else, publishing named *rankings* or
  applying disciplinary consequences for falling for a simulation.
- ❌ Using **salary, dismissal, bonus, health or family emergency** lures in a simulation.
- ❌ Authorising a **payment or bank account change** with verification through the same email
  thread, or with the phone number that appears in that email.
- ❌ Publishing `ruf` with an external destination **without a legal basis, without minimisation and without
  `_report._dmarc` authorisation** from the receiving domain.
- ❌ **DANE without DNSSEC** in your zone and in the MXs': without signing, validation adds nothing.
- ❌ Putting **MTA-STS in `enforce` without having gone through `testing` with TLS-RPT active**, or
  publishing a `max_age` of hours "just in case" — it nullifies the protection against the
  downgrade attack.
- ❌ Treating **BIMI as a security control**: it is branding. And buying a VMC before being at
  `p=reject` is money paid up front for work not done.
- ❌ Trusting `Authentication-Results` headers or **externally originated ARC** seals without an explicit
  list of trusted intermediaries: they are text anybody can write.
- ❌ Launching a **simulated phishing campaign without written scope and authorisation**
  (see `offensive-security-standards`) or without notifying the SOC (*deconfliction*).

## 8. Mandatory web verification

1. **Every RFC, one by one, at `rfc-editor.org`**, checking `obsoleted-by` and not just the
   number: SPF **7208**, DKIM **6376** (+8301, +8463), DMARC **9989/9990/9991** (which
   **obsolete 7489 and 9091** — almost all the literature still cites 7489), ARC **8617**,
   MTA-STS **8461**, TLS-RPT **8460**, DANE-SMTP **7672** (TLSA **6698**), Auth-Results
   **8601**, one-click unsubscribe **8058**.
2. **BIMI status**: it is still an individual *Internet-Draft*, not an RFC. Check the revision and
   its expiry at `datatracker.ietf.org` before citing it as a standard.
3. **Declared discrepancy**: the BIMI draft rev. 14 (May 2026) normatively references
   **RFC 7489 and the `pct` tag**, which **RFC 9989 (May 2026) declares historic**. Until it is
   updated, the condition "quarantine with `pct=100`" has no literal equivalent in DMARCbis;
   interpret it as "quarantine without test mode (`t=n`)" and **confirm with the receiver**.
4. **DKIM2 work at the IETF** (`dkim` working group, `draft-ietf-dkim-dkim2-*` drafts): it is
   work in progress, **there is no RFC**. Do not design against it yet.
5. **Requirements of the large mailbox providers**, which change without notice: Google (verified),
   Yahoo and Microsoft. **Declared gap**: it has not been possible to confirm against an accessible
   primary source the threshold and the exact enforcement date of Microsoft's requirements for
   high-volume senders to consumer domains (Microsoft's page does not serve content
   without JavaScript). **Verify before citing it**; do not take a blog's figure on faith.
6. **Figures discarded for lack of public methodology**: "90 % of cyberattacks
   start with email", "95 % of breaches are human error", the average cost of a
   breach and the detection rates of any secure email vendor. If the source is
   a provider selling the control the figure justifies and it publishes neither method nor sample,
   **it is not used**. Sources with a declared methodology: IC3/FBI (voluntary complaints, US
   bias), ENISA, CISA, and the mailbox operators' reports on their own traffic.
7. The status of the validators and aggregators being recommended (licence and maintenance) before
   pinning a tool.

If the web contradicts this document, **the web wins** — flag the discrepancy.
