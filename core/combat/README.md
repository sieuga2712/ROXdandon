# core/combat

## Mục đích
Logic chiến đấu DÙNG CHUNG bởi `features/stage` (Ải Thường/Treo máy) và `features/combat` (Ải Boss) — 2 feature này không được phép import thẳng nội bộ lẫn nhau (xem luật phụ thuộc CLAUDE.md), nên phần nào 2 bên cần y hệt nhau thì đặt ở đây. Gồm 2 phần tách bạch: **dữ liệu THUẦN** (`EncounterGenerator` - không Node/scene, chỉ tính số) và **hành vi NHÂN VẬT** (`CombatResolver` - có thao tác Node, nhưng vẫn không giữ trạng thái riêng, mọi state nằm trên chính `TroopUnit`).

## File chính
- `EncounterGenerator.gd` — `class_name EncounterGenerator`, không autoload, gọi thẳng qua global class. Công thức số-quái/đợt, cấp quái, số-đợt/tầng đều tăng theo `floor_number`; số-quái/đợt quay vòng 5→15 rồi cộng dồn +5 cấp quái mỗi vòng.
- `CombatResolver.gd` — `class_name CombatResolver extends RefCounted`, KHÔNG autoload (mỗi map tự `.new()` đúng 1 instance lúc `_ready()`). Toàn bộ hành vi CHIẾN ĐẤU của 1 đơn vị: targeting + chia góc vây quanh mục tiêu, né nhau khi di chuyển (Local Avoidance), đòn đánh thường + skill "Đánh mạnh" (windup/recovery, Priest xen kẽ hồi máu/đánh thường), đạn bay/hiệu ứng, rớt nguyên liệu, thưởng EXP/vàng. Đây là đặc trưng của NHÂN VẬT (không phải của map) — 2026-08 gộp lại từ 2 bản gần như trùng lặp ở `BattleScene`/`StageFarmWorld`, StageFarmWorld trước đó thiếu skill/né nhau chỉ vì lười viết chung, không phải chủ đích thiết kế. Mô hình "treadmill": chỉ phe `Enums.Team.ENEMY` thật sự di chuyển khi ngoài tầm đánh, phe PLAYER đứng yên chờ (map dựa vào giả định này để không cần bám camera/giới hạn thế giới phức tạp).

## Entry Point
Không cần — global class. `EncounterGenerator.generate_encounter_for_floor(floor_number)`/`generate_encounter(count, level)` gọi trực tiếp (thuần tính toán). `CombatResolver` cần khởi tạo instance: `CombatResolver.new(arena, grant_gold_on_kill)` 1 lần ở `_ready()` của map, rồi gọi `run_ai()`/`resolve_collisions()` mỗi frame.

## Public API
```
EncounterGenerator.generate_encounter_for_floor(floor_number: int) -> Dictionary  # {monster_ids: Array[int], monster_level: int}
EncounterGenerator.generate_encounter(monster_count: int, monster_level: int) -> Dictionary
EncounterGenerator.wave_count_for_floor(floor_number: int) -> int
EncounterGenerator.monsters_per_wave_for_floor(floor_number: int) -> int
EncounterGenerator.monster_level_for_floor(floor_number: int) -> int

CombatResolver.new(arena: Node2D, grant_gold_on_kill: bool) -> CombatResolver
CombatResolver.run_ai(player_units, enemy_units, delta, reward_troop_ids: Array[int]) -> void
CombatResolver.resolve_collisions(player_units, enemy_units) -> void
```

## Module được phép gọi
`EncounterGenerator`: không phụ thuộc module nào khác (chỉ `randi_range`/toán học built-in). `CombatResolver`: `core/app` (`GameState.grant_kill_exp`/`add_gold`/`add_material`), `core/database` (`MaterialDatabase`), `entities/troop` (`TroopUnit`, `Projectile`, `ImpactEffect`, `DamagePopup`).

## Ai được gọi vào đây
`features/stage/StageFarmWorld.gd` (Ải Thường/Treo máy - `EncounterGenerator` theo `floor_number` thật, `CombatResolver` với `grant_gold_on_kill=true`), `features/combat/BattleScene.gd` (Ải Boss - `EncounterGenerator` cho trash-wave trước boss thật dùng `StageData.boss_trash_wave_count`/`boss_trash_monster_level`, `CombatResolver` với `grant_gold_on_kill=false` vì vàng cộng 1 cục lúc thắng).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — thiết kế bản đồ nhiều đợt quái (2026-08, đã đổi sang mô hình "treadmill" - camera cố định, quái đi tới từ ngoài khung hình, xem `CombatResolver`/`BattleScene`/`StageFarmWorld`).
