# `ops` — the Services panel, the project, the IDE, data

Examples are the last step of the ladder, as `ops ▸ tool {args}`. `services` first before any other
services tool; `actions` first to find an id for `ide_action`.

| Tool | Capability | When · example |
|---|---|---|
| `services` | The Services tree as the user sees it: path, name, contributing plugin, state; `filter`. Only nodes with services, as the view shows. | Before any other services tool. `ops ▸ services {filter: "Docker"}` |
| `service_actions` | The actions the IDE offers on a node, with id, text and enabled. | To know what `service_action` can do. `ops ▸ service_actions {path: "Docker/Docker/Containers/web"}` |
| `service_action` *mutates* | Performs one of those actions exactly as clicking it would. | "stop the container", "connect to Docker". `ops ▸ service_action {path: "Docker/Docker/Containers/web", action: "Stop Container"}` |
| `service_open` | Reveals a node in the Services window. | "show me the cluster". `ops ▸ service_open {path: "Docker/Docker"}` |
| `project` | Name, base path, SDK, indexing, module count, active VCSs. | First call in an unknown project. `ops ▸ project {}` |
| `modules` | The modules as Project Structure shows them. | "how is the project split". `ops ▸ modules {}` |
| `dependencies` | One module's order entries in classpath order, with scope. | "what does the main module depend on". `ops ▸ dependencies {module: "app.main"}` |
| `dependency_add` *mutates* | Adds an existing library to a module through the project model (not for Gradle/Maven, which edit the build file). | Plain IntelliJ projects only. `ops ▸ dependency_add {module: "app", library: "junit", scope: "test"}` |
| `ide_action` *mutates* | Any registered IDE action by id, as its menu entry would; with a target it runs as that context menu would: a file (`path`, `line`, `column` — file, PSI and an editor on it), a commit (`hash` — selected in the Git Log), a Services node (`node`). | What no other tool covers. `ops ▸ ide_action {action_id: "Git.CompareWithBranch"}` · `ops ▸ ide_action {action_id: "Vcs.CherryPick", hash: "d20afbe"}` · `ops ▸ ide_action {action_id: "OverrideMethods", path: "src/A.kt", line: 12}` |
| `actions` | Every action the IDE registers, plugins included: id, menu text, description, group, enabled in the project context; `query` on id or text. | To find the id for `ide_action`. `ops ▸ actions {query: "cherry"}` |
| `menu` | The main menu as the user sees it: top level, or the items of one menu by path. | "what is under Code ▸ Analyze". `ops ▸ menu {path: "Code/Analyze"}` |
| `appearance` *mutates* | View ▸ Appearance modes: presentation, distraction_free, full_screen, zen, compact, assistant; toggle or set with `on`; returns the state. | "put the IDE in presentation mode". `ops ▸ appearance {mode: "presentation", on: true}` |
| `ui` *mutates* | Show or hide the toolbar, navigation_bar, tool_window_bars, status_bar or main_menu; toggle or set with `on`. | "hide the status bar". `ops ▸ ui {part: "status_bar", on: false}` |
| `service_data` | The console/editor text inside a Services node's panel (last `tail` lines). | "show me the container log". `ops ▸ service_data {path: "Docker/Docker/Containers/web", tail: 100}` |
| `service_extract` *mutates* | Extract a node into its own tab. | `ops ▸ service_extract {path: "Docker/Docker/Containers/web"}` |
| `service_expand` *mutates* | Expand a node in the tree. | `ops ▸ service_expand {path: "Docker/Docker"}` |
| `service_events` | Service events since a sequence number: added, removed, changed, reset. | "did anything change". `ops ▸ service_events {since: 12}` |
| `deployment` *mutates* | Tools ▸ Deployment: upload, download, sync, compare, browse, configure through the plugin's actions. | `ops ▸ deployment {action: "upload", path: "src"}` |
| `ssh_session` *mutates* | Tools ▸ Start SSH Session. | `ops ▸ ssh_session {}` |
| `qodana` *mutates* | Qodana results as data with the tab shown; run/open through the plugin. | `ops ▸ qodana {action: "results"}` |
| `vulnerable_dependencies` | The Package Checker's findings, tab shown. | `ops ▸ vulnerable_dependencies {}` |
| `javadoc` *mutates* | Tools ▸ Generate JavaDoc dialog, scoped to a path. | `ops ▸ javadoc {path: "src/main/java"}` |
| `launcher` *mutates* | Create Command-line Launcher or Desktop Entry. | `ops ▸ launcher {action: "script"}` |
| `xml` *mutates* | Validate an XML file, generate a DTD or an XSD schema. | `ops ▸ xml {action: "validate", path: "pom.xml"}` |
| `markdown` *mutates* | Import a docx, export, table of contents, pandoc settings. | `ops ▸ markdown {action: "export", path: "README.md"}` |
| `groovy_console` *mutates* | Tools ▸ Groovy Console. | `ops ▸ groovy_console {}` |
| `kotlin_bytecode` *mutates* | Show Kotlin Bytecode for a file. | `ops ▸ kotlin_bytecode {path: "A.kt"}` |
| `kotlin_configure` *mutates* | Configure Kotlin in Project. | `ops ▸ kotlin_configure {}` |
| `python_console` *mutates* | The Python console. | `ops ▸ python_console {}` |
| `tabs` *mutates* | The editor's tab groups with tabs, selection and pins; or close, close_others, close_all, pin, split_right, split_down, unsplit, move_to_opposite on a tab. | "split the editor with A.kt on the right". `ops ▸ tabs {action: "split_right", path: "A.kt"}` |
| `layout` *mutates* | save_default, restore_default or hide_all for the tool window layout. | "hide everything". `ops ▸ layout {action: "hide_all"}` |
| `zoom` *mutates* | in, out or reset on the selected editor's font (`scope=editor`) or the whole IDE (`ide`). | "make it bigger". `ops ▸ zoom {action: "in", scope: "ide"}` |
| `editor_settings` *mutates* | line_numbers, whitespace, soft_wraps or gutter_icons in every editor; toggle or set with `on`. | "show whitespace". `ops ▸ editor_settings {setting: "whitespace", on: true}` |
| `tool_window` *mutates* | Open, close or list tool windows. | "show the Problems view". `ops ▸ tool_window {action: "open", id: "Problems View"}` |
| `settings_open` *mutates* | Settings at a page by display name. | "open the plugin settings". `ops ▸ settings_open {name: "Claude Code"}` |
| `plugins` | The IDE's plugins with id, version and enabled; `filter`. | Before relying on a plugin; to know the IDE build (`com.intellij`). `ops ▸ plugins {filter: "database"}` |
| `notify` *mutates* | A balloon in the IDE's notification area. | A finished long task or a decision needed while the chat is hidden. `ops ▸ notify {title: "Build", message: "green", kind: "info"}` |
| `db_connections` | The Database tool window's data sources: name, DBMS, redacted URL. | First db call. `ops ▸ db_connections {}` |
| `db_schema` | Tables and views of a source, or the columns of one table. | "what tables are there". `ops ▸ db_schema {connection: "local", table: "users"}` |
| `db_query` *mutates* | One or several SQL statements over the IDE's connection and credentials; rows or update count. Reads by intent; a write is the user's to approve. | "how many rows". `ops ▸ db_query {connection: "local", code: "select count(*) from users"}` |
| `http_files` | The project's `.http`/`.rest` request files. | Before `http_run`. `ops ▸ http_files {}` |
| `http_run` *mutates* | Runs every request of a file through the HTTP Client's run configuration; console tail; streamed. | "call the API from the .http file". `ops ▸ http_run {path: "api/users.http", wait: 45}` |
| `http_open` | Opens a request file in the editor. | "show me the requests". `ops ▸ http_open {path: "api/users.http"}` |
| `ssh_hosts` | The SSH hosts the IDE knows: host, port, user, authentication kind; never the secret. | "which hosts are configured". `ops ▸ ssh_hosts {}` |
