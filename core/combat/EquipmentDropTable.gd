class_name EquipmentDropTable
extends RefCounted

## Công thức "rớt trang bị" thuần dữ liệu (không Node/scene/state) - TÁCH
## BIỆT khỏi rớt nguyên liệu hiện có (CombatResolver._roll_material_drop(),
## dùng MaterialDatabase.random_tier1_id() - không liên quan gì tới đây).
## Dùng khi giết quái trong combat thật (BattleScene/StageFarmWorld qua
## CombatResolver) - CHƯA nối dây ở đó (resource dữ liệu 1 món trang bị/kho đồ
## chưa tồn tại, xem ghi chú cuối file) - đây mới chỉ là công thức xác suất
## chất lượng + tier, gọi rồi tự lấy 2 con số ra dùng.

const DROP_CHANCE: float = 0.5 ## 50% giết quái có rớt được 1 món trang bị hay không

## Trắng < Lam < Tím < Vàng < Cam-đỏ - CỐ ĐỊNH mọi lúc, không phụ thuộc cấp
## quái (khác tier bên dưới) - khớp thứ tự Enums.EquipmentQuality.
const QUALITY_WEIGHTS: Array[float] = [40.0, 30.0, 19.0, 10.0, 1.0]

## 8 bậc theo mỗi TIER_LEVEL_STEP (20) cấp quái - bậc N ứng lv quái trong
## khoảng [(N-1)*20+1, N*20] (N 1-based), bậc CUỐI (141+) giữ nguyên mãi,
## không có bậc 9 trở lên. Mỗi hàng 5 số ứng T1..T5 - trọng số 0 nghĩa là
## tier đó CHƯA MỞ ở bậc này (quái chưa đủ mạnh). Thay HẲN cách "mở tier theo
## ngưỡng lv 1/30/70/100/140" của bản 2026-08-19 trước đó (EquipmentItemSlot
## docstring "T1=lv1, T2=lv30..." chỉ còn ý nghĩa "lv đề xuất mặc", KHÔNG còn
## là điều kiện rớt đồ).
const TIER_LEVEL_STEP: int = 20
const TIER_WEIGHTS_BY_BAND: Array[Array] = [
	[100.0, 0.0, 0.0, 0.0, 0.0],
	[70.0, 30.0, 0.0, 0.0, 0.0],
	[55.0, 30.0, 15.0, 0.0, 0.0],
	[45.0, 33.0, 20.0, 2.0, 0.0],
	[30.0, 40.0, 25.0, 5.0, 0.0],
	[19.0, 30.0, 40.0, 10.0, 1.0],
	[16.0, 20.0, 32.0, 30.0, 2.0],
	[9.0, 15.0, 25.0, 35.0, 16.0],
]

## true = quái này rớt được 1 món trang bị - roll 1 lần, ĐỘC LẬP với rớt
## nguyên liệu (CombatResolver._roll_material_drop() vẫn roll riêng của nó).
static func rolls_drop() -> bool:
	return randf() < DROP_CHANCE

## Chất lượng món vừa rớt (Enums.EquipmentQuality) theo QUALITY_WEIGHTS.
static func roll_quality() -> Enums.EquipmentQuality:
	return _weighted_pick(QUALITY_WEIGHTS) as Enums.EquipmentQuality

## Tier món vừa rớt (1..5) theo bậc 20lv của quái vừa giết - xem
## TIER_WEIGHTS_BY_BAND. monster_level < 1 được kẹp về 1 (bậc đầu).
static func roll_tier(monster_level: int) -> int:
	var band_index: int = mini((maxi(monster_level, 1) - 1) / TIER_LEVEL_STEP, TIER_WEIGHTS_BY_BAND.size() - 1)
	return _weighted_pick(TIER_WEIGHTS_BY_BAND[band_index]) + 1 ## index 0..4 -> tier 1..5

## Roll có trọng số thuần (không cần tổng = 100, tự chia theo tổng thật) -
## trọng số 0 không bao giờ được chọn.
static func _weighted_pick(weights: Array) -> int:
	var total: float = 0.0
	for w in weights:
		total += w
	var roll: float = randf() * total
	var acc: float = 0.0
	for i in range(weights.size()):
		acc += weights[i]
		if roll < acc:
			return i
	return weights.size() - 1

## ============================== CHƯA LÀM ==============================
## Chưa có resource kiểu "1 món trang bị" (loại/icon/quality/tier/tinh
## luyện/cường hóa gộp lại) hay hệ kho đồ trang bị (khác Kho nguyên liệu -
## GameState.materials) - roll_quality()/roll_tier() ở trên mới là công thức
## xác suất thuần, CHƯA gọi từ CombatResolver, CHƯA tạo ra item thật nào.
