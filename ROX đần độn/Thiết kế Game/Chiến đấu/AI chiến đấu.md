# AI chiến đấu

Thuộc [[Mục lục]]. Liên quan: [[Luồng chơi (Hub → Ải → Chiến đấu)]], [[Công thức sát thương]], [[Hệ thống Kỹ năng]]. **Đổi kiến trúc lớn nhất so với `vrisingDanDon`** - xem [[Chuyển thể từ vrisingDanDon]].

## Nguyên tắc kiến trúc (không đổi)
Toàn bộ AI (tìm mục tiêu, di chuyển, tấn công) chạy **tập trung ở `BattleScene`** mỗi frame cho MỌI unit - không để từng `TroopUnit` tự AI riêng. `TroopUnit` chỉ quyết định animation nào tương ứng với hành động được yêu cầu.

## Không còn Squad (khác biệt lớn nhất)
`vrisingDanDon` có khái niệm **"1 trại lính = 1 đội"** (squad cố định, đội trưởng tự tìm mục tiêu, cả đội dùng chung) - khái niệm này **không còn ý nghĩa** trong ROXdandon vì không còn barracks/trại lính (đội hình cố định 4 người, không phải "gom quân từ nhiều trại").

**Giải pháp thay thế** (`BattleScene._update_side()`) - tính toán lại **MỖI FRAME**, không có squad cố định:
1. Mỗi unit còn sống tự `_find_nearest()` tìm địch gần nhất của RIÊNG NÓ (không qua đội trưởng).
2. Gom các unit đang nhắm **CHUNG 1 mục tiêu** lại thành 1 nhóm tạm thời (`group_by_target: Dictionary`, tính lại từ đầu mỗi frame).
3. Mỗi nhóm tự chia đều góc quanh mục tiêu chung đó (Attack Slot, y hệt logic cũ) - `slot_angle = TAU × i / group.size()`.

Vì party chỉ có 4 người, việc "nhiều unit tự nhiên nhắm chung 1 mục tiêu" xảy ra RẤT thường xuyên (khác `vrisingDanDon` với hàng chục lính/squad) - cơ chế gom-theo-mục-tiêu-động này thay thế đúng vai trò squad cũ mà không cần khái niệm "đội" tồn tại xuyên suốt trận đấu.

## Các phần giữ nguyên từ `vrisingDanDon`
- **Separation / Push Force** (`_resolve_collisions`) - đẩy nhẹ 2 unit ra xa nếu khoảng cách 2 tâm < 2×`COLLISION_RADIUS`. Ưu tiên không đẩy unit đang `is_engaged` (đứng yên đánh nhau).
- **Local Avoidance chủ động** (`_compute_avoidance`) - lực đẩy tổng hợp từ đồng đội CÙNG PHE trong bán kính `AVOIDANCE_RADIUS` (= 4×`COLLISION_RADIUS`), cộng vào hướng Seek (`AVOIDANCE_WEIGHT = 0.8`).
- **Attack Slot / Combat Positioning cơ bản** - bán kính slot theo TẦM ĐÁNH RIÊNG từng unit (0.85× `attack_range_px()`) - unit đánh xa tự đứng vòng ngoài lớn hơn.
- **Y-sort** - `BattleArena.y_sort_enabled = true`.
- **Target Selection**: chỉ có "gần nhất" (`_find_nearest`) cho đánh, "HP thấp nhất" (`_find_heal_target`) cho Priest hồi máu - y hệt cũ.

## Giới hạn đã biết (kế thừa nguyên vẹn từ `vrisingDanDon`, chưa giải quyết)
- Hệ bao vây/né chỉ chạy khi unit **đang PHẢI DI CHUYỂN** tới mục tiêu. Nếu unit đã nằm trong tầm đánh NGAY LÚC VỪA SPAWN, nó đứng khựng luôn tại vị trí spawn, không bao giờ qua hệ bao vây/né.
- **Chưa phân vai theo loại** (melee bao vây/ranged đứng sau/support đứng cuối) - mọi loại xử lý giống nhau, chỉ khác bán kính slot theo tầm đánh.
- **FSM hình thức** - vẫn là if/else lồng nhau trong `_update_unit()`, không phải state machine tường minh. Thiếu trạng thái "Rút lui".
- **Arrive**/**Obstacle Avoidance** - chưa có (dừng đột ngột khi vào tầm đánh, không có vật cản trên sân).
- **Formation System/Dynamic Formation** - chỉ có vị trí SPAWN cố định (xem [[Luồng chơi (Hub → Ải → Chiến đấu)]]), không duy trì đội hình khi đang đánh.

## Kiến trúc code
`BattleScene._run_ai()` → `_update_side(units, enemies, delta)` (tìm mục tiêu + gom nhóm theo mục tiêu chung + gán góc slot, thay hẳn `_assign_targets(squads, enemies)` cũ) → `_update_unit()` (di chuyển/tấn công từng unit, logic bên trong GẦN NHƯ KHÔNG ĐỔI so với `vrisingDanDon`) → `_resolve_collisions()` (đẩy cứng khi đã chồng nhau, chạy SAU `_run_ai()` mỗi frame).
