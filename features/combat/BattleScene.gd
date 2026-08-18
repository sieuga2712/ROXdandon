class_name BattleScene
extends Control

## Màn chiến đấu PvE - auto-battle: bấm "Chọn ải" xong vào thẳng trận, không
## còn pha "xếp quân" (party cố định 4 người, không có gì để chọn trước mỗi
## trận - xem GameState.PARTY_TROOP_IDS). start_battle(stage) spawn phe mình
## vào %BattleArena (SubViewport riêng) rồi lần lượt spawn N đợt quái thường
## NGẪU NHIÊN (StageData.boss_trash_wave_count, xem EncounterGenerator), đợt
## CUỐI CÙNG luôn là boss thật (enemy_troop_ids/enemy_troop_counts) - xem
## _spawn_next_wave()/_check_battle_end(). Mỗi đợt thường có đồng hồ đếm ngược
## WAVE_TIMEOUT (10s) riêng - đánh không kịp thì đợt kế vẫn spawn CHỒNG LÊN
## đợt cũ (không xoá quái cũ, "chồng đợt", càng chậm càng dồn thêm quái) - xem
## _check_wave_timeout().
##
## Mô hình bản đồ "treadmill" (2026-08): CAMERA CỐ ĐỊNH VĨNH VIỄN tại (0,0)
## (xem _ready()). Khung hình camera (rộng 2*viewport_half_width) chia làm 4
## PHẦN BẰNG NHAU theo chiều ngang (Cam-1..Cam-4, trái->phải); khu vực quái
## spawn (NGOÀI khung hình, bên phải Cam-4) chia làm 2 phần (Spawn-1 gần
## camera, Spawn-2 xa/nơi quái spawn thật). Mỗi đợt, phe mình dàn quân theo 4
## GIAI ĐOẠN (WaveStagingState, xem _update_wave_staging()):
## 1. CENTER_WAIT - đứng ở ranh giới Cam-2/Cam-3 (chính giữa khung hình),
##    xếp đội hình "2-3-2 hình lục giác" (FORMATION_OFFSETS), giả vờ đi bộ
##    (animation walk, KHÔNG đổi vị trí thật) trong lúc quái còn ở Spawn-2.
## 2. RETREATING - quái lọt vào Spawn-1 (ranh giới Spawn-1/Spawn-2) -> phe
##    mình LÙI THẬT (đổi vị trí) về GIỮA Cam-1, map tự điều khiển .position
##    (CombatResolver chỉ biết "tiến tới", không có khái niệm "lùi xa").
## 3. ENGAGED - quái đi tới GIỮA Cam-4 -> phá đội hình, bỏ mọi ràng buộc, cả 2
##    bên tự do lao vào nhau như AI bình thường (CombatResolver lo hết).
## 4. REFORMING - quái đợt vừa rồi chết sạch (còn đợt kế) -> phe mình giả vờ
##    tiến thêm về bên phải 1 nhịp ngắn, RỒI mới thật sự đi (lerp) về lại
##    ĐÚNG 7 chỗ đội hình 2-3-2 tại CENTER_WAIT - xong mới spawn đợt kế
##    (không dùng đồng hồ cố định như bản trước - đợi dàn quân THẬT SỰ xong).
## Không còn world dài ra vô hạn cần bám/giới hạn/recenter camera phức tạp.
##
## Trận kết thúc khi phe mình chết hết/hết giờ (THUA) hoặc đợt boss chết (THẮNG).
##
## Toàn bộ hành vi CHIẾN ĐẤU của 1 đơn vị (targeting, né nhau, đòn đánh
## thường, skill "Đánh mạnh", đạn bay, rớt đồ, thưởng EXP/vàng) nằm ở
## `core/combat/CombatResolver.gd` - DÙNG CHUNG với StageFarmWorld (Treo máy),
## vì đây là đặc trưng của NHÂN VẬT chứ không phải của map. File này chỉ còn
## lo phần MAP: camera/vị trí spawn/giai đoạn dàn quân/timing đợt/kết thúc
## trận/vòng đời.
##
## Quyết định thiết kế (kế thừa từ bản city-builder cũ, xem lịch sử):
## - Sát thương = ATK (x Crit Damage nếu chí mạng) TRỪ THẲNG (không phải %),
##   giáp hiệu quả giảm theo Armor Penetration - xem CombatResolver._resolve_attack().
## - Quái vẫn rải quanh tâm đợt theo vòng tròn, bán kính tự giãn theo số
##   lượng (`maxf(SPREAD_RADIUS, total * 9.0)`) - xem _spawn_enemy_team().

signal closed(won: bool) ## StageFlowController lắng nghe để biết có mở khoá tầng kế tiếp không (xem tab "Vượt ải")

const TROOP_UNIT_SCENE: PackedScene = preload("res://entities/troop/TroopUnit.tscn")

const SPREAD_RADIUS: float = 44.0 ## Bán kính rải quái quanh tâm đợt - giống hệt StageFarmWorld, xem _spawn_enemy_team()

const FORMATION_SPACING: float = 40.0 ## khoảng cách giữa các hàng/cột trong đội hình 2-3-2, xem FORMATION_OFFSETS
## Đội hình "2-3-2 hình lục giác": hàng SAU (2, xa quái nhất, offset.x=-1) và
## hàng TRƯỚC (2, gần quái nhất, offset.x=1) HẸP; hàng GIỮA (3, offset.x=0)
## dàn RỘNG NHẤT - nối các điểm ngoài lại đúng hình lục giác. Gán vào lính
## theo INDEX (i % 7) - CHƯA có logic "ai đứng vị trí nào" (tank đứng
## trước...), để xử lý sau.
const FORMATION_OFFSETS: Array[Vector2] = [
	Vector2(-1.0, -0.5), Vector2(-1.0, 0.5), ## hàng SAU (2, hẹp)
	Vector2(0.0, -1.0), Vector2(0.0, 0.0), Vector2(0.0, 1.0), ## hàng GIỮA (3, rộng nhất)
	Vector2(1.0, -0.5), Vector2(1.0, 0.5), ## hàng TRƯỚC (2, hẹp)
]

const CAMERA_VIEW_MARGIN: float = 40.0 ## đệm dôi thêm quanh nền, tránh lộ mép đúng lúc party/quái đứng sát biên
const WAVE_SPAWN_MARGIN: float = 500.0 ## tổng bề rộng khu Spawn (ngoài khung hình camera) - chia làm 2 phần bằng nhau (Spawn-1 gần camera, Spawn-2 xa/nơi quái spawn thật)
const BOSS_EXTRA_DISTANCE: float = 300.0 ## boss spawn xa hơn đợt thường 1 khoảng cố định (tính từ Spawn-2) - tạo cảm giác "boss ở xa/đáng gờm hơn" dù camera không đổi

const WAVE_TIMEOUT: float = 10.0 ## đánh 1 đợt thường quá lâu (quá chừng này giây kể từ lúc spawn mà chưa sạch quái) thì ép spawn đợt kế CHỒNG LÊN thay vì chờ - "chồng đợt" (đánh càng chậm càng dồn thêm quái, khó hơn hẳn), xem _check_wave_timeout()/_spawn_next_wave()
const REFORM_FAKE_WALK_DURATION: float = 0.4 ## đầu giai đoạn REFORMING - phe mình "giả vờ" tiến thêm về bên phải (animation, KHÔNG đổi vị trí) đúng chừng này giây trước khi thật sự đi (lerp) về đội hình
const REFORM_ARRIVE_EPSILON: float = 4.0 ## coi là "đã về tới" đúng chỗ đội hình khi còn cách chừng này (px) - tránh rung/không bao giờ khớp tuyệt đối do float

## Giai đoạn dàn quân đợt HIỆN TẠI - xem _update_wave_staging().
enum WaveStagingState { CENTER_WAIT, RETREATING, ENGAGED, REFORMING }

## ================== DEBUG (đổi lại true nếu cần bật lại lúc test) ==================
const DEBUG_SHOW_COLLISION_SHAPES: bool = false
const DEBUG_FREEZE_UNITS: bool = false
## true = phóng to camera ra để thấy TOÀN BỘ map (khung hình chuẩn + khu
## spawn + boss xa nhất) + vẽ các đường chia vùng để xem trực quan lúc test -
## KHÔNG ảnh hưởng logic thật (mọi mốc/toạ độ vẫn tính theo khung hình CHUẨN
## chưa phóng to, xem _setup_debug_view()).
const DEBUG_TEST_MODE: bool = false
const DEBUG_ZONE_LINE_HEIGHT: float = 900.0

@onready var arena: Node2D = %BattleArena
@onready var battle_camera: Camera2D = %BattleCamera
@onready var battle_arena_background: ColorRect = %BattleArenaBackground
@onready var timer_label: Label = %BattleTimerLabel
@onready var result_panel: PanelContainer = %BattleResultPanel
@onready var result_title: Label = %BattleResultTitle
@onready var result_reward: Label = %BattleResultReward
@onready var result_close_button: Button = %BattleResultCloseButton
@onready var surrender_button: Button = %SurrenderButton

var _resolver: CombatResolver

var _stage: StageData
var _player_units: Array[TroopUnit] = []
var _enemy_units: Array[TroopUnit] = []
var _time_left: float = 0.0
var _active: bool = false ## true = đang chạy AI mỗi frame (xem _process)
var _last_result_won: bool = false ## lưu lại từ _end_battle() để _on_result_closed() phát kèm signal closed(won)

var _wave_count: int = 1 ## boss_trash_wave_count + 1 (đợt cuối = boss thật) - xem start_battle()
var _current_wave_index: int = -1 ## đợt đang đánh (0-based), -1 = chưa spawn đợt nào
var _wave_anchor_x: float = 0.0 ## tâm X đợt HIỆN TẠI - luôn = _wave_spawn_x (đợt thường) hoặc _boss_spawn_x (đợt boss), xem _spawn_next_wave()
var _wave_timeout_timer: float = -1.0 ## đếm ngược WAVE_TIMEOUT kể từ lúc đợt HIỆN TẠI spawn - hết giờ mà VẪN CÒN quái sống thì ép spawn đợt kế CHỒNG LÊN (xem _check_wave_timeout()). -1 = không áp dụng (đang là đợt boss cuối)
var _wave_staging_state: WaveStagingState = WaveStagingState.ENGAGED ## reset về CENTER_WAIT (đợt đầu) hoặc REFORMING (đợt sau) - giá trị khởi tạo không quan trọng
var _reform_timer: float = 0.0 ## đếm ngược REFORM_FAKE_WALK_DURATION lúc mới vào REFORMING - xem _update_reforming()

var _map_center_x: float = 0.0 ## = camera.position.x, ranh giới Cam-2/Cam-3 - đội hình ban đầu đứng đây (CENTER_WAIT)
var _retreat_x: float = 0.0 ## GIỮA Cam-1 - vị trí phe mình lùi về lúc RETREATING
var _engage_trigger_x: float = 0.0 ## GIỮA Cam-4 - quái X <= giá trị này -> ENGAGED (phá đội hình)
var _camera_right_edge_x: float = 0.0 ## mép phải Cam-4 = ranh giới Cam-4/Spawn-1
var _retreat_trigger_x: float = 0.0 ## ranh giới Spawn-1/Spawn-2 - quái X <= giá trị này (đã lọt vào Spawn-1) -> bắt đầu RETREATING
var _wave_spawn_x: float = 0.0 ## vị trí spawn CỐ ĐỊNH cho MỌI đợt thường (giữa Spawn-2, xa nhất) - tính 1 lần ở _ready(), camera không đổi nên không cần tính lại
var _boss_spawn_x: float = 0.0 ## vị trí spawn CỐ ĐỊNH cho đợt boss - xa hơn _wave_spawn_x đúng BOSS_EXTRA_DISTANCE

func _ready() -> void:
	visible = false
	result_panel.visible = false
	result_close_button.pressed.connect(_on_result_closed)
	surrender_button.pressed.connect(_on_surrender_pressed)
	if DEBUG_SHOW_COLLISION_SHAPES:
		get_tree().debug_collisions_hint = true
	battle_camera.zoom = Vector2.ONE
	_resolver = CombatResolver.new(arena, false) ## false = KHÔNG cộng vàng lúc giết - BattleScene cộng vàng 1 CỤC lúc thắng, xem _end_battle()
	_resolver.debug_freeze_units = DEBUG_FREEZE_UNITS

	## Camera CỐ ĐỊNH VĨNH VIỄN tại (0,0) - không bám theo ai, không đổi trong
	## suốt vòng đời scene. Mọi vị trí dàn quân/spawn đều suy ra từ đây, tính 1
	## lần vì camera không bao giờ đổi (kể cả khi DEBUG_TEST_MODE phóng to
	## camera THẬT SỰ để xem - các mốc dưới đây vẫn tính theo khung hình CHUẨN
	## này, xem _setup_debug_view()).
	battle_camera.position = Vector2.ZERO
	var viewport_half_width: float = get_viewport_rect().size.x / 2.0
	var cam_quarter: float = viewport_half_width * 0.5 ## bề rộng 1/4 khung hình (khung hình rộng 2*half, chia 4 phần bằng nhau)
	_map_center_x = battle_camera.position.x
	_retreat_x = _map_center_x - viewport_half_width + cam_quarter * 0.5 ## giữa Cam-1
	_camera_right_edge_x = _map_center_x + viewport_half_width
	_engage_trigger_x = _camera_right_edge_x - cam_quarter * 0.5 ## giữa Cam-4
	_retreat_trigger_x = _camera_right_edge_x + WAVE_SPAWN_MARGIN * 0.5 ## ranh giới Spawn-1/Spawn-2
	_wave_spawn_x = _camera_right_edge_x + WAVE_SPAWN_MARGIN
	_boss_spawn_x = _wave_spawn_x + BOSS_EXTRA_DISTANCE
	## Nền chỉ cần phủ đúng khung hình camera THẬT SỰ hiển thị lúc chơi thường
	## - camera cố định vĩnh viễn nên không bao giờ lộ ra ngoài khoảng
	## [-half, +half] này, kể cả quái spawn/đứng xa tít ngoài
	## _wave_spawn_x/_boss_spawn_x (không bao giờ được camera vẽ tới).
	battle_arena_background.offset_left = -viewport_half_width - CAMERA_VIEW_MARGIN
	battle_arena_background.offset_right = viewport_half_width + CAMERA_VIEW_MARGIN

	if DEBUG_TEST_MODE:
		_setup_debug_view(viewport_half_width)

func start_battle(stage: StageData) -> void:
	_stage = stage
	_clear_units()
	_spawn_player_team(GameState.PARTY_TROOP_IDS, Vector2(_map_center_x, 0.0))
	_wave_staging_state = WaveStagingState.CENTER_WAIT

	_wave_count = maxi(stage.boss_trash_wave_count, 0) + 1 ## đợt cuối luôn là boss thật
	_current_wave_index = -1
	_spawn_next_wave()

	_time_left = stage.time_limit
	timer_label.text = "%d:%02d" % [int(_time_left) / 60, int(_time_left) % 60]
	_active = true
	result_panel.visible = false
	surrender_button.visible = true
	timer_label.visible = true
	visible = true

## Xếp phe mình vào ĐÚNG 7 chỗ đội hình "2-3-2 hình lục giác" quanh `center`
## (xem FORMATION_OFFSETS) - gán theo INDEX tạm thời, CHƯA phân biệt ai đứng
## vị trí nào.
func _spawn_player_team(troop_ids: Array[int], center: Vector2) -> void:
	for i in range(troop_ids.size()):
		var troop := TroopDatabase.get_by_id(troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, Enums.Team.PLAYER)
		unit.position = center + FORMATION_OFFSETS[i % FORMATION_OFFSETS.size()] * FORMATION_SPACING
		_player_units.append(unit)

## Rải quái quanh `center` theo vòng tròn, bán kính tự giãn theo số lượng
## (`maxf(SPREAD_RADIUS, total * 9.0)`) - giống hệt công thức spawn quái của
## StageFarmWorld._spawn_next_wave(). monster_level > 1 chỉ có ý nghĩa với
## quái (xem TroopUnit._monster_stat_multiplier) - boss thật giữ default 1 =
## dùng đúng số liệu tay trong LinhData, không bị cấp quái ăn vào.
func _spawn_enemy_team(troop_ids: Array[int], center: Vector2, monster_level: int = 1) -> void:
	var total := troop_ids.size()
	var radius := maxf(SPREAD_RADIUS, total * 9.0)
	for i in range(total):
		var troop := TroopDatabase.get_by_id(troop_ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		arena.add_child(unit)
		unit.setup(troop, Enums.Team.ENEMY, monster_level)
		var offset := Vector2.RIGHT.rotated(TAU * i / maxi(total, 1)) * radius
		unit.position = center + offset
		_enemy_units.append(unit)

## Spawn đợt KẾ TIẾP - MỌI đợt thường spawn tại ĐÚNG _wave_spawn_x (không đổi
## giữa các đợt, camera cố định nên không cần xoay vòng/tính lại gì cả), đợt
## CUỐI CÙNG (boss thật) tại _boss_spawn_x. KHÔNG còn tự đưa phe mình về đội
## hình/CENTER_WAIT ở đây nữa - việc đó do start_battle() (đợt đầu) hoặc
## _update_reforming() hoàn tất xong đội hình mới gọi hàm này (đợt sau) lo.
##
## clear_existing=true (mặc định, gọi khi đợt cũ đã sạch quái): dọn quái cũ
## trước khi spawn quái mới, như 1 lần chuyển đợt bình thường.
## clear_existing=false (gọi từ _check_wave_timeout() khi đánh quá lâu chưa
## sạch quái): GIỮ NGUYÊN quái cũ - quái đợt mới spawn CHỒNG LÊN - "chồng
## đợt", càng đánh chậm càng dồn thêm quái.
func _spawn_next_wave(clear_existing: bool = true) -> void:
	if clear_existing:
		for unit in _enemy_units:
			unit.queue_free()
		_enemy_units.clear()

	_current_wave_index += 1
	if _current_wave_index < _wave_count - 1:
		_wave_anchor_x = _wave_spawn_x
		var encounter := EncounterGenerator.generate_encounter(EncounterGenerator.BASE_MONSTERS_PER_WAVE, _stage.boss_trash_monster_level)
		_spawn_enemy_team(encounter["monster_ids"], Vector2(_wave_anchor_x, 0.0), encounter["monster_level"])
		_wave_timeout_timer = WAVE_TIMEOUT ## còn đợt sau -> bắt đầu đếm ngược mới cho đợt VỪA spawn này
	else:
		_wave_anchor_x = _boss_spawn_x
		_spawn_boss_wave()
		_wave_timeout_timer = -1.0 ## đợt cuối - không còn gì để chồng thêm, WAVE_TIMEOUT không áp dụng nữa

func _spawn_boss_wave() -> void:
	var enemy_ids: Array[int] = []
	for i in range(_stage.enemy_troop_ids.size()):
		for _n in range(_stage.enemy_troop_counts[i]):
			enemy_ids.append(_stage.enemy_troop_ids[i])
	_spawn_enemy_team(enemy_ids, Vector2(_wave_anchor_x, 0.0))

func _clear_units() -> void:
	for child in arena.get_children():
		child.queue_free()
	_player_units.clear()
	_enemy_units.clear()

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
	for u in _enemy_units:
		if not u.is_dead():
			nearest_enemy_x = minf(nearest_enemy_x, u.position.x)
	if nearest_enemy_x == INF:
		return ## chưa spawn quái - giữ nguyên trạng thái hiện tại

	if nearest_enemy_x <= _engage_trigger_x:
		_wave_staging_state = WaveStagingState.ENGAGED
		return

	if _wave_staging_state == WaveStagingState.CENTER_WAIT:
		if nearest_enemy_x <= _retreat_trigger_x:
			_wave_staging_state = WaveStagingState.RETREATING
		else:
			for unit in _player_units:
				if not unit.is_dead():
					unit.play_walk() ## giả vờ đi bộ tại chỗ - KHÔNG đổi .position
		return

	## RETREATING - lùi THẬT về _retreat_x, map tự set .position trực tiếp
	## (CombatResolver chỉ biết "tiến tới mục tiêu", không có khái niệm "lùi
	## xa mục tiêu" nên không thể diễn tả bước này qua run_ai()).
	for unit in _player_units:
		if unit.is_dead():
			continue
		if unit.position.x > _retreat_x:
			unit.play_walk()
			unit.position.x = maxf(unit.position.x - unit.move_speed_px() * delta, _retreat_x)
		else:
			unit.play_idle()

## Quái đợt vừa rồi đã chết sạch (còn đợt kế) - trước khi spawn đợt kế, phe
## mình: (1) giả vờ tiến thêm về bên phải REFORM_FAKE_WALK_DURATION giây
## (animation, KHÔNG đổi vị trí - đúng cảm giác "vừa thắng, còn hăng"), (2)
## SAU ĐÓ mới thật sự đi (lerp theo move_speed_px riêng từng người) về ĐÚNG 7
## chỗ đội hình 2-3-2 tại CENTER_WAIT (_map_center_x). Khi TẤT CẢ đã về đúng
## chỗ (trong REFORM_ARRIVE_EPSILON) mới coi là xong - _process() phát hiện
## chuyển sang CENTER_WAIT thì mới spawn đợt kế (xem _spawn_next_wave()) -
## không dùng đồng hồ cố định như bản trước, đợi dàn quân THẬT SỰ xong.
func _update_reforming(delta: float) -> void:
	if _reform_timer > 0.0:
		_reform_timer -= delta
		for unit in _player_units:
			if not unit.is_dead():
				unit.play_walk()
		return

	var all_arrived := true
	for i in range(_player_units.size()):
		var unit := _player_units[i]
		if unit.is_dead():
			continue
		var target: Vector2 = Vector2(_map_center_x, 0.0) + FORMATION_OFFSETS[i % FORMATION_OFFSETS.size()] * FORMATION_SPACING
		var to_target := target - unit.position
		if to_target.length() > REFORM_ARRIVE_EPSILON:
			unit.play_walk()
			unit.position += to_target.normalized() * unit.move_speed_px() * delta
			all_arrived = false
		else:
			unit.position = target
			unit.play_idle()
	if all_arrived:
		_wave_staging_state = WaveStagingState.CENTER_WAIT

func _process(delta: float) -> void:
	if not _active:
		return
	var was_reforming: bool = _wave_staging_state == WaveStagingState.REFORMING
	_update_wave_staging(delta)
	if was_reforming and _wave_staging_state == WaveStagingState.CENTER_WAIT:
		_spawn_next_wave() ## vừa dàn quân xong đúng đội hình - spawn đợt kế NGAY, khỏi chờ đồng hồ cố định nào cả
		return
	if _wave_staging_state == WaveStagingState.REFORMING:
		return ## đang lo giả vờ tiến/dàn quân lại - quái đã chết sạch, chưa có gì để AI/kiểm tra thêm (KHÔNG trừ _time_left, giống hệt lúc nghỉ giữa 2 đợt bản trước)

	_time_left = maxf(_time_left - delta, 0.0)
	timer_label.text = "%d:%02d" % [int(_time_left) / 60, int(_time_left) % 60]
	_resolver.run_ai(_player_units, _enemy_units, delta, GameState.PARTY_TROOP_IDS, _current_free_movement_x())
	_resolver.resolve_collisions(_player_units, _enemy_units)
	_check_battle_end()
	_check_wave_timeout(delta)

## CENTER_WAIT/RETREATING: map tự điều khiển phe mình (fake-walk hoặc lùi
## thật, xem _update_wave_staging()) - chặn CombatResolver tự ý di chuyển phe
## mình đè lên (trả -INF, không mục tiêu nào thoả target.x <= -INF). ENGAGED:
## bỏ hẳn ràng buộc (trả INF) - CombatResolver cho phe mình tự do lao vào quái.
func _current_free_movement_x() -> float:
	return INF if _wave_staging_state == WaveStagingState.ENGAGED else -INF

## Đếm ngược WAVE_TIMEOUT kể từ lúc đợt HIỆN TẠI spawn - hết giờ mà VẪN CÒN
## quái sống (đánh không kịp) thì ép spawn đợt KẾ TIẾP CHỒNG LÊN (không xoá
## quái cũ - "chồng đợt", xem _spawn_next_wave(false)). Không áp dụng cho đợt
## boss cuối (_wave_timeout_timer = -1 lúc đó) - hết giờ trong lúc đánh boss
## chỉ bị giới hạn bởi stage.time_limit chung của cả trận như cũ.
##
## Guard "còn quái sống": nếu quái vừa chết SẠCH đúng khung hình này,
## _check_battle_end() (chạy trước, cùng frame) đã lo chuyển sang REFORMING
## rồi - khỏi chồng thêm thừa.
func _check_wave_timeout(delta: float) -> void:
	if _wave_timeout_timer < 0.0:
		return
	_wave_timeout_timer -= delta
	if _wave_timeout_timer > 0.0:
		return
	if not _enemy_units.any(func(u: TroopUnit) -> bool: return not u.is_dead()):
		return
	_spawn_next_wave(false)

## Quái ĐỢT HIỆN TẠI chết sạch: còn đợt kế (trash hoặc boss) -> chuyển sang
## REFORMING (KHÔNG kết thúc trận, xem _update_reforming()); là đợt CUỐI CÙNG
## (boss thật) -> THẮNG CẢ TRẬN. Party chết sạch/hết giờ -> THUA như cũ
## (không phân biệt đợt). Guard REFORMING: tránh set lại _reform_timer chồng
## lên chính nó mỗi frame trong lúc đang REFORMING dở (enemy_alive vẫn false).
func _check_battle_end() -> void:
	var enemy_alive := _enemy_units.any(func(u): return not u.is_dead())
	var player_alive := _player_units.any(func(u): return not u.is_dead())
	if not player_alive:
		_end_battle(false)
	elif _time_left <= 0.0:
		_end_battle(false)
	elif not enemy_alive and _wave_staging_state != WaveStagingState.REFORMING:
		if _current_wave_index < _wave_count - 1:
			_wave_staging_state = WaveStagingState.REFORMING
			_reform_timer = REFORM_FAKE_WALK_DURATION
		else:
			_end_battle(true)

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

## ============================== DEBUG_TEST_MODE ==============================

## CHỈ chạy khi DEBUG_TEST_MODE - phóng to camera THẬT SỰ ra đủ để thấy toàn
## bộ map (khung hình chuẩn + khu spawn + boss xa nhất), vẽ đường chia 6 vùng
## (Cam-1..4 + Spawn-1..2) + các mốc quan trọng bằng ColorRect mỏng. KHÔNG đổi
## bất kỳ hằng số/mốc thật nào ở trên - camera lúc chơi bình thường (không
## debug) vẫn đứng yên tại (0,0) zoom=1.
func _setup_debug_view(viewport_half_width: float) -> void:
	var debug_left: float = _map_center_x - viewport_half_width
	var debug_right: float = _boss_spawn_x + CAMERA_VIEW_MARGIN
	var debug_zoom: float = (viewport_half_width * 2.0) / (debug_right - debug_left)
	battle_camera.zoom = Vector2(debug_zoom, debug_zoom)
	battle_camera.position.x = (debug_left + debug_right) * 0.5

	## Vẽ vào 1 layer RIÊNG (không phải arena - arena bị _clear_units() xoá
	## sạch mỗi lần start_battle(), sẽ xoá luôn mấy đường debug này).
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
	_add_debug_vline(debug_layer, _wave_spawn_x, Color.ORANGE) ## quái đợt thường spawn ở đây
	_add_debug_vline(debug_layer, _boss_spawn_x, Color(1, 0.4, 0.7)) ## boss spawn ở đây
	_add_debug_vline(debug_layer, _retreat_x, Color.GREEN) ## đội hình lùi về đây (RETREATING)

func _add_debug_vline(parent: Node2D, x: float, color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.size = Vector2(3.0, DEBUG_ZONE_LINE_HEIGHT)
	line.position = Vector2(x - 1.5, -DEBUG_ZONE_LINE_HEIGHT * 0.5)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 100
	parent.add_child(line)
