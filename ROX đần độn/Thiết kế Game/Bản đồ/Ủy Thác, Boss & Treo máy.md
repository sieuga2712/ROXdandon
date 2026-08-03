# Ủy Thác, Boss & Treo máy

Thuộc [[Mục lục]]. **THAY THẾ hoàn toàn** phần "Tab Ải AFK-farm" cũ trong [[Thành phố & Ải AFK-Farm]] (đã đánh dấu SUPERSEDED trong note đó, xem note đó cho lịch sử tại sao đổi). Cập nhật lớn **2026-08-03**: đổi hẳn tab "Ải" từ map AFK-farm điều khiển được sang bảng kiểu "Ủy Thác" (không map, không điều khiển) + xây thật tab "Ải Boss" + xây thật hệ "Treo máy" (idle) + hệ EXP/Cấp độ đầu tiên của game.

## Vì sao đổi (tóm tắt quyết định thiết kế)
- Người dùng muốn mô hình giống AFK Arena: 4 map, mỗi map nhiều tầng tăng dần, xem bằng bảng thẻ chứ không phải đi lại trên map.
- Sau đó quyết định: **Ủy Thác (đánh tay) và Treo máy là 2 hệ HOÀN TOÀN TÁCH BIỆT** - nhân vật đang treo máy vẫn đánh Ủy Thác/Boss bình thường, không bị "bận". Ràng buộc DUY NHẤT: 1 nhân vật không thuộc 2 team treo máy cùng lúc.
- Vai trò của Ủy Thác/Boss thu hẹp lại: **chỉ để mở khoá tầng cao hơn cho Treo máy** (`GameState.highest_floor_cleared`), không còn là nguồn thưởng chính - nguồn thưởng chính giờ là Treo máy (tính theo thời gian trôi qua) + EXP giết quái.
- Giết quái (đánh tay HAY treo máy) → cả team liên quan nhận EXP → có Base Lv/Job Lv thật, ảnh hưởng chỉ số chiến đấu thật.

## Tab "Ải" (`stage`) = `StageBoardScreen.tscn`/`.gd` - bảng thẻ, KHÔNG có map
2 sub-tab (nút bấm thường, không phải `TabContainer`):

### Sub-tab "Ủy Thác"
- Data: `MapData`/`MapDatabase` (4 map, `data/maps/*.tres`) × `StageData`/`StageDatabase` (mỗi tầng 1 file, có `map_id`/`floor_number`, `data/stages/*.tres`).
- Mỗi map 1 thẻ (icon/tên/loại khu vực/điều kiện thắng/độ khó/tầng hiện tại) + nút "VÀO TRẬN" - bấm là **vào thẳng tầng tiếp theo** (`highest_floor_cleared[map_id] + 1`) qua `BattleScene` thật, KHÔNG có bước chọn tầng riêng.
- Thắng → `StageFlowController.stage_finished` → `GameState.report_floor_cleared()` → mở khoá tầng kế cho CẢ Ủy Thác lẫn giới hạn tầng của Treo máy.

### Sub-tab "Treo máy" - hệ treo máy THẬT (không còn placeholder)
- `GameState.idle_teams: Array[Dictionary]` - mỗi team: `id`, `stage_id`, `member_troop_ids` (1-4 người, không cần đủ 4), `last_tick_at` (unix time thật).
- **Không giới hạn thời gian** - `GameState.settle_idle_team(team)` mỗi lần gọi tính `cycles = floor((now - last_tick_at) / stage.time_limit)`, cộng `cycles * reward_gold` vào vàng + `cycles * tổng_exp_reward_quái` vào EXP của các thành viên, dời `last_tick_at` lên đúng số chu kỳ đó (phần dư giữ lại). Gọi lúc mở tab + mỗi 4s qua `%IdleSettleTimer` khi đang xem.
- Ràng buộc: tối đa `GameState.IDLE_MAX_TEAMS_PER_MAP` (= 3) team/map, 1 nhân vật không thuộc 2 team treo máy cùng lúc (`GameState.is_troop_idling()`).
- Tầng tối đa được chọn khi tạo team = `GameState.get_highest_floor(map_id)` (tầng 1 luôn mở sẵn dù chưa thắng gì) - **đây là lý do Ủy Thác vẫn cần tồn tại**.
- Màn "Tạo đội treo" (nội bộ trong `StageBoardScreen`, không phải scene riêng): chọn map (`OptionButton`) → chọn tầng (stepper -/+) → chọn 1-4 thành viên (ẩn/khoá người đang bận team khác) → "BẮT ĐẦU TREO".
- **⚠️ CHƯA có save/load** - "treo máy tính cả lúc tắt app" mới đúng về CÔNG THỨC (dùng `Time.get_unix_time_from_system()`, giờ hệ thống thật), nhưng `GameState` reset hoàn toàn mỗi lần mở lại game (xem đầu `GameState.gd`) nên tắt app hẳn hiện tại VẪN mất tiến độ. Muốn thật sự "tắt app vẫn cộng dồn" phải làm thêm 1 tính năng persistence riêng (lưu `idle_teams`/`base_exp_total`/`job_exp_total`/`gold` ra file + đọc lại lúc khởi động).

### Màn "Xem treo máy" - tái dùng `StageFarmMap.tscn`/`StageFarmWorld.gd`
- File này TỪNG LÀ toàn bộ nội dung tab Ải (map AFK-farm điều khiển được, xem [[Thành phố & Ải AFK-Farm]] cho lịch sử) - giờ viết lại thành **màn xem thuần cảnh, không điều khiển được**: bỏ hết `PartyRosterPanel`/leader/click-di-chuyển (file `PartyRosterPanel.gd` đã XOÁ - hết chỗ dùng).
- `configure(stage, member_troop_ids)` spawn ĐÚNG các thành viên đang treo team đó (không phải luôn đủ 4) bên trái, quái của đúng `StageData` đang treo bên phải, 2 bên tự đánh nhau bằng công thức sát thương giống `BattleScene` (đã sửa dùng `effective_def()`/`effective_m_def()` cho đúng chỉ số đã lên cấp). Hết 1 phe → chờ 2s → `TroopUnit.revive()` cả 2 phe → đánh lại - loop vô hạn, không có thắng/thua.
- **KHÔNG cộng vàng/EXP gì ở đây** - đây thuần là hình ảnh minh hoạ, phần thưởng thật đã tính riêng qua `settle_idle_team()` bất kể có đang xem hay không. Có ghi chú ngay trên UI để khỏi hiểu lầm 2 nguồn thưởng cộng dồn.
- Mở từ nút "XEM" trên mỗi thẻ team treo máy (bên cạnh "RÚT VỀ") → `StageBoardScreen._open_idle_view()` tự instance `StageFarmMap.tscn`, gọi `configure()`, nhúng vào `%IdleViewHost`; đóng lại (nút "←") thì `queue_free()` để dừng simulation.

## Tab "Ải Boss" (`boss`) = `BossBoardScreen.tscn`/`.gd` - xây THẬT, không còn placeholder
- Data mới: `BossData`/`BossDatabase` (`data/bosses/*.tres`) - mỗi boss trỏ tới 1-4 `StageData` có sẵn (KHÔNG có bộ số liệu riêng, HP/ATK/DEF hiện trên thẻ lấy thẳng từ `LinhData` của quái trong `StageData` đó, tránh 2 nơi giữ cùng dữ liệu).
- **Boss Ngày** (`is_world_boss=false`): mỗi boss 1 thẻ, chọn độ khó Dễ/Thường/Khó ngay trong thẻ (`stage_id_easy/normal/hard` - 3 `StageData`/`LinhData` riêng, quái càng khó HP/ATK/DEF càng cao thật, không phải số ảo) - đổi độ khó = đổi hẳn `StageData` sẽ gửi cho `BattleScene`. 2 boss hiện có: Hắc Long (`elite_orc` reskin), Ma Tướng (`armored_orc` reskin).
- **Boss Khủng** (`is_world_boss=true`): 1 thẻ, không có độ khó, dùng `stage_id_world` duy nhất. 1 boss hiện có: Ma Vương Abyss (`greatsword_skeleton` reskin, HP 6000 - mạnh nhất game). Có dòng "Thời gian xuất hiện" nhưng **CHƯA nối lịch hẹn giờ thật** - nút luôn bấm được.
- "THÁCH ĐẤU" dùng CHUNG `StageFlowController` với Ủy Thác (đã có sẵn comment trong `StageFlowController.gd` dự tính đúng việc này từ trước) - `MainShell.gd` nối cả `stage_screen` và `boss_screen` vào cùng 1 `stage_flow`, `stage_finished` phát ra cho CẢ 2 màn tự rebuild (màn không liên quan tự no-op, vô hại).

## Tab "Nhân vật" (`character`) = `CharacterBoardScreen.tscn`/`.gd` - xây THẬT
- Chỉ liệt kê đúng 4 thành viên party thật (`GameState.PARTY_TROOP_IDS`) - KHÔNG phải bộ sưu tập gacha (game này không có gacha/chiêu mộ). Vai trò TANK/DPS/SUPPORT trên thẻ chỉ là nhãn suy ra từ `character_key`/`troop_type`, không phải field dữ liệu thật.
- Portrait dùng đúng `LinhData.sprite` (icon thật), không phải emoji.
- Màn chi tiết: 8 ô trang bị + 3 ô phụ **THUẦN TƯỢNG TRƯNG** (chưa có hệ trang bị/item thật đứng sau, không bấm được gì) + khối EXP/Cấp độ THẬT + bảng đầy đủ chỉ số HIỆU DỤNG (đã cộng bonus theo cấp, không phải số gốc trong `LinhData`).

## Hệ EXP/Cấp độ (mới, dùng CHUNG cho cả đánh tay và treo máy)
- `scripts/state/ExpTables.gd` - 2 bảng const `BASE_REQUIRED` (129 cấp) + `JOB_REQUIRED` (49 cấp, chỉ "First Job" - CHƯA có cơ chế chuyển job) lấy ĐÚNG số trong `ROX_EXP_Goc_Base_Job_DayDu.xlsx` (chia 1/10, quy ước đã dùng từ lúc làm mockup HTML - xem `mockups/giao-dien-hien-tai.html`). `ExpTables.level_from_total_exp(total_exp, table)` suy ra cấp + tiến độ EXP từ tổng EXP đã tích (không lưu cấp riêng, luôn tính lại từ tổng - đơn giản, không lệch).
- `LinhData` thêm field `exp_reward: int` - hạ 1 quái/boss loại này thì CẢ TEAM (đánh tay = `GameState.PARTY_TROOP_IDS` đủ 4, treo máy = đúng `member_troop_ids` của team đó) nhận đúng số này, cộng vào CẢ Base EXP lẫn Job EXP (dùng chung 1 số, chưa tách riêng 2 giá trị khác nhau).
- Giết quái trong `BattleScene` (đánh tay) → `_apply_damage()` gọi `GameState.grant_kill_exp()` ngay khi quái chết. Giết quái trong Treo máy → `GameState.settle_idle_team()` cộng theo số chu kỳ.
- **Công thức tăng chỉ số theo cấp (chốt với người dùng, KHÔNG suy diễn)**: Base Lv +10%/cấp CỘNG THẲNG theo gốc cho HP/ATK/DEF/M.DEF (không dồn lãi kép - Lv.50 = +490%, không phải nhân dồn 1.1^49 lần). Job Lv +1 ATK THẲNG/cấp, cộng sau khi ATK đã +10%/Base Lv. Các chỉ số khác (tốc đánh/chí mạng/né/hồi máu/xuyên giáp/hút máu) KHÔNG scale theo cấp.
- Áp trực tiếp vào combat thật qua `GameState.effective_hp/atk/def/m_def(troop_id, base_value)` - `TroopUnit.max_hp()/effective_atk()/effective_def()/effective_m_def()` tự gọi các hàm này CHỈ khi `team == Enums.Team.PLAYER` (quái/boss không lên cấp, luôn dùng số gốc trong `LinhData`).

## Nguyên tắc dữ liệu mới (giữ đúng quy ước data-driven đã có)
Toàn bộ data mới (`BossData`, `MapData` đã có từ trước, 7 `LinhData` quái boss, 7 `StageData` quái boss) đều theo ĐÚNG khuôn `TroopDatabase`/`StageDatabase` cũ: auto-scan thư mục `data/<loại>/`, thêm file mới không cần sửa code autoload. `id` các entity mới đều dùng khoảng 100+/200+ để chắc chắn không đụng id cũ (troop id cũ lớn nhất quan sát được ~22, stage id cũ 1-6).
