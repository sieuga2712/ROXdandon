class_name MainShell
extends Control

## Vỏ app portrait (run/main_scene MỚI) - thay Hub.tscn cũ. Top bar (vàng) +
## ScreenRouter (5 tab, xem ScreenRouter.gd/BottomNav.gd) + BattleScene
## overlay dùng chung cho cả tab Ải lẫn Ải Boss (xem StageFlowController.gd)
## + BottomNav luôn nổi trên cùng, tự ẩn khi đang trong trận. Hub.tscn/.gd và
## StageSelectPanel.tscn/.gd không còn được dùng nhưng giữ nguyên file (không
## tự ý xoá hệ thống đang có).

@onready var gold_label: Label = %GoldLabel
@onready var screen_router: ScreenRouter = %ScreenContainer
@onready var battle_scene: BattleScene = %BattleScene
@onready var bottom_nav: BottomNav = %BottomNav
@onready var city_screen: OverworldMap = %city
@onready var stage_screen: StageFarmMap = %stage

func _ready() -> void:
	bottom_nav.tab_selected.connect(_on_tab_selected)
	_on_tab_selected("city")

func _process(_delta: float) -> void:
	gold_label.text = "Vàng: %d" % GameState.gold
	## BattleScene chiếm toàn màn hình khi mở trận - ẩn nav + tắt tương tác
	## map bên dưới, giống cơ chế interactive-gating cũ ở Hub.gd.
	var battle_active := battle_scene.visible
	bottom_nav.visible = not battle_active
	city_screen.set_interactive(not battle_active)
	stage_screen.set_interactive(not battle_active)

func _on_tab_selected(id: String) -> void:
	screen_router.show_screen(id)
	bottom_nav.refresh_for_screen(id, screen_router.get_active_screen())
