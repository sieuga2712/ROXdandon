class_name MainShell
extends Control

## Vỏ app portrait (run/main_scene). Top bar (vàng) + ScreenRouter (5 tab,
## xem ScreenRouter.gd/BottomNav.gd) + BattleScene overlay dùng chung cho cả
## Ủy Thác/Treo máy/Ải Boss (xem StageFlowController.gd) + BottomNav luôn nổi
## trên cùng, tự ẩn khi đang trong trận. `StageSelectPanel.tscn/.gd` (màn chọn
## ải popup cũ) không còn được dùng nhưng giữ nguyên file (không tự ý xoá).
##
## "Ải Boss" đã gộp làm sub-tab thứ 3 BÊN TRONG StageBoardScreen (%BossPanel,
## xem StageBoardScreen.gd) thay vì 1 tab riêng ở BottomNav - MainShell chỉ
## còn nối 1 đầu mối stage_screen, StageBoardScreen tự forward xuống BossPanel.

@onready var gold_label: Label = %GoldLabel
@onready var screen_router: ScreenRouter = %ScreenContainer
@onready var battle_scene: BattleScene = %BattleScene
@onready var bottom_nav: BottomNav = %BottomNav
@onready var stage_screen: StageBoardScreen = %stage
@onready var stage_flow: StageFlowController = %StageFlowController

func _ready() -> void:
	bottom_nav.tab_selected.connect(_on_tab_selected)
	stage_screen.stage_selected.connect(stage_flow.start_stage)
	stage_flow.stage_finished.connect(stage_screen.on_stage_finished)
	_on_tab_selected("city")

func _process(_delta: float) -> void:
	gold_label.text = "Vàng: %d" % GameState.gold
	## BattleScene chiếm toàn màn hình khi mở trận - ẩn nav (map Thành/bảng Ải
	## đều là UI/cảnh trang trí thuần, không có gì cần chặn tương tác riêng).
	bottom_nav.visible = not battle_scene.visible

func _on_tab_selected(id: String) -> void:
	screen_router.show_screen(id)
	bottom_nav.refresh_for_screen(id, screen_router.get_active_screen())
