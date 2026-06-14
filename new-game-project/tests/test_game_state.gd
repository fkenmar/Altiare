extends RefCounted

## Unit tests for GameState's logic — the stuff a headless boot can NEVER catch:
## derived stats, the XP/level-up cascade, the day/sleep reset, energy/HP clamping +
## faint signal, the tavern bounty escalation, and the overnight garden state machine.
## These are the real regression guards: change a tuning const or a formula and the
## affected assertion fails loudly instead of silently shipping a worse game.

const GameStateScript = preload("res://scripts/GameState.gd")

func run(t) -> void:
	_derived_stats(t)
	_xp_curve(t)
	_level_up_exact(t)
	_level_up_multi(t)
	_allocate_points(t)
	_sleep_resets_and_grows_crop(t)
	_energy_clamps(t)
	_damage_clamps_and_faints(t)
	_bounty(t)
	_garden(t)
	_misc_counters(t)

## A GameState instance with _ready()'s effect applied (hp = max_hp), since _ready
## only fires inside the tree and these tests run off-tree.
func _fresh():
	var gs = GameStateScript.new()
	gs.hp = gs.max_hp()
	return gs

func _derived_stats(t) -> void:
	var gs = _fresh()
	t.eq(gs.max_hp(), 38, "max_hp = BASE_MAX_HP + HP_PER_VIT*vitality (20+6*3)")
	t.eq(gs.attack_power(), 9, "attack_power = BASE_ATTACK + ATTACK_PER_STR*strength (3+2*3)")
	gs.free()

func _xp_curve(t) -> void:
	var gs = _fresh()
	t.eq(gs.xp_to_next(), 20, "xp_to_next at level 1")
	gs.level = 2
	t.eq(gs.xp_to_next(), 35, "xp_to_next at level 2")
	gs.level = 3
	t.eq(gs.xp_to_next(), 50, "xp_to_next at level 3")
	gs.free()

func _level_up_exact(t) -> void:
	var gs = _fresh()
	gs.gain_xp(20)
	t.eq(gs.level, 2, "exact-threshold XP levels up once")
	t.eq(gs.xp, 0, "leftover XP is zero after an exact level-up")
	t.eq(gs.unspent_points, 3, "level-up grants POINTS_PER_LEVEL")
	t.eq(gs.hp, gs.max_hp(), "level-up restores HP to full")
	gs.free()

func _level_up_multi(t) -> void:
	var gs = _fresh()
	gs.gain_xp(20 + 35)  # enough for L1->L2 (20) and L2->L3 (35)
	t.eq(gs.level, 3, "overflow XP cascades through multiple levels")
	t.eq(gs.xp, 0, "no leftover after a clean multi-level gain")
	t.eq(gs.unspent_points, 6, "points accumulate across cascaded levels")
	gs.free()

func _allocate_points(t) -> void:
	var gs = _fresh()
	t.check(gs.allocate_point("strength") == false, "cannot allocate with no unspent points")
	gs.gain_xp(20)  # -> 3 unspent points
	t.check(gs.allocate_point("strength"), "allocate strength succeeds with points")
	t.eq(gs.strength, 4, "strength incremented")
	t.eq(gs.attack_power(), 11, "attack_power tracks strength (3+2*4)")
	var hp_before = gs.hp
	t.check(gs.allocate_point("vitality"), "allocate vitality succeeds")
	t.eq(gs.vitality, 4, "vitality incremented")
	t.eq(gs.hp, hp_before + gs.HP_PER_VIT, "vitality immediately enlarges current HP")
	t.eq(gs.unspent_points, 1, "two allocations consumed two of three points")
	t.check(gs.allocate_point("bogus") == false, "unknown stat is rejected")
	t.eq(gs.unspent_points, 1, "a rejected allocation spends no point")
	gs.free()

func _sleep_resets_and_grows_crop(t) -> void:
	var gs = _fresh()
	gs.spend_energy(60)
	gs.hp = 5
	gs.crop_stage = 1
	gs.sleep()
	t.eq(gs.day, 2, "sleep advances the day")
	t.eq(gs.energy, gs.MAX_ENERGY, "sleep refills energy")
	t.eq(gs.hp, gs.max_hp(), "sleep fully heals")
	t.eq(gs.crop_stage, 2, "a seeded crop grows one stage overnight")
	gs.sleep()
	t.eq(gs.crop_stage, 3, "a growing crop ripens the next night")
	gs.sleep()
	t.eq(gs.crop_stage, 3, "a ripe crop does not over-grow")
	gs.free()

	var empty = _fresh()
	empty.sleep()
	t.eq(empty.crop_stage, 0, "an empty plot stays empty after sleep")
	empty.free()

func _energy_clamps(t) -> void:
	var gs = _fresh()
	gs.energy = 5
	gs.spend_energy(20)
	t.eq(gs.energy, 0, "energy never goes negative")
	gs.free()

func _damage_clamps_and_faints(t) -> void:
	var gs = _fresh()
	gs.hp = 10
	var fainted = [false]  # array so the lambda can flip it (reference capture)
	gs.player_fainted.connect(func(): fainted[0] = true)
	gs.take_damage(4)
	t.eq(gs.hp, 6, "damage subtracts from HP")
	t.check(not fainted[0], "no faint while HP remains")
	gs.take_damage(999)
	t.eq(gs.hp, 0, "HP clamps at zero")
	t.check(fainted[0], "reaching zero HP emits player_fainted")
	gs.free()

func _bounty(t) -> void:
	var gs = _fresh()
	var status = gs.claim_bounty()
	t.contains(status, "0/3", "an unmet bounty reports progress")
	t.eq(gs.gold, 0, "an unmet bounty pays nothing")
	gs.monsters_slain = 3
	var done = gs.claim_bounty()
	t.contains(done, "complete", "a met bounty reports completion")
	t.eq(gs.gold, 25, "completing the bounty pays its reward")
	t.eq(gs.monsters_slain, 0, "completing the bounty consumes the kills")
	t.eq(gs.bounty_goal, 5, "the next bounty goal escalates by 2")
	t.eq(gs.bounty_reward, 40, "the next bounty reward escalates by 15")
	gs.free()

func _garden(t) -> void:
	var gs = _fresh()
	t.contains(gs.plant_crop(), "plant", "planting on empty soil seeds it")
	t.eq(gs.crop_stage, 1, "soil becomes seeded")
	t.contains(gs.plant_crop(), "growing", "interacting mid-growth just waits")
	gs.crop_stage = 3
	t.contains(gs.plant_crop(), "harvest", "interacting with a ripe crop harvests it")
	t.eq(gs.gold, gs.CROP_REWARD, "harvest pays CROP_REWARD")
	t.eq(gs.crop_stage, 0, "a harvested plot resets to empty")
	gs.free()

func _misc_counters(t) -> void:
	var gs = _fresh()
	gs.record_kill()
	t.eq(gs.monsters_slain, 1, "record_kill increments the counter")
	gs.add_gold(7)
	t.eq(gs.gold, 7, "add_gold accumulates gold")
	gs.free()
