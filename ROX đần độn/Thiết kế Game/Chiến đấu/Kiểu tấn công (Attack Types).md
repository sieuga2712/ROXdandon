# Kiểu tấn công (Attack Types)

Thuộc [[Mục lục]]. Danh sách tham khảo 20 kiểu tấn công/kỹ năng phổ biến, kế thừa nguyên vẹn từ `vrisingDanDon` (không đổi gì về cơ chế khi chuyển sang ROXdandon) - dùng làm "thực đơn" khi thiết kế skill mới sau này. Đối chiếu với [[Luồng chơi (Hub → Ải → Chiến đấu)]]/[[AI chiến đấu]]/[[Hệ thống Kỹ năng]].

## Đã có (dù chưa tách thành hệ thống riêng)

1. **Melee (Cận chiến)** ✅ - mặc định cho mọi nhân vật không phải archer/wizard/priest: gây sát thương ngay khi trong tầm đánh - `BattleScene._resolve_attack()` nhánh `_` (default) → `_apply_damage()` ngay lập tức.
2. **Projectile (Đạn bay)** ✅ - Archer (mũi tên)/Wizard (luồng phép): `scripts/troop/Projectile.gd`, bay từ người bắn tới mục tiêu theo tốc độ cố định, sát thương chỉ áp dụng lúc TỚI NƠI.
3. **Hitscan (Trúng tức thì)** 🟡 - Melee ở trên đã "trúng tức thì" nhưng chưa có kiểu hitscan tầm XA thật - hiện muốn đánh xa bắt buộc phải qua Projectile có độ trễ bay.
6. **Lock Target (Khóa mục tiêu)** 🟡 - có ở dạng ẩn trong AI: Priest hồi máu khóa vào 1 đồng minh cụ thể (`_find_heal_target`), đòn đánh khóa vào 1 địch cụ thể (`_find_nearest`) - hành vi CỨNG, chưa phải "kiểu kỹ năng" tách riêng có thể gán tuỳ ý.
17. **Throw Weapon (Ném vũ khí)** 🟡 - trùng cơ chế Projectile, chưa có biến thể "quay lại tay" (boomerang).

## Chưa làm

4. **Beam (Tia liên tục)** ❌
5. **Ground Target (Chỉ định vị trí)** ❌ - game vẫn là auto-battler thuần, không có thao tác chọn điểm trong lúc đánh.
7. **Dash (Lao tới)** ❌
8. **Charge (Tích lực)** ❌ - `skill_windup_timer` là ĐỘ TRỄ CỐ ĐỊNH (xem [[Hệ thống Kỹ năng]]), không phải "giữ càng lâu càng mạnh".
9. **Cone (Hình quạt)** ❌
10. **Line (Đường thẳng)** ❌ - Projectile bay thẳng nhưng chỉ trúng ĐÚNG 1 mục tiêu đã khóa sẵn, không xuyên nhiều mục tiêu.
11. **Nova (Phát nổ quanh bản thân)** ❌
12. **Orbit (Quỹ đạo xoay)** ❌
13. **Chain (Chuỗi mục tiêu)** ❌
14. **Aura (Hào quang)** ❌ - heal của Priest là tác động RỜI RẠC theo chu kỳ, không phải aura liên tục.
15. **Trap (Bẫy)** ❌
16. **Summon (Triệu hồi)** ❌ - đội hình dàn sẵn từ đầu trận, chưa có kỹ năng triệu hồi thêm đơn vị giữa trận (dù trong asset pack, Skeleton/Necromancer có sẵn animation "Summon" - chủ động BỎ QUA lúc trích xuất vì chưa có hệ thống dùng tới, xem [[Danh sách quái (Monster Roster)]]).
18. **Multi-stage (Nhiều giai đoạn)** ❌ - Priest có 2 hành vi xen kẽ + luồng windup→cast→recovery nhiều pha, nhưng đó là NHỊP CHUNG của mọi skill chứ không phải 1 skill riêng gồm nhiều bước nối tiếp khác nhau.
19. **Grab (Khống chế)** ❌
20. **Environment (Môi trường)** ❌ - sân đấu không có địa hình/vật cản, chỉ có nền trống.

Xem thêm: [[AI chiến đấu]] (danh sách tương tự cho hệ di chuyển/đội hình).
