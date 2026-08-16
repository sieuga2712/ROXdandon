extends Node

## Autoload singleton: single source of truth for stage (ải) data. Auto-scans
## STAGES_DIR for every .tres at startup, so a new ải only needs a new .tres
## file, no code change here.

const STAGES_DIR: String = "res://data/stages/"

var _stages: Array[StageData] = []

func _ready() -> void:
	var file_names: Array[String] = []
	var dir := DirAccess.open(STAGES_DIR)
	if dir == null:
		push_error("StageDatabase: không mở được thư mục %s" % STAGES_DIR)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	file_names.sort() ## thứ tự file cố định, không tùy hệ điều hành
	for name in file_names:
		var data := load(STAGES_DIR + name) as StageData
		if data != null:
			_stages.append(data)

func get_all() -> Array[StageData]:
	return _stages

func get_by_id(stage_id: int) -> StageData:
	for data in _stages:
		if data.id == stage_id:
			return data
	return null

## Tab "Vượt ải": danh sách tầng của 1 map, sort theo floor_number tăng dần -
## StageBoardScreen dùng để vẽ list tầng + tính khoá/mở theo
## GameState.get_highest_floor().
func get_floors_for_map(map_id: int) -> Array[StageData]:
	## KHÔNG gán trực tiếp kết quả .filter() (Array trần) vào biến Array[StageData]
	## - lỗi với custom class_name (đã xác nhận thật với TroopUnit, xem "Lỗi đã
	## gặp & Bài học" trong vault). Dùng append_array() luôn an toàn.
	var floors: Array[StageData] = []
	floors.append_array(_stages.filter(func(s: StageData) -> bool: return s.map_id == map_id))
	floors.sort_custom(func(a: StageData, b: StageData) -> bool: return a.floor_number < b.floor_number)
	return floors
