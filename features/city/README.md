# features/city

## Mục đích
Tab "Thành" — lưới thẻ 3 thẻ đúng mockup `mockups/giao-dien-hien-tai.html` (#city), bấm thẻ mở panel shop tương ứng. KHÔNG có map/nhân vật đi lại (đã bỏ hẳn 2026-08, xem lịch sử Git nếu cần bản map+NPC cũ).

## File chính
- `OverworldMap.gd` / `.tscn` — controller chính của tab (dựng lưới thẻ bằng code trong `_build_grid()`), root scene được `core/app/MainShell.tscn` instance.
- `SimplePlaceholderPanel.gd` — panel placeholder dùng chung cho thẻ "Thợ rèn"/"Cửa hàng" (chưa có gameplay thật).
- `UpgraderPanel.gd` — panel nâng cấp (thẻ "Nâng cấp", đã có gameplay thật).
- `WarehousePanel.gd` — panel kho vật liệu - **thẻ "Kho báu" đã BỎ khỏi màn Thành (2026-08)**, file/node vẫn còn trong `.tscn` nhưng không còn cách mở từ UI (xem `features/inventory` - tab "Kho" ở BottomNav giờ là lối vào duy nhất, giao diện tương tự nhưng KHÔNG dùng chung class).

## Entry Point
`OverworldMap.gd` — instance bởi `core/app/MainShell.tscn`, id tab `city` trong `ScreenRouter`.

## Public API
Không có API được module khác gọi vào — đây là leaf UI screen, chỉ nhận điều hướng từ `core/app/ScreenRouter`.

## Module được phép gọi
`core/app` (`GameState` — vàng, vật liệu), `core/database` (`MaterialDatabase`), `core/shared` (UIBuilders/UIConstants).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Thành phố & Ải AFK-Farm.md` — lưu ý: phần "Ải AFK-Farm" trong file này đã SUPERSEDED, chỉ phần "Thành phố" còn đúng, xem `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` cho phần Ải hiện tại.
