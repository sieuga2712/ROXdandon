# Tiến độ & Việc còn dang dở

Thuộc [[Mục lục]]. Gộp toàn bộ mục "còn dang dở"/"việc cần làm tiếp theo" rải rác trong các ghi chú chức năng vào 1 chỗ. Chi tiết từng mục xem ở ghi chú chức năng tương ứng (link kèm theo).

> Cập nhật lớn nhất **2026-08-03**: đổi hẳn tab "Ải" từ map AFK-farm điều khiển được sang bảng "Ủy Thác" + hệ "Treo máy" thật; xây THẬT tab "Ải Boss" và tab "Nhân vật" (trước đó cả 2 chỉ là placeholder rỗng); thêm hệ EXP/Cấp độ đầu tiên của game (ảnh hưởng chỉ số chiến đấu thật). Xem đầy đủ ở [[Ủy Thác, Boss & Treo máy]].
>
> Cập nhật tiếp theo **2026-08-08**: đổi HẲN cách tính thưởng Treo máy - bỏ công thức chu kỳ/thời gian trôi qua, chuyển sang 1 trận đấu THẬT chạy nền liên tục, quái chết thật cộng thưởng thật ngay lúc đó (đúng ý tưởng gốc "tính riêng theo từng quái hạ được" đã từng ghi là chưa làm); chỉ còn 1 team treo máy (bỏ nhiều-team/nhiều-map); màn "Xem treo máy" giờ CHÍNH LÀ trận đó (reparent, không tạo bản giả lập riêng nữa); kèm loạt fix animation (đạn bay Cung/Pháp, xác chết tự ẩn sau 2s, không còn đứng hình ở tư thế đánh cuối) + dọn code trùng lặp. Xem đầy đủ ở [[Ủy Thác, Boss & Treo máy]].
>
> **Ghi chú (chưa rõ ngày chính xác, giữa 2 lần cập nhật trên và bản mới nhất)**: project đã được TÁI CẤU TRÚC toàn bộ từ `scripts/` phẳng sang module `core/`/`entities/`/`features/`/`legacy/` (xem `PROJECT_INDEX.md` ở gốc repo - đọc file đó trước khi mở code, mọi đường dẫn `scripts/...` trong các ghi chú CŨ ở vault đều đã LỖI THỜI). Kèm theo: gộp "Ải Boss" thành sub-tab thứ 3 trong tab "Ải" (không còn tab riêng ở BottomNav), thêm nhân vật Soldier #2, đổi combat sang nhiều ĐỢT quái/tầng (`EncounterGenerator`, camera tự bám đội hình kiểu auto-runner), và bắt đầu hệ nguyên liệu/kho (`MaterialDatabase`, `WarehousePanel`/`UpgraderPanel` trong tab Thành) - lúc đó CHƯA có nguồn rớt đồ thật.
>
> Cập nhật **2026-08-17**: thêm nguồn rớt đồ THẬT - hạ 1 quái (đánh tay hay treo máy) có **70% rơi 1 nguyên liệu cấp 1** (ngẫu nhiên trong 10 nhóm, `MaterialDatabase.random_tier1_id()`, gọi từ cả `StageFarmWorld`/`BattleScene`). Tách tab "Kho" (`inventory`, trước là placeholder tĩnh) thành module riêng `features/inventory/InventoryScreen.gd` - đọc thật `GameState.materials`, cùng dữ liệu với "Kho báu" trong tab Thành nhưng KHÔNG dùng chung code (2 feature không được gọi thẳng nhau). Thêm nhãn "Lv.X" cạnh thanh máu mỗi đơn vị trên chiến trường (`TroopUnit.level_label` - quái dùng `monster_level` thật từ `EncounterGenerator`, phe mình dùng Base Lv thật).
>
> Cập nhật tiếp theo **2026-08-17 (cùng ngày)**:
> - **Kho (`inventory`)**: nâng cấp P0 theo đề xuất `de_xuat_cai_thien_kho_do` - 2 tab "Tất cả"/"Nguyên liệu", viền ô đổi màu theo cấp (`MaterialData.tier`), bấm ô mở popup chi tiết + nút "Ghép lên cấp kế". Sửa layout lưới: `_grid` (`GridContainer`, 8 cột) có bề rộng CỐ ĐỊNH `GRID_WIDTH=442px` (ép qua `custom_minimum_size.x`, không co theo số món đang có) rồi canh giữa trong card - hàng thiếu ô không còn dồn về trái dư khoảng trống lớn bên phải, không cần ô filler.
> - **Bug "Boss nhảy sang map cũ"**: `features/combat/BattleScene.gd` (dùng cho MỌI trận Boss) thiếu hẳn cơ chế nền bám/giới hạn camera mà `StageFarmWorld` đã có, nên chỉ sau đúng 1 đợt quái, camera cuộn qua khỏi nền cố định 640px và lộ nền đen phía sau. Thiết kế lại CẢ HAI engine theo hướng "CombatArea nhỏ, cố định" (khác hẳn `_wave_anchor_x` cộng dồn vô hạn như trước): đợt quái thường xoay vòng qua 3 vị trí X cố định (`TRASH_WAVE_SLOTS`/`WAVE_SLOT_COUNT`), boss (`BattleScene`) luôn đứng ở 1 vị trí xa nhất cố định, `Camera2D.limit_left/right` chặn cứng camera không vượt quá nền (nền giờ TĨNH, đúng kích thước, không còn hack "bám theo camera mỗi frame" ở `StageFarmWorld` nữa), kèm kỹ thuật "floating-origin recenter" (dịch cả party+camera lùi lại đúng lúc hết quái giữa 2 đợt) để world-X không bao giờ tăng vô hạn dù 1 tầng có tới 29 đợt (floor cao ở Treo máy). KHÔNG gộp 2 combat engine, KHÔNG tạo class `WaveManager` mới, KHÔNG đổi `StageData`/`EncounterGenerator`/`GameState`/`TroopUnit`.

## Trạng thái tổng quan
- **Vỏ app portrait 5-tab chạy được đầy đủ**: `MainShell.tscn` (`540x960`, `stretch/aspect=expand`) + `BottomNav` (thu gọn/mở rộng kéo tay) + `ScreenRouter` (5 tab: Thành phố/Ải/Ải Boss/Nhân vật/Cài đặt). Xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- **Tab Thành phố** (`city`): `OverworldMap.tscn` KHÔNG có script - thuần cảnh trang trí (2 nhà + 2 NPC + 2 placeholder), KHÔNG điều khiển được, không combat.
- **Tab Ải** (`stage`) = `StageBoardScreen` - bảng thẻ, KHÔNG có map:
  - Sub-tab "Ủy Thác": 4 map × nhiều tầng, bấm thẻ vào thẳng tầng tiếp theo qua `BattleScene` thật. Chỉ có vai trò mở khoá tầng cho Treo máy.
  - Sub-tab "Treo máy": hệ treo máy THẬT - CHỈ 1 team tại 1 thời điểm, là 1 trận đấu thật chạy nền liên tục (`GameState._idle_farm_map`), quái chết thật cộng vàng/EXP thật NGAY LÚC ĐÓ (không qua công thức nào) - có nút "XEM" *nhúng* (reparent) đúng trận đang chạy vào màn hình để nhìn (không phải cảnh minh hoạ riêng) + "RÚT VỀ".
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
- [x] **2026-08-08**: Công thức thưởng Treo máy giờ mô phỏng đúng "tính riêng theo từng quái hạ được" (đã từng ghi là chưa làm ở bản 08-03) - không còn `reward_gold`/`time_limit` đơn giản hoá nữa, quái chết thật trong trận nền mới cộng thưởng thật.
- [x] **2026-08-08**: Màn "Xem treo máy" không còn là hình ảnh minh hoạ tách biệt - giờ `reparent()` đúng trận đang chạy nền vào màn hình, xem hay không xem không ảnh hưởng thưởng.
- [ ] **CHƯA có save/load persistence** (vẫn là việc lớn nhất còn thiếu, nhưng đổi khác đi so với trước) - riêng phần Treo máy giờ **"tắt app là mất luôn" là lựa chọn thiết kế có chủ đích** (không bù giờ, không cần persistence riêng cho nó - khác hẳn cách nghĩ "tính cả lúc tắt app" của bản 08-03). Nhưng `GameState` nói chung (vàng, EXP/cấp độ nhân vật, `highest_floor_cleared`) vẫn reset hoàn toàn mỗi lần mở lại game - cần 1 tính năng persistence riêng (lưu ra file, đọc lại lúc khởi động) nếu muốn giữ tiến độ chung xuyên suốt các lần mở app.
- [ ] Chỉ 4 map/vài tầng mỗi map có `StageData` thật - chưa có nội dung phong phú ở tầng cao.
- [ ] `StageFarmWorld` (trận treo máy nền) chỉ có đòn đánh thường, chưa có skill "đánh mạnh" như `BattleScene` - cắt bớt có chủ đích cho bản đầu.

## Đội hình / Roster (kế thừa từ trước, cập nhật EXP/Cấp độ)
- [ ] **Chỉ 4 nhân vật cố định** (Soldier/Archer/Wizard/Priest) - chưa có cách mở rộng/đổi thành viên, dù roster có sẵn 22+ loại lính/quái để chọn.
- [x] **EXP/Cấp độ thật đã có** (xem trên) - không còn "chưa có hệ lên cấp" như note cũ.
- [ ] Chưa có hệ trang bị/gacha (đã chốt KHÔNG làm gacha - game không có chiêu mộ nhân vật).
- [ ] Số liệu chỉ số GỐC của quái/boss vẫn phần lớn là placeholder tự chia tier (trừ EXP reward đã cân theo HP mỗi loại) - chưa phải công thức cân bằng cuối cùng.
- [ ] `archer.tres` vẫn còn lỗi kế thừa: `damage_type = MAGIC` dù là cung thủ (đáng lẽ vật lý) - chưa sửa, không chặn gì.

## Điều khiển party trên map - KHÔNG CÒN ÁP DỤNG
Model "1 leader + 3 người tự bám theo" (`PartyRosterPanel`) đã bị XOÁ hoàn toàn - City tab không điều khiển được, Ải tab không còn map. `PartyRosterPanel.gd` đã xoá file (hết chỗ dùng, xác nhận qua grep trước khi xoá). Nếu sau này có map điều khiển được trở lại, đây sẽ là 1 tính năng LÀM MỚI, không phải khôi phục.

## Kỹ thuật (không phải bug, chỉ cần lưu ý)
- **Chưa có save/persistence** - vẫn là việc quan trọng NHẤT còn thiếu (xem mục Treo máy ở trên), ảnh hưởng vàng, EXP/cấp độ nhân vật, tiến độ tầng - riêng team treo máy đang treo thì "mất khi tắt app" giờ là THIẾT KẾ có chủ đích (2026-08-08), không phải phần đang chờ persistence.
- Chưa có **export preset** cho ROXdandon - chưa từng export ra `.exe`/APK thật.
- Chưa test trên **thiết bị/emulator Android thật** (LDPlayer) - mới chỉnh kích thước cửa sổ (`540x960`) cho GIỐNG LDPlayer khi chạy trên PC, chưa build/deploy thật lên emulator.
- Mockup HTML `mockups/giao-dien-hien-tai.html` vẫn còn giữ (dùng để thảo luận/xác nhận thiết kế trước khi code Godot) - có thể đã LỖI THỜI hơn code thật ở vài chỗ (đặc biệt phần Nhân vật/Boss đã có nhiều quyết định thật hơn mockup ban đầu, ví dụ ô trang bị/EXP giờ dùng số THẬT trong Godot chứ mockup vẫn ghi "tượng trưng") - tin code hơn mockup khi lệch.
