extends Node

## Autoload singleton: trạng thái phiên chơi tối giản - vàng + party cố định.
## Không lưu file (chưa cần persistence ở bản này) - reset mỗi lần mở game.

## Party cố định 4 người (mở rộng sau) - id khớp LinhData.id trong
## data/troops/: 1=Soldier(tank, hp cao), 3=Archer, 4=Wizard, 9=Priest (cả 3
## đều troop_type ARCHER -> tầm đánh xa, đứng hậu phương không cần vào cận
## chiến - xem TroopUnit.attack_range_px). Priest là character_key DUY NHẤT
## biết hồi máu (xem BattleScene._priest_cast) nên bắt buộc phải có trong đội
## nếu muốn có khả năng hồi phục.
const PARTY_TROOP_IDS: Array[int] = [1, 3, 4, 9]

var gold: int = 0

func add_gold(amount: int) -> void:
	gold += amount
