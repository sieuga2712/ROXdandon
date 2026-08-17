# Chỉ số lính

Thuộc [[Mục lục]]. Liên quan: [[Đội hình cố định (Party)]], [[Danh sách quái (Monster Roster)]], [[Công thức sát thương]], [[Hệ thống Kỹ năng]]. Mang gần như nguyên vẹn từ `vrisingDanDon` - xem [[Chuyển thể từ vrisingDanDon]] về những gì đổi.

## Bảng chỉ số (mỗi `LinhData` đều có, dùng chung cho cả 4 party lẫn 13 quái)
| Chỉ số | Ghi chú |
|---|---|
| HP | |
| ATK | Gây sát thương theo hệ của nhân vật (vật lý/phép) |
| DEF | Giảm sát thương vật lý nhận vào |
| M.DEF | Giảm sát thương phép nhận vào |
| ATK Speed | 1 điểm = 1 giây đánh được 0.1 lần |
| Move Speed | Tốc độ di chuyển |
| Spellcast Speed | **Không dùng** - luôn = 0, xem [[Hệ thống Kỹ năng]] |
| Crit Rate / Crit Damage | Áp dụng cho cả đòn phép |
| Armor Penetration | 1 điểm = bỏ qua 1% giáp tương ứng đối phương |
| Life Steal | Hồi máu theo % sát thương gây ra |
| Regen HP | Hồi mỗi 5 giây (`REGEN_INTERVAL`) |
| Tầm đánh (data) | Xem công thức bên dưới |

- Chia 2 hệ sát thương (`Enums.DamageType`): **vật lý** (`troop_type = NORMAL`, cận chiến) và **phép** (`troop_type = ARCHER`, đánh xa) - ATK gây ra tương tác với DEF hoặc M.DEF đối phương tương ứng.

## Công thức tầm đánh → phạm vi tấn công thực tế
```
attack_range_px = HITBOX_DIAMETER × (1 + tầm_đánh_data × hệ_số)
HITBOX_DIAMETER = 36        (khớp kích thước nhân vật thật sau khi trim sprite - xem [[Hoạt ảnh & Asset lính]])
MELEE_RANGE_COEF = 0.1      (troop_type NORMAL)
RANGED_RANGE_COEF = 0.1     (troop_type ARCHER)
```
- Cận chiến (`attack_range` data = 1.0): 36×(1+1×0.1) = **39.6** world-unit.
- Đánh xa (`attack_range` data = 8.0): 36×(1+8×1.0) = **324** world-unit.
- Nguyên văn công thức từ `vrisingDanDon` - **không đổi gì** khi chuyển sang ROXdandon.

## Move Speed → px/giây
```
move_speed_px = Move Speed × MOVE_SPEED_SCALE (= 20)
```

## Kiến trúc code
- `scripts/troop/LinhData.gd` (Resource) - toàn bộ chỉ số trên + `character_key`, `troop_type`, `damage_type`, `skill_name`. **Đã bỏ `recruit_costs`** so với `vrisingDanDon` (không còn tuyển quân qua trại, xem [[Đội hình cố định (Party)]]).
- `TroopDatabase` (autoload) auto-scan `data/troops/*.tres` (22 file - 9 người + 13 quái) - xem [[Quy ước code & Autoload]].
- `TroopUnit.attack_range_px()`/`attack_interval()` - công thức ở trên, y hệt `vrisingDanDon`.
- **Đã bỏ hẳn** `stack_count`/`stack_max`/`effective_atk()` nhân theo số lượng dồn - mỗi `TroopUnit` giờ luôn là đúng 1 nhân vật, `effective_atk() == troop_data.atk`, `max_hp() == troop_data.hp`.
