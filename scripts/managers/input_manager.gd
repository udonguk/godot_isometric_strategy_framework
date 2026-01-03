class_name InputManagerNode
extends Node

## 게임 내 모든 입력을 중앙 관리하는 싱글톤
## Autoload로 등록하여 사용
## Autoload 이름: InputManager (싱글톤 인스턴스)
## class_name: InputManagerNode (스크립트 타입)
##
## SOLID 원칙:
## - 단일 책임: 입력 처리와 우선순위 판정만 담당
## - 의존성 역전: SelectionManager라는 추상화를 통해 선택 처리
## - 개방-폐쇄: 새 클릭 타입 추가 시 ClickPriority Enum만 확장

# ============================================================
# 클릭 우선순위 정의
# ============================================================

## 클릭 우선순위 (낮은 숫자 = 높은 우선순위)
enum ClickPriority {
	UNIT = 2,        # 유닛 (최우선 - Layer 2)
	BUILDING = 3,    # 건물 (2순위 - Layer 3)
	GROUND = 1       # 땅 (최하위 - Layer 1)
}


# ============================================================
# 입력 처리
# ============================================================

## 미처리 입력 이벤트 핸들러
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click()


## 좌클릭 처리 (선택)
func _handle_left_click() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	print("[InputManager] 좌클릭 - 마우스 위치: ", mouse_pos)

	# 우선순위 순서대로 검사: 유닛 > 건물 > 빈 공간

	# 1순위: 유닛 검사
	var unit_result = _query_entity_at(mouse_pos, ClickPriority.UNIT)
	if unit_result:
		print("[InputManager] 유닛 감지됨: ", unit_result.collider)
		_on_unit_clicked(unit_result.collider)
		return

	# 2순위: 건물 검사
	var building_result = _query_entity_at(mouse_pos, ClickPriority.BUILDING)
	print("[InputManager] 건물 검사 결과: ", building_result)
	if building_result:
		print("[InputManager] 건물 감지됨: ", building_result.collider, " (타입: ", building_result.collider.get_class(), ")")
		_on_building_clicked(building_result.collider)
		return

	# 3순위: 빈 공간 처리
	_on_empty_space_clicked()


## 우클릭 처리 (이동 명령)
func _handle_right_click() -> void:
	# SelectionManager에서 선택된 유닛들 가져오기
	var selected_units = SelectionManager.get_selected_units()

	# 선택된 유닛이 없으면 무시
	if selected_units.is_empty():
		return

	# 마우스 위치 → 월드 좌표
	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * mouse_pos

	# 월드 좌표 → 그리드 좌표
	var grid_pos = GridSystem.world_to_grid(world_pos)

	# Navigation 가능 여부 검증
	if not GridSystem.is_valid_navigation_position(grid_pos):
		push_warning("[InputManager] Navigation 불가능한 위치: ", grid_pos)
		return

	# 선택된 모든 유닛에게 이동 명령 (그리드 좌표 사용)
	for unit in selected_units:
		unit.move_to_grid(grid_pos)

	print("[InputManager] 유닛 이동 명령 - Grid: %s (유닛 %d개)" % [grid_pos, selected_units.size()])


# ============================================================
# Physics Query
# ============================================================

## 특정 위치의 엔티티 검색
## @param screen_pos: 스크린 좌표
## @param layer: 검색할 레이어 (ClickPriority)
## @return: 충돌 결과 (Dictionary) 또는 null
func _query_entity_at(screen_pos: Vector2, layer: ClickPriority) -> Dictionary:
	# 스크린 좌표 → 월드 좌표 변환
	var world_pos = get_viewport().get_canvas_transform().affine_inverse() * screen_pos

	# Physics Query 설정
	var space_state = get_viewport().get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()

	params.position = world_pos
	params.collision_mask = 1 << (layer - 1)  # Layer를 Mask로 비트 변환
	params.collide_with_areas = true
	params.collide_with_bodies = true

	# 충돌 검사
	var results = space_state.intersect_point(params)

	if results.size() > 0:
		return results[0]  # 첫 번째 결과 반환

	return {}  # 빈 Dictionary 반환


# ============================================================
# 클릭 핸들러
# ============================================================

## 유닛 클릭 핸들러
func _on_unit_clicked(unit: Node2D) -> void:
	if not unit is UnitEntity:
		push_warning("[InputManager] 유닛이 아닌 엔티티를 유닛으로 처리하려고 시도: ", unit.name)
		return

	# Ctrl 키 체크 (다중 선택)
	var multi_select = Input.is_key_pressed(KEY_CTRL)

	# SelectionManager에 위임
	SelectionManager.select_unit(unit, multi_select)

	print("[InputManager] 유닛 클릭: ", unit.name)


## 건물 클릭 핸들러
func _on_building_clicked(collider: Node2D) -> void:
	# Area2D가 감지되므로 부모 노드(BuildingEntity)를 가져옴
	var building = collider.get_parent()

	if not building is BuildingEntity:
		push_warning("[InputManager] 건물이 아닌 엔티티를 건물로 처리하려고 시도: ", building.name)
		return

	# SelectionManager에 위임
	SelectionManager.select_building(building)

	print("[InputManager] 건물 클릭: ", building.name)


## 빈 공간 클릭 핸들러
func _on_empty_space_clicked() -> void:
	# SelectionManager에 위임
	SelectionManager.deselect_all()

	print("[InputManager] 빈 공간 클릭")
