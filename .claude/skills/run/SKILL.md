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
3. Sync non-Yarn `.import` sidecar files from the main repo (required for textures and other C#-imported assets — but NOT the YarnProject, which must always be compiled fresh from source):
   ```sh
   rsync -a --exclude='outpost-nova.yarnproject*' /home/mathdaman/code/outpost-nova/data/dialogue/*.import ./data/dialogue/
   rsync -a /home/mathdaman/code/outpost-nova/.godot/imported/ ./.godot/imported/
   ```
4. Always compile the YarnProject fresh from this worktree's `.yarn` source files — never copy the compiled resource from the main repo, as it may be stale:
   ```sh
   rm -f data/dialogue/outpost-nova.yarnproject.import
   rm -f .godot/imported/outpost-nova.yarnproject-84d4224ec9fa642355d762aa911363c0.tres
   godot --headless --import --path <worktree_path>
   ```
   The `CompiledYarnProgramBase64` field is populated by the C# YarnSpinner importer when dotnet assemblies are built first (step 2).
5. Launch the game from the worktree:
   ```sh
   godot --path <worktree_path> &
   ```

**If in the main repo**:

```sh
cd /home/mathdaman/code/outpost-nova && godot &
```

Report to the user that the game is launching.
