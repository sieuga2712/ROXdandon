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
##
## Camera BÁM LIÊN TỤC theo 1 NHÂN VẬT CỤ THỂ trong party (không phải trung
## bình cả đội, không khoá cứng theo area/wave) - chọn nhân vật theo tầm đánh,
## thứ tự ưu tiên ĐỔI tuỳ đã giao chiến hay chưa (xem _pick_camera_follow_unit()):
## - CHƯA giao chiến (đang đi tới quái): ưu tiên MID (Priest) -> GẦN (Soldier)
##   -> XA (Archer/Wizard).
## - ĐÃ giao chiến (có unit is_engaged): ưu tiên GẦN (Soldier, tank đứng đầu)
##   -> MID (Priest) -> XA (Archer/Wizard).
## Lựa chọn này CHỈ đánh giá lại mỗi CAMERA_FOLLOW_SWITCH_HOLD giây (không
## phải mỗi frame) - tránh camera đổi hướng liên tục nếu is_engaged nhấp nháy
## lúc combat. Target còn lệch sang phải CAMERA_LOOKAHEAD_X so với nhân vật
## đang bám (nhân vật hiện ở bên trái tâm màn hình), để nhân vật hiện rõ hơn
## (không dính đúng tâm) và hé thêm không gian phía quái sắp tới. Hết phe
## mình (cả đội chết, đang chờ hồi sinh) ->
## fallback về PARTY_CENTER.x (xem _update_camera_follow()) - tự nhiên lerp về
## nhà, không cần code riêng cho lúc thua. Giới hạn camera THEO MAP
## (_camera_limit_left/right, tính từ
## viewport thật lúc _ready(), không hard-code độ phân giải) đảm bảo không bao
## giờ lộ ra ngoài world.
##
## Hết đợt hiện tại (còn đợt kế trong tầng) -> nghỉ WAVE_CLEAR_DELAY rồi spawn
## đợt kế (_spawn_next_wave). Hết ĐỢT CUỐI CÙNG (party còn sống) = THẮNG CẢ
## TẦNG -> báo GameState.report_floor_cleared rồi tự nạp StageData tầng kế
## tiếp (không còn bị kẹp ở tầng cuối cùng đã author tay - xem
## GameState.resolve_stage_for_floor). THUA (party chết sạch, ở BẤT KỲ đợt
## nào) -> đánh lại từ ĐỢT 1 của đúng tầng đang treo, không tiếp tục từ đợt
## đang thua (xem _revive_all). Cả thắng/thua cả tầng đều chờ RESTART_DELAY
## giây trước khi thật sự đổi - giống kiểu AFK Arena/game farm-tầng-tự-động.
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
const CAMERA_FOLLOW_LERP_SPEED: float = 4.0 ## hệ số lerp/giây - camera lerp mượt tới _camera_target_x, KHÔNG tính lại target mỗi frame

## --- Giới hạn bản đồ (2026-08) ---
## Trước đây _wave_anchor_x cộng dồn WAVE_SPACING_X mãi mãi theo floor_number
## (có thể tới 29 đợt ở floor 100) -> world "dài vô hạn" phải giả bằng cách
## cho ground_background bám theo camera mỗi frame (đã xoá, xem
## _update_camera_follow). Từ giờ: WAVE_SLOT_COUNT vị trí X CỐ ĐỊNH mà đợt
## quái xoay vòng qua - hết 1 vòng, _recenter_world() dịch lại party + camera
## lùi về đúng lúc không có quái trên màn (WAVE_CLEAR_DELAY), giữ nguyên cảm
## giác "luôn tiến về phía trước" nhưng world không bao giờ vượt
## _camera_limit_left/right nữa - ground_background giờ TĨNH, không cần bám
## theo camera mỗi frame nữa.
const WAVE_SLOT_COUNT: int = 3

const CAMERA_VIEW_MARGIN: float = 40.0 ## đệm dôi thêm, tránh clamp chạm biên đúng lúc đang cần thấy trọn cảnh

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

const CAMERA_FOLLOW_SWITCH_HOLD: float = 0.6 ## giữ nguyên nhân vật đang bám tối thiểu chừng này giây trước khi cho đổi lại - tránh camera "lật" liên tục nếu is_engaged nhấp nháy (unit ra/vào tầm đánh nhanh), xem _update_camera_follow()
const CAMERA_LOOKAHEAD_X: float = 60.0 ## camera lệch sang PHẢI 1 khoảng nhỏ so với nhân vật đang bám - nhân vật hiện rõ hơn ở bên trái tâm màn hình thay vì đúng giữa, hé thêm không gian bên phải (hướng quái tới)

var _camera_follow_unit: TroopUnit = null ## unit ĐANG được camera bám - chỉ đánh giá lại lựa chọn khi hết CAMERA_FOLLOW_SWITCH_HOLD hoặc unit này vừa chết, xem _update_camera_follow()
var _camera_follow_switch_cooldown: float = 0.0
var _camera_return_home: bool = false ## true = ép camera lerp về PARTY_CENTER.x bất kể đang bám ai - bật lúc THẮNG CẢ TẦNG/THUA (chờ RESTART_DELAY), để tới lúc configure() tầng mới/_revive_all() chạy thì camera đã sẵn ở nhà, không còn gì để "nhảy" - xem _check_wipe()
var _camera_target_x: float = 0.0 ## = _camera_follow_unit.position.x + CAMERA_LOOKAHEAD_X (hoặc PARTY_CENTER.x nếu hết phe mình/_camera_return_home) - lưu ở đây chỉ để tiện đọc/debug, camera.position lerp mượt tới giá trị này chứ không gán thẳng
var _camera_limit_left: float = 0.0 ## tính theo viewport THẬT lúc _ready() (không hard-code độ phân giải) - xem _ready()
var _camera_limit_right: float = 0.0

func _ready() -> void:
	## Nền + giới hạn camera CỐ ĐỊNH bất kể floor_number/wave_count - set 1 lần
	## ở đây (LUÔN chạy trước configure() đầu tiên - Godot gọi _ready() ngay
	## khi add_child(), trước khi add_child() trả về) để camera.position gán
	## lần đầu trong configure() đã bị giới hạn đúng ngay từ đầu. Đọc
	## get_viewport_rect() THẬT thay vì hard-code 1 độ phân giải cố định - vẫn
	## đúng nếu SubViewport (xem StageFarmMap.tscn) đổi kích thước sau này.
	var viewport_half_width: float = get_viewport_rect().size.x / 2.0
	_camera_limit_left = PARTY_CENTER.x - viewport_half_width - CAMERA_VIEW_MARGIN
	_camera_limit_right = PARTY_CENTER.x + FIRST_WAVE_OFFSET_X + (WAVE_SLOT_COUNT - 1) * WAVE_SPACING_X + viewport_half_width + CAMERA_VIEW_MARGIN
	ground_background.position.x = _camera_limit_left
	ground_background.size.x = _camera_limit_right - _camera_limit_left
	camera.limit_left = roundi(_camera_limit_left)
	camera.limit_right = roundi(_camera_limit_right)
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
	## Camera bắt đầu tại PARTY_CENTER (chỗ phe mình sắp spawn) - tránh
	## giật/lerp thừa từ vị trí Godot mặc định (0,0) lúc mới vào tầng.
	## _update_camera_follow() ngay frame kế sẽ tự tính lại target đúng theo
	## nhân vật được chọn (party vừa spawn tại đây nên giá trị khớp nhau).
	camera.position = Vector2(PARTY_CENTER.x, 0.0)
	camera.zoom = Vector2.ONE
	## party_units cũ vừa bị queue_free() ở trên (nếu có) - _camera_follow_unit
	## đang trỏ tới instance CŨ đó, phải reset để buộc đánh giá lại ngay trên
	## party MỚI vừa spawn, không đợi hết CAMERA_FOLLOW_SWITCH_HOLD. Tắt luôn
	## _camera_return_home (nếu bật từ lúc thắng cả tầng) - đợt/tầng mới đã bắt
	## đầu thật, quay lại bám nhân vật bình thường.
	_camera_follow_unit = null
	_camera_follow_switch_cooldown = 0.0
	_camera_return_home = false
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
		## Dịch cả party lẫn camera lùi lại - tính theo vị trí camera THẬT lúc
		## này (không dùng số lý thuyết WAVE_SLOT_COUNT*WAVE_SPACING_X cố định
		## nữa - camera giờ bám theo 1 NHÂN VẬT CỤ THỂ, nếu đó là Priest/Archer
		## (tầm xa, đứng lùi khá xa so với vị trí quái) thì số cố định đó dư ra
		## 1 khoảng, đẩy camera vọt ra NGOÀI HẲN _camera_limit_left - đây chính
		## là bug "camera nhảy thẳng" báo cáo 2026-08). Dịch sao cho camera hạ
		## cánh ĐÚNG vị trí PARTY_CENTER.x + CAMERA_LOOKAHEAD_X sau khi gộp -
		## luôn nằm trong giới hạn map, bất kể đang bám nhân vật nào.
		_recenter_world(camera.position.x - (PARTY_CENTER.x + CAMERA_LOOKAHEAD_X))
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

## Camera bám LIÊN TỤC theo 1 nhân vật cụ thể (xem _pick_camera_follow_unit())
## - hết phe mình (cả đội chết, đang chờ RESTART_DELAY hồi sinh) thì fallback
## về PARTY_CENTER.x, tự nhiên lerp về nhà, không cần code riêng cho lúc thua.
##
## CHỈ đánh giá lại "nên bám ai" mỗi CAMERA_FOLLOW_SWITCH_HOLD giây (hoặc ngay
## khi unit đang bám vừa chết) - không tính lại mỗi frame, vì is_engaged của
## 1 unit có thể nhấp nháy liên tục lúc combat (ra/vào tầm đánh), nếu đổi
## target ngay lập tức mỗi lần nhấp nháy thì camera cứ đổi hướng giữa chừng
## liên tục, nhìn như "do dự" dù từng bước lerp vẫn mượt riêng lẻ.
func _update_camera_follow(delta: float) -> void:
	if _camera_return_home:
		## Đang chờ RESTART_DELAY (thắng cả tầng/thua) - ép về nhà, KHÔNG bám
		## unit nào cả (party vẫn đứng nguyên chỗ vừa đánh xong, có thể rất xa
		## PARTY_CENTER - lerp về từ từ suốt lúc chờ, xem _check_wipe()).
		_camera_target_x = PARTY_CENTER.x
		camera.position.x = lerpf(camera.position.x, _camera_target_x, clampf(delta * CAMERA_FOLLOW_LERP_SPEED, 0.0, 1.0))
		return

	if _camera_follow_unit != null and _camera_follow_unit.is_dead():
		_camera_follow_unit = null ## buộc đánh giá lại ngay, không đợi hết cooldown
	_camera_follow_switch_cooldown -= delta
	if _camera_follow_unit == null or _camera_follow_switch_cooldown <= 0.0:
		_camera_follow_unit = _pick_camera_follow_unit()
		_camera_follow_switch_cooldown = CAMERA_FOLLOW_SWITCH_HOLD

	_camera_target_x = (_camera_follow_unit.position.x + CAMERA_LOOKAHEAD_X) if _camera_follow_unit != null else PARTY_CENTER.x
	camera.position.x = lerpf(camera.position.x, _camera_target_x, clampf(delta * CAMERA_FOLLOW_LERP_SPEED, 0.0, 1.0))

const NEAR_CHARACTER_KEY: String = "soldier" ## melee, tank đứng đầu tuyến
const MID_CHARACTER_KEY: String = "priest" ## hỗ trợ, thường đứng giữa đội hình
const FAR_CHARACTER_KEYS: Array[String] = ["archer", "wizard"] ## tầm xa, đứng hậu phương

## Chọn 1 nhân vật CỤ THỂ để camera bám theo (không lấy trung bình cả đội) -
## thứ tự ưu tiên ĐỔI tuỳ đã giao chiến hay chưa:
## - CHƯA giao chiến (không unit nào is_engaged, còn đang đi tới quái): ưu tiên
##   MID (Priest, thường đứng giữa) -> GẦN (Soldier, tank dẫn đầu) -> XA
##   (Archer/Wizard).
## - ĐÃ giao chiến (có unit is_engaged = đang trong tầm đánh): ưu tiên GẦN
##   (Soldier, người tiếp cận quái đầu tiên) -> MID (Priest) -> XA.
## Trả null nếu cả phe mình đã chết (xem _update_camera_follow() fallback).
func _pick_camera_follow_unit() -> TroopUnit:
	var any_engaged := party_units.any(func(u: TroopUnit) -> bool: return not u.is_dead() and u.is_engaged)
	var priority_keys := [NEAR_CHARACTER_KEY, MID_CHARACTER_KEY] if any_engaged else [MID_CHARACTER_KEY, NEAR_CHARACTER_KEY]
	for character_key in priority_keys:
		var unit := _find_alive_party_by_character_key(character_key)
		if unit != null:
			return unit
	for character_key in FAR_CHARACTER_KEYS:
		var unit := _find_alive_party_by_character_key(character_key)
		if unit != null:
			return unit
	return null

func _find_alive_party_by_character_key(character_key: String) -> TroopUnit:
	for unit in party_units:
		if not unit.is_dead() and unit.troop_data.character_key == character_key:
			return unit
	return null

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
		_camera_return_home = true ## lerp về PARTY_CENTER suốt lúc chờ hồi sinh, xem _update_camera_follow()
		return
	if _current_wave_index < _wave_count - 1:
		_wave_transition_timer = WAVE_CLEAR_DELAY
	else:
		_pending_win = true
		_restart_timer = RESTART_DELAY
		## THẮNG CẢ TẦNG - party đang đứng nguyên chỗ vừa đánh xong đợt cuối
		## (có thể rất xa PARTY_CENTER qua nhiều đợt). Ép camera lerp về nhà
		## NGAY (suốt RESTART_DELAY, không đợi configure() tầng mới snap tức
		## thì) - tới lúc tầng mới thật sự bắt đầu, camera đã sẵn ở đó, không
		## còn "nhảy" đúng lúc đợt quái đầu tầng mới xuất hiện nữa.
		_camera_return_home = true

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
	_camera_return_home = false ## đợt 1 bắt đầu lại thật - quay lại bám nhân vật bình thường
	_spawn_next_wave()
