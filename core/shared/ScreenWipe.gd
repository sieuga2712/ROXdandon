class_name ScreenWipe
extends ColorRect

## Overlay đen phủ kín parent (Control - dùng anchors PRESET_FULL_RECT, KHÔNG
## dùng được trực tiếp dưới Node2D vì anchors chỉ có tác dụng trong cây
## Control) - dùng để tạo hiệu ứng "wipe đóng/mở" quanh lúc đổi map/đổi
## tầng/đổi ải (nội dung bên dưới đổi ĐỘT NGỘT, wipe che lúc đổi cho mượt).
## Tự tạo bằng `ScreenWipe.new()` rồi `add_child()` vào ĐÚNG Control muốn che
## kín - KHÔNG phải scene/prefab, chỉ là 1 class tiện dùng lại nhiều chỗ.
##
## Dùng: `var wipe := ScreenWipe.new(); parent.add_child(wipe)`, rồi
## `await wipe.close()` (phủ đen) trước khi đổi nội dung, `await wipe.open()`
## (mờ dần lộ ra) sau khi đổi xong.

const DEFAULT_DURATION: float = 0.25

func _init() -> void:
	color = Color(0.0, 0.0, 0.0, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 4096 ## luôn nổi trên cùng trong parent của nó, không cần chỉnh thứ tự node thủ công

## "Đóng" - phủ đen dần che kín parent, gọi TRƯỚC khi đổi nội dung bên dưới.
func close(duration: float = DEFAULT_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 1.0, duration)
	await tween.finished

## "Mở" - mờ dần lộ nội dung MỚI đã đổi xong bên dưới, gọi SAU khi đổi.
func open(duration: float = DEFAULT_DURATION) -> void:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, duration)
	await tween.finished
