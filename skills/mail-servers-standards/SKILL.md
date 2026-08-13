---
name: mail-servers-standards
description: Running your own mail server — the decision first, the daemons second, because deliverability reputation decides the outcome. Use when working with Postfix (main.cf, master.cf, postconf, postqueue, postfix check, mynetworks, smtpd_relay_restrictions, smtpd_recipient_restrictions, transport and virtual maps, milter_default_action), Exim (exim.conf, exim4.conf.template, exim -bt, routers/transports/ACLs), Dovecot (dovecot.conf, conf.d 10-mail.conf and 10-auth.conf, dovecot_config_version, doveadm, dsync, Maildir, mdbox and sdbox, mail_location, quota plugin, Sieve and managesieve), Rspamd (rspamd.conf, local.d, worker-proxy, greylisting, milter headers) or SpamAssassin, an integrated suite (mailcow-dockerized, Mailu, iRedMail with iRedAdmin-Pro, Stalwart), SMTP and its extensions (RFC 5321, STARTTLS, SMTP AUTH, submission on 587 and implicit TLS on 465, port 25 blocked by the cloud provider), IMAP (RFC 9051) versus POP3 retirement, JMAP, mailbox storage format, quotas and mailbox growth, an open relay or a rate limit, a compromised account turning the server into a spam source, backscatter and a secondary MX that cannot validate recipients, IP and PTR reputation, bulk sender requirements from Gmail, Yahoo and Outlook, choosing between a managed outbound relay and a full self-hosted server, or migrating mailboxes between platforms with imapsync.
---

# Mail server standards — the decision weighs more than the configuration

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to **deciding, building and operating** your own mail: the prior choice between a managed
relay and a full server, MTA, MDA/store, filtering, protocols and ports, TLS, storage and quotas,
high availability, outbound reputation and mailbox migration.

Triggers: `main.cf`, `master.cf`, `postconf`, `postqueue`/`mailq`, `exim.conf`, `dovecot.conf`,
`doveadm`, `dsync`, `rspamd.conf`, `local.d`, `sieve`, `imapsync`, `mailcow`, `Mailu`, `iRedMail`,
`Stalwart`, "open relay", "port 25 blocked", "587", "465", "Maildir", "mdbox", "mailbox
quota", "deferred queue", "backscatter", "secondary MX", "listed on a blocklist".

**The premise that overrides everything else**: **running your own mail in 2026 almost never ends
well, and the reason is not technical but deliverability reputation.** Postfix and Dovecot can be
configured in an afternoon; what cannot be solved in an afternoon is getting your mail into someone
else's inbox. The three parts of the wall, verified: (1) **the cloud provider blocks your outbound
port 25** —Azure blocks it except on Enterprise Agreement/MCA-E subscriptions and recommends an
authenticated relay on 587; Google Cloud blocks it "due to the risk of abuse" and its Workspace
relay only accepts 465 or 587—, so your IP range is born suspicious; (2) **the large receivers set
hard requirements for anyone sending volume**: since **1 Feb 2024** Gmail requires anyone sending
more than **5,000 messages/day** to have DMARC, valid forward and reverse DNS (PTR), TLS in
transport, a spam rate **below 0.30 %** and **one-click unsubscribe** (RFC 8058) in marketing mail
—Yahoo aligned on almost identical requirements and the one-click deadline was **1 Jun 2024**—;
Microsoft announced theirs on **2 Apr 2025** and started enforcing on **5 May 2025** on
Outlook.com/Hotmail/Live for domains sending more than 5,000 messages/day, initially diverting to
Junk; (3) **building reputation takes months and is destroyed in hours**. With that on the table,
the right question is not "which MTA do I use?" but "**why not a managed relay?**".

**Not applicable**: the catalogue split: **`email-security-standards` owns SPF, DKIM,
DMARC, MTA-STS, TLS-RPT, BIMI, antiphishing filtering, BEC and mail policy**; here only
**the server that implements them** (where the key lives, what it signs and what it verifies), and **not
a single record is duplicated**; **`dns-standards` owns the records** —MX, PTR, TXT and their operation—,
`cryptography-pki-standards` the algorithm choice and the certificate, `identity-access-management-standards`
the account, MFA and session revocation, and `firewall-policy-standards` with `networking-standards`
filtering and egress. Towards operation: `backup-recovery-standards` owns mailbox backup and
restore, `bcdr-standards` the RTO/RPO, `ha-clustering-standards` the cluster,
`observability-standards` metrics and dashboards, `incident-management-standards` and
`incident-response-forensics-standards` the incident and the forensics of a compromised mailbox,
`vulnerability-management-standards` the CVE, `privacy-engineering-standards` personal data in
logs and mailboxes, and `grc-compliance-standards` legal retention. The system underneath belongs to
`linux-administration-standards`, `rhel-fedora-standards` and `linux-hardening-standards`;
`kubernetes-standards` if it runs in a container, `iac-standards`/`cicd-standards` how the
configuration gets there, and `onprem-standards` is the umbrella (`homelab-standards` for the lab). Its
sisters in this batch: **`web-app-servers-standards` owns webmail and the panels** (SOGo, Roundcube,
iRedAdmin are web applications, not mail) and `file-servers-standards` is another service.

## 2. The prior decision, and only then the components

| Situation | Decision |
|---|---|
| General corporate mail, no sovereignty requirement | **Managed mailboxes** (Google Workspace, Microsoft 365, a European provider). This is not surrender: it is not spending the budget on reputation |
| Application sending notifications, invoices or alerts | **Managed outbound SMTP relay** (authenticated on 587). Your application does not need its own MTA, it needs to deliver |
| Legal or contractual requirement that the data must not leave, or volume that makes the relay unaffordable | **Full self-hosted server**, with an explicit budget for operation, reputation monitoring and on-call |
| Own mailboxes but unreliable delivery | **Hybrid**: own reception and store, **outbound via a managed relay**. The most underrated option in this domain |
| Lab, learning, a domain with no traffic | Self-hosted server, accepting that delivery to the big receivers will be erratic |

**Honest criteria**: data sovereignty, cost at high volume and a legal requirement justify the
self-hosted server. "Saving money", "control" and "I do not trust the cloud" do **not** on their own justify the
real cost: on-call, patching, blocklist monitoring and responding to a compromised account.

## 3. Components, versions and licences

> Verify the latest version on the web before pinning it in a real project (§8).

| Component | Recommended | Verified data |
|---|---|---|
| MTA | **Postfix** | `3.11.5` (6 Jul 2026); legacy branches maintained (3.10.x, 3.9.x, 3.8.x) and occasional patches even for 3.5–3.7. **Dual licence**: `LICENSE` literally says *"dual-licensed under both the Eclipse Public License version 2.0 and the IBM Public License version 1.0"* — **it is neither GPL nor BSD** |
| Alternative MTA | **Exim** only if you already know it well or your distro ships it (Debian) | `4.99.5`, security release. **`LICENCE`** (British spelling, not `LICENSE`) is GPL-2; the tarball's `NOTICE` declares `SPDX-License-Identifier: GPL-2.0-or-later` with an explicit exception for linking with OpenSSL. **The GitHub repository is ARCHIVED** (last push Dec 2025): the project lives at `exim.org` and on its own Forgejo, and numbers its advisories as **GCVE**, not CVE. A 404 on GitHub is not abandonment |
| MDA / store | **Dovecot CE 2.4.x** (latest published tarball: `2.4.4`) | `2.4.0` was the first major in ~7 years. **Official lifecycle, verbatim**: *"All Dovecot versions before 2.3 are now fully EOL"*, for 2.3 *"we will provide critical security bug fixes"* and *"Dovecot CE 2.4.x is the current main release"*. **It is not a hot upgrade**: the 2.3 configuration is not valid, `dovecot_config_version` becomes mandatory and there is an official converter at `dovecot.org/upgrader/`. **Mixed licence**: MIT in `src/lib`, `src/auth` and `src/lib-sql`; **LGPL-2.1 for the rest**. The commercial version **OX Dovecot Pro is numbered 3.x** and has its own end-of-life policy: do not compare numbers |
| Antispam filtering | **Rspamd** | `4.1.4` (29 Jul 2026), high tempo. `LICENSE.md` in raw: **Apache-2.0** |
| Alternative filtering | **SpamAssassin** only for legacy integration | Apache-2.0, active repository but **latest release `4.0.2` of 27 Aug 2025**: slow cadence compared with Rspamd |
| Integrated suite | **mailcow-dockerized** if you want a ready-made stack | **GPL-3.0** (`LICENSE` in raw); date-based versioning (`2026-07a`); commercial model = optional paid **"Stay Awesome License"** (support/backing), the product is not cut down |
| Integrated suite | **Mailu** for a minimal deployment | **MIT** (`LICENSE.md` in raw); the stable line is still called **`2024.06.x`** and is patched (`2024.06.57`, 26 Jul 2026): active, but **the branch name does not indicate the patch date** |
| Integrated suite | **iRedMail** for an install on top of the OS | **GPLv3** for the installer; commercial model = **proprietary iRedAdmin-Pro** with an annual licence (SQL and LDAP editions) **plus** a separate upgrade contract — the paid panel **does not include server support** |
| Modern all-in-one server | **Stalwart** only with judgement: **still on `0.x`** (`v0.16.16`, 2 Aug 2026) | **Dual licence**: `LICENSES/AGPL-3.0-only.txt` and `LICENSES/LicenseRef-SEL.txt`; SELv2 is proprietary and defines *Subscription* as *"paid access to the Software… billed on a monthly or annual basis"*. **AGPL + paid Enterprise edition**: verify which feature sits on which side before depending on it |
| Mailbox migration | **imapsync** (`imapsync-2.314`) | **"NO LIMIT PUBLIC LICENSE"**, its own text: *"0 No limits to do anything with this work and this license. 1 GOTO 0"*. **It is not GPL**; the author sells binaries and support |

**Separation of responsibilities**: MTA (receives, queues, delivers), MDA/store (local delivery,
IMAP, quota, Sieve), filter (milter/proxy before accepting) and authentication (identity base).
Keep them separate even if they run on the same machine: **the filter never decides final delivery and
the store never talks to the outside**.

## 4. Protocols, ports and TLS

**RFCs verified one by one against `rfc-editor.org`** (and several common assumptions are
false):

- **SMTP: RFC 5321** — status **DRAFT STANDARD**, Oct 2008, **not obsolete**, updated by
  RFC 7504. Message format: **RFC 5322** (Draft Standard, updated by RFC 6854).
- **STARTTLS in SMTP: RFC 3207** (Proposed Standard), updated by RFC 7817 (verification of
  TLS server identity in mail protocols).
- **Submission: RFC 6409 is an INTERNET STANDARD** —not "just Proposed"—, updated by **RFC 8314**
  (*"Cleartext Considered Obsolete"*), itself updated by **RFC 8997**, which **deprecates TLS 1.1**
  for submission and access.
- **IMAP4rev2: RFC 9051** (Proposed Standard, Aug 2021) **obsoletes RFC 3501**.
- **POP3: RFC 1939 is an INTERNET STANDARD and is NOT obsolete.** Retiring it is a **product
  decision, not an IETF one**: do it because it has no shared state across devices, because
  "download and delete" makes the client the sole holder of the mail and ruins backup, and because
  its installed base is the one still most anchored to old authentication. **Turn it off by default and
  enable it by documented exception.**
- **JMAP: RFC 8620** (core, Jul 2019, updated by RFC 9404 and RFC 9670) and **RFC 8621** (mail,
  Aug 2019). Actual status: implemented by Fastmail, Cyrus, Stalwart and Apache James; **Dovecot does not
  implement it**; the mainstream client is only starting now. **Criteria: JMAP does not replace IMAP in a
  2026 infrastructure decision**; watch it, do not bet the design on it.

**Ports**: 25 only between MTAs (never for clients and **never with AUTH in the clear**); **587**
submission with mandatory STARTTLS and **465** submission with implicit TLS —RFC 8314 pushes towards
implicit—; 143/993 IMAP; 110/995 POP3 if it is still alive. **TLS mandatory everywhere**: on submission and
access it is not negotiable; between MTAs it is opportunistic by SMTP design, and **what hardens it is MTA-STS
or DANE, which belong to `email-security-standards`**. Verify that your server **validates** the certificate
when the policy requires it, not just that it encrypts.

## 5. Stack security

- **Open relay**: the classic failure, and today it is hours until the blocklist. Restrict relaying by
  explicit rule, keep `mynetworks` at the real minimum, **require authentication over TLS** for everything
  that goes out, and **test it from outside** after every change.
- **Signing and verification**: the DKIM private key is a server secret (permissions, rotation,
  outside the repository); the server **does not sign mail it has not authenticated**. **The policy —what
  to publish, what alignment to require, how to read the reports— belongs to `email-security-standards`.**
- **Rate limits per account and per IP**: messages/hour, recipients per message, maximum size and
  concurrent connections. Without them there is no defence against the next point.
- **The compromised account that turns your server into a spam source** is the typical incident, not
  the hypothetical one: it is detected by deviation in volume and recipients, not by a complaint. Decide
  in advance the automatic cut-off, credential rotation, **queue purging** and
  the notification; and treat automatic forwarding to an external mailbox as a signal (IAM owns it).
- **Backscatter**: reject the invalid recipient **inside the SMTP conversation** (5xx on
  `RCPT TO`). Accepting and then bouncing turns you into a spam source towards forged addresses
  and ends in a blocklist.
- **Authentication**: SASL against the identity base, never plaintext password files; no basic
  authentication over an unencrypted channel. Lockout on failed attempts and logging of the origin.
- **Surface**: webmail and the panel are web applications (`web-app-servers-standards` +
  `appsec-standards`); the antivirus and the filter run under their own user; **the MTA does not execute
  content**, and everything that decompresses attachments is bounded in time, memory and depth.
- **Encryption at rest for the store and encrypted backup**: a mailbox is the organisation's largest
  concentration of personal data, and the backup replicates all of it.

## 6. Storage, availability and operation

- **Format**: **Maildir** (one file per message) is robust and debuggable, but punishes the
  filesystem with millions of small files and makes backup and traversal painfully slow. **mdbox**
  groups messages and performs far better, at the cost of a Dovecot-specific format and maintenance
  (`doveadm purge`). **mbox: forbidden** with multi-access. Choose by backup profile, not by taste.
- **Quotas mandatory, no exceptions**: the mailbox grows until it fills the disk, and **a full disk
  on a mail server is an immediate service outage**. Per-mailbox quota, alert at 80 % of the
  volume and a written archiving policy.
- **High availability, with the right nuance**: a downed server **does not lose mail on its own**
  —the sender queues and retries for days—. Mail is lost when you answer 5xx because of a
  half-finished configuration, when you accept and cannot deliver locally, or when the **secondary
  MX accepts for recipients it cannot validate** and then bounces. Rule: **a backup MX that does not
  share the table of valid recipients is worse than having none.** And
  **Dovecot 2.4 removed the `replicator`**: if your HA design depended on it, it no longer exists —verify
  the supported path before replicating the old design.
- **Queue as the primary signal**: watch size, age of the oldest message and deferral rate.
  A deferred queue growing towards a single domain is a reputation problem; towards all of them, a
  network or DNS problem.
- **Reputation as a permanent task**: PTR matching the HELO and the public name, dedicated
  IP, gradual volume warm-up, enrolment in the receiver's tools (Postmaster
  Tools, SNDS) and a complaint feedback loop. **Blocklist monitoring with alerting**, not a
  manual lookup when somebody complains.
- **Migration between platforms**: `imapsync` and equivalents work, and the real cost **is not the
  tool**: it is the time per mailbox (hours per gigabyte with source-side rate limits), the special
  folders and flags that do not map, the dual-delivery window, the MX change with its
  TTL (`dns-standards`) and reconfiguring every client. Plan incremental passes and a
  short final one, never a single pass on cut-over day.
- **Logging and personal data**: mail logs contain addresses, subjects at some
  levels and relationship patterns. Bounded retention, restricted access and a justified level of
  detail (`privacy-engineering-standards`).

## 7. Sustainability and prohibitions

Cadence: patch the MTA/MDA **outside the window** on a remotely exploitable CVE (Exim and Dovecot
have form); a major version jump treated as a project —Dovecot's 2.3→2.4 **rewrites the
configuration**—; quarterly review of licences and commercial models of the suites, which change.

- ❌ Exposing a mail server without a **reputation plan** (PTR, warm-up, blocklist
  monitoring, receiver tools and someone on call).
- ❌ Running your own mail to "save money" without counting on-call, patching and incident response.
- ❌ Leaving an open relay, or not re-testing the relay from outside after every change.
- ❌ Accepting mail for recipients you cannot validate and bouncing afterwards (backscatter).
- ❌ Standing up a secondary MX that does not share the list of valid recipients.
- ❌ Allowing AUTH without TLS, or leaving POP3/IMAP in the clear "only on the internal network".
- ❌ Leaving POP3 enabled by default with no documented exception.
- ❌ Mailboxes without a quota, or without an alert on volume usage.
- ❌ Using `mbox` with concurrent access.
- ❌ Signing with DKIM mail that the server has not authenticated.
- ❌ Storing the DKIM private key in the repository or in the container image.
- ❌ Upgrading Dovecot 2.3 → 2.4 without converting the configuration and without testing in a separate environment.
- ❌ Trusting the commercial edition's version number as if it were the community one's
  (Dovecot Pro 3.x versus CE 2.4.x).
- ❌ Writing a project off as abandoned because its GitHub repository is archived (the Exim case).
- ❌ Migrating mailboxes in a single pass on cut-over day, with no prior incremental.
- ❌ Duplicating the SPF/DKIM/DMARC policy here: it belongs to `email-security-standards`.

## 8. Mandatory web verification

1. **Version and security advisories** for Postfix (`postfix.org/announcements.html`), Exim
   (**`exim.org`, not GitHub**; its identifiers are **GCVE**), Dovecot CE (`dovecot.org/releases/`)
   and Rspamd, before pinning any version.
2. **Licence in raw, always**: `LICENSE`/`LICENCE`/`COPYING`/`LICENSE.md`/`LICENSES/` and on the
   right branch. In this batch: Postfix EPL-2.0 **or** IPL-1.0; Exim `LICENCE` GPL-2.0-or-later with
   an OpenSSL exception; Dovecot mixed MIT+LGPL-2.1; Rspamd Apache-2.0; mailcow GPL-3.0; Mailu MIT;
   iRedMail GPLv3 + proprietary Pro; Stalwart AGPL-3.0-only + SELv2; imapsync its own licence.
3. **Commercial model** of the suites: it changes faster than the code and decides whether you can use them.
4. **Requirements of the large receivers**: re-read Google's, Yahoo's and Microsoft's guidance
   before promising delivery. **Declared gap**: Microsoft's page on high-volume
   senders **is rendered by JavaScript and could not be read in raw**; the dates of 2 Apr 2025 and
   5 May 2025 come from a web search that cites it, and **the date for moving to outright rejection
   was "to be announced"**: re-verify it on Microsoft's blog.
5. **Declared gap — DMARC hardening**: it is claimed that in 2026 the large receivers would require
   `p=quarantine`/`p=reject`. **I could not confirm this in a primary source**: treat it as a rumour
   until you see it in the provider's guidance, and consult `email-security-standards`.
6. **RFCs one by one at `rfc-editor.org`** before citing them: check status and the
   *obsoleted_by* / *updated_by* fields. Common assumptions were already corrected here: 5321 and 5322 are
   **Draft Standard** and are **not** obsolete, 6409 and 1939 are **Internet Standard**, and 3501
   is obsoleted by 9051.
7. **JMAP status**: which servers and clients actually implement it, and whether Dovecot has
   added it. That is the data point that decides whether you stop ignoring it.
8. **Supported HA path in Dovecot 2.4** after the removal of the `replicator`, and the status of the
   configuration converter.

If the web contradicts this document, **the web wins** — flag the discrepancy.
