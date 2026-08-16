# features/stage

## Mục đích
Tab "Ải" — 3 sub-tab: **Ủy Thác** (đánh tay, mở khoá tầng), **Treo máy** (idle, 1 trận đấu thật chạy nền liên tục khi app mở), và **Ải Boss** (2026-08 gộp vào từ `features/boss`, không còn là tab riêng ở BottomNav).

## File chính
- `StageBoardScreen.gd` / `.tscn` — UI chính của tab, cả 3 sub-tab. Sub-tab "Ải Boss" (`%BossPanel`) là instance của `features/boss/BossBoardScreen.tscn` được nhúng vào — KHÔNG copy logic, chỉ forward tín hiệu (`boss_panel.stage_selected` → `stage_selected` của chính mình, `on_stage_finished` → gọi tiếp `boss_panel.on_stage_finished`).
- `StageFarmMap.gd` / `.tscn` — instance trận treo máy chạy nền (giữ sống trong `GameState._idle_farm_map`).
- `StageFarmWorld.gd` — world mô phỏng chiến đấu treo máy (dùng lại `entities/troop/TroopUnit`).
- `MapData.gd` — định nghĩa dữ liệu 1 map (Resource, `class_name MapData`), nguồn cho `core/database/MapDatabase.gd`.

## Entry Point
`StageBoardScreen.gd` — instance bởi `core/app/MainShell.tscn`, id tab `stage`. Đây là điểm nối DUY NHẤT MainShell cần biết cho cả 3 sub-tab (kể cả Ải Boss).

## Public API
Không có API được module khác gọi vào trực tiếp (leaf UI screen) — giao tiếp qua `core/app/GameState` (`start_idle_team`, `has_idle_team`, `is_troop_idling`, `stop_idle_team`, `get_idle_farm_map`) và mở trận qua `features/combat/StageFlowController`.

## Module được phép gọi
`core/app`, `core/database`, `core/shared`, `entities/troop`, `entities/stage`, `features/boss` (nhúng `BossBoardScreen` làm panel con — module DUY NHẤT được phép làm vậy), `features/combat` (mở Ủy Thác/Ải Boss qua `StageFlowController.start_stage()`).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — tài liệu chính, đọc kỹ mục "Sub-tab Treo máy" trước khi sửa (thiết kế đã đổi hẳn 2026-08-08: chỉ 1 team treo máy toàn game, không phải nhiều team/nhiều map).
