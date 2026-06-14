extends Area2D

## A dungeon monster. Dead-simple contact combat (CLAUDE.md: "walk into monster,
## swing, numbers happen"): while the player overlaps, both sides trade blows on a
## timer. Player damage = GameState.attack_power() + a die roll; each swing costs the
## player energy. On death it awards XP + gold and frees itself. In the "monster"
## group so the HUD can inspect it; spawns floating damage numbers over the world.

const FloatingNumber = preload("res://scenes/FloatingNumber.tscn")

@export var monster_name: String = "Slime"
@export var max_hp: int = 22
@export var attack: int = 3
@export var xp_reward: int = 15
@export var gold_reward: int = 4

const COMBAT_INTERVAL: float = 0.6  # seconds between blow exchanges
const DIE_FACES: int = 4            # the "+ die roll" on top of the flat stat

var hp: int = 0
var _player: Node2D = null
var _player_in_contact: bool = false
var _timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("monster")  # lets the HUD's inspect find us
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		_player_in_contact = true
		_timer = COMBAT_INTERVAL  # land the first blow almost immediately on contact

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_contact = false

func _process(delta: float) -> void:
	if not _player_in_contact or hp <= 0:
		return
	_timer += delta
	if _timer >= COMBAT_INTERVAL:
		_timer = 0.0
		_exchange_blows()

func _exchange_blows() -> void:
	if GameState.energy <= 0:
		print("Too tired to swing — head home and sleep.")
		return

	# Player strikes first.
	var player_dmg := GameState.attack_power() + randi_range(1, DIE_FACES)
	hp -= player_dmg
	GameState.spend_energy(GameState.ENERGY_PER_HIT)
	_spawn_number(global_position, str(player_dmg), Color(1, 0.9, 0.35))
	print("You hit %s for %d. (%s HP: %d)" % [monster_name, player_dmg, monster_name, max(hp, 0)])
	if hp <= 0:
		_die()
		return

	# Monster strikes back.
	var monster_dmg := attack + randi_range(1, DIE_FACES)
	GameState.take_damage(monster_dmg)
	if _player != null and is_instance_valid(_player):
		_spawn_number(_player.global_position, str(monster_dmg), Color(1, 0.4, 0.4))
	print("%s hits you for %d. (Your HP: %d, Energy: %d)" % [monster_name, monster_dmg, GameState.hp, GameState.energy])

func _die() -> void:
	GameState.gain_xp(xp_reward)
	GameState.add_gold(gold_reward)
	print("%s defeated! +%d XP, +%d gold. (Lvl %d, %d/%d XP)" % [
		monster_name, xp_reward, gold_reward, GameState.level, GameState.xp, GameState.xp_to_next()])
	queue_free()

func _spawn_number(at: Vector2, value_text: String, color: Color) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var n := FloatingNumber.instantiate()
	parent.add_child(n)
	n.global_position = at
	n.show_value(value_text, color)
