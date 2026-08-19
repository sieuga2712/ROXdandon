# core/database

## Mục đích
6 autoload dạng "kho tra cứu theo id" — mỗi file tự quét 1 thư mục trong `data/` lúc khởi động (`DirAccess`, không cần đăng ký thủ công), cho các module khác `get_by_id()`/`get_all()`. Không chứa logic gameplay.

## File chính
| File | Quét thư mục | Trả về kiểu |
|---|---|---|
| `TroopDatabase.gd` | `data/troops/` | `entities/troop/LinhData.gd` |
| `StageDatabase.gd` | `data/stages/` | `entities/stage/StageData.gd` |
| `BossDatabase.gd` | `data/bosses/` | `features/boss/BossData.gd` |
| `MapDatabase.gd` | `data/maps/` | `features/stage/MapData.gd` |
| `MaterialDatabase.gd` | quét `data/` theo category | `MaterialData.gd` (nằm ngay trong module này) |
| `EquipmentTypeDatabase.gd` | KHÔNG quét thư mục - 20 loại tạo thẳng bằng code (icon lấy từ `tainguyen/`, giống `MaterialDatabase`) | `entities/equipment/EquipmentTypeData.gd` |

## Entry Point
Không có 1 entry point chung — mỗi file là 1 autoload độc lập, gọi thẳng qua tên singleton (`TroopDatabase.get_by_id(5)`).

## Public API (đồng nhất giữa các database)
```
get_all() -> Array[<Data>]
get_by_id(id) -> <Data>
```
Riêng thêm: `StageDatabase.get_floors_for_map(map_id)`, `MaterialDatabase.get_by_category()/get_group_keys()/make_id()`, `EquipmentTypeDatabase.get_by_slot_and_group(slot_type, combat_group)`.

## Module được phép gọi
`entities/troop`, `entities/stage`, `entities/equipment` (kiểu `EquipmentTypeData`), `features/boss` (chỉ để biết kiểu `BossData`), `features/stage` (kiểu `MapData`) — chỉ để định nghĩa kiểu trả về, không gọi ngược logic của các module đó.

## Ai được gọi vào đây
Mọi `features/*` và `core/app` (`GameState`). Muốn thêm data mới: chỉ cần thả file `.tres` vào đúng thư mục `data/<loại>/`, không sửa code database.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — mục "Nguyên tắc dữ liệu mới" giải thích quy ước auto-scan.
- `ROX đần độn/Kiến trúc kỹ thuật/Quy ước code & Autoload.md`.
