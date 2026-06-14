#!/usr/bin/env bash
# Stop-hook quality gate. Runs QA only when game source changed since the last green
# run (so conversational turns stay instant), and blocks "done" if QA fails.
#
# Exit 0  -> let the turn end (nothing changed, or QA passed).
# Exit 2  -> blocking error: Claude Code feeds stderr back and re-wakes Claude to fix.
set -uo pipefail

# <project>/.claude/hooks/qa-gate.sh -> ../.. is the Godot project / repo root.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAMP="$ROOT/.godot/.qa-stamp"   # lives under gitignored .godot/

# Has any game source changed since the last green QA? (no stamp => treat as changed)
changed=1
if [ -f "$STAMP" ]; then
	newer="$(find "$ROOT/scripts" "$ROOT/scenes" "$ROOT/tests" \
		\( -name '*.gd' -o -name '*.tscn' \) -newer "$STAMP" -print -quit 2>/dev/null)"
	[ -z "$newer" ] && changed=0
fi
[ "$changed" -eq 0 ] && exit 0

report="$(bash "$ROOT/.claude/hooks/qa.sh" 2>&1)"
rc=$?
if [ "$rc" -eq 0 ]; then
	mkdir -p "$(dirname "$STAMP")"
	touch "$STAMP"
	exit 0
fi

{
	echo "Quality gate FAILED — do not declare this done yet. Fix the issues below, then"
	echo "the gate will re-check automatically. (Run /qa to reproduce; /hooks to disable.)"
	echo ""
	echo "$report"
} >&2
exit 2
