# Camera & Hiệu ứng trận đấu

Thuộc [[Mục lục]]. Liên quan: [[Luồng chơi (Hub → Ải → Chiến đấu)]], [[Hệ thống Kỹ năng]], [[Hoạt ảnh & Asset lính]], [[Lỗi đã gặp & Bài học]] (lý do chọn SubViewport ngay từ đầu, không phải debug lại từ đầu).

## Kiến trúc màn hình riêng (SubViewport) - giữ nguyên từ `vrisingDanDon`
Sân đấu render trong 1 **`SubViewport` riêng hẳn** (`BattleScene.tscn` - `SubViewportContainer` > `SubViewport` > `BattleWorld2D` chứa nền sân + `BattleArena` + `BattleCamera`). Áp dụng lại NGAY TỪ ĐẦU (không phải debug lại) vì bài học đã có sẵn từ `vrisingDanDon`: 2 `Camera2D` chung 1 viewport từng gây lỗi zoom sai khó hiểu - xem [[Lỗi đã gặp & Bài học]].

## Camera TĨNH HOÀN TOÀN (đơn giản hơn hẳn `vrisingDanDon`)
- Đặt 1 lần lúc `_ready()`: `position = Vector2.ZERO`, `zoom = Vector2.ONE` - **không lăn chuột zoom, không giữ chuột phải kéo pan** như bản cũ.
- Lý do bỏ hẳn điều khiển camera: sân đấu giờ NHỎ CỐ ĐỊNH (~4 party vs ~4-8 quái, đội hình gói gọn quanh 2 tâm đội hình cách nhau 360 world-unit) - không còn cần zoom/pan để xem hết 1 bàn cờ lớn như bản 10x6 hex cũ. Nền sân (`BattleArenaBackground`) rộng 900×600 (`-450..450, -300..300`), vừa đủ trong khung nhìn 1280×720 ở zoom mặc định.

## Đạn bay & hiệu ứng skill - nguyên vẹn từ `vrisingDanDon`
- **Projectile** (`scripts/troop/Projectile.gd`) - Archer (mũi tên)/Wizard (luồng phép): bay từ người bắn tới mục tiêu theo `SPEED` cố định, sát thương áp dụng lúc TỚI NƠI (callback `on_arrive`).
- **ImpactEffect** (`scripts/troop/ImpactEffect.gd`) - Priest: hiệu ứng hiện THẲNG lên mục tiêu, KHÔNG di chuyển. Xem [[Hệ thống Kỹ năng]].
- Cả 2 dùng chung kỹ thuật sprite sheet trim/pack - xem [[Hoạt ảnh & Asset lính]].

## Thanh trạng thái trên đầu mỗi unit - nguyên vẹn
- **Thanh máu**: phe địch luôn tông đỏ (đậm→sẫm theo % máu), phe mình xanh lá (đầy)→đỏ (sắp chết).
- **2 thanh hồi chiêu** (đánh thường + skill) - trắng lúc đang hồi, chuyển **xanh lá (phe mình)/vàng (phe địch)** khi sẵn sàng ra đòn tiếp.
- **Số sát thương/hồi máu nhảy lên** (`DamagePopup`) - trắng = đòn thường, cam = đòn skill, xanh lá = hồi máu.
- Unit chết → ẩn hết cả 3 thanh + 2 vòng tròn debug hitbox/tầm đánh.

## Nút "Chịu thua"
Góc trên-phải màn chiến đấu - kết thúc trận ngay lập tức, luôn tính là **thua** (`_end_battle(false)`).

## Kiến trúc code
`BattleScene.gd`/`.tscn`, `scripts/troop/Projectile.gd`, `scripts/troop/ImpactEffect.gd`, `scripts/troop/DamagePopup.gd`, `TroopUnit` (thanh máu/cooldown, `_draw()` vẽ vòng tròn debug qua Debug > Visible Collision Shapes) - **toàn bộ mang nguyên từ `vrisingDanDon`, chỉ bỏ phần điều khiển camera tay** (`_unhandled_input`/`_zoom_by`/`_clamp_camera_position`/`_clamp_axis` và các hằng `MIN_ZOOM`/`MAX_ZOOM`/`ZOOM_STEP`/`PAN_MARGIN` đã xoá hẳn khỏi `BattleScene.gd`).
