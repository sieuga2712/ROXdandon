# core/shared

## Mục đích
Toolkit dựng UI dùng chung — hằng số style + hàm helper build control, tránh lặp code giữa các panel trong `features/city` (Upgrader/Warehouse/Placeholder) và `legacy/StageSelectPanel`.

## File chính
- `UIBuilders.gd` — hàm dựng sẵn các control lặp lại (panel, nút, label theo style chuẩn).
- `UIConstants.gd` — hằng số màu/kích thước/font dùng chung.

## Entry Point
Không có class chính — `class_name`/hàm static gọi trực tiếp từ bất kỳ script nào cần, không cần instance.

## Public API
Xem trực tiếp `UIBuilders.gd`/`UIConstants.gd` — đây là toolkit thuần hàm tiện ích, không có state, không có side-effect ngoài việc trả về Control node.

## Module được phép gọi
Không phụ thuộc module nào khác trong project.

## Ai được gọi vào đây
Bất kỳ module nào cần dựng UI theo đúng style chung — hiện đang dùng bởi `features/city` và `legacy/StageSelectPanel`.

## Tài liệu thiết kế liên quan
Chưa có tài liệu thiết kế riêng cho phần này trong `ROX đần độn/` — đây là toolkit kỹ thuật thuần, không phải quyết định thiết kế gameplay.
