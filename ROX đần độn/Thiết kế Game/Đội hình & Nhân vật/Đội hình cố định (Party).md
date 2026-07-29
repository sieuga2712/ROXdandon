# Đội hình cố định (Party)

Thuộc [[Mục lục]]. Liên quan: [[Chỉ số lính]], [[Danh sách quái (Monster Roster)]], [[Vàng (GameState)]].

## 4 thành viên hiện tại
`GameState.PARTY_TROOP_IDS: Array[int] = [1, 3, 4, 9]` - tra qua `TroopDatabase.get_by_id()`:

| id | Tên | Vai trò | HP | troop_type | Ghi chú |
|---|---|---|---|---|---|
| 1 | Soldier | Tank | 1000 | NORMAL (cận chiến) | HP cao gấp 10 lần 3 người còn lại |
| 3 | Archer | DPS vật lý tầm xa | 100 | ARCHER (đánh xa) | `attack_range=8.0` → đứng hậu phương |
| 4 | Wizard | DPS phép tầm xa | 100 | ARCHER (đánh xa) | dùng Projectile riêng (luồng phép) |
| 9 | Priest | Hồi máu | 100 | ARCHER (đánh xa) | **nhân vật DUY NHẤT biết hồi máu** - `character_key == "priest"` hard-code trong `BattleScene._priest_cast()` |

## Vì sao chọn 4 người này (không phải ngẫu nhiên)
- Soldier là lính duy nhất tách biệt hẳn về HP (tank rõ ràng, không lẫn với 3 người kia).
- Archer/Wizard/Priest đều có `troop_type = ARCHER` → hệ số tầm đánh xa hơn hẳn cận chiến (xem [[Chỉ số lính]]) - tự nhiên đứng hậu phương không cần AI riêng cho "đứng sau".
- Priest là bắt buộc nếu muốn có sustain trong đội - không có nhân vật nào khác thay thế được vai trò hồi máu.
→ Kết quả: 1 tank + 2 DPS tầm xa (1 vật lý/1 phép) + 1 healer, đúng công thức đội hình RPG kinh điển, tận dụng đúng cơ chế sẵn có thay vì phải code thêm.

## Mở rộng sau này
- Roster hiện có sẵn 22 nhân vật (9 người + 13 quái, xem [[Danh sách quái (Monster Roster)]]) - đổi đội hình chỉ cần sửa `PARTY_TROOP_IDS`, không cần code thêm gì (do `character_key`/`LinhData` đã tách rời "loại nhân vật" khỏi "vai trò phe" từ thời `vrisingDanDon`).
- Chưa có UI chọn đội hình - hiện là **hard-code trong `GameState.gd`**, không phải lựa chọn của người chơi. Khi cần mở rộng > 4 người thật (roster + chọn đội mỗi trận kiểu Ragnarok X thật), đây là chỗ cần thiết kế lại (đã bàn tới lúc lên kế hoạch dự án, chọn hard-code 4 người trước cho đơn giản - xem [[Tóm tắt dự án]]).

## Kiến trúc code
`scripts/state/GameState.gd` (autoload) - `PARTY_TROOP_IDS` (const) + `gold`/`add_gold()`. `BattleScene.start_battle()` spawn party từ danh sách này mỗi trận (party luôn hồi đầy máu, không có state tồn tại giữa các trận - xem [[Luồng chơi (Hub → Ải → Chiến đấu)]]).
