# legacy

## Mục đích
File cũ không còn dùng — giữ lại để tham khảo lịch sử, **không import/instance ở bất kỳ đâu trong project đang chạy**. Không xoá, không sửa nội dung.

## File chính
- `Hub.tscn` — main scene cũ trước khi chuyển sang kiến trúc `core/app/MainShell.tscn` 5-tab. Bên trong vẫn còn tham chiếu path cũ (kể cả 1 path tới `scripts/main/Hub.gd` — file đã bị xoá từ trước, không phải lỗi do lần tái cấu trúc này) — **cố ý không sửa** theo đúng quy tắc "không sửa nội dung file legacy".
- `StageSelectPanel.gd` / `.tscn` — panel chọn tầng kiểu cũ, trước khi tab Ải đổi sang bảng thẻ Ủy Thác/Treo máy.

## Entry Point
Không có — không được gọi từ bất kỳ scene/script nào đang hoạt động.

## Public API
Không áp dụng.

## Module được phép gọi
Không áp dụng — không sửa, không mở rộng.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Giao diện/Hub & Quy ước UI chung.md` — đã đánh dấu thay thế hoàn toàn bởi `ROX đần độn/Giao diện/Vỏ ứng dụng Portrait (MainShell & Navigation).md`.
- `ROX đần độn/Thiết kế Game/Bản đồ/Thành phố & Ải AFK-Farm.md` — phần liên quan `StageSelectPanel` đã SUPERSEDED, xem `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md`.
