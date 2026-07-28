extends Node

## Autoload singleton: single source of truth for troop type data. Auto-scans
## TROOPS_DIR for every .tres at startup, so a new troop type only needs a
## new .tres file, no code change here.

const TROOPS_DIR: String = "res://data/troops/"

var _troops: Array[LinhData] = []

func _ready() -> void:
	var file_names: Array[String] = []
	var dir := DirAccess.open(TROOPS_DIR)
	if dir == null:
		push_error("TroopDatabase: không mở được thư mục %s" % TROOPS_DIR)
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
		var data := load(TROOPS_DIR + name) as LinhData
		if data != null:
			_troops.append(data)

func get_all() -> Array[LinhData]:
	return _troops

func get_by_id(troop_id: int) -> LinhData:
	for data in _troops:
		if data.id == troop_id:
			return data
	return null
