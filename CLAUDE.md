# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A ColdBox 8 (HMVC framework) application running on the **BoxLang** runtime (not Lucee/Adobe CF), served via CommandBox. It's a Dungeons & Dragons style game demo. CBWIRE (a Livewire-style reactive component module) is installed, and the actual game UI is being built as a CBWIRE "wire" component at `app/wires/default.bx`, rendered via `wire(name="default")` from `app/views/main/index.bxm` inside the themed layout at `app/layouts/Main.bxm`.

## Commands

Requires CommandBox (`box`) and the BoxLang OS runtime installed locally.

```bash
box server start          # start the dev server (see server.json for port/config)
box server restart         # restart after changing runtime/boxlang.json, vendor lib/ files, or module config
box server stop
box server log             # tail the running server's console/log output
```

Reinitialize the ColdBox app (needed after changing `app/config/*.bx` files) by hitting any URL with `?fwreinit=1`.

Testing (TestBox, runner defined in `box.json` -> `tests/runner.bxm`):
```bash
box testbox run                                            # run all specs in tests/specs
box testbox run bundles=tests.specs.integration.MainSpec    # run a single bundle
box testbox run directory=tests.specs.unit                  # run only a subfolder
```

Formatting:
```bash
box run-script format         # format app/, tests/specs/, and root *.bx files
box run-script format:check   # check formatting without writing
```

Linting: `.cflintrc` configures CFLint rules; run via your editor's CFLint integration or `box cflint`.

Docker (optional, see `box.json` scripts): `box run-script docker:build|docker:run|docker:bash|docker:stack`.

Production build/package: `boxlang Build.bx` (see `readme.md` for customizing `variables.sources`/`variables.excludes`).

## Architecture

- `public/` is the actual webroot. `public/index.bxm` is an empty front-controller stub; `public/Application.bx` bootstraps ColdBox (`coldbox.system.Bootstrap`) and delegates `onRequestStart`/session/application lifecycle events into it. Don't confuse this with `app/handlers/Main.bx`'s implicit lifecycle methods (`onAppInit`, `onRequestStart`, etc.) — those are ColdBox-level implicit events, declared separately in `app/config/Coldbox.bx`.
- `app/` holds all real application code by ColdBox convention: `handlers/` (controllers), `models/`, `views/`, `layouts/`, `wires/` (CBWIRE components), `config/` (`Coldbox.bx`, `Router.bx`, `WireBox.bx`, `CacheBox.bx`, `Scheduler.bx`).
- `runtime/boxlang.json` is the BoxLang **engine-level** config: mappings (`/app`, `/wires`, `/coldbox`, `/modules`, etc.), datasources, module settings, logging. This is distinct from ColdBox's own config in `app/config/`. When something can't be found via a dot-path (`getInstance()`, `new`, `expandPath("/x/y")`), check here first — a missing top-level mapping is a common cause.
- `lib/` contains vendor dependencies managed by CommandBox (`box install`): `coldbox/` (framework core), `testbox/`, `modules/cbwire/` (with `cbstorages` nested inside it per its own dependency install path), `modules/route-visualizer/`.
- Routing: `app/config/Router.bx` has a few explicit example routes plus a catch-all conventions-based route (`:handler/:action?`).

## BoxLang vs Lucee/Adobe CF metadata quirks (important, non-obvious)

This app runs on BoxLang, but ColdBox 8 and CBWIRE 5 were primarily written/tested against Lucee/Adobe CF metadata shapes. Several BoxLang-specific incompatibilities have already been found and patched **directly in vendor files under `lib/`** (these are NOT app bugs, and will be silently reverted by any future `box install`/upgrade of `coldbox` or `cbwire` — re-check after any dependency update):

1. **`lib/coldbox/system/web/services/InterceptorService.cfc`** (`parseMetadata()`): custom function annotations (e.g. `eventPattern="..."` on an interceptor method) are nested under `metadata.functions[x].annotations` on BoxLang, but read directly off `metadata.functions[x]` in the original code (which is where Lucee/ACF puts them). Without the fix, any module interceptor using `eventPattern` fires globally instead of being scoped — this broke the whole app when CBWIRE was installed (its `preProcess` interceptor was rejecting every non-Livewire request with a blank HTTP 400). Fixed by normalizing to `fnMeta.keyExists("annotations") ? fnMeta.annotations : fnMeta` before reading `async`/`asyncPriority`/`eventPattern` — mirroring the same fallback already used elsewhere in ColdBox core (`Matcher.cfc`, `Mapping.cfc`).
2. **`lib/modules/cbwire/views/RendererEncapsulator.cfm`** (`addPublicMethods`/`addComputedProperties`): these recurse up a component's `extends` chain via `getMetadata()`. On BoxLang, the terminal (top-of-hierarchy) metadata struct still has an `extends` key but no `functions` key at all, unlike Lucee/ACF where `extends` is simply absent once there's nothing left. Fixed with an early-return guard (`if (!_metaData.keyExists("functions")) return;`) before iterating.
3. `runtime/boxlang.json` needs an explicit `/wires` mapping (`{"path": "${user-dir}/app/wires", "external": false}`) for CBWIRE's `wire()` helper to resolve components by dot-path (`wires.default`) — this isn't registered by default and must be added manually alongside the standard `/app`, `/modules`, etc. mappings.

If you hit a stack trace mentioning `ortus.boxlang.runtime.types.exceptions.*` inside `lib/coldbox` or `lib/modules/cbwire` code paths, suspect this class of engine/vendor metadata mismatch before assuming it's an app-level bug.
