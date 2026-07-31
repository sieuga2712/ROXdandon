# Tóm tắt dự án - ROXdandon

> Bản tóm tắt ngắn để dán ra ngoài Obsidian (Claude Project, đọc nhanh lấy lại ngữ cảnh) mà không cần đọc hết vault. Chi tiết đầy đủ nằm trong [[Mục lục]] - các link `[[...]]` dưới đây không bấm được ngoài Obsidian nhưng vẫn hữu ích làm tên tra cứu.
>
> **Cập nhật gần nhất: 2026-07-31** - đợt này chuyển toàn bộ app sang portrait mobile + xây map Thành phố + map Ải AFK-farm. Nếu bạn đọc note này sau ngày đó và thấy mô tả không khớp code, tin code hơn note.

## Giới thiệu
Game PvE kiểu Ragnarok X thu nhỏ - **đội hình cố định 4 nhân vật** vượt qua các ải quái vật. Làm bằng **Godot 4.3** (GDScript), project tên **"ROXdandon"**. Thư mục: `C:\Users\ADMIN\Documents\ROXdandon`. Repo git riêng, nhánh `main`, **fork từ `vrisingDanDon`** (mang qua phần chiến đấu, bỏ hẳn phần thành phố/kinh tế cũ) - xem [[Chuyển thể từ vrisingDanDon]]. **Portrait mobile app thật sự** (không còn landscape) với **5 tab cố định dưới màn hình** - xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].

## Kiến trúc chung
- 3 autoload: `TroopDatabase`, `StageDatabase`, `GameState`.
- Data-driven bằng Resource `.tres` + auto-scan thư mục cho lính/quái (`data/troops/`) và ải (`data/stages/`).
- `run/main_scene` = `MainShell.tscn` (KHÔNG còn `Hub.tscn`) - vỏ app 5 tab (Thành phố/Ải/Ải Boss/Nhân vật/Cài đặt) + bottom nav vuốt mở rộng được. Xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- `window/size` = `540x960` (preset LDPlayer phổ biến), `stretch/aspect="expand"` (UI neo cạnh tự lấp đầy cửa sổ thật, không viền đen).

## Tiến độ theo chức năng
| Chức năng | Trạng thái | Ghi chú chi tiết |
|---|---|---|
| Vỏ app portrait + 5 tab nav | ✅ Chạy được đầy đủ | [[Vỏ ứng dụng Portrait (MainShell & Navigation)]] |
| Tab Thành phố (đi lại/tương tác cảnh vật) | ✅ Chơi được | [[Thành phố & Ải AFK-Farm]] |
| Tab Ải (map AFK-farm, quái hồi sinh) | ✅ Chơi được (combat rút gọn) | [[Thành phố & Ải AFK-Farm]] |
| Tab Ải Boss | ❌ Placeholder rỗng, chưa xây | [[Tiến độ & Việc còn dang dở]] |
| Tab Nhân vật | ❌ Placeholder rỗng, chưa xây | [[Tiến độ & Việc còn dang dở]] |
| Tab Cài đặt | ✅ List text tĩnh (đúng yêu cầu, chưa cần logic) | - |
| Đội hình (4 nhân vật cố định) | ✅ Chơi được | [[Đội hình cố định (Party)]] · [[Chỉ số lính]] |
| Roster nhân vật/quái (22 tổng) | ✅ Có art thật đầy đủ | [[Danh sách quái (Monster Roster)]] · [[Hoạt ảnh & Asset lính]] |
| Chiến đấu qua `BattleScene` (đấu 1 trận, thắng/thua) | ✅ Chơi được, dành riêng cho Ải Boss sau này | [[Luồng chơi (Hub → Ải → Chiến đấu)]] |
| Vàng/phần thưởng | ✅ Cộng được (cả từ farm lẫn BattleScene), chưa tiêu được gì | [[Vàng (GameState)]] |
| Xây dựng thành phố thật (đặt/nâng cấp công trình) | ❌ Đã bỏ hẳn (chủ đích, tab "Thành phố" chỉ là tên) | [[Chuyển thể từ vrisingDanDon]] |
| Trang bị/lên cấp/gacha | ❌ Chưa làm | [[Tiến độ & Việc còn dang dở]] |
| Lưu game | ❌ Chưa có, `GameState` reset mỗi lần mở game | - |

Danh sách đầy đủ việc còn thiếu: [[Tiến độ & Việc còn dang dở]].

## Quyết định thiết kế đáng chú ý (để không hỏi lại/làm lại)
- **Portrait thật sự, không phải landscape thu nhỏ** - `BattleScene`/map Thành phố/map Ải đều đã dựng lại `SubViewport`/world bounds theo tỉ lệ dọc, không chỉ bọc khung ngang vào giữa màn dọc.
- **Map full màn hình, top bar/bottom nav NỔI ĐÈ lên trên** (không chiếm chỗ layout) - xem thứ tự vẽ trong [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- **Điều khiển party trên map (City/Ải)**: 1 leader (chọn qua `PartyRosterPanel`) + 3 người LUÔN tự bám theo, click trái ra lệnh di chuyển. Từng thử mô hình 3 trạng thái phức tạp hơn (điều khiển/đang theo/độc lập) nhưng bản đang chạy là bản đơn giản - xem [[Tiến độ & Việc còn dang dở]].
- **Map Ải = AFK-farm, KHÁC HẲN `BattleScene`** - combat trực tiếp trên map thường trực, quái hồi sinh, không có thắng/thua. `BattleScene` (đấu 1 trận, có thắng/thua/thời gian) giữ nguyên, dành cho Ải Boss sau này.
- **Không còn pha "xếp quân"** trong `BattleScene` - đội hình cố định, chọn ải xong vào thẳng trận.
- **`character_key` tách "loại nhân vật" khỏi "vai trò"** - dùng CHUNG 1 catalog 22 nhân vật cho cả party lẫn quái địch.

## Bài học kỹ thuật quan trọng nhất
Xem đầy đủ ở [[Lỗi đã gặp & Bài học]]. Mục MỚI đáng chú ý nhất: **cách ép kiểu `Array` sang `Array[T]` cho custom `class_name`** (khác hẳn cách làm với class gốc Godot như `Node`) - dùng `typed_array.append_array(mảng_thường)`, KHÔNG dùng `Array(source, TYPE_OBJECT, "TenClassTuyBien", null)` (sai, đã xác nhận bằng test thật).

## Cách chơi/build
Xem [[Cách build & chạy game]]. Godot binary: `D:\godot\Godot_v4.3-stable_win64.exe` (không có trong PATH) - lệnh kiểm tra nhanh: `godot --headless --import` rồi `--headless --quit-after 60`, phải sạch không có dòng `ERROR`/`SCRIPT ERROR` nào.
