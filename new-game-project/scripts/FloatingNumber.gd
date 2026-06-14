extends Node2D

## A combat number that floats up and fades over the world (M3: "see values float
## over the world"). Spawned by Monster into the level; frees itself when done.

@onready var _label: Label = $Label

## Call right after adding to the tree and setting global_position.
func show_value(value_text: String, color: Color) -> void:
	_label.text = value_text
	_label.add_theme_font_size_override("font_size", 18)
	_label.modulate = color
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30.0, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
