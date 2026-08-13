---
name: file-servers-standards
description: Classic file-sharing servers — the protocol that exposes a directory tree to other machines, and its blast radius. Use when working with Samba (smb.conf, testparm, smbcontrol, smbstatus, smbd/nmbd/winbindd, net ads join, net usershare, "server min protocol", "server smb encrypt", "vfs objects", vfs_shadow_copy2, vfs_full_audit, vfs_worm, vfs_recycle, vfs_acl_xattr, vfs_fruit, idmap config, wbinfo, pdbedit, "valid users", "force group", "veto files", msdfs root and msdfs proxy), ksmbd (ksmbd.conf, ksmbd.mountd, ksmbd.addshare) and whether an in-kernel SMB server belongs in production, NFS exports (/etc/exports, exports.d, exportfs -ra, /var/lib/nfs/etab, rpc.mountd, rpc.gssd, nfsdcltrack, nfs.conf, fsid=0 and the v4 pseudo-root, no_root_squash, all_squash, anonuid/anongid, subtree_check, sec=sys/krb5/krb5i/krb5p, nfsvers=3 vs 4.1 vs 4.2, nconnect, xprtsec=tls and xprtsec=mtls, tlshd and ktls-utils per RFC 9289), POSIX ACLs versus NT ACLs (getfacl/setfacl, acl_xattr, security.NTACL), project or user quotas on a share, DFS namespaces, SMB signing and encryption enforcement, share-level auditing, and containing ransomware that arrives through a mapped drive or an NFS mount.
---

# File server standards (SMB/CIFS and NFS)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies to the **file-sharing protocol and its exposure**: what is published, with which
dialect, authenticated against what, encrypted or not, with which identity mapping and with which
effective permissions; and how it is audited, limited and contained when the client is hostile.

**Governing principle: a file server is a remote executor of arbitrary writes over a
directory tree, with the client's identity.** It is not "a disk on the network". Ransomware
that encrypts a share exploits nothing: it uses the share as designed.

Triggers: those in the frontmatter. **If the answer is written in `smb.conf` or in `/etc/exports`,
it belongs here.**

**Not applicable**: see `linux-storage-standards` (**the block layer and the POSIX filesystem
underneath**, and **the client side of NFS and iSCSI**. **An iSCSI `target` is not file sharing: it
is a raw disk with a single owner** — if the question involves `targetcli`, `LUN` or `initiator`, it
belongs there), `zfs-standards` (pool, dataset, snapshots and `zfs send`; **the snapshot that feeds
*Previous Versions* is created there and published here** through `shadow_copy2`),
`object-storage-standards` (S3: **if you need POSIX semantics it belongs here; if you do not need
them, do not mount a share**), `windows-server-ad-standards` (**the directory and Kerberos/NTLM as
domain protocols**; here only the **domain member**: `net ads join`, `winbindd`, `idmap` and which
SID ends up as which UID), `identity-access-management-standards` (federation and lifecycle; here
the identity→effective-permission mapping), `backup-recovery-standards` (**the copy** — **a *shadow
copy* published by `shadow_copy2` is not a backup**, §5), `bcdr-standards` (RTO/RPO and recovery
order), `cryptography-pki-standards` (the CA and custody of the key `tlshd` uses),
`networking-standards`, `firewall-policy-standards` and `dns-standards` (who reaches 445/2049, and
the `A`/`PTR`/SPN Kerberos needs so it does not fall back to NTLM), `linux-hardening-standards` (CIS
baseline), `selinux-standards` (`samba_export_all_rw`, `nfs_export_all_rw` and the booleans people
disable "to make it work"), `observability-standards` (retention of the events generated here),
`detection-engineering-standards` (the rule that detects mass encryption; here the event
that feeds it), `incident-response-forensics-standards` (the live case),
`web-app-servers-standards` (another exposed service, other criteria).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Decision | Criterion | Verified note |
|---|---|---|
| SMB implementation | **Samba in user space**, unless a measured case justifies otherwise | Stable series as of Aug 2026: **4.24** (4.24.5, 28 Jul 2026); **4.23** in maintenance (4.23.11, 3 Aug 2026); **4.22** security only; **4.21 EOL since 12 Sept 2025**. Declared cycle: ~6 months *current* + 6 maintenance + 6 security only |
| Samba's licence | **GPLv3** | Read raw: `COPYING` = *"GNU GENERAL PUBLIC LICENSE / Version 3, 29 June 2007"* |
| ksmbd (SMB in the kernel) | **Vetoed on anything exposed to untrusted clients** | Its advantage is performance; its cost is that **a failure in it is a kernel failure, not a process failure**. 2026 has accumulated serious remote CVEs (e.g. **CVE-2026-31704**, an overflow in DACL handling with public exploitation reported; **CVE-2026-23226**, a UAF from a missing lock). If it is used: segmented network, disciplined kernel patching and 445 closed at the edge |
| Minimum SMB dialect | **SMB3 (`SMB3_11`)**; SMB2_02 only if a client forces it. **SMB1/NT1/CIFS vetoed without exception** | Samba sets `client min protocol`/`server min protocol = SMB2_02` **by default since 4.11**, with SMB1 "officially *deprecated*". The default already excludes SMB1: **raising it to SMB3 is on you**, and re-enabling SMB1 is an explicit configuration change — if somebody did it, that is a finding |
| SMB signing | **Mandatory** on server and client | Windows 11 24H2 and Windows Server 2025 require it **by default** (24H2 Pro/Enterprise/Education inbound and outbound; Server 2025 outbound; Home does not). **Operational consequence: it breaks *guest* access and third-party NAS boxes that do not sign** — that is the signal, not the problem |
| SMB encryption | **Required** (`server smb encrypt = required`) outside the server LAN | Signing protects integrity, **not confidentiality**. If the data is personal or regulated, encryption is required even if the network is "internal" |
| SMB over QUIC | A real alternative to publishing 445, **not a substitute for a VPN by default** | On Windows Server 2025 it is in **every** edition (in 2022 it was Azure Edition only). In Samba, **4.23** introduced SMB3 over QUIC, and on Linux the **server requires an out-of-tree `quic.ko` module** — that disqualifies it as a production base until it is in the kernel (§8) |
| NFS version | **NFSv4.2**; v4.1 as the floor | v3 only for clients that do not support v4, with a retirement date. v3 **has no identity mechanism**: `AUTH_SYS` is a UID with no proof |
| NFS security | **`sec=krb5p`** where there is sensitive data; **`sec=sys` never crosses a trust boundary** | `krb5` authenticates, `krb5i` adds integrity, `krb5p` adds confidentiality. Increasing CPU cost: measure it, do not assume it |
| NFS over TLS (RFC 9289) | An option when Kerberos is not viable; **it does not replace user authentication** | `xprtsec=tls` / `xprtsec=mtls` at mount time and in `exports(5)`; in-kernel kTLS (server from 6.4; the client needs `CONFIG_NET_HANDSHAKE=y`) + `tlshd` from **ktls-utils** with `/etc/tlshd.conf` at both ends. **It does not support PSK.** It protects the transport; with `sec=sys` behind it, identity remains unproven |
| `no_root_squash` | ❌ **Hard veto** | It grants the server's root to the client's root. If it "is needed", the design is wrong: use `anonuid`/`anongid` or a dedicated export |
| ACLs | **NT ACLs over `acl_xattr`** on domain SMB shares; POSIX ACLs on UNIX-only shares | They are not mixed in the same tree: the NT model has inheritance and denials that POSIX does not represent, and "almost equivalent" produces effective permissions nobody predicts |
| Quotas | **Filesystem/project quotas, always** | A share without a quota is a DoS that fires on its own |

## 3. Structure and conventions

- **One share = one purpose = one group.** `valid users = @group`, never individual users and never
  `@Domain Users`. Permissions are administered in the directory, not in `smb.conf`.
- **The filesystem ACL rules; the `smb.conf` one is a ceiling, not the model.** Design the ACL in the
  tree and use the share parameters only to *restrict* (`read only`, `valid users`).
  Duplicating the model in two places guarantees they diverge.
- **`net usershare`**: lets non-root users publish shares. **Disabled**
  (`usershare max shares = 0`) unless there is a written use case; it is publishing data without review.
- **`vfs objects`: order matters** and every module costs latency per operation. Base set:
  `acl_xattr` (NT ACLs), `shadow_copy2` (previous versions from ZFS/LVM snapshots),
  `full_audit` (§5), `recycle` only if the business asks for it (**it is not a security bin: the
  ransomware empties it**), and `fruit`+`streams_xattr` **only** if there are macOS clients.
- **`vfs_worm` is not immutability.** Verified: **CVE-2026-2340** — the WORM module was bypassed by
  renaming a new file over the protected one. Real immutability lives in the backup
  repository (Object Lock / *append-only*), not in a VFS module.
- **NFSv4: `fsid=0` defines the pseudo-root** and everything else hangs off it. `nohide` is a v3
  thing; v4 always behaves as if it were on. **Export the exact point, not a parent "for
  convenience", and never to `*` as a client.**
- **`/etc/exports.d/` with one file per consumer**, under version control, applied with
  `exportfs -ra`. Verify the result in `/var/lib/nfs/etab`, **not in the source file**: that is
  where you see what the server actually applies.
- **DFS (`msdfs root`)** decouples the logical path from the physical server: it is what lets you
  retire a server without touching 4,000 mapped network drives. It is decided **before** the first
  migration.
- **Identity mapping (`idmap config`)**: an explicit range, **documented per domain**, with a
  deterministic backend (`rid`, `ad` or `autorid`) — never `tdb` on more than one server. Two servers
  mapping the same SID to different UIDs produce incoherent permissions that only show up on restore.

## 4. Quality, changes and testing

- **Gates before reloading**: `testparm -s` with no warnings and `exportfs -ra` with no errors are
  mandatory, not optional; plus an access test **with an unprivileged account** from a real
  client — mounting as admin proves nothing.
- **Negative permission test, always**: check that whoever must *not* read, does not read. Almost every
  share-based leak passes the positive test.
- **Configuration versioned and deployed by IaC** (`iac-standards`): editing `smb.conf` by hand in
  production is not reversible.
- **Periodic drift check**: the actually negotiated dialect (`smbstatus`), effective signing and
  encryption per session, live exports versus declared ones, and **orphaned shares** with no
  identifiable owner — which get retired, not inherited.

## 5. Stack security

- **Surface**: 445/TCP (SMB), 2049/TCP (NFS), 139/137/138 (NetBIOS — **switched off**), and the
  *portmapper* on 111 in v3. **None of them crosses a perimeter without additional control.**
- **Authentication**: Kerberos. NTLM is blocked or explicitly restricted; if everything falls back to
  NTLM, the cause is almost always DNS/SPN (`dns-standards`), and fixing it is part of the job.
- **Anonymous/guest: forbidden.** `map to guest = never`. And note: requiring signing **already
  disables guest access** — if somebody "fixed" an incident by disabling signing, they undid two controls.
- **Access auditing mandatory** on shares holding sensitive data: `vfs_full_audit` with the
  operations that matter (`pwrite`, `rename`, `unlink`, `mkdir`, `set_nt_acl`), shipped **off
  the server** (`observability-standards`). Without it the forensic analyst cannot answer "who deleted
  this" and mass-encryption detection has no signal.
- **Ransomware containment — it is a *permissions* problem, not an antivirus one**:
  1. **Minimum write**: the "everyone writes everywhere" share is the condition that turns a
     compromised workstation into a company outage.
  2. **No share gives access to the backup repository**: the backup credential does not live on the
     client and the repository is not mounted as a network drive (`backup-recovery-standards`).
  3. **Filesystem snapshots** as first-level recovery, with their own retention and **outside
     the reach of the client's credential**. `shadow_copy2` publishes them read-only;
     publishing them does not protect them.
  4. **Detection signal**: an anomalous rate of `rename`/`pwrite` per session and the entropy of new
     extensions. The rule belongs to `detection-engineering-standards`; the event is generated here.
- **Encryption in transit by default**: encrypted SMB3 or NFS with `krb5p`/`xprtsec=tls`. "It is the
  internal network" is not a control.
- **Patching**: Samba publishes remote CVEs regularly and some are **unauthenticated RCE**
  (verified in 4.23.8: **CVE-2026-4408** in the SAMR server with `%u` in the password-check
  script; **CVE-2026-4480** in the printing subsystem with `%J`). Corollary:
  **disable what you do not use** — printing, WINS, AD DC — because their surface reaches you even
  if you never use it. Patching SLA per `vulnerability-management-standards`.
- **SELinux booleans**: `samba_export_all_rw` / `nfs_export_all_rw` disable the service's confinement
  over the whole tree. Enabling them "to make it work" is a finding, not a
  solution (`selinux-standards`).

## 6. Performance and operability

- **Measure before touching anything**: most "SMB is slow" cases are network latency, antivirus on the
  client or metadata (directories with tens of thousands of entries), not server parameters.
- `nconnect=` in NFS multiplies TCP connections per mount: it helps with latency and **is not free**
  on the server. Set a measured value, not the maximum.
- **Encryption and `krb5p` cost CPU**: that is not a reason to drop them; it is a reason to size for them.
- **Watch**: sessions and dialect per session, `nfsd` queue depth, authentication
  errors, usage and quota per share, latency per metadata operation.
- **Reload with `smbcontrol`**: restarting `smbd` with open files corrupts data in
  applications that do not retry.

## 7. Sustainability and prohibitions

- **Cadence**: stay on Samba's *current* series or, at most, the maintenance one;
  **a series in "security only" is an upgrade plan with a date**, not a stable state.
- **Every share has an owner, a purpose and a review date.** File servers die of
  accumulation: shares from projects closed in 2014 with 2014's permissions.

- ❌ **FORBIDDEN to enable SMB1/NT1/CIFS.** Not even "temporarily" for a scanner or an industrial
  machine: that device gets segmented, the server does not get degraded.
- ❌ **FORBIDDEN: `no_root_squash`.** And exporting over NFS to `*` or to a subnet without justification.
- ❌ Disabling SMB signing to "fix" an incompatible client: it gets fixed or isolated.
- ❌ *Guest*/anonymous write access. And read access only with explicitly public data.
- ❌ Publishing 445 or 2049 to the Internet.
- ❌ Treating `vfs_recycle`, `vfs_worm` or published shadow copies as a backup or
  as immutability (§5, CVE-2026-2340).
- ❌ ksmbd exposed to untrusted clients, or with no guaranteed kernel patching.
- ❌ Mixing POSIX ACLs and NT ACLs in the same tree. ❌ Shares without quotas.
- ❌ `net usershare` enabled without an approved use case.
- ❌ Mounting the backup repository as a share reachable from workstations.
- ❌ Enabling `samba_export_all_rw`/`nfs_export_all_rw` as a remedy for a permissions problem.
- ❌ Accepting a configuration as good because it mounts from an administrator account (§4).

## 8. Mandatory web verification

Before pinning anything in a real project, check on the web:

1. **Samba's current series and its calendar** at `samba.org/samba/history/` and in the
   *Release Planning* wiki (as of Aug 2026: 4.24 *current*, 4.23 maintenance, 4.22 security only, 4.21
   EOL since 12 Sept 2025). **The source is samba.org, not a GitHub feed.**
2. **Samba CVEs since your version** (the release notes list them with descriptions; there are recent
   unauthenticated RCEs, §5) and **ksmbd CVEs in your kernel** if you use it.
3. **The state of SMB3 over QUIC in Samba**: whether the Linux server still requires the out-of-tree
   `quic.ko` module, or whether it is already in the kernel. **Its usability depends on that.**
4. **The exact `smb.conf` defaults** (`server min protocol`, `server smb encrypt`, `map to guest`)
   **in your version's manpage**, not from memory. **Declared gap**: I could not quote verbatim the
   default value of `server min protocol` in 4.24 — the manpage is too large to extract it with
   confidence — so all that is asserted here is the change documented in the **4.11** release notes
   (`SMB2_02`); confirm it with `testparm -v`, which is the definitive source.
5. **Windows-side SMB signing and encryption policy** (`learn.microsoft.com`, *SMB security
   hardening*): the defaults change per edition and version, and they determine which clients break.
6. **NFS over TLS**: minimum kernel and `ktls-utils`/`tlshd` in your distribution, and whether your
   array or your client supports it (there are documented incompatibilities, e.g. with NFS over RDMA). And
   **your distribution's `exports(5)`/`nfs(5)`** for the exact behaviour of `sec=` and `xprtsec=`:
   there are historical bugs where options are silently ignored.
7. **Licences read raw** (Samba's `COPYING` = GPLv3, verified).

If the web contradicts this document, **the web wins** — flag the discrepancy.
