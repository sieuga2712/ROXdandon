# Vàng (GameState)

Thuộc [[Mục lục]]. Liên quan: [[Luồng chơi (Hub → Ải → Chiến đấu)]], [[Đội hình cố định (Party)]]. Thay thế TOÀN BỘ hệ kinh tế nhiều tài nguyên của `vrisingDanDon` (Vàng/Gỗ/Đá/Sắt/Lúa/Cung + `ResourceManager` + dân số + sản xuất) - xem [[Chuyển thể từ vrisingDanDon]].

## Hiện tại: đúng 1 loại tiền, chỉ để cộng
- `GameState.gold: int` (autoload) - bắt đầu = 0, cộng qua `GameState.add_gold(amount)`.
- Nguồn cộng duy nhất: thắng 1 ải → `+stage.reward_gold` (Ải 1 = 50 vàng, xem [[Luồng chơi (Hub → Ải → Chiến đấu)]]).
- **Chưa có chỗ nào TIÊU vàng** - không có shop/nâng cấp/tuyển quân (đội hình cố định, không cần mua). Vàng hiện chỉ để hiện số trong Hub, chưa có tác dụng gameplay.
- **Không lưu file** - `GameState` là autoload thường (không phải Resource lưu ra đĩa), vàng/mọi state reset về 0 mỗi lần mở lại game.

## Vì sao đơn giản hoá triệt để (so với `vrisingDanDon`)
`vrisingDanDon` cần nhiều tài nguyên vì có chuỗi sản xuất (gỗ/đá/sắt/lúa → chế tạo → tuyển quân) gắn liền với xây dựng thành phố. ROXdandon **không còn thành phố/chế tạo/tuyển quân** nên không có lý do giữ multi-resource - 1 counter `int` là đủ cho nhu cầu hiện tại (phần thưởng sau trận). Khi có hệ thống cần tiêu vàng (trang bị, mở khoá nhân vật...) đây là chỗ mở rộng tự nhiên - **chưa làm vì ngoài phạm vi đợt scaffold này**, xem [[Tiến độ & Việc còn dang dở]].

## Kiến trúc code
`scripts/state/GameState.gd` (autoload, đăng ký trong `project.godot`) - cực kỳ tối giản, chỉ `var gold: int = 0` + 1 hàm `add_gold()`. `Hub.gd` đọc `GameState.gold` mỗi frame trong `_process()` để cập nhật `GoldLabel` (tránh lỗi "label chỉ set 1 lần lúc dựng UI" đã từng gặp bên `vrisingDanDon`, xem [[Lỗi đã gặp & Bài học]]).
