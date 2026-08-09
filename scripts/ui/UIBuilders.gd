class_name UIBuilders
extends RefCounted

## Small reusable node-builders for UI trees assembled via `.new()` instead of
## scenes - keeps repeated TextureRect sizing/stretch setup and label styling
## in one place instead of copy-pasted across panels.

static func texture_icon(texture: Texture2D, size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

## TopStatusBar/BottomNav trong MainShell.tscn nổi cố định TRÊN MỌI tab (là
## sibling sau ScreenContainer nên luôn vẽ đè lên) - panel full-rect dựng
## bằng code (không qua .tscn, không tự thừa hưởng offset_top/offset_bottom
## như màn "settings" đã đặt sẵn trong MainShell.tscn) phải tự trừ đúng
## khoảng này ra, nếu không nút/chữ ở mép trên-dưới bị 2 thanh đó che mất dù
## vẫn tồn tại đúng trong cây scene (không phải lỗi, chỉ là bị vẽ đè lên).
const TOP_BAR_HEIGHT: float = 72.0
const BOTTOM_NAV_HEIGHT: float = 96.0

## Gọi ngay sau set_anchors_preset(Control.PRESET_FULL_RECT) cho 1 panel dựng
## bằng code để né đúng 2 thanh cố định đó.
static func inset_for_top_bottom_bars(control: Control) -> void:
	control.offset_top = TOP_BAR_HEIGHT
	control.offset_bottom = -BOTTOM_NAV_HEIGHT

static func small_label(text: String, font_size: int = 12) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	return label

## Khung "bảng" bo góc có viền - dùng cho panel NPC (Kho/Nâng Cấp/placeholder,
## xem WarehousePanel.gd/UpgraderPanel.gd/SimplePlaceholderPanel.gd) thay vì
## đặt nội dung thẳng lên nền mờ toàn màn hình.
static func bordered_card(bg_color: Color, border_color: Color, border_width: int = 2, corner_radius: int = 14) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)
	return card

## Header chuẩn cho panel NPC: "←" quay lại bên trái, tên ở giữa, "✕" đóng bên
## phải - cả 2 nút cùng gọi on_close (bấm nút nào cũng đóng được).
static func panel_header(title_text: String, title_color: Color, on_close: Callable) -> HBoxContainer:
	var header := HBoxContainer.new()
	var back_button := Button.new()
	back_button.text = "←"
	back_button.custom_minimum_size = Vector2(36, 36)
	back_button.pressed.connect(on_close)
	header.add_child(back_button)

	var title := Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_font_size_override("font_size", 18)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)

	var close_button := Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(36, 36)
	close_button.pressed.connect(on_close)
	header.add_child(close_button)

	return header
