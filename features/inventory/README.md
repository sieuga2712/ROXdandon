# features/inventory

## Mục đích
Tab "Kho" (`inventory`) — lưới hiện toàn bộ nguyên liệu (`MaterialDatabase`, 50 món: 10 nhóm x 5 cấp) và số lượng thật người chơi đang có (`GameState.materials`). Trước đây là placeholder tĩnh, giờ nối thật.

## File chính
- `InventoryScreen.gd` — dựng UI bằng code, lấy giao diện khung thẻ/ô của `WarehousePanel` làm mẫu nhưng: cố định 8 cột/hàng, CHỈ hiện món đã có (count > 0, không hiện đủ 50 ô). Grid có bề rộng CỐ ĐỊNH `GRID_WIDTH` (442px = 8×50 + 7×6, ép qua `custom_minimum_size.x`) bất kể đang có bao nhiêu món, rồi canh giữa cả khối đó trong card (`_scroll.size_flags_horizontal = SIZE_SHRINK_CENTER`) — không cần ô filler nào, hàng cuối thiếu ô cứ để trống bên phải của khối 442px, đúng kiểu túi đồ mobile đơn giản (AFK Arena). Số lượng lùi vào trong khỏi viền ô; card tự co theo đúng số hàng đang có (không kéo giãn hết màn hình khi ít món). Tự refresh mỗi lần tab được hiện lại.
- **Nâng cấp P0 (theo đề xuất `de_xuat_cai_thien_kho_do`, đã chốt phạm vi với người dùng)**: 2 tab "Tất cả"/"Nguyên liệu" (chỉ 2 tab vì hiện MỌI vật phẩm đều là nguyên liệu — không thêm tab chết cho Trang bị/Tiêu hao/Khác vì chưa có hệ thống nào đứng sau); viền ô + icon trong popup đổi màu theo `MaterialData.tier` (1-5, suy ra kiểu rarity — KHÔNG phải field rarity thật); bấm vào 1 ô mở popup chi tiết (icon lớn/tên/cấp/số lượng/mô tả ngắn + nút "Ghép lên cấp kế" gọi thẳng `GameState.merge_material_up` — hành động DUY NHẤT có thật cho 1 nguyên liệu, không bịa thêm "Sử dụng"/"nhận từ quái nào" vì quái rơi đồ ngẫu nhiên đều 10 nhóm, không gắn riêng nguyên liệu nào).

## Entry Point
`InventoryScreen.gd` — gắn thẳng vào node `inventory` trong `core/app/MainShell.tscn`, id tab `inventory`.

## Public API
Không có — leaf UI screen thuần đọc dữ liệu qua `GameState`/`MaterialDatabase`.

## Module được phép gọi
`core/app` (`GameState.get_material_count`, `GameState.merge_material_up`), `core/database` (`MaterialDatabase`, `MaterialData`), `core/shared` (`UIBuilders`).

## Lưu ý trùng lặp có chủ đích
Cùng ý tưởng hiển thị với `features/city/WarehousePanel.gd` nhưng KHÔNG dùng chung class — `features/inventory` và `features/city` là 2 module ngang hàng, không được phép gọi thẳng vào nhau (xem quy tắc phụ thuộc ở `CLAUDE.md`). Nếu sau này cần đồng bộ chỉnh sửa UI kho, phải sửa CẢ 2 file. **Thẻ "Kho báu" trong tab Thành đã bị BỎ (2026-08)** — `WarehousePanel.gd`/node vẫn còn trong `OverworldMap.tscn` (chưa xoá) nhưng không còn cách nào mở được từ UI, tab "Kho" (`inventory`) giờ là lối vào DUY NHẤT.

## Nguồn thu thập nguyên liệu
Rơi ra khi hạ quái — 70%/quái, luôn nguyên liệu cấp 1 ngẫu nhiên trong 10 nhóm (`MaterialDatabase.random_tier1_id()`), gọi từ `features/stage/StageFarmWorld._roll_material_drop()` và `features/combat/BattleScene._roll_material_drop()`. Đây là nguồn thu thập DUY NHẤT hiện có — chưa có cách lên cấp nguyên liệu qua nhặt trực tiếp (phải ghép qua `features/city/UpgraderPanel.gd`, 5 cấp N → 1 cấp N+1).
