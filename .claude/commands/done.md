---
description: Definition-of-done gate — QA clear + self code-review + update status docs
---
Run before declaring any feature, fix, or milestone finished. Quality > speed: do not
skip steps, and do not claim done until every gate is green.

1. **Quality gate.** `bash .claude/hooks/qa.sh` — must print `QA: ALL CLEAR ✓`
   (unit tests pass + all scenes boot clean). If not, fix and repeat.

2. **Self code-review.** Review the changes for correctness bugs first, then for
   reuse/simplification/altitude. Run the `/code-review` command (or, for a deeper
   pass, propose `/code-review high`). Address real findings; note anything
   deliberately deferred.

3. **New logic ⇒ new test.** If this change added or changed game *logic* (a formula,
   a state machine, a reward), there must be a matching assertion in
   `tests/test_game_state.gd` (or a new `tests/test_*.gd` added to `runner.gd`'s
   SUITES). If it's missing, add it now and re-run step 1.

4. **Update the docs that drift.** Refresh `CLAUDE.md`'s **Current status** to match
   reality, and log any playtest outcomes in `PLAYTEST.md`.

5. **Report.** Summarize what shipped, what's verified (quote the QA result), and —
   per "cut, don't add" — what you intentionally deferred to a later milestone.
