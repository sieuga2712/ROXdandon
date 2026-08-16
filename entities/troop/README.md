# entities/troop

## Mục đích
Domain object "đơn vị chiến đấu" (lính/quái/boss) và hiệu ứng đi kèm — dùng chung bởi `features/combat` (BattleScene) và `features/stage` (StageFarmWorld, treo máy). Không phải feature, không có UI riêng.

## File chính
- `TroopUnit.gd` / `.tscn` — actor thật trên chiến trường (di chuyển, đánh, nhận sát thương, chọn/bỏ chọn).
- `LinhData.gd` — định nghĩa dữ liệu 1 lính/quái/boss (Resource, `class_name LinhData`), nguồn cho `core/database/TroopDatabase.gd`.
- `Projectile.gd` / `.tscn` — đạn bay (Cung/Pháp).
- `ImpactEffect.gd` / `.tscn` — hiệu ứng va chạm.
- `DamagePopup.gd` / `.tscn` — số sát thương nổi lên.

## Entry Point
`TroopUnit.gd` (`class_name TroopUnit`) — module khác chỉ nên gọi qua các hàm public của nó, không tự ý đọc field nội bộ.

## Public API (TroopUnit)
```
setup(data: LinhData, unit_team: Enums.Team) -> void
take_damage(amount: float) -> void
heal(amount: float) -> void
is_dead() -> bool
revive() -> void
set_selected(value: bool) -> void
max_hp() / effective_atk() / effective_def() / effective_m_def() -> float
play_walk() / play_idle() / play_attack() / play_heal() -> void
face_towards(target_position: Vector2) -> void
attack_range_px() / attack_interval() / move_speed_px() -> float
```

## Module được phép gọi
`core/config` (Enums). **Không được phụ thuộc ngược vào bất kỳ `features/*` nào** — đây là quy tắc cứng cho `entities/`.

## Ai được gọi vào đây
`features/combat` (BattleScene spawn/điều khiển TroopUnit thật trong trận), `features/stage` (StageFarmWorld dùng lại y hệt cho treo máy).

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Đội hình & Nhân vật/Chỉ số lính.md`
- `ROX đần độn/Thiết kế Game/Đội hình & Nhân vật/Danh sách quái (Monster Roster).md`
- `ROX đần độn/Thiết kế Game/Đội hình & Nhân vật/Hoạt ảnh & Asset lính.md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Kiểu tấn công (Attack Types).md`
- `ROX đần độn/Thiết kế Game/Chiến đấu/Công thức sát thương.md`
