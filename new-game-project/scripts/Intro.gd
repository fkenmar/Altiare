extends CanvasLayer

## The isekai cold-open (M5). A few lines of summon/arrival text, advanced with the
## interact key, then it hands off to the town. Only the launch main scene plays this;
## returning from the dungeon loads the town directly, so the intro shows just once.

const LINES := [
	"A circle of light. Voices in a language you don't know. Then - falling.",
	"You wake on cold grass at the edge of a frontier village, the summoning still ringing in your ears.",
	"A stranger in another world. Level 1, nothing to your name... except a strange window only you can see.",
	"Move with WASD or the arrow keys. Press [C] to open your Status Window - the power that came with you.",
	"Find Mira in the village; she'll explain the rest. Welcome to your new life.",
]

var _index: int = 0
var _label: Label
var _hint: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 96
	_label.offset_right = -96
	_label.offset_top = -40
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -56
	_hint.offset_bottom = -28
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.text = "[Space] continue"
	_hint.modulate = Color(1, 1, 1, 0.6)
	add_child(_hint)

	_refresh()

func _refresh() -> void:
	_label.text = LINES[_index]
	if _index == LINES.size() - 1:
		_hint.text = "[Space] step into the world"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_index += 1
		if _index >= LINES.size():
			get_tree().change_scene_to_file("res://scenes/World.tscn")
		else:
			_refresh()
