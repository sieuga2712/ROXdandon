class_name OverworldWorld
extends Node2D

## Map "Thành phố" - KHÔNG điều khiển được nhân vật, tương tác DUY NHẤT là
## bấm/chạm vào NPC để mở panel tương ứng (xem OverworldMap.gd - lắng nghe
## signal npc_tapped bên dưới, biết NPC nào qua chính tên node con của Npcs).
##
## Cố tình KHÔNG dùng Area2D/CollisionShape2D + input_event (chưa có tiền lệ
## nào trong project này) - tính khoảng cách thẳng từ world_pos tới position
## từng NPC, giống kỹ thuật "tính từ event.position qua affine_inverse()" đã
## ghi trong Lỗi đã gặp & Bài học (KHÔNG dùng get_global_mouse_position() -
## hàm đó cần có InputEventMouseMotion xảy ra trước đó mới đúng, sai cho tap
## đơn lẻ trên touch).

signal npc_tapped(npc_id: String)

const TAP_RADIUS: float = 36.0

@onready var npcs: Node2D = $Npcs

func _unhandled_input(event: InputEvent) -> void:
	var screen_pos: Vector2
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		screen_pos = event.position
	elif event is InputEventScreenTouch and event.pressed:
		screen_pos = event.position
	else:
		return
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	var nearest_id := ""
	var nearest_dist := TAP_RADIUS
	for npc in npcs.get_children():
		var d: float = world_pos.distance_to(npc.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_id = npc.name
	if nearest_id != "":
		npc_tapped.emit(nearest_id)
