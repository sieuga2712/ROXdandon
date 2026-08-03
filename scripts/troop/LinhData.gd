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
@export var attack_range: float = 100.0 ## xem công thức quy đổi ra phạm vi tấn công trong TroopUnit.attack_range_px()

## Hạ được 1 con này thì CẢ TEAM (mọi thành viên đang cùng đội - đánh tay hay
## treo máy) nhận đúng số EXP này, cộng vào cả Base EXP lẫn Job EXP (xem
## GameState.grant_kill_exp) - chưa phân biệt 2 giá trị Base/Job riêng, cùng 1
## số cho cả 2 pool để đơn giản.
@export var exp_reward: int = 5
