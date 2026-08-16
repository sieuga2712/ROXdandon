class_name StageData
extends Resource

## Mô tả 1 ải PvE. Thêm ải mới chỉ cần thêm 1 .tres trong data/stages/ -
## StageDatabase auto-scan thư mục đó, không cần sửa code.

@export var id: int = 0
@export var stage_name: String = ""
@export var time_limit: float = 120.0 ## giây - "2 phút" mặc định
@export var reward_gold: int = 1 ## cộng thẳng khi thắng - xem GameState.add_gold

## Tab "Vượt ải" (bảng uỷ thác): mỗi tầng = 1 StageData, thuộc đúng 1 map
## (khớp MapData.id) và có số tầng riêng - StageDatabase.get_floors_for_map()
## lọc/sort theo 2 field này, GameState.highest_floor_cleared theo dõi tiến
## độ mở khoá tầng kế tiếp.
@export var map_id: int = 0
@export var floor_number: int = 1 ## đặt tên "floor_number" không phải "floor" - "floor" trùng tên hàm toán học built-in của GDScript, dễ gây shadowing khó lường

## Quân địch cố định - 2 mảng song song (thay vì Array[Dictionary]) cho dễ sửa
## tay trong .tres: enemy_troop_ids[i] con quái loại LinhData.id nào,
## enemy_troop_counts[i] số lượng - mỗi con là 1 TroopUnit riêng biệt (không
## dồn chung thành 1 icon xN như bản city-builder cũ), BattleScene tự xếp vị
## trí trong đội hình bên địch (xem BattleScene._spawn_side).
@export var enemy_troop_ids: Array[int] = []
@export var enemy_troop_counts: Array[int] = []

## Chỉ dùng cho ải Boss (BattleScene) - số đợt quái thường NGẪU NHIÊN (xem
## EncounterGenerator) xuất hiện TRƯỚC đợt boss thật (enemy_troop_ids ở trên
## luôn là đợt CUỐI CÙNG). Không liên quan floor_number (ải Boss không có khái
## niệm tầng) - map thủ công theo độ khó Dễ/Thường/Khó lúc author data.
@export var boss_trash_wave_count: int = 3
@export var boss_trash_monster_level: int = 1
