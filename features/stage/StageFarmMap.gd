class_name StageFarmMap
extends Control

## Proxy mỏng trỏ vào StageFarmWorld (SubViewport riêng, y hệt pattern
## OverworldMap.gd của tab Thành) - KHÔNG điều khiển được. Đây CHÍNH LÀ trận
## đấu treo máy thật (xem StageFarmWorld.gd) - GameState.start_idle_team()
## instance scene này rồi gọi configure() ngay, giữ sống suốt thời gian treo.

@onready var _world: StageFarmWorld = $SubViewportContainer/SubViewport/StageFarmWorld

func configure(stage: StageData, member_troop_ids: Array[int]) -> void:
	_world.configure(stage, member_troop_ids)

func get_stage() -> StageData:
	return _world.get_stage()

func get_member_troop_ids() -> Array[int]:
	return _world.get_member_troop_ids()
