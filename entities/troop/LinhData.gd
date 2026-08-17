class_name LinhData
extends Resource

## Mô tả 1 loại nhân vật (lính/quái). Cùng dùng 1 bộ chỉ số base - chỉ khác
## damage_type + attack_range. Thêm loại mới chỉ cần thêm 1 .tres trong
## data/troops/ - TroopDatabase auto-scan thư mục đó, không cần sửa code.

@export var id: int = 0
@export var troop_type: Enums.TroopType = Enums.TroopType.NORMAL
@export var troop_name: String = ""
@export var damage_type: Enums.DamageType = Enums.DamageType.PHYSICAL
@export var sprite: Texture2D
## Khớp tên trong TroopUnit.CHARACTER_FRAMES/CHARACTER_ATTACK_ANIMS - chọn bộ
## hoạt ảnh chiến đấu (không liên quan hình sprite ở trên, chỉ dùng làm icon
## UI) - xem assets/troops/<character_key>/.
@export var character_key: String = ""
@export var skill_name: String = "Đánh mạnh"

@export_group("Chỉ số")
@export var hp: int = 100
@export var atk: int = 10
@export var def: int = 5
@export var m_def: int = 5
@export var atk_speed: float = 10.0 ## 1 điểm = 1 giây đánh được 0.1 lần
@export var move_speed: float = 5.0
@export var spellcast_speed: float = 0.0
@export var crit_rate: float = 0.3 ## 30%
@export var crit_damage: float = 1.5 ## 150% sát thương đòn chí mạng
@export var armor_penetration: float = 10.0 ## 1 điểm = bỏ qua 1% giáp tương ứng (DEF/M.DEF đối phương)
@export var life_steal: float = 0.01 ## 1% - hồi máu theo % sát thương gây ra
@export var regen_hp: float = 10.0 ## hồi mỗi 5 giây

## Tầm đánh CHỈ được gán 1 trong 3 mốc dưới đây - không dùng số tự do khác.
## Quy đổi ra pixel thật dùng CHUNG 1 hệ số cho cả 3 mốc (xem
## TroopUnit.RANGE_COEF/attack_range_px()) - không còn phân biệt theo
## troop_type NORMAL/ARCHER như trước, tầm xa/gần giờ chọn TRỰC TIẾP qua field
## này cho từng loại lính/quái.
## RANGE_MID/RANGE_FAR đang tạm x10 (2.0->20.0, 4.0->40.0) để THỬ dãn đội hình
## chiến đấu ra xa nhau hơn (đánh giá bằng mắt xem có ổn không - trước đó với
## RANGE_COEF dùng chung 0.1, mọi loại tầm đánh chỉ chênh nhau rất ít khiến
## các đơn vị đứng dính sát nhau). RANGE_NEAR giữ nguyên 1.0 - chỉ x10 tầm
## trung/xa theo đúng yêu cầu.
const RANGE_NEAR: float = 1.0
const RANGE_MID: float = 20.0
const RANGE_FAR: float = 40.0

@export var attack_range: float = RANGE_NEAR ## xem RANGE_NEAR/RANGE_MID/RANGE_FAR ở trên

## Hạ được 1 con này thì CẢ TEAM (mọi thành viên đang cùng đội - đánh tay hay
## treo máy) nhận đúng số EXP này, cộng vào cả Base EXP lẫn Job EXP (xem
## GameState.grant_kill_exp) - chưa phân biệt 2 giá trị Base/Job riêng, cùng 1
## số cho cả 2 pool để đơn giản.
@export var exp_reward: int = 5

## Hạ được 1 con này (đánh tay hay treo máy) thì cộng thẳng đúng số vàng này
## vào GameState.gold NGAY LÚC ĐÓ - đúng kiểu "phần thưởng tính riêng theo
## từng quái hạ được" (Ragnarok X), KHÔNG còn dùng StageData.reward_gold cho
## treo máy nữa (Ủy Thác/Boss đánh tay vẫn giữ nguyên thưởng cố định theo
## tầng khi thắng, xem BattleScene._end_battle - 2 hệ không cần khớp nhau).
@export var gold_reward: int = 5
