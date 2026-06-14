extends CanvasLayer

## The diegetic player UI (M3 — the "Status Window" cheat ability). An always-on
## vitals bar, a toggleable Status Window to view and REALLOCATE your own stats, an
## inspect readout for an enemy's exact numbers, plus contextual prompts and transient
## messages. Built in code; panels/shadows give it a framed, readable look. Stays live
## via GameState signals. (Floating combat numbers live in the world, spawned by Monster.)

const TOGGLE_KEY := KEY_C    # open/close the status window
const INSPECT_KEY := KEY_F   # inspect the monster you're standing on

var _vitals: Label
var _inspect: Label
var _status_panel: Panel
var _status_text: Label
var _status_open := false
var _prompt: Label
var _message: Label
var _msg_tween: Tween

func _ready() -> void:
	_build_ui()
	GameState.stats_changed.connect(_refresh)
	GameState.prompt_changed.connect(_on_prompt)
	GameState.message_shown.connect(_on_message)
	_refresh()

func _panel_bg(alpha: float = 0.62) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.13, alpha)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 5
	sb.content_margin_bottom = 5
	return sb

func _make_label(font_size: int = 16) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_stylebox_override("normal", _panel_bg())
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l

func _build_ui() -> void:
	# Always-on vitals + hint + inspect, top-left (content-hugging panels).
	_vitals = _make_label(16)
	_vitals.position = Vector2(10, 8)
	add_child(_vitals)

	var hint := _make_label(12)
	hint.text = "[C] status   [F] inspect   WASD move   Space interact"
	hint.position = Vector2(10, 40)
	hint.modulate = Color(1, 1, 1, 0.85)
	add_child(hint)

	_inspect = _make_label(14)
	_inspect.position = Vector2(10, 66)
	_inspect.modulate = Color(0.9, 0.92, 1.0)
	_inspect.visible = false
	add_child(_inspect)

	# Transient message (dialogue / results), centred near the top, fades out.
	var msg_box := CenterContainer.new()
	msg_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	msg_box.offset_top = 92
	msg_box.offset_bottom = 128
	add_child(msg_box)
	_message = _make_label(16)
	_message.modulate = Color(1, 1, 1, 0)
	msg_box.add_child(_message)

	# Contextual interact prompt, centred at the bottom.
	var prompt_box := CenterContainer.new()
	prompt_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_box.offset_top = -56
	prompt_box.offset_bottom = -22
	add_child(prompt_box)
	_prompt = _make_label(16)
	_prompt.visible = false
	prompt_box.add_child(_prompt)

	# --- Status Window: centred, hidden until toggled ---
	_status_panel = Panel.new()
	_status_panel.anchor_left = 0.5
	_status_panel.anchor_top = 0.5
	_status_panel.anchor_right = 0.5
	_status_panel.anchor_bottom = 0.5
	_status_panel.offset_left = -180
	_status_panel.offset_top = -150
	_status_panel.offset_right = 180
	_status_panel.offset_bottom = 150
	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0.11, 0.10, 0.17, 0.97)
	sp.set_corner_radius_all(10)
	sp.set_border_width_all(2)
	sp.border_color = Color(0.55, 0.5, 0.72)
	_status_panel.add_theme_stylebox_override("panel", sp)
	_status_panel.visible = false
	add_child(_status_panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20, 18)
	vbox.custom_minimum_size = Vector2(320, 264)
	vbox.add_theme_constant_override("separation", 12)
	_status_panel.add_child(vbox)

	var title := Label.new()
	title.text = "[ STATUS WINDOW ]"
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	_status_text = Label.new()
	_status_text.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_status_text)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	vbox.add_child(buttons)

	var str_btn := Button.new()
	str_btn.text = "+ Strength"
	str_btn.pressed.connect(func(): GameState.allocate_point("strength"))
	buttons.add_child(str_btn)

	var vit_btn := Button.new()
	vit_btn.text = "+ Vitality"
	vit_btn.pressed.connect(func(): GameState.allocate_point("vitality"))
	buttons.add_child(vit_btn)

	var foot := Label.new()
	foot.text = "Spend points to reshape your build. [C] to close."
	foot.add_theme_font_size_override("font_size", 12)
	foot.modulate = Color(1, 1, 1, 0.6)
	vbox.add_child(foot)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == TOGGLE_KEY:
			_status_open = not _status_open
			_status_panel.visible = _status_open
			_refresh()
		elif event.keycode == INSPECT_KEY:
			_inspect_enemy()

## "Inspect any enemy's exact stats" — reads the monster the player is standing on.
func _inspect_enemy() -> void:
	_inspect.visible = true
	for m in get_tree().get_nodes_in_group("monster"):
		if is_instance_valid(m) and m._player_in_contact:
			_inspect.text = "Inspect: %s  -  HP %d/%d, ATK %d, rewards %d XP / %d gold" % [
				m.monster_name, m.hp, m.max_hp, m.attack, m.xp_reward, m.gold_reward]
			return
	_inspect.text = "Inspect: nothing here - stand on a monster, then press F."

func _refresh() -> void:
	_vitals.text = "Day %d    Lv %d    HP %d/%d    Energy %d/%d    XP %d/%d    Gold %d" % [
		GameState.day, GameState.level, GameState.hp, GameState.max_hp(),
		GameState.energy, GameState.MAX_ENERGY, GameState.xp, GameState.xp_to_next(), GameState.gold]
	if _status_open:
		var plural := "" if GameState.unspent_points == 1 else "s"
		_status_text.text = (
			"Level %d    (%d unspent point%s)\n\n" +
			"Strength  %d   ->  Attack  %d\n" +
			"Vitality   %d   ->  Max HP  %d\n\n" +
			"XP  %d / %d        Gold  %d"
		) % [
			GameState.level, GameState.unspent_points, plural,
			GameState.strength, GameState.attack_power(),
			GameState.vitality, GameState.max_hp(),
			GameState.xp, GameState.xp_to_next(), GameState.gold]

func _on_prompt(text: String) -> void:
	_prompt.visible = text != ""
	_prompt.text = ("[Space] " + text) if text != "" else ""

## Show a transient line (dialogue / harvest / bounty result), then fade it out.
func _on_message(text: String) -> void:
	_message.text = text
	_message.modulate = Color(1, 1, 1, 1)
	if _msg_tween != null and _msg_tween.is_valid():
		_msg_tween.kill()
	_msg_tween = create_tween()
	_msg_tween.tween_interval(2.5)
	_msg_tween.tween_property(_message, "modulate:a", 0.0, 1.0)
