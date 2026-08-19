# features/character

## Mục đích
Tab "Nhân vật" — danh sách + chi tiết đúng 4 thành viên party cố định (`GameState.PARTY_TROOP_IDS`). **KHÔNG phải hệ sưu tập/gacha** — game này không có chiêu mộ, không có cách thêm nhân vật mới.

## File chính
- `CharacterBoardScreen.gd` / `.tscn` — UI danh sách + chi tiết. Ô trang bị (2026-08-19) giờ THẬT: bấm 1 ô mở bảng chọn trang bị cùng loại + phù hợp `CombatGroup` trong túi đồ (`GameState.equipment_inventory`), bấm để mặc — giống AFK Arena (xem `_equipment_slot()`/`_open_equip_select()`).
- `EquipmentIcon.gd` — vẽ icon nét ngoài (outline, `_draw()` thuần, không dùng ảnh) qua enum `Kind`, dùng làm PLACEHOLDER cho ô CHƯA mặc gì (xem `_equipment_slot()`).
- `EquipmentItemSlot.gd` — `class_name EquipmentItemSlot extends PanelContainer`, ô trang bị THẬT (icon ảnh + viền màu theo `Enums.EquipmentQuality` + huy hiệu góc tier/tinh luyện/cường hóa, xem docstring đầu file). Dùng cho cả ô ĐÃ mặc trên `CharacterBoardScreen` lẫn lưới chọn trong bảng chọn trang bị.

## Lưu ý phụ thuộc ngược
`core/combat/EquipmentDropTable.gd` (công thức xác suất rớt trang bị) cần dùng CHUNG enum chất lượng với `EquipmentItemSlot.gd` ở đây, nhưng `core/*` không được import ngược `features/*` — nên enum thật nằm ở `core/config/Enums.gd` (`Enums.EquipmentQuality`, cùng `Enums.CombatGroup`/`Enums.EquipmentSlotType`), `EquipmentItemSlot.gd` chỉ tham chiếu tới, không tự khai báo riêng.

## Entry Point
`CharacterBoardScreen.gd` — instance bởi `core/app/MainShell.tscn`, id tab `character`.

## Public API
Không có API được module khác gọi vào — leaf UI screen thuần đọc/ghi qua `GameState`.

## Module được phép gọi
`core/app` (`GameState` — cấp độ, chỉ số hiệu dụng, túi đồ/mặc trang bị), `core/database` (`EquipmentTypeDatabase` gián tiếp qua `EquipmentItemData.get_type()`), `entities/troop` (`LinhData`, portrait/sprite thật), `entities/equipment` (`EquipmentItemData`).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Đội hình & Nhân vật/Đội hình cố định (Party).md`
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — mục "Tab Nhân vật" + "Hệ EXP/Cấp độ".
