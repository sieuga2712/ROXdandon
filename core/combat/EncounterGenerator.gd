class_name EncounterGenerator
extends RefCounted

## Công thức "quái sinh ra sao" DÙNG CHUNG bởi StageFarmWorld (Ải Thường -
## tăng theo floor_number thật) và BattleScene (Ải Boss - trash-wave trước
## wave boss thật, xem StageData.boss_trash_wave_count/boss_trash_monster_level).
## CHỈ chứa công thức/số liệu THUẦN (không Node/scene/state) - 2 "công cụ
## chiến đấu" tự lo spawn/vị trí/timing riêng, đúng quy ước duplicate STATE
## MACHINE đã có giữa StageFarmWorld/BattleScene (xem ghi chú đầu 2 file đó).

## 13 loại quái "trơn" liền id (Tiny RPG Character Asset Pack) - xem
## data/troops/*.tres: 10=orc … 22=necromancer. Loại trừ id lính người
## (1-9,23 = party/chưa dùng) và id 200+ (quái boss riêng, không lẫn vào hồ).
const MONSTER_POOL_MIN_ID: int = 10
const MONSTER_POOL_MAX_ID: int = 22

const BASE_MONSTERS_PER_WAVE: int = 5
const MAX_MONSTERS_PER_WAVE: int = 15 ## chạm mốc này thì quay vòng về BASE
const MONSTERS_PER_WAVE_FLOOR_STEP: int = 2 ## +1 quái/đợt mỗi 2 tầng
const LEVEL_BONUS_PER_CYCLE: int = 5 ## mỗi lần quay vòng số-quái/đợt, +5 cấp quái vĩnh viễn

const BASE_MONSTER_LEVEL: int = 1
const MONSTER_LEVEL_FLOOR_STEP: int = 3 ## +1 cấp quái mỗi 3 tầng

const BASE_WAVE_COUNT: int = 5
const WAVE_COUNT_FLOOR_STEP: int = 4 ## +1 đợt mỗi 4 tầng

## monsters_per_wave "quay vòng" 5→15→5→15... - trả về (count, cycle_index).
static func _monster_count_cycle(floor_number: int) -> Dictionary:
	var steps: int = maxi(floor_number - 1, 0) / MONSTERS_PER_WAVE_FLOOR_STEP
	var range_size: int = MAX_MONSTERS_PER_WAVE - BASE_MONSTERS_PER_WAVE + 1 ## 11
	return {"count": BASE_MONSTERS_PER_WAVE + steps % range_size, "cycle": steps / range_size}

static func monsters_per_wave_for_floor(floor_number: int) -> int:
	return _monster_count_cycle(floor_number)["count"]

## Cấp quái = công thức thẳng theo tầng CỘNG bonus mỗi lần số-quái/đợt quay
## vòng (xem _monster_count_cycle) - hệ số nhân dùng ở TroopUnit._monster_stat_multiplier().
static func monster_level_for_floor(floor_number: int) -> int:
	var base_level: int = BASE_MONSTER_LEVEL + maxi(floor_number - 1, 0) / MONSTER_LEVEL_FLOOR_STEP
	var cycle_bonus: int = _monster_count_cycle(floor_number)["cycle"] * LEVEL_BONUS_PER_CYCLE
	return base_level + cycle_bonus

static func wave_count_for_floor(floor_number: int) -> int:
	return BASE_WAVE_COUNT + maxi(floor_number - 1, 0) / WAVE_COUNT_FLOOR_STEP

## Chọn CÓ LẶP (trùng loại được phép) đúng `count` id quái từ hồ.
static func pick_random_monster_ids(count: int) -> Array[int]:
	var ids: Array[int] = []
	for _i in range(count):
		ids.append(randi_range(MONSTER_POOL_MIN_ID, MONSTER_POOL_MAX_ID))
	return ids

## API chính - THUẦN DỮ LIỆU, trả {"monster_ids": Array[int], "monster_level": int}.
static func generate_encounter(monster_count: int, monster_level: int) -> Dictionary:
	return {"monster_ids": pick_random_monster_ids(monster_count), "monster_level": monster_level}

## Tiện ích cho Ải Thường - suy count+level từ floor_number thật.
static func generate_encounter_for_floor(floor_number: int) -> Dictionary:
	return generate_encounter(monsters_per_wave_for_floor(floor_number), monster_level_for_floor(floor_number))
