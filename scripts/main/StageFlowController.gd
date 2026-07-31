class_name StageFlowController
extends Node

## Mở BattleScene cho 1 StageData - dùng chung bởi StageScreen (Ải) VÀ
## BossScreen (Ải Boss, xem StageData.is_boss). Không còn quản lý
## StageSelectPanel (màn chọn ải dạng popup cũ) - đã thay bằng StageScreen
## full-tab trong MainShell/ScreenRouter. StageSelectPanel.tscn/.gd vẫn giữ
## nguyên file (không xoá), chỉ không còn được instance ở đâu nữa.

@onready var battle_scene: BattleScene = %BattleScene

func start_stage(stage: StageData) -> void:
	battle_scene.start_battle(stage)
