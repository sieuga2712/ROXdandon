class_name MapData
extends Resource

## Mô tả 1 map trong tab "Vượt ải" (bảng kiểu uỷ thác) - mỗi map chứa nhiều
## tầng tăng dần độ khó (mỗi tầng = 1 StageData, xem StageData.map_id/floor).
## Thêm map mới chỉ cần thêm 1 .tres trong data/maps/ - MapDatabase auto-scan
## thư mục đó, không cần sửa code.

@export var id: int = 0
@export var map_name: String = ""
@export var card_color: Color = Color(0.3, 0.5, 0.3) ## tint thẻ map - chưa có art riêng từng map ở v1

## Nội dung thẻ map trên tab "Ủy Thác" (theo mockup bảng uỷ thác) - toàn bộ là
## text/emoji tĩnh, không có ý nghĩa gameplay riêng (chỉ để đọc cho có thông
## tin, không dùng để tính toán gì).
@export var map_icon: String = "🌲"
@export var map_type: String = "KHU VỰC RỪNG"
@export var win_condition: String = "Hạ toàn bộ địch"
@export var difficulty_label: String = "★★☆"
