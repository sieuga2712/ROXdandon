class_name ScreenRouter
extends Control

## Chuyển màn data-driven: mỗi con trực tiếp của node này = 1 tab, TÊN NODE
## chính là id tab (khớp id trong BottomNav.TABS, VD node "city" <-> tab
## {"id": "city", ...}). Thêm màn hình mới sau này chỉ cần thêm 1 node con ở
## đây + 1 entry trong BottomNav.TABS - không sửa gì trong file này.

func show_screen(id: String) -> void:
	for child in get_children():
		child.visible = child.name == id

func get_active_screen() -> Node:
	for child in get_children():
		if child.visible:
			return child
	return null
