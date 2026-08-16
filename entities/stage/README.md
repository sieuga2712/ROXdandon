# entities/stage

## Mục đích
`StageData` — contract dữ liệu "1 tầng/1 trận" dùng chung bởi nhiều feature thật sự (không chỉ nội bộ tab Ải). Tách riêng khỏi `features/stage` vì bị `features/combat`, `features/boss`, và `core/app/GameState` dùng trực tiếp qua type — không phải implementation riêng của 1 tab.

## File chính
- `StageData.gd` — Resource, `class_name StageData`, nguồn cho `core/database/StageDatabase.gd`.

## Entry Point
Chính nó — đây là 1 kiểu dữ liệu (Resource), không có hành vi phức tạp.

## Public API
Các field của `StageData` (map_id, floor_number, điều kiện thắng, danh sách quái...) — đọc trực tiếp, không có hàm nghiệp vụ riêng.

## Module được phép gọi
Không phụ thuộc module nào khác trong project.

## Ai được gọi vào đây
`features/combat` (`BattleScene.start_battle(stage: StageData)`, `StageFlowController.start_stage(stage: StageData)`), `features/boss` (`BossData.get_stage()` trả `StageData` qua `StageDatabase`), `features/stage` (chủ sở hữu nghiệp vụ Ủy Thác/Treo máy), `core/app/GameState` (`start_idle_team`, `get_idle_farm_map`).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md`
