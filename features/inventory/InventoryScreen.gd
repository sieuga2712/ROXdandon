class_name InventoryScreen
extends Control

## Tab "Kho" (`inventory`) - lấy ĐÚNG giao diện "Kho báu"
## (features/city/WarehousePanel.gd: khung thẻ bo viền + ô nguyên liệu) nhưng
## KHÔNG dùng chung class (2 feature không được gọi thẳng nhau, xem README
## module này). Nâng cấp theo đề xuất "de_xuat_cai_thien_kho_do" (phạm vi P0
## ĐÃ CHỐT với người dùng - chỉ làm đúng phần khớp dữ liệu thật đang có):
## 1. CHỈ hiện món đã có (count > 0), không hiện đủ 50 ô trống/mờ.
## 2. Cố định 8 cột/hàng, SLOT_SIZE+gap tính sẵn bằng tay = GRID_WIDTH (442px)
##    - ép thẳng vào custom_minimum_size.x của _grid nên KHÔNG co nhỏ lại dù
##    tổng số món < 8 (hành vi mặc định của GridContainer), rồi canh giữa cả
##    khối 442px này trong card qua _scroll.size_flags_horizontal - xem ghi
##    chú tại _build_ui(). Không cần ô filler nào, hàng cuối thiếu ô cứ để
##    trống bên phải của grid 442px, đúng kiểu túi đồ mobile đơn giản.
## 3. Icon cỡ theo ĐÚNG tỉ lệ "Kho báu" gốc (slot - 14) - số lượng lùi vào
##    trong khỏi viền ô (COUNT_INSET), đặt trong 1 Control THƯỜNG (overlay,
##    không phải Container) lồng bên trong slot - PanelContainer ép lại
##    offset của MỌI con TRỰC TIẾP mỗi lần sort_children (kể cả offset đã set
##    tay), đây mới là lý do thật sự bản "Kho báu" gốc bị số dán sát viền.
## 4. 2 tab "Tất cả"/"Nguyên liệu" - CHỈ 2 tab vì hiện tại toàn bộ vật phẩm
##    trong game ĐỀU là nguyên liệu (chưa có Trang bị/Tiêu hao/Khác) - không
##    thêm tab chết cho loại chưa tồn tại, xem _matches_tab().
## 5. Viền ô + icon lớn trong popup chi tiết đổi màu theo TIER_BORDER_COLORS
##    (suy ra từ MaterialData.tier 1-5) - KHÔNG phải field "rarity" riêng
##    (chưa có trong dữ liệu thật, tier là thứ gần nhất đang có).
## 6. Bấm vào 1 ô mở popup chi tiết (icon lớn/tên/cấp/số lượng/mô tả ngắn +
##    nút "Ghép lên cấp kế" gọi thẳng GameState.merge_material_up - đúng hành
##    động DUY NHẤT có thật cho 1 nguyên liệu, không bịa thêm "Sử dụng" nào
##    khác) thay vì chỉ có tooltip như bản trước.
##
## Vật phẩm rơi ra khi hạ quái (70%/quái, luôn cấp 1 - xem
## MaterialDatabase.random_tier1_id, gọi từ features/stage/StageFarmWorld và
## features/combat/BattleScene) là nguồn thu thập DUY NHẤT hiện có - popup chi
## tiết KHÔNG ghi "nhận từ quái nào" vì mọi quái đều rơi ngẫu nhiên đều 10
## nhóm, không có quái nào gắn riêng với 1 nguyên liệu cụ thể.

const COLS: int = 8
const SLOT_SIZE: int = 50 ## vừa khít trong ~452px còn lại (540 - margin/viền/thanh cuộn dọc)
const ROW_GAP: int = 6
const GRID_WIDTH: float = COLS * SLOT_SIZE + (COLS - 1) * ROW_GAP ## = 442 - bề rộng CỐ ĐỊNH của grid bất kể có bao nhiêu món (ép qua custom_minimum_size.x ở _build_ui() - không để GridContainer tự co theo hàng dài nhất, xem ghi chú ở đó)
const MAX_VISIBLE_ROWS: int = 6 ## quá số hàng này mới thật sự cuộn - tránh card cao vô hạn nếu có rất nhiều loại nguyên liệu
const ICON_SIZE: int = SLOT_SIZE - 14 ## = 36 - đúng tỉ lệ "slot - 14" của bản "Kho báu" gốc
const COUNT_BOX_SIZE: int = 18 ## khung số lượng ở góc dưới-phải
const COUNT_INSET: int = 4 ## lùi vào trong so với viền ô - KHÔNG dán sát cạnh như bản "Kho báu" gốc

const BG: Color = Color(0.16, 0.18, 0.22, 1)
const CARD_BG: Color = Color(0.16, 0.18, 0.22)
const CARD_BORDER: Color = Color(0.4, 0.44, 0.53)
const SLOT_BG: Color = Color(0.13, 0.15, 0.19)
const SLOT_BORDER: Color = Color(0.3, 0.34, 0.43)
const GOLD: Color = Color(0.85, 0.7, 0.3)
const MUTED: Color = Color(0.56, 0.6, 0.68)
const TEXT: Color = Color(0.9, 0.91, 0.93)
const ACTIVE_TAB_BG: Color = Color(0.24, 0.27, 0.33)

## Màu viền theo TIER (1-5) - quy ước rarity phổ biến (trắng/xanh lá/xanh
## dương/tím/cam), suy ra từ MaterialData.tier - KHÔNG phải field rarity thật.
const TIER_BORDER_COLORS: Dictionary = {
	1: Color(0.62, 0.65, 0.7),
	2: Color(0.4, 0.8, 0.45),
	3: Color(0.35, 0.6, 0.95),
	4: Color(0.68, 0.42, 0.88),
	5: Color(0.95, 0.62, 0.2),
}

const TABS: Array[Dictionary] = [
	{"id": "all", "label": "Tất cả"},
	{"id": "material", "label": "Nguyên liệu"},
]

var _grid: GridContainer
var _empty_label: Label
var _scroll: ScrollContainer
var _tab_buttons: Dictionary = {} ## id (String) -> Button
var _active_tab: String = "all"

var _detail_popup: Control
var _detail_icon: TextureRect
var _detail_icon_style: StyleBoxFlat
var _detail_name: Label
var _detail_tier: Label
var _detail_count: Label
var _detail_desc: Label
var _detail_merge_button: Button
var _detail_material_id: String = ""

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UIBuilders.inset_for_top_bottom_bars(self)
	_build_ui()
	_refresh()
	## ScreenRouter chỉ toggle .visible khi đổi tab (không huỷ/tạo lại node) -
	## tự refresh mỗi lần TRỞ LẠI tab này để thấy đúng số lượng mới nhất (VD
	## vừa treo máy rớt thêm nguyên liệu ở tab khác).
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		_refresh()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	## TOP_WIDE (không phải FULL_RECT) - card tự co theo đúng chiều cao nội
	## dung, neo ở TRÊN, KHÔNG kéo giãn hết chiều cao màn hình - lúc ít món để
	## card ngắn gọn thay vì để lại 1 khoảng trống lớn bên trong viền.
	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	for side in ["left", "top", "right", "bottom"]:
		outer_margin.add_theme_constant_override("margin_%s" % side, 16)
	add_child(outer_margin)

	var card := UIBuilders.bordered_card(CARD_BG, CARD_BORDER)
	outer_margin.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "KHO NGUYÊN LIỆU"
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	for tab in TABS:
		var button := Button.new()
		button.text = tab.label
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_tab_pressed.bind(tab.id))
		tab_row.add_child(button)
		_tab_buttons[tab.id] = button
	vbox.add_child(tab_row)
	_refresh_tab_styles()

	_empty_label = Label.new()
	_empty_label.text = "Chưa có nguyên liệu nào - đi đánh quái để rơi đồ."
	_empty_label.add_theme_color_override("font_color", MUTED)
	_empty_label.add_theme_font_size_override("font_size", 12)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_empty_label)

	## KHÔNG size_flags_vertical=EXPAND_FILL - chiều cao tính lại thủ công mỗi
	## lần _refresh() theo ĐÚNG số hàng đang có, cuộn thật chỉ khi vượt quá
	## MAX_VISIBLE_ROWS. Chiều ngang: SIZE_SHRINK_CENTER (không phải FILL mặc
	## định) để _scroll co đúng theo GRID_WIDTH cố định của _grid bên dưới rồi
	## canh giữa trong card - không kéo giãn hết bề ngang card (đã thử FILL,
	## ScrollContainer luôn chiếm hết bề ngang còn lại dù grid bên trong hẹp
	## hơn, để dư khoảng trống một bên) - cộng thêm khoá hẳn
	## horizontal_scroll_mode làm an toàn thứ 2.
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_scroll)

	_grid = GridContainer.new()
	_grid.columns = COLS
	## Bề rộng CỐ ĐỊNH = GRID_WIDTH (8 cột đầy đủ) dù đang có ít hơn 8 món -
	## GridContainer mặc định chỉ rộng bằng số cột THỰC SỰ dùng ở hàng dài
	## nhất, nên tổng < 8 món sẽ co nhỏ lại rồi bị canh giữa lệch tâm. Không
	## cần ô filler nào - hàng cuối thiếu ô cứ để trống bên phải RIÊNG của
	## grid 442px này, không phải trống bên phải của cả card.
	_grid.custom_minimum_size.x = GRID_WIDTH
	_grid.add_theme_constant_override("h_separation", ROW_GAP)
	_grid.add_theme_constant_override("v_separation", ROW_GAP)
	_scroll.add_child(_grid)

	_build_detail_popup(card)

func _on_tab_pressed(tab_id: String) -> void:
	_active_tab = tab_id
	_refresh_tab_styles()
	_refresh()

func _refresh_tab_styles() -> void:
	for id in _tab_buttons:
		var button: Button = _tab_buttons[id]
		if id == _active_tab:
			button.add_theme_color_override("font_color", GOLD)
			button.add_theme_stylebox_override("normal", _flat_style(ACTIVE_TAB_BG, GOLD, 1, 6))
		else:
			button.add_theme_color_override("font_color", MUTED)
			button.add_theme_stylebox_override("normal", _flat_style(SLOT_BG, SLOT_BORDER, 1, 6))

## "material" hiện KHỚP MỌI MaterialData (chưa có loại vật phẩm nào khác
## trong game) - tab này sẽ tự lọc đúng khi sau này có thêm nguồn dữ liệu
## khác (trang bị/tiêu hao) gộp chung vào "Tất cả".
func _matches_tab(_mat: MaterialData) -> bool:
	return _active_tab == "all" or _active_tab == "material"

func _refresh() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var owned: Array[MaterialData] = MaterialDatabase.get_all().filter(
		func(m: MaterialData) -> bool: return GameState.get_material_count(m.id) > 0 and _matches_tab(m)
	)
	_empty_label.visible = owned.is_empty()
	for mat in owned:
		_grid.add_child(_build_slot(mat))

	var total_rows: int = ceili(float(owned.size()) / float(COLS)) if not owned.is_empty() else 0
	var visible_rows: int = mini(total_rows, MAX_VISIBLE_ROWS)
	_scroll.custom_minimum_size.y = visible_rows * SLOT_SIZE + maxi(visible_rows - 1, 0) * ROW_GAP

func _build_slot(mat: MaterialData) -> PanelContainer:
	var count := GameState.get_material_count(mat.id)
	var tier_color: Color = TIER_BORDER_COLORS.get(mat.tier, SLOT_BORDER)
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.border_color = tier_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	slot.add_theme_stylebox_override("panel", style)

	## overlay là Control THƯỜNG (không phải Container) - PanelContainer chỉ ép
	## khít đúng 1 con NÀY vào content rect; BÊN TRONG overlay, icon/số lượng
	## giữ nguyên anchor+offset tự đặt (xem ghi chú đầu file).
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(overlay)

	var icon := UIBuilders.texture_icon(mat.icon, ICON_SIZE)
	icon.anchor_left = 0.5
	icon.anchor_right = 0.5
	icon.anchor_top = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -ICON_SIZE / 2.0
	icon.offset_right = ICON_SIZE / 2.0
	icon.offset_top = -ICON_SIZE / 2.0
	icon.offset_bottom = ICON_SIZE / 2.0
	overlay.add_child(icon)

	var count_label := Label.new()
	count_label.text = str(count)
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	count_label.add_theme_constant_override("outline_size", 3)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	## Lùi vào trong COUNT_INSET so với viền ô ở CẢ 4 cạnh - khác bản "Kho báu"
	## gốc (dán sát/chèn lên viền vì không có offset dương nào cả).
	count_label.anchor_left = 1.0
	count_label.anchor_right = 1.0
	count_label.anchor_top = 1.0
	count_label.anchor_bottom = 1.0
	count_label.offset_left = -(COUNT_BOX_SIZE + COUNT_INSET)
	count_label.offset_right = -COUNT_INSET
	count_label.offset_top = -(COUNT_BOX_SIZE + COUNT_INSET)
	count_label.offset_bottom = -COUNT_INSET
	overlay.add_child(count_label)

	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.tooltip_text = "%s (cấp %d) - Số lượng: %d" % [mat.display_name, mat.tier, count]
	button.pressed.connect(_open_detail.bind(mat))
	slot.add_child(button)

	return slot

## ============================== Popup chi tiết ==============================

func _build_detail_popup(parent_card: Control) -> void:
	_detail_popup = Control.new()
	_detail_popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_popup.visible = false
	## Con của CHÍNH card (không phải root InventoryScreen) để tự động nằm
	## đúng trong khung thẻ bo viền, đè lên trên phần lưới/tab.
	parent_card.add_child(_detail_popup)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_detail_popup.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_popup.add_child(center)

	var popup_card := UIBuilders.bordered_card(CARD_BG, CARD_BORDER)
	popup_card.custom_minimum_size = Vector2(260, 0)
	center.add_child(popup_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	popup_card.add_child(vbox)

	vbox.add_child(UIBuilders.panel_header("CHI TIẾT VẬT PHẨM", GOLD, _close_detail))

	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(80, 80)
	icon_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail_icon_style = StyleBoxFlat.new()
	_detail_icon_style.bg_color = SLOT_BG
	_detail_icon_style.set_border_width_all(2)
	_detail_icon_style.set_corner_radius_all(8)
	icon_frame.add_theme_stylebox_override("panel", _detail_icon_style)
	var icon_center := CenterContainer.new()
	icon_frame.add_child(icon_center)
	_detail_icon = TextureRect.new()
	_detail_icon.custom_minimum_size = Vector2(60, 60)
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_center.add_child(_detail_icon)
	vbox.add_child(icon_frame)

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 16)
	_detail_name.add_theme_color_override("font_color", TEXT)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_detail_name)

	_detail_tier = Label.new()
	_detail_tier.add_theme_font_size_override("font_size", 12)
	_detail_tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_detail_tier)

	_detail_count = Label.new()
	_detail_count.add_theme_font_size_override("font_size", 12)
	_detail_count.add_theme_color_override("font_color", MUTED)
	_detail_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_detail_count)

	_detail_desc = Label.new()
	_detail_desc.add_theme_font_size_override("font_size", 11)
	_detail_desc.add_theme_color_override("font_color", MUTED)
	_detail_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_detail_desc)

	_detail_merge_button = Button.new()
	_detail_merge_button.custom_minimum_size = Vector2(0, 40)
	_detail_merge_button.pressed.connect(_on_merge_pressed)
	vbox.add_child(_detail_merge_button)

func _open_detail(mat: MaterialData) -> void:
	_detail_material_id = mat.id
	var tier_color: Color = TIER_BORDER_COLORS.get(mat.tier, SLOT_BORDER)
	_detail_icon.texture = mat.icon
	_detail_icon_style.border_color = tier_color
	_detail_name.text = mat.display_name
	_detail_tier.text = "Cấp %d" % mat.tier
	_detail_tier.add_theme_color_override("font_color", tier_color)

	var count := GameState.get_material_count(mat.id)
	_detail_count.text = "Số lượng đang có: %d" % count
	## KHÔNG ghi "nhận từ quái nào" - mọi quái đều rơi ngẫu nhiên đều 10 nhóm,
	## không có quái nào gắn riêng với 1 nguyên liệu cụ thể (xem ghi chú đầu file).
	_detail_desc.text = "%s - dùng để ghép lên cấp cao hơn tại Thợ Nâng Cấp (tab Thành)." % mat.group_name

	var can_merge: bool = mat.tier < MaterialDatabase.MAX_TIER and count >= GameState.MERGE_COST
	_detail_merge_button.disabled = not can_merge
	if mat.tier < MaterialDatabase.MAX_TIER:
		_detail_merge_button.text = "GHÉP LÊN CẤP %d (cần %d)" % [mat.tier + 1, GameState.MERGE_COST]
	else:
		_detail_merge_button.text = "ĐÃ CẤP TỐI ĐA"

	_detail_popup.visible = true

func _close_detail() -> void:
	_detail_popup.visible = false

func _on_merge_pressed() -> void:
	var mat := MaterialDatabase.get_by_id(_detail_material_id)
	if mat == null:
		return
	if GameState.merge_material_up(mat.group_key, mat.tier):
		_refresh()
		_close_detail()

func _flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	return style
