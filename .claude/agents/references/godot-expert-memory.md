# Godot Expert Memory — Outpost Nova

Repo-local, version-controlled memory for the `godot-expert` agent. Read by the agent at task start
(see `.claude/agents/godot-expert.md`), which appends confirmed API gotchas here **alongside the work
that produced them** — never as a detached cleanup commit. Each entry dates its last confirmation and
names what would falsify it, because engine behaviour changes silently.

**How to read this file:** do not load it whole. `Grep` the `## Index` for the topic, then `Read`
only the matching section. Every entry is a self-contained `##` section; the index is the single
source of entry titles and one-line gists. When an entry grows stale, date the correction rather than
silently rewriting history.

## Index

| Topic | Section |
|---|---|
| New `class_name` invisible to GUT until the class cache is rebuilt | [A new `class_name` is invisible to GUT until the class cache is rebuilt](#a-new-class_name-is-invisible-to-gut-until-the-class-cache-is-rebuilt) |
| `AABB.intersects_segment()` returns `Vector3`/`null`, not `bool` | [AABB.intersects_segment() returns Vector3/null, not bool](#aabbintersects_segment-returns-vector3null-not-bool) |
| `_initialize()` never fires on a `-s` `SceneTree` script | [_initialize() never fires on a SceneTree -s script — use _init()](#_initialize-never-fires-on-a-scenetree--s-script--use-_init) |
| `detect_3d/compress_to` blurs pixel art in 3D | [detect_3d/compress_to blurs pixel art the first time a texture is used in 3D](#detect_3dcompress_to-blurs-pixel-art-the-first-time-a-texture-is-used-in-3d) |
| `load().instantiate()` returns Variant — `:=` cannot infer | [load(path).instantiate() returns Variant — := cannot infer it](#loadpathinstantiate-returns-variant----cannot-infer-it) |
| GUT prints "All tests passed" for a silently skipped file | [GUT prints "All tests passed" for a file it silently skipped](#gut-prints-all-tests-passed-for-a-file-it-silently-skipped) |

---

## A new `class_name` is invisible to GUT until the class cache is rebuilt

Creating a script with `class_name Foo` and immediately running GUT produces
`Parse Error: Identifier "Foo" not declared in the current scope` — even though the file exists and
is correct. Running `-s addons/gut/gut_cmdln.gd` does NOT trigger the rescan, and neither does a
plain `--headless --path . --quit`. Godot's `.godot/global_script_class_cache.cfg` must be rebuilt by
an editor filesystem scan first:

```powershell
./tools/godot.ps1 -Console --headless --path . --editor --quit
```

then re-run the GUT command. Symptom looks exactly like a typo or a missing file, so it costs a
debugging round every time it is hit fresh.

Note the same scan is what generates a new script's `.gd.uid` sidecar — a headless GUT run alone
will not produce one.

**Every git worktree has its own `.godot/`**, so the cache is cold there even when the main checkout
is warm — a worktree pays this cost once per new `class_name`, not once per repo. #103 hit it four
times in one session (`InteractScan`, `PocConsole`, `ExitDoor`, `PocDialogueLine`, `InteractTarget`);
budget one rebuild per new class when planning.

Confirmed 2026-09-05, Godot 4.7.1 mono (#103) — plain `--editor --quit` suffices, `--quit-after 2` is
not required. Falsified if a future Godot version rescans on `-s` script execution.

---

## AABB.intersects_segment() returns Vector3/null, not bool

In GDScript in this build it returns the intersection point, or `null` when there is no hit — so
`if aabb.intersects_segment(a, b) == true` silently never fires. Test with `!= null`.

Confirmed 2026-08-28, Godot 4.7.1 mono (#101). Falsified if the GDScript binding changes to return a
plain bool.

---

## _initialize() never fires on a SceneTree -s script — use _init()

A script run via `godot -s` that extends `SceneTree` will silently do nothing if the entry point is
`_initialize()`. Use `_init()` — that is the pattern GUT's own `addons/gut/gut_cmdln.gd` uses. This
is the standard shape for one-off headless verification scripts in this project.

Confirmed 2026-08-28, Godot 4.7.1 mono (#101). Falsified if the `SceneTree` main-loop entry point
changes.

---

## detect_3d/compress_to blurs pixel art the first time a texture is used in 3D

Godot re-imports a texture the first time it appears in a 3D material, switching it to VRAM block
compression with mipmaps — blurry mush on pixel art — and rewrites the `.import` file in place. Since
this repo tracks `.import` metadata in git, that also produces a mystery diff.

Before using any existing 2D texture in a 3D material, set `detect_3d/compress_to=0` in its
`.import` (leave `compress/mode=0` and `mipmaps/generate=false` as they are) and commit that
deliberately. Applies to every new texture PRDs #102-#104 pull into 3D, not just the ones already
fixed.

Separately: `rendering/textures/canvas_textures/default_texture_filter=0` in `project.godot` is
**2D-only**. Every 3D material must set `texture_filter = TEXTURE_FILTER_NEAREST` explicitly or pixel
art renders smoothed.

Confirmed 2026-08-28, Godot 4.7.1 mono (#101). Falsified if Godot stops auto-reimporting on first 3D
use, or if the canvas texture-filter setting is extended to 3D materials.

---

## load(path).instantiate() returns Variant — := cannot infer it

`var node := load(SCENE).instantiate()` is a **parse error**: `Cannot infer the type of "node"
variable because the value doesn't have a set type`. Same for `find_child()`, `get_node_or_null()`
on an untyped receiver, and `get_node()` with a non-literal path. Three ways out, in order of
preference:

- The scene root has a `class_name` → `var node: PocConsole = load(SCENE).instantiate()`.
- It does not, but you only need Node API → `var node: Node = load(SCENE).instantiate()`.
- You must call a *script* method the static type does not declare (e.g. `hud.show_message()`,
  `npc.speaker_name`) → leave it **untyped** with a comment saying why. Typing it as the engine
  class (`CanvasLayer`, `Node3D`) makes the member unresolvable; GDScript defers that to runtime, so
  it fails when the line executes rather than when the file parses.

Cost 4 separate fixes in #103 — worth writing correctly the first time in plans and tests.

Confirmed 2026-09-05, Godot 4.7.1 mono (#103). Falsified if GDScript gains inference through
`instantiate()` from the loaded scene's root type.

---

## GUT prints "All tests passed" for a file it silently skipped

A parse error in a test script makes GUT log `Ignoring script ... because it does not extend GutTest`
and carry on — the run summary still ends with `---- All tests passed! ----`. In #103 the suite
reported success at **162** tests when the true count was 191: one file failed to parse and vanished
from the run.

**The banner is not evidence. The `Scripts` and `Tests` counts are.** Watch for the count dropping
between runs, and grep for `SCRIPT ERROR` / `Nothing was run` alongside every headless invocation:

```powershell
./tools/godot.ps1 -Console --headless --path . -s addons/gut/gut_cmdln.gd "-gdir=res://tests" -gexit 2>&1 |
  Select-String -Pattern "SCRIPT ERROR|Failing Tests|Passing Tests|Scripts "
```

Confirmed 2026-09-05, Godot 4.7.1 mono, GUT (#103). Falsified if GUT starts failing the run on an
uncollectable script.
