# Công thức sát thương

Thuộc [[Mục lục]]. Liên quan: [[Chỉ số lính]], [[Hệ thống Kỹ năng]] (nhân thêm hệ số khi là đòn skill), [[Kiểu tấn công (Attack Types)]]. **Nguyên văn từ `vrisingDanDon`, không đổi gì** khi chuyển sang ROXdandon.

> Toàn bộ công thức trong ghi chú này là **số liệu tạm tự đặt**, chưa cân bằng kỹ - chỉ để trận đấu chạy được và luôn có hồi kết.

## Công thức
```
base_damage = ATK × (Crit Damage nếu chí mạng, tỉ lệ theo Crit Rate)
nếu là đòn skill: base_damage × SKILL_DAMAGE_MULT (= 2.0, xem [[Hệ thống Kỹ năng]])
effective_defense = (DEF hoặc M.DEF theo hệ đòn đánh) × (1 - Armor Penetration/100)
final_damage = max(base_damage - effective_defense, 1.0)   ← trừ THẲNG, không phải theo %, tối thiểu 1 sát thương/đòn
```
- Trừ thẳng (không phải %) để trận đấu luôn có hồi kết dù đối phương giáp rất cao.
- `Life Steal`: attacker hồi máu = `final_damage × life_steal` sau khi đòn trúng.

## Move Speed → px/giây
```
move_speed_px = Move Speed × MOVE_SPEED_SCALE (= 20)
```

## Thời điểm áp dụng sát thương - khác nhau theo kiểu tấn công
- **Melee/Priest** (xem [[Kiểu tấn công (Attack Types)]]): áp dụng NGAY khi ra đòn.
- **Archer/Wizard**: tính sát thương ngay lúc bắn (dùng chỉ số hiện tại 2 bên) nhưng chỉ THẬT SỰ áp dụng khi đạn bay TỚI NƠI - nếu mục tiêu đã chết bởi đòn khác trước đó thì đòn coi như trượt, không cộng thêm sát thương thừa. Xem [[Camera & Hiệu ứng trận đấu]] (mục đạn bay).

## Kiến trúc code
`BattleScene._resolve_attack()` (tính damage) → `_apply_damage()` (áp dụng thật, có check `defender.is_dead()` lại trước khi trừ máu) - y hệt tên hàm/logic bên `vrisingDanDon`.
