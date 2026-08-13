---
name: lua-standards
description: Use when writing or reviewing Lua code - .lua files, .luacheckrc, selene.toml, stylua.toml, .rockspec and luarocks, busted spec files, LuaJIT vs Lua 5.1/5.4/5.5 targets, OpenResty content_by_lua_block/access_by_lua_file/ngx.shared.DICT/lua-nginx-module, Neovim init.lua and vim.api/vim.uv plugins with lazy.nvim, Redis or Valkey EVAL/EVALSHA/FUNCTION scripts, Teal .tl files, lua-language-server ---@ annotations, or sandboxing untrusted Lua with load/setfenv/_ENV.
---

# Lua standards (reference: August 2026)

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Lua is almost never used on its own: **it is used embedded, and the host decides almost everything** —
interpreter version, available libraries, concurrency model, what can be called and what kills your
process. The first question in any Lua work is not "which version of the language" but **"who is the
host"**. This skill is structured by host.

Triggers: `.lua`, `.tl`, `.rockspec`, `.luacheckrc`, `selene.toml`, `stylua.toml`, `init.lua`,
`*_spec.lua` (busted), `content_by_lua_block`/`access_by_lua_file`/`ngx.*`, `vim.api`/`vim.uv`,
`EVAL`/`EVALSHA`/`FUNCTION LOAD`, `luarocks`, `---@` annotations.

**Not applicable**: see `caching-cdn-standards` and `networking-standards` (nginx/OpenResty **as a
platform**: configuration, TLS, upstreams, cache, limits — **the Lua that runs inside is ours**),
`data-platform-standards` and `nosql-standards` (Redis/Valkey **as an engine**: memory, persistence,
eviction, clustering — **the `EVAL` script is ours**), `homelab-standards` (self-hosting the stack),
`appsec-standards` (methodology and vulnerability classes; here only Lua's specific sandboxing),
`c-standards` (**Lua's C API, `lua_State`, native extensions and their memory are hers**; here only
the boundary as seen from Lua), `perl-standards` and `groovy-standards` (nothing in common beyond
"it is a dynamic language"), `secrets-management-standards`, `vulnerability-management-standards`,
`observability-standards`, `sql-standards`.

## 2. Default decisions: version and toolchain

> Verify the latest version on the web before committing to it in a real project (§8).

**The ecosystem's fracture is real and is not resolved by choosing "the latest"**: the host imposes
the version and many LuaRocks libraries only work on one branch.

| Branch | Status verified as of Aug 2026 | When it is your target |
|---|---|---|
| **Lua 5.1** | End of line (5.1.5, Feb 2012). Still **the most widely deployed version** via LuaJIT | Only because the host imposes it (LuaJIT, Redis, OpenResty) |
| Lua 5.2 / 5.3 | No active maintenance; 5.3.6 is from Sep 2020 | Never in a new project |
| **Lua 5.4** | 5.4.8 (4 Jun 2025), the latest of the branch | Default for **standalone** Lua if the host does not dictate |
| **Lua 5.5** | **5.5.0 published on 22 Dec 2025** | Greenfield standalone; verify your rocks' support first |
| **LuaJIT** | **Active**: a *rolling release* model on the `v2.1` branch, with commits in Aug 2026. No tarballs and no release tags; the version is `2.1.<commit timestamp>` | When performance or the host dictates (OpenResty, Neovim) |

**LuaJIT is supportable**, with explicit conditions: it is **compatible with Lua 5.1** plus a subset
of 5.2/5.3 extensions — it is **not** "modern Lua". A new project on LuaJIT accepts writing
5.1 for ever. Upstream operational rules that must be respected: follow the git `v2.1` branch
(not `master`, not the `v2.1.ROLLING` tag, not `2.1.0-beta3`), **do not use third-party tarballs nor
GitHub's automatic tarball** (without `.git` it does not compile the correct version), and if the
build needs "a release", take dated snapshots of the branch.

| Component | Choice | Verified | Licence (raw LICENSE) |
|---|---|---|---|
| Formatter | **StyLua** | v2.5.2 (May 2026) | **MPL-2.0** (not MIT) |
| Linter | **selene** | 0.31.0 (May 2026), active development | **MPL-2.0** (not MIT) |
| Linter (alternative) | `luacheck` (`lunarmodules/luacheck`) | v1.2.0, May 2024 — **no releases since** | MIT |
| Types | **lua-language-server** (LuaLS) + `---@` annotations | 3.18.2 (Apr 2026) | MIT |
| Real typing | **Teal** (`tl`) | v0.24.8 (Oct 2025) | MIT |
| Tests | **busted** | v2.3.0 (Jan 2026) | MIT |
| Packages | **LuaRocks** | 3.13.x | MIT |

Criterion: **selene by default** in a new project (active, fast, `selene.toml` with the *standard
library* declared per host: `lua51`, `lua54`, `roblox` or one of your own). `luacheck` is still valid
where it is already in place, but **its lack of releases since 2024 is a declared risk**. A committed
`stylua.toml` and `stylua --check` as a gate.

**Typing**: in non-trivial new code, either **Teal** (compiles to Lua, real types; only if you
control the host's build) or plain Lua **with LuaLS `---@` annotations** verified in CI
(`lua-language-server --check`). Without one of the two, a refactor in Lua is done blind.

**LuaRocks is the fragile point of the stack**: it resolves transitive versions poorly, many rocks do
not declare branch compatibility (5.1 vs 5.4) and those that carry C need the toolchain and headers
of the specific interpreter. Rule: **a local rock tree per project** (`luarocks --tree ./.rocks`),
a `.rockspec` with `dependencies` bounded by version, and for OpenResty/Neovim **vendor** the
dependency into the repo rather than depending on LuaRocks in the production runtime.

## 3. The language: what actually breaks

- **Variables are global by default. It is Lua's biggest operational design flaw.** A typo
  creates a silent global; in a long-lived host (an nginx worker, a game server) that is a
  memory leak and state contamination between requests. **`local` always**, without exception.
  Enable detection: `luacheck`/`selene` flag undeclared globals, and in hosts that allow it, load
  a `strict` module that *errors* on reading/writing an undeclared global.
- **The table is the only structure**: array, hash, object, module and namespace. There is nothing
  else. 1-indexed. `#t` and `ipairs` **are only reliable with no holes**; with a `nil` in the middle
  the result is undefined — for sparse collections, `pairs` and an explicit counter.
- **Metatables and `__index`**: inheritance is a chain of `__index`; use it sparingly, explicitly and
  flat (each level is an indirection on the hot path). Document every metatable that is not `__index`
  — `__gc`, `__close` (5.4+) and `__newindex` are powerful and opaque.
- **Errors are values, and `pcall` is the mechanism**: `error()` unwinds to the nearest
  `pcall`. Convention: library functions return `nil, err` (checkable) and reserve
  `error()` for programmer contract violations. `xpcall` with `debug.traceback` to
  keep the trace — with `pcall` you lose it. **A `pcall` whose error is discarded without a log is a
  veto.**
- **`nil` vs `false`**: only `nil` and `false` are falsy; **`0` and `""` are truthy**. Distinguish
  "absent" (`nil`) from "present and false" (`false`) in every API returning flags. Arithmetic
  coercion (`"10" + 1`) hides bugs: convert with `tonumber` and check for `nil`.
- In 5.3+ there are **separate integers and floats** (`3/2` is a float, `//` integer); in LuaJIT/5.1
  everything is a double. The same code on both, doing index or money arithmetic, **behaves
  differently**: pin it down with tests.
- **Closures**: cheap and the natural idiom for callbacks; careful with capturing `self` or big
  tables in long-lived closures (they retain memory).
- **GC**: incremental by default; **5.4 adds a generational mode**
  (`collectgarbage("generational")`), which usually wins with a lot of young garbage. Do not touch
  its parameters without measuring pauses before and after.

## 4. Criteria per host

### OpenResty / nginx (`lua-nginx-module`)
- **Hard prohibition: no blocking call in the event loop.** An nginx worker serves
  thousands of connections in one thread; one blocking call freezes them all. Vetoed in request
  code: `os.execute`, `io.*` over files, LuaSocket's `socket.*`, any library with synchronous
  I/O, `ngx.sleep` in a busy-wait loop, and C libraries that block. Use **cosockets**
  (`ngx.socket.tcp`), `ngx.timer.at`, `resty.http`, `lua-resty-redis`, `lua-resty-mysql`.
- Each request runs in a **lightweight coroutine** managed by the module: `ngx.thread.spawn` /
  `ngx.thread.wait` to parallelise subrequests; the cosocket object **is not shared between
  requests nor between coroutines**.
- **Life cycle phases**, each with what it may do: `init_by_lua` (master startup:
  preloading modules and immutable data), `init_worker_by_lua` (timers and per-worker state),
  `set_by_lua` (**it blocks, trivial computation only**), `rewrite`/`access_by_lua` (auth, routing),
  `content_by_lua`, `header_filter`/`body_filter_by_lua` (**no I/O**), `log_by_lua` (**no blocking
  cosockets**: use a buffer + timer). Choosing the wrong phase is the most common bug.
- **`ngx.shared.DICT` is the only state shared between workers**: a fixed size declared in
  `nginx.conf`, values only scalars/strings, and it **may evict by LRU when it fills up** — check
  the second return value of `:set()` (`err == "no memory"`) and handle the failure. It is not a
  database and does not replace Redis; it is a process cache with a global lock per operation.
- `lua_code_cache on` in production **always**; `off` only in development (it recompiles every
  request).
- A `require`d module is cached per worker: **module-level state persists between
  requests**. Nothing mutable per request at module level — it is the classic source of data leaks
  between users.
- Prefer `*_by_lua_file` over `*_by_lua_block` as soon as the code goes beyond a few lines: Lua
  embedded in `nginx.conf` is not linted, not tested and not reviewed well.

### Neovim
- The interpreter is **LuaJIT**: you write Lua 5.1 with extensions. Do not assume `goto`, integer
  division nor 5.4 APIs.
- `init.lua` as the single entry point; configuration split into `lua/<user>/*.lua` loaded with
  `require`. No logic in `init.lua` beyond bootstrapping the plugin manager.
- **API**: `vim.api.nvim_*` (stable and typed API) by default; `vim.fn.*` only for Vimscript
  functions with no equivalent; `vim.opt`/`vim.o` for options. **`vim.loop` is deprecated: use
  `vim.uv`** (the same libuv binding). Cache the handle (`local uv = vim.uv`) on hot paths.
- Plugin structure: `lua/<plugin>/init.lua` with an idempotent `M.setup(opts)`,
  `plugin/<plugin>.lua` only for what must run on load, `doc/` with `:help`. **No heavy work at the
  top level of the module**: that runs on `require` and is paid for in startup time.
- Manager: **lazy.nvim**, with `lazy-lock.json` **committed** (it is the lockfile: without it your
  config is not reproducible). Lazy loading by `event`/`ft`/`cmd`/`keys`, not `lazy = false` out of
  convenience.
- Autocommands always in their own `augroup` with `clear = true` — otherwise they duplicate on
  reload.
- Do not block the UI: I/O with `vim.uv` async or `vim.system()`; `vim.schedule` to get back to the
  main thread from a callback. A synchronous `vim.fn.system()` in an autocommand is a frozen editor.

### Redis / Valkey (`EVAL` / `EVALSHA` / Functions)
- The interpreter is **Lua 5.1** with a sandbox: `os`, `io` and system access do not exist.
- **The script is atomic and blocks the whole server while it runs.** Operational corollary:
  scripts are **short and bounded**; no loops over collections of unbounded size, no `KEYS *`,
  no O(n) over large structures. A slow script is a global latency outage.
- **Determinism**: historical and still correct criteria. Today replication is **by effects** (write
  commands are replicated, not the script) — the default since Redis 5.0 and **verbatim replication
  is no longer supported since Redis 7.0**, which relaxes the engine's restriction. **The
  engineering rule does not relax**: do not generate randomness nor read the time inside the script.
  Pass the timestamp and any random value **as an argument (`ARGV`)** from the client: it is
  reproducible, testable and auditable. If you need the server's time, `redis.call('TIME')`, never
  a Lua source.
- **Every key accessed goes in `KEYS`**, never built inside the script: it is the contract
  that makes it work in a cluster (all keys must fall in the same slot; use *hash tags*).
- `local` on every variable: **polluting Lua's global state breaks the server's consistency**.
- Deployment: `SCRIPT LOAD` + `EVALSHA` with a *fallback* to `EVAL` on `NOSCRIPT` (the script cache
  is lost on restart and is not replicated reliably). For stable and versioned logic, **Redis
  Functions** (`FUNCTION LOAD`) is preferable to a loose `EVAL`: it is persisted and replicated.
- Scripts are **code versioned in the repo**, not strings pasted into the application code.

### Games and modding
- Lua embedded in an engine with the explicit purpose of letting **third parties write code**: that
  is §5 and it is not negotiable. Mandatory sandbox, a minimal and audited API surface, and
  CPU/memory budgets.
- The mod's state lives in the host, not in Lua globals; expose functions, not mutable tables of the
  engine. Careful with `__gc` and with retaining references to native objects: it is the usual route
  to *use-after-free* across the C boundary.

### Other hosts (bounded)
**Wireshark** (dissectors in Lua: analysis code that runs over untrusted traffic — treat it
as a hostile parser), **HAProxy** (`lua-load`, the same blocking veto as OpenResty over its event
loop), **Kong** (plugins on OpenResty: apply the OpenResty section as is, plus Kong's plugin life
cycle). For each one, the rule is identical: **read which Lua version it embeds, which
libraries it exposes and which operations block its loop** before writing a line.

## 5. Security: running user Lua is running code

**Starting point, with no qualifications: if you load Lua you did not write yourself, you are
executing arbitrary code inside your process.** The sandbox reduces the damage; it does not
eliminate it.

- **Loading surface**: `load` / `loadstring` / `loadfile` / `dofile` / `require` over untrusted
  content are the sink. Use `load(chunk, name, "t", env)` — the **`"t"` mode (text only) is
  mandatory**: accepting bytecode (`"b"`) is fatal, because **Lua's bytecode verifier is not
  robust** and a malicious precompiled chunk corrupts the interpreter's memory and escapes the
  sandbox without needing any dangerous function.
- **Environment**: in 5.2+ pass an explicit `_ENV` as the fourth argument to `load`; in 5.1/LuaJIT,
  `setfenv` on the loaded function. The environment is an **allowlist** built from scratch, never
  a copy of `_G` with things deleted.
- **Out of the environment, always**: `os` (`execute`, `getenv`, `remove`, `rename`, `exit`,
  `tmpname`), the whole of `io`, `package` and `require` (it allows loading any `.so`), the
  **entire** `debug` (`debug` breaks any sandbox: `getupvalue`/`setupvalue`/`getregistry` give
  access to the host's state), `load`/`loadstring`/`loadfile`/`dofile`, `collectgarbage`,
  `rawset`/`rawget` over host tables, and `string.dump`. From `os`, at most
  `os.time`/`os.clock`/`os.date` if determinism does not matter.
- **Careful with indirect references**: `("").format` reaches the string metatable, which is
  **global and shared**; if the sandbox can modify it, it contaminates the host. Protect the string
  metatable (`debug.setmetatable` in the host, `__metatable` to block `getmetatable`) and freeze the
  environment's tables with `__newindex = function() error(...) end`.
- **A sandbox in pure Lua is never enough**, because it does not bound resources:
  - **CPU**: `while true do end` hangs the process. Mitigation: an instruction-counting hook
    (`debug.sethook(co, fn, "", N)`) that aborts on exceeding the budget — installed **from the
    host**, over a coroutine, and knowing that `debug` itself must not be exposed to the guest.
    It is a partial mitigation: there are operations (`string` patterns, huge concatenations) that
    burn a lot of time in few instructions.
  - **Memory**: a table that grows without limit exhausts the host's RAM. Real mitigation: **an
    allocator with a limit** (`lua_newstate` with your own allocator that fails on exceeding the
    quota) — done in C, not in Lua.
  - **Patterns**: `string.find`/`gsub` with user patterns over large inputs are a DoS
    (backtracking). Do not accept user patterns; if you must, bound the length of the pattern and
    the subject.
- **Real isolation**: for genuinely untrusted code, the control that cuts is **the
  process**: an interpreter in a separate process, unprivileged, with `rlimit` on CPU/memory/files,
  seccomp and no network, and communication over bounded IPC. The in-process sandbox is defence in
  depth, not the boundary.
- **Classic injection**: never build Lua code by concatenating input (`load("return "..x)`) — it is
  `eval` by another name. Never build SQL, commands or paths by concatenation from Lua.
- **Secrets**: outside the code and outside `nginx.conf`; in OpenResty they come in via the
  environment (`env` + `os.getenv` in `init_by_lua`) or via a fetch at startup, and **never into
  `ngx.shared.DICT` nor into logs**. Careful with dumping context tables into error logs: they carry
  tokens.
- **SCA**: LuaRocks has no auditing ecosystem comparable to npm/PyPI. Practical consequence:
  minimise dependencies, pin exact versions in the `.rockspec`, and **review the code** of rocks
  with C extensions that go into production.

## 6. Performance and operability

- Profile before optimising; in LuaJIT, first check that your hot path **compiles** (`-jv`,
  `-jdump`): a bail-out to the interpreter due to an NYI construct costs more than any
  micro-tuning.
- Real and measurable cost: concatenation in a loop is O(n²) (accumulate in a table and
  `table.concat`); a global is a hash lookup (cache `local ngx = ngx`, `local fmt = string.format`
  in the module).
- **Explicit timeouts on all I/O**: `settimeout`/`set_timeouts` on every cosocket; the default in
  many libraries is too high or infinite. Retries with backoff only on idempotent operations.
- Observability: structured logs with a correlation id (in OpenResty, `ngx.var.request_id`);
  per-worker metrics via `ngx.shared.DICT` on an internal endpoint. An error that only appears in
  `error.log` with no level and no context is an invisible incident.
- Watch `collectgarbage("count")` as a metric: in long-lived hosts, monotonic growth is the
  symptom of accumulated globals or retained closures. In OpenResty, changing the Lua requires a
  `reload`: design startup to be cheap and idempotent.

## 7. Sustainability and prohibitions

- **Cadence**: LuaJIT is updated by following the `v2.1` branch with dated snapshots and a review of
  the changes, not once a year. Lua 5.4/5.5 are updated by patch without drama; the branch jump
  (5.1→5.4, 5.4→5.5) is a **project**, not a version bump.
- Every dependency with no release in >18 months is reviewed (this applies today to `luacheck`);
  every C extension is audited before it goes in.
- Migrate from LuaJIT to Lua 5.4 only with a reason (you genuinely need 5.4) and with measurement:
  you lose the JIT and the FFI, and that can be an order of magnitude on the hot path.

**List of prohibitions (veto):**
- ❌ Implicit global variables. `local` or a written justification in the code.
- ❌ **FORBIDDEN** any blocking call in the OpenResty/HAProxy event loop
  (`os.execute`, `io.*`, LuaSocket, synchronous C libraries). It is an outage, not a *code smell*.
- ❌ **FORBIDDEN** `load`/`loadstring` with a mode that accepts bytecode (`"b"`/`"bt"`) over
  untrusted input. Only `"t"`.
- ❌ **FORBIDDEN** to expose `debug`, `package`, `require`, `os` or `io` to untrusted code; and
  **FORBIDDEN** to treat a pure-Lua sandbox as a security boundary without CPU/memory limits
  imposed from the host.
- ❌ Building Lua code, SQL or commands by concatenating input.
- ❌ Randomness or reading the clock inside a Redis/Valkey script; keys not declared in
  `KEYS`; scripts with unbounded loops.
- ❌ A `pcall` whose error is discarded with no log and no propagation.
- ❌ Per-request mutable state at module level in OpenResty; globals that persist between requests.
- ❌ Relying on `#t`/`ipairs` over tables with holes.
- ❌ Publishing/deploying without `lazy-lock.json` (Neovim) or without pinned versions in the
  `.rockspec`.
- ❌ Lua embedded in `nginx.conf` beyond a few lines (use `*_by_lua_file`).
- ❌ `lua_code_cache off` in production.
- ❌ Third-party LuaJIT tarballs or GitHub's automatic tarball; the `v2.1.ROLLING` tag as a pin.
- ❌ **Choosing Lua for new code that is not embedded in a host that requires it.** Lua shines as an
  extension language inside somebody else's process; as a standalone application language, its
  ecosystem (packages, auditing, types, minimal standard library) is a cost that almost never pays
  off against Python or Go.

## 8. Mandatory web verification

Before committing to versions or APIs, **verify online** (WebSearch/WebFetch, and the Atom feeds
`https://github.com/OWNER/REPO/releases.atom` — `api.github.com` returns 403 unauthenticated):
1. **LuaJIT**: activity on the `v2.1` branch (recent commits) and the project's status at
   `luajit.org/status.html`.
   It is the datum that decides whether a new project can rest on it. There are no release tags: do
   not look for one.
2. **Lua**: `lua.org/news.html` and `lua.org/versions.html` — the latest of 5.4, the status and
   adoption of **5.5.0** (published on 22 Dec 2025), and whether 5.5.1 or 5.4.9 have come out.
3. Versions and **raw licences** of StyLua and selene (**both MPL-2.0**, not MIT), LuaLS, Teal,
   busted and LuaRocks; and whether `luacheck` has published a release again.
4. The version of **OpenResty** and of `lua-nginx-module` (as of Aug 2026 the 0.10.32 branch was in
   *release candidate*: do not pin an `rc` in production without checking whether there is already a
   final).
5. **Neovim**: stable version (0.12.x as of Aug 2026) and the deprecation list (`:help deprecated`)
   before writing a plugin — `vim.loop`→`vim.uv` is not the only one.
6. **Redis/Valkey**: the Lua version embedded in the specific version you deploy and the state of
   Functions vs `EVAL`; the replication rules changed in 5.0 and 7.0.
7. CVEs of the interpreter and of the C extensions you use (osv.dev / GitHub Advisories).

**Declared discrepancy**: LuaRocks' releases Atom feed shows a feed `updated`
(2025-12-28) earlier than that of its most recent entry (LuaRocks 3.13.0, `updated` 2026-01-28).
Version 3.13.0 is taken as good; **its publication date is not verified** — confirm it at
`luarocks.org` before citing it.

If the web contradicts this document, **the web wins** — flag the discrepancy.
