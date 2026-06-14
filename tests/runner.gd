extends SceneTree

## Headless test runner. Run with:
##   godot --headless --path new-game-project --script res://tests/runner.gd
## Exits 0 when every assertion passes, 1 otherwise — so the QA gate / CI can trust
## the exit code (unlike --check-only, which prints errors but always exits 0).
##
## Tests instantiate game scripts directly, off-tree (no autoload, no scene needed),
## and free what they create so the run leaves no leaked-object noise. Add a new suite
## by dropping a `tests/test_*.gd` with a `run(t)` method and listing it in SUITES.

const SUITES := [
	preload("res://tests/test_game_state.gd"),
]

var _pass: int = 0
var _fail: int = 0
var _failures: PackedStringArray = []

func _initialize() -> void:
	for suite_script in SUITES:
		var suite = suite_script.new()
		suite.run(self)
	_report()
	quit(1 if _fail > 0 else 0)

## Assert a boolean. `label` is what prints on failure.
func check(cond: bool, label: String) -> void:
	if cond:
		_pass += 1
	else:
		_fail += 1
		_failures.append(label)

## Assert equality, with both values shown on mismatch.
func eq(actual, expected, label: String) -> void:
	check(actual == expected, "%s — expected %s, got %s" % [label, str(expected), str(actual)])

## Assert a substring (used for player-facing message text).
func contains(haystack: String, needle: String, label: String) -> void:
	check(haystack.contains(needle), "%s — '%s' did not contain '%s'" % [label, haystack, needle])

func _report() -> void:
	print("")
	print("──────────────────────────────────────────")
	print("Tests: %d passed, %d failed" % [_pass, _fail])
	for f in _failures:
		printerr("  FAIL: ", f)
	print("──────────────────────────────────────────")
