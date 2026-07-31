# Hub & Quy ước UI chung

> ⚠️ **LỖI THỜI - CHỈ GIỮ LÀM LỊCH SỬ.** `Hub.tscn` không còn là `run/main_scene` (đã thay bằng `MainShell.tscn`), `StageSelectPanel` không còn được instance ở đâu. Xem kiến trúc hiện tại ở [[Vỏ ứng dụng Portrait (MainShell & Navigation)]]. File `Hub.tscn`/`.gd` vẫn còn trong repo (chưa xoá) nhưng KHÔNG chạy.

Thuộc [[Mục lục]]. Liên quan: [[Quy ước code & Autoload]], [[Đội hình cố định (Party)]], [[Vàng (GameState)]]. Thay thế toàn bộ mảng "Giao diện & Hình ảnh" của `vrisingDanDon` (HUD thành phố, Menu xây dựng, Bảng quản lý công trình...) - xem [[Chuyển thể từ vrisingDanDon]].

## Hub (`scenes/main/Hub.tscn`, `run/main_scene`)
Màn hình gốc duy nhất - cố tình làm **tối giản**, không cố gắng đẹp:
- `PartyRoster` (HBoxContainer) - 1 thẻ/thành viên, mỗi thẻ = icon (`UIBuilders.texture_icon`, `LinhData.sprite`) + tên (`UIBuilders.small_label`). Dựng động trong `Hub._ready()` từ `GameState.PARTY_TROOP_IDS`.
- `GoldLabel` - cập nhật mỗi frame trong `_process()`, không set 1 lần lúc dựng UI (xem [[Lỗi đã gặp & Bài học]]).
- `ChonAiButton` ("Chọn ải") - mở `StageSelectPanel`.
- `StageSelectPanel`/`BattleScene` - instance sẵn làm con của `Hub`, ẩn/hiện qua `visible` (không dynamic-instance lúc runtime) - nối bằng `StageFlowController.gd`, xem [[Luồng chơi (Hub → Ải → Chiến đấu)]].

**Chưa có**: HP/level trên từng thẻ roster (chưa cần vì chưa có state tồn tại giữa các trận), màn xem chi tiết chỉ số từng nhân vật trước khi vào trận.

## Debug ID tag - quy ước GIỮ LẠI nhưng CHƯA DÙNG
`UIConstants.SHOW_DEBUG_TAGS` (const `bool`) đã mang qua từ `vrisingDanDon` để giữ quy ước, nhưng **chưa panel nào trong ROXdandon thật sự có `Label` "DebugTag"** - Hub/StageSelectPanel/BattleScene đều đủ đơn giản để không cần đánh số `#001`-`#010` như hồi còn nhiều bảng UI thành phố. Áp dụng lại nếu số lượng panel tăng lên đáng kể.

## `UIBuilders.gd` - chỉ giữ phần dùng chung, thật sự (đã rút gọn so với `vrisingDanDon`)
- `texture_icon()` - icon dùng chung (Hub roster, `StageSelectPanel`...).
- `small_label()` - label font nhỏ dùng chung.
- **Đã bỏ** `resource_icon()`/`resource_cost_row()` - phụ thuộc `Enums.ResourceType` đã xoá hẳn (không còn nhiều loại tài nguyên, xem [[Vàng (GameState)]]).

## Nguyên tắc khi thêm helper mới (không đổi)
Chỉ gộp vào `UIBuilders.gd` khi code THẬT SỰ lặp lại y hệt ở ≥2 nơi.
