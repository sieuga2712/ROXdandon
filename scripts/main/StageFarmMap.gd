class_name StageFarmMap
extends Control

## Proxy mỏng cho MainShell - y hệt OverworldMap.gd (City tab), chỉ trỏ vào
## StageFarmWorld thay vì OverworldWorld.

@onready var _world: StageFarmWorld = $SubViewportContainer/SubViewport/StageFarmWorld
@onready var _roster_panel: PartyRosterPanel = %PartyRosterPanel

func _ready() -> void:
	_roster_panel.leader_selected.connect(_world.select_leader)

func set_interactive(value: bool) -> void:
	_world.interactive = value
