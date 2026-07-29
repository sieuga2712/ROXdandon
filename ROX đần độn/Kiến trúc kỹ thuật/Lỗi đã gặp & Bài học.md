# Lỗi đã gặp & Bài học

Thuộc [[Mục lục]]. Mục đích: tránh lặp lại các lỗi/hướng-vá-sai đã tốn công thử trong quá khứ - **phần lớn kế thừa từ `vrisingDanDon`** (cùng công nghệ Godot 4.3/GDScript nên cùng loại bẫy), cộng 1 mục mới xác nhận thêm trong đợt trích xuất 13 quái. Liên quan: [[Camera & Hiệu ứng trận đấu]], [[Hoạt ảnh & Asset lính]].

## GDScript kiểu `Array[T]`
`return []` hoặc ternary trả về `Array[T]` nhưng nhánh khác là `[]` trần (không gõ kiểu) → lỗi *"Trying to return an array of type Array where expected Array[T]"*. Tương tự: gán `Dictionary.get()` (trả về Variant/Array KHÔNG gõ kiểu) thẳng vào biến `Array[String]` cũng lỗi dù runtime elements đúng kiểu - `as Array[String]` KHÔNG tự convert được. Fix đúng: dùng constructor `Array(nguồn, TYPE_STRING, "", null)` để ép kiểu từng phần tử - đang dùng lại đúng kỹ thuật này ở `TroopUnit.setup()` (ép `CHARACTER_ATTACK_ANIMS[character_key]` sang `Array[String]`).

## `Camera2D`/`SubViewport` - áp dụng NGAY TỪ ĐẦU, không phải debug lại
`vrisingDanDon` từng tốn công debug lỗi zoom sai khi 2 `Camera2D` cùng chia sẻ 1 viewport (`make_current()`/gán `current` không chuyển quyền sạch), cuối cùng phải đổi hẳn sang `SubViewport` riêng cho mỗi khung nhìn (chỉ 1 `Camera2D`/viewport thì luôn tự động đúng). **ROXdandon áp dụng kiến trúc này NGAY TỪ ĐẦU** (`BattleScene.tscn` có `SubViewport` riêng từ lúc scaffold, không có `Main.tscn`/city camera nào để tranh chấp) - bài học cũ giúp né hẳn lớp lỗi này thay vì phải gặp lại.

## Sprite sheet: margin giữ pivot khi trim - đã dùng lại đúng công thức, giờ CHÍNH XÁC hơn
`vrisingDanDon` mô tả kỹ thuật này khá mơ hồ ("margin bù lại phần đã cắt"). Đợt trích 13 quái mới đã **xác nhận công thức chính xác** bằng cách đối chiếu ngược dữ liệu `.tres` có sẵn: `margin = Rect2(bbox_left, bbox_top, 100 - w_đã_cắt, 100 - h_đã_cắt)` - tức `region.size + margin.size` LUÔN = kích thước khung gốc (100×100). Xem chi tiết đầy đủ ở [[Hoạt ảnh & Asset lính]].

## Asset mới tạo qua script ngoài Godot - lỗi "Could not preload resource"/UID lệch thoáng qua
Khi tạo file `.png`/`.tres` mới bằng script Python chạy ngoài Godot, Godot editor cần thời gian NGẦM để import (`.import` + cache). Xác nhận lại đợt này: khi COPY nguyên file `.tres`/`.png` từ `vrisingDanDon` sang `ROXdandon` (không copy kèm `.import` cũ), lần `--import` đầu tiên báo warning `invalid UID` cho mọi file `*Frames.tres` tham chiếu `ext_resource` bằng `uid://` cũ (UID gắn với project `vrisingDanDon`, không tồn tại trong `ROXdandon`) - **không phải lỗi thật**, Godot tự fallback dùng text path và load đúng, warning này vô hại và có thể bỏ qua khi kiểm tra output headless import.

## Godot editor tự lưu đè file đang mở
Nếu Godot Editor đang mở project trong lúc code bị sửa từ bên ngoài, cần chọn "Discard local changes and reload" khi được hỏi, không thì mất thay đổi.

## Label chỉ set 1 lần lúc dựng UI, không tự cập nhật theo thời gian
Bất kỳ label nào hiển thị số liệu ĐỘNG phải được lưu tham chiếu lại và cập nhật trong `_process()`, không chỉ set 1 lần lúc dựng node - áp dụng ngay từ đầu cho `Hub.GoldLabel` (đọc `GameState.gold` mỗi frame) để né lại đúng lỗi này.

## Hover-based UI dễ vỡ (bài học từ `vrisingDanDon`, chưa gặp lại vì ROXdandon chưa có UI kiểu này)
Panel hiện/ẩn theo `mouse_entered`/`mouse_exited` khi là SIBLING đặt cạnh thẻ kích hoạt dễ vỡ do khoảng hở hình học nhỏ - **bài học: ưu tiên bấm nút tường minh** nếu sau này ROXdandon cần thêm panel info tương tự (VD xem chi tiết chỉ số từng nhân vật trước trận, xem [[Tiến độ & Việc còn dang dở]]).

## Nguyên tắc chung rút ra
Khi 1 lỗi có vẻ "đúng công thức trên giấy nhưng sai thực tế" và đã thử vá 2-3 lần không triệt để - cân nhắc **đổi kiến trúc để né hẳn class lỗi đó** thay vì tiếp tục debug sâu hơn.
