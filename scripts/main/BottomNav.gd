class_name BottomNav
extends Control

## Thanh nav dưới cố định 5 tab. 2 trạng thái: thu gọn (chỉ hàng icon) và mở
## rộng (kéo lên bằng gesture qua DragHandle, hiện thêm shortcut của màn đang
## active). Data-driven qua TABS - thêm tab mới chỉ cần thêm 1 dòng ở đây +
## 1 node con cùng tên trong ScreenRouter, KHÔNG cần sửa logic gì trong file
## này. Nội dung mở rộng lấy từ `active_screen.get_shortcuts()` (nếu màn đó
## có hàm này) - BottomNav không biết/không cần biết nội dung từng màn.

signal tab_selected(id: String)

const TABS: Array[Dictionary] = [
	{"id": "city", "icon": "🏰", "label": "Thành"},
	{"id": "stage", "icon": "⚔️", "label": "Ải"},
	{"id": "boss", "icon": "👹", "label": "Boss"},
	{"id": "character", "icon": "👤", "label": "NV"},
	{"id": "settings", "icon": "⚙️", "label": "Cài"},
]

const COLLAPSED_HEIGHT: float = 96.0
const EXPANDED_HEIGHT: float = 340.0
const DRAG_TOGGLE_THRESHOLD_PX: float = 40.0 ## kéo dưới mức này tính là bấm nhầm - tự trở lại trạng thái cũ
const ANIM_DURATION: float = 0.25

const ACTIVE_TINT: Color = Color(1.0, 0.85, 0.3)

@onready var drag_handle: Control = %DragHandle
@onready var handle_bar: ColorRect = %HandleBar
@onready var shortcuts_scroll: ScrollContainer = %ShortcutsScroll
@onready var shortcuts_list: VBoxContainer = %ShortcutsList
@onready var tab_row: HBoxContainer = %TabRow

var is_expanded: bool = false
var _dragging: bool = false
var _drag_start_y: float = 0.0
var _tab_buttons: Dictionary = {} ## id (String) -> Button
var _has_shortcuts: bool = false ## màn đang active có shortcut nào không - không thì ẩn tay cầm kéo, khỏi mời vuốt lên xem 1 tấm trống

func _ready() -> void:
	offset_top = -COLLAPSED_HEIGHT
	shortcuts_scroll.visible = false
	for tab in TABS:
		var button := Button.new()
		button.text = "%s\n%s" % [tab.icon, tab.label]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_tab_button_pressed.bind(tab.id))
		tab_row.add_child(button)
		_tab_buttons[tab.id] = button
	drag_handle.gui_input.connect(_on_drag_handle_input)

func _on_tab_button_pressed(id: String) -> void:
	tab_selected.emit(id)

## MainShell gọi mỗi khi đổi tab - tô sáng nút active + đổi nội dung shortcut
## theo đúng màn đang hiện (rỗng nếu màn đó chưa có get_shortcuts()).
func refresh_for_screen(active_id: String, active_screen: Node) -> void:
	for id in _tab_buttons:
		_tab_buttons[id].modulate = ACTIVE_TINT if id == active_id else Color.WHITE
	for child in shortcuts_list.get_children():
		child.queue_free()
	if active_screen != null and active_screen.has_method("get_shortcuts"):
		for shortcut in active_screen.get_shortcuts():
			var button := Button.new()
			button.text = "%s  %s" % [shortcut.get("icon", ""), shortcut.get("label", "")]
			if shortcut.has("callback"):
				button.pressed.connect(shortcut.callback)
			shortcuts_list.add_child(button)

	_has_shortcuts = shortcuts_list.get_child_count() > 0
	handle_bar.visible = _has_shortcuts
	if not _has_shortcuts and is_expanded:
		set_expanded(false) ## đổi sang tab không có shortcut lúc đang mở rộng - tự thu gọn lại, không để treo 1 tấm trống

## Kéo trực tiếp theo ngón tay/chuột trong lúc giữ (feedback tức thời), chốt
## trạng thái đóng/mở khi thả ra dựa theo tổng khoảng cách đã kéo.
func _on_drag_handle_input(event: InputEvent) -> void:
	if not _has_shortcuts:
		return ## màn hiện tại không có gì để hiện lúc mở rộng - lờ luôn gesture kéo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_start_y = event.position.y
		elif _dragging:
			_dragging = false
			_finish_drag(event.position.y - _drag_start_y)
	elif event is InputEventMouseMotion and _dragging:
		var base_top: float = -EXPANDED_HEIGHT if is_expanded else -COLLAPSED_HEIGHT
		var delta_y: float = event.position.y - _drag_start_y
		offset_top = clampf(base_top + delta_y, -EXPANDED_HEIGHT, -COLLAPSED_HEIGHT)

func _finish_drag(total_delta_y: float) -> void:
	if absf(total_delta_y) < DRAG_TOGGLE_THRESHOLD_PX:
		set_expanded(is_expanded) ## kéo không đủ xa - coi như không đổi, animate về đúng vị trí cũ
		return
	set_expanded(total_delta_y < 0.0) ## kéo lên (delta âm, vì offset_top càng âm càng cao) = mở rộng

func set_expanded(value: bool) -> void:
	is_expanded = value
	if value:
		shortcuts_scroll.visible = true
	var target: float = -EXPANDED_HEIGHT if value else -COLLAPSED_HEIGHT
	var tween := create_tween()
	tween.tween_property(self, "offset_top", target, ANIM_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not value:
		tween.tween_callback(func(): shortcuts_scroll.visible = false)
