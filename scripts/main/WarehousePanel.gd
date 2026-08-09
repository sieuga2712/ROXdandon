class_name WarehousePanel
extends Control

## Panel "Quản Lý Kho" - lưới 10x10, 2 trang (PAGE_COUNT*COLS*ROWS = 200 ô
## chứa) hiện toàn bộ MaterialDatabase (hiện có 50 nguyên liệu, đủ trọn trang
## 1 - trang 2 còn trống, chừa chỗ cho nguyên liệu thêm sau này, xem yêu cầu
## "hiện cứ để kho hàng 10x10, 2 trang kho"). Số lượng lấy thẳng từ
## GameState.materials - CHƯA có nguồn thu thập thật nào gán vào đó (chưa có
## item drop khi đánh quái), nên phần lớn sẽ hiện đếm 0 cho tới khi có tính
## năng đó. Ô có count = 0 hiện mờ đi để phân biệt với ô đã có.

const COLS: int = 10
const ROWS: int = 10
const PER_PAGE: int = COLS * ROWS
const PAGE_COUNT: int = 2
const SLOT_SIZE: int = 56

const BG: Color = Color(0.08, 0.09, 0.12, 0.95)
const CARD_BG: Color = Color(0.16, 0.18, 0.22)
const CARD_BORDER: Color = Color(0.4, 0.44, 0.53)
const SLOT_BG: Color = Color(0.13, 0.15, 0.19)
const SLOT_BORDER: Color = Color(0.3, 0.34, 0.43)
const GOLD: Color = Color(0.85, 0.7, 0.3)

var _page: int = 0
var _grid: GridContainer
var _page_label: Label

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UIBuilders.inset_for_top_bottom_bars(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()

func open() -> void:
	_page = 0
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
	## app: Header (tên + nút quay lại/đóng, cố định trên) - Center (lưới kho,
	## co giãn lấp đầy phần giữa) - Footer (điều hướng trang, cố định dưới).
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	## Header
	vbox.add_child(UIBuilders.panel_header("KHO NGUYÊN LIỆU", GOLD, func() -> void: visible = false))

	## Center
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(_grid)

	## Footer
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 16)
	var prev_button := Button.new()
	prev_button.text = "◀"
	prev_button.custom_minimum_size = Vector2(44, 36)
	prev_button.pressed.connect(_on_prev_pressed)
	footer.add_child(prev_button)
	_page_label = Label.new()
	_page_label.custom_minimum_size = Vector2(90, 0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(_page_label)
	var next_button := Button.new()
	next_button.text = "▶"
	next_button.custom_minimum_size = Vector2(44, 36)
	next_button.pressed.connect(_on_next_pressed)
	footer.add_child(next_button)
	vbox.add_child(footer)

func _on_prev_pressed() -> void:
	_page = wrapi(_page - 1, 0, PAGE_COUNT)
	_refresh()

func _on_next_pressed() -> void:
	_page = wrapi(_page + 1, 0, PAGE_COUNT)
	_refresh()

func _refresh() -> void:
	_page_label.text = "Trang %d/%d" % [_page + 1, PAGE_COUNT]
	for child in _grid.get_children():
		child.queue_free()
	var all_materials: Array[MaterialData] = MaterialDatabase.get_all()
	var start := _page * PER_PAGE
	for i in range(PER_PAGE):
		var idx := start + i
		if idx < all_materials.size():
			_grid.add_child(_build_slot(all_materials[idx]))
		else:
			_grid.add_child(_build_empty_slot())

func _build_slot(mat: MaterialData) -> PanelContainer:
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

	var icon := UIBuilders.texture_icon(mat.icon, SLOT_SIZE - 12)
	icon.modulate.a = 1.0 if count > 0 else 0.35
	slot.add_child(icon)

	if count > 0:
		var count_label := Label.new()
		count_label.text = str(count)
		count_label.add_theme_font_size_override("font_size", 11)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		slot.add_child(count_label)

	return slot

func _build_empty_slot() -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.11, 0.14)
	style.border_color = Color(0.2, 0.22, 0.26)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	slot.add_theme_stylebox_override("panel", style)
	return slot
