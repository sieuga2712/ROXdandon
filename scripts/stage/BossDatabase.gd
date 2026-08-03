extends Node

## Autoload singleton: single source of truth for boss data (tab "Boss").
## Auto-scans BOSSES_DIR for every .tres at startup - y hệt MapDatabase/
## StageDatabase, thêm boss mới chỉ cần thêm 1 .tres, không cần sửa code ở đây.

const BOSSES_DIR: String = "res://data/bosses/"

var _bosses: Array[BossData] = []

func _ready() -> void:
	var file_names: Array[String] = []
	var dir := DirAccess.open(BOSSES_DIR)
	if dir == null:
		push_error("BossDatabase: không mở được thư mục %s" % BOSSES_DIR)
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
		var data := load(BOSSES_DIR + name) as BossData
		if data != null:
			_bosses.append(data)

func get_all() -> Array[BossData]:
	return _bosses

func get_by_id(boss_id: int) -> BossData:
	for data in _bosses:
		if data.id == boss_id:
			return data
	return null
