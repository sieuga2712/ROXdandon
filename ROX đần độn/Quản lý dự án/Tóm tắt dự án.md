# Tóm tắt dự án - ROXdandon

> Bản tóm tắt ngắn để dán ra ngoài Obsidian (Claude Project, đọc nhanh lấy lại ngữ cảnh) mà không cần đọc hết vault. Chi tiết đầy đủ nằm trong [[Mục lục]] - các link `[[...]]` dưới đây không bấm được ngoài Obsidian nhưng vẫn hữu ích làm tên tra cứu.
>
> **Cập nhật gần nhất: 2026-08-03** - đợt này đổi hẳn tab "Ải" từ map AFK-farm sang bảng "Ủy Thác" + hệ "Treo máy" thật, xây THẬT tab "Ải Boss" và "Nhân vật" (trước là placeholder), thêm hệ EXP/Cấp độ đầu tiên (ảnh hưởng chỉ số chiến đấu thật). Nếu bạn đọc note này sau ngày đó và thấy mô tả không khớp code, tin code hơn note.

## Giới thiệu
Game PvE kiểu Ragnarok X thu nhỏ - **đội hình cố định 4 nhân vật** vượt qua các ải quái vật. Làm bằng **Godot 4.3** (GDScript), project tên **"ROXdandon"**. Thư mục: `C:\Users\ADMIN\Documents\ROXdandon`. Repo git riêng, nhánh `main`, **fork từ `vrisingDanDon`** (mang qua phần chiến đấu, bỏ hẳn phần thành phố/kinh tế cũ) - xem [[Chuyển thể từ vrisingDanDon]]. **Portrait mobile app thật sự** (không còn landscape) với **5 tab cố định dưới màn hình** - xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].

## Kiến trúc chung
- 6 autoload: `TroopDatabase`, `StageDatabase`, `MapDatabase`, `BossDatabase`, `GameState` (+ `ExpTables` là class tiện ích tĩnh, không phải autoload).
- Data-driven bằng Resource `.tres` + auto-scan thư mục: lính/quái (`data/troops/`), ải (`data/stages/`), map Ủy Thác (`data/maps/`), boss (`data/bosses/`).
- `run/main_scene` = `MainShell.tscn` (KHÔNG còn `Hub.tscn`) - vỏ app 5 tab (Thành phố/Ải/Ải Boss/Nhân vật/Cài đặt) + bottom nav vuốt mở rộng được. Xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- `window/size` = `540x960` (preset LDPlayer phổ biến), `stretch/aspect="expand"` (UI neo cạnh tự lấp đầy cửa sổ thật, không viền đen).

## Tiến độ theo chức năng
| Chức năng | Trạng thái | Ghi chú chi tiết |
|---|---|---|
| Vỏ app portrait + 5 tab nav | ✅ Chạy được đầy đủ | [[Vỏ ứng dụng Portrait (MainShell & Navigation)]] |
| Tab Thành phố (thuần cảnh, không điều khiển được) | ✅ Đúng yêu cầu | [[Thành phố & Ải AFK-Farm]] |
| Tab Ải - Ủy Thác (4 map, đánh tay mở khoá tầng) | ✅ Chơi được | [[Ủy Thác, Boss & Treo máy]] |
| Tab Ải - Treo máy (idle thật, tính theo thời gian) | ✅ Chơi được (chưa có save/load, xem dưới) | [[Ủy Thác, Boss & Treo máy]] |
| Tab Ải Boss (Boss Ngày 3 độ khó + Boss Khủng) | ✅ Chơi được | [[Ủy Thác, Boss & Treo máy]] |
| Tab Nhân vật (4 party thật, chỉ số hiệu dụng + EXP/cấp) | ✅ Chơi được | [[Ủy Thác, Boss & Treo máy]] |
| Tab Cài đặt | ✅ List text tĩnh (đúng yêu cầu, chưa cần logic) | - |
| Hệ EXP/Cấp độ (Base Lv + Job Lv, ảnh hưởng HP/ATK/DEF/M.DEF) | ✅ Chơi được | [[Ủy Thác, Boss & Treo máy]] |
| Đội hình (4 nhân vật cố định) | ✅ Chơi được | [[Đội hình cố định (Party)]] · [[Chỉ số lính]] |
| Roster nhân vật/quái (22 gốc + 7 quái boss mới) | ✅ Có art thật đầy đủ | [[Danh sách quái (Monster Roster)]] · [[Hoạt ảnh & Asset lính]] |
| Chiến đấu qua `BattleScene` (đấu 1 trận, thắng/thua) | ✅ Chơi được, dùng chung cho Ủy Thác lẫn Ải Boss | [[Luồng chơi (Hub → Ải → Chiến đấu)]] |
| Vàng/phần thưởng | ✅ Cộng được (BattleScene + Treo máy theo thời gian), chưa tiêu được gì | [[Vàng (GameState)]] |
| Xây dựng thành phố thật (đặt/nâng cấp công trình) | ❌ Đã bỏ hẳn (chủ đích, tab "Thành phố" chỉ là tên) | [[Chuyển thể từ vrisingDanDon]] |
| Trang bị thật | ❌ Chưa làm (ô trang bị trong tab Nhân vật chỉ tượng trưng) | [[Tiến độ & Việc còn dang dở]] |
| Gacha/chiêu mộ nhân vật | ❌ Chốt KHÔNG làm - chỉ 4 nhân vật cố định | - |
| Lưu game (save/load) | ❌ **Chưa có - việc lớn nhất còn thiếu**, `GameState` reset mỗi lần mở game (mất cả vàng/EXP/cấp độ/team treo máy) | [[Tiến độ & Việc còn dang dở]] |

Danh sách đầy đủ việc còn thiếu: [[Tiến độ & Việc còn dang dở]].

## Quyết định thiết kế đáng chú ý (để không hỏi lại/làm lại)
- **Portrait thật sự, không phải landscape thu nhỏ** - `BattleScene`/map Thành phố đều đã dựng lại `SubViewport`/world bounds theo tỉ lệ dọc, không chỉ bọc khung ngang vào giữa màn dọc.
- **Map full màn hình, top bar/bottom nav NỔI ĐÈ lên trên** (không chiếm chỗ layout) - xem thứ tự vẽ trong [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- **Thành phố KHÔNG điều khiển được** - thuần cảnh trang trí, đã xoá hẳn script điều khiển party (theo yêu cầu người dùng).
- **Ải KHÔNG còn là map** - bảng thẻ "Ủy Thác" (đánh tay, chỉ để mở khoá tầng) + "Treo máy" (idle thật, tính theo thời gian, KHÔNG bận-chéo với Ủy Thác/Boss trừ ràng buộc 1 nhân vật không thuộc 2 team treo máy cùng lúc) - xem [[Ủy Thác, Boss & Treo máy]].
- **Boss dùng CHUNG `BattleScene`/`StageFlowController` với Ủy Thác** - không có hệ combat riêng cho boss.
- **EXP/Cấp độ: Base Lv +10%/cấp CỘNG THẲNG (không dồn lãi kép) cho HP/ATK/DEF/M.DEF, Job Lv +1 ATK thẳng/cấp** - chốt rõ với người dùng để tránh số vô lý ở cấp cao (compounding 10%/cấp tới Lv.130 sẽ phá game).
- **Không còn pha "xếp quân"** trong `BattleScene` - đội hình cố định, chọn ải xong vào thẳng trận.
- **`character_key` tách "loại nhân vật" khỏi "vai trò"** - dùng CHUNG 1 catalog lính/quái cho cả party lẫn địch (kể cả boss - boss chỉ là quái mạnh reskin, không có sprite riêng).

## Bài học kỹ thuật quan trọng nhất
Xem đầy đủ ở [[Lỗi đã gặp & Bài học]]. Mục MỚI đáng chú ý nhất: **cách ép kiểu `Array` sang `Array[T]` cho custom `class_name`** (khác hẳn cách làm với class gốc Godot như `Node`) - dùng `typed_array.append_array(mảng_thường)`, KHÔNG dùng `Array(source, TYPE_OBJECT, "TenClassTuyBien", null)` (sai, đã xác nhận bằng test thật).

## Cách chơi/build
Xem [[Cách build & chạy game]]. Godot binary: `D:\godot\Godot_v4.3-stable_win64.exe` (không có trong PATH) - lệnh kiểm tra nhanh: `godot --headless --import` rồi `--headless --quit-after 60`, phải sạch không có dòng `ERROR`/`SCRIPT ERROR` nào.
