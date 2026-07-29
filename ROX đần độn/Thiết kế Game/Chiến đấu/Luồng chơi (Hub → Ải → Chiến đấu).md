# Luồng chơi (Hub → Ải → Chiến đấu)

Thuộc [[Mục lục]]. Liên quan: [[AI chiến đấu]], [[Công thức sát thương]], [[Đội hình cố định (Party)]], [[Camera & Hiệu ứng trận đấu]]. Bản rút gọn RẤT NHIỀU so với "Luồng Vượt ải" của `vrisingDanDon` - xem [[Chuyển thể từ vrisingDanDon]] về những gì bị bỏ.

## 3 màn hình (so với 4 màn của `vrisingDanDon` - đã bỏ hẳn "màn chuẩn bị quân")
1. **Hub** (`scenes/main/Hub.tscn`, `run/main_scene`) - hiện đội hình 4 người + vàng hiện có + nút "Chọn ải". Thay hẳn "màn thành phố" cũ, không còn xây dựng/kinh tế gì.
2. **Màn chọn ải** (`StageSelectPanel`) - y hệt `vrisingDanDon`, liệt kê động từ `StageDatabase.get_all()` (auto-scan `data/stages/*.tres`).
3. **Màn chiến đấu** (`BattleScene`) - **vào thẳng trận ngay khi chọn ải, không còn pha xếp quân** (đội hình cố định, không có gì để chọn trước mỗi trận - xem [[Đội hình cố định (Party)]]). `start_battle(stage)` spawn cả 2 phe cùng lúc rồi chạy AI luôn.

## Ải 1 (ải duy nhất hiện có)
- Quân địch cố định: **2 Slime (id 18) + 2 Skeleton (id 14)** - xem [[Danh sách quái (Monster Roster)]].
- **Điều kiện thắng**: giết hết quân địch trong **2 phút** (`time_limit`).
- **Điều kiện thua**: hết giờ mà chưa giết hết địch, HOẶC quân mình chết hết trước, HOẶC người chơi tự bấm nút **"Chịu thua"**.
- **Phần thưởng khi thắng**: **+50 vàng** (`reward_gold`) - xem [[Vàng (GameState)]].
- **Đội hình luôn hồi đầy máu mỗi trận mới** - không có khái niệm "lính chết mất luôn"/"lính sống sót trả về" như `vrisingDanDon` (không còn barracks để trả về) - đơn giản hoá triệt để vì đội hình cố định, không có gì để mất.
- Chưa có ải 2 trở đi - `StageDatabase` đã auto-scan sẵn, thêm ải mới chỉ cần thêm `.tres` mới trong `data/stages/`.

## Đội hình spawn (thay hẳn bàn cờ hex 10x6 của `vrisingDanDon`)
- Không còn bàn ô/kéo-thả gì cả - `BattleScene._spawn_team()` xếp mỗi phe theo **đội hình hình nêm cố định** (`FORMATION_OFFSETS`, hand-copy từ `BattleHexCell.FORMATION_OFFSETS` cũ) quanh 1 tâm đội hình riêng mỗi phe (`PLAYER_TEAM_CENTER = (-180, 0)`, `ENEMY_TEAM_CENTER = (180, 0)`), mirror theo trục X cho phe địch.
- Đội hình địch **không còn xếp theo lưới ô như trước** - nếu 1 ải có > 6 quái tổng cộng thì các vị trí thừa quay vòng lại (`index % 6`) - đủ dùng cho Ải 1 (4 quái).

## Kiến trúc code
`scripts/stage/StageData.gd` (Resource: tên, thời gian giới hạn, vàng thưởng, `enemy_troop_ids`/`enemy_troop_counts` - **đã bỏ `enemy_cols`/`enemy_rows`** vì không còn bàn cờ) + `StageDatabase` (autoload) + `scripts/main/StageFlowController.gd` (nối `StageSelectPanel`↔`BattleScene`, đặt trong `Hub.tscn` thay vì `Main.tscn`/`UIManager` cũ) + `BattleScene.gd`/`.tscn`.

## Khác biệt kiến trúc lớn nhất so với `vrisingDanDon`
`vrisingDanDon` **không đổi scene** khi vượt ải (giữ nguyên `BuildingManager`/`ProductionManager` sống trong `Main.tscn`). ROXdandon **không có lý do đó nữa** (không còn building/economy nào cần giữ trạng thái) nhưng vẫn giữ NGUYÊN kiến trúc "overlay đặt sẵn trong scene gốc" (Hub.tscn chứa sẵn `StageSelectPanel`+`BattleScene` làm con, ẩn/hiện qua `visible`) - vì `%TênDuyNhất` cần cả 2 node cùng thuộc 1 owner scene đã load sẵn, và không có lý do gì để đổi cách này khi nó đã chạy đúng.
