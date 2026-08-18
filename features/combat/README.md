# features/combat

## Mục đích
Trận đấu thật (hiện chỉ dùng cho Ải Boss - "Thách đấu", Ải Thường dùng `features/stage/StageFarmWorld` riêng). Không thuộc riêng 1 tab nào. `BattleScene` sống cố định ở `core/app/MainShell.tscn` nhưng KHÔNG còn hiện overlay toàn màn (đổi 2026-08) - `MainShell.gd` tiêm instance này cho `StageBoardScreen` (`set_battle_scene()`), module đó tự mượn tạm (reparent) vào `%BattleViewHost` của nó lúc đánh boss rồi trả về khi xong - `StageFlowController`/`BattleScene` ở đây hoàn toàn không biết/không quan tâm việc mount đó, chỉ lo bắt đầu/kết thúc trận.

## File chính
- `StageFlowController.gd` — mở `BattleScene` cho 1 `StageData`, phát `signal stage_finished(stage, won)` khi xong.
- `BattleScene.gd` / `.tscn` — scene trận đấu thật, dùng `entities/troop/TroopUnit` cho cả 2 phe. Nhiều đợt quái thường trước boss thật (xem `core/combat/EncounterGenerator`). **Chỉ còn lo phần "map"**: camera CỐ ĐỊNH vĩnh viễn (mô hình "treadmill" 2026-08, bỏ hẳn camera bám-1-nhân-vật kiểu "Taskbar Heroes" trước đó), vị trí spawn quái CỐ ĐỊNH (mọi đợt thường cùng 1 chỗ, boss xa hơn 1 khoảng cố định), timing đợt (`WAVE_CLEAR_DELAY`/`WAVE_TIMEOUT` "chồng đợt" nếu đánh quá lâu), thắng/thua/kết quả. Toàn bộ hành vi CHIẾN ĐẤU của 1 đơn vị (targeting/né nhau/skill/đạn bay/rớt đồ/thưởng) đã chuyển sang `core/combat/CombatResolver.gd` — dùng CHUNG với `features/stage/StageFarmWorld.gd`.

## Entry Point
`StageFlowController.gd` — **entry point tạm thời** (theo quyết định 2026-08 khi tái cấu trúc: chưa tạo `CombatManager.gd` vì hiện chỉ có 1 luồng combat duy nhất — Ủy Thác/Boss đều gọi thẳng `StageFlowController.start_stage()`. Nếu sau này có thêm luồng combat khác (PvP, Guild War...), cân nhắc thêm `CombatManager.gd` làm facade chung lúc đó, không làm trước khi cần).

## Public API
```
StageFlowController.start_stage(stage: StageData) -> void
signal StageFlowController.stage_finished(stage: StageData, won: bool)
```

## Module được phép gọi
`core/app`, `core/combat` (`EncounterGenerator` — sinh đợt quái thường trước boss thật; `CombatResolver` — chạy AI/sát thương/skill/né nhau/thưởng cho 1 frame, xem `BattleScene._process`), `entities/troop`, `entities/stage`.

## Ai được gọi vào đây
`features/stage` (Ủy Thác), `features/boss` (Thách đấu) — cả 2 nối vào cùng 1 instance `StageFlowController` qua `core/app/MainShell.gd`.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Chiến đấu/Luồng chơi (Hub → Ải → Chiến đấu).md` — lưu ý tên cũ "Hub" đã thay bằng `MainShell`, đọc phần luồng logic vẫn đúng.
- `ROX đần độn/Thiết kế Game/Chiến đấu/AI chiến đấu.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Camera & Hiệu ứng trận đấu.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Hệ thống Kỹ năng.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Công thức sát thương.md`
