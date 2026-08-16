class_name Enums
extends RefCounted

## Mục 4 trong thiết kế - cả 2 loại lính dùng chung 1 bộ chỉ số base (xem
## LinhData), chỉ khác hệ sát thương (DamageType) và tầm đánh.
enum TroopType {
	NORMAL, ## Cận chiến
	ARCHER, ## Đánh xa (cung/phép)
}

## Lính cận chiến gây sát thương vật lý (chống bằng DEF), lính đánh xa gây sát
## thương phép (chống bằng M.DEF).
enum DamageType {
	PHYSICAL,
	MAGIC,
}

## Phe trong 1 trận đấu - xem TroopUnit/BattleScene.
enum Team {
	PLAYER,
	ENEMY,
}
