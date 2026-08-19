class_name EquipmentItemData
extends RefCounted

## 1 món trang bị CỤ THỂ đang sở hữu (xem GameState.equipment_inventory) -
## KHÔNG stack/gộp như nguyên liệu Kho, mỗi món có instance_id ĐỘC LẬP dù
## trùng type_id/quality/tier với món khác. Trỏ tới EquipmentTypeData qua
## type_id (tên loại, icon, slot, combat_group) - phần RIÊNG của TỪNG món chỉ
## có quality/tier/tinh luyện/cường hóa.

var instance_id: String = "" ## duy nhất, xem GameState._new_equipment_instance_id()
var type_id: String = "" ## khớp EquipmentTypeData.id, tra qua EquipmentTypeDatabase.get_by_id()
var quality: Enums.EquipmentQuality = Enums.EquipmentQuality.WHITE
var tier: int = 1 ## 1..5 - xem EquipmentDropTable.roll_tier()
var refine_level: int = 0 ## cấp tinh luyện - số La Mã, 0 = chưa tinh luyện
var enhance_level: int = 0 ## cấp cường hóa - số thường, 0 = chưa cường hóa

func get_type() -> EquipmentTypeData:
	return EquipmentTypeDatabase.get_by_id(type_id)

func get_icon() -> Texture2D:
	var type_data := get_type()
	return type_data.get_tier_icon(tier) if type_data != null else null

func get_display_name() -> String:
	var type_data := get_type()
	return type_data.display_name if type_data != null else "?"
