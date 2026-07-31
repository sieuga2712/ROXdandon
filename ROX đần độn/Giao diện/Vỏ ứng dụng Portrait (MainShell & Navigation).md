# Vỏ ứng dụng Portrait (MainShell & Navigation)

Thuộc [[Mục lục]]. Liên quan: [[Thành phố & Ải AFK-Farm]], [[Tiến độ & Việc còn dang dở]]. **Thay thế hoàn toàn** [[Hub & Quy ước UI chung]] (đã lỗi thời - xem ghi chú đầu file đó).

## Bối cảnh đổi
Game chuyển từ khung **landscape 1280x720 cố định, 1 màn Hub duy nhất** sang **portrait mobile thật sự** (`project.godot`: `viewport_width/height=540x960` - đúng preset LDPlayer phổ biến, `window/stretch/aspect="expand"` để UI neo cạnh tự lấp đầy cửa sổ thật bất kể hình dạng, `handheld/orientation="portrait"`) với **5 tab cố định dưới màn hình** kiểu app mobile thật.

## Kiến trúc

```
MainShell.tscn (run/main_scene MỚI - thay Hub.tscn)
  ScreenContainer (script ScreenRouter.gd) - full-rect, map/tab vẽ TOÀN MÀN HÌNH
    city      = instance OverworldMap.tscn   (xem [[Thành phố & Ải AFK-Farm]])
    stage     = instance StageFarmMap.tscn   (xem [[Thành phố & Ải AFK-Farm]])
    boss      = placeholder (Label "đang phát triển")
    character = placeholder (Label "đang phát triển")
    settings  = list Label tĩnh thật (Âm thanh/Nhạc/Rung/Đồ họa/Ngôn ngữ/Tài khoản/Lưu game/Trợ giúp/Phiên bản) - chưa có logic, chỉ hiển thị
  TopStatusBar (nổi ĐÈ LÊN map, không chiếm chỗ layout - vàng, mouse_filter=Ignore để không chặn click xuống map)
  BattleScene (instance có sẵn, overlay TOÀN app - StageFlowController.start_stage(stage) mở ra, dùng chung cho Ải/Ải Boss sau này)
  BottomNav (nổi trên cùng, tự ẩn khi BattleScene đang mở)
```

**Thứ tự vẽ quan trọng** (con sau đè con trước, đúng quy ước Control của Godot): `ScreenContainer` → `TopStatusBar` → `BattleScene` → `BottomNav`. Nhờ vậy map luôn full màn hình thật (không bị co lại chừa chỗ cho top bar/bottom nav), 2 thanh đó chỉ NỔI ĐÈ lên trên.

## `ScreenRouter.gd` - chuyển tab data-driven
Mỗi con trực tiếp của `ScreenContainer` = 1 tab, **tên node chính là id tab** (`city`/`stage`/`boss`/`character`/`settings`). `show_screen(id)` chỉ bật `.visible` đúng 1 con. **Thêm tab mới sau này = thêm 1 node con + 1 dòng trong `BottomNav.TABS` - không sửa gì trong `ScreenRouter.gd`.**

## `BottomNav.gd`/`.tscn` - thanh nav 2 trạng thái
- **Thu gọn**: hàng 5 nút (icon+tên, build động từ `const TABS` trong code, không hand-type từng Button trong `.tscn`).
- **Mở rộng**: kéo `DragHandle` lên/xuống (theo dõi qua `gui_input` signal, không phải override `_gui_input`) → `Tween` chạy `offset_top` (panel neo đáy, `offset_top` càng âm càng cao) giữa `COLLAPSED_HEIGHT` (96) và `EXPANDED_HEIGHT` (340), snap theo ngưỡng khoảng cách kéo (`DRAG_TOGGLE_THRESHOLD_PX`).
- Nội dung phần mở rộng lấy từ `active_screen.get_shortcuts()` (duck-typed, optional - `has_method()` check) - **BottomNav không biết gì về nội dung từng tab**. Hiện CHƯA tab nào implement hàm này (city/stage chưa có shortcut nào thật sự cần thiết).

## `MainShell.gd`
Chỉ làm 3 việc: cập nhật `GoldLabel` mỗi frame, forward `BottomNav.tab_selected` → `ScreenRouter.show_screen()` + `BottomNav.refresh_for_screen()`, và **gating tương tác** khi `BattleScene.visible` (ẩn nav + gọi `set_interactive(false)` trên TỪNG map-tab có state đó - `city`/`stage` hiện có, tab mới sau này có tương tác riêng thì tự thêm dòng gating tương tự).

## Lưu ý khi thêm tab thật (Ải Boss/Nhân vật)
1. Tạo scene/script riêng (không nhất thiết cần proxy Control + SubViewport như City/Ải - đó là do 2 map đó cần world 2D riêng; 1 tab UI thuần Control thì làm thẳng, xem `settings` làm ví dụ).
2. Thêm node con vào `ScreenContainer` trong `MainShell.tscn`, đặt tên đúng id tab.
3. Nếu cần chặn tương tác lúc `BattleScene` mở, thêm dòng gating trong `MainShell.gd._process()`.
4. Không cần đụng `ScreenRouter.gd`/`BottomNav.gd`.

## File cũ không còn dùng (giữ nguyên, không xoá)
`Hub.tscn`/`Hub.gd`, `StageSelectPanel.tscn`/`.gd` - đã ngưng instance ở bất kỳ đâu, thay bằng kiến trúc trên. `StageFlowController.gd` được GIỮ LẠI nhưng thu hẹp còn đúng 1 việc: `start_stage(stage: StageData)` mở `BattleScene` - không còn quản lý `StageSelectPanel`.
