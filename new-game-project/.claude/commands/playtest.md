---
description: Launch the game for a playtest, then capture + triage feedback into PLAYTEST.md
---
Run a playtest session. This is the heart of the quality loop for this game —
"prove fun before adding content" (CLAUDE.md). Two phases:

## Phase 1 — launch (do this now)

1. Quick health check first: `bash .claude/hooks/qa.sh` (don't launch a broken build).
2. Launch the game in the background so the session stays interactive:
   `godot --path .`
3. Remind the player of the controls: WASD/arrows move · Space/Enter interact ·
   C status window · F inspect.
4. Ask the player to actually play (ideally day 1 → a few days) and then tell you, in
   their own words:
   - What felt **good / fun**? (keep it)
   - What felt **off, slow, or grindy**? (tune it)
   - What was **confusing**? (clarify it)
   - Did you **want to keep playing**? Where did momentum drop?
   - Any **bugs** (crashes, stuck states, weird numbers)?

Then stop and wait for their report.

## Phase 2 — triage (when the player reports back)

Append a dated entry to `PLAYTEST.md` (stamp the heading with the current date —
`date +%F`). For each observation, write one line tagged: `[bug]` · `[tuning]` ·
`[confusing]` · `[fun]` · `[idea]`, and map it to a milestone (M1–M5) or "polish".

Then, honoring the working agreements (smallest version first; cut don't add; one
milestone at a time): propose the **single highest-leverage next change** and the
exact knob/file to touch (tuning consts live atop `scripts/GameState.gd`; dungeon
scaling in `scripts/Dungeon.gd`). Defer the rest into the log. Do not start coding
until the player picks.
