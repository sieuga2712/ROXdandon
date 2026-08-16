# features/character

## Mục đích
Tab "Nhân vật" — danh sách + chi tiết đúng 4 thành viên party cố định (`GameState.PARTY_TROOP_IDS`). **KHÔNG phải hệ sưu tập/gacha** — game này không có chiêu mộ, không có cách thêm nhân vật mới.

## File chính
- `CharacterBoardScreen.gd` / `.tscn` — UI danh sách + chi tiết (trang bị thuần tượng trưng, chỉ số hiệu dụng theo cấp).

## Entry Point
`CharacterBoardScreen.gd` — instance bởi `core/app/MainShell.tscn`, id tab `character`.

## Public API
Không có API được module khác gọi vào — leaf UI screen thuần đọc dữ liệu qua `GameState`.

## Module được phép gọi
`core/app` (`GameState` — cấp độ, chỉ số hiệu dụng), `entities/troop` (`LinhData`, portrait/sprite thật).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Đội hình & Nhân vật/Đội hình cố định (Party).md`
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — mục "Tab Nhân vật" + "Hệ EXP/Cấp độ".
