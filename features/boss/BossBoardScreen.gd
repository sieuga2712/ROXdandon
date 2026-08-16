class_name BossBoardScreen
extends Control

## Tab "Boss" - nhúng bên trong StageBoardScreen (tab "Ải"), KHÔNG còn hàng
## sub-tab riêng của mình - StageBoardScreen gộp "BOSS NGÀY"/"BOSS KHỦNG"
## chung 1 hàng với "ẢI THƯỜNG" (đổi 2026-08), chọn panel nào hiện qua
## show_daily_tab()/show_world_tab() (public API), KHÔNG tự vẽ nút chọn nữa:
## - "Boss Ngày": mỗi boss 1 thẻ, chọn độ khó (Dễ/Thường/Khó) ngay trong thẻ -
##   mỗi độ khó là 1 StageData THẬT riêng (xem BossData.get_stage) nên đổi độ
##   khó là đổi hẳn quái/thưởng sẽ đưa vào BattleScene, không phải số liệu ảo.
## - "Boss Khủng": 1 thẻ duy nhất/boss, không có chọn độ khó.
## HP/ATK/DEF hiện trên thẻ lấy thẳng từ LinhData của quái đầu tiên trong
## StageData đang chọn (_first_enemy) - không có bộ số liệu hiển thị riêng.
##
## MainShell làm trung gian nối stage_selected -> StageFlowController.start_stage
## và stage_flow.stage_finished -> on_stage_finished, dùng CHUNG 1
## StageFlowController với StageBoardScreen (đúng như ghi chú sẵn trong
## StageFlowController.gd) - chỉ 1 trận đấu chạy tại 1 thời điểm nên không có
## xung đột. Từ 2026-08, trận boss KHÔNG còn mở BattleScene toàn màn - xem
## StageBoardScreen._mount_boss_battle() (đánh ngay trong %BattleViewHost).

signal stage_selected(stage: StageData)

const CARD_BG: Color = Color(0.19, 0.22, 0.29, 1)
const CARD_BORDER: Color = Color(0.3, 0.34, 0.43, 1)
const INFO_BOX_BG: Color = Color(0.05, 0.06, 0.09, 0.55)
const INFO_BOX_BORDER: Color = Color(0.25, 0.29, 0.38, 1)
const GOLD: Color = Color(0.95, 0.82, 0.55)
const MUTED: Color = Color(0.56, 0.6, 0.68)
const CTA_BG: Color = Color(0.82, 0.65, 0.28)
const CTA_TEXT: Color = Color(0.13, 0.1, 0.04)
const DIFF_EASY: Color = Color(0.56, 0.75, 0.56)
const DIFF_NORMAL: Color = Color(0.78, 0.72, 0.5)
const DIFF_HARD: Color = Color(0.78, 0.56, 0.56)

const DIFFICULTIES: Array[String] = ["easy", "normal", "hard"]
const DIFFICULTY_LABELS: Dictionary = {"easy": "DỄ", "normal": "THƯỜNG", "hard": "KHÓ"}
const DIFFICULTY_COLORS: Dictionary = {"easy": DIFF_EASY, "normal": DIFF_NORMAL, "hard": DIFF_HARD}

@onready var daily_panel: Control = %DailyPanel
@onready var world_panel: Control = %WorldPanel
@onready var daily_list: VBoxContainer = %DailyList
@onready var world_list: VBoxContainer = %WorldList

var _selected_difficulty: Dictionary = {} ## boss_id (int) -> "easy"/"normal"/"hard", mặc định "easy"

func _ready() -> void:
	_build_daily_cards()
	_build_world_cards()

## Gọi từ StageBoardScreen khi user bấm "BOSS NGÀY"/"BOSS KHỦNG" ở hàng
## sub-tab chung - panel mặc định lúc _ready() là daily_panel (xem .tscn).
func show_daily_tab() -> void:
	daily_panel.visible = true
	world_panel.visible = false

func show_world_tab() -> void:
	daily_panel.visible = false
	world_panel.visible = true

## ============================== Boss Ngày ==============================

func _build_daily_cards() -> void:
	for child in daily_list.get_children():
		child.queue_free()
	for boss in BossDatabase.get_all():
		if boss.is_world_boss:
			continue
		daily_list.add_child(_build_daily_card(boss))

func _build_daily_card(boss: BossData) -> PanelContainer:
	var difficulty: String = _selected_difficulty.get(boss.id, "easy")
	var stage := boss.get_stage(difficulty)

	var card := _styled_panel(CARD_BG, CARD_BORDER, 1, 10)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(_build_boss_header(boss, stage))

	var diff_title := Label.new()
	diff_title.text = "ĐỘ KHÓ"
	diff_title.add_theme_color_override("font_color", MUTED)
	diff_title.add_theme_font_size_override("font_size", 10)
	vbox.add_child(diff_title)
	vbox.add_child(_build_difficulty_row(boss, difficulty))

	if stage != null:
		vbox.add_child(_build_row_line("Phần thưởng", "💰 %d" % stage.reward_gold))

	var cta := Button.new()
	cta.text = "THÁCH ĐẤU"
	cta.custom_minimum_size = Vector2(0, 40)
	cta.disabled = stage == null
	cta.add_theme_color_override("font_color", CTA_TEXT)
	cta.add_theme_stylebox_override("normal", _flat_style(CTA_BG, CTA_BG, 0, 6))
	cta.add_theme_stylebox_override("hover", _flat_style(CTA_BG.lightened(0.1), CTA_BG, 0, 6))
	cta.add_theme_stylebox_override("pressed", _flat_style(CTA_BG.darkened(0.1), CTA_BG, 0, 6))
	if stage != null:
		cta.pressed.connect(_on_challenge_pressed.bind(stage))
	vbox.add_child(cta)

	return card

func _build_boss_header(boss: BossData, stage: StageData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon_badge := _styled_panel(Color(0.24, 0.26, 0.32), Color(0.4, 0.43, 0.51), 2, 8)
	icon_badge.custom_minimum_size = Vector2(48, 48)
	var icon_label := Label.new()
	icon_label.text = boss.boss_icon
	icon_label.add_theme_font_size_override("font_size", 22)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_badge.add_child(icon_label)
	row.add_child(icon_badge)

	var name_col := VBoxContainer.new()
	name_col.add_theme_constant_override("separation", 2)
	name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = boss.boss_name
	name_label.add_theme_color_override("font_color", GOLD)
	name_label.add_theme_font_size_override("font_size", 16)
	var type_label := Label.new()
	type_label.text = boss.level_label
	type_label.add_theme_color_override("font_color", MUTED)
	type_label.add_theme_font_size_override("font_size", 10)
	name_col.add_child(name_label)
	name_col.add_child(type_label)

	var enemy := _first_enemy(stage)
	if enemy != null:
		var stats_grid := GridContainer.new()
		stats_grid.columns = 2
		stats_grid.add_theme_constant_override("h_separation", 10)
		stats_grid.add_theme_constant_override("v_separation", 2)
		stats_grid.add_child(_mini_stat("❤️", str(enemy.hp)))
		stats_grid.add_child(_mini_stat("⚔", str(enemy.atk)))
		stats_grid.add_child(_mini_stat("🛡", str(enemy.def)))
		stats_grid.add_child(_mini_stat("✨", str(enemy.m_def)))
		name_col.add_child(stats_grid)

	row.add_child(name_col)
	return row

func _mini_stat(icon: String, value: String) -> Label:
	var label := Label.new()
	label.text = "%s %s" % [icon, value]
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 10)
	return label

func _build_difficulty_row(boss: BossData, current: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	for difficulty in DIFFICULTIES:
		var button := Button.new()
		button.text = DIFFICULTY_LABELS[difficulty]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 30)
		button.add_theme_font_size_override("font_size", 10)
		var is_active: bool = difficulty == current
		var tint: Color = DIFFICULTY_COLORS[difficulty] if is_active else MUTED
		var bg: Color = tint.darkened(0.75) if is_active else Color(0.16, 0.18, 0.22)
		button.add_theme_color_override("font_color", tint)
		button.add_theme_stylebox_override("normal", _flat_style(bg, tint if is_active else CARD_BORDER, 1, 5))
		button.add_theme_stylebox_override("hover", _flat_style(bg.lightened(0.1), tint if is_active else CARD_BORDER, 1, 5))
		button.pressed.connect(_on_difficulty_pressed.bind(boss.id, difficulty))
		row.add_child(button)
	return row

func _on_difficulty_pressed(boss_id: int, difficulty: String) -> void:
	_selected_difficulty[boss_id] = difficulty
	_build_daily_cards()

func _first_enemy(stage: StageData) -> LinhData:
	if stage == null or stage.enemy_troop_ids.is_empty():
		return null
	return TroopDatabase.get_by_id(stage.enemy_troop_ids[0])

func _build_row_line(label_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", MUTED)
	label.add_theme_font_size_override("font_size", 11)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", GOLD)
	value.add_theme_font_size_override("font_size", 15)
	row.add_child(label)
	row.add_child(value)
	return row

func _on_challenge_pressed(stage: StageData) -> void:
	stage_selected.emit(stage)

## ============================== Boss Khủng ==============================

func _build_world_cards() -> void:
	for child in world_list.get_children():
		child.queue_free()
	for boss in BossDatabase.get_all():
		if not boss.is_world_boss:
			continue
		world_list.add_child(_build_world_card(boss))

func _build_world_card(boss: BossData) -> PanelContainer:
	var stage := boss.get_stage("world")

	var card := _styled_panel(CARD_BG, Color(0.44, 0.33, 0.38), 1, 10)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(_build_boss_header(boss, stage))

	if stage != null:
		vbox.add_child(_build_row_line("Phần thưởng", "💰 %d" % stage.reward_gold))

	## Chưa có hệ lịch xuất hiện thật (chưa có backend hẹn giờ boss khủng) -
	## hiện tạm 1 dòng ghi chú, nút thách đấu vẫn LUÔN bấm được (trận đấu thật
	## qua BattleScene, không giả).
	var note := Label.new()
	note.text = "(Chưa có lịch xuất hiện thật - luôn thách đấu được)"
	note.add_theme_color_override("font_color", MUTED)
	note.add_theme_font_size_override("font_size", 9)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(note)

	var cta := Button.new()
	cta.text = "THÁCH ĐẤU"
	cta.custom_minimum_size = Vector2(0, 40)
	cta.disabled = stage == null
	cta.add_theme_color_override("font_color", CTA_TEXT)
	cta.add_theme_stylebox_override("normal", _flat_style(CTA_BG, CTA_BG, 0, 6))
	cta.add_theme_stylebox_override("hover", _flat_style(CTA_BG.lightened(0.1), CTA_BG, 0, 6))
	cta.add_theme_stylebox_override("pressed", _flat_style(CTA_BG.darkened(0.1), CTA_BG, 0, 6))
	if stage != null:
		cta.pressed.connect(_on_challenge_pressed.bind(stage))
	vbox.add_child(cta)

	return card

## MainShell gọi lại sau khi StageFlowController.stage_finished bắn ra - vẽ
## lại thẻ (đổi độ khó vẫn còn nguyên vì _selected_difficulty giữ ở biến
## instance, chỉ rebuild lại số liệu/nút).
func on_stage_finished(_stage: StageData, _won: bool) -> void:
	_build_daily_cards()
	_build_world_cards()

## ============================== Helper style ==============================

func _styled_panel(bg: Color, border: Color, border_width: int, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat_style(bg, border, border_width, radius))
	return panel

func _flat_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	return style
