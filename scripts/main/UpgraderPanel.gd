class_name UpgraderPanel
extends Control

## Panel "Thợ Nâng Cấp" - 2 trang theo category ("quang"/"gem", xem
## MaterialDatabase.GROUPS), mỗi trang liệt kê 3 loại của category đó, mỗi
## loại hiện đủ 5 cấp kèm số lượng đang có + nút "▶" ghép GameState.MERGE_COST
## (5) nguyên liệu cấp N thành 1 nguyên liệu cấp N+1 cùng loại (xem
## GameState.merge_material_up). Nút ghép tự khoá khi không đủ số lượng hoặc
## đã ở cấp tối đa.

const CATEGORIES: Array[String] = ["quang", "gem"]
const CATEGORY_LABEL: Dictionary = {"quang": "Quặng", "gem": "Gem"}

const BG: Color = Color(0.08, 0.09, 0.12, 0.95)
const CARD_BG: Color = Color(0.16, 0.18, 0.22)
const CARD_BORDER: Color = Color(0.4, 0.44, 0.53)
const SLOT_BG: Color = Color(0.13, 0.15, 0.19)
const SLOT_BORDER: Color = Color(0.3, 0.34, 0.43)
const GOLD: Color = Color(0.85, 0.7, 0.3)
const MUTED: Color = Color(0.65, 0.68, 0.73)
const SLOT_SIZE: int = 44

var _category_index: int = 0
var _tab_buttons: Array[Button] = []
var _content_vbox: VBoxContainer

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UIBuilders.inset_for_top_bottom_bars(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func open() -> void:
	_category_index = 0
	_refresh()
	visible = true

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		outer_margin.add_theme_constant_override("margin_%s" % side, 20)
	add_child(outer_margin)

	var card := UIBuilders.bordered_card(CARD_BG, CARD_BORDER)
	outer_margin.add_child(card)

	## 3 vùng rõ ràng, giống đúng bố cục TopStatusBar/nội dung/BottomNav của cả
	## app: Header (tên + nút quay lại/đóng, cố định trên) - Center (danh sách
	## nguyên liệu theo loại, co giãn lấp đầy phần giữa) - Footer (2 tab
	## Quặng/Gem, cố định dưới, giống hệt vị trí BottomNav của cả app).
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	## Header
	vbox.add_child(UIBuilders.panel_header("THỢ NÂNG CẤP", GOLD, func() -> void: visible = false))

	## Center
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 16)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content_vbox)

	## Footer
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	for i in range(CATEGORIES.size()):
		var btn := Button.new()
		btn.text = CATEGORY_LABEL[CATEGORIES[i]]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_tab_pressed.bind(i))
		footer.add_child(btn)
		_tab_buttons.append(btn)
	vbox.add_child(footer)

func _on_tab_pressed(index: int) -> void:
	_category_index = index
	_refresh()

func _refresh() -> void:
	for i in range(_tab_buttons.size()):
		_tab_buttons[i].button_pressed = i == _category_index
	for child in _content_vbox.get_children():
		child.queue_free()

	var category: String = CATEGORIES[_category_index]
	for group_key in MaterialDatabase.get_group_keys(category):
		_content_vbox.add_child(_build_group_row(group_key))

func _build_group_row(group_key: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var group_name := MaterialDatabase.get_by_id(MaterialDatabase.make_id(group_key, 1)).group_name
	var name_label := Label.new()
	name_label.text = group_name
	name_label.add_theme_color_override("font_color", MUTED)
	name_label.add_theme_font_size_override("font_size", 13)
	box.add_child(name_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for tier in range(1, MaterialDatabase.MAX_TIER + 1):
		row.add_child(_build_tier_slot(group_key, tier))
		if tier < MaterialDatabase.MAX_TIER:
			row.add_child(_build_merge_button(group_key, tier))
	box.add_child(row)
	return box

func _build_tier_slot(group_key: String, tier: int) -> PanelContainer:
	var mat := MaterialDatabase.get_by_id(MaterialDatabase.make_id(group_key, tier))
	var count := GameState.get_material_count(mat.id)

	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.border_color = SLOT_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	slot.add_theme_stylebox_override("panel", style)
	slot.tooltip_text = "%s\nSố lượng: %d" % [mat.display_name, count]

	var icon := UIBuilders.texture_icon(mat.icon, SLOT_SIZE - 10)
	icon.modulate.a = 1.0 if count > 0 else 0.35
	slot.add_child(icon)

	var count_label := Label.new()
	count_label.text = str(count)
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 3)
	count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	slot.add_child(count_label)

	return slot

func _build_merge_button(group_key: String, tier: int) -> Button:
	var from_id := MaterialDatabase.make_id(group_key, tier)
	var have := GameState.get_material_count(from_id)
	var btn := Button.new()
	btn.text = "▶"
	btn.custom_minimum_size = Vector2(32, SLOT_SIZE)
	btn.tooltip_text = "Ghép %d cấp %d → 1 cấp %d" % [GameState.MERGE_COST, tier, tier + 1]
	btn.disabled = have < GameState.MERGE_COST
	btn.pressed.connect(_on_merge_pressed.bind(group_key, tier))
	return btn

func _on_merge_pressed(group_key: String, tier: int) -> void:
	if GameState.merge_material_up(group_key, tier):
		_refresh()
