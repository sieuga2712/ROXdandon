class_name SimplePlaceholderPanel
extends Control

## Panel tạm cho NPC chưa có gameplay thật (Thợ Rèn/Giả Kim/Tinh Luyện) - chỉ
## hiện tên + mô tả vai trò, không bấm được gì thêm. Dùng lại 1 script cho cả
## 3 NPC này (setup() gọi từ OverworldMap._ready()) thay vì viết 3 script gần
## như giống hệt nhau. Toàn bộ cây node dựng bằng code trong _ready() (giống
## StageBoardScreen/CharacterBoardScreen) - .tscn chỉ cần 1 Control trống gắn
## script này, không cần soạn tay node con.

const CARD_BG: Color = Color(0.16, 0.18, 0.22)
const CARD_BORDER: Color = Color(0.3, 0.34, 0.43)
const GOLD: Color = Color(0.85, 0.7, 0.3)
const MUTED: Color = Color(0.65, 0.68, 0.73)

var _title_label: Label
var _desc_label: Label
var _npc_name: String = ""
var _description: String = ""

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	UIBuilders.inset_for_top_bottom_bars(self)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.12, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var outer_margin := MarginContainer.new()
	outer_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		outer_margin.add_theme_constant_override("margin_%s" % side, 20)
	add_child(outer_margin)

	var card := UIBuilders.bordered_card(CARD_BG, CARD_BORDER)
	outer_margin.add_child(card)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 12)
	card.add_child(outer_vbox)

	var header := UIBuilders.panel_header("", GOLD, func() -> void: visible = false)
	_title_label = header.get_child(1) as Label
	outer_vbox.add_child(header)

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(center)

	_desc_label = Label.new()
	_desc_label.custom_minimum_size = Vector2(360, 0)
	_desc_label.add_theme_color_override("font_color", MUTED)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(_desc_label)

	_title_label.text = _npc_name
	_desc_label.text = _description

func setup(npc_name: String, description: String) -> void:
	_npc_name = npc_name
	_description = description
	if _title_label != null:
		_title_label.text = npc_name
		_desc_label.text = description

func open() -> void:
	visible = true
