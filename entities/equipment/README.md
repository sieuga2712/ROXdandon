# entities/equipment

## Mục đích
Contract dữ liệu cho hệ trang bị (2026-08-19, mới) — tách 2 khái niệm: `EquipmentTypeData` (1 LOẠI trang bị, VD "Kiếm") và `EquipmentItemData` (1 món CỤ THỂ đang sở hữu, có quality/tier/tinh luyện/cường hóa riêng, KHÔNG stack như nguyên liệu Kho). Dùng chung bởi `core/database` (nguồn tạo `EquipmentTypeData`), `core/app/GameState` (chủ sở hữu `equipment_inventory`/`equipped`), và `features/character` (UI mặc đồ).

## File chính
- `EquipmentTypeData.gd` — `class_name EquipmentTypeData extends RefCounted` (không phải Resource/.tres — 20 loại tạo thẳng bằng code trong `EquipmentTypeDatabase._ready()`, giống `MaterialData`). Field: `id`, `display_name`, `slot_type` (`Enums.EquipmentSlotType`), `combat_group` (`Enums.CombatGroup`), `tier_icon_paths`/`tier_icon_regions` (5 phần tử, T1..T5 — `tier_icon_regions` chỉ dùng khi icon cắt từ 1 spritesheet dùng chung như `Rings.png`). Hàm `get_tier_icon(tier)` tự load/cắt AtlasTexture đúng.
- `EquipmentItemData.gd` — `class_name EquipmentItemData extends RefCounted`, 1 món ĐANG SỞ HỮU: `instance_id` (duy nhất), `type_id` (tra `EquipmentTypeDatabase`), `quality`, `tier`, `refine_level`, `enhance_level`. Hàm `get_type()`/`get_icon()`/`get_display_name()` tiện tra cứu qua `type_id`.

## Entry Point
Không có class chính riêng — 2 kiểu dữ liệu (giống `StageData`), không có hành vi phức tạp ngoài vài hàm tiện ích tra cứu.

## Public API
```
EquipmentTypeData.get_tier_icon(tier: int) -> Texture2D

EquipmentItemData.get_type() -> EquipmentTypeData
EquipmentItemData.get_icon() -> Texture2D
EquipmentItemData.get_display_name() -> String
```

## Module được phép gọi
`EquipmentItemData.get_type()` gọi `EquipmentTypeDatabase` (autoload, `core/database`) — ngoài ra không phụ thuộc module nào khác trong project.

## Ai được gọi vào đây
`core/database/EquipmentTypeDatabase.gd` (tạo 20 `EquipmentTypeData`), `core/app/GameState.gd` (`equipment_inventory: Array[EquipmentItemData]`, `equipped: Dictionary`, các hàm `add_equipment_item`/`equip_item`/`get_owned_equipment_for_slot`...), `features/character/CharacterBoardScreen.gd` (UI chọn/mặc đồ), `features/character/EquipmentItemSlot.gd` (nhận `EquipmentItemData` gián tiếp qua các field icon/quality/tier/... để vẽ 1 ô).

## Tài liệu thiết kế liên quan
Chưa có tài liệu thiết kế riêng trong `ROX đần độn/` cho hệ trang bị — mới xây nền tảng qua trao đổi trực tiếp với người dùng (2026-08-19), xem `ROX đần độn/Quản lý dự án/Tiến độ & Việc còn dang dở.md` mục "Nhân vật" cho lịch sử quyết định.
