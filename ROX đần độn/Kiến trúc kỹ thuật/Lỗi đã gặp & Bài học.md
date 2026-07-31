# Lỗi đã gặp & Bài học

Thuộc [[Mục lục]]. Mục đích: tránh lặp lại các lỗi/hướng-vá-sai đã tốn công thử trong quá khứ - **phần lớn kế thừa từ `vrisingDanDon`** (cùng công nghệ Godot 4.3/GDScript nên cùng loại bẫy), cộng 1 mục mới xác nhận thêm trong đợt trích xuất 13 quái. Liên quan: [[Camera & Hiệu ứng trận đấu]], [[Hoạt ảnh & Asset lính]].

## GDScript kiểu `Array[T]`
`return []` hoặc ternary trả về `Array[T]` nhưng nhánh khác là `[]` trần (không gõ kiểu) → lỗi *"Trying to return an array of type Array where expected Array[T]"*. Tương tự: gán `Dictionary.get()` (trả về Variant/Array KHÔNG gõ kiểu) thẳng vào biến `Array[String]` cũng lỗi dù runtime elements đúng kiểu - `as Array[String]` KHÔNG tự convert được. Fix đúng cho kiểu built-in (String/int/...): dùng constructor `Array(nguồn, TYPE_STRING, "", null)` để ép kiểu từng phần tử - đang dùng ở `TroopUnit.setup()` (ép `CHARACTER_ATTACK_ANIMS[character_key]` sang `Array[String]`).

**Cập nhật quan trọng (2026-07-31) - KHÁC HẲN với custom `class_name` (VD `TroopUnit`)**: `Array(source, TYPE_OBJECT, "TroopUnit", null)` **KHÔNG hoạt động đúng** - đã tưởng nhầm là dùng được (copy nguyên công thức TYPE_STRING sang TYPE_OBJECT) và code chạy "có vẻ ổn" một thời gian dài chỉ vì đường code đó chưa từng được thực thi với dữ liệu thật cho tới khi xây map AFK-farm (Ải) - lúc đó lỗi runtime `"Trying to assign an array of type X to a variable of type X"` mới lộ ra. Đã test trực tiếp bằng `godot --headless --path . --script <tmp>.gd` với `TroopUnit.new()` thật để tìm cách đúng:
- **Cách an toàn nhất, ưu tiên dùng**: `typed_array.append_array(mảng_thường_chứa_object_đúng_kiểu)` - Godot tự kiểm tra đúng kiểu từng phần tử lúc chạy, không cần constructor gì cả.
- Nếu bắt buộc phải dùng `Array()` constructor: tham số string phải là **class GỐC của Godot mà class tuỳ biến kế thừa** (VD `"Node2D"` cho `TroopUnit extends Node2D`), KHÔNG phải tên class tuỳ biến, và tham số script (thứ 4) phải là chính class đó (`TroopUnit`), không phải `null`: `Array(source, TYPE_OBJECT, "Node2D", TroopUnit)`.
- Gán trực tiếp 1 kết quả `.filter()`/`.map()` (Array trần) vào biến `Array[T]` đã gõ kiểu: **hoạt động với class gốc Godot** (VD `Node`) nhưng **lỗi với class tuỳ biến** (VD `TroopUnit`) - đã test cả 2 để xác nhận khác biệt thật, không phải đoán.
- **Bài học chung**: đừng tin 1 pattern "đã test ổn" sẽ đúng cho MỌI loại class - nếu đổi từ class gốc Godot sang custom `class_name` (hoặc ngược lại), test lại bằng script standalone thật với đúng class đó trước khi tin dùng trong code chính.

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

## `Control.mouse_filter` mặc định = Stop → nuốt mất click trên map tương tác
`ColorRect` (và nhiều `Control` khác) mặc định `mouse_filter = Stop`, nên 1 `GroundBackground` (ColorRect phủ cả map) đặt trong world 2D tương tác được sẽ **âm thầm nuốt mọi click** trước khi `_unhandled_input` của script world kịp nhận - không có lỗi/warning gì, chỉ đơn giản là "bấm không thấy phản ứng gì". Fix: `mouse_filter = 2` (Ignore) cho mọi Control thuần trang trí nằm trên vùng cần click xuyên qua.

## `get_global_mouse_position()` không đáng tin cho click/tap đơn lẻ
Hàm này đọc vị trí chuột "đã lưu" của viewport - giá trị này không được cập nhật nếu chưa có `InputEventMouseMotion` nào xảy ra trước đó (thật sự xảy ra với tap trên touch, project này nhắm mobile). Fix: tính thẳng từ `event.position` của chính sự kiện click qua `get_viewport().get_canvas_transform().affine_inverse() * event.position` - luôn đúng bất kể có motion trước đó hay không.

## Cách kiểm tra input/hành vi runtime khi không có màn hình để bấm thử
Viết 1 script debug tạm (`extends Node`, có `_process()`) như 1 autoload TẠM THỜI (thêm 1 dòng trong `project.godot [autoload]`), dùng `get_tree().current_scene` để với xuống đúng node cần test, giả lập input bằng `get_tree().root.push_input(event, true)` (bắt buộc `in_local_coords=true`, KHÔNG dùng `Input.parse_input_event()` - hàm đó áp transform cửa sổ/DisplayServer nên ra toạ độ sai lệch trong môi trường headless không có display thật), rồi `print()` state ra console, chạy bằng `godot --headless --quit-after N`. Đã dùng kỹ thuật này để bắt được cả 2 lỗi `mouse_filter`/`get_global_mouse_position()` ở trên VÀ để test spawn/combat/respawn của map AFK-farm. **Luôn xoá script debug + dòng autoload sau khi xong**, đừng để sót lại trong repo.

## Godot editor có thể tự revert code đã sửa nhiều lần, không chỉ 1 lần
Không phải lỗi lặp lại 1 lần rồi hết - đã gặp lại việc `OverworldWorld.gd`/`PartyRosterPanel.gd` (mô hình điều khiển party) tự quay về bản cũ hơn nhiều lần trong project này dù đã sửa. **Luôn đọc lại file thật trước khi giả định API/logic hiện tại là bản mới nhất mình vừa viết** - đừng tin vào trí nhớ của phiên làm việc trước, kể cả khi mình chắc chắn đã lưu đúng.

## Nguyên tắc chung rút ra
Khi 1 lỗi có vẻ "đúng công thức trên giấy nhưng sai thực tế" và đã thử vá 2-3 lần không triệt để - cân nhắc **đổi kiến trúc để né hẳn class lỗi đó** thay vì tiếp tục debug sâu hơn.
