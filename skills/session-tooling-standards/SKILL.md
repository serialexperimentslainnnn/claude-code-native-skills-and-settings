---
name: session-tooling-standards
description: Use BEFORE creating or using `.claudetools/`, the project directory where a session leaves its own scripts — gathering commands, index generators, checkers. Carries the gate (every exclusion file must already list it, added before the directory exists), the placement rule (a tool's path mirrors the code scope it covers, so the location is derivable and nobody spends an `ls`), the prohibition on any secret inside, and the rule that it stores tooling and never notes or state. Also use when deciding whether a piece of work should leave something executable behind.
---

# Session tooling standards — the workshop is derivable, ignored, and free of secrets

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

> **Hard premise**: a session that solved something and left nothing executable behind makes the next
> session pay for it again. The workshop exists so that what cost thinking through once is
> **runnable** the next time — but a directory that is ignored by git invites exactly the two
> failures it must never have: a secret written into it because "nobody sees it", and a layout only
> its author can navigate.

## 1. Scope and triggers

Applies **before `.claudetools/` is created or used**, and every time a piece of work could leave
something executable behind: a composed gathering command that worked, an index generator, a
checker, a one-off script that will be wanted again.

**The trigger is the intent, not the file.** "I am about to re-type that `git ls-files | grep`
one-liner" is the trigger. So is "I need to check whether a tool already exists for this
directory" — because §3 answers that without a search.

**Not applicable**: `secrets-management-standards` owns **how a secret is stored, rotated and
injected**; here only that none of it may land in this directory and why being ignored is not being
protected. `project-map` owns **`PROJECTMAP.md`**, the distributed index of where things are; here
the executable counterpart, and §3 borrows its mirror-the-tree principle deliberately. The
**language skills** own how the script itself is written — idiom, shebang, error handling, linting;
here only where it lives and what it may contain. `cicd-standards` owns **checks that gate a
merge**; a tool here is a convenience, never a gate, and promoting one into CI moves it out of this
directory and under that skill. `lean-code-standards` owns whether the script should have been
written at all.

## 2. Default decisions — the tie-breakers

| Decision | Rule | Why |
|---|---|---|
| Order of operations | **Exclusions first, directory second.** Never the reverse, never "I'll add it after" | One `git add -A` in between and the workshop is in the history; getting it out is a rewrite |
| Exclusion missing | **Add it, then create the directory.** If the project forbids touching its exclusion files, work without the workshop and say so | `.gitignore` is a shared root file; changing one in someone else's repo is a change they did not ask for |
| Where a tool goes | **The path mirrors the code scope it covers** (§3) | Makes the location derivable instead of discoverable — no `ls`, no `find`, no exploration round |
| Build a tool, or retype the command | **Build it.** Creating tooling is the default, not an initiative | The toll is paid once; retyping is paid every session |
| Sensitive data inside | **Never, under any reading** (§5) | Ignored ≠ protected: it is on disk, in backups, in any tarball |
| Notes, state, findings, scratch output | **Forbidden.** It stores tooling, never prose | Findings go in the answer or in the documents that hold state; a file here that is not tooling is litter the next reader must classify |
| Cleanup at end of turn | **It is not scratch. It is not swept.** | The "leave nothing behind" rule covers residue; this is a project asset, and saying so is what stops the next session deleting it while believing it complies |

**The gate, literally.** Before the directory is created *or used*: `.claudetools/` must already be
listed in `.gitignore` **and in every other exclusion file the project has** — `.npmignore`,
`.dockerignore`, `.eslintignore`, `.prettierignore`, `.helmignore`, `.vercelignore`, `MANIFEST.in`,
whatever is present. Anchor the rule to the root (`/.claudetools/`), because an unanchored pattern
also matches any directory of that name deeper in the tree.

## 3. Placement — the path mirrors the scope, so the location is derivable

**A tool lives at the same path under `.claudetools/` as the code it covers.**

| The tool covers | It lives at |
|---|---|
| `skills/project-map/` | `.claudetools/skills/project-map/` |
| `skills/` as a whole | `.claudetools/skills/` |
| `src/api/` | `.claudetools/src/api/` |
| the whole repository | `.claudetools/` root |

**The mechanism is the whole point: derivable beats discoverable.** Working inside a directory, you
already know the one path its tooling would be at, so you **never spend an `ls`, a `find` or a round
of exploration** to learn whether one exists — you read the single path the scope implies, and an
empty answer is itself the answer, arrived at in one call. The alternative is a flat directory of
names nobody can predict, which forces reading the **whole** workshop to find the one script that
applies: the exact cost the distributed `PROJECTMAP.md` exists to remove, re-created in the tooling
layer.

**So the scope of a tool is a decision taken before writing it, not an afterthought:**

- **Place it at the deepest directory that contains everything it touches.** A tool that reads only
  `skills/*/SKILL.md` frontmatter belongs at `.claudetools/skills/`, not at the root — putting it
  higher makes it invisible from the subdirectory it serves.
- **A tool that would need two unrelated paths is two tools**, or its scope was drawn wrong. Do not
  place it at the common ancestor to make one file work: that pushes it up to a level where nobody
  looking for it will be.
- **Mirror the tree, never invent a parallel taxonomy.** No `.claudetools/scripts/`,
  `.claudetools/utils/`, `.claudetools/misc/` — a category directory is unpredictable by
  construction, which is the property being eliminated.
- **The path is the scope, so it is also the boundary.** A tool under `.claudetools/src/api/` that
  starts reading `src/core/` has outgrown its location; it moves, it does not stay and reach.

**This is what may be assumed without checking**: that if tooling for a given scope exists, it is at
the mirrored path, and that nothing relevant to that scope is hidden elsewhere. That assumption is
only safe because placement is a rule rather than a habit — a single tool filed by convenience
breaks it for every session afterwards, silently. **Placement is also what replaces announcing a
tool**: nobody has to be told it exists if its location was derivable before it was written.

## 4. Verification — how it is checked, not how it feels

- **The gate**: `grep -n 'claudetools' .gitignore` and every other exclusion file present in the
  tree — before creating anything. Absent → add it first, or do without the workshop.
- **Nothing is tracked**: `git status --porcelain --ignored=no | grep claudetools` must return
  nothing, and `git log --all --oneline -- '.claudetools/*'` must be empty. The second is the one
  that matters: it catches the failure the gate exists to prevent, after the fact.
- **Placement**: for a tool at `.claudetools/<p>`, the code it reads must live under `<p>`. Check
  the paths the script actually opens, not the ones its name implies.
- **No secrets**: the whole directory is greppable and small; read it. A scanner is not required to
  notice a token in a file you can `cat` in full.
- **It runs**: a tool that has never been executed since the tree changed under it is a claim. Run
  it before recommending it or quoting its output.

## 5. Security — what is never negotiable here

**Never any of this inside, under any reading**: credentials, tokens, API keys, private keys,
cookies, session identifiers, internal hostnames or endpoints, database dumps, anything holding
personal data, or anything that could not be read aloud.

**Being ignored is not being protected**, and this is the misreading the directory invites. An
ignored file is still on disk with normal permissions, still enters every backup, still ships inside
any tarball or image built from the project directory, still gets read whole by the next `cat`, and
is still visible to every process running as that user. Git ignorance is a **convenience for
`git status`**, not a control.

**What a script needs, it reads at run time** — from the environment or from the secret manager —
and never from a literal in the file. → `secrets-management-standards`.

**Two more, both real for scripts written to be re-run later:**

- **Quote every expansion and never build a shell command out of a value read from the tree.** A
  filename is untrusted input; a repository can contain one with a space, a newline or a `;`.
- **A tool here reads and reports. It does not modify the repository, does not install anything on
  the host and does not reach the network** unless that is explicitly its purpose and it was
  authorised. A convenience script acquiring side effects is how state changes without anybody
  reviewing it — edits stay with `Read`/`Edit`/`Write`, which is what the user sees as a diff.

## 6. Performance and operability

- **One tool, one job, run in one call.** The reason the workshop exists is to collapse ten tool
  rounds into one; a script that itself needs three invocations to be useful has not paid for
  itself.
- **Output is machine-readable and complete** — one fact per line, greppable, no pagination and no
  truncation.
- **It fails loudly with a non-zero status and a reason on stderr.** A tool that exits 0 having
  found nothing because a path moved is worse than no tool: it reports absence as a fact.
- **It takes its root from the repository, not from the caller's working directory** — the cwd is
  not guaranteed to be where the script assumes.

## 7. Sustainability and prohibitions

- **Forbidden: using the directory before its exclusion exists.** Including "just to test".
- **Forbidden: anything that is not tooling.** No notes, no findings, no intermediate state, no
  scratch output. Executables and their fixtures, nothing else.
- **Forbidden: category directories** (`scripts/`, `utils/`, `misc/`) — see §3.
- **A tool that no longer matches the tree is deleted, not left "in case".** A stale tool is
  believed, exactly like a stale map.
- **The directory is not scratch and is never swept** by the end-of-turn cleanup. Everything else a
  turn produced outside the repository — temp directories, caches, artifacts — still is.
- **A tool worth keeping is worth running once more before it is trusted.** The moment it is quoted
  without being re-run, it has become documentation with the authority of an executable.

## 8. Mandatory web verification

Verify before committing to anything: the **exclusion files each ecosystem actually honours** and
their pattern syntax (`.gitignore`, `.dockerignore` — whose pattern semantics are *not* git's —
`.npmignore`, `.helmignore`, `.vercelignore`, `MANIFEST.in`, and whatever the project's own
toolchain adds), and the current behaviour of `git check-ignore` / `git status --ignored` used to
prove the rule bites. Ecosystems add exclusion files over time, and a rule written for the set that
existed last year silently stops covering the new one.

If this document contradicts the primary source or the live behaviour of the tool, **the web wins**.
