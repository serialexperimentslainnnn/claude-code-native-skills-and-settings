# `run` — build, run, test, shell, debug

Examples are the last step of the ladder, as `run ▸ tool {args}`. Long tools (`build`,
`run_configuration`, `run_tests`, `shell`) stream to the card, answer `status: running` after `wait`
seconds, and are resumed with `job`.

| Tool | Capability | When · example |
|---|---|---|
| `build` *mutates* | The IDE's build, incremental or `rebuild`, a `module` or one `file`, with the compiler's errors and positions; streamed. | "does it compile". `run ▸ build {kind: "module", module: "app", wait: 110}` |
| `run_configurations` | The run configurations as the Run combo shows them: name, type, temporary, selected. | Before running anything. `run ▸ run_configurations {}` |
| `run_configuration` *mutates* | Starts one as the Run button does, before-launch tasks included; `executor` run, debug, coverage or profile; exit code and console tail; several with `names`. | "run the gates", any project script that already has a configuration. `run ▸ run_configuration {name: "Tool: lint", wait: 110}` |
| `processes` *mutates* | The Run tool window's tabs, or stops one by name. | "is it still running", "stop it". `run ▸ processes {action: "stop", name: "Kotlin tests"}` |
| `run_tests` *mutates* | Tests through the IDE's runner: a file, several, the test at a line, or a named configuration; pass/fail/ignored and each failure's message and frame. | "run this test". `run ▸ run_tests {name: "ToolModelTest", wait: 110}` |
| `tests` | The test classes and methods the IDE's frameworks recognise in a file, with lines. | "what tests are in here". `run ▸ tests {path: "src/test/X.kt"}` |
| `shell` *mutates* | A command in the user's shell inside a Terminal tab; exit code and tail. Replaces Bash. | Any command; several chained in one call. `run ▸ shell {command: "git log -3 --oneline", wait: 20}` |
| `terminal_tabs` *mutates* | The Terminal window's tabs (name, selected, ours, running) or close one by name. | "close your tab". `run ▸ terminal_tabs {action: "close", name: "Claude"}` |
| `edit_configuration` *mutates* | Run ▸ Edit Configurations at a configuration. | `run ▸ edit_configuration {name: "Kotlin tests"}` |
| `attach` *mutates* | Run ▸ Attach to Process chooser. | `run ▸ attach {}` |
| `coverage` *mutates* | The Coverage window; switch, hide, report, import. | After `executor: "coverage"`. `run ▸ coverage {action: "report"}` |
| `session` *mutates* | Start a configuration under the debugger and wait for the first stop; status with frames and variables; stop; list. | "debug this test". `run ▸ session {action: "start", name: "ToolModelTest"}` |
| `step` *mutates* | over, into, out, force_into, smart_into, resume, pause, mute, run_to a line, or wait; answers with the session status. | Once suspended. `run ▸ step {kind: "run_to", path: "A.kt", line: 22}` |
| `frames` | Threads and the stack of one; `frame` selects the current frame for `values`. | "where is it stopped". `run ▸ frames {max: 5}` |
| `values` *mutates* | Variables of the current frame; `eval` an expression; `set` a variable. | "what is x here". `run ▸ values {action: "eval", code: "tools.size"}` |
| `breakpoint` *mutates* | Add (with `condition`, `temporary`), remove or list line breakpoints. | Before `session`. `run ▸ breakpoint {action: "add", path: "A.kt", line: 21}` |
