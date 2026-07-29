# Cách build & chạy game

Thuộc [[Mục lục]].

- **Test nhanh**: mở project `C:\Users\ADMIN\Documents\ROXdandon` trong Godot 4.3, bấm **F5**.
- **Xuất file `.exe` chạy độc lập**: `Project → Export...` - **chưa có preset export nào cho ROXdandon** (khác `vrisingDanDon` vốn đã có sẵn preset `"ClashOfClanDanDon"`) - cần tự tạo preset Windows Desktop trước, và cài Export Templates khớp bản Godot 4.3 nếu máy chưa có.
- **Kiểm tra không cần mở editor** (dùng khi sửa code/asset bằng tool ngoài Godot): `"D:\godot\Godot_v4.3-stable_win64.exe" --headless --path "C:\Users\ADMIN\Documents\ROXdandon" --import` (bắt lỗi parse/resource) rồi `--quit-after 60` (bắt lỗi runtime `_ready()`/autoload) - không thay được việc F5 chơi thật, chỉ xác nhận project boot sạch.
