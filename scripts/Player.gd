extends CharacterBody2D

## Top-down player. WASD + arrow-key movement via move_and_slide(). Movement keys
## are polled directly so M1 needs no custom InputMap (see CLAUDE.md conventions).

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	velocity = direction.normalized() * speed
	move_and_slide()
