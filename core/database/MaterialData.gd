class_name MaterialData
extends RefCounted

## 1 nguyên liệu (đá cường hóa/thực vật/gem/quặng) ở 1 cấp cụ thể - xem
## MaterialDatabase.gd. Không phải Resource/.tres vì danh sách 50 món này
## hoàn toàn đều đặn (10 nhóm x 5 cấp), tạo thẳng bằng code lúc _ready() rẻ
## hơn hẳn tự soạn tay 50 file .tres, giống cách ExpTables.gd dùng const
## thay vì file riêng cho bảng số đều đặn.

var id: String = "" ## "<group_key>_cap<N>", VD "gem_loai1_bang_ngoc_cap3"
var display_name: String = "" ## "Băng Ngọc cấp 3"
var category: String = "" ## "da_cuong_hoa" | "thuc_vat" | "gem" | "quang"
var group_key: String = "" ## 1 trong 10 nhóm, xem MaterialDatabase.GROUPS
var group_name: String = "" ## "Băng Ngọc" (tên nhóm không kèm cấp)
var tier: int = 1 ## 1-5
var icon: Texture2D
