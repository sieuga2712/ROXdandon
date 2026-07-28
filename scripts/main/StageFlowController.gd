class_name StageFlowController
extends Node

## Nối luồng vượt ải lại với nhau: Hub -> Màn chọn ải -> Màn chiến đấu -> quay
## lại Hub. Hub (Main.tscn cũ) không bị thay thế/huỷ khi vượt ải - BattleScene
## chỉ là overlay ẩn/hiện đè lên trên, giống StageSelectPanel.

@onready var stage_select_panel: StageSelectPanel = %StageSelectPanel
@onready var battle_scene: BattleScene = %BattleScene
@onready var open_button: Button = %ChonAiButton

func _ready() -> void:
	open_button.pressed.connect(func(): stage_select_panel.open_panel())
	stage_select_panel.stage_selected.connect(_on_stage_selected)
	battle_scene.closed.connect(_on_battle_closed)

func _on_stage_selected(stage: StageData) -> void:
	stage_select_panel.visible = false
	battle_scene.start_battle(stage)

func _on_battle_closed() -> void:
	pass ## chỉ cần đóng màn chiến đấu, quay lại Hub là xong
