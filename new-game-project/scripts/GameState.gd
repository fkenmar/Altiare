extends Node

## Global game state singleton (autoload) — the hub every system hangs off (CLAUDE.md).
## Holds the day/energy daily loop plus the RPG stats that combat and the Status
## Window read and write. Primary stats (strength/vitality) are player-reallocatable;
## max HP and attack are derived from them so the "cheat ability" can retune the build.

signal stats_changed   ## anything that changes a tracked value emits this (HUD listens)
signal player_fainted  ## hp hit 0 (combat) — the dungeon listens to send us home
signal prompt_changed(text: String)  ## contextual "[Space] do X" prompt for the HUD
signal message_shown(text: String)   ## transient popup line (dialogue/results) for the HUD

# --- Tuning (magic numbers live up here, per conventions) ---
const STARTING_DAY: int = 1
const MAX_ENERGY: int = 100
const ENERGY_PER_HIT: int = 10  # a dungeon run of a few fights should drain a full bar
const POINTS_PER_LEVEL: int = 3
const CROP_REWARD: int = 30

const BASE_MAX_HP: int = 20
const HP_PER_VIT: int = 6
const BASE_ATTACK: int = 3
const ATTACK_PER_STR: int = 2

# --- Day loop ---
var day: int = STARTING_DAY
var energy: int = MAX_ENERGY

# --- Progression ---
var level: int = 1
var xp: int = 0
var gold: int = 0

# --- Primary stats (reallocatable via the Status Window in M3) ---
var strength: int = 3
var vitality: int = 3
var unspent_points: int = 0

# --- Current vitals ---
var hp: int = 0  # set to max in _ready once vitality is known

# --- Cozy layer (M4): bounty board + overnight garden ---
var monsters_slain: int = 0
var bounty_goal: int = 3
var bounty_reward: int = 25
var crop_stage: int = 0  # 0 empty, 1 seeded, 2 growing, 3 ripe

func _ready() -> void:
	hp = max_hp()

# --- Derived stats ---
func max_hp() -> int:
	return BASE_MAX_HP + HP_PER_VIT * vitality

func attack_power() -> int:
	return BASE_ATTACK + ATTACK_PER_STR * strength

func xp_to_next() -> int:
	return 20 + (level - 1) * 15

# --- Day loop ---
## Advance the world by one day; rest refills energy, fully heals, and grows crops.
func sleep() -> void:
	day += 1
	energy = MAX_ENERGY
	hp = max_hp()
	if crop_stage == 1 or crop_stage == 2:
		crop_stage += 1  # seed -> growing -> ripe over two nights
	stats_changed.emit()

# --- Combat-facing mutations ---
func spend_energy(amount: int) -> void:
	energy = max(0, energy - amount)
	stats_changed.emit()

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	stats_changed.emit()
	if hp == 0:
		player_fainted.emit()

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		_level_up()
	stats_changed.emit()

func add_gold(amount: int) -> void:
	gold += amount
	stats_changed.emit()

func record_kill() -> void:
	monsters_slain += 1
	stats_changed.emit()

func _level_up() -> void:
	level += 1
	unspent_points += POINTS_PER_LEVEL
	hp = max_hp()  # leveling restores you to full

# --- Status Window (M3) ---
## Spend one unspent point on a primary stat. Returns false if there are none left.
func allocate_point(stat: String) -> bool:
	if unspent_points <= 0:
		return false
	match stat:
		"strength":
			strength += 1
		"vitality":
			vitality += 1
			hp += HP_PER_VIT  # immediately enjoy the larger pool
		_:
			return false
	unspent_points -= 1
	stats_changed.emit()
	return true

# --- Cozy layer (M4): tavern bounties + the overnight garden ---
## Claim the monster-slaying bounty if earned; each completion raises the next one.
func claim_bounty() -> String:
	if monsters_slain >= bounty_goal:
		var reward := bounty_reward
		gold += reward
		monsters_slain -= bounty_goal
		bounty_goal += 2
		bounty_reward += 15
		stats_changed.emit()
		return "Bounty complete! +%d gold. Next: slay %d monsters for %d gold." % [reward, bounty_goal, bounty_reward]
	return "Bounty: slay %d monsters for %d gold (%d/%d so far)." % [bounty_goal, bounty_reward, monsters_slain, bounty_goal]

## Tend the garden plot: plant when empty, harvest when ripe, otherwise wait.
func plant_crop() -> String:
	if crop_stage == 0:
		crop_stage = 1
		stats_changed.emit()
		return "You plant a seed. Sleep a night or two and come back."
	if crop_stage == 3:
		return harvest_crop()
	return "The crop is still growing. Sleep to help it ripen."

func harvest_crop() -> String:
	if crop_stage == 3:
		gold += CROP_REWARD
		crop_stage = 0
		stats_changed.emit()
		return "You harvest a ripe crop! +%d gold." % CROP_REWARD
	return "Nothing ripe to harvest yet."
