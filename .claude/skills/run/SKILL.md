---
name: run
description: Launch the current build of the Outpost Nova game in the Godot editor
---

> **Never invoke `godot` / `godot_console` from PATH.** Those are WinGet shims in
> `%LOCALAPPDATA%\Microsoft\WinGet\Links`; Godot looks for its bundled `GodotSharp\`
> next to the executable it was launched as, doesn't find it through the shim, and
> crashes with `.NET: Assemblies not found (gd_mono.cpp:650)` / signal 11. Always go
> through `tools/godot.ps1`, which resolves the real executable inside the WinGet
> package directory (override with `$env:GODOT_BIN`). Add `-Console` to attach
> stdout/stderr.

Determine whether you are running inside a git worktree or the main repo:

```sh
git rev-parse --git-dir
git rev-parse --git-common-dir
```

If the two outputs differ, you are in a linked worktree; if they match, you are in the main repo. (Orca-managed worktrees live under `~\orca\workspaces\`.)

**If inside a worktree**:

1. Kill any running Godot instance
2. Rebuild C# assemblies from the worktree directory:
   ```sh
   dotnet build "Outpost Nova.csproj"
   ```
3. Sync all `.import` sidecar files and the `.godot/imported/` cache from the main repo:
   ```sh
   Copy-Item "C:\Code\outpost-nova\data\dialogue\*.import" -Destination ".\data\dialogue\" -Force
   Copy-Item -Recurse "C:\Code\outpost-nova\.godot\imported\*" -Destination ".\.godot\imported\" -Force
   ```
4. Delete ONLY the compiled YarnProject `.tres` — keep `outpost-nova.yarnproject.import` intact. The `.import` file contains `importer="yarnproject"` which tells Godot to invoke the C# YarnSpinner importer. Deleting the `.import` (or both files) causes headless import to use a generic loader that omits `CompiledYarnProgramBase64`, breaking all dialogue. Deleting just the `.tres` forces a fresh recompile from the worktree's current `.yarn` source files:
   ```sh
   rm -f .godot/imported/outpost-nova.yarnproject-84d4224ec9fa642355d762aa911363c0.tres
   C:\Code\outpost-nova\tools\godot.ps1 -Console --headless --editor --quit --path <worktree_path>
   ```
   This works whether or not `.yarn` files were modified in the worktree.
5. Launch the game from the worktree:
   ```sh
   Start-Process pwsh -ArgumentList "-NoProfile","-File","C:\Code\outpost-nova\tools\godot.ps1","--path","<worktree_path>"
   ```

**If in the main repo**:

1. Run a headless import to ensure the class cache is up to date (required after any `git pull` that adds new `class_name` scripts — skipping this causes parse errors at runtime):
   ```sh
   ./tools/godot.ps1 -Console --headless --editor --quit --path C:\Code\outpost-nova
   ```
2. Launch the game:
   ```sh
   Start-Process pwsh -ArgumentList "-NoProfile","-File","C:\Code\outpost-nova\tools\godot.ps1","--path","C:\Code\outpost-nova"
   ```

Report to the user that the game is launching.
