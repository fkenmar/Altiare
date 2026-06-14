# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Project context — read this first, every session.

---

## What this is

A cozy isekai slow-life RPG. You're summoned into a fantasy world as a level-1
nobody, build a quiet daily life in a frontier village, and snowball into the
region's strongest by descending the nearby dungeon.

**One-line vision:** Stardew's daily rhythm fused with an isekai progression fantasy.

**This is a for-fun project.** The only success metric is "am I enjoying building
and playing it." No audience, no roadmap pressure, no business model. Optimize for
momentum and fun, not completeness or polish.

---

## Locked design decisions

These are settled. Don't relitigate them unless I explicitly ask.

- **Genre:** top-down cozy RPG, Stardew-like loop, isekai framing.
- **Core loop:** wake up → spend energy on activities (town + dungeon) → sleep →
  world advances → repeat, stronger.
- **Tone:** cozy-village-first. The town is the heart; the dungeon is spice you
  visit to grow so you can do more in town. NOT a grindy dungeon-crawler.
- **Cheat ability (signature mechanic):** the **Status Window** — the player can
  see and manipulate numbers. Inspect any enemy's exact stats, freely reallocate
  their own points, see values float over the world. Peak isekai, and it's the
  optimization toy the game is built around. Diegetic UI: the RPG menus ARE the
  character's power, not video-game chrome bolted on.
- **D&D is flavor, not rules.** Classes, dice, builds, stats — yes. The 5e
  rulebook — no. We design our own combat system we fully control.
- **Combat is seasoning, not the meal.** Keep it dead simple (walk into monster,
  swing, numbers happen). Depth lives in the daily rhythm and the snowball.

---

## Tech stack

- **Engine:** Godot 4.x, GDScript.
- **Rendering:** top-down 2D, `TileMap` for the world.
- **Art:** free tilesets/sprites from itch.io. Do not hand-draw art. A sliding
  square is an acceptable placeholder — prove the loop before prettifying.
- **State:** a single autoload singleton (`GameState.gd`) holds the global game
  state (`day`, `energy`, later: stats, inventory). Every system hangs off this.

---

## Commands

This folder IS the Godot project root and the git repo root, so run Godot with
`--path .` (run Claude from here too). Godot 4.6 lives at `/opt/homebrew/bin/godot`.

```bash
# Play the game (opens a window; starts at the Intro main scene)
godot --path .

# Open the editor
godot -e --path .

# Run the unit tests — real exit code (0 pass / 1 fail). See "Quality workflow".
godot --headless --path . --script res://tests/runner.gd

# Smoke-boot a scene headless and auto-quit (catches load/parse errors)
godot --headless --path . --quit-after 120 res://scenes/World.tscn
godot --headless --path . --quit-after 120 res://scenes/Dungeon.tscn
godot --headless --path . --quit-after 120 res://scenes/Intro.tscn

# Full quality gate (unit tests + all scene boots) — also available as /qa
bash .claude/hooks/qa.sh
```

`--quit-after N` runs N frames then exits, so headless boots self-terminate. There's
no separate build step (GDScript is interpreted); "building" only matters when
exporting, which this for-fun project doesn't do.

---

## Architecture (how the code fits together)

**Scene flow.** `Intro.tscn` (the main scene) → `World.tscn` → `Dungeon.tscn` →
back to `World.tscn`. `World.tscn` is a composition: it instances `Town.tscn` +
`HUD.tscn` together. Returning from the dungeon (on faint or via the exit) loads
`World.tscn` directly, so the isekai intro plays only once. Transitions are plain
`get_tree().change_scene_to_file(...)`; all persistent state survives because it
lives on the `GameState` autoload, not in any scene.

**`GameState.gd` is the hub.** The only autoload. Holds the day/energy loop, RPG
stats, and progression, and exposes mutation methods (`sleep`, `take_damage`,
`gain_xp`, `allocate_point`, `plant_crop`, `claim_bounty`, …). Derived stats
(`max_hp()`, `attack_power()`) are computed from reallocatable primaries — that's
what lets the Status Window "cheat ability" retune the build. Tuning constants
(energy, XP curve, rewards, stat coefficients) are consts at the top of the file.

**Everything communicates through GameState signals**, not direct node references:
`stats_changed` (HUD redraws), `player_fainted` (dungeon sends you home),
`prompt_changed` / `message_shown` (HUD shows contextual prompts and transient
lines). New systems should emit/listen on these rather than reach across the tree.

**Interactables share a base class.** `Interactable.gd` (extends `Area2D`) handles
"stand on it, press the interact key" — it tracks player overlap, routes a prompt
to the HUD, and calls `_interact()` on `ui_accept`. `Bed`, `NPC`, `QuestBoard`,
`GardenPlot`, etc. extend it and override `_interact()` (and optionally `get_prompt()`
for stateful prompts). The player is in the `"player"` group; monsters are in the
`"monster"` group (so the HUD's inspect can find them).

**Rendering is fully procedural — no art assets.** `PixelArt.gd` generates every
sprite/tile as an `ImageTexture` in code (seeded, so visuals never shimmer between
runs). `TileFloorBuilder.gd` assembles themed (`"town"`/`"dungeon"`) tile floors
from those. To prettify later, swap these for itch.io tilesets; nothing else needs
to change.

**Conventions that keep headless runs working** (don't break these):
- Scripts reference each other via `preload(...)`, **not** `class_name` — headless
  boots then don't depend on the editor's global class cache.
- Uses `TileMapLayer` (the legacy `TileMap` node is deprecated in 4.6).
- Movement is **polled** in `_physics_process` (no custom InputMap actions);
  interaction uses the built-in `ui_accept` action.
- The HUD is **instanced per gameplay scene** (in `World` and `Dungeon`),
  deliberately *not* an autoload.

---

## Quality workflow (quality > speed)

This project favors getting things genuinely right over shipping fast. The tooling
below enforces that — use it.

**Tests.** Real unit tests for game *logic* live in `tests/` and run headless — a
boot-check only proves the game doesn't crash, not that the numbers are right. Run:

```bash
godot --headless --path . --script res://tests/runner.gd
```

`runner.gd` (a `SceneTree` script) returns a real exit code (0 pass / 1 fail).
`test_game_state.gd` covers the XP/level-up cascade, the day/sleep reset, energy/HP
clamping + the faint signal, bounty escalation, and the garden state machine. **Add a
test whenever you add or change logic:** drop a `tests/test_*.gd` with a `run(t)`
method (assert via `t.eq` / `t.check` / `t.contains`) and list it in `runner.gd`'s
`SUITES`. Tests instantiate scripts off-tree and `free()` what they make.

**`/qa` — the gate.** `bash .claude/hooks/qa.sh` runs the unit tests *and* boots
World/Dungeon/Intro, grepping their output for script errors (boots exit 0 even on
error, so the grep is the real signal). Healthy = `QA: ALL CLEAR ✓`.

**Stop-hook gate (optional).** If wired into `.claude/settings.json`,
`.claude/hooks/qa-gate.sh` runs the gate automatically whenever game files change and
blocks "done" until it's green (re-waking Claude with the exact failures). It
self-skips when nothing changed, so conversational turns stay instant. Disable any
time via `/hooks`.

**Slash commands:** `/play` (run) · `/qa` (gate) · `/boot-check [scene]` (quick smoke
boot) · `/playtest` (play + capture feedback to `PLAYTEST.md`) · `/new-interactable
<Name>` (scaffold) · `/done` (definition-of-done).

**Definition of done (`/done`):** QA clear → self `/code-review` → a test exists for
any new logic → `CLAUDE.md` Current status + `PLAYTEST.md` updated → report what
shipped and what was deferred.

**The fun loop:** the game becomes *good* through `/playtest` → log to `PLAYTEST.md` →
tune the smallest, highest-leverage knob → `/qa`. Systems are the content; tune one
thing at a time.

---

## Working agreements (how to build with me)

1. **One milestone at a time.** Do not build ahead. Finish and confirm the current
   milestone is *fun/working* before touching the next. The #1 risk here is losing
   momentum by building systems before there's anything playable.
2. **Smallest version first.** Always propose the most stripped-down thing that
   tests the question, then stop. No farming before the day loop works. No story
   before combat works. No save/load until much later.
3. **Prove fun before adding content.** Systems are the content. Get one fight,
   one day, one dungeon floor genuinely fun before multiplying them.
4. **Cut, don't add.** When in doubt, scope down. Suggest what to *defer*, not what
   to bolt on.
5. **Working code over specs.** This is for fun — favor "here's a script you can
   drop in and run" over long design docs. Show me a thing that moves.
6. **Flag scope creep.** If I ask for something that belongs in a later milestone,
   say so and offer the smaller version that fits the current one.

---

## Milestone roadmap

Build top to bottom. Each milestone has a concrete "done" line — stop there.

**M1 — Skeleton (the only thing that matters first).**
World + body + day reset. A `CharacterBody2D` player walks a small `TileMap` town,
bumps walls, enters one building (Area2D trigger), walks to a bed, sleeps, and the
day counter ticks up with energy refilled.
*Done:* walk around → enter building → sleep → day 2, energy full. No combat, no
menus, no isekai yet.

**M2 — Dungeon + dirt-simple combat.**
A dungeon door in town leads to one small floor. Walk-into-monster combat, HP, an
attack that does damage via a stat + die roll. Energy drains as you act; when it's
low you head home and sleep.
*Done:* descend → fight a couple monsters → take loot/XP → run out of energy →
sleep → start a stronger day.

**M3 — The Status Window (the cheat ability).**
The diegetic HUD: HP/energy, level, a stats screen where you reallocate points,
and "inspect" to see an enemy's exact numbers. This is the signature toy — make it
feel good.
*Done:* I can open my status window, inspect a monster, reallocate points, and feel
the optimization loop.

**M4 — Cozy layer.**
NPCs to talk to, a tavern quest board, the one thing that grows overnight (crops,
town rebuilding, or character growth — pick one snowball). The reason to want tomorrow.
*Done:* the village feels alive and there's a non-combat reason to come back.

**M5 — Isekai cold-open + loop tightening.**
The summon cutscene, the disoriented arrival, the kindly NPC who explains the world.
Tune the daily rhythm until ten in-game days feel good.
*Done:* a stranger could play day 1 through day 10 and want day 11.

---

## GDScript conventions

- `snake_case` for variables/functions, `PascalCase` for nodes/classes/scenes.
- One responsibility per script. `GameState.gd` is the only global singleton for now.
- Prefer signals over hard references between nodes (`body_entered`, custom signals).
- Keep magic numbers in exported vars or constants at the top of the file.
- Comment the *why*, not the *what*.

---

## Current status

**All milestones M1–M5 implemented, boots clean, awaiting playtest.** The full daily
loop closes: isekai intro → town → dungeon → sleep → a stronger day.

- **M1 Skeleton:** WASD/arrow `CharacterBody2D`, 20×15 `TileMapLayer` town with edge
  walls, a building entrance, bed → sleep (day++, energy + HP refilled).
- **M2 Dungeon + combat:** dungeon door → a floor of monsters; walk-into-monster
  contact combat (damage = stat + die roll, energy per swing); XP/gold loot; faint → home.
- **M3 Status Window:** HUD vitals; `[C]` opens the window to reallocate STR/VIT;
  `[F]` inspects an enemy's exact stats; floating combat numbers over the world.
- **M4 Cozy layer:** Mira (guide NPC) dialogue, a tavern bounty board, and the overnight
  garden snowball (plant → ripens over nights → harvest for gold).
- **M5 Cold-open + tuning:** the summon cutscene intro; Mira explains the world; dungeon
  monsters scale to the player's level each dive, keeping day 1 → 10 engaging.

**Verified:** boots headless with zero errors on every scene; per-milestone runtime
tests plus a full-game adversarial review passed (one same-frame double-faint edge case
was found and fixed).

**Controls:** WASD/arrows move · `Space`/`Enter` interact (sleep / talk / garden / board /
descend) · `C` status window · `F` inspect.

**Architecture notes:** see the **Architecture** section above for how the code fits
together (scene flow, the `GameState` hub + signals, the `Interactable` base class, the
procedural-art pipeline, and the headless-safe conventions). Visuals are now procedurally
generated by `PixelArt.gd` (a step up from flat placeholder squares) — drop in itch.io
tilesets to prettify further. Rendering is pixel-crisp (nearest filter, 2× camera,
y-sorted with per-map camera limits) and the window is **freely resizable**
(`canvas_items` + `expand` stretch, 960×540 base).

**Next:** playtest day 1 → 10 and tune to taste. The knobs are consts at the top of
`GameState.gd` (energy, XP curve, rewards, derived-stat coefficients) and `Dungeon.gd`
(`SCALING_PER_LEVEL`).
