# Quy ước code & Autoload

Thuộc [[Mục lục]]. Liên quan: [[Hub & Quy ước UI chung]], [[Lỗi đã gặp & Bài học]].

## Autoload singletons
Đăng ký trong `project.godot`: `TroopDatabase`, `StageDatabase`, `GameState` - chỉ **3 autoload** (so với 8 của `vrisingDanDon`: `BuildingDatabase`, `TroopDatabase`, `StageDatabase`, `ResourceManager`, `PopulationManager`, `BuildingRegistry`, `ProductionManager`, `NotificationManager` - phần lớn là hệ kinh tế/công trình đã bỏ hẳn, xem [[Chuyển thể từ vrisingDanDon]]).

## Data-driven bằng Resource `.tres` + auto-scan thư mục (giữ nguyên)
`TroopDatabase`/`StageDatabase` quét toàn bộ `.tres` trong thư mục tương ứng lúc khởi động (`data/troops/`, `data/stages/`) bằng `DirAccess` - thêm nội dung mới chỉ cần thả file `.tres`, không sửa code. Nguyên văn kiến trúc từ `vrisingDanDon`.

- **Áp dụng cho**: nhân vật/quái (`LinhData`), ải (`StageData`).
- **KHÔNG áp dụng cho phân loại CỐ ĐỊNH theo thiết kế** - VD `Enums.Team` (PLAYER/ENEMY), `Enums.TroopType` (NORMAL/ARCHER). Quyết định có chủ đích, không phải thiếu sót.

## `%TênDuyNhất` (unique_name_in_owner)
Dùng xuyên suốt để script truy cập node ở nhánh khác trong `Hub.tscn`, thay vì đường dẫn `$A/B/C` dễ vỡ. Chỉ hoạt động xuyên nhánh khi cả 2 node cùng thuộc 1 owner scene ĐÃ LOAD SẴN - đây là lý do `StageSelectPanel`/`BattleScene` đặt sẵn làm con `Hub.tscn` (overlay ẩn/hiện) thay vì dynamic-instance lúc runtime, xem [[Luồng chơi (Hub → Ải → Chiến đấu)]].

## Đã bỏ hẳn so với `vrisingDanDon`
- **Icon tài nguyên tự nạp theo quy ước tên file** (`Enums.get_resource_icon()`) - không còn `Enums.ResourceType` nào để tự nạp icon theo.
- **`ResourceAmount.gd`** (Resource mô tả "loại + số lượng" dùng cho chi phí xây/tuyển quân) - không còn khái niệm chi phí gì cả trong ROXdandon.
- `LinhData.recruit_costs` - xem [[Đội hình cố định (Party)]].

## `UIBuilders.gd`
Xem [[Hub & Quy ước UI chung]].
