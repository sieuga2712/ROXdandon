class_name EquipmentIcon
extends Control

## Vẽ icon trang bị bằng NÉT NGOÀI (outline, không tô màu) qua _draw() - thay
## cho ký tự Unicode cũ (◆○⬡▲■▼◇●◈) ở CharacterBoardScreen, mỗi loại trang bị
## có hình dáng riêng dễ nhận dạng hơn, không phụ thuộc font có đủ glyph hay
## không. Toạ độ mỗi hình vẽ theo tỉ lệ 0..1 rồi nhân với `m` (cạnh ngắn hơn
## của Control) để tự co giãn đúng theo kích thước ô, không hardcode pixel.

enum Kind { WEAPON, RING, CHARM, HELMET, SHIELD, BOOTS, GLOVES, GEM, MISC_A, MISC_B, MISC_C }

@export var kind: Kind = Kind.WEAPON
@export var line_color: Color = Color(0.56, 0.6, 0.68)
@export var line_width: float = 2.0

func _draw() -> void:
	var m: float = minf(size.x, size.y)
	match kind:
		Kind.WEAPON:
			_draw_weapon(m)
		Kind.RING:
			_draw_ring(m)
		Kind.CHARM:
			_draw_charm(m)
		Kind.HELMET:
			_draw_helmet(m)
		Kind.SHIELD:
			_draw_shield(m)
		Kind.BOOTS:
			_draw_boots(m)
		Kind.GLOVES:
			_draw_gloves(m)
		Kind.GEM:
			_draw_gem(m)
		Kind.MISC_A:
			_draw_star(m)
		Kind.MISC_B:
			_draw_potion(m)
		Kind.MISC_C:
			_draw_scroll(m)

func _p(x: float, y: float, m: float) -> Vector2:
	return Vector2(x, y) * m

## Dao găm/kiếm ngắn: lưỡi + cán chữ thập + chuôi + núm tròn cuối chuôi.
func _draw_weapon(m: float) -> void:
	draw_line(_p(0.5, 0.05, m), _p(0.5, 0.6, m), line_color, line_width, true)
	draw_line(_p(0.28, 0.6, m), _p(0.72, 0.6, m), line_color, line_width, true)
	draw_line(_p(0.5, 0.6, m), _p(0.5, 0.82, m), line_color, line_width, true)
	draw_circle(_p(0.5, 0.88, m), 0.055 * m, line_color, false, line_width, true)

## Nhẫn: vòng tròn trơn - khác GEM (đa giác mặt cắt) để không lẫn 2 loại.
func _draw_ring(m: float) -> void:
	draw_circle(_p(0.5, 0.55, m), 0.28 * m, line_color, false, line_width, true)

## Bùa/mề đay: vòng đeo nhỏ trên đỉnh nối xuống thân lục giác.
func _draw_charm(m: float) -> void:
	draw_circle(_p(0.5, 0.18, m), 0.08 * m, line_color, false, line_width, true)
	draw_line(_p(0.42, 0.24, m), _p(0.35, 0.4, m), line_color, line_width, true)
	draw_line(_p(0.58, 0.24, m), _p(0.65, 0.4, m), line_color, line_width, true)
	draw_polyline(_hexagon(_p(0.5, 0.62, m), 0.26 * m), line_color, line_width, true)

## Nón/mũ giáp: vòm cung phía trên + vành ngang + gai nhỏ trên đỉnh.
func _draw_helmet(m: float) -> void:
	draw_arc(_p(0.5, 0.5, m), 0.32 * m, PI, TAU, 24, line_color, line_width, true)
	draw_line(_p(0.18, 0.5, m), _p(0.82, 0.5, m), line_color, line_width, true)
	draw_line(_p(0.5, 0.18, m), _p(0.5, 0.1, m), line_color, line_width, true)

## Khiên: ngũ giác đáy nhọn kiểu khiên cổ điển.
func _draw_shield(m: float) -> void:
	var pts := PackedVector2Array([
		_p(0.25, 0.15, m), _p(0.75, 0.15, m), _p(0.75, 0.5, m),
		_p(0.5, 0.88, m), _p(0.25, 0.5, m), _p(0.25, 0.15, m),
	])
	draw_polyline(pts, line_color, line_width, true)

## Giày/ủng: dáng chữ L nhìn nghiêng (ống + phần mũi giày).
func _draw_boots(m: float) -> void:
	var pts := PackedVector2Array([
		_p(0.4, 0.12, m), _p(0.62, 0.12, m), _p(0.62, 0.55, m),
		_p(0.85, 0.55, m), _p(0.85, 0.78, m), _p(0.22, 0.78, m),
		_p(0.22, 0.6, m), _p(0.4, 0.55, m), _p(0.4, 0.12, m),
	])
	draw_polyline(pts, line_color, line_width, true)

## Găng tay: hình chữ nhật lòng bàn tay + mấu ngón cái nhô bên trái.
func _draw_gloves(m: float) -> void:
	var pts := PackedVector2Array([
		_p(0.35, 0.18, m), _p(0.68, 0.18, m), _p(0.68, 0.78, m),
		_p(0.35, 0.78, m), _p(0.35, 0.52, m), _p(0.18, 0.52, m),
		_p(0.18, 0.34, m), _p(0.35, 0.34, m), _p(0.35, 0.18, m),
	])
	draw_polyline(pts, line_color, line_width, true)

## Đá quý: hình mặt cắt đa giác (đỉnh phẳng, đáy nhọn) + 2 đường vát mặt.
func _draw_gem(m: float) -> void:
	var pts := PackedVector2Array([
		_p(0.3, 0.28, m), _p(0.7, 0.28, m), _p(0.86, 0.48, m),
		_p(0.5, 0.86, m), _p(0.14, 0.48, m), _p(0.3, 0.28, m),
	])
	draw_polyline(pts, line_color, line_width, true)
	draw_line(_p(0.14, 0.48, m), _p(0.86, 0.48, m), line_color, line_width, true)
	draw_line(_p(0.3, 0.28, m), _p(0.5, 0.48, m), line_color, line_width, true)
	draw_line(_p(0.7, 0.28, m), _p(0.5, 0.48, m), line_color, line_width, true)

## 3 ô phụ kiện chưa rõ loại - chỉ cần khác nhau: ngôi sao/bình thuốc/cuộn giấy.
func _draw_star(m: float) -> void:
	var pts := PackedVector2Array()
	var center := _p(0.5, 0.52, m)
	for i in range(11):
		var r: float = 0.36 * m if i % 2 == 0 else 0.15 * m
		var angle: float = deg_to_rad(-90 + i * 36)
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_polyline(pts, line_color, line_width, true)

func _draw_potion(m: float) -> void:
	draw_line(_p(0.42, 0.12, m), _p(0.42, 0.32, m), line_color, line_width, true)
	draw_line(_p(0.58, 0.12, m), _p(0.58, 0.32, m), line_color, line_width, true)
	draw_line(_p(0.42, 0.12, m), _p(0.58, 0.12, m), line_color, line_width, true)
	var pts := PackedVector2Array([
		_p(0.42, 0.32, m), _p(0.22, 0.62, m), _p(0.22, 0.82, m),
		_p(0.78, 0.82, m), _p(0.78, 0.62, m), _p(0.58, 0.32, m),
	])
	draw_polyline(pts, line_color, line_width, true)

func _draw_scroll(m: float) -> void:
	draw_circle(_p(0.22, 0.22, m), 0.09 * m, line_color, false, line_width, true)
	draw_circle(_p(0.78, 0.78, m), 0.09 * m, line_color, false, line_width, true)
	var pts := PackedVector2Array([
		_p(0.22, 0.22, m), _p(0.78, 0.22, m), _p(0.78, 0.78, m), _p(0.22, 0.78, m), _p(0.22, 0.22, m),
	])
	draw_polyline(pts, line_color, line_width, true)

func _hexagon(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(7):
		var angle: float = deg_to_rad(60 * i - 30)
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	return pts
