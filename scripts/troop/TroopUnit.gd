class_name TroopUnit
extends Node2D

## 1 nhân vật trên chiến trường. Thuần theo dõi trạng thái + hiển thị (sprite
## hoạt ảnh, thanh máu) - toàn bộ AI di chuyển/tấn công do BattleScene điều
## khiển mỗi frame (không tự chạy AI ở đây) để dễ theo dõi thứ tự xử lý cả
## trận đấu ở 1 chỗ. Party cố định 4 người + quái mỗi ải đều là TroopUnit
## riêng biệt - không còn cơ chế dồn nhiều lính cùng loại vào 1 icon (xem
## LinhData/hp, effective_atk() giờ = troop_data.atk thẳng).
##
## Hoạt ảnh dùng bộ asset "Tiny RPG Character Asset Pack 01 v2.0 -Full 22
## Characters" (assets/troops/<character_key>/) - mỗi LinhData.character_key
## chọn đúng 1 bộ SpriteFrames + danh sách animation đánh riêng (xem
## CHARACTER_FRAMES/CHARACTER_ATTACK_ANIMS).

## Đường kính hitbox giả định để quy đổi Tầm đánh -> phạm vi tấn công thực tế
## - khớp với kích thước THẬT của nhân vật (không tính viền trong suốt quanh
## khung 100x100, nội dung idle rộng ~21-27px gốc, trung bình ~24px) nhân với
## AnimatedSprite2D.scale = 1.5 -> ~36 world-unit.
const HITBOX_DIAMETER: float = 36.0
## Move Speed (base 5) -> px/giây - chọn tạm 1 hệ số cố định (5 * 20 = 100px/s).
const MOVE_SPEED_SCALE: float = 20.0

const CHARACTER_FRAMES: Dictionary = {
	"soldier": preload("res://assets/troops/soldier/SoldierFrames.tres"),
	"swordsman": preload("res://assets/troops/swordsman/SwordsmanFrames.tres"),
	"knight": preload("res://assets/troops/knight/KnightFrames.tres"),
	"knight_templar": preload("res://assets/troops/knight_templar/KnightTemplarFrames.tres"),
	"lancer": preload("res://assets/troops/lancer/LancerFrames.tres"),
	"armored_axeman": preload("res://assets/troops/armored_axeman/ArmoredAxemanFrames.tres"),
	"archer": preload("res://assets/troops/archer/ArcherFrames.tres"),
	"wizard": preload("res://assets/troops/wizard/WizardFrames.tres"),
	"priest": preload("res://assets/troops/priest/PriestFrames.tres"),
	## Quái (Tiny RPG Character Asset Pack 01 v2.0 -Full 22 Characters) - dùng
	## làm quân địch trong data/stages/*.tres, xem GameState.PARTY_TROOP_IDS
	## (party chỉ dùng 4 nhân vật lính người ở trên, không dùng quái).
	"orc": preload("res://assets/troops/orc/OrcFrames.tres"),
	"armored_orc": preload("res://assets/troops/armored_orc/ArmoredOrcFrames.tres"),
	"elite_orc": preload("res://assets/troops/elite_orc/EliteOrcFrames.tres"),
	"orc_rider": preload("res://assets/troops/orc_rider/OrcRiderFrames.tres"),
	"skeleton": preload("res://assets/troops/skeleton/SkeletonFrames.tres"),
	"armored_skeleton": preload("res://assets/troops/armored_skeleton/ArmoredSkeletonFrames.tres"),
	"greatsword_skeleton": preload("res://assets/troops/greatsword_skeleton/GreatswordSkeletonFrames.tres"),
	"skeleton_archer": preload("res://assets/troops/skeleton_archer/SkeletonArcherFrames.tres"),
	"slime": preload("res://assets/troops/slime/SlimeFrames.tres"),
	"bat": preload("res://assets/troops/bat/BatFrames.tres"),
	"werebear": preload("res://assets/troops/werebear/WerebearFrames.tres"),
	"werewolf": preload("res://assets/troops/werewolf/WerewolfFrames.tres"),
	"necromancer": preload("res://assets/troops/necromancer/NecromancerFrames.tres"),
}
const CHARACTER_ATTACK_ANIMS: Dictionary = {
	"soldier": ["attack01", "attack02", "attack03"],
	"swordsman": ["attack01", "attack02", "attack03"],
	"knight": ["attack01", "attack02", "attack03"],
	"knight_templar": ["attack01", "attack02", "attack03"],
	"lancer": ["attack01", "attack02", "attack03"],
	"armored_axeman": ["attack01", "attack02", "attack03"],
	"archer": ["attack01", "attack02"],
	"wizard": ["attack01", "attack02"],
	"priest": ["attack01"],
	"orc": ["attack01", "attack02"],
	"armored_orc": ["attack01", "attack02", "attack03"],
	"elite_orc": ["attack01", "attack02", "attack03"],
	"orc_rider": ["attack01", "attack02", "attack03"],
	"skeleton": ["attack01", "attack02"],
	"armored_skeleton": ["attack01", "attack02"],
	"greatsword_skeleton": ["attack01", "attack02", "attack03"],
	"skeleton_archer": ["attack01"],
	"slime": ["attack01", "attack02"],
	"bat": ["attack01", "attack02"],
	"werebear": ["attack01", "attack02", "attack03"],
	"werewolf": ["attack01", "attack02"],
	"necromancer": ["attack01", "attack02"],
}
const DEFAULT_CHARACTER_KEY: String = "soldier" ## LinhData.character_key rỗng/không khớp -> dùng tạm nhân vật này

## Phe mình: xanh lá (đầy) -> đỏ (sắp chết). Phe địch: luôn tông đỏ để phân
## biệt phe ngay từ xa, đậm (đầy) -> nhạt/sẫm (sắp chết).
const HP_FULL_COLOR: Color = Color(0.3, 0.9, 0.3)
const HP_LOW_COLOR: Color = Color(0.9, 0.2, 0.2)
const HP_FULL_COLOR_ENEMY: Color = Color(0.9, 0.15, 0.15)
const HP_LOW_COLOR_ENEMY: Color = Color(0.4, 0.05, 0.05)

## 2 thanh hồi chiêu dưới thanh máu (đánh thường + skill) - trắng trong lúc
## đang hồi, chuyển màu theo phe khi đã sẵn sàng (đầy) để dễ nhận biết lúc
## nào lính sắp ra đòn tiếp theo.
const COOLDOWN_BAR_CHARGING_COLOR: Color = Color(1, 1, 1)
const COOLDOWN_BAR_READY_COLOR_PLAYER: Color = Color(0.3, 0.9, 0.3)
const COOLDOWN_BAR_READY_COLOR_ENEMY: Color = Color(0.95, 0.85, 0.15)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar_bg: ColorRect = $HpBarBg
@onready var hp_bar_fill: ColorRect = $HpBarBg/HpBarFill
@onready var attack_bar_bg: ColorRect = $SkillStatus/AttackBarBg
@onready var attack_bar_fill: ColorRect = $SkillStatus/AttackBarBg/AttackBarFill
@onready var skill_bar_bg: ColorRect = $SkillStatus/SkillBarBg
@onready var skill_bar_fill: ColorRect = $SkillStatus/SkillBarBg/SkillBarFill

var troop_data: LinhData
var team: Enums.Team
var current_hp: float = 0.0
var attack_cooldown: float = 0.0
var skill_cooldown: float = 0.0 ## "Đánh mạnh" - xem BattleScene.SKILL_INTERVAL/SKILL_DAMAGE_MULT
var skill_cooldown_max: float = 1.0 ## BattleScene set kèm mỗi lần gán skill_cooldown - để thanh skill biết % đã hồi (SKILL_INTERVAL khác nhau theo loại lính)
var skill_toggle: bool = false ## Riêng Priest: xen kẽ đánh thường/hồi máu mỗi lần skill_cooldown sẵn sàng - xem BattleScene._priest_cast
var skill_windup_timer: float = -1.0 ## >=0: đang trong khoảng nghỉ TRƯỚC lúc skill thật sự ra hiệu ứng - xem BattleScene._update_unit
var skill_recovery_timer: float = 0.0 ## >0: đang trong khoảng nghỉ SAU khi vừa tung skill xong
var attack_windup_timer: float = -1.0 ## >=0: đòn đánh thường đã sẵn sàng, đang giữ 1 nhịp ngắn (ATTACK_READY_HOLD) trước khi thật sự ra đòn - để thanh đánh thường kịp hiện màu sẵn sàng
var regen_cooldown: float = 0.0
var is_engaged: bool = false ## true khi đang trong tầm đánh của mục tiêu (đứng yên đánh nhau) - BattleScene._update_unit set mỗi frame, dùng để _resolve_collisions() không đẩy lính đang đánh ra khỏi tầm
var is_selected: bool = false ## true = đang được chọn trên overworld map (RTS-style, xem OverworldWorld) - không liên quan gì tới combat/BattleScene
var _attack_animations: Array[String] = []

func setup(data: LinhData, unit_team: Enums.Team) -> void:
	troop_data = data
	team = unit_team
	current_hp = data.hp
	var character_key: String = data.character_key if CHARACTER_FRAMES.has(data.character_key) else DEFAULT_CHARACTER_KEY
	animated_sprite.sprite_frames = CHARACTER_FRAMES[character_key]
	## "as Array[String]" không tự convert Array thường (kiểu lưu trong
	## Dictionary) sang typed array - phải dùng constructor Array() để ép kiểu
	## từng phần tử, nếu không sẽ lỗi runtime "Trying to assign an array of
	## type Array to a variable of type Array[String]".
	_attack_animations = Array(CHARACTER_ATTACK_ANIMS[character_key], TYPE_STRING, "", null)
	## Hướng mặc định trước khi có mục tiêu - phe mình đứng bên trái (quay
	## phải), phe địch đứng bên phải (quay trái); face_towards() sẽ cập nhật
	## lại theo vị trí mục tiêu thật mỗi frame ngay khi combat bắt đầu.
	animated_sprite.flip_h = team == Enums.Team.ENEMY
	animated_sprite.play("idle")
	_update_hp_bar()
	queue_redraw()

func is_dead() -> bool:
	return current_hp <= 0.0

## OverworldWorld gọi khi đổi chọn/bỏ chọn unit (click/kéo vùng chọn) - chỉ
## queue_redraw() khi thực sự đổi giá trị, tránh vẽ lại thừa mỗi frame.
func set_selected(value: bool) -> void:
	if is_selected == value:
		return
	is_selected = value
	queue_redraw()

func max_hp() -> float:
	return troop_data.hp

func effective_atk() -> float:
	return troop_data.atk

const SELECTION_RING_RADIUS: float = HITBOX_DIAMETER / 2.0 + 4.0
const SELECTION_RING_COLOR: Color = Color(1.0, 1.0, 0.4, 0.9)

## Không dùng CollisionShape2D thật (hitbox/tầm đánh chỉ là số liệu logic để
## so khoảng cách - xem attack_range_px), nên vẽ tay 2 vòng tròn tương đương
## để bật/tắt cùng nút có sẵn của Godot: Debug > Visible Collision Shapes. Vòng
## chọn (is_selected) tách riêng, luôn hiện khi đang chọn - không phụ thuộc
## debug_collisions_hint.
func _draw() -> void:
	if is_dead():
		return
	if is_selected:
		draw_arc(Vector2.ZERO, SELECTION_RING_RADIUS, 0.0, TAU, 32, SELECTION_RING_COLOR, 2.0)
	if not get_tree().debug_collisions_hint:
		return
	draw_circle(Vector2.ZERO, HITBOX_DIAMETER / 2.0, Color(0.2, 1.0, 0.2, 0.25))
	if troop_data != null:
		draw_arc(Vector2.ZERO, attack_range_px(), 0.0, TAU, 48, Color(1.0, 0.2, 0.2, 0.85), 2.0)

const MELEE_RANGE_COEF: float = 0.1
const RANGED_RANGE_COEF: float = 1.0

## Phạm vi tấn công = đường kính hitbox * (1 + tầm đánh * hệ_số), hệ số khác
## nhau theo troop_type - lính cận chiến (NORMAL) tăng chậm hơn hẳn lính
## đánh xa (ARCHER) theo mỗi điểm tầm đánh, để 2 nhóm không dùng chung 1
## đường cong.
func attack_range_px() -> float:
	var range_coef: float = RANGED_RANGE_COEF if troop_data.troop_type == Enums.TroopType.ARCHER else MELEE_RANGE_COEF
	return HITBOX_DIAMETER * (1.0 + troop_data.attack_range * range_coef)

## "1 điểm ATK Speed = 1 giây đánh được 0.1 lần" -> số đòn/giây = atk_speed * 0.1.
func attack_interval() -> float:
	var attacks_per_second: float = troop_data.atk_speed * 0.1
	return 1.0 / attacks_per_second if attacks_per_second > 0.0 else INF

func move_speed_px() -> float:
	return troop_data.move_speed * MOVE_SPEED_SCALE

## Quay mặt về phía mục tiêu (lật sprite theo trục X) - gọi mỗi frame trước
## khi di chuyển/tấn công để hướng luôn đúng khi mục tiêu đổi.
func face_towards(target_position: Vector2) -> void:
	if is_dead():
		return
	animated_sprite.flip_h = target_position.x < position.x

func play_walk() -> void:
	if is_dead() or _is_busy() or animated_sprite.animation == "walk":
		return
	animated_sprite.play("walk")

func play_idle() -> void:
	if is_dead() or _is_busy() or animated_sprite.animation == "idle":
		return
	animated_sprite.play("idle")

## Chọn ngẫu nhiên 1 trong các đòn đánh thường của loại lính này - gọi đúng
## lúc thật sự ra đòn (BattleScene._resolve_attack), không gọi mỗi frame.
func play_attack() -> void:
	if is_dead():
		return
	animated_sprite.play(_attack_animations.pick_random())

## Riêng Priest (animation "heal" - xem BattleScene._priest_cast).
func play_heal() -> void:
	if is_dead():
		return
	animated_sprite.play("heal")

## Đang giữa chừng hoạt ảnh "heal" hoặc 1 đòn đánh (không loop) - không cho
## walk/idle chen vào ngắt ngang cho tới khi hoạt ảnh đó tự chạy xong. Bị đánh
## trúng KHÔNG còn tính là busy nữa (xem take_damage - đổi sang nháy đỏ thay
## vì animation "hurt", để không ngắt animation tấn công đang đánh dở).
func _is_busy() -> bool:
	if not animated_sprite.is_playing():
		return false
	return animated_sprite.animation == "heal" or animated_sprite.animation in _attack_animations

func take_damage(amount: float) -> void:
	if is_dead():
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_update_hp_bar()
	if is_dead():
		animated_sprite.play("death")
		hp_bar_bg.visible = false
		attack_bar_bg.visible = false
		skill_bar_bg.visible = false
		queue_redraw() ## ẩn luôn 2 vòng tròn debug hitbox/tầm đánh (nếu đang bật Visible Collision Shapes)
	else:
		## Không dùng animation "hurt" nữa - nó ngắt ngang animation tấn công
		## đang đánh dở (unit ăn đòn liên tục thì gần như không bao giờ thấy
		## được tư thế đánh). Thay bằng nháy đỏ nhanh, không ảnh hưởng animation.
		_flash_hurt()

const HURT_FLASH_COLOR: Color = Color(1.0, 0.3, 0.3)
const HURT_FLASH_DURATION: float = 0.15

func _flash_hurt() -> void:
	animated_sprite.modulate = HURT_FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, HURT_FLASH_DURATION)

func heal(amount: float) -> void:
	if is_dead():
		return
	current_hp = minf(current_hp + amount, troop_data.hp)
	_update_hp_bar()

func _update_hp_bar() -> void:
	if troop_data == null:
		return
	var ratio := clampf(current_hp / max_hp(), 0.0, 1.0)
	hp_bar_fill.size.x = hp_bar_bg.size.x * ratio
	var full_color := HP_FULL_COLOR_ENEMY if team == Enums.Team.ENEMY else HP_FULL_COLOR
	var low_color := HP_LOW_COLOR_ENEMY if team == Enums.Team.ENEMY else HP_LOW_COLOR
	hp_bar_fill.color = full_color.lerp(low_color, 1.0 - ratio)

## Chỉ cập nhật hiển thị (đọc attack_cooldown/skill_cooldown do BattleScene
## chỉnh mỗi frame) - không tự chạy AI/logic gì ở đây, giữ đúng nguyên tắc
## toàn bộ luật chơi nằm ở BattleScene.
func _process(_delta: float) -> void:
	if troop_data == null or is_dead():
		return
	_update_cooldown_bar(attack_bar_fill, attack_bar_bg, attack_cooldown, attack_interval())
	_update_cooldown_bar(skill_bar_fill, skill_bar_bg, skill_cooldown, skill_cooldown_max)

func _update_cooldown_bar(fill: ColorRect, bg: ColorRect, cooldown: float, max_value: float) -> void:
	var ratio := 1.0 if max_value <= 0.0 else clampf(1.0 - cooldown / max_value, 0.0, 1.0)
	fill.size.x = bg.size.x * ratio
	if cooldown <= 0.0:
		fill.color = COOLDOWN_BAR_READY_COLOR_ENEMY if team == Enums.Team.ENEMY else COOLDOWN_BAR_READY_COLOR_PLAYER
	else:
		fill.color = COOLDOWN_BAR_CHARGING_COLOR
