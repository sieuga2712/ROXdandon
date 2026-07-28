class_name Projectile
extends Node2D

## Đạn bay từ người bắn tới mục tiêu (Cung thủ = mũi tên tĩnh xoay theo hướng
## bay, Phù thủy = hoạt ảnh phép thuật) - BattleScene spawn khi lính có
## character_key "archer"/"wizard" ra đòn, sát thương chỉ thật sự áp dụng lúc
## đạn TỚI NƠI (on_arrive callback) chứ không phải lúc bấm nút đánh, để né
## trường hợp mục tiêu đã chết bởi đòn khác trước khi đạn tới.

const SPEED: float = 600.0 ## px/giây - chưa có số liệu chính thức, chọn tạm để đạn bay có thể thấy được nhưng không quá chậm

@onready var static_visual: Sprite2D = $StaticVisual
@onready var animated_visual: AnimatedSprite2D = $AnimatedVisual

var _target_pos: Vector2
var _on_arrive: Callable

func setup_static(from: Vector2, to: Vector2, texture: Texture2D, on_arrive: Callable, visual_scale: float = 1.0) -> void:
	position = from
	_target_pos = to
	_on_arrive = on_arrive
	static_visual.texture = texture
	static_visual.visible = true
	static_visual.rotation = (to - from).angle()
	static_visual.scale *= visual_scale

func setup_animated(from: Vector2, to: Vector2, frames: SpriteFrames, anim: String, on_arrive: Callable) -> void:
	position = from
	_target_pos = to
	_on_arrive = on_arrive
	animated_visual.sprite_frames = frames
	animated_visual.visible = true
	animated_visual.play(anim)

func _process(delta: float) -> void:
	var to_target: Vector2 = _target_pos - position
	var step: float = SPEED * delta
	if to_target.length() <= step:
		position = _target_pos
		_on_arrive.call()
		queue_free()
		return
	position += to_target.normalized() * step
