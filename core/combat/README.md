# core/combat

## Mục đích
Công thức "quái sinh ra sao" theo tầng/độ khó — logic sinh dữ liệu THUẦN (không Node/scene), dùng chung bởi `features/stage` (Ải Thường) và `features/combat` (Ải Boss). Đặt ở `core/` vì 2 feature trên không được phép import thẳng nội bộ lẫn nhau (xem luật phụ thuộc CLAUDE.md).

## File chính
- `EncounterGenerator.gd` — `class_name EncounterGenerator`, không autoload, gọi thẳng qua global class. Công thức số-quái/đợt, cấp quái, số-đợt/tầng đều tăng theo `floor_number`; số-quái/đợt quay vòng 5→15 rồi cộng dồn +5 cấp quái mỗi vòng.

## Entry Point
Không cần — global class, gọi trực tiếp `EncounterGenerator.generate_encounter_for_floor(floor_number)` hoặc `EncounterGenerator.generate_encounter(count, level)` (dùng cho trash-wave Ải Boss, không gắn với floor_number).

## Public API
```
EncounterGenerator.generate_encounter_for_floor(floor_number: int) -> Dictionary  # {monster_ids: Array[int], monster_level: int}
EncounterGenerator.generate_encounter(monster_count: int, monster_level: int) -> Dictionary
EncounterGenerator.wave_count_for_floor(floor_number: int) -> int
EncounterGenerator.monsters_per_wave_for_floor(floor_number: int) -> int
EncounterGenerator.monster_level_for_floor(floor_number: int) -> int
```

## Module được phép gọi
Không phụ thuộc module nào khác trong project (chỉ dùng `randi_range`/toán học built-in).

## Ai được gọi vào đây
`features/stage/StageFarmWorld.gd` (Ải Thường, theo `floor_number` thật), `features/combat/BattleScene.gd` (Ải Boss, trash-wave trước boss thật — dùng `StageData.boss_trash_wave_count`/`boss_trash_monster_level`, không liên quan `floor_number`).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — thiết kế bản đồ dài nhiều đợt quái, camera đuổi theo phe mình (2026-08).
