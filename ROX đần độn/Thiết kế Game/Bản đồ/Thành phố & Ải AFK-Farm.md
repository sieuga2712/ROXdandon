# Thành phố & Ải AFK-Farm

Thuộc [[Mục lục]]. Liên quan: [[Vỏ ứng dụng Portrait (MainShell & Navigation)]], [[Đội hình cố định (Party)]], [[Công thức sát thương]], [[Danh sách quái (Monster Roster)]].

> ⚠️ **Cập nhật 2026-08-03**: phần "Tab Ải AFK-farm" ở dưới đã **SUPERSEDED HOÀN TOÀN** - tab "Ải" không còn là map điều khiển được nữa, đã đổi sang bảng "Ủy Thác" + hệ "Treo máy" thật + tab "Ải Boss" thật. Xem chi tiết ở [[Ủy Thác, Boss & Treo máy]]. Phần Ải bên dưới CHỈ giữ lại làm lịch sử (để hiểu vì sao `StageFarmMap.tscn`/`StageFarmWorld.gd` tồn tại) - `StageFarmWorld.gd` đã bị VIẾT LẠI, không còn đúng như mô tả cũ (đã bỏ hết leader/điều khiển/6 điểm spawn rải map, giờ là màn "xem treo máy cho vui" không điều khiển được, xem note mới).

## Tab "Thành phố" (`city`) - CẬP NHẬT: không còn điều khiển được
- `OverworldMap.tscn` giờ **KHÔNG có script** (đã xoá `OverworldMap.gd`/`OverworldWorld.gd`) - chỉ còn node tĩnh: `GroundBackground` + `Decorations` (2 nhà, crop từ `houses.png`) + `Npcs` (2 NPC thật + 2 placeholder). Theo yêu cầu người dùng: "màn thành không cần điều khiển nhân vật... để các npc thôi".
- **Không có combat, không điều khiển party, không có gì bấm được** - thuần trang trí/cảnh nền. Chưa có đặt/nâng cấp công trình thật (city-building đã bị cắt hẳn khỏi project này từ lâu, xem [[Chuyển thể từ vrisingDanDon]] - "Thành phố" chỉ là tên tab).

## ~~Tab "Ải" (`stage`) = map AFK-farm~~ - ĐÃ THAY THẾ, xem [[Ủy Thác, Boss & Treo máy]]
Giữ nguyên mô tả cũ dưới đây làm lịch sử kỹ thuật (file `StageFarmMap.tscn`/`StageFarmWorld.gd` vẫn còn nhưng nội dung đã viết lại hoàn toàn khác):

Từng có: map RỘNG (`MAP_BOUNDS` 1800x2200), 1 leader + 3 người tự bám theo (`PartyRosterPanel` - **file này đã bị XOÁ**, không còn dùng), click trái ra lệnh di chuyển, 6 điểm spawn quái cố định rải khắp map, quái chết cộng vàng trực tiếp (`roundi(hp/10)`) và hồi sinh sau 20s. Combat là bản rút gọn của `BattleScene` (crit/giáp/life-steal, chưa có skill/đạn bay).

**Lý do đổi**: người dùng muốn mô hình bảng thẻ kiểu AFK Arena (4 map, nhiều tầng, Ủy Thác/Treo máy tách biệt) thay vì 1 map mở duy nhất. `StageFarmWorld.gd` được TÁI SỬ DỤNG (không xoá file, viết lại nội dung) thành màn "xem treo máy cho vui" - vẫn spawn `TroopUnit` 2 phe và dùng công thức sát thương tương tự, nhưng giờ được `StageBoardScreen` cấu hình theo đúng team/tầng đang treo, không còn map lớn/di chuyển/spawn-point nào.

## Nguyên tắc "copy-và-chỉnh" (lịch sử, vẫn đúng cho phần City)
`OverworldWorld.gd` (đã xoá) và `StageFarmWorld.gd` (đã viết lại) từng trùng lặp logic leader/follow một cách có chủ đích, ưu tiên không động vào City tab đang chạy tốt khi xây map farm mới. Nguyên tắc này không còn áp dụng cho Ải nữa (Ải giờ không có map/leader gì cả) nhưng vẫn là bài học chung nếu sau này có map điều khiển được khác.
