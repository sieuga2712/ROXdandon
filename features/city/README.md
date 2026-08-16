# features/city

## Mục đích
Tab "Thành" — màn hình thuần trang trí/xem, không điều khiển được nhân vật, chứa các panel shop (nâng cấp, kho).

## File chính
- `OverworldMap.gd` / `.tscn` — controller chính của tab, root scene được `core/app/MainShell.tscn` instance.
- `OverworldWorld.gd` — world 2D bên trong (hiển thị nhà/NPC, chọn đơn vị kiểu RTS — không liên quan combat).
- `SimplePlaceholderPanel.gd` — panel placeholder dùng chung trong tab này.
- `UpgraderPanel.gd` — panel nâng cấp.
- `WarehousePanel.gd` — panel kho vật liệu.

## Entry Point
`OverworldMap.gd` — instance bởi `core/app/MainShell.tscn`, id tab `city` trong `ScreenRouter`.

## Public API
Không có API được module khác gọi vào — đây là leaf UI screen, chỉ nhận điều hướng từ `core/app/ScreenRouter`.

## Module được phép gọi
`core/app` (`GameState` — vàng, vật liệu), `core/database` (`MaterialDatabase`), `core/shared` (UIBuilders/UIConstants).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Thành phố & Ải AFK-Farm.md` — lưu ý: phần "Ải AFK-Farm" trong file này đã SUPERSEDED, chỉ phần "Thành phố" còn đúng, xem `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` cho phần Ải hiện tại.
