class_name StageFarmWorld
extends Node2D

## "Bãi farm" treo máy THẬT - KHÔNG điều khiển được (không leader/không
## click-di-chuyển), party (đúng thành viên đang treo team đó) tự đánh nhau vô
## hạn với quái của đúng StageData đang treo. Đây CHÍNH LÀ trận đấu tạo ra
## phần thưởng thật - KHÔNG có công thức DPS/thời gian nào cả, quái chết thật
## thì cộng vàng (LinhData.gold_reward) + EXP (LinhData.exp_reward) NGAY LÚC
## ĐÓ cho member_troop_ids (xem CombatResolver._apply_damage). Instance này
## được GameState giữ sống suốt thời gian treo máy (xem
## GameState.start_idle_team) - "Xem treo máy" chỉ là NHÚNG (reparent)
## instance đang chạy này vào UI để nhìn, không tạo bản sao/không tính riêng
## gì cả.
##
## configure() được gọi ngay sau khi instance (xem GameState.start_idle_team_on_map) -
## lúc đó @onready đã sẵn sàng (Godot gọi _ready() ngay khi add_child() vào 1
## tree đang chạy, trước khi add_child() trả về). configure() có thể gọi LẠI
## nhiều lần trên cùng 1 instance (tự dọn quân cũ trước khi spawn quân mới) -
## dùng để LÊN TẦNG khi thắng, xem _advance_floor().
##
## Mô hình bản đồ "treadmill" (2026-08): CAMERA CỐ ĐỊNH VĨNH VIỄN tại (0,0)
## (xem _ready()). Khung hình camera (rộng 2*viewport_half_width) chia làm 4
## PHẦN BẰNG NHAU theo chiều ngang (Cam-1..Cam-4, trái->phải); khu vực quái
## spawn (NGOÀI khung hình, bên phải Cam-4) chia làm 2 phần (Spawn-1 gần
## camera, Spawn-2 xa/nơi quái spawn thật) - quái MỌI đợt (kể cả đợt đầu mỗi
## tầng, kể cả floor cao có tới hàng chục đợt) đều spawn ở ĐÚNG 1 vị trí CỐ
## ĐỊNH rồi tự đi vào. Mỗi đợt (trong 1 tầng), phe mình dàn quân theo 4 GIAI
## ĐOẠN (WaveStagingState, xem _update_wave_staging()):
## 1. CENTER_WAIT - đứng ở ranh giới Cam-2/Cam-3 (chính giữa khung hình), xếp
##    đội hình "2-3-2 hình lục giác" (FORMATION_OFFSETS), giả vờ đi bộ
##    (animation walk, KHÔNG đổi vị trí thật) trong lúc quái còn ở Spawn-2.
## 2. RETREATING - quái lọt vào Spawn-1 (ranh giới Spawn-1/Spawn-2) -> phe
##    mình LÙI THẬT (đổi vị trí) về GIỮA Cam-1.
## 3. ENGAGED - quái đi tới GIỮA Cam-4 -> phá đội hình, bỏ mọi ràng buộc, cả 2
##    bên tự do lao vào nhau như AI bình thường (CombatResolver lo hết).
## 4. REFORMING - quái đợt vừa rồi chết sạch (còn đợt kế trong tầng) -> phe
##    mình giả vờ tiến thêm về bên phải 1 nhịp ngắn, RỒI mới thật sự đi (lerp)
##    về lại ĐÚNG 7 chỗ đội hình 2-3-2 tại CENTER_WAIT - xong mới spawn đợt kế.
## Không còn world dài ra vô hạn cần bám/giới hạn/recenter camera phức tạp.
##
## Toàn bộ hành vi CHIẾN ĐẤU của 1 đơn vị (targeting, né nhau, đòn đánh
## thường, skill "Đánh mạnh", đạn bay, rớt đồ, thưởng EXP/vàng) nằm ở
## `core/combat/CombatResolver.gd` - DÙNG CHUNG với BattleScene (Ải Boss), vì
## đây là đặc trưng của NHÂN VẬT chứ không phải của map. File này chỉ còn lo
## phần MAP: camera/vị trí spawn/giai đoạn dàn quân/tiến độ tầng/hồi sinh/vòng
## đời. (Trước 2026-08, StageFarmWorld tự viết 1 bản chiến đấu RÚT GỌN riêng
## không có skill/né nhau - chỉ vì lười viết chung, không phải chủ đích thiết
## kế "map treo máy không nên có skill", nên giờ gộp lại và BẬT THẬT skill/né
## nhau ở đây luôn, không còn thiếu như trước.)
##
## Hết đợt hiện tại (còn đợt kế trong tầng) -> REFORMING rồi spawn đợt kế
## (_spawn_next_wave). Hết ĐỢT CUỐI CÙNG (party còn sống) = THẮNG CẢ TẦNG ->
## báo GameState.report_floor_cleared rồi tự nạp StageData tầng kế tiếp
## (không còn bị kẹp ở tầng cuối cùng đã author tay - xem
## GameState.resolve_stage_for_floor). THUA (party chết sạch, ở BẤT KỲ đợt
## nào) -> đánh lại từ ĐỢT 1 của đúng tầng đang treo, không tiếp tục từ đợt
## đang thua (xem _revive_all). Cả thắng/thua cả tầng đều chờ RESTART_DELAY
## giây trước khi thật sự đổi - giống kiểu AFK Arena/game farm-tầng-tự-động.

const TROOP_UNIT_SCENE: PackedScene = preload("res://entities/troop/TroopUnit.tscn")

const SPREAD_RADIUS: float = 44.0 ## giống hệt BattleScene.SPREAD_RADIUS - dùng cho quái, xem _spawn_enemy_team()

const FORMATION_SPACING: float = 40.0 ## khoảng cách giữa các hàng/cột trong đội hình 2-3-2, xem FORMATION_OFFSETS
## Đội hình "2-3-2 hình lục giác": hàng SAU (2, xa quái nhất, offset.x=-1) và
## hàng TRƯỚC (2, gần quái nhất, offset.x=1) HẸP; hàng GIỮA (3, offset.x=0)
## dàn RỘNG NHẤT - nối các điểm ngoài lại đúng hình lục giác. Gán vào lính
## theo INDEX (i % 7) - CHƯA có logic "ai đứng vị trí nào" (tank đứng
## trước...), để xử lý sau. Giống hệt BattleScene.FORMATION_OFFSETS.
const FORMATION_OFFSETS: Array[Vector2] = [
	Vector2(-1.0, -0.5), Vector2(-1.0, 0.5), ## hàng SAU (2, hẹp)
	Vector2(0.0, -1.0), Vector2(0.0, 0.0), Vector2(0.0, 1.0), ## hàng GIỮA (3, rộng nhất)
	Vector2(1.0, -0.5), Vector2(1.0, 0.5), ## hàng TRƯỚC (2, hẹp)
]

const RESTART_DELAY: float = 2.0 ## hết CẢ TẦNG (đợt cuối cùng) -> chờ rồi lên tầng/hồi sinh, đánh lại vòng mới
const CORPSE_VANISH_DELAY: float = 2.0 ## xác đơn vị chết ẩn đi sau chừng này giây (dù phe kia còn đang đánh tiếp, không đợi tới lúc cả phe bị xoá sạch mới ẩn)

const CAMERA_VIEW_MARGIN: float = 40.0 ## đệm dôi thêm quanh nền, tránh lộ mép đúng lúc party/quái đứng sát biên
const WAVE_SPAWN_MARGIN: float = 500.0 ## tổng bề rộng khu Spawn (ngoài khung hình camera) - chia làm 2 phần bằng nhau (Spawn-1 gần camera, Spawn-2 xa/nơi quái spawn thật)
const REFORM_FAKE_WALK_DURATION: float = 0.4 ## đầu giai đoạn REFORMING - phe mình "giả vờ" tiến thêm về bên phải (animation, KHÔNG đổi vị trí) đúng chừng này giây trước khi thật sự đi (lerp) về đội hình
const REFORM_ARRIVE_EPSILON: float = 4.0 ## coi là "đã về tới" đúng chỗ đội hình khi còn cách chừng này (px) - tránh rung/không bao giờ khớp tuyệt đối do float

## Giai đoạn dàn quân đợt HIỆN TẠI - xem _update_wave_staging().
enum WaveStagingState { CENTER_WAIT, RETREATING, ENGAGED, REFORMING }

## true = phóng to camera ra để thấy TOÀN BỘ map (khung hình chuẩn + khu
## spawn) + vẽ các đường chia vùng để xem trực quan lúc test - KHÔNG ảnh
## hưởng logic thật (mọi mốc/toạ độ vẫn tính theo khung hình CHUẨN chưa phóng
## to, xem _setup_debug_view()).
const DEBUG_TEST_MODE: bool = false
const DEBUG_ZONE_LINE_HEIGHT: float = 900.0

@onready var arena: Node2D = $Arena
@onready var camera: Camera2D = $FarmCamera
@onready var ground_background: ColorRect = $GroundBackground

var _resolver: CombatResolver

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
var _wave_anchor_x: float = 0.0 ## tâm X đợt HIỆN TẠI - luôn = _wave_spawn_x (CỐ ĐỊNH, mọi đợt mọi tầng), xem _spawn_next_wave()
var _wave_staging_state: WaveStagingState = WaveStagingState.ENGAGED ## reset về CENTER_WAIT/REFORMING - giá trị khởi tạo không quan trọng
var _reform_timer: float = 0.0 ## đếm ngược REFORM_FAKE_WALK_DURATION lúc mới vào REFORMING - xem _update_reforming()

var _wipe: ScreenWipe ## phủ đen lúc đổi tầng (xem _advance_floor()) - nằm trong 1 CanvasLayer riêng vì StageFarmWorld là Node2D (anchors FULL_RECT của ScreenWipe chỉ đúng khi ở trong cây Control/CanvasLayer, không phải Node2D)
var _transitioning: bool = false ## true trong lúc đang chạy hiệu ứng wipe đổi tầng - _process() tạm dừng AI/kiểm tra, tránh đụng vào party/enemy_units đang bị configure() dọn dở dang

var _map_center_x: float = 0.0 ## = camera.position.x, ranh giới Cam-2/Cam-3 - đội hình ban đầu đứng đây (CENTER_WAIT)
var _retreat_x: float = 0.0 ## GIỮA Cam-1 - vị trí phe mình lùi về lúc RETREATING
var _engage_trigger_x: float = 0.0 ## GIỮA Cam-4 - quái X <= giá trị này -> ENGAGED (phá đội hình)
var _camera_right_edge_x: float = 0.0 ## mép phải Cam-4 = ranh giới Cam-4/Spawn-1
var _retreat_trigger_x: float = 0.0 ## ranh giới Spawn-1/Spawn-2 - quái X <= giá trị này (đã lọt vào Spawn-1) -> bắt đầu RETREATING
var _wave_spawn_x: float = 0.0 ## vị trí spawn CỐ ĐỊNH cho MỌI đợt/MỌI tầng (giữa Spawn-2, xa nhất) - tính 1 lần ở _ready(), camera không đổi nên không cần tính lại

func _ready() -> void:
	_resolver = CombatResolver.new(arena, true) ## true = cộng vàng + hiện popup NGAY lúc giết (nguồn thưởng treo máy duy nhất, xem ghi chú đầu file)

	## Camera CỐ ĐỊNH VĨNH VIỄN tại (0,0) - không bám theo ai, không đổi kể cả
	## qua nhiều tầng/thắng/thua/hồi sinh. Mọi vị trí dàn quân/spawn đều suy ra
	## từ đây, tính 1 lần vì camera không bao giờ đổi.
	camera.position = Vector2.ZERO
	camera.zoom = Vector2.ONE
	var viewport_half_width: float = get_viewport_rect().size.x / 2.0
	var cam_quarter: float = viewport_half_width * 0.5 ## bề rộng 1/4 khung hình (khung hình rộng 2*half, chia 4 phần bằng nhau)
	_map_center_x = camera.position.x
	_retreat_x = _map_center_x - viewport_half_width + cam_quarter * 0.5 ## giữa Cam-1
	_camera_right_edge_x = _map_center_x + viewport_half_width
	_engage_trigger_x = _camera_right_edge_x - cam_quarter * 0.5 ## giữa Cam-4
	_retreat_trigger_x = _camera_right_edge_x + WAVE_SPAWN_MARGIN * 0.5 ## ranh giới Spawn-1/Spawn-2
	_wave_spawn_x = _camera_right_edge_x + WAVE_SPAWN_MARGIN
	## Nền chỉ cần phủ đúng khung hình camera THẬT SỰ hiển thị - camera cố
	## định vĩnh viễn nên không bao giờ lộ ra ngoài khoảng [-half, +half] này,
	## kể cả quái spawn/đứng xa tít ngoài _wave_spawn_x (không bao giờ được
	## camera vẽ tới) - không cần phủ xa như bản camera động cũ.
	ground_background.position.x = -viewport_half_width - CAMERA_VIEW_MARGIN
	ground_background.size.x = (viewport_half_width + CAMERA_VIEW_MARGIN) - ground_background.position.x

	if DEBUG_TEST_MODE:
		_setup_debug_view(viewport_half_width)

	var wipe_layer := CanvasLayer.new()
	add_child(wipe_layer)
	_wipe = ScreenWipe.new()
	wipe_layer.add_child(_wipe)

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
	_spawn_player_team(member_troop_ids, Vector2(_map_center_x, 0.0))
	_wave_staging_state = WaveStagingState.CENTER_WAIT

	_wave_count = EncounterGenerator.wave_count_for_floor(stage.floor_number)
	_current_wave_index = -1
	_spawn_next_wave()

func get_stage() -> StageData:
	return _stage

func get_member_troop_ids() -> Array[int]:
	return _member_troop_ids

## Xếp phe mình vào ĐÚNG 7 chỗ đội hình "2-3-2 hình lục giác" quanh `center`
## (xem FORMATION_OFFSETS) - gán theo INDEX tạm thời, CHƯA phân biệt ai đứng
## vị trí nào. Giống hệt BattleScene._spawn_player_team().
func _spawn_player_team(member_troop_ids: Array[int], center: Vector2) -> void:
	for i in range(member_troop_ids.size()):
		var troop := TroopDatabase.get_by_id(member_troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, Enums.Team.PLAYER)
		unit.position = center + FORMATION_OFFSETS[i % FORMATION_OFFSETS.size()] * FORMATION_SPACING
		party_units.append(unit)

## Rải quái quanh `center` theo vòng tròn, bán kính tự giãn theo số lượng
## (`maxf(SPREAD_RADIUS, total * 9.0)`) - giống hệt BattleScene._spawn_enemy_team().
func _spawn_enemy_team(troop_ids: Array[int], center: Vector2, monster_level: int) -> void:
	var total := troop_ids.size()
	var radius := maxf(SPREAD_RADIUS, total * 9.0) ## co giãn theo số quái - có thể lên tới MAX_MONSTERS_PER_WAVE
	for i in range(total):
		var troop := TroopDatabase.get_by_id(troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, Enums.Team.ENEMY, monster_level)
		var offset := Vector2.RIGHT.rotated(TAU * i / maxi(total, 1)) * radius
		unit.position = center + offset
		enemy_units.append(unit)

## Dọn đợt quái cũ (nếu có) rồi spawn đợt KẾ TIẾP (_current_wave_index += 1) -
## quái luôn random theo đúng floor_number đang treo (xem
## EncounterGenerator.generate_encounter_for_floor), LUÔN spawn tại ĐÚNG
## _wave_spawn_x (không đổi giữa các đợt/các tầng - camera cố định nên không
## cần xoay vòng/tính lại gì cả). KHÔNG còn tự đưa phe mình về đội
## hình/CENTER_WAIT ở đây nữa - việc đó do configure() (đợt đầu tầng) hoặc
## _update_reforming() hoàn tất xong đội hình mới gọi hàm này (đợt sau) lo.
## Gọi từ configure(), _process() (REFORMING vừa xong), và _revive_all()
## (thua -> đánh lại từ đợt 1).
func _spawn_next_wave() -> void:
	for unit in enemy_units:
		unit.queue_free()
		_death_timers.erase(unit)
	enemy_units.clear()

	_current_wave_index += 1
	_wave_anchor_x = _wave_spawn_x

	var encounter: Dictionary = EncounterGenerator.generate_encounter_for_floor(_stage.floor_number)
	_spawn_enemy_team(encounter["monster_ids"], Vector2(_wave_anchor_x, 0.0), encounter["monster_level"])
	_rebuild_all_units()

## party_units/enemy_units không đổi thành phần trong lúc chiến đấu (chết chỉ
## đổi is_dead()) - chỉ cần gộp lại _all_units mỗi lần ĐỔI ĐỢT/TẦNG (spawn lại
## enemy_units), dùng lại mỗi frame thay vì cấp phát mảng mới ở từng vòng lặp.
func _rebuild_all_units() -> void:
	_all_units.clear()
	_all_units.append_array(party_units)
	_all_units.append_array(enemy_units)

## Cập nhật giai đoạn dàn quân đợt hiện tại. REFORMING xử lý riêng (không cần
## quái, xem _update_reforming()); ENGAGED giữ nguyên tới hết đợt. CENTER_WAIT/
## RETREATING xét theo vị trí quái GẦN NHẤT còn sống - lọt vào Spawn-1 (X <=
## _retreat_trigger_x) -> RETREATING; tới giữa Cam-4 (X <= _engage_trigger_x)
## -> ENGAGED (phá đội hình, CombatResolver lo hết).
func _update_wave_staging(delta: float) -> void:
	if _wave_staging_state == WaveStagingState.ENGAGED:
		return
	if _wave_staging_state == WaveStagingState.REFORMING:
		_update_reforming(delta)
		return

	var nearest_enemy_x: float = INF
	for u in enemy_units:
		if not u.is_dead():
			nearest_enemy_x = minf(nearest_enemy_x, u.position.x)
	if nearest_enemy_x == INF:
		return ## chưa spawn quái hoặc quái đã chết sạch - giữ nguyên trạng thái hiện tại

	if nearest_enemy_x <= _engage_trigger_x:
		_wave_staging_state = WaveStagingState.ENGAGED
		return

	if _wave_staging_state == WaveStagingState.CENTER_WAIT:
		if nearest_enemy_x <= _retreat_trigger_x:
			_wave_staging_state = WaveStagingState.RETREATING
		else:
			for unit in party_units:
				if not unit.is_dead():
					unit.play_walk() ## giả vờ đi bộ tại chỗ - KHÔNG đổi .position
		return

	## RETREATING - lùi THẬT về ĐÚNG chỗ đội hình quanh _retreat_x, giữ nguyên
	## FORMATION_OFFSETS (xem _move_units_to_formation()) - map tự set
	## .position trực tiếp vì CombatResolver chỉ biết "tiến tới mục tiêu",
	## không có khái niệm "lùi xa mục tiêu" nên không thể diễn tả qua run_ai().
	_move_units_to_formation(party_units, _retreat_x, delta)

## Quái đợt vừa rồi đã chết sạch (còn đợt kế trong tầng) - trước khi spawn đợt
## kế, phe mình: (1) giả vờ tiến thêm về bên phải REFORM_FAKE_WALK_DURATION
## giây (animation, KHÔNG đổi vị trí - đúng cảm giác "vừa thắng, còn hăng"),
## (2) SAU ĐÓ mới thật sự đi (lerp theo move_speed_px riêng từng người) về
## ĐÚNG 7 chỗ đội hình 2-3-2 tại CENTER_WAIT (_map_center_x). Khi TẤT CẢ đã về
## đúng chỗ (trong REFORM_ARRIVE_EPSILON) mới coi là xong - _process() phát
## hiện chuyển sang CENTER_WAIT thì mới spawn đợt kế (xem _spawn_next_wave()) -
## không dùng đồng hồ cố định như bản trước, đợi dàn quân THẬT SỰ xong. Giống
## hệt BattleScene._update_reforming().
func _update_reforming(delta: float) -> void:
	if _reform_timer > 0.0:
		_reform_timer -= delta
		for unit in party_units:
			if not unit.is_dead():
				unit.play_walk()
		return

	if _move_units_to_formation(party_units, _map_center_x, delta):
		_wave_staging_state = WaveStagingState.CENTER_WAIT

## Di chuyển từng đơn vị trong `units` về ĐÚNG chỗ đội hình 2-3-2 quanh tâm
## `center_x` - GIỮ NGUYÊN offset riêng từng vị trí (FORMATION_OFFSETS), không
## chỉ kéo phẳng 1 trục X chung cho mọi người (bug đã gặp 2026-08-19: làm vậy
## cả đội hình dồn về cùng 1 X, mất hẳn hình lục giác, chỉ còn dàn theo Y
## thành 1 hàng dọc). Trả về true khi TẤT CẢ đã về đúng chỗ (trong
## REFORM_ARRIVE_EPSILON) - dùng chung cho cả RETREATING (lùi về Cam-1) lẫn
## REFORMING (về lại CENTER_WAIT).
func _move_units_to_formation(units: Array[TroopUnit], center_x: float, delta: float) -> bool:
	var all_arrived := true
	for i in range(units.size()):
		var unit := units[i]
		if unit.is_dead():
			continue
		var target: Vector2 = Vector2(center_x, 0.0) + FORMATION_OFFSETS[i % FORMATION_OFFSETS.size()] * FORMATION_SPACING
		var to_target := target - unit.position
		if to_target.length() > REFORM_ARRIVE_EPSILON:
			unit.play_walk()
			unit.position += to_target.normalized() * unit.move_speed_px() * delta
			all_arrived = false
		else:
			unit.position = target
			unit.play_idle()
	return all_arrived

## CENTER_WAIT/RETREATING: map tự điều khiển phe mình (fake-walk hoặc lùi
## thật, xem _update_wave_staging()) - chặn CombatResolver tự ý di chuyển phe
## mình đè lên (trả -INF, không mục tiêu nào thoả target.x <= -INF). ENGAGED:
## bỏ hẳn ràng buộc (trả INF) - CombatResolver cho phe mình tự do lao vào quái.
func _current_free_movement_x() -> float:
	return INF if _wave_staging_state == WaveStagingState.ENGAGED else -INF

func _process(delta: float) -> void:
	if _stage == null:
		return
	_update_corpses(delta)
	if _transitioning:
		return
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

	var was_reforming: bool = _wave_staging_state == WaveStagingState.REFORMING
	_update_wave_staging(delta)
	if was_reforming and _wave_staging_state == WaveStagingState.CENTER_WAIT:
		_spawn_next_wave() ## vừa dàn quân xong đúng đội hình - spawn đợt kế NGAY, khỏi chờ đồng hồ cố định nào cả
		return
	if _wave_staging_state == WaveStagingState.REFORMING:
		return ## đang lo giả vờ tiến/dàn quân lại - quái đã chết sạch, chưa có gì để AI/kiểm tra thêm

	_resolver.run_ai(party_units, enemy_units, delta, _member_troop_ids, _current_free_movement_x())
	_resolver.resolve_collisions(party_units, enemy_units)
	_check_wipe()

## Trong lúc chờ RESTART_DELAY, CombatResolver không còn chạy nên phải tự gọi
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

## Quái ĐỢT HIỆN TẠI chết sạch mà party còn sống: còn đợt kế tiếp trong tầng
## này -> chuyển REFORMING (KHÔNG kết thúc tầng, xem _update_reforming()); là
## đợt CUỐI CÙNG -> THẮNG CẢ TẦNG (lên tầng, RESTART_DELAY). Party chết sạch
## (bất kể đợt nào) = THUA -> đánh lại từ ĐỢT 1 của đúng tầng này
## (RESTART_DELAY, xem _revive_all). Guard REFORMING: tránh set lại
## _reform_timer chồng lên chính nó mỗi frame trong lúc đang REFORMING dở.
func _check_wipe() -> void:
	if _restart_timer >= 0.0 or _wave_staging_state == WaveStagingState.REFORMING:
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
		_wave_staging_state = WaveStagingState.REFORMING
		_reform_timer = REFORM_FAKE_WALK_DURATION
	else:
		_pending_win = true
		_restart_timer = RESTART_DELAY

## Báo GameState mở khoá tầng vừa thắng, rồi nạp tầng kế tiếp của ĐÚNG map
## đang treo - tầng tiến được VÔ HẠN kể cả khi chưa author StageData thật cho
## tầng đó (xem GameState.resolve_stage_for_floor - tự duplicate() tầng cuối
## cùng có sẵn, chỉ map_id/floor_number còn được đọc thật ở luồng này).
func _advance_floor() -> void:
	_transitioning = true
	await _wipe.close()
	var map_id: int = _stage.map_id
	var current_floor: int = _stage.floor_number
	GameState.report_floor_cleared(map_id, current_floor)

	var floors: Array[StageData] = StageDatabase.get_floors_for_map(map_id)
	var next_stage: StageData = GameState.resolve_stage_for_floor(floors, current_floor + 1)
	configure(next_stage, _member_troop_ids)
	await _wipe.open()
	_transitioning = false

## Thua -> đánh lại ĐỢT 1 của đúng tầng đang treo (không tiếp tục từ đợt đang
## thua) - hồi sinh party TẠI CHỖ rồi đưa .position về lại đội hình gốc quanh
## _map_center_x (party đã đi xa theo các đợt trước đó), dọn quái đợt dở dang,
## reset lại state đợt về ban đầu rồi spawn lại đợt 1.
func _revive_all() -> void:
	for unit in party_units:
		unit.revive()
	_death_timers.clear()
	_spawn_player_team_positions(Vector2(_map_center_x, 0.0))
	_wave_staging_state = WaveStagingState.CENTER_WAIT
	_current_wave_index = -1
	_spawn_next_wave()

## Đưa phe mình về ĐÚNG đội hình gốc quanh `center` (không spawn lại unit mới,
## chỉ set lại .position) - dùng khi hồi sinh (_revive_all()), vì lúc đó
## party_units đã tồn tại sẵn, khác _spawn_player_team() (spawn unit MỚI).
func _spawn_player_team_positions(center: Vector2) -> void:
	for i in range(party_units.size()):
		party_units[i].position = center + FORMATION_OFFSETS[i % FORMATION_OFFSETS.size()] * FORMATION_SPACING

## ============================== DEBUG_TEST_MODE ==============================

## CHỈ chạy khi DEBUG_TEST_MODE - phóng to camera THẬT SỰ ra đủ để thấy toàn
## bộ map (khung hình chuẩn + khu spawn), vẽ đường chia 6 vùng (Cam-1..4 +
## Spawn-1..2) + các mốc quan trọng bằng ColorRect mỏng. KHÔNG đổi bất kỳ hằng
## số/mốc thật nào ở trên - camera lúc chơi bình thường (không debug) vẫn
## đứng yên tại (0,0) zoom=1.
func _setup_debug_view(viewport_half_width: float) -> void:
	var debug_left: float = _map_center_x - viewport_half_width
	var debug_right: float = _wave_spawn_x + CAMERA_VIEW_MARGIN
	var debug_zoom: float = (viewport_half_width * 2.0) / (debug_right - debug_left)
	camera.zoom = Vector2(debug_zoom, debug_zoom)
	camera.position.x = (debug_left + debug_right) * 0.5

	## Vẽ vào 1 layer RIÊNG (không phải arena - arena bị configure() xoá sạch
	## mỗi lần lên tầng/hồi sinh đợt 1, sẽ xoá luôn mấy đường debug này).
	var debug_layer := Node2D.new()
	arena.get_parent().add_child(debug_layer)

	var cam_quarter: float = viewport_half_width * 0.5
	_add_debug_vline(debug_layer, debug_left, Color.YELLOW) ## mép trái Cam-1 ("hình vuông" camera chuẩn)
	_add_debug_vline(debug_layer, _map_center_x - cam_quarter, Color.CYAN) ## Cam-1/Cam-2
	_add_debug_vline(debug_layer, _map_center_x, Color.WHITE) ## Cam-2/Cam-3 (tâm - đội hình ban đầu, CENTER_WAIT)
	_add_debug_vline(debug_layer, _map_center_x + cam_quarter, Color.CYAN) ## Cam-3/Cam-4
	_add_debug_vline(debug_layer, _engage_trigger_x, Color.RED) ## giữa Cam-4 - quái tới đây thì phá đội hình (ENGAGED)
	_add_debug_vline(debug_layer, _camera_right_edge_x, Color.YELLOW) ## mép phải Cam-4 ("hình vuông" camera chuẩn) = Cam-4/Spawn-1
	_add_debug_vline(debug_layer, _retreat_trigger_x, Color.CYAN) ## Spawn-1/Spawn-2 - quái lọt qua đây thì bắt đầu RETREATING
	_add_debug_vline(debug_layer, _wave_spawn_x, Color.ORANGE) ## quái spawn ở đây
	_add_debug_vline(debug_layer, _retreat_x, Color.GREEN) ## đội hình lùi về đây (RETREATING)

func _add_debug_vline(parent: Node2D, x: float, color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.size = Vector2(3.0, DEBUG_ZONE_LINE_HEIGHT)
	line.position = Vector2(x - 1.5, -DEBUG_ZONE_LINE_HEIGHT * 0.5)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 100
	parent.add_child(line)
