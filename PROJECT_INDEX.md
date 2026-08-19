# PROJECT_INDEX.md

Bản đồ toàn bộ module — dùng để biết nên mở file nào trước. Chi tiết Public API xem README của từng module.

| Module | Entry Point | File chính | Phụ thuộc được phép |
|---|---|---|---|
| `core/app/` | `MainShell.gd` (main scene) | `MainShell.gd`, `ScreenRouter.gd`, `BottomNav.gd`, `GameState.gd` (autoload) | `core/database`, `entities/stage`, `entities/equipment` |
| `core/database/` | mỗi file 1 autoload độc lập | `TroopDatabase.gd`, `StageDatabase.gd`, `BossDatabase.gd`, `MapDatabase.gd`, `MaterialDatabase.gd`, `MaterialData.gd`, `EquipmentTypeDatabase.gd` | `entities/troop`, `entities/stage`, `entities/equipment` (kiểu dữ liệu trả về) |
| `core/shared/` | không có (thuần toolkit) | `UIBuilders.gd`, `UIConstants.gd`, `ScreenWipe.gd` | không phụ thuộc gì trong project |
| `core/config/` | không có (thuần hằng số) | `Enums.gd`, `ExpTables.gd` | không phụ thuộc gì trong project |
| `core/combat/` | không có (thuần công thức + hành vi nhân vật dùng chung) | `EncounterGenerator.gd`, `CombatResolver.gd`, `EquipmentDropTable.gd` | `CombatResolver` phụ thuộc `core/app`, `core/database`, `entities/troop`; `EncounterGenerator` không phụ thuộc gì; `EquipmentDropTable` phụ thuộc `core/config` (Enums) |
| `entities/troop/` | `TroopUnit.gd` | `TroopUnit.gd`, `LinhData.gd`, `Projectile.gd`, `ImpactEffect.gd`, `DamagePopup.gd` | `core/config` (Enums) |
| `entities/stage/` | `StageData.gd` | `StageData.gd` | không phụ thuộc gì trong project |
| `entities/equipment/` | không có (2 kiểu dữ liệu thuần) | `EquipmentTypeData.gd`, `EquipmentItemData.gd` | `EquipmentItemData.get_type()` gọi `core/database` (`EquipmentTypeDatabase`) |
| `features/city/` | `OverworldMap.gd` | `OverworldMap.gd`, `SimplePlaceholderPanel.gd`, `UpgraderPanel.gd`, `WarehousePanel.gd` | `core/app` (GameState), `core/database` (MaterialDatabase), `core/shared` |
| `features/stage/` | `StageBoardScreen.gd` | `StageBoardScreen.gd`, `StageFarmMap.gd`, `StageFarmWorld.gd`, `MapData.gd` | `core/app`, `core/database`, `core/combat`, `entities/troop`, `entities/stage`, `features/boss` (nhúng `BossBoardScreen` làm sub-tab thứ 3), `features/combat` (mở trận) |
| `features/boss/` | `BossBoardScreen.gd` (nhúng bởi `features/stage`, không còn instance trực tiếp bởi `core/app`) | `BossBoardScreen.gd`, `BossData.gd` | `core/database` (gồm `StageDatabase`), `features/combat` (mở trận, gián tiếp qua `features/stage` forward) |
| `features/character/` | `CharacterBoardScreen.gd` | `CharacterBoardScreen.gd`, `EquipmentIcon.gd`, `EquipmentItemSlot.gd` | `core/app` (GameState — túi đồ/mặc trang bị), `core/config` (Enums), `core/database` (`EquipmentTypeDatabase` gián tiếp), `entities/troop`, `entities/equipment` |
| `features/inventory/` | `InventoryScreen.gd` | `InventoryScreen.gd` | `core/app` (GameState), `core/database` (MaterialDatabase), `core/shared` |
| `features/combat/` | `StageFlowController.gd` (entry point tạm thời — xem README) | `StageFlowController.gd`, `BattleScene.gd` | `core/app`, `core/combat`, `entities/troop`, `entities/stage` |
| `legacy/` | — (không dùng, không instance ở đâu) | `Hub.tscn`, `StageSelectPanel.gd` | không áp dụng — không sửa nội dung |

## 5 tab UI thật của game (map sang module)

| Tab (`ScreenRouter` id) | Module |
|---|---|
| `city` (Thành) | `features/city` |
| `stage` (Ải: Ủy Thác + Treo máy + Ải Boss) | `features/stage` (sub-tab "Ải Boss" nhúng `features/boss`, không còn tab riêng - đổi 2026-08) |
| `character` (Nhân vật) | `features/character` |
| `inventory` (Kho) | `features/inventory` (thay thế vị trí tab `boss` cũ ở BottomNav) |
| `settings` (Cài đặt) | chưa tách module riêng — hiện là placeholder tĩnh trong `core/app` |

## `data/` (không phải module, resource thuần)

| Thư mục | Được quét bởi |
|---|---|
| `data/troops/` | `core/database/TroopDatabase.gd` |
| `data/stages/` | `core/database/StageDatabase.gd` |
| `data/maps/` | `core/database/MapDatabase.gd` |
| `data/bosses/` | `core/database/BossDatabase.gd` |

## Tài liệu thiết kế (lý do/ý tưởng, không phải code)

`ROX đần độn/` — xem `ROX đần độn/Mục lục.md` làm điểm vào.
