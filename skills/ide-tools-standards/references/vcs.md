# `vcs` — Git and the forge through the IDE

Examples are the last step of the ladder, as `vcs ▸ tool {args}`. Push, tags and pull requests
stay the maintainer's call: the tool exists, the decision does not move.

## git · git_write · forge

| Tool | Capability | When · example |
|---|---|---|
| `git_status` | The working tree as the Changes view sees it: branch, HEAD, upstream, ahead/behind, every changed path with its type. | Before staging or committing, and before any claim about the tree. `vcs ▸ git_status {}` |
| `git_log` | Recent commits with hash, subject, author, date and files; one or several `hashes` with their paths; `all_branches`. | "what changed lately", "what did commit X touch". `vcs ▸ git_log {hashes: ["5db1226"]}` |
| `git_diff` | The unified diff of the uncommitted changes: whole tree, one path, or several. | Reviewing before a commit. `vcs ▸ git_diff {paths: ["A.kt"], max_lines: 200}` |
| `git_branches` | Every local and remote branch with its commit, current first. | "which branches exist". `vcs ▸ git_branches {}` |
| `git_stage` *mutates* | Stages (`add`) or unstages (`reset`) paths through the IDE's Git. | Only the paths touched, never blind. `vcs ▸ git_stage {action: "add", paths: ["A.kt"]}` |
| `git_commit` *mutates* | Commits what is staged, or only `paths`; signing and hooks as the user's Git configures them. | One commit per logical unit. `vcs ▸ git_commit {message: "fix(x): …", paths: ["A.kt"]}` |
| `git_branch` *mutates* | Creates a branch or checks one out (`start_point` creates it there). Deleting is the user's. | "start a branch for". `vcs ▸ git_branch {action: "checkout", name: "feature/x", start_point: "develop"}` |
| `git_remote` *mutates* | Fetch, pull or push with the IDE's credentials; returns upstream and ahead/behind. Push is the maintainer's call. | "fetch". `vcs ▸ git_remote {action: "fetch"}` |
| `vcs_open` | Shows a VCS view: the Git log (at a `hash`, or only a `range` such as `v5.8.1..HEAD`), a file's history, the Commit window, or the pull-requests view. | "open the log", "compare the branch with the last release". `vcs ▸ vcs_open {view: "log", range: "v5.8.1..HEAD"}` |
| `pull_requests` | The GitHub repository's pull requests through the IDE's account: number, title, state, draft, author, updated, url; `state` open/closed/merged/all. The Pull Requests view is shown. | "what PRs are open". `vcs ▸ pull_requests {state: "open"}` |
| `pull_request` | One pull request by number with base, head, review decision and body; `open` shows the view and opens it in the browser. | "show me #42". `vcs ▸ pull_request {number: 42, open: true}` |
| `vcs_action` *mutates* | Every entry of the Git menu and its GitHub/GitLab submenus by name: pull, push, fetch, merge, rebase (+abort/continue/skip), cherry-pick continue/abort, revert_abort, branches, new_branch, rename_branch, compare_with_branch, stash, unstash, stash_silently, show_stash, shelve, show_shelf, rollback, annotate, compare_same_version, file_history, tag, reset, resolve_conflicts, commit, update, unshallow, worktrees, new_worktree, configure_remotes, clone, init, create_pull_request, pull_requests, share_on_github, clone_github, sync_fork, create_gist, github_accounts, create_merge_request, merge_requests, clone_gitlab, create_snippet, gitlab_accounts; `path` or `hash` for entries that act on a file or a commit. | When the user must confirm in the IDE. `vcs ▸ vcs_action {action: "annotate", path: "A.kt"}` |

## log_ops

| Tool | Capability | When · example |
|---|---|---|
| `commit_action` *mutates* | The Log's commit menu on a hash: cherry_pick, checkout, browse_at_revision, compare_with_local, reset_to, revert, undo, reword, fixup, squash_into, squash, drop, interactive_rebase, push_up_to, add_to_remote_branch, new_branch, new_tag, copy_revision, open_in_browser. The commit is selected in the Log first. | "cherry-pick that commit". `vcs ▸ commit_action {action: "cherry_pick", hash: "d20afbe"}` |
| `branch_op` *mutates* | The Branches popup through `GitBrancher`: merge, rebase, rebase_onto, compare, diff_with_local, rename, delete, checkout, checkout_as_new, new_tag; `target` is the other name. | "merge develop into this branch". `vcs ▸ branch_op {action: "merge", ref: "develop"}` |
| `worktrees` *mutates* | list, add (path, optional new branch) or remove a working tree. | "add a worktree for the hotfix". `vcs ▸ worktrees {action: "add", path: "../hotfix", branch: "hotfix/x"}` |
| `remotes` *mutates* | list, add, remove or rename a remote (`url` carries the new name for rename). | "add the upstream remote". `vcs ▸ remotes {action: "add", name: "upstream", url: "git@github.com:org/repo.git"}` |

## changes

| Tool | Capability | When · example |
|---|---|---|
| `stash` *mutates* | list, save (with message), pop, apply, drop through the IDE's Git; the stash list after. | "stash this while I check main". `vcs ▸ stash {action: "save", message: "wip"}` |
| `shelve` *mutates* | The IDE's shelf: list, shelve (name, optional `paths`) with rollback, unshelve by name. | "shelve these two files". `vcs ▸ shelve {action: "shelve", name: "spike", paths: ["A.kt", "B.kt"]}` |
| `patch` *mutates* | create writes the changes (or `paths`) as a unified diff to `path`; apply opens the IDE's Apply Patch dialog. | "make me a patch". `vcs ▸ patch {action: "create", path: "wip.patch"}` |
| `rollback` *mutates* | The IDE's Rollback on the given changed files, one call, undoable from Local History. | "throw away my changes to A.kt". `vcs ▸ rollback {paths: ["A.kt"]}` |

## history

| Tool | Capability | When · example |
|---|---|---|
| `blame` | Line, commit, author, date for lines `from`..`to` from the IDE's annotations; the gutter is shown. | "who wrote this". `vcs ▸ blame {path: "A.kt", from: 10, to: 20}` |
| `file_history` | The commits that touched a file, renames followed; the history tab is shown. | "when did this change". `vcs ▸ file_history {path: "A.kt"}` |
| `local_history` *mutates* | show the IDE's Local History of a file; label the project before a risky change; revert a file to a label of this session. | Before a big refactor. `vcs ▸ local_history {path: "A.kt", action: "label", label: "before-rename"}` |
| `file_at` | A file's content at a ref, and the IDE's diff of it against the working tree. | "how was this on main". `vcs ▸ file_at {path: "A.kt", ref: "main"}` |

## pull_request_ops

| Tool | Capability | When · example |
|---|---|---|
| `pr_create` *mutates* | Opens a pull request through the IDE's GitHub account: base, head, title, body, draft; the Pull Requests view is shown. | "open the PR to develop". `vcs ▸ pr_create {base: "develop", head: "feature/x", title: "…", body: "…"}` |
| `pr_comment` *mutates* | A comment on a pull request's conversation, as the IDE's account. | "leave a note on #74". `vcs ▸ pr_comment {number: 74, body: "…"}` |
| `pr_checks` | Mergeability and every check on the head commit, polled every 10 s until nothing is pending or `wait` runs out; `settled` and `can_merge` say where it stands. | "is the CI green". `vcs ▸ pr_checks {number: 74, wait: 110}` |
| `pr_merge` *mutates* | A merge commit through the IDE's account, only when the checks have settled green and the merge state is clean; refuses otherwise, naming the blocker. Merging into a branch that publishes on merge publishes. | "merge it". `vcs ▸ pr_merge {number: 74}` |

## release

| Tool | Capability | When · example |
|---|---|---|
| `tags` | The repository's tags on GitHub with their commits. | "is v6.0.0 tagged". `vcs ▸ tags {max: 5}` |
| `workflow_runs` | GitHub Actions runs, optionally of one branch: status, conclusion, url. | "did the release job pass". `vcs ▸ workflow_runs {branch: "main", max: 5}` |
| `release` | The GitHub Release of a tag with its assets. | "is the Release out, with the zip and the signatures". `vcs ▸ release {tag: "v6.0.0"}` |
| `marketplace` | The plugin's versions on the JetBrains Marketplace, from the public API, no account. | "is 6.0.0 on the Marketplace". `vcs ▸ marketplace {}` |
