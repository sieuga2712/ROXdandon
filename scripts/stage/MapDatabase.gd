extends Node

## Autoload singleton: single source of truth for map data (tab "Vượt ải").
## Auto-scans MAPS_DIR for every .tres at startup - y hệt TroopDatabase/
## StageDatabase, thêm map mới chỉ cần thêm 1 .tres, không cần sửa code ở đây.

const MAPS_DIR: String = "res://data/maps/"

var _maps: Array[MapData] = []

func _ready() -> void:
	var file_names: Array[String] = []
	var dir := DirAccess.open(MAPS_DIR)
	if dir == null:
		push_error("MapDatabase: không mở được thư mục %s" % MAPS_DIR)
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
		var data := load(MAPS_DIR + name) as MapData
		if data != null:
			_maps.append(data)

func get_all() -> Array[MapData]:
	return _maps

func get_by_id(map_id: int) -> MapData:
	for data in _maps:
		if data.id == map_id:
			return data
	return null
