class_name StageSelectPanel
extends Control

## Màn chọn ải - liệt kê động từ StageDatabase.get_all() để tự thêm nút khi có
## ải mới sau này, không cần sửa code ở đây.

signal stage_selected(stage: StageData)
signal closed

@onready var list_container: VBoxContainer = %StageSelectList
@onready var close_button: Button = %StageSelectCloseButton

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false; closed.emit())
	for stage in StageDatabase.get_all():
		var button := Button.new()
		button.text = stage.stage_name
		button.pressed.connect(func(): stage_selected.emit(stage))
		list_container.add_child(button)
	if list_container.get_child_count() == 0:
		list_container.add_child(UIBuilders.small_label("Chưa có ải nào"))

func open_panel() -> void:
	visible = true
