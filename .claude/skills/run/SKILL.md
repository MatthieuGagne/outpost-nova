---
name: run
description: Launch the current build of the Outpost Nova game in the Godot editor
---

Determine whether you are running inside a git worktree or the main repo:

```sh
pwd
```

**If inside a worktree** (path contains `.claude/worktrees/`):

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
   godot_console --headless --editor --quit --path <worktree_path>
   ```
   This works whether or not `.yarn` files were modified in the worktree.
5. Launch the game from the worktree:
   ```sh
   Start-Process godot_console -ArgumentList "--path <worktree_path>"
   ```

**If in the main repo**:

1. Run a headless import to ensure the class cache is up to date (required after any `git pull` that adds new `class_name` scripts — skipping this causes parse errors at runtime):
   ```sh
   godot_console --headless --editor --quit --path C:\Code\outpost-nova
   ```
2. Launch the game:
   ```sh
   Start-Process godot_console
   ```

Report to the user that the game is launching.
