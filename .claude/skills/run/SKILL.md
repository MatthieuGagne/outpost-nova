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
   rsync -a /home/mathdaman/code/outpost-nova/data/dialogue/*.import ./data/dialogue/
   rsync -a /home/mathdaman/code/outpost-nova/.godot/imported/ ./.godot/imported/
   ```
4. Delete ONLY the compiled YarnProject `.tres` — keep `outpost-nova.yarnproject.import` intact. The `.import` file contains `importer="yarnproject"` which tells Godot to invoke the C# YarnSpinner importer. Deleting the `.import` (or both files) causes headless import to use a generic loader that omits `CompiledYarnProgramBase64`, breaking all dialogue. Deleting just the `.tres` forces a fresh recompile from the worktree's current `.yarn` source files:
   ```sh
   rm -f .godot/imported/outpost-nova.yarnproject-84d4224ec9fa642355d762aa911363c0.tres
   godot --headless --import --path <worktree_path>
   ```
   This works whether or not `.yarn` files were modified in the worktree.
5. Launch the game from the worktree:
   ```sh
   godot --path <worktree_path> &
   ```

**If in the main repo**:

```sh
cd /home/mathdaman/code/outpost-nova && godot &
```

Report to the user that the game is launching.
