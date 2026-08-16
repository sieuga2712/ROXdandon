# core/config

## Mục đích
Hằng số và bảng cân bằng (balance) toàn cục — không phải logic ứng dụng, không phải feature.

## File chính
- `Enums.gd` — enum toàn cục (`Enums.Team`, `Enums.TroopType`...), `class_name Enums`, không có autoload — dùng thẳng qua global class.
- `ExpTables.gd` — 2 bảng const `BASE_REQUIRED` (129 cấp) + `JOB_REQUIRED` (49 cấp), hàm `level_from_total_exp()` suy cấp độ từ tổng EXP tích luỹ.

## Entry Point
Không cần — cả 2 đều là global class (`class_name`), gọi trực tiếp `Enums.Team.PLAYER`, `ExpTables.level_from_total_exp(...)`.

## Public API
```
ExpTables.level_from_total_exp(total_exp: int, table: Array) -> Dictionary
ExpTables.BASE_REQUIRED / ExpTables.JOB_REQUIRED   (const Array)
```

## Module được phép gọi
Không phụ thuộc module nào khác trong project.

## Ai được gọi vào đây
`core/app/GameState.gd` (tính cấp độ), và bất kỳ module nào cần `Enums`.

## Tài liệu thiết kế liên quan
- `ROX đần độn/Thiết kế Game/Bản đồ/Ủy Thác, Boss & Treo máy.md` — mục "Hệ EXP/Cấp độ" giải thích nguồn số liệu (`ROX_EXP_Goc_Base_Job_DayDu.xlsx`, quy ước chia 1/10) và công thức tăng chỉ số theo cấp.
