class_name StageFarmWorld
extends Node2D

## "Bãi farm" treo máy THẬT - KHÔNG điều khiển được (không leader/không
## click-di-chuyển), party (đúng thành viên đang treo team đó) tự đánh nhau vô
## hạn với quái của đúng StageData đang treo. Đây CHÍNH LÀ trận đấu tạo ra
## phần thưởng thật - KHÔNG có công thức DPS/thời gian nào cả, quái chết thật
## thì cộng vàng (LinhData.gold_reward) + EXP (LinhData.exp_reward) NGAY LÚC
## ĐÓ cho member_troop_ids (xem _apply_damage). Instance này được GameState
## giữ sống suốt thời gian treo máy (xem GameState.start_idle_team) - "Xem
## treo máy" chỉ là NHÚNG (reparent) instance đang chạy này vào UI để nhìn,
## không tạo bản sao/không tính riêng gì cả.
##
## configure() được gọi ngay sau khi instance (xem GameState.start_idle_team_on_map) -
## lúc đó @onready đã sẵn sàng (Godot gọi _ready() ngay khi add_child() vào 1
## tree đang chạy, trước khi add_child() trả về). configure() có thể gọi LẠI
## nhiều lần trên cùng 1 instance (tự dọn quân cũ trước khi spawn quân mới) -
## dùng để LÊN TẦNG khi thắng, xem _advance_floor().
##
## Mỗi tầng gồm NHIỀU ĐỢT quái nối tiếp dọc bản đồ (số đợt/số quái mỗi đợt/cấp
## quái đều tăng theo floor_number - xem core/combat/EncounterGenerator.gd),
## quái đợt kế luôn spawn xa hơn về +X (WAVE_SPACING_X) - party tự đi tới vì
## AI vẫn chỉ "tìm địch gần nhất rồi tới đánh" như cũ, không có gì đổi ở đó.
## Camera bám theo X trung bình của party mỗi frame (_update_camera_follow)
## tạo cảm giác phe mình đứng yên, quái/thế giới trôi qua - kiểu auto-runner
## (tham khảo Tap Titans/taskbar hero). Hết đợt hiện tại (còn đợt kế trong
## tầng) -> nghỉ WAVE_CLEAR_DELAY rồi spawn đợt kế (_spawn_next_wave). Hết ĐỢT
## CUỐI CÙNG (party còn sống) = THẮNG CẢ TẦNG -> báo
## GameState.report_floor_cleared rồi tự nạp StageData tầng kế tiếp (không
## còn bị kẹp ở tầng cuối cùng đã author tay - xem GameState.resolve_stage_for_floor).
## THUA (party chết sạch, ở BẤT KỲ đợt nào) -> đánh lại từ ĐỢT 1 của đúng tầng
## đang treo, không tiếp tục từ đợt đang thua (xem _revive_all). Cả thắng/thua
## cả tầng đều chờ RESTART_DELAY giây trước khi thật sự đổi - giống kiểu AFK
## Arena/game farm-tầng-tự-động.
##
## PHẠM VI (cắt bớt có chủ đích): chỉ có đòn đánh thường (đúng công thức sát
## thương của BattleScene._resolve_attack/_apply_damage - crit/giáp hiệu
## dụng/life steal), CHƯA có skill "đánh mạnh". Đạn bay Archer/Wizard + hiệu
## ứng Priest DÙNG CHUNG asset với BattleScene (chỉ bản đòn thường, không có
## bản "skill" phóng to) để đòn đánh tầm xa có hiệu ứng nhìn thấy được, không
## chỉ đổi tư thế đánh suông.

const TROOP_UNIT_SCENE: PackedScene = preload("res://entities/troop/TroopUnit.tscn")
const DAMAGE_POPUP_SCENE: PackedScene = preload("res://entities/troop/DamagePopup.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://entities/troop/Projectile.tscn")
const IMPACT_EFFECT_SCENE: PackedScene = preload("res://entities/troop/ImpactEffect.tscn")
const ARROW_TEXTURE: Texture2D = preload("res://assets/troops/archer/ArrowProjectile.png")
const MAGIC_PROJECTILE_FRAMES: SpriteFrames = preload("res://assets/troops/wizard/MagicProjectileFrames.tres")
const PRIEST_ATTACK_EFFECT_FRAMES: SpriteFrames = preload("res://assets/troops/priest/PriestAttackEffectFrames.tres")
const POPUP_SPAWN_OFFSET: Vector2 = Vector2(0, -70)
const COLOR_DAMAGE: Color = Color.WHITE
const COLOR_GOLD: Color = Color(1.0, 0.9, 0.3)
const COLOR_MATERIAL: Color = Color(0.6, 0.85, 1.0)
const MATERIAL_DROP_CHANCE: float = 0.7 ## hạ 1 quái = 70% rơi đúng 1 nguyên liệu cấp 1 (ngẫu nhiên trong 10 nhóm)

const PARTY_CENTER: Vector2 = Vector2(-160.0, 0.0)
const SPREAD_RADIUS: float = 44.0
const REGEN_INTERVAL: float = 5.0 ## giống BattleScene.REGEN_INTERVAL
const RESTART_DELAY: float = 2.0 ## hết CẢ TẦNG (đợt cuối cùng) -> chờ rồi lên tầng/hồi sinh, đánh lại vòng mới
const CORPSE_VANISH_DELAY: float = 2.0 ## xác đơn vị chết ẩn đi sau chừng này giây (dù phe kia còn đang đánh tiếp, không đợi tới lúc cả phe bị xoá sạch mới ẩn)

## Bản đồ dài nhiều đợt (xem EncounterGenerator) - quái đợt kế spawn xa hơn
## dọc trục X, quay vòng qua WAVE_SLOT_COUNT vị trí X cố định thay vì cộng dồn
## vô hạn (xem WAVE_SLOT_COUNT bên dưới).
const WAVE_SPACING_X: float = 900.0 ## khoảng cách world-X giữa 2 đợt liên tiếp
const FIRST_WAVE_OFFSET_X: float = 260.0 ## khoảng cách từ PARTY_CENTER tới đợt đầu tiên
const WAVE_CLEAR_DELAY: float = 0.6 ## nghỉ ngắn giữa 2 đợt trong CÙNG 1 tầng - khác RESTART_DELAY (dùng cho thắng/thua cả tầng)
const CAMERA_FOLLOW_LERP_SPEED: float = 4.0 ## hệ số lerp/giây - camera đuổi theo X trung bình của party còn sống, tạo cảm giác phe mình đứng yên
const CAMERA_LEFT_OFFSET_X: float = 180.0 ## lệch tâm camera sang PHẢI so với party 1 khoảng = 1/4 chiều rộng viewport (720px) - để phe mình luôn hiện ở góc trái màn, không đứng giữa, dễ theo dõi quái/boss tới từ bên phải

## --- Giới hạn bản đồ (2026-08) ---
## Trước đây _wave_anchor_x cộng dồn WAVE_SPACING_X mãi mãi theo floor_number
## (có thể tới 29 đợt ở floor 100) -> world "dài vô hạn" phải giả bằng cách
## cho ground_background bám theo camera mỗi frame (đã xoá, xem
## _update_camera_follow). Từ giờ: WAVE_SLOT_COUNT vị trí X CỐ ĐỊNH mà đợt
## quái xoay vòng qua - hết 1 vòng, _recenter_world() dịch lại party + camera
## lùi về đúng lúc không có quái trên màn (WAVE_CLEAR_DELAY), giữ nguyên cảm
## giác "luôn tiến về phía trước" nhưng world không bao giờ vượt
## CAMERA_LIMIT_LEFT/RIGHT nữa - ground_background giờ TĨNH, không cần bám
## theo camera mỗi frame nữa.
const WAVE_SLOT_COUNT: int = 3

const VIEWPORT_HALF_WIDTH: float = 360.0 ## SubViewport rộng 720 (xem .tscn)
const CAMERA_VIEW_MARGIN: float = 40.0 ## đệm dôi thêm, tránh clamp chạm biên đúng lúc đang cần thấy trọn cảnh
const CAMERA_LIMIT_LEFT: float = PARTY_CENTER.x + CAMERA_LEFT_OFFSET_X - VIEWPORT_HALF_WIDTH - CAMERA_VIEW_MARGIN
const CAMERA_LIMIT_RIGHT: float = PARTY_CENTER.x + FIRST_WAVE_OFFSET_X + (WAVE_SLOT_COUNT - 1) * WAVE_SPACING_X + CAMERA_LEFT_OFFSET_X + VIEWPORT_HALF_WIDTH + CAMERA_VIEW_MARGIN

@onready var arena: Node2D = $Arena
@onready var camera: Camera2D = $FarmCamera
@onready var ground_background: ColorRect = $GroundBackground

var party_units: Array[TroopUnit] = []
var enemy_units: Array[TroopUnit] = []
var _all_units: Array[TroopUnit] = [] ## party_units + enemy_units, gộp lại mỗi lần đổi đợt/tầng - xem _rebuild_all_units()
var _stage: StageData
var _member_troop_ids: Array[int] = []
var _restart_timer: float = -1.0
var _pending_win: bool = false ## chỉ có ý nghĩa trong lúc _restart_timer >= 0.0 - xem _check_wipe()/_advance_floor()
var _death_timers: Dictionary = {} ## TroopUnit đã chết -> số giây đã trôi qua kể từ lúc chết, xem _update_corpses

var _wave_count: int = 1 ## tổng số đợt của tầng đang treo - xem EncounterGenerator.wave_count_for_floor()
var _current_wave_index: int = -1 ## đợt đang đánh (0-based), -1 = chưa spawn đợt nào
var _wave_anchor_x: float = 0.0 ## tâm X của đợt HIỆN TẠI - tính lại mỗi lần _spawn_next_wave() theo slot xoay vòng (xem WAVE_SLOT_COUNT)
var _wave_transition_timer: float = -1.0 ## >=0: đang nghỉ WAVE_CLEAR_DELAY giữa 2 đợt (khác _restart_timer - dùng khi hết CẢ TẦNG)

func _ready() -> void:
	## Nền + giới hạn camera CỐ ĐỊNH bất kể floor_number/wave_count - set 1 lần
	## ở đây (LUÔN chạy trước configure() đầu tiên - Godot gọi _ready() ngay
	## khi add_child(), trước khi add_child() trả về) để camera.position gán
	## lần đầu trong configure() đã bị giới hạn đúng ngay từ đầu.
	ground_background.position.x = CAMERA_LIMIT_LEFT
	ground_background.size.x = CAMERA_LIMIT_RIGHT - CAMERA_LIMIT_LEFT
	camera.limit_left = roundi(CAMERA_LIMIT_LEFT)
	camera.limit_right = roundi(CAMERA_LIMIT_RIGHT)
	## KHÔNG set limit_top/limit_bottom - camera.position.y không bao giờ đổi
	## ở file này (lý do chi tiết xem BattleScene._ready(), cùng công thức).

## Gọi được NHIỀU LẦN trên cùng 1 instance (lên tầng khi thắng) - tự dọn hết
## quân cũ (queue_free + xoá 2 mảng) trước khi spawn quân mới, không cần
## instance StageFarmWorld mới mỗi lần đổi tầng.
func configure(stage: StageData, member_troop_ids: Array[int]) -> void:
	for child in arena.get_children():
		child.queue_free()
	party_units.clear()
	enemy_units.clear()
	_all_units.clear()
	_death_timers.clear()

	_stage = stage
	_member_troop_ids = member_troop_ids
	camera.position = PARTY_CENTER + Vector2(CAMERA_LEFT_OFFSET_X, 0.0)
	camera.zoom = Vector2.ONE
	_spawn_party(member_troop_ids)

	_wave_count = EncounterGenerator.wave_count_for_floor(stage.floor_number)
	_current_wave_index = -1
	_spawn_next_wave()

func get_stage() -> StageData:
	return _stage

func get_member_troop_ids() -> Array[int]:
	return _member_troop_ids

func _spawn_party(member_troop_ids: Array[int]) -> void:
	for i in range(member_troop_ids.size()):
		var troop := TroopDatabase.get_by_id(member_troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, Enums.Team.PLAYER)
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.ZERO
		if member_troop_ids.size() > 1:
			offset = Vector2.RIGHT.rotated(TAU * i / member_troop_ids.size()) * SPREAD_RADIUS
		unit.position = PARTY_CENTER + offset
		party_units.append(unit)

## Dọn đợt quái cũ (nếu có) rồi spawn đợt KẾ TIẾP (_current_wave_index += 1) -
## quái luôn random theo đúng floor_number đang treo (xem
## EncounterGenerator.generate_encounter_for_floor). Vị trí X xoay vòng qua
## WAVE_SLOT_COUNT vị trí cố định (xem ghi chú WAVE_SLOT_COUNT) - không cộng
## dồn vô hạn. Gọi từ configure() (đợt đầu tầng), _process() khi hết
## WAVE_CLEAR_DELAY, và _revive_all() (thua -> đánh lại từ đợt 1).
func _spawn_next_wave() -> void:
	for unit in enemy_units:
		unit.queue_free()
		_death_timers.erase(unit)
	enemy_units.clear()
	_current_wave_index += 1
	var slot: int = _current_wave_index % WAVE_SLOT_COUNT
	if slot == 0 and _current_wave_index > 0:
		_recenter_world(WAVE_SLOT_COUNT * WAVE_SPACING_X)
	_wave_anchor_x = PARTY_CENTER.x + FIRST_WAVE_OFFSET_X + slot * WAVE_SPACING_X

	var encounter: Dictionary = EncounterGenerator.generate_encounter_for_floor(_stage.floor_number)
	var monster_ids: Array[int] = encounter["monster_ids"]
	var monster_level: int = encounter["monster_level"]
	var total := monster_ids.size()
	var radius := maxf(SPREAD_RADIUS, total * 9.0) ## co giãn theo số quái - có thể lên tới MAX_MONSTERS_PER_WAVE
	for i in range(total):
		var troop := TroopDatabase.get_by_id(monster_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, Enums.Team.ENEMY, monster_level)
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.RIGHT.rotated(TAU * i / maxi(total, 1)) * radius
		unit.position = Vector2(_wave_anchor_x, 0.0) + offset
		enemy_units.append(unit)
	_rebuild_all_units()

## Dịch cả party lẫn camera lùi lại đúng `shift` - gọi ĐÚNG LÚC không còn quái
## nào sống trên màn (giữa 2 đợt CÙNG 1 tầng), khi party đang idle nhờ
## _hold_survivors_idle(), nên hoàn toàn không thấy "giật/nhảy".
func _recenter_world(shift: float) -> void:
	for unit in party_units:
		unit.position.x -= shift
	camera.position.x -= shift

## party_units/enemy_units không đổi thành phần trong lúc chiến đấu (chết chỉ
## đổi is_dead()) - chỉ cần gộp lại _all_units mỗi lần ĐỔI ĐỢT/TẦNG (spawn lại
## enemy_units), dùng lại mỗi frame thay vì cấp phát mảng mới ở từng vòng lặp.
func _rebuild_all_units() -> void:
	_all_units.clear()
	_all_units.append_array(party_units)
	_all_units.append_array(enemy_units)

func _process(delta: float) -> void:
	if _stage == null:
		return
	_update_corpses(delta)
	_update_camera_follow(delta)
	if _restart_timer >= 0.0:
		_hold_survivors_idle()
		_restart_timer -= delta
		if _restart_timer <= 0.0:
			_restart_timer = -1.0
			if _pending_win:
				_advance_floor()
			else:
				_revive_all()
		return
	## Nghỉ ngắn giữa 2 đợt CÙNG 1 tầng (khác _restart_timer ở trên - dùng khi
	## hết CẢ TẦNG tức đợt cuối cùng) - xem _check_wipe().
	if _wave_transition_timer >= 0.0:
		_hold_survivors_idle()
		_wave_transition_timer -= delta
		if _wave_transition_timer <= 0.0:
			_wave_transition_timer = -1.0
			_spawn_next_wave()
		return
	_update_regen(delta)
	_update_fight(delta)
	_check_wipe()

## Camera bám theo X trung bình của party còn sống mỗi frame - vì quái đợt
## sau luôn spawn xa hơn về +X và party tự đi tới (_fight_step không đổi gì),
## việc camera luôn tự canh theo party (LỆCH sang phải CAMERA_LEFT_OFFSET_X,
## không canh giữa) tạo đúng cảm giác "phe mình đứng yên ở góc trái, thế
## giới/quái trôi qua từ bên phải" - không cần waypoint/trạng thái "đang tiến
## quân" gì thêm. Chỉ dịch trục X (Y giữ nguyên, đội hình chỉ dàn theo chiều dọc nhẹ).
func _update_camera_follow(delta: float) -> void:
	var sum_x := 0.0
	var count := 0
	for unit in party_units:
		if not unit.is_dead():
			sum_x += unit.position.x
			count += 1
	if count == 0:
		return
	var target_x: float = sum_x / count + CAMERA_LEFT_OFFSET_X
	camera.position.x = lerpf(camera.position.x, target_x, clampf(delta * CAMERA_FOLLOW_LERP_SPEED, 0.0, 1.0))

## Trong lúc chờ RESTART_DELAY, _update_fight không còn chạy nên phải tự gọi
## play_idle() MỖI FRAME ở đây thay vì 1 lần duy nhất - play_idle() cố ý
## không ngắt animation đánh đang chạy dở (xem TroopUnit._is_busy()), nên gọi
## lại liên tục mới bắt đúng lúc animation đó tự kết thúc rồi chuyển hẳn về
## idle, thay vì đứng hình ở khung hình cuối cho tới hết cả 2 giây chờ.
func _hold_survivors_idle() -> void:
	for unit in _all_units:
		if not unit.is_dead():
			unit.is_engaged = false
			unit.play_idle()

## Ẩn xác sau CORPSE_VANISH_DELAY giây kể từ lúc chết - chạy độc lập với
## _restart_timer (kể cả lúc đang chờ hồi sinh) để xác luôn biến mất đúng hẹn.
## revive() sẽ set lại visible = true khi hồi sinh, xem TroopUnit.revive().
func _update_corpses(delta: float) -> void:
	for unit in _all_units:
		if not unit.is_dead():
			_death_timers.erase(unit)
			continue
		if not unit.visible:
			continue ## đã ẩn rồi - khỏi cập nhật/ghi lại timer mỗi frame cho tới lúc hồi sinh
		var elapsed: float = _death_timers.get(unit, 0.0) + delta
		_death_timers[unit] = elapsed
		if elapsed >= CORPSE_VANISH_DELAY:
			unit.visible = false

func _update_regen(delta: float) -> void:
	for unit in _all_units:
		if unit.is_dead():
			continue
		unit.regen_cooldown += delta
		if unit.regen_cooldown >= REGEN_INTERVAL:
			unit.regen_cooldown = 0.0
			unit.heal(unit.troop_data.regen_hp)

## Hết mục tiêu (phe kia đã chết sạch) -> đứng yên tư thế idle thay vì giữ
## nguyên animation cuối cùng (thường đang giữa chừng 1 đòn tấn công) - trước
## đây _fight_step chỉ được gọi khi CÓ mục tiêu nên animation bị đứng hình.
func _update_fight(delta: float) -> void:
	for unit in _all_units:
		if unit.is_dead():
			continue
		var target := _find_nearest_enemy_of(unit)
		if target != null:
			_fight_step(unit, target, delta)
		else:
			unit.is_engaged = false
			unit.play_idle()

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
## chung cho cả 2 phe, không có tấn công đặc biệt "đánh mạnh" (đạn bay đòn
## thường xem _resolve_simple_attack).
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
## SKILL_DAMAGE_MULT vì chưa có skill "đánh mạnh". Quái (ENEMY) chết THẬT ở
## _apply_damage() thì cộng vàng+EXP thật NGAY LÚC ĐÓ - đây chính là nguồn
## thưởng treo máy duy nhất, không phải hình ảnh minh hoạ (xem ghi chú đầu file).
##
## Archer/Wizard bắn đạn bay (sát thương chỉ áp dụng lúc đạn TỚI NƠI qua
## on_arrive callback, giống BattleScene._spawn_arrow/_spawn_magic_bolt) thay
## vì trừ máu ngay lúc ra đòn - nếu không đòn tầm xa chỉ đổi tư thế đánh mà
## không có hiệu ứng gì bay tới mục tiêu, nhìn như "đánh chay".
func _resolve_simple_attack(attacker: TroopUnit, defender: TroopUnit) -> void:
	var atk_data := attacker.troop_data
	var is_crit := randf() < atk_data.crit_rate
	var base_damage: float = attacker.effective_atk() * (atk_data.crit_damage if is_crit else 1.0)
	var raw_defense: float = defender.effective_m_def() if atk_data.damage_type == Enums.DamageType.MAGIC else defender.effective_def()
	var effective_defense: float = raw_defense * (1.0 - atk_data.armor_penetration / 100.0)
	var final_damage: float = maxf(base_damage - effective_defense, 1.0)

	match atk_data.character_key:
		"archer":
			_spawn_arrow(attacker, defender, final_damage)
		"wizard":
			_spawn_magic_bolt(attacker, defender, final_damage)
		"priest":
			_apply_damage(attacker, defender, final_damage)
			_spawn_impact_effect(defender.position, PRIEST_ATTACK_EFFECT_FRAMES)
		_:
			_apply_damage(attacker, defender, final_damage)

func _apply_damage(attacker: TroopUnit, defender: TroopUnit, final_damage: float) -> void:
	if defender.is_dead():
		return
	defender.take_damage(final_damage)
	_spawn_popup(defender.position + POPUP_SPAWN_OFFSET, "-%d" % roundi(final_damage), COLOR_DAMAGE)
	if attacker.troop_data.life_steal > 0.0:
		attacker.heal(final_damage * attacker.troop_data.life_steal)
	if defender.is_dead() and defender.team == Enums.Team.ENEMY:
		GameState.add_gold(defender.troop_data.gold_reward)
		GameState.grant_kill_exp(_member_troop_ids, defender.troop_data.exp_reward)
		_spawn_popup(defender.position + POPUP_SPAWN_OFFSET + Vector2(0, -16), "+%d vàng" % defender.troop_data.gold_reward, COLOR_GOLD)
		_roll_material_drop(defender)

## Hạ 1 quái = MATERIAL_DROP_CHANCE (70%) rơi đúng 1 nguyên liệu cấp 1, ngẫu
## nhiên trong 10 nhóm (xem MaterialDatabase.random_tier1_id) - cộng thẳng
## vào GameState.materials (WarehousePanel đọc trực tiếp từ đó).
func _roll_material_drop(defender: TroopUnit) -> void:
	if randf() >= MATERIAL_DROP_CHANCE:
		return
	var material_id := MaterialDatabase.random_tier1_id()
	GameState.add_material(material_id, 1)
	var mat := MaterialDatabase.get_by_id(material_id)
	_spawn_popup(defender.position + POPUP_SPAWN_OFFSET + Vector2(0, -32), "+1 %s" % mat.display_name, COLOR_MATERIAL)

func _spawn_arrow(attacker: TroopUnit, defender: TroopUnit, final_damage: float) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	arena.add_child(projectile)
	projectile.setup_static(attacker.position, defender.position, ARROW_TEXTURE, func(): _apply_damage(attacker, defender, final_damage))

func _spawn_magic_bolt(attacker: TroopUnit, defender: TroopUnit, final_damage: float) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	arena.add_child(projectile)
	projectile.setup_animated(attacker.position, defender.position, MAGIC_PROJECTILE_FRAMES, "cast", func(): _apply_damage(attacker, defender, final_damage))

func _spawn_impact_effect(world_position: Vector2, frames: SpriteFrames) -> void:
	var effect: ImpactEffect = IMPACT_EFFECT_SCENE.instantiate()
	arena.add_child(effect)
	effect.setup(world_position, frames, "cast")

func _spawn_popup(world_position: Vector2, text: String, color: Color) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	arena.add_child(popup)
	popup.setup(text, color, world_position)

## Quái ĐỢT HIỆN TẠI chết sạch mà party còn sống: còn đợt kế tiếp trong tầng
## này -> chuyển đợt (WAVE_CLEAR_DELAY, xem _process); là đợt CUỐI CÙNG ->
## THẮNG CẢ TẦNG (lên tầng, RESTART_DELAY). Party chết sạch (bất kể đợt nào)
## = THUA -> đánh lại từ ĐỢT 1 của đúng tầng này (RESTART_DELAY, xem _revive_all).
func _check_wipe() -> void:
	if _restart_timer >= 0.0 or _wave_transition_timer >= 0.0:
		return
	var party_alive := party_units.any(func(u: TroopUnit) -> bool: return not u.is_dead())
	var enemy_alive := enemy_units.any(func(u: TroopUnit) -> bool: return not u.is_dead())
	if party_alive and enemy_alive:
		return
	if not party_alive:
		_pending_win = false
		_restart_timer = RESTART_DELAY
		return
	if _current_wave_index < _wave_count - 1:
		_wave_transition_timer = WAVE_CLEAR_DELAY
	else:
		_pending_win = true
		_restart_timer = RESTART_DELAY

## Báo GameState mở khoá tầng vừa thắng, rồi nạp tầng kế tiếp của ĐÚNG map
## đang treo - tầng tiến được VÔ HẠN kể cả khi chưa author StageData thật cho
## tầng đó (xem GameState.resolve_stage_for_floor - tự duplicate() tầng cuối
## cùng có sẵn, chỉ map_id/floor_number còn được đọc thật ở luồng này).
func _advance_floor() -> void:
	var map_id: int = _stage.map_id
	var current_floor: int = _stage.floor_number
	GameState.report_floor_cleared(map_id, current_floor)

	var floors: Array[StageData] = StageDatabase.get_floors_for_map(map_id)
	var next_stage: StageData = GameState.resolve_stage_for_floor(floors, current_floor + 1)
	configure(next_stage, _member_troop_ids)

## Thua -> đánh lại ĐỢT 1 của đúng tầng đang treo (không tiếp tục từ đợt đang
## thua) - hồi sinh party TẠI CHỖ rồi đưa .position về lại đội hình gốc quanh
## PARTY_CENTER (party đã đi xa theo các đợt trước đó), dọn quái đợt dở dang,
## reset lại state đợt về ban đầu rồi spawn lại đợt 1.
func _revive_all() -> void:
	for i in range(party_units.size()):
		var unit := party_units[i]
		unit.revive()
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.ZERO
		if party_units.size() > 1:
			offset = Vector2.RIGHT.rotated(TAU * i / party_units.size()) * SPREAD_RADIUS
		unit.position = PARTY_CENTER + offset
	_death_timers.clear()
	_current_wave_index = -1
	_spawn_next_wave()
