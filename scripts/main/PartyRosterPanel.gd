class_name PartyRosterPanel
extends HBoxContainer

## Bảng hiển thị 4 thành viên party trên OverworldMap - bấm 1 thẻ để chọn
## người đó làm "leader" (người điều khiển trực tiếp bằng click trên bản đồ,
## xem OverworldWorld.select_leader). 4 nút dùng chung 1 ButtonGroup nên Godot
## tự đảm bảo luôn có đúng 1 nút đang bấm - không cần tự quản lý trạng thái
## chọn tay.

signal leader_selected(index: int)

var _button_group := ButtonGroup.new()

func _ready() -> void:
	var ids := GameState.PARTY_TROOP_IDS
	for i in range(ids.size()):
		var troop := TroopDatabase.get_by_id(ids[i])
		if troop == null:
			continue
		var button := Button.new()
		button.text = troop.troop_name
		button.icon = troop.sprite
		button.toggle_mode = true
		button.button_group = _button_group
		button.button_pressed = i == 0 ## mặc định leader = thành viên đầu tiên, khớp OverworldWorld._spawn_party()
		button.pressed.connect(_on_button_pressed.bind(i))
		add_child(button)

func _on_button_pressed(index: int) -> void:
	leader_selected.emit(index)
