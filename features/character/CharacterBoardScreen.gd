class_name CharacterBoardScreen
extends Control

## Tab "Nhân vật" - danh sách + chi tiết CHỈ 4 thành viên party thật
## (GameState.PARTY_TROOP_IDS), không phải 1 bộ sưu tập gacha nhiều nhân vật -
## đúng thiết kế "PvE 4 nhân vật cố định" của game (xem project.godot mô tả).
## HP/ATK/DEF/M.DEF hiển thị là CHỈ SỐ HIỆU DỤNG thật đang dùng trong trận
## (đã cộng bonus theo Base Lv/Job Lv - xem GameState.effective_*); Base
## Lv/Job Lv + thanh EXP cũng là số THẬT (xem GameState.get_base_level_info/
## get_job_level_info) - giết quái (đánh tay hay treo máy) cộng EXP thật cho
## cả team, xem BattleScene._apply_damage/StageFarmWorld._apply_damage. Chỉ ô
## trang bị vẫn TƯỢNG TRƯNG (chưa có hệ trang bị/item thật - xem ghi chú cuối
## _build_detail()).
##
## Vai trò (TANK/DPS/SUPPORT) hiển thị trên thẻ chỉ là NHÃN suy ra từ
## character_key/troop_type để dễ đọc (_role_of) - không phải 1 field dữ liệu
## thật, không dùng để tính toán gì trong trận đấu.

const CARD_BG: Color = Color(0.19, 0.22, 0.29, 1)
const CARD_BORDER: Color = Color(0.3, 0.34, 0.43, 1)
const GOLD: Color = Color(0.95, 0.82, 0.55)
const MUTED: Color = Color(0.56, 0.6, 0.68)
const TEXT: Color = Color(0.9, 0.91, 0.93)

const ROLE_FILTERS: Array[Dictionary] = [
	{"id": "all", "label": "Tất cả"},
	{"id": "tank", "label": "🛡 Tank"},
	{"id": "dps", "label": "⚔ DPS"},
	{"id": "support", "label": "✨ Support"},
]

@onready var list_panel: Control = %CharacterListPanel
@onready var detail_panel: Control = %CharacterDetailPanel
@onready var search_edit: LineEdit = %CharacterSearchEdit
@onready var filter_row: HBoxContainer = %CharacterFilterRow
@onready var character_list: VBoxContainer = %CharacterList
@onready var detail_content: VBoxContainer = %CharacterDetailContent
@onready var back_button: Button = %CharacterBackButton

var _search_text: String = ""
var _filter_id: String = "all"

func _ready() -> void:
	search_edit.text_changed.connect(_on_search_changed)
	back_button.pressed.connect(close_detail)
	_build_filter_buttons()
	_build_list()

## ============================== Danh sách ==============================

func _build_filter_buttons() -> void:
	for child in filter_row.get_children():
		child.queue_free()
	for filter_data in ROLE_FILTERS:
		var button := Button.new()
		button.text = filter_data.label
		button.toggle_mode = true
		button.button_pressed = filter_data.id == _filter_id
		button.pressed.connect(_on_filter_pressed.bind(filter_data.id))
		filter_row.add_child(button)

func _on_filter_pressed(filter_id: String) -> void:
	_filter_id = filter_id
	_build_filter_buttons()
	_build_list()

func _on_search_changed(text: String) -> void:
	_search_text = text.to_lower()
	_build_list()

func _party_troops() -> Array[LinhData]:
	var troops: Array[LinhData] = []
	for troop_id in GameState.PARTY_TROOP_IDS:
		var troop := TroopDatabase.get_by_id(troop_id)
		if troop != null:
			troops.append(troop)
	return troops

func _role_of(troop: LinhData) -> String:
	if troop.character_key == "priest":
		return "support"
	if troop.troop_type == Enums.TroopType.ARCHER:
		return "dps"
	return "tank"

const ROLE_LABELS: Dictionary = {"tank": "TANK", "dps": "DPS", "support": "SUPPORT"}

func _build_list() -> void:
	for child in character_list.get_children():
		child.queue_free()
	for troop in _party_troops():
		var role := _role_of(troop)
		if _filter_id != "all" and role != _filter_id:
			continue
		if not _search_text.is_empty() and not troop.troop_name.to_lower().contains(_search_text):
			continue
		character_list.add_child(_build_character_card(troop, role))

func _build_character_card(troop: LinhData, role: String) -> PanelContainer:
	var card := _styled_panel(CARD_BG, CARD_BORDER, 1, 10)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 12)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	row.add_child(_portrait(troop, 52))

	var info_col := VBoxContainer.new()
	info_col.add_theme_constant_override("separation", 3)
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = "%s  ·  Lv.%d" % [troop.troop_name, GameState.get_base_level(troop.id)]
	name_label.add_theme_color_override("font_color", GOLD)
	name_label.add_theme_font_size_override("font_size", 14)
	info_col.add_child(name_label)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 10)
	stats_row.add_child(_mini_stat("❤️", str(roundi(GameState.effective_hp(troop.id, troop.hp)))))
	stats_row.add_child(_mini_stat("⚔", str(roundi(GameState.effective_atk(troop.id, troop.atk)))))
	stats_row.add_child(_mini_stat("🛡", str(roundi(GameState.effective_def(troop.id, troop.def)))))
	info_col.add_child(stats_row)
	row.add_child(info_col)

	var role_badge := Label.new()
	role_badge.text = ROLE_LABELS[role]
	role_badge.add_theme_color_override("font_color", MUTED)
	role_badge.add_theme_font_size_override("font_size", 9)
	row.add_child(role_badge)

	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_open_detail.bind(troop, role))
	card.add_child(button)

	return card

func _mini_stat(icon: String, value: String) -> Label:
	var label := Label.new()
	label.text = "%s %s" % [icon, value]
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 10)
	return label

func _portrait(troop: LinhData, size: int) -> PanelContainer:
	var badge := _styled_panel(Color(0.24, 0.26, 0.32), Color(0.4, 0.43, 0.51), 1, 8)
	badge.custom_minimum_size = Vector2(size, size)
	if troop.sprite != null:
		var texture := TextureRect.new()
		texture.texture = troop.sprite
		texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge.add_child(texture)
	return badge

## Icon dùng ký tự hình học đơn sắc (◆○⬡▲■▼◇●◈) thay vì emoji màu (⚔️💍📿... cũ)
## - emoji có bảng màu riêng theo từng ký tự, không đổi màu qua font_color
## được; ký tự hình học thì render đơn sắc, ăn đúng 1 màu MUTED áp chung cho
## cả 11 ô, đúng ý "siêu tối giản chung màu" thay vì mỗi ô 1 màu emoji khác nhau.
func _equipment_slot(icon: String) -> PanelContainer:
	var slot := _styled_panel(Color(0.24, 0.26, 0.32), Color(0.35, 0.38, 0.46), 1, 6)
	slot.custom_minimum_size = Vector2(44, 44)
	var label := Label.new()
	label.text = icon
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", MUTED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.add_child(label)
	return slot

## ============================== Chi tiết ==============================

func _open_detail(troop: LinhData, role: String) -> void:
	_build_detail(troop, role)
	list_panel.visible = false
	detail_panel.visible = true

func close_detail() -> void:
	detail_panel.visible = false
	list_panel.visible = true

const EQUIP_SLOTS_LEFT: Array[String] = ["◆", "○", "⬡", "▲"] ## vũ khí/nhẫn/bùa/nón
const EQUIP_SLOTS_RIGHT: Array[String] = ["■", "▼", "◇", "●"] ## khiên/giày/găng/đá quý
const EQUIP_SLOTS_BOTTOM: Array[String] = ["◈", "◈", "◈"]

func _build_detail(troop: LinhData, role: String) -> void:
	for child in detail_content.get_children():
		child.queue_free()

	## Ô trang bị TƯỢNG TRƯNG - chưa có hệ trang bị thật (chưa có item/backend
	## gì đứng sau), chỉ dựng hình cho đủ khung như mockup, không bấm được gì.
	var equip_row := HBoxContainer.new()
	equip_row.alignment = BoxContainer.ALIGNMENT_CENTER
	equip_row.add_theme_constant_override("separation", 10)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	for icon in EQUIP_SLOTS_LEFT:
		left_col.add_child(_equipment_slot(icon))
	equip_row.add_child(left_col)

	var portrait_center := CenterContainer.new()
	portrait_center.add_child(_portrait(troop, 140))
	equip_row.add_child(portrait_center)

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	for icon in EQUIP_SLOTS_RIGHT:
		right_col.add_child(_equipment_slot(icon))
	equip_row.add_child(right_col)

	detail_content.add_child(equip_row)

	var name_label := Label.new()
	name_label.text = troop.troop_name
	name_label.add_theme_color_override("font_color", GOLD)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_content.add_child(name_label)

	var sub_label := Label.new()
	sub_label.text = "%s · %s · Kỹ năng: %s" % [
		ROLE_LABELS[role],
		"Cận chiến" if troop.troop_type == Enums.TroopType.NORMAL else "Đánh xa",
		troop.skill_name,
	]
	sub_label.add_theme_color_override("font_color", MUTED)
	sub_label.add_theme_font_size_override("font_size", 11)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_content.add_child(sub_label)

	var bottom_slots := HBoxContainer.new()
	bottom_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_slots.add_theme_constant_override("separation", 8)
	for icon in EQUIP_SLOTS_BOTTOM:
		bottom_slots.add_child(_equipment_slot(icon))
	detail_content.add_child(bottom_slots)

	var base_info := GameState.get_base_level_info(troop.id)
	var job_info := GameState.get_job_level_info(troop.id)

	var exp_panel := _styled_panel(CARD_BG, CARD_BORDER, 1, 8)
	var exp_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		exp_margin.add_theme_constant_override("margin_%s" % side, 12)
	exp_panel.add_child(exp_margin)
	var exp_vbox := VBoxContainer.new()
	exp_vbox.add_theme_constant_override("separation", 8)
	exp_margin.add_child(exp_vbox)
	exp_vbox.add_child(_build_exp_row("🧬 Base", base_info.level, base_info.exp_into_level, base_info.exp_required))
	exp_vbox.add_child(_build_exp_row("🎖 Job (First Job)", job_info.level, job_info.exp_into_level, job_info.exp_required))
	detail_content.add_child(exp_panel)

	var stats_panel := _styled_panel(CARD_BG, CARD_BORDER, 1, 8)
	var stats_margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		stats_margin.add_theme_constant_override("margin_%s" % side, 12)
	stats_panel.add_child(stats_margin)
	var stats_grid := GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 16)
	stats_grid.add_theme_constant_override("v_separation", 7)
	stats_margin.add_child(stats_grid)

	var damage_type_text: String = "Vật lý" if troop.damage_type == Enums.DamageType.PHYSICAL else "Phép"
	var rows: Array = [
		["❤️ HP", str(roundi(GameState.effective_hp(troop.id, troop.hp)))],
		["⚔ ATK", str(roundi(GameState.effective_atk(troop.id, troop.atk)))],
		["🛡 DEF", str(roundi(GameState.effective_def(troop.id, troop.def)))],
		["✨ M.DEF", str(roundi(GameState.effective_m_def(troop.id, troop.m_def)))],
		["🗡 Hệ sát thương", damage_type_text],
		["⚡ Tốc đánh", "%.1f đòn/s" % (troop.atk_speed * 0.1)],
		["🏃 Tốc di chuyển", str(troop.move_speed)],
		["🎯 Chí mạng", "%d%%" % roundi(troop.crit_rate * 100)],
		["💥 ST chí mạng", "%d%%" % roundi(troop.crit_damage * 100)],
		["🩶 Xuyên giáp", "%d%%" % roundi(troop.armor_penetration)],
		["🩸 Hút máu", "%d%%" % roundi(troop.life_steal * 100)],
		["💚 Hồi máu", "%s/5s" % str(troop.regen_hp)],
	]
	for entry in rows:
		stats_grid.add_child(_stat_label(entry[0], MUTED, 10))
		stats_grid.add_child(_stat_label(entry[1], TEXT, 11))

	detail_content.add_child(stats_panel)

	var note := Label.new()
	note.text = "(Base Lv/Job Lv/EXP là số THẬT - giết quái (đánh tay hay treo máy) cộng EXP cho cả team. Base Lv +10%/cấp cho HP/ATK/DEF/M.DEF, Job Lv +1 ATK/cấp, đã cộng vào chỉ số bên dưới. Ô trang bị vẫn TƯỢNG TRƯNG - chưa có hệ trang bị/item thật.)"
	note.add_theme_color_override("font_color", MUTED)
	note.add_theme_font_size_override("font_size", 9)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	detail_content.add_child(note)

func _build_exp_row(label_prefix: String, level: int, exp_into_level: int, exp_required: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	var is_max: bool = exp_required < 0

	var header := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = "%s Lv.%d" % [label_prefix, level]
	name_label.add_theme_color_override("font_color", TEXT)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value_label := Label.new()
	value_label.text = "MAX" if is_max else "%s / %s EXP" % [_format_int(exp_into_level), _format_int(exp_required)]
	value_label.add_theme_color_override("font_color", MUTED)
	value_label.add_theme_font_size_override("font_size", 10)
	header.add_child(name_label)
	header.add_child(value_label)
	col.add_child(header)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 1 if is_max else exp_required
	bar.value = 1 if is_max else exp_into_level
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	col.add_child(bar)
	return col

func _format_int(value: int) -> String:
	var digits := str(value)
	var result := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		result = digits[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	return result

func _stat_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

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
