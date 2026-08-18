class_name CombatResolver
extends RefCounted

## Toàn bộ hành vi CHIẾN ĐẤU của 1 ĐƠN VỊ (targeting + né nhau lúc di chuyển,
## đòn đánh thường, skill "Đánh mạnh", đạn bay/hiệu ứng, rớt nguyên liệu,
## thưởng EXP/vàng, hồi máu theo regen) - đây là đặc trưng của NHÂN VẬT, KHÔNG
## phải của map, nên dùng CHUNG cho cả `features/combat/BattleScene.gd` (đấu 1
## trận có thắng/thua) và `features/stage/StageFarmWorld.gd` (treo máy vô hạn)
## - 2 module này CHỈ còn khác nhau ở phần "map" (camera/spawn/timing/kết thúc
## trận/vòng đời), không còn khác nhau ở cách 1 đơn vị chiến đấu nữa (2026-08 -
## trước đó StageFarmWorld tự viết 1 bản RÚT GỌN không có skill/né nhau do lười
## viết 2 lần, không phải chủ đích thiết kế "map treo máy không nên có skill").
##
## Mô hình "treadmill": phe ENEMY LUÔN được di chuyển tới khi ngoài tầm đánh
## (không đổi). Phe PLAYER CHỈ được di chuyển nếu `target.position.x <=
## free_movement_x` (xem run_ai()) - `free_movement_x` KHÔNG cố định, do MAP
## tự điều khiển theo giai đoạn dàn quân đợt hiện tại (CENTER_WAIT/RETREATING
## -> map tự set .position phe mình trực tiếp, truyền free_movement_x = -INF
## để CHẮC CHẮN CombatResolver không tự ý di chuyển đè lên; ENGAGED -> truyền
## +INF, bỏ hẳn ràng buộc, phe mình tự do lao vào quái) - xem
## BattleScene/StageFarmWorld._update_wave_staging()/_current_free_movement_x().
## Tránh đúng bug "quái tầm xa dừng đánh từ xa hơn tầm lính mình, lính mình
## đứng chịu trận không phản kháng được" nếu khoá cứng player đứng yên tuyệt
## đối suốt trận (2026-08).
##
## Mỗi map tự `CombatResolver.new(arena, grant_gold_on_kill)` ĐÚNG 1 lần rồi
## gọi `run_ai()`/`resolve_collisions()` mỗi frame - KHÔNG lưu trạng thái riêng
## của từng đơn vị ở đây (mọi state - HP/cooldown/vị trí... - nằm trên chính
## TroopUnit, xem entities/troop/TroopUnit.gd), resolver chỉ là nơi chứa LUẬT
## CHUNG áp dụng lên các TroopUnit được truyền vào.

const PROJECTILE_SCENE: PackedScene = preload("res://entities/troop/Projectile.tscn")
const DAMAGE_POPUP_SCENE: PackedScene = preload("res://entities/troop/DamagePopup.tscn")
const IMPACT_EFFECT_SCENE: PackedScene = preload("res://entities/troop/ImpactEffect.tscn")
const ARROW_TEXTURE: Texture2D = preload("res://assets/troops/archer/ArrowProjectile.png")
const ARROW_SKILL_SCALE: float = 1.5 ## Đòn mạnh của cung thủ vẫn dùng chung ảnh mũi tên, chỉ phóng to hơn để phân biệt với đòn thường
const MAGIC_PROJECTILE_FRAMES: SpriteFrames = preload("res://assets/troops/wizard/MagicProjectileFrames.tres") ## Đòn thường
const MAGIC_SKILL_PROJECTILE_FRAMES: SpriteFrames = preload("res://assets/troops/wizard/MagicSkillProjectileFrames.tres") ## Đòn mạnh
const PRIEST_ATTACK_EFFECT_FRAMES: SpriteFrames = preload("res://assets/troops/priest/PriestAttackEffectFrames.tres")
const PRIEST_HEAL_EFFECT_FRAMES: SpriteFrames = preload("res://assets/troops/priest/PriestHealEffectFrames.tres")

const POPUP_SPAWN_OFFSET: Vector2 = Vector2(0, -70) ## Cao hơn thanh máu 1 chút
const COLOR_DAMAGE_NORMAL: Color = Color.WHITE
const COLOR_DAMAGE_SKILL: Color = Color(1.0, 0.6, 0.0) ## cam
const COLOR_HEAL: Color = Color(0.3, 0.9, 0.3) ## xanh lá
const COLOR_GOLD: Color = Color(1.0, 0.9, 0.3)
const COLOR_MATERIAL: Color = Color(0.6, 0.85, 1.0)
const MATERIAL_DROP_CHANCE: float = 0.7 ## hạ 1 quái = 70% rơi đúng 1 nguyên liệu cấp 1 (ngẫu nhiên trong 10 nhóm)

## Bán kính hitbox va chạm để lính không đè khít lên nhau - nhỏ hơn hẳn hitbox
## logic dùng cho tầm đánh (TroopUnit.HITBOX_DIAMETER/2). Không dùng physics
## thật vì lính di chuyển bằng cách gán thẳng .position mỗi frame, nên tự đẩy
## nhau ở resolve_collisions().
const COLLISION_RADIUS: float = TroopUnit.HITBOX_DIAMETER / 4.0
const AVOIDANCE_RADIUS: float = COLLISION_RADIUS * 4.0
const AVOIDANCE_WEIGHT: float = 0.8 ## <1 = Seek luôn có ảnh hưởng nhiều hơn

const SKILL_INTERVAL: float = 2.0 ## Đánh mạnh tự động kích hoạt mỗi 2 giây
const PRIEST_SKILL_INTERVAL: float = 1.0 ## Riêng Priest: chu kỳ ngắn hơn hẳn để hồi máu/đánh thường xen kẽ rõ hơn
const SKILL_DAMAGE_MULT: float = 2.0
const PRIEST_HEAL_RATIO: float = 0.5 ## Riêng Priest: skill hồi máu = 50% ATK thay vì đòn mạnh gây sát thương
const ATTACK_READY_HOLD: float = 0.15 ## Đòn thường giữ 1 nhịp "sẵn sàng" ngắn trước khi ra đòn, để thanh đánh thường kịp hiện màu sẵn sàng
const REGEN_INTERVAL: float = 5.0 ## Lính hồi máu mỗi 5 giây theo regen_hp

var arena: Node2D ## nơi spawn đạn bay/hiệu ứng/popup - do map truyền vào lúc khởi tạo
var grant_gold_on_kill: bool ## true (StageFarmWorld) = cộng vàng + hiện popup NGAY lúc giết; false (BattleScene) = map tự cộng vàng 1 cục lúc thắng, resolver chỉ lo EXP/rớt đồ
var debug_freeze_units: bool = false ## true = mọi unit chỉ quay mặt về mục tiêu, không di chuyển/tấn công - map tự bật qua const debug riêng nếu cần

func _init(p_arena: Node2D, p_grant_gold_on_kill: bool) -> void:
	arena = p_arena
	grant_gold_on_kill = p_grant_gold_on_kill

## Chạy AI 1 frame cho CẢ 2 phe - gọi 1 lần/frame từ map. `reward_troop_ids`
## (đội nhận EXP/vàng khi hạ quái) truyền MỚI mỗi lần gọi thay vì lưu lại lúc
## khởi tạo, vì StageFarmWorld có thể đổi thành viên treo máy giữa chừng.
## `free_movement_x`: phe PLAYER chỉ được di chuyển tới mục tiêu nếu
## `target.position.x <= free_movement_x` (quái đã lọt vào 1/4 bên phải khung
## hình camera) - map tự tính theo viewport thật của mình, xem ghi chú đầu file.
func run_ai(player_units: Array[TroopUnit], enemy_units: Array[TroopUnit], delta: float, reward_troop_ids: Array[int], free_movement_x: float) -> void:
	_update_side(player_units, enemy_units, delta, reward_troop_ids, free_movement_x)
	_update_side(enemy_units, player_units, delta, reward_troop_ids, free_movement_x)

## Không còn squad cố định - mỗi unit tự tìm địch gần nhất, nhưng các unit
## đang nhắm CHUNG 1 mục tiêu được gom lại và chia đều góc vây quanh mục tiêu
## đó (Attack Slot), tính lại MỖI FRAME - tránh đứng đè khít lên nhau.
func _update_side(units: Array[TroopUnit], enemies: Array[TroopUnit], delta: float, reward_troop_ids: Array[int], free_movement_x: float) -> void:
	var target_of: Dictionary = {} ## unit -> TroopUnit (null nếu hết địch)
	var group_by_target: Dictionary = {} ## TroopUnit mục tiêu -> Array[TroopUnit] đang cùng nhắm nó
	for unit in units:
		if unit.is_dead():
			continue
		var target := _find_nearest(unit, enemies)
		target_of[unit] = target
		if target != null:
			if not group_by_target.has(target):
				group_by_target[target] = []
			group_by_target[target].append(unit)

	var slot_of: Dictionary = {}
	for target in group_by_target:
		var group: Array = group_by_target[target]
		for i in range(group.size()):
			slot_of[group[i]] = TAU * i / group.size()

	for unit in units:
		_update_unit(unit, target_of.get(unit), slot_of.get(unit, 0.0), units, delta, reward_troop_ids, free_movement_x)

func _find_nearest(unit: TroopUnit, pool: Array[TroopUnit]) -> TroopUnit:
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

## Local Avoidance: lực đẩy tổng hợp từ mọi đồng đội (CÙNG PHE) đang đứng
## trong bán kính AVOIDANCE_RADIUS quanh unit - càng gần đẩy càng mạnh. Cộng
## vào hướng Seek (hướng tới slot) để lính tự lệch đường vòng qua chỗ đông.
func _compute_avoidance(unit: TroopUnit, allies: Array[TroopUnit]) -> Vector2:
	var avoidance := Vector2.ZERO
	for ally in allies:
		if ally == unit or ally.is_dead():
			continue
		var offset := unit.position - ally.position
		var dist := offset.length()
		if dist < AVOIDANCE_RADIUS and dist > 0.001:
			avoidance += offset.normalized() * (AVOIDANCE_RADIUS - dist) / AVOIDANCE_RADIUS
	return avoidance

func _skill_pause(unit: TroopUnit) -> float:
	return unit.attack_interval() * 0.5

func _update_unit(unit: TroopUnit, target: TroopUnit, slot_angle: float, allies: Array[TroopUnit], delta: float, reward_troop_ids: Array[int], free_movement_x: float) -> void:
	if unit.is_dead():
		return
	unit.attack_cooldown = maxf(unit.attack_cooldown - delta, 0.0)
	unit.skill_cooldown = maxf(unit.skill_cooldown - delta, 0.0)
	unit.regen_cooldown += delta
	if unit.regen_cooldown >= REGEN_INTERVAL:
		unit.regen_cooldown = 0.0
		unit.heal(unit.troop_data.regen_hp)

	if target == null:
		unit.is_engaged = false
		unit.play_idle()
		return

	unit.face_towards(target.position)
	if debug_freeze_units:
		unit.is_engaged = false
		unit.play_idle()
		return ## chỉ quay mặt về mục tiêu, không di chuyển/tấn công

	var distance := unit.position.distance_to(target.position)
	if distance > unit.attack_range_px():
		unit.is_engaged = false
		unit.play_walk()
		## Mô hình treadmill: phe ĐỊCH luôn được di chuyển tới. Phe MÌNH chỉ
		## được di chuyển nếu mục tiêu đã lọt vào free_movement_x (1/4 bên
		## phải khung hình camera) - tránh bug quái tầm xa dừng đánh từ xa hơn
		## tầm lính mình mà lính mình bị khoá đứng yên tuyệt đối, không phản
		## kháng được (2026-08).
		var can_move: bool = unit.team == Enums.Team.ENEMY or target.position.x <= free_movement_x
		if can_move:
			var slot_position := target.position + Vector2.RIGHT.rotated(slot_angle) * (unit.attack_range_px() * 0.85)
			var seek := (slot_position - unit.position).normalized()
			var avoidance := _compute_avoidance(unit, allies)
			var combined := seek + avoidance * AVOIDANCE_WEIGHT
			var move_dir := combined.normalized() if combined.length() > 0.05 else seek
			unit.position += move_dir * unit.move_speed_px() * delta
		return

	unit.is_engaged = true
	var is_priest: bool = unit.troop_data.character_key == "priest"

	if unit.skill_recovery_timer > 0.0:
		unit.skill_recovery_timer = maxf(unit.skill_recovery_timer - delta, 0.0)
		return

	if unit.skill_windup_timer >= 0.0:
		unit.skill_windup_timer -= delta
		if unit.skill_windup_timer <= 0.0:
			unit.skill_windup_timer = -1.0
			unit.skill_cooldown_max = PRIEST_SKILL_INTERVAL if is_priest else SKILL_INTERVAL
			unit.skill_cooldown = unit.skill_cooldown_max
			if is_priest:
				_priest_cast(unit, target, allies, reward_troop_ids)
			else:
				unit.play_attack()
				_resolve_attack(unit, target, true, reward_troop_ids)
			unit.skill_recovery_timer = _skill_pause(unit)
			unit.attack_cooldown = unit.attack_interval()
		return

	if unit.skill_cooldown <= 0.0:
		unit.skill_windup_timer = _skill_pause(unit)
		return

	if unit.attack_windup_timer >= 0.0:
		unit.attack_windup_timer -= delta
		if unit.attack_windup_timer <= 0.0:
			unit.attack_windup_timer = -1.0
			unit.attack_cooldown = unit.attack_interval()
			unit.play_attack()
			_resolve_attack(unit, target, false, reward_troop_ids)
		return

	if unit.attack_cooldown <= 0.0:
		unit.attack_windup_timer = ATTACK_READY_HOLD

func _priest_cast(unit: TroopUnit, target: TroopUnit, allies: Array[TroopUnit], reward_troop_ids: Array[int]) -> void:
	unit.skill_toggle = not unit.skill_toggle
	if unit.skill_toggle:
		var ally := _find_heal_target(allies)
		if ally != null:
			unit.play_heal()
			_apply_heal(unit, ally)
			return
	unit.play_attack()
	_resolve_attack(unit, target, false, reward_troop_ids)

func _find_heal_target(allies: Array[TroopUnit]) -> TroopUnit:
	var best: TroopUnit = null
	var best_ratio := INF
	for ally in allies:
		if ally.is_dead():
			continue
		var ratio: float = ally.current_hp / ally.max_hp()
		if ratio < best_ratio:
			best_ratio = ratio
			best = ally
	return best

func _apply_heal(caster: TroopUnit, ally: TroopUnit) -> void:
	var heal_amount: float = caster.effective_atk() * PRIEST_HEAL_RATIO
	ally.heal(heal_amount)
	_spawn_heal_popup(ally, heal_amount)
	_spawn_impact_effect(ally.position, PRIEST_HEAL_EFFECT_FRAMES)

## Sát thương = ATK HIỆU DỤNG nhân Crit Damage nếu chí mạng, nhân thêm
## SKILL_DAMAGE_MULT nếu là đòn "Đánh mạnh", trừ giáp hiệu quả của đối phương
## (DEF nếu đòn vật lý, M.DEF nếu đòn phép), giáp hiệu quả giảm theo Armor
## Penetration. Tối thiểu 1 sát thương.
func _resolve_attack(attacker: TroopUnit, defender: TroopUnit, is_skill: bool, reward_troop_ids: Array[int]) -> void:
	var atk_data := attacker.troop_data
	var is_crit := randf() < atk_data.crit_rate
	var base_damage: float = attacker.effective_atk() * (atk_data.crit_damage if is_crit else 1.0)
	if is_skill:
		base_damage *= SKILL_DAMAGE_MULT
	var raw_defense: float = defender.effective_m_def() if atk_data.damage_type == Enums.DamageType.MAGIC else defender.effective_def()
	var effective_defense: float = raw_defense * (1.0 - atk_data.armor_penetration / 100.0)
	var final_damage: float = maxf(base_damage - effective_defense, 1.0)

	match atk_data.character_key:
		"archer":
			_spawn_arrow(attacker, defender, final_damage, is_skill, reward_troop_ids)
		"wizard":
			_spawn_magic_bolt(attacker, defender, final_damage, is_skill, reward_troop_ids)
		"priest":
			_apply_damage(attacker, defender, final_damage, is_skill, reward_troop_ids)
			_spawn_impact_effect(defender.position, PRIEST_ATTACK_EFFECT_FRAMES)
		_:
			_apply_damage(attacker, defender, final_damage, is_skill, reward_troop_ids)

func _apply_damage(attacker: TroopUnit, defender: TroopUnit, final_damage: float, is_skill: bool, reward_troop_ids: Array[int]) -> void:
	if defender.is_dead():
		return
	defender.take_damage(final_damage)
	_spawn_damage_popup(defender, final_damage, is_skill)
	if attacker.troop_data.life_steal > 0.0:
		attacker.heal(final_damage * attacker.troop_data.life_steal)
	if defender.is_dead() and defender.team == Enums.Team.ENEMY:
		## Hạ quái - CẢ ĐỘI (reward_troop_ids) nhận EXP của con đó, y hệt quy
		## ước "giết quái thì cả team nhận EXP" ở cả 2 map.
		GameState.grant_kill_exp(reward_troop_ids, defender.troop_data.exp_reward)
		if grant_gold_on_kill:
			GameState.add_gold(defender.troop_data.gold_reward)
			_spawn_gold_popup(defender, defender.troop_data.gold_reward)
		_roll_material_drop(defender)

## Hạ 1 quái = MATERIAL_DROP_CHANCE (70%) rơi đúng 1 nguyên liệu cấp 1, ngẫu
## nhiên trong 10 nhóm (xem MaterialDatabase.random_tier1_id) - cộng thẳng
## vào GameState.materials (WarehousePanel/InventoryScreen đọc trực tiếp từ đó).
func _roll_material_drop(defender: TroopUnit) -> void:
	if randf() >= MATERIAL_DROP_CHANCE:
		return
	var material_id := MaterialDatabase.random_tier1_id()
	GameState.add_material(material_id, 1)
	var mat := MaterialDatabase.get_by_id(material_id)
	_spawn_loot_popup(defender, "+1 %s" % mat.display_name, COLOR_MATERIAL, Vector2(0, -32))

func _spawn_loot_popup(unit: TroopUnit, text: String, color: Color, extra_offset: Vector2 = Vector2.ZERO) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	arena.add_child(popup)
	popup.setup(text, color, unit.position + POPUP_SPAWN_OFFSET + extra_offset)

func _spawn_gold_popup(unit: TroopUnit, amount: int) -> void:
	_spawn_loot_popup(unit, "+%d vàng" % amount, COLOR_GOLD, Vector2(0, -16))

func _spawn_arrow(attacker: TroopUnit, defender: TroopUnit, final_damage: float, is_skill: bool, reward_troop_ids: Array[int]) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	arena.add_child(projectile)
	var visual_scale: float = ARROW_SKILL_SCALE if is_skill else 1.0
	projectile.setup_static(attacker.position, defender.position, ARROW_TEXTURE, func(): _apply_damage(attacker, defender, final_damage, is_skill, reward_troop_ids), visual_scale)

func _spawn_magic_bolt(attacker: TroopUnit, defender: TroopUnit, final_damage: float, is_skill: bool, reward_troop_ids: Array[int]) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	arena.add_child(projectile)
	var frames: SpriteFrames = MAGIC_SKILL_PROJECTILE_FRAMES if is_skill else MAGIC_PROJECTILE_FRAMES
	projectile.setup_animated(attacker.position, defender.position, frames, "cast", func(): _apply_damage(attacker, defender, final_damage, is_skill, reward_troop_ids))

func _spawn_impact_effect(world_position: Vector2, frames: SpriteFrames) -> void:
	var effect: ImpactEffect = IMPACT_EFFECT_SCENE.instantiate()
	arena.add_child(effect)
	effect.setup(world_position, frames, "cast")

func _spawn_damage_popup(unit: TroopUnit, amount: float, is_skill: bool) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	arena.add_child(popup)
	var color := COLOR_DAMAGE_SKILL if is_skill else COLOR_DAMAGE_NORMAL
	popup.setup("-%d" % roundi(amount), color, unit.position + POPUP_SPAWN_OFFSET)

func _spawn_heal_popup(unit: TroopUnit, amount: float) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	arena.add_child(popup)
	popup.setup("+%d" % roundi(amount), COLOR_HEAL, unit.position + POPUP_SPAWN_OFFSET)

## Đẩy nhẹ 2 lính ra xa nhau nếu khoảng cách giữa 2 tâm < 2*COLLISION_RADIUS.
## Lính đang is_engaged (đứng yên trong tầm đánh) không bị đẩy trừ khi CẢ 2
## đều đang engaged - lính đang di chuyển băng qua sẽ tự nhường, không kéo
## lính đang đánh dở ra khỏi tầm.
func resolve_collisions(player_units: Array[TroopUnit], enemy_units: Array[TroopUnit]) -> void:
	var all_units: Array[TroopUnit] = player_units + enemy_units
	var min_dist := COLLISION_RADIUS * 2.0
	for i in range(all_units.size()):
		var a := all_units[i]
		if a.is_dead():
			continue
		for j in range(i + 1, all_units.size()):
			var b := all_units[j]
			if b.is_dead():
				continue
			var diff := b.position - a.position
			var dist := diff.length()
			if dist >= min_dist:
				continue
			var dir := diff.normalized() if dist > 0.001 else Vector2.RIGHT
			var push := min_dist - dist
			if a.is_engaged and not b.is_engaged:
				b.position += dir * push
			elif b.is_engaged and not a.is_engaged:
				a.position -= dir * push
			else:
				a.position -= dir * push * 0.5
				b.position += dir * push * 0.5
