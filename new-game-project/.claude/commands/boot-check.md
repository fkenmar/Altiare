---
description: Headless-boot scenes and report any GDScript errors (a quick smoke check)
argument-hint: "[World | Dungeon | Intro | all]  (default: all)"
---
Quick smoke check: boot scenes headless and confirm a clean run (only the engine
banner, no parse/runtime errors). For the FULL gate (this + unit tests), use `/qa`.

For each scene to check, run:

`godot --headless --path . --quit-after 120 res://scenes/<Scene>.tscn`

`--quit-after 120` runs ~120 frames then exits, so each boot self-terminates.

Scenes to check: $ARGUMENTS
- If empty or "all", check `World`, `Dungeon`, and `Intro` (the three entry points).
- Otherwise check exactly the scene(s) named.

Report pass/fail per scene. For any failure, show the offending error line(s) and the
script/scene they point to. Boots exit 0 even on error, so judge by the output text,
not the exit code.
