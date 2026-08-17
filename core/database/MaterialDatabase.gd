extends Node

## Autoload singleton: danh sách 50 nguyên liệu (10 nhóm x 5 cấp, xem
## assets/materials/<group_key>/cap<N>.png - đã chọn/viền màu cấp sẵn từ
## tainguyen/bo_chon_vien). Tạo thẳng bằng code lúc _ready() thay vì 50 file
## .tres vì cấu trúc hoàn toàn đều đặn (xem MaterialData.gd).

## category: "da_cuong_hoa" | "thuc_vat" | "gem" | "quang" - dùng để lọc theo
## tab (VD UpgraderPanel chỉ lấy "quang"/"gem").
const GROUPS: Array[Dictionary] = [
	{"key": "da_cuong_hoa", "name": "Đá Cường Hóa", "category": "da_cuong_hoa"},
	{"key": "thuc_vat_loai1_bach_hoa", "name": "Bạch Hoa", "category": "thuc_vat"},
	{"key": "thuc_vat_loai2_hong_hoa", "name": "Hồng Hoa", "category": "thuc_vat"},
	{"key": "thuc_vat_loai3_hoang_hoa", "name": "Hoàng Hoa", "category": "thuc_vat"},
	{"key": "gem_loai1_bang_ngoc", "name": "Băng Ngọc", "category": "gem"},
	{"key": "gem_loai2_hac_ngoc", "name": "Hắc Ngọc", "category": "gem"},
	{"key": "gem_loai3_hoa_ngoc", "name": "Hỏa Ngọc", "category": "gem"},
	{"key": "quang_nguyenlieu_loai1_bang_thach", "name": "Băng Thạch", "category": "quang"},
	{"key": "quang_nguyenlieu_loai2_hoa_thach", "name": "Hỏa Thạch", "category": "quang"},
	{"key": "quang_nguyenlieu_loai3_tho_thach", "name": "Thổ Thạch", "category": "quang"},
]

const ICON_DIR: String = "res://assets/materials/"
const MAX_TIER: int = 5

var _materials: Array[MaterialData] = []

func _ready() -> void:
	for group in GROUPS:
		for tier in range(1, MAX_TIER + 1):
			var mat := MaterialData.new()
			mat.id = "%s_cap%d" % [group["key"], tier]
			mat.group_key = group["key"]
			mat.group_name = group["name"]
			mat.category = group["category"]
			mat.tier = tier
			mat.display_name = "%s cấp %d" % [group["name"], tier]
			mat.icon = load("%s%s/cap%d.png" % [ICON_DIR, group["key"], tier])
			_materials.append(mat)

func get_all() -> Array[MaterialData]:
	return _materials

func get_by_id(id: String) -> MaterialData:
	for mat in _materials:
		if mat.id == id:
			return mat
	return null

func get_by_category(category: String) -> Array[MaterialData]:
	return _materials.filter(func(m: MaterialData) -> bool: return m.category == category)

## Danh sách group_key thuộc 1 category, theo đúng thứ tự khai báo trong GROUPS.
func get_group_keys(category: String) -> Array[String]:
	var keys: Array[String] = []
	for group in GROUPS:
		if group["category"] == category:
			keys.append(group["key"])
	return keys

func make_id(group_key: String, tier: int) -> String:
	return "%s_cap%d" % [group_key, tier]

## Chọn ngẫu nhiên 1 nguyên liệu CẤP 1 (đều trong 10 nhóm) - dùng cho tỉ lệ
## rơi đồ khi hạ quái, xem StageFarmWorld/BattleScene._apply_damage().
func random_tier1_id() -> String:
	return make_id(GROUPS.pick_random()["key"], 1)
