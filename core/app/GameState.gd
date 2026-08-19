extends Node

## Autoload singleton: trạng thái phiên chơi (vàng + party cố định) CỘNG với
## việc giữ sống scene treo máy đang chạy nền (xem mục "Treo máy" bên dưới) -
## KHÔNG còn thuần data nữa (đổi từ lúc thêm treo máy chạy nền thật), do
## GameState là autoload duy nhất sống suốt vòng đời app nên tiện giữ luôn.
## Không lưu file (chưa cần persistence ở bản này) - reset mỗi lần mở game.

## Party cố định 4 người (mở rộng sau) - id khớp LinhData.id trong
## data/troops/: 1=Soldier(tank, hp cao), 3=Archer, 4=Wizard, 9=Priest (cả 3
## đều troop_type ARCHER -> tầm đánh xa, đứng hậu phương không cần vào cận
## chiến - xem TroopUnit.attack_range_px). Priest là character_key DUY NHẤT
## biết hồi máu (xem BattleScene._priest_cast) nên bắt buộc phải có trong đội
## nếu muốn có khả năng hồi phục.
const PARTY_TROOP_IDS: Array[int] = [1, 3, 4, 9]

var gold: int = 0

func add_gold(amount: int) -> void:
	gold += amount

## Tab "Vượt ải": tầng cao nhất đã ĐÁNH THẮNG của mỗi map (map_id -> int, 0 =
## chưa qua tầng nào - tầng 1 luôn mở sẵn, không cần entry riêng cho việc đó).
var highest_floor_cleared: Dictionary = {}

func get_highest_floor(map_id: int) -> int:
	return highest_floor_cleared.get(map_id, 0)

## Chỉ tăng, không bao giờ giảm - gọi khi thắng 1 tầng (xem StageFlowController).
func report_floor_cleared(map_id: int, floor_number: int) -> void:
	if floor_number > get_highest_floor(map_id):
		highest_floor_cleared[map_id] = floor_number

## ============================== EXP / cấp độ ==============================
## Base Lv dùng bảng ExpTables.BASE_REQUIRED, Job Lv dùng ExpTables.JOB_REQUIRED
## (chỉ "First Job" - chưa có cơ chế chuyển job trong game này). Hạ 1 quái
## (đánh tay hay treo máy) thì CẢ ĐỘI đang cùng tham gia trận/team đó nhận
## đúng LinhData.exp_reward của con đó, cộng vào CẢ base_exp_total lẫn
## job_exp_total (dùng chung 1 số, không tách riêng 2 giá trị khác nhau - xem
## grant_kill_exp).

var base_exp_total: Dictionary = {} ## troop_id (int) -> int
var job_exp_total: Dictionary = {} ## troop_id (int) -> int

func grant_kill_exp(troop_ids: Array[int], amount: int) -> void:
	for troop_id in troop_ids:
		base_exp_total[troop_id] = base_exp_total.get(troop_id, 0) + amount
		job_exp_total[troop_id] = job_exp_total.get(troop_id, 0) + amount

func get_base_level_info(troop_id: int) -> Dictionary:
	return ExpTables.level_from_total_exp(base_exp_total.get(troop_id, 0), ExpTables.BASE_REQUIRED)

func get_job_level_info(troop_id: int) -> Dictionary:
	return ExpTables.level_from_total_exp(job_exp_total.get(troop_id, 0), ExpTables.JOB_REQUIRED)

func get_base_level(troop_id: int) -> int:
	return get_base_level_info(troop_id).level

func get_job_level(troop_id: int) -> int:
	return get_job_level_info(troop_id).level

## "+10% mỗi Base Lv" CỘNG THẲNG theo gốc (không dồn lãi kép - dồn kép tới tận
## Lv.130 sẽ ra số vô lý). Lv.1 = hệ số 1.0, Lv.50 = hệ số 5.9 (+490%).
func stat_multiplier(troop_id: int) -> float:
	return 1.0 + 0.10 * (get_base_level(troop_id) - 1)

## Job Lv cộng thẳng +1 ATK/cấp, KHÔNG qua stat_multiplier - cộng sau khi ATK
## gốc đã nhân hệ số Base Lv (xem effective_atk()).
func job_atk_bonus(troop_id: int) -> int:
	return get_job_level(troop_id) - 1

func effective_hp(troop_id: int, base_hp: float) -> float:
	return base_hp * stat_multiplier(troop_id)

func effective_atk(troop_id: int, base_atk: float) -> float:
	return base_atk * stat_multiplier(troop_id) + job_atk_bonus(troop_id)

func effective_def(troop_id: int, base_def: float) -> float:
	return base_def * stat_multiplier(troop_id)

func effective_m_def(troop_id: int, base_m_def: float) -> float:
	return base_m_def * stat_multiplier(troop_id)

## ============================== Treo máy ==============================
## CHỈ 1 team treo máy tại 1 thời điểm (đã bỏ hẳn ý tưởng nhiều team/nhiều map
## + công thức DPS/thời gian trôi qua sau khi thảo luận lại). Treo máy = 1
## trận đấu THẬT chạy nền liên tục ngay khi bắt đầu (`StageFarmMap`/
## `StageFarmWorld` - instance được GameState giữ sống suốt thời gian treo,
## xem `start_idle_team_on_map`) - KHÔNG dùng công thức nào cả, quái chết thật trong
## trận nền đó thì cộng vàng (`LinhData.gold_reward`) + EXP
## (`LinhData.exp_reward`) NGAY LÚC ĐÓ cho các thành viên trong team (xem
## `StageFarmWorld._resolve_simple_attack`).
##
## "Farm bao nhiêu được bấy nhiêu" - CHẠY KHI APP ĐANG MỞ (bất kể tab nào,
## GameState là autoload nên Node này sống suốt vòng đời app), TẮT APP LÀ MẤT
## LUÔN NODE ĐÓ, không bù giờ, không có/không cần persistence cho phần này -
## đây là lựa chọn thiết kế, không phải thiếu sót.
##
## Tự động lên tầng khi thắng/đánh lại đúng tầng khi thua (xem
## StageFarmWorld._check_wipe/_advance_floor) - KHÔNG còn bước "Tạo đội treo"
## chọn map/tầng/thành viên thủ công (đã bỏ 2026-08, xem mockup đã chốt) -
## bấm 1 ải trong danh sách là tự treo NGAY bằng GameState.PARTY_TROOP_IDS, bắt
## đầu ở tầng highest_floor_cleared[map_id]+1.

const STAGE_FARM_MAP_SCENE: PackedScene = preload("res://features/stage/StageFarmMap.tscn")

var _idle_farm_map: StageFarmMap = null ## nguồn thật duy nhất cho team đang treo (stage/thành viên) - xem get_stage()/get_member_troop_ids() trên StageFarmMap/StageFarmWorld, không lưu trùng 1 bản riêng ở đây

func has_idle_team() -> bool:
	return _idle_farm_map != null

func is_troop_idling(troop_id: int) -> bool:
	return _idle_farm_map != null and troop_id in _idle_farm_map.get_member_troop_ids()

## Treo máy ở map_id, bắt đầu từ tầng highest_floor_cleared[map_id]+1 - KHÔNG
## còn kẹp ở tầng cuối cùng đã author (xem resolve_stage_for_floor(), tầng tiến
## được vô hạn nhờ EncounterGenerator sinh quái theo floor_number, không cần
## StageData thật cho từng tầng). Nếu đang treo map KHÁC thì tự dừng cái cũ
## trước, không cần rút về thủ công (đúng hành vi "bấm ải khác trong danh
## sách" của mockup). False nếu map không có StageData nào hoặc thành viên rỗng.
func start_idle_team_on_map(map_id: int, member_troop_ids: Array[int]) -> bool:
	var floors: Array[StageData] = StageDatabase.get_floors_for_map(map_id)
	if floors.is_empty() or member_troop_ids.is_empty():
		return false
	var stage: StageData = resolve_stage_for_floor(floors, get_highest_floor(map_id) + 1)

	if _idle_farm_map != null:
		stop_idle_team()
	_idle_farm_map = STAGE_FARM_MAP_SCENE.instantiate()
	add_child(_idle_farm_map)
	_idle_farm_map.configure(stage, member_troop_ids)
	return true

## Trả StageData ĐÚNG target_floor - nếu chưa author tới tầng đó thì tự
## duplicate() tầng cuối cùng có sẵn rồi đổi floor_number, để tầng luôn tiến
## được vô hạn (map_id/floor_number là 2 field DUY NHẤT còn được đọc thật ở
## luồng Ải Thường - enemy_troop_ids/stage_name/time_limit/reward_gold đều đã
## dead code từ khi treo máy chuyển sang EncounterGenerator sinh quái theo tầng).
func resolve_stage_for_floor(floors: Array[StageData], target_floor: int) -> StageData:
	for s in floors:
		if s.floor_number == target_floor:
			return s
	var synthesized: StageData = floors[-1].duplicate()
	synthesized.floor_number = target_floor
	return synthesized

func stop_idle_team() -> void:
	if _idle_farm_map != null:
		_idle_farm_map.queue_free()
		_idle_farm_map = null

## StageBoardScreen dùng để NHÚNG đúng instance đang chạy vào màn "Xem" (reparent
## - KHÔNG tạo bản mới, simulation phải tiếp tục chạy y như cũ) - null nếu
## chưa có team nào đang treo.
func get_idle_farm_map() -> StageFarmMap:
	return _idle_farm_map

## ============================== Nguyên liệu / Kho ==============================
## Kho nguyên liệu của người chơi - xem MaterialDatabase.gd cho danh sách 50
## nguyên liệu (10 nhóm x 5 cấp). CHƯA có nguồn thu thập thật nào gán vào đây
## (nhặt được lúc đánh quái/nhiệm vụ...) - đây mới chỉ là kho chứa +
## Thợ Nâng Cấp ghép cấp, xem [[Tiến độ & Việc còn dang dở]] khi cần thêm nguồn thu.

var materials: Dictionary = {} ## material_id (String, xem MaterialDatabase.make_id) -> int

func get_material_count(material_id: String) -> int:
	return materials.get(material_id, 0)

func add_material(material_id: String, amount: int) -> void:
	materials[material_id] = get_material_count(material_id) + amount

func remove_material(material_id: String, amount: int) -> bool:
	var have := get_material_count(material_id)
	if have < amount:
		return false
	materials[material_id] = have - amount
	return true

const MERGE_COST: int = 5 ## số lượng nguyên liệu cấp N cần để ghép lên 1 nguyên liệu cấp N+1

## Ghép MERGE_COST nguyên liệu `group_key` cấp `tier` thành 1 nguyên liệu cùng
## nhóm cấp `tier+1` - dùng cho Thợ Nâng Cấp (UpgraderPanel). False nếu đã ở
## cấp tối đa (MaterialDatabase.MAX_TIER) hoặc không đủ số lượng để ghép.
func merge_material_up(group_key: String, tier: int) -> bool:
	if tier >= MaterialDatabase.MAX_TIER:
		return false
	var from_id := MaterialDatabase.make_id(group_key, tier)
	if not remove_material(from_id, MERGE_COST):
		return false
	add_material(MaterialDatabase.make_id(group_key, tier + 1), 1)
	return true

## ============================== Trang bị ==============================
## Trang bị KHÔNG stack/gộp như Kho nguyên liệu ở trên - mỗi món
## (EquipmentItemData) là 1 instance ĐỘC LẬP dù trùng type_id, có thể khác
## quality/tier/tinh luyện/cường hóa. `equipment_inventory` = túi đồ (CHƯA
## mặc), `equipped` = đang mặc trên từng nhân vật (troop_id -> Dictionary
## Enums.EquipmentSlotType -> instance_id). CHƯA có nguồn thu thập thật nào
## gán vào đây (EquipmentDropTable.gd đã có công thức xác suất nhưng CHƯA nối
## vào CombatResolver lúc giết quái) - xem [[Tiến độ & Việc còn dang dở]].

var equipment_inventory: Array[EquipmentItemData] = []
var equipped: Dictionary = {} ## troop_id (int) -> Dictionary[Enums.EquipmentSlotType -> instance_id (String)]

var _next_equipment_instance_num: int = 1

func _new_equipment_instance_id() -> String:
	var id := "eq_%d" % _next_equipment_instance_num
	_next_equipment_instance_num += 1
	return id

## Thêm 1 món trang bị MỚI vào túi đồ (chưa mặc) - dùng khi rớt đồ
## (tương lai, xem EquipmentDropTable) hoặc debug/test. Trả về instance vừa tạo.
func add_equipment_item(type_id: String, quality: Enums.EquipmentQuality, tier: int, refine_level: int = 0, enhance_level: int = 0) -> EquipmentItemData:
	var item := EquipmentItemData.new()
	item.instance_id = _new_equipment_instance_id()
	item.type_id = type_id
	item.quality = quality
	item.tier = tier
	item.refine_level = refine_level
	item.enhance_level = enhance_level
	equipment_inventory.append(item)
	return item

func get_equipment_item(instance_id: String) -> EquipmentItemData:
	for item in equipment_inventory:
		if item.instance_id == instance_id:
			return item
	return null

## Trang bị đang mặc ở 1 slot của 1 nhân vật - null nếu chưa mặc gì.
func get_equipped_item(troop_id: int, slot_type: Enums.EquipmentSlotType) -> EquipmentItemData:
	var slots: Dictionary = equipped.get(troop_id, {})
	var instance_id: String = slots.get(slot_type, "")
	return get_equipment_item(instance_id) if instance_id != "" else null

## Mặc 1 món (phải đang có trong equipment_inventory) vào ĐÚNG slot khớp
## type của nó cho troop_id - món cũ đang mặc ở slot đó (nếu có) vẫn còn
## nguyên trong equipment_inventory (không mất, không tự trả về "chưa mặc" -
## đơn giản là không còn nằm trong `equipped` nữa vì đã bị món mới thế chỗ).
func equip_item(troop_id: int, instance_id: String) -> void:
	var item := get_equipment_item(instance_id)
	if item == null:
		return
	var type_data := item.get_type()
	if type_data == null:
		return
	if not equipped.has(troop_id):
		equipped[troop_id] = {}
	equipped[troop_id][type_data.slot_type] = instance_id

## Danh sách trang bị TRONG TÚI ĐỒ (chưa mặc) khớp đúng slot_type + phù hợp
## CombatGroup của nhân vật (UNIVERSAL luôn khớp mọi nhóm) - dùng để hiện bảng
## chọn khi bấm vào 1 ô trang bị, xem CharacterBoardScreen.
func get_owned_equipment_for_slot(slot_type: Enums.EquipmentSlotType, combat_group: Enums.CombatGroup) -> Array[EquipmentItemData]:
	return equipment_inventory.filter(func(item: EquipmentItemData) -> bool:
		var type_data := item.get_type()
		if type_data == null or type_data.slot_type != slot_type:
			return false
		return type_data.combat_group == combat_group or type_data.combat_group == Enums.CombatGroup.UNIVERSAL
	)

## Nhóm chiến đấu của 1 thành viên party CỐ ĐỊNH (Soldier/Archer/Wizard/Priest) -
## suy theo `character_key` (KHÔNG theo troop_type/damage_type: cả Archer lẫn
## Wizard đều là Enums.TroopType.ARCHER, và archer.tres có lỗi kế thừa
## damage_type=MAGIC dù là cung thủ vật lý - 2 field đó không đáng tin để suy
## nhóm, xem ghi chú archer.tres trong tiến độ dự án). Party cố định không
## phải gacha nên bảng cứng theo character_key là an toàn, không cần tổng quát hoá.
func get_combat_group_for_troop(troop_id: int) -> Enums.CombatGroup:
	var troop := TroopDatabase.get_by_id(troop_id)
	if troop == null:
		return Enums.CombatGroup.MELEE
	match troop.character_key:
		"archer":
			return Enums.CombatGroup.RANGED_PHYSICAL
		"wizard", "priest":
			return Enums.CombatGroup.RANGED_MAGIC
		_:
			return Enums.CombatGroup.MELEE
