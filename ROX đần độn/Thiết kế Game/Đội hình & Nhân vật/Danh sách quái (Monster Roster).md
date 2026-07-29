# Danh sách quái (Monster Roster)

Thuộc [[Mục lục]]. Liên quan: [[Đội hình cố định (Party)]], [[Chỉ số lính]], [[Hoạt ảnh & Asset lính]]. Toàn bộ 13 nhân vật ở đây **mới tạo trong ROXdandon, không tồn tại trong `vrisingDanDon`** (bên đó chỉ có 9 nhân vật người, dùng tạm lẫn nhau làm "địch" - xem [[Chuyển thể từ vrisingDanDon]]).

## Nguồn asset
Cùng bộ **"Tiny RPG Character Asset Pack 01 v2.0 - Full 22 Characters"** đã dùng cho 9 nhân vật người (xem [[Hoạt ảnh & Asset lính]]) - bộ này có tổng **22 nhân vật**, 9 người đã dùng từ `vrisingDanDon`, **13 còn lại là quái/undead/thú** trước giờ chưa từng trích xuất. Đợt này trích nốt toàn bộ 13 con còn lại.

## 13 quái (id 10-22)
| id | Tên | `character_key` | troop_type | damage_type | HP | ATK | Tầm đánh | Ghi chú animation |
|---|---|---|---|---|---|---|---|---|
| 18 | Slime | `slime` | NORMAL | PHYSICAL | 60 | 6 | 1.0 | idle/walk/attack01/02/death/hurt - đủ bộ chuẩn |
| 19 | Bat | `bat` | NORMAL | PHYSICAL | 70 | 8 | 1.0 | **không có Idle/Walk riêng** - dùng chung `Bat_Flying.png` cho cả idle lẫn walk (bay liên tục) |
| 14 | Skeleton | `skeleton` | NORMAL | PHYSICAL | 100 | 10 | 1.0 | bỏ qua `Block`/`Summon` (ngoài vocabulary animation hiện có) |
| 17 | Skeleton Archer | `skeleton_archer` | **ARCHER** | PHYSICAL | 90 | 10 | 8.0 | chỉ 1 file `_Attack.png` (không phải `_Attack01`) → map thành `attack01` |
| 10 | Orc | `orc` | NORMAL | PHYSICAL | 150 | 14 | 1.0 | |
| 21 | Werewolf | `werewolf` | NORMAL | PHYSICAL | 140 | 15 | 1.0 | |
| 15 | Armored Skeleton | `armored_skeleton` | NORMAL | PHYSICAL | 180 | 12 | 1.0 | bỏ qua `Summon` |
| 22 | Necromancer | `necromancer` | **ARCHER** | **MAGIC** | 120 | 16 | 8.0 | bỏ qua biến thể `(With magic effects)`/`_Effect`/`Summon` - chỉ lấy animation gốc |
| 20 | Werebear | `werebear` | NORMAL | PHYSICAL | 250 | 18 | 1.0 | |
| 11 | Armored Orc | `armored_orc` | NORMAL | PHYSICAL | 300 | 16 | 1.0 | bỏ qua `Block` |
| 16 | Greatsword Skeleton | `greatsword_skeleton` | NORMAL | PHYSICAL | 280 | 20 | 1.0 | bỏ qua `Summon` |
| 12 | Elite Orc | `elite_orc` | NORMAL | PHYSICAL | 400 | 22 | 1.0 | |
| 13 | Orc Rider | `orc_rider` | NORMAL | PHYSICAL | 500 | 24 | 1.0 | bỏ qua `Block` |

Số liệu HP/ATK là **placeholder tự chia tier theo cảm quan** (Slime yếu nhất → Orc Rider mạnh nhất) - chưa phải cân bằng thật, xem [[Tiến độ & Việc còn dang dở]]. Các chỉ số còn lại (DEF/M.DEF/ATK Speed/Crit/Armor Penetration/Life Steal/Regen HP) dùng chung mặt bằng với 9 nhân vật người (DEF/M.DEF dao động 2-14 theo tier, còn lại giữ nguyên `atk_speed=10.0, crit_rate=0.3, crit_damage=1.5, armor_penetration=10.0, life_steal=0.01, regen_hp=10.0`).

## Đang dùng ở đâu
- Party (4 người cố định): id 1, 3, 4, 9 - xem [[Đội hình cố định (Party)]].
- Ải 1 (`data/stages/stage_1.tres`): `enemy_troop_ids=[18, 14]` (Slime, Skeleton), `enemy_troop_counts=[2, 2]` → 4 quái yếu nhất trong roster, hợp làm màn khởi động.
- 9 nhân vật người còn lại (Swordsman id2, Knight id5, Knight Templar id6, Lancer id7, Armored Axeman id8) và 11 quái còn lại **có sẵn trong catalog nhưng chưa được ải nào dùng tới** - sẵn sàng cho việc thiết kế ải 2 trở lên.

## Kiến trúc code
Giống hệt 9 nhân vật người: `data/troops/<key>.tres` (Resource `LinhData`) + `assets/troops/<key>/<Pascal>Sheet.png`+`Frames.tres`+`Icon.tres`. Đã nối `character_key` mới vào `TroopUnit.CHARACTER_FRAMES`/`CHARACTER_ATTACK_ANIMS` (2 `Dictionary` tra theo `character_key`, xem [[Hoạt ảnh & Asset lính]]) - **thiếu bước này thì quái sẽ tự fallback hiện hình Soldier** (`DEFAULT_CHARACTER_KEY`).
