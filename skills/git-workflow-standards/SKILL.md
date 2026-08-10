---
name: git-workflow-standards
description: Git branching, commit and release process standards. Use when working with branching strategy, Conventional Commits, rebase vs merge, PR size limits, CODEOWNERS, protected branches or rulesets, SemVer tagging, CHANGELOG, release-please/changesets/semantic-release/goreleaser, git-filter-repo, Git LFS, or GPG/SSH commit signing.
---

# Git and release process standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when defining or reviewing how the repository is used and how a version ships: branching strategy, branch naming and lifetime, commit messages and `commitlint.config.*`, rebase/merge/squash policy, PR size and review checklist, `CODEOWNERS`, protected branches and rulesets, `.gitattributes`/`.gitignore`, tags and semantic versioning, `CHANGELOG.md`, configuration of `release-please`/`changesets`/`semantic-release`/`.goreleaser.yaml`, monorepo vs polyrepo and their tooling, history hygiene (`git-filter-repo`, BFG, Git LFS), commit and tag signing, `git bisect`/`blame`, and hotfix, revert and rollback procedures.

Guiding principle: **Git history is diagnostic and audit infrastructure**, not an accidental record of what happened. It is designed so that two years from now someone can answer "why is this line like this" with `blame` and "which commit broke it" with `bisect`; everything else (merge style, message format, PR size) follows from that.

**Not applicable**: see `cicd-standards` (the pipeline itself — jobs, runners, OIDC, SBOM, artifact signing and verification, deployment: it assumes the repo is already governed by this skill), `api-design-standards` (versioning of the API **contract**, which is independent of the package's SemVer), `appsec-standards` (triage of the findings the scanners produce), `cryptography-pki-standards` (algorithm choice, key management and PKI lifecycle; here only the concrete application to commits and tags), the language skills (publishing to the ecosystem registry: npm, PyPI, crates.io, Maven), `developer-workstation-standards` (**the signing policy —what gets signed, in which format and what is required on protected branches— belongs here**; **where the key lives and how it is custodied is theirs**: key in hardware, `verify-required`, and the minimum OpenSSH version Git's SSH signing requires), `code-review-standards` (**fine boundary, arbitration rule**: **everything mechanical and configurable about the repository belongs here** —branching strategy, commit format, `CODEOWNERS`, protected branches and *rulesets*, number of approvals required, the PR size limit as a rule—; **human judgement belongs there**: what to look for when reviewing and in which order, how to word a comment and what makes it blocking or a suggestion, which changes require a specialist reviewer, and how to review an AI-generated diff. In one sentence: **this skill sets the number, theirs supplies the judgement**. What this skill says about PR size, review SLA, the `nit:` prefix and "approving without having read is a false signature" is kept as a repo convention, but **its criteria live there and there they win if there is a discrepancy**).

## 2. Default decisions

> Verify the latest version on the web before pinning it in a real project (§8).

| Area | Default | Justifiable alternative |
|---|---|---|
| Branching model | **Trunk-based**: `main` always deployable + short-lived branches | GitHub Flow (equivalent, with mandatory PR); **GitFlow only** with versioned releases and several major versions supported in parallel (installable software, firmware) |
| Maximum branch lifetime | **≤ 2 days**, ideally < 1 | Up to 1 week with a documented daily rebase |
| Integrating large work | **Feature flags** + continuous merge to `main` | A long-lived branch only with an ADR justifying it |
| Merge policy into `main` | **Squash** (one logical unit per PR) with a Conventional Commit title | Rebase + fast-forward if the PR's commits are already atomic and clean; merge commit in repos that integrate release branches |
| Message format | **Conventional Commits 1.0.0** | A bespoke format only if you do not use release automation |
| Versioning | **SemVer 2.0.0**, annotated and signed `vX.Y.Z` tags | CalVer for products with no public API (internal services, infra) |
| Release automation | **release-please** (polyglot, monorepo, reviewable release PR) | `changesets` in JS/TS monorepos; `semantic-release` for fully automatic publishing; `goreleaser` for Go artifacts |
| Signing | **SSH with an `ed25519-sk` key on a YubiKey** (§5) | GPG with the OpenPGP applet if you need real revocation or an existing chain of trust |
| Protection of `main` | GitHub **rulesets** (they apply to admins by default) | Classic branch protection only in repos already configured with it |
| Repo strategy | **Polyrepo** by default; monorepo when changes systematically cross several repos | — |
| History rewriting | **git-filter-repo** | — |
| Large binaries | **Git LFS** with a versioned `.gitattributes` | — |

## 3. Branches, commits and review

### 3.1 Branches

- Naming: `<type>/<ticket-id>-<short-slug>` (`feat/PROJ-412-cursor-pagination`, `fix/PROJ-508-null-etag`). Lowercase, hyphens, no personal names (`juan/pruebas`) and no generic ones (`temp`, `wip`, `test2`).
- **One branch = one reviewable unit of value**. If describing it requires an "and", it is two branches.
- Sync with `main` **daily** by rebase while the branch is not published/shared. A branch that has gone a week without a rebase is no longer integrating: it is forking.
- Automatic branch deletion on merge. Dead branches on the remote are noise and confuse `bisect`.
- `main` protected; release branches (`release/1.x`) only in the GitFlow model and with the same protection.

### 3.2 Commits

- **Atomic**: a commit compiles, passes tests and does *one* thing. Refactor and behaviour change **always in separate commits** — mixing them makes review impossible and `bisect` useless.
- Conventional Commits 1.0.0: `<type>[optional scope]: <description>`. The spec only requires `feat` and `fix`; the rest (`docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`) is team convention and does **not** affect the version bump unless it carries a breaking change. Breaking: `!` after the type/scope **or** a `BREAKING CHANGE:` footer — maps to major.
- Subject in the imperative, ≤ 72 characters, no trailing full stop. **The body explains the why**, not the what (the diff already says the what): context, discarded alternatives, consequences. Footer with the ticket reference and `Co-authored-by:` where applicable.
- Forbidden: `wip`, `fix`, `.`, `asdf`, "various fixes". If the commit needs that message, it is not finished yet — use `git commit --fixup`/`--squash` + `rebase --autosquash`, or `git history fixup` if your Git version ships it (experimental since 2.55).
- Generated or assisted commits: real authorship is reflected in `Co-authored-by`; the message is still the responsibility of whoever signs it.

### 3.3 Rebase vs merge

- **Rebase** to bring an unpublished branch of your own up to date and to clean up history before the PR.
- **FORBIDDEN to rebase/force-push on shared or published branches** (including `main`). If something already published must be corrected: `git revert`, never a rewrite. Single exception: removal of a secret or of personal data (§5.3), and with explicit coordination across the whole team.
- If you need a force-push on your own branch, **`--force-with-lease`** (ideally `--force-if-includes`), never a bare `--force`.
- Squash on merge: keeps `main` readable and with one commit per unit of value. Mandatory consequence: **the PR title must comply with Conventional Commits** and is linted in CI, because it is the message that stays in history.
- With `--first-parent` in `log`/`bisect`, a squashed `main` is a linear sequence of complete changes: that is what makes `git bisect` cheap.

### 3.4 Pull requests and review

- **Size**: target ≤ 400 lines of net diff, hard maximum ~800 except for mechanical changes (generated, mass renames, lockfiles) declared in the description. Above that, review stops detecting defects and becomes a formality. Large PR ⇒ split it or review it commit by atomic commit.
- Description with: what changes and why, how it was verified, risk and rollback plan, screenshots or outputs where applicable. Link to the ticket. A PR that does not explain the why is not ready for review.
- Reviewer checklist: correctness and edges; security (inputs, authz, secrets, new dependencies); meaningful tests covering the failure, not just the happy path; observability of the change; backwards-compatible migrations; documentation and an ADR if the decision is one-way.
- **Etiquette and SLA**: first response within **≤ 1 working day** (a blocked PR is depreciating inventory). Comments about the code, not about the person; distinguish blocking from suggestion (`nit:` prefix); if there are more than 3 round trips, the conversation moves to synchronous. Approving without having read is a false signature.
- **CODEOWNERS** in `.github/CODEOWNERS` for critical areas: CI workflows, IaC, migrations, authentication, API contracts. The last matching rule wins — order matters. Owner review mandatory on those paths.

### 3.5 Protected branches and rulesets

On `main` (and on release branches), at minimum:
- Mandatory PR with ≥ 1 approval (2 on sensitive code), CODEOWNERS review where applicable, and dismissal of approvals on a new push.
- **Required status checks** with the explicit list of jobs, and "up to date before merging" or a merge queue. Careful: checks are referenced **by name**; renaming a job in CI silently disables the gate.
- Linear history required (consistent with squash/rebase), no force-push, no branch deletion.
- **Mandatory signed commits** (§5.1). Verified nuance: with rulesets, when creating a branch only the commits not reachable from other branches are checked; classic branch protection does not verify signatures on branch creation unless you restrict who can create branches.
- Prefer **rulesets** over classic protection: they apply to administrators by default, they can be defined at the organisation level, and they are evaluable/auditable as a whole.

## 4. Versioning, release and monorepo

### 4.1 SemVer and changelog

- SemVer 2.0.0 over the artifact's **public contract**: major = breakage, minor = compatible functionality, patch = fix. `0.x` is explicitly "no guarantees" — leave `0.x` once there are real consumers.
- **Annotated and signed** tags (`git tag -s vX.Y.Z -m`), immutable. **Moving a published tag is forbidden**: if the release is wrong, publish `X.Y.Z+1` and mark the previous one as *yanked* in the registry.
- `CHANGELOG.md` **generated** from the commits (Keep a Changelog as the format), never hand-written in parallel. Breaking-changes section with migration instructions: a breaking change without a migration guide is an incomplete release.
- The release includes: signed tag, notes, artifacts and their verification. Building, signing and publishing those artifacts is `cicd-standards`.

### 4.2 Tooling

- **release-please**: reads Conventional Commits, opens a **release PR** (human checkpoint), supports multiple ecosystems and monorepos with independent or linked versioning. Default when you want to review before publishing.
- **changesets**: change file written by the contributor (not inferred from the commit) — fits JS/TS monorepos with many packages and external collaboration. Limited to the JS ecosystem.
- **semantic-release**: publishes straight from CI with no checkpoint. Only with a reliable test suite and a team comfortable with continuous release.
- **goreleaser**: Go artifacts (cross-platform binaries, Homebrew, containers). **It does not create tags**: combine it with release-please/semantic-release/`svu` for the version.
- Without enforcement of Conventional Commits, these tools **silently ignore** non-compliant commits: the change simply never ships. Message linting is part of the release system, not cosmetics.

### 4.3 Monorepo vs polyrepo

- **Polyrepo by default**. Monorepo when changes systematically cross repos (atomic multi-package change), or when you share tooling and want a single dependency graph. The monorepo trades a coordination problem for a build-tooling problem.
- If monorepo: build with a graph and cache (Nx, Turborepo, Bazel/Buck2 depending on scale), running **only what is affected** in CI, `CODEOWNERS` per directory, per-package versioning (independent or linked) and `sparse-checkout`/`--filter=blob:none` for partial clones in large repos. Without "only what is affected" and without caching, the monorepo is a tax on every PR.
- The decision is **one-way in practice** (migrating takes months): ADR mandatory.

## 5. Repository security and hygiene

### 5.1 SSH signing backed by a YubiKey (concrete configuration)

Verified requirements: Git ≥ 2.34 (SSH signing), OpenSSH ≥ 8.2 (FIDO2 `-sk` keys), ≥ 8.4 for `-O verify-required`. YubiKey series 5/Bio/Security Key; *resident* keys require a configured FIDO2 PIN.

```bash
ssh-keygen -t ed25519-sk -O resident -O application=ssh:git -O verify-required \
  -C "dev@digitalexperiments.dev git signing"
```

```gitconfig
[user]
    signingKey = ~/.ssh/id_ed25519_sk.pub
[gpg]
    format = ssh
[gpg "ssh"]
    allowedSignersFile = ~/.config/git/allowed_signers
    revocationFile     = ~/.config/git/revoked_signers
[commit]
    gpgsign = true
[tag]
    gpgsign = true
```

`~/.config/git/allowed_signers` (format documented in `ssh-keygen(1)`, ALLOWED SIGNERS section):

```
dev@digitalexperiments.dev namespaces="git" valid-after="20260101" sk-ssh-ed25519@openssh.com AAAA...
```

Concrete rules and traps:
- **Do not generate the key with `-O no-touch-required`**: there are verifiers (GitLab, and GitHub via the `ssh_data` library) that mark signatures from `-sk` keys with that option as *unverified*. The per-commit *touch* is the price of extraction resistance; if it annoys you, batch with `--fixup` + `rebase --autosquash` instead of disabling it.
- On GitHub the key must be uploaded as a **Signing Key** — a separate record from the Authentication Key, even if it is the same material. Also, the **committer** email must be a verified email on the account or the badge does not appear. And careful: the signature verifies the *committer*, not the *author*.
- **Rotation and revocation**: GitHub does not revoke SSH signing keys (the verification is recorded and persists). Locally, `valid-after`/`valid-before` in `allowed_signers` invalidates from a given date onwards while keeping prior history valid; `revocationFile` invalidates **historical commits as well** — use it only in the event of a real key compromise.
- Local verification: `git log --show-signature`, `git verify-commit <sha>`, `git verify-tag <tag>`. Without `allowedSignersFile` configured, `verify-commit` fails with a configuration error, not with "invalid signature": do not confuse the two.
- A second backup YubiKey enrolled **from the start** (a lost key with no backup = signing identity lost) and both public keys in `allowed_signers` and in the forge.
- GPG alternative with the YubiKey's OpenPGP applet: valid and with real revocation (offline revocation certificate), at the cost of managing `gpg-agent`, pinentry and touch policy with `ykman` (verify the exact syntax, §8). Do not mix both formats in the same repo.
- **gitsign/Sigstore** (keyless signing via OIDC, ideal for bots in CI): maintained and with recent releases, but **GitHub does not display its signatures as Verified** — its root is not in the forge's trust root. Use it for CI traceability, not for the badge.
- Server side: rulesets with "require signed commits" on GitHub; on GitLab, the **Reject unsigned commits** push rule (Premium/Ultimate) — which also blocks commits from the Web IDE unless an admin disables the corresponding feature flag, and which has produced false rejections with bot signatures.

### 5.2 Secrets

- **Prevention first**: secret scanning with push protection in the forge + local hook + CI gate. Scanning is the last net, not the policy. The **choice of scanner and its licence** belong to `secrets-management-standards` (as of Aug 2026 `gitleaks` is *feature complete* and its GitHub action requires a commercial licence for organisations: verify before pinning it); the **post-leak procedure** also lives there — the secret is burned even if you rewrite history: you rotate first and clean up afterwards.
- A secret that reached the repo **is compromised**: the order is *rotate → revoke → invalidate → then clean history*. Deleting the commit without rotating is theatre: there are forks, clones, forge caches and CI logs.
- No `.env` with real values committed; `.env.example` with empty keys, a `.gitignore` covering artifacts, credentials and dumps, and `.gitattributes` to avoid mangling binaries.

### 5.3 History rewriting and large files

- **`git-filter-repo`** is the tool (Git officially discourages `filter-branch`: slow, full of traps and with non-obvious manglings). BFG is still published but with no recent releases; its community continuation is `bfg-ish`.
- Rewriting published history is a coordinated operation: advance notice, agreed window, everyone re-clones (`git pull --rebase` is not enough), forge forks invalidated and the provider's support contacted to purge caches and old PRs.
- Binaries and large files: **Git LFS** with a versioned `.gitattributes`, decided **before** the first commit (migrating later means a rewrite). Alternative: do not version them and publish them as release artifacts. A repo dragging binaries around is a repo nobody clones in under 10 minutes.
- Git LFS: use **≥ 3.7.1**, which fixes CVE-2025-26625 (writes outside the working tree through symlink/hardlink collisions with LFS paths in `checkout` and `pull`).

## 6. Diagnostics and emergency procedures

- **`git bisect`** is the reason you require atomic, green commits. `git bisect start/bad/good` + `git bisect run <script>` automates the search; with a linear `main` (squash) and `--first-parent`, the search space is one unit of value per step.
- A useful **`git blame`** requires not polluting history with reformatting: mass formatting changes go in their own commit and that SHA is recorded in `.git-blame-ignore-revs` (+ `blame.ignoreRevsFile` in the repo config).
- Useful when debugging: `git log -S<string>` (pickaxe, when a piece of text appeared/disappeared), `git log -L` (evolution of a line range), `git reflog` (recover what you thought was lost: almost nothing is truly lost within 90 days).
- **Revert**: `git revert <sha>` is the default mechanism for undoing on `main`. If the commit was a merge, `-m 1`; document in the message what is being reverted and why, and open the ticket for the fix — a revert is not the fix, it is the containment.
- **Hotfix**: branch from the production tag (not from `main` if `main` has moved on), minimal change, same CI gates (never `--no-verify` nor an admin merge bypassing checks), signed patch tag, and **backport to `main` the same day** with verification that it exists. A hotfix that never returns to `main` reappears in the next release.
- Production **rollback** is a deployment event (promoting the previous artifact), not a Git one; reverting the commit without deploying fixes nothing. See `cicd-standards`.
- Blameless postmortem when the cause was process (long-lived branch, giant PR, disabled gate): the follow-up action is a change to these rules, not a word with a person.

## 7. Sustainability and prohibitions

**Cadence**
- Weekly: review of open PRs > 3 days and of branches with no activity for > 1 week (they are closed or rescued).
- Monthly: review of protection rules and required checks (do those jobs still exist under that name?), and of the release tooling version.
- Quarterly: `git maintenance` / `gc` in large repos, review of repo size and LFS patterns, audit of active signing keys and of write-permission access.
- Per Git version: the defaults are going to change in **Git 3.0** (SHA-256 by default in new repos, reftable as the reference backend, default branch `main`, `safe.bareRepository=explicit`, Rust mandatory; removal of grafts, `git-pack-redundant`, `git whatchanged`, `name-rev --stdin`). No announced date: do not depend on behaviours already marked for change.

**FORBIDDEN**
- ❌ Pushing directly to `main` (including admins and bots) or merging around the gates.
- ❌ `--no-verify`, `[skip ci]` or disabling a check "temporarily" without an issue, a reason and an expiry date.
- ❌ Rebase or force-push on shared branches; `--force` without `--force-with-lease`.
- ❌ Rewriting published history except for secrets or personal data, and without explicit coordination.
- ❌ Moving, reusing or deleting an already-published tag.
- ❌ Long-lived branches without an ADR; parallel release branches "just because".
- ❌ Commits mixing refactor and behaviour change; commits that do not compile or break tests.
- ❌ Content-free messages (`wip`, `fix`, `.`) in `main`.
- ❌ A PR without a description, without declared verification or above the size limit without justification.
- ❌ Approving a PR without reviewing it, or self-approval on paths with CODEOWNERS.
- ❌ Secrets, credentials, data dumps or large binaries committed without LFS.
- ❌ Deleting a secret from history **without rotating it** first.
- ❌ Unsigned commits or tags in repos with mandatory signing; `-sk` keys with `no-touch-required`; a signing key with no enrolled backup.
- ❌ A `CHANGELOG.md` hand-written in parallel with the generated one.
- ❌ A manual release from somebody's laptop (no signed tag, no pipeline, no traceability).
- ❌ `git filter-branch` in new repos (use `git-filter-repo`).
- ❌ A hotfix that never returns to `main`.

## 8. Mandatory web verification

Before pinning any data point from this document, **look it up — do not recall it**:

1. **Current Git version** and its release notes (as of Aug 2026, the official `BreakingChanges` doc referenced **2.55.0**, Jun 2026; 2.54 introduced experimental `git history` with `reword`/`split` and hooks by configuration, and 2.55 added `git history fixup`). Check `git-scm.com/docs/BreakingChanges` for the real state of Git 3.0 and its defaults.
2. **Git and Git LFS CVEs** and the minimum patched version before pinning a version requirement (Git LFS ≥ 3.7.1 because of CVE-2025-26625).
3. **Signing**: current support and nuances for `-sk` keys as a *signing key* on GitHub and GitLab, behaviour of `no-touch-required`, and the exact syntax of `ykman openpgp keys set-touch` if you go the GPG route. Stable version of OpenSSH and GnuPG.
4. **Rulesets vs branch protection** on GitHub: exact names of the available rules, status of classic protection (as of Aug 2026 documented as active, not formally deprecated) and status of merge queue. On GitLab, whether "Reject unsigned commits" is still Premium/Ultimate and the status of the Web IDE feature flag.
5. **Release tooling**: version and health of `release-please`, `changesets` (`@changesets/cli` 2.x), `semantic-release` (24.x; its documentation moved to `semantic-release.org`, the GitBook one is discontinued) and `goreleaser` (2.x line, with a paid Pro edition).
6. **Specs**: Conventional Commits (1.0.0 current at `conventionalcommits.org`) and SemVer (2.0.0 at `semver.org`).
7. **Monorepo**: current versions and **licences** of Nx, Turborepo and Bazel before committing to a choice — do not assume they are still the ones from your last read.
8. **Hygiene**: latest version of `git-filter-repo` (2.47.x in Jun 2026) and maintenance status of BFG/`bfg-ish`; current file and repo size limits of the forge you use.

If the web contradicts this document, **the web wins** — flag the discrepancy.
