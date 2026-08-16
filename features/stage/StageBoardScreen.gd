class_name StageBoardScreen
extends Control

## Tab "Ải" - bảng kiểu "Ủy Thác" (theo mockup người dùng cung cấp) 3 sub-tab:
## - "Ủy Thác": danh sách thẻ map (MapDatabase, xếp dọc 1 cột) - mỗi thẻ hiện
##   icon/tên/loại khu vực/điều kiện thắng/độ khó/tầng hiện tại + nút "Vào
##   trận". Bấm nút = VÀO THẲNG tầng tiếp theo (highest+1) qua BattleScene,
##   KHÔNG có bước chọn tầng riêng (đã chốt - nút chỉ đổi TÊN so với mockup
##   gốc "CHỌN TẦNG TREO", hành vi vẫn là vào trận thật). Vai trò DUY NHẤT của
##   tab này với treo máy: mở khoá tầng cao hơn (xem GameState.highest_floor_cleared).
## - "Treo máy": hệ treo máy THẬT (xem GameState.start_idle_team) - CHỈ 1 team
##   tại 1 thời điểm (đơn giản hoá sau khi thảo luận lại, bỏ hẳn nhiều
##   team/nhiều map + công thức DPS/thời gian trôi qua). Còn trống thì hiện thẻ
##   "+" mở màn tạo team; có rồi thì hiện đúng 1 thẻ team đó (map/tầng/thành
##   viên) + nút XEM (nhúng thẳng trận đang chạy nền vào màn hình)/RÚT VỀ.
## - "Ải Boss": GỘP THÊM (trước đây là tab riêng ở BottomNav) - nhúng thẳng
##   instance BossBoardScreen.tscn làm 1 panel con (%BossPanel), KHÔNG copy lại
##   logic của nó. stage_selected của BossPanel được forward thẳng ra
##   stage_selected của chính StageBoardScreen (xem _ready), on_stage_finished
##   cũng forward xuống %BossPanel - MainShell chỉ còn nối 1 đầu mối duy nhất
##   (stage_screen) thay vì 2 đầu mối (stage_screen + boss_screen) như trước.
##
## MainShell làm trung gian nối stage_selected -> StageFlowController.start_stage
## và ngược lại StageFlowController.stage_finished -> on_stage_finished (đúng
## pattern BottomNav<->ScreenRouter đã dùng - %Unique không xuyên được ranh
## giới scene con nên không tự gọi thẳng StageFlowController từ đây được).

signal stage_selected(stage: StageData)

const CARD_BG: Color = Color(0.19, 0.22, 0.29, 1)
const CARD_BORDER: Color = Color(0.3, 0.34, 0.43, 1)
const INFO_BOX_BG: Color = Color(0.05, 0.06, 0.09, 0.55)
const INFO_BOX_BORDER: Color = Color(0.25, 0.29, 0.38, 1)
const GOLD: Color = Color(0.95, 0.82, 0.55)
const MUTED: Color = Color(0.56, 0.6, 0.68)
const CTA_BG: Color = Color(0.82, 0.65, 0.28)
const CTA_TEXT: Color = Color(0.13, 0.1, 0.04)
const EMPTY_BORDER: Color = Color(0.4, 0.43, 0.51)

@onready var sub_tab_row: HBoxContainer = %SubTabRow
@onready var conquer_panel: Control = %ConquerPanel
@onready var idle_panel: Control = %IdlePanel
@onready var boss_panel: BossBoardScreen = %BossPanel
@onready var map_list: VBoxContainer = %MapList
@onready var idle_list: VBoxContainer = %IdleList
@onready var create_idle_panel: Control = %CreateIdlePanel
@onready var create_idle_content: VBoxContainer = %CreateIdleContent
@onready var idle_view_panel: Control = %IdleViewPanel
@onready var idle_view_host: Control = %IdleViewHost
@onready var idle_view_back_button: Button = %IdleViewBackButton

func _ready() -> void:
	_build_sub_tab_buttons()
	_build_map_cards()
	_build_idle_list()
	idle_view_back_button.pressed.connect(_close_idle_view)
	boss_panel.stage_selected.connect(stage_selected.emit)

func _build_sub_tab_buttons() -> void:
	var conquer_button := Button.new()
	conquer_button.text = "Ủy Thác"
	conquer_button.pressed.connect(_set_sub_tab.bind("conquer"))
	sub_tab_row.add_child(conquer_button)

	var idle_button := Button.new()
	idle_button.text = "Treo máy"
	idle_button.pressed.connect(_set_sub_tab.bind("idle"))
	sub_tab_row.add_child(idle_button)

	var boss_button := Button.new()
	boss_button.text = "Ải Boss"
	boss_button.pressed.connect(_set_sub_tab.bind("boss"))
	sub_tab_row.add_child(boss_button)

## tab: "conquer" | "idle" | "boss" - đổi từ boolean 2 chiều sang string 3 chiều
## khi gộp thêm Ải Boss (2026-08, xem ghi chú đầu file).
func _set_sub_tab(tab: String) -> void:
	conquer_panel.visible = tab == "conquer"
	idle_panel.visible = tab == "idle"
	boss_panel.visible = tab == "boss"

## ============================== Tab Ủy Thác ==============================

func _build_map_cards() -> void:
	for child in map_list.get_children():
		child.queue_free()
	for i in range(MapDatabase.get_all().size()):
		map_list.add_child(_build_map_card(MapDatabase.get_all()[i], i))

func _build_map_card(map_data: MapData, index: int) -> PanelContainer:
	var card := _styled_panel(CARD_BG, CARD_BORDER, 1, 10)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var number_label := Label.new()
	number_label.text = "MAP %02d" % (index + 1)
	number_label.add_theme_color_override("font_color", MUTED)
	number_label.add_theme_font_size_override("font_size", 10)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(number_label)

	vbox.add_child(_build_map_header(map_data))
	vbox.add_child(_build_info_grid(
		"Điều kiện thắng", map_data.win_condition,
		"Độ khó", map_data.difficulty_label,
	))
	vbox.add_child(_build_row_line("Tầng hiện tại", _floor_display(map_data.id)))

	var cta := Button.new()
	cta.text = "VÀO TRẬN"
	cta.custom_minimum_size = Vector2(0, 40)
	cta.add_theme_color_override("font_color", CTA_TEXT)
	cta.add_theme_stylebox_override("normal", _flat_style(CTA_BG, CTA_BG, 0, 6))
	cta.add_theme_stylebox_override("hover", _flat_style(CTA_BG.lightened(0.1), CTA_BG, 0, 6))
	cta.add_theme_stylebox_override("pressed", _flat_style(CTA_BG.darkened(0.1), CTA_BG, 0, 6))
	cta.pressed.connect(_on_map_card_pressed.bind(map_data.id))
	vbox.add_child(cta)

	return card

func _build_map_header(map_data: MapData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon_badge := _styled_panel(map_data.card_color.lightened(0.1), map_data.card_color.lightened(0.4), 2, 8)
	icon_badge.custom_minimum_size = Vector2(48, 48)
	var icon_label := Label.new()
	icon_label.text = map_data.map_icon
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_badge.add_child(icon_label)
	row.add_child(icon_badge)

	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 2)
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = map_data.map_name
	name_label.add_theme_color_override("font_color", GOLD)
	name_label.add_theme_font_size_override("font_size", 16)
	var type_label := Label.new()
	type_label.text = map_data.map_type
	type_label.add_theme_color_override("font_color", MUTED)
	type_label.add_theme_font_size_override("font_size", 10)
	name_col.add_child(name_label)
	name_col.add_child(type_label)
	row.add_child(name_col)
	return row

func _build_info_grid(label_a: String, value_a: String, label_b: String, value_b: String) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	grid.add_child(_info_box(label_a, value_a))
	grid.add_child(_info_box(label_b, value_b))
	return grid

func _info_box(label_text: String, value_text: String) -> PanelContainer:
	var box := _styled_panel(INFO_BOX_BG, INFO_BOX_BORDER, 1, 5)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8)
	box.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	var label := Label.new()
	label.text = label_text.to_upper()
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 9)
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", Color(0.9, 0.91, 0.93))
	value.add_theme_font_size_override("font_size", 12)
	vbox.add_child(label)
	vbox.add_child(value)
	return box

func _build_row_line(label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 11)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", GOLD)
	value.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	row.add_child(value)
	return row

func _floor_display(map_id: int) -> String:
	var highest := GameState.get_highest_floor(map_id)
	if highest <= 0:
		return "Chưa bắt đầu"
	var floors := StageDatabase.get_floors_for_map(map_id)
	if floors.is_empty():
		return "Tầng %d" % highest
	return "%d / %d" % [highest, floors[-1].floor_number]

## Vào thẳng tầng tiếp theo (highest+1) - không còn bước chọn tầng riêng. Nếu
## đã vượt hết tầng hiện có của map đó (chưa thêm tầng mới), đứng lại ở tầng
## cuối cùng có sẵn để vẫn farm lại được.
func _on_map_card_pressed(map_id: int) -> void:
	var floors := StageDatabase.get_floors_for_map(map_id)
	if floors.is_empty():
		return
	var target_floor: int = mini(GameState.get_highest_floor(map_id) + 1, floors[-1].floor_number)
	var matches: Array = floors.filter(func(s: StageData) -> bool: return s.floor_number == target_floor)
	if matches.is_empty():
		return
	stage_selected.emit(matches[0])

## MainShell gọi lại sau khi StageFlowController.stage_finished bắn ra - vẽ
## lại thẻ map cho đúng tầng cao nhất mới, forward xuống %BossPanel để thẻ Boss
## cũng vẽ lại (trước đây MainShell nối riêng thẳng vào boss_screen).
func on_stage_finished(_stage: StageData, _won: bool) -> void:
	_build_map_cards()
	boss_panel.on_stage_finished(_stage, _won)

## ============================== Tab Treo máy ==============================
## Treo máy TÁCH BIỆT hoàn toàn với Ủy Thác/Boss - 1 nhân vật chỉ không được
## thuộc 2 team treo máy cùng lúc (xem GameState.is_troop_idling), nhưng vẫn
## đánh Ủy Thác/Boss bình thường dù đang treo máy ở đâu. Ủy Thác chỉ có vai
## trò MỞ KHOÁ tầng cao hơn để treo (xem GameState.get_highest_floor).
##
## CHỈ 1 team tại 1 thời điểm (GameState.has_idle_team(), không phải Array
## nữa) - thẻ "+" chỉ hiện khi CHƯA có team nào, có rồi thì hiện đúng 1 thẻ. Không
## còn công thức/chu kỳ gì để hiển thị - vàng/EXP cộng thẳng vào GameState
## ngay lúc quái chết thật trong trận nền (xem StageFarmWorld), số dư chỉ cần
## nhìn thanh Vàng ở top bar hoặc mở "XEM" ra coi trực tiếp.

var _create_map_id: int = -1
var _create_floor: int = 1
var _create_selected: Array[int] = []

func _build_idle_list() -> void:
	for child in idle_list.get_children():
		child.queue_free()
	if GameState.has_idle_team():
		idle_list.add_child(_build_idle_team_card())
	else:
		idle_list.add_child(_build_empty_idle_card())

func _build_idle_team_card() -> PanelContainer:
	var farm_map: StageFarmMap = GameState.get_idle_farm_map()
	var stage: StageData = farm_map.get_stage()
	var member_troop_ids: Array[int] = farm_map.get_member_troop_ids()
	var map_data: MapData = MapDatabase.get_by_id(stage.map_id) if stage != null else null

	var card := _styled_panel(CARD_BG, CARD_BORDER, 1, 10)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	if map_data != null:
		var icon_badge := _styled_panel(map_data.card_color.lightened(0.1), map_data.card_color.lightened(0.4), 2, 8)
		icon_badge.custom_minimum_size = Vector2(40, 40)
		var icon_label := Label.new()
		icon_label.text = map_data.map_icon
		icon_label.add_theme_font_size_override("font_size", 18)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_badge.add_child(icon_label)
		header.add_child(icon_badge)

	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 2)
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = "%s - Tầng %d" % [map_data.map_name if map_data != null else "?", stage.floor_number if stage != null else 0]
	name_label.add_theme_color_override("font_color", GOLD)
	name_label.add_theme_font_size_override("font_size", 14)
	var member_names: PackedStringArray = []
	for troop_id in member_troop_ids:
		var troop: LinhData = TroopDatabase.get_by_id(troop_id)
		if troop != null:
			member_names.append(troop.troop_name)
	var member_label := Label.new()
	member_label.text = "Đội: %s" % ", ".join(member_names)
	member_label.add_theme_color_override("font_color", MUTED)
	member_label.add_theme_font_size_override("font_size", 10)
	name_col.add_child(name_label)
	name_col.add_child(member_label)
	header.add_child(name_col)
	vbox.add_child(header)

	var note := Label.new()
	note.text = "Đang farm thật - vàng/EXP cộng ngay khi hạ được quái, xem trực tiếp bằng nút XEM. Chỉ tính khi app đang mở."
	note.add_theme_color_override("font_color", MUTED)
	note.add_theme_font_size_override("font_size", 9)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(note)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)

	var watch_button := Button.new()
	watch_button.text = "XEM"
	watch_button.custom_minimum_size = Vector2(0, 36)
	watch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	watch_button.add_theme_color_override("font_color", GOLD)
	watch_button.add_theme_stylebox_override("normal", _flat_style(Color(0.16, 0.18, 0.22), CARD_BORDER, 1, 6))
	watch_button.pressed.connect(_open_idle_view)
	button_row.add_child(watch_button)

	var recall_button := Button.new()
	recall_button.text = "RÚT VỀ"
	recall_button.custom_minimum_size = Vector2(0, 36)
	recall_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recall_button.add_theme_color_override("font_color", Color(0.85, 0.6, 0.6))
	recall_button.add_theme_stylebox_override("normal", _flat_style(Color(0.16, 0.18, 0.22), EMPTY_BORDER, 1, 6))
	recall_button.pressed.connect(_on_recall_pressed)
	button_row.add_child(recall_button)

	vbox.add_child(button_row)

	return card

func _on_recall_pressed() -> void:
	GameState.stop_idle_team()
	_build_idle_list()

## ============================== Màn "Xem treo máy" ==============================
## KHÔNG tạo bản mới - nhúng (reparent) đúng instance GameState đang giữ sống
## vào idle_view_host để nhìn, simulation vẫn chạy y hệt lúc không xem. Đóng
## lại thì reparent VỀ lại GameState (KHÔNG queue_free - phải tiếp tục chạy).

func _open_idle_view() -> void:
	var farm_map: StageFarmMap = GameState.get_idle_farm_map()
	if farm_map == null:
		return
	farm_map.reparent(idle_view_host, false)
	farm_map.set_anchors_preset(Control.PRESET_FULL_RECT)

	sub_tab_row.visible = false
	conquer_panel.visible = false
	idle_panel.visible = false
	boss_panel.visible = false
	idle_view_panel.visible = true

func _close_idle_view() -> void:
	var farm_map: StageFarmMap = GameState.get_idle_farm_map()
	if farm_map != null:
		farm_map.reparent(GameState, false) ## về lại "nhà" ẩn, simulation vẫn tiếp tục chạy nền
	idle_view_panel.visible = false
	sub_tab_row.visible = true
	_set_sub_tab("idle")
	_build_idle_list()

func _build_empty_idle_card() -> PanelContainer:
	var card := _styled_panel(Color(0.14, 0.16, 0.21, 0.6), EMPTY_BORDER, 1, 10)
	card.custom_minimum_size = Vector2(0, 150)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)

	var plus_badge := _styled_panel(Color(0, 0, 0, 0), EMPTY_BORDER, 2, 26)
	plus_badge.custom_minimum_size = Vector2(52, 52)
	var plus_label := Label.new()
	plus_label.text = "+"
	plus_label.add_theme_font_size_override("font_size", 28)
	plus_label.add_theme_color_override("font_color", MUTED)
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus_badge.add_child(plus_label)

	var title := Label.new()
	title.text = "Thêm đội hình treo"
	title.add_theme_color_override("font_color", Color(0.82, 0.84, 0.87))
	title.add_theme_font_size_override("font_size", 13)
	var subtitle := Label.new()
	subtitle.text = "Chọn map và tầng để bắt đầu"
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.add_theme_font_size_override("font_size", 10)

	vbox.add_child(plus_badge)
	vbox.add_child(title)
	vbox.add_child(subtitle)
	center.add_child(vbox)

	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_open_create_idle)
	card.add_child(button)

	return card

## ============================== Màn "Tạo đội treo" ==============================

func _open_create_idle() -> void:
	if GameState.has_idle_team():
		return ## đã có 1 team đang treo - phải rút về trước (nút "+" không hiện trong trường hợp này, đây chỉ là chốt an toàn)
	var maps := MapDatabase.get_all()
	if maps.is_empty():
		return
	_create_map_id = maps[0].id
	_create_floor = 1
	_create_selected.clear()
	sub_tab_row.visible = false
	conquer_panel.visible = false
	idle_panel.visible = false
	boss_panel.visible = false
	create_idle_panel.visible = true
	_build_create_idle_content()

func _close_create_idle() -> void:
	create_idle_panel.visible = false
	sub_tab_row.visible = true
	_set_sub_tab("idle")
	_build_idle_list()

func _max_idle_floor(map_id: int) -> int:
	return maxi(1, GameState.get_highest_floor(map_id))

func _build_create_idle_content() -> void:
	for child in create_idle_content.get_children():
		child.queue_free()

	var header := HBoxContainer.new()
	var back_button := Button.new()
	back_button.text = "←"
	back_button.custom_minimum_size = Vector2(36, 36)
	back_button.pressed.connect(_close_create_idle)
	var title := Label.new()
	title.text = "TẠO ĐỘI TREO"
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_size_override("font_size", 15)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(36, 0)
	header.add_child(back_button)
	header.add_child(title)
	header.add_child(spacer)
	create_idle_content.add_child(header)

	create_idle_content.add_child(_section_label("BẢN ĐỒ"))
	var map_option := OptionButton.new()
	for map_data in MapDatabase.get_all():
		map_option.add_item("%s %s" % [map_data.map_icon, map_data.map_name], map_data.id)
	var current_index := 0
	for i in range(map_option.item_count):
		if map_option.get_item_id(i) == _create_map_id:
			current_index = i
			break
	map_option.select(current_index)
	map_option.item_selected.connect(_on_create_map_selected.bind(map_option))
	create_idle_content.add_child(map_option)

	create_idle_content.add_child(_section_label("TẦNG (tối đa tầng đã thắng tay)"))
	var stepper := HBoxContainer.new()
	stepper.alignment = BoxContainer.ALIGNMENT_CENTER
	stepper.add_theme_constant_override("separation", 16)
	var minus_button := Button.new()
	minus_button.text = "−"
	minus_button.custom_minimum_size = Vector2(36, 36)
	minus_button.pressed.connect(_on_change_create_floor.bind(-1))
	var floor_label := Label.new()
	floor_label.name = "FloorValueLabel"
	floor_label.text = "Tầng %d / %d" % [_create_floor, _max_idle_floor(_create_map_id)]
	floor_label.add_theme_color_override("font_color", Color(0.9, 0.91, 0.93))
	floor_label.add_theme_font_size_override("font_size", 14)
	var plus_button := Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(36, 36)
	plus_button.pressed.connect(_on_change_create_floor.bind(1))
	stepper.add_child(minus_button)
	stepper.add_child(floor_label)
	stepper.add_child(plus_button)
	create_idle_content.add_child(stepper)

	create_idle_content.add_child(_section_label("ĐỘI HÌNH (chọn 1-4, không trùng người đang treo team khác)"))
	var member_row := HBoxContainer.new()
	member_row.add_theme_constant_override("separation", 8)
	for troop_id in GameState.PARTY_TROOP_IDS:
		var troop: LinhData = TroopDatabase.get_by_id(troop_id)
		if troop == null:
			continue
		var busy: bool = GameState.is_troop_idling(troop_id)
		var button := Button.new()
		button.text = troop.troop_name + ("\n(đang treo)" if busy else "")
		button.toggle_mode = true
		button.disabled = busy
		button.button_pressed = troop_id in _create_selected
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_on_toggle_member.bind(troop_id))
		member_row.add_child(button)
	create_idle_content.add_child(member_row)

	var start_button := Button.new()
	start_button.text = "BẮT ĐẦU TREO"
	start_button.custom_minimum_size = Vector2(0, 40)
	start_button.disabled = _create_selected.is_empty()
	start_button.add_theme_color_override("font_color", CTA_TEXT)
	start_button.add_theme_stylebox_override("normal", _flat_style(CTA_BG, CTA_BG, 0, 6))
	start_button.add_theme_stylebox_override("disabled", _flat_style(CTA_BG.darkened(0.4), CTA_BG.darkened(0.4), 0, 6))
	start_button.pressed.connect(_on_start_idle_pressed)
	create_idle_content.add_child(start_button)

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 10)
	return label

func _on_create_map_selected(index: int, map_option: OptionButton) -> void:
	_create_map_id = map_option.get_item_id(index)
	_create_floor = 1
	_build_create_idle_content()

func _on_change_create_floor(delta: int) -> void:
	_create_floor = clampi(_create_floor + delta, 1, _max_idle_floor(_create_map_id))
	_build_create_idle_content()

func _on_toggle_member(troop_id: int) -> void:
	if troop_id in _create_selected:
		_create_selected.erase(troop_id)
	elif _create_selected.size() < 4:
		_create_selected.append(troop_id)
	_build_create_idle_content()

func _on_start_idle_pressed() -> void:
	var floors := StageDatabase.get_floors_for_map(_create_map_id)
	var matches: Array = floors.filter(func(s: StageData) -> bool: return s.floor_number == _create_floor)
	if matches.is_empty() or _create_selected.is_empty():
		return
	var stage: StageData = matches[0]
	var members: Array[int] = []
	members.append_array(_create_selected)
	if not GameState.start_idle_team(stage.id, members):
		return
	_close_create_idle()

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
