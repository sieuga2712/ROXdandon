extends Node

## Autoload: 20 "loại trang bị" (không phải item cụ thể đang sở hữu, xem
## EquipmentItemData) - tạo thẳng bằng code trong _ready() (giống
## MaterialDatabase, danh sách hoàn toàn đều đặn: mỗi loại đúng 5 icon T1..T5)
## thay vì 20 file .tres tay. Icon lấy từ asset pack có sẵn trong tainguyen/ -
## đã soát/chọn tay theo loại nhưng gán tier CỐ Ý XẾP BỪA (không có ý nghĩa
## thẩm mỹ xếp hạng theo tier cụ thể), người dùng xác nhận không cần chỉnh kỹ.
##
## Ánh xạ slot -> loại theo CombatGroup (đã chốt với người dùng 2026-08-19):
## - WEAPON: kiếm(MELEE)/cung(RANGED_PHYSICAL)/trượng(RANGED_MAGIC)
## - OFFHAND: mũi tên(RANGED_PHYSICAL)/sách(RANGED_MAGIC) - khiên/ngọc có slot
##   riêng (SHIELD/GEM) dù cùng thuộc "vũ khí phụ" theo yêu cầu ban đầu
## - SHIELD: khiên(MELEE)
## - GEM: ngọc(RANGED_MAGIC)
## - ARMOR/SHOES: nhẹ(RANGED_MAGIC)/vừa(RANGED_PHYSICAL)/nặng(MELEE)
## - RING/CHARM/CLOAK/PANTS/GLOVES: UNIVERSAL (dùng chung mọi nhóm)

const TRANG_BI: String = "res://tainguyen/trang_bi/item%d.png"
const ICONS_FREE: String = "res://tainguyen/Icons_Free/32x32/sprites_outlined/tile%03d.png"
const GEM_DIR: String = "res://tainguyen/gem/item%d.png"
const KHAC_DIR: String = "res://tainguyen/khac/item%d.png"
const TRANSPERENT_DIR: String = "res://tainguyen/Transperent/Icon%d.png"
const RINGS_PATH: String = "res://tainguyen/Rings.png"
const RING_CELL: int = 16 ## Rings.png là spritesheet 7x7 ô 16x16, xem _add_ring()

var _by_id: Dictionary = {}
var _all: Array[EquipmentTypeData] = []

func _ready() -> void:
	_add("kiem", "Kiếm", Enums.EquipmentSlotType.WEAPON, Enums.CombatGroup.MELEE, _paths(TRANG_BI, [1, 3, 5, 7, 9]))
	_add("cung", "Cung", Enums.EquipmentSlotType.WEAPON, Enums.CombatGroup.RANGED_PHYSICAL, _paths(TRANG_BI, [186, 187, 188, 189, 190]))
	_add("truong", "Trượng", Enums.EquipmentSlotType.WEAPON, Enums.CombatGroup.RANGED_MAGIC, _paths(TRANG_BI, [131, 133, 136, 140, 142]))
	_add("mui_ten", "Mũi tên", Enums.EquipmentSlotType.OFFHAND, Enums.CombatGroup.RANGED_PHYSICAL, _paths(TRANG_BI, [22, 24, 25, 26, 28]))
	_add("sach", "Sách", Enums.EquipmentSlotType.OFFHAND, Enums.CombatGroup.RANGED_MAGIC, _paths(ICONS_FREE, [234, 235, 236, 237, 238]))
	_add("ngoc", "Ngọc", Enums.EquipmentSlotType.GEM, Enums.CombatGroup.RANGED_MAGIC, _paths(GEM_DIR, [541, 543, 544, 548, 555]))
	_add("khien", "Khiên", Enums.EquipmentSlotType.SHIELD, Enums.CombatGroup.MELEE, _paths(ICONS_FREE, [116, 117, 118, 119, 120]))
	_add("ao_giap_nhe", "Áo giáp nhẹ", Enums.EquipmentSlotType.ARMOR, Enums.CombatGroup.RANGED_MAGIC, _paths(ICONS_FREE, [156, 157, 161, 162, 163]))
	_add("ao_giap_vua", "Áo giáp vừa", Enums.EquipmentSlotType.ARMOR, Enums.CombatGroup.RANGED_PHYSICAL, _paths(ICONS_FREE, [158, 159, 166, 167, 173]))
	_add("ao_giap_nang", "Áo giáp nặng", Enums.EquipmentSlotType.ARMOR, Enums.CombatGroup.MELEE, _paths(TRANG_BI, [221, 223, 225, 227, 229]))
	_add("ao_khoac", "Áo khoác", Enums.EquipmentSlotType.CLOAK, Enums.CombatGroup.UNIVERSAL, _paths(KHAC_DIR, [875, 878, 880, 891, 904]))
	_add("giay_nhe", "Giày nhẹ", Enums.EquipmentSlotType.SHOES, Enums.CombatGroup.RANGED_MAGIC, _paths(TRANG_BI, [261, 262, 263, 264, 265]))
	_add("giay_vua", "Giày vừa", Enums.EquipmentSlotType.SHOES, Enums.CombatGroup.RANGED_PHYSICAL, _paths(TRANG_BI, [266, 267, 268, 269, 270]))
	_add("giay_nang", "Giày nặng", Enums.EquipmentSlotType.SHOES, Enums.CombatGroup.MELEE, _paths(ICONS_FREE, [169, 170, 171, 172, 176]))
	_add("quan", "Quần", Enums.EquipmentSlotType.PANTS, Enums.CombatGroup.UNIVERSAL, _paths(TRANG_BI, [241, 244, 247, 250, 253]))
	_add("gang", "Găng", Enums.EquipmentSlotType.GLOVES, Enums.CombatGroup.UNIVERSAL, _paths(TRANG_BI, [281, 282, 283, 291, 292]))
	_add_ring("nhan_bac_tron", "Nhẫn bạc trơn", 0)
	_add_ring("nhan_bac_da", "Nhẫn bạc đá", 1)
	_add_ring("nhan_vang_da", "Nhẫn vàng đá", 3)
	_add("bua_chu", "Bùa chú", Enums.EquipmentSlotType.CHARM, Enums.CombatGroup.UNIVERSAL, _paths(TRANSPERENT_DIR, [37, 38, 40, 41, 42]))

	for data in _all:
		_by_id[data.id] = data

func _paths(fmt: String, nums: Array) -> Array[String]:
	var arr: Array[String] = []
	for n in nums:
		arr.append(fmt % n)
	return arr

func _add(id: String, display_name: String, slot_type: Enums.EquipmentSlotType, combat_group: Enums.CombatGroup, tier_paths: Array[String]) -> void:
	var data := EquipmentTypeData.new()
	data.id = id
	data.display_name = display_name
	data.slot_type = slot_type
	data.combat_group = combat_group
	data.tier_icon_paths = tier_paths
	_all.append(data)

## Rings.png (spritesheet 7x7, ô 16x16) - `row` chọn 1 hàng làm 1 "loại", 5 ô
## ĐẦU của hàng đó dùng làm T1..T5 (không có ý nghĩa xếp hạng, xem ghi chú đầu file).
func _add_ring(id: String, display_name: String, row: int) -> void:
	var paths: Array[String] = []
	var regions: Array[Rect2] = []
	for col in range(5):
		paths.append(RINGS_PATH)
		regions.append(Rect2(col * RING_CELL, row * RING_CELL, RING_CELL, RING_CELL))
	var data := EquipmentTypeData.new()
	data.id = id
	data.display_name = display_name
	data.slot_type = Enums.EquipmentSlotType.RING
	data.combat_group = Enums.CombatGroup.UNIVERSAL
	data.tier_icon_paths = paths
	data.tier_icon_regions = regions
	_all.append(data)

func get_by_id(id: String) -> EquipmentTypeData:
	return _by_id.get(id)

func get_all() -> Array[EquipmentTypeData]:
	return _all

## Danh sách loại KHỚP đúng slot_type + phù hợp combat_group (UNIVERSAL luôn
## khớp mọi nhóm) - dùng để lọc trước khi lọc tiếp theo item ĐANG SỞ HỮU, xem
## GameState.get_owned_equipment_for_slot().
func get_by_slot_and_group(slot_type: Enums.EquipmentSlotType, combat_group: Enums.CombatGroup) -> Array[EquipmentTypeData]:
	return _all.filter(func(d: EquipmentTypeData) -> bool:
		return d.slot_type == slot_type and (d.combat_group == combat_group or d.combat_group == Enums.CombatGroup.UNIVERSAL)
	)
