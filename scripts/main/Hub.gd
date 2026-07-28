extends Control

## Màn hình gốc (run/main_scene) - thay cho thành phố cũ. Chỉ hiện party cố
## định + vàng hiện có + nút "Chọn ải". Việc nối StageSelectPanel/BattleScene
## nằm ở StageFlowController.gd (node con).

@onready var party_roster: HBoxContainer = %PartyRoster
@onready var gold_label: Label = %GoldLabel

func _ready() -> void:
	for troop_id in GameState.PARTY_TROOP_IDS:
		var troop := TroopDatabase.get_by_id(troop_id)
		if troop == null:
			continue
		var card := VBoxContainer.new()
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(UIBuilders.texture_icon(troop.sprite, UIConstants.TROOP_ICON_SIZE))
		card.add_child(UIBuilders.small_label(troop.troop_name))
		party_roster.add_child(card)

func _process(_delta: float) -> void:
	gold_label.text = "Vàng: %d" % GameState.gold
