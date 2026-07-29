# Hệ thống Kỹ năng

Thuộc [[Mục lục]]. Liên quan: [[Công thức sát thương]], [[Kiểu tấn công (Attack Types)]], [[Đội hình cố định (Party)]] (Priest), [[Camera & Hiệu ứng trận đấu]] (hiệu ứng hình ảnh khi tung skill). **Nguyên văn từ `vrisingDanDon`, không đổi gì.**

## "Đánh mạnh" - skill mặc định mọi nhân vật (trừ Priest)
- Cứ mỗi `SKILL_INTERVAL` giây (**2s**) lại có 1 đòn skill: **x2 sát thương** (`SKILL_DAMAGE_MULT`), hiệu ứng hình ảnh khác đòn thường.
  - Archer: cùng ảnh mũi tên nhưng phóng to **x1.5** (`ARROW_SKILL_SCALE`).
  - Wizard: đổi hẳn hiệu ứng từ `MagicProjectileFrames` (đòn thường) sang `MagicSkillProjectileFrames` (đòn mạnh).
- `Spellcast Speed` **không dùng** - mọi nhân vật (kể cả 13 quái mới) đều để = 0, skill dùng chu kỳ cố định `SKILL_INTERVAL` không phụ thuộc chỉ số này.

## Priest - ngoại lệ hoàn toàn
- **Không có đòn mạnh** - skill xen kẽ giữa **hồi máu đồng đội** (HP thấp nhất, có thể là chính mình, = 50% ATK của Priest, `PRIEST_HEAL_RATIO`) và **1 đòn đánh thường** - đảo chiều mỗi lần `skill_cooldown` sẵn sàng (`skill_toggle`).
- Chu kỳ riêng ngắn hơn hẳn: `PRIEST_SKILL_INTERVAL = 1s` (thay vì 2s chung).
- Đòn đánh thường của Priest dùng `ImpactEffect` (hiệu ứng hiện THẲNG LÊN mục tiêu, KHÔNG di chuyển) thay vì `Projectile`.
- Vì đội hình ROXdandon LUÔN có đúng 1 Priest cố định (xem [[Đội hình cố định (Party)]]), cơ chế này giờ **luôn chắc chắn có mặt trong mọi trận** - khác `vrisingDanDon` (Priest chỉ là 1 trong 9 lựa chọn tuyển quân, có thể vắng mặt cả trận nếu người chơi không tuyển).

## Khoảng nghỉ trước/sau skill (chống dính đòn)
Máy trạng thái 2 pha, mỗi pha = **50% `attack_interval()`** của chính nhân vật đó:
1. `skill_windup_timer` - "khoảng nghỉ TRƯỚC": skill_cooldown hồi xong không tung ngay, đứng yên không đánh gì cho tới khi đếm hết mới thật sự ra hiệu ứng.
2. `skill_recovery_timer` - "khoảng nghỉ SAU": ngay sau khi hiệu ứng skill xuất hiện, tiếp tục đứng yên thêm 1 nhịp trước khi được đánh thường trở lại.

## Kiến trúc code
`BattleScene._update_unit()` (máy trạng thái windup/recovery), `_priest_cast()` (xen kẽ heal/attack), `_skill_pause()` = `attack_interval() × 0.5`. `TroopUnit.skill_cooldown`/`skill_cooldown_max`/`skill_windup_timer`/`skill_recovery_timer`/`skill_toggle` - y hệt tên biến bên `vrisingDanDon`.
