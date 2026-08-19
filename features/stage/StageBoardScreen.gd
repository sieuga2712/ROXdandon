class_name StageBoardScreen
extends Control

## Tab "Ải" - đúng tỉ lệ 1/3 trên - 2/3 dưới theo mockup
## mockups/giao-dien-hien-tai.html (#stage): Phần 1 (BattleViewHost, ~1/3
## TRÊN) nhúng LIÊN TỤC trận đang chạy vào để xem trực tiếp - MẶC ĐỊNH là
## StageFarmWorld (treo máy, xem _mount_battle_view()), nhưng khi đánh boss
## (xem dưới) TẠM THỜI đổi sang hiện BattleScene ngay tại đây (KHÔNG mở toàn
## màn như trước 2026-08 - xem _mount_boss_battle()/_unmount_boss_battle()).
## Phần 2 (~2/3 DƯỚI) - 3 sub-tab CÙNG 1 HÀNG (gộp lại 2026-08, không còn tab
## "Ải Boss" trung gian): "ẢI THƯỜNG" (danh sách map, bấm 1 ải là TREO NGAY tại
## map đó qua GameState.start_idle_team_on_map) / "BOSS NGÀY" / "BOSS KHỦNG"
## (2 cái sau cùng hiện chung 1 panel BossBoardScreen đã nhúng sẵn, chỉ đổi
## panel con nào hiển thị qua BossBoardScreen.show_daily_tab()/show_world_tab()).
##
## Trạng thái treo còn thể hiện thêm qua viền xanh "current" trên đúng thẻ map
## đang treo trong danh sách, xem _build_map_cards().
##
## Mới vào lần đầu (chưa có đội treo) tự treo NGAY map đầu tiên - xem _ready().
## Thắng 1 tầng thì StageFarmWorld tự lên tầng kế, thua thì tự đánh lại đúng
## tầng đó (xem StageFarmWorld._check_wipe()/_advance_floor()) - màn này chỉ
## cần refresh định kỳ (%AfkRefreshTimer) để hiện đúng tầng/map/trận mới nhất,
## tự nó không điều khiển tiến trình đó (NGOẠI TRỪ lúc đang đánh boss -
## _boss_battle_active chặn timer tự remount treo máy đè lên trận boss).
##
## MainShell làm trung gian nối stage_selected -> StageFlowController.start_stage
## và ngược lại StageFlowController.stage_finished -> on_stage_finished (đúng
## pattern BottomNav<->ScreenRouter đã dùng), đồng thời tiêm (inject) instance
## BattleScene DUY NHẤT của app vào đây qua set_battle_scene() - CHỈ còn liên
## quan tới Ải Boss (đánh tay thật), Ải Thường không còn dùng BattleScene nữa.

signal stage_selected(stage: StageData)

const CARD_BG: Color = Color(0.2, 0.212, 0.235) ## #33363c - .stage-item
const CARD_BORDER: Color = Color(0.29, 0.302, 0.329) ## #4a4d54 - .stage-item border
const CARD_BORDER_CURRENT: Color = Color(0.416, 0.541, 0.416) ## #6a8a6a - .stage-item.current
const CARD_BG_CURRENT: Color = Color(0.18, 0.212, 0.188) ## #2e3630 - .stage-item.current
const MUTED: Color = Color(0.56, 0.6, 0.68)
const TEXT: Color = Color(0.9, 0.91, 0.93)

const AFK_REFRESH_INTERVAL: float = 1.0 ## StageFarmWorld tự lên tầng/đánh lại/đổi map ngầm - phải poll định kỳ để hiện đúng tầng/viền "current"/trận mới nhất, không có signal báo trực tiếp

@onready var battle_view_host: Control = %BattleViewHost
@onready var sub_tab_row: HBoxContainer = %SubTabRow
@onready var stage_list_panel: Control = %StageListPanel
@onready var boss_panel: BossBoardScreen = %BossPanel
@onready var map_list: VBoxContainer = %MapList
@onready var afk_refresh_timer: Timer = %AfkRefreshTimer

var _hosted_farm_map: StageFarmMap = null ## instance StageFarmMap hiện đang nhúng trong battle_view_host - đổi khi chuyển map (GameState tạo instance MỚI, xem start_idle_team_on_map), xem _mount_battle_view()

var _battle_scene: BattleScene = null ## tiêm bởi MainShell qua set_battle_scene() - KHÔNG sở hữu, chỉ mượn tạm vào battle_view_host lúc đánh boss
var _battle_scene_home_parent: Node = null ## cha gốc của _battle_scene (MainShell) - trả về đúng chỗ cũ khi đánh xong, xem _unmount_boss_battle()
var _boss_battle_active: bool = false ## true = đang hiện BattleScene trong battle_view_host (đè lên treo máy) - chặn %AfkRefreshTimer tự remount treo máy đè lên trận boss
var _view_wipe: ScreenWipe ## phủ đen lúc đổi map treo máy - xem _on_stage_item_pressed(). Luôn nổi trên cùng (z_index riêng, xem ScreenWipe) dù StageFarmMap/BattleScene reparent vào SAU nó.

func _ready() -> void:
	_build_sub_tab_buttons()
	boss_panel.stage_selected.connect(_on_boss_stage_selected)
	afk_refresh_timer.wait_time = AFK_REFRESH_INTERVAL
	afk_refresh_timer.timeout.connect(_on_refresh_timer_timeout)

	_view_wipe = ScreenWipe.new()
	battle_view_host.add_child(_view_wipe)

	## Mặc định treo ải đầu tiên của map đầu tiên ngay lần đầu vào tab, đúng
	## yêu cầu "mặc định đánh ải đầu tiên tại map đầu tiên của ải thường".
	if not GameState.has_idle_team():
		var maps := MapDatabase.get_all()
		if not maps.is_empty():
			GameState.start_idle_team_on_map(maps[0].id, GameState.PARTY_TROOP_IDS)

	_mount_battle_view()
	_build_map_cards()
	_set_sub_tab("normal")

## MainShell gọi 1 lần lúc khởi tạo, tiêm instance BattleScene DUY NHẤT của cả
## app vào đây - StageBoardScreen mượn tạm (reparent) instance này vào
## battle_view_host mỗi khi đánh boss (xem _mount_boss_battle()), trả về đúng
## cha gốc (MainShell) khi đánh xong (xem _unmount_boss_battle()) - KHÔNG sở
## hữu/tạo instance mới, BattleScene vẫn sống ở MainShell.tscn như cũ.
func set_battle_scene(scene: BattleScene) -> void:
	_battle_scene = scene
	_battle_scene_home_parent = scene.get_parent()

func _on_refresh_timer_timeout() -> void:
	if not _boss_battle_active:
		_mount_battle_view()
	_build_map_cards()

## Nhúng (reparent, KHÔNG tạo bản mới) đúng instance StageFarmMap đang chạy
## nền vào battle_view_host để xem trực tiếp, liên tục - không phải màn popup
## bấm mới hiện như bản cũ. GameState.start_idle_team_on_map() tạo instance
## MỚI mỗi lần đổi map (xem GameState.gd) nên phải so sánh lại instance mỗi
## lần refresh, không chỉ gọi 1 lần lúc _ready(). KHÔNG gọi trong lúc
## _boss_battle_active (xem _on_refresh_timer_timeout) - sẽ đè mất trận boss.
func _mount_battle_view() -> void:
	var farm_map: StageFarmMap = GameState.get_idle_farm_map()
	if farm_map == _hosted_farm_map:
		return
	for child in battle_view_host.get_children():
		if child == _view_wipe:
			continue ## overlay wipe sống cố định ở đây - không phải xác instance cũ
		child.queue_free() ## xác instance StageFarmMap cũ (nếu có) - không queue_free() farm_map hiện tại, chỉ dọn con thừa nếu lỡ có
	_hosted_farm_map = farm_map
	if farm_map == null:
		return
	farm_map.reparent(battle_view_host, false)
	farm_map.set_anchors_preset(Control.PRESET_FULL_RECT)

## Đổi trận đang hiện trong battle_view_host từ treo máy sang boss thật, gọi
## NGAY khi bấm "THÁCH ĐẤU" (trước khi tín hiệu stage_selected bubble lên
## MainShell -> StageFlowController.start_stage - BattleScene phải đã nằm sẵn
## trong battle_view_host lúc start_battle() spawn quân để hiện đúng chỗ).
func _on_boss_stage_selected(stage: StageData) -> void:
	_mount_boss_battle()
	stage_selected.emit(stage)

func _mount_boss_battle() -> void:
	if _battle_scene == null:
		return
	_boss_battle_active = true
	## Trả treo máy về lại "nhà" thật (GameState, xem GameState.start_idle_team_on_map)
	## để nó tiếp tục chạy nền - KHÔNG destroy, farm không mất tiến độ trong
	## lúc đánh boss (đúng quy ước "farm chạy bất kể tab nào" của game).
	if _hosted_farm_map != null and _hosted_farm_map.get_parent() == battle_view_host:
		_hosted_farm_map.reparent(GameState, false)
	_hosted_farm_map = null
	_battle_scene.reparent(battle_view_host, false)
	_battle_scene.set_anchors_preset(Control.PRESET_FULL_RECT)

## Gọi từ on_stage_finished() (StageFlowController.stage_finished bắn ra sau
## khi user đóng bảng kết quả thắng/thua) - trả BattleScene về cha gốc rồi
## remount lại treo máy (đã bị "mượn chỗ" đưa sang GameState lúc _mount_boss_battle).
func _unmount_boss_battle() -> void:
	if _battle_scene == null or not _boss_battle_active:
		return
	_boss_battle_active = false
	if _battle_scene.get_parent() == battle_view_host:
		_battle_scene.reparent(_battle_scene_home_parent, false)
	_mount_battle_view()

func _build_sub_tab_buttons() -> void:
	var normal_button := Button.new()
	normal_button.text = "ẢI THƯỜNG"
	normal_button.pressed.connect(_set_sub_tab.bind("normal"))
	sub_tab_row.add_child(normal_button)

	var daily_button := Button.new()
	daily_button.text = "BOSS NGÀY"
	daily_button.pressed.connect(_set_sub_tab.bind("boss_daily"))
	sub_tab_row.add_child(daily_button)

	var world_button := Button.new()
	world_button.text = "BOSS KHỦNG"
	world_button.pressed.connect(_set_sub_tab.bind("boss_world"))
	sub_tab_row.add_child(world_button)

func _set_sub_tab(tab: String) -> void:
	stage_list_panel.visible = tab == "normal"
	boss_panel.visible = tab != "normal"
	if tab == "boss_daily":
		boss_panel.show_daily_tab()
	elif tab == "boss_world":
		boss_panel.show_world_tab()

## ============================== Tab "Ải Thường" ==============================
## Bấm 1 ải = TREO NGAY tại map đó bằng GameState.PARTY_TROOP_IDS (đội cố định
## duy nhất hiện có, chưa có hệ đội hình nhiều-preset) - không còn bước chọn
## tầng/thành viên thủ công, không còn "VÀO TRẬN" qua BattleScene.

func _build_map_cards() -> void:
	for child in map_list.get_children():
		child.queue_free()
	var current_map_id: int = -1
	if GameState.has_idle_team():
		var stage: StageData = GameState.get_idle_farm_map().get_stage()
		if stage != null:
			current_map_id = stage.map_id
	for map_data in MapDatabase.get_all():
		map_list.add_child(_build_stage_item(map_data, map_data.id == current_map_id))

func _build_stage_item(map_data: MapData, is_current: bool) -> PanelContainer:
	var bg := CARD_BG_CURRENT if is_current else CARD_BG
	var border := CARD_BORDER_CURRENT if is_current else CARD_BORDER
	var card := _styled_panel(bg, border, 1, 7)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 10)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var icon_badge := _styled_panel(Color(0.239, 0.251, 0.275), CARD_BORDER, 0, 6)
	icon_badge.custom_minimum_size = Vector2(42, 42)
	var icon_label := Label.new()
	icon_label.text = map_data.map_icon
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_badge.add_child(icon_label)
	row.add_child(icon_badge)

	var info_col := VBoxContainer.new()
	info_col.add_theme_constant_override("separation", 3)
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = map_data.map_name
	name_label.add_theme_color_override("font_color", TEXT)
	name_label.add_theme_font_size_override("font_size", 13)
	var floor_label := Label.new()
	floor_label.text = "Tầng %d" % _next_floor_for_map(map_data.id)
	floor_label.add_theme_color_override("font_color", MUTED)
	floor_label.add_theme_font_size_override("font_size", 10)
	info_col.add_child(name_label)
	info_col.add_child(floor_label)
	row.add_child(info_col)

	var arrow := Label.new()
	arrow.text = "›"
	arrow.add_theme_color_override("font_color", Color(0.47, 0.47, 0.47))
	arrow.add_theme_font_size_override("font_size", 18)
	row.add_child(arrow)

	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_stage_item_pressed.bind(map_data.id))
	card.add_child(button)

	return card

## Tầng sẽ treo NẾU bấm ải này ngay bây giờ - khớp đúng công thức
## GameState.start_idle_team_on_map() dùng để chọn tầng bắt đầu.
func _next_floor_for_map(map_id: int) -> int:
	var floors: Array[StageData] = StageDatabase.get_floors_for_map(map_id)
	if floors.is_empty():
		return 1
	return mini(GameState.get_highest_floor(map_id) + 1, floors[-1].floor_number)

## "Wipe đóng/mở" quanh lúc đổi map treo máy - phủ đen TRƯỚC khi
## GameState tạo instance StageFarmMap mới (đổi đột ngột, không animation),
## mờ dần mở ra SAU khi đã nhúng xong map mới vào view.
func _on_stage_item_pressed(map_id: int) -> void:
	await _view_wipe.close()
	GameState.start_idle_team_on_map(map_id, GameState.PARTY_TROOP_IDS)
	_mount_battle_view() ## đổi ngay, không đợi %AfkRefreshTimer tick tiếp theo (tối đa 1s sau)
	_build_map_cards()
	await _view_wipe.open()

## MainShell gọi lại sau khi StageFlowController.stage_finished bắn ra (user
## vừa đóng bảng kết quả thắng/thua trong BattleScene) - CHỈ còn liên quan Ải
## Boss (đánh tay thật qua BattleScene), Ải Thường không còn dùng BattleScene
## nữa (tiến trình tự chạy trong StageFarmWorld). Trả BattleScene về cha gốc +
## remount lại treo máy vào battle_view_host (xem _unmount_boss_battle()).
func on_stage_finished(_stage: StageData, _won: bool) -> void:
	_unmount_boss_battle()
	boss_panel.on_stage_finished(_stage, _won)

## ============================== Helper style ==============================

func _styled_panel(bg: Color, border: Color, border_width: int, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(bg, border, border_width, radius))
	return panel

func _flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	return style
