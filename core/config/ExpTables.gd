class_name ExpTables
extends RefCounted

## Bảng "EXP cần để lên MỖI cấp" (không phải cộng dồn) - lấy đúng cột "EXP
## cần" trong ROX_EXP_Goc_Base_Job_DayDu.xlsx, chia 1/10 (đúng quy ước đã dùng
## từ lúc làm mockup HTML). BASE_REQUIRED[i] = EXP cần để lên từ cấp (i+1) lên
## cấp (i+2) - Base Lv tối đa đạt được = BASE_REQUIRED.size() + 1 = 130 (khớp
## "Level 130 MAX" trong sheet "Base EXP"). JOB_REQUIRED tương tự cho Job Lv
## (sheet "First Job", tối đa 50) - CHƯA hỗ trợ Second/Third/Fourth Job (chưa
## có cơ chế chuyển job trong game này).

const BASE_REQUIRED: Array[int] = [
	1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000, 6500, 7000, 7500, 9000,
	10500, 12250, 14000, 16000, 18000, 22000, 26000, 27500, 29000, 30500, 33500, 43000, 52500,
	62500, 73000, 83500, 94000, 105000, 116500, 128500, 140500, 153000, 166000, 178500, 230000,
	282500, 338500, 398500, 462500, 530500, 602000, 678000, 757500, 841000, 1044000, 1242000,
	1450500, 1670000, 1900500, 2150000, 2411000, 2683000, 2966500, 3261500, 5344000, 6115000,
	6922000, 7764000, 7977000, 8190000, 8403000, 8616000, 8829000, 9042000, 9345000, 9558000,
	9771000, 9984000, 10197000, 10410000, 10623000, 10836000, 11049000, 11262000, 11672500,
	11885500, 12099000, 12312000, 12526000, 12739000, 12952500, 15994500, 19608000, 23814000,
	24866000, 25752500, 26655000, 27572000, 28505000, 29452500, 30416000, 31394000, 32388000,
	33396500, 34642500, 35685000, 36744000, 37817000, 38906500, 40010000, 41130000, 42264000,
	43414500, 44579000, 46018500, 47217500, 48432500, 49662000, 50907500, 52167500, 53443500,
	54734000, 56040500, 57361500, 59348000, 60885000, 62442500, 64018500, 65615000, 67230000,
	68805000, 70397000, 72008500, 73637000,
]

const JOB_REQUIRED: Array[int] = [
	1950, 2350, 2750, 3150, 3500, 3900, 4800, 5200, 6150, 6650, 7800, 9000, 9550, 10950, 12350,
	13000, 15850, 18750, 19800, 20700, 21750, 22850, 25050, 26000, 26850, 27700, 28600, 29700,
	30650, 31950, 32850, 34100, 35050, 36000, 37200, 38150, 39500, 40450, 41450, 42950, 43900,
	45550, 46550, 47500, 49100, 50100, 51100, 52800, 53850,
]

## Suy ra cấp độ hiện tại + tiến độ EXP trong cấp đó từ TỔNG EXP đã tích -
## dùng chung cho cả Base/Job (khác nhau ở bảng truyền vào table).
## exp_required = -1 nghĩa là đã đạt cấp tối đa (MAX), không lên được nữa.
static func level_from_total_exp(total_exp: int, table: Array[int]) -> Dictionary:
	var level := 1
	var remaining := total_exp
	while level - 1 < table.size() and remaining >= table[level - 1]:
		remaining -= table[level - 1]
		level += 1
	var exp_required: int = table[level - 1] if level - 1 < table.size() else -1
	return {"level": level, "exp_into_level": remaining, "exp_required": exp_required}
