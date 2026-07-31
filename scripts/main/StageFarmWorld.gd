class_name StageFarmWorld
extends Node2D

## Map "Ải" kiểu AFK farm - map rộng hơn hẳn City (OverworldWorld), nhiều
## điểm spawn quái rải rác, party đi gần là tự đánh nhau NGAY TẠI CHỖ (không
## chuyển cảnh/không popup như BattleScene) - quái chết hồi sinh sau
## RESPAWN_TIME để cày liên tục. Điều khiển party y hệt City (1 leader chọn
## qua PartyRosterPanel, 3 người còn lại LUÔN tự bám theo - copy-và-chỉnh
## nguyên từ OverworldWorld.gd thay vì tách class dùng chung, tránh động vào
## City tab đang chạy tốt).
##
## PHẠM VI V1 (cắt bớt có chủ đích): chỉ có đòn đánh thường (đúng công thức
## sát thương của BattleScene._resolve_attack/_apply_damage - crit/giáp hiệu
## dụng/life steal), CHƯA có skill "đánh mạnh"/đạn bay Projectile - đánh trúng
## tầm là ra sát thương ngay, giống lính cận chiến. Không đụng BattleScene.gd
## (Ải Boss sau này vẫn dùng BattleScene nguyên vẹn cho trận có thắng/thua).

const TROOP_UNIT_SCENE: PackedScene = preload("res://scenes/troop/TroopUnit.tscn")
const DAMAGE_POPUP_SCENE: PackedScene = preload("res://scenes/troop/DamagePopup.tscn")
const POPUP_SPAWN_OFFSET: Vector2 = Vector2(0, -70)
const COLOR_DAMAGE: Color = Color.WHITE
const COLOR_GOLD: Color = Color(1.0, 0.9, 0.3)

const MAP_BOUNDS: Rect2 = Rect2(-900.0, -1100.0, 1800.0, 2200.0) ## map farm rộng hơn hẳn City (600x960)
const SPAWN_CENTER: Vector2 = Vector2(0.0, 900.0) ## party xuất phát gần mép dưới map
const SPAWN_SPREAD_RADIUS: float = 40.0
const ARRIVE_EPSILON_PX: float = 4.0
const AGGRO_RANGE: float = 180.0 ## trong tầm này mới lao vào đánh, ngoài tầm thì lờ đi
const RESPAWN_TIME: float = 20.0
const REGEN_INTERVAL: float = 5.0 ## hồi máu bị động - giống BattleScene.REGEN_INTERVAL
const MONSTER_SCATTER_RADIUS: float = 30.0 ## rải quái quanh điểm spawn cho khỏi đè lên nhau
const DEATH_CLEANUP_DELAY: float = 1.0 ## chờ animation "death" chạy xong rồi mới queue_free

const FOLLOW_OFFSETS: Array[Vector2] = [
	Vector2(-40.0, -25.0), Vector2(-40.0, 25.0), Vector2(-65.0, 0.0),
]

## Điểm spawn quái - quái NHẸ có sẵn trong catalog cho đúng chất "farm", 1
## điểm xa hơn dùng quái mạnh hơn 1 chút cho hơi thử thách. Xem "Danh sách
## quái (Monster Roster)" trong vault ghi chú cho id/HP/ATK từng loại.
const SPAWN_POINTS: Array[Dictionary] = [
	{"position": Vector2(-500.0, 500.0), "troop_id": 18, "count": 3}, ## Slime
	{"position": Vector2(500.0, 500.0), "troop_id": 19, "count": 3}, ## Bat
	{"position": Vector2(-600.0, 0.0), "troop_id": 14, "count": 2}, ## Skeleton
	{"position": Vector2(600.0, 0.0), "troop_id": 17, "count": 2}, ## Skeleton Archer
	{"position": Vector2(-400.0, -600.0), "troop_id": 10, "count": 2}, ## Orc
	{"position": Vector2(400.0, -800.0), "troop_id": 15, "count": 1}, ## Armored Skeleton - xa nhất, thử thách hơn
]

@onready var party: Node2D = $Party
@onready var monsters: Node2D = $Monsters
@onready var camera: Camera2D = $FarmCamera

## StageFarmMap.set_interactive() tắt khi StageSelectPanel/BattleScene đang mở
var interactive: bool = true
var party_units: Array[TroopUnit] = []
var leader: TroopUnit = null
var _leader_target: Vector2 = Vector2.ZERO
var _has_leader_target: bool = false

var _runtime_spawns: Array[Dictionary] = [] ## {config, alive: Array[TroopUnit], waiting_respawn, respawn_timer}

func _ready() -> void:
	camera.limit_left = int(MAP_BOUNDS.position.x)
	camera.limit_top = int(MAP_BOUNDS.position.y)
	camera.limit_right = int(MAP_BOUNDS.position.x + MAP_BOUNDS.size.x)
	camera.limit_bottom = int(MAP_BOUNDS.position.y + MAP_BOUNDS.size.y)
	_spawn_party()
	for config in SPAWN_POINTS:
		var spawn := {"config": config, "alive": [], "waiting_respawn": false, "respawn_timer": 0.0} ## "alive" cố tình để Array trần (không gõ kiểu) - xem _update_spawn_points cho lý do
		_runtime_spawns.append(spawn)
		_spawn_monsters(spawn)

## Giống OverworldWorld._spawn_party - chia đều 4 người quanh 1 điểm xuất
## phát. HP bar để HIỆN (khác City) vì map này có đánh nhau thật; attack/
## skill bar vẫn ẩn vì chưa có hệ skill windup ở v1.
func _spawn_party() -> void:
	var ids := GameState.PARTY_TROOP_IDS
	for i in range(ids.size()):
		var troop := TroopDatabase.get_by_id(ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		party.add_child(unit)
		unit.setup(troop, Enums.Team.PLAYER)
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.ZERO
		if ids.size() > 1:
			offset = Vector2.RIGHT.rotated(TAU * i / ids.size()) * SPAWN_SPREAD_RADIUS
		unit.position = SPAWN_CENTER + offset
		party_units.append(unit)
	select_leader(0)

func _spawn_monsters(spawn: Dictionary) -> void:
	var config: Dictionary = spawn.config
	var troop := TroopDatabase.get_by_id(config.troop_id)
	if troop == null:
		return
	for i in range(config.count):
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		monsters.add_child(unit)
		unit.setup(troop, Enums.Team.ENEMY)
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.ZERO
		if config.count > 1:
			offset = Vector2.RIGHT.rotated(TAU * i / config.count) * MONSTER_SCATTER_RADIUS
		unit.position = config.position + offset
		spawn.alive.append(unit)

## PartyRosterPanel.leader_selected gọi hàm này (nối trong StageFarmMap.gd) -
## y hệt OverworldWorld.select_leader (1 leader + 3 người còn lại LUÔN tự bám
## theo, không có trạng thái "độc lập" riêng - khớp đúng bản OverworldWorld.gd
## hiện tại, không phải bản 3 trạng thái đã thử trước đó).
func select_leader(index: int) -> void:
	if index < 0 or index >= party_units.size():
		return
	leader = party_units[index]
	_has_leader_target = false
	for unit in party_units:
		unit.set_selected(unit == leader)

func _process(delta: float) -> void:
	_update_regen(delta)
	_update_party(delta)
	_update_monsters(delta)
	_update_spawn_points(delta)
	if leader != null:
		camera.position = leader.position

func _update_regen(delta: float) -> void:
	for unit in party_units:
		_apply_regen(unit, delta)
	for spawn in _runtime_spawns:
		for unit in spawn.alive:
			_apply_regen(unit, delta)

func _apply_regen(unit: TroopUnit, delta: float) -> void:
	if unit.is_dead():
		return
	unit.regen_cooldown += delta
	if unit.regen_cooldown >= REGEN_INTERVAL:
		unit.regen_cooldown = 0.0
		unit.heal(unit.troop_data.regen_hp)

## Đơn vị người chơi: có địch trong AGGRO_RANGE thì lao vào đánh (ưu tiên hơn
## lệnh di chuyển/bám theo), không thì quay lại đúng hành vi leader/auto-follow
## như OverworldWorld (3 người còn lại LUÔN tự bám theo leader).
func _update_party(delta: float) -> void:
	for unit in party_units:
		if unit.is_dead():
			continue
		var enemy := _find_nearest_enemy_of(unit, AGGRO_RANGE)
		if enemy != null:
			_fight_step(unit, enemy, delta)
			continue
		if unit == leader:
			if _has_leader_target:
				_move_toward(leader, _leader_target, delta)
				if leader.position.distance_to(_leader_target) <= ARRIVE_EPSILON_PX:
					_has_leader_target = false
			else:
				leader.play_idle()
		else:
			## Dùng index cố định của unit trong party_units (không phải bộ đếm
			## chạy dần) để mỗi người luôn giữ đúng 1 slot bám theo, không đổi
			## lộn xộn khi có người vừa thoát combat.
			var slot := party_units.find(unit) % FOLLOW_OFFSETS.size()
			var target := _clamp_to_bounds(leader.position + FOLLOW_OFFSETS[slot])
			_move_toward(unit, target, delta)

## Quái: có người chơi trong AGGRO_RANGE thì đánh lại, không thì đứng yên tại
## chỗ (không rời điểm spawn đi lung tung).
func _update_monsters(delta: float) -> void:
	for spawn in _runtime_spawns:
		for unit in spawn.alive:
			if unit.is_dead():
				continue
			var target := _find_nearest_enemy_of(unit, AGGRO_RANGE)
			if target != null:
				_fight_step(unit, target, delta)
			else:
				unit.play_idle()

func _find_nearest_enemy_of(unit: TroopUnit, max_range: float) -> TroopUnit:
	var pool: Array[TroopUnit] = _enemy_pool_for(unit.team)
	var nearest: TroopUnit = null
	var nearest_dist := max_range
	for other in pool:
		if other.is_dead():
			continue
		var d := unit.position.distance_to(other.position)
		if d <= nearest_dist:
			nearest_dist = d
			nearest = other
	return nearest

## append_array() từ Array trần vào biến Array[TroopUnit] đã gõ kiểu tự kiểm
## tra đúng kiểu từng phần tử lúc chạy - AN TOÀN, không cần ép kiểu gì thêm
## (khác hẳn gán/"as" hay Array(src, TYPE_OBJECT, "TroopUnit", null) - 2 cách
## đó KHÔNG hoạt động đúng với custom class_name như TroopUnit, đã test thật
## bằng --script trước khi dùng, xem memory godot notes).
func _enemy_pool_for(team: Enums.Team) -> Array[TroopUnit]:
	if team == Enums.Team.PLAYER:
		var pool: Array[TroopUnit] = []
		for spawn in _runtime_spawns:
			pool.append_array(spawn.alive)
		return pool
	return party_units

## Ngoài tầm đánh thì đi tới, trong tầm thì đứng đánh theo cooldown - dùng
## chung cho cả 2 phe, không có tấn công đặc biệt/đạn bay ở v1.
func _fight_step(attacker: TroopUnit, defender: TroopUnit, delta: float) -> void:
	attacker.face_towards(defender.position)
	var distance := attacker.position.distance_to(defender.position)
	if distance > attacker.attack_range_px():
		attacker.is_engaged = false
		attacker.play_walk()
		var dir := (defender.position - attacker.position).normalized()
		attacker.position = _clamp_to_bounds(attacker.position + dir * attacker.move_speed_px() * delta)
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
## (crit, giáp hiệu dụng theo armor penetration, life steal) - KHÔNG có nhân
## SKILL_DAMAGE_MULT vì v1 chưa có skill "đánh mạnh".
func _resolve_simple_attack(attacker: TroopUnit, defender: TroopUnit) -> void:
	var atk_data := attacker.troop_data
	var is_crit := randf() < atk_data.crit_rate
	var base_damage: float = attacker.effective_atk() * (atk_data.crit_damage if is_crit else 1.0)
	var raw_defense: float = defender.troop_data.m_def if atk_data.damage_type == Enums.DamageType.MAGIC else defender.troop_data.def
	var effective_defense: float = raw_defense * (1.0 - atk_data.armor_penetration / 100.0)
	var final_damage: float = maxf(base_damage - effective_defense, 1.0)

	defender.take_damage(final_damage)
	_spawn_popup(defender.position + POPUP_SPAWN_OFFSET, "-%d" % roundi(final_damage), COLOR_DAMAGE)
	if attacker.troop_data.life_steal > 0.0:
		attacker.heal(final_damage * attacker.troop_data.life_steal)
	if defender.is_dead() and defender.team == Enums.Team.ENEMY:
		_on_monster_died(defender)

func _on_monster_died(unit: TroopUnit) -> void:
	var reward := roundi(unit.troop_data.hp / 10.0)
	GameState.add_gold(reward)
	_spawn_popup(unit.position + POPUP_SPAWN_OFFSET, "+%d vàng" % reward, COLOR_GOLD)
	var timer := get_tree().create_timer(DEATH_CLEANUP_DELAY)
	timer.timeout.connect(unit.queue_free)

func _spawn_popup(world_position: Vector2, text: String, color: Color) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	monsters.add_child(popup)
	popup.setup(text, color, world_position)

## Hết quái ở 1 điểm -> đếm ngược RESPAWN_TIME -> sinh lại đúng loại/số lượng.
func _update_spawn_points(delta: float) -> void:
	for spawn in _runtime_spawns:
		var alive: Array = spawn.alive.filter(func(u: TroopUnit) -> bool: return not u.is_dead())
		spawn.alive = alive
		if not alive.is_empty():
			spawn.waiting_respawn = false
			continue
		if not spawn.waiting_respawn:
			spawn.waiting_respawn = true
			spawn.respawn_timer = RESPAWN_TIME
			continue
		spawn.respawn_timer -= delta
		if spawn.respawn_timer <= 0.0:
			spawn.waiting_respawn = false
			_spawn_monsters(spawn)

func _move_toward(unit: TroopUnit, target: Vector2, delta: float) -> void:
	if unit.position.distance_to(target) <= ARRIVE_EPSILON_PX:
		unit.play_idle()
		return
	unit.face_towards(target)
	unit.play_walk()
	unit.position = _clamp_to_bounds(unit.position + (target - unit.position).normalized() * unit.move_speed_px() * delta)

func _clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, MAP_BOUNDS.position.x, MAP_BOUNDS.position.x + MAP_BOUNDS.size.x),
		clampf(pos.y, MAP_BOUNDS.position.y, MAP_BOUNDS.position.y + MAP_BOUNDS.size.y)
	)

## Click trái vào map = ra lệnh leader đi tới đó - y hệt OverworldWorld (xem
## đó cho lý do dùng canvas_transform thay vì get_global_mouse_position()).
func _unhandled_input(event: InputEvent) -> void:
	if not interactive or leader == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_point: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		_leader_target = _clamp_to_bounds(world_point)
		_has_leader_target = true
