# CLAUDE.md

Quy tắc làm việc cho Claude Code / AI coding agent trong project ROXdandon (Godot 4.3, GDScript).

## Bắt đầu từ đâu

Đọc [PROJECT_INDEX.md](PROJECT_INDEX.md) trước để biết module nào chứa file cần sửa. **Không quét toàn bộ repository.** Chỉ mở file thật sự cần cho task hiện tại.

## Kiến trúc thư mục

```
core/       hạ tầng dùng chung, không chứa gameplay riêng feature nào
  app/        MainShell (main scene), ScreenRouter, BottomNav, GameState (autoload)
  database/   6 autoload dạng "kho tra cứu theo id" (TroopDatabase, StageDatabase, BossDatabase, MapDatabase, MaterialDatabase) + MaterialData
  shared/     UIBuilders, UIConstants — toolkit dựng UI dùng chung
  config/     Enums, ExpTables — hằng số/bảng cân bằng toàn cục

entities/   domain object dùng chung bởi nhiều feature, KHÔNG phụ thuộc ngược vào features/
  troop/      TroopUnit (actor chiến đấu), LinhData, Projectile, ImpactEffect, DamagePopup
  stage/      StageData (dùng chung bởi stage/boss/combat/GameState)

features/   UI + logic riêng từng tab, phạm vi hẹp
  city/       tab "Thành"
  stage/      tab "Ải" (Ủy Thác + Treo máy)
  boss/       tab "Ải Boss"
  character/  tab "Nhân vật"
  combat/     trận đấu thật (StageFlowController = entry point, dùng chung bởi stage + boss)

legacy/     file cũ không còn dùng, giữ lại để tham khảo lịch sử — KHÔNG sửa nội dung, không import ở đâu

data/       resource .tres (troops/stages/maps/bosses) — không đổi khi tái cấu trúc, do database quét path cứng
```

Ngoài code: `assets/` = asset đã tích hợp thật (sprite/animation game dùng trực tiếp). `tainguyen/` = tài nguyên/asset pack bên ngoài dồn về 1 chỗ cho gọn (gồm cả pack bản quyền như Minifantasy, RPG Top Down Characters, và `houses.png/.psd`) — vẫn có thể bị tham chiếu `res://` thật từ `assets/*.tres` hoặc scene, không phải rác, không tự xoá.

Mỗi module có `README.md` riêng (mục đích, file chính, Entry Point, Public API, module được phép gọi, link thiết kế). Đọc README của đúng module đang sửa trước khi đọc code.

## Quy tắc phụ thuộc

```
features/*  →  entities/*  →  core/database, core/config
features/*  →  core/app (GameState)  →  core/database
features/*  →  core/shared, core/config
```

- **Cho phép**: feature gọi `GameState` (autoload), gọi các `*Database` (autoload), dùng `entities/troop`, `entities/stage`, `core/shared`, `core/config`.
- **Không cho phép**: 1 feature đọc/gọi thẳng code nội bộ của feature khác (vd `features/boss` không được import trực tiếp file trong `features/character`). Giao tiếp giữa feature khác chỉ qua `GameState`, `*Database`, hoặc signal có sẵn (vd `StageFlowController.stage_finished`).
- **Ngoại lệ đã biết, không phải lỗi**: `features/boss/BossData.gd` gọi `StageDatabase.get_by_id()` — hợp lệ vì đi qua autoload Database, không phải nội bộ `features/stage`.
- **Ngoại lệ đã biết #2** (2026-08): `features/stage/StageBoardScreen.tscn` nhúng thẳng instance `features/boss/BossBoardScreen.tscn` làm sub-tab thứ 3 (`%BossPanel`) — "Ải Boss" không còn là tab riêng ở BottomNav. Đây là ngoại lệ CÓ CHỦ ĐÍCH cho đúng 1 cặp module này (UI nhúng UI, không phải đọc field nội bộ) — không suy rộng ra cho các cặp feature khác nếu chưa có quyết định tương tự.
- `entities/` không bao giờ import ngược `features/` — nếu thấy vi phạm, đó là bug cần báo, không tự sửa lan sang việc khác.

## Nguyên tắc bắt buộc

1. **Không đổi gameplay/logic** trừ khi task yêu cầu rõ ràng.
2. **Không refactor ngoài phạm vi** task hiện tại — kể cả khi thấy chỗ "có thể làm gọn hơn".
3. **Không đổi**: tên file, tên class (`class_name`), tên hàm public, signal, resource path — trừ khi được yêu cầu trực tiếp.
4. **Minimal diff**: sửa đúng dòng cần sửa, không format lại cả file, không dọn dẹp không liên quan.
5. **Mỗi task chỉ xử lý một vấn đề/một module.** Phát hiện bug khác ngoài phạm vi task → **không sửa**, chỉ ghi chú lại cuối câu trả lời.
6. **Thiếu thông tin thì hỏi**, không tự suy đoán rồi mở rộng phạm vi đọc file.
7. Tài liệu thiết kế gốc (ý tưởng, lý do thiết kế, lịch sử quyết định) nằm ở `ROX đần độn/` — đọc ở đó khi cần hiểu "tại sao", không phải để tìm code.
8. Đừng tạo thư mục rỗng (vd không tự tạo `core/utils/` nếu chưa có file nào cần).
9. **Chỉ sửa `mockups/giao-dien-hien-tai.html` khi hướng thiết kế đã CHỐT** (user xác nhận rõ ràng, không còn đang so sánh/thảo luận phương án). Trong lúc thảo luận ý tưởng UI, chỉ trả lời bằng text/phân tích trade-off — không tự sửa file mockup theo từng ý tưởng chưa quyết, tránh mockup nhảy lung tung không phản ánh đúng cái đã chốt.
