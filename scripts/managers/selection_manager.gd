extends Node

## 선택 관리자 (SelectionManager)
##
## 게임 내 모든 선택 가능한 엔티티의 선택 상태를 관리합니다.
## - 유닛: 다중 선택 가능 (Ctrl+클릭)
## - 건물: 단일 선택만 가능
##
## SOLID 원칙:
## - 단일 책임: "선택 관리"라는 하나의 도메인만 담당
## - 개방-폐쇄: 새 엔티티 타입 추가 시 이 클래스만 확장

# ============================================================
# 선택된 엔티티 저장
# ============================================================

## 선택된 유닛들 (다중 선택 가능)
var selected_units: Array[UnitEntity] = []

## 선택된 건물 (단일 선택만)
var selected_building = null  # BuildingEntity 타입 (순환 참조 방지)


# ============================================================
# 유닛 선택 관리
# ============================================================

## 유닛 선택
## @param unit: 선택할 유닛
## @param multi_select: true면 기존 선택 유지, false면 기존 선택 해제
func select_unit(unit: UnitEntity, multi_select: bool = false) -> void:
	if not unit:
		push_warning("[SelectionManager] null 유닛을 선택하려고 시도했습니다.")
		return

	# 다중 선택이 아니면 기존 선택 해제
	if not multi_select:
		deselect_all_units()
		deselect_building()  # 건물 선택도 해제

	# 이미 선택된 유닛이면 무시
	if unit in selected_units:
		print("[SelectionManager] 이미 선택된 유닛: ", unit.name)
		return

	# 유닛 선택
	selected_units.append(unit)
	unit.is_selected = true

	print("[SelectionManager] 유닛 선택됨: ", unit.name, " (총 ", selected_units.size(), "개)")


## 특정 유닛 선택 해제
func deselect_unit(unit: UnitEntity) -> void:
	if unit in selected_units:
		selected_units.erase(unit)
		unit.is_selected = false
		print("[SelectionManager] 유닛 선택 해제: ", unit.name)


## 모든 유닛 선택 해제
func deselect_all_units() -> void:
	for unit in selected_units:
		unit.is_selected = false

	var count = selected_units.size()
	selected_units.clear()

	if count > 0:
		print("[SelectionManager] 모든 유닛 선택 해제 (", count, "개)")


## 선택된 유닛 목록 반환
func get_selected_units() -> Array[UnitEntity]:
	return selected_units


## 선택된 유닛이 있는지 확인
func has_selected_units() -> bool:
	return selected_units.size() > 0


# ============================================================
# 건물 선택 관리
# ============================================================

## 건물 선택 (단일 선택만)
func select_building(building) -> void:  # BuildingEntity 타입
	if not building:
		push_warning("[SelectionManager] null 건물을 선택하려고 시도했습니다.")
		return

	# 기존 건물 선택 해제
	if selected_building and selected_building != building:
		selected_building.hide_outline()

	# 유닛 선택도 해제 (건물 선택 시)
	deselect_all_units()

	# 새 건물 선택
	selected_building = building
	selected_building.show_outline()

	print("[SelectionManager] 건물 선택됨: ", building.name)


## 건물 선택 해제
func deselect_building() -> void:
	if selected_building:
		selected_building.hide_outline()
		print("[SelectionManager] 건물 선택 해제: ", selected_building.name)
		selected_building = null


## 선택된 건물 반환
func get_selected_building():  # BuildingEntity 타입 반환
	return selected_building


## 선택된 건물이 있는지 확인
func has_selected_building() -> bool:
	return selected_building != null


# ============================================================
# 통합 관리
# ============================================================

## 모든 선택 해제 (유닛 + 건물)
func deselect_all() -> void:
	deselect_all_units()
	deselect_building()


## 선택된 엔티티가 있는지 확인 (유닛 또는 건물)
func has_any_selection() -> bool:
	return has_selected_units() or has_selected_building()
