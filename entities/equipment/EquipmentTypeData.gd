class_name EquipmentTypeData
extends RefCounted

## 1 "LOẠI trang bị" (VD "Kiếm", "Áo giáp nhẹ", "Nhẫn bạc trơn") - KHÔNG phải
## 1 món trang bị CỤ THỂ đang sở hữu (xem EquipmentItemData cho item thật có
## quality/tier/tinh luyện/cường hóa riêng biệt, tham chiếu ngược lại type
## này qua type_id). Tạo thẳng bằng code trong
## EquipmentTypeDatabase._ready() (không phải Resource/.tres) - danh sách 20
## loại hoàn toàn đều đặn (mỗi loại đúng 5 icon theo tier T1..T5), giống
## MaterialData/MaterialDatabase.

var id: String = "" ## VD "kiem", "ao_giap_nhe" - duy nhất, xem EquipmentTypeDatabase
var display_name: String = ""
var slot_type: Enums.EquipmentSlotType = Enums.EquipmentSlotType.WEAPON
var combat_group: Enums.CombatGroup = Enums.CombatGroup.UNIVERSAL
var tier_icon_paths: Array[String] = [] ## đúng 5 phần tử, path ảnh cho T1..T5
var tier_icon_regions: Array[Rect2] = [] ## rỗng = dùng nguyên cả ảnh ở tier_icon_paths; có giá trị = cắt vùng trong 1 spritesheet dùng chung (VD Rings.png) - cùng chỉ số với tier_icon_paths

## Icon hiển thị cho 1 tier cụ thể (1..5) - tự cắt vùng (AtlasTexture) nếu
## tier_icon_regions có khai báo cho tier đó (dùng chung 1 spritesheet), nếu
## không thì trả nguyên texture đã load từ tier_icon_paths.
func get_tier_icon(tier: int) -> Texture2D:
	var idx: int = clampi(tier - 1, 0, tier_icon_paths.size() - 1)
	var base: Texture2D = load(tier_icon_paths[idx])
	if idx < tier_icon_regions.size() and tier_icon_regions[idx].size != Vector2.ZERO:
		var atlas := AtlasTexture.new()
		atlas.atlas = base
		atlas.region = tier_icon_regions[idx]
		return atlas
	return base
