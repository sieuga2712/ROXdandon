# Thành phố & Ải AFK-Farm

Thuộc [[Mục lục]]. Liên quan: [[Vỏ ứng dụng Portrait (MainShell & Navigation)]], [[Đội hình cố định (Party)]], [[Công thức sát thương]], [[Danh sách quái (Monster Roster)]]. Đây là 2 tab MAP MỚI hoàn toàn, không có trong bản gốc `vrisingDanDon` lẫn bản ROXdandon lúc mới scaffold (lúc đó chỉ có Hub tĩnh).

## Điểm chung 2 map
Cả 2 đều theo đúng khuôn: `<Tên>Map.tscn` (Control, script `<Tên>Map.gd` - proxy mỏng, chỉ có `set_interactive(bool)`) > `SubViewportContainer` > `SubViewport` > `<Tên>World.gd` (Node2D, TOÀN BỘ logic thật nằm ở đây) + 1 `PartyRosterPanel` (HUD nổi, tái dùng NGUYÊN `PartyRosterPanel.gd`).

**Điều khiển party** (giống hệt cả 2 map, copy-và-chỉnh giữa 2 file thay vì tách class dùng chung - xem "Nguyên tắc" cuối trang): đúng 1 người là **leader** (chọn qua bấm thẻ trên `PartyRosterPanel`, dùng `ButtonGroup` nên Godot tự đảm bảo luôn đúng 1 thẻ được chọn), **3 người còn lại LUÔN tự động bám theo leader** mỗi frame (không có trạng thái "độc lập" riêng ở bản hiện tại - đã từng thử mô hình 3 trạng thái "điều khiển/đang theo/độc lập" nhưng bị revert lại bản đơn giản, xem [[Tiến độ & Việc còn dang dở]]). Click TRÁI vào map = ra lệnh leader đi tới đó, tính world-point qua `get_viewport().get_canvas_transform().affine_inverse() * event.position` (KHÔNG dùng `get_global_mouse_position()` - xem [[Lỗi đã gặp & Bài học]] mục mới thêm).

## Tab "Thành phố" (`city`) = `OverworldMap.tscn`/`OverworldWorld.gd`
- Map nhỏ (`MAP_BOUNDS` 600x960), camera TĨNH (không cần bám theo vì map vừa khung hình).
- Trang trí: 2 nhà (crop trực tiếp từ `houses.png` qua `Sprite2D.region_rect`), 2 NPC đứng yên idle (Blonde Man/Blue Haired Woman, `assets/npcs/`), 2 placeholder marker (chừa chỗ thêm NPC sau).
- **Không có combat** - đây thuần là màn đi lại/tương tác cảnh vật. Chưa có đặt/nâng cấp công trình thật (city-building đã bị cắt hẳn khỏi project này từ lâu, xem [[Chuyển thể từ vrisingDanDon]] - "Thành phố" ở đây chỉ là cái tên tab, KHÔNG phải hồi sinh hệ xây dựng).

## Tab "Ải" (`stage`) = `StageFarmMap.tscn`/`StageFarmWorld.gd` — **AFK-farm, khác hẳn BattleScene**
- Map RỘNG hơn hẳn City (`MAP_BOUNDS` 1800x2200), `Camera2D` dùng `limit_left/top/right/bottom` = `MAP_BOUNDS` (Godot tự clamp) và `camera.position = leader.position` mỗi frame để BÁM THEO leader.
- **6 điểm spawn quái cố định** (`const SPAWN_POINTS` ngay trong script, chưa cần `.tres` riêng) rải khắp map, dùng quái nhẹ có sẵn trong catalog (Slime/Bat/Skeleton/Skeleton Archer/Orc, 1 điểm Armored Skeleton xa hơn cho khó hơn chút).
- **Combat diễn ra TRỰC TIẾP trên map, không chuyển cảnh/không popup** (khác hẳn `BattleScene`) - unit nào cũng tự tìm địch gần nhất trong `AGGRO_RANGE` (180px), ngoài tầm đánh thì đi tới, trong tầm thì đánh theo cooldown.
- **Quái chết → cộng vàng (`roundi(hp/10)`) → hiện popup "+N vàng" (tái dùng `DamagePopup.tscn`) → biến mất sau ~1s → hồi sinh lại đúng loại/số lượng sau `RESPAWN_TIME` (20s)** - đúng đặc trưng farm vô hạn.
- Đơn vị người chơi chết thì **nằm lại tại chỗ, không tự hồi sinh** (chỉ có `regen_hp` hồi máu bị động khi còn sống, y hệt `BattleScene`).

### Phạm vi v1 cắt bớt có chủ đích (không phải thiếu sót)
Công thức sát thương **copy đúng** từ `BattleScene._resolve_attack`/`_apply_damage` (crit, giáp hiệu dụng theo armor penetration, life steal) nhưng **CHƯA có skill "đánh mạnh"/windup 2 giai đoạn, CHƯA có đạn bay Projectile** - mọi đòn (kể cả archer/wizard) đều ra sát thương ngay khi trúng tầm như lính cận chiến. Nâng cấp thêm sau nếu cần, không chặn gì hiện tại.

## Không đụng `BattleScene.gd`/`.tscn`/`StageFlowController.gd`
Cố tình tách biệt - `BattleScene` (có thắng/thua/thời gian rõ ràng) dành riêng cho tab **Ải Boss** sau này. Map farm là kiểu chiến đấu world-thường-trực hoàn toàn khác, không có khái niệm thắng/thua.

## Nguyên tắc "copy-và-chỉnh" thay vì tách class dùng chung
Cả di chuyển leader/follow lẫn khung `<Tên>Map.gd` proxy đều bị TRÙNG LẶP giữa `OverworldWorld.gd` và `StageFarmWorld.gd` một cách có chủ đích - ưu tiên không động vào City tab đang chạy tốt khi xây map farm mới, chấp nhận trùng code. Nếu có chỗ thứ 3 cần y hệt logic này, đó là lúc nên tách 1 `PartyController` dùng chung thật sự (chưa làm).
