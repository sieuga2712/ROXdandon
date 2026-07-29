# Chuyển thể từ vrisingDanDon

Thuộc [[Mục lục]]. Ghi lại quyết định pivot thể loại và chính xác những gì mang qua/bỏ - tránh phải hỏi lại "tại sao không có X" khi X từng tồn tại bên `vrisingDanDon`.

## Lý do pivot
`vrisingDanDon` ("Village Builder Demo") là game xây dựng thành phố + kinh tế + nuôi quân + vượt ải theo mô hình mass-army auto-battler (dồn quân số lượng lớn, bàn cờ hex 10x6). Người chơi quyết định đổi hẳn thể loại: bỏ xây dựng thành phố, bỏ PvP, giữ lại đúng phần **PvE auto-battle**, đổi sang **đội hình cố định 4 người** kiểu Ragnarok X. Vì đây là đổi thể loại (không phải sửa tính năng), quyết định tạo **repo Godot mới hoàn toàn** (`ROXdandon`) thay vì sửa trong `vrisingDanDon`, mang qua những phần dùng lại được.

## Bảng mang qua / bỏ (tổng hợp, xem từng ghi chú liên quan để biết chi tiết)

| Nhóm | Mang qua | Bỏ hẳn |
|---|---|---|
| Nhân vật/quái | `LinhData.gd` (trừ `recruit_costs`), `TroopUnit.gd`/`.tscn` (trừ `stack_count`), `TroopDatabase.gd`, toàn bộ art 9 người + trích thêm 13 quái mới | `recruit_costs`, cơ chế dồn lính (`stack_count`/`stack_max`) |
| Chiến đấu | Toàn bộ công thức sát thương/skill/heal/projectile/popup trong `BattleScene.gd` (~gần như nguyên văn) | Bàn cờ hex, pha xếp quân/kéo-thả, Squad AI (đội = trại lính), camera zoom/pan tay, `BattleSquadBorders` debug |
| Ải | `StageData.gd` (trừ `enemy_cols`/`enemy_rows`), `StageDatabase.gd`, `StageSelectPanel.gd`/`.tscn` (gần như nguyên văn) | Toạ độ bàn cờ trong `StageData` |
| Kinh tế | Không gì cả | `ResourceManager`, `PopulationManager`, `ProductionManager`, `BuildingRegistry`, `ResourceAmount.gd`, toàn bộ `Enums.ResourceType`/`ProductionType` |
| Xây dựng | Không gì cả | `GridManager`, `BuildingManager`, `BuildingPreview`, `BuildingData`, `PlacedBuilding`, `BuildingLeveling`, `BuildingSelectionManager`, `BuildingDatabase`, toàn bộ UI xây dựng |
| Giao diện | `UIBuilders.texture_icon()`/`small_label()`, `UIConstants.TROOP_ICON_SIZE`/`SHOW_DEBUG_TAGS` (quy ước, chưa dùng) | `UIBuilders.resource_icon()`/`resource_cost_row()`, mọi UI thành phố, `NotificationManager`/`NotificationPanel` |
| Scene gốc | Ý tưởng "overlay đặt sẵn trong scene gốc" (từ `Main.tscn` → `Hub.tscn`) | `Main.tscn`/`Main.gd`, `CameraController`, `TileMap`/`GridOverlay` |

## Thay đổi mô hình cốt lõi
1. **Mass-army → đội hình nhỏ cố định**: không còn "1 icon đại diện N lính giống hệt nhau" - mỗi `TroopUnit` giờ luôn = đúng 1 nhân vật/quái. Kéo theo bỏ hẳn `_distribute_stack_counts()`, `effective_atk()`/`max_hp()` không còn nhân theo số lượng dồn.
2. **Xếp quân trước trận → không còn gì để xếp**: đội hình cố định (xem [[Đội hình cố định (Party)]]) nên bỏ hẳn pha "chuẩn bị quân" (bàn cờ hex, kéo-thả, khay lính, Auto xếp quân) - vào ải là vào thẳng trận.
3. **Squad theo trại → gom theo mục tiêu động mỗi frame**: không còn "trại lính = 1 đội" (không có trại lính nữa) - xem [[AI chiến đấu]].
4. **Multi-resource → 1 counter vàng**: xem [[Vàng (GameState)]].
5. **Camera điều khiển tay → camera tĩnh**: sân đấu nhỏ cố định, không cần zoom/pan - xem [[Camera & Hiệu ứng trận đấu]].

## Quy trình chuyển đổi thực tế (để tham khảo nếu cần fork tiếp lần sau)
1. Đọc trực tiếp từng file gốc cần port (không suy đoán từ tên file) - xác nhận đúng function signature/hằng số trước khi port.
2. Phân loại từng file: COPY-AS-IS / COPY-AND-EDIT (ghi rõ cắt gì) / NEW / DROP - làm thành plan trước khi động tay.
3. Port theo thứ tự phụ thuộc: schema data trước (`Enums`/`LinhData`/`StageData`) → autoload database → asset → node hiển thị (`TroopUnit`) → UI đơn giản (`StageSelectPanel`) → phần lớn nhất (`BattleScene`) → autoload state mới (`GameState`) → scene gốc (`Hub`) → nối dây.
4. Kiểm tra headless sau mỗi bước lớn: `--headless --import` rồi `--headless --quit-after 60`, xác nhận không có dòng `ERROR`/`SCRIPT ERROR`.
5. Asset mới (monster roster) trích XUẤT SAU, khi đã có khung sườn chạy được - không chặn việc có 1 bản chơi được sớm.

## Vault tài liệu cũ
`vrisingDanDon` có vault Obsidian riêng (`vrising đần độn/` trong thư mục project đó) - cấu trúc `ROX đần độn/` này CỐ TÌNH mirror cách tổ chức đó (cùng tên nhóm, cùng phong cách wikilink `[[...]]`) để dễ đối chiếu, dù nội dung đã viết lại gần như hoàn toàn cho đúng ROXdandon.
