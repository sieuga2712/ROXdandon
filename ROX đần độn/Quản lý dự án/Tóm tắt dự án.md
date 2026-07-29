# Tóm tắt dự án - ROXdandon

> Bản tóm tắt ngắn để dán ra ngoài Obsidian (Claude Project, đọc nhanh lấy lại ngữ cảnh) mà không cần đọc hết vault. Chi tiết đầy đủ nằm trong [[Mục lục]] - các link `[[...]]` dưới đây không bấm được ngoài Obsidian nhưng vẫn hữu ích làm tên tra cứu.

## Giới thiệu
Game PvE kiểu Ragnarok X thu nhỏ - **đội hình cố định 4 nhân vật** vượt qua các ải quái vật, auto-battle (không thao tác trong lúc đánh), **không có PvP, không có xây dựng thành phố**. Làm bằng **Godot 4.3** (GDScript), project tên **"ROXdandon"**. Thư mục: `C:\Users\ADMIN\Documents\ROXdandon`. Repo git riêng, nhánh `main`, **fork từ `vrisingDanDon`** (mang qua phần chiến đấu, bỏ hẳn phần thành phố/kinh tế) - xem [[Chuyển thể từ vrisingDanDon]].

## Kiến trúc chung (chi tiết: [[Quy ước code & Autoload]])
- 3 autoload: `TroopDatabase`, `StageDatabase`, `GameState` (so với 8 autoload của `vrisingDanDon` - phần lớn là hệ kinh tế/công trình đã bỏ).
- Data-driven bằng Resource `.tres` + auto-scan thư mục cho lính/quái (`data/troops/`) và ải (`data/stages/`) - kế thừa nguyên vẹn từ `vrisingDanDon`.
- `%TênDuyNhất` xuyên nhánh scene (kế thừa), không còn Debug tag `#001`-`#010` (chưa panel nào cần tới, xem [[Hub & Quy ước UI chung]]).

## Tiến độ theo chức năng
| Chức năng | Trạng thái | Ghi chú chi tiết |
|---|---|---|
| Đội hình (4 nhân vật cố định) | ✅ Chơi được | [[Đội hình cố định (Party)]] · [[Chỉ số lính]] |
| Roster nhân vật/quái (22 tổng) | ✅ Có art thật đầy đủ | [[Danh sách quái (Monster Roster)]] · [[Hoạt ảnh & Asset lính]] |
| Chiến đấu (auto-battle, skill, AI) | ✅ Chơi được, AI còn cơ bản | [[Luồng chơi (Hub → Ải → Chiến đấu)]] · [[AI chiến đấu]] · [[Hệ thống Kỹ năng]] |
| Hub (màn gốc thay thành phố) | ✅ Tối giản, đủ dùng | [[Hub & Quy ước UI chung]] |
| Vàng/phần thưởng | ✅ Cộng được, chưa tiêu được gì | [[Vàng (GameState)]] |
| Xây dựng/kinh tế/PvP | ❌ Đã bỏ hẳn (chủ đích) | [[Chuyển thể từ vrisingDanDon]] |
| Trang bị/lên cấp/gacha | ❌ Chưa làm, ngoài phạm vi đợt này | [[Tiến độ & Việc còn dang dở]] |
| Lưu game | ❌ Chưa có, `GameState` reset mỗi lần mở game | - |
| Âm thanh / Cốt truyện / Bản đồ | ❌ Chưa có gì (không còn map như bản cũ) | - |

Danh sách đầy đủ việc còn thiếu: [[Tiến độ & Việc còn dang dở]].

## Quyết định thiết kế đáng chú ý (để không hỏi lại/làm lại)
- **Không còn pha "xếp quân"** - đội hình cố định 4 người, chọn ải xong vào thẳng trận. Xem [[Luồng chơi (Hub → Ải → Chiến đấu)]].
- **Không còn dồn lính** (`stack_count` của `vrisingDanDon` đã bỏ hẳn) - mỗi `TroopUnit` = đúng 1 nhân vật/quái, không có khái niệm "1 icon đại diện nhiều lính".
- **Không còn squad theo trại** - AI gom nhóm "đang nhắm chung 1 mục tiêu" **lại mỗi frame** thay vì theo đội cố định (đơn giản hơn hẳn vì không còn khái niệm "trại lính = 1 đội"). Xem [[AI chiến đấu]].
- **Camera tĩnh** (không zoom/pan tay như bản cũ) - sân đấu giờ nhỏ cố định (~4 vs ~4-8 quân), không cần điều khiển camera. Xem [[Camera & Hiệu ứng trận đấu]].
- **`character_key` tách "loại nhân vật" khỏi "vai trò" (phe mình/quái)** - mang nguyên từ `vrisingDanDon`, cho phép dùng CHUNG 1 catalog 22 nhân vật cho cả party lẫn quái địch. Xem [[Danh sách quái (Monster Roster)]].

## Bài học kỹ thuật quan trọng nhất
Xem đầy đủ ở [[Lỗi đã gặp & Bài học]] - phần lớn kế thừa từ `vrisingDanDon` (SubViewport riêng cho combat camera, `AtlasTexture.margin` giữ pivot khi trim sprite - đã dùng lại chính xác công thức này để trích 13 quái mới) cộng thêm 1 mục kỹ thuật mới: **công thức chính xác của `AtlasTexture.margin`** giờ đã xác nhận rõ ràng (không còn mô tả mơ hồ như note gốc).

## Cách chơi/build
Xem [[Cách build & chạy game]].
