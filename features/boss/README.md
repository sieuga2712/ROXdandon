# features/boss

## Mục đích
"Ải Boss" — 2 sub-tab: Boss Ngày (chọn độ khó Dễ/Thường/Khó) và Boss Khủng (world boss, không chọn độ khó). **Không còn là tab riêng ở BottomNav** (đổi 2026-08) — giờ là sub-tab thứ 3 nhúng bên trong `features/stage/StageBoardScreen` (`%BossPanel`), cùng hàng với "Ủy Thác"/"Treo máy".

## File chính
- `BossBoardScreen.gd` / `.tscn` — UI của panel, hoàn toàn tự chứa (self-contained), không biết gì về việc mình bị nhúng ở đâu.
- `BossData.gd` — định nghĩa 1 boss (Resource, `class_name BossData`), nguồn cho `core/database/BossDatabase.gd`. Mỗi boss trỏ tới 1-4 `StageData` có sẵn qua `get_stage(difficulty)` (gọi `StageDatabase`), KHÔNG có bộ số liệu HP/ATK/DEF riêng — tránh 2 nơi giữ cùng dữ liệu.

## Entry Point
`BossBoardScreen.gd` — instance bởi `features/stage/StageBoardScreen.tscn` (`%BossPanel`), KHÔNG còn instance trực tiếp bởi `core/app/MainShell.tscn`. `signal stage_selected` và `on_stage_finished()` được `StageBoardScreen` forward hộ ra ngoài (MainShell chỉ nối 1 đầu mối `stage_screen`, không nối thẳng vào module này nữa).

## Public API
`stage_selected(stage: StageData)` (signal), `on_stage_finished(stage, won)` — 2 điểm nối duy nhất, hiện chỉ được `features/stage/StageBoardScreen.gd` gọi vào (không phải MainShell trực tiếp như trước). `BossData.get_stage(difficulty: String) -> StageData` là hàm nội bộ module này gọi ra `core/database/StageDatabase`.

## Module được phép gọi
`core/database` (gồm `StageDatabase` — ngoại lệ phụ thuộc chéo đã biết, xem `CLAUDE.md`), `entities/stage`, `features/combat` (mở trận qua `StageFlowController`, dùng chung với Ủy Thác — gián tiếp qua `features/stage` forward).

## Ai được gọi vào đây
Chỉ `features/stage/StageBoardScreen.gd` (module chủ quản panel này) — không module nào khác nên tự ý `preload`/reference thẳng `BossBoardScreen` nữa.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — mục "Tab Ải Boss".
