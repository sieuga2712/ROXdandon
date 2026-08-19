class_name EquipmentItemSlot
extends PanelContainer

## 1 ô trang bị THẬT (khác ô tượng trưng cũ ở CharacterBoardScreen) - hiện
## icon (nền gradient tròn) + viền dày màu theo CHẤT LƯỢNG + 3 chỉ số góc,
## style theo mockup HTML người dùng gửi 2026-08-19 (khung bo góc, huy hiệu
## "ruy băng" 2 góc trái có nền+viền riêng, số cường hóa nổi không khung):
## - Trên-trái: TIER theo lv đề xuất mặc, "T1".."T5" (T1=lv1, T2=lv30,
##   T3=lv70, T4=lv100, T5=lv140 - bảng lv cụ thể xem nơi tạo dữ liệu trang
##   bị, KHÔNG hardcode ở đây).
## - Trên-phải: cấp CƯỜNG HÓA, số thường (1, 2, 3...) - ẩn nếu = 0.
## - Dưới-trái: cấp TINH LUYỆN, số La Mã (I, II, III...) - ẩn nếu = 0.
## KHÔNG có số lượng như ô Kho/InventoryScreen - mỗi trang bị là 1 item ĐỘC
## LẬP (có thể khác tinh luyện/cường hóa dù cùng loại), không gộp/stack.

## Enum thật nằm ở Enums.EquipmentQuality (core/config) chứ không khai báo
## riêng ở đây - core/combat/EquipmentDropTable.gd (roll chất lượng lúc rớt
## đồ) cũng cần dùng, mà core/* không được phép import ngược features/* (xem
## CLAUDE.md), nên phải đặt enum dùng chung ở core.
## Thứ tự thấp -> cao: Trắng < Lam < Tím < Vàng < Cam/Đỏ.
const QUALITY_COLORS: Dictionary = {
	Enums.EquipmentQuality.WHITE: Color(0.85, 0.85, 0.87),
	Enums.EquipmentQuality.BLUE: Color(0.35, 0.6, 0.95),
	Enums.EquipmentQuality.PURPLE: Color(0.68, 0.42, 0.88),
	Enums.EquipmentQuality.GOLD: Color(0.79, 0.64, 0.31), ## #c9a34e - đúng màu vàng trong mockup gốc
	Enums.EquipmentQuality.ORANGE: Color(0.95, 0.4, 0.2),
}

const GRADIENT_CENTER: Color = Color(0.29, 0.325, 0.388) ## #4a5363
const GRADIENT_MID: Color = Color(0.188, 0.216, 0.267) ## #303744
const GRADIENT_EDGE: Color = Color(0.11, 0.129, 0.169) ## #1c212b
const BADGE_BG: Color = Color(0.094, 0.106, 0.133) ## #181b22

const CORNER_RADIUS: int = 10
const BORDER_WIDTH: int = 4
const BADGE_HEIGHT_RATIO: float = 0.167 ## ~30px trên khung 180px gốc - co theo SLOT_SIZE
const BADGE_RADIUS_RATIO: float = 0.033 ## ~6px trên khung 180px gốc
const ICON_SIZE_RATIO: float = 0.49 ## ~88px trên khung 180px gốc

@export var icon: Texture2D:
	set(value):
		icon = value
		_rebuild()
@export var quality: Enums.EquipmentQuality = Enums.EquipmentQuality.WHITE:
	set(value):
		quality = value
		_rebuild()
@export var refine_level: int = 0: ## cấp tinh luyện - La Mã góc dưới-trái, 0 = ẩn
	set(value):
		refine_level = value
		_rebuild()
@export var enhance_level: int = 0: ## cấp cường hóa - số thường góc trên-phải, 0 = ẩn
	set(value):
		enhance_level = value
		_rebuild()
@export var tier: int = 1: ## 1..5 theo lv đề xuất mặc - "T{n}" góc trên-trái
	set(value):
		tier = value
		_rebuild()
@export var slot_size: float = 88.0:
	set(value):
		slot_size = value
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	custom_minimum_size = Vector2(slot_size, slot_size)
	clip_contents = true ## bo góc panel thì nền gradient/icon bên trong cũng phải bị cắt theo, không tràn ra góc vuông

	var quality_color: Color = QUALITY_COLORS.get(quality, Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = GRADIENT_EDGE ## màu nền dự phòng - gradient thật vẽ đè lên bằng TextureRect bên dưới
	style.border_color = quality_color
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.shadow_color = Color(0, 0, 0, 0.65)
	style.shadow_size = maxi(2, roundi(slot_size * 0.08))
	style.shadow_offset = Vector2(0, slot_size * 0.03)
	add_theme_stylebox_override("panel", style)

	for child in get_children():
		child.queue_free()

	## overlay là Control THƯỜNG (không phải Container) - PanelContainer chỉ ép
	## khít đúng 1 con NÀY vào content rect; nền gradient/icon/nhãn góc bên
	## trong overlay tự đặt anchor riêng, không bị PanelContainer ép chồng lên nhau.
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var bg_rect := TextureRect.new()
	bg_rect.texture = _make_radial_gradient()
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(bg_rect)

	var icon_size: float = slot_size * ICON_SIZE_RATIO
	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.anchor_left = 0.5
	icon_rect.anchor_right = 0.5
	icon_rect.anchor_top = 0.5
	icon_rect.anchor_bottom = 0.5
	icon_rect.offset_left = -icon_size / 2.0
	icon_rect.offset_right = icon_size / 2.0
	icon_rect.offset_top = -icon_size / 2.0
	icon_rect.offset_bottom = icon_size / 2.0
	overlay.add_child(icon_rect)

	## `overlay` khớp CONTENT rect của PanelContainer (đã trừ viền
	## BORDER_WIDTH mỗi cạnh, xem stylebox ở trên) - mọi vị trí đặt vào trong
	## `overlay` (huy hiệu góc, số cường hóa) phải tính theo content_size này,
	## KHÔNG phải slot_size gốc, nếu không sẽ lồi ra ngoài/bị clip_contents cắt
	## mất (bug đã gặp lúc build).
	var content_size: float = slot_size - 2.0 * BORDER_WIDTH

	## Huy hiệu góc "ruy băng" - nền riêng + viền màu chất lượng, bo góc LỆCH
	## (bo 2 góc chéo nhau, giống dải ruy băng ôm sát góc khung) - đúng
	## border-radius: 6px 0 6px 0 (trên-trái) / 0 6px 0 6px (dưới-trái) trong
	## mockup HTML gốc.
	overlay.add_child(_corner_badge("T%d" % tier, quality_color, true, content_size))
	if refine_level > 0:
		overlay.add_child(_corner_badge(_to_roman(refine_level), quality_color, false, content_size))

	if enhance_level > 0:
		overlay.add_child(_enhance_label(content_size))

## Vị trí/kích thước ĐẶT THẲNG bằng position/size (không dùng anchors_preset) -
## overlay là Control thường (không phải Container) nên con của nó không tự
## được resize theo custom_minimum_size, phải tự tính tay. Bề rộng cố định
## (không auto-fit theo text) - giống đúng cách mockup HTML gốc dùng
## min-width cho .tier/.roman thay vì để trình duyệt tự co.
func _corner_badge(text: String, quality_color: Color, top_left: bool, content_size: float) -> PanelContainer:
	var badge_h: float = slot_size * BADGE_HEIGHT_RATIO
	var badge_w: float = slot_size * 0.34
	var badge_r: float = slot_size * BADGE_RADIUS_RATIO

	var badge := PanelContainer.new()
	badge.position = Vector2(0.0, 0.0) if top_left else Vector2(0.0, content_size - badge_h)
	badge.size = Vector2(badge_w, badge_h)

	var style := StyleBoxFlat.new()
	style.bg_color = BADGE_BG
	style.border_color = quality_color
	style.set_border_width_all(maxi(2, roundi(BORDER_WIDTH * 0.75)))
	if top_left:
		style.corner_radius_top_left = roundi(badge_r)
		style.corner_radius_bottom_right = roundi(badge_r)
	else:
		style.corner_radius_top_right = roundi(badge_r)
		style.corner_radius_bottom_left = roundi(badge_r)
	badge.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", maxi(9, roundi(slot_size * 0.1)))
	label.add_theme_color_override("font_color", Color(1, 0.87, 0.6) if top_left else Color(0.96, 0.9, 0.69))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)

	return badge

## Số nổi (không khung) - trải theo TOÀN BỘ bề ngang ô rồi canh chữ phải, thay
## vì đặt anchor đúng-điểm-góc (không tự co theo text dưới Control thường,
## xem _corner_badge()) - cách này luôn khớp mép phải bất kể độ dài số.
func _enhance_label(content_size: float) -> Label:
	var label := Label.new()
	label.text = str(enhance_level)
	label.add_theme_font_size_override("font_size", maxi(11, roundi(slot_size * 0.135)))
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", maxi(2, roundi(slot_size * 0.02)))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.position = Vector2(0.0, content_size * 0.04)
	label.size = Vector2(content_size - content_size * 0.06, content_size * 0.25)
	return label

func _to_roman(n: int) -> String:
	var vals: Array[int] = [10, 9, 5, 4, 1]
	var syms: Array[String] = ["X", "IX", "V", "IV", "I"]
	var result := ""
	var num := n
	for i in range(vals.size()):
		while num >= vals[i]:
			result += syms[i]
			num -= vals[i]
	return result

## Nền tròn tâm sáng rìa tối (radial-gradient trong mockup gốc) - tạo 1 lần
## bằng GradientTexture2D, KHÔNG phụ thuộc quality (giống mockup - chỉ viền
## khung mới đổi màu theo chất lượng, nền socket luôn 1 tông xám-xanh).
func _make_radial_gradient() -> GradientTexture2D:
	## Gán thẳng cả 2 mảng offsets/colors 1 lần - KHÔNG trộn add_point() với
	## set_color(index): add_point() chèn 1 điểm mới làm dịch chỉ số các điểm
	## sau nó, set_color(1, ...) sau đó vô tình ghi màu vào điểm VỪA CHÈN
	## (offset 0.45) thay vì điểm gốc ở offset 1.0 - điểm offset=1.0 mặc định
	## của Gradient (trắng) không bao giờ bị đổi, ra rìa trắng ngoài ý muốn
	## (bug đã gặp lúc build, xem ảnh test).
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([GRADIENT_CENTER, GRADIENT_MID, GRADIENT_EDGE])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.0, 0.45)
	tex.width = 128
	tex.height = 128
	return tex
