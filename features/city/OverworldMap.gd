class_name OverworldMap
extends Control

## Màn "Thành phố" (`city`) - lưới thẻ 2 cột đúng mockup
## mockups/giao-dien-hien-tai.html (#city .city-grid), bấm thẻ mở panel
## tương ứng. KHÔNG còn map/NPC đi lại (đã bỏ SubViewport+OverworldWorld) -
## đơn giản hoá theo đúng hướng mockup đã chốt, chỉ 2 thẻ có gameplay thật
## (Nâng cấp = UpgraderPanel, Kho báu = WarehousePanel), 2 thẻ còn lại (Thợ
## rèn/Cửa hàng) là placeholder cho tương lai.

const ITEMS: Array[Dictionary] = [
	{"icon": "⚒️", "name": "Thợ rèn", "action": "blacksmith"},
	{"icon": "🛒", "name": "Cửa hàng", "action": "shop"},
	{"icon": "🔮", "name": "Nâng cấp", "action": "upgrader"},
	{"icon": "🏦", "name": "Kho báu", "action": "warehouse"},
]

const COLS: int = 2
const ITEM_HEIGHT: int = 135 ## mockup .city-item height:90px * 1.5 (360->540 quy đổi theo chiều rộng màn hình thật)
const GAP: int = 15 ## mockup gap:10px * 1.5
const BG: Color = Color(0.165, 0.176, 0.2) ## mockup .content background #2a2d33
const ITEM_BG: Color = Color(0.204, 0.235, 0.208) ## mockup .city-item background #343c35
const ITEM_BORDER: Color = Color(0.298, 0.361, 0.298) ## mockup .city-item border #4c5c4c
const ICON_SIZE: int = 42 ## mockup .city-icon font-size:28px * 1.5
const NAME_SIZE: int = 16 ## mockup .city-name font-size:11px * 1.5
const NAME_COLOR: Color = Color(0.867, 0.867, 0.867) ## mockup .city-name color #ddd

@onready var _blacksmith_panel: SimplePlaceholderPanel = $BlacksmithPanel
@onready var _shop_panel: SimplePlaceholderPanel = $ShopPanel
@onready var _warehouse_panel: WarehousePanel = $WarehousePanel
@onready var _upgrader_panel: UpgraderPanel = $UpgraderPanel

func _ready() -> void:
	_blacksmith_panel.setup("Thợ Rèn", "Cường hóa trang bị - đang xây dựng, chưa có gì để bấm ở đây.")
	_shop_panel.setup("Cửa Hàng", "Mua bán vật phẩm - đang xây dựng, chưa có gì để bấm ở đây.")
	_build_grid()

## Cả 4 panel (Blacksmith/Shop/Warehouse/Upgrader) đã là con của node này SẴN
## từ .tscn, đứng TRƯỚC trong cây - phải move_child() bg/lưới về index 0/1 để
## chúng vẽ ở DƯỚI, nếu không lưới thẻ (thêm sau bằng code) sẽ đè lên panel
## đang mở (panel ẩn/hiện bằng visible, không đổi index).
func _build_grid() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	UIBuilders.inset_for_top_bottom_bars(outer_margin)
	for side in ["left", "top", "right", "bottom"]:
		outer_margin.add_theme_constant_override("margin_%s" % side, 20)
	add_child(outer_margin)
	move_child(outer_margin, 1)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	outer_margin.add_child(grid)

	for item in ITEMS:
		grid.add_child(_build_city_item(item["icon"], item["name"], item["action"]))

func _build_city_item(icon: String, item_name: String, action: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, ITEM_HEIGHT)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = ITEM_BG
	style.border_color = ITEM_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", ICON_SIZE)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", NAME_SIZE)
	name_label.add_theme_color_override("font_color", NAME_COLOR)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var button := Button.new()
	button.flat = true
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_item_pressed.bind(action))
	card.add_child(button)

	return card

func _on_item_pressed(action: String) -> void:
	match action:
		"blacksmith":
			_blacksmith_panel.open()
		"shop":
			_shop_panel.open()
		"upgrader":
			_upgrader_panel.open()
		"warehouse":
			_warehouse_panel.open()
