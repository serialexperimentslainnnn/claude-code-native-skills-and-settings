---
name: bash-linux-scripting-standards
description: Shell scripting and Linux automation standards. Use when writing or reviewing .sh/.bash/.zsh files, "#!/usr/bin/env bash" scripts, set -euo pipefail, shellcheck, shfmt, .shellcheckrc, .editorconfig shell rules, bats tests, getopts parsing, traps, mktemp, flock or POSIX sh portability.
---

# Shell scripting and Linux automation standards

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when writing, reviewing or refactoring shell: `.sh`, `.bash`, `.zsh` files, executables with a shell
shebang, `~/.bashrc`/`~/.zshrc` functions turned into tools, deployment wrappers, boot and maintenance
scripts, and any automation glued together with `bash` that already has users. Triggers:
`set -euo pipefail`, `shellcheck`, `shfmt`, `.shellcheckrc`, `bats`, `getopts`, `trap`, `mktemp`, `flock`,
`IFS`, "POSIX portability", "dry-run", "the script has grown huge".

Guiding principle: **bash is an excellent glue language and a terrible application language**. Its job is
to orchestrate processes and files; the moment data structures, concurrency, real parsing or business
logic show up, maintaining it costs more than rewriting it (§7, **rewrite threshold**). Write shell
assuming the script will live five years and someone will run it at 3 in the morning.

**Not applicable**: see `onprem-standards` (platform umbrella: systemd unit design,
inventory, fleet patching cadence — here only the script and its minimal wrapper),
`linux-hardening-standards` (CIS/STIG baseline, `sysctl`, auditd, sudoers, unit sandboxing
as a security control — here only script hygiene: `eval`, quoting, temporaries, `flock`),
`selinux-standards` (if the script fails because of an AVC denial, the diagnosis is there), `cicd-standards` (scripts embedded in
pipelines, runners, CI secrets and build gates), `python-standards` and `go-standards` (the natural
destination once the §7 threshold is crossed: Python for data-driven automation, Go for distributable
binaries with no dependencies), `ruby-standards` and `perl-standards` (alternative destination
for the growing script **only if the team already maintains them** — for new code, the default
destination is still Python or Go), `powershell-standards` (**reciprocal shell-choice
boundary**: in a Windows or mixed environment with AD, PowerShell wins —objects instead of text, without
POSIX's quoting and *word splitting* problem—; on Linux and in any script that must run
on a minimal system with no added dependencies, this skill wins. **Cross-platform is not a
sufficient argument for choosing PowerShell** if the real target is Linux only; it is if Windows
has to be administered).

## 2. Toolchain

> Verify the latest version on the web before pinning it in a real project (§8).

| Tool | Default | Reason / note |
|---|---|---|
| Interpreter | **bash 5.x**, shebang `#!/usr/bin/env bash` | 5.3 is the stable branch (Jul 2025; patches ongoing). Verified Aug 2026: Fedora 44 ships 5.3.x; **Debian stable is still on 5.2.x** → do not assume 5.3 on third-party targets |
| Strict mode | `set -Eeuo pipefail` + `IFS=$'\n\t'` + `shopt -s inherit_errexit` | With its known limits (§3); `-E` is essential for the ERR trap to work inside functions |
| Linter | **ShellCheck 0.11.x** (0.11.0, Aug 2025) with `.shellcheckrc` in the repo | A CI gate, not a suggestion. Recommended by the Google Shell Style Guide itself "for all your scripts, large or small" |
| Formatter | **shfmt 3.13.x** (3.13.1, Apr 2026) | Configured via `.editorconfig`; supports POSIX sh, bash, mksh and **zsh since 3.13.0** |
| Tests | **bats-core 1.14.x** (Jul 2026) | With `bats-support`/`bats-assert`; alternative: `shunit2` in environments that already use it |
| Style guide | **Google Shell Style Guide** (`google.github.io/styleguide/shellguide.html`) | The old `shell.xml` is deprecated. It is the reference with the most traction; its hard rules are captured here |
| Dialect | **bash exclusively**, unless portability is an explicit requirement | Google: restricting yourself to bash "means there is generally no need to look for POSIX compatibility or to avoid bashisms" |
| POSIX sh | `#!/bin/sh` + `shellcheck -s sh` **only** if the target demands it (initramfs, BusyBox, Alpine, `dash`, distroless images, multi-OS installers) | Current standard: **POSIX.1-2024 / Issue 8** (free text at `pubs.opengroup.org`) |
| Running scheduled tasks | systemd unit + timer (§6) | `cron` only in containers without systemd, BSD/macOS or legacy |

## 3. Structure and conventions

### Mandatory skeleton

```bash
#!/usr/bin/env bash
# What it does, what it assumes and who maintains it. One line, not a novel.
set -Eeuo pipefail
shopt -s inherit_errexit   # errexit also inside $( ); bash >= 4.4
IFS=$'\n\t'
SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_NAME SCRIPT_DIR   # separate from the assignment: SC2155
: "${LOG_LEVEL:=info}"            # configurable via the environment, with a default
DRY_RUN=false
WORKDIR=''
log() { printf '%s [%s] %s: %s\n' "$(date -u +%FT%TZ)" "$1" "$SCRIPT_NAME" "${*:2}" >&2; }
die() { log error "$*"; exit 1; }
cleanup() { local rc=$?; [[ -d "$WORKDIR" ]] && rm -rf -- "$WORKDIR"; exit "$rc"; }
trap cleanup EXIT
trap 'log error "failure in ${BASH_SOURCE[0]}:${LINENO} -> ${BASH_COMMAND}"' ERR

main() {
  WORKDIR="$(mktemp -d)"          # cleanup guaranteed by the EXIT trap
  ...
}
main "$@"
```

- **`main "$@"` at the end**: makes the file *sourceable* for tests and prevents partial execution if the
  download or the edit is truncated halfway through.
- Executables in `PATH` **without an extension**; **libraries with `.sh` and without the execute bit** (Google Shell
  Style Guide). `snake_case` for functions and locals, `UPPERCASE` only for constants and the environment.
- `local` for every variable inside functions, no exceptions; `readonly` for constants.

### Quoting, word splitting and globbing

- **Double-quote every expansion** (`"$var"`, `"${arr[@]}"`, `"$(cmd)"`), with the exception justified in a
  comment; `"${arr[@]}"` never `${arr[*]}` for lists. `IFS=$'\n\t'` reduces splitting, **it does not replace
  quoting**.
- `--` before positionals (`rm -rf -- "$dir"`) and `./` in front of globs (`rm -- ./*.log`): a file
  named `-rf` is a trivial exploit. To walk files, `find -print0` +
  `while IFS= read -r -d ''`, or globs with `shopt -s nullglob`; names with spaces, newlines and UTF-8
  are the norm, not a rare case.
- `[[ … ]]` preferred over `[`/`test` (no word splitting or globbing, with `=~`); arithmetic with `(( … ))`.
  They do not exist in POSIX sh: there it is `[ … ]` with everything quoted.

### Arguments, help and exit codes

- Parsing with **`getopts`** (built-in and portable). If long options, repeatable flags and
  subcommands are needed, that complexity **is already a threshold signal** (§7); if it stays in bash anyway, a
  `while [[ $# -gt 0 ]]` loop with `case`, without `getopt(1)` (divergent behaviour across systems).
- `usage()` is mandatory: synopsis, options, environment variables it reads, exit codes and **a real
  example**. To `stdout` with `exit 0` when requested with `-h`; to `stderr` with `exit 2` on a usage error.
- Exit codes: `0` success; `1` generic failure; **`2` usage error**; `3+` for documented business
  conditions. Respect `126`/`127` and `128+N`: a script that always exits `0` is undetectable from CI.
- **`stdout` for useful output, `stderr` for everything else**: that separation is what makes the script
  composable. Configuration: flag > environment > default; no paths or hostnames halfway through the code.

### Idempotence, `--dry-run`, temporaries and concurrency

- **Every script that modifies something must be runnable twice without harm**: check state before
  acting (`[[ -L $link ]]`, `id -u "$user" &>/dev/null`), use convergent operations (`mkdir -p`,
  `ln -sfn`, `install -D -m 0644`) and treat "already as it should be" as success, not as an error.
- **`--dry-run` in every destructive script**, with a single choke point — two different execution
  paths (real and "simulated") always diverge:

  ```bash
  run() { [[ "$DRY_RUN" == true ]] && { log info "DRY-RUN: $*"; return 0; }; "$@"; }
  ```
- Configuration files: write to a temporary, **validate** with the service's checker (`sshd -t`,
  `nginx -t`, `visudo -c`, `systemd-analyze verify`) and only then an atomic `mv` onto the target (same
  filesystem). Keep a timestamped previous copy.
- **`mktemp` always** (`mktemp -d` for directories). `/tmp/$$`, `/tmp/fixed-name` or `$RANDOM` are forbidden:
  race condition and symlink escalation. Cleanup goes **in the EXIT trap**, never at the end of the
  body — the script can die before getting there. One single `trap … EXIT` per script (the second replaces
  the first): centralise it in `cleanup()`.
- **`flock` for mutual exclusion** in every script that can overlap with itself (timer, cron, webhook):

  ```bash
  exec 9>"/run/lock/${SCRIPT_NAME}.lock" || die "cannot open the lock"
  flock -n 9 || { log info "another instance running; exiting"; exit 0; }
  ```
  With `-n` (fail fast) or `-w <seconds>`, **never** wait indefinitely; descriptor ≥ 9 and the file in
  `/run/lock` or `/run`, not in a shared `/tmp`. Under systemd it is enough that the unit does not allow overlap.
  Hand-written PID locks (`echo $$ > /var/run/x.pid`) are **forbidden**: they are not atomic and leave
  orphans after a `kill -9`.

### Logging, here-docs and pipelines

- Structured, stable format from the first version: `<ISO-8601 UTC timestamp> [level] script: message`
  to `stderr`; single-line JSON if the consumer is an aggregator. Levels `error|warn|info|debug` filtered
  by `LOG_LEVEL`; `-v` raises the level, `-q` lowers it.
- `set -x` **is not logging**: it is interactive debugging and **it leaks secrets**. Behind an explicit flag
  (`--debug`) and with `PS4='+ ${BASH_SOURCE[0]}:${LINENO}: '` so the trace is readable.
- Under systemd, writing to `stderr` already means writing to the journal: do not reinvent rotation or your own files.
- Here-doc **quoted** (`<<'EOF'`) by default: no expansion, no surprises; unquoted only when
  interpolation is wanted. **Never** build content that will be interpreted (SQL, another
  script) via here-doc by concatenating unescaped variables: that is injection by another name — pass the data via arguments,
  files or `stdin`.
- Process substitution (`< <(cmd)`, `diff <(a) <(b)`) so as not to lose variables in a subshell: the classic
  `cmd | while read` that "forgets" what was assigned is solved with `while read … < <(cmd)`. It is a pure bashism.
- Exit status in pipelines: `pipefail` is almost always enough; if you need the code of each stage,
  `PIPESTATUS` copied into an array **immediately** (it is overwritten by the next command).

### Privileges

- **The script does not run as root "because it is easier"**: check what it needs and fail clearly
  (`[[ $EUID -eq 0 ]] || die "requires root"`) or, better, run unprivileged and elevate only the
  specific commands with `sudo` (`sudo -n` when non-interactive, so it fails instead of hanging asking for a password)
  and a `sudoers` rule scoped to exact commands. `NOPASSWD: ALL` for a script is forbidden.
- Drop privileges for the real work: `runuser -u <user> -- cmd` or `setpriv`; under systemd,
  `User=`/`Group=` in the unit — let the service manager do the work (see `onprem-standards`).
- **SUID/SGID forbidden on shell scripts** (an explicit rule of the Google Shell Style Guide): the shell
  cannot be secured well enough. If privilege is needed: scoped `sudo` or a compiled binary.
- `umask 077` before creating any file with sensitive content.

## 4. Quality and CI gates

In order of increasing cost; the first three break the build:

1. **`shfmt -d -i 2 -ci -sr`** — fails if any file is unformatted; shared config in
   `.editorconfig` so editor and CI agree (`shfmt -l` already returns a non-zero status when it lists something).
2. **`shellcheck` over every script**, with `--severity=style` and `.shellcheckrc` in the repo; `-x` so
   it follows `source`, `-s bash`/`-s sh` according to the actual shebang. Suppressions **per line and justified**
   (`# shellcheck disable=SC2016  # literal pattern for sed`); real false positives (SC2016 in
   `sed`/`printf`/`find -exec sh -c`) are suppressed case by case, never by lowering the project's severity.
3. **Syntax and startup**: `bash -n` over each file and running `--help` (must exit `0`) in CI.
4. **Tests with `bats`**: happy path, **failure of each external dependency** (missing command, non-zero
   or empty output), invalid arguments (does it exit `2` with a message?) and **double execution** (idempotence). Isolate with
   `PATH` pointing at *stubs*; do not touch the real system. Every fixed bug leaves a regression test.
5. **Test on the target interpreter**: if it is going to Debian stable or an Alpine image, it is run there in
   CI. `${var,,}` and associative arrays do not exist in `dash`, and bash 5.3 is not everywhere.

Definition of *done* for a script: it passes shfmt + shellcheck with no unjustified suppressions, it has `usage()`,
documented exit codes, cleanup via trap, tests for edges, and it has actually been run on the target.

## 5. Security

- **`eval` forbidden**, with no practical exceptions: almost everything is solved with arrays
  (`cmd=(rsync -a "$src" "$dst"); "${cmd[@]}"`), with `declare -n` or with a function. Same rule for its
  cousins (`bash -c "$var"`, `source "$var"`, `ssh host "$built_cmd"`, `find -exec sh -c "…$var…"`):
  building commands by concatenating strings **is command injection**; use arrays and `--` to separate data
  from options. If there really is no alternative, it is justified in the PR and the input goes against an allowlist.
- **Parsing the output of `ls` is forbidden** (and that of `df`, `ps`, `stat` in human-readable format): its format is not a
  contract and it breaks with odd names and different locales. Use globs, `find -print0` or `stat --format`.
- **`curl | bash` forbidden**, both in the script and in the instructions you give the user: download to a file,
  verify signature or checksum, review, run. Downloads with `--fail --proto '=https' --tlsv1.2`; never `-k`.
- **Secrets**: never in the code, in command arguments (visible in `ps` to the whole machine) or in the
  log. Via an environment variable injected by the secrets manager, via a `0600` file or via `stdin`; under
  systemd, `LoadCredential=`. If the script dumps its configuration, redact them.
- Explicit `PATH` at the start of privileged or boot scripts; do not trust the inherited one. Check
  dependencies at startup (`command -v jq >/dev/null || die "jq missing"`) instead of failing halfway.
- Validate all external input (arguments, environment, files, HTTP responses) against the expected pattern
  before using it in a path, command or comparison; in paths, reject `..` and absolute ones where you expect
  relative ones.
- `rm -rf` with a variable: check first that it is **not empty** and that it points where you think
  (`[[ -n "$dir" && "$dir" == /srv/app/* ]]`). `rm -rf "$PREFIX/"` with an empty `PREFIX` has wiped out entire
  production systems.
- Working files with minimal permissions (`umask 077`, `install -m 0600`); never `chmod 777` "just to test".

## 6. Operability

### Scheduled execution: systemd units versus cron

- **Default with systemd**: a `Type=oneshot` unit + `.timer`. Advantages over cron: journal with metadata,
  `OnFailure=` to alert, resource limits and sandboxing, real dependencies, `Persistent=true` to
  recover missed runs and **`RandomizedDelaySec=`** to spread out the fleet (if 50 machines renew
  certificates at the same time, the problem is yours and your provider's). Validate before deploying with
  `systemd-analyze calendar '<expr>'` and `systemd-analyze verify`.
- **`cron` only** in containers without systemd, BSD/macOS or legacy; and then: explicit `PATH`, output to a
  real log (not to local mail), mandatory `flock` and manual jitter.
- Verified Aug 2026: **systemd 259** on Fedora 44, with support for SysV init scripts **deprecated and
  removal announced for v260** — migrate any `/etc/init.d/` of your own now. Unit design
  (sandboxing, `ProtectSystem=`, `DynamicUser=`) is the subject of `onprem-standards`.

### Signals and orderly shutdown

- Long-running script: `trap 'on_term' TERM INT` to shut down in an orderly way (finish the work in
  progress, release the lock, delete temporaries) and exit with `128+N`.
- Children must die with the parent: save the PIDs and kill them in `cleanup`, or run under systemd, which kills
  the whole cgroup — that is the operational reason to prefer the unit. If shutting down takes time, raise it in
  `TimeoutStopSec`; otherwise `SIGKILL` will arrive and leave the state half-done.
- **`timeout` on every network operation** (`timeout 30 curl …`, `curl --max-time`); retries with backoff
  only on idempotent operations and with a cap. An `until` loop with no limit is an incident with an open date.

### Performance

- The dominant cost is **forking**: no five-process pipelines per line of file. Parameter
  expansion (`${var%%…}`, `${var/…/…}`) instead of `sed`/`cut` for trivial things, and a single-pass `awk` where
  you were going to put a loop. Never `for line in $(cat f)`: `while IFS= read -r line; do … done < f`.
- bash 5.3 adds command substitution **without forking** (`${ cmd; }` and `${| cmd; }`, result in `REPLY`):
  useful, but **they break on 5.2 and earlier** — only with a verified 5.3+ target.
- If performance really matters, the answer is in §7: it is not a problem of optimising bash, it is a
  language problem.

## 7. Sustainability, rewrite threshold and prohibitions

### REWRITE THRESHOLD

Hard rule from the Google Shell Style Guide: shell only for *"small utilities or simple wrapper scripts"*, and
a script of more than **100 lines or with non-trivial control flow is rewritten in a more
structured language *now*** — not "when there is time". This document adopts it and adds the triggers that in
practice arrive before the line counter does. **One alone is enough**:

- **Data structures** beyond flat and associative arrays: records, nesting, JSON that is manipulated
  rather than just having a field extracted with `jq`.
- **Real error handling** (distinguishing failure types, retrying by class, partially undoing) or
  controlled **concurrency**: `wait -n` and `xargs -P` cover the trivial case and nothing more.
- **Parsing** (not extracting): formats with escapes, CSV with quotes, HTML, output meant for humans.
- **Unit tests of internal logic**, not of a command's observable behaviour.
- More than **a dozen options**, subcommands or file-based configuration; or it is going to be a **dependency of
  other teams** / distributed outside the machine where it was born.
- It has **three incidents** attributable to shell behaviour (quoting, globbing, exit code).

Destination: **Python** (`python-standards`) for automation with data, APIs and logic; **Go**
(`go-standards`) for a single binary with no dependencies on the target. Migrate in parts: the script
remains a thin wrapper while the logic moves out, and it is retired when it no longer adds anything.

### Cadence and maintenance

- Pin the minimum bash version in the repo and **check it in the script** if you use modern features
  (`(( BASH_VERSINFO[0] >= 5 )) || die "requires bash 5+"`): cheaper than a silent failure on the
  old server.
- Update ShellCheck and shfmt along with the rest of the tooling (at least twice a year) and **pin the version in CI**: each
  release adds checks that find real bugs.
- Scripts expire: review annually which ones are not being run and delete them. A dead script in `PATH` is
  a trap.

**FORBIDDEN**
- ❌ A script without `set -euo pipefail` (or without written justification), and unquoted expansions (`$var`,
  `${arr[*]}`, bare `$(cmd)`).
- ❌ `eval`, `bash -c "$var"`, uncontrolled `source "$var"`, or commands built by concatenating strings.
- ❌ Parsing the output of `ls` or of any human-oriented output to obtain file names.
- ❌ `curl … | bash`, downloads without verifying checksum/signature, or `curl -k`/`--insecure`.
- ❌ Predictable temporaries (`/tmp/foo`, `/tmp/$$`) instead of `mktemp`; cleanup outside the EXIT trap.
- ❌ A script that can overlap with itself without `flock` or equivalent; hand-written PID files.
- ❌ SUID/SGID on a shell script; `sudo` with `NOPASSWD: ALL` for automation.
- ❌ Secrets in the code, in command arguments or in logs; `set -x` without an explicit flag.
- ❌ `rm -rf` on a variable without checking that it is not empty and that it points to the expected prefix.
- ❌ Always exiting with `0`; reusing `126`, `127` or `128+N`; mixing useful output and logs on `stdout`.
- ❌ A destructive script without `--dry-run`, or with different execution paths for real and simulated.
- ❌ A network operation without a timeout, or retries with no cap and no backoff.
- ❌ Bashisms with a `#!/bin/sh` shebang (and vice versa), or options in the shebang (`#!/bin/bash -e`): they are
  ignored when invoking `bash script`, they go in `set`.
- ❌ New SysV init scripts in `/etc/init.d/` (deprecated, removal planned in systemd 260).
- ❌ Suppressing ShellCheck codes globally without a comment justifying it.
- ❌ Growing a script that has already crossed the rewrite threshold "because rewriting it takes time".

## 8. Mandatory web verification

Before pinning any version, flag or behaviour, **look it up — do not recall it**:

1. **bash version on the real target** (not on your laptop) and its patch level: `ftp.gnu.org/gnu/bash/` and the
   distro package. Verified Aug 2026: stable branch **5.3** (Jul 2025) with patches ongoing; Fedora 44
   ships 5.3.x, **Debian stable is still on 5.2.x**. The funsubs `${ cmd; }` are 5.3+.
2. **ShellCheck** and **shfmt** (`github.com/mvdan/sh/releases`), with their new codes and flags. Verified
   Aug 2026: ShellCheck **0.11.0** (Aug 2025), shfmt **v3.13.1** (Apr 2026, zsh since 3.13.0), bats-core
   **1.14.0** (Jul 2026). Distro packages lag behind: pin the version in CI.
3. **Google Shell Style Guide** at `google.github.io/styleguide/shellguide.html`: it is updated by commits,
   with no dated editions; the old `shell.xml` is deprecated.
4. **POSIX** if you write portable `sh`: current edition **POSIX.1-2024 (Issue 8)**, free text at
   `pubs.opengroup.org` (Shell Command Language), with a first technical corrigendum in progress. Verify there
   what is standard and what is a bashism, not from memory.
5. **systemd**: version on the target and changes that affect you (verified Aug 2026: **259** on Fedora 44;
   SysV deprecated with removal announced for **260**, which raises the minimum dependencies). Check the repo's `NEWS`
   before using a recent directive.
6. **CVEs** of the utilities you invoke with privileges (`sudo`, `util-linux`/`flock`, `tar`, `curl`).

If the web contradicts this document, **the web wins** — flag the discrepancy.
