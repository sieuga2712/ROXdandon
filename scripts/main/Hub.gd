extends Control

## Màn hình gốc (run/main_scene) - map nhỏ đi lại được (OverworldMap) thay cho
## hàng icon tĩnh cũ, party giờ là unit thật điều khiển được ngay trên map
## (xem OverworldWorld.gd). Việc nối StageSelectPanel/BattleScene nằm ở
## StageFlowController.gd (node con).

@onready var overworld_map: OverworldMap = %OverworldMap
@onready var gold_label: Label = %GoldLabel
@onready var stage_select_panel: StageSelectPanel = %StageSelectPanel
@onready var battle_scene: BattleScene = %BattleScene

func _process(_delta: float) -> void:
	gold_label.text = "Vàng: %d" % GameState.gold
	## StageSelectPanel/BattleScene cố tình cho chuột rơi xuyên qua vùng trống
	## của chúng xuống node vẽ bên dưới (trước giờ vô hại vì bên dưới chỉ là
	## Background tĩnh) - giờ bên dưới là map click/kéo được nên phải tắt
	## interactive lúc panel/trận đấu đang mở.
	overworld_map.set_interactive(not stage_select_panel.visible and not battle_scene.visible)
