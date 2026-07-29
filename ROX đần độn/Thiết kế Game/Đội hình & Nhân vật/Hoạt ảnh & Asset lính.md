# Hoạt ảnh & Asset lính

Thuộc [[Mục lục]]. Liên quan: [[Danh sách quái (Monster Roster)]], [[Chỉ số lính]] (`HITBOX_DIAMETER` dựa trên kích thước thật ở đây), [[Camera & Hiệu ứng trận đấu]] (đạn bay/hiệu ứng dùng chung kỹ thuật sprite sheet).

## Nguồn asset
Bộ **"Tiny RPG Character Asset Pack 01 v2.0 - Full 22 Characters"** - nguyên file gốc nằm trong `vrisingDanDon` (`Tiny RPG Character Asset Pack 01 v2.0 -Full 22 Characters/Characters(100x100 split)/<Tên>/<Tên> with shadows/`), KHÔNG có trong repo `ROXdandon` (chỉ có kết quả đã trích xuất). 22 nhân vật = 9 người (dùng làm party, xem [[Đội hình cố định (Party)]]) + 13 quái (xem [[Danh sách quái (Monster Roster)]]). Mỗi nhân vật có dải hoạt ảnh **100×100px/khung, 1 hàng ngang mỗi file animation**: `<Tên>_Idle.png`, `<Tên>_Walk.png`, `<Tên>_Attack01/02(/03).png`, `<Tên>_Death.png`, `<Tên>_Hurt.png` (+ biến thể riêng 1 số con: `Heal` cho Priest, `Flying` thay Idle/Walk cho Bat...).

**Lưu ý**: file gốc `<Tên>.png` (không hậu tố) KHÔNG phải animation - đó là ảnh xem trước dạng lưới (contact sheet) gộp mọi animation vào 1 ảnh (VD `Orc.png` = lưới 8×6 = 800×600px) - **phải bỏ qua**, chỉ dùng các file có hậu tố riêng từng animation.

## Chuẩn đóng gói sprite sheet (bắt buộc áp dụng cho MỌI sprite sheet tạo sau này)
1. Cắt từng khung 100×100 từ file animation gốc (số khung = `chiều_rộng_file / 100`).
2. Cắt sát nội dung theo alpha-bbox, đệm 1px mỗi cạnh (clamp trong 0..100).
3. Đóng gói khít các khung đã cắt vào 1 sheet, **1 hàng duy nhất** (`y = 0` cho mọi khung), không có khoảng hở giữa các khung - `region = Rect2(x_chạy_dồn, 0, w_đã_cắt, h_đã_cắt)`.
4. Dùng `AtlasTexture.margin` để giữ đúng pivot khung 100×100 GỐC - **công thức chính xác (xác nhận bằng cách đối chiếu ngược dữ liệu thật, note gốc bên `vrisingDanDon` chỉ mô tả mơ hồ)**:
   ```
   margin = Rect2(bbox_left, bbox_top, 100 - w_đã_cắt, 100 - h_đã_cắt)
   ```
   tức `region.size + margin.size` LUÔN LUÔN = `(100, 100)` (kích thước khung gốc) - Godot vẽ lại đúng vị trí ban đầu bằng cách đặt phần đã cắt tại `margin.position` bên trong khung ảo 100×100, animation không lệch/rung dù mỗi khung có kích thước cắt khác nhau.
5. **Icon UI tĩnh (không phải animation) thì KHÔNG cần `margin`** - chỉ cần `region` trỏ đúng khung đầu (thường là `idle` khung 0), để icon co khít đúng phần nhân vật.

### Phát hiện quan trọng (kế thừa từ `vrisingDanDon`)
Nội dung nhân vật thật trong khung 100×100 gốc chỉ chiếm **~17-34px** (phần lớn còn lại trong suốt) - nguyên nhân gốc khiến "nhân vật hiển thị bé" nếu chỉ chỉnh `scale` mà không trim đúng.

## Kích thước hiển thị hiện tại
- `AnimatedSprite2D.scale = 1.5` (giữ nguyên từ `vrisingDanDon`).
- `HITBOX_DIAMETER = 36` - xem công thức đầy đủ ở [[Chỉ số lính]].

## Animation states
`idle`, `walk`, `attack01`/`02`/`03` (số lượng đòn khác nhau theo nhân vật - `TroopUnit.play_attack()` chọn ngẫu nhiên 1 trong các đòn có sẵn mỗi lần đánh), `death`. Riêng Priest có thêm `heal`.

- **Không dùng animation "hurt"** - dù file `Frames.tres` vẫn build sẵn animation `hurt` (để nhất quán định dạng), `TroopUnit` không bao giờ gọi `play("hurt")` - thay bằng nháy đỏ nhanh (`modulate` tween 0.15s, `TroopUnit._flash_hurt()`), không ngắt animation đang chạy dở.
- `TroopUnit._is_busy()` chặn walk/idle chen ngang animation `heal`/đòn đánh đang chạy dở cho tới khi tự hết.

## Kiến trúc code
- `TroopUnit` là `AnimatedSprite2D`-based. `play_*()` (idle/walk/attack/heal) là hàm công khai để `BattleScene` gọi đúng lúc - bản thân `TroopUnit` không tự chạy AI, xem [[AI chiến đấu]].
- **2 script Python chạy 1 lần, không thuộc project Godot** (không có trong `scripts/`, chỉ chạy 1 lần ngoài editor rồi bỏ):
  - Script trích 9 nhân vật người - viết ở phiên làm việc trước, không còn giữ lại.
  - `extract_monsters.py` (trích 13 quái, đợt này) - đọc trực tiếp từ folder gốc `Tiny RPG Character Asset Pack...` bên `vrisingDanDon`, ghi thẳng ra `ROXdandon/assets/troops/<key>/` + `ROXdandon/data/troops/<key>.tres`. Không commit vào repo (chạy 1 lần, không cần chạy lại trừ khi cần trích thêm nhân vật mới từ CÙNG bộ asset pack).
- Thư mục: `assets/troops/<character_key>/` (mỗi nhân vật 1 thư mục riêng, chứa `<Tên>Sheet.png` + `<Tên>Frames.tres` + `<Tên>Icon.tres`) - **đúng quy ước y hệt `vrisingDanDon`**, chỉ khác không còn `orc/` (nhân vật thừa từ thời trước, không dùng) và có thêm 13 thư mục quái mới.
