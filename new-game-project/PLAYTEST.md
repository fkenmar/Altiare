# Playtest log

The fun-tuning loop for this game. After each play session (`/playtest`), log what you
felt here, then turn the highest-leverage item into the smallest next change. This log —
not a roadmap — drives what gets built next. "Prove fun before adding content."

**Tags:** `[bug]` broken · `[tuning]` numbers/pacing · `[confusing]` unclear ·
`[fun]` keep this · `[idea]` future. Map each to a milestone (M1–M5) or `polish`.

**Tuning knobs:** consts at the top of `new-game-project/scripts/GameState.gd`
(energy, XP curve, rewards, derived-stat coefficients) and `Dungeon.gd`
(`SCALING_PER_LEVEL`). Change a knob → add/adjust an assertion in
`tests/test_game_state.gd` → `/qa`.

---

## 2026-06-14 — baseline (not yet played)

All milestones M1–M5 are implemented and pass QA (49 unit assertions + clean headless
boots of World/Dungeon/Intro). Nothing has been playtested for *feel* yet — that's the
next move.

- [idea] M5 — First real playtest: play day 1 → day 10 and judge whether you want
  day 11. Capture the moment momentum drops; that's the first thing to tune.

_Next session: run `/playtest`, fill in observations below._
