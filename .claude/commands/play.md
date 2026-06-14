---
description: Launch the game in a window (starts at the Intro main scene)
---
Launch the Godot game so the user can play it.

Run, in the background so this session stays interactive (the project root is this
repo, so `--path .`):

`godot --path .`

Report the launched PID. If the process exits immediately, surface its output —
that almost always means a GDScript parse/runtime error worth fixing.

Notes for this project:
- Main scene is `res://scenes/Intro.tscn` (the isekai cold-open), which hands off to
  the town. To skip straight to a scene, pass it explicitly, e.g.
  `godot --path . res://scenes/World.tscn`.
- Controls: WASD/arrows move · Space/Enter interact · C status window · F inspect.
