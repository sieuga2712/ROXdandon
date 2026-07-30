class_name OverworldWorld
extends Node2D

## Map nhỏ thay Hub tĩnh cũ - 4 thành viên party đi lại được, mỗi người có 1
## trong 3 trạng thái (lấy cảm hứng Ragnarok X): ĐANG ĐIỀU KHIỂN (đúng 1 người,
## `leader` - đi theo lệnh chuột phải trên map), ĐANG THEO (`following[unit] =
## true` - tự bám theo leader mỗi frame), hoặc ĐỘC LẬP (đứng yên tại chỗ).
## PartyRosterPanel gọi select_leader()/toggle_follow()/recall_all() (nối
## trong OverworldMap.gd) - OverworldWorld là nguồn sự thật duy nhất, luôn
## emit state_changed sau khi đổi để panel refresh() lại đúng theo state thật
## (đổi leader làm leader cũ tự bật "đang theo" - panel không tự đoán được).
## NPC/nhà/placeholder trong scene chỉ là trang trí - không đưa vào
## party_units nên không thể điều khiển/theo/chọn được.
## Không có combat/AI ở đây - xem BattleScene.gd cho phần chiến đấu (tách biệt
## hoàn toàn, OverworldWorld không đụng tới).

signal state_changed

const TROOP_UNIT_SCENE: PackedScene = preload("res://scenes/troop/TroopUnit.tscn")

## Clamp di chuyển - nhỏ hơn GroundBackground (960x520, xem OverworldMap.tscn)
## 1 chút để unit không đi ra sát mép/lấn nhà.
const MAP_BOUNDS: Rect2 = Rect2(-460.0, -240.0, 920.0, 480.0)
const SPAWN_CENTER: Vector2 = Vector2(0.0, 150.0)
const SPAWN_SPREAD_RADIUS: float = 40.0
const ARRIVE_EPSILON_PX: float = 4.0

## Offset tĩnh (không xoay theo hướng leader - đơn giản hoá cho v1) cho từng
## người theo sau, gán theo thứ tự trong party_units (bỏ qua leader) - lấy
## vòng qua % nếu party đổi số lượng, giống BattleScene.FORMATION_OFFSETS.
const FOLLOW_OFFSETS: Array[Vector2] = [
	Vector2(-40.0, -25.0), Vector2(-40.0, 25.0), Vector2(-65.0, 0.0),
]

@onready var party: Node2D = $Party

## OverworldMap.set_interactive() tắt khi StageSelectPanel/BattleScene đang mở
## (Hub._process gọi) - tránh click xuyên qua panel/trận đấu xuống map.
var interactive: bool = true
var party_units: Array[TroopUnit] = []
var leader: TroopUnit = null
var following: Dictionary = {} ## TroopUnit -> bool, mặc định false (độc lập) nếu chưa có key
var _leader_target: Vector2 = Vector2.ZERO
var _has_leader_target: bool = false

func _ready() -> void:
	_spawn_party()

## Giống BattleScene._spawn_team nhưng không có team địch/đội hình hình nêm -
## chỉ chia đều 4 người quanh 1 điểm xuất phát. Ẩn 3 thanh trạng thái chiến đấu
## (hp/attack/skill) vì map này không có combat.
func _spawn_party() -> void:
	var ids := GameState.PARTY_TROOP_IDS
	for i in range(ids.size()):
		var troop := TroopDatabase.get_by_id(ids[i])
		if troop == null:
			continue
		var unit: TroopUnit = TROOP_UNIT_SCENE.instantiate()
		party.add_child(unit)
		unit.setup(troop, Enums.Team.PLAYER)
		unit.hp_bar_bg.visible = false
		unit.attack_bar_bg.visible = false
		unit.skill_bar_bg.visible = false
		var offset := Vector2.ZERO
		if ids.size() > 1:
			offset = Vector2.RIGHT.rotated(TAU * i / ids.size()) * SPAWN_SPREAD_RADIUS
		unit.position = SPAWN_CENTER + offset
		party_units.append(unit)
	select_leader(0) ## mặc định leader = thành viên đầu tiên, khớp icon điều khiển đầu tiên bị disable sẵn trên PartyRosterPanel

## PartyRosterPanel.control_requested gọi hàm này (nối trong OverworldMap.gd).
## Leader CŨ tự động chuyển sang "đang theo" leader mới - không bị bỏ rơi đứng
## yên đột ngột. Huỷ lệnh di chuyển dở của leader mới, chờ lệnh mới.
func select_leader(index: int) -> void:
	if index < 0 or index >= party_units.size() or party_units[index] == leader:
		return
	var old_leader := leader
	leader = party_units[index]
	_has_leader_target = false
	if old_leader != null:
		following[old_leader] = true
	following.erase(leader) ## người đang điều khiển không có khái niệm "đang theo"
	for unit in party_units:
		unit.set_selected(unit == leader)
	state_changed.emit()

## PartyRosterPanel.follow_toggled gọi hàm này - bấm thân thẻ 1 người KHÔNG
## PHẢI leader để bật/tắt "đang theo", không đụng gì tới ai đang điều khiển.
func toggle_follow(index: int) -> void:
	if index < 0 or index >= party_units.size():
		return
	var unit := party_units[index]
	if unit == leader:
		return
	following[unit] = not following.get(unit, false)
	state_changed.emit()

## PartyRosterPanel "Gọi tất cả" - dịch chuyển TỨC THỜI (không đi bộ) mọi
## người về quanh leader và bật "đang theo" cho tất cả, kể cả người đang độc
## lập ở xa.
func recall_all() -> void:
	if leader == null:
		return
	var follower_index := 0
	for unit in party_units:
		if unit == leader:
			follower_index += 1
			continue
		var target := _clamp_to_bounds(leader.position + FOLLOW_OFFSETS[follower_index % FOLLOW_OFFSETS.size()])
		follower_index += 1
		unit.position = target
		unit.play_idle()
		following[unit] = true
	state_changed.emit()

func _process(delta: float) -> void:
	if leader == null:
		return
	if _has_leader_target:
		_move_toward(leader, _leader_target, delta)
		if leader.position.distance_to(_leader_target) <= ARRIVE_EPSILON_PX:
			_has_leader_target = false
	else:
		leader.play_idle()

	var follower_index := 0
	for unit in party_units:
		if unit == leader:
			continue
		if following.get(unit, false):
			var target := _clamp_to_bounds(leader.position + FOLLOW_OFFSETS[follower_index % FOLLOW_OFFSETS.size()])
			_move_toward(unit, target, delta)
		else:
			unit.play_idle() ## độc lập - đứng yên tại chỗ, không đụng position
		follower_index += 1

## Rút gọn từ nhánh di chuyển của BattleScene._update_unit (seek + arrival
## check) - không có tấn công/tầm đánh/AI gì cả, chỉ đi tới điểm rồi dừng.
## Dùng chung cho cả leader (điểm đích cố định 1 lần) lẫn follower (điểm đích
## tính lại mỗi frame theo vị trí leader hiện tại).
func _move_toward(unit: TroopUnit, target: Vector2, delta: float) -> void:
	if unit.position.distance_to(target) <= ARRIVE_EPSILON_PX:
		unit.play_idle()
		return
	unit.face_towards(target)
	unit.play_walk()
	unit.position = _clamp_to_bounds(unit.position + (target - unit.position).normalized() * unit.move_speed_px() * delta)

func _clamp_to_bounds(pos: Vector2) -> Vector2:
	return Vector2(
		clampf(pos.x, MAP_BOUNDS.position.x, MAP_BOUNDS.position.x + MAP_BOUNDS.size.x),
		clampf(pos.y, MAP_BOUNDS.position.y, MAP_BOUNDS.position.y + MAP_BOUNDS.size.y)
	)

## Click phải vào map = ra lệnh leader đi tới đó. Dùng event.position tự tính
## ra world-space qua canvas_transform của viewport, KHÔNG dùng
## get_global_mouse_position() - hàm đó đọc vị trí chuột "đã lưu" của
## viewport, giá trị này không đáng tin nếu chưa có sự kiện chuyển động chuột
## nào trước đó cập nhật nó (xảy ra thật với tap trên touch, project này nhắm
## handheld/landscape - xem project.godot).
func _unhandled_input(event: InputEvent) -> void:
	if not interactive or leader == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var world_point: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		_leader_target = _clamp_to_bounds(world_point)
		_has_leader_target = true
