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

## Chất lượng trang bị - thứ tự thấp -> cao: Trắng < Lam < Tím < Vàng < Cam-đỏ.
## Đặt ở core/config (không phải features/character) vì core/combat
## (EquipmentDropTable) cũng cần dùng - core/* không được phép import ngược
## features/* (xem CLAUDE.md), nên enum dùng chung phải nằm ở core.
enum EquipmentQuality {
	WHITE,
	BLUE,
	PURPLE,
	GOLD,
	ORANGE,
}

## Nhóm chiến đấu - quyết định 1 loại trang bị MẶC ĐƯỢC cho nhân vật nào (xem
## EquipmentTypeData.combat_group, GameState.get_combat_group_for_troop()).
## UNIVERSAL = mọi nhóm đều dùng được (nhẫn/bùa/áo khoác/quần/găng - không
## phân biệt lối đánh).
enum CombatGroup {
	MELEE, ## cận chiến (Soldier)
	RANGED_PHYSICAL, ## đánh xa vật lý (Archer)
	RANGED_MAGIC, ## đánh xa phép (Wizard, Priest)
	UNIVERSAL,
}

## 11 vị trí trang bị trên nhân vật (khớp `CharacterBoardScreen`'s
## EQUIP_SLOTS_LEFT/RIGHT/BOTTOM) - xem EquipmentTypeData.slot_type.
enum EquipmentSlotType {
	WEAPON, ## vũ khí chính - kiếm/cung/trượng theo CombatGroup
	OFFHAND, ## vũ khí phụ - mũi tên/sách (khiên/ngọc có slot riêng, xem SHIELD/GEM)
	RING,
	CHARM,
	SHIELD,
	SHOES,
	GLOVES,
	GEM,
	ARMOR,
	CLOAK,
	PANTS,
}
