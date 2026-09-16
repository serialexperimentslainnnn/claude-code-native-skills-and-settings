## How to work — strict, from Lain, no exceptions

**You are inside a JetBrains IDE through the Claude Code Native plugin, not in the Claude Code CLI.
Forget the CLI: what it does natively does not apply here.** The IDE's tools are far more powerful,
spend far fewer tokens, and take a whole list per call. Load `ide-tools-standards` before choosing
an instrument.

1. **The IDE's MCP servers are the tools** (`code`, `run`, `vcs`, `ops`). They cost almost nothing,
   they are faster, and they run in parallel. Never a shell pipeline to look at or find things: no
   `grep`, `sed`, `awk`, `find`, `cat`, `head`, `tail`, `ls`. Never the native `Read`, `Edit`,
   `Write`, `Grep`, `Glob` or `Bash` where the IDE has the tool (memory files outside the project
   are the only exception).
2. **The loop is `search_text` → `read_file` → `replace_text`/`write_file`/`create_file`**, and it
   runs in mass: every call carries the whole list (`paths`, `edits`, `files`), independent calls
   go out in the same message, never one item per call, never serial. `search_text` needs `path`
   scoped to a subdirectory (root-scoped and `queries` return nothing); `find_files` finds by name.
3. **Write all the code first.** Every change the task needs, in one pass, checking with
   `problems` (bulk, every touched file in one call) as you go. **No builds and no tests per
   change.** When there is nothing left to write or optimise, then one build and one test run,
   and one clean-up of everything that came out, all at once.
4. Build and test through the IDE: `mcp__run__run build`, `run_tests`, and the IDE terminal
   (`shell`) only for what the project defines as its test command. Never `run_configuration` for
   CTest configurations, never scripts of your own, never two GPU test runs at once.
5. **Commits**: signed as Lain, Conventional Commits, subject only, no body, no trailers, no
   tool attribution. Commit every logical unit; never `push`, tag or open a PR until Lain says so.
6. **Docs are state, not diary.** Nothing about what happened, when or who said what goes into
   docs, comments or changelogs; that is memory. What Lain tells you about users is for
   diagnosing, not for writing down.
7. **Say the thing.** If a request rests on a false premise or an approach is wrong, say it plainly
   first, then do what was asked. Ask when two readings lead to different work; decide and say so
   when a sensible default exists. A guard refusal is reported, never retried in disguise.
8. **Timings never regress**: on a performance path, measure against the previous release with the
   same method before calling a change done, and report both numbers.
9. Always follow SOLID patterns even for the little's things, always use the power of asyncronous,
   multithreading and never create a file with more than 250 lines of code. Keeping small files
   helps you to read faster, wrhite faster, work faster, search faster, to use less tokens, and
   to make all your tasks always smaller.
10. **Commands are plain, short and readable — or the Guard blocks them, every time.** Type what a
    person would type at the prompt: one command, its arguments, nothing clever. **Forbidden**: big
    one-liners, inline scripts (`bash -c`, `sh -c`, `eval`, `python -c`, `node -e`, heredocs),
    `$( )` and backtick acrobatics, `mktemp` fixtures, chains longer than two steps, pipes longer
    than two stages, anything that obfuscates what runs. Run what the project already defines
    (`./check.sh`, `./install.sh --dry-run`) exactly as it is documented. Lain has to be able to
    read the command at a glance, and the Guard judges the string — a refusal means the command was
    wrong, not the Guard: rewrite it plain or hand it to Lain, never dress it up and retry.
11. **Read what comes back. All of it, every time.** A Guard block is never ignored and never treated
    as unreadable: it always says **which rule fired and which string tripped it** — quote both,
    act on them, and never claim you cannot see why you were blocked. Every MCP call to the IDE
    answers with the data of what it touched — the file, the lines, the problems, the hashes, the
    exit code, the tail, `status: running` with its `job`, `truncated` with its `max` — and that
    answer **is** the state of the IDE: read it whole before the next call and act on what it
    says, never on what you suppose it says. Guessing at a result, retrying a call whose answer you
    did not read, or saying "I don't know what happened" when the answer is in front of you is
    how a session gets lost in the IDE, and it is the defect, not the environment.
11. Never ignore a block from the guard and never act as you can't read the guard message about the blocking
    and never act as if you can't read all the data from every MCP call to the IDE or you don't understand whats 
    happening or supose whats happening. The Guard tells you always why you got blocked and which rule trigered.
    And all the MCP IDE tools brings you output and data of everything that you interact with the IDE, so always
    read and understand both Guard Blocks and MCP answer data in order to not get lost in the IDE environment.