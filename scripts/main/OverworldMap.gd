class_name OverworldMap
extends Control

## Proxy mỏng cho Hub - Hub chỉ được gọi qua đây, không đụng thẳng vào
## OverworldWorld bên trong SubViewport (giống cách Hub chỉ biết
## %StageSelectPanel/%BattleScene chứ không biết con của chúng).

@onready var _world: OverworldWorld = $SubViewportContainer/SubViewport/OverworldWorld
@onready var _roster_panel: PartyRosterPanel = %PartyRosterPanel

func _ready() -> void:
	_roster_panel.leader_selected.connect(_world.select_leader)

func set_interactive(value: bool) -> void:
	_world.interactive = value
