class_name MainShell
extends Control

## Vỏ app portrait (run/main_scene). Top bar (vàng) + ScreenRouter (5 tab,
## xem ScreenRouter.gd/BottomNav.gd) + BottomNav luôn nổi trên cùng.
## `StageSelectPanel.tscn/.gd` (màn chọn ải popup cũ) không còn được dùng
## nhưng giữ nguyên file (không tự ý xoá).
##
## `BattleScene` (trận boss thật, xem StageFlowController.gd) sống ở đây làm
## "nhà gốc" nhưng KHÔNG còn hiện overlay toàn màn (đổi 2026-08) - MainShell
## tiêm (inject) instance này cho `StageBoardScreen` qua set_battle_scene(),
## module đó tự mượn tạm (reparent) vào %BattleViewHost của nó lúc đánh boss
## rồi trả về đây khi xong, xem StageBoardScreen._mount_boss_battle()/_unmount_boss_battle().
##
## "Ải Boss" đã gộp làm sub-tab BÊN TRONG StageBoardScreen (%BossPanel, xem
## StageBoardScreen.gd) thay vì 1 tab riêng ở BottomNav - MainShell chỉ còn
## nối 1 đầu mối stage_screen, StageBoardScreen tự forward xuống BossPanel.

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
	stage_screen.set_battle_scene(battle_scene)
	_on_tab_selected("stage") ## màn khởi động = tab "Ải" (đổi 2026-08, trước đó là "city")

func _process(_delta: float) -> void:
	gold_label.text = "Vàng: %d" % GameState.gold

func _on_tab_selected(id: String) -> void:
	screen_router.show_screen(id)
	bottom_nav.refresh_for_screen(id, screen_router.get_active_screen())
