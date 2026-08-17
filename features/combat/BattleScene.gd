class_name BattleScene
extends Control

## Màn chiến đấu PvE - auto-battle: bấm "Chọn ải" xong vào thẳng trận, không
## còn pha "xếp quân" (party cố định 4 người, không có gì để chọn trước mỗi
## trận - xem GameState.PARTY_TROOP_IDS). start_battle(stage) spawn phe mình
## vào %BattleArena (SubViewport riêng) rồi lần lượt spawn N đợt quái thường
## NGẪU NHIÊN (StageData.boss_trash_wave_count, xem EncounterGenerator) cách
## nhau WAVE_SPACING_X dọc trục X, đợt CUỐI CÙNG luôn là boss thật
## (enemy_troop_ids/enemy_troop_counts) - xem _spawn_next_wave()/_check_battle_end().
##
## Camera BÁM LIÊN TỤC theo 1 NHÂN VẬT CỤ THỂ trong phe mình (không phải trung
## bình cả đội, không khoá cứng theo area/wave/boss) - chọn theo tầm đánh,
## thứ tự ưu tiên đổi tuỳ đã giao chiến hay chưa, giống hệt StageFarmWorld -
## xem _pick_camera_follow_unit()/_update_camera_follow().
##
## Trận kết thúc khi phe mình chết hết/hết giờ (THUA) hoặc đợt boss chết (THẮNG).
##
## Quyết định thiết kế (kế thừa từ bản city-builder cũ, xem lịch sử):
## - Sát thương = ATK (x Crit Damage nếu chí mạng) TRỪ THẲNG (không phải %)
##   giáp hiệu quả = DEF/M.DEF x (1 - Armor Penetration/100), tối thiểu 1 sát
##   thương mỗi đòn để trận đấu luôn có hồi kết.
## - Skill "Đánh mạnh": cứ mỗi SKILL_INTERVAL giây, đòn tiếp theo trong tầm
##   đánh tự động là 1 đòn mạnh (x SKILL_DAMAGE_MULT sát thương) thay cho đòn
##   thường. Riêng Priest không có đòn mạnh - skill xen kẽ giữa hồi máu đồng
##   đội (HP thấp nhất, = PRIEST_HEAL_RATIO x ATK) và 1 đòn đánh thường, xem
##   _priest_cast().
## - Đạn bay (Projectile): character_key "archer"/"wizard" spawn 1 Projectile
##   bay từ người bắn tới mục tiêu, sát thương chỉ áp dụng khi đạn TỚI NƠI.
##   Priest không dùng Projectile - áp dụng ngay lập tức kèm 1 ImpactEffect.
## - Không còn squad/dồn lính: mỗi TroopUnit là 1 nhân vật/quái riêng biệt.
##   AI target vẫn tự gom các unit đang nhắm CHUNG 1 mục tiêu để chia góc vây
##   quanh mục tiêu đó (tránh đứng đè lên nhau), tính lại mỗi frame thay vì
##   theo squad cố định - xem _update_side().
## - Đội hình: dùng 1 bộ offset hình nêm cố định (FORMATION_OFFSETS, kế thừa ý
##   tưởng từ BattleHexCell cũ) quanh tâm đội hình mỗi phe, mirror theo trục X
##   cho phe địch. Party 4 người luôn vừa trong 6 vị trí; quái MỖI ĐỢT (trash =
##   EncounterGenerator.BASE_MONSTERS_PER_WAVE = 5, boss = enemy_troop_ids/counts
##   của StageData) nên giữ tổng số <= 6 để đội hình không đè lên nhau (v1 chưa
##   cần > 6) - chỉ 1 đợt tồn tại trên màn cùng lúc, không cộng dồn giữa các đợt.

signal closed(won: bool) ## StageFlowController lắng nghe để biết có mở khoá tầng kế tiếp không (xem tab "Vượt ải")

const TROOP_UNIT_SCENE: PackedScene = preload("res://entities/troop/TroopUnit.tscn")
const PROJECTILE_SCENE: PackedScene = preload("res://entities/troop/Projectile.tscn")
const ARROW_TEXTURE: Texture2D = preload("res://assets/troops/archer/ArrowProjectile.png")
const ARROW_SKILL_SCALE: float = 1.5 ## Đòn mạnh của cung thủ vẫn dùng chung ảnh mũi tên, chỉ phóng to hơn để phân biệt với đòn thường
const MAGIC_PROJECTILE_FRAMES: SpriteFrames = preload("res://assets/troops/wizard/MagicProjectileFrames.tres") ## Đòn thường
const MAGIC_SKILL_PROJECTILE_FRAMES: SpriteFrames = preload("res://assets/troops/wizard/MagicSkillProjectileFrames.tres") ## Đòn mạnh
const IMPACT_EFFECT_SCENE: PackedScene = preload("res://entities/troop/ImpactEffect.tscn")
const PRIEST_ATTACK_EFFECT_FRAMES: SpriteFrames = preload("res://assets/troops/priest/PriestAttackEffectFrames.tres")
const PRIEST_HEAL_EFFECT_FRAMES: SpriteFrames = preload("res://assets/troops/priest/PriestHealEffectFrames.tres")

const DAMAGE_POPUP_SCENE: PackedScene = preload("res://entities/troop/DamagePopup.tscn")
const POPUP_SPAWN_OFFSET: Vector2 = Vector2(0, -70) ## Cao hơn thanh máu 1 chút
const COLOR_DAMAGE_NORMAL: Color = Color.WHITE
const COLOR_DAMAGE_SKILL: Color = Color(1.0, 0.6, 0.0) ## cam
const COLOR_HEAL: Color = Color(0.3, 0.9, 0.3) ## xanh lá
const COLOR_MATERIAL: Color = Color(0.6, 0.85, 1.0)
const MATERIAL_DROP_CHANCE: float = 0.7 ## hạ 1 quái = 70% rơi đúng 1 nguyên liệu cấp 1 (ngẫu nhiên trong 10 nhóm, giống StageFarmWorld._roll_material_drop)

## Bán kính hitbox va chạm để lính không đè khít lên nhau - nhỏ hơn hẳn
## hitbox logic dùng cho tầm đánh (TroopUnit.HITBOX_DIAMETER/2). Không dùng
## physics thật vì lính di chuyển bằng cách gán thẳng .position mỗi frame
## (xem _update_unit), nên tự đẩy nhau ở _resolve_collisions().
const COLLISION_RADIUS: float = TroopUnit.HITBOX_DIAMETER / 4.0

## Đội hình hình nêm quanh tâm đội - hand-copy từ BattleHexCell.FORMATION_OFFSETS
## của bản city-builder cũ (mũi nhọn hướng về phía địch, 2 hàng giữa, 3 hậu
## phương). offset[0] là mũi (đứng gần địch nhất - nên là tank).
const FORMATION_OFFSETS: Array[Vector2] = [
	Vector2(1.2, 0.0), ## mũi nhọn
	Vector2(0.0, -0.5), Vector2(0.0, 0.5), ## hàng giữa x2
	Vector2(-1.2, -1.0), Vector2(-1.2, 0.0), Vector2(-1.2, 1.0), ## hậu phương x3
]
const FORMATION_WORLD_SPACING: float = 40.0
const PLAYER_TEAM_CENTER: Vector2 = Vector2(-180, 0)

## Bản đồ dài nhiều đợt (giống StageFarmWorld, xem EncounterGenerator) - N đợt
## quái thường NGẪU NHIÊN (StageData.boss_trash_wave_count) trước khi tới đợt
## CUỐI CÙNG là boss thật (enemy_troop_ids/enemy_troop_counts). Camera kiểu
## Taskbar Heroes - KHÔNG follow theo pixel, chỉ đổi target lúc chuyển đợt,
## đúng kiểu StageFarmWorld (xem _update_camera_follow()).
const WAVE_SPACING_X: float = 900.0 ## khoảng cách world-X giữa 2 đợt liên tiếp
const FIRST_WAVE_OFFSET_X: float = 260.0 ## khoảng cách từ PLAYER_TEAM_CENTER tới đợt đầu tiên - đủ xa để phe mình tốn ~1-2s đi tới thay vì đứng chung chỗ với quái ngay từ đầu, giống hệt StageFarmWorld
const WAVE_CLEAR_DELAY: float = 0.6 ## nghỉ ngắn giữa 2 đợt (không kết thúc trận)
const CAMERA_FOLLOW_LERP_SPEED: float = 4.0 ## hệ số lerp/giây - camera lerp mượt tới _camera_target_x, giống hệt StageFarmWorld

## --- Giới hạn bản đồ (2026-08) ---
## Trước đây _wave_anchor_x cộng dồn WAVE_SPACING_X mãi mãi theo
## boss_trash_wave_count -> world dài vô hạn, không có limit_left/right thật,
## BattleArenaBackground rộng cố định quanh world X=0 nên khi camera cuộn quá
## đợt 1, nền đen (Background, ColorRect ngoài SubViewport) lộ ra phía sau.
## TRASH_WAVE_SLOTS = số vị trí X CỐ ĐỊNH mà đợt quái thường xoay vòng qua.
## boss_trash_wave_count hiện luôn = 3 (mặc định StageData, chưa .tres nào
## chỉnh) nên trong thực tế KHÔNG BAO GIỜ phải xoay vòng thật - đây là lưới an
## toàn cho sau này nếu 1 độ khó (vd *_kho.tres) tăng số đợt thường lên > 3.
## Nếu có xoay vòng thật, _recenter_world() dịch lại party + camera lùi về
## đúng lúc không có quái trên màn (WAVE_CLEAR_DELAY) để giữ cảm giác "luôn
## tiến về phía trước" mà KHÔNG để toạ độ world lớn dần vô hạn - xem
## _spawn_next_wave().
const TRASH_WAVE_SLOTS: int = 3
## Boss LUÔN đứng ở vị trí CỐ ĐỊNH ngay sau vị trí đợt thường xa nhất, bất kể
## trước đó có bao nhiêu đợt/có xoay vòng hay không - camera khoá đứng yên tại
## đây suốt trận boss (xem _update_camera_follow()), không cần code "camera
## nudge" riêng cho boss.
const BOSS_ANCHOR_X: float = PLAYER_TEAM_CENTER.x + FIRST_WAVE_OFFSET_X + TRASH_WAVE_SLOTS * WAVE_SPACING_X

const CAMERA_VIEW_MARGIN: float = 40.0 ## đệm dôi thêm, tránh clamp chạm biên đúng lúc đang cần thấy trọn cảnh

const SKILL_INTERVAL: float = 2.0 ## Đánh mạnh tự động kích hoạt mỗi 2 giây
const PRIEST_SKILL_INTERVAL: float = 1.0 ## Riêng Priest: chu kỳ ngắn hơn hẳn để hồi máu/đánh thường xen kẽ rõ hơn
const SKILL_DAMAGE_MULT: float = 2.0
const PRIEST_HEAL_RATIO: float = 0.5 ## Riêng Priest: skill hồi máu = 50% ATK thay vì đòn mạnh gây sát thương

## ================== DEBUG (đổi lại true nếu cần bật lại lúc test) ==================
const DEBUG_SHOW_COLLISION_SHAPES: bool = false
const DEBUG_FREEZE_UNITS: bool = false

@onready var arena: Node2D = %BattleArena
@onready var battle_camera: Camera2D = %BattleCamera
@onready var battle_arena_background: ColorRect = %BattleArenaBackground
@onready var timer_label: Label = %BattleTimerLabel
@onready var result_panel: PanelContainer = %BattleResultPanel
@onready var result_title: Label = %BattleResultTitle
@onready var result_reward: Label = %BattleResultReward
@onready var result_close_button: Button = %BattleResultCloseButton
@onready var surrender_button: Button = %SurrenderButton

var _stage: StageData
var _player_units: Array[TroopUnit] = []
var _enemy_units: Array[TroopUnit] = []
var _time_left: float = 0.0
var _active: bool = false ## true = đang chạy AI mỗi frame (xem _process)
var _last_result_won: bool = false ## lưu lại từ _end_battle() để _on_result_closed() phát kèm signal closed(won)

var _wave_count: int = 1 ## boss_trash_wave_count + 1 (đợt cuối = boss thật) - xem start_battle()
var _current_wave_index: int = -1 ## đợt đang đánh (0-based), -1 = chưa spawn đợt nào
var _wave_anchor_x: float = 0.0 ## tâm X của đợt HIỆN TẠI - tính lại mỗi lần _spawn_next_wave() theo slot xoay vòng (xem TRASH_WAVE_SLOTS) hoặc BOSS_ANCHOR_X nếu là đợt boss
var _wave_transition_timer: float = -1.0 ## >=0: đang nghỉ WAVE_CLEAR_DELAY giữa 2 đợt (KHÔNG kết thúc trận - chỉ đợt cuối chết mới end battle)

const CAMERA_FOLLOW_SWITCH_HOLD: float = 0.6 ## giữ nguyên nhân vật đang bám tối thiểu chừng này giây trước khi cho đổi lại - tránh camera "lật" liên tục nếu is_engaged nhấp nháy, giống hệt StageFarmWorld
const CAMERA_LOOKAHEAD_X: float = 60.0 ## camera lệch sang PHẢI 1 khoảng nhỏ so với nhân vật đang bám - nhân vật hiện rõ hơn ở bên trái tâm màn hình, giống hệt StageFarmWorld

var _camera_follow_unit: TroopUnit = null ## unit ĐANG được camera bám - chỉ đánh giá lại lựa chọn khi hết CAMERA_FOLLOW_SWITCH_HOLD hoặc unit này vừa chết, xem _update_camera_follow()
var _camera_follow_switch_cooldown: float = 0.0
var _camera_target_x: float = 0.0 ## = _camera_follow_unit.position.x + CAMERA_LOOKAHEAD_X (hoặc PLAYER_TEAM_CENTER.x nếu hết phe mình) - lưu ở đây chỉ để tiện đọc/debug, battle_camera.position lerp mượt tới giá trị này chứ không gán thẳng
var _camera_limit_left: float = 0.0 ## tính theo viewport THẬT lúc _ready() (không hard-code độ phân giải) - xem _ready()
var _camera_limit_right: float = 0.0

func _ready() -> void:
	visible = false
	result_panel.visible = false
	result_close_button.pressed.connect(_on_result_closed)
	surrender_button.pressed.connect(_on_surrender_pressed)
	if DEBUG_SHOW_COLLISION_SHAPES:
		get_tree().debug_collisions_hint = true
	battle_camera.zoom = Vector2.ONE

	## Nền + giới hạn camera CỐ ĐỊNH, không phụ thuộc stage/đợt - set 1 lần ở
	## đây (LUÔN chạy trước start_battle() đầu tiên) để battle_camera.position
	## gán lần đầu trong start_battle() đã bị giới hạn đúng ngay từ đầu. Đọc
	## get_viewport_rect() THẬT thay vì hard-code 1 độ phân giải cố định.
	var viewport_half_width: float = get_viewport_rect().size.x / 2.0
	_camera_limit_left = PLAYER_TEAM_CENTER.x - viewport_half_width - CAMERA_VIEW_MARGIN
	_camera_limit_right = BOSS_ANCHOR_X + viewport_half_width + CAMERA_VIEW_MARGIN
	battle_arena_background.offset_left = _camera_limit_left
	battle_arena_background.offset_right = _camera_limit_right
	battle_camera.limit_left = roundi(_camera_limit_left)
	battle_camera.limit_right = roundi(_camera_limit_right)
	## KHÔNG set limit_top/limit_bottom: camera.position.y luôn = 0 (không nơi
	## nào trong file này đổi .y). SubViewport ở đây cao 1280 (nửa=640) >
	## world cao 900 (nửa=450, offset_top/bottom không đổi) - nếu chặn
	## limit_top/bottom theo đúng 900 đó, Godot sẽ ép camera center Y lệch
	## khỏi 0 (khoảng hợp lệ [190,-190] rỗng/đảo ngược), làm lệch khung hình.
	## Để mặc định (không giới hạn dọc) là AN TOÀN vì Y không bao giờ bị đổi.

func start_battle(stage: StageData) -> void:
	_stage = stage
	_clear_units()
	_spawn_team(GameState.PARTY_TROOP_IDS, Enums.Team.PLAYER, PLAYER_TEAM_CENTER, 1.0)
	## Camera bắt đầu tại PLAYER_TEAM_CENTER (chỗ phe mình vừa spawn) - tránh
	## giật/lerp thừa từ vị trí Godot mặc định (0,0) lúc mới vào trận.
	battle_camera.position = Vector2(PLAYER_TEAM_CENTER.x, 0.0)
	## _clear_units() vừa queue_free() party cũ (nếu có trận trước) -
	## _camera_follow_unit đang trỏ tới instance CŨ đó, phải reset để buộc
	## đánh giá lại ngay trên party MỚI vừa spawn.
	_camera_follow_unit = null
	_camera_follow_switch_cooldown = 0.0

	_wave_count = maxi(stage.boss_trash_wave_count, 0) + 1 ## đợt cuối luôn là boss thật
	_current_wave_index = -1
	_spawn_next_wave()

	_time_left = stage.time_limit
	_active = true
	result_panel.visible = false
	surrender_button.visible = true
	timer_label.visible = true
	visible = true

## facing = +1.0 (phe mình, mũi nhọn hướng +X = về phía địch bên phải) hoặc
## -1.0 (phe địch, mirror ngược lại để mũi nhọn hướng về phía người chơi).
## monster_level > 1 chỉ có ý nghĩa với quái (xem TroopUnit._monster_stat_multiplier) -
## boss thật giữ default 1 = dùng đúng số liệu tay trong LinhData, không bị cấp quái ăn vào.
func _spawn_team(troop_ids: Array[int], team: Enums.Team, team_center: Vector2, facing: float, monster_level: int = 1) -> void:
	for i in range(troop_ids.size()):
		var troop := TroopDatabase.get_by_id(troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, team, monster_level)
		var offset := FORMATION_OFFSETS[i % FORMATION_OFFSETS.size()]
		offset.x *= facing
		unit.position = team_center + offset * FORMATION_WORLD_SPACING
		if team == Enums.Team.PLAYER:
			_player_units.append(unit)
		else:
			_enemy_units.append(unit)

## Dọn đợt quái cũ (nếu có) rồi spawn đợt KẾ TIẾP - đợt thường xoay vòng qua
## TRASH_WAVE_SLOTS vị trí X cố định (world không tăng vô hạn - xem ghi chú
## TRASH_WAVE_SLOTS), đợt CUỐI CÙNG (boss thật) luôn đứng ở BOSS_ANCHOR_X.
func _spawn_next_wave() -> void:
	for unit in _enemy_units:
		unit.queue_free()
	_enemy_units.clear()

	_current_wave_index += 1
	if _current_wave_index < _wave_count - 1:
		var slot: int = _current_wave_index % TRASH_WAVE_SLOTS
		if slot == 0 and _current_wave_index > 0:
			## Dịch cả party lẫn camera lùi lại - tính theo vị trí camera THẬT
			## lúc này (không dùng số lý thuyết TRASH_WAVE_SLOTS*WAVE_SPACING_X
			## cố định - camera giờ bám theo 1 NHÂN VẬT CỤ THỂ, nếu là
			## Priest/Archer đứng lùi xa thì số cố định dư ra, đẩy camera vọt
			## ra ngoài _camera_limit_left, xem StageFarmWorld cho chi tiết bug).
			_recenter_world(battle_camera.position.x - (PLAYER_TEAM_CENTER.x + CAMERA_LOOKAHEAD_X))
		_wave_anchor_x = PLAYER_TEAM_CENTER.x + FIRST_WAVE_OFFSET_X + slot * WAVE_SPACING_X
		_spawn_trash_wave()
	else:
		_wave_anchor_x = BOSS_ANCHOR_X
		_spawn_boss_wave()

## Dịch cả party lẫn camera lùi lại đúng `shift` - gọi ĐÚNG LÚC không còn quái
## nào sống trên màn (giữa 2 đợt, WAVE_CLEAR_DELAY), khi party đang idle không
## di chuyển, nên hoàn toàn không thấy "giật/nhảy". Giữ cảm giác "luôn tiến về
## phía trước" dù toạ độ world không bao giờ vượt CAMERA_LIMIT_LEFT/RIGHT.
func _recenter_world(shift: float) -> void:
	for unit in _player_units:
		unit.position.x -= shift
	battle_camera.position.x -= shift

func _spawn_trash_wave() -> void:
	var encounter: Dictionary = EncounterGenerator.generate_encounter(EncounterGenerator.BASE_MONSTERS_PER_WAVE, _stage.boss_trash_monster_level)
	_spawn_team(encounter["monster_ids"], Enums.Team.ENEMY, Vector2(_wave_anchor_x, 0.0), -1.0, encounter["monster_level"])

func _spawn_boss_wave() -> void:
	var enemy_ids: Array[int] = []
	for i in range(_stage.enemy_troop_ids.size()):
		for _n in range(_stage.enemy_troop_counts[i]):
			enemy_ids.append(_stage.enemy_troop_ids[i])
	_spawn_team(enemy_ids, Enums.Team.ENEMY, Vector2(_wave_anchor_x, 0.0), -1.0)

func _clear_units() -> void:
	for child in arena.get_children():
		child.queue_free()
	_player_units.clear()
	_enemy_units.clear()

func _process(delta: float) -> void:
	if not _active:
		return
	_update_camera_follow(delta)
	## Nghỉ ngắn giữa 2 đợt (KHÔNG kết thúc trận) - vẫn chạy _run_ai/_resolve_collisions
	## bình thường (đợt cũ đã hết mục tiêu -> tự chuyển idle qua nhánh
	## "target == null" có sẵn trong _update_unit(), KHÔNG đứng hình animation
	## tấn công cuối như bug đã gặp/sửa ở StageFarmWorld) - chỉ tạm hoãn
	## _check_battle_end() để không set lại _wave_transition_timer chồng lên chính nó.
	if _wave_transition_timer >= 0.0:
		_wave_transition_timer -= delta
		_run_ai(delta)
		_resolve_collisions()
		if _wave_transition_timer <= 0.0:
			_wave_transition_timer = -1.0
			_spawn_next_wave()
		return
	_time_left = maxf(_time_left - delta, 0.0)
	timer_label.text = "%d:%02d" % [int(_time_left) / 60, int(_time_left) % 60]
	_run_ai(delta)
	_resolve_collisions()
	_check_battle_end()

## Đẩy nhẹ 2 lính ra xa nhau nếu khoảng cách giữa 2 tâm < 2*COLLISION_RADIUS.
## Lính đang is_engaged (đứng yên trong tầm đánh) không bị đẩy trừ khi CẢ 2
## đều đang engaged - lính đang di chuyển băng qua sẽ tự nhường, không kéo
## lính đang đánh dở ra khỏi tầm.
func _resolve_collisions() -> void:
	var all_units: Array[TroopUnit] = _player_units + _enemy_units
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

func _run_ai(delta: float) -> void:
	_update_side(_player_units, _enemy_units, delta)
	_update_side(_enemy_units, _player_units, delta)

## Không còn squad cố định - mỗi unit tự tìm địch gần nhất, nhưng các unit
## đang nhắm CHUNG 1 mục tiêu (rất thường xảy ra vì party chỉ 4 người) được
## gom lại và chia đều góc vây quanh mục tiêu đó (Attack Slot), tính lại MỖI
## FRAME thay vì theo squad cố định như bản cũ - tránh đứng đè khít lên nhau.
func _update_side(units: Array[TroopUnit], enemies: Array[TroopUnit], delta: float) -> void:
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
		_update_unit(unit, target_of.get(unit), slot_of.get(unit, 0.0), units, delta)

## Local Avoidance: lực đẩy tổng hợp từ mọi đồng đội (CÙNG PHE) đang đứng
## trong bán kính AVOIDANCE_RADIUS quanh unit - càng gần đẩy càng mạnh. Cộng
## vào hướng Seek (hướng tới slot) để lính tự lệch đường vòng qua chỗ đông.
const AVOIDANCE_RADIUS: float = COLLISION_RADIUS * 4.0
const AVOIDANCE_WEIGHT: float = 0.8 ## <1 = Seek luôn có ảnh hưởng nhiều hơn

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

## Khoảng nghỉ TRƯỚC/SAU lúc skill thật sự ra hiệu ứng = 50% attack_interval().
func _skill_pause(unit: TroopUnit) -> float:
	return unit.attack_interval() * 0.5

const ATTACK_READY_HOLD: float = 0.15 ## Đòn thường giữ 1 nhịp "sẵn sàng" ngắn trước khi ra đòn, để thanh đánh thường kịp hiện màu sẵn sàng
const REGEN_INTERVAL: float = 5.0 ## Lính hồi máu mỗi 5 giây theo regen_hp

func _update_unit(unit: TroopUnit, target: TroopUnit, slot_angle: float, allies: Array[TroopUnit], delta: float) -> void:
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
	if DEBUG_FREEZE_UNITS:
		unit.is_engaged = false
		unit.play_idle()
		return ## chỉ quay mặt về mục tiêu, không di chuyển/tấn công

	var distance := unit.position.distance_to(target.position)
	if distance > unit.attack_range_px():
		unit.is_engaged = false
		unit.play_walk()
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
				_priest_cast(unit, target)
			else:
				unit.play_attack()
				_resolve_attack(unit, target, true)
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
			_resolve_attack(unit, target, false)
		return

	if unit.attack_cooldown <= 0.0:
		unit.attack_windup_timer = ATTACK_READY_HOLD

func _priest_cast(unit: TroopUnit, target: TroopUnit) -> void:
	unit.skill_toggle = not unit.skill_toggle
	if unit.skill_toggle:
		var ally := _find_heal_target(unit)
		if ally != null:
			unit.play_heal()
			_apply_heal(unit, ally)
			return
	unit.play_attack()
	_resolve_attack(unit, target, false)

func _find_heal_target(unit: TroopUnit) -> TroopUnit:
	var allies: Array[TroopUnit] = _player_units if unit.team == Enums.Team.PLAYER else _enemy_units
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

## Sát thương = ATK HIỆU DỤNG nhân Crit Damage nếu chí mạng, nhân thêm
## SKILL_DAMAGE_MULT nếu là đòn "Đánh mạnh", trừ giáp hiệu quả của đối
## phương (DEF nếu đòn vật lý, M.DEF nếu đòn phép), giáp hiệu quả giảm theo
## Armor Penetration. Tối thiểu 1 sát thương.
func _resolve_attack(attacker: TroopUnit, defender: TroopUnit, is_skill: bool = false) -> void:
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
			_spawn_arrow(attacker, defender, final_damage, is_skill)
		"wizard":
			_spawn_magic_bolt(attacker, defender, final_damage, is_skill)
		"priest":
			_apply_damage(attacker, defender, final_damage, is_skill)
			_spawn_impact_effect(defender.position, PRIEST_ATTACK_EFFECT_FRAMES)
		_:
			_apply_damage(attacker, defender, final_damage, is_skill)

func _apply_damage(attacker: TroopUnit, defender: TroopUnit, final_damage: float, is_skill: bool) -> void:
	if defender.is_dead():
		return
	defender.take_damage(final_damage)
	_spawn_damage_popup(defender, final_damage, is_skill)
	if attacker.troop_data.life_steal > 0.0:
		attacker.heal(final_damage * attacker.troop_data.life_steal)
	if defender.is_dead() and defender.team == Enums.Team.ENEMY:
		## Hạ quái trong trận đánh tay (Ủy Thác/Boss) - CẢ ĐỘI (luôn đủ 4
		## người, xem GameState.PARTY_TROOP_IDS) nhận EXP của con đó, cùng quy
		## ước "giết quái thì cả team nhận EXP" như treo máy (xem
		## StageFarmWorld._apply_damage).
		GameState.grant_kill_exp(GameState.PARTY_TROOP_IDS, defender.troop_data.exp_reward)
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
	_spawn_loot_popup(defender, "+1 %s" % mat.display_name, COLOR_MATERIAL)

func _spawn_loot_popup(unit: TroopUnit, text: String, color: Color) -> void:
	var popup: DamagePopup = DAMAGE_POPUP_SCENE.instantiate()
	arena.add_child(popup)
	popup.setup(text, color, unit.position + POPUP_SPAWN_OFFSET + Vector2(0, -16))

func _spawn_arrow(attacker: TroopUnit, defender: TroopUnit, final_damage: float, is_skill: bool) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	arena.add_child(projectile)
	var visual_scale: float = ARROW_SKILL_SCALE if is_skill else 1.0
	projectile.setup_static(attacker.position, defender.position, ARROW_TEXTURE, func(): _apply_damage(attacker, defender, final_damage, is_skill), visual_scale)

func _spawn_magic_bolt(attacker: TroopUnit, defender: TroopUnit, final_damage: float, is_skill: bool) -> void:
	var projectile: Projectile = PROJECTILE_SCENE.instantiate()
	arena.add_child(projectile)
	var frames: SpriteFrames = MAGIC_SKILL_PROJECTILE_FRAMES if is_skill else MAGIC_PROJECTILE_FRAMES
	projectile.setup_animated(attacker.position, defender.position, frames, "cast", func(): _apply_damage(attacker, defender, final_damage, is_skill))

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

## Quái ĐỢT HIỆN TẠI chết sạch: còn đợt kế (trash hoặc boss) -> chuyển đợt
## (WAVE_CLEAR_DELAY, KHÔNG kết thúc trận); là đợt CUỐI CÙNG (boss thật) ->
## THẮNG CẢ TRẬN. Party chết sạch/hết giờ -> THUA như cũ (không phân biệt đợt).
func _check_battle_end() -> void:
	var enemy_alive := _enemy_units.any(func(u): return not u.is_dead())
	var player_alive := _player_units.any(func(u): return not u.is_dead())
	if not player_alive:
		_end_battle(false)
	elif _time_left <= 0.0:
		_end_battle(false)
	elif not enemy_alive:
		if _current_wave_index < _wave_count - 1:
			_wave_transition_timer = WAVE_CLEAR_DELAY
		else:
			_end_battle(true)

## Camera bám LIÊN TỤC theo 1 nhân vật cụ thể (xem _pick_camera_follow_unit())
## - hết phe mình (cả đội chết) thì fallback về PLAYER_TEAM_CENTER.x.
##
## CHỈ đánh giá lại "nên bám ai" mỗi CAMERA_FOLLOW_SWITCH_HOLD giây (hoặc ngay
## khi unit đang bám vừa chết) - không tính lại mỗi frame, tránh camera đổi
## hướng liên tục nếu is_engaged nhấp nháy lúc combat, giống hệt StageFarmWorld.
func _update_camera_follow(delta: float) -> void:
	if _camera_follow_unit != null and _camera_follow_unit.is_dead():
		_camera_follow_unit = null ## buộc đánh giá lại ngay, không đợi hết cooldown
	_camera_follow_switch_cooldown -= delta
	if _camera_follow_unit == null or _camera_follow_switch_cooldown <= 0.0:
		_camera_follow_unit = _pick_camera_follow_unit()
		_camera_follow_switch_cooldown = CAMERA_FOLLOW_SWITCH_HOLD

	_camera_target_x = (_camera_follow_unit.position.x + CAMERA_LOOKAHEAD_X) if _camera_follow_unit != null else PLAYER_TEAM_CENTER.x
	battle_camera.position.x = lerpf(battle_camera.position.x, _camera_target_x, clampf(delta * CAMERA_FOLLOW_LERP_SPEED, 0.0, 1.0))

const NEAR_CHARACTER_KEY: String = "soldier" ## melee, tank đứng đầu tuyến
const MID_CHARACTER_KEY: String = "priest" ## hỗ trợ, thường đứng giữa đội hình
const FAR_CHARACTER_KEYS: Array[String] = ["archer", "wizard"] ## tầm xa, đứng hậu phương

## Chọn 1 nhân vật CỤ THỂ để camera bám theo (không lấy trung bình cả đội) -
## thứ tự ưu tiên ĐỔI tuỳ đã giao chiến hay chưa, giống hệt StageFarmWorld:
## - CHƯA giao chiến: ưu tiên MID (Priest) -> GẦN (Soldier) -> XA (Archer/Wizard).
## - ĐÃ giao chiến (có unit is_engaged): ưu tiên GẦN (Soldier) -> MID (Priest) -> XA.
## Trả null nếu cả phe mình đã chết.
func _pick_camera_follow_unit() -> TroopUnit:
	var any_engaged := _player_units.any(func(u: TroopUnit) -> bool: return not u.is_dead() and u.is_engaged)
	var priority_keys := [NEAR_CHARACTER_KEY, MID_CHARACTER_KEY] if any_engaged else [MID_CHARACTER_KEY, NEAR_CHARACTER_KEY]
	for character_key in priority_keys:
		var unit := _find_alive_player_by_character_key(character_key)
		if unit != null:
			return unit
	for character_key in FAR_CHARACTER_KEYS:
		var unit := _find_alive_player_by_character_key(character_key)
		if unit != null:
			return unit
	return null

func _find_alive_player_by_character_key(character_key: String) -> TroopUnit:
	for unit in _player_units:
		if not unit.is_dead() and unit.troop_data.character_key == character_key:
			return unit
	return null

## Người chơi chủ động bấm "Chịu thua" - luôn tính là thua ngay lập tức.
func _on_surrender_pressed() -> void:
	if not _active:
		return
	_end_battle(false)

func _end_battle(won: bool) -> void:
	_active = false
	surrender_button.visible = false
	result_title.text = "Thắng!" if won else "Thua!"
	result_reward.text = "+%d vàng" % _stage.reward_gold if won else "Không có phần thưởng"
	result_panel.visible = true
	_last_result_won = won
	if won:
		GameState.add_gold(_stage.reward_gold)

func _on_result_closed() -> void:
	visible = false
	_clear_units()
	closed.emit(_last_result_won)
