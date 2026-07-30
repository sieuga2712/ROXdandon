class_name PartyRosterPanel
extends HBoxContainer

## Bảng hiển thị 4 thành viên party trên OverworldMap - mỗi thẻ có 2 vùng bấm
## RIÊNG (không lồng nhau, tránh chồng vùng bấm): control_button (icon nhỏ)
## chuyển quyền điều khiển sang người đó, member_button (icon+tên) bật/tắt
## "đang theo" người đang điều khiển. Panel KHÔNG tự giữ trạng thái - chỉ phát
## signal ra ngoài rồi chờ OverworldWorld gọi lại refresh() để vẽ đúng theo
## state thật (đổi leader làm leader cũ tự bật "đang theo" - 1 hành động gây
## 2 thay đổi, để panel tự đoán dễ lệch).

signal control_requested(index: int)
signal follow_toggled(index: int)
signal recall_all_requested()

const CONTROLLED_TINT: Color = Color(1.0, 0.85, 0.3)

var _member_buttons: Array[Button] = []
var _control_buttons: Array[Button] = []

func _ready() -> void:
	var ids := GameState.PARTY_TROOP_IDS
	for i in range(ids.size()):
		var troop := TroopDatabase.get_by_id(ids[i])
		if troop == null:
			continue
		var card := VBoxContainer.new()

		var control_button := Button.new()
		control_button.text = "◎"
		control_button.tooltip_text = "Điều khiển %s" % troop.troop_name
		control_button.pressed.connect(_on_control_pressed.bind(i))
		card.add_child(control_button)
		_control_buttons.append(control_button)

		var member_button := Button.new()
		member_button.text = troop.troop_name
		member_button.icon = troop.sprite
		member_button.toggle_mode = true
		member_button.tooltip_text = "Bật/tắt đi theo"
		member_button.pressed.connect(_on_member_pressed.bind(i))
		card.add_child(member_button)
		_member_buttons.append(member_button)

		add_child(card)

	var recall_button := Button.new()
	recall_button.text = "Gọi tất cả"
	recall_button.pressed.connect(func(): recall_all_requested.emit())
	add_child(recall_button)

func _on_control_pressed(index: int) -> void:
	control_requested.emit(index)

func _on_member_pressed(index: int) -> void:
	follow_toggled.emit(index)

## OverworldWorld gọi lại mỗi khi leader/following đổi (kể cả tự động) - panel
## không tự suy đoán, luôn vẽ lại đúng theo dữ liệu thật truyền vào.
func refresh(party_units: Array[TroopUnit], leader: TroopUnit, following: Dictionary) -> void:
	for i in range(_member_buttons.size()):
		if i >= party_units.size():
			break
		var unit := party_units[i]
		var is_leader := unit == leader
		_member_buttons[i].button_pressed = following.get(unit, false)
		_member_buttons[i].modulate = CONTROLLED_TINT if is_leader else Color.WHITE
		_control_buttons[i].disabled = is_leader
