# core/app

## Mục đích
Vỏ ứng dụng: main scene, điều hướng 5 tab, và `GameState` — autoload trung tâm giữ toàn bộ tiến độ người chơi (vàng, cấp độ, tầng đã qua, team treo máy, vật liệu).

## File chính
- `MainShell.gd` / `.tscn` — main scene (`run/main_scene`), gating tương tác khi `BattleScene` đang mở.
- `ScreenRouter.gd` — chuyển tab, data-driven theo tên node con.
- `BottomNav.gd` / `.tscn` — thanh nav 5 tab, 2 trạng thái thu gọn/mở rộng.
- `GameState.gd` — autoload, không có `class_name` (truy cập qua singleton `GameState`).

## Entry Point
`MainShell.tscn` (main scene của toàn app). `GameState` là autoload — truy cập trực tiếp qua tên singleton `GameState.xxx()` từ bất kỳ đâu, không cần preload.

## Public API (GameState — phần hay dùng nhất)
```
add_gold(amount) / report_floor_cleared(map_id, floor) / get_highest_floor(map_id)
grant_kill_exp(troop_ids, amount) / get_base_level(troop_id) / get_job_level(troop_id)
effective_hp/atk/def/m_def(troop_id, base_value)
has_idle_team() / is_troop_idling(troop_id) / start_idle_team(stage_id, member_ids) / stop_idle_team() / get_idle_farm_map()
get_material_count(id) / add_material(id, amount) / remove_material(id, amount) / merge_material_up(group_key, tier)
```

## Module được phép gọi
`core/database` (đọc dữ liệu), `entities/stage` (kiểu `StageData` dùng trong `start_idle_team`/`get_idle_farm_map`).

## Ai được gọi vào đây
Mọi `features/*` đều được gọi `GameState`. Không module nào được đọc field nội bộ của `GameState` mà không qua hàm public ở trên.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Giao diện/Vỏ ứng dụng Portrait (MainShell & Navigation).md` — kiến trúc MainShell/ScreenRouter/BottomNav.
- `ROX đần độn/Thiết kế Game/Kinh tế/Vàng (GameState).md` — thiết kế hệ vàng.
- `ROX đần độn/Kiến trúc kỹ thuật/Quy ước code & Autoload.md` — quy ước autoload (lưu ý: viết lúc project chỉ có 3 autoload, nay đã 6, đọc phần "data-driven" vẫn đúng).
