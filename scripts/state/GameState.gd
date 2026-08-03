extends Node

## Autoload singleton: trạng thái phiên chơi tối giản - vàng + party cố định.
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
## Mỗi map tối đa IDLE_MAX_TEAMS_PER_MAP team, 1 nhân vật chỉ thuộc 1 team
## treo máy tại 1 thời điểm - KHÔNG liên quan gì tới Ủy Thác/Boss (đánh tay
## dùng party riêng, không bị chặn bởi treo máy, xem StageFlowController). Treo
## máy KHÔNG giới hạn thời gian - mỗi lần settle_idle_team() được gọi (lúc mở
## màn treo máy, hoặc tick định kỳ khi đang xem) sẽ cộng dồn gold+exp theo số
## "chu kỳ" (mỗi chu kỳ = time_limit giây của StageData đó, giống 1 lần thắng
## tay) đã trôi qua kể từ lần settle trước, dùng Time.get_unix_time_from_system()
## (giờ hệ thống thật, không phải giờ trong game).
##
## LƯU Ý: GameState hiện KHÔNG lưu file (reset khi tắt app - xem đầu file) nên
## "treo máy tính cả lúc tắt app" mới đúng về CÔNG THỨC (dựa timestamp thật);
## tắt app hẳn rồi mở lại vẫn mất tiến độ treo máy do CHƯA có hệ save/load -
## cần làm riêng 1 tính năng persistence mới xử lý được phần đó.

const IDLE_MAX_TEAMS_PER_MAP: int = 3

var idle_teams: Array[Dictionary] = []
var _next_idle_team_id: int = 1

func is_troop_idling(troop_id: int) -> bool:
	for team in idle_teams:
		if troop_id in team["member_troop_ids"]:
			return true
	return false

func get_idle_team_count_for_map(map_id: int) -> int:
	var count := 0
	for team in idle_teams:
		var stage: StageData = StageDatabase.get_by_id(team["stage_id"])
		if stage != null and stage.map_id == map_id:
			count += 1
	return count

## Trả về team mới tạo, hoặc null nếu vi phạm ràng buộc (map đã đủ
## IDLE_MAX_TEAMS_PER_MAP team, hoặc có nhân vật đang treo ở team khác).
func start_idle_team(stage_id: int, member_troop_ids: Array[int]) -> Variant:
	var stage: StageData = StageDatabase.get_by_id(stage_id)
	if stage == null or member_troop_ids.is_empty():
		return null
	if get_idle_team_count_for_map(stage.map_id) >= IDLE_MAX_TEAMS_PER_MAP:
		return null
	for troop_id in member_troop_ids:
		if is_troop_idling(troop_id):
			return null
	var team: Dictionary = {
		"id": _next_idle_team_id,
		"stage_id": stage_id,
		"member_troop_ids": member_troop_ids,
		"last_tick_at": Time.get_unix_time_from_system(),
	}
	_next_idle_team_id += 1
	idle_teams.append(team)
	return team

func stop_idle_team(team_id: int) -> void:
	settle_idle_team_by_id(team_id)
	idle_teams = idle_teams.filter(func(t: Dictionary) -> bool: return t["id"] != team_id)

func settle_idle_team_by_id(team_id: int) -> void:
	for team in idle_teams:
		if team["id"] == team_id:
			settle_idle_team(team)
			return

## Cộng dồn gold+exp theo số chu kỳ đã trôi qua kể từ last_tick_at, dời
## last_tick_at lên đúng bằng số chu kỳ đó (phần dư giữ lại cho lần sau) - gọi
## hàm này bất cứ lúc nào cần số liệu mới nhất (mở màn treo máy, tick định kỳ,
## trước khi rút team về).
func settle_idle_team(team: Dictionary) -> void:
	var stage: StageData = StageDatabase.get_by_id(team["stage_id"])
	if stage == null or stage.time_limit <= 0.0:
		return
	var now: float = Time.get_unix_time_from_system()
	var elapsed: float = now - team["last_tick_at"]
	var cycles: int = int(elapsed / stage.time_limit)
	if cycles <= 0:
		return
	team["last_tick_at"] += cycles * stage.time_limit

	add_gold(cycles * stage.reward_gold)
	var exp_per_cycle := 0
	for i in range(stage.enemy_troop_ids.size()):
		var enemy: LinhData = TroopDatabase.get_by_id(stage.enemy_troop_ids[i])
		if enemy != null:
			exp_per_cycle += enemy.exp_reward * stage.enemy_troop_counts[i]
	if exp_per_cycle > 0:
		grant_kill_exp(team["member_troop_ids"], exp_per_cycle * cycles)
