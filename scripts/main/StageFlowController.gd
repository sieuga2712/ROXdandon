class_name StageFlowController
extends Node

## Mở BattleScene cho 1 StageData - dùng chung bởi StageBoardScreen (tab
## "Vượt ải") và sau này BossScreen (Ải Boss). Khi thắng, tự báo tiến độ tầng
## lên GameState rồi phát stage_finished ra ngoài cho màn gọi biết để vẽ lại
## UI (mở khoá tầng kế tiếp) - không tự vẽ UI gì ở đây.

signal stage_finished(stage: StageData, won: bool)

@onready var battle_scene: BattleScene = %BattleScene

var _current_stage: StageData

func _ready() -> void:
	battle_scene.closed.connect(_on_battle_closed)

func start_stage(stage: StageData) -> void:
	_current_stage = stage
	battle_scene.start_battle(stage)

func _on_battle_closed(won: bool) -> void:
	var stage := _current_stage
	_current_stage = null
	if stage == null:
		return
	if won:
		GameState.report_floor_cleared(stage.map_id, stage.floor_number)
	stage_finished.emit(stage, won)
