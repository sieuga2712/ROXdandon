# Tiến độ & Việc còn dang dở

Thuộc [[Mục lục]]. Gộp toàn bộ mục "còn dang dở"/"việc cần làm tiếp theo" rải rác trong các ghi chú chức năng vào 1 chỗ. Chi tiết từng mục xem ở ghi chú chức năng tương ứng (link kèm theo).

> Cập nhật lớn nhất **2026-08-03**: đổi hẳn tab "Ải" từ map AFK-farm điều khiển được sang bảng "Ủy Thác" + hệ "Treo máy" thật; xây THẬT tab "Ải Boss" và tab "Nhân vật" (trước đó cả 2 chỉ là placeholder rỗng); thêm hệ EXP/Cấp độ đầu tiên của game (ảnh hưởng chỉ số chiến đấu thật). Xem đầy đủ ở [[Ủy Thác, Boss & Treo máy]].

## Trạng thái tổng quan
- **Vỏ app portrait 5-tab chạy được đầy đủ**: `MainShell.tscn` (`540x960`, `stretch/aspect=expand`) + `BottomNav` (thu gọn/mở rộng kéo tay) + `ScreenRouter` (5 tab: Thành phố/Ải/Ải Boss/Nhân vật/Cài đặt). Xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- **Tab Thành phố** (`city`): `OverworldMap.tscn` KHÔNG có script - thuần cảnh trang trí (2 nhà + 2 NPC + 2 placeholder), KHÔNG điều khiển được, không combat.
- **Tab Ải** (`stage`) = `StageBoardScreen` - bảng thẻ, KHÔNG có map:
  - Sub-tab "Ủy Thác": 4 map × nhiều tầng, bấm thẻ vào thẳng tầng tiếp theo qua `BattleScene` thật. Chỉ có vai trò mở khoá tầng cho Treo máy.
  - Sub-tab "Treo máy": hệ treo máy THẬT - tạo team (1-4 người, không trùng người đang treo team khác), tính thưởng theo thời gian trôi qua thật (`GameState.settle_idle_team`), có nút "XEM" mở cảnh auto-fight cho vui (không tính thưởng gì thêm) + "RÚT VỀ".
- **Tab Ải Boss** (`boss`) = `BossBoardScreen` - THẬT, không còn placeholder: Boss Ngày (2 boss, mỗi boss chọn độ khó Dễ/Thường/Khó, mỗi độ khó là 1 `StageData` riêng) + Boss Khủng (1 boss, không có độ khó, chưa có lịch hẹn giờ thật).
- **Tab Nhân vật** (`character`) = `CharacterBoardScreen` - THẬT, không còn placeholder: liệt kê đúng 4 party thật (không phải gacha), danh sách + chi tiết (chỉ số hiệu dụng đã cộng bonus cấp độ, ô trang bị tượng trưng, khối EXP/Cấp độ thật).
- **Tab Cài đặt**: list text tĩnh đúng yêu cầu, chưa bấm được gì.
- **Hệ EXP/Cấp độ mới** (dùng chung Ủy Thác/Boss/Treo máy): `ExpTables.gd` (129 cấp Base + 49 cấp Job, đúng số trong `ROX_EXP_Goc_Base_Job_DayDu.xlsx` chia 1/10) + `LinhData.exp_reward` + `GameState` tính cấp/EXP + công thức tăng chỉ số (Base Lv +10%/cấp cộng thẳng HP/ATK/DEF/M.DEF, Job Lv +1 ATK thẳng/cấp) áp trực tiếp vào combat thật.
- `BattleScene` (đấu 1 trận có thắng/thua/thời gian) giờ dùng CHUNG cho cả Ủy Thác lẫn Ải Boss qua 1 `StageFlowController` (đúng như kiến trúc đã chuẩn bị sẵn từ trước).
- Xác nhận qua headless import/boot (`--headless --import` + `--quit-after N`, không có ERROR) sau MỌI thay đổi lớn, cộng thêm debug script tạm (xoá ngay sau khi test) mô phỏng bấm nút/đổi tab/chạy nhiều frame combat để xác nhận hành vi UI+logic thật, không chỉ "không crash" - **vẫn CHƯA có ai F5 chơi thật bằng tay** để xác nhận cảm giác chơi/UI portrait trên máy thật.

## Việc dang dở theo tab

### Ải Boss (`boss`)
- [x] Đã xây thật - xem [[Ủy Thác, Boss & Treo máy]].
- [ ] Boss Khủng chưa có lịch hẹn giờ xuất hiện thật (dòng "Thời gian xuất hiện" là placeholder tĩnh, nút luôn bấm được).
- [ ] Chưa có giới hạn số lượt đánh Boss Ngày/ngày (reset mỗi ngày) - đánh được vô hạn lần hiện tại.
- [ ] Boss chỉ reskin quái có sẵn (`elite_orc`/`armored_orc`/`greatsword_skeleton`) - chưa có sprite/hoạt ảnh riêng cho boss.

### Nhân vật (`character`)
- [x] Đã xây thật - xem [[Ủy Thác, Boss & Treo máy]].
- [ ] Ô trang bị (8 + 3) hoàn toàn TƯỢNG TRƯNG - chưa có hệ trang bị/item thật đứng sau, không bấm được gì.
- [ ] EXP/Cấp độ mới ảnh hưởng HP/ATK/DEF/M.DEF - CHƯA ảnh hưởng crit/tốc đánh/né/hồi máu/xuyên giáp/hút máu (chốt phạm vi, không phải thiếu sót).
- [ ] Job Lv mới hỗ trợ "First Job" - CHƯA có cơ chế chuyển job (Second/Third/Fourth Job có số liệu sẵn trong `ExpTables` nguồn xlsx nhưng chưa nạp/chưa có gameplay chuyển job).

### Cài đặt (`settings`)
- [ ] List tĩnh đã đúng yêu cầu hiện tại - CHƯA cần thêm logic trừ khi được yêu cầu.

### Thành phố (`city`)
- [ ] Chưa có đặt/nâng cấp công trình thật - city-building đã bị cắt hẳn khỏi project từ lâu (xem [[Chuyển thể từ vrisingDanDon]]), tab này hiện thuần cảnh trang trí, KHÔNG điều khiển được nhân vật (theo yêu cầu người dùng).
- [ ] Chỉ 2/4 vị trí NPC có nhân vật thật (2 placeholder còn trống).

### Ải (`stage` - Ủy Thác + Treo máy)
- [x] Đổi hẳn kiến trúc, xem [[Ủy Thác, Boss & Treo máy]] cho chi tiết đầy đủ.
- [ ] **CHƯA có save/load** - Treo máy tính thưởng theo giờ hệ thống thật (`Time.get_unix_time_from_system()`) nên VỀ CÔNG THỨC đã đúng kiểu "tính cả lúc tắt app", nhưng `GameState` reset hoàn toàn mỗi lần mở lại game nên THỰC TẾ tắt app hẳn vẫn mất tiến độ. **Đây là việc lớn nhất còn thiếu** - cần 1 tính năng persistence riêng (lưu `idle_teams`/`base_exp_total`/`job_exp_total`/`gold`/`highest_floor_cleared` ra file, đọc lại lúc khởi động).
- [ ] Màn "Xem treo máy" (`StageFarmMap`/`StageFarmWorld` viết lại) là hình ảnh minh hoạ, KHÔNG dùng chỉ số thời gian đã trôi qua để mô phỏng đúng số lần đã đánh - mỗi lần mở là 1 trận mới từ đầu, không đồng bộ với tiến độ thật đang tính ở `settle_idle_team`.
- [ ] Công thức thưởng Treo máy đơn giản hoá: `reward_gold`/`time_limit` của `StageData`, KHÔNG mô phỏng DPS thật của từng thành viên so với HP/DEF quái như ý tưởng gốc "tính riêng theo từng quái hạ được" - chấp nhận được cho bản đầu, có thể làm đúng hơn sau.
- [ ] Chỉ 4 map/vài tầng mỗi map có `StageData` thật - chưa có nội dung phong phú ở tầng cao.

## Đội hình / Roster (kế thừa từ trước, cập nhật EXP/Cấp độ)
- [ ] **Chỉ 4 nhân vật cố định** (Soldier/Archer/Wizard/Priest) - chưa có cách mở rộng/đổi thành viên, dù roster có sẵn 22+ loại lính/quái để chọn.
- [x] **EXP/Cấp độ thật đã có** (xem trên) - không còn "chưa có hệ lên cấp" như note cũ.
- [ ] Chưa có hệ trang bị/gacha (đã chốt KHÔNG làm gacha - game không có chiêu mộ nhân vật).
- [ ] Số liệu chỉ số GỐC của quái/boss vẫn phần lớn là placeholder tự chia tier (trừ EXP reward đã cân theo HP mỗi loại) - chưa phải công thức cân bằng cuối cùng.
- [ ] `archer.tres` vẫn còn lỗi kế thừa: `damage_type = MAGIC` dù là cung thủ (đáng lẽ vật lý) - chưa sửa, không chặn gì.

## Điều khiển party trên map - KHÔNG CÒN ÁP DỤNG
Model "1 leader + 3 người tự bám theo" (`PartyRosterPanel`) đã bị XOÁ hoàn toàn - City tab không điều khiển được, Ải tab không còn map. `PartyRosterPanel.gd` đã xoá file (hết chỗ dùng, xác nhận qua grep trước khi xoá). Nếu sau này có map điều khiển được trở lại, đây sẽ là 1 tính năng LÀM MỚI, không phải khôi phục.

## Kỹ thuật (không phải bug, chỉ cần lưu ý)
- **Chưa có save/persistence** - đây giờ là việc quan trọng NHẤT còn thiếu (xem mục Treo máy ở trên), ảnh hưởng cả vàng, EXP/cấp độ nhân vật, tiến độ tầng, và team treo máy.
- Chưa có **export preset** cho ROXdandon - chưa từng export ra `.exe`/APK thật.
- Chưa test trên **thiết bị/emulator Android thật** (LDPlayer) - mới chỉnh kích thước cửa sổ (`540x960`) cho GIỐNG LDPlayer khi chạy trên PC, chưa build/deploy thật lên emulator.
- Mockup HTML `mockups/giao-dien-hien-tai.html` vẫn còn giữ (dùng để thảo luận/xác nhận thiết kế trước khi code Godot) - có thể đã LỖI THỜI hơn code thật ở vài chỗ (đặc biệt phần Nhân vật/Boss đã có nhiều quyết định thật hơn mockup ban đầu, ví dụ ô trang bị/EXP giờ dùng số THẬT trong Godot chứ mockup vẫn ghi "tượng trưng") - tin code hơn mockup khi lệch.
