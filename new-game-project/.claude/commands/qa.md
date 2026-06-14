---
description: Run the full quality gate — headless unit tests + scene boot smoke-checks
---
Run the project's quality gate and report the result:

`bash .claude/hooks/qa.sh`

What it does:
- Runs the GDScript unit tests (`tests/runner.gd`) — these have a real exit code and
  guard the game *logic* (XP curve, level-up, day/sleep, bounty, garden, clamps).
- Boots `World`, `Dungeon`, and `Intro` headless and greps their output for script
  errors (boots exit 0 even on error, so grep is the real signal).

Report pass/fail per section. If anything fails, treat it as a bug to fix now — do
NOT declare the work done. Re-run until the script prints `QA: ALL CLEAR ✓`.
