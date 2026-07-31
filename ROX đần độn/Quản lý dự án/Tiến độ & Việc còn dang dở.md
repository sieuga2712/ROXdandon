# Tiến độ & Việc còn dang dở

Thuộc [[Mục lục]]. Gộp toàn bộ mục "còn dang dở"/"việc cần làm tiếp theo" rải rác trong các ghi chú chức năng vào 1 chỗ. Chi tiết từng mục xem ở ghi chú chức năng tương ứng (link kèm theo).

> Cập nhật lớn nhất **2026-07-31**: chuyển toàn bộ app sang portrait mobile 5-tab + xây tab Thành phố + tab Ải (AFK-farm). Trước đó project chỉ có 1 màn Hub tĩnh landscape.

## Trạng thái tổng quan
- **Vỏ app portrait 5-tab chạy được đầy đủ**: `MainShell.tscn` (`540x960`, `stretch/aspect=expand`) + `BottomNav` (thu gọn/mở rộng kéo tay) + `ScreenRouter` (5 tab: Thành phố/Ải/Ải Boss/Nhân vật/Cài đặt). Xem [[Vỏ ứng dụng Portrait (MainShell & Navigation)]].
- **Tab Thành phố** (`city`): map nhỏ đi lại được, 2 nhà + 2 NPC + 2 placeholder, party điều khiển được (1 leader + 3 người tự theo). Không có combat, không có xây dựng thật.
- **Tab Ải** (`stage`): map AFK-farm rộng, 6 điểm spawn quái, combat trực tiếp trên map (rút gọn, chưa có skill/đạn bay), quái hồi sinh sau 20s, có thưởng vàng. Xem [[Thành phố & Ải AFK-Farm]].
- **Tab Ải Boss/Nhân vật**: CHỈ LÀ PLACEHOLDER (1 label "đang phát triển"), chưa có logic gì.
- **Tab Cài đặt**: list text tĩnh đúng yêu cầu (Âm thanh/Nhạc/Rung/Đồ họa/Ngôn ngữ/Tài khoản/Lưu game/Trợ giúp/Phiên bản) - chưa bấm được gì, chỉ hiển thị.
- `BattleScene` (đấu 1 trận có thắng/thua/thời gian, `data/stages/stage_1.tres`) **vẫn còn nguyên, đã dựng lại khung dọc**, nhưng **hiện KHÔNG có lối vào nào từ UI** (tab Ải giờ dùng AFK-farm thay vì mở `BattleScene`) - dự định dành cho tab Ải Boss, chưa nối.
- Xác nhận qua headless import/boot (`--headless --import` + `--quit-after N`, không có ERROR) sau MỌI thay đổi lớn, cộng thêm test hành vi bằng debug script tạm cho các phần input/spawn/combat phức tạp (xem [[Lỗi đã gặp & Bài học]]) - **vẫn CHƯA có ai F5 chơi thật bằng tay** để xác nhận cảm giác chơi/UI portrait trên máy thật.

## Việc dang dở theo tab

### Ải Boss (`boss`)
- [ ] Hoàn toàn chưa xây - chỉ có placeholder rỗng.
- [ ] Cần: `StageData` thêm field `is_boss: bool` để lọc riêng danh sách boss từ `StageDatabase` (kế hoạch đã có, chưa làm), 1 `StageData` boss thật (quái mạnh, HP cao), màn hình info+HP+nút "Đánh Boss" mở `BattleScene` qua `StageFlowController.start_stage()`.
- [ ] Kiến trúc chuẩn bị sẵn: `StageFlowController.gd` đã thu hẹp đúng 1 hàm `start_stage(stage)`, chỉ cần gọi từ đây.

### Nhân vật (`character`)
- [ ] Hoàn toàn chưa xây - chỉ có placeholder rỗng.
- [ ] Cần: roster + chỉ số (dữ liệu `LinhData` đã đủ hp/atk/def/... - chỉ thiếu UI xem), CHƯA có hệ trang bị/kỹ năng thật (đừng tự ý gộp "Quân đội" nếu sau này có hệ riêng - xem yêu cầu gốc của người dùng).

### Cài đặt (`settings`)
- [ ] List tĩnh đã đúng yêu cầu hiện tại - CHƯA cần thêm logic trừ khi được yêu cầu.

### Thành phố (`city`)
- [ ] Chưa có đặt/nâng cấp công trình thật - city-building đã bị cắt hẳn khỏi project từ lâu (xem [[Chuyển thể từ vrisingDanDon]]), tab này hiện chỉ là map đi lại/tương tác cảnh vật.
- [ ] Chỉ 2/4 vị trí NPC có nhân vật thật (2 placeholder còn trống).

### Ải (`stage`, AFK-farm)
- [ ] **Combat rút gọn có chủ đích**: chưa có skill "đánh mạnh"/windup, chưa có đạn bay Projectile (archer/wizard/priest) - mọi đòn ra ngay khi trúng tầm như cận chiến. Xem [[Thành phố & Ải AFK-Farm]].
- [ ] Đơn vị người chơi chết thì nằm lại luôn, không tự hồi sinh (chấp nhận được vì quái đầu map yếu).
- [ ] Chỉ 6 điểm spawn cố định hand-code trong script, chưa data-driven qua `.tres` (không cần thiết ở quy mô hiện tại).
- [ ] Chưa có UI hiển thị số liệu farm (tổng vàng/giờ, số quái đã giết...).

## Đội hình / Roster (kế thừa từ trước, chưa đổi)
- [ ] **Chỉ 4 nhân vật cố định** (Soldier/Archer/Wizard/Priest) - chưa có cách mở rộng/đổi thành viên, dù roster có sẵn 22 nhân vật để chọn.
- [ ] **Số liệu chỉ số của 13 quái mới hoàn toàn là placeholder tự chia tier** - chưa phải công thức cân bằng thật.
- [ ] `archer.tres` vẫn còn lỗi kế thừa: `damage_type = MAGIC` dù là cung thủ (đáng lẽ vật lý) - chưa sửa, không chặn gì.
- [ ] Chưa có hệ trang bị/lên cấp/gacha.

## Điều khiển party trên map (City/Ải) - đã đổi qua lại vài lần, ghi rõ để không làm lại
- [ ] Bản ĐANG CHẠY: 1 leader (chọn qua `PartyRosterPanel`) + 3 người LUÔN tự động bám theo - đơn giản, không có trạng thái "độc lập" riêng.
- [ ] Đã từng thử mô hình phức tạp hơn (Ragnarok X): 3 trạng thái điều khiển/đang theo/độc lập, 2 vùng bấm/thẻ, nút "Gọi tất cả" - bị revert lại bản đơn giản (không rõ chủ động hay do editor tự revert, xem [[Lỗi đã gặp & Bài học]]). **Nếu muốn làm lại mô hình phức tạp, đó là việc LÀM LẠI có chủ đích, không phải khôi phục lỗi.**
- [ ] Kéo-vùng-chọn (RTS multi-select) đã bị bỏ hẳn từ sớm, không quay lại.

## Kỹ thuật (không phải bug, chỉ cần lưu ý)
- Chưa có **save/persistence** - `GameState.gold`/party reset mỗi lần mở lại game.
- Chưa có **export preset** cho ROXdandon - chưa từng export ra `.exe`/APK thật.
- Chưa test trên **thiết bị/emulator Android thật** (LDPlayer) - mới chỉnh kích thước cửa sổ (`540x960`) cho GIỐNG LDPlayer khi chạy trên PC, chưa build/deploy thật lên emulator.
- `BattleScene` không còn lối vào từ UI (xem mục Ải Boss ở trên) - không phải bug, chỉ là chưa nối.
