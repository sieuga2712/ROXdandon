# features/combat

## Mục đích
Trận đấu thật — dùng chung bởi `features/stage` (Ủy Thác) và `features/boss` ("Thách đấu"). Không thuộc riêng 1 tab nào.

## File chính
- `StageFlowController.gd` — mở `BattleScene` cho 1 `StageData`, phát `signal stage_finished(stage, won)` khi xong.
- `BattleScene.gd` / `.tscn` — scene trận đấu thật, dùng `entities/troop/TroopUnit` cho cả 2 phe.

## Entry Point
`StageFlowController.gd` — **entry point tạm thời** (theo quyết định 2026-08 khi tái cấu trúc: chưa tạo `CombatManager.gd` vì hiện chỉ có 1 luồng combat duy nhất — Ủy Thác/Boss đều gọi thẳng `StageFlowController.start_stage()`. Nếu sau này có thêm luồng combat khác (PvP, Guild War...), cân nhắc thêm `CombatManager.gd` làm facade chung lúc đó, không làm trước khi cần).

## Public API
```
StageFlowController.start_stage(stage: StageData) -> void
signal StageFlowController.stage_finished(stage: StageData, won: bool)
```

## Module được phép gọi
`core/app`, `entities/troop`, `entities/stage`.

## Ai được gọi vào đây
`features/stage` (Ủy Thác), `features/boss` (Thách đấu) — cả 2 nối vào cùng 1 instance `StageFlowController` qua `core/app/MainShell.gd`.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Chiến đấu/Luồng chơi (Hub → Ải → Chiến đấu).md` — lưu ý tên cũ "Hub" đã thay bằng `MainShell`, đọc phần luồng logic vẫn đúng.
- `ROX đần độn/Thiết kế Game/Chiến đấu/AI chiến đấu.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Camera & Hiệu ứng trận đấu.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Hệ thống Kỹ năng.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Công thức sát thương.md`
