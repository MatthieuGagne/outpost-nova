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
3. Sync `.import` sidecar files from the main repo (required for YarnSpinner dialogue and other C#-imported assets):
   ```sh
   rsync -a /home/mathdaman/code/outpost-nova/data/dialogue/*.import ./data/dialogue/
   rsync -a /home/mathdaman/code/outpost-nova/.godot/imported/ ./.godot/imported/
   ```
4. Reimport the YarnProject — the rsync overwrites `outpost-nova.yarnproject.import` with the main repo's version, which breaks any `.yarn` files added in the worktree:
   ```sh
   rm -f data/dialogue/outpost-nova.yarnproject.import
   godot --headless --import --path <worktree_path>
   ```
5. Restore the compiled YarnProject — the headless import regenerates the compiled `.tres` without the `CompiledYarnProgramBase64` field, breaking dialogue. Copy the main repo's compiled resource back:
   ```sh
   cp /home/mathdaman/code/outpost-nova/.godot/imported/outpost-nova.yarnproject-84d4224ec9fa642355d762aa911363c0.tres \
      <worktree_path>/.godot/imported/outpost-nova.yarnproject-84d4224ec9fa642355d762aa911363c0.tres
   ```
6. Launch the game from the worktree:
   ```sh
   godot --path <worktree_path> &
   ```

**If in the main repo**:

```sh
cd /home/mathdaman/code/outpost-nova && godot &
```

Report to the user that the game is launching.
