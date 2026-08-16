class_name ImpactEffect
extends Node2D

## Hiệu ứng phát 1 lần ngay tại vị trí mục tiêu (khác Projectile - không bay,
## không có điểm xuất phát/đích, chỉ "hiện ra rồi biến mất") - dùng cho
## Priest: niệm phép xong hiệu ứng hiện thẳng lên mục tiêu, không có đường đạn.

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup(world_position: Vector2, frames: SpriteFrames, anim: String) -> void:
	position = world_position
	sprite.sprite_frames = frames
	sprite.play(anim)
	sprite.animation_finished.connect(queue_free)
