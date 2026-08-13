---
name: developer-workstation-standards
description: Use when provisioning, hardening or rebuilding the machine a developer works on — versioned dotfiles and a bootstrap script, chezmoi/yadm/GNU stow, Homebrew Brewfile and brew bundle, winget import/export and winget configuration, Nix flake.nix, home-manager, devenv.nix and direnv .envrc, mise with mise.toml and .tool-versions, asdf, nvm/pyenv/rbenv/rustup/uv, .devcontainer/devcontainer.json and the devcontainer CLI, GitHub Codespaces or a cloud dev environment, .editorconfig and formatter/linter config committed to the repo instead of the machine, .vscode/settings.json and .vscode/tasks.json from an untrusted repo, VS Code or Open VSX extension supply chain and malicious extension incidents, curl | sh installers, full-disk encryption with FileVault/BitLocker/LUKS, screen lock and MFA on the workstation, SSH keys in hardware with ed25519-sk or ecdsa-sk and resident or verify-required options, gpg.format ssh and a signing key held on a YubiKey, credential.helper store writing plaintext to ~/.git-credentials, tokens in ~/.netrc or in shell history, pre-commit secret scanning, unattended OS updates, coding agents' filesystem and credential scope on the workstation, build times and RAM as an opportunity cost, or a laptop being used as a server.
---

# Developer workstation standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

**The developer's machine is software production infrastructure.** It is where the code lives
before it exists anywhere else, where the credentials that open production are kept and where
third-party code runs with the permissions of a person who has access. It is treated as
infrastructure: **it is provisioned as code, hardened and can be rebuilt**. The three verbs are
the thesis, and the third is the one that gets checked.

Operational corollary: ***"it works on my machine" is not an excuse: it is a provisioning
failure**, and it has an owner.* If the environment that makes the project work is not described
in the repository, it does not exist.

Triggers: *dotfiles*, `chezmoi`, `yadm`, GNU `stow`, *bootstrap* script, `Brewfile`,
`brew bundle`, `winget import`/`export`, `winget configure`, `flake.nix`, `home-manager`,
`devenv.nix`, `.envrc`, `direnv allow`, `mise.toml`, `.mise.toml`, `.tool-versions`, `mise`,
`asdf`, `nvm`, `pyenv`, `rbenv`, `rustup`, `uv`, `volta`, `.devcontainer/devcontainer.json`,
`devcontainer` CLI, Codespaces, `.editorconfig`, `.vscode/settings.json`,
`.vscode/extensions.json`, `.vscode/tasks.json`, VS Code / Open VSX extensions, `curl | sh`,
FileVault, BitLocker, LUKS, `ed25519-sk`, `ecdsa-sk`, `-O resident`, `-O verify-required`,
`ssh-agent`, `gpg.format ssh`, `user.signingkey`, `credential.helper store`,
`~/.git-credentials`, `~/.netrc`, `_netrc`, *shell* history, *build* time, coding agent running
locally.

**Not applicable**: see `macos-fleet-standards` (**critical boundary over the same hardware**:
**the corporate fleet is theirs** — automated enrolment and supervision, MDM and declarative
management, FileVault key escrow, pre-configured TCC, enforced update policy, software catalogue
and CIS/mSCP compliance —; **here the workstation of whoever programs**, which is provisioned as
code, hardened and rebuilt. They are two different problems and the conflict between them is
real: **a well-made fleet policy breaks development tools if permissions are not pre-configured**,
and that negotiation is resolved by naming both parties, not by ignoring one),
`linux-administration-standards` and `rhel-fedora-standards` (**the server and the managed fleet
are theirs**: init, system packages, mass patching, server configuration management; **here one
person's working machine**, which is neither managed the same way nor switched off the same way),
`linux-hardening-standards` (**the CIS server baseline and operating system hardening are
theirs**; **here workstation hardening**: laptop encryption, screen lock, key custody, third-party
code the editor executes), `homelab-standards` (**the personal lab is theirs**: tinkering, home
services, learning by breaking. **Here the tool you get paid with**; the boundary is hard and runs
in both directions — §7 forbids using the work laptop as a lab server),
`secrets-management-standards` (**owner of the choice of secrets manager and secret scanner**, of
the rotation policy and of the process after a leak. **Here only where credentials CANNOT be on
this machine** and that scanning happens **before** the *commit*),
`identity-access-management-standards` (SSO, corporate MFA, account life cycle, privileged access;
here its landing on the workstation), `git-workflow-standards` (***commit* signing as a repository
policy is theirs**: requiring it, verifying it, `CODEOWNERS`, protected branches. **Here the
custody of the key it is signed with** — that it lives in hardware and not in `~/.ssh` in the
clear), `cicd-standards` (**parity between what runs locally and what runs in CI is defined
there**; **here the obligation that the local machine can reproduce it**: same runtime versions,
same formatters, same *hooks*. A *lint* that passes locally and fails in CI is a failure of this
skill), `container-runtime-security-standards` and `podman-systemd-containers-standards` (the
container runtime and its hardening; here only its use as a development environment),
`endpoint-security-standards` (**third-party EDR and the posture of the encryption guard across
the fleet** — which product, what is required of it and how coverage is measured — **are theirs**;
here the encryption and the keys of this machine as a decision of whoever uses it),
`ai-agent-workflow-standards` (**reciprocal, already declared from their side**: **the working
process with coding agents is theirs** — what is asked of them, how their output is reviewed, how
it fits the flow, indirect instruction injection, accountability for the diff. **Here only
hardening**: which permissions, what filesystem scope and which credentials the agent reaches from
this machine, §5.7), `claude-code-skills-standards` (skill authoring),
`bash-linux-scripting-standards` and `powershell-standards` (**the quality of the *bootstrap*
script** — `set -euo pipefail`, `shellcheck`, idempotence — is theirs; here what that script has
to do), `iac-standards` (IaC for real infrastructure) and
`performance-engineering-standards` (**sister skill of this wave**: the performance of the
**product**. **Here the performance of the machine**, which is team time, not user latency — §6).

## 2. Default decisions

> Verify the latest version and the licence on the web before fixing it (§8).

### 2.1 Provisioning

| Need | Default | Licence / verified status | When something else is justified |
|---|---|---|---|
| System packages (macOS) | **Homebrew** with a versioned `Brewfile` + `brew bundle` | BSD-2-Clause (raw `LICENSE.txt`) | MacPorts in environments with their own build requirements |
| System packages (Windows) | **`winget`** with an exported manifest (`winget export`/`import`) | winget-cli: MIT (raw `LICENSE`) | Scoop or Chocolatey if there is already investment; **do not mix three managers** |
| System packages (Linux) | The distribution's manager (`linux-administration-standards`) | — | Nix if real reproducibility is sought (below) |
| Strict reproducibility | **Nix** (`flake.nix`, `home-manager`) or **`devenv`** | `devenv`: Apache-2.0 (raw `LICENSE`) | Only if the team sustains it: the learning curve is real and so is the maintenance cost |
| Per-project runtime versions | **`mise`** (`mise.toml`, understands `.tool-versions`) | MIT (raw `LICENSE`) — v2026.8.1 (Aug 2026), very high release cadence | `asdf` if already deployed; the native ones (`rustup`, `uv`, `nvm`) if the team is single-language |
| Per-directory environment variables | **`direnv`** (`.envrc`) | MIT (raw `LICENSE`) | `mise` covers part of the case and avoids one tool |
| Containerised development environment | **Dev Containers** (`.devcontainer/devcontainer.json`) | Spec: CC BY 4.0 (Microsoft). Reference CLI `devcontainers/cli`: **MIT**, active (Aug 2026) | Real multi-vendor adoption (VS Code, JetBrains, cloud services), **with uneven feature parity across implementations** |
| *Dotfiles* | **`chezmoi`** (templates and per-machine secrets) or `stow` if there is no divergence between machines | Verify the licence before fixing it (§8) | `yadm` if the team already uses it |

**`mise` versus `asdf`, status verified as of August 2026** — the comparison has changed and the
old guides lie:

- **`asdf` was rewritten in Go in 0.16.0** (it used to be Bash). It is a binary, it is much
  faster than the Bash version, and it **removed commands** from the Bash era (`asdf global`,
  `asdf local`, `asdf shell`). Verified version: **v0.20.0** (7 Jul 2026). **Any internal
  documentation or script using `asdf global`/`asdf local` is broken**, and that is the real cost
  of migrating, not performance.
- **The performance argument has deflated**: `mise`'s documentation acknowledges that, against
  `asdf` in Go, the speed difference is now a *minor* reason; the remaining reasons are supply
  chain security, ergonomics and not depending on *shims*.
- **`mise` is withdrawing `asdf` plugins for supply chain reasons**: its documentation states that
  `asdf` plugins are considered legacy and that **no new `asdf` or `vfox` plugins are accepted**
  in its registry, directing to the `aqua` (preferred) or `github` *backends*. **This is a
  security criterion, not a matter of taste**: an `asdf` plugin is a third party's shell script
  that runs on every directory change.
- **Hard rule**: **one single version tool per machine.** `mise` and `asdf` inject *hooks* into
  the *shell* and **conflict** if both are present.

**Choice criterion, short**: `mise` by default for a polyglot team; the native managers if the
team is single-language; Nix/`devenv` only if somebody really maintains it.

### 2.2 The reproducibility ladder — climb only as far as needed

| Level | What it guarantees | Cost | When it pays off |
|---|---|---|---|
| 0. Nothing (README with steps) | Nothing | 0 | Never. It is the default state and it is a failure |
| 1. *Dotfiles* + package manifest + per-project runtime versions | Machine rebuildable in hours; identical runtime across people | Low | **Mandatory floor of this skill** |
| 2. Dev Container | System and service dependencies the same for everyone, isolated from the host | Medium (I/O and start-up, especially outside Linux) | Project with system dependencies, or team with mixed operating systems |
| 3. Nix / `devenv` | Reproducibility down to the dependency tree | High and **permanent** | Only with a declared owner. Without one, it falls over in the first week of holidays |
| 4. Remote or ephemeral cloud environment | Disposable machine, data that never touches the laptop | **Direct hourly cost and network dependency** | Below |

**When a remote or ephemeral environment pays off**, and when it does not:
- **Yes**: when the build needs more machine than fits in a laptop; when the code or the data has
  to be isolated from the device (contractors, compliance, regulated data); when onboarding new
  people is frequent and the cost of setting up a machine dominates; when the project needs a
  topology impossible locally.
- **No**: when the team works with a bad or intermittent network (bad typing latency destroys more
  productivity than any CPU compensates for); when the work is interactive with a GUI or local
  devices; when nobody has calculated the bill.
- **Always**: **the cost is hourly and runs while nobody is looking.** Automatic shutdown on
  inactivity **from day one**, not as a later improvement. And **the remote environment does not
  exempt you from hardening the laptop**: it still holds the credentials that open the remote
  environment.

### 2.3 Editor configuration: in the repository, not on the machine

- **`.editorconfig` in the repository, always.** It is the only thing every editor understands.
- **Formatter and linter configuration goes in the repository** (`.prettierrc`, `biome.json`,
  `ruff.toml` in `pyproject.toml`, `.clang-format`, `rustfmt.toml`, `.golangci.yml`), **with the
  tool version pinned**. The specific tool is chosen by the language skill; **the criterion here
  is where the configuration lives and that the version is pinned**.
- **A formatter whose version is not pinned produces different diffs per person** and turns every
  PR into noise. It is the most common shared-configuration failure.
- **Never depend on each person's editor "format on save"** as a guarantee: the guarantee is the
  pre-commit *hook* and the CI gate. Editor configuration is convenience; **the gate is the
  contract** (`cicd-standards`).
- **`.vscode/extensions.json` recommends; it does not install silently.** It is reviewed as code,
  with the same suspicion as any dependency (§5.6).

## 3. Structure: what is versioned

```
dotfiles/                     # own repository, public or private depending on contents
├── install.sh                # idempotent bootstrap, runnable N times without breaking
├── Brewfile / winget.json    # per-system package manifest
├── shell/                    # shell config WITHOUT secrets
├── git/                      # gitconfig with includeIf per context (personal/work)
├── ssh/config                # config YES; private keys NEVER
└── README.md                 # what it does and what it does NOT do

<project>/
├── .editorconfig
├── mise.toml                 # project runtime versions
├── .envrc                    # NON-secret variables; references to the secrets manager
├── .devcontainer/            # if applicable
├── .vscode/                  # shared settings and tasks, reviewed in PR
└── .pre-commit-config.yaml   # or equivalent: formatting, lint, secret scanning
```

**Hard rules**:
- **The *dotfiles* repository contains no secrets.** No private keys, no tokens, no real `.env`
  files, no histories. References to the secrets manager, yes.
- **The *bootstrap* script is idempotent and non-interactive by default.** A *bootstrap* that only
  works the first time is useless for the case that matters: rebuilding in a hurry.
- **Git configuration separates contexts** (`includeIf gitdir:`): personal and work identity,
  email and signing key **are not mixed**. Signing a work *commit* with the personal identity is a
  personal data leak, as well as a mess.
- **`~/.ssh/config` versioned, private keys never.** Not encrypted, not "the repo is private".

## 4. The test that validates all of this: the rebuild

**Provisioning that has not been tested does not exist.** It is the same criterion as a backup
with no tested restore.

- **Periodic rebuild exercise**: set the machine up from scratch — or a clean VM, or a container —
  with the *bootstrap*, and **time it**. The target is set per team (§8: this skill does not
  invent a number), but the **criterion is binary**: at the end, can you clone the main
  repository, build, pass the tests and deploy? If an undocumented manual step is missing, **the
  failure belongs to the provisioning and is fixed there**, not in the wiki.
- **Minimum cadence**: every time somebody new joins (their onboarding *is* the test, and their
  friction is the result), and on any major operating system change.
- **Parity with CI, checked**: the runtime versions declared by `mise.toml` / `.tool-versions` are
  **the same** ones the *pipeline* uses. It is verified automatically, not by habit. A green
  `lint` locally and red in CI means parity broke and it is a failure to fix, not a nuisance to
  tolerate. The *pipeline* belongs to `cicd-standards`; **the obligation to reproduce it locally
  belongs here**.
- **The machine is not a pet.** If losing it hurts for any reason beyond rebuild time, there is
  unversioned state that should be versioned. **That state is identified and taken off the
  machine.**

## 5. Workstation security — the critical section

The workstation is **the highest-return target** in the supply chain: it has the code before
review, the production credentials and the trust of every system it connects to. And the
2025-2026 evidence is that it is attacked there (§5.6).

### 5.1 Non-negotiable base

- **Full-disk encryption enabled and verified**: FileVault, BitLocker (with TPM and PIN or boot
  password), LUKS. **Verified**, not "enabled during onboarding": its status is checked. An
  unencrypted laptop is a leak waiting for a taxi.
- **Recovery key escrow** off the machine itself, in the corporate manager.
- **Automatic screen lock** with a short timer and lock on closing the lid.
- ***Phishing*-resistant MFA** (FIDO2/WebAuthn) on the corporate account, the operating system
  account and the version control and cloud ones. **SMS and TOTP are not equivalent**: the
  criterion and its rollout belong to `identity-access-management-standards`.
- **Automatic system and browser updates**, with an agreed maximum window for reboots.
  **Postponing indefinitely is forbidden**: it is the cheapest vulnerability to close and the most
  deferred.
- **Everyday account without permanent administrative privileges**; ad-hoc elevation.
- **Encrypted backup of the irreplaceable** (`backup-recovery-standards`).

### 5.2 SSH and signing keys: in hardware

- **The private key must not be copyable.** With a key in a file, a single piece of malware — or
  an editor extension, §5.6 — exfiltrates it without a trace and without anyone noticing until it
  is used.
- **FIDO2-backed SSH keys, verified status**: OpenSSH added support in **8.2 (14 Feb 2020)** with
  the key types **`ecdsa-sk`** and **`ed25519-sk`**. Verbatim from that release's notes: *"This
  release adds support for FIDO/U2F hardware authenticators to OpenSSH... In OpenSSH FIDO devices
  are supported by new public key types 'ecdsa-sk' and 'ed25519-sk'"* and *"FIDO tokens also
  generally require the user explicitly authorise operations by touching or tapping them."*
  Relevant options and **the version they appeared in**:
  - `-O resident` — key resident on the token, recoverable on a new machine: **8.2**.
  - `-O verify-required` — requires a **PIN** in addition to the touch: **8.4** (`authorized_keys`
    accepts `verify-required` from the same version).
  - `no-touch-required` — **relaxes** the touch requirement: **8.2**. **Used only with a written
    reason**; the touch is precisely the defence against silent use of the key by malware with
    access to the agent.
  - Verified current version reference: **OpenSSH 10.4 / 10.4p1 (6 Jul 2026)**.
  - **`ed25519-sk` is not supported by every token**; `ecdsa-sk` is the more universal fallback.
    It is checked **before** buying the hardware, not after.
- **Two tokens, always.** A primary one and a backup one registered on the same services, kept
  somewhere else. **A single token is a single point of failure shaped like a keyring**, and the
  day it is lost you cannot get in to fix anything.
- ***Commit* signing with a key in hardware**: Git supports SSH signing since **2.34** — verbatim
  from its release notes: *"In addition to GnuPG, ssh public crypto can be used for object and
  push-cert signing. Note that this feature cannot be used with ssh-keygen from OpenSSH 8.7, whose
  support for it is broken. Avoid using it unless you update to OpenSSH 8.8."* Configuration:
  `gpg.format = ssh` + `user.signingkey` pointing at the token's **public** key. **The policy of
  requiring signatures belongs to `git-workflow-standards`; here only that the key is in
  hardware.** Operational detail that makes verification fail on GitHub: the key must be added
  **as a signing key**, not (only) as an authentication key — they are two different entries even
  though it is the same material.
- **Keyless alternative for automation**: `gitsign` (Sigstore) signs with an ephemeral OIDC
  identity and a transparency log. **It is not a substitute** for the hardware key in daily human
  work, and **GitHub does not display its signatures as "Verified"** the way it does SSH or GPG
  ones: it is a different posture, verifiable with its own tool. Verify status (§8).
- **GPG**: if used, on a smart card (OpenPGP card / YubiKey), never in a file.
- **The agent**: `ssh-agent` with a bounded lifetime and **no agent forwarding** by default
  (`ForwardAgent`). Forwarding the agent to a host is giving that host the use of your keys for as
  long as the session lasts; if it is unavoidable, `ProxyJump` instead.

### 5.3 Credentials: where they CANNOT be

**FORBIDDEN, with no exceptions and no "it's temporary":**

- ❌ **Token in `~/.netrc` or `_netrc`.** Plain text, read by a multitude of tools, with no scope
  and no expiry.
- ❌ **`git config credential.helper store`.** Its own documentation says it verbatim:
  *"Using this helper will store your passwords unencrypted on disk, protected only by
  filesystem permissions."* Alternatives the documentation itself points to: `cache` (memory,
  ephemeral) or a helper integrated with the operating system's secure store.
- ❌ **Secrets in versioned *shell* configuration files** (`.zshrc`, `.bashrc`, `.profile`). It is
  the classic leak: the *dotfiles* repository goes public one Tuesday.
- ❌ **Secrets in the *shell* history.** An `export TOKEN=...` or a `curl -H "Authorization: ..."`
  stays in `~/.zsh_history` forever. Minimum mitigation: leading space with
  `HIST_IGNORE_SPACE`/`HISTCONTROL=ignorespace`, and **read the secret from a file or from the
  manager, never write it on the command line**.
- ❌ **Secrets in global, permanent environment variables.** Every child process sees them: the
  coding agent, the *linter*, the editor plugin, a dependency's `postinstall` script. **Scope is
  bounded per project and per session.**
- ❌ **A real `.env` outside the `.gitignore`**, or a `.env.example` carrying real values.

**What you do instead**: the secrets manager and the scanner — including their selection — belong
to `secrets-management-standards`. **This skill's own criterion is about location and timing**:
credentials in the system keychain or in the manager; **short-lived and with minimum scope** (OIDC
instead of static tokens whenever it exists); and **injected into the process that needs them,
when it needs them**.

**Secret scanning before the *commit*, not after.** A secret that reaches Git history **is already
compromised**: rewriting history does not dislodge it from clones, *forks*, CI *runners* or
caches. The only correct response to an already-pushed secret is **rotating it**. That is why the
local pre-commit *hook* is mandatory, **and server-side scanning too** — the local *hook* is
skipped with `--no-verify` and **it will be skipped**. The specific tool is chosen by
`secrets-management-standards`.

### 5.4 `curl | sh`: the same risk that is forbidden in CI

**The whole argument fits in one sentence**: *running a remote script without pinning a version or
verifying provenance is exactly what `cicd-standards` forbids in the pipeline — and there are more
credentials on the workstation than on the runner*. Whoever requires digest pinning and signature
verification in CI and then installs their toolchain with `curl | sh` does not have a supply chain
policy: they have one for other people's machines.

The failure modes, concretely:
- **The server serves what it wants, to whom it wants.** The URL's content is neither pinned nor
  signed, and it can change between two runs without anyone noticing.
- **Pipe detection**: the server can detect that it is being piped into `sh` — through the
  interpreter's read backpressure — and **serve different content** from what you would get by
  downloading it to read it. That is: **inspecting the URL in a browser proves nothing.**
- **Partial execution**: a network drop halfway leaves the system in an undefined state, with half
  the script executed.
- ⚠ **A `sha256` published on the same origin as the script adds almost nothing**: whoever
  controls the origin controls both. What does add value is a **signature** (Sigstore/cosign, the
  vendor's GPG) verified against a key known through another channel.

**Criterion, in order of preference**:
1. **System package manager package** (Homebrew, `winget`, the distribution, Nix). It is the
   default option and the one that almost always exists.
2. **Versioned artifact with a verified signature** (or, failing that, with a *checksum* obtained
   through a different channel), pinned to a **specific version**, never to `latest`/`master`.
3. **Script downloaded to a file, read and pinned by version**, then executed. It is not
   equivalent to point 2, but it is honest.
4. Blind `curl | sh`: **FORBIDDEN** (§7).

### 5.5 Automatic execution of project configuration

**Cloning a repository should not execute anything. In practice, it executes quite a lot.**

- **`direnv`**: `.envrc` is **arbitrary shell code** that runs on entering the directory. That it
  requires `direnv allow` is the defence, and **it works only if the file is read before
  authorising it**. Authorising by reflex is worse than not having `direnv`, because it also gives
  a sense of control. **It is re-authorised and re-read on every change to the file.**
- **`.vscode/tasks.json` and `settings.json` from someone else's repository**: they can point at
  interpreters, formatters and binaries **inside the repository itself**, which the editor will
  execute. Opening an unknown repository in the work editor is a security decision. **Workspace
  trust modes are used; they are not disabled because they are annoying.**
- **Dependency life cycle scripts** (npm's `postinstall` and equivalents) run on install. Hardening
  the installer belongs to the language skill (`frontend-web-platform-standards`,
  `python-standards`…); **here the rule is that the first `install` of an unknown repository is
  not done on the work machine**, but in a container or a disposable VM.
- **The repository's Git *hooks*** do not run by themselves on clone, but any tool that installs
  them does activate them. They are reviewed the same way.
- **Rule that solves 90% of the cases**: **untrusted repository → disposable container or Dev
  Container, never the host.** And the container **without** mounting `~/.ssh`, or the keychain, or
  the agent socket.

### 5.6 Editor extensions and *shell* plugins: third-party code with your permissions

**An editor extension runs with the user's permissions, with no meaningful isolation, with access
to the code, to `~/.ssh`, to the environment variables and to the network, and with automatic
updates.** In attack surface terms it is equivalent to installing a stranger's binary and giving
it permission to update itself. **There are documented and recent incidents** — this is not
theory:

- **GlassWorm** (initially documented by Koi Security in **Oct 2025**, with later waves): a family
  of **self-propagating** malware in editor extensions, present both on **Open VSX** and on the
  Visual Studio Marketplace. It uses **invisible Unicode characters** to hide the malicious code
  from view in the editor. It steals npm, GitHub, Open VSX and Git credentials to **compromise
  more packages** — each victim is a new infection vector —, drains cryptocurrency wallets and
  turns the machine into proxy infrastructure. Verbatim from the March 2026 coverage: *"Socket
  said it discovered at least 72 additional malicious Open VSX extensions since January 31, 2026,
  targeting developers"*, and it abuses `extensionPack` / `extensionDependencies` so that an
  innocent-looking package **later pulls in** the malicious extension, once trust has been won.
  The lures imitate *linters*, formatters and **AI coding assistants**.
- **GitHub, May 2026 — the case that closes the debate**: a compromised version of **Nx Console**
  (`nrwl.angular-console` v18.95.0), an extension with **more than 2 million installations**, was
  published on the Marketplace using stolen publishing credentials. A **single workstation**
  belonging to a GitHub employee, with automatic extension updates enabled, was compromised; from
  the tokens, secrets and **SSH keys** collected from that machine, the attacker exfiltrated
  **~3,800 internal GitHub repositories**. GitHub publicly confirmed the access on **19 May 2026**.
  **The whole chain — extension → workstation → internal repositories — is exactly the threat
  model of this section.**
- Other cases from the period reported by the specialist press: AI-branded extensions with ~1.5M
  cumulative installations capturing files and code modifications (Jan 2026), and infostealers
  published in Microsoft's registry (Dec 2025).

**Hard rules, and they are uncomfortable on purpose**:
- **Inventory of installed extensions, reviewed.** What is not used gets uninstalled: every
  extension is permanent surface.
- **They are installed out of a concrete need, not out of discovery.** Before installing: who
  publishes it, how long it has been around, what permissions it asks for, and whether it does
  something the editor already does.
- **Popularity is no guarantee**: Nx Console had millions of installations. **The download count
  can be inflated and the legitimate publisher's account can be stolen** — which is exactly what
  happened.
- ⚠ **Automatic extension updating is the vector.** In GitHub's case, the machine was compromised
  because the extension **updated itself** to the malicious version during a window of ~11
  minutes. **Criterion**: on machines with access to production or to private code, **disable
  automatic extension updates and update in batches after a waiting window**. It costs
  convenience; the alternative costs 3,800 repositories.
- **The same applies to *shell* plugins** (`oh-my-zsh` and its ecosystem, plugin managers,
  themes): they are **arbitrary shell that runs on every interactive session**, often installed
  with `curl | sh` (§5.4) and updated from `main`. **They are pinned by version or they are not
  installed.** A pretty prompt theme does not justify permanent remote execution.
- **The same rule for version manager plugins** (§2.1): that is why `mise` has stopped accepting
  `asdf` plugins in its registry.
- **On suspicion that an extension is compromised, the response is to rotate**, not to uninstall:
  every token, secret and **SSH key that was on disk** is assumed compromised. The keys that lived
  in hardware (§5.2) are precisely the ones that do **not** have to be rotated. That is the whole
  argument in favour of the token, summarised.

### 5.7 Coding agents on the workstation

The working **process** with agents belongs to `ai-agent-workflow-standards`, which **already
declares from its side that hardening the machine belongs here**. **Here only the hardening**, and
the framing is simple: **a coding agent is a local process that runs commands with the user's
permissions and with an input partly controlled by third parties** — the repository's content, a
tool's output, a web page, an API response. The threat model of §5.6 applies to it, not that of a
desktop tool.

- **Filesystem scope bounded to the project.** No access to the full home directory, and
  **explicitly no** `~/.ssh`, keychain, cloud configuration files (`~/.aws`, `~/.kube`,
  `~/.config/gcloud`) or the *dotfiles* repository.
- **Scoped, short-lived credentials**, injected into the agent's process and only into it.
  **Never** the long-lived personal credentials or the production ones.
- **Human approval for irreversible actions**: writing outside the project, `git push`, publishing
  packages, any command against real infrastructure, installing dependencies.
- **No production credentials on the workstation** (§7): this skill's general rule becomes
  critical when there is an autonomous process running commands.
- **Risky work goes in a disposable container**, not on the host — same criterion as §5.5 for
  untrusted repositories.
- **The agent's output is reviewed as third-party code**, with the same review as any PR
  (`code-review-standards`). Here all that matters is that **the agent is not an identity with
  trust of its own**.

## 6. Machine performance: the economic argument

**The developer's waiting time is opportunity cost, and it is the argument that wins budgets** —
but only if it is measured instead of felt.

**Method, and it must be done with your own data**:
1. **Measure**, do not estimate: incremental and clean *build* time, time of the test suite that
   runs before each *commit*, environment start-up time, editor indexing time.
2. **Multiply** by the real daily frequency (how many times a day a build actually happens) and by
   the number of people.
3. **Convert** to hours per year and value them with the team's internal cost.
4. **Compare** with the price of the hardware. If the calculation comes out in favour, it is not a
   comfort request: it is an investment with a calculated return, and that is how it is presented.

**This skill fixes no saving figures or multipliers** (§8): they circulate on the web with no
verifiable primary source. **The numbers come from your own machine and your own team.**

Concrete constraints that usually dominate:
- **RAM is the hard ceiling.** Once the system starts swapping to disk, everything else is
  irrelevant. An editor with indexing, a browser, containers and a local service compete for the
  same memory.
- **The disk**: NVMe SSD with **enough free space**. An almost-full disk degrades performance and
  **makes builds fail** in ways that look like a different problem for hours.
- **The CPU matters by cores for compilation** and by single-thread performance for everything
  else; it is not the same purchasing decision.
- ⚠ **Development containers outside Linux pay an I/O tax** on directories mounted from the host.
  It is the usual cause of a Dev Container "being slow". It is measured before blaming the tool;
  sometimes the solution is a native volume instead of a *bind mount*, and sometimes it is not
  using a container for that project.
- **The corporate antivirus scanning the *build* directory can double compilation time.** It is a
  real and frequent case. It is measured, and an exclusion is negotiated **with security**, with a
  bounded scope and in writing — **it is not disabled unilaterally** (§7).
- **Space hygiene**: dependency caches, container images and build artifacts grow without limit.
  Scheduled cleanup, not when the disk fills up at eleven at night.

## 7. Long-term sustainability and prohibitions

- **Workstation configuration is reviewed as code**: the team's *dotfiles*, in a repository, with
  review. A change to the shared *bootstrap* is an infrastructure change.
- **Cadence**: review the inventory of extensions and plugins **every quarter** (§5.6); review
  runtime versions whenever the *pipeline* changes; rebuild exercise at least with every
  onboarding (§4).
- **A new tool = a decision with a maintenance cost.** Every provisioning layer (`mise` + `direnv`
  + Nix + Dev Container at once) is one more thing that can break and one more piece of
  documentation that can go stale. **Climb the ladder in §2.2 only with a reason.**
- **Employee offboarding**: written procedure for withdrawing the machine — secure erasure, key
  revocation (including hardware keys registered with services) and rotation of anything it could
  have touched. It belongs to `identity-access-management-standards`; **here the device part**.

Explicit prohibitions:

- ❌ **Installing with `curl | sh` without pinning a version or verifying provenance** (§5.4).
  **FORBIDDEN** to do it with administrator privileges (`curl ... | sudo sh`) under any
  circumstances.
- ❌ **An SSH or GPG private key in a file** on a machine with access to production or to private
  code, when hardware is available (§5.2).
- ❌ **A token in `~/.netrc`, in `credential.helper store`, in the versioned `.zshrc`/`.bashrc` or
  in the *shell* history** (§5.3).
- ❌ **Production data on the local machine.** Not a dump "for debugging", not a customer CSV, not
  a database replica with real data, not logs with personal data. A laptop does not have the
  access controls, encryption, logging or retention that datum requires — and losing it is a
  notifiable incident (`privacy-engineering-standards`, `grc-compliance-standards`). If debugging
  with real data is needed, it is debugged **where the data lives**, with audited access.
  **Anonymised or synthetic data for everything else.**
- ❌ **Long-lived production credentials on the workstation.** Ad-hoc, short-lived, audited access.
- ❌ **The work laptop as a server.** Nothing others need should depend on a machine that gets
  closed, carried in a backpack, updated and loses wifi: not a shared service, not a CI *runner*,
  not a tunnel others use, not a cron somebody is waiting on. A laptop has no availability, no
  redundancy, no maintenance window and no successor. It goes to `homelab-standards` (if it is
  personal) or to real infrastructure (if it is work). **A service whose owner goes on holiday
  with it in their backpack is not a service.**
- ❌ **Disabling disk encryption, the screen lock, the corporate antivirus or automatic updates**
  for convenience or performance. Performance exclusions are negotiated with security, with a
  bounded scope and in writing (§6).
- ❌ **Installing an editor extension without reviewing who publishes it**, or keeping automatic
  extension updates on a machine with access to production or to private code (§5.6).
- ❌ **`direnv allow` without having read the `.envrc`** (§5.5).
- ❌ **Opening an unknown repository in the work editor** or running its `install` on the host:
  disposable container (§5.5).
- ❌ **SSH agent forwarding (`ForwardAgent`) by default** (§5.2).
- ❌ **Two runtime version managers at once** (`mise` and `asdf`): their shell *hooks* conflict
  (§2.1).
- ❌ **A formatter or linter whose version is not pinned in the repository**, or that only exists
  in one person's editor configuration (§2.3).
- ❌ **An undocumented manual step in the provisioning.** If you have to ask somebody to set the
  machine up, the provisioning is broken (§4).
- ❌ **Giving a coding agent access to the full home directory, to `~/.ssh` or to the cloud
  credentials** (§5.7).
- ❌ **"It works on my machine" as a conclusion.** It is the statement of a provisioning failure,
  and it has an owner.

## 8. Mandatory web verification

Before fixing any datum of this document in a real team:

1. **Runtime version managers**: verified as of August 2026 — **`mise` v2026.8.1** (very high
   release cadence: **any version written here expires within days**) and **`asdf` v0.20.0**
   (7 Jul 2026), already rewritten in Go since **0.16.0**, which **removed `asdf global`,
   `asdf local` and `asdf shell`**. Confirm the status of the **withdrawal of `asdf` plugins**
   from `mise`'s registry (documented as a supply chain reason) and whether `asdf` has already
   implemented plugin version locking, which it **did not have**.
2. **Dev Containers**: verified — specification under **CC BY 4.0** (Microsoft), reference CLI
   `devcontainers/cli` under **MIT** and with recent activity (Jul 2026). **Check the feature
   parity** of the specific implementation you are going to use (VS Code, JetBrains, cloud
   service): **it is uneven between them** and that is where the time goes.
3. **OpenSSH and FIDO2 keys**: verified in the official notes — FIDO/U2F support since
   **8.2 (14 Feb 2020)** with `ecdsa-sk` and `ed25519-sk`; `-O resident` and `no-touch-required` in
   **8.2**; **`verify-required` (PIN) in 8.4**; verified current version **10.4 / 10.4p1
   (6 Jul 2026)**. Check whether the specific token supports `ed25519-sk` **before buying it**.
4. ***Commit* signing with SSH**: verified in the **Git 2.34** notes, including the verbatim
   warning that it **does not work with `ssh-keygen` from OpenSSH 8.7** and you have to be on
   8.8+. Git at 2.55.0 as of August 2026. Confirm in the *forge*'s documentation that the key must
   be registered **as a signing key**, not an authentication one, for verification to come out as
   valid.
5. ***Passkeys* and signing**: **declared gap**. As of August 2026 no standard mechanism for
   *commit* signing with discoverable *passkeys* equivalent to the `-sk` keys has been found; what
   is verified is that FIDO2-backed SSH keys are the mature route. `gitsign` (Sigstore) is a
   different posture — ephemeral OIDC identity with a transparency log — and **its signatures are
   not shown as "Verified"** on GitHub the way SSH/GPG ones are. Verify status and version before
   adopting it.
6. **Extension incidents — reconfirm before citing them**: the facts in §5.6 come from the
   specialist press and security vendor reports (Koi Security, Socket, Aikido) and **not from
   primary sources read in full in this verification**, except GitHub's public confirmation of
   **19 May 2026**. Data to reconfirm: the figure of **≥72 malicious Open VSX extensions since
   31 Jan 2026** (Socket, verbatim in the coverage), the **~3,800 internal GitHub repositories**,
   the version **`nrwl.angular-console` 18.95.0** and the exposure window of **~11 minutes**.
   **Also check whether there are new incidents**: the cadence of this vector in 2025-2026 makes
   it foreseeable that there are.
7. **Licences verified in the raw `LICENSE` as of August 2026**: Homebrew **BSD-2-Clause**,
   `winget-cli` **MIT**, `mise` **MIT**, `asdf` **MIT**, `direnv` **MIT**, `devenv`
   **Apache-2.0**, `devcontainers/cli` **MIT**. **`chezmoi` remains unverified in this pass**:
   read its raw `LICENSE` before fixing it (§2.1). Remember that **the GitHub releases feed is not
   the source of truth**: cross-check with the project's official site, which in several cases in
   the catalogue publishes in another registry.
8. **`git credential-store`**: the warning quoted is verbatim from its official documentation
   (*"store your passwords unencrypted on disk, protected only by filesystem permissions"*).
   Check which helper integrated with the operating system's secure store is available on the
   specific platform.
9. **Declared gap — productivity figures**: this document **fixes** no number of hours saved, of
   return per gigabyte of RAM or of context switching cost. Many circulate and **no verifiable
   primary source has been found**. The calculation in §6 is done with your own measurements or it
   is not done.
10. **Declared gap — rebuild time target**: no number is fixed here ("machine operational in N
    hours"). It is agreed per team from the first real measurement (§4); the criterion that does
    belong to this skill is **binary** (can you build, test and deploy when you finish?).

If the web contradicts this document, **the web wins** — flag the discrepancy.
