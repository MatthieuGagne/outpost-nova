# 3D presentation POC

Standalone proof-of-concept for epic #100 (Xenogears-style presentation). Nothing here is reachable from the 2D game: `main.tscn`, `go_to_area()` and the seven existing areas are untouched, and `project.godot` still boots `scenes/character_creation.tscn`.

## Running it

```powershell
./tools/godot.ps1 --path . "res://scenes/poc3d/poc_entry.tscn"
```

Quote the `res://` argument — PowerShell splits an unquoted one on the colon.

To also see renderer warnings on the console:

```powershell
./tools/godot.ps1 -Console --path . "res://scenes/poc3d/poc_entry.tscn"
```

Opening `scenes/poc3d/poc_entry.tscn` in the editor and pressing F6 also works.

## Shape

| File | Role |
|------|------|
| `poc_entry.tscn` | The 480x270 `SubViewport` render target, with `hud.tscn` as a sibling above it |
| `rooms/test_room.tscn` | Greybox geometry, one directional light, the camera |
| `room_camera.tscn` | The per-room camera contract — FOV/pitch/yaw from `WorldScale` |
| `scripts/poc3d/world_scale.gd` | Every constant. 16 px = 1 world unit |

The HUD must never be moved inside the `SubViewport`; see the comment in `scripts/poc3d/poc_entry.gd`.
