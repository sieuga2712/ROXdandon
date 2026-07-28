class_name DamagePopup
extends Node2D

## Số nhảy lên khi trúng đòn/hồi máu (BattleScene._spawn_damage_popup /
## _spawn_heal_popup) - tự bay lên + mờ dần rồi tự hủy, không cần ai dọn.

const RISE_DISTANCE: float = 40.0
const DURATION: float = 0.8

@onready var label: Label = $Label

func setup(text: String, color: Color, world_position: Vector2) -> void:
	position = world_position
	label.text = text
	label.add_theme_color_override("font_color", color)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, DURATION)
	tween.tween_property(label, "modulate:a", 0.0, DURATION * 0.6).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)
