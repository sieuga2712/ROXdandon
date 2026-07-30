class_name OverworldMap
extends Control

## Proxy mỏng cho Hub - Hub chỉ được gọi qua đây, không đụng thẳng vào
## OverworldWorld bên trong SubViewport (giống cách Hub chỉ biết
## %StageSelectPanel/%BattleScene chứ không biết con của chúng).

@onready var _world: OverworldWorld = $SubViewportContainer/SubViewport/OverworldWorld
@onready var _roster_panel: PartyRosterPanel = %PartyRosterPanel

func _ready() -> void:
	_roster_panel.control_requested.connect(_world.select_leader)
	_roster_panel.follow_toggled.connect(_world.toggle_follow)
	_roster_panel.recall_all_requested.connect(_world.recall_all)
	_world.state_changed.connect(_on_world_state_changed)
	_on_world_state_changed() ## đồng bộ hiển thị ban đầu - OverworldWorld._ready() đã chọn sẵn leader mặc định trước khi 2 node này kết nối được với nhau

func _on_world_state_changed() -> void:
	_roster_panel.refresh(_world.party_units, _world.leader, _world.following)

func set_interactive(value: bool) -> void:
	_world.interactive = value
