class_name StageFarmMap
extends Control

## Màn "xem treo máy cho vui" - proxy mỏng trỏ vào StageFarmWorld (SubViewport
## riêng, y hệt pattern OverworldMap.gd của tab Thành) - KHÔNG điều khiển
## được, chỉ hiện auto-fight vô hạn. StageBoardScreen._open_idle_view()
## instance scene này rồi gọi configure() ngay, xem StageFarmWorld.gd.

@onready var _world: StageFarmWorld = $SubViewportContainer/SubViewport/StageFarmWorld

func configure(stage: StageData, member_troop_ids: Array[int]) -> void:
	_world.configure(stage, member_troop_ids)
