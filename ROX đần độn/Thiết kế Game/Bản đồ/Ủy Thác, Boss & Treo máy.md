# Ủy Thác, Boss & Treo máy

Thuộc [[Mục lục]]. **THAY THẾ hoàn toàn** phần "Tab Ải AFK-farm" cũ trong [[Thành phố & Ải AFK-Farm]] (đã đánh dấu SUPERSEDED trong note đó, xem note đó cho lịch sử tại sao đổi). Cập nhật lớn **2026-08-03**: đổi hẳn tab "Ải" từ map AFK-farm điều khiển được sang bảng kiểu "Ủy Thác" (không map, không điều khiển) + xây thật tab "Ải Boss" + xây thật hệ "Treo máy" (idle) + hệ EXP/Cấp độ đầu tiên của game.

> Cập nhật lớn **2026-08-08**: đổi HẲN cách tính thưởng Treo máy - bỏ công thức "chu kỳ theo thời gian trôi qua" (`settle_idle_team`), chuyển sang **1 trận đấu thật chạy nền liên tục**, quái chết thật thì cộng vàng/EXP thật ngay lúc đó. Đồng thời bỏ hẳn nhiều-team/nhiều-map (`idle_teams`), chỉ còn ĐÚNG 1 team treo máy tại 1 thời điểm. Xem mục "Treo máy" bên dưới đã viết lại hoàn toàn.

## Vì sao đổi (tóm tắt quyết định thiết kế)
- Người dùng muốn mô hình giống AFK Arena: 4 map, mỗi map nhiều tầng tăng dần, xem bằng bảng thẻ chứ không phải đi lại trên map.
- Sau đó quyết định: **Ủy Thác (đánh tay) và Treo máy là 2 hệ HOÀN TOÀN TÁCH BIỆT** - nhân vật đang treo máy vẫn đánh Ủy Thác/Boss bình thường, không bị "bận".
- Vai trò của Ủy Thác/Boss thu hẹp lại: **chỉ để mở khoá tầng cao hơn cho Treo máy** (`GameState.highest_floor_cleared`), không còn là nguồn thưởng chính.
- Giết quái (đánh tay HAY treo máy) → cả team liên quan nhận EXP → có Base Lv/Job Lv thật, ảnh hưởng chỉ số chiến đấu thật.
- **2026-08-08**: sau khi thảo luận lại, bỏ hẳn ý tưởng nhiều team/nhiều map treo máy cùng lúc + công thức DPS/thời gian trôi qua - đổi sang "Farm bao nhiêu được bấy nhiêu": chỉ 1 team treo máy, nhưng đó là 1 trận đấu THẬT chạy nền, quái chết thật mới tính thưởng thật (xem mục "Treo máy" bên dưới).

## Tab "Ải" (`stage`) = `StageBoardScreen.tscn`/`.gd` - bảng thẻ, KHÔNG có map
2 sub-tab (nút bấm thường, không phải `TabContainer`):

### Sub-tab "Ủy Thác"
- Data: `MapData`/`MapDatabase` (4 map, `data/maps/*.tres`) × `StageData`/`StageDatabase` (mỗi tầng 1 file, có `map_id`/`floor_number`, `data/stages/*.tres`).
- Mỗi map 1 thẻ (icon/tên/loại khu vực/điều kiện thắng/độ khó/tầng hiện tại) + nút "VÀO TRẬN" - bấm là **vào thẳng tầng tiếp theo** (`highest_floor_cleared[map_id] + 1`) qua `BattleScene` thật, KHÔNG có bước chọn tầng riêng.
- Thắng → `StageFlowController.stage_finished` → `GameState.report_floor_cleared()` → mở khoá tầng kế cho CẢ Ủy Thác lẫn giới hạn tầng của Treo máy.

### Sub-tab "Treo máy" - viết lại hoàn toàn 2026-08-08, KHÔNG còn công thức nào
- **CHỈ 1 team treo máy tại 1 thời điểm** (đã bỏ hẳn `idle_teams` Array/nhiều-team/nhiều-map/`IDLE_MAX_TEAMS_PER_MAP` của bản 08-03) - `GameState._idle_farm_map: StageFarmMap` giữ sống 1 instance duy nhất, `GameState.has_idle_team()`/`is_troop_idling()`/`get_idle_farm_map()` truy vấn thẳng instance đó (không còn Dictionary `idle_team` riêng lưu trùng `stage_id`/`member_troop_ids` - đã dọn dẹp 2026-08-08, `StageFarmMap.get_stage()`/`get_member_troop_ids()` là nguồn thật duy nhất).
- **Treo máy = 1 trận đấu THẬT chạy nền liên tục** ngay khi bấm "BẮT ĐẦU TREO" (`GameState.start_idle_team()` instance `StageFarmMap.tscn`, `add_child()` vào chính `GameState` - autoload nên sống suốt vòng đời app, KHÔNG phụ thuộc đang ở tab nào). Quái chết THẬT trong trận nền đó (`StageFarmWorld._apply_damage()`) thì cộng `LinhData.gold_reward` + `LinhData.exp_reward` **NGAY LÚC ĐÓ** cho các thành viên team - KHÔNG qua công thức/chu kỳ/thời gian trôi qua nào cả.
- "Farm bao nhiêu được bấy nhiêu" - **CHẠY KHI APP ĐANG MỞ**, tắt app là mất luôn node đó (không bù giờ) - đây là **lựa chọn thiết kế có chủ đích**, không phải thiếu sót (khác hẳn cách nghĩ "tính cả lúc tắt app" của bản 08-03 cũ).
- Ràng buộc còn lại: 1 nhân vật không thuộc 2 team treo máy cùng lúc, tầng tối đa được chọn khi tạo team vẫn = `GameState.get_highest_floor(map_id)` - **đây vẫn là lý do Ủy Thác cần tồn tại**.
- Màn "Tạo đội treo" (nội bộ trong `StageBoardScreen`, không phải scene riêng): chọn map (`OptionButton`) → chọn tầng (stepper -/+) → chọn 1-4 thành viên → "BẮT ĐẦU TREO". Nút "+" chỉ hiện khi CHƯA có team nào đang treo (phải "RÚT VỀ" trước khi tạo team khác, vì giờ chỉ 1 team).

### Màn "Xem treo máy" - giờ CHÍNH LÀ trận đấu thật, không còn là hình minh hoạ riêng
- Viết lại hoàn toàn tư duy so với bản 08-03: **KHÔNG tạo bản mới lúc bấm "XEM"** - `StageBoardScreen._open_idle_view()` chỉ **`reparent()`** đúng instance `StageFarmMap` đang chạy sống trong `GameState` vào `%IdleViewHost` để nhìn; đóng lại (nút "←") thì `reparent()` NGƯỢC VỀ `GameState` (KHÔNG `queue_free()` - phải tiếp tục chạy nền, khác hẳn bản cũ vốn `queue_free()` để "dừng simulation" khi đóng).
- Vì đây chính là trận thật nên xem hay không xem KHÔNG ảnh hưởng gì tới thưởng - quái vẫn chết và cộng thưởng y hệt lúc không mở màn này. Dòng ghi chú trên UI (`IdleViewNote`) đã sửa lại đúng nội dung này (trước đó còn sót câu "chỉ xem cho vui" của bản 08-03, gây hiểu lầm - đã sửa 2026-08-08).
- `StageFarmWorld.gd` (file TỪNG LÀ toàn bộ nội dung tab Ải cũ - map AFK-farm điều khiển được, xem [[Thành phố & Ải AFK-Farm]] cho lịch sử) chỉ có đòn đánh thường (chưa có skill "đánh mạnh"), nhưng ĐÃ có đạn bay Cung/Pháp + hiệu ứng Tu sĩ dùng chung asset với `BattleScene` (thêm 2026-08-08, trước đó Cung/Pháp chỉ đổi tư thế đánh mà không có hiệu ứng gì bay tới mục tiêu). Hết 1 phe → chờ 2s (`RESTART_DELAY`) → hồi sinh cả 2 phe → đánh lại, loop vô hạn, không có thắng/thua. Trong lúc chờ hồi sinh, các đơn vị còn sống được ép về idle mỗi frame (`_hold_survivors_idle`) để không đứng hình ở tư thế đánh dở dang; xác chết tự ẩn sau 2s (`CORPSE_VANISH_DELAY`) thay vì nằm lại tới khi cả phe chết sạch (2 fix thêm 2026-08-08).

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
- Giết quái trong `BattleScene` (đánh tay) HAY `StageFarmWorld` (treo máy) đều gọi `_apply_damage()` của chính scene đó → `GameState.grant_kill_exp()` ngay khi quái chết thật - CÙNG 1 thời điểm với lúc cộng vàng, không còn tách riêng "cộng theo chu kỳ" như bản 08-03 cũ.
- **Công thức tăng chỉ số theo cấp (chốt với người dùng, KHÔNG suy diễn)**: Base Lv +10%/cấp CỘNG THẲNG theo gốc cho HP/ATK/DEF/M.DEF (không dồn lãi kép - Lv.50 = +490%, không phải nhân dồn 1.1^49 lần). Job Lv +1 ATK THẲNG/cấp, cộng sau khi ATK đã +10%/Base Lv. Các chỉ số khác (tốc đánh/chí mạng/né/hồi máu/xuyên giáp/hút máu) KHÔNG scale theo cấp.
- Áp trực tiếp vào combat thật qua `GameState.effective_hp/atk/def/m_def(troop_id, base_value)` - `TroopUnit.max_hp()/effective_atk()/effective_def()/effective_m_def()` tự gọi các hàm này CHỈ khi `team == Enums.Team.PLAYER` (quái/boss không lên cấp, luôn dùng số gốc trong `LinhData`).

## Nguyên tắc dữ liệu mới (giữ đúng quy ước data-driven đã có)
Toàn bộ data mới (`BossData`, `MapData` đã có từ trước, 7 `LinhData` quái boss, 7 `StageData` quái boss) đều theo ĐÚNG khuôn `TroopDatabase`/`StageDatabase` cũ: auto-scan thư mục `data/<loại>/`, thêm file mới không cần sửa code autoload. `id` các entity mới đều dùng khoảng 100+/200+ để chắc chắn không đụng id cũ (troop id cũ lớn nhất quan sát được ~22, stage id cũ 1-6).
