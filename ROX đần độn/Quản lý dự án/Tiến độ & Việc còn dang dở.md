# Tiến độ & Việc còn dang dở

Thuộc [[Mục lục]]. Gộp toàn bộ mục "còn dang dở"/"việc cần làm tiếp theo" rải rác trong các ghi chú chức năng vào 1 chỗ. Chi tiết từng mục xem ở ghi chú chức năng tương ứng (link kèm theo).

## Trạng thái tổng quan
Project khung sườn đã **boot sạch và chơi được 1 vòng đầy đủ**: Hub → chọn Ải 1 → auto-battle 4 người (Soldier/Archer/Wizard/Priest) vs 4 quái (2 Slime + 2 Skeleton) → thắng/thua → nhận vàng → quay lại Hub. Đã xác nhận qua headless import/boot (`--headless --import` + `--quit-after 60`, không có ERROR nào) - **CHƯA có ai F5 chơi thật bằng tay để xác nhận cảm giác chơi** (animation, tốc độ, cân bằng số liệu).

## Đội hình / Roster
- [ ] **Chỉ 4 nhân vật cố định** (Soldier/Archer/Wizard/Priest, xem [[Đội hình cố định (Party)]]) - chưa có cách mở rộng/đổi thành viên, dù roster có sẵn 22 nhân vật để chọn.
- [ ] **Số liệu chỉ số của 13 quái mới hoàn toàn là placeholder tự chia tier** (Slime yếu nhất → Orc Rider mạnh nhất theo cảm quan, không phải công thức cân bằng thật) - xem [[Danh sách quái (Monster Roster)]].
- [ ] `archer.tres` vẫn còn lỗi kế thừa từ `vrisingDanDon`: `damage_type = MAGIC` dù là cung thủ (đáng lẽ vật lý) - chưa sửa, không chặn gì vì `def`/`m_def` hiện bằng nhau.
- [ ] Chưa có hệ trang bị/lên cấp/gacha - nằm ngoài phạm vi đợt scaffold này (xem [[Tóm tắt dự án]]).

## Chiến đấu
- [ ] **Chỉ có Ải 1** - chưa thiết kế độ khó tăng dần cho ải 2 trở đi (`StageDatabase` đã auto-scan sẵn, thêm ải mới chỉ cần thêm `.tres` mới, xem [[Luồng chơi (Hub → Ải → Chiến đấu)]]).
- [ ] **AI chưa phân vai theo loại lính** (melee bao vây/ranged đứng sau) - mọi loại xử lý giống nhau, chỉ khác bán kính slot theo tầm đánh riêng - kế thừa nguyên hạn chế này từ `vrisingDanDon`, xem [[AI chiến đấu]].
- [ ] Công thức sát thương/tầm đánh/Move Speed vẫn là **số liệu tạm tự đặt**, mang nguyên từ `vrisingDanDon` - xem [[Công thức sát thương]], [[Chỉ số lính]].
- [ ] 17/20 "Kiểu tấn công" tham khảo vẫn chưa làm (Beam, Dash, Cone, Nova, Chain, Summon...) - xem [[Kiểu tấn công (Attack Types)]], kế thừa nguyên danh sách từ `vrisingDanDon`.

## Hub / Giao diện
- [ ] Roster trong Hub chỉ hiện icon + tên, không có HP/level (chưa cần vì chưa có state lâu dài giữa các trận) - xem [[Hub & Quy ước UI chung]].
- [ ] Không có màn xem chi tiết chỉ số từng nhân vật trước khi vào trận (`vrisingDanDon` có bảng info khi hover/bấm ô lính - ROXdandon chưa có gì tương đương).

## Kỹ thuật (không phải bug, chỉ cần lưu ý)
- Chưa có **save/persistence** - `GameState.gold`/party reset mỗi lần mở lại game.
- Chưa có **export preset** cho ROXdandon (`vrisingDanDon` có sẵn preset `"ClashOfClanDanDon"` cho Windows Desktop - ROXdandon chưa từng export ra `.exe`).
- Repo `ROXdandon` mới tạo, **có thể chưa có commit nào** tuỳ thời điểm đọc note này - kiểm tra `git log` trước khi giả định lịch sử commit.
