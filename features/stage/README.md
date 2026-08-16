# features/stage

## Mục đích
Tab "Ải" — tỉ lệ 1/3 trên - 2/3 dưới theo mockup đã chốt (2026-08): Phần 1 (`%BattleViewHost`, ~1/3 trên) nhúng LIÊN TỤC trận đang chạy vào xem trực tiếp - MẶC ĐỊNH là treo máy (`_mount_battle_view()`), TẠM THỜI đổi sang trận boss thật khi đánh (`_mount_boss_battle()`/`_unmount_boss_battle()` — 2026-08: boss KHÔNG còn mở `BattleScene` toàn màn nữa, đánh ngay tại `%BattleViewHost`). Phần 2 (~2/3 dưới) 3 sub-tab CÙNG 1 HÀNG (gộp lại 2026-08, bỏ tab "Ải Boss" trung gian): **"ẢI THƯỜNG"** (danh sách map — bấm 1 ải là TREO NGAY tại map đó, tự lên tầng khi thắng/tự đánh lại khi thua; trạng thái đang treo còn thể hiện thêm qua viền xanh "current" trên đúng thẻ map đó), **"BOSS NGÀY"**, **"BOSS KHỦNG"** (2 cái sau dùng chung 1 panel `BossBoardScreen` đã nhúng sẵn, chỉ đổi panel con hiển thị qua `show_daily_tab()`/`show_world_tab()`).

## File chính
- `StageBoardScreen.gd` / `.tscn` — UI chính của tab (BattleViewHost + 3 sub-tab cùng hàng). Panel Boss (`%BossPanel`) là instance của `features/boss/BossBoardScreen.tscn` được nhúng vào — KHÔNG copy logic, chỉ gọi API public (`boss_panel.show_daily_tab()`/`show_world_tab()`, `on_stage_finished`) và forward tín hiệu (`boss_panel.stage_selected` → mount trận boss vào `%BattleViewHost` rồi mới forward tiếp thành `stage_selected` của chính mình, xem `_on_boss_stage_selected()`).
- `StageFarmMap.gd` / `.tscn` — instance trận treo máy chạy nền (giữ sống trong `GameState._idle_farm_map`, "mượn nhà" GameState trong lúc đang đánh boss - xem `_mount_boss_battle()`).
- `StageFarmWorld.gd` — world mô phỏng chiến đấu treo máy (dùng lại `entities/troop/TroopUnit`). Tự phân biệt THẮNG (quái chết sạch → báo `GameState.report_floor_cleared` rồi tự `configure()` lại với tầng kế tiếp) và THUA (party chết sạch → đánh lại đúng tầng đang treo) — xem `_check_wipe()`/`_advance_floor()`.
- `MapData.gd` — định nghĩa dữ liệu 1 map (Resource, `class_name MapData`), nguồn cho `core/database/MapDatabase.gd`.

## Entry Point
`StageBoardScreen.gd` — instance bởi `core/app/MainShell.tscn`, id tab `stage`. Đây là điểm nối DUY NHẤT MainShell cần biết cho cả Ải Thường lẫn Ải Boss. MainShell còn gọi `set_battle_scene()` 1 lần lúc khởi tạo để tiêm instance `BattleScene` DUY NHẤT của app (sống ở `MainShell.tscn`) — module này chỉ MƯỢN TẠM (reparent) instance đó vào `%BattleViewHost` lúc đánh boss, không sở hữu/tạo mới.

## Public API
`set_battle_scene(scene: BattleScene) -> void` — MainShell gọi 1 lần lúc khởi tạo. Ngoài ra không có API được module khác gọi vào trực tiếp (leaf UI screen) — giao tiếp qua `core/app/GameState` (`start_idle_team_on_map`, `has_idle_team`, `is_troop_idling`, `stop_idle_team`, `get_idle_farm_map`, `report_floor_cleared`, `get_highest_floor`) và mở trận Boss qua `features/combat/StageFlowController`.

## Module được phép gọi
`core/app`, `core/database`, `core/shared`, `core/combat` (`EncounterGenerator` — sinh quái theo đợt/tầng, xem `StageFarmWorld`), `entities/troop`, `entities/stage`, `features/boss` (nhúng `BossBoardScreen` làm panel con — module DUY NHẤT được phép làm vậy), `features/combat` (mở Ủy Thác/Ải Boss qua `StageFlowController.start_stage()`).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — tài liệu chính, đọc kỹ mục "Sub-tab Treo máy" trước khi sửa (thiết kế đã đổi hẳn 2026-08-08: chỉ 1 team treo máy toàn game, không phải nhiều team/nhiều map).
