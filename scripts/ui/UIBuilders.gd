class_name UIBuilders
extends RefCounted

## Small reusable node-builders for UI trees assembled via `.new()` instead of
## scenes - keeps repeated TextureRect sizing/stretch setup and label styling
## in one place instead of copy-pasted across panels.

static func texture_icon(texture: Texture2D, size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon

static func small_label(text: String, font_size: int = 12) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.text = text
	return label
