#!/usr/bin/env bash
# Quality gate for the Godot game: headless unit tests + scene boot smoke-checks.
# Exit 0 = all clear, 1 = something failed. Used by /qa and by the Stop-hook gate.
#
# Why grep for errors on boots: Godot's headless boot (and --check-only) print
# SCRIPT/parse errors to stderr but still exit 0, so the exit code can't be trusted
# for scenes. The unit runner DOES return a real exit code (it calls quit(1)).
set -uo pipefail

# This script lives at <project>/.claude/hooks/qa.sh, so ../.. is the Godot project
# root (which is also the git repo root). Works regardless of caller's cwd.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GODOT="$(command -v godot || echo /opt/homebrew/bin/godot)"
SCENES=(World Dungeon Intro)
# GDScript failure signatures (boots/--check-only emit these but exit 0).
ERR_RE='SCRIPT ERROR|Parse Error|Failed to load|Cannot call|Invalid (call|get|set|index)|Nonexistent|Attempt to call'

fail=0

echo "── Unit tests ─────────────────────────────"
test_out="$("$GODOT" --headless --path "$ROOT" --script res://tests/runner.gd 2>&1)"
test_rc=$?
echo "$test_out" | grep -vE '^Godot Engine|^$'
if [ "$test_rc" -eq 0 ]; then
	echo "unit tests: PASS"
else
	echo "unit tests: FAIL"
	fail=1
fi

echo ""
echo "── Scene boot smoke-checks ────────────────"
for scene in "${SCENES[@]}"; do
	out="$("$GODOT" --headless --path "$ROOT" --quit-after 120 "res://scenes/$scene.tscn" 2>&1)"
	if echo "$out" | grep -qiE "$ERR_RE"; then
		echo "boot $scene: FAIL"
		echo "$out" | grep -iE "$ERR_RE" | head -5 | sed 's/^/    /'
		fail=1
	else
		echo "boot $scene: PASS"
	fi
done

echo ""
if [ "$fail" -eq 0 ]; then
	echo "QA: ALL CLEAR ✓"
else
	echo "QA: FAILURES ✗"
fi
exit "$fail"
