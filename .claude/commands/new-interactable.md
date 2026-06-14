---
description: Scaffold a new "stand on it, press Space" interactable (script + Town.tscn node)
argument-hint: "<Name>  e.g. Chest, Well, Shrine  (PascalCase)"
---
Scaffold a new interactable following this project's existing pattern (see
`scripts/Bed.gd`, `scripts/QuestBoard.gd`, `scripts/GardenPlot.gd`). The name is:
**$ARGUMENTS** (PascalCase, e.g. `Chest`). If it's empty, ask for the name first.

## Critical conventions (don't deviate — these are how the codebase works)

- **Interactables have NO standalone `.tscn`.** Each is a script extending
  `res://scripts/Interactable.gd` plus an `Area2D` node placed directly inside
  `scenes/Town.tscn`. Do not create a `scenes/<Name>.tscn`.
- The base class (`Interactable.gd`) already wires `body_entered`/`body_exited`,
  tracks player overlap, routes the prompt to the HUD via `GameState.prompt_changed`,
  and calls `_interact()` on the `ui_accept` action. The subclass only sets `prompt`
  (in `_on_ready()`) and overrides `_interact()`. For a prompt that depends on state,
  override `get_prompt()` instead of setting a fixed `prompt` (see `GardenPlot.gd`).
- The Area2D node MUST use `collision_layer = 0` and `collision_mask = 2` (the player
  layer) so only the player trips it.
- Talk to the rest of the game only through `GameState` (call its mutation methods;
  emit `GameState.message_shown` for a transient line). Never reach across the tree.

## Step 1 — create `scripts/$ARGUMENTS.gd`

Use this skeleton (fill in the prompt text, the action, and the sprite):

```gdscript
extends "res://scripts/Interactable.gd"

## <one-line description of what this does — comment the WHY>

const PixelArt = preload("res://scripts/PixelArt.gd")

@onready var _visual: Sprite2D = $Visual

func _on_ready() -> void:
	prompt = "<verb shown after [Space], e.g. 'open the chest'>"
	_visual.texture = PixelArt.sign()  # placeholder — see Step 3

func _interact() -> void:
	# Do the thing. Talk to the world via GameState, e.g.:
	GameState.message_shown.emit("You interact with the $ARGUMENTS.")
```

## Step 2 — wire it into `scenes/Town.tscn`

Edit `scenes/Town.tscn` (it's a text `.tscn`), making THREE additions. Bump
`load_steps` in the header line by the number of new resources you add (1 script +
1 shape = +2).

1. A script `ext_resource` near the others (top of file), with a unique id:
   ```
   [ext_resource type="Script" path="res://scripts/$ARGUMENTS.gd" id="N_<lower>"]
   ```
2. A collision shape `sub_resource` near the other shapes:
   ```
   [sub_resource type="RectangleShape2D" id="$ARGUMENTSShape"]
   size = Vector2(32, 32)
   ```
3. The node block, placed BEFORE the `Player` node (so y-sort works). Choose a
   `position` that doesn't overlap existing nodes — first read `Town.tscn` (occupied:
   HouseEntrance 176,112 · DungeonDoor 336,112 · NPC 224,240 · QuestBoard 400,240 ·
   Player spawn 320,240 · GardenPlot 224,336 · Bed 464,336) and `Town.gd`'s `DECOR`
   array, then pick a free interior spot (interior is ~x 48–592, y 48–432; walls are
   the 32px border). Block:
   ```
   [node name="$ARGUMENTS" type="Area2D" parent="."]
   position = Vector2(<x>, <y>)
   collision_layer = 0
   collision_mask = 2
   script = ExtResource("N_<lower>")

   [node name="Visual" type="Sprite2D" parent="$ARGUMENTS"]

   [node name="CollisionShape2D" type="CollisionShape2D" parent="$ARGUMENTS"]
   shape = SubResource("$ARGUMENTSShape")
   ```

## Step 3 — the sprite

`PixelArt.gd` generates all art in code. Reuse an existing generator if one fits
(`bed()`, `sign()`, `house()`, `cave()`, `tree()`, `bush()`, `rock()`, `tilled(stage)`,
`creature(kind)`, `character(...)`). If none fits, add a new deterministic generator
to `PixelArt.gd` matching the existing palette/outline style and call it from
`_on_ready()`. A reused placeholder is fine to start — prove it works, then prettify.

## Step 4 — verify

If this added interactable *logic* (a new GameState mutation, a reward, a state
machine), add an assertion for it in `tests/test_game_state.gd`. Then run the full
gate and confirm it's clean:

`bash .claude/hooks/qa.sh`

Then tell me the new interactable's name, where you placed it, what its prompt says,
and what pressing Space does — so I can walk onto it and try it.
