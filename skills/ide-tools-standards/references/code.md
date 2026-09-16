# `code` — the project as the IDE resolves it

Examples are the last step of the ladder, as `code ▸ tool {args}`.

## read · search

| Tool | Capability | When · example |
|---|---|---|
| `read_file` | A file as the editor holds it, unsaved edits included; `offset`/`limit` for big files; several with `paths`. | Any "look at", "open", "what does X contain". `code ▸ read_file {paths: ["src/A.kt", "src/B.kt"], limit: 120}` |
| `search_text` | Text or regex across the project; one row per hit with file and line, no text. | "where is X used", "find the string". `code ▸ search_text {queries: ["TODO", "class .*Test"], regex: true}` |
| `find_files` | Files by exact name or glob. | "where is the file called". `code ▸ find_files {names: ["*.http", "Guard*.kt"]}` |
| `list_directory` | A directory as the project tree shows it, excluded entries left out, `depth` levels. | "what is in this folder". `code ▸ list_directory {path: "src/main/kotlin", depth: 2}` |

## navigate · outline · hierarchy

| Tool | Capability | When · example |
|---|---|---|
| `find_symbols` | Classes, functions and other named symbols whose name contains the query, as Go to Symbol does; `libraries` to include them. | "which classes are called …Tools". `code ▸ find_symbols {queries: ["Tools", "Guard"]}` |
| `definition` | The declaration the reference at a position resolves to. | "where is this defined". `code ▸ definition {path: "A.kt", line: 9, column: 24}` |
| `references` | Every place that references the symbol at a position. | "who calls this", "is this used". `code ▸ references {path: "A.kt", line: 14, column: 9}` |
| `implementations` | Implementations or overrides of the symbol at a position. | "who implements this interface". `code ▸ implementations {path: "I.kt", line: 6}` |
| `file_outline` | The declarations of a file as a tree with their lines, like the Structure view. | Before reading a big file. `code ▸ file_outline {paths: ["Session.kt"], depth: 2}` |
| `symbol_info` | Kind, name, declaring signature and location of the symbol at a position. | "what is this thing". `code ▸ symbol_info {positions: [{path: "A.kt", line: 21, column: 47}]}` |
| `hierarchy` | Callers or callees of the symbol at a position, nested up to `depth` 3. | "trace who reaches this". `code ▸ hierarchy {path: "A.kt", line: 123, kind: "callers", depth: 3}` |

## diagnostics · inspect

| Tool | Capability | When · example |
|---|---|---|
| `problems` | Errors and warnings the IDE's analysis shows for a file (opens it), with line, column, severity and inspection; `severity` error/warning/weak/all. | Before calling any edit done. `code ▸ problems {paths: ["A.kt", "B.kt"], severity: "warning"}` |
| `project_problems` | Everything the Problems view lists across the project; `group` filters by inspection family or plugin. | "is the project clean", "what does Qodana say". `code ▸ project_problems {group: "Qodana"}` |
| `problems_view` | Lists the Problems tool window's tabs, or shows one to the user. | "show me the security findings". `code ▸ problems_view {tab: "Security Analysis"}` |
| `inspections` | The inspections of the current profile — id, name, group, enabled — filtered by a query. | To find an inspection id. `code ▸ inspections {query: "unused"}` |
| `inspect` | Runs the profile's enabled inspections on a file, or one by id; findings with line, severity and message; hints below `severity` stay out. | "run the inspections on this file", "is there anything unused here". `code ▸ inspect {path: "A.kt", inspection: "UnusedSymbol"}` |

## edit

| Tool | Capability | When · example |
|---|---|---|
| `replace_text` *mutates* | One literal replacement (all with `replace_all`), one undo entry, saved, shown as a diff; several files with `edits`. | Any targeted change. `code ▸ replace_text {edits: [{path: "A.kt", old_string: "x", new_string: "y"}]}` |
| `insert_text` *mutates* | Whole lines before a line (one past the end appends). | Adding a member or an import. `code ▸ insert_text {path: "A.kt", line: 5, content: "fun twice() = 2"}` |
| `create_file` *mutates* | A new file, directories created, opened; fails if it exists. | "create a test for". `code ▸ create_file {files: [{path: "src/test/X.kt", content: "…"}]}` |
| `write_file` *mutates* | A whole rewrite as one undo entry and one diff, or creation when absent. | A file that changes more than it keeps. `code ▸ write_file {path: "A.kt", content: "…"}` |

## edit_ops

| Tool | Capability | When · example |
|---|---|---|
| `undo` *mutates* | Edit ▸ Undo on a file through the IDE's undo stack; returns whether there was anything to undo. | "take that back". `code ▸ undo {path: "A.kt"}` |
| `redo` *mutates* | Edit ▸ Redo on a file. | "put it back". `code ▸ redo {path: "A.kt"}` |
| `search_replace` *mutates* | Replace in Files with Replace All: text or regex across the files that match (or only `paths`, one call), one undoable command per file, first file shown. | A rename of a string across the project. `code ▸ search_replace {query: "foo", replacement: "bar", paths: ["A.kt", "B.kt"]}` |
| `line_ops` *mutates* | join, duplicate, delete, indent or unindent at a line, as the editor would. | "duplicate line 12". `code ▸ line_ops {action: "duplicate", path: "A.kt", line: 12}` |

## refactor · format

| Tool | Capability | When · example |
|---|---|---|
| `rename` *mutates* | The IDE's Rename on the symbol at a position, or the file; every reference follows; fails on conflict. | "rename X to Y". `code ▸ rename {path: "A.kt", line: 6, column: 9, new_name: "salute"}` |
| `move_file` *mutates* | The IDE's Move: packages, imports and references follow. | "move this into package p". `code ▸ move_file {path: "A.kt", destination: "src/main/kotlin/p"}` |
| `safe_delete` *mutates* | Deletes a symbol or a file only when nothing uses it; otherwise lists the blocking usages. | "remove this if unused". `code ▸ safe_delete {path: "A.kt", line: 7, column: 9}` |
| `reformat` *mutates* | Reformat Code on a file or a line range, with the project's code style. | After editing. `code ▸ reformat {paths: ["A.kt", "B.kt"]}` |
| `optimize_imports` *mutates* | Optimize Imports on a file. | After editing. `code ▸ optimize_imports {path: "A.kt"}` |

## editor

| Tool | Capability | When · example |
|---|---|---|
| `open_file` | Opens a file at a line and column, as Go to File does. | "show me", and on every file edited. `code ▸ open_file {path: "A.kt", line: 14}` |
| `active_file` | The selected editor with caret and selection, plus every open file. | "what am I looking at". `code ▸ active_file {}` |
| `index_status` | Whether the IDE is indexing; `wait` blocks until it is done. | On an indexing error, before symbol tools. `code ▸ index_status {wait: true}` |
| `editor_action` *mutates* | The Code menu at a position: override, implement, delegate, generate, surround, unwrap, comment_line/block, move_statement/element/line, rearrange, auto_indent, insert/save_template, fold/unfold (+recursively, +all), update_copyright, quick_doc/definition/type. Caret placed, file in a tab without focus. | "override toString here". `code ▸ editor_action {action: "override", path: "A.kt", line: 12}` |

## analyze

| Tool | Capability | When · example |
|---|---|---|
| `inspect_scope` *mutates* | Code ▸ Inspect Code on project, module, dir or file; the Inspection Results window shows them. | "inspect the whole module". `code ▸ inspect_scope {scope: "module", module: "app"}` |
| `cleanup` *mutates* | Code ▸ Code Cleanup on a scope, one undoable command. | "clean up this package". `code ▸ cleanup {scope: "dir", path: "src/main/kotlin/x"}` |
| `file_dependencies` | What the files of a scope depend on (forward, `transitive` levels); backward opens the IDE's analysis. | "what does this file pull in". `code ▸ file_dependencies {scope: "file", path: "A.kt"}` |
| `dataflow` | Analyze Data Flow to/from the expression at a position, in the IDE's window. | "where does this value come from". `code ▸ dataflow {path: "A.kt", line: 12, column: 9, direction: "to"}` |

## analysis

| Tool | Capability | When · example |
|---|---|---|
| `stack_trace` | Frames of a trace resolved to project files; the Analyze Stack Trace dialog opens with the text. | A pasted exception. `code ▸ stack_trace {text: "…"}` |
| `duplicates` | Locate Duplicates on a file or the project, in the IDE's window. | "is this duplicated anywhere". `code ▸ duplicates {path: "A.kt"}` |
| `infer_nullity` *mutates* | Infer Nullity (Java) with the IDE's dialog. | "annotate nullability". `code ▸ infer_nullity {path: "A.java"}` |
| `related` | Tests of a class, the subject of a test (data), super method, implementations; the Navigate action opens it. | "where are the tests for this". `code ▸ related {kind: "test", path: "A.kt", line: 5}` |

## views

| Tool | Capability | When · example |
|---|---|---|
| `diff_show` | The IDE's diff of two files. | "diff these two". `code ▸ diff_show {left: "A.kt", right: "B.kt"}` |
| `compare` | A file against another or against the active editor. | "compare with what I have open". `code ▸ compare {path: "A.kt"}` |
| `mark_as` *mutates* | Mark Directory as source, test, resources, test_resources, excluded, or unmark. | "this is a test root". `code ▸ mark_as {path: "src/it", kind: "test"}` |
| `open_in` | Reveal in the file manager, open in the IDE's Terminal, or in the associated app. | "open the folder". `code ▸ open_in {path: "build", where: "file_manager"}` |

## files

| Tool | Capability | When · example |
|---|---|---|
| `copy_path` | absolute, relative, name onto the clipboard and returned; reference runs Copy Reference. | "copy the path". `code ▸ copy_path {path: "A.kt", kind: "absolute"}` |
| `file_type` *mutates* | The file type the IDE assigns; with `type`, associates the name with it. | "treat this as JSON". `code ▸ file_type {path: "x.cfg", type: "JSON"}` |
| `ignore` *mutates* | Adds a path to .gitignore or another ignore file; the file opens. | "ignore the build dir". `code ▸ ignore {path: "build"}` |
| `delete_file` *mutates* | Deletes paths through the VFS, one call, inside the project only. | Scratch files with no usages. `code ▸ delete_file {paths: ["tmp.txt"]}` |

## refactor_ops

| Tool | Capability | When · example |
|---|---|---|
| `introduce` *mutates* | Introduce variable, constant, field, parameter or functional_parameter at a position or selection. | "extract this into a constant". `code ▸ introduce {kind: "constant", path: "A.kt", line: 8, column: 12, to_line: 8, to_column: 30}` |
| `extract` *mutates* | Extract method, interface, superclass, delegate or module. | "extract these lines into a method". `code ▸ extract {kind: "method", path: "A.kt", line: 10, to_line: 14}` |
| `inline` *mutates* | Refactor ▸ Inline at a position. | "inline this variable". `code ▸ inline {path: "A.kt", line: 9, column: 5}` |
| `members` *mutates* | pull_up, push_down, change_signature, move, encapsulate_fields, make_static, convert_to_instance, inheritance_to_delegation, anonymous_to_inner, method_object. | "change the signature". `code ▸ members {action: "change_signature", path: "A.kt", line: 20, column: 9}` |

## templates

| Tool | Capability | When · example |
|---|---|---|
| `templates` | The live templates: key, group, description, text; `query`. | Before `template_apply`. `code ▸ templates {query: "main"}` |
| `template_apply` *mutates* | Expands a live template at a position, as key + Tab would; the user fills the variables. | "put a for loop here". `code ▸ template_apply {key: "fori", path: "A.kt", line: 12}` |
| `file_templates` | The file templates: name, extension, text. | Before `file_from_template`. `code ▸ file_templates {query: "Kotlin"}` |
| `file_from_template` *mutates* | New ▸ template in a directory with `props`; the file opens. | "create a Kotlin class Foo in x". `code ▸ file_from_template {template: "Kotlin Class", dir: "src/main/kotlin/x", name: "Foo"}` |

## language

| Tool | Capability | When · example |
|---|---|---|
| `injections` | The language fragments injected into a file's literals. | "is that SQL recognised". `code ▸ injections {path: "Dao.kt"}` |
| `inject_at` *mutates* | Inject a language into the literal at a position (IntelliLang). | "treat this string as JSON". `code ▸ inject_at {path: "A.kt", line: 9, column: 20, language: "JSON"}` |
| `docs` | The quick documentation popup for a symbol. | "what does this do". `code ▸ docs {path: "A.kt", line: 9, column: 5}` |

## bookmarks

| Tool | Capability | When · example |
|---|---|---|
| `bookmarks` | Every bookmark: group, file, line, mnemonic, description. | "where did I leave marks". `code ▸ bookmarks {}` |
| `bookmark_add` *mutates* | A bookmark on a file or a line, in a group, with a description. | "remember this spot". `code ▸ bookmark_add {path: "A.kt", line: 40, description: "fix here"}` |
| `bookmark_remove` *mutates* | Remove the bookmarks of a file, or the one on a line. | `code ▸ bookmark_remove {path: "A.kt", line: 40}` |
| `project_view` | Select a file in the Project window, switching pane if asked. | "show it in the tree". `code ▸ project_view {path: "A.kt"}` |

## psi

| Tool | Capability | When · example |
|---|---|---|
| `psi_tree` | The syntax tree of a file or of the element at a line, to a depth. | When text is not enough. `code ▸ psi_tree {path: "A.kt", line: 12, depth: 2}` |
| `psi_at` | The leaf at a position and its parents. | "what is this token". `code ▸ psi_at {path: "A.kt", line: 12, column: 9}` |
| `psi_replace` *mutates* | Replace the element (or a parent) with text parsed in the file's language, reformatted. | Structural edits. `code ▸ psi_replace {path: "A.kt", line: 12, column: 9, parent: 1, text: "foo(1)"}` |
| `psi_insert` *mutates* | Insert parsed text before or after the element. | `code ▸ psi_insert {path: "A.kt", line: 12, text: "val x = 1", where: "after"}` |

## index

| Tool | Capability | When · example |
|---|---|---|
| `index_keys` | The keys of a file-based index by name. | `code ▸ index_keys {index: "TodoIndex"}` |
| `index_query` | The files behind one key. | `code ▸ index_query {index: "filetypes", key: "Kotlin"}` |
| `stub_query` | A stub index's keys, or the elements behind a key. | "every class named Foo". `code ▸ stub_query {index: "java.class.shortname", key: "Foo"}` |

## uast (IDEs with the Java plugin)

| Tool | Capability | When · example |
|---|---|---|
| `uast_tree` | The unified AST of a JVM-language file to a depth. | Cross-language analysis. `code ▸ uast_tree {path: "A.kt", depth: 2}` |
| `uast_at` | The UAST node at a position and its parents. | `code ▸ uast_at {path: "A.kt", line: 12, column: 9}` |

## workspace

| Tool | Capability | When · example |
|---|---|---|
| `workspace` | The workspace model's modules, content roots, source roots, libraries or SDKs, with their entity source. | "what did Gradle import". `code ▸ workspace {entity_type: "source_root"}` |

## markup

| Tool | Capability | When · example |
|---|---|---|
| `mark_add` *mutates* | A highlight, warning or error range over lines, or a gutter icon with a tooltip; returns an id. | "show me where the bug is". `code ▸ mark_add {path: "A.kt", line: 12, to_line: 14, kind: "warning", tooltip: "null here"}` |
| `mark_remove` *mutates* | Remove a mark or hint by id. | `code ▸ mark_remove {id: 3}` |
| `marks` | The marks of the session, all or for a file. | `code ▸ marks {path: "A.kt"}` |
| `hint_add` *mutates* | An inline hint before or after a position, as parameter hints look. | "annotate what this returns". `code ▸ hint_add {path: "A.kt", line: 12, column: 20, text: ": Int"}` |

## presence

| Tool | Capability | When · example |
|---|---|---|
| `banner_show` *mutates* | A banner over a file's editor with action labels; the click is reported by `banner_clear`. | A choice tied to a file. `code ▸ banner_show {path: "A.kt", text: "Migrate this?", actions: ["Yes", "Later"]}` |
| `banner_clear` *mutates* | Removes the banner; returns the chosen action. | `code ▸ banner_clear {path: "A.kt"}` |
| `status` *mutates* | Text in the status bar. | "tell me when it's done". `code ▸ status {text: "Claude: tests green"}` |
| `scratch_create` *mutates* | A scratch file with a language and content, opened. | Notes, queries, drafts. `code ▸ scratch_create {name: "plan.md", content: "# Plan"}` |

## recent

| Tool | Capability | When · example |
|---|---|---|
| `recent` | Recently opened files (`kind=files`) or recently changed ones (`changed_files`), newest first. | "what was I working on". `code ▸ recent {kind: "changed_files"}` |
| `navigate_history` *mutates* | Navigate ▸ Back, Forward, Last Edit Location, Next Edit Location on the user's editor. | "go back to where I was". `code ▸ navigate_history {direction: "back"}` |
| `compare_clipboard` | View ▸ Compare with Clipboard against a file, in the IDE's diff window. | "diff this against what I copied". `code ▸ compare_clipboard {path: "A.kt"}` |
| `scheme` *mutates* | List or set the theme, color scheme, keymap or code style, as Quick Switch Scheme does. | "switch to the dark theme". `code ▸ scheme {kind: "theme", action: "set", name: "Dark"}` |
