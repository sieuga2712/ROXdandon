class_name StageData
extends Resource

## Mô tả 1 ải PvE. Thêm ải mới chỉ cần thêm 1 .tres trong data/stages/ -
## StageDatabase auto-scan thư mục đó, không cần sửa code.

@export var id: int = 0
@export var stage_name: String = ""
@export var time_limit: float = 120.0 ## giây - "2 phút" mặc định
@export var reward_gold: int = 1 ## cộng thẳng khi thắng - xem GameState.add_gold

## Quân địch cố định - 2 mảng song song (thay vì Array[Dictionary]) cho dễ sửa
## tay trong .tres: enemy_troop_ids[i] con quái loại LinhData.id nào,
## enemy_troop_counts[i] số lượng - mỗi con là 1 TroopUnit riêng biệt (không
## dồn chung thành 1 icon xN như bản city-builder cũ), BattleScene tự xếp vị
## trí trong đội hình bên địch (xem BattleScene._spawn_side).
@export var enemy_troop_ids: Array[int] = []
@export var enemy_troop_counts: Array[int] = []
