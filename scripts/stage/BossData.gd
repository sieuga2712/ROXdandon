class_name BossData
extends Resource

## Mô tả 1 boss trong tab "Boss". Boss Ngày (is_world_boss=false) có 3 độ khó
## Dễ/Thường/Khó, mỗi độ khó là 1 StageData riêng (đổi độ khó trên thẻ = đổi
## StageData nào sẽ gửi cho BattleScene lúc bấm "Thách đấu"). Boss Khủng
## (is_world_boss=true) chỉ có 1 StageData duy nhất qua stage_id_world. Thêm
## boss mới chỉ cần thêm 1 .tres trong data/bosses/ - BossDatabase auto-scan
## thư mục đó, không cần sửa code.
##
## HP/ATK/DEF hiển thị trên thẻ boss LẤY THẲNG từ LinhData của quái đầu tiên
## trong StageData tương ứng (xem BossBoardScreen._boss_preview_stats) - không
## có bộ số liệu riêng ở đây, tránh 2 nơi giữ cùng 1 dữ liệu.

@export var id: int = 0
@export var boss_name: String = ""
@export var boss_icon: String = "🐉"
@export var level_label: String = "" ## VD "Lv.50 · Boss Ngày" - thuần hiển thị, không dùng để tính toán
@export var is_world_boss: bool = false

## Boss Ngày dùng 3 field này (trỏ id trong StageDatabase) - Boss Khủng dùng
## stage_id_world - field không dùng tới cứ để -1.
@export var stage_id_easy: int = -1
@export var stage_id_normal: int = -1
@export var stage_id_hard: int = -1
@export var stage_id_world: int = -1

func get_stage(difficulty: String) -> StageData:
	var stage_id: int = -1
	match difficulty:
		"easy": stage_id = stage_id_easy
		"normal": stage_id = stage_id_normal
		"hard": stage_id = stage_id_hard
		"world": stage_id = stage_id_world
	if stage_id < 0:
		return null
	return StageDatabase.get_by_id(stage_id)
