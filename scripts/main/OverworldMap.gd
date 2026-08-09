class_name OverworldMap
extends Control

## Màn "Thành phố" (`city`) - vỏ ngoài của map thuần cảnh. Tương tác DUY NHẤT
## là bấm 1 trong 5 NPC cố định (xem OverworldWorld.gd bắt tap, phát
## npc_tapped(npc_id) với npc_id = đúng tên node NPC trong Npcs) để mở panel
## tương ứng - mỗi panel là 1 Control full-rect riêng, ẩn/hiện bằng open()/
## đóng qua nút back của chính panel đó (xem SimplePlaceholderPanel.gd/
## WarehousePanel.gd/UpgraderPanel.gd).

@onready var _world: OverworldWorld = $SubViewportContainer/SubViewport/OverworldWorld
@onready var _blacksmith_panel: SimplePlaceholderPanel = $BlacksmithPanel
@onready var _alchemist_panel: SimplePlaceholderPanel = $AlchemistPanel
@onready var _refiner_panel: SimplePlaceholderPanel = $RefinerPanel
@onready var _warehouse_panel: WarehousePanel = $WarehousePanel
@onready var _upgrader_panel: UpgraderPanel = $UpgraderPanel

func _ready() -> void:
	_world.npc_tapped.connect(_on_npc_tapped)
	_blacksmith_panel.setup("Thợ Rèn", "Cường hóa trang bị - đang xây dựng, chưa có gì để bấm ở đây.")
	_alchemist_panel.setup("Thợ Giả Kim", "Yểm bùa trang bị - đang xây dựng, chưa có gì để bấm ở đây.")
	_refiner_panel.setup("Thợ Tinh Luyện", "Tinh luyện trang bị - đang xây dựng, chưa có gì để bấm ở đây.")

func _on_npc_tapped(npc_id: String) -> void:
	match npc_id:
		"ThoRenNpc":
			_blacksmith_panel.open()
		"ThoGiaKimNpc":
			_alchemist_panel.open()
		"ThoTinhLuyenNpc":
			_refiner_panel.open()
		"QuanLyKhoNpc":
			_warehouse_panel.open()
		"ThoNangCapNpc":
			_upgrader_panel.open()
