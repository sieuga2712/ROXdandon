class_name StageFarmWorld
extends Node2D

## Màn "xem treo máy cho vui" - KHÔNG điều khiển được (không leader/không
## click-di-chuyển), chỉ auto-fight vô hạn giữa party (đúng thành viên đang
## treo team đó) và quái của đúng StageData đang treo, để xem có gì đó xảy ra
## trong lúc chờ. PHẦN THƯỞNG THẬT đã tính riêng theo thời gian qua
## GameState.settle_idle_team() - màn này KHÔNG cộng vàng/EXP gì thêm, chỉ là
## hình ảnh minh hoạ.
##
## configure() được gọi ngay sau khi instance (xem StageFarmMap.gd/
## StageBoardScreen._open_idle_view) - lúc đó @onready đã sẵn sàng (Godot gọi
## _ready() ngay khi add_child() vào 1 tree đang chạy, trước khi add_child()
## trả về). Hết 1 phe thì dừng lại RESTART_DELAY giây rồi hồi sinh CẢ 2 PHÊ để
## đánh lại từ đầu (loop vô hạn, không có khái niệm thắng/thua ở đây).
##
## PHẠM VI (cắt bớt có chủ đích): chỉ có đòn đánh thường (đúng công thức sát
## thương của BattleScene._resolve_attack/_apply_damage - crit/giáp hiệu
## dụng/life steal), CHƯA có skill "đánh mạnh"/đạn bay Projectile.

const TROOP_UNIT_SCENE: PackedScene = preload("res://scenes/troop/TroopUnit.tscn")
const DAMAGE_POPUP_SCENE: PackedScene = preload("res://scenes/troop/DamagePopup.tscn")
const POPUP_SPAWN_OFFSET: Vector2 = Vector2(0, -70)
const COLOR_DAMAGE: Color = Color.WHITE

const PARTY_CENTER: Vector2 = Vector2(-160.0, 0.0)
const ENEMY_CENTER: Vector2 = Vector2(160.0, 0.0)
const SPREAD_RADIUS: float = 44.0
const REGEN_INTERVAL: float = 5.0 ## giống BattleScene.REGEN_INTERVAL
const RESTART_DELAY: float = 2.0 ## hết 1 phe -> chờ rồi hồi sinh cả 2 phe, đánh lại vòng mới

@onready var party: Node2D = $Party
@onready var monsters: Node2D = $Monsters
@onready var camera: Camera2D = $FarmCamera

var party_units: Array[TroopUnit] = []
var enemy_units: Array[TroopUnit] = []
var _stage: StageData
var _restart_timer: float = -1.0

func configure(stage: StageData, member_troop_ids: Array[int]) -> void:
	_stage = stage
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	_spawn_party(member_troop_ids)
	_spawn_enemies(stage)

func _spawn_party(member_troop_ids: Array[int]) -> void:
	for i in range(member_troop_ids.size()):
		var troop := TroopDatabase.get_by_id(member_troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		party.add_child(unit)
		unit.setup(troop, Enums.Team.PLAYER)
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.ZERO
		if member_troop_ids.size() > 1:
			offset = Vector2.RIGHT.rotated(TAU * i / member_troop_ids.size()) * SPREAD_RADIUS
		unit.position = PARTY_CENTER + offset
		party_units.append(unit)

func _spawn_enemies(stage: StageData) -> void:
	var total := 0
	for count in stage.enemy_troop_counts:
		total += count
	var index := 0
	for i in range(stage.enemy_troop_ids.size()):
		var troop := TroopDatabase.get_by_id(stage.enemy_troop_ids[i])
		if troop == null:
			continue
		for _n in range(stage.enemy_troop_counts[i]):
			var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
			monsters.add_child(unit)
			unit.setup(troop, Enums.Team.ENEMY)
			unit.attack_bar_bg.visible = false
			unit.skill_bar_bg.visible = false
			var offset := Vector2.RIGHT.rotated(TAU * index / maxi(total, 1)) * SPREAD_RADIUS
			unit.position = ENEMY_CENTER + offset
			enemy_units.append(unit)
			index += 1

func _process(delta: float) -> void:
	if _stage == null:
		return
	if _restart_timer >= 0.0:
		_restart_timer -= delta
		if _restart_timer <= 0.0:
			_restart_timer = -1.0
			_revive_all()
		return
	_update_regen(delta)
	_update_fight(delta)
	_check_wipe()

func _update_regen(delta: float) -> void:
	for unit in party_units + enemy_units:
		if unit.is_dead():
			continue
		unit.regen_cooldown += delta
		if unit.regen_cooldown >= REGEN_INTERVAL:
			unit.regen_cooldown = 0.0
			unit.heal(unit.troop_data.regen_hp)

func _update_fight(delta: float) -> void:
	for unit in party_units:
		if unit.is_dead():
			continue
		var target := _find_nearest_enemy_of(unit)
		if target != null:
			_fight_step(unit, target, delta)
	for unit in enemy_units:
		if unit.is_dead():
			continue
		var target := _find_nearest_enemy_of(unit)
		if target != null:
			_fight_step(unit, target, delta)

func _find_nearest_enemy_of(unit: TroopUnit) -> TroopUnit:
	var pool: Array[TroopUnit] = enemy_units if unit.team == Enums.Team.PLAYER else party_units
	var nearest: TroopUnit = null
	var nearest_dist := INF
	for other in pool:
		if other.is_dead():
			continue
		var d := unit.position.distance_to(other.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = other
	return nearest

## Ngoài tầm đánh thì đi tới, trong tầm thì đứng đánh theo cooldown - dùng
## chung cho cả 2 phe, không có tấn công đặc biệt/đạn bay.
func _fight_step(attacker: TroopUnit, defender: TroopUnit, delta: float) -> void:
	attacker.face_towards(defender.position)
	var distance := attacker.position.distance_to(defender.position)
	if distance > attacker.attack_range_px():
		attacker.is_engaged = false
		attacker.play_walk()
		var dir := (defender.position - attacker.position).normalized()
		attacker.position += dir * attacker.move_speed_px() * delta
		return
	attacker.is_engaged = true
	attacker.attack_cooldown = maxf(attacker.attack_cooldown - delta, 0.0)
	if attacker.attack_cooldown <= 0.0:
		attacker.attack_cooldown = attacker.attack_interval()
		attacker.play_attack()
		_resolve_simple_attack(attacker, defender)
	else:
		attacker.play_idle()

## Copy đúng công thức sát thương của BattleScene._resolve_attack/_apply_damage
## (crit, giáp hiệu dụng theo armor penetration, life steal) - KHÔNG nhân
## SKILL_DAMAGE_MULT vì chưa có skill "đánh mạnh". KHÔNG cộng vàng/EXP thật ở
## đây (xem ghi chú đầu file) - chỉ hiện số sát thương cho vui.
func _resolve_simple_attack(attacker: TroopUnit, defender: TroopUnit) -> void:
	var atk_data := attacker.troop_data
	var is_crit := randf() < atk_data.crit_rate
	var base_damage: float = attacker.effective_atk() * (atk_data.crit_damage if is_crit else 1.0)
	var raw_defense: float = defender.effective_m_def() if atk_data.damage_type == Enums.DamageType.MAGIC else defender.effective_def()
	var effective_defense: float = raw_defense * (1.0 - atk_data.armor_penetration / 100.0)
	var final_damage: float = maxf(base_damage - effective_defense, 1.0)

	defender.take_damage(final_damage)
	_spawn_popup(defender.position + POPUP_SPAWN_OFFSET, "-%d" % roundi(final_damage), COLOR_DAMAGE)
	if attacker.troop_data.life_steal > 0.0:
		attacker.heal(final_damage * attacker.troop_data.life_steal)

func _spawn_popup(world_position: Vector2, text: String, color: Color) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	monsters.add_child(popup)
	popup.setup(text, color, world_position)

## Hết 1 phe (thường là quái, party đông/mạnh hơn) -> chờ RESTART_DELAY rồi
## hồi sinh CẢ 2 PHÊ, đánh lại vòng mới - loop vô hạn, không có thắng/thua.
func _check_wipe() -> void:
	if _restart_timer >= 0.0:
		return
	var party_alive := party_units.any(func(u: TroopUnit) -> bool: return not u.is_dead())
	var enemy_alive := enemy_units.any(func(u: TroopUnit) -> bool: return not u.is_dead())
	if not party_alive or not enemy_alive:
		_restart_timer = RESTART_DELAY

func _revive_all() -> void:
	for unit in party_units + enemy_units:
		unit.revive()
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
